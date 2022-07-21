import 'package:collection/collection.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';

///////////////////////
// TweetsPage

class TweetsPage {
  final List<Tweet>? tweets;
  final TweetsIncludes? includes;
  final TweetsMeta? meta;

  TweetsPage({this.tweets, this.includes, this.meta}) {
    Tweet.applyIncludesToList(tweets, includes);
  }

  static TweetsPage? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? TweetsPage(
      tweets: Tweet.listFromJson(JsonUtils.listValue(json['data'])),
      includes: TweetsIncludes.fromJson(JsonUtils.mapValue(json['includes'])),
      meta: TweetsMeta.fromJson(JsonUtils.mapValue(json['meta']))
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'data': Tweet.listToJson(tweets),
      'includes': includes?.toJson(),
      'meta': meta?.toJson()
    };
  }

  bool operator ==(o) =>
    (o is TweetsPage) &&
      DeepCollectionEquality().equals(o.tweets, tweets) &&
      (o.includes == includes) &&
      (o.meta == meta);

  int get hashCode =>
    (DeepCollectionEquality().hash(tweets)) ^
    (includes?.hashCode ?? 0) ^
    (meta?.hashCode ?? 0);
}

///////////////////////
// Tweet

class Tweet {
  final String? id;
  final DateTime? createdAtUtc;
  final String? text;
  final String? lang;
  final String? conversationId;
  final String? authorId;
  final String? source;
  final String? replySettings;
  final bool? possiblySensitive;

  final TweetEntities? entities;
  final TweetPublicMetrics? publicMetrics;
  final TweetContextAnotations? contextAnotations;
  final TweetAttachments? attachments;
  final List<TweetRef>? referencedTweets;

  final String? html;
  TwitterUser? _author;

  Tweet({this.id, this.createdAtUtc, this.text, this.lang, this.conversationId, this.authorId, this.source, this.replySettings, this.possiblySensitive,
    this.entities, this.publicMetrics, this.contextAnotations, this.attachments, this.referencedTweets,
  }) :
    html = _buildHtml(text, entities);
 
