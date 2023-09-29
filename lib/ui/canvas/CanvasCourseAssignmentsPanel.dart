/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
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

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class CanvasCourseAssignmentsPanel extends StatefulWidget {
  final int courseId;
  CanvasCourseAssignmentsPanel({required this.courseId});

  @override
  _CanvasCourseAssignmentsPanelState createState() => _CanvasCourseAssignmentsPanelState();
}

class _CanvasCourseAssignmentsPanelState extends State<CanvasCourseAssignmentsPanel> {
  Map<int, Map<String, List<CanvasAssignment>?>?>? _courseDueAssignmentsMap;
  List<CanvasCourse>? _courses;
  int? _selectedCourseId;
  int _assignmentsCount = 0;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.courseId;
    _courses = Canvas().courses;
    _loadAssignments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.canvas_assignments.header.title', 'Assignments'),
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    late Widget contentWidget;
    if (_isLoading) {
      contentWidget = _buildLoadingContent();
    } else {
      if (_courseDueAssignmentsMap != null) {
        if (_hasAssignments) {
          contentWidget = _buildAssignmentsContent();
        } else {
          contentWidget = _buildEmptyContent();
        }
      } else {
        contentWidget = _buildErrorContent();
      }
    }

    return Column(
        children: [Padding(padding: EdgeInsets.all(16), child: _buildCourseDropDownWidget()), Expanded(child: contentWidget)]);
  }

  Widget _buildLoadingContent() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorContent() {
    return Center(
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text(
                Localization()
                    .getStringEx('panel.canvas_assignments.load.failed.error.msg', 'Failed to load assignments. Please, try again later.'),
                textAlign: TextAlign.center,
                style:  Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildEmptyContent() {
    return Center(
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text(Localization().getStringEx('panel.canvas_assignments.empty.msg', 'There are no assignments.'),
                textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildAssignmentsContent() {
    if ((_courseDueAssignmentsMap == null) || (CollectionUtils.isEmpty(_courseDueAssignmentsMap!.keys))) {
      return Container();
    }

    List<Widget> assignmentWidgetList = [];
    bool showCourseLabel = (_selectedCourseId == null);
    for (int courseId in _courseDueAssignmentsMap!.keys) {
      CanvasCourse? course = _getCurrentCourse(courseId: courseId);
      if (course != null) {
        if (showCourseLabel) {
          assignmentWidgetList.add(_buildCourseLabelWidget(course.name));
        }

        Map<String, List<CanvasAssignment>?>? dueAssignmentsMap = _courseDueAssignmentsMap![courseId];
        if ((dueAssignmentsMap != null) && CollectionUtils.isNotEmpty(dueAssignmentsMap.keys)) {
          for (String assignmentDueLabel in dueAssignmentsMap.keys) {
            List<CanvasAssignment>? assignments = dueAssignmentsMap[assignmentDueLabel];
            if (CollectionUtils.isNotEmpty(assignments)) {
              assignmentWidgetList.add(_buildDueAssignmentLabelWidget(assignmentDueLabel));
              for (CanvasAssignment assignment in assignments!) {
                assignmentWidgetList.add(_buildAssignmentItem(assignment));
              }
            }
          }
        }
      }
    }

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: assignmentWidgetList)));
  }
  
  Widget _buildCourseLabelWidget(String? label) {
    return Padding(
        padding: EdgeInsets.only(top: 16, bottom: 10),
        child: Container(
            decoration: BoxDecoration(
                color: Styles().colors!.backgroundVariant!, border: Border.all(color: Styles().colors!.blackTransparent06!, width: 1)),
            padding: EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Text(StringUtils.ensureNotEmpty(label),
                        style: Styles().textStyles?.getTextStyle("widget.message.dark.semi_large.fat")))
              ])
            ])));
  }

  Widget _buildDueAssignmentLabelWidget(String label) {
    return Padding(
        padding: EdgeInsets.only(top: 16),
        child: Container(
            decoration: BoxDecoration(
                color: Styles().colors!.backgroundVariant!, border: Border.all(color: Styles().colors!.blackTransparent06!, width: 1)),
            padding: EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Text(StringUtils.ensureNotEmpty(label),
                        style: Styles().textStyles?.getTextStyle("widget.message.dark.semi_large.fat") ))
              ])
            ])));
  }

  Widget _buildAssignmentItem(CanvasAssignment assignment) {
    String displayDueDate = StringUtils.ensureNotEmpty(assignment.dueDisplayDateTime);
    String displaySubmittedDate = StringUtils.ensureNotEmpty(assignment.submittedDisplayDateTime);
    BorderSide borderSide = BorderSide(color: Styles().colors!.blackTransparent06!, width: 1);
    return GestureDetector(
        onTap: () => _onTapAssignment(assignment),
        child: Container(
            decoration:
                BoxDecoration(color: Styles().colors!.white!, border: Border(left: borderSide, right: borderSide, bottom: borderSide)),
            padding: EdgeInsets.only(left: 30, top: 10, right: 10, bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Text(StringUtils.ensureNotEmpty(assignment.name),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: Styles().textStyles?.getTextStyle("panel.canvas.text.medium.fat")))
              ]),
              Visibility(
                  visible: StringUtils.isNotEmpty(displayDueDate),
                  child: Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Row(children: [
                        Text(Localization().getStringEx('panel.canvas_assignments.due.label', 'Due:'),
                            style:
    Styles().textStyles?.getTextStyle("widget.title.small.fat")),
                        Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Text(displayDueDate,
                                style: Styles().textStyles?.getTextStyle("widget.title.small")))
                      ]))),
              Visibility(
                  visible: StringUtils.isNotEmpty(displaySubmittedDate),
                  child: Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Row(children: [
                        Text(Localization().getStringEx('panel.canvas_assignments.submitted.label', 'Submitted:'),
                            style: Styles().textStyles?.getTextStyle("panel.canvas.text.small.accent")),
                        Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Text(displaySubmittedDate,
                                style: Styles().textStyles?.getTextStyle("panel.canvas.text.small.accent")))
                      ])))
            ])));
  }

  void _onTapAssignment(CanvasAssignment assignment) async {
    Analytics().logSelect(target: 'Canvas Assignment');
    String? assignmentDeepLinkFormat = Config().canvasAssignmentDeepLinkFormat;
    String? assignmentDeepLink =
        StringUtils.isNotEmpty(assignmentDeepLinkFormat) ? sprintf(assignmentDeepLinkFormat!, [assignment.courseId, assignment.id]) : null;
    if (StringUtils.isNotEmpty(assignmentDeepLink)) {
      await Canvas().openCanvasAppDeepLink(assignmentDeepLink!);
    }
  }
  
  Widget _buildCourseDropDownWidget() {
    double height = MediaQuery.of(context).textScaleFactor * 62;
    return Container(
        height: height,
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Styles().colors!.lightGray!, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(4))),
        child: Padding(
            padding: EdgeInsets.only(left: 10),
            child: DropdownButtonHideUnderline(
                child: DropdownButton(
                    style: Styles().textStyles?.getTextStyle("panel.canvas.item.regular.fat"),
                    items: _buildCourseDropDownItems,
                    value: _selectedCourseId,
                    itemHeight: null,
                    isExpanded: true,
                    onChanged: (courseId) => _onCourseIdChanged(courseId)))));
  }

  List<DropdownMenuItem<int>>? get _buildCourseDropDownItems {
    if(CollectionUtils.isEmpty(_courses)) {
      return null;
    }
    List<DropdownMenuItem<int>> items = [];
    CanvasCourse? currentCourse = _getCurrentCourse(courseId: widget.courseId);
    if (currentCourse != null) {
      items.add(DropdownMenuItem(
          value: currentCourse.id,
          child: Text(StringUtils.ensureNotEmpty(currentCourse.name),
              style: (_selectedCourseId == currentCourse.id) ? Styles().textStyles?.getTextStyle("panel.canvas.item.regular.fat") :  Styles().textStyles?.getTextStyle("panel.canvas.item.regular")
              )));
    }
    items.add(DropdownMenuItem(
        value: null,
        child: Text(Localization().getStringEx('panel.canvas.common.all_courses.label', 'All Courses'),
            style: (_selectedCourseId == null) ? Styles().textStyles?.getTextStyle("panel.canvas.item.regular.fat") :  Styles().textStyles?.getTextStyle("panel.canvas.item.regular"))));
    return items;
  }

  CanvasCourse? _getCurrentCourse({int? courseId}) {
    CanvasCourse? selectedCourse;
    if (CollectionUtils.isNotEmpty(_courses)) {
      for (CanvasCourse course in _courses!) {
        if (course.id == courseId) {
          selectedCourse = course;
          break;
        }
      }
    }
    return selectedCourse;
  }

  void _onCourseIdChanged(dynamic courseId) {
    if (_selectedCourseId != courseId) {
      _selectedCourseId = courseId;
      _loadAssignments();
    }
  }

  void _loadAssignments() {
    if (_courseDueAssignmentsMap != null) {
      _courseDueAssignmentsMap = null;
      _assignmentsCount = 0;
    }
    if (_selectedCourseId != null) {
      _loadAssignmentsForSingleCourse(_selectedCourseId!);
    } else {
      _loadAssignmentsForAllCourses();
    }
  }

  void _loadAssignmentsForAllCourses() {
    if (CollectionUtils.isNotEmpty(_courses)) {
      for (CanvasCourse course in _courses!) {
        _loadAssignmentsForSingleCourse(course.id!);
      }
    }
  }

  void _loadAssignmentsForSingleCourse(int courseId) {
    _increaseProgress();
    Canvas().loadAssignmentGroups(courseId).then((assignmentGroups) {
      DateTime now = DateTime.now().toUtc();
      if (CollectionUtils.isNotEmpty(assignmentGroups)) {
        List<CanvasAssignment> upcomingAssignments = [];
        List<CanvasAssignment> pastAssignments = [];
        for (CanvasAssignmentGroup group in assignmentGroups!) {
          List<CanvasAssignment>? groupAssignments = group.assignments;
          if (CollectionUtils.isNotEmpty(groupAssignments)) {
            for (CanvasAssignment assignment in groupAssignments!) {
              if (assignment.dueAt?.isBefore(now) ?? false) {
                pastAssignments.add(assignment);
              } else {
                upcomingAssignments.add(assignment);
              }
            }
          }
        }
        _sortAssignments(upcomingAssignments);
        _sortAssignments(pastAssignments, reverse: true);
        _assignmentsCount += upcomingAssignments.length;
        _assignmentsCount += pastAssignments.length;

        if (_courseDueAssignmentsMap == null) {
          _courseDueAssignmentsMap = HashMap();
        }

        Map<String, List<CanvasAssignment>> dueAssignmentsMap = {
          Localization().getStringEx('panel.canvas_assignments.upcoming.label', 'Upcoming Assignments'): upcomingAssignments,
          Localization().getStringEx('panel.canvas_assignments.past.label', 'Past Assignments'): pastAssignments
        };

        _courseDueAssignmentsMap![courseId] = dueAssignmentsMap;
      }
      _decreaseProgress();
    });
  }

  void _sortAssignments(List<CanvasAssignment>? assignments, {bool reverse = false}) {
    if (CollectionUtils.isNotEmpty(assignments)) {
      assignments!.sort((CanvasAssignment first, CanvasAssignment second) {
        DateTime? firstDate = reverse ? second.dueAt : first.dueAt;
        DateTime? secondDate = reverse ? first.dueAt : second.dueAt;
        if ((firstDate != null) && (secondDate != null)) {
          int compare = firstDate.compareTo(secondDate);
          if (compare == 0) {
            return (first.position ?? 0).compareTo(second.position ?? 0);
          } else {
            return compare;
          }
        } else if (firstDate != null) {
          return -1;
        } else if (secondDate != null) {
          return 1;
        } else {
          return 0;
        }
      });
    }
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

  bool get _hasAssignments {
    return (_assignmentsCount > 0);
  }
}
