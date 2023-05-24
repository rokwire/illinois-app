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

import 'package:flutter/material.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CanvasCalendarEventDetailPanel extends StatefulWidget {
  final int eventId;
  CanvasCalendarEventDetailPanel({required this.eventId});

  @override
  _CanvasCalendarEventDetailPanelState createState() => _CanvasCalendarEventDetailPanelState();
}

class _CanvasCalendarEventDetailPanelState extends State<CanvasCalendarEventDetailPanel> implements NotificationsListener {
  CanvasCalendarEvent? _event;
  bool _loading = false;

  @override
  void initState() {
    NotificationService().subscribe(this, Auth2UserPrefs.notifyFavoritesChanged);
    _loadEvent();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  void _loadEvent() {
    _setLoading(true);
    Canvas().loadCalendarEvent(widget.eventId).then((event) {
      _event = event;
      _setLoading(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.canvas_calendar_event.header.title', 'Calendar Event')
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return _buildLoadingContent();
    } else if (_event != null) {
      return _buildEventContent();
    } else {
      return _buildErrorContent();
    }
  }

  Widget _buildLoadingContent() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorContent() {
    return Center(
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
                Localization()
                    .getStringEx('panel.canvas_calendar_event.load.failed.error.msg', 'Failed to load event. Please, try again later.'),
                textAlign: TextAlign.center,
                style:  Styles().textStyles?.getTextStyle("widget.message.medium.thin"))));
  }

  Widget _buildEventContent() {
    bool isFavorite = Auth2().isFavorite(_event);

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(children: [
                Row(children: [
                  Expanded(
                      child: Text(StringUtils.ensureNotEmpty(_event?.title),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style:  Styles().textStyles?.getTextStyle("panel.canvas.detail.large")))
                ]),
                Visibility(
                    visible: Auth2().canFavorite,
                    child: Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              Analytics().logSelect(target: "Favorite: ${_event?.title}");
                              Auth2().prefs?.toggleFavorite(_event);
                            },
                            child: Semantics(
                                container: true,
                                label: isFavorite
                                    ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites')
                                    : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                                hint: isFavorite
                                    ? Localization().getStringEx('widget.card.button.favorite.off.hint', '')
                                    : Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
                                button: true,
                                excludeSemantics: true,
                                child: Container(
                                    padding: EdgeInsets.only(left: 24, bottom: 24),
                                    child: Image.asset(isFavorite ? 'images/icon-star-blue.png' : 'images/icon-star-gray-frame-thin.png',
                                        excludeFromSemantics: true))))))
              ]),
              Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(Localization().getStringEx('panel.canvas_calendar_event.calendar.label', 'Calendar:'),
                        style:  Styles().textStyles?.getTextStyle("widget.title.regular.fat")),
                    Expanded(
                        child: Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Text(StringUtils.ensureNotEmpty(_event?.contextName),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                                style:  Styles().textStyles?.getTextStyle("widget.info.regular.thin"))))
                  ])),
              Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(Localization().getStringEx('panel.canvas_calendar_event.date_time.label', 'Date & Time:'),
                        style:  Styles().textStyles?.getTextStyle("widget.title.regular.fat")),
                    Expanded(
                        child: Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Text(StringUtils.ensureNotEmpty(_event?.displayDateTime),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style:  Styles().textStyles?.getTextStyle("widget.info.regular.thin"))))
                  ]))
            ])));
  }

  void _setLoading(bool loading) {
    _loading = loading;
    if (mounted) {
      setState(() {});
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setState(() {});
    }
  }
}