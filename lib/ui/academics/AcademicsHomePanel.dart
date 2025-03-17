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
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/CheckList.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/appointments/AppointmentsContentWidget.dart';
import 'package:illinois/ui/academics/AcademicsEventsContentWidget.dart';
import 'package:illinois/ui/academics/EssentialSkillsCoachDashboardPanel.dart';
import 'package:illinois/ui/academics/MedicineCoursesContentWidget.dart';
import 'package:illinois/ui/academics/SkillsSelfEvaluation.dart';
import 'package:illinois/ui/academics/StudentCourses.dart';
import 'package:illinois/ui/canvas/CanvasCoursesContentWidget.dart';
import 'package:illinois/ui/canvas/GiesCanvasCoursesContentWidget.dart';
import 'package:illinois/ui/gies/CheckListContentWidget.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:illinois/ui/wellness/todo/WellnessToDoHomeContentWidget.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum AcademicsContent { events,
  gies_checklist, uiuc_checklist,
  canvas_courses, gies_canvas_courses, medicine_courses, student_courses,
  skills_self_evaluation, essential_skills_coach,
  todo_list, due_date_catalog, my_illini, appointments
}

class AcademicsHomePanel extends StatefulWidget with AnalyticsInfo {
  static final String routeName = 'AcademicsHomePanel';
  static const String notifySelectContent = "edu.illinois.rokwire.academics.content.select";

  final AcademicsContent? content;
  final bool rootTabDisplay;

  static Map<AcademicsContent, AnalyticsFeature> contentAnalyticsFeatures = {
    AcademicsContent.events:                 AnalyticsFeature.AcademicsEvents,
    AcademicsContent.gies_checklist:         AnalyticsFeature.AcademicsGiesChecklist,
    AcademicsContent.uiuc_checklist:         AnalyticsFeature.AcademicsChecklist,
    AcademicsContent.canvas_courses:         AnalyticsFeature.AcademicsCanvasCourses,
    AcademicsContent.gies_canvas_courses:    AnalyticsFeature.AcademicsGiesCanvasCourses,
    AcademicsContent.medicine_courses:       AnalyticsFeature.AcademicsMedicineCourses,
    AcademicsContent.student_courses:        AnalyticsFeature.AcademicsStudentCourses,
    AcademicsContent.skills_self_evaluation: AnalyticsFeature.AcademicsSkillsSelfEvaluation,
    AcademicsContent.essential_skills_coach: AnalyticsFeature.AcademicsEssentialSkillsCoach,
    AcademicsContent.todo_list:              AnalyticsFeature.AcademicsToDoList,
    AcademicsContent.due_date_catalog:       AnalyticsFeature.AcademicsDueDateCatalog,
    AcademicsContent.my_illini:              AnalyticsFeature.AcademicsMyIllini,
    AcademicsContent.appointments:           AnalyticsFeature.AcademicsAppointments,
  };

  AcademicsHomePanel({this.content, this.rootTabDisplay = false});

  @override
  _AcademicsHomePanelState createState() => _AcademicsHomePanelState();

  @override
  AnalyticsFeature? get analyticsFeature => contentAnalyticsFeatures[content];

