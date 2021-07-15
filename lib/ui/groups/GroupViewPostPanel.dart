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

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/utils/Utils.dart';

class GroupViewPostPanel extends StatefulWidget {
  final GroupPost post;
  final Group group;

  GroupViewPostPanel({@required this.post, @required this.group});

  @override
  _GroupViewPostPanelState createState() => _GroupViewPostPanelState();
}

class _GroupViewPostPanelState extends State<GroupViewPostPanel> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading: HeaderBackButton(),
            title: Text(
              Localization().getStringEx('panel.group.view.post.header.title', 'Post'),
              style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: Styles().fontFamilies.extraBold, letterSpacing: 1),
            ),
            centerTitle: true),
        backgroundColor: Styles().colors.background,
        bottomNavigationBar: TabBarWidget(),
        body: Stack(children: [SingleChildScrollView(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text(AppString.getDefaultEmptyString(value: widget.post?.subject), style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 24, color: Styles().colors.fillColorPrimary)),
            Visibility(visible: _isDeletePostVisible, child: GestureDetector(onTap: _onTapDeletePost, child: Padding(padding: EdgeInsets.only(left: 10, top: 3, bottom: 3), child: Image.asset('images/trash.png'))))
          ]),
          Padding(padding: EdgeInsets.only(top: 4), child: Text(AppString.getDefaultEmptyString(value: widget.post?.member?.name),
              style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 20, color: Styles().colors.fillColorPrimary))),
          Padding(
              padding: EdgeInsets.only(top: 16),
              child: Html(data: widget.post?.body, style: {
                "body": Style(
                    color: Styles().colors.fillColorPrimary,
                    fontFamily: Styles().fontFamilies.regular,
                    fontSize: FontSize(20))
              })),
          _buildRepliesWidget()
        ]))),
        Visibility(visible: _loading, child: Center(child: CircularProgressIndicator()))]));
  }

  Widget _buildRepliesWidget() {
    List<GroupPost> replies = _getVisibleReplies();
    if (AppCollection.isCollectionEmpty(replies)) {
      return Container();
    }
    List<Widget> replyWidgetList = [];
    for (int i = 0; i < replies.length; i++) {
      if (i > 0) {
        replyWidgetList.add(Container(height: 10));
      }
      GroupPost reply = replies[i];
      String deleteIconPath;
      Function deleteFunctionTap;
      if (_isDeleteReplyVisible(reply)) {
        deleteIconPath = 'images/trash.png';
        deleteFunctionTap = () => _onTapDeleteReply(reply);
      }
      replyWidgetList.add(GroupReplyCard(reply: reply, group: widget.group, iconPath: deleteIconPath, onIconTap: deleteFunctionTap));
    }
    return Padding(padding: EdgeInsets.only(left: 25, top: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: replyWidgetList));
  }

  List<GroupPost> _getVisibleReplies() {
    List<GroupPost> replies = widget.post?.replies;
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
        contentWidget: Text(Localization().getStringEx('panel.group.view.post.delete.confirm.msg', 'Are you sure that you want to delete this post?')),
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
    Groups().deletePost(widget.group?.id, widget.post?.id).then((succeeded) {
      _setLoading(false);
      if (succeeded) {
        Navigator.of(context).pop();
      } else {
        AppAlert.showDialogResult(context, Localization().getStringEx('panel.group.view.post.delete.failed.msg', 'Failed to delete post.'));
      }
    });
  }

  void _onTapDeleteReply(GroupPost reply) {
    AppAlert.showCustomDialog(
        context: context,
        contentWidget: Text(Localization().getStringEx('panel.group.view.post.reply.delete.confirm.msg', 'Are you sure that you want to delete this reply?')),
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
      if (succeeded) {
        Navigator.of(context).pop();
      } else {
        AppAlert.showDialogResult(context, Localization().getStringEx('panel.group.view.post.reply.delete.failed.msg', 'Failed to delete reply.'));
      }
    });
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _loading = loading;
      });
    }
  }

  bool _isDeleteReplyVisible(GroupPost reply) {
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
        String postMemberEmail = widget.post?.member?.email;
        return AppString.isStringNotEmpty(currentMemberEmail) && AppString.isStringNotEmpty(postMemberEmail) && (currentMemberEmail == postMemberEmail);
      } else {
        return false;
      }
    }
  }
}
