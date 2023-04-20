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
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:illinois/ext/Appointment.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
//import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;

class AppointmentSchedulePanel extends StatefulWidget {

  final AppointmentScheduleParam scheduleParam;
  final Appointment? sourceAppointment;
  final void Function(BuildContext context, Appointment? appointment)? onFinish;

  AppointmentSchedulePanel({ Key? key, required this.scheduleParam, this.sourceAppointment, this.onFinish }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AppointmentSchedulePanelState();
}

class _AppointmentSchedulePanelState extends State<AppointmentSchedulePanel> {

  final TextEditingController _notesController = TextEditingController();
  final FocusNode _notesFocus = FocusNode();

  late AppointmentType _appointmentType;
  late String _notes;

  bool _isSubmitting = false;

  @override
  void initState() {
    _appointmentType = widget.sourceAppointment?.type ?? AppointmentType.in_person;
    _notesController.text = _notes = widget.sourceAppointment?.notes ?? '';
    super.initState();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: HeaderBar(title: Localization().getStringEx('panel.appointment.schedule.header.title', 'Schedule Appointment')),
      body: _buildContentUi(),
      backgroundColor: Styles().colors!.background,
      //bottomNavigationBar: uiuc.TabBar()
    );
  }

  Widget _buildContentUi() {
    String toutImageKey = appointmentTypeImageKey(_appointmentType);

    return Column(children: <Widget>[
      Expanded(child:
        Container(child:
          CustomScrollView(scrollDirection: Axis.vertical, slivers: <Widget>[
            SliverToutHeaderBar(flexImageKey: toutImageKey, flexRightToLeftTriangleColor: Colors.white),
            SliverList(delegate: SliverChildListDelegate([
              Padding(padding: EdgeInsets.zero, child:
                Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Container(padding: EdgeInsets.symmetric(horizontal: 24), color: Colors.white, child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[

                      // Provider Name
                      Padding(padding: EdgeInsets.only(bottom: 2), child: Row(children: [Expanded(child:
                        Text(widget.scheduleParam.provider?.name ?? '', style: Styles().textStyles?.getTextStyle("widget.title.extra_large.semi_fat"))
                      ),],),),
                      
                      // Unit Name
                      Padding(padding: EdgeInsets.only(bottom: 12), child: Row(children: [Expanded(child:
                        Text(widget.scheduleParam.unit?.name ?? '', style: Styles().textStyles?.getTextStyle("widget.title.large"))
                      ),],),),

                      // Location
                      _buildLocationDetail(),

                      // Host
                      _buildHostDetail(),

                      // Date & Time
                      _buildDateTimeDetail(),
                    ]),
                  ),
                  Container(padding: EdgeInsets.symmetric(horizontal: 24), child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      _buildLabel(Localization().getStringEx('panel.appointment.schedule.type.label', 'APPOINTMENT TYPE'), required: true),
                      _buildAppontmentTypeDropdown(),

                      //_buildLabel(Localization().getStringEx('panel.appointment.schedule.notes.label', 'NOTES'), required: widget.scheduleParam.timeSlot?.notesRequired == true),
                      //_buildNotesTextField(),
                    ])
                  )
                ])
              )
            ], addSemanticIndexes: false))
          ])
        )
      ),
      SafeArea(child:
        _buildSubmit(),
      ),
    ]);
  }

  Widget _buildLocationDetail() => InkWell(onTap: () => _onLocation(), child:
    Padding(padding: EdgeInsets.only(top: 8, bottom: 8), child:
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.only(right: 4), child:
          Styles().images?.getImage('location', excludeFromSemantics: true),
        ),
        Expanded(child:
          Text(widget.scheduleParam.unit?.location?.address ?? widget.sourceAppointment?.location?.address ?? '', style: Styles().textStyles?.getTextStyle("widget.button.title.medium.underline"))
        ),
      ],),
    ),
  );

  Widget _buildHostDetail() => Padding(padding: EdgeInsets.only(top: 8, bottom: 6), child:
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(right: 4), child:
        Styles().images?.getImage('person', excludeFromSemantics: true),
      ),
      Expanded(child:
        Text(_displayHostName ?? '', style: Styles().textStyles?.getTextStyle("widget.item.regular"))
      ),
    ],),
  );

  String? get _displayHostName =>
    widget.scheduleParam.host?.displayName;

  Widget _buildDateTimeDetail() => Padding(padding: EdgeInsets.only(top: 8, bottom: 12), child:
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(right: 4), child:
        Styles().images?.getImage('calendar', excludeFromSemantics: true),
      ),
      Expanded(child:
        Text(_displayAppointmentTime ?? '', style: Styles().textStyles?.getTextStyle("widget.item.regular"))
      ),
    ],),
  );

  String? get _displayAppointmentTime =>
    widget.scheduleParam.timeSlot?.displayScheduleTime;
  
  Widget _buildLabel(String text, { bool required = false}) => Padding(padding: EdgeInsets.only(top: 12, bottom: 2), child: Row(children: [Expanded(child:
    RichText(text:
      TextSpan(text: text, style: Styles().textStyles?.getTextStyle('widget.title.tiny'), children: <InlineSpan>[
        TextSpan(text: required ? ' *' : '', style: Styles().textStyles?.getTextStyle('widget.label.small.fat'),),
      ])
    )
  ),],),);

  Widget _buildAppontmentTypeDropdown() => Padding(padding: EdgeInsets.only(bottom: 8), child:
    Container(decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1), borderRadius: BorderRadius.all(Radius.circular(4))), child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        DropdownButtonHideUnderline(child:
          DropdownButton<AppointmentType>(
            icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
            style: Styles().textStyles?.getTextStyle("widget.detail.light.regular"),
            hint: Text(appointment2TypeDisplayString(_appointmentType), style: Styles().textStyles?.getTextStyle("widget.detail.regular"),),
            items: _appontmentTypesDropdownList,
            onChanged: _onSelectAppointmentType,
          )
        ),
      ),
    ),
  );

  // ignore: unused_element
  Widget _buildNotesTextField() => Padding(padding: EdgeInsets.only(bottom: 8), child:
    Stack(children: [
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1),
          color: Styles().colors!.white),
        child: Semantics(textField: true, excludeSemantics: true, value: _notesController.text,
          label: Localization().getStringEx('panel.appointment.schedule.notes.field', 'NOTES FIELD'),
          hint: Localization().getStringEx('panel.appointment.schedule.notes.field.hint', ''),
          child: TextField(controller: _notesController, focusNode: _notesFocus, maxLines: 10,
            decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
            style: Styles().textStyles?.getTextStyle('widget.item.regular.thin'),
            onChanged: _onNoteChanged,
          )
        ),
      ),

      Align(alignment: Alignment.topRight, child:
        Visibility(visible:  _notesController.text.isNotEmpty, child:
          Semantics (button: true, excludeSemantics: true,
            label: Localization().getStringEx('dialog.clear.title', 'Clear'),
            hint: Localization().getStringEx('dialog.clear.hint', ''),
            child: GestureDetector(onTap: _onClearNote,
              child: Container(width: 36, height: 36,
                child: Align(alignment: Alignment.center,
                  child: Text('X', style: Styles().textStyles?.getTextStyle('widget.button.title.medium.thin'),),
                ),
              ),
            ),
          ),
        ),
      ),
    ],),
  );

  Widget _buildSubmit() => Padding(padding: EdgeInsets.all(16), child:
    Semantics(explicitChildNodes: true, child: 
      RoundedButton(
        label: (widget.sourceAppointment == null) ?
          Localization().getStringEx('panel.appointment.schedule.submit.button.title', 'Submit') :
          Localization().getStringEx('panel.appointment.reschedule.submit.button.title', 'Reschedule'),
        progress: _isSubmitting,
        onTap: _onSubmit,
      ),
    ),
  );

  List<DropdownMenuItem<AppointmentType>> get _appontmentTypesDropdownList =>
    AppointmentType.values.map<DropdownMenuItem<AppointmentType>>((AppointmentType appointmentType) =>
      DropdownMenuItem<AppointmentType>(
        value: appointmentType,
        child: Padding(padding: EdgeInsets.only(right: 16), child:
          Text(appointment2TypeDisplayString(appointmentType), style: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat"),),
        ),
      )
    ).toList();

  void _onSelectAppointmentType(AppointmentType? appointmentType) {
    if ((appointmentType != null) && mounted) {
      setState(() {
        _appointmentType = appointmentType;
      });
    }
  }

  void _onLocation() {
    Analytics().logSelect(target: 'Location');
    //TBD: Maps2 panel with marker
    AppointmentLocation? unitLocation = widget.scheduleParam.unit?.location ?? widget.sourceAppointment?.location;
    dynamic destination = (unitLocation != null) ? (((unitLocation.latitude != null) && (unitLocation.longitude != null)) ? LatLng(unitLocation.latitude!, unitLocation.longitude!) : unitLocation.address) : null;
    if (destination != null) {
      GeoMapUtils.launchDirections(destination: destination, travelMode: GeoMapUtils.traveModeWalking);
    }
  }

  void _onNoteChanged(String value) {
    bool wasEmpty = _notes.isEmpty;
    _notes = value;
    if (wasEmpty != _notes.isEmpty) {
      setState(() {});
    }
  }

  void _onClearNote() {
    Analytics().logSelect(target: 'Clear Notes');
    _notesController.text = _notes = '';
  }

  void _onSubmit() {
    Analytics().logSelect(target: 'Submit');

    /*if ((widget.scheduleParam.timeSlot?.notesRequired == true) && _notesController.text.isEmpty) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.appointment.schedule.notes.empty.message', 'Please fill your notes.')).then((_) => _notesFocus.requestFocus());
      return;
    }*/

    setStateIfMounted(() {
      _isSubmitting = true;
    });

    Future<Appointment?> processAppointment = (widget.sourceAppointment == null) ?
      Appointments().createAppointment(
        type: _appointmentType,
        provider: widget.scheduleParam.provider,
        unit: widget.scheduleParam.unit,
        host: widget.scheduleParam.host,
        timeSlot: widget.scheduleParam.timeSlot,
        answers: widget.scheduleParam.answers,
      ) :
      Appointments().updateAppointment(widget.sourceAppointment!,
        type: _appointmentType,
        timeSlot: widget.scheduleParam.timeSlot,
        answers: widget.scheduleParam.answers,
      );

    processAppointment.then((Appointment? appointment) {
      String message = (widget.sourceAppointment == null) ?
        Localization().getStringEx('panel.appointment.schedule.notes.submit.succeeded.message', 'Your appointment was scheduled successfully.') :
        Localization().getStringEx('panel.appointment.reschedule.notes.submit.succeeded.message', 'Your appointment was rescheduled successfully.');
      AppAlert.showDialogResult(context, message).then((_) {
        if (widget.onFinish != null) {
          widget.onFinish!(context, appointment);
        }
      });
    }).catchError((e) {
      String message = (widget.sourceAppointment == null) ?
        Localization().getStringEx('panel.appointment.schedule.notes.submit.failed.message', 'Failed to schedule appointment:') :
        Localization().getStringEx('panel.appointment.reschedule.notes.submit.failed.message', 'Failed to reschedule appointment:');
      AppAlert.showDialogResult(context, message + '\n' + e.toString());
    }).whenComplete(() {
      setStateIfMounted(() {
        _isSubmitting = false;
      });
    });
  }
}

