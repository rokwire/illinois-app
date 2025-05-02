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
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/wellness/WellnessHealthScreenerWidgets.dart';
import 'package:illinois/ui/wellness/WellnessMentalHealthContentWidget.dart';
import 'package:illinois/ui/wellness/WellnessRecreationContentWidget.dart';
import 'package:illinois/ui/wellness/WellnessSuccessTeamContentWidget.dart';
import 'package:illinois/ui/wellness/WellnessResourcesContentWidget.dart';
import 'package:illinois/ui/wellness/WellnessAppointmentsContentWidget.dart';
import 'package:illinois/ui/wellness/rings/WellnessRingsHomeContentWidget.dart';
import 'package:illinois/ui/wellness/WellnessDailyTipsContentWidget.dart';
import 'package:illinois/ui/wellness/todo/WellnessToDoHomeContentWidget.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum WellnessContent { dailyTips, rings, todo, appointments, healthScreener, resources, mentalHealth, successTeam, recreation}

class WellnessHomePanel extends StatefulWidget with AnalyticsInfo {
  static final String routeName = 'AcademicsHomePanel';
  static const String notifySelectContent = "edu.illinois.rokwire.wellness.content.select";

  final WellnessContent? content;
  final bool rootTabDisplay;

  static Map<WellnessContent, AnalyticsFeature> contentAnalyticsFeatures = {
    WellnessContent.dailyTips:      AnalyticsFeature.WellnessDailyTips,
    WellnessContent.rings:          AnalyticsFeature.WellnessRings,
    WellnessContent.todo:           AnalyticsFeature.WellnessToDo,
    WellnessContent.appointments:   AnalyticsFeature.WellnessAppointments,
    WellnessContent.healthScreener: AnalyticsFeature.WellnessHealthScreener,
    WellnessContent.resources:      AnalyticsFeature.WellnessResources,
    WellnessContent.mentalHealth:   AnalyticsFeature.WellnessMentalHealth,
    WellnessContent.successTeam:    AnalyticsFeature.WellnessSuccessTeam,
    WellnessContent.recreation:     AnalyticsFeature.WellnessRecreation,
  };

  WellnessHomePanel({this.content, this.rootTabDisplay = false});

  @override
  _WellnessHomePanelState createState() => _WellnessHomePanelState();

  @override
  AnalyticsFeature? get analyticsFeature => contentAnalyticsFeatures[content];

  static Future<void> push(BuildContext context, WellnessContent content) =>
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(content: content), settings: RouteSettings(name: WellnessHomePanel.routeName)));

  static bool get hasState {
    Set<NotificationsListener>? subscribers = NotificationService().subscribers(WellnessHomePanel.notifySelectContent);
    if (subscribers != null) {
      for (NotificationsListener subscriber in subscribers) {
        if ((subscriber is _WellnessHomePanelState) && subscriber.mounted) {
          return true;
        }
      }
    }
    return false;
  }
}

