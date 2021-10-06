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
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/RecentItems.dart';
import 'package:illinois/service/StudentGuide.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsArticlePanel.dart';
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreDetailPanel.dart';
import 'package:illinois/ui/guide/StudentGuideDetailPanel.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/SectionTitlePrimary.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class HomeRecentItemsWidget extends StatefulWidget {

  final StreamController<void> refreshController;

  HomeRecentItemsWidget({this.refreshController});

  @override
  _HomeRecentItemsWidgetState createState() => _HomeRecentItemsWidgetState();
}

class _HomeRecentItemsWidgetState extends State<HomeRecentItemsWidget> implements NotificationsListener {

  List<RecentItem> _recentItems;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, RecentItems.notifyChanged);

    if (widget.refreshController != null) {
      widget.refreshController.stream.listen((_) {
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
    return _RecentItemsList(
      heading: Localization().getStringEx('panel.home.label.recently_viewed', 'Recently Viewed'),
      headingIconRes: 'images/campus-tools.png',
      items: _recentItems,
    );
  }

  void _loadRecentItems() {
    setState(() {
      _recentItems = RecentItems().recentItems?.toSet()?.toList();
    });
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == RecentItems.notifyChanged) {
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) => setState(() {
          _recentItems = RecentItems().recentItems?.toSet()?.toList();
        }));
      }
    }
  }
}

class _RecentItemsList extends StatelessWidget{
  final int limit;
  final List<RecentItem> items;
  final String heading;
  final String subTitle;
  final String headingIconRes;
  final String slantImageRes;
  final Color slantColor;
  final Function tapMore;
  final bool showMoreChevron;
  final bool showMoreButtonExplicitly;
  final String moreButtonLabel;

  //Card Options
  final bool cardShowDate;

  const _RecentItemsList(
      {Key key, this.items, this.heading, this.subTitle, this.headingIconRes,
        this.slantImageRes = 'images/slant-down-right-blue.png', this.slantColor, this.tapMore, this.cardShowDate = false, this.limit = 3, this.showMoreChevron = true,
        this.moreButtonLabel, this.showMoreButtonExplicitly = false,})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool showMoreButton =showMoreButtonExplicitly ||( tapMore!=null && limit<(items?.length??0));
    String moreLabel = AppString.isStringEmpty(moreButtonLabel)? Localization().getStringEx('widget.home_recent_items.button.more.title', 'View All'): moreButtonLabel;
    return items!=null && items.isNotEmpty? Column(
      children: <Widget>[
        SectionTitlePrimary(
            title:heading,
            subTitle: subTitle,
            iconPath: headingIconRes,
            children: _buildListItems(context)
        ),
        !showMoreButton?Container():
        Container(height: 20,),
        !showMoreButton?Container():
        SmallRoundedButton(
          label: moreLabel,
          hint: Localization().getStringEx('widget.home_recent_items.button.more.hint', ''),
          onTap: tapMore,
          showChevron: showMoreChevron,),
        Container(height: 48,),
      ],
    ) : Container();

  }

  List<Widget> _buildListItems(BuildContext context){
    List<Widget> widgets =  [];
    if(items?.isNotEmpty??false){
      int visibleCount = items.length<limit?items.length:limit;
      for(int i = 0 ; i<visibleCount; i++) {
        RecentItem item = items[i];
        widgets.add(_buildItemCart(
            recentItem: item, context: context));
      }
    }
    return widgets;
  }

  Widget _buildItemCart({RecentItem recentItem, BuildContext context}) {
    return _HomeRecentItemCard(
      item: recentItem,
      showDate: cardShowDate,
      onTap: () {
        Analytics.instance.logSelect(target: "HomeRecentItemCard clicked: " + recentItem.recentTitle);
        Navigator.push(context, CupertinoPageRoute(builder: (context) => _getDetailPanel(recentItem)));
      },);
  }

  static Widget _getDetailPanel(RecentItem item) {
    Object originalObject = item.fromOriginalJson();
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
    else if ((item.recentItemType == RecentItemType.studentGuide) && (originalObject is Map)) {
      return StudentGuideDetailPanel(guideEntryId: StudentGuide().entryId(originalObject));
    }

    return Container();
  }
}

class _HomeRecentItemCard extends StatefulWidget {
  final bool showDate;
  final RecentItem item;
  final GestureTapCallback onTap;

