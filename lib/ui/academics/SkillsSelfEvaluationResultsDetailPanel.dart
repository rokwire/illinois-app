// Copyright 2022 Board of Trustees of the University of Illinois.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Video.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/academics/SkillsSelfEvaluation.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:illinois/ui/settings/SettingsVideoTutorialPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/VideoPlayButton.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/web_panel.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class SkillsSelfEvaluationResultsDetailPanel extends StatelessWidget {
  final SkillsSelfEvaluationContent? content;
  final Map<String, dynamic>? params;

  SkillsSelfEvaluationResultsDetailPanel({required this.content, this.params});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.skills_self_evaluation.results_detail.header.title', 'Skills Self-Evaluation'), leading: RootHeaderBarLeading.Back,),
      body: SingleChildScrollView(child: content != null ? SectionSlantHeader(
        headerWidget: content!.header != null ? _buildHeader() : null,
        slantColor: Styles().colors?.gradientColorPrimary,
        slantPainterHeadingHeight: 0,
        backgroundColor: Styles().colors?.background,
        children: _buildContent(context),
        childrenPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        childrenAlignment: CrossAxisAlignment.start,
        allowOverlap: false,
      ) : Padding(padding: const EdgeInsets.all(24.0), child: Text(
        Localization().getStringEx("panel.skills_self_evaluation.results_detail.unavailable.message", "Detailed results content for this skill is currently unavailable."),
        style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.title'),
        textAlign: TextAlign.center,
      ))),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 100, bottom: 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16), child: Text(content!.header!.title, style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.header'), textAlign: TextAlign.center,)),
        Visibility(visible: content!.header!.moreInfo != null, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(content!.header!.moreInfo ?? '', 
            style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.header.description'), 
            textAlign: TextAlign.center,
          )
        )),
      ]),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Styles().colors?.fillColorPrimaryVariant ?? Colors.transparent,
            Styles().colors?.gradientColorPrimary ?? Colors.transparent,
          ]
        )
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, {List<SkillsSelfEvaluationSection>? sections}) {
    List<Widget> contentWidgets = [];
    for (SkillsSelfEvaluationSection section in sections ?? content?.sections ?? []) {
      Widget titleWidget = Text(
        section.title,
        style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.title'),
        textAlign: TextAlign.start,
      );

      if (section.subtitle != null) {
        contentWidgets.add(titleWidget);
        contentWidgets.add(Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(
          section.subtitle!,
          style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.body'),
          textAlign: TextAlign.start,
        )));
      } else {
        contentWidgets.add(Padding(padding: const EdgeInsets.only(bottom: 16), child: titleWidget));
      }
      
      switch (section.type) {
        case "text":
          if (section.body != null) {
            RegExp regExp = RegExp(r"%{(.*?)}");
            Iterable<Match> matches = regExp.allMatches(section.body!);

            if (CollectionUtils.isEmpty(matches)) {
              contentWidgets.add(Text(
                section.body!,
                style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.body'),
                textAlign: TextAlign.start,
              ));
            } else if (matches.elementAt(0).start > 0) {
              contentWidgets.add(Text(
                section.body!.substring(0, matches.elementAt(0).start),
                style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.body'),
                textAlign: TextAlign.start,
              ));
            }

            for (int i = 0; i < matches.length; i++) {
              Match match = matches.elementAt(i);
              String? key = match.group(1);
              List<String>? parts = key?.split(".");

              if (CollectionUtils.isNotEmpty(parts)) {
                switch (parts![0]) {
                  case "links":
                    dynamic linkData = MapPathKey.entry(content?.links, parts.sublist(1).join('.'));
                    if (linkData is SkillsSelfEvaluationLink) {
                      contentWidgets.add(InkWell(onTap: () => _onTapLink(context, linkData), child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: linkData.text,
                              style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.link'),
                            ),
                            WidgetSpan(
                              child: linkData.icon != null ? Padding(padding: const EdgeInsets.only(left: 4.0), child: Image.asset(linkData.icon!)) : Container(),
                            ),
                          ],
                        ),
                      )));
                    }
                    break;
                  case "widget":
                    dynamic widgetData = MapPathKey.entry(params, parts.sublist(1).join('.'));
                    if (widgetData is String) {
                      contentWidgets.add(Text(
                        widgetData,
                        style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.body'),
                      ));
                    }
                    break;
                }
              }

              if (match.end < section.body!.length) {
                contentWidgets.add(Text(
                  section.body!.substring(match.end, (i+1 < matches.length) ? matches.elementAt(i+1).start : null),
                  style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.body'),
                  textAlign: TextAlign.start,
                ));
              }
            }
            contentWidgets.add(Container(height: 16.0));
          }
          if (CollectionUtils.isNotEmpty(section.subsections)) {
            contentWidgets.addAll(_buildContent(context, sections: section.subsections));
          }
          break;
        case "video":
          contentWidgets.add(Padding(padding: const EdgeInsets.only(bottom: 24.0, left: 24.0, right: 24.0), child: _buildVideoWidget(context, section.params ?? {})));
          break;
      }
    }
    
    return contentWidgets;
  }

  Widget _buildVideoWidget(BuildContext context, Map<String, dynamic> params) {
    Video? video = Video.fromJson(params);
    if (video == null) {
      return Container();
    }
    String? imageUrl = video.thumbUrl;
    String? title = video.title;
    final Widget emptyImagePlaceholder = Container(height: 102);
    return Container(
        decoration: BoxDecoration(
            color: Styles().colors?.white,
            boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4))),
        child: Stack(children: [
          GestureDetector(
              onTap: () => _onTapVideo(context, video),
              child: Semantics(
                  button: true,
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text(title ?? '', style: Styles().textStyles?.getTextStyle('widget.title.large.extra_fat'))),
                        Stack(alignment: Alignment.center, children: [
                          StringUtils.isNotEmpty(imageUrl)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(imageUrl!,
                                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                    return (loadingProgress == null) ? child : emptyImagePlaceholder;
                                  }))
                              : emptyImagePlaceholder,
                          VideoPlayButton()
                        ])
                      ])))),
          Container(color: Styles().colors?.accentColor3, height: 4)
        ]));
  }

  void _onTapVideo(BuildContext context, Video video) {
    Analytics().logSelect(target: 'Video', source: runtimeType.toString(), attributes: video.analyticsAttributes);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsVideoTutorialPanel(videoTutorial: video)));
  }

  void _onTapLink(BuildContext context, SkillsSelfEvaluationLink link) {
    switch (link.type) {
      case "web":
        if (link.internal && UrlUtils.launchInternal(link.url)) {
          Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: link.url)));
        } else if (link.url != null) {
          Uri? parsedUri = Uri.tryParse(link.url!);
          if (parsedUri != null) {
            launchUrl(parsedUri, mode: LaunchMode.externalApplication);
          }
        }
        break;
      case "app_panel":
        if (link.panel != null) {
          switch (link.panel) {
            case "GuideDetailPanel":
              if (link.params != null) {
                Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideDetailPanel(guideEntryId: link.params!['guideEntryId'])));
              }
          }
        }
        break;
    }
  }
}