  static Tweet? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Tweet(
      id: JsonUtils.stringValue(json['id']),
      createdAtUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['created_at']), isUtc: true),
      text: JsonUtils.stringValue(json['text']),
      lang: JsonUtils.stringValue(json['lang']),
      conversationId: JsonUtils.stringValue(json['conversation_id']),
      authorId: JsonUtils.stringValue(json['author_id']),
      source: JsonUtils.stringValue(json['source']),
      replySettings: JsonUtils.stringValue(json['reply_settings']),
      possiblySensitive: JsonUtils.boolValue(json['possibly_sensitive']),
      entities: TweetEntities.fromJson(JsonUtils.mapValue(json['entities'])),
      publicMetrics: TweetPublicMetrics.fromJson(JsonUtils.mapValue(json['public_metrics'])),
      contextAnotations: TweetContextAnotations.fromJson(JsonUtils.mapValue(json['context_annotations'])),
      attachments: TweetAttachments.fromJson(JsonUtils.mapValue(json['attachments'])),
      referencedTweets: TweetRef.listFromJson(JsonUtils.listValue(json['referenced_tweets'])),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': DateTimeUtils.utcDateTimeToString(createdAtUtc),
      'text': text,
      'lang': lang,
      'conversation_id': conversationId,
      'author_id': authorId,
      'source': source,
      'reply_settings': replySettings,
      'possibly_sensitive': possiblySensitive,
      'entities': entities?.toJson(),
      'public_metrics': publicMetrics?.toJson(),
      'context_annotations': contextAnotations?.toJson(),
      'attachments': attachments?.toJson(),
      'referenced_tweets': TweetRef.listToJson(referencedTweets),
    };
  }

  bool operator ==(o) =>
    (o is Tweet) &&
      (o.id == id) &&
      (o.createdAtUtc == createdAtUtc) &&
      (o.text == text) &&
      (o.lang == lang) &&
      (o.conversationId == conversationId) &&
      (o.authorId == authorId) &&
      (o.source == source) &&
      (o.replySettings == replySettings) &&
      (o.possiblySensitive == possiblySensitive) &&
      (o.entities == entities) &&
      (o.publicMetrics == publicMetrics) &&
      (o.contextAnotations == contextAnotations) &&
      (o.attachments == attachments) &&
      DeepCollectionEquality().equals(o.referencedTweets, referencedTweets);

  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (createdAtUtc?.hashCode ?? 0) ^
    (text?.hashCode ?? 0) ^
    (lang?.hashCode ?? 0) ^
    (conversationId?.hashCode ?? 0) ^
    (authorId?.hashCode ?? 0) ^
    (source?.hashCode ?? 0) ^
    (replySettings?.hashCode ?? 0) ^
    (possiblySensitive?.hashCode ?? 0) ^
    (entities?.hashCode ?? 0) ^
    (publicMetrics?.hashCode ?? 0) ^
    (contextAnotations?.hashCode ?? 0) ^
    (attachments?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(referencedTweets));

  TwitterUser? get author => _author;

  TwitterMedia? get media {
    if (CollectionUtils.isNotEmpty(attachments?.media)) {
      return attachments?.media?.first;
    }
    else if (CollectionUtils.isNotEmpty(referencedTweets)) {
      return TweetRef.mediaFromList(referencedTweets);
    }
    return null;
  }

  String? get detailUrl => TweetEntityUrl.detailUrlFromList(entities?.urls);

  String? get displayTime {
    
    DateTime? deviceDateTime = AppDateTime().getDeviceTimeFromUtcTime(createdAtUtc);
    if (deviceDateTime != null) {
      DateTime now = DateTime.now();
      if (deviceDateTime.compareTo(now) < 0) {
        Duration difference = DateTime.now().difference(deviceDateTime);
        if (difference.inSeconds < 60) {
          return 'Now';
        }
        else if (difference.inMinutes < 60) {
          return sprintf("%smin", [difference.inMinutes]);
        }
        else if (difference.inHours < 24) {
          return sprintf("%sh", [difference.inHours]);
        }
        else if (difference.inDays < 30) {
          return sprintf("%sd", [difference.inDays]);
        }
        else {
          int differenceInMonths = difference.inDays ~/ 30;
          if (differenceInMonths < 12) {
            return sprintf("%sm", [differenceInMonths]);
          }
        }
      }
      return DateFormat("MMM dd, yyyy").format(deviceDateTime);
    }
    else {
      return null;
    }
  }

  static String? _buildHtml(String? text, TweetEntities? entities) {
    String? html = text;
    if ((html != null) && !html.hasHighSurrogates && (entities?.entities != null)) {
      int? firstUpdated = text!.length;
      for (int entityIndex = entities!.entities.length - 1; 0 <= entityIndex; entityIndex--) {
        TweetEntity entetity = entities.entities[entityIndex];
        if (entetity.isValid && (entetity.end! <= firstUpdated!) && (entetity.end! <= text.length)) {
          String entetityText = text.substring(entetity.start!, entetity.end);
          String? entetityHtml = entetity.buildHtml(entetityText);
          if (entetityHtml != null) {
            html = html!.replaceRange(entetity.start!, entetity.end, entetityHtml);
            firstUpdated = entetity.start;
          }
        }
      }
    }
    html = html?.replaceAll('\n', '<br>');
    return html;
  }

  void _applyIncludes(TweetsIncludes? includes) {
    _author = TwitterUser.entryInList(includes?.users, id: authorId);
    attachments?._applyIncludes(includes);
    TweetRef.applyIncludesToList(referencedTweets, includes);
  }

  static void applyIncludesToList(List<Tweet>? tweets, TweetsIncludes? includes) {
    if ((tweets != null) && (includes != null)) {
      for (Tweet? tweet in tweets) {
        tweet!._applyIncludes(includes);
      }
    }
  }

  static List<Tweet>? listFromJson(List<dynamic>? jsonList) {
    List<Tweet>? result;
    if (jsonList != null) {
      result = <Tweet>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Tweet.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Tweet>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = [];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  static Tweet? entryInList(List<Tweet>? contentList, {String? id}) {
    if (contentList != null) {
      for (Tweet? contentEntry in contentList) {
        if (contentEntry?.id == id) {
          return contentEntry;
        }
      }
    }
    return null;
  }
}

///////////////////////
// TweetEntities

class TweetEntities {
  final List<TweetEntityUrl>? urls;
  final List<TweetEntityAnnotation>? annotations;
  final List<TweetEntityHashtag>? hashtags;
  final List<TweetEntityMention>? mentions;
  
  final List<TweetEntity> entities;

  TweetEntities({this.urls, this.annotations, this.hashtags, this.mentions}) :
    entities = _buildEntities([urls, annotations, hashtags, mentions]);

  static TweetEntities? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? TweetEntities(
        urls: TweetEntityUrl.listFromJson(JsonUtils.listValue(json['urls'])),
        annotations: TweetEntityAnnotation.listFromJson(JsonUtils.listValue(json['annotations'])),
        hashtags: TweetEntityHashtag.listFromJson(JsonUtils.listValue(json['hashtags'])),
        mentions: TweetEntityMention.listFromJson(JsonUtils.listValue(json['mentions'])),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'urls': TweetEntityUrl.listToJson(urls),
      'annotations': TweetEntityAnnotation.listToJson(annotations),
      'hashtags': TweetEntityHashtag.listToJson(hashtags),
      'mentions': TweetEntityMention.listToJson(mentions),
    };
  }

  bool operator ==(o) =>
    (o is TweetEntities) &&
      DeepCollectionEquality().equals(o.urls, urls) &&
      DeepCollectionEquality().equals(o.annotations, annotations) &&
      DeepCollectionEquality().equals(o.hashtags, hashtags) &&
      DeepCollectionEquality().equals(o.mentions, mentions);

  int get hashCode =>
    (DeepCollectionEquality().hash(urls)) ^
    (DeepCollectionEquality().hash(annotations)) ^
    (DeepCollectionEquality().hash(hashtags)) ^
    (DeepCollectionEquality().hash(mentions));

  static List<TweetEntity> _buildEntities(List<dynamic>? sourceEntities, { int? level }) {
    List<TweetEntity> entities = <TweetEntity>[];
    if (sourceEntities != null) {
      for (dynamic sourceEntity in sourceEntities) {
        if (sourceEntity is TweetEntity) {
          entities.add(sourceEntity);
        }
        else if (sourceEntity is List) {
          entities.addAll(_buildEntities(sourceEntity, level: (level ?? 0) + 1));
        }
      }
    }
    if ((level == null) || (level == 0)) {
      entities.sort();
    }
    return entities;
  }
}

