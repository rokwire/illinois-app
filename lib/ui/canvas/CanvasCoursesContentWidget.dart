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
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/canvas/CanvasCourseHomePanel.dart';
import 'package:illinois/ui/canvas/CanvasWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CanvasCoursesContentWidget extends StatefulWidget {
  CanvasCoursesContentWidget();

  @override
  _CanvasCoursesContentWidgetState createState() => _CanvasCoursesContentWidgetState();
}

class _CanvasCoursesContentWidgetState extends State<CanvasCoursesContentWidget> implements NotificationsListener {
  List<CanvasCourse>? _courses;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Canvas.notifyCoursesUpdated,
    ]);
    _courses = Canvas().giesCourses;
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
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
    return _buildContent();
  }

  Widget _buildContent() {
    if (Connectivity().isOffline) {
      return _buildMessageContent(Localization().getStringEx('panel.canvas_courses.load.offline.error.msg', 'My Gies Canvas Courses not available while offline.'),);
    }
    else if (!Auth2().isOidcLoggedIn) {
      return _buildMessageContent(Localization().getStringEx('panel.canvas_courses.load.logged_out.error.msg', 'You need to be logged in with your NetID to access My Gies Canvas Courses. Set your privacy level to 4 or 5 in your Profile. Then find the sign-in prompt under Settings.'),);
    }
    else if (_courses == null) {
      return _buildMessageContent(Localization().getStringEx('panel.canvas_courses.load.failed.error.msg', 'Unable to load courses.'),);
    }
    else if (_courses?.isEmpty ?? true) {
      return _buildMessageContent(Localization().getStringEx('panel.canvas_courses.load.empty.error.msg', 'You do not appear to be enrolled in any Gies Canvas courses.'),);
    }
    else {
      return _buildCoursesContent();
    }
  }

  Widget _buildMessageContent(String message) {
    return _buildCenterWidget(widget: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28),
        child: Text(
            message,
            textAlign: TextAlign.center,
            style: Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
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

  void _updateCourses() {
    setStateIfMounted(() {
      _courses = Canvas().giesCourses;
    });
  }
}
