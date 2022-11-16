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

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as firebase;
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class GroupMemberNotificationsPanel extends StatefulWidget {
  final String? groupId;
  final String? memberId;

  const GroupMemberNotificationsPanel({required this.groupId, required this.memberId});

  @override
  _GroupMemberNotificationsPanelState createState() => _GroupMemberNotificationsPanelState();
}

class _GroupMemberNotificationsPanelState extends State<GroupMemberNotificationsPanel> implements NotificationsListener {
  Member? _member;
  bool _notificationsAuthorized = false;
  int _loadingProgress = 0;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      FirebaseMessaging.notifySettingUpdated,
      FlexUI.notifyChanged,
    ]);
    _checkNotificationsEnabled();
    _loadMember();
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
        appBar: HeaderBar(
            title: Localization().getStringEx('panel.group_member_notifications.header.title', 'Group Notifications'),
            textAlign: TextAlign.center),
        body: Column(children: [
          Expanded(child: SingleChildScrollView(child: Container(color: Styles().colors!.background, child: _buildContent()))),
          Visibility(
              visible: (!_isLoading && (_member != null) && _toggleButtonEnabled),
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: RoundedButton(
                      label: Localization().getStringEx('panel.group_member_notifications.save.button', 'Save'), onTap: _onTapSave)))
        ]),
        backgroundColor: Styles().colors!.white);
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingContent();
    } else if (_member == null) {
      return _buildErrorContent();
    } else {
      return _buildNotificationsContent();
    }
  }

  Widget _buildLoadingContent() {
    return Center(
        child: Column(children: <Widget>[
      Container(height: MediaQuery.of(context).size.height / 3),
      CircularProgressIndicator(),
      Container(height: MediaQuery.of(context).size.height)
    ]));
  }

  Widget _buildErrorContent() {
    return Center(
        child: Column(children: <Widget>[
      Container(height: MediaQuery.of(context).size.height / 3),
      Text(Localization().getStringEx('panel.group_member_notifications.member.load.failed.msg', 'Failed to load member data.'),
          style: Styles().textStyles?.getTextStyle("panel.group_member_notifications.error.msg")),
      Container(height: MediaQuery.of(context).size.height)
    ]));
  }

  Widget _buildNotificationsContent() {
    List<Widget> preferenceWidgets = [];
    MemberNotificationsPreferences? memberPreferences = _member?.notificationsPreferences;

    preferenceWidgets.add(_EnabledToggleButton(
        enabled: _toggleButtonEnabled,
        borderRadius: BorderRadius.zero,
        label: Localization().getStringEx(
            "panel.group_member_notifications.override_notifications.label", "Override my notification preferences for this group"),
        toggled: memberPreferences?.overridePreferences ?? false,
        onTap: _toggleButtonEnabled ? _onToggleOverrideNotificationPreferences : null,
        textStyle: _toggleButtonEnabled
            ? Styles().textStyles?.getTextStyle("panel.group_member_notifications.toggle_button.title.fat.enabled")
            : Styles().textStyles?.getTextStyle("panel.group_member_notifications.toggle_button.title.fat.disabled")));
    preferenceWidgets.add(Row(children: [
      Expanded(
          child: Container(
              color: Styles().colors!.white,
              child: Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Column(children: [
                    _EnabledToggleButton(
                        enabled: _groupSubNotificationsEnabled,
                        borderRadius: BorderRadius.zero,
                        label: Localization().getStringEx("panel.group_member_notifications.posts.label", "Posts"),
                        toggled: !(memberPreferences?.mutePosts ?? false),
                        onTap: _groupSubNotificationsEnabled ? _onTogglePosts : null,
                        textStyle: _groupSubNotificationsEnabled
                            ? Styles().textStyles?.getTextStyle("panel.group_member_notifications.toggle_button.title.small.enabled")
                            : Styles().textStyles?.getTextStyle("panel.group_member_notifications.toggle_button.title.small.disabled")),
                    _EnabledToggleButton(
                        enabled: _groupSubNotificationsEnabled,
                        borderRadius: BorderRadius.zero,
                        label: Localization().getStringEx("panel.group_member_notifications.event.label", "Event"),
                        toggled: !(memberPreferences?.muteEvents ?? false),
                        onTap: _groupSubNotificationsEnabled ? _onToggleEvents : null,
                        textStyle: _groupSubNotificationsEnabled
                            ? Styles().textStyles?.getTextStyle("panel.group_member_notifications.toggle_button.title.small.enabled")
                            : Styles().textStyles?.getTextStyle("panel.group_member_notifications.toggle_button.title.small.disabled")),
                    _EnabledToggleButton(
                        enabled: _groupSubNotificationsEnabled,
                        borderRadius: BorderRadius.zero,
                        label: Localization().getStringEx("panel.group_member_notifications.invitations.label", "Invitations"),
                        toggled: !(memberPreferences?.muteInvitations ?? false),
                        onTap: _groupSubNotificationsEnabled ? _onToggleInvitations : null,
                        textStyle: _groupSubNotificationsEnabled
                            ? Styles().textStyles?.getTextStyle("panel.group_member_notifications.toggle_button.title.small.enabled")
                            : Styles().textStyles?.getTextStyle("panel.group_member_notifications.toggle_button.title.small.disabled")),
                    _EnabledToggleButton(
                        enabled: _groupSubNotificationsEnabled,
                        borderRadius: BorderRadius.zero,
                        label: Localization().getStringEx("panel.group_member_notifications.polls.label", "Polls"),
                        toggled: !(memberPreferences?.mutePolls ?? false),
                        onTap: _groupSubNotificationsEnabled ? _onTogglePolls : null,
                        textStyle: _groupSubNotificationsEnabled
                            ? Styles().textStyles?.getTextStyle("panel.group_member_notifications.toggle_button.title.small.enabled")
                            : Styles().textStyles?.getTextStyle("panel.group_member_notifications.toggle_button.title.small.disabled"))
                  ]))))
    ]));

    return Container(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: preferenceWidgets));
  }

  void _checkNotificationsEnabled() {
    _increaseProgress();
    firebase.FirebaseMessaging.instance.getNotificationSettings().then((settings) {
      firebase.AuthorizationStatus status = settings.authorizationStatus;
      _notificationsAuthorized = firebase.AuthorizationStatus.authorized == status;
      _decreaseProgress();
    });
  }

  void _loadMember() {
    _increaseProgress();
    Groups().loadMembers(groupId: widget.groupId, memberId: widget.memberId).then((members) {
      _member = members?.first;
      _decreaseProgress();
    });
  }

  void _onToggleOverrideNotificationPreferences() {
    if (!_isLoading && (_member != null)) {
      Analytics().logSelect(target: "Override Notification Preferences");
      if (_member!.notificationsPreferences == null) {
        _member!.notificationsPreferences = MemberNotificationsPreferences();
      }
      setStateIfMounted(() {
        _member!.notificationsPreferences!.overridePreferences = !(_member!.notificationsPreferences!.overridePreferences ?? false);
      });
    }
  }

  void _onTogglePosts() {
    if (!_isLoading && (_member != null)) {
      Analytics().logSelect(target: "Posts");
      if (_member!.notificationsPreferences == null) {
        _member!.notificationsPreferences = MemberNotificationsPreferences();
      }
      setStateIfMounted(() {
        _member!.notificationsPreferences!.mutePosts = !(_member!.notificationsPreferences!.mutePosts ?? false);
      });
    }
  }

  void _onToggleEvents() {
    if (!_isLoading && (_member != null)) {
      Analytics().logSelect(target: "Events");
      if (_member!.notificationsPreferences == null) {
        _member!.notificationsPreferences = MemberNotificationsPreferences();
      }
      setStateIfMounted(() {
        _member!.notificationsPreferences!.muteEvents = !(_member!.notificationsPreferences!.muteEvents ?? false);
      });
    }
  }

  void _onToggleInvitations() {
    if (!_isLoading && (_member != null)) {
      Analytics().logSelect(target: "Invitations");
      if (_member!.notificationsPreferences == null) {
        _member!.notificationsPreferences = MemberNotificationsPreferences();
      }
      setStateIfMounted(() {
        _member!.notificationsPreferences!.muteInvitations = !(_member!.notificationsPreferences!.muteInvitations ?? false);
      });
    }
  }

  void _onTogglePolls() {
    if (!_isLoading && (_member != null)) {
      Analytics().logSelect(target: "Polls");
      if (_member!.notificationsPreferences == null) {
        _member!.notificationsPreferences = MemberNotificationsPreferences();
      }
      setStateIfMounted(() {
        _member!.notificationsPreferences!.mutePolls = !(_member!.notificationsPreferences!.mutePolls ?? false);
      });
    }
  }

  void _onTapSave() {
    if (_isLoading) {
      return;
    }
    Analytics().logSelect(target: 'Save Notification Preferences');
    _saveNotificationPreferences();
  }

  void _saveNotificationPreferences() {
    _increaseProgress();
    Groups().updateMember(_member).then((success) {
      late String msg;
      if (success) {
        msg = Localization()
            .getStringEx('panel.group_member_notifications.save.success.msg', 'Notifications preferences were updated successfully.');
      } else {
        msg = Localization().getStringEx('panel.group_member_notifications.save.fail.msg', 'Failed to update notification preferences.');
      }
      AppAlert.showMessage(context, msg).then((_) {
        if (success) {
          Navigator.of(context).pop();
        }
      });
      _decreaseProgress();
    });
  }

  void _increaseProgress() {
    setStateIfMounted(() {
      _loadingProgress++;
    });
  }

  void _decreaseProgress() {
    setStateIfMounted(() {
      _loadingProgress--;
    });
  }

  bool get _isLoading => (_loadingProgress > 0);

  bool get _groupSubNotificationsEnabled {
    return ((_member?.notificationsPreferences?.overridePreferences == true) && _toggleButtonEnabled);
  }

  bool get _toggleButtonEnabled {
    return _notificationsEnabled && !FirebaseMessaging().notificationsPaused!;
  }

  bool get _notificationsEnabled {
    return _notificationsAuthorized && FlexUI().isNotificationsAvailable;
  }

  @override
  void onNotification(String name, param) {
    if (name == AppLivecycle.notifyStateChanged) {
      if (param == AppLifecycleState.resumed) {
        _checkNotificationsEnabled();
      }
    } else if (name == FirebaseMessaging.notifySettingUpdated) {
      setStateIfMounted(() {});
    } else if (name == FlexUI.notifyChanged) {
      setStateIfMounted(() {});
    }
  }
}

class _EnabledToggleButton extends ToggleRibbonButton {
  final bool? enabled;

  _EnabledToggleButton(
      {String? label,
      bool? toggled,
      void Function()? onTap,
      BoxBorder? border,
      BorderRadius? borderRadius,
      TextStyle? textStyle,
      this.enabled})
      : super(label: label, toggled: (toggled == true), onTap: onTap, border: border, borderRadius: borderRadius, textStyle: textStyle);

  @override
  bool get toggled => (enabled == true) && super.toggled;
}
