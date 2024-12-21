
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/ui/directory/DirectoryAccountsList.dart';
import 'package:neom/ui/directory/DirectoryWidgets.dart';
import 'package:neom/ui/profile/ProfileHomePanel.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class DirectoryAccountsPage extends StatefulWidget {
  static const String notifyEditInfo  = "edu.illinois.rokwire.directory.accounts.edit";

  final DirectoryAccounts contentType;
  final ScrollController? scrollController;
  final void Function(DirectoryAccounts contentType)? onEditProfile;

  DirectoryAccountsPage(this.contentType, { super.key, this.scrollController, this.onEditProfile});

  @override
  State<StatefulWidget> createState() => DirectoryAccountsPageState();
}

class DirectoryAccountsPageState extends State<DirectoryAccountsPage> {

  String _searchText = '';
  Map<String, dynamic> _filterAttributes = <String, dynamic>{};
  GlobalKey<DirectoryAccountsListState> _accountsListKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Auth2().isLoggedIn ? _pageContent : _loggedOutContent;
  }

  Widget get _pageContent =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      if (widget.onEditProfile != null)
        _editDescription,
      _searchBarWidget,
      _accountsListWidget,
    ]);

  Widget get _accountsListWidget => DirectoryAccountsList(widget.contentType,
    key: _accountsListKey,
    displayMode: DirectoryDisplayMode.browse,
    scrollController: widget.scrollController,
    searchText: _searchText,
    filterAttributes: _filterAttributes,
  );

  static const String _linkEditMacro = "{{link.edit.info}}";

  Widget get _editDescription {
    List<String> messages = _editDescriptionTemplate.split(_linkEditMacro);
    List<InlineSpan> spanList = <InlineSpan>[];
    if (0 < messages.length)
      spanList.add(TextSpan(text: messages.first));
    for (int index = 1; index < messages.length; index++) {
      spanList.add(TextSpan(
        text: Localization().getStringEx('panel.directory.accounts.command.edit.info.text', 'Edit your information'),
        style : Styles().textStyles.getTextStyleEx("widget.detail.small.fat.underline", color: Styles().colors.fillColorSecondary),
        recognizer: TapGestureRecognizer()..onTap = _onTapEditInfo, )
      );
      spanList.add(TextSpan(text: messages[index]));
    }

    return Padding(padding: EdgeInsets.only(bottom: 16), child:
      RichText(textAlign: TextAlign.left, text:
        TextSpan(style: Styles().textStyles.getTextStyle("widget.detail.small"), children: spanList)
      )
    );
  }

  String get _editDescriptionTemplate {
    switch(widget.contentType) {
      case DirectoryAccounts.connections: return Localization().getStringEx('panel.directory.accounts.connections.edit.info.description', '$_linkEditMacro that shows up in the Connections.');
      case DirectoryAccounts.directory: return Localization().getStringEx('panel.directory.accounts.directory.edit.info.description', '$_linkEditMacro that shows up in the User Directory.');
    }
  }

  void _onTapEditInfo() {
    Analytics().logSelect(target: 'Edit Info');
    widget.onEditProfile?.call(widget.contentType);
  }

  Widget get _searchBarWidget =>
    DirectoryFilterBar(
      key: ValueKey(DirectoryFilter(searchText: _searchText, attributes: _filterAttributes)),
      searchText: _searchText,
      onSearchText: _onSearchText,
      filterAttributes: _filterAttributes,
      onFilterAttributes: _onFilterAttributes,
    );

  void _onSearchText(String text) {
    setStateIfMounted((){
      _searchText = text;
      _accountsListKey = GlobalKey();
    });
  }

  void _onFilterAttributes(Map<String, dynamic> filterAttributes) {
    setStateIfMounted((){
      _filterAttributes = filterAttributes;
      _accountsListKey = GlobalKey();
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
        recognizer: TapGestureRecognizer()..onTap = _onTapSignIn, ));
      spanList.add(TextSpan(text: messages[index]));
    }

    return Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), child:
      RichText(textAlign: TextAlign.left, text:
        TextSpan(style: Styles().textStyles.getTextStyle("widget.message.dark.regular"), children: spanList)
      )
    );
  }

  void _onTapSignIn() => ProfileHomePanel.present(context, content: ProfileContent.login, );

  Future<void> refresh() async => _accountsListKey.currentState?.refresh();
}
