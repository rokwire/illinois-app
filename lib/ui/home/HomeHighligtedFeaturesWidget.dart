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

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/guide/CampusGuidePanel.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/ui/settings/SettingsNotificationsPanel.dart';
import 'package:illinois/ui/settings/SettingsPersonalInformationPanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';

class HomeHighlightedFeatures extends StatefulWidget {

  final String? favoriteId;
  final StreamController<void>? refreshController;
  final HomeScrollableDragging? scrollableDragging;

  const HomeHighlightedFeatures({Key? key, this.favoriteId, this.refreshController, this.scrollableDragging}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeHighlightedFeaturesState();
}

class _HomeHighlightedFeaturesState extends State<HomeHighlightedFeatures> implements NotificationsListener{

  // TBD_TB: Load widget content from FlexUI (like HomeSaferWidget does).
  // Please use the following entries: personalize, notifications, privacy, campus_guide 

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
    ]);

    if (widget.refreshController != null) {
      widget.refreshController!.stream.listen((_) {
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          _buildHeader(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: _buildCommandsList()
            )
          )
        ],
      )
    );
  }

  List<Widget> _buildCommandsList() {
  List<Widget> contentList = <Widget>[];
    List<dynamic>? contentListCodes = FlexUI()['home.highlighted_features'];
    if (contentListCodes != null) {
      for (dynamic contentListCode in contentListCodes) {
        Widget? contentEntry;
        if (contentListCode == 'personalize') {
          contentEntry = _buildCommandEntry(
            title: Localization().getStringEx('widgets.home_highlighted_features.button.personalize.title',  'Personalize This App') ,
            description: Localization().getStringEx('widgets.home_highlighted_features.button.personalize.hint', '') ,
            onTap: _onTapPersonalize,
          );
        }
        else if (contentListCode == 'notifications') {
          contentEntry = _buildCommandEntry(
            title:  Localization().getStringEx('widgets.home_highlighted_features.button.notifications.title',  'Manage Notification Preferences') ,
            description: Localization().getStringEx('widgets.home_highlighted_features.button.notifications.hint', '') ,
            onTap: _onTapNotificationPreferences,
          );
        }
        else if (contentListCode == 'privacy') {
          contentEntry = _buildCommandEntry(
            title: Localization().getStringEx('widgets.home_highlighted_features.button.privacy.title',  'Manage My Privacy') ,
            description: Localization().getStringEx('widgets.home_highlighted_features.button.privacy.hint', '') ,
            onTap: _onTapManagePrivacy,
          );
        }
        else if (contentListCode == 'campus_guide') {
          contentEntry = _buildCommandEntry(
            title: Localization().getStringEx('widgets.home_highlighted_features.button.guide.title',  'Campus Guide') ,
            description: Localization().getStringEx('widgets.home_highlighted_features.button.guide.hint', '') ,
            onTap: _onTapCampusGuide,
          );
        }

        if (contentEntry != null) {
          if (contentList.isNotEmpty) {
            contentList.add(Container(height: 12,));
          }
          contentList.add(contentEntry);
        }
      }

    }
    return contentList;
  }

  Widget _buildHeader() {
    return HomeRibonHeader(favoriteId: widget.favoriteId, scrollableDragging: widget.scrollableDragging,
      title: Localization().getStringEx('widgets.home_highlighted_features.header.title',  'Highlighted Features')
    );
  }

  Widget _buildCommandEntry({required String title, String? description, void Function()? onTap}) {
    return  RibbonButton(label:title, hint: description, onTap: onTap,
              borderRadius: BorderRadius.all(Radius.circular(5)),);
  }

  void _onTapPersonalize() {
    Analytics().logSelect(target: "HomeHighlightedFeatures: Personalize");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPersonalInformationPanel()));
  }

  void _onTapNotificationPreferences() {
    Analytics().logSelect(target: "HomeHighlightedFeatures: Notification Preferences");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsNotificationsPanel()));
  }

  void _onTapManagePrivacy() {
    Analytics().logSelect(target: "HomeHighlightedFeatures: Manage Privacy");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular)));
  }

  void _onTapCampusGuide() {
    Analytics().logSelect(target: "HomeHighlightedFeatures: Campus Guide");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CampusGuidePanel()));
  }
}