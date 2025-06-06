import 'package:geolocator/geolocator.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

///
/// Deep link name map
///
Map<String, String> deeplinkNameMap = {
  'home': 'Home',
  'browse': 'Browse',
  'map': 'Map',
  'map.events': 'Events',
  'map.dining': 'Residence Hall Dining',
  'map.buildings': 'Campus Buildings',
  'map.student_courses': 'My Courses',
  'map.appointments': 'MyMcKinley In-Person Appointments',
  'map.mtd_stops': 'Bus Stops',
  'map.my_locations': 'My Locations',
  'map.mental_health': 'Find a Therapist',
  'academics': 'Academics',
  'academics.gies_checklist': 'iDegrees New Student Checklist',
  'academics.uiuc_checklist': 'New Student Checklist',
  'academics.events': 'Academic Events',
  'academics.canvas_courses': 'My Canvas Courses',
  'academics.gies_canvas_courses': 'My Gies Canvas Courses',
  'academics.medicine_courses': 'My College of Medicine Compliance',
  'academics.student_courses': 'My Courses',
  'academics.skills_self_evaluation': 'Skills Self-Evaluation',
  'academics.todo_list': 'To-Do List',
  'academics.due_date_catalog': 'Due Date Catalog',
  'academics.my_illini': 'myIllini',
  'academics.appointments': 'Appointments',
  'wellness': 'Wellness',
  'wellness.daily_tips': 'Today\'s Wellness Tip',
  'wellness.rings': 'Daily Wellness Rings',
  'wellness.todo': 'To-Do List',
  'wellness.appointments': 'MyMcKinley Appointments',
  'wellness.health_screener': 'Illinois Health Screener',
  'wellness.podcast': 'Healthy Illini Podcast',
  'wellness.resources': 'Wellness Resources',
  'wellness.mental_health': 'Mental Health Resources',
  'inbox': 'Inbox Panel',
  'appointment': 'Appointment',
  'profile.my': 'My Profile',
  'profile.who_are_you': 'Who Are You?',
  'profile.privacy': 'My App Privacy Settings',
  'settings.sections': 'Sign In/Sign Out',
  'settings.interests': 'My Interests',
  'settings.food_filters': 'My Food Filters',
  'settings.sports': 'My Sports Teams',
  'settings.favorites': 'Customize Favorites',
  'settings.assessments': 'My Assessments',
  'settings.calendar': 'My Calendar Settings',
  'settings.appointments': 'MyMcKinley Appointments',
  'event_detail': 'Event Detail',
  'game_detail': 'Athletics Game Detail',
  'athletics_game_started': 'Athletics Game Detail',
  'athletics_news_detail': 'Athletics News Detail',
  'group': 'Group Detail',
  'canvas_app_deeplink': 'Canvas Student',
  'wellness_todo_entry': 'Wellness To-Do item',
  'poll': 'Poll Detail',
};

///
/// Message
///
class Message {
  static final String _unknownAnswerValue = "I don't know";

  final String id;
  final String content;
  final bool user;
  final bool example;
  final List<Link>? links;
  final List<SourceDataEntry>? sourceDatEntries;
  final Events2ListResult? eventsResult;
  final bool acceptsFeedback;
  final int? queryLimit;
  MessageFeedback? feedback;
  String? feedbackExplanation;

  AssistantProvider? provider;

  bool? sourcesExpanded;
  FeedbackResponseType? feedbackResponseType;
  bool? isNegativeFeedbackMessage;

  Message({this.id = '', required this.content, required this.user, this.example = false, this.acceptsFeedback = false,
    this.links, this.sourceDatEntries, this.eventsResult, this.queryLimit, this.feedback,  this.feedbackExplanation, this.provider,
    this.sourcesExpanded, this.feedbackResponseType, this.isNegativeFeedbackMessage});

