import 'dart:async';

import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/RadioPlayer.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class HomeRadioWidget extends StatelessWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeRadioWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.radio.illini.title', 'Illini Radio');

  @override
  Widget build(BuildContext context) {
    return HomeFavoriteWidget(favoriteId: favoriteId,
      title: title,
      child: Container(padding: EdgeInsets.all(16), margin: EdgeInsets.symmetric(horizontal: 16), decoration: HomeMessageCard.defaultDecoration, child:
        _RadioControl(analyticsHost: this.runtimeType.toString(),),
        /*HomeMessageCard(
          message: Localization().getStringEx('widget.home.radio.disabled.message', 'WPGU 107.1 FM is not enabled.'),
          margin: EdgeInsets.only(top: 8, bottom: 16),
        ),*/
      ),
    );
  }
}

class RadioPopupWidget extends StatelessWidget with AnalyticsInfo {
  RadioPopupWidget({ super.key });

  @override
  //Map<String, dynamic>? get analyticsPageAttributes =>
  //  _radioStationAnalyticsAttributes(radioStation);

  @override
  AnalyticsFeature? get analyticsFeature =>
    AnalyticsFeature.Radio;

  static void show(BuildContext context) =>
    showDialog(context: context, barrierDismissible: true, builder:
      (BuildContext context) => RadioPopupWidget()
    );

  static String stationTitle(RadioStation radioStation) =>
    _radioStationTitle(radioStation);

  @override
  Widget build(BuildContext context) =>
    ClipRRect(borderRadius: HomeMessageCard.defaultBorderRadius, child:
      Dialog(shape: RoundedRectangleBorder(borderRadius: HomeMessageCard.defaultBorderRadius,), child:
        HomeCardWidget(
          title: Localization().getStringEx('widget.home.radio.illini.title', 'Illini Radio'),
          onClose: () => _onClosePopup(context),
          margin: EdgeInsets.zero,
          child: _RadioControl(
            analyticsHost: this.runtimeType.toString(),
            onInitState: _didInitRadioControl,
          ),
        )
      ),
    );

  void _didInitRadioControl() {
    Analytics().logPageWidget(this);
  }

  void _onClosePopup(BuildContext context) {
    Analytics().logSelect(
      target: 'Close',
      source: runtimeType.toString(),
      attributes: analyticsPageAttributes,
    );
    Navigator.of(context).pop();
  }
}

class _RadioControl extends StatefulWidget {

  final void Function()? onInitState;
  final String? analyticsHost;


  const _RadioControl({
    Key? key,
    this.onInitState,
    this.analyticsHost
  }) : super(key: key);

  @override
  State<_RadioControl> createState() => _RadioControlState();
}

class _RadioControlState extends State<_RadioControl> with NotificationsListener {

