
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/BrowsePanel.dart';
import 'package:illinois/ui/home/HomeCustomizeFavoritesPanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/settings/SettingsHomePanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';

class HomeEmptyFavoritesWidget extends StatelessWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeEmptyFavoritesWidget({ super.key, this.favoriteId, this.updateController});

  @override
  Widget build(BuildContext context) =>
    HomeSlantWidget(favoriteId: null /*widget.favoriteId*/,
      title: Localization().getStringEx("panel.home.header.favorites.title", "Favorites"),
      childPadding: HomeSlantWidget.defaultChildPadding,
      child: Column(children: <Widget>[
        HomeFavoritesInstructionsMessageCard()
      ],),
    );
}

class HomeFavoritesInstructionsMessageCard extends StatelessWidget {

  static const String _localScheme = 'local';

  static const String _browseLocalUrlMacro          = '{{browse_local_url}}';
  static const String _browseLocalUrl               = 'browse';

  static const String _customizeFavsLocalUrlMacro   = '{{customize_favorites_local_url}}';
  static const String _customizeFavsLocalUrl        = 'customize_favorites';

  static const String _signInLocalUrlMacro          = '{{sign_in_local_url}}';
  static const String _signInLocalUrl               = 'sign_in';

  static const String _privacySettingsLocalUrlMacro = '{{privacy_settings_local_url}}';
  static const String _privacySettingsLocalUrl      = 'privacy_settings';

  @override
  Widget build(BuildContext context) =>
    HomeMessageHtmlCard(
      message: Localization().getStringEx("widget.home.favorites.instructions.message.text", "Tap the \u2606s in <a href='$_browseLocalUrlMacro'>Sections</a> or <a href='$_customizeFavsLocalUrlMacro'>Customize</a> to add shortcuts to Favorites. Note that some features require specific <a href='$_privacySettingsLocalUrlMacro'>privacy settings</a> and <a href='$_signInLocalUrlMacro'>signing in</a> with your NetID, phone number, or email address.")
        .replaceAll(_browseLocalUrlMacro, '$_localScheme://$_browseLocalUrl')
        .replaceAll(_customizeFavsLocalUrlMacro, '$_localScheme://$_customizeFavsLocalUrl')
        .replaceAll(_signInLocalUrlMacro, '$_localScheme://$_signInLocalUrl')
        .replaceAll(_privacySettingsLocalUrlMacro, '$_localScheme://$_privacySettingsLocalUrl'),
      margin: EdgeInsets.only(bottom: 16),
      onTapLink : (url) => _onTapLink(context, url),
    );

  void _onTapLink(BuildContext context, String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if (uri?.scheme == _localScheme) {
      if (uri?.host == _browseLocalUrl) {
        Analytics().logSelect(target: 'Sections', source: runtimeType.toString());
        NotificationService().notify(BrowsePanel.notifySelect);
      }
      if (uri?.host == _customizeFavsLocalUrl) {
        Analytics().logSelect(target: 'Customize', source: runtimeType.toString());
        HomeCustomizeFavoritesPanel.present(context);
      }
      else if (uri?.host == _signInLocalUrl) {
        Analytics().logSelect(target: 'Sign In', source: runtimeType.toString());
        ProfileHomePanel.present(context, contentType: ProfileContentType.login);
      }
      else if (uri?.host == _privacySettingsLocalUrl) {
        Analytics().logSelect(target: 'Privacy Settings', source: runtimeType.toString());
        SettingsHomePanel.present(context, content: SettingsContentType.privacy);
      }
    }
  }
}
