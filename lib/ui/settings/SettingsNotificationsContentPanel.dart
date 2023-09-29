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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/ui/settings/SettingsInboxHomeContentWidget.dart';
import 'package:illinois/ui/settings/SettingsNotificationPreferencesContentWidget.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

enum SettingsNotificationsContent { all, unread, preferences }

class SettingsNotificationsContentPanel extends StatefulWidget {
  static final String routeName = 'settings_notifications_content_panel';

  final SettingsNotificationsContent? content;

  SettingsNotificationsContentPanel._({this.content});

  static void present(BuildContext context, {SettingsNotificationsContent? content}) {
    if (isInboxContent(content) && Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.inbox', 'Notifications are not available while offline.'));
    }
    else if (isInboxContent(content) && !Auth2().isOidcLoggedIn) {
      AppAlert.showMessage(context,Localization().getStringEx('panel.browse.label.logged_out.inbox', 'You need to be logged in with your NetID to access Notifications. Set your privacy level to 4 or 5 in your Profile. Then find the sign-in prompt under Settings.'));
    }
    else if (ModalRoute.of(context)?.settings.name != routeName) {
      MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
      double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 16;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        useRootNavigator: true,
        routeSettings: RouteSettings(name: routeName),
        clipBehavior: Clip.antiAlias,
        backgroundColor: Styles().colors!.background,
        constraints: BoxConstraints(maxHeight: height, minHeight: height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (context) {
          return SettingsNotificationsContentPanel._(content: content);
        }
      );

      /*Navigator.push(context, PageRouteBuilder(
        settings: RouteSettings(name: routeName),
        pageBuilder: (context, animation1, animation2) => SettingsNotificationsContentPanel._(content: content),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero
      ));*/
    }
  }

  static void launchMessageDetail(InboxMessage message) {
    if (message.isRead == false) {
      Inbox().readMessage(message.messageId);
    }
    FirebaseMessaging().processDataMessageEx(message.data, allowedPayloadTypes: {
      FirebaseMessaging.payloadTypeHome,
      FirebaseMessaging.payloadTypeBrowse,
      FirebaseMessaging.payloadTypeMap,
      FirebaseMessaging.payloadTypeMapEvents,
      FirebaseMessaging.payloadTypeMapDining,
      FirebaseMessaging.payloadTypeMapBuildings,
      FirebaseMessaging.payloadTypeMapStudentCourses,
      FirebaseMessaging.payloadTypeMapAppointments,
      FirebaseMessaging.payloadTypeMapMtdStops,
      FirebaseMessaging.payloadTypeMapMtdDestinations,
      FirebaseMessaging.payloadTypeMapMentalHealth,
      FirebaseMessaging.payloadTypeMapStateFarmWayfinding,
      FirebaseMessaging.payloadTypeAcademics,
      FirebaseMessaging.payloadTypeAcademicsAppointments,
      FirebaseMessaging.payloadTypeAcademicsCanvasCourses,
      FirebaseMessaging.payloadTypeAcademicsDueDateCatalog,
      FirebaseMessaging.payloadTypeAcademicsEvents,
      FirebaseMessaging.payloadTypeAcademicsGiesCheckilst,
      FirebaseMessaging.payloadTypeAcademicsMedicineCourses,
      FirebaseMessaging.payloadTypeAcademicsMyIllini,
      FirebaseMessaging.payloadTypeAcademicsSkillsSelfEvaluation,
      FirebaseMessaging.payloadTypeAcademicsStudentCourses,
      FirebaseMessaging.payloadTypeAcademicsToDoList,
      FirebaseMessaging.payloadTypeAcademicsUiucCheckilst,
      FirebaseMessaging.payloadTypeWellness,
      FirebaseMessaging.payloadTypeWellnessAppointments,
      FirebaseMessaging.payloadTypeWellnessDailyTips,
      FirebaseMessaging.payloadTypeWellnessHealthScreener,
      FirebaseMessaging.payloadTypeWellnessMentalHealth,
      FirebaseMessaging.payloadTypeWellnessPodcast,
      FirebaseMessaging.payloadTypeWellnessResources,
      FirebaseMessaging.payloadTypeWellnessRings,
      FirebaseMessaging.payloadTypeWellnessStruggling,
      FirebaseMessaging.payloadTypeWellnessTodoList,
      FirebaseMessaging.payloadTypeWellnessToDoItem,
      FirebaseMessaging.payloadTypeEventDetail,
      FirebaseMessaging.payloadTypeEvent,
      FirebaseMessaging.payloadTypeGameDetail,
      FirebaseMessaging.payloadTypeAthleticsGameStarted,
      FirebaseMessaging.payloadTypeAthleticsNewDetail,
      FirebaseMessaging.payloadTypeGroup,
      FirebaseMessaging.payloadTypeAppointment,
      FirebaseMessaging.payloadTypePoll,
      FirebaseMessaging.payloadTypeProfileMy,
      FirebaseMessaging.payloadTypeProfileWhoAreYou,
      FirebaseMessaging.payloadTypeProfilePrivacy,
      FirebaseMessaging.payloadTypeSettingsSections,
      FirebaseMessaging.payloadTypeSettingsInterests,
      FirebaseMessaging.payloadTypeSettingsFoodFilters,
      FirebaseMessaging.payloadTypeSettingsSports,
      FirebaseMessaging.payloadTypeSettingsFavorites,
      FirebaseMessaging.payloadTypeSettingsAssessments,
      FirebaseMessaging.payloadTypeSettingsCalendar,
      FirebaseMessaging.payloadTypeSettingsAppointments
    });
  }

