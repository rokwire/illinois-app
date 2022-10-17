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

import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as firebase;

import 'SettingsWidgets.dart';

class SettingsNotificationPreferencesContentWidget extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => _SettingsNotificationPreferencesContentWidgetState();
}

class _SettingsNotificationPreferencesContentWidgetState extends State<SettingsNotificationPreferencesContentWidget> implements NotificationsListener{
  bool _notificationsAuthorized = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      FirebaseMessaging.notifySettingUpdated,
      FlexUI.notifyChanged,
    ]);

    _checkNotificationsEnabled();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  void _checkNotificationsEnabled() {
    firebase.FirebaseMessaging.instance.getNotificationSettings().then((settings) {
      firebase.AuthorizationStatus status = settings.authorizationStatus;
      setState(() {
        _notificationsAuthorized = firebase.AuthorizationStatus.authorized == status;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    return Container(
      child: Column(children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            Localization().getStringEx("panel.settings.notifications.label.desctiption", "Don’t miss an event or campus update."),
            style: Styles().textStyles?.getTextStyle("widget.message.regular.fat"),
          ),),
        Container(height: 24,),
        InfoButton(
          title: Localization().getStringEx("panel.settings.notifications.label.notifications", "Notifications"),
          description: _notificationsStatus,
          additionalInfo: Localization().getStringEx("panel.settings.notifications.label.info", "To receive notifications enable in your device's settings."),
          iconRes: "images/notifications-blue.png",
          onTap: (){_onOpenNotifications(context);},
        ),
        Container(height: 27,),
        _buildSettings()
      ],),
    );
  }

  Widget _buildSettings(){
//  BorderRadius _bottomRounding = BorderRadius.only(bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5));
    BorderRadius _topRounding = BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5));
    List<Widget> widgets = [];

    widgets.add(_CustomToggleButton(
          enabled: _toggleButtonEnabled,
          borderRadius: _topRounding,
          label: Localization().getStringEx("panel.settings.notifications.reminders", "Event Reminders"),
          toggled: FirebaseMessaging().notifyEventReminders,
          onTap: _toggleButtonEnabled?_onEventRemindersToggled : (){},
          textStyle: _toggleButtonEnabled? Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.fat.enabled") : Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.fat.disabled")
    ));
    widgets.add(Container(color:Styles().colors!.surfaceAccent,height: 1,));
    widgets.add(_CustomToggleButton(
          enabled: _toggleButtonEnabled,
          borderRadius: BorderRadius.zero,
          label: Localization().getStringEx("panel.settings.notifications.athletics_updates", "Athletics Updates"),
          toggled: FirebaseMessaging().notifyAthleticsUpdates,
          onTap: _toggleButtonEnabled? _onAthleticsUpdatesToggled : (){},
          textStyle: _toggleButtonEnabled? Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.fat.enabled") : Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.fat.disabled")
    ));
    widgets.add(Row(children: [
      Expanded(
          child: Container(
              color: Styles().colors!.white,
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(Localization().getStringEx("panel.settings.notifications.athletics_updates.description.label", 'Based on your favorite sports'),
                      style: _notificationsEnabled ? Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.variant.enabled") : Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.variant.disabled")
                  ))))
    ]));
    widgets.add(Row(children: [Expanded(child: Container(color: Styles().colors!.white, child: Padding(padding: EdgeInsets.only(left: 10), child: Column(children: [
      _CustomToggleButton(
          enabled: _athleticsSubNotificationsEnabled,
          borderRadius: BorderRadius.zero,
          label: Localization().getStringEx("panel.settings.notifications.athletics_updates.start.label", "Start"),
          toggled: FirebaseMessaging().notifyStartAthleticsUpdates,
          onTap: _athleticsSubNotificationsEnabled ? _onAthleticsUpdatesStartToggled : (){},
          textStyle: _athleticsSubNotificationsEnabled ?  Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.enabled") : Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.disabled")
    ),
      _CustomToggleButton(
          enabled: _athleticsSubNotificationsEnabled,
          borderRadius: BorderRadius.zero,
          label: Localization().getStringEx("panel.settings.notifications.athletics_updates.end.label", "End"),
          toggled: FirebaseMessaging().notifyEndAthleticsUpdates,
          onTap: _athleticsSubNotificationsEnabled ? _onAthleticsUpdatesEndToggled : (){},
          textStyle: _athleticsSubNotificationsEnabled ? Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.enabled") : Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.disabled")
      ),
      _CustomToggleButton(
          enabled: _athleticsSubNotificationsEnabled,
          borderRadius: BorderRadius.zero,
          label: Localization().getStringEx("panel.settings.notifications.athletics_updates.news.label", "News"),
          toggled: FirebaseMessaging().notifyNewsAthleticsUpdates,
          onTap: _athleticsSubNotificationsEnabled ? _onAthleticsUpdatesNewsToggled : (){},
          textStyle: _athleticsSubNotificationsEnabled ? Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.enabled") : Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.disabled")
    )
    ]))))]));
    widgets.add(Container(color:Styles().colors!.surfaceAccent,height: 1,));
    widgets.add(_CustomToggleButton(
        enabled: _toggleButtonEnabled,
        borderRadius: BorderRadius.zero,
        label: Localization().getStringEx("panel.settings.notifications.group_updates", "Group Updates"),
        toggled: FirebaseMessaging().notifyGroupUpdates,
        onTap: _toggleButtonEnabled? _onGroupsUpdatesToggled : (){},
        textStyle: _toggleButtonEnabled? Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.fat.enabled") : Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.fat.disabled")
    ));
    widgets.add(Row(children: [Expanded(child: Container(color: Styles().colors!.white, child: Padding(padding: EdgeInsets.only(left: 10), child: Column(children: [
      _CustomToggleButton(
          enabled: _groupsSubNotificationsEnabled,
          borderRadius: BorderRadius.zero,
          label: Localization().getStringEx("panel.settings.notifications.group_updates.posts.label", "Posts"),
          toggled: FirebaseMessaging().notifyGroupPostUpdates,
          onTap: _groupsSubNotificationsEnabled ? _onGroupsUpdatesPostsToggled : (){},
          textStyle: _groupsSubNotificationsEnabled ?Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.enabled") : Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.disabled")
        ),
      _CustomToggleButton(
          enabled: _groupsSubNotificationsEnabled,
          borderRadius: BorderRadius.zero,
          label: Localization().getStringEx("panel.settings.notifications.group_updates.event.label", "Event"),
          toggled: FirebaseMessaging().notifyGroupEventsUpdates,
          onTap: _groupsSubNotificationsEnabled ? _onGroupsUpdatesEventsToggled : (){},
          textStyle: _groupsSubNotificationsEnabled ? Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.enabled") : Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.disabled")
      ),
      _CustomToggleButton(
          enabled: _groupsSubNotificationsEnabled,
          borderRadius: BorderRadius.zero,
          label: Localization().getStringEx("panel.settings.notifications.group_updates.invitations.label", "Invitations"),
          toggled: FirebaseMessaging().notifyGroupInvitationsUpdates,
          onTap: _groupsSubNotificationsEnabled ? _onGroupsUpdatesInvitationsToggled: (){},
          textStyle: _groupsSubNotificationsEnabled ? Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.enabled") : Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.disabled")
        ),
      _CustomToggleButton(
          enabled: _groupsSubNotificationsEnabled,
          borderRadius: BorderRadius.zero,
          label: Localization().getStringEx("panel.settings.notifications.group_updates.polls.label", "Polls"),
          toggled: FirebaseMessaging().notifyGroupPollsUpdates,
          onTap: _groupsSubNotificationsEnabled ? _onGroupsUpdatesPollsToggled: (){},
          textStyle: _groupsSubNotificationsEnabled ? Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.enabled") : Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.small.disabled")
      )
    ]))))]));
    widgets.add(Container(color:Styles().colors!.surfaceAccent,height: 1,));
    widgets.add(_CustomToggleButton(
        enabled: _notificationsEnabled,
        borderRadius: BorderRadius.zero,
        label: Localization().getStringEx("panel.settings.notifications.pause_notifications", "Pause all notifications"),
        toggled: FirebaseMessaging().notificationsPaused,
        onTap: _notificationsEnabled? _onPauseNotificationsToggled : (){},
        textStyle: _notificationsEnabled? Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.fat.enabled") : Styles().textStyles?.getTextStyle("panel.settings.toggle_button.title.fat.disabled")
      ));
