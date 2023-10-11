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
import 'package:http/http.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/events2/Event2DetailPanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class AcademicsEventsContentWidget extends StatefulWidget {
  AcademicsEventsContentWidget();

  @override
  State<AcademicsEventsContentWidget> createState() => _AcademicsEventsContentWidgetState();
}

class _AcademicsEventsContentWidgetState extends State<AcademicsEventsContentWidget> {
  ScrollController _scrollController = ScrollController();

  Client? _initClient;
  Client? _refreshClient;
  Client? _extendClient;

  List<Event2>? _events;
  String? _eventsErrorText;
  int? _totalEventsCount;
  bool? _lastPageLoadedAll;
  static const int _eventsPageLength = 6;

  @override
  void initState() {
    _scrollController.addListener(_scrollListener);
    _init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: _onRefresh, child:
      SingleChildScrollView(scrollDirection: Axis.vertical, controller: _scrollController, child:
        _buildResultContent()
      ),
    );
  }

  Widget _buildResultContent() {
    if (_initClient != null) {
      return _buildLoadingContent(); 
    }
    else if (Connectivity().isOffline) {
      return _buildMessageContent(Localization().getStringEx('panel.academics.section.events.offline.msg', 'No Speakers & Seminars events are available while offline.'));
    }
    else if (_events == null) {
      return _buildMessageContent(_eventsErrorText ?? Localization().getStringEx('logic.general.unknown_error', 'Unknown Error Occurred'),
        title: Localization().getStringEx('panel.events2.home.message.failed.title', 'Failed')
      );
    }
    else if (_events?.length == 0) {
      return _buildMessageContent(Localization().getStringEx('panel.academics.section.events.empty.msg', 'There are no upcoming Speakers & Seminars events.'));
    }
    else {
      return _buildListContent();
    }
  }

  Widget _buildListContent() {
    List<Widget> cardsList = <Widget>[];
    for (Event2 event in _events!) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: 8), child:
        Event2Card(event, onTap: () => _onTapEvent(event),),
      ),);
    }
    if (_extendClient != null) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 8 : 0), child:
        _extendIndicator
      ));
    }
    return Padding(padding: EdgeInsets.zero, child:
      Column(children:  cardsList,)
    );
  }

  Widget get _extendIndicator => Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32), child:
    Align(alignment: Alignment.center, child:
      SizedBox(width: 24, height: 24, child:
        CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary),),),),);

  Widget _buildLoadingContent() => Padding(padding: EdgeInsets.only(left: 16, right: 16, top: _screenHeight / 4, bottom: 3 * _screenHeight / 4), child:
    Center(child:
      CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 3,),
    ),
  );

  Widget _buildMessageContent(String message, { String? title }) =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: _screenHeight / 6), child:
      Column(children: [
        (title != null) ? Padding(padding: EdgeInsets.only(bottom: 12), child:
          Text(title, textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle('widget.item.medium.fat'),)
        ) : Container(),
        Text(message, textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle((title != null) ? 'widget.item.regular.thin' : 'widget.item.medium.fat'),),
      ],),
    );

  double get _screenHeight => MediaQuery.of(context).size.height;

  void _onTapEvent(Event2 event) {
    Analytics().logSelect(target: 'Event: ${event.name}');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2DetailPanel(event: event,)));
  }

  Future<void> _onRefresh() {
    Analytics().logSelect(target: 'Refresh');
    return _refresh();
  }

  bool? get _hasMoreEvents => (_totalEventsCount != null) ?
    ((_events?.length ?? 0) < _totalEventsCount!) : _lastPageLoadedAll;

  void _scrollListener() {
    if ((_scrollController.offset >= _scrollController.position.maxScrollExtent) && (_hasMoreEvents != false) && (_initClient == null) && (_extendClient == null) && (_refreshClient == null) && (_refreshClient == null)) {
      _extend();
    }
  }

  Events2Query _buildQuery({int offset = 0, int limit =  _eventsPageLength}) => Events2Query(
      attributes: {
        'category': 'Speakers and Seminars'
      },
      offset: offset,
      limit: limit,
      sortType: Event2SortType.dateTime,
      sortOrder: Event2SortOrder.ascending
    );

  Future<void> _init() async {
    Client client = Client(); 

    _initClient?.close();
    _refreshClient?.close();
    _extendClient?.close();

    _initClient = client;
    _refreshClient = _extendClient = null;
    
    dynamic result = await Events2().loadEventsEx(_buildQuery(), client: _initClient);
    Events2ListResult? listResult = (result is Events2ListResult) ? result : null;
    List<Event2>? events = listResult?.events;
    int? totalEventsCount = listResult?.totalCount;
    String? errorTextResult = (result is String) ? result : null;

    if (mounted && identical(_initClient, client))
    setState(() {
      _events = (events != null) ? List<Event2>.from(events) : null;
      _totalEventsCount = totalEventsCount;
      _lastPageLoadedAll = (events != null) ? (events.length >= _eventsPageLength) : null;
      _eventsErrorText = errorTextResult;
      _initClient = null;
    });
  }

  Future<void> _refresh() async {
    Client client = Client();
    
    _initClient?.close();
    _refreshClient?.close();
    _extendClient?.close();
    
    setState(() {
      _refreshClient = client;
      _initClient = _extendClient = null;
    });

    int limit = max(_events?.length ?? 0, _eventsPageLength);
    dynamic result = await Events2().loadEventsEx(_buildQuery(limit: limit), client: _refreshClient);
    Events2ListResult? listResult = (result is Events2ListResult) ? result : null;
    List<Event2>? events = listResult?.events;
    int? totalEventsCount = listResult?.totalCount;
    String? errorTextResult = (result is String) ? result : null;

    if (mounted && identical(_refreshClient, client)) {
      setState(() {
        if (events != null) {
          _events = List<Event2>.from(events);
          _lastPageLoadedAll = (events.length >= limit);
          _eventsErrorText = null;
        }
        else if (_events == null) {
          // If there was events content, preserve it. Otherwise, show the error
          _eventsErrorText = errorTextResult;
        }
        if (totalEventsCount != null) {
          _totalEventsCount = totalEventsCount;
        }
        _refreshClient = null;
      });
    }
  }

  Future<void> _extend() async {
    Client client = Client();
    
    _initClient?.close();
    _refreshClient?.close();
    _extendClient?.close();
    
    setState(() {
      _extendClient = client;
      _initClient = _refreshClient = null;
    });

    Events2ListResult? listResult = await Events2().loadEvents(_buildQuery(offset: _events?.length ?? 0), client: _extendClient);
    List<Event2>? events = listResult?.events;
    int? totalEventsCount = listResult?.totalCount;

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
