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
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class GroupTagsPanel extends StatefulWidget {
  final List<String> selectedTags;

  GroupTagsPanel({this.selectedTags});

  @override
  _GroupTagsState createState() => _GroupTagsState();
}

class _GroupTagsState extends State<GroupTagsPanel> {

  List<String> _allTags;
  List<String> _groupTags;

  bool _searchView = false;
  TextEditingController _searchController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initTags();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool hasGroupTags = AppCollection.isCollectionNotEmpty(_groupTags);

    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
          context: context,
          titleWidget: Text(Localization().getStringEx('panel.group.tags.header.title', 'Group Tags'),
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0))),
      backgroundColor: Styles().colors.background,
      body: Stack(alignment: Alignment.center, children: <Widget>[
        SingleChildScrollView(
            child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Padding(padding: EdgeInsets.only(top: 12), child: Row(children: [
                Expanded(child: Container()),
                RoundedButton(label: Localization().getStringEx('panel.group.tags.button.done.title', 'Done'), width: 120, textColor: Styles().colors.fillColorPrimary, borderColor: Styles().colors.fillColorSecondary, backgroundColor: Styles().colors.white, onTap: _onTapDone)
              ])),
              Padding(padding: EdgeInsets.only(top: 12), child: _buildSearchWidget()),
              Visibility(visible: _searchView, child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text(Localization().getStringEx('panel.group.tags.list.search.label', "SEARCH")))),
              Visibility(visible: _searchView, child: _buildTagsWidget(_filterTags(_searchController?.text))),
              Visibility(visible: hasGroupTags, child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text(Localization().getStringEx('panel.group.tags.list.selected.label', "SELECTED")))),
              Visibility(visible: hasGroupTags, child: _buildTagsWidget(_groupTags)),
              Visibility(visible: !_searchView, child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text(Localization().getStringEx('panel.group.tags.list.all.label', "ALL TAGS")))),
              Visibility(visible: !_searchView, child: _buildTagsWidget(_allTags))
            ]))),
        Visibility(visible: _loading, child: Container(alignment: Alignment.center, color: Styles().colors.background, child: CircularProgressIndicator()))
      ])
    );
  }

  void _initTags() {
    _setLoading(true);
    _groupTags = AppCollection.isCollectionNotEmpty(widget.selectedTags) ? List.from(widget.selectedTags) : [];
    Groups().loadTags().then((List<String> tagList) {
      _allTags = tagList;
      _setLoading(false);
    });
  }

  Widget _buildTagsWidget(List<String> tags) {
    if (AppCollection.isCollectionEmpty(tags)) {
      return Container();
    }

    List<Widget> tagWidgets = [];
    for (String tag in tags) {
      if (AppCollection.isCollectionNotEmpty(tagWidgets)) {
        tagWidgets.add(Container(height: 1, color: Styles().colors.surfaceAccent));
      }
      tagWidgets.add(_TagSelectionWidget(label: tag, selected: _isTagSelected(tag), onTap: () => _onTagTaped(tag)));
    }
    return ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
                foregroundDecoration: BoxDecoration(
                  border: Border.all(color: Styles().colors.surfaceAccent, width: 1.0),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(children: tagWidgets)));
  }

  bool _isTagSelected(String tag) {
    return _groupTags?.contains(tag) ?? false;
  }

  void _onTagTaped(String tag) {
    Analytics.instance.logSelect(target: "Group Tag: $tag");
    _hideKeyboard();
    _switchTag(tag);
    AppSemantics.announceCheckBoxStateChange(context, _isTagSelected(tag), tag);
  }

  void _onTapDone() {
    _hideKeyboard();
    Navigator.of(context).pop(_groupTags);
  }

  void _switchTag(String tag) {
    if (_groupTags == null) {
      _groupTags = [];
    }
    if (_groupTags.contains(tag)) {
      _groupTags.remove(tag);
    } else {
      _groupTags.add(tag);
    }
    setState(() {});
  }

  Widget _buildSearchWidget() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      color: Styles().colors.surface,
      height: 48,
      child: Row(
        children: <Widget>[
          Flexible(
            child: Semantics(
                label: Localization().getStringEx("panel.group.tags.search.field.label", "Search for tags"),
                hint: Localization().getStringEx("panel.group.tags.search.field.hint", "type the tag you are looking for"),
                textField: true,
                excludeSemantics: true,
                child: TextField(
                  controller: _searchController,
                  onChanged: (text) => _onTextChanged(text),
                  onSubmitted: (_) => () {},
                  cursorColor: Styles().colors.fillColorSecondary,
                  keyboardType: TextInputType.text,
                  style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies.regular, color: Styles().colors.textBackground),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                  ),
                )),
          ),
          Semantics(
            label: Localization().getStringEx("panel.group.tags.search.cancel.label", "Cancel"),
            hint: Localization().getStringEx("panel.group.tags.search.cancel.hint", "clear the search filter"),
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
              label: Localization().getStringEx("panel.group.tags.search.button.title", "Search"),
              hint: Localization().getStringEx("panel.group.tags.search.button.hint", "filter tags"),
              button: true,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () {
                  _onSearchTap();
                },
                child: Image.asset(
                  'images/icon-search.png',
                  color: Styles().colors.fillColorSecondary,
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
      _searchView = AppString.isStringNotEmpty(text);
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

  List<String> _filterTags(String key) {
    if (AppString.isStringEmpty(key)) {
      return _allTags;
    } else if (AppCollection.isCollectionNotEmpty(_allTags)) {
      return _allTags.where((String tag) => tag.toLowerCase().contains(key.toLowerCase())).toList();
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

class _TagSelectionWidget extends StatelessWidget {
  final String label;
  final GestureTapCallback onTap;
  final bool selected;

  _TagSelectionWidget({@required this.label, this.onTap, this.selected = false});

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
                              style: TextStyle(fontFamily: Styles().fontFamilies.bold, color: Styles().colors.fillColorPrimary, fontSize: 16))),
                      Image.asset(selected ? 'images/deselected-dark.png' : 'images/deselected.png')
                    ])))));
  }
}