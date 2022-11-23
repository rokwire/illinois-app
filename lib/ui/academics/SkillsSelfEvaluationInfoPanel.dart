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
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/web_panel.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class SkillsSelfEvaluationInfoPanel extends StatefulWidget {
  final Map<String, dynamic> content;

  SkillsSelfEvaluationInfoPanel({required this.content});

  @override
  _SkillsSelfEvaluationInfoPanelState createState() => _SkillsSelfEvaluationInfoPanelState();
}

class _SkillsSelfEvaluationInfoPanelState extends State<SkillsSelfEvaluationInfoPanel> {
  late SkillsSelfEvaluationInfoContent _content;

  @override
  void initState() {
    _content = SkillsSelfEvaluationInfoContent.fromJson(widget.content);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootBackHeaderBar(title: Localization().getStringEx('panel.skills_self_evaluation.results.header.title', 'Skills Self-Evaluation'),),
      body: Padding(padding: const EdgeInsets.all(16.0), child: _buildContent()),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: null,
    );
  }

  Widget _buildContent({List<SkillsSelfEvaluationInfoSection>? sections}) {
    List<Widget> contentWidgets = [];
    for (SkillsSelfEvaluationInfoSection section in sections ?? _content.sections ?? []) {
      contentWidgets.add(Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(
        section.title,
        style: TextStyle(fontFamily: "ProximaNovaBold", fontSize: 16.0, color: Styles().colors?.fillColorPrimaryVariant),
        textAlign: TextAlign.start,
      )));

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
                dynamic linkData = MapPathKey.entry(_content.links, parts.sublist(1).join('.'));
                if (linkData is SkillsSelfEvaluationInfoLink) {
                  contentWidgets.add(InkWell(onTap: () => _onTapLink(linkData.url, linkData.internal), child: RichText(
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
            }
          }

          contentWidgets.add(Text(
            section.body!.substring(match.end, (i+1 < matches.length) ? matches.elementAt(i+1).start : null),
            style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.fillColorPrimaryVariant),
            textAlign: TextAlign.start,
          ));
        }
        contentWidgets.add(Container(height: 16.0));
      }
      if (CollectionUtils.isNotEmpty(section.subsections)) {
        contentWidgets.add(_buildContent(sections: section.subsections));
      }
    }
    return Container(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: contentWidgets),
    );
  }

  void _onTapLink(String url, bool internal) {
    if (internal == true || (internal != false && UrlUtils.launchInternal(url))) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
    } else {
      Uri? parsedUri = Uri.tryParse(url);
      if (parsedUri != null) {
        launchUrl(parsedUri, mode: LaunchMode.externalApplication);
      }
    }
  }
}

class SkillsSelfEvaluationInfoContent {
  final String id;
  final String category;
  final String key;
  final List<SkillsSelfEvaluationInfoSection>? sections;
  final Map<String, SkillsSelfEvaluationInfoLink>? links;

  SkillsSelfEvaluationInfoContent({required this.id, required this.category, required this.key, this.sections, this.links});

  factory SkillsSelfEvaluationInfoContent.fromJson(Map<String, dynamic> json) {
    Map<String, SkillsSelfEvaluationInfoLink>? links;
    Map<String, dynamic>? linksJson = JsonUtils.mapValue(json['links']);
    if (linksJson != null) {
      links = <String, SkillsSelfEvaluationInfoLink>{};
      for (MapEntry<String, dynamic> item in linksJson.entries) {
        if (item.value is Map<String, dynamic>) {
          links[item.key] = SkillsSelfEvaluationInfoLink.fromJson(item.value);
        }
      }
    }

    return SkillsSelfEvaluationInfoContent(
      id: JsonUtils.stringValue(json['id']) ?? '',
      category: JsonUtils.stringValue(json['category']) ?? '',
      key: JsonUtils.stringValue(json['key']) ?? '',
      sections: SkillsSelfEvaluationInfoSection.listFromJson(JsonUtils.listValue(json['sections'])),
      links: links,
    );
  }
}

class SkillsSelfEvaluationInfoSection {
  final String type;
  final String title;
  final String? subtitle;
  final String? body;
  final List<SkillsSelfEvaluationInfoSection>? subsections;

  SkillsSelfEvaluationInfoSection({required this.type, required this.title, this.subtitle, this.body, this.subsections});

  factory SkillsSelfEvaluationInfoSection.fromJson(Map<String, dynamic> json) {
    return SkillsSelfEvaluationInfoSection(
      type: JsonUtils.stringValue(json['type']) ?? '',
      title: JsonUtils.stringValue(json['title']) ?? '',
      subtitle: JsonUtils.stringValue(json['subtitle']),
      body: JsonUtils.stringValue(json['body']),
      subsections: SkillsSelfEvaluationInfoSection.listFromJson(JsonUtils.listValue(json['subsections'])),
    );
  }

  static List<SkillsSelfEvaluationInfoSection>? listFromJson(List<dynamic>? json) {
    if (json != null) {
      List<SkillsSelfEvaluationInfoSection> sections = [];
      for (dynamic item in json) {
        if (item is Map<String, dynamic>) {
          sections.add(SkillsSelfEvaluationInfoSection.fromJson(item));
        }
      }
      return sections;
    }

    return null;
  }
}

class SkillsSelfEvaluationInfoLink {
  final String type;
  final String text;
  final String? icon;
  final String url;
  final bool internal;

  SkillsSelfEvaluationInfoLink({required this.type, required this.text, this.icon, required this.url, this.internal = false});

  factory SkillsSelfEvaluationInfoLink.fromJson(Map<String, dynamic> json) {
    return SkillsSelfEvaluationInfoLink(
      type: JsonUtils.stringValue(json['type']) ?? '',
      text: JsonUtils.stringValue(json['text']) ?? '',
      icon: JsonUtils.stringValue(json['icon']),
      url: JsonUtils.stringValue(json['url']) ?? '',
      internal: JsonUtils.boolValue(json['internal']) ?? false,
    );
  }
}
