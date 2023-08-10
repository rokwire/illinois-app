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
import 'package:illinois/service/Occupations.dart';
import 'package:illinois/ui/academics/SkillsSelfEvaluationInfoPanel.dart';
import 'package:illinois/ui/academics/SkillsSelfEvaluationResultsPanel.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:illinois/ui/widgets/InfoPopup.dart';
import 'package:illinois/ui/widgets/AccessWidgets.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/storage.dart';
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

  static Future<Map<String, Map<String, dynamic>>?> loadContentItems(List<String> categories) async {
    Map<String, Map<String, dynamic>>? result;
    Map<String, dynamic>? contentItems = await Content().loadContentItems(categories);
    if (contentItems != null) {
      result = <String, Map<String, dynamic>>{};
      for (String category in contentItems.keys) {
        Map<String, Map<String, dynamic>>? categoryResult = _buildContentItems(contentItems[category], category);
        if (categoryResult != null) {
          result.addAll(categoryResult);
        }
      }
    }
    return result;
  }

  static Map<String, Map<String, dynamic>>? _buildContentItems(dynamic contentItem, String category) {
    if (contentItem is Iterable) {
      Map<String, Map<String, dynamic>> result = <String, Map<String, dynamic>>{};
      for (dynamic contentListEntry in contentItem) {
        Map<String, Map<String, dynamic>>? entryResult = _buildContentItems(contentListEntry, category);
        if (entryResult != null) {
          result.addAll(entryResult);
        }
      }
      return result;
    }
    else {
      Map<String, dynamic>? contentEntry = JsonUtils.mapValue(contentItem);
      if (contentEntry != null) {
        String? key = JsonUtils.stringValue(contentEntry['key']);
        if (key != null) {
          contentEntry['category'] = category;
          return <String, Map<String, dynamic>>{
            key: contentEntry
          };
        }
      }
    }
    return null;
  }
}

class _SkillsSelfEvaluationState extends State<SkillsSelfEvaluation> implements NotificationsListener {
  Map<String, SkillsSelfEvaluationContent> _infoContentItems = {};

