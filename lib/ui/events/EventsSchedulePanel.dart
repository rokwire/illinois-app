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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Event.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreEventDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreListPanel.dart';
import 'package:illinois/ui/explore/ExploreDisplayTypeHeader.dart';
import 'package:illinois/ui/widgets/Filters.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/MapWidget.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:sprintf/sprintf.dart';

enum _EventTab { All, Saved }

enum _EventFilterType { categories, event_tags}

class EventsSchedulePanel extends StatefulWidget {

  final Event? superEvent;

  EventsSchedulePanel({ this.superEvent});

  @override
  EventsSchedulePanelState createState() => EventsSchedulePanelState();
}

class EventsSchedulePanelState extends State<EventsSchedulePanel>
    with SingleTickerProviderStateMixin implements NotificationsListener {
  List<Event>? _events;

  List<_EventTab> _eventTabs = [];
  _EventTab  _selectedTab = _EventTab.All;

  Map<String,Map<String?,List<Event>>>? _sortedEvents;
  List<dynamic>? _eventCategories;
  List<String>? _eventTags;
  //Search tags
  List<String>? _visibleTags;
  TextEditingController _textEditingController = TextEditingController();
  //

  List<Event>? _displayEvents;

  Position? _locationData;
  LocationServicesStatus? _locationServicesStatus;

  List<_EventFilter>? _tabFilters;
  _EventFilter? _initialSelectedFilter;
  bool _filterOptionsVisible = false;

  ScrollController _scrollController = ScrollController();

  //Maps
  static const double MapBarHeight = 114;

  bool? _mapAllowed;
  MapController? _nativeMapController;
  ListMapDisplayType _displayType = ListMapDisplayType.List;
  dynamic _selectedMapExplore;
  late AnimationController _mapExploreBarAnimationController;

  bool _showSavedContent = false; //All by default

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      Connectivity.notifyStatusChanged,
      LocationServices.notifyStatusChanged,
      Localization.notifyStringsUpdated,
      NativeCommunicator.notifyMapSelectExplore,
      NativeCommunicator.notifyMapClearExplore,
      Auth2UserPrefs.notifyPrivacyLevelChanged,
    ]);
    _initFilters();
    _initLocationService();
    _initEventTabs();
    _initEvents();
    _mapExploreBarAnimationController = AnimationController (duration: Duration(milliseconds: 200), lowerBound: -MapBarHeight, upperBound: 0, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    if (_displayType == ListMapDisplayType.Map) {
      Analytics().logMapHide();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.events_schedule.header.title', 'Event Schedule'),
      ),
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 1,
              child:
              ExploreDisplayTypeHeader(displayType: _displayType,
                searchVisible: false,
                onTapList: () => _selectDisplayType(ListMapDisplayType.List),
                onTapMap: () => _selectDisplayType(ListMapDisplayType.Map),),
            ),
            Container( color: Styles().colors!.white,
                   child : Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: _buildTabWidgets(),
                        )),
            ),

            Expanded(
              flex: 9,
              child: Stack(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container( color: Styles().colors!.white,
                        width: double.infinity,
                        child :
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Padding(
                              padding: EdgeInsets.only(
                                  left: 12, right: 12, bottom: 12),
                              child: Row(
                                children: _buildFilterWidgets(),
                              )),
                      )),
                      Expanded(
                          child: Container(
                            color: Styles().colors!.background,
                            child: Center(
                              child: Stack(
                                children: <Widget>[
                                  _buildMapView(context),
                                  _buildListView(),
                                ],
                              ),
                            ),
                          ))
                    ],
                  ),
                  _buildFilterValuesContainer()
                ],
              ),
            )
          ]),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  //ListView
  Widget _buildListView() {
    Widget exploresContent;
     List<Widget> listContent = _constructListContent();
     if ((_displayEvents?.length ?? 0) > 0) {
      exploresContent =
          ListView.separated(
        separatorBuilder: (context, index) => Divider(
          height: 8,
          color: Colors.transparent,
        ),
        itemCount: listContent.length,
        itemBuilder: (context, index) {
          return listContent[index];
        },
        controller: _scrollController,
      );
    }
    else {
      exploresContent = _buildEmpty();
    }

    return Visibility(visible: (_displayType == ListMapDisplayType.List), child:
      Stack(children: [
        Container(padding: EdgeInsets.symmetric(horizontal: 16), color: Styles().colors!.background, child: exploresContent),
        _buildDimmedContainer(),
      ])
    );
  }

  List<Widget> _constructListContent() {
    List<Widget> content = [];
    content.add(Container(height: 12));
    if (_sortedEvents != null && _sortedEvents!.isNotEmpty) {
      for (String? date in _sortedEvents!.keys) {
        content.add(_buildDateTitle(date!));
        Map? categoryEvents = _sortedEvents![date];
        if (categoryEvents != null && categoryEvents.isNotEmpty) {
          for (String? category in categoryEvents.keys) {
            if (StringUtils.isNotEmpty(category)) {
              content.add(_buildCategoryTitle(category!));
            }
            List<Event> events = categoryEvents[category];
            for (Event event in events) {
              content.add(_buildEventCart(event));
            }
            content.add(Container(height: 12,));
          }
        }
      }
    }
    
    return content;
  }

  Widget _buildDateTitle(String date){
    return Text(date,
      style: TextStyle(
        fontSize: 20,
        color: Styles().colors!.fillColorPrimary,
        fontFamily: Styles().fontFamilies!.extraBold
      ),
    );
  }

  Widget _buildCategoryTitle(String category){
    return Text(category,
        style: TextStyle(
            fontSize: 16,
            color: Styles().colors!.textBackground,
            fontFamily: Styles().fontFamilies!.extraBold
        ));
  }

  Widget _buildEventCart(Event event) {
    return EventScheduleCard(event: event, superEventTitle: widget.superEvent?.title,);
  }

  //Event utils
  String getEventDate(Event event) {
    return AppDateTimeUtils.getDisplayDay(dateTimeUtc: event.startDateGmt, allDay: event.allDay)!;
  }

  Widget _buildEmpty() {
    String message =  Localization().getStringEx('panel.events_schedule.empty.events', 'No events.');
    return Container(child: Align(alignment: Alignment.center,
      child: Text(message, textAlign: TextAlign.center,),
    ));
  }

  //display type
  void _selectDisplayType(ListMapDisplayType displayType) {
    Analytics().logSelect(target: displayType.toString());
    if (_displayType != displayType) {
      _refresh(() {
        _displayType = displayType;
        _mapAllowed = (_displayType == ListMapDisplayType.Map) || (_mapAllowed == true);
        _enableMap(_displayType == ListMapDisplayType.Map);
      });
    }
  }

  //Filters
  void _initFilters() {
    _tabFilters = <_EventFilter>[
      _EventFilter(type: _EventFilterType.categories),
      _EventFilter(type: _EventFilterType.event_tags)
    ];
  }

  Widget _buildFilterValuesContainer() {
    
    _EventFilter? selectedFilter;
    if (CollectionUtils.isNotEmpty(_tabFilters)) {
      for (_EventFilter filter in _tabFilters!) {
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
    return Visibility(
      visible: _filterOptionsVisible,
      child: Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 36, bottom: 40),
          child: Container(
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
                  itemCount: filterValues.length + 1, // 1 ForSearchField
                  itemBuilder: (context, index) {
                    var filterIndex = index - 1;// 1 for Search field
                    return index == 0 ? constructSearchField(selectedFilter!) :
                     FilterListItem(
                      title: filterValues[filterIndex],
                      selected: (selectedFilter?.selectedIndexes != null && selectedFilter!.selectedIndexes.contains(filterIndex)),
                      onTap: () {
                        Analytics().logSelect(target: "FilterItem: ${filterValues[filterIndex]}");
                        _onFilterValueClick(selectedFilter!, filterIndex);
                      },
                    );
                  },
                  controller: _scrollController,
                ),
              ),
            ),
          )),
    );
  }

  Widget constructSearchField(_EventFilter filter){
    return Visibility(visible: filter.type == _EventFilterType.event_tags,child:
    Container(
      padding: EdgeInsets.only(left: 16),
      color: Colors.white,
      height: 48,
      child: Row(
        children: <Widget>[
          Flexible(
              child:
              Semantics(
                label: Localization().getStringEx('panel.events_schedule.field.search.title', 'Search'),
                hint: Localization().getStringEx('panel.events_schedule.field.search.hint', ''),
                textField: true,
                excludeSemantics: true,
                child: TextField(
                  controller: _textEditingController,
                  onChanged: (text) => _onTextChanged(text),
                  onSubmitted: (_) => _onTapSearchTags(),
                  autofocus: true,
                  cursorColor: Styles().colors!.fillColorSecondary,
                  keyboardType: TextInputType.text,
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: Styles().fontFamilies!.regular,
                      color: Styles().colors!.textBackground),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              )
          ),
          Semantics(
            label: Localization().getStringEx('panel.events_schedule.button.search.title', 'Search'),
            hint: Localization().getStringEx('panel.events_schedule.title.button.search.hint', ''),
            button: true,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: GestureDetector(
                onTap: _onTapSearchTags,
                child: Image.asset(
                  'images/icon-search.png',
                  color: Styles().colors!.fillColorSecondary,
                  width: 25,
                  height: 25,
                ),
              ),
            ),
          ),
        ],
      ),
    )
    );
  }

  void _onTapSearchTags() {
    Analytics().logSelect(target: "Search");
    FocusScope.of(context).requestFocus(new FocusNode());
    String searchValue = _textEditingController.text;
    if (StringUtils.isEmpty(searchValue)) {
      return;
    }
    _refreshVisibleSearchTags();
    setState(() {
    });
  }

  void _onTextChanged(String text) {
    _refreshVisibleSearchTags();
    setState(() {
    });
  }

  void _onFilterTypeClicked(_EventFilter selectedFilter) {
    _refresh(() {
      if (_tabFilters != null) {
        for (_EventFilter filter in _tabFilters!) {
          if (filter != selectedFilter) {
            filter.active = false;
          }
        }
      }
      selectedFilter.active = _filterOptionsVisible = !selectedFilter.active;
    });
  }

  void _onFilterValueClick(_EventFilter selectedFilter, int newValueIndex) {
    //Apply custom logic for selecting event categories.
    Set<int> selectedIndexes = Set.of(selectedFilter.selectedIndexes); //Copy

    selectedIndexes = {newValueIndex};

    selectedFilter.selectedIndexes = selectedIndexes;
    selectedFilter.active = _filterOptionsVisible = false;
    _refreshEvents();
  }

  List<String>? _getFilterValuesByType(_EventFilterType filterType) {
    switch (filterType) {
      case _EventFilterType.categories:
        return _getFilterCategoriesValues();
      case _EventFilterType.event_tags:
        return _getFilterTagsValues();
      default:
        return null;
    }
  }

  String? _getFilterHintByType(_EventFilterType filterType) {
    switch (filterType) {
      case _EventFilterType.categories:
        return Localization().getStringEx('panel.events_schedule.filter.categories.hint', '');
      case _EventFilterType.event_tags:
        return Localization().getStringEx('panel.events_schedule.filter.tags.hint', '');
      default:
        return null;
    }
  }

  List<String>? _getFilterCategoriesValues() {
    if (CollectionUtils.isEmpty(_eventCategories)) {
      return null;
    }
    List<String> categoriesValues = [];
    categoriesValues.add(Localization().getStringEx('panel.events_schedule.filter.tracks.all', 'All Tracks'));
    for (var category in _eventCategories!) {
      categoriesValues.add(category);
    }
    return categoriesValues;
  }

  List<String>? _getFilterTagsValues() {
    List<String> tagsValues = [];
    tagsValues.add(Localization().getStringEx('panel.events_schedule.filter.tags.all', 'All Tags'));

    if (_visibleTags != null) {
      for (var tag in _visibleTags!) {
        tagsValues.add(tag);
      }
    }
    return tagsValues;
  }

  List<Widget> _buildFilterWidgets() {
    List<Widget> filterTypeWidgets = [];
    if (CollectionUtils.isEmpty(_tabFilters) || _eventCategories == null) {
      filterTypeWidgets.add(Container());
      return filterTypeWidgets;
    }

    for (int i = 0; i < _tabFilters!.length; i++) {
      _EventFilter selectedFilter = _tabFilters![i];
      if (_initialSelectedFilter != null &&
          _initialSelectedFilter!.type == selectedFilter.type) {
        selectedFilter = _EventFilter(
            type: _initialSelectedFilter!.type,
            selectedIndexes: _initialSelectedFilter!.selectedIndexes,
            active: _initialSelectedFilter!.active);
        _initialSelectedFilter = null;
      }
      List<String>? filterValues = _getFilterValuesByType(selectedFilter.type);
      if (CollectionUtils.isEmpty(filterValues)) {
        continue;
      }
      int filterValueIndex = selectedFilter.firstSelectedIndex;
      String? filterHeaderLabel = filterValues![filterValueIndex];
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

  Widget _buildDimmedContainer() {
    return Visibility(
        visible: _filterOptionsVisible,
        child: BlockSemantics(child:Container(color: Color(0x99000000))));
  }

  //Tabs
  _initEventTabs(){
    _eventTabs.add(_EventTab.All);
    _eventTabs.add(_EventTab.Saved);
  }

  List<Widget> _buildTabWidgets() {
    List<Widget> tabs =  [];
    _eventTabs.forEach((_EventTab tab) {
      tabs.add(Expanded(
          child: _EventTabView(
              text: eventTabName(tab),
              selected: _selectedTab == tab,
              left: _EventTab.values.first == tab,
              onTap: () {
                setState(() {
                  _selectedTab = tab;
                  _showSavedContent = _selectedTab == _EventTab.Saved;
                  _refreshEvents();

                });
              })));
     });
   return tabs;
  }

  void _refreshEvents(){
    _sortEvents();
    _refresh((){});
  }

  void _refresh(void fn()){
    if(mounted) {
      this.setState(fn);
    }
  }

  static String? eventTabName(_EventTab exploreTab) {
    switch (exploreTab) {
      case _EventTab.All:    return Localization().getStringEx('panel.events_schedule.button.all.title', 'All');
      case _EventTab.Saved:  return Localization().getStringEx('panel.events_schedule.tab.title.saved', 'Saved');
      default:                return null;
    }
  }

  static String? exploreTabHint(_EventTab exploreTab) {
    switch (exploreTab) {
      case _EventTab.All:    return Localization().getStringEx('panel.events_schedule.button.all.hint', '');
      case _EventTab.Saved:  return Localization().getStringEx('panel.events_schedule.tab.title.saved', 'Saved');
      default:                return null;
    }
  }

  ///Maps
  ///
  Widget _buildMapView(BuildContext context) {
    String? title, description;
    Color? exploreColor = Colors.white;
    if (_selectedMapExplore is Event) {
      title = _selectedMapExplore?.exploreTitle;
      description = _selectedMapExplore.exploreLocation?.description;
      exploreColor = _selectedMapExplore.uiColor;
    }
    else if  (_selectedMapExplore is List<Event>) {
      String? exploreName = ExploreExt.getExploresListDisplayTitle(_selectedMapExplore);
      title = sprintf(Localization().getStringEx('panel.events_schedule.map.popup.title.format', '%d %s'), [_selectedMapExplore?.length, exploreName]);
      description = _selectedMapExplore?.first?.exploreLocation?.description;
      exploreColor = _selectedMapExplore.first?.uiColor;
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
                                    label: Localization().getStringEx('panel.events_schedule.button.directions.title', 'Directions'),
                                    hint: Localization().getStringEx('panel.events_schedule.button.directions.hint', ''),
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
                              label: Localization().getStringEx('panel.events_schedule.button.details.title', 'Details'),
                              hint: Localization().getStringEx('panel.events_schedule.button.details.hint', ''),
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

  _selectMapExplore(dynamic explore) {
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

  _presentMapExploreDirections(BuildContext context) async {
    dynamic explore = _selectedMapExplore;
    _mapExploreBarAnimationController.reverse().then((_){
      _refresh(() { _selectedMapExplore = null;});
    });
    if (explore != null) {
      NativeCommunicator().launchExploreMapDirections(target: explore);
    }
  }

  _presentMapExploreDetail(BuildContext context) {
    dynamic explore = _selectedMapExplore;
    _mapExploreBarAnimationController.reverse().then((_){
      _refresh(() { _selectedMapExplore = null;});
    });

    if (explore is Explore) {
      Event? event = (explore is Event) ? explore : null;
      if (event?.isGameEvent ?? false) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(gameId: event!.speaker, sportName: event.registrationLabel,)));
      }
      else {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreDetailPanel(explore: explore, initialLocationData: _locationData,)));
      }
    }
    else if (explore is List<Explore>) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreListPanel(explores: explore)));
    }
  }

  _onNativeMapCreated(mapController) {
    _nativeMapController = mapController;
    _placeEventOnMap(_displayEvents);
    _enableMap(_displayType == ListMapDisplayType.Map);
    _enableMyLocationOnMap();
  }

  _placeEventOnMap(List<Event>? explores) {
    if (_nativeMapController != null) {
      _nativeMapController!.placePOIs(explores);
    }
  }

  _enableMap(bool enable) {
    if (_nativeMapController != null) {
      _nativeMapController!.enable(enable);
      Analytics().logMapDisplay(action: enable ? Analytics.LogMapDisplayShowActionName : Analytics.LogMapDisplayHideActionName);
    }
  }

  _enableMyLocationOnMap() {
    if (_nativeMapController != null) {
      _nativeMapController!.enableMyLocation(_userLocationEnabled());
    }
  }

  Explore? _exploreFromMapExplore(Explore? mapExplore) {
    String? mapExploreId = mapExplore?.exploreId;
    if ((_displayEvents != null) && (mapExploreId != null)) {
      for (Explore displayExplore in _displayEvents!) {
        if ((displayExplore.runtimeType.toString() == mapExplore.runtimeType.toString()) && (displayExplore.exploreId != null) && (displayExplore.exploreId == mapExploreId)) {
          return displayExplore;
        }
      }
    }
    return mapExplore; // null;
  }

  List<Explore> _exploresFromMapExplores(List<Explore>? mapExplores) {
    List<Explore> explores = [];
    if (mapExplores != null) {
      for (Explore mapExplore in mapExplores) {
        explores.add(_exploreFromMapExplore(mapExplore) ?? mapExplore);
      }
    }
    return explores;
  }

  bool _userLocationEnabled() {
    return Auth2().privacyMatch(2) && (_locationServicesStatus == LocationServicesStatus.permissionAllowed);
  }

  //EventsLoading
  void _initEvents() {
    _events = widget.superEvent?.subEvents;
    _displayEvents = widget.superEvent?.subEvents;
    _sortEvents();
    _initEventsCategories();
    _initEventTags();
    _refreshVisibleSearchTags();
    _refresh(() {});
  }

  //Utils Sorting
  void _sortEvents() {
    if (CollectionUtils.isEmpty(_events)) {
      return;
    }
    _sortedEvents = Map();
    for(Event event in _events!){
        if(!_isEventMatchFilters(event)){
          continue;
        }
        //Sort by date
        String eventDate = getEventDate(event);
        Map<String?,List<Event>>? eventsForDate;
        if(_sortedEvents!.containsKey(eventDate)) {
          eventsForDate = _sortedEvents![eventDate];
        }
        else {
          eventsForDate = Map();
          _sortedEvents![eventDate] = eventsForDate;
        }
        //Sort By Category
        String? category = event.track;
        List<Event>? eventsForCategory;
        if(eventsForDate!.containsKey(category)) {
          eventsForCategory = eventsForDate[category];
        }
        else {
          eventsForCategory = [];
          eventsForDate[category] = eventsForCategory;
        }
        eventsForCategory!.add(event);
    }
  }

  _isEventMatchFilters(Event event){
      if(_showSavedContent){
        return Auth2().isFavorite(event);
      }

      //Categories
      Set<dynamic>? filteredCategories = getSelectedCategories(_tabFilters);
      if(filteredCategories!=null && filteredCategories.isNotEmpty){
        if(!filteredCategories.contains(event.track)){
          return false;
        }
      }

      //Tags
      Set<dynamic>? filteredTags = getSelectedTags(_tabFilters);
      if(filteredTags!=null && filteredTags.isNotEmpty){
        return event.tags?.any((String tag) => filteredTags.contains(tag)) ?? false;
      }

      return true; //match everything
  }

  void _initEventsCategories() {
    _eventCategories = [];
    if (CollectionUtils.isNotEmpty(_events)) {
      for (Event event in _events!) {
        String? track = event.track;
        if (StringUtils.isNotEmpty(track) && !_eventCategories!.contains(track))
          _eventCategories!.add(track);
      }
    }
  }

  _initEventTags(){
    _eventTags = [];
    if(_events!=null && _events!.isNotEmpty){
      for (Event event in _events!){
        List<String>? eventTags = event.tags;
        if(eventTags!=null && eventTags.isNotEmpty) {
          for(String eventTag in eventTags) {
            if(!_eventTags!.contains(eventTag))
              _eventTags!.add(eventTag);
          }
        }
      }
    }
  }

  _refreshVisibleSearchTags(){
    _visibleTags = _eventTags;
    String searchPattern = _textEditingController.text;
    if( StringUtils.isNotEmpty(searchPattern)){
      _visibleTags = _eventTags!.where((String tag){
          return tag.startsWith(searchPattern);
      }).toList();
    }
  }

  Set<dynamic>? getSelectedCategories(List<_EventFilter>? selectedFilterList) {
    _EventFilter? categoriesFilter = selectedFilterList != null && selectedFilterList.length > 0 ? selectedFilterList[0] : null; //Index 0 are Categories
    if (categoriesFilter != null) {
      Set<int> selextedIndexes = categoriesFilter.selectedIndexes;
      if (selextedIndexes.isEmpty ||
          selextedIndexes.contains(0)) {
        return null; //All Categories
      } else {
        return _eventCategories!.where((dynamic category){
          return selextedIndexes.contains(_eventCategories!.indexOf(category.toString()) + 1); //1 for the All categories button
        }).toSet();
      }
    }

    return null;
  }

  Set<dynamic>? getSelectedTags(List<_EventFilter>? selectedFilterList) {
    _EventFilter? categoriesFilter = selectedFilterList != null && selectedFilterList.length > 1 ? selectedFilterList[1] : null; //Index 1 are Tags
    if (categoriesFilter != null) {
      Set<int> selextedIndexes = categoriesFilter.selectedIndexes;
      if (selextedIndexes.isEmpty ||
          selextedIndexes.contains(0)) {
        return null; //All Categories
      } else {
        return _eventTags!.where((dynamic tag){
          return selextedIndexes.contains(_eventTags!.indexOf(tag) + 1);//1 for the All tags button
        }).toSet();
      }
    }

    return null;
  }

  //LocationServices
  _initLocationService(){
    if (Auth2().privacyMatch(2)) {
      LocationServices().status.then((LocationServicesStatus? locationServicesStatus) {
        _locationServicesStatus = locationServicesStatus;

        if (_locationServicesStatus == LocationServicesStatus.permissionNotDetermined) {
          LocationServices().requestPermission().then((LocationServicesStatus? locationServicesStatus) {
            _locationServicesStatus = locationServicesStatus;
            _refresh((){});
          });
        }
        else {
          _refresh((){});
        }
      });
    }
    else {
      _refresh((){});
    }
  }

  //Listeners
  @override
  void onNotification(String name, param) {
    if (name == LocationServices.notifyStatusChanged) {
      _onLocationServicesStatusChanged(param);
    } else if(name == Auth2UserPrefs.notifyFavoritesChanged) {
      _refreshEvents();
    }
    else if (name == Connectivity.notifyStatusChanged) {
      if (Connectivity().isNotOffline) {
        _refreshEvents();
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
    else if (name == Auth2UserPrefs.notifyPrivacyLevelChanged) {
      _onPrivacyLevelChanged();
    }
  }

  _onPrivacyLevelChanged(){
    if (Auth2().privacyMatch(2)) {
      LocationServices().status.then((LocationServicesStatus? locationServicesStatus) {
        _locationServicesStatus = locationServicesStatus;
        _refresh((){});
      });
    }
    else {
      _refresh((){});
    }
  }

  void _onLocationServicesStatusChanged(LocationServicesStatus? status) {
    if (Auth2().privacyMatch(2)) {
      _locationServicesStatus = status;
      _refresh((){});
    }
  }

  void _onNativeMapSelectExplore(int? mapID, dynamic exploreJson) {
    if (_nativeMapController!.mapId == mapID) {
      dynamic explore;
      if (exploreJson is Map) {
        explore = _exploreFromMapExplore(Explore.fromJson(exploreJson as Map<String, dynamic>?));
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

class _EventFilter {
  _EventFilterType type;
  Set<int> selectedIndexes;
  bool active;

  _EventFilter({required this.type, this.selectedIndexes = const {0}, this.active = false});

  int get firstSelectedIndex {
    if (selectedIndexes.isEmpty) {
      return -1;
    }
    return selectedIndexes.first;
  }
}

class EventScheduleCard extends StatefulWidget {
  final Event? event;
  final bool showHeader;
  final Color? headerColor;
  final String? superEventTitle;

  EventScheduleCard({this.event, this.showHeader = false, this.headerColor, this.superEventTitle});

  @override
  _EventScheduleCardState createState() => _EventScheduleCardState();
}

class _EventScheduleCardState extends State<EventScheduleCard> implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, Auth2UserPrefs.notifyFavoritesChanged);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.event == null) {
      return Container();
    }
    bool favorite = Auth2().isFavorite(widget.event);
    double headerHeight = 7;

    return GestureDetector(onTap: _onTapSubEvent, child: Semantics(
        button: true,
        label: widget.event!.title,
        child: Column(
          children: <Widget>[
            Visibility(
              visible: widget.showHeader,
              child: Container(
                height: headerHeight,
                color: widget.headerColor ?? Styles().colors!.fillColorSecondary,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0), borderRadius: BorderRadius.all(Radius.circular(5))),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Flex(
                    direction: Axis.vertical,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          Container(
                              child: Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Image.asset("images/icon-calendar.png"))),
                          Expanded(
                            child: Text(
                              widget.event!.title!,
                              style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20, fontFamily: Styles().fontFamilies!.extraBold),
                            ),
                          ),
                          Visibility(
                            visible: Auth2().canFavorite,
                            child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  Analytics().logSelect(target: "Favorite: ${widget.event?.title}");
                                  Auth2().prefs?.toggleFavorite(widget.event);
                                },
                                child: Semantics(
                                    label: favorite
                                        ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites')
                                        : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                                    hint: favorite
                                        ? Localization().getStringEx('widget.card.button.favorite.off.hint', '')
                                        : Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
                                    button: true,
                                    excludeSemantics: true,
                                    child: Container(
                                        child: Padding(
                                            padding: EdgeInsets.only(left: 24),
                                            child: Image.asset(favorite ? 'images/icon-star-blue.png' : 'images/icon-star-gray-frame-thin.png'))))),
                          )
                        ],
                      )
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 4, left: 28),
                    child: Text(widget.event?.displaySuperTime ?? '', style: TextStyle(color: Styles().colors!.textBackground, fontSize: 14, fontFamily: Styles().fontFamilies!.medium)),
                  )
                ]),
              ),
            )
          ],
        )),);
  }

  void _onTapSubEvent() {
    Navigator.push(context, CupertinoPageRoute(builder: (_) => ExploreEventDetailPanel(event: widget.event, superEventTitle: widget.superEventTitle,)));
  }
}

class _EventTabView extends StatelessWidget{
  final String? text;
  final bool? left;
  final bool? selected;
  final GestureTapCallback? onTap;

  _EventTabView({Key? key, this.text, this.left, this.selected, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
          label: text,
          button: true,
          excludeSemantics: true,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: selected! ? Colors.white : Color(0xffededed),
              border: Border.all(color: Color(0xffc1c1c1), width: 1, style: BorderStyle.solid),
              borderRadius: left! ? BorderRadius.horizontal(left: Radius.circular(100.0)) : BorderRadius.horizontal(right: Radius.circular(100.0)),
            ),
            child: Center(
                child: Text(text!,
                    style: TextStyle(fontFamily: selected! ? Styles().fontFamilies!.extraBold : Styles().fontFamilies!.medium, fontSize: 16, color: Styles().colors!.fillColorPrimary))),
          )),
    );
  }
}