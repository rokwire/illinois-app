/*
 * Copyright 2024 Board of Trustees of the University of Illinois.
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
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AthleticsEventsContentWidget extends StatefulWidget {
  AthleticsEventsContentWidget();

  @override
  State<AthleticsEventsContentWidget> createState() => _AthleticsEventsContentWidgetState();
}

class _AthleticsEventsContentWidgetState extends State<AthleticsEventsContentWidget> implements NotificationsListener {
  List<Event2>? _events;
  List<Sport>? _teamsFilter;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, []);
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildTeamsFilter(),
      _buildContent()
    ]);
  }

  Widget _buildContent() {
    if (_loading) {
      return _buildLoadingContent();
    } else if (CollectionUtils.isEmpty(_events)) {
      return _buildEmptyContent();
    } else {
      return _buildEventsContent();
    }
  }

  Widget _buildTeamsFilter() {
    return Column(children: [
      Container(
          color: Styles().colors?.white,
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                InkWell(
                    splashColor: Colors.transparent,
                    onTap: _onTapTeamsFilter,
                    child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Styles().colors!.disabledTextColor!, width: 1), borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            child: Row(children: [
                              Styles().images?.getImage('filters') ?? Container(),
                              Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  child: Text(Localization().getStringEx('panel.athletics.content.common.filter.teams.label', 'Teams'),
                                      style: Styles().textStyles?.getTextStyle('widget.button.title.small.fat'))),
                              Styles().images?.getImage('chevron-right-gray') ?? Container()
                            ])))),
                Expanded(child: Container())
              ]))),
      Divider(thickness: 1, color: Styles().colors!.lightGray!, height: 1),
      Container(
          decoration: BoxDecoration(color: Styles().colors?.white, boxShadow: kElevationToShadow[2]),
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                Expanded(child: Text(_teamsFilterLabel, style: Styles().textStyles?.getTextStyle('widget.button.title.small')))
              ])))
    ]);
  }

  Widget _buildEventsContent() {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [Text('TBD: to be implemented')]));
  }

  Widget _buildLoadingContent() {
    return Center(
        child: Column(children: <Widget>[
      Container(height: MediaQuery.of(context).size.height / 5),
      CircularProgressIndicator(),
      Container(height: MediaQuery.of(context).size.height / 5 * 3)
    ]));
  }

  Widget _buildEmptyContent() {
    return Text('TBD: to be implemented');
  }

  void _onTapTeamsFilter() {
    Analytics().logSelect(target: "Teams");
    //TBD: DD - implement
  }

  void _setLoading(bool loading) {
    setStateIfMounted(() {
      _loading = loading;
    });
  }

  String get _teamsFilterLabel {
    String filterPrefix = Localization().getStringEx('key', 'Filter:');
    String? teamsFilterDisplayString = CollectionUtils.isNotEmpty(_teamsFilter)
        ? _teamsFilter!.map((team) => team.title).toList().join(',')
        : Localization().getStringEx('key', 'None');
    return '$filterPrefix $teamsFilterDisplayString';
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == Events2.notifyChanged) {}
  }
}
