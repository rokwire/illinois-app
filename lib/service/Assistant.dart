import 'package:http/http.dart';
import 'package:neom/model/Assistant.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/service/Config.dart';
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

  List<Message> _displayMessages = <Message>[];

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
      Auth2.notifyLoginChanged,
    ]);
  }

  @override
  Future<void> initService() async {
    _loadMessages();
    _initFaqs();
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
    } else if (name == Auth2.notifyLoginChanged) {
      _loadMessages();
    }
  }

  void _onContentItemsChanged(Set<String>? categoriesDiff) {
    if (categoriesDiff?.contains(_faqContentCategory) == true) {
      _initFaqs();
      NotificationService().notify(notifyFaqsContentChanged);
    }
  }

  // ContentItemCategoryClient

  @override
  List<String> get contentItemCategory => <String>[_faqContentCategory];

  // FAQs

  void _initFaqs() {
    _faqsContent = Content().contentItem(_faqContentCategory);
  }

  String? get faqs {
    if (_faqsContent == null) {
      return null;
    }
    String defaultLocaleCode = Localization().defaultLocale?.languageCode ?? 'en';
    String? selectedLocaleCode = Localization().currentLocale?.languageCode;
    String? defaultFaqs = JsonUtils.stringValue(_faqsContent![defaultLocaleCode]);
    return JsonUtils.stringValue(_faqsContent![selectedLocaleCode]) ?? defaultFaqs;
  }

  // Messages

  List<Message> get messages => _displayMessages;

  void _initMessages() {
    if (CollectionUtils.isNotEmpty(_displayMessages)) {
      _displayMessages.clear();
    }
    addMessage(Message(
        content: Localization().getStringEx('panel.assistant.label.welcome_message.title',
            'The Illinois Assistant is a search feature that brings official university resources to your fingertips. Ask a question below to get started.'),
        user: false));
  }

  void addMessage(Message message) {
    _displayMessages.add(message);
  }

  void removeMessage(Message message) {
    _displayMessages.remove(message);
  }

  void removeLastMessage() {
    if (CollectionUtils.isNotEmpty(_displayMessages)) {
      _displayMessages.removeLast();
    }
  }

  Future<bool> removeAllMessages() async {
    bool succeeded = false;
    if (_isEnabled) {
      String url = '${Config().aiProxyUrl}/messages';
      Response? response = await Network().delete(url, auth: Auth2());
      succeeded = (response?.statusCode == 200);
      if (succeeded) {
        await _loadMessages();
      } else {
        Log.e('Failed to delete assistant messages. Reason: ${response?.statusCode}, ${response?.body}');
      }
    }
    return succeeded;
  }

  Future<void> _loadMessages() async {
    List<dynamic>? responseJson;
    if (_isEnabled) {
      String url = '${Config().aiProxyUrl}/messages/load';
      Map<String, String> headers = {'Content-Type': 'application/json'};
      Map<String, dynamic> bodyJson = {'sort_by': 'date', 'order': 'asc'};
      String? body = JsonUtils.encode(bodyJson);
      Response? response = await Network().post(url, auth: Auth2(), headers: headers, body: body);
      int? responseCode = response?.statusCode;
      String? responseString = response?.body;
      if (responseCode == 200) {
        responseJson = JsonUtils.decodeList(responseString);
      } else {
        Log.i('Failed to load assistant messages. Response:\n$responseCode: $responseString');
      }
    } else {
      Log.i('Failed to load assistant messages. Missing assistant url.');
    }
    _buildDisplayMessageList(responseJson);
  }

  void _buildDisplayMessageList(List<dynamic>? messagesJsonList) {
    _initMessages();
    if ((messagesJsonList != null) && messagesJsonList.isNotEmpty) {
      for(dynamic messageJsonEntry in messagesJsonList) {
        Message question = Message.fromQueryJson(messageJsonEntry);
        Message answer = Message.fromAnswerJson(messageJsonEntry);
        _displayMessages.add(question);
        _displayMessages.add(answer);
      }
    }
  }

  // Implementation
  
  Future<Message?> sendQuery(String? query, {Map<String, String>? context}) async {
    if (!_isEnabled) {
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
          return Message.fromAnswerJson(responseJson);
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
    if (!_isEnabled) {
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
          return Message.fromAnswerJson(responseJson);
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
    if (!_isEnabled) {
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


  bool get _isEnabled => StringUtils.isNotEmpty(Config().aiProxyUrl);
}