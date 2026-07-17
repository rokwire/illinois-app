
import 'dart:collection';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/groups/GroupConversationPanel.dart';
import 'package:illinois/ui/groups/GroupConversationWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class GroupConversationCreatePanel extends StatefulWidget {
  final Group? group;
  final List<Member>? groupAdmins;
  final AnalyticsFeature? analyticsFeature;

  GroupConversationCreatePanel({ super.key, this.group, this.groupAdmins, this.analyticsFeature });

  @override
  State<StatefulWidget> createState() => _GroupConversationCreatePanelState();
}

class _GroupConversationCreatePanelState extends State<GroupConversationCreatePanel> {

  List<Member>? _membersList;
  Map<String, Member>? _membersMap;
  List<Member> _displayMembers = <Member>[];
  ContentActivity? _membersActivity;

  String _searchText = '';
  bool _hasEditSearchText = false;
  TextEditingController _searchTextController = TextEditingController();
  FocusNode _searchTextFocusNode = FocusNode();

  LinkedHashSet<String> _selectedMemberIds = LinkedHashSet<String>();

  bool _submitting = false;

  @override
  void initState() {
    _loadMembers();
    super.initState();
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>  Scaffold(
    appBar: HeaderBar(title: Localization().getStringEx('', 'New Message')),
    body: _bodyWidget,
    backgroundColor: Styles().colors.surface,
  );

  Widget get _bodyWidget {
    if (_membersActivity == ContentActivity.reload) {
      return _loadingContent;
    }
    else if (_membersMap == null) {
      return _buildMessageContent(Localization().getStringEx('', 'Failed to load members'),
        title: Localization().getStringEx('common.label.failed', 'Failed')
      );
    }
    else {
      return _membersContent;
    }
  }

  Widget get _membersContent =>
    RefreshIndicator(onRefresh: _onRefresh, child:
      Column(children: [
        _selectedMembersBar,
        _searchBar,
        _membersListHeading,
        Expanded(child:
          _membersListView
        ),
        _submitBar
      ],)
    );

  // List View

  Widget get _membersListView => Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 16), child:
    ListView.separated(
      itemCount: _displayMembers.length,
      //itemBuilder: (context, index) => _buildMemberItem(ListUtils.entry(_displayMembers, index), decoration: _getMemberItemDecoration(index)),
      itemBuilder: (context, index) => _MemberListItemWidget(_displayMembers[index],
        pos: _MemberListItemPosImpl.fromListIndex(_displayMembers, index),
        selected: _selectedMemberIds.contains(_displayMembers[index].userId ?? ''),
        onSelect: () => _onTapMember(_displayMembers[index].userId ?? ''),
      ),
      separatorBuilder: (context, index) => Divider(color: _MemberListItemWidget.widgetBorderColor, height: _MemberListItemWidget.widgetBorderSize),
    ),
  );

  /*ListView.separated(
    itemBuilder: (context, index) => _buildDeparture(ListUtils.entry(_departures, index)),
    separatorBuilder: (context, index) => Divider(height: 1, color: Styles().colors.fillColorPrimaryTransparent03,),
    itemCount: _departures?.length ?? 0,
    padding: EdgeInsets.zero,
  );*/

  // Search Bar

  Widget get _searchBar => Padding(padding: EdgeInsetsGeometry.only(left: 16, top: 16), child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Expanded(child:
          Padding(padding: EdgeInsetsGeometry.only(right: 16), child:
            Text(Localization().getStringEx('', 'Search for a particular member'), style: Styles().textStyles.getTextStyle('widget.title.regular.fat'),),
          ),
        )
      ]),
      Row(children: [
        Expanded(child:
          TextField(
            controller: _searchTextController,
            focusNode: _searchTextFocusNode,
            decoration: _searchTextEditDecoration,
            style: Styles().textStyles.getTextStyle('widget.input_field.dark.text.regular.thin'),
            maxLines: 1,
            minLines: 1,
            keyboardType: TextInputType.text,
            autocorrect: false,
            onChanged: _onSearchTextChanged,
            onSubmitted: (text) => _onSearch(),
          ),
        ),
        _searchClearButton,
        _searchButton,
      ]),
    ]),
  );

  Widget get _searchClearButton => Semantics(label: Localization().getStringEx('', 'Clear Search'), button: true, child:
    InkWell(onTap: _onSearchClear, child:
      Padding(padding: EdgeInsetsGeometry.only(left: 16, right: 8, top: 16, bottom: 16), child:
        Styles().images.getImage('close-circle', size: 18, color: (_hasEditSearchText || _searchText.isNotEmpty) ? Styles().colors.fillColorSecondary : Styles().colors.mediumGray2)
      )
    )
  );

  Widget get _searchButton => Semantics(label: Localization().getStringEx('', 'Search'), button: true, child:
    InkWell(onTap: _onSearch, child:
      Padding(padding: EdgeInsetsGeometry.only(left: 8, right: 16, top: 16, bottom: 16), child:
        Styles().images.getImage('search', size: 18, color: _hasEditSearchText ? Styles().colors.fillColorSecondary : Styles().colors.mediumGray2)
      )
    )
  );

  InputDecoration get _searchTextEditDecoration => InputDecoration(
    fillColor: Styles().colors.surface,
    filled: true,
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Styles().colors.surfaceAccent, width: 1),
      borderRadius: BorderRadius.circular(4)
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  );
  
  // List Heading

  Widget get _membersListHeading => Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 16), child:
    Row(children: [
      Expanded(child:
        Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 11), child:
          Text(_searchText.isNotEmpty ? Localization().getStringEx('', 'SEARCH RESULTS') : Localization().getStringEx('', 'ALL MEMBERS'),
            style: Styles().textStyles.getTextStyle('widget.title.small.medium_fat'),
          ),
        )
      ),
      if (_searchText.isEmpty)
        _selectAllButton,
    ],),
  );

  bool get _allMembersSelected {
    Iterable<String>? allMemberIds = _membersMap?.keys;
    return ((allMemberIds != null) && _selectedMemberIds.containsAll(allMemberIds));
  }

  Widget get _selectAllButton {
    bool allMembersSelected = _allMembersSelected;
    String buttonTitle = allMembersSelected ?
      Localization().getStringEx('', 'Unselect All') : Localization().getStringEx('', 'Select All');
    String semanticsHint = allMembersSelected ?
      Localization().getStringEx('', 'Tap to unselect all members') : Localization().getStringEx('', 'Tap to select all members');

    return Semantics(label: buttonTitle, hint: semanticsHint, button: true, child:
      InkWell(onTap: _onSelectAll, child:
        Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 12), child:
          Text(allMembersSelected ?
            Localization().getStringEx('', 'Unselect All') : Localization().getStringEx('', 'Select All'), style: Styles().textStyles.getTextStyle('widget.button.title.small.fat.underline'),),
        )
      )
    );
  }

  // Selected Members Bar
  
  Widget get _selectedMembersBar => Container(padding: _selectedMembersPadding, decoration: _selectedMembersDecoration, constraints: _selectedMembersConstraints, child:
    SingleChildScrollView(child:
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.symmetric(vertical: 4), child:
          Text(Localization().getStringEx('', 'To: '), style: Styles().textStyles.getTextStyle('widget.title.regular.fat'),),
        ),
        Expanded(child:
          Wrap(spacing: _selectedMembersWrapSpacing, runSpacing: _selectedMembersWrapSpacing,
            children: _allMembersSelected ? <Widget>[_allGroupMembersWidget] : _selectedMembersWidgets
          )
        )
      ],)
    )
  );

  Widget get _allGroupMembersWidget => _SelectedMemberWidget.allGroupMembers(onRemove: _onRemoveAllMembers,);
  List<Widget> get _selectedMembersWidgets => List<Widget>.from(List.from(_selectedMemberIds).reversed.map((memberId) => _SelectedMemberWidget.member(_membersMap?[memberId] , onRemove: () => _onRemoveMember(memberId),)));

  BoxConstraints get _selectedMembersConstraints => BoxConstraints(minHeight: _selectedMembersHeight(1), maxHeight: _selectedMembersHeight(3));
  static double _selectedMembersHeight(int lineNum) => max(lineNum, 0) * _SelectedMemberWidget.height + max(lineNum - 1, 0) * _selectedMembersWrapSpacing + 2 * _selectedMembersSpacing;
  static double get _selectedMembersSpacing => 8;
  static double get _selectedMembersWrapSpacing => 4;

  EdgeInsetsGeometry get _selectedMembersPadding => EdgeInsets.symmetric(horizontal: 16, vertical: _selectedMembersSpacing);

  BoxDecoration get _selectedMembersDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border(bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1)),
    boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(0, 2))],
  );

  // Submit Bar

  Widget get _submitBar => Container(padding: _submitPadding, decoration: _submitDecoration, child:
    Row(children: [
      Expanded(flex: 1, child: Container()),
      Expanded(flex: 2, child:
        RoundedButton(
          label: Localization().getStringEx("dialog.done.title",  'Done'),
          backgroundColor: Styles().colors.white,
          textStyle: _canSubmit ? Styles().textStyles.getTextStyle("widget.button.title.regular") : Styles().textStyles.getTextStyleEx("widget.button.title.regular", color: Styles().colors.disabledTextColorTwo),
          borderColor: _canSubmit ? Styles().colors.fillColorSecondary : Styles().colors.disabledTextColorTwo,
          enabled: _canSubmit,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          borderWidth: 2,
          progress: _submitting,
          onTap: _onSubmit,
        ),
      ),
      Expanded(flex: 1, child: Container()),
    ],)
  );

  EdgeInsetsGeometry get _submitPadding => EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  BoxDecoration get _submitDecoration => BoxDecoration(
    color: Styles().colors.background,
    border: Border(top: BorderSide(color: Styles().colors.surfaceAccent, width: 1)),
    boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(0, 2))],
  );

  // Error & Loading Content

  Widget _buildMessageContent(String message, { String? title }) =>
    RefreshIndicator(onRefresh: _onRefresh, child:
      SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), scrollDirection: Axis.vertical, child:
        Center(child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: _screenHeight / 6), child:
            Column(mainAxisSize: MainAxisSize.min, children: [
              (title != null) ? Padding(padding: EdgeInsets.only(bottom: 12), child:
                Text(title, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.item.medium.fat'),)
              ) : Container(),
              Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle((title != null) ? 'widget.item.regular.thin' : 'widget.item.medium.fat'),),
            ],),
          )
        )
      )
    );

  Widget get _loadingContent => Center(child:
    Padding(padding: EdgeInsets.symmetric(vertical: _screenHeight / 4), child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 2)
      )
    )
  );

  double get _screenHeight => MediaQuery.of(context).size.height;

  // Members Management

  Future<void> _loadMembers() async {
    if ((_membersActivity != ContentActivity.reload) && mounted) {
      setState(() {
        _membersActivity = ContentActivity.reload;
      });

      List<Member>? membersList = await Groups().loadMembers(groupId: widget.group?.id,);

      if (mounted && (_membersActivity == ContentActivity.reload)) {
        setState(() {
          _membersList = membersList;
          _membersMap = MemberExt.mapFromList(membersList);
          _displayMembers = _buildDisplayMembers(membersList);
          _membersActivity = null;
        });
      }
    }
  }

  Future<void> _refreshMembers() async {
    if ((_membersActivity?.loading != true) && mounted) {
      setState(() {
        _membersActivity = ContentActivity.refresh;
      });

      List<Member>? membersList = await Groups().loadMembers(groupId: widget.group?.id,);

      if (mounted && (_membersActivity == ContentActivity.refresh)) {
        setState(() {
          _membersList = membersList;
          _membersMap = MemberExt.mapFromList(membersList);
          _displayMembers = _buildDisplayMembers(membersList);
          _membersActivity = null;
        });
      }
    }
  }

  List<Member> _buildDisplayMembers(List<Member>? membersList) {
    List<Member> displayMembers = <Member>[];
    if (membersList != null) {
      String searchLowercaseText = _searchText.trim().toLowerCase();
      for (Member member in membersList) {
        if ((member.userId?.isNotEmpty == true) && (searchLowercaseText.isEmpty || member.matchLowercaseText(searchLowercaseText))) {
          displayMembers.add(member);
        }
      }
    }
    return displayMembers;
  }

  // Event Handlers

  Future<void> _onRefresh() async {
    Analytics().logSelect(target: 'Refresh');
    return _refreshMembers();
  }

  void _onSearchTextChanged(String text) {
    bool hasEditSearchText =  text.trim().isNotEmpty;
    if (_hasEditSearchText != hasEditSearchText) {
      setState(() {
        _hasEditSearchText = hasEditSearchText;
      });
    }
  }
  
  void _onSearch() {
    Analytics().logSelect(target: 'Search');
    String searchText = _searchTextController.text.trim();
    if (searchText.isNotEmpty) {
      setState(() {
        _searchText = searchText;
        _hasEditSearchText = true;
        _displayMembers = _buildDisplayMembers(_membersList);
      });
    }
  }

  void _onSearchClear() {
    Analytics().logSelect(target: 'Clear Search');
    if (_searchText.isNotEmpty) {
      _searchTextController.text = '';
      setState(() {
        _searchText = '';
        _hasEditSearchText = false;
        _displayMembers = _buildDisplayMembers(_membersList);
      });
    } else if (_searchTextController.text.isNotEmpty) {
      _searchTextController.text = '';
      setState(() {
        _hasEditSearchText = false;
      });
    }
  }

  void _onSelectAll() {
    Iterable<String>? allMemberIds = _membersMap?.keys;
    if ((allMemberIds != null) && (_selectedMemberIds.containsAll(allMemberIds) != true)) {
      Analytics().logSelect(target: 'Select All');
      setState(() {
        _selectedMemberIds.addAll(allMemberIds);
      });
    } else {
      Analytics().logSelect(target: 'Unselect All');
      setState(() {
        _selectedMemberIds.clear();
      });
    }
  }

  void _onTapMember(String memberId) {
    if (_selectedMemberIds.contains(memberId)) {
      _onUnselectMember(memberId);
    } else {
      _onSelectMember(memberId);
    }
  }

  void _onSelectMember(String memberId) {
    Analytics().logSelect(target: 'Select Member');
    setState(() {
      _selectedMemberIds.add(memberId);
    });
  }

  void _onUnselectMember(String memberId) {
    Analytics().logSelect(target: 'Unselect Member');
    setState(() {
      _selectedMemberIds.remove(memberId);
    });
  }

  void _onRemoveMember(String memberId) {
    Analytics().logSelect(target: 'Remove Member');
    if (_selectedMemberIds.contains(memberId)) {
      setState(() {
        _selectedMemberIds.remove(memberId);
      });
    }
  }

  void _onRemoveAllMembers() {
    Analytics().logSelect(target: 'Remove All Group Member');
    if (_selectedMemberIds.isNotEmpty) {
      setState(() {
        _selectedMemberIds.clear();
      });
    }
  }

  bool get _canSubmit => _selectedMemberIds.isNotEmpty;


  void _onSubmit() async {
    Analytics().logSelect(target: 'Done');
    if (_canSubmit && (_submitting == false)) {

      ConversationType? conversationType;
      if (widget.group?.currentUserIsAdmin == true) {
        if (_allMembersSelected) {
          GroupConversationCreateOption? createOption = await GroupConversationCreateOptionsDialog.show(context);
          if (mounted) {
            if (createOption == GroupConversationCreateOption.individualMessages) {
              AppAlert.showTextMessage(context, Localization().getStringEx('', 'TBD'));
            } else if (createOption == GroupConversationCreateOption.groupMessage) {
              conversationType = ConversationType.groupAll;
            }
          }
        } else {
          conversationType = ConversationType.groupSubset;
        }
      } else {
        conversationType = ConversationType.groupSubset;
      }

      if (mounted && (conversationType != null)) {

        setState(() {
          _submitting = true;
        });

        Conversation? conversation = await Social().createConversation(
          type: conversationType,
          context: ContextItem.fromGroup(widget.group?.id),
          memberIds: (conversationType != ConversationType.groupAll) ? List.from(_selectedMemberIds) : null,
        );

        if (mounted) {
          setState(() {
            _submitting = false;
          });
          if (conversation != null) {
            Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) =>
              GroupConversationPanel(conversation,
                group: widget.group,
                groupAdmins: widget.groupAdmins,
                analyticsFeature: widget.analyticsFeature,
              )
            ));
          } else {
            AppAlert.showTextMessage(context, Localization().getStringEx('', 'Failed to create new message'));
          }
        }
      }
    }
  }
}

