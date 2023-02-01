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
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/web_panel.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class SkillsSelfEvaluationInfoPanel extends StatelessWidget {
  final SkillsSelfEvaluationContent? content;
  final Map<String, dynamic>? params;

  SkillsSelfEvaluationInfoPanel({required this.content, this.params});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.skills_self_evaluation.info.header.title', 'Skills Self-Evaluation'), leading: RootHeaderBarLeading.Back,),
      body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(24.0), child: content == null ? _buildUnavailableMessage() : _buildContent(context))),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildUnavailableMessage() {
    return Padding(padding: EdgeInsets.all(28), child:
      Center(child:
        Text(
          Localization().getStringEx('panel.skills_self_evaluation.info.unavailable.error.msg', 'Information content not available.'),
          textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.title')
        )
      ),
    );
  }

  Widget _buildContent(BuildContext context, {List<SkillsSelfEvaluationSection>? sections}) {
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
                          child: linkData.icon != null ? Padding(padding: const EdgeInsets.only(left: 4.0), child: Styles().images?.getImage(linkData.icon, excludeFromSemantics: true)) : Container(),
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
        contentWidgets.add(_buildContent(context, sections: section.subsections));
      }
    }
    
    return Container(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: contentWidgets),
    );
  }

  void _onTapLink(BuildContext context, SkillsSelfEvaluationLink link) {
    if (link.internal && UrlUtils.launchInternal(link.url)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: link.url)));
    } else if (link.url != null) {
      Uri? parsedUri = Uri.tryParse(link.url!);
      if (parsedUri != null) {
        launchUrl(parsedUri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
