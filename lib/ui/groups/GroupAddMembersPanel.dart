import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
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
  final GroupMemberStatus? memberStatus;

  const GroupAddMembersPanel({super.key, this.group, this.memberStatus});

  @override
  State<StatefulWidget> createState() => _GroupAddMembersState();
}

class _GroupAddMembersState extends State<GroupAddMembersPanel> {
  final _groupMembersController = TextEditingController();

  Map<GroupMemberStatus, LinkedHashMap<String, Auth2PublicAccount>> _groupMembers = <GroupMemberStatus, LinkedHashMap<String, Auth2PublicAccount>>{};
  static const List<GroupMemberStatus> _groupMembersDropdownStatuses = [ GroupMemberStatus.admin, GroupMemberStatus.member ];
  late GroupMemberStatus _groupMembersStatus;
  double? _membersDropdownStatusItemsWidth;

  bool _uploading = false;

  @override
  void initState() {
    _groupMembersStatus = widget.memberStatus ?? GroupMemberStatus.admin;
    super.initState();
  }

  @override
  void dispose() {
    _groupMembersController.dispose();
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
      _buildMembersSection(),
    ])
  );

  //
  // MembersSection
  Widget _buildMembersSection() {
    return Visibility(visible: true, child:
      Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [

        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child:
            GroupSectionTitle(title: _selectedMembersSectionLabel?.toUpperCase())
          )
        ]),
        Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: [
          Expanded(child:
            Container(decoration: _fieldDisabledDecoration, child:
              TextField(
                controller: _groupMembersController,
                maxLines: null,
                readOnly: true,
                onTap: _onBrowseMemberAccounts,
                decoration: _fieldSmallInputDecoration,
                style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
              )
            ),
          ),
          Padding(padding: EdgeInsets.symmetric(horizontal: 2), child:
            _membersBrowseButton,
          ),
          _membersDropdownStatus
        ]),
      ])
    );
  }

  Widget get _membersBrowseButton =>
    InkWell(onTap: _onBrowseMemberAccounts, child:
      Container(decoration: _buttonDecoration, padding: EdgeInsets.all(15), child:
        Styles().images.getImage('ellipsis')
      )
    );

  void _onBrowseMemberAccounts() {
    Analytics().logSelect(target: 'Browse Accounts');
    String? members = _selectedMembersSectionLabel;
    String? title = (members != null) ? (_isResearchProject ? 'Project $members' : 'Group $members') : null;

    Navigator.push<LinkedHashMap<String, Auth2PublicAccount>>(context, CupertinoPageRoute(builder: (context) => DirectoryAccountsSelectPanel(
      headerBarTitle: title,
      selectedAccounts: _selectedMembers,
    ))).then((LinkedHashMap<String, Auth2PublicAccount>? selection) {
      if ((selection != null) && mounted) {
        setState(() {
          _selectedMembers = selection;
          _groupMembersController.text = _selectedMembersDescription;
        });
      }
    });
  }

  Widget get _membersDropdownStatus =>
    DropdownButtonHideUnderline(child:
      DropdownButton2<GroupMemberStatus>(
        dropdownStyleData: DropdownStyleData(
          width: _membersDropdownStatusItemsWidth ??= _evaluateMembersDropdownItemsWidth(),
          direction: DropdownDirection.left,
          decoration: _buttonDecoration,
        ),
        customButton: _membersDropdownButton,
        isExpanded: false,
        items: membersDropdownItems,
        onChanged: _onMembersDropdownStatus,
      ),
    );

  void _onMembersDropdownStatus(GroupMemberStatus? memberStatus) {
    Analytics().logSelect(target: 'Select $memberStatus');
    if (memberStatus != null) {
      setState(() {
        _groupMembersStatus = memberStatus;
        _groupMembersController.text = _selectedMembersDescription;
      });
    }
  }

  Widget get _membersDropdownButton =>
      Container(decoration: _buttonDecoration, child:
        Padding(padding: _membersDropdownButtonPadding, child:
          Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: _membersDropdownIconSize, height: _membersDropdownIconSize, child:
              Center(child: _selectedMemberDropdownIcon,)
            ),
            Padding(padding: EdgeInsets.only(left: _membersDropdownButtonInnerIconPaddingX), child:
              SizedBox(width: _membersDropdownButtonChevronIconSize, height: _membersDropdownButtonChevronIconSize, child:
                Center(child:
                  _chevronDropdownIcon,
                )
              )
            )
          ],)
        )
      );

  LinkedHashMap<String, Auth2PublicAccount>? get _selectedMembers =>
    _groupMembers[_groupMembersStatus];

  set _selectedMembers(LinkedHashMap<String, Auth2PublicAccount>? value) {
    if (value != null) {
      _groupMembers.forEach((GroupMemberStatus memberStatus, LinkedHashMap<String, Auth2PublicAccount> accounts){
        if (memberStatus != _groupMembersStatus) {
          accounts.removeWhere((String accountId, Auth2PublicAccount account) => value.containsKey(accountId));
        }
      });
      _groupMembers[_groupMembersStatus] = value;
    }
    else {
      _groupMembers.remove(_groupMembersStatus);
    }
  }

  String get _selectedMembersDescription {
    String text = '';
    LinkedHashMap<String, Auth2PublicAccount>? accounts = _selectedMembers;
    if (accounts != null) {
      for (Auth2PublicAccount account in accounts.values) {
        String? accountName = account.profile?.fullName ?? account.profile?.email ?? account.id;
        if ((accountName != null) && accountName.isNotEmpty) {
          if (text.isNotEmpty) {
            text += ', ';
          }
          text += accountName;
        }
      }
    }
    return text;
  }

  String _memberStatusName(GroupMemberStatus memberStatus) =>
    _isResearchProject ? memberStatus.researchDisplayGroupTitle : memberStatus.groupDisplayGroupTitle;

  String? get _selectedMembersSectionLabel =>
    _isResearchProject ? _groupMembersStatus.researchDisplayGroupTitle : _groupMembersStatus.groupDisplayGroupTitle;

  Widget? get _selectedMemberDropdownIcon =>
    _membersDropdownIcon(_groupMembersStatus);

  List<DropdownMenuItem<GroupMemberStatus>> get membersDropdownItems {
    List<DropdownMenuItem<GroupMemberStatus>> items = <DropdownMenuItem<GroupMemberStatus>>[];
    for (GroupMemberStatus memberStatus in _groupMembersDropdownStatuses) {
      items.add(_membersDropdownItem(memberStatus, selected: memberStatus == _groupMembersStatus));
    }
    return items;
  }

  DropdownMenuItem<GroupMemberStatus> _membersDropdownItem(GroupMemberStatus memberStatus, { bool selected = false}) =>
    DropdownMenuItem<GroupMemberStatus>(value: memberStatus, child:
      Semantics(label: memberStatus.groupSemanticLabel, container: true, button: true, child:
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisSize: MainAxisSize.max, children: [
            Padding(padding: EdgeInsets.only(right: _membersDropdownItemInnerIconPaddingX), child:
              SizedBox(width: _membersDropdownIconSize, height: _membersDropdownIconSize, child:
                Center(child: _membersDropdownIcon(memberStatus))
              )
            ),
            Expanded(child:
              Text(_memberStatusName(memberStatus),
                overflow: TextOverflow.ellipsis,
                style: selected ? _selectedMembersDropdownItemTextStyle : _regularMembersDropdownItemTextStyle,
                semanticsLabel: "",
              ),
            ),
            Padding(padding: EdgeInsets.only(left: _membersDropdownItemInnerIconPaddingX), child:
              SizedBox(width: _membersDropdownIconSize, height: _membersDropdownIconSize, child:
                Center(child: selected ? _redioOnDropdownIcon : _redioOffDropdownIcon)
              )
            )
          ],),
        ],)
      ),
    );

  double _evaluateMembersDropdownItemsWidth() {
    double maxTextWidth = 0;
    for (GroupMemberStatus memberStatus in _groupMembersDropdownStatuses) {
      final Size textSizeFull = (TextPainter(
        text: TextSpan(text: _memberStatusName(memberStatus), style: _selectedMembersDropdownItemTextStyle,),
        textScaler: MediaQuery.of(context).textScaler,
        textDirection: TextDirection.ltr,
      )..layout()).size;
      if (maxTextWidth < textSizeFull.width) {
        maxTextWidth = textSizeFull.width;
      }
    }
    double dropdownItemWidth = (maxTextWidth * 5 / 3) + 2 * (_membersDropdownIconSize + _membersDropdownItemInnerIconPaddingX) + _membersDropdownMenuItemPadding.horizontal;
    return min(dropdownItemWidth, MediaQuery.of(context).size.width * 2 / 3);
  }

  static Widget? _membersDropdownIcon(GroupMemberStatus? memberStatus) {
    switch (memberStatus) {
      case GroupMemberStatus.admin: return _adminDropdownIcon;
      case GroupMemberStatus.member: return _memberDropdownIcon;
      default: return null;
    }
  }

  static const double _membersDropdownIconSize = 16;
  static const double _membersDropdownItemInnerIconPaddingX = 12;
  static const double _membersDropdownButtonChevronIconSize = 10;
  static const double _membersDropdownButtonInnerIconPaddingX = 12;

  static const EdgeInsetsGeometry _membersDropdownMenuItemPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  static const EdgeInsetsGeometry _membersDropdownButtonPadding = const EdgeInsets.only(left: 12, right: 4, top: 16, bottom: 16);

  TextStyle? get _selectedMembersDropdownItemTextStyle => Styles().textStyles.getTextStyle("widget.item.regular.extra_fat");
  TextStyle? get _regularMembersDropdownItemTextStyle => Styles().textStyles.getTextStyle("widget.item.regular.semi_fat");

  static Widget? get _adminDropdownIcon => Styles().images.getImage('user-tie', color: Styles().colors.fillColorSecondary, size: _membersDropdownIconSize);
  static Widget? get _memberDropdownIcon => Styles().images.getImage('users', color: Styles().colors.fillColorSecondary, size: _membersDropdownIconSize);
  static Widget? get _chevronDropdownIcon => Styles().images.getImage('chevron-down', color: Styles().colors.mediumGray2, size: _membersDropdownButtonChevronIconSize);
  static Widget? get _redioOnDropdownIcon => Styles().images.getImage('radio-button-on', size: _membersDropdownIconSize);
  static Widget? get _redioOffDropdownIcon => Styles().images.getImage('radio-button-off', size: _membersDropdownIconSize);

  bool get _isModified => _groupMembers.values.firstWhereOrNull((accounts) => accounts.isNotEmpty) != null;
  bool get _isResearchProject => widget.group?.researchProject == true;

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
    _groupMembers.forEach((GroupMemberStatus memberStatus, LinkedHashMap<String, Auth2PublicAccount> accounts){
      accounts.values.forEach((Auth2PublicAccount account) {
        members.add(Member.fromPublicAccount(account, status: memberStatus));
      });
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
