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
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:illinois/ui/settings/SettingsNotificationsContentPanel.dart';
import 'package:illinois/ui/settings/SettingsProfileContentPanel.dart';
import 'package:illinois/ui/settings/SettingsVideoTutorialPanel.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/SavedPanel.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/athletics/AthleticsHomePanel.dart';
import 'package:illinois/ui/events/CreateEventPanel.dart';
import 'package:illinois/ui/groups/GroupsHomePanel.dart';
import 'package:illinois/ui/guide/CampusGuidePanel.dart';
import 'package:illinois/ui/laundry/LaundryHomePanel.dart';
import 'package:illinois/ui/parking/ParkingEventsPanel.dart';
import 'package:illinois/ui/polls/CreateStadiumPollPanel.dart';
import 'package:illinois/ui/polls/PollsHomePanel.dart';
import 'package:illinois/ui/settings/SettingsAddIlliniCashPanel.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/settings/SettingsIlliniCashPanel.dart';
import 'package:illinois/ui/settings/SettingsMealPlanPanel.dart';
import 'package:illinois/ui/wallet/IDCardPanel.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class BrowsePanel extends StatefulWidget {

  BrowsePanel();

  @override
  _BrowsePanelState createState() => _BrowsePanelState();
}

class _BrowsePanelState extends State<BrowsePanel> with AutomaticKeepAliveClientMixin<BrowsePanel> implements NotificationsListener {

  final EdgeInsets _ribbonButtonPadding = EdgeInsets.symmetric(horizontal: 16);
  
