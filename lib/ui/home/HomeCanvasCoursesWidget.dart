import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/canvas/CanvasCourseHomePanel.dart';
import 'package:illinois/ui/canvas/CanvasWidgets.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeCanvasCoursesWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<void>? refreshController;
  final HomeScrollableDragging? scrollableDragging;

  HomeCanvasCoursesWidget({Key? key, this.favoriteId, this.refreshController, this.scrollableDragging}) : super(key: key);

  @override
  _HomeCanvasCoursesWidgetState createState() => _HomeCanvasCoursesWidgetState();
}

class _HomeCanvasCoursesWidgetState extends State<HomeCanvasCoursesWidget> implements NotificationsListener {

  List<CanvasCourse>? _courses;
  DateTime? _pausedDateTime;

  @override
  void initState() {
    super.initState();

    // TBD: Search for Canvas().loadCourses() and think of caching courses content. Examples: Config, GeoFence, Groups

    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
    ]);


    if (widget.refreshController != null) {
      widget.refreshController!.stream.listen((_) {
        _loadCourses();
      });
    }

    _loadCourses();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
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

    return Visibility(visible: _hasCourses, child:
      HomeDropTargetWidget(favoriteId: widget.favoriteId, child:
        HomeSlantWidget(favoriteId: widget.favoriteId, scrollableDragging: widget.scrollableDragging,
          title: Localization().getStringEx('widget.home_canvas_courses.header.label', 'Courses'),
          child: _buildCoursesContent(),
          childPadding: const EdgeInsets.only(top: 8, bottom: 16),
        ),
      ),
    );
  }

  Widget _buildCoursesContent() {
    List<Widget> courseWidgets = <Widget>[];
    if (CollectionUtils.isNotEmpty(_courses)) {
      for (CanvasCourse course in _courses!) {
        courseWidgets.add(_buildCourseCard(course));
      }
    }

    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Padding(padding: EdgeInsets.only(right: 10, bottom: 6), child: Row(children: courseWidgets)));
  }

  Widget _buildCourseCard(CanvasCourse course) {
    return Padding(padding: EdgeInsets.only(left: 10), child: GestureDetector(onTap: () => _onTapCourse(course), child: CanvasCourseCard(course: course, isSmall: true)));
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

  bool get _hasCourses {
    return CollectionUtils.isNotEmpty(_courses);
  }
}