//    widgets.add(_CustomToggleButton(
//          enabled: _notificationsEnabled,
//          borderRadius: _bottomRounding,
//          label: Localization().getStringEx("panel.settings.notifications.dining", "Dining specials"),
//          toggled: FirebaseMessaging().notifyDiningSpecials,
//          context: context,
//          onTap: _notificationsEnabled? _onDiningSpecialsToggled: (){},
//          style: _notificationsEnabled? TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold) :
//              TextStyle(color: Styles().colors.fillColorPrimaryTransparent015, fontSize: 16, fontFamily: Styles().fontFamilies.bold)));

    return Container(
      child: Padding(padding: EdgeInsets.all(0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets)),
    );
  }

  void _onOpenNotifications(BuildContext context) {
    Analytics().logSelect(target: 'Receive Notifications') ;
    _requestAuthorization(context);
  }

  void _requestAuthorization(BuildContext context) async {
    firebase.FirebaseMessaging messagingInstance = firebase.FirebaseMessaging.instance;
    firebase.NotificationSettings settings = await messagingInstance.getNotificationSettings();
    firebase.AuthorizationStatus authorizationStatus = settings.authorizationStatus;
    // There is not "notDetermined" status for android. Threat "denied" in Android like "notDetermined" in iOS
    if ((Platform.isAndroid && (authorizationStatus != firebase.AuthorizationStatus.denied)) ||
        (Platform.isIOS && (authorizationStatus != firebase.AuthorizationStatus.notDetermined))) {
      _onOpenSystemSettings();
    } else {
      firebase.NotificationSettings requestSettings = await messagingInstance.requestPermission(
          alert: true, announcement: false, badge: true, carPlay: false, criticalAlert: false, provisional: false, sound: true);
      if (requestSettings.authorizationStatus == firebase.AuthorizationStatus.authorized) {
        Analytics().updateNotificationServices();
      }
      _onOpenSystemSettings();
    }
  }
  
  void _onOpenSystemSettings() async{
    AppSettings.openAppSettings();
  }

  void _onEventRemindersToggled() {
    if(!_notificationsEnabled)
      return ;
    Analytics().logSelect(target: "Event Reminders");
    FirebaseMessaging().notifyEventReminders = !FirebaseMessaging().notifyEventReminders!;
  }

  void _onAthleticsUpdatesToggled() {
    if(!_notificationsEnabled)
      return ;
    Analytics().logSelect(target: "Athletics updates");
    FirebaseMessaging().notifyAthleticsUpdates = !FirebaseMessaging().notifyAthleticsUpdates!;
  }

  void _onAthleticsUpdatesStartToggled() {
    if(!_athleticsSubNotificationsEnabled) {
      return;
    }
    Analytics().logSelect(target: "Athletics updates: Start");
    FirebaseMessaging().notifyStartAthleticsUpdates = !FirebaseMessaging().notifyStartAthleticsUpdates!;
  }

  void _onAthleticsUpdatesEndToggled() {
    if(!_athleticsSubNotificationsEnabled) {
      return;
    }
    Analytics().logSelect(target: "Athletics updates: End");
    FirebaseMessaging().notifyEndAthleticsUpdates = !FirebaseMessaging().notifyEndAthleticsUpdates!;
  }

  void _onAthleticsUpdatesNewsToggled() {
    if(!_athleticsSubNotificationsEnabled) {
      return;
    }
    Analytics().logSelect(target: "Athletics updates: News");
    FirebaseMessaging().notifyNewsAthleticsUpdates = !FirebaseMessaging().notifyNewsAthleticsUpdates!;
  }

  void _onGroupsUpdatesToggled() {
    if(!_notificationsEnabled)
      return ;
    Analytics().logSelect(target: "Groups updates");
    FirebaseMessaging().notifyGroupUpdates = !FirebaseMessaging().notifyGroupUpdates!;
  }

  void _onPauseNotificationsToggled() {
    if(!_notificationsEnabled)
      return ;
    Analytics().logSelect(target: "Pause Notifications");
    FirebaseMessaging().notificationsPaused = !FirebaseMessaging().notificationsPaused!;
  }

  void _onGroupsUpdatesPostsToggled() {
    if(!_notificationsEnabled)
      return ;
    Analytics().logSelect(target: "Posts updates");
    FirebaseMessaging().notifyGroupPostUpdates = !FirebaseMessaging().notifyGroupPostUpdates!;
  }

  void _onGroupsUpdatesInvitationsToggled() {
    if(!_notificationsEnabled)
      return ;
    Analytics().logSelect(target: "Invitations updates");
    FirebaseMessaging().notifyGroupInvitationsUpdates = !FirebaseMessaging().notifyGroupInvitationsUpdates!;
  }

  void _onGroupsUpdatesPollsToggled() {
    if(!_notificationsEnabled)
      return ;
    Analytics().logSelect(target: "Invitations updates");
    FirebaseMessaging().notifyGroupPollsUpdates = !FirebaseMessaging().notifyGroupPollsUpdates!;
  }

  void _onGroupsUpdatesEventsToggled() {
    if(!_notificationsEnabled)
      return ;
    Analytics().logSelect(target: "Events updates");
    FirebaseMessaging().notifyGroupEventsUpdates = !FirebaseMessaging().notifyGroupEventsUpdates!;
  }