class _SelectedMemberWidget extends StatelessWidget {
  final Member? member;
  final bool? allGroupMembers;
  final void Function()? onRemove;

  _SelectedMemberWidget({ this.member, this.allGroupMembers, this.onRemove});

  factory _SelectedMemberWidget.member(Member? member, { void Function()? onRemove }) =>
      _SelectedMemberWidget(member: member, onRemove: onRemove,);

  factory _SelectedMemberWidget.allGroupMembers({ void Function()? onRemove }) =>
      _SelectedMemberWidget(allGroupMembers: true, onRemove: onRemove,);

  @override
  Widget build(BuildContext context) =>
    Container(decoration: _widgetDecoration, child:
      Semantics(label: _title ?? '', hint: _semanticsHint, button: true, child:
        InkWell(onTap: onRemove, child:
          Row(mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: EdgeInsetsGeometry.only(left: _spacing, top: _halfSpacing, bottom: _halfSpacing), child:
              Text(_title ?? '', style: Styles().textStyles.getTextStyle('widget.title.regular.fat'),)
            ),
            Padding(padding: EdgeInsets.only(left: _halfSpacing, right: _spacing, top: _spacing, bottom: _spacing), child:
              Styles().images.getImage('close', color: Styles().colors.fillColorPrimary, size: _iconSize)
            )
          ],)
        )
      ),
    );

  String? get _title => (allGroupMembers == true) ?
    Localization().getStringEx('', 'All Group Members') : member?.name;

  String? get _semanticsHint => (allGroupMembers == true) ?
    Localization().getStringEx('', 'Tap to remove all group members') :
    Localization().getStringEx('', 'Tap to remove ${member?.name ?? ''}');
  
  BoxDecoration get _widgetDecoration => BoxDecoration(
    color: Styles().colors.background,
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  static double get _spacing => 8;
  static double get _halfSpacing => _spacing / 2;
  static double get _iconSize => 12;
  static double get height => _iconSize + 2 * _spacing;
}

