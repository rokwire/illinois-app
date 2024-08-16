import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/ui/groups/GroupsHomePanel.dart';
import 'package:neom/ui/home/HomePanel.dart';
import 'package:neom/ui/home/HomeWidgets.dart';
import 'package:neom/ui/widgets/LinkButton.dart';
import 'package:neom/ui/widgets/SemanticsWidgets.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:neom/service/Config.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:neom/ui/groups/GroupWidgets.dart';
import 'package:rokwire_plugin/service/styles.dart';
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
  Map<String, GlobalKey> _groupCardKeys = <String, GlobalKey>{};
  DateTime? _pausedDateTime;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  final double _pageSpacing = 16;
  final double _pageBottomPadding = 16;

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
      AppLifecycle.notifyStateChanged,]);

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
    if (name == AppLifecycle.notifyStateChanged) {
      _onAppLifecycleStateChanged(param);
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

  void _onAppLifecycleStateChanged(AppLifecycleState? state) {
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
          _groups = _visibleGroups(groups);
          _groupCardKeys.clear();
        });
      }
    });
  }

  void _updateGroups() {
    Groups().loadGroups(contentType: widget.contentType).then((List<Group>? groupsList) {
      List<Group>? groups = ListUtils.from(groupsList);
      _sortGroups(groups);
      if (mounted && !DeepCollectionEquality().equals(_groups, _visibleGroups(groups))) {
        setState(() {
          _groups = _visibleGroups(groups);
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
          _groups = _visibleGroups(userGroups);
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
      child: CollectionUtils.isEmpty(_groups) ? _buildEmpty() : _buildContent(),
    );
  }


  Widget _buildContent() {
    Widget? contentWidget;
    int visibleCount = _groups?.length ?? 0;
    int pageCount = visibleCount ~/ _cardsPerPage;

    List<Widget> pages = <Widget>[];
    for (int index = 0; index < pageCount + 1; index++) {
      List<Widget> pageCards = [];
      for (int groupIndex = 0; groupIndex < _cardsPerPage; groupIndex++) {
        if (index * _cardsPerPage + groupIndex >= _groups!.length) {
          break;
        }
        Group group = _groups![index * _cardsPerPage + groupIndex];
        GlobalKey groupKey = (_groupCardKeys[group.id!] ??= GlobalKey());
        pageCards.add(Padding(padding: EdgeInsets.only(right: _pageSpacing, bottom: _pageBottomPadding), child:
          Semantics(/* excludeSemantics: !(_pageController?.page == _groups?.indexOf(group)),*/ child:
            Container(
              constraints: BoxConstraints(maxWidth: _cardWidth),
              child: GroupCard(key: groupKey, group: group, displayType: GroupCardDisplayType.homeGroups, margin: EdgeInsets.zero,)
            ),
        )));
      }
      if (_cardsPerPage > 1) {
        pages.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: pageCards,
        ));
      } else {
        pages.addAll(pageCards);
      }
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

    return Column(children: [
      contentWidget,
      AccessibleViewPagerNavigationButtons(
        controller: _pageController,
        pagesCount: () {
          if ((_groups?.length ?? 0) == _cardsPerPage) {
          return 1;
          }
          return (_groups?.length ?? 0) ~/ _cardsPerPage + 1;
        },
        centerWidget: LinkButton(
          title: Localization().getStringEx('widget.home.groups.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.groups.button.all.hint', 'Tap to view all groups'),
          textStyle: Styles().textStyles.getTextStyle('widget.description.regular.light.underline'),
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

  double get _cardWidth {
    double screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth - 2 * _cardsPerPage * _pageSpacing) / _cardsPerPage;
  }

  int get _cardsPerPage {
    ScreenType screenType = ScreenUtils.getType(context);
    switch (screenType) {
      case ScreenType.desktop:
        return min(5, (_groups?.length ?? 1));
      case ScreenType.tablet:
        return min(3, (_groups?.length ?? 1));
      case ScreenType.phone:
        return 1;
      default:
        return 1;
    }
  }

  void _onSeeAll() {
    Analytics().logSelect(target: "View All", source: '${widget.runtimeType}(${widget.contentType})' );
    Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: GroupsHomePanel.routeName), builder: (context) => GroupsHomePanel(contentType: widget.contentType,)));
  }
}