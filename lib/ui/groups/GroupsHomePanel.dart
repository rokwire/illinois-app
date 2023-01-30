/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/ContentFilter.dart';
import 'package:illinois/service/ContentFilter.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/groups/GroupFiltersPanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/groups/GroupCreatePanel.dart';
import 'package:illinois/ui/groups/GroupSearchPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/Filters.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class GroupsHomePanel extends StatefulWidget {
  final GroupsContentType? contentType;
  
  GroupsHomePanel({Key? key, this.contentType}) : super(key: key);
  
  _GroupsHomePanelState createState() => _GroupsHomePanelState();
}

enum _FilterType { none, category, tags }
enum _TagFilter { all, my }

class _GroupsHomePanelState extends State<GroupsHomePanel> implements NotificationsListener {
  final String _allCategoriesValue = Localization().getStringEx("panel.groups_home.label.all_categories", "All Categories");
  final Color _dimmedBackgroundColor = Color(0x99000000);

  bool _isFilterLoading = false;
  int _groupsLoadingProgress = 0;
  Set<Completer<void>>? _reloadGroupsContentCompleters;
  bool _myGroupsBusy = false;

  String? _newGroupId;
  GlobalKey? _newGroupKey;

  GroupsContentType? _selectedContentType;
  bool _contentTypesVisible = false;

  List<Group>? _allGroups;
  List<Group>? _userGroups;

  String? _selectedCategory;
  List<String>? _categories;

  ContentFilterSet? _contentFilters;
  Map<String, dynamic> _contentFiltersSelection = <String, dynamic>{};
  String? _contentFiltersSelectionDescription;

