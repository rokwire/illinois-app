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
import 'package:illinois/service/AppNavigation.dart';
import 'package:illinois/service/Auth.dart';
import 'package:illinois/service/Connectivity.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/dining/FoodFiltersPanel.dart';
import 'package:illinois/ui/onboarding/OnboardingLoginPhoneVerifyPanel.dart';
import 'package:illinois/ui/settings/SettingsRolesPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';
import 'package:package_info/package_info.dart';

import 'SettingsDebugPanel.dart';
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

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth.notifyUserPiiDataChanged,
      User.notifyUserUpdated,
      FirebaseMessaging.notifySettingUpdated,
      FlexUI.notifyChanged,
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
    if (name == Auth.notifyUserPiiDataChanged) {
      _updateState();
    } else if (name == User.notifyUserUpdated){
      _updateState();
    } else if (name == FirebaseMessaging.notifySettingUpdated) {
      _updateState();
    } else if (name == FlexUI.notifyChanged) {
      _updateState();
    }
  }

  @override
  Widget build(BuildContext context) {
    
    List<Widget> contentList = [];

    List<dynamic> codes = FlexUI()['settings'] ?? [];

    for (String code in codes) {
      if (code == 'user_info') {
        contentList.add(_buildUserInfo());
      }
      else if (code == 'connect') {
        contentList.add(_buildConnect());
      }
      else if (code == 'customizations') {
        contentList.add(_buildCustomizations());
      }
      else if (code == 'connected') {
        contentList.add(_buildConnected());
      }
      else if (code == 'notifications') {
        contentList.add(_buildNotifications());
      }
      else if (code == 'privacy') {
        contentList.add(_buildPrivacy());
      }
      else if (code == 'account') {
        contentList.add(_buildAccount());
      }
      else if (code == 'feedback') {
        contentList.add(_buildFeedback(),);
      }
    }

    if (!kReleaseMode) {
      contentList.add(_buildDebug());
    }

    contentList.add(_buildVersionInfo());
    
    contentList.add(Container(height: 12,),);

    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: _DebugContainer(
            child: Container(
          height: 40,
          child: Padding(
            //PS I know it is ugly..
            padding: EdgeInsets.only(top: 10),
            child: Text(
              Localization().getStringEx("panel.settings.home.settings.header", "Settings"),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        )),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                color: Styles().colors.background,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: contentList,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  // User Info

  Widget _buildUserInfo() {
    String fullName = Auth()?.userPiiData?.fullName ?? "";
    bool hasFullName =  AppString.isStringNotEmpty(fullName);
    String welcomeMessage = AppString.isStringNotEmpty(fullName)
        ? AppDateTime().getDayGreeting() + ","
        : Localization().getStringEx("panel.settings.home.user_info.title.sufix", "Welcome to Illinois");
    return Container(
        width: double.infinity,
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(welcomeMessage, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 20)),
              Visibility(
                visible: hasFullName,
                  child: Text(fullName, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 28))
              ),
            ])));
  }


  // Connect

  Widget _buildConnect() {
    List<Widget> contentList = new List();
    contentList.add(Padding(
        padding: EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 2),
        child: Text(
          Localization().getStringEx("panel.settings.home.connect.not_logged_in.title", "Connect to Illinois"),
          style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 20),
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
                style: TextStyle(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: 16),
                children: <TextSpan>[
                  new TextSpan(text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.description.part_1", "Are you a ")),
                  new TextSpan(
                      text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.description.part_2", "student"),
                      style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold)),
                  new TextSpan(text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.description.part_3", " or ")),
                  new TextSpan(
                      text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.description.part_4", "faculty member"),
                      style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold)),
                  new TextSpan(
                      text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.description.part_5",
                          "? Log in with your NetID to see Illinois information specific to you, like your Illini Cash and meal plan."))
                ],
              ),
            )),);
          contentList.add(RibbonButton(
            border: Border.all(color: Styles().colors.surfaceAccent, width: 0),
            borderRadius: _allRounding,
            label: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.title", "Connect your NetID"),
            onTap: _onConnectNetIdClicked),);
      }
      else if (code == 'phone') {
          contentList.add(Padding(
            padding: EdgeInsets.all(10),
            child: new RichText(
              text: new TextSpan(
                style: TextStyle(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: 16),
                children: <TextSpan>[
                  new TextSpan(
                      text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.phone.description.part_1", "Don't have a NetID"),
                      style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold)),
                  new TextSpan(
                      text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.phone.description.part_2",
                          "? Verify your phone number to save your preferences and have the same experience on more than one device.")),
                ],
              ),
            )),);
          contentList.add(RibbonButton(
            borderRadius: _allRounding,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 0),
            label: Localization().getStringEx("panel.settings.home.connect.not_logged_in.phone.title", "Verify Your Phone Number"),
            onTap: _onPhoneVerClicked),);
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
    Auth().authenticateWithShibboleth();
  }

  void _onPhoneVerClicked() {
    Analytics.instance.logSelect(target: "Phone Verification");
    if (Connectivity().isNotOffline) {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) => OnboardingLoginPhoneVerifyPanel(onFinish: _didPhoneVer,)));
    } else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.settings.label.offline.phone_ver', 'Verify Your Phone Number is not available while offline.'));
    }
  }

  void _didPhoneVer(_) {
    Navigator.of(context)?.popUntil((Route route){
      return AppNavigation.routeRootWidget(route, context: context)?.runtimeType == widget.runtimeType;
    });
  }

  // Customizations

  Widget _buildCustomizations() {
    List<Widget> customizationOptions = new List();
    List<dynamic> codes = FlexUI()['settings.customizations'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      
      BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
      
      if (code == 'roles') {
        customizationOptions.add(RibbonButton(
            borderRadius: borderRadius,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 0),
            label: Localization().getStringEx("panel.settings.home.customizations.role.title", "Who you are"),
            onTap: _onWhoAreYouClicked));
      }
      else if (code == 'interests') {
        customizationOptions.add(RibbonButton(
            borderRadius: borderRadius,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 0),
            label: Localization().getStringEx("panel.settings.home.customizations.manage_interests.title", "Manage your interests"),
            onTap: _onManageInterestsClicked));
      }
      else if (code == 'food_filters') {
        customizationOptions.add(RibbonButton(
            borderRadius: borderRadius,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 0),
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
    List<Widget> contentList = new List();

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
    }
    return Column(children: contentList,);

  }

  List<Widget> _buildConnectedNetIdLayout() {
    List<Widget> contentList = List();

    List<dynamic> codes = FlexUI()['settings.connected.netid'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
      if (code == 'info') {
        contentList.add(Container(
          width: double.infinity,
          decoration: BoxDecoration(borderRadius: borderRadius, border: Border.all(color: Styles().colors.surfaceAccent, width: 0.5)),
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text(Localization().getStringEx("panel.settings.home.net_id.message", "Connected as "),
                    style: TextStyle(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: 16)),
                Text(Auth().userPiiData?.fullName ?? "",
                    style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 20)),
              ]))));
      }
      else if (code == 'connect') {
        contentList.add(RibbonButton(
            borderRadius: borderRadius,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 0),
            label: Localization().getStringEx("panel.settings.home.net_id.button.connect", "Connect your NetID"),
            onTap: _onConnectNetIdClicked));
      }
      else if (code == 'disconnect') {
        contentList.add(RibbonButton(
            borderRadius: borderRadius,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 0),
            label: Localization().getStringEx("panel.settings.home.net_id.button.disconnect", "Disconnect your NetID"),
            onTap: _onDisconnectNetIdClicked));
      }
    }

    return contentList;
  }

  List<Widget> _buildConnectedPhoneLayout() {
    List<Widget> contentList = List();

    String fullName = Auth()?.userPiiData?.fullName ?? "";
    bool hasFullName = AppString.isStringNotEmpty(fullName);

    List<dynamic> codes = FlexUI()['settings.connected.phone'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
      if (code == 'info') {
        contentList.add(Container(
          width: double.infinity,
          decoration: BoxDecoration(borderRadius: borderRadius, border: Border.all(color: Styles().colors.surfaceAccent, width: 0.5)),
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text(Localization().getStringEx("panel.settings.home.phone_ver.message", "Verified as "),
                    style: TextStyle(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: 16)),
                Visibility(visible: hasFullName, child: Text(fullName ?? "", style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 20)),),
                Text(Auth().phoneToken?.phone ?? "", style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 20)),
              ]))));
      }
      else if (code == 'verify') {
        contentList.add(RibbonButton(
            borderRadius: borderRadius,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 0),
            label: Localization().getStringEx("panel.settings.home.phone_ver.button.connect", "Verify Your Phone Number"),
            onTap: _onPhoneVerClicked));
      }
      else if (code == 'disconnect') {
        contentList.add(RibbonButton(
            borderRadius: borderRadius,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 0),
            label: Localization().getStringEx("panel.settings.home.phone_ver.button.disconnect","Disconnect your Phone",),
            onTap: _onDisconnectNetIdClicked));
      }
    }
    return contentList;
  }

  void _onDisconnectNetIdClicked() {
    if(Auth().isShibbolethLoggedIn) {
      Analytics.instance.logSelect(target: "Disconnect netId");
    } else {
      Analytics.instance.logSelect(target: "Disconnect phone");
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
                style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Colors.black),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FlatButton(
                    onPressed: () {
                      Analytics.instance.logAlert(text: "Sign out", selection: "Yes");
                      Navigator.pop(context);
                      Auth().logout();
                    },
                    child: Text(Localization().getStringEx("panel.settings.home.logout.button.yes", "Yes"))),
                FlatButton(
                    onPressed: () {
                      Analytics.instance.logAlert(text: "Sign out", selection: "No");
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

  // NotificationsOptions

  Widget _buildNotifications() {
    List<Widget> contentList = new List();

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
    FirebaseMessaging().notifyEventReminders = !FirebaseMessaging().notifyEventReminders;
  }

  void _onAthleticsUpdatesToggled() {
    Analytics.instance.logSelect(target: "Athletics updates");
    FirebaseMessaging().notifyAthleticsUpdates = !FirebaseMessaging().notifyAthleticsUpdates;
  }

  void _onDiningSpecialsToggled() {
    Analytics.instance.logSelect(target: "Dining Specials");
    FirebaseMessaging().notifyDiningSpecials = !FirebaseMessaging().notifyDiningSpecials;
  }

  // Privacy

  Widget _buildPrivacy() {
    List<Widget> contentList = new List();

    List<dynamic> codes = FlexUI()['settings.privacy'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
      if (code == 'edit') {
        contentList.add(RibbonButton(
          borderRadius: borderRadius,
          border: Border.all(color: Styles().colors.surfaceAccent, width: 0),
          label: Localization().getStringEx("panel.settings.home.privacy.edit_my_privacy.title", "Edit My Privacy"),
          onTap: _onPrivacyClicked,
        ));
      }
      else if (code == 'statement') {
        contentList.add(RibbonButton(
          borderRadius: borderRadius,
          border: Border.all(color: Styles().colors.surfaceAccent, width: 0),
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

  // Account

  Widget _buildAccount() {
    List<Widget> contentList = new List();

    List<dynamic> codes = FlexUI()['settings.account'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
      if (code == 'personal_info') {
        contentList.add(RibbonButton(
          border: Border.all(color: Styles().colors.surfaceAccent, width: 0),
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
    if (Auth().isLoggedIn) {
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
                Localization().getStringEx("panel.settings.home.feedback.title", "We need your ideas!"),
                style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 20),
              ),
              Container(height: 5,),
              Text(
                Localization().getStringEx("panel.settings.home.feedback.description", "Enjoying the app? Missing something? Tap on the bottom to submit your idea."),
                style: TextStyle(fontFamily: Styles().fontFamilies.regular,color: Styles().colors.textBackground, fontSize: 16),
              ),
            ])
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: RoundedButton(
            label: Localization().getStringEx("panel.settings.home.button.feedback.title", "Submit Feedback"),
            hint: Localization().getStringEx("panel.settings.home.button.feedback.hint", ""),
            backgroundColor: Styles().colors.background,
            fontSize: 16.0,
            textColor: Styles().colors.fillColorPrimary,
            borderColor: Styles().colors.fillColorSecondary,
            onTap: _onFeedbackClicked,
          ),
        ),
      ],
    );
  }

  String _constructFeedbackParams(String email, String phone, String name) {
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
      String email = Auth().userPiiData?.email;
      String name =  Auth().userPiiData?.fullName;
      String phone = Auth().phoneToken?.phone;
      String params = _constructFeedbackParams(email, phone, name);
      String feedbackUrl = Config().feedbackUrl + params;

      String panelTitle = Localization().getStringEx('panel.settings.feedback.label.title', 'PROVIDE FEEDBACK');
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
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: RoundedButton(
        label: Localization().getStringEx("panel.profile_info.button.debug.title", "Debug"),
        hint: Localization().getStringEx("panel.profile_info.button.debug.hint", ""),
        backgroundColor: Styles().colors.background,
        fontSize: 16.0,
        textColor: Styles().colors.fillColorPrimary,
        borderColor: Styles().colors.fillColorSecondary,
        onTap: _onDebugClicked(),
      ),
    ); 
  }

  Function _onDebugClicked() {
    return () {
      Analytics.instance.logSelect(target: "Debug");
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsDebugPanel()));
    };
  }

  //Version Info
  Widget _buildVersionInfo(){
    return Container(
      alignment: Alignment.center,
      child:  Text(
        "Version: $_versionName",
        style: TextStyle(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: 16),
    ));
  }

  void _loadVersionInfo() async {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        _versionName = packageInfo?.version;
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
  final List<Widget> widgets;
  final String title;
  final String description;

  const _OptionsSection({Key key, this.widgets, this.title, this.description}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Text(
              title,
              style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 20),
            ),
          ),
          AppString.isStringEmpty(description)
              ? Container()
              : Padding(
                  padding: EdgeInsets.only(left: 8, right: 8, bottom: 12),
                  child: Text(
                    description,
                    style: TextStyle(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: 16),
                  )),
          Stack(alignment: Alignment.topCenter, children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Styles().colors.surfaceAccent, width: 0.5),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Padding(padding: EdgeInsets.all(0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets)),
            )
          ])
        ]));
  }
}

