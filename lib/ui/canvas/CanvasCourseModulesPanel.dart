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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/canvas/CanvasModuleDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CanvasCourseModulesPanel extends StatefulWidget {
  final int courseId;
  CanvasCourseModulesPanel({required this.courseId});

  @override
  _CanvasCourseModulesPanelState createState() => _CanvasCourseModulesPanelState();
}

class _CanvasCourseModulesPanelState extends State<CanvasCourseModulesPanel> {
  Map<int, List<CanvasModule>?>? _courseModulesMap;
  List<CanvasCourse>? _courses;
  int? _selectedCourseId;
  int _modulesCount = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.courseId;
    _courses = Canvas().courses;
    _loadModules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.canvas_modules.header.title', 'Modules')
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    late Widget contentWidget;
    if (_loading) {
      contentWidget = _buildLoadingContent();
    } else {
      if (_courseModulesMap != null) {
        if (_hasModules) {
          contentWidget = _buildModulesContent();
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
                    .getStringEx('panel.canvas_modules.load.failed.error.msg', 'Failed to load modules. Please, try again later.'),
                textAlign: TextAlign.center,
                style: Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildEmptyContent() {
    return Center(
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text(Localization().getStringEx('panel.canvas_modules.empty.msg', 'There are no modules.'),
                textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildModulesContent() {
    if (CollectionUtils.isEmpty(_courseModulesMap?.values)) {
      return Container();
    }

    List<Widget> moduleWidgetList = [];
    bool showCourseLabel = (_selectedCourseId == null);
    for (int courseId in _courseModulesMap!.keys) {
      CanvasCourse? course = _getCurrentCourse(courseId: courseId);
      if (course != null) {
        if (showCourseLabel) {
          moduleWidgetList.add(_buildCourseLabelWidget(course.name));
        }
        List<CanvasModule>? modules = _courseModulesMap![course.id];
        for (CanvasModule module in modules!) {
          moduleWidgetList.add(_buildModuleItem(module));
        }
      }
    }

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: moduleWidgetList)));
  }
  
  Widget _buildCourseLabelWidget(String? label) {
    return Padding(
        padding: EdgeInsets.only(bottom: 16, top: 10),
        child: Container(
            padding: EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Text(StringUtils.ensureNotEmpty(label),
                        style: Styles().textStyles?.getTextStyle("widget.title.medium.fat")))
              ])
            ])));
  }

  Widget _buildModuleItem(CanvasModule module) {
    return Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: GestureDetector(
            onTap: () => _onTapModule(module),
            child: Container(
                decoration: BoxDecoration(
                    color: Styles().colors!.backgroundVariant!, border: Border.all(color: Styles().colors!.blackTransparent06!, width: 1)),
                padding: EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                        child: Text(StringUtils.ensureNotEmpty(module.name),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: Styles().textStyles?.getTextStyle("panel.canvas.text.medium")))
                  ])
                ]))));
  }

  void _onTapModule(CanvasModule module) {
    Analytics().logSelect(target: 'Canvas Module');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasModuleDetailPanel(courseId: widget.courseId, module: module)));
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
              style: ((_selectedCourseId == currentCourse.id) ? Styles().textStyles?.getTextStyle("panel.canvas.item.regular.fat") :  Styles().textStyles?.getTextStyle("panel.canvas.item.regular")))));
    }
    items.add(DropdownMenuItem(
        value: null,
        child: Text(Localization().getStringEx('panel.canvas.common.all_courses.label', 'All Courses'),
            style: ((_selectedCourseId == null) ? Styles().textStyles?.getTextStyle("panel.canvas.item.regular.fat") :  Styles().textStyles?.getTextStyle("panel.canvas.item.regular")))));
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
      _loadModules();
    }
  }

  void _loadModules() {
    if (_courseModulesMap != null) {
      _courseModulesMap = null;
      _modulesCount = 0;
    }
    if (_selectedCourseId != null) {
      _loadModulesForSingleCourse(_selectedCourseId!);
    } else {
      _loadModulesForAllCourses();
    }
  }

  void _loadModulesForSingleCourse(int courseId) {
    setStateIfMounted(() {
      _loading = true;
    });
    Canvas().loadModules(courseId).then((modules) {
      setStateIfMounted(() {
        if (modules != null) {
          if (_courseModulesMap == null) {
            _courseModulesMap = HashMap();
          }
          _courseModulesMap![courseId] = modules;
          _modulesCount += modules.length;
        }
        _loading = false;
      });
    });
  }

  void _loadModulesForAllCourses() {
    if (CollectionUtils.isNotEmpty(_courses)) {
      for (CanvasCourse course in _courses!) {
        _loadModulesForSingleCourse(course.id!);
      }
    }
  }

  bool get _hasModules {
    return (_modulesCount > 0);
  }
}