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
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/model/sport/Coach.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';

import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';


class AthleticsCoachDetailPanel extends StatefulWidget {

  final SportDefinition? sport;
  final Coach coach;

  AthleticsCoachDetailPanel(this.sport, this.coach);

  _AthleticsCoachDetailPanelState createState() => _AthleticsCoachDetailPanelState();
}

class _AthleticsCoachDetailPanelState extends State<AthleticsCoachDetailPanel>{

  void _onTapPhoto(){
    Analytics().logSelect(target: "Photo");
    if (widget.coach.fullSizePhotoUrl != null) {
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (context, _, __) => ModalImagePanel(imageUrl: widget.coach.fullSizePhotoUrl!, onCloseAnalytics: () => Analytics().logSelect(target: "Close Photo"),)));
    }
  }

  @override
  Widget build(BuildContext context) {
    
    Color color = Theme.of(context).scaffoldBackgroundColor;
    Log.d(color.toString());

    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.athletics_coach_detail.header.title', 'Staff'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: ListView(
              children: <Widget>[
                _CoachDetailHeading(sport:widget.sport, coach:widget.coach, onTapPhoto: _onTapPhoto,),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(widget.coach.title!,
                    style: TextStyle(
                        fontSize: 24
                    ),
                  ),
                ),

                Container(
                    padding: EdgeInsets.only(top:16,left: 8,right: 8,bottom: 12),
                    color: Styles().colors!.background,
                    child: Visibility(visible: StringUtils.isNotEmpty(widget.coach.htmlBio), child: Container(
                      child: Html(
                        data: StringUtils.ensureNotEmpty(widget.coach.htmlBio),
                        onLinkTap: (url, renderContext, attributes, element) => _launchUrl(url, context: context),
                        style: { "body": Style(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(16), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
                      ),
                    ))
                )
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  void _launchUrl(String? url, {BuildContext? context}) {
    if (StringUtils.isNotEmpty(url)) {
      if (UrlUtils.launchInternal(url)) {
        Navigator.push(context!, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri);
        }
      }
    }
  }
}

class _CoachDetailHeading extends StatelessWidget{
  final _photoMargin = 10.0;
  final _horizontalMargin = 16.0;
  final _photoWidth = 80.0;

  final SportDefinition? sport;
  final Coach? coach;
  final GestureTapCallback? onTapPhoto;

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
                  color: Styles().colors!.fillColorPrimaryVariant,
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
                                Image.asset(sport!.iconPath!, width: 16, height: 16,),
                                Expanded(child:
                                  Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Text(sport!.name!,
                                      style: TextStyle(
                                          color: Styles().colors!.surfaceAccent,
                                          fontFamily: Styles().fontFamilies!.medium,
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
                                    child: Text(coach!.name!,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: Styles().fontFamilies!.bold,
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
                      decoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorPrimary!,width: 2, style: BorderStyle.solid)),
                      child: (StringUtils.isNotEmpty(coach?.thumbPhotoUrl) ?
                      Image.network(coach!.thumbPhotoUrl!, semanticLabel: "coach", width: _photoWidth,fit: BoxFit.cover, alignment: Alignment.topCenter):
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