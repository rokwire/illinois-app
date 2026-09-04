
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/directory/DirectoryAccountsPage.dart';
import 'package:illinois/ui/profile/ProfileInfoPage.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class DirectoryAccountsPanel extends StatefulWidget {
  DirectoryAccountsPanel({super.key});

  @override
  State<StatefulWidget> createState() => _DirectoryAccountsPanelState();
}

class _DirectoryAccountsPanelState extends State<DirectoryAccountsPanel> with NotificationsListener {

  final GlobalKey<DirectoryAccountsPageState> _pageKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyLoginChanged) {
      setStateIfMounted();
    }
  }

  @override
  Widget build(BuildContext context) =>
    Scaffold(
      appBar: RootHeaderBar(
        title: Localization().getStringEx('panel.profile.info_and_directory.tab.accounts.directory.title', 'Directory of Users'),
        leading: RootHeaderBarLeading.Back,
      ),
      body: _scaffoldContent,
      backgroundColor: Styles().colors.background,
      //bottomNavigationBar: uiuc.TabBar(),
    );

  Widget get _scaffoldContent => Auth2().isOidcLoggedIn ?
    _directoryContent : _signedOutContent;

  Widget get _directoryContent =>
    RefreshIndicator(onRefresh: _onRefresh, child:
      SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), child:
        Padding(padding: _contentPadding, child:
          DirectoryAccountsPage(key: _pageKey, scrollController: _scrollController, onEditProfile: _onEditProfile, onShareProfile: _onShareProfile,)
        )
      )
    );

  Widget get _signedOutContent =>
    Padding(padding: _contentPadding, child:
      DirectoryAccountsSignedOutDescription(onSignIn: _onSignIn),
    );

  EdgeInsets get _contentPadding => EdgeInsets.symmetric(horizontal: 16, vertical: 24);

  void _onEditProfile() {
    ProfileHomePanel.present(context,
      contentType: ProfileContentType.profile,
      contentParams: {
        ProfileInfoPage.editParamKey : true,
      }
    );
  }

  void _onShareProfile() {
    /*ProfileBusinessCardPanel.present(context,
      profile: Auth2().account?.previewProfile(permitted: contentType.profileInfo.permitedVisibility),
    );*/
    ProfileHomePanel.present(context,
      contentType: ProfileContentType.businessCard,
    );
  }

  void _onSignIn() {
    ProfileHomePanel.present(context,
      contentType: ProfileContentType.login,
    );
  }

  Future<void> _onRefresh() async =>
    _pageKey.currentState?.refresh();
}

// DirectoryAccountsEditOrShareDescription

class DirectoryAccountsSignedOutDescription extends StatefulWidget {

  final void Function()? onSignIn;
  final EdgeInsetsGeometry padding;

  DirectoryAccountsSignedOutDescription({ super.key, this.onSignIn, this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16) });

  @override
  State<StatefulWidget> createState() => _DirectoryAccountsSignedOutDescriptionState();
}

class _DirectoryAccountsSignedOutDescriptionState extends State<DirectoryAccountsSignedOutDescription> {
  GestureRecognizer? _signInRecognizer;

  @override
  void initState() {
    _signInRecognizer = TapGestureRecognizer()..onTap = _onTapSignIn;
    super.initState();
  }

  @override
  void dispose() {
    _signInRecognizer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String linkLoginMacro = "{{link.login}}";
    String messageTemplate = Localization().getStringEx('panel.directory.accounts.message.signed_out', 'To view Directory of Users, $linkLoginMacro with your NetID and set your privacy level to 4 or 5 under Settings.');
    List<String> messages = messageTemplate.split(linkLoginMacro);
    List<InlineSpan> spanList = <InlineSpan>[];
    if (0 < messages.length)
      spanList.add(TextSpan(text: messages.first));
    for (int index = 1; index < messages.length; index++) {
      spanList.add(TextSpan(text: Localization().getStringEx('panel.directory.accounts.message.signed_out.link.login', "sign in"), style : Styles().textStyles.getTextStyle("widget.link.button.title.regular"),
        recognizer: _signInRecognizer));
      spanList.add(TextSpan(text: messages[index]));
    }

    return Padding(padding: widget.padding, child:
      RichText(textAlign: TextAlign.left, text:
        TextSpan(style: Styles().textStyles.getTextStyle("widget.message.dark.regular"), children: spanList)
      )
    );
  }

  void _onTapSignIn() {
    Analytics().logSelect(target: "sign in");
    widget.onSignIn?.call();
  }
}
