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
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as Core;
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/WebPanel.dart';
import 'package:url_launcher/url_launcher.dart';

class AppointmentDetailPanel extends StatefulWidget {
  final Appointment appointment;
  final Core.Position? initialLocationData;

  AppointmentDetailPanel({required this.appointment, this.initialLocationData});

  @override
  _AppointmentDetailPanelState createState() => _AppointmentDetailPanelState();
}

class _AppointmentDetailPanelState extends State<AppointmentDetailPanel> implements NotificationsListener {
  static final double _horizontalPadding = 24;

  //Maps
  Core.Position? _locationData;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      LocationServices.notifyStatusChanged,
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged,
    ]);

    _locationData = widget.initialLocationData;
    _loadCurrentLocation().then((_) {
      setStateIfMounted(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    _locationData = FlexUI().isLocationServicesAvailable ? await LocationServices().location : null;
  }

  void _updateCurrentLocation() {
    _loadCurrentLocation().then((_) {
      setStateIfMounted(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(children: <Widget>[
          Expanded(
              child: Container(
                  child: CustomScrollView(scrollDirection: Axis.vertical, slivers: <Widget>[
            SliverToutHeaderBar(flexImageUrl: widget.appointment.imageUrl, flexRightToLeftTriangleColor: Colors.white),
            SliverList(
                delegate: SliverChildListDelegate([
              Stack(children: <Widget>[
                Container(
                    child: Column(children: <Widget>[
                  Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    _buildHeading(),
                    Column(children: <Widget>[
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 0),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                    padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
                                    color: Colors.white,
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[_buildTitle(), _buildDetails()])),
                                Container(
                                    padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
                                    child: Column(children: [_buildCancelDescription()]))
                              ]))
                    ])
                  ])
                ]))
              ])
            ], addSemanticIndexes: false))
          ])))
        ]),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: uiuc.TabBar());
  }

  Widget _buildHeading() {
    String? category = widget.appointment.category;
    bool isFavorite = Auth2().isFavorite(widget.appointment);
    bool starVisible = Auth2().canFavorite && widget.appointment.isUpcoming;
    return Container(
        color: Colors.white,
        padding: EdgeInsets.only(left: _horizontalPadding),
        child: Row(children: <Widget>[
          Expanded(
              child: Text(StringUtils.ensureNotEmpty(category).toUpperCase(),
                  style: TextStyle(
                      fontFamily: Styles().fontFamilies!.bold, fontSize: 14, color: Styles().colors!.fillColorPrimary, letterSpacing: 1))),
          Visibility(
              visible: starVisible,
              child: Container(
                  child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
                      child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Analytics().logSelect(target: "Favorite: ${widget.appointment.title}");
                            Auth2().prefs?.toggleFavorite(widget.appointment);
                          },
                          child: Container(
                              padding: EdgeInsets.only(left: _horizontalPadding, top: 16, bottom: 12),
                              child: Semantics(
                                  label: isFavorite
                                      ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites')
                                      : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                                  hint: isFavorite
                                      ? Localization().getStringEx('widget.card.button.favorite.off.hint', '')
                                      : Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
                                  button: true,
                                  child: Image.asset(isFavorite ? 'images/icon-star-blue.png' : 'images/icon-star-gray-frame-thin.png',
                                      excludeFromSemantics: true)))))))
        ]));
  }

  Widget _buildTitle() {
    return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          Expanded(child: Text(widget.appointment.title!, style: TextStyle(fontSize: 24, color: Styles().colors!.fillColorPrimary)))
        ]));
  }

  Widget _buildDetails() {
    List<Widget> details = [];

    Widget? time = _buildTimeDetail();
    if (time != null) {
      details.add(time);
    }

    Widget? location = _buildLocationDetail();
    if (location != null) {
      details.add(location);
    }

    Widget? online = _buildOnlineOnlineDetails();
    if (online != null) {
      details.add(online);
    }

    Widget? host = _buildHostDetail();
    if (host != null) {
      details.add(host);
    }

    Widget? phone = _buildPhoneDetail();
    if (phone != null) {
      details.add(phone);
    }

    Widget? url = _buildUrlDetail();
    if (url != null) {
      details.add(url);
    }

    return (0 < details.length)
        ? Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: details))
        : Container();
  }

  Widget? _buildTimeDetail() {
    String? displayTime = widget.appointment.displayDate;
    if (StringUtils.isEmpty(displayTime)) {
      return null;
    }
    return Semantics(
        label: displayTime,
        excludeSemantics: true,
        child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(children: <Widget>[
              Padding(padding: EdgeInsets.only(right: 10), child: Image.asset('images/icon-calendar.png', excludeFromSemantics: true)),
              Expanded(
                  child: Text(displayTime!,
                      style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Styles().colors!.textBackground)))
            ])));
  }

  Widget? _buildLocationDetail() {
    AppointmentType? type = widget.appointment.type;
    if (type != AppointmentType.in_person) {
      return null;
    }
    String typeLabel = Appointment.typeToDisplayString(type)!;
    String? longDisplayLocation = widget.appointment.getLongDisplayLocation(_locationData) ?? "";
    String? locationTitle = widget.appointment.location?.title;
    String? locationTextValue;
    if (StringUtils.isNotEmpty(longDisplayLocation)) {
      locationTextValue = longDisplayLocation;
    }
    if (StringUtils.isNotEmpty(locationTitle)) {
      if (locationTextValue != null) {
        locationTextValue += ', $locationTitle';
      } else {
        locationTextValue = locationTitle;
      }
    }
    bool isLocationTextVisible = StringUtils.isNotEmpty(locationTextValue);
    return GestureDetector(
        onTap: _onLocationDetailTapped,
        child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Padding(padding: EdgeInsets.only(right: 8), child: Image.asset('images/location.png', excludeFromSemantics: true)),
                    Container(
                        child: Text(typeLabel,
                            style:
                                TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Styles().colors!.textBackground)))
                  ]),
                  Container(height: 4),
                  Visibility(
                      visible: isLocationTextVisible,
                      child: Container(
                          padding: EdgeInsets.only(left: 28),
                          child: Container(
                              padding: EdgeInsets.only(bottom: 2),
                              child: Text(StringUtils.ensureNotEmpty(locationTextValue),
                                  style: TextStyle(
                                      fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Styles().colors!.textBackground)))))
                ])));
  }

  Widget? _buildOnlineOnlineDetails() {
    AppointmentType? type = widget.appointment.type;
    if (type != AppointmentType.online) {
      return null;
    }

    String typeLabel = Appointment.typeToDisplayString(type)!;
    String? meetingId = widget.appointment.onlineDetails?.meetingId;
    String? meetingPasscode = widget.appointment.onlineDetails?.meetingPasscode;
    return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Padding(padding: EdgeInsets.only(right: 8), child: Image.asset('images/laptop.png', excludeFromSemantics: true)),
                Container(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Text(typeLabel,
                        style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Styles().colors!.textBackground)))
              ]),
              Container(height: 4),
              Visibility(
                  visible: StringUtils.isNotEmpty(meetingId),
                  child: Container(
                      padding: EdgeInsets.only(left: 28),
                      child: Container(
                          padding: EdgeInsets.only(bottom: 2),
                          child: Text(
                              Localization().getStringEx('panel.appointment.detail.meeting.id.label', 'Meeting ID:') + ' $meetingId',
                              style: TextStyle(
                                  fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Styles().colors!.textBackground))))),
              Container(height: 4),
              Visibility(
                  visible: StringUtils.isNotEmpty(meetingPasscode),
                  child: Container(
                      padding: EdgeInsets.only(left: 28),
                      child: Container(
                          padding: EdgeInsets.only(bottom: 2),
                          child: Text(
                              Localization().getStringEx('panel.appointment.detail.meeting.passcode.label', 'Passcode:') +
                                  ' $meetingPasscode',
                              style: TextStyle(
                                  fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Styles().colors!.textBackground)))))
            ]));
  }

  Widget? _buildHostDetail() {
    String? hostDisplayName = widget.appointment.hostDisplayName;
    if (StringUtils.isEmpty(hostDisplayName)) {
      return null;
    }
    return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Row(children: <Widget>[
          Padding(padding: EdgeInsets.only(right: 10), child: Image.asset('images/u.png', excludeFromSemantics: true)),
          Expanded(
              child: Text(hostDisplayName!,
                  style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Styles().colors!.textBackground)))
        ]));
  }

  Widget? _buildPhoneDetail() {
    String? phone = widget.appointment.location?.phone;
    if (StringUtils.isEmpty(phone)) {
      return null;
    }
    return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Row(children: <Widget>[
          Padding(padding: EdgeInsets.only(right: 10), child: Image.asset('images/icon-phone.png', excludeFromSemantics: true)),
          Expanded(
              child: Text(phone!,
                  style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Styles().colors!.textBackground)))
        ]));
  }

  Widget? _buildUrlDetail() {
    String? url = Config().saferMcKinley['url'];
    if (StringUtils.isEmpty(url)) {
      return null;
    }
    return InkWell(
        onTap: () => _launchUrl(url),
        child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(children: <Widget>[
              Padding(padding: EdgeInsets.only(right: 10), child: Image.asset('images/external-link.png', excludeFromSemantics: true)),
              Expanded(
                  child: Text(url!,
                      style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Styles().colors!.textBackground)))
            ])));
  }

  //TBD: Appointment - display url and phone with different style
  Widget _buildCancelDescription() {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Html(
            data: Localization().getStringEx('panel.appointment.detail.cancel.description',
                'To cancel an appointment, go to MyMcKinley.illinois.edu or call (217-333-2700) during business hours. To avoid a missed appointment charge, you must cancel your appointment at least two hours prior to your scheduled appointment time.'),
            onLinkTap: (url, renderContext, attributes, element) => _launchUrl(url),
            style: {
              "body": Style(
                  color: Styles().colors!.textSurface,
                  fontFamily: Styles().fontFamilies!.medium,
                  fontSize: FontSize(16),
                  padding: EdgeInsets.zero,
                  margin: EdgeInsets.zero)
            }));
  }

  void _onLocationDetailTapped() {
    if ((widget.appointment.location?.latitude != null) && (widget.appointment.location?.longitude != null)) {
      Analytics().logSelect(target: "Location Detail");
      NativeCommunicator().launchExploreMapDirections(target: widget.appointment);
    }
  }

  void _launchUrl(String? url) {
    if (StringUtils.isNotEmpty(url)) {
      if (UrlUtils.launchInternal(url)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri);
        }
      }
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == LocationServices.notifyStatusChanged) {
      _updateCurrentLocation();
    } else if (name == Auth2UserPrefs.notifyPrivacyLevelChanged) {
      setStateIfMounted(() {});
      _updateCurrentLocation();
    } else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted(() {});
    } else if (name == FlexUI.notifyChanged) {
      setStateIfMounted(() {});
      _updateCurrentLocation();
    }
  }
}
