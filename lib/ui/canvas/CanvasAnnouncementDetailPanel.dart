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
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class CanvasAnnouncementDetailPanel extends StatefulWidget {
  final CanvasDiscussionTopic announcement;
  CanvasAnnouncementDetailPanel({required this.announcement});

  @override
  _CanvasAnnouncementDetailPanelState createState() => _CanvasAnnouncementDetailPanelState();
}

class _CanvasAnnouncementDetailPanelState extends State<CanvasAnnouncementDetailPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.canvas_announcement.header.title', 'Announcement'),
      ),
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
              Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                    child: Text(StringUtils.ensureNotEmpty(widget.announcement.title),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style:  Styles().textStyles?.getTextStyle("panel.canvas.text.medium"))),
                Padding(
                    padding: EdgeInsets.only(left: 7),
                    child: Text(StringUtils.ensureNotEmpty(widget.announcement.postedAtDisplayDate),
                        style:  Styles().textStyles?.getTextStyle("widget.info.small")))
              ]),
              Visibility(
                  visible: StringUtils.isNotEmpty(widget.announcement.author?.displayName),
                  child: Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Text(StringUtils.ensureNotEmpty(widget.announcement.author?.displayName),
                          style:  Styles().textStyles?.getTextStyle("widget.info.small")))),
              Visibility(
                  visible: StringUtils.isNotEmpty(widget.announcement.message),
                  child: Html(data: widget.announcement.message, style: {
                    "body": Style(
                        color: Styles().colors!.textSurfaceAccent,
                        fontFamily: Styles().fontFamilies!.bold,
                        fontSize: FontSize(16),
                        padding: EdgeInsets.zero,
                        margin: Margins.zero)
                  })),
              _buildAttachmentsContent()
            ])));
  }

  Widget _buildAttachmentsContent() {
    if (CollectionUtils.isEmpty(widget.announcement.attachments)) {
      return Container();
    }
    List<Widget> attachmentWidgetList = [];
    for (CanvasFile attachment in widget.announcement.attachments!) {
      attachmentWidgetList.add(Padding(
          padding: EdgeInsets.only(top: 5),
          child: GestureDetector(
              onTap: () => _onTapAttachment(attachment),
              child: Text(StringUtils.ensureNotEmpty(attachment.displayName),
                  style:  Styles().textStyles?.getTextStyle("widget.link.button.title.small")))));
    }
    return Padding(
        padding: EdgeInsets.only(top: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: attachmentWidgetList));
  }

  void _onTapAttachment(CanvasFile attachment) {
    String? url = attachment.url;
    if (StringUtils.isNotEmpty(url)) {
      Uri? uri = Uri.tryParse(url!);
      if (uri != null) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
