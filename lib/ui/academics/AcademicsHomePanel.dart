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
import 'package:illinois/service/Storage.dart';
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

enum AcademicsContentType { events,
  gies_checklist, uiuc_checklist,
  canvas_courses, gies_canvas_courses, medicine_courses, student_courses,
  skills_self_evaluation, essential_skills_coach,
  todo_list, due_date_catalog, my_illini, appointments
}

class AcademicsHomePanel extends StatefulWidget with AnalyticsInfo {
  static final String routeName = 'AcademicsHomePanel';
  static const String notifySelectContent = "edu.illinois.rokwire.academics.content.select";

  final AcademicsContentType? contentType;
  final bool rootTabDisplay;

  AcademicsHomePanel({this.contentType, this.rootTabDisplay = false});

  @override
  _AcademicsHomePanelState createState() => _AcademicsHomePanelState();

  @override
  AnalyticsFeature? get analyticsFeature => state?._selectedContentType.analyticsFeature ?? contentType?.analyticsFeature ?? AnalyticsFeature.Academics;

  static void present(BuildContext context, AcademicsContentType content) {
    if (hasState) {
      Navigator.of(context).popUntil((route) => (route.settings.name == routeName) || (route.isFirst));
      NotificationService().notify(notifySelectContent, content);
    }
    else {
      push(context, content);
    }
  }

  static Future<void> push(BuildContext context, AcademicsContentType content) =>
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AcademicsHomePanel(contentType: content), settings: RouteSettings(name: AcademicsHomePanel.routeName)));

  static bool get hasState => (state != null);

  static _AcademicsHomePanelState? get state {
    Set<NotificationsListener>? subscribers = NotificationService().subscribers(AcademicsHomePanel.notifySelectContent);
    if (subscribers != null) {
      for (NotificationsListener subscriber in subscribers) {
        if ((subscriber is _AcademicsHomePanelState) && subscriber.mounted) {
          return subscriber;
        }
      }
    }
    return null;
  }
}

