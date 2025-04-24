
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

  static const List<String> alphabet = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "#"];
  //TODO: make not static to filter alphabet based on counts map returned with accounts list (when filters are applied)
}

class _DirectoryAccountsPanelState extends State<DirectoryAccountsPanel> {

  final GlobalKey<DirectoryAccountsPageState> _pageKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController(viewportFraction: 1, initialPage: 0, keepPage: true);
  final _selectedIndexNotifier = ValueNotifier<int>(0);
  // final _positionNotifier = ValueNotifier<Offset>(const Offset(0, 0));
  int _lastSelectedLetterIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
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
              child: ValueListenableBuilder<int>(
                  valueListenable: _selectedIndexNotifier,
                  builder: (context, int selected, Widget? child) {
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: DirectoryAccountsPanel.alphabet.length,
                      itemBuilder: (BuildContext context, int index) {
                        bool isSelected = _lastSelectedLetterIndex == index;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          // key: isSelected ? letterKey : null,
                          child: Text(DirectoryAccountsPanel.alphabet[index].toUpperCase(), style: Styles().textStyles.getTextStyle(isSelected ? 'widget.button.title.small.fat' : 'widget.button.title.small'), textAlign: TextAlign.center,),
                          onTap: () => _onTapIndexLetter(index),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) => SizedBox(width: 6),
                    );
                  })
          ),
        ),
        Expanded(
          child: RefreshIndicator(onRefresh: _onRefresh, child:
            SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), child:
              Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 24), child:
                DirectoryAccountsPage(widget.contentType, key: _pageKey, scrollController: _scrollController, letterIndex: _lastSelectedLetterIndex, onEditProfile: _onEditProfile, onShareProfile: _onShareProfile,),
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
    ProfileInfoSharePanel.present(context,
      profile: Auth2().account?.previewProfile(permitted: contentType.profileInfo.permitedVisibility),
    );
  }

  void _onTapIndexLetter(int index) {
    // _selectedIndexNotifier.value = x;
    // scrollToIndex(x, positionNotifier.value);
    setState(() {
      _lastSelectedLetterIndex = index;
    });
  }

  Future<void> _onRefresh() async =>
    _pageKey.currentState?.refresh();
}