class _MemberListItemWidget extends StatelessWidget {
  final Member? member;
  final _MemberListItemPos pos;
  final bool selected;
  final void Function()? onSelect;

  _MemberListItemWidget(this.member, { this.pos = _MemberListItemPos.middle, this.selected = false, this.onSelect });

  @override
  Widget build(BuildContext context) =>
    Container(decoration: _widgetDecoration, child:
      Row(children: [
        _checkButton,
        Expanded(child:
          Padding(padding: EdgeInsets.symmetric(vertical: 4), child:
            Text(member?.name ?? '', style: Styles().textStyles.getTextStyle('widget.title.regular.fat'),)
          )
        ),
        if (_memberStatus != null)
          _MemberStatusWidget(_memberStatus),
      ],)
    );

  Widget get _checkButton =>
    InkWell(onTap: onSelect, child:
      Padding(padding: EdgeInsets.all(12), child:
        Styles().images.getImage(selected ? 'check-circle-filled' : 'check-circle-outline-gray', size: 24)
      ),
    );

  GroupMemberStatus? get _memberStatus => member?.status;

  BoxDecoration get _widgetDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border(
      left: widgetBorder,
      right: widgetBorder,
      top: pos.hasTopBorder ? widgetBorder : BorderSide.none,
      bottom: pos.hasBottomBorder ? widgetBorder : BorderSide.none,
    ),
    borderRadius: BorderRadius.vertical(
      top: pos.hasTopBorder ? Radius.circular(8) : Radius.zero,
      bottom: pos.hasBottomBorder ? Radius.circular(8) : Radius.zero,
    ),
  );

  static BorderSide get widgetBorder =>  BorderSide(color: widgetBorderColor, width: widgetBorderSize);
  static double get widgetBorderSize => 1;
  static Color get widgetBorderColor => Styles().colors.surfaceAccent2;
}

