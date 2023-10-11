
import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Favorite.dart';
import 'package:illinois/model/Location.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

////////////////////////////
/// MTDStopScheduleCard

class MTDStopCard extends StatelessWidget {
  final MTDStop? stop;
  final Set<String>? expanded;
  final void Function(MTDStop? stop)? onDetail;
  final void Function(MTDStop? stop)? onExpand;
  final Position? currentPosition;

  MTDStopCard({Key? key, this.stop, this.expanded, this.onDetail, this.onExpand, this.currentPosition }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[];
    contentList.add(_buildHeading(context));
    contentList.add(_buildEntries(context));
    return Column(children: contentList,);
  }

  Widget _buildHeading(BuildContext context) {
    String description = '';
    TextStyle? titleStyle;
    EdgeInsetsGeometry titlePadding, favoritePadding;
    if (CollectionUtils.isNotEmpty(stop?.points)) {

      if (StringUtils.isNotEmpty(stop?.code)) {
        description = stop!.code!;
      }

      String? distance = distanceText;
      if (StringUtils.isNotEmpty(distance)) {
        if (description.isNotEmpty) {
          description += ", $distance";
        }
        else {
          description = distance!;
        }
      }

      int stopPointsCount = stop?.points?.length ?? 0;
      String pointsDescription = (1 < stopPointsCount) ? "$stopPointsCount stop points" : "$stopPointsCount stop point";
      if (description.isNotEmpty) {
        description += " ($pointsDescription)";
      }
      else {
        description = pointsDescription;
      }

      titleStyle = Styles().textStyles?.getTextStyle("widget.title.large.extra_fat");
      titlePadding = EdgeInsets.only(top: 12);
      favoritePadding = EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8);
    }
    else {
      titleStyle = Styles().textStyles?.getTextStyle("widget.title.regular.fat");
      titlePadding = EdgeInsets.only(top: 16);
      favoritePadding = EdgeInsets.all(16);
    }

