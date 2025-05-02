import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/polls/CreatePollPanel.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

import 'GroupWidgets.dart';

class GroupPostCreatePanel extends StatefulWidget with AnalyticsInfo {
  final Group group;
  final PostType type;

  GroupPostCreatePanel({required this.group, required this.type});

  @override
  State<StatefulWidget> createState() => _GroupPostCreatePanelState();

  @override
  AnalyticsFeature? get analyticsFeature => (group.researchProject == true) ? AnalyticsFeature.ResearchProject : AnalyticsFeature.Groups;

  @override
  Map<String, dynamic>? get analyticsPageAttributes => group.analyticsAttributes;
}

class _GroupPostCreatePanelState extends State<GroupPostCreatePanel>{
  static final double _outerPadding = 16;

  bool _allowSenPostToOtherGroups = false;
  bool _pinPost = false;
  PostDataModel _postData = PostDataModel();
  List<GroupPostNudge>? _postNudges;
  GroupPostNudge? _selectedNudge;
  int _progressLoading = 0;
  //Refresh
  GlobalKey _postImageHolderKey = GlobalKey();
  List<Member>? _selectedMembers;
  List<Member>? _allMembersAllowedToPost;

  @override
  void initState() {
    super.initState();
    _loadMembersAllowedToPost();
    _loadPostNudges();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        appBar: AppBar(
          leading: HeaderBackButton(),
          title: Text(
            widget.type == PostType.direct_message ?
            Localization().getStringEx('panel.group.detail.post.header.title.message', 'Message'):
            Localization().getStringEx('panel.group.detail.post.header.title', 'Post'),
            style: Styles().textStyles.getTextStyle("widget.heading.regular.extra_fat.light")
          ),
          centerTitle: false,
          titleSpacing: 0,),
        backgroundColor: Styles().colors.background,
        bottomNavigationBar: uiuc.TabBar(),
        body: Stack(alignment: Alignment.topCenter, children: [
          SingleChildScrollView(child:
          Column(children: [
            ImageChooserWidget(
              key: _postImageHolderKey,
              imageUrl: _postData.imageUrl,
              backgroundColor: Styles().colors.dividerLineAccent,
              onImageChanged: (url) => setStateIfMounted((){_postData.imageUrl = url;})),
            Container(
              padding: EdgeInsets.symmetric(horizontal: _outerPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12,),
                  Visibility(
                    visible: _canSelectMembers,
                    child: GroupMembersSelectionWidget(allMembers: _allMembersAllowedToPost, selectedMembers: _selectedMembers, groupId: _groupId, groupPrivacy: widget.group.privacy, onSelectionChanged: _onMembersSelectionChanged),
                  ),
                  Container(height: 12,),
                  _buildNudgesWidget(),
                  Container(height: 12,),
                  // Visibility(visible: _isPost,
                  //   child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Text(Localization().getStringEx('panel.group.detail.post.create.subject.label', 'Subject'),
                  //         style: Styles().textStyles.getTextStyle("widget.title.medium.fat"),),
                  //       Container(
                  //           padding: EdgeInsets.only(top: 8, bottom: 8),
                  //           decoration: PostInputField.fieldDecoration,
                  //           child: TextField(
                  //               controller: TextEditingController(text: _postData.subject),
                  //               onChanged: (msg)=> _postData.subject = msg,
                  //               maxLines: 1,
                  //               textCapitalization: TextCapitalization.sentences,
                  //               decoration: InputDecoration(
                  //                   fillColor: Colors.white,
                  //                   // hintText: Localization().getStringEx('panel.group.detail.post.create.subject.field.hint', 'Write a Subject'),
                  //                   border: InputBorder.none,
                  //                   contentPadding: EdgeInsets.all(8)
                  //               ),
                  //               style: Styles().textStyles.getTextStyle("widget.input_field.text.regular"))),
                  //       Container(height: 12,),
                  //   ],)
                  // ),
                  PostInputField(
                    title: widget.type == PostType.post ?  "" : "MESSAGE",
                    text: _postData.body,
                    hint: "Write a post...",
                    onBodyChanged: (text) => _postData.body = text,
                    // hint:  Localization().getStringEx( "panel.group.detail.post.create.body.field.hint",  "Write a Post ..."),
                  ),
                  Container(height: 12,),
                  _buildScheduleWidget(),
                  Container(height: 12,),
                  Visibility(visible: _isPost && _canPinPost,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: EnabledToggleButton(
                          label: "Pin post to top of all posts (Only one pinned post per group is allowed. Pinning this post will automatically unpin any past admin posts.)",
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                          enabled: CollectionUtils.isEmpty(_selectedMembers),
                          toggled: _pinPost,
                          textStyle: CollectionUtils.isEmpty(_selectedMembers) ?
                            Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.enabled") :
                            Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.disabled"),
                          backgroundColor: Styles().colors.background,
                          onTap: () {
                            if(mounted){
                              setState(() {
                                _pinPost = !_pinPost;
                              });
                            }
                          }
                      ),
                    )
                  ),
                  Visibility(visible: _isPost,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: EnabledToggleButton(
                            label: "Also post to additional groups...",
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                            enabled: CollectionUtils.isEmpty(_selectedMembers),
                            toggled: _allowSenPostToOtherGroups,
                            textStyle: CollectionUtils.isEmpty(_selectedMembers) ?
                            Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.enabled") :
                            Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.disabled"),
                            backgroundColor: Styles().colors.background,
                            onTap: () {
                              if(mounted){
                                setState(() {
                                  _allowSenPostToOtherGroups = !_allowSenPostToOtherGroups;
                                });
                              }
                            }
                        ),
                      )
                  ),
                  Container(height: 16,),
                  Row(children: [
                    Flexible(
                      flex: 1,
                      child: RoundedButton(
                        label: (_postData.dateScheduled == null)
                          ? Localization().getStringEx('panel.group.detail.post.create.button.send.title', 'Send')
                          : Localization().getStringEx('panel.group.detail.post.create.button.schedule.title', 'Schedule Post'),
                        textStyle: Styles().textStyles.getTextStyle("widget.input_field.light.text.regular"),
                        borderColor: Styles().colors.fillColorSecondary,
                        backgroundColor: Styles().colors.black,
                        maxBorderRadius: 6.0,
                        onTap: _onTapSend)),
                    Container(width: 16),
                    Flexible(
                      flex: 1,
                      child: RoundedButton(
                        label: Localization().getStringEx('panel.group.detail.post.create.button.cancel.title', 'Cancel'),
                        textStyle: Styles().textStyles.getTextStyle("widget.card.title.small"),
                        borderColor: Styles().colors.textDark,
                        backgroundColor: Styles().colors.fillColorSecondary,
                        maxBorderRadius: 6.0,
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                        onTap: _onTapCancel)),
                    Container(width: 140),
                  ]),
                  const SizedBox(height: 16,),
              ],),
            )

          ])),
          Visibility(
              visible: _isLoading,
              child: Center(child: CircularProgressIndicator())),
        ])
    );
  }

  Widget _buildNudgesWidget() {
    // Do not show the nudges for regular members
    if (!(widget.group.currentUserIsAdmin)) {
      return Container();
    }
    if (CollectionUtils.isEmpty(_postNudges)) {
      return Container();
    }
    return Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Localization().getStringEx('panel.group.detail.post.create.nudges.label', 'Nudges'),
              style: Styles().textStyles.getTextStyle("widget.title.medium.fat")),
          Padding(
              padding: EdgeInsets.only(top: 5),
              child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                      border: Border.all(color: Styles().colors.mediumGray, width: 1),
                      borderRadius: BorderRadius.all(Radius.circular(4))),
                  child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: DropdownButtonHideUnderline(
                          child: DropdownButton<GroupPostNudge?>(
                              icon: Icon(Icons.arrow_drop_down, color: Styles().colors.fillColorSecondary),
                              isExpanded: true,
                              style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
                              items: _nudgesDropDownItems,
                              value: _selectedNudge,
                              onChanged: _onNudgeChanged)))))
        ]));
  }

  Widget _buildScheduleWidget(){
    return Visibility( visible: _canSchedule,
      child: GroupScheduleTimeWidget(
        scheduleTime: _postData.dateScheduled,
        onDateChanged: (DateTime? dateTimeUtc) => setStateIfMounted(() => _postData.dateScheduled = dateTimeUtc),
        showOnlyDropdown: true,
        enableTimeZone: true,
      )
    );
  }

  void _clearScheduleDate(){
    if( _postData.dateScheduled != null){
      _postData.dateScheduled = null;
    }
  }

  void _onMembersSelectionChanged(List<Member>? selectedMembers){
    _selectedMembers = selectedMembers;
    _clearScheduleDate(); //Members Selection disables scheduling
    setStateIfMounted();
  }

  List<DropdownMenuItem<GroupPostNudge?>> get _nudgesDropDownItems {
    List<DropdownMenuItem<GroupPostNudge?>> items = [];
    if (CollectionUtils.isNotEmpty(_postNudges)) {
      for (GroupPostNudge nudge in _postNudges!) {
        items.add(DropdownMenuItem(value: nudge, child: Text(StringUtils.ensureNotEmpty(nudge.subject))));
      }
    }
    items.add(DropdownMenuItem(
        value: null, child: Text(Localization().getStringEx('panel.group.detail.post.create.nudges.none.label', 'None'))));
    return items;
  }

  void _onNudgeChanged(GroupPostNudge? nudge) {
    _selectedNudge = nudge;
    String? subject;
    String? body;
    if (_selectedNudge != null) {
      subject = _selectedNudge?.subject;
      body = _selectedNudge?.body;
      _showPollConfirmationDialogIfNeeded();
    }
    _postData.subject = subject;
    _postData.body = body;
    setStateIfMounted();
  }

  void _showPollConfirmationDialogIfNeeded() {
    if (_selectedNudge?.canPoll ?? false) {
      AppAlert.showConfirmationDialog(context,
        message: Localization().getStringEx('panel.group.detail.post.create.nudges.create.poll.msg', 'Do you want to attach a Poll to the Post?'),
        positiveCallback: _onCreatePollConfirmed
      );
    }
  }

  void _onCreatePollConfirmed() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CreatePollPanel(group: widget.group))).then((poll) {
      if (poll is Poll) {
        String pollNudgeBodyMsg = sprintf(
            Localization().getStringEx('panel.group.detail.post.create.nudges.poll.body.msg', 'Please participate in the course Poll, #%s'),
            [StringUtils.ensureNotEmpty(poll.pinCode?.toString())]);
        _postData.body = StringUtils.ensureNotEmpty(_postData.body) + '\n\n $pollNudgeBodyMsg';
        setStateIfMounted();
      }
    });
  }

  //Tap actions
  void _onTapCancel() {
    Analytics().logSelect(target: 'Cancel');
    Navigator.of(context).pop();
  }

  void _onTapSend() async{
    Analytics().logSelect(target: 'Send');
    FocusScope.of(context).unfocus();

    String? body = _postData.body;
    String? imageUrl = _postData.imageUrl;
    String? subject = _postData.subject;
    DateTime? scheduleDate =  _postData.dateScheduled;
    // if (_isPost && StringUtils.isEmpty(subject)) {
    //   AppAlert.showDialogResult(context, Localization().getStringEx('panel.group.detail.post.create.validation.subject.msg', "Post subject required"));
    //   return;
    // }

    if (StringUtils.isEmpty(body)) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.group.detail.post.create.validation.body.msg', "Post message required"));
      return;
    }

    if (scheduleDate != null && scheduleDate.isBefore(DateTime.now())) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.group.detail.post.create.validation.schedule.msg', "Schedule time must be in future"));
      return;
    }

    String htmlModifiedBody = HtmlUtils.replaceNewLineSymbols(body);
    _increaseProgress();
    List<Group>? selectedGroups;
    if (_canSentToOtherAdminGroups) {
      selectedGroups = [];
      List<Group>? otherGroups = await _loadOtherAdminUserGroups();
      if (CollectionUtils.isNotEmpty(otherGroups)) {
        selectedGroups = await showDialog(context: context, barrierDismissible: true, builder: (_) => GroupsSelectionPopup(groups: otherGroups));
      }
    }
    late Post post;
    if (CollectionUtils.isNotEmpty(selectedGroups)) {
      List<String> groupIds = selectedGroups!.map((group) => group.id!).toList(growable: true);
      groupIds.add(_groupId); // add current group id.
      post = Post.forGroups(
          groupIds: groupIds, subject: subject, body: htmlModifiedBody, imageUrl: imageUrl, dateActivatedUtc: scheduleDate?.toUtc());
    } else {
      List<String>? memberAccountIds = MemberExt.extractUserIds(_selectedMembers);
      if (CollectionUtils.isNotEmpty(memberAccountIds)) {
        memberAccountIds!.add(Auth2().accountId!);
      }
      post = Post.forGroup(
          groupId: _groupId,
          subject: subject,
          body: htmlModifiedBody,
          imageUrl: imageUrl,
          dateActivatedUtc: scheduleDate?.toUtc(),
          memberAccountIds: memberAccountIds);
    }

    Social().createPost(post: post).then((Post? post) {
      if(_pinPost && StringUtils.isNotEmpty(post?.id)){
        Social().pinPost(postId: post!.id!).then((Post? pinnedPost){
          _onCreateFinished(pinnedPost);
        });
      } else {
        _onCreateFinished(post);
      }
    });
  }

  void _onCreateFinished(Post? post) {
    _decreaseProgress();
    if (post != null) {
      Navigator.of(context).pop(post);
    } else {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.group.detail.post.create.post.failed.msg', 'Failed to create new post.'));
    }
  }

  void _loadMembersAllowedToPost() {
    _increaseProgress();
    Groups().loadMembersAllowedToPost(groupId: _groupId).then((members) {
      _allMembersAllowedToPost = members;
      _decreaseProgress();
    });
  }

  void _loadPostNudges() {
    // Load post nudges only for admins
    if (widget.group.currentUserIsAdmin) {
      _increaseProgress();
      Groups().loadPostNudges(groupName: StringUtils.ensureNotEmpty(widget.group.title)).then((nudges) {
        _postNudges = nudges;
        _decreaseProgress();
      });
    }
  }

  //Copy from CreateEventPanel could be moved to Utils
  ///
  /// Returns the groups that current user is admin of without the current group
  ///
  Future<List<Group>?> _loadOtherAdminUserGroups() async {
    List<Group>? userGroups = await Groups().loadGroups(contentType: GroupsContentType.my);
    List<Group>? userAdminGroups;
    if (CollectionUtils.isNotEmpty(userGroups)) {
      userAdminGroups = [];
      for (Group? group in userGroups!) {
        if (group!.currentUserIsAdmin && (group.id != _groupId)) {
          userAdminGroups.add(group);
        }
      }
    }
    return userAdminGroups;
  }

  void _increaseProgress() {
    _progressLoading++;
    setStateIfMounted();
  }

  void _decreaseProgress() {
    _progressLoading--;
    setStateIfMounted();
  }

  bool get _isLoading {
    return (_progressLoading > 0);
  }

  bool get _canSelectMembers {
    return _isMessage && _userCanSelectMembers;
  }

  bool get _userCanSelectMembers => (widget.group.currentUserIsAdmin == true) ||
  (widget.group.currentUserIsMember &&
  widget.group.isMemberAllowedToPostToSpecificMembers);

  bool get _canSchedule =>  _isPost && CollectionUtils.isEmpty(_selectedMembers);

  bool get _canSentToOtherAdminGroups{
      return _allowSenPostToOtherGroups && CollectionUtils.isEmpty(_selectedMembers);
  }

  bool get _canPinPost =>  _isAdmin;

  bool get _isAdmin => widget.group.currentUserIsAdmin;

  String get _groupId => widget.group.id!;

  bool get _isMessage => widget.type ==  PostType.direct_message;

  bool get _isPost => widget.type ==  PostType.post;
}