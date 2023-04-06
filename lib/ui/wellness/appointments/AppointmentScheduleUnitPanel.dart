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
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/wellness/appointments/AppointmentSchedulePanel.dart';
import 'package:illinois/ui/wellness/appointments/AppointmentScheduleTimePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/InfoPopup.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
import 'package:rokwire_plugin/utils/utils.dart';
//import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;

class AppointmentScheduleUnitPanel extends StatefulWidget {

  final AppointmentScheduleParam? scheduleParam;

  AppointmentScheduleUnitPanel({Key? key, this.scheduleParam}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AppointmentScheduleUnitPanelState();
}

class _AppointmentScheduleUnitPanelState extends State<AppointmentScheduleUnitPanel> {
  List<AppointmentProvider>? _providers;
  bool _isLoadingProviders = false;

  List<AppointmentUnit>? _units;
  bool _isLoadingUnits = false;

  AppointmentProvider? _selectedProvider;
  bool _isProvidersExpanded = false;

  @override
  void initState() {
    _initProviders();
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
    if (_isLoadingProviders) {
      return _buildLoadingContent();
    }
    else if (_providers == null) {
      return _buildMessageContent(Localization().getStringEx('panel.wellness.appointments2.home.message.providers.failed', 'Failed to load providers'));
    }
    else if (_providers!.length == 0) {
      return _buildMessageContent(Localization().getStringEx('panel.wellness.appointments2.home.message.providers.empty', 'No providers available'));
    }
    else if (_providers!.length == 1) {
      return _buildUnitsContent();
    }
    else {
      return Column(children: [
        _buildProvidersDropdown(),
        Expanded(child:
          Stack(children: [
            Padding(padding: EdgeInsets.only(top: 16), child:
              _buildUnitsContent()
            ),
            _buildProvidersDropdownContainer()
          ],)
          
        )
      ],);
    }
  }

