
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/model/Questionnaire.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Questionnaires /* with Service */ {

  static const String _participateInResearchSetting = 'edu.illinois.rokwire.settings.questionnaire.research.participate';

  // Singletone instance

  static final Questionnaires _service = Questionnaires._internal();
  factory Questionnaires() => _service;

  Questionnaires._internal();

  // Implementation

  Future<Questionnaire?> loadDemographic() async {
    try { return Questionnaire.fromJson(JsonUtils.decodeMap(await rootBundle.loadString('assets/questionnaire.demographics.json'))); }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }

  // Settings

  bool get participateInResearch => (Auth2().prefs?.getBoolSetting(_participateInResearchSetting) == true);
  set participateInResearch(bool value) {
    if (value == false) {
      Auth2().prefs?.clearAllQuestionnaireAnswers();
    }
    Auth2().prefs?.applySetting(_participateInResearchSetting, value);
  }
}