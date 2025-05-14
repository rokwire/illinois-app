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

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
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

enum WellnessContentType { dailyTips, rings, todo, appointments, healthScreener, resources, mentalHealth, successTeam, recreation}

class WellnessHomePanel extends StatefulWidget with AnalyticsInfo {
  static final String routeName = 'WellnessHomePanel';
  static const String notifySelectContent = "edu.illinois.rokwire.wellness.content.select";

  final bool rootTabDisplay;
  final WellnessContentType? contentType;

  WellnessHomePanel({this.contentType, this.rootTabDisplay = false});

  @override
  _WellnessHomePanelState createState() => _WellnessHomePanelState();

  @override
  AnalyticsFeature? get analyticsFeature => (state?._selectedContentType ?? contentType)?.analyticsFeature;

  static Future<void> push(BuildContext context, WellnessContentType content) =>
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(contentType: content), settings: RouteSettings(name: WellnessHomePanel.routeName)));

  static bool get hasState => (state != null);

  static _WellnessHomePanelState? get state {
    Set<NotificationsListener>? subscribers = NotificationService().subscribers(WellnessHomePanel.notifySelectContent);
    if (subscribers != null) {
      for (NotificationsListener subscriber in subscribers) {
        if ((subscriber is _WellnessHomePanelState) && subscriber.mounted) {
          return subscriber;
        }
      }
    }
    return null;
  }
}

