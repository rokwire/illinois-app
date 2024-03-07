import 'package:flutter/material.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:rokwire_plugin/gen/styles.dart';
import 'package:illinois/gen/styles.dart' as illinois;

extension RecentItemExt on RecentItem {

  Color? get headerColor {
    switch (type) {
      case RecentItemType.event:   return illinois.AppColors.eventColor;
      case RecentItemType.event2:  return illinois.AppColors.eventColor;
      case RecentItemType.dining:  return  illinois.AppColors.diningColor;
      case RecentItemType.game:    return  AppColors.fillColorPrimary;
      case RecentItemType.news:    return  AppColors.fillColorPrimary;
      case RecentItemType.laundry: return  AppColors.accentColor2;
      case RecentItemType.guide:   return  AppColors.accentColor3;
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