import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neom/model/Dining.dart';
import 'package:neom/model/Explore.dart';
import 'package:neom/model/Laundry.dart';
import 'package:neom/model/Video.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/service/CheckList.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/service/Content.dart' as uiuc;
import 'package:neom/service/DeepLink.dart';
import 'package:neom/service/FlexUI.dart';
import 'package:neom/service/Guide.dart';
import 'package:neom/service/RadioPlayer.dart';
import 'package:neom/service/Storage.dart';
import 'package:neom/service/Wellness.dart';
import 'package:neom/ui/SavedPanel.dart';
import 'package:neom/ui/WebPanel.dart';
import 'package:neom/ui/academics/AcademicsAppointmentsContentWidget.dart';
import 'package:neom/ui/academics/AcademicsHomePanel.dart';
import 'package:neom/ui/academics/StudentCourses.dart';
import 'package:neom/ui/athletics/AthleticsContentPanel.dart';
import 'package:neom/ui/canvas/CanvasCoursesListPanel.dart';
import 'package:neom/ui/canvas/GiesCanvasCoursesListPanel.dart';
import 'package:neom/ui/events2/Event2HomePanel.dart';
import 'package:neom/ui/explore/ExplorePanel.dart';
import 'package:neom/ui/gies/CheckListPanel.dart';
import 'package:neom/ui/groups/GroupsHomePanel.dart';
import 'package:neom/ui/guide/CampusGuidePanel.dart';
import 'package:neom/ui/guide/GuideListPanel.dart';
import 'package:neom/ui/home/HomePanel.dart';
import 'package:neom/ui/home/HomeRecentItemsWidget.dart';
import 'package:neom/ui/home/HomeSaferTestLocationsPanel.dart';
import 'package:neom/ui/home/HomeSaferWellnessAnswerCenterPanel.dart';
import 'package:neom/ui/home/HomeTwitterWidget.dart';
import 'package:neom/ui/home/HomeRadioWidget.dart';
import 'package:neom/ui/home/HomeWidgets.dart';
import 'package:neom/ui/laundry/LaundryHomePanel.dart';
import 'package:neom/ui/mtd/MTDStopsHomePanel.dart';
import 'package:neom/ui/parking/ParkingEventsPanel.dart';
import 'package:neom/ui/polls/CreatePollPanel.dart';
import 'package:neom/ui/polls/CreateStadiumPollPanel.dart';
import 'package:neom/ui/polls/PollsHomePanel.dart';
import 'package:neom/ui/research/ResearchProjectsHomePanel.dart';
import 'package:neom/ui/surveys/PublicSurveysPanel.dart';
import 'package:neom/ui/wallet/WalletHomePanel.dart';
import 'package:neom/ui/notifications/NotificationsHomePanel.dart';
import 'package:neom/ui/apphelp/AppHelpVideoTutorialListPanel.dart';
import 'package:neom/ui/apphelp/AppHelpVideoTutorialPanel.dart';
import 'package:neom/ui/wallet/WalletICardHomePanel.dart';
import 'package:neom/ui/wellness/WellnessHomePanel.dart';
import 'package:neom/ui/widgets/FavoriteButton.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

///////////////////////////
// BrowsePanel

class BrowsePanel extends StatefulWidget {
  static const String notifyRefresh      = "edu.illinois.rokwire.browse.refresh";
  static const String notifySelect       = "edu.illinois.rokwire.browse.select";

  BrowsePanel();

  @override
  _BrowsePanelState createState() => _BrowsePanelState();
}

class _BrowsePanelState extends State<BrowsePanel> with AutomaticKeepAliveClientMixin<BrowsePanel> {
  StreamController<String> _updateController = StreamController.broadcast();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _updateController.close();
    super.dispose();
  }

  // AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.browse.label.title', 'Browse')),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child:
        Column(children: <Widget>[
          Expanded(child:
            SingleChildScrollView(child:
              Column(children: <Widget>[
                _BrowseToutWidget(updateController: _updateController,),
                BrowseContentWidget(),
              ],)
            )
          ),
        ]),
      ),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: null,
    );
  }

  Future<void> _onPullToRefresh() async {
    _updateController.add(BrowsePanel.notifyRefresh);
    if (mounted) {
      setState(() {});
    }
  }
}


///////////////////////////
// BrowseContentWidget

class BrowseContentWidget extends StatefulWidget {
  BrowseContentWidget({super.key});

  @override
  State<StatefulWidget> createState() => _BrowseContentWidgetState();

}

class _BrowseContentWidgetState extends State<BrowseContentWidget> implements NotificationsListener {

  List<String>? _contentCodes;
  Set<String> _expandedCodes = <String>{};

