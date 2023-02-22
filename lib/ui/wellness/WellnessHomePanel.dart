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
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:illinois/ui/wellness/WellnessHealthScreenerWidgets.dart';
import 'package:illinois/ui/wellness/WellnessResourcesContentWidget.dart';
import 'package:illinois/ui/wellness/appointments/WellnessAppointmentsHomeContentWidget.dart';
import 'package:illinois/ui/wellness/rings/WellnessRingsHomeContentWidget.dart';
import 'package:illinois/ui/wellness/WellnessDailyTipsContentWidget.dart';
import 'package:illinois/ui/wellness/todo/WellnessToDoHomeContentWidget.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum WellnessContent { dailyTips, rings, todo, appointments, healthScreener, podcast, resources, struggling }

class WellnessHomePanel extends StatefulWidget {
  final WellnessContent? content;
  final bool rootTabDisplay;

  WellnessHomePanel({this.content, this.rootTabDisplay = false});

  @override
  _WellnessHomePanelState createState() => _WellnessHomePanelState();
}

class _WellnessHomePanelState extends State<WellnessHomePanel>
  with AutomaticKeepAliveClientMixin<WellnessHomePanel>
  implements NotificationsListener
{
  static WellnessContent? _lastSelectedContent;
  late WellnessContent _selectedContent;
  bool _contentValuesVisible = false;

  UniqueKey _podcastKey = UniqueKey();
  UniqueKey _strugglingKey = UniqueKey();
  ScrollController _contentScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [FlexUI.notifyChanged]);
    _selectedContent = _selectableContent(widget.content) ?? (_lastSelectedContent ?? WellnessContent.dailyTips);
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
      setStateIfMounted((){});
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
          Padding(
              padding: EdgeInsets.only(left: 16, top: 16, right: 16),
              child: Semantics(
                  hint: Localization().getStringEx("dropdown.hint", "DropDown"),
                  container: true,
                  child: RibbonButton(
                    textColor: Styles().colors!.fillColorSecondary,
                    backgroundColor: Styles().colors!.white,
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
                    rightIconAsset: (_contentValuesVisible ? 'images/icon-up.png' : 'images/icon-down-orange.png'),
                    label: _getContentLabel(_selectedContent),
                    onTap: _changeSettingsContentValuesVisibility))),
          Expanded(
              child: Stack(children: [
            Padding(
                padding: EdgeInsets.only(top: 16),
                child: _buildScrollableContentWidget(
                    child: Padding(padding: EdgeInsets.only(bottom: 16), child: _contentWidget))),
            _buildContentValuesContainer()
          ]))
        ]),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: _navigationBar);
  }

  Widget _buildScrollableContentWidget({required Widget child}) {
    if (_selectedContent == WellnessContent.appointments) {
      return Container(child: child);
    } else {
      return SingleChildScrollView(controller: _contentScrollController, child: child);
    }
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

    List<String>? contentCodes = JsonUtils.listStringsValue(FlexUI()['wellness']);
    if (contentCodes != null) {
      for (String contentCode in contentCodes) {
        WellnessContent? section = _getContentValueFromCode(contentCode);
        if ((section != null) && (_selectedContent != section)) {
          sectionList.add(_buildContentItem(section));
        }
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
    _selectedContent = _lastSelectedContent = contentItem;
    _changeSettingsContentValuesVisibility();
  }

  void _changeSettingsContentValuesVisibility() {
    _contentValuesVisible = !_contentValuesVisible;
    if (mounted) {
      setState(() {});
    }
  }

  WellnessContent? _getContentValueFromCode(String? code) {
    if (code == 'daily_tips') {
      return WellnessContent.dailyTips;
    } else if (code == 'rings') {
      return WellnessContent.rings;
    } else if (code == 'todo_list') {
      return WellnessContent.todo;
    } else if (code == 'appointments') {
      return WellnessContent.appointments;
    } else if (code == 'health_screener') {
      return WellnessContent.healthScreener;
    } else if (code == 'podcast') {
      return WellnessContent.podcast;
    } else if (code == 'resources') {
      return WellnessContent.resources;
    } else if (code == 'struggling') {
      return WellnessContent.struggling;
    } else {
      return null;
    }
  }

  PreferredSizeWidget get _headerBar {
    String title = Localization().getStringEx('panel.wellness.home.header.sections.title', 'Wellness');
    if (widget.rootTabDisplay) {
      return RootHeaderBar(title: title);
    } else {
      return HeaderBar(title: title);
    }
  }

  Widget? get _navigationBar {
    return widget.rootTabDisplay ? null : uiuc.TabBar();
  }

  WellnessContent? _selectableContent(WellnessContent? content) =>
     ((content != WellnessContent.podcast) && (content != WellnessContent.struggling)) ? content : null;

  Widget get _contentWidget {
    switch (_selectedContent) {
      case WellnessContent.dailyTips:
        return WellnessDailyTipsContentWidget();
      case WellnessContent.rings:
        return WellnessRingsHomeContentWidget();
      case WellnessContent.todo:
        return WellnessToDoHomeContentWidget();
      case WellnessContent.appointments:
        return WellnessAppointmentsHomeContentWidget();
      case WellnessContent.healthScreener:
        return WellnessHealthScreenerHomeWidget(_contentScrollController);
      case WellnessContent.podcast:
        return GuideDetailWidget(key: _podcastKey, guideEntryId: _loadWellcomeResourceGuideId('podcast'), headingColor: Styles().colors?.background);
      case WellnessContent.resources:
        return WellnessResourcesContentWidget();
      case WellnessContent.struggling:
        return GuideDetailWidget(key: _strugglingKey, guideEntryId: _loadWellcomeResourceGuideId('where_to_start'), headingColor: Styles().colors?.background);
      default:
        return Container();
    }
  }

  String? _loadWellcomeResourceGuideId(String resourceId) {
    Map<String, dynamic>? content = JsonUtils.mapValue(Assets()['wellness.resources']) ;
    List<dynamic>? commands = (content != null) ? JsonUtils.listValue(content['commands']) : null;
    if (commands != null) {
      for (dynamic entry in commands) {
        Map<String, dynamic>? command = JsonUtils.mapValue(entry);
        if (command != null) {
          String? id = JsonUtils.stringValue(command['id']);
          if (id == resourceId) {
            String? url = JsonUtils.stringValue(command['url']);
            Uri? uri = (url != null) ? Uri.tryParse(url) : null;
            return Guide().detailIdFromUri(uri);
          }
        }
      }
    }
    return null;
  }

  // Utilities
  static String _getContentLabel(WellnessContent section, { String? language }) {
    switch (section) {
      case WellnessContent.dailyTips:
        return _loadContentString('panel.wellness.section.daily_tips.label', 'Today\'s Wellness Tip', language: language);
      case WellnessContent.rings:
        return _loadContentString('panel.wellness.section.rings.label', 'Daily Wellness Rings', language: language);
      case WellnessContent.todo:
        return _loadContentString('panel.wellness.section.todo.label', 'To-Do List');
      case WellnessContent.appointments:
        return _loadContentString('panel.wellness.section.appointments.label', 'MyMcKinley Appointments');
      case WellnessContent.healthScreener:
        return _loadContentString('panel.wellness.section.screener.label', 'Illinois Health Screener');
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

class WellnessFavorite extends Favorite {
  final String? id;
  final String? category;
  WellnessFavorite(this.id, {this.category});

  bool operator == (o) => o is WellnessFavorite && o.id == id && o.category == category;
  int get hashCode => (id?.hashCode ?? 0) ^ (category?.hashCode ?? 0);

  static String favoriteKeyName({String? category}) => (category != null) ? "wellness.$category.widgetIds" : "wellness.widgetIds";
  @override String get favoriteKey => favoriteKeyName(category: category);
  @override String? get favoriteId => id;
}
