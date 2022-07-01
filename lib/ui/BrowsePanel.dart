import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/SavedPanel.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/athletics/AthleticsHomePanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsListPanel.dart';
import 'package:illinois/ui/athletics/AthleticsTeamsPanel.dart';
import 'package:illinois/ui/canvas/CanvasCoursesListPanel.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/gies/CheckListPanel.dart';
import 'package:illinois/ui/groups/GroupsHomePanel.dart';
import 'package:illinois/ui/guide/CampusGuidePanel.dart';
import 'package:illinois/ui/guide/GuideListPanel.dart';
import 'package:illinois/ui/home/HomeCampusResourcesWidget.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeRecentItemsWidget.dart';
import 'package:illinois/ui/home/HomeSaferTestLocationsPanel.dart';
import 'package:illinois/ui/home/HomeSaferWellnessAnswerCenterPanel.dart';
import 'package:illinois/ui/home/HomeTwitterWidget.dart';
import 'package:illinois/ui/home/HomeWPGUFMRadioWidget.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/laundry/LaundryHomePanel.dart';
import 'package:illinois/ui/parking/ParkingEventsPanel.dart';
import 'package:illinois/ui/polls/CreatePollPanel.dart';
import 'package:illinois/ui/polls/CreateStadiumPollPanel.dart';
import 'package:illinois/ui/polls/PollsHomePanel.dart';
import 'package:illinois/ui/settings/SettingsIlliniCashPanel.dart';
import 'package:illinois/ui/settings/SettingsMealPlanPanel.dart';
import 'package:illinois/ui/settings/SettingsNotificationsContentPanel.dart';
import 'package:illinois/ui/settings/SettingsVideoTutorialPanel.dart';
import 'package:illinois/ui/wallet/IDCardPanel.dart';
import 'package:illinois/ui/wallet/MTDBusPassPanel.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class BrowsePanel extends StatefulWidget {

  static const String notifyRefresh      = "edu.illinois.rokwire.browse.refresh";

  BrowsePanel();

  @override
  _BrowsePanelState createState() => _BrowsePanelState();
}

class _BrowsePanelState extends State<BrowsePanel> with AutomaticKeepAliveClientMixin<BrowsePanel> implements NotificationsListener {

  List<String>? _contentCodes;
  Set<String> _expandedCodes = <String>{};
  StreamController<String> _updateController = StreamController.broadcast();

  @override
  void initState() {
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      Localization.notifyStringsUpdated,
      Styles.notifyChanged,
    ]);
    
    _contentCodes = JsonUtils.listStringsValue(FlexUI()['browse']);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _updateController.close();
    super.dispose();
  }

  // AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;


  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _updateContentCodes();
    } 
    else if((name == Auth2UserPrefs.notifyFavoritesChanged) ||
      (name == Localization.notifyStringsUpdated) ||
      (name == Styles.notifyChanged))
    {
      if (mounted) {
        setState(() { });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.browse.label.title', 'Browse')),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child:
        Column(children: <Widget>[
          Expanded(child:
            SingleChildScrollView(child:
              Column(children: _buildContentList(),)
            )
          ),
        ]),
      ),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: null,
    );
  }

  List<Widget> _buildContentList() {
    List<Widget> contentList = <Widget>[];

    contentList.add(_BrowseToutWidget(updateController: _updateController,));

    List<Widget> sectionsList = <Widget>[];
    if (_contentCodes != null) {
      for (String code in _contentCodes!) {
        sectionsList.add((code == _BrowseCampusResourcesSection.contentCode) ?
          _BrowseCampusResourcesSection(
            expanded: _isExpanded(code),
            onExpand: () => _toggleExpanded(code),) :
          _BrowseSection(
            sectionId: code,
            expanded: _isExpanded(code),
            onExpand: () => _toggleExpanded(code),)
        );
      }
    }

    if (sectionsList.isNotEmpty) {
      contentList.add(
        HomeSlantWidget(
          title: Localization().getStringEx('panel.browse.label.sections.title', 'App Sections'),
          titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
          child: Column(children: sectionsList,),
        )    
      );
    }
    
    return contentList;
  }

  void _updateContentCodes() {
    List<String>?  contentCodes = JsonUtils.listStringsValue(FlexUI()['browse']);
    if ((contentCodes != null) && !DeepCollectionEquality().equals(_contentCodes, contentCodes)) {
      if (mounted) {
        setState(() {
          _contentCodes = contentCodes;
        });
      }
      else {
        _contentCodes = contentCodes;
      }
    }
  }

  bool _isExpanded(String sectionId) => _expandedCodes.contains(sectionId);

  void _toggleExpanded(String sectionId) {
    if (mounted) {
      setState(() {
        if (_expandedCodes.contains(sectionId)) {
          _expandedCodes.remove(sectionId);
        }
        else {
          _expandedCodes.add(sectionId);
        }
      });
    }
  }
  
  Future<void> _onPullToRefresh() async {
    _updateController.add(BrowsePanel.notifyRefresh);
    if (mounted) {
      setState(() {});
    }
  }
}

