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
import 'package:illinois/ui/widgets/ExpandableNetworkImage.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/model/sport/Coach.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/model/sport/Team.dart';
import 'package:illinois/model/sport/Roster.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/athletics/AthleticsNewsCard.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:illinois/ui/athletics/AthleticsSchedulePanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsListPanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsArticlePanel.dart';
import 'package:illinois/ui/athletics/AthleticsRosterDetailPanel.dart';
import 'package:illinois/ui/athletics/AthleticsRosterListPanel.dart';
import 'package:illinois/ui/athletics/AthleticsCoachDetailPanel.dart';
import 'package:illinois/ui/athletics/AthleticsCoachListPanel.dart';
import 'package:illinois/ui/athletics/AthleticsScheduleCard.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class AthleticsTeamPanel extends StatefulWidget {
  final SportDefinition? sport;

  AthleticsTeamPanel(this.sport);

  @override
  _AthleticsTeamPanelState createState() => _AthleticsTeamPanelState();
}

class _AthleticsTeamPanelState extends State<AthleticsTeamPanel> implements NotificationsListener {
  List<Game>? _games;
  TeamRecord? _record;
  List<News>? _teamNews;
  List<Roster>? _allRosters;
  List<Coach>? _allCoaches;
  Set<String?>? _sportPreferences;

  int _progress = 0;

