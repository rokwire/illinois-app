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
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/settings/SettingsPersonalInfoContentWidget.dart';
import 'package:illinois/ui/settings/SettingsPrivacyCenterContentWidget.dart';
import 'package:illinois/ui/settings/SettingsRolesContentWidget.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class SettingsProfileContentPanel extends StatefulWidget {
  static final String routeName = 'settings_profile_content_panel';

  final SettingsProfileContent? content;

  SettingsProfileContentPanel._({this.content});

  @override
  _SettingsProfileContentPanelState createState() => _SettingsProfileContentPanelState();

  static void present(BuildContext context, {SettingsProfileContent? content}) {
    Navigator.push(
        context,
        CupertinoPageRoute(
            settings: RouteSettings(name: routeName), builder: (context) => SettingsProfileContentPanel._(content: content)));
  }
}

class _SettingsProfileContentPanelState extends State<SettingsProfileContentPanel> implements NotificationsListener {
  static SettingsProfileContent? _lastSelectedContent;
  late SettingsProfileContent _selectedContent;
  bool _contentValuesVisible = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Auth2.notifyLoginChanged]);
    _initInitialContent();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: RootHeaderBar(title: Localization().getStringEx('panel.settings.profile.header.profile.label', 'My Profile')),
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
                                onTap: _changeSettingsContentValuesVisibility)),
                        _buildContent()
                      ]))))
        ]),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: uiuc.TabBar());
  }


  Widget _buildContent() {
    return Stack(children: [Padding(padding: EdgeInsets.all(16), child: _contentWidget), _buildContentValuesContainer()]);
  }

  Widget _buildContentValuesContainer() {
    return Visibility(
        visible: _contentValuesVisible,
        child: Positioned.fill(child: Stack(children: <Widget>[_buildContentDismissLayer(), _buildContentValuesWidget()])));
  }

  Widget _buildContentDismissLayer() {
    return Positioned.fill(
        child: BlockSemantics(
            child: GestureDetector(
                onTap: () {
                  setState(() {
                    _contentValuesVisible = false;
                  });
                },
                child: Container(color: Styles().colors!.blackTransparent06))));
  }

  Widget _buildContentValuesWidget() {
    List<Widget> contentList = <Widget>[];
    contentList.add(Container(color: Styles().colors!.fillColorSecondary, height: 2));
    for (SettingsProfileContent contentItem in SettingsProfileContent.values) {
      if ((contentItem == SettingsProfileContent.profile) && !Auth2().isLoggedIn) {
        continue;
      }
      if ((_selectedContent != contentItem)) {
        contentList.add(_buildContentItem(contentItem));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: contentList)));
  }

  Widget _buildContentItem(SettingsProfileContent contentItem) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconAsset: null,
        label: _getContentLabel(contentItem),
        onTap: () => _onTapContentItem(contentItem));
  }

  void _initInitialContent() {
    // Do not allow not logged in users to view "Profile" content
    if (!Auth2().isLoggedIn && (_lastSelectedContent == SettingsProfileContent.profile)) {
      _lastSelectedContent = null;
    }
    _selectedContent =
        widget.content ?? (_lastSelectedContent ?? (Auth2().isLoggedIn ? SettingsProfileContent.profile : SettingsProfileContent.privacy));
  }

  void _onTapContentItem(SettingsProfileContent contentItem) {
    _selectedContent = _lastSelectedContent = contentItem;
    _changeSettingsContentValuesVisibility();
  }

  void _changeSettingsContentValuesVisibility() {
    _contentValuesVisible = !_contentValuesVisible;
    if (mounted) {
      setState(() {});
    }
  }

  Widget get _contentWidget {
    switch (_selectedContent) {
      case SettingsProfileContent.profile:
        return SettingsPersonalInfoContentWidget();
      case SettingsProfileContent.who_are_you:
        return SettingsRolesContentWidget();
      case SettingsProfileContent.privacy:
        return SettingsPrivacyCenterContentWidget();
      default:
        return Container();
    }
  }

  // Utilities

  String _getContentLabel(SettingsProfileContent content) {
    switch (content) {
      case SettingsProfileContent.profile:
        return Localization().getStringEx('panel.settings.profile.content.profile.label', 'My Profile');
      case SettingsProfileContent.who_are_you:
        return Localization().getStringEx('panel.settings.profile.content.who_are_you.label', 'Who Are You');
      case SettingsProfileContent.privacy:
        return Localization().getStringEx('panel.settings.profile.content.privacy.label', 'My App Privacy Settings');
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if (name == Auth2.notifyLoginChanged) {
      if ((_selectedContent == SettingsProfileContent.profile) && !Auth2().isLoggedIn) {
        // Do not allow not logged in users to view "Profile" content
        _selectedContent = _lastSelectedContent = SettingsProfileContent.privacy;
      }
      if (mounted) {
        setState(() {});
      }
    }
  }
  
}

enum SettingsProfileContent { profile, who_are_you, privacy }