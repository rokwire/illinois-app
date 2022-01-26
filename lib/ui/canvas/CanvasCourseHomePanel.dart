import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/canvas/CanvasCourseSyllabusPanel.dart';
import 'package:illinois/ui/canvas/CanvasWidgets.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/inbox/InboxHomePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';

class CanvasCourseHomePanel extends StatefulWidget {
  final int? courseId;
  CanvasCourseHomePanel({this.courseId});

  @override
  _CanvasCourseHomePanelState createState() => _CanvasCourseHomePanelState();
}

class _CanvasCourseHomePanelState extends State<CanvasCourseHomePanel> {
  CanvasCourse? _course;
  Group? _group;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadCourse();
    _loadGroup();
  }

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
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 28), child: Text(Localization().getStringEx('panel.home_canvas_course.load.failed.error.msg', 'Failed to load course. Please, try again later.')!,
            textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18))));
  }

  Widget _buildCourseContent() {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [CanvasCourseCard(course: _course!), _buildGroupContent(), _buildButtonsContent()]));
  }

  Widget _buildGroupContent() {
    if (_group == null) {
      return Container();
    }
    return Padding(padding: EdgeInsets.all(16), child: GroupCard(group: _group, displayType: GroupCardDisplayType.allGroups));
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
    Analytics.instance.logSelect(target: "Canvas Course Syllabus");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCourseSyllabusPanel(courseId: widget.courseId!)));
  }

  void _onTapInbox() {
    Analytics.instance.logSelect(target: "Canvas Course -> Inbox");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => InboxHomePanel()));
  }

  void _loadCourse() {
    _increaseProgress();
    Canvas().loadCourse(widget.courseId).then((course) {
      _course = course;
      _decreaseProgress();
    });
  }

  void _loadGroup() {
    _increaseProgress();
    Groups().loadGroupByCanvasCourseId(widget.courseId).then((group) {
      _group = group;
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
