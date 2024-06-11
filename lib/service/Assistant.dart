import 'package:http/http.dart';
import 'package:illinois/model/Assistant.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Assistant with Service implements NotificationsListener, ContentItemCategoryClient {

  static const String notifyFaqsContentChanged = "edu.illinois.rokwire.assistant.content.faqs.changed";
  static const String _faqContentCategory = "assistant_faqs";
  Map<String, dynamic>? _faqsContent;

  // Singleton Factory
  
  Assistant._internal();
  static final Assistant _instance = Assistant._internal();

  factory Assistant() {
    return _instance;
  }

  Assistant get instance {
    return _instance;
  }

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      Content.notifyContentItemsChanged,
    ]);
  }

  @override
  Future<void> initService() async {
    _faqsContent = Content().contentItem(_faqContentCategory);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Content()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Content.notifyContentItemsChanged) {
      _onContentItemsChanged(param);
    }
  }

  void _onContentItemsChanged(Set<String>? categoriesDiff) {
    if (categoriesDiff?.contains(_faqContentCategory) == true) {
      _faqsContent = Content().contentItem(_faqContentCategory);
      NotificationService().notify(notifyFaqsContentChanged);
    }
  }

  // ContentItemCategoryClient

  @override
  List<String> get contentItemCategory => <String>[_faqContentCategory];

  // FAQs

  String? get faqs {
    if (_faqsContent == null) {
      return null;
    }
    String defaultLocaleCode = Localization().defaultLocale?.languageCode ?? 'en';
    String? selectedLocaleCode = Localization().currentLocale?.languageCode;
    String? defaultFaqs = JsonUtils.stringValue(_faqsContent![defaultLocaleCode]);
    return JsonUtils.stringValue(_faqsContent![selectedLocaleCode]) ?? defaultFaqs;
  }

  // Implementation
  
  Future<Message?> sendQuery(String? query, {Map<String, String>? context}) async {
    if (!isEnabled) {
      Log.w('Failed to send assistant query. Missing assistant url.');
      return null;
    }

    String url = '${Config().aiProxyUrl}/query';
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    Map<String, dynamic> body = {
      'question': query,
    };
    if (context != null) {
      body['context'] = context;
    }

    try {
      String? json = JsonUtils.encode(body);
      Response? response = await Network().post(url, auth: Auth2(), headers: headers, body: json);
      int? responseCode = response?.statusCode;
      String? responseString = response?.body;
      if (responseCode == 200) {
        Map<String, dynamic>? responseJson = JsonUtils.decodeMap(responseString);
        if (responseJson != null) {
          return Message.fromJson(responseJson);
        }
        return null;
      } else {
        Log.w('Failed to load assistant response. Response:\n$responseCode: $responseString');
        return null;
      }
    } catch(e) {
      Log.e('Failed to load assistant response. Response: $e');
      return null;
    }
  }

  Future<Message?> sendFeedback(Message message) async {
    if (!isEnabled) {
      Log.w('Failed to send assistant feedback. Missing assistant url.');
      return null;
    }

    String url = '${Config().aiProxyUrl}/feedback';
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    Map<String, dynamic> body = {
      'message_id': message.id,
      'feedback': message.feedback?.name,
      'explanation': message.feedbackExplanation,
    };

    try {
      String? json = JsonUtils.encode(body);
      Response? response = await Network().post(url, auth: Auth2(), headers: headers, body: json, timeout: 30);
      int? responseCode = response?.statusCode;
      String? responseString = response?.body;
      if (responseCode == 200) {
        Map<String, dynamic>? responseJson = JsonUtils.decodeMap(responseString);
        if (responseJson != null) {
          return Message.fromJson(responseJson);
        }
        return null;
      } else {
        Log.w('Failed to load assistant feedback response. Response:\n$responseCode: $responseString');
        return null;
      }
    } catch(e) {
      Log.e('Failed to load assistant response. Response: $e');
      return null;
    }
  }


  Future<int?> getQueryLimit() async {
    if (!isEnabled) {
      Log.w('Failed to get assistant query limit. Missing assistant url.');
      return null;
    }

    String url = '${Config().aiProxyUrl}/query-limit';
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


  bool get isEnabled => StringUtils.isNotEmpty(Config().aiProxyUrl);
}