
import 'package:flutter/material.dart';
import 'package:illinois/model/Directory.dart';
import 'package:illinois/service/Directory.dart';
import 'package:illinois/ui/profile/ProfileDirectoryPage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class ProfileDirectoryConnectionsPage extends StatefulWidget {
  final DirectoryConnections contentType;
  ProfileDirectoryConnectionsPage({super.key, required this.contentType});

  @override
  State<StatefulWidget> createState() => _ProfileDirectoryConnectionsPageState();
}

class _ProfileDirectoryConnectionsPageState extends State<ProfileDirectoryConnectionsPage>  {

  bool _loading = false;
  List<DirectoryMember>? _members;


  @override
  void initState() {
    _loading = true;
    Directory().loadMembers().then((List<DirectoryMember>? members){
      setStateIfMounted(() {
        _loading = false;
        _members = members;
      });
    });

    _members = <DirectoryMember>[];
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

  Widget get _membersContent => _messageContent("${_members?.length} directory members loaded.");

  Widget get _loadingContent => Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 64,), child:
    Center(child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,)
      )
    )
  );

  Widget _messageContent(String message) => Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 64,), child:
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
}