  @override
  void initState() {
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      Localization.notifyStringsUpdated,
      Styles.notifyChanged,
    ]);

    _contentCodes = buildContentCodes();
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
    if (name == FlexUI.notifyChanged) {
      _updateContentCodes();
      if (mounted) {
        setState(() { });
      }
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
    List<Widget> contentList = <Widget>[];

    List<Widget> sectionsList = <Widget>[];
    if (_contentCodes != null) {
      for (String code in _contentCodes!) {
        List<String>? entryCodes = _BrowseSection.buildBrowseEntryCodes(sectionId: code);
        if ((entryCodes != null) && entryCodes.isNotEmpty) {
          sectionsList.add(_BrowseSection(
            sectionId: code,
            entryCodes: entryCodes,
            expanded: _isExpanded(code),
            onExpand: () => _toggleExpanded(code),)
          );
        }
      }
    }

    if (sectionsList.isNotEmpty) {
      contentList.add(
        HomeSlantWidget(
          title: Localization().getStringEx('panel.browse.label.sections.title', 'App Sections'),
          titleIconKey: 'browse',
          childPadding: HomeSlantWidget.defaultChildPadding,
          child: Column(children: sectionsList,),
        )
      );
    }

    return Column(children: contentList,);
  }

  void _updateContentCodes() {
    List<String>?  contentCodes = buildContentCodes();
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

    String action = _expandedCodes.contains(sectionId) ? 'Collapse' : 'Expand';
    Analytics().logSelect(target: "$action: '$sectionId'");

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

  static List<String>? buildContentCodes() {
    List<String>? codes = JsonUtils.listStringsValue(FlexUI()['browse']);
    codes?.sort((String code1, String code2) {
      String title1 = _BrowseSection.title(sectionId: code1);
      String title2 = _BrowseSection.title(sectionId: code2);
      return title1.compareGit4143To(title2);
    });
    return codes;
  }

}

///////////////////////////
// BrowseSection

class _BrowseSection extends StatelessWidget {

  final String sectionId;
  final bool expanded;
  final void Function()? onExpand;
  final List<String>? _browseEntriesCodes;
  final Set<String>? _homeSectionEntriesCodes;
  final Set<String>? _homeRootEntriesCodes;

  _BrowseSection({Key? key, required this.sectionId, List<String>? entryCodes, this.expanded = false, this.onExpand}) :
    _browseEntriesCodes = entryCodes ?? buildBrowseEntryCodes(sectionId: sectionId),
    _homeSectionEntriesCodes = JsonUtils.setStringsValue(FlexUI()['home.$sectionId']),
    _homeRootEntriesCodes = JsonUtils.setStringsValue(FlexUI()['home']),
    super(key: key);

