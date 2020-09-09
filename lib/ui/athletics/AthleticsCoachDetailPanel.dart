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
import 'package:illinois/service/Log.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/widgets/ModalImageDialog.dart';
import 'package:illinois/model/Coach.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';


class AthleticsCoachDetailPanel extends StatefulWidget {

  final SportDefinition sport;
  final Coach coach;

  AthleticsCoachDetailPanel(this.sport, this.coach);

  _AthleticsCoachDetailPanelState createState() => _AthleticsCoachDetailPanelState();
}

class _AthleticsCoachDetailPanelState extends State<AthleticsCoachDetailPanel>{

  bool _modalPhotoVisibility = false;

  void _onTapPhoto(){
    Analytics.instance.logSelect(target: "Photo");
    _modalPhotoVisibility = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    
    Color color = Theme.of(context).scaffoldBackgroundColor;
    Log.d(color.toString());

    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(
          Localization().getStringEx('panel.athletics_coach_detail.header.title', 'Staff'),
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
            child: Stack(
              children: <Widget>[
                ListView(
                  children: <Widget>[
                    _CoachDetailHeading(sport:widget.sport, coach:widget.coach, onTapPhoto: _onTapPhoto,),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(widget.coach.title,
                        style: TextStyle(
                            fontSize: 24
                        ),
                      ),
                    ),

                    Container(
                        padding: EdgeInsets.only(top:16,left: 8,right: 8,bottom: 12),
                        color: Styles().colors.background,
                        child: Column(
                          children: _createDetailList(),
                        )
                    )
                  ],
                ),
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
      imageUrl: widget.coach.fullSizePhotoUrl,
      onClose: () {
        Analytics.instance.logSelect(target: "Close");
        _modalPhotoVisibility = false;
        setState(() {});
      }
    ) : Container();
  }

  List<Widget> _createDetailList(){
    List<Widget> list = List<Widget>();
    list.add(Container(
      child: HtmlWidget(
        widget.coach.htmlBio,
        webView: false,
        textStyle: TextStyle(
            fontFamily: Styles().fontFamilies.regular,
            fontSize: 16
        ),
      ),
    ));

    return list;
  }
}

class _CoachDetailHeading extends StatelessWidget{
  final _photoMargin = 10.0;
  final _horizontalMargin = 16.0;
  final _photoWidth = 80.0;

  final SportDefinition sport;
  final Coach coach;
  final GestureTapCallback onTapPhoto;

  _CoachDetailHeading({this.sport, this.coach, this.onTapPhoto});

  @override
  Widget build(BuildContext context) {
    String sportName = sport?.name ?? "";
    String choachName = coach?.name ?? "";
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Semantics(
          label: '$sportName, $choachName',
          excludeSemantics: true,
          child: Container(
            child: Stack(
              children: <Widget>[
                Container(
                  color: Styles().colors.fillColorPrimaryVariant,
                  child: Container(
                    margin: EdgeInsets.only(right:(_photoWidth + (_photoMargin + _horizontalMargin))),
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
                                Expanded(child:
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
                                )
                              ],
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(coach.name,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: Styles().fontFamilies.bold,
                                          fontSize: 20
                                      ),
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
                      margin: EdgeInsets.only(right: _horizontalMargin + _photoMargin, top: _photoMargin),
                      decoration: BoxDecoration(border: Border.all(color: Styles().colors.fillColorPrimary,width: 2, style: BorderStyle.solid)),
                      child: (AppString.isStringNotEmpty(coach.photoUrl) ?
                      Image.network(coach.photoUrl,width: _photoWidth,fit: BoxFit.cover, alignment: Alignment.topCenter):
                      Container(height: 112, width: _photoWidth, color: Colors.white,)
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}