    return Padding(padding: EdgeInsets.only(bottom: 4), child:
      InkWell(onTap: () => _onTapDetail(stop), child:
        Container(
          decoration: BoxDecoration(color: Styles().colors?.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),),
          padding: EdgeInsets.only(left: 16,),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child:
                Padding(padding: titlePadding, child:
                  Text(stop?.name ?? '', style: titleStyle)
                )
              ),
              Opacity(opacity: 1, child:
                Semantics(label: 'Favorite', button: true, child:
                  InkWell(onTap: () => _onTapFavorite(context), child:
                    FavoriteStarIcon(selected: _isFavorite, style: FavoriteIconStyle.Button, padding: favoritePadding,)
                  ),
                ),
              ),
            ],),
            
            Visibility(visible: description.isNotEmpty || CollectionUtils.isNotEmpty(stop?.points), child:
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child:
                  Padding(padding: EdgeInsets.only(top: 4, bottom: 8), child:
                    Text(description, style: Styles().textStyles?.getTextStyle("widget.info.regular.thin"), maxLines: 1, overflow: TextOverflow.ellipsis,)
                  )
                ),
                Semantics(
                  label: _isExpanded ? Localization().getStringEx('panel.browse.section.status.colapse.title', 'Colapse') : Localization().getStringEx('panel.browse.section.status.expand.title', 'Expand'),
                  hint: _isExpanded ? Localization().getStringEx('panel.browse.section.status.colapse.hint', 'Tap to colapse section content') : Localization().getStringEx('panel.browse.section.status.expand.hint', 'Tap to expand section content'),
                  button: true, child:
                    InkWell(onTap: () => _onTapExpand(stop), child:
                      Container(padding: EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 16), child:
                        SizedBox(width: 18, height: 18, child:
                          Center(child:
                            _isExpanded ?
                            Styles().images?.getImage('chevron-up', excludeFromSemantics: true) :
                            Styles().images?.getImage('chevron-down', excludeFromSemantics: true)
                          ),
                        )
                      ),
                    ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildEntries(BuildContext context) {
      List<Widget> entriesList = <Widget>[];
      if (_isExpanded && CollectionUtils.isNotEmpty(stop?.points)) {
        for (MTDStop stop in stop!.points!) {
          entriesList.add(MTDStopCard(
            stop: stop,
            expanded: expanded,
            onExpand: onExpand,
            onDetail: onDetail,
            currentPosition: currentPosition,
          ));
        }
      }
      return entriesList.isNotEmpty ? Padding(padding: EdgeInsets.only(left: 16), child:
        Column(children: entriesList,)
      ) : Container();
  }

  String? get distanceText {
    LatLng? stopPosition = stop?.anyPosition;
    if ((currentPosition != null) && (stopPosition != null) && stopPosition.isValid) {
      double distanceInMeters = Geolocator.distanceBetween(stopPosition.latitude!, stopPosition.longitude!, currentPosition!.latitude, currentPosition!.longitude);
      double distanceInMiles = distanceInMeters / 1609.344;
      return distanceInMiles.toStringAsFixed(1) + " mi away";
    }
    return null;
  }

  bool get _canExpand => StringUtils.isNotEmpty(stop?.id) && CollectionUtils.isNotEmpty(stop?.points);

  bool get _isExpanded => expanded?.contains(stop?.id) ?? false;

  void _onTapExpand(MTDStop? stop) {
    if (_canExpand && (onExpand != null)) {
      onExpand!(stop);
    }
  }

  bool? get _isFavorite {
    if (CollectionUtils.isEmpty(stop?.points)) {
      return Auth2().account?.prefs?.isFavorite(stop) ?? false;
    }
    else {
      bool? stopSelected;
      for (MTDStop stopPoint in stop!.points!) {
        bool stopPointSelected = Auth2().account?.prefs?.isFavorite(stopPoint) ?? false;
        if (stopSelected == null) {
          stopSelected = stopPointSelected;
        }
        else if (stopSelected != stopPointSelected) {
          return null;
        }
      }
      return stopSelected;
    }
  }

  void _onTapFavorite(BuildContext context) {
    Analytics().logSelect(target: "Favorite: ${MTDStop.favoriteKeyName}");
    if (CollectionUtils.isEmpty(stop?.points)) {
      Auth2().account?.prefs?.toggleFavorite(stop);
    }
    else {
       Auth2().account?.prefs?.setListFavorite(stop?.points, _isFavorite != true);
    }
  }

  void _onTapDetail(MTDStop? stop) {
    if (onDetail != null) {
      onDetail!(stop);
    }
  }
}

////////////////////////////
/// MTDStopScheduleCard

class MTDStopScheduleCard extends StatefulWidget {
  final MTDStop stop;
  final void Function()? onTap;
  MTDStopScheduleCard({Key? key, required this.stop, this.onTap}) : super(key: key);

  @override
  State<MTDStopScheduleCard> createState() => _MTDStopScheduleCardState();
}

class _MTDStopScheduleCardState extends State<MTDStopScheduleCard> implements NotificationsListener {
  
