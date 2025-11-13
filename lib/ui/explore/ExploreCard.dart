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
import 'package:geolocator/geolocator.dart' as Core;
import 'package:illinois/ext/Dining.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Game.dart';
import 'package:illinois/ext/StudentCourse.dart';
import 'package:illinois/model/Building.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/model/wellness/WellnessBuilding.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Sports.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:illinois/model/Dining.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class ExploreCard extends StatefulWidget {
  final Explore? explore;
  final Core.Position? locationData;
  final GestureTapCallback? onTap;
  final ExploreSelectLocationBuilder? selectLocationBuilder;

  ExploreCard({super.key, this.explore, this.locationData, this.onTap, this.selectLocationBuilder});

  @override
  _ExploreCardState createState() => _ExploreCardState();
}

class _ExploreCardState extends State<ExploreCard> with NotificationsListener {

  static const EdgeInsets _detailPadding = EdgeInsets.only(bottom: 8, left: 16, right: 16);
  static const EdgeInsets _iconPadding = EdgeInsets.only(right: 8);
  static const double _smallImageSize = 64;

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

  String get semanticLabel {
    String? category = _exploreCategory;
    String? sportName = _gameSportName;
    if (StringUtils.isNotEmpty(category) && StringUtils.isNotEmpty(sportName)) {
      category = '$category - $sportName';
    }
    Explore? explore = widget.explore;
    String title = widget.explore?.exploreTitle ?? "";
    String? time = _getExploreTimeDisplayString();
    String locationText = widget.explore?.getShortDisplayLocation(widget.locationData) ?? "";
    String workTime = ((explore is Dining) ? explore.displayWorkTime : null) ?? "";

    return "$category, $title, $time, $locationText, $workTime";
  }

