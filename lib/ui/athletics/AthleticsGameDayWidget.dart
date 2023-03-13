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

import 'package:illinois/service/Sports.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';

import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailHeading.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class AthleticsGameDayWidget extends StatefulWidget {
  final Game? game;
  final String? favoriteId;
  AthleticsGameDayWidget({Key? key, this.game, this.favoriteId}) : super(key: key);

  _AthleticsGameDayWidgetState createState() => _AthleticsGameDayWidgetState();

  SportDefinition? get sportDefinition {
    return game?.sport?.shortName != null
        ? Sports().getSportByShortName(game!.sport!.shortName)
        : null;
  }
}

class _AthleticsGameDayWidgetState extends State<AthleticsGameDayWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return (widget.favoriteId != null) ?
      HomeSlantWidget(favoriteId: widget.favoriteId,
        title: Localization().getStringEx('widget.game_day.label.its_game_day', 'It\'s Game Day!'),
        titleIconKey: widget.sportDefinition?.iconPath,
        child: Padding(padding: EdgeInsets.only(bottom: 48), child:
          AthleticsGameDetailHeading(game: widget.game),
        ),
      )
    :
      Column(children: <Widget>[
        Container(color: Styles().colors!.fillColorPrimary, child:
          Semantics(label: Localization().getStringEx('widget.game_day.label.its_game_day', 'It\'s Game Day!'), excludeSemantics: true, header: true, child:
            Padding(padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16), child:
              Row(children: <Widget>[
                StringUtils.isNotEmpty(widget.sportDefinition?.iconPath)
                  ? Styles().images?.getImage(widget.sportDefinition!.iconPath!, excludeFromSemantics: true) ?? Container()
                  : Container(),
                Container(width: 10,),
                Text(Localization().getStringEx('widget.game_day.label.its_game_day', 'It\'s Game Day!'), style:
                  TextStyle(color: Colors.white, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20),
                )
              ],),
            )
          ),
        ),
      ]);
  }
}
