
import 'package:flutter/material.dart';
import 'package:illinois/ui/profile/ProfileDirectoryAccountsPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryMyInfoPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryPage.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
//import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class ProfileDirectoryAccountsPanel extends StatefulWidget {
  final DirectoryAccounts contentType;
  ProfileDirectoryAccountsPanel(this.contentType, {super.key});

  @override
  State<StatefulWidget> createState() => _ProfileDirectoryAccountsPanelState();
}

class _ProfileDirectoryAccountsPanelState extends State<ProfileDirectoryAccountsPanel> {

  final GlobalKey<ProfileDirectoryAccountsPageState> _pageKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) =>
    Scaffold(
      appBar: RootHeaderBar(title: _appTitle, leading: RootHeaderBarLeading.Back,),
      body: _scaffoldContent,
      backgroundColor: Styles().colors.background,
      //bottomNavigationBar: uiuc.TabBar(),
    );

  String get _appTitle {
    switch(widget.contentType) {
      case DirectoryAccounts.myConnections: return Localization().getStringEx('panel.profile.directory.tab.accounts.connections.title', 'My Connections');
      case DirectoryAccounts.appDirectory: return Localization().getStringEx('panel.profile.directory.tab.accounts.directory.title', 'User Directory');
    }
  }

  Widget get _scaffoldContent =>
    RefreshIndicator(onRefresh: _onRefresh, child:
      SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
          ProfileDirectoryAccountsPage(widget.contentType, key: _pageKey, scrollController: _scrollController, onEditProfile: _onEditProfile,),
        )
      )
    );

  void _onEditProfile(DirectoryAccounts contentType) {
    ProfileHomePanel.present(context,
      content: ProfileContent.directory,
      contentParams: {
        ProfileDirectoryPage.tabParamKey: ProfileDirectoryTab.myInfo,
        ProfileDirectoryMyInfoPage.editParamKey : true,
      }
    );
  }

  Future<void> _onRefresh() async =>
    _pageKey.currentState?.refresh();
}