// HomeFavorite

import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/auth2.dart';

class HomeFavorite implements Favorite {
  final String? id;
  HomeFavorite(this.id);

  bool operator == (o) => o is HomeFavorite && o.id == id;

  int get hashCode => (id?.hashCode ?? 0);

  static const String keyName = "home";
  static const String categoryName = "WidgetIds";
  static const String favoriteKeyName = "$keyName$categoryName";
  @override String get favoriteKey => favoriteKeyName;
  @override String? get favoriteId => id;
}

// HomeDragAndDropHost

abstract class HomeDragAndDropHost  {
  set isDragging(bool value);
  void onDragAndDrop({String? dragFavoriteId, String? dropFavoriteId, CrossAxisAlignment? dropAnchor});
}

