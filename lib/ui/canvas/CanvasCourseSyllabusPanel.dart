/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
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
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/canvas/CanvasCourseModulesPanel.dart';
import 'package:illinois/ui/canvas/CanvasSyllabusHtmlPanel.dart';
import 'package:illinois/ui/canvas/CanvasWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

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
          leftIcon: 'images/icon-canvas-implemented-working.png',
          onTap: _onTapSyllabus),
      _buildDelimiter(),
      RibbonButton(
          label: Localization().getStringEx('panel.syllabus_canvas_course.button.modules.title', 'Modules'),
          hint: Localization().getStringEx('panel.syllabus_canvas_course.button.modules.hint', ''),
          leftIcon: 'images/icon-canvas-implemented-working.png',
          onTap: _onTapModules),
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

  void _onTapSyllabus() {
    Analytics().logSelect(target: 'Syllabus -> Syllabus');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasSyllabusHtmlPanel(courseId: widget.courseId!)));
  }

  void _onTapModules() {
    Analytics().logSelect(target: 'Syllabus -> Modules');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCourseModulesPanel(courseId: widget.courseId!)));
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
