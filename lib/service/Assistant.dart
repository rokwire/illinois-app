import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:illinois/model/Assistant.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/ext/network.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Assistant with Service, NotificationsListener, ContentItemCategoryClient {

  static const String notifyFaqsContentChanged = "edu.illinois.rokwire.assistant.content.faqs.changed";
  static const String notifyProvidersChanged = "edu.illinois.rokwire.assistant.providers.changed";
  static const String notifySettingsChanged = "edu.illinois.rokwire.assistant.settings.changed";
  static const String _faqContentCategory = "assistant_faqs";

  AssistantUser? _user;
  AssistantSettings? _settings;
  List<AssistantProvider>? _providers;
  Map<String, dynamic>? _faqsContent;

  DateTime?  _pausedDateTime;

  Map<AssistantProvider, List<Message>> _displayMessages = <AssistantProvider, List<Message>>{
    AssistantProvider.google: List<Message>.empty(growable: true),
    AssistantProvider.grok: List<Message>.empty(growable: true),
    AssistantProvider.perplexity: List<Message>.empty(growable: true),
    AssistantProvider.openai: List<Message>.empty(growable: true)
  };

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
      FlexUI.notifyChanged,
      AppLivecycle.notifyStateChanged,
    ]);
  }

  @override
  Future<void> initService() async {
    _initFaqs();
    if (Auth2().isLoggedIn) {
      _loadSettings();
      _loadUser();
      _loadAllMessages();
      _buildAvailableProviders();
    }
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Auth2(), Content(), FlexUI()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Content.notifyContentItemsChanged) {
      _onContentItemsChanged(param);
    } else if (name == Auth2.notifyLoginChanged) {
      _loadSettings();
      _loadUser();
      _buildAvailableProviders();
      if (Auth2().isLoggedIn) {
        _loadAllMessages();
      } else {
        _clearAllMessages();
      }
    } else if (name == FlexUI.notifyChanged) {
      _buildAvailableProviders();
    } else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onContentItemsChanged(Set<String>? categoriesDiff) {
    if (categoriesDiff?.contains(_faqContentCategory) == true) {
      _initFaqs();
      NotificationService().notify(notifyFaqsContentChanged);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _loadSettings();
        }
      }
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

  // Settings

  bool get isAvailable => _settings?.available ?? false;
  String? get localizedTermsText => _settings?.getTermsText(locale: _localeCode);
  String? get localizedUnavailableText => _settings?.getUnavailableText(locale: _localeCode);

  String? get _localeCode => (Localization().currentLocale ?? Localization().defaultLocale)?.languageCode;

  Future<void> _loadSettings() async {
    AssistantSettings? settings;
    if (!_isEnabled) {
      Log.w('Assistant settings - missing url.');
    } else if (Auth2().isLoggedIn) {
      String? url = '${Config().aiProxyUrl}/client-settings';
      Response? response = await Network().get(url, auth: Auth2());
      int? responseCode = response?.statusCode;
      String? responseString = response?.body;
      if (responseCode == 200) {
        settings = AssistantSettings.fromJson(JsonUtils.decodeMap(responseString));
      } else {
        Log.w('Failed to load assistant settings. Reason: $responseCode, $responseString');
      }
    }
    if (_settings != settings) {
      _settings = settings;
      NotificationService().notify(notifySettingsChanged);
    }
  }

  // User

  bool hasUserAcceptedTerms() {
    DateTime? termsAcceptedDate = _user?.termsAcceptedDateUtc;
    if (termsAcceptedDate == null) {
      return false;
    }
    DateTime? termsIntroducedDate = _settings?.termsAcceptedDateUtc;
    if (termsIntroducedDate == null) {
      return true;
    }
    return termsIntroducedDate.isBefore(termsAcceptedDate);
  }

  Future<bool> acceptTerms() async {
    if (!_isEnabled) {
      Log.w('Assistant acceptTerms - missing url.');
      return false;
    }
    if (!Auth2().isLoggedIn) {
      Log.w('Assistant acceptTerms - user not signed in.');
      return false;
    }
    String? url = '${Config().aiProxyUrl}/user-consent';
    Response? response = await Network().post(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      await _loadUser();
      return true;
    } else {
      Log.w('Failed to accept assistant terms. Reason: $responseCode, $responseString');
      return false;
    }
  }

  Future<void> _loadUser() async {
    AssistantUser? user;
    if (!_isEnabled) {
      Log.w('Assistant loading user - missing url.');
    } else if (Auth2().isLoggedIn) {
      String? url = '${Config().aiProxyUrl}/user-settings';
      Response? response = await Network().get(url, auth: Auth2());
      int? responseCode = response?.statusCode;
      String? responseString = response?.body;
      if (responseCode == 200) {
        user = AssistantUser.fromJson(JsonUtils.decodeMap(responseString));
      } else {
        Log.w('Failed to load assistant user. Reason: $responseCode, $responseString');
      }
    }
    _user = user;
  }

  // Providers

  List<AssistantProvider>? get providers => _providers;

  void _buildAvailableProviders() {
    List<AssistantProvider>? updatedProviders;
    List<String>? contentCodes = JsonUtils.listStringsValue(FlexUI()['assistant']);
    if (contentCodes != null) {
      updatedProviders = <AssistantProvider>[];
      for (String code in contentCodes) {
        AssistantProvider? provider = _providerFromCode(code);
        if (provider != null) {
          updatedProviders.add(provider);
        }
      }
    } else {
      updatedProviders = null;
    }
    if (!DeepCollectionEquality().equals(_providers, updatedProviders)) {
      _providers = updatedProviders;
      NotificationService().notify(notifyProvidersChanged);
    }
  }

  AssistantProvider? _providerFromCode(String? code) {
    switch (code) {
      case 'google_assistant':
        return AssistantProvider.google;
      case 'grok_assistant':
        return AssistantProvider.grok;
      case 'perplexity_assistant':
        return AssistantProvider.perplexity;
      case 'openai_assistant':
        return AssistantProvider.openai;
      default:
        return null;
    }
  }

  // Messages

  List<Message> getMessages({AssistantProvider? provider}) {
    if (provider != null) {
      return _displayMessages[provider] ?? List<Message>.empty();
    } else {
      return List<Message>.empty();
    }
  }

  void _initMessages({required AssistantProvider provider}) {
    if (CollectionUtils.isNotEmpty(_displayMessages[provider])) {
      _displayMessages[provider]!.clear();
    }
    addMessage(
        provider: provider,
        message: Message(
            content: Localization().getStringEx('panel.assistant.label.welcome_message.title',
                '**Ask a question below to explore university resources with the NEW Illinois Assistant!**\nCheck the accuracy of responses. Your feedback ([:thumb_up:] [:thumb_down:]) will help improve the Assistant over time.'),
            user: false));
  }

  void _clearAllMessages() {
    for (AssistantProvider provider in AssistantProvider.values) {
      if (CollectionUtils.isNotEmpty(_displayMessages[provider])) {
        _displayMessages[provider]!.clear();
      }
    }
  }

  void addMessage({required AssistantProvider provider, required Message message}) {
    _displayMessages[provider]!.add(message);
  }

  void removeMessage({required AssistantProvider provider, required Message message}) {
    _displayMessages[provider]!.remove(message);
  }

  void removeLastMessage({required AssistantProvider provider}) {
    if (CollectionUtils.isNotEmpty(_displayMessages[provider])) {
      _displayMessages[provider]!.removeLast();
    }
  }

  Future<bool> removeAllMessages() async {
    bool succeeded = false;
    if (_isEnabled) {
      String url = '${Config().aiProxyUrl}/messages';
      Response? response = await Network().delete(url, auth: Auth2());
      succeeded = (response?.statusCode == 200);
      if (succeeded) {
        await _loadAllMessages();
      } else {
        Log.e('Failed to delete assistant messages. Reason: ${response?.statusCode}, ${response?.body}');
      }
    }
    return succeeded;
  }

  Future<void> _loadAllMessages() async {
    await Future.wait([
      _loadMessages(provider: AssistantProvider.google),
      _loadMessages(provider: AssistantProvider.grok),
      _loadMessages(provider: AssistantProvider.perplexity),
      _loadMessages(provider: AssistantProvider.openai),
    ]);
  }

  Future<void> _loadMessages({required AssistantProvider provider}) async {
    List<dynamic>? responseJson;
    if (_isEnabled) {
      String url = '${Config().aiProxyUrl}/messages/load';
      Map<String, String> headers = {'Content-Type': 'application/json'};
      Map<String, dynamic> bodyJson = {'sort_by': 'date', 'order': 'asc', 'provider': assistantProviderToKeyString(provider)};
      String? body = JsonUtils.encode(bodyJson);
      Response? response = await Network().post(url, auth: Auth2(), headers: headers, body: body);
      int? responseCode = response?.statusCode;
      String? responseString = response?.body;
      if (responseCode == 200) {
        responseJson = JsonUtils.decodeList(responseString);
      } else {
        Log.i('Failed to load assistant (${assistantProviderToKeyString(provider)}) messages. Response:\n$responseCode: $responseString');
      }
    } else {
      Log.i('Failed to load assistant (${assistantProviderToKeyString(provider)}) messages. Missing assistant url.');
    }
    _buildDisplayMessageList(provider: provider, messagesJsonList: responseJson);
  }

  void _buildDisplayMessageList({required AssistantProvider provider, List<dynamic>? messagesJsonList}) {
    _initMessages(provider: provider);
    if ((messagesJsonList != null) && messagesJsonList.isNotEmpty) {
      for(dynamic messageJsonEntry in messagesJsonList) {
        Message question = Message.fromQueryJson(messageJsonEntry);
        Message answer = Message.fromAnswerJson(messageJsonEntry);
        _displayMessages[provider]!.add(question);
        _displayMessages[provider]!.add(answer);
      }
    }
  }

  // Implementation
  
  Future<Message?> sendQuery(String? query, {AssistantProvider? provider, AssistantLocation? location, Map<String, String>? context}) async {
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
    if (provider != null) {
      body['provider'] = assistantProviderToKeyString(provider);
    }
    if (location != null) {
      body['params'] = {
        'location': {'latitude': location.latitude, 'longitude': location.longitude}
      };
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

  Future<Map<String, dynamic>?> loadUserDataJson() async {
    Response? response = (Config().aiProxyUrl != null) ? await Network().get("${Config().aiProxyUrl}/user-data", auth: Auth2()) : null;
    return (response?.succeeded == true) ? JsonUtils.decodeMap(response?.body) : null;
  }
}