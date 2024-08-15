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
import 'package:neom/ext/Event2.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/service/FlexUI.dart';
import 'package:neom/service/Storage.dart';
import 'package:neom/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:neom/ui/events2/Event2DetailPanel.dart';
import 'package:neom/ui/events2/Event2HomePanel.dart';
import 'package:neom/ui/events2/Event2Widgets.dart';
import 'package:neom/ui/home/HomePanel.dart';
import 'package:neom/ui/home/HomeWidgets.dart';
import 'package:neom/ui/widgets/LinkButton.dart';
import 'package:neom/ui/widgets/SemanticsWidgets.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';
import 'package:visibility_detector/visibility_detector.dart';

abstract class HomeEvent2Widget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeEvent2Widget({super.key, this.favoriteId, this.updateController});

  String get _title;

  Widget _emptyContentWidget(BuildContext context);

  //@override
  //State<StatefulWidget> createState() => _HomeEvent2WidgetState();
}

class HomeEvent2FeedWidget extends HomeEvent2Widget {

  HomeEvent2FeedWidget({super.key, super.favoriteId, super.updateController});

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.event2_feed.label.header.title', 'All Events');

  @override
  String get _title => title;

  @override
  Widget _emptyContentWidget(BuildContext context) => HomeMessageCard(
    message: Localization().getStringEx('widget.home.event2_feed.text.empty.description', 'There are no events available.')
  );

  @override
  State<StatefulWidget> createState() => _HomeEvent2WidgetState();
}

class HomeMyEvents2Widget extends HomeEvent2Widget {

  static const String localScheme = 'local';
  static const String localEventFeedHost = 'event2_feed';
  static const String localUrlMacro = '{{local_url}}';

  HomeMyEvents2Widget({super.key, super.favoriteId, super.updateController});

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.my_events2.label.header.title', 'My Events');

  @override
  String get _title => title;

  @override
  Widget _emptyContentWidget(BuildContext context) => HomeMessageHtmlCard(
    message: Localization().getStringEx("widget.home.my_events2.text.empty.description", "Tap the \u2606 on items in <a href='$localUrlMacro'><b>Events Feed</b></a> for quick access here.")
      .replaceAll(localUrlMacro, '$localScheme://$localEventFeedHost'),
    linkColor: Styles().colors.eventColor,
    onTapLink : (url) {
      Uri? uri = (url != null) ? Uri.tryParse(url) : null;
      if ((uri?.scheme == localScheme) && (uri?.host == localEventFeedHost)) {
        Analytics().logSelect(target: 'Events Feed', source: runtimeType.toString());
        Event2HomePanel.present(context);
      }
    },
  );

  @override
  State<StatefulWidget> createState() => _HomeEvent2WidgetState(
    timeFilter: Event2TimeFilter.upcoming, customStartTime: null, customEndTime: null,
    types: LinkedHashSet<Event2TypeFilter>.from([Event2TypeFilter.favorite]),
    attributes: <String, dynamic>{},
    sortType: Event2SortType.dateTime,
  );
}

enum _Staled { none, refresh, reload }

class _HomeEvent2WidgetState extends State<HomeEvent2Widget> implements NotificationsListener {
  final Event2TimeFilter? timeFilter;
  final TZDateTime? customStartTime;
  final TZDateTime? customEndTime;

  final LinkedHashSet<Event2TypeFilter>? types;
  final Map<String, dynamic>? attributes;

  final Event2SortType? sortType;

  List<Event2>? _events;
  bool? _lastPageLoadedAll;
  int? _totalEventsCount;
  String? _eventsErrorText;
  bool _loadingEvents = false;
  bool _refreshingEvents = false;
  bool _extendingEvents = false;
  static const int _eventsPageLength = 16;
  static const String _progressContentKey = '_progress_';
 
  LocationServicesStatus? _locationServicesStatus;
  bool _loadingLocationServicesStatus = false;
  Position? _currentLocation;

  DateTime? _pausedDateTime;
  bool _visible = false;
  _Staled _stalled = _Staled.none;

  PageController? _pageController;
  Key _visibilityDetectorKey = UniqueKey();
  Key _pageViewKey = UniqueKey();
  Map<String, GlobalKey> _contentKeys = <String, GlobalKey>{};
  final double _pageSpacing = 16;

  _HomeEvent2WidgetState({
    this.timeFilter, this.customStartTime, this.customEndTime,
    this.attributes, this.types, this.sortType
  });

