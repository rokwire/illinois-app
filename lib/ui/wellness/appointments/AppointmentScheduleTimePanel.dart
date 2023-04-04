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

import 'package:flutter/material.dart';
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class AppointmentScheduleTimePanel extends StatefulWidget {
  final void Function(BuildContext context, DateTime result) onContinue;

  AppointmentScheduleTimePanel({Key? key, required this.onContinue}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AppointmentScheduleTimePanelState();
}

class _AppointmentScheduleTimePanelState extends State<AppointmentScheduleTimePanel> {

  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  
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
      bottomNavigationBar: uiuc.TabBar()
    );
  }

  Widget _buildContent() {
    return Column(children: [
      _buildDateBar(),
      Expanded(child:
        _buildTime()
      ),
      _buildCommandBar(),
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
    return Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
       child: Container(
        decoration: BoxDecoration(
          color: (timeSlot.filled == true) ? Styles().colors?.background : Styles().colors?.white,
          borderRadius: BorderRadius.all(Radius.circular(4)),
          boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
        ),
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(timeString, textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle('widget.item.regular.fat'),)
        ),
      ),
    );
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
              Text(selectedDateString, style: Styles().textStyles?.getTextStyle('widget.item.medium.fat'),)
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
          borderColor: Styles().colors!.fillColorSecondary,
          backgroundColor: Styles().colors!.surface,
          textColor: Styles().colors!.fillColorPrimary,
          onTap: ()=> _onContinue(),
        ),
      ),
    );
  }

  void _onContinue() {
    widget.onContinue(context, _selectedDate);
  }

  void _loadTimeSlots() {
    setState(() {
      _loadingTimeSlots = true;
    });
    Appointments().loadTimeSlots(dateLocal: _selectedDate).then((List<AppointmentTimeSlot>? result) {
      if (mounted) {
        setState(() {
          _loadingTimeSlots = false;
          _timeSlots = result ?? <AppointmentTimeSlot>[];
        });
      }
    });

  }
}