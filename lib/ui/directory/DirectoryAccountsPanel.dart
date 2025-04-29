
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/directory/DirectoryAccountsList.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/ui/profile/ProfileInfoPage.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class DirectoryAccountsPanel extends StatefulWidget {
  static const String notifyEditInfo  = "edu.illinois.rokwire.directory.accounts.edit";

  final DirectoryAccounts contentType;
  DirectoryAccountsPanel(this.contentType, {super.key});

  @override
  State<StatefulWidget> createState() => _DirectoryAccountsPanelState();

  static const List<String> alphabet = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"];
  //TODO: make not static to filter alphabet based on counts map returned with accounts list (when filters are applied)
}

class _DirectoryAccountsPanelState extends State<DirectoryAccountsPanel> with NotificationsListener {

  final GlobalKey<_DirectoryAccountsPanelState> _pageKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController(viewportFraction: 1, initialPage: 0, keepPage: true);
  final _selectedIndexNotifier = ValueNotifier<int>(0);
  // final _positionNotifier = ValueNotifier<Offset>(const Offset(0, 0));
  int _lastSelectedLetterIndex = 0;

  final _letterKey = GlobalKey();

  String _searchText = '';
  Map<String, dynamic> _filterAttributes = <String, dynamic>{};
  GlobalKey<DirectoryAccountsListState> _accountsListKey = GlobalKey();
  GestureRecognizer? _editInfoRecognizer;
  GestureRecognizer? _shareInfoRecognizer;
  GestureRecognizer? _signInRecognizer;
  int? _accountTotal;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
    ]);
    _editInfoRecognizer = TapGestureRecognizer()..onTap = _onTapEditInfo;
    _shareInfoRecognizer = TapGestureRecognizer()..onTap = _onTapShareInfo;
    _signInRecognizer = TapGestureRecognizer()..onTap = _onTapSignIn;
    super.initState();
  }


  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _scrollController.dispose();
    _pageController.dispose();
    _editInfoRecognizer?.dispose();
    _shareInfoRecognizer?.dispose();
    _signInRecognizer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    Scaffold(
      appBar: RootHeaderBar(title: _appTitle, leading: RootHeaderBarLeading.Back,),
      body: Auth2().isOidcLoggedIn ? _scaffoldContent : _loggedOutContent,
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
        SizedBox(height: 8.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: _editOrShareDescription,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: _searchBarWidget,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Container(
            height: 52.0,
              child: ValueListenableBuilder<int>(
                  valueListenable: _selectedIndexNotifier,
                  builder: (context, int selected, Widget? child) {
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      scrollDirection: Axis.horizontal,
                      itemCount: DirectoryAccountsPanel.alphabet.length,
                      itemBuilder: (BuildContext context, int index) {
                        // bool isSelected = _lastSelectedLetterIndex == index;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          key: index == selected ? _letterKey : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 16.0),
                            child: Text(DirectoryAccountsPanel.alphabet[index].toUpperCase(),
                              style: Styles().textStyles.getTextStyle(index == selected ?
                                'widget.button.title.small.fat' : 'widget.button.title.small'),
                                textAlign: TextAlign.center,),
                          ),
                          onTap: () => _onTapIndexLetter(index),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) => SizedBox(width: 6),
                    );
                  })
          ),
        ),
        Expanded(
          child: Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 24), child:
            _accountsListWidget,
          ),
        ),
      ]
    );

  Widget get _accountsListWidget => DirectoryAccountsList(widget.contentType,
    key: _accountsListKey,
    displayMode: DirectoryDisplayMode.browse,
    scrollController: _scrollController,
    searchText: _searchText,
    filterAttributes: _filterAttributes,
    letterIndex: _lastSelectedLetterIndex,
    onAccountTotalUpdated: _onAccountTotalUpdated,
    onCurrentLetterChanged: _onCurrentIndexChanged,
  );

  static const String _linkEditMacro = "{{link.edit.info}}";
  static const String _linkShareMacro = "{{link.share.info}}";

  Widget get _editOrShareDescription {
    List<InlineSpan> spanList = StringUtils.split<InlineSpan>(_editOrShareDescriptionTemplate,
        macros: [_linkEditMacro, _linkShareMacro],
        builder: (String entry) {
          if (entry == _linkEditMacro) {
            return TextSpan(
              text: Localization().getStringEx('panel.directory.accounts.link.edit.info.text', 'Edit'),
              style : Styles().textStyles.getTextStyleEx("widget.detail.small.fat.underline", color: Styles().colors.fillColorSecondary),
              recognizer: _editInfoRecognizer,
            );
          }
          else if (entry == _linkShareMacro) {
            return TextSpan(
              text: Localization().getStringEx('panel.directory.accounts.link.share.info.text', 'share'),
              style : Styles().textStyles.getTextStyleEx("widget.detail.small.fat.underline", color: Styles().colors.fillColorSecondary),
              recognizer: _shareInfoRecognizer,
            );
          }
          else {
            return TextSpan(text: entry);
          }
        }
    );

    return Padding(padding: EdgeInsets.only(bottom: 16), child:
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(textAlign: TextAlign.left, text:
        TextSpan(style: Styles().textStyles.getTextStyle("widget.detail.small"), children: spanList)
        ),
        Text('${_accountTotal ?? 0} Users', style: Styles().textStyles.getTextStyleEx("widget.detail.small.fat")),
      ],
    )
    );
  }

  String get _editOrShareDescriptionTemplate {
    switch(widget.contentType) {
      case DirectoryAccounts.connections: return Localization().getStringEx('panel.directory.accounts.connections.edit.info.description', '$_linkEditMacro or $_linkShareMacro your connections information.');
      case DirectoryAccounts.directory: return Localization().getStringEx('panel.directory.accounts.directory.edit.info.description', '$_linkEditMacro or $_linkShareMacro your directory information.');
    }
  }

  void _onTapEditInfo() {
    Analytics().logSelect(target: 'Edit Info');
    _onEditProfile.call(widget.contentType);
  }

  void _onTapShareInfo() {
    Analytics().logSelect(target: 'Share Info');
    _onShareProfile.call(widget.contentType);
  }

  Widget get _searchBarWidget =>
      DirectoryFilterBar(
        key: ValueKey(DirectoryFilter(searchText: _searchText, attributes: _filterAttributes)),
        searchText: _searchText,
        onSearchText: _onSearchText,
        // [#4474] filterAttributes: _filterAttributes,
        // [#4474] onFilterAttributes: _onFilterAttributes,
      );

  void _onSearchText(String text) {
    setStateIfMounted((){
      _searchText = text;
      _accountsListKey = GlobalKey();
    });
  }

  // ignore: unused_element
  void _onFilterAttributes(Map<String, dynamic> filterAttributes) {
    setStateIfMounted((){
      _filterAttributes = filterAttributes;
      _accountsListKey = GlobalKey();
    });
  }

  void _onAccountTotalUpdated(int? accountTotal) {
    setStateIfMounted(() {
      _accountTotal = accountTotal;
    });
  }

  // Signed Out

  Widget get _loggedOutContent {
    final String linkLoginMacro = "{{link.login}}";
    String messageTemplate = Localization().getStringEx('panel.directory.accounts.message.signed_out', 'To view User Directory, $linkLoginMacro with your NetID and set your privacy level to 4 or 5 under Settings.');
    List<String> messages = messageTemplate.split(linkLoginMacro);
    List<InlineSpan> spanList = <InlineSpan>[];
    if (0 < messages.length)
      spanList.add(TextSpan(text: messages.first));
    for (int index = 1; index < messages.length; index++) {
      spanList.add(TextSpan(text: Localization().getStringEx('panel.directory.accounts.message.signed_out.link.login', "sign in"), style : Styles().textStyles.getTextStyle("widget.link.button.title.regular"),
          recognizer: _signInRecognizer));
      spanList.add(TextSpan(text: messages[index]));
    }

    return Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), child:
    RichText(textAlign: TextAlign.left, text:
    TextSpan(style: Styles().textStyles.getTextStyle("widget.message.dark.regular"), children: spanList)
    )
    );
  }

  void _onTapSignIn() {
    Analytics().logSelect(target: "sign in");
    ProfileHomePanel.present(context, content: ProfileContent.login, );
  }

  Future<void> refresh() async => _accountsListKey.currentState?.refresh();

  void _onCurrentIndexChanged(int index) {
    _selectedIndexNotifier.value = index;
    BuildContext? context = _letterKey.currentContext;
    if (context != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 500));
      });
    }
  }

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

  void _onTapIndexLetter(int index) {
    _selectedIndexNotifier.value = index;
    // scrollToIndex(x, positionNotifier.value);
    setState(() {
      _lastSelectedLetterIndex = index;
    });
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyLoginChanged) {
      setStateIfMounted();
    }
  }
}