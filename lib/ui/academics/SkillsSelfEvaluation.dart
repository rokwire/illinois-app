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
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Polls.dart';
import 'package:illinois/ui/academics/SkillsSelfEvaluationInfoPanel.dart';
import 'package:illinois/ui/academics/SkillsSelfEvaluationResultsPanel.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/ui/widgets/InfoPopup.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/flex_ui.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/survey_panel.dart';
import 'package:rokwire_plugin/ui/widgets/ribbon_button.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class SkillsSelfEvaluation extends StatefulWidget {

  SkillsSelfEvaluation();

  @override
  _SkillsSelfEvaluationState createState() => _SkillsSelfEvaluationState();
}

class _SkillsSelfEvaluationState extends State<SkillsSelfEvaluation> {
  Map<String, SkillsSelfEvaluationContent> _infoContentItems = {};

  @override
  void initState() {
    _loadContentItems();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SectionSlantHeader(
        header: _buildHeader(),
        slantColor: Styles().colors?.gradientColorPrimary,
        backgroundColor: Styles().colors?.background,
        children: _buildInfoAndSettings(),
        childrenPadding: const EdgeInsets.only(top: 416),
      );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 32, bottom: 32),
      child: Padding(padding: EdgeInsets.only(left: 24, right: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(Localization().getStringEx('panel.skills_self_evaluation.get_started.section.title', 'Skills Self Evaluation'), style: TextStyle(fontFamily: "ProximaNovaExtraBold", fontSize: 28.0, color: Styles().colors?.surface), textAlign: TextAlign.left,)),
          IconButton(
            icon: Image.asset('images/tab-more.png', color: Styles().colors?.surface),
            onPressed: _onTapShowBottomSheet,
            padding: EdgeInsets.zero,
          ),
        ]),
        Text(Localization().getStringEx('panel.skills_self_evaluation.get_started.time.description', '5 Minutes'), style: TextStyle(fontFamily: "ProximaNovaBold", fontSize: 16.0, color: Styles().colors?.fillColorSecondary), textAlign: TextAlign.left,),
        Padding(padding: EdgeInsets.only(top: 24), child: _buildDescription()),
        Padding(padding: EdgeInsets.only(top: 64, left: 64, right: 80), child: RoundedButton(
          label: Localization().getStringEx("panel.skills_self_evaluation.get_started.button.label", 'Get Started'),
          textColor: Styles().colors?.fillColorPrimaryVariant,
          backgroundColor: Styles().colors?.surface,
          onTap: _onTapStartEvaluation
        )),
      ]),),
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

  Widget _buildDescription() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(Localization().getStringEx("panel.skills_self_evaluation.get_started.description.title", 'Identify your strengths related to:'), style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.surface),),
      Padding(padding: EdgeInsets.only(top: 8), child: Text(
        Localization().getStringEx("panel.skills_self_evaluation.get_started.description.list", '\t\t\u2022 self-management\n\t\t\u2022 innovation\n\t\t\u2022 cooperation\n\t\t\u2022 social engagement\n\t\t\u2022 emotional resilience'),
        style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.surface),
      ))
    ]);
  }

  List<Widget> _buildInfoAndSettings() {
    return <Widget>[
      RibbonButton(
        leftIconAsset: "images/icon-info-orange.png",
        label: Localization().getStringEx("panel.skills_self_evaluation.get_started.body.info.description", "Your results will be saved for you to revisit or compare to future results."),
        textColor: Styles().colors?.fillColorPrimaryVariant,
        backgroundColor: Colors.transparent,
        // TODO: onTap: ,
      ),
      RibbonButton(
        leftIconAsset: "images/icon-settings.png",
        label: Localization().getStringEx("panel.skills_self_evaluation.get_started.body.settings.decription", "Don't Save My Results"),
        textColor: Styles().colors?.fillColorPrimaryVariant,
        backgroundColor: Colors.transparent,
        onTap: _onTapSettings,
      ),
    ];
  }

  void _loadContentItems() {
    Polls().loadContentItems(categories: ["Skills Self-Evaluation Info"]).then((content) {
      if (content?.isNotEmpty ?? false) {
        _infoContentItems.clear();
        for (MapEntry<String, Map<String, dynamic>> item in content?.entries ?? []) {
          _infoContentItems[item.key] = SkillsSelfEvaluationContent.fromJson(item.value);
        }
      }
    });
  }

  void _onTapShowBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Styles().colors?.surface,
      isScrollControlled: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Container(
                height: 24,
              ),
              RibbonButton(
                rightIconAsset: "images/chevron-right.png",
                label: Localization().getStringEx("panel.skills_self_evaluation.get_started.bottom_sheet.past_results.label", "View past results"),
                textColor: Styles().colors?.fillColorPrimaryVariant,
                onTap: () => _onTapResults(null),
              ),
              RibbonButton(
                rightIconAsset: "images/chevron-right.png",
                label: Localization().getStringEx("panel.skills_self_evaluation.get_started.bottom_sheet.where_results_go.label", "Where do my results go?"),
                textColor: Styles().colors?.fillColorPrimaryVariant,
                onTap: () => _onTapShowInfo("where_results_go"),
              ),
              RibbonButton(
                rightIconAsset: "images/chevron-right.png",
                label: Localization().getStringEx("panel.skills_self_evaluation.get_started.bottom_sheet.how_results_determined.label", "How are my results determined?"),
                textColor: Styles().colors?.fillColorPrimaryVariant,
                onTap: () => _onTapShowInfo("how_results_determined"),
              ),
              RibbonButton(
                rightIconAsset: "images/chevron-right.png",
                label: Localization().getStringEx("panel.skills_self_evaluation.get_started.bottom_sheet.why_skills_matter.label", "Why do these skills matter?"),
                textColor: Styles().colors?.fillColorPrimaryVariant,
                onTap: () => _onTapShowInfo("why_skills_matter"),
              ),
              RibbonButton(
                rightIconAsset: "images/chevron-right.png",
                label: Localization().getStringEx("panel.skills_self_evaluation.get_started.bottom_sheet.who_created_assessment.label", "Who created this assessment?"),
                textColor: Styles().colors?.fillColorPrimaryVariant,
                onTap: () => _onTapShowInfo("who_created_assessment"),
              ),
            ]));
      });
  }

  void _onTapStartEvaluation() {
    List<String>? academicUiComponents = JsonUtils.stringListValue(FlexUI()['academics']);
    if (academicUiComponents?.contains('skills_self_evaluation') == true) {
      if (Config().bessiSurveyID != null && Auth2().isOidcLoggedIn && Auth2().privacyMatch(4)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: Config().bessiSurveyID, onComplete: _onTapResults,)));
      } else {
        Widget infoTextWidget = RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: Localization().getStringEx('panel.skills_self_evaluation.get_started.auth_dialog.prefix', 'You need to be signed in with your NetID to access Assessments.\n'),
                style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.fillColorPrimaryVariant),
              ),
              WidgetSpan(
                child: InkWell(onTap: _onTapPrivacyLevel, child: Text(
                  Localization().getStringEx('panel.skills_self_evaluation.get_started.auth_dialog.privacy', 'Set your privacy level to 4 or 5.'),
                  style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.fillColorPrimaryVariant, decoration: TextDecoration.underline, decorationColor: Styles().colors?.fillColorSecondary),
                )),
              ),
              TextSpan(
                text: Localization().getStringEx('panel.skills_self_evaluation.get_started.auth_dialog.suffix', ' Then, sign in with your NetID under Settings.'),
                style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.fillColorPrimaryVariant),
              ),
            ],
          ),
        );
        showDialog(context: context, builder: (_) => InfoPopup(
          backColor: Styles().colors?.surface,
          padding: EdgeInsets.only(left: 24, right: 24, top: 28, bottom: 24),
          alignment: Alignment.center,
          infoTextWidget: infoTextWidget,
          closeIcon: Image.asset('images/close-orange-small.png'),
        ),);
      }
    }
  }

  void _onTapSettings() {
    SettingsHomeContentPanel.present(context, content: SettingsContent.assessments);
  }

  void _onTapResults(SurveyResponse? response) {
    Navigator.of(context).pop();
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SkillsSelfEvaluationResultsPanel(latestResponse: response)));
  }

  void _onTapShowInfo(String key) {
    Navigator.of(context).pop();
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SkillsSelfEvaluationInfoPanel(content: _infoContentItems[key])));
  }

  void _onTapPrivacyLevel() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,)));
  }
}

