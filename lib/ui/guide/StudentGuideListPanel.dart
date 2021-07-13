
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/StudentGuide.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/SavedPanel.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/athletics/AthleticsHomePanel.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/groups/GroupsHomePanel.dart';
import 'package:illinois/ui/guide/StudentGuideEntryCard.dart';
import 'package:illinois/ui/laundry/LaundryHomePanel.dart';
import 'package:illinois/ui/parking/ParkingEventsPanel.dart';
import 'package:illinois/ui/polls/PollsHomePanel.dart';
import 'package:illinois/ui/settings/SettingsIlliniCashPanel.dart';
import 'package:illinois/ui/settings/SettingsMealPlanPanel.dart';
import 'package:illinois/ui/wallet/IDCardPanel.dart';
import 'package:illinois/ui/wallet/MTDBusPassPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/utils/Utils.dart';

class StudentGuideListPanel extends StatefulWidget {
  final String category;
  final StudentGuideSection section;
  final List<dynamic> contentList;
  final String contentTitle;

  StudentGuideListPanel({ this.category, this.section, this.contentList, this.contentTitle});

  _StudentGuideListPanelState createState() => _StudentGuideListPanelState();
}

class _StudentGuideListPanelState extends State<StudentGuideListPanel> implements NotificationsListener {

