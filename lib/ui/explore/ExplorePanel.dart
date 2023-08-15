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
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/ui/explore/ExploreSearchPanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:illinois/ui/widgets/Filters.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/dining/HorizontalDiningSpecials.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/model/Dining.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:illinois/ui/explore/ExploreDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';

enum ExploreType { Events, Dining }

enum EventsDisplayType { single, multiple, all }

enum ExploreFilterType { categories, event_time, event_tags, payment_type, work_time, student_course_terms }

class _ExploreSortKey extends OrdinalSortKey {
  const _ExploreSortKey(double order) : super(order);

  static const _ExploreSortKey filterLayout = _ExploreSortKey(1.0);
  static const _ExploreSortKey headerBar = _ExploreSortKey(2.0);
}

class ExplorePanel extends StatefulWidget {

  final ExploreType exploreType;
  final ExploreFilter? initialFilter;
  final Group? browseGroup;

  ExplorePanel({required this.exploreType, this.initialFilter, this.browseGroup });

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
  
  late EventsDisplayType _selectedEventsDisplayType;

  List<dynamic>? _eventCategories;
  List<Explore>? _displayExplores;
  List<String>?  _filterWorkTimeValues;
  List<String>?  _filterPaymentTypeValues;
  List<String>?  _filterEventTimeValues;
  
  Map<ExploreType, List<ExploreFilter>>? _itemToFilterMap;
  bool _filterOptionsVisible = false;

  List<DiningSpecial>? _diningSpecials;

  ScrollController _scrollController = ScrollController();

