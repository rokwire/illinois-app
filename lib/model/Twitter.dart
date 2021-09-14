import 'package:collection/collection.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/utils/Utils.dart';

///////////////////////
// Tweets

class Tweets {
  final List<Tweet> tweets;
  final TweetsIncludes includes;

  Tweets({this.tweets, this.includes});

  factory Tweets.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Tweets(
      tweets: Tweet.listFromJson(AppJson.listValue(json['data'])),
      includes: TweetsIncludes.fromJson(AppJson.mapValue(json['includes']))
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'data': Tweet.listToJson(tweets),
      'includes': includes?.toJson()
    };
  }

  bool operator ==(o) =>
    (o is Tweets) &&
      DeepCollectionEquality().equals(o.tweets, tweets) &&
      (o.includes == includes);

  int get hashCode =>
    (DeepCollectionEquality().hash(tweets) ?? 0) ^
    (includes?.hashCode ?? 0);
}

///////////////////////
// Tweet

class Tweet {
  final String id;
  final DateTime createdAt;
  final String text;
  final String lang;
  final String conversationId;
  final String authorId;
  final String source;
  final String replySettings;
  final bool possiblySensitive;

  final TweetEntities entities;
  final TweetPublicMetrics publicMetrics;
  final TweetContextAnotations contextAnotations;
  final TweetAttachments attachments;

  TwitterUser _author;

  Tweet({this.id, this.createdAt, this.text, this.lang, this.conversationId, this.authorId, this.source, this.replySettings, this.possiblySensitive,
    this.entities, this.publicMetrics, this.contextAnotations, this.attachments,
  });

  factory Tweet.fromJson(Map<String, dynamic> json) {
    return (json != null) ? Tweet(
      id: AppJson.stringValue(json['id']),
      createdAt: AppDateTime().dateTimeFromString(AppJson.stringValue(json['created_at']), isUtc: true),
      text: AppJson.stringValue(json['text']),
      lang: AppJson.stringValue(json['lang']),
      conversationId: AppJson.stringValue(json['conversation_id']),
      authorId: AppJson.stringValue(json['author_id']),
      source: AppJson.stringValue(json['source']),
      replySettings: AppJson.stringValue(json['reply_settings']),
      possiblySensitive: AppJson.boolValue(json['possibly_sensitive']),
      entities: TweetEntities.fromJson(AppJson.mapValue(json['entities'])),
      publicMetrics: TweetPublicMetrics.fromJson(AppJson.mapValue(json['public_metrics'])),
      contextAnotations: TweetContextAnotations.fromJson(AppJson.mapValue(json['context_annotations'])),
      attachments: TweetAttachments.fromJson(AppJson.mapValue(json['attachments'])),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': AppDateTime().utcDateTimeToString(createdAt),
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
    };
  }

  bool operator ==(o) =>
    (o is Tweet) &&
      (o.id == id) &&
      (o.createdAt == createdAt) &&
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
      (o.attachments == attachments);

  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (createdAt?.hashCode ?? 0) ^
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
    (attachments?.hashCode ?? 0);

  TwitterUser get author => _author;

  void _applyIncludes(TweetsIncludes includes) {
    _author = TwitterUser.entryInList(includes?.users, id: authorId);
    attachments?._applyIncludes(includes);
  }

  static void applyIncludesToList(List<Tweet> tweets, TweetsIncludes includes) {
    if ((tweets != null) && (includes != null)) {
      for (Tweet tweet in tweets) {
        tweet._applyIncludes(includes);
      }
    }
  }

  static List<Tweet> listFromJson(List<dynamic> jsonList) {
    List<Tweet> result;
    if (jsonList != null) {
      result = [];
      for (dynamic jsonEntry in jsonList) {
        result.add((jsonEntry is Map) ? Tweet.fromJson(jsonEntry) : null);
      }
    }
    return result;
  }

