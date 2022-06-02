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
import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/home/HomeCanvasCoursesWidget.dart';
import 'package:illinois/ui/home/HomeFavoritesWidget.dart';
import 'package:illinois/ui/home/HomeToutWidget.dart';
import 'package:illinois/ui/home/HomeWPGUFMRadioWidget.dart';
import 'package:illinois/ui/home/HomeWalletWidget.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/home/HomeCampusRemindersWidget.dart';
import 'package:illinois/ui/home/HomeCampusToolsWidget.dart';
import 'package:illinois/ui/home/HomeCreatePollWidget.dart';
import 'package:illinois/ui/home/HomeGameDayWidget.dart';
import 'package:illinois/ui/home/HomeHighligtedFeaturesWidget.dart';
import 'package:illinois/ui/home/HomeLoginWidget.dart';
import 'package:illinois/ui/home/HomeMyGroupsWidget.dart';
import 'package:illinois/ui/home/HomePreferredSportsWidget.dart';
import 'package:illinois/ui/home/HomeRecentItemsWidget.dart';
import 'package:illinois/ui/home/HomeSaferWidget.dart';
import 'package:illinois/ui/home/HomeCampusHighlightsWidget.dart';
import 'package:illinois/ui/home/HomeTwitterWidget.dart';
import 'package:illinois/ui/home/HomeVoterRegistrationWidget.dart';
import 'package:illinois/ui/home/HomeUpcomingEventsWidget.dart';
import 'package:illinois/ui/widgets/FlexContent.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'HomeCheckListWidget.dart';

class HomePanel extends StatefulWidget {
  static const String notifyRefresh      = "edu.illinois.rokwire.home.refresh";
  static const String notifyEdit         = "edu.illinois.rokwire.home.edit";
  static const String notifyEditDone     = "edu.illinois.rokwire.home.edit.done";

  @override
  _HomePanelState createState() => _HomePanelState();

}

class _HomePanelState extends State<HomePanel> with AutomaticKeepAliveClientMixin<HomePanel> implements NotificationsListener, HomeDragAndDropHost {
  
