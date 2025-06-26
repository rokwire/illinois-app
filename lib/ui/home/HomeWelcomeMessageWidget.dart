import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/BrowsePanel.dart';
import 'package:illinois/ui/home/HomeCustomizeFavoritesPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/settings/SettingsHomePanel.dart';
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

  static const String _localScheme = 'local';

  static const String _browseLocalUrlMacro          = '{{browse_local_url}}';
  static const String _browseLocalUrl               = 'browse';

  static const String _customizeFavsLocalUrlMacro   = '{{customize_favorites_local_url}}';
  static const String _customizeFavsLocalUrl        = 'customize_favorites';

  static const String _signInLocalUrlMacro          = '{{sign_in_local_url}}';
  static const String _signInLocalUrl               = 'sign_in';

  static const String _privacySettingsLocalUrlMacro = '{{privacy_settings_local_url}}';
  static const String _privacySettingsLocalUrl      = 'privacy_settings';

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
      Container(padding: EdgeInsets.only(left: 12, bottom: 12), decoration: HomeMessageCard.defaultDecoration, child:
        Column(children: [
          Row(children: [
            Expanded(child:
              Padding(padding: EdgeInsets.only(right: 16, top: 12, bottom: 12), child:
                Text(Localization().getStringEx("widget.home.welcome.title.text", 'Tailor Your App Experience').toUpperCase(),
                  style: Styles().textStyles.getTextStyle("widget.title.regular.fat")
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
            HtmlWidget(_messageHtml,
              onTapUrl : (url) { _handleLinkTap(context, url, analyticsSource: widget.runtimeType.toString()); return true; },
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

  String get _messageHtml => Localization().getStringEx("widget.home.favorites.instructions.message.text", "Tap the \u2606s in <a href='$_browseLocalUrlMacro'>Sections</a> or <a href='$_customizeFavsLocalUrlMacro'>Customize</a> to add shortcuts to Favorites. Note that some features require specific <a href='$_privacySettingsLocalUrlMacro'>privacy settings</a> and <a href='$_signInLocalUrlMacro'>signing in</a> with your NetID, phone number, or email address.")
    .replaceAll(_browseLocalUrlMacro, '$_localScheme://$_browseLocalUrl')
    .replaceAll(_customizeFavsLocalUrlMacro, '$_localScheme://$_customizeFavsLocalUrl')
    .replaceAll(_signInLocalUrlMacro, '$_localScheme://$_signInLocalUrl')
    .replaceAll(_privacySettingsLocalUrlMacro, '$_localScheme://$_privacySettingsLocalUrl');

  void _handleLinkTap(BuildContext context, String? url, {String? analyticsSource}) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if (uri?.scheme == _localScheme) {
      if (uri?.host == _browseLocalUrl) {
        Analytics().logSelect(target: 'Sections', source: analyticsSource);
        NotificationService().notify(BrowsePanel.notifySelect);
      }
      if (uri?.host == _customizeFavsLocalUrl) {
        Analytics().logSelect(target: 'Customize', source: analyticsSource);
        HomeCustomizeFavoritesPanel.present(context);
      }
      else if (uri?.host == _signInLocalUrl) {
        Analytics().logSelect(target: 'Sign In', source: analyticsSource);
        ProfileHomePanel.present(context, contentType: ProfileContentType.login);
      }
      else if (uri?.host == _privacySettingsLocalUrl) {
        Analytics().logSelect(target: 'Privacy Settings', source: analyticsSource);
        SettingsHomePanel.present(context, content: SettingsContentType.privacy);
      }
    }
  }

}