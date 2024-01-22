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
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class AthleticsMyTeamsPanel extends StatefulWidget {
  AthleticsMyTeamsPanel();

  @override
  _AthleticsMyTeamsPanelState createState() => _AthleticsMyTeamsPanelState();
}

class _AthleticsMyTeamsPanelState extends State<AthleticsMyTeamsPanel> implements NotificationsListener {
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
    return _buildSheet(context);
  }

  Widget _buildSheet(BuildContext context) {
    return Column(children: [
      Container(
          color: Styles().colors.white,
          child: Row(children: [
            Expanded(
                child: Padding(
                    padding: EdgeInsets.only(left: 16, top: 16, bottom: 16),
                    child: Text(Localization().getStringEx('panel.athletics.content.my_teams.header.title', 'My Big 10 Teams'),
                        style: Styles().textStyles.getTextStyle('widget.sheet.title.regular')))),
            Semantics(
                label: Localization().getStringEx('dialog.close.title', 'Close'),
                hint: Localization().getStringEx('dialog.close.hint', ''),
                inMutuallyExclusiveGroup: true,
                button: true,
                child: InkWell(
                    onTap: _onTapClose,
                    child: Container(
                      padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
                      child: Styles().images.getImage('close-circle', excludeFromSemantics: true),
                    )))
          ])),
      Container(color: Styles().colors.surfaceAccent, height: 1),
      Expanded(child: Container(child: Text('TBD: to be implemented')))
    ]);
  }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: widget.runtimeType.toString());
    Navigator.of(context).pop();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    //TBD: DD - implement
  }
}
