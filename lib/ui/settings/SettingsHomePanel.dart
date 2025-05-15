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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/MobileAccess.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/athletics/AthleticsTeamsWidget.dart';
import 'package:illinois/ui/home/HomeCustomizeFavoritesPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/settings/SettingsAppointmentsPage.dart';
import 'package:illinois/ui/settings/SettingsAssessmentsPage.dart';
import 'package:illinois/ui/settings/SettingsCalendarPage.dart';
import 'package:illinois/ui/settings/SettingsContactsPage.dart';
import 'package:illinois/ui/settings/SettingsFoodFiltersPage.dart';
import 'package:illinois/ui/settings/SettingsICardPage.dart';
import 'package:illinois/ui/settings/SettingsLanguagePage.dart';
import 'package:illinois/ui/settings/SettingsMapsPage.dart';
import 'package:illinois/ui/settings/SettingsNotificationPreferencesPage.dart';
import 'package:illinois/ui/settings/SettingsPrivacyCenterPage.dart';
import 'package:illinois/ui/settings/SettingsRecentItemsPage.dart';
import 'package:illinois/ui/settings/SettingsResearchPage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/debug/DebugHomePanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

enum SettingsContentType { food_filters, sports, favorites, assessments, calendar, recent_items, appointments, i_card, language, contact, maps, research, privacy, notifications}

class SettingsHomePanel extends StatefulWidget with AnalyticsInfo {
  static final String routeName = 'settings_home_content_panel';

  static final Set<SettingsContentType> _dropdownContentTypes = <SettingsContentType>{
    //SettingsContent visible in the dropdown. Some can be accessed only from outside. Example: SettingsHomeContentPanel.present(context, content: SettingsContent.food_filters);
    SettingsContentType.contact,
    SettingsContentType.maps,
    SettingsContentType.appointments,
    SettingsContentType.assessments,
    SettingsContentType.research,
    SettingsContentType.calendar,
    SettingsContentType.recent_items,
    SettingsContentType.language,
    SettingsContentType.privacy,
    SettingsContentType.notifications,
    SettingsContentType.i_card,
  };

  final SettingsContentType? contentType;

  SettingsHomePanel._({this.contentType});

  @override
  _SettingsHomePanelState createState() => _SettingsHomePanelState();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.Settings;

  static void present(BuildContext context, { SettingsContentType? content}) {
    if (ModalRoute.of(context)?.settings.name != routeName) {
      MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
      double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 16;
      showModalBottomSheet(
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
  late List<SettingsContentType> _contentTypes;
  late SettingsContentType? _selectedContentType;
  bool _contentValuesVisible = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      MobileAccess.notifyMobileStudentIdChanged,
      Localization.notifyLocaleChanged,
    ]);
    _contentTypes = _SettingsContentTypeList.fromAvailableContentTypes(SettingsHomePanel._dropdownContentTypes);
    _selectedContentType = widget.contentType ?? Storage()._settingsContentType ?? (_contentTypes.isNotEmpty ? _contentTypes.first : null);
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
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
                  Semantics(hint: Localization().getStringEx("dropdown.hint", "DropDown"), focused: true, container: true, child:
                    RibbonButton(
                      textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"),
                      backgroundColor: Styles().colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                      rightIconKey: (_contentValuesVisible ? 'chevron-up' : 'chevron-down'),
                      label: _selectedContentType?.displayTitle ?? '',
                      onTap: _onTapContentDropdown
                    )
                  )
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
    return Stack(children: [
      Padding(padding: EdgeInsets.all(16), child:
        _contentWidget ?? Container()
      ),
      _buildContentValuesContainer()
    ]);
  }

  Widget _buildContentValuesContainer() {
    return Visibility(
      visible: _contentValuesVisible,
      child: Container /* Positioned.fill*/ (child:
        Stack(children: <Widget>[
          _dropdownDismissLayer,
          _dropdownList
        ])));
  }

