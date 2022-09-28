import 'dart:async';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class HomeWelcomeWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeWelcomeWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: Localization().getStringEx("widget.home_create_poll.heading.title", "Polls"),
    );

  @override
  State<HomeWelcomeWidget> createState() => _HomeWelcomeWidgetState();
}

class _HomeWelcomeWidgetState extends State<HomeWelcomeWidget> {
  bool? _visible;

  @override
  void initState() {
    super.initState();
    _visible = Storage().homeWelcomeVisible;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(visible: _visible ?? true, child:
      Container(color: Styles().colors?.fillColorPrimary, child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Container(height: 1, color: Styles().colors?.disabledTextColor),
          Row(children: [
            Expanded(child:
              Padding(padding: EdgeInsets.only(left: 16), child:
                Text(Localization().getStringEx("widget.home.welcome.text.title", 'Welcome to {{app_title}} {{app_version}}').
                  replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')).
                  replaceAll('{{app_version}}', Config().appMasterVersion ?? ''),
                  style: TextStyle(color: Styles().colors!.textColorPrimary, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20, ),),
              ),
            ),
            Semantics(label: Localization().getStringEx('widget.home.welcome.button.close.label', 'Close'), button: true, excludeSemantics: true, child:
              InkWell(onTap : _onClose, child:
                Padding(padding: EdgeInsets.all(16), child:
                  Image.asset('images/close-white.png')
                ),
              ),
            ),
          ],),
          Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16), child: 
            Text(Localization().getStringEx('widget.home.welcome.text.description', "New in this version: personalize the {{app_title}} app content you want front and center in Favorites. Change or reorder your favorites by tapping on Customize, or add or remove content by tapping \u2606.").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')),
              style: TextStyle(color: Styles().colors!.textColorPrimary, fontFamily: Styles().fontFamilies!.medium, fontSize: 16)),
          ),
          Container(height: 1, color: Styles().colors?.disabledTextColor),
        ],),
      )
    );
  }

  void _onClose() {
    Analytics().logSelect(target: "Close", source: widget.runtimeType.toString());
    setState(() {
      Storage().homeWelcomeVisible = _visible = false;
    });
  }
}
