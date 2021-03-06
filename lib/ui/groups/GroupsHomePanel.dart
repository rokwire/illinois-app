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
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/ui/groups/GroupCreatePanel.dart';
import 'package:illinois/ui/groups/GroupSearchPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/FilterWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class GroupsHomePanel extends StatefulWidget{
  _GroupsHomePanelState createState() => _GroupsHomePanelState();
}

enum _FilterType { none, category, tags }
enum _TagFilter { all, my }

class _GroupsHomePanelState extends State<GroupsHomePanel> implements NotificationsListener{
  final String _allCategoriesValue = Localization().getStringEx("panel.groups_home.label.all_categories", "All categories");

  bool _isFilterLoading = false;
  bool _isAllGroupsLoading = false;
  bool _isMyGroupsLoading = false;
  bool _myGroupsSelected = false;

  List<Group> _allGroups;
  List<Group> _myGroups;
  List<Group> _myPendingGroups;

  String _selectedCategory;
  List<String> _categories;

  _TagFilter _selectedTagFilter = _TagFilter.all;
  _FilterType __activeFilterType = _FilterType.none;

  //TBD: this filtering has to be done on the server side.
  List<Group> get _allFilteredGroups {
    if (AppCollection.isCollectionEmpty(_allGroups)) {
      return _allGroups;
    }
    // Filter By Category
    String selectedCategory = _allCategoriesValue != _selectedCategory ? _selectedCategory : null;
    List<Group> filteredGroups = _allGroups;
    if (AppString.isStringNotEmpty(selectedCategory)) {
      filteredGroups = _allGroups.where((group) => (selectedCategory == group.category)).toList();
    }
    // Filter by User Tags
    if (_selectedTagFilter == _TagFilter.my) {
      List<String> userTags = User().getTags();
      if (AppCollection.isCollectionNotEmpty(userTags) && AppCollection.isCollectionNotEmpty(filteredGroups)) {
        filteredGroups = filteredGroups.where((group) => group.tags?.any((tag) => userTags.contains(tag)) ?? false).toList();
      }
    }

    return filteredGroups;
  }

