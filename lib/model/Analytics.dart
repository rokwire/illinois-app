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

/////////////////////////
// AnalyticsFeature

class AnalyticsFeature {
  final String name;
  final dynamic _key;

  const AnalyticsFeature(this.name, { dynamic key}) :
    _key = key;

  bool matchKey(String className) {
    dynamic key = _key ?? name;
    if (key is String) {
      return className.contains(RegExp(key, caseSensitive: false));
    }
    else if ((key is List) || (key is Set)) {
      for (dynamic keyEntry in key) {
        if ((keyEntry is String) &&  className.contains(RegExp(keyEntry, caseSensitive: false))) {
          return true;
        }
      }
    }
    return false;
  }
}

/////////////////////////
// AnalyticsPage

abstract class AnalyticsInfo {
  String? get analyticsPageName => null;
  Map<String, dynamic>? get analyticsPageAttributes => null;
  AnalyticsFeature? get analyticsFeature => null;
}

