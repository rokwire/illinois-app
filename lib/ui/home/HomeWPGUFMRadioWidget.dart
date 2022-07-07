import 'dart:async';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/WPGUFMRadio.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeWPGUFMRadioWidget extends StatelessWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeWPGUFMRadioWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.radio.title', 'WPGU FM Radio');

  @override
  Widget build(BuildContext context) {
    return Visibility(visible: _isEnabled, child:
        HomeSlantWidget(favoriteId: favoriteId,
          title: Localization().getStringEx('widget.home.radio.title', 'WPGU FM Radio'),
          titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
          childPadding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 32),
          child: _WPGUFMRadioControl(borderRadius: BorderRadius.all(Radius.circular(6)),),
        ),
    );
  }

  bool get _isEnabled => StringUtils.isNotEmpty(Config().wpgufmRadioUrl);

  static void showPopup(BuildContext context) {
    showDialog(context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _buildPopup(context);
      },
    );
  }

  static Widget _buildPopup(BuildContext context) {
    return ClipRRect(borderRadius: BorderRadius.all(Radius.circular(8)), child:
      Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),), child:
        Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Container(color: Styles().colors!.fillColorPrimary, child:
            Row(children: <Widget>[
              Expanded(child:
                Padding(padding: EdgeInsets.all(8), child:
                  Center(child:
                    Text(Localization().getStringEx('widget.home.radio.title', 'WPGU FM Radio'), style: TextStyle(fontSize: 20, color: Colors.white),),
                  ),
                ),
              ),
              Semantics( label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), button: true, child:
                InkWell(onTap : () => _onClosePopup(context), child:
                  Padding(padding: EdgeInsets.all(16), child: 
                    Image.asset('images/close-white.png', semanticLabel: '',),
                  ),
                ),
              ),
            ],),
          ),
          _WPGUFMRadioControl(borderRadius: BorderRadius.vertical(bottom: Radius.circular(6))),
        ],),
      ),
    );
  }

  static void _onClosePopup(BuildContext context) {
    Analytics().logSelect(target: 'Close');
    Navigator.of(context).pop();
  }
}

class _WPGUFMRadioControl extends StatefulWidget {

  final BorderRadius borderRadius;

  const _WPGUFMRadioControl({Key? key, required this.borderRadius}) : super(key: key);

  @override
  State<_WPGUFMRadioControl> createState() => _WPGUFMRadioControlState();
}

class _WPGUFMRadioControlState extends State<_WPGUFMRadioControl> implements NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [
      WPGUFMRadio.notifyInitializeStatusChanged,
      WPGUFMRadio.notifyPlayerStateChanged,
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
    return Visibility(visible: WPGUFMRadio().isEnabled, child:
      _buildContentCard(),
    );
  }

  Widget _buildContentCard() {
    String? buttonTitle, iconAsset;
    if (WPGUFMRadio().isInitialized) {
      buttonTitle = WPGUFMRadio().isPlaying ? Localization().getStringEx('widget.home.radio.button.pause.title', 'Pause') :  Localization().getStringEx('widget.home.radio.button.play.title', 'Play');
      iconAsset = WPGUFMRadio().isPlaying ? 'images/button-pause-orange.png' : 'images/button-play-orange.png';
    }
    else if (WPGUFMRadio().isInitializing) {
      buttonTitle = Localization().getStringEx('widget.home.radio.button.initalize.title', 'Initializing');
    }
    else if (!WPGUFMRadio().isEnabled) {
      buttonTitle = Localization().getStringEx('widget.home.radio.button.fail.title', 'Not Available');
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
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.only(top: 8, right: 8, bottom: 8), child:
                    Row(children: <Widget>[
                      Expanded(child:
                        Container(color: Styles().colors!.white, child:
                          Padding(padding: EdgeInsets.only(top: 8, right: 8, bottom: 8), child:
                            Row(children: <Widget>[
                              Expanded(child:
                                Padding(padding: EdgeInsets.all(16), child:
                                  Container(decoration: BoxDecoration(border: Border(left: BorderSide(color: Styles().colors!.fillColorSecondary! , width: 3))), child:
                                    Padding(padding: EdgeInsets.only(left: 10), child:
                                    Row(children: [Expanded(child: Text(buttonTitle ?? '', style: TextStyle(fontFamily: Styles().fontFamilies?.extraBold, fontSize: 24, color: Styles().colors?.fillColorPrimary)))]))))),
                            ],),
                          ),
                        ),
                      ),
                      (iconAsset != null) ? Semantics(button: true,
                          excludeSemantics: true,
                          label: buttonTitle,
                          hint: Localization().getStringEx('widget.home.radio.button.add_radio.hint', ''),
                          child:  IconButton(color: Styles().colors!.fillColorPrimary,
                            icon: Image.asset(iconAsset, excludeFromSemantics: true),
                            onPressed: _onTapPlayPause)
                      ) : Container(),
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
    Analytics().logSelect(target: 'Play/Pause');
    WPGUFMRadio().togglePlayPause();
  }


  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if ((name == WPGUFMRadio.notifyInitializeStatusChanged) ||
        (name == WPGUFMRadio.notifyPlayerStateChanged)) {
      if (mounted) {
        setState(() {});
      }
    }
  }
} 