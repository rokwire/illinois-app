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
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class ExploreConvergeDetailItem extends StatelessWidget{
  final String? eventConvergeUrl;
  final int? eventConvergeScore;

  const ExploreConvergeDetailItem({Key? key, this.eventConvergeUrl, this.eventConvergeScore}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return !hasConvergeContent() ? Container():
    GestureDetector(
      child:Padding(
        padding: EdgeInsets.only(left:0, bottom: 5),
        child: Row(
          mainAxisAlignment: getContentAlignment(),
          children: content()
        ),
      ),
      onTap: () {
        onTap(context);
      },
    );
  }

  void onTap(BuildContext context){
    if (hasConvergeUrl()) {
      //No action fro now
    }
  }

  List<Widget> content(){
      return <Widget>[
        Visibility(
          visible: hasConvergeScore(),
          child:  Padding(
            padding: EdgeInsets.only(left: 8),
            child: buildTitle(),

          ),
        ),
        infoIcon(),
      ];
  }

  Widget infoIcon(){
      return Visibility(
        visible: hasConvergeUrl(),
        child:  Padding(
          padding: EdgeInsets.only(left: 3),
          child: Styles().images?.getImage('info', excludeFromSemantics: true),
        ),
      );
  }

  Widget buildTitle() {
    return Text(
        eventConvergeScore.toString() + "% ",
//           + Localization().getString("widget.card.label.converge"),
        style: Styles().textStyles?.getTextStyle("widget.message.light.small.semi_fat")
    );
  }

  bool hasConvergeUrl(){
    return !StringUtils.isEmpty(eventConvergeUrl);
  }

  bool hasConvergeScore(){
    return (eventConvergeScore != null) && eventConvergeScore!>0;
  }

  bool hasConvergeContent(){
    return  hasConvergeScore() || hasConvergeUrl();
  }

  MainAxisAlignment getContentAlignment(){
    return MainAxisAlignment.end;
  }

}

class ExploreConvergeDetailButton extends ExploreConvergeDetailItem{
  final String? eventConvergeUrl;
  final int? eventConvergeScore;

  const ExploreConvergeDetailButton({Key? key, this.eventConvergeUrl, this.eventConvergeScore}) : 
        super(eventConvergeScore: eventConvergeScore, eventConvergeUrl: eventConvergeUrl);

  @override
  List<Widget> content(){
    return <Widget>[
      Visibility(
        visible: hasConvergeScore(),
        child:  Padding(
          padding: EdgeInsets.only(right: 8),
          child: buildTitle(),

        ),
      ),
      Text( Localization().getString("widget.card.label.converge")!),
      Container(width: 5,),
//      Styles().images?.getImage('images/chevron-right.png')

    ];
  }

  @override
  MainAxisAlignment getContentAlignment(){
    return MainAxisAlignment.start;
  }
}