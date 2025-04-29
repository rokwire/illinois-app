
import 'package:flutter/material.dart';
import 'package:illinois/ui/directory/DirectoryAccountsList.dart';
import 'package:illinois/ui/directory/DirectoryAccountsPage.dart';
import 'package:illinois/ui/profile/ProfileInfoPage.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class DirectoryAccountsPanel extends StatefulWidget {
  final DirectoryAccounts contentType;
  DirectoryAccountsPanel(this.contentType, {super.key});

  @override
  State<StatefulWidget> createState() => _DirectoryAccountsPanelState();

  static const List<String> defaultAlphabet = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"];
}

class _DirectoryAccountsPanelState extends State<DirectoryAccountsPanel> {

  final GlobalKey<DirectoryAccountsPageState> _pageKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  int _letterIndex = 0;
  bool _listRefreshEnabled = true;

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
    Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Container(
            height: 48.0,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12.0),
                itemCount: _alphabet.length,
                itemBuilder: (BuildContext context, int index) {
                  bool isSelected = _letterIndex == index;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    child: Text(_alphabet[index].toUpperCase(), style: Styles().textStyles.getTextStyle(isSelected ? 'widget.button.title.medium.fat' : 'widget.button.title.medium'), textAlign: TextAlign.center,),
                    onTap: () => _onTapIndexLetter(index),
                  );
                },
                separatorBuilder: (BuildContext context, int index) => SizedBox(width: 6),
              )
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            notificationPredicate: _listRefreshEnabled ? (_) => true : (_) => false,
            child: SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), child:
              Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 24), child:
                DirectoryAccountsPage(
                  widget.contentType,
                  key: _pageKey,
                  scrollController: _scrollController,
                  letterIndex: _letterIndex,
                  onEditProfile: _onEditProfile,
                  onShareProfile: _onShareProfile,
                  onUpdateLetterIndex: _onTapIndexLetter,
                  onUpdateRefreshEnabled: _onUpdateRefreshEnabled,
                  onUpdateAlphabet: _onUpdateAlphabet,
                ),
              )
            ),
          ),
        ),
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
    /*ProfileInfoShareSheet.present(context,
      profile: Auth2().account?.previewProfile(permitted: contentType.profileInfo.permitedVisibility),
    );*/
    ProfileHomePanel.present(context,
      content: ProfileContent.share,
    );
  }

  void _onUpdateRefreshEnabled(bool enabled) {
    setStateIfMounted(() {
      _listRefreshEnabled = enabled;
    });
  }

  void _onUpdateAlphabet() {
    setStateIfMounted(() {});
  }

  void _onTapIndexLetter(int index) {
    setState(() {
      _letterIndex = index;
    });
  }

  Future<void> _onRefresh() async =>
    _pageKey.currentState?.refresh();

  List<String> get _alphabet => _pageKey.currentState?.alphabet ?? DirectoryAccountsPanel.defaultAlphabet;
}