class _BrowseSection extends StatelessWidget {

  final String sectionId;
  final bool expanded;
  final void Function()? onExpand;
  final List<String>? _browseEntriesCodes;
  final Set<String>? _homeSectionEntriesCodes;
  final Set<String>? _homeRootEntriesCodes;

  _BrowseSection({Key? key, required this.sectionId, this.expanded = false, this.onExpand}) :
    _browseEntriesCodes = JsonUtils.listStringsValue(FlexUI()['browse.$sectionId']),
    _homeSectionEntriesCodes = JsonUtils.setStringsValue(FlexUI().contentSourceEntry('home.$sectionId')),
    _homeRootEntriesCodes = JsonUtils.setStringsValue(FlexUI().contentSourceEntry('home')),
    super(key: key);

  HomeFavorite? _favorite(String code) {
    if (_homeSectionEntriesCodes?.contains(code) ?? false) {
      return HomeFavorite(code, category: sectionId);
    }
    else if (_homeRootEntriesCodes?.contains(code) ?? false) {
      return HomeFavorite(code);
    }
    else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[];
    contentList.add(_buildHeading(context));
    contentList.add(_buildEntries(context));
    return Column(children: contentList,);
  }

  Widget _buildHeading(BuildContext context) {
    return Padding(padding: EdgeInsets.only(bottom: 4), child:
      InkWell(onTap: _onTapExpand, child:
        Container(
          decoration: BoxDecoration(color: Styles().colors?.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),),
          padding: EdgeInsets.only(left: 16),
          child: Column(children: [
            Row(children: [
              Expanded(child:
                Padding(padding: EdgeInsets.only(top: 16), child:
                  Text(_title, style: TextStyle(fontFamily: Styles().fontFamilies?.extraBold, fontSize: 20, color: Styles().colors!.fillColorPrimary))
                )
              ),
              Opacity(opacity: _hasBrowseContent ? 1 : 0, child:
                Semantics(label: 'Favorite' /* TBD: Localization */, button: true, child:
                  InkWell(onTap: () => _onTapSectionFavorite(context), child:
                    FavoriteStarIcon(selected: _isSectionFavorite, style: FavoriteIconStyle.Button,)
                  ),
                ),
              ),
            ],),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child:
                Padding(padding: EdgeInsets.only(bottom: 16), child:
                  Text(_description, style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textSurface))
                )
              ),
              Semantics(
                label: expanded ? Localization().getStringEx('panel.browse.section.status.colapse.title', 'Colapse') : Localization().getStringEx('panel.browse.section.status.expand.title', 'Expand'),
                hint: expanded ? Localization().getStringEx('panel.browse.section.status.colapse.hint', 'Tap to colapse section content') : Localization().getStringEx('panel.browse.section.status.expand.hint', 'Tap to expand section content'),
                button: true, child:
                  Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
                    SizedBox(width: 18, height: 18, child:
                      Center(child:
                        _hasBrowseContent ? (
                          expanded ?
                            Image.asset('images/arrow-up-orange.png', excludeFromSemantics: true) :
                            Image.asset('images/arrow-down-orange.png', excludeFromSemantics: true)
                        ) : Container()
                      ),
                    )
                  ),
              ),
            ],)
          ],)
        ),
      ),
    );
  }

  Widget _buildEntries(BuildContext context) {
      List<Widget> entriesList = <Widget>[];
      if (expanded && (_browseEntriesCodes != null)) {
        for (String code in _browseEntriesCodes!) {
          entriesList.add(_BrowseEntry(
            sectionId: sectionId,
            entryId: code,
            favorite: _favorite(code),
          ));
        }
      }
      return entriesList.isNotEmpty ? Padding(padding: EdgeInsets.only(left: 24), child:
        Column(children: entriesList,)
      ) : Container();
  }

  String get _title => Localization().getStringEx('panel.browse.section.$sectionId.title', StringUtils.capitalize(sectionId, allWords: true, splitDelimiter: '_', joinDelimiter: ' '));
  String get _description => Localization().getStringEx('panel.browse.section.$sectionId.description', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit est et ante maximus.');

  void _onTapExpand() {
    if (_hasBrowseContent && (onExpand != null)) {
      onExpand!();
    }
  }

  bool get _hasBrowseContent => _browseEntriesCodes?.isNotEmpty ?? false;

  bool? get _isSectionFavorite {
    int favCount = 0, unfavCount = 0, totalCount = 0;
    if (_browseEntriesCodes?.isNotEmpty ?? false) {
      for (String code in _browseEntriesCodes!) {
        HomeFavorite? entryFavorite = _favorite(code);
        if (entryFavorite != null) {
          totalCount++;
          if (Auth2().prefs?.isFavorite(entryFavorite) ?? false) {
            favCount++;
          }
          else {
            unfavCount++;
          }
        }
      }
      if ((favCount == totalCount)) {
        return true;
      }
      else if (unfavCount == totalCount) {
        return false;
      }
    }
    return null;
  }

  void _onTapSectionFavorite(BuildContext context) {
    Analytics().logSelect(target: "Favorite: $sectionId");
    if (kReleaseMode) {
      promptSectionFavorite(context).then((bool? result) {
        if (result == true) {
          _toggleSectionFavorite();
        }
      });
    }
    else {
      _toggleSectionFavorite();
    }
  }

  void _toggleSectionFavorite() {
    Auth2().prefs?.setListFavorite(sectionFavorites, _isSectionFavorite != true);
  }

  List<Favorite> get sectionFavorites {
    List<Favorite> favorites = <Favorite>[];

    if (_browseEntriesCodes != null) {
      for(String code in _browseEntriesCodes!.reversed) {
        HomeFavorite? entryFavorite = _favorite(code);
        if (entryFavorite != null) {
          favorites.add(entryFavorite);
        }
      }
    }

    if ((_homeSectionEntriesCodes != null) && (_homeRootEntriesCodes?.contains(sectionId) ?? false)) {
      favorites.add(HomeFavorite(sectionId));
    }
    return favorites;
  }

  Future<bool?> promptSectionFavorite(BuildContext context) async {
    String message = (_isSectionFavorite != true) ?
      Localization().getStringEx('panel.browse.prompt.add.all.favorites', 'Are you sure you want to ADD ALL items to your favorites?') :
      Localization().getStringEx('panel.browse.prompt.remove.all.favorites', 'Are you sure you want to REMOVE ALL items from your favorites?');
    return await showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        content: Text(message),
        actions: <Widget>[
          TextButton(child: Text(Localization().getStringEx("dialog.yes.title", "Yes")),
            onPressed:(){
              Analytics().logAlert(text: message, selection: "Yes");
              Navigator.pop(context, true);
            }),
          TextButton(child: Text(Localization().getStringEx("dialog.no.title", "No")),
            onPressed:(){
              Analytics().logAlert(text: message, selection: "No");
              Navigator.pop(context, false);
            }),
        ]
      );
    });
  }
}

