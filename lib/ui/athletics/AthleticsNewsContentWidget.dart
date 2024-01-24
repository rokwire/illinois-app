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


import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/ui/athletics/AthleticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/athletics/AthleticsNewsCard.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

import 'AthleticsNewsArticlePanel.dart';

class AthleticsNewsContentWidget extends StatefulWidget {

  AthleticsNewsContentWidget();

  @override
  _AthleticsNewsContentWidgetState createState() => _AthleticsNewsContentWidgetState();
}

class _AthleticsNewsContentWidgetState extends State<AthleticsNewsContentWidget>{
  List<News>? _news;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Styles().colors.white,
        child: Column(children: [
          AthleticsTeamsFilterWidget(),
          Expanded(child: SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child: _buildContent()))
        ]));
  }

  void _loadNews() {
    //TBD: DD - implement with filtering etc
    _setLoading(true);
    Sports().loadNews(null, 0).then((news) {
      _news = news;
      _setLoading(false);
    });
  }

  Widget _buildContent() {
    if (_loading) {
      return _buildLoadingContent();
    } else if (_news == null) {
      return _buildErrorContent();
    } else if (_news?.length == 0) {
      return _buildEmptyContent();
    } else {
      return _buildNewsContent();
    }
  }

  Widget _buildLoadingContent() {
    return _buildCenteredWidget(CircularProgressIndicator(color: Styles().colors.fillColorSecondary));
  }

  Widget _buildEmptyContent() {
    return _buildCenteredWidget(Text(Localization().getStringEx('panel.athletics.content.news.empty.message', 'There are no news.'),
        textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.item.medium.fat')));
  }

  Widget _buildErrorContent() {
    return _buildCenteredWidget(Text(
        Localization().getStringEx('panel.athletics.content.news.failed.message', 'Failed to load news.'),
        textAlign: TextAlign.center,
        style: Styles().textStyles.getTextStyle('widget.item.medium.fat')));
  }

  Widget _buildCenteredWidget(Widget child) {
    return Center(child: Column(children: <Widget>[Container(height: _screenHeight / 5), child, Container(height: _screenHeight / 5 * 3)]));
  }

  Widget _buildNewsContent() {
    if (CollectionUtils.isEmpty(_news)) {
      return Container();
    }
    List<Widget> articleWidgets = <Widget>[];
    for (News news in _news!) {
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
    return Column(children: articleWidgets);
  }

  Widget _buildAthleticsNewsCard(News news) {
    return Padding(
        padding: EdgeInsets.only(top: 16, left: 16, right: 16), child: AthleticsNewsCard(news: news, onTap: () => _onTapArticle(news)));
  }

  void _setLoading(bool loading){
    setStateIfMounted(() {
      _loading = loading;
    });
  }

  void _onTapArticle(News article) {
    Analytics().logSelect(target: "Athletics News: " + article.title!);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsNewsArticlePanel(article: article)));
  }

  double get _screenHeight => MediaQuery.of(context).size.height;
}

