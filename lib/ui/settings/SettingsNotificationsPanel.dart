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
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/LocalNotifications.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:notification_permissions/notification_permissions.dart';

import 'SettingsWidgets.dart';

class SettingsNotificationsPanel extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => _SettingsNotificationsPanelState();
}

class _SettingsNotificationsPanelState extends State<SettingsNotificationsPanel> implements NotificationsListener{
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

  void _checkNotificationsEnabled(){
    NotificationPermissions.getNotificationPermissionStatus().then((PermissionStatus status){
      setState(() {
        _notificationsAuthorized = PermissionStatus.granted == status;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(
          Localization().getStringEx("panel.settings.notifications.label.title", "Notifications"),
          style: TextStyle(color: Styles().colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold, letterSpacing: 1.0),
        ),
      ),
      body: SingleChildScrollView(child: _buildContent()),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: <Widget>[
        Container(height: 24,),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            Localization().getStringEx("panel.settings.notifications.label.desctiption", "Don’t miss an event or campus update."),
            style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold),
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
    BorderRadius _bottomRounding = BorderRadius.only(bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5));
    BorderRadius _topRounding = BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5));
    List<Widget> widgets = [];

    widgets.add(_CustomToggleButton(
          enabled: _notificationsEnabled,
          borderRadius: _topRounding,
          label: Localization().getStringEx("panel.settings.notifications.reminders", "Event reminders"),
          toggled: FirebaseMessaging().notifyEventReminders,
          context: context,
          onTap: _notificationsEnabled?_onEventRemindersToggled : (){},
          style: _notificationsEnabled? TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold) :
              TextStyle(color: Styles().colors.fillColorPrimaryTransparent015, fontSize: 16, fontFamily: Styles().fontFamilies.bold)));
    widgets.add(Container(color:Styles().colors.surfaceAccent,height: 1,));
    widgets.add(_CustomToggleButton(
          enabled: _notificationsEnabled,
          borderRadius: BorderRadius.zero,
          label: Localization().getStringEx("panel.settings.notifications.athletics_updates", "Athletics updates"),
          toggled: FirebaseMessaging().notifyAthleticsUpdates,
          context: context,
          onTap: _notificationsEnabled? _onAthleticsUpdatesToggled : (){},
          style: _notificationsEnabled? TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold) :
              TextStyle(color: Styles().colors.fillColorPrimaryTransparent015, fontSize: 16, fontFamily: Styles().fontFamilies.bold)));
    widgets.add(Container(color:Styles().colors.surfaceAccent,height: 1,));
    widgets.add(_CustomToggleButton(
          enabled: _notificationsEnabled,
          borderRadius: _bottomRounding,
          label: Localization().getStringEx("panel.settings.notifications.dining", "Dining specials"),
          toggled: FirebaseMessaging().notifyDiningSpecials,
          context: context,
          onTap: _notificationsEnabled? _onDiningSpecialsToggled: (){},
          style: _notificationsEnabled? TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold) :
              TextStyle(color: Styles().colors.fillColorPrimaryTransparent015, fontSize: 16, fontFamily: Styles().fontFamilies.bold)));

    return Container(
      child: Padding(padding: EdgeInsets.all(0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets)),
    );
  }

  void _onOpenNotifications(BuildContext context) {
    Analytics.instance.logSelect(target: 'Receive Notifications') ;

    //Android does not need for permission for user notifications
    if (Platform.isAndroid) {
      _onOpenSystemSettings();
    } else if (Platform.isIOS) {
      _requestAuthorization(context);
    }
  }

  void _requestAuthorization(BuildContext context) async {
    bool notificationsAuthorized = await NativeCommunicator().queryNotificationsAuthorization("query");
    if (notificationsAuthorized) {
      _onOpenSystemSettings();
    } else {
      bool granted = await NativeCommunicator().queryNotificationsAuthorization("request");
      if (granted) {
        LocalNotifications().initPlugin();
        Analytics.instance.updateNotificationServices();
      }
      print('Notifications granted: $granted');
      _onOpenSystemSettings();
    }
  }
  
  void _onOpenSystemSettings() async{
    AppSettings.openAppSettings();
  }

  void _onEventRemindersToggled() {
    if(!_notificationsEnabled)
      return ;
    Analytics.instance.logSelect(target: "Event Reminders");
    FirebaseMessaging().notifyEventReminders = !FirebaseMessaging().notifyEventReminders;
  }

  void _onAthleticsUpdatesToggled() {
    if(!_notificationsEnabled)
      return ;
    Analytics.instance.logSelect(target: "Athletics updates");
    FirebaseMessaging().notifyAthleticsUpdates = !FirebaseMessaging().notifyAthleticsUpdates;
  }

  void _onDiningSpecialsToggled() {
    if(!_notificationsEnabled)
      return ;
    Analytics.instance.logSelect(target: "Dining Specials");
    FirebaseMessaging().notifyDiningSpecials = !FirebaseMessaging().notifyDiningSpecials;
  }

  bool get _notificationsEnabled{
    return _notificationsAuthorized && _matchPrivacyLevel;
  }

  bool get _matchPrivacyLevel{
    return Auth2().privacyMatch(4);
  }

  String get _notificationsStatus{
    return _notificationsEnabled?Localization().getStringEx("panel.settings.notifications.label.status.enabled", "Enabled"): Localization().getStringEx("panel.settings.notifications.label.status.disabled", "Disabled");
  }

  @override
  void onNotification(String name, param) {
    if (name == AppLivecycle.notifyStateChanged) {
      if (param == AppLifecycleState.resumed) {
        _checkNotificationsEnabled();
      }
    } else if (name == FirebaseMessaging.notifySettingUpdated) {
      setState(() {});
    }
  }
}

class _CustomToggleButton extends ToggleRibbonButton{
  final bool enabled;

  //super
  final String label;
  final GestureTapCallback onTap;
  final bool toggled;
  final BorderRadius borderRadius;
  final BoxBorder border;
  final BuildContext context; //Required in order to announce the VO status change
  final TextStyle style;
  final double height;

  _CustomToggleButton({this.style, this.enabled, this.label, this.onTap, this.toggled, this.borderRadius, this.border, this.context, this.height});

  @override
    Widget getImage() {
      return enabled? super.getImage(): Image.asset("images/off.png");
    }
}