  factory Message.fromAnswerJson(Map<String, dynamic> json) {
    Map<String, dynamic>? answerJson = JsonUtils.mapValue(json['answer']);
    Map<String, dynamic>? feedbackJson = JsonUtils.mapValue(json['feedback']);

    List<Link>? deeplinks = Link.listFromJson(answerJson?['deeplinks']);
    String? deeplink = JsonUtils.stringValue(answerJson?['deeplink'])?.trim();
    if (deeplink != null) {
      if (deeplinks == null) {
        deeplinks = [];
      }
      deeplinks.add(Link(name: deeplinkNameMap[deeplink] ?? deeplink.split('.|_').join(' '), link: deeplink));
    }

    List<dynamic>? structOutput = JsonUtils.listValue(answerJson?['struct_output']);
    Map<String, dynamic>? firstStruct = (structOutput != null && structOutput.isNotEmpty) ? structOutput.first : null;
    Events2ListResult? events2ListResult = Events2ListResult.fromJson(firstStruct);

    return Message(
      id: JsonUtils.stringValue(json['id'])?.trim() ?? '',
      content: JsonUtils.stringValue(answerJson?['answer'])?.trim() ?? '',
      user: JsonUtils.boolValue(answerJson?['user']) ?? false,
      example: JsonUtils.boolValue(answerJson?['example']) ?? false,
      queryLimit: JsonUtils.intValue(answerJson?['query_limit']),
      acceptsFeedback: JsonUtils.boolValue(answerJson?['accepts_feedback']) ?? true,
      links: deeplinks,
      sourceDatEntries: SourceDataEntry.listFromJson(answerJson?['source_data_entries']),
      eventsResult: events2ListResult,
      feedback: _feedbackFromString(JsonUtils.stringValue(feedbackJson?['feedback'])),
      feedbackExplanation: JsonUtils.stringValue(feedbackJson?['explanation']),
    );
  }

  factory Message.fromQueryJson(Map<String, dynamic> json) {
    Map<String, dynamic>? queryJson = JsonUtils.mapValue(json['query']);

    return Message(
        id: JsonUtils.stringValue(json['id'])?.trim() ?? '',
        content: StringUtils.ensureNotEmpty(JsonUtils.stringValue(queryJson?['question'])),
        user: true,
        example: false,
        acceptsFeedback: false,
        feedback: null,
        feedbackExplanation: null);
  }

  static MessageFeedback? _feedbackFromString(String? value) {
    switch (value) {
      case 'bad':
        return MessageFeedback.bad;
      case 'good':
        return MessageFeedback.good;
      default:
        return null;
    }
  }

  bool get isAnswerUnknown => (content.toLowerCase() == _unknownAnswerValue.toLowerCase());
}

///
/// SourceDataEntry
///
class SourceDataEntry {
  final String? actionLink;
  final dynamic metaData;
  final String? title;
  final String? subTitle;
  final String? type;

  SourceDataEntry({this.actionLink, this.metaData, this.title, this.subTitle, this.type});

  static SourceDataEntry? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return SourceDataEntry(actionLink: JsonUtils.stringValue(json['action_link']), metaData: json['meta_data'], title: JsonUtils.stringValue(json['title']), subTitle: JsonUtils.stringValue(json['subtitle']), type: JsonUtils.stringValue(json['type']));
  }

  static List<SourceDataEntry>? listFromJson(List<dynamic>? jsonList) {
    List<SourceDataEntry>? items;
    if (CollectionUtils.isNotEmpty(jsonList)) {
      items = <SourceDataEntry>[];
      for (dynamic jsonEntry in jsonList!) {
        ListUtils.add(items, SourceDataEntry.fromJson(jsonEntry));
      }
    }
    return items;
  }
}

///
/// FeedbackResponseType
///
enum FeedbackResponseType { positive, negative }

///
/// Link
///
class Link {
  final String name;
  final String link;
  final String? iconKey;
  final Map<String, dynamic>? params;

  Link({required this.name, required this.link, this.iconKey, this.params});

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      name: JsonUtils.stringValue(json['name']) ?? '',
      link: JsonUtils.stringValue(json['link']) ?? '',
      iconKey: JsonUtils.stringValue(json['icon_key']),
      params: JsonUtils.mapValue(json['params']),
    );
  }

  static List<Link>? listFromJson(List<dynamic>? jsonList) {
    List<Link>? items;
    if (jsonList != null && jsonList.isNotEmpty) {
      items = <Link>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(items, Link.fromJson(jsonEntry));
      }
    }
    return items;
  }
}

///
/// AssistantLocation
///
class AssistantLocation {
  final double? latitude;
  final double? longitude;

  AssistantLocation({this.latitude, this.longitude});