  Future<List<Explore>?>? _loadingTask;
  bool? _loadingProgress;
  bool _eventsDisplayDropDownValuesVisible = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Storage.offsetDateKey,
      Storage.useDeviceLocalTimeZoneKey,
      Connectivity.notifyStatusChanged,
      Localization.notifyStringsUpdated,
      Auth2UserPrefs.notifyFavoritesChanged,
      MTD.notifyStopsChanged,
      Appointments.notifyUpcomingAppointmentsChanged,
      AppLivecycle.notifyStateChanged,
    ]);


    _selectedEventsDisplayType = EventsDisplayType.single;
    _initFilters();

    _loadingProgress = true;
    
    if (widget.exploreType == ExploreType.Events) {
      _loadEventCategories().then((List<dynamic>? result) {
        _eventCategories = result;
        _loadExplores();
      });
    } else {
      _loadExplores();
    }

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
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
          onRefresh: () => _loadExplores(progress: false, updateOnly: true),
          child: _buildContent(),
        ),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: uiuc.TabBar());
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

  void _initFilters() {
    _itemToFilterMap = {
      ExploreType.Events: <ExploreFilter>[
        ExploreFilter(type: ExploreFilterType.categories),
        ExploreFilter(type: ExploreFilterType.event_time, selectedIndexes: {2})
      ],
      ExploreType.Dining: <ExploreFilter>[
        ExploreFilter(type: ExploreFilterType.work_time),
        ExploreFilter(type: ExploreFilterType.payment_type)
      ],
    };

    if (widget.initialFilter != null) {
      _itemToFilterMap?.forEach((ExploreType item, List<ExploreFilter> filters) {
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
        _loadExplores(updateOnly: true);
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

  Future<void> _loadExplores({bool? progress, bool updateOnly = false}) async {
    Future<List<Explore>?>? task;
    if (Connectivity().isNotOffline) {
      List<ExploreFilter>? selectedFilterList = (_itemToFilterMap != null) ? _itemToFilterMap![widget.exploreType] : null;
      switch (widget.exploreType) {
        case ExploreType.Events: task = _loadEvents(selectedFilterList); break;
        case ExploreType.Dining: task = _loadDining(selectedFilterList); break;
        default: break;
      }
    }

    if (task != null) {
      _refresh(() {
        _loadingTask = task;
        _loadingProgress = progress ?? !updateOnly;
      });
      
      List<Explore>? explores = await task;

      if (_loadingTask == task) {
        if ((updateOnly == false) || ((explores != null) && !DeepCollectionEquality().equals(explores, _displayExplores))) {
          _applyExplores(explores, updateOnly: updateOnly);
        }
        else {
          _refresh(() {
            _loadingTask = null;
            _loadingProgress = null;
          });
        }
      }
      else {
        // Do not do anything, _loadingTask will finish the loading.
      }
    }
    else if (updateOnly == false) {
      _applyExplores(null, updateOnly: updateOnly);
    }
  }


  void _applyExplores(List<Explore>? explores, { bool updateOnly = false}) {
    debugPrint('ExplorePanel._applyExplores(explores:${explores?.length} updateOnly: $updateOnly)');
    _refresh(() {
      _loadingTask = null;
      _loadingProgress = null;
      _displayExplores = explores;
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

    _diningSpecials = await Dinings().loadDiningSpecials();
    return Dinings().loadBackendDinings(onlyOpened, paymentType, null);
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
  /// Load athletics games if "All Categories" or "Big 10 Athletics" categories are selected
  ///
  bool _shouldLoadGames(Set<String?>? selectedCategories) {
    return CollectionUtils.isEmpty(selectedCategories) || selectedCategories!.contains('Big 10 Athletics');
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
    explores.sort();
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
      case ExploreFilterType.student_course_terms:
        return Localization().getStringEx('panel.explore.filter.terms.hint', '');
      default:
        return null;
    }
  }

  // Build UI

  PreferredSizeWidget get headerBarWidget {
    return HeaderBar(
      title: _headerBarListTitle(widget.exploreType),
      sortKey: _ExploreSortKey.headerBar,
      actions: (widget.exploreType == ExploreType.Events) ? <Widget>[_buildSearchHeaderButton()] : null,
    );
  }

  Widget _buildSearchHeaderButton() {
    return Semantics(label: Localization().getStringEx('headerbar.search.title', 'Search'), hint: Localization().getStringEx('headerbar.search.hint', ''), button: true, excludeSemantics: true, child:
      InkWell(onTap: _onTapSearch, child:
        Padding(padding: EdgeInsets.all(16), child:
          Styles().images?.getImage('search', excludeFromSemantics: true),
        )
      )
    );
  }

  void _onTapSearch() {
    Analytics().logSelect(target: "Search");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreSearchPanel(browseGroup: widget.browseGroup,)));
  }

  Widget _buildContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Expanded(child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Visibility(visible: (widget.exploreType == ExploreType.Events), child:
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
                    _buildListView(),
                  ),
                ),
              ]),
              _buildEventsDisplayTypesDropDownContainer(),
              _buildFilterValuesContainer()
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildEventsDisplayTypesDropDownButton() {
    return RibbonButton(
      textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat.secondary"),
      backgroundColor: Styles().colors!.white,
      borderRadius: BorderRadius.all(Radius.circular(5)),
      border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
      rightIconKey: (_eventsDisplayDropDownValuesVisible ? 'chevron-up' : 'chevron-down'),
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
        rightIconKey: null,
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

    return  Stack(children: [
      Container(color: Styles().colors!.background, child: exploresContent),
      _buildDimmedContainer(),
    ]);
  }

  Widget _buildExploreEntry(BuildContext context, int index){
    if(_hasDiningSpecials) {
      if (index == 0) {
        return HorizontalDiningSpecials(specials: _diningSpecials,);
      }
    }

    int realIndex = _hasDiningSpecials ? index -1 : index;
    Explore? explore = _displayExplores![realIndex];

    List<ExploreFilter>? selectedFilterList = (_itemToFilterMap != null) ? _itemToFilterMap![widget.exploreType] : null;
    Set<String>? tags  = _getSelectedEventTags(selectedFilterList);

    ExploreCard exploreView = ExploreCard(
        explore: explore,
        onTap: () => _onExploreTap(explore),
        hideInterests: tags == null,
        showTopBorder: true,
        source: widget.exploreType.toString());
    return Padding(
        padding: EdgeInsets.only(top: 16),
        child: exploreView);
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
    switch (widget.exploreType) {
      case ExploreType.Events: message = Localization().getStringEx('panel.explore.state.online.empty.events', 'No upcoming events.'); break;
      case ExploreType.Dining: message = Localization().getStringEx('panel.explore.state.online.empty.dining', 'No dining locations are currently open.'); break;
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
    switch (widget.exploreType) {
      case ExploreType.Events:              message = Localization().getStringEx('panel.explore.state.offline.empty.events', 'No upcoming events available while offline..'); break;
      case ExploreType.Dining:              message = Localization().getStringEx('panel.explore.state.offline.empty.dining', 'No dining locations available while offline.'); break;
      default:                              message =  ''; break;
    }
    return SingleChildScrollView(child:
      Center(child:
        Column(children: <Widget>[
          Container(height: MediaQuery.of(context).size.height / 5),
          Text(Localization().getStringEx("common.message.offline", "You appear to be offline"), style: Styles().textStyles?.getTextStyle("widget.message.regular")),
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

  Widget _buildFilterValuesContainer() {
    List<ExploreFilter>? itemFilters = (_itemToFilterMap != null) ? _itemToFilterMap![widget.exploreType] : null;
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
    List<ExploreFilter>? visibleFilters = (_itemToFilterMap != null) ? _itemToFilterMap![widget.exploreType] : null;
    if (visibleFilters == null ||
        visibleFilters.isEmpty ||
        _eventCategories == null) {
      filterTypeWidgets.add(Container());
      return filterTypeWidgets;
    }

    for (int i = 0; i < visibleFilters.length; i++) {
      ExploreFilter selectedFilter = visibleFilters[i];
      // Do not show categories filter if selected category is athletics "Big 10 Athletics" (e.g only one selected index with value 2)
      if ((selectedFilter.type == ExploreFilterType.categories) &&
          (widget.initialFilter?.type == ExploreFilterType.categories) &&
          (widget.initialFilter?.selectedIndexes.contains(2) ?? false)) {
        continue;
      }
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
          context, CupertinoPageRoute(builder: (context) => CompositeEventsDetailPanel(parentEvent: event, browseGroup: widget.browseGroup,)));
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
          ExploreDetailPanel(explore: explore, browseGroup: widget.browseGroup,)
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
    List<ExploreFilter>? itemFilters = (_itemToFilterMap != null) ? _itemToFilterMap![widget.exploreType] : null;
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

    _loadExplores();
  }

  static String? _headerBarListTitle(ExploreType? exploreItem) {
    switch (exploreItem) {
      case ExploreType.Events:              return Localization().getStringEx('panel.explore.header.events.title', 'Events');
      case ExploreType.Dining:              return Localization().getStringEx('panel.explore.header.dining.title', 'Residence Hall Dining');
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
        ? _itemToFilterMap![widget.exploreType] : null;
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

  // NotificationsListener
  
  @override
  void onNotification(String name, dynamic param) {
    if (name == Connectivity.notifyStatusChanged) {
      if ((Connectivity().isNotOffline) && mounted) {
        _updateEventCategories();
      }
    }
    else if (name == Localization.notifyStringsUpdated) {
      _refresh(() { });
    }
    else if (name == Storage.offsetDateKey) {
      if (mounted) {
        _loadExplores(updateOnly: true);
      }
    }
    else if (name == Storage.useDeviceLocalTimeZoneKey) {
      if (mounted) {
        _loadExplores(updateOnly: true);
      }
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _onFavoritesChanged();
    }
  }

  void _onFavoritesChanged() {
    _refresh(() {});
  }
}

/////////////////////////
// ExploreOptionalMessagePopup

class ExploreOptionalMessagePopup extends StatefulWidget {
  final String message;
  final String? showPopupStorageKey;
  ExploreOptionalMessagePopup({Key? key, required this.message, this.showPopupStorageKey}) : super(key: key);

  @override
  State<ExploreOptionalMessagePopup> createState() => _MTDInstructionsPopupState();
}

class _MTDInstructionsPopupState extends State<ExploreOptionalMessagePopup> {
  bool? showInstructionsPopup;
  
  @override
  void initState() {
    showInstructionsPopup = (widget.showPopupStorageKey != null) ? Storage().getBoolWithName(widget.showPopupStorageKey!) : null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String dontShow = Localization().getStringEx("panel.explore.instructions.mtd.dont_show.msg", "Don't show me this again.");

    return AlertDialog(contentPadding: EdgeInsets.zero, content:
      Container(decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: BorderRadius.circular(10.0)), child:
        Stack(alignment: Alignment.center, children: [
          Padding(padding: EdgeInsets.only(top: 36, bottom: 9), child:
            Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(padding: EdgeInsets.symmetric(horizontal: 32), child:
                Column(children: [
                  Styles().images?.getImage('university-logo', excludeFromSemantics: true) ?? Container(),
                  Padding(padding: EdgeInsets.only(top: 18), child:
                    Text(widget.message, textAlign: TextAlign.left, style: Styles().textStyles?.getTextStyle("widget.detail.small"))
                  )
                ]),
              ),

              Visibility(visible: (widget.showPopupStorageKey != null), child:
                Padding(padding: EdgeInsets.only(left: 16, right: 32), child:
                  Semantics(
                      label: dontShow,
                      value: showInstructionsPopup == false ?   Localization().getStringEx("toggle_button.status.checked", "checked",) : Localization().getStringEx("toggle_button.status.unchecked", "unchecked"),
                      button: true,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      InkWell(
                        onTap: (){
                          AppSemantics.announceCheckBoxStateChange(context,  /*reversed value*/!(showInstructionsPopup == false), dontShow);
                          _onDoNotShow();
                          },
                        child: Padding(padding: EdgeInsets.all(16), child:
                          Styles().images?.getImage((showInstructionsPopup == false) ? "check-circle-filled" : "check-circle-outline-gray"),
                        ),
                      ),
                      Expanded(child:
                        Text(dontShow, style: Styles().textStyles?.getTextStyle("widget.detail.small"), textAlign: TextAlign.left,semanticsLabel: "",)
                      ),
                  ])),
                ),
              ),
            ])
          ),
          Positioned.fill(child:
            Align(alignment: Alignment.topRight, child:
              Semantics(  button: true, label: "close",
              child: InkWell(onTap: () {
                Analytics().logSelect(target: 'Close MTD instructions popup');
                Navigator.of(context).pop();
                }, child:
                Padding(padding: EdgeInsets.all(16), child:
                  Styles().images?.getImage('close', excludeFromSemantics: true)
                )
              ))
            )
          ),
        ])
     )
    );
  }

  void _onDoNotShow() {
    setState(() {
      if (widget.showPopupStorageKey != null) {
        Storage().setBoolWithName(widget.showPopupStorageKey!, showInstructionsPopup = (showInstructionsPopup == false));
      }
    });  
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
// ExploreType


ExploreType? exploreItemFromString(String? value) {
  if (value == 'events') {
    return ExploreType.Events;
  }
  else if (value == 'dining') {
    return ExploreType.Dining;
  }
  else {
    return null;
  }
}

String? exploreItemToString(ExploreType? value) {
  switch(value) {
    case ExploreType.Events:              return 'events';
    case ExploreType.Dining:              return 'dining';
    default: return null;
  }
}

