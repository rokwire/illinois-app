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
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:illinois/ext/Event.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/explore/ExploreEventDetailPanel.dart';
import 'package:illinois/ui/widgets/Filters.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

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

  List<_EventFilter>? _tabFilters;
  _EventFilter? _initialSelectedFilter;
  bool _filterOptionsVisible = false;

  ScrollController _scrollController = ScrollController();

  bool _showSavedContent = false; //All by default

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      Connectivity.notifyStatusChanged,
      Localization.notifyStringsUpdated,
    ]);
    _initFilters();
    _initEventTabs();
    _initEvents();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.events_schedule.header.title', 'Event Schedule'),),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Container(color: Styles().colors!.white, child :
          Padding(padding: EdgeInsets.all(12), child:
            Row(children: _buildTabWidgets(),)
          ),
        ),

            Expanded(
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
                              child: _buildListView(),
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

    return Stack(children: [
      Container(padding: EdgeInsets.symmetric(horizontal: 16), color: Styles().colors!.background, child: exploresContent),
      _buildDimmedContainer(),
    ]);
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
    return Text(date, style: Styles().textStyles?.getTextStyle('panel.event_schedule.title')
    );
  }

  Widget _buildCategoryTitle(String category){
    return Text(category, style: Styles().textStyles?.getTextStyle('panel.event_schedule.category'));
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
                  style: Styles().textStyles?.getTextStyle('panel.event_schedule.search.edit'),
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
                child: Styles().images?.getImage('search'),
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

  //Listeners
  @override
  void onNotification(String name, param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
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
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged,
    ]);
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
      setStateIfMounted(() {});
    }
    else if (name == FlexUI.notifyChanged) {
      setStateIfMounted(() {});
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
                                  child: Styles().images?.getImage('calendar'))),
                          Expanded(
                            child: Text(
                              widget.event!.title!,
                              style: Styles().textStyles?.getTextStyle('widget.title.large.extra_fat'),
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
                                            child: Styles().images?.getImage(favorite ? 'star-filled' : 'star-outline-gray'))))),
                          )
                        ],
                      )
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 4, left: 28),
                    child: Text(widget.event?.displaySuperTime ?? '', style: Styles().textStyles?.getTextStyle('widget.explore.card.detail.regular')),
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
                    style: selected! ? Styles().textStyles?.getTextStyle('widget.tab.selected') : Styles().textStyles?.getTextStyle('widget.tab.not_selected') )),
          )),
    );
  }
}