///////////////////////
// TweetEntity

abstract class TweetEntity implements Comparable<TweetEntity> {
  int? get start;
  int? get end;

  bool get isValid {
    return (start != null) && (end != null) && (start! < end!);
  }

  int compareTo(TweetEntity? other) {
    return ((end != null) && (other?.end != null)) ? end!.compareTo(other!.end!) : 0;
  }

  String? buildHtml(String sourceText) {
    return null;
  }
}

///////////////////////
// TweetEntityUrl

class TweetEntityUrl with TweetEntity {
  final int? start;
  final int? end;
  final String? url;
  final String? expandedUrl;
  final String? displayUrl;
  final int? status;
  final String? title;
  final String? description;
  final String? unwoundUrl;

  TweetEntityUrl({this.start, this.end, this.url, this.expandedUrl, this.displayUrl, this.status, this.title, this.description, this.unwoundUrl});

  static TweetEntityUrl? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? TweetEntityUrl(
      start: JsonUtils.intValue(json['start']),
      end: JsonUtils.intValue(json['end']),
      url: JsonUtils.stringValue(json['url']),
      expandedUrl: JsonUtils.stringValue(json['expanded_url']),
      displayUrl: JsonUtils.stringValue(json['display_url']),
      status: JsonUtils.intValue(json['status']),
      title: JsonUtils.stringValue(json['title']),
      description: JsonUtils.stringValue(json['description']),
      unwoundUrl: JsonUtils.stringValue(json['unwound_url']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      'url': url,
      'expanded_url': expandedUrl,
      'display_url': displayUrl,
      'status': status,
      'title': title,
      'description': description,
      'unwound_url': unwoundUrl,
    };
  }

  bool operator ==(o) =>
    (o is TweetEntityUrl) &&
      (o.start == start) &&
      (o.end == end) &&
      (o.url == url) &&
      (o.expandedUrl == expandedUrl) &&
      (o.displayUrl == displayUrl) &&
      (o.status == status) &&
      (o.title == title) &&
      (o.description == description) &&
      (o.unwoundUrl == unwoundUrl);

