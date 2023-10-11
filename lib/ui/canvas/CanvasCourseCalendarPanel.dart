/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/canvas/CanvasCalendarEventDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/ui/widgets/swipe_detector.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class CanvasCourseCalendarPanel extends StatefulWidget {
  final int courseId;
  CanvasCourseCalendarPanel({required this.courseId});

  @override
  _CanvasCourseCalendarPanelState createState() => _CanvasCourseCalendarPanelState();
}

class _CanvasCourseCalendarPanelState extends State<CanvasCourseCalendarPanel> implements NotificationsListener {
  List<CanvasCalendarEvent>? _events;
  List<CanvasCourse>? _courses;
  int? _selectedCourseId;
  CanvasCalendarEventType? _selectedType;
  late DateTime _startDateTime;
  late DateTime _endDateTime;
  late DateTime _selectedDate;
  bool _loading = false;

  @override
  void initState() {
    NotificationService().subscribe(this, Auth2UserPrefs.notifyFavoritesChanged);
    _selectedCourseId = widget.courseId;
    _selectedType = CanvasCalendarEventType.event;
    _courses = Canvas().courses;
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
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.canvas_calendar.header.title', 'Calendar'),
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: uiuc.TabBar(),
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
                    padding: EdgeInsets.only(left: 12, right: 12, bottom: 20),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [_buildYearDropDown(), _buildMonthDropDown(), _buildTypeDropDown()])),
                Padding(
                    padding: EdgeInsets.only(left: 5, right: 5, bottom: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      _buildArrow(imagePath: 'images/chevron-left-blue.png', onTap: _onSwipeRight),
                      Expanded(child: Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: _buildCourseDropDown())),
                      _buildArrow(imagePath: 'images/chevron-blue-right.png', onTap: _onSwipeLeft)
                    ])),
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
            child: Text(_errorMessage,
                textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildEmptyContent() {
    return Center(
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text(_emptyMessage,
                textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  String get _errorMessage {
    switch (_selectedType) {
      case CanvasCalendarEventType.event:
        return Localization()
            .getStringEx('panel.canvas_calendar.events.load.failed.error.msg', 'Failed to load events. Please, try again later.');
      case CanvasCalendarEventType.assignment:
        return Localization()
            .getStringEx('panel.canvas_calendar.assignments.load.failed.error.msg', 'Failed to load assignments. Please, try again later.');
      default:
        return Localization().getStringEx(
            'panel.canvas_calendar.all.load.failed.error.msg', 'Failed to load events and assignments. Please, try again later.');
    }
  }

  String get _emptyMessage {
    switch (_selectedType) {
      case CanvasCalendarEventType.event:
        return Localization().getStringEx('panel.canvas_calendar.events.empty.msg', 'There are no events today.');
      case CanvasCalendarEventType.assignment:
        return Localization().getStringEx('panel.canvas_calendar.assignments.empty.msg', 'There are no assignments today.');
      default:
        return Localization().getStringEx('panel.canvas_calendar.all.empty.msg', 'There are no events and assignments today.');
    }
  }

  Widget _buildEventsContent() {
    if (_loading) {
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
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Image.asset(
                            (event.type == CanvasCalendarEventType.assignment) ? 'images/icon-schedule.png' : 'images/icon-news.png')),
                    Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(StringUtils.ensureNotEmpty(event.contextName),
                          textAlign: TextAlign.start,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Styles().textStyles?.getTextStyle("widget.label.regular.fat")),
                      Text(StringUtils.ensureNotEmpty(event.title),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Styles().textStyles?.getTextStyle("widget.title.medium.fat")),
                      Text(StringUtils.ensureNotEmpty(event.startAtDisplayDate),
                          style: Styles().textStyles?.getTextStyle("widget.title.disabled.medium.fat"))
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
                        Analytics().logSelect(target: "Favorite: ${event.title}");
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
                                  child: Image.asset(isFavorite ? 'images/icon-star-blue.png' : 'images/icon-star-gray-frame-thin.png',
                                      excludeFromSemantics: true)))))))
        ]));
  }

  Widget _buildEventDelimiter() {
    return Container(color: Styles().colors!.lightGray, height: 1);
  }

  void _onTapEvent(CanvasCalendarEvent event) {
    if (event.type == CanvasCalendarEventType.assignment) {
      Analytics().logSelect(target: 'Canvas Calendar -> Assignment');
      String? url = event.assignment?.htmlUrl;
      if (StringUtils.isNotEmpty(url)) {
        if (UrlUtils.launchInternal(url)) {
          Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
        } else {
          Uri? uri = Uri.tryParse(url!);
          if (uri != null) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      }
    } else {
      Analytics().logSelect(target: 'Canvas Calendar -> Event');
      Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCalendarEventDetailPanel(eventId: event.id!)));
    }
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
    _sortEvents(visibleEvents);
    return visibleEvents;
  }

  void _sortEvents(List<CanvasCalendarEvent>? events) {
    if (CollectionUtils.isNotEmpty(events)) {
      events!.sort((CanvasCalendarEvent first, CanvasCalendarEvent second) {
        DateTime? firstDate = first.startAt;
        DateTime? secondDate = second.startAt;
        if ((firstDate != null) && (secondDate != null)) {
          return firstDate.compareTo(secondDate);
        } else if (firstDate != null) {
          return -1;
        } else if (secondDate != null) {
          return 1;
        } else {
          return 0;
        }
      });
    }
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
              style: Styles().textStyles?.getTextStyle("panel.canvas.item.regular"),
              items: _buildYearDropDownItems,
              value: _selectedDate.year,
              onChanged: (year) => _onYearChanged(year),
            ))));
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
              style: Styles().textStyles?.getTextStyle("panel.canvas.item.large.fat"),
              items: _buildMonthDropDownItems,
              value: _selectedDate.month,
              onChanged: (month) => _onMonthChanged(month),
            ))));
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

  Widget _buildTypeDropDown() {
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
              style: Styles().textStyles?.getTextStyle("panel.canvas.item.regular"),
              items: _buildTypeDropDownItems,
              value: _selectedType,
              onChanged: (type) => _onTypeChanged(type),
            ))));
  }

  List<DropdownMenuItem<CanvasCalendarEventType>> get _buildTypeDropDownItems {
    List<DropdownMenuItem<CanvasCalendarEventType>> items = [];
    items.add(DropdownMenuItem(value: null, child: Text(Localization().getStringEx('panel.canvas_calendar.all_types.label', 'All'))));
    for (CanvasCalendarEventType type in CanvasCalendarEventType.values) {
      items.add(DropdownMenuItem(value: type, child: Text(StringUtils.ensureNotEmpty(CanvasCalendarEvent.typeToDisplayString(type)))));
    }
    return items;
  }

  void _onTypeChanged(dynamic type) {
    if (type != _selectedType) {
      _selectedType = type;
      _loadEvents();
    }
  }

  Widget _buildCourseDropDown() {
    double height = MediaQuery.of(context).textScaleFactor * 62;
    return Container(
        height: height,
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Styles().colors!.lightGray!, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(4))),
        child: Padding(
            padding: EdgeInsets.only(left: 10),
            child: DropdownButtonHideUnderline(
                child: DropdownButton(
                    style: Styles().textStyles?.getTextStyle("panel.canvas.item.regular.fat"),
                    items: _buildCourseDropDownItems,
                    value: _selectedCourseId,
                    itemHeight: null,
                    isExpanded: true,
                    onChanged: (courseId) => _onCourseIdChanged(courseId)))));
  }

  List<DropdownMenuItem<int>>? get _buildCourseDropDownItems {
    if (CollectionUtils.isEmpty(_courses)) {
      return null;
    }
    List<DropdownMenuItem<int>> items = [];
    CanvasCourse? currentCourse = _getCurrentCourse();
    if (currentCourse != null) {
      items.add(DropdownMenuItem(
          value: currentCourse.id,
          child: Text(StringUtils.ensureNotEmpty(currentCourse.name),
              style: ((_selectedCourseId == currentCourse.id) ? Styles().textStyles?.getTextStyle("panel.canvas.item.regular.fat") :  Styles().textStyles?.getTextStyle("panel.canvas.item.regular")))));
    }
    items.add(DropdownMenuItem(
        value: null,
        child: Text(Localization().getStringEx('panel.canvas.common.all_courses.label', 'All Courses'),
            style: (_selectedCourseId == null) ? Styles().textStyles?.getTextStyle("panel.canvas.item.regular.fat") :  Styles().textStyles?.getTextStyle("panel.canvas.item.regular"))));
    return items;
  }

  CanvasCourse? _getCurrentCourse() {
    CanvasCourse? selectedCourse;
    if (CollectionUtils.isNotEmpty(_courses)) {
      for (CanvasCourse course in _courses!) {
        if (course.id == widget.courseId) {
          selectedCourse = course;
          break;
        }
      }
    }
    return selectedCourse;
  }

  void _onCourseIdChanged(dynamic courseId) {
    if (_selectedCourseId != courseId) {
      _selectedCourseId = courseId;
      _loadEvents();
    }
  }

  Widget _buildArrow({GestureTapCallback? onTap, required String imagePath}) {
    double imageSize = 30;
    return GestureDetector(onTap: onTap, child: Container(width: imageSize, height: imageSize, child: Image.asset(imagePath)));
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
                style: Styles().textStyles?.getTextStyle("widget.title.small.fat")),
            Padding(
                padding: EdgeInsets.only(top: 3),
                child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: _weekDayBoxDecoration(currentWeekDate),
                    child: Text(StringUtils.ensureNotEmpty(AppDateTime().formatDateTime(currentWeekDate, format: 'd')),
                        style: Styles().textStyles?.getTextStyle("widget.title.medium")?.copyWith(color: _weekDayTextColor(currentWeekDate))))),
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

  ///
  /// Calculates month time frame including the whole weeks of the month's first and last day.
  ///
  void _initEventsTimeFrame() {
    DateTime monthStartDateTime = DateTime(_selectedDate.year, _selectedDate.month, 1);
    DateTime monthEndDateTime = DateTime(_selectedDate.year, (_selectedDate.month + 1), 1).subtract(Duration(milliseconds: 1));
    int monthStartDateWeekDay = monthStartDateTime.weekday;
    int monthEndDateWeekDay = monthEndDateTime.weekday;
    _startDateTime = monthStartDateTime.subtract(Duration(days: (monthStartDateWeekDay - 1)));
    _endDateTime = monthEndDateTime.add(Duration(days: (7 - monthEndDateWeekDay)));
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
    if (_events != null) {
      _events = null;
    }
    if (_selectedCourseId != null) {
      _loadEventTypeForSingleCourse(_selectedCourseId!);
    } else {
      _loadEventsForAllCourses();
    }
  }

  void _loadEventTypeForSingleCourse(int courseId) {
    if (_selectedType != null) {
      _loadForSingleCourse(courseId: courseId, type: _selectedType);
    } else {
      for (CanvasCalendarEventType type in CanvasCalendarEventType.values) {
        _loadForSingleCourse(courseId: courseId, type: type);
      }
    }
  }

  void _loadForSingleCourse({required int courseId, CanvasCalendarEventType? type}) {
    setStateIfMounted(() {
      _loading = true;
    });
    Canvas().loadCalendarEvents(courseId: courseId, type: type, startDate: _startDateTime, endDate: _endDateTime).then((events) {
      setStateIfMounted(() {
        if (CollectionUtils.isNotEmpty(events)) {
          if (_events == null) {
            _events = [];
          }
          _events!.addAll(events!);
        }
        _loading = false;
      });
    });
  }

  void _loadEventsForAllCourses() {
    if (CollectionUtils.isNotEmpty(_courses)) {
      for (CanvasCourse course in _courses!) {
        _loadEventTypeForSingleCourse(course.id!);
      }
    }
  }

  void _loadEventsIfNeeded() {
    if (_selectedDate.isBefore(_startDateTime) || _selectedDate.isAfter(_endDateTime)) {
      _initEventsTimeFrame();
      _loadEvents();
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setState(() {});
    }
  }
}
