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
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:notification_permissions/notification_permissions.dart';

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
    ]);

    _checkNotificationsEnabled();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  void _checkNotificationsEnabled(){
    NotificationPermissions.getNotificationPermissionStatus().then((PermissionStatus status){
      setState(() {
        _notificationsAuthorized = PermissionStatus.granted == status;
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
            style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold),
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
          textStyle: _toggleButtonEnabled? TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold) :
              TextStyle(color: Styles().colors!.fillColorPrimaryTransparent015, fontSize: 16, fontFamily: Styles().fontFamilies!.bold)));
    widgets.add(Container(color:Styles().colors!.surfaceAccent,height: 1,));
    widgets.add(_CustomToggleButton(
          enabled: _toggleButtonEnabled,
          borderRadius: BorderRadius.zero,
          label: Localization().getStringEx("panel.settings.notifications.athletics_updates", "Athletics Updates"),
          toggled: FirebaseMessaging().notifyAthleticsUpdates,
          onTap: _toggleButtonEnabled? _onAthleticsUpdatesToggled : (){},
          textStyle: _toggleButtonEnabled? TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold) :
              TextStyle(color: Styles().colors!.fillColorPrimaryTransparent015, fontSize: 16, fontFamily: Styles().fontFamilies!.bold)));
    widgets.add(Row(children: [
      Expanded(
          child: Container(
              color: Styles().colors!.white,
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(Localization().getStringEx("panel.settings.notifications.athletics_updates.description.label", 'Based on your favorite sports'),
                      style: _notificationsEnabled ? TextStyle(fontSize: 14, color: Styles().colors!.textSurface, fontFamily: Styles().fontFamilies!.regular) : TextStyle(fontSize: 14, color: Styles().colors!.fillColorPrimaryTransparent015, fontFamily: Styles().fontFamilies!.regular)))))
    ]));
    widgets.add(Row(children: [Expanded(child: Container(color: Styles().colors!.white, child: Padding(padding: EdgeInsets.only(left: 10), child: Column(children: [
      _CustomToggleButton(
          enabled: _athleticsSubNotificationsEnabled,
          borderRadius: BorderRadius.zero,
          label: Localization().getStringEx("panel.settings.notifications.athletics_updates.start.label", "Start"),
          toggled: FirebaseMessaging().notifyStartAthleticsUpdates,
          onTap: _athleticsSubNotificationsEnabled ? _onAthleticsUpdatesStartToggled : (){},
          textStyle: _athleticsSubNotificationsEnabled ? TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.bold) :
          TextStyle(color: Styles().colors!.fillColorPrimaryTransparent015, fontSize: 14, fontFamily: Styles().fontFamilies!.bold)),
      _CustomToggleButton(
          enabled: _athleticsSubNotificationsEnabled,
          borderRadius: BorderRadius.zero,
          label: Localization().getStringEx("panel.settings.notifications.athletics_updates.end.label", "End"),
          toggled: FirebaseMessaging().notifyEndAthleticsUpdates,
          onTap: _athleticsSubNotificationsEnabled ? _onAthleticsUpdatesEndToggled : (){},
          textStyle: _athleticsSubNotificationsEnabled ? TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.bold) :
          TextStyle(color: Styles().colors!.fillColorPrimaryTransparent015, fontSize: 14, fontFamily: Styles().fontFamilies!.bold)),
      _CustomToggleButton(
          enabled: _athleticsSubNotificationsEnabled,
          borderRadius: BorderRadius.zero,
          label: Localization().getStringEx("panel.settings.notifications.athletics_updates.news.label", "News"),
          toggled: FirebaseMessaging().notifyNewsAthleticsUpdates,
          onTap: _athleticsSubNotificationsEnabled ? _onAthleticsUpdatesNewsToggled : (){},
          textStyle: _athleticsSubNotificationsEnabled ? TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.bold) :
          TextStyle(color: Styles().colors!.fillColorPrimaryTransparent015, fontSize: 14, fontFamily: Styles().fontFamilies!.bold))
    ]))))]));
    widgets.add(Container(color:Styles().colors!.surfaceAccent,height: 1,));
    widgets.add(_CustomToggleButton(
        enabled: _toggleButtonEnabled,
        borderRadius: BorderRadius.zero,
        label: Localization().getStringEx("panel.settings.notifications.group_updates", "Group Updates"),
        toggled: FirebaseMessaging().notifyGroupUpdates,
        onTap: _toggleButtonEnabled? _onGroupsUpdatesToggled : (){},
        textStyle: _toggleButtonEnabled? TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold) :
        TextStyle(color: Styles().colors!.fillColorPrimaryTransparent015, fontSize: 16, fontFamily: Styles().fontFamilies!.bold)));
    widgets.add(Row(children: [Expanded(child: Container(color: Styles().colors!.white, child: Padding(padding: EdgeInsets.only(left: 10), child: Column(children: [
      _CustomToggleButton(
          enabled: _groupsSubNotificationsEnabled,
          borderRadius: BorderRadius.zero,
          label: Localization().getStringEx("panel.settings.notifications.group_updates.posts.label", "Posts"),
          toggled: FirebaseMessaging().notifyGroupPostUpdates,
          onTap: _groupsSubNotificationsEnabled ? _onGroupsUpdatesPostsToggled : (){},
          textStyle: _groupsSubNotificationsEnabled ? TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.bold) :
          TextStyle(color: Styles().colors!.fillColorPrimaryTransparent015, fontSize: 14, fontFamily: Styles().fontFamilies!.bold)),
      _CustomToggleButton(
          enabled: _groupsSubNotificationsEnabled,
          borderRadius: BorderRadius.zero,
          label: Localization().getStringEx("panel.settings.notifications.group_updates.event.label", "Event"),
          toggled: FirebaseMessaging().notifyGroupEventsUpdates,
          onTap: _groupsSubNotificationsEnabled ? _onGroupsUpdatesEventsToggled : (){},
          textStyle: _groupsSubNotificationsEnabled ? TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.bold) :
          TextStyle(color: Styles().colors!.fillColorPrimaryTransparent015, fontSize: 14, fontFamily: Styles().fontFamilies!.bold)),
      _CustomToggleButton(
          enabled: _groupsSubNotificationsEnabled,
          borderRadius: BorderRadius.zero,
          label: Localization().getStringEx("panel.settings.notifications.group_updates.invitations.label", "Invitations"),
          toggled: FirebaseMessaging().notifyGroupInvitationsUpdates,
          onTap: _groupsSubNotificationsEnabled ? _onGroupsUpdatesInvitationsToggled: (){},
          textStyle: _groupsSubNotificationsEnabled ? TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.bold) :
          TextStyle(color: Styles().colors!.fillColorPrimaryTransparent015, fontSize: 14, fontFamily: Styles().fontFamilies!.bold)),
      _CustomToggleButton(
          enabled: _groupsSubNotificationsEnabled,
          borderRadius: BorderRadius.zero,
          label: Localization().getStringEx("panel.settings.notifications.group_updates.polls.label", "Polls"),
          toggled: FirebaseMessaging().notifyGroupPollsUpdates,
          onTap: _groupsSubNotificationsEnabled ? _onGroupsUpdatesPollsToggled: (){},
          textStyle: _groupsSubNotificationsEnabled ? TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.bold) :
          TextStyle(color: Styles().colors!.fillColorPrimaryTransparent015, fontSize: 14, fontFamily: Styles().fontFamilies!.bold))
    ]))))]));
    widgets.add(Container(color:Styles().colors!.surfaceAccent,height: 1,));
    widgets.add(_CustomToggleButton(
        enabled: _notificationsEnabled,
        borderRadius: BorderRadius.zero,
        label: Localization().getStringEx("panel.settings.notifications.pause_notifications", "Pause all notifications"),
        toggled: FirebaseMessaging().notificationsPaused,
        onTap: _notificationsEnabled? _onPauseNotificationsToggled : (){},
        textStyle: _notificationsEnabled? TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold) :
        TextStyle(color: Styles().colors!.fillColorPrimaryTransparent015, fontSize: 16, fontFamily: Styles().fontFamilies!.bold)));
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

    //Android does not need for permission for user notifications
    if (Platform.isAndroid) {
      _onOpenSystemSettings();
    } else if (Platform.isIOS) {
      _requestAuthorization(context);
    }
  }

  void _requestAuthorization(BuildContext context) async {
    PermissionStatus permissionStatus = await NotificationPermissions.getNotificationPermissionStatus();
    if (permissionStatus != PermissionStatus.unknown) {
      _onOpenSystemSettings();
    } else {
      permissionStatus = await NotificationPermissions.requestNotificationPermissions();
      if (permissionStatus == PermissionStatus.granted) {
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

  bool get _notificationsEnabled{
    return _notificationsAuthorized && _matchPrivacyLevel;
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

  bool get _matchPrivacyLevel{
    return Auth2().privacyMatch(4);
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