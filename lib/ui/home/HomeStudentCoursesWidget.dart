import 'dart:async';

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

  Widget _buildCalendarContent() => _HomeStudentCoursesCalendarContentWidget(
    courses: _courses,
    weekday: DateTimeUni.nowUniOrLocal().weekday,
  );

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
// _HomeStudentCoursesCalendarContentWidget

class _HomeStudentCoursesCalendarContentWidget extends StatefulWidget {
  final List<StudentCourse>? courses;
  final int weekday;

  _HomeStudentCoursesCalendarContentWidget({this.courses, required this.weekday});

  @override
  State<StatefulWidget> createState() => _HomeStudentCoursesCalendarContentWidgetState();
}

class _HomeStudentCoursesCalendarContentWidgetState extends State<_HomeStudentCoursesCalendarContentWidget> {

  static const double _hourHeight = 40;
  static const double _timeColumnWidth = 64;
  static const int _startHour = 8;
  static const int _endHour = 16; // 4 PM

  static const double _hourLabelRightMargin = 24;
  static const double _hourLineLength = 20;
  static const double _hourLineRightOvershoot = 4;
  static const double _closingRowHeight = 20;

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
    return SizedBox(
      height: (visibleHourCount * _hourHeight) + _closingRowHeight,
      child: Stack(clipBehavior: Clip.hardEdge, children: <Widget>[
        Positioned(top: 0, left: 0, right: 0, height: visibleHourCount * _hourHeight, child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            _buildTimeColumn(),
            Expanded(child: _buildDayColumn()),
          ]),
        ),
        Positioned(top: visibleHourCount * _hourHeight, left: 0, right: 0, child: _buildClosingHourRow()),
      ]),
    );
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
    return SizedBox(width: _timeColumnWidth, height: visibleHourCount * _hourHeight, child:
      Stack(clipBehavior: Clip.none, children: <Widget>[
        ...List<Widget>.generate(visibleHourCount, (int index) =>
          Positioned(top: index * _hourHeight, right: -_hourLineRightOvershoot, width: _hourLineLength, child:
            Container(height: 1, color: Styles().colors.surfaceAccent),
          )
        ),
        ...List<Widget>.generate(visibleHourCount, (int index) =>
          Positioned(top: (index * _hourHeight) - 7, left: 0, right: _hourLabelRightMargin, child:
            Text(StudentCoursesCalendarLayout.hourLabel(_startHour + index), textAlign: TextAlign.right, style: Styles().textStyles.getTextStyle('widget.message.tiny')),
          )
        ),
      ]),
    );
  }

  Widget _buildClosingHourRow() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      SizedBox(width: _timeColumnWidth, height: _closingRowHeight, child:
        Stack(clipBehavior: Clip.none, children: <Widget>[
          Positioned(top: 0, right: -_hourLineRightOvershoot, width: _hourLineLength, child:
            Container(height: 1, color: Styles().colors.surfaceAccent),
          ),
          Positioned(top: -7, left: 0, right: _hourLabelRightMargin, child:
            Text(StudentCoursesCalendarLayout.hourLabel(_endHour), textAlign: TextAlign.right, style: Styles().textStyles.getTextStyle('widget.message.tiny')),
          ),
        ]),
      ),
      Expanded(child: Container(height: 1, color: Styles().colors.surfaceAccent)),
    ]);
  }

  Widget _buildDayColumn() {
    return Container(
      decoration: BoxDecoration(border: Border(left: BorderSide(color: Styles().colors.surfaceAccent, width: 1))),
      child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) =>
        Stack(children: <Widget>[
          _buildHourLines(),
          ..._blocks.map((StudentCourseBlock block) => _buildCourseBlock(block, dayWidth: constraints.maxWidth)),
        ]),
      ),
    );
  }

  Widget _buildHourLines() {
    int visibleHourCount = _endHour - _startHour;
    return Column(children: List<Widget>.generate(visibleHourCount, (_) =>
      Container(height: _hourHeight, decoration: BoxDecoration(border: Border(top: BorderSide(color: Styles().colors.surfaceAccent, width: 1))))
    ));
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
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: _courseColors[block.course.shortName] ?? Styles().colors.background,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(block.course.shortName ?? (block.course.title ?? ''),
              maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
              style: Styles().textStyles.getTextStyle('widget.message.tiny.fat'),
            ),
          ),
        ),
      ),
    );
  }

  void _onTapCourse(StudentCourse course) {
    Analytics().logSelect(target: "Student Course: ${course.title}");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentCourseDetailPanel(course: course)));
  }
}
