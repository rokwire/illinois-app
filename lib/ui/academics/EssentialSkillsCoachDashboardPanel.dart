
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/CustomCourses.dart';
import 'package:illinois/ui/academics/EssentialSkillsCoach.dart';
import 'package:illinois/ui/academics/courses/AssignmentPanel.dart';
import 'package:illinois/ui/academics/courses/ResourcesPanel.dart';
import 'package:illinois/ui/academics/courses/StreakPanel.dart';
import 'package:illinois/ui/academics/courses/UnitInfoPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class EssentialSkillsCoachDashboardPanel extends StatefulWidget {
  EssentialSkillsCoachDashboardPanel();

  @override
  State<EssentialSkillsCoachDashboardPanel> createState() => _EssentialSkillsCoachDashboardPanelState();
}

class _EssentialSkillsCoachDashboardPanelState extends State<EssentialSkillsCoachDashboardPanel> implements NotificationsListener {
  Course? _course;
  UserCourse? _userCourse;
  List<UserUnit>? _userCourseUnits;
  bool _loading = false;

  String? _selectedModuleKey;

  @override
  void initState() {
    _loadCourseAndUnits();
    //TODO: load course config if needed (check ESC onboarding completed, _hasStartedSkillsCoach, completed BESSI)

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    } else if (Auth2().isLoggedIn && _hasStartedSkillsCoach) {
      if (_selectedModule != null) {
        return SingleChildScrollView(
          child: Container(
            color: _selectedModulePrimaryColor,
            child: _buildModuleInfoView(_selectedModule!.display?.icon ?? 'skills-question'),
          ),
        );
      }
      return Center(
        child: Text(Localization().getStringEx('panel.essential_skills_coach.dashboard.content.missing.text', 'Course content could not be loaded. Please try again later.'))
      );
    }

