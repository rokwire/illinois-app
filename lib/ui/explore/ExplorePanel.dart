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
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/Location.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Gateway.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/ui/academics/StudentCourses.dart';
import 'package:illinois/ui/explore/ExploreBuildingDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreDiningDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreEventDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreSearchPanel.dart';
import 'package:illinois/ui/laundry/LaundryRoomDetailPanel.dart';
import 'package:illinois/ui/mtd/MTDStopDeparturesPanel.dart';
import 'package:illinois/ui/wellness/appointments/AppointmentDetailPanel.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreDisplayTypeHeader.dart';
import 'package:illinois/ui/widgets/Filters.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
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
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';

enum ExploreItem { Events, Dining, Laundry, Buildings, MTDStops, StudentCourse, Appointments, StateFarmWayfinding }

enum EventsDisplayType {single, multiple, all}

enum ExploreFilterType { categories, event_time, event_tags, payment_type, work_time, student_course_terms }

class _ExploreSortKey extends OrdinalSortKey {
  const _ExploreSortKey(double order) : super(order);

  static const _ExploreSortKey filterLayout = _ExploreSortKey(1.0);
  static const _ExploreSortKey headerBar = _ExploreSortKey(2.0);
}

class ExplorePanel extends StatefulWidget {

  final ExploreItem? initialItem;
  final EventsDisplayType? eventsDisplayType;
  final ExploreFilter? initialFilter;
  final ListMapDisplayType mapDisplayType;
  final bool rootTabDisplay;
  final String? browseGroupId;

  ExplorePanel({this.initialItem, this.eventsDisplayType, this.initialFilter, this.mapDisplayType = ListMapDisplayType.List, this.rootTabDisplay = false, this.browseGroupId });