  @override
  void initState() {

    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      AppLifecycle.notifyStateChanged,
      FlexUI.notifyChanged,
      Storage.notifySettingChanged,
      Events2.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      Auth2.notifyLoginSucceeded,
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
    if (name == AppLifecycle.notifyStateChanged) {
      _onAppLifecycleStateChanged(param);
    }
    else if (name == FlexUI.notifyChanged) {
      _currentLocation = null;
      _updateLocationServicesStatus(() {
        if (_needsContentUpdateOnLocationServicesStatusUpdate) {
          _reloadIfVisible();
        }
      });
    }
    else if (name == Storage.notifySettingChanged) {
      if ((param == Storage.events2TimeKey) || (param == Storage.events2TypesKey) || (param == Storage.events2AttributesKey) || (param == Storage.events2SortTypeKey)) {
        _reloadIfVisible();
      }
    }
    else if (name == Connectivity.notifyStatusChanged) {
      _reloadIfVisible(); // or mark as needs refresh
    }
    else if (name == Events2.notifyChanged) {
      _reloadIfVisible(); // or mark as needs refresh
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      if (_needsContentUpdateOnFavoritesChanged) {
        _reloadIfVisible(); // or mark as needs refresh
      }
    }
    else if (name == Auth2.notifyLoginSucceeded) {
      _reload(); // or mark as needs refresh
    }
  }

  void _onAppLifecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateLocationServicesStatus().then((_) {
            _refreshIfVisible();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(key: _visibilityDetectorKey, onVisibilityChanged: _onVisibilityChanged, child:
      HomeSlantWidget(favoriteId: widget.favoriteId,
        title: widget._title,
        titleIconKey: 'events',
        child: _buildContent(),
      )
    );
  }

  Widget _buildContent() {
    if (Connectivity().isOffline) {
      return HomeMessageCard(
        title: Localization().getStringEx("common.message.offline", "You appear to be offline"),
        message: Localization().getStringEx("widget.home.event2_feed.text.offline.description", "Events are not available while offline."),
      );
    }
    else if (_loadingEvents || _loadingLocationServicesStatus) {
      return HomeProgressWidget();
    }
    else if (_events == null) {
      return HomeMessageCard(
        title: Localization().getStringEx('panel.events2.home.message.failed.title', 'Failed'),
        message: _eventsErrorText ?? Localization().getStringEx('logic.general.unknown_error', 'Unknown Error Occurred')
      );
    }
    else if (_events?.length == 0) {
      return widget._emptyContentWidget(context);
    }
    else {
      return _buildEventsContent();
    }
  }

  Widget _buildEventsContent() {
    
    Widget contentWidget;
    int eventsCount = _events?.length ?? 0;
    int pageCount = eventsCount ~/ _cardsPerPage;

    List<Widget> pages = <Widget>[];
    for (int index = 0; index < pageCount + 1; index++) {
      List<Widget> pageCards = [];
      for (int eventIndex = 0; eventIndex < _cardsPerPage; eventIndex++) {
        if (index * _cardsPerPage + eventIndex >= _events!.length) {
          break;
        }
        Event2 event = _events![index * _cardsPerPage + eventIndex];
        String contentKey = "${event.id}-$index";
        pageCards.add(Padding(
          key: _contentKeys[contentKey] ??= GlobalKey(),
          padding: EdgeInsets.only(right: _pageSpacing + 2, bottom: 8),
          child: Container(
            constraints: BoxConstraints(maxWidth: _cardWidth),
            child: Event2Card(event, displayMode: Event2CardDisplayMode.page, userLocation: _currentLocation, onTap: () => _onTapEvent2(event),)
          )
        ));
      }
      if (_cardsPerPage > 1 && pageCards.length > 1) {
        pages.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: pageCards,
        ));
      } else {
        pages.addAll(pageCards);
      }
    }

