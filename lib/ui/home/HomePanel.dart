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
import 'package:illinois/ui/home/HomeCampusGuideWidget.dart';
import 'package:illinois/ui/home/HomeCampusLinksWidget.dart';
import 'package:illinois/ui/home/HomeCanvasCoursesWidget.dart';
import 'package:illinois/ui/home/HomeCheckListWidget.dart';
import 'package:illinois/ui/home/HomeDiningWidget.dart';
import 'package:illinois/ui/home/HomeFavoritesWidget.dart';
import 'package:illinois/ui/home/HomeRecentPollsWidget.dart';
import 'package:illinois/ui/home/HomeStateFarmCenterWidget.dart';
import 'package:illinois/ui/home/HomeToutWidget.dart';
import 'package:illinois/ui/home/HomeWPGUFMRadioWidget.dart';
import 'package:illinois/ui/home/HomeWalletWidget.dart';
import 'package:illinois/ui/home/HomeWelcomeWidget.dart';
import 'package:illinois/ui/home/HomeWellnessResourcesWidget.dart';
import 'package:illinois/ui/home/HomeWellnessWidget.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/home/HomeCampusRemindersWidget.dart';
import 'package:illinois/ui/home/HomeCampusResourcesWidget.dart';
import 'package:illinois/ui/home/HomeCreatePollWidget.dart';
import 'package:illinois/ui/home/HomeAthleticsGameDayWidget.dart';
import 'package:illinois/ui/home/HomeLoginWidget.dart';
import 'package:illinois/ui/home/HomeGroupsWidget.dart';
import 'package:illinois/ui/home/HomeRecentItemsWidget.dart';
import 'package:illinois/ui/home/HomeSaferWidget.dart';
import 'package:illinois/ui/home/HomeCampusHighlightsWidget.dart';
import 'package:illinois/ui/home/HomeTwitterWidget.dart';
import 'package:illinois/ui/home/HomeVoterRegistrationWidget.dart';
import 'package:illinois/ui/home/HomeSuggestedEventsWidget.dart';
import 'package:illinois/ui/widgets/FlexContent.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

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

    String title = _isEditing ?
      Localization().getStringEx('panel.home.header.editing.title', 'Customize') :
      Localization().getStringEx('panel.home.header.title', 'Favorites');

    return Scaffold(
      appBar: _HomeHeaderBar(title: title, onEditDone: _isEditing ? _onEditDone : null,),
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
          dynamic widget = _dataFromCode(code);
          if (widget is Widget) {
            widgets.add(widget);
          }
        }
      }
    }
    return widgets;
  }

  dynamic _dataFromCode(String code, { bool title = false, bool handle = false, int position = 0 }) {
    if (code == 'tout') {
      return (title || handle) ? null : HomeToutWidget(favoriteId: code, updateController: _updateController, onEdit: _onEdit,);
    }
    else if (code == 'emergency') {
      return (title || handle) ? null : FlexContent.fromAssets(code, favoriteId: code, updateController: _updateController);
    }
    else if (code == 'voter_registration') {
      return (title || handle) ? null : HomeVoterRegistrationWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'connect') {
      return (title || handle) ? null : HomeLoginWidget(favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'welcome') {
      return (title || handle) ? null : HomeWelcomeWidget(favoriteId: code, updateController: _updateController,); //TBD
    }

    else if (code == 'my_game_day') {
      if (title) {
        return HomeAthleticsGameDayWidget.title;
      } else if (handle) {
        return HomeAthleticsGameDayWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeAthleticsGameDayWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'sport_events') {
      if (title) {
        return HomeAthliticsEventsWidget.title;
      } else if (handle) {
        return HomeAthliticsEventsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeAthliticsEventsWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'sport_news') {
      if (title) {
        return HomeAthliticsNewsWidget.title;
      } else if (handle) {
        return HomeAthliticsNewsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeAthliticsNewsWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'sport_teams') {
      if (title) {
        return HomeAthliticsTeamsWidget.title;
      } else if (handle) {
        return HomeAthliticsTeamsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeAthliticsTeamsWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'campus_resources') {
      if (title) {
        return HomeCampusResourcesWidget.title;
      } else if (handle) {
        return HomeCampusResourcesWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeCampusResourcesWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'campus_reminders') {
      if (title) {
        return HomeCampusRemindersWidget.title;
      } else if (handle) {
        return HomeCampusRemindersWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeCampusRemindersWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'campus_guide') {
      if (title) {
        return HomeCampusGuideWidget.title;
      } else if (handle) {
        return HomeCampusGuideWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeCampusGuideWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'suggested_events') {
      if (title) {
        return HomeSuggestedEventsWidget.title;
      } else if (handle) {
        return HomeSuggestedEventsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeSuggestedEventsWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'recent_items') {
      if (title) {
        return HomeRecentItemsWidget.title;
      } else if (handle) {
        return HomeRecentItemsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeRecentItemsWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'campus_highlights') {
      if (title) {
        return HomeCampusHighlightsWidget.title;
      } else if (handle) {
        return HomeCampusHighlightsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeCampusHighlightsWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'twitter') {
      if (title) {
        return HomeTwitterWidget.title;
      } else if (handle) {
        return HomeTwitterWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeTwitterWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'gies_checklist') {
      if (title) {
        return HomeCheckListWidget.title(contentKey: 'gies');
      } else if (handle) {
        return HomeCheckListWidget.handle(contentKey: 'gies', favoriteId: code, dragAndDropHost: this, position: position);
      } else {
        return HomeCheckListWidget(contentKey: 'gies', favoriteId: code, updateController: _updateController);
      }
    }
    else if (code == 'new_student_checklist') {
      if (title) {
        return HomeCheckListWidget.title(contentKey: "new_student");
      } else if (handle) {
        return HomeCheckListWidget.handle(contentKey: "new_student", favoriteId: code, dragAndDropHost: this, position: position);
      } else {
        return HomeCheckListWidget(contentKey: "new_student", favoriteId: code, updateController: _updateController);
      }
    }
    else if (code == 'canvas_courses') {
      if (title) {
        return HomeCanvasCoursesWidget.title;
      } else if (handle) {
        return HomeCanvasCoursesWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeCanvasCoursesWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'create_poll') {
      if (title) {
        return HomeCreatePollWidget.title;
      } else if (handle) {
        return HomeCreatePollWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeCreatePollWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'recent_polls') {
      if (title) {
        return HomeRecentPollsWidget.title;
      } else if (handle) {
        return HomeRecentPollsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeRecentPollsWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'my_groups') {
      if (title) {
        return HomeMyGroupsWidget.title(contentType: GroupsContentType.my);
      } else if (handle) {
        return HomeMyGroupsWidget.handle(contentType: GroupsContentType.my, favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeMyGroupsWidget(contentType: GroupsContentType.my, favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'all_groups') {
      if (title) {
        return HomeMyGroupsWidget.titleForContentType(GroupsContentType.all);
      } else if (handle) {
        return HomeMyGroupsWidget.handle(contentType: GroupsContentType.all, favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeMyGroupsWidget(contentType: GroupsContentType.all, favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'safer') {
      if (title) {
        return HomeSaferWidget.title;
      } else if (handle) {
        return HomeSaferWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeSaferWidget(key: _saferKey, favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'dinings') {
      if (title) {
        return HomeDiningWidget.title;
      } else if (handle) {
        return HomeDiningWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeDiningWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'wallet') {
      if (title) {
        return HomeWalletWidget.title;
      } else if (handle) {
        return HomeWalletWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeWalletWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'wpgufm_radio') {
      if (title) {
        return HomeWPGUFMRadioWidget.title;
      } else if (handle) {
        return HomeWPGUFMRadioWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeWPGUFMRadioWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'app_help') {
      if (title) {
        return HomeAppHelpWidget.title;
      } else if (handle) {
        return HomeAppHelpWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeAppHelpWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'state_farm_center') {
      if (title) {
        return HomeStateFarmCenterWidget.title;
      } else if (handle) {
        return HomeStateFarmCenterWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeStateFarmCenterWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'campus_links') {
      if (title) {
        return HomeCampusLinksWidget.title;
      } else if (handle) {
        return HomeCampusLinksWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeCampusLinksWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'wellness') {
      if (title) {
        return HomeWellnessWidget.title;
      } else if (handle) {
        return HomeWellnessWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeWellnessWidget(favoriteId: code, updateController: _updateController,);
      }
    }

    else if (code == 'my_events') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: Event.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(favoriteKey: Event.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeFavoritesWidget(favoriteKey: Event.favoriteKeyName, favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'my_dining') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: Dining.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(favoriteKey: Dining.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeFavoritesWidget(favoriteKey: Dining.favoriteKeyName, favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'my_athletics') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: Game.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(favoriteKey: Game.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeFavoritesWidget(favoriteKey: Game.favoriteKeyName, favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'my_news') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: News.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(favoriteKey: News.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeFavoritesWidget(favoriteKey: News.favoriteKeyName, favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'my_laundry') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: LaundryRoom.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(favoriteKey: LaundryRoom.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeFavoritesWidget(favoriteKey: LaundryRoom.favoriteKeyName, favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'my_inbox') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: InboxMessage.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(favoriteKey: InboxMessage.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeFavoritesWidget(favoriteKey: InboxMessage.favoriteKeyName, favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'my_campus_guide') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: GuideFavorite.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(favoriteKey: GuideFavorite.favoriteKeyName, favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeFavoritesWidget(favoriteKey: GuideFavorite.favoriteKeyName, favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'wellness_resources') {
      if (title) {
        return HomeWellnessResourcesWidget.title;
      } else if (handle) {
        return HomeWellnessResourcesWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeWellnessResourcesWidget(favoriteId: code, updateController: _updateController,);
      }
    }
    else {
      return (handle || title) ? null : FlexContent.fromAssets(code, favoriteId: code, updateController: _updateController);
    }
  }

  static const String _favoritesHeaderId = 'edit.favorites';
  static const String _unfavoritesHeaderId = 'edit.unfavorites';

  List<Widget> _buildEditingContentList() {
    List<Widget> widgets = [];

    LinkedHashSet<String>? homeFavorites = Auth2().prefs?.getFavorites(HomeFavorite.favoriteKeyName());

    if (homeFavorites != null) {

      widgets.add(_buildEditingHeader(
        favoriteId: _favoritesHeaderId, dropAnchorAlignment: CrossAxisAlignment.end,
        title: Localization().getStringEx('panel.home.edit.favorites.header.title', 'Your Favorites'),
        description: Localization().getStringEx('panel.home.edit.favorites.header.description', 'Below is the content currently on your favorites screen. To reorder your favorites, tap, hold, and drag an item. To remove an item from your favorites, click on the star.'),
      ));
       
      int position = 0;
      for (String code in List<String>.from(homeFavorites).reversed) {
        if (_availableCodes?.contains(code) ?? false) {
          dynamic widget = _dataFromCode(code, handle: true, position: position);
          if (widget is Widget) {
            widgets.add(widget);
            position++;
          }
        }
      }
    }

    List<String>? fullContent = JsonUtils.listStringsValue(FlexUI()['home']);
    if (fullContent != null) {

      widgets.add(_buildEditingHeader(
        favoriteId: _unfavoritesHeaderId, dropAnchorAlignment: null,
        title: Localization().getStringEx('panel.home.edit.unused.header.title', 'Unused Favorites'),
        description: Localization().getStringEx('panel.home.edit.unused.header.description', 'To add one of the below items to your favorites, click on the star.'),
      ));

      List<Map<String, dynamic>> unusedList = <Map<String, dynamic>>[];

      for (String code in fullContent) {
        if (!(homeFavorites?.contains(code) ?? false)) {
          dynamic title = _dataFromCode(code, title: true);
          if (title is String) {
            unusedList.add({'title' : title, 'code': code});
          }
        }
      }
      
      unusedList.sort((Map<String, dynamic> entry1, Map<String, dynamic> entry2) {
        String title1 = JsonUtils.stringValue(entry1['title'])?.toLowerCase() ?? '';
        String title2 = JsonUtils.stringValue(entry2['title'])?.toLowerCase() ?? '';
        return title1.compareTo(title2);
      });

      int position = 0;
      for (Map<String, dynamic> entry in unusedList) {
        String? code = JsonUtils.stringValue(entry['code']);
        dynamic widget = (code != null) ? _dataFromCode(code, handle: true, position: position) : null;
          if (widget is Widget) {
            widgets.add(widget);
            position++;
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
        homeFavorites = LinkedHashSet<String>.from(fullContent.reversed);
        Future.delayed(Duration(), () {
          Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), homeFavorites);
        });
      }
    }
    return (homeFavorites != null) ? List.from(homeFavorites) : null;
  }

  void _updateDisplayCodes() {
    if (mounted) {
      List<String>? displayCodes = _buildDisplayCodes();
      if (_isEditing) {
        if (displayCodes != null) {
          _displayCodes = displayCodes;
        }
        setState(() {});
      }
      else {
        if ((displayCodes != null) && !DeepCollectionEquality().equals(_displayCodes, displayCodes)) {
          setState(() {
            _displayCodes = displayCodes;
          });
        }
      }
    }
  }

  Future<void> _onPullToRefresh() async {
    if (_isEditing) {
      //TMP:
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), null);
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: 'app_help'), null);
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: 'dinings'), null);
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: 'safer'), null);
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: 'campus_resources'), null);
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: 'state_farm_center'), null);
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: 'campus_links'), null);
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: 'wallet'), null);
      Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: 'wellness'), null);
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
        if (dropAnchor == CrossAxisAlignment.start) {
          // move or add drag favorite
          if (0 <= dragIndex) {
            favoritesList.removeAt(dragIndex);
          }
          favoritesList.insert(0, dragFavoriteId);
          Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), LinkedHashSet<String>.from(favoritesList));
        }
        else {
          if (0 <= dragIndex) {
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
    return Semantics(label: Localization().getStringEx('headerbar.save.title', 'Save'), hint: Localization().getStringEx('headerbar.save.hint', ''), button: true, excludeSemantics: true, child:
      TextButton(onPressed: () => onTapEditDone(context), child:
        Text(Localization().getStringEx('headerbar.save.title', 'Save'), style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies!.medium),)
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

