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
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/GeoFence.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/GeoFence.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/TransportationService.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class MTDBusPassPanel extends StatefulWidget {
  _MTDBusPassPanelState createState() => _MTDBusPassPanelState();
}

class _MTDBusPassPanelState extends State<MTDBusPassPanel> implements NotificationsListener {
  final double _headingH1 = 180;
  final double _headingH2 = 80;
  final double _photoSize = 240;
  final double _iconSize = 64;

  Color _activeBussColor;
  String _activeBusNumber;
  Set<String> _rangingRegionIds = Set();
  GeoFenceBeacon _currentBeacon;

  MemoryImage _photoImage;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      Auth.notifyCardChanged,
      GeoFence.notifyCurrentRegionsUpdated,
      GeoFence.notifyCurrentBeaconsUpdated,
      FlexUI.notifyChanged,
    ]);

    _updateRangingRegions();
    _loadBussPass();
    _loadPhotoImage();
    // Auth().updateAuthCard();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _stopRangingRegions();
    super.dispose();
  }

  void _loadPhotoImage(){
    _loadAsyncPhotoImage().then((MemoryImage photoImage){
      _photoImage = photoImage;
      setState(() {});
    });
  }

  Future<MemoryImage> _loadAsyncPhotoImage() async{
    Uint8List photoBytes = await  Auth().authCard.photoBytes;
    if(AppCollection.isCollectionNotEmpty(photoBytes)){
      return await compute(AppImage.memoryImageWithBytes, photoBytes);
    }
    return null;
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth.notifyCardChanged) {
      if (mounted) {
        _loadPhotoImage();
      }
    } else if (name == FlexUI.notifyChanged) {
      if (mounted) {
        setState(() {});
      }
    }
    else if (name == GeoFence.notifyCurrentRegionsUpdated) {
      _updateRangingRegions();
    }
    else if (name == GeoFence.notifyCurrentBeaconsUpdated) {
      _updateCurrentBeacon();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget contentWidget = (Auth().authCard != null) ? _buildBussContent() : Container();
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                height: _headingH1,
                color: _activeColor,
              ),
              Container(
                height: _headingH2,
                color: _activeColor,
                child: CustomPaint(
                  painter: TrianglePainter(painterColor: _backgroundColor),
                  child: Container(),
                ),
              ),
              Expanded(
                  child: Container(
                color: _backgroundColor,
              ))
            ],
          ),
          Column(children: <Widget>[
            Expanded(child:contentWidget),
            SafeArea(
              child: Align(
                  alignment: Alignment.bottomCenter, child:
                    Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child:Semantics(button: true,label: Localization().getStringEx("panel.buss_pass.button.close.title", "close"), child:
                      InkWell(
                        onTap: _onClose,
                        child:  Image.asset('images/close-white-large.png', excludeFromSemantics: true,)
                      ),
                    ))),
            ),
          ]),
          SafeArea(
            child: Stack(
              children: <Widget>[
                Padding(
                    padding: EdgeInsets.all(16),
                    child:Semantics(header: true, child: Text(
                      Localization().getStringEx("panel.buss_pass.header.title", "MTD Bus Pass"),
                      style: TextStyle(color: Color(0xff0f2040), fontFamily: Styles().fontFamilies.extraBold, fontSize: 20),
                    ),
                    )),
                Align(
                    alignment: Alignment.topRight,
                    child:Semantics(button: true,label: Localization().getStringEx("panel.buss_pass.button.close.title", "close"), child:
                    InkWell(
                        onTap: _onClose, child: Container(width: 48, height: 48, alignment: Alignment.center, child: Image.asset('images/close-blue.png', excludeFromSemantics: true,))),
                    )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBussContent() {
    String role = Auth().authCard?.role;
    return SingleChildScrollView(scrollDirection: Axis.vertical, child:
      Column(
        children: <Widget>[
          _buildAvatar(),
          Text(
            role,
            style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 36, color: Styles().colors.white),
          ),
          BussClockWidget(),
          Align(alignment: Alignment.center, child: Padding(padding: EdgeInsets.only(top: 10), child: _buildBussNumberContent())),
          Align(alignment: Alignment.center, child: Padding(padding: EdgeInsets.only(top: 20), child: Image.asset('images/mtd-logo.png', excludeFromSemantics: true,))),
          Align(
              alignment: Alignment.center,
              child: Container(
                width: _photoSize,
                padding: EdgeInsets.only(top: 12, left: 6, right: 6),
                child: Text(
                  Localization().getStringEx("panel.buss_pass.description.text", "Show this screen to the bus driver as you board."),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: Styles().fontFamilies.regular,
                    fontSize: 16,
                    color: Styles().colors.white,
                  ),
                ),
              )),
        ],
      )
    );
  }

  Widget _buildAvatar() {

    return Padding(
      padding: EdgeInsets.only(top: _headingH1 + (_headingH2 - _photoSize) / 2),
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: RotatingBorder(
              activeColor: _activeColor,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: _buildPhotoImage()
                )),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
                padding: EdgeInsets.only(top: _photoSize - _iconSize / 2 - 5, left: 15),
                child: Image.asset(
                  'images/group-5-blue.png',
                  excludeFromSemantics: true,
                  width: _iconSize,
                  height: _iconSize,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoImage(){
    return _photoImage != null
        ? Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            image: DecorationImage(
              fit: BoxFit.cover,
              alignment: Alignment.center,
              image: _photoImage,
            ),
          ))
        : Container(
            decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ));
  }

  Widget _buildBussNumberContent() {
    bool busNumberVisible = FlexUI().hasFeature('mtd_bus_number') && AppString.isStringNotEmpty(_busNumber);
    return Visibility(visible: busNumberVisible, child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildBusIcon(),
        Container(width: 8,),
        Container(
          child: Text(_busNumber,
              style: TextStyle(
                fontFamily: Styles().fontFamilies.bold,
                fontSize: 36,
                color: Styles().colors.white,
              )),
        ),
      ],
    ));
  }

  Widget _buildBusIcon(){
    double iconSize = 25;
    return Container(
      width: iconSize-1,
      height: iconSize-1,
      color: _activeColor,
      child: Image.asset(
        'images/transparent-buss-icon.png',
        excludeFromSemantics: true,
        width: iconSize,
        height: iconSize,
      ),
    );
  }

  void _loadBussPass() async {
    String deviceId = await NativeCommunicator().getDeviceId(); //TMP: '1234'
    Map<String, dynamic> beaconData = (_currentBeacon != null) ? {
      'uuid': _currentBeacon.uuid,
      'major': _currentBeacon.major.toString(),
      'minor': _currentBeacon.minor.toString(),
    } : null;
    TransportationService().loadBussPass(deviceId: deviceId, userId: User().uuid, iBeaconData: beaconData).then((dynamic result){

      if (result is Map) {
        setState(() {
            _activeBussColor = UiColors.fromHex(result["color"]);
            _activeBusNumber = result["bus_number"];
          });
      }
      else {
        String message = ((result is int) && (result == 403)) ?
          Localization().getStringEx("panel.buss_pass.error.duplicate.text", "This MTD bus pass has already been displayed on another device.\n\nOnly one device can display the MTD bus pass per Illini ID.") :
          Localization().getStringEx("panel.buss_pass.error.default.text", "Unable to load buss pass");
        AppAlert.showDialogResult(context, message,).then((result){
          Navigator.pop(context);
        });
      }
    });
  }

  void _updateCurrentBeacon() {
    GeoFenceBeacon currentBeacon = _getCurrentBeacon();
    if (((_currentBeacon == null) && (currentBeacon != null)) || ((_currentBeacon != null) && (_currentBeacon != currentBeacon))) {
      _currentBeacon = currentBeacon;
      _loadBussPass();
    }
  }

  GeoFenceBeacon _getCurrentBeacon() {
    // Just return the first beacon that we have for now.
    for (String regionId in _rangingRegionIds) {
      List<GeoFenceBeacon> regionBacons = GeoFence().currentBeaconsInRegion(regionId);
      if ((regionBacons != null) && regionBacons.isNotEmpty) {
        return regionBacons.first;
      }
    }
    return null;
  }

  void _updateRangingRegions() {
    Set<String> currentRegionIds = GeoFence().currentRegionIds;
    
    // 1. Remove all ranging regions that are not current (inside)
    Set<String> removeRegionIds;
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
      GeoFenceRegion region = GeoFence().regions[regionId];
      if ((region.regionType == GeoFenceRegionType.Beacon) && region.types.contains('MTD') && !_rangingRegionIds.contains(regionId)) {
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

  void _onClose() {
    Navigator.of(context).pop();
  }

  Color get _activeColor {
    return _activeBussColor??Styles().colors.fillColorSecondary;
  }

  Color get _backgroundColor {
    return Styles().colors.fillColorPrimaryVariant;
  }

  String get _busNumber {
    return AppString.getDefaultEmptyString(value: _activeBusNumber, defaultValue: '');
  }
}

class RotatingBorder extends StatefulWidget{
  final Widget child;
  final Color activeColor;
  final Color baseGradientColor;
  const RotatingBorder({Key key, this.child, this.activeColor, this.baseGradientColor}) : super(key: key);

  @override
  _RotatingBorderState createState() => _RotatingBorderState();

}

class _RotatingBorderState extends State<RotatingBorder>
    with SingleTickerProviderStateMixin{
  final double _photoSize = 240;
  Animation<double> animation;
  AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: Duration(hours: 1),animationBehavior: AnimationBehavior.preserve);
    animation = Tween<double>(begin: 0, end: 15000,).animate(controller)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller.repeat().orCancel;

        } else if (status == AnimationStatus.dismissed) {
          controller.forward();
        }
      });
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double angle = animation.value;
    return Container( width: _photoSize, height: _photoSize,
        child:Stack(children: <Widget>[
      Transform.rotate(
          angle: angle,
          child:Container(
            height: _photoSize,
            width: _photoSize,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [widget.activeColor, widget.baseGradientColor ?? Styles().colors.fillColorSecondary],
                  stops:  [0.0, 1.0],
                )
            ),
          )),
      widget.child,
    ], ));
  }

}

class BussClockWidget extends StatefulWidget{
  @override
  State<StatefulWidget> createState() =>_BussClockState();

}

class _BussClockState extends State<BussClockWidget> {
  Timer _timer;

  @override
  void initState() {
    _timer = Timer.periodic(Duration(seconds: 1), (time) => _updateTime());
    super.initState();
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _timeString,
      style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 48, color: Styles().colors.white),
    );
  }

  void _updateTime() {
    setState(() {});
  }

  String get _timeString {
    return AppDateTime().formatUniLocalTimeFromUtcTime(DateTime.now(), "hh:mm:ss");
  }

}