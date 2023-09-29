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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';

import 'package:illinois/service/RecentItems.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:share/share.dart';

class AthleticsNewsArticlePanel extends StatefulWidget {
  final String? articleId;
  final News? article;

  AthleticsNewsArticlePanel({this.article, this.articleId});

  @override
  _AthleticsNewsArticlePanelState createState() => _AthleticsNewsArticlePanelState();
}

class _AthleticsNewsArticlePanelState extends State<AthleticsNewsArticlePanel> implements NotificationsListener {

  News? _article;
  bool _loading = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged,
    ]);
    _article = widget.article;
    if (_article != null) {
      RecentItems().addRecentItem(RecentItem.fromSource(_article));
    }
    else {
      _loadNewsArticle();
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
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      if (mounted) {
        setState(() {});
      }
    }
    else if (name == FlexUI.notifyChanged) {
      if (mounted) {
        setState(() {});
      }
    }
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

    bool isNewsFavorite = Auth2().isFavorite(widget.article);

    return CustomScrollView(scrollDirection: Axis.vertical, slivers: <Widget>[
      SliverToutHeaderBar(
        flexImageUrl: _article?.imageUrl,
        flexBackColor: Styles().colors?.white,
        flexRightToLeftTriangleColor: Styles().colors?.white,
        flexLeftToRightTriangleColor: Styles().colors?.fillColorSecondaryTransparent05,
      ),
      SliverList(delegate: SliverChildListDelegate([
        Container(color: Styles().colors!.background, child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Column(children: <Widget>[
              Container(color: Colors.white, child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Padding(padding: EdgeInsets.only(top: 8, bottom: 8, left: 24, right: 8), child:
                    Row(children: <Widget>[
                      Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 86),
                        color: Styles().colors!.fillColorPrimary,
                        child: Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: Text(_article?.category?.toUpperCase() ?? '',
                            style: Styles().textStyles?.getTextStyle("widget.title.light.small.fat.spaced"),
                          ),
                        ),
                      ),
                      Expanded(child: Container(),),
                      Visibility(visible: Auth2().canFavorite, child:
                        Semantics(button: true, checked: isNewsFavorite,
                          label: Localization().getStringEx("panel.athletics_news_article.button.save_game.title", "Save Article"),
                          hint: Localization().getStringEx("panel.athletics_news_article.button.save_game.hint", "Tap to save"),
                          child: GestureDetector(onTap: _onTapSwitchFavorite, child:
                            Container(padding: EdgeInsets.all(24), child:
                              Styles().images?.getImage(isNewsFavorite ? 'star-filled' : 'star-outline-gray', excludeFromSemantics: true),
                            ),
                          ),
                        ),
                      ),
                    ],),
                  ),
                  Padding(padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 24), child:
                    Text(_article?.title ?? '', style: Styles().textStyles?.getTextStyle("widget.title.extra_large"),
                    ),
                  ),
                  Padding(padding: EdgeInsets.only(left: 24, right: 24, bottom: 24), child:
                    Row(children: <Widget>[
                      Styles().images?.getImage('news', excludeFromSemantics: true) ?? Container(),
                      Container(width: 5,),
                      Text(_article?.displayTime ?? '', style: Styles().textStyles?.getTextStyle("widget.item.regular"),
                      ),
                    ],),
                  ),
                ],),
              ),
              Padding(padding: EdgeInsets.all(24), child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children:
                  _buildContentWidgets(context),
                ),
              ),
              StringUtils.isNotEmpty(_article?.link) ? Padding(padding: EdgeInsets.only(left: 20, right: 20, bottom: 48), child:
                RoundedButton(
                  label: 'Share this article', //TBD localize
                  textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat"),
                  backgroundColor: Styles().colors!.background,
                  borderColor: Styles().colors!.fillColorSecondary,
                  onTap: _shareArticle,
                ),
              ) : Container()
            ],)
          ],),
        ),
      ]),
    )
  ],);
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
        child:
        HtmlWidget(
            StringUtils.ensureNotEmpty(_article!.description),
          textStyle:  Styles().textStyles?.getTextStyle("widget.item.regular.thin"),
        )
      ));
    }
    String? fullText = _article?.fillText;
    if (!StringUtils.isEmpty(fullText)) {
      widgets.add(Padding(
        padding: EdgeInsets.only(bottom: 24),
        child:
        HtmlWidget(
            StringUtils.ensureNotEmpty(fullText),
            textStyle:  Styles().textStyles?.getTextStyle("widget.item.regular.thin"),
            onTapUrl : (url) {
              Navigator.push(context, CupertinoPageRoute(
                      builder: (context) => WebPanel(url: url,)
              ));
              return true;
            },
        )
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

  void _onTapSwitchFavorite() {
    Analytics().logSelect(target: "Favorite: ${widget.article?.title}");
    Auth2().prefs?.toggleFavorite(widget.article);
  }

}
