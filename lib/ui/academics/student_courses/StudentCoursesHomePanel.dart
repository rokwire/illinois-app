/*
 * Copyright 2026 Board of Trustees of the University of Illinois.
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

import 'dart:math' as math;

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/StudentCourse.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/ui/academics/student_courses/StudentCoursesCalendarContentWidget.dart';
import 'package:illinois/ui/academics/student_courses/StudentCoursesListContentWidget.dart';
import 'package:illinois/ui/academics/student_courses/StudentCoursesMapContentWidget.dart';
import 'package:illinois/ui/map2/Map2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class StudentCoursesHomePanel extends StatefulWidget with AnalyticsInfo {

  final bool? showNavigationBars;
  final StudentCoursesViewType? initialViewType;
  StudentCoursesHomePanel({this.showNavigationBars = true, this.initialViewType});

  @override
  State<StudentCoursesHomePanel> createState() => _StudentCoursesHomePanelState();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.AcademicsStudentCourses;

  static Widget wrapDropDownTheme(Widget dropDown) => Theme(
    data: ThemeData(
      hoverColor: Styles().colors.white,
      focusColor: Styles().colors.white,
      canvasColor: Styles().colors.white,
      primaryColor: Styles().colors.white,
      highlightColor: Styles().colors.white,
      splashColor: Styles().colors.white,
    ),
    child: dropDown,
  );

  static BorderRadius get dropdownMenuBorderRadius => BorderRadius.circular(8);
}

class _StudentCoursesHomePanelState extends State<StudentCoursesHomePanel> with NotificationsListener {

  List<StudentCourse>? _courses;
  bool _loading = false;

  late StudentCoursesViewType _selectedViewType;

  double? _termsDropdownWidth;
  double? _viewTypeDropdownWidth;

  @override
  void initState() {
    super.initState();
    _selectedViewType = widget.initialViewType ?? Storage()._studentCoursesViewType ?? StudentCoursesViewType.calendar;

    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
      Connectivity.notifyStatusChanged,
      StudentCourses.notifyTermsChanged,
      StudentCourses.notifySelectedTermChanged,
      StudentCourses.notifyCachedCoursesChanged,
      AppDateTime.notifyTimeZoneChanged,
    ]);

    if (_canLoadCourses) {
      _loading = true;
      StudentCourses().loadCourses(termId: StudentCourses().displayTermId!).then((List<StudentCourse>? courses) {
        setStateIfMounted(() {
          _courses = courses;
          _sortCourses();
          _loading = false;
        });
      });
    }
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
      _updateCourses();
    }
    else if (name == StudentCourses.notifySelectedTermChanged) {
      _updateCourses();
    }
    else if (name == StudentCourses.notifyCachedCoursesChanged) {
      if ((param == null) || (StudentCourses().displayTermId == param)) {
        _updateCourses(forceLoad: false);
      }
    }
    else if (name == AppDateTime.notifyTimeZoneChanged) {
      setStateIfMounted(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _showNavigationBars ? HeaderBar(title: Localization().getStringEx('panel.student_courses.header.title', 'My Courses')) : null,
      body: Column(children: <Widget>[
        _buildFilterBar(),
        Container(height: 1, color: Styles().colors.surfaceAccent),
        Expanded(child: _buildContent()),
      ]),
      backgroundColor: _showNavigationBars ? Styles().colors.white : Styles().colors.background,
      bottomNavigationBar: _showNavigationBars ? uiuc.TabBar() : null,
    );
  }

  Widget _buildFilterBar() {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
      Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
        _buildTermsDropDown(),
        Padding(padding: EdgeInsets.only(left: 8), child: _buildViewTypeDropDown()),
      ]),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return _buildLoadingContent();
    }
    else if (Connectivity().isOffline) {
      return _buildMessageContent(Localization().getStringEx('panel.student_courses.load.offline.error.msg', 'My Courses is not available while offline.'));
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
      return _rawViewTypeContentWidget;
    }
  }

  Widget _buildLoadingContent() {
    return Center(child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary)));
  }

  Widget _buildMessageContent(String message) {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 28), child:
      Center(child:
        Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.message.medium.thin"))
      ),
    );
  }

  TextStyle? _getDropDownItemStyle({bool bold = false}) => bold ?
    Styles().textStyles.getTextStyle("widget.message.regular.fat") :
    Styles().textStyles.getTextStyle("widget.message.regular");

  Widget _buildTermsDropDown() {
    StudentCourseTerm? currentTerm = StudentCourses().displayTerm;
    _termsDropdownWidth ??= _evaluateTermsDropdownWidth();

    return Visibility(visible: CollectionUtils.isNotEmpty(StudentCourses().terms), child:
      Semantics(label: currentTerm?.name, hint: Localization().getStringEx('panel.student_courses.term_dropdown.hint', 'Double tap to select term'), button: true, container: true, child:
        DropdownButtonHideUnderline(child:
          DropdownButton2<String>(
            dropdownStyleData: DropdownStyleData(width: _termsDropdownWidth, padding: EdgeInsets.zero),
            buttonStyleData: ButtonStyleData(overlayColor: WidgetStateProperty.all(Colors.transparent)),
            customButton: Map2FilterTextButton(
              title: currentTerm?.name ?? '',
              rightIcon: Styles().images.getImage('chevron-down'),
            ),
            isExpanded: false,
            items: _buildTermDropDownItems(),
            onChanged: _onTermDropDownValueChanged,
          ),
        ),
      ),
    );
  }

  double _evaluateTermsDropdownWidth() {
    double width = 0;
    for (StudentCourseTerm term in StudentCourses().terms ?? <StudentCourseTerm>[]) {
      width = math.max(width, _measureDropDownItemTextWidth(term.name ?? ''));
    }
    return math.min(width + 3 * 18 + 4, MediaQuery.of(context).size.width / 2);
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
          child: Text(term.name ?? '', style: _getDropDownItemStyle(bold: (term.id == currentTermId)),)
        ));
      }
    }
    return items;
  }

  void _onTermDropDownValueChanged(String? termId) {
    StudentCourses().selectedTermId = termId;
  }

  void _updateCourses({bool forceLoad = true}) {
    if (_canLoadCourses) {
      setStateIfMounted(() {
        _loading = true;
      });
      StudentCourses().loadCourses(termId: StudentCourses().displayTermId!, forceLoad: forceLoad).then((List<StudentCourse>? courses) {
        setStateIfMounted(() {
          _courses = courses;
          _sortCourses();
          _loading = false;
        });
      });
    }
    else {
      setStateIfMounted(() {});
    }
  }

  void _sortCourses() {
    _courses?.sort((StudentCourse c1, StudentCourse c2) {
      String n1 = c1.section?.comparableValue ?? '';
      String n2 = c2.section?.comparableValue ?? '';
      return n1.compareTo(n2);
    });
  }

  Widget _buildViewTypeDropDown() {
    _viewTypeDropdownWidth ??= _evaluateViewTypeDropdownWidth();

    return Semantics(label: _selectedViewType.pillTitle, hint: Localization().getStringEx('panel.student_courses.view_type_dropdown.hint', 'Double tap to select view'), button: true, container: true, child:
      DropdownButtonHideUnderline(child:
        DropdownButton2<StudentCoursesViewType>(
          dropdownStyleData: DropdownStyleData(width: _viewTypeDropdownWidth, padding: EdgeInsets.zero),
          buttonStyleData: ButtonStyleData(overlayColor: WidgetStateProperty.all(Colors.transparent)),
          customButton: Map2FilterTextButton(
            title: _selectedViewType.pillTitle,
            rightIcon: Styles().images.getImage('chevron-down'),
          ),
          isExpanded: false,
          items: _buildViewTypeDropDownItems(),
          onChanged: _onViewTypeDropDownValueChanged,
        ),
      ),
    );
  }

  double _evaluateViewTypeDropdownWidth() {
    double width = 0;
    for (StudentCoursesViewType viewType in StudentCoursesViewType.values) {
      width = math.max(width, _measureDropDownItemTextWidth(viewType.pillTitle));
    }
    return math.min(width + 3 * 18 + 4, MediaQuery.of(context).size.width / 2);
  }

  double _measureDropDownItemTextWidth(String text) => (TextPainter(
    text: TextSpan(text: text, style: _getDropDownItemStyle(bold: true)),
    textScaler: MediaQuery.of(context).textScaler,
    textDirection: TextDirection.ltr,
  )..layout()).size.width;

  List<DropdownMenuItem<StudentCoursesViewType>> _buildViewTypeDropDownItems() {
    return StudentCoursesViewType.values.map((StudentCoursesViewType viewType) =>
      DropdownMenuItem<StudentCoursesViewType>(
        value: viewType,
        child: Text(viewType.pillTitle, style: _getDropDownItemStyle(bold: (viewType == _selectedViewType))),
      )
    ).toList();
  }

  void _onViewTypeDropDownValueChanged(StudentCoursesViewType? viewType) {
    if (viewType != null) {
      setStateIfMounted(() {
        Storage()._studentCoursesViewType = _selectedViewType = viewType;
      });
      Analytics().logPageWidget(_rawViewTypeContentWidget);
    }
  }

  Widget get _rawViewTypeContentWidget {
    switch (_selectedViewType) {
      case StudentCoursesViewType.calendar:
        return StudentCoursesCalendarContentWidget(courses: _courses, analyticsFeature: widget.analyticsFeature);
      case StudentCoursesViewType.list:
        return StudentCoursesListContentWidget(courses: _courses, analyticsFeature: widget.analyticsFeature);
      case StudentCoursesViewType.map:
        return StudentCoursesMapContentWidget(courses: _courses, analyticsFeature: widget.analyticsFeature);
    }
  }

  bool get _canLoadCourses => (Connectivity().isNotOffline && (StudentCourses().displayTermId != null) && Auth2().isOidcLoggedIn);

  bool get _showNavigationBars => (widget.showNavigationBars == true);
}

enum StudentCoursesViewType { calendar, list, map }

extension StudentCoursesViewTypeExt on StudentCoursesViewType {
  String get pillTitle {
    switch (this) {
      case StudentCoursesViewType.calendar: return Localization().getStringEx('panel.student_courses.view_type.calendar.pill.title', 'Calendar');
      case StudentCoursesViewType.list: return Localization().getStringEx('panel.student_courses.view_type.list.pill.title', 'List');
      case StudentCoursesViewType.map: return Localization().getStringEx('panel.student_courses.view_type.map.pill.title', 'Map');
    }
  }

  String toJson() {
    switch (this) {
      case StudentCoursesViewType.calendar: return 'calendar';
      case StudentCoursesViewType.list: return 'list';
      case StudentCoursesViewType.map: return 'map';
    }
  }

  static StudentCoursesViewType? fromJson(dynamic value) {
    switch (value) {
      case 'calendar': return StudentCoursesViewType.calendar;
      case 'list': return StudentCoursesViewType.list;
      case 'map': return StudentCoursesViewType.map;
    }
    return null;
  }
}

extension _StorageStudentCoursesExt on Storage {
  StudentCoursesViewType? get _studentCoursesViewType =>
    StudentCoursesViewTypeExt.fromJson(studentCoursesViewType);
  set _studentCoursesViewType(StudentCoursesViewType? value) => studentCoursesViewType = value?.toJson();
}
