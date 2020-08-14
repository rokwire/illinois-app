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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/ui/settings/SettingsNewPrivacyPanel.dart';
import 'package:illinois/ui/settings/SettingsPersonalInformationPanel.dart';
import 'package:illinois/ui/settings/SettingsVerifyIdentityPanel.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:package_info/package_info.dart';

import 'SettingsNotificationsPanel.dart';

class SettingsPrivacyCenterPanel extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _SettingsPrivacyCenterPanelState();

}

class _SettingsPrivacyCenterPanelState extends State<SettingsPrivacyCenterPanel> implements NotificationsListener{
  String _versionName = "";

  @override
  void initState() {
    NotificationService().subscribe(this, [Auth.notifyLoginSucceeded, Auth.notifyLoginFailed, Auth.notifyStarted]);
    _loadVersionInfo();
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
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(
            Localization().getStringEx("panel.settings.privacy_center.label.title", "Privacy Center"),
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
        ),
      ),
      body: SingleChildScrollView(child:_buildContent()),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildContent(){
    return
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child:
          Column(
          children: <Widget>[
            Container(height: 51,),
            Container(
              child: Image.asset("images/group-3.png",excludeFromSemantics: true,),
            ),
            _buildFinishSetupWidget(),
            Container(height: 40,),
            Text(Localization().getStringEx("panel.settings.privacy_center.label.description", "Personalize your privacy and data preferences."),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: Styles().fontFamilies.bold,
                  fontSize: 20,
                  color: Styles().colors.fillColorPrimary
              ),
            ),
            Container(height: 20,),
            _buildSquareButtonsLayout(),
            Container(height: 39,),
            _buildPrivacyPolicyButton(),
            Container(height: 33,),
            _buildDeleteButton(),
            Container(height: 33,),
            _buildVersionInfo(),
            Container(height: 30,),
          ],
        ));
  }


  Widget _buildFinishSetupWidget(){
    return Visibility(
      visible: _showFinishSetupWidget,
      child: Semantics( container: true,
        child:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(height: 32,),
          Text(Localization().getStringEx("panel.settings.privacy_center.label.finish_setup", "Finish setup"),
            style: TextStyle(
                fontFamily: Styles().fontFamilies.extraBold,
                fontSize: 16,
                color: Styles().colors.textSurface
            ),
          ),
          Container(height: 4,),
          Text(Localization().getStringEx("panel.settings.privacy_center.label.finish_setup_description", "Log in with your NetID or Telephone number to get the full Illinois experience."),
            style: TextStyle(
                fontFamily: Styles().fontFamilies.regular,
                fontSize: 16,
                color: Styles().colors.textSurface
            ),
          ),
          Container(height: 10,),
          Semantics(explicitChildNodes: true,
            child: RibbonButton(
            leftIcon: "images/user-check.png",
            label: Localization().getStringEx("panel.settings.privacy_center.button.verify_identity.title", "Verify your Identity"),
            borderRadius: BorderRadius.circular(4),
            onTap: () => _onTapVerifyIdentity(),
          )),
        ],
      ),
    ));
  }

  Widget _buildSquareButtonsLayout(){
    TextStyle buttonTextStyle =  TextStyle(
        fontFamily: Styles().fontFamilies.bold,
        fontSize: 16,
        color: Styles().colors.fillColorPrimary);

    return
      Container(
      alignment: Alignment.topCenter,
      child: Column(children: <Widget>[
        Row(children: <Widget>[
          Expanded(
            child:
            GestureDetector(
              onTap: _onTapManagePrivacy,
              child: Semantics(
                label: Localization().getStringEx("panel.settings.privacy_center.button.manage_privacy.title", "Manage and Understand Your Privacy"),
                hint:Localization().getStringEx("panel.settings.privacy_center.button.manage_privacy.hint", ""),
                button:true,
                child:Stack(children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(2),
                    child: Container(
                      decoration: BoxDecoration(
                          color: ( Colors.white),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color:Colors.white,
                              width: 2)),
                      child: Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 19, left:26, right: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Image.asset(('images/privacy.png'),excludeFromSemantics: true,),
                            Container(width: 18,),
                            Expanded(child:
                              Semantics(  excludeSemantics: true,
                              child: Text(
                                Localization().getStringEx("panel.settings.privacy_center.button.manage_privacy.title", "Manage and Understand Your Privacy"),
                                textAlign: TextAlign.left,
                                style: buttonTextStyle,
                              )),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )),
            ),
          )
        ],),
        Container(height: 12,),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(child: _buildSquareButton(
              label: Localization().getStringEx("panel.settings.privacy_center.button.personal_information.title", "Personal Information"),
              hint: Localization().getStringEx("panel.settings.privacy_center.button.personal_information.hint", ""),
              iconPath: 'images/group-5.png',
              onTap: _onTapPersonalInformation,
              ),),
            Container(width: 12,),
            Expanded(child: _buildSquareButton(
              label: Localization().getStringEx("panel.settings.privacy_center.button.notifications.title", "Notification Preferences"),
              hint: Localization().getStringEx("panel.settings.privacy_center.button.notifications.", ""),
              iconPath: 'images/notifications.png',
              onTap: _onTapNotifications,
            )),
          ],)
      ],)
      );
  }

  Widget _buildSquareButton({Function onTap, String label, String hint, String iconPath}){
    Color _boxShadowColor = Color.fromRGBO(19, 41, 75, 0.3);

    return GestureDetector(
      onTap: onTap,
      child: Semantics(label: label, hint:hint, button:true, excludeSemantics: true, child:Stack(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(color: (Styles().colors.white),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: _boxShadowColor, spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]),
              child: Padding(
                padding: EdgeInsets.only(top: 16, bottom: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child:
                      Image.asset((iconPath)),
                    ),
                    Container(height: 10,),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child:Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.fillColorPrimary)))
                  ],
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }

  /*Widget _buildButtonsLayout(){
      return
        Container(
            alignment: Alignment.topCenter,
            child:
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RibbonButton(
                  label: Localization().getStringEx("panel.settings.privacy_center.button.personal_information.title", "Personal Information"),
                  borderRadius: BorderRadius.circular(4),
                  onTap: _onTapPersonalInformation
                ),
                Container(height: 10,),
                RibbonButton(
                  label: Localization().getStringEx("panel.settings.privacy_center.button.notifications.title", "Notification Preferences"),
                  borderRadius: BorderRadius.circular(4),
                  onTap: _onTapNotifications
                ),
              ],)
        );
  }*/

  Widget _buildPrivacyPolicyButton(){
    return
      Semantics( button: true,
      child: GestureDetector(
        onTap: _onTapPrivacyPolicy,
        child: Text(
          Localization().getStringEx("panel.settings.privacy_center.button.privacy_policy.title", "Privacy Policy"),
          style: TextStyle(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: 16, decoration: TextDecoration.underline,decorationColor:  Styles().colors.fillColorSecondary,),
      )));
  }

  //Version Info
  Widget _buildVersionInfo(){
    return
      Column(children: <Widget>[
        Container(height: 1, color: Styles().colors.surfaceAccent,),
        Container(height: 12,),
        Container(
          alignment: Alignment.center,
          child:  Text(
            "Version: $_versionName",
            style: TextStyle(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: 16),
          )),
      ],);
  }

  Widget _buildDeleteButton(){
      return
          Column(children: <Widget>[
            RoundedButton(
              backgroundColor: Styles().colors.white,
              textColor: UiColors.fromHex("#f54400"),
              fontSize: 16,
              fontFamily: Styles().fontFamilies.regular,
              label: Localization().getStringEx("panel.settings.privacy_center.button.delete_data.title", "Forget all of my information"),
              hint: Localization().getStringEx("panel.settings.privacy_center.label.description", "This will delete all of your personal information that was shared and stored within the app."),
              onTap: _onTapDeleteData,
            ),
            Container(height: 16,),
            ExcludeSemantics(
            child: Text(Localization().getStringEx("panel.settings.privacy_center.label.description", "This will delete all of your personal information that was shared and stored within the app."),
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 12, color: Styles().colors.textSurface),)),
          ],);
  }

  void _loadVersionInfo() async {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        _versionName = packageInfo?.version;
      });
    });
  }


  void _onTapVerifyIdentity(){
    Analytics.instance.logSelect(target: "Verify Identity");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsVerifyIdentityPanel()));
  }

  void _onTapPersonalInformation(){
    Analytics.instance.logSelect(target: "Personal Information");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPersonalInformationPanel()));
  }

  void _onTapNotifications(){
    Analytics.instance.logSelect(target: "Notifications");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsNotificationsPanel()));
  }

  void _onTapPrivacyPolicy(){
    Analytics.instance.logSelect(target: "Privacy Policy");
    //TBD
  }

  void _onTapManagePrivacy(){
    Analytics.instance.logSelect(target: "Manage Privacy");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsNewPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,)));
  }

  void _onTapDeleteData(){
    SettingsDialog.show(context,
        title: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.title", "Forget all of your information?"),
        message: [
          TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description1", "This will ")),
          TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description2", "Permanently "),style: TextStyle(fontFamily: Styles().fontFamilies.bold)),
          TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description3", "delete all of your information. You will not be able to retrieve your data after you have deleted it. Are you sure you want to continue?")),
        ],
        continueTitle: Localization().getStringEx("panel.settings.privacy_center.button.forget_info.title","Forget My Information"),
        onContinue: (List<String> selectedValues, OnContinueProgressController progressController ){
            progressController(loading: true);
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
    await Auth().deleteUserPiiData();
    await User().deleteUser();
    Auth().logout();
  }

  bool get _showFinishSetupWidget{
    return !(Auth().isLoggedIn);
  }

  @override
  void onNotification(String name, param) {
    if (name == Auth.notifyLoginChanged) {
      setState(() {});
    }
  }
}