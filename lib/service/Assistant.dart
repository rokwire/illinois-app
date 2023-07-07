
import 'package:http/http.dart';
import 'package:illinois/model/Assistant.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Assistant /* with Service */ {

  // Singleton Factory
  
  Assistant._internal();
  static final Assistant _instance = Assistant._internal();

  factory Assistant() {
    return _instance;
  }

  Assistant get instance {
    return _instance;
  }

  // Implementation
  
  Future<Message?> sendQuery(String? query, {List<String>? context}) async {
    if (!isEnabled) {
      Log.w('Failed to send assistant query. Missing assistant url.');
      return null;
    }

    String url = '${Config().assistantUrl}/query';
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    Map<String, dynamic> body = {
      'question': query,
    };
    if (context != null) {
      body['context'] = context;
    }

    String? json = JsonUtils.encode(body);
    Response? response = await Network().post(url, auth: Auth2(), headers: headers, body: json);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Map<String, dynamic>? responseJson = JsonUtils.decodeMap(responseString);
      Map<String, dynamic>? answerJson = responseJson?['answer'];
      if (answerJson != null) {
        return Message.fromAnswerJson(answerJson);
      }
      return null;
    } else {
      Log.w('Failed to load assistant response. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  Future<Message?> sendFeedback(Message message) async {
    if (!isEnabled) {
      Log.w('Failed to send assistant feedback. Missing assistant url.');
      return null;
    }

    String url = '${Config().assistantUrl}/feedback';
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    Map<String, dynamic> body = {
      'message_id': message.id,
      'feedback': message.feedback?.name,
      'explanation': message.feedbackExplanation,
    };

    String? json = JsonUtils.encode(body);
    Response? response = await Network().post(url, auth: Auth2(), headers: headers, body: json, timeout: 30);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Map<String, dynamic>? responseJson = JsonUtils.decodeMap(responseString);
      Map<String, dynamic>? answerJson = responseJson?['answer'];
      if (answerJson != null) {
        return Message.fromAnswerJson(answerJson);
      }
      return null;
    } else {
      Log.w('Failed to load assistant feedback response. Response:\n$responseCode: $responseString');
      return null;
    }
  }


  Future<int?> getQueryLimit() async {
    if (!isEnabled) {
      Log.w('Failed to get assistant query limit. Missing assistant url.');
      return null;
    }

    String url = '${Config().assistantUrl}/query-limit';
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    Response? response = await Network().get(url, auth: Auth2(), headers: headers);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      Map<String, dynamic>? responseJson = JsonUtils.decodeMap(responseString);
      dynamic limit = responseJson?['limit'];
      if (limit is int) {
        return limit;
      }
      return null;
    } else {
      Log.w('Failed to load assistant query limit response. Response:\n$responseCode: $responseString');
      return null;
    }
  }


  bool get isEnabled => StringUtils.isNotEmpty(Config().assistantUrl);
}