  List<Map<String, dynamic>> _guideItems = <Map<String, dynamic>>[];
  LinkedHashSet<String> _features = LinkedHashSet<String>();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      StudentGuide.notifyChanged,
    ]);
    _buildGuideContent();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == StudentGuide.notifyChanged) {
      setState(() {
        _buildGuideContent();
      });
    }
  }

  void _buildGuideContent() {
    if ((widget.category != null) && (widget.section != null) && (StudentGuide().contentList != null)) {
      _guideItems = <Map<String, dynamic>>[];

      for (dynamic contentEntry in StudentGuide().contentList) {
        Map<String, dynamic> guideEntry = AppJson.mapValue(contentEntry);
        if (guideEntry != null) {
          String category = AppJson.stringValue(StudentGuide().entryValue(guideEntry, 'category'));
          StudentGuideSection section = StudentGuideSection.fromGuideEntry(guideEntry);
          if ((widget.category == category) && (widget.section == section)) {
            _guideItems.add(guideEntry);
          }
        }
      }
    }
    else if (widget.contentList != null) {
      _guideItems = List.from(widget.contentList);
    }
    else {
      _guideItems = null;
    }

    if (_guideItems != null) {

        _guideItems.sort((dynamic entry1, dynamic entry2) {
          return AppSort.compareIntegers(
            (entry1 is Map) ? AppJson.intValue(entry1['sort_order']) : null,
            (entry2 is Map) ? AppJson.intValue(entry2['sort_order']) : null
          );
        });

      _features = LinkedHashSet<String>();
      for (Map<String, dynamic> guideEntry in _guideItems) {
        List<dynamic> features = AppJson.listValue(StudentGuide().entryValue(guideEntry, 'features'));
        if (features != null) {
          for (dynamic feature in features) {
            if ((feature is String) && !_features.contains(feature)) {
              _features.add(feature);
            }
          }
        }
      }
    }
    else {
      _features = null;
    }
  }

  @override
  Widget build(BuildContext context) {

    String title;
    if (widget.category != null) {
      title = widget.category;
    }
    else if (widget.contentList != null) {
      title = Localization().getStringEx('panel.student_guide_list.label.highlights.heading', 'Student Guide');
    }
    
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(title ?? '', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold),),
      ),
      body: Column(children: _buildContent()),
      backgroundColor: Styles().colors.background,
    );
  }

  List<Widget> _buildContent() {
    List<Widget> contentList = <Widget>[];

    if ((_guideItems != null) && (0 < _guideItems.length)) {

      if ((_features != null) && _features.isNotEmpty) {
        contentList.add(_buildFeatures());
      }

      if (widget.section != null) {
        contentList.add(_buildSectionHeading(widget.section.name));
      }
      else if (widget.contentList != null) {
        contentList.add(_buildSectionHeading(widget.contentTitle));
      }

      List<Widget> cardsList = <Widget>[];
      if (_guideItems != null) {
        for (Map<String, dynamic> guideEntry in _guideItems) {
          cardsList.add(
            Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16), child:
              StudentGuideEntryCard(guideEntry)
            )
          );
        }
      }

      contentList.add(
        Expanded(child:
          SingleChildScrollView(child:
            Padding(padding: EdgeInsets.only(bottom: 16), child:
              SafeArea(child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children:
                  cardsList
                ),
              ),
            ),
          ),
        ),
      );
    }
    else {
      contentList.add(
        Expanded(child:
          Padding(padding: EdgeInsets.all(32), child:
            Center(child:
              Text(Localization().getStringEx('panel.student_guide_list.label.content.empty', 'Empty guide content'), style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold),)
            ,)
          ),
        ),
      );
    }
    contentList.add(TabBarWidget());

    return contentList;
  }

  Widget _buildSectionHeading(String title) {
    return Container(color: Styles().colors.fillColorPrimary, child:
      Row(children: [
        Expanded(child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
            Semantics(hint: "Heading", child:
              Text(title ?? '', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.bold),)
            )
          ),
        )
      ],),
    );
  }

  Widget _buildFeatures() {
    if (_features != null) {
      List<Widget> rowWidgets = <Widget>[];
      List<Widget> colWidgets = <Widget>[];
      for (String feature in _features) {
        StudentGuideFeatureButton featureButton = _buildFeatureButton(feature);
        if (featureButton != null) {
          if (rowWidgets.isNotEmpty) {
            rowWidgets.add(Container(width: 6),);
          }
          rowWidgets.add(Expanded(child: featureButton));
          
          if (rowWidgets.length >= 5) {
            if (colWidgets.isNotEmpty) {
              colWidgets.add(Container(height: 6),);
            }
            colWidgets.add(Row(crossAxisAlignment: CrossAxisAlignment.center, children: rowWidgets));
            rowWidgets = <Widget>[];
          }
        }
      }

      if (0 < rowWidgets.length) {
        while (rowWidgets.length < 5) {
          rowWidgets.add(Container(width: 6),);
          rowWidgets.add(Expanded(child: Container()));
        }
        if (colWidgets.isNotEmpty) {
          colWidgets.add(Container(height: 6),);
        }
        colWidgets.add(Row(children: rowWidgets));
      }

      return Container(height: (32 * 2 + (12 * 3 + 50 + 16)).toDouble(), child:
        SingleChildScrollView(child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32), child:
            Column(children: colWidgets,),
          )
        ),
      );

    }

    return null;

    /*return Padding(padding: EdgeInsets.all(16), child:
        Column(children: [
          Row(children: [
            Expanded(child: StudentGuideFeatureButton.fromFeature('athletics')),
            Container(width: 6),
            Expanded(child: StudentGuideFeatureButton.fromFeature('events')),
            Container(width: 6),
            Expanded(child: StudentGuideFeatureButton.fromFeature('dining')),
          ],),
          Container(height: 6),
          Row(children: [
            Expanded(child: StudentGuideFeatureButton.fromFeature('laundry')),
            Container(width: 6),
            Expanded(child: StudentGuideFeatureButton.fromFeature('quick-polls')),
            Container(width: 6),
            Expanded(child: Container()),
          ],),
        ],),
      );*/
  }

  StudentGuideFeatureButton _buildFeatureButton(String feature) {
    
    if (feature == 'athletics') {
      return StudentGuideFeatureButton(title: Localization().getStringEx("panel.student_guide_list.button.athletics.title", "Athletics"), icon: "images/icon-student-guide-athletics.png", onTap: _navigateAthletics,);
    }
    else if (feature == 'buss-pass') {
      return StudentGuideFeatureButton(title: Localization().getStringEx("panel.student_guide_list.button.buss_pass.title", "Buss Pass"), icon: "images/icon-student-guide-buss-pass.png", onTap: _navigateBussPass,);
    }
    else if (feature == 'dining') {
      return StudentGuideFeatureButton(title: Localization().getStringEx("panel.student_guide_list.button.dining.title", "Dining"), icon: "images/icon-student-guide-dining.png", onTap: _navigateDining);
    }
    else if (feature == 'events') {
      return StudentGuideFeatureButton(title: Localization().getStringEx("panel.student_guide_list.button.events.title", "Events"), icon: "images/icon-student-guide-events.png", onTap: _navigateEvents);
    }
    else if (feature == 'groups') {
      return StudentGuideFeatureButton(title: Localization().getStringEx("panel.student_guide_list.button.groups.title", "Groups"), icon: "images/icon-student-guide-groups.png", onTap: _navigateGroups);
    }
    else if (feature == 'illini-cash') {
      return StudentGuideFeatureButton(title: Localization().getStringEx("panel.student_guide_list.button.illini_cash.title", "Illini Cash"), icon: "images/icon-student-guide-illini-cash.png", onTap: _navigateIlliniCash);
    }
    else if (feature == 'illini-id') {
      return StudentGuideFeatureButton(title: Localization().getStringEx("panel.student_guide_list.button.illini_id.title", "Illini ID"), icon: "images/icon-student-guide-illini-id.png", onTap: _navigateIlliniId);
    }
    else if (feature == 'laundry') {
      return StudentGuideFeatureButton(title: Localization().getStringEx("panel.student_guide_list.button.laundry.title", "Laundry"), icon: "images/icon-student-guide-laundry.png", onTap: _navigateLaundry,);
    }
    else if (feature == 'library-card') {
      return StudentGuideFeatureButton(title: Localization().getStringEx("panel.student_guide_list.button.library_card.title", "Library Card"), icon: "images/icon-student-guide-library-card.png", onTap: _navigateLibraryCard);
    }
    else if (feature == 'meal-plan') {
      return StudentGuideFeatureButton(title: Localization().getStringEx("panel.student_guide_list.button.meal_plan.title", "Meal Plan"), icon: "images/icon-student-guide-meal-plan.png", onTap: _navigateMealPlan,);
    }
    else if (feature == 'my-illini') {
      return StudentGuideFeatureButton(title: Localization().getStringEx("panel.student_guide_list.button.my_illini.title", "My Illini"), icon: "images/icon-student-guide-my-illini.png", onTap: _navigateMyIllini);
    }
    else if (feature == 'parking') {
      return StudentGuideFeatureButton(title: Localization().getStringEx("panel.student_guide_list.button.parking.title", "Parking"), icon: "images/icon-student-guide-parking.png", onTap: _navigateParking);
    }
    else if (feature == 'quick-polls') {
      return StudentGuideFeatureButton(title: Localization().getStringEx("panel.student_guide_list.button.quick_polls.title", "Quick Polls"), icon: "images/icon-student-guide-quick-polls.png", onTap: _navigateQuickPolls);
    }
    else if (feature == 'saved') {
      return StudentGuideFeatureButton(title: Localization().getStringEx("panel.student_guide_list.button.saved.title", "Saved"), icon: "images/icon-student-guide-saved.png", onTap: _navigateSaved);
    }
    else {
      return null;
    }
  }

  void _navigateAthletics() {
    Analytics.instance.logSelect(target: "Athletics");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel()));
  }

  void _navigateBussPass() {
    Analytics.instance.logSelect(target: "Buss Pass");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => MTDBusPassPanel()));
  }

  void _navigateDining() {
    Analytics.instance.logSelect(target: "Dinings");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(initialTab: ExploreTab.Dining, showHeaderBack: true,)));
  }

  void _navigateEvents() {
    Analytics.instance.logSelect(target: "Events");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(initialTab: ExploreTab.Events, showHeaderBack: true,)));
  }

  void _navigateGroups() {
    Analytics.instance.logSelect(target: "Groups");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupsHomePanel()));
  }

  void _navigateIlliniCash() {
    Analytics.instance.logSelect(target: "Illini Cash");
    Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
        settings: RouteSettings(name: SettingsIlliniCashPanel.routeName),
        builder: (context){
          return SettingsIlliniCashPanel();
        }
    ));
  }

  void _navigateIlliniId() {
    Analytics.instance.logSelect(target: "Illini ID");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => IDCardPanel()));
  }

  void _navigateLaundry() {
    Analytics.instance.logSelect(target: "Laundry");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryHomePanel()));
  }

  void _navigateLibraryCard() {
    Analytics.instance.logSelect(target: "Library Card");
  }

  void _navigateMealPlan() {
    Analytics.instance.logSelect(target: "Meal Plan");
    Navigator.of(context, rootNavigator: false).push(CupertinoPageRoute(
        builder: (context){
          return SettingsMealPlanPanel();
        }
    ));
  }

  void _navigateMyIllini() {
    Analytics.instance.logSelect(target: "My Illini");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: Config().myIlliniUrl, title: Localization().getStringEx('panel.browse.web_panel.header.schedule_grades_more.title', 'My Illini'),)));
  }

  void _navigateParking() {
    Analytics.instance.logSelect(target: "Parking");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ParkingEventsPanel()));
  }

  void _navigateQuickPolls() {
    Analytics.instance.logSelect(target: "Quick Polls");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PollsHomePanel()));
  }

  void _navigateSaved() {
    Analytics.instance.logSelect(target: "Saved");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SavedPanel()));
  }
}


class StudentGuideFeatureButton extends StatefulWidget {
  final String title;
  final String icon;
  final Function onTap;
  StudentGuideFeatureButton({this.title, this.icon, this.onTap});

  _StudentGuideFeatureButtonState createState() => _StudentGuideFeatureButtonState();
}

class _StudentGuideFeatureButtonState extends State<StudentGuideFeatureButton> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(button: true, child:
      GestureDetector(onTap: widget.onTap ?? _nop, child:
        Container(
          decoration: BoxDecoration(
            color: Styles().colors.white,
            boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ), child:
          Padding(padding: EdgeInsets.symmetric(vertical: 12, horizontal: 6), child:
            Column(children: <Widget>[
              Image.asset(widget.icon, excludeFromSemantics: true,),
              Container(height: 12),
              Row(children: [
                Expanded(child:
                  Text(widget.title, textAlign: TextAlign.center, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.semiBold)),
                ),
              ],)

            ]),
          ),
    ),));
  }


  void _nop() {}
}
