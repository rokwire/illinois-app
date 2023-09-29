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
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class GroupsSearchPanel extends StatefulWidget {
  final bool researchProject;

  GroupsSearchPanel({Key? key, this.researchProject = false }) : super(key: key);

  @override
  _GroupsSearchPanelState createState() => _GroupsSearchPanelState();
}

class _GroupsSearchPanelState extends State<GroupsSearchPanel>  implements NotificationsListener {
  List<Group>? _groups;
  String? _searchValue;
  TextEditingController _searchController = TextEditingController();
  String? _searchLabel;
  int _resultsCount = 0;
  bool _resultsCountLabelVisible = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _searchLabel = _defaultSearchLabelValue;

    NotificationService().subscribe(this, [
      Auth2.notifyLoginSucceeded,
      Auth2.notifyLogout,
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  ///////////////////////////////////
  // NotificationsListener

  void onNotification(String name, dynamic param){
    if ((name == Auth2.notifyLoginSucceeded) ||  (name == Auth2.notifyLogout)) {
      // Reload content with some delay, do not unmount immidately GroupsCard that could have updated the login state.
      Future.delayed(Duration(microseconds: 300), () {
        if (mounted) {
          _refreshSearch();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.groups_search.header.title", "Search"),
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
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
                        cursorColor: Styles().colors!.fillColorSecondary,
                        keyboardType: TextInputType.text,
                        style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"),
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
                        child: Styles().images?.getImage('close', excludeFromSemantics: true),
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
                      child: Styles().images?.getImage('search', excludeFromSemantics: true),
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
                  style: Styles().textStyles?.getTextStyle("widget.title.large"),
                  children: <TextSpan>[
                    TextSpan(
                        text: _searchLabel,
                        style: Styles().textStyles?.getTextStyle("widget.title.large.semi_fat"),)
                  ],
                ),
              )),
          Visibility(
            visible: _resultsCountLabelVisible,
            child: Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 24),
              child: Text(_resultsInfoText!,
                style: Styles().textStyles?.getTextStyle("widget.item.regular.thin")
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
    int groupsCount = CollectionUtils.isNotEmpty(_groups) ? _groups!.length : 0;
    Widget? groupsContent;
    if (groupsCount > 0) {
      groupsContent = ListView.separated(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        separatorBuilder: (context, index) => Divider(
          color: Colors.transparent,
        ),
        itemCount: groupsCount,
        itemBuilder: (context, index) {
          Group? group = _groups![index];
          GroupCard groupCard = GroupCard(group: group);
          return Padding(padding: EdgeInsets.only(top: 16), child: groupCard);
        }
      );
    }
    return groupsContent ?? Container();
  }

  String? get _resultsInfoText {
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

  void _refreshSearch() {
    if (StringUtils.isNotEmpty(_searchValue)) {
      setState(() { _loading = true; });
      Groups().searchGroups(_searchValue!, researchProjects: widget.researchProject, researchOpen: widget.researchProject).then((groups) {
        if (mounted) {
          setState(() {
            if (groups != null) {
              _groups = _buildVisibleGroups(groups);
              _resultsCount = _groups?.length ?? 0;
              _resultsCountLabelVisible = true;
              _searchLabel = Localization().getStringEx('panel.groups_search.label.results_for', 'Results for ') + _searchController.text;
            }
            _loading = false;
          });
        }
      });
    }
  }

  void _onTapSearch() {
    Analytics().logSelect(target: "Search Groups");
    FocusScope.of(context).requestFocus(new FocusNode());
    _setLoading(true);
    String searchValue = _searchController.text;
    if (StringUtils.isEmpty(searchValue)) {
      return;
    }
    searchValue = searchValue.trim();
    if (StringUtils.isEmpty(searchValue)) {
      return;
    }
    _setLoading(true);
    Groups().searchGroups(searchValue, researchProjects: widget.researchProject, researchOpen: widget.researchProject).then((groups) {
      _groups = _buildVisibleGroups(groups);
      _searchValue = searchValue;
      _resultsCount = _groups?.length ?? 0;
      _resultsCountLabelVisible = true;
      _searchLabel = Localization().getStringEx('panel.groups_search.label.results_for', 'Results for ') + _searchController.text;
      _setLoading(false);
    });
  }

  void _onTapClear() {
    Analytics().logSelect(target: "Clear Search");
    if (StringUtils.isEmpty(_searchController.text)) {
      Navigator.pop(context);
      return;
    }
    _groups = null;
    _searchValue = null;
    _searchController.clear();
    _resultsCountLabelVisible = false;
    setState(() {
      _searchLabel = _defaultSearchLabelValue;
    });
  }

  void _onTextChanged(String text) {
    _resultsCountLabelVisible = false;
    setState(() {
      _searchLabel = _defaultSearchLabelValue;
    });
  }

  String get _defaultSearchLabelValue {
    return widget.researchProject ?
      'Searching Only Research Project Titles' :
      Localization().getStringEx('panel.groups_search.label.search_for', 'Searching Only Groups Titles');
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _loading = loading;
      });
    }
  }

  List<Group>? _buildVisibleGroups(List<Group>? allGroups) {
    List<Group>? visibleGroups;
    if (allGroups != null) {
      visibleGroups = <Group>[];
      for (Group group in allGroups) {
        if (group.isVisible) {
          ListUtils.add(visibleGroups, group);
        }
      }
    }
    return visibleGroups;
  }
}
