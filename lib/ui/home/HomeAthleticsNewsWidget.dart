
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/ui/athletics/AthleticsNewsArticlePanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsCard.dart';
import 'package:illinois/ui/athletics/AthleticsNewsListPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeAthliticsNewsWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeAthliticsNewsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.athletics_news.text.title', 'Athletics News');

  State<HomeAthliticsNewsWidget> createState() => _HomeAthleticsNewsWidgetState();
}

class _HomeAthleticsNewsWidgetState extends State<HomeAthliticsNewsWidget> implements NotificationsListener {

  List<News>? _news;
  bool _loadingNews = false;
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
          _refreshNews(showProgress: true);
        }
      });
    }

    if (Connectivity().isOnline) {
      _loadingNews = true;
      Sports().loadNews(null, Config().homeAthleticsNewsCount).then((List<News>? news) {
        setStateIfMounted(() {
          _news = news;
          _loadingNews = false;
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
      _refreshNews();
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
          _refreshNews();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
        title: Localization().getStringEx('widget.home.athletics_news.text.title', 'Athletics News'),
        titleIconKey: 'news',
        child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (Connectivity().isOffline) {
      return HomeMessageCard(
        title: Localization().getStringEx("common.message.offline", "You appear to be offline"),
        message: Localization().getStringEx("widget.home.athletics_news.text.offline", "Athletics News are not available while offline"),
      );
    }
    else if (_loadingNews) {
      return HomeProgressWidget();
    }
    else if (CollectionUtils.isEmpty(_news)) {
      return HomeMessageCard(
        message: Localization().getStringEx("widget.home.athletics_news.text.empty.description", "No Athletics News are available right now."),
      );
    }
    else {
      return _buildNewsContent();
    }

  }

  Widget _buildNewsContent() {
    Widget contentWidget;
    int visibleCount = _news?.length ?? 0;

    if (1 < visibleCount) {

      List<Widget> pages = <Widget>[];
      for (int index = 0; index < visibleCount; index++) {
        News news = _news![index];
        pages.add(Padding(key: _contentKeys[news.id ?? ''] ??= GlobalKey(), padding: EdgeInsets.only(right: _pageSpacing, bottom: 16), child:
          AthleticsNewsCard(news: news, onTap: () => _onTapNews(news))
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
        AthleticsNewsCard(news: _news!.first, onTap: () => _onTapNews(_news!.first))
      );
    }

    return Column(children: <Widget>[
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => visibleCount, centerWidget:
        LinkButton(
          title: Localization().getStringEx('widget.home.athletics_news.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.athletics_news.button.all.hint', 'Tap to view all news'),
          onTap: _onTapSeeAll,
        ),
      )
    ]);
  }

  void _onTapNews(News news) {
    Analytics().logSelect(target: "News: '${news.title}'", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsNewsArticlePanel(article: news)));
  }

  void _onTapSeeAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsNewsListPanel()));
  }

  void _refreshNews({bool showProgress = false}) {
    if (Connectivity().isOnline) {
      if (showProgress && mounted) {
        setState(() {
          _loadingNews = true;
        });
      }
      Sports().loadNews(null, Config().homeAthleticsNewsCount).then((List<News>? news) {
        if (mounted && !DeepCollectionEquality().equals(news, _news)) {
          setState(() {
            _news = news;
            _pageViewKey = UniqueKey();
            // _pageController = null;
            _pageController?.jumpToPage(0);
            _contentKeys.clear();
          });
        }
      }).whenComplete(() {
        if (mounted && showProgress) {
          setState(() {
            _loadingNews = false;
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