  int get hashCode =>
    (start?.hashCode ?? 0) ^
    (end?.hashCode ?? 0) ^
    (url?.hashCode ?? 0) ^
    (expandedUrl?.hashCode ?? 0) ^
    (displayUrl?.hashCode ?? 0) ^
    (status?.hashCode ?? 0) ^
    (title?.hashCode ?? 0) ^
    (description?.hashCode ?? 0) ^
    (unwoundUrl?.hashCode ?? 0);

  String? get detailUrl {
    if ((expandedUrl != null) && expandedUrl!.startsWith("https://twitter.com") &&
        (displayUrl != null) && displayUrl!.startsWith("pic.twitter.com")) {
      return expandedUrl;
    }
    return null;
  }

  String buildHtml(String sourceText) {
    return "<a href='$expandedUrl'>$sourceText</a>";
  }

  static String? detailUrlFromList(List<TweetEntityUrl>? contentList) {
    if (contentList != null) {
      for (int index = contentList.length - 1; 0 <= index; index--) {
        TweetEntityUrl? contentEntry = contentList[index];
        if (contentEntry.detailUrl != null) {
          return contentEntry.detailUrl;
        }
      }
    }
    return null;
  }

  static List<TweetEntityUrl>? listFromJson(List<dynamic>? jsonList) {
    List<TweetEntityUrl>? result;
    if (jsonList != null) {
      result = <TweetEntityUrl>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, TweetEntityUrl.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<TweetEntityUrl>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = [];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }
}

///////////////////////
// TweetEntityAnnotation

class TweetEntityAnnotation with TweetEntity {
  final int? start;
  final int? end;
  final double? probability;
  final String? type;
  final String? normalizedText;

  TweetEntityAnnotation({this.start, this.end, this.probability, this.type, this.normalizedText});

  static TweetEntityAnnotation? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? TweetEntityAnnotation(
      start: JsonUtils.intValue(json['start']),
      end: JsonUtils.intValue(json['end']),
      probability: JsonUtils.doubleValue(json['probability']),
      type: JsonUtils.stringValue(json['type']),
      normalizedText: JsonUtils.stringValue(json['normalized_text']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      'probability': probability,
      'type': type,
      'normalized_text': normalizedText,
    };
  }

  bool operator ==(o) =>
    (o is TweetEntityAnnotation) &&
      (o.start == start) &&
      (o.end == end) &&
      (o.probability == probability) &&
      (o.type == type) &&
      (o.normalizedText == normalizedText);

  int get hashCode =>
    (start?.hashCode ?? 0) ^
    (end?.hashCode ?? 0) ^
    (probability?.hashCode ?? 0) ^
    (type?.hashCode ?? 0) ^
    (normalizedText?.hashCode ?? 0);

  static List<TweetEntityAnnotation>? listFromJson(List<dynamic>? jsonList) {
    List<TweetEntityAnnotation>? result;
    if (jsonList != null) {
      result = <TweetEntityAnnotation>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, TweetEntityAnnotation.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<TweetEntityAnnotation>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = [];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }
}

///////////////////////
// TweetEntityHashtag

class TweetEntityHashtag with TweetEntity {
  final int? start;
  final int? end;
  final String? tag;

  TweetEntityHashtag({this.start, this.end, this.tag});

  static TweetEntityHashtag? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? TweetEntityHashtag(
      start: JsonUtils.intValue(json['start']),
      end: JsonUtils.intValue(json['end']),
      tag: JsonUtils.stringValue(json['tag']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      'tag': tag,
    };
  }

  bool operator ==(o) =>
    (o is TweetEntityHashtag) &&
      (o.start == start) &&
      (o.end == end) &&
      (o.tag == tag);

  int get hashCode =>
    (start?.hashCode ?? 0) ^
    (end?.hashCode ?? 0) ^
    (tag?.hashCode ?? 0);

  String buildHtml(String sourceText) {
    return "<a href='https://twitter.com/hashtag/$tag'>$sourceText</a>";
  }

  static List<TweetEntityHashtag>? listFromJson(List<dynamic>? jsonList) {
    List<TweetEntityHashtag>? result;
    if (jsonList != null) {
      result = <TweetEntityHashtag>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, TweetEntityHashtag.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<TweetEntityHashtag>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = [];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }
}

///////////////////////
// TweetEntityMention

class TweetEntityMention with TweetEntity {
  final int? start;
  final int? end;
  final String? userName;
  final String? id;

