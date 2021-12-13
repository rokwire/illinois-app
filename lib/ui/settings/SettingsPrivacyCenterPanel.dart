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
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/settings/SettingsNewPrivacyPanel.dart';
import 'package:illinois/ui/settings/SettingsPersonalInformationPanel.dart';
import 'package:illinois/ui/settings/SettingsVerifyIdentityPanel.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
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
    NotificationService().subscribe(this, [ Auth2.notifyLoginChanged ]);
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
      body:Container(
        child: SafeArea(child:
          Column(children: <Widget>[
              Container(
                color: Styles().colors!.fillColorPrimaryVariant,
                  padding: EdgeInsets.only(),
                  child: Column(
                    children: <Widget>[
                      Container(height: 14,),
                      Container(
                        child:
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Semantics(
                                label: Localization().getStringEx('headerbar.back.title', 'Back'),
                                hint: Localization().getStringEx('headerbar.back.hint', ''),
                                button: true,
                                excludeSemantics: true,
                                child: Container(
                                  width: 42,
                                  alignment: Alignment.topCenter,
                                  child: IconButton(
                                    icon: Image.asset("images/chevron-left-white.png", excludeFromSemantics: true),
                                    onPressed: _onTapBack))),
                            Expanded(child:Container()),
                            Container(height: 90,
                              child: Image.asset("images/group-6.png",excludeFromSemantics: true,),
                            ),
                            Expanded(child:Container()),
                            Container(width: 42,)
                          ],
                        )

                      ),
                      Container(height: 10,),
                      Row(children: <Widget>[
                        Expanded(child:
                          Semantics(header: true, child:
                            Text(
                              Localization().getStringEx("panel.settings.privacy_center.label.title", "Privacy Center")!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: Styles().fontFamilies!.extraBold),
                            ),)
                        ),
                      ],),
                      Container(height: 24,)
                    ],
                  )
              ),
              Expanded(child:
                SingleChildScrollView(child:_buildContent()),
              )
          ],),)),
      backgroundColor: Styles().colors!.background,
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
            _buildFinishSetupWidget(),
            Container(height: 40,),
            Text(Localization().getStringEx("panel.settings.privacy_center.label.description", "Personalize your privacy and data preferences.")!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: Styles().fontFamilies!.bold,
                  fontSize: 20,
                  color: Styles().colors!.fillColorPrimary
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
          Container(height: 40,),
          Text(Localization().getStringEx("panel.settings.privacy_center.label.finish_setup", "Finish setup")!,
            style: TextStyle(
                fontFamily: Styles().fontFamilies!.extraBold,
                fontSize: 16,
                color: Styles().colors!.textSurface
            ),
          ),
          Container(height: 4,),
          Text(Localization().getStringEx("panel.settings.privacy_center.label.finish_setup_description", "Log in with your NetID or Telephone number to get the full Illinois experience.")!,
            style: TextStyle(
                fontFamily: Styles().fontFamilies!.regular,
                fontSize: 16,
                color: Styles().colors!.textSurface
            ),
          ),
          Container(height: 10,),
          Semantics(explicitChildNodes: true,
            child: RibbonButton(
            leftIcon: "images/user-check.png",
            label: Localization().getStringEx("panel.settings.privacy_center.button.verify_identity.title", "Verify your Identity"),
            borderRadius: BorderRadius.circular(4),
            shadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.15), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))],
            onTap: () => _onTapVerifyIdentity(),
          )),
        ],
      ),
    ));
  }

  Widget _buildSquareButtonsLayout(){
    TextStyle buttonTextStyle =  TextStyle(
        fontFamily: Styles().fontFamilies!.bold,
        fontSize: 16,
        color: Styles().colors!.fillColorPrimary);

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
                          boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))],
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
                                Localization().getStringEx("panel.settings.privacy_center.button.manage_privacy.title", "Manage and Understand Your Privacy")!,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(child: _buildSquareButton(
              label: Localization().getStringEx("panel.settings.privacy_center.button.personal_information.title", "Personal Information")!,
              hint: Localization().getStringEx("panel.settings.privacy_center.button.personal_information.hint", ""),
              iconPath: 'images/group-5.png',
              onTap: _onTapPersonalInformation,
              ),),
            Container(width: 12,),
            Expanded(child: _buildSquareButton(
              label: Localization().getStringEx("panel.settings.privacy_center.button.notifications.title", "Notification Preferences")!,
              hint: Localization().getStringEx("panel.settings.privacy_center.button.notifications.", ""),
              iconPath: 'images/notifications.png',
              onTap: _onTapNotifications,
            )),
          ],)
      ],)
      );
  }

  Widget _buildSquareButton({Function? onTap, required String label, String? hint, required String iconPath}){
    Color _boxShadowColor = Color.fromRGBO(19, 41, 75, 0.3);

    return GestureDetector(
      onTap: onTap as void Function()?,
      child: Semantics(label: label, hint:hint, button:true, excludeSemantics: true, child:Stack(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(color: (Styles().colors!.white),
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
                      Image.asset(iconPath, excludeFromSemantics: true),
                    ),
                    Container(height: 10,),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child:Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary)))
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
          Localization().getStringEx("panel.settings.privacy_center.button.privacy_policy.title", "Privacy Statement")!,
          style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16, decoration: TextDecoration.underline,decorationColor:  Styles().colors!.fillColorSecondary,),
      )));
  }

  //Version Info
  Widget _buildVersionInfo(){
    return
      Column(children: <Widget>[
        Container(height: 1, color: Styles().colors!.surfaceAccent,),
        Container(height: 12,),
        Container(
          alignment: Alignment.center,
          child:  Text(
            "Version: $_versionName",
            style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16),
          )),
      ],);
  }

  Widget _buildDeleteButton(){
      return
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
            Container(height: 16,),
            ExcludeSemantics(
            child: Text(Localization().getStringEx("panel.settings.privacy_center.label.delete.description", "This will delete all of your personal information that was shared and stored within the app.")!,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 12, color: Styles().colors!.textSurface),)),
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
    Analytics.instance.logSelect(target: "Privacy Statement");
    if (Config().privacyPolicyUrl != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: Config().privacyPolicyUrl, title: Localization().getStringEx("panel.settings.privacy_statement.label.title", "Privacy Statement"),)));
    }
  }

  void _onTapManagePrivacy(){
    Analytics.instance.logSelect(target: "Manage Privacy");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsNewPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,)));
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
          TextSpan(text: contributeInGroups?
          Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description.groups", " You have contributed to Groups. Do you wish to delete all of those entries (posts, replies, and events) or leave them for others to see.") :
          "")
        ],
        options:contributeInGroups ? [groupsSwitchTitle] : null,
        initialOptionsSelection:contributeInGroups ?  [groupsSwitchTitle] : [],
        continueTitle: Localization().getStringEx("panel.settings.privacy_center.button.forget_info.title","Forget My Information"),
        onContinue: (List<String> selectedValues, OnContinueProgressController progressController ){
            progressController(loading: true);
            if(selectedValues?.contains(groupsSwitchTitle) ?? false){
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

  bool get _showFinishSetupWidget{
    return !(Auth2().isLoggedIn);
  }

  void _onTapBack() {
    Analytics.instance.logSelect(target: "Back");
    Navigator.pop(context);
  }

  @override
  void onNotification(String name, param) {
    if (name == Auth2.notifyLoginChanged) {
      setState(() {});
    }
  }
}