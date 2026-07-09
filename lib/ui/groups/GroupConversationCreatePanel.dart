
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

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

  LinkedHashSet<String> _selectedMembers = LinkedHashSet<String>();

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
        _listHeading,
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
      itemBuilder: (context, index) => _buildMemberItem(ListUtils.entry(_displayMembers, index), decoration: _getMemberItemDecoration(index)),
      separatorBuilder: (context, index) => Divider(height: 1, color: _memberItemBorderColor,),
    ),
  );

  Widget _buildMemberItem(Member? member, { BoxDecoration? decoration }) =>
    Container(decoration: decoration, child:
      Row(children: [
        _buildMemberCheckButton(member),
        Expanded(child:
          Padding(padding: EdgeInsets.symmetric(vertical: 4), child:
            Text(member?.name ?? '', style: Styles().textStyles.getTextStyle('widget.title.regular.fat'),)
          )
        ),
        _buildMemberStatusIndicator(member),
      ],)
    );

  Widget _buildMemberCheckButton(Member? member) =>
    InkWell(onTap: () => _onTapMember(member), child:
      Padding(padding: EdgeInsets.all(12), child:
        Styles().images.getImage(_selectedMembers.contains(member?.userId) ? 'check-circle-filled' : 'check-circle-outline-gray', size: 24)
      ),
    );

  Widget _buildMemberStatusIndicator(Member? member) =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
      Container(padding: _memberStatusPadding, decoration: _getMemberStatusDecoration(member?.status), child:
        Text(groupMemberStatusToDisplayString(member?.status)?.toUpperCase() ?? '', style: Styles().textStyles.getTextStyle('widget.heading.extra_small')),
      ),
    );

  EdgeInsetsGeometry get _memberStatusPadding => EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  BoxDecoration _getMemberStatusDecoration(GroupMemberStatus? memberStatus) => BoxDecoration(
    color: groupMemberStatusToColor(memberStatus),
    borderRadius: BorderRadius.all(Radius.circular(2)),
  );


  BoxDecoration _getMemberItemDecoration(int index) {
    if (_displayMembers.length <= 1) {
      return _allMemberItemDecoration;
    } else if (index == 0) {
      return _firstMemberItemDecoration;
    } else if (index == _displayMembers.length - 1) {
      return _lastMemberItemDecoration;
    } else {
      return _memberItemDecoration;
    }
  }

  BoxDecoration get _memberItemDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border(left: _memberItemBorder, right: _memberItemBorder),
  );

  BoxDecoration get _firstMemberItemDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border(left: _memberItemBorder, right: _memberItemBorder, top: _memberItemBorder),
    borderRadius: BorderRadius.vertical(top: Radius.circular(8),),
  );

  BoxDecoration get _lastMemberItemDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border(left: _memberItemBorder, right: _memberItemBorder, bottom: _memberItemBorder),
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(8),),
  );

  BoxDecoration get _allMemberItemDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: _memberItemBorderColor, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(16))
  );

  BorderSide get _memberItemBorder =>  BorderSide(color: _memberItemBorderColor, width: 1);
  Color get _memberItemBorderColor => Styles().colors.surfaceAccent2;

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

  Widget get _searchClearButton => InkWell(onTap: _onSearchClear, child:
    Padding(padding: EdgeInsetsGeometry.only(left: 16, right: 8, top: 16, bottom: 16), child:
      Styles().images.getImage('close-circle', size: 18, color: (_hasEditSearchText || _searchText.isNotEmpty) ? Styles().colors.fillColorSecondary : Styles().colors.mediumGray2)
    )
  );

  Widget get _searchButton => InkWell(onTap: _onSearch, child:
    Padding(padding: EdgeInsetsGeometry.only(left: 8, right: 16, top: 16, bottom: 16), child:
      Styles().images.getImage('search', size: 18, color: _hasEditSearchText ? Styles().colors.fillColorSecondary : Styles().colors.mediumGray2)
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

  Widget get _listHeading => Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 16), child:
    Row(children: [
      Expanded(child:
        Text(Localization().getStringEx('', 'ALL MEMBERS'), style: Styles().textStyles.getTextStyle('widget.title.small.medium_fat'),),
      ),
      _selectAllButton,
    ],),
  );

  Widget get _selectAllButton => InkWell(onTap: _onSelectAll, child:
    Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 12), child:
      Text(_selectedMembers.containsAll(_displayMembers.map((member) => member.userId ?? '')) ?
        Localization().getStringEx('', 'Unselect All') : Localization().getStringEx('', 'Select All'), style: Styles().textStyles.getTextStyle('widget.button.title.small.fat.underline'),),
    )
  );

  // Selected Members Bar
  
  Widget get _selectedMembersBar => Container(padding: _selectedMembersPadding, decoration: _selectedMembersDecoration, child:
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.symmetric(vertical: 4), child:
        Text(Localization().getStringEx('', 'To: '), style: Styles().textStyles.getTextStyle('widget.title.regular.fat'),),
      ),
      Expanded(child: Wrap(children: [
        //TBD build
      ],))
    ],)
  );

  EdgeInsetsGeometry get _selectedMembersPadding => EdgeInsets.symmetric(horizontal: 16, vertical: 8);
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
          textStyle: _selectedMembers.isNotEmpty ? Styles().textStyles.getTextStyle("widget.button.title.regular") : Styles().textStyles.getTextStyleEx("widget.button.title.regular", color: Styles().colors.disabledTextColorTwo),
          borderColor: _selectedMembers.isNotEmpty ? Styles().colors.fillColorSecondary : Styles().colors.disabledTextColorTwo,
          enabled: _selectedMembers.isNotEmpty,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          borderWidth: 2,
          onTap:_onDone,
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
    if ((_membersActivity != ContentActivity.reload) && (_membersActivity != ContentActivity.refresh) && mounted) {
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
        if ((member.userId != null) && (searchLowercaseText.isEmpty || member.matchLowercaseText(searchLowercaseText))) {
          displayMembers.add(member);
        }
      }
    }
    return displayMembers;
  }

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
    Analytics().logSelect(target: 'Select All');
    Iterable<String> allMembers = _displayMembers.map((member) => member.userId ?? '');
    setState(() {
      if (_selectedMembers.containsAll(allMembers)) {
        _selectedMembers.clear();
      } else {
        _selectedMembers.addAll(allMembers);
      }
    });
  }

  void _onTapMember(Member? member) {
    Analytics().logSelect(target: 'Select Member');
    String memberId = member?.userId ?? '';
    setState(() {
      if (_selectedMembers.contains(memberId)) {
        _selectedMembers.remove(memberId);
      } else {
        _selectedMembers.add(memberId);
      }
    });
  }

  void _onDone() {
    Analytics().logSelect(target: 'Select All');
  }

}
