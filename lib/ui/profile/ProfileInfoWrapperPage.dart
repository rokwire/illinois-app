
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/ui/profile/ProfileInfoPage.dart';
import 'package:neom/ui/settings/SettingsPrivacyPanel.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileInfoWrapperPage extends StatefulWidget {
  static const String notifySignIn = "edu.illinois.rokwire.profile.sign_in";

  final Map<String, dynamic>? params;

  ProfileInfoWrapperPage({super.key, this.params});

  @override
  ProfileInfoWrapperPageState createState() => ProfileInfoWrapperPageState();
}

class ProfileInfoWrapperPageState extends State<ProfileInfoWrapperPage> implements NotificationsListener {

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
  Widget build(BuildContext context) {
    if (!Auth2().isLoggedIn) {
      return _loggedOutContent;
    }
    else {
      return _pageContent;
    }
  }

  Widget get _pageContent =>
    Column(children: [ _myInfoTabPage ],);

  // My Info

  Widget get _myInfoTabPage =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
      Column(children: [
        ProfileInfoPage(
          key: _profileInfoKey,
          contentType: ProfileInfo.directoryInfo,
          params: widget.params,
        )
      ],),
    );

  // Signed out

  Widget get _loggedOutContent {
    final String linkLoginMacro = "{{link.login}}";
    final String linkPrivacyMacro = "{{link.privacy}}";
    String messageTemplate = Localization().getStringEx('panel.profile.info_and_directory.message.signed_out', 'To view "My Info & User Directory", $linkLoginMacro with your NetID and set your privacy level to 4 or 5.');
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

  void _onTapSignIn() {
    Analytics().logSelect(target: 'sign in');
    NotificationService().notify(ProfileInfoWrapperPage.notifySignIn);
  }

  void _onTapProfile() {
    Analytics().logSelect(target: 'Privacy Level');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,)));
  }
}

