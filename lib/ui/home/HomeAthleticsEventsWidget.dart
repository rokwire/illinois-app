
import 'dart:async';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/main.dart';
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
  final double _pageSpacing = 16;
  PageController? _pageController;
  DateTime? _pausedDateTime;

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

    double screenWidth = MediaQuery.of(App.instance?.currentContext ?? context).size.width;
    double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
    _pageController = PageController(viewportFraction: pageViewport);

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

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: Localization().getStringEx('widget.home.athletics_events.text.title', 'Athletics Events'),
      titleIcon: Image.asset('images/icon-calendar.png'),
      childPadding: EdgeInsets.zero,
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
        title: Localization().getStringEx("widget.home.athletics_events.text.empty", "Whoops! Nothing to see here."),
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
      
      double pageHeight = (24 + 16) * MediaQuery.of(context).textScaleFactor + 20 + (24 + 8 + 18) + 12 + 10 + 12 + 24 + 12;

      List<Widget> pages = <Widget>[];
      for (Game game in _games!) {
        pages.add(Padding(padding: EdgeInsets.only(right: _pageSpacing, bottom: 3), child:
          AthleticsCard(game: game, onTap: () => _onTapGame(game), showInterests: true, margin: EdgeInsets.zero,),),
        );
      }

      contentWidget = Container(constraints: BoxConstraints(minHeight: pageHeight), child:
        ExpandablePageView(controller: _pageController, children: pages, estimatedPageSize: pageHeight),
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
        if (mounted) {
          setState(() {
            if (showProgress) {
              _loadingGames = false;
            }
            if (games != null) {
              _games = games;
            }
          });
        }
      });
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
}