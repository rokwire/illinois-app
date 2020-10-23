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
import 'package:illinois/ui/groups/GroupCreatePanel.dart';
import 'package:illinois/ui/groups/GroupDetailPanel.dart';
import 'package:illinois/ui/widgets/FilterWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class GroupsHomePanel extends StatefulWidget{
  _GroupsHomePanelState createState() => _GroupsHomePanelState();
}

enum FilterType {none, category, type}

class _GroupsHomePanelState extends State<GroupsHomePanel> implements NotificationsListener{

  bool _isFilterLoading = false;
  bool _isGroupsLoading = false;
  bool get _isLoading => _isFilterLoading || _isGroupsLoading;

  List<Group> _groups;

  final String _allCategoriesValue = Localization().getStringEx("panel.groups_home.label.all_categories", "All categories");
  String _selectedCategory;
  List<String> _categories;

  final String _allTypesValue = Localization().getStringEx("panel.groups_home.label.all_types", "All types");
  String _selectedType;
  List<String> _types;

  FilterType __activeFilterType = FilterType.none;
  bool get _hasActiveFilter{ return _activeFilterType != FilterType.none; }
  FilterType get _activeFilterType{ return __activeFilterType; }
  set _activeFilterType(FilterType value){
    if(__activeFilterType != value){
      __activeFilterType = value;
      _loadGroups();
    }
  }

  List<String> get _activeFilterList{
    switch(_activeFilterType){
      case FilterType.type: return _types;
      case FilterType.category: return _categories;
      default: return null;
    }
  }

