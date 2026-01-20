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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
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

enum AthleticsContentType { events, news, teams, game_day }

class AthleticsHomePanel extends StatefulWidget {
  static const String notifySelectContent = "edu.illinois.rokwire.athletics.content.select";
  static const String contentItemKey = "content-item";

  final AthleticsContentType? contentType;
  final bool? starred;

  AthleticsHomePanel({this.contentType, this.starred});

  @override
  _AthleticsHomePanelState createState() => _AthleticsHomePanelState();

  static bool get hasState => (state != null);

  static _AthleticsHomePanelState? get state {
    Set<NotificationsListener>? subscribers = NotificationService().subscribers(AthleticsHomePanel.notifySelectContent);
    if (subscribers != null) {
      for (NotificationsListener subscriber in subscribers) {
        if ((subscriber is _AthleticsHomePanelState) && subscriber.mounted) {
          return subscriber;
        }
      }
    }
    return null;
  }
}

class _AthleticsHomePanelState extends State<AthleticsHomePanel>
  with NotificationsListener, AutomaticKeepAliveClientMixin<AthleticsHomePanel> {

  static AthleticsContentType _defaultContentType = AthleticsContentType.events;

  late List<AthleticsContentType> _contentTypes;
  AthleticsContentType? _selectedContentType;
  bool _contentValuesVisible = false;
  bool? _starred;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      AthleticsHomePanel.notifySelectContent
    ]);

    _contentTypes = _buildContentTypes();
    _selectedContentType = widget.contentType?._ensure(availableTypes: _contentTypes) ??
        Storage()._athleticsContentType?._ensure(availableTypes: _contentTypes) ??
        _defaultContentType._ensure(availableTypes: _contentTypes) ??
        (_contentTypes.isNotEmpty ? _contentTypes.first : null);
    _starred = widget.starred;
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
      _updateContentValues();
    } else if (name == AthleticsHomePanel.notifySelectContent) {
      AthleticsContentType? contentItem = (param is AthleticsContentType) ? param : null;
      if (mounted && (contentItem != null) && (contentItem != _selectedContentType)) {
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
                      backgroundColor: Styles().colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                      rightIconKey: (_contentValuesVisible ? 'chevron-up' : 'chevron-down'),
                      title: _selectedContentType?.displayTitle ?? '',
                      onTap: _onTapRibbonButton))),
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
    return Visibility(visible: _contentValuesVisible, child:
      Positioned.fill(child:
        Stack(children: <Widget>[
          _buildContentDismissLayer(),
          _buildContentValuesWidget()
        ])
      )
    );
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
    for (AthleticsContentType contentType in _contentTypes) {
      sectionList.add(RibbonButton(
        backgroundColor: Styles().colors.white,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        textStyle: Styles().textStyles.getTextStyle((_selectedContentType == contentType) ? 'widget.button.title.medium.fat.secondary' : 'widget.button.title.medium.fat'),
        rightIconKey: (_selectedContentType == contentType) ? 'check-accent' : null,
        title: contentType.displayTitle,
        onTap: () => _onTapContentItem(contentType)
      ));
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: sectionList)));
  }

  void _onTapContentItem(AthleticsContentType contentItem) {
    Analytics().logSelect(target: contentItem.displayTitleEn);
    _changeSettingsContentValuesVisibility();
    NotificationService().notify(AthleticsHomePanel.notifySelectContent, contentItem);
  }

  void _onContentItemChanged(AthleticsContentType contentItem) {
    setStateIfMounted(() {
      Storage()._athleticsContentType = _selectedContentType = contentItem;
      _starred = null;
    });
  }

  void _onTapRibbonButton() {
    Analytics().logSelect(target: 'Toggle Dropdown');
    _changeSettingsContentValuesVisibility();
  }

  void _changeSettingsContentValuesVisibility() {
    setStateIfMounted(() {
      _contentValuesVisible = !_contentValuesVisible;
    });
  }

  void _updateContentValues() {
    List<AthleticsContentType> contentValues = _buildContentTypes();
    if (!DeepCollectionEquality().equals(_contentTypes, contentValues)) {
      setStateIfMounted(() {
        _contentTypes = contentValues;
      });
    }
  }

  static List<AthleticsContentType> _buildContentTypes() {
    List<AthleticsContentType>? contentTypes = List<AthleticsContentType>.from(AthleticsContentType.values);
    contentTypes.sortAlphabetical();
    return contentTypes;
  }

  PreferredSizeWidget get _headerBar {
    String title = Localization().getStringEx('panel.athletics.content.home.title.label', 'Athletics');
    return RootHeaderBar(leading: RootHeaderBarLeading.Back, title: title);
  }

  Widget? get _contentWidget {
    switch (_selectedContentType) {
      case AthleticsContentType.events: return AthleticsEventsContentWidget(starred: _starred,);
      case AthleticsContentType.news: return AthleticsNewsContentWidget(starred: _starred,);
      case AthleticsContentType.teams: return AthleticsTeamsContentWidget();
      case AthleticsContentType.game_day: return AthleticsGameDayContentWidget();
      default: return null;
    }
  }

}

// AthleticsContentType

extension AthleticsContentTypeImpl on AthleticsContentType {

  String get displayTitle => displayTitleLng();
  String get displayTitleEn => displayTitleLng('en');

  String displayTitleLng([String? language]) {
    switch (this) {
      case AthleticsContentType.events: return Localization().getStringEx('panel.athletics.content.section.events.label', 'Big 10 Events', language: language);
      case AthleticsContentType.news: return Localization().getStringEx('panel.athletics.content.section.news.label', 'Big 10 News', language: language);
      case AthleticsContentType.teams: return Localization().getStringEx('panel.athletics.content.section.teams.label', 'Big 10 Teams', language: language);
      case AthleticsContentType.game_day: return Localization().getStringEx('panel.athletics.content.section.game_day.label', "It's Game Day!", language: language);
    }
  }

  String get jsonString {
    switch (this) {
      case AthleticsContentType.events: return 'sport_events';
      case AthleticsContentType.news: return 'sport_news';
      case AthleticsContentType.teams: return 'sport_teams';
      case AthleticsContentType.game_day: return 'my_game_day';
    }
  }

  static AthleticsContentType? fromJsonString(String? value) {
    switch (value) {
      case 'sport_events': return AthleticsContentType.events;
      case 'sport_news': return AthleticsContentType.news;
      case 'sport_teams': return AthleticsContentType.teams;
      case 'my_game_day': return AthleticsContentType.game_day;
      default: return null;
    }
  }

  AthleticsContentType? _ensure({List<AthleticsContentType>? availableTypes}) =>
      (availableTypes?.contains(this) != false) ? this : null;
}

extension _AthleticsContentTypeList on List<AthleticsContentType> {
  void sortAlphabetical() => sort((AthleticsContentType t1, AthleticsContentType t2) => t1.displayTitle.compareTo(t2.displayTitle));
}

extension _StorageWellnessExt on Storage {
  AthleticsContentType? get _athleticsContentType => AthleticsContentTypeImpl.fromJsonString(athleticsContentType);
  set _athleticsContentType(AthleticsContentType? value) => athleticsContentType = value?.jsonString;
}
