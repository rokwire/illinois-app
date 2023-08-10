
import 'dart:async';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/laundry/LaundryHomePanel.dart';
import 'package:illinois/ui/laundry/LaundryRoomDetailPanel.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeLaundryWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeLaundryWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.laundry.text.title', 'Laundry');

  State<HomeLaundryWidget> createState() => _HomeLaundryWidgetState();
}

class _HomeLaundryWidgetState extends State<HomeLaundryWidget> implements NotificationsListener {

  LaundrySchool? _laundrySchool;
  bool _loading = false;
  DateTime? _pausedDateTime;
  
  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  Map<String, GlobalKey> _contentKeys = <String, GlobalKey>{};
  final double _pageSpacing = 16;

  @override
  void initState() {

    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      AppLivecycle.notifyStateChanged,
      Config.notifyConfigChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _refreshLaundry(showProgress: true);
        }
      });
    }

    if (Connectivity().isOnline) {
      _loading = true;
      Laundries().loadSchoolRooms().then((LaundrySchool? laundrySchool) {
        setStateIfMounted(() {
          _laundrySchool = laundrySchool;
          _loading = false;
        });
      });
    }

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
      _refreshLaundry();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == Config.notifyConfigChanged) {
      if (mounted) {
        setState(() {});
      }
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
          _refreshLaundry();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
        title: HomeLaundryWidget.title,
        titleIconKey: 'laundry',
        child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (Connectivity().isOffline) {
      return HomeMessageCard(
        title: Localization().getStringEx("common.message.offline", "You appear to be offline"),
        message: Localization().getStringEx("widget.home.laundry.text.offline", "Laundries are not available while offline."),
      );
    }
    else if (_loading) {
      return HomeProgressWidget();
    }
    else if (CollectionUtils.isEmpty(_laundrySchool?.rooms)) {
      return HomeMessageCard(
        message: Localization().getStringEx("widget.home.laundry.text.empty.description", "No Laundries are available right now."),
      );
    }
    else {
      return _buildRoomsContent();
    }

  }

  Widget _buildRoomsContent() {
    Widget contentWidget;
    int visibleCount = _laundrySchool?.rooms?.length ?? 0;

    if (1 < visibleCount) {

      List<Widget> pages = <Widget>[];
      for (LaundryRoom room in _laundrySchool!.rooms!) {
        pages.add(Padding(key: _contentKeys[room.id ?? ''] ??= GlobalKey(), padding: EdgeInsets.only(right: _pageSpacing, bottom: 3), child:
          LaundryRoomCard(room: room, onTap: () => _onTapRoom(room))
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
    else {
      contentWidget = Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8), child:
        LaundryRoomCard(room: _laundrySchool!.rooms!.first, onTap: () => _onTapRoom(_laundrySchool!.rooms!.single))
      );
    }

    return Column(children: <Widget>[
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => visibleCount, centerWidget:
        LinkButton(
          title: Localization().getStringEx('widget.home.laundry.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.laundry.button.all.hint', 'Tap to view all laundries'),
          onTap: _onTapSeeAll,
        ),
      ),
    ]);
  }

  void _onTapRoom(LaundryRoom room) {
    Analytics().logSelect(target: "Laundry: '${room.name}'", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryRoomDetailPanel(room: room,)));
  }

  void _onTapSeeAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryHomePanel(laundrySchool: _laundrySchool,)));
  }

  void _refreshLaundry({bool showProgress = false}) {
    if (Connectivity().isOnline) {
      if (showProgress && mounted) {
        setState(() {
          _loading = true;
        });
      }
      Laundries().loadSchoolRooms().then((LaundrySchool? laundrySchool) {
        if (mounted && (laundrySchool != null) && (_laundrySchool != laundrySchool)) {
          setState(() {
            _laundrySchool = laundrySchool;
            _pageViewKey = UniqueKey();
            // _pageController = null;
            _pageController?.jumpToPage(0);
            _contentKeys.clear();
          });
        }
      }).whenComplete(() {
        if (mounted && showProgress) {
          setState(() {
            _loading = false;
          });
        }
      });
    }
  }

  double get _pageHeight {

    double? minContentHeight;
    for(GlobalKey contentKey in _contentKeys.values) {
      final RenderObject? renderBox = contentKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && ((minContentHeight == null) || (renderBox.size.height < minContentHeight))) {
        minContentHeight = renderBox.size.height;
      }
    }

    return minContentHeight ?? 0;
  }
}

class LaundryRoomCard extends StatefulWidget {
  final LaundryRoom? room;
  final GestureTapCallback? onTap;

  LaundryRoomCard({Key? key, this.room, this.onTap}) : super(key: key);

  @override
  State<LaundryRoomCard> createState() => _LaundryRoomCardState();
}

class _LaundryRoomCardState extends State<LaundryRoomCard> implements NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged,
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
    else if (name == FlexUI.notifyChanged) {
      setStateIfMounted(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isFavorite = Auth2().isFavorite(widget.room);
    Color? headerColor = Styles().colors?.accentColor2;
    String? title = widget.room?.name;

    return GestureDetector(onTap: widget.onTap, child:
      Semantics(label: title, child:
        Column(children: <Widget>[
          Container(height: 7, color: headerColor,),
          Container(decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4))), child:
            Padding(padding: EdgeInsets.all(16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Flex(direction: Axis.vertical, children: <Widget>[
                    Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                      Expanded(child:
                        Text(title ?? '', semanticsLabel: "", style: Styles().textStyles?.getTextStyle("widget.card.title.medium")),
                      ),
                      Visibility(visible: Auth2().canFavorite, child:
                        GestureDetector(behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Analytics().logSelect(target: "Favorite: $title");
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
                              Container(padding: EdgeInsets.only(left: 24, bottom: 24), child: Styles().images?.getImage(isFavorite ? 'star-filled' : 'star-outline-gray', excludeFromSemantics: true)))),
                          )
                        ],
                      )
                    ],
                  ),
                ]),
              ),
            )
          ],
        )),);
  }
}