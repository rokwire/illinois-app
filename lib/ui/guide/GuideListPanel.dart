
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/athletics/AthleticsHomePanel.dart';
import 'package:illinois/ui/events2/Event2HomePanel.dart';
import 'package:illinois/ui/wallet/WalletHomePanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Guide.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/SavedPanel.dart';
import 'package:illinois/ui/groups/GroupsHomePanel.dart';
import 'package:illinois/ui/guide/GuideEntryCard.dart';
import 'package:illinois/ui/laundry/LaundryHomePanel.dart';
import 'package:illinois/ui/polls/PollsHomePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class GuideListPanel extends StatefulWidget with AnalyticsInfo {
  final String? guide;
  final String? category;
  final GuideSection? section;
  final List<Map<String, dynamic>>? contentList;
  final String? contentTitle;
  final String? contentEmptyMessage;
  final String favoriteKey;
  final AnalyticsFeature? _analyticsFeature;

  GuideListPanel({ this.guide, this.category, this.section, this.contentList, this.contentTitle, this.contentEmptyMessage, this.favoriteKey = GuideFavorite.favoriteKeyName, AnalyticsFeature? analyticsFeature}) :
    _analyticsFeature = analyticsFeature;

  @override
  _GuideListPanelState createState() => _GuideListPanelState();

  @override
  AnalyticsFeature? get analyticsFeature =>
    _analyticsFeature ??
    AnalyticsFeature.fromName(guide) ??
    AnalyticsFeature.fromName(Guide().listContentType(contentList));

  @override
  Map<String, dynamic> get analyticsPageAttributes {
    return {
      Analytics.LogAttributeGuide : guide,
      Analytics.LogAttributeGuideCategory : category,
      Analytics.LogAttributeGuideSection : section?.name,
    };
  }
}

class _GuideListPanelState extends State<GuideListPanel> with NotificationsListener {

  List<Map<String, dynamic>>? _guideItems = <Map<String, dynamic>>[];
  LinkedHashSet<String>? _features = LinkedHashSet<String>();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Guide.notifyChanged,
      FlexUI.notifyChanged,
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
    if ((name == Guide.notifyChanged) ||
        (name == FlexUI.notifyChanged)) {
      setState(() {
        _buildGuideContent();
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    String? title;
    if (widget.category != null) {
      title = widget.category;
    }
    else if (widget.contentList?.isEmpty ?? true) {
      title = widget.contentTitle;
    }
    
    return Scaffold(
      appBar: HeaderBar(title: title ?? Localization().getStringEx('panel.guide_list.label.highlights.heading', 'Campus Guide')),
      body: Column(children: _buildContent()),
      backgroundColor: Styles().colors.background,
    );
  }

  void _buildGuideContent() {
    if (widget.contentList != null) {
      _guideItems = List.from(widget.contentList!);
    }
    else if ((widget.guide != null) || (widget.category != null) || (widget.section != null)) {
      _guideItems = Guide().getContentList(guide: widget.guide, category: widget.category, section: widget.section);
    }
    else {
      _guideItems = null;
    }

    if (_guideItems != null) {

      _features = LinkedHashSet<String>();
      for (Map<String, dynamic> guideEntry in _guideItems!) {
        List<dynamic>? features = JsonUtils.listValue(Guide().entryValue(guideEntry, 'features'));
        if (features != null) {
          for (dynamic feature in features) {
            if ((feature is String) && !_features!.contains(feature)) {
              _features!.add(feature);
            }
          }
        }
      }
    }
    else {
      _features = null;
    }
  }

  List<Widget> _buildContent() {
    List<Widget> contentList = <Widget>[];

    if ((_guideItems != null) && (0 < _guideItems!.length)) {

      if ((_features != null) && _features!.isNotEmpty) {
        contentList.add(_buildFeatures()!);
      }

      if (widget.section != null) {
        contentList.add(_buildSectionHeading(widget.section!.name));
      }
      else if (widget.contentList != null) {
        contentList.add(_buildSectionHeading(widget.contentTitle));
      }

      List<Widget> cardsList = <Widget>[];
      if (_guideItems != null) {
        for (Map<String, dynamic> guideEntry in _guideItems!) {
          cardsList.add(
            Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16), child:
              GuideEntryCard(guideEntry, favoriteKey: widget.favoriteKey, analyticsFeature: widget._analyticsFeature,)
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
              Text(widget.contentEmptyMessage ?? Localization().getStringEx('panel.guide_list.label.content.empty', 'Empty guide content'), textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.message.regular.fat"))
            ,)
          ),
        ),
      );
    }
    contentList.add(uiuc.TabBar());

    return contentList;
  }

  Widget _buildSectionHeading(String? title) {
    return Container(color: Styles().colors.fillColorPrimary, child:
      Row(children: [
        Expanded(child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
            Semantics(hint: "Heading", child:
              Text(title ?? '', style: Styles().textStyles.getTextStyle("widget.heading.regular.fat"))
            )
          ),
        )
      ],),
    );
  }

