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

import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/service/Assets.dart';
import 'package:illinois/service/Connectivity.dart';
import 'package:illinois/service/DiningService.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:illinois/service/LaundryService.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/StudentGuide.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/service/LocalNotifications.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/model/UserData.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreDiningDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreEventDetailPanel.dart';
import 'package:illinois/ui/guide/StudentGuideDetailPanel.dart';
import 'package:illinois/ui/laundry/LaundryDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/service/ExploreService.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/widgets/SectionTitlePrimary.dart';
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

import 'athletics/AthleticsNewsArticlePanel.dart';
import 'events/CompositeEventsDetailPanel.dart';
import 'explore/ExploreDetailPanel.dart';

class SavedPanel extends StatefulWidget {

  final ScrollController scrollController;

  SavedPanel({this.scrollController});

  @override
  _SavedPanelState createState() => _SavedPanelState();
}

class _SavedPanelState extends State<SavedPanel> implements NotificationsListener {

  int _progress = 0;

  List<Favorite> _events;
  List<Favorite> _dinings;
  List<Favorite> _athletics;
  List<Favorite> _news;
  List<Favorite> _laundries;
  List<Favorite> _guideItems;

  bool _showNotificationPermissionPrompt = false;
  bool _laundryAvailable = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Assets.notifyChanged,
      User.notifyFavoritesUpdated,
      StudentGuide.notifyChanged
    ]);
    _laundryAvailable = (IlliniCash().ballance?.housingResidenceStatus ?? false);
    _loadSavedItems();
    _requestPermissionsStatus();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  void _requestPermissionsStatus(){
    if (Platform.isIOS && User().privacyMatch(4)) {
      NativeCommunicator().queryNotificationsAuthorization("query").then((bool authorized){
        if(!authorized){
          setState(() {
            _showNotificationPermissionPrompt = true;
          });
        }
      });
    }
  }

  void _requestAuthorization() async {
    bool notificationsAuthorized = await NativeCommunicator().queryNotificationsAuthorization("query");
    if (notificationsAuthorized) {
      showDialog(context: context, builder: (context) => _buildNotificationPermissionDialogWidget(context));
    } else {
      bool granted = await NativeCommunicator().queryNotificationsAuthorization("request");
      if (granted) {
        LocalNotifications().initPlugin();
        Analytics.instance.updateNotificationServices();
      }
      print('Notifications granted: $granted');
      setState(() {
        _showNotificationPermissionPrompt = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: <Widget>[
        Expanded(
          child: Container(
            color: Styles().colors.background,
            child: Stack(
              children: <Widget>[
                CustomScrollView(
                  slivers: <Widget>[
                    SliverHeaderBar(
                      context: context,
                      backIconRes: widget.scrollController == null
                          ? 'images/chevron-left-white.png'
                          : 'images/chevron-left-blue.png',
                      titleWidget: Text(
                        Localization().getStringEx('panel.saved.header.label', 'Saved'),
                        style: TextStyle(
                            color: widget.scrollController == null
                                ? Styles().colors.white
                                : Styles().colors.fillColorPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _buildNotificationsSection(),
                            _buildStackTop(),
                            _buildItemsSection(headingTitle: Localization().getStringEx('panel.saved.label.events', 'Events'),
                                headingIconResource: 'images/icon-calendar.png',
                                items: _events),
                            _buildItemsSection(headingTitle: Localization().getStringEx('panel.saved.label.dining', "Dining"),
                              headingIconResource: 'images/icon-dining-orange.png',
                              items: _dinings,),
                            _buildItemsSection(headingTitle: Localization().getStringEx('panel.saved.label.athletics', 'Athletics'),
                                headingIconResource: 'images/icon-calendar.png',
                                items: _athletics),
                            _buildItemsSection(
                              headingTitle: Localization().getStringEx('panel.saved.label.news', 'News'),
                              headingIconResource: 'images/icon-news.png',
                              items: _news,),
                            Visibility(visible: _laundryAvailable, child: _buildItemsSection(
                              headingTitle: Localization().getStringEx('panel.saved.label.laundry', 'Laundry'),
                              headingIconResource: 'images/icon-news.png',
                              items: _laundries,),),
                            _buildItemsSection(
                              headingTitle: Localization().getStringEx('panel.saved.label.student_guide', 'Student Guide'),
                              headingIconResource: 'images/icon-news.png',
                              items: _guideItems,),
                          ],
                        ),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: widget.scrollController == null
          ? TabBarWidget()
          : Container(height: 0,),
    );
  }

  void _loadSavedItems() {
    _loadEvents();
    _loadDinings();
    _loadAthletics();
    _loadNews();
    _loadLaundries();
    _loadGuideItems();
  }

  void _loadEvents() {
    Set<String> favoriteEventIds = User().getFavorites(Event.favoriteKeyName);
    if (AppCollection.isCollectionNotEmpty(favoriteEventIds) && Connectivity().isNotOffline) {
      setState(() {
        _progress++;
      });
      ExploreService().loadEventsByIds(favoriteEventIds).then((List<Event> events) {
        setState(() {
          _progress--;
          _events = _buildFilteredItems(events, favoriteEventIds);
        });
      });
    }
    else if (AppCollection.isCollectionNotEmpty(_events)) {
      setState(() {
        _events = null;
      });
    }
  }

  void _loadDinings() {
    Set<String> favoriteDiningIds = User().getFavorites(Dining.favoriteKeyName);
    if (AppCollection.isCollectionNotEmpty(favoriteDiningIds) && Connectivity().isNotOffline) {
      setState(() {
        _progress++;
      });
      DiningService().loadBackendDinings(false, null, null).then((List<Dining> items) {
        setState(() {
          _progress--;
          _dinings = _buildFilteredItems(items, favoriteDiningIds);
        });
      });
    }
    else if (AppCollection.isCollectionNotEmpty(_dinings)) {
      setState(() {
        _dinings = null;
      });
    }
  }

  void _loadAthletics() {
    Set<String> favoriteGameIds = User().getFavorites(Game.favoriteKeyName);
    if (AppCollection.isCollectionNotEmpty(favoriteGameIds) && Connectivity().isNotOffline) {
      setState(() {
        _progress++;
      });
      Sports().loadAllScheduleGamesUnlimited().then((List<Game> athleticItems) {
        setState(() {
          _progress--;
          _athletics = _buildFilteredItems(athleticItems, favoriteGameIds);
        });
      });
    }
    else if (AppCollection.isCollectionNotEmpty(_athletics)) {
      setState(() {
        _athletics = null;
      });
    }
  }

  void _loadNews() {
    Set<String> favoriteNewsIds = User().getFavorites(News.favoriteKeyName);
    if (AppCollection.isCollectionNotEmpty(favoriteNewsIds) && Connectivity().isNotOffline) {
      setState(() {
        _progress++;
      });
      Sports().loadNews(null, 0).then((List<News> newsItems) {
        setState(() {
          _progress--;
          _news = _buildFilteredItems(newsItems, favoriteNewsIds);
        });
      });
    }
    else if (AppCollection.isCollectionNotEmpty(_news)) {
      setState(() {
        _news = null;
      });
    }
  }

  void _loadLaundries() {
    if (!_laundryAvailable) {
      return;
    }
    Set<String> favoriteLaundryIds = User().getFavorites(LaundryRoom.favoriteKeyName);
    if (AppCollection.isCollectionNotEmpty(favoriteLaundryIds) && Connectivity().isNotOffline) {
      setState(() {
        _progress++;
      });
      LaundryService().getRoomData().then((List<LaundryRoom> laundries) {
        setState(() {
          _progress--;
          _laundries = _buildFilteredItems(laundries, favoriteLaundryIds);
        });
      });
    }
    else if (AppCollection.isCollectionNotEmpty(_laundries)) {
      setState(() {
        _laundries = null;
      });
    }
  }

  void _loadGuideItems() {

    Set<String> favoriteGuideIds = User().getFavorites(StudentGuideFavorite.favoriteKeyName);
    List<Favorite> guideItems = <Favorite>[];
    if (favoriteGuideIds != null) {
      for (dynamic contentEntry in StudentGuide().contentList) {
        String guideEntryId = StudentGuide().entryId(AppJson.mapValue(contentEntry));
        if ((guideEntryId != null) && favoriteGuideIds.contains(guideEntryId)) {
          guideItems.add(StudentGuideFavorite(id: guideEntryId));
        }
      }
    }

    if (AppCollection.isCollectionNotEmpty(guideItems) && Connectivity().isNotOffline) {
      setState(() {
        _guideItems = guideItems;
      });
    }
    else if (AppCollection.isCollectionNotEmpty(_guideItems)) {
      setState(() {
        _guideItems = null;
      });
    }
  }

  List<Favorite> _buildFilteredItems(List<Favorite> items, Set<String> ids) {
    if (AppCollection.isCollectionEmpty(items) || AppCollection.isCollectionEmpty(ids)) {
      return null;
    }
    List<Favorite> result = [];
    items.forEach((Favorite item) {
      String id = item.favoriteId;
      if (AppString.isStringNotEmpty(id) && ids.contains(id)) {
        result.add(item);
      }
    });
    return result;
  }

  Widget _buildNotificationPermissionDialogWidget(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              Localization().getStringEx('app.title', 'Illinois'),
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Text(
                Localization().getStringEx('panel.onboarding.notifications.label.access_granted', 'You already have granted access to this app.'),
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontFamily: Styles().fontFamilies.medium,
                    fontSize: 16,
                    color: Colors.black),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                    onPressed: () {
                      Analytics.instance.logAlert(text:"Already have access", selection: "Ok");
                      setState(() {
                        Navigator.pop(context);
                        _showNotificationPermissionPrompt = false;
                      });
                    },
                    child: Text(Localization().getStringEx('dialog.ok.title', 'OK')))
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return _showNotificationPermissionPrompt ? Padding(
      padding: const EdgeInsets.all(0),
      child: Container(color: Styles().colors.fillColorPrimary, child:
        Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child:
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  Localization().getStringEx("panel.saved.notifications.label", "Don’t miss an event! Get reminders of upcoming events."),
                  style: TextStyle(
                      fontFamily: Styles().fontFamilies.regular,
                      fontSize: 16,
                      color: Styles().colors.white
                  ),
                )
              )
              ),
              Padding(padding: EdgeInsets.only(right: 16),
                child: InkWell(onTap: _onSkipTapped, child: Image.asset('images/close-white.png'))
              )

            ],
          ),
          Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: ToggleRibbonButton(
              height: null,
              label: Localization().getStringEx("panel.saved.notifications.enable.label", "Enable notifications"),
              toggled: false,
              onTap: _onAuthorizeTapped,
              context: context,
              borderRadius:
              BorderRadius.all(Radius.circular(4)),
              )),
        ]
      )),
    ) : Container();
  }

  Widget _buildItemsSection({@required String headingTitle, @required String headingIconResource, @required List<Favorite> items}) {
    return _SavedItemsList(
      heading: headingTitle,
      headingIconRes: headingIconResource,
      items: items,
    );
  }

  Widget _buildStackTop() {
    if (0 < _progress) {
      return _buildProgress();
    }
    else if (Connectivity().isOffline) {
      return _buildOffline();
    }
    else if (_isContentEmpty()) {
      return _buildEmpty();
    }
    else {
      return Container();
    }
  }

  Widget _buildProgress() {
    return Container(alignment: Alignment.center, child:
      CircularProgressIndicator(),
    );
  }

  Widget _buildOffline() {
    return Column(children: <Widget>[
      Expanded(child: Container(), flex: 1),
      Text(Localization().getStringEx("app.offline.message.title", "You appear to be offline"), style: TextStyle(fontSize: 16),),
      Container(height:8),
      Text(Localization().getStringEx("panel.saved.message.offline", "Saved Items are not available while offline")),
      Expanded(child: Container(), flex: 3),
    ],);
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: <Widget>[
          Container(height: 24,),
          Text(Localization().getStringEx("panel.saved.message.no_items", "Whoops! Nothing to see here."),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: Styles().fontFamilies.bold,
                fontSize: 20,
                color: Styles().colors.fillColorPrimary
            ),
          ),
          Container(height: 24,),
          Text(Localization().getStringEx("panel.saved.message.no_items.description", "Tap the \u2606 on events, dining locations, and reminders that interest you to quickly find them here."),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: Styles().fontFamilies.regular,
                fontSize: 16,
                color: Styles().colors.textBackground
            ),
          ),
        ],
      ),
    );
  }

  bool _isContentEmpty() {
    return
      !AppCollection.isCollectionNotEmpty(_events) &&
          !AppCollection.isCollectionNotEmpty(_dinings) &&
          !AppCollection.isCollectionNotEmpty(_athletics) &&
          !AppCollection.isCollectionNotEmpty(_news) &&
          !AppCollection.isCollectionNotEmpty(_laundries) &&
          !AppCollection.isCollectionNotEmpty(_guideItems);
  }

  void _onAuthorizeTapped(){
    _requestAuthorization();
  }

  void _onSkipTapped(){
    setState(() {
      _showNotificationPermissionPrompt = false;
    });
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Connectivity.notifyStatusChanged) {
      setState(() { _loadSavedItems(); });
    }
    else if (name == Assets.notifyChanged) {
      setState(() { _loadDinings(); });
    }
    else if (name == User.notifyFavoritesUpdated) {
      setState(() { _loadSavedItems(); });
    }
    else if (name == StudentGuide.notifyChanged) {
      setState(() { _loadGuideItems(); });
    }
  }
}

