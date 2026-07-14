import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/StudentCourse.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Analytics.dart';
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
import 'package:rokwire_plugin/service/app_datetime.dart';
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

  @override
  void initState() {

    _viewType = StudentCoursesViewTypeExt.fromJson(Storage().getHomeFavoriteSelectedContent(widget.favoriteId)) ?? StudentCoursesViewType.list;

    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Auth2.notifyLoginChanged,
      Connectivity.notifyStatusChanged,
      StudentCourses.notifyTermsChanged,
      StudentCourses.notifySelectedTermChanged,
      StudentCourses.notifyCachedCoursesChanged,
    ]);


    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _updateCourses(forceLoad: true);
        }
      });
    }

    _loadCourses();
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
      setStateIfMounted(() {});
    }
    else if (name == StudentCourses.notifySelectedTermChanged) {
      _updateCourses();
    }
    else if (name == StudentCourses.notifyCachedCoursesChanged) {
      if ((param == null) || (StudentCourses().displayTermId == param)) {
        _updateCourses();
      }
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
    actions: [ _buildTermsDropDown(), ],
    child: _buildContent(),
  );

  TextStyle? getTermDropDownItemStyle({bool selected = false}) => selected ? Styles().textStyles.getTextStyle("widget.button.title.small.fat") : Styles().textStyles.getTextStyle("widget.button.title.small");

  Widget _buildTermsDropDown() {
    StudentCourseTerm? currentTerm = StudentCourses().displayTerm;

    return Semantics(label: currentTerm?.name, hint: "Double tap to select account", button: true, container: true, child:
      DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Padding(padding: EdgeInsets.only(left: 4), child: Styles().images.getImage('chevron-down', excludeFromSemantics: true)),
          isExpanded: false,
          isDense: true,
          style: getTermDropDownItemStyle(selected: false),
          hint: (currentTerm?.name?.isNotEmpty ?? false) ? Text(currentTerm?.name ?? '', style: Styles().textStyles.getTextStyle("widget.title.small.semi_fat")) : null,
          alignment: AlignmentDirectional.centerEnd,
          items: _buildTermDropDownItems(),
          onChanged: _onTermDropDownValueChanged
        ),
      ),
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
          child: Text(term.name ?? '', style: getTermDropDownItemStyle(selected: term.id == currentTermId),)
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
        (_viewType == StudentCoursesViewType.calendar) ? _buildCalendarContent() : _buildCoursesContent(),
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
      });
    }
  }

  Widget _buildCalendarContent() {
    int todayIndex = StudentCoursesCalendarLayout.weekdayOrder.indexOf(DateTimeUni.nowUniOrLocal().weekday);
    int initialPageIndex = _calendarPageIndex ?? ((0 <= todayIndex) ? todayIndex : 0);

    return _HomeStudentCoursesCalendarPager(
      courses: _courses,
      initialPageIndex: initialPageIndex,
      onPageIndexChanged: (int index) => _calendarPageIndex = index,
      onViewAll: _onViewAll,
    );
  }

  Widget _buildCoursesContent() {

    Widget contentWidget;
    int visibleCount = _courses?.length ?? 0; // Config().homeCampusHighlightsCount

    if (1 < visibleCount) {
      List<Widget> coursePages = <Widget>[];
      for (StudentCourse course in _courses!) {
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
    else {
      contentWidget = Padding(padding: HomeCard.defaultSingleCardMargin, child:
        StudentCourseCard(course: _courses!.first, displayMode: CardDisplayMode.home),
      );
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
      if (mounted && showProgress) {
        setState(() {
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
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentCoursesHomePanel()));
  }
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

class _HomeStudentCoursesCalendarContentWidgetState extends State<_HomeStudentCoursesCalendarContentWidget> {

  static const double _minHourHeight = 24; // floor so hour rows never become unreadably small
  static const int _startHour = 8;
  static const int _endHour = 16; // 4 PM

  static const double _cardPadding = 16;
  static const double _headerHeight = 32;
  static const double _gridTopPadding = 8;
  static const double _timeColumnGap = 8; // space between the hour labels and the day column
  static const double _closingRowHeight = 16;

  double _hourHeight = _minHourHeight;

  late final List<Color> _coursePalette;
  Map<String, Color> _courseColors = <String, Color>{};
  List<StudentCourseBlock> _blocks = <StudentCourseBlock>[];

  @override
  void initState() {
    super.initState();
    _coursePalette = StudentCoursesCalendarLayout.defaultPalette;
    _updateCourseColors();
    _updateBlocks();
  }

  @override
  void didUpdateWidget(_HomeStudentCoursesCalendarContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateCourseColors();
    _updateBlocks();
  }

  @override
  Widget build(BuildContext context) {
    int visibleHourCount = _endHour - _startHour;
    double targetCardHeight = StudentCourseCard.height(context);
    double chromeHeight = _headerHeight + _gridTopPadding + _cardPadding + _closingRowHeight;
    _hourHeight = math.max((targetCardHeight - chromeHeight) / visibleHourCount, _minHourHeight);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: HomeCard.boxDecoration,
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        _buildHeader(),
        Padding(padding: EdgeInsets.fromLTRB(_cardPadding, _gridTopPadding, _cardPadding, _cardPadding), child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            _buildTimeColumn(),
            SizedBox(width: _timeColumnGap),
            Expanded(child: SizedBox(height: visibleHourCount * _hourHeight, child: _buildDayColumn())),
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

  String get _dayLabel {
    bool isToday = (widget.weekday == DateTimeUni.nowUniOrLocal().weekday);
    return isToday ?
      Localization().getStringEx('widget.home.student_courses.calendar.day.today.label', 'TODAY') :
      _weekdayName(widget.weekday);
  }

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
        StudentCourseBlock block = StudentCourseBlock(course: course, startMinutes: startMinutes, durationMinutes: StudentCoursesCalendarLayout.fixedDurationMinutes);
        if ((block.startMinutes < (_endHour * 60)) && (block.endMinutes > (_startHour * 60))) {
          blocks.add(block);
        }
      }
    }
    StudentCoursesCalendarLayout.layoutOverlappingBlocks(blocks);
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

  Widget _buildCourseBlock(StudentCourseBlock block, {required double dayWidth}) {
    double columnWidth = dayWidth / block.columnCount;
    double windowStartMinutes = (_startHour * 60).toDouble();
    return Positioned(
      top: ((block.startMinutes - windowStartMinutes) / 60.0) * _hourHeight,
      left: block.column * columnWidth,
      width: columnWidth,
      height: (block.durationMinutes / 60.0) * _hourHeight,
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
            child: _buildCourseBlockText(block),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseBlockText(StudentCourseBlock block) {
    String timeRange = StudentCoursesCalendarLayout.displayTimeRange(block.startMinutes);
    return RichText(maxLines: 1, overflow: TextOverflow.ellipsis, text: TextSpan(children: <TextSpan>[
      TextSpan(text: block.course.shortName ?? (block.course.title ?? ''), style: Styles().textStyles.getTextStyle('widget.message.tiny.fat')),
      TextSpan(text: ' | $timeRange', style: Styles().textStyles.getTextStyle('widget.message.tiny')),
    ]));
  }

  void _onTapCourse(StudentCourse course) {
    Analytics().logSelect(target: "Student Course: ${course.title}");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentCourseDetailPanel(course: course)));
  }
}
