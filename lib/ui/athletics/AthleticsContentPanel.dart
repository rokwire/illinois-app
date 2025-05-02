/*
 * Copyright 2024 Board of Trustees of the University of Illinois.
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
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/athletics/AthleticsEventsContentWidget.dart';
import 'package:illinois/ui/athletics/AthleticsGameDayContentWidget.dart';
import 'package:illinois/ui/athletics/AthleticsNewsContentWidget.dart';
import 'package:illinois/ui/athletics/AthleticsTeamsContentWidget.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum AthleticsContent { events, game_day, my_events, my_news, news, teams }

class AthleticsContentPanel extends StatefulWidget {
  static const String notifySelectContent = "edu.illinois.rokwire.athletics.content.select";
  static const String contentItemKey = "content-item";

  final AthleticsContent? content;

  final Map<String, dynamic> params = <String, dynamic>{};

  AthleticsContentPanel({this.content});

  @override
  _AthleticsContentPanelState createState() => _AthleticsContentPanelState();

  static bool get hasState {
    Set<NotificationsListener>? subscribers = NotificationService().subscribers(AthleticsContentPanel.notifySelectContent);
    if (subscribers != null) {
      for (NotificationsListener subscriber in subscribers) {
        if ((subscriber is _AthleticsContentPanelState) && subscriber.mounted) {
          return true;
        }
      }
    }
    return false;
  }
}

class _AthleticsContentPanelState extends State<AthleticsContentPanel> with AutomaticKeepAliveClientMixin<AthleticsContentPanel> implements NotificationsListener {

  static AthleticsContent? _lastSelectedContent;
  late AthleticsContent _selectedContent;
  List<AthleticsContent>? _contentValues;
  bool _contentValuesVisible = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [FlexUI.notifyChanged, AthleticsContentPanel.notifySelectContent]);
    _buildContentValues();
    _selectedContent = _ensureContent(_initialContentItem) ?? (_lastSelectedContent ?? AthleticsContent.events);
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _buildContentValues();
    } else if (name == AthleticsContentPanel.notifySelectContent) {
      AthleticsContent? contentItem = (param is AthleticsContent) ? param : null;
      if (mounted && (contentItem != null) && (contentItem != _selectedContent)) {
        _onContentItemChanged(contentItem);
      }
    }
  }

  // AutomaticKeepAliveClientMixin

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
        appBar: _headerBar,
        body: Column(children: <Widget>[
          Container(
              color: Styles().colors.fillColorPrimary,
              padding: EdgeInsets.all(16),
              child: Semantics(
                  hint: Localization().getStringEx("dropdown.hint", "DropDown"),
                  container: true,
                  child: RibbonButton(
                      textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"),
                      backgroundColor: Styles().colors.surface,
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                      rightIconKey: (_contentValuesVisible ? 'icon-up-orange' : 'icon-down-orange'),
                      label: _getContentLabel(_selectedContent),
                      onTap: _changeSettingsContentValuesVisibility))),
          Expanded(
              child: Stack(children: [
                Container(child: _contentWidget),
            _buildContentValuesContainer()
          ]))
        ]),
        backgroundColor: Styles().colors.background,
        bottomNavigationBar: uiuc.TabBar());
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
                child: Container(color: Styles().colors.blackTransparent06))));
  }

  Widget _buildContentValuesWidget() {
    List<Widget> sectionList = <Widget>[];
    sectionList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));

    if (CollectionUtils.isNotEmpty(_contentValues)) {
      for (AthleticsContent content in _contentValues!) {
        if (_selectedContent != content) {
          sectionList.add(_buildContentItem(content));
        }
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: sectionList)));
  }

  Widget _buildContentItem(AthleticsContent contentItem) {
    return RibbonButton(
        backgroundColor: Styles().colors.surface,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        rightIconKey: null,
        label: _getContentLabel(contentItem),
        onTap: () => _onTapContentItem(contentItem));
  }

  void _buildContentValues() {
    List<String>? contentCodes = JsonUtils.listStringsValue(FlexUI()['browse.athletics']);
    List<AthleticsContent>? contentValues;
    if (contentCodes != null) {
      contentValues = [];
      for (String code in contentCodes) {
        AthleticsContent? value = _getContentValueFromCode(code);
        if (value != null) {
          contentValues.add(value);
        }
      }
    }

    setStateIfMounted(() {
      _contentValues = contentValues;
    });
  }

  void _onTapContentItem(AthleticsContent contentItem) {
    Analytics().logSelect(target: _getContentLabel(contentItem));
    _changeSettingsContentValuesVisibility();
    NotificationService().notify(AthleticsContentPanel.notifySelectContent, contentItem);
  }

  void _onContentItemChanged(AthleticsContent contentItem) {
    setStateIfMounted(() {
      _selectedContent = _lastSelectedContent = contentItem;
    });
  }

  void _changeSettingsContentValuesVisibility() {
    setStateIfMounted(() {
      _contentValuesVisible = !_contentValuesVisible;
    });
  }

  AthleticsContent? _getContentValueFromCode(String? code) {
    switch (code) {
      case 'my_athletics':
        return AthleticsContent.my_events;
      case 'my_game_day':
        return AthleticsContent.game_day;
      case 'my_news':
        return AthleticsContent.my_news;
      case 'sport_events':
        return AthleticsContent.events;
      case 'sport_news':
        return AthleticsContent.news;
      case 'sport_teams':
        return AthleticsContent.teams;
      default:
        return null;
    }
  }

  PreferredSizeWidget get _headerBar {
    String title = Localization().getStringEx('panel.athletics.content.home.title.label', 'Athletics');
    return RootHeaderBar(leading: RootHeaderBarLeading.Back, title: title);
  }

  AthleticsContent? _ensureContent(AthleticsContent? contentItem, {List<AthleticsContent>? contentItems}) {
    contentItems ??= _contentValues;
    return ((contentItem != null) && contentItems!.contains(contentItem)) ? contentItem : null;
  }

  AthleticsContent? get _initialContentItem => widget.params[AthleticsContentPanel.contentItemKey] ?? widget.content;

  Widget get _contentWidget {
    switch (_selectedContent) {
      case AthleticsContent.events:
        return AthleticsEventsContentWidget();
      case AthleticsContent.my_events:
        return AthleticsEventsContentWidget(showFavorites: true);
      case AthleticsContent.news:
        return AthleticsNewsContentWidget();
      case AthleticsContent.my_news:
        return AthleticsNewsContentWidget(showFavorites: true);
      case AthleticsContent.game_day:
        return AthleticsGameDayContentWidget();
      case AthleticsContent.teams:
        return AthleticsTeamsContentWidget();
      default:
        return Container();
    }
  }

  // Utilities

  static String _getContentLabel(AthleticsContent section, { String? language }) {
    switch (section) {
      case AthleticsContent.events:
        return _loadContentString('panel.athletics.content.section.events.label', 'Big 10 Events', language: language);
      case AthleticsContent.game_day:
        return _loadContentString('panel.athletics.content.section.game_day.label', "It's Game Day!", language: language);
      case AthleticsContent.my_events:
        return _loadContentString('panel.athletics.content.section.my_events.label', 'My Big 10 Events', language: language);
      case AthleticsContent.my_news:
        return _loadContentString('panel.athletics.content.section.my_news.label', 'My News', language: language);
      case AthleticsContent.news:
        return _loadContentString('panel.athletics.content.section.news.label', 'Big 10 News', language: language);
      case AthleticsContent.teams:
        return _loadContentString('panel.athletics.content.section.teams.label', 'Big 10 Teams', language: language);
    }
  }

  static String _loadContentString(String key, String defaults, {String? language}) {
    return Localization().getString(key, defaults: defaults, language: language) ?? defaults;
  }
}