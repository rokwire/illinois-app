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

import 'package:illinois/model/News.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Guide.dart';

enum RecentItemType{
  news,
  game,
  event,
  dining,
  explore, // for backward compatability only, we now use event / dining RecentItemType
  guide,
}

class RecentItem{
  RecentItemType? recentItemType;
  String? recentTitle;
  String? recentDescripton;
  String? recentTime;

  Map<String,dynamic>? recentOriginalJson;

  RecentItem({this.recentItemType, this.recentTitle, this.recentDescripton,this.recentTime, this.recentOriginalJson});

  static RecentItem? fromJson(Map<String, dynamic> json){
    return (json != null) ? RecentItem(
      recentItemType: recentTypeFromString(json["recent_type"]),
      recentTitle: json["recent_title"],
      recentDescripton: json["recent_description"],
      recentTime: json["recent_time"],
      recentOriginalJson: json["recent_original_json"],
    ) : null;
  }

  static RecentItem? fromOriginalType(dynamic item){
    if(item is Event) {
      Event event = item;
      if (event != null) {
        bool recurringEvent = event.isRecurring;
        String? recentTime = recurringEvent ? event.displayRecurringDates : event.displayDateTime;
        RecentItem eventItem = RecentItem(
            recentItemType: RecentItemType.event,
            recentTitle: event.exploreTitle,
            recentDescripton: event.shortDescription,
            recentTime: recentTime,
            recentOriginalJson: event.toJson()
        );
        return eventItem;
      }
    } else if(item is Dining) {
      Dining dining = item;
      if (dining != null) {
        RecentItem diningItem = RecentItem(
            recentItemType: RecentItemType.dining,
            recentTitle: dining.exploreTitle,
            recentDescripton: dining.shortDescription,
            recentTime: "",//dining.getDisplayWorkTime(), // MD: Temporary disabled Issue
            recentOriginalJson: dining.toJson()
        );
        return diningItem;
      }
    } else if(item is Game) {
      Game game = item;
      if (game != null) {
        RecentItem gameItem = RecentItem(
            recentItemType: RecentItemType.game,
            recentTitle: game.title,
            recentDescripton: game.shortDescription,
            recentTime: game.displayTime,
            recentOriginalJson: game.jsonData
        );
        return gameItem;
      }
    } else if(item is News) {
      News news = item;
      if (news != null) {
        RecentItem gameItem = RecentItem(
            recentItemType: RecentItemType.news,
            recentTitle: news.title,
            recentDescripton: news.description,
            recentTime: news.displayTime,
            recentOriginalJson: news.json
        );
        return gameItem;
      }
    } else if(item is Explore) {
      Explore explore = item;
      if(explore!=null){
        RecentItem exploreItem = RecentItem(
            recentItemType: RecentItemType.explore,
            recentTitle: explore.exploreTitle,
            recentDescripton: explore.exploreShortDescription,
            recentOriginalJson: explore.toJson()
        );
        return exploreItem;
      }
    }

    return null;
  }

  static RecentItem? fromGuideItem(Map<String, dynamic>? guideItem) {
    return (guideItem != null) ? RecentItem(
      recentItemType: RecentItemType.guide,
      recentTitle: Guide().entryListTitle(guideItem, stripHtmlTags: true) ?? '',
      recentDescripton: Guide().entryListDescription(guideItem, stripHtmlTags: true) ?? '',
      recentOriginalJson: guideItem
    ) : null;

  }

  Map<String, dynamic> toJson() =>
      {
        'recent_type': recentTypeToString(recentItemType),
        'recent_title': recentTitle,
        'recent_description': recentDescripton,
        'recent_time': recentTime,
        'recent_original_json': recentOriginalJson,
      };

  Object? fromOriginalJson(){
    switch(recentItemType){
      case RecentItemType.news: return News.fromJson(recentOriginalJson);
      case RecentItemType.game: return Game.fromJson(recentOriginalJson);
      case RecentItemType.event: return Event.fromJson(recentOriginalJson);
      case RecentItemType.dining: return Dining.fromJson(recentOriginalJson);
      case RecentItemType.explore: return Explore.fromJson(recentOriginalJson);
      case RecentItemType.guide: return recentOriginalJson;
      default: return null;
    }
  }

  String? getIconPath() {
    switch (recentItemType) {
      case RecentItemType.news:
        return 'images/icon-news.png';
      case RecentItemType.game:
        return 'images/icon-athletics-blue.png';
      case RecentItemType.event:
        return 'images/icon-calendar.png';
      case RecentItemType.dining:
        return 'images/icon-dining-yellow.png';
      case RecentItemType.guide:
        return 'images/icon-news.png';
      case RecentItemType.explore:
        {
          if (Event.canJson(recentOriginalJson)) {
            return 'images/icon-calendar.png';
          }
          else if (Dining.canJson(recentOriginalJson)) {
            return 'images/icon-dining-yellow.png';
          }
          else {
            return null;
          }
        }
        break;
      default:
        return null;
    }
  }

  bool operator ==(o) =>
      o is RecentItem &&
          o.recentItemType == recentItemType &&
          o.recentDescripton == recentDescripton &&
          o.recentTime == recentTime &&
          o.recentTitle == recentTitle;

  int get hashCode =>
      (recentTitle?.hashCode ?? 0) ^
      (recentDescripton?.hashCode ?? 0) ^
      (recentItemType?.hashCode ?? 0) ^
      (recentTime?.hashCode ?? 0);

  static RecentItemType? recentTypeFromString(String? value){
    if("news" == value){
      return RecentItemType.news;
    }
    if("game" == value){
      return RecentItemType.game;
    }
    if("event" == value){
      return RecentItemType.event;
    }
    if("dining" == value){
      return RecentItemType.dining;
    }
    if("explore" == value){
      return RecentItemType.explore;
    }
    if("student_guide" == value){
      return RecentItemType.guide;
    }
    return null;
  }

  static String? recentTypeToString(RecentItemType? value){
    switch(value){
      case RecentItemType.news: return "news";
      case RecentItemType.game: return "game";
      case RecentItemType.event: return "event";
      case RecentItemType.dining: return "dining";
      case RecentItemType.explore: return "explore";
      case RecentItemType.guide: return "student_guide";
      default: return null;
    }
  }

  static List<RecentItem> createFromList(List items ){
    List<RecentItem> result = [];
    if(items!=null && items.isNotEmpty){
      items.forEach((dynamic each){
        RecentItem? item = RecentItem.fromOriginalType(each);
        if(item!=null)
          result.add(item);
      });
    }
    return result;
  }


}