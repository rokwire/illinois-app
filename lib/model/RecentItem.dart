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
import 'package:collection/collection.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/ext/Event.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ext/Game.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Guide.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum RecentItemType {
  event,
  event2,
  dining,
  game,
  news,
  laundry,
  guide,
  mtdStop,
}

class RecentItem {
  RecentItemType? type;
  String? id;
  String? title;
  String? descripton;
  String? time;

  Map<String, dynamic>? sourceJson;

  RecentItem({this.type, this.id, this.title, this.descripton, this.time, this.sourceJson});

  static RecentItem? fromJson(Map<String, dynamic>? json){
    return (json != null) ? RecentItem(
      type:       recentTypeFromString(JsonUtils.stringValue(json["recent_type"])),
      id:         JsonUtils.stringValue(json["id"]),
      title:      JsonUtils.stringValue(json["recent_title"]),
      descripton: JsonUtils.stringValue(json["recent_description"]),
      time:       JsonUtils.stringValue(json["recent_time"]),
      sourceJson: JsonUtils.mapValue(json["recent_original_json"]),
    ) : null;
  }

  Map<String, dynamic> toJson() => {
    'recent_type': recentTypeToString(type),
    'id': id,
    'recent_title': title,
    'recent_description': descripton,
    'recent_time': time,
    'recent_original_json': sourceJson,
  };

  static RecentItem? fromSource(dynamic item){
    if(item is Event) {
      return RecentItem(
          type: RecentItemType.event,
          id: item.id,
          title: item.title,
          descripton: item.description,
          time: item.isRecurring ? item.displayRecurringDates : item.displayDateTime,
          sourceJson: item.toJson()
      );
    } else if(item is Event2) {
      return RecentItem(
          type: RecentItemType.event2,
          id: item.id,
          title: item.name,
          descripton: item.description,
          time: item.shortDisplayDateAndTime,
          sourceJson: item.toJson()
      );
    } else if(item is Dining) {
      return RecentItem(
          type: RecentItemType.dining,
          id: item.id,
          title: item.title,
          descripton: item.description,
          time: item.displayWorkTime,
          sourceJson: item.toJson()
      );
    } else if(item is Game) {
      return RecentItem(
          type: RecentItemType.game,
          id: item.id,
          title: item.title,
          descripton: item.description,
          time: item.displayTime,
          sourceJson: item.jsonData
      );
    } else if(item is News) {
      return RecentItem(
          type: RecentItemType.news,
          id: item.id,
          title: item.title,
          descripton: item.description,
          time: item.displayTime,
          sourceJson: item.json
      );
    } else if(item is LaundryRoom) {
      return RecentItem(
          type: RecentItemType.laundry,
          id: item.id,
          title: item.name,
          descripton: item.displayStatus,
          time: null,
          sourceJson: item.toJson()
      );
    } else if(item is MTDStop) {
      return RecentItem(
          type: RecentItemType.mtdStop,
          id: item.id,
          title: item.name,
          descripton: item.code,
          time: null,
          sourceJson: item.toJson()
      );
    }

    return null;
  }

  static RecentItem? fromGuideItem(Map<String, dynamic>? guideItem) {
    String? guideId = Guide().entryId(guideItem);
    return (guideId != null) ? RecentItem(
      type: RecentItemType.guide,
      id: guideId,
      title: Guide().entryListTitle(guideItem, stripHtmlTags: true) ?? '',
      descripton: Guide().entryListDescription(guideItem, stripHtmlTags: true) ?? '',
      sourceJson: guideItem
    ) : null;

  }

  dynamic get source {
    switch (type) {
      case RecentItemType.event: return Event.fromJson(sourceJson);
      case RecentItemType.event2: return Event2.fromJson(sourceJson);
      case RecentItemType.dining: return Dining.fromJson(sourceJson);
      case RecentItemType.game: return Game.fromJson(sourceJson);
      case RecentItemType.news: return News.fromJson(sourceJson);
      case RecentItemType.laundry: return LaundryRoom.fromJson(sourceJson);
      case RecentItemType.mtdStop: return MTDStop.fromJson(sourceJson);
      case RecentItemType.guide: return sourceJson;
      default: return null;
    }
  }

