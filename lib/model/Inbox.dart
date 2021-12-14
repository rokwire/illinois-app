import 'package:collection/collection.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/utils/Utils.dart';
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
      messageId: AppJson.stringValue(json['id']),
      priority: AppJson.intValue(json['priority']),
      topic: AppJson.stringValue(json['topic']),
      category: AppJson.stringValue(json['category']),

      dateCreatedUtc: AppDateTime().dateTimeFromString(AppJson.stringValue(json['date_created'])),
      dateUpdatedUtc: AppDateTime().dateTimeFromString(AppJson.stringValue(json['date_updated'])),
      dateSentUtc: AppDateTime().dateTimeFromString(AppJson.stringValue(json['date_sent'])),

      subject: AppJson.stringValue(json['subject']),
      body: AppJson.stringValue(json['body']),
      data: AppJson.mapValue(json['data']),

      sender: InboxSender.fromJson(AppJson.mapValue(json['sender'])),
      recepients: InboxRecepient.listFromJson(AppJson.listValue(json['recipients']))
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': messageId,
      'priority': priority,
      'topic': topic,

      'date_created': AppDateTime.utcDateTimeToString(dateCreatedUtc),
      'date_updated': AppDateTime.utcDateTimeToString(dateUpdatedUtc),
      'date_sent': AppDateTime.utcDateTimeToString(dateSentUtc),

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
        AppList.add(result, InboxMessage.fromJson(AppJson.mapValue(jsonEntry)));
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
    if (sender?.type == InboxSenderType.System) {
      return 'System';
    }
    else if (sender?.type == InboxSenderType.User) {
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
      userId: AppJson.stringValue(json['user_id'])
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
        AppList.add(result, InboxRecepient.fromJson(AppJson.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<InboxRecepient?>? recepientsList) {
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
      type: inboxSenderTypeFromString(AppJson.stringValue(json['type'])),
      user: InboxSenderUser.fromJson(AppJson.mapValue(json['user'])),
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
      userId: AppJson.stringValue(json['user_id']),
      name: AppJson.stringValue(json['name']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
    };
  }
}

enum InboxSenderType { System, User }

InboxSenderType? inboxSenderTypeFromString(String? value) {
  if (value == 'system') {
    return InboxSenderType.System;
  }
  else if (value == 'user') {
    return InboxSenderType.User;
  }
  else {
    return null;
  }
}

String? inboxSenderTypeToString(InboxSenderType? value) {
  if(value == InboxSenderType.System) {
    return 'system';
  }
  else if (value == InboxSenderType.User) {
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
      userId: AppJson.stringValue(json["user_id"]),
      dateCreated: AppJson.stringValue(json["date_created"]),
      dateUpdated: AppJson.stringValue(json["date_updated"]),
      notificationsDisabled: AppJson.boolValue(json["notifications_disabled"]),
      topics: AppJson.stringSetValue(json["topics"]),
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

  bool operator ==(o) =>
    (o is InboxUserInfo) &&
      (o.userId == userId) &&
      (o.dateCreated == dateCreated) &&
      (o.dateUpdated == dateUpdated) &&
      (o.notificationsDisabled == notificationsDisabled)&&
      (DeepCollectionEquality().equals(o.topics, topics));

  int get hashCode =>
    (userId?.hashCode ?? 0) ^
    (dateCreated?.hashCode ?? 0) ^
    (dateUpdated?.hashCode ?? 0) ^
    (notificationsDisabled?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(topics));
}