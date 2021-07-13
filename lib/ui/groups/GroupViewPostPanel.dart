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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading: HeaderBackButton(),
            title: Text(
              Localization().getStringEx('panel.group.post.header.title', 'Post'),
              style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: Styles().fontFamilies.extraBold, letterSpacing: 1),
            ),
            centerTitle: true),
        backgroundColor: Styles().colors.background,
        bottomNavigationBar: TabBarWidget(),
        body: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppString.getDefaultEmptyString(value: widget.post?.subject), style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 24, color: Styles().colors.fillColorPrimary)),
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
        ]))));
  }

  Widget _buildRepliesWidget() {
    List<GroupPostReply> replies = _getVisibleReplies();
    if (AppCollection.isCollectionEmpty(replies)) {
      return Container();
    }
    List<Widget> replyWidgetList = [];
    for (int i = 0; i < replies.length; i++) {
      if (i > 0) {
        replyWidgetList.add(Container(height: 10));
      }
      replyWidgetList.add(GroupReplyCard(reply: replies[i], group: widget.group));
    }
    return Padding(padding: EdgeInsets.only(left: 25, top: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: replyWidgetList));
  }

  List<GroupPostReply> _getVisibleReplies() {
    List<GroupPostReply> replies = widget.post?.replies;
    if (AppCollection.isCollectionEmpty(replies)) {
      return null;
    }
    List<GroupPostReply> visibleReplies = [];
    bool currentUserIsMemberOrAdmin = widget.group?.currentUserIsMemberOrAdmin ?? false;
    for (GroupPostReply reply in replies) {
      bool replyVisible = (reply.private == false) || (reply.private == null) || currentUserIsMemberOrAdmin;
      if (replyVisible) {
        visibleReplies.add(reply);
      }
    }
    return visibleReplies;
  }
}
