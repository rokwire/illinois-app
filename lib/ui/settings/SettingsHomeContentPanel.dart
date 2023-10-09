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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/MobileAccess.dart';
import 'package:illinois/ui/athletics/AthleticsTeamsWidget.dart';
import 'package:illinois/ui/home/HomeCustomizeFavoritesPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/settings/SettingsAppointmentsContentWidget.dart';
import 'package:illinois/ui/settings/SettingsAssessmentsContentWidget.dart';
import 'package:illinois/ui/settings/SettingsCalendarContentWidget.dart';
import 'package:illinois/ui/settings/SettingsFoodFiltersContentWidget.dart';
import 'package:illinois/ui/settings/SettingsICardContentWidget.dart';
import 'package:illinois/ui/settings/SettingsInterestsContentWidget.dart';
import 'package:illinois/ui/settings/SettingsLanguageContentWidget.dart';
import 'package:illinois/ui/settings/SettingsSectionsContentWidget.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/debug/DebugHomePanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

enum SettingsContent { sections, interests, food_filters, sports, favorites, assessments, calendar, appointments, i_card, language }

class SettingsHomeContentPanel extends StatefulWidget {
  static final String routeName = 'settings_home_content_panel';
  
  final SettingsContent? content;

  SettingsHomeContentPanel._({this.content});

  @override
  _SettingsHomeContentPanelState createState() => _SettingsHomeContentPanelState();

  static void present(BuildContext context, { SettingsContent? content}) {
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
        backgroundColor: Styles().colors!.background,
        constraints: BoxConstraints(maxHeight: height, minHeight: height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (context) {
          return SettingsHomeContentPanel._(content: content);
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

class _SettingsHomeContentPanelState extends State<SettingsHomeContentPanel> implements NotificationsListener {
  static SettingsContent? _lastSelectedContent;
  late SettingsContent _selectedContent;
  bool _contentValuesVisible = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      MobileAccess.notifyMobileStudentIdChanged,
      Localization.notifyLocaleChanged,
    ]);
    _selectedContent = widget.content ?? (_lastSelectedContent ?? SettingsContent.sections);
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
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar()
    );
  }*/

