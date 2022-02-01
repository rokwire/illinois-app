import 'package:collection/collection.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';

class InboxMessage with Favorite {
  final String?   messageId;
  final int?      priority;
  final String?   topic;
  final String?   category;
  
  final DateTime? dateCreatedUtc;
  final DateTime? dateUpdatedUtc;
  final DateTime? dateSentUtc;

  final String?   subject;
  final String?   body;
  final Map<String, dynamic>? data;
  
  final InboxSender?          sender;
  final List<InboxRecepient>? recepients;

  InboxMessage({this.messageId, this.priority, this.topic, this.category,
    this.dateCreatedUtc, this.dateUpdatedUtc, this.dateSentUtc,
    this.subject, this.body, this.data,
    this.sender, this.recepients
  });

  static InboxMessage? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? InboxMessage(
      messageId: JsonUtils.stringValue(json['id']),
      priority: JsonUtils.intValue(json['priority']),
      topic: JsonUtils.stringValue(json['topic']),
      category: JsonUtils.stringValue(json['category']),

      dateCreatedUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['date_created'])),
      dateUpdatedUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['date_updated'])),
      dateSentUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['date_sent'])),

      subject: JsonUtils.stringValue(json['subject']),
      body: JsonUtils.stringValue(json['body']),
      data: JsonUtils.mapValue(json['data']),

      sender: InboxSender.fromJson(JsonUtils.mapValue(json['sender'])),
      recepients: InboxRecepient.listFromJson(JsonUtils.listValue(json['recipients']))
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': messageId,
      'priority': priority,
      'topic': topic,

      'date_created': DateTimeUtils.utcDateTimeToString(dateCreatedUtc),
      'date_updated': DateTimeUtils.utcDateTimeToString(dateUpdatedUtc),
      'date_sent': DateTimeUtils.utcDateTimeToString(dateSentUtc),

      'subject': subject,
      'body': body,
      'data': data,

      'sender': sender?.toJson(),
      'recipients': InboxRecepient.listToJson(recepients),
    };
  }

  static List<InboxMessage>? listFromJson(List<dynamic>? jsonList) {
    List<InboxMessage>? result;
    if (jsonList != null) {
      result = [];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, InboxMessage.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<InboxMessage>? messagesList) {
    List<dynamic>? result;
    if (messagesList != null) {
      result = [];
      for (dynamic message in messagesList) {
        result.add(message?.toJson());
      }
    }
    return result;
  }

  // Accessies

  String get displaySender {
    if (sender?.type == InboxSenderType.system) {
      return 'System';
    }
    else if (sender?.type == InboxSenderType.user) {
      return sender?.user?.name ?? 'Unknown';
    }
    else {
      return 'Unknown';
    }
  }

  String? get displayInfo {
    
    DateTime? deviceDateTime = AppDateTime().getDeviceTimeFromUtcTime(dateSentUtc ?? dateCreatedUtc);
    if (deviceDateTime != null) {
      DateTime now = DateTime.now();
      if (deviceDateTime.compareTo(now) < 0) {
        Duration difference = DateTime.now().difference(deviceDateTime);
        if (difference.inSeconds < 60) {
          return 'Sent by $displaySender now.';
        }
        else if (difference.inMinutes < 60) {
          return sprintf((difference.inMinutes != 1) ?
            'Sent by %s about %s minutes ago.' :
            'Sent by %s about a minute ago.',
            [displaySender, difference.inMinutes]);
        }
        else if (difference.inHours < 24) {
          return sprintf((difference.inHours != 1) ?
            'Sent by %s about %s hours ago.' :
            'Sent by %s about an hour ago.',
            [displaySender, difference.inHours]);
        }
        else if (difference.inDays < 30) {
          return sprintf((difference.inDays != 1) ?
            'Sent by %s about %s days ago.' :
            'Sent by %s about a day ago.',
            [displaySender, difference.inDays]);
        }
        else {
          int differenceInMonths = difference.inDays ~/ 30;
          if (differenceInMonths < 12) {
            return sprintf((differenceInMonths != 1) ?
              'Sent by %s about %s months ago.' :
              'Sent by %s about a month ago.',
              [displaySender, differenceInMonths]);
          }
        }
      }
      String value = DateFormat("MMM dd, yyyy").format(deviceDateTime);
      return sprintf(
        'Sent by %s on %s.',
        [displaySender, value]);
    }
    else {
      return "Sent by $displaySender";
    }
  }

  // Favorite

  @override
  String? get favoriteId => messageId;

  @override
  String? get favoriteTitle => subject;

  @override
  String get favoriteKey => favoriteKeyName;

  static String favoriteKeyName = "InboxMessageIds";
}

