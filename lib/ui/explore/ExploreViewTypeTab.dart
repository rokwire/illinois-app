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
import 'package:rokwire_plugin/service/styles.dart';


class ExploreViewTypeTab extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? iconKey;
  final GestureTapCallback? onTap;
  final bool selected;

  ExploreViewTypeTab(
      {this.label,
      this.iconKey,
      this.onTap,
      this.hint = '',
      this.selected = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: label,
        hint: hint,
        button: true,
        selected: selected,
        excludeSemantics: true,
        child:Column(children: <Widget>[
        Expanded(child: Container(),),
        Container(
          //color: Colors.amber,
          decoration: selected ? BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors!.fillColorSecondary!,width: 2, style: BorderStyle.solid))) : null,
          child:Padding(padding: EdgeInsets.symmetric(vertical:3, horizontal: 5), child:Column(children: <Widget>[
            Row(children: <Widget>[
              Styles().images?.getImage(iconKey, excludeFromSemantics: true) ?? Container(),
              Container(width: 5,),
              Text(label!, style: Styles().textStyles?.getTextStyle("widget.colourful_button.title.accent"), textScaleFactor:( MediaQuery.of(context).textScaleFactor> 2 ? MediaQuery.of(context).textScaleFactor - 0.8 : MediaQuery.of(context).textScaleFactor),)
            ]),
          ],)
        )),
        Expanded(child: Container(),),
        ],),
    ));
  }
}