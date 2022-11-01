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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/athletics/AthleticsTeamsWidget.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/settings/SettingsCalendarContentWidget.dart';
import 'package:illinois/ui/settings/SettingsFoodFiltersContentWidget.dart';
import 'package:illinois/ui/settings/SettingsInterestsContentWidget.dart';
import 'package:illinois/ui/settings/SettingsSectionsContentWidget.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/debug/DebugHomePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class SettingsHomeContentPanel extends StatefulWidget {
  static final String routeName = 'settings_home_content_panel';
  
  final SettingsContent? content;

  SettingsHomeContentPanel._({this.content});

  @override
  _SettingsHomeContentPanelState createState() => _SettingsHomeContentPanelState();

  static void present(BuildContext context, {SettingsContent? content}) {
    if (ModalRoute.of(context)?.settings.name != routeName) {
      Navigator.push(context, PageRouteBuilder(
        settings: RouteSettings(name: routeName),
        pageBuilder: (context, animation1, animation2) => SettingsHomeContentPanel._(content: content),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero)
      );
    }
  }
}

class _SettingsHomeContentPanelState extends State<SettingsHomeContentPanel> {
  static SettingsContent? _lastSelectedContent;
  late SettingsContent _selectedContent;
  bool _contentValuesVisible = false;

  @override
  void initState() {
    super.initState();
    _selectedContent = widget.content ?? (_lastSelectedContent ?? SettingsContent.sections);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _DebugContainer(
            child: RootHeaderBar(
              title: Localization().getStringEx('panel.settings.home.header.settings.label', 'Settings'),
              onSettings: _onTapSettings,
          ),
        ),
        body: Column(children: <Widget>[
          Expanded(
              child: SingleChildScrollView(
                  physics: (_contentValuesVisible ? NeverScrollableScrollPhysics() : null),
                  child: Container(
                      color: Styles().colors!.background,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(
                            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
                            child: RibbonButton(
                                textColor: Styles().colors!.fillColorSecondary,
                                backgroundColor: Styles().colors!.white,
                                borderRadius: BorderRadius.all(Radius.circular(5)),
                                border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
                                rightIconAsset: (_contentValuesVisible ? 'images/icon-up.png' : 'images/icon-down-orange.png'),
                                label: _getContentLabel(_selectedContent),
                                onTap: _onTapContentDropdown)),
                        _buildContent()
                      ]))))
        ]),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: uiuc.TabBar());
  }

  Widget _buildContent() {
    return Stack(children: [
      Padding(padding: EdgeInsets.all(16), child:
        _contentWidget
      ),
      _buildContentValuesContainer()
    ]);
  }

  Widget _buildContentValuesContainer() {
    return Visibility(
      visible: _contentValuesVisible,
      child: Container /* Positioned.fill*/ (child:
        Stack(children: <Widget>[
          _buildContentDismissLayer(),
          _buildContentValuesWidget()
        ])));
  }

  Widget _buildContentDismissLayer() {
    return Container /* Positioned.fill */ (
        child: BlockSemantics(
            child: GestureDetector(
                onTap: () {
                  setState(() {
                    _contentValuesVisible = false;
                  });
                },
                child: Container(
                  color: Styles().colors!.blackTransparent06,
                  height: MediaQuery.of(context).size.height,
                  
                ))));
  }

  Widget _buildContentValuesWidget() {
    List<Widget> sectionList = <Widget>[];
    sectionList.add(Container(color: Styles().colors!.fillColorSecondary, height: 2));
    for (SettingsContent section in SettingsContent.values) {
      if ((_selectedContent != section)) {
        sectionList.add(_buildContentItem(section));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: sectionList)));
  }

  Widget _buildContentItem(SettingsContent contentItem) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconAsset: null,
        label: _getContentLabel(contentItem),
        onTap: () => _onTapContentItem(contentItem));
  }

  void _onTapContentDropdown() {
    Analytics().logSelect(target: 'Content Dropdown');
    _changeSettingsContentValuesVisibility();
  }

  void _onTapContentItem(SettingsContent contentItem) {
    Analytics().logSelect(target: "Content Item: ${contentItem.toString()}");
    if (contentItem == SettingsContent.favorites) {
      NotificationService().notify(HomePanel.notifyCustomize);
    }
    else {
    _selectedContent = _lastSelectedContent = contentItem;
    }
    _changeSettingsContentValuesVisibility();
  }

  void _changeSettingsContentValuesVisibility() {
    if (mounted) {
      setState(() {
        _contentValuesVisible = !_contentValuesVisible;
      });
    }
  }

  Widget get _contentWidget {
    switch (_selectedContent) {
      case SettingsContent.sections:
        return SettingsSectionsContentWidget();
      case SettingsContent.interests:
        return SettingsInterestsContentWidget();
      case SettingsContent.food_filters:
        return SettingsFoodFiltersContentWidget();
      case SettingsContent.sports:
        return AthleticsTeamsWidget();
      case SettingsContent.calendar:
        return SettingsCalendarContentWidget();
      case SettingsContent.favorites:
        return Container();
    }
  }

  void _onTapSettings() {
    if (kDebugMode || (Config().configEnvironment == ConfigEnvironment.dev)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugHomePanel()));
    }
  }

  // Utilities

  String _getContentLabel(SettingsContent section) {
    switch (section) {
      case SettingsContent.sections:
        return Localization().getStringEx('panel.settings.home.settings.sections.section.label', 'Sign In/Sign Out');
      case SettingsContent.interests:
        return Localization().getStringEx('panel.settings.home.settings.sections.interests.label', 'My Interests');
      case SettingsContent.food_filters:
        return Localization().getStringEx('panel.settings.home.settings.sections.food_filter.label', 'My Food Filter');
      case SettingsContent.sports:
        return Localization().getStringEx('panel.settings.home.settings.sections.sports.label', 'My Sports Teams');
      case SettingsContent.calendar:
        return Localization().getStringEx('panel.settings.home.settings.sections.calendar.label', 'My Calendar Settings');
      case SettingsContent.favorites:
        return Localization().getStringEx('panel.settings.home.settings.sections.favorites.label', 'My Favorites');
    }
  }
}

enum SettingsContent { sections, interests, food_filters, sports, calendar, favorites }

class _DebugContainer extends StatefulWidget implements PreferredSizeWidget {
  final Widget _child;

  _DebugContainer({required Widget child}) : _child = child;

  // PreferredSizeWidget
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  _DebugContainerState createState() => _DebugContainerState();
}

class _DebugContainerState extends State<_DebugContainer> {
  int _clickedCount = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: widget._child,
      onTap: () {
        Analytics().logSelect(target: 'Debug 7 Clicks', source: 'Header Bar');
        Log.d("On tap debug widget");
        _clickedCount++;

        if (_clickedCount == 7) {
          if (Auth2().isDebugManager) {
            Analytics().logSelect(target: 'Debug 7th Click', source: 'Header Bar');
            Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugHomePanel()));
          }
          _clickedCount = 0;
        }
      },
    );
  }
}
