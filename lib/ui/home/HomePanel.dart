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
import 'package:illinois/ui/home/HomeAppHelpWidget.dart';
import 'package:illinois/ui/home/HomeAthleticsEventsWidget.dart';
import 'package:illinois/ui/home/HomeAthleticsNewsWidget.dart';
import 'package:illinois/ui/home/HomeAthleticsTeamsWidget.dart';
import 'package:illinois/ui/home/HomeCampusLinksWidget.dart';
import 'package:illinois/ui/home/HomeCanvasCoursesWidget.dart';
import 'package:illinois/ui/home/HomeFavoritesWidget.dart';
import 'package:illinois/ui/home/HomeStateFarmCenterWidget.dart';
import 'package:illinois/ui/home/HomeTBDWidget.dart';
import 'package:illinois/ui/home/HomeToutWidget.dart';
import 'package:illinois/ui/home/HomeWPGUFMRadioWidget.dart';
import 'package:illinois/ui/home/HomeWalletWidget.dart';
import 'package:illinois/ui/home/HomeWelcomeWidget.dart';
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
import 'package:illinois/ui/home/HomeCampusResourcesWidget.dart';
import 'package:illinois/ui/home/HomeCreatePollWidget.dart';
import 'package:illinois/ui/home/HomeAthleticsGameDayWidget.dart';
import 'package:illinois/ui/home/HomeLoginWidget.dart';
import 'package:illinois/ui/home/HomeMyGroupsWidget.dart';
import 'package:illinois/ui/home/HomeRecentItemsWidget.dart';
import 'package:illinois/ui/home/HomeSaferWidget.dart';
import 'package:illinois/ui/home/HomeCampusHighlightsWidget.dart';
import 'package:illinois/ui/home/HomeTwitterWidget.dart';
import 'package:illinois/ui/home/HomeVoterRegistrationWidget.dart';
import 'package:illinois/ui/home/HomeSuggestedEventsWidget.dart';
import 'package:illinois/ui/widgets/FlexContent.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'HomeCheckListWidget.dart';

class HomePanel extends StatefulWidget {
  static const String notifyRefresh      = "edu.illinois.rokwire.home.refresh";

  @override
  _HomePanelState createState() => _HomePanelState();

}

class _HomePanelState extends State<HomePanel> with AutomaticKeepAliveClientMixin<HomePanel> implements NotificationsListener, HomeDragAndDropHost {
  
