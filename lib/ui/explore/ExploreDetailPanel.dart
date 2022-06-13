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

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/explore/ExploreDiningDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreEventDetailPanel.dart';

import 'package:rokwire_plugin/model/explore.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ext/Explore.dart';

class ExploreDetailPanel extends StatelessWidget implements AnalyticsPageAttributes {
  final Explore? explore;
  final Position? initialLocationData;
  final String? browseGroupId;

  ExploreDetailPanel({this.explore, this.initialLocationData, this.browseGroupId});

  @override
  Map<String, dynamic>? get analyticsPageAttributes => explore?.analyticsAttributes;

  @override
  Widget build(BuildContext context) {
    if(explore is Dining){
      return ExploreDiningDetailPanel(dining: explore as Dining, initialLocationData: initialLocationData);
    }
    else if(explore is Event) {
      Event event = explore as Event;
      return event.isComposite ?
        CompositeEventsDetailPanel(parentEvent: event) :
        ExploreEventDetailPanel(event: event, initialLocationData: initialLocationData, browseGroupId: browseGroupId, );
    }
    else{ // Default for unexpected type
      return Scaffold(
        appBar: HeaderBar(),
      );
    }
  }
}