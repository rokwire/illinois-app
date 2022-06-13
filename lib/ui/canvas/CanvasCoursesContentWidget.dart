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
import 'package:illinois/ui/canvas/CanvasCourseHomePanel.dart';
import 'package:illinois/ui/canvas/CanvasWidgets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CanvasCoursesContentWidget extends StatefulWidget {
  CanvasCoursesContentWidget();

  @override
  _CanvasCoursesContentWidgetState createState() => _CanvasCoursesContentWidgetState();
}

class _CanvasCoursesContentWidgetState extends State<CanvasCoursesContentWidget> {
  List<CanvasCourse>? _courses;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    if (_loading) {
      return _buildLoadingContent();
    }
    if (_courses != null) {
      return _buildCoursesContent();
    } else {
      return _buildErrorContent();
    }
  }

  Widget _buildLoadingContent() {
    return _buildCenterWidget(widget: CircularProgressIndicator());
  }

  Widget _buildErrorContent() {
    return _buildCenterWidget(widget: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28),
        child: Text(
            Localization().getStringEx('panel.canvas_courses.load.failed.error.msg', 'Failed to load courses. Please, try again later.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18))));
  }

  Widget _buildCoursesContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: _buildCoursesWidgetList());
  }

  List<Widget> _buildCoursesWidgetList() {
    List<Widget> widgets = <Widget>[];
    if (CollectionUtils.isNotEmpty(_courses)) {
      for (CanvasCourse course in _courses!) {
        widgets.add(Padding(
            padding: EdgeInsets.only(top: 10),
            child: GestureDetector(onTap: () => _onTapCourse(course.id!), child: CanvasCourseCard(course: course))));
      }
    }
    return widgets;
  }

  Widget _buildCenterWidget({required Widget widget}) {
    return Center(
        child: Column(children: <Widget>[
      Container(height: MediaQuery.of(context).size.height / 5),
      widget,
      Container(height: MediaQuery.of(context).size.height / 5 * 3)
    ]));
  }

  void _onTapCourse(int courseId) {
    Analytics().logSelect(target: 'Canvas Course');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCourseHomePanel(courseId: courseId)));
  }

  void _loadCourses() {
    _setLoading(true);
    Canvas().loadCourses().then((courses) {
      _courses = courses;
      _setLoading(false);
    });
  }

  void _setLoading(bool loading) {
    _loading = loading;
    if (mounted) {
      setState(() {});
    }
  }
}
