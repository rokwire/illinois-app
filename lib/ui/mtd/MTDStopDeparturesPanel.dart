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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/ui/mtd/MTDWidgets.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class MTDStopDeparturesPanel extends StatefulWidget  {
  final MTDStop stop;

  MTDStopDeparturesPanel({required this.stop });

  @override
  State<MTDStopDeparturesPanel> createState() => _MTDStopDeparturesPanelState();
}

class _MTDStopDeparturesPanelState extends State<MTDStopDeparturesPanel> implements NotificationsListener {

  List<MTDDeparture>? _departures;
  bool _loadingDepartures = false;
  bool _updatingDepartures = false;
  bool _refreshingDepartures = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);

    _refreshTimer = Timer.periodic(Duration(minutes: 1), (time) => _updateDepartures());

    if (widget.stop.id != null) {
      _loadingDepartures = _refreshingDepartures = _updatingDepartures = true;
      MTD().getDepartures(stopId: widget.stop.id!, previewTime: 1440).then((List<MTDDeparture>? departures) {
        if (mounted) {
          setState(() {
            _loadingDepartures = _refreshingDepartures = _updatingDepartures = false;
            _departures = departures;
          });
        }
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _refreshTimer?.cancel();
    _refreshTimer = null;
    super.dispose();
  }

 // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      if (mounted) {
        setState(() {
        });
      }
    }
  }

  void _updateDepartures() {
    if ((widget.stop.id != null) && !_updatingDepartures && !_refreshingDepartures && mounted) {
      _updatingDepartures = true;
      MTD().getDepartures(stopId: widget.stop.id!, previewTime: 1440).then((List<MTDDeparture>? departures) {
        if (_updatingDepartures && !_refreshingDepartures) {
          _updatingDepartures = false;
          if (mounted && (departures != null) && !DeepCollectionEquality().equals(_departures, departures)) {
            setState(() {
              _departures = departures;
            });
          }
        }
      });
    }
  }

  Future<void> _refreshDepartures() async {
    if ((widget.stop.id != null) && !_refreshingDepartures) {
      _refreshingDepartures = true;
      _updatingDepartures = false;
      List<MTDDeparture>? departures = await MTD().getDepartures(stopId: widget.stop.id!, previewTime: 1440);
      if (_refreshingDepartures) {
        _refreshingDepartures = false;
        if (mounted && (departures != null) && !DeepCollectionEquality().equals(_departures, departures)) {
          setState(() {
            _departures = departures;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: widget.stop.name,
        actions: [
          FavoriteButton(favorite: widget.stop, style: FavoriteIconStyle.SlantHeader)
        ],
      ),
      body: _buildBody(),
      backgroundColor: Styles().colors?.white,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildBody() {
    return Column(children: <Widget>[
      //_buildRoutes(),
      Expanded(child:
        _buildDepartures(),
      ),
    ]);
  }

  /*Widget _buildRoutes() {
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
  }*/

  Widget _buildDepartures() {
    if (_loadingDepartures) {
      return _buildDeparturesLoading();
    }
    else if (_departures == null) {
      return RefreshIndicator(onRefresh: _refreshDepartures, child: _buildDeparturesError('Failed to load bus schedule.'));
    }
    else if (_departures!.isEmpty) {
      return RefreshIndicator(onRefresh: _refreshDepartures, child: _buildDeparturesError('No bus schedule available.'));
    }
    else {
      return RefreshIndicator(onRefresh: _refreshDepartures, child: _buildDeparturesList());
    }
  }

  Widget _buildDeparturesList() {
    return ListView.separated(
      itemBuilder: (context, index) => _buildDeparture(ListUtils.entry(_departures, index)),
      separatorBuilder: (context, index) => Divider(height: 1, color: Styles().colors!.fillColorPrimaryTransparent03,),
      itemCount: _departures?.length ?? 0,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildDeparture(MTDDeparture? departure) {
    return (departure != null) ? MTDDepartureCard(departure: departure, onTap: () => _onDeparture(departure),) : Container();
  }

  /*Widget _buildRoute(MTDRoute route) {
    return Container(decoration: BoxDecoration(color: route.color, border: Border.all(color: route.textColor ?? Colors.transparent, width: 1), borderRadius: BorderRadius.circular(5)), child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), child:
        Text(route.shortName ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 12, color: route.textColor,)),
      )
    );
  }*/

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
    return 
    Row(children: [
      Expanded(child:
        Column(children: [
          Expanded(child:
            SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child:
              Align(alignment: Alignment.center, child:
                Padding(padding: EdgeInsets.only(left: 32, right: 32, top: 96, bottom: 24), child:
                  Row(children: [
                    Expanded(child:
                      Text(error ?? '', style:
                        Styles().textStyles?.getTextStyle("widget.message.large"), textAlign: TextAlign.center,),
                    ),
                  ],)
                )
              ),
            ),
          ),
        ],)
      )
    ]);
  }

  void _onDeparture(MTDDeparture departure) {
    //TBD
  }
}
