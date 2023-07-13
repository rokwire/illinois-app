import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/groups/GroupsHomePanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class HomeGroupsWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;
  final GroupsContentType contentType;

  const HomeGroupsWidget({Key? key, required this.contentType, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({required GroupsContentType contentType, Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: titleForContentType(contentType),
    );

  String get _title => titleForContentType(contentType);
  
  static String title({required GroupsContentType contentType}) => titleForContentType(contentType);

  static String titleForContentType(GroupsContentType contentType) {
    switch(contentType) {
      case GroupsContentType.my: return Localization().getStringEx('widget.home.groups.my.label.header.title', 'My Groups');
      case GroupsContentType.all: return Localization().getStringEx('widget.home.groups.all.label.header.title', 'All Groups');
    }
  }

  @override
  State<StatefulWidget> createState() => _HomeGroupsWidgetState();
}

class _HomeGroupsWidgetState extends State<HomeGroupsWidget> implements NotificationsListener{
  List<Group>? _groups;
  Map<String, Key> _groupCardKeys = <String, Key>{};
  DateTime? _pausedDateTime;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  final double _pageSpacing = 16;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      Groups.notifyUserMembershipUpdated,
      Groups.notifyGroupCreated,
      Groups.notifyGroupUpdated,
      Groups.notifyGroupDeleted,
      Groups.notifyUserGroupsUpdated,
      Auth2.notifyLoginChanged,
      AppLivecycle.notifyStateChanged,]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _updateGroups();
        }
      });
    }

    _loadGroups();
  }

  @override
  void dispose() {
    super.dispose();
    _pageController?.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  void onNotification(String name, param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if ((name == Groups.notifyGroupCreated) ||
      (name == Groups.notifyGroupUpdated) ||
      (name == Groups.notifyGroupDeleted) ||
      (name == Groups.notifyUserMembershipUpdated) ||
      (name == Auth2.notifyLoginChanged)) {
        _loadGroups();
    }
    else if (name == Groups.notifyUserGroupsUpdated) {
      _applyUserGroups();
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
          _updateGroups();
        }
      }
    }
  }

  void _loadGroups(){
    Groups().loadGroups(contentType: widget.contentType).then((List<Group>? groupsList) {
      List<Group>? groups = ListUtils.from(groupsList);
      _sortGroups(groups);
      if (mounted) {
        setState(() {
          _groups = groups;
          _groupCardKeys.clear();
        });
      }
    });
  }

  void _updateGroups() {
    Groups().loadGroups(contentType: widget.contentType).then((List<Group>? groupsList) {
      List<Group>? groups = ListUtils.from(groupsList);
      _sortGroups(groups);
      if (mounted && !DeepCollectionEquality().equals(_groups, groups)) {
        setState(() {
          _groups = groups;
          _pageViewKey = UniqueKey();
          _groupCardKeys.clear();
          // _pageController = null;
          _pageController?.jumpToPage(0);
        });
      }
    });
  }

  void _applyUserGroups() {
    if (widget.contentType == GroupsContentType.my) {
      List<Group>? userGroups = ListUtils.from(Groups().userGroups);
      _sortGroups(userGroups);
      if (mounted) {
        setState(() {
          _groups = userGroups;
          _groupCardKeys.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: widget._title,
      titleIconKey: 'groups',
      child: _haveGroups ? _buildContent() : _buildEmpty(),
    );
  }


  Widget _buildContent() {
    List<Widget> pages = <Widget>[];
    if(_groups?.isNotEmpty ?? false) {
      for (Group? group in _groups!) {
        if ((group != null) && group.isVisible) {
          Key groupKey = (_groupCardKeys[group.id] ?? UniqueKey());
          pages.add(Padding(padding: EdgeInsets.only(right: _pageSpacing, bottom: 16), child:
            Semantics(/* excludeSemantics: !(_pageController?.page == _groups?.indexOf(group)),*/ child:
              GroupCard(key: groupKey, group: group, displayType: GroupCardDisplayType.homeGroups, margin: EdgeInsets.zero,),
          )));
        }
      }
    }

    double pageHeight = 92 * 2 * MediaQuery.of(context).textScaleFactor;

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
          title: Localization().getStringEx('widget.home.groups.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.groups.button.all.hint', 'Tap to view all groups'),
          onTap: _onSeeAll,
        ),
      ),
    ],);

  }

  List<Group>? _sortGroups(List<Group>? groups){
    if(groups?.isNotEmpty ?? false){
      groups!.sort((group1, group2) {
        if (group2.dateUpdatedUtc == null) {
          return -1;
        }
        if (group1.dateUpdatedUtc == null) {
          return 1;
        }

        return group2.dateUpdatedUtc!.compareTo(group1.dateUpdatedUtc!);
      });
    }

    return groups;
  }

  Widget _buildEmpty() {
    String message;
    switch(widget.contentType) {
      case GroupsContentType.my:
        message = Localization().getStringEx('widget.home.groups.my.text.empty.description', 'You have not created any groups yet.');
        break;
      
      case GroupsContentType.all:
        message = Localization().getStringEx('widget.home.groups.all.text.empty.description', 'Failed to load groups.');
        break;
    }
    return HomeMessageCard(message: message,);
  }

  bool get _haveGroups{
    return _groups?.isNotEmpty ?? false;
  }

  void _onSeeAll() {
    Analytics().logSelect(target: "View All", source: '${widget.runtimeType}(${widget.contentType})' );
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupsHomePanel(contentType: widget.contentType,)));
  }
}