class _SavedItemsList extends StatefulWidget {
  final int limit;
  final List<Favorite> items;
  final String heading;
  final String headingIconRes;
  final String slantImageRes;
  final Color slantColor;

  _SavedItemsList(
      {this.items, this.limit = 3, this.heading, this.headingIconRes, this.slantImageRes = 'images/slant-down-right-blue.png',
        this.slantColor,});

  _SavedItemsListState createState() => _SavedItemsListState();
}

class _SavedItemsListState extends State<_SavedItemsList>{

  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    if (AppCollection.isCollectionEmpty(widget.items)) {
      return Container();
    }
    bool showMoreButton = widget.limit < widget.items.length;
    return Column(
      children: <Widget>[
        SectionTitlePrimary(
            title: widget.heading,
            iconPath: widget.headingIconRes,
            slantImageRes: widget.slantImageRes,
            slantColor: widget.slantColor ?? Styles().colors.fillColorPrimary,
            children: _buildListItems(context)),
        Visibility(visible: showMoreButton, child: Padding(padding: EdgeInsets.only(top: 8, bottom: 40), child: SmallRoundedButton(
          label: _showAll ? Localization().getStringEx('panel.saved.events.button.less', "Show Less") : Localization().getStringEx(
              'panel.saved.events.button.all', "Show All"),
          onTap: _onViewAllTapped,
        ),),)
      ],
    );
  }

  List<Widget> _buildListItems(BuildContext context) {
    List<Widget> widgets = [];
    if (AppCollection.isCollectionNotEmpty(widget.items)) {
      int itemsCount = widget.items.length;
      int visibleCount = (_showAll ? itemsCount : min(widget.limit, itemsCount));
      for (int i = 0; i < visibleCount; i++) {
        Favorite item = widget.items[i];
        widgets.add(_buildItemCard(item));
        if (i < (visibleCount - 1)) {
          widgets.add(Container(height: 12,));
        }
      }
    }
    return widgets;
  }

  Widget _buildItemCard(Favorite item) {
    //Custom layout for super events before release
    if(item is Event && item.isComposite){
      return _buildCompositEventCard(item);
    }

    bool favorite = User().isFavorite(item);
    Color headerColor = _cardHeaderColor(item);
    String title = AppString.getDefaultEmptyString(value: _cardTitle(item));
    String cardDetailLabel = AppString.getDefaultEmptyString(value: _cardDetailLabel(item));
    String cardDetailImgRes = _cardDetailImageResource(item);
    bool detailVisible = AppString.isStringNotEmpty(cardDetailLabel);
    return GestureDetector(onTap: () => _onTapItem(item), child: Semantics(
        label: title,
        child: Column(
          children: <Widget>[
            Container(height: 7, color: headerColor,),
            Container(
              decoration: BoxDecoration(color: Colors.white,
                  border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4))),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Flex(
                    direction: Axis.vertical,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 20),
                            ),
                          ),
                          Visibility(
                            visible: User().favoritesStarVisible,
                            child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  Analytics.instance.logSelect(target: "Favorite : $title");
                                  User().switchFavorite(item);
                                },
                                child: Semantics(
                                    label: favorite
                                        ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites')
                                        : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                                    hint: favorite
                                        ? Localization().getStringEx('widget.card.button.favorite.off.hint', '')
                                        : Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
                                    button: true,
                                    excludeSemantics: true,
                                    child: Container(
                                        child: Padding(
                                            padding: EdgeInsets.only(left: 24),
                                            child: Image.asset(favorite ? 'images/icon-star-selected.png' : 'images/icon-star.png'))))),
                          )
                        ],
                      )
                    ],
                  ),
                  Visibility(visible: detailVisible, child:
                    Semantics(label: cardDetailLabel, excludeSemantics: true, child:
                      Padding(padding: EdgeInsets.only(top: 12), child:
                        (cardDetailImgRes != null) ? 
                        Row(children: <Widget>[
                          Padding(padding: EdgeInsets.only(right: 10), child: Image.asset(cardDetailImgRes),),
                          Expanded(child:
                            Text(cardDetailLabel, style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Styles().colors.textBackground)),
                          )
                        ],) :
                        Text(cardDetailLabel, style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Styles().colors.textBackground)),
                  )),)
                ]),
              ),
            )
          ],
        )),);
  }

  void _onTapItem(Favorite item) {
    if (item is Event) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreEventDetailPanel(event: item,)));
    } else if (item is Dining) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreDiningDetailPanel(dining: item,)));
    } else if (item is Game) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(game: item,)));
    } else if (item is News) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsNewsArticlePanel(article: item,)));
    } else if (item is LaundryRoom) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryDetailPanel(room: item,)));
    } else if (item is StudentGuideFavorite) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentGuideDetailPanel(guideEntryId: item.id,)));
    }
  }

  void _onViewAllTapped() {
    setState(() {
      _showAll = !_showAll;
    });
  }

  Color _cardHeaderColor(Favorite item) {
    if (item is Explore) {
      return (item as Explore).uiColor;
    } else if (item is Game) {
      return Styles().colors.fillColorPrimary;
    } else if (item is News) {
      return Styles().colors.fillColorPrimary;
    } else if (item is LaundryRoom) {
      return Styles().colors.accentColor2;
    } else if (item is StudentGuideFavorite) {
      return Styles().colors.accentColor3;
    } else {
      return Styles().colors.fillColorSecondary;
    }
  }

  String _cardTitle(Favorite item) {
    if (item is Explore) {
      return (item as Explore).exploreTitle;
    } else if (item is Game) {
      return item.title;
    } else if (item is News) {
      return item.title;
    } else if (item is LaundryRoom) {
      return item.title;
    } else if (item is StudentGuideFavorite) {
      return StudentGuide().entryListTitle(StudentGuide().entryById(item.id), stripHtmlTags: true);
    } else {
      return null;
    }
  }

  String _cardDetailLabel(Favorite item) {
    if (item is Event) {
      return item.displayDateTime;
    } else if (item is Dining) {
      return item.displayWorkTime;
    } else if (item is Game) {
      return item.displayTime;
    } else if (item is News) {
      return item.getDisplayTime();
    } else if (item is StudentGuideFavorite) {
      return StudentGuide().entryListDescription(StudentGuide().entryById(item.id), stripHtmlTags: true);
    } else
      return null;
  }

  String _cardDetailImageResource(Favorite item) {
    if (item is StudentGuideFavorite) {
      return null;
    } else if (item is Event || item is Game || item is News) {
      return 'images/icon-calendar.png';
    } else {
      return 'images/icon-time.png';
    }
  }

  Widget _buildCompositEventCard(Event item){
      return ExploreCard(explore: item,showTopBorder: true, horizontalPadding: 0,border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        onTap:(){
          if (item != null) {
            if (item.isComposite ?? false) {
              Navigator.push(context, CupertinoPageRoute(builder: (context) => CompositeEventsDetailPanel(parentEvent: item)));
            } else {
              Navigator.push(context, CupertinoPageRoute(builder: (context) =>
                  ExploreDetailPanel(explore: item)));
            }
          }
        });
  }
}
