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

import 'package:flutter/cupertino.dart';
import 'package:illinois/model/Video.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/settings/SettingsVideoTutorialPanel.dart';
import 'package:illinois/ui/wellness/WellnessResourcesContentWidget.dart';
import 'package:illinois/ui/widgets/VideoPlayButton.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class WellnessMentalHealthContentWidget extends StatefulWidget {
  WellnessMentalHealthContentWidget();

  @override
  State<WellnessMentalHealthContentWidget> createState() => _WellnessMentalHealthContentWidgetState();
}

class _WellnessMentalHealthContentWidgetState extends State<WellnessMentalHealthContentWidget> implements NotificationsListener {

  Map<String, List<Map<String, dynamic>>> _sectionLists = <String, List<Map<String, dynamic>>>{};
  List<String> _sections = <String>[];

  Video? _video;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      Guide.notifyChanged,
    ]);
    _loadVideo();
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

    if (_video != null) {
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
    if (_video == null) {
      return Container();
    }
    String? imageUrl = _video!.thumbUrl;
    bool hasImage = StringUtils.isNotEmpty(imageUrl);
    final Widget emptyImagePlaceholder = Container(height: 102);
    return Container(
        decoration: BoxDecoration(
            color: Styles().colors?.white,
            boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4))),
        child: Stack(children: [
          Semantics(button: true,
              label: "${_video?.title ?? ""} video",
              child: GestureDetector(
                onTap: _onTapVideo,
                child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Stack(alignment: Alignment.center, children: [
                        hasImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(imageUrl!,
                                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                  return (loadingProgress == null) ? child : emptyImagePlaceholder;
                                }))
                            : emptyImagePlaceholder,
                        VideoPlayButton()
                      ])))),
          Container(color: Styles().colors?.accentColor3, height: 4)
        ]));
  }

  void _loadVideo() {
    String? videoUrl = Config().wellnessMentalHealthVideoUrl;
    if (StringUtils.isNotEmpty(videoUrl)) {
      String title = Localization().getStringEx('panel.wellness.sections.mental_health.video.title', 'Mental Health');
      _video = Video(
          videoUrl: videoUrl, ccUrl: Config().wellnessMentalHealthCcUrl, thumbUrl: Config().wellnessMentalHealthThumbUrl, title: title);
    }
  }

  void _onTapVideo() {
    if (_video != null) {
      Analytics().logSelect(
          target: 'Mental Health Video', source: widget.runtimeType.toString(), attributes: _video!.analyticsAttributes);
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsVideoTutorialPanel(videoTutorial: _video!)));
    }
  }
}
