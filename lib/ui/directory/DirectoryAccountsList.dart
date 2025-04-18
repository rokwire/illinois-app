
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart' as illinois;
import 'package:illinois/ui/directory/DirectoryAccountsPanel.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/ui/profile/ProfileInfoPage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.directory.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/auth2.directory.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum DirectoryAccounts { connections, directory }

class DirectoryAccountsList extends StatefulWidget {
  final DirectoryAccounts contentType;
  final DirectoryDisplayMode displayMode;
  final ScrollController? scrollController;
  final int? letterIndex;
  final String? searchText;
  final Map<String, dynamic>? filterAttributes;
  final Set<String>? selectedAccountIds;
  final void Function(Auth2PublicAccount, bool)? onAccountSelectionChanged;

  DirectoryAccountsList(this.contentType, { super.key, this.displayMode = DirectoryDisplayMode.browse, this.scrollController,
    this.letterIndex, this.searchText, this.filterAttributes, this.onAccountSelectionChanged, this.selectedAccountIds});

  @override
  State<StatefulWidget> createState() => DirectoryAccountsListState();
}

class DirectoryAccountsListState extends State<DirectoryAccountsList> with NotificationsListener, AutomaticKeepAliveClientMixin<DirectoryAccountsList>  {

  Map<String, List<Auth2PublicAccount>>? _accounts;
  Map<String, int> _nameGapIndices = Map.fromIterable(DirectoryAccountsPanel.alphabet, value: (_) => 0);
  int _totalAccounts = 0; //TODO: display in UI
  Map<String, int>? _letterCounts;
  bool _loading = false;
  bool _loadingProgress = false;
  bool _extending = false;
  bool _reverseExtending = false;
  static const int _pageLength = 32;

  String? _expandedAccountId;