  TweetEntityMention({this.start, this.end, this.userName, this.id});

  static TweetEntityMention? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? TweetEntityMention(
      start: JsonUtils.intValue(json['start']),
      end: JsonUtils.intValue(json['end']),
      userName: JsonUtils.stringValue(json['username']),
      id: JsonUtils.stringValue(json['id']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      'username': userName,
      'id': id,
    };
  }

  bool operator ==(o) =>
    (o is TweetEntityMention) &&
      (o.start == start) &&
      (o.end == end) &&
      (o.userName == userName) &&
      (o.id == id);

  int get hashCode =>
    (start?.hashCode ?? 0) ^
    (end?.hashCode ?? 0) ^
    (userName?.hashCode ?? 0) ^
    (id?.hashCode ?? 0);

  String buildHtml(String sourceText) {
    return "<a href='https://twitter.com/$userName'>$sourceText</a>";
  }

  static List<TweetEntityMention>? listFromJson(List<dynamic>? jsonList) {
    List<TweetEntityMention>? result;
    if (jsonList != null) {
      result = <TweetEntityMention>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, TweetEntityMention.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<TweetEntityMention>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = [];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }
}

///////////////////////
// TweetRef

class TweetRef {
  final String? id;
  final String? type;
  Tweet? _tweet;

  TweetRef({this.id, this.type});

  static TweetRef? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? TweetRef(
      id: JsonUtils.stringValue(json['id']),
      type: JsonUtils.stringValue(json['type']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
    };
  }

  bool operator ==(o) =>
    (o is TweetRef) &&
      (o.id == id) &&
      (o.type == type);

  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (type?.hashCode ?? 0);

  Tweet? get tweet => _tweet;
  
  void _applyIncludes(TweetsIncludes? includes) {
    _tweet = Tweet.entryInList(includes?.tweets, id: id);
    _tweet?._applyIncludes(includes);
  }

  static void applyIncludesToList(List<TweetRef>? tweetRefs, TweetsIncludes? includes) {
    if ((tweetRefs != null) && (includes != null)) {
      for (TweetRef? tweetRef in tweetRefs) {
        tweetRef!._applyIncludes(includes);
      }
    }
  }

  static TwitterMedia? mediaFromList(List<TweetRef>? tweetRefs) {
    if (tweetRefs != null) {
      for (TweetRef? tweetRef in tweetRefs) {
        if (tweetRef?.tweet?.media != null) {
          return tweetRef?.tweet?.media;
        }
      }
    }
    return null;
  }

  static List<TweetRef>? listFromJson(List<dynamic>? jsonList) {
    List<TweetRef>? result;
    if (jsonList != null) {
      result = <TweetRef>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, TweetRef.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<TweetRef>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = [];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }
}

///////////////////////
// TweetAttachments

class TweetAttachments {
  final List<String>? mediaKeys;
  List<TwitterMedia>? _media;

  TweetAttachments({this.mediaKeys});

  static TweetAttachments? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? TweetAttachments(
      mediaKeys: JsonUtils.listStringsValue(json['media_keys']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'media_keys': mediaKeys,
    };
  }

  bool operator ==(o) =>
    (o is TweetAttachments) &&
      DeepCollectionEquality().equals(o.mediaKeys, mediaKeys);

  int get hashCode =>
    (DeepCollectionEquality().hash(mediaKeys));

  List<TwitterMedia>? get media => _media;

  void _applyIncludes(TweetsIncludes? includes) {
    _media = TwitterMedia.listFromKeys(includes?.media, keys: mediaKeys);
  }
}

///////////////////////
// TweetPublicMetrics

class TweetPublicMetrics {
  final int? retweetCount;
  final int? replyCount;
  final int? likeCount;
  final int? quoteCount;
  TweetPublicMetrics({this.retweetCount, this.replyCount, this.likeCount, this.quoteCount});