  static List<String>? buildBrowseEntryCodes({required String sectionId}) {
    List<String>? codes = JsonUtils.listStringsValue(FlexUI()['browse.$sectionId']);
    codes?.sort((String code1, String code2) {
      String title1 = _BrowseEntry.title(sectionId: sectionId, entryId: code1);
      String title2 = _BrowseEntry.title(sectionId: sectionId, entryId: code2);
      return title1.compareGit4143To(title2);
    });
    return codes;
  }

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
          decoration: BoxDecoration(color: Styles().colors.surface, border: Border.all(color: Styles().colors.surfaceAccent, width: 1),),
          padding: EdgeInsets.only(left: 16),
          child: Column(children: [
            Row(children: [
              Expanded(child:
                Padding(padding: EdgeInsets.only(top: 16), child:
                  Text(_title, style: Styles().textStyles.getTextStyle("widget.title.dark.large.extra_fat"))
                )
              ),
              Opacity(opacity: _hasFavoriteContent ? 1 : 0, child:
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
                  Text(_description, style: Styles().textStyles.getTextStyle("widget.info.regular.thin"))
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
                            Styles().images.getImage('chevron-up', excludeFromSemantics: true) :
                            Styles().images.getImage('chevron-down', excludeFromSemantics: true)
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

  String get _title => title(sectionId: sectionId);
  String get _description => description(sectionId: sectionId);

  static String get appTitle => Localization().getStringEx('app.title', 'Illinois');

  static String title({required String sectionId}) {
    return Localization().getString('panel.browse.section.$sectionId.title') ?? StringUtils.capitalize(sectionId, allWords: true, splitDelimiter: '_', joinDelimiter: ' ');
  }

  static String description({required String sectionId}) {
    return Localization().getString('panel.browse.section.$sectionId.description')?.replaceAll('{{app_title}}', appTitle) ?? '';
  }

  void _onTapExpand() {
    if (_hasBrowseContent && (onExpand != null)) {
      onExpand!();
    }
  }

  bool get _hasBrowseContent => _browseEntriesCodes?.isNotEmpty ?? false;

  bool get _hasFavoriteContent {
    if (_browseEntriesCodes?.isNotEmpty ?? false) {
      for (String code in _browseEntriesCodes!) {
        HomeFavorite? entryFavorite = _favorite(code);
        if (entryFavorite != null) {
          return true;
        }
      }
    }
    return false;
  }

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
      if (0 < totalCount) {
        if (favCount == totalCount) {
          return true;
        }
        else if (unfavCount == totalCount) {
          return false;
        }
      }
    }
    return null;
  }

  void _onTapSectionFavorite(BuildContext context) {
    Analytics().logSelect(target: "Favorite: {${HomeFavorite.favoriteKeyName(category: sectionId)}}");

    bool? isSectionFavorite = _isSectionFavorite;
    if (kReleaseMode) {
      promptSectionFavorite(context, isSectionFavorite: isSectionFavorite).then((bool? result) {
        if (result == true) {
          _toggleSectionFavorite(isSectionFavorite: isSectionFavorite);
        }
      });
    }
    else {
      _toggleSectionFavorite(isSectionFavorite: isSectionFavorite);
    }
  }

  void _toggleSectionFavorite({bool? isSectionFavorite}) {
    List<Favorite> favorites = _sectionFavorites;
    Auth2().prefs?.setListFavorite(favorites, isSectionFavorite != true);
    HomeFavorite.log(favorites, isSectionFavorite != true);
  }

  List<Favorite> get _sectionFavorites {
    List<Favorite> favorites = <Favorite>[];

    if ((_homeSectionEntriesCodes != null) && (_homeRootEntriesCodes?.contains(sectionId) ?? false)) {
      favorites.add(HomeFavorite(sectionId));
    }

    if (_browseEntriesCodes != null) {
      for(String code in _browseEntriesCodes!.reversed) {
        HomeFavorite? entryFavorite = _favorite(code);
        if (entryFavorite != null) {
          favorites.add(entryFavorite);
        }
      }
    }

    return favorites;
  }

  Future<bool?> promptSectionFavorite(BuildContext context, {bool? isSectionFavorite}) async {
    String message = (isSectionFavorite != true) ?
      Localization().getStringEx('panel.browse.prompt.add.all.favorites', 'Are you sure you want to ADD these items to your favorites?') :
      Localization().getStringEx('panel.browse.prompt.remove.all.favorites', 'Are you sure you want to REMOVE these items from your favorites?');
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

///////////////////////////
// BrowseEntry

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
          decoration: BoxDecoration(color: Styles().colors.surface, border: Border.all(color: Styles().colors.surfaceAccent, width: 1),),
          padding: EdgeInsets.zero,
          child:
            Row(children: [
              Opacity(opacity: (favorite != null) ? 1 : 0, child:
                HomeFavoriteButton(favorite: favorite, style: FavoriteIconStyle.Button, prompt: true,),
              ),
              Expanded(child:
                Padding(padding: EdgeInsets.symmetric(vertical: 14), child:
                  Text(_title, style: Styles().textStyles.getTextStyle("widget.title.dark.large.extra_fat"),)
                ),
              ),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: _iconWidget),
            ],),
        ),
      ),
    );
  }

  String get _title => title(sectionId: sectionId, entryId: entryId);

  static String title({required String sectionId, required String entryId}) {
    return Localization().getString('panel.browse.entry.$sectionId.$entryId.title') ?? StringUtils.capitalize(entryId, allWords: true, splitDelimiter: '_', joinDelimiter: ' ');
  }

  static Map<String, String> _iconsMap = <String, String>{
    'academics.my_illini'        : 'external-link',
    'academics.due_date_catalog' : 'external-link',
    'feeds.daily_illini'         : 'external-link',
    'app_help.faqs'              : 'external-link',
    'app_help.feedback'          : 'external-link',
    'safer.my_mckinley'          : 'external-link',
  };

  Widget? get _iconWidget =>
    Styles().images.getImage(_iconsMap['$sectionId.$entryId'] ?? 'chevron-right-bold', excludeFromSemantics: true);

  void _onTap(BuildContext context) {
    switch("$sectionId.$entryId") {
      case "academics.gies_checklist":        _onTapGiesChecklist(context); break;
      case "academics.new_student_checklist": _onTapNewStudentChecklist(context); break;
      case "academics.skills_self_evaluation":_onTapSkillSelfEvaluation(context); break;
      case "academics.essential_skills_coach":_onTapEssentialSkillCoach(context); break;
      case "academics.wellness_todo":         _onTapAcademicsToDo(context); break;
      case "academics.student_courses":       _onTapStudentCourses(context); break;
      case "academics.canvas_courses":        _onTapCanvasCourses(context); break;
      case "academics.gies_canvas_courses":   _onTapGiesCanvasCourses(context); break;
      case "academics.campus_reminders":      _onTapCampusReminders(context); break;
      case "academics.due_date_catalog":      _onTapDueDateCatalog(context); break;
      case "academics.appointments":          _onTapAcademicsAppointments(context); break;
      case "academics.my_illini":             _onTapAcademicsMyIllini(context); break;

      case "app_help.video_tutorials":       _onTapVideoTutorials(context); break;
      case "app_help.feedback":              _onTapFeedback(context); break;
      case "app_help.review":                _onTapReview(context); break;
      case "app_help.faqs":                  _onTapFAQs(context); break;

      case "appointments.appointments":       _onTapAcademicsAppointments(context); break;

      case "athletics.my_game_day":          _onTapMyGameDay(context); break;
      case "athletics.sport_events":         _onTapSportEvents(context); break;
      case "athletics.my_athletics":         _onTapMyAthletics(context); break;
      case "athletics.sport_news":           _onTapSportNews(context); break;
      case "athletics.sport_teams":          _onTapSportTeams(context); break;
      case "athletics.my_news":              _onTapMyNews(context); break;

      case "safer.building_access":          _onTapBuildingAccess(context); break;
      case "safer.test_locations":           _onTapTestLocations(context); break;
      case "safer.my_mckinley":              _onTapMyMcKinley(context); break;
      case "safer.wellness_answer_center":   _onTapWellnessAnswerCenter(context); break;

      case "laundry.laundry":                 _onTapLaundry(context); break;
      case "laundry.my_laundry":              _onTapMyLaundry(context); break;

      case "mtd.all_mtd_stops":              _onTapMTDStops(context); break;
      case "mtd.my_mtd_stops":               _onTapMyMTDStops(context); break;
      case "mtd.my_mtd_destinations":        _onTapMyMTDDestinations(context); break;

      case "campus_guide.campus_highlights": _onTapCampusHighlights(context); break;
      case "campus_guide.campus_safety_resources": _onTapCampusSafetyResources(context); break;
      case "campus_guide.campus_guide":      _onTapCampusGuide(context); break;
      case "campus_guide.my_campus_guide":   _onTapMyCampusGuide(context); break;

      case "dinings.dinings_all":            _onTapDiningsAll(context); break;
      case "dinings.dinings_open":           _onTapDiningsOpen(context); break;
      case "dinings.my_dining":              _onTapMyDinings(context); break;

      case "events.event_feed":              _onTapEventFeed(context); break;
      case "events.my_events":               _onTapMyEvents(context); break;

      case "feeds.twitter":                  _onTapTwitter(context); break;
      case "feeds.daily_illini":             _onTapDailyIllini(context); break;

      case "radio_stations.will_radio":      _onTapRadioStation(context, RadioStation.will); break;
      case "radio_stations.willfm_radio":    _onTapRadioStation(context, RadioStation.willfm); break;
      case "radio_stations.willhd_radio":    _onTapRadioStation(context, RadioStation.willhd); break;
      case "radio_stations.wpgufm_radio":    _onTapRadioStation(context, RadioStation.wpgufm); break;

      case "groups.all_groups":              _onTapAllGroups(context); break;
      case "groups.my_groups":               _onTapMyGroups(context); break;

      case "research_projects.open_research_projects": _onTapOpenResearchProjects(context); break;
      case "research_projects.my_research_projects": _onTapMyResearchProjects(context); break;

      case "inbox.all_notifications":        _onTapNotifications(context); break;
      case "inbox.unread_notifications":     _onTapNotifications(context, unread: true); break;

      case "polls.create_poll":              _onTapCreatePoll(context); break;
      case "polls.recent_polls":             _onTapViewPolls(context); break;

      case "recent.recent_items":            _onTapRecentItems(context); break;

      case "surveys.public_surveys":         _onTapPublicSurveys(context); break;

      case "state_farm_center.parking":      _onTapParking(context); break;
      case "state_farm_center.wayfinding":   _onTapStateFarmWayfinding(context); break;
      case "state_farm_center.create_stadium_poll": _onTapCreateStadiumPoll(context); break;

      case "wallet.illini_cash_card":        _onTapIlliniCash(context); break;
      case "wallet.add_illini_cash":         _onTapAddIlliniCash(context); break;
      case "wallet.meal_plan_card":          _onTapMealPlan(context); break;
      case "wallet.bus_pass_card":           _onTapBusPass(context); break;
      case "wallet.illini_id_card":          _onTapIlliniId(context); break;
      case "wallet.library_card":            _onTapLibraryCard(context); break;

      case "wellness.wellness_resources":       _onTapWellnessResources(context); break;
      case "wellness.wellness_mental_health":   _onTapWellnessMentalHealth(context); break;
      case "wellness.wellness_rings":           _onTapWellnessRings(context); break;
      case "wellness.wellness_todo":            _onTapWellnessToDo(context); break;
      case "wellness.my_appointments":          _onTapWellnessAppointments(context); break;
      case "wellness.wellness_tips":            _onTapWellnessTips(context); break;
      case "wellness.wellness_health_screener": _onTapWellnessHealthScreener(context); break;
      case "wellness.wellness_success_team":    _onTapWellnessSuccessTeam(context); break;
      case "wellness.wellness_podcast":         _onTapWellnessPodcast(context); break;
      case "wellness.wellness_struggling":      _onTapWellnessStruggling(context); break;
    }
  }

  void _onTapGiesChecklist(BuildContext context) {
    Analytics().logSelect(target: "Gies Checklist");
    CheckListPanel.present(context, contentKey: CheckList.giesOnboarding);
  }

  void _onTapNewStudentChecklist(BuildContext context) {
    Analytics().logSelect(target: "New Student Checklist");
    CheckListPanel.present(context, contentKey: CheckList.uiucOnboarding);
  }

  void _onTapSkillSelfEvaluation(BuildContext context) {
    Analytics().logSelect(target: "Skills Self-Evaluation");
    AcademicsHomePanel.push(context, AcademicsContent.skills_self_evaluation);
  }

  void _onTapEssentialSkillCoach(BuildContext context) {
    Analytics().logSelect(target: "Essential Skills Coach");
    AcademicsHomePanel.push(context, AcademicsContent.essential_skills_coach);
  }

  void _onTapAcademicsToDo(BuildContext context) {
    Analytics().logSelect(target: "Academics To Do");
    AcademicsHomePanel.push(context, AcademicsContent.todo_list);
  }

  void _onTapCanvasCourses(BuildContext context) {
    Analytics().logSelect(target: "Canvas Courses");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCoursesListPanel()));
  }

  void _onTapGiesCanvasCourses(BuildContext context) {
    Analytics().logSelect(target: "Gies Canvas Courses");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GiesCanvasCoursesListPanel()));
  }

  void _onTapStudentCourses(BuildContext context) {
    Analytics().logSelect(target: "Student Courses");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentCoursesListPanel()));
  }

  void _onTapCampusReminders(BuildContext context) {
    Analytics().logSelect(target: "Campus Reminders");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(
      contentList: Guide().remindersList,
      contentTitle: Localization().getStringEx('panel.guide_list.label.campus_reminders.section', 'Campus Reminders'),
      contentEmptyMessage: Localization().getStringEx("panel.guide_list.label.campus_reminders.empty", "There are no active Campus Reminders."),
    )));
  }

  int get _videoTutorialsCount => uiuc.Content().videos?.length ?? 0;

  bool get _canVideoTutorials => (_videoTutorialsCount > 0);

  void _onTapVideoTutorials(BuildContext context) {
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.video_tutorial', 'Video Tutorial not available while offline.'));
    }
    else if (_canVideoTutorials) {
      List<Video>? videoTutorials = _getVideoTutorials();
      if (videoTutorials?.length == 1) {
        Video? videoTutorial = videoTutorials?.first;
        if (videoTutorial != null) {
          Analytics().logSelect(target: "Video Tutorials", source: runtimeType.toString(), attributes: videoTutorial.analyticsAttributes);
          Navigator.push(context, CupertinoPageRoute( settings: RouteSettings(), builder: (context) => AppHelpVideoTutorialPanel(videoTutorial: videoTutorial)));
        }
      } else {
        Analytics().logSelect(target: "Video Tutorials", source: runtimeType.toString());
        Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) => AppHelpVideoTutorialListPanel(videoTutorials: videoTutorials)));
      }
    }
  }

  List<Video>? _getVideoTutorials() {
    Map<String, dynamic>? videoTutorials = uiuc.Content().videoTutorials;
    if (videoTutorials == null) {
      return null;
    }
    List<dynamic>? videos = JsonUtils.listValue(videoTutorials['videos']);
    if (CollectionUtils.isEmpty(videos)) {
      return null;
    }
    Map<String, dynamic>? strings = JsonUtils.mapValue(videoTutorials['strings']);
    return Video.listFromJson(jsonList: videos, contentStrings: strings);
  }

  bool get _canFeedback => StringUtils.isNotEmpty(Config().feedbackUrl);

  void _onTapFeedback(BuildContext context) {
    Analytics().logSelect(target: "Provide Feedback");

    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('widget.home.app_help.feedback.label.offline', 'Providing a Feedback is not available while offline.'));
    }
    else if (_canFeedback) {
      String email = Uri.encodeComponent(Auth2().emails.firstOrNull ?? '');
      String name =  Uri.encodeComponent(Auth2().fullName ?? '');
      String phone = Uri.encodeComponent(Auth2().phones.firstOrNull ?? '');
      String feedbackUrl = "${Config().feedbackUrl}?email=$email&phone=$phone&name=$name";
      _launchUrl(context, feedbackUrl);
    }
  }

  void _onTapReview(BuildContext context) {
    Analytics().logSelect(target: "Provide Review");
    InAppReview.instance.openStoreListing(appStoreId: Config().appStoreId);
  }

  bool get _canFAQs => StringUtils.isNotEmpty(Config().faqsUrl);

  void _onTapFAQs(BuildContext context) {
    Analytics().logSelect(target: "FAQs");

    if (_canFAQs) {
      _launchUrl(context, Config().faqsUrl);
    }
  }

  void _onTapSportEvents(BuildContext context) {
    Analytics().logSelect(target: "Events");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsContentPanel(content: AthleticsContent.events)));
  }

  void _onTapSportNews(BuildContext context) {
    Analytics().logSelect(target: "News");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsContentPanel(content: AthleticsContent.news)));
  }

  void _onTapSportTeams(BuildContext context) {
    Analytics().logSelect(target: "Teams");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsContentPanel(content: AthleticsContent.teams)));
  }

  void _onTapBuildingAccess(BuildContext context) {
    Analytics().logSelect(target: 'Building Access');
    WalletICardHomeContentPanel.present(context, content: WalletICardContent.i_card);
  }

  void _onTapTestLocations(BuildContext context) {
    Analytics().logSelect(target: 'Locations');
    Navigator.push(context, CupertinoPageRoute(
      builder: (context) => HomeSaferTestLocationsPanel()
    ));
  }

  void _onTapMyMcKinley(BuildContext context) {
    Analytics().logSelect(target: 'MyMcKinley');
    _launchUrl(context, Config().saferMcKinleyUrl);
  }

  void _onTapWellnessAnswerCenter(BuildContext context) {
    Analytics().logSelect(target: 'Answer Center');
    Navigator.push(context, CupertinoPageRoute(
      builder: (context) => HomeSaferWellnessAnswerCenterPanel()
    ));
  }

  void _onTapCampusHighlights(BuildContext context) {
    Analytics().logSelect(target: 'Campus Highlights');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(
      contentList: Guide().promotedList,
      contentTitle: Localization().getStringEx('panel.guide_list.label.highlights.section', 'Campus Highlights'),
      contentEmptyMessage: Localization().getStringEx("panel.guide_list.label.highlights.empty", "There are no active Campus Hightlights."),
      favoriteKey: GuideFavorite.constructFavoriteKeyName(contentType: Guide.campusHighlightContentType),
    )));
  }

  void _onTapCampusSafetyResources(BuildContext context) {
    Analytics().logSelect(target: 'Campus Safety Resources');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(
      contentList: Guide().safetyResourcesList,
      contentTitle: Localization().getStringEx('panel.guide_list.label.campus_safety_resources.section', 'Safety Resources'),
      contentEmptyMessage: Localization().getStringEx("panel.guide_list.label.campus_safety_resources.empty", "There are no active Campus Safety Resources."),
      favoriteKey: GuideFavorite.constructFavoriteKeyName(contentType: Guide.campusSafetyResourceContentType),
    )));
  }

  bool get _canDueDateCatalog => StringUtils.isNotEmpty(Config().dateCatalogUrl);

  void _onTapDueDateCatalog(BuildContext context) {
    Analytics().logSelect(target: "Due Date Catalog");

    if (_canDueDateCatalog) {
      _launchUrl(context, Config().dateCatalogUrl);
    }
  }

  void _onTapDiningsAll(BuildContext context) {
    Analytics().logSelect(target: "HomeDiningWidget: Residence Hall Dining");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(exploreType: ExploreType.Dining) ));
  }

  void _onTapDiningsOpen(BuildContext context) {
    Analytics().logSelect(target: "HomeDiningWidget: Residence Hall Dining Open Now");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(exploreType: ExploreType.Dining, initialFilter: ExploreFilter(type: ExploreFilterType.work_time, selectedIndexes: {1}))));
  }

  void _onTapLaundry(BuildContext context) {
    Analytics().logSelect(target: "Laundry");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryHomePanel()));
  }

  void _onTapMTDStops(BuildContext context) {
    Analytics().logSelect(target: "All Bus Stops");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => MTDStopsHomePanel(contentType: MTDStopsContentType.all,)));
  }

  void _onTapCampusGuide(BuildContext context) {
    Analytics().logSelect(target: "Campus Guide");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CampusGuidePanel()));
  }

  void _onTapNotifications(BuildContext context, {bool? unread}) {
    bool isUnread = (unread == true);
    Analytics().logSelect(target: isUnread ? "Unread Notifications" : "All Notifications");
    NotificationsHomePanel.present(context, content: isUnread ? NotificationsContent.unread : NotificationsContent.all);
  }

  void _onTapEventFeed(BuildContext context) {
    Analytics().logSelect(target: "Events Feed");
    Event2HomePanel.present(context);
  }

  void _onTapMyEvents(BuildContext context) {
    Analytics().logSelect(target: "My Events");
    Event2HomePanel.present(context, types: LinkedHashSet<Event2TypeFilter>.from([Event2TypeFilter.favorite]));
  }

  /*void _onTapSuggestedEvents(BuildContext context) {
    Analytics().logSelect(target: "Suggested Events");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return ExplorePanel(exploreType: ExploreType.Events); } ));
  }*/

  void _onTapTwitter(BuildContext context) {
    Analytics().logSelect(target: "Twitter");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return TwitterPanel(); } ));
  }

  void _onTapDailyIllini(BuildContext context) {
    Analytics().logSelect(target: "Daily Illini");
    _launchUrl(context, Config().dailyIlliniHomepageUrl);
  }

  void _onTapRadioStation(BuildContext context, RadioStation radioStation) {
    Analytics().logSelect(target: "Radio Station (${radioStation.toString()})");
    HomeRadioWidget.showPopup(context, radioStation);
  }

  void _onTapAllGroups(BuildContext context) {
    Analytics().logSelect(target: "All Groups");
    Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: GroupsHomePanel.routeName), builder: (context) => GroupsHomePanel(contentType: GroupsContentType.all,)));
  }

  void _onTapMyGroups(BuildContext context) {
    Analytics().logSelect(target: "My Groups");
    Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: GroupsHomePanel.routeName), builder: (context) => GroupsHomePanel(contentType: GroupsContentType.my)));
  }

  void _onTapOpenResearchProjects(BuildContext context) {
    Analytics().logSelect(target: "Open Research Projects");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ResearchProjectsHomePanel(contentType: ResearchProjectsContentType.open,)));
  }

  void _onTapMyResearchProjects(BuildContext context) {
    Analytics().logSelect(target: "My Research Projects");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ResearchProjectsHomePanel(contentType: ResearchProjectsContentType.my)));
  }

  void _onTapMyGameDay(BuildContext context) {
    Analytics().logSelect(target: "It's Game Day");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsContentPanel(content: AthleticsContent.game_day)));
  }

  void _onTapMyDinings(BuildContext context) {
    Analytics().logSelect(target: "My Dinings");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return SavedPanel(favoriteCategories: [Dining.favoriteKeyName]); } ));
  }

  void _onTapMyAthletics(BuildContext context) {
    Analytics().logSelect(target: "My Big 10 Events");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsContentPanel(content: AthleticsContent.my_events)));
  }

  void _onTapMyNews(BuildContext context) {
    Analytics().logSelect(target: "My News");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsContentPanel(content: AthleticsContent.my_news)));
  }

  void _onTapMyLaundry(BuildContext context) {
    Analytics().logSelect(target: "My Laundry");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return SavedPanel(favoriteCategories: [LaundryRoom.favoriteKeyName]); } ));
  }

  void _onTapMyMTDStops(BuildContext context) {
    Analytics().logSelect(target: "My Bus Stops");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => MTDStopsHomePanel(contentType: MTDStopsContentType.my,)));
  }

  void _onTapMyMTDDestinations(BuildContext context) {
    Analytics().logSelect(target: "My Destinations");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return SavedPanel(favoriteCategories: [ExplorePOI.favoriteKeyName]); } ));
  }

  void _onTapMyCampusGuide(BuildContext context) {
    Analytics().logSelect(target: "My Campus Guide");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return SavedPanel(favoriteCategories: [GuideFavorite.favoriteKeyName]); } ));
  }

  void _onTapWellnessResources(BuildContext context) {
    Analytics().logSelect(target: "Wellness Resources");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return WellnessHomePanel(content: WellnessContent.resources,); } ));
  }

  void _onTapWellnessMentalHealth(BuildContext context) {
    Analytics().logSelect(target: "Wellness Resources");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return WellnessHomePanel(content: WellnessContent.mentalHealth,); } ));
  }

  void _onTapWellnessAppointments(BuildContext context) {
    Analytics().logSelect(target: "MyMcKinley Appointments");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return WellnessHomePanel(content: WellnessContent.appointments); } ));
  }

  void _onTapAcademicsAppointments(BuildContext context) {
    Analytics().logSelect(target: "Appointments");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AppointmentsListPanel()));
  }

  void _onTapAcademicsMyIllini(BuildContext context) {
    Analytics().logSelect(target: "myIllini");
    _launchUrl(context, Config().myIlliniUrl);
  }

  void _onTapCreatePoll(BuildContext context) {
    Analytics().logSelect(target: "Create Poll");
    CreatePollPanel.present(context);
  }

  void _onTapViewPolls(BuildContext context) {
    Analytics().logSelect(target: "View Polls");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PollsHomePanel()));
  }

  void _onTapRecentItems(BuildContext context) {
    Analytics().logSelect(target: "Recent Items");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => HomeRecentItemsPanel()));
  }

  void _onTapPublicSurveys(BuildContext context) {
    Analytics().logSelect(target: "Public Surveys");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PublicSurveysPanel()));
  }

  void _onTapParking(BuildContext context) {
    Analytics().logSelect(target: "Parking");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ParkingEventsPanel()));
  }

  void _onTapStateFarmWayfinding(BuildContext context) {
    Analytics().logSelect(target: "State Farm Wayfinding");
    /* TBD Map2 NativeCommunicator().launchMap(target: {
      'latitude': Config().stateFarmWayfinding['latitude'],
      'longitude': Config().stateFarmWayfinding['longitude'],
      'zoom': Config().stateFarmWayfinding['zoom'],
    }); */
  }

  void _onTapCreateStadiumPoll(BuildContext context) {
    Analytics().logSelect(target: "Create Stadium Poll");
    CreateStadiumPollPanel.present(context);
  }

  void _onTapIlliniCash(BuildContext context) {
    Analytics().logSelect(target: "Illini Cash");
    WalletHomePanel.present(context, contentType: WalletContentType.illiniCash);
  }

  void _onTapAddIlliniCash(BuildContext context) {
    Analytics().logSelect(target: "Add Illini Cash");
    WalletHomePanel.present(context, contentType: WalletContentType.addIlliniCash);
  }

  void _onTapMealPlan(BuildContext context) {
    Analytics().logSelect(target: "Meal Plan");
    WalletHomePanel.present(context, contentType: WalletContentType.mealPlan);
  }

  void _onTapBusPass(BuildContext context) {
    Analytics().logSelect(target: "Bus Pass");
    WalletHomePanel.present(context, contentType: WalletContentType.busPass);
  }

  void _onTapIlliniId(BuildContext context) {
    Analytics().logSelect(target: "Illini ID");
    WalletHomePanel.present(context, contentType: WalletContentType.illiniId);
  }

  void _onTapLibraryCard(BuildContext context) {
    Analytics().logSelect(target: "Library Card");
    _notImplemented(context);
  }

  void _onTapWellnessRings(BuildContext context) {
    Analytics().logSelect(target: "Wellness Daily Rings");
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

  void _onTapWellnessHealthScreener(BuildContext context) {
    Analytics().logSelect(target: "Illinois Health Screener");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(content: WellnessContent.healthScreener,)));
  }

  void _onTapWellnessSuccessTeam(BuildContext context) {
    Analytics().logSelect(target: "My Success Team");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(content: WellnessContent.successTeam,)));
  }

  void _onTapWellnessPodcast(BuildContext context) {
    Analytics().logSelect(target: "Healthy Illini Podcast");
    _launchUrl(context, Wellness().getResourceUrl(resourceId: 'podcast'));
  }

  void _onTapWellnessStruggling(BuildContext context) {
    Analytics().logSelect(target: "I'm Struggling");
    _launchUrl(context, Wellness().getResourceUrl(resourceId: 'where_to_start'));
  }

  void _notImplemented(BuildContext context) {
    AppAlert.showDialogResult(context, "Not implemented yet.");
  }

  static void _launchUrl(BuildContext context, String? url, {bool launchInternal = false}) {
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else if (launchInternal && UrlUtils.launchInternal(url)){
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      }
      else {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri, mode: (Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault));
        }
      }
    }
  }

}

