
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:illinois/ext/Favorite.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/MTD.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

////////////////////////////
/// MTDStopCard

class MTDStopCard extends StatefulWidget {
  final MTDStop stop;
  final void Function()? onTap;
  MTDStopCard({Key? key, required this.stop, this.onTap}) : super(key: key);

  @override
  State<MTDStopCard> createState() => _MTDStopCardState();
}

class _MTDStopCardState extends State<MTDStopCard> implements NotificationsListener {
  
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
    Image? favoriteStarIcon = widget.stop.favoriteStarIcon(selected: isFavorite);
    Color? headerColor = widget.stop.favoriteHeaderColor;
    String? title = widget.stop.favoriteTitle;
    String? cardDetailText = widget.stop.favoriteDetailText;
    Color? cardDetailTextColor = widget.stop.favoriteDetailTextColor ?? Styles().colors?.textBackground;
    Image? cardDetailImage = StringUtils.isNotEmpty(cardDetailText) ? widget.stop.favoriteDetailIcon : null;
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
                        Text(title ?? '', semanticsLabel: "", style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20), ),
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
                              Text(cardDetailText ?? '', semanticsLabel: "", style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: cardDetailTextColor)),
                            )
                          ],) :
                          Text(cardDetailText ?? '', semanticsLabel: "", style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: cardDetailTextColor)),
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
        _refreshingDepartures = false;
        if (mounted && (departures != null)) {
          setState(() {
            _departures = departures;
          });
        }
      });
    }
  }

  void _onTapFavoriteStar() {
    Analytics().logSelect(target: "Favorite: ${widget.stop.favoriteTitle}", source: '${widget.runtimeType.toString()}(${MTDStop.favoriteKeyName})');
    Auth2().prefs?.toggleFavorite(widget.stop);
  }

  void _onTapDeparture(MTDDeparture departure) {
    //TBD
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
    
    return InkWell(onTap: onTap, child: Container(padding: padding, child:
      Row(children: [
        Container(width: circleSize, height: circleSize,
          decoration: BoxDecoration(
            color: departure.route?.color,
            border: Border.all(color: Styles().colors!.surfaceAccentTransparent15!, width: 1),
            shape: BoxShape.circle),
          child: Center(child:
            Text(departure.route?.shortName ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 20, color: departure.route?.textColor,))
          )
        ),
        Expanded(child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
            Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(departure.headsign ?? '', style: TextStyle(fontFamily: Styles().fontFamilies?.medium, fontSize: textSize, color: Styles().colors?.textBackground,),),
                Text(desciption, style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: textSize, color: Styles().colors?.textBackground,),)
            ],)
          )
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(expectedTimeString1 ?? '', style: TextStyle(fontFamily: Styles().fontFamilies?.medium, fontSize: timeSize1, color: Styles().colors?.fillColorPrimary,),),
          Text(expectedTimeString2 ?? '', style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: timeSize2, color: Styles().colors?.textBackground,),),
        ],)
      ],)
    ),);
  }
}

