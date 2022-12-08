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
import 'package:geolocator/geolocator.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/explore/ExploreDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ExploreListPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final List<Explore>? explores;
  final Position? initialLocationData;

  ExploreListPanel({this.explores, this.initialLocationData});

  @override
  _ExploreListPanelState createState() =>
      _ExploreListPanelState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes {
    if ((explores != null) && explores!.isNotEmpty) {
      return { Analytics.LogAttributeLocation : explores!.first.exploreLocation?.description };
    }
    else {
      return null;
    }

  }
}

class _ExploreListPanelState extends State<ExploreListPanel> {

  List<Explore>? _explores;

  @override
  void initState() {
    super.initState();
    if (widget.explores != null) {
      _explores = widget.explores;
      //Sort "only for when we go to details from map view and there is a list of items because of the map grouping"
      SortUtils.sort(_explores);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.explore_list.header.title", "Explore"),
      ),
      body: _buildBody(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildBody() {
    return Column(children: <Widget>[
      Expanded(
          child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[_buildListViewWidget()],
              ))),
    ]);
  }

  Widget _buildListViewWidget() {
    if (_explores == null || _explores!.length == 0) {
      return Container();
    }
    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      separatorBuilder: (context, index) =>
          Divider(
            color: Colors.transparent,
          ),
      itemCount: _explores!.length,
      itemBuilder: (context, index) {
        Explore explore = _explores![index];
        ExploreCard exploreView = ExploreCard(
            explore: explore,
            onTap: () => _onExploreTap(explore),
            locationData: widget.initialLocationData,
            showTopBorder: true);
        return Padding(
            padding: EdgeInsets.only(top: 16),
            child: exploreView);
      },
    );
  }

  void _onExploreTap(Explore explore) {
    Analytics().logSelect(target: explore.exploreTitle);

    //show the detail panel
    Widget? detailPanel = ExploreDetailPanel.contentPanel(explore: explore, initialLocationData: widget.initialLocationData,);
    if (detailPanel != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => detailPanel));
    }
  }
}
