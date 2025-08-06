class SurveyTracker {
  final Map<String, dynamic> responses = {};

  void setResponse(String key, dynamic value) {
    responses[key] = value;
  }

  dynamic getResponse(String key) => responses[key];
}
