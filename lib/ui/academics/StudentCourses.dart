import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/StudentCourse.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

import '../explore/DisplayFloorPlanPanel.dart';

class StudentCoursesContentWidget extends StatefulWidget with AnalyticsInfo {
  StudentCoursesContentWidget();

  @override
  State<StudentCoursesContentWidget> createState() => _StudentCoursesContentWidgetState();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.AcademicsStudentCourses;
}

class _StudentCoursesContentWidgetState extends State<StudentCoursesContentWidget> implements NotificationsListener {

  List<StudentCourse>? _courses;
  bool _loading = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
      Connectivity.notifyStatusChanged,
      StudentCourses.notifyTermsChanged,
      StudentCourses.notifySelectedTermChanged,
      StudentCourses.notifyCachedCoursesChanged,
    ]);

    if (Connectivity().isNotOffline && (StudentCourses().displayTermId != null) && Auth2().isOidcLoggedIn) {
      _loading = true;
      StudentCourses().loadCourses(termId: StudentCourses().displayTermId!, forceLoad: true).then((List<StudentCourse>? courses) {
        setStateIfMounted(() {
          _courses = courses;
          _loading = false;
        });
      });
    }
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
    if (name == Auth2.notifyLoginChanged) {
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
        _updateCourses(forceLoad: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    if (_loading) {
      return _buildLoadingContent();
    }
    else if (Connectivity().isOffline) {
      return _buildMessageContent(Localization().getStringEx('panel.student_courses.load.offline.error.msg', 'My Courses not available while offline.'));
    }
    else if (!Auth2().isOidcLoggedIn) {
      return _buildMessageContent(AppTextUtils.loggedOutFeatureNA(Localization().getStringEx('generic.app.feature.student_courses', 'My Courses'), verbose: true));
    }
    else if (_courses == null) {
      return _buildMessageContent(Localization().getStringEx('panel.student_courses.load.failed.error.msg', 'It appears you have no courses registered for the selected term.'));
    }
    else if (_courses?.isEmpty ?? true) {
      return _buildMessageContent(Localization().getStringEx('panel.student_courses.empty.content.msg', 'You do not appear to be enrolled in any courses for the selected term.'));
    }
    else {
      return _buildCoursesContent();
    }
  }

  Widget _buildCoursesContent() {
    List<Widget> courseWidgets = <Widget>[
      Align(alignment: Alignment.centerLeft, child:
        _buildTermsDropDown(),
      ),
    ];
    
    if (_courses != null) {
      for (StudentCourse course in _courses!) {
        courseWidgets.add(Padding(padding: EdgeInsets.only(top: (1 < courseWidgets.length) ? 8 : 0), child:
          StudentCourseCard(course: course, analyticsFeature: widget.analyticsFeature,),
        ));

      }
    }

    return SingleChildScrollView(child:
      Padding(padding: EdgeInsets.only(bottom: 16), child:
        Column(children: courseWidgets,),
      )
    );
  }

  Widget _buildLoadingContent() {
    return Column(children: <Widget>[
      Align(alignment: Alignment.centerLeft, child:
        _buildTermsDropDown(),
      ),
      Expanded(flex: 1, child: Container()),
      CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary),),
      Expanded(flex: 4, child: Container()),
    ]);
  }

  Widget _buildMessageContent(String message) {
    return Column(children: <Widget>[
      Align(alignment: Alignment.centerLeft, child:
        _buildTermsDropDown(),
      ),
      Expanded(flex: 1, child: Container()),
      Padding(padding: EdgeInsets.symmetric(horizontal: 28), child:
        Center(child:
          Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.message.medium.thin"))
        ),
      ),
      Expanded(flex: 4, child: Container()),
    ]);
  }

  TextStyle? getTermDropDownItemStyle({bool selected = false}) => selected ?
  Styles().textStyles.getTextStyle("widget.message.regular") :
  Styles().textStyles.getTextStyle("widget.message.regular.semi_fat");

  Widget _buildTermsDropDown() {
    StudentCourseTerm? currentTerm = StudentCourses().displayTerm;

    return Visibility(visible: CollectionUtils.isNotEmpty(StudentCourses().terms), child:
      Semantics(label: currentTerm?.name, hint: "Double tap to select account", button: true, container: true, child:
        DropdownButtonHideUnderline(child:
          DropdownButton<String>(
            icon: Padding(padding: EdgeInsets.only(left: 4), child: Styles().images.getImage('chevron-down', excludeFromSemantics: true)),
            isExpanded: false,
            style: getTermDropDownItemStyle(selected: true),
            //alignment: AlignmentDirectional.centerEnd,
            hint: (currentTerm?.name?.isNotEmpty ?? false) ? Text(currentTerm?.name ?? '', style: getTermDropDownItemStyle(selected: true)) : null,
            items: _buildTermDropDownItems(),
            onChanged: _onTermDropDownValueChanged
          ),
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

  void _updateCourses({bool forceLoad = true}) {
    if (Connectivity().isNotOffline && (StudentCourses().displayTermId != null) && Auth2().isOidcLoggedIn) {
      setStateIfMounted(() {
        _loading = true;
      });
      StudentCourses().loadCourses(termId: StudentCourses().displayTermId!, forceLoad: forceLoad).then((List<StudentCourse>? courses) {
        setStateIfMounted(() {
          _courses = courses;
          _loading = false;
        });
      });
    }
    else {
        setStateIfMounted(() {});
    }
  }
}

class StudentCourseCard extends StatelessWidget {
  final StudentCourse course;
  final AnalyticsFeature? analyticsFeature;

  StudentCourseCard({Key? key, required this.course, this.analyticsFeature}) : super(key: key);

  static double height(BuildContext context) =>
  MediaQuery.of(context).textScaler.scale(36 + 18 + (6 + 16) + 16 + (6 + 18) + (12 + 18));

  @override
  Widget build(BuildContext context) {
    String courseSchedule = course.section?.displaySchedule ?? '';
    String courseLocation = course.section?.displayLocation ?? '';
    
    return InkWell(onTap: () => _onCard(context), child:
      ClipRRect(borderRadius: BorderRadius.all(Radius.circular(4)), child:
        Stack(children: [
          Container(
            decoration: BoxDecoration(
              color: Styles().colors.surface,
              border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            child:
              Padding(padding: EdgeInsets.all(16), child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  
                  Row(children: [Expanded(child:
                    Text(course.title ?? '', style: Styles().textStyles.getTextStyle("widget.card.title.regular.extra_fat")),
                  )]),
                  
                  Padding(padding: EdgeInsets.only(top: 6), child:
                    Row(children: [Expanded(child:
                      Text(course.displayInfo, style: Styles().textStyles.getTextStyle("widget.card.detail.medium")),
                    )]),
                  ),
                  
                  Padding(padding: EdgeInsets.zero, child:
                    Row(children: [Expanded(child:
                      Text(sprintf(Localization().getStringEx('panel.student_courses.instructor.title', 'Instructor: %s'), [course.section?.instructor ?? '']), style: Styles().textStyles.getTextStyle("widget.card.detail.medium"),)
                    )]),
                  ),
                  
                  Visibility(visible: courseSchedule.isNotEmpty, child:
                    Padding(padding: EdgeInsets.only(top: 6), child:
                      Row(children: [
                        Padding(padding: EdgeInsets.only(right: 6), child:
                          Styles().images.getImage('calendar', excludeFromSemantics: true),
                        ),
                        Expanded(child:
                          Text(courseSchedule, style: Styles().textStyles.getTextStyle("widget.card.detail.medium")),
                        )
                        
                      ],),
                    ),
                  ),
                  
                  Visibility(visible: courseLocation.isNotEmpty, child:
                    InkWell(onTap: course.hasValidLocation ? _onLocaltion : null, child:
                      Padding(padding: EdgeInsets.symmetric(vertical: 6), child:
                        Row(children: [
                          Padding(padding: EdgeInsets.only(right: 6), child:
                            Styles().images.getImage('location', excludeFromSemantics: true),
                          ),
                          Expanded(child:
                            Text(courseLocation, style: course.hasValidLocation ?
                              Styles().textStyles.getTextStyle("widget.button.light.title.medium.underline") :
                              Styles().textStyles.getTextStyle("widget.button.light.title.medium")
                            ),
                          )
                          
                        ],),
                      ),
                    ),
                  ),

                ],)
              ),
          ),
          Container(color: Styles().colors.fillColorSecondary, height: 4),
        ]),
      ),
    );
  }

  void _onLocaltion() {
    Analytics().logSelect(target: "Location Detail");
    course.launchDirections();
  }

  void _onCard(BuildContext context) {
    Analytics().logSelect(target: "Student Course: ${course.title}");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentCourseDetailPanel(course: course, analyticsFeature: analyticsFeature,)));
  }

}

