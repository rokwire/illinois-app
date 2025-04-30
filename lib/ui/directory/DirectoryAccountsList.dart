
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
  final void Function(int)? onCurrentLetterChanged;
  final void Function()? onUpdateAlphabet;

  DirectoryAccountsList(this.contentType, { super.key,
    required this.letterIndex, this.displayMode = DirectoryDisplayMode.browse,
    this.scrollController, this.searchText, this.filterAttributes,
    this.onAccountSelectionChanged, this.onAccountTotalUpdated,
    this.selectedAccountIds, this.onUpdateAlphabet, this.onCurrentLetterChanged});

  @override
  State<StatefulWidget> createState() => DirectoryAccountsListState();
}

class DirectoryAccountsListState extends State<DirectoryAccountsList> with NotificationsListener, AutomaticKeepAliveClientMixin<DirectoryAccountsList>  {
  static const double kCollapsedCardHeight = 44;
  static const double kExpandedCardHeight = 169;
  static const double kSectionHeadingHeight = 38;

  Map<String, List<Auth2PublicAccount>>? _accounts;
  Map<String, int> _nameGapIndices = {};
  Map<String, int>? _letterCounts;
  // Map<String, GlobalKey> _sectionHeadingKeys = {};

  late int _letterIndex;
  List<String> _alphabet = DirectoryAccountsPanel.defaultAlphabet;

  bool _loading = false;
  bool _loadingProgress = false;
  bool _extending = false;
  bool _reverseExtending = false;
  bool _refreshEnabled = true;
  bool _jumping = false;
  static const int _pageLength = 32;

  Auth2PublicAccount? _expandedAccount;

  String _directoryPhotoImageToken = DirectoryProfilePhotoUtils.newToken;
  String _userPhotoImageToken = DirectoryProfilePhotoUtils.newToken;

  List<Auth2PublicAccount> _displayAccounts = [];

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
          expanded: (_expandedAccount != null) && (account.id == _expandedAccount?.id),
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

