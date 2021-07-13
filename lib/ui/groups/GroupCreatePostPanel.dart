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
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';

class GroupCreatePostPanel extends StatefulWidget{
  
  final Group group;
  final GroupPost post;

  GroupCreatePostPanel({@required this.group, this.post});

  @override
  State<StatefulWidget> createState() => _GroupCreatePostPanelState();
}

class _GroupCreatePostPanelState extends State<GroupCreatePostPanel>{

  TextEditingController _subjectController = TextEditingController();
  TextEditingController _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: HeaderBackButton(),
          title: Text(Localization().getStringEx('panel.group.post.create.header.title', 'New Post'),
              style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: Styles().fontFamilies.extraBold, letterSpacing: 1)),
          centerTitle: true),
      body: SingleChildScrollView(child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(Localization().getStringEx('panel.group.post.create.subject.label', 'Subject'),
                style: TextStyle(fontSize: 18, fontFamily: Styles().fontFamilies.bold, color: Styles().colors.fillColorPrimary)),
            Padding(
                padding: EdgeInsets.only(top: 8),
                child: TextField(
                  controller: _subjectController,
                  maxLines: 1,
                  decoration: InputDecoration(
                      hintText: Localization().getStringEx("panel.group.post.create.subject.field.hint", "Write a Subject"), border: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors.mediumGray, width: 0.0))),
                  style: TextStyle(color: Styles().colors.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies.regular),
                )),
            Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(Localization().getStringEx('panel.group.post.create.body.label', 'Body'),
                    style: TextStyle(fontSize: 18, fontFamily: Styles().fontFamilies.bold, color: Styles().colors.fillColorPrimary))),
            Padding(
                padding: EdgeInsets.only(top: 8),
                child: TextField(
                  controller: _bodyController,
                  maxLines: 15,
                  decoration: InputDecoration(
                      hintText: Localization().getStringEx("panel.group.post.create.body.field.hint", "Write a Body"), border: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors.mediumGray, width: 0.0))),
                  style: TextStyle(color: Styles().colors.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies.regular),
                )),
            //TBD: position, implement on send
            Row(children: [
              Flexible(flex: 1, child: RoundedButton(label: Localization().getStringEx('panel.group.post.create.button.send.title', 'Send'), borderColor: Styles().colors.fillColorSecondary, textColor: Styles().colors.fillColorPrimary, backgroundColor: Styles().colors.white)),
              Container(width: 20),
              Flexible(flex: 1, child: RoundedButton(label: Localization().getStringEx('panel.group.post.create.button.cancel.title', 'Cancel'), borderColor: Styles().colors.textSurface, textColor: Styles().colors.fillColorPrimary, backgroundColor: Styles().colors.white, onTap: _onTapCancel))
            ])
          ]))),
      backgroundColor: Styles().colors.background,
    );
  }

  void _onTapCancel() {
    Navigator.of(context).pop();
  }
}