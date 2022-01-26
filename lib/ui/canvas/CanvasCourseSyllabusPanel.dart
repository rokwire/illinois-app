import 'package:flutter/material.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/canvas/CanvasWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';

class CanvasCourseSyllabusPanel extends StatefulWidget {
  final CanvasCourse course;
  CanvasCourseSyllabusPanel({required this.course});

  @override
  _CanvasCourseSyllabusPanelState createState() => _CanvasCourseSyllabusPanelState();
}

class _CanvasCourseSyllabusPanelState extends State<CanvasCourseSyllabusPanel> {
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
      body: Column(children: <Widget>[
        Expanded(
            child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: _buildSyllabusContent()
            )
        )
      ]),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildSyllabusContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CanvasCourseCard(course: widget.course),
      _buildButtonsContent()
    ]);
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
}
