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
import 'package:illinois/ui/canvas/CanvasCourseAssignmentsPanel.dart';
import 'package:illinois/ui/canvas/CanvasWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/rokwire_plugin.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

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
            textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18))));
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
          leftIconAsset: 'images/icon-canvas-implemented-working.png',
          onTap: _onTapAssignments),
      _buildDelimiter(),
      RibbonButton(
          label: Localization().getStringEx('panel.home_canvas_course.button.launch.title', 'Launch Canvas'),
          hint: Localization().getStringEx('panel.home_canvas_course.button.launch.hint', ''),
          leftIconAsset: 'images/icon-canvas-implemented-working.png',
          onTap: _onTapLaunch),
      _buildDelimiter()
    ]);
  }

  Widget _buildDelimiter() {
    return Container(height: 1, color: Styles().colors!.surfaceAccent);
  }

  void _onTapLaunch() async {
    Analytics().logSelect(target: 'Canvas Course -> Launch Canvas');
    String? courseDeepLinkFormat = Config().canvasCourseDeepLinkFormat;
    String? courseDeepLink = StringUtils.isNotEmpty(courseDeepLinkFormat) ? sprintf(courseDeepLinkFormat!, [_course!.id]) : null;
    bool? appLaunched = await RokwirePlugin.launchApp({"deep_link": courseDeepLink});
    if (appLaunched != true) {
      String? canvasStoreUrl = Config().canvasStoreUrl;
      if ((canvasStoreUrl != null) && await url_launcher.canLaunch(canvasStoreUrl)) {
        await url_launcher.launch(canvasStoreUrl, forceSafariVC: false);
      }
    }
  }

  void _onTapAssignments() {
    Analytics().logSelect(target: 'Canvas Course -> Assignments');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCourseAssignmentsPanel(courseId: widget.courseId!)));
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
