import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/StudentCourse.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/ui/academics/student_courses/StudentCourseDetailPanel.dart';
import 'package:illinois/ui/academics/student_courses/StudentCoursesCalendarLayout.dart';
import 'package:illinois/ui/academics/student_courses/StudentCoursesHomePanel.dart';
import 'package:illinois/ui/academics/student_courses/StudentCoursesWidgets.dart';
import 'package:illinois/ui/accessibility/AccessiblePageView.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class HomeStudentCoursesWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeStudentCoursesWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.student_courses.header.label', 'My Courses');

  @override
  _HomeStudentCoursesWidgetState createState() => _HomeStudentCoursesWidgetState();
}

class _HomeStudentCoursesWidgetState extends State<HomeStudentCoursesWidget> with NotificationsListener {

  List<StudentCourse>? _courses;
  bool _loading = false;
  DateTime? _pausedDateTime;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();

  int? _calendarPageIndex;

  late StudentCoursesViewType _viewType;

  StreamSubscription<String>? _updateSubscription;

  @override
  void initState() {

    _viewType = StudentCoursesViewTypeExt.fromJson(Storage().getHomeFavoriteSelectedContent(widget.favoriteId)) ?? StudentCoursesViewType.calendar;

    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Auth2.notifyLoginChanged,
      Connectivity.notifyStatusChanged,
      StudentCourses.notifyTermsChanged,
      StudentCourses.notifySelectedTermChanged,
      StudentCourses.notifyCachedCoursesChanged,
      AppDateTime.notifyTimeZoneChanged,
    ]);


    _updateSubscription = widget.updateController?.stream.listen((String command) {
      if (command == HomePanel.notifyRefresh) {
        _updateCourses(forceLoad: true);
      }
    });

    _loadCourses();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _pageController?.dispose();
    _updateSubscription?.cancel();
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == Auth2.notifyLoginChanged) {
      _updateCourses();
    }
    else if (name == Connectivity.notifyStatusChanged) {
      _updateCourses();
    }
    else if (name == StudentCourses.notifyTermsChanged) {
      _updateCourses();
    }
    else if (name == StudentCourses.notifySelectedTermChanged) {
      _updateCourses();
    }
    else if (name == StudentCourses.notifyCachedCoursesChanged) {
      if ((param == null) || (StudentCourses().displayTermId == param)) {
        _updateCourses();
      }
    }
    else if (name == AppDateTime.notifyTimeZoneChanged) {
      setStateIfMounted(() {});
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateCourses(showProgress: false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => HomeFavoriteWidget(
    favoriteId: widget.favoriteId,
    title: HomeStudentCoursesWidget.title,
    updateController: widget.updateController,
    actions: [ _buildTermsDropDown(), ],
    child: _buildContent(),
  );

  TextStyle? _getTermDropDownItemStyle({bool selected = false}) => selected ? Styles().textStyles.getTextStyle("widget.button.title.small.fat") : Styles().textStyles.getTextStyle("widget.button.title.small");

  Widget _buildTermsDropDown() {
    StudentCourseTerm? currentTerm = StudentCourses().displayTerm;

    return Semantics(label: currentTerm?.name, hint: Localization().getStringEx('widget.home.student_courses.term_dropdown.hint', 'Double tap to select term'), button: true, container: true, child:
      DropdownButtonHideUnderline(child: StudentCoursesHomePanel.wrapDropDownTheme(
        DropdownButton<String>(
          icon: Padding(padding: EdgeInsets.only(left: 4), child: Styles().images.getImage('chevron-down', excludeFromSemantics: true)),
          isExpanded: false,
          isDense: true,
          dropdownColor: Styles().colors.white,
          focusColor: Styles().colors.white,
          borderRadius: StudentCoursesHomePanel.dropdownMenuBorderRadius,
          style: _getTermDropDownItemStyle(selected: false),
          hint: (currentTerm?.name?.isNotEmpty ?? false) ? Text(currentTerm?.name ?? '', style: _getTermDropDownItemStyle(selected: true)) : null,
          alignment: AlignmentDirectional.centerEnd,
          items: _buildTermDropDownItems(),
          onChanged: _onTermDropDownValueChanged
        ),
      )),
    );
  }

  List<DropdownMenuItem<String>>? _buildTermDropDownItems() {
    List<StudentCourseTerm>? terms = StudentCourses().terms;
    String? currentTermId = StudentCourses().displayTermId;

    List<DropdownMenuItem<String>>? items;
    if (terms != null) {
      items = <DropdownMenuItem<String>>[];
      for (StudentCourseTerm term in terms) {
        items.add(DropdownMenuItem<String>(
          value: term.id,
          child: Text(term.name ?? '', style: _getTermDropDownItemStyle(selected: (term.id == currentTermId)),)
        ));
      }
    }
    return items;
  }

  void _onTermDropDownValueChanged(String? termId) {
    StudentCourses().selectedTermId = termId;
  }

  Widget _buildContent() {
    if (_loading) {
      return HomeProgressWidget();
    }
    else if (Connectivity().isOffline) {
      return HomeMessageCard(message: Localization().getStringEx('widget.home.student_courses.text.offline.description', 'My Courses not available while offline.'),);
    }
    else if (!Auth2().isOidcLoggedIn) {
      return HomeMessageCard(message: Localization().getStringEx('widget.home.student_courses.text.logged_out.description', 'You need to be logged in with your NetID to access My Courses. Set your privacy level to 4 or 5 in your Profile. Then find the sign-in prompt under Settings.'),);
    }
    else if (_courses == null) {
      return HomeMessageCard(message: Localization().getStringEx('widget.home.student_courses.text.failed.description', 'It appears you have no courses registered for the selected term.'),);
    }
    else if (_courses?.isEmpty ?? true) {
      return HomeMessageCard(message: Localization().getStringEx('widget.home.student_courses.text.empty.description', 'You do not appear to be enrolled in any courses for the selected term.'),);
    }
    else {
      return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 8), child: _buildViewTypeToggle()),
        Visibility(visible: (_viewType == StudentCoursesViewType.calendar), maintainState: true, child: _buildCalendarContent()),
        Visibility(visible: (_viewType == StudentCoursesViewType.list), maintainState: true, child: _buildCoursesContent()),
      ]);
    }
  }

  Widget _buildViewTypeToggle() => Row(children: <Widget>[
    Expanded(child: HomeFavTabBarBtn(
      StudentCoursesViewType.calendar.pillTitle.toUpperCase(),
      position: HomeFavTabBarBtnPos.first,
      selected: (_viewType == StudentCoursesViewType.calendar),
      onTap: () => _onTapViewType(StudentCoursesViewType.calendar),
    )),
    Expanded(child: HomeFavTabBarBtn(
      StudentCoursesViewType.list.pillTitle.toUpperCase(),
      position: HomeFavTabBarBtnPos.last,
      selected: (_viewType == StudentCoursesViewType.list),
      onTap: () => _onTapViewType(StudentCoursesViewType.list),
    )),
  ]);

  void _onTapViewType(StudentCoursesViewType viewType) {
    if (_viewType != viewType) {
      setStateIfMounted(() {
        _viewType = viewType;
        Storage().setHomeFavoriteSelectedContent(widget.favoriteId, viewType.toJson());
      });
    }
  }

  Widget _buildCalendarContent() {
    int todayIndex = StudentCoursesCalendarLayout.weekdayOrder.indexOf(AppDateTime().getZonedNowTZTime().weekday);
    int initialPageIndex = _calendarPageIndex ?? ((0 <= todayIndex) ? todayIndex : 0);

    return _HomeStudentCoursesCalendarPager(
      courses: _scheduledCourses,
      initialPageIndex: initialPageIndex,
      onPageIndexChanged: (int index) => _calendarPageIndex = index,
      onViewAll: _onViewAll,
    );
  }

  Widget _buildCoursesContent() {
    List<StudentCourse> visibleCourses = _scheduledCourses ?? <StudentCourse>[];

    Widget contentWidget;
    int visibleCount = visibleCourses.length; // Config().homeCampusHighlightsCount

    if (1 < visibleCount) {
      List<Widget> coursePages = <Widget>[];
      for (StudentCourse course in visibleCourses) {
        coursePages.add(Padding(padding: HomeCard.defaultPageMargin, child:
          StudentCourseCard(course: course, displayMode: CardDisplayMode.home,),
        ),);
      }

      if (_pageController == null) {
        double screenWidth = MediaQuery.of(context).size.width;
        double pageViewport = (screenWidth - 2 * HomeCard.pageSpacing) / screenWidth;
        _pageController = PageController(viewportFraction: pageViewport);
      }

      double pageHeight = StudentCourseCard.height(context);

      contentWidget = Container(constraints: BoxConstraints(minHeight: pageHeight), child:
        AccessiblePageView(
          key: _pageViewKey,
          controller: _pageController,
          estimatedPageSize: pageHeight,
          allowImplicitScrolling: true,
          children: coursePages,
        ),
      );
    }
    else if (1 == visibleCount) {
      contentWidget = Padding(padding: HomeCard.defaultSingleCardMargin, child:
        StudentCourseCard(course: visibleCourses.first, displayMode: CardDisplayMode.home),
      );
    }
    else {
      contentWidget = SizedBox.shrink();
    }

    return Column(children: [
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => visibleCount, centerWidget:
        HomeBrowseLinkButton(
          title: Localization().getStringEx('widget.home.student_courses.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.student_courses.button.all.hint', 'Tap to view all courses'),
          onTap: _onViewAll,
        ),
      ),
    ],);
  }

  void _loadCourses() {
    if (Connectivity().isNotOffline && (StudentCourses().displayTermId != null) && Auth2().isOidcLoggedIn && !_loading) {
      _loading = true;
      StudentCourses().loadCourses(termId: StudentCourses().displayTermId!).then((List<StudentCourse>? courses) {
        setStateIfMounted(() {
          _courses = courses;
          _loading = false;
        });
      });
    }
  }

  void _updateCourses({bool forceLoad = false, bool showProgress = true}) {
    if (Connectivity().isNotOffline && (StudentCourses().displayTermId != null) && Auth2().isOidcLoggedIn && !_loading) {
      if (showProgress) {
        setStateIfMounted(() {
          _loading = true;
        });
      }
      StudentCourses().loadCourses(termId: StudentCourses().displayTermId!, forceLoad: forceLoad).then((List<StudentCourse>? courses) {
        setStateIfMounted(() {
          _courses = courses;
          _loading = false;
        });
      });
    }
    else {
      setStateIfMounted(() { });
    }
  }

  void _onViewAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentCoursesHomePanel(initialViewType: _viewType)));
  }

  List<StudentCourse>? get _scheduledCourses => _courses?.withScheduledMeeting;
}

