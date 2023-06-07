
import 'package:http/http.dart';
import 'package:illinois/model/Assistant.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Assistant with Service {

  // Singleton Factory
  Assistant._internal();
  static final Assistant _instance = Assistant._internal();

  factory Assistant() {
    return _instance;
  }

  Assistant get instance {
    return _instance;
  }

  Future<Message?> sendQuery(String? query) async {
    if (!isEnabled) {
      Log.w('Failed to send assistant query. Missing assistant url.');
      return null;
    }

    String url = '${Config().assistantUrl}/query';
    String? apiKey = Config().assistantAPIKey;
    if (apiKey == null) {
      Log.w('Failed to send assistant query. Missing assistant api key.');
      return null;
    }
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-API-KEY': apiKey,
    };
    Map<String, dynamic> body = {
      'question': query,
    };

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

  bool get isEnabled => StringUtils.isNotEmpty(Config().wellnessUrl);
}