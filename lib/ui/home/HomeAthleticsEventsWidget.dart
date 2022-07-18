
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/athletics/AthleticsHomePanel.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeAthliticsEventsWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeAthliticsEventsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.athletics_events.text.title', 'Athletics Events');

  State<HomeAthliticsEventsWidget> createState() => _HomeAthleticsEventsWidgetState();
}

class _HomeAthleticsEventsWidgetState extends State<HomeAthliticsEventsWidget> implements NotificationsListener {

  List<Game>? _games;
  bool _loadingGames = false;
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
          _refreshGames(showProgress: true);
        }
      });
    }

    if (Connectivity().isOnline) {
      _loadingGames = true;
      Sports().loadGames(limit: Config().homeAthleticsEventsCount).then((List<Game>? games) {
        setStateIfMounted(() {
          _games = games;
          _loadingGames = false;
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
      _refreshGames();
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
          _refreshGames();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: Localization().getStringEx('widget.home.athletics_events.text.title', 'Athletics Events'),
      titleIcon: Image.asset('images/icon-calendar.png'),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (Connectivity().isOffline) {
      return HomeMessageCard(
        title: Localization().getStringEx("app.offline.message.title", "You appear to be offline"),
        message: Localization().getStringEx("widget.home.athletics_events.text.offline", "Athletics Events are not available while offline"),
      );
    }
    else if (_loadingGames) {
      return HomeProgressWidget();
    }
    else if (CollectionUtils.isEmpty(_games)) {
      return HomeMessageCard(
        message: Localization().getStringEx("widget.home.athletics_events.text.empty.description", "No Athletics Events are available right now."),
      );
    }
    else {
      return _buildEventsContent();
    }

  }

  Widget _buildEventsContent() {
    Widget contentWidget;
    int visibleCount = _games?.length ?? 0;

    if (1 < visibleCount) {
      
      List<Widget> pages = <Widget>[];
      for (int index = 0; index < visibleCount; index++) {
        Game game = _games![index];
        pages.add(Padding(key: _contentKeys[game.id ?? ''] ??= GlobalKey(), padding: EdgeInsets.only(right: _pageSpacing, bottom: 3), child:
          AthleticsCard(game: game, onTap: () => _onTapGame(game), showInterests: true, margin: EdgeInsets.zero,),),
        );
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
          children: pages),
      );
    }
    else {
      contentWidget = Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8), child:
        AthleticsCard(game: _games!.first, onTap: () => _onTapGame( _games!.first), showInterests: true, margin: EdgeInsets.zero)
      );
    }
    
    return Column(children: <Widget>[
      contentWidget,
      LinkButton(
        title: Localization().getStringEx('widget.home.athletics_events.button.all.title', 'View All'),
        hint: Localization().getStringEx('widget.home.athletics_events.button.all.hint', 'Tap to view all events'),
        onTap: _onTapSeeAll,
      ),
    ],);
  }


  void _onTapGame(Game game) {
    Analytics().logSelect(target: "Game: "+game.title);
    if (Connectivity().isNotOffline) {
      Navigator.push(context, CupertinoPageRoute( builder: (context) => AthleticsGameDetailPanel(game: game)));
    }
    else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.game', 'Game detail is not available while offline.'));
    }
  }

  void _onTapSeeAll() {
    Analytics().logSelect(target: "HomeAthleticsEvents: View All");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(initialItem: ExploreItem.Events, initialFilter: ExploreFilter(type: ExploreFilterType.categories, selectedIndexes: {3}))));
  }

  void _refreshGames({bool showProgress = false}) {
    if (Connectivity().isOnline) {
      if (showProgress && mounted) {
        setState(() {
          _loadingGames = true;
        });
      }
      Sports().loadGames(limit: Config().homeAthleticsEventsCount).then((List<Game>? games) {
        if (mounted && !DeepCollectionEquality().equals(_games, games)) {
          setState(() {
            _games = games;
            _pageViewKey = UniqueKey();
            _pageController = null;
            _contentKeys.clear();
          });
        }
      }).whenComplete(() {
        if (mounted && showProgress) {
          setState(() {
            _loadingGames = false;
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