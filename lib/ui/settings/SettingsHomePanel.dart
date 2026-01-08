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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/athletics/AthleticsTeamsWidget.dart';
import 'package:illinois/ui/home/HomeCustomizeFavoritesPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/settings/SettingsAccessibilityPage.dart';
import 'package:illinois/ui/settings/SettingsAppointmentsAndEventsPage.dart';
import 'package:illinois/ui/settings/SettingsAssessmentsPage.dart';
import 'package:illinois/ui/settings/SettingsAboutPage.dart';
import 'package:illinois/ui/settings/SettingsFoodFiltersPage.dart';
import 'package:illinois/ui/settings/SettingsLanguagePage.dart';
import 'package:illinois/ui/settings/SettingsNotificationPreferencesPage.dart';
import 'package:illinois/ui/settings/SettingsPrivacyCenterPage.dart';
import 'package:illinois/ui/settings/SettingsRecentItemsPage.dart';
import 'package:illinois/ui/settings/SettingsResearchPage.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/debug/DebugHomePanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum SettingsContentType { food_filters, sports, favorites, assessments, recent_items, appointments_and_events, language, about, research, privacy, notifications, accessibility }

class SettingsHomePanel extends StatefulWidget with AnalyticsInfo {
  static final String routeName = 'settings_home_content_panel';

  static final SettingsContentType _defaultContentType = SettingsContentType.about;

  final SettingsContentType? contentType;

  SettingsHomePanel._({this.contentType});

  @override
  _SettingsHomePanelState createState() => _SettingsHomePanelState();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.Settings;

  static Future<void> present(BuildContext context, { SettingsContentType? content}) async {
    if (ModalRoute.of(context)?.settings.name != routeName) {
      MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
      double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 16;
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        useRootNavigator: true,
        routeSettings: RouteSettings(name: routeName),
        clipBehavior: Clip.antiAlias,
        backgroundColor: Styles().colors.background,
        constraints: BoxConstraints(maxHeight: height, minHeight: height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (context) {
          return SettingsHomePanel._(contentType: content);
        }
      );
      /*Navigator.push(context, PageRouteBuilder(
        settings: RouteSettings(name: routeName),
        pageBuilder: (context, animation1, animation2) => SettingsHomeContentPanel._(content: content),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero
      ));*/
    }
  }
}

class _SettingsHomePanelState extends State<SettingsHomePanel> with NotificationsListener {
  final GlobalKey _innerContentKey = GlobalKey();
  late List<SettingsContentType> _contentTypes;
  late SettingsContentType? _selectedContentType;
  bool _contentValuesVisible = false;

