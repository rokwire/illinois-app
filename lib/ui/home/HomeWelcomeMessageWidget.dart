import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Video.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Content.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/apphelp/AppHelpVideoTutorialPanel.dart';
import 'package:illinois/ui/home/HomeEmptyFavoritesWidget.dart';
import 'package:illinois/ui/widgets/VideoPlayButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeWelcomeMessageWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeWelcomeMessageWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeWelcomeMessageWidgetState();
}

class _HomeWelcomeMessageWidgetState extends State<HomeWelcomeMessageWidget>  {

  late bool _isVisible;

  @override
  void initState() {
    _isVisible = (Storage().homeWelcomeMessageVisible != false);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Visibility(visible: _isVisible, child:
    Container(color: Styles().colors.fillColorPrimary, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Container(height: 1, color: Styles().colors.disabledTextColor),
        Row(children: [
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 16), child:
              Text(Localization().getStringEx("widget.home.welcome_message.title.text", 'Tailor Your App Experience'),
                style: Styles().textStyles.getTextStyle("widget.title.light.large.extra_fat")
              ),
            ),
          ),
          Semantics(label: Localization().getStringEx('dialog.close.title', 'Close'), button: true, excludeSemantics: true, child:
            InkWell(onTap : _onClose, child:
              Padding(padding: EdgeInsets.all(16), child:
                Styles().images.getImage('close-circle-white', excludeFromSemantics: true)
              ),
            ),
          ),
        ],),
        Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16), child:
        HomeFavoritesInstructionsMessageCard()
        ),
        Container(height: 1, color: Styles().colors.disabledTextColor),
      ],),
    )
  );

  void _onClose() {
    Analytics().logSelect(target: "Close", source: widget.runtimeType.toString());
    setState(() {
      Storage().homeWelcomeMessageVisible = _isVisible = false;
    });
  }
}