import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Questionnaire {
  final String? id;
  final String? title;
  final String? description;
  final List<Question>? questions;
  final Map<String, dynamic>? strings;

  Questionnaire({this.id, this.title, this.description, this.questions, this.strings});

  // JSON serialization

  static Questionnaire? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Questionnaire(
      id: JsonUtils.stringValue(json['id']),
      title: JsonUtils.stringValue(json['title']),
      description: JsonUtils.stringValue(json['description']),
      questions: Question.listFromJson(JsonUtils.listValue(json['questions'])),
      strings: JsonUtils.mapValue(json['strings']),
    ) : null;
  }

  toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'questions': Question.listToJson(questions),
    'strings': strings,
  };

  // Equality

  @override
  bool operator==(Object other) =>
    (other is Questionnaire) &&
    (id == other.id) &&
    (title == other.title) &&
    (description == other.description) &&
    (DeepCollectionEquality().equals(questions, other.questions)) &&
    (DeepCollectionEquality().equals(strings, other.strings));

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (title?.hashCode ?? 0) ^
    (description?.hashCode ?? 0) ^
    DeepCollectionEquality().hash(questions) ^
    DeepCollectionEquality().hash(strings);

  // List<Questionnaire> JSON Serialization

  static List<Questionnaire>? listFromJson(List<dynamic>? jsonList) {
    List<Questionnaire>? values;
    if (jsonList != null) {
      values = <Questionnaire>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, Questionnaire.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<Questionnaire>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (Questionnaire value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }

  // Accessories

  String? stringValue(String? key, { String? languageCode }) {
    if ((strings != null) && (key != null)) {
      Map<String, dynamic>? mapping =
        JsonUtils.mapValue(strings![languageCode]) ??
        JsonUtils.mapValue(strings![Localization().currentLocale?.languageCode]) ??
        JsonUtils.mapValue(strings![Localization().defaultLocale?.languageCode]);
      String? value = (mapping != null) ? JsonUtils.stringValue(mapping[key]) : null;
      if (value != null) {
        return value;
      }
    }
    return key;
  }
}

enum QuestionType { checkList, dateOfBirth, schoolYear }
enum QuestionVisibilty { public, research }

class Question {
  final String? id;
  final QuestionType? type;
  final QuestionVisibilty? visibility;

  final String? title;
  final String? hint;
  final String? descriptionPrefix;
  final String? descriptionSuffix;

  final int? minAnswers;
  final int? maxAnswers;
  final List<Answer>? answers;

  Question({this.id, this.type, this.visibility,
    this.title, this.hint, this.descriptionPrefix, this.descriptionSuffix,
    this.minAnswers, this.maxAnswers, this.answers
  });

  // JSON serialization

  static Question? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Question(
      id: JsonUtils.stringValue(json['id']),
      type: QuestionTypeImpl.fromJsonString(JsonUtils.stringValue(json['type'])),
      visibility: QuestionVisibiltyImpl.fromJsonString(JsonUtils.stringValue(json['visibility'])),
      title: JsonUtils.stringValue(json['title']),
      hint: JsonUtils.stringValue(json['hint']),
      descriptionPrefix: JsonUtils.stringValue(json['description_prefix']),
      descriptionSuffix: JsonUtils.stringValue(json['description_suffix']),
      minAnswers: JsonUtils.intValue(json['min_answers']),
      maxAnswers: JsonUtils.intValue(json['max_answers']),
      answers: Answer.listFromJson(JsonUtils.listValue(json['answers'])),
    ) : null;
  }

  toJson() => {
    'id': id,
    'type': type?.toJsonString(),
    'visibility': visibility?.toJsonString(),
    'title': title,
    'hint': hint,
    'description_prefix': descriptionPrefix,
    'description_suffix': descriptionSuffix,
    'min_answers': minAnswers,
    'max_answers': maxAnswers,
    'answers': Answer.listToJson(answers),
  };

  // Equality

  @override
  bool operator==(Object other) =>
    (other is Question) &&
    (id == other.id) &&
    (type == other.type) &&
    (visibility == other.visibility) &&
    (title == other.title) &&
    (hint == other.hint) &&
    (descriptionPrefix == other.descriptionPrefix) &&
    (descriptionSuffix == other.descriptionSuffix) &&
    (minAnswers == other.minAnswers) &&
    (maxAnswers == other.maxAnswers) &&
    (DeepCollectionEquality().equals(answers, other.answers));

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (type?.hashCode ?? 0) ^
    (visibility?.hashCode ?? 0) ^
    (title?.hashCode ?? 0) ^
    (hint?.hashCode ?? 0) ^
    (descriptionPrefix?.hashCode ?? 0) ^
    (descriptionSuffix?.hashCode ?? 0) ^
    (minAnswers?.hashCode ?? 0) ^
    (maxAnswers?.hashCode ?? 0) ^
    DeepCollectionEquality().hash(answers);

  // List<Question> JSON Serialization

  static List<Question>? listFromJson(List<dynamic>? jsonList) {
    List<Question>? values;
    if (jsonList != null) {
      values = <Question>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, Question.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<Question>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (Question value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }

  // Accessories

  String? get displayHint => hint ?? title;
}

class Answer {
  static const String _analyticsSkipHint = 'NA';

  final String? id;
  final String? title;
  final String? hint;
  final AnswerInterval? interval;

  Answer({this.id, this.title, this.hint, this.interval});

  // JSON serialization

  static Answer? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Answer(
      id: JsonUtils.stringValue(json['id']),
      title: JsonUtils.stringValue(json['title']),
      hint: JsonUtils.stringValue(json['hint']),
      interval: AnswerInterval.fromJson(JsonUtils.mapValue(json['interval'])),
    ) : null;
  }

  toJson() => {
    'id': id,
    'title': title,
    'hint': hint,
    'interval': interval?.toJson(),
  };

  // Equality

  @override
  bool operator==(Object other) =>
    (other is Answer) &&
    (id == other.id) &&
    (title == other.title) &&
    (hint == other.hint) &&
    (interval == other.interval);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (title?.hashCode ?? 0) ^
    (hint?.hashCode ?? 0) ^
    (interval?.hashCode ?? 0);

  // Accessories
  
  bool get isAnalyticsSkipAnswer => hint == _analyticsSkipHint; // TBD: better skip answer identification

  // List<Answer> JSON Serialization

  static List<Answer>? listFromJson(List<dynamic>? jsonList) {
    List<Answer>? values;
    if (jsonList != null) {
      values = <Answer>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, Answer.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<Answer>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (Answer value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }

  // List<Answer> Accessories

  static Answer? answerInList(List<Answer>? answers, { String? answerId }) {
    if (answers != null) {
      for (Answer answer in answers) {
        if ((answerId != null) && (answerId == answer.id)) {
          return answer;
        }
      }
    }
    return null;
  }

  // Accessories

  String? get displayHint => hint ?? title;
}

class AnswerInterval {
  final AnswerIntervalDelta? startDelta;
  final AnswerIntervalDelta? endDelta;

  static const String delimiter = ';';

  AnswerInterval({this.startDelta, this.endDelta});

  static AnswerInterval? fromJson(Map<String, dynamic>? json) => (json != null) ? AnswerInterval(
    startDelta: AnswerIntervalDelta.fromJsonString(JsonUtils.stringValue(json['start'])),
    endDelta: AnswerIntervalDelta.fromJsonString(JsonUtils.stringValue(json['end'])),
  ) : null;

  Map<String, dynamic> toJson() => {
    'start': startDelta?.toJsonString(),
    'end': endDelta?.toJsonString(),
  };

  String? matchSchoolYearSelection(Iterable<String>? selection) {
    if (selection != null) {
      int currentSchoolYear = SchoolYearQuestion.currentSchoolYear;
      int? startYear = startDelta?.applyOnYear(currentSchoolYear);
      int? endYear = endDelta?.applyOnYear(currentSchoolYear);
      for (String selectedEntry in selection) {
        int? selectedYear = int.tryParse(selectedEntry);
        if ((selectedYear != null) &&
            ((startYear == null) || (startYear <= selectedYear )) &&
            ((endYear == null) || (selectedYear <= endYear)))
        {
          return selectedEntry;
        }
      }
    }
    return null;
  }

  String? toSchoolYearSelectionValue() {
    int currentSchoolYear = SchoolYearQuestion.currentSchoolYear;
    String? startValue = startDelta?.applyOnYear(currentSchoolYear).toString();
    String? endValue = endDelta?.applyOnYear(currentSchoolYear).toString();
    return startValue ?? endValue;
  }

  String toSchoolYearFilterValue() {
    int currentSchoolYear = SchoolYearQuestion.currentSchoolYear;
    String startValue = startDelta?.applyOnYear(currentSchoolYear).toString() ?? '';
    String endValue = endDelta?.applyOnYear(currentSchoolYear).toString() ?? '';
    return [startValue, endValue].join(delimiter);
  }

  String toDateOfBirthFilterValue() {
    DateTime now = DateUtils.dateOnly(DateTime.now());
    String startValue = startDelta?.applyOnDate(now).difference(DateOfBirthQuestion.dobOrgDate).inDays.toString() ?? '';
    String endValue = endDelta?.applyOnDate(now).difference(DateOfBirthQuestion.dobOrgDate).inDays.toString() ?? '';
    return [startValue, endValue].join(delimiter);
  }

  // Equality

  @override
  bool operator==(Object other) =>
    (other is AnswerInterval) &&
    (startDelta == other.startDelta) &&
    (endDelta == other.endDelta);

  @override
  int get hashCode =>
    (startDelta?.hashCode ?? 0) ^
    (endDelta?.hashCode ?? 0);
}

class AnswerIntervalDelta {
  final int? years;
  final int? months;
  final int? days;

  static const String delimiter = ';';

  AnswerIntervalDelta({this.years, this.months, this.days});

  static AnswerIntervalDelta? fromJsonString(String? value) {
    if (value != null) {
      List<String> items = value.split(delimiter);
      return AnswerIntervalDelta(
        years: (0 < items.length) ? int.tryParse(items[0]) : null,
        months: (1 < items.length) ? int.tryParse(items[1]) : null,
        days: (2 < items.length) ? int.tryParse(items[2]) : null
      );
    }
    else {
      return null;
    }
  }

  String toJsonString() => [_yearsString, _monthsString, _daysString].join(delimiter);

  String get _yearsString => (years != null) ? years.toString() : '';
  String get _monthsString => (months != null) ? months.toString() : '';
  String get _daysString => (days != null) ? days.toString() : '';

  // Equality

  @override
  bool operator==(Object other) =>
    (other is AnswerIntervalDelta) &&
    (years == other.years) &&
    (months == other.months) &&
    (days == other.days);

  @override
  int get hashCode =>
    (years?.hashCode ?? 0) ^
    (months?.hashCode ?? 0) ^
    (days?.hashCode ?? 0);

  // Functinality

  DateTime applyOnDate(DateTime origin) => DateTime(
    origin.year + _years,
    origin.month + _months,
    origin.day + _days,
  );

  int applyOnYear(int origin) => origin + _years;

  int get _years => years ?? 0;
  int get _months => months ?? 0;
  int get _days => days ?? 0;
}

extension QuestionTypeImpl on QuestionType {

  String toJsonString() {
    switch (this) {
      case QuestionType.checkList: return 'check-list';
      case QuestionType.dateOfBirth: return 'date-of-birth';
      case QuestionType.schoolYear: return 'school-year';
    }
  }

  static QuestionType? fromJsonString(String? value) {
    switch (value) {
      case 'check-list': return QuestionType.checkList;
      case 'date-of-birth': return QuestionType.dateOfBirth;
      case 'school-year': return QuestionType.schoolYear;
      default: return null;
    }
  }
}

 extension QuestionVisibiltyImpl on QuestionVisibilty {

  String toJsonString() {
    switch (this) {
      case QuestionVisibilty.public: return 'public';
      case QuestionVisibilty.research: return 'research';
    }
  }

  static QuestionVisibilty? fromJsonString(String? value) {
    switch (value) {
      case 'public': return QuestionVisibilty.public;
      case 'research': return QuestionVisibilty.research;
      default: return null;
    }
  }
}

extension QuestionVisibilityExt on Question {
  bool get isPubliclyVisible => (visibility == null) || (visibility == QuestionVisibilty.public);
  bool get isResearhVisible => isPubliclyVisible || (visibility == QuestionVisibilty.research);
}

extension DateOfBirthQuestion on Question {
  static const int dobOrgYear = 1900;
  static final DateTime dobOrgDate = DateTime(dobOrgYear, 1, 1);

  static DateTime? fromDOBString(String? value) {
    int? numberOfDays = (value != null) ? int.tryParse(value) : null;
    return (numberOfDays != null) ? dobOrgDate.add(Duration(days: numberOfDays)) : null;
  }

  static String toDOBString(DateTime value) =>
    value.difference(dobOrgDate).inDays.toString();
}

extension SchoolYearQuestion on Question {

  // We asume the school year starts on Aug 20
  static const int schoolYearOrgMonth = 8;
  static const int schoolYearOrgDay = 20;
  
  static int get currentSchoolYear {
    DateTime now = DateTime.now();
    int schoolYear = now.year;
    DateTime schoolYearOrg = DateTime(schoolYear, schoolYearOrgMonth, schoolYearOrgDay);
    return schoolYearOrg.isBefore(now) ? schoolYear : (schoolYear - 1);
  }
}