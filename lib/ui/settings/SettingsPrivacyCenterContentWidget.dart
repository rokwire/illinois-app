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
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/ui/settings/SettingsPersonalInformationPanel.dart';
import 'package:illinois/ui/settings/SettingsVerifyIdentityPanel.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:package_info/package_info.dart';

import 'SettingsNotificationsPanel.dart';

class SettingsPrivacyCenterContentWidget extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _SettingsPrivacyCenterContentWidgetState();

}

class _SettingsPrivacyCenterContentWidgetState extends State<SettingsPrivacyCenterContentWidget> implements NotificationsListener{
  String _versionName = "";

  @override
  void initState() {
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      Auth2.notifyLoginChanged
    ]);
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
    return _buildContent();
  }

  Widget _buildContent(){
    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['privacy_center'] ?? [];
    for (String code in codes) {
      if (code == 'connect') {
        contentList.add(_buildConnectWidget());
      }
      else if (code == 'heading') {
        contentList.add(_buildHeadingWidget());
      }
      else if (code == 'manage') {
        contentList.add(_buildManagePrivacyWidget());
      }
      else if (code == 'buttons') {
        contentList.add(_buildSquareButtonsLayout());
      }
      else if (code == 'policy') {
        contentList.add(_buildPrivacyPolicyButton());
      }
      else if (code == 'delete') {
        contentList.add(_buildDeleteButton());
      }
      else if (code == 'version') {
        contentList.add(_buildVersionInfo());
      }
    }

    // bottom spacing
    if (contentList.isNotEmpty) {
      contentList.add(Container(height: 20,));
    }
  
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: contentList,
    ));
  }



  Widget _buildConnectWidget(){
    return Visibility(
      visible: _showFinishSetupWidget,
      child: Semantics( container: true,
        child:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(height: 40,),
          Text(Localization().getStringEx("panel.settings.privacy_center.label.finish_setup", "Finish setup"),
            style: TextStyle(
                fontFamily: Styles().fontFamilies!.extraBold,
                fontSize: 16,
                color: Styles().colors!.textSurface
            ),
          ),
          Container(height: 4,),
          Text(Localization().getStringEx("panel.settings.privacy_center.label.finish_setup_description", "Sign in with your NetID or Telephone number to get the full Illinois experience."),
            style: TextStyle(
                fontFamily: Styles().fontFamilies!.regular,
                fontSize: 16,
                color: Styles().colors!.textSurface
            ),
          ),
          Container(height: 10,),
          Semantics(explicitChildNodes: true,
            child: RibbonButton(
            label: Localization().getStringEx("panel.settings.privacy_center.button.verify_identity.title", "Verify your Identity"),
            leftIconAsset: "images/user-check.png",
            borderRadius: BorderRadius.circular(4),
            borderShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.15), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))],
            onTap: () => _onTapVerifyIdentity(),
          )),
        ],
      ),
    ));
  }

  Widget _buildHeadingWidget(){
    return Padding(
      padding: EdgeInsets.only(top: 40, bottom: 20),
      child: Text(Localization().getStringEx("panel.settings.privacy_center.label.description", "Personalize your privacy and data preferences."),
        textAlign: TextAlign.center,
        style: TextStyle(
            fontFamily: Styles().fontFamilies!.bold,
            fontSize: 20,
            color: Styles().colors!.fillColorPrimary
        ),
      ),
    );
  }

  Widget _buildManagePrivacyWidget(){
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(children: <Widget>[
        Expanded(
          child: GestureDetector(
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
                              Localization().getStringEx("panel.settings.privacy_center.button.manage_privacy.title", "Manage and Understand Your Privacy"),
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontFamily: Styles().fontFamilies!.bold,
                                fontSize: 16,
                                color: Styles().colors!.fillColorPrimary),
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
    );
  }

  Widget _buildSquareButtonsLayout(){
    //return Container(height: 80, color: Colors.amber,);
    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['privacy_center.buttons'] ?? [];
    for (String code in codes) {
      if (code == 'personal_information') {
        contentList.add(_buildSquareButton(
          label: Localization().getStringEx("panel.settings.privacy_center.button.personal_information.title", "Personal Information"),
          hint: Localization().getStringEx("panel.settings.privacy_center.button.personal_information.hint", ""),
          iconPath: 'images/group-5.png',
          onTap: _onTapPersonalInformation,
          ),);
      }
      else if (code == 'notifications') {
        contentList.add(_buildSquareButton(
          label: Localization().getStringEx("panel.settings.privacy_center.button.notifications.title", "Notification Preferences"),
          hint: Localization().getStringEx("panel.settings.privacy_center.button.notifications.", ""),
          iconPath: 'images/notifications.png',
          onTap: _onTapNotifications,
        ),);
      }
    }

    final int buttonsPerRow = 2;
    final int entriesPerRow = buttonsPerRow + (buttonsPerRow - 1);
    List<Widget> row = [];
    List<Widget> cols = [];
    for (Widget entry in contentList) {
      if (entriesPerRow <= row.length) {
        cols.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children:row));
        cols.add(Container(height: 12,));
        row = [];
      }
      if (row.isNotEmpty) {
        row.add(Container(width: 12,));
      }
      row.add(Expanded(child: entry));
    }
    
    // add last row
    if (row.isNotEmpty) {
      while (row.length < entriesPerRow) {
        if (row.isNotEmpty) {
          row.add(Container(width: 12,));
        }
        row.add(Expanded(child: Container()));
      }
      cols.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: row));
      cols.add(Container(height: 12,));
      row = [];
    }

    return Column(
      children: cols,
    );