//  void _onDiningSpecialsToggled() {
//    if(!_notificationsEnabled)
//      return ;
//    Analytics().logSelect(target: "Dining Specials");
//    FirebaseMessaging().notifyDiningSpecials = !FirebaseMessaging().notifyDiningSpecials;
//  }

  bool get _notificationsEnabled {
    return _notificationsAuthorized && FlexUI().isNotificationsAvailable;
  }

  bool get _athleticsSubNotificationsEnabled {
    return (FirebaseMessaging().notifyAthleticsUpdates! && _toggleButtonEnabled);
  }

  bool get _groupsSubNotificationsEnabled {
    return (FirebaseMessaging().notifyGroupUpdates! && _toggleButtonEnabled);
  }

  bool get _toggleButtonEnabled{
    return _notificationsEnabled && !FirebaseMessaging().notificationsPaused!;
  }

  String? get _notificationsStatus{
    return _notificationsEnabled?Localization().getStringEx("panel.settings.notifications.label.status.enabled", "Enabled"): Localization().getStringEx("panel.settings.notifications.label.status.disabled", "Disabled");
  }

  @override
  void onNotification(String name, param) {
    if (name == AppLivecycle.notifyStateChanged) {
      if (param == AppLifecycleState.resumed) {
        _checkNotificationsEnabled();
      }
    } else if (name == FirebaseMessaging.notifySettingUpdated) {
      if (mounted) {
        setState(() {});
      }
    } else if (name == FlexUI.notifyChanged) {
      if (mounted) {
        setState(() {});
      }
    }
  }
}

class _CustomToggleButton extends ToggleRibbonButton {
  final bool? enabled;

  _CustomToggleButton({
    String? label,
    bool? toggled,
    void Function()? onTap,
    BoxBorder? border,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
    this.enabled,
  }) : super(
    label: label,
    toggled: (toggled == true),
    onTap: onTap,
    border: border,
    borderRadius: borderRadius,
    textStyle: textStyle,
  );

  @override
  bool get toggled => (enabled == true) && super.toggled;
}