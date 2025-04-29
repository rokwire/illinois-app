
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
import 'package:visibility_detector/visibility_detector.dart';

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
  final void Function(int)? onUpdateLetterIndex;
  final void Function(bool)? onUpdateRefreshEnabled;
  final void Function()? onUpdateAlphabet;

  DirectoryAccountsList(this.contentType, { super.key, required this.letterIndex, this.displayMode = DirectoryDisplayMode.browse, this.scrollController,
    this.searchText, this.filterAttributes, this.onAccountSelectionChanged, this.onAccountTotalUpdated, this.onUpdateLetterIndex, this.onUpdateRefreshEnabled, this.onUpdateAlphabet, this.selectedAccountIds});

  @override
  State<StatefulWidget> createState() => DirectoryAccountsListState();
}

class DirectoryAccountsListState extends State<DirectoryAccountsList> with NotificationsListener, AutomaticKeepAliveClientMixin<DirectoryAccountsList>  {
  Map<String, List<Auth2PublicAccount>>? _accounts;
  Map<String, int> _nameGapIndices = {};
  Map<String, int>? _letterCounts;
  Map<String, GlobalKey> _sectionHeadingKeys = {};
  late int _letterIndex;
  String? _firstDisplayLastName;
  String? _lastDisplayLastName;
  List<String> _alphabet = DirectoryAccountsPanel.defaultAlphabet;

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
      _letterIndex = widget.letterIndex;
      _jumpToLetter();
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
    List<Widget> contentList = <Widget>[
      if (_reverseExtending)
        _extendingIndicator,
    ];

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

  Widget _sectionHeading(String dirEntry) {
    String lowerDirEntry = dirEntry.toLowerCase();
    int userCount = _letterCounts?[lowerDirEntry] ?? 0;
    String userText = userCount == 1 ? 'User' : 'Users';
    _sectionHeadingKeys[lowerDirEntry] ??= GlobalKey();
    Widget heading = Padding(padding: EdgeInsets.zero, child:
      Row(
        key: _sectionHeadingKeys[lowerDirEntry],
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(dirEntry, style: Styles().textStyles.getTextStyle('widget.title.small.semi_fat'),),
          Text('$userCount $userText', style: Styles().textStyles.getTextStyle('widget.title.small.semi_fat'),),
        ],
      )
    );

