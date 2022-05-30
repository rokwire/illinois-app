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

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:illinois/ui/settings/SettingsLinkedAccountPanel.dart';
import 'package:illinois/ui/settings/SettingsLoginEmailPanel.dart';
import 'package:illinois/ui/settings/SettingsLoginPhoneConfirmPanel.dart';
import 'package:illinois/ui/settings/SettingsLoginPhoneOrEmailPanel.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_navigation.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/config.dart' as rokwire;
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/debug/DebugHomePanel.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:package_info/package_info.dart';

class SettingsSectionsContentWidget extends StatefulWidget {
  @override
  _SettingsSectionsContentWidgetState createState() => _SettingsSectionsContentWidgetState();
}

class _SettingsSectionsContentWidgetState extends State<SettingsSectionsContentWidget> implements NotificationsListener {

  static BorderRadius _bottomRounding = BorderRadius.only(bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5));
  static BorderRadius _topRounding = BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5));
  static BorderRadius _allRounding = BorderRadius.all(Radius.circular(5));
  static Border _allBorder = Border.all(color: Styles().colors!.surfaceAccent!, width: 1);

  String _versionName = "";
  bool _connectingNetId = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
      Auth2.notifyLinkChanged,
      Auth2.notifyPrefsChanged,
      FirebaseMessaging.notifySettingUpdated,
      FlexUI.notifyChanged,
      Styles.notifyChanged
    ]);
    _loadVersionInfo();

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyLoginChanged) {
      _updateState();
    } else if (name == Auth2.notifyLinkChanged){
      _updateState();
    } else if (name == Auth2.notifyPrefsChanged){
      _updateState();
    } else if (name == FirebaseMessaging.notifySettingUpdated) {
      _updateState();
    } else if (name == FlexUI.notifyChanged) {
      _updateState();
    } else if (name == Styles.notifyChanged) {
      _updateState();
    }
  }

  @override
  Widget build(BuildContext context) {
    
    List<Widget> contentList = [];

    List<dynamic> codes = FlexUI()['settings'] ?? [];

    for (String code in codes) {
      if (code == 'connect') {
        contentList.add(_buildConnect());
      }
      else if (code == 'connected') {
        contentList.add(_buildConnected());
      }
      else if (code == 'linked') {
        contentList.add(_buildLinked());
      }
      else if (code == 'feedback') {
        contentList.add(_buildFeedback(),);
      }
    }

    if (kDebugMode || (Config().configEnvironment == rokwire.ConfigEnvironment.dev)) {
      contentList.add(_buildDebug());
    }

    contentList.add(_buildVersionInfo());
    
    contentList.add(Container(height: 12,),);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList);
  }

  // Connect

  Widget _buildConnect() {
    List<Widget> contentList =  [];
    contentList.add(Padding(
        padding: EdgeInsets.only(bottom: 2),
        child: Text(
          Localization().getStringEx("panel.settings.home.connect.not_logged_in.title", "Sign in to Illinois"),
          style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20),
        ),
      ),
    );

    List<dynamic> codes = FlexUI()['settings.connect'] ?? [];
    for (String code in codes) {
      if (code == 'netid') {
          contentList.add(Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: new RichText(
              text: new TextSpan(
                style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16),
                children: <TextSpan>[
                  new TextSpan(text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.description.part_1", "Are you a ")),
                  new TextSpan(
                      text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.description.part_2", "university student"),
                      style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold)),
                  new TextSpan(text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.description.part_3", " or ")),
                  new TextSpan(
                      text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.description.part_4", "employee"),
                      style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold)),
                  new TextSpan(
                      text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.description.part_5",
                          "? Sign in with your NetID to see Illinois information specific to you, like your Illini Cash and meal plan."))
                ],
              ),
            )),);
          contentList.add(RibbonButton(
            border: _allBorder,
            borderRadius: _allRounding,
            label: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.title", "Sign in with your NetID"),
            progress: _connectingNetId == true,
            onTap: _onConnectNetIdClicked
          ),);
      }
      else if (code == 'phone_or_email') {
          contentList.add(Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: new RichText(
              text: new TextSpan(
                style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16),
                children: <TextSpan>[
                  new TextSpan(
                      text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.phone_or_email.description.part_1", "Don't have a NetID? "),
                      style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold)),
                  new TextSpan(
                      text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.phone_or_email.description.part_2",
                          "Verify your phone number or sign in by email to save your preferences and have the same experience on more than one device.")),
                ],
              ),
            )),);
          contentList.add(RibbonButton(
            borderRadius: _allRounding,
            border: _allBorder,
            label: Localization().getStringEx("panel.settings.home.connect.not_logged_in.phone_or_email.title", "Continue"),
            onTap: _onPhoneOrEmailLoginClicked),);
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: contentList),
    );
  }

  void _onConnectNetIdClicked() {
    Analytics().logSelect(target: "Connect netId");
    if (_connectingNetId != true) {
      setState(() { _connectingNetId = true; });
      Auth2().authenticateWithOidc().then((Auth2OidcAuthenticateResult? result) {
        if (mounted) {
          setState(() { _connectingNetId = false; });
          if (result != Auth2OidcAuthenticateResult.succeeded) {
            AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
          }
        }
      });
    }
  }

  void _onPhoneOrEmailLoginClicked() {
    Analytics().logSelect(target: "Phone or Email Login");
    if (Connectivity().isNotOffline) {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) => SettingsLoginPhoneOrEmailPanel(onFinish: () {
        _popToMe();
      },),),);
    } else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.settings.label.offline.phone_or_email', 'Feature not available when offline.'));
    }
  }

  void _popToMe() {
    Navigator.of(context).popUntil((Route route){
      return AppNavigation.routeRootWidget(route, context: context)?.runtimeType == widget.runtimeType;
    });
  }

  // Connected

  Widget _buildConnected() {
    List<Widget> contentList =  [];

    List<dynamic> codes = FlexUI()['settings.connected'] ?? [];
    for (String code in codes) {
      if (code == 'netid') {
        contentList.addAll(_buildConnectedNetIdLayout());
      }
      else if (code == 'phone') {
        contentList.addAll(_buildConnectedPhoneLayout());
      }
      else if (code == 'email') {
        contentList.addAll(_buildConnectedEmailLayout());
      }
    }

    return Visibility(
        visible: CollectionUtils.isNotEmpty(contentList),
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                    color: Styles().colors!.white,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList))));
  }

  List<Widget> _buildConnectedNetIdLayout() {
    List<Widget> contentList = [];

    List<dynamic> codes = FlexUI()['settings.connected.netid'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      if (code == 'info') {
        contentList.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(Localization().getStringEx("panel.settings.home.net_id.message", "Signed in with your NetID"),
                  style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 16)),
              Padding(padding: EdgeInsets.only(top: 3), child: Text(Auth2().fullName ?? "",
                  style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20))),
            ]));
      }
      else if (code == 'disconnect') {
        contentList.add(Padding(
            padding: EdgeInsets.only(top: 12),
            child: RoundedButton(
                contentWeight: 0.45,
                fontSize: 16,
                conentAlignment: MainAxisAlignment.start,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                label: Localization().getStringEx("panel.settings.home.net_id.button.disconnect", "Sign Out"),
                onTap: _onDisconnectNetIdClicked)));
      }
    }

    return contentList;
  }

  List<Widget> _buildConnectedPhoneLayout() {
    List<Widget> contentList = [];

    String fullName = Auth2().fullName ?? "";
    bool hasFullName = StringUtils.isNotEmpty(fullName);

    List<dynamic> codes = FlexUI()['settings.connected.phone'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      if (code == 'info') {
        contentList.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(Localization().getStringEx("panel.settings.home.phone_ver.message", "Signed in with your Phone"),
              style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 16)),
          Visibility(
              visible: hasFullName,
              child: Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Text(fullName,
                      style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20)))),
          Padding(
              padding: EdgeInsets.only(top: 3),
              child: Text(Auth2().account?.authType?.phone ?? "",
                  style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20)))
        ]));
      }
      else if (code == 'verify') {
        contentList.add(RibbonButton(
            border: _allBorder,
            borderRadius: _allRounding,
            label: Localization().getStringEx("panel.settings.home.phone_ver.button.connect", "Verify Your Phone Number"),
            onTap: _onPhoneOrEmailLoginClicked));
      }
      else if (code == 'disconnect') {
        contentList.add(Padding(
            padding: EdgeInsets.only(top: 12),
            child: RoundedButton(
                contentWeight: 0.45,
                fontSize: 16,
                conentAlignment: MainAxisAlignment.start,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                label: Localization().getStringEx("panel.settings.home.phone_ver.button.disconnect", "Sign Out"),
                onTap: _onDisconnectNetIdClicked)));
      }
    }
    return contentList;
  }

  List<Widget> _buildConnectedEmailLayout() {
    List<Widget> contentList = [];

    String fullName = Auth2().fullName ?? "";
    bool hasFullName = StringUtils.isNotEmpty(fullName);

    List<dynamic> codes = FlexUI()['settings.connected.email'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      if (code == 'info') {
        contentList.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(Localization().getStringEx("panel.settings.home.email_login.message", "Signed in with your Email"),
              style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 16)),
          Visibility(
              visible: hasFullName,
              child: Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Text(fullName,
                      style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20)))),
          Padding(
              padding: EdgeInsets.only(top: 3),
              child: Text(Auth2().account?.authType?.email ?? "",
                  style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20)))
        ]));
      }
      else if (code == 'login') {
        contentList.add(RibbonButton(
            border: _allBorder,
            borderRadius: _allRounding,
            label: Localization().getStringEx("panel.settings.home.email_login.button.connect", "Login With Email"),
            onTap: _onPhoneOrEmailLoginClicked));
      }
      else if (code == 'disconnect') {
        contentList.add(Padding(
            padding: EdgeInsets.only(top: 12),
            child: RoundedButton(
                contentWeight: 0.45,
                fontSize: 16,
                conentAlignment: MainAxisAlignment.start,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                label: Localization().getStringEx("panel.settings.home.email_login.button.disconnect", "Sign Out"),
                onTap: _onDisconnectNetIdClicked)));
      }
    }
    return contentList;
  }

  void _onDisconnectNetIdClicked() {
    if(Auth2().isOidcLoggedIn) {
      Analytics().logSelect(target: "Disconnect netId");
    } if(Auth2().isPhoneLoggedIn) {
      Analytics().logSelect(target: "Disconnect phone");
    } if(Auth2().isEmailLoggedIn) {
      Analytics().logSelect(target: "Disconnect email");
    }
    showDialog(context: context, builder: (context) => _buildLogoutDialog(context));
  }

  Widget _buildLogoutDialog(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              Localization().getStringEx("panel.settings.home.logout.title", "Illinois"),
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Text(
                Localization().getStringEx("panel.settings.home.logout.message", "Are you sure you want to sign out?"),
                textAlign: TextAlign.left,
                style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Colors.black),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                    onPressed: () {
                      Analytics().logAlert(text: "Sign out", selection: "Yes");
                      Navigator.pop(context);
                      Auth2().logout();
                    },
                    child: Text(Localization().getStringEx("panel.settings.home.logout.button.yes", "Yes"))),
                TextButton(
                    onPressed: () {
                      Analytics().logAlert(text: "Sign out", selection: "No");
                      Navigator.pop(context);
                    },
                    child: Text(Localization().getStringEx("panel.settings.home.logout.no", "No")))
              ],
            ),
          ],
        ),
      ),
    );
  }


  // Linked

  Widget _buildLinked() {
    List<Widget> contentList =  [];

    List<dynamic> codes = FlexUI()['settings.linked'] ?? [];
    for (String code in codes) {
      if (code == 'netid') {
        List<Widget> linkedNetIDs = _buildLinkedNetIdLayout();
        contentList.addAll(linkedNetIDs);
      }
      else if (code == 'phone') {
        List<Widget> linkedPhones = _buildLinkedPhoneLayout();
        if (linkedPhones.length > 0 && contentList.length > 0) {
          contentList.add(Container(height: 16.0,));
        }
        contentList.addAll(linkedPhones);
      }
      else if (code == 'email') {
        List<Widget> linkedEmails = _buildLinkedEmailLayout();
        if (linkedEmails.length > 0 && contentList.length > 0) {
          contentList.add(Container(height: 16.0,));
        }
        contentList.addAll(linkedEmails);
      }
    }

    contentList.add(_buildLink());

    return (contentList.isNotEmpty) ? _OptionsSection(
      title: Localization().getStringEx("panel.settings.home.linked.title", "Alternate Sign Ins"),
      titlePadding: EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      widgets: contentList,
      showBox: false,
    ) : Container(height: 0.0,);
  }

  List<Widget> _buildLinkedNetIdLayout() {
    List<Widget> contentList = [];
    List<Auth2Type> linkedTypes = Auth2().linkedOidc;

    List<dynamic> codes = FlexUI()['settings.linked.netid'] ?? [];
    for (Auth2Type linked in linkedTypes) {
      if (StringUtils.isNotEmpty(linked.identifier) && linked.identifier != Auth2().account?.authType?.identifier) {
        for (int index = 0; index < codes.length; index++) {
          String code = codes[index];
          BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
          if (code == 'info') {
            contentList.add(Container(
                width: double.infinity,
                decoration: BoxDecoration(borderRadius: borderRadius, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1)),
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(Localization().getStringEx("panel.settings.home.linked.net_id.header", "UIN"),
                            style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 14)),
                        Text(linked.identifier!, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 16)),
                      ],
                    )
                )));
          }
        }
      }
    }

    return contentList;
  }

  List<Widget> _buildLinkedPhoneLayout() {
    List<Widget> contentList = [];
    List<Auth2Type> linkedTypes = Auth2().linkedPhone;

    List<dynamic> codes = FlexUI()['settings.linked.phone'] ?? [];
    for (Auth2Type linked in linkedTypes) {
      if (StringUtils.isNotEmpty(linked.identifier) && linked.identifier != Auth2().account?.authType?.identifier) {
        for (int index = 0; index < codes.length; index++) {
          String code = codes[index];
          BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
          if (code == 'info') {
            contentList.add(GestureDetector(onTap: (){_onTapAlternatePhone(linked);}, child: Container(
                width: double.infinity,
                decoration: BoxDecoration(borderRadius: borderRadius, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1)),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(Localization().getStringEx("panel.settings.home.linked.phone.header", "Phone"),
                            style: TextStyle(
                                color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 14)),
                        Text(linked.identifier!,
                            style:
                                TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 16)),
                      ],
                    ),
                    Expanded(child: Container()),
                    Image.asset('images/chevron-right.png')
                  ])
                ))));
          }
        }
      }
    }

    return contentList;
  }

  List<Widget> _buildLinkedEmailLayout() {
    List<Widget> contentList = [];
    List<Auth2Type> linkedTypes = Auth2().linkedEmail;

    List<dynamic> codes = FlexUI()['settings.linked.email'] ?? [];
    for (Auth2Type linked in linkedTypes) {
      if (StringUtils.isNotEmpty(linked.identifier) && linked.identifier != Auth2().account?.authType?.identifier) {
        for (int index = 0; index < codes.length; index++) {
          String code = codes[index];
          BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
          if (code == 'info') {
            contentList.add(GestureDetector(onTap: (){_onTapAlternateEmail(linked);}, child: Container(
                width: double.infinity,
                decoration: BoxDecoration(borderRadius: borderRadius, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1)),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(Localization().getStringEx("panel.settings.home.linked.email.header", "Email"),
                            style: TextStyle(
                                color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 14)),
                        Text(linked.identifier!,
                            style:
                                TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 16)),
                      ]
                    ),
                    Expanded(child: Container()),
                    Image.asset('images/chevron-right.png')
                  ]),
                ))));
          }
        }
      }
    }

    return contentList;
  }


  // Link

  Widget _buildLink() {
    List<Widget> contentList =  [];
    List<dynamic> codes = FlexUI()['settings.link'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      if (code == 'netid') {
        contentList.add(RibbonButton(
            backgroundColor: Styles().colors!.white,
            border: _allBorder, 
            borderRadius: _allRounding,
            label: Localization().getStringEx("panel.settings.home.connect.not_linked.netid.title", "Add a NetID"),
            progress: (_connectingNetId == true),
            onTap: _onLinkNetIdClicked),
        );
      }
      else if (code == 'phone') {
        contentList.add(RibbonButton(
            backgroundColor: Styles().colors!.white,
            border: _allBorder, 
            borderRadius: _allRounding,
            label: Localization().getStringEx("panel.settings.home.connect.not_linked.phone.title", "Add a phone number"),
            onTap: () =>
                _onLinkPhoneOrEmailClicked(SettingsLoginPhoneOrEmailMode.phone)),);
      }
      else if (code == 'email') {
        contentList.add(RibbonButton(
            backgroundColor: Styles().colors!.white,
            border: _allBorder, 
            borderRadius: _allRounding,
            label: Localization().getStringEx("panel.settings.home.connect.not_linked.email.title", "Add an email address"),
            onTap: () =>
                _onLinkPhoneOrEmailClicked(SettingsLoginPhoneOrEmailMode.email)),);
      }
    }

    if (contentList.length > 0) {
      return Column(children: contentList);
    }

    return Container(height: 0.0,);
  }

  void _onLinkNetIdClicked() {
    Analytics().logSelect(target: "Link Illinois NetID");
    if (Connectivity().isNotOffline) {
      SettingsDialog.show(context,
        title: Localization().getStringEx("panel.settings.link.login_prompt.title", "Sign In Required"),
        message: [ TextSpan(text: Localization().getStringEx("panel.settings.link.login_prompt.description", "For security, you must sign in again to confirm it's you before adding an alternate account.")), ],
        continueTitle: Localization().getStringEx("panel.settings.link.login_prompt.confirm.title", "Sign In"),
        onContinue: (List<String> selectedValues, OnContinueProgressController progressController ) => _onLinkNetIdReloginConfirmed(progressController),
      );
    } else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.settings.label.offline.netid', 'Feature not available when offline.'));
    }
  }

  void _onLinkNetIdReloginConfirmed(OnContinueProgressController progressController) {
      progressController(loading: true);
      _linkVerifySignIn().then((bool? result) {
        progressController(loading: false);
        _popToMe();
        if (result == true) {
          Auth2().authenticateWithOidc(link: true).then((Auth2OidcAuthenticateResult? result) {
            if (result == Auth2OidcAuthenticateResult.failed) {
              AppAlert.showDialogResult(context, Localization().getStringEx("panel.settings.netid.link.failed", "Failed to add Illinois NetID."));
            } else if (result == Auth2OidcAuthenticateResult.failedAccountExist) {
              _showNetIDAccountExistsDialog();
            }
          });
        }
      });
  }

  void _showNetIDAccountExistsDialog() {
    AppAlert.showCustomDialog(context: context,
      contentWidget: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(Localization().getStringEx("panel.settings.netid.link.failed.exists", "An account is already using this NetID."),
          style: TextStyle(color: Colors.red, fontSize: 16, fontFamily: Styles().fontFamilies!.bold),),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(Localization().getStringEx("panel.settings.netid.link.failed.exists.details",
              "1. You will need to sign in to the other account with this NetID.\n2. Go to \"Settings\" and press \"Forget all of my information\".\nYou can now use this as an alternate login."),
            style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.regular),),
        ),
      ]),
      actions: [
        TextButton(
          child: Text(Localization().getStringEx("dialog.ok.title", "OK")),
          onPressed: () {
            Navigator.pop(context, true);
          }
        ),
      ]
    );
  }

  void _onLinkPhoneOrEmailClicked(SettingsLoginPhoneOrEmailMode mode) {
    Analytics().logSelect(target: "Link ${settingsLoginPhoneOrEmailModeToString(mode)}");

    if (Connectivity().isNotOffline) {
      SettingsDialog.show(context,
        title: Localization().getStringEx("panel.settings.link.login_prompt.title", "Sign In Required"),
        message: [ TextSpan(text: Localization().getStringEx("panel.settings.link.login_prompt.description", "For security, you must sign in again to confirm it's you before adding an alternate account.")), ],
        continueTitle: Localization().getStringEx("panel.settings.link.login_prompt.confirm.title", "Sign In"),
        onContinue: (List<String> selectedValues, OnContinueProgressController progressController) => _onLinkPhoneOrEmailReloginConfirmed(mode, progressController),
      );
    } else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.settings.label.offline.phone_or_email', 'Feature not available when offline.'));
    }
  }

  void _onLinkPhoneOrEmailReloginConfirmed(SettingsLoginPhoneOrEmailMode mode, OnContinueProgressController progressController) {
    progressController(loading: true);
    _linkVerifySignIn().then((bool? result) {
      progressController(loading: false);
      _popToMe();
      if (result == true) {
        Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) => SettingsLoginPhoneOrEmailPanel(mode: mode, link: true, onFinish: () {
          _popToMe();
        },)),);
      }
    });
  }

  Future<bool?> _linkVerifySignIn() async {
    if (Auth2().isOidcLoggedIn) {
      Auth2OidcAuthenticateResult? result = await Auth2().authenticateWithOidc();
      return (result != null) ? (result == Auth2OidcAuthenticateResult.succeeded) : null;
    }
    else if (Auth2().isEmailLoggedIn) {
      Completer<bool?> completer = Completer<bool?>();
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) =>
        SettingsLoginEmailPanel(email: Auth2().account?.authType?.identifier, state: Auth2EmailAccountState.verified, onFinish: () {
          completer.complete(true);
        },)
      ),).then((_) {
        completer.complete(null);
      });
      return completer.future;
    }
    else if (Auth2().isPhoneLoggedIn) {
      Completer<bool?> completer = Completer<bool?>();
      Auth2().authenticateWithPhone(Auth2().account?.authType?.identifier).then((Auth2PhoneRequestCodeResult result) {
        if (result == Auth2PhoneRequestCodeResult.succeeded) {
          Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) =>
            SettingsLoginPhoneConfirmPanel(phoneNumber: Auth2().account?.authType?.identifier, onFinish: () {
              completer.complete(true);
            },)
          ),).then((_) {
            completer.complete(null);
          });
        }
        else {
          AppAlert.showDialogResult(context, Localization().getStringEx("panel.onboarding2.phone_or_email.phone.failed", "Failed to send phone verification code. An unexpected error has occurred.")).then((_) {
            completer.complete(null);
          });
        }
      });
      return completer.future;
    }
  }

  void _onTapAlternateEmail(Auth2Type linked) {
    Analytics().logSelect(target: "Alternate Email");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsLinkedAccountPanel(linkedAccount: linked, mode: LinkAccountMode.email,)));
  }

  void _onTapAlternatePhone(Auth2Type linked) {
    Analytics().logSelect(target: "Alternate Phone");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsLinkedAccountPanel(linkedAccount: linked, mode: LinkAccountMode.phone,)));
  }

  // Feedback

  Widget _buildFeedback() {
    final String rkwPlatformMacro = '{{rkw_platform_label}}';
    final String smartHealthyInitiativeMacro = '{{smart_healthy_initiative_label}}';
    String appDescriptionContent = Localization().getStringEx('panel.settings.home.feedback.app.description.format',
        'The Illinois App is the official campus app for the University of Illinois Urbana-Champaign. The app is powered by the $rkwPlatformMacro. The Rowkire project is an effort of the $smartHealthyInitiativeMacro, which is funded by the Office of the Provost at the University of Illinois.');
    int rkwPlatformMacroPosition = appDescriptionContent.indexOf(rkwPlatformMacro);
    int smartHealthyInitiativeMacroPosition = appDescriptionContent.indexOf(smartHealthyInitiativeMacro);
    String feedbackMsgStart = appDescriptionContent.substring(0, rkwPlatformMacroPosition);
    String feedbackMsgMiddle = appDescriptionContent.substring((rkwPlatformMacroPosition + rkwPlatformMacro.length), smartHealthyInitiativeMacroPosition);
    String feedbackMsgEnd = appDescriptionContent.substring(smartHealthyInitiativeMacroPosition + smartHealthyInitiativeMacro.length);

    return Column(
      children: <Widget>[
        Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(
                Localization().getStringEx("panel.settings.home.feedback.title", "App Feedback"),
                style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20),
              ),
              Container(height: 5,),
              Text(
                Localization().getStringEx("panel.settings.home.feedback.description", "Enjoying the app? Missing something? The University of Illinois Smart, Healthy Communities Initiative needs your ideas and input. Thank you!"),
                style: TextStyle(fontFamily: Styles().fontFamilies!.regular,color: Styles().colors!.textBackground, fontSize: 16),
              ),
            ])
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: RibbonButton(
            border: _allBorder,
            borderRadius: _allRounding,
            label: Localization().getStringEx("panel.settings.home.button.feedback.title", "Submit Feedback"),
            onTap: _onFeedbackClicked
          )
        ),
    RichText(text: TextSpan(style: TextStyle(fontFamily: Styles().fontFamilies!.regularIt, color: Styles().colors!.textBackground, fontSize: 16), children: [
      TextSpan(text: feedbackMsgStart),
      TextSpan(text: Localization().getStringEx('panel.settings.home.feedback.app.description.rokwire_platform.label', 'Rokwire opensource software platform'), style: TextStyle(decoration: TextDecoration.underline)),
      TextSpan(text: feedbackMsgMiddle),
      TextSpan(text: Localization().getStringEx('panel.settings.home.feedback.app.description.smart_healthy_initiative.label', 'Smart, Healthy Communities Initiative'), style: TextStyle(decoration: TextDecoration.underline)),
      TextSpan(text: feedbackMsgEnd)
    ]))
      ],
    );
  }

  String _constructFeedbackParams(String? email, String? phone, String? name) {
    Map params = Map();
    params['email'] = Uri.encodeComponent(email != null ? email : "");
    params['phone'] = Uri.encodeComponent(phone != null ? phone : "");
    params['name'] = Uri.encodeComponent(name != null ? name : "");

    String result = "";
    if (params.length > 0) {
      result += "?";
      params.forEach((key, value) =>
      result+= key + "=" + value + "&"
      );
      result = result.substring(0, result.length - 1); //remove the last symbol &
    }
    return result;
  }

  void _onFeedbackClicked() {
    Analytics().logSelect(target: "Provide Feedback");

    if (Connectivity().isNotOffline && (Config().feedbackUrl != null)) {
      String? email = Auth2().email;
      String? name =  Auth2().fullName;
      String? phone = Auth2().phone;
      String params = _constructFeedbackParams(email, phone, name);
      String feedbackUrl = Config().feedbackUrl! + params;

      String? panelTitle = Localization().getStringEx('panel.settings.feedback.label.title', 'PROVIDE FEEDBACK');
      Navigator.push(
          context, CupertinoPageRoute(builder: (context) => WebPanel(url: feedbackUrl, title: panelTitle,)));
    }
    else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.feedback', 'Providing a Feedback is not available while offline.'));
    }
  }

  // Debug

  Widget _buildDebug() {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: RibbonButton(
            border: _allBorder,
            borderRadius: _allRounding,
            label: Localization().getStringEx("panel.profile_info.button.debug.title", "Debug"),
            onTap: _onDebugClicked));
  }

  void _onDebugClicked() {
    Analytics().logSelect(target: "Debug");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugHomePanel()));
  }

  // Version Info
  Widget _buildVersionInfo() {
    String versionLabel = Localization().getStringEx('panel.settings.home.version.info.label', 'Illinois App Version:') + _versionName;
    return Container(
        alignment: Alignment.center,
        child: Text(versionLabel,
            style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16)));
  }

  void _loadVersionInfo() async {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        _versionName = packageInfo.version;
      });
    });
  }

  // Utilities

  BorderRadius _borderRadiusFromIndex(int index, int length) {
    int first = 0;
    int last = length - 1;
    if ((index == first) && (index < last)) {
      return _topRounding;
    }
    else if ((first < index) && (index == last)) {
      return _bottomRounding;
    }
    else if ((index == first) && (index == last)) {
      return _allRounding;
    }
    else {
      return BorderRadius.zero;
    }
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

}

