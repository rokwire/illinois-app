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

import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Favorite.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/News.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:illinois/service/Sports.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/model/Dining.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreDetailPanel.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:notification_permissions/notification_permissions.dart';

class SavedPanel extends StatefulWidget {

  SavedPanel();

  @override
  _SavedPanelState createState() => _SavedPanelState();
}

class _SavedPanelState extends State<SavedPanel> implements NotificationsListener {

  Map<String, List<Favorite>?> _favorites = <String, List<Favorite>>{};
  bool _loadingFavorites = false;
  bool _showNotificationPermissionPrompt = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      Auth2.notifyLoginChanged,
      Assets.notifyChanged,
      Guide.notifyChanged,
    ]);
    _refreshFavorites();
    _requestPermissionsStatus();
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
    else if (name == Auth2.notifyLoginChanged) {
      _refreshFavorites(showProgress: false);
    }
    else if (name == Assets.notifyChanged) {
      _refreshFavorites(showProgress: false);
    }
    else if (name == Guide.notifyChanged) {
      //TBD: refresh only guide items!
      _refreshFavorites(showProgress: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.saved.header.label', 'Saved'),
      ),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child:
        Column(children: <Widget>[
          _buildNotificationPermision(),
          Expanded(child:
            _buildContent(),
          ),
        ]),
        
      ),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: uiuc.TabBar(),
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
        Text(Localization().getStringEx("app.offline.message.title", "You appear to be offline"), style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 20, color: Styles().colors?.fillColorPrimary),),
        Container(height:8),
        Text(Localization().getStringEx("panel.saved.message.offline", "Saved Items are not available while offline"), style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground),),
        Expanded(child: Container(), flex: 3),
    ],),);
  }

  Widget _buildEmpty() {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), child:
      Column(children: <Widget>[
        Expanded(child: Container(), flex: 1),
        Text(Localization().getStringEx("panel.saved.message.no_items", "Whoops! Nothing to see here."), style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 20, color: Styles().colors?.fillColorPrimary),),
        Container(height:8),
        Text(Localization().getStringEx("panel.saved.message.no_items.description", "Tap the \u2606 on events, dining locations, and reminders that interest you to quickly find them here."), style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground),),
        Expanded(child: Container(), flex: 3),
    ],),);
  }

  Widget _buildFavoritesContent() {
    return SingleChildScrollView(child:
      Column(children: [
        _SavedItemsList(headingTitle: Localization().getStringEx('panel.favorites.label.events', 'Events'),
          headingIconResource: 'images/icon-calendar.png',
          items: _favorites[Event.favoriteKeyName]),
        _SavedItemsList(headingTitle: Localization().getStringEx('panel.favorites.label.dining', "Dining"),
          headingIconResource: 'images/icon-dining-orange.png',
          items: _favorites[Dining.favoriteKeyName],),
        _SavedItemsList(headingTitle: Localization().getStringEx('panel.favorites.label.athletics', 'Athletics'),
          headingIconResource: 'images/icon-calendar.png',
          items: _favorites[Game.favoriteKeyName]),
        _SavedItemsList(
          headingTitle: Localization().getStringEx('panel.favorites.label.news', 'News'),
          headingIconResource: 'images/icon-news.png',
          items: _favorites[News.favoriteKeyName],),
        _SavedItemsList(
          headingTitle: Localization().getStringEx('panel.favorites.label.laundry', 'Laundry'),
          headingIconResource: 'images/icon-news.png',
          items: _favorites[LaundryRoom.favoriteKeyName],),
        _SavedItemsList(
          headingTitle: Localization().getStringEx('panel.favorites.label.campus_guide', 'Campus Guide'),
          headingIconResource: 'images/icon-news.png',
          items: _favorites[GuideFavorite.favoriteKeyName],),
        _SavedItemsList(
          headingTitle: Localization().getStringEx('panel.favorites.label.inbox', 'Inbox'),
          headingIconResource: 'images/icon-news.png',
          items: _favorites[InboxMessage.favoriteKeyName],),
      ],)
    );
  }

  Widget _buildNotificationPermision() {
    return (_showNotificationPermissionPrompt) ? Padding(padding: const EdgeInsets.all(0), child:
      Container(color: Styles().colors?.fillColorPrimary, child:
        Column(children: <Widget>[
          Row(children: <Widget>[
            Expanded(child:
              Padding(padding: EdgeInsets.all(16), child:
                Text(Localization().getStringEx("panel.saved.notifications.label", "Don’t miss an event! Get reminders of upcoming events."), style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.white),)
              ),
            ),
            InkWell(onTap: _onAuthorizeSkip, child: 
              Padding(padding: EdgeInsets.only(right: 16), child:
                Image.asset('images/close-white.png', excludeFromSemantics: true))
              )
          ],),
          Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
            ToggleRibbonButton(label: Localization().getStringEx("panel.saved.notifications.enable.label", "Enable notifications"), toggled: false, borderRadius: BorderRadius.all(Radius.circular(4)), onTap: _onAuthorize,),
          ),
        ]
      )),
    ) : Container();
  }

  Widget _buildNotificationPermissionPrompt(BuildContext context, PermissionStatus permissionStatus) {
    String? message;
    if (permissionStatus == PermissionStatus.granted) {
      message = Localization().getStringEx('panel.onboarding.notifications.label.access_granted', 'You already have granted access to this app.');
    }
    else if (permissionStatus == PermissionStatus.denied) {
      message = Localization().getStringEx('panel.onboarding.notifications.label.access_denied', 'You already have denied access to this app.');
    }
    return Dialog(child:
      Padding(padding: EdgeInsets.all(18), child:
        Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Text(Localization().getStringEx('app.title', 'Illinois'), style: TextStyle(fontSize: 24, color: Colors.black), ),
            Padding(padding: EdgeInsets.symmetric(vertical: 26), child:
              Text(message ?? '', textAlign: TextAlign.left, style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Colors.black),),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                TextButton(onPressed: _onAuthorizeOK, child:
                  Text(Localization().getStringEx('dialog.ok.title', 'OK')))
              ],
            )
          ],
        ),
      ),
    );
  }

  // Content

  Future<Map<String, List<Favorite>?>> _loadFavorites() async {

    Map<String, Future<List<Favorite>?> Function(LinkedHashSet<String>?)> favoriteLoaders = <String, Future<List<Favorite>?> Function(LinkedHashSet<String>?)> {
      Event.favoriteKeyName: _loadFavoriteEvents,
      Dining.favoriteKeyName: _loadFavoriteDinings,
      Game.favoriteKeyName: _loadFavoriteGames,
      News.favoriteKeyName: _loadFavoriteNews,
      LaundryRoom.favoriteKeyName: _laundryAvailable ? _loadFavoriteLaundries : _loadNOP,
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

  Future<List<Favorite>?> _loadNOP(LinkedHashSet<String>? favoriteIds) async => null;

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

  bool get _isFavoritesEmpty {
    int favoritesCount = 0;
    _favorites.forEach((_, List<Favorite>? list ) {
      favoritesCount += (list != null) ? list.length : 0;
    });
    return (favoritesCount == 0);
  }

  void _requestPermissionsStatus(){
    if (Platform.isIOS && Auth2().privacyMatch(4)) {

      NotificationPermissions.getNotificationPermissionStatus().then((PermissionStatus status) {
        if ((status == PermissionStatus.unknown) && mounted) {
          setState(() {
            _showNotificationPermissionPrompt = true;
          });
        }
      });

    }
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

  void _onAuthorizeOK() {
      Analytics().logAlert(text:"Already have access", selection: "Ok");
      Navigator.pop(context);
      setState(() {
        _showNotificationPermissionPrompt = false;
      });
  }


  void _onAuthorize() {
    _requestAuthorization();
  }

  void _onAuthorizeSkip(){
    setState(() {
      _showNotificationPermissionPrompt = false;
    });
  }





  void _requestAuthorization() async {
    PermissionStatus permissionStatus = await NotificationPermissions.getNotificationPermissionStatus();
    if (permissionStatus != PermissionStatus.unknown) {
      showDialog(context: context, builder: (context) => _buildNotificationPermissionPrompt(context, permissionStatus));
    }
    else {
      permissionStatus = await NotificationPermissions.requestNotificationPermissions();
      if (permissionStatus == PermissionStatus.granted) {
        Analytics().updateNotificationServices();
      }
      setState(() {
        _showNotificationPermissionPrompt = false;
      });
    }
  }

  bool get _laundryAvailable => IlliniCash().ballance?.housingResidenceStatus ?? false;

}

class _SavedItemsList extends StatefulWidget {
  final List<Favorite>? items;
  final int limit;
  final String? headingTitle;
  final String? headingIconResource;
  final String slantImageResource;
  final Color? slantColor;

  _SavedItemsList(
      {this.items, this.limit = 3, this.headingTitle, this.headingIconResource, this.slantImageResource = 'images/slant-down-right-blue.png',
        this.slantColor,});

  _SavedItemsListState createState() => _SavedItemsListState();
}

class _SavedItemsListState extends State<_SavedItemsList>{

  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    if (CollectionUtils.isEmpty(widget.items)) {
      return Container();
    }
    bool showMoreButton = widget.limit < widget.items!.length;
    return Column(
      children: <Widget>[
        SectionSlantHeader(
            title: widget.headingTitle,
            titleIconAsset: widget.headingIconResource,
            slantImageAsset: widget.slantImageResource,
            slantColor: widget.slantColor ?? Styles().colors!.fillColorPrimary,
            children: _buildListItems(context)),
        Visibility(visible: showMoreButton, child: Padding(padding: EdgeInsets.only(top: 8, bottom: 40), child: SmallRoundedButton(
          label: _showAll ? Localization().getStringEx('panel.saved.events.button.less', "Show Less") : Localization().getStringEx('panel.saved.events.button.all', "Show All"),
          onTap: _onViewAllTapped,
        ),),)
      ],
    );
  }

  List<Widget> _buildListItems(BuildContext context) {
    List<Widget> widgets = [];
    if (CollectionUtils.isNotEmpty(widget.items)) {
      int itemsCount = widget.items!.length;
      int visibleCount = (_showAll ? itemsCount : min(widget.limit, itemsCount));
      for (int i = 0; i < visibleCount; i++) {
        Favorite? item = widget.items![i];
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
