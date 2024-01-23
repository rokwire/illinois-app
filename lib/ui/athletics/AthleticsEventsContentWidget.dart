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
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/ui/athletics/AthleticsEventCard.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/athletics/AthleticsMyTeamsPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AthleticsEventsContentWidget extends StatefulWidget {
  AthleticsEventsContentWidget();

  @override
  State<AthleticsEventsContentWidget> createState() => _AthleticsEventsContentWidgetState();
}

class _AthleticsEventsContentWidgetState extends State<AthleticsEventsContentWidget> implements NotificationsListener {
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

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Events2.notifyChanged, Auth2UserPrefs.notifyInterestsChanged]);
    _scrollController.addListener(_scrollListener);
    _buildTeamsFilter();
    _reload();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildTeamsFilterContent(),
      Expanded(child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: AlwaysScrollableScrollPhysics(),
            child: _buildContent(),
          )))
    ]);
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

  Widget _buildTeamsFilterContent() {
    return Column(children: [
      Container(
          color: Styles().colors.white,
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                InkWell(
                    splashColor: Colors.transparent,
                    onTap: _onTapTeamsFilter,
                    child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Styles().colors.disabledTextColor, width: 1), borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            child: Row(children: [
                              Styles().images.getImage('filters') ?? Container(),
                              Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  child: Text(Localization().getStringEx('panel.athletics.content.common.filter.teams.label', 'Teams'),
                                      style: Styles().textStyles.getTextStyle('widget.button.title.small.fat'))),
                              Styles().images.getImage('chevron-right-gray') ?? Container()
                            ])))),
                Expanded(child: Container())
              ]))),
      Divider(thickness: 1, color: Styles().colors.lightGray, height: 1),
      Container(
          decoration: BoxDecoration(color: Styles().colors.white, boxShadow: kElevationToShadow[2]),
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                Expanded(child: Text(_teamsFilterLabel, style: Styles().textStyles.getTextStyle('widget.button.title.small'), overflow: TextOverflow.ellipsis, maxLines: 1))
              ])))
    ]);
  }

  Widget _buildEventsContent() {
    List<Widget> cardsList = <Widget>[];
    for (Event2 event in _events!) {
      Game? game = event.game;
      if (game != null) {
        cardsList.add(Padding(
            padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 8 : 0),
            child: AthleticsEventCard(game: game, onTap: () => _onTapGame(game), showImage: true)));
      }
    }
    if (_extendingEvents) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 8 : 0), child: _buildExtendingWidget()));
    }
    return Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Column(children: cardsList));
  }

  Widget _buildLoadingContent() {
    return _buildCenteredWidget(CircularProgressIndicator(color: Styles().colors.fillColorSecondary));
  }

  Widget _buildEmptyContent() {
    return _buildCenteredWidget(Text(Localization().getStringEx('panel.athletics.content.events.empty.message', 'There are no events.'),
        textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.item.medium.fat')));
  }

  Widget _buildErrorContent() {
    return _buildCenteredWidget(Text(
        StringUtils.ensureNotEmpty(_eventsErrorText,
            defaultValue: Localization().getStringEx('panel.athletics.content.events.unknown_error.message', 'Unknown Error Occurred.')),
        textAlign: TextAlign.center,
        style: Styles().textStyles.getTextStyle('widget.item.medium.fat')));
  }

  Widget _buildCenteredWidget(Widget child) {
    return Center(child: Column(children: <Widget>[Container(height: _screenHeight / 5), child, Container(height: _screenHeight / 5 * 3)]));
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

  void _onTapTeamsFilter() {
    Analytics().logSelect(target: 'Teams');
    MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
    double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 16;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        useRootNavigator: true,
        clipBehavior: Clip.antiAlias,
        backgroundColor: Styles().colors.background,
        constraints: BoxConstraints(maxHeight: height, minHeight: height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (context) {
          return AthleticsMyTeamsPanel();
        });
  }

  void _onTapGame(Game game) {
    Analytics().logSelect(target: 'Athletics Event');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(game: game)));
  }

  Events2Query _queryParam({int offset = 0, int limit = _eventsPageLength}) {
    return Events2Query(
      offset: offset,
      limit: limit,
      timeFilter: Event2TimeFilter.upcoming,
      //TBD: DD - store the athletics categories in a single place
      attributes: {'category': 'Big 10 Athletics'},
      sortType: Event2SortType.dateTime,
      sortOrder: Event2SortOrder.ascending
    );
  }

  Future<void> _reload({ int limit = _eventsPageLength }) async {
    if (!_loadingEvents && !_refreshingEvents) {
      setStateIfMounted(() {
        _loadingEvents = true;
        _extendingEvents = false;
      });

      dynamic result = await Events2().loadEventsEx(await _queryParam(limit: limit));
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
      dynamic result = await Events2().loadEventsEx(await _queryParam(limit: limit));
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

      Events2ListResult? listResult = await Events2().loadEvents(await _queryParam(offset: _events?.length ?? 0, limit: _eventsPageLength));
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

  String get _teamsFilterLabel {
    String filterPrefix = Localization().getStringEx('panel.athletics.content.common.filter.label', 'Filter:');
    String? teamsFilterDisplayString = CollectionUtils.isNotEmpty(_teamsFilter)
        ? _teamsFilter!.map((team) => team.name).toList().join(', ')
        : Localization().getStringEx('panel.athletics.content.common.filter.value.none.label', 'None');
    return '$filterPrefix $teamsFilterDisplayString';
  }

  double get _screenHeight => MediaQuery.of(context).size.height;

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == Events2.notifyChanged) {
      _reload();
    } else if (name == Auth2UserPrefs.notifyInterestsChanged) {
      _buildTeamsFilter();
      _reload();
    }
  }
}
