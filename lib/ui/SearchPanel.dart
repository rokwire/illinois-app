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
import 'package:illinois/service/ExploreService.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/explore/ExploreDetailPanel.dart';
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';
import 'package:sprintf/sprintf.dart';

import 'athletics/AthleticsGameDetailPanel.dart';

class SearchPanel extends StatefulWidget {
  final Map<String, dynamic>? searchData;

  const SearchPanel({Key? key, this.searchData}) : super(key: key);

  @override
  _SearchPanelState createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  TextEditingController _textEditingController = TextEditingController();
  String? _searchLabel = Localization().getStringEx('panel.search.label.search_for', 'Searching only Events Titles');
  int _resultsCount = 0;
  bool _resultsCountLabelVisible = false;
  bool _loading = false;
  List<Explore>? _events;

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx("panel.search.header.title", "Search")!,
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0),
        ),
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors!.background,
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
                        label: Localization().getStringEx('panel.search.field.search.title', 'Search'),
                        hint: Localization().getStringEx('panel.search.field.search.hint', ''),
                        textField: true,
                        excludeSemantics: true,
                        child: TextField(
                          controller: _textEditingController,
                          onChanged: (text) => _onTextChanged(text),
                          onSubmitted: (_) => _onTapSearch(),
                          autofocus: true,
                          cursorColor: Styles().colors!.fillColorSecondary,
                          keyboardType: TextInputType.text,
                          style: TextStyle(
                              fontSize: 16,
                              fontFamily: Styles().fontFamilies!.regular,
                              color: Styles().colors!.textBackground),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                      )
                    ),
                    Semantics(
                      label: Localization().getStringEx('panel.search.button.clear.title', 'Clear'),
                      hint: Localization().getStringEx('panel.search.button.clear.hint', ''),
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
                            excludeFromSemantics: true
                          ),
                        ),
                      )
                    ),
                    Semantics(
                      label: Localization().getStringEx('panel.search.button.search.title', 'Search'),
                      hint: Localization().getStringEx('panel.search.button.search.hint', ''),
                      button: true,
                      excludeSemantics: true,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: GestureDetector(
                          onTap: _onTapSearch,
                          child: Image.asset(
                            'images/icon-search.png',
                            color: Styles().colors!.fillColorSecondary,
                            width: 25,
                            height: 25,
                            excludeFromSemantics: true
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
                          fontSize: 20, color: Styles().colors!.fillColorPrimary),
                      children: <TextSpan>[
                        TextSpan(
                            text: _searchLabel,
                            style: TextStyle(
                              fontFamily: Styles().fontFamilies!.semiBold,
                            )),
                      ],
                    ),
                  )),
              Visibility(
                visible: _resultsCountLabelVisible,
                child: Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, bottom: 24),
                  child: Text(getResultsInfoText()!,
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: Styles().fontFamilies!.regular,
                        color: Styles().colors!.textBackground),
                  ),
                ),
              ),
              _buildListViewWidget()
            ],
          ),
    );
  }

  String? getResultsInfoText() {
    if (_resultsCount == 0)
      return Localization().getStringEx('panel.search.label.not_found', 'No results found');
    else if (_resultsCount == 1)
      return Localization().getStringEx('panel.search.label.found_single', '1 result found');
    else if (_resultsCount > 1)
      return sprintf(Localization().getStringEx('panel.search.label.found_multi', '%d results found')!, [_resultsCount]);
    else
      return "";
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
    int eventsCount = (_events != null) ? _events!.length : 0;
    Widget? exploresContent;
    if (eventsCount > 0) {
      exploresContent = ListView.separated(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        separatorBuilder: (context, index) => Divider(
              color: Colors.transparent,
            ),
        itemCount: eventsCount,
        itemBuilder: (context, index) {
          Explore explore = _events![index];
          ExploreCard exploreView = ExploreCard(
              explore: explore,
              onTap: () => _onExploreTap(explore),
              showTopBorder: true,
              hideInterests: true);
          return Padding(
              padding: EdgeInsets.only(top: 16),
              child: exploreView);
        },
      );
    }
    return exploresContent ?? Container();
  }

  void _onExploreTap(Explore explore) {
    Event? event = (explore is Event) ? explore : null;

    if (event?.isComposite ?? false) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => CompositeEventsDetailPanel(parentEvent: event)));
    }
    else if (event?.isGameEvent ?? false) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) =>
          AthleticsGameDetailPanel(gameId: event!.speaker, sportName: event.registrationLabel,)));
    }
    else {
      String? groupId = AppJson.stringValue(widget.searchData!= null ? widget.searchData!["group_id"] : null);
      Navigator.push(context, CupertinoPageRoute(builder: (context) =>
          ExploreDetailPanel(explore: explore, browseGroupId: groupId,))).
            then(
              (value){
                if(value!=null && value == true){
                  Navigator.pop(context, true);
                }
              }
            );
    }
  }

  void _searchEvents(String keyword) {
    if (keyword == null) {
      return;
    }
    keyword = keyword.trim();
    if (AppString.isStringEmpty(keyword)) {
      return;
    }
    ExploreService().loadEvents(searchText: keyword, eventFilter: EventTimeFilter.upcoming,).then((events) => _onEventsSearchFinished(events));
  }

  void _onEventsSearchFinished(List<Explore>? events) {
    _events = events;
    _resultsCount = _events?.length ?? 0;
    _resultsCountLabelVisible = true;
    _searchLabel = Localization().getStringEx('panel.search.label.results_for', 'Results for ')! + _textEditingController.text;
    _setLoading(false);
  }

  void _onTextChanged(String text) {
    _resultsCountLabelVisible = false;
    setState(() {
      _searchLabel = Localization().getStringEx('panel.search.label.search_for', 'Searching only Events Titles');
    });
  }

  void _onTapClear() {
    Analytics.instance.logSelect(target: "Clear");
    if (AppString.isStringEmpty(_textEditingController.text)) {
      Navigator.pop(context);
      return;
    }
    _events = null;
    _textEditingController.clear();
    _resultsCountLabelVisible = false;
    setState(() {
      _searchLabel = Localization().getStringEx('panel.search.label.search_for', 'Searching only Events Titles');
    });
  }

  void _onTapSearch() {
    Analytics.instance.logSelect(target: "Search");
    FocusScope.of(context).requestFocus(new FocusNode());
    _setLoading(true);
    String searchValue = _textEditingController.text;
    if (AppString.isStringEmpty(searchValue)) {
      return;
    }
    _searchEvents(searchValue);
  }

  void _setLoading(bool loading) {
    setState(() {
      _loading = loading;
    });
  }
}
