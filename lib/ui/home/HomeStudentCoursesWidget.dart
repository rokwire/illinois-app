import 'dart:async';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/ui/academics/StudentCourses.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';

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

  List<StudentCourse>? _courses;
  bool _loading = false;
  DateTime? _pausedDateTime;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  final double _pageSpacing = 16;
  
  @override
  void initState() {

    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Auth2.notifyLoginChanged,
      Connectivity.notifyStatusChanged,
      StudentCourses.notifyTermsChanged,
      StudentCourses.notifySelectedTermChanged,
      StudentCourses.notifyCachedCoursesChanged,
    ]);


    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _updateCourses(forceLoad: true);
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
    else if (name == Auth2.notifyLoginChanged) {
      _updateCourses();
    }
    else if (name == Connectivity.notifyStatusChanged) {
      _updateCourses();
    }
    else if (name == StudentCourses.notifyTermsChanged) {
      setStateIfMounted(() {});
    }
    else if (name == StudentCourses.notifySelectedTermChanged) {
      _updateCourses();
    }
    else if (name == StudentCourses.notifyCachedCoursesChanged) {
      if ((param == null) || (StudentCourses().displayTermId == param)) {
        _updateCourses();
      }
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
          _updateCourses(showProgress: false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildSlant();
  }

  Widget _buildSlant() {
    final double flatHeight = 40;
    final double slantHeight = 65;

    return Column(children: [
      
      // Title Row
      Padding(padding: EdgeInsets.zero, child: 
        Semantics(container: true, header: true,
          child: Container(color: Styles().colors?.fillColorPrimary, child:
            Row(children: <Widget>[

              HomeTitleIcon(image: Styles().images?.getImage('courses', excludeFromSemantics: true)),

              Expanded(child:
                Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
                  Semantics(label: HomeStudentCoursesWidget.title, header: true, excludeSemantics: true, child:
                    Text(HomeStudentCoursesWidget.title, style: Styles().textStyles?.getTextStyle("widget.title.light.large.extra_fat"))
                  )
                )
              ),

              Semantics(container: true,  button: true, child: _buildTermsDropDown(), ),
              
              Opacity(opacity: (widget.favoriteId != null) ? 1 : 0, child:
                HomeFavoriteButton(favorite: HomeFavorite(widget.favoriteId), style: FavoriteIconStyle.SlantHeader, prompt: true),
              ),
            ],),
        ),),
      ),
      
      Stack(children:<Widget>[
      
        // Slant
        Column(children: <Widget>[
          Container(color: Styles().colors?.fillColorPrimary, height: flatHeight,),
          Container(color: Styles().colors?.fillColorPrimary, child:
            CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.background, horzDir: TriangleHorzDirection.rightToLeft), child:
              Container(height: slantHeight,),
            ),
          ),
        ],),
        
        // Content
        Padding(padding: EdgeInsets.zero, child:
          _buildContent(),
        )
      ])

    ],);
  }

  TextStyle? getTermDropDownItemStyle({bool selected = false}) => selected ? Styles().textStyles?.getTextStyle("widget.button.title.medium.fat") : Styles().textStyles?.getTextStyle("widget.button.title.medium");

  Widget _buildTermsDropDown() {
    StudentCourseTerm? currentTerm = StudentCourses().displayTerm;

    return Semantics(label: currentTerm?.name, hint: "Double tap to select account", button: true, container: true, child:
      DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Padding(padding: EdgeInsets.only(left: 4), child: Styles().images?.getImage('chevron-down-white', excludeFromSemantics: true)),
          isExpanded: false,
          style: getTermDropDownItemStyle(selected: false),
          hint: (currentTerm?.name?.isNotEmpty ?? false) ? Text(currentTerm?.name ?? '', style: Styles().textStyles?.getTextStyle("widget.colourful_button.title")) : null,
          alignment: AlignmentDirectional.centerEnd,
          items: _buildTermDropDownItems(),
          onChanged: _onTermDropDownValueChanged
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>>? _buildTermDropDownItems() {
    List<StudentCourseTerm>? terms = StudentCourses().terms;
    String? currentTermId = StudentCourses().displayTermId;

    List<DropdownMenuItem<String>>? items;
    if (terms != null) {
      items = <DropdownMenuItem<String>>[];
      for (StudentCourseTerm term in terms) {
        items.add(DropdownMenuItem<String>(
          value: term.id,
          child: Text(term.name ?? '', style: getTermDropDownItemStyle(selected: term.id == currentTermId),)
        ));
      }
    }
    return items;
  }

  void _onTermDropDownValueChanged(String? termId) {
    StudentCourses().selectedTermId = termId;
  }

  Widget _buildContent() {
    if (_loading) {
      return HomeProgressWidget();
    }
    else if (Connectivity().isOffline) {
      return HomeMessageCard(message: Localization().getStringEx('widget.home.student_courses.text.offline.description', 'My Courses not available while offline.'),);
    }
    else if (!Auth2().isOidcLoggedIn) {
      return HomeMessageCard(message: Localization().getStringEx('widget.home.student_courses.text.logged_out.description', 'You need to be logged in with your NetID to access My Courses. Set your privacy level to 4 or 5 in your Profile. Then find the sign-in prompt under Settings.'),);
    }
    else if (_courses == null) {
      return HomeMessageCard(message: Localization().getStringEx('widget.home.student_courses.text.failed.description', 'It appears you have no courses registered for the selected term.'),);
    }
    else if (_courses?.isEmpty ?? true) {
      return HomeMessageCard(message: Localization().getStringEx('widget.home.student_courses.text.empty.description', 'You do not appear to be enrolled in any courses for the selected term.'),);
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
      for (StudentCourse course in _courses!) {
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
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => visibleCount, centerWidget:
        LinkButton(
          title: Localization().getStringEx('widget.home.student_courses.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.student_courses.button.all.hint', 'Tap to view all courses'),
          onTap: _onViewAll,
        ),
      ),
    ],);
  }

  void _loadCourses() {
    if (Connectivity().isNotOffline && (StudentCourses().displayTermId != null) && Auth2().isOidcLoggedIn && !_loading) {
      _loading = true;
      StudentCourses().loadCourses(termId: StudentCourses().displayTermId!).then((List<StudentCourse>? courses) {
        setStateIfMounted(() {
          _courses = courses;
          _loading = false;
        });
      });
    }
  }

  void _updateCourses({bool forceLoad = false, bool showProgress = true}) {
    if (Connectivity().isNotOffline && (StudentCourses().displayTermId != null) && Auth2().isOidcLoggedIn && !_loading) {
      if (mounted && showProgress) {
        setState(() {
          _loading = true;
        });
      }
      StudentCourses().loadCourses(termId: StudentCourses().displayTermId!, forceLoad: forceLoad).then((List<StudentCourse>? courses) {
        setStateIfMounted(() {
          _courses = courses;
          _loading = false;
        });
      });
    }
    else {
      setStateIfMounted(() { });
    }
  }

  void _onViewAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentCoursesListPanel()));
  }
}
