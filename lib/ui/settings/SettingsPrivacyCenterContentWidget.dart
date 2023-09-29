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
import 'package:illinois/model/PrivacyData.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/ui/settings/SettingsVerifyIdentityPanel.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SettingsPrivacyCenterContentWidget extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _SettingsPrivacyCenterContentWidgetState();

}

class _SettingsPrivacyCenterContentWidgetState extends State<SettingsPrivacyCenterContentWidget> implements NotificationsListener {
  PrivacyData? _privacyData;
  bool _loadingPrivacyData = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      Auth2.notifyLoginChanged,
      Localization.notifyLocaleChanged
    ]);
    
    _loadingPrivacyData = true;
    Content().loadContentItem('privacy').then((dynamic value) {
      setStateIfMounted(() {
        _privacyData = PrivacyData.fromJson(JsonUtils.mapValue(value));
        _loadingPrivacyData = false;
      });
    });
    
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _loadingPrivacyData ? _buildLoading() : _buildContent();
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
      else if (code == 'description') {
        contentList.add(_buildDescriptionWidget());
      }
      else if (code == 'manage') {
        contentList.add(_buildManagePrivacyWidget());
      }
      else if (code == 'policy') {
        contentList.add(_buildPrivacyPolicyButton());
      }
      else if (code == 'delete') {
        contentList.add(_buildDeleteButton());
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
      child: Semantics(container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(Localization().getStringEx("panel.settings.privacy_center.label.finish_setup", "Finish setup"),
              style: Styles().textStyles?.getTextStyle("panel.settings.privacy_center.title.medium.fat")
            ),
            SizedBox(height: 8,),
            Text(Localization().getStringEx("panel.settings.privacy_center.label.finish_setup_description", "Sign in with your NetID or Telephone number to get the full  {{app_title}} experience.").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')),
              style: Styles().textStyles?.getTextStyle("panel.settings.privacy_center.title.regular")
            ),
            SizedBox(height: 16,),
            Semantics(explicitChildNodes: true,
              child: RibbonButton(
              label: Localization().getStringEx("panel.settings.privacy_center.button.verify_identity.title", "Verify your Identity"),
              leftIconKey: "user-check",
              borderRadius: BorderRadius.circular(4),
              borderShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.15), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))],
              onTap: () => _onTapVerifyIdentity(),
            )),
            SizedBox(height: 24,),
          ],
      ),
    ));
  }

  Widget _buildHeadingWidget(){
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Text(Localization().getStringEx("panel.settings.privacy_center.label.description", "Personalize your privacy and data preferences."),
        textAlign: TextAlign.center,
        style: Styles().textStyles?.getTextStyle("widget.title.large.fat")
      ),
    );
  }

  Widget _buildDescriptionWidget() {
    int? level = Auth2().prefs?.privacyLevel;
    PrivacyDescription? description;
    if (CollectionUtils.isNotEmpty(_privacyData?.privacyDescription)) {
      for (PrivacyDescription desc in _privacyData!.privacyDescription!) {
        if (desc.level == level) {
          description = desc;
          break;
        }
      }
    }
    if (description == null) {
      return Container();
    }
    return Container(
        padding: EdgeInsets.only(bottom: 20),
        color: Styles().colors!.background,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Container(
                  height: 60,
                  width: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 2),
                      color: Styles().colors!.white,
                      borderRadius: BorderRadius.all(Radius.circular(100))),
                  child: Container(
                      height: 52,
                      width: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          border: Border.all(color: Styles().colors!.fillColorSecondary!, width: 2),
                          color: Styles().colors!.white,
                          borderRadius: BorderRadius.all(Radius.circular(100))),
                      child: Semantics(
                          label: Localization().getStringEx("panel.settings.privacy.label.privacy_level.title", "Privacy Level: "),
                          child: Text(level.toString(),
                              style: Styles().textStyles?.getTextStyle("widget.title.extra_large.extra_fat"))))),
              Container(width: 20),
              Expanded(
                  child: Text(Localization().getString(description.key, defaults: description.text) ?? '',
                      style: Styles().textStyles?.getTextStyle("panel.settings.privacy_center.title.regular"),
                      textAlign: TextAlign.left))
            ]));
  }

  Widget _buildManagePrivacyWidget(){
    return Row(children: <Widget>[
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
                          Styles().images?.getImage('privacy', excludeFromSemantics: true) ?? Container(),
                          Container(width: 18,),
                          Expanded(child:
                            Semantics(  excludeSemantics: true,
                            child: Text(
                              Localization().getStringEx("panel.settings.privacy_center.button.manage_privacy.title", "Manage and Understand Your Privacy"),
                              textAlign: TextAlign.left,
                              style: Styles().textStyles?.getTextStyle("widget.title.regular.fat")
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
      ]);
  }

  Widget _buildPrivacyPolicyButton() {
    return Padding(
      padding: EdgeInsets.only(top: 20),
      child: Semantics( button: true,
        child: GestureDetector(
          onTap: _onTapPrivacyPolicy,
          child: Text(
            Localization().getStringEx("panel.settings.privacy_center.button.privacy_policy.title", "Privacy Statement"),
            style: Styles().textStyles?.getTextStyle("panel.settings.privacy_center.button.underline")
        ))));
  }

  Widget _buildDeleteButton(){
    return Padding(
      padding: EdgeInsets.only(top: 40),
      child: Column(children: <Widget>[
        RoundedButton(
          backgroundColor: Styles().colors!.white,
          borderColor: Styles().colors!.white,
          label: Localization().getStringEx("panel.settings.privacy_center.button.delete_data.title", "Delete My Account"),
          hint: Localization().getStringEx("panel.settings.privacy_center.label.delete.description", "This will delete all of your personal information that was shared and stored within the app."),
          textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.thin.secondary"),
          borderShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))],
          onTap: _onTapDeleteData,
        ),
        Container(height: 16,),
        ExcludeSemantics(
        child: Text(Localization().getStringEx("panel.settings.privacy_center.label.delete.description", "This will delete all of your personal information that was shared and stored within the app."),
          textAlign: TextAlign.center,
          style: Styles().textStyles?.getTextStyle("panel.settings.privacy_center.message.tiny"))),
      ],),);
  }


  void _onTapVerifyIdentity(){
    Analytics().logSelect(target: "Verify Identity");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsVerifyIdentityPanel()));
  }

  void _onTapPrivacyPolicy(){
    Analytics().logSelect(target: "Privacy Statement");
    AppPrivacyPolicy.launch(context);
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
          TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description2", "Permanently "),style: Styles().textStyles?.getTextStyle("widget.message.regular.fat")),
          TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description3", "delete all of your information. You will not be able to retrieve your data after you have deleted it. Are you sure you want to continue?")),
          TextSpan(text: contributeInGroups?
          Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description.groups", " You have contributed to Groups. Do you wish to delete all of those entries (posts, replies, reactions and events) or leave them for others to see.") :
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
    return !Auth2().isLoggedIn && FlexUI().isAuthenticationAvailable;
  }

  @override
  void onNotification(String name, param) {
    if (name == Auth2.notifyLoginChanged) {
      _updateState();
    }
    else if (name == FlexUI.notifyChanged) {
      _updateState();
    }
    else if (name == Localization.notifyLocaleChanged) {
      _privacyData?.reload();
      _updateState();
    }
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildLoading() => Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 64), child:
    Center(child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 3,),
      ),
    ),
  );

}