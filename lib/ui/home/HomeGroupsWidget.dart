import 'dart:async';

import 'package:collection/collection.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/groups/GroupsHomePanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
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

class _HomeGroupsWidgetState extends State<HomeGroupsWidget> with NotificationsListener{
  List<Group>? _groups;
  Map<String, GlobalKey> _groupCardKeys = <String, GlobalKey>{};
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
    return HomeFavoriteWidget(
      favoriteId: widget.favoriteId,
      title: widget._title,
      child: _buildContent(),
    );
  }


  Widget _buildContent() {
    Widget? contentWidget;
    List<Group>? visibleGroups = _visibleGroups(_groups);
    int visibleCount = visibleGroups?.length ?? 0;

    if (1 < visibleCount) {
      List<Widget> pages = <Widget>[];
      for (Group group in visibleGroups!) {
        GlobalKey groupKey = (_groupCardKeys[group.id!] ??= GlobalKey());
        pages.add(Padding(padding: EdgeInsets.only(right: _pageSpacing, top: HomeCard.defaultShadowBlurRadius, bottom: HomeCard.defaultShadowBlurRadius), child:
          // Semantics(/*excludeSemantics: !(_pageController?.page == _groups?.indexOf(group)),*/ container: true,  child:
            GroupCard(key: groupKey, group: group, displayType: GroupCardDisplayType.homeGroups, margin: EdgeInsets.zero,),
          // )
        ));
      }

      if (_pageController == null) {
        double screenWidth = MediaQuery.of(context).size.width;
        double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
        _pageController = PageController(viewportFraction: pageViewport);
      }

      contentWidget = Container(constraints: BoxConstraints(minHeight: _pageHeight), child:
        ExpandablePageView(
          key: _pageViewKey,
          controller: _pageController,
          estimatedPageSize: _pageHeight,
          allowImplicitScrolling: true,
          children: pages,
        ),
      );
    }
    else if (visibleCount == 1) {
      contentWidget = Padding(padding: EdgeInsets.symmetric(horizontal: _pageSpacing), child:
        Semantics(/* excludeSemantics: !(_pageController?.page == _groups?.indexOf(group)),*/ container: true, child:
          GroupCard(group: visibleGroups!.first, displayType: GroupCardDisplayType.homeGroups, margin: EdgeInsets.zero,),
      ));
    }

    return (contentWidget != null) ? Column(children: [
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => visibleCount, centerWidget:
        HomeBrowseLinkButton(
          title: Localization().getStringEx('widget.home.groups.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.groups.button.all.hint', 'Tap to view all groups'),
          onTap: _onSeeAll,
        ),
        semanticsController: SemanticsController(
            adapter: SemanticsPageAdapter.fromList(keys: _groupCardKeys.values.toList())),
            // adapter: SemanticsPageAdapter.fromMap(keys: _groupCardKeys,
            //     mapper: (dynamic index) => index is int ? (visibleGroups?[index].id) : null))
      ),
    ],) : _buildEmpty();

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

  List<Group>? _visibleGroups(List<Group>? groups) {
    List<Group>? visibleGroups;
    if (groups != null) {
      visibleGroups = <Group>[];
      for (Group group in groups) {
        if ((group.id != null) && group.isVisible) {
          visibleGroups.add(group);
        }
      }
    }
    return visibleGroups;
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

  double get _pageHeight {

    double? minContentHeight;
    for(GlobalKey contentKey in _groupCardKeys.values) {
      final RenderObject? renderBox = contentKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && renderBox.hasSize && ((minContentHeight == null) || (renderBox.size.height < minContentHeight))) {
        minContentHeight = renderBox.size.height;
      }
    }

    return minContentHeight ?? 0;
  }

  void _onSeeAll() {
    Analytics().logSelect(target: "View All", source: '${widget.runtimeType}(${widget.contentType})' );
    Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: GroupsHomePanel.routeName), builder: (context) => GroupsHomePanel(contentType: widget.contentType,)));
  }

}