class _WellnessHomePanelState extends State<WellnessHomePanel>
  with NotificationsListener, AutomaticKeepAliveClientMixin<WellnessHomePanel>
{
  late List<WellnessContentType> _contentTypes;
  late WellnessContentType? _selectedContentType;
  bool _contentValuesVisible = false;

  ScrollController _contentScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      WellnessHomePanel.notifySelectContent
    ]);
    _contentTypes = _buildContentTypes();
    _selectedContentType = _ensureContentType(widget.contentType, contentTypes: _contentTypes) ??
      _ensureContentType(Storage()._wellnessContentType, contentTypes: _contentTypes) ??
      (_contentTypes.isNotEmpty ? _contentTypes.first : null);
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
      List<WellnessContentType> contentTypes = _buildContentTypes();
      if (!DeepCollectionEquality().equals(_contentTypes, contentTypes)) {
        setState(() {
          _contentTypes = contentTypes;
        });
      }
    } else if (name == WellnessHomePanel.notifySelectContent) {
      WellnessContentType? contentType = (param is WellnessContentType) ? param : null;
      if (mounted && (contentType != null) && (_contentTypes.contains(contentType)) && (contentType != _selectedContentType)) {
        _onSelectedContentTypeChanged(contentType);
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
                  backgroundColor: Styles().colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                  border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                  rightIconKey: (_contentValuesVisible ? 'chevron-up' : 'chevron-down'),
                  label: _selectedContentType?.displayTitle ?? '',
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
    if (_selectedContentType == WellnessContentType.appointments || _selectedContentType == WellnessContentType.todo) {
      return Container(child: child);
    } else {
      return SingleChildScrollView(controller: _contentScrollController, child: child);
    }
  }

  Widget _buildContentValuesContainer() {
    return Visibility(
        visible: _contentValuesVisible,
        child: Positioned.fill(child: Stack(children: <Widget>[_dropdownDismissLayer, _dropdownList])));
  }

  Widget get _dropdownDismissLayer =>
    Positioned.fill(child:
      BlockSemantics( child:
        GestureDetector(onTap: () => setState(() { _contentValuesVisible = false; }), child:
        Container(color: Styles().colors.blackTransparent06)
        )
      )
    );

  Widget get _dropdownList {
    List<Widget> sectionList = <Widget>[];
    sectionList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));
    for (WellnessContentType contentType in _contentTypes) {
      sectionList.add(RibbonButton(
        backgroundColor: Styles().colors.white,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        textStyle: Styles().textStyles.getTextStyle((_selectedContentType == contentType) ? 'widget.button.title.medium.fat.secondary' : 'widget.button.title.medium.fat'),
        rightIconKey: (_selectedContentType == contentType) ? 'check-accent' : null,
        label: contentType.displayTitle,
        onTap: () => _onTapDropdownItem(contentType)
        )
      );
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: sectionList)
      )
    );
  }

  void _onTapDropdownItem(WellnessContentType contentItem) {
    Analytics().logSelect(target: contentItem.displayTitleEn);
    NotificationService().notify(WellnessHomePanel.notifySelectContent, contentItem);
    _changeSettingsContentValuesVisibility();
  }

  void _onSelectedContentTypeChanged(WellnessContentType contentItem) {
    if (mounted) {
      setState(() {
        Storage()._wellnessContentType = _selectedContentType = contentItem;
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

  static List<WellnessContentType> _buildContentTypes() {
    List<WellnessContentType>? contentTypes = [];
    List<String>? contentCodes = JsonUtils.listStringsValue(FlexUI()['wellness']);
    if (contentCodes != null) {
      for (String code in contentCodes) {
        WellnessContentType? value = WellnessContentTypeImpl.fromJsonString(code);
        if (value != null) {
          contentTypes.add(value);
        }
      }
    }
    contentTypes.sortAlphabetical();
    return contentTypes;
  }

  static WellnessContentType? _ensureContentType(WellnessContentType? contentType, { List<WellnessContentType>? contentTypes }) =>
    ((contentType != null) && (contentTypes?.contains(contentType) != false)) ? contentType : null;

  Widget get _contentWidget {
    switch (_selectedContentType) {
      case WellnessContentType.dailyTips:
        return WellnessDailyTipsContentWidget();
      case WellnessContentType.rings:
        return WellnessRingsHomeContentWidget();
      case WellnessContentType.todo:
        return WellnessToDoHomeContentWidget(analyticsFeature: AnalyticsFeature.WellnessToDo);
      case WellnessContentType.appointments:
        return WellnessAppointmentsContentWidget();
      case WellnessContentType.healthScreener:
        return WellnessHealthScreenerHomeWidget(_contentScrollController);
      case WellnessContentType.resources:
        return WellnessResourcesContentWidget();
      case WellnessContentType.recreation:
        return WellnessRecreationContentWidget();
      case WellnessContentType.mentalHealth:
        return WellnessMentalHealthContentWidget();
      case WellnessContentType.successTeam:
        return WellnessSuccessTeamContentWidget();
      default:
        return Container();
    }
  }

  bool get _healthScreenerSelected => _selectedContentType == WellnessContentType.healthScreener;

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

// WellnessContentType

extension WellnessContentTypeImpl on WellnessContentType {

  String get displayTitle => displayTitleLng();
  String get displayTitleEn => displayTitleLng('en');

  String displayTitleLng([String? language]) {
    switch (this) {
      case WellnessContentType.dailyTips: return Localization().getStringEx('panel.wellness.section.daily_tips.label', 'Today\'s Wellness Tip', language: language);
      case WellnessContentType.rings: return Localization().getStringEx('panel.wellness.section.rings.label', 'Daily Wellness Rings', language: language);
      case WellnessContentType.todo: return Localization().getStringEx('panel.wellness.section.todo.label', 'To-Do List');
      case WellnessContentType.appointments: return Localization().getStringEx('panel.wellness.section.appointments.label', 'MyMcKinley Appointments');
      case WellnessContentType.healthScreener: return Localization().getStringEx('panel.wellness.section.screener.label', 'Illinois Health Screener');
      case WellnessContentType.resources: return Localization().getStringEx('panel.wellness.section.resources.label', 'General Resources', language: language);
      case WellnessContentType.mentalHealth: return Localization().getStringEx('panel.wellness.section.mental_health.label', 'Mental Health Resources', language: language);
      case WellnessContentType.successTeam: return Localization().getStringEx('panel.wellness.section.success_team.label', 'My Primary Care Provider', language: language);
      case WellnessContentType.recreation: return Localization().getStringEx('panel.wellness.section.recreation.label', 'Campus Recreation', language: language);
    }
  }

  String get jsonString {
    switch (this) {
      case WellnessContentType.dailyTips: return 'daily_tips';
      case WellnessContentType.rings: return 'rings';
      case WellnessContentType.todo: return 'todo_list';
      case WellnessContentType.appointments: return 'appointments';
      case WellnessContentType.healthScreener: return 'health_screener';
      case WellnessContentType.resources: return 'resources';
      case WellnessContentType.mentalHealth: return 'mental_health';
      case WellnessContentType.successTeam: return 'success_team';
      case WellnessContentType.recreation: return 'recreation';
    }
  }

  static WellnessContentType? fromJsonString(String? value) {
    switch (value) {
      case 'daily_tips':      return WellnessContentType.dailyTips;
      case 'rings':           return WellnessContentType.rings;
      case 'todo_list':       return WellnessContentType.todo;
      case 'appointments':    return WellnessContentType.appointments;
      case 'health_screener': return WellnessContentType.healthScreener;
      case 'resources':       return WellnessContentType.resources;
      case 'mental_health':   return WellnessContentType.mentalHealth;
      case 'success_team':    return WellnessContentType.successTeam;
      case 'recreation':      return WellnessContentType.recreation;
      default:                return null;
    }
  }

  AnalyticsFeature? get analyticsFeature {
    switch (this) {
      case WellnessContentType.dailyTips:      return AnalyticsFeature.WellnessDailyTips;
      case WellnessContentType.rings:          return AnalyticsFeature.WellnessRings;
      case WellnessContentType.todo:           return AnalyticsFeature.WellnessToDo;
      case WellnessContentType.appointments:   return AnalyticsFeature.WellnessAppointments;
      case WellnessContentType.healthScreener: return AnalyticsFeature.WellnessHealthScreener;
      case WellnessContentType.resources:      return AnalyticsFeature.WellnessResources;
      case WellnessContentType.mentalHealth:   return AnalyticsFeature.WellnessMentalHealth;
      case WellnessContentType.successTeam:    return AnalyticsFeature.WellnessSuccessTeam;
      case WellnessContentType.recreation:     return AnalyticsFeature.WellnessRecreation;
    }
  }
}

extension _WellnessContentTypeList on List<WellnessContentType> {
  void sortAlphabetical() => sort((WellnessContentType t1, WellnessContentType t2) => t1.displayTitle.compareTo(t2.displayTitle));
}

extension _StorageWellnessExt on Storage {
  WellnessContentType? get _wellnessContentType => WellnessContentTypeImpl.fromJsonString(wellnessContentType);
  set _wellnessContentType(WellnessContentType? value) => wellnessContentType = value?.jsonString;
}
