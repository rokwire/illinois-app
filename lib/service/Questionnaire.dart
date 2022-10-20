
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/model/Questionnaire.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Questionnaires /* with Service */ {

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
}