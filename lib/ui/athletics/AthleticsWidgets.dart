/*
 * Copyright 2024 Board of Trustees of the University of Illinois.
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
import 'package:neom/ext/Event2.dart';
import 'package:neom/ext/Game.dart';
import 'package:neom/model/sport/Game.dart';
import 'package:neom/model/sport/SportDetails.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/service/FlexUI.dart';
import 'package:neom/service/Sports.dart';
import 'package:neom/ui/athletics/AthleticsMyTeamsPanel.dart';
import 'package:neom/ui/athletics/AthleticsTeamPanel.dart';
import 'package:neom/ui/widgets/PrivacyTicketsDialog.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_io/io.dart';

class AthleticsEventCard extends StatefulWidget {
  final Event2 sportEvent;
  final GestureTapCallback? onTap;
  final EdgeInsetsGeometry margin;
  final bool showImage;
  final bool showDescription;
  final bool showInterests;
  final bool showGetTickets;

  static const EdgeInsetsGeometry imageMargin = const EdgeInsets.only(left: 20, right: 20);
  static const EdgeInsetsGeometry regularMargin = const EdgeInsets.only(left: 20, right: 20, top: 20);

  AthleticsEventCard(
      {required this.sportEvent,
      this.onTap,
      EdgeInsetsGeometry? margin,
      this.showImage = false,
      this.showDescription = false,
      this.showInterests = false,
      this.showGetTickets = false})
      : margin = margin ?? (showImage ? imageMargin : regularMargin);

  @override
  _AthleticsEventCardState createState() => _AthleticsEventCardState();
}

class _AthleticsEventCardState extends State<AthleticsEventCard> implements NotificationsListener {
  static const EdgeInsets _detailPadding = EdgeInsets.only(bottom: 12, left: 24, right: 24);
  static const EdgeInsets _iconPadding = EdgeInsets.only(right: 5);

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted(() {});
    } else if (name == FlexUI.notifyChanged) {
      setStateIfMounted(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Game? game = widget.sportEvent.hasGame ? widget.sportEvent.game : null;
    String? sportKey = game?.sport?.shortName;
    SportDefinition? sport = Sports().getSportByShortName(sportKey);
    String sportName = sport?.name ?? '';
    bool isTicketedSport = sport?.ticketed ?? false;
    bool showImage = widget.showImage && StringUtils.isNotEmpty(game?.imageUrl) && isTicketedSport;
    bool isGetTicketsVisible = widget.showGetTickets && StringUtils.isNotEmpty(game?.links?.tickets) && isTicketedSport;
    bool isFavorite = Auth2().isFavorite(widget.sportEvent);
    String? interestsLabelValue = _getInterestsLabelValue();
    bool showInterests = StringUtils.isNotEmpty(interestsLabelValue) && widget.showInterests;
    String? description = game?.description;
    bool showDescription = widget.showDescription && StringUtils.isNotEmpty(description);

    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        child: Stack(alignment: showImage ? Alignment.bottomCenter : Alignment.topCenter, children: <Widget>[
          Column(children: <Widget>[
            Stack(alignment: showImage ? Alignment.bottomCenter : Alignment.topCenter, children: <Widget>[
              showImage
                  ? Positioned(
                      child: InkWell(
                          onTap: () => _onTapCardImage(game!.imageUrl!),
                          child: Image.network(game!.imageUrl!, semanticLabel: "Sports")))
                  : Container(),
              showImage
                  ? Container(
                      height: 72,
                      color: Styles().colors.fillColorSecondaryTransparent05,
                    )
                  : Container(height: 0)
            ]),
            showImage
                ? Container(
                    height: 112,
                    width: double.infinity,
                    child: Styles().images.getImage('slant', fit: BoxFit.fill, excludeFromSemantics: true))
                : Container(),
            showImage ? Container(height: 140, color: Styles().colors.background) : Container()
          ]),
          Padding(
              padding: widget.margin,
              child: Stack(alignment: Alignment.topCenter, children: [
                Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [
                      const BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))
                    ]),
                    child: Padding(
                        padding: EdgeInsets.only(bottom: ((showInterests && !isTicketedSport) ? 0 : 12)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          Padding(
                              padding: EdgeInsets.only(left: 20, right: 0),
                              child: Row(children: <Widget>[
                                Semantics(
                                    button: true,
                                    child: GestureDetector(
                                        onTap: () => _onTapSportCategory(sport!),
                                        child: Padding(
                                            padding: EdgeInsets.only(top: 24),
                                            child: Container(
                                                color: Styles().colors.fillColorPrimary,
                                                child: Padding(
                                                    padding: EdgeInsets.all(5),
                                                    child: Text(sportName.toUpperCase(),
                                                        style: Styles()
                                                            .textStyles
                                                            .getTextStyle('widget.colourful_button.title.regular.accent'))))))),
                                Expanded(child: Container()),
                                Visibility(
                                    visible: Auth2().canFavorite,
                                    child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: _onTapSave,
                                        child: Semantics(
                                            label: isFavorite
                                                ? Localization()
                                                    .getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites')
                                                : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                                            hint: isFavorite
                                                ? Localization().getStringEx('widget.card.button.favorite.off.hint', '')
                                                : Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
                                            excludeSemantics: true,
                                            child: Padding(
                                                padding: EdgeInsets.only(right: 24, top: 24, left: 24, bottom: 8),
                                                child: Styles().images.getImage(isFavorite ? 'star-filled' : 'star-outline-secondary',
                                                    excludeFromSemantics: true)))))
                              ])),
                          Padding(
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                              child: Text(StringUtils.ensureNotEmpty(game?.title), style: Styles().textStyles.getTextStyle('widget.title.dark.large.extra_fat'))),
                          _athleticsDetails(),
                          Visibility(
                              visible: showDescription,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                                _divider(),
                                Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                    child: Text(description ?? '', style: Styles().textStyles.getTextStyle('widget.card.detail.medium')))
                              ])),
                          Visibility(
                              visible: showInterests,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                                Container(height: 1, color: Styles().colors.surfaceAccent),
                                Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                                      Text(Localization().getStringEx('widget.card.label.interests', 'Because of your interest in:'),
                                          style: Styles().textStyles.getTextStyle('widget.card.detail.tiny.fat')),
                                      Text(StringUtils.ensureNotEmpty(interestsLabelValue),
                                          style: Styles().textStyles.getTextStyle('widget.card.detail.tiny.medium_fat'))
                                    ]))
                              ])),
                          Visibility(
                              visible: isGetTicketsVisible,
                              child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: RoundedButton(
                                      label: Localization().getStringEx('widget.athletics_card.button.get_tickets.title', 'Get Tickets'),
                                      hint: Localization().getStringEx('widget.athletics_card.button.get_tickets.hint', ''),
                                      textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
                                      backgroundColor: Colors.white,
                                      borderColor: Styles().colors.fillColorSecondary,
                                      onTap: _onTapGetTickets)))
                        ]))),
                !showImage ? Container(height: 7, color: Styles().colors.fillColorPrimary) : Container(),
              ]))
        ]));
  }

  void _onTapGetTickets() {
    Analytics().logSelect(target: "AthleticsEventCard: Item:${_game?.title} - Get Tickets");
    if (PrivacyTicketsDialog.shouldConfirm) {
      PrivacyTicketsDialog.show(context, onContinueTap: () {
        _showTicketsPanel();
      });
    } else {
      _showTicketsPanel();
    }
  }

  void _onTapCardImage(String? url) {
    Analytics().logSelect(target: "Athletics Image");
    if (url != null) {
      Navigator.push(
          context,
          PageRouteBuilder(
              opaque: false,
              pageBuilder: (context, _, __) =>
                  ModalImagePanel(imageUrl: url, onCloseAnalytics: () => Analytics().logSelect(target: "Close Image"))));
    }
  }

  void _showTicketsPanel() {
    String? url = _game?.links?.tickets;
    if (StringUtils.isNotEmpty(url)) {
      Uri? uri = Uri.tryParse(url!);
      if (uri != null) {
        launchUrl(uri, mode: Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault);
      }
    }
  }

  Widget _athleticsDetails() {
    List<Widget> details = [];

    Widget? time = _athleticsTimeDetail();
    if (time != null) {
      details.add(time);
    }

    Widget? location = _athleticsLocationDetail();
    if (location != null) {
      details.add(location);
    }

    return (0 < details.length)
        ? Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: details))
        : Container();
  }

  Widget? _athleticsTimeDetail() {
    String? displayTime = _game?.displayTime;
    if (StringUtils.isNotEmpty(displayTime)) {
      return Padding(
        padding: _detailPadding,
        child: Semantics(
            label: displayTime,
            excludeSemantics: true,
            child: Row(
              children: <Widget>[
                Styles().images.getImage('time', excludeFromSemantics: true) ?? Container(),
                Padding(
                  padding: _iconPadding,
                ),
                Text(displayTime!, style: Styles().textStyles.getTextStyle('widget.card.detail.medium')),
              ],
            )),
      );
    } else {
      return null;
    }
  }

  Widget? _athleticsLocationDetail() {
    String? locationText = _game?.location?.location;
    if ((locationText != null) && locationText.isNotEmpty) {
      return Padding(
        padding: _detailPadding,
        child: Semantics(
            label: locationText,
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Styles().images.getImage('location', excludeFromSemantics: true) ?? Container(),
                Padding(
                  padding: _iconPadding,
                ),
                Flexible(
                    child: Text(locationText,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: Styles().textStyles.getTextStyle('widget.card.detail.medium'))),
              ],
            )),
      );
    } else {
      return null;
    }
  }

  Widget _divider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0),
      child: Container(
        height: 1,
        color: Styles().colors.fillColorPrimaryTransparent015,
      ),
    );
  }

  void _onTapSave() {
    Analytics().logSelect(target: "Favorite: ${_game?.title}");
    Auth2().prefs?.toggleFavorite(widget.sportEvent);
  }

  void _onTapSportCategory(SportDefinition? sport) {
    Analytics().logSelect(target: "AthleticsEventCard: Item:${_game?.title} - category: ${sport?.name}");
    if (sport != null) {
      if (Connectivity().isNotOffline) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsTeamPanel(sport)));
      } else {
        AppAlert.showOfflineMessage(
            context, Localization().getStringEx('widget.athletics_card.label.offline.sports', 'Sports are not available while offline.'));
      }
    }
  }

  String? _getInterestsLabelValue() {
    String? sportName = _game?.sport?.shortName;
    bool isSportFavorite = Auth2().prefs?.hasSportInterest(sportName) ?? false;
    return isSportFavorite ? Sports().getSportByShortName(sportName)?.customName : null;
  }

  Game? get _game => (widget.sportEvent.hasGame ? widget.sportEvent.game : null);
}

class AthleticsTeamsFilterWidget extends StatefulWidget {
  final bool? favoritesMode;
  final bool? hideFilterDescription;

  AthleticsTeamsFilterWidget({this.favoritesMode, this.hideFilterDescription});

  @override
  State<AthleticsTeamsFilterWidget> createState() => _AthleticsTeamsFilterWidgetState();
}

class _AthleticsTeamsFilterWidgetState extends State<AthleticsTeamsFilterWidget> implements NotificationsListener {
  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Auth2UserPrefs.notifyInterestsChanged]);
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
          color: _showFilterDescription ? Styles().colors.surface : null,
          decoration: !_showFilterDescription ? _filterDecoration : null,
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                InkWell(
                    splashColor: Colors.transparent,
                    onTap: () => _onTapTeamsFilter(context),
                    child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Styles().colors.disabledTextColor, width: 1),
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            child: Row(children: [
                              Styles().images.getImage('filters') ?? Container(),
                              Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  child: Text(Localization().getStringEx('panel.athletics.content.common.filter.teams.label', 'Teams'),
                                      style: Styles().textStyles.getTextStyle('widget.button.title.small.fat'))),
                              Styles().images.getImage('chevron-right-gray') ?? Container()
                            ])))),
                Expanded(child: Container())
              ]))),
      Visibility(
          visible: _showFilterDescription,
          child: Column(children: [
            Divider(thickness: 1, color: Styles().colors.lightGray, height: 1),
            Container(
                decoration: _showFilterDescription ? _filterDecoration : null,
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(children: [
                      Expanded(
                          child: Text(StringUtils.ensureNotEmpty(_teamsFilterLabel),
                              style: Styles().textStyles.getTextStyle('widget.button.title.small'),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1))
                    ])))
          ]))
    ]);
  }

  void _onTapTeamsFilter(BuildContext context) {
    Analytics().logSelect(target: 'Teams');
    AthleticsMyTeamsPanel.present(context);
  }

  String get _teamsFilterLabel {
    Set<String>? favoriteSports = Auth2().prefs?.sportsInterests;
    String filterPrefix = Localization().getStringEx('panel.athletics.content.common.filter.label', 'Filter:');
    String teamsFilterDisplayString = Localization().getStringEx('panel.athletics.content.common.filter.value.none.label', 'None');
    if (CollectionUtils.isNotEmpty(favoriteSports)) {
      List<SportDefinition> sports = <SportDefinition>[];
      for (String sportShortName in favoriteSports!) {
        SportDefinition? sport = Sports().getSportByShortName(sportShortName);
        if (sport != null) {
          sports.add(sport);
        }
      }
      teamsFilterDisplayString = sports.map((team) => team.name).toList().join(', ');
      if (_favoritesMode) {
        teamsFilterDisplayString +=
            ', ' + Localization().getStringEx('panel.athletics.content.common.filter.value.starred.label', 'Starred');
      }
    } else if (_favoritesMode) {
      teamsFilterDisplayString = Localization().getStringEx('panel.athletics.content.common.filter.value.starred.label', 'Starred');
    }
    return '$filterPrefix $teamsFilterDisplayString';
  }

  bool get _favoritesMode => (widget.favoritesMode == true);

  bool get _showFilterDescription => (_filterApplied || (widget.hideFilterDescription != true));

  bool get _filterApplied => CollectionUtils.isNotEmpty(Auth2().prefs?.sportsInterests);

  BoxDecoration get _filterDecoration => BoxDecoration(color: Styles().colors.surface, boxShadow: kElevationToShadow[2]);

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == Auth2UserPrefs.notifyInterestsChanged) {
      setStateIfMounted(() {});
    }
  }
}