  static Future<void> presentDetailPanel(BuildContext context, {String? eventId}) async {
    List<Event>? events = (eventId != null) ? await Events().loadEventsByIds([eventId]) : null;
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
  ExplorePanelState createState() => ExplorePanelState();
}

class ExplorePanelState extends State<ExplorePanel>
  with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin<ExplorePanel>
  implements NotificationsListener {
  
  List<ExploreItem> _exploreItems = [];
  ExploreItem?    _selectedItem;
  late EventsDisplayType _selectedEventsDisplayType;

  List<dynamic>? _eventCategories;
  List<StudentCourseTerm>? _studentCourseTerms;
  List<Explore>? _displayExplores;
  List<String>?  _filterWorkTimeValues;
  List<String>?  _filterPaymentTypeValues;
  List<String>?  _filterEventTimeValues;
  
  Position? _locationData;
  LocationServicesStatus? _locationServicesStatus;

  Map<ExploreItem, List<ExploreFilter>>? _itemToFilterMap;
  bool _filterOptionsVisible = false;

  List<DiningSpecial>? _diningSpecials;

  ScrollController _scrollController = ScrollController();

  Future<List<Explore>?>? _loadingTask;
  bool? _loadingProgress;
  bool _itemsDropDownValuesVisible = false;
  bool _eventsDisplayDropDownValuesVisible = false;

  //Maps
  static const double MapBarHeight = 116;

  bool? _mapAllowed;
  MapController? _nativeMapController;
  ListMapDisplayType? _displayType;
  dynamic _selectedMapExplore;
  late AnimationController _mapExploreBarAnimationController;
  String? _loadingMapStopIdRoutes;
  List<MTDRoute>? _selectedMapStopRoutes;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Storage.offsetDateKey,
      Storage.useDeviceLocalTimeZoneKey,
      Connectivity.notifyStatusChanged,
      LocationServices.notifyStatusChanged,
      Localization.notifyStringsUpdated,
      NativeCommunicator.notifyMapSelectExplore,
      NativeCommunicator.notifyMapSelectPOI,
      NativeCommunicator.notifyMapSelectLocation,
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged,
      Styles.notifyChanged,
      StudentCourses.notifyTermsChanged,
      StudentCourses.notifySelectedTermChanged,
      StudentCourses.notifyCachedCoursesChanged,
    ]);


    _displayType = widget.mapDisplayType;
    _mapAllowed = (_displayType == ListMapDisplayType.Map);
    _selectedItem = widget.initialItem ?? _defaultExploreItem ?? ExploreItem.Events;
    _selectedEventsDisplayType = widget.eventsDisplayType ?? EventsDisplayType.single;
    _studentCourseTerms = StudentCourses().terms;
    _initFilters();

    _mapExploreBarAnimationController = AnimationController (duration: Duration(milliseconds: 200), lowerBound: -MapBarHeight, upperBound: 0, vsync: this)
      ..addListener(() {
        this._refresh(() {});
      });

    _loadingProgress = true;
    _loadEventCategories().then((List<dynamic>? result) {
      _eventCategories = result;
      _initExploreItems();
    });

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);

    if (_displayType == ListMapDisplayType.Map) {
      Analytics().logMapHide();
    }

    _mapExploreBarAnimationController.dispose();

    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
        appBar: headerBarWidget,
        body: RefreshIndicator(
          onRefresh: () => _loadExplores(progress: false),
          child: _buildContent(),
        ),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: widget.rootTabDisplay ? null : uiuc.TabBar());
  }


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

  ExploreItem? get _defaultExploreItem {
    switch(_displayType) {
      case ListMapDisplayType.List: return exploreItemFromString(Storage().selectedListExploreItem);
      case ListMapDisplayType.Map: return exploreItemFromString(Storage().selectedMapExploreItem);
      default: return null;
    }
  }

  set _defaultExploreItem(ExploreItem? value) {
    switch(_displayType) {
      case ListMapDisplayType.List: Storage().selectedListExploreItem = exploreItemToString(value); break;
      case ListMapDisplayType.Map: Storage().selectedMapExploreItem = exploreItemToString(value); break;
      default: break;
    }
  }

  void _initExploreItems() {
    if (FlexUI().isLocationServicesAvailable) {
      LocationServices().status.then((LocationServicesStatus? locationServicesStatus) {
        _locationServicesStatus = locationServicesStatus;

        if (_locationServicesStatus == LocationServicesStatus.permissionNotDetermined) {
          LocationServices().requestPermission().then((LocationServicesStatus? locationServicesStatus) {
            _locationServicesStatus = locationServicesStatus;
            _updateExploreItems();
          });
        }
        else {
          _updateExploreItems();
        }
      });
    }
    else {
        _updateExploreItems();
    }
  }

  void _updateExploreItems() {

    List<ExploreItem> exploreItems = [];
    List<dynamic>? codes = FlexUI()[(_displayType == ListMapDisplayType.Map) ? 'explore.map' : 'explore.list'];
    if (codes != null) {
      for (dynamic code in codes) {
        if (code == 'events') {
          exploreItems.add(ExploreItem.Events);
        }
        else if (code == 'dining') {
          exploreItems.add(ExploreItem.Dining);
        }
        else if (code == 'laundry') {
          exploreItems.add(ExploreItem.Laundry);
        }
        else if (code == 'buildings') {
          exploreItems.add(ExploreItem.Buildings);
        }
        else if (code == 'mtd_stops') {
          exploreItems.add(ExploreItem.MTDStops);
        }
        else if (code == 'student_courses') {
          exploreItems.add(ExploreItem.StudentCourse);
        }
        else if (code == 'appointments') {
          exploreItems.add(ExploreItem.Appointments);
        }
        else if (code == 'state_farm_wayfinding') {
          exploreItems.add(ExploreItem.StateFarmWayfinding);
        }
      }
    }
    
    if (!ListEquality().equals(_exploreItems, exploreItems)) {
      _exploreItems = exploreItems;

      if (!_exploreItems.contains(_selectedItem)) {
        selectItem(_exploreItems[0]);
      }
      else {
        _loadExplores();
      }
    }

    _enableMyLocationOnMap();
  }

  bool _userLocationEnabled() {
    return FlexUI().isLocationServicesAvailable && (_locationServicesStatus == LocationServicesStatus.permissionAllowed);
  }

  void _initFilters() {
    _itemToFilterMap = {
      ExploreItem.Events: <ExploreFilter>[
        ExploreFilter(type: ExploreFilterType.categories),
        ExploreFilter(type: ExploreFilterType.event_time, selectedIndexes: {2})
      ],
      ExploreItem.Dining: <ExploreFilter>[
        ExploreFilter(type: ExploreFilterType.work_time),
        ExploreFilter(type: ExploreFilterType.payment_type)
      ],
      ExploreItem.StudentCourse: <ExploreFilter>[
        ExploreFilter(type: ExploreFilterType.student_course_terms, selectedIndexes: { _selectedTermIndex }),
      ],
    };

    if (widget.initialFilter != null) {
      _itemToFilterMap?.forEach((ExploreItem item, List<ExploreFilter> filters) {
        for (int index = 0; index < filters.length; index++) {
          ExploreFilter filter = filters[index];
          if (filter.type == widget.initialFilter?.type) {
            filters[index] = widget.initialFilter!;
          }
        }
      });
    }

    _filterEventTimeValues = [
      Localization().getStringEx('panel.explore.filter.time.upcoming', 'Upcoming'),
      Localization().getStringEx('panel.explore.filter.time.today', 'Today'),
      Localization().getStringEx('panel.explore.filter.time.next_7_days', 'Next 7 Days'),
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

  Future<List<dynamic>?> _loadEventCategories() async {
    return Connectivity().isNotOffline ? await Events().loadEventCategories() : null;
  }

  void _updateEventCategories() {
    _loadEventCategories().then((List<dynamic>? result) {
      if (result != null) {
        _refresh(() {
          _eventCategories = result;
        });
        _loadExplores();
      }
    });
    
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

  List<String> _getFilterTermsValues() {
    List<String> categoriesValues = [];
    if (_studentCourseTerms != null) {
      for (StudentCourseTerm term in _studentCourseTerms!) {
        categoriesValues.add(term.name ?? '');
      }
    }
    return categoriesValues;
  }

  int get _selectedTermIndex {
    String? displayTermId = StudentCourses().displayTermId;
    if ((_studentCourseTerms != null) && (displayTermId != null)) {
      for (int index = 0; index < _studentCourseTerms!.length; index++) {
        if (_studentCourseTerms![index].id == displayTermId) {
          return index;
        }
      }
    }
    return -1;
  }

  Future<void> _loadExplores({bool progress = true}) async {

    _diningSpecials = null;

    _selectMapExplore(null);

    Future<List<Explore>?>? task;
    if (Connectivity().isNotOffline) {

      List<ExploreFilter>? selectedFilterList = (_itemToFilterMap != null) ? _itemToFilterMap![_selectedItem] : null;
      switch (_selectedItem) {
        
        case ExploreItem.Events: 
          task = _loadEvents(selectedFilterList);
          break;
        
        case ExploreItem.Dining:
          task = _loadDining(selectedFilterList);
          break;

        case ExploreItem.Laundry:
          task = _loadLaundry();
          break;

        case ExploreItem.Buildings:
          task = _loadBuildings();
          break;

        case ExploreItem.MTDStops:
          task = _loadMTDStops();
          break;

        case ExploreItem.StudentCourse:
          task = _loadStudentCourse(selectedFilterList);
          break;

        case ExploreItem.Appointments:
          task = _loadAppointments();
          break;

        case ExploreItem.StateFarmWayfinding:
          _clearExploresFromMap();
          _viewStateFarmPoi();
          break;

        default:
          break;
      }
    }

    if (task != null) {

      _refresh(() {
        _loadingTask = task;
        _loadingProgress = (progress == true);
      });
      
      List<Explore>? explores = await task;

      if (_loadingTask == task) {
        _applyExplores(explores);
      }
    }
    else {
      _applyExplores(null);
    }
  }

  void _applyExplores(List<Explore>? explores) {
    _refresh(() {
      _loadingTask = null;
      _loadingProgress = null;
      _displayExplores = explores;
      _placeExploresOnMap();
      if (_selectedItem == ExploreItem.Appointments) {
        if (Storage().appointmentsCanDisplay != true) {
          _showMissingAppointmentsPopup(Localization().getStringEx('panel.explore.hide.appointments.msg',
              'There is nothing to display as you have chosen not to display any past or future appointments.'));
        } else if (CollectionUtils.isEmpty(_displayExplores)) {
          _showMissingAppointmentsPopup(Localization()
              .getStringEx('panel.explore.missing.appointments.msg',
                  'You currently have no upcoming in-person appointments linked within {{app_title}} app.')
              .replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')));
        }
      }
    });
  }

  Future<List<Explore>> _loadEvents(List<ExploreFilter>? selectedFilterList) async {
    Set<String?>? categories = _getSelectedCategories(selectedFilterList);
    Set<String>? tags = _getSelectedEventTags(selectedFilterList);
    EventTimeFilter eventFilter = _getSelectedEventTimePeriod(selectedFilterList);
    List<Explore> explores = [];
    List<Event>? events = await Events().loadEvents(categories: categories, tags: tags, eventFilter: eventFilter);
    if (CollectionUtils.isNotEmpty(events)) {
      List<Event>? displayEvents = _buildDisplayEvents(events!);
      if (CollectionUtils.isNotEmpty(displayEvents)) {
        explores.addAll(displayEvents!);
      }
    }
    if (_shouldLoadGames(categories)) {
      List<DateTime?> gamesTimeFrame = _getGamesTimeFrame(eventFilter);
      List<Game>? games = await Sports().loadGames(startDate: gamesTimeFrame.first, endDate: gamesTimeFrame.last);
      if (CollectionUtils.isNotEmpty(games)) {
        List<Game>? displayGames = _buildDisplayGames(games!);
        if (CollectionUtils.isNotEmpty(displayGames)) {
          explores.addAll(displayGames!);
        }
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

  Future<List<Explore>?> _loadLaundry() async {
    LaundrySchool? laundrySchool = await Laundries().loadSchoolRooms();
    return laundrySchool?.rooms;
  }

  Future<List<Explore>?> _loadBuildings() async {
    return await Gateway().loadBuildings();
  }

  Future<List<Explore>?> _loadMTDStops() async {
    List<Explore> result = <Explore>[];
    _collectBusStops(result, stops: MTD().stops?.stops);
    return result;
  }

  void _collectBusStops(List<Explore> result, { List<MTDStop>? stops }) {
    if (stops != null) {
      for(MTDStop stop in stops) {
        if (stop.hasLocation) {
          result.add(stop);
        }
        if (stop.points != null) {
          _collectBusStops(result, stops: stop.points);
        }
      }
    }
  }

  Future<List<Explore>?> _loadStudentCourse(List<ExploreFilter>? selectedFilterList) async {
    String? termId = _getSelectedTermId(selectedFilterList) ?? StudentCourses().displayTermId;
    return (termId != null) ? StudentCourses().loadCourses(termId: termId) : null;
  }

  Future<List<Explore>?> _loadAppointments() async {
    return Appointments().loadAppointments(onlyUpcoming: true, type: AppointmentType.in_person);
  }

  void _showMissingAppointmentsPopup(String missingAppointmentsText) {
    AppAlert.showCustomDialog(
        context: context,
        contentPadding: EdgeInsets.all(0),
        contentWidget: Container(
            height: 200,
            decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: BorderRadius.circular(10.0)),
            child: Stack(alignment: Alignment.center, fit: StackFit.loose, children: [
              Padding(
                  padding: EdgeInsets.all(30),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                    Image.asset('images/block-i-orange.png'),
                    Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Text(missingAppointmentsText,
                            textAlign: TextAlign.center,
                            style: Styles().textStyles?.getTextStyle("widget.detail.small")))
                  ])),
              Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                      onTap: () {
                        Analytics().logSelect(target: 'Close missing appointments popup');
                        Navigator.of(context).pop();
                      },
                      child: Padding(padding: EdgeInsets.all(16), child: Image.asset('images/icon-x-orange.png'))))
            ])));
  }

  List<Event>? _buildDisplayEvents(List<Event> allEvents) {
    List<Event>? displayEvents;
    switch (_selectedEventsDisplayType) {
      case EventsDisplayType.all:
        displayEvents = allEvents;
        break;
      case EventsDisplayType.multiple:
        displayEvents = [];
        for (Event event in allEvents) {
          if (event.isMultiEvent) {
            displayEvents.add(event);
          }
        }
        break;
      case EventsDisplayType.single:
        displayEvents = [];
        for (Event event in allEvents) {
          if (!event.isMultiEvent) {
            displayEvents.add(event);
          }
        }
        break;
    }
    return displayEvents;
  }

  List<Game>? _buildDisplayGames(List<Game> allGames) {
    List<Game>? displayGames;
    switch (_selectedEventsDisplayType) {
      case EventsDisplayType.all:
        displayGames = allGames;
        break;
      case EventsDisplayType.multiple:
        displayGames = [];
        for (Game game in allGames) {
          if (game.isMoreThanOneDay) {
            displayGames.add(game);
          }
        }
        break;
      case EventsDisplayType.single:
        displayGames = [];
        for (Game game in allGames) {
          if (!game.isMoreThanOneDay) {
            displayGames.add(game);
          }
        }
        break;
    }
    return displayGames;
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

  ExploreFilter? _getSelectedFilter(List<ExploreFilter>? selectedFilterList, ExploreFilterType type) {
    if (selectedFilterList != null) {
      for (ExploreFilter selectedFilter in selectedFilterList) {
        if (selectedFilter.type == type) {
          return selectedFilter;
        }
      }
    }
    return null;
  }

  String? _getSelectedTermId(List<ExploreFilter>? selectedFilterList) {
    ExploreFilter? selectedFilter = _getSelectedFilter(selectedFilterList, ExploreFilterType.student_course_terms);
    int index = selectedFilter?.firstSelectedIndex ?? -1;
    return ((0 <= index) && (index < (_studentCourseTerms?.length ?? 0))) ? _studentCourseTerms![index].id : null;
  }

  void _updateSelectedTermId() {
    List<ExploreFilter>? selectedFilterList = (_itemToFilterMap != null) ? _itemToFilterMap![ExploreItem.StudentCourse] : null; 
    ExploreFilter? selectedFilter = _getSelectedFilter(selectedFilterList, ExploreFilterType.student_course_terms);
    if (selectedFilter != null) {
      selectedFilter.selectedIndexes = { _selectedTermIndex };
    }
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
      case ExploreFilterType.student_course_terms:
        return _getFilterTermsValues();
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
      case ExploreFilterType.student_course_terms:
        return Localization().getStringEx('panel.explore.filter.terms.hint', '');
      default:
        return null;
    }
  }

  // Build UI

  PreferredSizeWidget get headerBarWidget {
    String? headerLabel;
    List<Widget>? actions;
    switch (_displayType) {
      case ListMapDisplayType.List:
        headerLabel = _headerBarListTitle(_selectedItem);
        if (_selectedItem == ExploreItem.Events) {
          actions ??= <Widget>[];
          actions.add(_buildSearchHeaderButton());
        }
        break;
      case ListMapDisplayType.Map:
        headerLabel = Localization().getStringEx("panel.maps.header.title", "Map");
        break;
      default:
        break;
    }
    if (widget.rootTabDisplay) {
      return RootHeaderBar(title: headerLabel);
    } else {
      return HeaderBar(title: headerLabel, sortKey: _ExploreSortKey.headerBar, actions: actions,);
    }
  }

  Widget _buildSearchHeaderButton() {
    return Semantics(label: Localization().getStringEx('headerbar.search.title', 'Search'), hint: Localization().getStringEx('headerbar.search.hint', ''), button: true, excludeSemantics: true, child:
      InkWell(onTap: _onTapSearch, child:
        Padding(padding: EdgeInsets.all(16), child:
          Image.asset('images/icon-search.png', excludeFromSemantics: true,),
        )
      )
    );
  }

  void _onTapSearch() {
    Analytics().logSelect(target: "Search");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreSearchPanel()));
  }

  Widget _buildContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Visibility(visible: (_displayType == ListMapDisplayType.Map), child:
        Padding(padding: EdgeInsets.only(left: 16, top: 16, right: 16), child:
          _buildExploreItemsDropDownButton(),
        ),
      ),
      Expanded(child:
        Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Visibility(visible: (_selectedItem == ExploreItem.Events), child:
              Padding(padding: EdgeInsets.only(left: 16, top: 16, right: 16), child:
                _buildEventsDisplayTypesDropDownButton(),
              ),
            ),
            Expanded(child:
              Stack(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: EdgeInsets.only(left: 12, right: 12, bottom: 12), child:
                    Wrap(children: _buildFilterWidgets()),
                  ),
                  Expanded(child:
                    Container(color: Styles().colors!.background, child:
                      Stack(children: <Widget>[
                        _buildMapView(),
                        _buildListView(),
                      ]),
                    ),
                  ),
                ]),
                _buildEventsDisplayTypesDropDownContainer(),
                _buildFilterValuesContainer()
              ]),
            ),
          ]),
          _buildExploreItemsDropDownContainer()
        ]),
      ),
    ]);
  }

  Widget _buildExploreItemsDropDownButton() {
    return RibbonButton(
      textColor: Styles().colors!.fillColorSecondary,
      backgroundColor: Styles().colors!.white,
      borderRadius: BorderRadius.all(Radius.circular(5)),
      border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
      rightIconAsset: (_itemsDropDownValuesVisible ? 'images/icon-up.png' : 'images/icon-down-orange.png'),
      label: _exploreItemName(_selectedItem!),
      hint: _exploreItemHint(_selectedItem!),
      onTap: _changeExploreItemsDropDownValuesVisibility
    );
  }

  Widget _buildExploreItemsDropDownContainer() {
    return Visibility(
        visible: _itemsDropDownValuesVisible,
        child: Positioned.fill(child: Stack(children: <Widget>[_buildExploreDropDownDismissLayer(), _buildExploreItemsDropDownWidget()])));
  }

  Widget _buildExploreDropDownDismissLayer() {
    return Positioned.fill(
        child: BlockSemantics(
            child: GestureDetector(
                onTap: () {
                  setState(() {
                    _itemsDropDownValuesVisible = false;
                  });
                },
                child: Container(color: Styles().colors!.blackTransparent06))));
  }

  Widget _buildExploreItemsDropDownWidget() {
    List<Widget> itemList = <Widget>[];
    itemList.add(Container(color: Styles().colors!.fillColorSecondary, height: 2));
    for (ExploreItem exploreItem in _exploreItems) {
      if ((_selectedItem != exploreItem)) {
        itemList.add(_buildExploreDropDownItem(exploreItem));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: itemList)));
  }

  Widget _buildExploreDropDownItem(ExploreItem exploreItem) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconAsset: null,
        label: _exploreItemName(exploreItem),
        onTap: () => _onTapExploreItem(exploreItem));
  }

  void _onTapExploreItem(ExploreItem item) {
    Analytics().logSelect(target: _exploreItemName(item));
    selectItem(item);
    _defaultExploreItem = item; //Store last user selection
    _changeExploreItemsDropDownValuesVisibility();
  }

  void _changeExploreItemsDropDownValuesVisibility() {
    if (_filterOptionsVisible) {
      _deactivateSelectedFilters();
    }
    _itemsDropDownValuesVisible = !_itemsDropDownValuesVisible;
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildEventsDisplayTypesDropDownButton() {
    return RibbonButton(
      textColor: Styles().colors!.fillColorSecondary,
      backgroundColor: Styles().colors!.white,
      borderRadius: BorderRadius.all(Radius.circular(5)),
      border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
      rightIconAsset: (_eventsDisplayDropDownValuesVisible ? 'images/icon-up.png' : 'images/icon-down-orange.png'),
      label: _eventsDisplayTypeLabel(_selectedEventsDisplayType),
      onTap: _changeEventsDisplayDropDownValuesVisibility
    );
  }

  Widget _buildEventsDisplayTypesDropDownContainer() {
    return Visibility(
        visible: _eventsDisplayDropDownValuesVisible,
        child: Positioned.fill(child: Stack(children: <Widget>[_buildEventsDisplayTypesDropDownDismissLayer(), _buildEventsDisplayTypesDropDownWidget()])));
  }

  Widget _buildEventsDisplayTypesDropDownDismissLayer() {
    return Positioned.fill(
        child: BlockSemantics(
            child: GestureDetector(
                onTap: () {
                  setState(() {
                    _eventsDisplayDropDownValuesVisible = false;
                  });
                },
                child: Container(color: Styles().colors!.blackTransparent06))));
  }

  Widget _buildEventsDisplayTypesDropDownWidget() {
    List<Widget> displayTypesWidgetList = <Widget>[];
    displayTypesWidgetList.add(Container(color: Styles().colors!.fillColorSecondary, height: 2));
    for (EventsDisplayType displayType in EventsDisplayType.values) {
      if ((_selectedEventsDisplayType != displayType)) {
        displayTypesWidgetList.add(_buildEventsDisplayTypeDropDownItem(displayType));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: displayTypesWidgetList)));
  }

  Widget _buildEventsDisplayTypeDropDownItem(EventsDisplayType displayType) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconAsset: null,
        label: _eventsDisplayTypeLabel(displayType),
        onTap: () => _onTapEventsDisplayType(displayType));
  }

  void _onTapEventsDisplayType(EventsDisplayType displayType) {
    Analytics().logSelect(target: _eventsDisplayTypeLabel(displayType));
    if (_selectedEventsDisplayType != displayType) {
      _refresh(() {
        _selectedEventsDisplayType = displayType;
      });
      _loadExplores();
    }
    _changeEventsDisplayDropDownValuesVisibility();
  }

  void _changeEventsDisplayDropDownValuesVisibility() {
    if (_filterOptionsVisible) {
      _deactivateSelectedFilters();
    }
    _eventsDisplayDropDownValuesVisible = !_eventsDisplayDropDownValuesVisible;
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildListView() {
    if (_loadingProgress == true) {
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

    List<ExploreFilter>? selectedFilterList = (_itemToFilterMap != null) ? _itemToFilterMap![_selectedItem] : null;
    Set<String>? tags  = _getSelectedEventTags(selectedFilterList);

    ExploreCard exploreView = ExploreCard(
        explore: explore,
        onTap: () => _onExploreTap(explore),
        locationData: _locationData,
        hideInterests: tags == null,
        showTopBorder: true,
        source: _selectedItem?.toString());
    return Padding(
        padding: EdgeInsets.only(top: 16),
        child: exploreView);
  }

  Widget _buildMapView() {
    String? title, description;
    String detailsLabel = Localization().getStringEx('panel.explore.button.details.title', 'Details');
    String detailsHint = Localization().getStringEx('panel.explore.button.details.hint', '');
    Color? exploreColor;
    Widget? descriptionWidget;
    bool canDirections = _userLocationEnabled(), canDetail = true;

    if (_selectedMapExplore is Explore) {
      title = _selectedMapExplore?.exploreTitle;
      description = _selectedMapExplore.exploreLocationDescription;
      exploreColor = (_selectedMapExplore as Explore).uiColor ?? Styles().colors?.white;
      if (_selectedMapExplore is MTDStop) {
        detailsLabel = Localization().getStringEx('panel.explore.button.bus_schedule.title', 'Bus Schedule');
        detailsHint = Localization().getStringEx('panel.explore.button.bus_schedule.hint', '');
        descriptionWidget = _buildStopDescription();
      }
      canDetail = !(_selectedMapExplore is ExplorePOI);
    }
    else if  (_selectedMapExplore is List<Explore>) {
      String? exploreName = ExploreExt.getExploresListDisplayTitle(_selectedMapExplore);
      title = sprintf(Localization().getStringEx('panel.explore.map.popup.title.format', '%d %s'), [_selectedMapExplore?.length, exploreName]);
      Explore? explore = _selectedMapExplore.isNotEmpty ? _selectedMapExplore.first : null;
      description = explore?.exploreLocation?.description ?? "";
      exploreColor = explore?.uiColor ?? Styles().colors?.fillColorSecondary;
    }
    else {
      exploreColor = Styles().colors?.white;
      canDirections = canDetail = false;
    }

    double buttonWidth = (MediaQuery.of(context).size.width - (40 + 12)) / 2;

    return Stack(clipBehavior: Clip.hardEdge, children: <Widget>[
      (_mapAllowed == true) ? MapWidget(
        onMapCreated: _onNativeMapCreated,
        creationParams: { "myLocationEnabled" : _userLocationEnabled(), "levelsEnabled": Storage().debugMapShowLevels},
      ) : Container(),
      Positioned(bottom: _mapExploreBarAnimationController.value, left: 0, right: 0, child:
        Container(height: MapBarHeight, decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: exploreColor!, width: 2, style: BorderStyle.solid), bottom: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1, style: BorderStyle.solid),),), child:
          Stack(children: [
            Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Padding(padding: EdgeInsets.only(right: 10), child:
                  Text(title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20, color: Styles().colors!.fillColorPrimary, )),
                ),
                (descriptionWidget != null) ?
                  Row(children: <Widget>[
                    Text(description ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Colors.black38,)),
                    descriptionWidget
                  ]) :
                  Text(description ?? "", overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Colors.black38,)),
                Container(height: 8,),
                Row(children: <Widget>[
                  SizedBox(width: buttonWidth, child:
                    RoundedButton(
                      label: Localization().getStringEx('panel.explore.button.directions.title', 'Directions'),
                      hint: Localization().getStringEx('panel.explore.button.directions.hint', ''),
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      fontSize: 16.0,
                      textColor: canDirections ? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent,
                      borderColor: canDirections ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
                      onTap: _onTapMapExploreDirections
                    ),
                  ),
                  Container(width: 12,),
                  SizedBox(width: buttonWidth, child:
                    RoundedButton(
                      label: detailsLabel,
                      hint: detailsHint,
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      fontSize: 16.0,
                      textColor: canDetail ? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent,
                      borderColor: canDetail ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
                      onTap: _onTapMapExploreDetail,
                    ),
                  ),
                ],),
              ]),
            ),
            (_selectedMapExplore is Favorite) ?
              Align(alignment: Alignment.topRight, child:
                FavoriteButton(favorite: (_selectedMapExplore as Favorite), style: FavoriteIconStyle.Button, padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),),
              ) :
              Container(),
          ],),
        ),
      )
    ]);
  }

  Widget? _buildStopDescription() {
    if (_loadingMapStopIdRoutes != null) {
      return Padding(padding: EdgeInsets.only(left: 8), child:
        SizedBox(width: 16, height: 16, child:
          CircularProgressIndicator(color: Styles().colors?.mtdColor, strokeWidth: 2,),
        ),
      );
    }
    else {
      List<Widget> routeWidgets = <Widget>[];
      if (_selectedMapStopRoutes != null) {
        for (MTDRoute route in _selectedMapStopRoutes!) {
          routeWidgets.add(
            Padding(padding: EdgeInsets.only(left: routeWidgets.isNotEmpty ? 6 : 0), child:
              Container(decoration: BoxDecoration(color: route.color, border: Border.all(color: route.textColor ?? Colors.transparent, width: 1), borderRadius: BorderRadius.circular(5)), child:
                Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), child:
                  Text(route.shortName ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 12, color: route.textColor,)),
                )
              )
            )
          );
        }
      }
      if (routeWidgets.isNotEmpty) {
        return Padding(padding: EdgeInsets.only(left: 8), child:
          SingleChildScrollView(scrollDirection: Axis.horizontal, child:
            Row(children: routeWidgets,)
          ),
        );
      }
      else {
        return null;
      }
    }
  }

  void _selectMapExplore(dynamic explore) {
    if (explore != null) {
      _nativeMapController?.markPOI((explore is ExplorePOI) ? explore : null);
      _refresh(() { _selectedMapExplore = explore; });
      _updateSelectedMapStopRoutes();
      _mapExploreBarAnimationController.forward();
    }
    else if (_selectedMapExplore != null) {
      _nativeMapController?.markPOI(null);
      _mapExploreBarAnimationController.reverse().then((_){
        _refresh(() { _selectedMapExplore = null; });
        _updateSelectedMapStopRoutes();
      });
    }
  }

  void _onTapMapExploreDirections() {
    Analytics().logSelect(target: 'Directions');
    if (_userLocationEnabled()) {
      dynamic explore = _selectedMapExplore;
      _selectMapExplore(null);
      if (explore != null) {
        NativeCommunicator().launchExploreMapDirections(target: explore);
      }
    }
    else {
      AppAlert.showMessage(context, Localization().getStringEx("panel.explore.directions.na.msg", "You need to enable location services in order to get navigation directions."));
    }
  }
  
  void _onTapMapExploreDetail() {
    Analytics().logSelect(target: (_selectedMapExplore is MTDStop) ? 'Bus Schedule' : 'Details');

    Route? route;
    String? message;
    if (_selectedMapExplore is Event) {
      if (_selectedMapExplore.isGameEvent) {
        route = CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(gameId: _selectedMapExplore.speaker, sportName: _selectedMapExplore.registrationLabel,),);
      }
      else if (_selectedMapExplore.isComposite) {
        route = CupertinoPageRoute(builder: (context) => CompositeEventsDetailPanel(parentEvent: _selectedMapExplore),);
      }
      else {
        route = CupertinoPageRoute(builder: (context) => ExploreEventDetailPanel(event: _selectedMapExplore, initialLocationData: _locationData),);
      }
    }
    else if (_selectedMapExplore is Dining) {
      route = CupertinoPageRoute(builder: (context) => ExploreDiningDetailPanel(dining: _selectedMapExplore, initialLocationData: _locationData),);
    }
    else if (_selectedMapExplore is LaundryRoom) {
      route = CupertinoPageRoute(builder: (context) => LaundryRoomDetailPanel(room: _selectedMapExplore),);
    }
    else if (_selectedMapExplore is Game) {
      route = CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(game: _selectedMapExplore),);
    }
    else if (_selectedMapExplore is Building) {
      route = CupertinoPageRoute(builder: (context) => ExploreBuildingDetailPanel(building: _selectedMapExplore),);
    }
    else if (_selectedMapExplore is MTDStop) {
      route = CupertinoPageRoute(builder: (context) => MTDStopDeparturesPanel(stop: _selectedMapExplore,),);
    }
    else if (_selectedMapExplore is StudentCourse) {
      route = CupertinoPageRoute(builder: (context) => StudentCourseDetailPanel(course: _selectedMapExplore,),);
    }
    else if (_selectedMapExplore is Appointment) {
      route = CupertinoPageRoute(builder: (context) => AppointmentDetailPanel(appointment: _selectedMapExplore),);
    }
    else if (_selectedMapExplore is ExplorePOI) {
      message = Localization().getStringEx("panel.explore.details.na.msg", "Details are not available for custom points of interests.");
    }
    else if (_selectedMapExplore is Explore) {
      route = CupertinoPageRoute(builder: (context) => ExploreDetailPanel(explore: _selectedMapExplore, initialLocationData: _locationData,),);
    }
    else if (_selectedMapExplore is List<Explore>) {
      route = CupertinoPageRoute(builder: (context) => ExploreListPanel(explores: _selectedMapExplore),);
    }

    if (route != null) {
      _selectMapExplore(null);
      Navigator.push(context, route);
    }
    else if (message != null) {
      AppAlert.showMessage(context, message);
    }
  }

  void _updateSelectedMapStopRoutes() {
    String? stopId = (_selectedMapExplore is MTDStop) ? (_selectedMapExplore as MTDStop).id : null;
    if ((stopId != null) && (stopId != _loadingMapStopIdRoutes)) {
      _refresh(() { _loadingMapStopIdRoutes = stopId; });
      MTD().getRoutes(stopId: stopId).then((List<MTDRoute>? routes) {
        String? currentStopId = (_selectedMapExplore is MTDStop) ? (_selectedMapExplore as MTDStop).id : null;
        if (currentStopId == stopId) {
          _refresh(() {
            _loadingMapStopIdRoutes = null;
            _selectedMapStopRoutes = MTDRoute.mergeUiRoutes(routes);
          });
        }
      });
    }
    else if ((stopId == null) && ((_loadingMapStopIdRoutes != null) || (_selectedMapStopRoutes != null))) {
      _refresh(() {
        _loadingMapStopIdRoutes = null;
        _selectedMapStopRoutes = null;
      });
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
    switch (_selectedItem) {
      case ExploreItem.Events: message = Localization().getStringEx('panel.explore.state.online.empty.events', 'No upcoming events.'); break;
      case ExploreItem.Dining: message = Localization().getStringEx('panel.explore.state.online.empty.dining', 'No dining locations are currently open.'); break;
      case ExploreItem.Laundry: message = Localization().getStringEx('panel.explore.state.online.empty.laundry', 'No laundry locations are currently open.'); break;
      case ExploreItem.Buildings: message = Localization().getStringEx('panel.explore.state.online.empty.buildings', 'No building locations available.'); break;
      case ExploreItem.MTDStops: message = Localization().getStringEx('panel.explore.state.online.empty.bus_stops', 'No bus stop locations available.'); break;
      case ExploreItem.StudentCourse: message = Localization().getStringEx('panel.explore.state.online.empty.student_course', 'No student courses available.'); break;
      default:  message =  ''; break;
    }
    return SingleChildScrollView(child:
      Center(child:
        Column(children: <Widget>[
          Container(height: MediaQuery.of(context).size.height / 5),
          Text(message, textAlign: TextAlign.center,),
          Container(height: MediaQuery.of(context).size.height / 5 * 3),
        ]),
      ),
    );
  }

  Widget _buildOffline() {
    String message;
    switch (_selectedItem) {
      case ExploreItem.Events:              message = Localization().getStringEx('panel.explore.state.offline.empty.events', 'No upcoming events available while offline..'); break;
      case ExploreItem.Dining:              message = Localization().getStringEx('panel.explore.state.offline.empty.dining', 'No dining locations available while offline.'); break;
      case ExploreItem.Laundry:             message = Localization().getStringEx('panel.explore.state.offline.empty.laundry', 'No laundry locations available while offline.'); break;
      case ExploreItem.Buildings:           message = Localization().getStringEx('panel.explore.state.offline.empty.buildings', 'No building locations available while offline.'); break;
      case ExploreItem.MTDStops:            message = Localization().getStringEx('panel.explore.state.offline.empty.bus_stops', 'No bus stop locations available while offline.'); break;
      case ExploreItem.StudentCourse:       message = Localization().getStringEx('panel.explore.state.offline.empty.student_course', 'No student courses available while offline.'); break;
      case ExploreItem.StateFarmWayfinding: message = Localization().getStringEx('panel.explore.state.offline.empty.state_farm', 'No State Farm Wayfinding available while offline.'); break;
      default:                              message =  ''; break;
    }
    return SingleChildScrollView(child:
      Center(child:
        Column(children: <Widget>[
          Container(height: MediaQuery.of(context).size.height / 5),
          Text(Localization().getStringEx("common.message.offline", "You appear to be offline"), style: TextStyle(fontSize: 16),),
          Container(height: 8),
          Text(message),
          Container(height: MediaQuery.of(context).size.height / 5 * 3),
        ],),),
    );
  }

  Widget _buildDimmedContainer() {
    return Visibility(
        visible: _filterOptionsVisible,
        child: BlockSemantics(child:Container(color: Color(0x99000000))));
  }

  /*void _selectDisplayType(ListMapDisplayType displayType) {
    Analytics().logSelect(target: displayType.toString());
    if (_displayType != displayType) {
      _refresh((){
        _displayType = displayType;
        _mapAllowed = (_displayType == ListMapDisplayType.Map) || (_mapAllowed == true);
        _enableMap(_displayType == ListMapDisplayType.Map);
        Analytics().logMapDisplay(action: (_displayType == ListMapDisplayType.Map) ? Analytics.LogMapDisplayShowActionName : Analytics.LogMapDisplayHideActionName);
      });
    }
  }*/

  Widget _buildFilterValuesContainer() {


    List<ExploreFilter>? itemFilters = (_itemToFilterMap != null) ? _itemToFilterMap![_selectedItem] : null;
    ExploreFilter? selectedFilter;
    if (itemFilters != null && itemFilters.isNotEmpty) {
      for (ExploreFilter filter in itemFilters) {
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
                    return  FilterListItem(
                      title: filterValues[index],
                      description: hasSubLabels ? filterSubLabels![index] : null,
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
    List<ExploreFilter>? visibleFilters = (_itemToFilterMap != null) ? _itemToFilterMap![_selectedItem] : null;
    if (visibleFilters == null ||
        visibleFilters.isEmpty ||
        _eventCategories == null) {
      filterTypeWidgets.add(Container());
      return filterTypeWidgets;
    }

    for (int i = 0; i < visibleFilters.length; i++) {
      ExploreFilter selectedFilter = visibleFilters[i];
      List<String> filterValues = _getFilterValuesByType(selectedFilter.type)!;
      int filterValueIndex = selectedFilter.firstSelectedIndex;
      String? filterHeaderLabel = filterValues[filterValueIndex];
      filterTypeWidgets.add(FilterSelector(
        title: filterHeaderLabel,
        hint: _getFilterHintByType(selectedFilter.type),
        active: selectedFilter.active,
        onTap: (){
          Analytics().logSelect(target: "Filter: $filterHeaderLabel");
          return _onFilterTypeClicked(selectedFilter);},
      ));
    }
    return filterTypeWidgets;
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
    List<ExploreFilter>? itemFilters = (_itemToFilterMap != null) ? _itemToFilterMap![_selectedItem] : null;
    _refresh(() {
      if (itemFilters != null) {
        for (ExploreFilter filter in itemFilters) {
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

    if (selectedFilter.type == ExploreFilterType.student_course_terms) {
      StudentCourseTerm? term = ListUtils.entry(_studentCourseTerms, newValueIndex);
      if (term != null) {
        StudentCourses().selectedTermId = term.id;
      }
    }
    
    _loadExplores();
  }

  ///Public interface
  void selectItem(ExploreItem exploreItem, {ExploreFilter? initialFilter}) {
    bool reloadExplores = false;
    if (exploreItem != _selectedItem) {
      reloadExplores = true;
      _selectedItem = exploreItem; //Fix initial panel opening selection
      _deactivateSelectedFilters();
      _refresh(() {
        _selectedItem = exploreItem;
      });
    }
    if (reloadExplores) {
      _loadExplores();
    }
  }

  static String? _exploreItemName(ExploreItem exploreItem) {
    switch (exploreItem) {
      case ExploreItem.Events:              return Localization().getStringEx('panel.explore.button.events.title', 'Events');
      case ExploreItem.Dining:              return Localization().getStringEx('panel.explore.button.dining.title', 'Residence Hall Dining');
      case ExploreItem.Laundry:             return Localization().getStringEx('panel.explore.button.laundry.title', 'Laundry');
      case ExploreItem.Buildings:           return Localization().getStringEx('panel.explore.button.buildings.title', 'Campus Buildings');
      case ExploreItem.MTDStops:            return Localization().getStringEx('panel.explore.button.bus_stops.title', 'MTD Bus');
      case ExploreItem.StudentCourse:       return Localization().getStringEx('panel.explore.button.student_course.title', 'My Courses');
      case ExploreItem.Appointments:        return Localization().getStringEx('panel.explore.button.appointments.title', 'MyMcKinley In-Person Appointments');
      case ExploreItem.StateFarmWayfinding: return Localization().getStringEx('panel.explore.button.state_farm.title', 'State Farm Wayfinding');
      default:                              return null;
    }
  }

  static String? _exploreItemHint(ExploreItem exploreItem) {
    switch (exploreItem) {
      case ExploreItem.Events:              return Localization().getStringEx('panel.explore.button.events.hint', '');
      case ExploreItem.Dining:              return Localization().getStringEx('panel.explore.button.dining.hint', '');
      case ExploreItem.Laundry:             return Localization().getStringEx('panel.explore.button.laundry.hint', '');
      case ExploreItem.Buildings:           return Localization().getStringEx('panel.explore.button.buildings.hint', '');
      case ExploreItem.MTDStops:            return Localization().getStringEx('panel.explore.button.bus_stops.hint', '');
      case ExploreItem.StudentCourse:       return Localization().getStringEx('panel.explore.button.student_course.hint', '');
      case ExploreItem.Appointments:        return Localization().getStringEx('panel.explore.button.appointments.hint', '');
      case ExploreItem.StateFarmWayfinding: return Localization().getStringEx('panel.explore.button.state_farm.hint', '');
      default:                              return null;
    }
  }

  static String? _headerBarListTitle(ExploreItem? exploreItem) {
    switch (exploreItem) {
      case ExploreItem.Events:              return Localization().getStringEx('panel.explore.header.events.title', 'Events');
      case ExploreItem.Dining:              return Localization().getStringEx('panel.explore.header.dining.title', 'Residence Hall Dining');
      case ExploreItem.Laundry:             return Localization().getStringEx('panel.explore.header.laundry.title', 'Laundry');
      case ExploreItem.Buildings:           return Localization().getStringEx('panel.explore.header.buildings.title', 'Campus Buildings');
      case ExploreItem.MTDStops:            return Localization().getStringEx('panel.explore.header.bus_stops.title', 'MTD Bus');
      case ExploreItem.StudentCourse:       return Localization().getStringEx('panel.explore.header.student_course.title', 'My Courses');
      case ExploreItem.Appointments:        return Localization().getStringEx('panel.explore.header.appointments.title', 'MyMcKinley In-Person Appointments');
      case ExploreItem.StateFarmWayfinding: return Localization().getStringEx('panel.explore.header.state_farm.title', 'State Farm Wayfinding');
      default:                              return null;
    }
  }

  static String? _eventsDisplayTypeLabel(EventsDisplayType type) {
    switch (type) {
      case EventsDisplayType.all:       return Localization().getStringEx('panel.explore.button.events.display_type.all.label', 'All Events');
      case EventsDisplayType.multiple:  return Localization().getStringEx('panel.explore.button.events.display_type.multiple.label', 'Multi-day events');
      case EventsDisplayType.single:    return Localization().getStringEx('panel.explore.button.events.display_type.single.label', 'Single day events');
      default:                      return null;
    }
  }

  void _deactivateSelectedFilters() {
    List<ExploreFilter>? itemFilters = (_itemToFilterMap != null)
        ? _itemToFilterMap![_selectedItem] : null;
    if (itemFilters != null && itemFilters.isNotEmpty) {
      for (ExploreFilter filter in itemFilters) {
        filter.active = false;
      }
    }
    _filterOptionsVisible = false;
  }

  void _refresh(void fn()){
    if(mounted) {
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
    if (_nativeMapController != null)   {
      _nativeMapController!.placePOIs(_displayExplores, options: <String, dynamic>{
        MapController.HideBuildingLabelsParams : (_selectedItem == ExploreItem.Buildings) ? true : null,
        MapController.HideBusStopPOIsParams : (_selectedItem == ExploreItem.MTDStops) ? true : null,
        MapController.ShowMarkerPopupsParams: (_selectedItem != ExploreItem.MTDStops) ? true : false,
      });
    }
  }

  void _clearExploresFromMap() {
    if (_nativeMapController != null) {
      _nativeMapController!.placePOIs(null);
    }
  }

  void _enableMap(bool enable) {
    if (_nativeMapController != null) {
      _nativeMapController!.enable(enable);
    }
  }

  void _enableMyLocationOnMap() {
    if (_nativeMapController != null) {
      _nativeMapController!.enableMyLocation(_userLocationEnabled());
    }
  }

  void _viewStateFarmPoi() {
    Analytics().logSelect(target: "State Farm Wayfinding");
    if (_nativeMapController != null) {
      _nativeMapController!.viewPOI({
        'latitude': Config().stateFarmWayfinding['latitude'],
        'longitude': Config().stateFarmWayfinding['longitude'],
        'zoom': Config().stateFarmWayfinding['zoom'],
      });
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
        _updateEventCategories();
      }
    }
    else if (name == Localization.notifyStringsUpdated) {
      _refresh(() { });
    }
    else if (name == NativeCommunicator.notifyMapSelectExplore) {
      _onNativeMapSelectExplore(param);
    }
    else if (name == NativeCommunicator.notifyMapSelectPOI) {
      _onNativeMapSelectPOI(param);
    }
    else if (name == NativeCommunicator.notifyMapSelectLocation) {
      _onNativeMapSelectLocation(param);
    }
    else if(name == Storage.offsetDateKey){
      _loadExplores();
    }
    else if(name == Storage.useDeviceLocalTimeZoneKey){
      _loadExplores();
    }
    else if (name == Auth2UserPrefs.notifyPrivacyLevelChanged) {
      _updateLocationServicesStatus();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _refresh(() { });
    }
    else if (name == FlexUI.notifyChanged) {
      _updateLocationServicesStatus();
      _updateExploreItems();
    }
    else if (name == Styles.notifyChanged){
      _refresh(() { });
    }
    else if (name == StudentCourses.notifyTermsChanged){
      _refresh(() {
        _studentCourseTerms = StudentCourses().terms;
      });
      _loadExplores();
    }
    else if (name == StudentCourses.notifySelectedTermChanged) {
      _refresh(() {
        _updateSelectedTermId();
      });
      _loadExplores();
    }
    else if (name == StudentCourses.notifyCachedCoursesChanged) {
      if ((param == null) || (StudentCourses().displayTermId == param)) {
        _loadExplores();
      }
    }
  }

  void _updateLocationServicesStatus() {
    if (FlexUI().isLocationServicesAvailable) {
      LocationServices().status.then((LocationServicesStatus? locationServicesStatus) {
        _locationServicesStatus = locationServicesStatus;
        _updateExploreItems();
      });
    }
    else {
        _updateExploreItems();
    }
  }

  void _onLocationServicesStatusChanged(LocationServicesStatus? status) {
    if (FlexUI().isLocationServicesAvailable) {
      _locationServicesStatus = status;
      _updateExploreItems();
    }
  }

  void _onNativeMapSelectExplore(Map<String, dynamic>? params) {
    int? mapId = (params != null) ? JsonUtils.intValue(params['mapId']) : null;
    if (_nativeMapController?.mapId == mapId) {
      dynamic explore;
      dynamic exploreJson = (params != null) ? params['explore'] : null;
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
  
  void _onNativeMapSelectPOI(Map<String, dynamic>? params) {
    int? mapId = (params != null) ? JsonUtils.intValue(params['mapId']) : null;
    if (_nativeMapController?.mapId == mapId) {
      Map<String, dynamic>? poi = (params != null) ? JsonUtils.mapValue(params['poi']) : null;
      String? poiName = (poi != null) ? JsonUtils.stringValue(poi['name']) : null;
      LatLng? poiLocation = (poi != null) ? LatLng.fromJson(JsonUtils.mapValue(poi['location'])) : null;
      if ((poiName != null) || (poiLocation != null)) {
        MTDStop? mtdStop = MTD().stops?.findStop(name: poiName, location: poiLocation, locationThresholdDistance: 10 /*in meters*/);
        if ((mtdStop == null) && (poiName != null) && (poiLocation != null)) {
          mtdStop = MTD().stops?.findStop(name: poiName) ??
            MTD().stops?.findStop(location: poiLocation, locationThresholdDistance: 10 /*in meters*/);
        }
        _selectMapExplore(mtdStop ?? ExplorePOI.fromJson(poi));
      }
    }
  }

  void _onNativeMapSelectLocation(Map<String, dynamic>? params) {
    int? mapId = (params != null) ? JsonUtils.intValue(params['mapId']) : null;
    if (_nativeMapController?.mapId == mapId) {
      LatLng? location = (params != null) ? LatLng.fromJson(JsonUtils.mapValue(params['location'])) : null;
      MTDStop? mtdStop = (location != null) ? MTD().stops?.findStop(location: location, locationThresholdDistance: 25 /*in meters*/) : null;
      if (mtdStop != null) {
        _selectMapExplore(mtdStop);
      }
      else if (_selectedMapExplore != null) {
        _selectMapExplore(null);
      }
      else if (location?.isValid ?? false){
        _selectMapExplore(ExplorePOI(location: ExploreLocation(latitude: location?.latitude, longitude: location?.longitude)));
      }
    }
  }

}

////////////////////
// ExploreFilter

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

////////////////////
// ExploreItem


ExploreItem? exploreItemFromString(String? value) {
  if (value == 'events') {
    return ExploreItem.Events;
  }
  else if (value == 'dining') {
    return ExploreItem.Dining;
  }
  else if (value == 'laundry') {
    return ExploreItem.Laundry;
  }
  else if (value == 'buildings') {
    return ExploreItem.Buildings;
  }
  else if (value == 'mtdStops') {
    return ExploreItem.MTDStops;
  }
  else if (value == 'studentCourse') {
    return ExploreItem.StudentCourse;
  }
  else if (value == 'appointments') {
    return ExploreItem.Appointments;
  }
  else if (value == 'stateFarmWayfinding') {
    return ExploreItem.StateFarmWayfinding;
  }
  else {
    return null;
  }
}

String? exploreItemToString(ExploreItem? value) {
  switch(value) {
    case ExploreItem.Events: return 'events';
    case ExploreItem.Dining: return 'dining';
    case ExploreItem.Laundry: return 'laundry';
    case ExploreItem.Buildings: return 'buildings';
    case ExploreItem.MTDStops: return 'mtdStops';
    case ExploreItem.StudentCourse: return 'studentCourse';
    case ExploreItem.Appointments: return 'appointments';
    case ExploreItem.StateFarmWayfinding: return 'stateFarmWayfinding';
    default: return null;
  }
}
