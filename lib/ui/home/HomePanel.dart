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

import 'package:flutter/material.dart';
import 'package:neom/model/Analytics.dart';
import 'package:neom/model/Dining.dart';
import 'package:neom/model/Explore.dart';
import 'package:neom/model/Laundry.dart';
import 'package:neom/model/MTD.dart';
import 'package:neom/model/News.dart';
import 'package:neom/model/sport/Game.dart';
import 'package:neom/model/Appointment.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/service/CheckList.dart';
import 'package:neom/service/Guide.dart';
import 'package:neom/ui/BrowsePanel.dart';
import 'package:neom/service/RadioPlayer.dart';
import 'package:neom/ui/home/HomeAppHelpWidget.dart';
import 'package:neom/ui/home/HomeAthleticsEventsWidget.dart';
import 'package:neom/ui/home/HomeAthleticsNewsWidget.dart';
import 'package:neom/ui/home/HomeCampusSafetyResourcesWidget.dart';
import 'package:neom/ui/home/HomeCanvasCoursesWidget.dart';
import 'package:neom/ui/home/HomeFavoritesPanel.dart';
import 'package:neom/ui/home/HomeCheckListWidget.dart';
import 'package:neom/ui/home/HomeDailyIlliniWidget.dart';
import 'package:neom/ui/home/HomeDiningWidget.dart';
import 'package:neom/ui/home/HomeEvent2Widget.dart';
import 'package:neom/ui/home/HomeFavoritesWidget.dart';
import 'package:neom/ui/home/HomeInboxWidget.dart';
import 'package:neom/ui/home/HomeLaundryWidget.dart';
import 'package:neom/ui/home/HomePublicSurveysWidget.dart';
import 'package:neom/ui/home/HomeRecentPollsWidget.dart';
import 'package:neom/ui/home/HomeResearchProjectsWidget.dart';
import 'package:neom/ui/home/HomeStateFarmCenterWidget.dart';
import 'package:neom/ui/home/HomeStudentCoursesWidget.dart';
import 'package:neom/ui/home/HomeToutWidget.dart';
import 'package:neom/ui/home/HomeVideoTutorialsWidget.dart';
import 'package:neom/ui/home/HomeRadioWidget.dart';
import 'package:neom/ui/home/HomeWalletWidget.dart';
import 'package:neom/ui/home/HomeWellnessMentalHealthWidget.dart';
import 'package:neom/ui/home/HomeWellnessToDoWidget.dart';
import 'package:neom/ui/home/HomeWellnessRingsWidget.dart';
import 'package:neom/ui/home/HomeWellnessTipsWidget.dart';
import 'package:neom/ui/home/HomeWellnessResourcesWidget.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:neom/service/FlexUI.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:neom/service/Storage.dart';
import 'package:neom/ui/home/HomeCampusRemindersWidget.dart';
import 'package:neom/ui/home/HomeCreatePollWidget.dart';
import 'package:neom/ui/home/HomeAthleticsGameDayWidget.dart';
import 'package:neom/ui/home/HomeGroupsWidget.dart';
import 'package:neom/ui/home/HomeRecentItemsWidget.dart';
import 'package:neom/ui/home/HomeSaferWidget.dart';
import 'package:neom/ui/home/HomeCampusHighlightsWidget.dart';
import 'package:neom/ui/home/HomeTwitterWidget.dart';
import 'package:neom/ui/widgets/FlexContent.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum HomeContentType { favorites, browse }

////////////////////////
// HomePanel

class HomePanel extends StatefulWidget with AnalyticsInfo {
  static const String notifyRefresh  = "edu.illinois.rokwire.home.refresh";
  static const String notifySelect   = "edu.illinois.rokwire.home.select";
  static const String selectParamKey = "select-param";

  final Map<String, dynamic> params = <String, dynamic>{};

  HomeContentType? get initialContentType => params[selectParamKey];
  set initialContentType(HomeContentType? value) => params[selectParamKey] = value;

  @override
  State<StatefulWidget> createState() => _HomePanelState();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.Home;

  static bool get hasState {
    Set<NotificationsListener>? subscribers = NotificationService().subscribers(notifySelect);
    if (subscribers != null) {
      for (NotificationsListener subscriber in subscribers) {
        if ((subscriber is _HomePanelState) && subscriber.mounted) {
          return true;
        }
      }
    }
    return false;
  }

