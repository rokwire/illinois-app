
import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/accessibility/AccessiblePageView.dart';
import 'package:illinois/ui/athletics/AthleticsHomePanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsArticlePanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsCard.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HomeAthliticsNewsWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeAthliticsNewsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  String get _title => title;
  static String get title => Localization().getStringEx('widget.home.athletics_news.header.title', 'Big 10 News');

  State<HomeAthliticsNewsWidget> createState() => _HomeAthleticsNewsWidgetState();
}

class _HomeAthleticsNewsWidgetState extends State<HomeAthliticsNewsWidget> {
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

  Widget get _contentTypeBar => Row(children:List<Widget>.from(
    FavoriteContentType.values.map((FavoriteContentType contentType) => Expanded(child:
      HomeFavTabBarBtn(contentType.athleticsNewsTitle.toUpperCase(),
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

  Iterable<Widget> get _contentTypeWidgets => FavoriteContentType.values.map((FavoriteContentType contentType) =>
    Visibility(visible: (_contentType == contentType), maintainState: true, child:
    _HomeAthliticsNewsImplWidget(contentType,
        updateController: widget.updateController,
      ),
    ));

}

class _HomeAthliticsNewsImplWidget extends StatefulWidget {

  final FavoriteContentType contentType;
  final StreamController<String>? updateController;

  // ignore: unused_element_parameter
  _HomeAthliticsNewsImplWidget(this.contentType, {super.key, this.updateController});

  State<_HomeAthliticsNewsImplWidget> createState() => _HomeAthliticsNewsImplWidgetState();
}

class _HomeAthliticsNewsImplWidgetState extends State<_HomeAthliticsNewsImplWidget> with NotificationsListener {

  List<News>? _news;
  bool _loadingNews = false;
  bool _refreshingNews = false;

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
          _refreshNewsIfVisible();
        }
      });
    }

    _loadNews();

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
      _loadNewsIfVisible();
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
          _refreshNewsIfVisible();
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
        message: Localization().getStringEx("widget.home.athletics_news.text.offline", "Big 10 News is not available while offline."),
      );
    }
    else if (_loadingNews || _refreshingNews) {
      return HomeProgressWidget();
    }
    else {
      return _newsContentWidget;
    }

  }

  Widget get _newsContentWidget {

    Widget? contentWidget;
    List<News>? displayNews = _buildDisplayNews();
    int visibleCount = displayNews?.length ?? 0;

    if (displayNews != null) {
      if (1 < visibleCount) {

        List<Widget> pages = <Widget>[];
        for (News news in displayNews) {
          pages.add(Padding(
            key: _contentKeys[news.id ?? ''] ??= GlobalKey(),
            padding: HomeCard.defaultPageMargin,
            child: AthleticsNewsCard(news: news, displayMode: CardDisplayMode.home, onTap: () => _onTapNews(news))
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
          AthleticsNewsCard(news: displayNews.first, displayMode: CardDisplayMode.home, onTap: () => _onTapNews(displayNews.first))
        );
      }
    }


    return (contentWidget != null) ? Column(children: <Widget>[
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => visibleCount, centerWidget:
        HomeBrowseLinkButton(
          title: Localization().getStringEx('widget.home.athletics_news.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.athletics_news.button.all.hint', 'Tap to view all news'),
          onTap: _onTapSeeAll,
        ),
      )
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
  static const String localAthleticsNewsHost = 'athletics_news';
  static const String localUrlMacro = '{{local_url}}';
  static const String privacyScheme = 'privacy';
  static const String privacyLevelHost = 'level';
  static const String privacyUrlMacro = '{{privacy_url}}';

  Widget get _emptyContentWidget {
    if (widget.contentType == FavoriteContentType.all) {
      return HomeMessageCard(message: Localization().getStringEx("widget.home.athletics_news.all.empty.description", "Big 10 News is not available right now."),);
    }
    else if (widget.contentType == FavoriteContentType.my) {
      String message = Localization().getStringEx("widget.home.athletics_news.my.empty.description", "Tap the \u2606 on items in <a href='$localUrlMacro'><b>Big 10 News</b></a> for quick access here.  (<a href='$privacyUrlMacro'>Your privacy level</a> must be at least 2.)")
        .replaceAll(localUrlMacro, '$localScheme://$localAthleticsNewsHost')
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
      if (uri?.host.toLowerCase() == localAthleticsNewsHost.toLowerCase()) {
        Analytics().logSelect(target: 'Big 10 News', source: runtimeType.toString());
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel(contentType: AthleticsContentType.news)));
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
        case FavoriteContentStatus.refresh: _refreshNews(); break;
        case FavoriteContentStatus.reload: _loadNews(); break;
      }
    }
  }

  // Content Data

  Future<void> _loadNewsIfVisible() async {
    if (_visible) {
      return _loadNews();
    }
    else if (_contentStatus.index < FavoriteContentStatus.reload.index) {
      _contentStatus = FavoriteContentStatus.reload;
    }
  }

  Future<void> _loadNews() async {
    if ((_loadingNews == false) && mounted) {
      setState(() {
        _loadingNews = true;
        _refreshingNews = false;
      });

      List<News>? news = await Sports().loadNews(null, 0);

      setStateIfMounted(() {
        _news = news;
        _contentStatus = FavoriteContentStatus.none;
        _loadingNews = false;
        _contentKeys.clear();
      });
    }
  }

  Future<void> _refreshNewsIfVisible() async {
    if (_visible) {
      return _refreshNews();
    }
    else if (_contentStatus.index < FavoriteContentStatus.refresh.index) {
      _contentStatus = FavoriteContentStatus.refresh;
    }
  }

  Future<void> _refreshNews() async {
    if ((_loadingNews == false) && (_refreshingNews == false) && mounted) {
      setState(() {
        _refreshingNews = true;
      });

      List<News>? news = await Sports().loadNews(null, 0);

      if (mounted && _refreshingNews && (news != null) && !DeepCollectionEquality().equals(_news, news)) {
        setState(() {
          _news = news;
          _contentStatus = FavoriteContentStatus.none;
          _refreshingNews = false;
          _pageViewKey = UniqueKey();
          _contentKeys.clear();
          // _pageController = null;
          if ((_news?.isNotEmpty == true) && (_pageController?.hasClients == true)) {
            _pageController?.jumpToPage(0);
          }
        });
      }
    }
  }

  List<News>? _buildDisplayNews() {
    switch (widget.contentType) {
      case FavoriteContentType.my: return _buildFavoriteNews();
      case FavoriteContentType.all: return _news;
    }
  }

  List<News>? _buildFavoriteNews() {
    List<News>? newsList = _news;
    LinkedHashSet<String>? favoriteNews = Auth2().prefs?.getFavorites(News.favoriteKeyName);
    if ((newsList != null) && (favoriteNews != null)) {
      Map<String, News> favorites = <String, News>{};
      if (newsList.isNotEmpty && favoriteNews.isNotEmpty) {
        for (News news in newsList) {
          if ((news.favoriteId != null) && favoriteNews.contains(news.favoriteId)) {
            favorites[news.favoriteId!] = news;
          }
        }
      }

      List<Favorite>? result = <Favorite>[];
      if (favorites.isNotEmpty) {
        for (String favoriteId in favoriteNews) {
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

  void _onTapNews(News news) {
    Analytics().logSelect(target: "News: '${news.title}'", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsNewsArticlePanel(article: news)));
  }

  void _onTapSeeAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel(contentType: AthleticsContentType.news, starred: widget.contentType == FavoriteContentType.my)));
  }
}

extension _FavoriteAthleticsNewsContentType on FavoriteContentType {
  String get athleticsNewsTitle {
    switch (this) {
      case FavoriteContentType.my: return Localization().getStringEx('widget.home.athletics_news.my.button.title', 'My Big 10 News');
      case FavoriteContentType.all: return Localization().getStringEx('widget.home.athletics_news.all.button.title', 'All Big 10 News');
    }
  }

}
