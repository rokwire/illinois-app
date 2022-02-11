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
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/canvas/CanvasAccountNotificationDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CanvasAccountNotificationsPanel extends StatefulWidget {

  @override
  _CanvasAccountNotificationsPanelState createState() => _CanvasAccountNotificationsPanelState();
}

class _CanvasAccountNotificationsPanelState extends State<CanvasAccountNotificationsPanel> {
  List<CanvasAccountNotification>? _notifications;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx('panel.canvas_notifications.header.title', 'Account Notifications'),
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0)
        )
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
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
            textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18))));
  }

  Widget _buildEmptyContent() {
    return Center(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 28), child: Text(Localization().getStringEx('panel.canvas_notifications.empty.msg', 'There are no account notifications.'),
            textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18))));
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
                        style: TextStyle(fontSize: 14, color: Styles().colors!.fillColorPrimaryVariant, fontFamily: Styles().fontFamilies!.bold)))
                  ]),
                  Padding(padding: EdgeInsets.only(top: 5), child: Row(children: [Expanded(child: Text(StringUtils.ensureNotEmpty(notification.startAtDisplayDate),
                        style: TextStyle(fontSize: 14, fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.textSurface)))]))
                ]))));
  }

  void _onTapNotification(CanvasAccountNotification notification) {
    Analytics().logSelect(target: "Notification");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CanvasAccountNotificationDetailPanel(notification: notification)));
  }

  void _loadNotifications() {
    _increaseProgress();
    Canvas().loadAccountNotifications().then((notifications) {
      _notifications = notifications;
      _decreaseProgress();
    });
  }

  void _increaseProgress() {
    _loadingProgress++;
    if (mounted) {
      setState(() {});
    }
  }

  void _decreaseProgress() {
    _loadingProgress--;
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isLoading {
    return (_loadingProgress > 0);
  }
}
