
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/CustomCourses.dart';
import 'package:illinois/ui/academics/EssentialSkillsCoach.dart';
import 'package:illinois/ui/academics/courses/AssignmentPanel.dart';
import 'package:illinois/ui/academics/courses/AssignmentCompletePanel.dart';
import 'package:illinois/ui/academics/courses/ResourcesPanel.dart';
import 'package:illinois/ui/academics/courses/StreakPanel.dart';
import 'package:illinois/ui/academics/courses/UnitInfoPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';


class EssentialSkillsCoachDashboardPanel extends StatefulWidget {
  EssentialSkillsCoachDashboardPanel();

  @override
  State<EssentialSkillsCoachDashboardPanel> createState() => _EssentialSkillsCoachDashboardPanelState();
}

class _EssentialSkillsCoachDashboardPanelState extends State<EssentialSkillsCoachDashboardPanel> implements NotificationsListener {
  Course? _course;
  UserCourse? _userCourse;
  List<UserUnit>? _userCourseUnits;
  CourseConfig? _courseConfig;
  bool _loading = false;

  String? _selectedModuleKey;
  DateTime? _pausedDateTime;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
    ]);

    _loadCourseAndUnits();
    _loadCourseConfig();
    //TODO: check ESC onboarding completed, _hasStartedSkillsCoach, completed BESSI for onboarding sequence

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    } else if (Auth2().isLoggedIn && _hasStartedSkillsCoach) {
      if (_selectedModule != null) {
        return Column(
          children: [
            _buildStreakWidget(),
            Container(
              color: _selectedModulePrimaryColor,
              child: _buildModuleSelection(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  color: Styles().colors.background,
                  child: Column(children: _buildModuleUnitWidgets(),),
                ),
              ),
            ),
          ],
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            Localization().getStringEx('panel.essential_skills_coach.dashboard.content.missing.text', 'Course content could not be loaded. Please try again later.'),
            style: Styles().textStyles.getTextStyle("panel.essential_skills_coach.content.title"),
          ),
        )
      );
    }

    return SingleChildScrollView(child: EssentialSkillsCoach(onStartCourse: _startCourse,));
  }

  bool get _hasStartedSkillsCoach => _userCourse != null;

  Module? get _selectedModule => _userCourse?.course?.searchByKey(moduleKey: _selectedModuleKey) ?? _course?.searchByKey(moduleKey: _selectedModuleKey); //TODO: remove _course option after start course UI
  Color? get _selectedModulePrimaryColor => _selectedModule!.styles?.colors?['primary'] != null ? Styles().colors.getColor(_selectedModule!.styles!.colors!['primary']!) : Styles().colors.fillColorPrimary;
  Color? get _selectedModuleAccentColor => _selectedModule!.styles?.colors?['accent'] != null ? Styles().colors.getColor(_selectedModule!.styles!.colors!['accent']!) : Styles().colors.fillColorSecondary;
  Widget? get _selectedModuleIcon => Styles().images.getImage(_selectedModule!.styles?.images?['icon'] ?? 'skills-question', size: 48);

  @override
  void onNotification(String name, param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  Widget _buildStreakWidget() {
    return Container(
      height: 48,
      color: Styles().colors.fillColorPrimaryVariant,
      child: TextButton(
        onPressed: _userCourse != null ? () {
          Navigator.push(context, CupertinoPageRoute(builder: (context) => StreakPanel(
            userCourse: _userCourse!,
            courseConfig: _courseConfig,
            firstScheduleItemCompleted: UserUnit.firstScheduleItemCompletionFromList(_userCourseUnits ?? []),
          )));
        } : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Styles().colors.surface,
                shape: BoxShape.circle,
              ),
              child: Styles().images.getImage('streak', color: Styles().colors.fillColorPrimary, size: 40.0) ?? Container()
            ),
            SizedBox(width: 8,),
            Text(
              (_userCourse?.streak ?? 0) > 0 ? '${_userCourse!.streak} ' + Localization().getStringEx('panel.essential_skills_coach.streak.days.suffix', "Day Streak!") :
                Localization().getStringEx('panel.essential_skills_coach.dashboard.no_streak.text', 'No Streak'),
              style: Styles().textStyles.getTextStyle("widget.title.light.small.fat"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildModuleSelection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Flexible(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: _selectedModuleIcon,
            ),
          ),
          Flexible(
            flex: 4,
            child: Padding(padding: EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                decoration: BoxDecoration(
                  color: Styles().colors.surface,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(4.0)),
                ),
                child: ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButton(
                      alignment: AlignmentDirectional.centerStart,
                      value: _selectedModuleKey,
                      iconDisabledColor: Styles().colors.fillColorSecondary,
                      iconEnabledColor: Styles().colors.fillColorSecondary,
                      focusColor: Styles().colors.surface,
                      dropdownColor: Styles().colors.surface,
                      underline: Divider(color: Styles().colors.fillColorSecondary, height: 1.0, indent: 16.0, endIndent: 16.0),
                      borderRadius: BorderRadius.all(Radius.circular(4.0)),
                      isExpanded: true,
                      items: _moduleDropdownItems(),
                      onChanged: (String? selected) {
                        setState(() {
                          _selectedModuleKey = selected;
                        });
                      }
                  )
                ),
              )
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildModuleUnitWidgets(){
    List<Widget> moduleUnitWidgets = <Widget>[];
    for (int i = 0; i < (_selectedModule?.units?.length ?? 0); i++) {
      Unit unit = _selectedModule!.units![i];
      UserUnit showUnit = _userCourseUnits?.firstWhere(
        (userUnit) => (userUnit.unit?.key != null) && (userUnit.unit!.key == unit.key) && (_selectedModuleKey != null) && (userUnit.moduleKey == _selectedModuleKey),
        orElse: () => UserUnit.emptyFromUnit(unit, Config().essentialSkillsCoachKey ?? '', current: i == 0)
      ) ?? UserUnit.emptyFromUnit(unit, Config().essentialSkillsCoachKey ?? '', current: i == 0);
      moduleUnitWidgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: _buildUnitInfoWidget(showUnit, i+1),
      ));
      if (CollectionUtils.isNotEmpty(showUnit.userSchedule)) {
        moduleUnitWidgets.addAll(_buildUnitWidgets(showUnit, i+1));
      }
    }
    return moduleUnitWidgets;
  }

  Widget _buildUnitInfoWidget(UserUnit userUnit, int displayNumber){
    return Container(
      color: Styles().colors.fillColorPrimary,
      child: Column(
        children: [
          if (!userUnit.current)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(sprintf(Localization().getStringEx('panel.essential_skills_coach.dashboard.complete_to_unlock.text', 'Complete Unit %d to unlock'), [displayNumber-1]), style: Styles().textStyles.getTextStyle("widget.title.light.regular.fat")),
            ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Unit $displayNumber', style: Styles().textStyles.getTextStyle("widget.title.light.huge.fat")),
                      Text(userUnit.unit?.name ?? "", style: Styles().textStyles.getTextStyle("widget.title.light.regular.fat"))
                    ],
                  ),
                ),
                if (CollectionUtils.isNotEmpty(userUnit.unit?.resourceContent))
                  Flexible(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: ElevatedButton(
                            onPressed: userUnit.current ? () {
                              Navigator.push(context, CupertinoPageRoute(builder: (context) => ResourcesPanel(
                                  color: _selectedModulePrimaryColor,
                                  unitNumber: displayNumber,
                                  contentItems: userUnit.unit!.resourceContent!,
                                  unitName: userUnit.unit?.name ?? "",
                                  moduleIcon: _selectedModuleIcon,
                                  moduleName: _selectedModule?.name ?? '',
                              )));
                            } : null,
                            child: Styles().images.getImage('closed-book'),
                            style: ElevatedButton.styleFrom(
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(16),
                              backgroundColor: Styles().colors.surface,
                              disabledBackgroundColor: Styles().colors.surface,
                            ),
                          ),
                        ),
                        Text(Localization().getStringEx('panel.essential_skills_coach.dashboard.resources.button.label', 'Resources'), style: Styles().textStyles.getTextStyle("widget.title.light.small.fat")),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUnitWidgets(UserUnit userUnit, int displayNumber){
    List<Widget> unitWidgets = [];
    for (int i = 0; i < (userUnit.userSchedule?.length ?? 0); i++) {
      UserScheduleItem item = userUnit.userSchedule![i];
      if ((item.userContent?.length ?? 0) > 1) {
        List<Widget> contentButtons = [];
        for (UserContentReference reference in item.userContent!) {
          Content? content = userUnit.unit?.searchByKey(contentKey: reference.contentKey);
          if (content != null && StringUtils.isNotEmpty(userUnit.unit?.key)) {
            contentButtons.add(_buildContentWidget(userUnit, displayNumber, reference, content, i));
          }
        }
        unitWidgets.add(SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: contentButtons,
          ),
        ));
      } else if ((item.userContent?.length ?? 0) == 1) {
        Content? content = userUnit.unit?.searchByKey(contentKey: item.userContent![0].contentKey);
        if (content != null && StringUtils.isNotEmpty(userUnit.unit?.key)) {
          unitWidgets.add(_buildContentWidget(userUnit, displayNumber, item.userContent![0], content, i));
        }
      }

      unitWidgets.add(SizedBox(height: 16,));
    }
    return unitWidgets;
  }

  Widget _buildContentWidget(UserUnit userUnit, int unitNumber, UserContentReference userContentReference, Content content, int scheduleIndex) {
    int activityNumber = userUnit.unit?.getActivityNumber(scheduleIndex) ?? scheduleIndex;

    bool required = userUnit.unit?.scheduleItems?[scheduleIndex].isRequired ?? false;
    bool isCompleted = (scheduleIndex < userUnit.completed) && userUnit.current;
    bool isCurrent = (scheduleIndex == userUnit.completed) && userUnit.current;
    bool isNextWithCurrentComplete = (scheduleIndex == userUnit.completed + 1) && userUnit.current && (userUnit.currentUserScheduleItem?.isComplete ?? false);
    bool isCompletedOrCurrent = isCompleted || isCurrent;

    bool isFirstIncompleteInScheduleItem = userContentReference.contentKey != null && userUnit.currentUserScheduleItem?.firstIncomplete?.contentKey == userContentReference.contentKey;
    bool shouldHighlight = (isCurrent && userContentReference.isNotComplete && isFirstIncompleteInScheduleItem) || isNextWithCurrentComplete;

    Color? contentColor = content.styles?.colors?['primary'] != null ? Styles().colors.getColor(content.styles!.colors!['primary']!) : Styles().colors.fillColorPrimary;
    Color? borderColor = content.styles?.colors?['accent'] != null ? Styles().colors.getColor(content.styles!.colors!['accent']!) : Styles().colors.fillColorSecondary;
    Color? completedColor = content.styles?.colors?['complete'] != null ? Styles().colors.getColor(content.styles!.colors!['complete']!) : Colors.green;
    Color? incompleteColor = content.styles?.colors?['incomplete'] != null ? Styles().colors.getColor(content.styles!.colors!['incomplete']!) : Colors.grey[700];

    DateTime? nextCourseDayStart;
    if (_courseConfig != null) {
      nextCourseDayStart = _userCourse?.nextScheduleItemUnlockTimeUtc(_courseConfig!);
    }

    double? size = shouldHighlight ? 32.0 : null;
    Widget? iconImage = Styles().images.getImage(content.styles?.images?['icon'], size: size);
    if (content.styles?.images?['icon'] == 'skills-play') {
      iconImage = Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: iconImage,
      );
    }
    if (userContentReference.isComplete && required) {
      iconImage = Styles().images.getImage('skills-check', size: size);
    } else if (!userUnit.current) {
      iconImage = Padding(
        padding: const EdgeInsets.only(left: 4.0, right: 4.0, bottom: 4.0),
        child: Styles().images.getImage('lock', size: size),
      );
    }
    Widget icon = Padding(
      padding: shouldHighlight ? EdgeInsets.zero : EdgeInsets.all(16.0),
      child: Opacity(
        opacity: isCompletedOrCurrent ? 1 : 0.3,
        child: iconImage,
      )
    );
    Widget contentWidget = icon;
    if (shouldHighlight) {
      String? unlockTimeText;
      if (isNextWithCurrentComplete && nextCourseDayStart != null) {
        unlockTimeText = '${AppDateTime().getDisplayDay(dateTimeUtc: nextCourseDayStart, includeAtSuffix: true)} ${AppDateTime().getDisplayTime(dateTimeUtc: nextCourseDayStart)}';
      }
      contentWidget = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  SizedBox(width: 16.0),
                  Text(
                    content.reference?.highlightDisplayText() ?? sprintf(Localization().getStringEx('panel.essential_skills_coach.dashboard.activity.button.label', 'Activity %d'), [activityNumber]),
                    style: Styles().textStyles.getTextStyle("widget.title.light.huge.fat")
                  )
                ]
              ),
            ),
            Text(
              content.reference?.highlightActionText() ?? (isNextWithCurrentComplete ?
                sprintf(Localization().getStringEx('panel.essential_skills_coach.dashboard.activity.button.action.unlock.label', 'Starts %s'), [unlockTimeText ?? 'Tomorrow']) :
                  Localization().getStringEx('panel.essential_skills_coach.dashboard.activity.button.action.label', 'GET STARTED')),
              style: Styles().textStyles.getTextStyle("widget.title.light.medium.fat")
            )
          ]
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ElevatedButton(
        onPressed: userUnit.current ? () {
          Navigator.push(context, CupertinoPageRoute(builder: (context) => !required ? UnitInfoPanel(
              content: content,
              contentReference: userContentReference,
              color: _selectedModulePrimaryColor,
              colorAccent: _selectedModuleAccentColor,
              preview: !isCompletedOrCurrent,
              moduleIcon: _selectedModuleIcon,
              moduleName: _selectedModule?.name ?? '',
            ) : AssignmentPanel(
              content: content,
              contentReference: userContentReference,
              color: _selectedModulePrimaryColor,
              colorAccent: _selectedModuleAccentColor,
              helpContent: (_userCourse?.course ?? _course) != null ? content.getLinkedContent(_userCourse?.course ?? _course) : null,
              preview: !isCompletedOrCurrent,
              courseDayStart: nextCourseDayStart?.subtract(Duration(days: 1)),
              moduleIcon: _selectedModuleIcon,
              moduleName: _selectedModule?.name ?? '',
              unitNumber: unitNumber,
              unitName: userUnit.unit?.name ?? '',
              activityNumber: activityNumber,
            )
          )).then((result) {
            if (result is Map<String, dynamic>) {
              String? moduleKey = _selectedModuleKey;
              if (moduleKey != null && StringUtils.isNotEmpty(userUnit.unit?.key) && StringUtils.isNotEmpty(userContentReference.contentKey)) {
                _updateProgress(moduleKey, userUnit.unit!.key!, result, userContentReference, unitNumber, activityNumber);
              }
            }
          });
        } : null,
        child: contentWidget,
        style: ElevatedButton.styleFrom(
          shape: shouldHighlight ? RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))) : CircleBorder(),
          side: isCurrent && userContentReference.isNotComplete ? BorderSide(color: borderColor ?? Styles().colors.fillColorSecondary, width: 6.0, strokeAlign: BorderSide.strokeAlignOutside) : null,
          padding: EdgeInsets.all(8.0),
          backgroundColor: isCompletedOrCurrent ? (userContentReference.isComplete ? completedColor : contentColor) : incompleteColor,
          disabledBackgroundColor: incompleteColor
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _moduleDropdownItems() {
    List<DropdownMenuItem<String>> dropDownItems = <DropdownMenuItem<String>>[]; //TODO: add option for ESC overview

    for (Module module in _userCourse?.course?.modules ?? _course?.modules ?? []) {
      if (module.key != null && module.name != null && CollectionUtils.isNotEmpty(module.units)) {
        dropDownItems.add(DropdownMenuItem(
          value: module.key,
          child: Text(module.name!, style: Styles().textStyles.getTextStyle("widget.detail.large"))
        ));
      }
    }
    return dropDownItems;
  }

  Future<void> _loadCourseAndUnits() async {
    _userCourse ??= CustomCourses().userCourses?[Config().essentialSkillsCoachKey];
    if (_userCourse == null) {
      if (StringUtils.isNotEmpty(Config().essentialSkillsCoachKey)) {
        _setLoading(true);
        UserCourse? userCourse = await CustomCourses().loadUserCourse(Config().essentialSkillsCoachKey!);
        if (userCourse != null) {
          setStateIfMounted(() {
            _userCourse = userCourse;
            _selectedModuleKey ??= CollectionUtils.isNotEmpty(userCourse.course?.modules) ? userCourse.course!.modules![0].key : null;
            _loading = false;
          });
          await _loadUserCourseUnits();
        } else {
          await _loadCourse();
        }
      }
    } else {
      _selectedModuleKey ??= CollectionUtils.isNotEmpty(_userCourse?.course?.modules) ? _userCourse?.course!.modules![0].key : null;
      await _loadUserCourseUnits();
    }
  }

  Future<void> _loadCourse() async {
    _course ??= CustomCourses().courses?[Config().essentialSkillsCoachKey];
    if (_course == null) {
      if (StringUtils.isNotEmpty(Config().essentialSkillsCoachKey)) {
        _setLoading(true);
        Course? course = await CustomCourses().loadCourse(Config().essentialSkillsCoachKey!);
        if (course != null) {
          setStateIfMounted(() {
            _course = course;
            _selectedModuleKey ??= CollectionUtils.isNotEmpty(course.modules) ? course.modules![0].key : null;
            _loading = false;
          });
        } else {
          _setLoading(false);
        }
      }
    } else {
      setStateIfMounted(() {
        _selectedModuleKey ??= CollectionUtils.isNotEmpty(_course!.modules) ? _course!.modules![0].key : null;
        _loading = false;
      });
    }
  }

  Future<void> _loadUserCourseUnits() async {
    _userCourseUnits ??= CustomCourses().userCourseUnits?[Config().essentialSkillsCoachKey];
    if (_userCourseUnits == null) {
      if (StringUtils.isNotEmpty(Config().essentialSkillsCoachKey)) {
        _setLoading(true);
        List<UserUnit>? userUnits = await CustomCourses().loadUserCourseUnits(Config().essentialSkillsCoachKey!);
        if (userUnits != null) {
          setStateIfMounted(() {
            _userCourseUnits = userUnits;
          });
        }
      }
    }
    _setLoading(false);
  }

  Future<void> _loadCourseConfig() async {
    if (_courseConfig == null && StringUtils.isNotEmpty(Config().essentialSkillsCoachKey)) {
      _setLoading(true);
      CourseConfig? courseConfig = await CustomCourses().loadCourseConfig(Config().essentialSkillsCoachKey!);
      if (courseConfig != null) {
        setStateIfMounted(() {
          _courseConfig = courseConfig;
          _loading = false;
        });
      } else {
        _setLoading(false);
      }
    }
  }

  Future<void> _startCourse() async {
    await _loadCourseAndUnits();
    if (_userCourse == null && StringUtils.isNotEmpty(Config().essentialSkillsCoachKey)) {
      _setLoading(true);
      UserCourse? userCourse = await CustomCourses().createUserCourse(Config().essentialSkillsCoachKey!);
      if (userCourse != null) {
        setStateIfMounted(() {
          _userCourse = userCourse;
        });
      }
    }
    _setLoading(false);
  }

  Future<void> _updateProgress(String moduleKey, String unitKey, Map<String, dynamic> response, UserContentReference userContentReference, int unitNumber, int activityNumber) async {
    _setLoading(true);
    UserUnit? updatedUserUnit = await CustomCourses().updateUserCourseProgress(UserResponse(unitKey: unitKey, contentKey: userContentReference.contentKey!, response: response), courseKey: _userCourse!.course!.key!, moduleKey: moduleKey);
    if (updatedUserUnit != null) {
      if (CollectionUtils.isNotEmpty(_userCourseUnits)) {
        int unitIndex = _userCourseUnits!.indexWhere((userUnit) => userUnit.id != null && userUnit.id == updatedUserUnit.id);
        if (unitIndex >= 0) {
          setStateIfMounted(() {
            _userCourseUnits![unitIndex] = updatedUserUnit;
          });
        } else {
          setStateIfMounted(() {
            _userCourseUnits!.add(updatedUserUnit);
          });
        }
      } else {
        setStateIfMounted(() {
          _userCourseUnits ??= [];
          _userCourseUnits!.add(updatedUserUnit);
        });
      }

      bool earnedPause = false;
      bool extendedStreak = false;
      UserCourse? userCourse = await CustomCourses().loadUserCourse(Config().essentialSkillsCoachKey!);
      if (userCourse != null) {
        earnedPause = (userCourse.pauses ?? 0) > (_userCourse?.pauses ?? 0);
        extendedStreak = (userCourse.streak ?? 0) > (_userCourse?.streak ?? 0);
        setStateIfMounted(() {
          _userCourse = userCourse;
          _loading = false;
        });
      } else {
        _setLoading(false);
      }

      // if the current task was just completed and it extended the user's streak
      if (extendedStreak && userContentReference.isNotComplete && response[UserContent.completeKey] == true) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AssignmentCompletePanel(
          unitNumber: unitNumber,
          activityNumber: activityNumber,
          pauses: earnedPause ? _userCourse?.pauses : null,
          color: _selectedModulePrimaryColor,
        )));
      }
    } else {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    setStateIfMounted(() {
      _loading = value;
    });
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _loadCourseAndUnits();
          _loadCourseConfig();
        }
      }
    }
  }
}
