
import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/accessibility/AccessiblePageView.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/laundry/LaundryHomePanel.dart';
import 'package:illinois/ui/laundry/LaundryRoomDetailPanel.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/ui/widgets/AccentCard.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HomeLaundryWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeLaundryWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  String get _title => title;
  static String get title => Localization().getStringEx('widget.home.laundry.text.title', 'Laundry');

  State<HomeLaundryWidget> createState() => _HomeLaundryWidgetState();
}

class _HomeLaundryWidgetState extends State<HomeLaundryWidget> {
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
    _HomeLaundryImplWidget(contentType,
        updateController: widget.updateController,
      ),
    ));

  Widget get _contentTypeBar => Row(children:List<Widget>.from(
    FavoriteContentType.values.map((FavoriteContentType contentType) => Expanded(child:
      HomeFavTabBarBtn(contentType.laundryTitle.toUpperCase(),
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

class _HomeLaundryImplWidget extends StatefulWidget {

  final FavoriteContentType contentType;
  final StreamController<String>? updateController;

  // ignore: unused_element_parameter
  const _HomeLaundryImplWidget(this.contentType, {super.key, this.updateController});

  State<StatefulWidget> createState() => _HomeLaundryImplWidgetState();
}

class _HomeLaundryImplWidgetState extends State<_HomeLaundryImplWidget> with NotificationsListener {

  LaundrySchool? _laundrySchool;
  FavoriteContentActivity _contentActivity = FavoriteContentActivity.none;

  bool _visible = false;
  Key _visibilityDetectorKey = UniqueKey();
  DateTime? _pausedDateTime;
  FavoriteContentStatus _contentStatus = FavoriteContentStatus.none;
  
  Map<String, GlobalKey> _contentKeys = <String, GlobalKey>{};
  PageController? _pageController;
  Key _pageViewKey = UniqueKey();

  @override
  void initState() {

    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      AppLivecycle.notifyStateChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _refreshLaundryIfVisible();
        }
      });
    }

    _loadLaundry();

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _pageController?.dispose();
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Connectivity.notifyStatusChanged) {
      _loadLaundryIfVisible();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _refreshLaundryIfVisible();
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
        message: Localization().getStringEx("widget.home.laundry.text.offline", "Laundries are not available while offline."),
      );
    }
    else if (_contentActivity.showsProgress) {
      return HomeProgressWidget();
    }
    else {
      return _laundryContentWidget;
    }
  }

  Widget get _laundryContentWidget {
      Widget? contentWidget;
      List<LaundryRoom>? displayLaundryRooms = _buildDisplayLaundryRooms();
      int visibleCount = displayLaundryRooms?.length ?? 0;

      if (1 < visibleCount) {

        List<Widget> pages = <Widget>[];
        for (LaundryRoom room in displayLaundryRooms!) {
          pages.add(Padding(
              key: _contentKeys[room.id ?? ''] ??= GlobalKey(),
              padding: HomeCard.defaultPageMargin,
              child: LaundryRoomCard(room: room, displayMode: CardDisplayMode.home, onTap: () => _onTapRoom(room))
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
        LaundryRoomCard(room: displayLaundryRooms!.first, onTap: () => _onTapRoom(_laundrySchool!.rooms!.single))
        );
      }

      return (contentWidget != null) ? Column(children: <Widget>[
        contentWidget,
        AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => visibleCount, centerWidget:
        HomeBrowseLinkButton(
          title: Localization().getStringEx('widget.home.laundry.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.laundry.button.all.hint', 'Tap to view all laundries'),
          onTap: _onTapSeeAll,
        ),
        ),
      ]) : _emptyContentWidget;
    }

  double get _pageHeight {

    double? minContentHeight;
    for(GlobalKey contentKey in _contentKeys.values) {
      final RenderObject? renderBox = contentKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && renderBox.hasSize && ((minContentHeight == null) || (renderBox.size.height < minContentHeight))) {
        minContentHeight = renderBox.size.height;
      }
    }

    return minContentHeight ?? 0;
  }

  static const String localScheme = 'local';
  static const String localLaundryHost = 'laundry';
  static const String localUrlMacro = '{{local_url}}';
  static const String privacyScheme = 'privacy';
  static const String privacyLevelHost = 'level';
  static const String privacyUrlMacro = '{{privacy_url}}';

  Widget get _emptyContentWidget {
    if (widget.contentType == FavoriteContentType.all) {
      return HomeMessageCard(message: Localization().getStringEx("widget.home.laundry.all.text.empty.description", "No Laundries are available right now."),);
    }
    else if (widget.contentType == FavoriteContentType.my) {
      String message = Localization().getStringEx("widget.home.laundry.my.text.empty.description", "Tap the \u2606 on items in <a href='$localUrlMacro'><b>Laundry</b></a> for quick access here.  (<a href='$privacyUrlMacro'>Your privacy level</a> must be at least 2.)")
          .replaceAll(localUrlMacro, '$localScheme://$localLaundryHost')
          .replaceAll(privacyUrlMacro, '$privacyScheme://$privacyLevelHost');

      return HomeMessageHtmlCard(message: message, onTapLink: _onMessageLink,);
    }
    else {
      return Container();
    }
  }

  void _onMessageLink(String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if (uri?.scheme == localScheme) {
      if (uri?.host.toLowerCase() == localLaundryHost.toLowerCase()) {
        Analytics().logSelect(target: "Laundry", source: widget.runtimeType.toString());
        Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryHomePanel(laundrySchool: _laundrySchool)));
      }
      else if ((uri?.scheme == privacyScheme) && (uri?.host == privacyLevelHost)) {
        Analytics().logSelect(target: 'Privacy Level', source: runtimeType.toString());
        Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,)));
      }
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
        case FavoriteContentStatus.refresh: _refreshLaundry(); break;
        case FavoriteContentStatus.reload: _loadLaundry(); break;
      }
    }
  }

  // Content Data

  Future<void> _loadLaundryIfVisible() async {
    if (_visible) {
      return _loadLaundry();
    }
    else if (_contentStatus.canReload) {
      _contentStatus = FavoriteContentStatus.reload;
    }
  }

  Future<void> _loadLaundry() async {
    if (_contentActivity.canReload && mounted) {
      setState(() {
        _contentActivity = FavoriteContentActivity.reload;
      });

      LaundrySchool? laundrySchool = await Laundries().loadSchoolRooms();

      setStateIfMounted(() {
        _laundrySchool = laundrySchool;
        _contentStatus = FavoriteContentStatus.none;
        _contentActivity = FavoriteContentActivity.none;
        _contentKeys.clear();
      });
    }
  }

  Future<void> _refreshLaundryIfVisible() async {
    if (_visible) {
      return _refreshLaundry();
    }
    else if (_contentStatus.canRefresh) {
      _contentStatus = FavoriteContentStatus.refresh;
    }
  }

  Future<void> _refreshLaundry() async {
    if (_contentActivity.canRefresh && mounted) {
      setState(() {
        _contentActivity = FavoriteContentActivity.refresh;
      });

      LaundrySchool? laundrySchool = await Laundries().loadSchoolRooms();

      if (mounted && (_contentActivity == FavoriteContentActivity.refresh)) {
        if ((laundrySchool != null) && (_laundrySchool != laundrySchool)) {
          setState(() {
            _laundrySchool = laundrySchool;
            _contentStatus = FavoriteContentStatus.none;
            _contentActivity = FavoriteContentActivity.none;
            _pageViewKey = UniqueKey();
            _contentKeys.clear();
            // _pageController = null;
            if ((_laundrySchool?.rooms?.isNotEmpty == true) && (_pageController?.hasClients == true)) {
              _pageController?.jumpToPage(0);
            }
          });
        } else {
          setState(() {
            _contentActivity = FavoriteContentActivity.none;
          });
        }
      }

    }
  }

  List<LaundryRoom>? _buildDisplayLaundryRooms() {
    switch (widget.contentType) {
      case FavoriteContentType.my: return _buildFavoriteLaundryRooms();
      case FavoriteContentType.all: return _laundrySchool?.rooms;
    }
  }

  List<LaundryRoom>? _buildFavoriteLaundryRooms() {
    List<LaundryRoom>? laundryRooms = _laundrySchool?.rooms;
    LinkedHashSet<String>? favoriteRoomIds = Auth2().prefs?.getFavorites(LaundryRoom.favoriteKeyName);
    if ((laundryRooms != null) && (favoriteRoomIds != null)) {
      Map<String, LaundryRoom> favorites = <String, LaundryRoom>{};
      if (laundryRooms.isNotEmpty && favoriteRoomIds.isNotEmpty) {
        for (LaundryRoom laundryRoom in laundryRooms) {
          if ((laundryRoom.favoriteId != null) && favoriteRoomIds.contains(laundryRoom.favoriteId)) {
            favorites[laundryRoom.favoriteId!] = laundryRoom;
          }
        }
      }

      List<Favorite>? result = <Favorite>[];
      if (favorites.isNotEmpty) {
        for (String favoriteId in favoriteRoomIds) {
          ListUtils.add(result, favorites[favoriteId]);
        }
      }

      // show last added at top
      return List.from(result.reversed);
    }
    else {
      return null;
    }
  }

  // Event Handlers

  void _onTapRoom(LaundryRoom room) {
    Analytics().logSelect(target: "Laundry: '${room.name}'", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryRoomDetailPanel(room: room,)));
  }

  void _onTapSeeAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryHomePanel(laundrySchool: _laundrySchool, starred: widget.contentType == FavoriteContentType.my,)));
  }
}

