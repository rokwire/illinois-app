import 'dart:ui';

import 'package:http/http.dart';
import 'package:illinois/model/Assistant.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/ext/network.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Assistant with Service, NotificationsListener {

  static const String notifySettingsChanged = "edu.illinois.rokwire.assistant.settings.changed";
  static const String notifyUserChanged = "edu.illinois.rokwire.assistant.user.changed";

  AssistantUser? _user;
  AssistantSettings? _settings;

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
      Auth2.notifyLoginChanged,
      AppLivecycle.notifyStateChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Future<void> initService() async {

    List<Future<String?>> initFutures = <Future<String?>>[];

    int? futuresSettingsIndex;
    _settings = AssistantSettings.fromJson(JsonUtils.decodeMap(Storage().assistantSettings));
    if (_settings == null) {
      futuresSettingsIndex = initFutures.length;
      initFutures.add(_loadSettingsStringFromNet());
    }
    else {
      _updateSettings();
    }

    int? futuresUserIndex;
    _user = AssistantUser.fromJson(JsonUtils.decodeMap(Storage().assistantUser));
    if (_user == null) {
      futuresUserIndex = initFutures.length;
      initFutures.add(_loadUserStringFromNet());
    }
    else {
      _updateUser();
    }

    // Do not wait for messages loading, load them assynchronically
    _loadAllMessages();

    if (initFutures.isNotEmpty) {
      List<String?> futuresResults = await Future.wait<String?>(initFutures);
      if (futuresSettingsIndex != null) {
        String? settingsString = ListUtils.entry<String?>(futuresResults, futuresSettingsIndex);
        if (settingsString != null) {
          _settings = AssistantSettings.fromJson(JsonUtils.decodeMap(settingsString));
          Storage().assistantSettings = settingsString;
        }
      }
      if (futuresUserIndex != null) {
        String? userString = ListUtils.entry<String?>(futuresResults, futuresUserIndex);
        if (userString != null) {
          _user = AssistantUser.fromJson(JsonUtils.decodeMap(userString));
          Storage().assistantUser = userString;
        }
      }
    }

    await super.initService();
  }


  @override
  Set<Service> get serviceDependsOn =>
    <Service>{ Storage(), Config(), Auth2() };

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyLoginChanged) {
      _updateUser();
      _updateSettings();
      _loadAllMessages();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateUser();
          _updateSettings();
        }
      }
    }
  }

  // Settings
  AssistantSettings? get settings => _settings;

  bool get isAvailable => (_settings?.available == true);

  Future<String?> _loadSettingsStringFromNet() async {
    if (_isEnabled) {
      String? url = '${Config().aiProxyUrl}/client-settings';
      Response? response = await Network().get(url, auth: Auth2());
      int? responseCode = response?.statusCode;
      String? responseString = response?.body;
      if (responseCode == 200) {
        Log.i('Succeeded to load assistant settings.');
        return responseString;
      } else {
        Log.w('Failed to load assistant settings. Reason: $responseCode, $responseString');
      }
    }
    else {
      Log.w('Assistant settings - missing url.');
    }
    return null;
  }

  //Future<AssistantSettings?> _loadSettings() async =>
  //  AssistantSettings.fromJson(JsonUtils.decodeMap(await _loadSettingsStringFromNet()));

  Future<void> _updateSettings() async {
    String? settingsString = await _loadSettingsStringFromNet();
    AssistantSettings? settings = AssistantSettings.fromJson(JsonUtils.decodeMap(settingsString));
    if ((settings != null) && (settings != _settings)) {
      _settings = settings;
      Storage().assistantSettings = settingsString;
      NotificationService().notify(notifySettingsChanged);
    }
  }

  // User

  Future<String?> _loadUserStringFromNet() async {
    if (_isEnabled) {
      String? url = '${Config().aiProxyUrl}/user-settings';
      Response? response = await Network().get(url, auth: Auth2());
      int? responseCode = response?.statusCode;
      String? responseString = response?.body;
      if (responseCode == 200) {
        return responseString;
      } else {
        Log.w('Failed to load assistant user. Reason: $responseCode, $responseString');
      }
    }
    else {
      Log.w('Assistant loading user - missing url.');
    }
    return null;
  }

  //Future<AssistantUser?> _loadUser() async =>
  //  AssistantUser.fromJson(JsonUtils.decodeMap(await _loadUserStringFromNet()));

  Future<void> _updateUser() async {
    String? userString = await _loadUserStringFromNet();
    AssistantUser? user = AssistantUser.fromJson(JsonUtils.decodeMap(userString));
    if ((user != null) && (user != _user)) {
      _user = user;
      Storage().assistantUser = userString;
      NotificationService().notify(notifyUserChanged);
    }
  }

  bool hasUserAcceptedTerms() {
    DateTime? termsAcceptedDate = _user?.termsAcceptedDateUtc;
    if (termsAcceptedDate == null) {
      return false;
    }
    DateTime? termsIntroducedDate = _settings?.termsSubmittedDateUtc;
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
    String? url = '${Config().aiProxyUrl}/user-consent';
    Response? response = await Network().post(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      await _updateUser();
      return true;
    } else {
      Log.w('Failed to accept assistant terms. Reason: $responseCode, $responseString');
      return false;
    }
  }

  // Messages

  List<Message> getMessages({AssistantProvider? provider}) =>
    _displayMessages[provider] ?? List<Message>.empty();

  void _applyMessages(List<Message>? messages, { required AssistantProvider provider}) {
    List<Message> providerMessages = _displayMessages[provider] ??= List<Message>.empty(growable: true);
    if (messages != null) {
      providerMessages.clear();
      providerMessages.add(_initialMessage);
      providerMessages.addAll(messages);
    }
  }

  Message get _initialMessage => Message(
    content: Localization().getStringEx('panel.assistant.label.welcome_message.title',
      '**Ask a question below to explore university resources with the NEW Illinois Assistant!**\nCheck the accuracy of responses. Your feedback ([:thumb_up:] [:thumb_down:]) will help improve the Assistant over time.'),
    user: false
  );

  void addMessage({required AssistantProvider provider, required Message message}) {
    (_displayMessages[provider] ??= List<Message>.empty(growable: true)).add(message);
  }

  void removeMessage({required AssistantProvider provider, required Message message}) {
    _displayMessages[provider]?.remove(message);
  }

  void removeLastMessage({required AssistantProvider provider}) {
    List<Message>? providerMessages = _displayMessages[provider];
    if ((providerMessages != null) && providerMessages.isNotEmpty) {
      providerMessages.removeLast();
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
    List<AssistantProvider> providers = AssistantProvider.values;
    Iterable<Future<List<Message>?>> providerFutures = providers.map((AssistantProvider provider) => _loadMessages(provider:provider));
    List<List<Message>?> results = await Future.wait<List<Message>?>(providerFutures);
    for (int index = 0; index < providers.length; index++) {
      _applyMessages(ListUtils.entry<List<Message>?>(results, index), provider: providers[index]);
    }
  }

  Future<List<Message>?> _loadMessages({required AssistantProvider provider}) async {
    if (_isEnabled) {
      String url = '${Config().aiProxyUrl}/messages/load';
      Map<String, String> headers = {'Content-Type': 'application/json'};
      Map<String, dynamic> bodyJson = {'sort_by': 'date', 'order': 'asc', 'provider': provider.key};
      String? body = JsonUtils.encode(bodyJson);
      Response? response = await Network().post(url, auth: Auth2(), headers: headers, body: body);
      int? responseCode = response?.statusCode;
      String? responseString = response?.body;
      if (responseCode == 200) {
        return Message.listFromJsonList(JsonUtils.decodeList(responseString));
      } else {
        Log.i('Failed to load assistant (${provider.key}) messages. Response:\n$responseCode: $responseString');
      }
    } else {
      Log.i('Failed to load assistant (${provider.key}) messages. Missing assistant url.');
    }
    return null;
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
      body['provider'] = provider.key;
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