class _AcademicsHomePanelState extends State<AcademicsHomePanel>
    with NotificationsListener, AutomaticKeepAliveClientMixin<AcademicsHomePanel> {

  late AcademicsContentType _selectedContentType;
  late List<AcademicsContentType> _contentTypes;
  bool _contentValuesVisible = false;
  UniqueKey _dueDateCatalogKey = UniqueKey();

  @override
  void initState() {
    NotificationService().subscribe(this, [FlexUI.notifyChanged, Auth2.notifyLoginChanged, AcademicsHomePanel.notifySelectContent]);
    _contentTypes = _buildContentTypes();
    _selectedContentType = _ensureContentType(widget.contentType, contentTypes: _contentTypes) ??
      _ensureContentType(Storage()._academicsContentType, contentTypes: _contentTypes) ??
      _defaultContentType(contentTypes: _contentTypes);

    if (widget.contentType?.canSelect == true) {
      _onContentItem(widget.contentType!);
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
            title: _selectedContentType.displayTitle,
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
    return Visibility(visible: _contentValuesVisible, child:
      Positioned.fill(child:
        Stack(children: <Widget>[
          _buildContentDismissLayer(),
          _dropdownList
        ])
      )
    );
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

  Widget get _dropdownList {
    List<Widget> sectionList = <Widget>[];
    sectionList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));
    for (AcademicsContentType contentType in _contentTypes) {
      sectionList.add(RibbonButton(
        backgroundColor: Styles().colors.white,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        textStyle: Styles().textStyles.getTextStyle((_selectedContentType == contentType) ? 'widget.button.title.medium.fat.secondary' : 'widget.button.title.medium.fat'),
        rightIconKey: null, //(_selectedContentType == contentType) ? 'check-accent' : null,
        rightIcon: _dropdownItemIcon(contentType),
        title: contentType.displayTitle,
        onTap: () => _onTapContentItem(contentType)
      ));
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: sectionList)));
  }

  Widget? _dropdownItemIcon(AcademicsContentType contentType) {
    if (contentType == AcademicsContentType.my_illini) {
      return Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
        Styles().images.getImage('key', excludeFromSemantics: true) ?? Container(),
        Container(width: 6,),
        Styles().images.getImage('external-link', excludeFromSemantics: true) ?? Container()
      ]);
    }
    else if (contentType == _selectedContentType) {
      return Styles().images.getImage('check-accent', excludeFromSemantics: true);
    }
    else {
      return null;
    }
  }

  static List<AcademicsContentType> _buildContentTypes() {
    List<AcademicsContentType> contentTypes = <AcademicsContentType>[];
    List<String>? contentCodes = JsonUtils.listStringsValue(FlexUI()['academics']);
    if (contentCodes != null) {
      for (String code in contentCodes) {
        AcademicsContentType? value = AcademicsContentTypeImpl.fromJsonString(code);
        if (value != null) {
          contentTypes.add(value);
        }
      }
    }

    contentTypes.sortAlphabeticalIgnoreCase();
    return contentTypes;
  }

  static AcademicsContentType? _ensureContentType(AcademicsContentType? contentType, { List<AcademicsContentType>? contentTypes }) =>
    ((contentType != null) && contentType.canSelect && (contentTypes?.contains(contentType) != false)) ? contentType : null;

  static AcademicsContentType _defaultContentType({List<AcademicsContentType>? contentTypes}) {
    if ((contentTypes?.contains(AcademicsContentType.gies_checklist) == true) && !_isCheckListCompleted(CheckList.giesOnboarding)) {
      return AcademicsContentType.gies_checklist;
    } else if (contentTypes?.contains(AcademicsContentType.gies_canvas_courses) == true) {
      return AcademicsContentType.gies_canvas_courses;
    } else if (contentTypes?.contains(AcademicsContentType.student_courses) == true) {
      return AcademicsContentType.student_courses;
    } else if (contentTypes?.contains(AcademicsContentType.events) == true) {
      return AcademicsContentType.events;
    } else {
      return AcademicsContentType.appointments;
    }
  }

  void _updateContentValues() {
    List<AcademicsContentType> contentValues = _buildContentTypes();
    if (!DeepCollectionEquality().equals(_contentTypes, contentValues)) {
      setStateIfMounted(() {
        _contentTypes = contentValues;
      });
    }
  }

  void _onTapContentItem(AcademicsContentType contentType) {
    Analytics().logSelect(target: '$contentType');
    _changeSettingsContentValuesVisibility();
    NotificationService().notify(AcademicsHomePanel.notifySelectContent, contentType);
  }

  void _onContentItem(AcademicsContentType contentType) {
    String? launchUrl;
    if (contentType == AcademicsContentType.my_illini) {
      // Open myIllini in an external browser
      //_onMyIlliniSelected();
      launchUrl = Config().myIlliniUrl;
    } else if (contentType == AcademicsContentType.due_date_catalog) {
      // Open Due Date Catalog in an external browser
      launchUrl = Config().dateCatalogUrl;
    }

    if ((launchUrl != null) && (Guide().detailIdFromUrl(launchUrl) == null)) {
      _launchUrl(launchUrl);
    }
    else if (mounted) {
      setState(() {
        Storage()._academicsContentType = _selectedContentType = contentType;
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
          Localization().getStringEx('panel.browse.label.offline.my_illini', 'myIllini not available while offline.'));
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
      //       'widget.home.campus_resources.header.my_illini.title', 'myIllini');
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
        AppLaunchUrl.launch(context: context, url: url, tryInternal: launchInternal);
      }
    }
  }

  Widget get _contentWidget =>
    ((_selectedContentType == AcademicsContentType.gies_checklist) ||
    (_selectedContentType == AcademicsContentType.uiuc_checklist) ||
    (_selectedContentType == AcademicsContentType.student_courses) ||
    (_selectedContentType == AcademicsContentType.todo_list) ||
    (_selectedContentType == AcademicsContentType.essential_skills_coach) ||
    (_selectedContentType == AcademicsContentType.appointments) ||
    (_selectedContentType == AcademicsContentType.events)) ?
      Padding(padding: EdgeInsets.zero, child: _rawContentWidget) :
      SingleChildScrollView(child:
        Padding(padding: EdgeInsets.only(bottom: 16), child: _rawContentWidget),
      );

  Widget? get _rawContentWidget {
    // There is no content for AcademicsContent.my_illini - it is a web url opened in an external browser
    switch (_selectedContentType) {
      case AcademicsContentType.events: return AcademicsEventsContentWidget();
      case AcademicsContentType.gies_checklist: return CheckListContentWidget(contentKey: CheckList.giesOnboarding, analyticsFeature: AnalyticsFeature.AcademicsGiesChecklist,);
      case AcademicsContentType.uiuc_checklist: return CheckListContentWidget(contentKey: CheckList.uiucOnboarding, analyticsFeature: AnalyticsFeature.AcademicsChecklist,);
      case AcademicsContentType.canvas_courses: return CanvasCoursesContentWidget();
      case AcademicsContentType.gies_canvas_courses: return GiesCanvasCoursesContentWidget();
      case AcademicsContentType.medicine_courses: return MedicineCoursesContentWidget();
      case AcademicsContentType.student_courses: return StudentCoursesContentWidget();
      case AcademicsContentType.skills_self_evaluation: return SkillsSelfEvaluation();
      case AcademicsContentType.essential_skills_coach: return EssentialSkillsCoachDashboardPanel();
      case AcademicsContentType.todo_list: return WellnessToDoHomeContentWidget(analyticsFeature: AnalyticsFeature.AcademicsToDoList,);
      case AcademicsContentType.due_date_catalog:
        String? guideId = Guide().detailIdFromUrl(Config().dateCatalogUrl);
        return (guideId != null) ? GuideDetailWidget(key: _dueDateCatalogKey, guideEntryId: guideId, headingColor: Styles().colors.background, analyticsFeature: AnalyticsFeature.AcademicsDueDateCatalog,) : null;
      case AcademicsContentType.appointments: return AppointmentsContentWidget(analyticsFeature: AnalyticsFeature.AcademicsAppointments,);
      default: return null;
    }
  }
  
  bool get _skillsSelfEvaluationSelected => _selectedContentType == AcademicsContentType.skills_self_evaluation;
  bool get _skillsDashboardSelected => _selectedContentType == AcademicsContentType.essential_skills_coach;
  bool get _isAppointmentsSelected => _selectedContentType == AcademicsContentType.appointments;

  static bool _isCheckListCompleted(String contentKey) {
    int stepsCount = CheckList(contentKey).progressSteps?.length ?? 0;
    int completedStepsCount = CheckList(contentKey).completedStepsCount;
    return (stepsCount == completedStepsCount);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _updateContentValues();
    } else if (name == Auth2.notifyLoginChanged) {
      _updateContentValues();
    } else if (name == AcademicsHomePanel.notifySelectContent) {
      AcademicsContentType? contentType = (param is AcademicsContentType) ? param : null;
      if (mounted && (contentType != null) && (contentType != _selectedContentType)) {
        _onContentItem(contentType);
      }
    }
  }
}

