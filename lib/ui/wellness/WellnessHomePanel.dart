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
import 'package:illinois/ui/wellness/WellnessDimensionContentWidget.dart';
import 'package:illinois/ui/wellness/WellnessResourcesContentWidget.dart';
import 'package:illinois/ui/wellness/WellnessRingsHomeContentWidget.dart';
import 'package:illinois/ui/wellness/WellnessSectionsContentWidget.dart';
import 'package:illinois/ui/wellness/WellnessToDoHomeContentWidget.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/styles.dart';

class WellnessHomePanel extends StatefulWidget {
  final WellnessContent? content;
  final bool rootTabDisplay;

  WellnessHomePanel({this.content, this.rootTabDisplay = false});

  @override
  _WellnessHomePanelState createState() => _WellnessHomePanelState();
}

class _WellnessHomePanelState extends State<WellnessHomePanel> {
  static WellnessContent? _lastSelectedContent;
  late WellnessContent _selectedContent;
  ScrollController _scrollController = ScrollController();
  bool _contentValuesVisible = false;

  @override
  void initState() {
    super.initState();
    _selectedContent = widget.content ?? (_lastSelectedContent ?? WellnessContent.sections);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: headerBar,
        body: Column(children: <Widget>[
          Expanded(
              child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: (_contentValuesVisible ? NeverScrollableScrollPhysics() : null),
                  child: Container(
                      color: Styles().colors!.background,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(
                            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
                            child: RibbonButton(
                                textColor: Styles().colors!.fillColorSecondary,
                                backgroundColor: Styles().colors!.white,
                                borderRadius: BorderRadius.all(Radius.circular(5)),
                                border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
                                rightIconAsset: (_contentValuesVisible ? 'images/icon-up.png' : 'images/icon-down-orange.png'),
                                label: _getContentLabel(_selectedContent),
                                onTap: _changeSettingsContentValuesVisibility)),
                        _buildContent()
                      ]))))
        ]),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: navigationBar);
  }

  Widget _buildContent() {
    return Stack(children: [Padding(padding: EdgeInsets.symmetric(vertical: 16), child: _contentWidget), _buildContentValuesContainer()]);
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
    for (WellnessContent section in WellnessContent.values) {
      if ((_selectedContent != section)) {
        sectionList.add(_buildContentItem(section));
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
    _selectedContent = _lastSelectedContent = contentItem;
    _changeSettingsContentValuesVisibility();
  }

  void _onTapEightDimensions() {
    Analytics().logSelect(target: "Wellness 8 Dimensions");
    _selectedContent = _lastSelectedContent = WellnessContent.eight_dimensions;
    _contentValuesVisible = false;
    _scrollController.animateTo(0, duration: Duration(milliseconds: 10), curve: Curves.ease);
    if (mounted) {
      setState(() {});
    }
  }

  void _changeSettingsContentValuesVisibility() {
    _contentValuesVisible = !_contentValuesVisible;
    if (mounted) {
      setState(() {});
    }
  }

  PreferredSizeWidget get headerBar {
    String title = Localization().getStringEx('panel.wellness.home.header.sections.title', 'Wellness');
    if (widget.rootTabDisplay) {
      return RootHeaderBar(title: title);
    } else {
      return HeaderBar(title: title);
    }
  }

  Widget? get navigationBar {
    return widget.rootTabDisplay ? null : uiuc.TabBar();
  }

  Widget get _contentWidget {
    switch (_selectedContent) {
      case WellnessContent.sections:
        return WellnessSectionsContentWidget(onTapEightDimension: () => _onTapEightDimensions());
      case WellnessContent.rings:
        return WellnessRingsHomeContentWidget();
      case WellnessContent.todo:
        return WellnessToDoHomeContentWidget();
      case WellnessContent.resources:
        return WellnessResourcesContentWidget();
      case WellnessContent.eight_dimensions:
        return WellnessDimensionContentWidget();
      default:
        return Container();
    }
  }

  // Utilities

  String _getContentLabel(WellnessContent section) {
    switch (section) {
      case WellnessContent.sections:
        return Localization().getStringEx('panel.wellness.section.sections.label', 'Wellness Sections');
      case WellnessContent.rings:
        return Localization().getStringEx('panel.wellness.section.rings.label', 'Daily Wellness Rings');
      case WellnessContent.todo:
        return Localization().getStringEx('panel.wellness.section.todo.label', 'To-Do List');
      case WellnessContent.resources:
        return Localization().getStringEx('panel.wellness.section.resources.label', 'Wellness Resources');
      case WellnessContent.eight_dimensions:
        return Localization().getStringEx('panel.wellness.section.eight_dimensions.label', '8 Dimensions of Wellness');
    }
  }
}

enum WellnessContent { sections, rings, todo, resources, eight_dimensions }