class SkillsSelfEvaluationContent {
  final String id;
  final String category;
  final String key;
  final SkillsSelfEvaluationHeader? header;
  final List<SkillsSelfEvaluationSection>? sections;
  final Map<String, SkillsSelfEvaluationLink>? links;
  final Map<String, dynamic>? data;

  SkillsSelfEvaluationContent({required this.id, required this.category, required this.key, this.header, this.sections, this.links, this.data});

  factory SkillsSelfEvaluationContent.fromJson(Map<String, dynamic> json) {
    Map<String, SkillsSelfEvaluationLink>? links;
    Map<String, dynamic>? linksJson = JsonUtils.mapValue(json['links']);
    if (linksJson != null) {
      links = <String, SkillsSelfEvaluationLink>{};
      for (MapEntry<String, dynamic> item in linksJson.entries) {
        if (item.value is Map<String, dynamic>) {
          links[item.key] = SkillsSelfEvaluationLink.fromJson(item.value);
        }
      }
    }

    return SkillsSelfEvaluationContent(
      id: JsonUtils.stringValue(json['id']) ?? '',
      category: JsonUtils.stringValue(json['category']) ?? '',
      key: JsonUtils.stringValue(json['key']) ?? '',
      header: JsonUtils.mapOrNull((json) => SkillsSelfEvaluationHeader.fromJson(json), json['header']),
      sections: SkillsSelfEvaluationSection.listFromJson(JsonUtils.listValue(json['sections'])),
      links: links,
      data: JsonUtils.mapValue(json['data']),
    );
  }
}

