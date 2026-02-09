
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart' as illinois;
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.directory.dart';
import 'package:rokwire_plugin/service/Log.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/auth2.directory.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class DirectoryAccountsList2 extends StatefulWidget {
  final DirectoryDisplayMode displayMode;
  final ScrollController? scrollController;
  final String? searchText;
  final Map<String, dynamic>? filterAttributes;
  final Set<String>? selectedAccountIds;
  final void Function(Auth2PublicAccount, bool)? onAccountSelectionChanged;

  DirectoryAccountsList2({ super.key, this.displayMode = DirectoryDisplayMode.browse, this.scrollController,
    this.searchText, this.filterAttributes, this.onAccountSelectionChanged, this.selectedAccountIds});

  @override
  State<StatefulWidget> createState() => DirectoryAccountsList2State();
}

class DirectoryAccountsList2State extends State<DirectoryAccountsList2> with NotificationsListener, AutomaticKeepAliveClientMixin<DirectoryAccountsList2>  {
  static const int _pageLength = 32; //TBD test
  static const String _globalExtendingKey = 'global';

  Map<String, List<Auth2PublicAccount>>? _accounts;
  bool _loading = false;
  bool _loadingProgress = false;

  Map<String, int> _previousExtendingLengths = <String, int>{};
  Map<String, Completer<void>> _extendingTasks = <String, Completer<void>>{};

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

