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
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/dining/FoodFiltersPanel.dart';
import 'package:illinois/ui/settings/SettingsManageInterestsPanel.dart';
import 'package:illinois/ui/settings/SettingsPersonalInfoPanel.dart';
import 'package:illinois/ui/settings/SettingsRolesPanel.dart';
import 'package:illinois/ui/settings/SettingsVerifyIdentityPanel.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';

class SettingsPersonalInformationPanel extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _SettingsPersonalInformationPanelState();

}

class _SettingsPersonalInformationPanelState extends State<SettingsPersonalInformationPanel> implements NotificationsListener {

  LocationServicesStatus? _locationServicesStatus;

  @override
  void initState() {
    NotificationService().subscribe(this, [AppLivecycle.notifyStateChanged]);
    _initLocationServicesStatus();
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
    if ((name == AppLivecycle.notifyStateChanged) && (param == AppLifecycleState.resumed)) {
      _initLocationServicesStatus();
    }
  }

  void _initLocationServicesStatus() {
    if (Auth2().privacyMatch(2)) {
      LocationServices().status.then((LocationServicesStatus? locationServicesStatus) {
        setState(() {
          _locationServicesStatus = locationServicesStatus;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.settings.personal_information.label.title", "Personal Information"),
      ),
      body: Column(
        children:[
          Expanded(child:
            SingleChildScrollView(child: _buildContent()),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: <Widget>[
                Container(height: 1, color: Styles().colors!.surfaceAccent,),
                Container(height: 24,),
                RoundedButton(
                  backgroundColor: Styles().colors!.white,
                  borderColor: Styles().colors!.white,
                  textColor: UiColors.fromHex("#f54400"),
                  fontSize: 16,
                  fontFamily: Styles().fontFamilies!.regular,
                  label: Localization().getStringEx("panel.settings.personal_information.button.delete_data.title", "Delete My Personal Information"),
                  borderShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))],
                  onTap: _onTapDeleteData,
                ),
                Container(height: 16,),
                Text(Localization().getStringEx("panel.settings.personal_information.label.description", "Delete your location history, your tags and categories, and saved events and dining locations."),
                  style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 12, color: Styles().colors!.textSurface),),
                Container(height: 30,),
            ],),
          ),
        ]),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    bool campusRegionMonitorSelected, campusRegionMonitorEnabled;
    String? campusRegionMonitorInfo;
    if (!Auth2().privacyMatch(2)) {
      campusRegionMonitorSelected = campusRegionMonitorEnabled = false;
      campusRegionMonitorInfo = '(privacy restriction).';
    }
    else if (_locationServicesStatus == null) {
      campusRegionMonitorSelected = campusRegionMonitorEnabled = false;
      campusRegionMonitorInfo = '(checking location services status)';
    }
    else if (_locationServicesStatus == LocationServicesStatus.serviceDisabled) {
      campusRegionMonitorSelected = campusRegionMonitorEnabled = false;
      campusRegionMonitorInfo = '(location services not available)';
    }
    else {
      campusRegionMonitorEnabled = true;
      campusRegionMonitorSelected = Storage().campusRegionMonitorEnabled ?? (FlexUI().hasFeature('gies') ? false : true); // by default, false for GIES, true for the rest
      campusRegionMonitorInfo = '(requires location services)';
    }

    bool campusRegionManualInsideEnabled, campusRegionManualInsideSelected;
    if (campusRegionMonitorSelected == true) {
      campusRegionManualInsideSelected = campusRegionManualInsideEnabled = false;
    }
    else {
      campusRegionManualInsideEnabled = true;
      campusRegionManualInsideSelected = (Storage().campusRegionManualInside != false); // by default, true
    }
    