  bool _buildingAccessAuthLoading = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Localization.notifyStringsUpdated,
      FlexUI.notifyChanged,
      Config.notifyConfigChanged,
      Styles.notifyChanged,
      Storage.notifySettingChanged,
    ]);
    
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;


  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if ((name == Connectivity.notifyStatusChanged) ||
        (name == Localization.notifyStringsUpdated) ||
        (name == FlexUI.notifyChanged) ||
        (name == Config.notifyConfigChanged) ||
        (name == Styles.notifyChanged))
    {
      setState(() { });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.browse.label.title', 'Browse')),
      body: Column(children: <Widget>[
        Expanded(child:
          SingleChildScrollView(child:
            Column(children: _buildContentList(),)
          )
        ),
      ]),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: null,
    );
  }

  List<Widget> _buildContentList() {

    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['browse'] ?? [];
    for (String code in codes) {
      if (code == 'primary') {
        contentList.add(_buildBrowsePrimary());
      }
      else if (code == 'secondary') {
        contentList.addAll(_buildBrowseSecondary());
      }
    }
    return contentList;
  }

  Widget _buildBrowsePrimary() {

    List<Widget> row = [];
    int rowEntries = 0;

    List<Widget> list = [];
    int listEntrues = 0;

    list.add(Container(height: 18,));

    const int gridWidth = 2;
    List<dynamic> codes = FlexUI()['browse.primary'] ?? [];
    for (String code in codes) {
      Widget? entry = _buildBrowsePrimaryEntry(code);
      if (entry != null) {
        
        if (0 < rowEntries) {
          row.add(Container(width: 16,),);
        }
        
        row.add(Expanded(child: entry));
        rowEntries++;
        
        if (rowEntries == gridWidth) {
          if (0 < listEntrues) {
            list.add(Container(height: 18,));
          }
          
          list.add(Row(children: row));
          listEntrues++;
          
          row = [];
          rowEntries = 0;
        }
      }
    }
    
    if (0 < rowEntries) {
      while (rowEntries < gridWidth) {
        if (0 < row.length) {
          row.add(Container(width: 16,),);
        }
        row.add(Expanded(child: Container()));
        rowEntries++;
      }
      if (0 < listEntrues) {
        list.add(Container(height: 18,));
      }
      list.add(Row(children: row));
    }

    list.add(Container(height: 18,),);

    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Column(children: list),);
  }
  
  Widget? _buildBrowsePrimaryEntry(String code) {
    if (code == 'athletics') {
      return _GridSquareButton(
        title: Localization().getStringEx('panel.browse.button.athletics.title', 'Athletics'),
        hint: Localization().getStringEx('panel.browse.button.athletics.hint', ''),
        icon: 'images/icon-browse-athletics.png',
        textColor: Styles().colors!.fillColorPrimary,
        onTap: () => _navigateToAthletics(),
      );
    }
    else if (code == 'events') {
      return _GridSquareButton(
        title: Localization().getStringEx('panel.browse.button.events.title', 'Events'),
        hint: Localization().getStringEx('panel.browse.button.events.hint', ''),
        icon: 'images/icon-browse-events.png',
        textColor: Styles().colors!.fillColorPrimary,
        onTap: () => _navigateToExploreEvents(),
      );
    }
    else if (code == 'dining') {
      return _GridSquareButton(
        title: Localization().getStringEx('panel.browse.button.dining.title', 'Dining'),
        hint: Localization().getStringEx('panel.browse.button.dining.hint', ''),
        icon: 'images/icon-browse-dinings.png',
        textColor: Styles().colors!.fillColorPrimary,
        onTap: () => _navigateToExploreDining(),
      );
    }
    else if (code == 'wellness') {
      return _GridSquareButton(
        title: Localization().getStringEx('panel.browse.button.wellness.title', 'Wellness'),
        hint: Localization().getStringEx('panel.browse.button.wellness.hint', ''),
        icon: 'images/icon-browse-wellness.png',
        textColor: Styles().colors!.fillColorPrimary,
        onTap: () => _navigateToWellness(),
      );
    }
    else if (code == 'saved') {
      return _GridSquareButton(
        title: Localization().getStringEx('panel.browse.button.saved.title', 'Saved'),
        hint: Localization().getStringEx('panel.browse.button.saved.hint', ''),
        icon: 'images/icon-browse-saved.png',
        textColor: Styles().colors!.fillColorPrimary,
        onTap: () => _navigateSaved(),
      );
    }
    else if (code == 'quick_polls') {
      return _GridSquareButton(
        title: Localization().getStringEx('panel.browse.button.quick_polls.title', 'Quick Polls'),
        hint: Localization().getStringEx('panel.browse.button.quick_polls.hint', ''),
        icon: 'images/icon-browse-quick-polls.png',
        textColor: Styles().colors!.fillColorPrimary,
        onTap: () => _navigateQuickPolls(),
      );
    }
    else if (code == 'groups') {
      return _GridSquareButton(
        title: Localization().getStringEx('panel.browse.button.groups.title', 'Groups'),
        hint: Localization().getStringEx('panel.browse.button.groups.hint', ''),
        icon: 'images/icon-browse-gropus.png',
        textColor: Styles().colors!.fillColorPrimary,
        onTap: () => _navigateGroups(),
      );
    }
    else if (code == 'building_access') {
      return _GridSquareButton(
        title: Localization().getStringEx('panel.browse.button.building_access.title', 'Building Access'),
        hint: Localization().getStringEx('panel.browse.button.building_access.hint', ''),
        icon: 'images/icon-browse-building-status.png',
        textColor: Styles().colors!.fillColorPrimary,
        loading: _buildingAccessAuthLoading,
        onTap: () => _navigateBuildingAccess(),
      );
    }
    else if (code == 'campus_guide') {
      return _GridSquareButton(
        title: Localization().getStringEx('panel.browse.button.campus_guide.title', 'Campus Guide'),
        hint: Localization().getStringEx('panel.browse.button.campus_guide.hint', ''),
        icon: 'images/icon-browse-student-guide.png',
        textColor: Styles().colors!.fillColorPrimary,
        onTap: () => _navigateCampusGuide(),
      );
    }
    else if (code == 'inbox') {
      return _GridSquareButton(
        title: Localization().getStringEx('panel.browse.button.inbox.title', 'Notifications'),
        hint: Localization().getStringEx('panel.browse.button.inbox.hint', ''),
        icon: 'images/icon-browse-inbox.png',
        textColor: Styles().colors!.fillColorPrimary,
        onTap: () => _navigateInbox(),
      );
    }
    else if (code == 'privacy_center') {
      return _GridSquareButton(
        title: Localization().getStringEx('panel.browse.button.privacy_center.title', 'Privacy'),
        hint: Localization().getStringEx('panel.browse.button.privacy_center.hint', ''),
        icon: 'images/icon-browse-privacy-center.png',
        textColor: Styles().colors!.fillColorPrimary,
        onTap: () => _navigatePrivacyCenter(),
      );
    }
    else if ((code == 'crisis_help') && _canCrisisHelp) {
      return _GridSquareButton(
        title: Localization().getStringEx('panel.browse.button.crisis_help.title', 'Crisis Help'),
        hint: Localization().getStringEx('panel.browse.button.crisis_help.hint', ''),
        icon: 'images/icon-browse-crisis-help.png',
        textColor: Styles().colors!.fillColorPrimary,
        onTap: () => _navigateCrisisHelp(),
      );
    }
    else {
      return null;
    }
  }

  List<Widget> _buildBrowseSecondary() {
    List<Widget> list = [
//      Container(height: 1, color: Styles().colors.surfaceAccent,),
    ];
    List<dynamic> codes = FlexUI()['browse.secondary'] ?? [];
    for (String code in codes) {
      Widget? entry = _buildBrowseSecondaryEntry(code);
      if (entry != null) {
        list.add(entry);
        list.add(Padding(padding: _ribbonButtonPadding, child: Container(height: 1, color: Styles().colors!.surfaceAccent,),));
      }
    }

    return list;
  }

  Widget? _buildBrowseSecondaryEntry(String code) {
    if (code == 'settings') {
      return _RibbonButton(
        icon: Image.asset('images/icon-settings.png'),
        title: Localization().getStringEx("panel.browse.button.settings.title","Settings"),
        hint: Localization().getStringEx("panel.browse.button.settings.hint",""),
        padding: _ribbonButtonPadding,
        onTap: () => _navigateSettings(),
      );
    }
    else if (code == 'my_illini') {
      return _RibbonButton(
        icon: Image.asset('images/icon-my-illini.png'),
        accessoryIcon: Image.asset('images/link-out.png'),
        title: Localization().getStringEx('panel.browse.button.my_illini.title', 'My Illini'),
        hint: Localization().getStringEx('panel.browse.button.my_illini.hint', ''),
        padding: _ribbonButtonPadding,
        onTap: () =>  _navigateMyIllini(),
      );
    }
    else if (code == 'illini_cash') {
      return _RibbonButton(
        icon: Image.asset('images/icon-cost.png'),
        title: Localization().getStringEx('panel.browse.button.illini_cash.title', 'Illini Cash'),
        hint: Localization().getStringEx('panel.browse.button.illini_cash.hint', ''),
        padding: _ribbonButtonPadding,
        onTap: () =>  _navigateIlliniCash(),
      );
    }
    else if (code == 'add_illini_cash') {
      return _RibbonButton(
        title: Localization().getStringEx('panel.browse.button.add_illini_cash.title', 'Add Illini Cash'),
        hint: Localization().getStringEx('panel.browse.button.add_illini_cash.hint', ''),
        icon: Image.asset('images/icon-illini-cash.png'),
        padding: _ribbonButtonPadding,
        onTap: () => _navigateToAddIlliniCash(),
      );
    }
    else if (code == 'meal_plan') {
      return _RibbonButton(
        icon: Image.asset('images/icon-dining-orange.png'),
        title: Localization().getStringEx('panel.browse.button.meal_plan.title', 'Meal Plan'),
        hint: Localization().getStringEx('panel.browse.button.meal_plan.hint', ''),
        padding: _ribbonButtonPadding,
        onTap: () =>  _navigateMealPlan(),
      );
    }
    else if (code == 'laundry') {
      return _RibbonButton(
        icon: Image.asset('images/icon-washer.png'),
        title: Localization().getStringEx('panel.browse.button.laundry.title', 'Laundry'),
        hint: Localization().getStringEx('panel.browse.button.laundry.hint', ''),
        padding: _ribbonButtonPadding,
        onTap: () =>  _navigateLaundry(),
      );
    }
    else if (code == 'parking') {
      return _RibbonButton(
        icon: Image.asset('images/icon-parking.png'),
        title: Localization().getStringEx('panel.browse.button.parking.title', 'State Farm Event Parking'),
        hint: Localization().getStringEx('panel.browse.button.parking.hint',''),
        padding: _ribbonButtonPadding,
        onTap: () => _navigateParking(),
      );
    }
    else if (code == 'create_event') {
      return _RibbonButton(
        icon: Image.asset('images/icon-create-event.png'),
        title: Localization().getStringEx('panel.browse.button.create_event.title', 'Create an event'),
        hint: Localization().getStringEx('panel.browse.button.create_event.hint', ''),
        padding: _ribbonButtonPadding,
        onTap: () => _navigateCreateEvent(),
      );
    }
    else if (code == 'create_stadium_poll') {
      return _RibbonButton(
        icon: Image.asset('images/icon-settings.png'),
        title: Localization().getStringEx('panel.browse.button.create_stadium_poll.title', 'Create Stadium Poll'),
        hint: Localization().getStringEx('panel.browse.button.create_stadium_poll.hint',''),
        padding: _ribbonButtonPadding,
        onTap:  () => _navigateCreateStadiumPoll(),
      );
    }
    else if (code == 'feedback') {
      return _RibbonButton(
        icon: Image.asset('images/icon-feedback.png'),
        accessoryIcon: Image.asset('images/link-out.png'),
        title: Localization().getStringEx('panel.browse.button.feedback.title', 'Provide Feedback'),
        hint: Localization().getStringEx('panel.browse.button.feedback.hint', ''),
        padding: _ribbonButtonPadding,
        onTap: () => _onFeedbackTap(),
      );
    }
    else if ((code == 'faqs') && _canFAQs) {
      return _RibbonButton(
        icon: Image.asset('images/icon-faqs.png'),
        accessoryIcon: Image.asset('images/link-out.png'),
        title: Localization().getStringEx('panel.browse.button.faqs.title', 'FAQs'),
        hint: Localization().getStringEx('panel.browse.button.faqs.hint', ''),
        padding: _ribbonButtonPadding,
        onTap: () => _onFAQsTap(),
      );
    }
    else if ((code == 'date_cat') && _canDateCat) {
      return _RibbonButton(
        icon: Image.asset('images/icon-settings.png'),
        accessoryIcon: Image.asset('images/link-out.png'),
        title: Localization().getStringEx('panel.browse.button.date_cat.title', 'Due Date Catalog'),
        hint: Localization().getStringEx('panel.browse.button.date_cat.hint', ''),
        padding: _ribbonButtonPadding,
        onTap: () => _onDateCatTap(),
      );
    }
    else if ((code == 'video_tutorial') && _canVideoTutorial) {
      return _RibbonButton(
        icon: Image.asset('images/icon-settings.png'),
        title: Localization().getStringEx('panel.browse.button.video_tutorial.title', 'Video Tutorial'),
        hint: Localization().getStringEx('panel.browse.button.video_tutorial.hint', ''),
        padding: _ribbonButtonPadding,
        onTap: () => _onVideoTutorialTap(),
      );
    }

    else {
      return null;
    }
  }

  Widget _buildPrivacyAlertWidget() {
    final String iconMacro = '{{privacy_level_icon}}';
    String privacyMsg = Localization().getStringEx('panel.browse.alert.building_access.privacy_update.msg', 'With your privacy level at $iconMacro , you will have to sign in every time to show your building access status. Do you want to change your privacy level to 4 or 5 so you only have to sign in once?');
    int iconMacroPosition = privacyMsg.indexOf(iconMacro);
    String privacyMsgStart = (0 < iconMacroPosition) ? privacyMsg.substring(0, iconMacroPosition) : '';
    String privacyMsgEnd = ((0 < iconMacroPosition) && (iconMacroPosition < privacyMsg.length)) ? privacyMsg.substring(iconMacroPosition + iconMacro.length) : '';
    return RichText(text: TextSpan(style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.bold), children: [
      TextSpan(text: privacyMsgStart),
      WidgetSpan(alignment: PlaceholderAlignment.middle, child: _buildPrivacyLevelWidget()),
      TextSpan(text: privacyMsgEnd)
    ]));
  }

  Widget _buildPrivacyLevelWidget() {
    String privacyLevel = Auth2().prefs?.privacyLevel?.toString() ?? '';
    return Container(height: 40, width: 40, alignment: Alignment.center, decoration: BoxDecoration( border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 2), color: Styles().colors!.white, borderRadius: BorderRadius.all(Radius.circular(100)),), child:
      Container(height: 32, width: 32, alignment: Alignment.center, decoration: BoxDecoration( border: Border.all(color: Styles().colors!.fillColorSecondary!, width: 2), color: Styles().colors!.white, borderRadius: BorderRadius.all(Radius.circular(100)), ), child:
        Text(privacyLevel.toString(), style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 18, color: Styles().colors!.fillColorPrimary))));
  }

  // Primary

  void _navigateToAthletics() {
    Analytics().logSelect(target: "Athletics");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel()));
  }

  void _navigateToExploreEvents() {
    Analytics().logSelect(target: "Events");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(initialItem: ExploreItem.Events)));
  }

  void _navigateToExploreDining() {
    Analytics().logSelect(target: "Dining");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(initialItem: ExploreItem.Dining)));
  }

  void _navigateToWellness() {
    Analytics().logSelect(target: "Wellness");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel()));
  }

  void _navigateSaved() {
    Analytics().logSelect(target: "Saved");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SavedPanel()));
  }

  void _navigateQuickPolls() {
    Analytics().logSelect(target: "Quick Polls");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PollsHomePanel()));
  }

  void _navigateGroups() {
    Analytics().logSelect(target: "Groups");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupsHomePanel()));
  }

  void _navigateBuildingAccess() {
    if (!_buildingAccessAuthLoading) {
      Analytics().logSelect(target: 'Building Access');
      if (Connectivity().isOffline) {
        AppAlert.showOfflineMessage(context, "");
      } else if (!Auth2().privacyMatch(4)) {
        _onBuildingAccessPrivacyDoNotMatch();
      } else {
        _onBuildingAccessPrivacyMatch();
      }
    }
  }
  
  void _onBuildingAccessPrivacyDoNotMatch() {
    AppAlert.showCustomDialog(context: context, contentWidget: _buildPrivacyAlertWidget(), actions: [
      TextButton(
          child: Text(Localization().getStringEx('panel.browse.alert.building_access.privacy_level.4.button.label', 'Set to 4')),
          onPressed: () => _buildingAccessIncreasePrivacyLevelAndAuthentiate(4)),
      TextButton(
          child: Text(Localization().getStringEx('panel.browse.alert.building_access.privacy_level.5.button.label', 'Set to 5')),
          onPressed: () => _buildingAccessIncreasePrivacyLevelAndAuthentiate(5)),
      TextButton(child: Text(Localization().getStringEx('dialog.no.title', 'No')), onPressed: _buildingAccessNotIncreasePrivacyLevel)
    ]);
  }

  void _onBuildingAccessPrivacyMatch() {
    if (Auth2().isOidcLoggedIn) {
      _showBuildingAccessPanel();
    } else {
      _buildingAccessOidcAuthenticate();
    }
  }

  void _buildingAccessNotIncreasePrivacyLevel() {
    Analytics().logSelect(target: 'No');
    Navigator.of(context).pop();
    if (StringUtils.isNotEmpty(Config().iCardBoardingPassUrl)) {
      url_launcher.launch(Config().iCardBoardingPassUrl!);
    }
  }

  void _buildingAccessIncreasePrivacyLevelAndAuthentiate(int privacyLevel) {
    Analytics().logSelect(target: 'Yes');
    Navigator.of(context).pop();
    Auth2().prefs?.privacyLevel = privacyLevel;
    Future.delayed(Duration(milliseconds: 300), () {
      _onBuildingAccessPrivacyMatch();
    });
  }

  void _buildingAccessOidcAuthenticate() {
    if (mounted) {
      setState(() {
        _buildingAccessAuthLoading = true;
      });
    }
    Auth2().authenticateWithOidc().then((Auth2OidcAuthenticateResult? result) {
      if (mounted) {
        setState(() {
          _buildingAccessAuthLoading = false;
        });
        _buildingAccessOidcDidAuthenticate(result);
      }
    });
  }

  void _buildingAccessOidcDidAuthenticate(Auth2OidcAuthenticateResult? result) {
    if (result == Auth2OidcAuthenticateResult.succeeded) {
      _showBuildingAccessPanel();
    } else if (result != null) {
      AppAlert.showDialogResult(
          context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
    }
  }

  void _showBuildingAccessPanel() {
    showModalBottomSheet(context: context,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        builder: (context) {
          return IDCardPanel();
        });
  }

  void _navigateCampusGuide() {
    Analytics().logSelect(target: "Campus Guide");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CampusGuidePanel()));
  }

  void _navigateInbox() {
    Analytics().logSelect(target: "Inbox");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsNotificationsContentPanel(content: SettingsNotificationsContent.inbox)));
  }

  void _navigatePrivacyCenter() {
    Analytics().logSelect(target: "Privacy Center");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsProfileContentPanel(content: SettingsProfileContent.privacy)));
  }

  bool get _canCrisisHelp => StringUtils.isNotEmpty(Config().crisisHelpUrl);

  void _navigateCrisisHelp() {
    Analytics().logSelect(target: "Crisis Help");

    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.crisis_help', 'Crisis Help is not available while offline.'));
    }
    else if (StringUtils.isNotEmpty(Config().crisisHelpUrl)) {
      url_launcher.launch(Config().crisisHelpUrl!);
    }
  }

  // Secondary

  void _navigateSettings() {
    Analytics().logSelect(target: "Settings");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsHomeContentPanel()));
  }

  void _navigateMyIllini() {
    Analytics().logSelect(target: "My Illini");
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.my_illini', 'My Illini not available while offline.'));
    }
    else if (StringUtils.isNotEmpty(Config().myIlliniUrl)) {
      url_launcher.launch(Config().myIlliniUrl!);
    }
  }

  void _navigateIlliniCash() {
    Analytics().logSelect(target: "Illini Cash");
    Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
        settings: RouteSettings(name: SettingsIlliniCashPanel.routeName),
        builder: (context){
          return SettingsIlliniCashPanel();
        }
    ));
  }

  void _navigateToAddIlliniCash() {
    Analytics().logSelect(target: "Add Illini Cash");
    Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) => SettingsAddIlliniCashPanel()));
  }

  void _navigateMealPlan() {
    Analytics().logSelect(target: "Meal Plan");
    Navigator.of(context, rootNavigator: false).push(CupertinoPageRoute(
        builder: (context){
          return SettingsMealPlanPanel();
        }
    ));
  }

  void _navigateLaundry() {
    Analytics().logSelect(target: "Laundry");
    if (Connectivity().isNotOffline) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryHomePanel()));
    }
    else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.laundry', 'Laundry not available while offline.'));
    }
  }

  void _navigateParking() {
    Analytics().logSelect(target: "Parking");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ParkingEventsPanel()));
  }

  void _navigateCreateEvent() {
    Analytics().logSelect(target: "Create an Event");
    if (Connectivity().isNotOffline) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => CreateEventPanel()));
    }
    else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.create_event', 'Create event not available while offline.'));
    }
  }

  void _navigateCreateStadiumPoll() {
    Analytics().logSelect(target: "Create Stadium Poll");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CreateStadiumPollPanel()));
  }

  void _onFeedbackTap() {
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

  bool get _canFAQs => StringUtils.isNotEmpty(Config().faqsUrl);

  void _onFAQsTap() {
    Analytics().logSelect(target: "FAQs");

    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.faqs', 'FAQs is not available while offline.'));
    }
    else if (StringUtils.isNotEmpty(Config().faqsUrl)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(
        url: Config().faqsUrl,
        title: Localization().getStringEx('panel.settings.faqs.label.title', 'FAQs'),
      )));
    }
  }

  bool get _canDateCat => StringUtils.isNotEmpty(Config().dateCatalogUrl);

  void _onDateCatTap() {
    Analytics().logSelect(target: "Due Date Catalog");
    
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.date_cat', 'Due Date Catalog not available while offline.'));
    }
    else if (StringUtils.isNotEmpty(Config().dateCatalogUrl)) {
      url_launcher.launch(Config().dateCatalogUrl!);
    }
  }

  bool get _canVideoTutorial => StringUtils.isNotEmpty(Config().videoTutorialUrl);

  void _onVideoTutorialTap() {
    Analytics().logSelect(target: "Video Tutorial");
    
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.video_tutorial', 'Video Tutorial not available while offline.'));
    }
    else if (_canVideoTutorial) {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) => SettingsVideoTutorialPanel()));
    }
  }
}

