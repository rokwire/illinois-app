import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Favorite.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:illinois/ui/explore/ExploreDetailPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeFavoritesWidget extends StatefulWidget {

  final String? favoriteId;
  final String favoriteKey;
  final StreamController<void>? refreshController;
  final HomeScrollableDragging? scrollableDragging;

  HomeFavoritesWidget({Key? key, required this.favoriteKey, this.favoriteId, this.refreshController, this.scrollableDragging}) : super(key: key);

  @override
  _HomeFavoritesWidgetState createState() => _HomeFavoritesWidgetState();
}

class _HomeFavoritesWidgetState extends State<HomeFavoritesWidget> implements NotificationsListener {

  List<Favorite>? _favorites;
  bool _loadingFavorites = false;
  bool _showAll = false;
  final int limit = 3;
  
  @override
  void initState() {
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      Guide.notifyChanged,
    ]);
    if (widget.refreshController != null) {
      widget.refreshController!.stream.listen((_) {
        _refreshFavorites();
      });
    }
    _refreshFavorites();
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

  }

  @override
  Widget build(BuildContext context) {
    return HomeDropTargetWidget(favoriteId: widget.favoriteId, child:
      HomeSlantWidget(favoriteId: widget.favoriteId, scrollableDragging: widget.scrollableDragging,
        title: headingTitle,
        child: Column(children: _buildContent()
      ),
    ),);
  }

  List<Widget> _buildContent() {
    if (Connectivity().isOffline) {
      return [_buildOffline()];
    }
    else if (_loadingFavorites) {
      return [_buildProgress()];
    }
    else if ((_favorites == null) || (_favorites!.length == 0)) {
      return [_buildEmpty()];
    }
    else {
      return _buildContentList();
    }
  }

  Widget _buildProgress() {
    return Padding(padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16), child:
      Align(alignment: Alignment.center, child:
        CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary),),
      ),
    );
  }

  Widget _buildOffline() {
    return Padding(padding: EdgeInsets.only(left: 32, right: 32, top: 96, bottom: 16), child:
      Column(children: <Widget>[
        Text(Localization().getStringEx("app.offline.message.title", "You appear to be offline"), style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 20, color: Styles().colors?.fillColorPrimary),),
        Container(height:8),
        Text(Localization().getStringEx("panel.favorites.message.offline", "Favorite Items are not available while offline"), style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground),),
    ],),);
  }

  Widget _buildEmpty() {
    return Padding(padding: EdgeInsets.only(left: 32, right: 32, top: 96, bottom: 16), child:
      Column(children: <Widget>[
        Text(Localization().getStringEx("panel.favorites.message.empty", "Whoops! Nothing to see here."), style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 20, color: Styles().colors?.fillColorPrimary),),
        Container(height:8),
        Text(Localization().getStringEx("panel.favorites.message.empty.description", "Tap the \u2606 on events, dining locations, and reminders that interest you to quickly find them here."), style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground),),
    ],),);
  }

  List<Widget> _buildContentList() {
    List<Widget> widgets = [];
    if (CollectionUtils.isNotEmpty(_favorites)) {
      int itemsCount = _favorites!.length;
      int visibleCount = (_showAll ? itemsCount : min(limit, itemsCount));
      for (int i = 0; i < visibleCount; i++) {
        Favorite? item = _favorites![i];
        widgets.add(_buildItemCard(item));
        if (i < (visibleCount - 1)) {
          widgets.add(Container(height: 12,));
        }
      }

      if (limit < _favorites!.length) {
        widgets.add(
          Padding(padding: EdgeInsets.only(top: 8, bottom: 40), child:
            SmallRoundedButton(label: _showAll ? Localization().getStringEx('panel.favorites.button.less', "Show Less") : Localization().getStringEx('panel.favorites.button.all', "Show All"), onTap: _onViewAllTapped,),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildItemCard(Favorite? item) {
    //Custom layout for super events before release
    if(item is Event && item.isComposite){
      return _buildCompositEventCard(item);
    }

    bool favorite = Auth2().isFavorite(item);
    Color? headerColor = item?.favoriteHeaderColor;
    String? title = item?.favoriteTitle;
    String? cardDetailText = item?.favoriteDetailText;
    Image? cardDetailImage = StringUtils.isNotEmpty(cardDetailText) ? item?.favoriteDetailIcon : null;
    bool detailVisible = StringUtils.isNotEmpty(cardDetailText);
    return GestureDetector(onTap: () => _onTapItem(item), child:
      Semantics(label: title, child:
        Column(children: <Widget>[
          Container(height: 7, color: headerColor,),
          Container(decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4))), child:
            Padding(padding: EdgeInsets.all(16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Flex(direction: Axis.vertical, children: <Widget>[
                    Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                      Expanded(child:
                        Text(title ?? '', semanticsLabel: "", style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20), ),
                      ),
                      Visibility(visible: Auth2().canFavorite, child:
                        GestureDetector(behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Analytics().logSelect(target: "Favorite: $title");
                            Auth2().prefs?.toggleFavorite(item);
                          }, child:
                          Semantics(container: true,
                            label: favorite
                                ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites')
                                : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                            hint: favorite
                                ? Localization().getStringEx('widget.card.button.favorite.off.hint', '')
                                : Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
                            button: true,
                            excludeSemantics: true,
                            child:
                              Container(padding: EdgeInsets.only(left: 24, bottom: 24), child: Image.asset(favorite ? 'images/icon-star-selected.png' : 'images/icon-star.png', excludeFromSemantics: true)))),
                          )
                        ],
                      )
                    ],
                  ),
                  Visibility(visible: detailVisible, child:
                    Semantics(label: cardDetailText, excludeSemantics: true, child:
                      Padding(padding: EdgeInsets.only(top: 12), child:
                        (cardDetailImage != null) ? 
                        Row(children: <Widget>[
                          Padding(padding: EdgeInsets.only(right: 10), child: cardDetailImage,),
                          Expanded(child:
                            Text(cardDetailText ?? '', semanticsLabel: "", style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Styles().colors!.textBackground)),
                          )
                        ],) :
                        Text(cardDetailText ?? '', semanticsLabel: "", style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Styles().colors!.textBackground)),
                  )),)
                ]),
              ),
            )
          ],
        )),);
  }

  Widget _buildCompositEventCard(Event? item){
      return ExploreCard(explore: item,showTopBorder: true, horizontalPadding: 0,border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        onTap:(){
          if (item != null) {
            if (item.isComposite) {
              Navigator.push(context, CupertinoPageRoute(builder: (context) => CompositeEventsDetailPanel(parentEvent: item)));
            } else {
              Navigator.push(context, CupertinoPageRoute(builder: (context) =>
                  ExploreDetailPanel(explore: item)));
            }
          }
        });
  }

  void _refreshFavorites({bool showProgress = true}) {
    if (Connectivity().isOnline) {
      if (showProgress && mounted) {
        setState(() {
          _loadingFavorites = true;
        });
      }
      _loadFavorites().then((List<Favorite>? favorites) {
        if (mounted) {
          setState(() {
            _favorites = favorites;
            _loadingFavorites = false;
          });
        }
      }); 
    }
  }

  Future<List<Favorite>?> _loadFavorites() async {
    LinkedHashSet<String>? favoriteIds = Auth2().prefs?.getFavorites(widget.favoriteKey);
    if (CollectionUtils.isNotEmpty(favoriteIds)) {
      switch(widget.favoriteKey) {
        case Event.favoriteKeyName: return _loadFavoriteEvents(favoriteIds);
        case Dining.favoriteKeyName: return _loadFavoriteDinings(favoriteIds);
        case Game.favoriteKeyName: return _loadFavoriteGames(favoriteIds);
        case News.favoriteKeyName: return _loadFavoriteNews(favoriteIds);
        case LaundryRoom.favoriteKeyName: return _loadFavoriteLaundries(favoriteIds);
        case InboxMessage.favoriteKeyName: return _loadFavoriteNotifications(favoriteIds);
        case GuideFavorite.favoriteKeyName: return _loadFavoriteGuideItems(favoriteIds);
      }
    }
    return null;
  }

  Future<List<Favorite>?> _loadFavoriteEvents(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList(await Events().loadEventsByIds(favoriteIds), favoriteIds) : null;

  Future<List<Favorite>?> _loadFavoriteDinings(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList(await Dinings().loadBackendDinings(false, null, null), favoriteIds) : null;

  Future<List<Favorite>?> _loadFavoriteGames(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList(await Sports().loadGames(), favoriteIds) : null;

  Future<List<Favorite>?> _loadFavoriteNews(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList(await Sports().loadNews(null, 0), favoriteIds) : null;

  Future<List<Favorite>?> _loadFavoriteLaundries(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList((await Laundries().loadSchoolRooms())?.rooms, favoriteIds) : null;

  Future<List<Favorite>?> _loadFavoriteNotifications(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList(await Inbox().loadMessages(messageIds: favoriteIds), favoriteIds) : null;

  Future<List<Favorite>?> _loadFavoriteGuideItems(LinkedHashSet<String>? favoriteIds) async {
    List<Favorite>? guideItems;
    if ((favoriteIds != null) && (Guide().contentList != null)) {
      
      Map<String, Favorite> favorites = <String, Favorite>{};
      for (dynamic contentEntry in Guide().contentList!) {
        String? guideEntryId = Guide().entryId(JsonUtils.mapValue(contentEntry));
        
        if ((guideEntryId != null) && favoriteIds.contains(guideEntryId)) {
          favorites[guideEntryId] = GuideFavorite(id: guideEntryId);
        }
      }

      if (favorites.isNotEmpty) {
        List<Favorite> result = <Favorite>[];
        for (String favoriteId in favoriteIds) {
          Favorite? favorite = favorites[favoriteId];
          if (favorite != null) {
            result.add(favorite);
          }
        }
        guideItems = List.from(result.reversed);
      }
    }
    return guideItems;
  }

  List<Favorite>? _buildFavoritesList(List<Favorite>? sourceList, LinkedHashSet<String>? favoriteIds) {
    if ((sourceList != null) && (favoriteIds != null)) {
      Map<String, Favorite> favorites = <String, Favorite>{};
      if (sourceList.isNotEmpty && favoriteIds.isNotEmpty) {
        for (Favorite sourceItem in sourceList) {
          if ((sourceItem.favoriteId != null) && favoriteIds.contains(sourceItem.favoriteId)) {
            favorites[sourceItem.favoriteId!] = sourceItem;
          }
        }
      }

      List<Favorite>? result = <Favorite>[];
      if (favorites.isNotEmpty) {
        for (String favoriteId in favoriteIds) {
          Favorite? favorite = favorites[favoriteId];
          if (favorite != null) {
            result.add(favorite);
          }
        }
      }
      
      // show last added at top
      return List.from(result.reversed);
    }
    return null;
  }

  String? get headingTitle {
    switch(widget.favoriteKey) {
      case Event.favoriteKeyName: return Localization().getStringEx('panel.favorites.label.events', 'Events');
      case Dining.favoriteKeyName: return Localization().getStringEx('panel.favorites.label.dining', "Dining");
      case Game.favoriteKeyName: return Localization().getStringEx('panel.favorites.label.athletics', 'Athletics');
      case News.favoriteKeyName: return Localization().getStringEx('panel.favorites.label.news', 'News');
      case LaundryRoom.favoriteKeyName: return Localization().getStringEx('panel.favorites.label.laundry', 'Laundry');
      case InboxMessage.favoriteKeyName: return Localization().getStringEx('panel.favorites.label.campus_guide', 'Campus Guide');
      case GuideFavorite.favoriteKeyName: return Localization().getStringEx('panel.favorites.label.inbox', 'Inbox');
    }
    return null;
  }

  void _onTapItem(Favorite? item) {
    Analytics().logSelect(target: item?.favoriteTitle);
    item?.favoriteLaunchDetail(context);
  }

  void _onViewAllTapped() {
    setState(() {
      _showAll = !_showAll;
    });
  }
}