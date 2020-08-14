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
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/model/Roster.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/widgets/ModalImageDialog.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class AthleticsRosterDetailPanel extends StatefulWidget{
  final SportDefinition sport;
  final Roster roster;

  AthleticsRosterDetailPanel(this.sport, this.roster);

  _AthleticsRosterDetailPanel createState() =>  _AthleticsRosterDetailPanel();
}

class _AthleticsRosterDetailPanel extends State<AthleticsRosterDetailPanel>{

  bool _modalPhotoVisibility = false;

  @override
  void initState() {
    super.initState();
  }

  void _onTapPhoto(){
    Analytics.instance.logSelect(target: "Photo");
    _modalPhotoVisibility = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool hasPosition = widget.sport != null ? widget.sport.hasPosition : false;

    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(
          Localization().getStringEx('panel.athletics_roster_detail.header.title', 'Roster'),
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0),
        ),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child:  Stack(
              children: <Widget>[
                ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    _RosterDetailHeading(sport: widget.sport, roster:widget.roster, onTapPhoto: _onTapPhoto,),
                    hasPosition ? _LineEntryWidget(
                        title: Localization().getStringEx("panel.athletics_roster_detail.label.position.title", "Position"),
                        value: widget.roster.position
                    ) : Container(),
                    _createdHeightWeightWidget(),
                    _LineEntryWidget(
                        title: Localization().getStringEx("panel.athletics_roster_detail.label.year.title", "Year"),
                        value: widget.roster.year
                    ),
                    _LineEntryWidget(
                        title: Localization().getStringEx("panel.athletics_roster_detail.label.hometown.title", "Hometown"),
                        value: widget.roster.hometown
                    ),
                    _LineEntryWidget(
                        title: Localization().getStringEx("panel.athletics_roster_detail.label.highschool.title", "High School"),
                        value: widget.roster.highSchool
                    ),
                    Container(
                        padding: EdgeInsets.only(top:16,left: 8,right: 8,bottom: 12),
                        color: Styles().colors.background,
                        child: Column(
                            children: <Widget>[
                              HtmlWidget(
                                widget.roster.htmlBio,
                                webView: false,
                                textStyle: TextStyle(
                                  fontFamily: Styles().fontFamilies.regular,
                                  fontSize: 16
                                ),
                              )
                            ]
                        )
                    )
                  ],
                ),
                //modalPhotoVisibility ? Expanded
                _createModalPhotoDialog(),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _createModalPhotoDialog(){
   return _modalPhotoVisibility ? ModalImageDialog(
     imageUrl: widget.roster.rosterFullSizePhotoUrl,
     onClose: () {
       Analytics.instance.logSelect(target: "Close");
       _modalPhotoVisibility = false;
       setState(() {});
     }
   ) : Container();
  }

  Widget _createdHeightWeightWidget(){
    if(widget.sport != null) {
      if (widget.sport.hasWeight && widget.sport.hasHeight) {
        return _LineEntryWidget(
            title: Localization().getStringEx("panel.athletics_roster_detail.label.htwt.title", "Ht./Wt."),
            semanticTitle: Localization().getStringEx("panel.athletics_roster_detail.label.height_weight.title", "Height and Weight"),
            value: "${widget.roster.height} / ${widget.roster.weight}"
        );
      }
      else if (widget.sport.hasHeight) {
        return _LineEntryWidget(
            title: Localization().getStringEx("panel.athletics_roster_detail.label.ht.title", "Ht."),
            semanticTitle: Localization().getStringEx("panel.athletics_roster_detail.label.height.title", "Height"),
            value: widget.roster.height
        );
      }
      else if (widget.sport.hasWeight) {
        return _LineEntryWidget(
            title: Localization().getStringEx("panel.athletics_roster_detail.label.wt.title", "Wt."),
            semanticTitle: Localization().getStringEx("panel.athletics_roster_detail.label.weight.title", "Weight"),
            value: widget.roster.weight
        );
      }
      else {
        return Container();
      }
    }
    else{return Container();}
  }
}

class _RosterDetailHeading extends StatelessWidget{
  final photoMargin = 10.0;
  final photoHeight = 112.0;
  final horizontalMargin = 16.0;
  final photoWidth = 80.0;
  final blueHeight = 48.0;

  final SportDefinition sport;
  final Roster roster;

  final GestureTapCallback onTapPhoto;

  _RosterDetailHeading({this.sport, this.roster, this.onTapPhoto});

  @override
  Widget build(BuildContext context) {
    String sportLabel = sport.name;
    String rosterName = roster.name;
    String number = roster.numberString;
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Semantics(
          label: '$sportLabel, $rosterName, $number',
          excludeSemantics: true,
          child: Container(
            child: Stack(
              children: <Widget>[
                Container(
                  color: Styles().colors.fillColorPrimaryVariant,
                  child: Container(
                    margin: EdgeInsets.only(right:(photoWidth + (photoMargin + horizontalMargin))),
                    child: Padding(
                      padding: EdgeInsets.only(left:16,right:16, top: 18, bottom: 12),
                      child: Align(
                        alignment: Alignment.center,
                        child:  Column(
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Image.asset(sport.iconPath, width: 16, height: 16,),
                                Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Text(sport.name,
                                    style: TextStyle(
                                        color: Styles().colors.surfaceAccent,
                                        fontFamily: Styles().fontFamilies.medium,
                                        fontSize: 16
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(roster.name,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: Styles().fontFamilies.bold,
                                          fontSize: 20
                                      ),
                                    ),
                                  ),
                                  Text(roster.numberString,
                                    style: TextStyle(
                                        color: Styles().colors.whiteTransparent06,
                                        fontFamily: Styles().fontFamilies.medium,
                                        fontSize: 20
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        )
                      ),
                    ),
                  ),
                ),


                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: onTapPhoto,
                    child: Container(
                      margin: EdgeInsets.only(right: horizontalMargin + photoMargin, top: photoMargin),
                      decoration: BoxDecoration(border: Border.all(color: Styles().colors.fillColorPrimary,width: 2, style: BorderStyle.solid)),
                      child: (AppString.isStringNotEmpty(roster.rosterPhotoUrl) ?
                      Image.network(roster.rosterPhotoUrl,width: photoWidth,fit: BoxFit.cover, alignment: Alignment.topCenter):
                      Container(height: 112, width: photoWidth, color: Colors.white,)
                      ),
                    ),
                  )
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LineEntryWidget extends StatelessWidget{
  final String title;
  final String semanticTitle;
  final String value;

  _LineEntryWidget({this.title, this.semanticTitle, this.value});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppString.isStringNotEmpty(semanticTitle) ? semanticTitle : title,
      value: value,
      excludeSemantics: true,
      child: Container(
        child: AppString.isStringNotEmpty(value) ?
        Container(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: <Widget>[
              Container(
                width: 120.0,
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: Styles().fontFamilies.medium,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: Styles().fontFamilies.bold,
                  fontSize: 16,
                ),
              )
            ],
          ),
        ) : Container()
      ),
    );
  }
}