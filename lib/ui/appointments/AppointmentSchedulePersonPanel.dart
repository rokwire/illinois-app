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
import 'package:illinois/ext/Appointment.dart';
import 'package:illinois/model/Appointment.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/ui/appointments/AppointmentSchedulePanel.dart';
import 'package:illinois/ui/appointments/AppointmentScheduleTimePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
//import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;

class AppointmentSchedulePersonPanel extends StatefulWidget {

  final AppointmentScheduleParam? scheduleParam;
  final void Function(BuildContext context, Appointment? appointment)? onFinish;

  AppointmentSchedulePersonPanel({Key? key, this.scheduleParam, this.onFinish}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AppointmentSchedulePersonPanelState();
}

class _AppointmentSchedulePersonPanelState extends State<AppointmentSchedulePersonPanel> {

  List<AppointmentPerson>? _persons;
  bool _isLoadingPersons = false;

  @override
  void initState() {
    _loadHosts();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.appointment.schedule.person.header.title', 'Schedule Appointment')),
      body: _buildContent(),
      backgroundColor: Styles().colors!.background,
      //bottomNavigationBar: uiuc.TabBar()
    );
  }

  Widget _buildContent() {
    if (_unitId == null) {
      return _buildMessageContent(Localization().getStringEx('panel.academics.appointments.home.message.unit.empty', 'No selected location.'));
    }
    else if (_isLoadingPersons) {
      return _buildLoadingContent();
    }
    else if (_persons == null) {
      return _buildMessageContent(Localization().getStringEx('panel.academics.appointments.home.message.persons.failed', 'Failed to load advisors for location.'));
    }
    else if (_persons?.length == 0) {
      return _buildMessageContent(Localization().getStringEx('panel.academics.appointments.home.message.persons.empty', 'No advisors available for selected location.'));
    }
    else  {
      return _buildPersonsList();
    }
  }

  Widget _buildPersonsList() {
    List<Widget> personsList = <Widget>[];
    if (_persons != null) {
      for (AppointmentPerson person in _persons!) {
        if (personsList.isNotEmpty) {
          personsList.add(Container(height: 8,));
        }
        personsList.add(_AppointmentPersonCard(person: person, onTap: () => _onPerson(person)));
      }
    }
    personsList.add(Container(height: 24)); // Ensures width for providers dropdown container
    
    return SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: personsList)
    );
  }

  void _onPerson(AppointmentPerson person) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AppointmentScheduleTimePanel(
      scheduleParam: AppointmentScheduleParam.fromOther(widget.scheduleParam,
        person: person
      ),
      onFinish: widget.onFinish,
    )));
  }

  Widget _buildLoadingContent() {
    return Center(child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 3,),
      )
    );
  }

  Widget _buildMessageContent(String message) {
    return Center(child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 32), child:
        Text(message, style: Styles().textStyles?.getTextStyle('widget.item.medium.fat'),)
      )
    );
  }

  String? get _unitId =>
    widget.scheduleParam?.unit?.id;

  String? get _providerId =>
    widget.scheduleParam?.provider?.id;

  void _loadHosts() {
    String? unitId = _unitId;
    String? providerId = _providerId;
    if ((unitId != null) && (providerId != null)) {
      applyStateIfMounted(() {
        _isLoadingPersons = true;
      });
      Appointments().loadPersons(providerId: providerId, unitId: unitId).then((List<AppointmentPerson>? result) {
        setStateIfMounted(() {
          _persons = result;
          _isLoadingPersons = false;
        });
     });
    }
    else {
      setStateIfMounted(() {
        _persons = null;
      });
    }
  }
}

class _AppointmentPersonCard extends StatelessWidget {

  final AppointmentPerson person;
  final void Function()? onTap;