    if (_hasMoreEvents != false) {
      pages.add(Padding(
        key: _contentKeys[_progressContentKey] ??= GlobalKey(),
        padding: EdgeInsets.only(right: _pageSpacing + 2, bottom: 8),
        child: HomeProgressWidget(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        ),
      ));
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
        onPageChanged: _onPageChanged,
      ),
    );

    return Column(children: <Widget>[
      contentWidget,
      AccessibleViewPagerNavigationButtons(
        controller: _pageController,
        pagesCount: () {
          if ((_events?.length ?? 0) == _cardsPerPage) {
            return 1;
          }
          return (_events?.length ?? 0) ~/ _cardsPerPage + 1;
        },
        centerWidget: LinkButton(
          title: Localization().getStringEx('widget.home.event2_feed.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.event2_feed.button.all.hint', 'Tap to view all events'),
          textStyle: Styles().textStyles.getTextStyle('widget.description.regular.light.underline'),
          onTap: _onTapViewAll,
        ),
      ),
    ]);
  }

  double get _pageHeight {
    double? minContentHeight;
    for (GlobalKey contentKey in _contentKeys.values) {
      final RenderObject? renderBox = contentKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && renderBox.hasSize && ((minContentHeight == null) || (renderBox.size.height < minContentHeight))) {
        minContentHeight = renderBox.size.height;
      }
    }
    return minContentHeight ?? 0;
  }

  double get _cardWidth {
    double screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth - 2 * _cardsPerPage * _pageSpacing) / _cardsPerPage;
  }

  int get _cardsPerPage {
    ScreenType screenType = ScreenUtils.getType(context);
    switch (screenType) {
      case ScreenType.desktop:
        return min(5, (_events?.length ?? 1));
      case ScreenType.tablet:
        return min(3, (_events?.length ?? 1));
      case ScreenType.phone:
        return 1;
      default:
        return 1;
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    _updateInternalVisibility(!info.visibleBounds.isEmpty);
  }

  bool? get _hasMoreEvents => (_totalEventsCount != null) ?
    ((_events?.length ?? 0) < _totalEventsCount!) : _lastPageLoadedAll;

  void _onPageChanged(int index) {
    if ((_events?.length ?? 0) < (index + 1) && (_hasMoreEvents != false) && !_extendingEvents && !_loadingEvents && !_refreshingEvents) {
      _extend();
    }
  }

  void _onTapEvent2(Event2 event) {
    Analytics().logSelect(target: "Event: '${event.name}'", source: widget.runtimeType.toString());
    if (event.hasGame) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(game: event.game)));
    } else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2DetailPanel(event: event, userLocation: _currentLocation,)));
    }
  }

  void _onTapViewAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Event2HomePanel.present(context,
      timeFilter: timeFilter, customStartTime: customEndTime, customEndTime: customEndTime,
      types: types, attributes: attributes, sortType: sortType,
    );
  }

  // Visibility

  void _updateInternalVisibility(bool visible) {
    if (_visible != visible) {
      _visible = visible;
      _onInternalVisibilityChanged();
    }
  }

  void _onInternalVisibilityChanged() {
    if (_visible) {
      switch(_stalled) {
        case _Staled.none: break;
        case _Staled.refresh: _refresh(); break;
        case _Staled.reload: _reload(); break;
      }
    }
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

  Future<void> _updateLocationServicesStatus([void Function()? onChanged]) async {
    LocationServicesStatus? locationServicesStatus = await Event2HomePanel.getLocationServicesStatus();
    if (_locationServicesStatus != locationServicesStatus) {
      setStateIfMounted(() {
        _locationServicesStatus = locationServicesStatus;
      });
      if (onChanged != null) {
        onChanged();
      }
    }
  }

  bool get _needsContentUpdateOnLocationServicesStatusUpdate {
    bool locationNotAvailable = ((_locationServicesStatus == LocationServicesStatus.serviceDisabled) || ((_locationServicesStatus == LocationServicesStatus.permissionDenied)));
    return (locationNotAvailable && ((_queryTypes?.contains(Event2TypeFilter.nearby) == true) || (_querySortType == Event2SortType.proximity)));
  }

  bool get _needsContentUpdateOnFavoritesChanged =>
      (_queryTypes?.contains(Event2TypeFilter.favorite) == true);

  // Event2 Query

  Future<Events2Query> _queryParam({int offset = 0, int limit = _eventsPageLength}) async {
    Event2TimeFilter queryTimeFilter;
    TZDateTime? queryCustomStartTime, queryCustomEndTime;

    if ((timeFilter != null) && (timeFilter != Event2TimeFilter.customRange) || ((customStartTime != null) && (customEndTime != null))) {
      queryTimeFilter = timeFilter ?? Event2TimeFilter.upcoming;
      queryCustomStartTime = (queryTimeFilter == Event2TimeFilter.customRange) ? customStartTime : null;
      queryCustomEndTime = (queryTimeFilter == Event2TimeFilter.customRange) ? customEndTime : null;
    }
    else {
      queryTimeFilter = event2TimeFilterFromString(Storage().events2Time) ?? Event2TimeFilter.upcoming;
      queryCustomStartTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomStartTime));
      queryCustomEndTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomEndTime));
    }

    LinkedHashSet<Event2TypeFilter>? queryTypes = _queryTypes;
    Event2SortType? querySortType = _querySortType;

    bool locationNotAvailable = ((_locationServicesStatus == LocationServicesStatus.serviceDisabled) || ((_locationServicesStatus == LocationServicesStatus.permissionDenied)));
    if ((queryTypes?.contains(Event2TypeFilter.nearby) == true) && locationNotAvailable) {
      queryTypes?.remove(Event2TypeFilter.nearby);
    }
    if ((querySortType == Event2SortType.proximity) && locationNotAvailable) {
      querySortType = Event2SortType.dateTime;
    }

    if (((types?.contains(Event2TypeFilter.nearby) == true) || (sortType == Event2SortType.proximity)) && (_locationServicesStatus == LocationServicesStatus.permissionAllowed)) {
      _currentLocation = await LocationServices().location;
    }

    return Events2Query(
      offset: offset,
      limit: limit,
      timeFilter: queryTimeFilter,
      customStartTimeUtc: queryCustomStartTime?.toUtc(),
      customEndTimeUtc: queryCustomEndTime?.toUtc(),
      types: queryTypes,
      attributes: _queryAttributes,
      groupings: Event2Grouping.individualEvents(),
      sortType: querySortType,
      sortOrder: Event2SortOrder.ascending,
      location: _currentLocation,
    );
  }

  LinkedHashSet<Event2TypeFilter>? get _queryTypes =>
    types ?? LinkedHashSetUtils.from<Event2TypeFilter>(event2TypeFilterListFromStringList(Storage().events2Types));

  Map<String, dynamic>? get _queryAttributes =>
    attributes ?? Storage().events2Attributes;

  Event2SortType? get _querySortType =>
    sortType ?? event2SortTypeFromString(Storage().events2SortType) ?? Event2SortType.dateTime;

  Future<void> _reloadIfVisible({ int limit = _eventsPageLength }) async {
    if (_visible) {
      return _reload(limit: limit);
    }
    else if (_stalled.index < _Staled.reload.index) {
      _stalled = _Staled.reload;
    }
  }

  Future<void> _reload({ int limit = _eventsPageLength }) async {
    if (!_loadingEvents && !_refreshingEvents) {
      setStateIfMounted(() {
        _loadingEvents = true;
        _extendingEvents = false;
      });

      dynamic result = Connectivity().isNotOffline ? await Events2().loadEventsEx(await _queryParam(limit: limit)) : null;
      Events2ListResult? listResult = (result is Events2ListResult) ? result : null;
      List<Event2>? events = listResult?.events;
      String? errorTextResult = (result is String) ? result : null;

      setStateIfMounted(() {
        _events = (events != null) ? List<Event2>.from(events) : null;
        _totalEventsCount = listResult?.totalCount;
        _lastPageLoadedAll = (events != null) ? (events.length >= limit) : null;
        _eventsErrorText = errorTextResult;
        _loadingEvents = false;
        _stalled = _Staled.none;
        _pageViewKey = UniqueKey();
        _contentKeys.clear();
      });
    }
  }

  Future<void> _refreshIfVisible() async {
    if (_visible) {
      return _refresh();
    }
    else if (_stalled.index < _Staled.refresh.index) {
      _stalled = _Staled.refresh;
    }
  }

  Future<void> _refresh() async {

    if (!_loadingEvents && !_refreshingEvents) {
      setStateIfMounted(() {
        _refreshingEvents = true;
        _extendingEvents = false;
      });

      int limit = max(_events?.length ?? 0, _eventsPageLength);
      dynamic result = Connectivity().isNotOffline ? await Events2().loadEventsEx(await _queryParam(limit: limit)) : null;
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
          // If there was events content, preserve it. Otherwise, show the error
          _eventsErrorText = errorTextResult;
        }
        if (totalCount != null) {
          _totalEventsCount = totalCount;
        }
        _refreshingEvents = false;
        _stalled = _Staled.none;
        _pageViewKey = UniqueKey();
        _contentKeys.clear();
      });
    }
  }

  Future<void> _extend() async {
    if (!_loadingEvents && !_refreshingEvents && !_extendingEvents && Connectivity().isNotOffline) {
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
          _stalled = _Staled.none;
        });
      }
    }
  }
}