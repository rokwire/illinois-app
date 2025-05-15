import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/CheckList.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/service/RadioPlayer.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/SavedPanel.dart';
import 'package:illinois/ui/appointments/AppointmentsContentWidget.dart';
import 'package:illinois/ui/academics/AcademicsHomePanel.dart';
import 'package:illinois/ui/academics/StudentCourses.dart';
import 'package:illinois/ui/athletics/AthleticsHomePanel.dart';
import 'package:illinois/ui/canvas/CanvasCoursesListPanel.dart';
import 'package:illinois/ui/canvas/GiesCanvasCoursesListPanel.dart';
import 'package:illinois/ui/messages/MessagesHomePanel.dart';
import 'package:illinois/ui/directory/DirectoryAccountsPanel.dart';
import 'package:illinois/ui/events2/Event2HomePanel.dart';
import 'package:illinois/ui/dining/DiningHomePanel.dart';
import 'package:illinois/ui/gies/CheckListPanel.dart';
import 'package:illinois/ui/groups/GroupsHomePanel.dart';
import 'package:illinois/ui/guide/CampusGuidePanel.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:illinois/ui/guide/GuideListPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeRecentItemsWidget.dart';
import 'package:illinois/ui/home/HomeTwitterWidget.dart';
import 'package:illinois/ui/home/HomeRadioWidget.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/laundry/LaundryHomePanel.dart';
import 'package:illinois/ui/mtd/MTDStopsHomePanel.dart';
import 'package:illinois/ui/polls/CreatePollPanel.dart';
import 'package:illinois/ui/polls/PollsHomePanel.dart';
import 'package:illinois/ui/research/ResearchProjectsHomePanel.dart';
import 'package:illinois/ui/safety/SafetyHomePanel.dart';
import 'package:illinois/ui/surveys/PublicSurveysPanel.dart';
import 'package:illinois/ui/wallet/WalletHomePanel.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/WebNetworkImage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';

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

class BrowseContentWidget extends StatefulWidget with AnalyticsInfo {
  BrowseContentWidget({super.key});

  @override
  State<StatefulWidget> createState() => _BrowseContentWidgetState();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.Browse;
}

