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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/settings/SettingsProfileContentPanel.dart';
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

  bool _isFilterLoading = false;
  bool _isGroupsLoading = false;
  bool _myGroupsBusy = false;

  GroupsContentType? _selectedContentType;

  List<Group>? _allGroups;

  String? _selectedCategory;
  List<String>? _categories;

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
      Auth2.notifyLoginSucceeded,
      Auth2.notifyLogout,
      Connectivity.notifyStatusChanged,
    ]);
    _selectedContentType = widget.contentType;
    _loadFilters();
    _loadGroupsContent();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.groups_home.label.heading","Groups"),
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  ///////////////////////////////////
  // Data Loading

  void _loadGroupsContent() {

    setState(() {
      _isGroupsLoading = true;
    });

    // Load only my groups if the device is offline - allow the user to reach his groups
    Groups().loadGroups(contentType: Connectivity().isOffline ? GroupsContentType.my : GroupsContentType.all).then((List<Group>? groups) {
      if (mounted) {
        setState(() {
          _isGroupsLoading = false;
          _allGroups = _sortGroups(groups);
          if (_selectedContentType == null) {
            _selectedContentType = _hasMyGroups ? GroupsContentType.my : GroupsContentType.all;
          }
        });
      }
    });
  }

  Future<void> _loadFilters() async{
    setState(() {
      _isFilterLoading = true;
    });
    List<String> categories = [];
    categories.add(_allCategoriesValue);
    List<String>? groupCategories = await Groups().loadCategories();
    if (CollectionUtils.isNotEmpty(groupCategories)) {
      categories.addAll(groupCategories!);
    }
    _categories = categories;
    _selectedCategory = _allCategoriesValue;

    setState(() {
      _isFilterLoading = false;
    });
  }

  List<Group>? _sortGroups(List<Group>? groups) {
    if (CollectionUtils.isEmpty(groups)) {
      return groups;
    }
    groups!.sort((group1, group2) {
      int cmp = group1.category!.toLowerCase().compareTo(group2.category!.toLowerCase());
      if (cmp != 0) {
        return cmp;
      } else {
        return group1.title!.toLowerCase().compareTo(group2.title!.toLowerCase());
      }
    });
    return groups;
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

  bool get _hasMyGroups {
    if (Auth2().isOidcLoggedIn && Auth2().privacyMatch(4) && (_allGroups != null)) {
      for (Group group in _allGroups!) {
        if (group.currentUserIsMemberOrAdminOrPending) {
          return true;
        }
      }
    }
    return false;
  }

  bool get _showMyGroups {
    return Auth2().privacyMatch(4);
  }

  void _buildMyGroupsAndPending({List<Group>? myGroups, List<Group>? myPendingGroups}) {
    if (_allGroups != null) {
      for (Group group in _allGroups!) {
        Member? currentUserAsMember = group.currentUserAsMember;
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

  List<Group>? get _filteredAllGroupsContent {
    if (CollectionUtils.isEmpty(_allGroups)) {
      return _allGroups;
    }
    // Filter By Category
    String? selectedCategory = _allCategoriesValue != _selectedCategory ? _selectedCategory : null;
    List<Group>? filteredGroups = _allGroups;
    if (StringUtils.isNotEmpty(selectedCategory)) {
      filteredGroups = _allGroups!.where((group) => (selectedCategory == group.category)).toList();
    }
    // Filter by User Tags
    if (_selectedTagFilter == _TagFilter.my) {
      Set<String>? userTags = Auth2().prefs?.positiveTags;
      if (CollectionUtils.isNotEmpty(userTags) && CollectionUtils.isNotEmpty(filteredGroups)) {
        filteredGroups = filteredGroups!.where((group) => group.tags?.any((tag) => userTags!.contains(tag)) ?? false).toList();
      }
    }

    return filteredGroups;
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
      setState(() {});
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
        _buildTabs(),
        _buildFilterButtons(),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorPrimary), ),)
              : Stack(
            alignment: AlignmentDirectional.topCenter,
            children: <Widget>[
              Container(color: Styles().colors!.background, child:
                RefreshIndicator(onRefresh: _onPullToRefresh, child:
                  SingleChildScrollView(scrollDirection: Axis.vertical, physics: AlwaysScrollableScrollPhysics(), child:
                    Column( children: <Widget>[ _buildGroupsContent(), ],),
                  ),
                ),
              ),
              Visibility(
                  visible: _hasActiveFilter,
                  child: _buildDimmedContainer()
              ),
              _hasActiveFilter
                  ? _buildFilterContent()
                  : Container()
            ],
          ),
        ),
      ],);
  }

  Widget _buildTabs(){
    return Container(padding: EdgeInsets.symmetric(horizontal: 10), color: Styles().colors!.fillColorPrimary, child:
      Row(children: [
        Expanded(child:
            SingleChildScrollView(scrollDirection: Axis.horizontal, child:
            ConstrainedBox(constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 20 /*padding*/,), child:
              IntrinsicWidth(child:
                Row(children: <Widget>[
                  Padding(padding: EdgeInsets.only(right: 15), child:
                    _GroupTabButton(title: Localization().getStringEx("panel.groups_home.button.all_groups.title", 'All Groups'), hint: '', selected: (_selectedContentType == GroupsContentType.all) , onTap: _onTapAllGroups),
                  ),
                  Visibility(visible: _showMyGroups, child:
                    Padding(padding: EdgeInsets.only(right: 15), child:
                      _GroupTabButton(title: Localization().getStringEx("panel.groups_home.button.my_groups.title", 'My Groups'), hint: '', selected: (_selectedContentType == GroupsContentType.my), progress: _myGroupsBusy, onTap: _onTapMyGroups),
                    ),
                  ),
                  Flexible(child: Container()),
                  Visibility(visible: Auth2().isLoggedIn, child:
                    Padding(padding: EdgeInsets.only(left: 10, bottom: 3), child:
                      Container(height: 32, width: 32, child:
                        GroupMemberProfileImage(userId: Auth2().accountId, onTap: _onTapUserProfileImage)
                      ),
                    ),
                  ),
                  Visibility(visible: _canCreateGroup, child:
                    Padding(padding: EdgeInsets.only(left: 5), child:
                      _GroupTabButton(title: Localization().getStringEx("panel.groups_home.button.create_group.title", 'Create'), hint: '', rightIcon: Image.asset('images/icon-plus.png', height: 10, width: 10, excludeFromSemantics: true), selected: false, onTap: _onTapCreate),
                    ),
                  ),
                ],),
              )
            )
          )
        ),
      ],)
    );
  }

  Widget _buildFilterButtons() {
    bool hasCategories = CollectionUtils.isNotEmpty(_categories);
    return (_isFilterLoading || (_selectedContentType == GroupsContentType.my))
      ? Container()
      : Container(
        width: double.infinity,
        color: Styles().colors!.white,
        child: Padding(
            padding: const EdgeInsets.only(left: 6, right: 16, bottom: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Visibility(visible: hasCategories, child: FilterSelector(
                  title: _selectedCategory,
                  active: (_activeFilterType == _FilterType.category),
                  onTap: (){
                    Analytics().logSelect(target: "GroupFilter - Category");
                    setState(() {
                      _activeFilterType = (_activeFilterType != _FilterType.category) ? _FilterType.category : _FilterType.none;
                    });
                  }
                )),
                Visibility(visible: hasCategories, child: Container(width: 8)),
                FilterSelector(
                  title: StringUtils.ensureNotEmpty(_tagFilterToDisplayString(_selectedTagFilter)),
                  hint: "",
                  active: (_activeFilterType == _FilterType.tags),
                  onTap: (){
                    Analytics().logSelect(target: "GroupFilter - Tags");
                    setState(() {
                      _activeFilterType = (_activeFilterType != _FilterType.tags) ? _FilterType.tags : _FilterType.none;
                    });
                  }
                ),
                Expanded(child: Container()),
                Semantics(label:Localization().getStringEx("panel.groups_home.button.search.title", "Search"), child:
                  IconButton(
                    icon: Image.asset('images/icon-search.png', color: Styles().colors!.fillColorSecondary, excludeFromSemantics: true, width: 25, height: 25,),
                    onPressed: () {
                      Analytics().logSelect(target: "Search");
                      Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupsSearchPanel()));
                    },
                  ),
                )
              ],
            ),
          ),
      );
  }

  Widget _buildFilterContent() {
    return _buildFilterContentEx(
        itemCount: _activeFilterList!.length,
        itemBuilder: (context, index) {
          return  FilterListItem(
            title: StringUtils.ensureNotEmpty(_getFilterItemLabel(index)),
            selected: _isFilterItemSelected(index),
            onTap: ()=> _onTapFilterEntry(_activeFilterList![index]),
            iconAsset: "images/oval-orange.png",
            selectedIconAsset: "images/checkbox-selected.png",
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
        child: Container(color: Color(0x99000000)))
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
    // _myGroups = sortedGroups?.where((group) => group.currentUserIsMemberOrAdmin).toList();
    // _myPendingGroups = sortedGroups?.where((group) => group.currentUserIsPendingMember).toList();
    List<Group> myGroups = <Group>[], myPendingGroups = <Group>[];
    _buildMyGroupsAndPending(myGroups: myGroups, myPendingGroups: myPendingGroups);

    if (CollectionUtils.isEmpty(myGroups) && CollectionUtils.isEmpty(myPendingGroups)) {
      String text = Localization().getStringEx("panel.groups_home.label.my_groups.empty", "You are not member of any groups yet");
      //Localization().getStringEx("panel.groups_home.label.my_groups.failed", "Failed to load groups");
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
      widgets.add(Container(height: 8,));
      for (Group? group in myGroups) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: GroupCard(group: group, displayType: GroupCardDisplayType.myGroup, onImageTap: (){ onTapImage(group);} ,),
        ));
      }
      widgets.add(Container(height: 8,));
    }
    return Column(children: widgets,);
  }

  Widget _buildMyPendingGroupsSection(List<Group> myPendingGroups) {
    if(CollectionUtils.isNotEmpty(myPendingGroups)) {
      List<Widget> widgets = [];
      widgets.add(Container(height: 16,));
      widgets.add(Container(padding: EdgeInsets.symmetric(horizontal: 16), child:
        Text(Localization().getStringEx("panel.groups_home.label.pending", "Pending"), style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 20, color: Styles().colors!.fillColorPrimary),)
        )
      );
      widgets.add(Container(height: 8,));
      for (Group group in myPendingGroups) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: GroupCard(group: group, displayType: GroupCardDisplayType.myGroup,),
        ));
      }
      return
        Stack(children: [
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
          Column(crossAxisAlignment: CrossAxisAlignment.start,children: widgets,)
        ],);
    }
    return Container();
  }

  Widget _buildAllGroupsContent(){
    List<Group>? filteredGroups = CollectionUtils.isNotEmpty(_allGroups) ? _filteredAllGroupsContent : null;
    if(CollectionUtils.isNotEmpty(filteredGroups)){
      List<Widget> widgets = [];
      widgets.add(Container(height: 8,));
      for(Group? group in filteredGroups!){
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: GroupCard(group: group),
        ));
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
  }

  void _onTapAllGroups(){
    Analytics().logSelect(target: "All Groups");
    if(_selectedContentType != GroupsContentType.all){
      setState(() {
        _selectedContentType = GroupsContentType.all;
      });
    }
  }

  void _onTapMyGroups(){
    Analytics().logSelect(target: "My Groups");
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
    // Load only my groups if the device is offline - allow the user to reach his groups
    List<Group>? groups = await Groups().loadGroups(contentType: Connectivity().isOffline ? GroupsContentType.my : GroupsContentType.all);
    if (mounted && (groups != null)) {
      setState(() {
        _allGroups = _sortGroups(groups);
      });
    }
  }

  void onTapImage(Group? group){
    Analytics().logSelect(target: "Image");
    if(group?.imageURL!=null){
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (context, _, __) => ModalImagePanel(imageUrl: group!.imageURL!, onCloseAnalytics: () => Analytics().logSelect(target: "Close Image"))));
    }
  }

  void _onTapUserProfileImage() {
    Analytics().logSelect(target: "User Profile Image");
    SettingsProfileContentPanel.present(context);
  }
  
  bool get _canCreateGroup {
    return Auth2().isOidcLoggedIn && Auth2().privacyMatch(5);
  }

  ///////////////////////////////////
  // NotificationsListener

  void onNotification(String name, dynamic param){
    if (name == Groups.notifyUserMembershipUpdated) {
      if (mounted) {
        setState(() {});
      }
    }
    else if ((name == Groups.notifyGroupCreated) || (name == Groups.notifyGroupUpdated) || (name == Groups.notifyGroupDeleted)) {
      if (mounted) {
        _loadGroupsContent();
      }
    }
    else if ((name == Auth2.notifyLoginSucceeded) ||  (name == Auth2.notifyLogout)) {
      // Reload content with some delay, do not unmount immidately GroupsCard that could have updated the login state.
      Future.delayed(Duration(microseconds: 300), () {
        if (mounted) {
          _loadGroupsContent();
        }
      });
    }
    else if (name == Connectivity.notifyStatusChanged) {
      if (Connectivity().isOnline && mounted) {
        _loadGroupsContent();
      }
    }
  }
}

