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
import 'package:illinois/model/Video.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/apphelp/AppHelpVideoTutorialPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AppHelpVideoTutorialListPanel extends StatefulWidget {
  final List<Video>? videoTutorials;

  AppHelpVideoTutorialListPanel({this.videoTutorials});

  @override
  State<AppHelpVideoTutorialListPanel> createState() => _AppHelpVideoTutorialListPanelState();
}

class _AppHelpVideoTutorialListPanelState extends State<AppHelpVideoTutorialListPanel> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Styles().colors.background,
        appBar: HeaderBar(title: Localization().getStringEx("panel.settings.video_tutorials.header.title", "Video Tutorials")),
        body: _buildContent());
  }

  Widget _buildContent() {
    if (CollectionUtils.isEmpty(widget.videoTutorials)) {
      return Center(
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(Localization().getStringEx("panel.settings.video_tutorials.empty.msg", "There are no video tutorials."),
                  style: Styles().textStyles.getTextStyle("widget.message.large.fat"))));
    }
    List<Widget> contentList = <Widget>[];
    for (Video video in widget.videoTutorials!) {
      contentList.add(_buildVideoEntry(video));
    }
    return SingleChildScrollView(child: Padding(padding: EdgeInsets.all(16), child: Column(children: contentList)));
  }

  Widget _buildVideoEntry(Video video) {
    String videoTitle =
        JsonUtils.stringValue(video.title) ?? Localization().getStringEx("panel.settings.video_tutorial.header.title", "Video Tutorial");
    return InkWell(
        onTap: () => _onTapVideoTutorial(video),
        child: Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Container(
                decoration: BoxDecoration(
                    color: Styles().colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    border: Border.all(color: Styles().colors.lightGray, width: 1)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(videoTitle,
                              style: Styles().textStyles.getTextStyle("widget.button.title.enabled")))),
                  Padding(padding: EdgeInsets.only(right: 16, top: 18, bottom: 18), child: Styles().images.getImage('chevron-right-bold', excludeFromSemantics: true))
                ]))));
  }

  void _onTapVideoTutorial(Video video) {
    Analytics().logSelect(target: 'Video Tutorial', source: widget.runtimeType.toString(), attributes: video.analyticsAttributes);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AppHelpVideoTutorialPanel(videoTutorial: video)));
  }
}