    return SingleChildScrollView(child: EssentialSkillsCoach(onStartCourse: _startCourse,));
  }

  bool get _hasStartedSkillsCoach => _userCourse != null;

  Module? get _selectedModule => _userCourse?.course?.searchByKey(moduleKey: _selectedModuleKey) ?? _course?.searchByKey(moduleKey: _selectedModuleKey); //TODO: remove _course option after start course UI
  Color? get _selectedModulePrimaryColor => _selectedModule!.display?.primaryColor != null ? Styles().colors.getColor(_selectedModule!.display!.primaryColor!) : Styles().colors.fillColorPrimary;
  Color? get _selectedModuleAccentColor => _selectedModule!.display?.accentColor != null ? Styles().colors.getColor(_selectedModule!.display!.accentColor!) : Styles().colors.fillColorSecondary;

  @override
  void onNotification(String name, param) {
    // TODO: implement onNotification
  }

  Widget _buildModuleInfoView(String iconKey){
    return Column(
      children: [
        _buildStreakWidget(),
        SizedBox(height: 16.0),
        Padding(
          padding: EdgeInsets.all(8),
          child: Styles().images.getImage(iconKey),
        ),
        Padding(padding: EdgeInsets.only(left: 16, right: 16,bottom: 16),
          child: DropdownButton(
              value: _selectedModuleKey,
              iconDisabledColor: Colors.white,
              iconEnabledColor: Colors.white,
              focusColor: Colors.white,
              dropdownColor: _selectedModuleAccentColor,
              isExpanded: true,
              items: _moduleDropdownItems(style: Styles().textStyles.getTextStyle("widget.title.light.large.fat")),
              onChanged: (String? selected) {
                setState(() {
                  _selectedModuleKey = selected;
                });
              }
          )
        ),
        ..._buildModuleUnitWidgets(),
      ],
    );
  }

  Widget _buildStreakWidget() {
    return Container(
      height: 48,
      color: Styles().colors.fillColorPrimaryVariant,
      child: TextButton(
        onPressed: () {
          Navigator.push(context, CupertinoPageRoute(builder: (context) => StreakPanel()));
        },
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

  List<Widget> _buildModuleUnitWidgets(){
    List<Widget> moduleUnitWidgets = <Widget>[];
    for (int i = 0; i < (_selectedModule?.units?.length ?? 0); i++) {
      Unit unit = _selectedModule!.units![i];
      UserUnit showUnit = _userCourseUnits?.firstWhere(
        (userUnit) => (userUnit.unit?.key != null) && (userUnit.unit!.key == unit.key),
        orElse: () => UserUnit.emptyFromUnit(unit, Config().essentialSkillsCoachKey ?? '', current: i == 0)
      ) ?? UserUnit.emptyFromUnit(unit, Config().essentialSkillsCoachKey ?? '');
      moduleUnitWidgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: _buildUnitInfoWidget(showUnit.unit!, i+1),
      ));
      if (CollectionUtils.isNotEmpty(showUnit.unit!.scheduleItems)) {
        moduleUnitWidgets.addAll(_buildUnitWidgets(showUnit.unit!, showUnit.completed, showUnit.current));
      }
    }
    return moduleUnitWidgets;
  }

  Widget _buildUnitInfoWidget(Unit unit, int displayNumber){
    return Container(
      color: _selectedModuleAccentColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Unit $displayNumber', style: Styles().textStyles.getTextStyle("widget.title.light.huge.fat")),
                  Text(unit.name ?? "", style: Styles().textStyles.getTextStyle("widget.title.light.regular.fat"))
                ],
              ),
            ),
          ),
          Flexible(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.all(24),
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
                            contentItems: unit.resourceContent,
                            unitName: unit.name ?? ""
                        )));
                      },
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: _selectedModulePrimaryColor,
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
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUnitWidgets(Unit unit, int? completed, bool current){
    List<Widget> unitWidgets = [];
    int scheduleStart = unit.scheduleStart ?? 0;
    for (int i = 0; i < (unit.scheduleItems?.length ?? 0); i++) {
      ScheduleItem item = unit.scheduleItems![i];
      if ((item.userContent?.length ?? 0) > 1) {
        List<Widget> contentButtons = [];
        for (UserContent userContent in item.userContent!) {
          Content? content = unit.searchByKey(contentKey: userContent.contentKey);
          if (content != null && StringUtils.isNotEmpty(unit.key)) {
            contentButtons.add(_buildContentWidget(unit.key!, current, userContent, content, i, scheduleStart, completed ?? scheduleStart));
          }
        }
        unitWidgets.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: contentButtons,
        ));
      } else if ((item.userContent?.length ?? 0) == 1) {
        Content? content = unit.searchByKey(contentKey: item.userContent![0].contentKey);
        if (content != null && StringUtils.isNotEmpty(unit.key)) {
          unitWidgets.add(_buildContentWidget(unit.key!, current, item.userContent![0], content, i, scheduleStart, completed ?? scheduleStart));
        }
      }

      unitWidgets.add(SizedBox(height: 16,));
    }
    return unitWidgets;
  }

  Widget _buildContentWidget(String unitKey, bool currentUnit, UserContent userContent, Content content, int scheduleIndex, int scheduleStart, int completed) {
    Widget scheduleItemBase = new Container(
      width: 82.0,
      height: 82.0,
      decoration: new BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );

    bool required = scheduleIndex >= scheduleStart;
    bool isCompleted = scheduleIndex < completed;
    bool isCurrent = (scheduleIndex == completed) && currentUnit;
    bool isCompletedOrCurrent = isCompleted || isCurrent;

    Color? contentColor = content.display?.primaryColor != null ? Styles().colors.getColor(content.display!.primaryColor!) : Styles().colors.fillColorSecondary;
    Color? completedColor = content.display?.completedColor != null ? Styles().colors.getColor(content.display!.completedColor!) : Styles().colors.greenAccent;
    Widget contentButton = ElevatedButton(
      onPressed: isCompletedOrCurrent ? () {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => !required ? UnitInfoPanel(
            content: content,
            color: _selectedModulePrimaryColor,
            colorAccent: _selectedModuleAccentColor,
          ) : AssignmentPanel(
            content: content,
            data: userContent.userData,
            color: _selectedModulePrimaryColor,
            colorAccent: _selectedModuleAccentColor,
            isCurrent: isCurrent,
            // helpContent: helpContent,
          )
        )).then((result) {
          if (result is Map<String, dynamic> && StringUtils.isNotEmpty(userContent.contentKey)) {
            _updateProgress(unitKey, userContent.contentKey!, result);
          }
        });
      } : null,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: userContent.hasData ? Styles().images.getImage("skills-check") : Styles().images.getImage(content.display?.icon),
      ),
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: EdgeInsets.all(8.0),
        backgroundColor: isCompletedOrCurrent ? (!required || userContent.hasData ? completedColor : contentColor) : contentColor?.withOpacity(.3),
      ),
    );

    if (!isCompletedOrCurrent || (required && !userContent.hasData)) {
      return Center(
        child: Stack(
          children: [
            scheduleItemBase,
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: contentButton,
            ),
          ],
        ),
      );
    }
    return contentButton;
  }

  List<DropdownMenuItem<String>> _moduleDropdownItems({String? nullOption, TextStyle? style}) {
    //TODO: add option for ESC overview
    List<DropdownMenuItem<String>> dropDownItems = <DropdownMenuItem<String>>[];
    if (nullOption != null) {
      dropDownItems.add(DropdownMenuItem(value: null, child: Text(nullOption, style: style ?? Styles().textStyles.getTextStyle("widget.detail.regular"))));
    }
    for (Module module in _userCourse?.course?.modules ?? _course?.modules ?? []) {
      if (module.key != null && module.name != null && CollectionUtils.isNotEmpty(module.units)) {
        dropDownItems.add(DropdownMenuItem(value: module.key, child: Text(module.name!, style: style ?? Styles().textStyles.getTextStyle("widget.detail.regular"))));
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

  Future<void> _updateProgress(String unitKey, String contentKey, Map<String, dynamic> result) async {
    _setLoading(true);
    UserUnit? updatedUserUnit = await CustomCourses().updateUserCourseProgress(UserContent(contentKey: contentKey, userData: result), courseKey: _userCourse!.course!.key!, unitKey: unitKey);
    if (updatedUserUnit != null) {
      if (CollectionUtils.isNotEmpty(_userCourseUnits)) {
        int unitIndex = _userCourseUnits!.indexWhere((userUnit) => userUnit.id != null && userUnit.id == updatedUserUnit.id);
        if (unitIndex > 0) {
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

      UserCourse? userCourse = await CustomCourses().loadUserCourse(Config().essentialSkillsCoachKey!);
      if (userCourse != null) {
        setStateIfMounted(() {
          _userCourse = userCourse;
          _loading = false;
        });
      } else {
        _setLoading(false);
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
