import 'dart:async';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/home/HomeEmptyFavoritesWidget.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
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

class _HomeWelcomeMessageWidgetState extends State<HomeWelcomeMessageWidget> implements NotificationsListener {

  late bool _isUserVisible;
  late bool _isFavoritesEmpty;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);

    widget.updateController?.stream.listen((String command) {
      if (command == HomePanel.notifyRefresh) {
        _refresh();
      }
    });

    _isUserVisible = (Storage().homeWelcomeMessageVisible != false);
    _isFavoritesEmpty = _buildIsFavoritesEmpty();
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
    if (name == FlexUI.notifyChanged) {
      _updateIsFavoritesEmpty();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _updateIsFavoritesEmpty();
    }
  }

  bool get _isWidgetVisible => _isUserVisible || _isFavoritesEmpty;
  bool get _isCloseVisible => _isUserVisible;

  @override
  Widget build(BuildContext context) => Visibility(visible: _isWidgetVisible, child:
    Container(color: Styles().colors.fillColorPrimary, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Container(height: 1, color: Styles().colors.textDisabled),
        Row(children: [
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 16, top: 16, bottom: 16), child:
              Text(Localization().getStringEx("widget.home.welcome_message.title.text", 'Tailor Your App Experience'),
                style: Styles().textStyles.getTextStyle("widget.title.light.large.extra_fat")
              ),
            ),
          ),
          Visibility(visible: _isCloseVisible, child:
            Semantics(label: Localization().getStringEx('dialog.close.title', 'Close'), button: true, excludeSemantics: true, child:
              InkWell(onTap : _onClose, child:
                Padding(padding: EdgeInsets.all(16), child:
                  Styles().images.getImage('close-circle-white', excludeFromSemantics: true)
                ),
              ),
            ),
          ),
        ],),
        Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16), child:
          HomeFavoritesInstructionsMessageCard()
        ),
        Container(height: 1, color: Styles().colors.textDisabled),
      ],),
    )
  );

  void _refresh() {
    bool isUserVisible = (Storage().homeWelcomeMessageVisible != false);
    bool isFavoritesEmpty = _buildIsFavoritesEmpty();
    if ((_isUserVisible != isUserVisible) || (_isFavoritesEmpty != isFavoritesEmpty)) {
      setStateIfMounted((){
        _isUserVisible = isUserVisible;
        _isFavoritesEmpty = isFavoritesEmpty;
      });
    }
  }

  bool _buildIsFavoritesEmpty() {
    Set<String> favoriteCodes = Auth2().prefs?.getFavorites(HomeFavorite.favoriteKeyName()) ?? <String>{};
    Set<String> availableCodes = JsonUtils.setStringsValue(FlexUI()['home']) ?? <String>{};
    Set<String> visibleCodes = favoriteCodes.intersection(availableCodes);
    return visibleCodes.isEmpty;
  }

  void _updateIsFavoritesEmpty() {
    bool isFavoritesEmpty = _buildIsFavoritesEmpty();
    if ((_isFavoritesEmpty != isFavoritesEmpty) && mounted) {
      setState((){
        _isFavoritesEmpty = isFavoritesEmpty;
      });
    }
  }

  void _onClose() {
    Analytics().logSelect(target: "Close", source: widget.runtimeType.toString());
    setState(() {
      Storage().homeWelcomeMessageVisible = _isUserVisible = false;
    });
  }
}