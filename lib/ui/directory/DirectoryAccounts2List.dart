import 'dart:collection';
import 'dart:core';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart' as illinois;
import 'package:illinois/ui/directory/DirectoryAccountsList.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/auth2.directory.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/auth2.directory.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

enum _ContentMode { directory, filter, }

class DirectoryAccounts2List extends StatefulWidget {
  final Widget? listHeader;
  final String? searchText;
  final Map<String, dynamic>? filterAttributes;

  _ContentMode get _contentMode => ((searchText?.isNotEmpty != true) && (filterAttributes?.isNotEmpty != true)) ?
    _ContentMode.directory : _ContentMode.filter;
  bool get _directoryMode => (_contentMode == _ContentMode.directory);
  bool get _filterMode => (_contentMode == _ContentMode.filter);

  DirectoryAccounts2List({ super.key, this.listHeader, this.searchText, this.filterAttributes, });

  @override
  State<StatefulWidget> createState() => _DirectoryAccounts2ListState();
}

class _DirectoryAccounts2ListState extends State<DirectoryAccounts2List> with NotificationsListener, AutomaticKeepAliveClientMixin<DirectoryAccounts2List> {

  GlobalKey _listViewKey = GlobalKey();
  ScrollController _scrollController = ScrollController();

  LinkedHashMap<String, _SectionContent>? _contentMap;
  List<_DisplayListItem>? _displayList;
  ContentActivity? _contentActivity;
  Map<String, GlobalKey> _extendDetectorKeys = <String, GlobalKey>{};
  bool _canExtendFilteredContent = false;
  String? _expandedAccountId;

  bool get _defaultExtended => widget._filterMode;

  String _directoryPhotoImageToken = DirectoryProfilePhotoUtils.newToken;
  String _userPhotoImageToken = DirectoryProfilePhotoUtils.newToken;

