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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/CheckList.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/academics/AcademicsAppointmentsContentWidget.dart';
import 'package:illinois/ui/academics/AcademicsEventsContentWidget.dart';
import 'package:illinois/ui/academics/MedicineCoursesContentWidget.dart';
import 'package:illinois/ui/academics/SkillsSelfEvaluation.dart';
import 'package:illinois/ui/academics/StudentCourses.dart';
import 'package:illinois/ui/canvas/CanvasCoursesContentWidget.dart';
import 'package:illinois/ui/gies/CheckListContentWidget.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:illinois/ui/wellness/todo/WellnessToDoHomeContentWidget.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum AcademicsContent { events,
  gies_checklist, uiuc_checklist,
  canvas_courses, medicine_courses, student_courses,
  skills_self_evaluation,
  todo_list, due_date_catalog, my_illini, appointments
}

class AcademicsHomePanel extends StatefulWidget {
  static const String notifySelectContent = "edu.illinois.rokwire.academics.content.select";
  static const String contentItemKey = "content-item";

  final AcademicsContent? content;
  final bool rootTabDisplay;

  final Map<String, dynamic> params = <String, dynamic>{};

  AcademicsHomePanel({this.content, this.rootTabDisplay = false});

  @override
  _AcademicsHomePanelState createState() => _AcademicsHomePanelState();

  static bool get hasState {
    Set<NotificationsListener>? subscribers = NotificationService().subscribers(AcademicsHomePanel.notifySelectContent);
    if (subscribers != null) {
      for (NotificationsListener subscriber in subscribers) {
        if ((subscriber is _AcademicsHomePanelState) && subscriber.mounted) {
          return true;
        }
      }
    }
    return false;
  }
}

