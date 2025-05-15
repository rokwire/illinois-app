
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/profile/ProfileInfoPage.dart';
import 'package:illinois/ui/profile/ProfileInfoSharePanel.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum ProfileInfoWrapperContent { info, share }

class ProfileInfoWrapperPage extends StatefulWidget {

  final ProfileInfoWrapperContent content;
  final Map<String, dynamic>? _contentParams;

  ProfileInfoWrapperPage(this.content, {super.key, Map<String, dynamic>? contentParams}) :
    _contentParams = contentParams;

  Map<String, dynamic>? contentParams(ProfileInfoWrapperContent? contentType) =>
    (content == contentType) ? _contentParams : null;

  @override
  ProfileInfoWrapperPageState createState() => ProfileInfoWrapperPageState();
}

class ProfileInfoWrapperPageState extends State<ProfileInfoWrapperPage> with NotificationsListener {

  GestureRecognizer? _signInRecognizer;
  GestureRecognizer? _privacyRecognizer;
  final GlobalKey<ProfileInfoPageState> _profileInfoKey = GlobalKey();

  Future<bool?> saveModified() async => _profileInfoKey.currentState?.saveModified();

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
    ]);
    _signInRecognizer = TapGestureRecognizer()..onTap = _onTapSignIn;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _onTapProfile;

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _signInRecognizer?.dispose();
    _privacyRecognizer?.dispose();
    super.dispose();
  }

  @override
  void onNotification(String name, param) {
    if (name == Auth2.notifyLoginChanged) {
      setStateIfMounted();
    }
  }

  @override
  Widget build(BuildContext context) =>
    (Auth2().isLoggedIn) ? _loggedInContent : _loggedOutContent;

  Widget get _loggedInContent => Column(children: [
    Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
      Column(children: [
        _pageWidget,
      ],),
    )
  ],);

  Widget get _pageWidget {
    switch(widget.content) {
      case ProfileInfoWrapperContent.info: return ProfileInfoPage(
        key: _profileInfoKey,
        params: widget.contentParams(ProfileInfoWrapperContent.info),
      );

      case ProfileInfoWrapperContent.share: return ProfileInfoSharePage(
        params: widget.contentParams(ProfileInfoWrapperContent.share)
      );
    }
  }

  // Signed out

  Widget get _loggedOutContent {
    final String featureMacro = "{{feature}}";
    final String linkLoginMacro = "{{link.login}}";
    final String linkPrivacyMacro = "{{link.privacy}}";

    String messageTemplate = Localization().getStringEx('panel.profile.info_and_directory.message.signed_out', 'To view $featureMacro, $linkLoginMacro with your NetID and set your privacy level to 4 or 5.').
      replaceAll(featureMacro, featureName);

    List<InlineSpan> spanList = StringUtils.split<InlineSpan>(messageTemplate, macros: [linkLoginMacro, linkPrivacyMacro], builder: (String entry) {
      if (entry == linkLoginMacro) {
        return TextSpan(
          text: Localization().getStringEx('panel.profile.info_and_directory.message.signed_out.link.login', "sign in"),
          style : Styles().textStyles.getTextStyle("widget.link.button.title.regular"),
          recognizer: _signInRecognizer,
        );
      }
      else if (entry == linkPrivacyMacro) {
        return TextSpan(
          text: Localization().getStringEx('panel.profile.info_and_directory.message.signed_out.link.privacy', "set your privacy level"),
          style : Styles().textStyles.getTextStyle("widget.link.button.title.regular"),
          recognizer: _privacyRecognizer,
        );
      }
      else {
        return TextSpan(text: entry);
      }
    });

    return Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), child:
      RichText(textAlign: TextAlign.left, text:
        TextSpan(style: Styles().textStyles.getTextStyle("widget.message.dark.regular"), children: spanList)
      )
    );
  }

  String get featureName {
    switch(widget.content) {
      case ProfileInfoWrapperContent.info: return Localization().getStringEx('panel.profile.info_and_directory.message.signed_out.feature.info', 'your profile');
      case ProfileInfoWrapperContent.share: return Localization().getStringEx('panel.profile.info_and_directory.message.signed_out.feature.share', 'your Digital Business Card');
    }
  }

  void _onTapSignIn() {
    Analytics().logSelect(target: 'sign in');
    NotificationService().notify(ProfileHomePanel.notifySelectContent, ProfileContentType.login);
  }

  void _onTapProfile() {
    Analytics().logSelect(target: 'Privacy Level');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,)));
  }
}

