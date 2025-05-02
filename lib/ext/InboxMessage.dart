/*
 * Copyright 2024 Board of Trustees of the University of Illinois.
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

import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Config.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

extension InboxMessageExt on InboxMessage {
  String get displaySender {
    if (sender?.type == InboxSenderType.system) {
      return 'System';
    } else if (sender?.type == InboxSenderType.user) {
      return sender?.user?.name ?? 'Unknown';
    } else {
      return 'Unknown';
    }
  }

  String? get displayInfo {
    if (sender?.type == InboxSenderType.user) {
      return displayUserInfo;
    } else {
      return displaySystemInfo;
    }
  }

  String? get displayUserInfo {
    DateTime? deviceDateTime = AppDateTime().getDeviceTimeFromUtcTime(dateTimeSentUtc);
    if (deviceDateTime != null) {
      DateTime now = DateTime.now();
      if (deviceDateTime.compareTo(now) < 0) {
        Duration difference = DateTime.now().difference(deviceDateTime);
        if (difference.inSeconds < 60) {
          return 'Sent by $displaySender now.';
        } else if (difference.inMinutes < 60) {
          return sprintf((difference.inMinutes != 1) ? 'Sent by %s about %s minutes ago.' : 'Sent by %s about a minute ago.',
              [displaySender, difference.inMinutes]);
        } else if (difference.inHours < 24) {
          return sprintf((difference.inHours != 1) ? 'Sent by %s about %s hours ago.' : 'Sent by %s about an hour ago.',
              [displaySender, difference.inHours]);
        } else if (difference.inDays < 30) {
          return sprintf((difference.inDays != 1) ? 'Sent by %s about %s days ago.' : 'Sent by %s about a day ago.',
              [displaySender, difference.inDays]);
        } else {
          int differenceInMonths = difference.inDays ~/ 30;
          if (differenceInMonths < 12) {
            return sprintf((differenceInMonths != 1) ? 'Sent by %s about %s months ago.' : 'Sent by %s about a month ago.',
                [displaySender, differenceInMonths]);
          }
        }
      }
      String value = DateFormat("MMM dd, yyyy").format(deviceDateTime);
      return sprintf('Sent by %s on %s.', [displaySender, value]);
    } else {
      return "Sent by $displaySender";
    }
  }

  String? get displaySystemInfo {
    DateTime? deviceDateTime = AppDateTime().getDeviceTimeFromUtcTime(dateTimeSentUtc);
    if (deviceDateTime != null) {
      DateTime now = DateTime.now();
      if (deviceDateTime.compareTo(now) < 0) {
        Duration difference = DateTime.now().difference(deviceDateTime);
        if (difference.inSeconds < 60) {
          return 'Sent now.';
        } else if (difference.inMinutes < 60) {
          return sprintf((difference.inMinutes != 1) ? 'Sent about %s minutes ago.' : 'Sent about a minute ago.', [difference.inMinutes]);
        } else if (difference.inHours < 24) {
          return sprintf((difference.inHours != 1) ? 'Sent about %s hours ago.' : 'Sent about an hour ago.', [difference.inHours]);
        } else if (difference.inDays < 30) {
          return sprintf((difference.inDays != 1) ? 'Sent about %s days ago.' : 'Sent about a day ago.', [difference.inDays]);
        } else {
          int differenceInMonths = difference.inDays ~/ 30;
          if (differenceInMonths < 12) {
            return sprintf((differenceInMonths != 1) ? 'Sent about %s months ago.' : 'Sent about a month ago.', [differenceInMonths]);
          }
        }
      }
      String value = DateFormat("MMM dd, yyyy").format(deviceDateTime);
      return sprintf('Sent on %s.', [value]);
    } else {
      return "Sent";
    }
  }

  String? get displayBody => (body != null) ? StringUtils.truncate(value: body!, atLength: Config().notificationBodyMaxLength) : body;

  bool get isMuted => (mute == true);

  bool get isRead => (read == true);
}