class _AcademicsHomePanelState extends State<AcademicsHomePanel>
    with AutomaticKeepAliveClientMixin<AcademicsHomePanel>
    implements NotificationsListener {

  static AcademicsContent? _lastSelectedContent;
  late AcademicsContent _selectedContent;
  List<AcademicsContent>? _contentValues;
  bool _contentValuesVisible = false;
  UniqueKey _dueDateCatalogKey = UniqueKey();

  @override
  void initState() {
    NotificationService().subscribe(this, [FlexUI.notifyChanged, Auth2.notifyLoginChanged, AcademicsHomePanel.notifySelectContent]);
    _buildContentValues();
    _initSelectedContentItem();
    if (_initialContentItem == AcademicsContent.my_illini) {
      _onContentItem(_initialContentItem!);
    }
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
        child: Semantics(
          hint:  Localization().getStringEx("dropdown.hint", "DropDown"),
          container: true,
          child: RibbonButton(
            textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat.secondary"),
            backgroundColor: Styles().colors!.white,
            borderRadius: BorderRadius.all(Radius.circular(5)),
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
            rightIconKey: (_contentValuesVisible ? 'chevron-up' : 'chevron-down'),
            label: _getContentLabel(_selectedContent),
            onTap: _onTapRibbonButton
          ),
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
        rightIconKey: null,
        rightIcon: _buildContentItemRightIcon(contentItem),
        label: _getContentLabel(contentItem),
        onTap: () => _onTapContentItem(contentItem));
  }

  Widget? _buildContentItemRightIcon(AcademicsContent contentItem) {
    switch (contentItem) {
      case AcademicsContent.my_illini:
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Styles().images?.getImage('key', excludeFromSemantics: true) ?? Container(),
          Padding(padding: EdgeInsets.only(left: 6), child: Styles().images?.getImage('external-link', excludeFromSemantics: true))
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
    AcademicsContent? initialContent = _ensureContent(_initialContentItem) ?? _ensureContent(_lastSelectedContent);
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
    } else if (code == 'medicine_courses') {
      return AcademicsContent.medicine_courses;
    } else if (code == 'student_courses') {
      return AcademicsContent.student_courses;
    } else if (code == 'academics_events') {
      return AcademicsContent.events;
    } else if (code == 'skills_self_evaluation') {
      return AcademicsContent.skills_self_evaluation;
    } else if (code == 'todo_list') {
      return AcademicsContent.todo_list;
    } else if (code == 'due_date_catalog') {
      return AcademicsContent.due_date_catalog;
    } else if (code == 'my_illini') {
      return AcademicsContent.my_illini;
    } else if (code == 'appointments') {
      return AcademicsContent.appointments;
    } else {
      return null;
    }
  }

  void _onTapContentItem(AcademicsContent contentItem) {
    Analytics().logSelect(target: '$contentItem');
    _changeSettingsContentValuesVisibility();
    NotificationService().notify(AcademicsHomePanel.notifySelectContent, contentItem);
  }

  void _onContentItem(AcademicsContent contentItem) {
    String? launchUrl;
    if (contentItem == AcademicsContent.my_illini) {
      // Open My Illini in an external browser
      //_onMyIlliniSelected();
      launchUrl = Config().myIlliniUrl;
    } else if (contentItem == AcademicsContent.due_date_catalog) {
      // Open Due Date Catalog in an external browser
      launchUrl = Config().dateCatalogUrl;
    } else {
      _selectedContent = _lastSelectedContent = contentItem;
    }

    if ((launchUrl != null) && (Guide().detailIdFromUrl(launchUrl) == null)) {
      _launchUrl(launchUrl);
    }
    else {
      _selectedContent = _lastSelectedContent = contentItem;
    }
    if (mounted) {
      setState(() {});
    }
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

  /*void _onMyIlliniSelected() {
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
  }*/

  /*void _onTapDueDateCatalog() {
    Analytics().logSelect(target: "Due Date Catalog");
    if (StringUtils.isNotEmpty(Config().dateCatalogUrl)) {
      Uri? uri = Uri.tryParse(Config().dateCatalogUrl!);
      if (uri != null) {
        launchUrl(uri);
      }
    }
  }*/

  void _launchUrl(String? url, { bool launchInternal = false}) {
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else if (launchInternal && UrlUtils.launchInternal(url)){
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      }
      else {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          UrlUtils.launchExternal(url);
        }
      }
    }
  }

  Widget get _contentWidget {
    return ((_selectedContent == AcademicsContent.gies_checklist) ||
            (_selectedContent == AcademicsContent.uiuc_checklist) ||
            (_selectedContent == AcademicsContent.student_courses) ||
            (_selectedContent == AcademicsContent.appointments) ||
            (_selectedContent == AcademicsContent.events)) ?
      _rawContentWidget :
      SingleChildScrollView(child:
        Padding(padding: EdgeInsets.only(bottom: 16), child:
          _rawContentWidget
        ),
      );
  }

  Widget get _rawContentWidget {
    // There is no content for AcademicsContent.my_illini - it is a web url opened in an external browser
    switch (_selectedContent) {
      case AcademicsContent.events:
        return AcademicsEventsContentWidget();
      case AcademicsContent.gies_checklist:
        return CheckListContentWidget(contentKey: CheckList.giesOnboarding);
      case AcademicsContent.uiuc_checklist:
        return CheckListContentWidget(contentKey: CheckList.uiucOnboarding);
      case AcademicsContent.canvas_courses:
        return CanvasCoursesContentWidget();
      case AcademicsContent.medicine_courses:
        return MedicineCoursesContentWidget();
      case AcademicsContent.student_courses:
        return StudentCoursesContentWidget();
      case AcademicsContent.skills_self_evaluation:
        return SkillsSelfEvaluation();
      case AcademicsContent.todo_list:
        return WellnessToDoHomeContentWidget();
      case AcademicsContent.due_date_catalog:
        String? guideId = Guide().detailIdFromUrl(Config().dateCatalogUrl);
        return (guideId != null) ? GuideDetailWidget(key: _dueDateCatalogKey, guideEntryId: guideId, headingColor: Styles().colors?.background) : Container();
      case AcademicsContent.appointments:
        return AcademicsAppointmentsContentWidget();
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
        return Localization().getStringEx('panel.academics.section.events.label', 'Speakers & Seminars');
      case AcademicsContent.gies_checklist:
        return Localization().getStringEx('panel.academics.section.gies_checklist.label', 'iDegrees New Student Checklist');
      case AcademicsContent.uiuc_checklist:
        return Localization().getStringEx('panel.academics.section.uiuc_checklist.label', 'New Student Checklist');
      case AcademicsContent.canvas_courses:
        return Localization().getStringEx('panel.academics.section.canvas_courses.label', 'My Gies Canvas Courses');
      case AcademicsContent.medicine_courses:
        return Localization().getStringEx('panel.academics.section.medicine_courses.label', 'My College of Medicine Compliance');
      case AcademicsContent.student_courses:
        return Localization().getStringEx('panel.academics.section.student_courses.label', 'My Courses');
      case AcademicsContent.skills_self_evaluation:
        return Localization().getStringEx('panel.academics.section.skills_self_evaluation.label', 'Skills Self-Evaluation');
      case AcademicsContent.todo_list:
        return Localization().getStringEx('panel.academics.section.todo_list.label', 'To-Do List');
      case AcademicsContent.due_date_catalog:
        return Localization().getStringEx('panel.academics.section.due_date_catalog.label', 'Due Date Catalog');
      case AcademicsContent.my_illini:
        return Localization().getStringEx('panel.academics.section.my_illini.label', 'myIllini');
      case AcademicsContent.appointments:
        return Localization().getStringEx('panel.academics.section.appointments.label', 'Appointments');
    }
  }

  AcademicsContent? _ensureContent(AcademicsContent? contentItem, {List<AcademicsContent>? contentItems}) {
    contentItems ??= _contentValues;
    return ((contentItem != null) && (contentItem != AcademicsContent.my_illini) && contentItems!.contains(contentItem)) ? contentItem : null;
  }

  AcademicsContent? get _initialContentItem => widget.params[AcademicsHomePanel.contentItemKey] ?? widget.content;

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _buildContentValues();
    } else if (name == Auth2.notifyLoginChanged) {
      _buildContentValues();
    } else if (name == AcademicsHomePanel.notifySelectContent) {
      AcademicsContent? contentItem = (param is AcademicsContent) ? param : null;
      if (mounted && (contentItem != null) && (contentItem != _selectedContent)) {
        _onContentItem(contentItem);
      }
    }
  }
}
