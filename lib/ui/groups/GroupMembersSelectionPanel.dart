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

import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ext/Group.dart';

enum _DetailTab { Name, Uin, Email}

class GroupMembersSelectionPanel extends StatefulWidget {
  final List<Member>? selectedMembers;
  final List<Member>? allMembers;

  GroupMembersSelectionPanel({this.selectedMembers, this.allMembers});

  @override
  _GroupMembersSelectionState createState() => _GroupMembersSelectionState();
}

class _GroupMembersSelectionState extends State<GroupMembersSelectionPanel> {

  List<Member>? _allMembers;
  List<Member>? _groupMembers;

  bool _searchView = false;
  TextEditingController _searchController = TextEditingController();

  bool _loading = false;

  _DetailTab _currentTab = _DetailTab.Name;

  @override
  void initState() {
    super.initState();
    _initMembers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool hasGroupMembers = CollectionUtils.isNotEmpty(_groupMembers);

    return Scaffold(
        appBar: HeaderBar(
          title: Localization().getStringEx('panel.group.members.header.title', 'Members'),
          onLeading: _onTapDone,
        ),
        backgroundColor: Styles().colors!.white,
        body: Stack(alignment: Alignment.center, children: <Widget>[
          SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                // Padding(padding: EdgeInsets.only(top: 12), child: Row(children: [
                //   Expanded(child: Container()),
                //   RoundedButton(label: Localization().getStringEx('panel.group.members.button.done.title', 'Done'), contentWeight: 0.0, textColor: Styles().colors!.fillColorPrimary, borderColor: Styles().colors!.fillColorSecondary, backgroundColor: Styles().colors!.white, onTap: _onTapDone)
                // ])),
                Container(
                  padding: EdgeInsets.only(left: 12,bottom: 32),
                  color: Styles().colors!.fillColorPrimary!,
                  child: Semantics(
                    label: Localization().getStringEx("panel.group.members.label.tap_to_follow_team.title", "Tap the checkmark to select members"),
                    hint: Localization().getStringEx("panel.group.members.label.tap_to_follow_team.hint", ""),
                    excludeSemantics: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          Localization().getStringEx("panel.group.members.label.tap_the.title", "Tap the "),
                          style: TextStyle(
                              fontFamily: Styles().fontFamilies!.medium,
                              color: Styles().colors!.white,
                              fontSize: 16),
                        ),
                        Image.asset(
                            'images/icon-check-example.png', excludeFromSemantics: true, color: Styles().colors!.white,),
                        Expanded(
                            child:Text(
                              Localization().getStringEx("panel.group.members.label.follow_team.title", " to select members"),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontFamily: Styles().fontFamilies!.medium,
                                  color: Styles().colors!.white,
                                  fontSize: 16),
                            )
                        )
                      ],
                    ),
                  )
                ),
                _buildTabs(),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Padding(padding: EdgeInsets.only(top: 12), child: _buildSearchWidget()),
                  Visibility(visible: _searchView, child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text(Localization().getStringEx('panel.group.members.list.search.label', "SEARCH")))),
                  Visibility(visible: _searchView, child: _buildMembersWidget(_filterMembers(_searchController.text))),
                  Visibility(visible: hasGroupMembers, child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text(Localization().getStringEx('panel.group.members.list.selected.label', "SELECTED")))),
                  Visibility(visible: hasGroupMembers, child: _buildMembersWidget(_groupMembers)),
                  Visibility(visible: !_searchView, child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text(Localization().getStringEx('panel.group.members.list.all.label', "ALL MemberS")))),
                  Visibility(visible: !_searchView, child: _buildMembersWidget(_allMembers))
                ]))
              ])),
          Visibility(visible: _loading, child: Container(alignment: Alignment.center, color: Styles().colors!.background, child: CircularProgressIndicator()))
        ])
    );
  }

  void _initMembers() {
    _setLoading(true);
    _groupMembers = CollectionUtils.isNotEmpty(widget.selectedMembers) ? List.from(widget.selectedMembers!) : [];
    _allMembers = CollectionUtils.isNotEmpty(widget.allMembers) ? List.from(widget.allMembers!) : [];
    _setLoading(false);
  }

  Widget _buildMembersWidget(List<Member>? members) {
    if (CollectionUtils.isEmpty(members)) {
      return Container();
    }

    List<Widget> memberWidgets = [];
    for (Member member in members!) {
      if (CollectionUtils.isNotEmpty(memberWidgets)) {
        memberWidgets.add(Container(height: 1, color: Styles().colors!.surfaceAccent));
      }
      memberWidgets.add(_MemberSelectionWidget(member: member, label: _getMemberDisplayData(member), selected: _isMemberSelected(member), onTap: () => _onMemberTaped(member)));
    }
    return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
            foregroundDecoration: BoxDecoration(
              border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1.0),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(children: memberWidgets)));
  }

  Widget _buildTabs() {
    List<Widget> tabs = [];
    for (_DetailTab tab in _DetailTab.values) {
      String title;
      switch (tab) {
        case _DetailTab.Name:
          title = Localization().getStringEx("panel.group.members.button.events.title", 'Name');
          break;
        case _DetailTab.Uin:
          title = Localization().getStringEx("panel.group.members.button.posts.title", 'UIN');
          break;
        case _DetailTab.Email:
          title = Localization().getStringEx("panel.group.members.button.polls.title", 'Email');
          break;
      }
      bool isSelected = (_currentTab == tab);

      if (0 < tabs.length) {
        tabs.add(Padding(
          padding: EdgeInsets.only(left: 6),
          child: Container(),
        ));
      }

      Widget tabWidget = RoundedButton(
          label: title,
          backgroundColor: isSelected ? Styles().colors!.fillColorPrimary : Styles().colors!.background,
          textColor: (isSelected ? Colors.white : Styles().colors!.fillColorPrimary),
          fontFamily: isSelected ? Styles().fontFamilies!.bold : Styles().fontFamilies!.regular,
          fontSize: 16,
          contentWeight: 0.0,
          borderColor: isSelected ? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent,
          borderWidth: 1,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          onTap: () => _onTab(tab));

      tabs.add(tabWidget);
    }

    return
      Row(
        children: [
          Expanded(
            child:
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              color: Colors.white,
              child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: tabs))
            )
          )
        ]);
  }

  bool _isMemberSelected(Member member) {
    return _groupMembers?.contains(member) ?? false;
  }

  void _onMemberTaped(Member member) {
    Analytics().logSelect(target: "Group Member: $member");
    _hideKeyboard();
    _switchMember(member);
    AppSemantics.announceCheckBoxStateChange(context, _isMemberSelected(member), _getMemberDisplayData(member));
  }

  void _onTapDone() {
    Analytics().logSelect(target: 'Done');
    _hideKeyboard();
    Navigator.of(context).pop(_groupMembers);
  }

  void _switchMember(Member member) {
    if (_groupMembers == null) {
      _groupMembers = [];
    }
    if (_groupMembers!.contains(member)) {
      _groupMembers!.remove(member);
    } else {
      _groupMembers!.add(member);
    }
    setState(() {});
  }

  Widget _buildSearchWidget() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      color: Styles().colors!.surface,
      height: 48,
      child: Row(
        children: <Widget>[
          Flexible(
            child: Semantics(
                label: Localization().getStringEx("panel.group.members.search.field.label", "Search for Members"),
                hint: Localization().getStringEx("panel.group.members.search.field.hint", "type the Member you are looking for"),
                textField: true,
                excludeSemantics: true,
                child: TextField(
                  controller: _searchController,
                  onChanged: (text) => _onTextChanged(text),
                  onSubmitted: (_) => () {},
                  cursorColor: Styles().colors!.fillColorSecondary,
                  keyboardType: TextInputType.text,
                  style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.textBackground),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                  ),
                )),
          ),
          Semantics(
            label: Localization().getStringEx("panel.group.members.search.cancel.label", "Cancel"),
            hint: Localization().getStringEx("panel.group.members.search.cancel.hint", "clear the search filter"),
            button: true,
            excludeSemantics: true,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: GestureDetector(
                onTap: () {
                  _onTapCancelSearch();
                },
                child: Image.asset(
                  'images/icon-x-orange.png',
                  width: 25,
                  height: 25,
                ),
              ),
            ),
          ),
          Semantics(
              label: Localization().getStringEx("panel.group.members.search.button.title", "Search"),
              hint: Localization().getStringEx("panel.group.members.search.button.hint", "filter Members"),
              button: true,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () {
                  _onSearchTap();
                },
                child: Image.asset(
                  'images/icon-search.png',
                  color: Styles().colors!.fillColorSecondary,
                  width: 25,
                  height: 25,
                ),
              ))
        ],
      ),
    );
  }

  void _onTextChanged(text) {
    setState(() {
      _searchView = StringUtils.isNotEmpty(text);
    });
  }

  void _onSearchTap() async {
    _hideKeyboard();
    setState(() {
      _searchView = true;
    });
  }

  void _onTapCancelSearch() {
    _hideKeyboard();
    setState(() {
      _searchController.clear();
      _searchView = false;
    });
  }

  void _onTab(_DetailTab tab) {
    Analytics().logSelect(target: "Tab: $tab");
    if (_currentTab != tab) {
      setState(() {
        _currentTab = tab;
      });
    }
  }

  List<Member>? _filterMembers(String key) {
    if (StringUtils.isEmpty(key)) {
      return _allMembers;
    } else if (CollectionUtils.isNotEmpty(_allMembers)) {
      return _allMembers!.where((Member member) => _getMemberDisplayData(member).toLowerCase().contains(key.toLowerCase())).toList();
    }
    return null;
  }

  String _getMemberDisplayData(Member member){
    String? result = "";
    switch(_currentTab){

      case _DetailTab.Name:
         result = member.name;
         break;
      case _DetailTab.Uin:
        result = member.userId;
        break;
      case _DetailTab.Email:
        result = member.email;
        break;
    }
    return result ?? "";
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _loading = loading;
      });
    }
  }
}

