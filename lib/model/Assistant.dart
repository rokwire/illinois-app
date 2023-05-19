class Message {
  String content;
  bool user;
  bool example;
  Link? link;
  MessageFeedback? feedback;
  String? feedbackExplanation;

  Message({required this.content, required this.user, this.example = false, this.link, this.feedback, this.feedbackExplanation});
}

class Link {
  String name;
  String link;
  String? iconKey;

  Link({required this.name, required this.link, this.iconKey});
}

enum MessageFeedback { good, bad }