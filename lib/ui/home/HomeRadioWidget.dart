import 'dart:async';

import 'package:flutter/material.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/RadioPlayer.dart';
import 'package:neom/ui/home/HomePanel.dart';
import 'package:neom/ui/home/HomeWidgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class HomeRadioWidget extends StatelessWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;
  final RadioStation radioStation;

  const HomeRadioWidget(this.radioStation, {Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle(RadioStation radioStation, {Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: stationTitle(radioStation),
    );

  String get title => stationTitle(radioStation);

  static String stationTitle(RadioStation radioStation) {
    switch(radioStation) {
      case RadioStation.will: return Localization().getStringEx('widget.home.radio.will.title', 'WILL News & Talk (NPR)');
      case RadioStation.willfm: return Localization().getStringEx('widget.home.radio.willfm.title', 'WILL Classical & More');
      case RadioStation.willhd: return Localization().getStringEx('widget.home.radio.willhd.title', 'Illinois Soul 101.1 FM');
      case RadioStation.wpgufm: return Localization().getStringEx('widget.home.radio.wpgufm.title', 'WPGU 107.1 FM');
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: favoriteId,
      title: title,
      titleIconKey: 'radio',
      childPadding: HomeSlantWidget.defaultChildPadding,
      child: _isEnabled ? _RadioControl(radioStation, borderRadius: BorderRadius.all(Radius.circular(6)),) : HomeMessageCard(
        message: Localization().getStringEx('widget.home.radio.disabled.message', 'WPGU 107.1 FM is not enabled.'),
        margin: EdgeInsets.only(top: 8, bottom: 16),
      ),
    );
  }

  bool get _isEnabled => RadioPlayer().isStationEnabled(radioStation);

  static void showPopup(BuildContext context, RadioStation radioStation) {
    showDialog(context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _buildPopup(context, radioStation);
      },
    );
  }

  static Widget _buildPopup(BuildContext context, RadioStation radioStation) {
    return ClipRRect(borderRadius: BorderRadius.all(Radius.circular(8)), child:
      Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),), child:
        Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Container(color: Styles().colors.fillColorPrimary, child:
            Row(children: <Widget>[
              Expanded(child:
                Padding(padding: EdgeInsets.all(8), child:
                  Center(child:
                    Text(HomeRadioWidget.stationTitle(radioStation), style: Styles().textStyles.getTextStyle("widget.dialog.message.regular")),
                  ),
                ),
              ),
              Semantics( label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), button: true, child:
                InkWell(onTap : () => _onClosePopup(context, radioStation), child:
                  Padding(padding: EdgeInsets.all(16), child:
                    Styles().images.getImage('close-circle-white', excludeFromSemantics: true),
                  ),
                ),
              ),
            ],),
          ),
          _RadioControl(radioStation, borderRadius: BorderRadius.vertical(bottom: Radius.circular(6))),
        ],),
      ),
    );
  }

  static void _onClosePopup(BuildContext context, RadioStation radioStation) {
    Analytics().logSelect(target: 'Close', source: 'HomeRadioWidget(${radioStation.toString()})');
    Navigator.of(context).pop();
  }
}

class _RadioControl extends StatefulWidget {

  final RadioStation radioStation;
  final BorderRadius borderRadius;


  const _RadioControl(this.radioStation, {Key? key, required this.borderRadius}) : super(key: key);

  @override
  State<_RadioControl> createState() => _RadioControlState();
}

class _RadioControlState extends State<_RadioControl> implements NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [
      RadioPlayer.notifyCreateStatusChanged,
      RadioPlayer.notifyPlayerStateChanged,
    ]);

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(visible: RadioPlayer().isStationEnabled(widget.radioStation), child:
      _buildContentCard(),
    );
  }

  Widget _buildContentCard() {
    String? buttonTitle, iconKey;
    bool? progress;
    if (!RadioPlayer().isStationEnabled(widget.radioStation)) {
      buttonTitle = Localization().getStringEx('widget.home.radio.button.not_available.title', 'Not Available');
    }
    else if (RadioPlayer().isCreating) {
      buttonTitle = Localization().getStringEx('widget.home.radio.button.initalize.title', 'Initializing');
      progress = true;
    }
    else if (!RadioPlayer().isStationCreated(widget.radioStation)) {
      buttonTitle = Localization().getStringEx('widget.home.radio.button.fail.title', 'Initialization Failed');
    }
    else {
      PlayerState? stationState = RadioPlayer().stationState(widget.radioStation);
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

          buttonTitle = Localization().getStringEx('widget.home.radio.button.play.title', 'Tune In');
          iconKey = 'play-circle-large';
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
      Container(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))
        ]),
        child:
        ClipRRect(borderRadius: widget.borderRadius, child:
          Row(children: <Widget>[
            Expanded(child:
              Column(children: <Widget>[
                Container(color: Styles().colors.surface, child:
                  Padding(padding: EdgeInsets.only(top: 8, right: 8, bottom: 8), child:
                    Row(children: <Widget>[
                      Expanded(child:
                        Container(color: Styles().colors.surface, child:
                          Padding(padding: EdgeInsets.only(top: 8, right: 8, bottom: 8), child:
                            Row(children: <Widget>[
                              Expanded(child:
                                Padding(padding: EdgeInsets.all(16), child:
                                  Container(decoration: BoxDecoration(border: Border(left: BorderSide(color: Styles().colors.fillColorSecondary , width: 3))), child:
                                    Padding(padding: EdgeInsets.only(left: 10), child:
                                    Row(children: [Expanded(child: Text(buttonTitle, style: Styles().textStyles.getTextStyle('widget.title.dark.large.extra_fat')))]))))),
                            ],),
                          ),
                        ),
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
                          SizedBox(width: 28, height: 28, child:
                            CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
                          ),
                        ),
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }


  void _onTapPlayPause() {
    Analytics().logSelect(target: 'Play/Pause', source: 'HomeRadioWidget');
    RadioPlayer().toggleStationPlayPause(widget.radioStation);
  }


  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (((name == RadioPlayer.notifyCreateStatusChanged) && (param == widget.radioStation)) ||
        ((name == RadioPlayer.notifyPlayerStateChanged) && (param == widget.radioStation))) {
      if (mounted) {
        setState(() {});
      }
    }
  }
} 