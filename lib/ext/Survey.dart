import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension SurveyExt on Survey {
  String? get displayTitle {
    if (StringUtils.isNotEmpty(title)) {
      return title;
    }
    else if (StringUtils.isNotEmpty(id)) {
      return id;
    }
    else {
      return null;
    }
  }
}

extension Event2SurveysExt on Surveys {

  Future<List<Survey>?> loadEvent2SurveyTemplates() =>
    loadSurveys(types: [Survey.templateSurveyPrefix + Event2.followUpSurveyType]);

  Future<Survey?> loadEvent2Survey(String eventId) async {
    List<Survey>? surveys = await loadSurveys(calendarEventID: eventId);
    return (0 < (surveys?.length ?? 0)) ? surveys?.first : null;
  }

  Future<bool?> createEvent2Survey(Survey template, Event2 event) async {
    Survey survey = Survey.fromOther(template);
    survey.calendarEventId = event.id;
    // this will cause problems when updating an event name after creating the survey
    // instead, the event_name key should be replaced with the current event name when an event attendee begins the survey
    // survey.replaceKey('event_name', event.name);
    return createSurvey(survey);
  }
}