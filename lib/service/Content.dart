import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/content.dart' as rokwire;
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Content extends rokwire.Content {

  static const String notifyVideoTutorialsChanged = "edu.illinois.rokwire.content.video_tutorials.changed";

  static const String _videoTutorialsContentCategory = "video_tutorials";

  // Singletone Factory

  @protected
  Content.internal() : super.internal();

  factory Content() => ((rokwire.Content.instance is Content) ? (rokwire.Content.instance as Content) : (rokwire.Content.instance = Content.internal()));

  // Content Items

  @override
  void onContentItemsChanged(Set<String> categoriesDiff) {
    if (categoriesDiff.contains(videoTutorialsContentCategory)) {
      _onVideoTutorialsChanged();
    }
    super.onContentItemsChanged(categoriesDiff);
  }

  // ContentItemCategoryClient

  @override
  List<String> get contentItemCategory => <String>[
    ...super.contentItemCategory,
    videoTutorialsContentCategory,
  ];

  // Video Tutorials Content Items

  @protected
  String get videoTutorialsContentCategory =>
    _videoTutorialsContentCategory;

  Map<String, dynamic>? get videoTutorials =>
    contentMapItem(videoTutorialsContentCategory);

  List<dynamic>? get videos =>
    JsonUtils.listValue(MapUtils.get(videoTutorials, 'videos'));

  void _onVideoTutorialsChanged() {
    NotificationService().notify(notifyVideoTutorialsChanged);
  }

}