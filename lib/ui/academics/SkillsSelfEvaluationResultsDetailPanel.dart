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
import 'package:illinois/ui/academics/SkillsSelfEvaluation.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/web_panel.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class SkillsSelfEvaluationResultsDetailPanel extends StatefulWidget {
  final SkillsSelfEvaluationContent? content;
  final Map<String, dynamic>? params;

  SkillsSelfEvaluationResultsDetailPanel({required this.content, this.params});

  @override
  _SkillsSelfEvaluationResultsDetailPanelState createState() => _SkillsSelfEvaluationResultsDetailPanelState();
}

class _SkillsSelfEvaluationResultsDetailPanelState extends State<SkillsSelfEvaluationResultsDetailPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootBackHeaderBar(title: Localization().getStringEx('panel.skills_self_evaluation.results.header.title', 'Skills Self-Evaluation'),),
      body: widget.content != null ? SectionSlantHeader(
        header: widget.content!.header != null ? _buildHeader() : null,
        slantColor: Styles().colors?.gradientColorPrimary,
        backgroundColor: Styles().colors?.background,
        children: _buildContent(),
        childrenPadding: const EdgeInsets.only(top: 240),
        childrenAlignment: CrossAxisAlignment.start,
      ) : Padding(padding: const EdgeInsets.all(24.0), child: Text(
        Localization().getStringEx("panel.skills_self_evaluation.results_detail.missing_content", "There is no detailed results content for this skill."),
        style: TextStyle(fontFamily: "ProximaNovaBold", fontSize: 20.0, color: Styles().colors?.fillColorPrimaryVariant),
        textAlign: TextAlign.center,
      )),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 100, bottom: 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(widget.content!.header!.title, style: TextStyle(fontFamily: "ProximaNovaExtraBold", fontSize: 36.0, color: Styles().colors?.surface), textAlign: TextAlign.center,)),
        Visibility(visible: widget.content!.header!.moreInfo != null, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(widget.content!.header!.moreInfo ?? '', 
            style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.surface), 
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

  List<Widget> _buildContent({List<SkillsSelfEvaluationSection>? sections}) {
    List<Widget> contentWidgets = [];
    for (SkillsSelfEvaluationSection section in sections ?? widget.content?.sections ?? []) {
      Widget titleWidget = Text(
        section.title,
        style: TextStyle(fontFamily: "ProximaNovaBold", fontSize: 16.0, color: Styles().colors?.fillColorPrimaryVariant),
        textAlign: TextAlign.start,
      );

      if (section.subtitle != null) {
        contentWidgets.add(titleWidget);
        contentWidgets.add(Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(
          section.subtitle!,
          style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.fillColorPrimaryVariant),
          textAlign: TextAlign.start,
        )));
      } else {
        contentWidgets.add(Padding(padding: const EdgeInsets.only(bottom: 16), child: titleWidget));
      }
      
      if (section.body != null) {
        RegExp regExp = RegExp(r"%{(.*?)}");
        Iterable<Match> matches = regExp.allMatches(section.body!);
        contentWidgets.add(Text(
          CollectionUtils.isNotEmpty(matches) ? section.body!.substring(0, matches.elementAt(0).start) : section.body!,
          style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.fillColorPrimaryVariant),
          textAlign: TextAlign.start,
        ));

        for (int i = 0; i < matches.length; i++) {
          Match match = matches.elementAt(i);
          String? key = match.group(1);
          List<String>? parts = key?.split(".");

          if (CollectionUtils.isNotEmpty(parts)) {
            switch (parts![0]) {
              case "links":
                dynamic linkData = MapPathKey.entry(widget.content?.links, parts.sublist(1).join('.'));
                if (linkData is SkillsSelfEvaluationLink) {
                  contentWidgets.add(InkWell(onTap: () => _onTapLink(linkData), child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: linkData.text,
                          style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.fillColorPrimaryVariant, decoration: TextDecoration.underline, decorationColor: Styles().colors?.fillColorSecondary),
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
                dynamic widgetData = MapPathKey.entry(widget.params, parts.sublist(1).join('.'));
                if (widgetData is String) {
                  contentWidgets.add(Text(
                    widgetData,
                    style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.fillColorPrimaryVariant,),
                  ));
                }
                break;
            }
          }

          if (match.end < section.body!.length) {
            contentWidgets.add(Text(
              section.body!.substring(match.end, (i+1 < matches.length) ? matches.elementAt(i+1).start : null),
              style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.fillColorPrimaryVariant),
              textAlign: TextAlign.start,
            ));
          }
        }
        contentWidgets.add(Container(height: 16.0));
      }
      if (CollectionUtils.isNotEmpty(section.subsections)) {
        contentWidgets.addAll(_buildContent(sections: section.subsections));
      }
    }
    
    return contentWidgets;
  }

  void _onTapLink(SkillsSelfEvaluationLink link) {
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
