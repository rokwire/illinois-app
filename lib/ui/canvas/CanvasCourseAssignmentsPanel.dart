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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class CanvasCourseAssignmentsPanel extends StatefulWidget {
  final int courseId;
  CanvasCourseAssignmentsPanel({required this.courseId});

  @override
  _CanvasCourseAssignmentsPanelState createState() => _CanvasCourseAssignmentsPanelState();
}

class _CanvasCourseAssignmentsPanelState extends State<CanvasCourseAssignmentsPanel> {
  Map<String, List<CanvasAssignment>?>? _dueAssignmentsMap;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
          context: context,
          titleWidget: Text(Localization().getStringEx('panel.canvas_assignments.header.title', 'Assignments'),
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0))),
      body: _buildContent(),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingContent();
    }
    if (_dueAssignmentsMap != null) {
      if (_dueAssignmentsMap!.keys.isNotEmpty) {
        return _buildAssignmentsContent();
      } else {
        return _buildEmptyContent();
      }
    } else {
      return _buildErrorContent();
    }
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
                style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18))));
  }

  Widget _buildEmptyContent() {
    return Center(
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text(Localization().getStringEx('panel.canvas_assignments.empty.msg', 'There are no assignments for this course.'),
                textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18))));
  }

  Widget _buildAssignmentsContent() {
    List<Widget> assignmentWidgetList = [];
    if ((_dueAssignmentsMap == null) || (CollectionUtils.isEmpty(_dueAssignmentsMap!.keys))) {
      return Container();
    }
    for (String assignmentDueLabel in _dueAssignmentsMap!.keys) {
      assignmentWidgetList.add(_buildDueAssignmentLabelWidget(assignmentDueLabel));
      List<CanvasAssignment>? assignments = _dueAssignmentsMap![assignmentDueLabel];
      if (CollectionUtils.isNotEmpty(assignments)) {
        for (CanvasAssignment assignment in assignments!) {
          assignmentWidgetList.add(_buildAssignmentItem(assignment));
        }
      }
    }

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: assignmentWidgetList)));
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
                        style: TextStyle(fontSize: 18, color: Colors.black, fontFamily: Styles().fontFamilies!.bold)))
              ])
            ])));
  }

  Widget _buildAssignmentItem(CanvasAssignment assignment) {
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
                        style: TextStyle(
                            fontSize: 18, color: Styles().colors!.fillColorPrimaryVariant, fontFamily: Styles().fontFamilies!.bold)))
              ]),
              Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Row(children: [
                    Text(Localization().getStringEx('panel.canvas_assignments.due.label', 'Due'),
                        style: TextStyle(fontSize: 14, color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold)),
                    Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Text(StringUtils.ensureNotEmpty(assignment.dueDisplayDateTime),
                            style: TextStyle(
                                fontSize: 14, color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.regular)))
                  ]))
            ])));
  }

  void _onTapAssignment(CanvasAssignment assignment) {
    Analytics().logSelect(target: 'Canvas Assignment');
    String? url = assignment.htmlUrl;
    if (StringUtils.isNotEmpty(url)) {
      if (UrlUtils.launchInternal(url)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        launch(url!);
      }
    }
  }

  void _loadAssignments() {
    _increaseProgress();
    Canvas().loadAssignmentGroups(widget.courseId).then((assignmentGroups) {
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

        _dueAssignmentsMap = {
          Localization().getStringEx('panel.canvas_assignments.upcoming.label', 'Upcoming Assignments'): upcomingAssignments,
          Localization().getStringEx('panel.canvas_assignments.past.label', 'Past Assignments'): pastAssignments
        };
      } else {
        _dueAssignmentsMap = null;
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
}
