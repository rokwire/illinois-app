
import 'package:flutter/material.dart';
import 'package:illinois/ext/Auth2.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/directory/DirectoryAccountsList.dart';
import 'package:illinois/ui/directory/DirectoryAccountsPage.dart';
import 'package:illinois/ui/profile/ProfileInfoPage.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/profile/ProfileInfoSharePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class DirectoryAccountsPanel extends StatefulWidget {
  final DirectoryAccounts contentType;
  DirectoryAccountsPanel(this.contentType, {super.key});

  @override
  State<StatefulWidget> createState() => _DirectoryAccountsPanelState();
}

class _DirectoryAccountsPanelState extends State<DirectoryAccountsPanel> {

  final GlobalKey<DirectoryAccountsPageState> _pageKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  static const List<String> alphabet = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "#"];

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
      case DirectoryAccounts.connections: return Localization().getStringEx('panel.profile.info_and_directory.tab.accounts.connections.title', 'My Connections');
      case DirectoryAccounts.directory: return Localization().getStringEx('panel.profile.info_and_directory.tab.accounts.directory.title', 'User Directory');
    }
  }

  Widget get _scaffoldContent =>
    Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          flex: 10,
          child: RefreshIndicator(onRefresh: _onRefresh, child:
            SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), child:
              Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
                DirectoryAccountsPage(widget.contentType, key: _pageKey, scrollController: _scrollController, onEditProfile: _onEditProfile, onShareProfile: _onShareProfile,),
              )
            ),
          )
        ),
        Flexible(
          flex: 1,
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alphabet.length,
            itemBuilder: (BuildContext context, int index) => Text(alphabet[index], style: Styles().textStyles.getTextStyle('widget.button.title.tiny'), textAlign: TextAlign.center,),
            separatorBuilder: (BuildContext context, int index) => SizedBox(height: 4),
          ),
        )
      ]
    );

  void _onEditProfile(DirectoryAccounts contentType) {
    ProfileHomePanel.present(context,
      content: ProfileContent.profile,
      contentParams: {
        ProfileInfoPage.editParamKey : true,
      }
    );
  }

  void _onShareProfile(DirectoryAccounts contentType) {
    ProfileInfoSharePanel.present(context,
      profile: Auth2().account?.previewProfile(permitted: contentType.profileInfo.permitedVisibility),
    );
  }

  Future<void> _onRefresh() async =>
    _pageKey.currentState?.refresh();
}