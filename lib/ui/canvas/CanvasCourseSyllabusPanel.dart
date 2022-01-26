import 'package:flutter/material.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/canvas/CanvasWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';

class CanvasCourseSyllabusPanel extends StatefulWidget {
  final int? courseId;
  CanvasCourseSyllabusPanel({this.courseId});

  @override
  _CanvasCourseSyllabusPanelState createState() => _CanvasCourseSyllabusPanelState();
}

class _CanvasCourseSyllabusPanelState extends State<CanvasCourseSyllabusPanel> {
  CanvasCourse? _course;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
          context: context,
          titleWidget: Text(Localization().getStringEx('panel.syllabus_canvas_course.header.title', 'Syllabus')!,
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
    if (_isLoading) {
      return _buildLoadingContent();
    }
    if (_course != null) {
      return _buildCourseContent();
    } else {
      return _buildErrorContent();
    }
  }

  Widget _buildLoadingContent() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorContent() {
    return Center(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 28), child: Text(Localization().getStringEx('panel.syllabus_canvas_course.load.failed.error.msg', 'Failed to load course. Please, try again later.')!,
            textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18))));
  }

  Widget _buildCourseContent() {
    return SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [CanvasCourseCard(course: _course!), _buildButtonsContent()]));
  }

  Widget _buildButtonsContent() {
    return Column(children: [
      _buildDelimiter(),
      RibbonButton(
          label: Localization().getStringEx('panel.syllabus_canvas_course.button.syllabus.title', 'Syllabus'),
          hint: Localization().getStringEx('panel.syllabus_canvas_course.button.syllabus.hint', ''),
          leftIcon: 'images/icon-settings.png'),
      _buildDelimiter(),
      RibbonButton(
          label: Localization().getStringEx('panel.syllabus_canvas_course.button.modules.title', 'Modules'),
          hint: Localization().getStringEx('panel.syllabus_canvas_course.button.modules.hint', ''),
          leftIcon: 'images/icon-settings.png'),
      _buildDelimiter(),
      RibbonButton(
          label: Localization().getStringEx('panel.syllabus_canvas_course.button.assignments.title', 'Assignments'),
          hint: Localization().getStringEx('panel.syllabus_canvas_course.button.assignments.hint', ''),
          leftIcon: 'images/icon-settings.png'),
      _buildDelimiter(),
      RibbonButton(
          label: Localization().getStringEx('panel.syllabus_canvas_course.button.zoom.title', 'Zoom Meeting'),
          hint: Localization().getStringEx('panel.syllabus_canvas_course.button.zoom.hint', ''),
          leftIcon: 'images/icon-settings.png'),
      _buildDelimiter(),
      RibbonButton(
          label: Localization().getStringEx('panel.syllabus_canvas_course.button.grades.title', 'Grades'),
          hint: Localization().getStringEx('panel.syllabus_canvas_course.button.grades.hint', ''),
          leftIcon: 'images/icon-settings.png'),
      _buildDelimiter()
    ]);
  }

  Widget _buildDelimiter() {
    return Container(height: 1, color: Styles().colors!.surfaceAccent);
  }

  void _loadCourse() {
    _increaseProgress();
    Canvas().loadCourse(widget.courseId).then((course) {
      _course = course;
      _decreaseProgress();
    });
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
}
