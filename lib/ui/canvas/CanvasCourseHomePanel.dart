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
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/canvas/CanvasAccountNotificationsPanel.dart';
import 'package:illinois/ui/canvas/CanvasCourseAnnouncementsPanel.dart';
import 'package:illinois/ui/canvas/CanvasCourseAssignmentsPanel.dart';
import 'package:illinois/ui/canvas/CanvasCourseCalendarPanel.dart';
import 'package:illinois/ui/canvas/CanvasCourseCollaborationsPanel.dart';
import 'package:illinois/ui/canvas/CanvasCourseModulesPanel.dart';
import 'package:illinois/ui/canvas/CanvasFeedbackPanel.dart';
import 'package:illinois/ui/canvas/CanvasFileSystemEntitiesListPanel.dart';
import 'package:illinois/ui/canvas/CanvasSyllabusHtmlPanel.dart';
import 'package:illinois/ui/canvas/CanvasWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class CanvasCourseHomePanel extends StatefulWidget {
  final int? courseId;
  CanvasCourseHomePanel({this.courseId});

  @override
  _CanvasCourseHomePanelState createState() => _CanvasCourseHomePanelState();
}

class _CanvasCourseHomePanelState extends State<CanvasCourseHomePanel> {
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
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.home_canvas_course.header.title', 'Course'),
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: uiuc.TabBar(),
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
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 28), child: Text(Localization().getStringEx('panel.home_canvas_course.load.failed.error.msg', 'Failed to load course. Please, try again later.'),
            textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildCourseContent() {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [CanvasCourseCard(course: _course!), _buildButtonsContent()]));
  }

  Widget _buildButtonsContent() {
    return Column(children: [
      _buildDelimiter(),
      RibbonButton(
          label: Localization().getStringEx('panel.home_canvas_course.button.assignments.title', 'Assignments'),
          hint: Localization().getStringEx('panel.home_canvas_course.button.assignments.hint', ''),
          leftIconKey: 'settings-working',
          onTap: _onTapAssignments),
      _buildDelimiter(),
      RibbonButton(
          label: Localization().getStringEx('panel.home_canvas_course.button.launch.title', 'Launch Canvas'),
          hint: Localization().getStringEx('panel.home_canvas_course.button.launch.hint', ''),
          leftIconKey: 'settings-working',
          onTap: _onTapLaunch),
      _buildDelimiter(),
      // Show only when the flag is set to true
      Visibility(
          visible: (Storage().debugUseCanvasLms == true),
          child: Column(children: [
            RibbonButton(
                label: Localization().getStringEx('panel.home_canvas_course.button.syllabus.title', 'Syllabus'),
                hint: Localization().getStringEx('panel.home_canvas_course.button.syllabus.hint', ''),
                leftIconKey: 'settings-working',
                onTap: _onTapSyllabus),
            _buildDelimiter(),
            RibbonButton(
                label: Localization().getStringEx('panel.home_canvas_course.button.announcements.title', 'Announcements'),
                hint: Localization().getStringEx('panel.home_canvas_course.button.announcements.hint', ''),
                leftIconKey: 'settings-working',
                onTap: _onTapAnnouncements),
            _buildDelimiter(),
            RibbonButton(
                label: Localization().getStringEx('panel.home_canvas_course.button.files.title', 'Files'),
                hint: Localization().getStringEx('panel.home_canvas_course.button.files.hint', ''),
                leftIconKey: 'settings-working',
                onTap: _onTapFiles),
            _buildDelimiter(),
            RibbonButton(
                label: Localization().getStringEx('panel.home_canvas_course.button.collaborations.title', 'Collaborations'),
                hint: Localization().getStringEx('panel.home_canvas_course.button.collaborations.hint', ''),
                leftIconKey: 'settings-working',
                onTap: _onTapCollaborations),
            _buildDelimiter(),
            RibbonButton(
                label: Localization().getStringEx('panel.home_canvas_course.button.calendar.title', 'Calendar'),
                hint: Localization().getStringEx('panel.home_canvas_course.button.calendar.hint', ''),
                leftIconKey: 'settings-working',
                onTap: _onTapCalendar),
            _buildDelimiter(),
            RibbonButton(
                label: Localization().getStringEx('panel.home_canvas_course.button.notifications.title', 'Notifications'),
                hint: Localization().getStringEx('panel.home_canvas_course.button.notifications.hint', ''),
                leftIconKey: 'settings-working',
                onTap: _onTapNotifications),
            _buildDelimiter(),
            RibbonButton(
                label: Localization().getStringEx('panel.home_canvas_course.button.modules.title', 'Modules'),
                hint: Localization().getStringEx('panel.home_canvas_course.button.modules.hint', ''),
                leftIconKey: 'settings-working',
                onTap: _onTapModules),
            _buildDelimiter(),
            RibbonButton(
                label: Localization().getStringEx('panel.home_canvas_course.button.feedback.title', 'Feedback'),
                hint: Localization().getStringEx('panel.home_canvas_course.button.feedback.hint', ''),
                leftIconKey: 'settings-working',
                onTap: _onTapFeedback),
            _buildDelimiter()
          ]))
    ]);
  }

  Widget _buildDelimiter() {
    return Container(height: 1, color: Styles().colors!.surfaceAccent);
  }

  void _onTapLaunch() async {
    Analytics().logSelect(target: 'Canvas Course -> Launch Canvas');
    String? courseDeepLinkFormat = Config().canvasCourseDeepLinkFormat;
    String? courseDeepLink = StringUtils.isNotEmpty(courseDeepLinkFormat) ? sprintf(courseDeepLinkFormat!, [_course!.id]) : null;
    if (StringUtils.isNotEmpty(courseDeepLink)) {
      await Canvas().openCanvasAppDeepLink(courseDeepLink!);
    }
  }

  void _onTapAssignments() {
    Analytics().logSelect(target: 'Canvas Course -> Assignments');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCourseAssignmentsPanel(courseId: widget.courseId!)));
  }

  void _onTapSyllabus() {
    Analytics().logSelect(target: 'Canvas Course -> Syllabus');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasSyllabusHtmlPanel(courseId: widget.courseId!)));
  }

  void _onTapAnnouncements() {
    Analytics().logSelect(target: 'Canvas Course -> Announcements');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCourseAnnouncementsPanel(courseId: widget.courseId!)));
  }

  void _onTapFiles() {
    Analytics().logSelect(target: 'Canvas Course -> Files');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasFileSystemEntitiesListPanel(courseId: widget.courseId)));
  }

  void _onTapCollaborations() {
    Analytics().logSelect(target: 'Canvas Course -> Collaborations');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCourseCollaborationsPanel(courseId: widget.courseId!)));
  }

  void _onTapCalendar() {
    Analytics().logSelect(target: 'Canvas Course -> Calendar');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCourseCalendarPanel(courseId: widget.courseId!)));
  }

  void _onTapNotifications() {
    Analytics().logSelect(target: 'Canvas Course -> Notifications');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasAccountNotificationsPanel()));
  }

  void _onTapModules() {
    Analytics().logSelect(target: 'Canvas Course -> Modules');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCourseModulesPanel(courseId: widget.courseId!)));
  }

  void _onTapFeedback() {
    Analytics().logSelect(target: 'Canvas Course -> Feedback');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasFeedbackPanel()));
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
