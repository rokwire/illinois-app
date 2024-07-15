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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/CheckList.dart';
import 'package:illinois/ui/gies/CheckListContentWidget.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';

class CheckListPanel extends StatelessWidget with AnalyticsInfo {
  final String contentKey;

  const CheckListPanel({Key? key, required this.contentKey}) : super(key: key);

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.Academics;

  static void present(BuildContext context, { required String contentKey }) {
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, _offlineMessage(contentKey));
    }
    else if (!Auth2().isOidcLoggedIn) {
      AppAlert.showMessage(context, _loggedOutMessage(contentKey));
    }
    else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => CheckListPanel(contentKey: contentKey,)));
    }
  }

  static String? _offlineMessage(String contentKey) {
    if (contentKey == CheckList.giesOnboarding) {
      return Localization().getStringEx('widget.checklist.gies.offline', 'iDegrees New Student Checklist not available while offline.');
    } else if (contentKey == CheckList.uiucOnboarding) {
      return Localization().getStringEx('widget.checklist.uiuc.offline', 'New Student Checklist not available while offline.');
    } else {
      return null;
    }
  }

  static String? _loggedOutMessage(String contentKey) {
    if (contentKey == CheckList.giesOnboarding) {
      return Localization().getStringEx('widget.checklist.gies.logged_out', 'You need to be logged in with your NetID to access iDegrees New Student Checklist. Set your privacy level to 4 or 5 in your Profile. Then find the sign-in prompt under Settings.');
    } else if (contentKey == CheckList.uiucOnboarding) {
      return Localization().getStringEx('widget.checklist.uiuc.logged_out', 'You need to be logged in with your NetID to access New Student Checklist. Set your privacy level to 4 or 5 in your Profile. Then find the sign-in prompt under Settings.');
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: _title),
      body: CheckListContentWidget(contentKey: contentKey, panelDisplay: true,)
    );
  }

  String get _title {
    if (contentKey == CheckList.giesOnboarding) {
      return Localization().getStringEx('widget.checklist.gies.title', 'iDegrees New Student Checklist');
    } else if (contentKey == CheckList.uiucOnboarding) {
      return Localization().getStringEx('widget.checklist.uiuc.title', 'New Student Checklist');
    }

    return "";
  }
}
