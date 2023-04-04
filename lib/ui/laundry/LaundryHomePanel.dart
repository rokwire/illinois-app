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
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/laundry/LaundryRoomDetailPanel.dart';
import 'package:illinois/ui/laundry/LaundryListPanel.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';


class LaundryHomePanel extends StatefulWidget {
  final LaundrySchool? laundrySchool;

  LaundryHomePanel({Key? key, this.laundrySchool}) : super(key: key);

  @override
  _LaundryHomePanelState createState() => _LaundryHomePanelState();
}

class _LaundryHomePanelState extends State<LaundryHomePanel> {
  LaundrySchool? _laundrySchool;
  bool _loading = false;

  @override
  void initState() {
    super.initState();


    _laundrySchool = widget.laundrySchool;
    if (_laundrySchool == null) {
      _loadSchool();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.laundry_home.heading.laundry', 'Laundry'),),
      body: _loading ? Center(child: CircularProgressIndicator(),) : _buildContentWidget(),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  /*PreferredSizeWidget _buildHeaderBar() {
    return AppBar(
      leading: Semantics(
        label: Localization().getStringEx('headerbar.back.title', 'Back'),
        hint: Localization().getStringEx('headerbar.back.hint', ''),
        button: true,
        child: IconButton(
          icon: Styles().images?.getImage('images/chevron-left-white.png', excludeFromSemantics: true),
          onPressed: _onTapBack)
        ),
      actions: <Widget>[
        Column(children: <Widget>[
          Expanded(child:
            Row(children: <Widget>[
              ExploreViewTypeTab(
                label: Localization().getStringEx('panel.laundry_home.button.list.title', 'List'),
                hint: Localization().getStringEx('panel.laundry_home.button.list.hint', ''),
                iconResource: 'images/icon-list-view.png',
                selected: (_displayType == _DisplayType.List),
                onTap: _onTapList,
              ),
              
              Container(width: 10,),
              
              ExploreViewTypeTab(
                label: Localization().getStringEx('panel.laundry_home.button.map.title', 'Map'),
                hint: Localization().getStringEx('panel.laundry_home.button.map.hint', ''),
                iconResource: 'images/icon-map-view.png',
                selected: (_displayType == _DisplayType.Map),
                onTap: _onTapMap,
              ),
            ],),
          ),
        ]),
      ],
      title: Text(Localization().getStringEx('panel.laundry_home.heading.laundry', 'Laundry'),
        style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 16, color: Colors.white, letterSpacing: 1),
      ),
      centerTitle: false,
    );
  }

  void _onTapMap() {
    Analytics().logSelect(target: 'Map');
    _selectDisplayType(_DisplayType.Map);
  }

  void _onTapList() {
    Analytics().logSelect(target: 'List');
    _selectDisplayType(_DisplayType.List);
  }

  void _onTapBack() {
    Analytics().logSelect(target: 'Back');
    Navigator.pop(context);
  }*/

  Widget _buildContentWidget() {
    if (_loading == true) {
      return _buildProgressContentWidget();
    }
    else if (CollectionUtils.isEmpty(_laundrySchool?.rooms)) {
      return _buildEmptyContentWidget();
    }
    else {
      return _buildRoomsContentWidget();
    }
  }

  Widget _buildRoomsContentWidget() {
    return Column(children: <Widget>[
      Expanded(child:
        Container(color: Styles().colors?.background, child:
          Padding(padding: EdgeInsets.only(top: 16), child:
            SingleChildScrollView(scrollDirection: Axis.vertical, child:
              Container(color: Styles().colors?.background, child:
                Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                  Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 80), child:
                    ListView.separated(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemBuilder: _buildListItem,
                      separatorBuilder: _buildListSeparator,
                      itemCount: _laundrySchool?.rooms?.length ?? 0
                    ),
                  ),
                ],),
              ),
            ),
          ),
        ),
      ),
    ],);
  }

  Widget _buildEmptyContentWidget() {
    return Center(child:
      Padding(padding: EdgeInsets.all(32), child:
        Text(Localization().getStringEx('panel.laundry_home.content.empty', 'No rooms available'), style: Styles().textStyles?.getTextStyle("widget.description.regular.fat")),
      )
    );
  }

  Widget _buildProgressContentWidget() {
    return Center(child:
      CircularProgressIndicator(),
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    LaundryRoom? laundryRoom = (_laundrySchool?.rooms != null) ? _laundrySchool?.rooms![index] : null;
    return (laundryRoom != null) ? LaundryRoomRibbonButton(
      label: laundryRoom.name,
      onTap: () => _onRoomTap(laundryRoom),
    ) : Container();
  }

  Widget _buildListSeparator(BuildContext context, int index) {
    return Container();
  }

  void _loadSchool() {
    setState(() { _loading = true; });
    Laundries().loadSchoolRooms().then((laundrySchool) => _onSchoolLoaded(laundrySchool));
  }

  /*void _selectDisplayType(_DisplayType displayType) {
    Analytics().logSelect(target: displayType.toString());
    if (_displayType != displayType) {
      setState(() {
        _displayType = displayType;
        _mapAllowed = (_displayType == _DisplayType.Map) || (_mapAllowed == true);
        _enableMap(_displayType == _DisplayType.Map);
      });
    }
  }*/

  void _onSchoolLoaded(LaundrySchool? laundrySchool) {
    if (mounted) {
      setState(() {
        _laundrySchool = laundrySchool;
        _loading = false;
      });
    }
  }

  void _onRoomTap(LaundryRoom room) {
    Analytics().logSelect(target: "Room Tap: " + room.id!);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryRoomDetailPanel(room: room,)));
  }
}

