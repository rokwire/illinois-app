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
import 'package:illinois/model/MTD.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class MTDStopDeparturesPanel extends StatefulWidget  {
  final MTDStop stop;
  final List<MTDRoute>? routes;

  MTDStopDeparturesPanel({required this.stop, this.routes });

  @override
  State<MTDStopDeparturesPanel> createState() => _MTDStopDeparturesPanelState();
}

class _MTDStopDeparturesPanelState extends State<MTDStopDeparturesPanel> {

  List<MTDRoute>? _routes;
  bool _loadingRoutes = false;
  List<MTDDeparture>? _departures;
  bool _loadingDepartures = false;

  @override
  void initState() {
    if (widget.routes != null) {
      _routes = widget.routes;
    }
    else if (widget.stop.id != null) {
      _loadingRoutes = true;
      MTD().getRoutes(stopId: widget.stop.id!).then((List<MTDRoute>? routes) {
        if (mounted) {
          setState(() {
            _loadingRoutes = false;
            _routes = routes;
          });
        }
      });
    }

    if (widget.stop.id != null) {
      _loadingDepartures = true;
      MTD().getDepartures(stopId: widget.stop.id!, previewTime: 1440).then((List<MTDDeparture>? departures) {
        if (mounted) {
          setState(() {
            _loadingDepartures = false;
            _departures = departures;
          });
        }
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: widget.stop.name,),
      body: _buildBody(),
      backgroundColor: Styles().colors?.white,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildBody() {
    return Column(children: <Widget>[
      _buildRoutes(),
      Expanded(child:
        _buildDepartures(),
      ),
    ]);
  }

  Widget _buildRoutes() {
    Widget contentWidget;
    if (_loadingRoutes) {
      contentWidget = Center(child:
        SizedBox(width: 16, height: 16, child:
          CircularProgressIndicator(color: Styles().colors?.mtdColor, strokeWidth: 2,),
        ),
      );
    }
    else if (CollectionUtils.isEmpty(_routes))  {
      contentWidget = Text('NA', style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Colors.black,));
    }
    else {
      List<Widget> routeWidgets = <Widget>[];
      if (_routes != null) {
        for (MTDRoute route in _routes!) {
          routeWidgets.add(Padding(padding: EdgeInsets.only(left: routeWidgets.isNotEmpty ? 6 : 0), child:
            _buildRoute(route)
          ));
        }
      }

      contentWidget = SingleChildScrollView(scrollDirection: Axis.horizontal, child:
        Row(children: routeWidgets)
      );
    }


    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1),),
      ),
      padding: EdgeInsets.all(24),
      child: Row(children: [
        Padding(padding: EdgeInsets.only(right: 8), child:
          Text('Routes:', style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Colors.black38,)),
        ),
        Expanded(child: contentWidget),
      ],),
    );
  }

  Widget _buildDepartures() {
    if (_loadingDepartures) {
      return _buildDeparturesLoading();
    }
    else if (_departures == null) {
      return _buildDeparturesError('Failed to load bus schedule.');
    }
    else if (_departures!.isEmpty) {
      return _buildDeparturesError('No bus schedule available.');
    }
    else {
      return SingleChildScrollView(scrollDirection: Axis.vertical, child:
          Column(children: _buildDeparturesList(),)
        );
    }
  }

  List<Widget> _buildDeparturesList() {
    List<Widget> contentList = <Widget>[];
    if (_departures != null) {
      for (MTDDeparture departure in _departures!) {
        contentList.add(_buildDeparture(departure));
      }
    }
    return contentList;
  }

  Widget _buildDeparture(MTDDeparture departure) {
    String? status = (departure.isScheduled == true) ? 'Scheduled' : null;
    DateTime? expectedTime = departure.expectedTime;
    String? expectedTimeString = (expectedTime != null) ? DateFormat('h:mm').format(expectedTime) : null;
    String? expectedAMPMString = (expectedTime != null) ? DateFormat('a').format(expectedTime) : null;
    
    return InkWell(onTap: () => _onDeparture(departure), child: Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1),),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Padding(padding: EdgeInsets.only(right: 6), child:
            Image.asset('images/icon-bus-solid.png', color: Styles().colors?.fillColorPrimary,),
          ),
          (departure.route != null) ? Padding(padding: EdgeInsets.only(right: 6), child: _buildRoute(departure.route!)) : Container(),
          Expanded(child:
            Text(departure.trip?.headsign ?? '', style: TextStyle(fontFamily: Styles().fontFamilies?.medium, fontSize: 16, color: Styles().colors?.textBackground,),)
          ),
          Text(expectedTimeString ?? '', style: TextStyle(fontFamily: Styles().fontFamilies?.medium, fontSize: 16, color: Styles().colors?.textBackground,),)
        ],),
        Row(children: [
          Expanded(child:
            Text(status ?? '', style: TextStyle(fontFamily: Styles().fontFamilies?.medium, fontSize: 16, color: Styles().colors?.textBackground,),)
          ),
          Text(expectedAMPMString ?? '', style: TextStyle(fontFamily: Styles().fontFamilies?.medium, fontSize: 16, color: Styles().colors?.textBackground,),),
        ]),
      ],),
    ),);
  }

  Widget _buildRoute(MTDRoute route) {
    return Container(decoration: BoxDecoration(color: route.color, border: Border.all(color: route.textColor ?? Colors.transparent, width: 1), borderRadius: BorderRadius.circular(5)), child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), child:
        Text(route.shortName ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 12, color: route.textColor,)),
      )
    );
  }

  Widget _buildDeparturesLoading() {
    return Row(children: [
      Expanded(child:
        Column(children: [
          Expanded(child:
            Align(alignment: Alignment.center, child:
              CircularProgressIndicator(color: Styles().colors?.mtdColor, strokeWidth: 3, )
            ),
          ),
        ],),
      ),
    ]);
  }

  Widget _buildDeparturesError(String? error) {
    return Row(children: [
      Expanded(child:
        Column(children: [
          Expanded(child:
            Align(alignment: Alignment.center, child:
              Padding(padding: EdgeInsets.only(left: 32, right: 32, top: 24, bottom: 24), child:
                Row(children: [
                  Expanded(child:
                    Text(error ?? '', style:
                      Styles().textStyles?.getTextStyle("widget.message.large"), textAlign: TextAlign.center,),
                  ),
                ],)
              )
            ),
          ),
        ],))
    ]);
  }

  void _onDeparture(MTDDeparture departure) {
    //TBD
  }
}