  static AssistantLocation? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return AssistantLocation(latitude: JsonUtils.doubleValue(json['latitude']), longitude: JsonUtils.doubleValue(json['longitude']));
  }

  static AssistantLocation? fromPosition(Position? position) {
    if (position == null) {
      return null;
    }
    return AssistantLocation(latitude: position.latitude, longitude: position.longitude);
  }

  static AssistantLocation? fromExploreLocation(ExploreLocation? exploreLocation) {
    if (exploreLocation == null) {
      return null;
    }
    return AssistantLocation(latitude: exploreLocation.latitude, longitude: exploreLocation.longitude);
  }

  Map<String, dynamic> toJson() => {'latitude': latitude, 'longitude': longitude};

  ExploreLocation toExploreLocation() => ExploreLocation(latitude: latitude, longitude: longitude);

  @override
  bool operator ==(Object other) => (other is AssistantLocation) && (latitude == other.latitude) && (longitude == other.longitude);

  @override
  int get hashCode => (latitude?.hashCode ?? 0) ^ (longitude?.hashCode ?? 0);
}

///
/// AssistantUser
///
class AssistantUser {
  final DateTime? termsAcceptedDateUtc;

  AssistantUser({this.termsAcceptedDateUtc});

  static AssistantUser? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return AssistantUser(termsAcceptedDateUtc: DateTimeUtils.dateTimeFromSecondsSinceEpoch(JsonUtils.intValue(json['terms_accepted_date']), isUtc: true));
  }

  @override
  bool operator ==(Object other) => (other is AssistantUser) && (termsAcceptedDateUtc == other.termsAcceptedDateUtc);

  @override
  int get hashCode => (termsAcceptedDateUtc?.hashCode ?? 0);
}

///
/// AssistantSettings
///
class AssistantSettings {
  final bool? available;
  final DateTime? termsAcceptedDateUtc;
  final Map<String, String?>? termsTextJson;
  final Map<String, String?>? unavailableTextJson;

  AssistantSettings({this.available, this.termsAcceptedDateUtc, this.termsTextJson, this.unavailableTextJson});

  static AssistantSettings? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return AssistantSettings(
        available: JsonUtils.boolValue(json['available']),
        termsAcceptedDateUtc: DateTimeUtils.dateTimeFromSecondsSinceEpoch(JsonUtils.intValue(json['terms_accepted_date']), isUtc: true),
        termsTextJson: JsonUtils.mapCastValue<String, String?>(json['terms_text']),
        unavailableTextJson: JsonUtils.mapCastValue<String, String?>(json['unavailable_text'])
    );
  }

  String? getTermsText({String? locale}) => termsTextJson?[locale ?? 'en'];
  String? getUnavailableText({String? locale}) => unavailableTextJson?[locale ?? 'en'];

  @override
  bool operator ==(Object other) => (other is AssistantSettings) && (available == other.available) &&
      (termsTextJson == other.termsTextJson) && (unavailableTextJson == other.unavailableTextJson) &&
      (termsAcceptedDateUtc == other.termsAcceptedDateUtc);

  @override
  int get hashCode => (available?.hashCode ?? 0) ^ (termsTextJson?.hashCode ?? 0) ^ (unavailableTextJson?.hashCode ?? 0) ^
    (termsAcceptedDateUtc?.hashCode ?? 0);
}

///
/// MessageFeedback
///
enum MessageFeedback { good, bad }

///
/// AssistantProvider
///
enum AssistantProvider { google, grok, perplexity, openai }

String? assistantProviderToKeyString(AssistantProvider? provider) {
  switch (provider) {
    case AssistantProvider.google:
      return 'google';
    case AssistantProvider.grok:
      return 'grok';
    case AssistantProvider.perplexity:
      return 'perplexity';
    case AssistantProvider.openai:
      return 'openai';
    default:
      return null;
  }
}

String assistantProviderToDisplayString(AssistantProvider? provider) {
  switch (provider) {
    case AssistantProvider.google:
      return Localization().getStringEx('model.assistant.provider.google.label', 'Google');
    case AssistantProvider.grok:
      return Localization().getStringEx('model.assistant.provider.grok.label', 'Grok');
    case AssistantProvider.perplexity:
      return Localization().getStringEx('model.assistant.provider.perplexity.label', 'Perplexity');
    case AssistantProvider.openai:
      return Localization().getStringEx('model.assistant.provider.openai.label', 'Illinois');
    default:
      return Localization().getStringEx('model.assistant.provider.unknown.label', 'Unknown');
  }
}
