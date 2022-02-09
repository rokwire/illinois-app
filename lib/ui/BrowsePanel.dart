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

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/SavedPanel.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/athletics/AthleticsHomePanel.dart';
import 'package:illinois/ui/events/CreateEventPanel.dart';
import 'package:illinois/ui/groups/GroupsHomePanel.dart';
import 'package:illinois/ui/guide/CampusGuidePanel.dart';
import 'package:illinois/ui/inbox/InboxHomePanel.dart';
import 'package:illinois/ui/laundry/LaundryHomePanel.dart';
import 'package:illinois/ui/parking/ParkingEventsPanel.dart';
import 'package:illinois/ui/polls/CreateStadiumPollPanel.dart';
import 'package:illinois/ui/polls/PollsHomePanel.dart';
import 'package:illinois/ui/settings/SettingsAddIlliniCashPanel.dart';
import 'package:illinois/ui/settings/SettingsHomePanel.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/WellnessPanel.dart';
import 'package:illinois/ui/settings/SettingsIlliniCashPanel.dart';
import 'package:illinois/ui/settings/SettingsMealPlanPanel.dart';
import 'package:illinois/ui/settings/SettingsPrivacyCenterPanel.dart';
import 'package:illinois/ui/wallet/IDCardPanel.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class BrowsePanel extends StatefulWidget {

  BrowsePanel();

  @override
  _BrowsePanelState createState() => _BrowsePanelState();
}

class _BrowsePanelState extends State<BrowsePanel> implements NotificationsListener {

  static const _saferIllonoisAppDeeplink      = "edu.illinois.covid://covid.illinois.edu/health/status";
  static const _saferIllonoisAppStoreApple    = "itms-apps://itunes.apple.com/us/app/apple-store/id1524691383";
  static const _saferIllonoisAppStoreAndroid  = "market://details?id=edu.illinois.covid";

  final EdgeInsets _ribbonButtonPadding = EdgeInsets.symmetric(horizontal: 16);

  bool _groupsLogin = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Localization.notifyStringsUpdated,
      FlexUI.notifyChanged,
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