class LaundryRoomCard extends StatefulWidget {
  final LaundryRoom room;
  final CardDisplayMode displayMode;
  final GestureTapCallback? onTap;

  LaundryRoomCard({super.key, required this.room, this.displayMode = CardDisplayMode.browse, this.onTap});

  @override
  State<LaundryRoomCard> createState() => _LaundryRoomCardState();
}

class _LaundryRoomCardState extends State<LaundryRoomCard> with NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);
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
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted(() {});
    }
  }

  @override
  Widget build(BuildContext context) =>
    InkWell(onTap: widget.onTap ?? _onTapLaundryCard, child:
      Semantics(label: widget.room.name,
        child: AccentCard(
          displayMode: widget.displayMode,
          accentColor: Styles().colors.accentColor2,
          child: _contentWidget,
        )
      ),
    );

  Widget get _contentWidget {
    bool isFavorite = Auth2().isFavorite(widget.room);

    return Padding(padding: EdgeInsets.all(16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Flex(direction: Axis.vertical, children: <Widget>[
          Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
            Expanded(child:
              Text(widget.room.name ?? '', semanticsLabel: "", style: Styles().textStyles.getTextStyle("widget.card.title.regular.extra_fat")), // widget.title.medium.extra_fat
            ),
            Visibility(visible: Auth2().canFavorite, child:
              GestureDetector(behavior: HitTestBehavior.opaque,
                onTap: () {
                  Analytics().logSelect(target: "Favorite: ${widget.room.name}");
                  Auth2().prefs?.toggleFavorite(widget.room);
                }, child:
                Semantics(container: true,
                  label: isFavorite
                      ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites')
                      : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                  hint: isFavorite
                      ? Localization().getStringEx('widget.card.button.favorite.off.hint', '')
                      : Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
                  button: true,
                  excludeSemantics: true,
                  child:
                    Container(padding: EdgeInsets.only(left: 24, bottom: 24), child: Styles().images.getImage(isFavorite ? 'star-filled' : 'star-outline-gray', excludeFromSemantics: true)))),
                )
              ],
            )
          ],
        ),
      ]),
    );
  }

  void _onTapLaundryCard() {
    Analytics().logSelect(target: "Laundry: '${widget.room.name}'", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryRoomDetailPanel(room: widget.room,)));
  }
}

extension _FavoriteLaundryContentType on FavoriteContentType {
  String get laundryTitle {
    switch (this) {
      case FavoriteContentType.my: return Localization().getStringEx('widget.home.laundry.my.text.title', 'My Laundry');
      case FavoriteContentType.all: return Localization().getStringEx('widget.home.laundry.all.text.title', 'All Laundry');
    }
  }
}