    if (lowerDirEntry == _alphabet[0]) {
      return VisibilityDetector(
        key: UniqueKey(),
        onVisibilityChanged: (VisibilityInfo info) {
          List<Auth2PublicAccount>? firstSectionAccounts = _accounts?[lowerDirEntry];
          if (CollectionUtils.isNotEmpty(firstSectionAccounts)) {
            String? firstLastName = firstSectionAccounts!.first.profile?.lastName;
            if (firstLastName != null && _firstDisplayLastName != null && (_firstDisplayLastName == firstLastName)) {
              widget.onUpdateRefreshEnabled?.call(info.visibleFraction >= 1);
            }
          }
        },
        child: heading,
      );
    }
    return heading;
  }


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
      // int? extendFromLetterIndex = _getLetterIndexToExtend();
      // if (extendFromLetterIndex != null) {
        // _extend(letterIndex: extendFromLetterIndex);
        _extend();
      // }
    } else if ((scrollController != null) && (scrollController.offset <= scrollController.position.minScrollExtent) && !_loading && !_reverseExtending) {
      // int? extendFromLetterIndex = _getLetterIndexToExtend(reverse: true);
      // if (extendFromLetterIndex != null) {
        // _extend(letterIndex: extendFromLetterIndex, reverse: true);
        _extend(reverse: true);
      // }
    }
  }

  Future<void> _load({ int limit = _pageLength, bool silent = false, bool init = true }) async {
    if (!_loading) {
      setStateIfMounted(() {
        _loading = true;
        _loadingProgress = !silent;
        _extending = false;
      });

      Auth2PublicAccountsResult? result = await Auth2().loadDirectoryAccounts(
        search: StringUtils.ensureEmpty(widget.searchText),
        attributes: widget.filterAttributes,
        offset: _getOffset(init: init),
        limit: limit,
      );

      widget.onAccountTotalUpdated?.call(result?.totalCount);
      setStateIfMounted(() {
        _loading = false;
        _loadingProgress = false;
        _letterCounts = result?.indexCounts;
        _updateAlphabet();
        if (result?.accounts != null) {
          if (init) {
            _accounts?.clear();
            _nameGapIndices.clear();
            // _sectionHeadingKeys.clear();
          }
          // else if (!_hasLoadedAccountsAtSectionStart()) {
          //   _sectionHeadingKeys.clear();
          // }
          _accounts ??= {};
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
    widget.onUpdateLetterIndex?.call(0);
    _load(silent: true);
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
        limit: _pageLength,
        reverse: reverse,
      );

      widget.onAccountTotalUpdated?.call(result?.totalCount);
      if (mounted && (_extending || _reverseExtending) && !_loading) {
        setState(() {
          _letterCounts = result?.indexCounts;
          _updateAlphabet();
          if (result?.accounts != null) {
            _accounts ??= {};
            Map<String, int> accountsInserted = {};
            for (Auth2PublicAccount account in (reverse ? result?.accounts : result?.accounts?.reversed) ?? []) {
              String? indexLetter = account.profile?.lastName?.substring(0, 1).toLowerCase();
              if (indexLetter != null) {
                int gapIndex = _nameGapIndices[indexLetter] ?? 0;
                _accounts![indexLetter] ??= [];
                //TODO: check for duplicate
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

  void _jumpToLetter() {
    String letter = _alphabet[_letterIndex];
    int loadedAccounts = _accounts?[letter]?.length ?? 0;
    int gapIndex = _nameGapIndices[letter] ?? 0;
    if (loadedAccounts == 0 || gapIndex == 0) {
      // have not loaded accounts at the beginning of this letter section
      bool ensureVisible = false;
      if (_letterIndex > 0) {
        int previousLetterLoaded = _accounts?[previousLetter]?.length ?? 0;
        int previousLetterTotal = _letterCounts?[previousLetter] ?? 0;
        if (previousLetterLoaded >= previousLetterTotal) {
          ensureVisible = true;
        }
      }
      _load(silent: true, init: false).then((_) {
        if (ensureVisible) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            BuildContext? context = _sectionHeadingKeys[letter]?.currentContext;
            if (context != null) {
              Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 500));
            }
          });
        }
      });

      // if accounts not loaded, load accounts for letter (show loading indicator) then UI updates to show loaded accounts
        // when accounts are loaded, check if in current accounts chunk (check _firstDisplayLastName and _lastDisplayLastName)
        // if in current chunk, animate to first account with lastname starting with letter (use widget key Map<String, GlobalKey?>)
        // if not in current chunk, UI update performs the jump by displaying a different list of accounts
    } else if (_hasLoadedAccountsAtSectionStart(letter: letter)) {
      BuildContext? context = _sectionHeadingKeys[letter]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, duration: Duration(milliseconds: 500));
      }
    } else {
      // already have accounts for start of letter - rebuild UI to show separate list of accounts
      setStateIfMounted(() {
        // _sectionHeadingKeys.clear();
      });
    }
  }

  List<Auth2PublicAccount> get _displayAccounts {
    List<Auth2PublicAccount> previousLetterAccounts = [];
    for (int i = _letterIndex - 1; i >- 0; i--) {
      String letter = _alphabet[i];
      int gapIndex = _nameGapIndices[letter] ?? 0;
      int loadedAccounts = _accounts?[letter]?.length ?? 0;
      int letterAccounts = _letterCounts?[letter] ?? 0;
      if (loadedAccounts >= letterAccounts) {
        previousLetterAccounts.addAll(_accounts?[letter]?.reversed ?? []);
      } else {
        if (gapIndex < loadedAccounts) {
          previousLetterAccounts.addAll(_accounts?[letter]?.sublist(gapIndex).reversed ?? []);
        }
        break;  // have not loaded all accounts for this letter, do not go to the one before this in alphabet
      }
    }
    if (previousLetterAccounts.isNotEmpty) {
      _firstDisplayLastName = previousLetterAccounts.last.profile?.lastName;
      _lastDisplayLastName = previousLetterAccounts.first.profile?.lastName;
    }

    List<Auth2PublicAccount> currentAndNextLetterAccounts = [];
    for (int i = _letterIndex; i < _alphabet.length; i++) {
      String letter = _alphabet[i];
      int gapIndex = _nameGapIndices[letter] ?? 0;
      int loadedAccounts = _accounts?[letter]?.length ?? 0;
      int letterAccounts = _letterCounts?[letter] ?? 0;
      if (loadedAccounts >= letterAccounts) {
        currentAndNextLetterAccounts.addAll(_accounts?[letter] ?? []);
      } else {
        if (gapIndex > 0) {
          currentAndNextLetterAccounts.addAll(_accounts?[letter]?.sublist(0, gapIndex) ?? []);
        }
        break;  // have not loaded all accounts for this letter, do not go to the one after this in alphabet
      }
    }
    if (currentAndNextLetterAccounts.isNotEmpty) {
      String? firstLastName = currentAndNextLetterAccounts.first.profile?.lastName;
      if (_firstDisplayLastName == null || (firstLastName != null && firstLastName.compareTo(_firstDisplayLastName!) < 0)) {
        _firstDisplayLastName = firstLastName;
      }
      String? lastLastName = currentAndNextLetterAccounts.last.profile?.lastName;
      if (_lastDisplayLastName == null || (lastLastName != null && lastLastName.compareTo(_lastDisplayLastName!) > 0)) {
        _lastDisplayLastName = lastLastName;
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

  bool _hasLoadedAccountsAtSectionStart({String? letter}) {
    letter ??= currentLetter;
    return (_firstDisplayLastName != null && letter.compareTo(_firstDisplayLastName!) >= 0) && (_lastDisplayLastName != null && letter.compareTo(_lastDisplayLastName!) <= 0);
  }

  String? _getOffset({int? letterIndex, bool reverse = false, bool init = false}) {
    if (!init) {
      letterIndex ??= _letterIndex;
      String letter = _alphabet[letterIndex];
      if (reverse) {
        if (_accounts?[letter]?.isEmpty == false) {
          int gapIndex = _nameGapIndices[letter] ?? 0;
          if (gapIndex < (_accounts?[letter]?.length ?? 0)) {
            Auth2PublicAccount? account = _accounts?[letter]?[gapIndex+1];
            return '${account?.profile?.lastName},${account?.profile?.firstName},${account?.id}';
          }
        }
        return letter;
      }
      if (_accounts?[letter]?.isEmpty == false) {
        int gapIndex = _nameGapIndices[letter] ?? 0;
        if (gapIndex > 0) {
          Auth2PublicAccount? account = _accounts?[letter]?[gapIndex - 1];
          return '${account?.profile?.lastName},${account?.profile?.firstName},${account?.id}';
        }
        return letter;
      }
    }
    return currentLetter;
  }

  int? _getLetterIndexToExtend({bool reverse = false}) {
    if (reverse) {
      for (int i = _letterIndex; i >= 0; i--) {
        String letter = _alphabet[i];
        int gapIndex = _nameGapIndices[letter] ?? 0;
        if (!_hasLoadedAllAccountsForLetter(letter: letter) && (gapIndex == 0 || i > 0)) {
          return i;
        }
      }
    } else {
      for (int i = _letterIndex; i < _alphabet.length; i++) {
        String letter = _alphabet[i];
        int gapIndex = _nameGapIndices[letter] ?? 0;
        int loadedAccounts = _accounts?[letter]?.length ?? 0;
        if (!_hasLoadedAllAccountsForLetter(letter: letter) && (gapIndex == loadedAccounts || i < _alphabet.length - 1)) {
          return i;
        }
      }
    }
    return null;
  }

  void _updateAlphabet() {
    Set<String> newAlphabet = _letterCounts?.keys.where((letter) => (_letterCounts?[letter] ?? 0) > 0).toSet() ?? {};
    Set<String> currentAlphabet = _alphabet.toSet();
    if (newAlphabet.difference(currentAlphabet).isNotEmpty || currentAlphabet.difference(newAlphabet).isNotEmpty) {
      _alphabet = newAlphabet.toList()..sort((a, b) => a.compareTo(b));
      widget.onUpdateAlphabet?.call();
    }
  }

  String get currentLetter => _alphabet[_letterIndex];
  String get previousLetter => _alphabet[_letterIndex - 1];
  List<String> get alphabet => _alphabet;
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