  bool _myGroupsSelected = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, Groups.notifyUserMembershipUpdated);
    _loadFilters().whenComplete((){
      _loadGroups();
    });
    Groups().updateUserMemberships();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  void _loadGroups(){
    setState(() {
      _isGroupsLoading = true;
    });
    String selectedCategory = _allCategoriesValue != _selectedCategory ? _selectedCategory : null;
    String selectedType = _allTypesValue != _allTypesValue ? _selectedType : null;
    Groups().loadGroups(category: selectedCategory, type: selectedType).then((List<Group> groups){
      _groups = groups;
    }).whenComplete((){
      setState(() {
        _isGroupsLoading = false;
      });
    });
  }

  Future<void> _loadFilters() async{
    setState(() {
      _isFilterLoading = true;
    });
    List<String> categories = List<String>();
    categories.add(_allCategoriesValue);
    categories.addAll(await Groups().categories);
    _categories = categories;
    _selectedCategory = _allCategoriesValue;

    List<String> types = List<String>();
    types.add(_allTypesValue);
    types.addAll(await Groups().types);
    _types = types;
    _selectedType = _allTypesValue;
    setState(() {
      _isFilterLoading = false;
    });
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
      body: Column(
        children: <Widget>[
          _buildTabs(),
          _buildFilterButtons(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(),)
                : Stack(
              alignment: AlignmentDirectional.topCenter,
              children: <Widget>[
                Container(
                  color: Styles().colors.background,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: <Widget>[
                        _buildGroupsContent(),
                      ],
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
        ],
      ),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildTabs(){
    return Container(
      color: Styles().colors.fillColorPrimary,
      padding: EdgeInsets.symmetric(horizontal: 12),
      child:
      Row(children: [
        Expanded(child:
//          SingleChildScrollView(
//            scrollDirection: Axis.horizontal,
//            child:
            Row(
              children: <Widget>[
                _GroupTabButton(title: 'All groups', hint: '', selected: !_myGroupsSelected ,onTap: onTapAllGroups),
                Container(width: 24,),
                _GroupTabButton(title: 'My groups', hint: '', selected: _myGroupsSelected, onTap: onTapMyGroups),
                Container(width: 24,),
                Expanded(child: Container()),
                _GroupTabButton(title: 'Create', hint: '', rightIcon: Image.asset('images/icon-plus.png', height: 10, width: 10,), selected: false, onTap: onTapCreate),
              ],
            )
//          )
        ),
      ],)
    );
  }

  Widget _buildFilterButtons(){
    return _isFilterLoading
      ? Container()
      : Container(
        width: double.infinity,
        color: Styles().colors.white,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                AppCollection.isCollectionEmpty(_categories)
                    ? Container()
                    : FilterSelectorWidget(
                    label: _selectedCategory,
                    hint: "",
                    active: (_activeFilterType == FilterType.category),
                    visible: true,
                    onTap: (){
                      Analytics.instance.logSelect(target: "GroupFilter");
                      setState(() {
                        _activeFilterType = (_activeFilterType != FilterType.category) ? FilterType.category : FilterType.none;
                      });
                    },
                  ),
                Container(width: 12,),
//                AppCollection.isCollectionEmpty(_types)
//                    ? Container()
//                    : FilterSelectorWidget(
//                      label: _selectedType,
//                      hint: "",
//                      active: (_activeFilterType == FilterType.type),
//                      visible: true,
//                      onTap: (){
//                        Analytics.instance.logSelect(target: "TypeFilter");
//                        setState(() {
//                          _activeFilterType = (_activeFilterType != FilterType.type) ? FilterType.type : FilterType.none;
//                        });
//                      },
//                    ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildFilterContent(){
    return _buildFilterContentEx(
        itemCount: _activeFilterList.length,
        itemBuilder: (context, index) {
          return FilterListItemWidget(
            label: _activeFilterList[index],
            selected: (_selectedCategory == _activeFilterList[index]),
            onTap: ()=> _onTapFilterEntry(_activeFilterList[index]),
          );
        }
    );
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
          _activeFilterType = FilterType.none;
        });
      },
        child: Container(color: Color(0x99000000)))
    );
  }

  Widget _buildGroupsContent(){
    if(AppCollection.isCollectionNotEmpty(_groups)){
      List<Widget> widgets = List<Widget>();
      for(Group group in _groups){
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _GroupCard(group: group),
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

  void switchTabSelection() {setState((){ _myGroupsSelected = !_myGroupsSelected; }); }

  void _onTapFilterEntry(String entry){
    String analyticsTarget;
    switch(_activeFilterType){
      case FilterType.type: _selectedType = entry; analyticsTarget = "TypeFilter"; break;
      case FilterType.category: _selectedCategory = entry; analyticsTarget = "CategoryFilter"; break;
      default: break;
    }
    Analytics.instance.logSelect(target: "$analyticsTarget: $entry");
    setState(() {
      _activeFilterType = FilterType.none;
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

  void onNotification(String name, dynamic param){
    if(name == Groups.notifyUserMembershipUpdated){
      setState(() {});
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
                    padding: EdgeInsets.symmetric(vertical: 10),
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

class _GroupCard extends StatelessWidget{
  final Group group;

  _GroupCard({@required this.group});

  bool get _isMember{
    return Groups().getUserMembership(group.id) != null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTapCard(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Styles().colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8))
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildHeading(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(group?.title ?? "",
                  style: TextStyle(
                      fontFamily: Styles().fontFamilies.extraBold,
                      fontSize: 20,
                      color: Styles().colors.fillColorPrimary
                  ),
                ),
              ),
              _buildMember()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeading(){
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildCertified(),
        Container(width: group.certified ? 8 : 0,),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8, left: 0),
            child: Text(group?.category ?? "" ,
              style: TextStyle(
                  fontFamily: Styles().fontFamilies.bold,
                  fontSize: 12,
                  color: Styles().colors.mediumGray
              ),
            ),
          ),
        ),
        _buildSaved()
      ],
    );
  }

  Widget _buildCertified(){
    return group.certified
        ? Image.asset('images/icon-certified.png')
        : Container();
  }

  Widget _buildSaved(){
    return Image.asset('images/icon-star-selected.png');
    //return true ? Image.asset('images/icon-star-selected.png') : Image.asset('images/icon-star.png');
  }

  Widget _buildMember(){
    return _isMember
        ? Row(
          children: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Styles().colors.fillColorPrimary,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
              child: Center(
                child: Text("MEMBER",
                  style: TextStyle(
                      fontFamily: Styles().fontFamilies.bold,
                      fontSize: 12,
                      color: Styles().colors.white
                  ),
                ),
              ),
            ),
            Expanded(child: Container(),),
          ],
        )
        : Container();
  }

  void _onTapCard(BuildContext context) {
    Analytics.instance.logSelect(target: "${group.title}");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupDetailPanel(groupId: group.id)));
  }
}

