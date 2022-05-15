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

  int _progress = 0;

  List<Favorite>? _events;
  List<Favorite>? _dinings;
  List<Favorite>? _athletics;
  List<Favorite>? _news;
  List<Favorite>? _laundries;
  List<Favorite>? _guideItems;
  List<Favorite>? _inboxMessageItems;

  bool _showNotificationPermissionPrompt = false;
  bool _laundryAvailable = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Assets.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      Guide.notifyChanged
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
    if (Platform.isIOS && Auth2().privacyMatch(4)) {

      NotificationPermissions.getNotificationPermissionStatus().then((PermissionStatus status) {
        if (status == PermissionStatus.unknown) {
          setState(() {
            _showNotificationPermissionPrompt = true;
          });
        }
      });

    }
  }

  void _requestAuthorization() async {
    PermissionStatus permissionStatus = await NotificationPermissions.getNotificationPermissionStatus();
    if (permissionStatus != PermissionStatus.unknown) {
      showDialog(context: context, builder: (context) => _buildNotificationPermissionDialogWidget(context, permissionStatus));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: <Widget>[
        Expanded(
          child: Container(
            color: Styles().colors!.background,
            child: Stack(
              children: <Widget>[
                CustomScrollView(
                  slivers: <Widget>[
                    SliverHeaderBar(
                      leadingAsset: 'images/chevron-left-white.png',
                      title: Localization().getStringEx('panel.saved.header.label', 'Saved'),
                      textColor: Styles().colors!.white,
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
                              headingTitle: Localization().getStringEx('panel.saved.label.campus_guide', 'Campus Guide'),
                              headingIconResource: 'images/icon-news.png',
                              items: _guideItems,),
                            _buildItemsSection(
                              headingTitle: Localization().getStringEx('panel.saved.label.inbox', 'Inbox'),
                              headingIconResource: 'images/icon-news.png',
                              items: _inboxMessageItems,),
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
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  void _loadSavedItems() {
    _loadEvents();
    _loadDinings();
    _loadAthletics();
    _loadNews();
    _loadLaundries();
    _loadGuideItems();
    _loadInboxMessages();
  }

  void _loadEvents() {
    Set<String>? favoriteEventIds = Auth2().prefs?.getFavorites(Event.favoriteKeyName);
    if (CollectionUtils.isNotEmpty(favoriteEventIds) && Connectivity().isNotOffline) {
      setState(() {
        _progress++;
      });
      Events().loadEventsByIds(favoriteEventIds).then((List<Event>? events) {
        setState(() {
          _progress--;
          _events = _buildFilteredItems(events, favoriteEventIds);
        });
      });
    }
    else if (CollectionUtils.isNotEmpty(_events)) {
      setState(() {
        _events = null;
      });
    }
  }

  void _loadDinings() {
    Set<String>? favoriteDiningIds = Auth2().prefs?.getFavorites(Dining.favoriteKeyName);
    if (CollectionUtils.isNotEmpty(favoriteDiningIds) && Connectivity().isNotOffline) {
      setState(() {
        _progress++;
      });
      Dinings().loadBackendDinings(false, null, null).then((List<Dining>? items) {
        setState(() {
          _progress--;
          _dinings = _buildFilteredItems(items, favoriteDiningIds);
        });
      });
    }
    else if (CollectionUtils.isNotEmpty(_dinings)) {
      setState(() {
        _dinings = null;
      });
    }
  }

  void _loadAthletics() {
    Set<String>? favoriteGameIds = Auth2().prefs?.getFavorites(Game.favoriteKeyName);
    if (CollectionUtils.isNotEmpty(favoriteGameIds) && Connectivity().isNotOffline) {
      setState(() {
        _progress++;
      });
      Sports().loadGames().then((List<Game>? athleticItems) {
        setState(() {
          _progress--;
          _athletics = _buildFilteredItems(athleticItems, favoriteGameIds);
        });
      });
    }
    else if (CollectionUtils.isNotEmpty(_athletics)) {
      setState(() {
        _athletics = null;
      });
    }
  }

  void _loadNews() {
    Set<String>? favoriteNewsIds = Auth2().prefs?.getFavorites(News.favoriteKeyName);
    if (CollectionUtils.isNotEmpty(favoriteNewsIds) && Connectivity().isNotOffline) {
      setState(() {
        _progress++;
      });
      Sports().loadNews(null, 0).then((List<News>? newsItems) {
        setState(() {
          _progress--;
          _news = _buildFilteredItems(newsItems, favoriteNewsIds);
        });
      });
    }
    else if (CollectionUtils.isNotEmpty(_news)) {
      setState(() {
        _news = null;
      });
    }
  }

  void _loadLaundries() {
    if (!_laundryAvailable) {
      return;
    }
    Set<String>? favoriteLaundryIds = Auth2().prefs?.getFavorites(LaundryRoom.favoriteKeyName);
    if (CollectionUtils.isNotEmpty(favoriteLaundryIds) && Connectivity().isNotOffline) {
      setState(() {
        _progress++;
      });
      Laundries().loadSchoolRooms().then((LaundrySchool? laundrySchool) {
        setState(() {
          _progress--;
          _laundries = _buildFilteredItems(laundrySchool?.rooms, favoriteLaundryIds);
        });
      });
    }
    else if (CollectionUtils.isNotEmpty(_laundries)) {
      setState(() {
        _laundries = null;
      });
    }
  }

  void _loadGuideItems() {

    Set<String?>? favoriteGuideIds = Auth2().prefs?.getFavorites(GuideFavorite.favoriteKeyName);
    List<Favorite> guideItems = <Favorite>[];
    if (favoriteGuideIds != null) {
      for (dynamic contentEntry in Guide().contentList!) {
        String? guideEntryId = Guide().entryId(JsonUtils.mapValue(contentEntry));
        
        if ((guideEntryId != null) && favoriteGuideIds.contains(guideEntryId)) {
          guideItems.add(GuideFavorite(id: guideEntryId,));
        }
      }
    }

    if (CollectionUtils.isNotEmpty(guideItems) && Connectivity().isNotOffline) {
      setState(() {
        _guideItems = guideItems;
      });
    }
    else if (CollectionUtils.isNotEmpty(_guideItems)) {
      setState(() {
        _guideItems = null;
      });
    }
  }

  void _loadInboxMessages() {
    Set<String?>? favoriteMessageIds = Auth2().prefs?.getFavorites(InboxMessage.favoriteKeyName);
    if (favoriteMessageIds != null) {
      setState(() {
        _progress++;
      });
      Inbox().loadMessages(messageIds: favoriteMessageIds).then((List<InboxMessage>? messages) {
        if (mounted) {
          setState(() {
            _progress--;
            _inboxMessageItems = messages;
          });
        }
      });
    }
  }

  List<Favorite>? _buildFilteredItems(List<Favorite>? items, Set<String>? ids) {
    if (CollectionUtils.isEmpty(items) || CollectionUtils.isEmpty(ids)) {
      return null;
    }
    List<Favorite> result = [];
    items!.forEach((Favorite? item) {
      String? id = item!.favoriteId;
      if (StringUtils.isNotEmpty(id) && ids!.contains(id)) {
        result.add(item);
      }
    });
    return result;
  }

  Widget _buildNotificationPermissionDialogWidget(BuildContext context, PermissionStatus permissionStatus) {
    String? message;
    if (permissionStatus == PermissionStatus.granted) {
      message = Localization().getStringEx('panel.onboarding.notifications.label.access_granted', 'You already have granted access to this app.');
    }
    else if (permissionStatus == PermissionStatus.denied) {
      message = Localization().getStringEx('panel.onboarding.notifications.label.access_denied', 'You already have denied access to this app.');
    }
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
                message ?? '',
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontFamily: Styles().fontFamilies!.medium,
                    fontSize: 16,
                    color: Colors.black),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                    onPressed: () {
                      Analytics().logAlert(text:"Already have access", selection: "Ok");
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
      child: Container(color: Styles().colors!.fillColorPrimary, child:
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
                      fontFamily: Styles().fontFamilies!.regular,
                      fontSize: 16,
                      color: Styles().colors!.white
                  ),
                )
              )
              ),
              Padding(padding: EdgeInsets.only(right: 16),
                child: InkWell(onTap: _onSkipTapped, child: Image.asset('images/close-white.png', excludeFromSemantics: true))
              )

            ],
          ),
          Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: ToggleRibbonButton(
              label: Localization().getStringEx("panel.saved.notifications.enable.label", "Enable notifications"),
              toggled: false,
              onTap: _onAuthorizeTapped,
              borderRadius:
              BorderRadius.all(Radius.circular(4)),
              )),
        ]
      )),
    ) : Container();
  }

  Widget _buildItemsSection({required String? headingTitle, required String headingIconResource, required List<Favorite>? items}) {
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
                fontFamily: Styles().fontFamilies!.bold,
                fontSize: 20,
                color: Styles().colors!.fillColorPrimary
            ),
          ),
          Container(height: 24,),
          Text(Localization().getStringEx("panel.saved.message.no_items.description", "Tap the \u2606 on events, dining locations, and reminders that interest you to quickly find them here."),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: Styles().fontFamilies!.regular,
                fontSize: 16,
                color: Styles().colors!.textBackground
            ),
          ),
        ],
      ),
    );
  }

  bool _isContentEmpty() {
    return
      !CollectionUtils.isNotEmpty(_events) &&
          !CollectionUtils.isNotEmpty(_dinings) &&
          !CollectionUtils.isNotEmpty(_athletics) &&
          !CollectionUtils.isNotEmpty(_news) &&
          !CollectionUtils.isNotEmpty(_laundries) &&
          !CollectionUtils.isNotEmpty(_guideItems);
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
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setState(() { _loadSavedItems(); });
    }
    else if (name == Guide.notifyChanged) {
      setState(() { _loadGuideItems(); });
    }
  }
}

class _SavedItemsList extends StatefulWidget {
  final int limit;
  final List<Favorite>? items;
  final String? heading;
  final String? headingIconRes;
  final String slantImageRes;
  final Color? slantColor;

  _SavedItemsList(
      {this.items, this.limit = 3, this.heading, this.headingIconRes, this.slantImageRes = 'images/slant-down-right-blue.png',
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
            title: widget.heading,
            titleIconAsset: widget.headingIconRes,
            slantImageAsset: widget.slantImageRes,
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
