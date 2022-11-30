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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/CheckList.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/home/HomeAppHelpWidget.dart';
import 'package:illinois/ui/home/HomeAppointmentsWidget.dart';
import 'package:illinois/ui/home/HomeAthleticsEventsWidget.dart';
import 'package:illinois/ui/home/HomeAthleticsNewsWidget.dart';
import 'package:illinois/ui/home/HomeCanvasCoursesWidget.dart';
import 'package:illinois/ui/home/HomeCheckListWidget.dart';
import 'package:illinois/ui/home/HomeDailyIlliniWidget.dart';
import 'package:illinois/ui/home/HomeDiningWidget.dart';
import 'package:illinois/ui/home/HomeFavoritesWidget.dart';
import 'package:illinois/ui/home/HomeInboxWidget.dart';
import 'package:illinois/ui/home/HomeLaundryWidget.dart';
import 'package:illinois/ui/home/HomeRecentPollsWidget.dart';
import 'package:illinois/ui/home/HomeResearchProjectsWidget.dart';
import 'package:illinois/ui/home/HomeStateFarmCenterWidget.dart';
import 'package:illinois/ui/home/HomeStudentCoursesWidget.dart';
import 'package:illinois/ui/home/HomeToutWidget.dart';
import 'package:illinois/ui/home/HomeVideoTutorialsWidget.dart';
import 'package:illinois/ui/home/HomeWPGUFMRadioWidget.dart';
import 'package:illinois/ui/home/HomeWalletWidget.dart';
import 'package:illinois/ui/home/HomeWelcomeWidget.dart';
import 'package:illinois/ui/home/HomeWellnessToDoWidget.dart';
import 'package:illinois/ui/home/HomeWellnessRingsWidget.dart';
import 'package:illinois/ui/home/HomeWellnessTipsWidget.dart';
import 'package:illinois/ui/home/HomeWellnessResourcesWidget.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/config.dart';
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
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePanel extends StatefulWidget {
  static const String notifyRefresh      = "edu.illinois.rokwire.home.refresh";
  static const String notifyCustomize    = "edu.illinois.rokwire.home.customize";

  @override
  _HomePanelState createState() => _HomePanelState();

}

class _HomePanelState extends State<HomePanel> with AutomaticKeepAliveClientMixin<HomePanel> implements NotificationsListener, HomeDragAndDropHost {
  
  List<String>? _favoriteCodes;
  Set<String>? _availableCodes;
  StreamController<String> _updateController = StreamController.broadcast();
  Map<String, GlobalKey> _widgetKeys = <String, GlobalKey>{};
  Map<String, GlobalKey> _handleKeys = <String, GlobalKey>{};
  GlobalKey _contentWrapperKey = GlobalKey();
  ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  bool _isDragging = false;
  bool _isEditing = false;