class _GroupTabButton extends StatefulWidget{
  final String? title;
  final String hint;
  final Image? rightIcon;
  final GestureDragCancelCallback onTap;
  final bool selected;
  final bool progress;

  _GroupTabButton({required this.title, required this.hint, this.rightIcon, required this.onTap, this.selected = false, this.progress = false});

  @override
  _GroupTabButtonState createState() => _GroupTabButtonState();
}

class _GroupTabButtonState extends State<_GroupTabButton> {
  
  final GlobalKey _contentKey = GlobalKey();
  Size? _contentSize;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _evalContentSize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(label: widget.title, hint: widget.hint, button: true, selected: widget.selected, excludeSemantics: true, child:
      GestureDetector(onTap: widget.onTap, child:
          Row(children: <Widget>[
            Stack(key: _contentKey, children: <Widget>[
              Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
                Text(widget.title ?? '', style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 16, color: Styles().colors?.white,),),
              ),
              Positioned(left: 0, right: 0, bottom: 0, child:
                Visibility(visible: widget.selected, child:
                  Container(height: 4, color: Styles().colors?.fillColorSecondary,)
                ),
              ),
              Visibility(visible: widget.progress, child:
                (_contentSize != null) ? SizedBox(width: _contentSize!.width, height: _contentSize!.height, child:
                  Align(alignment: Alignment.center, child: // TBD: align centered
                    SizedBox(height: 16, width: 16, child:
                      CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), )
                    ),
                  ),
                ) : Container(),
              ),
            ],),
            (widget.rightIcon != null) ? Padding(padding: const EdgeInsets.only(left: 5), child: widget.rightIcon,) : Container()
          ],),
      ),
    );
  }

  void _evalContentSize() {
    try {
      final RenderObject? renderBox = _contentKey.currentContext?.findRenderObject();
      if (renderBox is RenderBox) {
        if (mounted) {
          setState(() {
            _contentSize = renderBox.size;
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}

