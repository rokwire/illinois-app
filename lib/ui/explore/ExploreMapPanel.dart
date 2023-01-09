
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/widgets/Filters.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ExploreMapPanel extends StatefulWidget {
  final ExploreItem? initialContent;

  ExploreMapPanel({this.initialContent});
  
  @override
  State<StatefulWidget> createState() => _ExploreMapPanelState();
}

class _ExploreMapPanelState extends State<ExploreMapPanel> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin<ExploreMapPanel> {

  static const double filterLayoutSortKey = 1.0;
  static const CameraPosition defaultCameraPosition = CameraPosition(target: LatLng(40.102116, -88.227129), zoom: 17);

  List<ExploreItem> _exploreItems = [];
  ExploreItem? _selectedExploreItem;
  EventsDisplayType? _selectedEventsDisplayType;

  List<String>? _eventCategories;
  List<StudentCourseTerm>? _studentCourseTerms;
  
  List<String>? _filterWorkTimeValues;
  List<String>? _filterPaymentTypeValues;
  List<String>? _filterEventTimeValues;
  
  Map<ExploreItem, List<ExploreFilter>>? _itemToFilterMap;
  
  bool _itemsDropDownValuesVisible = false;
  bool _eventsDisplayDropDownValuesVisible = false;
  bool _filtersDropdownVisible = false;
  
  GoogleMapController? _mapController;
  LocationServicesStatus? _locationServicesStatus;

