/*
 * Copyright 2024 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/datetime_utils.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension PostExt on Post {
  PostType get type =>
      (authorizationContext?.items?.firstWhereOrNull((item) => item.members?.type == ContextItemMembersType.listed_accounts) != null)
          ? PostType.direct_message
          : PostType.post;

  bool get isPost => (type == PostType.post);
  bool get isMessage => (type == PostType.direct_message);
  bool get isScheduled => (status == PostStatus.draft);

  int get commentsCount => (details?.commentsCount ?? 0);

  String? get displayDateTime => AppRelativeTime.timeAgoSinceDate(dateCreatedUtc);

  String? get displayScheduledTime {
    DateTime? displayDateTime = AppDateTime().getDateTimeToCompare(dateTimeUtc: dateActivatedUtc);
    if (displayDateTime != null) {
      return DateFormat("MMM dd, HH:mm").format(displayDateTime);
    }
    return null;
  }

  DateTime? get dateActivatedLocal => (dateActivatedUtc != null) ? AppDateTime().getDisplayTZDateTime(dateActivatedUtc!) : null;

  String? get creatorName => creator?.name;
  String? get creatorId => creator?.accountId;
  bool get createdByUser => creatorId == Auth2().accountId;
}

extension CommentExt on Comment {
  String? get displayDateTime => AppRelativeTime.timeAgoSinceDate(dateCreatedUtc);

  String? get creatorName => creator?.name;
  String? get creatorId => creator?.accountId;
}

extension ReactionExt on Reaction {
  String? get engagerName => engager?.name;
  String? get engagerId => engager?.accountId;
  bool get isCurrentUserReacted => (Auth2().accountId == engagerId);
  String? get emoji => data?["emoji_source"];
  String? get emojiName => data?["emoji_name"];

  /// Returns Key: Emoji.emoji and Value: List of all Reactions with this emoji
  static   Map<String, List<Reaction>>?  extractSameEmojiReactions(List<Reaction>? reactions){
    return reactions?.fold(<String, List<Reaction>>{}, (map, element) {
      if(element.type == ReactionType.emoji &&  element.data != null){
        List<Reaction>? collection = map?[element.emoji];
        if(collection == null){
          map?[element.emoji!] = collection = <Reaction>[];
        }
        collection?.add(element);
      }
      return map;
    });
  }

  static  List<Reaction>? extractUsersReactions(Iterable<Reaction>? reactions, {String? emoji}) =>
      reactions?.where((Reaction reaction) =>
          (emoji == null || reaction.emoji == emoji) &&
          reaction.isCurrentUserReacted
      ).toList();
}

extension MessageExt on Message {
  DateTime? get dateSentLocal =>  AppDateTime().getDateTimeToCompare(dateTimeUtc: dateSentUtc);
  String? get dateSentLocalString => DateTimeUtils.localDateTimeToString(dateSentLocal, format: 'MMMM dd, yyyy');

  String? get displayDateTime => AppRelativeTime.timeAgoSinceDate(dateUpdatedUtc ?? dateSentUtc);

  String? get identityKey => (((id != null) && (id?.isNotEmpty == true)) && ((globalId != null) && (globalId?.isNotEmpty == true))) ?
    "${id}:${globalId}" : null;

  static bool matchIdentityKey(String identityKey, { String? messageId, String? messageGlobalId}) {
    List<String> sections = identityKey.split(':');
    return (sections.length == 2) &&
      ((messageId == null) || (messageId == sections.first)) &&
      ((messageGlobalId == null) || (messageGlobalId == sections.last));
  }

  Iterable<String>? get attachmentFileKeys => fileAttachments?.map((fileAttachment) => fileAttachment.id).nonNulls;

  static List<String> collectAttachmentFileKeysFromList(List<Message> messages) {
    List<String> result = <String>[];
    for (Message message in messages) {
      Iterable<String>? messageKeys = message.attachmentFileKeys;
      if ((messageKeys != null) && messageKeys.isNotEmpty) {
        result.addAll(messageKeys);
      }
    }
    return result;
  }

  static void applyContentRefsToList(List<Message> messages, { required Map<String, FileContentItemReference> fileRefsMap }) {
    for (Message message in messages) {
      if (message.fileAttachments?.isNotEmpty == true) {
        for (FileAttachment attachment in message.fileAttachments ?? []) {
          attachment.url ??= fileRefsMap[attachment.id]?.url;
        }
      }
    }
  }
}

extension ConversationExt on Conversation {

  bool get isGroup => (type?.isGroup == true);
  bool get isGroupAll => (type == ConversationType.groupAll);
  bool get isGroupSubset => (type == ConversationType.groupSubset);

  String? get displayDateTime {
    DateTime? displayDateTime = AppDateTime().getDateTimeToCompare(dateTimeUtc: lastActivityTimeUtc);
    if (displayDateTime != null) {
      DateTime now = DateTime.now();
      if (displayDateTime.compareTo(now) < 0) {
        Duration difference = DateTime.now().difference(displayDateTime);
        if (difference.inSeconds < 60) {
          return Localization().getStringEx("generic.time.now", "now");
        }
        else if (difference.inMinutes < 60) {
          return "${difference.inMinutes} ${difference.inMinutes > 1 ? Localization().getStringEx("generic.time.minutes", "minutes") : Localization().getStringEx("generic.time.minute", "minute")}";
        }
        else if (difference.inHours < 24) {
          return "${difference.inHours} ${difference.inHours > 1 ? Localization().getStringEx("generic.time.hours", "hours") : Localization().getStringEx("generic.time.hour", "hour")}";
        }
        else if (difference.inDays < 30) {
          return "${difference.inDays} ${difference.inDays > 1 ? Localization().getStringEx("generic.time.days", "days") : Localization().getStringEx("generic.time.day", "day")}";
        }
        else {
          int differenceInMonths = difference.inDays ~/ 30;
          if (differenceInMonths < 12) {
            return "$differenceInMonths ${differenceInMonths > 1 ? Localization().getStringEx("generic.time.months", "months") : Localization().getStringEx("generic.time.month", "month")}";
          }
        }
      }
      return DateFormat("MMM dd, yyyy").format(displayDateTime);
    }
    return null;
  }

  String? get displayUpdateTime => AppRelativeTime.timeAgoSinceDate(lastActivityTimeUtc);

  List<Message> buildDisplayMessageList(List<Message> messages, { Set<String>? globalMessageIds, bool mustCopy = true }) => isGroupConversation ?
    _buildGroupDisplayMessageList(messages, globalMessageIds: globalMessageIds ?? <String>{}) :
    (mustCopy ? List<Message>.from(messages) : messages);

  List<Message> _buildGroupDisplayMessageList(Iterable<Message> messages, { required Set<String> globalMessageIds }) {
    List<Message> displayMessages = <Message>[];
    for (Message message in messages) {
      String? messageGlobalId = message.globalId;
      if ((messageGlobalId != null) && messageGlobalId.isNotEmpty && (globalMessageIds.contains(messageGlobalId) != true)) {
        displayMessages.add(message);
        globalMessageIds.add(messageGlobalId);
      }
    }
    return displayMessages;
  }
}

extension CreatorExt on Creator{
  Member? findAsMember({List<Member>? groupMembers}){
    Iterable<Member>? creators = groupMembers?.where((Member member) =>
      member.userId == accountId
    );
    return CollectionUtils.isNotEmpty(creators) ? creators!.first : null;
  }
}

extension ConversationMemberExt on ConversationMember {

  bool get isCurrentUser => accountId == Auth2().accountId;

  static int compareNames(ConversationMember m1, ConversationMember m2) {
    String? n1 = m1.name, n2 = m2.name;
    if ((n1 != null) && (n2 != null)) {
      List<String> fn1 = n1.split(' ');
      List<String> fn2 = n2.split(' ');
      if ((1 < fn1.length) && (1 < fn2.length)) {
        int result = fn1.last.compareTo(fn2.last);
        if (result != 0) {
          return result;
        } else {
          return fn1.first.compareTo(fn2.first);
        }
      } else {
        return n1.compareTo(n2);
      }
    } else {
      return 0;
    }
  }
}

enum AttachmentFileType { image, video, audio, file }

extension AttachmentFileTypeImpl on AttachmentFileType {

  static AttachmentFileType? fromString(String? value) => (value != null) ?
    AttachmentFileType.values.firstWhereOrNull((e) => e.name == value) : null;

  static AttachmentFileType? fromAttachment(dynamic attachment) {
    if (attachment is FileAttachment) {
      return AttachmentFileTypeImpl.fromString(attachment.type);
    }
    else if (attachment is XFile) {
      return kIsWeb ? attachment.name.attachmentFileTypeFromPath : attachment.path.attachmentFileTypeFromPath;
    }
    else if (attachment is AudioResult) {
      return AttachmentFileType.audio;
    }
    else if (attachment is PlatformFile) {
      return kIsWeb ? attachment.name.attachmentFileTypeFromPath : attachment.path?.attachmentFileTypeFromPath;
    }
    else {
      return null;
    }
  }
}

extension AttachmentFileTypeUtils on String {
  AttachmentFileType? get attachmentFileTypeFromPath {
    if (FileUtils.isVideo(this)) {
      return AttachmentFileType.video;
    } else if (FileUtils.isImage(this)) {
      return AttachmentFileType.image;
    } else if (FileUtils.isAudio(this)) {
      return AttachmentFileType.audio;
    } else {
      return AttachmentFileType.file;
    }
  }
}

extension AudioResultSocialUtils on AudioResult {
  String get audioFileName => 'audio_${hashCode}${audioFileExtension}';
}

class AttachmentDetails {
  final String? url;
  final String? path;
  final Uint8List? data;
  final Future<Uint8List>? asyncData;
  final String? name;
  final String? extension;

  FutureOr<Uint8List?> get asyncOrData {
    if (data != null) {
      return data;
    } else if (asyncData != null) {
      return asyncData;
    } else if (path != null) {
      try { return File(path ?? '').readAsBytes(); }
      catch(e) { print(e); return null; }
    } else {
      return null;
    }
  }

  AttachmentDetails({ this.url, this.path, this.data, this.asyncData, this.name, this.extension });

  static AttachmentDetails? fromAttachment(dynamic attachment) {
    if (attachment is FileAttachment) {
      return AttachmentDetails(url: attachment.url, name: attachment.name, extension: attachment.extension);
    } else if (attachment is XFile) {
      return AttachmentDetails(asyncData: attachment.readAsBytes(), path: attachment.path, name: attachment.name, extension: path_pkg.extension(attachment.path));
    } else if (attachment is PlatformFile) {
        return AttachmentDetails(data: attachment.bytes, path: attachment.path, name: attachment.name, extension: attachment.extension);
    } else if (attachment is AudioResult) {
      return AttachmentDetails(data: attachment.audioData, name: attachment.audioFileName, extension: attachment.audioFileExtension);
    } else {
      return null;
    }
  }
}

extension FileAttachmentUtils on FileAttachment {

  static Map<String, FileAttachment> mapList(List<FileAttachment> list, { String? Function(FileAttachment ref) keyAccess = accessAttachmentId }) {
    Map<String, FileAttachment> map = <String, FileAttachment>{};
    for (FileAttachment entry in list) {
      String? entryKey = keyAccess(entry);
      if (entryKey != null) {
        map[entryKey] = entry;
      }
    }
    return map;
  }

  static String? accessAttachmentId(FileAttachment attachment) => attachment.id;
  static String? accessAttachmentName(FileAttachment attachment) => attachment.name;

}