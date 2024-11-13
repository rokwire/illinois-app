
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class ProfileConnectionsPage extends StatefulWidget {
  static const String notifySignIn = "edu.illinois.rokwire.profile.sign_in";

  ProfileConnectionsPage({super.key});

  @override
  _ProfileConnectionsPageState createState() => _ProfileConnectionsPageState();
}

class _ProfileConnectionsPageState extends State<ProfileConnectionsPage> implements NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
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
    Container();

  Widget get _loggedOutContent {
    final String appTitleMacro = "{{app_title}}";
    final String linkLoginMacro = "{{link.login}}";
    String messageTemplate = Localization().getStringEx('panel.profile.connections.message.signed_out', 'To view "My Info & $appTitleMacro Connections", $linkLoginMacro with your NetID and set your privacy level to 4 or 5 under Settings.').replaceAll(appTitleMacro, Localization().getStringEx('app.title', 'Illinois'));
    List<String> messages = messageTemplate.split(linkLoginMacro);
    List<InlineSpan> spanList = <InlineSpan>[];
    if (0 < messages.length)
      spanList.add(TextSpan(text: messages.first));
    for (int index = 1; index < messages.length; index++) {
      spanList.add(TextSpan(text: Localization().getStringEx('panel.profile.connections.message.signed_out.link.login', "sign in"), style : Styles().textStyles.getTextStyle("widget.link.button.title.regular"),
        recognizer: TapGestureRecognizer()..onTap = _onTapSignIn, ));
      spanList.add(TextSpan(text: messages[index]));
    }

    return Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), child:
      RichText(textAlign: TextAlign.left, text:
        TextSpan(style: Styles().textStyles.getTextStyle("widget.message.dark.regular"), children: spanList)
      )
    );
  }

  void _onTapSignIn() => NotificationService().notify(ProfileConnectionsPage.notifySignIn);

}