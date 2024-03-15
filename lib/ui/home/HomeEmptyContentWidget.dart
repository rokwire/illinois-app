
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/BrowsePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';

class HomeEmptyContentWidget extends StatelessWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  static const String _localScheme = 'local';

  static const String _browseLocalUrlMacro          = '{{browse_local_url}}';
  static const String _browseLocalUrl               = 'browse';

  static const String _signInLocalUrlMacro          = '{{sign_in_local_url}}';
  static const String _signInLocalUrl               = 'sign_in';

  static const String _privacySettingsLocalUrlMacro = '{{privacy_settings_local_url}}';
  static const String _privacySettingsLocalUrl      = 'privacy_settings';

  HomeEmptyContentWidget({ super.key, this.favoriteId, this.updateController});

  @override
  Widget build(BuildContext context) {
    String htmlContent = Localization().getStringEx("widget.home.empty.content.text", "Tap the \u2606s under <a href='$_browseLocalUrlMacro'>Browse</a> to add shortcuts to Favorites. Note that some features require specific <a href='$_privacySettingsLocalUrlMacro'>privacy settings</a> and <a href='$_signInLocalUrlMacro'>signing in</a> with your NetID, phone number, or email address.")
        .replaceAll(_browseLocalUrlMacro, '$_localScheme://$_browseLocalUrl')
        .replaceAll(_signInLocalUrlMacro, '$_localScheme://$_signInLocalUrl')
        .replaceAll(_privacySettingsLocalUrlMacro, '$_localScheme://$_privacySettingsLocalUrl');

    return HomeSlantWidget(favoriteId: null /*widget.favoriteId*/,
      title: Localization().getStringEx("panel.home.header.title", "Favorites"),
      childPadding: HomeSlantWidget.defaultChildPadding,
      child: Column(children: <Widget>[
        HomeMessageHtmlCard(
          message: htmlContent,
          margin: EdgeInsets.only(bottom: 16),
          onTapLink : (url) => _onTapLink(context, url),
        )
      ],),
    );
  }

  void _onTapLink(BuildContext context, String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if (uri?.scheme == _localScheme) {
      if (uri?.host == _browseLocalUrl) {
        Analytics().logSelect(target: 'Browse', source: runtimeType.toString());
        NotificationService().notify(BrowsePanel.notifySelect);
      }
      else if (uri?.host == _signInLocalUrl) {
        Analytics().logSelect(target: 'Sign In', source: runtimeType.toString());
        ProfileHomePanel.present(context, content: ProfileContent.login);
      }
      else if (uri?.host == _privacySettingsLocalUrl) {
        Analytics().logSelect(target: 'Privacy Settings', source: runtimeType.toString());
        SettingsHomeContentPanel.present(context, content: SettingsContent.privacy);
      }
    }
  }
}


