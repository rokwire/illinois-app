import 'package:flutter/material.dart';
import 'package:neom/ui/canvas/CanvasCoursesContentWidget.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:neom/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class CanvasCoursesListPanel extends StatefulWidget {
  CanvasCoursesListPanel();

  @override
  _CanvasCoursesListPanelState createState() => _CanvasCoursesListPanelState();
}

class _CanvasCoursesListPanelState extends State<CanvasCoursesListPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: Localization().getStringEx('panel.canvas_courses.header.title', 'My Canvas Courses')),
        body: SingleChildScrollView(
            child: Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child: CanvasCoursesContentWidget())),
        backgroundColor: Styles().colors.surface,
        bottomNavigationBar: uiuc.TabBar());
  }
}