import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

//TBD LOCALIZE
class HomeWPGUFMRadioWidget extends StatefulWidget {
  HomeWPGUFMRadioWidget();

  @override
  State<HomeWPGUFMRadioWidget> createState() => _HomeWPGUFMRadioWidgetState();
}

class _HomeWPGUFMRadioWidgetState extends State<HomeWPGUFMRadioWidget> implements NotificationsListener {
  late String _radioUrl;
  bool _playing = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      //TBD remove if none
    ]);

    _radioUrl = "https://ice64.securenetsystems.net/WPGUFM "; //TBD load from Config
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(StringUtils.isEmpty(_radioUrl)){
      return Container();
    }
    String buttonTitle = _playing ? Localization().getStringEx('widget.home.radio.button.stop.title', 'Stop') :  Localization().getStringEx('widget.home.radio.button.play.title', 'Play');

    return GestureDetector(onTap: _onTap, child:
    Container(
      margin: EdgeInsets.only(left: 16, right: 16, bottom: 20),
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3),
            spreadRadius: 2.0,
            blurRadius: 8.0,
            offset: Offset(0, 2))
      ]),
      child:
      ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
      Row(children: <Widget>[
        Expanded(child:
        Column(children: <Widget>[
          Container(color: Styles().colors!.fillColorPrimary, child:
          Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(Localization().getStringEx(
                'widget.home.radio.title', 'WPGUFM Radio'),
                style: TextStyle(color: Styles().colors!.white,
                    fontFamily: Styles().fontFamilies!.extraBold,
                    fontSize: 20))),
          ])
          ),
          ),
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
                          Row(children: [Expanded(child: Text(buttonTitle, style: TextStyle(fontFamily: Styles().fontFamilies?.extraBold, fontSize: 24, color: Styles().colors?.fillColorPrimary)))]))))),
                  ],),
                ),
              ),
            ),
            Semantics(button: true,
                excludeSemantics: true,
                label: buttonTitle,
                hint: Localization().getStringEx(
                    'widget.home.radio.button.add_radio.hint', ''),
                child:
                IconButton(color: Styles().colors!.fillColorPrimary,
                    icon: _playing ?
                      Image.asset('images/button-plus-orange.png', excludeFromSemantics: true) : //TBD update Image
                      Image.asset('images/button-plus-orange.png', excludeFromSemantics: true) ,
                    onPressed: _onTap)
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

  void _onTap() {
    Analytics().logSelect(target: 'Play/Pause');
    if(mounted){
      setState(() {
        _playing = !_playing;
      });
    }

  }

  /* Commented out because of warning for not used code
  void _applyState(){
    if(_playing){
      //TBD implement play stream
    } else {
      //TBD STOP
    }
  }*/
  
  // NotificationsListener

  void onNotification(String name, dynamic param) {
    //TBD remove if none
    // if (name == Radio.notifyBallanceUpdated) {
    //   if (mounted) {
    //     setState(() {});
    //   }
    // }
  }
} 