    _isGlobalSectionMode ? _loadAccounts() : _loadIndexes();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    widget.scrollController?.removeListener(_scrollListener);
    super.dispose();
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
      return _messageContent(Localization().getStringEx('panel.directory.accounts.directory.failed.text', 'Failed to load Directory of Users content.'));
    }
    else if (_accounts?.isEmpty == true) {
      return _messageContent(Localization().getStringEx('panel.directory.accounts.directory.empty.text', 'No results found.'));
    }
    else {
      return _accountsContent;
    }
  }

  Widget get _accountsContent {
    List<Widget> contentList = <Widget>[];

    Map<String, List<Auth2PublicAccount>>? accounts = _accounts;
    if ((accounts != null) && accounts.isNotEmpty) {
      contentList.add(Padding(padding: EdgeInsets.only(bottom: 0), child: _sectionSplitter));

      for (String index in accounts.keys) {
        // if ((accounts[index]?.isNotEmpty == true)) {
          if (contentList.isNotEmpty) {
            contentList.add(Padding(padding: EdgeInsets.only(bottom: 0), child: _sectionSplitter));
          }
          contentList.add(DirectoryExpandableSection(
            initExpanded: _expandAllSections,
            accountsExtender: _isGlobalSectionMode ? null : _extend,
            index: index,
            accounts: accounts[index],
            extending: _isExtending(index),
            itemBuilder: (account) => DirectoryAccountListCard(account,
              displayMode: widget.displayMode,
              photoImageToken: (account.id == Auth2().accountId) ? _userPhotoImageToken : _directoryPhotoImageToken,
              expanded: (_expandedAccountId != null) && (account.id == _expandedAccountId),
              onToggleExpanded: () => _onToggleAccountExpanded(account),
              selected: widget.selectedAccountIds?.contains(account.id) == true,
              onToggleSelected: (value) => _onToggleAccountSelected(account, value),
            ),
          ));
        // }
      }
      if (contentList.isNotEmpty) {
        contentList.add(Padding(padding: EdgeInsets.only(bottom: 16), child: _sectionSplitter));
      }
    }

    if (_isExtending(_globalExtendingKey)) {
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


  void _scrollListener() {
    ScrollController? scrollController = widget.scrollController;
    if ((scrollController != null) && (scrollController.offset >= scrollController.position.maxScrollExtent) && _canExtend(_globalExtendingKey) && !_loading && !_isExtending(_globalExtendingKey)) {
      if(_isGlobalSectionMode)//Extend only if we are  in expandedSections mode
        _extend();
    }
  }

  Future<void> _loadIndexes({ bool silent = false }) async {
    if(!_loading){
       setState(() {
          _loading = true;
          _loadingProgress = !silent;
       });
    }
    List<String>? indexes = await Auth2().loadDirectoryAccountsIndexes();
    setStateIfMounted(() {
      _loading = false;
      _loadingProgress = false;
      if (indexes != null) {
        _accounts = Map<String, List<Auth2PublicAccount>>.fromIterable(indexes, key: (index) => index, value: (index) => <Auth2PublicAccount>[]);
      }
    });
  }

  Future<void> _loadAccounts({ int limit = _pageLength, bool silent = false }) async {
    if (!_loading) {
      setStateIfMounted(() {
        _loading = true;
        _loadingProgress = !silent;
      });

      List<Auth2PublicAccount>? accounts = await Auth2().loadDirectoryAccounts(
        search: StringUtils.ensureEmpty(widget.searchText),
        attriutes: widget.filterAttributes,
        limit: limit,
      );

      _previousExtendingLengths[_globalExtendingKey] = accounts?.length ?? 0;

      setStateIfMounted(() {
        _loading = false;
        _loadingProgress = false;
        if (accounts != null) {
          _accounts = accounts.groupListsBy((account) => account.directoryKey ?? "");
        }
      });
    }
  }

  Future<void> refresh() async {//Disable refresh for now. Implement it if requested
    // return _loadAccounts(limit: max(_getAccountsCount(_globalExtendingKey), _pageLength), silent: true);
  }


  Future<void> _extend({String? index, int limit = _pageLength}) async {
    String taskKey = index ?? _globalExtendingKey;

    if(_loading || _isExtending(taskKey) || !_canExtend(taskKey))
      return;

    Completer<void> taskCompleter = Completer<void>();
    try{
      Log.d("DirectoryAccountsListState._extend() index: $index");
      setStateIfMounted(() {
        _extendingTasks[taskKey] = taskCompleter;
      });

      List<Auth2PublicAccount>? accounts = await Auth2().loadDirectoryAccounts(
          index: index,
          search: StringUtils.ensureEmpty(widget.searchText),
          attriutes: widget.filterAttributes,
          offset: _getAccountsCount(index),
          limit: limit
      );

      _previousExtendingLengths[taskKey] = accounts?.length ?? 0;

      if (mounted && !_loading) {
        setState(() {
          if (accounts != null) {
            if (_accounts != null) {
              if(index != null){ //We load for single section
                (_accounts?[index] ??= <Auth2PublicAccount>[])?.addAll(accounts);
              } else { //We load Globally
                Map<String, List<Auth2PublicAccount>> groupedNewAccounts = accounts.groupListsBy((account) => account.directoryKey ?? "");
                mergeGroupedListMaps(
                    _accounts ?? <String, List<Auth2PublicAccount>>{},
                    groupedNewAccounts);
              }
            } else {
              _accounts = accounts.groupListsBy((account) => account.directoryKey ?? "");
            }
          }
        });
      }
    } catch(e){
      Log.d("Extending error: $e");
    } finally {
      _extendingTasks.remove(taskKey);
      taskCompleter.complete();
    }
  }

  bool _isExtending(String? extendingKey) => _extendingTasks.containsKey(extendingKey ?? _globalExtendingKey) &&
      _extendingTasks[extendingKey ?? _globalExtendingKey]?.isCompleted == false;

  bool _canExtend(String? extendingKey) => _previousExtendingLengths.containsKey(extendingKey) == false || //First time loading
      (_previousExtendingLengths[extendingKey] ?? 0) >= _pageLength; //Reached the limit when extending

  int  _getAccountsCount(String? index) {
    if(index != null && index != _globalExtendingKey)
      return _accounts?[index]?.length ?? 0;
    else { //Global
      int count = 0;
      _accounts?.forEach((key, value) => count += value.length);
      return count;
    }
  }
  bool get _expandAllSections => StringUtils.isNotEmpty(widget.searchText); //TBD replace with _isGlobalSectionMode when hooked to APIs

  bool get _isGlobalSectionMode => //true; //TBD use when sections API is done until then treat as single section
      StringUtils.isNotEmpty(widget.searchText); //If we have searchText we treat all sections as one and we load them together. Otherwise each section is extending by itself.

  /// Merges grouped  [newMap] into an [existingMap].
  static void mergeGroupedListMaps<K, V>(Map<K, List<V>> existingMap, Map<K, List<V>> newMap) {
    newMap.forEach((key, newList) {
      // If the key already exists, add the new items to the existing list.
      // Otherwise, create a new entry with the new list.
      (existingMap[key] ??= <V>[]).addAll(newList);
    });
  }
}

extension _Auth2PublicAccountUtils on Auth2PublicAccount {
  String? get directoryKey => (profile?.lastName?.isNotEmpty == true) ?
    profile?.lastName?.substring(0, 1).toUpperCase() : null;
}

