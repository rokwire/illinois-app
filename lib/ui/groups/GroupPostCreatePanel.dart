import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'GroupWidgets.dart';

class GroupPostCreatePanel extends StatefulWidget{
  final Group? group;

  const GroupPostCreatePanel({Key? key, this.group}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupPostCreatePanelState();
}

class _GroupPostCreatePanelState extends State<GroupPostCreatePanel>{
  static final double _outerPadding = 16;

  PostDataModel _postData = PostDataModel();
  List<GroupPostTemplate>? _postTemplates;
  GroupPostTemplate? _selectedTemplate;
  bool _loading = false;
  //Refresh
  GlobalKey _postImageHolderKey = GlobalKey();
  List<Member>? _selectedMembers;
  List<Member>? _allMembersAllowedToPost;

  @override
  void initState() {
    super.initState();
    _initAllMembersAllowedToPost();
    _loadPostTemplates();
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
          centerTitle: true),
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
                  GroupMembersSelectionWidget(allMembers: _allMembersAllowedToPost, selectedMembers: _selectedMembers, groupId: widget.group?.id, onSelectionChanged: _onMembersSelectionChanged),
                  _buildTemplatesWidget(),
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
              visible: _loading,
              child: Center(child: CircularProgressIndicator())),
        ])
    );
  }

  Widget _buildTemplatesWidget() {
    // Do not show the templates for regular members
    if (!(widget.group?.currentUserIsAdmin ?? false)) {
      return Container();
    }
    if (CollectionUtils.isEmpty(_postTemplates)) {
      return Container();
    }
    return Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Localization().getStringEx('panel.group.detail.post.create.templates.label', 'Templates'),
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
                          child: DropdownButton<GroupPostTemplate?>(
                              icon: Icon(Icons.arrow_drop_down, color: Styles().colors!.fillColorSecondary),
                              isExpanded: true,
                              style: TextStyle(
                                  fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textBackground),
                              items: _templatesDropDownItems,
                              value: _selectedTemplate,
                              onChanged: _onTemplateChanged)))))
        ]));
  }

  void _onMembersSelectionChanged(List<Member>? selectedMembers){
    if(mounted) {
      setState(() {
        _selectedMembers = selectedMembers;
      });
    }
  }

  List<DropdownMenuItem<GroupPostTemplate?>> get _templatesDropDownItems {
    List<DropdownMenuItem<GroupPostTemplate?>> items = [];
    if (CollectionUtils.isNotEmpty(_postTemplates)) {
      for (GroupPostTemplate template in _postTemplates!) {
        items.add(DropdownMenuItem(value: template, child: Text(StringUtils.ensureNotEmpty(template.subject))));
      }
    }
    items.add(DropdownMenuItem(
        value: null, child: Text(Localization().getStringEx('panel.group.detail.post.create.templates.custom.label', 'Custom'))));
    return items;
  }

  void _onTemplateChanged(GroupPostTemplate? template) {
    _selectedTemplate = template;
    String? subject;
    String? body;
    if (_selectedTemplate != null) {
      subject = _selectedTemplate?.subject;
      body = _selectedTemplate?.body;
    }
    _postData.subject = subject;
    _postData.body = body;
    if (mounted) {
      setState(() {});
    }
  }

  //Tap actions
  void _onTapCancel() {
    Analytics().logSelect(target: 'Cancel');
    Navigator.of(context).pop();
  }

  void _onTapSend() {
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
    _setLoading(true);

    GroupPost post = GroupPost(subject: subject, body: htmlModifiedBody, private: true, imageUrl: imageUrl, members: _selectedMembers); // if no parentId then this is a new post for the group.
    Groups().createPost(widget.group?.id, post).then((succeeded) {
      _onCreateFinished(succeeded);
    });
  }

  void _onCreateFinished(bool succeeded) {
    _setLoading(false);
    if (succeeded) {
      Navigator.of(context).pop(true);
    } else {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.group.detail.post.create.post.failed.msg', 'Failed to create new post.'));
    }
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _loading = loading;
      });
    }
  }

  void _initAllMembersAllowedToPost(){
    if((widget.group?.members?.length ?? 0) >0) {
      _allMembersAllowedToPost = widget.group!.members!.where((member) => _isMemberAllowedToReceivePost(member)).toList();
    }
  }

  void _loadPostTemplates() {
    // Load post templates only for admins
    if (widget.group?.currentUserIsAdmin ?? false) {
      _setLoading(true);
      Groups().loadPostTemplates(groupName: StringUtils.ensureNotEmpty(widget.group?.title)).then((templates) {
        _postTemplates = templates;
        _setLoading(false);
      });
    }
  }

  bool _isMemberAllowedToReceivePost(Member member){
    //TMP:
    // return true;
    return member.isMemberOrAdmin;
  }
}