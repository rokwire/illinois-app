import 'package:collection/collection.dart';
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
  bool operator==(dynamic other) =>
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

class Question {
  final String? id;
  final String? title;
  final String? hint;
  final String? descriptionPrefix;
  final String? descriptionSuffix;
  final int? minAnswers;
  final int? maxAnswers;
  final List<Answer>? answers;

  Question({this.id, this.title, this.hint, this.descriptionPrefix, this.descriptionSuffix, this.minAnswers, this.maxAnswers, this.answers});

  // JSON serialization

  static Question? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Question(
      id: JsonUtils.stringValue(json['id']),
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
  bool operator==(dynamic other) =>
    (other is Question) &&
    (id == other.id) &&
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
  final String? id;
  final String? title;
  final String? hint;

  Answer({this.id, this.title, this.hint});

  // JSON serialization

  static Answer? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Answer(
      id: JsonUtils.stringValue(json['id']),
      title: JsonUtils.stringValue(json['title']),
      hint: JsonUtils.stringValue(json['hint']),
    ) : null;
  }

  toJson() => {
    'id': id,
    'title': title,
    'hint': hint,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is Answer) &&
    (id == other.id) &&
    (title == other.title) &&
    (hint == other.hint);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (title?.hashCode ?? 0) ^
    (hint?.hashCode ?? 0);

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

  // Accessories

  String? get displayHint => hint ?? title;
}