  final FocusNode _dropdownFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Localization.notifyLocaleChanged,
      FlexUI.notifyChanged,
    ]);
    _contentTypes = _SettingsContentTypeList.fromFlexUi();

    _selectedContentType = widget.contentType ?? // Some content types are not available in dropdown list.
      Storage()._settingsContentType?._ensure(availableTypes: _contentTypes) ??
      SettingsHomePanel._defaultContentType._ensure(availableTypes: _contentTypes) ??
      (_contentTypes.isNotEmpty ? _contentTypes.first : null);
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == Localization.notifyLocaleChanged) {
      setStateIfMounted(() {});
    }
    else if (name == FlexUI.notifyChanged) {
      _updateContentTypesIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    //return _buildScaffold(context);
    return _buildSheet(context);
  }

  /*Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: _DebugContainer(child:
        RootHeaderBar(title: Localization().getStringEx('panel.settings.home.header.settings.label', 'Settings'), onSettings: _onTapDebug,),
      ),
      body: _buildPage(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar()
    );
  }*/

  Widget _buildSheet(BuildContext context) {
    // MediaQuery(data: MediaQueryData.fromWindow(WidgetsBinding.instance.window), child: SafeArea(bottom: false, child: ))
    return Column(children: [
        Container(color: Styles().colors.white, child:
          Row(children: [
            Expanded(child:
              _DebugContainer(child:
                Padding(padding: EdgeInsets.only(left: 16), child:
                  Text(Localization().getStringEx('panel.settings.home.header.settings.label', 'Settings'), style: Styles().textStyles.getTextStyle("widget.sheet.title.regular"))
                )
              ),
            ),
            Visibility(visible: (kDebugMode || (Config().configEnvironment == ConfigEnvironment.dev)), child:
              Semantics(label: "debug", child:
                InkWell(onTap : _onTapDebug, child:
                  Container(padding: EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 16), child:
                    Styles().images.getImage('bug', excludeFromSemantics: true),
                  ),
                ),
              )
            ),
            Semantics( label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), inMutuallyExclusiveGroup: true, button: true, child:
              InkWell(onTap : _onTapClose, child:
                Container(padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16), child:
                  Styles().images.getImage('close-circle', excludeFromSemantics: true),
                ),
              ),
            ),

          ],),
        ),
        Container(color: Styles().colors.surfaceAccent, height: 1,),
        Expanded(child:
          _buildPage(context),
        )
      ],);
  }

  Widget _buildPage(BuildContext context) {
    return Column(children: <Widget>[
      Expanded(child:
        Container(color: Styles().colors.background, child:
          SingleChildScrollView(physics: (_contentValuesVisible ? NeverScrollableScrollPhysics() : null), child:
            Container(color: Styles().colors.background, child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: EdgeInsets.only(left: 16, top: 16, right: 16), child:
                  WebFocusableSemanticsWidget(onSelect: _onTapContentDropdown, child: Semantics(hint: Localization().getStringEx("dropdown.hint", "DropDown"), label: _selectedContentType?.displayTitle ?? '', button: true, child:
                    RibbonButton(
                      textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"),
                      backgroundColor: Styles().colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                      rightIconKey: (_contentValuesVisible ? 'chevron-up' : 'chevron-down'),
                      title: _selectedContentType?.displayTitle ?? '',
                      onTap: _onTapContentDropdown
                    )
                  ))
                ),
                _buildContent()
              ]),
            ),
          ),
        )
      ),
    ]);
  }

  Widget _buildContent() {
    return Stack(key: _innerContentKey, children: [
      Padding(padding: EdgeInsets.all(16), child:
        _contentWidget ?? Container()
      ),
      _buildContentValuesContainer()
    ]);
  }

  Widget _buildContentValuesContainer() {
    return Visibility(visible: _contentValuesVisible, child:
        Focus(focusNode: _dropdownFocusNode, canRequestFocus: true, child:
          Semantics(container: true, liveRegion: true, explicitChildNodes: true, child:
            Container /* Positioned.fill*/ (child:
              Stack(children: <Widget>[
                _dropdownDismissLayer,
                Positioned.fill(child: _dropdownList),
        ])))));
  }

  Widget get _dropdownDismissLayer =>
    BlockSemantics( child:
      Semantics(excludeSemantics: true, child:
        GestureDetector(onTap: () => setState(() { _contentValuesVisible = false;}), child:
          Container(color: Styles().colors.blackTransparent06, height: _innserContentHeight,)
        )
      )
    );

  double get _innserContentHeight {
    final screenHeight = MediaQuery.of(context).size.height;
    final RenderObject? renderObj = _innerContentKey.currentContext?.findRenderObject();
    final RenderBox? renderBox = (renderObj is RenderBox) ? renderObj : null;
    Offset? position = renderBox?.localToGlobal(Offset.zero);
    return (position != null) ? (screenHeight - position.dy) : screenHeight;
  }

  Widget get _dropdownList {
    List<Widget> sectionList = <Widget>[];
    sectionList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));
    for (SettingsContentType contentType in _contentTypes) {
      sectionList.add(WebFocusableSemanticsWidget(onSelect:() => _onTapDropdownItem(contentType), child: Semantics(button: true, label: contentType.displayTitle, child:
        RibbonButton(
          backgroundColor: Styles().colors.white,
          border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
          textStyle: Styles().textStyles.getTextStyle((_selectedContentType == contentType) ? 'widget.button.title.medium.fat.secondary' : 'widget.button.title.medium.fat'),
          rightIconKey: (_selectedContentType == contentType) ? 'check-accent' : null,
          title: contentType.displayTitle,
          onTap: () => _onTapDropdownItem(contentType)
      ))));
    }
    sectionList.add(Container(height: 32,));
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: sectionList)
      )
    );
  }

  void _onTapContentDropdown() {
    Analytics().logSelect(target: 'Content Dropdown');
    _changeSettingsContentValuesVisibility();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dropdownFocusNode.requestFocus();
    });
  }

  void _onTapDropdownItem(SettingsContentType contentType) {
    Analytics().logSelect(target: contentType.displayTitleEn);
    if (contentType == SettingsContentType.favorites) {
      HomeCustomizeFavoritesPanel.present(context).then((_) => NotificationService().notify(HomePanel.notifySelect));
    }
    else {
      _selectedContentType = Storage()._settingsContentType = contentType;
    }
    _changeSettingsContentValuesVisibility();
  }

  void _changeSettingsContentValuesVisibility() {
    if (mounted) {
      setState(() {
        _contentValuesVisible = !_contentValuesVisible;
      });
    }
    if (!_contentValuesVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _dropdownFocusNode.requestFocus();
      });
    }
  }

  Widget? get _contentWidget {
    switch (_selectedContentType) {
      case SettingsContentType.food_filters: return SettingsFoodFiltersPage();
      case SettingsContentType.sports: return AthleticsTeamsWidget();
      case SettingsContentType.recent_items: return SettingsRecentItemsPage();
      case SettingsContentType.appointments_and_events: return SettingsAppointmentsAndEventsPage();
      case SettingsContentType.favorites: return null;
      case SettingsContentType.assessments: return SettingsAssessmentsPage();
      case SettingsContentType.language: return SettingsLanguagePage();
      case SettingsContentType.about: return SettingsAboutPage();
      case SettingsContentType.research: return SettingsResearchPage(parentRouteName: SettingsHomePanel.routeName);
      case SettingsContentType.privacy: return SettingsPrivacyCenterPage();
      case SettingsContentType.notifications: return SettingsNotificationPreferencesPage();
      case SettingsContentType.accessibility: return SettingsAccessibilityPage();
      default: return null;
    }
  }

  void _updateContentTypesIfNeeded() {
    List<SettingsContentType> contentTypes = _SettingsContentTypeList.fromFlexUi();
    if (!DeepCollectionEquality().equals(_contentTypes, contentTypes) && mounted) {
      setState(() {
        _contentTypes = contentTypes;
      });
    }
  }

  void _onTapDebug() {
    Analytics().logSelect(target: 'Debug', source: widget.runtimeType.toString());
    if (kDebugMode || (Config().configEnvironment == ConfigEnvironment.dev)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugHomePanel()));
    }
  }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: widget.runtimeType.toString());
    Navigator.of(context).pop();
  }

}

