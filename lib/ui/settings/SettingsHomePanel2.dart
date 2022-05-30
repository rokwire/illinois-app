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
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/settings/SettingsHomePanel.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/debug/DebugHomePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/config.dart' as rokwire;
import 'package:rokwire_plugin/service/styles.dart';

class SettingsHomePanel2 extends StatefulWidget {
  @override
  _SettingsHomePanel2State createState() => _SettingsHomePanel2State();
}

class _SettingsHomePanel2State extends State<SettingsHomePanel2> {
  late _SettingsSection _selectedSection;
  bool _sectionsVisible = false;

  @override
  void initState() {
    super.initState();
    _selectedSection = _SettingsSection.sections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _DebugContainer(child: RootHeaderBar(title: _panelHeaderLabel)),
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
    bool debugVisible = (kDebugMode || (Config().configEnvironment == rokwire.ConfigEnvironment.dev));
    for (_SettingsSection section in _SettingsSection.values) {
      if ((_selectedSection != section)) {
        sectionList.add(_buildSectionItem(section));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: sectionList)));
  }

  Widget _buildSectionItem(_SettingsSection section) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconAsset: null,
        label: _getSectionLabel(section),
        onTap: () => _onTapSection(section));
  }

  void _onTapSection(_SettingsSection section) {
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
      case _SettingsSection.sections:
        return SettingsHomePanel();
      case _SettingsSection.profile:
        //TODO: implement
        return Container();
      case _SettingsSection.privacy:
        //TODO: implement
        return Container();
      case _SettingsSection.personal_info:
        //TODO: implement
        return Container();
      case _SettingsSection.who_are_you:
        //TODO: implement
        return Container();
      case _SettingsSection.interests:
        //TODO: implement
        return Container();
      case _SettingsSection.food_filters:
        //TODO: implement
        return Container();
      case _SettingsSection.sports:
        //TODO: implement
        return Container();
      case _SettingsSection.notifications:
        //TODO: implement
        return Container();
      default:
        return Container();
    }
  }

  // Utilities

  String _getSectionLabel(_SettingsSection section) {
    switch (section) {
      case _SettingsSection.sections:
        return Localization().getStringEx('panel.settings.home.settings.sections.section.label', 'Setting Sections');
      case _SettingsSection.profile:
        return Localization().getStringEx('panel.settings.home.settings.sections.profile.label', 'My Profile');
      case _SettingsSection.privacy:
        return Localization().getStringEx('panel.settings.home.settings.sections.privacy.label', 'My App Privacy Settings');
      case _SettingsSection.personal_info:
        return Localization().getStringEx('panel.settings.home.settings.sections.personal_info.label', 'Personal Information');
      case _SettingsSection.who_are_you:
        return Localization().getStringEx('panel.settings.home.settings.sections.who_are_you.label', 'Who Are You');
      case _SettingsSection.interests:
        return Localization().getStringEx('panel.settings.home.settings.sections.interests.label', 'My Interests Filter');
      case _SettingsSection.food_filters:
        return Localization().getStringEx('panel.settings.home.settings.sections.food_filter.label', 'My Food Filter');
      case _SettingsSection.sports:
        return Localization().getStringEx('panel.settings.home.settings.sections.sports.label', 'My Sports Teams');
      case _SettingsSection.notifications:
        return Localization().getStringEx('panel.settings.home.settings.sections.notifications.label', 'My Notifications');
    }
  }

  String get _panelHeaderLabel {
    switch (_selectedSection) {
      case _SettingsSection.sections:
        return Localization().getStringEx('panel.settings.home.header.settings.label', 'Settings');
      case _SettingsSection.profile:
        return Localization().getStringEx('panel.settings.home.header.profile.label', 'Profile');
      case _SettingsSection.privacy:
        return Localization().getStringEx('panel.settings.home.header.privacy.label', 'Privacy');
      case _SettingsSection.personal_info:
        return Localization().getStringEx('panel.settings.home.header.personal_info.label', 'Personal Information');
      case _SettingsSection.who_are_you:
        return Localization().getStringEx('panel.settings.home.header.who_are_you.label', 'Who Are You');
      case _SettingsSection.interests:
        return Localization().getStringEx('panel.settings.home.header.interests.label', 'My Interests');
      case _SettingsSection.food_filters:
        return Localization().getStringEx('panel.settings.home.header.food_filter.label', 'My Food Filter');
      case _SettingsSection.sports:
        return Localization().getStringEx('panel.settings.home.header.sports.label', 'My Sports Teams');
      case _SettingsSection.notifications:
        return Localization().getStringEx('panel.settings.home.header.notifications.label', 'My Notifications');
    }
  }
}

enum _SettingsSection { sections, profile, privacy, personal_info, who_are_you, interests, food_filters, sports, notifications }

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
