
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';

class Event2TimeRangePanel extends StatefulWidget {
  static const String customStartTimeAttribute = 'custom-start-time';
  static const String customEndTimeAttribute = 'custom-end-time';

  final Map<String, dynamic>? customData;

  Event2TimeRangePanel({Key? key, this.customData}) : super(key: key);

  TZDateTime? get startTime => customDataTime(customData, customStartTimeAttribute);
  TZDateTime? get endTime => customDataTime(customData, customEndTimeAttribute);

  static TZDateTime? getStartTime(Map<String, dynamic>? customData) => customDataTime(customData, customStartTimeAttribute);
  static TZDateTime? getEndTime(Map<String, dynamic>? customData) => customDataTime(customData, customEndTimeAttribute);
  static TZDateTime? customDataTime(Map<String, dynamic>? customData, String key) {
    dynamic value = customData?[key];
    return (value is TZDateTime) ? value : null;
  }

  static Map<String, dynamic> buldCustomData(TZDateTime? startTime, TZDateTime? endTime) => <String, dynamic>{
    customStartTimeAttribute : startTime,
    customEndTimeAttribute : endTime,
  };

  static TZDateTime dateTimeWithDateAndTimeOfDay(Location timeZone, DateTime date, TimeOfDay? time, { bool inclusive = false}) =>
    TZDateTime(timeZone, date.year, date.month, date.day, time?.hour ?? (inclusive ? 23 : 0), time?.minute ?? (inclusive ? 59 : 0));

  @override
  State<StatefulWidget> createState() => _Event2TimeRangePanelState();
}