class _WellnessHomePanelState extends State<WellnessHomePanel>
  with AutomaticKeepAliveClientMixin<WellnessHomePanel>
  implements NotificationsListener
{
  static WellnessContent? _lastSelectedContent;
  late WellnessContent _selectedContent;
  List<WellnessContent>? _contentValues;
  bool _contentValuesVisible = false;

  ScrollController _contentScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [FlexUI.notifyChanged, WellnessHomePanel.notifySelectContent]);
    _buildContentValues();
    _selectedContent = _ensureContent(widget.content) ?? _ensureContent(_lastSelectedContent) ?? WellnessContent.dailyTips;
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
    } else if (name == WellnessHomePanel.notifySelectContent) {
      WellnessContent? contentItem = (param is WellnessContent) ? param : null;
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
            color: _healthScreenerSelected ? Styles().colors.fillColorPrimaryVariant : Styles().colors.background,
            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
            child: Semantics(
              hint:  Localization().getStringEx("dropdown.hint", "DropDown"),
              container: true,
              child: RibbonButton(
                  textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"),
                  backgroundColor: Styles().colors.surface,
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                  border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                  rightIconKey: (_contentValuesVisible ? 'chevron-up' : 'chevron-down'),
                  label: _getContentLabel(_selectedContent),
                  onTap: _changeSettingsContentValuesVisibility
              ),
            ),
          ),
          Expanded(
              child: Stack(children: [
            Padding(
                padding: EdgeInsets.only(top: _healthScreenerSelected ? 0 : 16.0),
                child: _buildScrollableContentWidget(
                    child: Padding(padding: EdgeInsets.only(bottom: 16), child: _contentWidget))),
            _buildContentValuesContainer()
          ]))
        ]),
        backgroundColor: Styles().colors.background,
        bottomNavigationBar: _navigationBar);
  }

  Widget _buildScrollableContentWidget({required Widget child}) {
    if (_selectedContent == WellnessContent.appointments || _selectedContent == WellnessContent.todo) {
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
                child: Container(color: Styles().colors.blackTransparent06))));
  }

  Widget _buildContentValuesWidget() {
    List<Widget> sectionList = <Widget>[];
    sectionList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));

    if (CollectionUtils.isNotEmpty(_contentValues)) {
      for (WellnessContent content in _contentValues!) {
        if (_selectedContent != content) {
          sectionList.add(_buildContentItem(content));
        }
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: sectionList)));
  }

  Widget _buildContentItem(WellnessContent contentItem) {
    return RibbonButton(
        backgroundColor: Styles().colors.surface,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        rightIconKey: null,
        label: _getContentLabel(contentItem),
        onTap: () => _onTapContentItem(contentItem));
  }

  void _buildContentValues() {
    List<String>? contentCodes = JsonUtils.listStringsValue(FlexUI()['wellness']);
    List<WellnessContent>? contentValues;
    if (contentCodes != null) {
      contentValues = [];
      for (String code in contentCodes) {
        WellnessContent? value = WellnessContentImpl.fromString(code);
        if (value != null) {
          contentValues.add(value);
        }
      }
    }

    _contentValues = contentValues;
    setStateIfMounted(() { });
  }

  void _onTapContentItem(WellnessContent contentItem) {
    Analytics().logSelect(target: _getContentLabel(contentItem));
    _changeSettingsContentValuesVisibility();
    NotificationService().notify(WellnessHomePanel.notifySelectContent, contentItem);
  }

  void _onContentItemChanged(WellnessContent contentItem) {
    if (mounted) {
      setState(() {
        _selectedContent = _lastSelectedContent = contentItem;
      });
      Analytics().logPageWidget(_contentWidget);
    }
  }

  void _changeSettingsContentValuesVisibility() {
    _contentValuesVisible = !_contentValuesVisible;
    setStateIfMounted(() { });
  }

  PreferredSizeWidget get _headerBar {
    String title = Localization().getStringEx('panel.wellness.home.header.sections.title', 'Health & Wellness');
    if (widget.rootTabDisplay) {
      return RootHeaderBar(title: title);
    } else {
      return HeaderBar(title: title);
    }
  }

  Widget? get _navigationBar {
    return widget.rootTabDisplay ? null : uiuc.TabBar();
  }

  WellnessContent? _ensureContent(WellnessContent? contentItem, {List<WellnessContent>? contentItems}) {
    contentItems ??= _contentValues;
    return ((contentItem != null) && contentItems!.contains(contentItem)) ? contentItem : null;
  }

  Widget get _contentWidget {
    switch (_selectedContent) {
      case WellnessContent.dailyTips:
        return WellnessDailyTipsContentWidget();
      case WellnessContent.rings:
        return WellnessRingsHomeContentWidget();
      case WellnessContent.todo:
        return WellnessToDoHomeContentWidget(analyticsFeature: AnalyticsFeature.WellnessToDo);
      case WellnessContent.appointments:
        return WellnessAppointmentsContentWidget();
      case WellnessContent.healthScreener:
        return WellnessHealthScreenerHomeWidget(_contentScrollController);
      case WellnessContent.resources:
        return WellnessResourcesContentWidget();
      case WellnessContent.recreation:
        return WellnessRecreationContentWidget();
      case WellnessContent.mentalHealth:
        return WellnessMentalHealthContentWidget();
      case WellnessContent.successTeam:
        return WellnessSuccessTeamContentWidget();
      default:
        return Container();
    }
  }

  bool get _healthScreenerSelected => _selectedContent == WellnessContent.healthScreener;

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
        return _loadContentString('panel.wellness.section.resources.label', 'General Resources', language: language);
      case WellnessContent.mentalHealth:
        return _loadContentString('panel.wellness.section.mental_health.label', 'Mental Health Resources', language: language);
      case WellnessContent.successTeam:
        return _loadContentString('panel.wellness.section.success_team.label', 'My Success Team', language: language);
      case WellnessContent.recreation:
        return _loadContentString('panel.wellness.section.recreation.label', 'Campus Recreation', language: language); //TBD localize
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

// WellnessContentImpl

extension WellnessContentImpl on WellnessContent {
  static WellnessContent? fromString(String? value) {
    switch (value) {
      case 'recreation':      return WellnessContent.recreation;
      case 'daily_tips':      return WellnessContent.dailyTips;
      case 'rings':           return WellnessContent.rings;
      case 'todo_list':       return WellnessContent.todo;
      case 'appointments':    return WellnessContent.appointments;
      case 'health_screener': return WellnessContent.healthScreener;
      case 'resources':       return WellnessContent.resources;
      case 'mental_health':   return WellnessContent.mentalHealth;
      case 'success_team':    return WellnessContent.successTeam;
      default:                return null;
    }
  }
}
