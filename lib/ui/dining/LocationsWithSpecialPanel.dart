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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/explore/ExploreDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class LocationsWithSpecialPanel extends StatefulWidget {

  final DiningSpecial? special;

  final Position? locationData;

  final bool onlyOpened;

  LocationsWithSpecialPanel({required this.special, this.onlyOpened = false, this.locationData});

  _LocationsWithSpecialPanelState createState() => _LocationsWithSpecialPanelState();
}

class _LocationsWithSpecialPanelState extends State<LocationsWithSpecialPanel> {

  bool _isLoading = false;

  List<Dining>? _locationList;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  void _loadLocations(){
    setState(() {
      _isLoading = true;
    });

    Dinings().loadBackendDinings(widget.onlyOpened, null, widget.locationData).then((List<Dining>? list){
      setState(() {
        _isLoading = false;
      });

      if(list != null){
        if(widget.special!.hasLocationIds) {
          _locationList = list.where((location) {
            return widget.special!.locationIds!.contains(location.id);
          }).toList();
        }
        setState(() {});
      }
    });
  }

  bool get _hasLocations{
    return _locationList != null && _locationList!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.food_special_offers.title.text", "Dining News"),
        //textStyle: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 16 ),
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
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
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
                HtmlWidget(
                    StringUtils.ensureNotEmpty(widget.special!.text),
                    textStyle: Styles().textStyles?.getTextStyle("widget.item.regular.thin")
                ),
                // Html(
                //   data: widget.special!.text ?? "",
                //   style: {
                //     "body": Style(fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.textBackground,)
                //   },
                // ),
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
                  style: Styles().textStyles?.getTextStyle("widget.item.regular.extra_fat")
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
    List<Widget> list = [];

    if(_hasLocations) {
      for (Dining? dining in _locationList!) {
        if (list.isNotEmpty) {
          list.add(Container(height: 10,));
        }
        list.add(ExploreCard(
            explore: dining,
            onTap: () => _onDiningTap(dining!),
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
    Analytics().logSelect(target: dining.exploreTitle);

    Navigator.push(context, CupertinoPageRoute(
        builder: (context) =>
            ExploreDetailPanel(explore: dining, initialLocationData: widget.locationData,))
    );
  }
}