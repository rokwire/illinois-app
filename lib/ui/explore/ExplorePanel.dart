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

import 'package:flutter/semantics.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreDisplayTypeHeader.dart';
import 'package:illinois/ui/widgets/FilterWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/dining/HorizontalDiningSpecials.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/model/Dining.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:illinois/ui/explore/ExploreDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreListPanel.dart';
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/MapWidget.dart';
import 'package:illinois/ui/widgets/RoundedTab.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';

enum ExploreTab { All, NearMe, Events, Dining }

enum ExploreFilterType { categories, event_time, event_tags, payment_type, work_time }

class _PanelData {
  ExplorePanelState?         _panelState;
  ExploreTab?                _selectedTab;
  ExploreFilter?             _selectedFilter;
  bool?                      _showHeaderBack;
  bool?                      _showTabBar;
}

class _ExploreSortKey extends OrdinalSortKey {
  const _ExploreSortKey(double order) : super(order);

  static const _ExploreSortKey filterLayout = _ExploreSortKey(1.0);
  static const _ExploreSortKey headerBar = _ExploreSortKey(2.0);
}

class ExplorePanel extends StatefulWidget {

  final _PanelData _data = _PanelData();
  final String? browseGroupId;

  ExplorePanel({ExploreTab initialTab = ExploreTab.Events, ExploreFilter? initialFilter, bool showHeaderBack = true, bool showTabBar = true,  this.browseGroupId }){
    _data._selectedTab = initialTab;
    _data._showHeaderBack = showHeaderBack;
    _data._selectedFilter = initialFilter;
    _data._showTabBar = showTabBar;
  }

  void selectTab(ExploreTab? tab, {ExploreFilter? initialFilter, bool showHeaderBack = false, bool showTabBar = true}) {
    if ((_data._panelState != null) && _data._panelState!.mounted  && (tab != null)) {
      _data._panelState!.selectTab(tab, initialFilter: initialFilter);
    } else {
      _data._selectedTab = tab;
      _data._selectedFilter = initialFilter;
      _data._showHeaderBack = showHeaderBack;
      _data._showTabBar = showTabBar;
    }
  }

  static Future<void> presentDetailPanel(BuildContext context, {String? eventId}) async {
    List<Event>? events = (eventId != null) ? await Events().loadEventsByIds(Set.from([eventId])) : null;
    Event? event = ((events != null) && (0 < events.length)) ? events.first : null;
    //Explore explore = (eventId != null) ? await Events().getEventById(eventId) : null;
    //Event event = (explore is Event) ? explore : null;
    if (event != null) {
      if (event.isComposite) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => CompositeEventsDetailPanel(parentEvent: event)));
      }
      else if (event.isGameEvent) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) =>
            AthleticsGameDetailPanel(gameId: event.speaker, sportName: event.registrationLabel,)));
      }
      else {
        Navigator.push(context, CupertinoPageRoute(builder: (context) =>
          ExploreDetailPanel(explore: event)));
      }
    }
  }

  @override
  ExplorePanelState createState() {
    return _data._panelState = ExplorePanelState();
  }
}

