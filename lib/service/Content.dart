import 'package:flutter/foundation.dart';
import 'package:illinois/model/Content.dart';
import 'package:rokwire_plugin/service/content.dart' as rokwire;
import 'package:rokwire_plugin/service/notification_service.dart';

class Content extends rokwire.Content {

  static String get notifyContentItemsChanged           => rokwire.Content.notifyContentItemsChanged;
  static String get notifyContentAttributesChanged      => rokwire.Content.notifyContentAttributesChanged;
  static String get notifyContentImagesChanged          => rokwire.Content.notifyContentImagesChanged;
  static String get notifyContentWidgetsChanged         => rokwire.Content.notifyContentWidgetsChanged;
  static String get notifyUserProfilePictureChanged     => rokwire.Content.notifyUserProfilePictureChanged;
  static const String notifyContentAlertChanged         = "edu.illinois.rokwire.content.alert.changed";

  static const String _alertContentCategory = "alert";

  ContentAlert? _contentAlert;

  // Singletone Factory

  @protected
  Content.internal() : super.internal();

  factory Content() => ((rokwire.Content.instance is Content) ? (rokwire.Content.instance as Content) : (rokwire.Content.instance = Content.internal()));

  // Service

  @override
  Future<void> initService() async {
    await super.initService();
    _contentAlert = _contentMapAlert();
  }

  // ContentItemCategoryClient

  @override
  List<String> get contentItemCategory => <String>[
    ...super.contentItemCategory,
    _alertContentCategory,
  ];

  // ContentItems

  @protected
  void onContentItemsChanged(Set<String> categoriesDiff) {
    if (categoriesDiff.contains(_alertContentCategory)) {
      _onContentAlertChanged();
    }
    super.onContentItemsChanged(categoriesDiff);
  }

  // Alert Content Item

  ContentAlert? get contentAlert => _contentAlert;

  ContentAlert? _contentMapAlert() => ContentAlert.fromJson(contentMapItem(_alertContentCategory)) ;

  void _onContentAlertChanged() {
    ContentAlert? contentAlert = _contentMapAlert();
    if (_contentAlert != contentAlert) {
      _contentAlert = contentAlert;
      NotificationService().notify(notifyContentAlertChanged);
    }
  }
}