class _BrowseContentWidgetState extends State<BrowseContentWidget> with NotificationsListener {

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
        _BrowseSlantWidget(
          childPadding: _BrowseSlantWidget.defaultChildPadding,
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
    return Padding(padding: EdgeInsets.only(bottom: (expanded ? 0 : 4)), child:
      InkWell(onTap: () => _onTapHeading(context), child:
        Container(
          decoration: BoxDecoration(color: Styles().colors.white, border: Border.all(color: Styles().colors.surfaceAccent, width: 1),),
          padding: EdgeInsets.only(left: 16),
          child: Column(children: [
            Row(children: [
              Expanded(child:
                Padding(padding: EdgeInsets.only(top: 16), child:
                  Text(_title, style: Styles().textStyles.getTextStyle("widget.title.regular.fat"))
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
                        _headingIcon
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

  Widget? get _headingIcon {
    if (_hasBrowseContent) {
      if (_singleBrowseCode != null) {
        return Styles().images.getImage('chevron-right', excludeFromSemantics: true);
      }
      else if (expanded) {
        return Styles().images.getImage('chevron-up', excludeFromSemantics: true);
      }
      else {
        return Styles().images.getImage('chevron-down', excludeFromSemantics: true);
      }
    }
    else {
      return Container();
    }
  }

  Widget _buildEntries(BuildContext context) {
      List<Widget> entriesList = <Widget>[];
      int browseEntriesCount = expanded ? (_browseEntriesCodes?.length ?? 0) : 0;
      if (1 < browseEntriesCount) {
        for (String code in _browseEntriesCodes!) {
          entriesList.add(_BrowseEntry(
            sectionId: sectionId,
            entryId: code,
            favorite: _favorite(code),
          ));
        }
      }
      return entriesList.isNotEmpty ? Padding(padding: EdgeInsets.only(left: 24), child:
        Padding(padding: EdgeInsets.only(bottom: 4), child: Column(children: entriesList))
      ) : Container();
  }

  String get _title => title(sectionId: sectionId);
  String get _description => description(sectionId: sectionId);

  static String title({required String sectionId}) =>
    AppTextUtils.appBrandString('panel.browse.section.$sectionId.title', defaultTitle(sectionId: sectionId));

  static String defaultTitle({required String sectionId}) =>
    StringUtils.capitalize(sectionId, allWords: true, splitDelimiter: '_', joinDelimiter: ' ');

  static String description({required String sectionId}) =>
      AppTextUtils.appBrandString('panel.browse.section.$sectionId.description', '');

  void _onTapHeading(BuildContext context) {
    if (_hasBrowseContent) {
      String? singleBrowseCode = _singleBrowseCode;
      if (singleBrowseCode != null) {
        _BrowseEntry.process(context, sectionId, singleBrowseCode);
      }
      else {
        onExpand?.call();
      }
    }
  }

  bool get _hasBrowseContent => _browseEntriesCodes?.isNotEmpty ?? false;
  String? get _singleBrowseCode => (_browseEntriesCodes?.length == 1) ? _browseEntriesCodes?.first : null;

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
    return InkWell(onTap: () => _onTap(context), child:
        Container(
          decoration: BoxDecoration(color: Styles().colors.white, border: Border.all(color: Styles().colors.surfaceAccent, width: 1),),
          padding: EdgeInsets.zero,
          child:
            Row(children: [
              Opacity(opacity: (favorite != null) ? 1 : 0, child:
                HomeFavoriteButton(favorite: favorite, style: FavoriteIconStyle.Button, prompt: true,),
              ),
              Expanded(child:
                Padding(padding: EdgeInsets.symmetric(vertical: 14), child:
                  Text(_title, style: Styles().textStyles.getTextStyle("widget.title.regular.fat"),)
                ),
              ),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: _iconWidget),
            ],),
        )
    );
  }

  String get _title => title(sectionId: sectionId, entryId: entryId);

  static String title({required String sectionId, required String entryId}) {
    return Localization().getString('panel.browse.entry.$sectionId.$entryId.title') ?? StringUtils.capitalize(entryId, allWords: true, splitDelimiter: '_', joinDelimiter: ' ');
  }

  static Map<String, String> _iconsMap = <String, String>{
    'academics.my_illini'        : 'external-link',
    'academics.due_date_catalog' : 'external-link',
    'music_and_news.daily_illini': 'external-link',
  };

  Widget? get _iconWidget =>
    Styles().images.getImage(_iconsMap['$sectionId.$entryId'] ?? 'chevron-right-bold', excludeFromSemantics: true);

  void _onTap(BuildContext context) {
    process(context, sectionId, entryId);
  }

  static void process(BuildContext context, String sectionId, String entryId) {
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
      case "academics.appointments":          _onTapAppointments(context, analyticsFeature: AnalyticsFeature.AcademicsAppointments); break;
      case "academics.my_illini":             _onTapAcademicsMyIllini(context); break;

      case "appointments.appointments":       _onTapAppointments(context, analyticsFeature: AnalyticsFeature.Appointments); break;

      case "athletics.my_game_day":          _onTapMyGameDay(context); break;
      case "athletics.sport_events":         _onTapSportEvents(context); break;
      case "athletics.my_athletics":         _onTapMyAthletics(context); break;
      case "athletics.sport_news":           _onTapSportNews(context); break;
      case "athletics.sport_teams":          _onTapSportTeams(context); break;
      case "athletics.my_news":              _onTapMyNews(context); break;

      case "laundry.laundry":                _onTapLaundry(context); break;
      case "laundry.my_laundry":             _onTapMyLaundry(context); break;

      case "messages.messages":              _onTapMessages(context); break;

      case "mtd.all_mtd_stops":              _onTapMTDStops(context); break;
      case "mtd.my_mtd_stops":               _onTapMyMTDStops(context); break;
      case "mtd.my_locations":               _onTapMyLocations(context); break;

      case "campus_guide.campus_highlights": _onTapCampusHighlights(context); break;
      case "campus_guide.campus_guide":      _onTapCampusGuide(context); break;
      case "campus_guide.my_campus_guide":   _onTapMyCampusGuide(context); break;

      case "dinings.dinings_all":            _onTapDiningsAll(context); break;
      case "dinings.dinings_open":           _onTapDiningsOpen(context); break;
      case "dinings.my_dining":              _onTapMyDinings(context); break;

      case "directory.user_directory":       _onTapUserDirectory(context); break;

      case "events.event_feed":              _onTapEventFeed(context); break;
      case "events.my_events":               _onTapMyEvents(context); break;

      case "feeds.twitter":                  _onTapTwitter(context); break;

      case "music_and_news.will_radio":      _onTapRadioStation(context, RadioStation.will); break;
      case "music_and_news.willfm_radio":    _onTapRadioStation(context, RadioStation.willfm); break;
      case "music_and_news.willhd_radio":    _onTapRadioStation(context, RadioStation.willhd); break;
      case "music_and_news.wpgufm_radio":    _onTapRadioStation(context, RadioStation.wpgufm); break;
      case "music_and_news.daily_illini":    _onTapDailyIllini(context); break;

      case "groups.all_groups":              _onTapAllGroups(context); break;
      case "groups.my_groups":               _onTapMyGroups(context); break;

      case "research_projects.open_research_projects": _onTapOpenResearchProjects(context); break;
      case "research_projects.my_research_projects": _onTapMyResearchProjects(context); break;

      case "polls.create_poll":              _onTapCreatePoll(context); break;
      case "polls.recent_polls":             _onTapViewPolls(context); break;

      case "recent.recent_items":            _onTapRecentItems(context); break;

      case "safety.safewalk_request":        _onTapSafewalkRequest(context); break;
      case "safety.saferides":               _onTapSafeRides(context); break;
      case "safety.safety_resources":        _onTapSafetyResources(context); break;

      case "surveys.public_surveys":         _onTapPublicSurveys(context); break;

      case "wallet.illini_cash_card":        _onTapIlliniCash(context); break;
      case "wallet.add_illini_cash":         _onTapAddIlliniCash(context); break;
      case "wallet.meal_plan_card":          _onTapMealPlan(context); break;
      case "wallet.bus_pass_card":           _onTapBusPass(context); break;
      case "wallet.illini_id_card":          _onTapIlliniId(context); break;

      case "wellness.wellness_resources":       _onTapWellnessResources(context); break;
      case "wellness.wellness_mental_health":   _onTapWellnessMentalHealth(context); break;
      case "wellness.wellness_recreation":   _onTapWellnessRecreation(context); break;
      case "wellness.wellness_rings":           _onTapWellnessRings(context); break;
      case "wellness.wellness_todo":            _onTapWellnessToDo(context); break;
      case "wellness.my_appointments":          _onTapWellnessAppointments(context); break;
      case "wellness.wellness_tips":            _onTapWellnessTips(context); break;
      case "wellness.wellness_health_screener": _onTapWellnessHealthScreener(context); break;
      case "wellness.wellness_success_team":    _onTapWellnessSuccessTeam(context); break;
    }
  }

  static void _onTapGiesChecklist(BuildContext context) {
    Analytics().logSelect(target: "Gies Checklist");
    CheckListPanel.present(context, contentKey: CheckList.giesOnboarding, analyticsFeature: AnalyticsFeature.AcademicsGiesChecklist);
  }

  static void _onTapNewStudentChecklist(BuildContext context) {
    Analytics().logSelect(target: "New Student Checklist");
    CheckListPanel.present(context, contentKey: CheckList.uiucOnboarding, analyticsFeature: AnalyticsFeature.AcademicsChecklist);
  }

  static void _onTapSkillSelfEvaluation(BuildContext context) {
    Analytics().logSelect(target: "Skills Self-Evaluation");
    AcademicsHomePanel.push(context, AcademicsContentType.skills_self_evaluation);
  }

  static void _onTapEssentialSkillCoach(BuildContext context) {
    Analytics().logSelect(target: "Essential Skills Coach");
    AcademicsHomePanel.push(context, AcademicsContentType.essential_skills_coach);
  }

  static void _onTapAcademicsToDo(BuildContext context) {
    Analytics().logSelect(target: "Academics To Do");
    AcademicsHomePanel.push(context, AcademicsContentType.todo_list);
  }

  static void _onTapCanvasCourses(BuildContext context) {
    Analytics().logSelect(target: "Canvas Courses");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCoursesListPanel()));
  }

  static void _onTapGiesCanvasCourses(BuildContext context) {
    Analytics().logSelect(target: "Gies Canvas Courses");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GiesCanvasCoursesListPanel()));
  }

  static void _onTapStudentCourses(BuildContext context) {
    Analytics().logSelect(target: "Student Courses");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentCoursesListPanel()));
  }

  static void _onTapCampusReminders(BuildContext context) {
    Analytics().logSelect(target: "Campus Reminders");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(
      contentList: Guide().remindersList,
      contentTitle: Localization().getStringEx('panel.guide_list.label.campus_reminders.section', 'Campus Reminders'),
      contentEmptyMessage: Localization().getStringEx("panel.guide_list.label.campus_reminders.empty", "There are no active Campus Reminders."),
      analyticsFeature: AnalyticsFeature.AcademicsCampusReminders,
    )));
  }

  static void _onTapSportEvents(BuildContext context) {
    Analytics().logSelect(target: "Events");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel(contentType: AthleticsContentType.events)));
  }

  static void _onTapSportNews(BuildContext context) {
    Analytics().logSelect(target: "News");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel(contentType: AthleticsContentType.news)));
  }

  static void _onTapSportTeams(BuildContext context) {
    Analytics().logSelect(target: "Teams");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel(contentType: AthleticsContentType.teams)));
  }

  static void _onTapCampusHighlights(BuildContext context) {
    Analytics().logSelect(target: 'Campus Highlights');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(
      contentList: Guide().promotedList,
      contentTitle: Localization().getStringEx('panel.guide_list.label.highlights.section', 'Campus Highlights'),
      contentEmptyMessage: Localization().getStringEx("panel.guide_list.label.highlights.empty", "There are no active Campus Hightlights."),
      favoriteKey: GuideFavorite.constructFavoriteKeyName(contentType: Guide.campusHighlightContentType),
    )));
  }

  static void _onTapDueDateCatalog(BuildContext context) {
    Analytics().logSelect(target: "Due Date Catalog");
    if (StringUtils.isNotEmpty(Config().dateCatalogUrl)) {
      _launchUrl(context, Config().dateCatalogUrl);
    }
  }

  static void _onTapDiningsAll(BuildContext context) {
    Analytics().logSelect(target: "HomeDiningWidget: Residence Hall Dining");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DiningHomePanel(
      analyticsFeature: AnalyticsFeature.DiningAll
    )));
  }

  static void _onTapDiningsOpen(BuildContext context) {
    Analytics().logSelect(target: "HomeDiningWidget: Residence Hall Dining Open Now");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DiningHomePanel(
      initialFilter: DiningFilter(type: DiningFilterType.work_time, selectedIndexes: {1}),
      analyticsFeature: AnalyticsFeature.DiningOpen,
    )));
  }

  static void _onTapUserDirectory(BuildContext context) {
    Analytics().logSelect(target: "Directory of Users");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return DirectoryAccountsPanel(); } ));
  }

  static void _onTapLaundry(BuildContext context) {
    Analytics().logSelect(target: "Laundry");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryHomePanel()));
  }

  static void _onTapMessages(BuildContext context) {
    Analytics().logSelect(target: "Messages");
    MessagesHomePanel.present(context);
  }

  static void _onTapMTDStops(BuildContext context) {
    Analytics().logSelect(target: "All Bus Stops");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => MTDStopsHomePanel(scope: MTDStopsScope.all,)));
  }

  static void _onTapCampusGuide(BuildContext context) {
    Analytics().logSelect(target: "Campus Guide");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CampusGuidePanel()));
  }

  static void _onTapEventFeed(BuildContext context) {
    Analytics().logSelect(target: "Events Feed");
    Event2HomePanel.present(context,
      analyticsFeature: AnalyticsFeature.EventsAll,
    );
  }

  static void _onTapMyEvents(BuildContext context) {
    Analytics().logSelect(target: "My Events");
    Event2HomePanel.present(context,
      types: LinkedHashSet<Event2TypeFilter>.from([Event2TypeFilter.favorite]),
      analyticsFeature: AnalyticsFeature.EventsMy,
    );
  }

  static void _onTapTwitter(BuildContext context) {
    Analytics().logSelect(target: "Twitter");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return TwitterPanel(); } ));
  }

  static void _onTapDailyIllini(BuildContext context) {
    Analytics().logSelect(target: "Daily Illini");
    _launchUrl(context, Config().dailyIlliniHomepageUrl);
  }

  static void _onTapRadioStation(BuildContext context, RadioStation radioStation) {
    Analytics().logSelect(target: "Radio Station: ${RadioPopupWidget.stationTitle(radioStation)}");
    RadioPopupWidget.show(context, radioStation);
  }

  static void _onTapAllGroups(BuildContext context) {
    Analytics().logSelect(target: "All Groups");
    Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: GroupsHomePanel.routeName), builder: (context) => GroupsHomePanel(contentType: GroupsContentType.all,)));
  }

  static void _onTapMyGroups(BuildContext context) {
    Analytics().logSelect(target: "My Groups");
    Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: GroupsHomePanel.routeName), builder: (context) => GroupsHomePanel(contentType: GroupsContentType.my)));
  }

  static void _onTapOpenResearchProjects(BuildContext context) {
    Analytics().logSelect(target: "Open Research Projects");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ResearchProjectsHomePanel(contentType: ResearchProjectsContentType.open,)));
  }

  static void _onTapMyResearchProjects(BuildContext context) {
    Analytics().logSelect(target: "My Research Projects");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ResearchProjectsHomePanel(contentType: ResearchProjectsContentType.my)));
  }

  static void _onTapMyGameDay(BuildContext context) {
    Analytics().logSelect(target: "It's Game Day");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel(contentType: AthleticsContentType.game_day)));
  }

  static void _onTapMyDinings(BuildContext context) {
    Analytics().logSelect(target: "My Dinings");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return SavedPanel(favoriteCategories: [Dining.favoriteKeyName]); } ));
  }

  static void _onTapMyAthletics(BuildContext context) {
    Analytics().logSelect(target: "My Big 10 Events");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel(contentType: AthleticsContentType.my_events)));
  }

  static void _onTapMyNews(BuildContext context) {
    Analytics().logSelect(target: "My News");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel(contentType: AthleticsContentType.my_news)));
  }

  static void _onTapMyLaundry(BuildContext context) {
    Analytics().logSelect(target: "My Laundry");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return SavedPanel(favoriteCategories: [LaundryRoom.favoriteKeyName]); } ));
  }

  static void _onTapMyMTDStops(BuildContext context) {
    Analytics().logSelect(target: "My Bus Stops");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => MTDStopsHomePanel(scope: MTDStopsScope.my,)));
  }

  static void _onTapMyLocations(BuildContext context) {
    Analytics().logSelect(target: "My Locations");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return SavedPanel(favoriteCategories: [ExplorePOI.favoriteKeyName]); } ));
  }

  static void _onTapMyCampusGuide(BuildContext context) {
    Analytics().logSelect(target: "My Campus Guide");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return SavedPanel(favoriteCategories: [GuideFavorite.favoriteKeyName]); } ));
  }

  static void _onTapWellnessResources(BuildContext context) {
    Analytics().logSelect(target: "Wellness Resources");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return WellnessHomePanel(contentType: WellnessContentType.resources,); } ));
  }

  static void _onTapWellnessRecreation(BuildContext context) {
    Analytics().logSelect(target: "Campus Recreation");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return WellnessHomePanel(contentType: WellnessContentType.recreation,); } ));
  }

  static void _onTapWellnessMentalHealth(BuildContext context) {
    Analytics().logSelect(target: "Wellness Resources");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return WellnessHomePanel(contentType: WellnessContentType.mentalHealth,); } ));
  }

  static void _onTapWellnessAppointments(BuildContext context) {
    Analytics().logSelect(target: "MyMcKinley Appointments");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return WellnessHomePanel(contentType: WellnessContentType.appointments); } ));
  }

  static void _onTapAppointments(BuildContext context, { AnalyticsFeature? analyticsFeature }) {
    Analytics().logSelect(target: "Appointments");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AppointmentsListPanel(analyticsFeature: analyticsFeature,)));
  }

  static void _onTapAcademicsMyIllini(BuildContext context) {
    Analytics().logSelect(target: "myIllini");
    _launchUrl(context, Config().myIlliniUrl);
  }

  static void _onTapCreatePoll(BuildContext context) {
    Analytics().logSelect(target: "Create Poll");
    CreatePollPanel.present(context);
  }

  static void _onTapViewPolls(BuildContext context) {
    Analytics().logSelect(target: "View Polls");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PollsHomePanel()));
  }

  static void _onTapRecentItems(BuildContext context) {
    Analytics().logSelect(target: "Recent Items");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => HomeRecentItemsPanel()));
  }

  static void _onTapSafewalkRequest(BuildContext context) {
    Analytics().logSelect(target: "Request a SafeWalk");
    if (FlexUI().isSafeWalkAvailable) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SafetyHomePanel()));
    }
    else {
      AppAlert.showDialogResult(context, Localization().getStringEx("model.safety.safewalks.not_available.text", "SafeWalk feature is not currently available."));
    }
  }

  static void _onTapSafeRides(BuildContext context) {
    Analytics().logSelect(target: "SafeRides (MTD)");
    Map<String, dynamic>? safeRidesGuideEntry = Guide().entryById(Config().safeRidesGuideId);
    if (safeRidesGuideEntry != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideDetailPanel(guideEntry: safeRidesGuideEntry)));
    }
    else {
      AppAlert.showDialogResult(context, Localization().getStringEx("model.safety.saferides.not_available.text", "SafeRides feature is not currently available."));
    }
  }

  static void _onTapSafetyResources(BuildContext context) {
    Analytics().logSelect(target: "Safety Resources");
    List<Map<String, dynamic>>? safetyResourcesList = Guide().safetyResourcesList;
    if (CollectionUtils.isNotEmpty(safetyResourcesList)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(
        contentList: safetyResourcesList,
        contentTitle: Localization().getStringEx('panel.guide_list.label.campus_safety_resources.section', 'Safety Resources'),
        contentEmptyMessage: Localization().getStringEx("panel.guide_list.label.campus_safety_resources.empty", "There are no active Campus Safety Resources."),
        favoriteKey: GuideFavorite.constructFavoriteKeyName(contentType: Guide.campusSafetyResourceContentType),
      )));
    }
    else {
      AppAlert.showDialogResult(context, Localization().getStringEx("model.safety.safety_resources.not_available.text", "Safety Resources are not currently available."));
    }
  }

  static void _onTapPublicSurveys(BuildContext context) {
    Analytics().logSelect(target: "Public Surveys");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PublicSurveysPanel()));
  }

  static void _onTapIlliniCash(BuildContext context) {
    Analytics().logSelect(target: "Illini Cash");
    WalletHomePanel.present(context, contentType: WalletContentType.illiniCash);
  }

  static void _onTapAddIlliniCash(BuildContext context) {
    Analytics().logSelect(target: "Add Illini Cash");
    WalletHomePanel.present(context, contentType: WalletContentType.addIlliniCash);
  }

  static void _onTapMealPlan(BuildContext context) {
    Analytics().logSelect(target: "Meal Plan");
    WalletHomePanel.present(context, contentType: WalletContentType.mealPlan);
  }

  static void _onTapBusPass(BuildContext context) {
    Analytics().logSelect(target: "Bus Pass");
    WalletHomePanel.present(context, contentType: WalletContentType.busPass);
  }

  static void _onTapIlliniId(BuildContext context) {
    Analytics().logSelect(target: "Illini ID");
    WalletHomePanel.present(context, contentType: WalletContentType.illiniId);
  }

  static void _onTapWellnessRings(BuildContext context) {
    Analytics().logSelect(target: "Wellness Daily Rings");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(contentType: WellnessContentType.rings,)));
  }

  static void _onTapWellnessToDo(BuildContext context) {
    Analytics().logSelect(target: "Wellness To Do");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(contentType: WellnessContentType.todo,)));
  }

  static void _onTapWellnessTips(BuildContext context) {
    Analytics().logSelect(target: "Wellness Daily Tips");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(contentType: WellnessContentType.dailyTips,)));
  }

  static void _onTapWellnessHealthScreener(BuildContext context) {
    Analytics().logSelect(target: "Illinois Health Screener");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(contentType: WellnessContentType.healthScreener,)));
  }

  static void _onTapWellnessSuccessTeam(BuildContext context) {
    Analytics().logSelect(target: "My Primary Care Provider");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(contentType: WellnessContentType.successTeam,)));
  }

  // ignore: unused_element
  static void _notImplemented(BuildContext context) {
    AppAlert.showDialogResult(context, "Not implemented yet.");
  }

  static void _launchUrl(BuildContext context, String? url, {bool launchInternal = false}) {
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else {
        bool tryInternal = launchInternal && UrlUtils.canLaunchInternal(url);
        AppLaunchUrl.launch(context: context, url: url, tryInternal: tryInternal);
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

class _BrowseToutWidgetState extends State<_BrowseToutWidget> with NotificationsListener {

  String? _imageUrl;
  DateTime? _imageDateTime;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
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
      ModalImageHolder(child: WebNetworkImage(imageUrl: _imageUrl, semanticLabel: 'tout', loadingBuilder:(  BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
        double imageWidth = MediaQuery.of(context).size.width;
        double imageHeight = imageWidth * 810 / 1080;
        return (loadingProgress != null) ?
          Container(color: Styles().colors.fillColorPrimary, width: imageWidth, height: imageHeight, child:
            Center(child:
              CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.white), )
            ),
          ) :
          AspectRatio(aspectRatio: (1080.0 / 810.0), child:
            Container(color: Styles().colors.fillColorPrimary, child: child)
          );
      })),
      Positioned.fill(child:
        Align(alignment: Alignment.bottomCenter, child:
          Column(mainAxisSize: MainAxisSize.min, children: [
            CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.fillColorSecondaryTransparent05, horzDir: TriangleHorzDirection.rightToLeft, vertDir: TriangleVertDirection.topToBottom), child:
              Container(height: 40)
            ),
            Container(height: 20, color: Styles().colors.fillColorSecondaryTransparent05),
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
    if ((name == AppLivecycle.notifyStateChanged) && (param == AppLifecycleState.resumed)) {
      _update();
    }
    else if (name == Content.notifyContentImagesChanged) {
      _update();
    }
  }
}

class _BrowseSlantWidget extends StatelessWidget {

  static const EdgeInsetsGeometry defaultChildPadding = const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 16);
  final double flatHeight = 40;
  final double slantHeight = 60;
  final EdgeInsetsGeometry childPadding;
  final Widget child;

  const _BrowseSlantWidget({Key? key, required this.child,  required this.childPadding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return
      Stack(children:<Widget>[
        // Slant
        Column(children: <Widget>[
          Container(color: Styles().colors.fillColorPrimary, height: flatHeight,),
          Container(color: Styles().colors.fillColorPrimary, child:
            CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.background, horzDir: TriangleHorzDirection.rightToLeft), child:
              Container(height: slantHeight,),
            ),
          ),
        ],),

        // Content
        Padding(padding: childPadding, child:
          child
        )
      ]);
  }
}
