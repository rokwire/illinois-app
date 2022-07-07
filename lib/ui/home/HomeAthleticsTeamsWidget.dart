import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/athletics/AthleticsTeamsPanel.dart';
import 'package:illinois/ui/athletics/AthleticsTeamsWidget.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

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
    return Column(children: <Widget>[
      Padding(padding: EdgeInsets.only(left: 18, right: 4, top: 4, bottom: 4), child:
        Row(children: [
          Expanded(child:
            Align(alignment: Alignment.centerLeft, child:
              Text(Localization().getStringEx('widget.home.athletics_teams.text.title', 'Athletics Teams'), style: TextStyle(fontSize: 20, color: Styles().colors?.fillColorPrimary, fontFamily: Styles().fontFamilies?.extraBold),),
            ),
          ),
          HomeFavoriteButton(favorite: HomeFavorite(widget.favoriteId), style: FavoriteIconStyle.Button, prompt: true,)
        ],)
      ),
      Padding(padding: EdgeInsets.symmetric(horizontal: 16),
        child: AthleticsTeamsWidget(handleTeamTap: true, sportsLimit: Config().homeAthleticsTeamsCount, updateSportPrefs: false),
      ),
      LinkButton(
        title: Localization().getStringEx('widget.home.athletics_teams.button.all.title', 'View All'),
        hint: Localization().getStringEx('widget.home.athletics_teams.button.all.hint', 'Tap to view all teams'),
        onTap: _onTapSeeAll,
      ),
      
    ],);
  }

  void _onTapSeeAll() {
    Analytics().logSelect(target: "HomeAthleticsTeams: View All");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsTeamsPanel()));
  }

}