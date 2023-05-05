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
import 'package:illinois/model/Appointment.dart';
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

  late AppointmentType _appointmentType;
  String? _toutImageKey;

  bool _isSubmitting = false;

  @override
  void initState() {
    _applyAppointmentType(widget.sourceAppointment?.type ?? AppointmentType.in_person);
    super.initState();
  }

  @override
  void dispose() {
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
    String toutTitle = Localization().getStringEx('panel.appointment.schedule.header.title', 'Schedule Appointment');

    return Column(children: <Widget>[
      Expanded(child:
        Container(child:
          CustomScrollView(scrollDirection: Axis.vertical, slivers: <Widget>[
            SliverToutHeaderBar(flexImageKey: _toutImageKey, title: toutTitle, flexRightToLeftTriangleColor: Colors.white),
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

                      // Person
                      _buildPersonDetail(),

                      // Date & Time
                      _buildDateTimeDetail(),
                    ]),
                  ),
                  Container(padding: EdgeInsets.symmetric(horizontal: 24), child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      _buildLabel(Localization().getStringEx('panel.appointment.schedule.type.label', 'APPOINTMENT TYPE'), required: true),
                      _buildAppontmentTypeDropdown(),

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

  Widget _buildLocationDetail() {
    String? displayLocation = widget.scheduleParam.unit?.address ?? widget.sourceAppointment?.location?.address;
    return ((displayLocation != null) && displayLocation.isNotEmpty) ?
      InkWell(onTap: () => _onLocation(), child:
        Padding(padding: EdgeInsets.only(top: 8, bottom: 8), child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: EdgeInsets.only(right: 4), child:
              Styles().images?.getImage('location', excludeFromSemantics: true),
            ),
            Expanded(child:
              Text(displayLocation, style: Styles().textStyles?.getTextStyle("widget.button.title.medium.underline"))
            ),
          ],),
        ),
      ) : Container();
  }

  Widget _buildPersonDetail() {
    String? displayPerson = widget.scheduleParam.person?.name ?? widget.sourceAppointment?.host?.displayName;
    return ((displayPerson != null) && displayPerson.isNotEmpty) ? 
      Padding(padding: EdgeInsets.only(top: 8, bottom: 6), child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: EdgeInsets.only(right: 4), child:
            Styles().images?.getImage('person', excludeFromSemantics: true),
          ),
          Expanded(child:
            Text(displayPerson, style: Styles().textStyles?.getTextStyle("widget.item.regular"))
          ),
        ],),
      ) : Container();
  }

  Widget _buildDateTimeDetail() {
    String? displayTime = widget.scheduleParam.timeSlot?.displayLongScheduleTime ?? widget.sourceAppointment?.displayLongScheduleTime;
    return ((displayTime != null) && displayTime.isNotEmpty) ?
      Padding(padding: EdgeInsets.only(top: 8, bottom: 12), child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: EdgeInsets.only(right: 4), child:
            Styles().images?.getImage('calendar', excludeFromSemantics: true),
          ),
          Expanded(child:
            Text(displayTime, style: Styles().textStyles?.getTextStyle("widget.item.regular"))
          ),
        ],),
      ) : Container();
  }

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
            hint: Text(appointmentTypeToDisplayString(_appointmentType, provider: widget.scheduleParam.provider) ?? '', style:
              Styles().textStyles?.getTextStyle("widget.detail.regular"),),
            items: _appontmentTypesDropdownList,
            onChanged: _onSelectAppointmentType,
          )
        ),
      ),
    ),
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
          Text(appointmentTypeToDisplayString(appointmentType, provider: widget.scheduleParam.provider) ?? '', style: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat"),),
        ),
      )
    ).toList();

  void _onSelectAppointmentType(AppointmentType? appointmentType) {
    if ((appointmentType != null) && mounted) {
      setState(() {
        _applyAppointmentType(appointmentType);
      });
    }
  }

  void _applyAppointmentType (AppointmentType appointmentType) {
    _appointmentType = appointmentType;
    _toutImageKey = AppointmentExt.buildImageKey(type: _appointmentType, unit: widget.scheduleParam.unit, provider: widget.scheduleParam.provider);
  }

  void _onLocation() {
    Analytics().logSelect(target: 'Location');
    //TBD: Maps2 panel with marker
    String? address = widget.scheduleParam.unit?.address ?? widget.sourceAppointment?.location?.address;
    if (address != null) {
      GeoMapUtils.launchDirections(destination: address, travelMode: GeoMapUtils.traveModeWalking);
    }
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
        person: widget.scheduleParam.person,
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
  final AppointmentProvider? provider;
  final AppointmentUnit? unit;
  final AppointmentPerson? person;
  final AppointmentTimeSlot? timeSlot;
  final List<AppointmentAnswer>? answers;

  AppointmentScheduleParam({ this.provider, this.unit, this.person, this.timeSlot, this.answers, });

  factory AppointmentScheduleParam.fromOther(AppointmentScheduleParam? other, {
    AppointmentProvider? provider,
    AppointmentUnit? unit,
    AppointmentPerson? person,
    AppointmentTimeSlot? timeSlot,
    List<AppointmentAnswer>? answers,
  }) => AppointmentScheduleParam(
    provider: provider ?? other?.provider,
    unit: unit ?? other?.unit,
    person: person ?? other?.person,
    timeSlot: timeSlot ?? other?.timeSlot,
    answers: answers ?? other?.answers,
  );

  static Future<AppointmentScheduleParam> fromAppointment(Appointment? appointment) async {

    String? providerId = appointment?.providerId;
    String? unitId = appointment?.unitId;
    String? personId = appointment?.personId;

    List<dynamic> results = await Future.wait([
      ((providerId != null) && (unitId != null)) ? Appointments().loadUnit(providerId: providerId, unitId: unitId) : Future.value(null),
      ((providerId != null) && (unitId != null) && (personId != null)) ? Appointments().loadPerson(providerId: providerId, unitId: unitId, personId: personId) : Future.value(null),
    ]);

    AppointmentUnit? unit = ((0 < results.length) && (results[0] is AppointmentUnit)) ? results[0] : null;
    AppointmentPerson? person = ((1 < results.length) && (results[1] is AppointmentPerson)) ? results[1] : null;

    return AppointmentScheduleParam(
      provider: appointment?.provider,
      unit: unit,
      person: person,
      timeSlot: AppointmentTimeSlot.fromAppointment(appointment),
      answers: appointment?.answers,
    );
  }

}