  String _directoryPhotoImageToken = DirectoryProfilePhotoUtils.newToken;
  String _userPhotoImageToken = DirectoryProfilePhotoUtils.newToken;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      illinois.Auth2.notifyProfilePictureChanged,
      Auth2.notifyProfileChanged,
      Auth2.notifyPrivacyChanged,
      Auth2.notifyLoginChanged,
    ]);

    widget.scrollController?.addListener(_scrollListener);

    _load();
    super.initState();
  }


  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    widget.scrollController?.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DirectoryAccountsList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.letterIndex != widget.letterIndex) {
      _load();
    }
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == illinois.Auth2.notifyProfilePictureChanged) {
      if (mounted) {
        setState((){
          _userPhotoImageToken = DirectoryProfilePhotoUtils.newToken;
        });
      }
    }
    else if ((name == Auth2.notifyProfileChanged) || (name == Auth2.notifyPrivacyChanged) || (name == Auth2.notifyLoginChanged)) {
      if (mounted) {
        setState(() {
          _userPhotoImageToken = DirectoryProfilePhotoUtils.newToken;
        });
        refresh();
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loadingProgress) {
      return _loadingContent;
    }
    else if (_accounts == null) {
      return _messageContent(_failedText);
    }
    else if (_accounts?.isEmpty == true) {
      return _messageContent(_emptyText);
    }
    else {
      return _accountsContent;
    }
  }

  Widget get _accountsContent {
    List<Widget> contentList = <Widget>[];

    List<Auth2PublicAccount>? accounts = _accounts?[currentLetter];
    if ((accounts != null) && accounts.isNotEmpty) {
      String? directoryIndex;
      for (Auth2PublicAccount account in accounts) {
        String? accountDirectoryIndex = account.directoryKey;
        if ((accountDirectoryIndex != null) && (directoryIndex != accountDirectoryIndex)) {
          if (contentList.isNotEmpty) {
            contentList.add(Padding(padding: EdgeInsets.only(bottom: 16), child: _sectionSplitter));
          }
          contentList.add(_sectionHeading(directoryIndex = accountDirectoryIndex));
        }
        contentList.add(_sectionSplitter);
        contentList.add(DirectoryAccountListCard(account,
          displayMode: widget.displayMode,
          photoImageToken: (account.id == Auth2().accountId) ? _userPhotoImageToken : _directoryPhotoImageToken,
          expanded: (_expandedAccountId != null) && (account.id == _expandedAccountId),
          onToggleExpanded: () => _onToggleAccountExpanded(account),
          selected: widget.selectedAccountIds?.contains(account.id) == true,
          onToggleSelected: (value) => _onToggleAccountSelected(account, value),
        ));
      }
      if (contentList.isNotEmpty) {
        contentList.add(Padding(padding: EdgeInsets.only(bottom: 16), child: _sectionSplitter));
      }
    }

    if (_extending) {
      contentList.add(_extendingIndicator);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList);
  }

  void _onToggleAccountExpanded(Auth2PublicAccount account) {
    Analytics().logSelect(target: 'Expand', source: account.id);
    setState(() {
      _expandedAccountId = (_expandedAccountId != account.id) ? account.id : null;
    });
  }

  void _onToggleAccountSelected(Auth2PublicAccount account, bool value) {
    Analytics().logSelect(target: value ? 'Select' : 'Unselect', source: account.id);
    widget.onAccountSelectionChanged?.call(account, value);
  }

  Widget _sectionHeading(String dirEntry) =>
    Padding(padding: EdgeInsets.zero, child:
      Text(dirEntry, style: Styles().textStyles.getTextStyle('widget.title.small.semi_fat'),)
    );

  Widget get _sectionSplitter => Container(height: 1, color: Styles().colors.dividerLineAccent,);

  Widget get _extendingIndicator => Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child:
    Align(alignment: Alignment.center, child:
      SizedBox(width: 24, height: 24, child:
        DirectoryProgressWidget()
      ),
    ),
  );

  Widget get _loadingContent => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 64,), child:
    Center(child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,)
      )
    )
  );

  Widget _messageContent(String message) => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 64,), child:
    Center(child:
      Text(message, style: Styles().textStyles.getTextStyle("widget.message.dark.regular"), textAlign: TextAlign.center,)
    )
  );

  String get _emptyText {
    switch (widget.contentType) {
      case DirectoryAccounts.connections: return Localization().getStringEx('panel.directory.accounts.connections.empty.text', 'You do not have any Connections. Your connections will appear after you swap info with another ${AppTextUtils.universityLongNameMacro} student or employee.').replaceAll(AppTextUtils.universityLongNameMacro, AppTextUtils.universityLongName);
      case DirectoryAccounts.directory: return Localization().getStringEx('panel.directory.accounts.directory.empty.text', 'The User Directory is empty.');
    }
  }

  String get _failedText {
    switch (widget.contentType) {
      case DirectoryAccounts.connections: return Localization().getStringEx('panel.directory.accounts.connections.failed.text', 'Failed to load Connections content.');
      case DirectoryAccounts.directory: return Localization().getStringEx('panel.directory.accounts.directory.failed.text', 'Failed to load User Directory content.');
    }
  }

  void _scrollListener() {
    ScrollController? scrollController = widget.scrollController;
    if ((scrollController != null) && (scrollController.offset >= scrollController.position.maxScrollExtent) && _canExtend && !_loading && !_extending) {
      _extend();
    } else if ((scrollController != null) && (scrollController.offset <= scrollController.position.minScrollExtent) && _canReverseExtend && !_loading && !_reverseExtending) {
      _extend(reverse: true);
    }
  }

  Future<void> _load({ int limit = _pageLength, bool silent = false }) async {
    if (!_loading) {
      setStateIfMounted(() {
        _loading = true;
        _loadingProgress = !silent;
        _extending = false;
      });

      Auth2PublicAccountsResult? result = await Auth2().loadDirectoryAccounts(
        search: StringUtils.ensureEmpty(widget.searchText),
        attributes: widget.filterAttributes,
        nameOffset: _getNameOffset(),
        limit: limit,
      );

      setStateIfMounted(() {
        _loading = false;
        _loadingProgress = false;
        _totalAccounts = result?.totalCount ?? 0;
        _letterCounts = result?.indexCounts;
        if (result?.accounts != null) {
          _accounts ??= {};
          for (Auth2PublicAccount account in result?.accounts?.reversed ?? []) {
            String? indexLetter = account.profile?.lastName?.substring(0, 1);
            if (indexLetter != null) {
              int? gapIndex = _nameGapIndices[indexLetter];
              if (gapIndex != null) {
                _accounts![indexLetter] ??= [];
                _accounts![indexLetter]!.insert(gapIndex, account);
              }
            }
          }
        }
        else if (!silent) {
          _accounts = null;
        }
      });
    }
  }

  Future<void> refresh() =>
    _load(limit: max(_accountsCount, _pageLength), silent: true);

  Future<void> _extend({bool reverse = false}) async {
    if (!_loading && !_extending) {
      setStateIfMounted(() {
        _extending = true;
      });

      Auth2PublicAccountsResult? result = await Auth2().loadDirectoryAccounts(
        search: StringUtils.ensureEmpty(widget.searchText),
        attributes: widget.filterAttributes,
        nameOffset: _getNameOffset(reverse: reverse),
        limit: _pageLength
      );

      if (mounted && _extending && !_loading) {
        setState(() {
          _totalAccounts = result?.totalCount ?? 0;
          _letterCounts = result?.indexCounts;
          if (result?.accounts != null) {
            _accounts ??= {};
            for (Auth2PublicAccount account in result?.accounts?.reversed ?? []) {
              String? indexLetter = account.profile?.lastName?.substring(0, 1);
              //TODO: check for duplicates
              if (indexLetter != null) {
                int? gapIndex = _nameGapIndices[indexLetter];
                if (gapIndex != null) {
                  _accounts![indexLetter] ??= [];
                  if (reverse) {
                    _accounts![indexLetter]!.insert(gapIndex + 1, account);
                  } else {
                    _accounts![indexLetter]!.insert(gapIndex, account);
                  }
                }
              }
            }
          }
          _extending = false;
        });
      }
    }
  }

  int get _accountsCount {
    int total = 0;
    for (List<Auth2PublicAccount> letterAccounts in _accounts?.values ?? []) {
      total += letterAccounts.length;
    }
    return total;
  }

  bool _hasLoadedAllAccountsForLetter({String? letter}) {
    letter ??= currentLetter;
    int? loadedAccounts = _accounts?[letter]?.length;
    int? letterAccounts = _letterCounts?[letter];
    return letterAccounts == null || (loadedAccounts != null && loadedAccounts < letterAccounts);
  }

  String? _getNameOffset({bool reverse = false}) {
    if (reverse) {
      if (_accounts?[currentLetter]?.isEmpty != true) {
        int? gapIndex = _nameGapIndices[currentLetter];
        if (gapIndex != null && gapIndex < (_accounts?[currentLetter]?.length ?? 0) - 1) {
          Auth2PublicAccount? account = _accounts?[currentLetter]?[gapIndex+1];
          return account?.profile?.lastName;
        }
      }
      return previousLetter;
    }
    if (_accounts?[currentLetter]?.isEmpty != true) {
      int? gapIndex = _nameGapIndices[currentLetter];
      if (gapIndex != null) {
        Auth2PublicAccount? account = _accounts?[currentLetter]?[gapIndex];
        return account?.profile?.lastName;
      }
    }
    return currentLetter;
  }

  bool get _canExtend {
    if (widget.letterIndex != null) {
      for (int i = widget.letterIndex!; i < DirectoryAccountsPanel.alphabet.length; i++) {
        String? letter = DirectoryAccountsPanel.alphabet[i];
        if (!_hasLoadedAllAccountsForLetter(letter: letter)) {
          return true;
        }
      }
    }
    return false;
  }

  bool get _canReverseExtend {
    if (widget.letterIndex != null) {
      for (int i = widget.letterIndex!; i >= 0; i--) {
        String? letter = DirectoryAccountsPanel.alphabet[i];
        if (!_hasLoadedAllAccountsForLetter(letter: letter)) {
          return true;
        }
      }
    }
    return false;
  }

  String get currentLetter => widget.letterIndex != null ? DirectoryAccountsPanel.alphabet[widget.letterIndex!] : '';
  String get previousLetter => widget.letterIndex != null ? DirectoryAccountsPanel.alphabet[widget.letterIndex! - 1] : '';
}

extension _Auth2PublicAccountUtils on Auth2PublicAccount {
  String? get directoryKey => (profile?.lastName?.isNotEmpty == true) ?
    profile?.lastName?.substring(0, 1).toUpperCase() : null;
}

extension DirectoryAccountsProfile on DirectoryAccounts {
  ProfileInfo get profileInfo {
    switch(this) {
      case DirectoryAccounts.directory: return ProfileInfo.directoryInfo;
      case DirectoryAccounts.connections: return ProfileInfo.connectionsInfo;
    }
  }
}