class SkillsSelfEvaluationHeader {
  final String title;
  final String? moreInfo;

  SkillsSelfEvaluationHeader({required this.title, this.moreInfo});

  factory SkillsSelfEvaluationHeader.fromJson(Map<String, dynamic> json) {
    return SkillsSelfEvaluationHeader(
      title: JsonUtils.stringValue(json['title']) ?? '',
      moreInfo: JsonUtils.stringValue(json['more_info']),
    );
  }
}

class SkillsSelfEvaluationSection {
  final String type;
  final String title;
  final String? subtitle;
  final String? body;
  final Map<String, dynamic>? params;
  final List<SkillsSelfEvaluationSection>? subsections;

  SkillsSelfEvaluationSection({required this.type, required this.title, this.subtitle, this.body, this.params, this.subsections});

  factory SkillsSelfEvaluationSection.fromJson(Map<String, dynamic> json) {
    return SkillsSelfEvaluationSection(
      type: JsonUtils.stringValue(json['type']) ?? 'text',
      title: JsonUtils.stringValue(json['title']) ?? '',
      subtitle: JsonUtils.stringValue(json['subtitle']),
      body: JsonUtils.stringValue(json['body']),
      params: JsonUtils.mapValue(json['params']),
      subsections: SkillsSelfEvaluationSection.listFromJson(JsonUtils.listValue(json['subsections'])),
    );
  }

  static List<SkillsSelfEvaluationSection>? listFromJson(List<dynamic>? json) {
    if (json != null) {
      List<SkillsSelfEvaluationSection> sections = [];
      for (dynamic item in json) {
        if (item is Map<String, dynamic>) {
          sections.add(SkillsSelfEvaluationSection.fromJson(item));
        }
      }
      return sections;
    }

    return null;
  }
}

class SkillsSelfEvaluationLink {
  final String type;
  final String text;
  final String? icon;
  final String? url;
  final String? panel;
  final Map<String, dynamic>? params;

  SkillsSelfEvaluationLink({required this.type, required this.text, this.icon, this.url, this.panel, this.params});

  factory SkillsSelfEvaluationLink.fromJson(Map<String, dynamic> json) {
    return SkillsSelfEvaluationLink(
      type: JsonUtils.stringValue(json['type']) ?? '',
      text: JsonUtils.stringValue(json['text']) ?? '',
      icon: JsonUtils.stringValue(json['icon']),
      url: JsonUtils.stringValue(json['url']),
      panel: JsonUtils.stringValue(json['panel']),
      params: JsonUtils.mapValue(json['params']),
    );
  }

  bool get internal => params != null ? params!['internal'] ?? false : false;
}