class _OptionsSection extends StatelessWidget {
  final List<Widget>? widgets;
  final String? title;
  final String? description;
  final bool? showBox;
  final EdgeInsetsGeometry titlePadding;

  const _OptionsSection(
      {Key? key,
      this.widgets,
      this.title,
      this.description,
      this.showBox,
      this.titlePadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 12)})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Visibility(
            visible: StringUtils.isNotEmpty(title),
            child: Padding(
              padding: titlePadding,
              child: Text(
                (title != null) ? title! : '',
                style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20),
              ),
            ),
          ),
          StringUtils.isEmpty(description)
              ? Container()
              : Padding(
                  padding: EdgeInsets.only(left: 8, right: 8, bottom: 12),
                  child: Text(
                    description!,
                    style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16),
                  )),
          Stack(alignment: Alignment.topCenter, children: [
            Container(
              decoration: (showBox == false) ? null : BoxDecoration(
                border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0.5),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Padding(padding: EdgeInsets.all(0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets!)),
            )
          ])
        ]));
  }
}

class _DebugContainer extends StatefulWidget {

  final Widget _child;

  _DebugContainer({required Widget child}) : _child = child;

  _DebugContainerState createState() => _DebugContainerState();
}

class _DebugContainerState extends State<_DebugContainer> {

  int _clickedCount = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: widget._child,
      onTap: () {
        Log.d("On tap debug widget");
        _clickedCount++;

        if (_clickedCount == 7) {
          if (Auth2().isDebugManager) {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugHomePanel()));
          }
          _clickedCount = 0;
        }
      },
    );
  }
}