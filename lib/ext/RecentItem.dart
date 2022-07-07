import 'package:flutter/material.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:rokwire_plugin/service/styles.dart';

extension RecentItemExt on RecentItem {

  Color? get headerColor {
    switch (type) {
      case RecentItemType.event:   return Styles().colors?.eventColor;
      case RecentItemType.dining:  return  Styles().colors?.diningColor;
      case RecentItemType.game:    return  Styles().colors?.fillColorPrimary;
      case RecentItemType.news:    return  Styles().colors?.fillColorPrimary;
      case RecentItemType.laundry: return  Styles().colors?.accentColor2;
      case RecentItemType.guide:   return  Styles().colors?.accentColor3;
      default:                     return null;
    }
  }

  String? get iconPath {
    switch (type) {
      case RecentItemType.event:   return 'images/icon-calendar.png';
      case RecentItemType.dining:  return 'images/icon-dining-yellow.png';
      case RecentItemType.game:    return 'images/icon-athletics-blue.png';
      case RecentItemType.news:    return 'images/icon-news.png';
      case RecentItemType.laundry: return 'images/icon-news.png';
      case RecentItemType.guide:   return 'images/icon-news.png';
      default:
        return null;
    }
  }

}