import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/athletics/AthleticsTeamsPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/localization.dart';

class HomeAthliticsTeamsWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeAthliticsTeamsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.athletics_teams.text.title', 'Athletics Teams');

  State<HomeAthliticsTeamsWidget> createState() => _HomeAthliticsTeamsWidgetState();
}

class _HomeAthliticsTeamsWidgetState extends State<HomeAthliticsTeamsWidget> {
  
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
    String description = Localization().getStringEx('widget.home.athletics_teams.text.description', 'See all athletics teams and select your favorite sports.');
    String descriptionHint = Localization().getStringEx('widget.home.athletics_teams.text.description.hint', 'Tap to see all athletics teams and select your favorite sports.');

    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: HomeAthliticsTeamsWidget.title,
      titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
      child: Padding(padding: EdgeInsets.only(top: 24, bottom: 16),
        child: Semantics(container: true, excludeSemantics: true, label: description, hint: descriptionHint,
          child: InkWell(onTap: _onTapSeeAll, 
            child: HomeMessageCard(message: description,)
          ),
        )
      ),
    );
  }

  void _onTapSeeAll() {
    Analytics().logSelect(target: "HomeAthleticsTeams: View All");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsTeamsPanel()));
  }

}