  static List<dynamic> listToJson(List<Tweet> contentList) {
    List<dynamic> jsonList;
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
// TweetEntities

class TweetEntities {
  final List<TweetEntityUrl> urls;
  final List<TweetEntityAnnotation> annotations;
  final List<TweetEntityHashtag> hashtags;

  TweetEntities({this.urls, this.annotations, this.hashtags});

  factory TweetEntities.fromJson(Map<String, dynamic> json) {
    return (json != null) ? TweetEntities(
        urls: TweetEntityUrl.listFromJson(AppJson.listValue(json['urls'])),
        annotations: TweetEntityAnnotation.listFromJson(AppJson.listValue(json['annotations'])),
        hashtags: TweetEntityHashtag.listFromJson(AppJson.listValue(json['hashtags'])),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'urls': TweetEntityUrl.listToJson(urls),
      'annotations': TweetEntityAnnotation.listToJson(annotations),
      'hashtags': TweetEntityHashtag.listToJson(hashtags),
    };
  }

  bool operator ==(o) =>
    (o is TweetEntities) &&
      DeepCollectionEquality().equals(urls, urls) &&
      DeepCollectionEquality().equals(annotations, annotations) &&
      DeepCollectionEquality().equals(hashtags, hashtags);

  int get hashCode =>
    (DeepCollectionEquality().hash(urls) ?? 0) ^
    (DeepCollectionEquality().hash(annotations) ?? 0) ^
    (DeepCollectionEquality().hash(hashtags) ?? 0);
}

///////////////////////
// TweetEntityUrl

class TweetEntityUrl {
  final int start;
  final int end;
  final String url;
  final String expandedUrl;
  final String displayUrl;

  TweetEntityUrl({this.start, this.end, this.url, this.expandedUrl, this.displayUrl});

  factory TweetEntityUrl.fromJson(Map<String, dynamic> json) {
    return (json != null) ? TweetEntityUrl(
      start: AppJson.intValue(json['start']),
      end: AppJson.intValue(json['end']),
      url: AppJson.stringValue(json['url']),
      expandedUrl: AppJson.stringValue(json['expanded_url']),
      displayUrl: AppJson.stringValue(json['display_url']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      'url': url,
      'expanded_url': expandedUrl,
      'display_url': displayUrl,
    };
  }

  bool operator ==(o) =>
    (o is TweetEntityUrl) &&
      (o.start == start) &&
      (o.end == end) &&
      (o.url == url) &&
      (o.expandedUrl == expandedUrl) &&
      (o.displayUrl == displayUrl);

  int get hashCode =>
    (start?.hashCode ?? 0) ^
    (end?.hashCode ?? 0) ^
    (url?.hashCode ?? 0) ^
    (expandedUrl?.hashCode ?? 0) ^
    (displayUrl?.hashCode ?? 0);

  static List<TweetEntityUrl> listFromJson(List<dynamic> jsonList) {
    List<TweetEntityUrl> result;
    if (jsonList != null) {
      result = [];
      for (dynamic jsonEntry in jsonList) {
        result.add((jsonEntry is Map) ? TweetEntityUrl.fromJson(jsonEntry) : null);
      }
    }
    return result;
  }

  static List<dynamic> listToJson(List<TweetEntityUrl> contentList) {
    List<dynamic> jsonList;
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

class TweetEntityAnnotation {
  final int start;
  final int end;
  final double probability;
  final String type;
  final String normalizedText;

  TweetEntityAnnotation({this.start, this.end, this.probability, this.type, this.normalizedText});

  factory TweetEntityAnnotation.fromJson(Map<String, dynamic> json) {
    return (json != null) ? TweetEntityAnnotation(
      start: AppJson.intValue(json['start']),
      end: AppJson.intValue(json['end']),
      probability: AppJson.doubleValue(json['probability']),
      type: AppJson.stringValue(json['type']),
      normalizedText: AppJson.stringValue(json['normalized_text']),
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

  static List<TweetEntityAnnotation> listFromJson(List<dynamic> jsonList) {
    List<TweetEntityAnnotation> result;
    if (jsonList != null) {
      result = [];
      for (dynamic jsonEntry in jsonList) {
        result.add((jsonEntry is Map) ? TweetEntityAnnotation.fromJson(jsonEntry) : null);
      }
    }
    return result;
  }

  static List<dynamic> listToJson(List<TweetEntityAnnotation> contentList) {
    List<dynamic> jsonList;
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

class TweetEntityHashtag {
  final int start;
  final int end;
  final String tag;

  TweetEntityHashtag({this.start, this.end, this.tag});

  factory TweetEntityHashtag.fromJson(Map<String, dynamic> json) {
    return (json != null) ? TweetEntityHashtag(
      start: AppJson.intValue(json['start']),
      end: AppJson.intValue(json['end']),
      tag: AppJson.stringValue(json['tag']),
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

  static List<TweetEntityHashtag> listFromJson(List<dynamic> jsonList) {
    List<TweetEntityHashtag> result;
    if (jsonList != null) {
      result = [];
      for (dynamic jsonEntry in jsonList) {
        result.add((jsonEntry is Map) ? TweetEntityHashtag.fromJson(jsonEntry) : null);
      }
    }
    return result;
  }

  static List<dynamic> listToJson(List<TweetEntityHashtag> contentList) {
    List<dynamic> jsonList;
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
  final List<String> mediaKeys;
  List<TwitterMedia> _media;

  TweetAttachments({this.mediaKeys});

  factory TweetAttachments.fromJson(Map<String, dynamic> json) {
    return (json != null) ? TweetAttachments(
      mediaKeys: AppJson.listStringsValue(json['media_keys']),
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
    (DeepCollectionEquality().hash(mediaKeys) ?? 0);

  List<TwitterMedia> get media => _media;

  void _applyIncludes(TweetsIncludes includes) {
    _media = TwitterMedia.listFromKeys(includes?.media, keys: mediaKeys);
  }
}

///////////////////////
// TweetPublicMetrics

class TweetPublicMetrics {
  final int retweetCount;
  final int replyCount;
  final int likeCount;
  final int quoteCount;
  TweetPublicMetrics({this.retweetCount, this.replyCount, this.likeCount, this.quoteCount});

  factory TweetPublicMetrics.fromJson(Map<String, dynamic> json) {
    return (json != null) ? TweetPublicMetrics(
      retweetCount: AppJson.intValue(json['retweet_count']),
      replyCount: AppJson.intValue(json['reply_count']),
      likeCount: AppJson.intValue(json['like_count']),
      quoteCount: AppJson.intValue(json['quote_count']),
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
  final String id;
  final String name;
  final String description;

  TweetContextAnotation({this.id, this.name, this.description});

  factory TweetContextAnotation.fromJson(Map<String, dynamic> json) {
    return (json != null) ? TweetContextAnotation(
      id: AppJson.stringValue(json['id']),
      name: AppJson.stringValue(json['name']),
      description: AppJson.stringValue(json['description']),
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
  final TweetContextAnotation domain;
  final TweetContextAnotation entity;

  TweetContextAnotations({this.domain, this.entity});

  factory TweetContextAnotations.fromJson(Map<String, dynamic> json) {
    return (json != null) ? TweetContextAnotations(
      domain: TweetContextAnotation.fromJson(AppJson.mapValue(json['domain'])),
      entity: TweetContextAnotation.fromJson(AppJson.mapValue(json['entity'])),
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
  final List<TwitterMedia> media;
  final List<TwitterUser> users;

  TweetsIncludes({this.media, this.users});

  factory TweetsIncludes.fromJson(Map<String, dynamic> json) {
    return (json != null) ? TweetsIncludes(
      media: TwitterMedia.listFromJson(AppJson.listValue(json['media'])),
      users: TwitterUser.listFromJson(AppJson.listValue(json['users'])),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'media': TwitterMedia.listToJson(media),
      'users': TwitterUser.listToJson(users),
    };
  }

  bool operator ==(o) =>
    (o is TweetsIncludes) &&
      DeepCollectionEquality().equals(o.media, media) &&
      DeepCollectionEquality().equals(o.users, users);

  int get hashCode =>
    (DeepCollectionEquality().hash(media) ?? 0) ^
    (DeepCollectionEquality().hash(users) ?? 0);
}

///////////////////////
// TwitterMedia

class TwitterMedia {
  final String key;
  final String type;
  final String url;
  final String altText;
  final int width;
  final int height;
  
  TwitterMedia({this.key, this.type, this.url, this.altText, this.width, this.height});

  factory TwitterMedia.fromJson(Map<String, dynamic> json) {
    return (json != null) ? TwitterMedia(
      key: AppJson.stringValue(json['media_key']),
      type: AppJson.stringValue(json['type']),
      url: AppJson.stringValue(json['url']),
      altText: AppJson.stringValue(json['alt_text']),
      width: AppJson.intValue(json['width']),
      height: AppJson.intValue(json['height']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'media_key': key,
      'type': type,
      'url': url,
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
      (o.altText == altText) &&
      (o.width == width) &&
      (o.height == height);

  int get hashCode =>
    (key?.hashCode ?? 0) ^
    (type?.hashCode ?? 0) ^
    (url?.hashCode ?? 0) ^
    (altText?.hashCode ?? 0) ^
    (width?.hashCode ?? 0) ^
    (height?.hashCode ?? 0);

  static List<TwitterMedia> listFromJson(List<dynamic> jsonList) {
    List<TwitterMedia> result;
    if (jsonList != null) {
      result = [];
      for (dynamic jsonEntry in jsonList) {
        result.add((jsonEntry is Map) ? TwitterMedia.fromJson(jsonEntry) : null);
      }
    }
    return result;
  }

  static List<dynamic> listToJson(List<TwitterMedia> contentList) {
    List<dynamic> jsonList;
    if (contentList != null) {
      jsonList = [];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  static TwitterMedia entryInList(List<TwitterMedia> contentList, {String key}) {
    if (contentList != null) {
      for (TwitterMedia contentEntry in contentList) {
        if (contentEntry?.key == key) {
          return contentEntry;
        }
      }
    }
    return null;
  }

  static List<TwitterMedia> listFromKeys(List<TwitterMedia> contentList, {List<String> keys}) {
    List<TwitterMedia> result;
    if ((contentList != null) && (keys != null)) {
      result = <TwitterMedia>[];
      for (String key in keys) {
        result.add(entryInList(contentList, key: key));
      }
    }
    return result;
  }
}

///////////////////////
// TwitterUser

class TwitterUser {

  final String id;
  final DateTime createdAt;
  final String name;
  final String userName;
  final String description;
  final String url;
  final String profileImageUrl;
  final String location;
  final bool protected;
  final bool verified;

  final TweeterUserPublicMetrics publicMetrics;
  final List<TweetEntityUrl> entetityUrls;

  TwitterUser({this.id, this.createdAt, this.name, this.userName, this.description, this.url, this.profileImageUrl, this.location, this.protected, this.verified, this.publicMetrics, this.entetityUrls});

  factory TwitterUser.fromJson(Map<String, dynamic> json) {
    if (json != null) {
      Map<String, dynamic> entities = AppJson.mapValue(json['entities']);
      Map<String, dynamic> entitiesUrl = (entities != null) ? AppJson.mapValue(entities['url']) : null;
      return TwitterUser(
        id: AppJson.stringValue(json['id']),
        createdAt: AppDateTime().dateTimeFromString(AppJson.stringValue(json['created_at']), isUtc: true),
        name: AppJson.stringValue(json['name']),
        userName: AppJson.stringValue(json['username']),
        description: AppJson.stringValue(json['description']),
        url: AppJson.stringValue(json['url']),
        profileImageUrl: AppJson.stringValue(json['profile_image_url']),
        location: AppJson.stringValue(json['location']),
        protected: AppJson.boolValue(json['protected']),
        verified: AppJson.boolValue(json['verified']),
        publicMetrics: TweeterUserPublicMetrics.fromJson(AppJson.mapValue(json['public_metrics'])),
        entetityUrls: (entitiesUrl != null) ? TweetEntityUrl.listFromJson(AppJson.listValue(entitiesUrl['urls'])) : null,
      );
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': AppDateTime().utcDateTimeToString(createdAt),
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
      (o.createdAt == createdAt) &&
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
    (createdAt?.hashCode ?? 0) ^
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

  static List<TwitterUser> listFromJson(List<dynamic> jsonList) {
    List<TwitterUser> result;
    if (jsonList != null) {
      result = [];
      for (dynamic jsonEntry in jsonList) {
        result.add((jsonEntry is Map) ? TwitterUser.fromJson(jsonEntry) : null);
      }
    }
    return result;
  }

  static List<dynamic> listToJson(List<TwitterUser> contentList) {
    List<dynamic> jsonList;
    if (contentList != null) {
      jsonList = [];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  static TwitterUser entryInList(List<TwitterUser> contentList, {String id}) {
    if (contentList != null) {
      for (TwitterUser contentEntry in contentList) {
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
  final int followersCount;
  final int followingCount;
  final int tweetCount;
  final int listedCount;
  TweeterUserPublicMetrics({this.followersCount, this.followingCount, this.tweetCount, this.listedCount});

  factory TweeterUserPublicMetrics.fromJson(Map<String, dynamic> json) {
    return (json != null) ? TweeterUserPublicMetrics(
      followersCount: AppJson.intValue(json['followers_count']),
      followingCount: AppJson.intValue(json['following_count']),
      tweetCount: AppJson.intValue(json['tweet_count']),
      listedCount: AppJson.intValue(json['listed_count']),
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
