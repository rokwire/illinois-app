
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart' as illinois;
import 'package:illinois/ui/attributes/ContentAttributesPanel.dart';
import 'package:illinois/ui/profile/ProfileDirectoryPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.directory.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/auth2.directory.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileDirectoryAccountsPage extends StatefulWidget {
  final DirectoryAccounts contentType;
  final ScrollController? scrollController;
  ProfileDirectoryAccountsPage({super.key, required this.contentType, this.scrollController});

  @override
  State<StatefulWidget> createState() => _ProfileDirectoryAccountsPageState();
}

class _ProfileDirectoryAccountsPageState extends State<ProfileDirectoryAccountsPage> implements NotificationsListener  {

  Map<String, List<Auth2PublicAccount>> _accountsMap = <String, List<Auth2PublicAccount>>{};
  String? _errorText;
  String _searchText = '';
  bool _loading = false;
  bool _loadingProgress = false;
  bool _extending = false;
  bool _canExtend = false;
  static const int _pageLength = 32;

  String? _expandedAccountId;

  String _directoryPhotoImageToken = DirectoryProfilePhotoUtils.newToken;
  String _userPhotoImageToken = DirectoryProfilePhotoUtils.newToken;

  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Map<String, dynamic> _filters = <String, dynamic>{};

  @override
  void initState() {
    NotificationService().subscribe(this, [
      illinois.Auth2.notifyProfilePictureChanged,
      Auth2.notifyProfileChanged,
      Auth2.notifyPrivacyChanged,
    ]);
    widget.scrollController?.addListener(_scrollListener);
    _load();
    super.initState();
  }


  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    widget.scrollController?.removeListener(_scrollListener);
    _searchTextController.dispose();
    _searchFocusNode.dispose();
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
    else if ((name == Auth2.notifyProfileChanged) || (name == Auth2.notifyPrivacyChanged)) {
      if (mounted) {
        setState((){
          _userPhotoImageToken = DirectoryProfilePhotoUtils.newToken;
        });
        _refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[
      _searchBarWidget,
    ];
    if (_loadingProgress) {
      contentList.add(_loadingContent);
    }
    else if (_errorText != null) {
      contentList.add(_messageContent(_errorText ?? ''));
    }
    else if (_accountsMap.isEmpty) {
      contentList.add(_messageContent(_emptyText));
    }
    else {
      contentList.add(_accountsContent);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList);
  }

  Widget get _accountsContent {
    List<Widget> sections = <Widget>[];

    int? firstCharCode, lastCharCode;
    _accountsMap.forEach((key, value){
      int charCode = key.codeUnits.first;
      if ((firstCharCode == null) || (charCode < firstCharCode!)) {
        firstCharCode = charCode;
      }
      if ((lastCharCode == null) || (lastCharCode! < charCode)) {
        lastCharCode = charCode;
      }
    });

    if ((firstCharCode != null) && (lastCharCode != null)) {
      for (int charCode = firstCharCode!; charCode <= lastCharCode!; charCode++) {
        String dirEntry = String.fromCharCode(charCode);
        List<Auth2PublicAccount>? accounts = _accountsMap[dirEntry];
        if (accounts != null) {
          sections.addAll(_accountsSection(dirEntry, accounts));
        }
      }
    }

    if (_extending) {
      sections.add(_extendingIndicator);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: sections);
  }

  List<Widget> _accountsSection(String dirEntry, List<Auth2PublicAccount> accounts) {
    List<Widget> result = <Widget>[
      _sectionHeading(dirEntry)
    ];
    for (Auth2PublicAccount account in accounts) {
      result.add(_sectionSplitter);
      result.add(DirectoryAccountCard(account,
        photoImageToken: (account.id == Auth2().accountId) ? _userPhotoImageToken : _directoryPhotoImageToken,
        expanded: (_expandedAccountId != null) && (account.id == _expandedAccountId),
        onToggleExpanded: () => _onToggleAccountExpanded(account),
      ));
    }
    if (accounts.isNotEmpty) {
      result.add(Padding(padding: EdgeInsets.only(bottom: 16), child: _sectionSplitter));
    }
    return result;
  }

  void _onToggleAccountExpanded(Auth2PublicAccount profile) {
    Analytics().logSelect(target: 'Expand', source: profile.id);
    setState(() {
      _expandedAccountId = (_expandedAccountId != profile.id) ? profile.id : null;
    });
  }

  Widget _sectionHeading(String dirEntry) =>
    Padding(padding: EdgeInsets.zero, child:
      Text(dirEntry, style: Styles().textStyles.getTextStyle('widget.title.small.semi_fat'),)
    );

  Widget get _searchBarWidget =>
    Padding(padding: const EdgeInsets.only(bottom: 16), child:
      Row(children: [
        Expanded(child:
          Container(decoration: _searchBarDecoration, padding: EdgeInsets.only(left: 16), child:
            Row(children: <Widget>[
              Expanded(child:
                _searchTextWidget
              ),
              _searchImageButton('close',
                label: Localization().getStringEx('panel.search.button.clear.title', 'Clear'),
                hint: Localization().getStringEx('panel.search.button.clear.hint', ''),
                rightPadding: _searchImageButtonHorzPadding / 2,
                onTap: _onTapClear,
              ),
              _searchImageButton('search',
                label: Localization().getStringEx('panel.search.button.search.title', 'Search'),
                hint: Localization().getStringEx('panel.search.button.search.hint', ''),
                leftPadding: _searchImageButtonHorzPadding / 2,
                onTap: _onTapSearch,
              ),
            ],)
          )
        ),
        Padding(padding: EdgeInsets.only(left: 6), child:
          _filtersButton
        ),
      ],),
    );

    Widget get _searchTextWidget =>
      Semantics(
        label: Localization().getStringEx('panel.profile.directory.accounts.search.field.label', 'SEARCH FIELD'),
        hint: null,
        textField: true,
        excludeSemantics: true,
        value: _searchTextController.text,
        child: TextField(
          controller: _searchTextController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(border: InputBorder.none,),
          style: Styles().textStyles.getTextStyle('widget.input_field.dark.text.regular.thin'),
          cursorColor: Styles().colors.fillColorSecondary,
          keyboardType: TextInputType.text,
          autocorrect: false,
          autofocus: false,
          maxLines: 1,
          onSubmitted: (_) => _onTapSearch(),
      )
    );

  Decoration get _searchBarDecoration => BoxDecoration(
    color: Styles().colors.white,
    border: Border.all(color: Styles().colors.disabledTextColor, width: 1),
    borderRadius: BorderRadius.circular(12),
  );

  Widget _searchImageButton(String image, { String? label, String? hint, double leftPadding = _searchImageButtonHorzPadding, double rightPadding = _searchImageButtonHorzPadding, void Function()? onTap }) =>
    Semantics(label: label, hint: hint, button: true, excludeSemantics: true, child:
      InkWell(onTap: onTap, child:
        Padding(padding: EdgeInsets.only(left: leftPadding, right: rightPadding, top: _searchImageButtonVertPadding, bottom: _searchImageButtonVertPadding), child:
          Styles().images.getImage(image, excludeFromSemantics: true),
        ),
      ),
    );

  static const double _searchImageButtonHorzPadding = 16;
  static const double _searchImageButtonVertPadding = 12;

  Widget get _filtersButton =>
    InkWell(onTap: _onFilter, child:
      Container(decoration: _searchBarDecoration, padding: EdgeInsets.symmetric(vertical: 14, horizontal: 14), child:
        Styles().images.getImage('filters') ?? SizedBox(width: 18, height: 18,),
      ),
    );

  void _onFilter() {
    Analytics().logSelect(target: 'Filters');

    if (Auth2().directoryAttributes != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ContentAttributesPanel(
        title: Localization().getStringEx('panel.profile.directory.accounts.filters.header.title', 'App Directory Filters'),
        description: AppTextUtils.appTitleString('panel.profile.directory.accounts.filters.header.description', 'Choose at leasrt one attribute to filter the ${AppTextUtils.appTitleMacro} App Directory.'),
        scope: Auh2Directory.attributesScope,
        contentAttributes: Auth2().directoryAttributes,
        selection: _filters,
        sortType: ContentAttributesSortType.alphabetical,
        filtersMode: true,
      ))).then((selection) {
        if ((selection != null) && mounted) {
          setState(() {
            _filters = selection;
          });
          _load();
        }
      });
    }

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
      case DirectoryAccounts.myConnections: return AppTextUtils.appTitleString('panel.profile.directory.accounts.connections.empty.text', 'You do not have any ${AppTextUtils.appTitleMacro} Connections. Your connections will appear after you swap info with another ${AppTextUtils.universityLongNameMacro} student or employee.').replaceAll(AppTextUtils.universityLongNameMacro, AppTextUtils.universityLongName);
      case DirectoryAccounts.appDirectory: return AppTextUtils.appTitleString('panel.profile.directory.accounts.directory.empty.text', 'The ${AppTextUtils.appTitleMacro} App Directory is empty.');
    }
  }

  String get _failedText {
    switch (widget.contentType) {
      case DirectoryAccounts.myConnections: return AppTextUtils.appTitleString('panel.profile.directory.accounts.connections.failed.text', 'Failed to load ${AppTextUtils.appTitleMacro} Connections content.');
      case DirectoryAccounts.appDirectory: return AppTextUtils.appTitleString('panel.profile.directory.accounts.directory.failed.text', 'Failed to load ${AppTextUtils.appTitleMacro} App Directory content.');
    }
  }

  void _scrollListener() {
    ScrollController? scrollController = widget.scrollController;
    if ((scrollController != null) && (scrollController.offset >= scrollController.position.maxScrollExtent) && _canExtend && !_loading && !_extending) {
      _extend();
    }
  }

  Future<void> _load({ int limit = _pageLength }) async {
    if (!_loading) {
      setStateIfMounted(() {
        _loading = true;
        _loadingProgress = true;
        _extending = false;
      });

      List<Auth2PublicAccount>? accounts = await Auth2().loadDirectoryAccounts(
        search: StringUtils.ensureEmpty(_searchText),
        limit: limit
      );

      setStateIfMounted(() {
        _loading = false;
        _loadingProgress = false;
        if (accounts != null) {
          _accountsMap = _buildAccounts(accounts);
          _errorText = null;
          _canExtend = (accounts.length >= limit);
        }
        else {
          _accountsMap.clear();
          _errorText = _failedText;
          _canExtend = false;
        }
      });
    }
  }

  Future<void> _refresh() async {
    if (!_loading) {
      setStateIfMounted(() {
        _loading = true;
        _extending = false;
      });

      int limit = max(_accountsCount, _pageLength);
      List<Auth2PublicAccount>? accounts = await Auth2().loadDirectoryAccounts(
        search: StringUtils.ensureEmpty(_searchText),
        limit: limit
      );

      setStateIfMounted(() {
        _loading = false;
        if (accounts != null) {
          _accountsMap = _buildAccounts(accounts);
          _errorText = null;
          _canExtend = (accounts.length >= limit);
        }
      });
    }
  }

  Future<void> _extend() async {
    if (!_loading && !_extending) {
      setStateIfMounted(() {
        _extending = true;
      });

      List<Auth2PublicAccount>? accounts = await Auth2().loadDirectoryAccounts(
        search: StringUtils.ensureEmpty(_searchText),
        offset: _accountsCount,
        limit: _pageLength
      );

      if (mounted && _extending && !_loading) {
        setState(() {
          if (accounts != null) {
            _addAccounts(_buildAccounts(accounts));
            _canExtend = (accounts.length >= _pageLength);
            _errorText = null;
          }
          _extending = false;
        });
      }
    }
  }

  int get _accountsCount {
    int accountsCount = 0;
    for (List<Auth2PublicAccount> entries in _accountsMap.values) {
      accountsCount += entries.length;
    }
    return accountsCount;
  }

  void _addAccounts(Map<String, List<Auth2PublicAccount>> accountsMap) {
    for (String code in accountsMap.keys) {
      List<Auth2PublicAccount>? accounts = accountsMap[code];
      if ((accounts != null) && accounts.isNotEmpty) {
        List<Auth2PublicAccount> codeAccounts = _accountsMap[code] ??= <Auth2PublicAccount>[];
        codeAccounts.addAll(accounts);
      }
    }
  }

  static Map<String, List<Auth2PublicAccount>> _buildAccounts(List<Auth2PublicAccount> accounts) {
    Map<String, List<Auth2PublicAccount>> result = <String, List<Auth2PublicAccount>>{};
    for (Auth2PublicAccount account in accounts) {
      String mapKey = ((account.profile?.lastName?.isNotEmpty == true) ? account.profile?.lastName?.substring(0, 1).toUpperCase() : null) ?? ' ';
      List<Auth2PublicAccount> mapValue = (result[mapKey] ??= <Auth2PublicAccount>[]);
      mapValue.add(account);
    }
    for (List<Auth2PublicAccount> mapValue in result.values) {
      mapValue.sort((Auth2PublicAccount account1, Auth2PublicAccount account2) {
        int result = SortUtils.compare(account1.profile?.lastName?.toUpperCase(), account2.profile?.lastName?.toUpperCase());
        if (result == 0) {
          result = SortUtils.compare(account1.profile?.firstName?.toUpperCase(), account2.profile?.firstName?.toUpperCase());
        }
        if (result == 0) {
          result = SortUtils.compare(account1.profile?.middleName?.toUpperCase(), account2.profile?.middleName?.toUpperCase());
        }
        return result;
      });
    }
    return result;
  }

  void _onTapClear() {
    Analytics().logSelect(target: 'Search Clear');
    if (_searchText.isNotEmpty) {
      setState(() {
        _searchTextController.text = _searchText = '';
      });
      _searchFocusNode.unfocus();
      _load();
    }

  }

  void _onTapSearch() {
    Analytics().logSelect(target: 'Search Text');
    if (_searchText != _searchTextController.text) {
      setState(() {
        _searchText = _searchTextController.text;
      });
      _searchFocusNode.unfocus();
      _load();
    }
  }

}
