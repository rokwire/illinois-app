
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

  @override
  void initState() {
    _loadCourseAndUnits();
    _loadCourseConfig();
    //TODO: check ESC onboarding completed, _hasStartedSkillsCoach, completed BESSI for onboarding sequence

    super.initState();
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
              child: _buildModuleSelection(_selectedModule!.styles?.images?['icon'] ?? 'skills-question'),
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

  @override
  void onNotification(String name, param) {
    // TODO: implement onNotification
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
            Icon(
              Icons.lightbulb_circle,
              color: Colors.white,
              size: 30.0,
            ),
            SizedBox(width: 8,),
            //TODO: update 'No Streak' string
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

  Widget _buildModuleSelection(String iconKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Flexible(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Styles().images.getImage(iconKey, size: 48),
            ),
          ),
          Flexible(
            flex: 4,
            child: Padding(padding: EdgeInsets.only(right: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Styles().colors.surface,
                  shape: BoxShape.rectangle,
                  border: Border.all(color: Styles().colors.surfaceAccent, width: 1), borderRadius: BorderRadius.all(Radius.circular(4.0)),
                ),
                child: ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButton(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      alignment: AlignmentDirectional.centerStart,
                      value: _selectedModuleKey,
                      iconDisabledColor: Styles().colors.fillColorSecondary,
                      iconEnabledColor: Styles().colors.fillColorSecondary,
                      focusColor: Styles().colors.fillColorSecondary,
                      dropdownColor: Styles().colors.surface,
                      underline: Divider(color: Styles().colors.fillColorSecondary, height: 1.0),
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
        (userUnit) => (userUnit.unit?.key != null) && (userUnit.unit!.key == unit.key),
        orElse: () => UserUnit.emptyFromUnit(unit, Config().essentialSkillsCoachKey ?? '', current: i == 0)
      ) ?? UserUnit.emptyFromUnit(unit, Config().essentialSkillsCoachKey ?? '', current: i == 0);
      moduleUnitWidgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: _buildUnitInfoWidget(showUnit, i+1),
      ));
      if (CollectionUtils.isNotEmpty(showUnit.unit!.scheduleItems)) {
        moduleUnitWidgets.addAll(_buildUnitWidgets(showUnit));
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
                Flexible(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, CupertinoPageRoute(builder: (context) => ResourcesPanel(
                                color: _selectedModulePrimaryColor,
                                colorAccent: _selectedModuleAccentColor,
                                unitNumber: displayNumber,
                                contentItems: userUnit.unit?.resourceContent,
                                unitName: userUnit.unit?.name ?? ""
                            )));
                          },
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: Styles().colors.fillColorPrimary,
                            size: 30.0,
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(16),
                            backgroundColor: Colors.white,
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

  List<Widget> _buildUnitWidgets(UserUnit userUnit){
    List<Widget> unitWidgets = [];
    for (int i = 0; i < (userUnit.unit?.scheduleItems?.length ?? 0); i++) {
      ScheduleItem item = userUnit.unit!.scheduleItems![i];
      if ((item.userContent?.length ?? 0) > 1) {
        List<Widget> contentButtons = [];
        for (UserContent userContent in item.userContent!) {
          Content? content = userUnit.unit?.searchByKey(contentKey: userContent.contentKey);
          if (content != null && StringUtils.isNotEmpty(userUnit.unit?.key)) {
            contentButtons.add(_buildContentWidget(userUnit, userContent, content, i));
          }
        }
        unitWidgets.add(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: contentButtons,
        ));
      } else if ((item.userContent?.length ?? 0) == 1) {
        Content? content = userUnit.unit?.searchByKey(contentKey: item.userContent![0].contentKey);
        if (content != null && StringUtils.isNotEmpty(userUnit.unit?.key)) {
          unitWidgets.add(_buildContentWidget(userUnit, item.userContent![0], content, i));
        }
      }

      unitWidgets.add(SizedBox(height: 16,));
    }
    return unitWidgets;
  }

  Widget _buildContentWidget(UserUnit userUnit, UserContent userContent, Content content, int scheduleIndex) {
    Unit unit = userUnit.unit!;
    int scheduleStart = unit.scheduleStart!;

    bool required = scheduleIndex >= scheduleStart;
    bool isCompleted = (scheduleIndex < userUnit.completed) && userUnit.current;
    bool isCurrent = (scheduleIndex == userUnit.completed) && userUnit.current;
    bool isNextWithCurrentComplete = (scheduleIndex == userUnit.completed + 1) && userUnit.current && (unit.scheduleItems?[userUnit.completed].isComplete ?? false);
    bool isCompletedOrCurrent = isCompleted || isCurrent;
    bool shouldHighlight = (isCurrent && !userContent.hasData) || isNextWithCurrentComplete;

    Color? contentColor = content.styles?.colors?['primary'] != null ? Styles().colors.getColor(content.styles!.colors!['primary']!) : Styles().colors.fillColorSecondary;
    Color? completedColor = content.styles?.colors?['complete'] != null ? Styles().colors.getColor(content.styles!.colors!['complete']!) : Colors.green;
    Color? incompleteColor = content.styles?.colors?['incomplete'] != null ? Styles().colors.getColor(content.styles!.colors!['incomplete']!) : Colors.grey[700];

    double? size = shouldHighlight ? 24.0 : null;
    Widget icon = Padding(
      padding: shouldHighlight ? EdgeInsets.zero : EdgeInsets.all(8.0),
      child: Opacity(opacity: isCompletedOrCurrent ? 1 : 0.3, child: (userContent.hasData && required ? Styles().images.getImage("skills-check", size: size) :
        Styles().images.getImage(content.styles?.images?['icon'], size: size)
      )) ?? Container()
    );
    Widget contentWidget = icon;
    if (shouldHighlight) {
      String? unlockTimeText;
      if (isNextWithCurrentComplete && _courseConfig != null) {
        DateTime? unlockTimeUtc = _userCourse?.nextScheduleItemUnlockTimeUtc(_courseConfig!);
        if (unlockTimeUtc != null) {
          unlockTimeText = '${AppDateTime().getDisplayDay(dateTimeUtc: unlockTimeUtc, includeAtSuffix: true)} ${AppDateTime().getDisplayTime(dateTimeUtc: unlockTimeUtc)}';
        }
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
                    content.reference?.highlightDisplayText() ?? Localization().getStringEx('panel.essential_skills_coach.dashboard.activity.button.label', 'Activity') + ' ${scheduleIndex - scheduleStart + 1}',
                    style: Styles().textStyles.getTextStyle("widget.title.light.large.fat")
                  )
                ]
              ),
            ),
            Text(
              content.reference?.highlightActionText() ?? (isNextWithCurrentComplete ?
                sprintf(Localization().getStringEx('panel.essential_skills_coach.dashboard.activity.button.action.unlock.label', 'Starts %s'), [unlockTimeText ?? 'tomorrow']) :
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
              data: userContent.userData,
              color: _selectedModulePrimaryColor,
              colorAccent: _selectedModuleAccentColor,
              preview: !isCompletedOrCurrent,
            ) : AssignmentPanel(
              content: content,
              data: userContent.userData,
              color: _selectedModulePrimaryColor,
              colorAccent: _selectedModuleAccentColor,
              isCurrent: isCurrent,
              helpContent: (_userCourse?.course ?? _course) != null ? content.getLinkedContent(_userCourse?.course ?? _course) : null,
              preview: !isCompletedOrCurrent,
            )
          )).then((result) {
            if (result is Map<String, dynamic>) {
              _updateProgress(unit.key!, userContent, content, result);
            }
          });
        } : null,
        child: contentWidget,
        style: ElevatedButton.styleFrom(
          shape: shouldHighlight ? RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))) : CircleBorder(),
          side: isCurrent && !userContent.hasData ? BorderSide(color: _selectedModulePrimaryColor ?? Styles().colors.fillColorPrimary, width: 6.0, strokeAlign: BorderSide.strokeAlignOutside) : null,
          padding: EdgeInsets.all(8.0),
          backgroundColor: isCompletedOrCurrent ? (!required || userContent.hasData ? completedColor : contentColor) : incompleteColor,
          disabledBackgroundColor: incompleteColor
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _moduleDropdownItems() {
    List<DropdownMenuItem<String>> dropDownItems = <DropdownMenuItem<String>>[
      // DropdownMenuItem(value: null, child: Text('Skills Coach Overview', style: Styles().textStyles.getTextStyle("widget.detail.large"))) //TODO: add option for ESC overview
    ];

    for (Module module in _userCourse?.course?.modules ?? _course?.modules ?? []) {
      if (module.key != null && module.name != null/* && CollectionUtils.isNotEmpty(module.units)*/) { // TODO remove comment
        dropDownItems.add(DropdownMenuItem(
          value: module.key,
          alignment: AlignmentDirectional.center,
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
    if (StringUtils.isNotEmpty(Config().essentialSkillsCoachKey)) {
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

  Future<void> _updateProgress(String unitKey, UserContent current, Content content, Map<String, dynamic> updatedData) async {
    _setLoading(true);
    UserUnit? updatedUserUnit = await CustomCourses().updateUserCourseProgress(UserContent(contentKey: current.contentKey, userData: updatedData), courseKey: _userCourse!.course!.key!, unitKey: unitKey);
    if (updatedUserUnit != null) {
      if (CollectionUtils.isNotEmpty(_userCourseUnits)) {
        int unitIndex = _userCourseUnits!.indexWhere((userUnit) => userUnit.id != null && userUnit.id == updatedUserUnit.id);
        if (unitIndex >= 0) {
          setStateIfMounted(() {
            _userCourseUnits![unitIndex] = updatedUserUnit;
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
      if (extendedStreak && current.isNotComplete && updatedData[UserContent.completeKey] == true) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AssignmentCompletePanel(
          contentName: content.name ?? '',
          pauses: earnedPause ? _userCourse?.pauses : null,
          color: _selectedModulePrimaryColor,
          colorAccent: _selectedModuleAccentColor,
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
}