  Widget _buildProvidersDropdown() {
    return Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16), child:
      Semantics(hint: Localization().getStringEx("dropdown.hint", "DropDown"), container: true, child:
        RibbonButton(
          textColor: Styles().colors!.fillColorSecondary,
          backgroundColor: Styles().colors!.white,
          borderRadius: BorderRadius.all(Radius.circular(5)),
          border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
          rightIconKey: _isProvidersExpanded ? 'chevron-up' : 'chevron-down',
          label: (_selectedProvider != null) ? (_selectedProvider?.name ?? '') : 'Select a provider',
          onTap: _onProvidersDropdown
        )
      )
    );
  }

  Widget _buildProvidersDropdownContainer() {
    return Visibility(visible: _isProvidersExpanded, child:
      Positioned.fill(child:
        Stack(children: <Widget>[
          _buildProvidersDropdownDismissLayer(),
          _buildProvidersDropdownItems()
        ])
      )
    );
  }

  Widget _buildProvidersDropdownDismissLayer() {
    return Positioned.fill(child:
      BlockSemantics(child:
        GestureDetector(onTap: _onDismissProvidersDropdown, child:
          Container(color: Styles().colors!.blackTransparent06)
        )
      )
    );
  }

  Widget _buildProvidersDropdownItems() {
    List<Widget> items = <Widget>[];
    items.add(Container(color: Styles().colors!.fillColorSecondary, height: 2));

    if (_providers != null) {
      for (AppointmentProvider provider in _providers!) {
        items.add(RibbonButton(
          backgroundColor: Styles().colors!.white,
          border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
          rightIconKey: null,
          label: provider.name,
          onTap: () => _onTapProvider(provider)
        ));
      }
    }

    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: items)
      )
    );
  }

  void _onProvidersDropdown() {
    setStateIfMounted(() {
      _isProvidersExpanded = !_isProvidersExpanded;
    });
  }

  void _onDismissProvidersDropdown() {
    setStateIfMounted(() {
      _isProvidersExpanded = false;
    });
  }

  void _onTapProvider(AppointmentProvider provider) {
    setStateIfMounted(() {
      _isProvidersExpanded = false;
      _selectedProvider = provider;
      Storage().selectedAppointmentProviderId = provider.id;
    });
    _loadUnits();
  }

  Widget _buildUnitsContent() {
    if (_selectedProvider == null) {
      return _buildMessageContent(Localization().getStringEx('panel.wellness.appointments2.home.message.provider.empty', 'No selected provider'));
    }
    else if (_isLoadingUnits) {
      return _buildLoadingContent();
    }
    else if (_units == null) {
      return _buildMessageContent(Localization().getStringEx('panel.wellness.appointments2.home.message.units.failed', 'Failed to load units for provider'));
    }
    else if (_units!.length == 0) {
      return _buildMessageContent(Localization().getStringEx('panel.wellness.appointments2.home.message.units.empty', 'No units available for selected provider'));
    }
    else  {
      return _buildUnitsList();
    }
  }

  Widget _buildUnitsList() {
    List<Widget> unitsList = <Widget>[];
    if (_units != null) {
      for (AppointmentUnit unit in _units!) {
        if (unitsList.isNotEmpty) {
          unitsList.add(Container(height: 8,));
        }
        unitsList.add(_AppointmentUnitCard(provider: _selectedProvider!, unit: unit, onTap: () => _onUnit(unit)));
      }
    }
    unitsList.add(Container(height: 24)); // Ensures width for providers dropdown container
    
    return SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: unitsList)
    );
  }

  void _onUnit(AppointmentUnit unit) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AppointmentScheduleTimePanel(scheduleParam: AppointmentScheduleParam(
      providers: _providers,
      provider: _selectedProvider,
      units: _units,
      unit: unit
    ),)));
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

  void _initProviders() {
    if (CollectionUtils.isNotEmpty(widget.scheduleParam?.providers)) {
      _providers = widget.scheduleParam?.providers;
      _selectedProvider = widget.scheduleParam?.provider ??
        AppointmentProvider.findInList(_providers, id: Storage().selectedAppointmentProviderId) ??
        (((_providers != null) && _providers!.isNotEmpty) ? _providers!.first : null);
      _loadUnits();
    }
    else {
      _isLoadingProviders = true;
      Appointments().loadProviders().then((List<AppointmentProvider>? result) {
        setStateIfMounted(() {
          _providers = result;
          _selectedProvider = AppointmentProvider.findInList(result, id: widget.scheduleParam?.provider?.id) ??
            AppointmentProvider.findInList(result, id: Storage().selectedAppointmentProviderId) ??
            (((_providers != null) && _providers!.isNotEmpty) ? _providers!.first : null);
          _isLoadingProviders = false;
        });
        _loadUnits();
      });
    }
  }

  void _loadUnits() {
    String? providerId = _selectedProvider?.id;
    if (providerId != null) {
      setStateIfMounted(() {
        _isLoadingUnits = true;
      });
      Appointments().loadUnits(providerId: providerId).then((List<AppointmentUnit>? result) {
        setStateIfMounted(() {
          _units = result;
          _isLoadingUnits = false;
        });
     });
    }
    else {
      setStateIfMounted(() {
        _units = null;
      });
    }
  }
}

class _AppointmentUnitCard extends StatelessWidget {

  final AppointmentUnit unit;
  final AppointmentProvider? provider;
  final void Function()? onTap;

