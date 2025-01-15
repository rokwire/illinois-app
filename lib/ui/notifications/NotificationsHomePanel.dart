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
import 'package:illinois/ui/notifications/NotificationsInboxPage.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:illinois/ext/InboxMessage.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

enum NotificationsContent { all, unread }

class NotificationsHomePanel extends StatefulWidget {
  static final String routeName = 'settings_notifications_content_panel';

  final NotificationsContent? content;

  NotificationsHomePanel._({this.content});

  static void present(BuildContext context, {NotificationsContent? content}) {
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(
          context, Localization().getStringEx('panel.browse.label.offline.inbox', 'Notifications are not available while offline.'));
    } else if (!Auth2().isOidcLoggedIn) {
      AppAlert.showLoggedOutFeatureNAMessage(context, Localization().getStringEx('generic.app.feature.notifications', 'Notifications'));
    } else if (ModalRoute.of(context)?.settings.name != routeName) {
      MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
      double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 16;
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: true,
          useRootNavigator: true,
          routeSettings: RouteSettings(name: routeName),
          clipBehavior: Clip.antiAlias,
          backgroundColor: Styles().colors.background,
          constraints: BoxConstraints(maxHeight: height, minHeight: height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (context) {
            return NotificationsHomePanel._(content: content);
          });
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
      FirebaseMessaging.payloadTypeMapMyLocations,
      FirebaseMessaging.payloadTypeMapMentalHealth,
      FirebaseMessaging.payloadTypeMapStateFarmWayfinding,
      FirebaseMessaging.payloadTypeAcademics,
      FirebaseMessaging.payloadTypeAcademicsAppointments,
      FirebaseMessaging.payloadTypeAcademicsGiesCanvasCourses,
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
      FirebaseMessaging.payloadTypeProfileLogin,
      FirebaseMessaging.payloadTypeSettingsSections, //TBD deprecate. Use payloadTypeProfileLogin instead
      FirebaseMessaging.payloadTypeSettingsFoodFilters,
      FirebaseMessaging.payloadTypeSettingsSports,
      FirebaseMessaging.payloadTypeSettingsFavorites,
      FirebaseMessaging.payloadTypeSettingsAssessments,
      FirebaseMessaging.payloadTypeSettingsCalendar,
      FirebaseMessaging.payloadTypeSettingsAppointments,
      FirebaseMessaging.payloadTypeSocialMessage,
    });
  }

  @override
  _NotificationsHomePanelState createState() => _NotificationsHomePanelState();
}

class _NotificationsHomePanelState extends State<NotificationsHomePanel> implements NotificationsListener {
  late NotificationsContent? _selectedContent;

  final GlobalKey _allContentKey = GlobalKey();
  final GlobalKey _unreadContentKey = GlobalKey();
  final GlobalKey _sheetHeaderKey = GlobalKey();

  @override
  void initState() {
    NotificationService().subscribe(this, [Auth2.notifyLoginChanged]);

    if (_isContentItemEnabled(widget.content)) {
      _selectedContent = widget.content;
    } else {
      _selectedContent = _initialSelectedContent;
    }

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if (name == Auth2.notifyLoginChanged) {}
  }

  @override
  Widget build(BuildContext context) {
    return _buildSheet(context);
  }

  Widget _buildSheet(BuildContext context) {
    return Column(children: [
      Container(
          color: Styles().colors.white,
          child: Row(key: _sheetHeaderKey, children: [
            Expanded(
                child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Semantics(
                        container: true,
                        header: true,
                        child: Text(Localization().getStringEx('panel.settings.notifications.header.inbox.label', 'Notifications'),
                            style: Styles().textStyles.getTextStyle("widget.sheet.title.regular"))))),
            Semantics(
                label: Localization().getStringEx('dialog.close.title', 'Close'),
                hint: Localization().getStringEx('dialog.close.hint', ''),
                container: true,
                button: true,
                child: InkWell(
                    onTap: _onTapClose,
                    child: Container(
                        padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
                        child: Styles().images.getImage('close-circle', excludeFromSemantics: true))))
          ])),
      Container(color: Styles().colors.surfaceAccent, height: 1),
      Expanded(child: _buildContent())
    ]);
  }

  Widget _buildContent() {
    return Semantics(
        container: true,
        child: Container(
            color: Styles().colors.background,
            child: _contentWidget));
  }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: widget.runtimeType.toString());
    Navigator.of(context).pop();
  }

  void _onTapPausedBanner() {
    Analytics().logSelect(target: 'Notifications Paused', source: widget.runtimeType.toString());
    if (mounted) {
      SettingsHomeContentPanel.present(context, content: SettingsContent.notifications);
    }
  }

  // Utilities

  Widget? get _contentWidget {
    switch (_selectedContent) {
      case NotificationsContent.all:
        return NotificationsInboxPage(key: _allContentKey, onTapBanner: _onTapPausedBanner);
      case NotificationsContent.unread:
        return NotificationsInboxPage(unread: true, key: _unreadContentKey, onTapBanner: _onTapPausedBanner);
      default:
        return null;
    }
  }

  bool _isContentItemEnabled(NotificationsContent? contentItem) {
    switch (contentItem) {
      case NotificationsContent.all:
        return Auth2().isLoggedIn;
      case NotificationsContent.unread:
        return Auth2().isLoggedIn;
      default:
        return false;
    }
  }

  NotificationsContent? get _initialSelectedContent {
    for (NotificationsContent contentItem in NotificationsContent.values) {
      if (_isContentItemEnabled(contentItem)) {
        return contentItem;
      }
    }
    return null;
  }
}
