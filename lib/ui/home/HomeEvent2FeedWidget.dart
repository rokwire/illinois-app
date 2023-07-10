/*
 * Copyright 2022 Board of Trustees of the University of Illinois.
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

import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/events2/Event2DetailPanel.dart';
import 'package:illinois/ui/events2/Event2HomePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';

class HomeEvent2FeedWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeEvent2FeedWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.event2_feed.label.header.title', 'Event Feed');

  State<HomeEvent2FeedWidget> createState() => _HomeEvent2FeedWidgetState();
}

class _HomeEvent2FeedWidgetState extends State<HomeEvent2FeedWidget> implements NotificationsListener {
  List<Event2>? _events;
  bool? _lastPageLoadedAll;
  int? _totalEventsCount;
  bool _loadingEvents = false;
  bool _refreshingEvents = false;
  bool _extendingEvents = false;
  static const int _eventsPageLength = 16;
 
  LocationServicesStatus? _locationServicesStatus;
  bool _loadingLocationServicesStatus = false;
  Position? _currentLocation;

  DateTime? _pausedDateTime;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  Map<String, GlobalKey> _contentKeys = <String, GlobalKey>{};
  final double _pageSpacing = 16;

  @override
  void initState() {

    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      FlexUI.notifyChanged,
      Events2.notifyChanged
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _refresh();
        }
      });
    }

    _initLocationServicesStatus().then((_) {
      _reload();
    });

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _pageController?.dispose();
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == FlexUI.notifyChanged) {
      _currentLocation = null;
      _updateLocationServicesStatus();
    }
    else if (name == Events2.notifyChanged) {
      _reload();
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateLocationServicesStatus().then((_) {
            _refresh();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: HomeEvent2FeedWidget.title,
      titleIconKey: 'events',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loadingEvents || _loadingLocationServicesStatus) {
      return HomeProgressWidget();
    }
    else if (_refreshingEvents) {
      return Container();
    }
    else if (_events == null) {
      return HomeMessageCard(message: 'Failed to load events.');
    }
    else if (_events?.length == 0) {
      return HomeMessageCard(message: 'There are no events matching the selected filters.');
    }
    else {
      return _buildEventsContent();
    }
  }

  Widget _buildEventsContent() {
    
    Widget contentWidget;
    if (1 < (_events?.length ?? 0)) {

      List<Widget> pages = <Widget>[];
      for (Event2 event in _events!) {
        pages.add(Padding(
          key: _contentKeys[StringUtils.ensureNotEmpty(event.id)] ??= GlobalKey(),
          padding: EdgeInsets.only(right: _pageSpacing + 2, bottom: 8),
          child: Event2Card(event, displayMode: Event2CardDisplayMode.page, userLocation: _currentLocation, onTap: () => _onTapEvent2(event),)));
      }

      if (_pageController == null) {
        double screenWidth = MediaQuery.of(context).size.width;
        double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
        _pageController = PageController(viewportFraction: pageViewport);
      }

      contentWidget = Container(constraints: BoxConstraints(minHeight: _pageHeight), child:
        ExpandablePageView(
          key: _pageViewKey,
          controller: _pageController,
          estimatedPageSize: _pageHeight,
          allowImplicitScrolling: true,
          children: pages,
        ),
      );
    }
    else {
      contentWidget = Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
        Event2Card(_events!.first, displayMode: Event2CardDisplayMode.page, userLocation: _currentLocation, onTap: () => _onTapEvent2(_events!.first))
      );
    }

    return Column(children: <Widget>[
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => (_events?.length ?? 0),),
      LinkButton(
        title: Localization().getStringEx('widget.home.event2_feed.button.all.title', 'View All'),
        hint: Localization().getStringEx('widget.home.event2_feed.button.all.hint', 'Tap to view all events'),
        onTap: _onTapViewAll,
      ),
    ]);
  }

  double get _pageHeight {
    double? minContentHeight;
    for (GlobalKey contentKey in _contentKeys.values) {
      final RenderObject? renderBox = contentKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && ((minContentHeight == null) || (renderBox.size.height < minContentHeight))) {
        minContentHeight = renderBox.size.height;
      }
    }
    return minContentHeight ?? 0;
  }

  void _onTapEvent2(Event2 event) {
    Analytics().logSelect(target: "Event: '${event.name}'", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2DetailPanel(event: event, userLocation: _currentLocation,)));
  }

  void _onTapViewAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
  }

  // Location Status and Position

  Future<void> _initLocationServicesStatus() async {
    setStateIfMounted(() {
      _loadingLocationServicesStatus = true;
    });
    LocationServicesStatus? locationServicesStatus = await Event2HomePanel.getLocationServicesStatus();
    if (locationServicesStatus != null) {
      setStateIfMounted(() {
        _locationServicesStatus = locationServicesStatus;
        _loadingLocationServicesStatus = false;
      });
    }
  }

  Future<void> _updateLocationServicesStatus() async {
    LocationServicesStatus? locationServicesStatus = await Event2HomePanel.getLocationServicesStatus();
    if (_locationServicesStatus != locationServicesStatus) {
      setStateIfMounted(() {
        _locationServicesStatus = locationServicesStatus;
      });
      if (_needsUpdateOnLocationServicesStatus()) {
        _reload();
      }
    }
  }

  bool _needsUpdateOnLocationServicesStatus() {
    bool locationNotAvailable = ((_locationServicesStatus == LocationServicesStatus.serviceDisabled) || ((_locationServicesStatus == LocationServicesStatus.permissionDenied)));
    LinkedHashSet<Event2TypeFilter>? types = LinkedHashSetUtils.from<Event2TypeFilter>(event2TypeFilterListFromStringList(Storage().events2Types));
    Event2SortType? sortType = event2SortTypeFromString(Storage().events2SortType) ?? Event2SortType.dateTime;
    return (locationNotAvailable && ((types?.contains(Event2TypeFilter.nearby) == true) || (sortType == Event2SortType.proximity)));
  }

  // Event2 Query

  Future<Events2Query> _queryParam({int offset = 0, int limit = _eventsPageLength}) async {
    Event2TimeFilter timeFilter = event2TimeFilterFromString(Storage().events2Time) ?? Event2TimeFilter.upcoming;
    TZDateTime? customStartTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomStartTime));
    TZDateTime? customEndTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomEndTime));
    LinkedHashSet<Event2TypeFilter>? types = LinkedHashSetUtils.from<Event2TypeFilter>(event2TypeFilterListFromStringList(Storage().events2Types));
    Map<String, dynamic>? attributes = Storage().events2Attributes;
    Event2SortType? sortType = event2SortTypeFromString(Storage().events2SortType) ?? Event2SortType.dateTime;

    bool locationNotAvailable = ((_locationServicesStatus == LocationServicesStatus.serviceDisabled) || ((_locationServicesStatus == LocationServicesStatus.permissionDenied)));
    if ((types?.contains(Event2TypeFilter.nearby) == true) && locationNotAvailable) {
      types?.remove(Event2TypeFilter.nearby);
    }
    if ((sortType == Event2SortType.proximity) && locationNotAvailable) {
      sortType = Event2SortType.dateTime;
    }

    if (((types?.contains(Event2TypeFilter.nearby) == true) || (sortType == Event2SortType.proximity)) && (_locationServicesStatus == LocationServicesStatus.permissionAllowed)) {
      _currentLocation = await LocationServices().location;
    }

    return Events2Query(
      offset: offset,
      limit: limit,
      timeFilter: timeFilter,
      customStartTimeUtc: customStartTime?.toUtc(),
      customEndTimeUtc: customEndTime?.toUtc(),
      types: types,
      attributes: attributes,
      sortType: sortType,
      sortOrder: Event2SortOrder.ascending,
      location: _currentLocation,
    );
  }

  Future<void> _reload({ int limit = _eventsPageLength }) async {
    if (!_loadingEvents && !_refreshingEvents) {
      setStateIfMounted(() {
        _loadingEvents = true;
        _extendingEvents = false;
      });

      Events2ListResult? loadResult = await Events2().loadEvents(await _queryParam(limit: limit));
      List<Event2>? events = loadResult?.events;

      setStateIfMounted(() {
        _events = (events != null) ? List<Event2>.from(events) : null;
        _totalEventsCount = loadResult?.totalCount;
        _lastPageLoadedAll = (events != null) ? (events.length >= limit) : null;
        _loadingEvents = false;
      });
    }
  }

  Future<void> _refresh() async {

    if (!_loadingEvents && !_refreshingEvents) {
      setStateIfMounted(() {
        _refreshingEvents = true;
        _extendingEvents = false;
      });

      int limit = max(_events?.length ?? 0, _eventsPageLength);
      Events2ListResult? loadResult = await Events2().loadEvents(await _queryParam(limit: limit));
      List<Event2>? events = loadResult?.events;
      int? totalCount = loadResult?.totalCount;

      setStateIfMounted(() {
        if (events != null) {
          _events = List<Event2>.from(events);
          _lastPageLoadedAll = (events.length >= limit);
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

      Events2ListResult? loadResult = await Events2().loadEvents(await _queryParam(offset: _events?.length ?? 0, limit: _eventsPageLength));
      List<Event2>? events = loadResult?.events;
      int? totalCount = loadResult?.totalCount;

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
}