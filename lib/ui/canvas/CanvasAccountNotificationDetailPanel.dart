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
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class CanvasAccountNotificationDetailPanel extends StatefulWidget {
  final CanvasAccountNotification notification;
  CanvasAccountNotificationDetailPanel({required this.notification});

  @override
  _CanvasAccountNotificationDetailPanelState createState() => _CanvasAccountNotificationDetailPanelState();
}

class _CanvasAccountNotificationDetailPanelState extends State<CanvasAccountNotificationDetailPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.canvas_notification.header.title', 'Notification')),
      body: _buildContent(),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    return _buildAnnouncementContent();
  }

  Widget _buildAnnouncementContent() {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(StringUtils.ensureNotEmpty(widget.notification.subject),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style:  Styles().textStyles?.getTextStyle("panel.canvas.text.medium")))
              ]),
              Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Row(children: [
                    Expanded(
                        child: Text(StringUtils.ensureNotEmpty(widget.notification.startAtDisplayDate),
                            style:  Styles().textStyles?.getTextStyle("widget.info.small") 
                          ))
                  ])),
              Visibility(
                  visible: StringUtils.isNotEmpty(widget.notification.message),
                  child: Html(data: widget.notification.message, onLinkTap: (url, context, element) => _onTapLink(url), style: {
                    "body": Style(
                        color: Styles().colors!.textSurfaceAccent,
                        fontFamily: Styles().fontFamilies!.bold,
                        fontSize: FontSize(16),
                        padding: EdgeInsets.zero,
                        margin: Margins.zero)
                  }))
            ])));
  }

  void _onTapLink(String? url) {
    if (StringUtils.isNotEmpty(url)) {
      if (UrlUtils.launchInternal(url)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    }
  }
}
