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
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/ui/settings/SettingsInboxHomeContentWidget.dart';
import 'package:illinois/ui/settings/SettingsNotificationPreferencesContentWidget.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

enum SettingsNotificationsContent { inbox, preferences }

class SettingsNotificationsContentPanel extends StatefulWidget {
  static final String routeName = 'settings_notifications_content_panel';

  final SettingsNotificationsContent? content;

  SettingsNotificationsContentPanel._({this.content});

  static void present(BuildContext context, { SettingsNotificationsContent? content}) {
    if (content == SettingsNotificationsContent.inbox) {
      if (Connectivity().isOffline) {
        AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.inbox', 'Notifications are not available while offline.'));
      }
      else if (!Auth2().isOidcLoggedIn) {
        AppAlert.showMessage(context, Localization().getStringEx('panel.browse.label.logged_out.inbox', 'You need to be logged in to access Notifications.'));
      }
      else {
        Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: routeName), builder: (context) => SettingsNotificationsContentPanel._(content: content)));
      }
    }
    else {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: routeName), builder: (context) => SettingsNotificationsContentPanel._(content: content)));
    }
  }

  static void launchMessageDetail(InboxMessage message) {
    FirebaseMessaging().processDataMessageEx(message.data, allowedPayloadTypes: {
      FirebaseMessaging.payloadTypeEventDetail,
      FirebaseMessaging.payloadTypeGameDetail,
      FirebaseMessaging.payloadTypeAthleticsGameStarted,
      FirebaseMessaging.payloadTypeAthleticsNewDetail,
      FirebaseMessaging.payloadTypeGroup
    });
  }

  @override
  _SettingsNotificationsContentPanelState createState() => _SettingsNotificationsContentPanelState();
}

class _SettingsNotificationsContentPanelState extends State<SettingsNotificationsContentPanel> implements NotificationsListener {
  static final double _defaultPadding = 16;
  static SettingsNotificationsContent? _lastSelectedContent;
  late SettingsNotificationsContent _selectedContent;
  final GlobalKey _headerBarKey = GlobalKey();
  final GlobalKey _tabBarKey = GlobalKey();
  final GlobalKey _contentDropDownKey = GlobalKey();
  double _contentWidgetHeight = 300; // default value
  bool _contentValuesVisible = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [Auth2.notifyLoginChanged]);
    
    _initInitialContent();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _evalContentWidgetHeight();
    });
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: RootHeaderBar(
            key: _headerBarKey, title: Localization().getStringEx('panel.settings.notifications.header.inbox.label', 'My Notifications')),
        body: Column(children: <Widget>[
          Expanded(
              child:
                  SingleChildScrollView(physics: (_contentValuesVisible ? NeverScrollableScrollPhysics() : null), child: _buildContent()))
        ]),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: uiuc.TabBar(key: _tabBarKey));
  }

  Widget _buildContent() {
    return Container(
        color: Styles().colors!.background,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              key: _contentDropDownKey,
              padding: EdgeInsets.only(left: _defaultPadding, top: _defaultPadding, right: _defaultPadding),
              child: RibbonButton(
                  textColor: Styles().colors!.fillColorSecondary,
                  backgroundColor: Styles().colors!.white,
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                  border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
                  rightIconAsset: (_contentValuesVisible ? 'images/icon-up.png' : 'images/icon-down-orange.png'),
                  label: _getContentLabel(_selectedContent),
                  onTap: _changeSettingsContentValuesVisibility)),
          Container(
              height: (_isInboxContent ? _contentWidgetHeight : null),
              child: Stack(children: [Padding(padding: EdgeInsets.all(_defaultPadding), child: _contentWidget), _buildContentValuesContainer()]))
        ]));
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
    for (SettingsNotificationsContent contentItem in SettingsNotificationsContent.values) {
      if (_isInboxContent && !Auth2().isLoggedIn) {
        continue;
      }
      if ((_selectedContent != contentItem)) {
        contentList.add(_buildContentItem(contentItem));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: _defaultPadding), child: SingleChildScrollView(child: Column(children: contentList)));
  }

  Widget _buildContentItem(SettingsNotificationsContent contentItem) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconAsset: null,
        label: _getContentLabel(contentItem),
        onTap: () => _onTapContentItem(contentItem));
  }

  void _initInitialContent() {
    // Do not allow not logged in users to view "Notifications" content
    if (!Auth2().isLoggedIn && (_lastSelectedContent == SettingsNotificationsContent.inbox)) {
      _lastSelectedContent = null;
    }
    _selectedContent = widget.content ??
        (_lastSelectedContent ?? (Auth2().isLoggedIn ? SettingsNotificationsContent.inbox : SettingsNotificationsContent.preferences));
  }

  void _onTapContentItem(SettingsNotificationsContent contentItem) {
    _selectedContent = _lastSelectedContent = contentItem;
    _changeSettingsContentValuesVisibility();
  }

  void _changeSettingsContentValuesVisibility() {
    _contentValuesVisible = !_contentValuesVisible;
    if (mounted) {
      setState(() {});
    }
  }

  void _evalContentWidgetHeight() {
    double takenHeight = 0;
    try {
      final RenderObject? headerRenderBox = _headerBarKey.currentContext?.findRenderObject();
      if (headerRenderBox is RenderBox) {
        takenHeight += headerRenderBox.size.height;
      }

      final RenderObject? contentDropDownRenderBox = _contentDropDownKey.currentContext?.findRenderObject();
      if (contentDropDownRenderBox is RenderBox) {
        takenHeight += contentDropDownRenderBox.size.height;
      }

      final RenderObject? tabBarRenderBox = _tabBarKey.currentContext?.findRenderObject();
      if (tabBarRenderBox is RenderBox) {
        takenHeight += tabBarRenderBox.size.height;
      }
    } on Exception catch (e) {
      print(e.toString());
    }

    if (mounted) {
      setState(() {
        _contentWidgetHeight = MediaQuery.of(context).size.height - takenHeight + _defaultPadding;
      });
    }
  }

  Widget get _contentWidget {
    switch (_selectedContent) {
      case SettingsNotificationsContent.inbox:
        return SettingsInboxHomeContentWidget();
      case SettingsNotificationsContent.preferences:
        return SettingsNotificationPreferencesContentWidget();
    }
  }

  bool get _isInboxContent {
    return (_selectedContent == SettingsNotificationsContent.inbox);
  }

  // Utilities

  String _getContentLabel(SettingsNotificationsContent content) {
    switch (content) {
      case SettingsNotificationsContent.inbox:
        return Localization().getStringEx('panel.settings.notifications.content.inbox.label', 'My Notifications');
      case SettingsNotificationsContent.preferences:
        return Localization().getStringEx('panel.settings.notifications.content.preferences.label', 'My Notification Preferences');
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if (name == Auth2.notifyLoginChanged) {
      if ((_selectedContent == SettingsNotificationsContent.inbox) && !Auth2().isLoggedIn) {
        // Do not allow not logged in users to view "Notifications" content
        _selectedContent = _lastSelectedContent = SettingsNotificationsContent.preferences;
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

}
