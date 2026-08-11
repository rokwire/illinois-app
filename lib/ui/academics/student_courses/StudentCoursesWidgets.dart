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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/StudentCourse.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/academics/student_courses/StudentCourseDetailPanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/map2/Map2Widgets.dart';
import 'package:illinois/ui/widgets/AccentCard.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:sprintf/sprintf.dart';

class StudentCourseCard extends StatelessWidget {
   final StudentCourse course;
   final CardDisplayMode displayMode;
   final AnalyticsFeature? analyticsFeature;

   StudentCourseCard({super.key,
     required this.course,
     this.displayMode = CardDisplayMode.browse,
     this.analyticsFeature
   });

   static double height(BuildContext context) =>
     MediaQuery.of(context).textScaler.scale(36 + 18 + (6 + 16) + 16 + (6 + 18) + (12 + 18));

   @override
   Widget build(BuildContext context) =>
     InkWell(onTap: () => _onCard(context), child:
       Semantics(label: course.title,
         child: AccentCard(
           displayMode: displayMode,
           accentColor: Styles().colors.fillColorSecondary,
           child: _contentWidget,
         )
       ),
     );

   Widget get _contentWidget {
     String courseSchedule = course.section?.displaySchedule ?? '';
     String courseLocation = course.section?.displayLocation ?? '';

     return Padding(padding: EdgeInsets.all(16), child:
       Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

         Row(children: [Expanded(child:
           Text(course.title ?? '', style: Styles().textStyles.getTextStyle("widget.card.title.regular.extra_fat")),
         )]),

         Padding(padding: EdgeInsets.only(top: 6), child:
           Row(children: [
             Visibility(visible: (course.section?.isOnline == true), child:
               Padding(padding: EdgeInsets.only(right: 6), child:
                 Styles().images.getImage('laptop', excludeFromSemantics: true),
               ),
             ),
             Expanded(child:
               Text(course.displayInfo, style: Styles().textStyles.getTextStyle("widget.card.detail.medium")),
             ),
           ]),
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
           InkWell(onTap: course.hasValidLocation ? _onLocation : null, child:
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

         Visibility(visible: (course.section?.isInPerson == true) && course.hasValidLocation, child:
           Padding(padding: EdgeInsets.symmetric(vertical: 6), child:
             Row(children: [
               Padding(padding: EdgeInsets.only(right: 6), child:
                 Opacity(opacity: 0, child:
                   Styles().images.getImage('location', excludeFromSemantics: true),
                 )
               ),
               Expanded(child:
                 Wrap(spacing: 8, runSpacing: 8, children: [
                   Map2NavDirectionsButton('person-walking', onTap: () => _onNavigationDirections(GeoMapUtils.traveModeWalking)),
                   Map2NavDirectionsButton('bicycle', onTap: () => _onNavigationDirections(GeoMapUtils.traveModeBycycling)),
                   Map2NavDirectionsButton('car', onTap: () => _onNavigationDirections(GeoMapUtils.traveModeDriving)),
                   Map2NavDirectionsButton('bus', onTap: () => _onNavigationDirections(GeoMapUtils.traveModeTransit)),
                 ],),
               )
             ],),
           ),
         ),
       ],)
     );
   }

   void _onLocation() {
     Analytics().logSelect(target: "Location Detail");
     course.launchDirections();
   }

   void _onNavigationDirections(String travelMode) {
     Analytics().logSelect(target: 'Navigation Directions: $travelMode');
     course.launchDirections(travelMode: travelMode);
     //GeoMapUtils.launchDirections(destination: course?.section?.building?.exploreLocation?.exploreLocationMapCoordinate, travelMode: travelMode);
   }

   void _onCard(BuildContext context) {
     Analytics().logSelect(target: "Student Course: ${course.title}");
     Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentCourseDetailPanel(course: course, analyticsFeature: analyticsFeature,)));
   }

 }