class InboxRecepient {
  final String? userId;
  
  InboxRecepient({this.userId});

  static InboxRecepient? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? InboxRecepient(
      userId: JsonUtils.stringValue(json['user_id'])
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
    };
  }

  static List<InboxRecepient>? listFromJson(List<dynamic>? jsonList) {
    List<InboxRecepient>? result;
    if (jsonList != null) {
      result = [];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, InboxRecepient.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<InboxRecepient>? recepientsList) {
    List<dynamic>? result;
    if (recepientsList != null) {
      result = [];
      for (dynamic recepient in recepientsList) {
        result.add(recepient?.toJson());
      }
    }
    return result;
  }
}

class InboxSender {
  final InboxSenderType? type;
  final InboxSenderUser? user;

  InboxSender({this.type, this.user});

  static InboxSender? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? InboxSender(
      type: inboxSenderTypeFromString(JsonUtils.stringValue(json['type'])),
      user: InboxSenderUser.fromJson(JsonUtils.mapValue(json['user'])),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': inboxSenderTypeToString(type),
      'user': user?.toJson(),
    };
  }  
}

class InboxSenderUser {
  final String? userId;
  final String? name;

  InboxSenderUser({this.userId, this.name,});

  static InboxSenderUser? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? InboxSenderUser(
      userId: JsonUtils.stringValue(json['user_id']),
      name: JsonUtils.stringValue(json['name']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
    };
  }
}

enum InboxSenderType { system, user }

InboxSenderType? inboxSenderTypeFromString(String? value) {
  if (value == 'system') {
    return InboxSenderType.system;
  }
  else if (value == 'user') {
    return InboxSenderType.user;
  }
  else {
    return null;
  }
}

String? inboxSenderTypeToString(InboxSenderType? value) {
  if(value == InboxSenderType.system) {
    return 'system';
  }
  else if (value == InboxSenderType.user) {
    return 'user';
  }
  else {
    return null;
  }
}

class InboxUserInfo{
  String? userId;
  String? dateCreated;
  String? dateUpdated;
  Set<String?>? topics;
  bool? notificationsDisabled;

  InboxUserInfo({this.userId, this.dateCreated, this.dateUpdated, this.topics, this.notificationsDisabled});

  static InboxUserInfo? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? InboxUserInfo(
      userId: JsonUtils.stringValue(json["user_id"]),
      dateCreated: JsonUtils.stringValue(json["date_created"]),
      dateUpdated: JsonUtils.stringValue(json["date_updated"]),
      notificationsDisabled: JsonUtils.boolValue(json["notifications_disabled"]),
      topics: JsonUtils.stringSetValue(json["topics"]),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      "date_created" : dateCreated,
      "date_updated" : dateUpdated,
      "notifications_disabled": notificationsDisabled,
      "topics" : topics?.toList(),
    };
  }

  @override
  bool operator ==(other) =>
    (other is InboxUserInfo) &&
      (other.userId == userId) &&
      (other.dateCreated == dateCreated) &&
      (other.dateUpdated == dateUpdated) &&
      (other.notificationsDisabled == notificationsDisabled)&&
      (const DeepCollectionEquality().equals(other.topics, topics));

  @override
  int get hashCode =>
    (userId?.hashCode ?? 0) ^
    (dateCreated?.hashCode ?? 0) ^
    (dateUpdated?.hashCode ?? 0) ^
    (notificationsDisabled?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(topics));
}