  static TweetPublicMetrics? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? TweetPublicMetrics(
      retweetCount: JsonUtils.intValue(json['retweet_count']),
      replyCount: JsonUtils.intValue(json['reply_count']),
      likeCount: JsonUtils.intValue(json['like_count']),
      quoteCount: JsonUtils.intValue(json['quote_count']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'retweet_count': retweetCount,
      'reply_count': replyCount,
      'like_count': likeCount,
      'quote_count': quoteCount,
    };
  }

  bool operator ==(o) =>
    (o is TweetPublicMetrics) &&
      (o.retweetCount == retweetCount) &&
      (o.replyCount == replyCount) &&
      (o.likeCount == likeCount) &&
      (o.quoteCount == quoteCount);

  int get hashCode =>
    (retweetCount?.hashCode ?? 0) ^
    (replyCount?.hashCode ?? 0) ^
    (likeCount?.hashCode ?? 0) ^
    (quoteCount?.hashCode ?? 0);
}

///////////////////////
// TweetContextAnotation

class TweetContextAnotation {
  final String? id;
  final String? name;
  final String? description;

  TweetContextAnotation({this.id, this.name, this.description});

  static TweetContextAnotation? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? TweetContextAnotation(
      id: JsonUtils.stringValue(json['id']),
      name: JsonUtils.stringValue(json['name']),
      description: JsonUtils.stringValue(json['description']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  bool operator ==(o) =>
    (o is TweetContextAnotation) &&
      (o.id == id) &&
      (o.name == name) &&
      (o.description== description);

  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (description?.hashCode ?? 0);
}

///////////////////////
// TweetContextAnotations

class TweetContextAnotations {
  final TweetContextAnotation? domain;
  final TweetContextAnotation? entity;

  TweetContextAnotations({this.domain, this.entity});

  static TweetContextAnotations? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? TweetContextAnotations(
      domain: TweetContextAnotation.fromJson(JsonUtils.mapValue(json['domain'])),
      entity: TweetContextAnotation.fromJson(JsonUtils.mapValue(json['entity'])),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'domain': domain?.toJson(),
      'entity': entity?.toJson(),
    };
  }

  bool operator ==(o) =>
    (o is TweetContextAnotations) &&
      (o.domain == domain) &&
      (o.entity == entity);

  int get hashCode =>
    (domain?.hashCode ?? 0) ^
    (entity?.hashCode ?? 0);
}

///////////////////////
// TweetsIncludes

class TweetsIncludes {
  final List<TwitterMedia>? media;
  final List<TwitterUser>? users;
  final List<Tweet>? tweets;

  TweetsIncludes({this.media, this.users, this.tweets});

  static TweetsIncludes? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? TweetsIncludes(
      media: TwitterMedia.listFromJson(JsonUtils.listValue(json['media'])),
      users: TwitterUser.listFromJson(JsonUtils.listValue(json['users'])),
      tweets: Tweet.listFromJson(JsonUtils.listValue(json['tweets'])),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'media': TwitterMedia.listToJson(media),
      'users': TwitterUser.listToJson(users),
      'tweets': Tweet.listToJson(tweets)
    };
  }

  bool operator ==(o) =>
    (o is TweetsIncludes) &&
      DeepCollectionEquality().equals(o.media, media) &&
      DeepCollectionEquality().equals(o.users, users) &&
      DeepCollectionEquality().equals(o.tweets, tweets);

  int get hashCode =>
    (DeepCollectionEquality().hash(media)) ^
    (DeepCollectionEquality().hash(users)) ^
    (DeepCollectionEquality().hash(tweets));
}

///////////////////////
// TwitterMedia

class TwitterMedia {
  final String? key;
  final String? type;
  final String? url;
  final String? previewImageUrl;
  final String? altText;
  final int? width;
  final int? height;
  
  TwitterMedia({this.key, this.type, this.url, this.previewImageUrl, this.altText, this.width, this.height});

  static TwitterMedia? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? TwitterMedia(
      key: JsonUtils.stringValue(json['media_key']),
      type: JsonUtils.stringValue(json['type']),
      url: JsonUtils.stringValue(json['url']),
      previewImageUrl: JsonUtils.stringValue(json['preview_image_url']),
      altText: JsonUtils.stringValue(json['alt_text']),
      width: JsonUtils.intValue(json['width']),
      height: JsonUtils.intValue(json['height']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'media_key': key,
      'type': type,
      'url': url,
      'preview_image_url': previewImageUrl,
      'alt_text': altText,
      'width': width,
      'height': height,
    };
  }

