
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/profile/ProfileDirectoryPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/directory.dart';
import 'package:rokwire_plugin/service/directory.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileDirectoryAccountsPage extends StatefulWidget {
  final DirectoryAccounts contentType;
  ProfileDirectoryAccountsPage({super.key, required this.contentType});

  @override
  State<StatefulWidget> createState() => _ProfileDirectoryAccountsPageState();
}

class _ProfileDirectoryAccountsPageState extends State<ProfileDirectoryAccountsPage>  {

  bool _loading = false;
  Map<String, List<Auth2PublicAccount>>? _accounts;
  String? _expandedAccountId;

  late TextEditingController _searchTextController;
  late FocusNode _searchFocusNode;


  @override
  void initState() {
    _loading = true;
    _searchTextController = TextEditingController();
    _searchFocusNode = FocusNode();
    Directory().loadAccounts().then((List<Auth2PublicAccount>? accounts){
      setStateIfMounted(() {
        _loading = false;
        _accounts = (accounts != null) ? _buildAccounts(accounts) : null;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
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
    List<Widget> sections = <Widget>[
      _searchBarWidget,
    ];
    int? firstCharCode, lastCharCode;
    _accounts?.forEach((key, value){
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
        List<Auth2PublicAccount>? accounts = _accounts?[dirEntry];
        if (accounts != null) {
          sections.addAll(_accountsSection(dirEntry, accounts));
        }
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: sections);
  }

  List<Widget> _accountsSection(String dirEntry, List<Auth2PublicAccount> accounts) {
    List<Widget> result = <Widget>[
      _sectionHeading(dirEntry)
    ];
    for (Auth2PublicAccount account in accounts) {
      result.add(_sectionSplitter);
      result.add(DirectoryProfileCard(account, expanded: (_expandedAccountId != null) && (account.id == _expandedAccountId), onToggleExpanded: () => _onToggleAccountExpanded(account),));
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
      ),
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

  Widget get _sectionSplitter => Container(height: 1, color: Styles().colors.dividerLineAccent,);

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

  Map<String, List<Auth2PublicAccount>> _buildAccounts(List<Auth2PublicAccount> accounts) {
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
    _searchTextController.text = '';
  }

  void _onTapSearch() {
    Analytics().logSelect(target: 'Search Text');
  }

}
