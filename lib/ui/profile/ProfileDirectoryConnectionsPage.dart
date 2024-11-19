
import 'package:flutter/material.dart';
import 'package:illinois/model/Directory.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Directory.dart';
import 'package:illinois/ui/profile/ProfileDirectoryPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileDirectoryConnectionsPage extends StatefulWidget {
  final DirectoryConnections contentType;
  ProfileDirectoryConnectionsPage({super.key, required this.contentType});

  @override
  State<StatefulWidget> createState() => _ProfileDirectoryConnectionsPageState();
}

class _ProfileDirectoryConnectionsPageState extends State<ProfileDirectoryConnectionsPage>  {

  bool _loading = false;
  Map<String, List<DirectoryMember>>? _members;
  String? _expandedMemberId;


  @override
  void initState() {
    _loading = true;
    Directory().loadMembers().then((List<DirectoryMember>? members){
      setStateIfMounted(() {
        _loading = false;
        _members = (members != null) ? _buildMembers(members) : null;
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
    else if (_members == null) {
      return _messageContent(_failedText);
    }
    else if (_members?.isEmpty == true) {
      return _messageContent(_emptyText);
    }
    else {
      return _membersContent;
    }
  }

  Widget get _membersContent {
    List<Widget> sections = <Widget>[];
    int? firstCharCode, lastCharCode;
    _members?.forEach((key, value){
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
        List<DirectoryMember>? members = _members?[dirEntry];
        if (members != null) {
          sections.addAll(_membersSection(dirEntry, members));
        }
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: sections);
  }

  List<Widget> _membersSection(String dirEntry, List<DirectoryMember> members) {
    List<Widget> result = <Widget>[
      _sectionHeading(dirEntry)
    ];
    for (DirectoryMember member in members) {
      result.add(_sectionSplitter);
      result.add(DirectoryMemberCard(member, expanded: (_expandedMemberId != null) && (member.id == _expandedMemberId), onToggleExpanded: () => _onToggleMemberExpanded(member),));
    }
    if (members.isNotEmpty) {
      result.add(Padding(padding: EdgeInsets.only(bottom: 16), child: _sectionSplitter));
    }
    return result;
  }

  void _onToggleMemberExpanded(DirectoryMember member) {
    Analytics().logSelect(target: 'Expand', source: member.id);
    setState(() {
      _expandedMemberId = (_expandedMemberId != member.id) ? member.id : null;
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
      case DirectoryConnections.myConnections: return AppTextUtils.appTitleString('panel.profile.directory.connections.connections.empty.text', 'You do not have any ${AppTextUtils.appTitleMacro} Connections. Your connections will appear after you swap info with another ${AppTextUtils.universityLongNameMacro} student or employee.').replaceAll(AppTextUtils.universityLongNameMacro, AppTextUtils.universityLongName);
      case DirectoryConnections.appDirectory: return AppTextUtils.appTitleString('panel.profile.directory.connections.directory.empty.text', 'The ${AppTextUtils.appTitleMacro} App Directory is empty.');
    }
  }

  String get _failedText {
    switch (widget.contentType) {
      case DirectoryConnections.myConnections: return AppTextUtils.appTitleString('panel.profile.directory.connections.connections.failed.text', 'Failed to load ${AppTextUtils.appTitleMacro} Connections content.');
      case DirectoryConnections.appDirectory: return AppTextUtils.appTitleString('panel.profile.directory.connections.directory.failed.text', 'Failed to load ${AppTextUtils.appTitleMacro} App Directory content.');
    }
  }

  Map<String, List<DirectoryMember>> _buildMembers(List<DirectoryMember> members) {
    Map<String, List<DirectoryMember>> result = <String, List<DirectoryMember>>{};
    for (DirectoryMember member in members) {
      String mapKey = ((member.lastName?.isNotEmpty == true) ? member.lastName?.substring(0, 1).toUpperCase() : null) ?? ' ';
      List<DirectoryMember> mapValue = (result[mapKey] ??= <DirectoryMember>[]);
      mapValue.add(member);
    }
    for (List<DirectoryMember> mapValue in result.values) {
      mapValue.sort((DirectoryMember member1, DirectoryMember member2) {
        int result = SortUtils.compare(member1.lastName?.toUpperCase(), member2.lastName?.toUpperCase());
        if (result == 0) {
          result = SortUtils.compare(member1.firstName?.toUpperCase(), member2.firstName?.toUpperCase());
        }
        if (result == 0) {
          result = SortUtils.compare(member1.middleName?.toUpperCase(), member2.middleName?.toUpperCase());
        }
        return result;
      });
    }
    return result;
  }

}