// _DebugContainer

class _DebugContainer extends StatefulWidget implements PreferredSizeWidget {
  final Widget _child;

  _DebugContainer({required Widget child}) : _child = child;

  // PreferredSizeWidget
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  _DebugContainerState createState() => _DebugContainerState();
}

class _DebugContainerState extends State<_DebugContainer> {
  int _clickedCount = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: widget._child,
      onTap: () {
        Analytics().logSelect(target: 'Debug 7 Clicks', source: 'Header Bar');
        Log.d("On tap debug widget");
        _clickedCount++;

        if (_clickedCount == 7) {
          if (Auth2().isDebugManager) {
            Analytics().logSelect(target: 'Debug 7th Click', source: 'Header Bar');
            Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugHomePanel()));
          }
          _clickedCount = 0;
        }
      },
    );
  }
}

// SettingsContentTypeImpl

extension SettingsContentTypeImpl on SettingsContentType {
  String get displayTitle => displayTitleLng();
  String get displayTitleEn => displayTitleLng('en');

  String displayTitleLng([ String? language ]) {
    switch (this) {
      case SettingsContentType.food_filters: return Localization().getStringEx('panel.settings.home.settings.sections.food_filter.label', 'My Food Filter', language: language);
      case SettingsContentType.sports: return Localization().getStringEx('panel.settings.home.settings.sections.sports.label', 'My Sports Teams', language: language);
      case SettingsContentType.recent_items: return Localization().getStringEx('panel.settings.home.settings.sections.recent_items.label', 'My Browsing History', language: language);
      case SettingsContentType.appointments_and_events: return Localization().getStringEx('panel.settings.home.settings.sections.appointments_and_events.label', 'My Appointments & Events', language: language);
      case SettingsContentType.favorites: return Localization().getStringEx('panel.settings.home.settings.sections.favorites.label', 'Customize Favorites', language: language);
      case SettingsContentType.assessments: return Localization().getStringEx('panel.settings.home.settings.sections.assessments.label', 'My Assessments', language: language);
      case SettingsContentType.language: return Localization().getStringEx('panel.settings.home.settings.sections.language.label', 'My Language', language: language);
      case SettingsContentType.about: return Localization().getStringEx('panel.settings.home.settings.sections.about.label', 'About the App', language: language);
      case SettingsContentType.research: return Localization().getStringEx('panel.settings.home.settings.sections.research.label', 'My Participation in Research', language: language);
      case SettingsContentType.privacy: return Localization().getStringEx('panel.settings.home.settings.sections.privacy.label', 'My App Privacy Settings', language: language);
      case SettingsContentType.notifications: return Localization().getStringEx('panel.settings.home.settings.sections.notifications.label', 'My Notification Preferences', language: language);
      case SettingsContentType.accessibility: return Localization().getStringEx('panel.settings.home.settings.sections.accessibility.label', 'Accessibility', language: language);
    }
  }