  static bool isInboxContent(SettingsNotificationsContent? content) {
    return (content != SettingsNotificationsContent.preferences);
  }

  @override
  _SettingsNotificationsContentPanelState createState() => _SettingsNotificationsContentPanelState();
}

class _SettingsNotificationsContentPanelState extends State<SettingsNotificationsContentPanel> implements NotificationsListener {
  static final double _defaultPadding = 16;
  static SettingsNotificationsContent? _lastSelectedContent;
  late SettingsNotificationsContent _selectedContent;
  final GlobalKey _allContentKey = GlobalKey();
  final GlobalKey _unreadContentKey = GlobalKey();
  final GlobalKey _sheetHeaderKey = GlobalKey();
  final GlobalKey _contentDropDownKey = GlobalKey();
  double _contentWidgetHeight = 300; // default value
  bool _contentValuesVisible = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [Auth2.notifyLoginChanged]);
    
    _initInitialContent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    //return _buildScaffold();
    return _buildSheet(context);
  }

  /*Widget _buildScaffold() {
    return Scaffold(
      appBar: RootHeaderBar(key: _headerBarKey, title: Localization().getStringEx('panel.settings.notifications.header.inbox.label', 'Notifications')),
      body: _buildPage(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(key: _tabBarKey)
    );
  }*/

  Widget _buildSheet(BuildContext context) {
    // MediaQuery(data: MediaQueryData.fromWindow(WidgetsBinding.instance.window), child: SafeArea(bottom: false, child: ))
    return Column(children: [
      Container(color: Styles().colors?.white, child:
        Row(key: _sheetHeaderKey, children: [
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 16), child:
              Text(Localization().getStringEx('panel.settings.notifications.header.inbox.label', 'Notifications'), style:  Styles().textStyles?.getTextStyle("widget.sheet.title.regular"),)
            )
          ),
          Semantics( label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), inMutuallyExclusiveGroup: true, button: true, child:
            InkWell(onTap : _onTapClose, child:
              Container(padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16), child:
              Styles().images?.getImage('close', excludeFromSemantics: true),
              ),
            ),
          ),

        ],),
      ),
      Container(color: Styles().colors?.surfaceAccent, height: 1,),
      Expanded(child:
        _buildPage(context),
      )
    ],);
  }

  Widget _buildPage(BuildContext context) {
    return Column(children: <Widget>[
      Expanded(child:
        SingleChildScrollView(physics: (_contentValuesVisible ? NeverScrollableScrollPhysics() : null), child:
          _buildContent()
        )
      )
    ]);
  }

  Widget _buildContent() {
    return Container(color: Styles().colors!.background, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(key: _contentDropDownKey, padding: EdgeInsets.only(left: _defaultPadding, top: _defaultPadding, right: _defaultPadding), child:
          RibbonButton(
            textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat.secondary"),
            backgroundColor: Styles().colors!.white,
            borderRadius: BorderRadius.all(Radius.circular(5)),
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
            rightIconKey: (_contentValuesVisible ? 'chevron-up' : 'chevron-down'),
            label: _getContentLabel(_selectedContent),
            onTap: _changeSettingsContentValuesVisibility
          )
        ),
        Container(height: (_isInboxContent ? _contentWidgetHeight : null), child:
          Stack(children: [
            Padding(padding: EdgeInsets.all(_defaultPadding), child: _contentWidget),
            _buildContentValuesContainer()
          ])
        )
      ])
    );
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
        rightIconKey: null,
        label: _getContentLabel(contentItem),
        onTap: () => _onTapContentItem(contentItem));
  }

  void _initInitialContent() {
    // Do not allow not logged in users to view "Notifications" content
    if (!Auth2().isLoggedIn && (_lastSelectedContent != SettingsNotificationsContent.preferences)) {
      _lastSelectedContent = null;
    }
    _selectedContent = widget.content ??
        (_lastSelectedContent ?? (Auth2().isLoggedIn ? SettingsNotificationsContent.all : SettingsNotificationsContent.preferences));
  }

  void _onTapContentItem(SettingsNotificationsContent contentItem) {
    Analytics().logSelect(target: contentItem.toString(), source: widget.runtimeType.toString());
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
      MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
      takenHeight += mediaQuery.viewPadding.top + mediaQuery.viewInsets.top + 16;

      final RenderObject? contentDropDownRenderBox = _contentDropDownKey.currentContext?.findRenderObject();
      if (contentDropDownRenderBox is RenderBox) {
        takenHeight += contentDropDownRenderBox.size.height;
      }

      final RenderObject? sheetHeaderRenderBox = _sheetHeaderKey.currentContext?.findRenderObject();
      if (sheetHeaderRenderBox is RenderBox) {
        takenHeight += sheetHeaderRenderBox.size.height;
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
      case SettingsNotificationsContent.all:
        return SettingsInboxHomeContentWidget(key: _allContentKey, onTapBanner: _onTapPausedBanner,);
      case SettingsNotificationsContent.unread:
        return SettingsInboxHomeContentWidget(unread: true, key: _unreadContentKey, onTapBanner: _onTapPausedBanner);
      case SettingsNotificationsContent.preferences:
        return SettingsNotificationPreferencesContentWidget();
    }
  }

  bool get _isInboxContent => SettingsNotificationsContentPanel.isInboxContent(_selectedContent);

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: widget.runtimeType.toString());
    Navigator.of(context).pop();
  }

  void _onTapPausedBanner() {
    Analytics().logSelect(target: 'Notifications Paused', source: widget.runtimeType.toString());
    if (mounted) {
      setState(() {
        _selectedContent = _lastSelectedContent = SettingsNotificationsContent.preferences;
      });
    }
  }

  // Utilities

  String _getContentLabel(SettingsNotificationsContent content) {
    switch (content) {
      case SettingsNotificationsContent.all:
        return Localization().getStringEx('panel.settings.notifications.content.notifications.all.label', 'All Notifications');
      case SettingsNotificationsContent.unread:
        return Localization().getStringEx('panel.settings.notifications.content.notifications.unread.label', 'Unread Notifications');
      case SettingsNotificationsContent.preferences:
        return Localization().getStringEx('panel.settings.notifications.content.preferences.label', 'My Notification Preferences');
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if (name == Auth2.notifyLoginChanged) {
      if ((_selectedContent != SettingsNotificationsContent.preferences) && !Auth2().isLoggedIn) {
        // Do not allow not logged in users to view "Notifications" content
        _selectedContent = _lastSelectedContent = SettingsNotificationsContent.preferences;
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

}
