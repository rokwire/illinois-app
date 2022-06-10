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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/canvas/CanvasCourseHomePanel.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/gies/CheckListPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class AcademicsPanel extends StatefulWidget {
  AcademicsPanel();

  @override
  _AcademicsPanelState createState() => _AcademicsPanelState();
}

class _AcademicsPanelState extends State<AcademicsPanel>
    with AutomaticKeepAliveClientMixin<AcademicsPanel>
    implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, [FlexUI.notifyChanged, Auth2.notifyLoginChanged]);

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _updateState();
    } else if (name == Auth2.notifyLoginChanged) {
      _updateState();
    }
  }

  // AutomaticKeepAliveClientMixin

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.academics.header.title', 'Academics')),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child: Column(children: <Widget>[Expanded(child: _buildContent())])),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: null,
    );
  }

  // Widgets

  Widget _buildContent() {
    return Padding(padding: EdgeInsets.all(16), child: Column(children: _buildContentWidgets()));
  }

  List<Widget> _buildContentWidgets() {
    List<String>? contentCodes = JsonUtils.listStringsValue(FlexUI()['academics']);
    List<Widget> widgetList = [];
    if (contentCodes != null) {
      for (String code in contentCodes) {
        Widget? widget = _buildWidgetFromCode(code);
        if (widget != null) {
          widgetList.add(Padding(padding: EdgeInsets.only(bottom: 10), child: widget));
        }
      }
    }
    return widgetList;
  }

  Widget? _buildWidgetFromCode(String? code) {
    if (code == 'gies_checklist') {
      return _buildRibbonButtonWidget(
          label: Localization().getStringEx('panel.academics.gies_checklist.button.title', 'iDegrees New Student Checklist'),
          onTap: _onTapGiesChecklist);
    } else if (code == 'new_student_checklist') {
      return _buildRibbonButtonWidget(
          label: Localization().getStringEx('panel.academics.new_student_checklist.button.title', 'New Student Checklist'),
          onTap: _onTapNewStudentChecklist);
    } else if (code == 'canvas_courses') {
      return _buildRibbonButtonWidget(
          label: Localization().getStringEx('panel.academics.courses.button.title', 'Courses'), onTap: _onTapCanvasCourses);
    } else if (code == 'academics_events') {
      return _buildRibbonButtonWidget(
          label: Localization().getStringEx('panel.academics.events.button.title', 'Academics Events'), onTap: _onTapAcademicsEvents);
    } else if (code == 'my_illini') {
      return _buildRibbonButtonWidget(
          label: Localization().getStringEx('panel.academics.my_illini.button.title', 'My Illini'), onTap: _onTapMyIllini);
    } else {
      return null;
    }
  }

  Widget _buildRibbonButtonWidget({required String label, void Function()? onTap}) {
    return RibbonButton(
        label: label,
        border: Border.all(color: Styles().colors!.lightGray!, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(5)),
        onTap: onTap);
  }

  Future<void> _onPullToRefresh() async {
    _updateState();
  }

  void _onTapGiesChecklist() {
    Analytics().logSelect(target: "Gies Checklist");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CheckListPanel(contentKey: 'gies')));
  }

  void _onTapNewStudentChecklist() {
    Analytics().logSelect(target: "New Student Checklist");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CheckListPanel(contentKey: 'uiuc_student')));
  }

  void _onTapCanvasCourses() {
    //TBD: DD - implement Canvas Courses List Panel and push it from here
    Analytics().logSelect(target: "Canvas Courses");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasCourseHomePanel()));
  }

  void _onTapAcademicsEvents() {
    Analytics().logSelect(target: "Academics Events");
    ExploreFilter initialFilter = ExploreFilter(type: ExploreFilterType.categories, selectedIndexes: {2}); // index 2 is "Academic"
    Navigator.push(
        context, CupertinoPageRoute(builder: (context) => ExplorePanel(initialItem: ExploreItem.Events, initialFilter: initialFilter)));
  }

  void _onTapMyIllini() {
    Analytics().logSelect(target: "My Illini");
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context,
          Localization().getStringEx('widget.home.campus_resources.label.my_illini.offline', 'My Illini not available while offline.'));
    } else if (StringUtils.isNotEmpty(Config().myIlliniUrl)) {
      // Please make this use an external browser
      // Ref: https://github.com/rokwire/illinois-app/issues/1110
      launch(Config().myIlliniUrl!);

      //
      // Until webview_flutter get fixed for the dropdowns we will continue using it as a webview plugin,
      // but we will open in an external browser all problematic pages.
      // The other plugin doesn't work with VoiceOver
      // Ref: https://github.com/rokwire/illinois-client/issues/284
      //      https://github.com/flutter/plugins/pull/2330
      //
      // if (Platform.isAndroid) {
      //   launch(Config().myIlliniUrl);
      // }
      // else {
      //   String myIlliniPanelTitle = Localization().getStringEx(
      //       'widget.home.campus_resources.header.my_illini.title', 'My Illini');
      //   Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: Config().myIlliniUrl, title: myIlliniPanelTitle,)));
      // }
    }
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }
}