  bool operator ==(o) =>
    (o is TwitterMedia) &&
      (o.key == key) &&
      (o.type == type) &&
      (o.url == url) &&
      (o.previewImageUrl == previewImageUrl) &&
      (o.altText == altText) &&
      (o.width == width) &&
      (o.height == height);

  int get hashCode =>
    (key?.hashCode ?? 0) ^
    (type?.hashCode ?? 0) ^
    (url?.hashCode ?? 0) ^
    (previewImageUrl?.hashCode ?? 0) ^
    (altText?.hashCode ?? 0) ^
    (width?.hashCode ?? 0) ^
    (height?.hashCode ?? 0);

  String? get imageUrl {
    return previewImageUrl ?? url;
  }
  
  static List<TwitterMedia>? listFromJson(List<dynamic>? jsonList) {
    List<TwitterMedia>? result;
    if (jsonList != null) {
      result = <TwitterMedia>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, TwitterMedia.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<TwitterMedia>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = [];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  static TwitterMedia? entryInList(List<TwitterMedia>? contentList, {String? key}) {
    if (contentList != null) {
      for (TwitterMedia? contentEntry in contentList) {
        if (contentEntry?.key == key) {
          return contentEntry;
        }
      }
    }
    return null;
  }

  static List<TwitterMedia>? listFromKeys(List<TwitterMedia>? contentList, {List<String>? keys}) {
    List<TwitterMedia>? result;
    if ((contentList != null) && (keys != null)) {
      result = <TwitterMedia>[];
      for (String key in keys) {
        ListUtils.add(result, entryInList(contentList, key: key));
      }
    }
    return result;
  }
}

///////////////////////
// TwitterUser

class TwitterUser {

  final String? id;
  final DateTime? createdAtUtc;
  final String? name;
  final String? userName;
  final String? description;
  final String? url;
  final String? profileImageUrl;
  final String? location;
  final bool? protected;
  final bool? verified;

  final TweeterUserPublicMetrics? publicMetrics;
  final List<TweetEntityUrl>? entetityUrls;

  TwitterUser({this.id, this.createdAtUtc, this.name, this.userName, this.description, this.url, this.profileImageUrl, this.location, this.protected, this.verified, this.publicMetrics, this.entetityUrls});

  static TwitterUser? fromJson(Map<String, dynamic>? json) {
    if (json != null) {
      Map<String, dynamic>? entities = JsonUtils.mapValue(json['entities']);
      Map<String, dynamic>? entitiesUrl = (entities != null) ? JsonUtils.mapValue(entities['url']) : null;
      return TwitterUser(
        id: JsonUtils.stringValue(json['id']),
        createdAtUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['created_at']), isUtc: true),
        name: JsonUtils.stringValue(json['name']),
        userName: JsonUtils.stringValue(json['username']),
        description: JsonUtils.stringValue(json['description']),
        url: JsonUtils.stringValue(json['url']),
        profileImageUrl: JsonUtils.stringValue(json['profile_image_url']),
        location: JsonUtils.stringValue(json['location']),
        protected: JsonUtils.boolValue(json['protected']),
        verified: JsonUtils.boolValue(json['verified']),
        publicMetrics: TweeterUserPublicMetrics.fromJson(JsonUtils.mapValue(json['public_metrics'])),
        entetityUrls: (entitiesUrl != null) ? TweetEntityUrl.listFromJson(JsonUtils.listValue(entitiesUrl['urls'])) : null,
      );
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': DateTimeUtils.utcDateTimeToString(createdAtUtc),
      'name': name,
      'username': userName,
      'description': description,
      'url': url,
      'profile_image_url': profileImageUrl,
      'location': location,
      'protected': protected,
      'verified': verified,
      'public_metrics': publicMetrics?.toJson(),
      'entities': {
        'url': {
          'urls': TweetEntityUrl.listToJson(entetityUrls)
        }
      }
    };
  }

