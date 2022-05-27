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

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/RecentItems.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsArticlePanel.dart';
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreDetailPanel.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class HomeRecentItemsWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<void>? refreshController;
  final HomeDragAndDropHost? dragAndDropHost;

  HomeRecentItemsWidget({Key? key, this.favoriteId, this.refreshController, this.dragAndDropHost}) : super(key: key);

  @override
  _HomeRecentItemsWidgetState createState() => _HomeRecentItemsWidgetState();
}

class _HomeRecentItemsWidgetState extends State<HomeRecentItemsWidget> implements NotificationsListener {

  List<RecentItem>? _recentItems;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, RecentItems.notifyChanged);

    if (widget.refreshController != null) {
      widget.refreshController!.stream.listen((_) {
        _loadRecentItems();
      });
    }

    _loadRecentItems();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    return _RecentItemsList(favoriteId: widget.favoriteId, dragAndDropHost: widget.dragAndDropHost,
      heading: Localization().getStringEx('panel.home.label.recently_viewed', 'Recently Viewed'),
      items: _recentItems,
    );
  }

  void _loadRecentItems() {
    if (mounted) {
      setState(() {
        _recentItems = RecentItems().recentItems.toSet().toList();
      });
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == RecentItems.notifyChanged) {
      if (mounted) {
        SchedulerBinding.instance!.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _recentItems = RecentItems().recentItems.toSet().toList();
            });
          }
        });
      }
    }
  }
}

class _RecentItemsList extends StatelessWidget{
  final String? heading;
  final List<RecentItem>? items;
  final int limit;
  final String? moreButtonLabel;
  final void Function()? tapMore;
  final String? favoriteId;
  final HomeDragAndDropHost? dragAndDropHost;


  const _RecentItemsList(
      {Key? key, this.items, this.heading,
        this.tapMore, this.limit = 3,
        this.moreButtonLabel, this.favoriteId, this.dragAndDropHost})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Visibility(visible: CollectionUtils.isNotEmpty(items), child:
      HomeDropTargetWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, child:
        HomeSlantWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost,
            title: heading,
            child: Column(children: _buildListItems(context),)
        ),
      ),
    );
  }

  List<Widget> _buildListItems(BuildContext context){
    List<Widget> widgets =  [];
    if (items?.isNotEmpty??false){
      
      int visibleCount = (items!.length < limit) ? items!.length : limit;
      for (int i = 0 ; i < visibleCount; i++) {
        RecentItem item = items![i];
        if (0 < widgets.length) {
          widgets.add(Container(height: 4));
        }
        widgets.add(_buildItemCart(recentItem: item, context: context));
      }

      if ((tapMore != null) && (limit < items!.length)) {
        widgets.add(Padding(padding: EdgeInsets.only(top: 16), child:
          SmallRoundedButton(
            label: StringUtils.isNotEmpty(moreButtonLabel) ? moreButtonLabel! : Localization().getStringEx('widget.home_recent_items.button.more.title', 'View All'),
            hint: Localization().getStringEx('widget.home_recent_items.button.more.hint', ''),
            onTap: tapMore ?? (){},),
        ));
      }
      
      widgets.add(Container(height: 16,));
    }

    
    return widgets;
  }

  Widget _buildItemCart({RecentItem? recentItem, BuildContext? context}) {
    return _HomeRecentItemCard(item: recentItem, onTap: () {
        Analytics().logSelect(target: "HomeRecentItemCard clicked: " + recentItem!.recentTitle!);
        Navigator.push(context!, CupertinoPageRoute(builder: (context) => _getDetailPanel(recentItem)));
      },);
  }

  static Widget _getDetailPanel(RecentItem item) {
    Object? originalObject = item.fromOriginalJson();
    if (originalObject is News) { // News
      return AthleticsNewsArticlePanel(article: originalObject,);
    } else if (originalObject is Game) { // Game
      return AthleticsGameDetailPanel(game: originalObject,);
    } else if (originalObject is Explore) { // Event or Dining
      if (originalObject is Event && originalObject.isComposite) {
        return CompositeEventsDetailPanel(parentEvent: originalObject);
      }
      return ExploreDetailPanel(explore: originalObject,);
    }
    else if ((item.recentItemType == RecentItemType.guide) && (originalObject is Map)) {
      return GuideDetailPanel(guideEntryId: Guide().entryId(JsonUtils.mapValue(originalObject)));
    }

    return Container();
  }
}

class _HomeRecentItemCard extends StatefulWidget {
  final bool showDate;
  final RecentItem? item;
  final GestureTapCallback? onTap;

  _HomeRecentItemCard(
      {required this.item, this.onTap, this.showDate = false}) {
    assert(item != null);
  }

  @override
  _HomeRecentItemCardState createState() => _HomeRecentItemCardState();
}

class _HomeRecentItemCardState extends State<_HomeRecentItemCard> implements NotificationsListener {

//  Object _originalItem;

