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
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/laundry/LaundryRoomDetailPanel.dart';
import 'package:illinois/ui/laundry/LaundryListPanel.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';


class LaundryHomePanel extends StatefulWidget {
  final LaundrySchool? laundrySchool;
  final bool? starred;

  LaundryHomePanel({super.key, this.laundrySchool, this.starred });

  @override
  _LaundryHomePanelState createState() => _LaundryHomePanelState();
}

class _LaundryHomePanelState extends State<LaundryHomePanel> with NotificationsListener {
  LaundrySchool? _laundrySchool;
  List<LaundryRoom>? _displayRooms;
  bool _loading = false;
  late bool _starred;

  bool get _canFavorite => (_laundrySchool?.rooms?.isNotEmpty == true) && !_loading;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);
    _starred = (widget.starred == true);

    _laundrySchool = widget.laundrySchool;
    if (_laundrySchool == null) {
      _loadSchool();
    }
    else {
      _displayRooms = _buildDisplayRooms();
    }

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.laundry_home.heading.laundry', 'Laundry'),
        actions: _canFavorite ? [ _starredButton ] : null,
      ),
      body: _loading ? Center(child: CircularProgressIndicator(),) : _buildContentWidget(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

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
        Container(color: Styles().colors.background, child:
          Padding(padding: EdgeInsets.only(top: 16), child:
            SingleChildScrollView(scrollDirection: Axis.vertical, child:
              Container(color: Styles().colors.background, child:
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
        Text(Localization().getStringEx('panel.laundry_home.content.empty', 'No rooms available'), style: Styles().textStyles.getTextStyle("widget.description.regular.fat")),
      )
    );
  }

  Widget _buildProgressContentWidget() {
    return Center(child:
      CircularProgressIndicator(),
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    LaundryRoom? laundryRoom = ListUtils.entry(_displayRooms, index);
    return (laundryRoom != null) ? LaundryRoomRibbonButton(
      label: laundryRoom.name,
      starred: (Auth2().prefs?.isFavorite(laundryRoom) == true),
      onTap: () => _onRoomTap(laundryRoom),
    ) : Container();
  }

  Widget _buildListSeparator(BuildContext context, int index) {
    return Container();
  }

  Widget get _starredButton =>
    InkWell(onTap: _onTapStarred, child:
      Padding(padding: EdgeInsets.all(12), child:
        Styles().images.getImage(_starred ? 'star-filled-orange' : 'star-outline-white')
      )
    );

  void _onTapStarred() {
    Analytics().logSelect(target: 'Starred');
    setState(() {
      _starred = !_starred;
      _displayRooms = _buildDisplayRooms();
    });
  }


  Future<void> _loadSchool() async {
    setState(() { _loading = true; });
    LaundrySchool? laundrySchool = await Laundries().loadSchoolRooms();
    setStateIfMounted((){
      _laundrySchool = laundrySchool;
      _displayRooms = _buildDisplayRooms();
      _loading = false;
    });
  }

  List<LaundryRoom>? _buildDisplayRooms() =>
    _starred ? _starredRooms : _laundrySchool?.rooms;

  List<LaundryRoom>? get _starredRooms =>
    ListUtils.from(_laundrySchool?.rooms?.where((LaundryRoom room) => (Auth2().prefs?.isFavorite(room) == true)));

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

  void _onRoomTap(LaundryRoom room) {
    Analytics().logSelect(target: "Room Tap: " + room.id!);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryRoomDetailPanel(room: room,)));
  }
}

