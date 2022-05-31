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
import 'package:flutter/cupertino.dart';
import 'package:illinois/ui/settings/SettingsSectionsContentWidget.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/debug/DebugHomePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/styles.dart';

class SettingsHomeContentPanel extends StatefulWidget {
  final SettingsSection? section;

  SettingsHomeContentPanel({this.section});

  @override
  _SettingsHomeContentPanelState createState() => _SettingsHomeContentPanelState();
}

class _SettingsHomeContentPanelState extends State<SettingsHomeContentPanel> {
  late SettingsSection _selectedSection;
  bool _sectionsVisible = false;

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.section ?? SettingsSection.sections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(titleWidget: _buildHeaderBarTitle()),
        body: Column(children: <Widget>[
          Expanded(
              child: SingleChildScrollView(
                  physics: (_sectionsVisible ? NeverScrollableScrollPhysics() : null),
                  child: Container(
                      color: Styles().colors!.background,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(
                            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
                            child: RibbonButton(
                                textColor: (_sectionsVisible ? Styles().colors!.fillColorSecondary : Styles().colors!.fillColorPrimary),
                                backgroundColor: Styles().colors!.white,
                                borderRadius: BorderRadius.all(Radius.circular(5)),
                                border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
                                rightIconAsset: (_sectionsVisible ? 'images/icon-up.png' : 'images/icon-down.png'),
                                label: _getSectionLabel(_selectedSection),
                                onTap: _changeSettingsSectionsVisibility)),
                        _buildContent()
                      ]))))
        ]),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: uiuc.TabBar());
  }

  Widget _buildHeaderBarTitle() {
    return _DebugContainer(
        child: Text(_panelHeaderLabel,
            style: TextStyle(color: Styles().colors!.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
            textAlign: TextAlign.center));
  }

  Widget _buildContent() {
    return Stack(children: [Padding(padding: EdgeInsets.all(16), child: _contentWidget), _buildSectionsContainer()]);
  }

  Widget _buildSectionsContainer() {
    return Visibility(
        visible: _sectionsVisible,
        child: Positioned.fill(child: Stack(children: <Widget>[_buildSectionsDismissLayer(), _buildSectionsValuesContainer()])));
  }

  Widget _buildSectionsDismissLayer() {
    return Positioned.fill(
        child: BlockSemantics(
            child: GestureDetector(
                onTap: () {
                  setState(() {
                    _sectionsVisible = false;
                  });
                },
                child: Container(color: Styles().colors!.blackTransparent06))));
  }

  Widget _buildSectionsValuesContainer() {
    List<Widget> sectionList = <Widget>[];
    sectionList.add(Container(color: Styles().colors!.fillColorSecondary, height: 2));
    for (SettingsSection section in SettingsSection.values) {
      if ((_selectedSection != section)) {
        sectionList.add(_buildSectionItem(section));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: sectionList)));
  }

  Widget _buildSectionItem(SettingsSection section) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconAsset: null,
        label: _getSectionLabel(section),
        onTap: () => _onTapSection(section));
  }

  void _onTapSection(SettingsSection section) {
    _selectedSection = section;
    _changeSettingsSectionsVisibility();
  }

  void _changeSettingsSectionsVisibility() {
    _sectionsVisible = !_sectionsVisible;
    if (mounted) {
      setState(() {});
    }
  }

  Widget get _contentWidget {
    switch (_selectedSection) {
      case SettingsSection.sections:
        return SettingsSectionsContentWidget();
      case SettingsSection.interests:
        //TODO: implement
        return Container();
      case SettingsSection.food_filters:
        //TODO: implement
        return Container();
      case SettingsSection.sports:
        //TODO: implement
        return Container();
      case SettingsSection.calendar:
        //TODO: implement
        return Container();
      default:
        return Container();
    }
  }

  // Utilities

  String _getSectionLabel(SettingsSection section) {
    switch (section) {
      case SettingsSection.sections:
        return Localization().getStringEx('panel.settings.home.settings.sections.section.label', 'Setting Sections');
      // case SettingsSection.profile:
        // return Localization().getStringEx('panel.settings.home.settings.sections.profile.label', 'My Profile');
      // case SettingsSection.privacy:
      //   return Localization().getStringEx('panel.settings.home.settings.sections.privacy.label', 'My App Privacy Settings');
      // case SettingsSection.personal_info:
      //   return Localization().getStringEx('panel.settings.home.settings.sections.personal_info.label', 'Personal Information');
      // case SettingsSection.who_are_you:
      //   return Localization().getStringEx('panel.settings.home.settings.sections.who_are_you.label', 'Who Are You');
      case SettingsSection.interests:
        return Localization().getStringEx('panel.settings.home.settings.sections.interests.label', 'My Interests Filter');
      case SettingsSection.food_filters:
        return Localization().getStringEx('panel.settings.home.settings.sections.food_filter.label', 'My Food Filter');
      case SettingsSection.sports:
        return Localization().getStringEx('panel.settings.home.settings.sections.sports.label', 'My Sports Teams');
      // case SettingsSection.notifications:
      //   return Localization().getStringEx('panel.settings.home.settings.sections.notifications.label', 'My Notifications');
      case SettingsSection.calendar:
        return Localization().getStringEx('panel.settings.home.settings.sections.calendar.label', 'My Calendar Settings');
    }
  }

  String get _panelHeaderLabel {
    switch (_selectedSection) {
      case SettingsSection.sections:
        return Localization().getStringEx('panel.settings.home.header.settings.label', 'Settings');
      // case SettingsSection.profile:
      //   return Localization().getStringEx('panel.settings.home.header.profile.label', 'Profile');
      // case SettingsSection.privacy:
        // return Localization().getStringEx('panel.settings.home.header.privacy.label', 'Privacy');
      // case SettingsSection.personal_info:
      //   return Localization().getStringEx('panel.settings.home.header.personal_info.label', 'Personal Information');
      // case SettingsSection.who_are_you:
      //   return Localization().getStringEx('panel.settings.home.header.who_are_you.label', 'Who Are You');
      case SettingsSection.interests:
        return Localization().getStringEx('panel.settings.home.header.interests.label', 'My Interests');
      case SettingsSection.food_filters:
        return Localization().getStringEx('panel.settings.home.header.food_filter.label', 'My Food Filter');
      case SettingsSection.sports:
        return Localization().getStringEx('panel.settings.home.header.sports.label', 'My Sports Teams');
      // case SettingsSection.notifications:
      //   return Localization().getStringEx('panel.settings.home.header.notifications.label', 'My Notifications');
      case SettingsSection.calendar:
        return Localization().getStringEx('panel.settings.home.header.calendar.label', 'My Calendar Settings');
    }
  }
}

enum SettingsSection { sections, interests, food_filters, sports, calendar }

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
        Log.d("On tap debug widget");
        _clickedCount++;

        if (_clickedCount == 7) {
          if (Auth2().isDebugManager) {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugHomePanel()));
          }
          _clickedCount = 0;
        }
      },
    );
  }
}
