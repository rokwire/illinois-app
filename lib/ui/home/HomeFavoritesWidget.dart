import 'dart:async';
import 'dart:collection';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Favorite.dart';
import 'package:illinois/main.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/ui/SavedPanel.dart';
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:illinois/ui/explore/ExploreDetailPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
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
  final StreamController<String>? updateController;

  HomeFavoritesWidget({Key? key, required this.favoriteKey, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({required String favoriteKey, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: titleFromKey(favoriteKey: favoriteKey),
    );
  
  static String? titleFromKey({required String favoriteKey}) {
    switch(favoriteKey) {
      case Event.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.title.events', 'My Events');
      case Dining.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.title.dining', 'My Dinings');
      case Game.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.title.athletics', 'My Athletics');
      case News.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.title.news', 'My News');
      case LaundryRoom.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.title.laundry', 'My Laundry');
      case InboxMessage.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.title.inbox', 'My Notifications');
      case GuideFavorite.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.title.campus_guide', 'My Campus Guide');
    }
    return null;
  }

  @override
  _HomeFavoritesWidgetState createState() => _HomeFavoritesWidgetState();

}

class _HomeFavoritesWidgetState extends State<HomeFavoritesWidget> implements NotificationsListener {

  List<Favorite>? _favorites;
  PageController? _pageController;
  bool _loadingFavorites = false;
  final double _pageSpacing = 16;
  
  @override
  void initState() {
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      Auth2.notifyLoginChanged,
      Guide.notifyChanged,
      Config.notifyConfigChanged,
    ]);
    
    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _refreshFavorites();
        }
      });
    }

    double screenWidth = MediaQuery.of(App.instance?.currentContext ?? context).size.width;
    double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
    _pageController = PageController(viewportFraction: pageViewport);

    _refreshFavorites();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _pageController?.dispose();
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if ((name == Config.notifyConfigChanged) ||
        (name == Connectivity.notifyStatusChanged) ||
        (name == Auth2.notifyLoginChanged)) {
      if (mounted) {
        setState(() {});
      }
    }
    else if ((name == Auth2UserPrefs.notifyFavoritesChanged) ||
            (name == Guide.notifyChanged)) {
      _refreshFavorites(showProgress: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: headingTitle,
      titleIcon: headingIcon,
      childPadding: EdgeInsets.zero,
      child: _buildContent()
    );
  }

  Widget _buildContent() {
    if (Connectivity().isOffline) {
      return HomeMessageCard(title: Localization().getStringEx("app.offline.message.title", "You appear to be offline"), message: _offlineMessage,);
    }
    else if ((widget.favoriteKey == InboxMessage.favoriteKeyName) && !Auth2().isOidcLoggedIn) {
      return HomeMessageCard(title: Localization().getStringEx("app.logged_out.message.title", "You are not logged in"), message: _loggedOutMessage,);
    }
    else if (_loadingFavorites) {
      return HomeProgressWidget();
    }
    else if ((_favorites == null) || (_favorites!.length == 0)) {
      return HomeMessageCard(message: _emptyMessage);
    }
    else {
      return _buildFavorites();
    }
  }

  Widget _buildFavorites() {
    Widget contentWidget;
    int visibleCount = _favorites?.length ?? 0; // min(Config().homeFavoriteItemsCount, ...)
    if (1 < visibleCount) {

      double pageHeight = (20 + 16) * MediaQuery.of(context).textScaleFactor + 7 + 2 * 16 + 12;

      List<Widget> pages = [];
      for (int i = 0; i < visibleCount; i++) {
        pages.add(Padding(padding: EdgeInsets.only(right: _pageSpacing), child:
          _buildItemCard(_favorites![i])),
        );
      }

      contentWidget = Container(constraints: BoxConstraints(minHeight: pageHeight), child:
        ExpandablePageView(controller: _pageController, children: pages, estimatedPageSize: pageHeight),
      );
    }
    else {
      contentWidget = Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        _buildItemCard(_favorites!.first),
      );
    }


    return Column(children: <Widget>[
      Padding(padding: EdgeInsets.only(top: 8), child:
        contentWidget,
      ),
      LinkButton(
        title: Localization().getStringEx('panel.saved.button.all.title', 'View All'),
        hint: _viewAllHint,
        onTap: _onSeeAll,
      )      
    ]);
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
                              Container(padding: EdgeInsets.only(left: 24, bottom: 24), child: Image.asset(favorite ? 'images/icon-star-blue.png' : 'images/icon-star-gray-frame-thin.png', excludeFromSemantics: true)))),
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

  String? get headingTitle => HomeFavoritesWidget.titleFromKey(favoriteKey: widget.favoriteKey);


  Image? get headingIcon {
    switch(widget.favoriteKey) {
      case Event.favoriteKeyName: return Image.asset('images/icon-calendar.png', excludeFromSemantics: true,);
      case Dining.favoriteKeyName: return Image.asset('images/icon-dining-orange.png', excludeFromSemantics: true,);
      case Game.favoriteKeyName: return Image.asset('images/icon-calendar.png', excludeFromSemantics: true,);
      case News.favoriteKeyName: return Image.asset('images/icon-news.png', excludeFromSemantics: true,);
      case LaundryRoom.favoriteKeyName: return Image.asset('images/icon-news.png', excludeFromSemantics: true,);
      case InboxMessage.favoriteKeyName: return Image.asset('images/icon-news.png', excludeFromSemantics: true,);
      case GuideFavorite.favoriteKeyName: return Image.asset('images/icon-news.png', excludeFromSemantics: true,);
    }
    return null;
  }

  String? get _offlineMessage {
    switch(widget.favoriteKey) {
      case Event.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.offline.events', 'My Events are not available while offline.');
      case Dining.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.offline.dining', 'My Dinings are not available while offline.');
      case Game.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.offline.athletics', 'My Athletics are not available while offline.');
      case News.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.offline.news', 'My News are not available while offline.');
      case LaundryRoom.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.offline.laundry', 'My Laundry are not available while offline.');
      case InboxMessage.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.offline.inbox', 'My Notifications are not available while offline.');
      case GuideFavorite.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.offline.campus_guide', 'My Campus Guide are not available while offline.');
    }
    return null;
  }

  String? get _loggedOutMessage {
    switch(widget.favoriteKey) {
      case InboxMessage.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.logged_out.inbox', 'You need to be logged in to access My Notifications.');
    }
    return null;
  }

  String? get _emptyMessage {
    switch(widget.favoriteKey) {
      case Event.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.empty.events', 'Tap the \u2606 on on items in Events so you can quickly find them here.');
      case Dining.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.empty.dining', 'Tap the \u2606 on on items in Dinings so you can quickly find them here.');
      case Game.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.empty.athletics', 'Tap the \u2606 on on items in Athletics Events so you can quickly find them here.');
      case News.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.empty.news', 'Tap the \u2606 on on items in Athletics News so you can quickly find them here.');
      case LaundryRoom.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.empty.laundry', 'Tap the \u2606 on on items in Laundry so you can quickly find them here.');
      case InboxMessage.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.empty.inbox', 'Tap the \u2606 on on items in Notifications so you can quickly find them here.');
      case GuideFavorite.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.empty.campus_guide', 'Tap the \u2606 on on items in Campus Guide so you can quickly find them here.');
    }
    return null;
  }

  String? get _viewAllHint {
    switch(widget.favoriteKey) {
      case Event.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.all.hint.events', 'Tap to view all favorite events');
      case Dining.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.all.hint.dining', 'Tap to view all favorite dinings');
      case Game.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.all.hint.athletics', 'Tap to view all favorite athletics events');
      case News.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.all.hint.news', 'Tap to view all favorite athletics news');
      case LaundryRoom.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.all.hint.laundry', 'Tap to view all favorite laundries');
      case InboxMessage.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.all.hint.inbox', 'Tap to view all favorite notifications');
      case GuideFavorite.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.all.hint.campus_guide', 'Tap to view all favorite campus guide articles');
    }
    return null;
  }

  void _onTapItem(Favorite? item) {
    Analytics().logSelect(target: item?.favoriteTitle);
    item?.favoriteLaunchDetail(context);
  }

  void _onSeeAll() {
    Analytics().logSelect(target: 'HomeFavoritesWidget(${widget.favoriteKey}) View All');
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return SavedPanel(favoriteCategories: [widget.favoriteKey]); } ));
  }
}