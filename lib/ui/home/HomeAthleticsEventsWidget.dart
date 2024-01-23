
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/events2/Event2DetailPanel.dart';
import 'package:illinois/ui/events2/Event2HomePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeAthliticsEventsWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeAthliticsEventsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.athletics_events.text.title', 'Athletics Events');

  State<HomeAthliticsEventsWidget> createState() => _HomeAthleticsEventsWidgetState();
}

class _HomeAthleticsEventsWidgetState extends State<HomeAthliticsEventsWidget> implements NotificationsListener {

  List<Event2>? _sportEvents;
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
      _loadSportEvents().then((List<Event2>? events) {
        setStateIfMounted(() {
          _sportEvents = events;
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
      titleIconKey: 'calendar',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (Connectivity().isOffline) {
      return HomeMessageCard(
        title: Localization().getStringEx("common.message.offline", "You appear to be offline"),
        message: Localization().getStringEx("widget.home.athletics_events.text.offline", "Athletics Events are not available while offline"),
      );
    }
    else if (_loadingGames) {
      return HomeProgressWidget();
    }
    else if (CollectionUtils.isEmpty(_sportEvents)) {
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
    int visibleCount = _sportEvents?.length ?? 0;

    if (1 < visibleCount) {
      
      List<Widget> pages = <Widget>[];
      for (int index = 0; index < visibleCount; index++) {
        Event2 event = _sportEvents![index];
        pages.add(Padding(key: _contentKeys[event.id ?? ''] ??= GlobalKey(), padding: EdgeInsets.only(right: _pageSpacing, bottom: 16), child:
          Event2Card(event, onTap: () => _onTapEvent(event))),
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
          allowImplicitScrolling : true,
          children: pages),
      );
    }
    else {
      contentWidget = Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8), child:
        Event2Card(_sportEvents!.first, onTap: () => _onTapEvent(_sportEvents!.first))
      );
    }
    
    return Column(children: <Widget>[
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => visibleCount, centerWidget:
        LinkButton(
          title: Localization().getStringEx('widget.home.athletics_events.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.athletics_events.button.all.hint', 'Tap to view all events'),
          onTap: _onTapSeeAll,
        ),
      ),
    ],);
  }


  void _onTapEvent(Event2 event) {
    Analytics().logSelect(target: "Event: '${event.name}'" , source: widget.runtimeType.toString());
    if (Connectivity().isNotOffline) {
      if (event.hasGame) {
        Navigator.push(context, CupertinoPageRoute( builder: (context) => AthleticsGameDetailPanel(game: event.game)));
      } else {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2DetailPanel(event: event)));
      }
    }
    else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.game', 'Game detail is not available while offline.'));
    }
  }

  void _onTapSeeAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Event2HomePanel.present(context, attributes: Event2HomePanel.athleticsCategoryAttributes);
  }

  void _refreshGames({bool showProgress = false}) {
    if (Connectivity().isOnline) {
      if (showProgress && mounted) {
        setState(() {
          _loadingGames = true;
        });
      }
      _loadSportEvents().then((List<Event2>? event) {
        if (mounted && !DeepCollectionEquality().equals(_sportEvents, event)) {
          setState(() {
            _sportEvents = event;
            _pageViewKey = UniqueKey();
            // _pageController = null;
            _pageController?.jumpToPage(0);
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

  Future<List<Event2>?> _loadSportEvents() async {
    Events2Query query = Events2Query(
        attributes: Event2HomePanel.athleticsCategoryAttributes,
        limit: Config().homeAthleticsEventsCount,
        sortType: Event2SortType.dateTime);
    Events2ListResult? result = await Events2().loadEvents(query);
    return result?.events;
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