  @override
  void initState() {
    NotificationService().subscribe(this, Auth2UserPrefs.notifyInterestsChanged);

    _loadSportPreferences();
    _loadGames();
    _loadRecord();
    _loadNews();
    _loadRosters();
    _loadCoaches();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  bool get hasSportPreference{
    return _sportPreferences != null && _sportPreferences!.contains(widget.sport!.shortName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.athletics_team.header.title', 'Team'),
      ),
      body: _buildContentWidget(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContentWidget() {
    if(_isLoading()) {
      return Center(child: CircularProgressIndicator(),);
    }
    String? sportShortName = widget.sport!.shortName;
    SportSocialMedia? sportSocialMedia = Sports().getSocialMediaForSport(sportShortName);
    String? facebookPageUrl = sportSocialMedia?.facebookPage;
    String? instagramUrl;
    String? instagramName = sportSocialMedia?.instagramName;
    if (StringUtils.isNotEmpty(Config().instagramHostUrl) && StringUtils.isNotEmpty(instagramName)) {
      instagramUrl = '${Config().instagramHostUrl}/$instagramName';
    }
    String? twitterUrl;
    String? twitterName = sportSocialMedia?.twitterName;
    if (StringUtils.isNotEmpty(Config().twitterHostUrl) && StringUtils.isNotEmpty(twitterName)) {
      twitterUrl = '${Config().twitterHostUrl}/$twitterName';
    }

    String followLabel = Localization().getStringEx("panel.athletics_team.label.follow.title", "Follow") + " ${widget.sport?.name}";
    String randomImageURL = Assets().randomStringFromListWithKey('images.random.sports.$sportShortName') ?? '';
    return SingleChildScrollView(
      child: Container(
        color: Styles().colors!.background,
        child: Column(
          children: <Widget>[
            Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                Positioned(
                    child: ExpandableNetworkImage(randomImageURL, semanticLabel: widget.sport?.name ?? "sport",)),
                CustomPaint(
                  painter: TrianglePainter(painterColor: Colors.white),
                  child: Container(
                    height: 40,
                  ),
                )
              ],
            ),
            Container(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.only(
                      left: 24, top: 12, right: 24, bottom: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          widget.sport!.name!,
                          maxLines: 2,

                          style: TextStyle(
                              color: Styles().colors!.fillColorPrimary, fontSize: 32),
                        ),
                      ),
                      Container(width: 24,),
                      Semantics(
                        label: Localization().getStringEx("panel.athletics_team.button.favorite_team.title", "Favorite Team"),
                        hint: Localization().getStringEx("panel.athletics_team.button.favorite_team.hint", ""),
                        checked: hasSportPreference,
                        button: true,
                        child: GestureDetector(
                          onTap: _onTapSportPreference,
                          child: Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: hasSportPreference ? Image.asset('images/deselected-dark.png', excludeFromSemantics: true) : Image.asset('images/deselected.png', excludeFromSemantics: true)
                          ),
                        ),
                      )
                    ],
                  ),
                )),
            Padding(
              padding: EdgeInsets.all(24),
              child: Semantics(
                label: Localization().getStringEx("panel.athletics_team.label.record.title", "Record"),
                hint: Localization().getStringEx("panel.athletics_team.label.record.hint", ""),
                value: _record?.overallRecordUnformatted ?? "",
                excludeSemantics: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Expanded(child:
                    Text(
                      Localization().getStringEx("panel.athletics_team.label.record.title", "Record"),
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          color: Styles().colors!.fillColorPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900),
                    ),),
                    Expanded(
                      child: Text(
                        StringUtils.ensureNotEmpty(_record?.overallRecordUnformatted),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: Styles().colors!.fillColorPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w900),
                      )
                    )
                  ],
                ),
              ),
            ),
            Container(
              color: Styles().colors!.surfaceAccent,
              height: 1,
            ),
            Padding(
              padding: EdgeInsets.only(top: 17, bottom: 48),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    _GameResult(
                      header: Localization().getStringEx("panel.athletics_team.label.conf.title", 'Conf'),
                      hint: Localization().getStringEx("panel.athletics_team.label.conf.hint", ''),
                      result: StringUtils.ensureNotEmpty(_record?.conferenceRecord),
                    ),
                    _GameResult(
                      header: Localization().getStringEx("panel.athletics_team.label.home.title", 'Home'),
                      hint: Localization().getStringEx("panel.athletics_team.label.home.hint", ''),
                      result: StringUtils.ensureNotEmpty(_record?.homeRecord),
                    ),
                    _GameResult(
                      header: Localization().getStringEx("panel.athletics_team.label.away.title", 'Away'),
                      hint: Localization().getStringEx("panel.athletics_team.label.away.hint", ''),
                      result: StringUtils.ensureNotEmpty(_record?.awayRecord),
                    ),
                    _GameResult(
                      header: Localization().getStringEx("panel.athletics_team.label.neutral.title", 'Neutral'),
                      hint: Localization().getStringEx("panel.athletics_team.label.neutral.hint", ''),
                      result: StringUtils.ensureNotEmpty(_record?.neutralRecord),
                    ),
                    _GameResult(
                      header: Localization().getStringEx("panel.athletics_team.label.streak.title", 'Streak'),
                      hint: Localization().getStringEx("panel.athletics_team.label.streak.hint", ''),
                      result: StringUtils.ensureNotEmpty(_record?.streak),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 6, right: 10),
                      child: Container(
                        color: Styles().colors!.fillColorSecondary,
                        width: 2,
                        height: 48,
                      ),
                    )
                  ],
                ),
              ),
            ),
            Visibility(visible:(_games != null && _games!.isNotEmpty) ,child: Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      color: Styles().colors!.fillColorPrimary,
                      height: 40,
                    ),
                    Container(
                      height: 112,
                      width: double.infinity,
                      child: Image.asset('images/slant-down-right.png',
                        color: Styles().colors!.fillColorPrimary,
                        fit: BoxFit.fill,
                        excludeFromSemantics: true
                      ),
                    )
                  ],
                ),
                Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Semantics(
                        label: Localization().getStringEx("panel.athletics_team.label.schedule.title", 'Schedule'),
                        hint: Localization().getStringEx("panel.athletics_team.label.schedule.hint", ''),
                        excludeSemantics: true,
                        child: Row(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(right: 16),
                              child: Image.asset('images/icon-schedule.png', excludeFromSemantics: true),
                            ),
                            Text(
                              Localization().getStringEx("panel.athletics_team.label.schedule.title", 'Schedule'),
                              style:
                              TextStyle(color: Colors.white, fontSize: 20),
                            )
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                      EdgeInsets.only(left: 16, right: 16, bottom: 32),
                      child: ListView.separated(
                        shrinkWrap: true,
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.transparent,
                          height: 20,
                        ),
                        itemCount: (_games != null ? _games!.length : 0),
                        itemBuilder: (context, index) {
                          if (_games != null && _games!.length > 0) {
                            Game game =
                            _games![index];
                            return AthleticsScheduleCard(
                              game: game,
                            );
                          } else {
                            return Container();
                          }
                        },
                        controller: ScrollController(),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 48, left: 10, right: 10),
                      child: RoundedButton(
                        label: Localization().getStringEx("panel.athletics_team.button.full_schedule.title", 'Full Schedule'),
                        hint: Localization().getStringEx("panel.athletics_team.button.full_schedule.hint", ''),
                        onTap: _showScheduleListPanel(),
                        textColor: Styles().colors!.fillColorPrimary,
                        borderColor: Styles().colors!.fillColorSecondary,
                        backgroundColor: Styles().colors!.background,
                      ),
                    )
                  ],
                )
              ],
            )),
            Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      color: Styles().colors!.fillColorPrimary,
                      height: 40,
                    ),
                    Container(
                      height: 112,
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage(
                                  'images/slant-down-right-blue.png'),
                              fit: BoxFit.fill)),
                    )
                  ],
                ),
                Column(
                  children: <Widget>[
                    Container(
                      color: Styles().colors!.fillColorPrimary,
                      height: 56,
                      child: Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Semantics(
                          label: Localization().getStringEx("panel.athletics_team.label.news.title", 'News'),
                          hint: Localization().getStringEx("panel.athletics_team.label.news.hint", ''),
                          excludeSemantics: true,
                          child: Row(
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.only(right: 16),
                                child: Image.asset('images/icon-news.png', excludeFromSemantics: true),
                              ),
                              Text(
                                Localization().getStringEx("panel.athletics_team.button.news.title", 'News'),
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                        padding:
                        EdgeInsets.only(bottom: 26),
                        child: _buildNewsList()
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 48, left: 10, right: 10),
                      child:
                      Row(children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Container(),
                      ),
                      Expanded(
                        flex: 5,
                        child: RoundedButton(
                          label: Localization().getStringEx("panel.athletics_team.button.all_news.title", 'All News'),
                          hint: Localization().getStringEx("panel.athletics_team.button.all_news.hint", ''),
                          onTap: () {
                            Analytics().logSelect(target:"All News");
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => AthleticsNewsListPanel(sportName: widget.sport!.name,)));
                          },
                          textColor: Styles().colors!.fillColorPrimary,
                          borderColor: Styles().colors!.fillColorSecondary,
                          backgroundColor: Styles().colors!.background,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(),),
                      ],)
                    )
                  ],
                )
              ],
            ),
            Visibility(
              visible: CollectionUtils.isNotEmpty(_allRosters),
              child: Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  Container(
                    color: Styles().colors!.backgroundVariant,
                    height: 112,
                    width: MediaQuery.of(context).size.width,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16, top: 16),
                      child: Text(
                        Localization().getStringEx("panel.athletics_team.label.team_roster.title", 'Team Roster'),
                        style: TextStyle(
                            color: Styles().colors!.fillColorPrimary, fontSize: 20),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 16, top: 52, bottom: 32),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildTeamRoster(),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Visibility(
              visible: CollectionUtils.isNotEmpty(_allRosters),
              child: Padding(
                padding: EdgeInsets.only(bottom: 32, left: 10, right: 10),
                child:
                Row(children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: Container(),),
                  Expanded(
                    flex: 5,
                    child: RoundedButton(
                      label: Localization().getStringEx("panel.athletics_team.button.full_roster.title", 'Full Roster'),
                      hint: Localization().getStringEx("panel.athletics_team.button.full_roster.hint", ''),
                      onTap: _showRosterListPanel(),
                      textColor: Styles().colors!.fillColorPrimary,
                      borderColor: Styles().colors!.fillColorSecondary,
                      backgroundColor: Styles().colors!.background,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(),),
                ],)

              ),
            ),
            Visibility(
              visible: CollectionUtils.isNotEmpty(_allCoaches),
              child: Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  Container(
                    color: Styles().colors!.backgroundVariant,
                    height: 112,
                    width: MediaQuery.of(context).size.width,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16, top: 16),
                      child: Text(
                        Localization().getStringEx("panel.athletics_team.label.coaching_staff.title", 'Coaching Staff'),
                        style: TextStyle(
                            color: Styles().colors!.fillColorPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 16, top: 52, bottom: 32),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildCoachingStaff(),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Visibility(
              visible: CollectionUtils.isNotEmpty(_allCoaches),
              child: Padding(
                padding: EdgeInsets.only(bottom: 48, left: 10, right: 10),
                child:
                  Row(children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Container(),
                    ),
                    Expanded(
                      flex: 5,
                      child: RoundedButton(
                        label: Localization().getStringEx("panel.athletics_team.button.all_staff.title", 'All Staff'),
                        hint: Localization().getStringEx("panel.athletics_team.button.all_staff.hint", ''),
                        onTap:_showCoachListPanel(),
                        textColor: Styles().colors!.fillColorPrimary,
                        borderColor: Styles().colors!.fillColorSecondary,
                        backgroundColor: Styles().colors!.background,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(),),
                  ],)
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 32),
              child: Text(
                followLabel,
                style: TextStyle(color: Styles().colors!.textBackground, fontSize: 20),
              ),
            ),
            Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Container(
                    height: 98,
                    width: double.infinity,
                    child: Image.asset('images/slant-down-right-rotated.png', color: Styles().colors!.fillColorSecondary,fit: BoxFit.fill, excludeFromSemantics: true),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Semantics(
                      label: Localization().getStringEx("panel.athletics_team.button.facebook.title", "Facebook"),
                      hint: Localization().getStringEx("panel.athletics_team.button.facebook.hint", ""),
                      button: true,
                      excludeSemantics: true,
                      child: _TeamSocialCell(
                        name:"Facebook",
                        iconResource: 'images/fb-16x32.png',
                        webUrl: facebookPageUrl,
                      ),
                    ),
                    Semantics(
                      label: Localization().getStringEx("panel.athletics_team.button.twitter.title", "Twitter"),
                      hint: Localization().getStringEx("panel.athletics_team.button.twitter.hint", ""),
                      button: true,
                      excludeSemantics: true,
                      child: _TeamSocialCell(
                        name:"Twitter",
                        iconResource: 'images/twitter-32x28.png',
                        webUrl: twitterUrl,
                      ),
                    ),
                    Semantics(
                      label: Localization().getStringEx("panel.athletics_team.button.youtube.title", "Youtube"),
                      hint: Localization().getStringEx("panel.athletics_team.button.youtube.hint", ""),
                      button: true,
                      excludeSemantics: true,
                      child: _TeamSocialCell(
                        name:"Youtube",
                        iconResource: 'images/you-tube-32x24.png',
                        webUrl: Config().youtubeUrl,
                      ),
                    ),
                    Semantics(
                      label: Localization().getStringEx("panel.athletics_team.button.instagram.title", "Instagram"),
                      hint: Localization().getStringEx("panel.athletics_team.button.instagram.hint", ""),
                      button: true,
                      excludeSemantics: true,
                      child: _TeamSocialCell(
                        name:"Instagram",
                        iconResource: 'images/ig-32x32.png',
                        webUrl: instagramUrl,
                      ),
                    )
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNewsList() {
    return CollectionUtils.isNotEmpty(_teamNews) ? ListView.separated(
      shrinkWrap: true,
      separatorBuilder: (context, index) => Divider(color: Colors.transparent, height: 30,),
      itemCount: _teamNews!.length,
      itemBuilder: (context, index) {
        News news = _teamNews![index];
        return ((index == 0) && StringUtils.isNotEmpty(news.imageUrl)) ? ImageSlantHeader(
          //Only the first item got image
          imageUrl: news.imageUrl,
          slantImageColor: Styles().colors!.fillColorPrimaryTransparent03,
          slantImageAsset: 'images/slant-down-right-blue.png',
          onImageTap: (){_onTapNewsToutImage(news.imageUrl);},
          child: _buildAthleticsNewsCard(news)
        ) : _buildAthleticsNewsCard(news);
      },
      controller: ScrollController(),
    ) : Container();
  }

  Widget _buildAthleticsNewsCard(News news ) {
    return Padding(padding: EdgeInsets.only(top: 16, left: 16, right: 16), child:
      AthleticsNewsCard(news: news, onTap: () {
        Analytics().logSelect(target:"NewsCard: "+news.title!);
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsNewsArticlePanel(article: news)));
      }),
    );
  }

  void _loadSportPreferences() {
    if (mounted) {
      setState(() {
        _sportPreferences = Auth2().prefs?.sportsInterests;
      });
    }
  }

  void _loadGames() {
    _increaseProgress();
    Sports().loadGames(sports: [widget.sport!.shortName], limit: 3).then((games) {
      _games = games;
      _decreaseProgress();
    });
  }

  void _loadRecord() {
    _increaseProgress();
    Sports().loadRecordForCurrentSeason(widget.sport!.shortName).then((record) {
      _record = record;
      _decreaseProgress();
    });
  }

  void _loadNews() {
    _increaseProgress();
    Sports().loadNews(widget.sport!.shortName, 2).then((newsList) {
      _teamNews = newsList;
      _decreaseProgress();
    });
  }

  void _loadRosters() {
    _increaseProgress();
    Sports().loadRosters(widget.sport!.shortName).then((rosters) {
      _allRosters = rosters;
      _decreaseProgress();
    });
  }

  void _loadCoaches() {
    _increaseProgress();
    Sports().loadCoaches(widget.sport!.shortName).then((coaches) {
      _allCoaches = coaches;
      _decreaseProgress();
    });
  }

  GestureTapCallback _showRosterListPanel() {
    return () {
      Analytics().logSelect(target:"Full Rosters");
      Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => AthleticsRosterListPanel(widget.sport, _allRosters)));
    };
  }

  GestureTapCallback _showCoachListPanel() {
    return () {
      Analytics().logSelect(target:"All Staff");
      Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => AthleticsCoachListPanel(widget.sport, _allCoaches)));
    };
  }

  GestureTapCallback _showScheduleListPanel() {
    return () {
      Analytics().logSelect(target:"Full Schedule List");
      Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) =>
                  AthleticsSchedulePanel(sport: widget.sport,)));
    };
  }

  void _onTapSportPreference() {
    Analytics().logSelect(target:"Category -Favorite");
    Auth2().prefs?.toggleSportInterest(widget.sport!.shortName);
  }

  void _onTapRosterItem(BuildContext context, Roster roster) {
    Analytics().logSelect(target:"Roster: "+roster.name!);
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) =>
                AthleticsRosterDetailPanel(widget.sport, roster)));
  }

  void _onTapCoachItem(BuildContext context, Coach coach) {
    Analytics().logSelect(target:"Coach: "+coach.title!);
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) =>
                AthleticsCoachDetailPanel(widget.sport, coach)));
  }

  void _onTapNewsToutImage(String? url) {
    Analytics().logSelect(target: "News Image");
    if (url != null) {
      Navigator.push(
          context,
          PageRouteBuilder(
              opaque: false,
              pageBuilder: (context, _, __) =>
                  ModalImagePanel(imageUrl: url,
                      onCloseAnalytics: () =>
                          Analytics().logSelect(target: "Close Image"))));
    }
  }

  List<Widget> _buildTeamRoster() {
    List<Widget> rosterWidgets = [];
    if(_allRosters != null) {
      for (Roster roster in _allRosters!) {
        if(rosterWidgets.length >= 5){
          break;
        }
        rosterWidgets
            .add(_RosterItem(
          name: roster.name,
          position: roster.position,
          imageUrl: roster.thumbPhotoUrl,
          onTap: () => _onTapRosterItem(context, roster),));
      }
    }
    return rosterWidgets;
  }

  List<Widget> _buildCoachingStaff() {
    List<Widget> coachingWidgets = [];
    if(_allCoaches != null) {
      for (Coach coach in _allCoaches!) {
        if(coachingWidgets.length >= 5){
          break;
        }
        coachingWidgets
            .add(_RosterItem(name: coach.name,
          position: coach.title,
          imageUrl: coach.thumbPhotoUrl,
          onTap: () => _onTapCoachItem(context, coach),));
      }
    }
    return coachingWidgets;
  }

  void _increaseProgress() {
    if (mounted) {
      setState(() {
        _progress++;
      });
    }
  }

  void _decreaseProgress() {
    if (mounted) {
      setState(() {
        _progress--;
      });
    }
  }

  bool _isLoading() {
    return _progress > 0;
  }

  // NotificationsListener
  
  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyInterestsChanged) {
      _loadSportPreferences();
    }
  }
}