class _BrowseEntry extends StatelessWidget {

  final String sectionId;
  final String entryId;
  final HomeFavorite? favorite;

  _BrowseEntry({required this.sectionId, required this.entryId, this.favorite});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(bottom: 4), child:
      InkWell(onTap: () => _onTap(context), child:
        Container(
          decoration: BoxDecoration(color: Styles().colors?.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),),
          padding: EdgeInsets.zero,
          child: 
            Row(children: [
              Opacity(opacity: (favorite != null) ? 1 : 0, child:
                HomeFavoriteButton(favorite: favorite, style: FavoriteIconStyle.Button, prompt: true,),
              ),
              Expanded(child:
                Padding(padding: EdgeInsets.symmetric(vertical: 14), child:
                  Text(_title, style: TextStyle(fontFamily: Styles().fontFamilies?.extraBold, fontSize: 20, color: Styles().colors!.fillColorPrimary)),
                ),
              ),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18), child:
                Image.asset('images/chevron-right.png'),
              ),
            ],),
        ),
      ),
    );
  }

  String get _title => Localization().getStringEx('panel.browse.entry.$sectionId.$entryId.title', StringUtils.capitalize(entryId, allWords: true, splitDelimiter: '_', joinDelimiter: ' '));

  void _onTap(BuildContext context) {
    switch("$sectionId.$entryId") {
      case "academics.gies_checklist":        _onTapGiesChecklist(context); break;
      case "academics.new_student_checklist": _onTapNewStudentChecklist(context); break;
      case "academics.canvas_courses":        _onTapCanvasCourses(context); break;
      case "academics.my_illini":             _onTapMyIllini(context); break;
      case "academics.campus_reminders":      _onTapCampusReminders(context); break;

      case "app_help.video_tutorial":        _onTapVideoTutorial(context); break;
      case "app_help.feedback":              _onTapFeedback(context); break;
      case "app_help.faqs":                  _onTapFAQs(context); break;

      case "athletics.sport_events":         _onTapSportEvents(context); break;
      case "athletics.sport_news":           _onTapSportNews(context); break;
      case "athletics.sport_teams":          _onTapSportTeams(context); break;

      case "safer.building_access":          _onTapBuildingAccess(context); break;
      case "safer.test_locations":           _onTapTestLocations(context); break;
      case "safer.my_mckinley":              _onTapMyMcKinley(context); break;
      case "safer.wellness_answer_center":   _onTapWellnessAnswerCenter(context); break;

      case "campus_guide.campus_highlights": _onTapCampusHighlights(context); break;
      case "campus_guide.campus_guide":      _onTapCampusGuide(context); break;

      case "campus_links.due_date_catalog":  _onTapDueDateCatalog(context); break;

      case "dinings.dinings_all":            _onTapDiningsAll(context); break;
      case "dinings.dinings_open":           _onTapDiningsOpen(context); break;

      case "campus_resources.events":       _onTapEvents(context); break;
      case "campus_resources.dining":       _onTapDining(context); break;
      case "campus_resources.athletics":    _onTapAthletics(context); break;
      case "campus_resources.laundry":      _onTapLaundry(context); break;
      case "campus_resources.illini_cash":  _onTapIlliniCash(context); break;
      case "campus_resources.my_illini":    _onTapMyIllini(context); break;
      case "campus_resources.wellness":     _onTapWellness(context); break;
      case "campus_resources.crisis_help":  _onTapCrisisHelp(context); break;
      case "campus_resources.groups":       _onTapGroups(context); break;
      case "campus_resources.quick_polls":  _onTapQuickPolls(context); break;
      case "campus_resources.campus_guide": _onTapCampusGuide(context); break;
      case "campus_resources.inbox":        _onTapInbox(context); break;

      case "events.suggested_events": _onTapSuggestedEvents(context); break;

      case "feeds.twitter":      _onTapTwitter(context); break;
      case "feeds.wpgufm_radio": _onTapWPGUFMRadio(context); break;

      case "groups.all_groups":  _onTapAllGroups(context); break;
      case "groups.my_groups":   _onTapMyGroups(context); break;

      case "my.my_groups":       _onTapMyGroups(context); break;
      case "my.my_game_day":     _onTapMyGameDay(context); break;
      case "my.my_events":       _onTapMyEvents(context); break;
      case "my.my_dining":       _onTapMyDinings(context); break;
      case "my.my_athletics":    _onTapMyAthletics(context); break;
      case "my.my_news":         _onTapMyNews(context); break;
      case "my.my_laundry":      _onTapMyLaundry(context); break;
      case "my.my_inbox":        _onTapMyNotifications(context); break;
      case "my.my_campus_guide": _onTapMyCampusGuide(context); break;
      case "my.wellness_resources": _onTapWellnessResources(context); break;

      case "polls.create_poll":  _onTapCreatePoll(context); break;
      case "polls.recent_polls":   _onTapViewPolls(context); break;

      case "recent.recent_items": _onTapRecentItems(context); break;

      case "state_farm_center.parking":             _onTapParking(context); break;
      case "state_farm_center.wayfinding":          _onTapStateFarmWayfinding(context); break;
      case "state_farm_center.create_stadium_poll": _onTapCreateStadiumPoll(context); break;

      case "wallet.illini_cash_card": _onTapIlliniCash(context); break;
      case "wallet.meal_plan_card":   _onTapMealPlan(context); break;
      case "wallet.bus_pass_card":    _onTapBusPass(context); break;
      case "wallet.illini_id_card":   _onTapIlliniId(context); break;
      case "wallet.library_card":     _onTapLibraryCard(context); break;

      case "wellness.rings": _onTapWellnessRings(context); break;
      case "wellness.todo":  _onTapWellnessToDo(context); break;
      case "wellness.tips":  _onTapWellnessTips(context); break;
      case "wellness.wellness_resources": _onTapWellnessResources(context); break;
    }
  }

  void _onTapGiesChecklist(BuildContext context) {
    Analytics().logSelect(target: "Gies Checklist");
    CheckListPanel.present(context, contentKey: 'gies');
  }

  void _onTapNewStudentChecklist(BuildContext context) {
    Analytics().logSelect(target: "New Student Checklist");
    CheckListPanel.present(context, contentKey: 'new_student');
  }

  void _onTapCanvasCourses(BuildContext context) {
    Analytics().logSelect(target: "Canvas Course");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCoursesListPanel()));
  }

  void _onTapMyIllini(BuildContext context) {
    Analytics().logSelect(target: "My Illini");
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.my_illini', 'My Illini not available while offline.'));
    }
    else if (StringUtils.isNotEmpty(Config().myIlliniUrl)) {

      // Please make this use an external browser
      // Ref: https://github.com/rokwire/illinois-app/issues/1110
      launch(Config().myIlliniUrl!);

      //
      // Until webview_flutter get fixed for the dropdowns we will continue using it as a webview plugin,
      // but we will open in an external browser all problematic pages.
      // The other plugin doesn't work with VoiceOver
      // Ref: https://github.com/rokwire/illinois-client/issues/284
      //      https://github.com/flutter/plugins/pull/2330
      //
      // if (Platform.isAndroid) {
      //   launch(Config().myIlliniUrl);
      // }
      // else {
      //   String myIlliniPanelTitle = Localization().getStringEx(
      //       'widget.home.campus_resources.header.my_illini.title', 'My Illini');
      //   Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: Config().myIlliniUrl, title: myIlliniPanelTitle,)));
      // }
    }
  }

  void _onTapCampusReminders(BuildContext context) {
    Analytics().logSelect(target: "Campus Reminders");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(contentList: Guide().remindersList, contentTitle: Localization().getStringEx('panel.guide_list.label.campus_reminders.section', 'Campus Reminders'))));
  }

  bool get _canVideoTutorial => StringUtils.isNotEmpty(Config().videoTutorialUrl);

  void _onTapVideoTutorial(BuildContext context) {
    Analytics().logSelect(target: "Video Tutorial");
    
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.video_tutorial', 'Video Tutorial not available while offline.'));
    }
    else if (_canVideoTutorial) {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) => SettingsVideoTutorialPanel()));
    }
  }

  bool get _canFeedback => StringUtils.isNotEmpty(Config().feedbackUrl);

  void _onTapFeedback(BuildContext context) {
    Analytics().logSelect(target: "Provide Feedback");

    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('widgets.home.app_help.feedback.label.offline', 'Providing a Feedback is not available while offline.'));
    }
    else if (_canFeedback) {
      String email = Uri.encodeComponent(Auth2().email ?? '');
      String name =  Uri.encodeComponent(Auth2().fullName ?? '');
      String phone = Uri.encodeComponent(Auth2().phone ?? '');
      String feedbackUrl = "${Config().feedbackUrl}?email=$email&phone=$phone&name=$name";

      String? panelTitle = Localization().getStringEx('widgets.home.app_help.feedback.panel.title', 'PROVIDE FEEDBACK');
      Navigator.push(
          context, CupertinoPageRoute(builder: (context) => WebPanel(url: feedbackUrl, title: panelTitle,)));
    }
  }

  bool get _canFAQs => StringUtils.isNotEmpty(Config().faqsUrl);

  void _onTapFAQs(BuildContext context) {
    Analytics().logSelect(target: "FAQs");

    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.faqs', 'FAQs is not available while offline.'));
    }
    else if (_canFAQs) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(
        url: Config().faqsUrl,
        title: Localization().getStringEx('panel.settings.faqs.label.title', 'FAQs'),
      )));
    }
  }

  void _onTapSportEvents(BuildContext context) {
    Analytics().logSelect(target: "Athletics Events");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(initialItem: ExploreItem.Events, initialFilter: ExploreFilter(type: ExploreFilterType.categories, selectedIndexes: {3}))));
  }

  void _onTapSportNews(BuildContext context) {
    Analytics().logSelect(target: "Athletics News");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsNewsListPanel()));
  }

  void _onTapSportTeams(BuildContext context) {
    Analytics().logSelect(target: "Athletics Teams");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsTeamsPanel()));
  }

  void _onTapBuildingAccess(BuildContext context) {
    Analytics().logSelect(target: 'Building Access');
    IDCardPanel.present(context);
  }
  
  void _onTapTestLocations(BuildContext context) {
    Analytics().logSelect(target: 'Locations');
    Navigator.push(context, CupertinoPageRoute(
      builder: (context) => HomeSaferTestLocationsPanel()
    ));
  }

  void _onTapMyMcKinley(BuildContext context) {
    Analytics().logSelect(target: 'MyMcKinley');
    if (StringUtils.isNotEmpty(Config().saferMcKinley['url'])) {
      launch(Config().saferMcKinley['url']);
    }
  }

  void _onTapWellnessAnswerCenter(BuildContext context) {
    Analytics().logSelect(target: 'Answer Center');
    Navigator.push(context, CupertinoPageRoute(
      builder: (context) => HomeSaferWellnessAnswerCenterPanel()
    ));
  }

  void _onTapCampusHighlights(BuildContext context) {
    Analytics().logSelect(target: 'Campus Highlights');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(contentList: Guide().promotedList, contentTitle: Localization().getStringEx('panel.guide_list.label.highlights.section', 'Highlights'))));
  }

  bool get _canDueDateCatalog => StringUtils.isNotEmpty(Config().dateCatalogUrl);

  void _onTapDueDateCatalog(BuildContext context) {
    Analytics().logSelect(target: "Due Date Catalog");
    
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.date_cat', 'Due Date Catalog not available while offline.'));
    }
    else if (_canDueDateCatalog) {
      launch(Config().dateCatalogUrl!);
    }
  }

  void _onTapDiningsAll(BuildContext context) {
    Analytics().logSelect(target: "HomeDiningWidget: Residence Hall Dining");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(initialItem: ExploreItem.Dining) ));
  }

  void _onTapDiningsOpen(BuildContext context) {
    Analytics().logSelect(target: "HomeDiningWidget: Residence Hall Dining Open Now");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(initialItem: ExploreItem.Dining, initialFilter: ExploreFilter(type: ExploreFilterType.work_time, selectedIndexes: {1}))));
  }

  void _onTapEvents(BuildContext context) {
    Analytics().logSelect(target: "Events");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return ExplorePanel(initialItem: ExploreItem.Events); } ));
  }
    
  void _onTapDining(BuildContext context) {
    Analytics().logSelect(target: "Dining");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return ExplorePanel(initialItem: ExploreItem.Dining); } ));
  }

  void _onTapAthletics(BuildContext context) {
    Analytics().logSelect(target: "Athletics");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel()));
  }

  void _onTapLaundry(BuildContext context) {
    Analytics().logSelect(target: "Laundry");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryHomePanel()));
  }

  void _onTapIlliniCash(BuildContext context) {
    Analytics().logSelect(target: "Illini Cash");
    SettingsIlliniCashPanel.present(context);
  }

  void _onTapWellness(BuildContext context) {
    Analytics().logSelect(target: "Wellness");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel()));
  }

  void _onTapCrisisHelp(BuildContext context) {
    Analytics().logSelect(target: "Crisis Help");
    String? url = Config().crisisHelpUrl;
    if (StringUtils.isNotEmpty(url)) {
      launch(url!);
    } else {
      debugPrint("Missing Config().crisisHelpUrl");
    }
  }

  void _onTapGroups(BuildContext context) {
    Analytics().logSelect(target: "Groups");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupsHomePanel()));
  }

  void _onTapQuickPolls(BuildContext context) {
    Analytics().logSelect(target: "Quick Polls");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PollsHomePanel()));
  }

  void _onTapCampusGuide(BuildContext context) {
    Analytics().logSelect(target: "Campus Guide");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CampusGuidePanel()));
  }

  void _onTapInbox(BuildContext context) {
    Analytics().logSelect(target: "Inbox");
    SettingsNotificationsContentPanel.present(context, content: SettingsNotificationsContent.inbox);
  }

  void _onTapSuggestedEvents(BuildContext context) {
    Analytics().logSelect(target: "Suggested Events");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return ExplorePanel(initialItem: ExploreItem.Events); } ));
  }

  void _onTapTwitter(BuildContext context) {
    Analytics().logSelect(target: "Twitter");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return TwitterPanel(); } ));
  }

  void _onTapWPGUFMRadio(BuildContext context) {
    Analytics().logSelect(target: "WPGU FM Radio");
    HomeWPGUFMRadioWidget.showPopup(context);
  }

  void _onTapAllGroups(BuildContext context) {
    Analytics().logSelect(target: "All Groups");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupsHomePanel(contentType: GroupsContentType.all,)));
  }

  void _onTapMyGroups(BuildContext context) {
    Analytics().logSelect(target: "My Groups");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupsHomePanel(contentType: GroupsContentType.my)));
  }

  void _onTapMyGameDay(BuildContext context) {
    Analytics().logSelect(target: "My Game Day");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel()));
  }

  void _onTapMyEvents(BuildContext context) {
    Analytics().logSelect(target: "My Events");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return SavedPanel(favoriteCategories: [Event.favoriteKeyName]); } ));
  }

  void _onTapMyDinings(BuildContext context) {
    Analytics().logSelect(target: "My Dinings");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return SavedPanel(favoriteCategories: [Dining.favoriteKeyName]); } ));
  }

  void _onTapMyAthletics(BuildContext context) {
    Analytics().logSelect(target: "My Athletics");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return SavedPanel(favoriteCategories: [Game.favoriteKeyName]); } ));
  }

  void _onTapMyNews(BuildContext context) {
    Analytics().logSelect(target: "My News");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return SavedPanel(favoriteCategories: [News.favoriteKeyName]); } ));
  }

  void _onTapMyLaundry(BuildContext context) {
    Analytics().logSelect(target: "My Laundry");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return SavedPanel(favoriteCategories: [LaundryRoom.favoriteKeyName]); } ));
  }

  void _onTapMyNotifications(BuildContext context) {
    Analytics().logSelect(target: "My Notifications");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return SavedPanel(favoriteCategories: [InboxMessage.favoriteKeyName]); } ));
  }

  void _onTapMyCampusGuide(BuildContext context) {
    Analytics().logSelect(target: "My Campus Guide");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return SavedPanel(favoriteCategories: [GuideFavorite.favoriteKeyName]); } ));
  }

  void _onTapWellnessResources(BuildContext context) {
    Analytics().logSelect(target: "Wellness Resources");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return WellnessHomePanel(content: WellnessContent.resources,); } ));
  }

  void _onTapCreatePoll(BuildContext context) {
    Analytics().logSelect(target: "Create Poll");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CreatePollPanel()));
  }

  void _onTapViewPolls(BuildContext context) {
    Analytics().logSelect(target: "View Polls");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PollsHomePanel()));
  }

  void _onTapRecentItems(BuildContext context) {
    Analytics().logSelect(target: "Recent Items");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => HomeRecentItemsPanel()));
  }

  void _onTapParking(BuildContext context) {
    Analytics().logSelect(target: "Parking");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ParkingEventsPanel()));
  }

  void _onTapStateFarmWayfinding(BuildContext context) {
    Analytics().logSelect(target: "State Farm Wayfinding");
    NativeCommunicator().launchMap(target: {
      'latitude': Config().stateFarmWayfinding['latitude'],
      'longitude': Config().stateFarmWayfinding['longitude'],
      'zoom': Config().stateFarmWayfinding['zoom'],
    });
  }

  void _onTapCreateStadiumPoll(BuildContext context) {
    Analytics().logSelect(target: "Create Stadium Poll");
    CreateStadiumPollPanel.present(context);
  }

  void _onTapMealPlan(BuildContext context) {
    Analytics().logSelect(target: "Meal Plan");
    SettingsMealPlanPanel.present(context);
  }

  void _onTapBusPass(BuildContext context) {
    Analytics().logSelect(target: "Bus Pass");
    MTDBusPassPanel.present(context);
  }

  void _onTapIlliniId(BuildContext context) {
    Analytics().logSelect(target: "Illini ID");
    IDCardPanel.present(context);
  }

  void _onTapLibraryCard(BuildContext context) {
    Analytics().logSelect(target: "Library Card");
    _notImplemented(context);
  }

  void _onTapWellnessRings(BuildContext context) {
    Analytics().logSelect(target: "Wellness Rings");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(content: WellnessContent.rings,)));
  }

  void _onTapWellnessToDo(BuildContext context) {
    Analytics().logSelect(target: "Wellness To Do");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(content: WellnessContent.todo,)));
  }

  void _onTapWellnessTips(BuildContext context) {
    Analytics().logSelect(target: "Wellness Daily Tips");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(content: WellnessContent.dailyTips,)));
  }

  void _notImplemented(BuildContext context) {
    AppAlert.showDialogResult(context, "Not implemented yet.");
  }

}

