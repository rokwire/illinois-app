import 'package:flutter/material.dart';
import 'package:neom/ui/events2/Event2CreatePanel.dart';
import 'package:neom/ui/groups/GroupWidgets.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class GroupAddMembersPanel extends StatefulWidget {
  final Group? group;
  final GroupMemberStatus? selectedMemberStatus;

  const GroupAddMembersPanel({super.key, this.group, this.selectedMemberStatus});

  @override
  State<StatefulWidget> createState() => _GroupAddMembersState();
}

class _GroupAddMembersState extends State<GroupAddMembersPanel> {
  final _groupNetIdsController = TextEditingController();

  GroupMemberStatus _selectedStatus = GroupMemberStatus.member;
  bool _uploading = false;

  @override
  void initState() {
    if(widget.selectedMemberStatus == GroupMemberStatus.member ||
        widget.selectedMemberStatus == GroupMemberStatus.admin){
      _selectedStatus = widget.selectedMemberStatus!;
    }

    super.initState();
  }

  @override
  void dispose() {
    _groupNetIdsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
          backgroundColor: Styles().colors.background,
          appBar: HeaderBar(title: Localization().getStringEx("", "Add Members"), //TBD localize
            actions: _headerBarActions,),
          body:Container(
                padding:  EdgeInsets.symmetric(horizontal: 16),
                child: Column(mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child:
                            GroupSectionTitle(title: 'NETIDS (comma separated)', requiredMark: false))
                          ]),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                  decoration: BoxDecoration(border: Border.all(color: Styles().colors.fillColorPrimary, width: 1),color: Styles().colors.surface),
                                  child: TextField(
                                    controller: _groupNetIdsController,
                                    maxLines: 1,
                                    decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                                    style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
                                    onChanged: (_) => setStateIfMounted(),
                                  )),
                            ),
                            Expanded(
                                flex: 1,
                                child: Padding(
                                    padding: EdgeInsets.only(left: /*AppScreen.isLarge(context) ? 30 : */6),
                                    child: GroupDropDownButton(
                                        initialSelectedValue: _selectedStatus,
                                        constructTitle:
                                            (dynamic item) => item is GroupMemberStatus ? groupMemberStatusToString(item) : "",
                                        onValueChanged: _onMemberStatusChanged,
                                        items: _statusItems))
                            )
                          ])
                    ])
            )
      );
  }

  void _onMemberStatusChanged(dynamic status) {
    if (status is GroupMemberStatus)
      setStateIfMounted(() {
        _selectedStatus = status;
      });
  }

  List<GroupMemberStatus> get _statusItems => [GroupMemberStatus.admin, GroupMemberStatus.member];

  List<Widget>? get _headerBarActions {
    if (_uploading) {
      return [Event2CreatePanel.buildHeaderBarActionProgress()];
    }
    else if(StringUtils.isNotEmpty(_groupNetIdsController.text)) {
      return [Event2CreatePanel.buildHeaderBarActionButton(
        title: Localization().getStringEx('dialog.apply.title', 'Apply'),
        onTap: _onTapApply,
      )];
    }
    else
      return null;
  }

  void _onTapApply() {
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() => _uploading = true);
    List<String>? adminNetIds;
    if(StringUtils.isNotEmpty(_groupNetIdsController.text)) {
      adminNetIds = ListUtils.notEmpty(
          ListUtils.stripEmptyStrings(
              _groupNetIdsController.text.split(ListUtils.commonDelimiterRegExp)));
    }

    List<Member>? members = adminNetIds?.map((netId) => Member(netId: netId, status: _selectedStatus)).toList();
    if(CollectionUtils.isNotEmpty(members)){
        Groups().addMembers(group: widget.group, members: members).
            then((result){
                setStateIfMounted(()=> _uploading = false);
                if(result.successful){
                  Navigator.of(context).pop();
                } else {
                  AppAlert.showDialogResult(context, StringUtils.ensureNotEmpty(result.error, defaultValue: "Error occurred"));
                }
              }
            );
    }
  }
}