  @override
  Widget build(BuildContext context) {

    List<Widget> contentList = [];
    List<dynamic> codes = FlexUI()['browse'] ?? [];
    for (String code in codes) {
      if (code == 'all') {
        contentList.add(_buildBrowseAll());
      }
      else if (code == 'content') {
        contentList.addAll(_buildBrowseContent());
      }
    }

    return Scaffold(
        body: Column(
          children: <Widget>[
            Expanded(
                child: CustomScrollView(
                  slivers: <Widget>[
                    SliverAppBar(pinned: true, floating: true, primary: true, forceElevated: true, centerTitle: true,
                      title: Text(
                        Localization().getStringEx('panel.browse.label.title','Browse')!,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0),
                      ),
                      actions: <Widget>[
                        Semantics(
                          label: Localization().getStringEx('headerbar.settings.title', 'Settings'),
                          hint: Localization().getStringEx('headerbar.settings.hint', ''),
                          button: true,
                          excludeSemantics: true,
                          child: IconButton(
                              icon: Image.asset('images/settings-white.png'),
                              onPressed: () {_navigateSettings(); }))
                      ],
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        Column(
                          children: contentList,
                        )
                      ]),
                    )
                  ],
                )
            ),
          ],
        ),
        backgroundColor: Styles().colors!.background,
      );
  }

  Widget _buildBrowseAll() {

    List<Widget> row = [];
    int rowEntries = 0;

    List<Widget> list = [];
    int listEntrues = 0;

    list.add(Container(height: 18,));

    const int gridWidth = 2;
    List<dynamic> codes = FlexUI()['browse.all'] ?? [];
    for (String code in codes) {
      Widget? entry = _buildBrowseAllEntry(code);
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
  
  Widget? _buildBrowseAllEntry(String code) {
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
        title: Localization().getStringEx('panel.browse.button.quick_polls.title', 'Quick polls'),
        hint: Localization().getStringEx('panel.browse.button.quick_polls.hint', ''),
        icon: 'images/icon-browse-quick-polls.png',
        textColor: Styles().colors!.fillColorPrimary,
        onTap: () => _navigateQuickPolls(),
      );
    }
    else if (code == 'groups') {
      return Stack(
        alignment: Alignment.center,
        children: [
          _GridSquareButton(
            title: Localization().getStringEx('panel.browse.button.groups.title', 'Groups'),
            hint: Localization().getStringEx('panel.browse.button.groups.hint', ''),
            icon: 'images/icon-browse-gropus.png',
            textColor: Styles().colors!.fillColorPrimary,
            onTap: () => _navigateGroups(),
          ),
          Visibility(
            visible: _groupsLogin,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.white)
            ),
          )
        ],
      );
    }
    else if (code == 'safer') {
      return _GridSquareButton(
        title: Localization().getStringEx('panel.browse.button.safer.title', 'Safer Illinois'),
        hint: Localization().getStringEx('panel.browse.button.safer.hint', ''),
        icon: 'images/icon-browse-safer.png',
        textColor: Styles().colors!.fillColorPrimary,
        onTap: () => _navigateToSaferIllinois(),
      );
    }
    else if (code == 'building_status') {
      return _GridSquareButton(
        title: Localization().getStringEx('panel.browse.button.building_status.title', 'Building Entry'),
        hint: Localization().getStringEx('panel.browse.button.building_status.hint', ''),
        icon: 'images/icon-browse-building-status.png',
        textColor: Styles().colors!.fillColorPrimary,
        onTap: () => _navigateToBuildingStatus(),
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
    else if (code == 'crisis_help') {
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

  List<Widget> _buildBrowseContent() {
    List<Widget> list = [
//      Container(height: 1, color: Styles().colors.surfaceAccent,),
    ];
    List<dynamic> codes = FlexUI()['browse.content'] ?? [];
    for (String code in codes) {
      Widget? entry = _buildBrowseContentEntry(code);
      if (entry != null) {
        list.add(entry);
        list.add(Padding(padding: _ribbonButtonPadding, child: Container(height: 1, color: Styles().colors!.surfaceAccent,),));
      }
    }

    return list;
  }

  Widget? _buildBrowseContentEntry(String code) {
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
    else if (code == 'saved') {
      return _RibbonButton(
        icon: Image.asset('images/icon-saved.png'),
        title: Localization().getStringEx('panel.browse.button.saved.title', 'Saved'),
        hint: Localization().getStringEx('panel.browse.button.saved.hint', ''),
        padding: _ribbonButtonPadding,
        onTap: () => _navigateSaved(),
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
    else if (code == 'quick_polls') {
      return _RibbonButton(
        icon: Image.asset('images/icon-quickpoll.png'),
        title: Localization().getStringEx('panel.browse.button.quick_polls.title', 'Quick Polls'),
        hint: Localization().getStringEx('panel.browse.button.quick_polls.hint',''),
        padding: _ribbonButtonPadding,
        onTap: () => _navigateQuickPolls(),
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
    else if (code == 'state_farm_wayfinding') {
      return _RibbonButton(
        icon: Image.asset('images/icon-settings.png'),
        title: Localization().getStringEx('panel.browse.button.state_farm_wayfinding.title', 'State Farm Wayfinding'),
        hint: Localization().getStringEx('panel.browse.button.state_farm_wayfinding.hint',''),
        padding: _ribbonButtonPadding,
        onTap:  () => _navigateStateFarmWayfinding(),
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
    else if (code == 'faqs') {
      return _RibbonButton(
        icon: Image.asset('images/icon-faqs.png'),
        accessoryIcon: Image.asset('images/link-out.png'),
        title: Localization().getStringEx('panel.browse.button.faqs.title', 'FAQs'),
        hint: Localization().getStringEx('panel.browse.button.faqs.hint', ''),
        padding: _ribbonButtonPadding,
        onTap: () => _onFAQsTap(),
      );
    }

    else {
      return null;
    }
  }

  void _navigateToExploreEvents() {
    Analytics().logSelect(target: "Events");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(initialTab: ExploreTab.Events, showHeaderBack: true,)));
  }

  void _navigateToExploreDining() {
    Analytics().logSelect(target: "Dining");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(initialTab: ExploreTab.Dining, showHeaderBack: true,)));
  }

  void _navigateToAthletics() {
    Analytics().logSelect(target: "Athletics");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel()));
  }

  void _navigateToWellness() {
    Analytics().logSelect(target: "Wellness");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessPanel()));
  }

  void _navigateSettings() {
    Analytics().logSelect(target: "Settings");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsHomePanel()));
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

  void _navigateSaved() {
    Analytics().logSelect(target: "Saved");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SavedPanel()));
  }

  void _navigateParking() {
    Analytics().logSelect(target: "Parking");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ParkingEventsPanel()));
  }

  void _navigateQuickPolls() {
    Analytics().logSelect(target: "Quick Polls");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PollsHomePanel()));
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

  void _navigateStateFarmWayfinding() {
    Analytics().logSelect(target: "State Farm Wayfinding");
    NativeCommunicator().launchMap(target: {
      'latitude': 40.096247,
      'longitude': -88.235923,
      'zoom': 17,
    });
  }

  void _navigateGroups() {
    Analytics().logSelect(target: "Groups");
    if(Auth2().isOidcLoggedIn) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupsHomePanel()));
    } else if (_groupsLogin != true) {
      setState(() { _groupsLogin = true; });
      Auth2().authenticateWithOidc().then((bool? success) {
        if (mounted) {
          setState(() { _groupsLogin = false; });
          if (success == true) {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupsHomePanel()));
          } else if (success == false) {
            AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
          }
        }
      });
    }
  }

  void _navigateCampusGuide() {
    Analytics().logSelect(target: "Campus Guide");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CampusGuidePanel()));
  }

  void _navigateInbox() {
    Analytics().logSelect(target: "Inbox");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => InboxHomePanel()));
  }

  void _navigatePrivacyCenter() {
    Analytics().logSelect(target: "Privacy Center");
    Navigator.push(context, CupertinoPageRoute(builder: (context) =>SettingsPrivacyCenterPanel()));
  }

  void _navigateCrisisHelp() {
    Analytics().logSelect(target: "Crisis Help");

    if (Connectivity().isNotOffline && Config().crisisHelpUrl != null) {
      url_launcher.launch(Config().crisisHelpUrl!);
    }
    else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.crisis_help', 'Crisis Help is not available while offline.'));
    }
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


  void _onFAQsTap() {
    Analytics().logSelect(target: "FAQs");

    if (Connectivity().isNotOffline ) {
      String faqsUrl = "http://mhcwellness.illinois.edu/faq"; // TBD from Config after confirmation Config().faqsUrl

      String? panelTitle = Localization().getStringEx('panel.settings.faqs.label.title', 'FAQs');
      Navigator.push(
          context, CupertinoPageRoute(builder: (context) => WebPanel(url: faqsUrl, title: panelTitle,)));
    }
    else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.faqs', 'FAQs is not available while offline.'));
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

  Future<void> _navigateToSaferIllinois() async{
    Analytics().logSelect(target: "Safer Illinois");
    try {

      if (await url_launcher.canLaunch(_saferIllonoisAppDeeplink)) {
        await url_launcher.launch(_saferIllonoisAppDeeplink);
      } else {
        if(Platform.isAndroid){
          if(await url_launcher.canLaunch(_saferIllonoisAppStoreAndroid)) {
            await url_launcher.launch(_saferIllonoisAppStoreAndroid);
          }
        }
        else{
          if(await url_launcher.canLaunch(_saferIllonoisAppStoreApple)) {
            await url_launcher.launch(_saferIllonoisAppStoreApple);
          }
        }
      }
    }
    catch(e) {
      print(e);
    }
  }

  void _navigateToBuildingStatus() {
    Analytics().logSelect(target: 'Building Entry');
    //Navigator.push(context, CupertinoPageRoute(
    //  builder: (context) => IDCardPanel()
    //));
    showModalBottomSheet(context: context,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        builder: (context){
          return IDCardPanel();
        }
    );
  }

  void _navigateToAddIlliniCash(){
    Analytics().logSelect(target: "Add Illini Cash");
    Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) => SettingsAddIlliniCashPanel()));
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if ((name == Connectivity.notifyStatusChanged) ||
        (name == Localization.notifyStringsUpdated) ||
        (name == FlexUI.notifyChanged) ||
        (name == Styles.notifyChanged))
    {
      setState(() { });
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
  final GestureTapCallback? onTap;

  _GridSquareButton({this.title, this.hint = '', this.icon, this.color = Colors.white, this.textColor = Colors.white, this.onTap});

  @override
  Widget build(BuildContext context) {
    const int contentHeight = 80;
    double scaleFactorAdditionalHeight = MediaQuery.of(context).textScaleFactor * 30 ;
    return GestureDetector(
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
        )));
  }
}
