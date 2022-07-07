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
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/wellness/WellnessResourcesContentWidget.dart';
import 'package:illinois/ui/wellness/rings/WellnessRingsHomeContentWidget.dart';
import 'package:illinois/ui/wellness/WellnessDailyTipsContentWidget.dart';
import 'package:illinois/ui/wellness/todo/WellnessToDoHomeContentWidget.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

enum WellnessContent { dailyTips, rings, todo, resources, podcast, struggling }

class WellnessHomePanel extends StatefulWidget {
  final WellnessContent? content;
  final bool rootTabDisplay;

  WellnessHomePanel({this.content, this.rootTabDisplay = false});

  @override
  _WellnessHomePanelState createState() => _WellnessHomePanelState();
}

class _WellnessHomePanelState extends State<WellnessHomePanel> {
  static WellnessContent? _lastSelectedContent;
  late WellnessContent _selectedContent;
  ScrollController _scrollController = ScrollController();
  bool _contentValuesVisible = false;

  @override
  void initState() {
    super.initState();
    _selectedContent = selectableContent(widget.content) ?? (_lastSelectedContent ?? WellnessContent.dailyTips);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: headerBar,
        body: Column(children: <Widget>[
          Expanded(
              child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: (_contentValuesVisible ? NeverScrollableScrollPhysics() : null),
                  child: Container(
                      color: Styles().colors!.background,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(
                            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
                            child: RibbonButton(
                                textColor: Styles().colors!.fillColorSecondary,
                                backgroundColor: Styles().colors!.white,
                                borderRadius: BorderRadius.all(Radius.circular(5)),
                                border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
                                rightIconAsset: (_contentValuesVisible ? 'images/icon-up.png' : 'images/icon-down-orange.png'),
                                label: _getContentLabel(_selectedContent),
                                onTap: _changeSettingsContentValuesVisibility)),
                        _buildContent()
                      ]))))
        ]),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: navigationBar);
  }

  Widget _buildContent() {
    return Stack(children: [Padding(padding: EdgeInsets.symmetric(vertical: 16), child: _contentWidget), _buildContentValuesContainer()]);
  }

  Widget _buildContentValuesContainer() {
    return Visibility(
        visible: _contentValuesVisible,
        child: Positioned.fill(child: Stack(children: <Widget>[_buildContentDismissLayer(), _buildContentValuesWidget()])));
  }

  Widget _buildContentDismissLayer() {
    return Positioned.fill(
        child: BlockSemantics(
            child: GestureDetector(
                onTap: () {
                  setState(() {
                    _contentValuesVisible = false;
                  });
                },
                child: Container(color: Styles().colors!.blackTransparent06))));
  }

  Widget _buildContentValuesWidget() {
    List<Widget> sectionList = <Widget>[];
    sectionList.add(Container(color: Styles().colors!.fillColorSecondary, height: 2));
    for (WellnessContent section in WellnessContent.values) {
      if ((_selectedContent != section)) {
        sectionList.add(_buildContentItem(section));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: sectionList)));
  }

  Widget _buildContentItem(WellnessContent contentItem) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconAsset: null,
        label: _getContentLabel(contentItem),
        onTap: () => _onTapContentItem(contentItem));
  }

  void _onTapContentItem(WellnessContent contentItem) {
    Analytics().logSelect(target: _getContentLabel(contentItem));
    if (contentItem == WellnessContent.podcast) {
      _loadWellcomeResource('podcast');
    }
    else if (contentItem == WellnessContent.struggling) {
      _loadWellcomeResource('where_to_start');
    }
    else {
      _selectedContent = _lastSelectedContent = contentItem;
    }
    _changeSettingsContentValuesVisibility();
  }

  void _changeSettingsContentValuesVisibility() {
    _contentValuesVisible = !_contentValuesVisible;
    if (mounted) {
      setState(() {});
    }
  }

  PreferredSizeWidget get headerBar {
    String title = Localization().getStringEx('panel.wellness.home.header.sections.title', 'Wellness');
    if (widget.rootTabDisplay) {
      return RootHeaderBar(title: title);
    } else {
      return HeaderBar(title: title);
    }
  }

  Widget? get navigationBar {
    return widget.rootTabDisplay ? null : uiuc.TabBar();
  }

  WellnessContent? selectableContent(WellnessContent? content) =>
     ((content != WellnessContent.podcast) && (content != WellnessContent.struggling)) ? content : null;

  Widget get _contentWidget {
    switch (_selectedContent) {
      case WellnessContent.dailyTips:
        return WellnessDailyTipsContentWidget();
      case WellnessContent.rings:
        return WellnessRingsHomeContentWidget();
      case WellnessContent.todo:
        return WellnessToDoHomeContentWidget();
      case WellnessContent.resources:
        return WellnessResourcesContentWidget();
      default:
        return Container();
    }
  }

  void _loadWellcomeResource(String resourceId) {
    Map<String, dynamic>? content = JsonUtils.mapValue(Assets()['wellness.resources']) ;
    List<dynamic>? commands = (content != null) ? JsonUtils.listValue(content['commands']) : null;
    if (commands != null) {
      for (dynamic entry in commands) {
        Map<String, dynamic>? command = JsonUtils.mapValue(entry);
        if (command != null) {
          String? id = JsonUtils.stringValue(command['id']);
          if (id == resourceId) {
            _launchUrl(JsonUtils.stringValue(command['url']));
            break;
          }
        }
      }
    }
  }

  void _launchUrl(String? url) {
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else if (UrlUtils.launchInternal(url)){
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      }
      else{
        launch(url!);
      }
    }
  }

  // Utilities

  static String _getContentLabel(WellnessContent section, { String? language }) {
    switch (section) {
      case WellnessContent.dailyTips:
        return _loadContentString('panel.wellness.section.daily_tips.label', 'Wellness Daily Tips', language: language);
      case WellnessContent.rings:
        return _loadContentString('panel.wellness.section.rings.label', 'Daily Wellness Rings', language: language);
      case WellnessContent.todo:
        return _loadContentString('panel.wellness.section.todo.label', 'To-Do List');
      case WellnessContent.resources:
        return _loadContentString('panel.wellness.section.resources.label', 'Wellness Resources', language: language);
      case WellnessContent.podcast:
        return _loadContentString('panel.wellness.section.podcast.label', 'Healthy Illini Podcast', language: language);
      case WellnessContent.struggling:
        return _loadContentString('panel.wellness.section.struggling.label', 'I\'m Struggling', language: language);
    }
  }

  static String _loadContentString(String key, String defaults, {String? language}) {
    return Localization().getString(key, defaults: defaults, language: language) ?? defaults;
  }
}

// WellnessFavorite

class WellnessFavorite implements Favorite {
  final String? id;
  final String? category;
  WellnessFavorite(this.id, {this.category});

  bool operator == (o) => o is WellnessFavorite && o.id == id && o.category == category;
  int get hashCode => (id?.hashCode ?? 0) ^ (category?.hashCode ?? 0);

  static String favoriteKeyName({String? category}) => (category != null) ? "wellness.$category.widgetIds" : "wellness.widgetIds";
  @override String get favoriteKey => favoriteKeyName(category: category);
  @override String? get favoriteId => id;
}