///////////////////////////////
// _HomeStudentCoursesCalendarPager

class _HomeStudentCoursesCalendarPager extends StatefulWidget {
  final List<StudentCourse>? courses;
  final int initialPageIndex;
  final ValueChanged<int> onPageIndexChanged;
  final VoidCallback onViewAll;

  _HomeStudentCoursesCalendarPager({required this.courses, required this.initialPageIndex, required this.onPageIndexChanged, required this.onViewAll});

  @override
  State<_HomeStudentCoursesCalendarPager> createState() => _HomeStudentCoursesCalendarPagerState();
}

class _HomeStudentCoursesCalendarPagerState extends State<_HomeStudentCoursesCalendarPager> {
  PageController? _pageController;
  final Key _pageViewKey = UniqueKey();

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> dayPages = StudentCoursesCalendarLayout.weekdayOrder.map((int weekday) =>
      Padding(padding: HomeCard.defaultPageMargin, child:
        _HomeStudentCoursesCalendarContentWidget(courses: widget.courses, weekday: weekday),
      ),
    ).toList();

    if (_pageController == null) {
      double screenWidth = MediaQuery.of(context).size.width;
      double pageViewport = (screenWidth - 2 * HomeCard.pageSpacing) / screenWidth;
      _pageController = PageController(viewportFraction: pageViewport, initialPage: widget.initialPageIndex);
    }

