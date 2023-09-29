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
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/ext/Favorite.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/model/Appointment.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/ui/home/HomeFavoritesWidget.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:illinois/service/Sports.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/model/Dining.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreDetailPanel.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class SavedPanel extends StatefulWidget {

  static const List<String> allFavoriteCategories = <String>[
    Event.favoriteKeyName,
    Event2.favoriteKeyName,
    Dining.favoriteKeyName,
    Game.favoriteKeyName,
    News.favoriteKeyName,
    LaundryRoom.favoriteKeyName,
    MTDStop.favoriteKeyName,
    ExplorePOI.favoriteKeyName,
    GuideFavorite.favoriteKeyName,
  ];

  final List<String> favoriteCategories;

  SavedPanel({this.favoriteCategories = allFavoriteCategories});

  @override
  _SavedPanelState createState() => _SavedPanelState();
}

class _SavedPanelState extends State<SavedPanel> implements NotificationsListener {

  Map<String, List<Favorite>?> _favorites = <String, List<Favorite>>{};
  bool _loadingFavorites = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      Auth2.notifyLoginChanged,
      Guide.notifyChanged,
      Appointments.notifyUpcomingAppointmentsChanged,
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
    else if (name == Auth2.notifyLoginChanged) {
      _refreshFavorites(showProgress: false);
    }
    else if (name == Guide.notifyChanged) {
      _refreshFavorites(favoriteCategories: {GuideFavorite.favoriteKeyName}, showProgress: false);
    }
    else if (name == Appointments.notifyUpcomingAppointmentsChanged) {
      _refreshFavorites(favoriteCategories: {Appointment.favoriteKeyName}, showProgress: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: _headerBarTitle,),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child:
        Column(children: <Widget>[
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
        Text(Localization().getStringEx("common.message.offline", "You appear to be offline"), style: Styles().textStyles?.getTextStyle("widget.message.large.fat"),),
        Container(height:8),
        Text(Localization().getStringEx("panel.saved.message.offline", "Saved Items are not available while offline"), style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"),),
        Expanded(child: Container(), flex: 3),
    ],),);
  }

  Widget _buildEmpty() {
    String? favoriteCategory = (widget.favoriteCategories.length == 1) ? widget.favoriteCategories.single : null;
    return Padding(padding: EdgeInsets.symmetric(horizontal: 48, vertical: 32), child:
      Column(children: <Widget>[
        Expanded(child: Container(), flex: 1),
        (favoriteCategory != null) ?
            HtmlWidget(
                "<div style=text-align:center> ${HomeFavoritesWidget.emptyMessageHtml(favoriteCategory)} </div>",
                onTapUrl : (url) {HomeFavoritesWidget.handleLocalUrl(url, context: context, analyticsTarget: 'View Home', analyticsSource: 'SavedPanel($favoriteCategory)'); return true;},
                textStyle: Styles().textStyles?.getTextStyle("widget.message.medium.semi_thin"),
                customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(HomeFavoritesWidget.linkColor(favoriteCategory) ?? Colors.red)} : null,
                // renderMode: RenderMode.sliverList,
            )
            : Text(Localization().getStringEx("panel.saved.message.no_items.description", "Tap the \u2606 on events, dining locations, and reminders that interest you to quickly find them here."), style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"),),
        Expanded(child: Container(), flex: 3),
    ],),);
  }

  Widget _buildFavoritesContent() {
    List<Widget> contentList = <Widget>[];
    EdgeInsetsGeometry padding = EdgeInsets.zero;
    if (widget.favoriteCategories.length > 1) {
      for (String favoriteCategory in widget.favoriteCategories) {
        contentList.add(_SavedItemsList(headingTitle: _favoriteCategoryTitle(favoriteCategory),
          headingIconKey: _favoriteCategoryIconKey(favoriteCategory),
          items: _favorites[favoriteCategory])
        );
      }
      padding = EdgeInsets.zero;
    }
    else if (widget.favoriteCategories.length == 1) {
      String favoriteCategory = widget.favoriteCategories.single;
      List<Favorite>? favorites = _favorites[favoriteCategory];
      if (0 < (favorites?.length ?? 0)) {
        for (int index = 0; index < favorites!.length; index++) {
          contentList.add(Padding(padding: EdgeInsets.only(top: (0 < index) ? 8 : 0), child:
            _SavedItem(favorites[index])
          ));
        }
        contentList.add(LinkButton(
          title: Localization().getStringEx('panel.saved.button.all.title', 'View All'),
          hint: Localization().getStringEx('panel.saved.button.all.hint', 'Tap to see all favorite items'),
          onTap: () => _onViewAll(favoriteCategory),
        ));
      }
      padding = EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    }
    
    return SingleChildScrollView(child:
      Padding(padding: padding, child:
        Column(children: contentList,)
      ,)
    );
  }