  Widget? _buildFeatures() {
    if (_features != null) {
      List<Widget> rowWidgets = <Widget>[];
      List<Widget> colWidgets = <Widget>[];
      for (String feature in _features!) {
        GuideFeatureButton? featureButton = _buildFeatureButton(feature);
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
            Expanded(child: GuideFeatureButton.fromFeature('athletics')),
            Container(width: 6),
            Expanded(child: GuideFeatureButton.fromFeature('events')),
            Container(width: 6),
            Expanded(child: GuideFeatureButton.fromFeature('dining')),
          ],),
          Container(height: 6),
          Row(children: [
            Expanded(child: GuideFeatureButton.fromFeature('laundry')),
            Container(width: 6),
            Expanded(child: GuideFeatureButton.fromFeature('quick-polls')),
            Container(width: 6),
            Expanded(child: Container()),
          ],),
        ],),
      );*/
  }

  GuideFeatureButton? _buildFeatureButton(String feature) {

    List<dynamic> features = JsonUtils.listValue(FlexUI()['campus_guide.features']) ?? [];

    if (feature == 'athletics') {
      return features.contains('athletics') ? GuideFeatureButton(title: Localization().getStringEx("panel.guide_list.button.athletics.title", "Athletics"), iconKey: "guide-athletics", onTap: _navigateAthletics,) : null;
    }
    else if (feature == 'bus-pass') {
      return features.contains('bus_pass') ? GuideFeatureButton(title: Localization().getStringEx("panel.guide_list.button.bus_pass.title", "Bus Pass"), iconKey: "guide-bus-pass", onTap: _navigateBusPass,) : null;
    }
    else if (feature == 'dining') {
      return features.contains('dining') ? GuideFeatureButton(title: Localization().getStringEx("panel.guide_list.button.dining.title", "Dining"), iconKey: "guide-dining", onTap: _navigateDining) : null;
    }
    else if (feature == 'events') {
      return features.contains('events') ? GuideFeatureButton(title: Localization().getStringEx("panel.guide_list.button.events.title", "Events"), iconKey: "guide-events", onTap: _navigateEvents) : null;
    }
    else if (feature == 'groups') {
      return features.contains('groups') ? GuideFeatureButton(title: Localization().getStringEx("panel.guide_list.button.groups.title", "Groups"), iconKey: "guide-groups", onTap: _navigateGroups) : null;
    }
    else if (feature == 'illini-cash') {
      return features.contains('illini_cash') ? GuideFeatureButton(title: Localization().getStringEx("panel.guide_list.button.illini_cash.title", "Illini Cash"), iconKey: "guide-student-cash", onTap: _navigateIlliniCash) : null;
    }
    else if (feature == 'illini-id') {
      return features.contains('illini_id') ? GuideFeatureButton(title: Localization().getStringEx("panel.guide_list.button.illini_id.title", "Illini ID"), iconKey: "guide-student-id", onTap: _navigateIlliniId) : null;
    }
    else if (feature == 'laundry') {
      return features.contains('laundry') ? GuideFeatureButton(title: Localization().getStringEx("panel.guide_list.button.laundry.title", "Laundry"), iconKey: "guide-laundry", onTap: _navigateLaundry,) : null;
    }
    else if (feature == 'meal-plan') {
      return features.contains('meal_plan') ? GuideFeatureButton(title: Localization().getStringEx("panel.guide_list.button.meal_plan.title", "Meal Plan"), iconKey: "guide-meal-plan", onTap: _navigateMealPlan,) : null;
    }
    else if (feature == 'my-illini') {
      return features.contains('my_illini') ? GuideFeatureButton(title: Localization().getStringEx("panel.guide_list.button.my_illini.title", "My Illini"), iconKey: "guide-student-portal", onTap: _navigateMyIllini) : null;
    }
    else if (feature == 'quick-polls') {
      return features.contains('quick_polls') ? GuideFeatureButton(title: Localization().getStringEx("panel.guide_list.button.quick_polls.title", "Quick Polls"), iconKey: "guide-polls", onTap: _navigateQuickPolls) : null;
    }
    else if (feature == 'saved') {
      return features.contains('saved') ? GuideFeatureButton(title: Localization().getStringEx("panel.guide_list.button.saved.title", "Saved"), iconKey: "guide-saved", onTap: _navigateSaved) : null;
    }
    else if (feature == 'library-card') {
      return features.contains('saved') ? GuideFeatureButton(title: Localization().getStringEx("panel.guide_list.button.library_card.title", "Library Card"), iconKey: "guide-library-card", onTap: _navigateLibraryCard) : null;
    }
    else if (feature == 'parking') {
      return null; // We do not support parking any more
    }
    else {
      return null;
    }
  }

  void _navigateAthletics() {
    Analytics().logSelect(target: "Athletics");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel(contentType: AthleticsContentType.events)));
  }

  void _navigateBusPass() {
    Analytics().logSelect(target: "Bus Pass");
    WalletHomePanel.present(context, contentType: WalletContentType.busPass);
  }

  void _navigateDining() {
    Analytics().logSelect(target: "Dining");
    Event2HomePanel.present(context);
  }

  void _navigateEvents() {
    Analytics().logSelect(target: "Events");
    Event2HomePanel.present(context);
  }

  void _navigateGroups() {
    Analytics().logSelect(target: "Groups");
    Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: GroupsHomePanel.routeName), builder: (context) => GroupsHomePanel()));
  }

  void _navigateIlliniCash() {
    Analytics().logSelect(target: "Illini Cash");
    WalletHomePanel.present(context, contentType: WalletContentType.illiniCash);
  }

  void _navigateIlliniId() {
    Analytics().logSelect(target: "Illini ID");
    WalletHomePanel.present(context, contentType: WalletContentType.illiniId);
  }

  void _navigateLaundry() {
    Analytics().logSelect(target: "Laundry");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryHomePanel()));
  }

  void _navigateMealPlan() {
    Analytics().logSelect(target: "Meal Plan");
    WalletHomePanel.present(context, contentType: WalletContentType.mealPlan);
  }

  void _navigateMyIllini() {
    Analytics().logSelect(target: "My Illini");
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.my_illini', 'My Illini not available while offline.'));
    }
    else if (StringUtils.isNotEmpty(Config().myIlliniUrl)) {
      Uri? uri = Uri.tryParse(Config().myIlliniUrl!);
      if (uri != null) {
        launchUrl(uri);
      }
    }
  }

  void _navigateQuickPolls() {
    Analytics().logSelect(target: "Quick Polls");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PollsHomePanel()));
  }

  void _navigateSaved() {
    Analytics().logSelect(target: "Saved");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SavedPanel()));
  }

  void _navigateLibraryCard() {
    Analytics().logSelect(target: "Library Card");
    WalletHomePanel.present(context, contentType: WalletContentType.libraryCard);
  }
}


class GuideFeatureButton extends StatefulWidget {
  final String? title;
  final String? iconKey;
  final void Function()? onTap;
  GuideFeatureButton({this.title, this.iconKey, this.onTap});

  _GuideFeatureButtonState createState() => _GuideFeatureButtonState();
}

class _GuideFeatureButtonState extends State<GuideFeatureButton> {

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
              Styles().images.getImage(widget.iconKey, excludeFromSemantics: true) ?? Container(),
              Container(height: 12),
              Row(children: [
                Expanded(child:
                  Text(widget.title!, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.title.regular.semi_fat")),
                ),
              ],)

            ]),
          ),
    ),));
  }


  void _nop() {}
}
