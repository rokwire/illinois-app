
import 'package:flutter/material.dart';
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