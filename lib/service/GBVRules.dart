import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class GBVResultRulesService {
  static Future<List<dynamic>> loadRules() async {
    final String jsonStr = await rootBundle.loadString('assets/extra/gbv/illinois_gbv_result_rules.json');
    return json.decode(jsonStr);
  }
}

bool evaluateCondition(Map<String, dynamic> condition, Map<String, dynamic> responses) {
  String operator = condition['operator'];
  if (operator == '==') {
    return responses[condition['data_key']] == condition['compare_to'];
  } else if (operator == '!=') {
    return responses[condition['data_key']] != condition['compare_to'];
  } else if (operator == 'and') {
    return (condition['conditions'] as List)
        .every((c) => evaluateCondition(c, responses));
  } else if (operator == 'or') {
    return (condition['conditions'] as List)
        .any((c) => evaluateCondition(c, responses));
  }
  return false;
}

dynamic getMatchingResult(List<dynamic> rules, Map<String, dynamic> responses) {
  for (final rule in rules) {
    final cond = rule['condition'];
    if (evaluateCondition(cond, responses)) {
      return rule['true_result'];
    }
  }
  return null;
}
