
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Questionnaire.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ResearchQuestionnaireAcknowledgementPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ResearchQuestionnairePanel.dart';
import 'package:illinois/ui/research/ResearchProjectsHomePanel.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';

class HomeResearchProjectsWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;
  final ResearchProjectsContentType contentType;

  const HomeResearchProjectsWidget({Key? key, required this.contentType, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({required ResearchProjectsContentType contentType, Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: titleForContentType(contentType),
    );

  String get _title => titleForContentType(contentType);
  
  static String title({required ResearchProjectsContentType contentType}) => titleForContentType(contentType);

  static String titleForContentType(ResearchProjectsContentType contentType) {
    switch(contentType) {
      case ResearchProjectsContentType.open: return Localization().getStringEx('panel.research_projects.home.content_type.open.title', 'Open Research Projects');
      case ResearchProjectsContentType.my: return Localization().getStringEx('panel.research_projects.home.content_type.my.title', 'My Research Participation');
    }
  }

  @override
  State<StatefulWidget> createState() => _HomeGroupsWidgetState();
}

class _HomeGroupsWidgetState extends State<HomeResearchProjectsWidget> implements NotificationsListener {

  List<Group>? _researchProjects;
  bool _loadingResearchProjects = false;
  DateTime? _pausedDateTime;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  final double _pageSpacing = 16;

  static const String localScheme = 'local';
  static const String openProjectsHost = 'open_projects';
  static const String openProjectsUrlMacro = '{{open_projects_url}}';
  static const String questionnaireHost = 'questionnaire';
  static const String questionnaireUrlMacro = '{{questionnaire_url}}';

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Auth2.notifyLoginChanged,
      AppLivecycle.notifyStateChanged,]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _updateResearchProjects();
        }
      });
    }

    _loadResearchProjects();
  }

  @override
  void dispose() {
    super.dispose();
    _pageController?.dispose();
    NotificationService().unsubscribe(this);
  }

  void _loadResearchProjects() {
    if (mounted) {
      setState(() {
        _loadingResearchProjects = true;
      });
      Groups().loadResearchProjects(contentType: widget.contentType).then((List<Group>? researchProjects) {
        _sortResearchProjects(researchProjects);
        if (mounted) {
          setState(() {
            _researchProjects = researchProjects;
            _loadingResearchProjects = false;
          });
        }
      });
    }
  }

  void _updateResearchProjects() {
    Groups().loadResearchProjects(contentType: widget.contentType).then((List<Group>? researchProjects) {
      _sortResearchProjects(researchProjects);
      if (mounted && !DeepCollectionEquality().equals(_researchProjects, researchProjects)) {
        setState(() {
          _researchProjects = researchProjects;
          _pageViewKey = UniqueKey();
          // _pageController = null;
          _pageController?.jumpToPage(0);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: widget._title,
      titleIconKey: 'research',
      child: _buildContent(),
    );
  }
  Widget _buildContent() {
    if (Connectivity().isOffline) {
      return HomeMessageCard(
        title: Localization().getStringEx("common.message.offline", "You appear to be offline"),
        message: Localization().getStringEx('widget.home.research_projects.message.offline', 'Research Projects are not available while offline.'),
      );
    }
    else if (!Auth2().isLoggedIn) {
      return HomeMessageCard(
        title: Localization().getStringEx("common.message.logged_out", "You are not logged in"),
        message: Localization().getStringEx('widget.home.research_projects.message.logged_out', 'You need to be logged in to access Research Projects.'),
      );
    }
    else if (_loadingResearchProjects) {
      return HomeProgressWidget();
    }
    else if (_researchProjects?.isEmpty ?? true) {
      return _buildEmpty();
    }
    else {
      return _buildProjects();
    }
  }

  Widget _buildProjects() {

    List<Widget> pages = <Widget>[];
    if(_researchProjects?.isNotEmpty ?? false) {
      for (Group? researchProject in _researchProjects!) {
        if ((researchProject != null) && researchProject.isVisible) {
          pages.add(Padding(padding: EdgeInsets.only(right: _pageSpacing, bottom: 16), child:
            Semantics(
              // excludeSemantics: !(_pageController?.page == _researchProjects?.indexOf(researchProject)),
             child: GroupCard(group: researchProject, displayType: GroupCardDisplayType.homeGroups, margin: EdgeInsets.zero,),
          )));
        }
      }
    }

    double pageHeight = 90 * 2 * MediaQuery.of(context).textScaleFactor;

    if (_pageController == null) {
      double screenWidth = MediaQuery.of(context).size.width;
      double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
      _pageController = PageController(viewportFraction: pageViewport);
    }

    return Column(children: [
      Container(height: pageHeight, child:
        PageView(
          key: _pageViewKey,
          controller: _pageController,
          children: pages,
          allowImplicitScrolling : true,
        )
      ),
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => pages.length, centerWidget:
        LinkButton(
          title: Localization().getStringEx('widget.home.research_projects.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.research_projects.button.all.hint', 'Tap to view all research projects'),
          onTap: _onSeeAll,
        ),
      ),
    ],);

  }

  List<Group>? _sortResearchProjects(List<Group>? researchProjects){
    if(researchProjects?.isNotEmpty ?? false){
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

  Widget _buildEmpty() {
    if (widget.contentType == ResearchProjectsContentType.open) {
      return HomeMessageCard(message: Localization().getStringEx('widget.home.research_projects.all.text.empty.description', 'There are no opened research projects at the moment.'));
    }
    else if (widget.contentType == ResearchProjectsContentType.my) {
      if (Auth2().account?.isResearchProjectAdmin ?? false) {
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
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2ResearchQuestionnairePanel(onboardingContext: {
      "onContinueAction": () {
        _didResearchQuestionnaire();
      }
    },)));
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

  @override
  void onNotification(String name, param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == Auth2.notifyLoginChanged) {
      _loadResearchProjects();
    }
    else if (name == Connectivity.notifyStatusChanged) {
      if (mounted) {
        setState(() {});
      }
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
          _updateResearchProjects();
        }
      }
    }
  }

  void _onSeeAll() {
    Analytics().logSelect(target: "View All", source: '${widget.runtimeType}(${widget.contentType})' );
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ResearchProjectsHomePanel(contentType: widget.contentType,)));
  }
}