  Set<String>? _contentCodesSet;
  List<String>? _contentCodesList;
  HomeToutWidget? _toutWidget;
  StreamController<String> _updateController = StreamController.broadcast();
  GlobalKey _saferKey = GlobalKey();
  GlobalKey _contentWrapperKey = GlobalKey();
  ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  bool _isDragging = false;
  bool _isEditing = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Localization.notifyStringsUpdated,
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged,
      Styles.notifyChanged,
      Assets.notifyChanged,
      HomeSaferWidget.notifyNeedsVisiblity,
    ]);
    _contentCodesSet = JsonUtils.setStringsValue(FlexUI()['home']) ?? <String>{};
    _contentCodesList = _buildContentCodesList();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _updateController.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.home.header.title', 'ILLINOIS')),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child:
        Listener(onPointerMove: _onPointerMove, onPointerUp: (_) => _onPointerCancel, onPointerCancel: (_) => _onPointerCancel, child:
          Column(key: _contentWrapperKey, children: <Widget>[
            Expanded(child:
              SingleChildScrollView(controller: _scrollController, child:
                Column(children: _isEditing ? _buildEditingContentList() : _buildRegularContentList(),)
              )
            ),
          ]),
        ),
      ),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: null,
    );
  }

  List<Widget> _buildRegularContentList() {

    List<Widget> widgets = [];

    widgets.add(_toutWidget ??= HomeToutWidget(updateController: _updateController, editing: _isEditing, onEdit: _onEdit, onEditDone: _onEditDone,));

    if (_contentCodesList != null) {
      for (String code in _contentCodesList!) {
        if (_contentCodesSet?.contains(code) ?? false) {
          Widget? widget = _buildWidgetFromCode(code);

          // Assets widget
          if (widget == null) {
            widget = FlexContent.fromAssets(code);
          }

          if (widget != null) {
            widgets.add(widget);
          }
        }
      }
    }

    return widgets;
  }

  Widget? _buildWidgetFromCode(String code) {
    if (code == 'game_day') {
      return HomeGameDayWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'campus_tools') {
      return HomeCampusToolsWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'pref_sports') {
      return HomePreferredSportsWidget(menSports: true, womenSports: true, favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'campus_reminders') {
      return HomeCampusRemindersWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'upcoming_events') {
      return HomeUpcomingEventsWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'recent_items') {
      return HomeRecentItemsWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'campus_highlights') {
      return HomeCampusHighlightsWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'twitter') {
      return HomeTwitterWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'gies_checklist') {
      return HomeCheckListWidget(contentKey: 'gies', favoriteId: code, updateController: _updateController);
    }
    else if (code == 'new_student_checklist') {
      return HomeCheckListWidget(contentKey: "uiuc_student" /* TBD => "new_student" */, favoriteId: code, updateController: _updateController);
    }
    else if (code == 'canvas_courses') {
      return HomeCanvasCoursesWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'voter_registration') {
      return HomeVoterRegistrationWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'create_poll') {
      return HomeCreatePollWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'connect') {
      return HomeLoginWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'highlighted_features') {
      return HomeHighlightedFeatures(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'my_groups') {
      return HomeMyGroupsWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'safer') {
      return HomeSaferWidget(key: _saferKey, favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'wallet') {
      return HomeWalletWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'wpgufm_radio') {
      return HomeWPGUFMRadioWidget(favoriteId: code, updateController: _updateController,);
    }

    // Favs

    else if (code == 'events_favs') {
      return HomeFavoritesWidget(favoriteKey: Event.favoriteKeyName, favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'dining_favs') {
      return HomeFavoritesWidget(favoriteKey: Dining.favoriteKeyName, favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'athletics_favs') {
      return HomeFavoritesWidget(favoriteKey: Game.favoriteKeyName, favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'news_favs') {
      return HomeFavoritesWidget(favoriteKey: News.favoriteKeyName, favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'laundry_favs') {
      return HomeFavoritesWidget(favoriteKey: LaundryRoom.favoriteKeyName, favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'inbox_favs') {
      return HomeFavoritesWidget(favoriteKey: InboxMessage.favoriteKeyName, favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'campus_guide_favs') {
      return HomeFavoritesWidget(favoriteKey: GuideFavorite.favoriteKeyName, favoriteId: code, updateController: _updateController,);
    }
    else {
      return null;
    }
  }

  List<Widget> _buildEditingContentList() {
    List<Widget> widgets = [];

    widgets.add(_toutWidget ??= HomeToutWidget(updateController: _updateController, editing: _isEditing, onEdit: _onEdit, onEditDone: _onEditDone,));

    LinkedHashSet<String>? homeFavorites = Auth2().prefs?.getFavorites(HomeFavorite.favoriteKeyName);

    if (homeFavorites != null) {

      widgets.add(_buildEditingHeader(title: 'Favorites', favoriteId: '', dropAnchorAlignment: CrossAxisAlignment.end,
        description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec risus sapien, tempus sed bibendum et, accumsan interdum velit. Integer bibendum feugiat lectus, eget sollicitudin enim vulputate sit amet. Pellentesque at risus odio.',
      ));
       
      int position = 0;
      for (String code in homeFavorites) {
        Widget? widget = _buildWidgetHandleFromCode(code, position);
        if (widget != null) {
          widgets.add(widget);
          position++;
        }
      }
    }

    List<String>? fullContent = JsonUtils.listStringsValue(FlexUI().contentSourceEntry('home'));
    if (fullContent != null) {

      widgets.add(_buildEditingHeader(title: 'Unused Favorites', favoriteId: null, dropAnchorAlignment: CrossAxisAlignment.end,
        description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec risus sapien, tempus sed bibendum et, accumsan interdum velit. Integer bibendum feugiat lectus, eget sollicitudin enim vulputate sit amet. Pellentesque at risus odio.',
      ));

      int position = 0;
      for (String code in fullContent) {
        if (!(homeFavorites?.contains(code) ?? false)) {
          Widget? widget = _buildWidgetHandleFromCode(code, position);
          if (widget != null) {
            widgets.add(widget);
            position++;
          }
        }
      }
    }

    widgets.add(Container(height: 24,));

    return widgets;
  }

  Widget? _buildWidgetHandleFromCode(String code, int position) {
    if (code == 'game_day') {
      return HomeGameDayWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'campus_tools') {
      return HomeCampusToolsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'pref_sports') {
      return HomePreferredSportsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'campus_reminders') {
      return HomeCampusRemindersWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'upcoming_events') {
      return HomeUpcomingEventsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'recent_items') {
      return HomeRecentItemsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'campus_highlights') {
      return HomeCampusHighlightsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'twitter') {
      return HomeTwitterWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'gies_checklist') {
      return HomeCheckListWidget.handle(contentKey: 'gies', favoriteId: code, dragAndDropHost: this, position: position);
    }
    else if (code == 'new_student_checklist') {
      return HomeCheckListWidget.handle(contentKey: "uiuc_student" /* TBD => "new_student" */, favoriteId: code, dragAndDropHost: this, position: position);
    }
    else if (code == 'canvas_courses') {
      return HomeCanvasCoursesWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'voter_registration') {
      return null;
    }
    else if (code == 'create_poll') {
      return HomeCreatePollWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'connect') {
      return null;
    }
    else if (code == 'highlighted_features') {
      return HomeHighlightedFeatures.handle(favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'my_groups') {
      return HomeMyGroupsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'safer') {
      return HomeSaferWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'wallet') {
      return HomeWalletWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'wpgufm_radio') {
      return HomeWPGUFMRadioWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
    }

    // Favs

    else if (code == 'events_favs') {
      return HomeFavoritesWidget.handle(favoriteKey: Event.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'dining_favs') {
      return HomeFavoritesWidget.handle(favoriteKey: Dining.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'athletics_favs') {
      return HomeFavoritesWidget.handle(favoriteKey: Game.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'news_favs') {
      return HomeFavoritesWidget.handle(favoriteKey: News.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'laundry_favs') {
      return HomeFavoritesWidget.handle(favoriteKey: LaundryRoom.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'inbox_favs') {
      return HomeFavoritesWidget.handle(favoriteKey: InboxMessage.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else if (code == 'campus_guide_favs') {
      return HomeFavoritesWidget.handle(favoriteKey: GuideFavorite.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,);
    }
    else {
      return null;
    }
  }

  Widget _buildEditingHeader({String? title, String? description, String? favoriteId, CrossAxisAlignment? dropAnchorAlignment}) {
    return HomeDropTargetWidget(favoriteId: favoriteId, dragAndDropHost: this, childBuilder: (BuildContext context, { bool? dropTarget }) {
      return Column(children: [
          Container(height: 2, color: ((dropTarget == true) && (dropAnchorAlignment == CrossAxisAlignment.start)) ? Styles().colors?.fillColorSecondary : Colors.transparent,),
          Row(children: [
            Expanded(child:
              Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
                Text(title ?? '', style: TextStyle(color: Styles().colors?.fillColorPrimary, fontSize: 22, fontFamily: Styles().fontFamilies?.extraBold),),
              ),
            )
          ],),
          Row(children: [
            Expanded(child:
              Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
                Text(description ?? '', style: TextStyle(color: Styles().colors?.textColorPrimaryVariant, fontSize: 16, fontFamily: Styles().fontFamilies?.regular),),
              ),
            )
          ],),
          Container(height: 2, color: ((dropTarget == true) && (dropAnchorAlignment == CrossAxisAlignment.end)) ? Styles().colors?.fillColorSecondary : Colors.transparent,),
        ],);

    },);
  }

  void _updateContentCodesSet() {
    Set<String>? contentCodesSet = JsonUtils.setStringsValue(FlexUI()['home']);
    if ((contentCodesSet != null) && !DeepCollectionEquality().equals(_contentCodesSet, contentCodesSet)) {
      setState(() {
        _contentCodesSet = contentCodesSet;
      });
    }
  }

  List<String> _buildContentCodesList() {
    LinkedHashSet<String>? homeFavorites = Auth2().prefs?.getFavorites(HomeFavorite.favoriteKeyName);
    if ((homeFavorites != null) && homeFavorites.isNotEmpty) {
      return List.from(homeFavorites);
    }
    
    List<String>? fullContent = JsonUtils.listStringsValue(FlexUI().contentSourceEntry('home'));
    if (fullContent != null) {
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName, LinkedHashSet<String>.from(fullContent));
      return List.from(fullContent);
    }
    
    return <String>[];
  }

  void _updateContentCodesList() {
    List<String> contentCodesList = _buildContentCodesList();
    if (contentCodesList.isNotEmpty && !DeepCollectionEquality().equals(_contentCodesList, contentCodesList)) {
      setState(() {
        _contentCodesList = contentCodesList;
      });
    }
  }

  Future<void> _onPullToRefresh() async {
    if (_isEditing) {
      //TMP:
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName, null);
    }
    else {
      _updateController.add(HomePanel.notifyRefresh);
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isDragging) {
      RenderBox render = _contentWrapperKey.currentContext?.findRenderObject() as RenderBox;
      Offset position = render.localToGlobal(Offset.zero);
      double topY = position.dy;  // top position of the widget
      double bottomY = topY + render.size.height; // bottom position of the widget

      const detectedRange = 64;
      const double maxScrollDistance = 64;
      if (event.position.dy < topY + detectedRange) {
        // scroll up
        double scrollOffet = (topY + detectedRange - max(event.position.dy, topY)) / detectedRange * maxScrollDistance;
        _scrollUp(scrollOffet);

        if (_scrollTimer != null) {
          _scrollTimer?.cancel();
        }
        _scrollTimer = Timer.periodic(Duration(milliseconds: 100), (time) => _scrollUp(scrollOffet));
      }
      else if (event.position.dy > bottomY - detectedRange) {
        // scroll down
        double scrollOffet = (min(event.position.dy, bottomY) - bottomY + detectedRange) / detectedRange * maxScrollDistance;
        _scrollDown(scrollOffet);

        if (_scrollTimer != null) {
          _scrollTimer?.cancel();
        }
        _scrollTimer = Timer.periodic(Duration(milliseconds: 100), (time) => _scrollDown(scrollOffet));
      }
      else {
        _cancelScrollTimer();
      }
    }
  }

  void _onPointerCancel() {
    _cancelScrollTimer();
  }

  
  void _scrollUp(double scrollDistance) {
    double offset = max(_scrollController.offset - scrollDistance, _scrollController.position.minScrollExtent);
    if (offset < _scrollController.offset) {
      _scrollController.jumpTo(offset);
    }
  }

  void _scrollDown(double scrollDistance) {
    double offset = min(_scrollController.offset + scrollDistance, _scrollController.position.maxScrollExtent);
    if (_scrollController.offset < offset) {
      _scrollController.jumpTo(offset);
    }
  }

  void _cancelScrollTimer() {
    if (_scrollTimer != null) {
      _scrollTimer?.cancel();
      _scrollTimer = null;
    }
  }

  // HomeDragAndDropHost
  
  bool get isDragging => _isDragging;

  set isDragging(bool value) {
    if (_isDragging != value) {
      _isDragging = value;
      
      if (_isDragging) {
      }
      else {
        _cancelScrollTimer();
      }
    }
  }

  void onDragAndDrop({String? dragFavoriteId, String? dropFavoriteId, CrossAxisAlignment? dropAnchor}) {

    isDragging = false;

    if (dragFavoriteId != null) {
      List<String> favoritesList = List.from(Auth2().prefs?.getFavorites(HomeFavorite.favoriteKeyName) ?? <String>{});
      int dragIndex = favoritesList.indexOf(dragFavoriteId);
      int dropIndex = (dropFavoriteId != null) ? favoritesList.indexOf(dropFavoriteId) : -1;
      
      if ((0 <= dragIndex) && (0 <= dropIndex)) {
        // Reorder favorites
        if (dragIndex != dropIndex) {
          favoritesList.removeAt(dragIndex);
          if (dragIndex < dropIndex) {
            dropIndex--;
          }
          if (dropAnchor == CrossAxisAlignment.end) {
            dropIndex++;
          }
          favoritesList.insert(dropIndex, dragFavoriteId);
          Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName, LinkedHashSet<String>.from(favoritesList));
        }
      }
      else if ((0 <= dropIndex)) {
        // Add favorite at specific position
        HomeFavoriteButton.promptFavorite(context, dragFavoriteId).then((bool? result) {
          if (result == true) {
            if (dropAnchor == CrossAxisAlignment.end) {
              dropIndex++;
            }
            favoritesList.insert(dropIndex, dragFavoriteId);
            Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName, LinkedHashSet<String>.from(favoritesList));
          }
        });

      }
      else if ((0 <= dragIndex) && (dropFavoriteId != '')) {
        // Remove favorite
        HomeFavoriteButton.promptFavorite(context, dragFavoriteId).then((bool? result) {
          if (result == true) {
            Auth2().prefs?.toggleFavorite(HomeFavorite(dragFavoriteId));
          }
        });
      }
    }



  }

  void _ensureSaferWidgetVisibiity() {
      BuildContext? saferContext = _saferKey.currentContext;
      if (saferContext != null) {
        Scrollable.ensureVisible(saferContext, duration: Duration(milliseconds: 300));
      }
  }

  void _onEdit() {
    _updateController.add(HomePanel.notifyEdit);
    if (mounted) {
      setState(() {
        _isEditing = true;
      });
    }
  }

  void _onEditDone() {
    _updateController.add(HomePanel.notifyEditDone);
    if (mounted) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      if (param == AppLifecycleState.resumed) {
        setState(() {});
      }
    }
    else if (name == Localization.notifyStringsUpdated) {
      setState(() { });
    }
    else if (name == FlexUI.notifyChanged) {
      _updateContentCodesSet();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _updateContentCodesList();
    }
    else if(name == Storage.offsetDateKey){
      setState(() {});
    }
    else if(name == Storage.useDeviceLocalTimeZoneKey){
      setState(() {});
    }
    else if (name == Styles.notifyChanged){
      setState(() {});
    }
    else if (name == Assets.notifyChanged) {
      setState(() {});
    }
    else if (name == HomeSaferWidget.notifyNeedsVisiblity) {
      _ensureSaferWidgetVisibiity();
    }
  }
}

// HomeFavorite

class HomeFavorite implements Favorite {
  final String? id;
  HomeFavorite(this.id);

  bool operator == (o) => o is HomeFavorite && o.id == id;

  int get hashCode => (id?.hashCode ?? 0);

  static const String keyName = "home";
  static const String categoryName = "WidgetIds";
  static const String favoriteKeyName = "$keyName$categoryName";
  @override String get favoriteKey => favoriteKeyName;
  @override String? get favoriteId => id;
}

// HomeDragAndDropHost

abstract class HomeDragAndDropHost  {
  set isDragging(bool value);
  void onDragAndDrop({String? dragFavoriteId, String? dropFavoriteId, CrossAxisAlignment? dropAnchor});
}

