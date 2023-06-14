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
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ext/Group.dart';

class GroupMembersSelectionPanel extends StatefulWidget {
  final String? groupId;
  final GroupPrivacy? groupPrivacy;
  final List<Member>? selectedMembers;
  final List<Member>? allMembers;

  GroupMembersSelectionPanel({this.selectedMembers, this.allMembers, this.groupPrivacy, this.groupId});

  @override
  _GroupMembersSelectionState createState() => _GroupMembersSelectionState();
}

class _GroupMembersSelectionState extends State<GroupMembersSelectionPanel> {
  Group? _group;
  List<Member>? _allMembers;
  List<Member>? _selectedMembers;

  bool _searchView = false;
  TextEditingController _searchController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initGroup();
    _initMembers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool hasGroupMembers = CollectionUtils.isNotEmpty(_selectedMembers);

    return new WillPopScope(
      onWillPop: () async{
        _onTapDone();
        return false;
      },
      child: Scaffold(
        appBar: HeaderBar(
          title: Localization().getStringEx('panel.group.members.header.title', 'Members'),
          onLeading: _onTapDone,
        ),
        backgroundColor: Styles().colors!.white,
        body: Stack(alignment: Alignment.center, children: <Widget>[
          Column(
            children:[
              Expanded(child:
                SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    // Padding(padding: EdgeInsets.only(top: 12), child: Row(children: [
                    //   Expanded(child: Container()),
                    //   RoundedButton(label: Localization().getStringEx('panel.group.members.button.done.title', 'Done'), contentWeight: 0.0, textColor: Styles().colors!.fillColorPrimary, borderColor: Styles().colors!.fillColorSecondary, backgroundColor: Styles().colors!.white, onTap: _onTapDone)
                    // ])),
                    Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                                style: Styles().textStyles?.getTextStyle("widget.title.light.regular")
                              ),
                              Styles().images?.getImage('check-circle-outline-gray-white', excludeFromSemantics: true) ?? Container(),
                              Expanded(
                                  child:Text(
                                    Localization().getStringEx("panel.group.members.label.follow_team.title", " to select members"),
                                    overflow: TextOverflow.ellipsis,
                                    style: Styles().textStyles?.getTextStyle("widget.title.light.regular")
                                  )
                              )
                            ],
                          ),
                        )
                    ),

                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      Padding(padding: EdgeInsets.only(top: 12), child: _buildSearchWidget()),
                      Visibility(visible: _searchView, child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text(Localization().getStringEx('panel.group.members.list.search.label', "SEARCH")))),
                      Visibility(visible: _searchView, child: _buildMembersWidget(_filterMembers(_searchController.text))),
                      Visibility(visible: (!_searchView) && hasGroupMembers, child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text(Localization().getStringEx('panel.group.members.list.selected.label', "To: ")))),
                      Visibility(visible: (!_searchView) && hasGroupMembers, child: _buildMembersWidget(_selectedMembers)),
                      Visibility(visible: true, child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text(Localization().getStringEx('panel.group.members.list.all.label', "ALL MEMBERS")))),
                      Visibility(visible: true, child: _buildMembersWidget(_allMembers))
                    ])),
                  ])),
              ),
              Padding(padding: EdgeInsets.only(top: 24, bottom: 24), child:
              RoundedButton(label: Localization().getStringEx('panel.group.members.button.done.title', 'Done'),
                  textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                  contentWeight: 0.5,
                  borderColor: Styles().colors!.fillColorSecondary,
                  backgroundColor: Styles().colors!.white,
                  onTap: _onTapDone),
              ),
            ]),

          Visibility(visible: _loading, child: Container(alignment: Alignment.center, color: Styles().colors!.background, child: CircularProgressIndicator()))
        ])
    ));
  }

  void _initGroup(){
    _setLoading(true);
    Groups().loadGroup(widget.groupId).then((group) {
        _group = group;
        if(mounted){
          setState(() {
            _setLoading(false);
          });
        }
    });
  }

  void _initMembers() {
    // _setLoading(true);
    _selectedMembers = CollectionUtils.isNotEmpty(widget.selectedMembers) ? List.from(widget.selectedMembers!) : [];
    _allMembers = CollectionUtils.isNotEmpty(widget.allMembers) ? List.from(widget.allMembers!) : [];
    // _setLoading(false);
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

  bool _isMemberSelected(Member member) {
    return _selectedMembers?.contains(member) ?? false;
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
    _storeSelection();
    Navigator.of(context).pop(_selectedMembers);
  }

  void _storeSelection(){ //Too much logic. If we need it somewhere else we should move it in Service class
    const int maxStoredSelections = 5;

    Map<String, List<List<Member>>>? selectionsTable = Storage().groupMembersSelection;
    if(selectionsTable == null){
      selectionsTable = Map<String, List<List<Member>>>();
  }

    List<List<Member>>? groupMemberSelection = widget.groupId!=null? selectionsTable[widget.groupId] : null;
    if(groupMemberSelection == null){
      groupMemberSelection = [];
      selectionsTable[(widget.groupId)!] = groupMemberSelection;
    }

    if(_selectedMembers!=null && widget.groupId!=null) {
      if(!_memberSelectionsContainsSelection(groupMemberSelection, _selectedMembers!)) {
        groupMemberSelection.add(_selectedMembers!);
        if(groupMemberSelection.length> maxStoredSelections){ //Support Max Count
          groupMemberSelection.removeAt(0);
        }
      }
    }

    Storage().groupMembersSelection = selectionsTable;
  }

  void _switchMember(Member member) {
    if (_selectedMembers == null) {
      _selectedMembers = [];
    }
    if (_selectedMembers!.contains(member)) {
      _selectedMembers!.remove(member);
    } else {
      _selectedMembers!.add(member);
    }
    setState(() {});
  }

  Widget _buildSearchWidget() {
    return
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Text(Localization().getStringEx("panel.group.members.list.search.description","Search for a particular member:"),style: Styles().textStyles?.getTextStyle("widget.message.regular.fat"),)), //TBD localize
          Container(
          padding: EdgeInsets.symmetric(horizontal: 0),
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
                      style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"),
                      decoration: InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0)))
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
                    child: Styles().images?.getImage('clear'),
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
                    child: Styles().images?.getImage('search'),
                  ))
            ],
          ),
        )
      ],);
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

    if(_allowSnowName && StringUtils.isNotEmpty(member.name)) {
      result += member.name ?? "";
    }
    if(_allowSnowEmail && StringUtils.isNotEmpty(member.email)){
      result += StringUtils.isNotEmpty(result) ? "\r\n" : "";
      result += member.email ?? "";
    }
    if(_allowSnowID && StringUtils.isNotEmpty(member.netId)) {
      result += StringUtils.isNotEmpty(result) ? "\r\n" : "";
      result += member.netId ?? "";
    }

    return result;
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

  bool get _allowSnowName{
    if(_group == null){
      return false;
    }
    MemberInfoPreferences? infoPref = _group?.settings?.memberInfoPreferences;

    return _group!.currentUserIsAdmin ||
        (infoPref?.allowMemberInfo == true &&
        infoPref?.viewMemberName == true);
  }

  bool get _allowSnowEmail{
    if(_group == null){
      return false;
    }
    MemberInfoPreferences? infoPref = _group?.settings?.memberInfoPreferences;

    return _group!.currentUserIsAdmin ||
        (infoPref?.allowMemberInfo == true &&
            infoPref?.viewMemberEmail == true);
  }

  bool get _allowSnowID{
    if(_group == null){
      return false;
    }
    MemberInfoPreferences? infoPref = _group?.settings?.memberInfoPreferences;

    return _group!.currentUserIsAdmin ||
        (infoPref?.allowMemberInfo == true &&
            infoPref?.viewMemberNetId == true);
  }
  //Utils TBD better way is to create class MemberSelection which will override == properly
  bool _memberSelectionsContainsSelection(List<List<Member>> collection, List<Member> item){
    return collection.any(
            (List<Member> selection) => //We have a selection
              selection.length == item.length && //Which has same length as the desired one
                selection.every((member) => // And for every member
                (item.any((element) => element.userId == member.userId)))); // Items has member with same userId
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
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                      Styles().images?.getImage(selected ? 'check-circle-filled' : 'check-circle-outline-gray') ?? Container(),
                      SizedBox(width: 16),
                      Expanded(
                          child:
                          Container(
                            child: Text(label,
                              style: Styles().textStyles?.getTextStyle("widget.title.regular.fat")))),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: groupMemberStatusToColor(member?.status) ?? Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                        child: Center(
                          child: Text(groupMemberStatusToDisplayString(member?.status)?.toUpperCase() ?? "",
                            style: Styles().textStyles?.getTextStyle("widget.title.light.little.fat")
                          ),
                        ),
                      ),
                    ])))));
  }
}