class _MemberSelectionWidget extends StatelessWidget {
  final String label;
  final Member? member;
  final GestureTapCallback? onTap;
  final bool selected;

  _MemberSelectionWidget({required this.label, this.onTap, this.selected = false, this.member});

  @override
  Widget build(BuildContext context) {
    return Semantics(
        label: label,
        value: (selected
            ? Localization().getStringEx(
          "toggle_button.status.checked",
          "checked",
        )
            : Localization().getStringEx("toggle_button.status.unchecked", "unchecked")) +
            ", " +
            Localization().getStringEx("toggle_button.status.checkbox", "checkbox"),
        excludeSemantics: true,
        child: GestureDetector(
            onTap: onTap,
            child: Container(
                color: Colors.white,
                child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                      Expanded(
                          child: Text(label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: Styles().fontFamilies!.bold, color: Styles().colors!.fillColorPrimary, fontSize: 16))),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: groupMemberStatusToColor(member?.status) ?? Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                        child: Center(
                          child: Text(groupMemberStatusToDisplayString(member?.status)?.toUpperCase() ?? "",
                            style: TextStyle(
                                fontFamily: Styles().fontFamilies!.bold,
                                fontSize: 12,
                                color: Styles().colors!.white
                            ),
                          ),
                        ),
                      ),
                      Container(width: 6,),
                      Image.asset(selected ? 'images/deselected-dark.png' : 'images/deselected.png')
                    ])))));
  }
}