  _HomeRecentItemCard(
      {@required this.item, this.onTap, this.showDate = false}) {
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
    Object originalItem = widget.item.fromOriginalJson();
    if (originalItem is Favorite) {
      isFavorite = Auth2().isFavorite(originalItem);
    }
    else if ((widget.item.recentItemType == RecentItemType.studentGuide) && (originalItem is Map)) {
      isFavorite = Auth2().isFavorite(StudentGuideFavorite(id: StudentGuide().entryId(originalItem)));
    }
    else {
      isFavorite = false;
    }

    String favLabel = isFavorite ?
      Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') :
      Localization().getStringEx('widget.card.button.favorite.on.title','Add To Favorites');
    String favHint = isFavorite ?
      Localization().getStringEx('widget.card.button.favorite.off.hint', '') :
      Localization().getStringEx('widget.card.button.favorite.on.hint','');
    String favIcon = isFavorite ? 'images/icon-star-selected.png' : 'images/icon-star.png';

    return Padding(padding: EdgeInsets.only(bottom: 8), child:
      Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(4))), clipBehavior: Clip.none, child:
        Stack(children: [
          GestureDetector(behavior: HitTestBehavior.translucent, onTap: widget.onTap, child:
            Padding(padding: EdgeInsets.all(16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Expanded(child:
                    Padding(padding: EdgeInsets.only(right: 24), child:
                      Text(widget.item.recentTitle ?? '', style: TextStyle(fontSize: 18, fontFamily: Styles().fontFamilies.extraBold, color: Styles().colors.fillColorPrimary,),)
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
    ),);
  }

  List<Widget> _buildDetails() {
    List<Widget> details =  [];
    if(AppString.isStringNotEmpty(widget.item.recentTime)) {
      Widget dateDetail = widget.showDate ? _dateDetail() : null;
      if (dateDetail != null) {
        details.add(dateDetail);
      }
      Widget timeDetail = _timeDetail();
      if (timeDetail != null) {
        if (details.isNotEmpty) {
          details.add(Container(height: 8,));
        }
      }
      details.add(timeDetail);
    }
    Widget descriptionDetail = ((widget.item.recentItemType == RecentItemType.studentGuide) && AppString.isStringNotEmpty(widget.item.recentDescripton)) ? _descriptionDetail() : null;
    if (descriptionDetail != null) {
      if (details.isNotEmpty) {
        details.add(Container(height: 8,));
      }
      details.add(descriptionDetail);
    }
    return details;
  }

  //Not used any more
  Widget _dateDetail(){
    String displayTime = widget.item.recentTime;
    if ((displayTime != null) && displayTime.isNotEmpty) {
      String displayDate = Localization().getStringEx('widget.home_recent_item_card.label.date', 'Date');
      return Semantics(label: displayDate, excludeSemantics: true, child:
        Row(children: <Widget>[
          Image.asset('images/icon-calendar.png'),
          Padding(padding: EdgeInsets.only(right: 5),),
          Text(displayDate, style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 12, color: Styles().colors.textBackground)),
        ],),
      );
    } else {
      return null;
    }
  }

  Widget _timeDetail() {
    String displayTime = widget.item.recentTime;
    if ((displayTime != null) && displayTime.isNotEmpty) {
      return Semantics(label: displayTime, excludeSemantics: true, child:
        Row(children: <Widget>[
            Image.asset('images/icon-calendar.png'),
            Padding(padding: EdgeInsets.only(right: 5),),
            Text(displayTime, style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 12, color: Styles().colors.textBackground)),
        ],),
      );
    } else {
      return null;
    }
  }

  Widget _descriptionDetail() {
    return Semantics(label: widget.item.recentDescripton ?? '', excludeSemantics: true, child:
      Text(widget.item.recentDescripton ?? '', style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 14, color: Styles().colors.textBackground)),
    );
  }

  Widget _topBorder() {
    Object originalItem = widget.item.fromOriginalJson();
    Color borderColor = Styles().colors.fillColorPrimary;
    if (originalItem is Explore) {
      borderColor = originalItem.uiColor;
    }
    else if (widget.item.recentItemType == RecentItemType.studentGuide) {
      borderColor = Styles().colors.accentColor3;
    }
    else {
      borderColor = Styles().colors.fillColorPrimary;
    }
    return Container(height: 7, color: borderColor);
  }

  void _onTapFavorite() {
    Analytics.instance.logSelect(target: "Favorite: ${widget?.item?.recentTitle}");
    Object originalItem = widget.item.fromOriginalJson();
    if (originalItem is Favorite) {
      Auth2().prefs?.toggleFavorite(originalItem);
    }
    else if ((widget.item.recentItemType == RecentItemType.studentGuide) && (originalItem is Map)) {
      Auth2().prefs?.toggleFavorite(StudentGuideFavorite(
        id: StudentGuide().entryId(originalItem),
        title: StudentGuide().entryTitle(originalItem)
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

