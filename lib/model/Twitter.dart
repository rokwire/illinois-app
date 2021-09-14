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
}

///////////////////////
// TweetContextAnotations

class TweetContextAnotations {
  final TweetContextAnotation domainAnotation;
  final TweetContextAnotation entityAnotation;

  TweetContextAnotations({this.domainAnotation, this.entityAnotation});

  factory TweetContextAnotations.fromJson(Map<String, dynamic> json) {
    return (json != null) ? TweetContextAnotations(
      domainAnotation: TweetContextAnotation.fromJson(AppJson.mapValue(json['domain'])),
      entityAnotation: TweetContextAnotation.fromJson(AppJson.mapValue(json['entity'])),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'domain': domainAnotation?.toJson(),
      'entity': entityAnotation?.toJson(),
    };
  }
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
}
