/*
 * Copyright 2025 Board of Trustees of the University of Illinois.
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

import 'package:illinois/model/Assistant.dart';
import 'package:illinois/model/Dining.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/utils/utils.dart';

///////////////////////////////
/// Message
extension MessageExt on Message {

  List<dynamic>? get structElements {
    List<dynamic>? elements;
    if (structOutput != null) {
      List<AssistantStructOutputItem>? items = structOutput?.items;
      if ((items != null) && items.isNotEmpty) {
        elements = <dynamic>[];
        for (AssistantStructOutputItem item in items) {
          if (item.type == AssistantStructOutputItemType.event) {
            ListUtils.add(elements, Event2.fromJson(item.data));
          } else if (item.type == AssistantStructOutputItemType.dining_schedule) {
            ListUtils.add(elements, Dining.fromJson(item.data));
          }
        }
      }
    }
    return elements;
  }
}