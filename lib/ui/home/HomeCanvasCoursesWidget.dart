import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/canvas/CanvasCourseHomePanel.dart';
import 'package:illinois/ui/canvas/CanvasWidgets.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeCanvasCoursesWidget extends StatefulWidget {
  final StreamController<void>? refreshController;

  HomeCanvasCoursesWidget({this.refreshController});

  @override
  _HomeCanvasCoursesWidgetState createState() => _HomeCanvasCoursesWidgetState();
}

class _HomeCanvasCoursesWidgetState extends State<HomeCanvasCoursesWidget> implements NotificationsListener {

  List<CanvasCourse>? _courses;

  @override
  void initState() {
    super.initState();

    //TBD_DD: Refresh courses on awake from background (like HomeTwitterWidget does).
    // Why do we need to listen for FlexUI.notifyChanged since HomeCanvasCoursesWidget does not depend on it?
    // Search for Canvas().loadCourses() and think of caching courses content. Examples: Config, GeoFence, Groups

    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
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
    if (name == FlexUI.notifyChanged) {
      _loadCourses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
        visible: _hasCourses,
        child: Container(
            child: Column(children: [
          _buildHeader(),
          Stack(children: <Widget>[
            _buildSlant(),
            _buildCoursesContent(),
          ])
        ])));
  }

  Widget _buildHeader() {
    return Semantics(
        container: true,
        header: true,
        child: Container(
            color: Styles().colors!.fillColorPrimary,
            child: Padding(
                padding: EdgeInsets.only(left: 20, top: 10, bottom: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Image.asset(
                        'images/campus-tools.png',
                        excludeFromSemantics: true,
                      )),
                  Expanded(
                      child: Text(Localization().getStringEx('widget.home_canvas_courses.header.label', 'Courses'),
                          style: TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20)))
                ]))));
  }

  Widget _buildSlant() {
    return Column(children: <Widget>[
      Container(color: Styles().colors!.fillColorPrimary, height: 45),
      Container(
          color: Styles().colors!.fillColorPrimary,
          child: CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.background, horzDir: TriangleHorzDirection.rightToLeft), child: Container(height: 65)))
    ]);
  }

  Widget _buildCoursesContent() {
    List<Widget> courseWidgets = <Widget>[];
    if (CollectionUtils.isNotEmpty(_courses)) {
      for (CanvasCourse course in _courses!) {
        courseWidgets.add(_buildCourseCard(course));
      }
    }

    return Center(child: Padding(
        padding: EdgeInsets.only(top: 10, bottom: 20),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Padding(padding: EdgeInsets.only(right: 10, bottom: 6), child: Row(children: courseWidgets)))),);
  }

  Widget _buildCourseCard(CanvasCourse course) {
    return Padding(padding: EdgeInsets.only(left: 10), child: GestureDetector(onTap: () => _onTapCourse(course), child: CanvasCourseCard(course: course, isSmall: true)));
  }

  void _loadCourses() {
    Canvas().loadCourses().then((courses) {
      _courses = courses;
      if (mounted) {
        setState(() {});
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
