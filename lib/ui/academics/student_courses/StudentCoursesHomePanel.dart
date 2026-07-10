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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/StudentCourse.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/ui/academics/student_courses/StudentCoursesCalendarContentWidget.dart';
import 'package:illinois/ui/academics/student_courses/StudentCoursesListContentWidget.dart';
import 'package:illinois/ui/academics/student_courses/StudentCoursesMapContentWidget.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class StudentCoursesHomePanel extends StatefulWidget with AnalyticsInfo {
  StudentCoursesHomePanel();

  @override
  State<StudentCoursesHomePanel> createState() => _StudentCoursesHomePanelState();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.AcademicsStudentCourses;
}

class _StudentCoursesHomePanelState extends State<StudentCoursesHomePanel> with NotificationsListener {

  List<StudentCourse>? _courses;
  bool _loading = false;

  late _StudentCoursesViewType _selectedViewType;

  @override
  void initState() {
    super.initState();
    _selectedViewType = Storage()._studentCoursesViewType ?? _StudentCoursesViewType.calendar;

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
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.student_courses.header.title', 'My Courses')),
      body: Column(children: <Widget>[
        _buildFilterBar(),
        Container(height: 1, color: Styles().colors.surfaceAccent),
        Expanded(child: _buildContent()),
      ]),
      backgroundColor: Styles().colors.white,
      bottomNavigationBar: uiuc.TabBar(),
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

  Widget _wrapDropDownTheme(Widget dropDown) => Theme(
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

  Widget _buildTermsDropDown() {
    StudentCourseTerm? currentTerm = StudentCourses().displayTerm;

    return Visibility(visible: CollectionUtils.isNotEmpty(StudentCourses().terms), child:
      Container(
        padding: EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Styles().colors.white,
          border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Semantics(label: currentTerm?.name, hint: Localization().getStringEx('panel.student_courses.term_dropdown.hint', 'Double tap to select term'), button: true, container: true, child:
          DropdownButtonHideUnderline(child: _wrapDropDownTheme(
            DropdownButton<String>(
              icon: Padding(padding: EdgeInsets.only(left: 4), child: Styles().images.getImage('chevron-down', excludeFromSemantics: true)),
              isExpanded: false,
              dropdownColor: Styles().colors.white,
              focusColor: Styles().colors.white,
              borderRadius: _dropdownMenuBorderRadius,
              style: _getDropDownItemStyle(),
              hint: (currentTerm?.name?.isNotEmpty ?? false) ? Text(currentTerm?.name ?? '', style: _getDropDownItemStyle()) : null,
              items: _buildTermDropDownItems(),
              onChanged: _onTermDropDownValueChanged,
            ),
          )),
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
          child: Text(term.name ?? '', style: _getDropDownItemStyle(bold: term.id == currentTermId),)
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Styles().colors.white,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Semantics(label: _selectedViewType.pillTitle, hint: Localization().getStringEx('panel.student_courses.view_type_dropdown.hint', 'Double tap to select view'), button: true, container: true, child:
        DropdownButtonHideUnderline(child: _wrapDropDownTheme(
          DropdownButton<_StudentCoursesViewType>(
            icon: Padding(padding: EdgeInsets.only(left: 4), child: Styles().images.getImage('chevron-down', excludeFromSemantics: true)),
            isExpanded: false,
            dropdownColor: Styles().colors.white,
            focusColor: Styles().colors.white,
            borderRadius: _dropdownMenuBorderRadius,
            style: _getDropDownItemStyle(),
            hint: Text(_selectedViewType.pillTitle, style: _getDropDownItemStyle()),
            items: _buildViewTypeDropDownItems(),
            onChanged: _onViewTypeDropDownValueChanged,
          ),
        )),
      ),
    );
  }

  List<DropdownMenuItem<_StudentCoursesViewType>> _buildViewTypeDropDownItems() {
    return _StudentCoursesViewType.values.map((_StudentCoursesViewType viewType) =>
      DropdownMenuItem<_StudentCoursesViewType>(
        value: viewType,
        child: Text(viewType.pillTitle, style: _getDropDownItemStyle(bold: (viewType == _selectedViewType))),
      )
    ).toList();
  }

  void _onViewTypeDropDownValueChanged(_StudentCoursesViewType? viewType) {
    if (viewType != null) {
      setStateIfMounted(() {
        Storage()._studentCoursesViewType = _selectedViewType = viewType;
      });
      Analytics().logPageWidget(_rawViewTypeContentWidget);
    }
  }

  Widget get _rawViewTypeContentWidget {
    switch (_selectedViewType) {
      case _StudentCoursesViewType.calendar:
        return StudentCoursesCalendarContentWidget(courses: _courses, analyticsFeature: widget.analyticsFeature);
      case _StudentCoursesViewType.list:
        return StudentCoursesListContentWidget(courses: _courses, analyticsFeature: widget.analyticsFeature);
      case _StudentCoursesViewType.map:
        return StudentCoursesMapContentWidget(courses: _courses, analyticsFeature: widget.analyticsFeature);
    }
  }

  BorderRadius get _dropdownMenuBorderRadius => BorderRadius.circular(8);
}

enum _StudentCoursesViewType { calendar, list, map }

extension _StudentCoursesViewTypeExt on _StudentCoursesViewType {
  String get pillTitle {
    switch (this) {
      case _StudentCoursesViewType.calendar: return Localization().getStringEx('panel.student_courses.view_type.calendar.pill.title', 'Calendar');
      case _StudentCoursesViewType.list: return Localization().getStringEx('panel.student_courses.view_type.list.pill.title', 'List');
      case _StudentCoursesViewType.map: return Localization().getStringEx('panel.student_courses.view_type.map.pill.title', 'Map');
    }
  }
}

extension _StorageStudentCoursesExt on Storage {
  _StudentCoursesViewType? get _studentCoursesViewType =>
    _StudentCoursesViewType.values.firstWhereOrNull((_StudentCoursesViewType type) => (type.name == studentCoursesViewType));
  set _studentCoursesViewType(_StudentCoursesViewType? value) => studentCoursesViewType = value?.name;
}
