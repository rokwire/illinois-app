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

import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class AthleticsNewsCard extends StatefulWidget {
  final GestureTapCallback? onTap;
  final News? news;

  AthleticsNewsCard({Key? key, this.onTap, this.news}) : super(key: key);

  @override
  _AthleticsNewsCardState createState() => _AthleticsNewsCardState();
}

class _AthleticsNewsCardState extends State<AthleticsNewsCard> implements NotificationsListener {

  static const EdgeInsets _detailPadding = EdgeInsets.only(left: 24, right: 24);
  static const EdgeInsets _iconPadding = EdgeInsets.only(right: 5);

  @override
  void initState() {
    NotificationService().subscribe(this, Auth2UserPrefs.notifyFavoritesChanged);
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
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: new Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    boxShadow: [const BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _newsCategory(),
                      _newsName(),
                      _newsDetails(),
                    ],
                  ),
                ),
              ),
              _topBorder(),
            ]));
  }

  Widget _newsCategory() {
    bool isFavorite = Auth2().isFavorite(widget.news);
    String? category = widget.news!.category;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              color: Styles().colors!.fillColorPrimary,
              constraints: new BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 106),
              child: Padding(
              padding: EdgeInsets.only(left: 8, right: 8, top:6, bottom: 4),
                child:
                     Text(
                      (category != null) ? category.toUpperCase() : "",
                      softWrap: true,
                      style: TextStyle(
                          fontFamily: Styles().fontFamilies!.bold,
                          fontSize: 14,
                          color: Colors.white),
                    )
                 ),
              ),
            ),
          Visibility(visible: Auth2().canFavorite,
            child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTapSave,
                child: Semantics(
                    label: isFavorite
                        ? Localization().getStringEx(
                        'widget.card.button.favorite.off.title',
                        'Remove From Favorites')
                        : Localization().getStringEx(
                        'widget.card.button.favorite.on.title',
                        'Add To Favorites'),
                    hint: isFavorite ? Localization()
                        .getStringEx(
                        'widget.card.button.favorite.off.hint',
                        '') : Localization().getStringEx(
                        'widget.card.button.favorite.on.hint',
                        ''),
                    excludeSemantics: true,
                    child: Container(child: Padding(
                        padding: EdgeInsets.only(
                            left: 24,
                            bottom: 0),
                        child: Image.asset(isFavorite
                            ? 'images/icon-star-blue.png'
                            : 'images/icon-star-gray-frame-thin.png')
                    ))
                )),)
        ],
      ),
    );
  }

  Widget _newsName() {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 12),
      child: Text(
        (widget.news!.title != null) ? widget.news!.title! : "",
        style:
        TextStyle(fontSize: 24,
            color: Styles().colors!.fillColorPrimary),
      ),
    );
  }

  Widget _newsDetails() {
    List<Widget> details = [];

    Widget? time = _newsTimeDetail();
    if (time != null) {
      details.add(time);
    }

    return (0 < details.length)
        ? Padding(
        padding: EdgeInsets.only(top: 12),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: details))
        : Container();
  }

  Widget? _newsTimeDetail() {
    News? news = widget.news;
    String? displayTime = news?.displayTime;
    if ((displayTime != null) && displayTime.isNotEmpty) {
      return Padding(
        padding: _detailPadding,
        child: Row(
          children: <Widget>[
            Image.asset('images/icon-news.png'),
            Padding(
              padding: _iconPadding,
            ),
            Text(displayTime,
                style: TextStyle(
                    fontSize: 16,
                    color: Styles().colors!.textBackground,
                    fontFamily: Styles().fontFamilies!.medium
                     )),
          ],
        ),
      );
    } else {
      return null;
    }
  }

  Widget _topBorder() {
    Color? borderColor = Styles().colors!.fillColorPrimary;
    return _showTopBorder()? Container(height: 7,color: borderColor) : Container();
  }

  bool _showTopBorder(){
    return widget.news?.imageUrl == null;
  }

  void _onTapSave() {
    Analytics().logSelect(target: "Favorite: ${widget.news?.title}");
    Auth2().prefs?.toggleFavorite(widget.news);
  }

}