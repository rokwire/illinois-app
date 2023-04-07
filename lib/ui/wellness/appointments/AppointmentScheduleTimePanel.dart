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
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/ui/wellness/appointments/AppointmentSchedulePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
//import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class AppointmentScheduleTimePanel extends StatefulWidget {
  final AppointmentScheduleParam scheduleParam;

  AppointmentScheduleTimePanel({Key? key, required this.scheduleParam}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AppointmentScheduleTimePanelState();
}

class _AppointmentScheduleTimePanelState extends State<AppointmentScheduleTimePanel> {

  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  AppointmentTimeSlot? _selectedSlot;
  
  List<AppointmentTimeSlot> _timeSlots = <AppointmentTimeSlot>[];
  bool _loadingTimeSlots = false;

  @override
  void initState() {
    super.initState();
    _loadTimeSlots();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.appointment.schedule.time.header.title', 'Schedule Appointment')),
      body: _buildContent(),
      backgroundColor: Styles().colors!.background,
      //bottomNavigationBar: uiuc.TabBar()
    );
  }

  Widget _buildContent() {
    return Column(children: [
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
    List<Widget> columns = <Widget>[];
    List<Widget>? row;
    int? rowHour;
    for (AppointmentTimeSlot timeSlot in _timeSlots) {
      int? slotHour = timeSlot.startTime?.hour;
      if (slotHour != null) {
        if (slotHour != rowHour) {
          if ((row != null) && (row.isNotEmpty)) {
            columns.add(Row(children: row,));
          }
          row = <Widget>[];
          rowHour = slotHour;
        }
        else if (row == null) {
          row = <Widget>[];
        }
        row.add(Expanded(child: _buildTimeSlot(timeSlot)));
      }
    }
    if ((row != null) && (row.isNotEmpty)) {
      columns.add(Row(children: row,));
    }

    return Padding(padding: EdgeInsets.symmetric(horizontal: 8), child:
      SingleChildScrollView(child:
        Column(children: columns,),
      ),
    );
  }

  Widget _buildTimeSlot(AppointmentTimeSlot timeSlot) {
    String timeString = (timeSlot.startTime != null) ? DateFormat('hh:mm aaa').format(timeSlot.startTime!) : '';
    Color? backColor;
    String textStyle;
    if (timeSlot.filled == true) {
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
       child: Container(
        decoration: BoxDecoration(
          color: backColor,
          borderRadius: BorderRadius.all(Radius.circular(4)),
          boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
        ),
        child: InkWell(onTap: () => _onTimeSlot(timeSlot),
          child: Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(timeString, textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle(textStyle),)
          )
        ),
      ),
    );
  }

  void _onTimeSlot(AppointmentTimeSlot timeSlot) {
    if (mounted) {
      if (timeSlot.filled != true) {
        setState(() {
          _selectedSlot = timeSlot;
        });
      }
      else {
        SystemSound.play(SystemSoundType.click);
      }
    }
  }

  Widget _buildDateBar() {
    String selectedDateString = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);
    return InkWell(onTap: _onEditDate, child:
      Padding(padding: EdgeInsets.all(16), child:
        Row(children: [
          Padding(padding: EdgeInsets.only(right: 8), child:
            Styles().images?.getImage('calendar')
          ),
          Expanded(child:
              Text(selectedDateString, style: Styles().textStyles?.getTextStyle('widget.button.title.regular.thin.underline'),)
          ),
        
        ],),
      )
    );
  }

  void _onEditDate() {
    DateTime firstDate = DateUtils.dateOnly(DateTime.now());
    DateTime lastDate = firstDate.add(Duration(days: 356));
    showDatePicker(context: context, initialDate: _selectedDate, firstDate: firstDate, lastDate: lastDate).then((DateTime? result) {
      if ((result != null) && mounted) {
        setState(() {
          _selectedDate = result;
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

  bool get _canContinue => (_selectedSlot != null);

  void _onContinue() {
    if (_canContinue) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AppointmentSchedulePanel(scheduleParam: AppointmentScheduleParam.fromOther(widget.scheduleParam, timeSlot: _selectedSlot),),));
    }
    else {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void _loadTimeSlots() {
    setState(() {
      _loadingTimeSlots = true;
    });
    Appointments().loadTimeSlots(unitId: widget.scheduleParam.unit?.id, dateLocal: _selectedDate).then((List<AppointmentTimeSlot>? result) {
      if (mounted) {
        setState(() {
          _loadingTimeSlots = false;
          _timeSlots = result ?? <AppointmentTimeSlot>[];
          _selectedSlot = _findSelectedTimeSlot(result, _selectedSlot);
        });
      }
    });
  }

  AppointmentTimeSlot? _findSelectedTimeSlot(List<AppointmentTimeSlot>? timeSlots, AppointmentTimeSlot? sourceSlot) {
    int? selectedMinutes = sourceSlot?.startMinutesSinceMidnightUtc;
    if ((timeSlots != null) && (selectedMinutes != null)) {
      for (AppointmentTimeSlot timeSlot in timeSlots) {
        if ((timeSlot.filled != true) && (timeSlot.startMinutesSinceMidnightUtc == selectedMinutes)) {
          return timeSlot;
        }
      }
    }
    return null;
  }
}

extension _AppointmentTimeSlot on AppointmentTimeSlot {

  int? get startMinutesSinceMidnightUtc {
    return (startTimeUtc != null) ? (startTimeUtc!.hour * 60 + startTimeUtc!.minute) : null;
  }

}
