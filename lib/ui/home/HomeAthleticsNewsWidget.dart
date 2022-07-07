
import 'dart:async';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/main.dart';
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

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.athletics_news.text.title', 'Athletics News');

  State<HomeAthliticsNewsWidget> createState() => _HomeAthleticsNewsWidgetState();
}

class _HomeAthleticsNewsWidgetState extends State<HomeAthliticsNewsWidget> implements NotificationsListener {

  List<News>? _news;
  bool _loadingNews = false;
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
          _refreshNews(showProgress: true);
        }
      });
    }

    double screenWidth = MediaQuery.of(App.instance?.currentContext ?? context).size.width;
    double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
    _pageController = PageController(viewportFraction: pageViewport);

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

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
        title: Localization().getStringEx('widget.home.athletics_news.text.title', 'Athletics News'),
        titleIcon: Image.asset('images/icon-news.png'),
        childPadding: EdgeInsets.zero,
        child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (Connectivity().isOffline) {
      return HomeMessageCard(
        title: Localization().getStringEx("app.offline.message.title", "You appear to be offline"),
        message: Localization().getStringEx("widget.home.athletics_news.text.offline", "Athletics News are not available while offline"),
      );
    }
    else if (_loadingNews) {
      return HomeProgressWidget();
    }
    else if (CollectionUtils.isEmpty(_news)) {
      return HomeMessageCard(
        title: Localization().getStringEx("widget.home.athletics_news.text.empty", "Whoops! Nothing to see here."),
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

      double pageHeight = (14 + 24 * 2) * MediaQuery.of(context).textScaleFactor + 2 * 24 + 10 + 12 + 12 + 16;

      List<Widget> pages = <Widget>[];
      for (News news in _news!) {
        pages.add(Padding(padding: EdgeInsets.only(right: _pageSpacing, bottom: 3), child:
          AthleticsNewsCard(news: news, onTap: () => _onTapNews(news))
        ));
      }

      contentWidget = Container(constraints: BoxConstraints(minHeight: pageHeight), child:
        ExpandablePageView(controller: _pageController, children: pages, estimatedPageSize: pageHeight),
      );
    }
    else {
      contentWidget = Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8), child:
        AthleticsNewsCard(news: _news!.first, onTap: () => _onTapNews(_news!.first))
      );
    }

    return Column(children: <Widget>[
      contentWidget,
      LinkButton(
        title: Localization().getStringEx('widget.home.athletics_news.button.all.title', 'View All'),
        hint: Localization().getStringEx('widget.home.athletics_news.button.all.hint', 'Tap to view all news'),
        onTap: _onTapSeeAll,
      ),
    ]);
  }

  void _onTapNews(News news) {
    Analytics().logSelect(target: "news: "+news.title!);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsNewsArticlePanel(article: news)));
  }

  void _onTapSeeAll() {
    Analytics().logSelect(target: "HomeAthleticsNews: View All");
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
        if (mounted) {
          setState(() {
            if (showProgress) {
              _loadingNews = false;
            }
            if (news != null) {
              _news = news;
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
          _refreshNews();
        }
      }
    }
  }
}