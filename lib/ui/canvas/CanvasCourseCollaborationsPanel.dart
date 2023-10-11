/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CanvasCourseCollaborationsPanel extends StatefulWidget {
  final int courseId;
  CanvasCourseCollaborationsPanel({required this.courseId});

  @override
  _CanvasCourseCollaborationsPanelState createState() => _CanvasCourseCollaborationsPanelState();
}

class _CanvasCourseCollaborationsPanelState extends State<CanvasCourseCollaborationsPanel> {
  Map<int, List<CanvasCollaboration>?>? _courseCollaborationsMap;
  List<CanvasCourse>? _courses;
  int? _selectedCourseId;
  int _collaborationsCount = 0;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.courseId;
    _courses = Canvas().courses;
    _loadCollaborations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.canvas_collaborations.header.title', 'Collaborations'),
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
      if (_courseCollaborationsMap != null) {
        if (_hasCollaborations) {
          contentWidget = _buildCollaborationsContent();
        } else {
          contentWidget = _buildEmptyContent();
        }
      } else {
        contentWidget = _buildErrorContent();
      }
    }

    return Column(children: [Padding(padding: EdgeInsets.all(16), child: _buildCourseDropDownWidget()), Expanded(child: contentWidget)]);
  }

  Widget _buildLoadingContent() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorContent() {
    return Center(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 28), child: Text(Localization().getStringEx('panel.canvas_collaborations.load.failed.error.msg', 'Failed to load collaborations. Please, try again later.'),
            textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildEmptyContent() {
    return Center(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 28), child: Text(Localization().getStringEx('panel.canvas_collaborations.empty.msg', 'There are no collaborations.'),
            textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildCollaborationsContent() {
    if (CollectionUtils.isEmpty(_courseCollaborationsMap?.values)) {
      return Container();
    }

    List<Widget> collaborationWidgetList = [];
    bool showCourseLabel = (_selectedCourseId == null);
    for (int courseId in _courseCollaborationsMap!.keys) {
      CanvasCourse? course = _getCurrentCourse(courseId: courseId);
      if (course != null) {
        if (showCourseLabel) {
          collaborationWidgetList.add(_buildCourseLabelWidget(course.name));
        }
        List<CanvasCollaboration>? collaborations = _courseCollaborationsMap![course.id];
        for (CanvasCollaboration collaboration in collaborations!) {
          collaborationWidgetList.add(_buildCollaborationWidget(collaboration));
        }
      }
    }

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: collaborationWidgetList)));
  }
  
  Widget _buildCourseLabelWidget(String? label) {
    return Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Container(
            decoration: BoxDecoration(
                color: Styles().colors!.backgroundVariant!, border: Border.all(color: Styles().colors!.blackTransparent06!, width: 1)),
            padding: EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Text(StringUtils.ensureNotEmpty(label),
                        style: Styles().textStyles?.getTextStyle("widget.description.dark.medium.fat")))
              ])
            ])));
  }

  Widget _buildCollaborationWidget(CanvasCollaboration collaboration) {
    return Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: GestureDetector(
            onTap: () => _onTapCollaboration(collaboration),
            child: Container(
                decoration: BoxDecoration(
                    color: Styles().colors!.white!,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Styles().colors!.lightGray!, width: 1),
                    boxShadow: [
                      BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))
                    ]),
                padding: EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(StringUtils.ensureNotEmpty(collaboration.title),
                        style: Styles().textStyles?.getTextStyle("panel.canvas.text.medium")),
                    Text(StringUtils.ensureNotEmpty(collaboration.createdAtDisplayDate),
                        style:Styles().textStyles?.getTextStyle("widget.info.small"))
                  ]),
                  Visibility(
                      visible: StringUtils.isNotEmpty(collaboration.userName),
                      child: Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(StringUtils.ensureNotEmpty(collaboration.userName),
                              style: Styles().textStyles?.getTextStyle("widget.info.small"))))
                ]))));
  }

  void _onTapCollaboration(CanvasCollaboration collaboration) {
    //TBD: implement when we know how to do it.
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
              style: (_selectedCourseId == currentCourse.id) ? Styles().textStyles?.getTextStyle("panel.canvas.item.regular.fat") :  Styles().textStyles?.getTextStyle("panel.canvas.item.regular"))));
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
      _loadCollaborations();
    }
  }

  void _loadCollaborations() {
    if (_courseCollaborationsMap != null) {
      _courseCollaborationsMap = null;
      _collaborationsCount = 0;
    }
    if (_selectedCourseId != null) {
      _loadCollaborationsForSingleCourse(_selectedCourseId!);
    } else {
      _loadCollaborationsForAllCourses();
    }
  }

  void _loadCollaborationsForSingleCourse(int courseId) {
    _increaseProgress();
    Canvas().loadCollaborations(courseId).then((collaborations) {
      if (collaborations != null) {
        if (_courseCollaborationsMap == null) {
          _courseCollaborationsMap = HashMap();
        }
        _courseCollaborationsMap![courseId] = collaborations;
        _collaborationsCount += collaborations.length;
      }
      _decreaseProgress();
    });
  }

  void _loadCollaborationsForAllCourses() {
    if (CollectionUtils.isNotEmpty(_courses)) {
      for (CanvasCourse course in _courses!) {
        _loadCollaborationsForSingleCourse(course.id!);
      }
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

  bool get _hasCollaborations {
    return (_collaborationsCount > 0);
  }
}