  @override
  void initState() {
    NotificationService().subscribe(this, [Storage.notifySettingChanged]);
    _loadContentItems();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SectionSlantHeader(
        headerWidget: _buildHeader(),
        slantColor: Styles().colors?.gradientColorPrimary,
        slantPainterHeadingHeight: 0,
        backgroundColor: Styles().colors?.background,
        children: _buildInfoAndSettings(),
        childrenPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        allowOverlap: false,
      );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 32, bottom: 32),
      child: Padding(padding: EdgeInsets.only(left: 24, right: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(Localization().getStringEx('panel.skills_self_evaluation.get_started.section.title', 'Skills Self Evaluation'), style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.get_started.header'), textAlign: TextAlign.left,)),
          IconButton(
            icon: Styles().images?.getImage('more-white', excludeFromSemantics: true) ?? Container(),
            tooltip: Localization().getStringEx('panel.skills_self_evaluation.button.more.hint', 'Show more'),
            onPressed: _onTapShowBottomSheet,
            padding: EdgeInsets.zero,
          ),
        ]),
        Text(Localization().getStringEx('panel.skills_self_evaluation.get_started.time.description', '5 Minutes'), style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.get_started.time.description'), textAlign: TextAlign.left,),
        Padding(padding: EdgeInsets.only(top: 24), child: _buildDescription()),
        Padding(padding: EdgeInsets.only(top: 64, left: 64, right: 80), child: RoundedButton(
          label: Localization().getStringEx("panel.skills_self_evaluation.get_started.button.label", 'Get Started'),
          textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat.variant"),
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
      Text(Localization().getStringEx("panel.skills_self_evaluation.get_started.description.title", 'Identify your strengths related to:'), style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.header.description'),),
      Padding(padding: EdgeInsets.only(top: 8), child: Text(
        Localization().getStringEx("panel.skills_self_evaluation.get_started.description.list", '\t\t\u2022 self-management\n\t\t\u2022 innovation\n\t\t\u2022 cooperation\n\t\t\u2022 social engagement\n\t\t\u2022 emotional resilience'),
        style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.header.description'),
      ))
    ]);
  }

  List<Widget> _buildInfoAndSettings() {
    bool saveEnabled = Storage().assessmentsSaveResultsMap?['bessi'] != false;
    return <Widget>[
      RibbonButton(
        leftIconKey: "info",
        label: saveEnabled ? Localization().getStringEx("panel.skills_self_evaluation.get_started.body.save.description", "Your results will be saved for you to revisit or compare to future results.") :
                Localization().getStringEx("panel.skills_self_evaluation.get_started.body.dont_save.description", "Your results will not be saved for you to compare to future results."),
        textStyle: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.title'),
        backgroundColor: Colors.transparent,
        onTap: _onTapSavedResultsInfo,
      ),
      RibbonButton(
        leftIconKey: "settings",
        label: saveEnabled ? Localization().getStringEx("panel.skills_self_evaluation.get_started.body.dont_save.label", "Don't Save My Results") :
                Localization().getStringEx("panel.skills_self_evaluation.get_started.body.save.label", "Save My Results"),
        textStyle: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.link.fat'),
        backgroundColor: Colors.transparent,
        onTap: _onTapSettings,
      ),
    ];
  }

  void _loadContentItems() {

    SkillsSelfEvaluation.loadContentItems(["bessi_info"]).then((content) {
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
              SizedBox(height: 16),
              Semantics(label: Localization().getStringEx("dialog.close.title", "Close"),
                  child: GestureDetector(onTap: () => Navigator.of(context).pop(),
                      child: Container(height: 8, width: 48,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                              color: Styles().colors?.mediumGray)))),
              SizedBox(height: 16),
              RibbonButton(
                rightIconKey: "chevron-right-bold",
                label: Localization().getStringEx("panel.skills_self_evaluation.get_started.bottom_sheet.past_results.label", "View past results"),
                textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat.variant"),
                onTap: _onTapResults,
              ),
              RibbonButton(
                rightIconKey: "chevron-right-bold",
                label: Localization().getStringEx("panel.skills_self_evaluation.get_started.bottom_sheet.where_results_go.label", "Where do my results go?"),
                textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat.variant"),
                onTap: () => _onTapShowInfo("where_results_go"),
              ),
              RibbonButton(
                rightIconKey: "chevron-right-bold",
                label: Localization().getStringEx("panel.skills_self_evaluation.get_started.bottom_sheet.how_results_determined.label", "How are my results determined?"),
                textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat.variant"),
                onTap: () => _onTapShowInfo("how_results_determined"),
              ),
              RibbonButton(
                rightIconKey: "chevron-right-bold",
                label: Localization().getStringEx("panel.skills_self_evaluation.get_started.bottom_sheet.why_skills_matter.label", "Why do these skills matter?"),
                textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat.variant"),
                onTap: () => _onTapShowInfo("why_skills_matter"),
              ),
              RibbonButton(
                rightIconKey: "chevron-right-bold",
                label: Localization().getStringEx("panel.skills_self_evaluation.get_started.bottom_sheet.who_created_assessment.label", "Who created this assessment?"),
                textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat.variant"),
                onTap: () => _onTapShowInfo("who_created_assessment"),
              ),
            ]));
      });
  }

  void _onTapStartEvaluation() {
    Future? result = AccessDialog.show(context: context, resource: 'academics.skills_self_evaluation');
    if (Config().bessiSurveyID != null && result == null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: Config().bessiSurveyID, onComplete: _gotoResults, offlineWidget: _buildOfflineWidget(), tabBar: uiuc.TabBar())));
    }
  }

  void _onTapSavedResultsInfo() {
    bool saveEnabled = Storage().assessmentsSaveResultsMap?['bessi'] != false;
    Widget textWidget = Text(
      saveEnabled ? Localization().getStringEx("panel.skills_self_evaluation.get_started.body.save.dialog",
        "Your results will be saved for you to compare to future results.\n\nNo data from this assessment will be shared with other people or systems or stored outside of your Illinois app account.") :
          Localization().getStringEx("panel.skills_self_evaluation.get_started.body.dont_save.description", "Your results will not be saved for you to compare to future results."),
      style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.auth_dialog.text'),
      textAlign: TextAlign.center,
    );
    showDialog(context: context, builder: (_) => InfoPopup(
      backColor: Styles().colors?.surface,
      padding: EdgeInsets.only(left: 32, right: 32, top: 40, bottom: 32),
      alignment: Alignment.center,
      infoTextWidget: textWidget,
      closeIcon: Styles().images?.getImage('close', excludeFromSemantics: true),
    ),);
  }

  void _onTapSettings() {
    SettingsHomeContentPanel.present(context, content: SettingsContent.assessments);
  }

  Widget _buildOfflineWidget() {
    return Padding(padding: EdgeInsets.all(28), child:
      Center(child:
        Text(
          Localization().getStringEx('panel.skills_self_evaluation.get_started.offline.error.msg', 'Skills Self-Evaluation is not available while offline.'),
          textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.title')
        )
      ),
    );
  }

  void _onTapResults() {
    Navigator.of(context).pop();
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SkillsSelfEvaluationResultsPanel()));
  }

  void _gotoResults(dynamic response) {
    if (response is SurveyResponse) {
      Occupations().postResults(surveyResponse: response);
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SkillsSelfEvaluationResultsPanel(latestResponse: response)));
    }
  }

  void _onTapShowInfo(String key) {
    Navigator.of(context).pop();
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SkillsSelfEvaluationInfoPanel(content: _infoContentItems[key])));
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Storage.notifySettingChanged && param == Storage().assessmentsEnableSaveKey && mounted) {
      setState(() {});
    }
  }
}

class SkillsSelfEvaluationProfile {
  final String id;
  final String category;
  final String key;
  final Map<String, dynamic> params;
  final Map<String, num> scores;

  SkillsSelfEvaluationProfile({required this.id, required this.category, required this.key, required this.params, required this.scores});

  factory SkillsSelfEvaluationProfile.fromJson(Map<String, dynamic> json) {
    Map<String, num> scores = {};
    Map<String, dynamic>? scoresJson = JsonUtils.mapValue(json['scores']);
    if (scoresJson != null) {
      for (MapEntry<String, dynamic> item in scoresJson.entries) {
        if (item.value is num) {
          scores[item.key] = item.value;
        }
      }
    }

    return SkillsSelfEvaluationProfile(
      id: JsonUtils.stringValue(json['id']) ?? '',
      category: JsonUtils.stringValue(json['category']) ?? '',
      key: JsonUtils.stringValue(json['key']) ?? '',
      params: JsonUtils.mapValue(json['params']) ?? {},
      scores: scores,
    );
  }
}

class SkillsSelfEvaluationContent {
  final String id;
  final String category;
  final String key;
  final SkillsSelfEvaluationHeader? header;
  final List<SkillsSelfEvaluationSection>? sections;
  final Map<String, SkillsSelfEvaluationLink>? links;
  final Map<String, dynamic>? params;

  SkillsSelfEvaluationContent({required this.id, required this.category, required this.key, this.header, this.sections, this.links, this.params});

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
      params: JsonUtils.mapValue(json['params']),
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
