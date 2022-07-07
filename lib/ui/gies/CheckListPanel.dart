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
import 'package:illinois/ui/gies/CheckListContentWidget.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';

class CheckListPanel extends StatefulWidget {
  final String contentKey;

  const CheckListPanel({Key? key, required this.contentKey}) : super(key: key);

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
    if (contentKey == "gies") {
      return Localization().getStringEx('widget.checklist.gies.offline', 'iDegrees New Student Checklist not available while offline.');
    } else if (contentKey == "new_student") {
      return Localization().getStringEx('widget.checklist.uiuc.offline', 'New Student Checklist not available while offline.');
    }
  }

  static String? _loggedOutMessage(String contentKey) {
    if (contentKey == "gies") {
      return Localization().getStringEx('widget.checklist.gies.logged_out', 'You need to be logged in to access iDegrees New Student Checklist.');
    } else if (contentKey == "new_student") {
      return Localization().getStringEx('widget.checklist.uiuc.logged_out', 'You need to be logged in to access New Student Checklist.');
    }
  }

  @override
  State<StatefulWidget> createState() => _CheckListPanelState();
}

class _CheckListPanelState extends State<CheckListPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: _title), body: SingleChildScrollView(child: CheckListContentWidget(contentKey: widget.contentKey)));
  }

  String get _title {
    if (widget.contentKey == "gies") {
      return Localization().getStringEx('widget.checklist.gies.title', 'iDegrees New Student Checklist');
    } else if (widget.contentKey == "new_student") {
      return Localization().getStringEx('widget.checklist.uiuc.title', 'New Student Checklist');
    }

    return "";
  }
}
