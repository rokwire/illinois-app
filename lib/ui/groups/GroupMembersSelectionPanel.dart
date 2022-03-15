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
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

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
          title: Localization().getStringEx('panel.group.members.header.title', 'Group Members'),
        ),
        backgroundColor: Styles().colors!.background,
        body: Stack(alignment: Alignment.center, children: <Widget>[
          SingleChildScrollView(
              child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Padding(padding: EdgeInsets.only(top: 12), child: Row(children: [
                  Expanded(child: Container()),
                  RoundedButton(label: Localization().getStringEx('panel.group.members.button.done.title', 'Done'), contentWeight: 0.0, textColor: Styles().colors!.fillColorPrimary, borderColor: Styles().colors!.fillColorSecondary, backgroundColor: Styles().colors!.white, onTap: _onTapDone)
                ])),
                Padding(padding: EdgeInsets.only(top: 12), child: _buildSearchWidget()),
                Visibility(visible: _searchView, child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text(Localization().getStringEx('panel.group.members.list.search.label', "SEARCH")))),
                Visibility(visible: _searchView, child: _buildMembersWidget(_filterMembers(_searchController.text))),
                Visibility(visible: hasGroupMembers, child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text(Localization().getStringEx('panel.group.members.list.selected.label', "SELECTED")))),
                Visibility(visible: hasGroupMembers, child: _buildMembersWidget(_groupMembers)),
                Visibility(visible: !_searchView, child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text(Localization().getStringEx('panel.group.members.list.all.label', "ALL MemberS")))),
                Visibility(visible: !_searchView, child: _buildMembersWidget(_allMembers))
              ]))),
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
      memberWidgets.add(_MemberSelectionWidget(label: member.displayName, selected: _isMemberSelected(member), onTap: () => _onMemberTaped(member)));
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
    return _groupMembers?.contains(member) ?? false;
  }

  void _onMemberTaped(Member member) {
    Analytics().logSelect(target: "Group Member: $member");
    _hideKeyboard();
    _switchMember(member);
    AppSemantics.announceCheckBoxStateChange(context, _isMemberSelected(member), member.displayName);
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

  List<Member>? _filterMembers(String key) {
    if (StringUtils.isEmpty(key)) {
      return _allMembers;
    } else if (CollectionUtils.isNotEmpty(_allMembers)) {
      return _allMembers!.where((Member member) => member.displayName.toLowerCase().contains(key.toLowerCase())).toList();
    }
    return null;
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
  final GestureTapCallback? onTap;
  final bool selected;

  _MemberSelectionWidget({required this.label, this.onTap, this.selected = false});

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
                      Flexible(
                          child: Text(label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: Styles().fontFamilies!.bold, color: Styles().colors!.fillColorPrimary, fontSize: 16))),
                      Image.asset(selected ? 'images/deselected-dark.png' : 'images/deselected.png')
                    ])))));
  }
}