  _TagFilter? _selectedTagFilter = _TagFilter.all;
  _FilterType __activeFilterType = _FilterType.none;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Groups.notifyUserMembershipUpdated,
      Groups.notifyGroupCreated,
      Groups.notifyGroupUpdated,
      Groups.notifyGroupDeleted,
      Groups.notifyUserGroupsUpdated,
      Auth2.notifyLoginSucceeded,
      Auth2.notifyLogout,
      FlexUI.notifyChanged,
      Connectivity.notifyStatusChanged,
    ]);
    _selectedContentType = widget.contentType;
    _loadFilters();
    _reloadGroupsContent();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx("panel.groups_home.label.heading","Groups"), leading: RootHeaderBarLeading.Back,),
      body: _buildContent(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  ///////////////////////////////////
  // Data Loading

  Future<void> _reloadGroupsContent() async {
    if (!Connectivity().isOffline) {
      if (_reloadGroupsContentCompleters == null) {
        _reloadGroupsContentCompleters = <Completer<void>>{};

        _allGroups = null;
        _increaseGroupsLoadingProgress();
        List<List<Group>?> result = await Future.wait([
          _loadUserGroups(),
          _loadAllGroups(),
        ]);
        _userGroups = (0 < result.length) ? result[0] : Groups().userGroups;
        _allGroups = (1 < result.length) ? result[1] : null;
        _decreaseGroupsLoadingProgress();
        _checkGroupsContentLoaded();

        if (_reloadGroupsContentCompleters != null) {
          Set<Completer<void>> loginCompleters = _reloadGroupsContentCompleters!;
          _reloadGroupsContentCompleters = null;
          for (Completer<void> completer in loginCompleters) {
            completer.complete();
          }
        }
      }
      else {
        Completer<void> completer = Completer<bool?>();
        _reloadGroupsContentCompleters!.add(completer);
        return completer.future;
      }
    }
  }

  Future<void> _reloadAllGroupsContent() async {
    if (!Connectivity().isOffline) {
      _increaseGroupsLoadingProgress();
      _allGroups = await _loadAllGroups();
      _decreaseGroupsLoadingProgress();
      _checkGroupsContentLoaded();
    }
  }

  Future<List<Group>?> _loadUserGroups() async =>
    Groups().loadGroups(contentType: GroupsContentType.my);

  Future<List<Group>?> _loadAllGroups() async =>
    Groups().loadGroups(
      contentType: GroupsContentType.all,
      category: (_selectedCategory != _allCategoriesValue) ? _selectedCategory : null,
      filters: _contentFiltersSelection,
      tags: (_selectedTagFilter == _TagFilter.my) ? Auth2().prefs?.positiveTags : null,
    );

  void _checkGroupsContentLoaded() {
    if (!_isGroupsLoading) {
      _selectedContentType ??= (CollectionUtils.isNotEmpty(_userGroups) ? GroupsContentType.my : GroupsContentType.all);
      _updateState();
    }
  }

  void _applyUserGroups() {
    _userGroups = Groups().userGroups;
    _updateState();
  }

  Future<void> _loadFilters() async{
    setState(() {
      _isFilterLoading = true;
    });
    List<dynamic> results = await Future.wait([
      Groups().loadCategories(),
      ContentFilters().loadFilterSet('groups'),
    ]);
    
    List<String> categories = [];
    categories.add(_allCategoriesValue);
    List<String>? groupCategories = (0 < results.length) ? JsonUtils.stringListValue(results[0])  : null;
    if (CollectionUtils.isNotEmpty(groupCategories)) {
      categories.addAll(groupCategories!);
    }

    setStateIfMounted(() {
      _categories = categories;
      _selectedCategory = _allCategoriesValue;
      _contentFilters = ((1 < results.length) && (results[1] is ContentFilterSet)) ? results[1] : null;
      _isFilterLoading = false;
    });
  }

  static String? _tagFilterToDisplayString(_TagFilter? tagFilter) {
    switch (tagFilter) {
      case _TagFilter.all:
        return Localization().getStringEx('panel.groups_home.filter.tag.all.label', 'All Tags');
      case _TagFilter.my:
        return Localization().getStringEx('panel.groups_home.filter.tag.my.label', 'My Tags');
      default:
        return null;
    }
  }

  bool get _showMyGroups {
    return FlexUI().isAuthenticationAvailable;
  }

  void _buildMyGroupsAndPending({List<Group>? myGroups, List<Group>? myPendingGroups}) {
    if (_userGroups != null) {
      for (Group group in _userGroups!) {
        Member? currentUserAsMember = group.currentMember;
        if (currentUserAsMember != null) {
          if (currentUserAsMember.isMemberOrAdmin) {
            myGroups?.add(group);
          }
          else if (currentUserAsMember.isPendingMember) {
            myPendingGroups?.add(group);
          }
        }
      }
    }
  }

  void _increaseGroupsLoadingProgress() {
    _groupsLoadingProgress++;
    _updateState();
  }

  void _decreaseGroupsLoadingProgress() {
    _groupsLoadingProgress--;
    _updateState();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isGroupsLoading {
    return (_groupsLoadingProgress > 0);
  }

  bool get _isLoading {
    return _isFilterLoading || _isGroupsLoading;
  }

  bool get _hasActiveFilter {
    return _activeFilterType != _FilterType.none;
  }

  _FilterType get _activeFilterType {
    return __activeFilterType;
  }

  set _activeFilterType(_FilterType value) {
    if (__activeFilterType != value) {
      __activeFilterType = value;
      _updateState();
    }
  }

  List<dynamic>? get _activeFilterList {
    switch (_activeFilterType) {
      case _FilterType.category:
        return _categories;
      case _FilterType.tags:
        return _TagFilter.values;
      default:
        return null;
    }
  }

  ///////////////////////////////////
  // Content Building

  Widget _buildContent(){
    return
      Column(children: <Widget>[
        _buildGroupsContentSelection(),
        Expanded(child: Stack(alignment: Alignment.topCenter, children: [
          Column(children: [
            _buildFunctionalBar(),
            Expanded(child: _isLoading
              ? Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorPrimary), ),)
              : Stack(alignment: AlignmentDirectional.topCenter, children: <Widget>[
                  Container(color: Styles().colors!.background, child:
                    RefreshIndicator(onRefresh: _onPullToRefresh, child:
                      SingleChildScrollView(scrollDirection: Axis.vertical, physics: AlwaysScrollableScrollPhysics(), child:
                        Column(children: <Widget>[ _buildGroupsContent(), ],),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: _hasActiveFilter, child: _buildDimmedContainer()),
                  _hasActiveFilter ? _buildFilterContent() : Container()
                ],),
            )
          ]),
          _buildContentTypesContainer()
        ]))
      ]);
  }

  Widget _buildContentTypesContainer() {
    return Visibility(visible: _contentTypesVisible, child: Stack(children: [
        GestureDetector(onTap: _changeContentTypesVisibility, child: Container(color: _dimmedBackgroundColor)),
        _buildTypesValuesWidget()
    ]));
  }

  Widget _buildTypesValuesWidget() {
    List<Widget> typeWidgetList = <Widget>[];
    typeWidgetList.add(Container(color: Styles().colors!.fillColorSecondary, height: 2));
    for (GroupsContentType type in GroupsContentType.values) {
      if ((_selectedContentType != type)) {
        typeWidgetList.add(_buildContentItem(type));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: typeWidgetList)));
  }

  Widget _buildContentItem(GroupsContentType contentType) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconKey: null,
        label: _getContentLabel(contentType),
        onTap: () => _onTapContentType(contentType));
  }

  Widget _buildGroupsContentSelection() {
    return Padding(padding: EdgeInsets.only(left: 16, top: 16, right: 16), child: RibbonButton(
      progress: _myGroupsBusy,
      textColor: Styles().colors!.fillColorSecondary,
      backgroundColor: Styles().colors!.white,
      borderRadius: BorderRadius.all(Radius.circular(5)),
      border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
      rightIconKey: _contentTypesVisible ? 'chevron-up' : 'chevron-down',
      label: _getContentLabel(_selectedContentType),
      onTap: _canTapGroupsContentType ? _changeContentTypesVisibility : null
    ));
  }

  Widget _buildFunctionalBar() {
    return Padding(padding: const EdgeInsets.only(left: 16), child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: <Widget>[ Expanded(child:
        Wrap(alignment: WrapAlignment.spaceBetween, runAlignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.start, children: <Widget>[
          _buildFiltersBar(),
          _buildCommandsBar(),
        ],),
      )]),
      _buildContentFiltersDescription(),
    ],)
    );
  }

  Widget _buildFiltersBar() {
    if (_isFilterLoading || (_selectedContentType == GroupsContentType.my)) {
      return SizedBox();
    }
    else {
      return _buildFilterButtons();
    }
  }

  Widget _buildFilterButtons() {
    String filtersTitle = Localization().getStringEx("panel.groups_home.filter.content_filter.label", "Filters");
    
    return Row(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
      Visibility(visible: CollectionUtils.isNotEmpty(_categories), child:
        Padding(padding: EdgeInsets.only(right: 6), child:
          FilterSelector(
            padding: EdgeInsets.only(top: 14, bottom: 8),
            title: _selectedCategory,
            active: (_activeFilterType == _FilterType.category),
            onTap: () {
              Analytics().logSelect(target: "GroupFilter - Category");
              setState(() {
                _activeFilterType = (_activeFilterType != _FilterType.category) ? _FilterType.category : _FilterType.none;
              });
            }
          )
        )
      ),
      
      Padding(padding: EdgeInsets.only(right: 6), child:
        FilterSelector(
          padding: EdgeInsets.only(top: 14, bottom: 8),
          title: StringUtils.ensureNotEmpty(_tagFilterToDisplayString(_selectedTagFilter)),
          active: (_activeFilterType == _FilterType.tags),
          onTap: () {
            Analytics().logSelect(target: "GroupFilter - Tags");
            setState(() {
              _activeFilterType = (_activeFilterType != _FilterType.tags) ? _FilterType.tags : _FilterType.none;
            });
          }
        ),
      ),
      
      Visibility(visible: _contentFilters?.isNotEmpty ?? false, child:
        Padding(padding: EdgeInsets.only(right: 6), child:
          InkWell(onTap: _onContentFilters, child:
            Padding(padding: EdgeInsets.only(top: 14, bottom: 8), child:
              Row(children: [
                Text(filtersTitle, style: TextStyle(
                  fontFamily: Styles().fontFamilies?.bold, fontSize: 16, color: Styles().colors?.fillColorPrimary,
                ),),
                Padding(padding: EdgeInsets.symmetric(horizontal: 4), child:
                  Styles().images?.getImage('chevron-right', width: 6, height: 10) ?? Container(),
                )
              ],),
              /*Container(
                decoration: BoxDecoration(border:
                  Border(bottom: BorderSide(color: Styles().colors!.fillColorSecondary!, width: 1.5, ))
                ),
                child: Text(filtersTitle, style: TextStyle(
                  fontFamily: Styles().fontFamilies?.bold, fontSize: 16, color: Styles().colors?.fillColorPrimary,
                ),),
              ),*/
              /*Text(filtersTitle, style: TextStyle(
                fontFamily: Styles().fontFamilies?.bold, fontSize: 16, color: Styles().colors?.fillColorPrimary,
                decoration: TextDecoration.underline, decorationColor: Styles().colors?.fillColorSecondary, decorationStyle: TextDecorationStyle.solid, decorationThickness: 1
              ),)*/
            )
          ),
        ),
      ),
    ],);
  }

  Widget _buildContentFiltersDescription() {
    return StringUtils.isNotEmpty(_contentFiltersSelectionDescription) ? 
      Padding(padding: EdgeInsets.only(top: 0, bottom: 4), child: 
      Row(children: [Expanded(child:
        Text(_contentFiltersSelectionDescription ?? '', style: TextStyle(color: Styles().colors!.textBackground, fontSize: 14, fontFamily: Styles().fontFamilies!.medium,),),
      ),],)
        
      ) : Container();
  }

  Widget _buildCommandsBar() {
    return Row(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
        Visibility(visible: _canCreateGroup, child:
          InkWell(onTap: _onTapCreate, child:
            Padding(padding: EdgeInsets.symmetric(vertical: 10), child:
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text(Localization().getStringEx("panel.groups_home.button.create_group.title", 'Create'), style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 16, color: Styles().colors?.fillColorPrimary)),
                Padding(padding: EdgeInsets.only(left: 4), child:
                  Styles().images?.getImage('plus-circle', excludeFromSemantics: true)
                )
              ])
            ),
          ),
        ),
        Semantics(label: Localization().getStringEx("panel.groups_home.button.search.title", "Search"), child:
          IconButton(icon: Styles().images?.getImage('search', excludeFromSemantics: true) ?? Container(), onPressed: () {
            Analytics().logSelect(target: "Search");
            Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupsSearchPanel()));
          },),
        )
    ],);
  }

  void _onContentFilters() {
    Analytics().logSelect(target: 'Filters');
    if (_contentFilters != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupFiltersPanel(contentFilters: _contentFilters!, selection: _contentFiltersSelection))).then((selection) {
        if ((selection != null) && mounted) {
          String? selectionText = _contentFilters?.selectionDescription(selection,
            filtersSeparator: ', ',
            entriesSeparator: ' or ',
            titleDelimiter: ' is '
          );
          setState(() {
            _contentFiltersSelection = selection;
            _contentFiltersSelectionDescription = StringUtils.isNotEmpty(selectionText) ? "Filter: $selectionText" : null;
          });
          _reloadAllGroupsContent();
        }
      });
    }
  }

  Widget _buildFilterContent() {
    return _buildFilterContentEx(
        itemCount: _activeFilterList!.length,
        itemBuilder: (context, index) {
          return  FilterListItem(
            title: StringUtils.ensureNotEmpty(_getFilterItemLabel(index)),
            selected: _isFilterItemSelected(index),
            onTap: ()=> _onTapFilterEntry(_activeFilterList![index]),
          );
        }
    );
  }

  bool _isFilterItemSelected(int filterListIndex) {
    if (CollectionUtils.isEmpty(_activeFilterList) || filterListIndex >= _activeFilterList!.length) {
      return false;
    }
    switch (_activeFilterType) {
      case _FilterType.category:
        return (_selectedCategory == _activeFilterList![filterListIndex]);
      case _FilterType.tags:
        return (_selectedTagFilter == _activeFilterList![filterListIndex]);
      default:
        return false;
    }
  }

  String? _getFilterItemLabel(int filterListIndex) {
    if (CollectionUtils.isEmpty(_activeFilterList) || filterListIndex >= _activeFilterList!.length) {
      return null;
    }
    switch (_activeFilterType) {
      case _FilterType.category:
        return _activeFilterList![filterListIndex];
      case _FilterType.tags:
        return _tagFilterToDisplayString(_activeFilterList![filterListIndex]);
      default:
        return null;
    }
  }

  Widget _buildFilterContentEx({required int itemCount, required IndexedWidgetBuilder itemBuilder}){

    return Semantics(child:Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 40),
        child: Semantics(child:Container(
          decoration: BoxDecoration(
            color: Styles().colors!.fillColorSecondary,
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Padding(
            padding: EdgeInsets.only(top: 2),
            child: Container(
              color: Colors.white,
              child: ListView.separated(
                shrinkWrap: true,
                separatorBuilder: (context, index) => Divider(height: 1, color: Styles().colors!.fillColorPrimaryTransparent03,),
                itemCount: itemCount,
                itemBuilder: itemBuilder,
              ),
            ),
          ),
        ))));
  }

  Widget _buildDimmedContainer() {
    return BlockSemantics(child:GestureDetector(
      onTap: (){
        setState(() {
          _activeFilterType = _FilterType.none;
        });
      },
        child: Container(color: _dimmedBackgroundColor))
    );
  }

  Widget _buildGroupsContent() {
    if (_selectedContentType == GroupsContentType.my) {
      return _buildMyGroupsContent();
    }
    else if (_selectedContentType == GroupsContentType.all) {
      return _buildAllGroupsContent();
    }
    else {
      return Container();
    }
  }

  Widget _buildMyGroupsContent(){
    List<Group> myGroups = <Group>[], myPendingGroups = <Group>[];
    _buildMyGroupsAndPending(myGroups: myGroups, myPendingGroups: myPendingGroups);

    if (CollectionUtils.isEmpty(myGroups) && CollectionUtils.isEmpty(myPendingGroups)) {
      String text = Localization().getStringEx("panel.groups_home.label.my_groups.empty", "You are not member of any groups yet");
      return Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 30), child:
        Text(text, style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground),),
      );
    }
    else {
      return Column(children: [
        _buildMyGroupsSection(myGroups),
        _buildMyPendingGroupsSection(myPendingGroups),
      ],);
    }
  }

  Widget _buildMyGroupsSection(List<Group> myGroups) {
    List<Widget> widgets = [];
    if(CollectionUtils.isNotEmpty(myGroups)) {
      for (Group group in myGroups) {
        if (group.isVisible) {
          EdgeInsetsGeometry padding = widgets.isNotEmpty ? const EdgeInsets.symmetric(vertical: 8) : const EdgeInsets.only(top: 6, bottom: 8);
          widgets.add(Padding(padding: padding, child:
            GroupCard(
              group: group,
              displayType: GroupCardDisplayType.myGroup,
              onImageTap: (){ onTapImage(group);},
              key: _getGroupKey(group),
            ),
          ));
        }
      }
      widgets.add(Container(height: 8,));
    }
    return Column(children: widgets,);
  }

  Widget _buildMyPendingGroupsSection(List<Group> myPendingGroups) {
    if(CollectionUtils.isNotEmpty(myPendingGroups)) {
      List<Widget> widgets = [];
      widgets.add(Container(height: 8));
      widgets.add(Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        Text(Localization().getStringEx("panel.groups_home.label.pending", "Pending"), style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 20, color: Styles().colors!.fillColorPrimary),)
        )
      );
      widgets.add(Container(height: 8,));
      for (Group group in myPendingGroups) {
        if (group.isVisible) {
          widgets.add(Padding(padding: const EdgeInsets.symmetric(vertical: 8), child:
            GroupCard(
              group: group,
              displayType: GroupCardDisplayType.myGroup,
              key: _getGroupKey(group),
            ),
          ));
        }
      }
      return Stack(children: [
          Container(height: 112, color: Styles().colors!.backgroundVariant, child:
            Column(children: [
              Container(height: 80,),
              Container(height: 32, child:
                CustomPaint(painter:
                  TrianglePainter(painterColor: Styles().colors!.background), child:
                    Container(),
                ),
              ),
            ],)
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets,)
        ],);
    }
    return Container();
  }

  Widget _buildAllGroupsContent(){
    if(CollectionUtils.isNotEmpty(_allGroups)){
      List<Widget> widgets = [];
      for(Group group in _allGroups!) {
        if (group.isVisible) {
          EdgeInsetsGeometry padding = widgets.isNotEmpty ? const EdgeInsets.symmetric(vertical: 8) : const EdgeInsets.only(top: 6, bottom: 8);
          widgets.add(Padding(padding: padding, child:
            GroupCard(
              group: group,
              key: _getGroupKey(group),
            ),
          ));
        }
      }
      return Column(children: widgets,);
    }
    else{
      String text;
      if (_allGroups == null) {
        text = Localization().getStringEx("panel.groups_home.label.all_groups.failed", "Failed to load groups");
      }
      else if (_allGroups!.isEmpty) {
        text = Localization().getStringEx("panel.groups_home.label.all_groups.empty", "There are no groups created yet");
      }
      else {
        text = Localization().getStringEx("panel.groups_home.label.all_groups.filtered.empty", "No groups match the selected filter");
      }
      return Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 30), child:
        Text(text, style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground),),
      );
    }
  }

  Key? _getGroupKey(Group group) {
    if ((_newGroupId != null) && (_newGroupId == group.id)) {
      return _newGroupKey;
    }
    else {
      return null;
    }
  }

  String _getContentLabel(GroupsContentType? contentType) {
    switch (contentType) {
      case GroupsContentType.all:
        return Localization().getStringEx("panel.groups_home.button.all_groups.title", 'All Groups');
      case GroupsContentType.my:
        return Localization().getStringEx("panel.groups_home.button.my_groups.title", 'My Groups');
      default:
        return '';
    }
  }
  
  void _changeContentTypesVisibility() {
    _contentTypesVisible = !_contentTypesVisible;
    _updateState();
  }

  void _onTapContentType(GroupsContentType contentType) {
    Analytics().logSelect(target: _getContentLabel(contentType));
    if (contentType == GroupsContentType.all) {
      _onSelectAllGroups();
    }
    else if (contentType == GroupsContentType.my) {
      _onSelectMyGroups();
    }
    _changeContentTypesVisibility();
  }

  void _onTapFilterEntry(dynamic entry) {
    String? analyticsTarget;
    switch (_activeFilterType) {
      case _FilterType.category:
        _selectedCategory = entry;
        analyticsTarget = "CategoryFilter";
        break;
      case _FilterType.tags:
        _selectedTagFilter = entry;
        analyticsTarget = "TagFilter";
        break;
      default:
        break;
    }
    Analytics().logSelect(target: "$analyticsTarget: $entry");
    setState(() {
      _activeFilterType = _FilterType.none;
    });
    _reloadAllGroupsContent();
  }

  void _onSelectAllGroups(){
    if(_selectedContentType != GroupsContentType.all){
      setState(() {
        _selectedContentType = GroupsContentType.all;
      });
    }
  }

  void _onSelectMyGroups() {
    if(_selectedContentType != GroupsContentType.my){
      if (Auth2().isOidcLoggedIn) {
        setState(() { _selectedContentType = GroupsContentType.my; });
      }
      else {
        setState(() { _myGroupsBusy = true; });
        
        Auth2().authenticateWithOidc().then((Auth2OidcAuthenticateResult? result) {
          if (mounted) {
            setState(() {
              _myGroupsBusy = false;
              if (result == Auth2OidcAuthenticateResult.succeeded) {
                _selectedContentType = GroupsContentType.my;
              }
            });
          }
        });

      }
    }
  }

  void _onTapCreate(){
    Analytics().logSelect(target: "Create Group");
    Navigator.push(context, MaterialPageRoute(builder: (context)=>GroupCreatePanel()));
  }

  Future<void> _onPullToRefresh() async {
    Analytics().logSelect(target: "Pull To Refresh");
    _reloadGroupsContent();
  }

  void onTapImage(Group? group){
    Analytics().logSelect(target: "Image");
    if(group?.imageURL!=null){
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (context, _, __) => ModalImagePanel(imageUrl: group!.imageURL!, onCloseAnalytics: () => Analytics().logSelect(target: "Close Image"))));
    }
  }
  
  bool get _canCreateGroup {
    return Auth2().isOidcLoggedIn && FlexUI().isSharingAvailable;
  }

  bool get _canTapGroupsContentType {
    return _showMyGroups && !_myGroupsBusy;
  }

  ///////////////////////////////////
  // NotificationsListener

  void onNotification(String name, dynamic param){
    if (name == Groups.notifyUserMembershipUpdated) {
      _updateState();
    }
    else if (name == Groups.notifyGroupCreated) {
      if (mounted) {
        _newGroupId = param;
        _newGroupKey = GlobalKey();
        _reloadGroupsContent().then((_) {
          if (_newGroupId == param) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              BuildContext? newGroupContext = _newGroupKey?.currentContext;
              _newGroupId = null;
              _newGroupKey = null;
              if (newGroupContext != null) {
                Scrollable.ensureVisible(newGroupContext, duration: Duration(milliseconds: 300));
              }
            });
          }
        });
      }
    }
    else if ((name == Groups.notifyGroupUpdated) || (name == Groups.notifyGroupDeleted)) {
      if (mounted) {
        _reloadGroupsContent();
      }
    }
    else if (name == Groups.notifyUserGroupsUpdated) {
      _applyUserGroups();
    }
    else if ((name == Auth2.notifyLoginSucceeded) ||  (name == Auth2.notifyLogout)) {
      // Reload content with some delay, do not unmount immidately GroupsCard that could have updated the login state.
      Future.delayed(Duration(microseconds: 300), () {
        if (mounted) {
          _reloadGroupsContent();
        }
      });
    }
    else if (name == FlexUI.notifyChanged) {
      if (mounted) {
        _reloadGroupsContent();
      }
    }
    else if (name == Connectivity.notifyStatusChanged) {
      if (Connectivity().isOnline && mounted) {
        _reloadGroupsContent();
      }
    }
  }
}