class ExplorePanelState extends State<ExplorePanel>
    with
        SingleTickerProviderStateMixin,
        AutomaticKeepAliveClientMixin<ExplorePanel>
    implements NotificationsListener, RoundedTabListener {
  
  List<ExploreTab> _exploreTabs = [];
  ExploreTab?    _selectedTab;

  List<dynamic>? _eventCategories;
  List<Explore>? _displayExplores;
  List<String>?  _filterWorkTimeValues;
  List<String>?  _filterPaymentTypeValues;
  List<String>?  _filterEventTimeValues;
  
  Position? _locationData;
  LocationServicesStatus? _locationServicesStatus;

  ExploreFilter? _initialSelectedFilter;
  bool           _showHeaderBack = true;
  bool           _showTabBar = true;
  Map<ExploreTab, List<ExploreFilter>>? _tabToFilterMap;
  bool _filterOptionsVisible = false;

  List<DiningSpecial>? _diningSpecials;

  ScrollController _scrollController = ScrollController();

  Future<List<Explore>?>? _loadingTask;
  

  // When we click item[index == 2] -the TabBar creates and immediately dispose item[index == 1] (But _state.mounted = true)
  // as a result the ExplorePanel.panelState loses its _element so we need to recreate the panel(as workaround)
  // store if expose() is called
  bool disposed = false;

  //Maps
  static const double MapBarHeight = 114;

  bool? _mapAllowed;
  MapController? _nativeMapController;
  ListMapDisplayType _displayType = ListMapDisplayType.List;
  dynamic _selectedMapExplore;
  late AnimationController _mapExploreBarAnimationController;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Storage.offsetDateKey,
      Storage.useDeviceLocalTimeZoneKey,
      Connectivity.notifyStatusChanged,
      LocationServices.notifyStatusChanged,
      Localization.notifyStringsUpdated,
      NativeCommunicator.notifyMapSelectExplore,
      NativeCommunicator.notifyMapClearExplore,
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      Styles.notifyChanged,
    ]);

    _selectedTab = widget._data._selectedTab;
    _initialSelectedFilter = widget._data._selectedFilter;
    _showHeaderBack = widget._data._showHeaderBack ?? true;
    _showTabBar = widget._data._showTabBar ?? true;

    _initTabs();
    _initFilters();
    _loadEventCategories();
    _mapExploreBarAnimationController = AnimationController (duration: Duration(milliseconds: 200), lowerBound: -MapBarHeight, upperBound: 0, vsync: this)
      ..addListener(() {
        this._refresh(() {});
      });
    disposed = false;
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);

    if (_displayType == ListMapDisplayType.Map) {
      Analytics().logMapHide();
    }

    disposed = true;
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  bool get _hasDiningSpecials{
    return _diningSpecials != null && _diningSpecials!.isNotEmpty;
  }

  int get _exploresCount{
    int exploresCount = (_displayExplores != null) ? _displayExplores!.length : 0;

    if(_hasDiningSpecials){
      exploresCount++;
    }
    return exploresCount;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: HeaderBar(
        title:  Localization().getStringEx("panel.explore.label.title", "Explore"),
        sortKey: _ExploreSortKey.headerBar,
        leadingAsset: _showHeaderBack  ? HeaderBar.defaultLeadingAsset : null,
        onLeading: _onTapHeaderBackButton,
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        ExploreDisplayTypeHeader(
          displayType: _displayType,
          searchVisible: (_selectedTab != ExploreTab.Dining),
          additionalData: {"group_id": widget.browseGroupId},
          onTapList: () => _selectDisplayType(ListMapDisplayType.List),
          onTapMap: () => _selectDisplayType(ListMapDisplayType.Map),),
          Padding(padding: EdgeInsets.all(12), child:
            Wrap(children: _buildTabWidgets(),
            )),
        Expanded(child:
          Stack(children: <Widget>[
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Padding(padding: EdgeInsets.only(left: 12, right: 12, bottom: 12), child:
                  Wrap(children: _buildFilterWidgets(),
              ),),
              Expanded(child:
                Container(color: Styles().colors!.background, child:
                  Stack(children: <Widget>[
                    _buildMapView(),
                    _buildListView(),
                  ]),
              ),),
            ],),
            _buildFilterValuesContainer()
          ],),
        ),
      ]),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: _showTabBar ? TabBarWidget() : null,
    );
  }

  void _initTabs() {
    if (Auth2().privacyMatch(2)) {
      LocationServices().status.then((LocationServicesStatus? locationServicesStatus) {
        _locationServicesStatus = locationServicesStatus;

        if (_locationServicesStatus == LocationServicesStatus.permissionNotDetermined) {
          LocationServices().requestPermission().then((LocationServicesStatus? locationServicesStatus) {
            _locationServicesStatus = locationServicesStatus;
            _updateTabs();
          });
        }
        else {
          _updateTabs();
        }
      });
    }
    else {
        _updateTabs();
    }
  }

  void _updateTabs() {

    List<ExploreTab> exploreTabs = [];

    if (_userLocationEnabled()) {
      exploreTabs.add(ExploreTab.NearMe);
    }
    else {
      // We would like you to "omit it" (point 3.3.2).
      // exploreTabs.add(ExploreTab.All);
    }
    exploreTabs.add(ExploreTab.Events);
    exploreTabs.add(ExploreTab.Dining);

    if (!ListEquality().equals(_exploreTabs, exploreTabs)) {
      _exploreTabs = exploreTabs;

      if (!_exploreTabs.contains(_selectedTab)) {
        selectTab(_exploreTabs[0]);
      }
      else {
        _loadExplores();
      }
    }

    _enableMyLocationOnMap();
  }

  bool _userLocationEnabled() {
    return Auth2().privacyMatch(2) && (_locationServicesStatus == LocationServicesStatus.permissionAllowed);
  }

  void _initFilters() {
    _tabToFilterMap = {
      ExploreTab.All: <ExploreFilter>[
        ExploreFilter(type: ExploreFilterType.categories),
        ExploreFilter(type: ExploreFilterType.event_tags)
      ],
      ExploreTab.NearMe: <ExploreFilter>[
        ExploreFilter(type: ExploreFilterType.categories),
        ExploreFilter(type: ExploreFilterType.event_time, selectedIndexes: {2}),
        ExploreFilter(type: ExploreFilterType.event_tags)
      ],
      ExploreTab.Events: <ExploreFilter>[
        ExploreFilter(type: ExploreFilterType.categories),
        ExploreFilter(type: ExploreFilterType.event_time, selectedIndexes: {2}),
        ExploreFilter(type: ExploreFilterType.event_tags)
      ],
      ExploreTab.Dining: <ExploreFilter>[
        ExploreFilter(type: ExploreFilterType.work_time),
        ExploreFilter(type: ExploreFilterType.payment_type)
      ],
    };

    _filterEventTimeValues = [
      Localization().getStringEx('panel.explore.filter.time.upcoming', 'Upcoming'),
      Localization().getStringEx('panel.explore.filter.time.today', 'Today'),
      Localization().getStringEx('panel.explore.filter.time.next_7_days', 'Next 7 days'),
      Localization().getStringEx('panel.explore.filter.time.this_weekend', 'This Weekend'),
      Localization().getStringEx('panel.explore.filter.time.this_month', 'Next 30 days'),
    ];

    _filterPaymentTypeValues = [
      Localization().getStringEx('panel.explore.filter.payment_types.all', 'All Payment Types')  
    ];
    for (PaymentType paymentType in PaymentType.values) {
      _filterPaymentTypeValues!.add(PaymentTypeHelper.paymentTypeToDisplayString(paymentType) ?? '');
    }

    _filterWorkTimeValues = [
      Localization().getStringEx('panel.explore.filter.worktimes.all', 'All Locations'),
      Localization().getStringEx('panel.explore.filter.worktimes.open_now', 'Open Now'),
    ];
  }

  void _loadEventCategories() {
    if (Connectivity().isNotOffline) {
      Events().loadEventCategories().then((List<dynamic>? result) {
        _refresh(() {
          _eventCategories = result;
        });
        _loadExplores();
      });
    }
  }

  List<String?> _buildFilterEventDateSubLabels() {
    String dateFormat = 'MM/dd';
    DateTime now = DateTime.now();
    String? todayDateLabel = AppDateTime()
        .formatDateTime(now, format: dateFormat,
        ignoreTimeZone: true);

    //Next 7 days
    String next7DaysEnd = '${AppDateTime()
        .formatDateTime(now.add(Duration(days: 6)), format: dateFormat,
        ignoreTimeZone: true)}';
    String next7DaysLabel = '$todayDateLabel - $next7DaysEnd';

    //This weekend
    int currentWeekDay = now.weekday;
    DateTime weekendStartDate = DateTime(
        now.year, now.month, now.day, 0, 0, 0)
        .add(Duration(days: (6 - currentWeekDay)));
    DateTime weekendEndDate = weekendStartDate.add(
        Duration(days: 1, hours: 23, minutes: 59, seconds: 59));
    String? weekendStartLabel = AppDateTime().formatDateTime(
        weekendStartDate, format: dateFormat,
        ignoreTimeZone: true);
    String? weekendEndLabel = AppDateTime().formatDateTime(
        weekendEndDate, format: dateFormat, ignoreTimeZone: true);
    String weekendLabel = '$weekendStartLabel - $weekendEndLabel';

    //Next 30 days
    String? next30DaysEndLabel = AppDateTime()
        .formatDateTime(now.add(Duration(days: 30)), format: dateFormat,
        ignoreTimeZone: true);
    String next30DaysLabel = '$todayDateLabel - $next30DaysEndLabel';

    return [
      null, //Upcoming has no subLabel
      todayDateLabel,
      next7DaysLabel,
      weekendLabel,
      next30DaysLabel
    ];
  }

  List<String> _getFilterCategoriesValues() {
    List<String> categoriesValues = [];
    categoriesValues.add(Localization().getStringEx('panel.explore.filter.categories.all', 'All Categories'));
    categoriesValues.add(Localization().getStringEx('panel.explore.filter.categories.my', 'My Categories'));
    if (_eventCategories != null) {
      for (var category in _eventCategories!) {
        categoriesValues.add(category['category']);
      }
    }
    return categoriesValues;
  }

  List<String> _getFilterTagsValues() {
    List<String> tagsValues = [];
    tagsValues.add(Localization().getStringEx('panel.explore.filter.tags.all', 'All Tags'));
    tagsValues.add(Localization().getStringEx('panel.explore.filter.tags.my', 'My Tags'));
    return tagsValues;
  }

  void _loadExplores() {

    _diningSpecials = null;

    _selectMapExplore(null);

    Future<List<Explore>?>? task;
    if (Connectivity().isNotOffline) {

      List<ExploreFilter>? selectedFilterList = (_tabToFilterMap != null) ? _tabToFilterMap![_selectedTab] : null;
      switch (_selectedTab) {
        
        case ExploreTab.All:
          task = _loadAll(selectedFilterList);
          break;
        
        case ExploreTab.NearMe:
          task = _loadNearMe(selectedFilterList);
          break;
        
        case ExploreTab.Events: 
          {
            if (_initialSelectedFilter != null) {
              ExploreFilter? filter = (CollectionUtils.isNotEmpty(selectedFilterList)) ? (selectedFilterList as List<ExploreFilter?>).firstWhereOrNull((selectedFilter) =>
              selectedFilter?.type == _initialSelectedFilter?.type) : null;
              if (filter != null) {
                int filterIndex = selectedFilterList!.indexOf(filter);
                selectedFilterList.remove(filter);
                selectedFilterList.insert(filterIndex, ExploreFilter(
                    type: _initialSelectedFilter!.type, selectedIndexes: _initialSelectedFilter!.selectedIndexes, active: _initialSelectedFilter!.active));
              }
            }
            task = _loadEvents(selectedFilterList);
            break;
          }
        
        case ExploreTab.Dining:
          task = _loadDining(selectedFilterList);
          break;

        default:
          break;
      }
    }

    if (task != null) {
      _refresh(() {
        _loadingTask = task;
        _loadingTask!.then((List<Explore>? explores) {
          if (_loadingTask == task) {
            _applyExplores(explores);
          }
        });
      });
    }
    else {
      _applyExplores(null);
    }
  }

  void _applyExplores(List<Explore>? explores) {
    _refresh(() {
        _loadingTask = null;
        _displayExplores = explores;
        _placeExploresOnMap();
      });
  }

  Future<List<Explore>> _loadAll(List<ExploreFilter>? selectedFilterList) async {
    Set<String?>? categories = _getSelectedCategories(selectedFilterList);
    List<Explore> explores = [];
    List<Explore>? events = await Events().loadEvents(categories: categories, eventFilter: EventTimeFilter.upcoming);
    if (CollectionUtils.isNotEmpty(events)) {
      explores.addAll(events!);
    }
    if (_shouldLoadGames(categories)) {
      List<DateTime?> gamesTimeFrame = _getGamesTimeFrame(EventTimeFilter.upcoming);
      List<Explore>? games = await Sports().loadGames(startDate: gamesTimeFrame.first, endDate: gamesTimeFrame.last);
      if (CollectionUtils.isNotEmpty(games)) {
        explores.addAll(games!);
      }
    }
    _sortExplores(explores);
    return explores;
  }

  Future<List<Explore>?>? _loadNearMe(List<ExploreFilter>? selectedFilterList) async {
    Set<String?>? categories = _getSelectedCategories(selectedFilterList);
    Set<String>? tags = _getSelectedEventTags(selectedFilterList);
    EventTimeFilter eventFilter = _getSelectedEventTimePeriod(selectedFilterList);
    _locationData = _userLocationEnabled() ? await LocationServices().location : null;
    // Do not load games here, because they do not have proper location data (lat, long)
    return (_locationData != null) ? Events().loadEvents(locationData: _locationData, categories: categories, tags: tags, eventFilter: eventFilter) : null;
  }

  Future<List<Explore>> _loadEvents(List<ExploreFilter>? selectedFilterList) async {
    Set<String?>? categories = _getSelectedCategories(selectedFilterList);
    Set<String>? tags = _getSelectedEventTags(selectedFilterList);
    EventTimeFilter eventFilter = _getSelectedEventTimePeriod(selectedFilterList);
    List<Explore> explores = [];
    List<Explore>? events = await Events().loadEvents(categories: categories, tags: tags, eventFilter: eventFilter);
    if (CollectionUtils.isNotEmpty(events)) {
      explores.addAll(events!);
    }
    if (_shouldLoadGames(categories)) {
      List<DateTime?> gamesTimeFrame = _getGamesTimeFrame(eventFilter);
      List<Explore>? games = await Sports().loadGames(startDate: gamesTimeFrame.first, endDate: gamesTimeFrame.last);
      if (CollectionUtils.isNotEmpty(games)) {
        explores.addAll(games!);
      }
    }
    _sortExplores(explores);
    return explores;
  }

  Future<List<Explore>?> _loadDining(List<ExploreFilter>? selectedFilterList) async {
    String? workTime = _getSelectedWorkTime(selectedFilterList);
    PaymentType? paymentType = _getSelectedPaymentType(selectedFilterList);
    bool onlyOpened = (CollectionUtils.isNotEmpty(_filterWorkTimeValues)) ? (_filterWorkTimeValues![1] == workTime) : false;

    _locationData = _userLocationEnabled() ? await LocationServices().location : null;
    _diningSpecials = await Dinings().loadDiningSpecials();

    return Dinings().loadBackendDinings(onlyOpened, paymentType, _locationData);
  }

  ///
  /// Load athletics games if "All Categories" or "Athletics" categories are selected
  ///
  bool _shouldLoadGames(Set<String?>? selectedCategories) {
    return CollectionUtils.isEmpty(selectedCategories) || selectedCategories!.contains('Athletics');
  }

  ///
  /// calculates games start and end date for loading games based on EventTimeFilter
  ///
  /// returns list with 2 items. The first one is start date, the second is the end date
  ///
  List<DateTime?> _getGamesTimeFrame(EventTimeFilter eventFilter) {
    DateTime? startDate;
    DateTime? endDate;
    DateTime now = AppDateTime().now;
    switch (eventFilter) {
      case EventTimeFilter.today:
        startDate = endDate = now;
        break;
      case EventTimeFilter.thisWeekend:
        int currentWeekDay = now.weekday;
        DateTime weekendStartDateTime = DateTime(now.year, now.month, now.day, 0, 0, 0).add(Duration(days: (6 - currentWeekDay)));
        startDate = now.isBefore(weekendStartDateTime) ? weekendStartDateTime : now;
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59).add(Duration(days: (7 - currentWeekDay)));
        break;
      case EventTimeFilter.next7Day:
        startDate = now;
        endDate = now.add(Duration(days: 6));
        break;
      case EventTimeFilter.next30Days:
        DateTime next = now.add(Duration(days: 30));
        endDate = DateTime(next.year, next.month, next.day, 23, 59, 59);
        break;
      default:
        break;
    }
    return [startDate, endDate];
  }

  void _sortExplores(List<Explore> explores) {
    if (CollectionUtils.isEmpty(explores)) {
      return;
    }
    explores.sort((Explore first, Explore second) {
      if (first.exploreStartDateUtc == null || second.exploreStartDateUtc == null) {
        return 0;
      } else {
        return (first.exploreStartDateUtc!.isBefore(second.exploreStartDateUtc!)) ? -1 : 1;
      }
    });
  }

  Set<int>? _getSelectedFilterIndexes(List<ExploreFilter>? selectedFilterList, ExploreFilterType filterType) {
    if (selectedFilterList != null) {
      for (ExploreFilter selectedFilter in selectedFilterList) {
        if (selectedFilter.type == filterType) {
          return selectedFilter.selectedIndexes;
        }
      }
    }
    return null;
  }

  Set<String?>? _getSelectedCategories(List<ExploreFilter>? selectedFilterList) {
    if (selectedFilterList == null || selectedFilterList.isEmpty) {
      return null;
    }
    Set<String?>? selectedCategories;
    for (ExploreFilter selectedFilter in selectedFilterList) {
      //Apply custom logic for categories
      if (selectedFilter.type == ExploreFilterType.categories) {
        Set<int> selectedIndexes = selectedFilter.selectedIndexes;
        if (selectedIndexes.isEmpty || selectedIndexes.contains(0)) {
          break; //All Categories
        } else {
          selectedCategories = Set();
          if (selectedIndexes.contains(1)) { //My categories
            Iterable<String>? userCategories = Auth2().prefs?.interestCategories;
            if (userCategories != null && userCategories.isNotEmpty) {
              selectedCategories.addAll(userCategories);
            }
          }
          List<String> filterCategoriesValues = _getFilterCategoriesValues();
          if (filterCategoriesValues.isNotEmpty) {
            for (int selectedCategoryIndex in selectedIndexes) {
              if ((selectedCategoryIndex < filterCategoriesValues.length) &&
                  selectedCategoryIndex != 1) {
                String? singleCategory = filterCategoriesValues[selectedCategoryIndex];
                if (StringUtils.isNotEmpty(singleCategory)) {
                  selectedCategories.add(singleCategory);
                }
              }
            }
          }
        }
      }
    }
    return selectedCategories;
  }

  EventTimeFilter _getSelectedEventTimePeriod(List<ExploreFilter>? selectedFilterList) {
    Set<int>? selectedIndexes = _getSelectedFilterIndexes(selectedFilterList, ExploreFilterType.event_time);
    int index = (selectedIndexes != null && selectedIndexes.isNotEmpty) ? selectedIndexes.first : -1; //Get first one because only categories has more than one selectable index
    switch (index) {

      case 0: // 'Upcoming':
        return EventTimeFilter.upcoming;
      case 1: // 'Today':
        return EventTimeFilter.today;
      case 2: // 'Next 7 days':
        return EventTimeFilter.next7Day;
      case 3: // 'This Weekend':
        return EventTimeFilter.thisWeekend;
      
      case 4: //'Next 30 days':
        return EventTimeFilter.next30Days;
      default:
        return EventTimeFilter.upcoming;
    }

    /*//Filter by the time in the University
    DateTime nowUni = AppDateTime().getUniLocalTimeFromUtcTime(now.toUtc());
    int hoursDiffToUni = now.hour - nowUni.hour;
    DateTime startDateUni = startDate.add(Duration(hours: hoursDiffToUni));
    DateTime endDateUni = (endDate != null) ? endDate.add(
        Duration(hours: hoursDiffToUni)) : null;

    return {
      'start_date' : startDateUni,
      'end_date' : endDateUni
    };*/
  }

  Set<String>? _getSelectedEventTags(List<ExploreFilter>? selectedFilterList) {
    if (selectedFilterList == null || selectedFilterList.isEmpty) {
      return null;
    }
    for (ExploreFilter selectedFilter in selectedFilterList) {
      if (selectedFilter.type == ExploreFilterType.event_tags) {
        int index = selectedFilter.firstSelectedIndex;
        if (index == 0) {
          return null; //All Tags
        } else { //My tags
          return Auth2().prefs?.positiveTags;
        }
      }
    }
    return null;
  }

  String? _getSelectedWorkTime(List<ExploreFilter>? selectedFilterList) {
    if (selectedFilterList == null || selectedFilterList.isEmpty) {
      return null;
    }
    for (ExploreFilter selectedFilter in selectedFilterList) {
      if (selectedFilter.type == ExploreFilterType.work_time) {
        int index = selectedFilter.firstSelectedIndex;
        return (_filterWorkTimeValues!.length > index)
            ? _filterWorkTimeValues![index]
            : null;
      }
    }
    return null;
  }

  PaymentType? _getSelectedPaymentType(List<ExploreFilter>? selectedFilterList) {
    if (selectedFilterList == null || selectedFilterList.isEmpty) {
      return null;
    }
    for (ExploreFilter selectedFilter in selectedFilterList) {
      if (selectedFilter.type == ExploreFilterType.payment_type) {
        int index = selectedFilter.firstSelectedIndex;
        if (index == 0) {
          return null; //All payment types
        }
        return (_filterPaymentTypeValues!.length > index)
            ? PaymentType.values[index - 1]
            : null;
      }
    }
    return null;
  }

  List<String>? _getFilterValuesByType(ExploreFilterType filterType) {
    switch (filterType) {
      case ExploreFilterType.categories:
        return _getFilterCategoriesValues();
      case ExploreFilterType.work_time:
        return _filterWorkTimeValues;
      case ExploreFilterType.payment_type:
        return _filterPaymentTypeValues;
      case ExploreFilterType.event_time:
        return _filterEventTimeValues;
      case ExploreFilterType.event_tags:
        return _getFilterTagsValues();
      default:
        return null;
    }
  }

  String? _getFilterHintByType(ExploreFilterType filterType) {
    switch (filterType) {
      case ExploreFilterType.categories:
        return Localization().getStringEx('panel.explore.filter.categories.hint', '');
      case ExploreFilterType.work_time:
        return Localization().getStringEx('panel.explore.filter.worktimes.hint', '');
      case ExploreFilterType.payment_type:
        return Localization().getStringEx('panel.explore.filter.payment_types.hint', '');
      case ExploreFilterType.event_time:
        return Localization().getStringEx('panel.explore.filter.time.hint', '');
      case ExploreFilterType.event_tags:
        return Localization().getStringEx('panel.explore.filter.tags.hint', '');
      default:
        return null;
    }
  }

  // Build UI

  Widget _buildListView() {
    if (_loadingTask != null) {
      return _buildLoading();
    }
    
    Widget exploresContent;

    if (Connectivity().isOffline) {
      exploresContent = _buildOffline();
    }
    else if (_exploresCount > 0) {
      exploresContent = ListView.separated(
        separatorBuilder: (context, index) => Divider(
              color: Colors.transparent,
            ),
        itemCount: _exploresCount,
        itemBuilder: _buildExploreEntry,
        controller: _scrollController,
      );
    }
    else {
      exploresContent = _buildEmpty();
    }

    return Visibility(visible: (_displayType == ListMapDisplayType.List), child:
      Stack(children: [
        Container(color: Styles().colors!.background, child: exploresContent),
        _buildDimmedContainer(),
      ]),
    );
  }

  Widget _buildExploreEntry(BuildContext context, int index){
    if(_hasDiningSpecials) {
      if (index == 0) {
        return HorizontalDiningSpecials(specials: _diningSpecials,);
      }
    }

    int realIndex = _hasDiningSpecials ? index -1 : index;
    Explore? explore = _displayExplores![realIndex];

    List<ExploreFilter>? selectedFilterList = (_tabToFilterMap != null) ? _tabToFilterMap![_selectedTab] : null;
    Set<String>? tags  = _getSelectedEventTags(selectedFilterList);

    ExploreCard exploreView = ExploreCard(
        explore: explore,
        onTap: () => _onExploreTap(explore),
        locationData: _locationData,
        hideInterests: tags == null,
        showTopBorder: true,
        source: _selectedTab?.toString());
    return Padding(
        padding: EdgeInsets.only(top: 16),
        child: exploreView);
  }

  Widget _buildMapView() {
    String? title, description;
    Color? exploreColor = Colors.white;
    if (_selectedMapExplore is Explore) {
      title = _selectedMapExplore?.exploreTitle;
      description = _selectedMapExplore.exploreLocation?.description;
      exploreColor = _selectedMapExplore.uiColor;
    }
    else if  (_selectedMapExplore is List<Explore>) {
      String? exploreName = ExploreExt.getExploresListDisplayTitle(_selectedMapExplore);
      title = sprintf(Localization().getStringEx('panel.explore.map.popup.title.format', '%d %s'), [_selectedMapExplore?.length, exploreName]);
      Explore? explore = _selectedMapExplore.isNotEmpty ? _selectedMapExplore.first : null;
      description = explore?.exploreLocation?.description ?? "";
      exploreColor = explore?.uiColor ?? Styles().colors!.fillColorSecondary!;
    }

    double buttonWidth = (MediaQuery.of(context).size.width - (40 + 12)) / 2;
    return Stack(clipBehavior: Clip.hardEdge, children: <Widget>[
      (_mapAllowed == true) ? MapWidget(
        onMapCreated: _onNativeMapCreated,
        creationParams: { "myLocationEnabled" : _userLocationEnabled()},
      ) : Container(),
      Positioned(
          bottom: _mapExploreBarAnimationController.value,
          left: 0,
          right: 0,
          child: Container(
            height: MapBarHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: exploreColor!, width: 2, style: BorderStyle.solid),
                  bottom: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1, style: BorderStyle.solid)),
            ),
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text((title != null) ? title : "",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Styles().colors!.fillColorPrimary,
                              fontFamily: Styles().fontFamilies!.extraBold,
                              fontSize: 20)),
                      Text((description != null) ? description : "",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.black38,
                              fontFamily: Styles().fontFamilies!.medium,
                              fontSize: 16)),
                      Container(
                        height: 8,
                      ),
                      Row(
                        children: <Widget>[
                          _userLocationEnabled() ?
                          Row(
                              children: <Widget>[
                                SizedBox(width: buttonWidth, child: RoundedButton(
                                    label: Localization().getStringEx('panel.explore.button.directions.title', 'Directions'),
                                    hint: Localization().getStringEx('panel.explore.button.directions.hint', ''),
                                    backgroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    fontSize: 16.0,
                                    textColor: Styles().colors!.fillColorPrimary,
                                    borderColor: Styles().colors!.fillColorSecondary,
                                    onTap: () {
                                      Analytics().logSelect(target: 'Directions');
                                      _presentMapExploreDirections(context);
                                    }),),
                                Container(
                                  width: 12,
                                ),
                              ]) :
                          Container(),
                          SizedBox(width: buttonWidth, child: RoundedButton(
                              label: Localization().getStringEx('panel.explore.button.details.title', 'Details'),
                              hint: Localization().getStringEx('panel.explore.button.details.hint', ''),
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              fontSize: 16.0,
                              textColor: Styles().colors!.fillColorPrimary,
                              borderColor: Styles().colors!.fillColorSecondary,
                              onTap: () {
                                Analytics().logSelect(target: 'Details');
                                _presentMapExploreDetail(context);
                              }),),


                        ],
                      )
                    ])),
          ))
    ]);
  }

  void _selectMapExplore(dynamic explore) {
    if (explore != null) {
      _refresh(() { _selectedMapExplore = explore;});
      _mapExploreBarAnimationController.forward();
    }
    else if (_selectedMapExplore != null) {
      _mapExploreBarAnimationController.reverse().then((_){
        _refresh(() { _selectedMapExplore = null;});
      });
    }
  }

  void _presentMapExploreDirections(BuildContext context) async {
      dynamic explore = _selectedMapExplore;
      _mapExploreBarAnimationController.reverse().then((_){
        _refresh(() { _selectedMapExplore = null;});
      });
      if (explore != null) {
        NativeCommunicator().launchExploreMapDirections(target: explore);
      }
  }
  
  void _presentMapExploreDetail(BuildContext context) {
      dynamic explore = _selectedMapExplore;
      _mapExploreBarAnimationController.reverse().then((_){
        _refresh(() { _selectedMapExplore = null;});
      });

      if (explore is Explore) {
        Event? event = (explore is Event) ? explore : null;
        if (event?.isGameEvent ?? false) {
          Navigator.push(context, CupertinoPageRoute(builder: (context) =>
              AthleticsGameDetailPanel(gameId: event!.speaker, sportName: event.registrationLabel,)));
        }
        else if(explore is Game) {
          Navigator.push(context, CupertinoPageRoute(builder: (context) =>
              AthleticsGameDetailPanel(game: explore)));
        }
        else {
          Navigator.push(context, CupertinoPageRoute(builder: (context) =>
            ExploreDetailPanel(explore: explore,initialLocationData: _locationData,)));
        }
      }
      else if (explore is List<Explore>) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreListPanel(explores: explore)));
      }
  }

  Widget _buildLoading() {
    return Semantics(
      label: Localization().getStringEx('panel.explore.state.loading.title', 'Loading'),
      hint: Localization().getStringEx('panel.explore.state.loading.hint', 'Please wait'),
      excludeSemantics: true,
      child:Container(
      color: Styles().colors!.background,
      child: Align(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ),
    ));
  }

  Widget _buildEmpty() {
    String message;
    switch (_selectedTab) {
      case ExploreTab.All:    message = Localization().getStringEx('panel.explore.state.online.empty.all', 'No events.'); break;
      case ExploreTab.NearMe: message = Localization().getStringEx('panel.explore.state.online.empty.near_me', 'No events near me.'); break;
      case ExploreTab.Events: message = Localization().getStringEx('panel.explore.state.online.empty.events', 'No upcoming events.'); break;
      case ExploreTab.Dining: message = Localization().getStringEx('panel.explore.state.online.empty.dining', 'No dining locations are currently open.'); break;
      default:                message =  ''; break;
    }
    return Center(child:
      Column(children: <Widget>[
        Expanded(child: Container(), flex: 1),
        Text(message, textAlign: TextAlign.center,),
        Expanded(child: Container(), flex: 3),
      ]),
    );
  }

  Widget _buildOffline() {
    String message;
    switch (_selectedTab) {
      case ExploreTab.All:    message = Localization().getStringEx('panel.explore.state.offline.empty.all', 'No events available while offline.'); break;
      case ExploreTab.NearMe: message = Localization().getStringEx('panel.explore.state.offline.empty.near_me', 'No events near me available while offline.'); break;
      case ExploreTab.Events: message = Localization().getStringEx('panel.explore.state.offline.empty.events', 'No upcoming events available while offline..'); break;
      case ExploreTab.Dining: message = Localization().getStringEx('panel.explore.state.offline.empty.dining', 'No dining locations available while offline.'); break;
      default:                message =  ''; break;
    }
    return Center(child:
      Column(children: <Widget>[
        Expanded(child: Container(), flex: 1),
        Text(Localization().getStringEx("app.offline.message.title", "You appear to be offline"), style: TextStyle(fontSize: 16),),
        Container(height:8),
        Text(message),
        Expanded(child: Container(), flex: 3),
      ],),);
  }

  Widget _buildDimmedContainer() {
    return Visibility(
        visible: _filterOptionsVisible,
        child: BlockSemantics(child:Container(color: Color(0x99000000))));
  }

  void _selectDisplayType (ListMapDisplayType displayType) {
    Analytics().logSelect(target: displayType.toString());
    if (_displayType != displayType) {
      _refresh((){
        _displayType = displayType;
        _mapAllowed = (_displayType == ListMapDisplayType.Map) || (_mapAllowed == true);
        _enableMap(_displayType == ListMapDisplayType.Map);
      });
    }
  }

  Widget _buildFilterValuesContainer() {


    List<ExploreFilter>? tabFilters = (_tabToFilterMap != null) ? _tabToFilterMap![_selectedTab] : null;
    ExploreFilter? selectedFilter;
    if (tabFilters != null && tabFilters.isNotEmpty) {
      for (ExploreFilter filter in tabFilters) {
        if (filter.active) {
          selectedFilter = filter;
          break;
        }
      }
    }
    if (selectedFilter == null) {
      return Container();
    }
    List<String> filterValues = _getFilterValuesByType(selectedFilter.type)!;
    List<String?>? filterSubLabels = (selectedFilter.type ==
        ExploreFilterType.event_time) ? _buildFilterEventDateSubLabels() : null;
    bool hasSubLabels = CollectionUtils.isNotEmpty(filterSubLabels);
    return Semantics(sortKey: _ExploreSortKey.filterLayout,
      child: Visibility(
        visible: _filterOptionsVisible,
        child: Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 36, bottom: 40),
          child: Semantics(child:Container(
            decoration: BoxDecoration(
              color: Styles().colors!.fillColorSecondary,
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Container(
                color: Colors.white,
                child: ListView.separated(
                  shrinkWrap: true,
                  separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Styles().colors!.fillColorPrimaryTransparent03,
                      ),
                  itemCount: filterValues.length,
                  itemBuilder: (context, index) {
                    return FilterListItemWidget(
                      label: filterValues[index],
                      subLabel: hasSubLabels ? filterSubLabels![index] : null,
                      selected: (selectedFilter?.selectedIndexes != null && selectedFilter!.selectedIndexes.contains(index)),
                      onTap: () {
                        Analytics().logSelect(target: "FilterItem: ${filterValues[index]}");
                        _onFilterValueClick(selectedFilter!, index);
                      },
                    );
                  },
                  controller: _scrollController,
                ),
              ),
            ),
          ))),
    ));
  }

  List<Widget> _buildFilterWidgets() {
    List<Widget> filterTypeWidgets = [];
    List<ExploreFilter>? visibleFilters = (_tabToFilterMap != null) ? _tabToFilterMap![_selectedTab] : null;
    if (visibleFilters == null ||
        visibleFilters.isEmpty ||
        _eventCategories == null) {
      filterTypeWidgets.add(Container());
      return filterTypeWidgets;
    }

    for (int i = 0; i < visibleFilters.length; i++) {
      ExploreFilter selectedFilter = visibleFilters[i];
      if (_initialSelectedFilter != null &&
          _initialSelectedFilter!.type == selectedFilter.type) {
        selectedFilter = ExploreFilter(
            type: _initialSelectedFilter!.type,
            selectedIndexes: _initialSelectedFilter!.selectedIndexes,
            active: _initialSelectedFilter!.active);
        _initialSelectedFilter = null;
      }
      List<String> filterValues = _getFilterValuesByType(selectedFilter.type)!;
      int filterValueIndex = selectedFilter.firstSelectedIndex;
      String? filterHeaderLabel = filterValues[filterValueIndex];
      filterTypeWidgets.add(FilterSelectorWidget(
        label: filterHeaderLabel,
        hint: _getFilterHintByType(selectedFilter.type),
        active: selectedFilter.active,
        visible: true,
        onTap: (){
          Analytics().logSelect(target: "Filter: $filterHeaderLabel");
          return _onFilterTypeClicked(selectedFilter);},
      ));
    }
    return filterTypeWidgets;
  }

  List<RoundedTab> _buildTabWidgets() {

    List<RoundedTab> tabs = [];
    for (ExploreTab exploreTab in _exploreTabs) {
      tabs.add(RoundedTab(title: exploreTabName(exploreTab), hint: exploreTabHint(exploreTab), tabIndex: ExploreTab.values.indexOf(exploreTab), listener: this, selected: (_selectedTab == exploreTab)));
    }
    return tabs;
  }

  //Click listeners

  void _onExploreTap(Explore explore) {
    Analytics().logSelect(target: explore.exploreTitle);

    Event? event = (explore is Event) ? explore : null;

    if (event?.isComposite ?? false) {
      Navigator.push(
          context, CupertinoPageRoute(builder: (context) => CompositeEventsDetailPanel(parentEvent: event, initialLocationData: _locationData,browseGroupId: widget.browseGroupId,)));
    }
    else if (event?.isGameEvent ?? false) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) =>
          AthleticsGameDetailPanel(gameId: event!.speaker, sportName: event.registrationLabel,)));
    }
    else if (explore is Game) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(game: explore)));
    }
    else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) =>
          ExploreDetailPanel(explore: explore,initialLocationData: _locationData,browseGroupId: widget.browseGroupId,)
      )).then(
          (value){
            if(value!=null && value == true){
              Navigator.pop(context);
            }
          }
      );
    }
  }

  void _onFilterTypeClicked(ExploreFilter selectedFilter) {
    // Analytics().logSelect(target:...);
    List<ExploreFilter>? tabFilters = (_tabToFilterMap != null) ? _tabToFilterMap![_selectedTab] : null;
    _refresh(() {
      if (tabFilters != null) {
        for (ExploreFilter filter in tabFilters) {
          if (filter != selectedFilter) {
            filter.active = false;
          }
        }
      }
      selectedFilter.active = _filterOptionsVisible = !selectedFilter.active;
    });
  }

  void _onFilterValueClick(ExploreFilter selectedFilter, int newValueIndex) {
    //Apply custom logic for selecting event categories.
    Set<int> selectedIndexes = Set.of(selectedFilter.selectedIndexes); //Copy
    
    // JP: Change category selection back to radio button only. Only one of the possibilities should be picked at a time. Sorry I asked for the change.
    selectedIndexes = {newValueIndex};
    /*if (selectedFilter.type == ExploreFilterType.categories) {
      if (newValueIndex == 0) {
        selectedIndexes = {newValueIndex};
      } else {
        if (selectedIndexes.contains(newValueIndex)) {
          selectedIndexes.remove(newValueIndex);
          if (selectedIndexes.isEmpty) {
            selectedIndexes = {0}; //select All categories
          }
        } else {
          selectedIndexes.remove(0);
          selectedIndexes.add(newValueIndex);
        }
      }
    } else {
      selectedIndexes = {newValueIndex};
    }*/
    
    selectedFilter.selectedIndexes = selectedIndexes;
    selectedFilter.active = _filterOptionsVisible = false;
    _loadExplores();
  }

  void _onTapHeaderBackButton() {
    Navigator.pop(context);
  }

  @override
  void onTabClicked(int? tabIndex, RoundedTab tab) {
    if ((0 <= tabIndex!) && (tabIndex < ExploreTab.values.length)) {
      Analytics().logSelect(target: tab.title) ;
      selectTab(ExploreTab.values[tabIndex]);
    }
  }

  ///Public interface
  void selectTab(ExploreTab exploreTab, {ExploreFilter? initialFilter}) {
    bool reloadExplores = false;
    if (_initialSelectedFilter != initialFilter) {
      reloadExplores = true;
      _initialSelectedFilter = initialFilter;
    }
    if (exploreTab != _selectedTab) {
      reloadExplores = true;
      _selectedTab = exploreTab; //Fix initial panel opening selection
      _deactivateSelectedFilters();
      _refresh(() {
        _selectedTab = exploreTab;
      });
    }
    if (reloadExplores) {
      _loadExplores();
    }
  }

  static String? exploreTabName(ExploreTab exploreTab) {
    switch (exploreTab) {
      case ExploreTab.All:    return Localization().getStringEx('panel.explore.button.all.title', 'All');
      case ExploreTab.NearMe: return Localization().getStringEx('panel.explore.button.near_me.title', 'Events Near Me');
      case ExploreTab.Events: return Localization().getStringEx('panel.explore.button.events.title', 'Events');
      case ExploreTab.Dining: return Localization().getStringEx('panel.explore.button.dining.title', 'Dining');
      default:                return null;
    }
  }

  static String? exploreTabHint(ExploreTab exploreTab) {
    switch (exploreTab) {
      case ExploreTab.All:    return Localization().getStringEx('panel.explore.button.all.hint', '');
      case ExploreTab.NearMe: return Localization().getStringEx('panel.explore.button.near_me.hint', '');
      case ExploreTab.Events: return Localization().getStringEx('panel.explore.button.events.hint', '');
      case ExploreTab.Dining: return Localization().getStringEx('panel.explore.button.dining.hint', '');
      default:                return null;
    }
  }

  void _deactivateSelectedFilters() {
    List<ExploreFilter>? tabFilters = (_tabToFilterMap != null)
        ? _tabToFilterMap![_selectedTab] : null;
    if (tabFilters != null && tabFilters.isNotEmpty) {
      for (ExploreFilter filter in tabFilters) {
        filter.active = false;
      }
    }
    _filterOptionsVisible = false;
  }

  void _refresh(void fn()){
    if(!disposed && mounted) {
      this.setState(fn);
    }
  }

  ///Maps
  ///
  void _onNativeMapCreated(mapController) {
    _nativeMapController = mapController;
    _placeExploresOnMap();
    _enableMap(_displayType == ListMapDisplayType.Map);
    _enableMyLocationOnMap();
  }

  void _placeExploresOnMap() {
    if ((_nativeMapController != null) && (_displayExplores != null))   {
      _nativeMapController!.placePOIs(_displayExplores);
    }
  }

  void _enableMap(bool enable) {
    if (_nativeMapController != null) {
      _nativeMapController!.enable(enable);
      Analytics().logMapDisplay(action: enable ? Analytics.LogMapDisplayShowActionName : Analytics.LogMapDisplayHideActionName);
    }
  }

  void _enableMyLocationOnMap() {
    if (_nativeMapController != null) {
      _nativeMapController!.enableMyLocation(_userLocationEnabled());
    }
  }

  Explore? _exploreFromMapExplore(Explore? mapExplore) {
    String? mapExploreId = mapExplore?.exploreId;
    if ((_displayExplores != null) && (mapExploreId != null)) {
      for (Explore? displayExplore in _displayExplores!) {
        if ((displayExplore.runtimeType.toString() == mapExplore.runtimeType.toString()) && (displayExplore!.exploreId != null) && (displayExplore.exploreId == mapExploreId)) {
          return displayExplore;
        }
      }
    }
    return mapExplore; // null;
  }

  List<Explore>? _exploresFromMapExplores(List<Explore>? mapExplores) {
    List<Explore>? explores;
    if (mapExplores != null) {
      explores = <Explore>[];
      for (Explore mapExplore in mapExplores) {
        explores.add(_exploreFromMapExplore(mapExplore) ?? mapExplore);
      }
    }
    return explores;
  }

  // NotificationsListener
  
  @override
  void onNotification(String name, dynamic param) {
    if (name == LocationServices.notifyStatusChanged) {
      _onLocationServicesStatusChanged(param);
    }
    else if (name == Connectivity.notifyStatusChanged) {
      if (Connectivity().isNotOffline) {
        _loadEventCategories();
      }
    }
    else if (name == Localization.notifyStringsUpdated) {
      setState(() { });
    }
    else if (name == NativeCommunicator.notifyMapSelectExplore) {
      _onNativeMapSelectExplore(param['mapId'], param['exploreJson']);
    }
    else if (name == NativeCommunicator.notifyMapClearExplore) {
      _onNativeMapClearExplore(param['mapId']);
    }
    else if(name == Storage.offsetDateKey){
      _loadExplores();
    }
    else if(name == Storage.useDeviceLocalTimeZoneKey){
      _loadExplores();
    }
    else if (name == Auth2UserPrefs.notifyPrivacyLevelChanged) {
      _onPrivacyLevelChanged();
    }
    else if(name == Styles.notifyChanged){
      setState(() { });
    }
  }

  void _onPrivacyLevelChanged() {
    if (Auth2().privacyMatch(2)) {
      LocationServices().status.then((LocationServicesStatus? locationServicesStatus) {
        _locationServicesStatus = locationServicesStatus;
        _updateTabs();
      });
    }
    else {
        _updateTabs();
    }
  }

  void _onLocationServicesStatusChanged(LocationServicesStatus? status) {
    if (Auth2().privacyMatch(2)) {
      _locationServicesStatus = status;
      _updateTabs();
    }
  }

  void _onNativeMapSelectExplore(int? mapID, dynamic exploreJson) {
    if (_nativeMapController!.mapId == mapID) {
      dynamic explore;
      if (exploreJson is Map) {
        explore = _exploreFromMapExplore(Explore.fromJson(JsonUtils.mapValue(exploreJson)));
      }
      else if (exploreJson is List) {
        explore = _exploresFromMapExplores(Explore.listFromJson(exploreJson));
      }

      if (explore != null) {
          _selectMapExplore(explore);
      }
    }
  }
  
  void _onNativeMapClearExplore(int? mapID) {
    if (_nativeMapController!.mapId == mapID) {
      _selectMapExplore(null);
    }
  }

}

class ExploreFilter {
  ExploreFilterType type;
  Set<int> selectedIndexes;
  bool active;

  ExploreFilter(
      {required this.type, this.selectedIndexes = const {0}, this.active = false});

  int get firstSelectedIndex {
    if (selectedIndexes.isEmpty) {
      return -1;
    }
    return selectedIndexes.first;
  }
}

