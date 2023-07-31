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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/model/Appointment.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/CheckList.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/home/HomeAppHelpWidget.dart';
import 'package:illinois/ui/home/HomeAthleticsEventsWidget.dart';
import 'package:illinois/ui/home/HomeAthleticsNewsWidget.dart';
import 'package:illinois/ui/home/HomeCampusSafetyResourcesWidget.dart';
import 'package:illinois/ui/home/HomeCanvasCoursesWidget.dart';
import 'package:illinois/ui/home/HomeCheckListWidget.dart';
import 'package:illinois/ui/home/HomeCustomizeFavoritesPanel.dart';
import 'package:illinois/ui/home/HomeDailyIlliniWidget.dart';
import 'package:illinois/ui/home/HomeDiningWidget.dart';
import 'package:illinois/ui/home/HomeEvent2FeedWidget.dart';
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
import 'package:illinois/ui/home/HomeWellnessMentalHealthWidget.dart';
import 'package:illinois/ui/home/HomeWellnessToDoWidget.dart';
import 'package:illinois/ui/home/HomeWellnessRingsWidget.dart';
import 'package:illinois/ui/home/HomeWellnessTipsWidget.dart';
import 'package:illinois/ui/home/HomeWellnessResourcesWidget.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
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
import 'package:illinois/ui/widgets/FlexContent.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomePanel extends StatefulWidget {
  static const String notifyRefresh      = "edu.illinois.rokwire.home.refresh";
  static const String notifySelect       = "edu.illinois.rokwire.home.select";

  @override
  _HomePanelState createState() => _HomePanelState();

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
    else if (code == 'campus_resources') {
      if (title) {
        return HomeCampusResourcesWidget.title;
      } else if (handle) {
        return HomeCampusResourcesWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeCampusResourcesWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
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
    /*else if (code == 'suggested_events') {
      if (title) {
        return HomeSuggestedEventsWidget.title;
      } else if (handle) {
        return HomeSuggestedEventsWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeSuggestedEventsWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
      }
    }*/
    else if (code == 'recent_items') {
      if (title) {
        return HomeRecentItemsWidget.title;
      } else if (handle) {
        return HomeRecentItemsWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeRecentItemsWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
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
    else if (code == 'canvas_courses') {
      if (title) {
        return HomeCanvasCoursesWidget.title;
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
    else if (code == 'wpgufm_radio') {
      if (title) {
        return HomeWPGUFMRadioWidget.title;
      } else if (handle) {
        return HomeWPGUFMRadioWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position,);
      } else {
        return HomeWPGUFMRadioWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController,);
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

    else if (code == 'my_events') {
      if (title) {
        return HomeFavoritesWidget.titleFromKey(favoriteKey: Event2.favoriteKeyName); 
      } else if (handle) {
        return HomeFavoritesWidget.handle(key: _globalKey(globalKeys, code), favoriteId: code, dragAndDropHost: dragAndDropHost, position: position, favoriteKey: Event2.favoriteKeyName, );
      } else {
        return HomeFavoritesWidget(key: _globalKey(globalKeys, code), favoriteId: code, updateController: updateController, favoriteKey: Event2.favoriteKeyName);
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
  
  List<String>? _favoriteCodes;
  Set<String>? _availableCodes;
  List<String>? _systemCodes;
  StreamController<String> _updateController = StreamController.broadcast();
  Map<String, GlobalKey> _widgetKeys = <String, GlobalKey>{};
  GlobalKey _contentWrapperKey = GlobalKey();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {

    // Build Favorite codes before start listening for Auth2UserPrefs.notifyFavoritesChanged
    // because _buildFavoriteCodes may fire such.
    _favoriteCodes = _buildFavoriteCodes();
    _availableCodes = JsonUtils.setStringsValue(FlexUI()['home']) ?? <String>{};
    _systemCodes = JsonUtils.listStringsValue(FlexUI()['home.system']);

    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Localization.notifyStringsUpdated,
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged,
      Styles.notifyChanged,
      HomeSaferWidget.notifyNeedsVisiblity,
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

    String title = Localization().getStringEx('panel.home.header.title', 'Favorites');

    return Scaffold(
      appBar: RootHeaderBar(title: title),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child:
        Column(key: _contentWrapperKey, children: <Widget>[
          Expanded(child:
            SingleChildScrollView(controller: _scrollController, child:
              Column(children: _buildRegularContentList(),)
            )
          ),
        ]),
      ),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: null,
    );
  }

  List<Widget> _buildRegularContentList() {
    List<Widget> widgets = [];
    widgets.addAll(_buildWidgetsFromCodes(_systemCodes));
    widgets.addAll(_buildWidgetsFromCodes(_favoriteCodes?.reversed, availableCodes: _availableCodes));
    return widgets;
  }

  List<Widget> _buildWidgetsFromCodes(Iterable<String>? codes, { Set<String>? availableCodes }) {
    List<Widget> widgets = [];
    if (codes != null) {
      for (String code in codes) {
        if ((availableCodes == null) || availableCodes.contains(code)) {
          Widget? widget = _widgetFromCode(code);
          if (widget is Widget) {
            widgets.add(widget);
          }
        }
      }
    }
    return widgets;
  }

  Widget? _widgetFromCode(String code,) {
    if (code == 'tout') {
      return HomeToutWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController, onEdit: _onEdit,);
    }
    else if (code == 'emergency') {
      return FlexContent(contentKey: code, key: _widgetKey(code), favoriteId: code, updateController: _updateController);
    }
    else if (code == 'voter_registration') {
      return HomeVoterRegistrationWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'connect') {
      return HomeLoginWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,);
    }
    else if (code == 'welcome') {
      return HomeWelcomeWidget(key: _widgetKey(code), favoriteId: code, updateController: _updateController,); //TBD
    }
    else {
      dynamic data = HomePanel.dataFromCode(code,
        title: false, handle: false, position: 0,
        globalKeys: _widgetKeys,
        updateController: _updateController,
      );
      
      return (data is Widget) ? data : FlexContent(contentKey: code, key: _widgetKey(code), favoriteId: code, updateController: _updateController);
    }
  }

  GlobalKey _widgetKey(String code) => _widgetKeys[code] ??= GlobalKey();

  void _updateSystemAndAvailableCodes() {
    Set<String>? availableCodes = JsonUtils.setStringsValue(FlexUI()['home']);
    bool availableCodesChanged = (availableCodes != null) && !DeepCollectionEquality().equals(_availableCodes, availableCodes);

    List<String>? systemCodes = JsonUtils.listStringsValue(FlexUI()['home.system']);
    bool systemCodesChanged = (systemCodes != null) && !DeepCollectionEquality().equals(_systemCodes, systemCodes);

    if (mounted && (availableCodesChanged || systemCodesChanged)) {
      setState(() {
        if (availableCodesChanged) {
          _availableCodes = availableCodes;
        }
        if (systemCodesChanged) {
          _systemCodes = systemCodes;
        }
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
    _updateController.add(HomePanel.notifyRefresh);
  }

  GlobalKey get _saferWidgetKey => _widgetKey('safer');

  void _ensureSaferWidgetVisibiity() {
      BuildContext? saferContext = _saferWidgetKey.currentContext;
      if (saferContext != null) {
        Scrollable.ensureVisible(saferContext, duration: Duration(milliseconds: 300));
      }
  }

  void _onEdit() {
    HomeCustomizeFavoritesPanel.present(context);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _updateSystemAndAvailableCodes();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _updateFavoriteCodes();
    }
    else if (name == HomeSaferWidget.notifyNeedsVisiblity) {
      _ensureSaferWidgetVisibiity();
    }
    else if (((name == AppLivecycle.notifyStateChanged) && (param == AppLifecycleState.resumed)) ||
        (name == Localization.notifyStringsUpdated) ||
        (name == Styles.notifyChanged) ||
        (name == Storage.offsetDateKey) ||
        (name == Storage.useDeviceLocalTimeZoneKey))
    {
      if (mounted) {
        setState(() {});
      }
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

