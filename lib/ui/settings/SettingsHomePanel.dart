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
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/service/AppNavigation.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Groups.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/debug/DebugHomePanel.dart';
import 'package:illinois/ui/dining/FoodFiltersPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2LoginPhoneOrEmailPanel.dart';
import 'package:illinois/ui/settings/SettingsNotificationsPanel.dart';
import 'package:illinois/ui/settings/SettingsPersonalInformationPanel.dart';
import 'package:illinois/ui/settings/SettingsPrivacyCenterPanel.dart';
import 'package:illinois/ui/settings/SettingsRolesPanel.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/service/Styles.dart';
import 'package:package_info/package_info.dart';

import 'SettingsManageInterestsPanel.dart';
import 'SettingsPersonalInfoPanel.dart';
import 'SettingsPrivacyPanel.dart';

class SettingsHomePanel extends StatefulWidget {
  @override
  _SettingsHomePanelState createState() => _SettingsHomePanelState();
}

class _SettingsHomePanelState extends State<SettingsHomePanel> implements NotificationsListener {

  static BorderRadius _bottomRounding = BorderRadius.only(bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5));
  static BorderRadius _topRounding = BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5));
  static BorderRadius _allRounding = BorderRadius.all(Radius.circular(5));
  
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
    List<Widget> actionsList = [];

    List<dynamic> codes = FlexUI()['settings'] ?? [];

    for (String code in codes) {
      if (code == 'user_info') {
        contentList.add(_buildUserInfo());
      }
      else if (code == 'privacy_center') {
        contentList.add(_buildPrivacyCenterButton(),);
      }
      else if (code == 'connect') {
        contentList.add(_buildConnect());
      }
      else if (code == 'connected') {
        contentList.add(_buildConnected());
      }
      else if (code == 'customizations') {
        contentList.add(_buildCustomizations());
      }
      else if (code == 'notifications') {
        contentList.add(_buildNotifications());
      }
      else if (code == 'privacy0') {
        contentList.add(_buildPrivacy0());
      }
      else if (code == 'privacy') {
        contentList.add(_buildPrivacy(),);
      }
      else if (code == 'linked') {
        contentList.add(_buildLinked());
      }
      else if (code == 'link') {
        contentList.add(_buildLink());
      }
      else if (code == 'account') {
        contentList.add(_buildAccount());
      }
      else if (code == 'feedback') {
        contentList.add(_buildFeedback(),);
      }
      else if (code == 'delete') {
        contentList.add(_buildPrivacyDelete());
      }
    }

    if (kDebugMode || (Config().configEnvironment == ConfigEnvironment.dev)) {
      contentList.add(_buildDebug());
      actionsList.add(_buildHeaderBarDebug());
    }

    contentList.add(_buildVersionInfo());
    
    contentList.add(Container(height: 12,),);

    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: _buildHeaderBarTitle(),
        actions: actionsList,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                color: Styles().colors!.background,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: contentList,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  //Header Bar
  Widget _buildHeaderBarTitle() {
    return _DebugContainer(child:
      Text(Localization().getStringEx("panel.settings.home.settings.header", "Settings")!, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0, ), textAlign: TextAlign.center,),
    );
  }

  //Privacy Center
  Widget _buildPrivacyCenterButton(){
    return GestureDetector(
        onTap: (){
          Analytics.instance.logSelect(target: "Privacy Center");
          Navigator.push(context, CupertinoPageRoute(builder: (context) =>SettingsPrivacyCenterPanel()));
        },
        child: Semantics(
            button: true,
            child:Container(
              padding: EdgeInsets.only(left: 16, right: 16, top: 10),
              child:Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                    color: UiColors.fromHex("9318bb"),
                    //border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))]
                ),
                child:  Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(child:
                    Text(
                      Localization().getStringEx("panel.setting.home.button.privacy_center.title","Privacy Center")!, //TBD to Strings
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          color: Styles().colors!.white,
                          fontSize: 20,
                          fontFamily: Styles().fontFamilies!.bold),
                    )),
                    Image.asset("images/group-8.png", excludeFromSemantics: true,),
                  ],),
              ),
            )));
  }


  // User Info

  Widget _buildUserInfo() {
    String fullName = Auth2().fullName ?? "";
    bool hasFullName =  StringUtils.isNotEmpty(fullName);
    String welcomeMessage = StringUtils.isNotEmpty(fullName)
        ? AppDateTimeUtils.getDayGreeting() + ","
        : Localization().getStringEx("panel.settings.home.user_info.title.sufix", "Welcome to Illinois")!;
    return Container(
        width: double.infinity,
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(welcomeMessage, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20)),
              Visibility(
                visible: hasFullName,
                  child: Text(fullName, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 28))
              ),
            ])));
  }


  // Connect

  Widget _buildConnect() {
    List<Widget> contentList =  [];
    contentList.add(Padding(
        padding: EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 2),
        child: Text(
          Localization().getStringEx("panel.settings.home.connect.not_logged_in.title", "Connect to Illinois")!,
          style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20),
        ),
      ),
    );

    List<dynamic> codes = FlexUI()['settings.connect'] ?? [];
    for (String code in codes) {
      if (code == 'netid') {
          contentList.add(Padding(
            padding: EdgeInsets.all(10),
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
                          "? Log in with your NetID to see Illinois information specific to you, like your Illini Cash and meal plan."))
                ],
              ),
            )),);
          contentList.add(Stack(children: [
            RibbonButton(
              height: null,
              border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
              borderRadius: _allRounding,
              label: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.title", "Connect your NetID"),
              onTap: _onConnectNetIdClicked),
            Visibility(visible: _connectingNetId == true, child:
              Container(height: 46, child:
                Align(alignment: Alignment.centerRight, child:
                  Padding(padding: EdgeInsets.only(right: 10), child:
                    SizedBox(height: 24, width: 24, child:
                      CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), )
                    ),
                  )
                ),
              ),
            ),
          ],),);
      }
      else if (code == 'phone_or_email') {
          contentList.add(Padding(
            padding: EdgeInsets.all(10),
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
            height: null,
            borderRadius: _allRounding,
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
            label: Localization().getStringEx("panel.settings.home.connect.not_logged_in.phone_or_email.title", "Proceed"),
            onTap: _onPhoneOrEmailLoginClicked),);
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: contentList),
    );
  }

  void _onConnectNetIdClicked() {
    Analytics.instance.logSelect(target: "Connect netId");
    if (_connectingNetId != true) {
      setState(() { _connectingNetId = true; });
      Auth2().authenticateWithOidc().then((bool? result) {
        if (mounted) {
          setState(() { _connectingNetId = false; });
          if (result == false) {
            AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
          }
        }
      });
    }
  }

  void _onPhoneOrEmailLoginClicked() {
    Analytics.instance.logSelect(target: "Phone or Email Login");
    if (Connectivity().isNotOffline) {
      Navigator.push(context, CupertinoPageRoute(
        settings: RouteSettings(),
        builder: (context) => Onboarding2LoginPhoneOrEmailPanel(
          onboardingContext: {
            "link": false,
            "onContinueAction": () {
              _didLogin(context);
            }
          },
        ),
      ),);
    } else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.settings.label.offline.phone_or_email', 'Feature not available when offline.'));
    }
  }

  void _didLogin(_) {
    Navigator.of(context).popUntil((Route route){
      return AppNavigation.routeRootWidget(route, context: context)?.runtimeType == widget.runtimeType;
    });
  }


  // Customizations

  Widget _buildCustomizations() {
    List<Widget> customizationOptions =  [];
    List<dynamic> codes = FlexUI()['settings.customizations'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      
      BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
      
      if (code == 'roles') {
        customizationOptions.add(RibbonButton(
            height: null,
            borderRadius: borderRadius,
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
            label: Localization().getStringEx("panel.settings.home.customizations.role.title", "Who you are"),
            onTap: _onWhoAreYouClicked));
      }
      else if (code == 'interests') {
        customizationOptions.add(RibbonButton(
            height: null,
            borderRadius: borderRadius,
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
            label: Localization().getStringEx("panel.settings.home.customizations.manage_interests.title", "Manage your interests"),
            onTap: _onManageInterestsClicked));
      }
      else if (code == 'food_filters') {
        customizationOptions.add(RibbonButton(
            height: null,
            borderRadius: borderRadius,
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
            label: Localization().getStringEx("panel.settings.home.customizations.food_filters.title", "Food filters"),
            onTap: _onFoodFlitersClicked));
      }
    }

    return _OptionsSection(
      title: Localization().getStringEx("panel.settings.home.customizations.title", "Customizations"),
      widgets: customizationOptions,
      description: Localization().getStringEx("panel.settings.home.customizations.description", "See Illinois events, places, and teams that matter most to you."),);

  }

  void _onWhoAreYouClicked() {
    Analytics.instance.logSelect(target: "Who are you");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsRolesPanel()));
  }

  void _onManageInterestsClicked() {
    Analytics.instance.logSelect(target: "Manage Your Interests");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsManageInterestsPanel()));
  }

  void _onFoodFlitersClicked() {
    Analytics.instance.logSelect(target: "Food Filters");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => FoodFiltersPanel()));
  }

  // Connected

  Widget _buildConnected() {
    List<Widget> contentList =  [];

    List<dynamic> codes = FlexUI()['settings.connected'] ?? [];
    for (String code in codes) {
      if (code == 'netid') {
        contentList.add(_OptionsSection(
          title: Localization().getStringEx("panel.settings.home.net_id.title", "Illinois NetID"),
          widgets: _buildConnectedNetIdLayout()));
      }
      else if (code == 'phone') {
        contentList.add(_OptionsSection(
          title: Localization().getStringEx("panel.settings.home.phone_ver.title", "Phone Verification"),
          widgets: _buildConnectedPhoneLayout()));
      }
      else if (code == 'email') {
        contentList.add(_OptionsSection(
          title: Localization().getStringEx("panel.settings.home.email_login.title", "Email Login"),
          widgets: _buildConnectedEmailLayout()));
      }
    }
    return Column(children: contentList,);

  }

  List<Widget> _buildConnectedNetIdLayout() {
    List<Widget> contentList = [];

    List<dynamic> codes = FlexUI()['settings.connected.netid'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
      if (code == 'info') {
        contentList.add(Container(
          width: double.infinity,
          decoration: BoxDecoration(borderRadius: borderRadius, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0.5)),
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text(Localization().getStringEx("panel.settings.home.net_id.message", "Connected as ")!,
                    style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16)),
                Text(Auth2().fullName ?? "",
                    style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20)),
              ]))));
      }
      else if (code == 'connect') {
        contentList.add(Stack(children: [
            RibbonButton(
              height: null,
              borderRadius: borderRadius,
              border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
              label: Localization().getStringEx("panel.settings.home.net_id.button.connect", "Connect your NetID"),
              onTap: _onConnectNetIdClicked),
            Visibility(visible: _connectingNetId == true, child:
              Container(height: 46, child:
                Align(alignment: Alignment.centerRight, child:
                  Padding(padding: EdgeInsets.only(right: 10), child:
                    SizedBox(height: 24, width: 24, child:
                      CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), )
                    ),
                  )
                ),
              ),
            ),
          ],),);
      }
      else if (code == 'disconnect') {
        contentList.add(RibbonButton(
            height: null,
            borderRadius: borderRadius,
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
            label: Localization().getStringEx("panel.settings.home.net_id.button.disconnect", "Disconnect your NetID"),
            onTap: _onDisconnectNetIdClicked));
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
      BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
      if (code == 'info') {
        contentList.add(Container(
          width: double.infinity,
          decoration: BoxDecoration(borderRadius: borderRadius, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0.5)),
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text(Localization().getStringEx("panel.settings.home.phone_ver.message", "Verified as ")!,
                    style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16)),
                Visibility(visible: hasFullName, child: Text(fullName, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20)),),
                Text(Auth2().account?.authType?.phone ?? "", style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20)),
              ]))));
      }
      else if (code == 'verify') {
        contentList.add(RibbonButton(
            height: null,
            borderRadius: borderRadius,
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
            label: Localization().getStringEx("panel.settings.home.phone_ver.button.connect", "Verify Your Phone Number"),
            onTap: _onPhoneOrEmailLoginClicked));
      }
      else if (code == 'disconnect') {
        contentList.add(RibbonButton(
            height: null,
            borderRadius: borderRadius,
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
            label: Localization().getStringEx("panel.settings.home.phone_ver.button.disconnect","Disconnect your Phone",),
            onTap: _onDisconnectNetIdClicked));
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
      BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
      if (code == 'info') {
        contentList.add(Container(
          width: double.infinity,
          decoration: BoxDecoration(borderRadius: borderRadius, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0.5)),
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text(Localization().getStringEx("panel.settings.home.email_login.message", "Logged in as ")!,
                    style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16)),
                Visibility(visible: hasFullName, child: Text(fullName, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20)),),
                Text(Auth2().account?.authType?.email ?? "", style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20)),
              ]))));
      }
      else if (code == 'login') {
        contentList.add(RibbonButton(
            height: null,
            borderRadius: borderRadius,
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
            label: Localization().getStringEx("panel.settings.home.email_login.button.connect", "Login With Email"),
            onTap: _onPhoneOrEmailLoginClicked));
      }
      else if (code == 'disconnect') {
        contentList.add(RibbonButton(
            height: null,
            borderRadius: borderRadius,
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
            label: Localization().getStringEx("panel.settings.home.email_login.button.disconnect","Logout",),
            onTap: _onDisconnectNetIdClicked));
      }
    }
    return contentList;
  }

  void _onDisconnectNetIdClicked() {
    if(Auth2().isOidcLoggedIn) {
      Analytics.instance.logSelect(target: "Disconnect netId");
    } if(Auth2().isPhoneLoggedIn) {
      Analytics.instance.logSelect(target: "Disconnect phone");
    } if(Auth2().isEmailLoggedIn) {
      Analytics.instance.logSelect(target: "Disconnect email");
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
              Localization().getStringEx("panel.settings.home.logout.title", "Illinois")!,
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Text(
                Localization().getStringEx("panel.settings.home.logout.message", "Are you sure you want to sign out?")!,
                textAlign: TextAlign.left,
                style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Colors.black),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                    onPressed: () {
                      Analytics.instance.logAlert(text: "Sign out", selection: "Yes");
                      Navigator.pop(context);
                      Auth2().logout();
                    },
                    child: Text(Localization().getStringEx("panel.settings.home.logout.button.yes", "Yes")!)),
                TextButton(
                    onPressed: () {
                      Analytics.instance.logAlert(text: "Sign out", selection: "No");
                      Navigator.pop(context);
                    },
                    child: Text(Localization().getStringEx("panel.settings.home.logout.no", "No")!))
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

        // if (linkedNetIDs.length > 0) {
        //   contentList.add(_OptionsSection(
        //       // title: Localization().getStringEx("panel.settings.home.linked_net_id.title", "Linked Illinois NetID"),
        //       widgets: linkedNetIDs,
        //       showBox: false));
        // }
      }
      else if (code == 'phone') {
        List<Widget> linkedPhones = _buildLinkedPhoneLayout();
        if (linkedPhones.length > 0 && contentList.length > 0) {
          contentList.add(Container(height: 16.0,));
        }
        contentList.addAll(linkedPhones);
        // if (linkedPhones.length > 0) {
        //   contentList.add(Container(height: 16.0,));
        // }

        // if (linkedPhones.length > 0) {
        //   contentList.add(_OptionsSection(
        //       // title: Localization().getStringEx("panel.settings.home.linked_phone.title", "Linked Phone"),
        //       widgets: linkedPhones,
        //       showBox: false));
        // }
      }
      else if (code == 'email') {
        List<Widget> linkedEmails = _buildLinkedEmailLayout();
        if (linkedEmails.length > 0 && contentList.length > 0) {
          contentList.add(Container(height: 16.0,));
        }
        contentList.addAll(linkedEmails);

        // if (linkedEmails.length > 0) {
        //   contentList.add(_OptionsSection(
        //       // title: Localization().getStringEx("panel.settings.home.linked_email.title", "Linked Email"),
        //       widgets: linkedEmails,
        //       showBox: false));
        // }
      }
    }

    // if (contentList.length > 0) {
    //   contentList.insert(0, Padding(
    //     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    //     child: Text(
    //       Localization().getStringEx("panel.settings.home.linked.title", "Linked Credentials")!,
    //       style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20),
    //     ),
    //   ));
    // }
    // return Column(children: contentList,);
    return (contentList.isNotEmpty) ? _OptionsSection(
      title: Localization().getStringEx("panel.settings.home.linked.title", "Linked credentials"),
      widgets: contentList,
      showBox: false,
    ) : Container(height: 0.0,);
  }

  List<Widget> _buildLinkedNetIdLayout() {
    List<Widget> contentList = [];
    List<String> identifiers = Auth2().linkedOidcIds;

    List<dynamic> codes = FlexUI()['settings.linked.netid'] ?? [];
    for (String identifier in identifiers) {
      if (StringUtils.isNotEmpty(identifier) && identifier != Auth2().account?.authType?.identifier) {
        for (int index = 0; index < codes.length; index++) {
          String code = codes[index];
          BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
          if (code == 'info') {
            contentList.add(Container(
                width: double.infinity,
                decoration: BoxDecoration(borderRadius: borderRadius, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0.5)),
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(Localization().getStringEx("panel.settings.home.linked_net_id.header", "UIN")!,
                            style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16)),
                        Text(identifier, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20)),
                      ],
                    )
                )));
          }
          else if (code == 'options') {
            // contentList.add(Row(
            //   children: [
            //     Expanded(
            //       child: RibbonButton(
            //           height: null,
            //           borderRadius: borderRadius,
            //           border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
            //           label: Localization().getStringEx("panel.settings.home.linked_net_id.button.login", "Login"),
            //           onTap: () => _loginWithLinkedAuthType(Auth2LoginType.oidcIllinois, identifier: identifier)),
            //     ),
            //     Expanded(
            //       child: RibbonButton(
            //           height: null,
            //           borderRadius: borderRadius,
            //           border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
            //           label: Localization().getStringEx("panel.settings.home.linked_net_id.button.unlink", "Unlink"),
            //           onTap: () => _unlinkAuthType(Auth2LoginType.oidcIllinois, identifier))
            //     ),
            //   ],
            // ));
            contentList.add(RibbonButton(
                height: null,
                borderRadius: borderRadius,
                border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
                label: Localization().getStringEx("panel.settings.home.linked_net_id.button.unlink", "Unlink"),
                onTap: () => _unlinkAuthType(Auth2LoginType.oidcIllinois, identifier)));
          }
        }
        if (identifiers.indexOf(identifier) < identifiers.length - 1) {
          contentList.add(Container(height: 16.0,));
        }
      }
    }

    return contentList;
  }

  List<Widget> _buildLinkedPhoneLayout() {
    List<Widget> contentList = [];
    List<String> identifiers = Auth2().linkedPhoneIds;

    List<dynamic> codes = FlexUI()['settings.linked.phone'] ?? [];
    for (String identifier in identifiers) {
      if (StringUtils.isNotEmpty(identifier) && identifier != Auth2().account?.authType?.identifier) {
        for (int index = 0; index < codes.length; index++) {
          String code = codes[index];
          BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
          if (code == 'info') {
            contentList.add(Container(
                width: double.infinity,
                decoration: BoxDecoration(borderRadius: borderRadius, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0.5)),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(Localization().getStringEx("panel.settings.home.linked_phone.header", "Phone")!,
                          style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16)),
                      Text(identifier, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20)),
                    ],
                  )
                )));
          }
          else if (code == 'options') {
            // contentList.add(Row(
            //   children: [
            //     Expanded(
            //       child: RibbonButton(
            //           height: null,
            //           borderRadius: borderRadius,
            //           border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
            //           label: Localization().getStringEx("panel.settings.home.linked_phone.button.login", "Login"),
            //           onTap: () => _loginWithLinkedAuthType(Auth2LoginType.phoneTwilio, identifier: identifier)),
            //     ),
            //     Expanded(
            //       child: RibbonButton(
            //           height: null,
            //           borderRadius: borderRadius,
            //           border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
            //           label: Localization().getStringEx("panel.settings.home.linked_phone.button.unlink", "Unlink"),
            //           onTap: () => _unlinkAuthType(Auth2LoginType.phoneTwilio, identifier))
            //     ),
            //   ],
            // ));
            contentList.add(RibbonButton(
                height: null,
                borderRadius: borderRadius,
                border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
                label: Localization().getStringEx("panel.settings.home.linked_phone.button.unlink", "Unlink"),
                onTap: () => _unlinkAuthType(Auth2LoginType.phoneTwilio, identifier)));
          }
        }
        if (identifiers.indexOf(identifier) < identifiers.length - 1) {
          contentList.add(Container(height: 16.0,));
        }
      }
    }

    return contentList;
  }

  List<Widget> _buildLinkedEmailLayout() {
    List<Widget> contentList = [];
    List<String> identifiers = Auth2().linkedEmailIds;

    List<dynamic> codes = FlexUI()['settings.linked.email'] ?? [];
    for (String identifier in identifiers) {
      if (StringUtils.isNotEmpty(identifier) && identifier != Auth2().account?.authType?.identifier) {
        for (int index = 0; index < codes.length; index++) {
          String code = codes[index];
          BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
          if (code == 'info') {
            contentList.add(Container(
                width: double.infinity,
                decoration: BoxDecoration(borderRadius: borderRadius, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0.5)),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(Localization().getStringEx("panel.settings.home.linked_email.header", "Email")!,
                          style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16)),
                      Text(identifier, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20)),
                    ],
                  ),
                )));
          }
          else if (code == 'options') {
            // contentList.add(Row(
            //   children: [
            //     Expanded(
            //       child: RibbonButton(
            //           height: null,
            //           borderRadius: borderRadius,
            //           border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
            //           label: Localization().getStringEx("panel.settings.home.linked_email.button.login", "Login"),
            //           onTap: () => _loginWithLinkedAuthType(Auth2LoginType.email, identifier: identifier)),
            //     ),
            //     Expanded(
            //       child: RibbonButton(
            //           height: null,
            //           borderRadius: borderRadius,
            //           border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
            //           label: Localization().getStringEx("panel.settings.home.linked_email.button.unlink", "Unlink"),
            //           onTap: () => _unlinkAuthType(Auth2LoginType.email, identifier)),
            //     ),
            //   ],
            // ));
            contentList.add(RibbonButton(
                height: null,
                borderRadius: borderRadius,
                border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
                label: Localization().getStringEx("panel.settings.home.linked_email.button.unlink", "Unlink"),
                onTap: () => _unlinkAuthType(Auth2LoginType.email, identifier)));
          }
        }
        if (identifiers.indexOf(identifier) < identifiers.length - 1) {
          contentList.add(Container(height: 16.0,));
        }
      }
    }

    return contentList;
  }


  // Link

  Widget _buildLink() {
    List<Widget> contentList =  [];
    List<dynamic> codes = FlexUI()['settings.link'] ?? [];
    for (String code in codes) {
      if (code == 'netid') {
        contentList.add(Padding(
            padding: EdgeInsets.all(10),
            child: new RichText(
              text: new TextSpan(
                style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16),
                children: <TextSpan>[
                  new TextSpan(text: Localization().getStringEx("panel.settings.home.connect.not_linked.netid.description.part_1", "Are you a ")),
                  new TextSpan(
                      text: Localization().getStringEx("panel.settings.home.connect.not_linked.netid.description.part_2", "university student"),
                      style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold)),
                  new TextSpan(text: Localization().getStringEx("panel.settings.home.connect.not_linked.netid.description.part_3", " or ")),
                  new TextSpan(
                      text: Localization().getStringEx("panel.settings.home.connect.not_linked.netid.description.part_4", "employee"),
                      style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold)),
                  new TextSpan(
                      text: Localization().getStringEx("panel.settings.home.connect.not_linked.netid.description.part_5",
                          "? Link your NetID to see Illinois information specific to you, like your Illini Cash and meal plan."))
                ],
              ),
            )),);
        contentList.add(Stack(children: [
          RibbonButton(
              height: null,
              border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
              borderRadius: _allRounding,
              label: Localization().getStringEx("panel.settings.home.connect.not_linked.netid.title", "Link your NetID"),
              onTap: _onLinkNetIdClicked),
          Visibility(visible: _connectingNetId == true, child:
            Container(height: 46, child:
              Align(alignment: Alignment.centerRight, child:
                Padding(padding: EdgeInsets.only(right: 10), child:
                  SizedBox(height: 24, width: 24, child:
                    CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), )
                  ),
                )
              ),
            ),
          ),
        ],),);
      }
      else if (code == 'phone_or_email' && (!Auth2().isPhoneLinked || !Auth2().isEmailLinked)) {
        contentList.add(Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            Localization().getStringEx("panel.settings.home.connect.not_linked.phone_or_email.description",
                "Link your phone number or email address.")!,
            style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16),
          ),
        ),);
        contentList.add(RibbonButton(
            height: null,
            borderRadius: _allRounding,
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
            label: Localization().getStringEx("panel.settings.home.connect.not_linked.phone_or_email.title", "Proceed"),
            onTap: _onLinkPhoneOrEmailClicked),);
      }
    }

    if (contentList.length > 0) {
      contentList.insert(0, Padding(
        padding: EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 2),
        child: Text(
          Localization().getStringEx("panel.settings.home.connect.not_linked.title", "Link a new credential")!,
          style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20),
        ),));

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: contentList),
      );
    }

    return Container(height: 0.0,);
  }

  void _onLinkNetIdClicked() {
    Analytics.instance.logSelect(target: "Link Illinois NetID");
    if (Connectivity().isNotOffline) {
      Auth2().authenticateWithOidc(link: true).then((bool? result) {
        if (result == false) {
          AppAlert.showDialogResult(context, Localization().getStringEx("panel.settings.netid.link.failed", "Failed to link Illinois NetID."));
        }
      });
    } else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.settings.label.offline.netid', 'Feature not available when offline.'));
    }
  }

  void _onLinkPhoneOrEmailClicked() {
    Analytics.instance.logSelect(target: "Link Phone or Email");
    if (Connectivity().isNotOffline) {
      Navigator.push(context, CupertinoPageRoute(
        settings: RouteSettings(),
        builder: (context) => Onboarding2LoginPhoneOrEmailPanel(
          onboardingContext: {
            "link": true,
            "onContinueAction": () {
              _didLogin(context);
            }
          },
        ),
      ),);
    } else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.settings.label.offline.phone_or_email', 'Feature not available when offline.'));
    }
  }

  /*
  void _loginWithLinkedAuthType(Auth2LoginType loginType, {String? identifier}) {
    Analytics.instance.logSelect(target: "Login with linked auth type");
    if (Connectivity().isNotOffline) {
      Auth2().logout();
      switch (loginType) {
        case Auth2LoginType.oidcIllinois:
          setState(() { _connectingNetId = true; });
          Auth2().authenticateWithOidc().then((bool? result) {
            if (mounted) {
              setState(() { _connectingNetId = false; });
              if (result == false) {
                AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
              }
            }
          });
          break;
        case Auth2LoginType.phoneTwilio:
          Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2LoginPhoneOrEmailPanel(onboardingContext: {
            "link": false,
            "identifier": identifier,
            "onContinueAction": () {
              _didLogin(context);
            }
          },)));
          break;
        case Auth2LoginType.email:
          Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2LoginPhoneOrEmailPanel(onboardingContext: {
            "link": false,
            "identifier": identifier,
            "onContinueAction": () {
              _didLogin(context);
            }
          },)));
          break;
        default:
          break;
      }
    } else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.settings.label.offline.phone_or_email', 'Feature not available when offline.'));
    }
  }
   */

  void _unlinkAuthType(Auth2LoginType loginType, String identifier) {
    Analytics.instance.logSelect(target: "Unlink auth type");
    if (Connectivity().isNotOffline) {
      Auth2().unlinkAccountAuthType(loginType, identifier).then((bool? result) {
        if (mounted && result == false) {
          AppAlert.showDialogResult(context, Localization().getStringEx("panel.settings.home.unlink.failed", "Unlink failed."));
        }
      });
    } else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.settings.label.offline.phone_or_email', 'Feature not available when offline.'));
    }
  }


  // NotificationsOptions

  Widget _buildNotifications() {
    List<Widget> contentList =  [];

    List<dynamic> codes = FlexUI()['settings.notifications'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
      if (code == 'reminders') {
        contentList.add(ToggleRibbonButton(
            borderRadius: borderRadius,
            label: Localization().getStringEx("panel.settings.home.notifications.reminders", "Event reminders"),
            toggled: FirebaseMessaging().notifyEventReminders,
            context: context,
            onTap: _onEventRemindersToggled));
      }
      else if (code == 'athletics_updates') {
        contentList.add(ToggleRibbonButton(
            borderRadius: borderRadius,
            label: Localization().getStringEx("panel.settings.home.notifications.athletics_updates", "Athletics updates"),
            toggled: FirebaseMessaging().notifyAthleticsUpdates,
            context: context,
            onTap: _onAthleticsUpdatesToggled));
      }
      else if (code == 'dining') {
        contentList.add(ToggleRibbonButton(
            borderRadius: borderRadius,
            label: Localization().getStringEx("panel.settings.home.notifications.dining", "Dining specials"),
            toggled: FirebaseMessaging().notifyDiningSpecials,
            context: context,
            onTap: _onDiningSpecialsToggled));
      }
    }

    return _OptionsSection(
        title: Localization().getStringEx("panel.settings.home.notifications.title", "Notifications"),
        widgets: contentList);
  }

  void _onEventRemindersToggled() {
    Analytics.instance.logSelect(target: "Event Reminders");
    FirebaseMessaging().notifyEventReminders = !FirebaseMessaging().notifyEventReminders!;
  }

  void _onAthleticsUpdatesToggled() {
    Analytics.instance.logSelect(target: "Athletics updates");
    FirebaseMessaging().notifyAthleticsUpdates = !FirebaseMessaging().notifyAthleticsUpdates!;
  }

  void _onDiningSpecialsToggled() {
    Analytics.instance.logSelect(target: "Dining Specials");
    FirebaseMessaging().notifyDiningSpecials = !FirebaseMessaging().notifyDiningSpecials!;
  }


  // Privacy 0

  Widget _buildPrivacy0() {
    List<Widget> contentList =  [];

    List<dynamic> codes = FlexUI()['settings.privacy0'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
      if (code == 'edit') {
        contentList.add(RibbonButton(
          height: null,
          borderRadius: borderRadius,
          border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
          label: Localization().getStringEx("panel.settings.home.privacy.edit_my_privacy.title", "Edit My Privacy"),
          onTap: _onPrivacyClicked,
        ));
      }
      else if (code == 'statement') {
        contentList.add(RibbonButton(
          height: null,
          borderRadius: borderRadius,
          border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
          label: Localization().getStringEx("panel.settings.home.privacy.privacy_statement.title", "Privacy Statement"),
          onTap: _onPrivacyStatementClicked,
        ));
      }
    }

    return _OptionsSection(
      title: Localization().getStringEx("panel.settings.home.privacy.title", "Privacy"),
      widgets: contentList);
  }

  void _onPrivacyClicked() {
    Analytics.instance.logSelect(target: "Edit my privacy");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel()));
  }

  void _onPrivacyStatementClicked() {
    Analytics.instance.logSelect(target: "Privacy Statement");
    if (Config().privacyPolicyUrl != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: Config().privacyPolicyUrl, title: Localization().getStringEx("panel.settings.privacy_statement.label.title", "Privacy Statement"),)));
    }
  }

  // Privacy

  Widget _buildPrivacy() {
    List<Widget> contentList =  [];

    List<dynamic> codes = FlexUI()['settings.privacy'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      if (code == 'buttons') {
        contentList.add(_buildPrivacyButtons());
      }
      // else if (code == 'delete') {
      //   contentList.add(_buildPrivacyDelete());
      // }
    }

    return Padding(padding: EdgeInsets.only(left: 16, right: 16), child: Column(children: contentList,));
  }

  Widget _buildPrivacyButtons() {

    List<Widget> rowWidgets = <Widget>[];
    List<Widget> colWidgets = <Widget>[];

    List<dynamic> codes = FlexUI()['settings.privacy.buttons'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      Widget? privacyButton = _buildPrivacyButton(codes[index]);
      if (privacyButton != null) {
          if (rowWidgets.isNotEmpty) {
            rowWidgets.add(Container(width: 12),);
          }
          rowWidgets.add(Expanded(child: privacyButton));

          if (rowWidgets.length >= 3) {
            if (colWidgets.isNotEmpty) {
              colWidgets.add(Container(height: 12),);
            }
            colWidgets.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowWidgets));
            rowWidgets = <Widget>[];
          }
      }
    }

    if (0 < rowWidgets.length) {
      while (rowWidgets.length < 3) {
        rowWidgets.add(Container(width: 12),);
        rowWidgets.add(Expanded(child: Container()));
      }
      if (colWidgets.isNotEmpty) {
        colWidgets.add(Container(height: 12),);
      }
      colWidgets.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowWidgets));
    }

    return Padding(padding: EdgeInsets.only(top: 12), child: Column(children: colWidgets,));

    /*return Padding(padding: EdgeInsets.only(top: 12), child:
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Expanded(child: _PrivacyGridButton(
        title: Localization().getStringEx("panel.settings.privacy_center.button.personal_information.title", "Personal Information"),
        hint: Localization().getStringEx("panel.settings.privacy_center.button.personal_information.hint", ""),
        iconPath: 'images/group-5.png',
        onTap: _onTapPersonalInformation,
      ),),
      Container(width: 12,),
      Expanded(child: _PrivacyGridButton(
        title: Localization().getStringEx("panel.settings.privacy_center.button.notifications.title", "Notification Preferences"),
        hint: Localization().getStringEx("panel.settings.privacy_center.button.notifications.", ""),
        iconPath: 'images/notifications.png',
        onTap: _onTapNotifications,
      ),),
    ]));*/
  }

  Widget? _buildPrivacyButton(String code) {
    if (code == 'personal_info') {
      return _PrivacyGridButton(
        title: Localization().getStringEx("panel.settings.privacy_center.button.personal_information.title", "Personal Information"),
        hint: Localization().getStringEx("panel.settings.privacy_center.button.personal_information.hint", ""),
        iconPath: 'images/group-5.png',
        onTap: _onTapPersonalInformation,
      );
    }
    else if (code == 'notifications') {
      return _PrivacyGridButton(
        title: Localization().getStringEx("panel.settings.privacy_center.button.notifications.title", "Notification Preferences"),
        hint: Localization().getStringEx("panel.settings.privacy_center.button.notifications.", ""),
        iconPath: 'images/notifications.png',
        onTap: _onTapNotifications,
      );
    }
    else {
      return null;
    }
  }

  void _onTapPersonalInformation() {
    Analytics.instance.logSelect(target: "Personal Information");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPersonalInformationPanel()));
  }

  void _onTapNotifications() {
    Analytics.instance.logSelect(target: "Notifications");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsNotificationsPanel()));
  }

  // Account

  Widget _buildAccount() {
    List<Widget> contentList =  [];

    List<dynamic> codes = FlexUI()['settings.account'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
      if (code == 'personal_info') {
        contentList.add(RibbonButton(
          border: Border.all(color: Styles().colors!.surfaceAccent!, width: 0),
          borderRadius: borderRadius,
          label: Localization().getStringEx("panel.settings.home.account.personal_info.title", "Personal Info"),
          onTap: _onPersonalInfoClicked));
      }
    }

    return _OptionsSection(
      title: Localization().getStringEx("panel.settings.home.account.title", "Your Account"),
      widgets: contentList,
    );
  }

  void _onPersonalInfoClicked() {
    Analytics.instance.logSelect(target: "Personal Info");
    if (Auth2().isLoggedIn) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPersonalInfoPanel()));
    }
  }

  // Feedback

  Widget _buildFeedback(){
    return Column(
      children: <Widget>[
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(
                Localization().getStringEx("panel.settings.home.feedback.title", "We need your ideas!")!,
                style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20),
              ),
              Container(height: 5,),
              Text(
                Localization().getStringEx("panel.settings.home.feedback.description", "Enjoying the app? Missing something? Tap on the bottom to submit your idea.")!,
                style: TextStyle(fontFamily: Styles().fontFamilies!.regular,color: Styles().colors!.textBackground, fontSize: 16),
              ),
            ])
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: ScalableRoundedButton(
            label: Localization().getStringEx("panel.settings.home.button.feedback.title", "Submit Feedback"),
            hint: Localization().getStringEx("panel.settings.home.button.feedback.hint", ""),
            backgroundColor: Styles().colors!.background,
            fontSize: 16.0,
            textColor: Styles().colors!.fillColorPrimary,
            borderColor: Styles().colors!.fillColorSecondary,
            onTap: _onFeedbackClicked,
          ),
        ),
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
    Analytics.instance.logSelect(target: "Provide Feedback");

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

  // Delete Information

  Widget _buildPrivacyDelete() {
    return Padding(padding: EdgeInsets.only(left: 18, right: 18, top: 24, bottom: 12), child:
    Column(children: <Widget>[
      ScalableRoundedButton(
        backgroundColor: Styles().colors!.white,
        textColor: UiColors.fromHex("#f54400"),
        fontSize: 16,
        fontFamily: Styles().fontFamilies!.regular,
        label: Localization().getStringEx("panel.settings.privacy_center.button.delete_data.title", "Forget all of my information"),
        hint: Localization().getStringEx("panel.settings.privacy_center.label.delete.description", "This will delete all of your personal information that was shared and stored within the app."),
        shadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))],
        onTap: _onTapDeleteData,
      ),
    ],),);
  }

  void _onTapDeleteData() async{
    final String groupsSwitchTitle = "Please delete all my contributions.";
    int userPostCount = await Groups().getUserPostCount();
    bool contributeInGroups = userPostCount > 0;

    SettingsDialog.show(context,
        title: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.title", "Forget all of your information?"),
        message: [
          TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description1", "This will ")),
          TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description2", "Permanently "),style: TextStyle(fontFamily: Styles().fontFamilies!.bold)),
          TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description3", "delete all of your information. You will not be able to retrieve your data after you have deleted it. Are you sure you want to continue?")),
          //TBD localization
          TextSpan(text: contributeInGroups?
          Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description.groups", " You have contributed to Groups. Do you wish to delete all of those entries (posts, replies, and events) or leave them for others to see.") :
          ""
          ),
        ],
        options:contributeInGroups ? [groupsSwitchTitle] : null,
        initialOptionsSelection:contributeInGroups ?  [groupsSwitchTitle] : [],
        continueTitle: Localization().getStringEx("panel.settings.privacy_center.button.forget_info.title","Forget My Information"),
        onContinue: (List<String> selectedValues, OnContinueProgressController progressController ){
          progressController(loading: true);
          if(selectedValues.contains(groupsSwitchTitle)){
            Groups().deleteUserData();
          }
          _deleteUserData().then((_){
            progressController(loading: false);
            Navigator.pop(context);
          });

        },
        longButtonTitle: true
    );
  }

  Future<void> _deleteUserData() async{
    Analytics.instance.logAlert(text: "Remove My Information", selection: "Yes");
    await Auth2().deleteUser();
  }

  // Debug

  Widget _buildDebug() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ScalableRoundedButton(
        label: Localization().getStringEx("panel.profile_info.button.debug.title", "Debug"),
        hint: Localization().getStringEx("panel.profile_info.button.debug.hint", ""),
        backgroundColor: Styles().colors!.background,
        fontSize: 16.0,
        textColor: Styles().colors!.fillColorPrimary,
        borderColor: Styles().colors!.fillColorSecondary,
        onTap: _onDebugClicked,
      ),
    );
  }

  Widget _buildHeaderBarDebug() {
    return Semantics(label: Localization().getStringEx('headerbar.debug.title', 'Debug'), hint: Localization().getStringEx('headerbar.debug.hint', ''), button: true, excludeSemantics: true, child:
      IconButton(icon: Image.asset('images/debug-white.png'), onPressed: _onDebugClicked),
    );
  }

  void _onDebugClicked() {
    Analytics.instance.logSelect(target: "Debug");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugHomePanel()));
  }

  //Version Info
  Widget _buildVersionInfo(){
    return Container(
      alignment: Alignment.center,
      child:  Text(
        "Version: $_versionName",
        style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16),
    ));
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

  const _OptionsSection({Key? key, this.widgets, this.title, this.description, this.showBox}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Visibility(
            visible: StringUtils.isNotEmpty(title),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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

class _PrivacyGridButton extends StatelessWidget {
  final String? title;
  final String? hint;
  final String? iconPath;
  final void Function()? onTap;

  const _PrivacyGridButton({Key? key, this.title, this.hint, this.iconPath, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child:
      Semantics(label: title, hint: hint, button: true, excludeSemantics: true, child:
        Padding(padding: EdgeInsets.all(2), child:
          Container(
            decoration: BoxDecoration(color: (Styles().colors!.white),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]),
            child: Padding(padding: EdgeInsets.only(top: 16, bottom: 16), child:
              Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: <Widget>[
                Padding(padding: EdgeInsets.only(bottom: 16), child:
                  Image.asset(iconPath!),
                ),
                Padding(padding: EdgeInsets.only(left: 10, right: 10, top: 10), child:
                  Text(title!, textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary)))
              ],),
            ),
          ),
        ),
      ),
    );
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