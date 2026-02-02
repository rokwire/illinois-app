
import 'dart:math';

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

class DirectoryAccountsList extends StatefulWidget {
  final DirectoryDisplayMode displayMode;
  final ScrollController? scrollController;
  final String? searchText;
  final Map<String, dynamic>? filterAttributes;
  final Set<String>? selectedAccountIds;
  final void Function(Auth2PublicAccount, bool)? onAccountSelectionChanged;

  DirectoryAccountsList({ super.key, this.displayMode = DirectoryDisplayMode.browse, this.scrollController,
    this.searchText, this.filterAttributes, this.onAccountSelectionChanged, this.selectedAccountIds});

  @override
  State<StatefulWidget> createState() => DirectoryAccountsListState();
}

class DirectoryAccountsListState extends State<DirectoryAccountsList> with NotificationsListener, AutomaticKeepAliveClientMixin<DirectoryAccountsList>  {

  Map<String, List<Auth2PublicAccount>>? _accounts;
  bool _loading = false;
  bool _loadingProgress = false;
  bool _extending = false;
  Map<String, dynamic> _extendingTasks = <String, dynamic>{};
  bool _canExtend = false;
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
        if ((accounts[index]?.isNotEmpty == true)) {
          if (contentList.isNotEmpty) {
            contentList.add(Padding(padding: EdgeInsets.only(bottom: 0), child: _sectionSplitter));
          }
          contentList.add(DirectoryExpandableSection(
            expanded: _expandedSections,
            accountsExtender: _expandedSections ? null : _extend, //TBD Test
            index: index,
            accounts: accounts[index],
            extending: _extendingTasks[index] != null,
            itemBuilder: (account) => DirectoryAccountListCard(account,
              displayMode: widget.displayMode,
              photoImageToken: (account.id == Auth2().accountId) ? _userPhotoImageToken : _directoryPhotoImageToken,
              expanded: (_expandedAccountId != null) && (account.id == _expandedAccountId),
              onToggleExpanded: () => _onToggleAccountExpanded(account),
              selected: widget.selectedAccountIds?.contains(account.id) == true,
              onToggleSelected: (value) => _onToggleAccountSelected(account, value),
            ),
          ));
        }
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
    if ((scrollController != null) && (scrollController.offset >= scrollController.position.maxScrollExtent) && _canExtend && !_loading && !_extending) {
      if(_expandedSections)//Extend only if we are  in expandedSections mode
        _extend();
    }
  }

  Future<void> _load({ int limit = _pageLength, bool silent = false }) async {
    if (!_loading) {
      setStateIfMounted(() {
        _loading = true;
        _loadingProgress = !silent;
        _extending = false;
      });

      List<Auth2PublicAccount>? accounts = await Auth2().loadDirectoryAccounts(
        search: StringUtils.ensureEmpty(widget.searchText),
        attriutes: widget.filterAttributes,
        limit: limit,
      );

      setStateIfMounted(() {
        _loading = false;
        _loadingProgress = false;
        if (accounts != null) {
          _accounts = accounts.groupListsBy((account) => account.directoryKey ?? "");
          _canExtend = (accounts.length >= limit);
        }
        else if (!silent) {
          _accounts = null;
          _canExtend = false;
        }
      });
    }
  }

  Future<void> refresh() =>
    _load(limit: max(_accountsCount, _pageLength), silent: true);

  Future<void> _extend({String? index, int? offset, int limit = _pageLength}) async {
    Log.d('DirectoryAccountsListState._extend index: $index');
    offset ??= _accountsCount;
    if (!_loading && !_isExtending(index)) {
      setStateIfMounted(() {
        if(index != null) //We load for single section //TBD test
          _extendingTasks[index] = true;
        else
        _extending = true;
      });
      //TBD synchronise extension of multiple sections
      List<Auth2PublicAccount>? accounts = await Auth2().loadDirectoryAccounts(
        index: index,
        search: StringUtils.ensureEmpty(widget.searchText),
        attriutes: widget.filterAttributes,
        offset: offset,
        limit: limit
      );

      if (mounted && !_loading && _isExtending(index)) {
        setState(() {
          if (accounts != null) {
            if (_accounts != null) {
              if(index != null){ //We load for single section //TBD test
                (_accounts?[index] ??= <Auth2PublicAccount>[])?.addAll(accounts);
              } else {
                Map<String, List<Auth2PublicAccount>> groupedNewAccounts = accounts.groupListsBy((account) => account.directoryKey ?? "");
                MapUtils.mergeGroupedListMaps(
                    _accounts ?? <String, List<Auth2PublicAccount>>{},
                    groupedNewAccounts);
              }
            }
            else {
              _accounts = accounts.groupListsBy((account) => account.directoryKey ?? "");
            }

            _canExtend = (accounts.length >= _pageLength);
          }
          _extending = false;
          if(index != null)
            _extendingTasks.remove(index);
        });
      }
    }
  }

  int get _accountsCount {
      int count = 0;
      _accounts?.forEach((key, value) => count += value.length);
      return count;
  }

  bool get _expandedSections => StringUtils.isNotEmpty(widget.searchText); //If we show all expanded sections then we load and extend all sections as one. Otherwise each section is extending by itself.

  bool _isExtending(String? index) => (index != null && _extendingTasks[index] != null) || _extending;
}

extension _Auth2PublicAccountUtils on Auth2PublicAccount {
  String? get directoryKey => (profile?.lastName?.isNotEmpty == true) ?
    profile?.lastName?.substring(0, 1).toUpperCase() : null;
}

