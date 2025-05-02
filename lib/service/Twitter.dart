
import 'package:http/http.dart';
import 'package:illinois/model/Twitter.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Twitter  /* with Service */ {

  static const String _tweetFieldsUrlParam = "tweet.fields=attachments,author_id,context_annotations,conversation_id,created_at,entities,geo,id,in_reply_to_user_id,lang,public_metrics,possibly_sensitive,referenced_tweets,reply_settings,source,text,withheld";
  static const String _userFieldsUrlParam = "user.fields=created_at,description,entities,id,location,name,pinned_tweet_id,profile_image_url,protected,public_metrics,url,username,verified,withheld";
  static const String _mediaFieldsUrlParam = "media.fields=duration_ms,height,media_key,preview_image_url,type,url,width,public_metrics,alt_text";
  static const String _expansionsUrlParam = "expansions=attachments.poll_ids,attachments.media_keys,author_id,entities.mentions.username,geo.place_id,in_reply_to_user_id,referenced_tweets.id,referenced_tweets.id.author_id";
  static const String _excludeUrlParam = "exclude=retweets,replies";

  // Singletone instance

  static final Twitter _service = Twitter._internal();
  Twitter._internal();

  factory Twitter() {
    return _service;
  }

  // Service

  Future<TweetsPage?> loadTweetsPage({int? count, DateTime? startTimeUtc, DateTime? endTimeUtc, String? accountKey, String? token, bool? noCache}) async {
    String? twitterUserId = Config().twitterAccountId(accountKey);
    if ((Config().contentUrl != null) && (twitterUserId != null)) {
      String url = "${Config().contentUrl}/twitter/users/$twitterUserId/tweets?$_tweetFieldsUrlParam&$_userFieldsUrlParam&$_mediaFieldsUrlParam&$_expansionsUrlParam&$_excludeUrlParam";
      if (token != null) {
        url += "&pagination_token=$token";
      }
      if (startTimeUtc != null) {
        url += "&start_time=${DateTimeUtils.utcDateTimeToString(startTimeUtc, format: "yyyy-MM-ddTHH:mm:ss")}";
      }
      if (endTimeUtc != null) {
        url += "&end_time=${DateTimeUtils.utcDateTimeToString(endTimeUtc, format: "yyyy-MM-ddTHH:mm:ss")}";
      }
      url += "&max_results=${count ?? Config().twitterTweetsCount}";

      Map<String, String>? headers = (noCache == true) ? {
        "Cache-Control" : "no-cache"
      } : null;
      
      Response? response = await Network().get(url, auth: Auth2(), headers: headers);
      String? responseString = ((response != null) && (response.statusCode == 200)) ? response.body : null;
      //print("Twitter Page Load: ${response?.statusCode}\n${response?.body}");
      return TweetsPage.fromJson(JsonUtils.decodeMap(responseString));
    }
    return null;
  }

  /*Future<TweetsPage> loadTweetsPage({int count, DateTime startTimeUtc, DateTime endTimeUtc, String accountKey, String token}) async {
    if ((Config().twitterUrl != null) && (Config().twitterUserId(accountKey) != null)) {
      String url = "${Config().twitterUrl}/users/${Config().twitterUserId(accountKey)}/tweets?$_tweetFieldsUrlParam&$_userFieldsUrlParam&$_mediaFieldsUrlParam&$_expansionsUrlParam&$_excludeUrlParam";
      if (token != null) {
        url += "&pagination_token=$token";
      }
      if (startTimeUtc != null) {
        url += "&start_time=${DateTimeUtils.utcDateTimeToString(startTimeUtc, format: "yyyy-MM-ddTHH:mm:ss")}";
      }
      if (endTimeUtc != null) {
        url += "&end_time=${DateTimeUtils.utcDateTimeToString(endTimeUtc, format: "yyyy-MM-ddTHH:mm:ss")}";
      }
      url += "&max_results=${count ?? Config().twitterTweetsCount}";

      Map<String, String> headers = {
        HttpHeaders.authorizationHeader : "${Config().twitterTokenType} ${Config().twitterToken}"
      };
      
      Response response = await Network().get(url, headers: headers);
      String responseString = ((response != null) && (response.statusCode == 200)) ? response.body : null;
      //print("Twitter Page Load: ${response?.statusCode}\n${response?.body}");
      return TweetsPage.fromJson(JsonUtils.decodeMap(responseString));
    }
    return null;
  }*/
}