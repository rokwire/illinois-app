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
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/canvas/CanvasAnnouncementDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CanvasCourseAnnouncementsPanel extends StatefulWidget {
  final int courseId;
  CanvasCourseAnnouncementsPanel({required this.courseId});

  @override
  _CanvasCourseAnnouncementsPanelState createState() => _CanvasCourseAnnouncementsPanelState();
}

class _CanvasCourseAnnouncementsPanelState extends State<CanvasCourseAnnouncementsPanel> {
  Map<int, List<CanvasDiscussionTopic>?>? _courseAnnouncementsMap;
  List<CanvasCourse>? _courses;
  int? _selectedCourseId;
  int _announcementsCount = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.courseId;
    _courses = Canvas().courses;
    _loadAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.canvas_announcements.header.title', 'Announcements'),
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
      if (_courseAnnouncementsMap != null) {
        if (_hasAnnouncements) {
          contentWidget = _buildAnnouncementsContent();
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
                Localization().getStringEx(
                    'panel.canvas_announcements.load.failed.error.msg', 'Failed to load announcements. Please, try again later.'),
                textAlign: TextAlign.center,
                style: Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildEmptyContent() {
    return Center(
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text(Localization().getStringEx('panel.canvas_announcements.empty.msg', 'There are no announcements.'),
                textAlign: TextAlign.center, style:  Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildAnnouncementsContent() {
    if (CollectionUtils.isEmpty(_courseAnnouncementsMap?.values)) {
      return Container();
    }

    List<Widget> announcementWidgetList = [];
    bool showCourseLabel = (_selectedCourseId == null);
    for (int courseId in _courseAnnouncementsMap!.keys) {
      CanvasCourse? course = _getCurrentCourse(courseId: courseId);
      if (course != null) {
        if (showCourseLabel) {
          announcementWidgetList.add(_buildCourseLabelWidget(course.name));
        }
        List<CanvasDiscussionTopic>? announcements = _courseAnnouncementsMap![course.id];
        for (CanvasDiscussionTopic announcement in announcements!) {
          announcementWidgetList.add(_buildAnnouncementItem(announcement));
        }
      }
    }

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: announcementWidgetList)));
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
                        style: Styles().textStyles?.getTextStyle("widget.message.dark.semi_large.fat")))
              ])
            ])));
  }

  Widget _buildAnnouncementItem(CanvasDiscussionTopic announcement) {
    return Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: GestureDetector(
            onTap: () => _onTapAnnouncement(announcement),
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
                  Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(
                        child: Text(StringUtils.ensureNotEmpty(announcement.title),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Styles().textStyles?.getTextStyle("panel.canvas.text.medium"))),
                    Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Text(StringUtils.ensureNotEmpty(announcement.postedAtDisplayDate),
                            style: Styles().textStyles?.getTextStyle("widget.info.small")))
                  ]),
                  Visibility(
                      visible: StringUtils.isNotEmpty(announcement.author?.displayName),
                      child: Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(StringUtils.ensureNotEmpty(announcement.author?.displayName),
                              style: Styles().textStyles?.getTextStyle("widget.info.small")))),
                  Visibility(
                      visible: StringUtils.isNotEmpty(announcement.message),
                      child: Html(data: announcement.message, style: {
                        "body": Style(
                            color: Styles().colors!.textSurfaceAccent,
                            fontFamily: Styles().fontFamilies!.bold,
                            fontSize: FontSize(16),
                            textOverflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            padding: EdgeInsets.zero,
                            margin: Margins.zero)
                      }))
                ]))));
  }

  void _onTapAnnouncement(CanvasDiscussionTopic announcement) {
    Analytics().logSelect(target: "Canvas Course -> Announcement");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasAnnouncementDetailPanel(announcement: announcement)));
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
            style:  (_selectedCourseId == null) ? Styles().textStyles?.getTextStyle("panel.canvas.item.regular.fat") :  Styles().textStyles?.getTextStyle("panel.canvas.item.regular"))));
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
      _loadAnnouncements();
    }
  }

  void _loadAnnouncements() {
    if (_courseAnnouncementsMap != null) {
      _courseAnnouncementsMap = null;
      _announcementsCount = 0;
    }
    if (_selectedCourseId != null) {
      _loadAnnouncementsForSingleCourse(_selectedCourseId!);
    } else {
      _loadAnnouncementsForAllCourses();
    }
  }

  void _loadAnnouncementsForSingleCourse(int courseId) {
    setStateIfMounted(() {
      _loading = true;
    });
    Canvas().loadAnnouncementsForCourse(courseId).then((announcements) {
      setStateIfMounted(() {
        _loading = false;
        if (announcements != null) {
          if (_courseAnnouncementsMap == null) {
            _courseAnnouncementsMap = HashMap();
          }
          _courseAnnouncementsMap![courseId] = announcements;
          _announcementsCount += announcements.length;
        }
      });
    });
  }

  void _loadAnnouncementsForAllCourses() {
    if (CollectionUtils.isNotEmpty(_courses)) {
      for (CanvasCourse course in _courses!) {
        _loadAnnouncementsForSingleCourse(course.id!);
      }
    }
  }

  bool get _hasAnnouncements {
    return (_announcementsCount > 0);
  }
}