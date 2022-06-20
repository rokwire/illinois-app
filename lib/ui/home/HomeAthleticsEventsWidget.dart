
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
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
      flatHeight: 0, slantHeight: 0,
      childPadding: EdgeInsets.zero,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (Connectivity().isOffline) {
      return _buildOfflineContent();
    }
    else if (_loadingGames) {
      return _buildLoadingContent();
    }
    else if (CollectionUtils.isEmpty(_games)) {
      return _buildEmptyContent();
    }
    else {
      return _buildEventsContent();
    }

  }

  Widget _buildOfflineContent() {
    return Padding(padding: EdgeInsets.only(left: 32, right: 32, top: 48, bottom: 48), child:
      Column(children: <Widget>[
        Text(Localization().getStringEx("app.offline.message.title", "You appear to be offline"), style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 20, color: Styles().colors?.fillColorPrimary),),
        Container(height:8),
        Text(Localization().getStringEx("widget.home.athletics_events.text.offline", "Athletics Events are not available while offline"), style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground),),
    ],),);
  }

  Widget _buildEmptyContent() {
    return Padding(padding: EdgeInsets.only(left: 32, right: 32, top: 48, bottom: 48), child:
      Column(children: [
        Text(Localization().getStringEx("widget.home.athletics_events.text.empty", "Whoops! Nothing to see here."), style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 20, color: Styles().colors?.fillColorPrimary),),
        Container(height:8),
        Text(Localization().getStringEx("widget.home.athletics_events.text.empty.description", "No Athletics Events are available right now."), style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground),),
      ],)
    );
  }

  Widget _buildLoadingContent() {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 48), child:
      Center(child:
        SizedBox(height: 24, width: 24, child:
          CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorPrimary), )
        ),
      ),
    );
  }

  Widget _buildEventsContent() {
    List<Widget> contentList = [];
    if (_games != null) {
      for (Game game in _games!) {
        //contentList.add(AthleticsCard(game: game, onTap: () => _onTapGame(game), showImage: contentList.isEmpty, showInterests: false,),);
        if (contentList.isEmpty && StringUtils.isNotEmpty(game.imageUrl)) {
          contentList.add(ImageSlantHeader(
            slantImageColor: Styles().colors!.fillColorSecondaryTransparent05,
            slantImageAsset: 'images/slant-down-right.png',
            child: AthleticsCard(game: game, onTap: () => _onTapGame(game), showInterests: true,),
            imageUrl: game.imageUrl
          ));
        }
        else {
          contentList.add(AthleticsCard(game: game, onTap: () => _onTapGame(game), showInterests: true),);
        }
      }
      contentList.add(
          LinkButton(
            title: Localization().getStringEx('widget.home.athletics_events.button.all.title', 'View All'),
            hint: Localization().getStringEx('widget.home.athletics_events.button.all.hint', 'Tap to view all events'),
            onTap: _onTapSeeAll,
          ),

      );
    }
    return Column(children: contentList,);
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