class _GameResult extends StatelessWidget {
  final String? header;
  final String? hint;
  final String? result;

  _GameResult({required this.header, required this.hint, required this.result});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: header,
      hint: hint,
      value: result,
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(left: 6, right: 10),
            child: Container(
              color: Styles().colors!.fillColorSecondary,
              width: 2,
              height: 48,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                header!,
                style: TextStyle(
                    fontFamily: Styles().fontFamilies!.medium,
                    color: Styles().colors!.fillColorPrimary,
                    fontSize: 14),
              ),
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  result!,
                  style:
                      TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 24),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

class _RosterItem extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final String? position;
  final GestureTapCallback? onTap;

  _RosterItem(
      {required this.name,
      required this.position,
      this.imageUrl,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Container(
          width: 128,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _imageContainer()),
              Container(height: 12,),
              Text(
                name!,
                style: TextStyle(
                    fontFamily: Styles().fontFamilies!.bold,
                    color: Styles().colors!.fillColorPrimary,
                    fontSize: 16),
              ),
              Text(
                StringUtils.ensureNotEmpty(position),
                softWrap: true,
                style: TextStyle(
                    fontFamily: Styles().fontFamilies!.medium,
                    color: Styles().colors!.textBackground,
                    fontSize: 16),
              ),
            ],
          ),
        )
      ),
    );
  }

  Widget _imageContainer() {
    double width = 128;
    double height = 144;
    if (StringUtils.isNotEmpty(imageUrl)) {
      return Image.network(imageUrl!, excludeFromSemantics: true, width: width, height: height, fit: BoxFit.cover, alignment: Alignment.topCenter);
    } else {
      return Container(width: width, height: height, color: Styles().colors!.background);
    }
  }
}