  late RadioStation _radioStation;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      RadioPlayer.notifyCreateStatusChanged,
      RadioPlayer.notifyPlayerStateChanged,
    ]);

    _radioStation = RadioStation.values.first;
    widget.onInitState?.call();
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
    if (((name == RadioPlayer.notifyCreateStatusChanged) && (param == _radioStation)) ||
        ((name == RadioPlayer.notifyPlayerStateChanged) && (param == _radioStation))) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    _stationsBar,
    _stationControl,
  ],);

  Widget get _stationsBar {
    final double borderWidth = 1.0;
    final Color borderColor = Styles().colors.surfaceAccent; // Styles().colors.mediumGray2
    final BorderSide borderSide = BorderSide(color: borderColor, width: borderWidth);
    final Radius radius = Radius.circular(MediaQuery.of(context).textScaler.scale(14));

    List<Widget> stations = <Widget>[];
    for (int index = 0; index < RadioStation.values.length; index++) {
      RadioStation radioStation = RadioStation.values[index];
      bool selected = (radioStation == _radioStation);

      Border border;
      BorderRadius? borderRadius;
      if (index == 0) {
        border = Border(left: borderSide, top: borderSide, bottom: borderSide, right: borderSide);
        borderRadius = BorderRadius.horizontal(left: radius);
      }
      else if (index == (RadioStation.values.length - 1)) {
        border = Border(right: borderSide, top: borderSide, bottom: borderSide);
        borderRadius = BorderRadius.horizontal(right: radius);
      }
      else {
        border = Border(right: borderSide, top: borderSide, bottom: borderSide);
      }
      BoxDecoration decoration = BoxDecoration(
        color: selected ? Styles().colors.white : Styles().colors.background,
        border: border,
        borderRadius: borderRadius,
      );

      TextStyle? textStyle = selected ? Styles().textStyles.getTextStyleEx('widget.button.title.small.fat', color: Styles().colors.fillColorSecondary) : Styles().textStyles.getTextStyle('widget.button.title.small.medium');

      stations.add(Expanded(child:
        InkWell(onTap: () => _onTapStation(radioStation), child:
          Container(
            decoration: decoration,
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text(_radioStationFrequency(radioStation), style: textStyle, textAlign: TextAlign.center,),
          ),
        ),
      ));
    }
    return Row(children: stations,);
  }

  Widget get _stationControl {
    String? buttonTitle, iconKey;
    bool? progress;
    if (!RadioPlayer().isStationEnabled(_radioStation)) {
      buttonTitle = Localization().getStringEx('widget.home.radio.button.not_available.title', 'Not Available');
    }
    else if (RadioPlayer().isCreating) {
      buttonTitle = Localization().getStringEx('widget.home.radio.button.initalize.title', 'Initializing');
      progress = true;
    }
    else if (!RadioPlayer().isStationCreated(_radioStation)) {
      buttonTitle = Localization().getStringEx('widget.home.radio.button.fail.title', 'Initialization Failed');
    }
    else {
      PlayerState? stationState = RadioPlayer().stationState(_radioStation);
      switch (stationState?.processingState) {
        case ProcessingState.idle:
        case ProcessingState.ready:
          buttonTitle = (stationState?.playing == true) ?
            Localization().getStringEx('widget.home.radio.button.pause.title', 'Pause') :
            Localization().getStringEx('widget.home.radio.button.play.title', 'Tune In');
          iconKey = (stationState?.playing == true) ? 'pause-circle-large' : 'play-circle-large';
          break;

        case ProcessingState.loading:
          buttonTitle = Localization().getStringEx('widget.home.radio.button.loading.title', 'Loading');
          progress = true;
          break;

        case ProcessingState.buffering:
          buttonTitle = Localization().getStringEx('widget.home.radio.button.buffering.title', 'Buffering');
          progress = true;
          break;

        case ProcessingState.completed:
          buttonTitle = Localization().getStringEx('widget.home.radio.button.finished.title', 'Finished');
          break;

        default:
          buttonTitle = Localization().getStringEx('widget.home.radio.button.unknown.title', 'Unknown');
          break;
      }
    }

    return GestureDetector(onTap: _onTapPlayPause, child:
      Padding(padding: EdgeInsets.only(left: 12, top: 16), child:
        Row(children: <Widget>[
          Expanded(child:
              Container(decoration: BoxDecoration(border: Border(left: BorderSide(color: Styles().colors.fillColorSecondary , width: 2))), child:
                Padding(padding: EdgeInsets.only(left: 12, top: 8, bottom: 8), child:
                  Text(buttonTitle, style: Styles().textStyles.getTextStyle('widget.title.medium.extra_fat'))
                )
              )
          ),
          if (iconKey != null)
            Semantics(button: true,
              excludeSemantics: true,
              label: buttonTitle,
              hint: Localization().getStringEx('widget.home.radio.button.add_radio.hint', ''),
              child:  IconButton(color: Styles().colors.fillColorPrimary,
                icon: Styles().images.getImage(iconKey, excludeFromSemantics: true) ?? Container(),
                onPressed: _onTapPlayPause)
            ),
          if (progress == true)
            Padding(padding: const EdgeInsets.all(12), child:
              SizedBox(width: 26, height: 26, child:
                CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
              ),
            ),
        ]),
      ),
    );
  }

  void _onTapStation(RadioStation radioStation) {
    PlayerState? stationState = RadioPlayer().stationState(_radioStation);
    setState(() {
      _radioStation = radioStation;
    });
    if (stationState?.playing == true) {
      RadioPlayer().playStation(_radioStation);
    }
  }

  void _onTapPlayPause() {
    Analytics().logSelect(
      target: RadioPlayer().isStationPlaying(_radioStation) ? 'Pause' : 'Play',
      source: widget.analyticsHost ?? this.runtimeType.toString(),
      attributes: _radioStationAnalyticsAttributes(_radioStation),
    );
    RadioPlayer().toggleStationPlayPause(_radioStation);
  }
}

String _radioStationTitle(RadioStation radioStation) {
  switch(radioStation) {
    case RadioStation.will: return Localization().getStringEx('widget.home.radio.will.title', 'WILL News & Talk (NPR)');
    case RadioStation.willfm: return Localization().getStringEx('widget.home.radio.willfm.title', 'WILL Classical & More');
    case RadioStation.willhd: return Localization().getStringEx('widget.home.radio.willhd.title', 'Illinois Soul 101.1 FM');
    case RadioStation.wpgufm: return Localization().getStringEx('widget.home.radio.wpgufm.title', 'WPGU 107.1 FM');
  }
}

String _radioStationFrequency(RadioStation radioStation) {
  switch(radioStation) {
    case RadioStation.will: return Localization().getStringEx('widget.home.radio.will.frequency', 'АМ 580');
    case RadioStation.willfm: return Localization().getStringEx('widget.home.radio.willfm.frequency', '90.0 FM');
    case RadioStation.willhd: return Localization().getStringEx('widget.home.radio.willhd.frequency', '101.1 FM');
    case RadioStation.wpgufm: return Localization().getStringEx('widget.home.radio.wpgufm.frequency', '107.1 FM');
  }
}


Map<String, dynamic> _radioStationAnalyticsAttributes(RadioStation radioStation) => <String, dynamic>{
  Analytics.LogAttributeRadioStation: _radioStationTitle(radioStation),
};