  List<MTDDeparture>? _departures;
  bool _loadingDepartures = false;
  bool _refreshingDepartures = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);

    _loadDepartures();

    _refreshTimer = Timer.periodic(Duration(minutes: 1), (time) => _refreshDepartures());

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _refreshTimer?.cancel();
    _refreshTimer = null;
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      if (mounted) {
        setState(() {});
      }
    }
    else if ((name == AppLivecycle.notifyStateChanged) && (param == AppLifecycleState.resumed)) {
      if (mounted) {
        _refreshDepartures();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isFavorite = Auth2().isFavorite(widget.stop);
    Widget? favoriteStarIcon = widget.stop.favoriteStarIcon(selected: isFavorite);
    Color? headerColor = widget.stop.favoriteHeaderColor;
    String? title = widget.stop.favoriteTitle;
    String? cardDetailText = widget.stop.favoriteDetailText;
    Color? cardDetailTextColor = widget.stop.favoriteDetailTextColor ?? Styles().colors?.textBackground;
    Widget? cardDetailImage = StringUtils.isNotEmpty(cardDetailText) ? widget.stop.favoriteDetailIcon : null;
    bool detailVisible = StringUtils.isNotEmpty(cardDetailText);
    return GestureDetector(onTap: widget.onTap, child:
      Semantics(label: title, child:
        Column(children: <Widget>[
          Container(height: 7, color: headerColor,),
          Container(decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4))), child:
            Column(children: [
              Padding(padding: EdgeInsets.all(16), child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Flex(direction: Axis.vertical, children: <Widget>[
                    Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                      Expanded(child:
                        Text(title ?? '', semanticsLabel: "", style: Styles().textStyles?.getTextStyle("widget.title.large")),
                      ),
                      Visibility(visible: Auth2().canFavorite && (favoriteStarIcon != null), child:
                        GestureDetector(behavior: HitTestBehavior.opaque, onTap: _onTapFavoriteStar, child:
                          Semantics(container: true,
                            label: isFavorite
                                ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites')
                                : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                            hint: isFavorite
                                ? Localization().getStringEx('widget.card.button.favorite.off.hint', '')
                                : Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
                            button: true,
                            excludeSemantics: true,
                            child: Container(padding: EdgeInsets.only(left: 24, bottom: 24), child: favoriteStarIcon))),
                          )
                        ],
                      )
                    ],
                  ),
                  Visibility(visible: detailVisible, child:
                    Semantics(label: cardDetailText, excludeSemantics: true, child:
                      Padding(padding: EdgeInsets.only(top: 12), child:
                        (cardDetailImage != null) ? 
                          Row(children: <Widget>[
                            Padding(padding: EdgeInsets.only(right: 10), child: cardDetailImage,),
                            Expanded(child:
                              Text(cardDetailText ?? '', semanticsLabel: "", style: Styles().textStyles?.getTextStyle("widget.item.regular")?.copyWith(color: cardDetailTextColor)),
                            )
                          ],) :
                          Text(cardDetailText ?? '', semanticsLabel: "", style: Styles().textStyles?.getTextStyle("widget.item.regular")?.copyWith(color: cardDetailTextColor)),
                      ),
                    ),
                  ),
                ]),
              ),
              Divider(height: 1, color: Styles().colors!.fillColorPrimaryTransparent03,),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0), child:
                _buildDepartures(),
              ),
            ],),
          )
        ],)
      ),
    );
  }

  Widget _buildDepartures() {
    if (_loadingDepartures) {
      return _buildDeparturesLoading();
    }
    else if (_departures == null) {
      return _buildDeparturesError('Failed to load bus schedule.');
    }
    else if (_departures!.isEmpty) {
      return _buildDeparturesError('No bus schedule available.');
    }
    else {
      return _buildDeparturesList();
    }
  }

  Widget _buildDeparturesLoading() {
    return Center(child:
      Padding(padding: EdgeInsets.all(16), child:
        SizedBox(width: 24, height: 24, child:
          CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 2, )
        )
      )

    );
  }

  Widget _buildDeparturesError(String? error) {
    return  Center(child:
      Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
        Row(children: [
          Expanded(child:
            Text(error ?? '', style:
              Styles().textStyles?.getTextStyle("widget.message.regular"), textAlign: TextAlign.center,),
          ),
        ],)
      )
    );
  }

  Widget _buildDeparturesList() {
    List<Widget> contentList = <Widget>[];
    int departuresCount = min(_departures?.length ?? 0, 2);
    for (int index = 0; index < departuresCount; index++) {
      MTDDeparture departure = _departures![index];
      if (contentList.isNotEmpty) {
        contentList.add(Divider(height: 1, color: Styles().colors!.fillColorPrimaryTransparent03,));
      }
      contentList.add(MTDDepartureCard(
        departure: departure,
        onTap: () => _onTapDeparture(departure),
        padding: EdgeInsets.symmetric(vertical: 8),
        circleSize: 42,
        textSize: 16,
        timeSize1: 20,
        timeSize2: 14,
      ));
    }
    return Column(children: contentList,);
  }

  void _loadDepartures() {
    if (widget.stop.id != null) {
      //debugPrint('Loading departures for ${widget.stop.name}...');
      _loadingDepartures = _refreshingDepartures = true;
       
      MTD().getDepartures(stopId: widget.stop.id!, previewTime: 1440).then((List<MTDDeparture>? departures) {
        //debugPrint('Did load departures for ${widget.stop.name}: ${departures?.length}');
        if (mounted) {
          setState(() {
            _loadingDepartures = _refreshingDepartures = false;
            _departures = departures;
          });
        }
      });
    }
  }

  void _refreshDepartures() {
    if ((widget.stop.id != null) && !_refreshingDepartures && mounted) {
      //debugPrint('Refreshing departures for ${widget.stop.name}...');
      _refreshingDepartures = true;
      MTD().getDepartures(stopId: widget.stop.id!, previewTime: 1440).then((List<MTDDeparture>? departures) {
        //debugPrint('Did refresh departures for ${widget.stop.name}: ${departures?.length}');
        if (_refreshingDepartures) {
          _refreshingDepartures = false;
          if (mounted && (departures != null) && !DeepCollectionEquality().equals(_departures, departures)) {
            setState(() {
              _departures = departures;
            });
          }
        }
      });
    }
  }

  void _onTapFavoriteStar() {
    Analytics().logSelect(target: "Favorite: ${widget.stop.favoriteTitle}", source: '${widget.runtimeType.toString()}(${MTDStop.favoriteKeyName})');
    Auth2().prefs?.toggleFavorite(widget.stop);
  }

  void _onTapDeparture(MTDDeparture departure) {
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }
}

