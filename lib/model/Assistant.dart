import 'package:rokwire_plugin/utils/utils.dart';

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
  'map.mtd_destinations': 'My Destinations',
  'map.mental_health': 'Find a Therapist',
  'map.state_farm_wayfinding': 'State Farm Wayfinding',
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
  'wellness.struggling': 'I\'m Struggling',
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

class Message {
  static final String _unknownAnswerValue = "I don't know";

  final String id;
  final String content;
  final bool user;
  final bool example;
  final List<Link>? links;
  final List<String> sources;
  final bool acceptsFeedback;
  final int? queryLimit;
  MessageFeedback? feedback;
  String? feedbackExplanation;

  bool? sourcesExpanded;
  FeedbackResponseType? feedbackResponseType;
  bool? isNegativeFeedbackMessage;

  Message({this.id = '', required this.content, required this.user, this.example = false, this.acceptsFeedback = false,
    this.links, this.sources = const [], this.queryLimit, this.feedback,  this.feedbackExplanation,
    this.sourcesExpanded, this.feedbackResponseType, this.isNegativeFeedbackMessage});

  factory Message.fromAnswerJson(Map<String, dynamic> json) {
    Map<String, dynamic>? answerJson = JsonUtils.mapValue(json['answer']);
    Map<String, dynamic>? feedbackJson = JsonUtils.mapValue(json['feedback']);

    List<String>? sources = JsonUtils.stringListValue(answerJson?['sources']);
    if (sources == null) {
      String? source = JsonUtils.stringValue(answerJson?['sources']);
      if (StringUtils.isNotEmpty(source)) {
        sources = source!.split((RegExp(r'[,\n]')));
        sources = sources.map((e) => e.trim()).toList();
      }
    }

    List<Link>? deeplinks = Link.listFromJson(answerJson?['deeplinks']);
    String? deeplink = JsonUtils.stringValue(answerJson?['deeplink'])?.trim();
    if (deeplink != null) {
      if (deeplinks == null) {
        deeplinks = [];
      }
      deeplinks.add(Link(name: deeplinkNameMap[deeplink] ?? deeplink.split('.|_').join(' '), link: deeplink));
    }

    return Message(
      id: JsonUtils.stringValue(json['id'])?.trim() ?? '',
      content: JsonUtils.stringValue(answerJson?['answer'])?.trim() ?? '',
      user: JsonUtils.boolValue(answerJson?['user']) ?? false,
      example: JsonUtils.boolValue(answerJson?['example']) ?? false,
      queryLimit: JsonUtils.intValue(answerJson?['query_limit']),
      acceptsFeedback: JsonUtils.boolValue(answerJson?['accepts_feedback']) ?? true,
      links: deeplinks,
      sources: sources ?? [],
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

enum FeedbackResponseType { positive, negative }

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

enum MessageFeedback { good, bad }