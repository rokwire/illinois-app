/*
 * Copyright 2024 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/ui/athletics/AthleticsWidgets.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/athletics/AthleticsNewsCard.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

import 'AthleticsNewsArticlePanel.dart';

class AthleticsNewsContentWidget extends StatefulWidget {

  final bool? showFavorites;

  AthleticsNewsContentWidget({this.showFavorites});

  @override
  _AthleticsNewsContentWidgetState createState() => _AthleticsNewsContentWidgetState();
}

class _AthleticsNewsContentWidgetState extends State<AthleticsNewsContentWidget> with NotificationsListener {
  List<News>? _news;
  List<News>? _displayNews;

  bool _loading = false;

  static const String _privacyUrl = 'privacy://level';
  static const String _privacyUrlMacro = '{{privacy_url}}';

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Auth2UserPrefs.notifyInterestsChanged, Auth2UserPrefs.notifyFavoritesChanged]);
    _loadNews();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(AthleticsNewsContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showFavorites != oldWidget.showFavorites) {
      setStateIfMounted(() {
        _displayNews = _buildDisplayNews();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Styles().colors.surface,
        child: Column(children: [
          AthleticsTeamsFilterWidget(favoritesMode: _favoritesMode),
          Expanded(child: _buildContent())
        ]));
  }

  void _loadNews() {
    setStateIfMounted(() {
      _loading = true;
    });
    Sports().loadNews(null, 0).then((news) {
      _news = news;
      setStateIfMounted(() {
        _loading = false;
        _displayNews = _buildDisplayNews();
      });
    });
  }

  List<News>? _buildDisplayNews() {
    Set<String>? favoriteSports = Auth2().prefs?.sportsInterests;
    if (CollectionUtils.isEmpty(favoriteSports)) {
      return <News>[];
    } else if (_news == null) {
      return null;
    } else {
      List<News> displayNews = <News>[];
      LinkedHashSet<String>? favoriteIds = Auth2().account?.prefs?.getFavorites(News.favoriteKeyName);
      for (News article in _news!) {
        if ((favoriteSports?.contains(article.sportKey) == true) && (!_favoritesMode || (favoriteIds?.contains(article.id) == true))) {
          displayNews.add(article);
        }
      }
      return displayNews;
    }
  }

  Widget _buildContent() {
    if (_loading) {
      return _buildLoadingContent();
    } else if (_displayNews == null) {
      return _buildErrorContent();
    } else if (_displayNews?.length == 0) {
      return _buildEmptyContent();
    } else {
      return _buildNewsContent();
    }
  }

  Widget _buildLoadingContent() {
    return _buildCenteredWidget(CircularProgressIndicator(color: Styles().colors.fillColorSecondary));
  }

  Widget _buildEmptyContent() {
    return _buildCenteredWidget(
      HtmlWidget("<center>$_emptyMessageHtml</center>",
        onTapUrl : _handleLocalUrl,
        textStyle:  Styles().textStyles.getTextStyle('widget.item.medium'),
        customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null,
      )
    );
  }

  bool _handleLocalUrl(String? url) {
    if (url == _privacyUrl) {
      Analytics().logSelect(target: 'Privacy Level', source: widget.runtimeType.toString());
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,)));
      return true;
    }
    else {
      return false;
    }
  }

  Widget _buildErrorContent() {
    return _buildCenteredWidget(Text(
        Localization().getStringEx('panel.athletics.content.news.failed.message', 'Failed to load news.'),
        textAlign: TextAlign.center,
        style: Styles().textStyles.getTextStyle('widget.item.medium.fat')));
  }

  Widget _buildCenteredWidget(Widget child) {
    return Padding(padding: EdgeInsets.symmetric(vertical: 32, horizontal: 48), child:
      Center(child: child)
    );
  }

  Widget _buildNewsContent() {
    if (CollectionUtils.isEmpty(_displayNews)) {
      return Container();
    }
    List<Widget> articleWidgets = <Widget>[];
    for (News news in _displayNews!) {
      String? imageUrl = news.imageUrl;
      late Widget card;
      if (StringUtils.isNotEmpty(imageUrl)) {
        card = ImageSlantHeader(
            imageUrl: news.imageUrl,
            slantImageColor: Styles().colors.fillColorPrimaryTransparent03,
            slantImageKey: 'slant-dark',
            child: _buildAthleticsNewsCard(news));
      } else {
        card = _buildAthleticsNewsCard(news);
      }
      articleWidgets.add(Padding(padding: EdgeInsets.only(bottom: 16), child: card));
    }
    return SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child: Column(children: articleWidgets));
  }

  Widget _buildAthleticsNewsCard(News news) {
    return Padding(
        padding: EdgeInsets.only(top: 16, left: 16, right: 16), child: AthleticsNewsCard(news: news, onTap: () => _onTapArticle(news)));
  }

  void _onTapArticle(News article) {
    Analytics().logSelect(target: "Athletics News: " + article.title!);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsNewsArticlePanel(article: article)));
  }

  bool get _favoritesMode => (widget.showFavorites == true);

  String get _emptyMessageHtml {
    return _favoritesMode ?
      Localization().getStringEx('panel.athletics.content.news.my.empty.message', "There is no starred news for the selected teams. (<a href='$_privacyUrlMacro'>Your privacy level</a> must be at least 2.)").replaceAll(_privacyUrlMacro, _privacyUrl) :
      Localization().getStringEx('panel.athletics.content.news.empty.message', 'There is no news for the selected teams.');
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == Auth2UserPrefs.notifyInterestsChanged) {
      setStateIfMounted(() {
        _displayNews = _buildDisplayNews();
      });
    } else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      if (_favoritesMode) {
        setStateIfMounted((){
          _displayNews = _buildDisplayNews();
        });
      }
    }
  }
}

