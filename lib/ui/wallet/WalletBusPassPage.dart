/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:illinois/ui/wallet/WalletHomePanel.dart';
import 'package:illinois/ui/wallet/WalletPhotoWrapper.dart';
import 'package:rokwire_plugin/model/geo_fence.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/geo_fence.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Transportation.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class WalletBusPassPage extends StatefulWidget with WalletHomePage {
  final double topOffset;
  WalletBusPassPage({super.key, this.topOffset = 0});

  @override
  State<StatefulWidget> createState() => _WalletBusPassPageState();

  @override
  Color get backgroundColor => Styles().colors.fillColorPrimaryVariant;
}

class _WalletBusPassPageState extends State<WalletBusPassPage> with NotificationsListener {
  Color? _activeBusColor;
  String? _activeBusNumber;
  bool _loadingActiveBusDetails = false;
  Set<String> _rangingRegionIds = Set();
  GeoFenceBeacon? _currentBeacon;

  Color get _headingColor =>
    _loadingActiveBusDetails ? widget.backgroundColor : (_activeBusColor ?? Styles().colors.fillColorSecondary);

  Color get _displayBusColor =>
    _loadingActiveBusDetails ? Styles().colors.white : (_activeBusColor ?? Styles().colors.fillColorSecondary);

  String? get _busNumber =>
    StringUtils.ensureNotEmpty(_activeBusNumber, defaultValue: '');

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      GeoFence.notifyCurrentRegionsUpdated,
      GeoFence.notifyCurrentBeaconsUpdated,
      FlexUI.notifyChanged,
    ]);

    _updateRangingRegions();
    _loadBusPass();
    // Auth2().updateAuthCard();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _stopRangingRegions();
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == GeoFence.notifyCurrentRegionsUpdated) {
      _updateRangingRegions();
    }
    else if (name == GeoFence.notifyCurrentBeaconsUpdated) {
      _updateCurrentBeacon();
    }
    else if (name == FlexUI.notifyChanged) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
    WalletPhotoWrapper(
      topOffset: widget.topOffset,
      headingColor: _headingColor,
      backgroundColor: widget.backgroundColor,
      child: _buildBusContent(),
    );

  Widget _buildBusContent() {
    bool busPassAvailable = FlexUI().isMTDBusPassAvailable;
    String description = busPassAvailable ?
      Localization().getStringEx("panel.bus_pass.description.text", "Show this screen to the bus operator as you board.") :
      Localization().getStringEx("panel.bus_pass.error.disabled.text", "You do not have an MTD Bus Pass.");
    return SingleChildScrollView(scrollDirection: Axis.vertical, child:
      Column(children: <Widget>[
        Text(Auth2().iCard?.role ?? '', style: Styles().textStyles.getTextStyle("panel.mtd_bus.role")),
        _BusClock(),
        Align(alignment: Alignment.center, child:
          Padding(padding: EdgeInsets.only(top: 10), child:
            _buildBusNumberContent()
          )
        ),
        Align(alignment: Alignment.center, child:
          Padding(padding: EdgeInsets.only(top: 20), child:
            Opacity(opacity: busPassAvailable ? 1 : 0, child:
              Styles().images.getImage('transit-logo', excludeFromSemantics: true)
            )
          ),
        ),
        Align(alignment: Alignment.center, child:
          Container(width: WalletPhotoWrapper.photoSize(context), padding: EdgeInsets.only(top: 12, left: 6, right: 6), child:
            Text(description, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("panel.mtd_bus.description.label")),
          ),
        ),
      ],)
    );
  }

  Widget _buildBusNumberContent() {
    bool busNumberVisible = StringUtils.isNotEmpty(_busNumber);
    return Visibility(visible: busNumberVisible, child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildBusIcon(),
        Container(width: 8,),
        Container(
          child: Text(_busNumber!, style: Styles().textStyles.getTextStyle("panel.mtd_bus.buss_number.label"),),
        ),
      ],
    ));
  }

  Widget _buildBusIcon(){
    final double iconSize = 24;
    return Container(width: iconSize-1, height: iconSize-1, color: _displayBusColor, child:
      Styles().images.getImage('transit-logo-cutout-dark', excludeFromSemantics: true, width: iconSize, height: iconSize,),
    );
  }

  void _loadBusPass() {
    setStateIfMounted(() {
      _loadingActiveBusDetails = true;
    });

    String? deviceId = Auth2().deviceId; //TMP: '1234'
    Map<String, dynamic>? beaconData = (_currentBeacon != null) ? {
      'uuid': _currentBeacon!.uuid,
      'major': _currentBeacon!.major.toString(),
      'minor': _currentBeacon!.minor.toString(),
    } : null;
    Transportation().loadBusPass(deviceId: deviceId, userId: Auth2().accountId, iBeaconData: beaconData).then((dynamic result){
      if (mounted) {
        if (result is Map) {
          setState(() {
              _activeBusColor = UiColors.fromHex(JsonUtils.stringValue(result['color']));
              _activeBusNumber = JsonUtils.stringValue(result['bus_number']);
              _loadingActiveBusDetails = false;
            });
        }
        else {
          setState(() {
            _loadingActiveBusDetails = false;
          });
          String? message = ((result is int) && (result == 403)) ?
            Localization().getStringEx("panel.bus_pass.error.duplicate.text", "This MTD bus pass has already been displayed on another device.\n\nOnly one device can display the MTD bus pass per Illini ID.") :
            Localization().getStringEx("panel.bus_pass.error.default.text", "Unable to load bus pass");
          AppAlert.showDialogResult(context, message,);
        }
      }
    });
  }

  void _updateCurrentBeacon() {
    GeoFenceBeacon? currentBeacon = _getCurrentBeacon();
    if (((_currentBeacon == null) && (currentBeacon != null)) || ((_currentBeacon != null) && (_currentBeacon != currentBeacon))) {
      _currentBeacon = currentBeacon;
      _loadBusPass();
    }
  }

  GeoFenceBeacon? _getCurrentBeacon() {
    // Just return the first beacon that we have for now.
    for (String regionId in _rangingRegionIds) {
      Set<GeoFenceBeacon>? regionBacons = GeoFence().currentBeaconsInRegion(regionId);
      if ((regionBacons != null) && regionBacons.isNotEmpty) {
        return regionBacons.first;
      }
    }
    return null;
  }

  void _updateRangingRegions() {
    Set<String> currentRegionIds = GeoFence().currentRegionIds;

    // 1. Remove all ranging regions that are not current (inside)
    Set<String>? removeRegionIds;
    for (String regionId in _rangingRegionIds) {
      if (!currentRegionIds.contains(regionId)) {
        GeoFence().stopRangingBeaconsInRegion(regionId);
        if (removeRegionIds == null) {
          removeRegionIds = Set();
        }
        removeRegionIds.add(regionId);
      }
    }
    if (removeRegionIds != null) {
      _rangingRegionIds.removeAll(removeRegionIds);
    }

    // 2. Start ranging for all current (inside) regions that are not already raning.
    for (String regionId in currentRegionIds) {
      GeoFenceRegion region = GeoFence().regions![regionId]!;
      if ((region.regionType == GeoFenceRegionType.beacon) && region.types!.contains('MTD') && !_rangingRegionIds.contains(regionId)) {
        GeoFence().startRangingBeaconsInRegion(regionId).then((_) {
          _rangingRegionIds.add(regionId);
        });
      }
    }
  }

  void _stopRangingRegions() {
    for (String regionId in _rangingRegionIds) {
      GeoFence().stopRangingBeaconsInRegion(regionId);
    }
    _rangingRegionIds.clear();
  }
}

class _BusClock extends StatefulWidget{
  @override
  State<StatefulWidget> createState() =>_BusClockState();

}

class _BusClockState extends State<_BusClock> {
  Timer? _timer;

  @override
  void initState() {
    _timer = Timer.periodic(Duration(seconds: 1), (time) => _updateTime());
    super.initState();
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_timeString!, style: Styles().textStyles.getTextStyle("panel.mtd_bus.clock.time"));
  }

  void _updateTime() {
    setState(() {});
  }

  String? get _timeString {
    return AppDateTime().formatUniLocalTimeFromUtcTime(DateTime.now(), "hh:mm:ss");
  }

}