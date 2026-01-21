import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/accessibility/AccessiblePageView.dart';
import 'package:illinois/ui/groups/GroupHome2Panel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';


class HomeGroupsWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeGroupsWidget({super.key, required this.favoriteId, this.updateController});

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  String get _title => title;
  static String get title => Localization().getStringEx('widget.home.groups.label.header.title', 'Groups');

  @override
  State<StatefulWidget> createState() => _HomeGroupsWidgetState();
}

class _HomeGroupsWidgetState extends State<HomeGroupsWidget> {
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
      _HomeGroupsImplWidget(contentType,
        updateController: widget.updateController,
      ),
    ));

  Widget get _contentTypeBar => Row(children:List<Widget>.from(
    FavoriteContentType.values.map((FavoriteContentType contentType) => Expanded(child:
      HomeFavTabBarBtn(contentType.groupsTitle.toUpperCase(),
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

class _HomeGroupsImplWidget extends StatefulWidget {
  final FavoriteContentType contentType;
  final StreamController<String>? updateController;

  // ignore: unused_element_parameter
  const _HomeGroupsImplWidget(this.contentType, {super.key, this.updateController});

  @override
  State<StatefulWidget> createState() => _HomeGroupsImplWidgetState();
}

class _HomeGroupsImplWidgetState extends State<_HomeGroupsImplWidget> with NotificationsListener{

  List<Group>? _groups;
  bool _loadingGroups = false;
  bool _updatingGroups = false;

  bool _visible = false;
  Key _visibilityDetectorKey = UniqueKey();
  DateTime? _pausedDateTime;
  FavoriteContentStatus _contentStatus = FavoriteContentStatus.none;

  Map<String, GlobalKey> _groupCardKeys = <String, GlobalKey>{};
  PageController? _pageController;
  Key _pageViewKey = UniqueKey();

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      Groups.notifyGroupCreated,
      Groups.notifyGroupUpdated,
      Groups.notifyGroupDeleted,
      Groups.notifyUserGroupsUpdated,
      Connectivity.notifyStatusChanged,
      Auth2.notifyLoginChanged,
      AppLivecycle.notifyStateChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _loadGroupsIfVisible();
        }
      });
    }

    _loadGroups();
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
    else if ((name == Groups.notifyGroupCreated) ||
      (name == Groups.notifyGroupUpdated) ||
      (name == Groups.notifyGroupDeleted) ||
      (name == Connectivity.notifyStatusChanged) ||
      (name == Groups.notifyUserGroupsUpdated) ||
      (name == Auth2.notifyLoginChanged)
    ) {
      _loadGroupsIfVisible();
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
          _updateGroupsIfVisible();
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
        message: Localization().getStringEx('widget.home.groups.message.offline', 'Groups are not available while offline.'),
      );
    }
    else if (!Auth2().isLoggedIn) {
      return HomeMessageCard(
        title: Localization().getStringEx("common.message.logged_out", "You are not logged in"),
        message: AppTextUtils.loggedOutFeatureNA(Localization().getStringEx('generic.app.feature.groups', 'Groups'), verbose: true),
      );
    }
    else if (_loadingGroups) {
      return HomeProgressWidget();
    }
    else {
      return _groupsContentWidget;
    }
  }

  Widget get _groupsContentWidget {
    Widget? contentWidget;
    List<Group>? visibleGroups = _groups;
    int visibleCount = visibleGroups?.length ?? 0;

    if (1 < visibleCount) {
      List<Widget> pages = <Widget>[];
      for (Group group in visibleGroups!) {
        GlobalKey groupKey = (_groupCardKeys[group.id!] ??= GlobalKey());
        pages.add(Padding(padding: HomeCard.defaultPageMargin, child:
          // Semantics(/*excludeSemantics: !(_pageController?.page == _groups?.indexOf(group)),*/ container: true,  child:
            GroupCard(group, key: groupKey, displayType: GroupCardDisplayType.homeGroups, margin: EdgeInsets.zero,),
          // )
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
          allowImplicitScrolling: true,
          children: pages,
        ),
      );
    }
    else if (visibleCount == 1) {
      contentWidget = Padding(padding: HomeCard.defaultSingleCardMargin, child:
        Semantics(/* excludeSemantics: !(_pageController?.page == _groups?.indexOf(group)),*/ container: true, child:
          GroupCard(visibleGroups!.first, displayType: GroupCardDisplayType.homeGroups, margin: EdgeInsets.zero,),
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
    ],) : HomeMessageCard(
      title: widget.contentType.emptyContentTitle,
      message: widget.contentType.emptyContentMessage,
    );
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
        case FavoriteContentStatus.refresh: _updateGroups(); break;
        case FavoriteContentStatus.reload: _loadGroups(); break;
      }
    }
  }

  // Content Data

  Future<void> _loadGroupsIfVisible() async {
    if (_visible) {
      return _loadGroups();
    }
    else if (_contentStatus.index < FavoriteContentStatus.reload.index) {
      _contentStatus = FavoriteContentStatus.reload;
    }
  }

  Future<void> _loadGroups() async {
    if ((_loadingGroups == false) && mounted) {
      setState(() {
        _loadingGroups = true;
        _updatingGroups = false;
      });

      List<Group>? groupsList = await Groups().loadDisplayGroupsListV3(widget.contentType.groupsFilter);
      List<Group>? groups = ListUtils.from(groupsList);
      _sortGroups(groups);

      setStateIfMounted(() {
        _groups = groups;
        _contentStatus = FavoriteContentStatus.none;
        _loadingGroups = false;
        _groupCardKeys.clear();
      });
    }
  }

  Future<void> _updateGroupsIfVisible() async {
    if (_visible) {
      return _updateGroups();
    }
    else if (_contentStatus.index < FavoriteContentStatus.refresh.index) {
      _contentStatus = FavoriteContentStatus.refresh;
    }
  }

  Future<void> _updateGroups() async {
    if ((_loadingGroups == false) && (_updatingGroups == false) && mounted) {
      setState(() {
        _updatingGroups = true;
      });

      List<Group>? groupsList = await Groups().loadDisplayGroupsListV3(widget.contentType.groupsFilter);
      List<Group>? groups = ListUtils.from(groupsList);
      _sortGroups(groups);

      if (mounted && _updatingGroups && (groups != null) && !DeepCollectionEquality().equals(_groups, groups)) {
        setState(() {
          _groups = groups;
          _contentStatus = FavoriteContentStatus.none;
          _updatingGroups = false;
          _pageViewKey = UniqueKey();
          _groupCardKeys.clear();
          // _pageController = null;
          if ((_groups?.isNotEmpty == true) && (_pageController?.hasClients == true)) {
            _pageController?.jumpToPage(0);
          }
        });
      }
    }
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

  // Event Handlers

  void _onSeeAll() {
    Analytics().logSelect(target: "View All", source: '${widget.runtimeType}(${widget.contentType})' );
    GroupHome2Panel.push(context, filter: widget.contentType.groupsFilter);
  }

}

extension _FavoriteGroupsContentType on FavoriteContentType {
  String get groupsTitle {
    switch (this) {
      case FavoriteContentType.my: return Localization().getStringEx('widget.home.groups.my.label.header.title', 'My Groups');
      case FavoriteContentType.all: return Localization().getStringEx('widget.home.groups.all.label.header.title', 'All Groups');
    }
  }

  String get emptyContentTitle {
    switch(this) {
      case FavoriteContentType.my: return Localization().getStringEx('common.label.failed', 'Empty');
      case FavoriteContentType.all: return Localization().getStringEx('common.label.failed', 'Failed');
    }
  }

  String get emptyContentMessage {
    switch(this) {
      case FavoriteContentType.my: return Localization().getStringEx('widget.home.groups.my.text.empty.description', 'You have not created any groups yet.');
      case FavoriteContentType.all: return Localization().getStringEx('widget.home.groups.all.text.empty.description', 'Failed to load groups.');
    }
  }

  GroupsFilter get groupsFilter {
    switch (this) {
      case FavoriteContentType.my: return Groups.userGroupsFilter;
      case FavoriteContentType.all: return Groups.allGroupsFilter;
    }
  }
}