enum _MemberListItemPos { only, first, middle, last, }

extension _MemberListItemPosImpl on _MemberListItemPos {
  bool get hasTopBorder => (this == _MemberListItemPos.first) || (this == _MemberListItemPos.only);
  bool get hasBottomBorder => (this == _MemberListItemPos.last) || (this == _MemberListItemPos.only);

  static _MemberListItemPos fromListIndex(List list, int index) {
    if (list.length <= 1) {
      return _MemberListItemPos.only;
    } else if (index <= 0) {
      return _MemberListItemPos.first;
    } else if ((index + 1) < list.length) {
      return _MemberListItemPos.middle;
    } else {
      return _MemberListItemPos.last;
    }
  }
}

class _MemberStatusWidget extends StatelessWidget {
  final GroupMemberStatus? memberStatus;

  _MemberStatusWidget(this.memberStatus);

  @override
  Widget build(BuildContext context) =>
    Container(padding: _widgetPadding, decoration: _widgetDecoration, child:
      Text(groupMemberStatusToDisplayString(memberStatus)?.toUpperCase() ?? '', style: Styles().textStyles.getTextStyle('widget.heading.extra_small')),
    );

  EdgeInsetsGeometry get _widgetPadding => EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  BoxDecoration get _widgetDecoration => BoxDecoration(
    color: groupMemberStatusToColor(memberStatus),
    borderRadius: BorderRadius.all(Radius.circular(2)),
  );
}
