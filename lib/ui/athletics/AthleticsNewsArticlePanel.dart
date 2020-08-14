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

import 'package:illinois/service/RecentItems.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';
import 'package:share/share.dart';

class AthleticsNewsArticlePanel extends StatelessWidget {
  final News article;

  AthleticsNewsArticlePanel({@required this.article}){
    RecentItems().addRecentItem(RecentItem.fromOriginalType(article));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildContent(context),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
}

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
        scrollDirection: Axis.vertical,
        slivers: <Widget>[
            SliverToutHeaderBar(
            context: context,
            imageUrl: article.getImageUrl(),
            backColor: Styles().colors.white,
            leftTriangleColor: Styles().colors.white,
            rightTriangleColor: Styles().colors.fillColorSecondaryTransparent05,
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Container(
                color: Styles().colors.background,
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
                                                color: Styles().colors.fillColorPrimary,
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 6, horizontal: 8),
                                                  child: Text(
                                                    article.category?.toUpperCase(),
                                                    style: TextStyle(
                                                        fontFamily: Styles().fontFamilies.bold,
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
                                              article.title,
                                              style: TextStyle(
                                                  fontSize: 24,
                                                  color: Styles().colors.fillColorPrimary),
                                            ),
                                          ),
                                          Row(
                                            children: <Widget>[
                                              Image.asset('images/icon-news.png'),
                                              Container(width: 5,),
                                              Text(article.getDisplayTime(),
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      color: Styles().colors.textBackground,
                                                      fontFamily: Styles().fontFamilies.medium
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
                                  AppString.isStringNotEmpty(article?.link)?
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: 20, right: 20, bottom: 48),
                                    child: RoundedButton(
                                      label: 'Share this article',
                                      backgroundColor: Styles().colors.background,
                                      textColor: Styles().colors.fillColorPrimary,
                                      borderColor: Styles().colors.fillColorSecondary,
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
    Analytics.instance.logSelect(target: "Share Article");
    Share.share(article.link);
  }

  List<Widget> _buildContentWidgets(BuildContext context) {
    List<Widget> widgets = List();
    if (!AppString.isStringEmpty(article.description)) {
      widgets.add(Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Html(
          data:article.description,
          defaultTextStyle: TextStyle(color: Styles().colors.textBackground, fontSize: 20)
        ),
      ));
    }
    String fullText = article.getFillText();
    if (!AppString.isStringEmpty(fullText)) {
      widgets.add(Padding(
        padding: EdgeInsets.only(bottom: 24),
        child: Html(
          data:fullText,
            onLinkTap: (url){
              Navigator.push(context, CupertinoPageRoute(
                builder: (context) => WebPanel(url: url,)
              ));
            },
        ),
      ));
    }
    return widgets;
  }
}
