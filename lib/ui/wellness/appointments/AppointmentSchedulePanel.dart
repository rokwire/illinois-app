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
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
//import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;

class AppointmentSchedulePanel extends StatefulWidget {

  final AppointmentScheduleParam scheduleParam;

  AppointmentSchedulePanel({ Key? key, required this.scheduleParam }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AppointmentSchedulePanelState();
}

class _AppointmentSchedulePanelState extends State<AppointmentSchedulePanel> {

  AppointmentType _appointmentType = AppointmentType.in_person;

  @override
  void initState() {
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
                      InkWell(onTap: () => _onLocation(), child:
                        Padding(padding: EdgeInsets.only(top: 8, bottom: 8), child:
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Padding(padding: EdgeInsets.only(right: 4), child:
                              Styles().images?.getImage('location', excludeFromSemantics: true),
                            ),
                            Expanded(child:
                              Text(widget.scheduleParam.unit?.location?.address ?? '', style: Styles().textStyles?.getTextStyle("widget.button.title.medium.underline"))
                            ),
                          ],),
                        ),
                      ),

                      // Date & Time
                      Padding(padding: EdgeInsets.only(top: 8, bottom: 12), child:
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Padding(padding: EdgeInsets.only(right: 4), child:
                            Styles().images?.getImage('calendar', excludeFromSemantics: true),
                          ),
                          Expanded(child:
                            Text(_displayAppointmentTime ?? '', style: Styles().textStyles?.getTextStyle("widget.item.regular"))
                          ),
                        ],),
                      ),

                    ]),
                  ),
                  Container(padding: EdgeInsets.symmetric(horizontal: 24), child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      Padding(padding: EdgeInsets.only(top: 12, bottom: 6), child: Row(children: [Expanded(child:
                        Text('Appointment Type:', style: Styles().textStyles?.getTextStyle("widget.title.regular.fat"))
                      ),],),),

                      Padding(padding: EdgeInsets.only(bottom: 8), child:
                        Container(decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1), borderRadius: BorderRadius.all(Radius.circular(4))), child:
                          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
                            DropdownButtonHideUnderline(child:
                              DropdownButton<AppointmentType>(
                                icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
                                style: Styles().textStyles?.getTextStyle("widget.detail.light.regular"),
                                hint: Text(_displayAppointmentType, style: Styles().textStyles?.getTextStyle("widget.detail.regular"),),
                                items: _appontmentTypesDropdownList,
                                onChanged: _onSelectAppointmentType,
                              )
                            ),
                          ),
                        ),
                      )

                    ])
                  )
                ])
              )
            ], addSemanticIndexes: false))
          ])
        )
      )
    ]);
  }

  String? get _displayAppointmentTime {
    DateTime? startTime = widget.scheduleParam.timeSlot?.startTime;
    if (startTime != null) {
      DateTime? endTime = widget.scheduleParam.timeSlot?.endTime;
      if (endTime != null) {
        String startTimeStr = DateFormat('EEEE, MMMM d, yyyy hh:mm').format(startTime);
        String endTimeStr = DateFormat('hh:mm aaa').format(endTime);
        return "$startTimeStr - $endTimeStr";
      }
      else {
        return DateFormat('EEEE, MMMM d, yyyy hh:mm aaa').format(startTime);
      }
    }
    return null;
  }

  String get _displayAppointmentType =>
    _appointmentTypeDisplayString(_appointmentType);

  static String _appointmentTypeDisplayString(AppointmentType _appointmentType) {
    switch (_appointmentType) {
      case AppointmentType.in_person: return Localization().getStringEx('model.wellness.appointment2.type.in_person.label', 'In Person');
      case AppointmentType.online: return Localization().getStringEx('model.wellness.appointment2.type.online.label', 'Online');
    }
  }

  List<DropdownMenuItem<AppointmentType>> get _appontmentTypesDropdownList =>
    AppointmentType.values.map<DropdownMenuItem<AppointmentType>>((AppointmentType appointmentType) =>
      DropdownMenuItem<AppointmentType>(
        value: appointmentType,
        child: Padding(padding: EdgeInsets.only(right: 16), child:
          Text(_appointmentTypeDisplayString(appointmentType), style: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat"),),
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
    //TBD: Maps2 panel with marker
    AppointmentLocation? unitLocation = widget.scheduleParam.unit?.location;
    dynamic destination = (unitLocation != null) ? (((unitLocation.latitude != null) && (unitLocation.longitude != null)) ? LatLng(unitLocation.latitude!, unitLocation.longitude!) : unitLocation.address) : null;
    if (destination != null) {
      GeoMapUtils.launchDirections(destination: destination, travelMode: GeoMapUtils.traveModeWalking);
    }
  }
}

class AppointmentScheduleParam {
  final List<AppointmentProvider>? providers;
  final AppointmentProvider? provider;

  final List<AppointmentUnit>? units;
  final AppointmentUnit? unit;

  final AppointmentTimeSlot? timeSlot;

  AppointmentScheduleParam({
    this.providers, this.provider,
    this.units, this.unit,
    this.timeSlot,
  });

  factory AppointmentScheduleParam.fromOther(AppointmentScheduleParam? other, {
    List<AppointmentProvider>? providers,
    AppointmentProvider? provider,

    List<AppointmentUnit>? units,
    AppointmentUnit? unit,

    AppointmentTimeSlot? timeSlot,
  }) => AppointmentScheduleParam(
    providers: other?.providers ?? providers,
    provider: other?.provider ?? provider,

    units: other?.units ?? units,
    unit: other?.unit ?? unit,

    timeSlot: other?.timeSlot ?? timeSlot
  );

}