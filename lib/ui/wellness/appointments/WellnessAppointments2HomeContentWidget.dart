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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/wellness/appointments/AppointmentSchedulePanel.dart';
import 'package:illinois/ui/widgets/AccessWidgets.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessAppointments2HomeContentWidget extends StatefulWidget {
  WellnessAppointments2HomeContentWidget();

  @override
  State<WellnessAppointments2HomeContentWidget> createState() => _WellnessAppointments2HomeContentWidgetState();
}

class _WellnessAppointments2HomeContentWidgetState extends State<WellnessAppointments2HomeContentWidget> implements NotificationsListener {

  List<AppointmentProvider>? _providers;
  AppointmentProvider? _selectedProvider;

  bool _isLoading = false;
  bool _isProvidersExpanded = false;

  @override
  void initState() {
    NotificationService().subscribe(this, []);
    _initProviders();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener
  @override
  void onNotification(String name, param) {
  }

  @override
  Widget build(BuildContext context) {
    Widget? accessWidget = AccessCard.builder(resource: 'wellness.appointments');
    if (accessWidget != null) {
      return accessWidget;
    }
    else if (_isLoading) {
      return _buildLoadingContent();
    }
    else if (_providers == null) {
      return _buildMessageContent('Failed to load providers');
    }
    else if (_providers!.length == 0) {
      return _buildMessageContent('No providers available');
    }
    else if (_providers!.length == 1) {
      return _buildAppointmentsContent();
    }
    else {
      return Column(children: [
        _buildProvidersDropdown(),
        Expanded(child:
          Stack(children: [
            Padding(padding: EdgeInsets.only(top: 16), child:
              _buildAppointmentsContent()
            ),
            _buildProvidersDropdownContainer()
          ],)
          
        )
      ],);
    }
  }

  Widget _buildProvidersDropdown() {
    return Padding(padding: EdgeInsets.only(left: 16, right: 16), child:
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
  }

  Widget _buildAppointmentsContent() {
    return RefreshIndicator(onRefresh: _onPullToRefresh, child:
      SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), padding: EdgeInsets.symmetric(horizontal: 16), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildScheduleDescription(),
          Container(height: 24) // Ensures width for providers dropdown container
        ])
      )
    );
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

  Widget _buildScheduleDescription() {
    String descriptionHtml = Localization().getStringEx('panel.wellness.appointments.home.schedule_appointment.label', '<a href={{schedule_url}}>Schedule an appointment.</a>');
    return HtmlWidget(descriptionHtml,
      onTapUrl : _onDesciptionLink,
      textStyle:  Styles().textStyles?.getTextStyle("widget.message.medium"),
      customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors!.fillColorSecondary!) } : null
    );
  }

  bool _onDesciptionLink(String url) {
    if (url == '{{schedule_url}}') {
      _onScheduleAppointment();
    }
    return true;
  }

  void _initProviders() {
    _isLoading = true;
    Appointments().loadProviders().then((List<AppointmentProvider>? result) {
      if (mounted) {
        setState(() {
          _providers = result;
          _selectedProvider = AppointmentProvider.findInList(result, id: Storage().selectedAppointmentProviderId) ??
            (((result != null) && result.isNotEmpty) ? result.first : null);
          _isLoading = false;
        });
      }
    });
  }

  void _onScheduleAppointment() {
    AppointmentSchedulePanel.present(context);
  }

  Future<void> _onPullToRefresh() async {
    //TBD;
  }


}