/*class _RosterMoreItem extends StatelessWidget {
  final String label;
  final GestureTapCallback onTap;

  _RosterMoreItem({@required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              color: Styles().colors.fillColorPrimary,
              height: 2,
              width: 128,
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10.0),
                    bottomRight: Radius.circular(10.0)),
              ),
              width: 128,
              height: 144,
              child: Padding(
                padding: EdgeInsets.only(left: 16, top: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Flexible(
                        child: Text(
                      label,
                      maxLines: 2,
                      style: TextStyle(
                          color: Styles().colors.fillColorPrimary, fontSize: 20),
                    )),
                    Image.asset('images/chevron-right.png')
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}*/

class _TeamSocialCell extends StatelessWidget {
  final String? name;
  final String? iconResource;
  final String? webUrl;

  _TeamSocialCell({this.iconResource, this.webUrl, this.name});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _onTap(context),
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
            color: Styles().colors!.fillColorPrimary,
            borderRadius: BorderRadius.all(Radius.circular(4))),
        child: Center(
          child: Image.asset(iconResource!, excludeFromSemantics: true),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    Analytics().logSelect(target:"Social: "+name!);
    if (StringUtils.isNotEmpty(webUrl)) {
      Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) =>
                  WebPanel(
                      url: webUrl, title: name!.toUpperCase(),)));
    }
  }
}