////////////////////////////
/// MTDDepartureCard

class MTDDepartureCard extends StatelessWidget {
  final MTDDeparture departure;
  final void Function()? onTap;
  final EdgeInsetsGeometry padding;
  final double circleSize;
  final double textSize;
  final double timeSize1;
  final double timeSize2;
  
  MTDDepartureCard({Key? key, required this.departure, this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.circleSize = 48,
    this.textSize = 16,
    this.timeSize1 = 24,
    this.timeSize2 = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? expectedTimeString1, expectedTimeString2;
    int expectedMins = departure.expectedMins ?? -1;
    if (expectedMins == 0) {
      expectedTimeString1 = 'Now';
    }
    else if (expectedMins == 1) {
      expectedTimeString1 = '1';
      expectedTimeString2 = 'min';
    }
    else if ((1 < expectedMins) && (expectedMins < 60)) {
      expectedTimeString1 = '$expectedMins';
      expectedTimeString2 = 'mins';
    }
    else {
      DateTime? expectedTime = departure.expectedTime;
      expectedTimeString1 = (expectedTime != null) ? DateFormat('h:mm').format(expectedTime) : null;
      expectedTimeString2 = (expectedTime != null) ? DateFormat('a').format(expectedTime) : null;
    }

    String? desciption = StringUtils.isNotEmpty(departure.trip?.headsign) ? 'To ${departure.trip?.headsign}' : '';
    
    return Semantics(child: InkWell(onTap: onTap, child: Container(padding: padding, child:
      Row(children: [
        Container(width: circleSize, height: circleSize,
          decoration: BoxDecoration(
            color: departure.route?.color,
            border: Border.all(color: Styles().colors!.surfaceAccentTransparent15!, width: 1),
            shape: BoxShape.circle),
          child: Center(child:
            Text(departure.route?.shortName ?? '', overflow: TextOverflow.ellipsis, style: Styles().textStyles?.getTextStyle("widget.detail.large.thin")?.copyWith(color: departure.route?.textColor))
          )
        ),
        Expanded(child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
            Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(departure.headsign ?? '', style: Styles().textStyles?.getTextStyle("widget.item.regular")?.copyWith(fontSize: textSize)),
                Text(desciption, style: Styles().textStyles?.getTextStyle("widget.item.regular.thin")?.copyWith(fontSize: textSize))
            ],)
          )
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(expectedTimeString1 ?? '', style: Styles().textStyles?.getTextStyle("widget.detail.extra_large")?.copyWith(fontSize: timeSize1)),
          Text(expectedTimeString2 ?? '', style: Styles().textStyles?.getTextStyle("widget.item.regular.thin")?.copyWith(fontSize: timeSize2)),
        ],)
      ],)
    ),));
  }
}

