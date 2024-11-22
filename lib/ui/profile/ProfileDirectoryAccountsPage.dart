
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/profile/ProfileDirectoryPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/directory.dart';
import 'package:rokwire_plugin/service/directory.dart';
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


  @override
  void initState() {
    _loading = true;
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
    List<Widget> sections = <Widget>[];
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

}
