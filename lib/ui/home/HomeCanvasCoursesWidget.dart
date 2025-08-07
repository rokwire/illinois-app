import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/canvas/CanvasCoursesListPanel.dart';
import 'package:illinois/ui/canvas/GiesCanvasCoursesListPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/canvas/CanvasCourseHomePanel.dart';
import 'package:illinois/ui/canvas/CanvasWidgets.dart';
import 'package:rokwire_plugin/service/notification_service.dart';

class HomeCanvasCoursesWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;
  final bool isGies;

  HomeCanvasCoursesWidget({Key? key, this.favoriteId, this.updateController, this.isGies = false}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position, bool? isGies}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: (isGies == true) ? giesTitle : canvasTitle,
    );

  static String get giesTitle => Localization().getStringEx('widget.home.gies_canvas_courses.header.label', 'My Gies Canvas Courses');
  static String get canvasTitle => Localization().getStringEx('widget.home.canvas_courses.header.label', 'My Canvas Courses');

  @override
  _HomeCanvasCoursesWidgetState createState() => _HomeCanvasCoursesWidgetState();
}

class _HomeCanvasCoursesWidgetState extends State<HomeCanvasCoursesWidget> with NotificationsListener {

  List<CanvasCourse>? _courses;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();

  @override
  void initState() {

    NotificationService().subscribe(this, [
      Canvas.notifyCoursesUpdated
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _updateCourses();
        }
      });
    }

    _courses = widget.isGies ? Canvas().giesCourses : Canvas().courses;
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
    if (name == Canvas.notifyCoursesUpdated) {
      _updateCourses();
    }
  }

  @override
  Widget build(BuildContext context) {

    return HomeFavoriteWidget(favoriteId: widget.favoriteId,
      title: widget.isGies ? HomeCanvasCoursesWidget.giesTitle : HomeCanvasCoursesWidget.canvasTitle,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (Connectivity().isOffline) {
      String offlineMessage = widget.isGies
          ? Localization().getStringEx('panel.gies_canvas_courses.load.offline.error.msg', 'My Gies Canvas Courses not available while offline.')
          : Localization().getStringEx('panel.canvas_courses.load.offline.error.msg', 'My Canvas Courses not available while offline.');
      return HomeMessageCard(message: offlineMessage);
    }
    else if (!Auth2().isOidcLoggedIn) {
      String signedOutMsg = widget.isGies
          ? Localization().getStringEx('generic.app.feature.canvas_courses.gies', 'My Gies Canvas Courses')
          : Localization().getStringEx('generic.app.feature.canvas_courses.uiuc', 'My Canvas Courses');
      return HomeMessageCard(message: AppTextUtils.loggedOutFeatureNA(signedOutMsg, verbose: true));
    }
    else if (_courses == null) {
      String failedMsg = Localization().getStringEx('panel.gies_canvas_courses.load.failed.error.msg', 'Unable to load courses.');
      return HomeMessageCard(message: failedMsg,);
    }
    else if (_courses?.isEmpty ?? true) {
      String emptyMsg = widget.isGies
          ? Localization().getStringEx('panel.gies_canvas_courses.load.empty.error.msg', 'You do not appear to be enrolled in any Gies Canvas courses.')
          : Localization().getStringEx('panel.canvas_courses.load.empty.error.msg', 'You do not appear to be enrolled in any Canvas courses.');
      return HomeMessageCard(message: emptyMsg);
    }
    else {
      return _buildCoursesContent();
    }
  }

  Widget _buildCoursesContent() {
    List<Widget> coursePages = <Widget>[];
    for (CanvasCourse course in _courses!) {
      coursePages.add(Padding(
        padding: HomeCard.defaultPageMargin,
        child: GestureDetector(onTap: () => _onTapCourse(course), child:
          CanvasCourseCard(course: course, small: true)
        ),
      ),);
    }

    if (_pageController == null) {
      double screenWidth = MediaQuery.of(context).size.width;
      double pageViewport = (screenWidth - 2 * HomeCard.pageSpacing) / screenWidth;
      _pageController = PageController(viewportFraction: pageViewport);
    }

    double pageHeight = CanvasCourseCard.height(context, isSmall: true) + (2 * HomeCard.shadowMargin);

    return Column(children: [
      Container(height: pageHeight, child:
        PageView(
          key: _pageViewKey,
          controller: _pageController,
          children: coursePages,
          allowImplicitScrolling: true,
        )
      ),
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => coursePages.length, centerWidget:
        HomeBrowseLinkButton(
          title: Localization().getStringEx('widget.home.gies_canvas_courses.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.gies_canvas_courses.button.all.hint', 'Tap to view all courses'),
          onTap: _onViewAll,
        ),
      ),
    ],);
  }

  void _updateCourses() {
    setStateIfMounted(() {
      _courses = widget.isGies ? Canvas().giesCourses : Canvas().courses;
      _pageViewKey = UniqueKey();
      // _pageController = null;
      if (_courses?.isNotEmpty == true) {
        _pageController?.jumpToPage(0);
      }
    });
  }

  void _onTapCourse(CanvasCourse course) {
    Analytics().logSelect(target: "Course: '${course.name}'", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCourseHomePanel(courseId: course.id)));
  }

  void _onViewAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(
        context, CupertinoPageRoute(builder: (context) => widget.isGies ? GiesCanvasCoursesListPanel() : CanvasCoursesListPanel()));
  }
}
