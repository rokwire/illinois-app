
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
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
        flatHeight: 0, slantHeight: 0,
        childPadding: EdgeInsets.zero,
        child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (Connectivity().isOffline) {
      return _buildOfflineContent();
    }
    else if (_loadingNews) {
      return _buildLoadingContent();
    }
    else if (CollectionUtils.isEmpty(_news)) {
      return _buildEmptyContent();
    }
    else {
      return _buildNewsContent();
    }

  }

  Widget _buildOfflineContent() {
    return Padding(padding: EdgeInsets.only(left: 32, right: 32, top: 48, bottom: 48), child:
      Column(children: <Widget>[
        Text(Localization().getStringEx("app.offline.message.title", "You appear to be offline"), style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 20, color: Styles().colors?.fillColorPrimary),),
        Container(height:8),
        Text(Localization().getStringEx("widget.home.athletics_news.text.offline", "Athletics News are not available while offline"), style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground),),
    ],),);
  }

  Widget _buildEmptyContent() {
    return Padding(padding: EdgeInsets.only(left: 32, right: 32, top: 48, bottom: 48), child:
      Column(children: [
        Text(Localization().getStringEx("widget.home.athletics_news.text.empty", "Whoops! Nothing to see here."), style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 20, color: Styles().colors?.fillColorPrimary),),
        Container(height:8),
        Text(Localization().getStringEx("widget.home.athletics_news.text.empty.description", "No Athletics News are available right now."), style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground),),
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

  Widget _buildNewsContent() {
    List<Widget> contentList = [];
    if (_news != null) {
      for (News news in _news!) {
        if (contentList.isEmpty && StringUtils.isNotEmpty(news.imageUrl)) {
          contentList.add(ImageSlantHeader(
            slantImageColor: Styles().colors!.fillColorPrimaryTransparent03,
            slantImageAsset: 'images/slant-down-right-blue.png',
            child: _buildNewsCard(news),
            imageUrl: news.imageUrl
          ));
        }
        else {
          contentList.add(_buildNewsCard(news),);
        }
      }
      contentList.add(
          LinkButton(
            title: Localization().getStringEx('widget.home.athletics_news.button.all.title', 'View All'),
            hint: Localization().getStringEx('widget.home.athletics_news.button.all.hint', 'Tap to view all news'),
            onTap: _onTapSeeAll,
          ),

      );
    }
    return Column(children: contentList,);
  }

  Widget _buildNewsCard(News news) {
    return Padding(padding: EdgeInsets.only(top: 16, left: 16, right: 16), child:
      AthleticsNewsCard(news: news, onTap: () => _onTapNews(news)),
    );
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