  bool operator ==(o) =>
    (o is TwitterUser) &&
      (o.id == id) &&
      (o.createdAtUtc == createdAtUtc) &&
      (o.name == name) &&
      (o.userName == userName) &&
      (o.description == description) &&
      (o.url == url) &&
      (o.profileImageUrl == profileImageUrl) &&
      (o.location == location) &&
      (o.protected == protected) &&
      (o.verified == verified) &&
      (o.publicMetrics == publicMetrics) &&
      DeepCollectionEquality().equals(o.entetityUrls, entetityUrls);

  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (createdAtUtc?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (userName?.hashCode ?? 0) ^
    (description?.hashCode ?? 0) ^
    (url?.hashCode ?? 0) ^
    (profileImageUrl?.hashCode ?? 0) ^
    (location?.hashCode ?? 0) ^
    (protected?.hashCode ?? 0) ^
    (verified?.hashCode ?? 0) ^
    (publicMetrics?.hashCode ?? 0) ^
    DeepCollectionEquality().hash(entetityUrls);

  String get html {
    return "<a href='https://twitter.com/$userName'>@$userName</a>";
  }
  
  static List<TwitterUser>? listFromJson(List<dynamic>? jsonList) {
    List<TwitterUser>? result;
    if (jsonList != null) {
      result = <TwitterUser>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, TwitterUser.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<TwitterUser>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = [];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  static TwitterUser? entryInList(List<TwitterUser>? contentList, {String? id}) {
    if (contentList != null) {
      for (TwitterUser? contentEntry in contentList) {
        if (contentEntry?.id == id) {
          return contentEntry;
        }
      }
    }
    return null;
  }
}

///////////////////////
// TweeterUserPublicMetrics

class TweeterUserPublicMetrics {
  final int? followersCount;
  final int? followingCount;
  final int? tweetCount;
  final int? listedCount;
  TweeterUserPublicMetrics({this.followersCount, this.followingCount, this.tweetCount, this.listedCount});

  static TweeterUserPublicMetrics? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? TweeterUserPublicMetrics(
      followersCount: JsonUtils.intValue(json['followers_count']),
      followingCount: JsonUtils.intValue(json['following_count']),
      tweetCount: JsonUtils.intValue(json['tweet_count']),
      listedCount: JsonUtils.intValue(json['listed_count']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'followers_count': followersCount,
      'following_count': followingCount,
      'tweet_count': tweetCount,
      'listed_count': listedCount,
    };
  }

  bool operator ==(o) =>
    (o is TweeterUserPublicMetrics) &&
      (o.followersCount == followersCount) &&
      (o.followingCount == followingCount) &&
      (o.tweetCount == tweetCount) &&
      (o.listedCount == listedCount);

  int get hashCode =>
    (followersCount?.hashCode ?? 0) ^
    (followingCount?.hashCode ?? 0) ^
    (tweetCount?.hashCode ?? 0) ^
    (listedCount?.hashCode ?? 0);
}

///////////////////////
// TweetsMeta

class TweetsMeta {
  final String? oldestId;
  final String? newestId;
  final String? nextToken;
  final String? previousToken;
  final int? resultCount;
  TweetsMeta({this.newestId, this.oldestId, this.nextToken, this.previousToken, this.resultCount});

  static TweetsMeta? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? TweetsMeta(
      oldestId: JsonUtils.stringValue(json['oldest_id']),
      newestId: JsonUtils.stringValue(json['newest_id']),
      nextToken: JsonUtils.stringValue(json['next_token']),
      previousToken: JsonUtils.stringValue(json['previous_token']),
      resultCount: JsonUtils.intValue(json['result_count']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'oldest_id': oldestId,
      'newest_id': newestId,
      'next_token': nextToken,
      'previous_token': previousToken,
      'result_count': resultCount,
    };
  }

  bool operator ==(o) =>
    (o is TweetsMeta) &&
      (o.oldestId == oldestId) &&
      (o.newestId == newestId) &&
      (o.nextToken == nextToken) &&
      (o.previousToken == previousToken) &&
      (o.resultCount == resultCount);

  int get hashCode =>
    (oldestId?.hashCode ?? 0) ^
    (newestId?.hashCode ?? 0) ^
    (nextToken?.hashCode ?? 0) ^
    (previousToken?.hashCode ?? 0) ^
    (resultCount?.hashCode ?? 0);
}

extension _StringTwitterExt on String {
  bool get hasHighSurrogates {
    for (int codeUnit in codeUnits) {
      if ((0xD800 <= codeUnit) && (codeUnit <= 0xDB7F)) {
        return true;
      }
    }
    return false;
  }
}