import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/polls/CreatePollPanel.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

import 'GroupWidgets.dart';

class GroupPostCreatePanel extends StatefulWidget{
  final Group group;

  GroupPostCreatePanel({required this.group});

  @override
  State<StatefulWidget> createState() => _GroupPostCreatePanelState();
}

class _GroupPostCreatePanelState extends State<GroupPostCreatePanel>{
  static final double _outerPadding = 16;

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
            Localization().getStringEx('panel.group.detail.post.header.title', 'Post'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: Styles().fontFamilies!.extraBold,
              letterSpacing: 1),
          ),
          centerTitle: false),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: uiuc.TabBar(),
        body: Stack(alignment: Alignment.topCenter, children: [
          SingleChildScrollView(child:
          Column(children: [
            ImageChooserWidget(
              key: _postImageHolderKey,
              imageUrl: _postData.imageUrl,
              buttonVisible: true ,
              onImageChanged: (url) => _postData.imageUrl = url,),
            Container(
              padding: EdgeInsets.symmetric(horizontal: _outerPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12,),
                  GroupMembersSelectionWidget(allMembers: _allMembersAllowedToPost, selectedMembers: _selectedMembers, groupId: widget.group.id, onSelectionChanged: _onMembersSelectionChanged),
                  _buildNudgesWidget(),
                  Container(height: 12,),
                  Text(Localization().getStringEx('panel.group.detail.post.create.subject.label', 'Subject'),
                    style: TextStyle(
                        fontSize: 18,
                        fontFamily: Styles().fontFamilies!.bold,
                        color: Styles().colors!.fillColorPrimary)),
                  Padding(
                    padding: EdgeInsets.only(top: 8, bottom: _outerPadding),
                    child: TextField(
                      controller: TextEditingController(text: _postData.subject),
                      onChanged: (msg)=> _postData.subject = msg,
                      maxLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: Localization().getStringEx('panel.group.detail.post.create.subject.field.hint', 'Write a Subject'),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Styles().colors!.mediumGray!,
                              width: 0.0))),
                      style: TextStyle(
                        color: Styles().colors!.textBackground,
                        fontSize: 16,
                        fontFamily: Styles().fontFamilies!.regular))),
                  PostInputField(
                    text: _postData.body,
                    onBodyChanged: (text) => _postData.body = text,
                    hint:  Localization().getStringEx( "panel.group.detail.post.create.body.field.hint",  "Write a Post ..."),
                  ),
                  Row(children: [
                    Flexible(
                      flex: 1,
                      child: RoundedButton(
                        label: Localization().getStringEx('panel.group.detail.post.create.button.send.title', 'Send'),
                        borderColor: Styles().colors!.fillColorSecondary,
                        textColor: Styles().colors!.fillColorPrimary,
                        backgroundColor: Styles().colors!.white,
                        onTap: _onTapSend)),
                    Container(width: 20),
                    Flexible(
                      flex: 1,
                      child: RoundedButton(
                        label: Localization().getStringEx('panel.group.detail.post.create.button.cancel.title', 'Cancel'),
                        borderColor: Styles().colors!.textSurface,
                        textColor: Styles().colors!.fillColorPrimary,
                        backgroundColor: Styles().colors!.white,
                        onTap: _onTapCancel))
                  ])
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
              style: TextStyle(fontSize: 18, fontFamily: Styles().fontFamilies!.bold, color: Styles().colors!.fillColorPrimary)),
          Padding(
              padding: EdgeInsets.only(top: 5),
              child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                      border: Border.all(color: Styles().colors!.mediumGray!, width: 1),
                      borderRadius: BorderRadius.all(Radius.circular(4))),
                  child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: DropdownButtonHideUnderline(
                          child: DropdownButton<GroupPostNudge?>(
                              icon: Icon(Icons.arrow_drop_down, color: Styles().colors!.fillColorSecondary),
                              isExpanded: true,
                              style: TextStyle(
                                  fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textBackground),
                              items: _nudgesDropDownItems,
                              value: _selectedNudge,
                              onChanged: _onNudgeChanged)))))
        ]));
  }

  void _onMembersSelectionChanged(List<Member>? selectedMembers){
    _selectedMembers = selectedMembers;
    _updateState();
  }

  List<DropdownMenuItem<GroupPostNudge?>> get _nudgesDropDownItems {
    List<DropdownMenuItem<GroupPostNudge?>> items = [];
    if (CollectionUtils.isNotEmpty(_postNudges)) {
      for (GroupPostNudge nudge in _postNudges!) {
        items.add(DropdownMenuItem(value: nudge, child: Text(StringUtils.ensureNotEmpty(nudge.subject))));
      }
    }
    items.add(DropdownMenuItem(
        value: null, child: Text(Localization().getStringEx('panel.group.detail.post.create.nudges.custom.label', 'Custom'))));
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
    _updateState();
  }

  void _showPollConfirmationDialogIfNeeded() {
    if (_selectedNudge?.canPoll ?? false) {
      AppAlert.showConfirmationDialog(
          buildContext: context,
          message: Localization()
              .getStringEx('panel.group.detail.post.create.nudges.create.poll.msg', 'Do you want to attach a Poll to the Post?'),
          positiveCallback: _onCreatePollConfirmed);
    }
  }

  void _onCreatePollConfirmed() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CreatePollPanel(group: widget.group))).then((poll) {
      if (poll is Poll) {
        String pollNudgeBodyMsg = sprintf(
            Localization().getStringEx('panel.group.detail.post.create.nudges.poll.body.msg', 'Please participate in the course Poll, #%s'),
            [StringUtils.ensureNotEmpty(poll.pinCode?.toString())]);
        _postData.body = StringUtils.ensureNotEmpty(_postData.body) + '\n\n $pollNudgeBodyMsg';
        _updateState();
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
    if (StringUtils.isEmpty(subject)) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.group.detail.post.create.validation.subject.msg', "Post subject required"));
      return;
    }

    if (StringUtils.isEmpty(body)) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.group.detail.post.create.validation.body.msg', "Post message required"));
      return;
    }

    String htmlModifiedBody = HtmlUtils.replaceNewLineSymbols(body);
    _increaseProgress();
    List<Group> selectedGroups = [];
    List<Group>? otherGroupsToSave;

    selectedGroups.add(widget.group);
    // If the event is part of a group - allow the admin to select other groups that one wants to save the event as well.
    //If post has membersSelection then do not allow linking to other groups
    if (CollectionUtils.isEmpty(_selectedMembers)) {
        List<Group>? otherGroups = await _loadOtherAdminUserGroups();
        if (CollectionUtils.isNotEmpty(otherGroups)) {
          otherGroupsToSave = await showDialog(context: context, barrierDismissible: true, builder: (_) => GroupsSelectionPopup(groups: otherGroups,));
        }

        if(CollectionUtils.isNotEmpty(otherGroupsToSave)){
          selectedGroups.addAll(otherGroupsToSave!);
        }
    }

    GroupPost post = GroupPost(subject: subject, body: htmlModifiedBody, private: true, imageUrl: imageUrl, members: _selectedMembers); // if no parentId then this is a new post for the group.
    if(CollectionUtils.isNotEmpty(selectedGroups)) {
      List<Future<bool>> futures = [];
      for(Group group in selectedGroups){
        futures.add(Groups().createPost(group.id, post));
      }
      
      List<bool> results = await Future.wait(futures);
      _onCreateFinished(!results.contains(false));
    }
  }

  void _onCreateFinished(bool succeeded) {
    _decreaseProgress();
    if (succeeded) {
      Navigator.of(context).pop(true);
    } else {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.group.detail.post.create.post.failed.msg', 'Failed to create new post.'));
    }
  }

  void _loadMembersAllowedToPost() {
    _increaseProgress();
    Groups().loadMembersAllowedToPost(groupId: widget.group.id).then((members) {
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
      String? currentGroupId = widget.group.id;
      for (Group? group in userGroups!) {
        if (group!.currentUserIsAdmin && (group.id != currentGroupId)) {
          userAdminGroups.add(group);
        }
      }
    }
    return userAdminGroups;
  }

  void _increaseProgress() {
    _progressLoading++;
    _updateState();
  }

  void _decreaseProgress() {
    _progressLoading--;
    _updateState();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isLoading {
    return (_progressLoading > 0);
  }
}