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
import 'package:geolocator/geolocator.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/model/Appointment.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ui/academics/StudentCourses.dart';
import 'package:illinois/ui/explore/ExploreMapPanel.dart';
import 'package:illinois/ui/home/HomeLaundryWidget.dart';
import 'package:illinois/ui/mtd/MTDStopDeparturesPanel.dart';
import 'package:illinois/ui/mtd/MTDWidgets.dart';
import 'package:illinois/ui/appointments/AppointmentCard.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ExploreListPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final List<Explore>? explores;
  final ExploreMapType? exploreMapType;
  final Position? initialLocationData;

  ExploreListPanel({this.explores, this.exploreMapType, this.initialLocationData});

  @override
  _ExploreListPanelState createState() =>
      _ExploreListPanelState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes {
    if ((explores != null) && explores!.isNotEmpty) {
      return { Analytics.LogAttributeLocation : explores!.first.exploreLocation?.description };
    }
    else {
      return null;
    }

  }
}

class _ExploreListPanelState extends State<ExploreListPanel> implements NotificationsListener {

  List<Explore>? _explores;
  Set<String> _mtdExpanded = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.explores != null) {
      _explores = widget.explores;
      //Sort "only for when we go to details from map view and there is a list of items because of the map grouping"
      SortUtils.sort(_explores);
    }
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.explore_list.header.title", "Explore"),
      ),
      body: _buildBody(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildBody() {
    return Column(children: <Widget>[
      Expanded(child:
        Padding(padding: EdgeInsets.zero, child:
          CollectionUtils.isNotEmpty(_explores) ? ListView.separated(
            separatorBuilder: (context, index) => Container(),
            itemCount: _explores!.length,
            itemBuilder: (context, index) => _exploreCard(index)
          ) : Container()
        )
      )
    ]);
  }

  Widget _exploreCard(int index) {
    Explore explore = _explores![index];
    bool isFirst = (index == 0);
    bool isLast = ((index + 1) == _explores!.length);

    if (explore is LaundryRoom) {
      return Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: isLast ? 16 : 0), child:
        LaundryRoomCard(room: explore, onTap: () => _onTapExplore(explore)),
      );
    }
    else if (explore is MTDStop) {
      return Padding(padding: EdgeInsets.only(left: 16, right: 16, top: isFirst ? 16 : 4, bottom: isLast ? 16 : 0), child:
        MTDStopCard(
          stop: explore,
          expanded: _mtdExpanded,
          onDetail: _onTapMTDStop,
          onExpand: _onExpandMTDStop,
          currentPosition: widget.initialLocationData,
        ),
      );
    }
    else if (explore is StudentCourse) {
      return Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: isLast ? 16 : 0), child:
        StudentCourseCard(course: explore,),
      );
    }
    else if (explore is Appointment) {
      return Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: isLast ? 16 : 0), child:
        AppointmentCard(appointment: explore)
      );
    }
    else {
      return Padding(padding: EdgeInsets.only(top: 16, bottom: isLast ? 16 : 0), child:
        ExploreCard(explore: explore, onTap: () => _onTapExplore(explore), locationData: widget.initialLocationData, showTopBorder: true),
      );
    }
  }

  void _onTapExplore(Explore explore) {
    Analytics().logSelect(target: explore.exploreTitle);
    explore.exploreLaunchDetail(context, initialLocationData: widget.initialLocationData,);
  }

  void _onTapMTDStop(MTDStop? stop) {
    Analytics().logSelect(target: "Bus Stop: ${stop?.name}" );
    if (stop != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => MTDStopDeparturesPanel(stop: stop)));
    }
  }

  void _onExpandMTDStop(MTDStop? stop) {
    Analytics().logSelect(target: "Bus Stop: ${stop?.name}" );
    if (mounted && (stop?.id != null)) {
      setState(() {
        SetUtils.toggle(_mtdExpanded, stop?.id);
      });
    }
  }

  @override
  void onNotification(String name, param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      if (mounted) {
        setState(() { });
      }
    }
  }
}
