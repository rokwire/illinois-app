/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:rokwire_plugin/service/localization.dart';

import 'package:illinois/service/RecentItems.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:share/share.dart';
import 'package:html/dom.dart' as dom;

class AthleticsNewsArticlePanel extends StatefulWidget {
  final String? articleId;
  final News? article;

  AthleticsNewsArticlePanel({this.article, this.articleId});

  @override
  _AthleticsNewsArticlePanelState createState() => _AthleticsNewsArticlePanelState();
}

class _AthleticsNewsArticlePanelState extends State<AthleticsNewsArticlePanel> {

  News? _article;
  bool _loading = false;

  @override
  void initState() {
    _article = widget.article;
    if (_article != null) {
      RecentItems().addRecentItem(RecentItem.fromSource(_article));
    }
    else {
      _loadNewsArticle();
    }

    super.initState();
  }

  void _loadNewsArticle() {
    _setLoading(true);
    Sports().loadNewsArticle(widget.articleId).then((article) {
      _article = article;
      RecentItems().addRecentItem(RecentItem.fromSource(_article));
      _setLoading(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildContent(context),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
}

  Widget _buildContent(BuildContext context) {
    if (_loading == true) {
      return Center(child: CircularProgressIndicator());
    }

    if (_article == null) {
      return Center(child: Text(Localization().getStringEx('panel.athletics_news_article.load.failed.msg', 'Failed to load news article. Please, try again.')));
    }

    return CustomScrollView(
        scrollDirection: Axis.vertical,
        slivers: <Widget>[
            SliverToutHeaderBar(
            flexImageUrl: _article?.imageUrl,
            flexBackColor: Styles().colors?.white,
            flexRightToLeftTriangleColor: Styles().colors?.white,
            flexLeftToRightTriangleColor: Styles().colors?.fillColorSecondaryTransparent05,
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Container(
                color: Styles().colors!.background,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: <Widget>[
                        Container(
                          child: Column(
                            children: <Widget>[
                              Column(
                                children: <Widget>[
                                  Container(
                                    color: Colors.white,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 24),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Row(
                                            children: <Widget>[
                                              Container(
                                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 86),
                                                color: Styles().colors!.fillColorPrimary,
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 6, horizontal: 8),
                                                  child: Text(
                                                    _article?.category?.toUpperCase() ?? '',
                                                    style: TextStyle(
                                                        fontFamily: Styles().fontFamilies!.bold,
                                                        fontSize: 14,
                                                        letterSpacing: 1.0,
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding:
                                            EdgeInsets.only(top: 12, bottom: 24),
                                            child: Text(
                                              _article?.title ?? '',
                                              style: TextStyle(
                                                  fontSize: 24,
                                                  color: Styles().colors!.fillColorPrimary),
                                            ),
                                          ),
                                          Row(
                                            children: <Widget>[
                                              Image.asset('images/icon-news.png'),
                                              Container(width: 5,),
                                              Text(_article?.displayTime ?? '',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      color: Styles().colors!.textBackground,
                                                      fontFamily: Styles().fontFamilies!.medium
                                                  )),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                      child: Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: _buildContentWidgets(context),
                                        ),
                                      )),
                                  StringUtils.isNotEmpty(_article?.link)?
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: 20, right: 20, bottom: 48),
                                    child: RoundedButton(
                                      label: 'Share this article',
                                      backgroundColor: Styles().colors!.background,
                                      textColor: Styles().colors!.fillColorPrimary,
                                      borderColor: Styles().colors!.fillColorSecondary,
                                      fontSize: 16,
                                      onTap: () => {
                                        _shareArticle()
                                      },
                                    ),
                                  ) : Container()
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ])
          )
        ],
      );
  }

  _shareArticle(){
    Analytics().logSelect(target: "Share Article");
    if (StringUtils.isNotEmpty(_article?.link)) {
      Share.share(_article!.link!);
    }
  }

  List<Widget> _buildContentWidgets(BuildContext context) {
    List<Widget> widgets = [];
    if (!StringUtils.isEmpty(_article?.description)) {
      widgets.add(Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Html(
          data:_article!.description!,
          style: {
            "body": Style(color: Styles().colors!.textBackground)
          },
        ),
      ));
    }
    String? fullText = _article?.fillText;
    if (!StringUtils.isEmpty(fullText)) {
      widgets.add(Padding(
        padding: EdgeInsets.only(bottom: 24),
        child: Html(
          data:fullText,
          onLinkTap: (String? url,
              RenderContext context1,
              Map<String, String> attributes,
              dom.Element? element){
            Navigator.push(context, CupertinoPageRoute(
                builder: (context) => WebPanel(url: url,)
            ));
          },
        ),
      ));
    }
    return widgets;
  }

  void _setLoading(bool loading) {
    _loading = loading;
    if (mounted) {
      setState(() {});
    }
  }
}
