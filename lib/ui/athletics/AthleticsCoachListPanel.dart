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
import 'package:flutter/cupertino.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/athletics/AthleticsCoachDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/model/sport/Coach.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';


class AthleticsCoachListPanel extends StatefulWidget {
  final SportDefinition? sport;
  final List<Coach>? allCoaches;
  AthleticsCoachListPanel(this.sport,this.allCoaches);

  @override
  _AthleticsCoachListPanelState createState() => _AthleticsCoachListPanelState();
}

class _AthleticsCoachListPanelState extends State<AthleticsCoachListPanel> implements _CoachItemListener{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(
          title: Localization().getStringEx('panel.athletics_coach_list.header.title', 'Staff'),
        ),
        body: Column(
          children: <Widget>[
            _CoachListHeading(widget.sport),
            Expanded(
              child: ListView(
                children: _constructCoachList(context),
              ),
            ),
          ],
        ),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: uiuc.TabBar(),
    );
  }

  List<Widget> _constructCoachList(BuildContext context){
    List<Widget> widgets = [];
    if(widget.allCoaches != null) {
      widget.allCoaches!.forEach((coach) =>
        widgets.add(_CoachItem(coach,listener: this,))
      );
    }

    return widgets;
  }

  void _onCoachItemTap(Coach coach){
    Analytics().logSelect(target: "Coach: "+coach.name!);
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => AthleticsCoachDetailPanel(widget.sport, coach)));
  }
}

abstract class _CoachItemListener{
  _onCoachItemTap(Coach coach);
}

class _CoachListHeading extends StatelessWidget{
  final SportDefinition? sport;

  _CoachListHeading(this.sport);

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      Expanded(
        child: Container(
          color: Styles().colors!.fillColorPrimaryVariant,
          padding: EdgeInsets.only(left: 16, right: 16, top:12, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Styles().images?.getImage(sport!.iconPath!, excludeFromSemantics: true) ?? Container(),
                  Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(sport!.name!,
                      style: Styles().textStyles?.getTextStyle("panel.athletics.coach_detail.title.regular.accent")
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.0,),
              Text(Localization().getStringEx("panel.athletics_coach_list.label.heading.title", "All Staff"),
                style: Styles().textStyles?.getTextStyle("widget.heading.large.extra_fat")
              ),
            ],
          ),
        ),
      ),
    ],
    );
  }
}

class _CoachItem extends StatelessWidget{
  final _horizontalMargin = 16.0;
  final _photoMargin = 10.0;
  final _photoWidth = 80.0;
  final _blueHeight = 48.0;

  final _CoachItemListener? listener;
  final Coach coach;

  _CoachItem(this.coach, {this.listener});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=>listener!._onCoachItemTap(coach),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Container(
            padding: EdgeInsets.only( bottom: 8),
            child: Stack(
              children: <Widget>[
                Container(
                  color: Styles().colors!.fillColorPrimary,
                  height: _blueHeight,
                  margin: EdgeInsets.only(top: _photoMargin*2, left: _horizontalMargin, right: _horizontalMargin,),
                  child: Container(
                    margin: EdgeInsets.only(right:(_photoWidth + (_photoMargin + _horizontalMargin))),
                    child: Padding(
                      padding: EdgeInsets.only(left:8,right:8),
                      child: Align(
                        alignment: Alignment.center,
                        child:  Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              child: Text(coach.name!,
                                style: Styles().textStyles?.getTextStyle("widget.title.light.large.fat")
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadiusDirectional.only(
                        topStart: Radius.zero,
                        topEnd: Radius.zero,
                        bottomStart: Radius.circular(5),
                        bottomEnd: Radius.circular(5),
                      ),
                      boxShadow: [
                        BoxShadow(color: Styles().colors!.fillColorPrimary!,blurRadius: 4,),
                      ]

                  ),
                  constraints: BoxConstraints(
                    minHeight: 85
                  ),
                  margin: EdgeInsets.only(top: _blueHeight + _photoMargin*2,left: _horizontalMargin, right: _horizontalMargin,),
                  child: Padding(
                    padding: EdgeInsets.only(left: 8, top: 8, bottom: 8, right:(_photoWidth + (_photoMargin + _horizontalMargin))),
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: 80,
                              child: Text(Localization().getStringEx("panel.athletics_coach_list.label.position.title", "Position"),
                                  style: Styles().textStyles?.getTextStyle("widget.item.small")
                              ),
                            ),
                            Expanded(
                              child: Text(coach.title!,
                                  softWrap: true,
                                  style: Styles().textStyles?.getTextStyle("widget.item.small.fat")
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: EdgeInsets.only(right: _horizontalMargin + _photoMargin, top: _photoMargin),
                    decoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorPrimary!,width: 2, style: BorderStyle.solid)),
                    child: (StringUtils.isNotEmpty(coach.thumbPhotoUrl) ?
                    ModalImageHolder(url: coach.fullSizePhotoUrl, child: Image.network(coach.thumbPhotoUrl!, semanticLabel: "coach", width: _photoWidth, fit: BoxFit.cover, alignment: Alignment.topCenter,)):
                      Container(height: 96, width: 80, color: Colors.white,)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}