  Set<String>? _availableCodes;
  List<String>? _displayCodes;
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
    _availableCodes = JsonUtils.setStringsValue(FlexUI()['home']) ?? <String>{};
    _displayCodes = _buildDisplayCodes();
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
      appBar: _HomeHeaderBar(title: Localization().getStringEx('panel.home.header.title', 'ILLINOIS'), onEditDone: _isEditing ? _onEditDone : null,),
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
    widgets.addAll(_buildWidgetsFromCodes(JsonUtils.listStringsValue(FlexUI()['home.system'])));
    widgets.addAll(_buildWidgetsFromCodes(_displayCodes?.reversed, availableCodes: _availableCodes));
    return widgets;
  }

  List<Widget> _buildWidgetsFromCodes(Iterable<String>? codes, { Set<String>? availableCodes }) {
    List<Widget> widgets = [];
    if (codes != null) {
      for (String code in codes) {
        if ((availableCodes == null) || availableCodes.contains(code)) {
          Widget? widget = _buildWidgetFromCode(code);
          if (widget != null) {
            widgets.add(widget);
          }
        }
      }
    }
    return widgets;
  }

  Widget? _buildWidgetFromCode(String code, { bool handle = false, int position = 0 }) {
    if (code == 'tout') {
      return handle ? null : HomeToutWidget(favoriteId: code, updateController: _updateController, onEdit: _onEdit,);
    }
    else if (code == 'emergency') {
      return handle ? null : FlexContent.fromAssets(code, favoriteId: code, updateController: _updateController);
    }
    else if (code == 'voter_registration') {
      return handle ? null : HomeVoterRegistrationWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'connect') {
      return handle ? null : HomeLoginWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'welcome') {
      return handle? null : HomeWelcomeWidget(favoriteId: code, updateController: _updateController,); //TBD
    }

    else if (code == 'my_game_day') {
      return handle ? HomeAthleticsGameDayWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeAthleticsGameDayWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'sport_events') {
      return handle ? HomeAthliticsEventsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeAthliticsEventsWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'sport_news') {
      return handle ? HomeAthliticsNewsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeAthliticsNewsWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'sport_teams') {
      return handle ? HomeAthliticsTeamsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeAthliticsTeamsWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'campus_resources') {
      return handle ? HomeCampusResourcesWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeCampusResourcesWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'campus_reminders') {
      return handle ? HomeCampusRemindersWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeCampusRemindersWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'suggested_events') {
      return handle ? HomeSuggestedEventsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeSuggestedEventsWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'recent_items') {
      return handle ? HomeRecentItemsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeRecentItemsWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'campus_highlights') {
      return handle ? HomeCampusHighlightsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeCampusHighlightsWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'twitter') {
      return handle ? HomeTwitterWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeTwitterWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'gies_checklist') {
      return handle ? HomeCheckListWidget.handle(contentKey: 'gies', favoriteId: code, dragAndDropHost: this, position: position) : HomeCheckListWidget(contentKey: 'gies', favoriteId: code, updateController: _updateController);
    }
    else if (code == 'new_student_checklist') {
      return handle ? HomeCheckListWidget.handle(contentKey: "uiuc_student" /* TBD => "new_student" */, favoriteId: code, dragAndDropHost: this, position: position) : HomeCheckListWidget(contentKey: "uiuc_student" /* TBD => "new_student" */, favoriteId: code, updateController: _updateController);
    }
    else if (code == 'canvas_courses') {
      return handle ? HomeCanvasCoursesWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeCanvasCoursesWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'create_poll') {
      return handle ? HomeCreatePollWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeCreatePollWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'my_groups') {
      return handle ? HomeMyGroupsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeMyGroupsWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'safer') {
      return handle ? HomeSaferWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeSaferWidget(key: _saferKey, favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'wallet') {
      return handle ? HomeWalletWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeWalletWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'wpgufm_radio') {
      return handle ? HomeWPGUFMRadioWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeWPGUFMRadioWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'app_help') {
      return handle ? HomeAppHelpWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeAppHelpWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'state_farm_center') {
      return handle ? HomeStateFarmCenterWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeStateFarmCenterWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'campus_links') {
      return handle ? HomeCampusLinksWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,) : HomeCampusLinksWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'illini_news') {
      return handle ? HomeHandleWidget(title: 'Illini News', favoriteId: code, dragAndDropHost: this, position: position,) : HomeTBDWidget(title: 'Illini News', favoriteId: code, updateController: _updateController);
    }
    else if (code == 'wellness_rings') {
      return handle ? HomeHandleWidget(title: 'Wellness Rings', favoriteId: code, dragAndDropHost: this, position: position,) : HomeTBDWidget(title: 'Wellness Rings', favoriteId: code, updateController: _updateController);
    }
    else if (code == 'wellness_todo') {
      return handle ? HomeHandleWidget(title: 'Wellness To Do', favoriteId: code, dragAndDropHost: this, position: position,) : HomeTBDWidget(title: 'Wellness To Do', favoriteId: code, updateController: _updateController);
    }

    else if (code == 'my_events') {
      return handle ? HomeFavoritesWidget.handle(favoriteKey: Event.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,) : HomeFavoritesWidget(favoriteKey: Event.favoriteKeyName, favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'my_dining') {
      return handle ? HomeFavoritesWidget.handle(favoriteKey: Dining.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,) : HomeFavoritesWidget(favoriteKey: Dining.favoriteKeyName, favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'my_athletics') {
      return handle ? HomeFavoritesWidget.handle(favoriteKey: Game.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,) : HomeFavoritesWidget(favoriteKey: Game.favoriteKeyName, favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'my_news') {
      return handle ? HomeFavoritesWidget.handle(favoriteKey: News.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,) : HomeFavoritesWidget(favoriteKey: News.favoriteKeyName, favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'my_laundry') {
      return handle ? HomeFavoritesWidget.handle(favoriteKey: LaundryRoom.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,) : HomeFavoritesWidget(favoriteKey: LaundryRoom.favoriteKeyName, favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'my_inbox') {
      return handle ? HomeFavoritesWidget.handle(favoriteKey: InboxMessage.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,) : HomeFavoritesWidget(favoriteKey: InboxMessage.favoriteKeyName, favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'my_campus_guide') {
      return handle ? HomeFavoritesWidget.handle(favoriteKey: GuideFavorite.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,) : HomeFavoritesWidget(favoriteKey: GuideFavorite.favoriteKeyName, favoriteId: code, updateController: _updateController,);
    }
    else {
      return handle ? null : FlexContent.fromAssets(code, favoriteId: code, updateController: _updateController);
    }
  }

  static const String _favoritesHeaderId = 'edit.favorites';
  static const String _unfavoritesHeaderId = 'edit.unfavorites';

  List<Widget> _buildEditingContentList() {
    List<Widget> widgets = [];

    LinkedHashSet<String>? homeFavorites = Auth2().prefs?.getFavorites(HomeFavorite.favoriteKeyName());

    if (homeFavorites != null) {

      widgets.add(_buildEditingHeader(title: Localization().getStringEx('panel.home.favorites.editing.header.title', 'Favorites'), favoriteId: _favoritesHeaderId, dropAnchorAlignment: CrossAxisAlignment.end,
        description: Localization().getStringEx('panel.home.favorites.editing.header.description', 'Tap and hold an item to change its order in favorites. Touch "Done" to view your updated Favorites.'),
      ));
       
      int position = 0;
      for (String code in List<String>.from(homeFavorites).reversed) {
        if (_availableCodes?.contains(code) ?? false) {
          Widget? widget = _buildWidgetFromCode(code, handle: true, position: position);
          if (widget != null) {
            widgets.add(widget);
            position++;
          }
        }
      }
    }

    List<String>? fullContent = JsonUtils.listStringsValue(FlexUI()['home']);
    if (fullContent != null) {

      widgets.add(_buildEditingHeader(title: 'Unused Favorites', favoriteId: _unfavoritesHeaderId, dropAnchorAlignment: null,
        description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec risus sapien, tempus sed bibendum et, accumsan interdum velit. Integer bibendum feugiat lectus, eget sollicitudin enim vulputate sit amet. Pellentesque at risus odio.',
      ));

      int position = 0;
      for (String code in fullContent) {
        if (!(homeFavorites?.contains(code) ?? false)) {
          Widget? widget = _buildWidgetFromCode(code, handle: true, position: position);
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

  Widget _buildEditingHeader({String? title, String? description, String? favoriteId, CrossAxisAlignment? dropAnchorAlignment}) {
    return HomeDropTargetWidget(favoriteId: favoriteId, dragAndDropHost: this, dropAnchorAlignment: dropAnchorAlignment, childBuilder: (BuildContext context, { bool? dropTarget, CrossAxisAlignment? dropAnchorAlignment }) {
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

  void _updateAvailableCodes() {
    Set<String>? availableCodes = JsonUtils.setStringsValue(FlexUI()['home']);
    if ((availableCodes != null) && !DeepCollectionEquality().equals(_availableCodes, availableCodes) && mounted) {
      setState(() {
        _availableCodes = availableCodes;
      });
    }
  }

  List<String>? _buildDisplayCodes() {
    LinkedHashSet<String>? homeFavorites = Auth2().prefs?.getFavorites(HomeFavorite.favoriteKeyName());
    if (homeFavorites == null) {
      // Build a default set of favorites
      List<String>? fullContent = JsonUtils.listStringsValue(FlexUI().contentSourceEntry('home'));
      if (fullContent != null) {
        Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), homeFavorites = LinkedHashSet<String>.from(fullContent.reversed));
      }
    }
    return (homeFavorites != null) ? List.from(homeFavorites) : null;
  }

  void _updateDisplayCodes() {
    List<String>? displayCodes = _buildDisplayCodes();
    if ((displayCodes != null) && !DeepCollectionEquality().equals(_displayCodes, displayCodes) && mounted) {
      setState(() {
        _displayCodes = displayCodes;
      });
    }
  }

  Future<void> _onPullToRefresh() async {
    if (_isEditing) {
      //TMP:
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), null);
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: 'safer'), null);
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: 'app_help'), null);
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: 'state_farm_center'), null);
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: 'campus_links'), null);
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: 'campus_resources'), null);
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
      List<String> favoritesList = List.from(Auth2().prefs?.getFavorites(HomeFavorite.favoriteKeyName()) ?? <String>{});
      int dragIndex = favoritesList.indexOf(dragFavoriteId);
      int dropIndex = (dropFavoriteId != null) ? favoritesList.indexOf(dropFavoriteId) : -1;
      
      if ((0 <= dragIndex) && (0 <= dropIndex)) {
        // Reorder favorites
        if (dragIndex != dropIndex) {
          favoritesList.removeAt(dragIndex);
          if (dragIndex < dropIndex) {
            dropIndex--;
          }
          if (dropAnchor == CrossAxisAlignment.start) {
            dropIndex++;
          }
          favoritesList.insert(dropIndex, dragFavoriteId);
          Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), LinkedHashSet<String>.from(favoritesList));
        }
      }
      else if (0 <= dropIndex) {
        // Add favorite at specific position
        HomeFavoriteButton.promptFavorite(context, HomeFavorite(dragFavoriteId)).then((bool? result) {
          if (result == true) {
            if (dropAnchor == CrossAxisAlignment.start) {
              dropIndex++;
            }
            favoritesList.insert(dropIndex, dragFavoriteId);
            Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), LinkedHashSet<String>.from(favoritesList));
          }
        });
      }
      else if (dropFavoriteId == _favoritesHeaderId) {
        if (0 <= dragIndex) {
          // move drag favorite at 
          favoritesList.removeAt(dragIndex);
          favoritesList.insert(favoritesList.length, dragFavoriteId);
          Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), LinkedHashSet<String>.from(favoritesList));
        }
        else {
          // add favorite
          HomeFavoriteButton.promptFavorite(context, HomeFavorite(dragFavoriteId)).then((bool? result) {
            if (result == true) {
              Auth2().prefs?.toggleFavorite(HomeFavorite(dragFavoriteId));
            }
          });
        }
      }
      else if (dropFavoriteId == _unfavoritesHeaderId) {
        if (0 <= dragIndex) {
          if (dropAnchor == CrossAxisAlignment.start) {
            // move drag favorite at 
            favoritesList.removeAt(dragIndex);
            favoritesList.insert(0, dragFavoriteId);
            Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), LinkedHashSet<String>.from(favoritesList));
          }
          else {
            // remove favorite
            HomeFavoriteButton.promptFavorite(context, HomeFavorite(dragFavoriteId)).then((bool? result) {
              if (result == true) {
                Auth2().prefs?.toggleFavorite(HomeFavorite(dragFavoriteId));
              }
            });
          }
        }
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
    if (mounted) {
      setState(() {
        _isEditing = true;
      });
    }
  }

  void _onEditDone() {
    if (mounted) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _updateAvailableCodes();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _updateDisplayCodes();
    }
    else if (name == HomeSaferWidget.notifyNeedsVisiblity) {
      _ensureSaferWidgetVisibiity();
    }
    else if (((name == AppLivecycle.notifyStateChanged) && (param == AppLifecycleState.resumed)) ||
        (name == Localization.notifyStringsUpdated) ||
        (name == Styles.notifyChanged) ||
        (name == Assets.notifyChanged) ||
        (name == Storage.offsetDateKey) ||
        (name == Storage.useDeviceLocalTimeZoneKey))
    {
      if (mounted) {
        setState(() {});
      }
    }
  }
}