class _Event2TimeRangePanelState extends State<Event2TimeRangePanel> {
  late Location _timeZone;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  @override
  void initState() {
    _timeZone = widget.startTime?.location ?? widget.endTime?.location ?? DateTimeLocal.timezoneLocal;
    
    DateTime now = DateTime.now();
    if (widget.startTime != null) {
      DateTime startDateTime = DateTimeUtils.max(widget.startTime!, now);
      _startDate = DateUtils.dateOnly(startDateTime);
      _startTime = TimeOfDay.fromDateTime(startDateTime);
    }
    
    if ((widget.endTime != null) && now.isBefore(widget.endTime!)) {
      _endDate = DateUtils.dateOnly(widget.endTime!);
      _endTime = TimeOfDay.fromDateTime(widget.endTime!);
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.event2.attributes.filters.time_range.header.title', 'Date & Time'), actions: _isModified ? <Widget>[_buildApplyButton(enabled: _canApply)] : null,),
      body: _buildContent(),
      backgroundColor: Styles().colors!.white,
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(child:
      Padding(padding: EdgeInsets.all(16), child:
        Column(children: <Widget>[
          _buildTimeZoneDropdown(),
          Container(height: 8,),
          _buildDateTime(
            date: _startDate,
            time: _startTime,
            onDate: _onStartDate,
            onTime: _onStartTime,
            semanticsDateLabel: Localization().getStringEx("panel.create_event.date_time.start_date.title", "START DATE"),
            semanticsTimeLabel: Localization().getStringEx("panel.create_event.date_time.start_time.title",'START TIME'),
            dateLabel: Localization().getStringEx("panel.create_event.date_time.start_date.title", "START DATE"),
            timeLabel: Localization().getStringEx("panel.create_event.date_time.start_time.title","START TIME"),
          ),
          Container(height: 8,),
          _buildDateTime(
            date: _endDate,
            time: _endTime,
            onDate: _onEndDate,
            onTime: _onEndTime,
            semanticsDateLabel: Localization().getStringEx("panel.create_event.date_time.end_date.title", "END DATE"),
            semanticsTimeLabel: Localization().getStringEx("panel.create_event.date_time.end_time.title",'END TIME'),
            dateLabel: Localization().getStringEx("panel.create_event.date_time.end_date.title", "END DATE"),
            timeLabel: Localization().getStringEx("panel.create_event.date_time.end_time.title","END TIME"),
          ),
        ]),
      )
    );
  }

  Widget _buildTimeZoneDropdown(){
    return Semantics(container: true, child:
      Row(children: <Widget>[
        Expanded(flex: 3, child:
          Text(Localization().getStringEx("panel.create_event.date_time.time_zone.title", "TIME ZONE"), style:
            Styles().textStyles?.getTextStyle("panel.create_event.title.small")
          ),
        ),
        Container(width: 16,),
        Expanded(flex: 7, child:
          Container(decoration: _dropdownDecoration, child:
            Padding(padding: EdgeInsets.only(left: 12, right: 8), child:
              DropdownButtonHideUnderline(child:
                DropdownButton<Location>(
                  icon: Styles().images?.getImage('chevron-down'),
                  isExpanded: true,
                  style: Styles().textStyles?.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                  hint: Text(_timeZone.name,),
                  items: _buildTimeZoneDropDownItems(),
                  onChanged: _onTimeZoneChanged
                ),
              ),
            ),
          ),
        ),
      ])
    );
  }

  List<DropdownMenuItem<Location>>? _buildTimeZoneDropDownItems() {
    List<DropdownMenuItem<Location>> menuItems = <DropdownMenuItem<Location>>[];
    timeZoneDatabase.locations.forEach((String name, Location location) {
      if (name.startsWith('US/')) {
        menuItems.add(DropdownMenuItem<Location>(
          value: location,
          child: Text(name,),
        ));
        }
    });
    
    return menuItems;
  }

  Widget _buildDateTime({
    DateTime? date,
    TimeOfDay? time,
    void Function()? onDate,
    void Function()? onTime,
    String? semanticsDateLabel,
    String? semanticsTimeLabel,
    String? dateLabel,
    String? timeLabel,
  }) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
      Expanded(flex:2, child:
        Semantics(label: semanticsDateLabel, button: true, excludeSemantics: true, child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Padding(padding: EdgeInsets.only(bottom: 8), child:
              Row(children: <Widget>[
                Text(dateLabel ?? '', style: Styles().textStyles?.getTextStyle("panel.create_event.title.small"), ),
              ],),
            ),
            _buildDropdownButton(label: (date != null) ? DateFormat("EEE, MMM dd, yyyy").format(date) : "-", onTap: onDate,)
          ],)
        ),
      ),
      Container(width: 10),
      Expanded(flex: 1, child:
        Semantics(label:semanticsTimeLabel, button: true, excludeSemantics: true, child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Padding(padding: EdgeInsets.only(bottom: 8), child:
              Row(children: <Widget>[
                Text(timeLabel ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: Styles().textStyles?.getTextStyle("panel.create_event.title.small")),
              ],),
            ),
            _buildDropdownButton(label: (time != null) ? DateFormat("h:mma").format(_dateWithTimeOfDay(time)) : "-", onTap: onTime,)
          ],)
        ),
      ),
    ],);
  }

  Widget _buildDropdownButton({String? label, GestureTapCallback? onTap}) {
    return InkWell(onTap: onTap, child:
      Container(decoration: _dropdownDecoration, padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), child:
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Text(label ??  '-', style: Styles().textStyles?.getTextStyle("widget.title.regular"),),
          Styles().images?.getImage('chevron-down') ?? Container()
        ],),
      ),
    );
  }

  BoxDecoration get _dropdownDecoration => BoxDecoration(
    border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(4))
  );

  Widget _buildApplyButton({bool enabled = true}) => _buildHeaderBarButton(
    title:  Localization().getStringEx('dialog.apply.title', 'Apply'),
    enabled: enabled,
    onTap: _onTapApply,
  );

  Widget _buildHeaderBarButton({String? title, void Function()? onTap, bool enabled = true, double horizontalPadding = 16}) {
    return Semantics(label: title, button: true, excludeSemantics: true, child: 
      InkWell(onTap: onTap, child:
        Align(alignment: Alignment.center, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12), child:
            Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: enabled ? Styles().colors!.white! : Styles().colors!.whiteTransparent06!, width: 1.5, ))),
                child: Text(title ?? '',
                  style: Styles().textStyles?.getTextStyle(enabled ? "widget.heading.regular.fat" : "widget.heading.regular.fat.disabled")
                ),
              ),
            ],)
          ),
        ),
        //Padding(padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12), child:
        //  Text(title ?? '', style: Styles().textStyles?.getTextStyle('panel.athletics.home.button.underline'))
        //),
      ),
    );
  }

  void _onTimeZoneChanged(Location? value) {
    Analytics().logSelect(target: "Time Zone selected: $value");
    if (value != null) {
      setState(() {
        _timeZone = value;
      });
    }
  }

  void _onStartDate() {
    Analytics().logSelect(target: "Start Date");
    DateTime now = DateUtils.dateOnly(DateTime.now());
    DateTime minDate = now;
    DateTime maxDate = ((_endDate != null) && now.isBefore(_endDate!)) ? _endDate! : now.add(Duration(days: 366));
    showDatePicker(context: context,
      initialDate: _startDate ?? minDate,
      firstDate: minDate,
      lastDate: maxDate,
      currentDate: now,
    ).then((DateTime? result) {
      if ((result != null) && mounted) {
        setState(() {
          _startDate = DateUtils.dateOnly(result);
        });
      }
    });
  }

  void _onStartTime() {
    Analytics().logSelect(target: "Start Time");
    showTimePicker(context: context, initialTime: _startTime ?? TimeOfDay(hour: 0, minute: 0)).then((TimeOfDay? result) {
      if ((result != null) && mounted) {
        setState(() {
          _startTime = result;
        });
      }
    });
  }

  void _onEndDate() {
    Analytics().logSelect(target: "End Date");
    DateTime now = DateUtils.dateOnly(DateTime.now());
    DateTime minDate = (_startDate != null) ? DateTimeUtils.max(_startDate!, now) : now;
    DateTime maxDate = minDate.add(Duration(days: 366));
    showDatePicker(context: context,
      initialDate: _endDate ?? minDate,
      firstDate: minDate,
      lastDate: maxDate,
      currentDate: now,
    ).then((DateTime? result) {
      if ((result != null) && mounted) {
        setState(() {
          _endDate = DateUtils.dateOnly(result);
        });
      }
    });
  }

  void _onEndTime() {
    Analytics().logSelect(target: "End Time");
    showTimePicker(context: context, initialTime: _endTime ?? TimeOfDay(hour: 0, minute: 0)).then((TimeOfDay? result) {
      if ((result != null) && mounted) {
        setState(() {
          _endTime = result;
        });
      }
    });
  }

  DateTime _dateWithTimeOfDay(TimeOfDay time) =>
    _dateTimeWithDateAndTimeOfDay(DateTime.now(), time);

  TZDateTime _dateTimeWithDateAndTimeOfDay(DateTime date, TimeOfDay? time, { bool inclusive = false}) =>
    Event2TimeRangePanel.dateTimeWithDateAndTimeOfDay(_timeZone, date, time, inclusive: inclusive);

  bool get _isModified {
    TZDateTime? startTime = (_startDate != null) ? _dateTimeWithDateAndTimeOfDay(_startDate!, _startTime) : null;
    bool sameStartTime = ((startTime == null) && (widget.startTime == null)) ||
      ((startTime != null) && (widget.startTime != null) && (startTime == widget.startTime));
    TZDateTime? endTime = (_endDate != null) ? _dateTimeWithDateAndTimeOfDay(_endDate!, _endTime, inclusive: true) : null;
    bool sameEndTime = ((endTime == null) && (widget.endTime == null)) ||
      ((endTime != null) && (widget.endTime != null) && (endTime == widget.endTime));
    return (!sameStartTime || !sameEndTime);
  }

  bool get _canApply {
    TZDateTime now = TZDateTime.now(_timeZone);
    TZDateTime? startTime = (_startDate != null) ? _dateTimeWithDateAndTimeOfDay(_startDate!, _startTime) : null;
    TZDateTime? endTime = (_endDate != null) ? _dateTimeWithDateAndTimeOfDay(_endDate!, _endTime, inclusive: true) : null;
    return ((startTime != null) || (endTime != null)) &&
      ((startTime == null) || startTime.isAfter(now)) &&
      ((endTime == null) || endTime.isAfter(startTime ?? now));
  }

  void _onTapApply() {
    Analytics().logSelect(target: 'Apply');
    TZDateTime now = TZDateTime.now(_timeZone);
    TZDateTime? startTime = (_startDate != null) ? _dateTimeWithDateAndTimeOfDay(_startDate!, _startTime) : null;
    TZDateTime? endTime = (_endDate != null) ? _dateTimeWithDateAndTimeOfDay(_endDate!, _endTime, inclusive: true) : null;
    if ((startTime == null) && (endTime == null)) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.event2.attributes.filters.time_range.error.select.message', 'You must select start or end time.'));
    }
    else if ((startTime != null) && startTime.isBefore(now)) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.event2.attributes.filters.time_range.error.start_in_past.message', 'Start time must not be past.'));
    }
    else if ((endTime != null) && endTime.isBefore(now)) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.event2.attributes.filters.time_range.error.end_in_past.message', 'End time must not be past.'));
    }
    else if ((startTime != null) && (endTime != null) && endTime.isBefore(startTime)) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.event2.attributes.filters.time_range.error.end_before_start.message', 'End time must be after start time.'));
      AppAlert.showDialogResult(context, 'End time must be after start time.');
    }
    else if ((startTime != null) || (endTime != null)) {
      Navigator.of(context).pop(Event2TimeRangePanel.buldCustomData(startTime, endTime));
    }
  }
}