  static const int _sectionContentPageLength = 128;
  static const int _filteredContentPageLength = 128;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      illinois.Auth2.notifyProfilePictureChanged,
      Auth2.notifyProfileChanged,
      Auth2.notifyPrivacyChanged,
      Auth2.notifyLoginChanged,
    ]);
    _scrollController.addListener(_scrollListener);
    if (widget._directoryMode) {
      _initDirectoryContent();
    }
    else if (widget._filterMode) {
      _initFilteredContent();
    }
    super.initState();
  }


  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DirectoryAccounts2List oldWidget) {
    if ((widget._contentMode != oldWidget._contentMode) ||
        (widget._filterMode && ((widget.searchText != oldWidget.searchText) || !DeepCollectionEquality().equals(widget.filterAttributes, oldWidget.filterAttributes)) ))
    {
      if (widget._directoryMode) {
        _initDirectoryContent();
      }
      else if (widget._filterMode) {
        _initFilteredContent();
      }
    }
    super.didUpdateWidget(oldWidget);
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
        //TBD refresh();
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(onRefresh: _onRefresh, child:
      _widgetContent
    );
  }

  Widget get _widgetContent {
    if (_contentActivity == ContentActivity.reload) {
      return _loadingContent;
    }
    else if (_contentActivity == ContentActivity.refresh) {
      return Container();
    }
    else if (_displayList == null) {
      return _buildMessageContent(Localization().getStringEx('', 'Failed to load directory accounts'),
        title: Localization().getStringEx('common.label.failed', 'Failed')
      );
    }
    else if (_displayList?.length == 0) {
      return _buildMessageContent(Localization().getStringEx('panel.group.home2.empty.text', 'There are no groups matching the selected filters.'));
    }
    else {
      return _listContent;
    }
  }

  Widget get _listContent =>
    ListView.builder(
      key: _listViewKey,
      controller: _scrollController,
      physics: BouncingScrollPhysics(),
      itemCount: _displayList?.length ?? 0,
      itemBuilder: _buildDisplayListItem,
      scrollDirection: Axis.vertical,
    );


  Widget? _buildDisplayListItem(BuildContext context, int index) {
    _DisplayListItem? displayListItem = ListUtils.entry(_displayList, index);
    if (displayListItem is _SectionHeadingListItem) {
      return _buildSection(displayListItem.section, expanded: (_contentMap?[displayListItem.section]?.expanded == true));
    } else if (displayListItem is _SplitterListItem) {
      return Divider(height: _dividerHeight, color: Styles().colors.surfaceAccent,);
    //} else if (displayListItem is _SpacerListItem) {
    //  return SizedBox(height: displayListItem.height);
    } else if (displayListItem is _ProgressListItem) {
      return _progressListItem;
    } else if (displayListItem is _MessageListItem) {
      return _buildMessageListItem(displayListItem.message);
    } else if (displayListItem is _ExtendDetectorListItem) {
      return _buildSectionExtendDetectorListItem(displayListItem.section);
    } else if (displayListItem is _WidgetListItem) {
      return displayListItem.widget;
    } else if (displayListItem is _AccountListItem) {
      return Padding(padding: _accountCardPadding, child:
        DirectoryAccountListCard(displayListItem.account,
          photoImageToken: (displayListItem.account.id == Auth2().accountId) ? _userPhotoImageToken : _directoryPhotoImageToken,
          expanded: (_expandedAccountId != null) && (displayListItem.account.id == _expandedAccountId),
          onToggleExpanded: () => _onToggleAccountExpanded(displayListItem.account.id),
        )
      );
    } else {
      return null;
    }
  }

  Widget _buildSection(String name, { bool expanded = false}) =>
    InkWell(onTap: () => _onToggleSection(name), child:
      Row(children: [
        Padding(padding: _sectionIconPadding, child:
          Styles().images.getImage((expanded == true) ? 'chevron2-up' : 'chevron2-down', color: Styles().colors.fillColorSecondary, size: _sectionIconSize, excludeFromSemantics: true)
        ),
        Expanded(child:
          Padding(padding: _sectionTextPadding, child:
            Text(name, style: Styles().textStyles.getTextStyle('widget.title.regular.fat'),)
          )
        )
      ],),
    );

  static const EdgeInsetsGeometry _sectionIconPadding = const EdgeInsetsGeometry.all(
    _sectionIconPaddingSize
  );
  static const double _sectionIconPaddingSize = 16;
  static const double _sectionIconSize = 16;

  static const EdgeInsetsGeometry _sectionTextPadding = const EdgeInsetsGeometry.only(
    top: _sectionTextPaddingV,
    bottom: _sectionTextPaddingV,
    right: _sectionTextPaddingH
  );
  static const double _sectionTextPaddingV = 8;
  static const double _sectionTextPaddingH = 16;

  // Group Card

  static const EdgeInsetsGeometry _accountCardPadding = const EdgeInsetsGeometry.symmetric(
    horizontal: _accountCardPaddingH,
  );
  static const double _accountCardPaddingH = 16;

  // Divider

  static const double _dividerHeight = 1;

  // Progress

  Widget get _progressListItem =>
    Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 16, vertical: 48), child:
      Center(child:
        SizedBox.square(dimension: 16, child:
          CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary,)
        )
      )
    );

  // Message

  Widget _buildMessageListItem(String message) =>
    Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 48, vertical: 32), child:
      Center(child:
        Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.item.regular.thin'),),
      )
    );

  // ExtendDetector

  Widget _buildSectionExtendDetectorListItem(String section) =>
    VisibilityDetector(
      key: _extendDetectorKeys[section] ??= GlobalKey(),
      onVisibilityChanged: (info) => _onSectionExtendDetectorVisibilityChanged(section, info),
      child: Container(height: 0.1),
    );

  // Other Content Types
  Widget _buildMessageContent(String message, { String? title }) =>
    SingleChildScrollView(physics: BouncingScrollPhysics(), child:
      Center(child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: _screenHeight / 6), child:
          Column(children: [
            (title != null) ? Padding(padding: EdgeInsets.only(bottom: 12), child:
              Text(title, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.item.medium.fat'),)
            ) : Container(),
            Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle((title != null) ? 'widget.item.regular.thin' : 'widget.item.medium.fat'),),
          ],),
        )
      )
    );

  Widget get _loadingContent =>
    Column(children: [
      Expanded(flex: 1, child: Container()),
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary,)
      ),
      Expanded(flex: 2, child: Container()),
    ],);

  double get _screenHeight => MediaQuery.of(context).size.height;

  // Data

  Future<void> _initDirectoryContent() async {
    if (_contentActivity != ContentActivity.reload) {
      setState(() {
        _contentActivity = ContentActivity.reload;
      });

      List<Auth2PublicAccountSection>? sections = await Auth2().loadDirectoryAccountSections(
        search: StringUtils.ensureEmpty(widget.searchText),
        attriutes: widget.filterAttributes,
      );

      if (mounted && (_contentActivity == ContentActivity.reload)) {
        setState(() {
          _contentMap = (sections != null) ? _ContentMapImpl.buildFromSections(sections,
            defaultExpnded: _defaultExtended
          ) : null;
          _displayList = _buildDisplayList(_contentMap);
          _contentActivity = null;
        });
      }
    }
  }

  Future<void> _initFilteredContent() async {
    if (_contentActivity != ContentActivity.reload) {
      setState(() {
        _contentActivity = ContentActivity.reload;
      });

      List<Auth2PublicAccount>? accounts = await Auth2().loadDirectoryAccounts(
        search: StringUtils.ensureEmpty(widget.searchText),
        attriutes: widget.filterAttributes,
        offset: 0, limit: _filteredContentPageLength,
      );

      if (mounted && (_contentActivity == ContentActivity.reload)) {
        setState(() {
          if (accounts != null) {
            _contentMap = LinkedHashMap<String, _SectionContent>();
            _contentMap?.fillAccounts(accounts, defaultExpnded: _defaultExtended);
            _displayList = _buildDisplayList(_contentMap);
            _canExtendFilteredContent = (accounts.length >= _filteredContentPageLength);
          }
          _contentActivity = null;
        });
      }
    }
  }

  List<_DisplayListItem>? _buildDisplayList(LinkedHashMap<String, _SectionContent>? contentMap) {
    if (contentMap != null) {
      List<_DisplayListItem> displayList = <_DisplayListItem>[];
      if (widget.listHeader != null) {
        displayList.add(_WidgetListItem(widget.listHeader ?? Container()));
      }
      for (String section in contentMap.keys) {
        _SectionContent? sectionContent = contentMap[section];
        displayList.add(_SplitterListItem());
        displayList.add(_SectionHeadingListItem(section));
        if ((sectionContent != null) && sectionContent.expanded) {
          displayList.addAll(_buildDisplaySectionContent(sectionContent, section: section));
        }
      }
      if (widget._filterMode && (_contentActivity?.extending == true)) {
        displayList.addAll(<_DisplayListItem>[_SplitterListItem(), _ProgressListItem()]);
      }
      if (displayList.isNotEmpty) {
        displayList.add(_SplitterListItem());
      }
      return displayList;
    } else {
      return null;
    }
  }

  List<_DisplayListItem> _buildDisplaySectionContent(_SectionContent sectionContent, { String? section }) {
    List<Auth2PublicAccount>? sectionAccounts = sectionContent.accounts;
    if (sectionContent.activity?.loading == true) {
      return <_DisplayListItem>[_SplitterListItem(), _ProgressListItem()];
    } else if (sectionAccounts == null) {
      return <_DisplayListItem>[_SplitterListItem(), _MessageListItem(Localization().getStringEx('', 'Failed to load accounts in this section.'))];
    } else if (sectionAccounts.isEmpty) {
      return <_DisplayListItem>[_SplitterListItem(), _MessageListItem(Localization().getStringEx('', 'No accounts in this section.'))];
    } else {
      List<_DisplayListItem> displayList = <_DisplayListItem>[];
      for (Auth2PublicAccount account in sectionAccounts) {
        displayList.addAll(<_DisplayListItem>[
        _SplitterListItem(),
        _AccountListItem(account),
        ]);
      }

      if (sectionContent.activity?.extending == true) {
        displayList.addAll(<_DisplayListItem>[
          _SplitterListItem(),
          _ProgressListItem(),
        ]);
      } else if (widget._directoryMode && sectionContent.canExtend && (section != null)) {
        displayList.add(_ExtendDetectorListItem(section),);
      }
      return displayList;
    }
  }

  void _onToggleAccountExpanded(String? accountId) {
    Analytics().logSelect(target: 'Expand', source: accountId);
    setState(() {
      _expandedAccountId = (_expandedAccountId != accountId) ? accountId : null;
    });
  }

  Future<void> _onToggleSection(String section) async {
    Analytics().logSelect(target: section);
    _SectionContent? sectionContent = _contentMap?[section];
    if (sectionContent != null) {
      if (sectionContent.expanded) {
        setState(() {
          sectionContent.expanded = false;
          _displayList = _buildDisplayList(_contentMap!);
        });
      }
      else if (widget._filterMode || (sectionContent.accounts != null)) {
        setState(() {
          sectionContent.expanded = true;
          _displayList = _buildDisplayList(_contentMap!);
        });
      }
      else if (widget._directoryMode) {
        // Extend directory section content
        if (sectionContent.activity?.loading != true) {
          setState(() {
            sectionContent.expanded = true;
            sectionContent.activity = ContentActivity.reload;
            _displayList = _buildDisplayList(_contentMap!);
          });

          List<Auth2PublicAccount>? accounts = await Auth2().loadDirectoryAccounts(
            section: section,
            search: StringUtils.ensureEmpty(widget.searchText),
            attriutes: widget.filterAttributes,
            offset: 0, limit: _sectionContentPageLength,
          );

          if (mounted && (sectionContent.activity == ContentActivity.reload)) {
            setState(() {
              sectionContent.activity = null;
              if (accounts != null) {
                sectionContent.accounts = accounts.toList();
                sectionContent.canLoadMoreAccounts = (accounts.length >= _sectionContentPageLength);
              }
              _displayList = _buildDisplayList(_contentMap!);
            });
          }
        }
      }
    }
  }

  void _checkSectionExtendDetectorsVisibility() {
    //TBD: Check if section extend detector is visible using global key's rendering boxes.
    // Extend those that are visible and not currently extending.
    // Example: _GroupHome2PanelState._isCompletelyVisibleInHeight
  }

  Future<void> _onSectionExtendDetectorVisibilityChanged(String section, VisibilityInfo info ) async {
    bool isVisible = !info.visibleBounds.isEmpty;
    _SectionContent? sectionContent = _contentMap?[section];
    if (isVisible && (sectionContent != null)) {
      await _extendSection(section, sectionContent);
    }
  }

  Future<void> _extendSection(String section, _SectionContent sectionContent) async {
    if (sectionContent.activity == null) {
      setState(() {
        sectionContent.activity = ContentActivity.extend;
        _displayList = _buildDisplayList(_contentMap!);
      });

      List<Auth2PublicAccount>? accounts = await Auth2().loadDirectoryAccounts(
        section: section,
        search: StringUtils.ensureEmpty(widget.searchText),
        attriutes: widget.filterAttributes,
        offset: sectionContent.accounts?.length ?? 0,
        limit: _sectionContentPageLength,
      );

      if (mounted && (sectionContent.activity == ContentActivity.extend)) {
        setState(() {
          sectionContent.activity = null;
          if (accounts != null) {
            sectionContent.accounts?.addAll(accounts);
            sectionContent.canLoadMoreAccounts = (accounts.length >= _sectionContentPageLength);
          }
          _displayList = _buildDisplayList(_contentMap!);
        });
      }
    }
  }

  void _scrollListener() {
    if (widget._filterMode) {
      if ((_scrollController.offset >= _scrollController.position.maxScrollExtent) && _canExtendFilteredContent && (_contentActivity == null)) {
        _extendFilteredContent();
      }
    } else if (widget._directoryMode) {
      _checkSectionExtendDetectorsVisibility();
    }
  }

  Future<void> _onRefresh() async {
    if (_contentActivity?.loading != true) {
      if (widget._directoryMode) {
        await _refreshDirectoryContent();
      } else {
        await _refreshFilteredContent();
      }
    }
  }

  Future<void> _refreshDirectoryContent() async {
    if (_contentActivity?.loading != true) {
      setState(() {
        _contentActivity = ContentActivity.refresh;
      });

      List<Future<dynamic>> requestFutures = <Future<dynamic>>[
        Auth2().loadDirectoryAccountSections(
          search: StringUtils.ensureEmpty(widget.searchText),
          attriutes: widget.filterAttributes,
        ),
      ];

      Map<String, int> sectionToFutureIndex = <String, int>{};
      if (_contentMap != null) {
        for (String section in _contentMap?.keys ?? []) {
          _SectionContent? sectionContent = _contentMap?[section];
          if ((sectionContent?.expanded == true) || (sectionContent?.accounts != null)) {
            sectionToFutureIndex[section] = requestFutures.length;
            requestFutures.add(Auth2().loadDirectoryAccounts(
              section: section,
              search: StringUtils.ensureEmpty(widget.searchText),
              attriutes: widget.filterAttributes,
              offset: 0,
              limit: max(sectionContent?.accounts?.length ?? 0, _sectionContentPageLength),
            ));
          }
        }
      }

      List<dynamic> futureResponses = await Future.wait(requestFutures);

      if (mounted && (_contentActivity == ContentActivity.refresh)) {
        List<Auth2PublicAccountSection>? sections = JsonUtils.cast(futureResponses.first);
        if (sections != null) {
          Map<String, List<Auth2PublicAccount>?> sectionAccountsMap = sectionToFutureIndex.map((String section, int futureIndex) => MapEntry(section, JsonUtils.cast(ListUtils.entry(futureResponses, futureIndex))));
          LinkedHashMap<String, _SectionContent> contentMap = _ContentMapImpl.buildFromSections(sections,
            sectionAccountsMap: sectionAccountsMap,
            sectionContentPageLength: _sectionContentPageLength,
            sourceContentMap: _contentMap,
            defaultExpnded: _defaultExtended
          );
          setState(() {
            _contentMap = contentMap;
            _displayList = _buildDisplayList(_contentMap);
            _contentActivity = null;
          });
        } else {
          setState(() {
            _contentActivity = null;
          });
        }
      }
    }
  }

  Future<void> _refreshFilteredContent() async {
    if (_contentActivity?.loading != true) {
      setState(() {
        _contentActivity = ContentActivity.refresh;
      });

      int requestLimit = max(_contentMap?.totalAccountsCount ?? 0, _filteredContentPageLength);
      List<Auth2PublicAccount>? accounts = await Auth2().loadDirectoryAccounts(
        search: StringUtils.ensureEmpty(widget.searchText),
        attriutes: widget.filterAttributes,
        offset: 0, limit: requestLimit,
      );

      if (mounted && (_contentActivity == ContentActivity.refresh)) {
        if (accounts != null) {
          LinkedHashMap<String, _SectionContent> contentMap = LinkedHashMap<String, _SectionContent>();
          contentMap.fillAccounts(accounts,
            sourceContentMap: _contentMap,
            defaultExpnded: _defaultExtended
          );
          setState(() {
            _contentMap = contentMap;
            _displayList = _buildDisplayList(_contentMap);
            _canExtendFilteredContent = (accounts.length >= _filteredContentPageLength);
            _contentActivity = null;
          });
        } else {
          setState(() {
            _contentActivity = null;
          });
        }
      }
    }
  }

  Future<void> _extendFilteredContent() async {
    if (_contentActivity == null) {
      setState(() {
        _contentActivity = ContentActivity.extend;
      });

      List<Auth2PublicAccount>? accounts = await Auth2().loadDirectoryAccounts(
        search: StringUtils.ensureEmpty(widget.searchText),
        attriutes: widget.filterAttributes,
        offset: _contentMap?.totalAccountsCount ?? 0,
        limit: _filteredContentPageLength,
      );

      if (mounted && (_contentActivity == ContentActivity.extend)) {
        if (accounts != null) {
          setState(() {
            _contentMap ??= LinkedHashMap<String, _SectionContent>();
            _contentMap?.fillAccounts(accounts,
              defaultExpnded: _defaultExtended
            );
            _displayList = _buildDisplayList(_contentMap);
            _canExtendFilteredContent = (accounts.length >= _filteredContentPageLength);
            _contentActivity = null;
          });
        } else {
          setState(() {
            _contentActivity = null;
          });
        }
      }
    }
  }
}

