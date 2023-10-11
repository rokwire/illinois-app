/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/canvas/CanvasAccountNotificationDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/utils/AppUtils.dart';

class CanvasAccountNotificationsPanel extends StatefulWidget {

  @override
  _CanvasAccountNotificationsPanelState createState() => _CanvasAccountNotificationsPanelState();
}

class _CanvasAccountNotificationsPanelState extends State<CanvasAccountNotificationsPanel> {
  List<CanvasAccountNotification>? _notifications;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.canvas_notifications.header.title', 'Account Notifications'),
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return _buildLoadingContent();
    }
    if (_notifications != null) {
      if (_notifications!.isNotEmpty) {
        return _buildNotificationsContent();
      } else {
        return _buildEmptyContent();
      }
    } else {
      return _buildErrorContent();
    }
  }

  Widget _buildLoadingContent() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorContent() {
    return Center(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 28), child: Text(Localization().getStringEx('panel.canvas_notifications.load.failed.error.msg', 'Failed to load account notifications. Please, try again later.'),
            textAlign: TextAlign.center, style:  Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildEmptyContent() {
    return Center(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 28), child: Text(Localization().getStringEx('panel.canvas_notifications.empty.msg', 'There are no account notifications.'),
            textAlign: TextAlign.center, style:  Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildNotificationsContent() {
    if (CollectionUtils.isEmpty(_notifications)) {
      return Container();
    }

    List<Widget> notificationWidgetList = [];
    for (CanvasAccountNotification notification in _notifications!) {
      notificationWidgetList.add(_buildNotificationItem(notification));
    }

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: notificationWidgetList)));
  }

  Widget _buildNotificationItem(CanvasAccountNotification notification) {
    return Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: GestureDetector(
            onTap: () => _onTapNotification(notification),
            child: Container(
                decoration: BoxDecoration(
                    color: Styles().colors!.white!,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1)),
                padding: EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(StringUtils.ensureNotEmpty(notification.subject), maxLines: 2, overflow: TextOverflow.ellipsis,
                        style:  Styles().textStyles?.getTextStyle("panel.canvas.text.small")))
                  ]),
                  Padding(padding: EdgeInsets.only(top: 5), child: Row(children: [Expanded(child: Text(StringUtils.ensureNotEmpty(notification.startAtDisplayDate),
                        style:  Styles().textStyles?.getTextStyle("widget.info.small")))]))
                ]))));
  }

  void _onTapNotification(CanvasAccountNotification notification) {
    Analytics().logSelect(target: "Notification");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasAccountNotificationDetailPanel(notification: notification)));
  }

  void _loadNotifications() {
    setStateIfMounted(() {
      _loading = true;
    });
    Canvas().loadAccountNotifications().then((notifications) {
      setStateIfMounted(() {
        _notifications = notifications;
        _loading = false;
      });
    });
  }
}