  static dynamic dataFromCode(String code, {
    bool title = false,
    bool handle = false,
    int position = 0,
    Map<String, GlobalKey>? globalKeys,
    StreamController<String>? updateController,
    HomeDragAndDropHost? dragAndDropHost,
  }) {

    if (code == 'my_game_day') {
      if (title) {
        return HomeAthleticsGameDayWidget.title;
      } else if (handle) {
        return HomeAthleticsGameDayWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeAthleticsGameDayWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'sport_events') {
      if (title) {
        return HomeAthliticsEventsWidget.title;
      } else if (handle) {
        return HomeAthliticsEventsWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeAthliticsEventsWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'sport_news') {
      if (title) {
        return HomeAthliticsNewsWidget.title;
      } else if (handle) {
        return HomeAthliticsNewsWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeAthliticsNewsWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'campus_reminders') {
      if (title) {
        return HomeCampusRemindersWidget.title;
      } else if (handle) {
        return HomeCampusRemindersWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeCampusRemindersWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'event_feed') {
      if (title) {
        return HomeEvent2FeedWidget.title;
      } else if (handle) {
        return HomeEvent2FeedWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeEvent2FeedWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'my_events') {
      if (title) {
        return HomeMyEvents2Widget.title;
      } else if (handle) {
        return HomeMyEvents2Widget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeMyEvents2Widget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController);
      }
    }
    else if (code == 'recent_items') {
      if (title) {
        return HomeRecentItemsWidget.title;
      } else if (handle) {
        return HomeRecentItemsWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeRecentItemsWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'public_surveys') {
      if (title) {
        return HomePublicSurveysWidget.title;
      } else if (handle) {
        return HomePublicSurveysWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomePublicSurveysWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'campus_highlights') {
      if (title) {
        return HomeCampusHighlightsWidget.title;
      } else if (handle) {
        return HomeCampusHighlightsWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeCampusHighlightsWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'campus_safety_resources') {
      if (title) {
        return HomeCampusSafetyResourcesWidget.title;
      } else if (handle) {
        return HomeCampusSafetyResourcesWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeCampusSafetyResourcesWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'twitter') {
      if (title) {
        return HomeTwitterWidget.title;
      } else if (handle) {
        return HomeTwitterWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeTwitterWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'daily_illini') {
      if (title) {
        return HomeDailyIlliniWidget.title;
      } else if (handle) {
        return HomeDailyIlliniWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeDailyIlliniWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'gies_checklist') {
      if (title) {
        return HomeCheckListWidget.title(contentKey: CheckList.giesOnboarding);
      } else if (handle) {
        return HomeCheckListWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position, contentKey: CheckList.giesOnboarding);
      } else {
        return HomeCheckListWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController, contentKey: CheckList.giesOnboarding, );
      }
    }
    else if (code == 'new_student_checklist') {
      if (title) {
        return HomeCheckListWidget.title(contentKey: CheckList.uiucOnboarding);
      } else if (handle) {
        return HomeCheckListWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position, contentKey: CheckList.uiucOnboarding);
      } else {
        return HomeCheckListWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController, contentKey: CheckList.uiucOnboarding, );
      }
    }
    else if (code == 'gies_canvas_courses') {
      if (title) {
        return HomeCanvasCoursesWidget.giesTitle;
      } else if (handle) {
        return HomeCanvasCoursesWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position, isGies: true);
      } else {
        return HomeCanvasCoursesWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController, isGies: true,);
      }
    }
    else if (code == 'canvas_courses') {
      if (title) {
        return HomeCanvasCoursesWidget.canvasTitle;
      } else if (handle) {
        return HomeCanvasCoursesWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeCanvasCoursesWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'student_courses') {
      if (title) {
        return HomeStudentCoursesWidget.title;
      } else if (handle) {
        return HomeStudentCoursesWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeStudentCoursesWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'create_poll') {
      if (title) {
        return HomeCreatePollWidget.title;
      } else if (handle) {
        return HomeCreatePollWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeCreatePollWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'recent_polls') {
      if (title) {
        return HomeRecentPollsWidget.title;
      } else if (handle) {
        return HomeRecentPollsWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeRecentPollsWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'laundry') {
      if (title) {
        return HomeLaundryWidget.title;
      } else if (handle) {
        return HomeLaundryWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeLaundryWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'my_groups') {
      if (title) {
        return HomeGroupsWidget.title(contentType: GroupsContentType.my);
      } else if (handle) {
        return HomeGroupsWidget.handle(contentType: GroupsContentType.my, favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeGroupsWidget(key: _globalKey(globalKeys, code), contentType: GroupsContentType.my, favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'all_groups') {
      if (title) {
        return HomeGroupsWidget.titleForContentType(GroupsContentType.all);
      } else if (handle) {
        return HomeGroupsWidget.handle(contentType: GroupsContentType.all, favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeGroupsWidget(key: _globalKey(globalKeys, code), contentType: GroupsContentType.all, favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'my_research_projects') {
      if (title) {
        return HomeResearchProjectsWidget.title(contentType: ResearchProjectsContentType.my);
      } else if (handle) {
        return HomeResearchProjectsWidget.handle(contentType: ResearchProjectsContentType.my, favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeResearchProjectsWidget(key: _globalKey(globalKeys, code), contentType: ResearchProjectsContentType.my, favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'open_research_projects') {
      if (title) {
        return HomeResearchProjectsWidget.titleForContentType(ResearchProjectsContentType.open);
      } else if (handle) {
        return HomeResearchProjectsWidget.handle(contentType: ResearchProjectsContentType.open, favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeResearchProjectsWidget(key: _globalKey(globalKeys, code), contentType: ResearchProjectsContentType.open, favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'my_appointments') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: Appointment.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position, favoriteKey: Appointment.favoriteKeyName, );
      } else {
        return HomeFavoritesWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController, favoriteKey: Appointment.favoriteKeyName);
      }
    }
    else if (code == 'my_mtd_stops') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: MTDStop.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position, favoriteKey: MTDStop.favoriteKeyName, );
      } else {
        return HomeFavoritesWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController, favoriteKey: MTDStop.favoriteKeyName);
      }
    }
    else if (code == 'my_mtd_destinations') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: ExplorePOI.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position, favoriteKey: ExplorePOI.favoriteKeyName, );
      } else {
        return HomeFavoritesWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController, favoriteKey: ExplorePOI.favoriteKeyName);
      }
    }
    else if (code == 'safer') {
      if (title) {
        return HomeSaferWidget.title;
      } else if (handle) {
        return HomeSaferWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeSaferWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'dinings') {
      if (title) {
        return HomeDiningWidget.title;
      } else if (handle) {
        return HomeDiningWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeDiningWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'wallet') {
      if (title) {
        return HomeWalletWidget.title;
      } else if (handle) {
        return HomeWalletWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeWalletWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'will_radio') {
      if (title) {
        return HomeRadioWidget.stationTitle(RadioStation.will);
      } else if (handle) {
        return HomeRadioWidget.handle(RadioStation.will, key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeRadioWidget(RadioStation.will, key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'willfm_radio') {
      if (title) {
        return HomeRadioWidget.stationTitle(RadioStation.willfm);
      } else if (handle) {
        return HomeRadioWidget.handle(RadioStation.willfm, key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeRadioWidget(RadioStation.willfm, key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'willhd_radio') {
      if (title) {
        return HomeRadioWidget.stationTitle(RadioStation.willhd);
      } else if (handle) {
        return HomeRadioWidget.handle(RadioStation.willhd, key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeRadioWidget(RadioStation.willhd, key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'wpgufm_radio') {
      if (title) {
        return HomeRadioWidget.stationTitle(RadioStation.wpgufm);
      } else if (handle) {
        return HomeRadioWidget.handle(RadioStation.wpgufm, key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeRadioWidget(RadioStation.wpgufm, key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'all_notifications') {
      if (title) {
        return HomeInboxWidget.title(content: HomeInboxContent.all);
      } else if (handle) {
        return HomeInboxWidget.handle(key: _globalKey(globalKeys, code), content: HomeInboxContent.all, favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeInboxWidget(key: _globalKey(globalKeys, code), content: HomeInboxContent.all, favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'unread_notifications') {
      if (title) {
        return HomeInboxWidget.title(content: HomeInboxContent.unread);
      } else if (handle) {
        return HomeInboxWidget.handle(key: _globalKey(globalKeys, code), content: HomeInboxContent.unread, favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeInboxWidget(key: _globalKey(globalKeys, code), content: HomeInboxContent.unread, favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'app_help') {
      if (title) {
        return HomeAppHelpWidget.title;
      } else if (handle) {
        return HomeAppHelpWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeAppHelpWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'video_tutorials') {
      if (title) {
        return HomeVideoTutorialsWidget.title;
      } else if (handle) {
        return HomeVideoTutorialsWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeVideoTutorialsWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'state_farm_center') {
      if (title) {
        return HomeStateFarmCenterWidget.title;
      } else if (handle) {
        return HomeStateFarmCenterWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeStateFarmCenterWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }

    else if (code == 'my_dining') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: Dining.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position, favoriteKey: Dining.favoriteKeyName, );
      } else {
        return HomeFavoritesWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController, favoriteKey: Dining.favoriteKeyName,);
      }
    }
    else if (code == 'my_athletics') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: Game.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position, favoriteKey: Game.favoriteKeyName);
      } else {
        return HomeFavoritesWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController, favoriteKey: Game.favoriteKeyName,);
      }
    }
    else if (code == 'my_news') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: News.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position, favoriteKey: News.favoriteKeyName,);
      } else {
        return HomeFavoritesWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController, favoriteKey: News.favoriteKeyName, );
      }
    }
    else if (code == 'my_laundry') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: LaundryRoom.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position, favoriteKey: LaundryRoom.favoriteKeyName);
      } else {
        return HomeFavoritesWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController, favoriteKey: LaundryRoom.favoriteKeyName, );
      }
    }
    else if (code == 'my_campus_guide') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: GuideFavorite.favoriteKeyName);
      } else if (handle) {
        return HomeFavoritesWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position, favoriteKey: GuideFavorite.favoriteKeyName, );
      } else {
        return HomeFavoritesWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController, favoriteKey: GuideFavorite.favoriteKeyName, );
      }
    }

    else if (code == 'wellness_resources') {
      if (title) {
        return HomeWellnessResourcesWidget.title;
      } else if (handle) {
        return HomeWellnessResourcesWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeWellnessResourcesWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'wellness_mental_health') {
      if (title) {
        return HomeWellnessMentalHealthWidget.title;
      } else if (handle) {
        return HomeWellnessMentalHealthWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeWellnessMentalHealthWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'wellness_todo') {
      if (title) {
        return HomeWellnessToDoWidget.title;
      } else if (handle) {
        return HomeWellnessToDoWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeWellnessToDoWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'wellness_rings') {
      if (title) {
        return HomeWellnessRingsWidget.title;
      } else if (handle) {
        return HomeWellnessRingsWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeWellnessRingsWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else if (code == 'wellness_tips') {
      if (title) {
        return HomeWellnessTipsWidget.title;
      } else if (handle) {
        return HomeWellnessTipsWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeWellnessTipsWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }
    else {
      return (handle || title) ? null : FlexContent(contentKey: code, key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController);
    }
  }

  static Key? _globalKey(Map<String, GlobalKey>? globalKeys, String code) => (globalKeys != null) ? (globalKeys[code] ??= GlobalKey()) : null;
}

class _HomePanelState extends State<HomePanel> with AutomaticKeepAliveClientMixin<HomePanel> implements NotificationsListener {

  late HomeContentType _contentType;
  Set<String>? _availableSystemCodes;
  StreamController<String> _updateController = StreamController.broadcast();
  GlobalKey _contentWrapperKey = GlobalKey();
  GlobalKey _toutKey = GlobalKey();
  GlobalKey _browseKey = GlobalKey();
  GlobalKey _favoritesKey = GlobalKey();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {

    NotificationService().subscribe(this, [
      _HomeContentTab.notifySelect,
      HomePanel.notifySelect,
    ]);

    HomeContentType? initialContentType = widget.initialContentType;
    if (initialContentType != null) {
      Storage().homeContentType = _homeContentTypeToString(_contentType = initialContentType);
      widget.initialContentType = null;
    }
    else {
      _contentType = _homeContentTypeFromString(Storage().homeContentType) ?? HomeContentType.favorites;
    }

    _availableSystemCodes = JsonUtils.setStringsValue(FlexUI()['home.system']) ?? <String>{};
    _availableSystemCodes?.remove('tout'); // Tout widget embedded statically here, do not show it as part of favorites

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _updateController.close();
    _scrollController.dispose();
    super.dispose();
  }

  // AutomaticKeepAliveClientMixin

  @override
  bool get wantKeepAlive => true;

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if ((name == _HomeContentTab.notifySelect) && (param is HomeContentType)) {
      _updateContentType(param);
    }
    else if ((name == HomePanel.notifySelect) && (param is HomeContentType)) {
      _updateContentType(param);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.home.header.title', 'Home')),
      body: Column(key: _contentWrapperKey, children: <Widget>[
        Row(children: [
          Expanded(child: _HomeContentTab(HomeContentType.favorites, selected: _contentType == HomeContentType.favorites,)),
          Expanded(child: _HomeContentTab(HomeContentType.browse, selected: _contentType == HomeContentType.browse,)),
        ],),
        Expanded(child:
          RefreshIndicator(onRefresh: _onPullToRefresh, child:
            Stack(children: [
              SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), child:
                Column(children: [
                  HomeToutWidget(key: _toutKey, contentType: _contentType, updateController: _updateController,),

                  Visibility(visible: (_contentType == HomeContentType.favorites), maintainState: true, child:
                    HomeFavoritesContentWidget(key: _favoritesKey, availableSystemCodes: _availableSystemCodes, updateController: _updateController,),
                  ),

                  Visibility(visible: (_contentType == HomeContentType.browse), maintainState: true, child:
                    BrowseContentWidget(key: _browseKey),
                  ),
                ],),
              ),
              _topShaddow,
            ],),
          ),
        ),
      ]),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: null,
    );
  }

  Widget get _topShaddow => Container(height: HomeToutWidget.triangleHeight, decoration: BoxDecoration(
    // color: Styles().colors.fillColorPrimaryTransparent03,
    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
      Styles().colors.fillColorPrimaryTransparent03,
      Colors.transparent,
    ]),
  ),);

  Future<void> _onPullToRefresh() async {
    _updateController.add(HomePanel.notifyRefresh);
  }

  void _updateContentType(HomeContentType? contentType) {
    if (mounted && (contentType != null) && (contentType != _contentType)) {
      setState(() {
        Storage().homeContentType = _homeContentTypeToString(_contentType = contentType);
      });
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

// _HomeContentTab

class _HomeContentTab extends StatelessWidget {
  static const String notifySelect      = "edu.illinois.rokwire.home.content_tab.select";

  final HomeContentType contentType;
  final bool selected;
  _HomeContentTab(this.contentType, { this.selected = false });

  @override
  Widget build(BuildContext context) => InkWell(onTap: _onTap, child:
    Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: selected ? Styles().colors.fillColorSecondary : Styles().colors.white, width: 3))),
      child: Center(child:
        Row(mainAxisSize: MainAxisSize.min, children: [
          _iconWidget,
          _textWidget,
        ],)
      ),
    ),
  );

  Widget get _iconWidget {
    Widget? image = _icon;
    return (image != null) ? Padding(padding: EdgeInsets.only(right: 8,), child: image) : Container();
  }

  Widget? get _icon {
    switch (contentType) {
      case HomeContentType.favorites: return Styles().images.getImage(selected ? 'star-filled' : 'star-outline-gray');
      case HomeContentType.browse: return Styles().images.getImage(selected ? 'browse-filled' : 'browse-outline-gray');
    }
  }

  Widget get _textWidget => Text(_text, style: _textStyle,);

  String get _text {
    switch (contentType) {
      case HomeContentType.favorites: return Localization().getStringEx('', 'Favorites');
      case HomeContentType.browse: return Localization().getStringEx('', 'Sections');
    }
  }

  TextStyle? get _textStyle => Styles().textStyles.getTextStyle(
    selected ?'widget.message.small.fat' : 'widget.message.light.small.semi_fat',
  );

  void _onTap() => NotificationService().notify(notifySelect, contentType);
}

// HomeContentType

HomeContentType? _homeContentTypeFromString(String? value) {
  switch(value) {
    case 'favorites': return HomeContentType.favorites;
    case 'browse': return HomeContentType.browse;
    default: return null;
  }
}

String? _homeContentTypeToString(HomeContentType? value) {
  switch(value) {
    case HomeContentType.favorites: return 'favorites';
    case HomeContentType.browse: return 'browse';
    default: return null;
  }
}