  @override
  void initState() {
    NotificationService().subscribe(this, Auth2UserPrefs.notifyFavoritesChanged);
//    _originalItem = widget.item.fromOriginalJson();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isFavorite;
    Object? originalItem = widget.item!.fromOriginalJson();
    if (originalItem is Favorite) {
      isFavorite = Auth2().isFavorite(originalItem);
    }
    else if ((widget.item!.recentItemType == RecentItemType.guide) && (originalItem is Map)) {
      isFavorite = Auth2().isFavorite(GuideFavorite(id: Guide().entryId(JsonUtils.mapValue(originalItem))));
    }
    else {
      isFavorite = false;
    }

    String? favLabel = isFavorite ?
      Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') :
      Localization().getStringEx('widget.card.button.favorite.on.title','Add To Favorites');
    String? favHint = isFavorite ?
      Localization().getStringEx('widget.card.button.favorite.off.hint', '') :
      Localization().getStringEx('widget.card.button.favorite.on.hint','');
    String favIcon = isFavorite ? 'images/icon-star-selected.png' : 'images/icon-star.png';

    return Padding(padding: EdgeInsets.only(bottom: 8), child:
      Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), clipBehavior: Clip.none, child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
          Stack(children: [
            GestureDetector(behavior: HitTestBehavior.translucent, onTap: widget.onTap, child:
              Container(color: Colors.white, padding: EdgeInsets.all(16), child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Expanded(child:
                      Padding(padding: EdgeInsets.only(right: 24), child:
                        Text(widget.item!.recentTitle ?? '', style: TextStyle(fontSize: 18, fontFamily: Styles().fontFamilies!.extraBold, color: Styles().colors!.fillColorPrimary,),)
                      ),
                    ),
                  ]),
                  Padding(padding: EdgeInsets.only(top: 10), child:
                    Column(children: _buildDetails()),
                  )
                ])
              )
            ),
            _topBorder(),
            Visibility(visible: Auth2().canFavorite, child:
              Align(alignment: Alignment.topRight, child:
                GestureDetector(onTap: _onTapFavorite, child:
                  Semantics(excludeSemantics: true, label: favLabel, hint: favHint, child:
                    Container(padding: EdgeInsets.all(16), child: 
                      Image.asset(favIcon)
              ),),),),
            ),

          ],),
      ),
    ),);
  }

  List<Widget> _buildDetails() {
    List<Widget> details =  [];
    if(StringUtils.isNotEmpty(widget.item!.recentTime)) {
      Widget? dateDetail = widget.showDate ? _dateDetail() : null;
      if (dateDetail != null) {
        details.add(dateDetail);
      }
      Widget? timeDetail = _timeDetail();
      if (timeDetail != null) {
        if (details.isNotEmpty) {
          details.add(Container(height: 8,));
        }
        details.add(timeDetail);
      }
    }
    Widget? descriptionDetail = ((widget.item!.recentItemType == RecentItemType.guide) && StringUtils.isNotEmpty(widget.item!.recentDescripton)) ? _descriptionDetail() : null;
    if (descriptionDetail != null) {
      if (details.isNotEmpty) {
        details.add(Container(height: 8,));
      }
      details.add(descriptionDetail);
    }
    return details;
  }

  //Not used any more
  Widget? _dateDetail(){
    String? displayTime = widget.item!.recentTime;
    if ((displayTime != null) && displayTime.isNotEmpty) {
      String displayDate = Localization().getStringEx('widget.home_recent_item_card.label.date', 'Date');
      return Semantics(label: displayDate, excludeSemantics: true, child:
        Row(children: <Widget>[
          Image.asset('images/icon-calendar.png'),
          Padding(padding: EdgeInsets.only(right: 5),),
          Text(displayDate, style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 12, color: Styles().colors!.textBackground)),
        ],),
      );
    } else {
      return null;
    }
  }

  Widget? _timeDetail() {
    String? displayTime = widget.item!.recentTime;
    if ((displayTime != null) && displayTime.isNotEmpty) {
      return Semantics(label: displayTime, excludeSemantics: true, child:
        Row(children: <Widget>[
            Image.asset('images/icon-calendar.png'),
            Padding(padding: EdgeInsets.only(right: 5),),
            Text(displayTime, style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 12, color: Styles().colors!.textBackground)),
        ],),
      );
    } else {
      return null;
    }
  }

  Widget _descriptionDetail() {
    return Semantics(label: widget.item!.recentDescripton ?? '', excludeSemantics: true, child:
      Text(widget.item!.recentDescripton ?? '', style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 14, color: Styles().colors!.textBackground)),
    );
  }

  Widget _topBorder() {
    Object? originalItem = widget.item!.fromOriginalJson();
    Color? borderColor = Styles().colors!.fillColorPrimary;
    if (originalItem is Explore) {
      borderColor = originalItem.uiColor;
    }
    else if (widget.item!.recentItemType == RecentItemType.guide) {
      borderColor = Styles().colors!.accentColor3;
    }
    else {
      borderColor = Styles().colors!.fillColorPrimary;
    }
    return Container(height: 7, color: borderColor);
  }

  void _onTapFavorite() {
    Analytics().logSelect(target: "Favorite: ${widget.item?.recentTitle}");
    Object? originalItem = widget.item!.fromOriginalJson();
    if (originalItem is Favorite) {
      Auth2().prefs?.toggleFavorite(originalItem);
    }
    else if ((widget.item!.recentItemType == RecentItemType.guide) && (originalItem is Map)) {
      Auth2().prefs?.toggleFavorite(GuideFavorite(
        id: Guide().entryId(JsonUtils.mapValue(originalItem)),
      ));
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      if (mounted){
        setState(() {});
      }
    }
  }
}

