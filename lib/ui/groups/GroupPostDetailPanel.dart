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
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/groups/GroupCreatePostPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/utils/Utils.dart';

class GroupPostDetailPanel extends StatefulWidget {
  final GroupPost post;
  final Group group;

  GroupPostDetailPanel({@required this.post, @required this.group});

  @override
  _GroupPostDetailPanelState createState() => _GroupPostDetailPanelState();
}

class _GroupPostDetailPanelState extends State<GroupPostDetailPanel> implements NotificationsListener {
  static final double _outerPadding = 16;

  GroupPost _post;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, Groups.notifyGroupPostsUpdated);
    _post = widget.post;
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading: HeaderBackButton(),
            title: Text(
              Localization().getStringEx('panel.group.detail.post.header.title', 'Post'),
              style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: Styles().fontFamilies.extraBold, letterSpacing: 1),
            ),
            centerTitle: true),
        backgroundColor: Styles().colors.background,
        bottomNavigationBar: TabBarWidget(),
        body: Stack(children: [
          Stack(alignment: Alignment.topRight, children: [
            CustomScrollView(slivers: [
              SliverPersistentHeader(
                  floating: false,
                  pinned: true,
                  delegate: _GroupPostSubjectHeading(
                      child: Container(
                          color: Styles().colors.background,
                          padding: EdgeInsets.only(left: _outerPadding, top: _outerPadding, right: _outerPadding),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
                              Expanded(
                                  child: Padding(
                                      padding: EdgeInsets.only(right: 60),
                                      child: Text(AppString.getDefaultEmptyString(value: _post?.subject),
                                          maxLines: 5,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 24, color: Styles().colors.fillColorPrimary))))
                            ]),
                            Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(AppString.getDefaultEmptyString(value: _post?.member?.name),
                                    style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 20, color: Styles().colors.fillColorPrimary))),
                            Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Text(AppString.getDefaultEmptyString(value: _post?.displayDateTime),
                                    style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Styles().colors.fillColorPrimary))),
                          ])))),
              SliverList(
                  delegate: SliverChildListDelegate([
                Padding(
                    padding: EdgeInsets.only(left: _outerPadding, top: _outerPadding, right: _outerPadding),
                    child: Html(
                        data: _post?.body,
                        style: {"body": Style(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.regular, fontSize: FontSize(20))})),
                Padding(padding: EdgeInsets.only(left: _outerPadding, right: _outerPadding, bottom: _outerPadding), child: _buildRepliesWidget(replies: _post?.replies))
              ]))
            ]),
            Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
              Visibility(
                  visible: _isDeletePostVisible,
                  child: GestureDetector(
                      onTap: _onTapDeletePost,
                      child: Container(color: Colors.transparent, child: Padding(
                          padding: EdgeInsets.only(left: 16, top: 22, bottom: 10, right: (_isReplyVisible ? (_outerPadding / 2) : _outerPadding)),
                          child: Image.asset('images/trash.png', width: 20, height: 20))))),
              Visibility(
                  visible: _isReplyVisible,
                  child: GestureDetector(
                      onTap: _onTapReply,
                      child: Container(color: Colors.transparent, child: Padding(
                          padding: EdgeInsets.only(left: (_isDeletePostVisible ? 8 : 16), top: 22, bottom: 10, right: _outerPadding),
                          child: Image.asset('images/icon-group-post-reply.png', width: 20, height: 20, fit: BoxFit.fill)))))
            ])
          ]),
          Visibility(visible: _loading, child: Center(child: CircularProgressIndicator()))
        ]));
  }

  Widget _buildRepliesWidget({List<GroupPost> replies, double leftPaddingOffset = 0, bool nestedReply = false}) {
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
      replyWidgetList.add(Padding(padding: EdgeInsets.only(left: leftPaddingOffset), child: GroupReplyCard(reply: reply, group: widget.group, iconPath: optionsIconPath, onIconTap: optionsFunctionTap)));
      replyWidgetList.add(_buildRepliesWidget(replies: reply?.replies, leftPaddingOffset: (leftPaddingOffset + 5), nestedReply: true));
    }
    return Padding(
        padding: EdgeInsets.only(left: nestedReply ? 0 : 10, top: nestedReply ? 0 : 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: replyWidgetList));
  }

  List<GroupPost> _getVisibleReplies(List<GroupPost> replies) {
    if (AppCollection.isCollectionEmpty(replies)) {
      return null;
    }
    List<GroupPost> visibleReplies = [];
    bool currentUserIsMemberOrAdmin = widget.group?.currentUserIsMemberOrAdmin ?? false;
    for (GroupPost reply in replies) {
      bool replyVisible = (reply.private == false) || (reply.private == null) || currentUserIsMemberOrAdmin;
      if (replyVisible) {
        visibleReplies.add(reply);
      }
    }
    return visibleReplies;
  }

  void _onTapDeletePost() {
    AppAlert.showCustomDialog(
        context: context,
        contentWidget: Text(Localization().getStringEx('panel.group.detail.post.delete.confirm.msg', 'Are you sure that you want to delete this post?')),
        actions: <Widget>[
          TextButton(
              child: Text(Localization().getStringEx('dialog.yes.title', 'Yes')),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePost();
              }),
          TextButton(child: Text(Localization().getStringEx('dialog.no.title', 'No')), onPressed: () => Navigator.of(context).pop())
        ]);
  }

  void _deletePost() {
    _setLoading(true);
    Groups().deletePost(widget.group?.id, _post?.id).then((succeeded) {
      _setLoading(false);
      if (succeeded) {
        Navigator.of(context).pop();
      } else {
        AppAlert.showDialogResult(context, Localization().getStringEx('panel.group.detail.post.delete.failed.msg', 'Failed to delete post.'));
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
        builder: (context){
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 16,vertical: 17),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RibbonButton(
                  height: null,
                  leftIcon: "images/trash.png",
                  label:Localization().getStringEx("panel.group.detail.post.reply.delete.label", "Delete"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _onTapDeleteReply(reply);
                  },
                ),
                RibbonButton(
                  height: null,
                  leftIcon: "images/icon-group-post-reply.png",
                  label:Localization().getStringEx("panel.group.detail.post.reply.reply.label", "Reply"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _onTapReply(reply: reply);
                  },
                ),
              ],
            ),
          );
        }
    );
  }

  void _onTapDeleteReply(GroupPost reply) {
    AppAlert.showCustomDialog(
        context: context,
        contentWidget: Text(Localization().getStringEx('panel.group.detail.post.reply.delete.confirm.msg', 'Are you sure that you want to delete this reply?')),
        actions: <Widget>[
          TextButton(
              child: Text(Localization().getStringEx('dialog.yes.title', 'Yes')),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteReply(reply?.id);
              }),
          TextButton(child: Text(Localization().getStringEx('dialog.no.title', 'No')), onPressed: () => Navigator.of(context).pop())
        ]);
  }

  void _deleteReply(String replyId) {
    _setLoading(true);
    Groups().deletePost(widget.group?.id, replyId).then((succeeded) {
      _setLoading(false);
      if (!succeeded) {
        AppAlert.showDialogResult(context, Localization().getStringEx('panel.group.detail.post.reply.delete.failed.msg', 'Failed to delete reply.'));
      }
    });
  }

  void _onTapReply({GroupPost reply}) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupCreatePostPanel(post: ((reply != null) ? reply : _post), group: widget.group)));
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
      return AppString.isStringNotEmpty(currentMemberEmail) && AppString.isStringNotEmpty(replyMemberEmail) && (currentMemberEmail == replyMemberEmail);
    } else {
      return false;
    }
  }

  bool get _isDeletePostVisible {
    if (widget.group?.currentUserIsAdmin ?? false) {
      return true;
    } else {
      if (widget.group?.currentUserIsUserMember ?? false) {
        String currentMemberEmail = widget.group?.currentUserAsMember?.email;
        String postMemberEmail = _post?.member?.email;
        return AppString.isStringNotEmpty(currentMemberEmail) && AppString.isStringNotEmpty(postMemberEmail) && (currentMemberEmail == postMemberEmail);
      } else {
        return false;
      }
    }
  }

  bool get _isReplyVisible {
    return widget.group?.currentUserIsMemberOrAdmin ?? false;
  }


  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if(name == Groups.notifyGroupPostsUpdated) {
      _reloadPost();
    }
  }
}

class _GroupPostSubjectHeading extends SliverPersistentHeaderDelegate {

  final Widget child;
  final double constExtent = 100;

  _GroupPostSubjectHeading({@required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(height: constExtent, child: child,);
  }

  @override
  double get maxExtent => constExtent;

  @override
  double get minExtent => constExtent;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