    return RefreshIndicator(
      onRefresh: _onRefresh,
      notificationPredicate: _refreshEnabled ? (_) => true : (_) => false,
      child: ListView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: contentList.length,
        itemBuilder: (context, index) {
          return contentList[index];
        }
      ),
    );
  }

  Future<void> _onRefresh() async {
    _load();
  }

  void _onToggleAccountExpanded(Auth2PublicAccount account) {
    Analytics().logSelect(target: 'Expand', source: account.id);
    setState(() {
      _expandedAccount = (_expandedAccount?.id != account.id) ? account : null;
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
    // _sectionHeadingKeys[lowerDirEntry] ??= GlobalKey();
    // key: _sectionHeadingKeys[lowerDirEntry],
    Widget heading = Padding(padding: EdgeInsets.zero, child:
      Row(
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
        onVisibilityChanged: (info) => _onFirstHeadingVisibilityChanged(info, lowerDirEntry),
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
    if (!_jumping) {
      _checkForLetterIndexChange();

      ScrollController? scrollController = widget.scrollController;
      if ((scrollController != null) && (scrollController.offset >= scrollController.position.maxScrollExtent) && !_loading && !_extending && _canExtend) {
        _extend();
      } else if ((scrollController != null) && (scrollController.offset <= scrollController.position.minScrollExtent) && !_loading && !_reverseExtending && _canReverseExtend) {
        _extend(reverse: true);
      }
    }
  }

  void _checkForLetterIndexChange() {
    ScrollController? scrollController = widget.scrollController;
    int index = _getCurrentLetterIndex(scrollController?.offset);
    if (index >= 0 && _letterIndex != index) {
      _letterIndex = index;
      widget.onCurrentLetterChanged?.call(index);
    }
  }

  int _getCurrentLetterIndex(double? vPosition) {
    if (vPosition == null) {
      return -1;
    }

    //TODO: determine position bounds for each displayed section, return which interval the current position falls into (handle headings and expanded card)
    // get height of headings above the current position
    String? firstDisplayAccountSection = _firstDisplayAccount?.profile?.lastName?.substring(0, 1).toLowerCase();
    int firstSectionIndex = firstDisplayAccountSection != null ? _alphabet.indexOf(firstDisplayAccountSection) : _letterIndex;
    double headingsHeight = (_letterIndex - firstSectionIndex + 1) * kSectionHeadingHeight;

    int itemIndex = max(0, vPosition - headingsHeight) ~/ kCollapsedCardHeight;
    List<Auth2PublicAccount> accounts = _displayAccounts;
    if (itemIndex < 0 || itemIndex >= accounts.length) {
      return -1;
    }
    String? letter = accounts[itemIndex].profile?.lastName?.substring(0, 1).toLowerCase();
    if (letter == null) {
      return -1;
    }
    return _alphabet.indexOf(letter);
  }

  double get _sectionHeadingScrollOffset {
    String? firstDisplayAccountSection = _firstDisplayAccount?.profile?.lastName?.substring(0, 1).toLowerCase();
    int firstSectionIndex = firstDisplayAccountSection != null ? _alphabet.indexOf(firstDisplayAccountSection) : _letterIndex;
    double headingsHeight = (_letterIndex - firstSectionIndex) * kSectionHeadingHeight;

    double accountsHeight = 0;
    for (int i = firstSectionIndex; i < _letterIndex; i++) {
      String letter = _alphabet[i];
      int loadedAccounts = _accounts?[letter]?.length ?? 0;
      int gapIndex = _nameGapIndices[letter] ?? 0;
      if (gapIndex == loadedAccounts) {
        accountsHeight += loadedAccounts * kCollapsedCardHeight;
      } else {
        accountsHeight += (loadedAccounts - gapIndex) * kCollapsedCardHeight;
      }
    }

    double expandedCardCorrection = 0;
    if (_expandedAccount != null) {
      String? expandedAccountLastName = _expandedAccount?.profile?.lastName?.toLowerCase();
      if (expandedAccountLastName != null && firstDisplayAccountSection != null &&
          expandedAccountLastName.compareTo(firstDisplayAccountSection) > 0 && expandedAccountLastName.compareTo(_alphabet[_letterIndex]) < 0) {
        expandedCardCorrection = kExpandedCardHeight - kCollapsedCardHeight;
      }
    }

    return accountsHeight + headingsHeight + expandedCardCorrection;
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
            _displayAccounts.clear();
            _nameGapIndices.clear();
          }
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
          _displayAccounts = _generateDisplayAccounts;
        }
        else if (!silent) {
          _accounts = null;
        }
      });
    }
  }

  Future<void> refresh() async {
    _letterIndex = 0;
    _load(silent: true);
  }

  Future<void> _extend({bool reverse = false}) async {
    if (!_loading && ((!reverse && !_extending) || (reverse && !_reverseExtending))) {
      setStateIfMounted(() {
        _extending = !reverse;
        _reverseExtending = reverse;
      });

      Auth2PublicAccountsResult? result = await Auth2().loadDirectoryAccounts(
        search: StringUtils.ensureEmpty(widget.searchText),
        attributes: widget.filterAttributes,
        offset: _getOffset(reverse: reverse),
        limit: _pageLength,
        reverse: reverse,
      );

      widget.onAccountTotalUpdated?.call(result?.totalCount);
      if (mounted && (_extending || _reverseExtending) && !_loading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkForLetterIndexChange();
        });

        setState(() {
          _letterCounts = result?.indexCounts;
          _updateAlphabet();
          if (result?.accounts != null) {
            _accounts ??= {};
            Map<String, int> accountsInserted = {};
            bool searchForDuplicates = true;
            for (Auth2PublicAccount account in (reverse ? result?.accounts : result?.accounts?.reversed) ?? []) {
              String? indexLetter = account.profile?.lastName?.substring(0, 1).toLowerCase();
              if (indexLetter != null) {
                int gapIndex = _nameGapIndices[indexLetter] ?? 0;
                _accounts![indexLetter] ??= [];

                // check for duplicates
                bool duplicate = false;
                if (searchForDuplicates) {
                  if (reverse) {
                    for (int i = gapIndex - 1; i >= 0; i--) {
                      if (_accounts![indexLetter]![i].id == account.id) {
                        duplicate = true;
                      }
                    }
                  } else {
                    for (int i = gapIndex; i < (_accounts?[indexLetter]?.length ?? 0); i++) {
                      if (_accounts![indexLetter]![i].id == account.id) {
                        duplicate = true;
                      }
                    }
                  }
                }
                if (duplicate) {
                  continue;
                } else {
                  searchForDuplicates = false;
                }

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
          _displayAccounts = _generateDisplayAccounts;
          _extending = false;
          _reverseExtending = false;
        });
      }
    }
  }

  void _jumpToLetter() {
    String letter = _alphabet[_letterIndex];
    int gapIndex = _nameGapIndices[letter] ?? 0;
    if (gapIndex == 0) {
      _load(silent: true, init: false).then((_) {
        _scheduleJump();
      });
    } else {
      // already have accounts for start of letter - rebuild UI to show separate list of accounts
      _scheduleJump();
      setStateIfMounted(() {
        _displayAccounts = _generateDisplayAccounts;
      });
    }
  }

  void _scheduleJump() {
    if (widget.scrollController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _jumping = true;
        widget.scrollController?.animateTo(max(_sectionHeadingScrollOffset, 1), duration: const Duration(milliseconds: 1000), curve: Curves.linear).then((_) {
          _jumping = false;
        });
      });
    }
  }

  void _onFirstHeadingVisibilityChanged(VisibilityInfo info, String letter) {
    setState(() {
      _refreshEnabled = (info.visibleFraction >= 1);
    });
  }

  List<Auth2PublicAccount> get _generateDisplayAccounts {
    List<Auth2PublicAccount> previousLetterAccounts = [];
    for (int i = _letterIndex - 1; i >= 0; i--) {
      String letter = _alphabet[i];
      int gapIndex = _nameGapIndices[letter] ?? 0;
      int loadedAccounts = _accounts?[letter]?.length ?? 0;
      if (_hasLoadedAllAccountsForLetter(letter: letter)) {
        previousLetterAccounts.addAll(_accounts?[letter]?.reversed ?? []);
      } else {
        if (gapIndex < loadedAccounts) {
          previousLetterAccounts.addAll(_accounts?[letter]?.sublist(gapIndex).reversed ?? []);
        }
        break;  // have not loaded all accounts for this letter, do not go to the one before this in alphabet
      }
    }

    List<Auth2PublicAccount> currentAndNextLetterAccounts = [];
    for (int i = _letterIndex; i < _alphabet.length; i++) {
      String letter = _alphabet[i];
      int gapIndex = _nameGapIndices[letter] ?? 0;
      if (_hasLoadedAllAccountsForLetter(letter: letter) || (gapIndex == 0 && i == _letterIndex)) {
        currentAndNextLetterAccounts.addAll(_accounts?[letter] ?? []);
      } else {
        if (gapIndex > 0) {
          currentAndNextLetterAccounts.addAll(_accounts?[letter]?.sublist(0, gapIndex) ?? []);
        }
        break;  // have not loaded all accounts for this letter, do not go to the one after this in alphabet
      }
    }

    return [
      ...previousLetterAccounts.reversed,
      ...currentAndNextLetterAccounts,
    ];
  }

  bool _hasLoadedAllAccountsForLetter({String? letter}) {
    letter ??= currentLetter;
    int? loadedAccounts = _accounts?[letter]?.length;
    int? letterAccounts = _letterCounts?[letter];
    return letterAccounts == null || (loadedAccounts != null && loadedAccounts >= letterAccounts);
  }

  String? _getOffset({bool reverse = false, bool init = false}) {
    if (!init) {
      String firstDisplayLastName = _firstDisplayAccount?.profile?.lastName ?? '';
      String lastDisplayLastName = _lastDisplayAccount?.profile?.lastName ?? '';
      if (currentLetter.compareTo(firstDisplayLastName.toLowerCase()) > 0 && currentLetter.compareTo(lastDisplayLastName.toLowerCase()) < 0) {
        return reverse ? '${_firstDisplayAccount?.profile?.lastName},${_firstDisplayAccount?.profile?.firstName},${_firstDisplayAccount?.id}' :
          '${_lastDisplayAccount?.profile?.lastName},${_lastDisplayAccount?.profile?.firstName},${_lastDisplayAccount?.id}';
      } else if (!reverse && lastDisplayLastName.toLowerCase().startsWith(currentLetter)) {
        return '${_lastDisplayAccount?.profile?.lastName},${_lastDisplayAccount?.profile?.firstName},${_lastDisplayAccount?.id}';
      } else if (reverse && firstDisplayLastName.toLowerCase().startsWith(currentLetter)) {
        return '${_firstDisplayAccount?.profile?.lastName},${_firstDisplayAccount?.profile?.firstName},${_firstDisplayAccount?.id}';
      }
    }
    return currentLetter;
  }

  void _updateAlphabet() {
    Set<String> newAlphabet = _letterCounts?.keys.where((letter) => (_letterCounts?[letter] ?? 0) > 0).toSet() ?? {};
    Set<String> currentAlphabet = _alphabet.toSet();
    if (newAlphabet.difference(currentAlphabet).isNotEmpty || currentAlphabet.difference(newAlphabet).isNotEmpty) {
      _alphabet = newAlphabet.toList()..sort((a, b) => a.compareTo(b));
      widget.onUpdateAlphabet?.call();
    }
  }

  bool get _canExtend => currentLetter != _alphabet.last || (_nameGapIndices[currentLetter] == _accounts?[currentLetter]?.length && !_hasLoadedAllAccountsForLetter(letter: currentLetter));
  bool get _canReverseExtend => currentLetter != _alphabet.first || _nameGapIndices[currentLetter] == 0;

  String get currentLetter => _alphabet[_letterIndex];
  String get previousLetter => _alphabet[_letterIndex - 1];
  List<String> get alphabet => _alphabet;

  Auth2PublicAccount? get _firstDisplayAccount => _displayAccounts.isNotEmpty ? _displayAccounts.first : null;
  Auth2PublicAccount? get _lastDisplayAccount => _displayAccounts.isNotEmpty ? _displayAccounts.last : null;
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