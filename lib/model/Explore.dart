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

import 'dart:ui';

import 'package:illinois/model/Location.dart';

//////////////////////////////
/// Explore

abstract class Explore {

  String?   get exploreId;
  String?   get exploreTitle;
  String?   get exploreSubTitle;
  String?   get exploreShortDescription;
  String?   get exploreLongDescription;
  DateTime? get exploreStartDateUtc;
  String?   get exploreImageURL;
  String?   get explorePlaceId;
  Location? get exploreLocation;
  Color?    get uiColor;
  Map<String, dynamic> toJson();

  static Set<ExploreJsonHandler> _jsonHandlers = {};
  static void addJsonHandler(ExploreJsonHandler handler) => _jsonHandlers.add(handler);
  static void removeJsonHandler(ExploreJsonHandler handler) => _jsonHandlers.remove(handler);

  static ExploreJsonHandler? _getJsonHandler(Map<String, dynamic>? json) {
    if (json != null) {
      for (ExploreJsonHandler handler in _jsonHandlers) {
        if (handler.exploreCanJson(json)) {
          return handler;
        }
      }
    }
    return null;
  }

  static Explore? fromJson(Map<String, dynamic>? json) => _getJsonHandler(json)?.exploreFromJson(json);

  static List<Explore>? listFromJson(List<dynamic>? jsonList) {
    List<Explore>? explores;
    if (jsonList is List) {
      explores = [];
      for (dynamic jsonEntry in jsonList) {
        Explore? explore = Explore.fromJson(jsonEntry);
        if (explore != null) {
          explores.add(explore);
        }
      }
    }
    return explores;
  }

  static List<dynamic>? listToJson(List<Explore>? explores) {
    List<dynamic>? result;
    if (explores != null) {
      result = [];
      for (Explore explore in explores) {
        result.add(explore.toJson());
      }
    }
    return result;
  }
}

abstract class ExploreJsonHandler {
  bool exploreCanJson(Map<String, dynamic>? json) => false;
  Explore? exploreFromJson(Map<String, dynamic>? json) => null;
}

