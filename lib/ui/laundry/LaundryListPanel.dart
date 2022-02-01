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
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/laundry/LaundryDetailPanel.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';

class LaundryListPanel extends StatefulWidget {
  final List<LaundryRoom>? rooms;

  LaundryListPanel({this.rooms});

  @override
  _LaundryListPanelState createState() => _LaundryListPanelState();
}

class _LaundryListPanelState extends State<LaundryListPanel>  {

  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx("panel.laundry_detail.header.title", "Laundry")!,
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0),
        ),
      ),
      body: _buildContentWidget(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildContentWidget() {
    return Column(
      children: <Widget>[
        Expanded(
          child: 
            Container(
                  color: Styles().colors!.background,
                  child: Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Container(
                          color: Styles().colors!.background,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.only(
                                    left: 16, right: 16, bottom: 80),
                                child: ListView.separated(
                                    physics: NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemBuilder: (context, index) {
                                      LaundryRoom laundryRoom = widget.rooms![index];
                                      return LaundryRoomRibbonButton(
                                        label: laundryRoom.title,
                                        onTap: () => _onRoomTap(laundryRoom),
                                      );
                                    },
                                    separatorBuilder: (context, index) => Container(),
                                    itemCount: widget.rooms!.length),
                              )
                            ],
                          )),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _onRoomTap(LaundryRoom room) {
    Analytics().logSelect(target: "Room" + room.title!);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryDetailPanel(room: room,)));
  }
}

class LaundryRoomRibbonButton extends StatelessWidget {
  final String? label;
  final GestureTapCallback? onTap;
  final BorderRadius borderRadius;
  final String? labelFontFamily;
  final Color backgroundColor;

  LaundryRoomRibbonButton(
      {required this.label,
        this.onTap,
        this.borderRadius = BorderRadius.zero,
        this.labelFontFamily,
        this.backgroundColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Semantics(
          label: label,
          hint:
          Localization().getStringEx('panel.laundry_list.button.item.hint', ''),
          button: true,
          excludeSemantics: true,
          child: Container(
            decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
                borderRadius: borderRadius),
//            height: 48,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(child:
                    Text(
                      label!,
                      style: TextStyle(
                          color: Styles().colors!.fillColorPrimary,
                          fontSize: 16,
                          fontFamily: labelFontFamily ?? Styles().fontFamilies!.medium),
                    ),
                  ),
                  Image.asset('images/chevron-right.png', excludeFromSemantics: true)
                ],
              ),
            ),
          ),
        ));
  }
}