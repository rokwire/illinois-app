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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Canvas.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/StudentCourse.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Map2.dart';
import 'package:illinois/ui/canvas/CanvasCourseAssignmentsPanel.dart';
import 'package:illinois/ui/explore/DisplayFloorPlanPanel.dart';
import 'package:illinois/ui/map2/Map2HomePanel.dart';
import 'package:illinois/ui/map2/Map2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class StudentCourseDetailPanel extends StatefulWidget with AnalyticsInfo {
  final StudentCourse? course;
  final AnalyticsFeature? analyticsFeature;

  StudentCourseDetailPanel({super.key, this.course, this.analyticsFeature});
  @override
  _StudentCourseDetailPanelState createState() => _StudentCourseDetailPanelState();
}
class _StudentCourseDetailPanelState extends State<StudentCourseDetailPanel> {
  bool _floorsPlansExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _buildContent(),
        backgroundColor: Styles().colors.white,
        bottomNavigationBar: uiuc.TabBar()
    );
  }

  Widget _buildContent() {
    return Column(children: <Widget>[
      Expanded(child:
        Container(child:
          CustomScrollView(scrollDirection: Axis.vertical, slivers: <Widget>[
            SliverToutHeaderBar(
              flexRightToLeftTriangleColor: Colors.white,
              flexImageKey: 'course-detail-default',
            ),
            SliverList(delegate: SliverChildListDelegate([
              Container(color: Colors.white, padding:EdgeInsets.symmetric(horizontal: 20), child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  _buildTitle(),

                  if ((widget.course?.displayInfo.isNotEmpty == true) || (widget.course?.displayInfo.isNotEmpty == true))
                    ...<Widget>[
                      Container(height: 12),
                      if (widget.course?.displayInfo.isNotEmpty == true)
                        _buildDisplayInfo(),
                      if (widget.course?.section?.instructor?.isNotEmpty == true)
                        _buildInstructor(),
                    ],

                  Container(height: 18),

                  if (widget.course?.section?.displaySchedule.isNotEmpty == true)
                    _buildScheduleDetail(),

                  if ((widget.course?.section?.isInPerson == true) && (widget.course?.section?.building?.fullAddress?.isNotEmpty == true))
                    _buildLocation(),

                  if ((widget.course?.section?.isInPerson == true) && (widget.course?.section?.building?.floors?.isNotEmpty == true))
                    _buildFloorPlans(),

                  if ((widget.course?.section?.isInPerson == true) && (widget.course?.hasValidLocation == true))
                    _buildNavDirections(),

                  if (_canvasVisible)
                    _buildCanvasContent(),

                  Container(height: 32),

                  if (widget.course?.section?.isInPerson == true)
                    _buildInPersonMapButton(),

                ])
              )
            ], addSemanticIndexes:false),),
          ],),
        ),
      ),
    ],);
  }

  Widget _buildTitle() =>
      Text(widget.course?.title ?? "", style: Styles().textStyles.getTextStyle("widget.title.medium_large.fat"));

  Widget _buildDisplayInfo() =>
      Text(widget.course?.displayInfo ?? "", style: Styles().textStyles.getTextStyle("widget.item.regular.thin"));

  Widget _buildInstructor() =>
      Text(sprintf(Localization().getStringEx('panel.student_courses.instructor.title', 'Instructor: %s'), [widget.course?.section?.instructor ?? '']), style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),);

  Widget _buildScheduleDetail() =>
    Padding(padding: EdgeInsets.symmetric(vertical: 6), child:
      Row(children: [
        _buildDetailIcon('calendar'),
        Expanded(child:
          Text(widget.course?.section?.displaySchedule ?? '', style: Styles().textStyles.getTextStyle("widget.item.regular.thin")),
        )
      ],),
    );

  Widget _buildLocation() =>
    InkWell(onTap: (widget.course?.hasValidLocation ?? false) ? _onLocation : null, child:
      Padding(padding: EdgeInsets.symmetric(vertical: 6,), child:
        Row(children: [
          _buildDetailIcon('location'),
          Expanded(child:
            Text(widget.course?.section?.building?.fullAddress ?? '', style: (widget.course?.hasValidLocation ?? false) ?
              Styles().textStyles.getTextStyle("widget.button.light.title.medium.underline") :
              Styles().textStyles.getTextStyle("widget.button.light.title.medium")
            ),
          )
        ],),
      ),
    );


  Widget _buildNavDirections() =>
      Padding(padding: EdgeInsets.symmetric(vertical: 6,), child:
        Row(children: [
          _buildDetailIcon(),
          Expanded(child:
            Wrap(spacing: 8, runSpacing: 8, children: [
              Map2NavDirectionsButton('person-walking', onTap: () => _onNavigationDirections(GeoMapUtils.traveModeWalking)),
              Map2NavDirectionsButton('bicycle', onTap: () => _onNavigationDirections(GeoMapUtils.traveModeBycycling)),
              Map2NavDirectionsButton('car', onTap: () => _onNavigationDirections(GeoMapUtils.traveModeDriving)),
              Map2NavDirectionsButton('bus', onTap: () => _onNavigationDirections(GeoMapUtils.traveModeTransit)),
            ],),
          )
        ],),
      );

  Widget _buildFloorPlans() {
    String? room = widget.course?.section?.room;
    String displayRoom = ((room != null) && room.isNotEmpty) ? room : Localization().getStringEx('panel.student_courses.room.title', 'Room');
    List<String> floors = widget.course?.section?.building?.floors ?? [];
    return Padding(padding: EdgeInsets.symmetric(), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(onTap: _onFloorsPlans, child:
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child:
            Row(children: [
              _buildDetailIcon(_floorsPlansExpanded ? 'chevron-up' : 'chevron-down'),
              Text("Room ${displayRoom}", style: Styles().textStyles.getTextStyle("widget.button.light.title.medium.underline"))
            ]),
          ),
        ),
        Visibility(visible: _floorsPlansExpanded, child:
          Row(children: [
            _buildDetailIcon(),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("${Localization().getStringEx('panel.explore_building_detail.detail.fllor_plan_and_amenities', 'Floor Plans & Amenities')}:", style: Styles().textStyles.getTextStyle('widget.button.light.title.medium.fat')),
              ...floors.map((floor) => InkWell(onTap: () => _onFloor(floor), child:
                Padding(padding: EdgeInsets.symmetric(vertical: 2), child:
                  Text("Floor ${floor}", style: Styles().textStyles.getTextStyle("widget.description.small.underline")))
              )).toList()
            ])
          ]),
        )
      ])
    );
  }

  Widget _buildDetailIcon([String? iconKey]) =>
      Padding(padding: EdgeInsets.only(right: 8), child:
        SizedBox(width: 18, height: 18, child:
          Center(child: (iconKey != null) ?
            Styles().images.getImage(iconKey, excludeFromSemantics: true) : null
          )
        )
      );

  Widget _buildInPersonMapButton() =>
      Padding(padding: EdgeInsets.symmetric(horizontal: 18 + 8), child:
        RoundedButton(
          label: Localization().getStringEx('panel.student_courses.map.button.title', 'View In-Person Courses on Map'),
          textStyle: Styles().textStyles.getTextStyle('widget.button.title.medium.fat'),
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          onTap: _onMap,
        ),
      );

  Widget _buildCanvasContent() {
    return Padding(padding: EdgeInsets.only(top: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(height: 1, color: Styles().colors.surfaceAccent2,),
      _buildCanvasButton(label: Localization().getStringEx('panel.student_courses.canvas.assignments.view.label', 'Canvas Assignments'), onTap: _onCanvasAssignments),
      _buildCanvasButton(label: Localization().getStringEx('panel.student_courses.canvas.launch.view.label', 'Launch Canvas'), onTap: _onCanvasLaunch),
    ],),);
  }

  Widget _buildCanvasButton({required String label, required void Function() onTap}) {
    return GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(top: 16),
          child: Row(
            children: [
              _buildDetailIcon('canvas'),
              Expanded(
                child: Text(label, style: Styles().textStyles.getTextStyle("widget.button.light.title.medium.underline")),
              ),
            ],
          ),
        ));
  }

  void _onLocation() {
    Analytics().logSelect(target: "Location Directions");
    widget.course?.launchDirections();
  }

  void _onNavigationDirections(String travelMode) {
    Analytics().logSelect(target: 'Navigation Directions: $travelMode');
    widget.course?.launchDirections(travelMode: travelMode);
    //GeoMapUtils.launchDirections(destination: widget.course?.section?.building?.exploreLocation?.exploreLocationMapCoordinate, travelMode: travelMode);
  }

  void _onFloor(String floor) {
    Analytics().logSelect(target: "Floor Plan");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DisplayFloorPlanPanel(building: widget.course?.section?.building, startingFloor: floor)));
  }

  void _onFloorsPlans() {
    Analytics().logSelect(target: "Toggle Floor Plan & Amenities");
    setState(() {
      _floorsPlansExpanded = !_floorsPlansExpanded;
    });
  }

  void _onCanvasAssignments() {
    Analytics().logSelect(target: 'Canvas Assignments');
    int? courseId = _canvasCourse?.id;
    if (courseId != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCourseAssignmentsPanel(courseId: courseId, analyticsFeature: widget.analyticsFeature)));
    }
  }

  void _onCanvasLaunch() async {
    Analytics().logSelect(target: 'Launch Canvas');
    String? courseDeepLinkFormat = Config().canvasCourseDeepLinkFormat;
    String? courseDeepLink = StringUtils.isNotEmpty(courseDeepLinkFormat) ? sprintf(courseDeepLinkFormat!, [_canvasCourse?.id]) : null;
    if (StringUtils.isNotEmpty(courseDeepLink)) {
      await Canvas().openCanvasAppDeepLink(courseDeepLink!);
    }
  }

  void _onMap() {
    Analytics().logSelect(target: "View on Map");
    NotificationService().notify(Map2.notifySelect, Map2ContentType.StudentCourses);
  }

  String? get _courseNumber => widget.course?.number;

  bool get _canvasVisible => (_canvasCourse != null);

  ///
  /// #5584:
  /// "the coursenumber property coming from the gatway building block should match the CRN of the canvas course."
  ///
  CanvasCourse? get _canvasCourse => (_courseNumber != null) ?
    Canvas().courses?.firstWhereOrNull((item) => (item.crn == _courseNumber)) :
    null;
}