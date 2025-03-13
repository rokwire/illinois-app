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

import 'package:rokwire_plugin/ext/uri.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SkillsSelfEvaluation with Service implements NotificationsListener {
  static const String notifyLaunchSkillsSelfEvaluation = "edu.illinois.rokwire.skills_self_evaluation.launch";

  // Singleton Factory

  static SkillsSelfEvaluation? _instance;

  factory SkillsSelfEvaluation() => _instance ?? (_instance = SkillsSelfEvaluation.internal());

  SkillsSelfEvaluation.internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      DeepLink.notifyUiUri,
    ]);
    super.createService();
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return {DeepLink()};
  }

  // DeepLinks

  static String get skillsSelfEvaluationUrl => '${DeepLink().appUrl}/skills_self_evaluation';

  void _onDeepLinkUri(Uri? uri) {
    if ((uri != null) && uri.matchDeepLinkUri(Uri.tryParse(skillsSelfEvaluationUrl))) {
      NotificationService().notify(notifyLaunchSkillsSelfEvaluation);
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUiUri) {
      _onDeepLinkUri(JsonUtils.cast(param));
    }
  }
}
