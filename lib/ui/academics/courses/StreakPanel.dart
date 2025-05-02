import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/CustomCourses.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:table_calendar/table_calendar.dart';

class StreakPanel extends StatefulWidget with AnalyticsInfo {
  final UserCourse userCourse;
  final CourseConfig? courseConfig;
  final DateTime? firstScheduleItemCompleted;
  final AnalyticsFeature? analyticsFeature; //This overrides AnalyticsInfo.analyticsFeature getter

  const StreakPanel({required this.userCourse, this.courseConfig, this.firstScheduleItemCompleted, this.analyticsFeature});

  @override
  State<StreakPanel> createState() => _StreakPanelState();
}

class _StreakPanelState extends State<StreakPanel> {
  CourseConfig? _courseConfig;
  Duration _courseDayStartOffset = Duration();

  bool _loading = false;
  late int _streak;
  int? _pauses;

  @override
  void initState() {
    _streak = widget.userCourse.streak ?? 0;
    _pauses = widget.userCourse.pauses;
    if (widget.courseConfig != null) {
      _courseConfig = widget.courseConfig;
      _setCourseDayStartOffset();
    } else {
      _loadCourseConfig();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double streakCircleSize = 100.0;
    if (_streak >= 100) {
      streakCircleSize += 60.0;
    } else if (_streak >= 10) {
      streakCircleSize += 10.0;
    }

    List<Widget> pauseIconWidgets = [];
    for(int i = 0; i < (_courseConfig?.maxPauses ?? 0); i++) {
      pauseIconWidgets.add(Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: i < (_pauses ?? 0) ? Styles().images.getImage('pause-filled-blue') : Styles().images.getImage('pause-empty-blue'),
      ));
    }

    String earnedPausesText = Localization().getStringEx('panel.essential_skills_coach.pauses.missing.text', 'Your number of pauses could not be determined.');
    if (_pauses != null) {
      if (_courseConfig?.maxPauses != null) {
        earnedPausesText = sprintf(Localization().getStringEx('panel.essential_skills_coach.pauses.ratio.text', 'You have earned %d of %d pauses.'), [_pauses, _courseConfig!.maxPauses]);
      } else {
        earnedPausesText = sprintf(Localization().getStringEx('panel.essential_skills_coach.pauses.text', 'You have earned %d %s.'), [_pauses, _pauses! == 1 ? 'pause' : 'pauses']);
      }
    }
    String pauseRewardText = Localization().getStringEx('panel.essential_skills_coach.pauses_reward.missing.text', 'Pauses can be earned by responding to tasks daily. Check in daily to keep your streak going!');
    if (_courseConfig?.pauseProgressReward != null) {
      pauseRewardText = sprintf(Localization().getStringEx('panel.essential_skills_coach.pauses_reward.text', 'Pauses can be earned by responding to a task for %d consecutive days. Check in daily to keep your streak going!'), [_courseConfig!.pauseProgressReward]);
    }

    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.essential_skills_coach.streak.header.title', 'Streak'),
        textStyle: Styles().textStyles.getTextStyle('header_bar'),),
      body: _loading ? Center(child: CircularProgressIndicator()) :
        SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(left: 16, bottom: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: [
                      Align(alignment: AlignmentDirectional.centerEnd, child: Opacity(opacity: 0.2, child: Styles().images.getImage("streak", color: Styles().colors.fillColorPrimary))),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            alignment: AlignmentDirectional.center,
                            children: [
                              Container(
                                width: streakCircleSize,
                                height: streakCircleSize,
                                decoration: new BoxDecoration(
                                  color: Styles().colors.fillColorPrimary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(_streak.toString(), style: TextStyle(fontSize: 80, color: Styles().colors.surface), textAlign: TextAlign.center,)
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(Localization().getStringEx('panel.essential_skills_coach.streak.days.suffix', "Day Streak!"), style: Styles().textStyles.getTextStyle("widget.title.huge.extra_fat")),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:EdgeInsets.symmetric(horizontal: 16.0),
                  child:Text(Localization().getStringEx('panel.essential_skills_coach.streak.calendar.header', "Calendar"), style: Styles().textStyles.getTextStyle("widget.detail.large.fat")),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Styles().colors.dividerLineAccent),
                      borderRadius: BorderRadius.all(
                          Radius.circular(5.0)
                      ),
                    ),
                    child: TableCalendar(
                      selectedDayPredicate: _isStreak,
                      holidayPredicate: (day) {
                        return widget.userCourse.isDatePauseUse(day, _courseDayStartOffset);
                      },
                      headerStyle: HeaderStyle(
                        titleCentered: true,
                        titleTextStyle: Styles().textStyles.getTextStyle("widget.detail.large.fat") ?? TextStyle(),
                        leftChevronIcon: Icon(
                          Icons.chevron_left_rounded,
                          color: Styles().colors.surface,
                        ),
                        rightChevronIcon: Icon(
                            Icons.chevron_right_rounded,
                            color: Styles().colors.surface,
                        )
                      ),
                      availableCalendarFormats: const {
                        CalendarFormat.month : 'Month'
                      },
                      availableGestures: AvailableGestures.horizontalSwipe,
                      pageJumpingEnabled: true,
                      rangeSelectionMode: RangeSelectionMode.disabled,
                      daysOfWeekHeight: 32.0,
                      daysOfWeekStyle: DaysOfWeekStyle(
                        dowTextFormatter: (date, locale) => DateFormat.E(locale).format(date).substring(0, 2),
                        weekdayStyle: Styles().textStyles.getTextStyle("widget.detail.small.fat") ?? TextStyle(),
                        weekendStyle: Styles().textStyles.getTextStyle("widget.detail.small.fat") ?? TextStyle(),
                      ),
                      calendarStyle: CalendarStyle(
                        cellMargin: EdgeInsets.zero,
                        defaultTextStyle: Styles().textStyles.getTextStyle("widget.detail.large.fat") ?? TextStyle(),
                        weekendTextStyle: Styles().textStyles.getTextStyle("widget.detail.large.fat") ?? TextStyle(),
                        tablePadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      ),
                      calendarBuilders: CalendarBuilders(
                        selectedBuilder: _buildSelected,
                        holidayBuilder: _buildHoliday,
                        todayBuilder: _buildToday,
                      ),
                      firstDay: (widget.userCourse.dateCreated ?? widget.firstScheduleItemCompleted ?? DateTime(2024, 2, 1)).subtract(_courseDayStartOffset),
                      lastDay: DateTime.now().add(Duration(days: 365)).subtract(_courseDayStartOffset),
                      focusedDay: DateTime.now().subtract(_courseDayStartOffset),
                    ),
                  ),
                ),
                Padding(
                  padding:EdgeInsets.only(left: 16, right: 16, top: 16),
                  child:Text(Localization().getStringEx('panel.essential_skills_coach.streak.pauses.header', "Pauses"), style: Styles().textStyles.getTextStyle("widget.detail.large.fat")),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Styles().colors.dividerLineAccent),
                      borderRadius: BorderRadius.all(
                          Radius.circular(5.0)
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (pauseIconWidgets.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: pauseIconWidgets,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(earnedPausesText, style: Styles().textStyles.getTextStyle("widget.detail.regular.fat")),
                          ),
                          Text(pauseRewardText, style: Styles().textStyles.getTextStyle("widget.title.regular")),
                        ]
                      ),
                    ),
                  ),
                ),
              ],
          ),
        ),
      ),
      backgroundColor: Styles().colors.background,
    );
  }

  Widget? _buildSelected(BuildContext context, DateTime day, DateTime focusedDay) {
    double radius = 20.0;
    double cellWidth = 54.0;
    BoxDecoration singleDecoration = BoxDecoration(color: Styles().colors.fillColorPrimary, shape: BoxShape.circle);
    BoxDecoration rangeMiddleDecoration = BoxDecoration(color: Styles().colors.fillColorPrimary, shape: BoxShape.rectangle);
    BoxDecoration rangeStartDecoration = BoxDecoration(color: Styles().colors.fillColorPrimary, borderRadius: BorderRadius.only(topLeft: Radius.circular(radius), bottomLeft: Radius.circular(radius)));
    BoxDecoration rangeEndDecoration = BoxDecoration(color: Styles().colors.fillColorPrimary, borderRadius: BorderRadius.only(topRight: Radius.circular(radius), bottomRight: Radius.circular(radius)));

    DateTime dayBefore = day.subtract(const Duration(days: 1));
    DateTime dayAfter = day.add(const Duration(days: 1));
    BoxDecoration decoration = singleDecoration;
    bool wide = false;
    if ((_isStreak(dayBefore) && !_isStreak(dayAfter) && day.weekday != DateTime.sunday) || _isStreak(dayBefore) && _isStreak(dayAfter) && day.weekday == DateTime.saturday) {
      decoration = rangeEndDecoration;
      wide = true;
    } else if ((!_isStreak(dayBefore) && _isStreak(dayAfter) && day.weekday != DateTime.saturday) || _isStreak(dayBefore) && _isStreak(dayAfter) && day.weekday == DateTime.sunday) {
      decoration = rangeStartDecoration;
      wide = true;
    } else if (_isStreak(dayBefore) && _isStreak(dayAfter) && day.weekday != DateTime.saturday && day.weekday != DateTime.sunday) {
      decoration = rangeMiddleDecoration;
      wide = true;
    }

    return Center(
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          Container(
            width: wide ? cellWidth : 2 * radius,
            height: 2 * radius,
            decoration: decoration,
          ),
          Text(day.day.toString(), style: Styles().textStyles.getTextStyle("widget.title.light.large.fat"), textAlign: TextAlign.center,)
        ],
      ),
    );
  }

  Widget? _buildHoliday(BuildContext context, DateTime day, DateTime focusedDay) {
    return Center(
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Styles().colors.background, border: Border.all(color: Styles().colors.fillColorPrimary, width: 2.0), shape: BoxShape.circle),
          ),
          Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: Styles().images.getImage('pause-filled-blue', size: 16.0),
          ),
          Text(day.day.toString(), style: Styles().textStyles.getTextStyle("widget.detail.large.fat"), textAlign: TextAlign.center,)
        ],
      ),
    );
  }

  Widget? _buildToday(BuildContext context, DateTime day, DateTime focusedDay) {
    return Center(
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Styles().colors.surfaceAccent, shape: BoxShape.circle),
          ),
          Text(day.day.toString(), style: Styles().textStyles.getTextStyle("widget.detail.large.fat"), textAlign: TextAlign.center,)
        ],
      ),
    );
  }

  bool _isStreak(DateTime date) {
    return widget.userCourse.isDateStreak(date, widget.firstScheduleItemCompleted, _courseDayStartOffset);
  }

  Future<void> _loadCourseConfig() async {
    if (StringUtils.isNotEmpty(Config().essentialSkillsCoachKey)) {
      _setLoading(true);
      CourseConfig? courseConfig = await CustomCourses().loadCourseConfig(Config().essentialSkillsCoachKey!);
      if (courseConfig != null) {
        setStateIfMounted(() {
          _courseConfig = courseConfig;
          _setCourseDayStartOffset();
          _loading = false;
        });
      } else {
        _setLoading(false);
      }
    }
  }

  void _setCourseDayStartOffset() {
    // set _courseDayStartOffset to align the course-defined day, which starts at a local time defined by _courseConfig, to the actual day (midnight to midnight) with lowest possible hour difference
    int hourOffset = 0;
    int? courseDayStartHour = _courseConfig!.nextScheduleItemUnlockTime()?.hour;
    if (courseDayStartHour != null) {
      hourOffset = courseDayStartHour;
      if (hourOffset >= 12) {
        hourOffset -= 24;
      }
    }
    _courseDayStartOffset = Duration(hours: hourOffset);
    //TODO: verify this works as intended
  }

  void _setLoading(bool value) {
    setStateIfMounted(() {
      _loading = value;
    });
  }
}