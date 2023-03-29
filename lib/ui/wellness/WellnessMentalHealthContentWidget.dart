/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/wellness/WellnessResourcesContentWidget.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class WellnessMentalHealthContentWidget extends StatefulWidget {
  WellnessMentalHealthContentWidget();

  @override
  State<WellnessMentalHealthContentWidget> createState() => _WellnessMentalHealthContentWidgetState();
}

class _WellnessMentalHealthContentWidgetState extends State<WellnessMentalHealthContentWidget> implements NotificationsListener {

  List<dynamic>? _guideItems;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      Guide.notifyChanged,
    ]);
    _initContent();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }
  
  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Guide.notifyChanged) {
      if (mounted) {
        setState(() {
          _initContent();
        });
      }
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    List<Widget> widgetList = <Widget>[];
    if (_guideItems != null) {
      for (dynamic entry in _guideItems!) {
        Map<String, dynamic>? guideItem = JsonUtils.mapValue(entry);
        if (guideItem != null) {
          String? id = Guide().entryId(guideItem);
          String? title = Guide().entryListTitle(guideItem);
          Favorite favorite = GuideFavorite(id: id, contentType: Guide.wellnessMentalHealthContentType);
          if (widgetList.isNotEmpty) {
            widgetList.add(Container(height: 8));
          }
          widgetList.add(WellnessLargeResourceButton(
            label: title,
            favorite: favorite,
            onTap: () => _onGuideItem(guideItem),
          ));
        }
      }
    }

    widgetList.add(Container(height: 16,));
    
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Column(children: widgetList));
  }

  void _initContent() {
    _guideItems = Guide().mentalHealthList;
  }

  void _onGuideItem(Map<String, dynamic> guideItem) {
    String? title = Guide().entryListTitle(guideItem);
    Analytics().logSelect(target: title, source: widget.runtimeType.toString());

    String? id = Guide().entryId(guideItem);
    String? url = "${Guide().guideDetailUrl}?guide_id=$id";
    if (DeepLink().isAppUrl(url)) {
      DeepLink().launchUrl(url);
    }
    else {
      Uri? uri = Uri.tryParse(url);
      if (uri != null) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
