
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Questionnaire.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/accessibility/AccessiblePageView.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ResearchQuestionnaireAcknowledgementPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ResearchQuestionnairePanel.dart';
import 'package:illinois/ui/research/ResearchProjectsHomePanel.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HomeResearchProjectsWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeResearchProjectsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  String get _title => title;
  static String get title => Localization().getStringEx('widget.home.research_projects.label.header.title', 'Research Participation');

  @override
  State<StatefulWidget> createState() => _HomeResearchProjectsWidgetState();
}

class _HomeResearchProjectsWidgetState extends State<HomeResearchProjectsWidget> {
  late FavoriteContentType _contentType;

  @override
  void initState() {
    _contentType = FavoritesContentTypeImpl.fromJson(Storage().getHomeFavoriteSelectedContent(widget.favoriteId)) ?? FavoriteContentType.all;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return HomeFavoriteWidget(favoriteId: widget.favoriteId, title: widget._title, child:
      _contentWidget,
    );
  }

  Widget get _contentWidget => Column(mainAxisSize: MainAxisSize.min, children: [
    Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 8), child:
      _contentTypeBar,
    ),
    ..._contentTypeWidgets,
  ],);

  Iterable<Widget> get _contentTypeWidgets => FavoriteContentType.values.map((FavoriteContentType contentType) =>
    Visibility(visible: (_contentType == contentType), maintainState: true, child:
    _HomeResearchProjectsImplWidget(contentType.researchProjectsContentType,
        updateController: widget.updateController,
      ),
    ));

  Widget get _contentTypeBar => Row(children:List<Widget>.from(
    FavoriteContentType.values.map((FavoriteContentType contentType) => Expanded(child:
      HomeFavTabBarBtn(contentType.researchProjectTitle.toUpperCase(),
        position: contentType.position,
        selected: _contentType == contentType,
        onTap: () => _onContentType(contentType),
      )
    )),
  ));

  void _onContentType(FavoriteContentType contentType) {
    if ((_contentType != contentType) && mounted) {
      setState(() {
        _contentType = contentType;
        Storage().setHomeFavoriteSelectedContent(widget.favoriteId, contentType.toJson());
      });
    }
  }
}

class _HomeResearchProjectsImplWidget extends StatefulWidget {
  final ResearchProjectsContentType contentType;
  final StreamController<String>? updateController;

  // ignore: unused_element_parameter
  const _HomeResearchProjectsImplWidget(this.contentType, {super.key, this.updateController});

  @override
  State<StatefulWidget> createState() => _HomeResearchProjectsImplWidgetState();
}

class _HomeResearchProjectsImplWidgetState extends State<_HomeResearchProjectsImplWidget> with NotificationsListener {

  List<Group>? _researchProjects;
  bool _loadingResearchProjects = false;
  bool _updatingResearchProjects = false;

  bool _visible = false;
  Key _visibilityDetectorKey = UniqueKey();
  DateTime? _pausedDateTime;
  FavoriteContentStatus _contentStatus = FavoriteContentStatus.none;