  Favorite? get favorite {
    if (id != null) {
      switch (type) {
        case RecentItemType.event:   return FavoriteItem(key: Event.favoriteKeyName, id: id);
        case RecentItemType.event2:  return FavoriteItem(key: Event2.favoriteKeyName, id: id);
        case RecentItemType.dining:  return FavoriteItem(key: Dining.favoriteKeyName, id: id);
        case RecentItemType.game:    return FavoriteItem(key: Game.favoriteKeyName, id: id);
        case RecentItemType.news:    return FavoriteItem(key: News.favoriteKeyName, id: id);
        case RecentItemType.laundry: return FavoriteItem(key: LaundryRoom.favoriteKeyName, id: id);
        case RecentItemType.mtdStop: return FavoriteItem(key: MTDStop.favoriteKeyName, id: id);
        case RecentItemType.guide:   return GuideFavorite(id: id);
        default: return null;
      }
    }
    else {
      dynamic sourceItem = source;
      if (sourceItem is Favorite) {
        return sourceItem;
      }
      else if ((type == RecentItemType.guide) && (sourceItem is Map)) {
        return GuideFavorite(id: Guide().entryId(JsonUtils.mapValue(sourceItem)));
      }
      else {
        return null;
      }
    }
  }

  bool operator ==(o) =>
      o is RecentItem &&
          o.type == type &&
          o.id == id &&
          o.title == title &&
          o.descripton == descripton &&
          o.time == time &&
          DeepCollectionEquality().equals(o.sourceJson, sourceJson);

  int get hashCode =>
      (type?.hashCode ?? 0) ^
      (id?.hashCode ?? 0) ^
      (title?.hashCode ?? 0) ^
      (descripton?.hashCode ?? 0) ^
      (time?.hashCode ?? 0) ^
      (DeepCollectionEquality().hash(sourceJson));

  static Queue<RecentItem>? queueFromJson(List<dynamic>? jsonList) {
    Queue<RecentItem>? queue;
    if (jsonList != null) {
      queue = Queue<RecentItem>();
      for (dynamic jsonEntry in jsonList) {
        RecentItem? recentItem = RecentItem.fromJson(JsonUtils.mapValue(jsonEntry));
        if (recentItem != null) {
          queue.add(recentItem);
        }
      }
    }
    return queue;
  }

  static List<dynamic>? queueToJson(Queue<RecentItem>? queue) {
    List<dynamic>? jsonList;
    if (queue != null) {
      jsonList = [];
      for (RecentItem recentItem in queue) {
        jsonList.add(recentItem.toJson());
      }
    }
    return jsonList;
  }


}


// RecentItemType

RecentItemType? recentTypeFromString(String? value){
  if ("event" == value) {
    return RecentItemType.event;
  }
  else if ("event2" == value) {
    return RecentItemType.event2;
  }
  else if ("dining" == value) {
    return RecentItemType.dining;
  }
  else if ("game" == value) {
    return RecentItemType.game;
  }
  else if ("news" == value) {
    return RecentItemType.news;
  }
  else if ("laundry" == value) {
    return RecentItemType.laundry;
  }
  else if ("mtd_stop" == value) {
    return RecentItemType.mtdStop;
  }
  else if ("student_guide" == value) {
    return RecentItemType.guide;
  }
  return null;
}

String? recentTypeToString(RecentItemType? value){
  switch(value){
    case RecentItemType.event: return "event";
    case RecentItemType.event2: return "event2";
    case RecentItemType.dining: return "dining";
    case RecentItemType.game: return "game";
    case RecentItemType.news: return "news";
    case RecentItemType.laundry: return "laundry";
    case RecentItemType.mtdStop: return "mtd_stop";
    case RecentItemType.guide: return "student_guide";
    default: return null;
  }
}
