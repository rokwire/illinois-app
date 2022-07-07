import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:illinois/main.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/academics/AcademicsHomePanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/canvas/CanvasCourseHomePanel.dart';
import 'package:illinois/ui/canvas/CanvasWidgets.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeCanvasCoursesWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeCanvasCoursesWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home_canvas_courses.header.label', 'Courses');
  
  @override
  _HomeCanvasCoursesWidgetState createState() => _HomeCanvasCoursesWidgetState();
}

class _HomeCanvasCoursesWidgetState extends State<HomeCanvasCoursesWidget> implements NotificationsListener {

  List<CanvasCourse>? _courses;
  PageController? _pageController;
  DateTime? _pausedDateTime;
  final double _pageSpacing = 16;

  @override
  void initState() {
    super.initState();

    // TBD: Search for Canvas().loadCourses() and think of caching courses content. Examples: Config, GeoFence, Groups

    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
    ]);


    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _loadCourses();
        }
      });
    }

    double screenWidth = MediaQuery.of(App.instance?.currentContext ?? context).size.width;
    double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
    _pageController = PageController(viewportFraction: pageViewport);

    _loadCourses();
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
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _loadCourses();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: Localization().getStringEx('widget.home_canvas_courses.header.label', 'Courses'),
      titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
      childPadding: EdgeInsets.zero,
      child: _hasCourses ? _buildCoursesContent() : _buildEmptyContent(),
    );
  }

  Widget _buildCoursesContent() {

    List<Widget> coursePages = <Widget>[];
    if (CollectionUtils.isNotEmpty(_courses)) {
      for (CanvasCourse course in _courses!) {
        coursePages.add(Padding(padding: EdgeInsets.only(right: _pageSpacing), child:
          GestureDetector(onTap: () => _onTapCourse(course), child:
            CanvasCourseCard(course: course, isSmall: true)
          ),
        ),);
      }
    }

    double pageHeight = CanvasCourseCard.height(context, isSmall: true);

    return Column(children: [
      Container(height: pageHeight, child:
        PageView(controller: _pageController, children: coursePages,)
      ),
      LinkButton(
        title: Localization().getStringEx('widget.home.home_canvas_courses.button.all.title', 'View All'),
        hint: Localization().getStringEx('widget.home.home_canvas_courses.button.all.hint', 'Tap to view all courses'),
        onTap: _onViewAll,
      ),
    ],);
  }

  Widget _buildEmptyContent() {
    return HomeMessageCard(
      title: Localization().getStringEx('widget.home.home_canvas_courses.text.empty', 'Whoops! Nothing to see here.'),
      message: Localization().getStringEx('widget.home.home_canvas_courses.text.empty.description', 'You do not enroll in any courses.'),
    );
  }

  void _loadCourses() {
    Canvas().loadCourses().then((courses) {
      if (mounted) {
        setState(() {
          _courses = courses;
        });
      }
    });
  }

  void _onTapCourse(CanvasCourse course) {
    Analytics().logSelect(target: "Home Canvas Course");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCourseHomePanel(courseId: course.id)));
  }

  void _onViewAll() {
    Analytics().logSelect(target: "Home Canvas Courses View All");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AcademicsHomePanel(content: AcademicsContent.courses,)));
  }


  bool get _hasCourses {
    return CollectionUtils.isNotEmpty(_courses);
  }
}
