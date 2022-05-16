
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
import 'package:illinois/ui/settings/SettingsHomePanel.dart';
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
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class FavoritesPanel extends StatefulWidget {

  FavoritesPanel();

  @override
  _FavoritesPanelState createState() => _FavoritesPanelState();
}

class _FavoritesPanelState extends State<FavoritesPanel> with AutomaticKeepAliveClientMixin<FavoritesPanel> implements NotificationsListener {
  
  Map<String, List<Favorite>?> _favorites = <String, List<Favorite>>{};
  bool _loadingFavorites = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      Guide.notifyChanged,
    ]);

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
    if (name == Connectivity.notifyStatusChanged) {
      _refreshFavorites();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _refreshFavorites(showProgress: false);
    }
    else if (name == Guide.notifyChanged) {
      //TBD: refresh only guide items!
    }
  }

  // AutomaticKeepAliveClientMixin
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Styles().colors!.fillColorPrimaryVariant,
        leading: _buildHeaderHomeButton(),
        title: _buildHeaderTitle(),
        actions: [_buildHeaderActions()],
      ),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child:
        Column(children: <Widget>[
          Expanded(child:
            _buildContent(),
          ),
        ]),
        
      ),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: null,
    );
  }

  // Widgets

  Widget _buildContent() {
    if (Connectivity().isOffline) {
      return _buildOffline();
    }
    else if (_loadingFavorites) {
      return _buildProgress();
    }
    else if (_isFavoritesEmpty) {
      return _buildEmpty();
    }
    else {
      return _buildFavoritesContent();
    }
  }

  Widget _buildProgress() {
    return Align(alignment: Alignment.center, child:
      CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), )
    );
  }

  Widget _buildOffline() {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), child:
      Column(children: <Widget>[
        Expanded(child: Container(), flex: 1),
        Text(Localization().getStringEx("app.offline.message.title", "You appear to be offline"), style: TextStyle(fontSize: 16),),
        Container(height:8),
        Text(Localization().getStringEx("panel.favorites.message.offline", "Favorite Items are not available while offline")),
        Expanded(child: Container(), flex: 3),
    ],),);
  }

  Widget _buildEmpty() {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), child:
      Column(children: <Widget>[
        Expanded(child: Container(), flex: 1),
        Text(Localization().getStringEx("panel.favorites.message.empty", "Whoops! Nothing to see here."), style: TextStyle(fontSize: 16),),
        Container(height:8),
        Text(Localization().getStringEx("panel.favorites.message.empty.description", "Tap the \u2606 on events, dining locations, and reminders that interest you to quickly find them here.")),
        Expanded(child: Container(), flex: 3),
    ],),);
  }

  Widget _buildFavoritesContent() {
    return SingleChildScrollView(child:
      Column(children: [
        _FavoritesList(headingTitle: Localization().getStringEx('panel.favorites.label.events', 'Events'),
          headingIconResource: 'images/icon-calendar.png',
          favorites: _favorites[Event.favoriteKeyName]),
        _FavoritesList(headingTitle: Localization().getStringEx('panel.favorites.label.dining', "Dining"),
          headingIconResource: 'images/icon-dining-orange.png',
          favorites: _favorites[Dining.favoriteKeyName],),
        _FavoritesList(headingTitle: Localization().getStringEx('panel.favorites.label.athletics', 'Athletics'),
          headingIconResource: 'images/icon-calendar.png',
          favorites: _favorites[Game.favoriteKeyName]),
        _FavoritesList(
          headingTitle: Localization().getStringEx('panel.favorites.label.news', 'News'),
          headingIconResource: 'images/icon-news.png',
          favorites: _favorites[News.favoriteKeyName],),
        _FavoritesList(
          headingTitle: Localization().getStringEx('panel.favorites.label.laundry', 'Laundry'),
          headingIconResource: 'images/icon-news.png',
          favorites: _favorites[LaundryRoom.favoriteKeyName],),
        _FavoritesList(
          headingTitle: Localization().getStringEx('panel.favorites.label.campus_guide', 'Campus Guide'),
          headingIconResource: 'images/icon-news.png',
          favorites: _favorites[GuideFavorite.favoriteKeyName],),
        _FavoritesList(
          headingTitle: Localization().getStringEx('panel.favorites.label.inbox', 'Inbox'),
          headingIconResource: 'images/icon-news.png',
          favorites: _favorites[InboxMessage.favoriteKeyName],),
      ],)
    );
  }

  Widget _buildHeaderHomeButton() {
    return Semantics(label: Localization().getStringEx('headerbar.home.title', 'Home'), hint: Localization().getStringEx('headerbar.home.hint', ''), button: true, excludeSemantics: true, child:
      IconButton(icon: Image.asset('images/block-i-orange.png', excludeFromSemantics: true), onPressed: _onTapHome,),);
  }

  Widget _buildHeaderTitle() {
    return Semantics(label: Localization().getStringEx('panel.favorites.header.title', 'ILLINOIS'), excludeSemantics: true, child:
      Text(Localization().getStringEx('panel.favorites.header.title', 'ILLINOIS'), style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),),);
  }

  Widget _buildHeaderSettingsButton() {
    return Semantics(label: Localization().getStringEx('headerbar.settings.title', 'Settings'), hint: Localization().getStringEx('headerbar.settings.hint', ''), button: true, excludeSemantics: true, child:
      IconButton(icon: Image.asset('images/settings-white.png', excludeFromSemantics: true), onPressed: _onTapSettings));
  }

  Widget _buildHeaderActions() {
    List<Widget> actions = <Widget>[ _buildHeaderSettingsButton() ];
    return Row(mainAxisSize: MainAxisSize.min, children: actions,);
  }

  // Content

  Future<Map<String, List<Favorite>?>> _loadFavorites() async {

    Map<String, Future<List<Favorite>?> Function(LinkedHashSet<String>?)> favoriteLoaders = <String, Future<List<Favorite>?> Function(LinkedHashSet<String>?)> {
      Event.favoriteKeyName: _loadFavoriteEvents,
      Dining.favoriteKeyName: _loadFavoriteDinings,
      Game.favoriteKeyName: _loadFavoriteGames,
      News.favoriteKeyName: _loadFavoriteNews,
      LaundryRoom.favoriteKeyName: _loadFavoriteLaundries,
      InboxMessage.favoriteKeyName: _loadFavoriteNotifications,
      GuideFavorite.favoriteKeyName: _loadFavoriteGuideItems,
    };
    
    List<String> favoriteCategories = List.from(favoriteLoaders.keys);
    
    List<Future<List<Favorite>?>> futures = <Future<List<Favorite>?>>[];
    for (String favoriteCategory in favoriteCategories) {
      futures.add(favoriteLoaders[favoriteCategory]!(Auth2().prefs?.getFavorites(favoriteCategory)));
    }

    List<List<Favorite>?> results = await Future.wait(futures);
    
    Map<String, List<Favorite>?> result = <String, List<Favorite>?>{};
    for (int index = 0; index < favoriteCategories.length; index++) {
      if (index < results.length) {
        result[favoriteCategories[index]] = results[index];
      }
    }
    return result;
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
    if (Connectivity().isNotOffline && (favoriteIds != null) && (Guide().contentList != null)) {
      
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

  bool get _isFavoritesEmpty {
    int favoritesCount = 0;
    _favorites.forEach((_, List<Favorite>? list ) {
      favoritesCount += (list != null) ? list.length : 0;
    });
    return (favoritesCount == 0);
  }

  // Handlers

  Future<void>_onPullToRefresh() async {
    Map<String, List<Favorite>?> favorites = await _loadFavorites();
    if (mounted) {
      setState(() {
        _favorites = favorites;
      });
    }
  }

  void _refreshFavorites({bool showProgress = true}) {
    if (Connectivity().isOnline) {
      if (showProgress && mounted) {
        setState(() {
          _loadingFavorites = true;
        });
      }
      _loadFavorites().then((Map<String, List<Favorite>?> favorites) {
        if (mounted) {
          setState(() {
            _favorites = favorites;
            _loadingFavorites = false;
          });
        }
      }); 
    }
  }

  void _onTapSettings() {
    Analytics().logSelect(target: "Settings");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsHomePanel()));
  }

  void _onTapHome() {
    Analytics().logSelect(target: "Home");
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _FavoritesList extends StatefulWidget {
  final List<Favorite>? favorites;
  final int limit;
  final String? headingTitle;
  final String? headingIconResource;
  final String slantImageRes;
  final Color? slantColor;

  _FavoritesList({this.favorites, this.limit = 3, this.headingTitle, this.headingIconResource, this.slantImageRes = 'images/slant-down-right-blue.png', this.slantColor,});

  _FavoritesListState createState() => _FavoritesListState();
}

class _FavoritesListState extends State<_FavoritesList>{

  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    if (CollectionUtils.isNotEmpty(widget.favorites)) {
      bool showMoreButton = widget.limit < widget.favorites!.length;
      return Column(
        children: <Widget>[
          SectionSlantHeader(
              title: widget.headingTitle,
              titleIconAsset: widget.headingIconResource,
              slantImageAsset: widget.slantImageRes,
              slantColor: widget.slantColor ?? Styles().colors!.fillColorPrimary,
              children: _buildListItems(context)),
          Visibility(visible: showMoreButton, child: Padding(padding: EdgeInsets.only(top: 8, bottom: 40), child: SmallRoundedButton(
            label: _showAll ? Localization().getStringEx('panel.favorites.button.less', "Show Less") : Localization().getStringEx('panel.favorites.button.all', "Show All"),
            onTap: _onViewAllTapped,
          ),),)
        ],
      );
    }
    else {
      return Container();
    }
  }

  List<Widget> _buildListItems(BuildContext context) {
    List<Widget> widgets = [];
    if (CollectionUtils.isNotEmpty(widget.favorites)) {
      int itemsCount = widget.favorites!.length;
      int visibleCount = (_showAll ? itemsCount : min(widget.limit, itemsCount));
      for (int i = 0; i < visibleCount; i++) {
        Favorite? item = widget.favorites![i];
        widgets.add(_buildItemCard(item));
        if (i < (visibleCount - 1)) {
          widgets.add(Container(height: 12,));
        }
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

  void _onTapItem(Favorite? item) {
    Analytics().logSelect(target: item?.favoriteTitle);
    item?.favoriteLaunchDetail(context);
  }

  void _onViewAllTapped() {
    setState(() {
      _showAll = !_showAll;
    });
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
}
