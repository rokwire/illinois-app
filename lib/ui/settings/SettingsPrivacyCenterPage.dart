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
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/ui/settings/SettingsVerifyIdentityPanel.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/web_semantics.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SettingsPrivacyCenterPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _SettingsPrivacyCenterPageState();

}

class _SettingsPrivacyCenterPageState extends State<SettingsPrivacyCenterPage> with NotificationsListener {
  PrivacyData? _privacyData;
  bool _loadingPrivacyData = false;

  final FocusNode _entryFocusNode = FocusNode();

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
    _entryFocusNode.dispose();
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
              style: Styles().textStyles.getTextStyle("panel.settings.privacy_center.title.medium.fat")
            ),
            SizedBox(height: 8,),
            Text(Localization().getStringEx("panel.settings.privacy_center.label.finish_setup_description", "Sign in with your NetID to get the full {{app_title}} experience.").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')),
              style: Styles().textStyles.getTextStyle("panel.settings.privacy_center.title.regular")
            ),
            SizedBox(height: 16,),
            WebFocusableSemanticsWidget(focusNode: (_showFinishSetupWidget ? _entryFocusNode : null), onSelect: _onTapVerifyIdentity, child: Semantics(explicitChildNodes: true,
              child: RibbonButton(
              title: Localization().getStringEx("panel.settings.privacy_center.button.verify_identity.title", "Verify your Identity"),
              leftIconKey: "user-check",
              borderRadius: BorderRadius.circular(4),
              borderShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.15), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))],
              onTap: () => _onTapVerifyIdentity(),
            ))),
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
        style: Styles().textStyles.getTextStyle("widget.title.large.fat")
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
    String? levelTitle = _privacyLevelTitle(level);
    return Container(
        padding: EdgeInsets.only(top: 24),
        color: Styles().colors.background,
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
              Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: <Widget>[
                Styles().images.getImage("lock-illustration", excludeFromSemantics: true, width: 96, fit: BoxFit.fitWidth) ?? Container(),
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: Container(
                      height: 48,
                      width: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          border: Border.all(color: Styles().colors.fillColorPrimary, width: 2),
                          color: Styles().colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(100))),
                      child: Container(
                          height: 40,
                          width: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              border: Border.all(color: Styles().colors.fillColorSecondary, width: 2),
                              color: Styles().colors.white,
                              borderRadius: BorderRadius.all(Radius.circular(100))),
                          child: Semantics(
                              label: Localization().getStringEx("panel.settings.privacy.label.privacy_level.title", "Privacy Level: "),
                              child: Text(level.toString(),
                                  style: Styles().textStyles.getTextStyle("widget.title.large.extra_fat")))))),
              ]),
              Container(height: 16),
              if (levelTitle != null) Text(levelTitle,
                  textAlign: TextAlign.center,
                  style: Styles().textStyles.getTextStyle("widget.title.extra_huge.fat")),
              Container(height: 12),
              Text(Localization().getString(description.key, defaults: description.text) ?? '',
                  style: Styles().textStyles.getTextStyle("widget.description.regular"),
                  textAlign: TextAlign.center),
            ]));
  }

  String? _privacyLevelTitle(int? level) {
    switch (level) {
      case 1: return Localization().getStringEx("panel.settings.privacy_center.privacy_level.title.1", "Browse privately");
      case 2: return Localization().getStringEx("panel.settings.privacy_center.privacy_level.title.2", "Explore privately");
      case 3: return Localization().getStringEx("panel.settings.privacy_center.privacy_level.title.3", "Personalized for you");
      case 4: return Localization().getStringEx("panel.settings.privacy_center.privacy_level.title.4", "Personalized for you");
      case 5: return Localization().getStringEx("panel.settings.privacy_center.privacy_level.title.5", "Full Access");
      default: return null;
    }
  }

  Widget _buildManagePrivacyWidget(){
    return Padding(
      padding: EdgeInsets.only(top: 40),
      child: RoundedButton(
        backgroundColor: Styles().colors.white,
        borderColor: Styles().colors.white,
        label: Localization().getStringEx("panel.settings.privacy_center.button.manage_privacy.title", "Manage Your Privacy"),
        hint: Localization().getStringEx("panel.settings.privacy_center.button.manage_privacy.hint", ""),
        textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
        borderShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))],
        onTap: _onTapManagePrivacy,
      ),
    );
  }

  Widget _buildPrivacyPolicyButton() {
    return WebFocusableSemanticsWidget(onSelect: _onTapPrivacyPolicy, child: Padding(
      padding: EdgeInsets.only(top: 20),
      child: Semantics( button: true,
        child: GestureDetector(
          onTap: _onTapPrivacyPolicy,
          child: Text(
            Localization().getStringEx("panel.settings.privacy_center.button.privacy_policy.title", "Privacy Statement"),
            style: Styles().textStyles.getTextStyle("panel.settings.privacy_center.button.underline")
        )))));
  }

  Widget _buildDeleteButton(){
    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: Column(children: <Widget>[
        RoundedButton(
          backgroundColor: Styles().colors.white,
          borderColor: Styles().colors.white,
          label: Localization().getStringEx("panel.settings.privacy_center.button.delete_data.title", "Delete My Account"),
          hint: Localization().getStringEx("panel.settings.privacy_center.label.delete.description", "This will delete all of your personal information that was shared and stored within the app."),
          textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.thin.secondary"),
          borderShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))],
          onTap: _onTapDeleteData,
        ),
        Container(height: 16,),
        ExcludeSemantics(
        child: Text(Localization().getStringEx("panel.settings.privacy_center.label.delete.description", "This will delete all of your personal information that was shared and stored within the app."),
          textAlign: TextAlign.center,
          style: Styles().textStyles.getTextStyle("panel.settings.privacy_center.message.tiny"))),
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
    int userPostCount = await Social().getUserPostsCount();
    bool contributeInGroups = userPostCount > 0;

    SettingsDialog.show(context,
        title: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.title", "Delete your account?"),
        message: [
          TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description1", "This will ")),
          TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description2", "Permanently "),style: Styles().textStyles.getTextStyle("widget.message.regular.fat")),
          TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description3", "delete all of your information. You will not be able to retrieve your data after you have deleted it. Are you sure you want to continue?")),
          TextSpan(text: contributeInGroups?
          Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description.groups", " You have contributed to Groups. Do you wish to delete all of those entries (posts, replies, reactions and events) or leave them for others to see.") :
          "")
        ],
        options:contributeInGroups ? [groupsSwitchTitle] : null,
        initialOptionsSelection:contributeInGroups ?  [groupsSwitchTitle] : [],
        continueTitle: Localization().getStringEx("panel.settings.privacy_center.button.forget_info.title","Forget My Information"),
        onContinue: (List<String> selectedValues, OnContinueProgressController progressController ) => _deleteAccount(selectedValues.contains(groupsSwitchTitle), progressController),
        longButtonTitle: true
      );
  }

  void _deleteAccount(bool deleteContributions, OnContinueProgressController progressController) async {
    Analytics().logAlert(text: "Remove My Information", selection: "Yes");
    progressController(loading: true);
    NetworkAuthProvider? authProvider = Auth2().networkAuthProvider; // Store token before
    bool? result = await Auth2().deleteUser();
    if (result == true) {
      List<Future<bool?>> futures = [
        Inbox().deleteUser(auth: authProvider)
      ];
      if (deleteContributions) {
        futures.addAll(<Future<bool?>>[
          Groups().deleteUserData(auth: authProvider),
          Social().deleteUser(auth: authProvider)
        ]);
      }
      await Future.wait(futures);
      progressController(loading: false);
      Navigator.pop(context);
    }
    else {
      progressController(loading: false);
      AppAlert.showTextMessage(context, Localization().getStringEx('panel.profile.info.delete.failed.text', 'Failed to delete app account.'));
    }
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
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
      ),
    ),
  );

}