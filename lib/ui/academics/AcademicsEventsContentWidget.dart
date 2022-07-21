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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:illinois/ui/explore/ExploreDetailPanel.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AcademicsEventsContentWidget extends StatefulWidget {
  AcademicsEventsContentWidget();

  @override
  State<AcademicsEventsContentWidget> createState() => _AcademicsEventsContentWidgetState();
}

class _AcademicsEventsContentWidgetState extends State<AcademicsEventsContentWidget> {
  List<Explore>? _events;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    _setLoading(true);
    Events().loadEvents(categories: {'Academic'}, eventFilter: EventTimeFilter.next7Day).then((events) {
      _events = events;
      _sortEvents(_events);
      _setLoading(false);
    });
  }

  void _sortEvents(List<Explore>? explores) {
    if (CollectionUtils.isEmpty(explores)) {
      return;
    }
    explores!.sort((Explore first, Explore second) {
      if (first.exploreStartDateUtc == null || second.exploreStartDateUtc == null) {
        return 0;
      } else {
        return (first.exploreStartDateUtc!.isBefore(second.exploreStartDateUtc!)) ? -1 : 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    if (Connectivity().isOffline) {
      return _buildOfflineContent();
    } else if (_loading) {
      return _buildLoadingContent();
    } else if (CollectionUtils.isEmpty(_events)) {
      return _buildEmptyContent();
    } else {
      return _buildEventsContent();
    }
  }

  Widget _buildOfflineContent() {
    String message =
        Localization().getStringEx('panel.academics.section.events.offline.msg', 'No academic events available while offline.');
    return _buildCenterWidget(Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(Localization().getStringEx("app.offline.message.title", "You appear to be offline"), style: TextStyle(fontSize: 16)),
      Container(height: 8),
      Text(message)
    ]));
  }

  Widget _buildLoadingContent() {
    return _buildCenterWidget(CircularProgressIndicator());
  }

  Widget _buildEmptyContent() {
    String message = Localization().getStringEx('panel.academics.section.events.empty.msg', 'No academic events.');
    return _buildCenterWidget(Text(message, textAlign: TextAlign.center));
  }

  Widget _buildEventsContent() {
    List<Widget> contentList = <Widget>[];
    if (CollectionUtils.isNotEmpty(_events)) {
      for (Explore event in _events!) {
        contentList.add(_buildExploreEntry(event));
        contentList.add(Divider(color: Colors.transparent));
      }
    }
    return Column(children: contentList);
  }

  Widget _buildExploreEntry(Explore event) {
    ExploreCard exploreCard =
        ExploreCard(explore: event, horizontalPadding: 0, onTap: () => _onTapEvent(event), hideInterests: true, showTopBorder: true);
    return exploreCard;
  }

  Widget _buildCenterWidget(Widget widget) {
    return Center(
        child: Column(children: <Widget>[
      Container(height: MediaQuery.of(context).size.height / 5),
      widget,
      Container(height: MediaQuery.of(context).size.height / 5 * 3)
    ]));
  }

  void _onTapEvent(Explore explore) {
    Analytics().logSelect(target: explore.exploreTitle);
    Event? event = (explore is Event) ? explore : null;
    if (event?.isComposite ?? false) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => CompositeEventsDetailPanel(parentEvent: event)));
    } else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreDetailPanel(explore: explore))).then((value) {
        if (value != null && value == true) {
          Navigator.pop(context);
        }
      });
    }
  }

  void _setLoading(bool loading) {
    _loading = loading;
    if (mounted) {
      setState(() {});
    }
  }
}
