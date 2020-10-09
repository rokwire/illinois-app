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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DiningService.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/ui/explore/ExploreDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:illinois/service/Styles.dart';
import 'package:location/location.dart';

class LocationsWithSpecialPanel extends StatefulWidget {

  final DiningSpecial special;

  final LocationData locationData;

  final bool onlyOpened;

  LocationsWithSpecialPanel({@required this.special, this.onlyOpened = false, this.locationData});

  _LocationsWithSpecialPanelState createState() => _LocationsWithSpecialPanelState();
}

class _LocationsWithSpecialPanelState extends State<LocationsWithSpecialPanel> {

  bool _isLoading = false;

  List<Dining> _locationList;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  void _loadLocations(){
    setState(() {
      _isLoading = true;
    });

    DiningService().loadBackendDinings(widget.onlyOpened, null, widget.locationData).then((List<Dining> list){
      setState(() {
        _isLoading = false;
      });

      if(list != null){
        if(widget.special.hasLocationIds) {
          _locationList = list.where((location) {
            return widget.special.locationIds.contains(location.id);
          }).toList();
        }
        setState(() {});
      }
    });
  }

  bool get _hasLocations{
    return _locationList != null && _locationList.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx("panel.food_special_offers.title.text", "Specials"),
          style: TextStyle(
              fontFamily: Styles().fontFamilies.extraBold,
              fontSize: 16
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _isLoading
                ? _buildLoading()
                : _buildMainContent(),
          ),
        ],
      ),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildLoading(){
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        )
      ],
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(height: 16,),
                Html(
                  data: widget.special.text ?? "",
                  style: {
                    "body": Style(fontFamily: Styles().fontFamilies.regular, color: Styles().colors.textBackground,)
                  },
                ),
                /*Text(
                  widget.special.text ?? "",
                  style: TextStyle(
                      fontFamily: Styles().fontFamilies.regular,
                      fontSize: 16,
                      color: Styles().colors.textBackground
                  ),
                ),*/
                Container(height: 20,),
                Text(_hasLocations
                    ? Localization().getStringEx("panel.food_special_offers.available.text", "Available at these locations")
                    : Localization().getStringEx("panel.food_special_offers.not_available.text", "No available locations"),
                  style: TextStyle(
                      fontFamily: Styles().fontFamilies.extraBold,
                      fontSize: 16,
                      color: Styles().colors.textBackground
                  ),
                ),
                Container(height: 16,),
              ],
            ),
          ),
          Column(
            children: _buildExploreCards(),
          ),
        ],
      )
    );
  }

  List<Widget> _buildExploreCards(){
    List<Widget> list = List<Widget>();

    if(_hasLocations) {
      for (Dining dining in _locationList) {
        if (list.isNotEmpty) {
          list.add(Container(height: 10,));
        }
        list.add(ExploreCard(
            explore: dining,
            onTap: () => _onDiningTap(dining),
            locationData: widget.locationData,
            hideInterests: true,
            showTopBorder: true)
        );
      }
    }

    return list;
  }

  //Click listeners

  void _onDiningTap(Dining dining) {
    Analytics.instance.logSelect(target: dining.exploreTitle);

    Navigator.push(context, CupertinoPageRoute(
        builder: (context) =>
            ExploreDetailPanel(explore: dining, initialLocationData: widget.locationData,))
    );
  }
}