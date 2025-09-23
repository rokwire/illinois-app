/*
 * Copyright 2024 Board of Trustees of the University of Illinois.
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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/ui/athletics/AthleticsWidgets.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AthleticsEventsContentWidget extends StatefulWidget {
  final bool? showFavorites;

  AthleticsEventsContentWidget({this.showFavorites});

  @override
  State<AthleticsEventsContentWidget> createState() => _AthleticsEventsContentWidgetState();
}

class _AthleticsEventsContentWidgetState extends State<AthleticsEventsContentWidget> with NotificationsListener {
  List<Event2>? _events;
  bool? _lastPageLoadedAll;
  int? _totalEventsCount;
  String? _eventsErrorText;
  bool _loadingEvents = false;
  bool _refreshingEvents = false;
  bool _extendingEvents = false;
  static const int _eventsPageLength = 16;

  List<SportDefinition>? _teamsFilter;

  ScrollController _scrollController = ScrollController();

  static const String _privacyUrl = 'privacy://level';
  static const String _privacyUrlMacro = '{{privacy_url}}';

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Events2.notifyChanged, Auth2UserPrefs.notifyInterestsChanged, Auth2UserPrefs.notifyFavoritesChanged]);
    _scrollController.addListener(_scrollListener);
    _loadEvents();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(AthleticsEventsContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showFavorites != oldWidget.showFavorites) {
      setState(() {
        _loadEvents();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [AthleticsTeamsFilterWidget(favoritesMode: _favoritesMode), Expanded(child: _buildContent())]);
  }

  Widget _buildContent() {
    if (_loadingEvents) {
      return _buildLoadingContent();
    } else if (_events == null) {
      return _buildErrorContent();
    } else if (_events?.length == 0) {
      return _buildEmptyContent();
    } else {
      return _buildEventsContent();
    }
  }

  Widget _buildEventsContent() {
    List<Widget> cardsList = <Widget>[];
    for (Event2 event in _events!) {
      Game? game = event.game;
      if (game != null) {
        cardsList.add(Padding(
            padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 8 : 0),
            child: AthleticsEventCard(sportEvent: event, onTap: () => _onTapGame(event), showImage: true)));
      }
    }
    if (_extendingEvents) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 8 : 0), child: _buildExtendingWidget()));
    }
    return RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
            controller: _scrollController,
            physics: AlwaysScrollableScrollPhysics(),
            child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Column(children: cardsList))));
  }

  Widget _buildLoadingContent() {
    return _buildCenteredWidget(CircularProgressIndicator(color: Styles().colors.fillColorSecondary));
  }

  Widget _buildEmptyContent() {
    return _buildCenteredWidget(
      HtmlWidget("<center>$_emptyMessageHtml</center>",
        onTapUrl : _handleLocalUrl,
        textStyle:  Styles().textStyles.getTextStyle('widget.item.medium'),
        customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null,
      )
    );
  }

  bool _handleLocalUrl(String? url) {
    if (url == _privacyUrl) {
      Analytics().logSelect(target: 'Privacy Level', source: widget.runtimeType.toString());
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,)));
      return true;
    }
    else {
      return false;
    }
  }

  Widget _buildErrorContent() {
    return _buildCenteredWidget(Text(
        StringUtils.ensureNotEmpty(_eventsErrorText,
            defaultValue: Localization().getStringEx('panel.athletics.content.events.unknown_error.message', 'Unknown Error Occurred.')),
        textAlign: TextAlign.center,
        style: Styles().textStyles.getTextStyle('widget.item.medium.fat')));
  }

  Widget _buildCenteredWidget(Widget child) {
    return Padding(padding: EdgeInsets.symmetric(vertical: 32, horizontal: 48), child:
      Center(child: child)
    );
  }

  Widget _buildExtendingWidget() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Align(
            alignment: Alignment.center,
            child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary)))));
  }

  void _onTapGame(Event2 event) {
    Analytics().logSelect(target: 'Athletics Event');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(game: event.game, event: event)));
  }

  Events2Query _queryParam({int offset = 0, int limit = _eventsPageLength}) {
    return Events2Query(
      offset: offset,
      limit: limit,
      timeFilter: Event2TimeFilter.upcoming,
      attributes: _buildQueryAttributes(),
      types: _favoritesMode ? {Event2TypeFilter.favorite} : null,
      groupings: Event2Grouping.individualEvents(),
      sortType: Event2SortType.dateTime,
      sortOrder: Event2SortOrder.ascending
    );
  }

  void _loadEvents() {
    _buildTeamsFilter();
    if (CollectionUtils.isNotEmpty(_teamsFilter)) {
      _reloadEvents();
    } else {
      setState(() {
        _events = <Event2>[];
      });
    }
  }

  Future<void> _reloadEvents({ int limit = _eventsPageLength }) async {
    if (!_loadingEvents && !_refreshingEvents) {
      setStateIfMounted(() {
        _loadingEvents = true;
        _extendingEvents = false;
      });

      dynamic result = await Events2().loadEventsEx(_queryParam(limit: limit));
      Events2ListResult? listResult = (result is Events2ListResult) ? result : null;
      List<Event2>? events = listResult?.events;
      String? errorTextResult = (result is String) ? result : null;

      setStateIfMounted(() {
        _events = (events != null) ? List<Event2>.from(events) : null;
        _totalEventsCount = listResult?.totalCount;
        _lastPageLoadedAll = (events != null) ? (events.length >= limit) : null;
        _eventsErrorText = errorTextResult;
        _loadingEvents = false;
      });
    }
  }

  void _scrollListener() {
    if ((_scrollController.offset >= _scrollController.position.maxScrollExtent) && (_hasMoreEvents != false) && !_loadingEvents && !_extendingEvents) {
      _extend();
    }
  }

  Future<void> _onRefresh() {
    Analytics().logSelect(target: 'Refresh');
    return _refresh();
  }

  bool? get _hasMoreEvents => (_totalEventsCount != null) ?
  ((_events?.length ?? 0) < _totalEventsCount!) : _lastPageLoadedAll;

  Future<void> _refresh() async {

    if (!_loadingEvents && !_refreshingEvents) {
      setStateIfMounted(() {
        _refreshingEvents = true;
        _extendingEvents = false;
      });

      int limit = max(_events?.length ?? 0, _eventsPageLength);
      dynamic result = await Events2().loadEventsEx(_queryParam(limit: limit));
      Events2ListResult? listResult = (result is Events2ListResult) ? result : null;
      List<Event2>? events = listResult?.events;
      int? totalCount = listResult?.totalCount;
      String? errorTextResult = (result is String) ? result : null;

      setStateIfMounted(() {
        if (events != null) {
          _events = List<Event2>.from(events);
          _lastPageLoadedAll = (events.length >= limit);
          _eventsErrorText = null;
        }
        else if (_events == null) {
          _eventsErrorText = errorTextResult;
        }
        if (totalCount != null) {
          _totalEventsCount = totalCount;
        }
        _refreshingEvents = false;
      });
    }
  }

  Future<void> _extend() async {
    if (!_loadingEvents && !_refreshingEvents && !_extendingEvents) {
      setStateIfMounted(() {
        _extendingEvents = true;
      });

      Events2ListResult? listResult = await Events2().loadEvents(_queryParam(offset: _events?.length ?? 0, limit: _eventsPageLength));
      List<Event2>? events = listResult?.events;
      int? totalCount = listResult?.totalCount;

      if (mounted && _extendingEvents && !_loadingEvents && !_refreshingEvents) {
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
          if (totalCount != null) {
            _totalEventsCount = totalCount;
          }
          _extendingEvents = false;
        });
      }

    }
  }

  void _buildTeamsFilter() {
    Set<String>? preferredTeams = Auth2().prefs?.sportsInterests;
    if (CollectionUtils.isNotEmpty(preferredTeams)) {
      _teamsFilter = <SportDefinition>[];
      for (String sportShortName in preferredTeams!) {
        SportDefinition? sport = Sports().getSportByShortName(sportShortName);
        if (sport != null) {
          _teamsFilter!.add(sport);
        }
      }
    } else {
      _teamsFilter = null;
    }
  }

  Map<String, dynamic> _buildQueryAttributes() {
    Map<String, dynamic> attributes = {'category': Events2.sportEventCategory};
    if (CollectionUtils.isNotEmpty(_teamsFilter)) {
      late dynamic sportAttribute;
      if (_teamsFilter!.length == 1) {
        sportAttribute = _getSportFilterKey(_teamsFilter!.first);
      } else {
        sportAttribute = <String>[];
        sportAttribute = List.from(_teamsFilter!.map((sport) {
          return _getSportFilterKey(sport);
        }));
      }
      attributes.addAll({'sport': sportAttribute});
    }
    return attributes;
  }

  String? _getSportFilterKey(SportDefinition? sport) {
    // "Manually" select different property name for these sports because they do not match with labels in Calendar and Sports BB
    if ((sport?.shortName == 'wrestling') || (sport?.shortName == 'wswim') || (sport?.shortName == 'wvball')) {
      return sport?.customName;
    } else {
      return sport?.name;
    }
  }

  bool get _favoritesMode => (widget.showFavorites == true);

  String get _emptyMessageHtml {
    return _favoritesMode ?
      Localization().getStringEx('panel.athletics.content.events.my.empty.message', "There are no starred events for the selected teams. (<a href='$_privacyUrlMacro'>Your privacy level</a> must be at least 2.)").replaceAll(_privacyUrlMacro, _privacyUrl) :
      Localization().getStringEx('panel.athletics.content.events.empty.message', 'There are no events for the selected teams.');
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == Events2.notifyChanged) {
      _reloadEvents();
    } else if (name == Auth2UserPrefs.notifyInterestsChanged) {
      _loadEvents();
    } else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      if (_favoritesMode) {
        _reloadEvents();
      }
    }
  }
}