  Widget get _dropdownDismissLayer {
    return Container /* Positioned.fill */ (
        child: BlockSemantics(
            child: Semantics(excludeSemantics: true,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _contentValuesVisible = false;
                  });
                },
                child: Container(
                  color: Styles().colors.blackTransparent06,
                  height: MediaQuery.of(context).size.height,
                  
                )))));
  }

  Widget get _dropdownList {
    List<Widget> sectionList = <Widget>[];
    sectionList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));
    for (SettingsContentType contentType in _contentTypes) {
      sectionList.add(RibbonButton(
        backgroundColor: Styles().colors.white,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        textStyle: Styles().textStyles.getTextStyle((_selectedContentType == contentType) ? 'widget.button.title.medium.fat.secondary' : 'widget.button.title.medium.fat'),
        rightIconKey: (_selectedContentType == contentType) ? 'check-accent' : null,
        label: contentType.displayTitle,
        onTap: () => _onTapDropdownItem(contentType)
      ));
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: sectionList)));
  }

  void _onTapContentDropdown() {
    Analytics().logSelect(target: 'Content Dropdown');
    _changeSettingsContentValuesVisibility();
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
  }

  Widget? get _contentWidget {
    switch (_selectedContentType) {
      case SettingsContentType.food_filters: return SettingsFoodFiltersPage();
      case SettingsContentType.sports: return AthleticsTeamsWidget();
      case SettingsContentType.calendar: return SettingsCalendarPage();
      case SettingsContentType.recent_items: return SettingsRecentItemsPage();
      case SettingsContentType.appointments: return SettingsAppointmentsPage();
      case SettingsContentType.favorites: return null;
      case SettingsContentType.assessments: return SettingsAssessmentsPage();
      case SettingsContentType.i_card: return SettingsICardPage();
      case SettingsContentType.language: return SettingsLanguagePage();
      case SettingsContentType.contact: return SettingsContactsPage();
      case SettingsContentType.maps: return SettingsMapsPage();
      case SettingsContentType.research: return SettingsResearchPage(parentRouteName: SettingsHomePanel.routeName);
      case SettingsContentType.privacy: return SettingsPrivacyCenterPage();
      case SettingsContentType.notifications: return SettingsNotificationPreferencesPage();
      default: return null;
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

  // NotificationsListener
  
  @override
  void onNotification(String name, dynamic param) {
    if (name == MobileAccess.notifyMobileStudentIdChanged) {
      setStateIfMounted(() {});
    }
    else if (name == Localization.notifyLocaleChanged) {
      setStateIfMounted(() {});
    }
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
      case SettingsContentType.calendar: return Localization().getStringEx('panel.settings.home.settings.sections.calendar.label', 'Add to My Device\'s Calendar', language: language);
      case SettingsContentType.recent_items: return Localization().getStringEx('panel.settings.home.settings.sections.recent_items.label', 'My Browsing History', language: language);
      case SettingsContentType.appointments: return Localization().getStringEx('panel.settings.home.settings.sections.appointments.label', 'My Appointments', language: language);
      case SettingsContentType.favorites: return Localization().getStringEx('panel.settings.home.settings.sections.favorites.label', 'Customize Favorites', language: language);
      case SettingsContentType.assessments: return Localization().getStringEx('panel.settings.home.settings.sections.assessments.label', 'My Assessments', language: language);
      case SettingsContentType.i_card: return Localization().getStringEx('panel.settings.home.settings.sections.i_card.label', 'Illini ID', language: language);
      case SettingsContentType.language: return Localization().getStringEx('panel.settings.home.settings.sections.language.label', 'My Language', language: language);
      case SettingsContentType.contact: return Localization().getStringEx('panel.settings.home.settings.sections.contact.label', 'Contact Us', language: language);
      case SettingsContentType.maps: return Localization().getStringEx('panel.settings.home.settings.sections.maps.label', 'Maps & Wayfinding', language: language);
      case SettingsContentType.research: return Localization().getStringEx('panel.settings.home.settings.sections.research.label', 'My Participation in Research', language: language);
      case SettingsContentType.privacy: return Localization().getStringEx('panel.settings.home.settings.sections.privacy.label', 'My App Privacy Settings', language: language);
      case SettingsContentType.notifications: return Localization().getStringEx('panel.settings.home.settings.sections.notifications.label', 'My Notification Preferences', language: language);
    }
  }

  String get jsonString {
    switch (this) {
      case SettingsContentType.food_filters: return 'food_filters';
      case SettingsContentType.sports: return 'sports';
      case SettingsContentType.calendar: return 'calendar';
      case SettingsContentType.recent_items: return 'recent_items';
      case SettingsContentType.appointments: return 'appointments';
      case SettingsContentType.favorites: return 'favorites';
      case SettingsContentType.assessments: return 'assessments';
      case SettingsContentType.i_card: return 'i_card';
      case SettingsContentType.language: return 'language';
      case SettingsContentType.contact: return 'contact';
      case SettingsContentType.maps: return 'maps';
      case SettingsContentType.research: return 'research';
      case SettingsContentType.privacy: return 'privacy';
      case SettingsContentType.notifications: return 'notifications';
    }
  }

  static SettingsContentType? fromJsonString(String? value) {
    switch(value) {
      case 'food_filters': return SettingsContentType.food_filters;
      case 'sports': return SettingsContentType.sports;
      case 'calendar': return SettingsContentType.calendar;
      case 'recent_items': return SettingsContentType.recent_items;
      case 'appointments': return SettingsContentType.appointments;
      case 'favorites': return SettingsContentType.favorites;
      case 'assessments': return SettingsContentType.assessments;
      case 'i_card': return SettingsContentType.i_card;
      case 'language': return SettingsContentType.language;
      case 'contact': return SettingsContentType.contact;
      case 'maps': return SettingsContentType.maps;
      case 'research': return SettingsContentType.research;
      case 'privacy': return SettingsContentType.privacy;
      case 'notifications': return SettingsContentType.notifications;
      default: return null;
    }
  }

  bool get isAvailable {
    switch (this) {
      // Add i_card content only if icard mobile is available
      case SettingsContentType.i_card: return MobileAccess().isMobileAccessAvailable;

      default: return true;
    }
  }
}

extension _SettingsContentTypeList on List<SettingsContentType> {
  void sortAlphabetical() => sort((SettingsContentType t1, SettingsContentType t2) => t1.displayTitle.compareTo(t2.displayTitle));

  static List<SettingsContentType> fromAvailableContentTypes(Iterable<SettingsContentType> contentTypes) {
    List<SettingsContentType> contentTypesList = List<SettingsContentType>.from(contentTypes.where((contentType) => contentType.isAvailable));
    contentTypesList.sortAlphabetical();
    return contentTypesList;
  }
}

extension _StorageSettingsExt on Storage {
  SettingsContentType? get _settingsContentType => SettingsContentTypeImpl.fromJsonString(walletContentType);
  set _settingsContentType(SettingsContentType? value) => walletContentType = value?.jsonString;
}