class _DebugContainer extends StatefulWidget {

  final Widget _child;

  _DebugContainer({@required Widget child}) : _child = child;

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
          _showPinDialog();
          _clickedCount = 0;
        }
      },
    );
  }

  void _showPinDialog(){
    TextEditingController pinController = TextEditingController(text: (!kReleaseMode || (Config().configEnvironment == ConfigEnvironment.dev)) ? this.pinOfTheDay : '');
    showDialog(context: context, barrierDismissible: false, builder: (context) =>  Dialog(
      child:  Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              Localization().getStringEx('app.title', 'Illinois'),
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Text(
                Localization().getStringEx('panel.debug.label.pin', 'Please enter pin'),
                textAlign: TextAlign.left,
                style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Colors.black),
              ),
            ),
            Container(height: 6,),
            TextField(controller: pinController, autofocus: true, keyboardType: TextInputType.number, obscureText: true,
              onSubmitted:(String value){
                _onEnterPin(value);
                }
            ,),
            Container(height: 6,),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FlatButton(
                    onPressed: () {
                      Navigator.pop(context);
                      //_finish();
                    },
                    child: Text(Localization().getStringEx('dialog.cancel.title', 'Cancel'))),
                Container(width: 6),
                FlatButton(
                    onPressed: () {
                      _onEnterPin(pinController?.text);
                      //_finish();
                    },
                    child: Text(Localization().getStringEx('dialog.ok.title', 'OK')))
              ],
            )
          ],
        ),
      ),
    ));
  }

  String get pinOfTheDay {
    return AppDateTime().formatUniLocalTimeFromUtcTime(DateTime.now(), "MMdd");
  }

  void _onEnterPin(String pin){
    if (this.pinOfTheDay == pin) {
      Navigator.pop(context);
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsDebugPanel()));
    } else {
      AppToast.show("Invalid pin");
    }
  }
}