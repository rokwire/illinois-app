import 'package:flutter/material.dart';
import 'package:illinois/model/Courses.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Courses.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:sprintf/sprintf.dart';

class StudentCoursesContentWidget extends StatefulWidget {
  StudentCoursesContentWidget();

  @override
  State<StudentCoursesContentWidget> createState() => _StudentCoursesContentWidgetState();
}

class _StudentCoursesContentWidgetState extends State<StudentCoursesContentWidget> implements NotificationsListener {

  List<Course>? _courses;
  bool _loading = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Courses.notifyTermsChanged,
      Courses.notifySelectedTermChanged,
    ]);

    if (Courses().displayTermId != null) {
      _loading = true;
      Courses().loadCourses(termId: Courses().displayTermId!).then((List<Course>? courses) {
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
    if (name == Courses.notifyTermsChanged) {
      setStateIfMounted(() {});
    }
    else if (name == Courses.notifySelectedTermChanged) {
      _updateCourses();
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
    else if (_courses == null) {
      return _buildMessageContent(Localization().getStringEx('panel.student_courses.load.failed.error.msg', 'Unable to load courses.'));
    }
    else if (_courses?.isEmpty ?? true) {
      return _buildMessageContent(Localization().getStringEx('panel.student_courses.empty.content.msg', 'You do not appear to be enrolled in any courses.'));
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
      for (Course course in _courses!) {
        courseWidgets.add(Padding(padding: EdgeInsets.only(top: (1 < courseWidgets.length) ? 8 : 0), child:
          StudentCourseCard(course: course,),
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
      CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors?.fillColorSecondary),),
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
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18))
        ),
      ),
      Expanded(flex: 4, child: Container()),
    ]);
  }

  TextStyle getTermDropDownItemStyle({bool selected = false}) => selected ?
    TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 16, color: Styles().colors?.fillColorPrimary) :
    TextStyle(fontFamily: Styles().fontFamilies?.medium, fontSize: 16, color: Styles().colors?.fillColorPrimary);

  Widget _buildTermsDropDown() {
    CourseTerm? currentTerm = Courses().displayTerm;

    return Semantics(label: currentTerm?.name, hint: "Double tap to select account", button: true, container: true, child:
      DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Padding(padding: EdgeInsets.only(left: 4), child: Image.asset('images/icon-down.png')),
          isExpanded: false,
          style: getTermDropDownItemStyle(selected: true),
          hint: (currentTerm?.name?.isNotEmpty ?? false) ? Text(currentTerm?.name ?? '', style: getTermDropDownItemStyle(selected: true)) : null,
          items: _buildTermDropDownItems(),
          onChanged: _onTermDropDownValueChanged
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>>? _buildTermDropDownItems() {
    List<CourseTerm>? terms = Courses().terms;
    String? currentTermId = Courses().displayTermId;

    List<DropdownMenuItem<String>>? items;
    if (terms != null) {
      items = <DropdownMenuItem<String>>[];
      for (CourseTerm term in terms) {
        items.add(DropdownMenuItem<String>(
          value: term.id,
          child: Text(term.name ?? '', style: getTermDropDownItemStyle(selected: term.id == currentTermId),)
        ));
      }
    }
    return items;
  }

  void _onTermDropDownValueChanged(String? termId) {
    Courses().selectedTermId = termId;
  }

  void _updateCourses() {
    if (Courses().displayTermId != null) {
      setStateIfMounted(() {
        _loading = true;
      });
      Courses().loadCourses(termId: Courses().displayTermId!).then((List<Course>? courses) {
        setStateIfMounted(() {
          _courses = courses;
          _loading = false;
        });
      });
    }
  }
}

class StudentCourseCard extends StatelessWidget {
  final Course course;
  
  StudentCourseCard({Key? key, required this.course}) : super(key: key);

  static double height(BuildContext context) =>
    MediaQuery.of(context).textScaleFactor * (36 + 18 + (6 + 16) + 16 /*+ (6 + 18) + (12 + 18)*/);

  @override
  Widget build(BuildContext context) {
    String courseSchedule = _courseSchedule;
    String courseLocation = _courseLocation;
    

    return ClipRRect(borderRadius: BorderRadius.all(Radius.circular(4)), child:
      Stack(children: [
        Container(
          decoration: BoxDecoration(
            color: Styles().colors!.surface,
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          child:
                Padding(padding: EdgeInsets.all(16), child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    
                    Row(children: [Expanded(child:
                      Text(course.title ?? '', style: TextStyle(color: Styles().colors?.fillColorPrimary, fontFamily: Styles().fontFamilies?.extraBold, fontSize: 18),),
                    )]),
                    
                    Padding(padding: EdgeInsets.only(top: 6), child:
                      Row(children: [Expanded(child:
                        Text('${course.shortName} (${course.number}) ${course.instructionMethod}', style: TextStyle(color: Styles().colors?.textBackground, fontFamily: Styles().fontFamilies?.medium, fontSize: 16),),
                      )]),
                    ),
                    
                    Padding(padding: EdgeInsets.zero, child:
                      Row(children: [Expanded(child:
                        Text(sprintf(Localization().getStringEx('panel.student_courses.instructor.title', 'Instructor: %s'), [course.section?.instructor ?? '']), style: TextStyle(color: Styles().colors?.textBackground, fontFamily: Styles().fontFamilies?.medium, fontSize: 16),)
                      )]),
                    ),
                    
                    Visibility(visible: courseSchedule.isNotEmpty, child:
                      Padding(padding: EdgeInsets.only(top: 6), child:
                        Row(children: [
                          Padding(padding: EdgeInsets.only(right: 6), child:
                            Image.asset('images/icon-calendar.png'),
                          ),
                          Expanded(child:
                            Text(courseSchedule, style: TextStyle(color: Styles().colors?.textBackground, fontFamily: Styles().fontFamilies?.medium, fontSize: 16),),
                          )
                          
                        ],),
                      ),
                    ),
                    
                    Visibility(visible: courseLocation.isNotEmpty && course.hasLocation, child:
                      InkWell(onTap: _onLocaltion, child:
                        Padding(padding: EdgeInsets.symmetric(vertical: 6), child:
                          Row(children: [
                            Padding(padding: EdgeInsets.only(right: 6), child:
                              Image.asset('images/icon-location.png'),
                            ),
                            Expanded(child:
                              Text(_courseLocation, style:
                                TextStyle(color: Styles().colors?.textBackground, fontFamily: Styles().fontFamilies?.medium, fontSize: 16,
                                  decoration: TextDecoration.underline, decorationColor: Styles().colors?.fillColorSecondary, decorationStyle: TextDecorationStyle.solid, decorationThickness: 1
                                ),
                              ),
                            )
                            
                          ],),
                        ),
                      ),
                    ),

                  ],)
                ),
        ),
        Container(color: Styles().colors?.fillColorSecondary, height: 4),
      ]),
    );

  }

  String get _courseSchedule {
    String time = ((course.section?.startTime?.isNotEmpty ?? false) && (course.section?.endTime?.isNotEmpty ?? false)) ?
      "${course.section?.startTime} - ${course.section?.endTime}" : "${course.section?.startTime ?? ''}";
    String days = course.section?.days?.replaceAll(',', ', ') ?? '';
    if (days.isNotEmpty) {
      return (time.isNotEmpty) ? "$days $time" : days;
    }
    else {
      return time;
    }
  }

  String get _courseLocation {
    String buildingName = course.section?.buildingName ?? '';
    String room = course.section?.room ?? '';
    return (buildingName.isNotEmpty && room.isNotEmpty) ? "$buildingName $room" : buildingName;
  }

  void _onLocaltion() {
    Analytics().logSelect(target: "Location Detail");
    NativeCommunicator().launchMapDirections(jsonData: course.toMapsJson());
  }

}

class StudentCoursesListPanel extends StatelessWidget {
  StudentCoursesListPanel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.student_courses.header.title', 'My Courses')),
      body: Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child: StudentCoursesContentWidget()),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: uiuc.TabBar()
    );
  }
}
