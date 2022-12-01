/*
 * Copyright 2022 Board of Trustees of the University of Illinois.
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
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';

class SettingsAppointmentsContentWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsAppointmentsContentWidgetState();
}

class _SettingsAppointmentsContentWidgetState extends State<SettingsAppointmentsContentWidget> {
  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    return Container(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(height: 16),
      Row(children: [
        Expanded(
            child: Text(
                Localization()
                    .getStringEx(
                        'panel.settings.home.appointments.description.format', 'Display appointments in the {{app_title}} app for:')
                    .replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')),
                style: Styles().textStyles?.getTextStyle("widget.detail.regular.fat")))
      ]),
      Container(height: 4),
      ToggleRibbonButton(
          label: Localization().getStringEx('panel.settings.home.appointments.mckinley.label', 'MyMcKinley'),
          toggled: Storage().appointmentsCanDisplay ?? false,
          border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(4)),
          onTap: _onToggleMcKinley)
    ]));
  }

  void _onToggleMcKinley() {
    Analytics().logSelect(target: 'MyMcKinley appointment settings');
    setStateIfMounted(() {
      Storage().appointmentsCanDisplay = !(Storage().appointmentsCanDisplay ?? false);
    });
  }
}
