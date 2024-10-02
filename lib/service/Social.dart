import 'package:neom/model/Social.dart';
import 'package:neom/service/Auth2.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Social with Service implements NotificationsListener {

  List<Message> _displayMessages = <Message>[];

  // Singleton Factory

  Social._internal();
  static final Social _instance = Social._internal();

  factory Social() {
    return _instance;
  }

  Social get instance {
    return _instance;
  }

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
    ]);
  }

  @override
  Future<void> initService() async {
    // _loadMessages();
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Auth2()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyLoginChanged) {
      // _loadMessages();
    }
  }

  // Messages

  List<Message> get messages => _displayMessages;

  // void _initMessages() {
  //   if (CollectionUtils.isNotEmpty(_displayMessages)) {
  //     _displayMessages.clear();
  //   }
  //   addMessage(Message(
  //       content: Localization().getStringEx('panel.assistant.label.welcome_message.title',
  //           'The Illinois Assistant is a search feature that brings official university resources to your fingertips. Ask a question below to get started.'),
  //       user: false));
  // }

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
}