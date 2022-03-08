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

import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/polls.dart' as rokwire;
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:sprintf/sprintf.dart';

class Polls extends rokwire.Polls implements NotificationsListener {

  // Singletone Factory

  @protected
  Polls.internal() : super.internal();

  factory Polls() => ((rokwire.Polls.instance is Polls) ? (rokwire.Polls.instance as Polls) : (rokwire.Polls.instance = Polls.internal()));

  // Service

  @override
  void createService() {
    super.createService();
    NotificationService().subscribe(this, FirebaseMessaging.notifyPollOpen);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this, FirebaseMessaging.notifyPollOpen);
    super.destroyService();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    super.onNotification(name, param);
    
    if (super.enabled) {
      if (name == FirebaseMessaging.notifyPollOpen) {
        dynamic pollId = (param is Map) ? param['poll_id'] : null;
        if (pollId is String) {
          onPollStarted(pollId);
        }
      }
    }
  }

  // Implementation

  @protected
  String getPollNotificationMessage(Poll poll) {
    // Localize prompt
    String creator = poll.creatorUserName ?? Localization().getStringEx('panel.poll_prompt.text.someone', 'Someone');
    return sprintf(Localization().getStringEx('panel.poll_prompt.text.wants_to_know', '%s wants to know'), [creator]);
  }

  static String localizedErrorString(Object error) {
    if (error is rokwire.PollsException) {
      String errorText;
      switch(error.error) {
        case rokwire.PollsError.serverResponse: errorText = Localization().getStringEx('logic.general.response_error', 'Server Response Error'); break;
        case rokwire.PollsError.serverResponseContent: errorText = Localization().getStringEx('logic.general.invalid_response', 'Invalid Server Response'); break;
        case rokwire.PollsError.internal: errorText = Localization().getStringEx('logic.general.internal_error', 'Internal Error Occured'); break;
      }
      return (error.descrition != null) ? '$errorText: ${error.descrition}' : errorText;
    }
    else  {
      return error.toString();
    }
  }
}