  String get jsonString {
    switch (this) {
      case SettingsContentType.food_filters: return 'food_filters';
      case SettingsContentType.sports: return 'sports';
      case SettingsContentType.recent_items: return 'recent_items';
      case SettingsContentType.appointments_and_events: return 'appointments_and_events';
      case SettingsContentType.favorites: return 'favorites';
      case SettingsContentType.assessments: return 'assessments';
      case SettingsContentType.language: return 'language';
      case SettingsContentType.about: return 'about';
      case SettingsContentType.research: return 'research';
      case SettingsContentType.privacy: return 'privacy';
      case SettingsContentType.notifications: return 'notifications';
      case SettingsContentType.accessibility: return 'accessibility';
    }
  }

  static SettingsContentType? fromJsonString(String? value) {
    switch(value) {
      case 'food_filters': return SettingsContentType.food_filters;
      case 'sports': return SettingsContentType.sports;
      case 'recent_items': return SettingsContentType.recent_items;
      case 'appointments_and_events': return SettingsContentType.appointments_and_events;
      case 'favorites': return SettingsContentType.favorites;
      case 'assessments': return SettingsContentType.assessments;
      case 'language': return SettingsContentType.language;
      case 'about': return SettingsContentType.about;
      case 'research': return SettingsContentType.research;
      case 'privacy': return SettingsContentType.privacy;
      case 'notifications': return SettingsContentType.notifications;
      case 'accessibility': return SettingsContentType.accessibility;
      default: return null;
    }
  }

  SettingsContentType? _ensure({List<SettingsContentType>? availableTypes}) =>
      (availableTypes?.contains(this) != false) ? this : null;
}

extension _SettingsContentTypeList on List<SettingsContentType> {
  void sortAlphabetical() => sort((SettingsContentType t1, SettingsContentType t2) => t1.displayTitle.compareTo(t2.displayTitle));

  static List<SettingsContentType> fromFlexUi() {
    List<SettingsContentType> contentTypesList = <SettingsContentType>[];
    List<String>? codes = JsonUtils.listStringsValue(FlexUI()['settings']);
    if (codes != null) {
      for (String code in codes) {
        SettingsContentType? contentType = SettingsContentTypeImpl.fromJsonString(code);
        if (contentType != null) {
          contentTypesList.add(contentType);
        }
      }
      if (1 < contentTypesList.length) {
        contentTypesList.sortAlphabetical();
      }
    }
    return contentTypesList;
  }
}

extension _StorageSettingsExt on Storage {
  SettingsContentType? get _settingsContentType => SettingsContentTypeImpl.fromJsonString(settingsContentType);
  set _settingsContentType(SettingsContentType? value) => settingsContentType = value?.jsonString;
}