  @override
  void initState() {
    _exploreItems = _buildExploreItems();
    _selectedExploreItem = widget.initialContent ?? _lastExploreItem ?? ExploreItem.Events;
    _selectedEventsDisplayType = EventsDisplayType.single;
    
    _initFilters();
    _initLocationServicesStatus();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx("panel.maps.header.title", "Map")),
      body: RefreshIndicator(onRefresh: _onRefresh, child: _buildContent(),),
      backgroundColor: Styles().colors?.background,
    );
  }

  Widget _buildContent() {
    return Column(children: <Widget>[
      Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 0), child:
        _buildExploreItemsDropDownButton(),
      ),
      Expanded(child:
        Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Visibility(visible: (_selectedExploreItem == ExploreItem.Events), child:
              Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 0), child:
                _buildEventsDisplayTypesDropDownButton(),
              ),
            ),
            Expanded(child:
              Stack(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: EdgeInsets.only(left: 12, right: 12, bottom: 12), child:
                    Wrap(children: _buildFilters()),
                  ),
                  Expanded(child:
                    Container(color: Styles().colors!.background, child:
                      _buildMapView(),
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
      )
    ]);
  }

  // Map Widget

  Widget _buildMapView() {
    return GoogleMap(
      initialCameraPosition: defaultCameraPosition,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      compassEnabled: _userLocationEnabled,
      mapToolbarEnabled: Storage().debugMapShowLevels ?? false,
    );
  }

  // Dropdown Widgets

  Widget _buildExploreItemsDropDownButton() {
    return RibbonButton(
      textColor: Styles().colors!.fillColorSecondary,
      backgroundColor: Styles().colors!.white,
      borderRadius: BorderRadius.all(Radius.circular(5)),
      border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
      rightIconKey: (_itemsDropDownValuesVisible ? 'chevron-up' : 'chevron-down'),
      label: _exploreItemName(_selectedExploreItem),
      hint: _exploreItemHint(_selectedExploreItem),
      onTap: _onExploreItemsDropdown
    );
  }

  void _onExploreItemsDropdown() {
    Analytics().logSelect(target: 'Explore Dropdown');
    if (mounted) {
      setState(() {
        _clearActiveFilter();
        _itemsDropDownValuesVisible = !_itemsDropDownValuesVisible;
      });
    }
  }

  Widget _buildEventsDisplayTypesDropDownButton() {
    return RibbonButton(
      textColor: Styles().colors!.fillColorSecondary,
      backgroundColor: Styles().colors!.white,
      borderRadius: BorderRadius.all(Radius.circular(5)),
      border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
      rightIconKey: (_eventsDisplayDropDownValuesVisible ? 'chevron-up' : 'chevron-down'),
      label: _eventsDisplayTypeName(_selectedEventsDisplayType),
      onTap: _onEventsDisplayTypesDropDown
    );
  }

  void _onEventsDisplayTypesDropDown() {
    Analytics().logSelect(target: 'Events Type Dropdown');
    if (mounted) {
      setState(() {
        _clearActiveFilter();
        _eventsDisplayDropDownValuesVisible = !_eventsDisplayDropDownValuesVisible;
      });
    }
  }

  Widget _buildEventsDisplayTypesDropDownContainer() {
    return Visibility(visible: _eventsDisplayDropDownValuesVisible, child:
      Positioned.fill(child:
        Stack(children: <Widget>[
          _buildEventsDisplayTypesDropDownDismissLayer(),
          _buildEventsDisplayTypesDropDownWidget()
        ]),
      ),
    );
  }

  Widget _buildEventsDisplayTypesDropDownDismissLayer() {
    return Positioned.fill(child:
      BlockSemantics(child:
        GestureDetector(onTap: _onDismissEventsDisplayTypesDropDown, child:
          Container(color: Styles().colors!.blackTransparent06)
        )
      )
    );
  }

  void _onDismissEventsDisplayTypesDropDown() {
    Analytics().logSelect(target: 'Events Type Dismiss');
    if (mounted) {
      setState(() {
        _eventsDisplayDropDownValuesVisible = false;
      });
    }
  }

  Widget _buildEventsDisplayTypesDropDownWidget() {
    List<Widget> displayTypesWidgetList = <Widget>[
      Container(color: Styles().colors!.fillColorSecondary, height: 2)
    ];
    for (EventsDisplayType displayType in EventsDisplayType.values) {
      if ((_selectedEventsDisplayType != displayType)) {
        displayTypesWidgetList.add(_buildEventsDisplayTypeDropDownItem(displayType));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: displayTypesWidgetList)
      )
    );
  }

  Widget _buildEventsDisplayTypeDropDownItem(EventsDisplayType displayType) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconKey: null,
        label: _eventsDisplayTypeName(displayType),
        onTap: () => _onEventsDisplayType(displayType));
  }

  void _onEventsDisplayType(EventsDisplayType displayType) {
    Analytics().logSelect(target: _eventsDisplayTypeName(displayType));

    if (mounted) {
      EventsDisplayType? lastDisplayType = _selectedEventsDisplayType;
      setState(() {
        _clearActiveFilter();
        _selectedEventsDisplayType = displayType;
        _eventsDisplayDropDownValuesVisible = !_eventsDisplayDropDownValuesVisible;
      });
      if (lastDisplayType != _selectedEventsDisplayType) {
        //TBD: _loadExplores();
      }
    }
  }

  Widget _buildExploreItemsDropDownContainer() {
    return Visibility(visible: _itemsDropDownValuesVisible, child:
      Positioned.fill(child:
        Stack(children: <Widget>[
          _buildExploreDropDownDismissLayer(),
          _buildExploreItemsDropDownWidget()
        ])
      )
    );
  }

  Widget _buildExploreDropDownDismissLayer() {
    return Positioned.fill(child:
      BlockSemantics(child:
        GestureDetector(onTap: _onDismissExploreDropDown, child:
          Container(color: Styles().colors!.blackTransparent06)
        )
      )
    );
  }

  void _onDismissExploreDropDown() {
    Analytics().logSelect(target: "Explore Dropdown Dismiss");
    if (mounted) {
      setState(() {
        _itemsDropDownValuesVisible = false;
      });
    }
  }

  Widget _buildExploreItemsDropDownWidget() {
    List<Widget> itemList = <Widget>[
      Container(color: Styles().colors!.fillColorSecondary, height: 2),
    ];
    for (ExploreItem exploreItem in _exploreItems) {
      if ((_selectedExploreItem != exploreItem)) {
        itemList.add(_buildExploreDropDownItem(exploreItem));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: itemList)
      )
    );
  }

  Widget _buildExploreDropDownItem(ExploreItem exploreItem) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconKey: null,
        label: _exploreItemName(exploreItem),
        onTap: () => _onTapExploreItem(exploreItem)
      );
  }

  void _onTapExploreItem(ExploreItem item) {
    Analytics().logSelect(target: _exploreItemName(item));
    if (mounted) {
      ExploreItem? lastExploreItem = _selectedExploreItem;
      Storage().selectedMapExploreItem = exploreItemToString(item);
      setState(() {
        _clearActiveFilter();
        _selectedExploreItem = item;
        _itemsDropDownValuesVisible = false;
      });
      if (lastExploreItem != item) {
        //TBD: _loadExplores();
      }

    }
  }

  // Filter Widgets

  List<Widget> _buildFilters() {
    List<Widget> filterTypeWidgets = [];
    List<ExploreFilter>? visibleFilters = (_itemToFilterMap != null) ? _itemToFilterMap![_selectedExploreItem] : null;
    if ((visibleFilters == null ) || visibleFilters.isEmpty || (_eventCategories == null)) {
      filterTypeWidgets.add(Container());
    }
    else {
      for (int i = 0; i < visibleFilters.length; i++) {
        ExploreFilter selectedFilter = visibleFilters[i];
        List<String> filterValues = _getFilterValues(selectedFilter.type)!;
        int filterValueIndex = selectedFilter.firstSelectedIndex;
        String? filterHeaderLabel = (0 <= filterValueIndex) && (filterValueIndex < filterValues.length) ? filterValues[filterValueIndex] : null;
        filterTypeWidgets.add(FilterSelector(
          title: filterHeaderLabel,
          hint: _getFilterHint(selectedFilter.type),
          active: selectedFilter.active,
          onTap: () => _onFilterType(filterHeaderLabel, selectedFilter),
        ));
      }
    }
    return filterTypeWidgets;
  }

  void _onFilterType(String? filterName, ExploreFilter selectedFilter) {
    Analytics().logSelect(target: filterName);
    if (mounted) {
      setState(() {
        _toggleActiveFilter(selectedFilter);
      });
    }
  }

  Widget _buildFilterValuesContainer() {
    ExploreFilter? selectedFilter = _selectedFilter;
    List<String>? filterValues = (selectedFilter != null) ? _getFilterValues(selectedFilter.type) : null;
    if ((selectedFilter != null) && (filterValues != null)) {
      List<String?>? filterSubLabels = (selectedFilter.type == ExploreFilterType.event_time) ? _buildFilterEventDateSubLabels() : null;
      return Semantics(sortKey: OrdinalSortKey(filterLayoutSortKey), child:
        Visibility(visible: _filtersDropdownVisible, child:
          Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 36, bottom: 40), child:
            Semantics(child:
              Container(decoration: BoxDecoration(color: Styles().colors!.fillColorSecondary, borderRadius: BorderRadius.circular(5.0),), child:
                Padding(padding: EdgeInsets.only(top: 2), child:
                  Container(color: Colors.white, child:
                    ListView.separated(
                      shrinkWrap: true,
                      separatorBuilder: (context, index) => Divider(height: 1, color: Styles().colors!.fillColorPrimaryTransparent03,),
                      itemCount: filterValues.length,
                      itemBuilder: (context, index) => FilterListItem(
                        title: filterValues[index],
                        description: CollectionUtils.isNotEmpty(filterSubLabels) ? filterSubLabels![index] : null,
                        selected: selectedFilter.selectedIndexes.contains(index),
                        onTap: () => _onFilterItem(selectedFilter, filterValues[index], index),
                      ),
                    ),
                  ),
                ),
              )
            )
          ),
        )
      );
    }
    return Container();
  }

  void _onFilterItem(ExploreFilter selectedFilter, String newValueText, int newValueIndex) {
    Analytics().logSelect(target: "FilterItem: $newValueText");
    
    // JP: Change category selection back to radio button only. Only one of the possibilities should be picked at a time. Sorry I asked for the change.
    Set<int> selectedIndexes = { newValueIndex };
    /*Apply custom logic for selecting event categories.
    Set<int> selectedIndexes = Set.of(selectedFilter.selectedIndexes); //Copy
    
    if (selectedFilter.type == ExploreFilterType.categories) {
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
    
    Set<int> lastSelectedIndexes = selectedFilter.selectedIndexes;
    selectedFilter.selectedIndexes = selectedIndexes;
    selectedFilter.active = _filtersDropdownVisible = false;

    if (selectedFilter.type == ExploreFilterType.student_course_terms) {
      StudentCourseTerm? term = ListUtils.entry(_studentCourseTerms, newValueIndex);
      if (term != null) {
        StudentCourses().selectedTermId = term.id;
      }
    }

    if (!DeepCollectionEquality().equals(lastSelectedIndexes, selectedIndexes)) {
      //TBD: _loadExplores();
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

  // Explore Items

  List<ExploreItem> _buildExploreItems() {
    List<ExploreItem> exploreItems = [];
    List<dynamic>? codes = FlexUI()['explore.map'];
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
        else if (code == 'student_courses') {
          exploreItems.add(ExploreItem.StudentCourse);
        }
        else if (code == 'appointments') {
          exploreItems.add(ExploreItem.Appointments);
        }
        else if (code == 'mtd_stops') {
          exploreItems.add(ExploreItem.MTDStops);
        }
        else if (code == 'mtd_destinations') {
          exploreItems.add(ExploreItem.MTDDestinations);
        }
        else if (code == 'state_farm_wayfinding') {
          exploreItems.add(ExploreItem.StateFarmWayfinding);
        }
      }
    }
    return exploreItems;
  }

  ExploreItem? get _lastExploreItem => exploreItemFromString(Storage().selectedMapExploreItemKey);

  static String? _exploreItemName(ExploreItem? exploreItem) {
    switch (exploreItem) {
      case ExploreItem.Events:              return Localization().getStringEx('panel.explore.button.events.title', 'Events');
      case ExploreItem.Dining:              return Localization().getStringEx('panel.explore.button.dining.title', 'Residence Hall Dining');
      case ExploreItem.Laundry:             return Localization().getStringEx('panel.explore.button.laundry.title', 'Laundry');
      case ExploreItem.Buildings:           return Localization().getStringEx('panel.explore.button.buildings.title', 'Campus Buildings');
      case ExploreItem.StudentCourse:       return Localization().getStringEx('panel.explore.button.student_course.title', 'My Courses');
      case ExploreItem.Appointments:        return Localization().getStringEx('panel.explore.button.appointments.title', 'MyMcKinley In-Person Appointments');
      case ExploreItem.MTDStops:            return Localization().getStringEx('panel.explore.button.mtd_stops.title', 'MTD Stops');
      case ExploreItem.MTDDestinations:     return Localization().getStringEx('panel.explore.button.mtd_destinations.title', 'MTD Destinations');
      case ExploreItem.StateFarmWayfinding: return Localization().getStringEx('panel.explore.button.state_farm.title', 'State Farm Wayfinding');
      default:                              return null;
    }
  }

  static String? _exploreItemHint(ExploreItem? exploreItem) {
    switch (exploreItem) {
      case ExploreItem.Events:              return Localization().getStringEx('panel.explore.button.events.hint', '');
      case ExploreItem.Dining:              return Localization().getStringEx('panel.explore.button.dining.hint', '');
      case ExploreItem.Laundry:             return Localization().getStringEx('panel.explore.button.laundry.hint', '');
      case ExploreItem.Buildings:           return Localization().getStringEx('panel.explore.button.buildings.hint', '');
      case ExploreItem.StudentCourse:       return Localization().getStringEx('panel.explore.button.student_course.hint', '');
      case ExploreItem.Appointments:        return Localization().getStringEx('panel.explore.button.appointments.hint', '');
      case ExploreItem.MTDStops:            return Localization().getStringEx('panel.explore.button.mtd_stops.hint', '');
      case ExploreItem.MTDDestinations:     return Localization().getStringEx('panel.explore.button.mtd_destinations.hint', '');
      case ExploreItem.StateFarmWayfinding: return Localization().getStringEx('panel.explore.button.state_farm.hint', '');
      default:                              return null;
    }
  }

  // Filters

  void _initFilters() {

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

    _studentCourseTerms = StudentCourses().terms;

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

    if (Connectivity().isNotOffline) {
      Events().loadEventCategories().then((List<dynamic>? categories) {
        if (mounted) {
          setState(() {
            _eventCategories = _buildEventCategories(categories);
          });
        }
      });
    }
  }

  void _clearActiveFilter() {
    List<ExploreFilter>? itemFilters = (_itemToFilterMap != null) ? _itemToFilterMap![_selectedExploreItem] : null;
    if (itemFilters != null && itemFilters.isNotEmpty) {
      for (ExploreFilter filter in itemFilters) {
        filter.active = false;
      }
    }
    _filtersDropdownVisible = false;
  }

  void _toggleActiveFilter(ExploreFilter selectedFilter) {
    _clearActiveFilter();
    selectedFilter.active = _filtersDropdownVisible = !selectedFilter.active;
  }

  ExploreFilter? get _selectedFilter {
    List<ExploreFilter>? itemFilters = (_itemToFilterMap != null) ? _itemToFilterMap![_selectedExploreItem] : null;
    if (itemFilters != null && itemFilters.isNotEmpty) {
      for (ExploreFilter filter in itemFilters) {
        if (filter.active) {
          return filter;
        }
      }
    }
    return null;
  }

  static String? _eventsDisplayTypeName(EventsDisplayType? type) {
    switch (type) {
      case EventsDisplayType.all:       return Localization().getStringEx('panel.explore.button.events.display_type.all.label', 'All Events');
      case EventsDisplayType.multiple:  return Localization().getStringEx('panel.explore.button.events.display_type.multiple.label', 'Multi-day events');
      case EventsDisplayType.single:    return Localization().getStringEx('panel.explore.button.events.display_type.single.label', 'Single day events');
      default:                      return null;
    }
  }

  List<String>? _getFilterValues(ExploreFilterType filterType) {
    switch (filterType) {
      case ExploreFilterType.categories:   return _filterEventCategoriesValues;
      case ExploreFilterType.work_time:    return _filterWorkTimeValues;
      case ExploreFilterType.payment_type: return _filterPaymentTypeValues;
      case ExploreFilterType.event_time:   return _filterEventTimeValues;
      case ExploreFilterType.event_tags:   return _filterTagsValues;
      case ExploreFilterType.student_course_terms: return _filterTermsValues;
      default: return null;
    }
  }

  List<String> get _filterEventCategoriesValues => <String>[
      Localization().getStringEx('panel.explore.filter.categories.all', 'All Categories'),
      Localization().getStringEx('panel.explore.filter.categories.my', 'My Categories'),
      ... _eventCategories ?? <String>[]
    ];

  List<String> get _filterTagsValues => <String>[
    Localization().getStringEx('panel.explore.filter.tags.all', 'All Tags'),
    Localization().getStringEx('panel.explore.filter.tags.my', 'My Tags'),
  ];

  List<String> get _filterTermsValues {
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

  String? _getFilterHint(ExploreFilterType filterType) {
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

  List<String>? _buildEventCategories(List<dynamic>? categories) {
    List<String>? eventCategories;
    if (categories != null) {
      eventCategories = <String>[];
      for (dynamic entry in categories) {
        Map<String, dynamic>? mapEntry = JsonUtils.mapValue(entry);
        String? category = (mapEntry != null) ? JsonUtils.stringValue(['category']) : null;
        if (category != null) {
          eventCategories.add(category); 
        }
      }
    }
    return eventCategories;
  }

  // Locaction Services

  bool get _userLocationEnabled {
    return FlexUI().isLocationServicesAvailable && (_locationServicesStatus == LocationServicesStatus.permissionAllowed);
  }

  void _initLocationServicesStatus() {
    if (FlexUI().isLocationServicesAvailable) {
      LocationServices().status.then((LocationServicesStatus? locationServicesStatus) {
        if (mounted) {
          setState(() {
            _locationServicesStatus = locationServicesStatus;
          });
        }
      });
    }
  }


  // Explore Content

  Future<void> _onRefresh() async {

  }


}

