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
import 'package:illinois/service/OnCampus.dart';
import 'package:illinois/ui/settings/SettingsProfileContentPanel.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/flex_ui.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/dining/FoodFiltersPanel.dart';
import 'package:illinois/ui/settings/SettingsManageInterestsPanel.dart';
import 'package:illinois/ui/settings/SettingsVerifyIdentityPanel.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;

class SettingsPersonalInformationPanel extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _SettingsPersonalInformationPanelState();

}

class _SettingsPersonalInformationPanelState extends State<SettingsPersonalInformationPanel> implements NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      OnCampus.notifyChanged
    ]);
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
    if ((name == OnCampus.notifyChanged) ||
        ((name == AppLivecycle.notifyStateChanged) && (param == AppLifecycleState.resumed))) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx("panel.settings.personal_information.label.title", "Personal Information"),),
      body: Column( children:[
        Expanded(child:
          SingleChildScrollView(child: _buildContent()),
        ),
        _buildFooter(),
      ]),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    
    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['personal_information'] ?? [];
    for (String code in codes) {
      if (code == 'buttons') {
        contentList.addAll(_buildButtons());
      }
      else if (code == 'calendar') {
        contentList.addAll(_buildCalendar());
      }
      else if (code == 'on_campus') {
        contentList.addAll(_buildOnCampus());
      }
    }

    if (contentList.isNotEmpty) {
      contentList.insert(0, Container(height: 8));
      contentList.add(Container(height: 16),);
    }

    return Container( padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList,),
    );
  }

  List<Widget> _buildButtons() {

    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['personal_information.buttons'] ?? [];
    for (String code in codes) {
      Widget? buttonWidget;
      if (code == 'personal_info') {
        buttonWidget = InfoButton(
          title: Localization().getStringEx("panel.settings.personal_information.button.personal_information.title", "Personal Information"),
          description: Localization().getStringEx("panel.settings.personal_information.button.personal_information.description", "Your name and contact info you’ve shared"),
          iconRes: "images/i.png",
          onTap: _onTapPersonalInfo,
        );
      }
      else if (code == 'roles') {
        buttonWidget = InfoButton(
          title: Localization().getStringEx("panel.settings.personal_information.button.who_you_are.title", "Who You Are"),
          description: Localization().getStringEx("panel.settings.personal_information.button.who_you_are.description", "Your status as a student, faculty, resident, etc."),
          iconRes: "images/identiy-blue.png",
          onTap: _onTapWhoYouAre,
        );
      }
      else if (code == 'interests') {
        buttonWidget = InfoButton(
          title: Localization().getStringEx("panel.settings.personal_information.button.interest.title", "Your Interests"),
          description: Localization().getStringEx("panel.settings.personal_information.button.interest.description", "Categories, teams, and tags you follow"),
          iconRes: "images/h.png",
          onTap: _onTapInterests,
        );
      }
      else if (code == 'food_filters') {
        buttonWidget = InfoButton(
          title: Localization().getStringEx("panel.settings.personal_information.button.food_filters.title", "Food Filters"),
          description: Localization().getStringEx("panel.settings.personal_information.button.food_filters.description", "Add or edit your food preferences"),
          iconRes: "images/u-blue.png",
          onTap: _onTapFoodFilters,
        );
      }

      if (buttonWidget != null) {
        contentList.add(Container(height: contentList.isEmpty ? 16 : 8,));
        contentList.add(buttonWidget);
      }
    }

    return contentList;
  }

  List<Widget> _buildCalendar() {
    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['personal_information.calendar'] ?? [];
    for (String code in codes) {
      if (code == 'add') {
        contentList.add(Container(height: 4,));
        contentList.add(ToggleRibbonButton(
          label: 'Add saved events to calendar',
          toggled: Storage().calendarEnabledToSave ?? false,
          border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(4)),
          onTap: () {
            setState(() { Storage().calendarEnabledToSave = !Storage().calendarEnabledToSave!;});
          }));
      }
      else if (code == 'prompt') {
        contentList.add(Container(height: 4,));
        contentList.add(ToggleRibbonButton(
          label: 'Prompt when saving events to calendar',
          textStyle: TextStyle(fontSize: 16,fontFamily: Styles().fontFamilies!.bold, color: Storage().calendarEnabledToSave! ? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent,) ,
          border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(4)),
          toggled: Storage().calendarCanPrompt ?? false,
          onTap: () {
            if (Storage().calendarEnabledToSave == false) {
              setState(() { Storage().calendarCanPrompt = (Storage().calendarCanPrompt != true);});
            }
          }));
      }
    }
    
    if (contentList.isNotEmpty) {
      contentList.insertAll(0, <Widget>[
        Container(height: 16,),
        Row(children: [ Expanded(child: Text('Calendar', style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies?.bold, color: Styles().colors!.fillColorPrimary,)), )],),
      ]);
    }
    return contentList;
  }

  List<Widget> _buildOnCampus() {

    bool onCampusRegionMonitorEnabled = OnCampus().enabled;
    bool onCampusRegionMonitorSelected = OnCampus().monitorEnabled;
    String onCampusRegionMonitorInfo = onCampusRegionMonitorEnabled
        ? Localization()
            .getStringEx('panel.settings.personal_information.on_campus.location_services.required.label', 'requires location services')
        : Localization()
            .getStringEx('panel.settings.personal_information.on_campus.location_services.not_available.label', 'not available');
    String autoOnCampusInfo = Localization().getStringEx(
            'panel.settings.personal_information.on_campus.radio_button.auto.title', 'Automatically detect when I am on Campus') +
        '\n($onCampusRegionMonitorInfo)';

    bool campusRegionManualInsideSelected = OnCampus().monitorManualInside;
    bool onCampusSelected = !onCampusRegionMonitorSelected && campusRegionManualInsideSelected;
    bool offCampusSelected = !onCampusRegionMonitorSelected && !campusRegionManualInsideSelected;

    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['personal_information.on_campus'] ?? [];
    for (String code in codes) {
      if (code == 'auto') {
        contentList.add(_buildOnCampusRadioItem(
            label: autoOnCampusInfo,
            enabled: onCampusRegionMonitorEnabled,
            selected: onCampusRegionMonitorSelected,
            onTap: onCampusRegionMonitorEnabled
                ? () {
                    setState(() {
                      OnCampus().monitorEnabled = true;
                    });
                  }
                : () {}));
      } else if (code == 'on_campus') {
        contentList.add(_buildOnCampusRadioItem(
            label: Localization()
                .getStringEx('panel.settings.personal_information.on_campus.radio_button.on.title', 'Always make me on campus'),
            enabled: true,
            selected: onCampusSelected,
            onTap: !onCampusSelected
                ? () {
                    setState(() {
                      OnCampus().monitorEnabled = false;
                      OnCampus().monitorManualInside = true;
                    });
                  }
                : () {}));
      } else if (code == 'off_campus') {
        contentList.add(_buildOnCampusRadioItem(
            label: Localization()
                .getStringEx('panel.settings.personal_information.on_campus.radio_button.off.title', 'Always make me off campus'),
            enabled: true,
            selected: offCampusSelected,
            onTap: !offCampusSelected
                ? () {
                    setState(() {
                      OnCampus().monitorEnabled = false;
                      OnCampus().monitorManualInside = false;
                    });
                  }
                : () {}));
      }
    }
    
    if (contentList.isNotEmpty) {
      contentList.insertAll(0, <Widget>[
        Container(height: 16),
        Row(children: [
          Expanded(
              child: Text(Localization().getStringEx('panel.settings.personal_information.on_campus.title', 'On Campus'),
                  style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies?.bold, color: Styles().colors!.fillColorPrimary)))
        ])
      ]);
    }
    return contentList;
  }

  Widget _buildOnCampusRadioItem({required String label, required bool enabled, required bool selected, VoidCallback? onTap}) {
    String imageAssetName = selected ? 'images/deselected-dark.png' : 'images/deselected.png';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(height: 4),
      GestureDetector(
          onTap: onTap,
          child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                  color: Styles().colors!.white,
                  border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(4))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 16,
                            fontFamily: Styles().fontFamilies!.bold,
                            color: (enabled ? Styles().colors?.fillColorPrimary : Styles().colors?.surfaceAccent)))),
                Padding(padding: EdgeInsets.only(left: 10), child: Image.asset(imageAssetName))
              ])))
    ]);
  }

  Widget _buildFooter() {
    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['personal_information.footer'] ?? [];
    for (String code in codes) {
      if (code == 'delete') {
        contentList.addAll(_buildDelete());
      }
    }
    if (contentList.isNotEmpty) {
      contentList.insertAll(0, <Widget>[
        Container(height: 1, color: Styles().colors!.surfaceAccent,),
      ]);
      contentList.add(Container(height: 16,));
      return Container(padding: EdgeInsets.symmetric(horizontal: 16), child:
        Column(children: contentList),
      );
    }
    else {
      return Container();
    }

  }

  List<Widget> _buildDelete() {
    return <Widget>[
      Container(height: 16,),
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
    ];
  }

  void _onTapPersonalInfo(){
    if(isLoggedIn){
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsProfileContentPanel()));
    } else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsVerifyIdentityPanel()));
    }
  }

  void _onTapWhoYouAre(){
    Analytics().logSelect(target: "Who are you");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsProfileContentPanel(content: SettingsProfileContent.who_are_you)));
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
