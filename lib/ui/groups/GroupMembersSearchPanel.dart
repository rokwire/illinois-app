import 'package:flutter/material.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/FirebaseMessaging.dart';
import 'package:neom/ui/groups/GroupMembersPanel.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:neom/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class GroupMembersSearchPanel extends StatefulWidget{
  final GroupMemberStatus? selectedMemberStatus;
  final Group? group;

  const GroupMembersSearchPanel({super.key, this.selectedMemberStatus, this.group});

  @override
  State<StatefulWidget> createState() => _GroupMembersSearchState();

}

class _GroupMembersSearchState extends State<GroupMembersSearchPanel> implements NotificationsListener{
  static final int _defaultMembersLimit = 10;

  List<Member>? _visibleMembers;
  int? _membersOffset;
  int? _membersLimit;
  ScrollController? _scrollController;
  int _loadingProgress = 0;
  bool _isLoadingMembers = false;

  String? _searchTextValue;
  TextEditingController _searchEditingController = TextEditingController();
  late FocusNode _searchFocus;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Groups.notifyGroupMembershipApproved,
      Groups.notifyGroupMembershipRejected,
      Groups.notifyGroupMembershipRemoved,
      FirebaseMessaging.notifyGroupsNotification,
    ]);

    _searchFocus = FocusNode();
    _scrollController = ScrollController();
    _scrollController!.addListener(_scrollListener);
    _reloadMembers();
    super.initState();
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  void onNotification(String name, param) {
    bool reloadMembers = false;
    if ((name == Groups.notifyGroupMembershipApproved) ||
        (name == Groups.notifyGroupMembershipRejected) ||
        (name == Groups.notifyGroupMembershipRemoved)) {
      Group? group = (param is Group) ? param : null;
      reloadMembers = (group?.id != null) && (group?.id == widget.group?.id);
    }
    else if (name == FirebaseMessaging.notifyGroupsNotification) {
      String? groupId = (param is Map) ? JsonUtils.stringValue(param['entity_id']) : null;
      reloadMembers = (groupId != null) && (groupId == widget.group?.id);
    }

    if (reloadMembers) {
      _reloadMembers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("", "Search"),//TBD localize
      ),
      body:  _isLoading
          ? Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary)))
          : RefreshIndicator(
          onRefresh: _onPullToRefresh,
          child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              child: _buildMembersContent())),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildMembersContent() {
    late Widget contentWidget;
    if (CollectionUtils.isEmpty(_visibleMembers)) {
      contentWidget = Center(
          child: Column(children: <Widget>[
            Container(height: MediaQuery.of(context).size.height / 5),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(_emptyMembersMessage, textAlign: TextAlign.center,
                    style: Styles().textStyles.getTextStyle('widget.group.members.title'))),
            Container(height: MediaQuery.of(context).size.height / 4)
          ]));
    } else {
      List<Widget> members = [];
      for (Member member in _visibleMembers!) {
        if (members.isNotEmpty) {
          members.add(Container(height: 10));
        }
        late Widget memberCard;
        if (member.status == GroupMemberStatus.pending) {
          memberCard = PendingMemberCard(member: member, group: widget.group);
        } else {
          memberCard = GroupMemberCard(member: member, group: widget.group);
        }
        members.add(memberCard);
      }
      if (members.isNotEmpty) {
        members.add(Container(height: 10));
      }
      contentWidget = Padding(padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: members));
    }
    return Padding(padding: EdgeInsets.only(top: 0), child:
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
          _buildMembersSearch(),
          _buildSearchLabel(),
          Container(height: 8,),
          contentWidget
      ]));
  }

  Widget _buildMembersSearch() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Container(
        padding: EdgeInsets.only(left: 16),
        color: Colors.white,
        height: 48,
        child: Row(
          children: <Widget>[
            Flexible(
                child:
                Semantics(
                  label: Localization().getStringEx('panel.manage_members.field.search.title', 'Search'),
                  hint: Localization().getStringEx('panel.manage_members.field.search.hint', ''),
                  textField: true,
                  excludeSemantics: true,
                  child: TextField(
                    controller: _searchEditingController,
                    onChanged: (text) => _onSearchTextChanged(text),
                    onSubmitted: (_) => _onTapSearch(),
                    autofocus: false,
                    focusNode: _searchFocus,
                    cursorColor: Styles().colors.fillColorSecondary,
                    keyboardType: TextInputType.text,
                    style:  Styles().textStyles.getTextStyle('widget.group.members.search'),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                )
            ),
            Semantics(
                label: Localization().getStringEx('panel.manage_members.button.search.clear.title', 'Clear'),
                hint: Localization().getStringEx('panel.manage_members.button.search.clear.hint', ''),
                button: true,
                excludeSemantics: true,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: GestureDetector(
                    onTap: _onTapClearSearch,
                    child: Styles().images.getImage('clear', excludeFromSemantics: true),
                  ),
                )
            ),
            Semantics(
              label: Localization().getStringEx('panel.manage_members.button.search.title', 'Search'),
              hint: Localization().getStringEx('panel.manage_members.button.search.hint', ''),
              button: true,
              excludeSemantics: true,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: _onTapSearch,
                  child: Styles().images.getImage('search', excludeFromSemantics: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchLabel(){
    return Padding(
        padding: EdgeInsets.all(16),
        child: RichText(
          text: TextSpan(
            style: Styles().textStyles.getTextStyle("widget.title.large"),
            children: <TextSpan>[
              TextSpan(
                text: "Searching ",
              ),
              TextSpan(
                text: _defaultSearchLabelValue,
                style: Styles().textStyles.getTextStyle("widget.title.large.semi_fat"),),
              TextSpan(
                text: widget.selectedMemberStatus == null? "" : " only",
              ),
            ],

          ),
        ));
  }

  void _onSearchTextChanged(String text) {
    // implement if needed
  }

  void _onTapSearch() {
    Analytics().logSelect(target: "Search");
    if(!_searchFocus.hasFocus){
      FocusScope.of(context).requestFocus(_searchFocus);
    }
    String? initialSearchTextValue = _searchTextValue;
    _searchTextValue = _searchEditingController.text.toString();
    String? currentSearchTextValue = _searchTextValue;
    if (!(StringUtils.isEmpty(initialSearchTextValue) && StringUtils.isEmpty(currentSearchTextValue))) {
      FocusScope.of(context).unfocus();
      Analytics().logSearch(currentSearchTextValue ?? '');
      _reloadMembers();
    }
  }

  void _onTapClearSearch() {
    if(_searchFocus.hasFocus){
      _searchFocus.unfocus();
    }

    if (StringUtils.isNotEmpty(_searchTextValue)) {
      _searchEditingController.text = "";
      _searchTextValue = "";
      _reloadMembers();
    }
  }

  void _reloadMembers() {
    _membersOffset = 0;
    _membersLimit = _defaultMembersLimit;
    _visibleMembers = null;
    _loadMembers();
  }

  void _loadMembers({bool showLoadingIndicator = true}) {
    if (!_isLoadingMembers && ((_visibleMembers == null) || ((_membersLimit != null) && (_membersOffset != null)))) {
      _isLoadingMembers = true;
      if (showLoadingIndicator) {
        _increaseProgress();
      }
      List<GroupMemberStatus>? memberStatuses;
      if (widget.selectedMemberStatus != null) {
        memberStatuses = [widget.selectedMemberStatus!];
      }
      Groups().loadMembers(groupId: widget.group?.id, name: _searchTextValue, statuses: memberStatuses, offset: _membersOffset, limit: _membersLimit).then((members) {
        _isLoadingMembers = false;
        int resultsCount = members?.length ?? 0;

        if (resultsCount > 0) {
          if (_visibleMembers == null) {
            _visibleMembers = <Member>[];
          }
          _visibleMembers!.addAll(members!);
          _membersOffset = (_membersOffset ?? 0) + resultsCount;
          _membersLimit = 10;
        }
        else {
          _membersOffset = null;
          _membersLimit = null;
        }

        if (showLoadingIndicator) {
          _decreaseProgress();
        } else {
          _updateState();
        }
      });
    }
  }

  Future<void> _onPullToRefresh() async {
    _reloadMembers();
  }

  void _scrollListener() {
    if ((_scrollController!.offset >= _scrollController!.position.maxScrollExtent)) {
      _loadMembers(showLoadingIndicator: false);
    }
  }

  void _increaseProgress() {
    _loadingProgress++;
    _updateState();
  }

  void _decreaseProgress() {
    _loadingProgress--;
    _updateState();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isResearchProject {
    return widget.group?.researchProject == true;
  }

  bool get _isLoading {
    return (_loadingProgress > 0);
  }

  String get _defaultSearchLabelValue => _memberStatusToString(widget.selectedMemberStatus);

  String get _emptyMembersMessage {
    switch (widget.selectedMemberStatus) {
      case GroupMemberStatus.admin:
        return _isResearchProject ? Localization().getStringEx('panel.manage_members.status.admin.empty.project.message', 'There are no principal investigators.') : Localization().getStringEx('panel.manage_members.status.admin.empty.message', 'There are no admins.');
      case GroupMemberStatus.member:
        return _isResearchProject ? Localization().getStringEx('panel.manage_members.status.member.empty.project.message', 'There are no participants.') : Localization().getStringEx('panel.manage_members.status.member.empty.message', 'There are no members.');
      case GroupMemberStatus.pending:
        return _isResearchProject ? Localization().getStringEx('panel.manage_members.status.pending.empty.project.message', 'There are no pending participants.') : Localization().getStringEx('panel.manage_members.status.pending.empty.message', 'There are no pending members.');
      case GroupMemberStatus.rejected:
        return _isResearchProject ? Localization().getStringEx('panel.manage_members.status.rejected.empty.project.message', 'There are no rejected participants.') : Localization().getStringEx('panel.manage_members.status.rejected.empty.message', 'There are no rejected members.');
      default: // All
        return _isResearchProject ? Localization().getStringEx('panel.manage_members.status.all.empty.project.message', 'There are no participants.') : Localization().getStringEx('panel.manage_members.status.all.empty.message', 'There are no members.');
    }
  }

  String _memberStatusToString(GroupMemberStatus? status) {
    switch (status) {
      case GroupMemberStatus.admin:
        return _isResearchProject ? Localization().getStringEx('', 'principal investigators') : Localization().getStringEx('', 'admins');
      case GroupMemberStatus.member:
        return _isResearchProject ? Localization().getStringEx('', 'participants') : Localization().getStringEx('', 'members');
      case GroupMemberStatus.pending:
        return _isResearchProject ? Localization().getStringEx('', 'pending participants') : Localization().getStringEx('', 'pending members');
      case GroupMemberStatus.rejected:
        return _isResearchProject ? Localization().getStringEx('', 'rejected participants') : Localization().getStringEx('', 'rejected members');
      default:
        return _isResearchProject ? Localization().getStringEx('', 'all participants') : Localization().getStringEx('', 'all members');
    }
  }
}