class _BrowseCampusResourcesSection extends _BrowseSection {

  static const String contentCode = 'campus_resources';

  _BrowseCampusResourcesSection({Key? key, bool expanded = false, void Function()? onExpand}) :
    super(key: key, sectionId: contentCode, expanded: expanded, onExpand: onExpand);

  @override
  Widget _buildEntries(BuildContext context) {
    return (expanded && (_browseEntriesCodes?.isNotEmpty ?? false)) ?
      Padding(padding: EdgeInsets.only(left: 16, bottom: 4), child:
        HomeCampusResourcesGridWidget(favoriteCategory: contentCode, contentCodes: _browseEntriesCodes!, promptFavorite: kReleaseMode,)
      ) :
      Container();
  }
}

class _BrowseToutWidget extends StatefulWidget {

  final StreamController<String>? updateController;

  _BrowseToutWidget({Key? key, this.updateController}) : super(key: key);

  @override
  State<_BrowseToutWidget> createState() => _BrowseToutWidgetState();
}

class _BrowseToutWidgetState extends State<_BrowseToutWidget> implements NotificationsListener {

  String? _imageUrl;
  DateTime? _imageDateTime;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
    ]);

    widget.updateController?.stream.listen((String command) {
      if (command == BrowsePanel.notifyRefresh) {
        _refresh();
      }
    });

    _imageUrl = Storage().browseToutImageUrl;
    _imageDateTime = DateTime.fromMillisecondsSinceEpoch(Storage().browseToutImageTime ?? 0);
    if (_shouldUpdateImage) {
      _updateImage();
    }
 
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return (_imageUrl != null) ? Stack(children: [
      Image.network(_imageUrl!, semanticLabel: 'tout', loadingBuilder:(  BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
        double imageWidth = MediaQuery.of(context).size.width;
        double imageHeight = imageWidth * 810 / 1080;
        return (loadingProgress != null) ? Container(color: Styles().colors?.fillColorPrimary, width: imageWidth, height: imageHeight, child:
          Center(child:
            CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors?.white), ) 
          ),
        ) : child;
      }),
      Positioned.fill(child:
        Align(alignment: Alignment.bottomCenter, child:
          Column(mainAxisSize: MainAxisSize.min, children: [
            CustomPaint(painter: TrianglePainter(painterColor: Styles().colors?.fillColorSecondaryTransparent05, horzDir: TriangleHorzDirection.rightToLeft, vertDir: TriangleVertDirection.topToBottom), child:
              Container(height: 40)
            ),
            Container(height: 20, color: Styles().colors?.fillColorSecondaryTransparent05),
          ],),
        ),
      ),
    ],) : Container();

  }

  bool get _shouldUpdateImage {
    return (_imageUrl == null) || (_imageDateTime == null) || (DateTimeUtils.midnight(_imageDateTime)!.compareTo(DateTimeUtils.midnight(DateTime.now())!) < 0);
  }

  void _update() {
    if (_shouldUpdateImage && mounted) {
        setState(() {
          _updateImage();
        });
    }
  }

  void _refresh() {
    if (mounted) {
        setState(() {
          _updateImage();
        });
    }
  }

  void _updateImage() {
    Storage().browseToutImageUrl = _imageUrl = Assets().randomStringFromListWithKey('images.random.browse.tout');
    Storage().browseToutImageTime = (_imageDateTime = DateTime.now()).millisecondsSinceEpoch;
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if ((name == AppLivecycle.notifyStateChanged) && (param == AppLifecycleState.resumed)) {
      _update();
    }
  }
}