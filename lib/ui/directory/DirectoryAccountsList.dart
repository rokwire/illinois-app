
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
  final int letterIndex;
  final String? searchText;
  final Map<String, dynamic>? filterAttributes;
  final Set<String>? selectedAccountIds;
  final void Function(Auth2PublicAccount, bool)? onAccountSelectionChanged;
  final void Function(int?)? onAccountTotalUpdated;

  DirectoryAccountsList(this.contentType, { super.key, required this.letterIndex, this.displayMode = DirectoryDisplayMode.browse, this.scrollController,
    this.searchText, this.filterAttributes, this.onAccountSelectionChanged, this.onAccountTotalUpdated, this.selectedAccountIds});

  @override
  State<StatefulWidget> createState() => DirectoryAccountsListState();
}

class DirectoryAccountsListState extends State<DirectoryAccountsList> with NotificationsListener, AutomaticKeepAliveClientMixin<DirectoryAccountsList>  {
  static List<String> get alphabet => DirectoryAccountsPanel.alphabet;

  Map<String, List<Auth2PublicAccount>>? _accounts;
  Map<String, int> _nameGapIndices = Map.fromIterable(alphabet, value: (_) => 0);
  Map<String, int>? _letterCounts;
  late int _letterIndex;

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

    _letterIndex = widget.letterIndex;
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

