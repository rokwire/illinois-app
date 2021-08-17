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

import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/StudentGuide.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/ui/guide/StudentGuideEntryCard.dart';
import 'package:illinois/ui/guide/StudentGuideListPanel.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/SectionTitlePrimary.dart';
import 'package:illinois/utils/Utils.dart';

class HomeCampusRemindersWidget extends StatefulWidget {
  final StreamController<void> refreshController;

  HomeCampusRemindersWidget({this.refreshController});

  @override
  _HomeCampusRemindersWidgetState createState() => _HomeCampusRemindersWidgetState();
}

class _HomeCampusRemindersWidgetState extends State<HomeCampusRemindersWidget> implements NotificationsListener {
  static const int _maxItems = 3;

  List<dynamic> _reminderItems;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      StudentGuide.notifyChanged,
      User.notifyRolesUpdated,
      AppLivecycle.notifyStateChanged,
      Auth2.notifyCardChanged,
    ]);

    if (widget.refreshController != null) {
      widget.refreshController.stream.listen((_) {
        StudentGuide().refresh();
      });
    }

    _reminderItems = StudentGuide().remindersList;
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == StudentGuide.notifyChanged) {
      _updateReminderItems();
    }
    else if (name == User.notifyRolesUpdated) {
      _updateReminderItems();
    }
    else if (name == Auth2.notifyCardChanged) {
      _updateReminderItems();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      if (param == AppLifecycleState.resumed) {
        _updateReminderItems(); // update on each resume for time interval filtering
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(visible: AppCollection.isCollectionNotEmpty(_reminderItems), child:
      Column(children: [
          SectionTitlePrimary(
            title: Localization().getStringEx('widget.home_campus_reminders.label.campus_reminders', 'CAMPUS REMINDERS'),
            iconPath: 'images/campus-tools.png',
            children: _buildRemindersList()
          ),
        ]),
    );
  }

  void _updateReminderItems() {
    List<dynamic> reminderItems = StudentGuide().remindersList;
    if (!DeepCollectionEquality().equals(_reminderItems, reminderItems)) {
      setState(() {
        _reminderItems = reminderItems;
      });
    }
  }

  List<Widget> _buildRemindersList() {
    List<Widget> contentList = <Widget>[];
    if (_reminderItems != null) {
      int remindersCount = min(_reminderItems.length, _maxItems);
      for (int index = 0; index < remindersCount; index++) {
        dynamic reminderItem = _reminderItems[index];
        if (contentList.isNotEmpty) {
          contentList.add(Container(height: 8,));
        }
        contentList.add(StudentGuideEntryCard(AppJson.mapValue(reminderItem)));
      }
      if (_maxItems < _reminderItems.length) {
        contentList.add(Container(height: 16,));
        contentList.add(ScalableRoundedButton(
          label: Localization().getStringEx('widget.home_campus_reminders.button.more.title', 'View All'),
          hint: Localization().getStringEx('widget.home_campus_reminders.button.more.hint', 'Tap to view all reminders'),
          borderColor: Styles().colors.fillColorSecondary,
          textColor: Styles().colors.fillColorPrimary,
          backgroundColor: Styles().colors.white,
          onTap: () => _showAll(),
        ));
      }
    }
    return contentList;
  }

  void _showAll() {
    Analytics.instance.logSelect(target: "HomeCampusRemindersWidget View All");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentGuideListPanel(contentList: _reminderItems, contentTitle: Localization().getStringEx('panel.student_guide_list.label.campus_reminders.section', 'Campus Reminders'))));
  }
}