  static Future<void> push(BuildContext context, AcademicsContent content) =>
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AcademicsHomePanel(content: content), settings: RouteSettings(name: AcademicsHomePanel.routeName)));

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
  late List<AcademicsContent> _contentValues;
  bool _contentValuesVisible = false;
  UniqueKey _dueDateCatalogKey = UniqueKey();

  @override
  void initState() {
    NotificationService().subscribe(this, [FlexUI.notifyChanged, Auth2.notifyLoginChanged, AcademicsHomePanel.notifySelectContent]);
    _contentValues = _buildContentValues();
    _selectedContent = _initialSelection;
    if (widget.content == AcademicsContent.my_illini) {
      _onContentItem(widget.content!);
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
        backgroundColor: Styles().colors.background,
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
        color: _skillsSelfEvaluationSelected ? Styles().colors.fillColorPrimaryVariant : Styles().colors.background,
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
            label: _getContentLabel(_selectedContent),
            onTap: _onTapRibbonButton
          ),
        ),
      ),
      Expanded(child:
        Stack(children: [
          Padding(padding: _skillsSelfEvaluationSelected || _isAppointmentsSelected ? EdgeInsets.zero : (_skillsDashboardSelected ? EdgeInsets.only(top: 16) : EdgeInsets.only(top: 16, left: 16, right: 16,)), child:
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
                child: Container(color: Styles().colors.blackTransparent06))));
  }

  Widget _buildContentValuesWidget() {
    List<Widget> sectionList = <Widget>[];
    sectionList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));
    for (AcademicsContent section in _contentValues) {
      if ((_selectedContent != section)) {
        sectionList.add(_buildContentItem(section));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: sectionList)));
  }

  Widget _buildContentItem(AcademicsContent contentItem) {
    return RibbonButton(
        backgroundColor: Styles().colors.white,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        rightIconKey: null,
        rightIcon: _buildContentItemRightIcon(contentItem),
        label: _getContentLabel(contentItem),
        onTap: () => _onTapContentItem(contentItem));
  }

  Widget? _buildContentItemRightIcon(AcademicsContent contentItem) {
    switch (contentItem) {
      case AcademicsContent.my_illini:
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Styles().images.getImage('key', excludeFromSemantics: true) ?? Container(),
          Padding(padding: EdgeInsets.only(left: 6), child: Styles().images.getImage('external-link', excludeFromSemantics: true))
        ]);
      default:
        return null;
    }
  }

  List<AcademicsContent> _buildContentValues() {
    List<AcademicsContent> contentValues = <AcademicsContent>[];
    Map<AcademicsContent, String> contentLabels = <AcademicsContent, String>{};

    List<String>? contentCodes = JsonUtils.listStringsValue(FlexUI()['academics']);
    if (contentCodes != null) {
      for (String code in contentCodes) {
        AcademicsContent? value = _getContentValueFromCode(code);
        if (value != null) {
          contentValues.add(value);
          contentLabels[value] = _getContentLabel(value);
        }
      }
    }

    contentValues.sort((AcademicsContent cont1, AcademicsContent cont2) =>
      SortUtils.compare(contentLabels[cont1]?.toLowerCase(), contentLabels[cont2]?.toLowerCase())
    );

    return contentValues;
  }

  void _updateContentValues() {
    List<AcademicsContent> contentValues = _buildContentValues();
    if (!DeepCollectionEquality().equals(_contentValues, contentValues)) {
      setStateIfMounted(() {
        _contentValues = contentValues;
      });
    }
  }

  AcademicsContent get _initialSelection {
    AcademicsContent? initialContent = _ensureContent(widget.content) ?? _ensureContent(_lastSelectedContent);
    if (initialContent != null) {
      return initialContent;
    }
    else if (_contentValues.contains(AcademicsContent.gies_checklist) && !_isCheckListCompleted(CheckList.giesOnboarding)) {
      return AcademicsContent.gies_checklist;
    } else if (_contentValues.contains(AcademicsContent.gies_canvas_courses)) {
      return AcademicsContent.gies_canvas_courses;
    } else if (_contentValues.contains(AcademicsContent.student_courses)) {
      return AcademicsContent.student_courses;
    }
    else {
      return AcademicsContent.events;
    }
  }

  AcademicsContent? _getContentValueFromCode(String? code) {
    if (code == 'gies_checklist') {
      return AcademicsContent.gies_checklist;
    } else if (code == 'new_student_checklist') {
      return AcademicsContent.uiuc_checklist;
    } else if (code == 'canvas_courses') {
      return AcademicsContent.canvas_courses;
    } else if (code == 'gies_canvas_courses') {
      return AcademicsContent.gies_canvas_courses;
    } else if (code == 'medicine_courses') {
      return AcademicsContent.medicine_courses;
    } else if (code == 'student_courses') {
      return AcademicsContent.student_courses;
    } else if (code == 'academics_events') {
      return AcademicsContent.events;
    } else if (code == 'skills_self_evaluation') {
      return AcademicsContent.skills_self_evaluation;
    } else if (code == 'essential_skills_coach') {
      return AcademicsContent.essential_skills_coach;
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
    }

    if ((launchUrl != null) && (Guide().detailIdFromUrl(launchUrl) == null)) {
      _launchUrl(launchUrl);
    }
    else if (mounted) {
      setState(() {
        _selectedContent = _lastSelectedContent = contentItem;
      });
      Analytics().logPageWidget(_rawContentWidget);
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
      else {
        bool tryInternal = launchInternal && UrlUtils.canLaunchInternal(url);
        AppLaunchUrl.launch(context: context, url: url, tryInternal: tryInternal);
      }
    }
  }

  Widget get _contentWidget {
    return ((_selectedContent == AcademicsContent.gies_checklist) ||
            (_selectedContent == AcademicsContent.uiuc_checklist) ||
            (_selectedContent == AcademicsContent.student_courses) ||
            (_selectedContent == AcademicsContent.todo_list) ||
            (_selectedContent == AcademicsContent.essential_skills_coach) ||
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
        return CheckListContentWidget(contentKey: CheckList.giesOnboarding, analyticsFeature: AnalyticsFeature.AcademicsGiesChecklist,);
      case AcademicsContent.uiuc_checklist:
        return CheckListContentWidget(contentKey: CheckList.uiucOnboarding, analyticsFeature: AnalyticsFeature.AcademicsChecklist,);
      case AcademicsContent.canvas_courses:
        return CanvasCoursesContentWidget();
      case AcademicsContent.gies_canvas_courses:
        return GiesCanvasCoursesContentWidget();
      case AcademicsContent.medicine_courses:
        return MedicineCoursesContentWidget();
      case AcademicsContent.student_courses:
        return StudentCoursesContentWidget();
      case AcademicsContent.skills_self_evaluation:
        return SkillsSelfEvaluation();
      case AcademicsContent.essential_skills_coach:
        return EssentialSkillsCoachDashboardPanel();
      case AcademicsContent.todo_list:
        return WellnessToDoHomeContentWidget(analyticsFeature: AnalyticsFeature.AcademicsToDoList,);
      case AcademicsContent.due_date_catalog:
        String? guideId = Guide().detailIdFromUrl(Config().dateCatalogUrl);
        return (guideId != null) ? GuideDetailWidget(key: _dueDateCatalogKey, guideEntryId: guideId, headingColor: Styles().colors.background, analyticsFeature: AnalyticsFeature.AcademicsDueDateCatalog,) : Container();
      case AcademicsContent.appointments:
        return AppointmentsContentWidget(analyticsFeature: AnalyticsFeature.AcademicsAppointments,);
      default:
        return Container();
    }
  }
  
  bool get _skillsSelfEvaluationSelected => _selectedContent == AcademicsContent.skills_self_evaluation;
  bool get _skillsDashboardSelected => _selectedContent == AcademicsContent.essential_skills_coach;
  bool get _isAppointmentsSelected => _selectedContent == AcademicsContent.appointments;

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
        return Localization().getStringEx('panel.academics.section.canvas_courses.label', 'My Canvas Courses');
      case AcademicsContent.gies_canvas_courses:
        return Localization().getStringEx('panel.academics.section.gies_canvas_courses.label', 'My Gies Canvas Courses');
      case AcademicsContent.medicine_courses:
        return Localization().getStringEx('panel.academics.section.medicine_courses.label', 'My College of Medicine Compliance');
      case AcademicsContent.student_courses:
        return Localization().getStringEx('panel.academics.section.student_courses.label', 'My Courses');
      case AcademicsContent.skills_self_evaluation:
        return Localization().getStringEx('panel.academics.section.skills_self_evaluation.label', 'Skills Self-Evaluation & Career Explorer');
      case AcademicsContent.essential_skills_coach:
        return Localization().getStringEx('panel.academics.section.essential_skills_coach.label', 'Essential Skills Coach');
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
    return ((contentItem != null) && (contentItem != AcademicsContent.my_illini) && contentItems.contains(contentItem)) ? contentItem : null;
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _updateContentValues();
    } else if (name == Auth2.notifyLoginChanged) {
      _updateContentValues();
    } else if (name == AcademicsHomePanel.notifySelectContent) {
      AcademicsContent? contentItem = (param is AcademicsContent) ? param : null;
      if (mounted && (contentItem != null) && (contentItem != _selectedContent)) {
        _onContentItem(contentItem);
      }
    }
  }
}
