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

import 'package:collection/collection.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/main.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/guide/GuideEntryCard.dart';
import 'package:illinois/ui/guide/GuideListPanel.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeCampusRemindersWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeCampusRemindersWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.campus_reminders.label.campus_reminders', 'Campus Reminders');
  
  @override
  _HomeCampusRemindersWidgetState createState() => _HomeCampusRemindersWidgetState();
}

class _HomeCampusRemindersWidgetState extends State<HomeCampusRemindersWidget> implements NotificationsListener {

  List<Map<String, dynamic>>? _reminderItems;
  PageController? _pageController;
  final double _pageSpacing = 16;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      Config.notifyConfigChanged,
      Guide.notifyChanged,
      Auth2UserPrefs.notifyRolesChanged,
      AppLivecycle.notifyStateChanged,
      Auth2.notifyCardChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          Guide().refresh();
        }
      });
    }

    double screenWidth = MediaQuery.of(App.instance?.currentContext ?? context).size.width;
    double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
    _pageController = PageController(viewportFraction: pageViewport);

    _reminderItems = Guide().remindersList;
  }

  @override
  void dispose() {
    _pageController?.dispose();
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Config.notifyConfigChanged) {
      if (mounted) {
        setState(() {});
      }
    }
    else if (name == Guide.notifyChanged) {
      _updateReminderItems();
    }
    else if (name == Auth2UserPrefs.notifyRolesChanged) {
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
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: Localization().getStringEx('widget.home.campus_reminders.label.campus_reminders', 'Campus Reminders'),
      titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
      childPadding: EdgeInsets.zero,
      child: _buildContent()
    );
  }

  Widget _buildContent() {
    return  (_reminderItems?.isEmpty ?? true) ? HomeMessageCard(
      title: Localization().getStringEx("widget.home.campus_reminders.text.empty", "Whoops! Nothing to see here."),
      message: Localization().getStringEx("widget.home.campus_reminders.text.empty.description", "There are no active Campus Reminders."),
    ) : _buildRemindersContent();
  }

  Widget _buildRemindersContent() {
    Widget contentWidget;
    int visibleCount = _reminderItems?.length ?? 0; // Config().homeCampusRemindersCount
    if (1 < visibleCount) {
      
      double pageHeight = (18 + 16) * MediaQuery.of(context).textScaleFactor + 4 + 8 + 2 * 16;

      List<Widget> pages = <Widget>[];
      for (int index = 0; index < visibleCount; index++) {
        pages.add(Padding(padding: EdgeInsets.only(right: _pageSpacing + 2, bottom: 2), child:
          GuideEntryCard(JsonUtils.mapValue(_reminderItems![index]))
        ));
      }

      contentWidget = Container(constraints: BoxConstraints(minHeight: pageHeight), child:
        ExpandablePageView(controller: _pageController, children: pages, estimatedPageSize: pageHeight),
      );

    }
    else {
      contentWidget = Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        GuideEntryCard(_reminderItems?.first)
      );
    }
    return Column(children: <Widget>[
      contentWidget,
      LinkButton(
        title: Localization().getStringEx('widget.home.campus_reminders.button.all.title', 'View All'),
        hint: Localization().getStringEx('widget.home.campus_reminders.button.all.hint', 'Tap to view all reminders'),
        onTap: _onViewAll,
      ),
    ]);
  }

  void _updateReminderItems() {
    List<Map<String, dynamic>>? reminderItems = Guide().remindersList;
    if (!DeepCollectionEquality().equals(_reminderItems, reminderItems)) {
      setState(() {
        _reminderItems = reminderItems;
      });
    }
  }

  void _onViewAll() {
    Analytics().logSelect(target: "HomeCampusRemindersWidget View All");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(contentList: _reminderItems, contentTitle: Localization().getStringEx('panel.guide_list.label.campus_reminders.section', 'Campus Reminders'))));
  }
}

