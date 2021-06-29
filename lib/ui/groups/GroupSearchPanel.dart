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
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:sprintf/sprintf.dart';

class GroupsSearchPanel extends StatefulWidget {
  @override
  _GroupsSearchPanelState createState() => _GroupsSearchPanelState();
}

class _GroupsSearchPanelState extends State<GroupsSearchPanel> {
  List<Group> _groups;
  TextEditingController _searchController = TextEditingController();
  String _searchLabel = Localization().getStringEx('panel.groups_search.label.search_for', 'Searching only Groups Titles');
  int _resultsCount = 0;
  bool _resultsCountLabelVisible = false;
  bool _loading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx("panel.groups_search.header.title", "Search"),
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0),
        ),
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(left: 16),
            color: Colors.white,
            height: 48,
            child: Row(
              children: <Widget>[
                Flexible(
                    child:
                    Semantics(
                      label: Localization().getStringEx('panel.groups_search.field.search.title', 'Search'),
                      hint: Localization().getStringEx('panel.groups_search.field.search.hint', ''),
                      textField: true,
                      excludeSemantics: true,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (text) => _onTextChanged(text),
                        onSubmitted: (_) => _onTapSearch(),
                        autofocus: true,
                        cursorColor: Styles().colors.fillColorSecondary,
                        keyboardType: TextInputType.text,
                        style: TextStyle(
                            fontSize: 16,
                            fontFamily: Styles().fontFamilies.regular,
                            color: Styles().colors.textBackground),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    )
                ),
                Semantics(
                    label: Localization().getStringEx('panel.groups_search.button.clear.title', 'Clear'),
                    hint: Localization().getStringEx('panel.groups_search.button.clear.hint', ''),
                    button: true,
                    excludeSemantics: true,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: GestureDetector(
                        onTap: _onTapClear,
                        child: Image.asset(
                          'images/icon-x-orange.png',
                          width: 25,
                          height: 25,
                        ),
                      ),
                    )
                ),
                Semantics(
                  label: Localization().getStringEx('panel.groups_search.button.search.title', 'Search'),
                  hint: Localization().getStringEx('panel.groups_search.button.search.hint', ''),
                  button: true,
                  excludeSemantics: true,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: GestureDetector(
                      onTap: _onTapSearch,
                      child: Image.asset(
                        'images/icon-search.png',
                        color: Styles().colors.fillColorSecondary,
                        width: 25,
                        height: 25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
              padding: EdgeInsets.all(16),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                      fontSize: 20, color: Styles().colors.fillColorPrimary),
                  children: <TextSpan>[
                    TextSpan(
                        text: _searchLabel,
                        style: TextStyle(
                          fontFamily: Styles().fontFamilies.semiBold,
                        )),
                  ],
                ),
              )),
          Visibility(
            visible: _resultsCountLabelVisible,
            child: Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 24),
              child: Text(_resultsInfoText,
                style: TextStyle(
                    fontSize: 16,
                    fontFamily: Styles().fontFamilies.regular,
                    color: Styles().colors.textBackground),
              ),
            ),
          ),
          _buildListViewWidget()
        ],
      ),
    );
  }

  Widget _buildListViewWidget() {
    if (_loading) {
      return Container(
        child: Align(
          alignment: Alignment.center,
          child: CircularProgressIndicator(),
        ),
      );
    }
    int groupsCount = AppCollection.isCollectionNotEmpty(_groups) ? _groups.length : 0;
    Widget groupsContent;
    if (groupsCount > 0) {
      groupsContent = ListView.separated(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        separatorBuilder: (context, index) => Divider(
          color: Colors.transparent,
        ),
        itemCount: groupsCount,
        itemBuilder: (context, index) {
          Group group = _groups[index];
          GroupCard groupCard = GroupCard(group: group);
          return Padding(padding: EdgeInsets.only(top: 16), child: groupCard);
        }
      );
    }
    return groupsContent ?? Container();
  }

  String get _resultsInfoText {
    if (_resultsCount == 0) {
      return Localization().getStringEx('panel.groups_search.label.not_found', 'No results found');
    } else if (_resultsCount == 1) {
      return Localization().getStringEx('panel.groups_search.label.found_single', '1 result found');
    } else if (_resultsCount > 1) {
      return sprintf(Localization().getStringEx('panel.groups_search.label.found_multi', '%d results found'), [_resultsCount]);
    } else {
      return "";
    }
  }

  void _onTapSearch() {
    Analytics.instance.logSelect(target: "Search Groups");
    FocusScope.of(context).requestFocus(new FocusNode());
    _setLoading(true);
    String searchValue = _searchController.text;
    if (AppString.isStringEmpty(searchValue)) {
      return;
    }
    searchValue = searchValue.trim();
    if (AppString.isStringEmpty(searchValue)) {
      return;
    }
    _setLoading(true);
    Groups().searchGroups(searchValue).then((groups) {
      _groups = groups;
      _resultsCount = _groups?.length ?? 0;
      _resultsCountLabelVisible = true;
      _searchLabel = Localization().getStringEx('panel.groups_search.label.results_for', 'Results for ') + _searchController.text;
      _setLoading(false);
    });
  }

  void _onTapClear() {
    Analytics.instance.logSelect(target: "Clear Search");
    if (AppString.isStringEmpty(_searchController.text)) {
      Navigator.pop(context);
      return;
    }
    _groups = null;
    _searchController.clear();
    _resultsCountLabelVisible = false;
    setState(() {
      _searchLabel = Localization().getStringEx('panel.groups_search.label.search_for', 'Searching only Groups Titles');
    });
  }

  void _onTextChanged(String text) {
    _resultsCountLabelVisible = false;
    setState(() {
      _searchLabel = Localization().getStringEx('panel.groups_search.label.search_for', 'Searching only Groups Titles');
    });
  }

  void _setLoading(bool loading) {
    setState(() {
      _loading = loading;
    });
  }
}