    double pageHeight = StudentCourseCard.height(context);

    return Column(children: [
      Container(constraints: BoxConstraints(minHeight: pageHeight), child:
        AccessiblePageView(
          key: _pageViewKey,
          controller: _pageController,
          estimatedPageSize: pageHeight,
          allowImplicitScrolling: true,
          onPageChanged: widget.onPageIndexChanged,
          children: dayPages,
        ),
      ),
      AccessibleViewPagerNavigationButtons(controller: _pageController, initialPage: widget.initialPageIndex, pagesCount: () => dayPages.length, centerWidget:
        HomeBrowseLinkButton(
          title: Localization().getStringEx('widget.home.student_courses.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.student_courses.button.all.hint', 'Tap to view all courses'),
          onTap: widget.onViewAll,
        ),
      ),
    ]);
  }
}

///////////////////////////////
// _HomeStudentCoursesCalendarContentWidget

class _HomeStudentCoursesCalendarContentWidget extends StatefulWidget {
  final List<StudentCourse>? courses;
  final int weekday;

  _HomeStudentCoursesCalendarContentWidget({this.courses, required this.weekday});

  @override
  State<StatefulWidget> createState() => _HomeStudentCoursesCalendarContentWidgetState();
}

class _HomeStudentCoursesCalendarContentWidgetState extends State<_HomeStudentCoursesCalendarContentWidget> with NotificationsListener {

