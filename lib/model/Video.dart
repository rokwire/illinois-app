/*
 * Copyright 2022 Board of Trustees of the University of Illinois.
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

import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Video {
  final String? id;
  final String? title;
  final String? videoUrl;
  final String? thumbUrl;
  final String? ccUrl;

  Video({this.id, this.title, this.videoUrl, this.thumbUrl, this.ccUrl});

  static Video? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return Video(id: json['id'], title: json['title'], videoUrl: json['video_url'], thumbUrl: json['image_url'], ccUrl: json['cc_url']);
  }

  static List<Video>? listFromJson({List<dynamic>? jsonList, Map<String, dynamic>? contentStrings}) {
    List<Video>? result;
    if (jsonList != null) {
      result = <Video>[];
      for (dynamic videoJsonEntry in jsonList) {
        String? videoId = videoJsonEntry['id'];
        String? videoTitle = Localization().getContentString(contentStrings, videoId);
        videoJsonEntry['title'] = videoTitle;
        ListUtils.add(result, Video.fromJson(JsonUtils.mapValue(videoJsonEntry)));
      }
    }
    return result;
  }
}