/*
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
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
        ],),
    );*/
  }

  Widget _buildSquareButton({void Function()? onTap, required String label, String? hint, required String iconPath}){
    Color _boxShadowColor = Color.fromRGBO(19, 41, 75, 0.3);

    return GestureDetector(
      onTap: onTap,
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
    return Padding(
      padding: EdgeInsets.only(top: 40),
      child: Semantics( button: true,
        child: GestureDetector(
          onTap: _onTapPrivacyPolicy,
          child: Text(
            Localization().getStringEx("panel.settings.privacy_center.button.privacy_policy.title", "Privacy Statement"),
            style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16, decoration: TextDecoration.underline,decorationColor:  Styles().colors!.fillColorSecondary,),
        ))));
  }

  //Version Info
  Widget _buildVersionInfo(){
    return Padding(
      padding: EdgeInsets.only(top: 40),
      child: Column(children: <Widget>[
        Container(height: 1, color: Styles().colors!.surfaceAccent,),
        Container(height: 12,),
        Container(
          alignment: Alignment.center,
          child:  Text(
            "Version: $_versionName",
            style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16),
          )),
      ],),);
  }

  Widget _buildDeleteButton(){
    return Padding(
      padding: EdgeInsets.only(top: 40),
      child: Column(children: <Widget>[
        RoundedButton(
          backgroundColor: Styles().colors!.white,
          borderColor: Styles().colors!.white,
          textColor: UiColors.fromHex("#f54400"),
          fontSize: 16,
          fontFamily: Styles().fontFamilies!.regular,
          label: Localization().getStringEx("panel.settings.privacy_center.button.delete_data.title", "Delete My Account"),
          hint: Localization().getStringEx("panel.settings.privacy_center.label.delete.description", "This will delete all of your personal information that was shared and stored within the app."),
          borderShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))],
          onTap: _onTapDeleteData,
        ),
        Container(height: 16,),
        ExcludeSemantics(
        child: Text(Localization().getStringEx("panel.settings.privacy_center.label.delete.description", "This will delete all of your personal information that was shared and stored within the app."),
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 12, color: Styles().colors!.textSurface),)),
      ],),);
  }

  void _loadVersionInfo() async {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        _versionName = packageInfo.version;
      });
    });
  }


  void _onTapVerifyIdentity(){
    Analytics().logSelect(target: "Verify Identity");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsVerifyIdentityPanel()));
  }

  void _onTapPersonalInformation(){
    Analytics().logSelect(target: "Personal Information");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPersonalInformationPanel()));
  }

  void _onTapNotifications(){
    Analytics().logSelect(target: "Notifications");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsNotificationsPanel()));
  }

  void _onTapPrivacyPolicy(){
    Analytics().logSelect(target: "Privacy Statement");
    if (Config().privacyPolicyUrl != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: Config().privacyPolicyUrl, title: Localization().getStringEx("panel.settings.privacy_statement.label.title", "Privacy Statement"),)));
    }
  }

  void _onTapManagePrivacy(){
    Analytics().logSelect(target: "Manage Privacy");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,)));
  }

  void _onTapDeleteData() async{
    final String groupsSwitchTitle = "Please delete all my contributions.";
    int userPostCount = await Groups().getUserPostCount();
    bool contributeInGroups = userPostCount > 0;

    SettingsDialog.show(context,
        title: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.title", "Delete your account?"),
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
    Analytics().logAlert(text: "Remove My Information", selection: "Yes");
    await Auth2().deleteUser();
  }

  bool get _showFinishSetupWidget{
    return !Auth2().isLoggedIn && Auth2().privacyMatch(4);
  }

  @override
  void onNotification(String name, param) {
    if (name == Auth2.notifyLoginChanged) {
      setState(() {});
    }
    else if (name == FlexUI.notifyChanged) {
      setState(() {});
    }
  }
}