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

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:illinois/ui/events2/Event2DetailPanel.dart';
import 'package:illinois/ui/events2/Event2HomePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class Event2SearchPanel extends StatefulWidget {
  final Position? userLocation;

  Event2SearchPanel({Key? key, this.userLocation}) : super(key: key);

  @override
  _Event2SearchPanelState createState() => _Event2SearchPanelState();
}

class _Event2SearchPanelState extends State<Event2SearchPanel> {

  ScrollController _scrollController = ScrollController();
  TextEditingController _searchTextController = TextEditingController();
  FocusNode _searchTextNode = FocusNode();

  Client? _searchClient;
  Client? _refreshClient;
  Client? _extendClient;

  String? _searchText;
  List<Event2>? _events;
  int? _totalEventsCount;
  bool? _lastPageLoadedAll;
  static const int _eventsPageLength = 8;

  Position? _userLocation;

  @override
  void initState() {
    _scrollController.addListener(_scrollListener);

    if ((_userLocation = widget.userLocation) == null) {
      Event2HomePanel.getUserLocationIfAvailable().then((Position? userLocation) {
        setStateIfMounted(() {
          _userLocation = userLocation;
        });
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    _searchTextNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx("panel.event2.search.header.title", "Search"),),
      body: _buildScaffoldContent(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildScaffoldContent() {
    return RefreshIndicator(onRefresh: _onRefresh, child:
      SingleChildScrollView(scrollDirection: Axis.vertical, controller: _scrollController, child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Container(color: Styles().colors?.white, child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              _buildSearchBar(),
              _buildContentDescription(),
            ]),
          ),
          _buildResultContent()
        ],),
      ),
    );
  }

  Widget _buildSearchBar() => Container(decoration: _contentDescriptionDecoration, padding: EdgeInsets.only(left: 16), child:
    Row(children: <Widget>[
      Expanded(child:
        _buildSearchTextField()
      ),
      _buildSearchImageButton('close',
        label: Localization().getStringEx('panel.search.button.clear.title', 'Clear'),
        hint: Localization().getStringEx('panel.search.button.clear.hint', ''),
        onTap: _onTapClear,
      ),
      _buildSearchImageButton('search',
        label: Localization().getStringEx('panel.search.button.search.title', 'Search'),
        hint: Localization().getStringEx('panel.search.button.search.hint', ''),
        onTap: _onTapSearch,
      ),
    ],),
  );

  Widget _buildSearchTextField() => Semantics(
    label: Localization().getStringEx('panel.search.field.search.title', 'Search'),
    hint: Localization().getStringEx('panel.search.field.search.hint', ''),
    textField: true,
    excludeSemantics: true,
    child: TextField(
      controller: _searchTextController,
      focusNode: _searchTextNode,
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
  );
  
  Widget _buildSearchImageButton(String image, {String? label, String? hint, void Function()? onTap}) =>
    Semantics(label: label, hint: hint, button: true, excludeSemantics: true, child:
      InkWell(onTap: onTap, child:
        Padding(padding: EdgeInsets.all(12), child:
          Styles().images?.getImage(image, excludeFromSemantics: true),
        ),
      ),
    );

  Widget _buildContentDescription() {
    if (_searchText != null) {
      List<InlineSpan> descriptionList = <InlineSpan>[];
      TextStyle? boldStyle = Styles().textStyles?.getTextStyle("widget.card.title.tiny.fat");
      TextStyle? regularStyle = Styles().textStyles?.getTextStyle("widget.card.detail.small.regular");
      descriptionList.add(TextSpan(text: Localization().getStringEx('panel.event2.search.search.label.title', 'Search: ') , style: boldStyle,));
      descriptionList.add(TextSpan(text: _searchText ?? '' , style: regularStyle,));
      descriptionList.add(TextSpan(text: '; ', style: regularStyle,),);
      descriptionList.add(TextSpan(text: Localization().getStringEx('panel.event2.search.events.label.title', 'Events: ') , style: boldStyle,));
      descriptionList.add(TextSpan(text: (_searchClient != null) ? '...' : ((_events != null) ? _events!.length.toString() : '-') , style: regularStyle,));
      descriptionList.add(TextSpan(text: '.', style: regularStyle,),);
      return Container(decoration: _contentDescriptionDecoration, padding: EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 12), child:
        Row(children: [ Expanded(child:
          RichText(text: TextSpan(style: regularStyle, children: descriptionList))
        ),],)
      );
    }
    else {
      return Container();
    }
  }

  Decoration get _contentDescriptionDecoration => BoxDecoration(
    color: Styles().colors?.white,
    border: Border(
      bottom: BorderSide(color: Styles().colors?.disabledTextColor ?? Color(0xFF717273), width: 1))
  );

  Widget _buildResultContent() {
    if (_searchClient != null) {
      return _buildLoadingContent(); 
    }
    else if (StringUtils.isEmpty(_searchText)) {
      return Container();
    }
    else if (_events == null) {
      return _buildMessageContent(Localization().getStringEx('panel.event2.search.failed.message', 'Failed to search events.'));
    }
    else if (_events?.length == 0) {
      return _buildMessageContent(Localization().getStringEx('panel.event2.search.empty.message', 'There are no events matching the search text.'));
    }
    else {
      return _buildListContent();
    }
  }