class AppointmentScheduleParam {
  final List<AppointmentProvider>? providers;
  final AppointmentProvider? provider;
  final AppointmentUnit? unit;
  final AppointmentHost? host;
  final AppointmentTimeSlot? timeSlot;
  final List<AppointmentAnswer>? answers;

  AppointmentScheduleParam({
    this.providers, this.provider,
    this.unit, this.host, this.timeSlot, this.answers,
  });

  factory AppointmentScheduleParam.fromOther(AppointmentScheduleParam? other, {
    List<AppointmentProvider>? providers,
    AppointmentProvider? provider,
    AppointmentUnit? unit,
    AppointmentHost? host,
    AppointmentTimeSlot? timeSlot,
    List<AppointmentAnswer>? answers,
  }) => AppointmentScheduleParam(
    providers: providers ?? other?.providers,
    provider: provider ?? other?.provider,
    unit: unit ?? other?.unit,
    host: host ?? other?.host,
    timeSlot: timeSlot ?? other?.timeSlot,
    answers: answers ?? other?.answers,
  );

  factory AppointmentScheduleParam.fromAppointment(Appointment? appointment) => AppointmentScheduleParam(
    provider: appointment?.provider,
    unit: appointment?.unit,
    host: appointment?.host,
    timeSlot: AppointmentTimeSlot.fromAppointment(appointment),
    answers: appointment?.answers,
  );

}