  @override
  void initState() {

    // Build Favorite codes before start listening for Auth2UserPrefs.notifyFavoritesChanged
    // because _buildFavoriteCodes may fire such.
    _favoriteCodes = _buildFavoriteCodes();
    _availableCodes = JsonUtils.setStringsValue(FlexUI()['home']) ?? <String>{};

    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Localization.notifyStringsUpdated,
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged,
      Styles.notifyChanged,
      Assets.notifyChanged,
      HomeSaferWidget.notifyNeedsVisiblity,
      HomePanel.notifyCustomize,
    ]);
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
    widgets.addAll(_buildWidgetsFromCodes(_favoriteCodes?.reversed, availableCodes: _availableCodes));
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
      return (title || handle) ? null : HomeToutWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController, onEdit: _onEdit,);
    }
    else if (code == 'emergency') {
      return (title || handle) ? null : FlexContent.fromAssets(code, key: _widgetKey(code), favoriteId: code, updateController: _updateController);
    }
    else if (code == 'voter_registration') {
      return (title || handle) ? null : HomeVoterRegistrationWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'connect') {
      return (title || handle) ? null : HomeLoginWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'welcome') {
      return (title || handle) ? null : HomeWelcomeWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,); //TBD
    }

    else if (code == 'my_game_day') {
      if (title) {
        return HomeAthleticsGameDayWidget.title;
      } else if (handle) {
        return HomeAthleticsGameDayWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeAthleticsGameDayWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'sport_events') {
      if (title) {
        return HomeAthliticsEventsWidget.title;
      } else if (handle) {
        return HomeAthliticsEventsWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeAthliticsEventsWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'sport_news') {
      if (title) {
        return HomeAthliticsNewsWidget.title;
      } else if (handle) {
        return HomeAthliticsNewsWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeAthliticsNewsWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'campus_resources') {
      if (title) {
        return HomeCampusResourcesWidget.title;
      } else if (handle) {
        return HomeCampusResourcesWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeCampusResourcesWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'campus_reminders') {
      if (title) {
        return HomeCampusRemindersWidget.title;
      } else if (handle) {
        return HomeCampusRemindersWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeCampusRemindersWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'suggested_events') {
      if (title) {
        return HomeSuggestedEventsWidget.title;
      } else if (handle) {
        return HomeSuggestedEventsWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeSuggestedEventsWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'recent_items') {
      if (title) {
        return HomeRecentItemsWidget.title;
      } else if (handle) {
        return HomeRecentItemsWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeRecentItemsWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'campus_highlights') {
      if (title) {
        return HomeCampusHighlightsWidget.title;
      } else if (handle) {
        return HomeCampusHighlightsWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeCampusHighlightsWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'twitter') {
      if (title) {
        return HomeTwitterWidget.title;
      } else if (handle) {
        return HomeTwitterWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeTwitterWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'daily_illini') {
      if (title) {
        return HomeDailyIlliniWidget.title;
      } else if (handle) {
        return HomeDailyIlliniWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeDailyIlliniWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'gies_checklist') {
      if (title) {
        return HomeCheckListWidget.title(contentKey: CheckList.giesOnboarding);
      } else if (handle) {
        return HomeCheckListWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position, contentKey: CheckList.giesOnboarding);
      } else {
        return HomeCheckListWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController, contentKey: CheckList.giesOnboarding, );
      }
    }
    else if (code == 'new_student_checklist') {
      if (title) {
        return HomeCheckListWidget.title(contentKey: CheckList.uiucOnboarding);
      } else if (handle) {
        return HomeCheckListWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position, contentKey: CheckList.uiucOnboarding);
      } else {
        return HomeCheckListWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController, contentKey: CheckList.uiucOnboarding, );
      }
    }
    else if (code == 'canvas_courses') {
      if (title) {
        return HomeCanvasCoursesWidget.title;
      } else if (handle) {
        return HomeCanvasCoursesWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeCanvasCoursesWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'student_courses') {
      if (title) {
        return HomeStudentCoursesWidget.title;
      } else if (handle) {
        return HomeStudentCoursesWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeStudentCoursesWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'create_poll') {
      if (title) {
        return HomeCreatePollWidget.title;
      } else if (handle) {
        return HomeCreatePollWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeCreatePollWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'recent_polls') {
      if (title) {
        return HomeRecentPollsWidget.title;
      } else if (handle) {
        return HomeRecentPollsWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeRecentPollsWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'laundry') {
      if (title) {
        return HomeLaundryWidget.title;
      } else if (handle) {
        return HomeLaundryWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeLaundryWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'my_groups') {
      if (title) {
        return HomeGroupsWidget.title(contentType: GroupsContentType.my);
      } else if (handle) {
        return HomeGroupsWidget.handle(contentType: GroupsContentType.my, favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeGroupsWidget(key: _widgetKey(code), contentType: GroupsContentType.my, favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'all_groups') {
      if (title) {
        return HomeGroupsWidget.titleForContentType(GroupsContentType.all);
      } else if (handle) {
        return HomeGroupsWidget.handle(contentType: GroupsContentType.all, favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeGroupsWidget(key: _widgetKey(code), contentType: GroupsContentType.all, favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'my_research_projects') {
      if (title) {
        return HomeResearchProjectsWidget.title(contentType: ResearchProjectsContentType.my);
      } else if (handle) {
        return HomeResearchProjectsWidget.handle(contentType: ResearchProjectsContentType.my, favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeResearchProjectsWidget(key: _widgetKey(code), contentType: ResearchProjectsContentType.my, favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'open_research_projects') {
      if (title) {
        return HomeResearchProjectsWidget.titleForContentType(ResearchProjectsContentType.open);
      } else if (handle) {
        return HomeResearchProjectsWidget.handle(contentType: ResearchProjectsContentType.open, favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeResearchProjectsWidget(key: _widgetKey(code), contentType: ResearchProjectsContentType.open, favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'my_appointments') {
      if (title) {
        return HomeAppointmentsWidget.title;
      } else if (handle) {
        return HomeAppointmentsWidget.handle(favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeAppointmentsWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'my_mtd_stops') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: MTDStop.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position, favoriteKey: MTDStop.favoriteKeyName, );
      } else {
        return HomeFavoritesWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController, favoriteKey: MTDStop.favoriteKeyName);
      }
    }
    else if (code == 'safer') {
      if (title) {
        return HomeSaferWidget.title;
      } else if (handle) {
        return HomeSaferWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeSaferWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'dinings') {
      if (title) {
        return HomeDiningWidget.title;
      } else if (handle) {
        return HomeDiningWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeDiningWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'wallet') {
      if (title) {
        return HomeWalletWidget.title;
      } else if (handle) {
        return HomeWalletWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeWalletWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'wpgufm_radio') {
      if (title) {
        return HomeWPGUFMRadioWidget.title;
      } else if (handle) {
        return HomeWPGUFMRadioWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeWPGUFMRadioWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'all_notifications') {
      if (title) {
        return HomeInboxWidget.title(content: HomeInboxContent.all);
      } else if (handle) {
        return HomeInboxWidget.handle(key: _handleKey(code), content: HomeInboxContent.all, favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeInboxWidget(key: _widgetKey(code), content: HomeInboxContent.all, favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'unread_notifications') {
      if (title) {
        return HomeInboxWidget.title(content: HomeInboxContent.unread);
      } else if (handle) {
        return HomeInboxWidget.handle(key: _handleKey(code), content: HomeInboxContent.unread, favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeInboxWidget(key: _widgetKey(code), content: HomeInboxContent.unread, favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'app_help') {
      if (title) {
        return HomeAppHelpWidget.title;
      } else if (handle) {
        return HomeAppHelpWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeAppHelpWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'video_tutorials') {
      if (title) {
        return HomeVideoTutorialsWidget.title;
      } else if (handle) {
        return HomeVideoTutorialsWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeVideoTutorialsWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'state_farm_center') {
      if (title) {
        return HomeStateFarmCenterWidget.title;
      } else if (handle) {
        return HomeStateFarmCenterWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeStateFarmCenterWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }

    else if (code == 'my_events') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: Event.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,favoriteKey: Event.favoriteKeyName, );
      } else {
        return HomeFavoritesWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController, favoriteKey: Event.favoriteKeyName);
      }
    }
    else if (code == 'my_dining') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: Dining.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position, favoriteKey: Dining.favoriteKeyName, );
      } else {
        return HomeFavoritesWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController, favoriteKey: Dining.favoriteKeyName,);
      }
    }
    else if (code == 'my_athletics') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: Game.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position, favoriteKey: Game.favoriteKeyName);
      } else {
        return HomeFavoritesWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController, favoriteKey: Game.favoriteKeyName,);
      }
    }
    else if (code == 'my_news') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: News.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position, favoriteKey: News.favoriteKeyName,);
      } else {
        return HomeFavoritesWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController, favoriteKey: News.favoriteKeyName, );
      }
    }
    else if (code == 'my_laundry') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: LaundryRoom.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position, favoriteKey: LaundryRoom.favoriteKeyName);
      } else {
        return HomeFavoritesWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController, favoriteKey: LaundryRoom.favoriteKeyName, );
      }
    }
    else if (code == 'my_campus_guide') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: GuideFavorite.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position, favoriteKey: GuideFavorite.favoriteKeyName, );
      } else {
        return HomeFavoritesWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController, favoriteKey: GuideFavorite.favoriteKeyName, );
      }
    }
    
    else if (code == 'wellness_resources') {
      if (title) {
        return HomeWellnessResourcesWidget.title;
      } else if (handle) {
        return HomeWellnessResourcesWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeWellnessResourcesWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'wellness_todo') {
      if (title) {
        return HomeWellnessToDoWidget.title;
      } else if (handle) {
        return HomeWellnessToDoWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeWellnessToDoWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'wellness_rings') {
      if (title) {
        return HomeWellnessRingsWidget.title;
      } else if (handle) {
        return HomeWellnessRingsWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeWellnessRingsWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else if (code == 'wellness_tips') {
      if (title) {
        return HomeWellnessTipsWidget.title;
      } else if (handle) {
        return HomeWellnessTipsWidget.handle(key: _handleKey(code), favoriteId: code, dragAndDropHost: this, position: position,);
      } else {
        return HomeWellnessTipsWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
      }
    }
    else {
      return (handle || title) ? null : FlexContent.fromAssets(code, key: _widgetKey(code), favoriteId: code, updateController: _updateController);
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
        title: Localization().getStringEx('panel.home.edit.favorites.header.title', 'Current Favorites'),
        linkButtonTitle: Localization().getStringEx('panel.home.edit.favorites.unstar.link.button', 'Unstar All'),
        onTapLinkButton: CollectionUtils.isNotEmpty(homeFavorites) ? () => _onTapUnstarAll(homeFavorites.toList()) : null,
        description: Localization().getStringEx('panel.home.edit.favorites.header.description', 'Tap, <b>hold</b>, and drag an item to reorder your favorites. To remove an item from Favorites, tap the star.'),
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


      widgets.add(_buildEditingHeader(
        favoriteId: _unfavoritesHeaderId, dropAnchorAlignment: null,
        title: Localization().getStringEx('panel.home.edit.unused.header.title', 'Other Items to Favorite'),
        linkButtonTitle: Localization().getStringEx('panel.home.edit.unused.star.link.button', 'Star All'),
        onTapLinkButton: CollectionUtils.isNotEmpty(unusedList) ? () => _onTapStarAll(unusedList) : null,
        description: Localization().getStringEx('panel.home.edit.unused.header.description', 'Tap the star to add any below items to Favorites.'),
      ));

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

  Widget _buildEditingHeader({String? title, String? description, String? linkButtonTitle, void Function()? onTapLinkButton, String? favoriteId, CrossAxisAlignment? dropAnchorAlignment}) {
    return HomeDropTargetWidget(favoriteId: favoriteId, dragAndDropHost: this, dropAnchorAlignment: dropAnchorAlignment, childBuilder: (BuildContext context, { bool? dropTarget, CrossAxisAlignment? dropAnchorAlignment }) {
      return Column(children: [
          Container(height: 2, color: ((dropTarget == true) && (dropAnchorAlignment == CrossAxisAlignment.start)) ? Styles().colors?.fillColorSecondary : Colors.transparent,),
          Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
              Text(title ?? '', style: TextStyle(color: Styles().colors?.fillColorPrimary, fontSize: 22, fontFamily: Styles().fontFamilies?.extraBold),),
            ),
            Expanded(child: Container()),
            Visibility(visible: (onTapLinkButton != null), child: InkWell(onTap: onTapLinkButton, child: 
              Padding(padding: EdgeInsets.only(left: 5, top: 5, bottom: 5, right: 16), child: Text(StringUtils.ensureNotEmpty(linkButtonTitle), style: 
                TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.accentColor3, 
                  decoration: TextDecoration.underline, decorationStyle: TextDecorationStyle.solid, decorationThickness: 1, decorationColor: Styles().colors!.accentColor3),
              ))
            ))
          ],)),
          Row(children: [
            Expanded(child:
              Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
                Html(data: StringUtils.ensureNotEmpty(description),
                  onLinkTap: (url, context, attributes, element) => _onTapHtmlLink(url),
                  style: { 
                    "body": Style(color: Styles().colors!.textColorPrimaryVariant, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(16), textAlign: TextAlign.left, padding: EdgeInsets.zero, margin: EdgeInsets.zero),
                    "b": Style(fontFamily: Styles().fontFamilies!.bold)
                  })
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

  List<String>? _buildFavoriteCodes() {
    LinkedHashSet<String>? homeFavorites = Auth2().prefs?.getFavorites(HomeFavorite.favoriteKeyName());
    if (homeFavorites == null) {
      homeFavorites = _initDefaultFavorites();
    }
    return (homeFavorites != null) ? List.from(homeFavorites) : null;
  }

  void _updateFavoriteCodes() {
    if (mounted) {
      List<String>? favoriteCodes = _buildFavoriteCodes();
      if ((favoriteCodes != null) && !DeepCollectionEquality().equals(_favoriteCodes, favoriteCodes)) {
        setState(() {
          _favoriteCodes = favoriteCodes;
        });
      }
    }
  }

  static LinkedHashSet<String>? _initDefaultFavorites() {
    Map<String, dynamic>? defaults = FlexUI().content('defaults.favorites');
    if (defaults != null) {
      List<String>? defaultContent = JsonUtils.listStringsValue(defaults['home']);
      if (defaultContent != null) {

        // Init content of all compound widgets that bellongs to home favorites content
        for (String code in defaultContent) {
          List<String>? defaultWidgetContent = JsonUtils.listStringsValue(defaults['home.$code']);
          if (defaultWidgetContent != null) {
            Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: code),
              LinkedHashSet<String>.from(defaultWidgetContent.reversed));
          }
        }

        // Clear content of all compound widgets that do not bellongs to home favorites content
        Iterable<String>? favoriteKeys = Auth2().prefs?.favoritesKeys;
        if (favoriteKeys != null) {
          for (String favoriteKey in List.from(favoriteKeys)) {
            String? code = HomeFavorite.parseFavoriteKeyCategory(favoriteKey);
            if ((code != null) && !defaultContent.contains(code)) {
              Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: code), null);
            }
          }
        }

        // Init content of home favorites
        LinkedHashSet<String>? defaultFavorites = LinkedHashSet<String>.from(defaultContent.reversed);
        Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), defaultFavorites);
        return defaultFavorites;
      }
    }
    return null;
  }

  Future<void> _onPullToRefresh() async {
    if (_isEditing) {
      if (kDebugMode || (Config().configEnvironment == ConfigEnvironment.dev)) {
        _initDefaultFavorites();
      }
      else {
        setStateIfMounted((){});
      }
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

  void _onTapHtmlLink(String? url) {
    if (StringUtils.isNotEmpty(url)) {
      Uri? uri = Uri.tryParse(url!);
      if (uri != null) {
        launchUrl(uri);
      }
    }
  }

  void _onTapUnstarAll(List<String>? favorites) {
    Analytics().logSelect(source: 'Customize', target: 'Unstar All');
    _showUnstarConfirmationDialog(favorites);
  }

  void _showUnstarConfirmationDialog(List<String>? favorites) {
    AppAlert.showCustomDialog(
        context: context,
        contentPadding: EdgeInsets.all(0),
        contentWidget: Container(
            height: 250,
            decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: BorderRadius.circular(15.0)),
            child: Stack(alignment: Alignment.center, fit: StackFit.loose, children: [
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                            Localization().getStringEx('panel.home.edit.favorites.confirmation.dialog.msg',
                                'Are you sure you want to REMOVE all items from your favorites? Items can always be added back later.'),
                            textAlign: TextAlign.center,
                            style:  Styles().textStyles?.getTextStyle("widget.detail.small"))),
                    Padding(padding: EdgeInsets.only(top: 40), child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Expanded(child: RoundedButton(label: Localization().getStringEx('dialog.no.title', 'No'), borderColor: Styles().colors!.fillColorPrimary, onTap: _dismissUnstarConfirmationDialog)),
                      Container(width: 16),
                      Expanded(child: RoundedButton(label: Localization().getStringEx('dialog.yes.title', 'Yes'), borderColor: Styles().colors!.fillColorSecondary, onTap: () {
                        _dismissUnstarConfirmationDialog();
                        _unstarAvailableFavorites(favorites);
                      } ))
                    ]))
                  ])),
              Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                      onTap: _dismissUnstarConfirmationDialog,
                      child: Padding(padding: EdgeInsets.all(16), child: Image.asset('images/icon-x-orange.png', color: Colors.black))))
            ])));
  }

  void _dismissUnstarConfirmationDialog() {
    Navigator.of(context).pop();
  }

  void _unstarAvailableFavorites(List<String>? favorites) {
    if (CollectionUtils.isNotEmpty(favorites)) {
      for (String code in favorites!) {
        _setFavorite(code: code, value: false);
      }
    }
  }

  void _onTapStarAll(List<Map<String, dynamic>>? notFavorites) {
    Analytics().logSelect(source: 'Customize', target: 'Star All');
    if (CollectionUtils.isNotEmpty(notFavorites)) {
      for (Map<String, dynamic>? entry in notFavorites!.reversed) {
        if (entry != null) {
          String? code = entry['code'];
          if (StringUtils.isNotEmpty(code)) {
            _setFavorite(code: code!, value: true);
          }
        }
      }
    }
  }

  void _setFavorite({required String code, required bool value}) {
    HomeFavorite favorite = HomeFavorite(code);
    List<String>? avalableSectionFavorites = JsonUtils.listStringsValue(FlexUI()['home.${favorite.id}']);
    if (avalableSectionFavorites != null) {
      List<Favorite> favorites = <Favorite>[favorite];
      for (String sectionEntry in avalableSectionFavorites) {
        favorites.add(HomeFavorite(sectionEntry, category: favorite.id));
      }
      Auth2().prefs?.setListFavorite(favorites, value);
      HomeFavorite.log(favorites, value);
    } else {
      Auth2().prefs?.setFavorite(favorite, value);
      HomeFavorite.log(favorite, value);
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
          HomeFavorite.log(HomeFavorite(dragFavoriteId));
        }
      }
      else if (0 <= dropIndex) {
        // Add favorite at specific position
        HomeFavoriteButton.promptFavorite(context, favorite: HomeFavorite(dragFavoriteId)).then((bool? result) {
          if (result == true) {
            if (dropAnchor == CrossAxisAlignment.start) {
              dropIndex++;
            }
            favoritesList.insert(dropIndex, dragFavoriteId);
            Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), LinkedHashSet<String>.from(favoritesList));
            _setSectionFavorites(dragFavoriteId, true);
            HomeFavorite.log(HomeFavorite(dragFavoriteId));
          }
        });
      }
      else if (dropFavoriteId == _favoritesHeaderId) {
        if (0 <= dragIndex) {
          // move drag favorite at 
          favoritesList.removeAt(dragIndex);
          favoritesList.insert(favoritesList.length, dragFavoriteId);
          Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), LinkedHashSet<String>.from(favoritesList));
          HomeFavorite.log(HomeFavorite(dragFavoriteId));
        }
        else {
          // add favorite
          HomeFavoriteButton.promptFavorite(context, favorite: HomeFavorite(dragFavoriteId)).then((bool? result) {
            if (result == true) {
              Auth2().prefs?.setFavorite(HomeFavorite(dragFavoriteId), true);
              _setSectionFavorites(dragFavoriteId, true);
              HomeFavorite.log(HomeFavorite(dragFavoriteId));
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
          _setSectionFavorites(dragFavoriteId, true);
          HomeFavorite.log(HomeFavorite(dragFavoriteId));
        }
        else {
          if (0 <= dragIndex) {
            // remove favorite
            HomeFavoriteButton.promptFavorite(context, favorite: HomeFavorite(dragFavoriteId)).then((bool? result) {
              if (result == true) {
                Auth2().prefs?.setFavorite(HomeFavorite(dragFavoriteId), false);
                _setSectionFavorites(dragFavoriteId, false);
                HomeFavorite.log(HomeFavorite(dragFavoriteId));
              }
            });
          }
        }
      }
      else {
        // remove favorite
        HomeFavoriteButton.promptFavorite(context, favorite: HomeFavorite(dragFavoriteId)).then((bool? result) {
          if (result == true) {
            Auth2().prefs?.setFavorite(HomeFavorite(dragFavoriteId), false);
            _setSectionFavorites(dragFavoriteId, false);
            HomeFavorite.log(HomeFavorite(dragFavoriteId));
          }
        });
      }
    }
  }

  void onAccessibilityMove({String? dragFavoriteId, int? delta}) {
    if (dragFavoriteId != null) {
      List<String> favoritesList = List.from(Auth2().prefs?.getFavorites(HomeFavorite.favoriteKeyName()) ?? <String>{});
      int dragIndex = favoritesList.indexOf(dragFavoriteId);
      if (0 <= dragIndex) {
        // Moving a favorite item. Where?
        int dropIndex = dragIndex + (delta ?? 0);
        if (dropIndex < favoritesList.length) {
          if (0 <= dropIndex) {
            // Inside the favorites list => Reorder Favorites
            if (dragIndex != dropIndex) {
              favoritesList.swap(dragIndex, dropIndex);
              favoritesList.insert(dropIndex, dragFavoriteId);
              Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), LinkedHashSet<String>.from(favoritesList));
              _ensureVisibleHandle(dragFavoriteId);
              HomeFavorite.log(HomeFavorite(dragFavoriteId));
            }
          }
          else {
            // Outside the favorites list => Remove Favorite
            HomeFavoriteButton.promptFavorite(context, favorite: HomeFavorite(dragFavoriteId)).then((bool? result) {
              if (result == true) {
                Auth2().prefs?.setFavorite(HomeFavorite(dragFavoriteId), false);
                _setSectionFavorites(dragFavoriteId, false);
                _ensureVisibleHandle(dragFavoriteId);
                HomeFavorite.log(HomeFavorite(dragFavoriteId));
              }
            });
          }
        }
      }
      else {
        // Moving unused item. Where?
        int dropIndex = -1 + (delta ?? 0);
        if ((0 <= dropIndex) && (dropIndex <= favoritesList.length)) {
          // Inside favorites list => Add Favorite
          HomeFavoriteButton.promptFavorite(context, favorite: HomeFavorite(dragFavoriteId)).then((bool? result) {
            if (result == true) {
              favoritesList.insert(dropIndex, dragFavoriteId);
              Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), LinkedHashSet<String>.from(favoritesList));
              _setSectionFavorites(dragFavoriteId, true);
              _ensureVisibleHandle(dragFavoriteId);
              HomeFavorite.log(HomeFavorite(dragFavoriteId));
            }
          });
        }
      }
    }
  }

  void _setSectionFavorites(String favoriteId, bool value) {
      List<String>? avalableSectionFavorites = JsonUtils.listStringsValue(FlexUI()['home.$favoriteId']);            
      if (avalableSectionFavorites != null) {
        Iterable<Favorite> favorites = avalableSectionFavorites.map((e) => HomeFavorite(e, category: favoriteId));
        Auth2().prefs?.setListFavorite(favorites, value);
      }
  }

  void _ensureVisibleHandle(String favoriteId) {
    BuildContext? handleContext = _handleKeys[favoriteId]?.currentContext;
    if (handleContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(handleContext, duration: Duration(milliseconds: 300)).then((_) {
        });
      });
    }
  }

  GlobalKey _widgetKey(String code) => _widgetKeys[code] ??= GlobalKey();
  GlobalKey _handleKey(String code) => _handleKeys[code] ??= GlobalKey();

  GlobalKey get _saferWidgetKey => _widgetKey('safer');

  void _ensureSaferWidgetVisibiity() {
      BuildContext? saferContext = _saferWidgetKey.currentContext;
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
      _updateFavoriteCodes();
    }
    else if (name == HomeSaferWidget.notifyNeedsVisiblity) {
      _ensureSaferWidgetVisibiity();
    }
    else if (name == HomePanel.notifyCustomize) {
      if (mounted && !_isEditing) {
        setState(() {
          _isEditing = true;
        });
      }
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

class _HomeHeaderBar extends StatefulWidget implements PreferredSizeWidget {

  final void Function()? onEditDone;
  final String? title;
  
  _HomeHeaderBar({Key? key, this.title, this.onEditDone}) : super(key: key);

  bool get editing => (onEditDone != null);

  // PreferredSizeWidget
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  _HomeHeaderBarState createState() => _HomeHeaderBarState();
}

class _HomeHeaderBarState extends State<_HomeHeaderBar> {

  @override
  Widget build(BuildContext context) {
    if (widget.editing) {
      return HeaderBar(title: widget.title, onLeading: _onBack);
    } else {
      return RootHeaderBar(key: widget.key, title: widget.title);
    }
  }

  void _onBack() {
    Analytics().logSelect(target: 'Customize Done', source: 'HomePanel');
    if (widget.onEditDone != null) {
      widget.onEditDone!();
    }
  }
}

// HomeDragAndDropHost

abstract class HomeDragAndDropHost  {
  set isDragging(bool value);
  void onDragAndDrop({String? dragFavoriteId, String? dropFavoriteId, CrossAxisAlignment? dropAnchor});
  void onAccessibilityMove({String? dragFavoriteId, int? delta});
}

// HomeFavorite

class HomeFavorite extends Favorite {
  final String? id;
  final String? category;
  HomeFavorite(this.id, {this.category});

  bool operator == (o) => o is HomeFavorite && o.id == id && o.category == category;
  int get hashCode => (id?.hashCode ?? 0) ^ (category?.hashCode ?? 0);

  static String favoriteKeyName({String? category}) => (category != null) ? "home.$category.widgetIds" : "home.widgetIds";
  @override String get favoriteKey => favoriteKeyName(category: category);
  @override String? get favoriteId => id;

  static String? parseFavoriteKeyCategory(String? value) {
    if (value != null) {
      String prefix = "home.";
      int prefixIndex = value.indexOf(prefix);

      String suffix = ".widgetIds";
      int suffixIndex = value.indexOf(suffix);

      if ((prefixIndex == 0) && ((prefixIndex + prefix.length) < suffixIndex) && ((suffixIndex + suffix.length) == value.length)) {
        return value.substring(prefix.length, value.length - suffix.length);
      }
    }
    return null;
  }

  static void log(dynamic favorite, [bool? selected]) {
    List<Favorite> usedList = <Favorite>[];
    List<Favorite> unusedList = <Favorite>[];
    
    List<String>? fullContent = JsonUtils.listStringsValue(FlexUI()['home']);
    LinkedHashSet<String>? homeFavorites = Auth2().prefs?.getFavorites(favoriteKeyName());

    if (homeFavorites != null) {
      for (String code in List<String>.from(homeFavorites).reversed) {
        if (fullContent?.contains(code) ?? false) {
          usedList.add(HomeFavorite(code));
        }
      }
    }

    if (fullContent != null) {
      for (String code in fullContent) {
        if (!(homeFavorites?.contains(code) ?? false)) {
          unusedList.add(HomeFavorite(code));
        }
      }
    }

    Analytics().logWidgetFavorite(favorite, selected, used: usedList, unused: unusedList);
  }
}

