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

import 'package:flutter/material.dart';
import 'package:illinois/model/Parking.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Transportation.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class ParkingEventPanel extends StatefulWidget{

  final ParkingEvent? event;

  ParkingEventPanel({this.event});

  _ParkingEventPanelState createState() => _ParkingEventPanelState();
}

class _ParkingEventPanelState extends State<ParkingEventPanel>{

  bool _isLoading = false;

  List<ParkingLot>? _eventLots;

  @override
  void initState() {
    super.initState();

    _loadInventory();
  }

  void _loadInventory(){
    setState(() {
      _isLoading = true;
    });
    Transportation().loadParkingEventInventory(widget.event!.id).then((List<ParkingLot>? eventLots){
      _eventLots = eventLots;
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(
        Localization().getStringEx("panel.parking_lots.label.heading","Parking Spots"),
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0),
        ),
      ),
      body: _buildScaffoldBody(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildScaffoldBody() {
    return Column(
      children: <Widget>[
        Expanded(
          child:
          _isLoading
          ? Column(
              children: <Widget>[
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded( child:
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            CircularProgressIndicator(),
                            Container(height: 5,),
                            Row(children:[
                              Expanded(child:
                                Text(
                                  Localization().getStringEx("panel.parking_lots.label.loading", "Loading parking lots. Please wait..."),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: Styles().fontFamilies!.regular,
                                    fontSize: 16,
                                    color: Styles().colors!.mediumGray,
                                  ),
                                )
                              )
                            ])
                          ],
                        )
                      )
                    ],
                  ),
                )
              ],
            )
          : SingleChildScrollView(
            child: _buildLots(),
          ),
        )
      ],
    );
  }

  Widget _buildLots(){
    List<Widget> widgets = [];
    if(CollectionUtils.isNotEmpty(_eventLots)){
      for(ParkingLot inventory in _eventLots! ){
        if(inventory.totalSpots != null && inventory.totalSpots! > 0){
          if(widgets.isNotEmpty){
            widgets.add(Container(height: 1,));
          }
          widgets.add( _ParkingLotWidget(inventory: inventory,));
        }
      }
    }
    if(CollectionUtils.isEmpty(widgets)){
      widgets.add(Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(Localization().getStringEx("panel.parking_lots.label.empty","No parking lots available for this event"),
          style: TextStyle(
            fontFamily: Styles().fontFamilies!.regular,
            fontSize: 16,
            color: Styles().colors!.textBackground,
          ),
        ),
      ));
    }


    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.event?.name ?? "",
            style: TextStyle(
              fontSize: 20,
              color: Styles().colors!.fillColorPrimary,
            ),
          ),
        ),
        Column(
          children: widgets,
        )
      ],
    );
  }
}

class _ParkingLotWidget extends StatefulWidget {
  final ParkingLot? inventory;

  _ParkingLotWidget({Key? key, this.inventory}) : super(key: key);

  @override
  _ParkingLotWidgetState createState() => _ParkingLotWidgetState();
}

class _ParkingLotWidgetState extends State<_ParkingLotWidget> implements NotificationsListener {

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [FlexUI.notifyChanged,]);
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool directionsVisible = FlexUI().hasFeature('parking_lot_directions') && (widget.inventory!.entrance != null);
    return Semantics(container: true, child: Container(color: Colors.white, child: Row(
      children: <Widget>[
        Expanded(
          flex: 5,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.inventory!.lotName!,
                  style: TextStyle(
                    fontFamily: Styles().fontFamilies!.bold,
                    fontSize: 18,
                    color: Styles().colors!.fillColorPrimary,
                  ),
                ),
                Text(
                  "${StringUtils.ensureNotEmpty(widget.inventory!.lotAddress)}",
                  style: TextStyle(
                    fontFamily: Styles().fontFamilies!.medium,
                    fontSize: 16,
                    color: Styles().colors!.fillColorPrimary,
                  ),
                ),
                Text(
                  Localization().getStringEx("panel.parking_lots.label.available_spots", "Available Spots: ") + "${widget.inventory!.availableSpots}",
                  style: TextStyle(
                    fontFamily: Styles().fontFamilies!.regular,
                    fontSize: 16,
                    color: Styles().colors!.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Semantics(explicitChildNodes: true, child: Visibility(
          visible: directionsVisible, child: Padding(padding: EdgeInsets.only(right: 8), child: RoundedButton(
            label: Localization().getStringEx('panel.parking_lots.button.directions.title', 'Directions'),
            hint: Localization().getStringEx('panel.parking_lots.button.directions.hint', ''),
            backgroundColor: Colors.white,
            fontSize: 16.0,
            textColor: Styles().colors!.fillColorPrimary,
            borderColor: Styles().colors!.fillColorSecondary,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            onTap: _onTapDirections),),))
        )
      ],
    ),));
  }

  void _onTapDirections() {
    Analytics().logSelect(target: 'Parking Lot Directions');
    NativeCommunicator().launchExploreMapDirections(target: widget.inventory);
  }
}