  // Content

  void _refreshFavorites({Set<String>? favoriteCategories, bool showProgress = true}) {
    if (Connectivity().isOnline) {
      if (showProgress && mounted) {
        setState(() {
          _loadingFavorites = true;
        });
      }
      _loadFavorites(favoriteCategories: favoriteCategories).then((Map<String, List<Favorite>?> favorites) {
        if (mounted) {
          setState(() {
            _favorites = favorites;
            _loadingFavorites = false;
          });
        }
      }); 
    }
  }

  Future<Map<String, List<Favorite>?>> _loadFavorites({Set<String>? favoriteCategories}) async {

    List<String> futuresCategories = <String>[];
    List<Future<List<Favorite>?>> futures = <Future<List<Favorite>?>>[];
    for (String favoriteCategory in widget.favoriteCategories) {
      if ((favoriteCategories == null) || favoriteCategories.contains(favoriteCategory)) {
        futures.add(_favoriteCategoryLoader(favoriteCategory)(Auth2().prefs?.getFavorites(favoriteCategory)));
        futuresCategories.add(favoriteCategory);
      }
    }

    List<List<Favorite>?> results = await Future.wait(futures);
    
    Map<String, List<Favorite>?> result = <String, List<Favorite>?>{};
    for (int index = 0; index < futuresCategories.length; index++) {
      if (index < results.length) {
        result[futuresCategories[index]] = results[index];
      }
    }
    return result;
  }

  Future<List<Favorite>?> Function(LinkedHashSet<String>?) _favoriteCategoryLoader(String favoriteCategory) {
    switch(favoriteCategory) {
      case Event.favoriteKeyName: return _loadFavoriteEvents;
      case Event2.favoriteKeyName: return _loadFavoriteEvents2;
      case Dining.favoriteKeyName: return _loadFavoriteDinings;
      case Game.favoriteKeyName: return _loadFavoriteGames;
      case News.favoriteKeyName: return _loadFavoriteNews;
      case LaundryRoom.favoriteKeyName: return _laundryAvailable ? _loadFavoriteLaundries : _loadNOP;
      case MTDStop.favoriteKeyName: return _loadFavoriteMTDStops;
      case ExplorePOI.favoriteKeyName: return _loadFavoriteMTDDestinations;
      case GuideFavorite.favoriteKeyName: return _loadFavoriteGuideItems;
      case Appointment.favoriteKeyName: return _loadFavoriteAppointments;
    }
    return _loadNOP;
  }

  Future<List<Favorite>?> _loadNOP(LinkedHashSet<String>? favoriteIds) async => null;

