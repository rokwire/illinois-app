
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/research/ResearchProjectsHomePanel.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
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
  DateTime? _pausedDateTime;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  final double _pageSpacing = 16;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
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

  void _loadResearchProjects(){
    Groups().loadResearchProjects(contentType: widget.contentType).then((List<Group>? researchProjects) {
      _sortResearchProjects(researchProjects);
      if (mounted) {
        setState(() {
          _researchProjects = researchProjects;
        });
      }
    });
  }

  void _updateResearchProjects() {
    Groups().loadResearchProjects(contentType: widget.contentType).then((List<Group>? researchProjects) {
      _sortResearchProjects(researchProjects);
      if (mounted && !DeepCollectionEquality().equals(_researchProjects, researchProjects)) {
        setState(() {
          _researchProjects = researchProjects;
          _pageViewKey = UniqueKey();
          _pageController = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: widget._title,
      titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
      child: _haveResearchProjects ? _buildContent() : _buildEmpty(),
    );
  }


  Widget _buildContent() {

    List<Widget> pages = <Widget>[];
    if(_researchProjects?.isNotEmpty ?? false) {
      for (Group? researchProject in _researchProjects!) {
        if ((researchProject != null) && researchProject.isVisible) {
          pages.add(Padding(padding: EdgeInsets.only(right: _pageSpacing), child:
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
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: pages.length,),
      LinkButton(
        title: Localization().getStringEx('widget.home.research_projects.button.all.title', 'View All'),
        hint: Localization().getStringEx('widget.home.research_projects.button.all.hint', 'Tap to view all research projects'),
        onTap: _onSeeAll,
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
    String message;
    switch(widget.contentType) {
      case ResearchProjectsContentType.my: message = Localization().getStringEx('widget.home.research_projects.my.text.empty.description', 'You have not created any research projects yet.'); break;
      case ResearchProjectsContentType.open: message = Localization().getStringEx('widget.home.research_projects.all.text.empty.description', 'Failed to load research projects.'); break;
    }
    return HomeMessageCard(message: message,);
  }

  @override
  void onNotification(String name, param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == Auth2.notifyLoginChanged) {
      _loadResearchProjects();
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

  bool get _haveResearchProjects {
    return _researchProjects?.isNotEmpty ?? false;
  }

  void _onSeeAll() {
    Analytics().logSelect(target: "View All", source: '${widget.runtimeType}(${widget.contentType})' );
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ResearchProjectsHomePanel(contentType: widget.contentType,)));
  }
}