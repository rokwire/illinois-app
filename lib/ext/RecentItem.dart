import 'package:flutter/material.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:rokwire_plugin/service/styles.dart';

extension RecentItemExt on RecentItem {

  Color? get headerColor {
    switch (type) {
      case RecentItemType.event:   return Styles().colors?.eventColor;
      case RecentItemType.event2:  return Styles().colors?.eventColor;
      case RecentItemType.dining:  return  Styles().colors?.diningColor;
      case RecentItemType.game:    return  Styles().colors?.fillColorPrimary;
      case RecentItemType.news:    return  Styles().colors?.fillColorPrimary;
      case RecentItemType.laundry: return  Styles().colors?.accentColor2;
      case RecentItemType.guide:   return  Styles().colors?.accentColor3;
      default:                     return null;
    }
  }

  String? get iconKey {
    switch (type) {
      case RecentItemType.event:   return 'calendar';
      case RecentItemType.event2:  return 'calendar';
      case RecentItemType.dining:  return 'dining';
      case RecentItemType.game:    return 'athletics';
      case RecentItemType.news:    return 'news';
      case RecentItemType.laundry: return 'laundry';
      case RecentItemType.guide:   return 'guide';
      default:
        return null;
    }
  }

}