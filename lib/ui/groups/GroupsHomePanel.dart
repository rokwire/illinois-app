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
import 'package:illinois/ui/settings/SettingsPersonalInfoPanel.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/auth2.dart';
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

class GroupsHomePanel extends StatefulWidget{
  _GroupsHomePanelState createState() => _GroupsHomePanelState();
}

enum _FilterType { none, category, tags }
enum _TagFilter { all, my }

class _GroupsHomePanelState extends State<GroupsHomePanel> implements NotificationsListener{
  final String _allCategoriesValue = Localization().getStringEx("panel.groups_home.label.all_categories", "All Categories");

  bool _isFilterLoading = false;
  bool _isGroupsLoading = false;
  bool _myGroupsSelected = true;

  List<Group>? _allGroups;
  List<Group>? _myGroups;
  List<Group>? _myPendingGroups;

  String? _selectedCategory;
  List<String>? _categories;

  _TagFilter? _selectedTagFilter = _TagFilter.all;
  _FilterType __activeFilterType = _FilterType.none;

  //TBD: this filtering has to be done on the server side.
  List<Group>? _getFilteredAllGroupsContent() {
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

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Groups.notifyUserMembershipUpdated, Groups.notifyGroupCreated, Groups.notifyGroupUpdated, Groups.notifyGroupDeleted]);
    _loadFilters();
    _loadInitialGroupsContent();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  void _loadInitialGroupsContent() {

    setState(() {
      _isGroupsLoading = true;
    });

    Groups().loadGroups(myGroups: _myGroupsSelected).then((List<Group>? groups) {
      if (mounted) {
        if (groups != null) {
          // Initial request succeded
          List<Group>? sortedGroups = _sortGroups(groups);
          if (_myGroupsSelected) {
            List<Group>? myGroups = sortedGroups?.where((group) => group.currentUserIsMemberOrAdmin).toList();
            List<Group>? myPendingGroups = sortedGroups?.where((group) => group.currentUserIsPendingMember).toList();
            if ((myGroups?.isNotEmpty ?? false) || (myPendingGroups?.isNotEmpty ?? false)) {
              // Non-Empty My Groups content => apply it
              setState(() {
                _isGroupsLoading = false;
                _myGroups = myGroups;
                _myPendingGroups = myPendingGroups;
              });
            }
            else {
              // Empty My Groups content => Load All Groups content
              Groups().loadGroups(myGroups: false).then((List<Group>? groups2) {
                if (mounted) {
                  if (groups2 != null) {
                    // Empty My Groups content; All Groups request succeded => apply everything collected + switch tab seletion
                    List<Group>? allGroups = _sortGroups(groups2);
                    setState(() {
                      _isGroupsLoading = false;
                      _myGroupsSelected = false;
                      _myGroups = myGroups;
                      _myPendingGroups = myPendingGroups;
                      _allGroups = allGroups;
                    });
                  }
                  else {
                    // Empty My Groups content; All Groups request failed => apply everything collected
                    setState(() {
                      _isGroupsLoading = false;
                      _myGroups = myGroups;
                      _myPendingGroups = myPendingGroups;
                    });
                  }
                }
              });
            }
          }
          else {
            // Apply All Groups content
            setState(() {
              _isGroupsLoading = false;
              _allGroups = sortedGroups;
            });
          }
        }
        else {
          // Initial request failed
          setState(() {
            _isGroupsLoading = false;
          });
        }
      }
    });
  }

  void _loadTabContentIfNeeded() {
    bool needsLoad = _myGroupsSelected ? ((_myGroups == null) || (_myPendingGroups == null)) : (_allGroups == null);
    if (needsLoad) {
      _loadCurrentTabContent();
    }
  }

  void _refreshGroups() {
    // Force other tab content reload on next tab switch
    if (_myGroupsSelected) {
      _allGroups = null;
    }
    else {
      _myGroups = _myPendingGroups = null;
    }
    _loadCurrentTabContent();
  }

  void _loadCurrentTabContent() {
    setState(() {
      _isGroupsLoading = true;
    });
    Groups().loadGroups(myGroups: _myGroupsSelected).then((List<Group>? groups) {
      if (mounted) {
        if (groups != null) {
          List<Group>? sortedGroups = _sortGroups(groups);
          if (_myGroupsSelected) {
            setState(() {
              _isGroupsLoading = false;
              _myGroups = sortedGroups?.where((group) => group.currentUserIsMemberOrAdmin).toList();
              _myPendingGroups = sortedGroups?.where((group) => group.currentUserIsPendingMember).toList();
            });
          }
          else {
            setState(() {
              _isGroupsLoading = false;
              _allGroups = sortedGroups;
            });
          }
        }
        else {
          setState(() {
            _isGroupsLoading = false;
          });
        }
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
              Column( children: <Widget>[ _myGroupsSelected ? _buildMyGroupsContent() : _buildAllGroupsContent(), ],),
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
    return Container(
      color: Styles().colors!.fillColorPrimary,
      padding: EdgeInsets.symmetric(horizontal: 10),
      child:
      Row(children: [
        Expanded(child:
            SingleChildScrollView(scrollDirection: Axis.horizontal, child:
            ConstrainedBox(
              constraints:BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 20/*padding*/,
              ),
              child: IntrinsicWidth(child:
                Row(
                  children: <Widget>[
                    _GroupTabButton(title: Localization().getStringEx("panel.groups_home.button.all_groups.title", 'All Groups'), hint: '', selected: !_myGroupsSelected ,onTap: _onTapAllGroups),
                    Container(width: 15,),
                    _GroupTabButton(title: Localization().getStringEx("panel.groups_home.button.my_groups.title", 'My Groups'), hint: '', selected: _myGroupsSelected, onTap: _onTapMyGroups),
                    Container(width: 15,),
                    Flexible(child: Container()),
                    Visibility(visible: Auth2().isLoggedIn, child: _buildUserProfilePicture()),
                    Visibility(visible: _canCreateGroup, child: _GroupTabButton(title: Localization().getStringEx("panel.groups_home.button.create_group.title", 'Create'), hint: '', rightIcon: Image.asset('images/icon-plus.png', height: 10, width: 10, excludeFromSemantics: true), selected: false, onTap: _onTapCreate)),
                  ],
                ),
              )
            )
          )
        ),
      ],)
    );
  }

  Widget _buildFilterButtons() {
    bool hasCategories = CollectionUtils.isNotEmpty(_categories);
    return _isFilterLoading || _myGroupsSelected
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
                Semantics(
                  label:Localization().getStringEx("panel.groups_home.button.search.title", "Search"),
                  child:
                  IconButton(
                    icon: Image.asset(
                      'images/icon-search.png',
                      color: Styles().colors!.fillColorSecondary,
                      excludeFromSemantics: true,
                      width: 25,
                      height: 25,
                    ),
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
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Styles().colors!.fillColorPrimaryTransparent03,
                ),
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

  Widget _buildMyGroupsContent(){
    if (CollectionUtils.isEmpty(_myGroups) && CollectionUtils.isEmpty(_myPendingGroups)) {
      String text = ((_myGroups != null) && (_myPendingGroups != null)) ?
        Localization().getStringEx("panel.groups_home.label.my_groups.empty", "You are not member of any groups yet") :
        Localization().getStringEx("panel.groups_home.label.my_groups.failed", "Failed to load groups");
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        child: Text(text,
          style: TextStyle(
              fontFamily: Styles().fontFamilies!.regular,
              fontSize: 16,
              color: Styles().colors!.textBackground
          ),
        ),
      );
    }
    else {
      return Column(children: [
        _buildMyGroupsSection(),
        _buildMyPendingGroupsSection(),
      ],);
    }
  }

  Widget _buildMyGroupsSection() {
    List<Widget> widgets = [];
    if(CollectionUtils.isNotEmpty(_myGroups)) {
      widgets.add(Container(height: 8,));
      for (Group? group in _myGroups!) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: GroupCard(group: group, displayType: GroupCardDisplayType.myGroup, onImageTap: (){ onTapImage(group);} ,),
        ));
      }
      widgets.add(Container(height: 8,));
    }
    return Column(children: widgets,);
  }

  Widget _buildMyPendingGroupsSection(){
    if(CollectionUtils.isNotEmpty(_myPendingGroups)) {
      List<Widget> widgets = [];
      widgets.add(Container(height: 16,));
      widgets.add(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(Localization().getStringEx("panel.groups_home.label.pending", "Pending"),
            style: TextStyle(
                fontFamily: Styles().fontFamilies!.bold,
                fontSize: 20,
                color: Styles().colors!.fillColorPrimary
            ),
          )
        )
      );
      widgets.add(Container(height: 8,));
      for (Group? group in _myPendingGroups!) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: GroupCard(group: group, displayType: GroupCardDisplayType.myGroup,),
        ));
      }
      return
        Stack(children: [
          Container(
            height: 112,
            color: Styles().colors!.backgroundVariant,
            child:
            Column(children: [
              Container(height: 80,),
              Container(
                height: 32,
                child: CustomPaint(
                  painter: TrianglePainter(painterColor: Styles().colors!.background),
                  child: Container(),
                )
              ),
            ],)
          ),
          Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets,)
        ],);
    }
    return Container();
  }

  Widget _buildAllGroupsContent(){
    List<Group>? filteredGroups = CollectionUtils.isNotEmpty(_allGroups) ? _getFilteredAllGroupsContent() : null;
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
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        child: Text(text,
          style: TextStyle(
            fontFamily: Styles().fontFamilies!.regular,
            fontSize: 16,
            color: Styles().colors!.textBackground
          ),
        ),
      );
    }
  }

  Widget _buildUserProfilePicture() {
    return Center(
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Container(
                height: 34, width: 34, child: GroupMemberProfileImage(userId: Auth2().accountId, onTap: _onTapUserProfileImage))));
  }
  
  void switchTabSelection() {
    setState(() {
      _myGroupsSelected = !_myGroupsSelected;
    });
    _loadTabContentIfNeeded();
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
    if(_myGroupsSelected){
      switchTabSelection();
    }
  }

  void _onTapMyGroups(){
    Analytics().logSelect(target: "My Groups");
    if(!_myGroupsSelected){
      switchTabSelection();
    }
  }

  void _onTapCreate(){
    Analytics().logSelect(target: "Create Group");
    Navigator.push(context, MaterialPageRoute(builder: (context)=>GroupCreatePanel()));
  }

  Future<void> _onPullToRefresh() async {
    Analytics().logSelect(target: "Pull To Refresh");
    List<Group>? groups = await Groups().loadGroups(myGroups: _myGroupsSelected);
    if (mounted && (groups != null)) {
      List<Group>? sortedGroups = _sortGroups(groups);
      setState(() {
        if (_myGroupsSelected) {
          _myGroups = sortedGroups?.where((group) => group.currentUserIsMemberOrAdmin).toList();
          _myPendingGroups = sortedGroups?.where((group) => group.currentUserIsPendingMember).toList();
        }
        else {
          _allGroups = sortedGroups;
        }
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
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPersonalInfoPanel()));
  }
  
  bool get _canCreateGroup {
    return Auth2().isOidcLoggedIn;
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
        _refreshGroups();
      }
    }
  }
}

class _GroupTabButton extends StatelessWidget{
  final String? title;
  final String hint;
  final Image? rightIcon;
  final GestureDragCancelCallback onTap;
  final bool selected;

  _GroupTabButton({required this.title, required this.hint, this.rightIcon, required this.onTap, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      hint: hint,
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          child: Row(
            children: <Widget>[
              Stack(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      title!,
                      style: TextStyle(
                        fontFamily: Styles().fontFamilies!.bold,
                        fontSize: 16,
                        color: Styles().colors!.white,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: Visibility(
                      visible: selected,
                      child: Container(height: 4, color: Styles().colors!.fillColorSecondary,)
                    ),
                  )
                ],
              ),
              rightIcon != null ? Padding(
                padding: const EdgeInsets.only(left: 5),
                child: rightIcon,
              ) : Container()
            ],
          ),
        ),
      ),
    );
  }
}