class _SectionContent {
  List<Auth2PublicAccount>? accounts;
  final int? accountsCount;
  bool canLoadMoreAccounts;
  bool expanded;
  ContentActivity? activity;

  _SectionContent({this.accounts, this.accountsCount, this.canLoadMoreAccounts = false, this.expanded = false});

  bool get canExtend => (accountsCount != null) ? ((accounts?.length ?? 0) < (accountsCount ?? 0)) : canLoadMoreAccounts;
}

extension _ContentMapImpl on LinkedHashMap<String, _SectionContent> {

  static LinkedHashMap<String, _SectionContent> buildFromSections(List<Auth2PublicAccountSection> sections, {
    Map<String, List<Auth2PublicAccount>?>? sectionAccountsMap,
    int? sectionContentPageLength,
    LinkedHashMap<String, _SectionContent>? sourceContentMap,
    required bool defaultExpnded,
  }) {
    LinkedHashMap<String, _SectionContent> contentMap = LinkedHashMap<String, _SectionContent>();
    for (Auth2PublicAccountSection section in sections) {
      String? sectionName = section.name;
      if (sectionName != null) {
        List<Auth2PublicAccount>? sectionAccounts = sectionAccountsMap?[sectionName];
        contentMap[sectionName] = _SectionContent(
          accounts: sectionAccounts?.toList(),
          accountsCount: section.accountsCount,
          canLoadMoreAccounts: (sectionAccounts != null) && (sectionContentPageLength != null) && (sectionAccounts.length >= sectionContentPageLength),
          expanded: sourceContentMap?[sectionName]?.expanded ?? defaultExpnded,
        );
      }
    }
    return contentMap;
  }

