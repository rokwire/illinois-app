/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class GroupPostDetailPanel extends StatefulWidget {
  final GroupPost post;
  final Group group;
  final bool postReply;

  GroupPostDetailPanel(
      {@required this.group, this.post, this.postReply = false});

  @override
  _GroupPostDetailPanelState createState() => _GroupPostDetailPanelState();
}

class _GroupPostDetailPanelState extends State<GroupPostDetailPanel>
    implements NotificationsListener {
  static final double _outerPadding = 16;
  static final double _sliverHeaderHeight = 110;

  GroupPost _post;
  TextEditingController _subjectController = TextEditingController();
  TextEditingController _bodyController = TextEditingController();
  TextEditingController _linkController = TextEditingController();
  final ItemScrollController _positionedScrollController =
      ItemScrollController();
  String _selectedReplyId;
  bool _private = true;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, Groups.notifyGroupPostsUpdated);
    _post = widget.post;
    if (widget.postReply) {
      _selectedReplyId = _post?.id; // default reply to the main post
    }
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
    _subjectController.dispose();
    _bodyController.dispose();
    _linkController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _postBuildCallback();
    return Scaffold(
        appBar: AppBar(
            leading: HeaderBackButton(),
            title: Text(
              Localization()
                  .getStringEx('panel.group.detail.post.header.title', 'Post'),
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: Styles().fontFamilies.extraBold,
                  letterSpacing: 1),
            ),
            centerTitle: true),
        backgroundColor: Styles().colors.background,
        bottomNavigationBar: TabBarWidget(),
        body: Stack(children: [
          Stack(alignment: Alignment.topCenter, children: [
            ScrollablePositionedList.builder(
                itemCount: 2,
                itemBuilder: (context, index) =>
                    _buildPositionedItem(context, index),
                itemScrollController: _positionedScrollController),
            Visibility(
                visible: !_isCreatePost,
                child: Container(
                    height: _sliverHeaderHeight,
                    color: Styles().colors.background,
                    padding: EdgeInsets.only(left: _outerPadding),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                              sortKey: OrdinalSortKey(1),
                              container: true,
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                        child: Text(
                                            AppString.getDefaultEmptyString(
                                                value: _post?.subject),
                                            maxLines: 5,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontFamily:
                                                    Styles().fontFamilies.bold,
                                                fontSize: 24,
                                                color: Styles()
                                                    .colors
                                                    .fillColorPrimary))),
                                    Visibility(
                                        visible: _isDeletePostVisible,
                                        child: Semantics(
                                            container: true,
                                            sortKey: OrdinalSortKey(5),
                                            child: Container(
                                                child: Semantics(
                                                    label: Localization()
                                                        .getStringEx(
                                                            'panel.group.detail.post.reply.delete.label',
                                                            "Delete"),
                                                    button: true,
                                                    child: GestureDetector(
                                                        onTap: _onTapDeletePost,
                                                        child: Container(
                                                            color: Colors
                                                                .transparent,
                                                            child: Padding(
                                                                padding: EdgeInsets.only(
                                                                    left: 16,
                                                                    top: 22,
                                                                    bottom: 10,
                                                                    right: (_isReplyVisible
                                                                        ? (_outerPadding /
                                                                            2)
                                                                        : _outerPadding)),
                                                                child:
                                                                    Image.asset(
                                                                  'images/trash.png',
                                                                  width: 20,
                                                                  height: 20,
                                                                  excludeFromSemantics:
                                                                      true,
                                                                )))))))),
                                    Visibility(
                                        visible: _isReplyVisible,
                                        child: Semantics(
                                            label: Localization().getStringEx(
                                                'panel.group.detail.post.reply.reply.label',
                                                "Reply"),
                                            button: true,
                                            child: GestureDetector(
                                                onTap: _onTapReply,
                                                child: Container(
                                                    color: Colors.transparent,
                                                    child: Padding(
                                                        padding: EdgeInsets.only(
                                                            left:
                                                                (_isDeletePostVisible
                                                                    ? 8
                                                                    : 16),
                                                            top: 22,
                                                            bottom: 10,
                                                            right:
                                                                _outerPadding),
                                                        child: Image.asset(
                                                          'images/icon-group-post-reply.png',
                                                          width: 20,
                                                          height: 20,
                                                          fit: BoxFit.fill,
                                                          excludeFromSemantics:
                                                              true,
                                                        ))))))
                                  ])),
                          Semantics(
                              sortKey: OrdinalSortKey(2),
                              container: true,
                              child: Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                      AppString.getDefaultEmptyString(
                                          value: _post?.member?.name),
                                      style: TextStyle(
                                          fontFamily:
                                              Styles().fontFamilies.medium,
                                          fontSize: 20,
                                          color: Styles()
                                              .colors
                                              .fillColorPrimary)))),
                          Semantics(
                              sortKey: OrdinalSortKey(3),
                              container: true,
                              child: Padding(
                                  padding: EdgeInsets.only(top: 3),
                                  child: Text(
                                      AppString.getDefaultEmptyString(
                                          value: _post?.displayDateTime),
                                      style: TextStyle(
                                          fontFamily:
                                              Styles().fontFamilies.medium,
                                          fontSize: 16,
                                          color: Styles()
                                              .colors
                                              .fillColorPrimary)))),
                        ])))
          ]),
          Visibility(
              visible: _loading,
              child: Center(child: CircularProgressIndicator()))
        ]));
  }

  Widget _buildPositionedItem(BuildContext context, int index) {
    switch (index) {
      case 0:
        return _buildPostContent();
      case 1:
        return _buildPostEdit();
      default:
        return Container();
    }
  }

  Widget _buildPostContent() {
    return Semantics(
        sortKey: OrdinalSortKey(4),
        container: true,
        child: Visibility(
            visible: !_isCreatePost,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: EdgeInsets.only(
                      left: _outerPadding,
                      top: _sliverHeaderHeight,
                      right: _outerPadding),
                  child: Html(
                      data: AppString.getDefaultEmptyString(value: _post?.body),
                      style: {
                        "body": Style(
                            color: Styles().colors.fillColorPrimary,
                            fontFamily: Styles().fontFamilies.regular,
                            fontSize: FontSize(20))
                      })),
              Padding(
                  padding: EdgeInsets.only(
                      left: _outerPadding,
                      right: _outerPadding,
                      bottom: _outerPadding),
                  child: _buildRepliesWidget(replies: _post?.replies))
            ])));
  }

  Widget _buildPostEdit() {
    return Padding(
        padding: EdgeInsets.all(_outerPadding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Visibility(
              visible: _privateSwitchVisible,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        Localization().getStringEx(
                            'panel.group.detail.post.create.private.label',
                            'Private'),
                        style: TextStyle(
                            fontSize: 18,
                            fontFamily: Styles().fontFamilies.bold,
                            color: Styles().colors.fillColorPrimary)),
                    GestureDetector(
                        onTap: _onTapPrivate,
                        child: Image.asset(_private
                            ? 'images/switch-on.png'
                            : 'images/switch-off.png'))
                  ])),
          Visibility(
              visible: _isCreatePost,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: EdgeInsets.only(
                            top: _privateSwitchVisible ? 16 : 0),
                        child: Text(
                            Localization().getStringEx(
                                'panel.group.detail.post.create.subject.label',
                                'Subject'),
                            style: TextStyle(
                                fontSize: 18,
                                fontFamily: Styles().fontFamilies.bold,
                                color: Styles().colors.fillColorPrimary))),
                    Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: TextField(
                            controller: _subjectController,
                            maxLines: 1,
                            decoration: InputDecoration(
                                hintText: Localization().getStringEx(
                                    'panel.group.detail.post.create.subject.field.hint',
                                    'Write a Subject'),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Styles().colors.mediumGray,
                                        width: 0.0))),
                            style: TextStyle(
                                color: Styles().colors.textBackground,
                                fontSize: 16,
                                fontFamily: Styles().fontFamilies.regular)))
                  ])),
          Padding(
              padding: EdgeInsets.only(
                  top: (_privateSwitchVisible || _isCreatePost) ? 16 : 0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                        Localization().getStringEx(
                            'panel.group.detail.post.create.body.label',
                            'Body'),
                        style: TextStyle(
                            fontSize: 18,
                            fontFamily: Styles().fontFamilies.bold,
                            color: Styles().colors.fillColorPrimary)),
                    Padding(
                        padding: EdgeInsets.only(left: 30),
                        child: GestureDetector(
                            onTap: _onTapBold,
                            child: Text('B',
                                style: TextStyle(
                                    fontSize: 24,
                                    color: Styles().colors.fillColorPrimary,
                                    fontFamily: Styles().fontFamilies.bold)))),
                    Padding(
                        padding: EdgeInsets.only(left: 20),
                        child: GestureDetector(
                            onTap: _onTapItalic,
                            child: Text('I',
                                style: TextStyle(
                                    fontSize: 24,
                                    color: Styles().colors.fillColorPrimary,
                                    fontFamily:
                                        Styles().fontFamilies.mediumIt)))),
                    Padding(
                        padding: EdgeInsets.only(left: 20),
                        child: GestureDetector(
                            onTap: _onTapUnderline,
                            child: Text('U',
                                style: TextStyle(
                                    fontSize: 24,
                                    color: Styles().colors.fillColorPrimary,
                                    fontFamily: Styles().fontFamilies.medium,
                                    decoration: TextDecoration.underline,
                                    decorationThickness: 2,
                                    decorationColor:
                                        Styles().colors.fillColorPrimary)))),
                    Padding(
                        padding: EdgeInsets.only(left: 20),
                        child: GestureDetector(
                            onTap: _onTapLink,
                            child: Text(
                                Localization().getStringEx(
                                    'panel.group.detail.post.create.link.label',
                                    'Link'),
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Styles().colors.fillColorPrimary,
                                    fontFamily:
                                        Styles().fontFamilies.medium)))),
                  ])),
          Padding(
              padding: EdgeInsets.only(top: 8, bottom: _outerPadding),
              child: TextField(
                  toolbarOptions:
                      ToolbarOptions(copy: false, cut: false, selectAll: false),
                  controller: _bodyController,
                  maxLines: 15,
                  decoration: InputDecoration(
                      hintText: Localization().getStringEx(
                          "panel.group.detail.post.create.body.field.hint",
                          "Write a Body"),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Styles().colors.mediumGray, width: 0.0))),
                  style: TextStyle(
                      color: Styles().colors.textBackground,
                      fontSize: 16,
                      fontFamily: Styles().fontFamilies.regular))),
          Row(children: [
            Flexible(
                flex: 1,
                child: RoundedButton(
                    label: Localization().getStringEx(
                        'panel.group.detail.post.create.button.send.title',
                        'Send'),
                    borderColor: Styles().colors.fillColorSecondary,
                    textColor: Styles().colors.fillColorPrimary,
                    backgroundColor: Styles().colors.white,
                    onTap: _onTapSend)),
            Container(width: 20),
            Flexible(
                flex: 1,
                child: RoundedButton(
                    label: Localization().getStringEx(
                        'panel.group.detail.post.create.button.cancel.title',
                        'Cancel'),
                    borderColor: Styles().colors.textSurface,
                    textColor: Styles().colors.fillColorPrimary,
                    backgroundColor: Styles().colors.white,
                    onTap: _onTapCancel))
          ])
        ]));
  }

  Widget _buildRepliesWidget(
      {List<GroupPost> replies,
      double leftPaddingOffset = 0,
      bool nestedReply = false}) {
    List<GroupPost> visibleReplies = _getVisibleReplies(replies);
    if (AppCollection.isCollectionEmpty(visibleReplies)) {
      return Container();
    }
    List<Widget> replyWidgetList = [];
    for (int i = 0; i < visibleReplies.length; i++) {
      if (i > 0 || nestedReply) {
        replyWidgetList.add(Container(height: 10));
      }
      GroupPost reply = visibleReplies[i];
      String optionsIconPath;
      Function optionsFunctionTap;
      if (_isReplyOptionsVisible(reply)) {
        optionsIconPath = 'images/icon-groups-options-orange.png';
        optionsFunctionTap = () => _onTapReplyOptions(reply);
      }
      replyWidgetList.add(Padding(
          padding: EdgeInsets.only(left: leftPaddingOffset),
          child: GroupReplyCard(
              reply: reply,
              group: widget.group,
              iconPath: optionsIconPath,
              semanticsLabel: "options",
              onIconTap: optionsFunctionTap)));
      replyWidgetList.add(_buildRepliesWidget(
          replies: reply?.replies,
          leftPaddingOffset: (leftPaddingOffset + 5),
          nestedReply: true));
    }
    return Padding(
        padding: EdgeInsets.only(top: nestedReply ? 0 : 20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: replyWidgetList));
  }

  List<GroupPost> _getVisibleReplies(List<GroupPost> replies) {
    if (AppCollection.isCollectionEmpty(replies)) {
      return null;
    }
    List<GroupPost> visibleReplies = [];
    bool currentUserIsMemberOrAdmin =
        widget.group?.currentUserIsMemberOrAdmin ?? false;
    for (GroupPost reply in replies) {
      bool replyVisible = (reply.private == false) ||
          (reply.private == null) ||
          currentUserIsMemberOrAdmin;
      if (replyVisible) {
        visibleReplies.add(reply);
      }
    }
    return visibleReplies;
  }

  void _onTapDeletePost() {
    AppAlert.showCustomDialog(
        context: context,
        contentWidget: Text(Localization().getStringEx(
            'panel.group.detail.post.delete.confirm.msg',
            'Are you sure that you want to delete this post?')),
        actions: <Widget>[
          TextButton(
              child:
                  Text(Localization().getStringEx('dialog.yes.title', 'Yes')),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePost();
              }),
          TextButton(
              child: Text(Localization().getStringEx('dialog.no.title', 'No')),
              onPressed: () => Navigator.of(context).pop())
        ]);
  }

  void _deletePost() {
    _setLoading(true);
    Groups().deletePost(widget.group?.id, _post?.id).then((succeeded) {
      _setLoading(false);
      if (succeeded) {
        Navigator.of(context).pop();
      } else {
        AppAlert.showDialogResult(
            context,
            Localization().getStringEx(
                'panel.group.detail.post.delete.failed.msg',
                'Failed to delete post.'));
      }
    });
  }

  void _onTapReplyOptions(GroupPost reply) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Styles().colors.white,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RibbonButton(
                  height: null,
                  leftIcon: "images/trash.png",
                  label: Localization().getStringEx(
                      "panel.group.detail.post.reply.delete.label", "Delete"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _onTapDeleteReply(reply);
                  },
                ),
                RibbonButton(
                  height: null,
                  leftIcon: "images/icon-group-post-reply.png",
                  label: Localization().getStringEx(
                      "panel.group.detail.post.reply.reply.label", "Reply"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _onTapReply(reply: reply);
                  },
                ),
              ],
            ),
          );
        });
  }

  void _onTapDeleteReply(GroupPost reply) {
    AppAlert.showCustomDialog(
        context: context,
        contentWidget: Text(Localization().getStringEx(
            'panel.group.detail.post.reply.delete.confirm.msg',
            'Are you sure that you want to delete this reply?')),
        actions: <Widget>[
          TextButton(
              child:
                  Text(Localization().getStringEx('dialog.yes.title', 'Yes')),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteReply(reply?.id);
              }),
          TextButton(
              child: Text(Localization().getStringEx('dialog.no.title', 'No')),
              onPressed: () => Navigator.of(context).pop())
        ]);
  }

  void _deleteReply(String replyId) {
    _setLoading(true);
    _clearSelectedReplyId();
    Groups().deletePost(widget.group?.id, replyId).then((succeeded) {
      _setLoading(false);
      if (!succeeded) {
        AppAlert.showDialogResult(
            context,
            Localization().getStringEx(
                'panel.group.detail.post.reply.delete.failed.msg',
                'Failed to delete reply.'));
      }
    });
  }

  void _onTapReply({GroupPost reply}) {
    _selectedReplyId = AppString.getDefaultEmptyString(
        value: reply?.id, defaultValue: _post?.id);
    if (mounted) {
      setState(() {});
    }
  }

  void _reloadPost() {
    _setLoading(true);
    Groups().loadGroupPosts(widget.group?.id).then((posts) {
      if (AppCollection.isCollectionNotEmpty(posts)) {
        _post = posts.firstWhere((post) => (post.id == _post?.id));
      } else {
        _post = null;
      }
      _setLoading(false);
    });
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _loading = loading;
      });
    }
  }

  bool _isReplyOptionsVisible(GroupPost reply) {
    if (reply == null) {
      return false;
    } else if (widget.group?.currentUserIsAdmin ?? false) {
      return true;
    } else if (widget.group?.currentUserIsUserMember ?? false) {
      String currentMemberEmail = widget.group?.currentUserAsMember?.email;
      String replyMemberEmail = reply?.member?.email;
      return AppString.isStringNotEmpty(currentMemberEmail) &&
          AppString.isStringNotEmpty(replyMemberEmail) &&
          (currentMemberEmail == replyMemberEmail);
    } else {
      return false;
    }
  }

  void _onTapCancel() {
    Navigator.of(context).pop();
  }

  void _onTapSend() {
    FocusScope.of(context).unfocus();
    String subject = _subjectController.text;
    if (_isCreatePost && AppString.isStringEmpty(subject)) {
      AppAlert.showDialogResult(
          context,
          Localization().getStringEx(
              'panel.group.detail.post.create.validation.subject.msg',
              "Please, populate 'Subject' field"));
      return;
    }
    String body = _bodyController.text;
    if (AppString.isStringEmpty(body)) {
      AppAlert.showDialogResult(
          context,
          Localization().getStringEx(
              'panel.group.detail.post.create.validation.body.msg',
              "Please, populate 'Body' field"));
      return;
    }
    _setLoading(true);
    GroupPost post;
    if (_isCreatePost) {
      post = GroupPost(subject: subject, body: body, private: _private);
    } else {
      post = GroupPost(
          parentId: AppString.getDefaultEmptyString(
              value: _selectedReplyId, defaultValue: _post?.id),
          body: body,
          private: _private);
    }
    Groups().createPost(widget.group?.id, post).then((succeeded) {
      _onCreateFinished(succeeded);
    });
  }

  void _onCreateFinished(bool succeeded) {
    _setLoading(false);
    _clearSelectedReplyId();
    if (succeeded) {
      _bodyController.text = ''; //clear body content after successfull save
      if (_isCreatePost) {
        Navigator.of(context).pop();
      } else {
        _reloadPost();
      }
    } else {
      AppAlert.showDialogResult(
          context,
          _isCreatePost
              ? Localization().getStringEx(
                  'panel.group.detail.post.create.post.failed.msg',
                  'Failed to create new post.')
              : Localization().getStringEx(
                  'panel.group.detail.post.create.reply.failed.msg',
                  'Failed to create new reply.'));
    }
  }

  void _onTapPrivate() {
    if (mounted) {
      setState(() {
        _private = !_private;
      });
    }
  }

  void _onTapBold() {
    _wrapBodySelection('<b>', '</b>');
  }

  void _onTapItalic() {
    _wrapBodySelection('<i>', '</i>');
  }

  void _onTapUnderline() {
    _wrapBodySelection('<u>', '</u>');
  }

  void _onTapLink() {
    int linkStartPosition = _bodyController.selection.start;
    int linkEndPosition = _bodyController.selection.end;
    AppAlert.showCustomDialog(
        context: context,
        contentWidget: _buildLinkDialog(),
        actions: [
          TextButton(
              onPressed: () => _onTapOkLink(linkStartPosition, linkEndPosition),
              child: Text(Localization().getStringEx('dialog.ok.title', 'OK'))),
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                  Localization().getStringEx('dialog.cancel.title', 'Cancel')))
        ]);
  }

  Widget _buildLinkDialog() {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              Localization().getStringEx(
                  'panel.group.detail.post.create.dialog.link.edit.header',
                  'Edit Link'),
              style: TextStyle(
                  fontSize: 20,
                  color: Styles().colors.fillColorPrimary,
                  fontFamily: Styles().fontFamilies.medium)),
          Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                  Localization().getStringEx(
                      'panel.group.detail.post.create.dialog.link.label',
                      'Link to:'),
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: Styles().fontFamilies.regular,
                      color: Styles().colors.fillColorPrimary))),
          Padding(
              padding: EdgeInsets.only(top: 6),
              child: TextField(
                  controller: _linkController,
                  maxLines: 1,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Styles().colors.mediumGray, width: 0.0))),
                  style: TextStyle(
                      color: Styles().colors.textBackground,
                      fontSize: 16,
                      fontFamily: Styles().fontFamilies.regular)))
        ]);
  }

  void _onTapOkLink(int startPosition, int endPosition) {
    Navigator.of(context).pop();
    if ((startPosition < 0) || (endPosition < 0)) {
      return;
    }
    String link = _linkController.text;
    _linkController.text = '';
    _wrapBody('<a href="$link">', '</a>', startPosition, endPosition);
  }

  void _wrapBodySelection(String firstValue, String secondValue) {
    int startPosition = _bodyController.selection.start;
    int endPosition = _bodyController.selection.end;
    if ((startPosition < 0) || (endPosition < 0)) {
      return;
    }
    _wrapBody(firstValue, secondValue, startPosition, endPosition);
  }

  void _wrapBody(String firstValue, String secondValue, int startPosition,
      int endPosition) {
    String currentText = _bodyController.text;
    String result = AppString.wrapRange(
        currentText, firstValue, secondValue, startPosition, endPosition);
    _bodyController.text = result;
    _bodyController.selection = TextSelection.fromPosition(
        TextPosition(offset: (endPosition + firstValue.length)));
  }

  void _postBuildCallback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToPostEdit();
    });
  }

  void _scrollToPostEdit() {
    if (AppString.isStringNotEmpty(_selectedReplyId)) {
      // index = 2 is the index of the post edit control
      _positionedScrollController.scrollTo(
          index: 1, duration: Duration(milliseconds: 10));
    }
  }

  void _clearSelectedReplyId() {
    _selectedReplyId = null;
  }

  bool get _isDeletePostVisible {
    if (widget.group?.currentUserIsAdmin ?? false) {
      return true;
    } else {
      if (widget.group?.currentUserIsUserMember ?? false) {
        String currentMemberEmail = widget.group?.currentUserAsMember?.email;
        String postMemberEmail = _post?.member?.email;
        return AppString.isStringNotEmpty(currentMemberEmail) &&
            AppString.isStringNotEmpty(postMemberEmail) &&
            (currentMemberEmail == postMemberEmail);
      } else {
        return false;
      }
    }
  }

  bool get _isReplyVisible {
    return widget.group?.currentUserIsMemberOrAdmin ?? false;
  }

  bool get _privateSwitchVisible {
    return (widget.group?.privacy == GroupPrivacy.public);
  }

  bool get _isCreatePost {
    return (_post == null);
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == Groups.notifyGroupPostsUpdated) {
      _reloadPost();
    }
  }
}
