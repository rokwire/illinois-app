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
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/explore/ExploreSearchPanel.dart';
import 'package:illinois/ui/explore/ExploreViewTypeTab.dart';
import 'package:rokwire_plugin/service/styles.dart';

enum ListMapDisplayType { List, Map }

class ExploreDisplayTypeHeader extends StatelessWidget {
  final ListMapDisplayType? displayType;
  final GestureTapCallback? onTapList;
  final GestureTapCallback? onTapMap;
  final bool searchVisible;
  final Map<String, dynamic>? additionalData;

  ExploreDisplayTypeHeader({this.displayType, this.onTapList, this.onTapMap, this.searchVisible = false, this.additionalData});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 24 + (16*(MediaQuery.of(context).textScaleFactor)),
        color: Styles().colors!.fillColorPrimaryVariant,
        child: Padding(
            padding: EdgeInsets.only(left: 18),
            child: Column(children: <Widget>[
              Expanded(
                  child: Row(
                children: <Widget>[
                  ExploreViewTypeTab(
                    label: Localization().getStringEx('widget.explore_display_type.header.list.title', 'List'),
                    hint: Localization().getStringEx('widget.explore_display_type.header.list.hint', ''),
                    iconKey: 'list-outline',
                    selected: (displayType == ListMapDisplayType.List),
                    onTap: onTapList,
                  ),
                  Container(
                    width: 10,
                  ),
                  ExploreViewTypeTab(
                    label: Localization().getStringEx('widget.explore_display_type.header.map.title', 'Map'),
                    hint: Localization().getStringEx('widget.explore_display_type.header.map.hint', ''),
                    iconKey: 'location-outline',
                    selected: (displayType == ListMapDisplayType.Map),
                    onTap: onTapMap,
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  Visibility(
                    visible: searchVisible,
                    child: Semantics(
                      button: true, excludeSemantics: true,
                      label: Localization().getStringEx('panel.search.button.search.title', 'Search'),child:
                    IconButton(
                      icon: Styles().images?.getImage('search', excludeFromSemantics: true) ?? Container(),
                      onPressed: () {
                        Analytics().logSelect(target: "Search");
                        Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreSearchPanel(searchData:additionalData ))).
                          then(
                            (value){
                              if(value!=null && value == true){
                                Navigator.pop(context, true);
                              }
                            }
                        );
                      },
                    ),
                  ))
                ],
              )),
            ])));
  }
}