  static const double _minHourHeight = 24;
  static const int _startHour = 8;
  static const int _endHour = 16;

  static const double _cardPadding = 16;
  static const double _headerHeight = 32;
  static const double _gridTopPadding = 8;
  static const double _timeColumnGap = 8;
  static const double _closingRowHeight = _minHourHeight;

  double _hourHeight = _minHourHeight;

  late final List<Color> _coursePalette;
  Map<String, Color> _courseColors = <String, Color>{};
  List<StudentCourseBlock> _blocks = <StudentCourseBlock>[];

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      AppDateTime.notifyTimeZoneChanged,
    ]);
    _coursePalette = StudentCoursesCalendarLayout.defaultPalette;
    _updateCourseColors();
    _updateBlocks();
  }

  @override
  void didUpdateWidget(_HomeStudentCoursesCalendarContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool coursesChanged = !identical(widget.courses, oldWidget.courses);
    if (coursesChanged) {
      _updateCourseColors();
    }
    if (coursesChanged || (widget.weekday != oldWidget.weekday)) {
      _updateBlocks();
    }
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppDateTime.notifyTimeZoneChanged) {
      setStateIfMounted(() {
        _updateBlocks();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int visibleHourCount = _endHour - _startHour;
    double targetCardHeight = StudentCourseCard.height(context);
    double chromeHeight = _headerHeight + _gridTopPadding + _cardPadding + _closingRowHeight;
    _hourHeight = math.max((targetCardHeight - chromeHeight) / visibleHourCount, _minHourHeight);
    double gridHeight = visibleHourCount * _hourHeight;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: HomeCard.boxDecoration,
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        _buildHeader(),
        Padding(padding: EdgeInsets.fromLTRB(_cardPadding, _gridTopPadding, _cardPadding, _cardPadding), child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            _buildTimeColumn(),
            SizedBox(width: _timeColumnGap),
            Expanded(child: SizedBox(height: gridHeight + _closingRowHeight, child: _buildDayColumn())),
          ]),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: _headerHeight,
      padding: EdgeInsets.symmetric(horizontal: _cardPadding),
      decoration: BoxDecoration(
        color: HomeCard.backColor,
        border: Border(bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1)),
        boxShadow: <BoxShadow>[BoxShadow(color: Styles().colors.blackTransparent018, blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Align(alignment: Alignment.centerLeft, child:
        Text(_dayLabel, style: Styles().textStyles.getTextStyle('widget.card.title.tiny.fat')),
      ),
    );
  }

  String get _dayLabel => _weekdayName(widget.weekday);

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday: return Localization().getStringEx('widget.home.student_courses.calendar.day.monday.label', 'MONDAY');
      case DateTime.tuesday: return Localization().getStringEx('widget.home.student_courses.calendar.day.tuesday.label', 'TUESDAY');
      case DateTime.wednesday: return Localization().getStringEx('widget.home.student_courses.calendar.day.wednesday.label', 'WEDNESDAY');
      case DateTime.thursday: return Localization().getStringEx('widget.home.student_courses.calendar.day.thursday.label', 'THURSDAY');
      case DateTime.friday: return Localization().getStringEx('widget.home.student_courses.calendar.day.friday.label', 'FRIDAY');
      case DateTime.saturday: return Localization().getStringEx('widget.home.student_courses.calendar.day.saturday.label', 'SATURDAY');
      case DateTime.sunday: return Localization().getStringEx('widget.home.student_courses.calendar.day.sunday.label', 'SUNDAY');
      default: return '';
    }
  }

  // Data prep

  void _updateBlocks() {
    List<StudentCourseBlock> blocks = <StudentCourseBlock>[];
    for (StudentCourse course in widget.courses ?? <StudentCourse>[]) {
      int? startMinutes = course.section?.startTimeMinutes;
      bool matchesWeekday = course.section?.weekdays.contains(widget.weekday) ?? false;
      if ((startMinutes != null) && matchesWeekday) {
        int durationMinutes = StudentCoursesCalendarLayout.resolveDurationMinutes(startMinutes: startMinutes, endMinutes: course.section?.endTimeMinutes);
        StudentCourseBlock block = StudentCourseBlock(course: course, startMinutes: startMinutes, durationMinutes: durationMinutes);
        if ((block.startMinutes < ((_endHour + 1) * 60)) && (block.endMinutes > (_startHour * 60))) {
          blocks.add(block);
        }
      }
    }
    StudentCoursesCalendarLayout.layoutOverlappingBlocks(blocks);
    StudentCoursesCalendarLayout.assignPartOfTermLabels(blocks);
    _blocks = blocks;
  }

  void _updateCourseColors() {
    _courseColors = StudentCoursesCalendarLayout.computeCourseColors(widget.courses, _coursePalette);
  }

  // Hour grid + course blocks

  Widget _buildTimeColumn() {
    int visibleHourCount = _endHour - _startHour;
    return IntrinsicWidth(child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[
        ...List<Widget>.generate(visibleHourCount, (int index) =>
          SizedBox(height: _hourHeight, child: Align(alignment: Alignment.centerRight, child:
            _buildHourLabelText(StudentCoursesCalendarLayout.hourLabel(_startHour + index)),
          )),
        ),
        SizedBox(height: _closingRowHeight, child: Align(alignment: Alignment.centerRight, child:
          _buildHourLabelText(StudentCoursesCalendarLayout.hourLabel(_endHour)),
        )),
      ]),
    );
  }

  Widget _buildHourLabelText(String label) => Text(label, style: Styles().textStyles.getTextStyle('widget.message.tiny'));

  Widget _buildDayColumn() {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) =>
      Stack(children: <Widget>[
        ..._blocks.map((StudentCourseBlock block) => _buildCourseBlock(block, dayWidth: constraints.maxWidth)),
      ]),
    );
  }

  double _minutesToOffset(double minutes) {
    double windowStartMinutes = (_startHour * 60).toDouble();
    double windowFullEndMinutes = (_endHour * 60).toDouble();
    double windowOverflowEndMinutes = windowFullEndMinutes + 60;

    double clampedMinutes = minutes.clamp(windowStartMinutes, windowOverflowEndMinutes);
    if (clampedMinutes <= windowFullEndMinutes) {
      return ((clampedMinutes - windowStartMinutes) / 60.0) * _hourHeight;
    }
    else {
      double fullScaleHeight = ((windowFullEndMinutes - windowStartMinutes) / 60.0) * _hourHeight;
      return fullScaleHeight + ((clampedMinutes - windowFullEndMinutes) / 60.0) * _closingRowHeight;
    }
  }

  Widget _buildCourseBlock(StudentCourseBlock block, {required double dayWidth}) {
    double columnWidth = dayWidth / block.columnCount;
    double top = _minutesToOffset(block.startMinutes.toDouble());
    double bottom = _minutesToOffset(block.endMinutes.toDouble());

    return Positioned(
      top: top,
      left: block.column * columnWidth,
      width: columnWidth,
      height: math.max(bottom - top, 0),
      child: Padding(padding: EdgeInsets.all(1), child:
        InkWell(onTap: () => _onTapCourse(block.course), child:
          Container(
            width: double.infinity,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _courseColors[block.course.shortName] ?? Styles().colors.background,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Visibility(visible: (block.course.section?.isOnline == true), child:
                Padding(padding: EdgeInsets.only(right: 4), child:
                  Styles().images.getImage('laptop', excludeFromSemantics: true, size: 12),
                ),
              ),
              Expanded(child: _buildCourseBlockText(block)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseBlockText(StudentCourseBlock block) {
    String timeRange = StudentCoursesCalendarLayout.displayTimeRange(startMinutes: block.startMinutes, durationMinutes: block.durationMinutes);
    String courseName = block.course.shortName ?? (block.course.title ?? '');
    String title = (block.potLabel != null) ? '${block.potLabel}: $courseName' : courseName;
    return RichText(maxLines: 1, overflow: TextOverflow.ellipsis, text: TextSpan(children: <TextSpan>[
      TextSpan(text: title, style: Styles().textStyles.getTextStyle('widget.message.tiny.fat')),
      TextSpan(text: ' | $timeRange', style: Styles().textStyles.getTextStyle('widget.message.tiny')),
    ]));
  }

  void _onTapCourse(StudentCourse course) {
    Analytics().logSelect(target: "Student Course: ${course.title}");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentCourseDetailPanel(course: course)));
  }
}
