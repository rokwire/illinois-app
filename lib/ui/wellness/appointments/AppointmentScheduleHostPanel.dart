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
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/ui/wellness/appointments/AppointmentSchedulePanel.dart';
import 'package:illinois/ui/wellness/appointments/AppointmentScheduleTimePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
//import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;

class AppointmentScheduleHostPanel extends StatefulWidget {

  final AppointmentScheduleParam? scheduleParam;
  final void Function(BuildContext context, Appointment? appointment)? onFinish;

  AppointmentScheduleHostPanel({Key? key, this.scheduleParam, this.onFinish}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AppointmentScheduleHostPanelState();
}

class _AppointmentScheduleHostPanelState extends State<AppointmentScheduleHostPanel> {

  List<AppointmentHost>? _hosts;
  bool _isLoadingHosts = false;

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
      appBar: HeaderBar(title: Localization().getStringEx('panel.appointment.schedule.unit.header.title', 'Schedule Appointment')),
      body: _buildContent(),
      backgroundColor: Styles().colors!.background,
      //bottomNavigationBar: uiuc.TabBar()
    );
  }

  Widget _buildContent() {
    if (_unitId == null) {
      return _buildMessageContent(Localization().getStringEx('panel.wellness.appointments2.home.message.unit.empty', 'No selected unit'));
    }
    else if (_isLoadingHosts) {
      return _buildLoadingContent();
    }
    else if (_hosts == null) {
      return _buildMessageContent(Localization().getStringEx('panel.wellness.appointments2.home.message.hosts.failed', 'Failed to load hosts for unit'));
    }
    else if (_hosts?.length == 0) {
      return _buildMessageContent(Localization().getStringEx('panel.wellness.appointments2.home.message.hosts.empty', 'No hosts available for selected unit'));
    }
    else  {
      return _buildHostsList();
    }
  }

  Widget _buildHostsList() {
    List<Widget> hostsList = <Widget>[];
    if (_hosts != null) {
      for (AppointmentHost host in _hosts!) {
        if (hostsList.isNotEmpty) {
          hostsList.add(Container(height: 8,));
        }
        hostsList.add(_AppointmentHostCard(host: host, onTap: () => _onHost(host)));
      }
    }
    hostsList.add(Container(height: 24)); // Ensures width for providers dropdown container
    
    return SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: hostsList)
    );
  }

  void _onHost(AppointmentHost host) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AppointmentScheduleTimePanel(
      scheduleParam: AppointmentScheduleParam.fromOther(widget.scheduleParam,
        host: host
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
        _isLoadingHosts = true;
      });
      Appointments().loadHosts(providerId: providerId, unitId: unitId).then((List<AppointmentHost>? result) {
        setStateIfMounted(() {
          _hosts = result;
          _isLoadingHosts = false;
        });
     });
    }
    else {
      setStateIfMounted(() {
        _hosts = null;
      });
    }
  }
}

class _AppointmentHostCard extends StatelessWidget {

  final AppointmentHost host;
  final void Function()? onTap;

  _AppointmentHostCard({Key? key, required this.host, this.onTap}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child:
      ClipRRect(borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)), child:
        Stack(children: [
          Container(decoration: BoxDecoration(color: Styles().colors!.surface, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1), borderRadius: BorderRadius.all(Radius.circular(4))), child:
            Padding(padding: EdgeInsets.all(16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Text(host.speciality?.toUpperCase() ?? '', style: Styles().textStyles?.getTextStyle('widget.item.small.semi_fat'),),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      Padding(padding: EdgeInsets.only(top: 6, bottom: 2), child:
                        Row(children: [
                          Expanded(child:
                            Text(host.displayName ?? '', style: Styles().textStyles?.getTextStyle('widget.title.large.extra_fat'),),
                          ),
                        ]),
                      ),

                      Visibility(visible: StringUtils.isNotEmpty(host.email), child:
                        Padding(padding: EdgeInsets.only(top: 4), child:
                          Row(children: [
                            Padding(padding: EdgeInsets.only(right: 4), child:
                              Styles().images?.getImage('mail', excludeFromSemantics: true),
                            ),
                            Expanded(child:
                              Text(host.email ?? '', style: Styles().textStyles?.getTextStyle("widget.button.light.title.medium"))
                            ),
                          ],),
                        ),
                      ),

                      Visibility(visible: StringUtils.isNotEmpty(host.phone), child:
                        Padding(padding: EdgeInsets.only(top: 4), child:
                          Row(children: [
                            Padding(padding: EdgeInsets.only(right: 4), child:
                              Styles().images?.getImage('phone', excludeFromSemantics: true),
                            ),
                            Expanded(child:
                              Text(host.phone ?? '', style: Styles().textStyles?.getTextStyle("widget.button.light.title.medium"))
                            ),
                          ],),
                        ),
                      ),


                    ]),
                  ),

                  Padding(padding: EdgeInsets.only(left: 16), child:
                    Semantics(button: true, label: "host image", hint: "Double tap to expand image", child:
                      SizedBox(width: 72, height: 72, child:
                        StringUtils.isNotEmpty(host.photoUrl) ?
                          Image.network(host.photoUrl ?? '', excludeFromSemantics: true, fit: BoxFit.cover,) :
                          Styles().images?.getImage('profile-placeholder', excludeFromSemantics: true)
                      ),
                    ),
                  ),
                ]),

                Padding(padding: EdgeInsets.only(top: 4, bottom: 2), child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child:
                      Text(host.description ?? '', style: Styles().textStyles?.getTextStyle("widget.button.light.title.medium"))
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