class StudentCoursesListPanel extends StatelessWidget with AnalyticsInfo {
  StudentCoursesListPanel();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.AcademicsStudentCourses;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.student_courses.header.title', 'My Courses')),
      body: Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child: StudentCoursesContentWidget()),
      backgroundColor: Styles().colors.surface,
      bottomNavigationBar: uiuc.TabBar()
    );
  }
}

class StudentCourseDetailPanel extends StatefulWidget with AnalyticsInfo {
  final StudentCourse? course;
  final AnalyticsFeature? analyticsFeature; //This overrides AnalyticsInfo.analyticsFeature getter

  StudentCourseDetailPanel({super.key, this.course, this.analyticsFeature});
  @override
  _StudentCourseDetailPanelState createState() => _StudentCourseDetailPanelState();
}
class _StudentCourseDetailPanelState extends State<StudentCourseDetailPanel> {
  bool _roomExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildContent(),
      backgroundColor: Styles().colors.surface,
      bottomNavigationBar: uiuc.TabBar()
    );
  }

  Widget _buildContent() {
    return   Column(
      children: <Widget>[
        Expanded(
          child: Container(
            child: CustomScrollView(
              scrollDirection: Axis.vertical,
              slivers: <Widget>[
                SliverToutHeaderBar(
                  flexRightToLeftTriangleColor: Colors.white,
                  flexImageKey: 'course-detail-default',
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                      [
                        Stack(
                          children: <Widget>[
                            Container(
                                color: Colors.white,
                                child: Column(
                                  children: <Widget>[
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Column(
                                          children: <Widget>[
                                            Padding(
                                                padding:
                                                EdgeInsets.only(right: 20, left: 20),
                                                child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: <Widget>[
                                                      _buildTitle(),
                                                      _buildDisplayInfo(),
                                                      _buildInstructor(),
                                                      _buildSchedule(),
                                                      _buildLocation(),
                                                      _buildRoom(),
                                                    ]
                                                )),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                            )
                          ],
                        )
                      ],
                      addSemanticIndexes:false),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(){
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                widget.course?.title ?? "",
                style: Styles().textStyles.getTextStyle("widget.student_courses.title.extra_large")
              ),
            ),
          ],
        ));
  }

  Widget _buildDisplayInfo(){
    return  widget.course?.displayInfo != null?
    Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          widget.course?.displayInfo ?? "",
          style: Styles().textStyles.getTextStyle("widget.item.regular.thin")
        )) :
    Container();
  }

  Widget _buildInstructor(){
    return
      Padding(padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [Expanded(child:
          Text(sprintf(Localization().getStringEx('panel.student_courses.instructor.title', 'Instructor: %s'), [widget.course?.section?.instructor ?? '']), style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),)
        )]),
    );
  }

  Widget _buildSchedule(){
    String courseSchedule = widget.course?.section?.displaySchedule ?? '';
    return Visibility(visible: courseSchedule.isNotEmpty, child:
      Padding(padding: EdgeInsets.symmetric(vertical: 10), child:
        Row(children: [
          Padding(padding: EdgeInsets.only(right: 6), child:
            Styles().images.getImage('calendar', excludeFromSemantics: true),
          ),
          Expanded(child:
            Text(courseSchedule, style: Styles().textStyles.getTextStyle("widget.item.regular.thin")),
          )

        ],),
      ),
    );
  }

  Widget _buildLocation(){
    String courseLocation = widget.course?.section?.building?.fullAddress ?? '';
    return Visibility(visible: courseLocation.isNotEmpty, child:
      InkWell(onTap: (widget.course?.hasValidLocation ?? false) ? _onLocation : null, child:
        Padding(padding: EdgeInsets.symmetric(vertical: 10, ), child:
          Row(children: [
            Padding(padding: EdgeInsets.only(right: 6), child:
              Styles().images.getImage('location', excludeFromSemantics: true),
            ),
            Expanded(child:
              Text(courseLocation, style: (widget.course?.hasValidLocation ?? false) ?
                Styles().textStyles.getTextStyle("widget.button.light.title.medium.underline") :
                Styles().textStyles.getTextStyle("widget.button.light.title.medium")
              ),
            )
          ],),
        ),
      ),
    );
  }

  Widget _buildRoom() {
    String room = widget.course?.section?.room ?? '';
    List<String> floors = widget.course?.section?.building?.floors ?? [];
    return Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4), child:
      InkWell(onTap: _onRoom, child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Padding(padding: EdgeInsets.only(right: 6), child:
            (_roomExpanded)
              ? Styles().images.getImage('chevron-up', excludeFromSemantics: true) ?? Container()
              : Styles().images.getImage('chevron-down', excludeFromSemantics: true) ?? Container()
            ),
            Text("Room ${room}", style: Styles().textStyles.getTextStyle("widget.button.light.title.medium.underline"))
          ]),
          Visibility(visible: _roomExpanded, child:
            Padding(padding: EdgeInsets.only(left: 17), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: EdgeInsets.symmetric(vertical: 4), child:
                  Text("${Localization().getStringEx('panel.explore_building_detail.detail.fllor_plan_and_amenities', 'Floor Plans & Amenities')}:", style: Styles().textStyles.getTextStyle('widget.button.light.title.medium.fat'))
                ),
                ...floors.map((floor) => InkWell(onTap: () => _onFloor(floor), child:
                  Padding(padding: EdgeInsets.symmetric(vertical: 2), child:
                    Text("Floor ${floor}", style: Styles().textStyles.getTextStyle("widget.description.small.underline")))
                  )
                ).toList()
              ])
            )
          )
        ])
      )
    );
  }

  void _onLocation() {
    Analytics().logSelect(target: "Location Directions");
    widget.course?.launchDirections();
  }

  void _onFloor(String floor) {
    Analytics().logSelect(target: "Floor Plan");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DisplayFloorPlanPanel(building: widget.course?.section?.building, startingFloor: floor)));
  }

  void _onRoom() {
    setState(() {
      _roomExpanded = !_roomExpanded;
    });
  }
}