  Widget _buildListContent() {
    List<Widget> cardsList = <Widget>[];
    for (Event2 event in _events!) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: 8), child:
        Event2Card(event, userLocation: _userLocation, onTap: () => _onTapEvent(event),),
      ),);
    }
    if (_extendClient != null) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 8 : 0), child:
        _extendIndicator
      ));
    }
    return Padding(padding: EdgeInsets.all(16), child:
      Column(children:  cardsList,)
    );
  }

  Widget get _extendIndicator => Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32), child:
    Align(alignment: Alignment.center, child:
      SizedBox(width: 24, height: 24, child:
        CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary),),),),);

  Widget _buildLoadingContent() => Padding(padding: EdgeInsets.only(left: 32, right: 32, top: _screenHeight / 4, bottom: 3 * _screenHeight / 4), child:
    Center(child:
      CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 3,),
    ),
  );

  Widget _buildMessageContent(String message) => Padding(padding: EdgeInsets.only(left: 32, right: 32, top: _screenHeight / 4, bottom: 3 * _screenHeight / 4), child:
    Text(message, textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle('widget.item.medium.fat'),)
  );

  double get _screenHeight => MediaQuery.of(context).size.height;

  void _onTapEvent(Event2 event) {
    Analytics().logSelect(target: 'Event: ${event.name}');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2DetailPanel(event: event, userLocation: _userLocation,)));
  }

  void _onTextChanged(String text) {
    if ((text.trim() != _searchText) && mounted) {
      setState(() {
        _searchText = null;
        _totalEventsCount = null;
        _lastPageLoadedAll = null;
        _events = null;
      });
    }
  }

  void _onTapClear() {
    Analytics().logSelect(target: "Clear");
    if (StringUtils.isEmpty(_searchTextController.text.trim())) {
      Navigator.pop(context);
    }
    else if (mounted) {
      _searchTextController.text = '';
      _searchTextNode.requestFocus();
      setState(() {
        _searchText = null;
        _totalEventsCount = null;
        _lastPageLoadedAll = null;
        _events = null;
      });
    }
  }

  void _onTapSearch() {
    Analytics().logSelect(target: "Search");
    _search(_searchTextController.text.trim());
  }

  Future<void> _onRefresh() {
    Analytics().logSelect(target: 'Refresh');
    return _refresh();
  }

  bool? get _hasMoreEvents => (_totalEventsCount != null) ?
    ((_events?.length ?? 0) < _totalEventsCount!) : _lastPageLoadedAll;

  void _scrollListener() {
    if ((_scrollController.offset >= _scrollController.position.maxScrollExtent) && (_hasMoreEvents != false) && (_searchClient == null) && (_extendClient == null)) {
      _extend();
    }
  }

  Future<void> _search(String searchText, { int limit = _eventsPageLength }) async {
    if (searchText.isNotEmpty) {
      Client client = Client();
      FocusScope.of(context).requestFocus(FocusNode());

      _searchClient?.close();
      _refreshClient?.close();
      _extendClient?.close();

      setState(() {
        _searchText = searchText;
        _searchClient = client;
        _refreshClient = _extendClient = null;
      });

      Events2ListResult? result = await Events2().loadEvents(Events2Query(
        searchText: searchText,
        offset: 0,
        limit: limit,
        location: _userLocation
      ), client: _extendClient);
      List<Event2>? events = result?.events;
      int? totalEventsCount = result?.totalCount;

      if (identical(_searchClient, client)) {
        setStateIfMounted(() {
          _events = (events != null) ? List<Event2>.from(events) : null;
          _totalEventsCount = totalEventsCount;
          _lastPageLoadedAll = (events != null) ? (events.length >= limit) : null;
          _searchClient = null;
        });
      }
    }
  }

  Future<void> _refresh() async {
    if (_searchText?.isNotEmpty == true) {
      Client client = Client();
      
      _searchClient?.close();
      _refreshClient?.close();
      _extendClient?.close();
      
      setState(() {
        _refreshClient = client;
        _searchClient = _extendClient = null;
      });

      int limit = max(_events?.length ?? 0, _eventsPageLength);
      Events2ListResult? result = await Events2().loadEvents(Events2Query(
        searchText: _searchText,
        offset: 0,
        limit: limit,
        location: _userLocation
      ), client: _extendClient);
      List<Event2>? events = result?.events;
      int? totalEventsCount = result?.totalCount;

      if (mounted && identical(_refreshClient, client)) {
        setState(() {
          if (events != null) {
            _events = List<Event2>.from(events);
            _lastPageLoadedAll = (events.length >= limit);
          }
          if (totalEventsCount != null) {
            _totalEventsCount = totalEventsCount;
          }
          _refreshClient = null;
        });
      }
    }
  }

  Future<void> _extend() async {
    if (_searchText?.isNotEmpty == true) {
      Client client = Client();
      
      _searchClient?.close();
      _refreshClient?.close();
      _extendClient?.close();
      
      setState(() {
        _extendClient = client;
        _searchClient = _refreshClient = null;
      });

      Events2ListResult? result = await Events2().loadEvents(Events2Query(
        searchText: _searchText,
        offset: _events?.length ?? 0,
        limit: _eventsPageLength,
        location: _userLocation
      ), client: _extendClient);
      List<Event2>? events = result?.events;
      int? totalEventsCount = result?.totalCount;

      if (mounted && identical(_extendClient, client)) {
        setState(() {
          if (events != null) {
            if (_events != null) {
              _events?.addAll(events);
            }
            else {
              _events = List<Event2>.from(events);
            }
            _lastPageLoadedAll = (events.length >= _eventsPageLength);
          }
          if (totalEventsCount != null) {
            _totalEventsCount = totalEventsCount;
          }
          _extendClient = null;
        });
      }
    }
  }
}