// AcademicsContentType

extension AcademicsContentTypeImpl on AcademicsContentType {

  String get displayTitle => displayTitleLng();
  String get displayTitleEn => displayTitleLng('en');

  String displayTitleLng([String? language]) {
    switch (this) {
      case AcademicsContentType.events: return Localization().getStringEx('panel.academics.section.events.label', 'Speakers & Seminars');
      case AcademicsContentType.gies_checklist: return Localization().getStringEx('panel.academics.section.gies_checklist.label', 'iDegrees New Student Checklist');
      case AcademicsContentType.uiuc_checklist: return Localization().getStringEx('panel.academics.section.uiuc_checklist.label', 'New Student Checklist');
      case AcademicsContentType.canvas_courses: return Localization().getStringEx('panel.academics.section.canvas_courses.label', 'My Canvas Courses');
      case AcademicsContentType.gies_canvas_courses: return Localization().getStringEx('panel.academics.section.gies_canvas_courses.label', 'My Gies Canvas Courses');
      case AcademicsContentType.medicine_courses: return Localization().getStringEx('panel.academics.section.medicine_courses.label', 'My College of Medicine Compliance');
      case AcademicsContentType.student_courses: return Localization().getStringEx('panel.academics.section.student_courses.label', 'My Courses');
      case AcademicsContentType.skills_self_evaluation: return Localization().getStringEx('panel.academics.section.skills_self_evaluation.label', 'Skills Self-Evaluation & Career Explorer');
      case AcademicsContentType.essential_skills_coach: return Localization().getStringEx('panel.academics.section.essential_skills_coach.label', 'Essential Skills Coach');
      case AcademicsContentType.todo_list: return Localization().getStringEx('panel.academics.section.todo_list.label', 'To-Do List');
      case AcademicsContentType.due_date_catalog: return Localization().getStringEx('panel.academics.section.due_date_catalog.label', 'Due Date Catalog');
      case AcademicsContentType.my_illini: return Localization().getStringEx('panel.academics.section.my_illini.label', 'myIllini');
      case AcademicsContentType.appointments: return Localization().getStringEx('panel.academics.section.appointments.label', 'Appointments');
    }
  }

