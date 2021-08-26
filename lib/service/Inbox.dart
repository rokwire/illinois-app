import 'dart:math';

import 'package:illinois/model/Inbox.dart';

/// Inbox service does rely on Service initialization API so it does not override service interfaces and is not registered in Services.
class Inbox /* with Service */ {

  static final Inbox _instance = Inbox._internal();

  factory Inbox() {
    return _instance;
  }

  Inbox._internal();

  Future<List<InboxMessage>> loadMessages({DateTime startDate, DateTime endDate, String type, int offset, int limit }) async {
    return Future.delayed(Duration(seconds: 3), () {
      List<String> subjects = ['Important!', 'Exclusive News', 'Disappointing News', 'Attention Required', 'Silent Notification', 'Test Message', 'Incredible Event'];
      List<String> categories = ['Admin', 'Academic', 'Athletics', 'Community', 'Entertainment', 'Recreation', 'Other'];
      List<String> bodies = [
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus semper pretium eros vel finibus. Cras eleifend, sem id lobortis tristique, tellus nisl efficitur erat, sed consequat lacus mi at orci.',
        'Duis vitae ex sed leo laoreet tincidunt in id diam. Quisque pharetra, diam ac maximus pellentesque, turpis erat tincidunt neque, nec feugiat tortor dolor hendrerit eros.',
        'Vestibulum sed justo eu eros faucibus ultrices quis nec urna. Fusce interdum iaculis turpis, tristique bibendum mi tristique commodo.',
        'Integer interdum, ex id aliquet tincidunt, est ligula rutrum dui, sit amet finibus ex lorem quis felis. Aenean quis ornare dolor.'
        'Donec vulputate suscipit pulvinar. Nam nec tempus lectus.',
        'Proin sed velit egestas, porttitor leo vitae, cursus nisi.'
      ];
      List<InboxMessage> result = <InboxMessage>[];
      for (int index = 0; index < 10; index++) {
        result.add(InboxMessage(
          messageId: '${100 + index}',
          subject: subjects[Random().nextInt(subjects.length)],
          body: bodies[Random().nextInt(bodies.length)],
          category: categories[Random().nextInt(categories.length)],
          dateSentUtc: DateTime(2021, 8, 1 + index, 10, 0, 0),
          sender: InboxSender(type: InboxSenderType.User, user: InboxSenderUser(email: 'misho@inabyte.bg'))));
      }
      return result;
    });
  }

}