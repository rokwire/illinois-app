import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/ui/canvas/CanvasCoursesContentWidget.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class CanvasCoursesListPanel extends StatelessWidget with AnalyticsInfo {
  CanvasCoursesListPanel();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.AcademicsCanvasCourses;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: Localization().getStringEx('panel.canvas_courses.header.title', 'My Canvas Courses')),
        body: _scaffoldContent,
        backgroundColor: Styles().colors.surface,
        bottomNavigationBar: uiuc.TabBar());
  }

  Widget get _scaffoldContent =>
    SingleChildScrollView(child:
      Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
        CanvasCoursesContentWidget()
      )
    );
}