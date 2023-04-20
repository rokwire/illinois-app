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
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/wellness/WellnessResourcesContentWidget.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart' as flutter_webview;

class WellnessMentalHealthContentWidget extends StatefulWidget {
  WellnessMentalHealthContentWidget();

  @override
  State<WellnessMentalHealthContentWidget> createState() => _WellnessMentalHealthContentWidgetState();
}

class _WellnessMentalHealthContentWidgetState extends State<WellnessMentalHealthContentWidget> implements NotificationsListener {

  Map<String, List<Map<String, dynamic>>> _sectionLists = <String, List<Map<String, dynamic>>>{};
  List<String> _sections = <String>[];

  bool _isVideoLoading = false;
  String? _videoUrl;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      Guide.notifyChanged,
    ]);
    _initVideo();
    _buildContentData();
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
          _buildContentData();
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
    return _buildContentUi();
  }

  Widget _buildContentUi() {
    List<Widget> widgetList = <Widget>[];

    if (StringUtils.isNotEmpty(_videoUrl)) {
      widgetList.add(_buildContentVideo());
    }

    for (String section in _sections) {
      List<Map<String, dynamic>>? sectionList = _sectionLists[section];
      if ((sectionList != null) && sectionList.isNotEmpty) {
        if (widgetList.isNotEmpty) {
          widgetList.add(Container(height: 24));
        }
        if (section.isNotEmpty) {
          widgetList.add(Padding(padding: EdgeInsets.only(bottom: 2), child:
            Text(section, style: Styles().textStyles?.getTextStyle('widget.title.large.extra_fat'))
          ));
        }
        int startLength = widgetList.length;
        for (Map<String, dynamic> guideItem in sectionList) {
          String? id = Guide().entryId(guideItem);
          String? title = Guide().entryListTitle(guideItem);
          Favorite favorite = GuideFavorite(id: id, contentType: Guide.wellnessMentalHealthContentType);
          if (startLength < widgetList.length) {
            widgetList.add(Container(height: 4));
          }
          widgetList.add(WellnessLargeResourceButton(
            label: title,
            favorite: favorite,
            onTap: () => _onGuideItem(guideItem),
          ));
        }
      }
    }
    
    widgetList.add(Container(height: 24,));
    
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgetList)
    );
  }

  void _buildContentData() {
    _sections.clear();
    _sectionLists.clear();

    List<dynamic>? guideItems = Guide().mentalHealthList;
    if (guideItems != null) {

      for (dynamic entry in guideItems) {
        Map<String, dynamic>? guideItem = JsonUtils.mapValue(entry);
        if (guideItem != null) {
          String section = JsonUtils.stringValue(Guide().entrySection(guideItem)) ?? '';
          List<Map<String, dynamic>>? sectionList = _sectionLists[section];
          if (sectionList == null) {
            _sectionLists[section] = sectionList = <Map<String, dynamic>>[];
            _sections.add(section);
          }
          sectionList.add(guideItem);

        }
      }

      _sections.sort((String section1, String section2) {
        return section1.compareTo(section2);
      });

      _sectionLists.forEach((String secton, List<Map<String, dynamic>> sectionList) {
        sectionList.sort((Map<String, dynamic> entry1, Map<String, dynamic> entry2) {
          int? sortOrder1 = JsonUtils.intValue(entry1['sort_order']);
          int? sortOrder2 = JsonUtils.intValue(entry2['sort_order']);
          if ((sortOrder1 != null) && (sortOrder2 != null)) {
            sortOrder1.compareTo(sortOrder2);
          }

          String? listTitle1 = Guide().entryListTitle(entry1);
          String? listTitle2 = Guide().entryListTitle(entry2);
          if ((listTitle1 != null) && (listTitle2 != null)) {
            listTitle1.compareTo(listTitle2);
          }

          return 0;
        });
      });
    }
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

  Widget _buildContentVideo() {
    if (StringUtils.isEmpty(_videoUrl)) {
      return Container();
    }
    double width = MediaQuery.of(context).size.width;
    double height = (width * 3) / 4;
    return Stack(alignment: Alignment.center, children: [
      Container(
          height: height,
          child: flutter_webview.WebView(
              initialUrl: _videoUrl,
              javascriptMode: flutter_webview.JavascriptMode.unrestricted,
              onPageFinished: (url) {
                setState(() {
                  _isVideoLoading = false;
                });
              })),
      Visibility(visible: _isVideoLoading, child: CircularProgressIndicator())
    ]);
  }

  void _initVideo() {
    _videoUrl = Config().wellnessMentalHealthVideoUrl;
    if (StringUtils.isNotEmpty(_videoUrl)) {
      _isVideoLoading = true;
    }
  }
}