// _HomeHeaderBar

class _HomeHeaderBar extends RootHeaderBar {

  final void Function()? onEditDone;
  
  _HomeHeaderBar({Key? key, String? title, this.onEditDone}) :
    super(key: key, title: title);

  bool get editing => (onEditDone != null);

  @override
  List<Widget> buildHeaderActions(BuildContext context) {
    return editing ? <Widget>[ buildHeaderEditDoneButton(context), ] : super.buildHeaderActions(context);
  }

  Widget buildHeaderEditDoneButton(BuildContext context) {
    return Semantics(label: Localization().getStringEx('headerbar.done.title', 'Done'), hint: Localization().getStringEx('headerbar.done.hint', ''), button: true, excludeSemantics: true, child:
      TextButton(onPressed: () => onTapEditDone(context), child:
        Text(Localization().getStringEx('headerbar.done.title', 'Done'), style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies!.medium),)
      )
    );
  }

  void onTapEditDone(BuildContext context) {
    if (onEditDone != null) {
      onEditDone!();
    }
  }
}

// HomeDragAndDropHost

abstract class HomeDragAndDropHost  {
  set isDragging(bool value);
  void onDragAndDrop({String? dragFavoriteId, String? dropFavoriteId, CrossAxisAlignment? dropAnchor});
}

// HomeFavorite

class HomeFavorite implements Favorite {
  final String? id;
  final String? category;
  HomeFavorite(this.id, {this.category});

  bool operator == (o) => o is HomeFavorite && o.id == id && o.category == category;
  int get hashCode => (id?.hashCode ?? 0) ^ (category?.hashCode ?? 0);

  static String favoriteKeyName({String? category}) => (category != null) ? "home.$category.widgetIds" : "home.widgetIds";
  @override String get favoriteKey => favoriteKeyName(category: category);
  @override String? get favoriteId => id;
}