  _AppointmentUnitCard({Key? key, required this.unit, this.provider, this.onTap}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    const double imageSize = 64;
    const String imageKey = 'photo-building';
    return InkWell(onTap: onTap, child:
      ClipRRect(borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)), child:
        Stack(children: [
          Container(decoration: BoxDecoration(color: Styles().colors!.surface, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1), borderRadius: BorderRadius.all(Radius.circular(4))), child:
            Padding(padding: EdgeInsets.all(16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                
                Row(children: [
                  Expanded(child:
                    Text(provider?.name?.toUpperCase() ?? '', style: Styles().textStyles?.getTextStyle('widget.item.small.semi_fat'),)
                  ),
                ]),
                
                
                Padding(padding: EdgeInsets.only(top: 6), child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child:
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(padding: EdgeInsets.only(bottom: 2), child:
                          Text(unit.name ?? '', style: Styles().textStyles?.getTextStyle('widget.title.large.extra_fat'),),
                        ),
                        
                        InkWell(onTap: () => _onLocation(), child:
                          Padding(padding: EdgeInsets.only(top: 4, bottom: 2), child:
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Padding(padding: EdgeInsets.only(right: 4), child:
                                Styles().images?.getImage('location', excludeFromSemantics: true),
                              ),
                              Expanded(child:
                                Text(unit.location?.address ?? '', style: Styles().textStyles?.getTextStyle("widget.button.light.title.medium.underline"))
                              ),
                            ],),
                          ),
                        ),

                        InkWell(onTap: () => _onHoursOfOperation(context), child:
                          Padding(padding: EdgeInsets.only(top: 4, bottom: 2), child:
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Padding(padding: EdgeInsets.only(right: 6), child:
                                Styles().images?.getImage('calendar', excludeFromSemantics: true),
                              ),
                              Expanded(child:
                                Text(unit.hoursOfOperation ?? '', style: Styles().textStyles?.getTextStyle("widget.button.light.title.medium.underline"))
                              ),
                            ],),
                          ),
                        ),
                      ],)
                    ),
                    
                    Padding(padding: EdgeInsets.only(left: 16), child:
                      Semantics(button: true, label: "appointment image", hint: "Double tap to expand image", child:
                        SizedBox(width: imageSize, height: imageSize, child:
                          InkWell(onTap: () => _onCardImage(context, imageKey), child:
                            Styles().images?.getImage(imageKey, excludeFromSemantics: true, fit: BoxFit.fill, networkHeaders: Config().networkAuthHeaders)
                          )
                        ),
                      ),
                    )
                  ]),
                ),

                Padding(padding: EdgeInsets.only(top: 4), child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child:
                      Text(unit.details ?? '', style: Styles().textStyles?.getTextStyle("widget.button.light.title.medium"))
                    ),
                  ],),
                ),
              ])
            )
          ),
          Container(color: Styles().colors?.fillColorSecondary, height: 4,)
        ],)
      )
    );
  }

  void _onCardImage(BuildContext context,String? imageKey) {
    Analytics().logSelect(target: 'Appointment Unit Image');
    Navigator.push(context, PageRouteBuilder(opaque: false, pageBuilder: (context, _, __) =>
      ModalImagePanel(imageKey: imageKey, onCloseAnalytics: () => Analytics().logSelect(target: 'Close Image'))
    ));
  }

  void _onLocation() {
    //TBD: Maps2 panel with marker
    dynamic destination = ((unit.location?.latitude != null) && (unit.location?.longitude != null)) ? LatLng(unit.location!.latitude!, unit.location!.longitude!) : unit.location?.address;
    if (destination != null) {
      GeoMapUtils.launchDirections(destination: destination, travelMode: GeoMapUtils.traveModeWalking);
    }
  }

  void _onHoursOfOperation(BuildContext context) {
    showDialog(context: context, builder: (_) => InfoPopup(
      backColor: Styles().colors?.surface,
      padding: EdgeInsets.only(left: 24, right: 24, top: 28, bottom: 24),
      alignment: Alignment.center,
      infoText: "${provider?.name?.toUpperCase()}\n${unit.name}\n${unit.hoursOfOperation}",
      infoTextStyle: TextStyle(fontFamily: Styles().fontFamilies?.medium, fontSize: 16, color: Styles().colors?.fillColorPrimary),
      closeIcon: Styles().images?.getImage('close'),
    ),);
  }

}