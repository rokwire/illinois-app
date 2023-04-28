/*
 * Copyright 2022 Board of Trustees of the University of Illinois.
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
import 'package:flutter/services.dart';
import 'package:illinois/ext/Appointment.dart';
import 'package:illinois/model/Appointment.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/ui/appointments/AppointmentSchedulePanel.dart';
import 'package:illinois/ui/appointments/AppointmentScheduleQuestionsPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
//import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AppointmentScheduleTimePanel extends StatefulWidget {
  final AppointmentScheduleParam scheduleParam;
  final Appointment? sourceAppointment;
  final void Function(BuildContext context, Appointment? appointment)? onFinish;

  AppointmentScheduleTimePanel({Key? key, required this.scheduleParam, this.sourceAppointment, this.onFinish}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AppointmentScheduleTimePanelState();
}

class _AppointmentScheduleTimePanelState extends State<AppointmentScheduleTimePanel> {

  late DateTime _selectedDate;
  AppointmentTimeSlot? _selectedSlot;
  
  List<AppointmentTimeSlot> _timeSlots = <AppointmentTimeSlot>[];
  List<AppointmentQuestion>? _questions;
  bool _loadingTimeSlots = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(widget.sourceAppointment?.startTimeUtc?.toLocal() ?? DateTime.now());
    _loadTimeSlots();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: (widget.sourceAppointment == null) ?
        Localization().getStringEx('panel.appointment.schedule.time.header.title', 'Schedule Appointment') :
        Localization().getStringEx('panel.appointment.reschedule.time.header.title', 'Reschedule Appointment')
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors!.background,
      //bottomNavigationBar: uiuc.TabBar()
    );
  }

  Widget _buildContent() {
    return Column(children: [
      _buildRescheduleBar(),
      _buildDateBar(),
      Expanded(child:
        _buildTime()
      ),
      SafeArea(child:
        _buildCommandBar(),
      ),
    ],);
  }

  Widget _buildTime() {
    if (_loadingTimeSlots) {
      return _buildLoading();
    }
    else if (_timeSlots.isEmpty) {
      return _buildEmpty();
    }
    else {
      return _buildTimeSlots();
    }
  }

  Widget _buildLoading() {
    return Center(child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 2,),
      )
    );
  }

  Widget _buildEmpty() {
    return Center(child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 32), child:
        Text(Localization().getStringEx('panel.appointment.schedule.time.label.empty', 'No time slots available for this date'), style: Styles().textStyles?.getTextStyle('widget.item.medium.fat'),)
      )
    );
  }

  Widget _buildTimeSlots() {
    Set<int> startMinutes = <int>{};
    Map<int, Map<int, AppointmentTimeSlot>> timeSlotRows = <int, Map<int, AppointmentTimeSlot>>{};
    for (AppointmentTimeSlot timeSlot in _timeSlots) {
      DateTime? slotStartTime = timeSlot.startTime;
      int? slotStartHour = slotStartTime?.hour;
      int? slotStartMinute = slotStartTime?.minute;
      if ((slotStartHour != null) && (slotStartMinute != null)) {
        Map<int, AppointmentTimeSlot> timeSlotRow = (timeSlotRows[slotStartHour] ??= <int, AppointmentTimeSlot>{});
        timeSlotRow[slotStartMinute] = timeSlot;
        startMinutes.add(slotStartMinute);
      }
    }

    List<Widget> rows = <Widget>[];
    for (int hour in timeSlotRows.keys) {
      List<Widget> row = <Widget>[];
      Map<int, AppointmentTimeSlot>? slotsPerHour = timeSlotRows[hour];
      for (int startMinute in startMinutes) {
        AppointmentTimeSlot? timeSlot = (slotsPerHour != null) ? slotsPerHour[startMinute] : null;
        row.add(Expanded(child: _buildTimeSlot(timeSlot)));  
      }
      rows.add(Row(children: row,));
    }

    return Padding(padding: EdgeInsets.symmetric(horizontal: 8), child:
      SingleChildScrollView(child:
        Column(children: rows,),
      ),
    );
  }

  Widget _buildTimeSlot(AppointmentTimeSlot? timeSlot) {
    String? timeString;
    if (timeSlot?.startTime != null) {
      if (timeSlot?.endTime != null) {
        String startTime = DateFormat('hh:mm').format(timeSlot!.startTime!);
        String endTime = DateFormat('hh:mm aaa').format(timeSlot.endTime!);
        timeString = "$startTime - $endTime";
      }
      else {
        timeString = DateFormat('hh:mm aaa').format(timeSlot!.startTime!);
      }
    }

    Color? backColor;
    String textStyle;
    if (timeSlot?.available != true) {
      backColor = Styles().colors?.background;
      textStyle = 'widget.button.title.disabled';
    }
    else if (_selectedSlot == timeSlot) {
      backColor = Styles().colors?.fillColorPrimary;
      textStyle = 'widget.colourful_button.title.accent';
    }
    else {
      backColor = Styles().colors?.white;
      textStyle = 'widget.button.title.enabled';
    }

    return Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
       child: Semantics(
         button: true, enabled: timeSlot.available, inMutuallyExclusiveGroup: true, selected: _selectedSlot == timeSlot,
         child: Container(
          decoration: BoxDecoration(
            color: backColor,
            borderRadius: BorderRadius.all(Radius.circular(4)),
            boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
          ),
          child: InkWell(onTap: () => _onTimeSlot(timeSlot),
            child: Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(timeString ?? '', textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle(textStyle),)
            )
          ),
        ),
       )
    );
  }

  void _onTimeSlot(AppointmentTimeSlot? timeSlot) {
    if (mounted) {
      if ((timeSlot != null) && timeSlot.available) {
        setState(() {
          _selectedSlot = timeSlot;
        });
      }
      else {
        SystemSound.play(SystemSoundType.click);
      }
    }
  }

  Widget _buildRescheduleBar() {

    if (widget.sourceAppointment == null) {
      return Container();
    }
    else {
      String? currentDateString = AppointmentTimeSlotExt.getDisplayScheduleTime(widget.sourceAppointment?.startTimeUtc, widget.sourceAppointment?.endTimeUtc) ??
        Localization().getStringEx('panel.appointment.reschedule.time.label.unknown', 'Unknown');
      
      return Padding(padding:EdgeInsets.only(left: 16, right: 16, top: 16), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Localization().getStringEx('panel.appointment.reschedule.time.label.current.appointment', 'Current Appointment:'), style: Styles().textStyles?.getTextStyle('widget.title.large.fat'),),
          Row(children: [
            Expanded(child:
                Text(currentDateString, style: Styles().textStyles?.getTextStyle('widget.button.title.regular.thin'),)
            ),
          
          ],),
        ],),
      );
    }
  }

  Widget _buildDateBar() {
    String selectedDateString = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);

    return Padding(padding: EdgeInsets.all(16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text((widget.sourceAppointment == null) ?
          Localization().getStringEx('panel.appointment.schedule.time.label.current.appointment', 'Showing available appointments for:') :
          Localization().getStringEx('panel.appointment.reschedule.time.label.new.appointment', 'New Appointment:'),
          style: Styles().textStyles?.getTextStyle('widget.title.large.fat'),
        ),
        Padding(padding: EdgeInsets.only(top: 2, bottom: 6), child:
          Row(children: [
            Padding(padding: EdgeInsets.only(right: 8), child:
              Styles().images?.getImage('calendar')
            ),
            Expanded(child:
              Text(selectedDateString, style: Styles().textStyles?.getTextStyle('widget.button.title.regular.thin'),)
            ),
          ],),
        ),
        RoundedButton(
          label: Localization().getStringEx("panel.appointment.schedule.time.button.select.date.title", "Select Alternative Date"),
          hint: Localization().getStringEx("panel.appointment.schedule.time.button.select.date.hint", ""),
          backgroundColor: Styles().colors!.surface,
          textColor: Styles().colors?.fillColorPrimary,
          borderColor: Styles().colors?.fillColorSecondary,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onTap: ()=> _onEditDate(),
        ),
      ],)
    );
  }

  void _onEditDate() {
    DateTime firstDate = DateUtils.dateOnly(DateTime.now());
    DateTime lastDate = firstDate.add(Duration(days: 356));
    showDatePicker(context: context, initialDate: _selectedDate, firstDate: firstDate, lastDate: lastDate).then((DateTime? result) {
      if ((result != null) && mounted) {
        setState(() {
          _selectedDate = DateUtils.dateOnly(result);
        });
        _loadTimeSlots();
      }
    });
  }

  Widget _buildCommandBar() {
    return Padding(padding: EdgeInsets.all(16), child:
      Semantics(explicitChildNodes: true, child: 
        RoundedButton(
          label: Localization().getStringEx("panel.appointment.schedule.time.button.continue.title", "Next"),
          hint: Localization().getStringEx("panel.appointment.schedule.time.button.continue.hint", ""),
          backgroundColor: Styles().colors!.surface,
          textColor: _canContinue ? Styles().colors!.fillColorPrimary : Styles().colors?.surfaceAccent,
          borderColor: _canContinue ? Styles().colors!.fillColorSecondary : Styles().colors?.surfaceAccent,
          onTap: ()=> _onContinue(),
        ),
      ),
    );
  }

  bool get _canContinue => (_selectedSlot != null) && (_loadingTimeSlots != true);

  void _onContinue() {
    if (_canContinue) {
      if (CollectionUtils.isNotEmpty(_questions)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AppointmentScheduleQuestionsPanel(questions: _questions!,
          scheduleParam: AppointmentScheduleParam.fromOther(widget.scheduleParam,
            timeSlot: _selectedSlot,
          ),
          sourceAppointment: widget.sourceAppointment,
          onFinish: widget.onFinish,
        ),));
      }
      else {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AppointmentSchedulePanel(
          scheduleParam: AppointmentScheduleParam.fromOther(widget.scheduleParam,
            timeSlot: _selectedSlot,
            answers: (_questions != null) ? <AppointmentAnswer>[] : null,
          ),
          sourceAppointment: widget.sourceAppointment,
          onFinish: widget.onFinish,
        ),));
      }
    }
    else {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void _loadTimeSlots() {
    setState(() {
      _loadingTimeSlots = true;
    });
    Appointments().loadTimeSlotsAndQuestions(
      providerId: widget.scheduleParam.provider?.id,
      unitId: widget.scheduleParam.unit?.id,
      personId: widget.scheduleParam.person?.id,
      dateLocal: _selectedDate).then((AppointmentTimeSlotsAndQuestions? result) {
      if (mounted) {
        setState(() {
          _loadingTimeSlots = false;
          _timeSlots = result?.timeSlots ?? <AppointmentTimeSlot>[];
          _questions = result?.questions;
          _selectedSlot = _findSelectedTimeSlot(
            result?.timeSlots,
            _selectedSlot?.startMinutesSinceMidnightUtc ?? widget.sourceAppointment?.startMinutesSinceMidnightUtc,
            slotFilter: (AppointmentTimeSlot timeSlot) => timeSlot.available,
          );
        });
      }
    });
  }

  AppointmentTimeSlot? _findSelectedTimeSlot(List<AppointmentTimeSlot>? timeSlots, int? startMinutesSinceMidnightUtc, { bool Function(AppointmentTimeSlot timeSlot)? slotFilter }) {
    if ((timeSlots != null) && (startMinutesSinceMidnightUtc != null)) {
      for (AppointmentTimeSlot timeSlot in timeSlots) {
        if (((slotFilter == null) || slotFilter(timeSlot)) && (timeSlot.startMinutesSinceMidnightUtc == startMinutesSinceMidnightUtc)) {
          return timeSlot;
        }
      }
    }
    return null;
  }
}
