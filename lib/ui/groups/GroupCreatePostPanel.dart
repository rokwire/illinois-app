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
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/utils/Utils.dart';

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
  TextEditingController _linkController = TextEditingController();
  bool _private = true;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _linkController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String headerTitle = _isNewPost
        ? Localization().getStringEx('panel.group.post.create.header.post.title', 'New Post')
        : Localization().getStringEx('panel.group.post.create.header.reply.title', 'New Reply');

    return Scaffold(
      appBar: AppBar(
          leading: HeaderBackButton(),
          title: Text(headerTitle, style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: Styles().fontFamilies.extraBold, letterSpacing: 1)),
          centerTitle: true),
      body: Padding(
          padding: EdgeInsets.all(16),
          child: Stack(alignment: Alignment.center, children: [
            Stack(children: [
              SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Visibility(
                    visible: _privateSwitchVisible,
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(Localization().getStringEx('panel.group.post.create.private.label', 'Private'),
                          style: TextStyle(fontSize: 18, fontFamily: Styles().fontFamilies.bold, color: Styles().colors.fillColorPrimary)),
                      GestureDetector(onTap: _onTapPrivate, child: Image.asset(_private ? 'images/switch-on.png' : 'images/switch-off.png'))
                    ])),
                Padding(
                    padding: EdgeInsets.only(top: _privateSwitchVisible ? 16 : 0),
                    child: Text(Localization().getStringEx('panel.group.post.create.subject.label', 'Subject'),
                        style: TextStyle(fontSize: 18, fontFamily: Styles().fontFamilies.bold, color: Styles().colors.fillColorPrimary))),
                Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: TextField(
                        controller: _subjectController,
                        maxLines: 1,
                        decoration: InputDecoration(
                            hintText: Localization().getStringEx('panel.group.post.create.subject.field.hint', 'Write a Subject'),
                            border: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors.mediumGray, width: 0.0))),
                        style: TextStyle(color: Styles().colors.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies.regular))),
                Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Text(Localization().getStringEx('panel.group.post.create.body.label', 'Body'),
                          style: TextStyle(fontSize: 18, fontFamily: Styles().fontFamilies.bold, color: Styles().colors.fillColorPrimary)),
                      Padding(padding: EdgeInsets.only(left: 30), child: GestureDetector(onTap: _onTapBold, child: Text('B', style: TextStyle(fontSize: 24, color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold)))),
                      Padding(padding: EdgeInsets.only(left: 20), child: GestureDetector(onTap: _onTapItalic, child: Text('I', style: TextStyle(fontSize: 24, color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.mediumIt)))),
                      Padding(padding: EdgeInsets.only(left: 20), child: GestureDetector(onTap: _onTapUnderline, child: Text('U', style: TextStyle(fontSize: 24, color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.medium, decoration: TextDecoration.underline, decorationThickness: 2, decorationColor: Styles().colors.fillColorPrimary)))),
                      Padding(padding: EdgeInsets.only(left: 20), child: GestureDetector(onTap: _onTapLink, child: Text(Localization().getStringEx('panel.group.post.create.link.label', 'Link'), style: TextStyle(fontSize: 18, color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.medium)))),
                    ])),
                Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: TextField(
                        toolbarOptions: ToolbarOptions(copy: false, cut: false, selectAll: false),
                        controller: _bodyController,
                        maxLines: 15,
                        decoration: InputDecoration(
                            hintText: Localization().getStringEx("panel.group.post.create.body.field.hint", "Write a Body"),
                            border: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors.mediumGray, width: 0.0))),
                        style: TextStyle(color: Styles().colors.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies.regular)))
              ])),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Flexible(
                    flex: 1,
                    child: RoundedButton(
                        label: Localization().getStringEx('panel.group.post.create.button.send.title', 'Send'),
                        borderColor: Styles().colors.fillColorSecondary,
                        textColor: Styles().colors.fillColorPrimary,
                        backgroundColor: Styles().colors.white,
                        onTap: _onTapSend)),
                Container(width: 20),
                Flexible(
                    flex: 1,
                    child: RoundedButton(
                        label: Localization().getStringEx('panel.group.post.create.button.cancel.title', 'Cancel'),
                        borderColor: Styles().colors.textSurface,
                        textColor: Styles().colors.fillColorPrimary,
                        backgroundColor: Styles().colors.white,
                        onTap: _onTapCancel))
              ])
            ]),
            Visibility(visible: _loading, child: CircularProgressIndicator())
          ])),
      backgroundColor: Styles().colors.background,
    );
  }

  void _onTapCancel() {
    Navigator.of(context).pop();
  }

  void _onTapSend() {
    FocusScope.of(context).unfocus();
    String subject = _subjectController.text;
    if (AppString.isStringEmpty(subject)) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.group.post.create.validation.subject.msg', "Please, populate 'Subject' field"));
      return;
    }
    String body = _bodyController.text;
    if (AppString.isStringEmpty(body)) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.group.post.create.validation.body.msg', "Please, populate 'Body' field"));
      return;
    }
    _setLoading(true);
    if (_isNewPost) {
      GroupPost post = GroupPost(subject: subject, body: body, private: _private);
      Groups().createPost(widget.group?.id, post).then((succeeded) {
        _onCreateFinished(succeeded);
      });
    } else {
      GroupPostReply reply = GroupPostReply(parentId: widget.post?.id, subject: subject, body: body, private: _private);
      _setLoading(true);
      Groups().createPostReply(widget.group?.id, reply).then((succeeded) {
        _onCreateFinished(succeeded);
      });
    }
  }

  void _onCreateFinished(bool succeeded) {
    _setLoading(false);
    if (succeeded) {
      Navigator.of(context).pop();
    } else {
      AppAlert.showDialogResult(
          context,
          _isNewPost
              ? Localization().getStringEx('panel.group.post.create.post.failed.msg', 'Failed to create new post.')
              : Localization().getStringEx('panel.group.post.create.reply.failed.msg', 'Failed to create new reply.'));
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
    AppAlert.showCustomDialog(context: context, contentWidget: _buildLinkDialog(), actions: [
      TextButton(onPressed: () => _onTapOkLink(linkStartPosition, linkEndPosition), child: Text(Localization().getStringEx('dialog.ok.title', 'OK'))),
      TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(Localization().getStringEx('dialog.cancel.title', 'Cancel')))
    ]);
  }

  Widget _buildLinkDialog() {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(Localization().getStringEx('panel.group.post.create.dialog.link.edit.header', 'Edit Link'),
          style: TextStyle(fontSize: 20, color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.medium)),
      Padding(padding: EdgeInsets.only(top: 16), child: Text(Localization().getStringEx('panel.group.post.create.dialog.link.label', 'Link to:'),
          style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies.regular, color: Styles().colors.fillColorPrimary))),
      Padding(padding: EdgeInsets.only(top: 6), child: TextField(
          controller: _linkController,
          maxLines: 1,
          decoration: InputDecoration(
              border: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors.mediumGray, width: 0.0))),
          style: TextStyle(color: Styles().colors.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies.regular)))
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

  void _wrapBody(String firstValue, String secondValue, int startPosition, int endPosition) {
    String currentText = _bodyController.text;
    String result = AppString.wrapRange(currentText, firstValue, secondValue, startPosition, endPosition);
    _bodyController.text = result;
    _bodyController.selection = TextSelection.fromPosition(TextPosition(offset: (endPosition + firstValue.length)));
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _loading = loading;
      });
    }
  }

  bool get _isNewPost {
    return (widget.post == null);
  }

  bool get _privateSwitchVisible {
    return (widget.group?.privacy == GroupPrivacy.public);
  }
}