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
    List<String>? sources = JsonUtils.stringListValue(json['sources']);
    if (sources == null) {
      String? source = JsonUtils.stringValue(json['sources']);
      if (source != null) {
        sources = source.split(',');
        sources = sources.map((e) => e.trim()).toList();
      }
    }
    return Message(
      content: JsonUtils.stringValue(json['answer'])?.trim() ?? '',
      user: JsonUtils.boolValue(json['user']) ?? false,
      example: JsonUtils.boolValue(json['example']) ?? false,
      link: null,
      sources: sources ?? [],
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