  String get jsonString {
    switch (this) {
      case AcademicsContentType.events: return 'academics_events';
      case AcademicsContentType.gies_checklist: return 'gies_checklist';
      case AcademicsContentType.uiuc_checklist: return 'new_student_checklist';
      case AcademicsContentType.canvas_courses: return 'canvas_courses';
      case AcademicsContentType.gies_canvas_courses: return 'gies_canvas_courses';
      case AcademicsContentType.medicine_courses: return 'medicine_courses';
      case AcademicsContentType.student_courses: return 'student_courses';
      case AcademicsContentType.skills_self_evaluation: return 'skills_self_evaluation';
      case AcademicsContentType.essential_skills_coach: return 'essential_skills_coach';
      case AcademicsContentType.todo_list: return 'todo_list';
      case AcademicsContentType.due_date_catalog: return 'due_date_catalog';
      case AcademicsContentType.my_illini: return 'my_illini';
      case AcademicsContentType.appointments: return 'appointments';
    }
  }

  static AcademicsContentType? fromJsonString(String? value) {
    switch (value) {
      case 'academics_events': return AcademicsContentType.events;
      case 'gies_checklist':  return AcademicsContentType.gies_checklist;
      case 'new_student_checklist': return AcademicsContentType.uiuc_checklist;
      case 'canvas_courses': return AcademicsContentType.canvas_courses;
      case 'gies_canvas_courses': return AcademicsContentType.gies_canvas_courses;
      case 'medicine_courses': return AcademicsContentType.medicine_courses;
      case 'student_courses': return AcademicsContentType.student_courses;
      case 'skills_self_evaluation': return AcademicsContentType.skills_self_evaluation;
      case 'essential_skills_coach': return AcademicsContentType.essential_skills_coach;
      case 'todo_list': return AcademicsContentType.todo_list;
      case 'due_date_catalog': return AcademicsContentType.due_date_catalog;
      case 'my_illini': return AcademicsContentType.my_illini;
      case 'appointments': return AcademicsContentType.appointments;
      default: return null;
    }
  }

  AnalyticsFeature? get analyticsFeature {
    switch (this) {
      case AcademicsContentType.events:                 return AnalyticsFeature.AcademicsEvents;
      case AcademicsContentType.gies_checklist:         return AnalyticsFeature.AcademicsGiesChecklist;
      case AcademicsContentType.uiuc_checklist:         return AnalyticsFeature.AcademicsChecklist;
      case AcademicsContentType.canvas_courses:         return AnalyticsFeature.AcademicsCanvasCourses;
      case AcademicsContentType.gies_canvas_courses:    return AnalyticsFeature.AcademicsGiesCanvasCourses;
      case AcademicsContentType.medicine_courses:       return AnalyticsFeature.AcademicsMedicineCourses;
      case AcademicsContentType.student_courses:        return AnalyticsFeature.AcademicsStudentCourses;
      case AcademicsContentType.skills_self_evaluation: return AnalyticsFeature.AcademicsSkillsSelfEvaluation;
      case AcademicsContentType.essential_skills_coach: return AnalyticsFeature.AcademicsEssentialSkillsCoach;
      case AcademicsContentType.todo_list:              return AnalyticsFeature.AcademicsToDoList;
      case AcademicsContentType.due_date_catalog:       return AnalyticsFeature.AcademicsDueDateCatalog;
      case AcademicsContentType.my_illini:              return AnalyticsFeature.AcademicsMyIllini;
      case AcademicsContentType.appointments:           return AnalyticsFeature.AcademicsAppointments;
    }
  }

  bool get canSelect {
    switch (this) {
      case AcademicsContentType.due_date_catalog: return false;
      case AcademicsContentType.my_illini: return false;
      default: return true;
    }
  }
}

extension _AcademicsContentTypeList on List<AcademicsContentType> {
  // void sortAlphabetical() => sort((AcademicsContentType t1, AcademicsContentType t2) => t1.displayTitle.compareTo(t2.displayTitle));
  void sortAlphabeticalIgnoreCase() => sort((AcademicsContentType t1, AcademicsContentType t2) => compareAsciiLowerCase(t1.displayTitle, t2.displayTitle));
}

extension _StorageWellnessExt on Storage {
  AcademicsContentType? get _academicsContentType => AcademicsContentTypeImpl.fromJsonString(academicsContentType);
  set _academicsContentType(AcademicsContentType? value) => academicsContentType = value?.jsonString;
}
