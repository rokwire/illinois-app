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

import 'package:rokwire_plugin/utils/utils.dart';

class VoterRule {
  DateTime? startDate;
  DateTime? endDate;

  String? nrvTitle;
  String? nrvText;
  List<RuleOption>? nrvOptions;
  String? nrvPlaceTitle;
  List<RuleOption>? nrvPlaceOptions;
  String? nrvAlert;

  String? rvPlaceTitle;
  List<RuleOption>? rvPlaceOptions;
  String? rvTitle;
  String? rvText;
  List<RuleOption>? rvOptions;
  String? rvUrl;
  String? rvAlert;

  String? vbmText;
  String? vbmButtonTitle;
  String? vbmUrl;

  bool? hideForPeriod;
  bool? electionPeriod;

  static final String dateFormat = "yyyy/MM/dd";

  VoterRule({this.startDate, this.endDate,
    this.nrvTitle, this.nrvText, this.nrvOptions, this.nrvPlaceTitle, this.nrvPlaceOptions, this.nrvAlert,
    this.rvPlaceTitle, this.rvPlaceOptions, this.rvTitle, this.rvText, this.rvOptions, this.rvUrl, this.rvAlert,
    this.vbmText, this.vbmButtonTitle, this.vbmUrl,
    this.hideForPeriod, this.electionPeriod});

  static VoterRule? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? VoterRule(
        startDate: DateTimeUtils.dateTimeFromString(json['date_start'], format: dateFormat, isUtc: false),
        endDate: DateTimeUtils.dateTimeFromString(json['date_end'], format: dateFormat, isUtc: false),
        nrvTitle: json['NRV_title'],
        nrvText: json['NRV_text'],
        nrvOptions: RuleOption.listFromJson(JsonUtils.listValue(json['NRV_options'])),
        nrvPlaceTitle: json['NRV_place_title'],
        nrvPlaceOptions: RuleOption.listFromJson(JsonUtils.listValue(json['NRV_place_options'])),
        nrvAlert: json['NRV_alert'],
        rvPlaceTitle: json['RV_place_title'],
        rvPlaceOptions: RuleOption.listFromJson(JsonUtils.listValue(json['RV_place_options'])),
        rvTitle: json['RV_title'],
        rvText: json['RV_text'],
        rvOptions: RuleOption.listFromJson(JsonUtils.listValue(json['RV_options'])),
        rvUrl: json['RV_url'],
        rvAlert: json['RV_alert'],
        vbmText: json['VBM_text'],
        vbmButtonTitle: json['VBM_button'],
        vbmUrl: json['VBM_url'],
        hideForPeriod: json['hide_for_period'],
        electionPeriod: json['election_period']
    ) : null;
  }

  static List<VoterRule>? listFromJson(List<dynamic>? jsonList) {
    List<VoterRule>? result;
    if (jsonList != null) {
      result = <VoterRule>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, VoterRule.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<VoterRule>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  static VoterRule? getVoterRuleForToday(List<VoterRule>? voterRules, DateTime? dateTime) {
    //DateTime? uniLocalTime = AppDateTime().getUniLocalTimeFromUtcTime(AppDateTime().now.toUtc());
    if (CollectionUtils.isNotEmpty(voterRules) && (dateTime != null)) {
      for (VoterRule rule in voterRules!) {
        bool afterStartDate = true;
        bool beforeEndDate = true;
        if (rule.startDate != null) {
          bool isSameStartDay = (dateTime.year == rule.startDate?.year) && (dateTime.month == rule.startDate?.month) &&
              (dateTime.day == rule.startDate?.day);
          afterStartDate = (rule.startDate?.isBefore(dateTime) ?? false) || isSameStartDay;
        }
        if (rule.endDate != null) {
          bool isSameEndDay = (dateTime.year == rule.endDate?.year) && (dateTime.month == rule.endDate?.month) && (dateTime.day == rule.endDate?.day);
          beforeEndDate = (rule.endDate?.isAfter(dateTime) ?? false) || isSameEndDay;
        }
        if (afterStartDate && beforeEndDate) {
          return rule;
        }
      }
    }
    return null;
  }
}

class RuleOption {
  String? label;
  String? value;

  RuleOption({this.label, this.value});

  static RuleOption? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return RuleOption(
        label: json['label'],
        value: json['value']
    );
  }

  toJson() {
    return {
      'label' : label,
      'value' : value,
    };
  }

  static List<RuleOption>? listFromJson(List<dynamic>? json) {
    List<RuleOption>? values;
    if (json != null) {
      values = <RuleOption>[];
      for (dynamic entry in json) {
        ListUtils.add(values, RuleOption.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<RuleOption>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (RuleOption value in values) {
        json.add(value.toJson());
      }
    }
    return json;
  }
}
