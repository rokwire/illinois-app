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
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/laundry/LaundryRoomDetailPanel.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;

class LaundryListPanel extends StatefulWidget {
  final List<LaundryRoom>? rooms;

  LaundryListPanel({this.rooms});

  @override
  _LaundryListPanelState createState() => _LaundryListPanelState();
}

class _LaundryListPanelState extends State<LaundryListPanel> with NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);
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
      appBar: HeaderBar(title: Localization().getStringEx("panel.laundry_detail.header.title", "Laundry"),),
      body: _buildContentWidget(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContentWidget() {
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
                      itemCount: widget.rooms?.length ?? 0
                    ),
                  )
                ],),
              ),
            ),
          ),
        ),
      ),
    ],);
  }

  Widget _buildListItem(BuildContext context, int index) {
    LaundryRoom? laundryRoom = (widget.rooms != null) ? widget.rooms![index] : null;
    return (laundryRoom != null) ? LaundryRoomRibbonButton(
      label: laundryRoom.name,
      onTap: () => _onTapRoom(laundryRoom),
      starred: Auth2().canFavorite ? (Auth2().prefs?.isFavorite(laundryRoom) == true) : null,
      onTapStarred: () => _onTapRoomFavorite(laundryRoom),
    ) : Container();
  }

  Widget _buildListSeparator(BuildContext context, int index) {
    return Container();
  }

  void _onTapRoom(LaundryRoom room) {
    Analytics().logSelect(target: "Room" + room.name!);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryRoomDetailPanel(room: room,)));
  }

  void _onTapRoomFavorite(LaundryRoom room) {
    Analytics().logSelect(target: 'Starred: ${room.name}');
    Auth2().prefs?.toggleFavorite(room);
  }
}

class LaundryRoomRibbonButton extends StatelessWidget {
  final String? label;
  final GestureTapCallback? onTap;
  final bool? starred;
  final GestureTapCallback? onTapStarred;
  final BorderRadius borderRadius;
  final String? labelFontFamily;
  final Color backgroundColor;

  LaundryRoomRibbonButton(
      {required this.label,
        this.starred,
        this.onTapStarred,
        this.onTap,
        this.borderRadius = BorderRadius.zero,
        this.labelFontFamily,
        this.backgroundColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child:
      Semantics(label: label, hint: Localization().getStringEx('panel.laundry_list.button.item.hint', ''), button: true, excludeSemantics: true, child:
        Container(decoration: BoxDecoration(color: backgroundColor, border: Border.all(color: Styles().colors.surfaceAccent, width: 1), borderRadius: borderRadius), child:
          Row(children: <Widget>[
            (starred != null) ? _starredButton : _leftSpacing,
            Expanded(child:
              Padding(padding: EdgeInsets.only(right: 8, top: 14, bottom: 14), child:
                Text(label ?? '', style:  Styles().textStyles.getTextStyle("widget.button.title.medium")?.copyWith(fontFamily: labelFontFamily)),
              )
            ),
            Padding(padding: EdgeInsets.only(right: 16, top: 14, bottom: 14), child:
              Styles().images.getImage('chevron-right-bold', excludeFromSemantics: true),
            ),
          ],),
        ),
      )
    );
  }

  Widget get _starredButton {
    bool isStarred = (starred == true);
    String semanticsLabel = isStarred ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites');
    String semanticsHint = isStarred ? Localization().getStringEx('widget.card.button.favorite.off.hint', '') : Localization().getStringEx('widget.card.button.favorite.on.hint', '');
    return Semantics(button: true, label: semanticsLabel, hint: semanticsHint, child:
      InkWell(onTap: onTapStarred, child:
        Padding(padding: EdgeInsets.only(left: 16, right: 8, top: 14, bottom: 14), child:
          Styles().images.getImage(isStarred ? 'star-filled-orange' : 'star-outline-blue', excludeFromSemantics: true)
        ),
      ),
    );
  }

  Widget get _leftSpacing => Padding(padding: EdgeInsets.only(left: 16));
}