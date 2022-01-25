import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/canvas/CanvasWidgets.dart';
import 'package:illinois/ui/inbox/InboxHomePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';

class CanvasCourseHomePanel extends StatefulWidget {
  final CanvasCourse course;
  CanvasCourseHomePanel({required this.course});

  @override
  _CanvasCourseHomePanelState createState() => _CanvasCourseHomePanelState();
}

class _CanvasCourseHomePanelState extends State<CanvasCourseHomePanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx('panel.home_canvas_course.header.title', 'Course')!,
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
            child: _buildCourseContent()
          )
        )
      ]),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildCourseContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CanvasCourseCard(course: widget.course),
      //TBD: here place the group
      _buildButtonsContent()
    ]);
  }

  Widget _buildButtonsContent() {
    return Column(children: [
      _buildDelimiter(),
      RibbonButton(
          label: Localization().getStringEx('panel.home_canvas_course.button.syllabus.title', 'Syllabus'),
          hint: Localization().getStringEx('panel.home_canvas_course.button.syllabus.hint', ''),
          leftIcon: 'images/icon-settings.png',
          onTap: _onTapSyllabus),
      _buildDelimiter(),
      RibbonButton(
          label: Localization().getStringEx('panel.home_canvas_course.button.announcements.title', 'Announcements'),
          hint: Localization().getStringEx('panel.home_canvas_course.button.announcements.hint', ''),
          leftIcon: 'images/icon-settings.png'),
      _buildDelimiter(),
      RibbonButton(
          label: Localization().getStringEx('panel.home_canvas_course.button.files.title', 'Files'),
          hint: Localization().getStringEx('panel.home_canvas_course.button.files.hint', ''),
          leftIcon: 'images/icon-settings.png'),
      _buildDelimiter(),
      RibbonButton(
          label: Localization().getStringEx('panel.home_canvas_course.button.collaborations.title', 'Collaborations'),
          hint: Localization().getStringEx('panel.home_canvas_course.button.collaborations.hint', ''),
          leftIcon: 'images/icon-settings.png'),
      _buildDelimiter(),
      RibbonButton(
          label: Localization().getStringEx('panel.home_canvas_course.button.calendar.title', 'Calendar'),
          hint: Localization().getStringEx('panel.home_canvas_course.button.calendar.hint', ''),
          leftIcon: 'images/icon-settings.png'),
      _buildDelimiter(),
      RibbonButton(
          label: Localization().getStringEx('panel.home_canvas_course.button.notifications.title', 'Notifications'),
          hint: Localization().getStringEx('panel.home_canvas_course.button.notifications.hint', ''),
          leftIcon: 'images/icon-settings.png'),
      _buildDelimiter(),
      RibbonButton(
          label: Localization().getStringEx('panel.home_canvas_course.button.inbox.title', 'Inbox'),
          hint: Localization().getStringEx('panel.home_canvas_course.button.inbox.hint', ''),
          leftIcon: 'images/icon-settings.png',
          onTap: _onTapInbox),
      _buildDelimiter(),
    ]);
  }

  Widget _buildDelimiter() {
    return Container(height: 1, color: Styles().colors!.surfaceAccent);
  }

  void _onTapSyllabus() {
    //TBD: handle tap action
  }

  void _onTapInbox() {
    Analytics.instance.logSelect(target: "Canvas Course -> Inbox");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => InboxHomePanel()));
  }
}