  @override
  Widget build(BuildContext context) {
    bool isEvent2 = (widget.explore is Event2);
    bool isGame = (widget.explore is Game);
    String imageUrl = StringUtils.ensureNotEmpty(widget.explore?.exploreImageUrl);
    Widget? selectWidget = widget.selectLocationBuilder?.call(context, ExploreSelectLocationContext.card, explore: widget.explore);
    Widget? imageWidget = StringUtils.isNotEmpty(imageUrl) ?
      SizedBox(width: _smallImageSize, height: _smallImageSize, child:
        InkWell(onTap: () => _onTapCardImage(imageUrl),
          child: Image.network(imageUrl, excludeFromSemantics: true, fit: BoxFit.fill, headers: Config().networkAuthHeaders)),
      ) : null;
    Widget? rightWidget = ((selectWidget != null) || (imageWidget != null)) ?
      Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: _hasPaymentTypes ? 12 : 16, top: (isEvent2 || isGame) ? 12 : 0), child:
        selectWidget ?? imageWidget
      ) : null;

    return Semantics(label: semanticLabel, button: true, child:
      GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTap, child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
          Container(decoration: _cardDecoration, child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              _topBorder,
              _topWidget,
              Semantics(excludeSemantics: true, child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Expanded(child:
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        if (isEvent2 || isGame)
                          _exploreName,
                        if (selectWidget == null)
                          _exploreDetails,
                      ],)
                    ),
                    if (rightWidget != null)
                      rightWidget,
                  ],),
                  _explorePaymentTypes(),
                ]),
              )
            ],),
          ),
        ),
      ),
    );
  }

  Decoration get _cardDecoration =>
    BoxDecoration(
      color: Colors.white,
      //border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
      borderRadius: BorderRadius.all(Radius.circular(4)),
      boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]
    );

  Widget get _topWidget {

    String? category = _exploreCategory;
    bool isFavorite = widget.explore?.isFavorite ?? false;
    bool starVisible = Auth2().canFavorite && (widget.explore is Favorite);
    String leftLabel = "";
    TextStyle? leftLabelStyle;
    if (StringUtils.isNotEmpty(category)) {
      leftLabel = category!.toUpperCase();
      String? sportName = _gameSportName;
      if (StringUtils.isNotEmpty(sportName)) {
        leftLabel += ' - $sportName';
      }
      leftLabelStyle = Styles().textStyles.getTextStyle('widget.description.small.fat.semi_expanded') ;
    } else {
      leftLabel = widget.explore!.exploreTitle ?? "";
      leftLabelStyle = Styles().textStyles.getTextStyle('widget.explore.card.title.regular.extra_fat') ;
    }

    return Row(children: <Widget>[
      Expanded(child:
        Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 12), child:
          Text(leftLabel, style: leftLabelStyle, semanticsLabel: "",)
        ),
      ),
      Visibility(visible: starVisible, child:
        Semantics(container: true, child:
          Container( child:
            Semantics(
              label: isFavorite ? Localization().getStringEx(
                  'widget.card.button.favorite.off.title',
                  'Remove From Favorites') : Localization().getStringEx(
                  'widget.card.button.favorite.on.title',
                  'Add To Favorites'),
              hint: isFavorite ? Localization().getStringEx(
                  'widget.card.button.favorite.off.hint', '') : Localization()
                  .getStringEx('widget.card.button.favorite.on.hint', ''),
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                  onTap: _onTapExploreCardStar,
                  child: Container(child:
                    Padding(
                      padding: EdgeInsets.only(right: 16, top: 12, left: 24, bottom: 5),
                      child: Styles().images.getImage(isFavorite ? 'star-filled' : 'star-outline-gray', excludeFromSemantics: true,)
                    )
                  )
                )
            ),
          )
        )
      )
    ],);
  }

  Widget get _exploreName =>
    Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 6), child:
      Text(StringUtils.ensureNotEmpty(widget.explore?.exploreTitle), style:
        Styles().textStyles.getTextStyle('widget.title.large.extra_fat')
      )
    );

  Widget get _exploreDetails {
    List<Widget> details = [];

    Widget? time = _exploreTimeDetail();
    if (time != null) {
      details.add(time);
    }

    Widget? location = _exploreLocationDetail();
    if (location != null) {
      details.add(location);
    }

    Widget? online = _exploreOnlineDetail();
    if (online != null) {
      details.add(online);
    }

    Widget? workTime = _exploreWorkTimeDetail();
    if (workTime != null) {
      details.add(workTime);
    }

    return (0 < details.length) ?
      Padding(padding: EdgeInsets.only(top: 6, bottom: 12), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: details)
      ) : Container();
  }

  Widget? _exploreTimeDetail() {
    String? displayTime = _getExploreTimeDisplayString();
    if (StringUtils.isEmpty(displayTime)) {
      return null;
    }
    return Semantics(label: displayTime, child: Padding(
      padding: _detailPadding,
      child: Row(
        children: <Widget>[
          Styles().images.getImage('calendar', excludeFromSemantics: true) ?? Container(),
          Padding(
            padding: _iconPadding,
          ),
          Flexible(child: Text(displayTime!, overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Styles().textStyles.getTextStyle('widget.explore.card.detail.regular') )
            ,)
        ],
      ),
    ));
  }

  Widget? _exploreLocationDetail() {
    String? locationText;
    void Function()? onLocationTap;

    Explore? explore = widget.explore;
    if (explore is Event2 ) {//For Events we show Two Locati
      if (explore.isInPerson) {
        locationText = Localization().getStringEx('panel.explore_detail.event_type.in_person', "In-person event");
      }
    }
    else if (explore is Building) {
      locationText = explore.fullAddress;
      onLocationTap = _onTapExploreLocation;
    }
    else if (explore is WellnessBuilding) {
      locationText = explore.building.fullAddress;
      onLocationTap = _onTapExploreLocation;
    }
    else if (explore is StudentCourse) {
      locationText = explore.section?.displayLocation;
      onLocationTap = _onTapExploreLocation;
    }

    if ((locationText != null) && locationText.isNotEmpty) {
      return Semantics(label: locationText, button: (onLocationTap != null), child:
        InkWell(onTap: onLocationTap, child:
          Padding(padding: _detailPadding, child:
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Padding(padding: _iconPadding, child: Styles().images.getImage('location', excludeFromSemantics: true)
              ),
              Expanded(child:
                Text(locationText, style: (onLocationTap != null) ? Styles().textStyles.getTextStyle('widget.explore.card.detail.regular.underline') : Styles().textStyles.getTextStyle('widget.explore.card.detail.regular')
                )
              ),
            ],
          ),
        ),
      ));
    } else {
      return null;
    }
  }

  Widget? _exploreOnlineDetail() {
    if ((widget.explore is Event2) && ((widget.explore as Event2).isOnline)) {
        return Semantics(label: Localization().getStringEx('panel.explore_detail.event_type.online', "Online Event"), child:Padding(
          padding: _detailPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Styles().images.getImage("laptop", excludeFromSemantics: true) ?? Container(), //TBD update icon res
              Padding(
                padding: _iconPadding,
              ),
              Expanded(child: Text(Localization().getStringEx('panel.explore_detail.event_type.online', "Online Event") ,
                  style: Styles().textStyles.getTextStyle('widget.explore.card.detail.regular'))),
            ],
          ),
        ));
    }

    return null;
  }

  Widget? _exploreWorkTimeDetail() {
    Dining? dining = (widget.explore is Dining) ? (widget.explore as Dining) : null;
    String? displayTime = dining?.displayWorkTime;
    if ((displayTime != null) && displayTime.isNotEmpty) {
      return Semantics(label: displayTime, child:Padding(
        padding: _detailPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Styles().images.getImage('time', excludeFromSemantics: true) ?? Container(),
            Padding(
              padding: _iconPadding,
            ),
            Expanded(
              child: Text(displayTime,
                  style: Styles().textStyles.getTextStyle('widget.explore.card.detail.regular')),
            ),
          ],
        ),
      ));
    }
    return null;
  }

  bool get _hasPaymentTypes {
    Dining? dining = (widget.explore is Dining) ? (widget.explore as Dining) : null;
    List<PaymentType>? paymentTypes = dining?.paymentTypes;
    return ((paymentTypes != null) && (0 < paymentTypes.length));
  }

  Widget _explorePaymentTypes() {
    List<Widget>? details;
    Dining? dining = (widget.explore is Dining) ? (widget.explore as Dining) : null;
    List<PaymentType>? paymentTypes = dining?.paymentTypes;
    if ((paymentTypes != null) && (0 < paymentTypes.length)) {
      details = [];
      for (PaymentType paymentType in paymentTypes) {
        Widget? image = paymentType.iconWidget;
        if (image != null) {
          details.add(Padding(padding: EdgeInsets.only(right: 6), child:image) );
        }
      }
    }
      return ((details != null) && (0 < details.length)) ? Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _divider(),
              Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: details))
              
            ])
        
        : Container();
  }

  String? _getExploreTimeDisplayString() {
    Explore? explore = widget.explore;
    if (explore is Event2) {
      return explore.shortDisplayDateAndTime;
    } else if (explore is Game) {
      return explore.displayTime;
    } else if (explore is StudentCourse) {
      return explore.section?.displaySchedule;
    } else {
      return '';
    }
  }

  Widget _divider(){
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0),
      child: Container(
        height: 1,
        color: Styles().colors.fillColorPrimaryTransparent015,
      ),
    );
  }

  Widget get _topBorder =>
    Container(height: 7, color: widget.explore?.uiColor);

  void _onTapExploreCardStar() {
    Analytics().logSelect(target: "Favorite: ${widget.explore?.exploreTitle}");
    widget.explore?.toggleFavorite();
  }

  void _onTapExploreLocation() {
    Analytics().logSelect(target: "Location Directions");
    widget.explore?.launchDirections();
  }

  void _onTapCardImage(String? url) {
    Analytics().logSelect(target: "Explore Image");
    if (url != null) {
      Navigator.push(
          context,
          PageRouteBuilder(
              opaque: false,
              pageBuilder: (context, _, __) =>
                  ModalPhotoImagePanel(imageUrl: url, onCloseAnalytics: () => Analytics().logSelect(target: "Close Image"))));
    }
  }

  String? get _exploreCategory {
    if (widget.explore is Event2) {
      return Events2().displaySelectedContentAttributeLabelsFromSelection((widget.explore as Event2).attributes, usage: ContentAttributeUsage.category)?.join(', ');
    } else if (widget.explore is Game) {
      return Events2.sportEventCategory;
    } else {
      return '';
    }
  }

  String? get _gameSportName {
    if (!(widget.explore is Game)) {
      return null;
    }
    Game? game = (widget.explore is Game) ? (widget.explore as Game) : null;
    SportDefinition? sport = Sports().getSportByShortName(game?.sport?.shortName);
    return sport?.customName;
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted(() {});
    }
    else if (name == FlexUI.notifyChanged) {
      setStateIfMounted(() {});
    }
  }
}