// _RibbonButton

class _RibbonButton extends StatelessWidget {
  final Image icon;
  final Image? accessoryIcon;
  final String? title;
  final String? hint;
  final GestureTapCallback? onTap;
  final EdgeInsets padding;

  _RibbonButton({required this.icon,
    required this.title,
    required this.hint,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 0),
    this.accessoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: title,
        hint:hint,
        button: true,
        excludeSemantics: true,
        child: Container(
//          height: 48,
          padding: padding,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                icon,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      title!,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          color: Styles().colors!.fillColorPrimary,
                          fontSize: 16,
                          fontFamily: Styles().fontFamilies!.bold),
                    ),
                  ),
                ),
                accessoryIcon ?? Image.asset('images/chevron-right.png')
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// _GridSquareButton

class _GridSquareButton extends StatelessWidget {
  final String? title;
  final String? hint;
  final String? icon;
  final Color? color;
  final Color? textColor;
  final bool? loading;
  final GestureTapCallback? onTap;

  _GridSquareButton({this.title, this.hint = '', this.icon, this.color = Colors.white, this.textColor = Colors.white, this.loading = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    const int contentHeight = 80;
    double scaleFactorAdditionalHeight = MediaQuery.of(context).textScaleFactor * 30 ;
    return Stack(alignment: Alignment.center, children: [
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Semantics(
          label: title,
          hint: hint,
          button: true,
          excludeSemantics: true,
          child: Container(
            height: contentHeight + scaleFactorAdditionalHeight,
            decoration: BoxDecoration(
                          color: color,
                          //border: Border.all(color: Colors.grey, width: 1),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))]
            ),
            child: Padding(padding: EdgeInsets.all(12), child: Stack(children: <Widget>[
              Align(alignment: Alignment.topLeft, child: Text(title!,
                style: TextStyle(
                    fontFamily: Styles().fontFamilies!.bold,
                    color: textColor,
                    fontSize: 20,),
              ),),
              Align(alignment: Alignment.bottomRight, child:
                Image.asset(icon!, color: color, colorBlendMode:BlendMode.multiply),
              ),
              
            ],),)
        ))),
        Visibility(visible: (loading == true), child:
          CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary)),
        ),
    ]);
  }
}
