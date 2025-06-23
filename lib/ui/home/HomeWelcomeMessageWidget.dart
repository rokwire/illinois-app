import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/home/HomeEmptyFavoritesWidget.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
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

class _HomeWelcomeMessageWidgetState extends State<HomeWelcomeMessageWidget> with NotificationsListener {

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
    Padding(padding: EdgeInsets.all(16), child:
      Container(padding: EdgeInsets.only(left: 12, bottom: 12), decoration: HomeMessageCard.decoration, child:
        Column(children: [
          Row(children: [
            Expanded(child:
              Padding(padding: EdgeInsets.only(right: 16, top: 12, bottom: 12), child:
                Text(Localization().getStringEx("widget.home.welcome.title.text", 'Tailor Your App Experience'),
                  style: Styles().textStyles.getTextStyle("widget.title.medium.extra_fat")
                ),
              ),
            ),
            Visibility(visible: _isCloseVisible, child:
              Semantics(label: Localization().getStringEx('dialog.close.title', 'Close'), button: true, excludeSemantics: true, child:
                InkWell(onTap : _onClose, child:
                  Padding(padding: EdgeInsets.all(12), child:
                    Styles().images.getImage('close-circle-small', excludeFromSemantics: true)
                  ),
                ),
              ),
            ),
          ],),

          Padding(padding: EdgeInsets.only(right: 12), child:
            HtmlWidget(HomeFavoritesInstructionsMessageCard.messageHtml,
              onTapUrl : (url) { HomeFavoritesInstructionsMessageCard.handleLinkTap(context, url, analyticsSource: widget.runtimeType.toString()); return true; },
              textStyle:  Styles().textStyles.getTextStyle("widget.description.small.semi_fat"),
              customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null
            ),
          ),
        ],),
      )
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