  void fillAccounts(List<Auth2PublicAccount> accounts, {
    LinkedHashMap<String, _SectionContent>? sourceContentMap,
    required bool defaultExpnded,
  }) {
    for (Auth2PublicAccount account in accounts) {
      String? sectionName = account.directoryKey;
      if (sectionName != null) {
        _SectionContent? sectionContent = this[sectionName];
        if (sectionContent != null) {
          if (sectionContent.accounts != null) {
            sectionContent.accounts?.add(account);
          } else {
            sectionContent.accounts = <Auth2PublicAccount>[account];
          }
        } else {
          this[sectionName] = _SectionContent(
            accounts: <Auth2PublicAccount>[account],
            expanded: sourceContentMap?[sectionName]?.expanded ?? defaultExpnded,
          );
        }
      }
    }
  }

  int get totalAccountsCount {
    int totalAccountsCount = 0;
    for (_SectionContent sectionContent in values) {
      totalAccountsCount += (sectionContent.accounts?.length ?? 0);
    }
    return totalAccountsCount;
  }
}

abstract class _DisplayListItem {}

class _SectionHeadingListItem extends _DisplayListItem {
  final String section;
  _SectionHeadingListItem(this.section);
}

class _SplitterListItem extends _DisplayListItem {
  _SplitterListItem();
}

/*class _SpacerListItem extends _DisplayListItem {
  final double height;
  _SpacerListItem(this.height);
}*/

class _AccountListItem extends _DisplayListItem {
  final Auth2PublicAccount account;
  _AccountListItem(this.account);
}

class _ProgressListItem extends _DisplayListItem {
  _ProgressListItem();
}

class _MessageListItem extends _DisplayListItem {
  final String message;
  _MessageListItem(this.message);
}

class _ExtendDetectorListItem extends _DisplayListItem {
  final String section;
  _ExtendDetectorListItem(this.section);

  //Key get key => Key();
}

class _WidgetListItem extends _DisplayListItem {
  final Widget widget;
  _WidgetListItem(this.widget);
}