  bool get _isLoading {
    return _isFilterLoading || _isAllGroupsLoading || _isMyGroupsLoading;
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

  List<dynamic> get _activeFilterList {
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
    _loadGroups();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  void _loadGroups(){
    setState(() {
      _isAllGroupsLoading = true;
    });

    Groups().loadGroups(myGroups: false).then((List<Group> groups){
      if(groups != null) {
        _allGroups = _sortGroups(groups);
      }
    }).whenComplete((){
      setState(() {
        _isAllGroupsLoading = false;
      });
    });
  }

  void _loadMyGroups(){
    setState(() {
      _isMyGroupsLoading = true;
    });
    Groups().loadGroups(myGroups: true).then((List<Group> groups){
      if(AppCollection.isCollectionNotEmpty(groups)) {
        List<Group> sortedGroups = _sortGroups(groups);
        _myGroups = sortedGroups?.where((group) => group?.currentUserIsUserMember)?.toList();
        _myPendingGroups = sortedGroups?.where((group) => group?.currentUserIsPendingMember)?.toList();
      }
      else{
        _myGroups = [];
        _myPendingGroups = [];
      }
    }).whenComplete((){
      setState(() {
        _isMyGroupsLoading = false;
      });
    });
  }

  Future<void> _loadFilters() async{
    setState(() {
      _isFilterLoading = true;
    });
    List<String> categories = [];
    categories.add(_allCategoriesValue);
    List<String> groupCategories = await Groups().loadCategories();
    if (AppCollection.isCollectionNotEmpty(groupCategories)) {
      categories.addAll(groupCategories);
    }
    _categories = categories;
    _selectedCategory = _allCategoriesValue;

    setState(() {
      _isFilterLoading = false;
    });
  }

  void _loadContentFromNet({bool force = false}){
    if(_myGroupsSelected){
      if(force || _myGroups == null && _myPendingGroups == null){
        _loadMyGroups();
      }
    }
    else if(force || _allGroups == null){
      _loadGroups();
    }
  }

  List<Group> _sortGroups(List<Group> groups) {
    if (AppCollection.isCollectionEmpty(groups)) {
      return groups;
    }
    groups.sort((group1, group2) {
      int cmp = group1.category.compareTo(group2.category);
      if (cmp != 0) {
        return cmp;
      } else {
        return group1.title.compareTo(group2.title);
      }
    });
    return groups;
  }

  static String _tagFilterToDisplayString(_TagFilter tagFilter) {
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
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx("panel.groups_home.label.heading","Groups"),
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: Styles().fontFamilies.extraBold,
              letterSpacing: 1.0),
        ),
      ),
      body: Column(children: <Widget>[
        _buildTabs(),
        _buildFilterButtons(),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorPrimary), ),)
              : Stack(
            alignment: AlignmentDirectional.topCenter,
            children: <Widget>[
              Container(color: Styles().colors.background, child:
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
      ],),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildTabs(){
    return Container(
      color: Styles().colors.fillColorPrimary,
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
                    _GroupTabButton(title: Localization().getStringEx("panel.groups_home.button.all_groups.title", 'All groups'), hint: '', selected: !_myGroupsSelected ,onTap: onTapAllGroups),
                    Container(width: 15,),
                    _GroupTabButton(title: Localization().getStringEx("panel.groups_home.button.my_groups.title", 'My groups'), hint: '', selected: _myGroupsSelected, onTap: onTapMyGroups),
                    Container(width: 15,),
                    Flexible(child: Container()),
                    _GroupTabButton(title: Localization().getStringEx("panel.groups_home.button.create_group.title", 'Create'), hint: '', rightIcon: Image.asset('images/icon-plus.png', height: 10, width: 10,), selected: false, onTap: onTapCreate),
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
    bool hasCategories = AppCollection.isCollectionNotEmpty(_categories);
    return _isFilterLoading || _myGroupsSelected
      ? Container()
      : Container(
        width: double.infinity,
        color: Styles().colors.white,
        child: Padding(
            padding: const EdgeInsets.only(left: 6, right: 16, bottom: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Visibility(visible: hasCategories, child: FilterSelectorWidget(
                  label: _selectedCategory,
                  hint: "",
                  active: (_activeFilterType == _FilterType.category),
                  visible: true,
                  onTap: (){
                    Analytics.instance.logSelect(target: "GroupFilter - Category");
                    setState(() {
                      _activeFilterType = (_activeFilterType != _FilterType.category) ? _FilterType.category : _FilterType.none;
                    });
                  }
                )),
                Visibility(visible: hasCategories, child: Container(width: 8)),
                FilterSelectorWidget(
                  label: AppString.getDefaultEmptyString(value: _tagFilterToDisplayString(_selectedTagFilter)),
                  hint: "",
                  active: (_activeFilterType == _FilterType.tags),
                  visible: true,
                  onTap: (){
                    Analytics.instance.logSelect(target: "GroupFilter - Tags");
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
                      color: Styles().colors.fillColorSecondary,
                      excludeFromSemantics: true,
                      width: 25,
                      height: 25,
                    ),
                    onPressed: () {
                      Analytics.instance.logSelect(target: "Search");
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
        itemCount: _activeFilterList.length,
        itemBuilder: (context, index) {
          return FilterListItemWidget(
            label: AppString.getDefaultEmptyString(value: _getFilterItemLabel(index)),
            selected: _isFilterItemSelected(index),
            onTap: ()=> _onTapFilterEntry(_activeFilterList[index]),
            selectedIconRes: "images/checkbox-selected.png",
            unselectedIconRes: "images/oval-orange.png"
          );
        }
    );
  }

  bool _isFilterItemSelected(int filterListIndex) {
    if (AppCollection.isCollectionEmpty(_activeFilterList) || filterListIndex >= _activeFilterList.length) {
      return false;
    }
    switch (_activeFilterType) {
      case _FilterType.category:
        return (_selectedCategory == _activeFilterList[filterListIndex]);
      case _FilterType.tags:
        return (_selectedTagFilter == _activeFilterList[filterListIndex]);
      default:
        return false;
    }
  }

  String _getFilterItemLabel(int filterListIndex) {
    if (AppCollection.isCollectionEmpty(_activeFilterList) || filterListIndex >= _activeFilterList.length) {
      return null;
    }
    switch (_activeFilterType) {
      case _FilterType.category:
        return _activeFilterList[filterListIndex];
      case _FilterType.tags:
        return _tagFilterToDisplayString(_activeFilterList[filterListIndex]);
      default:
        return null;
    }
  }

  Widget _buildFilterContentEx({@required int itemCount, @required IndexedWidgetBuilder itemBuilder}){

    return Semantics(child:Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 40),
        child: Semantics(child:Container(
          decoration: BoxDecoration(
            color: Styles().colors.fillColorSecondary,
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
                  color: Styles().colors.fillColorPrimaryTransparent03,
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
    return Column(
      children: [
        _buildMyGroupsSection(),
        _buildMyPendingGroupsSection(),
      ],
    );
  }

  Widget _buildMyGroupsSection(){
    if(AppCollection.isCollectionEmpty(_myGroups) && AppCollection.isCollectionEmpty(_myPendingGroups)) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        child: Text(
          Localization().getStringEx("panel.groups_home.label.no_results", "There are no groups for the desired filter"),
          style: TextStyle(
              fontFamily: Styles().fontFamilies.regular,
              fontSize: 16,
              color: Styles().colors.textBackground
          ),
        ),
      );
    } else {
      List<Widget> widgets = [];
      if(AppCollection.isCollectionNotEmpty(_myGroups)) {
        widgets.add(Container(height: 8,));
        for (Group group in _myGroups) {
          widgets.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: GroupCard(group: group, displayType: GroupCardDisplayType.myGroup),
          ));
        }
        widgets.add(Container(height: 8,));
      }

      return Column(children: widgets,);
    }
  }

  Widget _buildMyPendingGroupsSection(){
    if(AppCollection.isCollectionNotEmpty(_myPendingGroups)) {
      List<Widget> widgets = [];
      widgets.add(Container(height: 16,));
      widgets.add(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(Localization().getStringEx("panel.groups_home.label.pending", "Pending"),
            style: TextStyle(
                fontFamily: Styles().fontFamilies.bold,
                fontSize: 20,
                color: Styles().colors.fillColorPrimary
            ),
          )
        )
      );
      widgets.add(Container(height: 8,));
      for (Group group in _myPendingGroups) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: GroupCard(group: group, displayType: GroupCardDisplayType.myGroup,),
        ));
      }
      return
        Stack(children: [
          Container(
            height: 112,
            color: Styles().colors.backgroundVariant,
            child:
            Column(children: [
              Container(height: 80,),
              Container(
                height: 32,
                child: CustomPaint(
                  painter: TrianglePainter(painterColor: Styles().colors.background),
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
    if(AppCollection.isCollectionNotEmpty(_allFilteredGroups)){
      List<Widget> widgets = [];
      widgets.add(Container(height: 8,));
      for(Group group in _allFilteredGroups){
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: GroupCard(group: group),
        ));
      }
      return Column(children: widgets,);
    }
    else{
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        child: Text(
          Localization().getStringEx("panel.groups_home.label.no_results", "There are no groups for the desired filter"),
          style: TextStyle(
            fontFamily: Styles().fontFamilies.regular,
            fontSize: 16,
            color: Styles().colors.textBackground
          ),
        ),
      );
    }
  }

  void switchTabSelection() {
    setState((){ _myGroupsSelected = !_myGroupsSelected; });
    _loadContentFromNet();
  }

  void _onTapFilterEntry(dynamic entry) {
    String analyticsTarget;
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
    Analytics.instance.logSelect(target: "$analyticsTarget: $entry");
    setState(() {
      _activeFilterType = _FilterType.none;
    });
  }

  void onTapAllGroups(){
    if(_myGroupsSelected){
      switchTabSelection();
    }
  }

  void onTapMyGroups(){
    if(!_myGroupsSelected){
      switchTabSelection();
    }
  }

  void onTapCreate(){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>GroupCreatePanel()));
  }

  Future<void> _onPullToRefresh() async {
    Analytics.instance.logSelect(target: "Pull To Refresh");
    List<Group> groups = await Groups().loadGroups(myGroups: _myGroupsSelected);
    if (groups != null) {
      setState(() {
        if (_myGroupsSelected) {
          List<Group> sortedGroups = _sortGroups(groups);
          _myGroups = sortedGroups?.where((group) => group?.currentUserIsUserMember)?.toList();
          _myPendingGroups = sortedGroups?.where((group) => group?.currentUserIsPendingMember)?.toList();
        }
        else {
          _allGroups = _sortGroups(groups);
        }
      });
    }

  }

  ///////////////////////////////////
  // NotificationsListener

  void onNotification(String name, dynamic param){
    if(name == Groups.notifyUserMembershipUpdated){
      setState(() {});
    }
    else if ((name == Groups.notifyGroupCreated) || (name == Groups.notifyGroupUpdated) || (name == Groups.notifyGroupDeleted)) {
      if (mounted) {
        _loadGroups();
        _loadMyGroups();
      }
    }
  }
}

class _GroupTabButton extends StatelessWidget{
  final String title;
  final String hint;
  final Image rightIcon;
  final GestureDragCancelCallback onTap;
  final bool selected;

  _GroupTabButton({@required this.title, @required this.hint, this.rightIcon, @required this.onTap, this.selected = false});

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
                      title,
                      style: TextStyle(
                        fontFamily: Styles().fontFamilies.bold,
                        fontSize: 16,
                        color: Styles().colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: Visibility(
                      visible: selected,
                      child: Container(height: 4, color: Styles().colors.fillColorSecondary,)
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

