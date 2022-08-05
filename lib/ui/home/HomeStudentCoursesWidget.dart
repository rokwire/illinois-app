import 'dart:async';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/model/Courses.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Courses.dart';
import 'package:illinois/ui/academics/StudentCoursesContentWidget.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';

class HomeStudentCoursesWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeStudentCoursesWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.student_courses.header.label', 'My Courses');
  
  @override
  _HomeStudentCoursesWidgetState createState() => _HomeStudentCoursesWidgetState();
}

class _HomeStudentCoursesWidgetState extends State<HomeStudentCoursesWidget> implements NotificationsListener {

  List<Course>? _courses;
  bool _loading = false;
  DateTime? _pausedDateTime;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  final double _pageSpacing = 16;
  
  @override
  void initState() {

    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
    ]);


    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _updateCourses(showProgress: true);
        }
      });
    }

    _loadCourses();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _pageController?.dispose();
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateCourses();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: HomeStudentCoursesWidget.title,
      titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return HomeProgressWidget();
    }
    else if (_courses == null) {
      return HomeMessageCard(message: Localization().getStringEx('widget.home.student_courses.text.failed.description', 'Unable to load courses.'),);
    }
    else if (_courses?.isEmpty ?? true) {
      return HomeMessageCard(message: Localization().getStringEx('widget.home.student_courses.text.empty.description', 'You do not appear to be enrolled in any courses.'),);
    }
    else {
      return _buildCoursesContent();
    }
  }

  Widget _buildCoursesContent() {

    Widget contentWidget;
    int visibleCount = _courses?.length ?? 0; // Config().homeCampusHighlightsCount

    if (1 < visibleCount) {
      List<Widget> coursePages = <Widget>[];
      for (Course course in _courses!) {
        coursePages.add(Padding(padding: EdgeInsets.only(right: _pageSpacing), child:
          StudentCourseCard(course: course),
        ),);
      }

      if (_pageController == null) {
        double screenWidth = MediaQuery.of(context).size.width;
        double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
        _pageController = PageController(viewportFraction: pageViewport);
      }

      double pageHeight = StudentCourseCard.height(context);

      contentWidget = Container(constraints: BoxConstraints(minHeight: pageHeight), child:
        ExpandablePageView(
          key: _pageViewKey,
          controller: _pageController,
          estimatedPageSize: pageHeight,
          allowImplicitScrolling: true,
          children: coursePages,
        ),
      );
    }
    else {
      contentWidget = Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        StudentCourseCard(course: _courses!.first),
      );
    }

    return Column(children: [
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: visibleCount,),
      LinkButton(
        title: Localization().getStringEx('widget.home.student_courses.button.all.title', 'View All'),
        hint: Localization().getStringEx('widget.home.student_courses.button.all.hint', 'Tap to view all courses'),
        onTap: _onViewAll,
      ),
    ],);
  }

  void _loadCourses() {
    if (Courses().displayTermId != null) {
      _loading = true;
      Courses().loadCourses(termId: Courses().displayTermId!).then((List<Course>? courses) {
        setStateIfMounted(() {
          _courses = courses;
          _loading = false;
        });
      });
    }
  }

  void _updateCourses({bool showProgress = false}) {
    if (Courses().displayTermId != null) {
      if (mounted && showProgress) {
        setState(() {
          _loading = true;
        });
      }
      Courses().loadCourses(termId: Courses().displayTermId!).then((List<Course>? courses) {
        setStateIfMounted(() {
          _courses = courses;
          _loading = false;
        });
      });
    }
  }

  void _onViewAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentCoursesListPanel()));
  }
}
