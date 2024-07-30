import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';

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

  String? get displayEndDate => displayDate(endDate);

  int? get endDateDiff => (endDate != null) ? displayDateDiff(endDate!) : null;

  static String? displayDate(DateTime? dateTime, { String format = 'MMM d' }) {
    if (dateTime != null) {
      int daysDiff = displayDateDiff(dateTime);
      switch(daysDiff) {
        case 0: return Localization().getStringEx('model.explore.date_time.today', 'Today');
        case 1: return Localization().getStringEx('model.explore.date_time.tomorrow', 'Tomorrow');
        default: return DateFormat(format).format(dateTime);
      }
    }
    return null;
  }

  static int displayDateDiff(DateTime dateTime) {
    TZDateTime nowLocal = DateTimeLocal.nowLocalTZ();
    TZDateTime nowMidnightLocal = TZDateTimeUtils.dateOnly(nowLocal);

    TZDateTime dateTimeLocal = dateTime.toLocalTZ();
    TZDateTime dateTimeMidnightLocal = TZDateTimeUtils.dateOnly(dateTimeLocal);

    return dateTimeMidnightLocal.difference(nowMidnightLocal).inDays;
  }

}

extension Event2SurveysExt on Surveys {

  Future<List<Survey>?> loadEvent2SurveyTemplates() =>
    loadSurveys(SurveysQueryParam.fromType(Survey.templateSurveyPrefix + Event2.followUpSurveyType));

  Future<Survey?> loadEvent2Survey(String eventId) async {
    List<Survey>? surveys = await loadSurveys(SurveysQueryParam.fromCalendarEventID(eventId));
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