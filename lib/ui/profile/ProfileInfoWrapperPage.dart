
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/profile/ProfileInfoPage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class ProfileInfoWrapperPage extends StatefulWidget {
  static const String notifySignIn = "edu.illinois.rokwire.profile.sign_in";

  final Map<String, dynamic>? params;

  ProfileInfoWrapperPage({super.key, this.params});

  @override
  ProfileInfoWrapperPageState createState() => ProfileInfoWrapperPageState();
}

class ProfileInfoWrapperPageState extends State<ProfileInfoWrapperPage> implements NotificationsListener {

  GestureRecognizer? _signInRecognizer;
  final GlobalKey<ProfileInfoPageState> _profileInfoKey = GlobalKey();

  Future<void> saveModified() async => _profileInfoKey.currentState?.saveModified();

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
    ]);
    _signInRecognizer = TapGestureRecognizer()..onTap = _onTapSignIn;

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _signInRecognizer?.dispose();
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
    String messageTemplate = Localization().getStringEx('panel.profile.info_and_directory.message.signed_out', 'To view "My Info & User Directory", $linkLoginMacro with your NetID and set your privacy level to 4 or 5 under Settings.');
    List<String> messages = messageTemplate.split(linkLoginMacro);
    List<InlineSpan> spanList = <InlineSpan>[];
    if (0 < messages.length)
      spanList.add(TextSpan(text: messages.first));
    for (int index = 1; index < messages.length; index++) {
      spanList.add(TextSpan(text: Localization().getStringEx('panel.profile.info_and_directory.message.signed_out.link.login', "sign in"), style : Styles().textStyles.getTextStyle("widget.link.button.title.regular"),
        recognizer: _signInRecognizer, ));
      spanList.add(TextSpan(text: messages[index]));
    }

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
}