    // handles letter index taps
    if (_letterIndex != widget.letterIndex) {
      //TODO: load or jump to letter with accounts already loaded
      //TODO: _letterIndex should be updated by scrolling
      _letterIndex = widget.letterIndex;
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

    List<Auth2PublicAccount>? accounts = _displayAccounts;
    if (accounts.isNotEmpty) {
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
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(dirEntry, style: Styles().textStyles.getTextStyle('widget.title.small.semi_fat'),),
          Text('${_letterCounts?[dirEntry.toLowerCase()] ?? 0} Users', style: Styles().textStyles.getTextStyle('widget.title.small.semi_fat'),),
        ],
      )
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
    if ((scrollController != null) && (scrollController.offset >= scrollController.position.maxScrollExtent) && !_loading && !_extending) {
      int? extendFromLetterIndex = _getLetterIndexToExtend();
      if (extendFromLetterIndex != null) {
        _extend(letterIndex: extendFromLetterIndex);
      }
    } else if ((scrollController != null) && (scrollController.offset <= scrollController.position.minScrollExtent) && !_loading && !_reverseExtending) {
      int? extendFromLetterIndex = _getLetterIndexToExtend(reverse: true);
      if (extendFromLetterIndex != null) {
        _extend(letterIndex: extendFromLetterIndex, reverse: true);
      }
    }
    //TODO: handle scrolling to new letter index updating UI in DirectoryAccountsPanel, calculating _displayAccounts
  }

  Future<void> _load({ int limit = _pageLength, bool silent = false, bool refresh = false }) async {
    if (!_loading) {
      setStateIfMounted(() {
        _loading = true;
        _loadingProgress = !silent;
        _extending = false;
      });

      Auth2PublicAccountsResult? result = await Auth2().loadDirectoryAccounts(
        search: StringUtils.ensureEmpty(widget.searchText),
        attributes: widget.filterAttributes,
        offset: _getOffset(refresh: refresh),
        limit: limit,
      );

      widget.onAccountTotalUpdated?.call(result?.totalCount);
      setStateIfMounted(() {
        _loading = false;
        _loadingProgress = false;
        _letterCounts = result?.indexCounts;
        if (result?.accounts != null) {
          _accounts = {};
          _nameGapIndices = {};
          Map<String, int> accountsInserted = {};
          for (Auth2PublicAccount account in result?.accounts?.reversed ?? []) {
            String? indexLetter = account.profile?.lastName?.substring(0, 1).toLowerCase();
            if (indexLetter != null) {
              int gapIndex = _nameGapIndices[indexLetter] ?? 0;
              _accounts![indexLetter] ??= [];
              _accounts![indexLetter]!.insert(gapIndex, account);

              int added = accountsInserted[indexLetter] ?? 0;
              accountsInserted[indexLetter] = ++added;
            }
          }

          for (MapEntry<String, int> inserted in accountsInserted.entries) {
            _nameGapIndices[inserted.key] = (_nameGapIndices[inserted.key] ?? 0) + inserted.value;
          }
        }
        else if (!silent) {
          _accounts = null;
        }
      });
    }
  }

  Future<void> refresh() async {
    _letterIndex = 0;
    _load(silent: true, refresh: true);
  }

  Future<void> _extend({int? letterIndex, bool reverse = false}) async {
    if (!_loading && ((!reverse && !_extending) || (reverse && !_reverseExtending))) {
      setStateIfMounted(() {
        _extending = true;
      });

      Auth2PublicAccountsResult? result = await Auth2().loadDirectoryAccounts(
        search: StringUtils.ensureEmpty(widget.searchText),
        attributes: widget.filterAttributes,
        offset: _getOffset(letterIndex: letterIndex, reverse: reverse),
        limit: _pageLength
      );

      widget.onAccountTotalUpdated?.call(result?.totalCount);
      if (mounted && _extending && !_loading) {
        setState(() {
          _letterCounts = result?.indexCounts;
          if (result?.accounts != null) {
            _accounts ??= {};
            Map<String, int> accountsInserted = {};
            for (Auth2PublicAccount account in (reverse ? result?.accounts : result?.accounts?.reversed) ?? []) {
              String? indexLetter = account.profile?.lastName?.substring(0, 1).toLowerCase();
              if (indexLetter != null) {
                int gapIndex = _nameGapIndices[indexLetter] ?? 0;
                _accounts![indexLetter] ??= [];
                _accounts![indexLetter]!.insert(gapIndex, account);

                int added = accountsInserted[indexLetter] ?? 0;
                accountsInserted[indexLetter] = ++added;
              }
            }

            for (MapEntry<String, int> inserted in accountsInserted.entries) {
              if (!reverse) {
                _nameGapIndices[inserted.key] = (_nameGapIndices[inserted.key] ?? 0) + inserted.value;
              }
            }
          }
          _extending = false;
        });
      }
    }
  }

  List<Auth2PublicAccount> get _displayAccounts {
    List<Auth2PublicAccount> previousLetterAccounts = [];
    for (int i = _letterIndex - 1; i >- 0; i--) {
      String letter = alphabet[i];
      int gapIndex = _nameGapIndices[currentLetter] ?? 0;
      int loadedAccounts = _accounts?[letter]?.length ?? 0;
      int letterAccounts = _letterCounts?[letter] ?? 0;
      if (loadedAccounts >= letterAccounts) {
        previousLetterAccounts.addAll(_accounts?[letter]?.reversed ?? []);
      } else if (gapIndex < loadedAccounts) {
        previousLetterAccounts.addAll(_accounts?[letter]?.sublist(gapIndex).reversed ?? []);
        break;  // have not loaded all accounts for this letter, do not go to the one before this in alphabet
      }
    }

    List<Auth2PublicAccount> currentAndNextLetterAccounts = [];
    for (int i = _letterIndex; i < alphabet.length; i++) {
      String letter = alphabet[i];
      int gapIndex = _nameGapIndices[currentLetter] ?? 0;
      int loadedAccounts = _accounts?[letter]?.length ?? 0;
      int letterAccounts = _letterCounts?[letter] ?? 0;
      if (loadedAccounts >= letterAccounts) {
        currentAndNextLetterAccounts.addAll(_accounts?[letter] ?? []);
      } else if (gapIndex > 0) {
        currentAndNextLetterAccounts.addAll(_accounts?[letter]?.sublist(0, gapIndex) ?? []);
        break;  // have not loaded all accounts for this letter, do not go to the one after this in alphabet
      }
    }

    return [
      ...previousLetterAccounts.reversed,
      ...currentAndNextLetterAccounts,
    ];
  }

  // int get _accountsCount {
  //   int total = 0;
  //   for (List<Auth2PublicAccount> letterAccounts in _accounts?.values ?? []) {
  //     total += letterAccounts.length;
  //   }
  //   return total;
  // }

  bool _hasLoadedAllAccountsForLetter({String? letter}) {
    letter ??= currentLetter;
    int? loadedAccounts = _accounts?[letter]?.length;
    int? letterAccounts = _letterCounts?[letter];
    return letterAccounts == null || (loadedAccounts != null && loadedAccounts >= letterAccounts);
  }

  String? _getOffset({int? letterIndex, bool reverse = false, bool refresh = false}) {
    if (!refresh) {
      letterIndex ??= _letterIndex;
      String? letter = alphabet[letterIndex];
      if (reverse) {
        if (_accounts?[letter]?.isEmpty == false) {
          int gapIndex = _nameGapIndices[letter] ?? 0;
          if (gapIndex < (_accounts?[letter]?.length ?? 0) - 1) {
            Auth2PublicAccount? account = _accounts?[letter]?[gapIndex+1];
            return '${account?.profile?.lastName},${account?.profile?.firstName},${account?.id}';
          }
        }
        return previousLetter;
      }
      if (_accounts?[letter]?.isEmpty == false) {
        int gapIndex = _nameGapIndices[letter] ?? 0;
        Auth2PublicAccount? account = _accounts?[letter]?[gapIndex];
        return '${account?.profile?.lastName},${account?.profile?.firstName},${account?.id}';
      }
    }
    return currentLetter;
  }

  int? _getLetterIndexToExtend({bool reverse = false}) {
    if (reverse) {
      for (int i = _letterIndex; i >= 0; i--) {
        String? letter = alphabet[i];
        if (!_hasLoadedAllAccountsForLetter(letter: letter)) {
          return i;
        }
      }
    } else {
      for (int i = _letterIndex; i < alphabet.length; i++) {
        String? letter = alphabet[i];
        if (!_hasLoadedAllAccountsForLetter(letter: letter)) {
          return i;
        }
      }
    }
    return null;
  }

  String get currentLetter => alphabet[_letterIndex];
  String get previousLetter => alphabet[_letterIndex - 1];
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