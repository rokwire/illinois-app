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
import 'package:illinois/service/OnCampus.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/flex_ui.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';

class SettingsCalendarContentWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsCalendarContentWidgetState();
}

class _SettingsCalendarContentWidgetState extends State<SettingsCalendarContentWidget> implements NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [AppLivecycle.notifyStateChanged, OnCampus.notifyChanged]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if ((name == OnCampus.notifyChanged) || ((name == AppLivecycle.notifyStateChanged) && (param == AppLifecycleState.resumed))) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['calendar'] ?? [];
    for (String code in codes) {
      if (code == 'settings') {
        contentList.addAll(_buildCalendarSettings());
      } else if (code == 'on_campus') {
        contentList.addAll(_buildOnCampus());
      }
    }

    if (contentList.isNotEmpty) {
      contentList.insert(0, Container(height: 8));
      contentList.add(Container(height: 16));
    }

    return Container(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList));
  }

  List<Widget> _buildCalendarSettings() {
    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['calendar.settings'] ?? [];
    for (String code in codes) {
      if (code == 'add') {
        contentList.add(Container(height: 4));
        contentList.add(ToggleRibbonButton(
            label: Localization().getStringEx('panel.settings.home.calendar.settings.add_events.label', 'Add saved events to calendar'),
            toggled: Storage().calendarEnabledToSave ?? false,
            border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(4)),
            onTap: () {
              setState(() {
                Storage().calendarEnabledToSave = !Storage().calendarEnabledToSave!;
              });
            }));
      } else if (code == 'prompt') {
        contentList.add(Container(height: 4));
        contentList.add(ToggleRibbonButton(
            label: Localization().getStringEx('panel.settings.home.calendar.settings.prompt.label', 'Prompt when saving events to calendar'),
            textStyle: TextStyle(
                fontSize: 16,
                fontFamily: Styles().fontFamilies!.bold,
                color: Storage().calendarEnabledToSave! ? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent),
            border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(4)),
            toggled: Storage().calendarCanPrompt ?? false,
            onTap: () {
              if (Storage().calendarEnabledToSave == false) {
                setState(() {
                  Storage().calendarCanPrompt = (Storage().calendarCanPrompt != true);
                });
              }
            }));
      }
    }

    if (contentList.isNotEmpty) {
      contentList.insertAll(0, <Widget>[
        Container(height: 16),
        Row(children: [
          Expanded(
              child: Text('Calendar',
                  style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies?.bold, color: Styles().colors!.fillColorPrimary)))
        ])
      ]);
    }
    return contentList;
  }

  List<Widget> _buildOnCampus() {
    bool onCampusRegionMonitorEnabled = OnCampus().enabled;
    bool onCampusRegionMonitorSelected = OnCampus().monitorEnabled;
    String onCampusRegionMonitorInfo = onCampusRegionMonitorEnabled
        ? Localization()
            .getStringEx('panel.settings.home.calendar.on_campus.location_services.required.label', 'requires location services')
        : Localization()
            .getStringEx('panel.settings.home.calendar.on_campus.location_services.not_available.label', 'not available');
    String autoOnCampusInfo = Localization().getStringEx(
            'panel.settings.home.calendar.on_campus.radio_button.auto.title', 'Automatically detect when I am on Campus') +
        '\n($onCampusRegionMonitorInfo)';

    bool campusRegionManualInsideSelected = OnCampus().monitorManualInside;
    bool onCampusSelected = !onCampusRegionMonitorSelected && campusRegionManualInsideSelected;
    bool offCampusSelected = !onCampusRegionMonitorSelected && !campusRegionManualInsideSelected;

    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['calendar.on_campus'] ?? [];
    for (String code in codes) {
      if (code == 'auto') {
        contentList.add(_buildOnCampusRadioItem(
            label: autoOnCampusInfo,
            enabled: onCampusRegionMonitorEnabled,
            selected: onCampusRegionMonitorSelected,
            onTap: onCampusRegionMonitorEnabled
                ? () {
                    setState(() {
                      OnCampus().monitorEnabled = true;
                    });
                  }
                : () {}));
      } else if (code == 'on_campus') {
        contentList.add(_buildOnCampusRadioItem(
            label: Localization()
                .getStringEx('panel.settings.home.calendar.on_campus.radio_button.on.title', 'Always make me on campus'),
            enabled: true,
            selected: onCampusSelected,
            onTap: !onCampusSelected
                ? () {
                    setState(() {
                      OnCampus().monitorEnabled = false;
                      OnCampus().monitorManualInside = true;
                    });
                  }
                : () {}));
      } else if (code == 'off_campus') {
        contentList.add(_buildOnCampusRadioItem(
            label: Localization()
                .getStringEx('panel.settings.home.calendar.on_campus.radio_button.off.title', 'Always make me off campus'),
            enabled: true,
            selected: offCampusSelected,
            onTap: !offCampusSelected
                ? () {
                    setState(() {
                      OnCampus().monitorEnabled = false;
                      OnCampus().monitorManualInside = false;
                    });
                  }
                : () {}));
      }
    }
    
    if (contentList.isNotEmpty) {
      contentList.insertAll(0, <Widget>[
        Container(height: 16),
        Row(children: [
          Expanded(
              child: Text(Localization().getStringEx('panel.settings.home.calendar.on_campus.title', 'On Campus'),
                  style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies?.bold, color: Styles().colors!.fillColorPrimary)))
        ])
      ]);
    }
    return contentList;
  }

  Widget _buildOnCampusRadioItem({required String label, required bool enabled, required bool selected, VoidCallback? onTap}) {
    String imageAssetName = selected ? 'images/deselected-dark.png' : 'images/deselected.png';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(height: 4),
      GestureDetector(
          onTap: onTap,
          child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                  color: Styles().colors!.white,
                  border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(4))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 16,
                            fontFamily: Styles().fontFamilies!.bold,
                            color: (enabled ? Styles().colors?.fillColorPrimary : Styles().colors?.surfaceAccent)))),
                Padding(padding: EdgeInsets.only(left: 10), child: Image.asset(imageAssetName))
              ])))
    ]);
  }
}