///////////////////////////
// BrowseToutWidget

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
      AppLifecycle.notifyStateChanged,
      Content.notifyContentImagesChanged,
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
      ModalImageHolder(child: Image.network(_imageUrl!, semanticLabel: 'tout', loadingBuilder:(  BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
        double imageWidth = MediaQuery.of(context).size.width;
        double imageHeight = imageWidth * 810 / 1080;
        return (loadingProgress != null) ?
          Container(color: Styles().colors.fillColorPrimary, width: imageWidth, height: imageHeight, child:
            Center(child:
              CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.surface), )
            ),
          ) :
          AspectRatio(aspectRatio: (1080.0 / 810.0), child:
            Container(color: Styles().colors.fillColorPrimary, child: child)
          );
      })),
      Positioned.fill(child:
        Align(alignment: Alignment.bottomCenter, child:
          Column(mainAxisSize: MainAxisSize.min, children: [
            CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.fillColorSecondary, horzDir: TriangleHorzDirection.rightToLeft, vertDir: TriangleVertDirection.topToBottom), child:
              Container(height: 40)
            ),
            Container(height: 20, color: Styles().colors.fillColorSecondary),
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
    Storage().browseToutImageUrl = _imageUrl = Content().randomImageUrl('browse.tout');
    Storage().browseToutImageTime = (_imageDateTime = DateTime.now()).millisecondsSinceEpoch;
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if ((name == AppLifecycle.notifyStateChanged) && (param == AppLifecycleState.resumed)) {
      _update();
    }
    else if (name == Content.notifyContentImagesChanged) {
      _update();
    }
  }
}
