import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/directory/DirectoryAccountsSelectPanel.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/PopScopeFix.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.directory.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class GroupAddMembersPanel extends StatefulWidget {
  final Group? group;
  final GroupMemberStatus? status;

  const GroupAddMembersPanel({super.key, this.group, this.status});

  @override
  State<StatefulWidget> createState() => _GroupAddMembersState();
}

class _GroupAddMembersState extends State<GroupAddMembersPanel> {
  final _groupAdminAccountsController = TextEditingController();
  final _groupMemberAccountsController = TextEditingController();

  LinkedHashMap<String, Auth2PublicAccount> _groupAdminAccounts = LinkedHashMap<String, Auth2PublicAccount>();
  LinkedHashMap<String, Auth2PublicAccount> _groupMemberAccounts = LinkedHashMap<String, Auth2PublicAccount>();

  bool _uploading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _groupAdminAccountsController.dispose();
    _groupMemberAccountsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      PopScopeFix(onBack: _onSwipeBack, child:
        Scaffold(
          appBar: HeaderBar(
            title: Localization().getStringEx("", "Add Members"),
            onLeading: _onTapHeaderBack,
            actions: _headerBarActions,
          ),
          backgroundColor: Styles().colors.background,
          body: _scaffoldContent,
        ),
      );

  Widget get _scaffoldContent => Padding(padding: EdgeInsets.all(16), child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildAdminSettingsSection(),
    ])
  );

  //
  // AdminSection
  Widget _buildAdminSettingsSection() {
    return Visibility(visible: true, child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [

          if (widget.status != GroupMemberStatus.member)
            ..._adminSettingsSection,

          if (widget.status != GroupMemberStatus.admin)
            ..._membersSettingsSection,
        ])
      )
    );
  }

  List<Widget> get _adminSettingsSection => <Widget>[
    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(child:
        GroupSectionTitle(title: 'ADMINS')
      )
    ]),
    Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: [
      Expanded(child:
        Container(decoration: _fieldDisabledDecoration, child:
          TextField(
            controller: _groupAdminAccountsController,
            maxLines: null,
            readOnly: true,
            decoration: _fieldSmallInputDecoration,
            style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
          )
        ),
      ),
      Padding(padding: EdgeInsets.only(left: 2), child:
        _adminBrowseButton(onTap: _onBrowseAdminAccounts),
      ),
    ]),
  ];

  List<Widget> get _membersSettingsSection => <Widget>[
    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(child:
        GroupSectionTitle(title: 'MEMBERS')
      )
    ]),
    Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: [
      Expanded(child:
        Container(decoration: _fieldDisabledDecoration, child:
          TextField(
            controller: _groupMemberAccountsController,
            maxLines: null,
            readOnly: true,
            decoration: _fieldSmallInputDecoration,
            style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
          )
        ),
      ),
      Padding(padding: EdgeInsets.only(left: 2), child:
        _adminBrowseButton(onTap: _onBrowseMemberAccounts),
      )
    ]),
  ];

  Widget _adminBrowseButton({void Function()? onTap}) =>
    InkWell(onTap: onTap, child:
      Container(decoration: _buttonDecoration, padding: EdgeInsets.all(15), child:
        Styles().images.getImage('ellipsis')
      )
    );

  void _onBrowseAdminAccounts() {
    Analytics().logSelect(target: 'Browse Admin Accounts');

    Navigator.push<LinkedHashMap<String, Auth2PublicAccount>>(context, CupertinoPageRoute(builder: (context) => DirectoryAccountsSelectPanel(
      headerBarTitle: (widget.group?.isResearchProject == true) ? 'Project Admins' : 'Group Admins',
      selectedAccounts: _groupAdminAccounts,
    ))).then((LinkedHashMap<String, Auth2PublicAccount>? selection) {
      if ((selection != null) && mounted) {
        setState(() {
          _groupAdminAccounts = selection;
          _groupAdminAccountsController.text = _buildAdminAccounts(_groupAdminAccounts);

          _groupMemberAccounts.removeWhere((String accountId, Auth2PublicAccount account) => selection.containsKey(accountId));
          _groupMemberAccountsController.text = _buildAdminAccounts(_groupMemberAccounts);
        });
      }
    });
  }

  void _onBrowseMemberAccounts() {
    Analytics().logSelect(target: 'Browse Member Accounts');

    Navigator.push<LinkedHashMap<String, Auth2PublicAccount>>(context, CupertinoPageRoute(builder: (context) => DirectoryAccountsSelectPanel(
      headerBarTitle: (widget.group?.isResearchProject == true) ? 'Project Members' : 'Group Members',
      selectedAccounts: _groupMemberAccounts,
    ))).then((LinkedHashMap<String, Auth2PublicAccount>? selection) {
      if ((selection != null) && mounted) {
        setState(() {
          _groupMemberAccounts = selection;
          _groupMemberAccountsController.text = _buildAdminAccounts(_groupMemberAccounts);

          _groupAdminAccounts.removeWhere((String accountId, Auth2PublicAccount account) => selection.containsKey(accountId));
          _groupAdminAccountsController.text = _buildAdminAccounts(_groupAdminAccounts);
        });
      }
    });
  }

  String _buildAdminAccounts(LinkedHashMap<String, Auth2PublicAccount> accounts) {
    String text = '';
    for (Auth2PublicAccount account in accounts.values) {
      String? accountName = account.profile?.fullName ?? account.profile?.email ?? account.id;
      if ((accountName != null) && accountName.isNotEmpty) {
        if (text.isNotEmpty) {
          text += ', ';
        }
        text += accountName;
      }
    }
    return text;
  }

  bool get _isModified => _groupMemberAccounts.isNotEmpty || _groupAdminAccounts.isNotEmpty;

  // Header bar

  List<Widget>? get _headerBarActions {
    if (_uploading) {
      return [Event2CreatePanel.buildHeaderBarActionProgress()];
    }
    else if (_isModified) {
      return [HeaderBarActionTextButton(title:  Localization().getStringEx('dialog.apply.title', 'Apply'), onTap: _onTapApply,)];
    }
    else {
      return null;
    }

  }

  void _onTapApply() {
    Analytics().logSelect(target: 'HeaderBar: Apply');
    _apply().then((bool? result){
      if ((result == true) && mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  Future<bool?> _apply() async {
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() => _uploading = true);

    List<Member> members = <Member>[];
    _groupAdminAccounts.values.forEach((Auth2PublicAccount account) {
      members.add(Member.fromPublicAccount(account, status: GroupMemberStatus.admin));
    });
    _groupMemberAccounts.values.forEach((Auth2PublicAccount account) {
      members.add(Member.fromPublicAccount(account, status: GroupMemberStatus.member));
    });

    if (CollectionUtils.isNotEmpty(members)) {
      GroupResult? result = await Groups().addMembers(group: widget.group, members: members);
      setStateIfMounted(() => _uploading = false);
      if (result.successful) {
        return true;
      }
      else {
        await AppAlert.showDialogResult(context, StringUtils.ensureNotEmpty(result.error, defaultValue: "Error occurred"));
        return false;
      }
    }
    else {
      return null;
    }
  }

  void _onTapHeaderBack() {
    Analytics().logSelect(target: 'HeaderBar: Back');
    _onHeaderBack();
  }

  void _onSwipeBack() {
    Analytics().logSelect(target: 'Swipte Right: Back');
    _onHeaderBack();
  }

  void _onHeaderBack() {
    Analytics().logSelect(target: 'Back');
    if (_isModified) {
      showDialog<bool?>(context: context, builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0),),
        content: Text(_headerBackApplyPromptText(), textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.message.regular.fat'),),
        actions: [
          _headerBackPromptButton(context, promptBuilder: _headerBackApplyPromptText, textBuilder: _headerBackPromptYesText, value: true),
          _headerBackPromptButton(context, promptBuilder: _headerBackApplyPromptText, textBuilder: _headerBackPromptNoText, value: false),
          _headerBackPromptButton(context, promptBuilder: _headerBackApplyPromptText, textBuilder: _headerBackPromptCancelText, value: null),
        ],
      )).then((bool? result) {
        if (mounted) {
          if (result == true) {
            _apply().then((bool? result) {
              if ((result == true) && mounted) {
                Navigator.pop(context, true);
              }
            });
          }
          else if (result == false) {
            Navigator.pop(context, false);
          }
        }
      });
    }
    else {
      Navigator.pop(context, false);
    }
  }

  Widget _headerBackPromptButton(BuildContext context, {String Function({String? language})? promptBuilder, String Function({String? language})? textBuilder, bool? value}) =>
    OutlinedButton(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0),)),
      ),
      onPressed: () => _onTapHeaderBackPromptButton(context,
        prompt: (promptBuilder != null) ? promptBuilder(language: 'en') : null,
        text: (textBuilder != null) ? textBuilder(language: 'en') : null,
        value: value
      ),
      child: Text((textBuilder != null)  ? textBuilder() : '',
        style: Styles().textStyles.getTextStyle('widget.message.regular.semi_fat'),
      ),
    );

  void _onTapHeaderBackPromptButton(BuildContext context, {String? prompt, String? text, bool? value}) {
    Analytics().logAlert(text: prompt, selection: text);
    Navigator.of(context).pop(value);
  }

  String _headerBackApplyPromptText({String? language}) =>
    Localization().getStringEx('panel.directory.accounts.select.apply.prompt', 'Apply your changes?', language: language);

  String _headerBackPromptYesText({String? language}) => Localization().getStringEx("dialog.yes.title", "Yes", language: language);
  String _headerBackPromptNoText({String? language}) => Localization().getStringEx("dialog.no.title", "No", language: language);
  String _headerBackPromptCancelText({String? language}) => Localization().getStringEx("dialog.cancel.title", "Cancel", language: language);

  BoxDecoration get _buttonDecoration =>
    BoxDecoration(border: Border.all(color: Styles().colors.surfaceAccent, width: 1), borderRadius: BorderRadius.circular(4), color: Styles().colors.white);

  BoxDecoration get _fieldDisabledDecoration =>
    _fieldDecorationEx(backColor: Styles().colors.background);

  BoxDecoration _fieldDecorationEx({Color? backColor}) =>
    BoxDecoration(border: Border.all(color: Styles().colors.fillColorPrimary, width: 1),color: backColor);

  InputDecoration get _fieldSmallInputDecoration =>
    _fieldInputDecorationEx(contentPadding: EdgeInsets.symmetric(horizontal: 8));

  InputDecoration _fieldInputDecorationEx({ String? hintText, EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 12) }) =>
    InputDecoration(border: InputBorder.none, hintText: hintText, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0));
}
