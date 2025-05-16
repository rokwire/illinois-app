
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/directory/DirectoryAccountsList.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class DirectoryAccountsPage extends StatefulWidget {
  static const String notifyEditInfo  = "edu.illinois.rokwire.directory.accounts.edit";

  final ScrollController? scrollController;
  final void Function()? onEditProfile;
  final void Function()? onShareProfile;

  DirectoryAccountsPage({ super.key, this.scrollController, this.onEditProfile, this.onShareProfile });

  @override
  State<StatefulWidget> createState() => DirectoryAccountsPageState();
}

class DirectoryAccountsPageState extends State<DirectoryAccountsPage> with NotificationsListener {

  String _searchText = '';
  Map<String, dynamic> _filterAttributes = <String, dynamic>{};
  GlobalKey<DirectoryAccountsListState> _accountsListKey = GlobalKey();
  GestureRecognizer? _editInfoRecognizer;
  GestureRecognizer? _shareInfoRecognizer;
  GestureRecognizer? _signInRecognizer;

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
    _editInfoRecognizer?.dispose();
    _shareInfoRecognizer?.dispose();
    _signInRecognizer?.dispose();
    super.dispose();
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyLoginChanged) {
      setStateIfMounted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Auth2().isOidcLoggedIn ? _pageContent : _loggedOutContent;
  }

  Widget get _pageContent =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      if ((widget.onEditProfile != null) && (widget.onShareProfile != null))
        _editOrShareDescription,
      _searchBarWidget,
      _accountsListWidget,
    ]);

  Widget get _accountsListWidget => DirectoryAccountsList(
    key: _accountsListKey,
    displayMode: DirectoryDisplayMode.browse,
    scrollController: widget.scrollController,
    searchText: _searchText,
    filterAttributes: _filterAttributes,
  );

  static const String _linkEditMacro = "{{link.edit.info}}";
  static const String _linkShareMacro = "{{link.share.info}}";

  Widget get _editOrShareDescription {
    String templateString = Localization().getStringEx('panel.directory.accounts.directory.edit.info.description', '$_linkEditMacro or $_linkShareMacro your directory information.');
    List<InlineSpan> spanList = StringUtils.split<InlineSpan>(templateString,
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
      RichText(textAlign: TextAlign.left, text:
        TextSpan(style: Styles().textStyles.getTextStyle("widget.detail.small"), children: spanList)
      )
    );
  }

  void _onTapEditInfo() {
    Analytics().logSelect(target: 'Edit Info');
    widget.onEditProfile?.call();
  }

  void _onTapShareInfo() {
    Analytics().logSelect(target: 'Share Info');
    widget.onShareProfile?.call();
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

  // Signed Out

  Widget get _loggedOutContent {
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

    return Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), child:
      RichText(textAlign: TextAlign.left, text:
        TextSpan(style: Styles().textStyles.getTextStyle("widget.message.dark.regular"), children: spanList)
      )
    );
  }

  void _onTapSignIn() {
    Analytics().logSelect(target: "sign in");
    ProfileHomePanel.present(context, contentType: ProfileContentType.login, );
  }

  Future<void> refresh() async => _accountsListKey.currentState?.refresh();
}
