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
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/CheckList.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/academics/AcademicsEventsContentWidget.dart';
import 'package:illinois/ui/academics/SkillsSelfEvaluation.dart';
import 'package:illinois/ui/academics/StudentCourses.dart';
import 'package:illinois/ui/canvas/CanvasCoursesContentWidget.dart';
import 'package:illinois/ui/gies/CheckListContentWidget.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class AcademicsHomePanel extends StatefulWidget {
  final AcademicsContent? content;
  final bool rootTabDisplay;

  AcademicsHomePanel({this.content, this.rootTabDisplay = false});

  @override
  _AcademicsHomePanelState createState() => _AcademicsHomePanelState();
}

class _AcademicsHomePanelState extends State<AcademicsHomePanel>
    with AutomaticKeepAliveClientMixin<AcademicsHomePanel>
    implements NotificationsListener {

  static AcademicsContent? _lastSelectedContent;
  late AcademicsContent _selectedContent;
  List<AcademicsContent>? _contentValues;
  bool _contentValuesVisible = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [FlexUI.notifyChanged, Auth2.notifyLoginChanged]);
    _buildContentValues();
    _initSelectedContentItem();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // AutomaticKeepAliveClientMixin

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
        appBar: _headerBar,
        body: _bodyWidget,
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: _navigationBar,
      );
  }

  PreferredSizeWidget get _headerBar {
    String title = Localization().getStringEx('panel.academics.header.title', 'Academics');
    if (widget.rootTabDisplay) {
      return RootHeaderBar(title: title);
    } else {
      return HeaderBar(title: title);
    }
  }

  Widget? get _navigationBar {
    return widget.rootTabDisplay ? null : uiuc.TabBar();
  }

  Widget get _bodyWidget {
    return Column(children: <Widget>[
      Container(
        color: _skillsSelfEvaluationSelected ? Styles().colors?.fillColorPrimaryVariant : Styles().colors?.background,
        padding: EdgeInsets.only(left: 16, top: 16, right: 16), 
        child: RibbonButton(
          textColor: Styles().colors!.fillColorSecondary,
          backgroundColor: Styles().colors!.white,
          borderRadius: BorderRadius.all(Radius.circular(5)),
          border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
          rightIconAsset: (_contentValuesVisible ? 'images/icon-up.png' : 'images/icon-down-orange.png'),
          label: _getContentLabel(_selectedContent),
          onTap: _onTapRibbonButton
        ),
      ),
      Expanded(child:
        Stack(children: [
          Padding(padding: _skillsSelfEvaluationSelected ? EdgeInsets.zero : EdgeInsets.only(top: 16, left: 16, right: 16,), child:
            _contentWidget
          ),
          _buildContentValuesContainer()
        ]),
      )
    ]);
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
                  Analytics().logSelect(target: 'Close Dropdown');
                  setState(() {
                    _contentValuesVisible = false;
                  });
                },
                child: Container(color: Styles().colors!.blackTransparent06))));
  }

  Widget _buildContentValuesWidget() {
    List<Widget> sectionList = <Widget>[];
    sectionList.add(Container(color: Styles().colors!.fillColorSecondary, height: 2));
    if (CollectionUtils.isNotEmpty(_contentValues)) {
      for (AcademicsContent section in _contentValues!) {
        if ((_selectedContent != section)) {
          sectionList.add(_buildContentItem(section));
        }
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: sectionList)));
  }

  Widget _buildContentItem(AcademicsContent contentItem) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconAsset: null,
        rightIcon: _buildContentItemRightIcon(contentItem),
        label: _getContentLabel(contentItem),
        onTap: () => _onTapContentItem(contentItem));
  }

  Widget? _buildContentItemRightIcon(AcademicsContent contentItem) {
    switch (contentItem) {
      case AcademicsContent.my_illini:
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Image.asset('images/icon-login-grey.png'),
          Padding(padding: EdgeInsets.only(left: 6), child: Image.asset('images/icon-external-link-grey.png'))
        ]);
      default:
        return null;
    }
  }

  void _buildContentValues() {
    List<String>? contentCodes = JsonUtils.listStringsValue(FlexUI()['academics']);
    List<AcademicsContent>? contentValues;
    if (contentCodes != null) {
      contentValues = [];
      for (String code in contentCodes) {
        AcademicsContent? value = _getContentValueFromCode(code);
        if (value != null) {
          contentValues.add(value);
        }
      }
    }

    _contentValues = contentValues;
    if (mounted) {
      setState(() {});
    }
  }

  void _initSelectedContentItem() {
    AcademicsContent? initialContent = widget.content ?? _lastSelectedContent;
    if (initialContent == null) {
      if (CollectionUtils.isNotEmpty(_contentValues)) {
        if (_contentValues!.contains(AcademicsContent.gies_checklist) && !_isCheckListCompleted(CheckList.giesOnboarding)) {
          initialContent = AcademicsContent.gies_checklist;
        } else if (_contentValues!.contains(AcademicsContent.canvas_courses)) {
          initialContent = AcademicsContent.canvas_courses;
        } else if (_contentValues!.contains(AcademicsContent.student_courses)) {
          initialContent = AcademicsContent.student_courses;
        }
      }
    }
    _selectedContent = initialContent ?? AcademicsContent.events;
  }

  AcademicsContent? _getContentValueFromCode(String? code) {
    if (code == 'gies_checklist') {
      return AcademicsContent.gies_checklist;
    } else if (code == 'new_student_checklist') {
      return AcademicsContent.uiuc_checklist;
    } else if (code == 'canvas_courses') {
      return AcademicsContent.canvas_courses;
    } else if (code == 'student_courses') {
      return AcademicsContent.student_courses;
    } else if (code == 'academics_events') {
      return AcademicsContent.events;
    } else if (code == 'due_date_catalog') {
      return AcademicsContent.due_date_catalog;
    } else if (code == 'my_illini') {
      return AcademicsContent.my_illini;
    } else if (code == 'skills_self_evaluation') {
      return AcademicsContent.skills_self_evaluation;
    } else {
      return null;
    }
  }

  void _onTapContentItem(AcademicsContent contentItem) {
    Analytics().logSelect(target: '$contentItem');
    if (contentItem == AcademicsContent.my_illini) {
      // Open My Illini in an external browser
      _onMyIlliniSelected();
    } else if (contentItem == AcademicsContent.due_date_catalog) {
      // Open Due Date Catalog in an external browser
      _onTapDueDateCatalog();
    } else {
      _selectedContent = _lastSelectedContent = contentItem;
    }
    _changeSettingsContentValuesVisibility();
  }

  void _onTapRibbonButton() {
    Analytics().logSelect(target: 'Toggle Dropdown');
    _changeSettingsContentValuesVisibility();
  }

  void _changeSettingsContentValuesVisibility() {
    _contentValuesVisible = !_contentValuesVisible;
    if (mounted) {
      setState(() {});
    }
  }

  void _onMyIlliniSelected() {
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context,
          Localization().getStringEx('panel.browse.label.offline.my_illini', 'My Illini not available while offline.'));
    } else if (StringUtils.isNotEmpty(Config().myIlliniUrl)) {
      // Please make this use an external browser
      // Ref: https://github.com/rokwire/illinois-app/issues/1110
      Uri? myIlliniUri = Uri.tryParse(Config().myIlliniUrl!);
      if (myIlliniUri != null) {
        launchUrl(myIlliniUri);
      }

      //
      // Until webview_flutter get fixed for the dropdowns we will continue using it as a webview plugin,
      // but we will open in an external browser all problematic pages.
      // The other plugin doesn't work with VoiceOver
      // Ref: https://github.com/rokwire/illinois-client/issues/284
      //      https://github.com/flutter/plugins/pull/2330
      //
      // if (Platform.isAndroid) {
      //   launch(Config().myIlliniUrl);
      // }
      // else {
      //   String myIlliniPanelTitle = Localization().getStringEx(
      //       'widget.home.campus_resources.header.my_illini.title', 'My Illini');
      //   Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: Config().myIlliniUrl, title: myIlliniPanelTitle,)));
      // }
    }
  }

  void _onTapDueDateCatalog() {
    Analytics().logSelect(target: "Due Date Catalog");
    if (StringUtils.isNotEmpty(Config().dateCatalogUrl)) {
      Uri? uri = Uri.tryParse(Config().dateCatalogUrl!);
      if (uri != null) {
        launchUrl(uri);
      }
    }
  }

  Widget get _contentWidget {
    return ((_selectedContent == AcademicsContent.gies_checklist) || (_selectedContent == AcademicsContent.uiuc_checklist) || (_selectedContent == AcademicsContent.student_courses)) ?
      _rawContentWidget :
      SingleChildScrollView(child:
        Padding(padding: EdgeInsets.only(bottom: 16), child:
          _rawContentWidget
        ),
      );
  }

  Widget get _rawContentWidget {
    // There is no content for AcademicsContent.my_illini and AcademicsContent.due_date_catalog - it is a web url opened in an external browser
    switch (_selectedContent) {
      case AcademicsContent.events:
        return AcademicsEventsContentWidget();
      case AcademicsContent.gies_checklist:
        return CheckListContentWidget(contentKey: CheckList.giesOnboarding);
      case AcademicsContent.uiuc_checklist:
        return CheckListContentWidget(contentKey: CheckList.uiucOnboarding);
      case AcademicsContent.canvas_courses:
        return CanvasCoursesContentWidget();
      case AcademicsContent.student_courses:
        return StudentCoursesContentWidget();
      case AcademicsContent.skills_self_evaluation:
        return SkillsSelfEvaluation();
      default:
        return Container();
    }
  }
  
  bool get _skillsSelfEvaluationSelected => _selectedContent == AcademicsContent.skills_self_evaluation;

  bool _isCheckListCompleted(String contentKey) {
    int stepsCount = CheckList(contentKey).progressSteps?.length ?? 0;
    int completedStepsCount = CheckList(contentKey).completedStepsCount;
    return (stepsCount == completedStepsCount);
  }

  // Utilities

  String _getContentLabel(AcademicsContent section) {
    switch (section) {
      case AcademicsContent.events:
        return Localization().getStringEx('panel.academics.section.events.label', 'Academic Events');
      case AcademicsContent.gies_checklist:
        return Localization().getStringEx('panel.academics.section.gies_checklist.label', 'iDegrees New Student Checklist');
      case AcademicsContent.uiuc_checklist:
        return Localization().getStringEx('panel.academics.section.uiuc_checklist.label', 'New Student Checklist');
      case AcademicsContent.canvas_courses:
        return Localization().getStringEx('panel.academics.section.canvas_courses.label', 'My Gies Canvas Courses');
      case AcademicsContent.student_courses:
        return Localization().getStringEx('panel.academics.section.student_courses.label', 'My Courses');
      case AcademicsContent.due_date_catalog:
        return Localization().getStringEx('panel.academics.section.due_date_catalog.label', 'Due Date Catalog');
      case AcademicsContent.my_illini:
        return Localization().getStringEx('panel.academics.section.my_illini.label', 'myIllini');
      case AcademicsContent.skills_self_evaluation:
        return Localization().getStringEx('panel.academics.section.skills_self_evaluation.label', 'Skills Self-Evaluation');
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _buildContentValues();
    } else if (name == Auth2.notifyLoginChanged) {
      _buildContentValues();
    }
  }
}

enum AcademicsContent { events, gies_checklist, uiuc_checklist, canvas_courses, student_courses, due_date_catalog, my_illini, skills_self_evaluation }