  Map<String, GlobalKey> _researchProjectsCardKeys = <String, GlobalKey>{};
  PageController? _pageController;
  Key _pageViewKey = UniqueKey();

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Auth2.notifyLoginChanged,
      AppLivecycle.notifyStateChanged,]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _updateResearchProjectsIfVisible();
        }
      });
    }

    _loadResearchProjects();

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void onNotification(String name, param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if ((name == Connectivity.notifyStatusChanged) ||
        (name == Auth2.notifyLoginChanged)
    ) {
      _loadResearchProjectsIfVisible();
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateResearchProjectsIfVisible();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => VisibilityDetector(
    key: _visibilityDetectorKey,
    onVisibilityChanged: _onVisibilityChanged,
    child: _contentWidget,
  );

  Widget get _contentWidget {
    if (Connectivity().isOffline) {
      return HomeMessageCard(
        title: Localization().getStringEx("common.message.offline", "You appear to be offline"),
        message: Localization().getStringEx('widget.home.research_projects.message.offline', 'Research Projects are not available while offline.'),
      );
    }
    else if (!Auth2().isLoggedIn) {
      return HomeMessageCard(
        title: Localization().getStringEx("common.message.logged_out", "You are not logged in"),
        message: AppTextUtils.loggedOutFeatureNA(Localization().getStringEx('generic.app.feature.research_projects', 'Research Projects'), verbose: true),
      );
    }
    else if (_loadingResearchProjects) {
      return HomeProgressWidget();
    }
    else {
      return _researchProjectsContentWidget;
    }
  }

  Widget get _researchProjectsContentWidget {

    Widget? contentWidget;
    List<Group>? visibleResearchProjects = _visibleResearchProjects(_researchProjects);
    int visibleCount = visibleResearchProjects?.length ?? 0;

    if (1 < visibleCount) {
      List<Widget> pages = <Widget>[];
      for (Group researchProject in visibleResearchProjects!) {
        GlobalKey researchProjectKey = (_researchProjectsCardKeys[researchProject.id!] ??= GlobalKey());
        pages.add(Padding(
          padding: HomeCard.defaultPageMargin,
          child: Semantics(// excludeSemantics: !(_pageController?.page == _researchProjects?.indexOf(researchProject)),
           child: GroupCard(key: researchProjectKey, group: researchProject, displayType: GroupCardDisplayType.homeGroups, margin: EdgeInsets.zero,),
          )
        ));
      }

      if (_pageController == null) {
        double screenWidth = MediaQuery.of(context).size.width;
        double pageViewport = (screenWidth - 2 * HomeCard.pageSpacing) / screenWidth;
        _pageController = PageController(viewportFraction: pageViewport);
      }

      contentWidget = Container(constraints: BoxConstraints(minHeight: _pageHeight), child:
        AccessiblePageView(
          key: _pageViewKey,
          controller: _pageController,
          estimatedPageSize: _pageHeight,
          allowImplicitScrolling : true,
          children: pages,
        )
      );
    }
    else if (visibleCount == 1) {
      contentWidget = Padding(padding: HomeCard.defaultSingleCardMargin, child:
        Semantics(/* excludeSemantics: !(_pageController?.page == _groups?.indexOf(group)),*/ child:
         GroupCard(group: visibleResearchProjects!.first, displayType: GroupCardDisplayType.homeGroups, margin: EdgeInsets.zero,),
        )
      );
    }

    return (contentWidget != null) ? Column(children: [
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => visibleCount, centerWidget:
      HomeBrowseLinkButton(
          title: Localization().getStringEx('widget.home.research_projects.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.research_projects.button.all.hint', 'Tap to view all research projects'),
          onTap: _onSeeAll,
        ),
      ),
    ],) : _emptyContentWidget;
  }

  double get _pageHeight {

    double? minContentHeight;
    for(GlobalKey contentKey in _researchProjectsCardKeys.values) {
      final RenderObject? renderBox = contentKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && renderBox.hasSize && ((minContentHeight == null) || (renderBox.size.height < minContentHeight))) {
        minContentHeight = renderBox.size.height;
      }
    }

    return minContentHeight ?? 0;
  }

  static const String localScheme = 'local';
  static const String openProjectsHost = 'open_projects';
  static const String openProjectsUrlMacro = '{{open_projects_url}}';
  static const String questionnaireHost = 'questionnaire';
  static const String questionnaireUrlMacro = '{{questionnaire_url}}';

  Widget get _emptyContentWidget {
    if (widget.contentType == ResearchProjectsContentType.open) {
      return HomeMessageCard(message: Localization().getStringEx('widget.home.research_projects.all.text.empty.description', 'There are no opened research projects at the moment.'));
    }
    else if (widget.contentType == ResearchProjectsContentType.my) {
      if (Auth2().isResearchProjectAdmin) {
        return HomeMessageCard(message: Localization().getStringEx('widget.home.research_projects.my.text.empty.admin.description', 'You have not created any research projects yet.'));
      }
      else {
        String message = Localization().getStringEx("widget.home.research_projects.my.html.empty.user.description", "You are currently not participating in any research projects. <a href='{{open_projects_url}}'>View current studies</a> that match your <a href='{{questionnaire_url}}'>Research Interest Form</a> to opt in and become part of the study’s recruitment pool.")
          .replaceAll(openProjectsUrlMacro, '$localScheme://$openProjectsHost')
          .replaceAll(questionnaireUrlMacro, '$localScheme://$questionnaireHost');

        return HomeMessageHtmlCard(message: message, onTapLink: _onMessageLink,);
      }
    }
    else {
      return Container();
    }
  }


  // Visibility

  void _onVisibilityChanged(VisibilityInfo info) {
    _updateInternalVisibility(!info.visibleBounds.isEmpty);
  }

  void _updateInternalVisibility(bool visible) {
    if (_visible != visible) {
      _visible = visible;
      _onInternalVisibilityChanged();
    }
  }

  void _onInternalVisibilityChanged() {
    if (_visible) {
      switch(_contentStatus) {
        case FavoriteContentStatus.none: break;
        case FavoriteContentStatus.refresh: _updateResearchProjects(); break;
        case FavoriteContentStatus.reload: _loadResearchProjects(); break;
      }
    }
  }

  // Content Data

  Future<void> _loadResearchProjectsIfVisible() async {
    if (_visible) {
      return _loadResearchProjects();
    }
    else if (_contentStatus.index < FavoriteContentStatus.reload.index) {
      _contentStatus = FavoriteContentStatus.reload;
    }
  }

  Future<void> _loadResearchProjects() async {
    if ((_loadingResearchProjects == false) && mounted) {
      setState(() {
        _loadingResearchProjects = true;
        _updatingResearchProjects = true;
      });

      List<Group>? researchProjects = await Groups().loadResearchProjects(contentType: widget.contentType);
      _sortResearchProjects(researchProjects);

      setStateIfMounted(() {
        _researchProjects = researchProjects;
        _contentStatus = FavoriteContentStatus.none;
        _loadingResearchProjects = false;
        _researchProjectsCardKeys.clear();
      });
    }
  }

  Future<void> _updateResearchProjectsIfVisible() async {
    if (_visible) {
      return _updateResearchProjects();
    }
    else if (_contentStatus.index < FavoriteContentStatus.refresh.index) {
      _contentStatus = FavoriteContentStatus.refresh;
    }
  }

  Future<void> _updateResearchProjects() async {
    if ((_loadingResearchProjects == false) && (_updatingResearchProjects == false) && mounted) {
      setState(() {
        _updatingResearchProjects = true;
      });
    }

    List<Group>? researchProjects = await Groups().loadResearchProjects(contentType: widget.contentType);
    _sortResearchProjects(researchProjects);

    if (mounted && _updatingResearchProjects && (researchProjects != null) && !DeepCollectionEquality().equals(_researchProjects, researchProjects)) {
      setState(() {
        _researchProjects = researchProjects;
        _contentStatus = FavoriteContentStatus.none;
        _updatingResearchProjects = false;
        _pageViewKey = UniqueKey();
        _researchProjectsCardKeys.clear();
        // _pageController = null;
        if ((_researchProjects?.isNotEmpty == true) && (_pageController?.hasClients == true)) {
          _pageController?.jumpToPage(0);
        }
      });
    }
  }

  List<Group>? _sortResearchProjects(List<Group>? researchProjects){
    if (researchProjects?.isNotEmpty ?? false){
      researchProjects!.sort((group1, group2) {
        if (group2.dateUpdatedUtc == null) {
          return -1;
        }
        if (group1.dateUpdatedUtc == null) {
          return 1;
        }

        return group2.dateUpdatedUtc!.compareTo(group1.dateUpdatedUtc!);
      });
    }

    return researchProjects;
  }

  List<Group>? _visibleResearchProjects(List<Group>? researchProjects) {
    List<Group>? visibleResearchProjects;
    if (researchProjects != null) {
      visibleResearchProjects = <Group>[];
      for (Group researchProject in researchProjects) {
        if ((researchProject.id != null) && researchProject.isVisible) {
          visibleResearchProjects.add(researchProject);
        }
      }
    }
    return visibleResearchProjects;
  }

  // Event Handlers

  void _onMessageLink(String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if (uri?.scheme == localScheme) {
      if (uri?.host.toLowerCase() == openProjectsHost.toLowerCase()) {
        _onOpenResearchProjectsLink();
      }
      else if (uri?.host.toLowerCase() == questionnaireHost.toLowerCase()) {
        _onResearchQuestionnaireLink();
      }
    }
  }

  void _onOpenResearchProjectsLink() {
    Analytics().logSelect(target: "View Open Research Projects", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ResearchProjectsHomePanel(contentType: ResearchProjectsContentType.open,)));
  }

  void _onResearchQuestionnaireLink() {
    Analytics().logSelect(target: "View Research Interests Form", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2ResearchQuestionnairePanel(
      onContinue: _didResearchQuestionnaire,
    )));
  }

  void _didResearchQuestionnaire() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2ResearchQuestionnaireAcknowledgementPanel(onboardingContext: {
      "onContinueAction": () {
        Questionnaires().participateInResearch = true;
        _didAcknowledgeResearchQuestionnaire();
      }
    },)));
  }

  void _didAcknowledgeResearchQuestionnaire() {
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  void _onSeeAll() {
    Analytics().logSelect(target: "View All", source: '${widget.runtimeType}(${widget.contentType})' );
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ResearchProjectsHomePanel(contentType: widget.contentType,)));
  }
}

extension _FavoriteGroupsContentType on FavoriteContentType {
  String get researchProjectTitle {
    switch (this) {
      case FavoriteContentType.my: return Localization().getStringEx('widget.home.research_projects.my.label.header.title', 'My Projects');
      case FavoriteContentType.all: return Localization().getStringEx('widget.home.research_projects.open.label.header.title', 'Open Projects');
    }
  }

  ResearchProjectsContentType get researchProjectsContentType {
    switch (this) {
      case FavoriteContentType.my: return ResearchProjectsContentType.my;
      case FavoriteContentType.all: return ResearchProjectsContentType.open;
    }
  }
}

