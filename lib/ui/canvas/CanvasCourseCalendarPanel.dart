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
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/canvas/CanvasCalendarEventDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/SwipeDetector.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CanvasCourseCalendarPanel extends StatefulWidget {
  final int courseId;
  CanvasCourseCalendarPanel({required this.courseId});

  @override
  _CanvasCourseCalendarPanelState createState() => _CanvasCourseCalendarPanelState();
}

class _CanvasCourseCalendarPanelState extends State<CanvasCourseCalendarPanel> implements NotificationsListener {
  List<CanvasCalendarEvent>? _events;
  late DateTime _startDateTime;
  late DateTime _endDateTime;
  late DateTime _selectedDate;
  int _loadingProgress = 0;

  @override
  void initState() {
    NotificationService().subscribe(this, Auth2UserPrefs.notifyFavoritesChanged);
    _initCalendarDates();
    _loadEvents();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx('panel.canvas_calendar.header.title', 'Calendar')!,
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0)
        )
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildContent() {
    double horizontalPadding = 16;
    return SwipeDetector(
        onSwipeLeft: _onSwipeLeft,
        onSwipeRight: _onSwipeRight,
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(children: [
              Expanded(
                  child: SingleChildScrollView(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                    padding: EdgeInsets.only(left: horizontalPadding, right: horizontalPadding, bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [_buildYearDropDown(), _buildMonthDropDown()],
                    )),
                Padding(padding: EdgeInsets.only(left: 5, right: 5, bottom: 10), child: _buildWeekChangeArrows()),
                Padding(padding: EdgeInsets.only(left: 5, right: 5, bottom: 20), child: _buildWeekDaysWidget()),
                Padding(padding: EdgeInsets.symmetric(horizontal: horizontalPadding), child: _buildEventsContent())
              ])))
            ])));
  }

  void _onSwipeLeft() {
    DateTime newDate = _selectedDate.add(Duration(days: 7)); // Swipe to next week
    _changeSelectedDate(year: newDate.year, month: newDate.month, day: newDate.day);
  }

  void _onSwipeRight() {
    DateTime newDate = _selectedDate.subtract(Duration(days: 7)); // Swipe to previous week
    _changeSelectedDate(year: newDate.year, month: newDate.month, day: newDate.day);
  }

  Widget _buildLoadingContent() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorContent() {
    return Center(
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text(
                Localization()
                    .getStringEx('panel.canvas_calendar.load.failed.error.msg', 'Failed to load events. Please, try again later.')!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18))));
  }

  Widget _buildEmptyContent() {
    return Center(
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text(Localization().getStringEx('panel.canvas_calendar.empty.msg', 'There are no events today.')!,
                textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18))));
  }

  Widget _buildEventsContent() {
    if (_isLoading) {
      return _buildLoadingContent();
    }
    if (_events != null) {
      List<CanvasCalendarEvent>? visibleEvents = _visibleEvents;
      if (CollectionUtils.isNotEmpty(visibleEvents)) {
        return _buildVisibleEventsContent(visibleEvents!);
      } else {
        return _buildEmptyContent();
      }
    } else {
      return _buildErrorContent();
    }
  }

  Widget _buildVisibleEventsContent(List<CanvasCalendarEvent> visibleEvents) {
    List<Widget> eventsWidgetList = [];
    eventsWidgetList.add(_buildEventDelimiter());
    for (CanvasCalendarEvent event in visibleEvents) {
      eventsWidgetList.add(_buildEventCard(event));
    }
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: eventsWidgetList));
  }

  Widget _buildEventCard(CanvasCalendarEvent event) {
    bool isFavorite = Auth2().isFavorite(event);

    return GestureDetector(
        onTap: () => _onTapEvent(event),
        child: Stack(children: [
          Column(children: [
            Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Image.asset('images/icon-news.png')),
                    Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(StringUtils.ensureNotEmpty(event.contextName),
                          textAlign: TextAlign.start,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: Styles().colors!.fillColorSecondary, fontFamily: Styles().fontFamilies!.bold, fontSize: 16)),
                      Text(StringUtils.ensureNotEmpty(event.title),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 18)),
                      Text(StringUtils.ensureNotEmpty(event.startAtDisplayDate),
                          style:
                              TextStyle(color: Styles().colors!.disabledTextColor, fontFamily: Styles().fontFamilies!.bold, fontSize: 18))
                    ]))
                  ])),
                  Image.asset('images/chevron-right.png')
                ])),
            _buildEventDelimiter()
          ]),
          Visibility(
              visible: Auth2().canFavorite,
              child: Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Analytics().logSelect(target: "Favorite: ${event.favoriteTitle}");
                        Auth2().prefs?.toggleFavorite(event);
                      },
                      child: Semantics(
                          container: true,
                          label: isFavorite
                              ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites')
                              : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                          hint: isFavorite
                              ? Localization().getStringEx('widget.card.button.favorite.off.hint', '')
                              : Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
                          button: true,
                          excludeSemantics: true,
                          child: Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Container(
                                  padding: EdgeInsets.only(left: 24, bottom: 24),
                                  child: Image.asset(isFavorite ? 'images/icon-star-selected.png' : 'images/icon-star.png',
                                      excludeFromSemantics: true)))))))
        ]));
  }

  Widget _buildEventDelimiter() {
    return Container(color: Styles().colors!.lightGray, height: 1);
  }

  void _onTapEvent(CanvasCalendarEvent event) {
    Analytics().logSelect(target: "Canvas Calendar Event");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCalendarEventDetailPanel(event: event)));
  }

  List<CanvasCalendarEvent>? get _visibleEvents {
    if (CollectionUtils.isEmpty(_events)) {
      return null;
    }
    List<CanvasCalendarEvent> visibleEvents = [];
    for (CanvasCalendarEvent event in _events!) {
      DateTime? eventStartDateLocal = event.startAtLocal;
      if ((eventStartDateLocal != null) &&
          (eventStartDateLocal.year == _selectedDate.year) &&
          (eventStartDateLocal.month == _selectedDate.month) &&
          (eventStartDateLocal.day == _selectedDate.day)) {
        visibleEvents.add(event);
      }
    }
    return visibleEvents;
  }

  Widget _buildYearDropDown() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Styles().colors!.lightGray!, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(4))),
      child: Padding(
          padding: EdgeInsets.only(left: 10),
          child: DropdownButtonHideUnderline(
              child: DropdownButton(
            style: TextStyle(color: Styles().colors!.textSurfaceAccent, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
            items: _buildYearDropDownItems,
            value: _selectedDate.year,
            onChanged: (year) => _onYearChanged(year),
          ))),
    );
  }

  List<DropdownMenuItem<int>> get _buildYearDropDownItems {
    int currentYear = DateTime.now().year;
    int previousYear = currentYear - 1;
    int nextYear = currentYear + 1;
    List<DropdownMenuItem<int>> items = [];
    items.add(DropdownMenuItem(value: previousYear, child: Text('$previousYear')));
    items.add(DropdownMenuItem(value: currentYear, child: Text('$currentYear')));
    items.add(DropdownMenuItem(value: nextYear, child: Text('$nextYear')));
    return items;
  }

  void _onYearChanged(dynamic year) {
    _changeSelectedDate(year: year);
  }

  Widget _buildMonthDropDown() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Styles().colors!.lightGray!, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(4))),
      child: Padding(
          padding: EdgeInsets.only(left: 10),
          child: DropdownButtonHideUnderline(
              child: DropdownButton(
            style: TextStyle(color: Styles().colors!.textSurfaceAccent, fontSize: 20, fontFamily: Styles().fontFamilies!.bold),
            items: _buildMonthDropDownItems,
            value: _selectedDate.month,
            onChanged: (month) => _onMonthChanged(month),
          ))),
    );
  }

  List<DropdownMenuItem<int>> get _buildMonthDropDownItems {
    List<DropdownMenuItem<int>> items = [];
    for (int i = 1; i < 13; i++) {
      items.add(DropdownMenuItem(value: i, child: Text(DateFormat.MMMM().format(DateTime(0, i)))));
    }
    return items;
  }

  void _onMonthChanged(dynamic month) {
    _changeSelectedDate(month: month);
  }

  Widget _buildWeekChangeArrows() {
    double imageSize = 30;
    return Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      GestureDetector(onTap: _onSwipeRight, child: Container(width: imageSize, height: imageSize, child: Image.asset('images/chevron-left-blue.png'))),
      GestureDetector(onTap: _onSwipeLeft, child: Container(width: imageSize, height: imageSize, child: Image.asset('images/chevron-blue-right.png')))
    ]);
  }

  Widget _buildWeekDaysWidget() {
    int selectedWeekDay = _selectedDate.weekday;
    DateTime currentWeekDate =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).subtract(Duration(days: (selectedWeekDay - 1)));

    List<Widget> dayWidgetList = [];
    for (int i = 1; i < 8; i++) {
      Widget dayWidget = GestureDetector(
          onTap: () => _onTapWeekDay(i),
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            Text(StringUtils.ensureNotEmpty(AppDateTime().formatDateTime(currentWeekDate, format: 'E')),
                style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold)),
            Padding(
                padding: EdgeInsets.only(top: 3),
                child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: _weekDayBoxDecoration(currentWeekDate),
                    child: Text(StringUtils.ensureNotEmpty(AppDateTime().formatDateTime(currentWeekDate, format: 'd')),
                        style: TextStyle(color: _weekDayTextColor(currentWeekDate), fontSize: 18)))),
            Visibility(
                visible: _hasEvent(currentWeekDate),
                child: Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Container(
                        decoration: BoxDecoration(color: Styles().colors!.fillColorPrimary, shape: BoxShape.circle), width: 6, height: 6)))
          ]));
      dayWidgetList.add(dayWidget);
      currentWeekDate = currentWeekDate.add(Duration(days: 1));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: dayWidgetList);
  }

  BoxDecoration _weekDayBoxDecoration(DateTime date) {
    bool isToday = _isToday(date);
    bool isSelectedDate = _isSelectedDay(date);

    return BoxDecoration(
        color: (isToday ? Styles().colors!.fillColorPrimary : null),
        shape: BoxShape.circle,
        border: Border.all(color: (isSelectedDate ? Styles().colors!.fillColorPrimary! : Colors.transparent), width: 2));
  }

  Color _weekDayTextColor(DateTime date) {
    return _isToday(date) ? Styles().colors!.white! : Styles().colors!.fillColorPrimary!;
  }

  bool _isToday(DateTime currentDate) {
    DateTime now = DateTime.now();
    return (currentDate.year == now.year) && (currentDate.month == now.month) && (currentDate.day == now.day);
  }

  bool _isSelectedDay(DateTime currentDate) {
    return (currentDate.year == _selectedDate.year) && (currentDate.month == _selectedDate.month) && (currentDate.day == _selectedDate.day);
  }

  bool _hasEvent(DateTime date) {
    if (CollectionUtils.isEmpty(_events)) {
      return false;
    }
    for (CanvasCalendarEvent event in _events!) {
      DateTime? eventStartDateLocal = event.startAtLocal;
      if ((eventStartDateLocal != null) &&
          (eventStartDateLocal.year == date.year) &&
          (eventStartDateLocal.month == date.month) &&
          (eventStartDateLocal.day == date.day)) {
        return true;
      }
    }
    return false;
  }

  void _onTapWeekDay(int weekDay) {
    int daysDiff = weekDay - _selectedDate.weekday;
    DateTime newDate = _selectedDate.add(Duration(days: (daysDiff)));
    _changeSelectedDate(year: newDate.year, month: newDate.month, day: newDate.day);
  }

  void _initCalendarDates() {
    DateTime now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _initEventsTimeFrame();
  }

  // Load events per week
  void _initEventsTimeFrame() {
    int selectedWeekDay = _selectedDate.weekday;
    _startDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).subtract(Duration(days: (selectedWeekDay - 1)));
    _endDateTime = _startDateTime.add(Duration(days: 7)).subtract(Duration(milliseconds: 1));
  }

  void _changeSelectedDate({int? year, int? month, int? day}) {
    int newYear = (year != null) ? year : _selectedDate.year;
    int newMonth = (month != null) ? month : _selectedDate.month;
    int newDay = (day != null) ? day : _selectedDate.day;
    _selectedDate = DateTime(newYear, newMonth, newDay);
    if (mounted) {
      setState(() {});
    }
    _loadEventsIfNeeded();
  }

  void _loadEvents() {
    _increaseProgress();
    Canvas().loadCalendarEvents(widget.courseId, startDate: _startDateTime, endDate: _endDateTime).then((events) {
      _events = events;
      _decreaseProgress();
    });
  }

  void _loadEventsIfNeeded() {
    if (_selectedDate.isBefore(_startDateTime) || _selectedDate.isAfter(_endDateTime)) {
      _initEventsTimeFrame();
      _loadEvents();
    }
  }

  void _increaseProgress() {
    _loadingProgress++;
    if (mounted) {
      setState(() {});
    }
  }

  void _decreaseProgress() {
    _loadingProgress--;
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isLoading {
    return (_loadingProgress > 0);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setState(() {});
    }
  }
}