  Future<List<Favorite>?> _loadFavoriteEvents(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList(await Events().loadEventsByIds(favoriteIds), favoriteIds) : null;

  Future<List<Favorite>?> _loadFavoriteEvents2(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList(await Events2().loadEventsByIds(eventIds: favoriteIds?.toList()), favoriteIds) : null;

  Future<List<Favorite>?> _loadFavoriteDinings(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList(await Dinings().loadBackendDinings(false, null, null), favoriteIds) : null;

  Future<List<Favorite>?> _loadFavoriteGames(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList(await Sports().loadGames(), favoriteIds) : null;

  Future<List<Favorite>?> _loadFavoriteNews(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList(await Sports().loadNews(null, 0), favoriteIds) : null;

  Future<List<Favorite>?> _loadFavoriteMTDStops(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? ListUtils.reversed(MTD().stopsByIds(favoriteIds)) : null;

  Future<List<Favorite>?> _loadFavoriteMTDDestinations(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? ListUtils.reversed(ExplorePOI.listFromString(favoriteIds)) : null;

  Future<List<Favorite>?> _loadFavoriteLaundries(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList((await Laundries().loadSchoolRooms())?.rooms, favoriteIds) : null;

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

  Future<List<Favorite>?> _loadFavoriteAppointments(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList(Appointments().getAppointments(timeSource: AppointmentsTimeSource.upcoming), favoriteIds) : null;

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

  String get _headerBarTitle => (widget.favoriteCategories.length == 1) ?
    (_favoriteCategoryTitle(widget.favoriteCategories.first) ?? '') :
    Localization().getStringEx('panel.saved.header.label', 'Saved');

  String? _favoriteCategoryTitle(String favoriteCategory) {
    switch(favoriteCategory) {
      case Event.favoriteKeyName:         return Localization().getStringEx('panel.saved.label.events', 'My Events');
      case Event2.favoriteKeyName:        return Localization().getStringEx('panel.saved.label.events2', 'My Events');
      case Dining.favoriteKeyName:        return Localization().getStringEx('panel.saved.label.dining', "My Dining Locations");
      case Game.favoriteKeyName:          return Localization().getStringEx('panel.saved.label.athletics', 'My Athletics Events');
      case News.favoriteKeyName:          return Localization().getStringEx('panel.saved.label.news', 'My Athletics News');
      case LaundryRoom.favoriteKeyName:   return Localization().getStringEx('panel.saved.label.laundry', 'My Laundry');
      case MTDStop.favoriteKeyName:       return Localization().getStringEx('panel.saved.label.mtd_stops', 'My Bus Stops');
      case ExplorePOI.favoriteKeyName:    return Localization().getStringEx('panel.saved.label.mtd_destinations', 'My Destinations');
      case GuideFavorite.favoriteKeyName: return Localization().getStringEx('panel.saved.label.campus_guide', 'My Campus Guide');
      case Appointment.favoriteKeyName:   return Localization().getStringEx('panel.saved.label.appointments', 'MyMcKinley Appointments');
    }
    return null;
  }

  String? _favoriteCategoryIconKey(String favoriteCategory) {
    switch(favoriteCategory) {
      case Event.favoriteKeyName:         return 'events';
      case Event2.favoriteKeyName:        return 'events';
      case Dining.favoriteKeyName:        return 'dining';
      case Game.favoriteKeyName:          return 'athletics';
      case News.favoriteKeyName:          return 'news';
      case LaundryRoom.favoriteKeyName:   return 'laundry';
      case MTDStop.favoriteKeyName:       return 'transit';
      case ExplorePOI.favoriteKeyName:    return 'location';
      case GuideFavorite.favoriteKeyName: return 'guide.';
      case Appointment.favoriteKeyName:   return 'appointments';
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

  bool get _laundryAvailable => true; // IlliniCash().ballance?.housingResidenceStatus ?? false;

  void _onViewAll(String favoriteCategory) {
    Analytics().logSelect(target: 'View All');
    FavoriteExt.launchHome(context, key: favoriteCategory);
  }
}

class _SavedItemsList extends StatefulWidget {
  final List<Favorite>? items;
  final int limit;
  final String? headingTitle;
  final String? headingIconKey;
  final String slantImageKey;
  final Color? slantColor;

  // ignore: unused_element
  _SavedItemsList({this.items, this.limit = 3, this.headingTitle, this.headingIconKey, this.slantImageKey = 'slant-dark', this.slantColor});

  _SavedItemsListState createState() => _SavedItemsListState();
}

class _SavedItemsListState extends State<_SavedItemsList>{

  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    if (CollectionUtils.isEmpty(widget.items)) {
      return Container();
    }
    bool showMoreButton = (0 < widget.limit) && (widget.limit < widget.items!.length);
    return Column(
      children: <Widget>[
        SectionSlantHeader(
            title: widget.headingTitle,
            titleIconKey: widget.headingIconKey,
            slantImageKey: widget.slantImageKey,
            slantColor: widget.slantColor ?? Styles().colors!.fillColorPrimary,
            children: (0 <  widget.items!.length) ? _buildListItems(context) : _buildEmptyContent(context),),
        Visibility(visible: showMoreButton, child: Padding(padding: EdgeInsets.only(top: 8, bottom: 40), child: SmallRoundedButton(
          label: _showAll ? Localization().getStringEx('panel.saved.button.less.title', "Show Less") : Localization().getStringEx('panel.saved.button.more.title', "Show All"),
          onTap: _onViewAllTapped,
        ),),)
      ],
    );
  }

  List<Widget> _buildListItems(BuildContext context) {
    List<Widget> widgets = [];
    if (CollectionUtils.isNotEmpty(widget.items)) {
      int itemsCount = widget.items!.length;
      int visibleCount = (((widget.limit <= 0) || _showAll) ? itemsCount : min(widget.limit, itemsCount));
      for (int i = 0; i < visibleCount; i++) {
        widgets.add(_SavedItem(widget.items![i]));
        if (i < (visibleCount - 1)) {
          widgets.add(Container(height: 12,));
        }
      }
    }
    return widgets;
  }

  List<Widget> _buildEmptyContent(BuildContext context) {
    return <Widget>[Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), child:
      Column(children: <Widget>[
        Expanded(child: Container(), flex: 1),
        Text(Localization().getStringEx("panel.saved.message.no_items.description", "Tap the \u2606 on events, dining locations, and reminders that interest you to quickly find them here."), style: Styles().textStyles?.getTextStyle("widget.item.regular.thin")),
        Expanded(child: Container(), flex: 3),
    ],),)];
  
  }

  void _onViewAllTapped() {
    setState(() {
      _showAll = !_showAll;
    });
  }
}

class _SavedItem extends StatelessWidget {
  final Favorite favorite;
  
  _SavedItem(this.favorite, {Key ? key}) : super(key: key);

  Event? get _favoriteEvent => (favorite is Event) ? (favorite as Event) : null;

  @override
  Widget build(BuildContext context) {
    return  (_favoriteEvent?.isComposite ?? false) ? _buildCompositEventCard(context) : _buildFavoriteCard(context);
  }

  Widget _buildFavoriteCard(BuildContext context) {
    bool isFavorite = Auth2().isFavorite(favorite);
    Color? headerColor = favorite.favoriteHeaderColor;
    String? title = favorite.favoriteTitle;
    String? cardDetailText = favorite.favoriteDetailText;
    Widget? cardDetailImage = StringUtils.isNotEmpty(cardDetailText) ? favorite.favoriteDetailIcon : null;
    bool detailVisible = StringUtils.isNotEmpty(cardDetailText);
    return GestureDetector(onTap: () => _onTapFavorite(context), child:
      Semantics(label: title, child:
        Column(children: <Widget>[
          Container(height: 7, color: headerColor,),
          Container(decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4))), child:
            Padding(padding: EdgeInsets.all(16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Flex(direction: Axis.vertical, children: <Widget>[
                    Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                      Expanded(child:
                        Text(title ?? '', semanticsLabel: "", style: Styles().textStyles?.getTextStyle("widget.card.title.medium"), ),
                      ),
                      Visibility(visible: Auth2().canFavorite, child:
                        GestureDetector(behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Analytics().logSelect(target: "Favorite: $title");
                            Auth2().prefs?.toggleFavorite(favorite);
                          }, child:
                          Semantics(container: true,
                            label: isFavorite
                                ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites')
                                : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                            hint: isFavorite
                                ? Localization().getStringEx('widget.card.button.favorite.off.hint', '')
                                : Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
                            button: true,
                            excludeSemantics: true,
                            child:
                              Container(padding: EdgeInsets.only(left: 24, bottom: 24), child: favorite.favoriteStarIcon(selected: isFavorite)))),
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
                            Text(cardDetailText ?? '', semanticsLabel: "", style: Styles().textStyles?.getTextStyle("widget.card.detail.medium")),
                          )
                        ],) :
                        Text(cardDetailText ?? '', semanticsLabel: "", style: Styles().textStyles?.getTextStyle("widget.card.detail.medium")),
                  )),)
                ]),
              ),
            )
          ],
        )),);
  }

  Widget _buildCompositEventCard(BuildContext context) {
      return ExploreCard(explore: favorite as Event, showTopBorder: true, horizontalPadding: 0, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        onTap:() => _onTapCompositeEvent(context));
  }

  void _onTapFavorite(BuildContext context) {
    Analytics().logSelect(target: favorite.favoriteTitle);
    favorite.favoriteLaunchDetail(context);
  }

  void _onTapCompositeEvent(BuildContext context) {
    Analytics().logSelect(target: favorite.favoriteTitle);
    if (_favoriteEvent?.isComposite ?? false) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => CompositeEventsDetailPanel(parentEvent: _favoriteEvent)));
    }
    else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreDetailPanel(explore: _favoriteEvent)));
    }
  }
}