  Widget _buildSheet(BuildContext context) {
    // MediaQuery(data: MediaQueryData.fromWindow(WidgetsBinding.instance.window), child: SafeArea(bottom: false, child: ))
    return Column(children: [
        Container(color: Styles().colors?.white, child:
          Row(children: [
            Expanded(child:
              _DebugContainer(child:
                Padding(padding: EdgeInsets.only(left: 16), child:
                  Text(Localization().getStringEx('panel.settings.home.header.settings.label', 'Settings'), style: Styles().textStyles?.getTextStyle("widget.sheet.title.regular"))
                )
              ),
            ),
            Visibility(visible: (kDebugMode || (Config().configEnvironment == ConfigEnvironment.dev)), child:
              InkWell(onTap : _onTapDebug, child:
                Container(padding: EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 16), child: 
                  Styles().images?.getImage('bug', excludeFromSemantics: true),
                ),
              ),
            ),
            Semantics( label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), inMutuallyExclusiveGroup: true, button: true, child:
              InkWell(onTap : _onTapClose, child:
                Container(padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16), child:
                  Styles().images?.getImage('close', excludeFromSemantics: true),
                ),
              ),
            ),

          ],),
        ),
        Container(color: Styles().colors?.surfaceAccent, height: 1,),
        Expanded(child:
          _buildPage(context),
        )
      ],);
  }

  Widget _buildPage(BuildContext context) {
    return Column(children: <Widget>[
      Expanded(child:
        SingleChildScrollView(physics: (_contentValuesVisible ? NeverScrollableScrollPhysics() : null), child:
          Container(color: Styles().colors!.background, child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: EdgeInsets.only(left: 16, top: 16, right: 16), child:
                RibbonButton(
                  textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat.secondary"),
                  backgroundColor: Styles().colors!.white,
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                  border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
                  rightIconKey: (_contentValuesVisible ? 'chevron-up' : 'chevron-down'),
                  label: _getContentLabel(_selectedContent),
                  onTap: _onTapContentDropdown
                )
              ),
              _buildContent()
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildContent() {
    return Stack(children: [
      Padding(padding: EdgeInsets.all(16), child:
        _contentWidget
      ),
      _buildContentValuesContainer()
    ]);
  }

  Widget _buildContentValuesContainer() {
    return Visibility(
      visible: _contentValuesVisible,
      child: Container /* Positioned.fill*/ (child:
        Stack(children: <Widget>[
          _buildContentDismissLayer(),
          _buildContentValuesWidget()
        ])));
  }

  Widget _buildContentDismissLayer() {
    return Container /* Positioned.fill */ (
        child: BlockSemantics(
            child: GestureDetector(
                onTap: () {
                  setState(() {
                    _contentValuesVisible = false;
                  });
                },
                child: Container(
                  color: Styles().colors!.blackTransparent06,
                  height: MediaQuery.of(context).size.height,
                  
                ))));
  }

  Widget _buildContentValuesWidget() {
    List<Widget> sectionList = <Widget>[];
    sectionList.add(Container(color: Styles().colors!.fillColorSecondary, height: 2));
    for (SettingsContent section in SettingsContent.values) {
      if ((_selectedContent != section)) {
        // Add i_card content only if icard mobile is available
        if ((section != SettingsContent.i_card) || (MobileAccess().isMobileAccessAvailable)) {
          sectionList.add(_buildContentItem(section));
        }
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: sectionList)));
  }

  Widget _buildContentItem(SettingsContent contentItem) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconKey: null,
        label: _getContentLabel(contentItem),
        onTap: () => _onTapContentItem(contentItem));
  }

  void _onTapContentDropdown() {
    Analytics().logSelect(target: 'Content Dropdown');
    _changeSettingsContentValuesVisibility();
  }

  void _onTapContentItem(SettingsContent contentItem) {
    Analytics().logSelect(target: "Content Item: ${contentItem.toString()}");
    if (contentItem == SettingsContent.favorites) {
      HomeCustomizeFavoritesPanel.present(context).then((_) => NotificationService().notify(HomePanel.notifySelect));
    }
    else {
    _selectedContent = _lastSelectedContent = contentItem;
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

  Widget get _contentWidget {
    switch (_selectedContent) {
      case SettingsContent.sections:
        return SettingsSectionsContentWidget();
      case SettingsContent.interests:
        return SettingsInterestsContentWidget();
      case SettingsContent.food_filters:
        return SettingsFoodFiltersContentWidget();
      case SettingsContent.sports:
        return AthleticsTeamsWidget();
      case SettingsContent.calendar:
        return SettingsCalendarContentWidget();
      case SettingsContent.appointments:
        return SettingsAppointmentsContentWidget();
      case SettingsContent.favorites:
        return Container();
      case SettingsContent.assessments:
        return SettingsAssessmentsContentWidget();
      case SettingsContent.i_card:
        return SettingsICardContentWidget();
      case SettingsContent.language:
        return SettingsLanguageContentWidget();
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

  // Utilities

  String _getContentLabel(SettingsContent section) {
    switch (section) {
      case SettingsContent.sections:
        return Localization().getStringEx('panel.settings.home.settings.sections.section.label', 'Sign In/Sign Out');
      case SettingsContent.interests:
        return Localization().getStringEx('panel.settings.home.settings.sections.interests.label', 'My Interests');
      case SettingsContent.food_filters:
        return Localization().getStringEx('panel.settings.home.settings.sections.food_filter.label', 'My Food Filter');
      case SettingsContent.sports:
        return Localization().getStringEx('panel.settings.home.settings.sections.sports.label', 'My Sports Teams');
      case SettingsContent.calendar:
        return Localization().getStringEx('panel.settings.home.settings.sections.calendar.label', 'Add to My Device\'s Calendar');
      case SettingsContent.appointments:
        return Localization().getStringEx('panel.settings.home.settings.sections.appointments.label', 'MyMcKinley Appointments');
      case SettingsContent.favorites:
        return Localization().getStringEx('panel.settings.home.settings.sections.favorites.label', 'Customize Favorites');
      case SettingsContent.assessments:
        return Localization().getStringEx('panel.settings.home.settings.sections.assessments.label', 'My Assessments');
      case SettingsContent.i_card:
        return Localization().getStringEx('panel.settings.home.settings.sections.i_card.label', 'Illini ID');
      case SettingsContent.language:
        return Localization().getStringEx('panel.settings.home.settings.sections.language.label', 'My Language');
    }
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