  _AppointmentPersonCard({Key? key, required this.person, this.onTap}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    int numSlots = person.numberOfAvailableSlots ?? 0;
    String? numberOfAvailableSlots = person.displayNumberOfAvailableSlots;
    String? nextAvailableTime = person.displayNextAvailableTime;

    return InkWell(onTap: onTap, child:
      ClipRRect(borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)), child:
        Stack(children: [
          Container(decoration: BoxDecoration(color: Styles().colors!.surface, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1), borderRadius: BorderRadius.all(Radius.circular(4))), child:
            Padding(padding: EdgeInsets.all(16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                //Text(person.speciality?.toUpperCase() ?? '', style: Styles().textStyles?.getTextStyle('widget.item.small.semi_fat'),),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      Padding(padding: EdgeInsets.only(top: 6, bottom: 2), child:
                        Row(children: [
                          Expanded(child:
                            Text(person.name ?? '', style: Styles().textStyles?.getTextStyle('widget.title.large.extra_fat'),),
                          ),
                        ]),
                      ),

                      /*Visibility(visible: StringUtils.isNotEmpty(person.email), child:
                        Padding(padding: EdgeInsets.only(top: 4, bottom: 2), child:
                          Row(children: [
                            Padding(padding: EdgeInsets.only(right: 4), child:
                              Styles().images?.getImage('mail', excludeFromSemantics: true),
                            ),
                            Expanded(child:
                              Text(person.email ?? '', style: Styles().textStyles?.getTextStyle("widget.item.regular"))
                            ),
                          ],),
                        ),
                      ),*/

                      /*Visibility(visible: StringUtils.isNotEmpty(person.phone), child:
                        Padding(padding: EdgeInsets.only(top: 4, bottom: 2), child:
                          Row(children: [
                            Padding(padding: EdgeInsets.only(right: 4), child:
                              Styles().images?.getImage('phone', excludeFromSemantics: true),
                            ),
                            Expanded(child:
                              Text(person.phone ?? '', style: Styles().textStyles?.getTextStyle("widget.item.regular"))
                            ),
                          ],),
                        ),
                      ),*/

                      Visibility(visible: StringUtils.isNotEmpty(numberOfAvailableSlots), child:
                        Padding(padding: EdgeInsets.only(top: 4, bottom: 2), child:
                          Row(children: [
                            Padding(padding: EdgeInsets.only(right: 4), child:
                              Styles().images?.getImage('edit', excludeFromSemantics: true),
                            ),
                            Expanded(child:
                              Text(numberOfAvailableSlots ?? '', style: Styles().textStyles?.getTextStyle("widget.item.regular"))
                            ),
                          ],),
                        ),
                      ),

                      Visibility(visible: StringUtils.isNotEmpty(nextAvailableTime) && (0 < numSlots), child:
                        Padding(padding: EdgeInsets.only(top: 4, bottom: 2), child:
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Padding(padding: EdgeInsets.only(right: 6), child:
                              Styles().images?.getImage('calendar', excludeFromSemantics: true),
                            ),
                            Expanded(child:
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(Localization().getStringEx('panel.appointment.schedule.next_available_appointment.label', 'Next Available Appointment:'), style: Styles().textStyles?.getTextStyle("widget.item.regular")),
                                Text(nextAvailableTime ?? '', style: Styles().textStyles?.getTextStyle("widget.item.regular.fat")),
                              ],)
                            ),
                          ],),
                        ),
                      ),

                    ]),
                  ),

                  Padding(padding: EdgeInsets.only(left: 16), child:
                    Semantics(button: true, label: "advisor image", hint: "Double tap to expand image", child:
                      SizedBox(width: 72, height: 72, child:
                        StringUtils.isNotEmpty(person.imageUrl) ?
                          Image.network(person.imageUrl ?? '', excludeFromSemantics: true, fit: BoxFit.cover,) :
                          Styles().images?.getImage('profile-placeholder', excludeFromSemantics: true)
                      ),
                    ),
                  ),
                ]),

                Padding(padding: EdgeInsets.only(top: 4, bottom: 2), child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child:
                      Text(person.notes ?? '', style: Styles().textStyles?.getTextStyle("widget.item.regular"))
                    ),
                  ],),
                ),

              ])
            )
          ),
          Container(color: Styles().colors?.accentColor3, height: 4,)
        ],)
      )
    );
  }
}