    return
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(height: 24),
          InfoButton(
            title: Localization().getStringEx("panel.settings.personal_information.button.personal_information.title", "Personal Information"),
            description: Localization().getStringEx("panel.settings.personal_information.button.personal_information.description", "Your name and contact info you’ve shared"),
            iconRes: "images/i.png",
            onTap: _onTapPersonalInfo,
          ),
          Container(height: 8,),
          InfoButton(
            title: Localization().getStringEx("panel.settings.personal_information.button.who_you_are.title", "Who You Are"),
            description: Localization().getStringEx("panel.settings.personal_information.button.who_you_are.description", "Your status as a student, faculty, resident, etc."),
            iconRes: "images/identiy-blue.png",
            onTap: _onTapWhoYouAre,
          ),
          Container(height: 8,),
          InfoButton(
            title: Localization().getStringEx("panel.settings.personal_information.button.interest.title", "Your Interests"),
            description: Localization().getStringEx("panel.settings.personal_information.button.interest.description", "Categories, teams, and tags you follow"),
            iconRes: "images/h.png",
            onTap: _onTapInterests,
          ),
          Container(height: 8,),
          InfoButton(
            title: Localization().getStringEx("panel.settings.personal_information.button.food_filters.title", "Food Filters"),
            description: Localization().getStringEx("panel.settings.personal_information.button.food_filters.description", "Add or edit your food preferences"),
            iconRes: "images/u-blue.png",
            onTap: _onTapFoodFilters,
          ),
          Container(height: 16,),
          Row(children: [Expanded(child: Text('Calendar', style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies?.bold, color: Styles().colors!.fillColorPrimary,)), )],),
          Container(height: 4,),
          ToggleRibbonButton(
              label: 'Add saved events to calendar',
              toggled: Storage().calendarEnabledToSave ?? false,
              border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
              borderRadius: BorderRadius.all(Radius.circular(4)),
              onTap: (){ setState(() {Storage().calendarEnabledToSave = !Storage().calendarEnabledToSave!;});}),
          Container(height: 4,),
          ToggleRibbonButton(
              label: 'Prompt when saving events to calendar',
              textStyle: TextStyle(fontSize: 16,fontFamily: Styles().fontFamilies!.bold, color: Storage().calendarEnabledToSave! ? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent,) ,
              border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
              borderRadius: BorderRadius.all(Radius.circular(4)),
              toggled: Storage().calendarCanPrompt ?? false,
              onTap: (){
                if(Storage().calendarEnabledToSave == false) {
                  setState(() { Storage().calendarCanPrompt = (Storage().calendarCanPrompt != true);});
                }
              }),
          Container(height: 16,),
          Row(children: [Expanded(child: Text('On Campus', style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies?.bold, color: Styles().colors!.fillColorPrimary,)), )],),
          Container(height: 4,),
          ToggleRibbonButton(
              label: StringUtils.isNotEmpty(campusRegionMonitorInfo) ? 'Automatically detect I am on campus\n$campusRegionMonitorInfo' : 'Automatically detect I am on campus',
              textColor: campusRegionMonitorEnabled ? Styles().colors?.fillColorPrimary : Styles().colors?.surfaceAccent,
              toggled: campusRegionMonitorSelected,
              border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
              borderRadius: BorderRadius.all(Radius.circular(4)),
              onTap: campusRegionMonitorEnabled ? (){ setState(() { Storage().campusRegionMonitorEnabled = !campusRegionMonitorSelected; });} : (){}),
          Container(height: 4,),
          ToggleRibbonButton(
              label: 'The App behaves as if I am on campus',
              textColor: campusRegionManualInsideEnabled ? Styles().colors?.fillColorPrimary : Styles().colors?.surfaceAccent,
              toggled: campusRegionManualInsideSelected,
              border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
              borderRadius: BorderRadius.all(Radius.circular(4)),
              onTap: campusRegionManualInsideEnabled ? (){ setState(() { Storage().campusRegionManualInside = !campusRegionManualInsideSelected; });} : (){}),

          //Container(height: 8,),

          Container(height: 29,),
        ],));
  }

  void _onTapPersonalInfo(){
    if(isLoggedIn){
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPersonalInfoPanel()));
    } else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsVerifyIdentityPanel()));
    }
  }

  void _onTapWhoYouAre(){
    Analytics().logSelect(target: "Who are you");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsRolesPanel()));
  }

  void _onTapInterests(){
    Analytics().logSelect(target: "Manage Your Interests");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsManageInterestsPanel()));
  }

  void _onTapFoodFilters(){
    Analytics().logSelect(target: "Food Filters");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => FoodFiltersPanel()));
  }

  void _onTapDeleteData(){
    SettingsDialog.show(context,
        title: Localization().getStringEx("panel.settings.personal_information.label.delete_message.title", "Delete your personal information?"),
        message: [
          TextSpan(text: Localization().getStringEx("panel.settings.personal_information.label.delete_message.description1", "Select all that you would like to ")),
          TextSpan(text: Localization().getStringEx("panel.settings.personal_information.label.delete_message.description2", "Permanently "),style: TextStyle(fontFamily: Styles().fontFamilies!.bold)),
          TextSpan(text: Localization().getStringEx("panel.settings.personal_information.label.delete_message.description3", "delete:")),
        ],
        continueTitle: Localization().getStringEx("panel.settings.personal_information.button.forget_info.title","Delete My Information"),
        options: [OptionYourInterests,OptionFoodFilters],
        onContinue: _onDelete
    );
  }

  void _onDelete(List<String> selectedOptions, OnContinueProgressController progressController){
    progressController(loading: true);
    if(selectedOptions.contains(OptionFoodFilters)){
      Auth2().prefs?.clearFoodFilters();
    }
    if(selectedOptions.contains(OptionYourInterests)){
      Auth2().prefs?.clearInterestsAndTags();
    }
    progressController(loading: false);
    Navigator.pop(context);
  }

  bool get isLoggedIn{
    return Auth2().isLoggedIn;
  }

  //Option keys
  //static const String OptionPersonalInformation = "Personal information";
  //static const String OptionWhoYouAre = "Who you are";
  static const String OptionYourInterests = "Your Interests";
  static const String OptionFoodFilters = "Food Filters";
}
