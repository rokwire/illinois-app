import 'package:rokwire_plugin/utils/utils.dart';

class Message {
  final String content;
  final bool user;
  final bool example;
  final Link? link;
  final List<String> sources;
  MessageFeedback? feedback;
  String? feedbackExplanation;

  Message({required this.content, required this.user, this.example = false,
    this.link, this.sources = const [], this.feedback, this.feedbackExplanation});

  factory Message.fromAnswerJson(Map<String, dynamic> json) {
    return Message(
      content: JsonUtils.stringValue(json['answer']) ?? '',
      user: JsonUtils.boolValue(json['user']) ?? false,
      example: JsonUtils.boolValue(json['example']) ?? false,
      link: null,
      sources: JsonUtils.stringListValue(json['sources']) ?? [],
      feedback: null,
      feedbackExplanation: null,
    );
  }
}

class Link {
  final String name;
  final String link;
  final String? iconKey;

  Link({required this.name, required this.link, this.iconKey});
}

enum MessageFeedback { good, bad }