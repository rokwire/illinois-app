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
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/groups/GroupTagsPanel.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/groups/GroupMembershipQuestionsPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:sprintf/sprintf.dart';

class GroupSettingsPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Group? group;
  
  GroupSettingsPanel({this.group});

  @override
  _GroupSettingsPanelState createState() => _GroupSettingsPanelState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes => group?.analyticsAttributes;
}

class _GroupSettingsPanelState extends State<GroupSettingsPanel> {
  final _eventTitleController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  final _linkController = TextEditingController();
  final _authManGroupNameController = TextEditingController();

  List<GroupPrivacy>? _groupPrivacyOptions;
  List<String>? _groupCategories;

  bool _nameIsValid = true;
  bool _loading = false;

  Group? _group; // edit settings here until submit

  @override
  void initState() {
    _group = Group.fromOther(widget.group);
    _initPrivacyData();
    _initCategories();
    _fillGroups();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                color: Colors.white,
                child: CustomScrollView(
                  scrollDirection: Axis.vertical,
                  slivers: <Widget>[
                    SliverHeaderBar(
                      title: Localization().getStringEx("panel.groups_settings.label.heading", "Group Settings"),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        Container(
                          color: Styles().colors!.white,
                          child: Column(children: <Widget>[
                            _buildImageSection(),
                            Container(padding: EdgeInsets.symmetric(horizontal: 16), child:
                              _buildSectionTitle(Localization().getStringEx("panel.groups_settings.label.heading.general_info", "General group information"), "images/icon-schedule.png"),
                            ),
                            _buildNameField(),
                            _buildDescriptionField(),
                            _buildLinkField(),
                            Container(height: 1, color: Styles().colors!.surfaceAccent,),
                            Container(padding: EdgeInsets.symmetric(horizontal: 16), child:
                              _buildSectionTitle(Localization().getStringEx("panel.groups_settings.label.heading.discoverability", "Discoverability"), "images/icon-schedule.png"),
                            ),
                            _buildCategoryDropDown(),
                            _buildTagsLayout(),
                            Container(color: Styles().colors!.background, child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _buildSectionTitle(Localization().getStringEx("panel.groups_settings.privacy.title", "Privacy"), "images/icon-privacy.png"),
                              //_buildInfoHeader(Localization().getStringEx("panel.groups_settings.privacy.title.description", "SELECT PRIVACY"), null)
                            ]))),
                            Container(height: 12, color: Styles().colors!.background),
                            _buildPrivacyDropDown(),
                            _buildHiddenForSearch(),
                            _buildAuthManLayout(),
                            Visibility(
                              visible: !_isAuthManGroup,
                              child: _buildMembershipLayout()),
                            Container(height: 8, color: Styles().colors!.background),
                            _buildPollsLayout(),
                            Container(height: 16, color: Styles().colors!.background),
                            _buildAttendanceLayout(),
                            Container(height: 16, color: Styles().colors!.background),
                            _buildCanAutoJoinLayout(),
                            Container(height: 24,  color: Styles().colors!.background,),
                          ],),)
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            _buildButtonsLayout(),
          ],
        ),
        backgroundColor: Styles().colors!.background);
  }

  //Init
  void _initPrivacyData(){
    _groupPrivacyOptions = GroupPrivacy.values;
  }

  void _initCategories(){
    Groups().loadCategories().then((categories){
     setState(() {
       _groupCategories = categories;
     });
    });
  }

  void _fillGroups(){
    if(_group!=null){
      //textFields
      if(_group!.title!=null)
        _eventTitleController.text=_group!.title!;
      if(_group!.description!=null)
        _eventDescriptionController.text=_group!.description!;
      if(_group!.webURL!=null)
        _linkController.text = _group!.webURL!;
      if (_group!.authManGroupName != null) {
        _authManGroupNameController.text = _group!.authManGroupName!;
      }
    }
  }

  //
  //Image
  Widget _buildImageSection(){
    final double _imageHeight = 200;

    return Container(
      height: _imageHeight,
      color: Styles().colors!.background,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          StringUtils.isNotEmpty(_group?.imageURL) ?  Positioned.fill(child:Image.network(_group!.imageURL!, excludeFromSemantics: true, fit: BoxFit.cover, headers: Config().networkAuthHeaders)) : Container(),
          CustomPaint(
            painter: TrianglePainter(painterColor: Styles().colors!.fillColorSecondaryTransparent05, horzDir: TriangleHorzDirection.leftToRight),
            child: Container(
              height: 53,
            ),
          ),
          CustomPaint(
            painter: TrianglePainter(painterColor: Styles().colors!.white),
            child: Container(
              height: 30,
            ),
          ),
          Container(
            height: _imageHeight,
            child: Center(
              child:
              Semantics(label: StringUtils.isNotEmpty(_group?.imageURL) ? Localization().getStringEx("panel.groups_settings.modify_image","Modify cover image") : Localization().getStringEx("panel.groups_settings.add_image","Add Cover Image"),
                  hint: StringUtils.isNotEmpty(_group?.imageURL) ? Localization().getStringEx("panel.groups_settings.modify_image.hint","") : Localization().getStringEx("panel.groups_settings.add_image.hint",""),
                  button: true, excludeSemantics: true, child:
                  RoundedButton(
                    label: StringUtils.isNotEmpty(_group?.imageURL) ? Localization().getStringEx("panel.groups_settings.modify_image","Modify cover image") : Localization().getStringEx("panel.groups_settings.add_image","Add Cover Image"),
                    textColor: Styles().colors!.fillColorPrimary,
                    contentWeight: 0.8,
                    onTap: _onTapAddImage,)
              ),
            ),
          )
        ],
      ),
    );
  }

  void _onTapAddImage() async {
    Analytics().logSelect(target: "Add Image");
    String? _imageUrl = await showDialog(
        context: context,
        builder: (_) => Material(
          type: MaterialType.transparency,
          child: GroupAddImageWidget(),
        )
    );
    if(_imageUrl!=null){
      setState(() {
        _group!.imageURL = _imageUrl;
      });
    }
    Log.d("Image Url: $_imageUrl");
  }
  //
  //Name
  Widget _buildNameField() {
    String title = Localization().getStringEx("panel.groups_settings.name.title", "GROUP NAME");
    String? fieldTitle = Localization().getStringEx("panel.groups_settings.name.field", "NAME FIELD");
    String? fieldHint = Localization().getStringEx("panel.groups_settings.name.field.hint", "");

    return
      Column(children: <Widget>[
        Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildInfoHeader(title,null),
            Container(
              decoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1),color: Styles().colors!.white),
              child: Semantics(
                  label: fieldTitle,
                  hint: fieldHint,
                  textField: true,
                  excludeSemantics: true,
                  child: TextField(
                    controller: _eventTitleController,
                    onChanged: onNameChanged,
                    maxLines: 1,
                    decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                    style: TextStyle(color: Styles().colors!.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
                  )),
            ),
          ],
        ),

        ),
        _buildNameError()
    ],);
  }

  Widget _buildNameError(){
    String errorMessage = Localization().getStringEx("panel.groups_settings.name.error.message", "A group with this name already exists. Please try a different name.");

    return Visibility(visible: !_nameIsValid,
        child: Container( padding: EdgeInsets.only(left:16, right:16,top: 6),
            child:Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                  color: Styles().colors!.fillColorSecondaryVariant,
                  border: Border.all(
                      color: Styles().colors!.fillColorSecondary!,
                      width: 1),
                  borderRadius:
                  BorderRadius.all(Radius.circular(4))),
              child: Row(
                children: <Widget>[
                  Image.asset('images/warning-orange.png'),
                  Expanded(child:
                  Container(
                      padding: EdgeInsets.only(left: 12, right: 4),
                      child:Text(errorMessage,
                          style: TextStyle(color: Styles().colors!.textBackground, fontSize: 14, fontFamily: Styles().fontFamilies!.regular))
                  ))
                ],
              ),
            )
        ));
  }

  //Description
  Widget _buildDescriptionField() {
    String title = Localization().getStringEx("panel.groups_settings.description.title", "GROUP DESCRIPTION");
    String? fieldTitle = Localization().getStringEx("panel.groups_settings.description.field", "What’s the purpose of your group? Who should join? What will you do at your events?");
    String? fieldHint = Localization().getStringEx("panel.groups_settings.description.field.hint", "");

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildInfoHeader(title,fieldTitle),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1),color: Styles().colors!.white),
            child: Semantics(
                label: title,
                hint: fieldHint,
                textField: true,
                excludeSemantics: true,
                child: TextField(
                  controller: _eventDescriptionController,
                  onChanged: (description){ _group!.description = description;},
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: fieldHint,
                    border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
                  style: TextStyle(color: Styles().colors!.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
                )),
          ),
        ],
      ),
    );
  }
  //
  //Link
  Widget _buildLinkField(){
    return
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
          Semantics(label:Localization().getStringEx("panel.groups_settings.link.title", "WEBSITE LINK"),
            hint: Localization().getStringEx("panel.groups_settings.link.title.hint",""), textField: true, excludeSemantics: true, child:
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: 8, top:24),
                    child: Text(
                      Localization().getStringEx("panel.groups_settings.link.title", "WEBSITE LINK"),
                      style: TextStyle(
                          color: Styles().colors!.fillColorPrimary,
                          fontSize: 14,
                          fontFamily: Styles().fontFamilies!.bold,
                          letterSpacing: 1),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 15),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                              color: Styles().colors!.fillColorPrimary!,
                              width: 1)),
                      child: TextField(
                        controller: _linkController,
                        decoration: InputDecoration(
                            hintText:  Localization().getStringEx("panel.groups_settings.link.hint", "Add URL"),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                        style: TextStyle(
                            color: Styles().colors!.textBackground,
                            fontSize: 16,
                            fontFamily: Styles().fontFamilies!.regular),
                        onChanged: (link){ _group!.webURL = link;},
                        maxLines: 1,
                      ),
                    ),
                  ),
                ]
            )
        ),
        Semantics(label:Localization().getStringEx("panel.groups_settings.link.button.confirm.link",'Confirm website URL'),
            hint: Localization().getStringEx("panel.groups_settings.link.button.confirm.link.hint",""), button: true, excludeSemantics: true, child:
            GestureDetector(
              onTap: _onTapConfirmLinkUrl,
              child: Text(
                Localization().getStringEx("panel.groups_settings.link.button.confirm.link.title",'Confirm URL'),
                style: TextStyle(
                    color: Styles().colors!.fillColorPrimary,
                    fontSize: 16,
                    fontFamily: Styles().fontFamilies!.medium,
                    decoration: TextDecoration.underline,
                    decorationThickness: 1,
                    decorationColor:
                    Styles().colors!.fillColorSecondary),
              ),
            )
        ),
        Container(height: 15)
    ],));
  }

  void _onTapConfirmLinkUrl() {
    Analytics().logSelect(target: "Confirm Website url");
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => WebPanel(url: _linkController.text)));
  }
  //
  //Category
  Widget _buildCategoryDropDown() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildInfoHeader(Localization().getStringEx("panel.groups_settings.category.title", "CATEGORY"),
              Localization().getStringEx("panel.groups_settings.category.description", "Choose the category your group can be filtered by."),),
            Semantics(
            explicitChildNodes: true,
            child: GroupDropDownButton(
                emptySelectionText: Localization().getStringEx("panel.groups_settings.category.default_text", "Select a category.."),
                buttonHint: Localization().getStringEx("panel.groups_settings.category.hint", "Double tap to show categories options"),
                initialSelectedValue: _group?.category,
                items: _groupCategories,
                constructTitle: (dynamic item) => item,
                onValueChanged: (value) {
                  setState(() {
                    _group?.category = value;
                    Log.d("Selected Category: $value");
                  });
                }
            ))
          ],
        ));
  }

  //Tags
  Widget _buildTagsLayout(){
    String title = Localization().getStringEx("panel.groups_create.tags.title", "TAGS");
    String? description = Localization().getStringEx("panel.groups_create.tags.description", "Tags help people understand more about your group.");
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Expanded(flex: 5, child: _buildInfoHeader(title, description)),
                Container(width: 8),
                Expanded(
                    flex: 2,
                    child:
                    RoundedButton(
                      label: Localization().getStringEx("panel.groups_settings.button.tags.title", "Tags"),
                      hint: Localization().getStringEx("panel.groups_settings.button.tags.hint", ""),
                      backgroundColor: Styles().colors!.white,
                      textColor: Styles().colors!.fillColorPrimary,
                      borderColor: Styles().colors!.fillColorSecondary,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      onTap: _onTapTags,
                    )
                )
              ],
            ),
            Container(height: 10,),
            _constructTagButtonsContent()
          ],
        ));
  }

  Widget _constructTagButtonsContent(){
    List<Widget> buttons = _buildTagsButtons();
    if(buttons.isEmpty)
      return Container();

    List<Widget> rows = [];
    List<Widget>? lastRowChildren;
    for(int i=0; i<buttons.length;i++){
      if(i%2==0){
        lastRowChildren =  [];
        rows.add(SingleChildScrollView(scrollDirection: Axis.horizontal, child:Row(children:lastRowChildren,)));
        rows.add(Container(height: 8,));
      } else {
        lastRowChildren?.add(Container(width: 13,));
      }
      lastRowChildren!.add(buttons[i]);
    }
    rows.add(Container(height: 24,));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  List<Widget> _buildTagsButtons(){
    List<String>? tags = _group?.tags;
    List<Widget> result =  [];
    if (CollectionUtils.isNotEmpty(tags)) {
      tags!.forEach((String tag) {
        result.add(_buildTagButton(tag));
      });
    }
    return result;
  }

  Widget _buildTagButton(String tag){
    return
      Semantics(
        label: tag + Localization().getStringEx("panel.groups_create.tags.label.tag", " tag, "),
        hint: Localization().getStringEx("panel.groups_create.tags.label.tag.hint", "double tab to remove tag"),
        button: true,
        excludeSemantics: true,
        child:InkWell(
          child: Container(
              decoration: BoxDecoration(
                  color: Styles().colors!.fillColorPrimary,
                  borderRadius: BorderRadius.all(Radius.circular(4))),
              child: Row(children: <Widget>[
                Semantics(excludeSemantics: true, child:
                  Container(
                      padding: EdgeInsets.only(top:4,bottom: 4,left: 8),
                      child: Text(tag,
                        style: TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.bold, fontSize: 12,),
                      )),
                  ),
                Container (
                  padding: EdgeInsets.only(top:8,bottom: 8,right: 8, left: 8),
                  child: Image.asset("images/small-add-orange.png", excludeFromSemantics: true,),
                )

              ],)
          ),
          onTap: () => onTagTap(tag)
      ));
  }

  void onTagTap(String tag){
    Analytics().logSelect(target: "Group tag: $tag");
    if(_group!=null) {
      if (_group!.tags == null) {
        _group!.tags =  [];
      }

      if (_group!.tags!.contains(tag)) {
        _group!.tags!.remove(tag);
      } else {
        _group!.tags!.add(tag);
      }
    }
    setState(() {});
  }

  void _onTapTags(){
    Analytics().logSelect(target: "Tags");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupTagsPanel(selectedTags: _group!.tags))).then((tags) {
      // (tags == null) means that the user hit the back button
      if (tags != null) {
        setState(() {
          _group!.tags = tags;
        });
      }
    });
  }
  //
  //Privacy
  Widget _buildPrivacyDropDown() {

    String? longDescription;
    switch(_group?.privacy) {
      case GroupPrivacy.private: longDescription = Localization().getStringEx("panel.groups.common.privacy.description.long.private", "Anyone who uses the app can find this group if they search and match the full name. Only admins can see who is in the group."); break;
      case GroupPrivacy.public: longDescription = Localization().getStringEx("panel.groups.common.privacy.description.long.public", "Anyone who uses the app will see this group. Only admins can see who is in the group."); break;
      default: break;
    }

    return Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        color: Styles().colors!.background,
        child:Column(children: <Widget>[
          Semantics(
          explicitChildNodes: true,
          child: Container(
              child:  GroupDropDownButton(
                  emptySelectionText: Localization().getStringEx("panel.groups_settings.privacy.hint.default","Select privacy setting.."),
                  buttonHint: Localization().getStringEx("panel.groups_settings.privacy.hint", "Double tap to show privacy oprions"),
                  items: _groupPrivacyOptions,
                  initialSelectedValue: _group?.privacy ?? (_groupPrivacyOptions!=null?_groupPrivacyOptions![0] : null),
                  constructTitle:
                      (dynamic item) => item == GroupPrivacy.private?
                        Localization().getStringEx("panel.groups.common.privacy.title.private", "Private") :
                        Localization().getStringEx("panel.groups.common.privacy.title.public",  "Public"),
                  constructDropdownDescription:
                      (dynamic item) => item == GroupPrivacy.private?
                        Localization().getStringEx("panel.groups.common.privacy.description.short.private", "Only members can see group events and posts, unless an event is marked public.") :
                        Localization().getStringEx("panel.groups.common.privacy.description.short.public",  "Only members can see group events and posts, unless an event is marked public."),
                  onValueChanged: (value) => _onPrivacyChanged(value)
              )
          )),
          Semantics(
            explicitChildNodes: true,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8,vertical: 12),
              child:Text(longDescription ?? '',
                style: TextStyle(color: Styles().colors!.textBackground, fontSize: 14, fontFamily: Styles().fontFamilies!.regular, letterSpacing: 1),
            ),)),
          Container(height: 8,)
      ],));
  }

  void _onPrivacyChanged(dynamic value) {
    _group?.privacy = value;
    if (_isPublicGroup) {
      // Do not hide group from search if it is public
      _group!.hiddenForSearch = false;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildHiddenForSearch() {
    return Visibility(
        visible: _isPrivateGroup,
        child: Container(
            color: Styles().colors!.background,
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  child: _buildSwitch(
                      title: Localization().getStringEx("panel.groups.common.private.search.hidden.label", "Make Group Hidden"),
                      value: _group?.hiddenForSearch,
                      onTap: _onTapHiddenForSearch)),
              Semantics(
                  container: true,
                  child: Container(
                      padding: EdgeInsets.only(left: 8, right: 8, top: 12),
                      child: Text(
                          Localization()
                              .getStringEx("panel.groups.common.private.search.hidden.description", "A hidden group is unsearchable."),
                          style: TextStyle(
                              color: Styles().colors!.textBackground,
                              fontSize: 14,
                              fontFamily: Styles().fontFamilies!.regular,
                              letterSpacing: 1))))
            ])));
  }

  void _onTapHiddenForSearch() {
    _group!.hiddenForSearch = !(_group!.hiddenForSearch ?? false);
    if (mounted) {
      setState(() {});
    }
  }

  //
  //Membership
  Widget _buildMembershipLayout(){
    int questionsCount = _group?.questions?.length ?? 0;
    String questionsDescription = (0 < questionsCount) ?
      (questionsCount.toString() + " " + Localization().getStringEx("panel.groups_settings.tags.label.question","Question(s)")) :
      Localization().getStringEx("panel.groups_settings.membership.button.question.description.default","No question");

    return
      Container(
        color: Styles().colors!.background,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column( children: <Widget>[
          _buildSectionTitle( Localization().getStringEx("panel.groups_settings.membership.title", "Membership"),"images/icon-member.png"),
          Container(height: 12,),
          Semantics(
            explicitChildNodes: true,
            child:_buildMembershipButton(title: Localization().getStringEx("panel.groups_settings.membership.button.question.title","Membership Questions"),
              description: questionsDescription,
              onTap: _onTapMembershipQuestion)),
          Container(height: 20,),
    ]),);
  }

  Widget _buildMembershipButton({required String title, required String description, void onTap()?}){
    return
      InkWell(onTap: onTap,
      child:
        Container (
          decoration: BoxDecoration(
              color: Styles().colors!.white,
              border: Border.all(
                  color: Styles().colors!.surfaceAccent!,
                  width: 1),
              borderRadius:
              BorderRadius.all(Radius.circular(4))),
          padding: EdgeInsets.only(left: 16, right: 16, top: 14,bottom: 18),
          child:
          Column( crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Expanded(child:
                      Text(
                        title,
                        style: TextStyle(
                            fontFamily: Styles().fontFamilies!.bold,
                            fontSize: 16,
                            color: Styles().colors!.fillColorPrimary),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: Image.asset('images/chevron-right.png'),
                    ),
                ]),
                Container(
                  padding: EdgeInsets.only(right: 42,top: 4),
                  child: Text(description,
                    style: TextStyle(color: Styles().colors!.mediumGray, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
                  ),
                )
              ]
          )
      )
    );
  }

  void _onTapMembershipQuestion(){
    Analytics().logSelect(target: "Membership Question");
    if (_group!.questions == null) {
      _group!.questions = [];
    }
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMembershipQuestionsPanel(questions: _group!.questions,))).then((dynamic questions){
      if(questions is List<GroupMembershipQuestion>){
        _group!.questions = questions;
      }
      setState(() {});
    });
  }

  // AuthMan Group
  Widget _buildAuthManLayout() {
    bool isAuthManGroup = _isAuthManGroup;

    return Container(
        color: Styles().colors!.background,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: <Widget>[
          _buildSectionTitle(Localization().getStringEx("panel.groups_settings.authman.section.title", "University managed membership"), "images/icon-member.png"),
          Container(height: 12),
          Padding(
              padding: EdgeInsets.only(top: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    decoration: BoxDecoration(
                        color: Styles().colors!.white,
                        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(4))),
                    padding: EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded( child:
                        Text(Localization().getStringEx("panel.groups_settings.authman.enabled.label", "Is this a managed membership group?"),
                            style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary))),
                        GestureDetector(
                            onTap: _onTapAuthMan,
                            child: Padding(
                                padding: EdgeInsets.only(left: 10), child: Image.asset(isAuthManGroup ? 'images/switch-on.png' : 'images/switch-off.png')))
                      ])
                    ])),
                Visibility(
                    visible: isAuthManGroup,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        _buildInfoHeader(Localization().getStringEx("panel.groups_settings.authman.group.name.label", "Membership name"), null),
                        Padding(padding: EdgeInsets.only(top: 14), child: Text('*', style: TextStyle(color: Styles().colors!.fillColorSecondary, fontSize: 18, fontFamily: Styles().fontFamilies!.bold)))
                      ]),
                      Container(
                          decoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1), color: Styles().colors!.white!),
                          child: TextField(
                            onChanged: _onAuthManGroupNameChanged,
                            controller: _authManGroupNameController,
                            maxLines: 5,
                            decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
                            style: TextStyle(color: Styles().colors!.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
                          ))
                    ]))
              ])),
        ]));
  }

  void _onTapAuthMan() {
    Analytics().logSelect(target: "AuthMan Group");
    if (_group != null) {
      _group!.authManEnabled = (_group!.authManEnabled != true);
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onAuthManGroupNameChanged(String name) {
    if (_group != null) {
      _group!.authManGroupName = name;
    }
    if (mounted) {
      setState(() {});
    }
  }

  //Buttons
  Widget _buildButtonsLayout() {
    return SafeArea(child: Container( color: Styles().colors!.white,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Center(
        child:
        Stack(children: <Widget>[
          RoundedButton(
            label: Localization().getStringEx("panel.groups_settings.button.update.title", "Update Settings"),
            backgroundColor: Colors.white,
            borderColor: Styles().colors!.fillColorSecondary,
            textColor: Styles().colors!.fillColorPrimary,
            progress: _loading,
            onTap: _onUpdateTap,
          ),
        ],),
      )
      ,),);
  }

  void _onUpdateTap(){
    Analytics().logSelect(target: 'Update Settings');
    setState(() {
      _loading = true;
    });

    // if the group is not authman then clear authman group name
    if ((_group != null) && (_group!.authManEnabled != true)) {
      _group!.authManGroupName = null;
    }

    Groups().updateGroup(_group).then((GroupError? error){
      if (mounted) {
        setState(() {
          _loading = false;
        });
        if (error == null) { //ok
          Navigator.pop(context);
        } else { //not ok
          String? message;
          switch (error.code) {
            case 1: message = Localization().getStringEx("panel.groups_create.permission.error.message", "You do not have permission to perform this operation."); break;
            case 5: message = Localization().getStringEx("panel.groups_create.name.error.message", "A group with this name already exists. Please try a different name."); break;
            default: message = sprintf(Localization().getStringEx("panel.groups_update.failed.msg", "Failed to update group: %s."), [error.text ?? Localization().getStringEx('panel.groups_create.unknown.error.message', 'Unknown error occurred')]); break;
          }
          AppAlert.showDialogResult(context, message);
        }
      }
    });
  }
  //


  //Polls
  Widget _buildPollsLayout(){
    return Container(
      color: Styles().colors!.background,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: _buildSwitch(title: Localization().getStringEx("panel.groups_create.only_admins_create_polls.enabled.label", "Only admins can create Polls"), //TBD localization
          value: _group?.onlyAdminsCanCreatePolls,
          onTap: _onTapOnlyAdminCreatePolls
      ),
    );
  }

  void _onTapOnlyAdminCreatePolls(){
    if(_group?.onlyAdminsCanCreatePolls != null) {
      if(mounted){
        setState(() {
          _group!.onlyAdminsCanCreatePolls = !(_group!.onlyAdminsCanCreatePolls ?? false);
        });
      }
    }
  }
  
  // Attendance
  Widget _buildAttendanceLayout() {
    return Container(
      color: Styles().colors!.background,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _buildSwitch(
            title: Localization().getStringEx("panel.groups_settings.attendance_group.label", "Enable attendance checking"),
            value: _group?.attendanceGroup,
            onTap: _onTapAttendanceGroup));
  }

  void _onTapAttendanceGroup() {
    if (_group != null) {
      _group!.attendanceGroup = !(_group!.attendanceGroup ?? false);
      if (mounted) {
        setState(() {});
      }
    }
  }

  //Auto Join
  //Autojoin
  Widget _buildCanAutoJoinLayout(){
    return Container( color: Styles().colors!.background,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _buildSwitch(title: Localization().getStringEx("panel.groups_create.auto_join.enabled.label", "Group can be joined automatically?"),//TBD localize
          value: _group?.canJoinAutomatically,
          onTap: () {
            if (_group?.canJoinAutomatically != null) {
              _group!.canJoinAutomatically = !(_group!.canJoinAutomatically!);
            } else {
              _group?.canJoinAutomatically = true;
            }

            if(mounted){
              setState(() {

              });
            }
          }
      ),
    );
  }

  // Common
  Widget _buildInfoHeader(String title, String? description,{double topPadding = 24}){
    return Container(
        padding: EdgeInsets.only(bottom: 8, top:topPadding),
        child:
        Semantics(
        container: true,
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              label: title,
              header: true,
              excludeSemantics: true,
              child:
              Text(
                title,
                style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 12, fontFamily: Styles().fontFamilies!.bold),
              ),
            ),
            description==null? Container():
            Container(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                description,
                style: TextStyle(color: Styles().colors!.textBackground, fontSize: 14, fontFamily: Styles().fontFamilies!.regular),
              ),
            )
          ],))
    );
  }

  Widget _buildSectionTitle(String title, String iconRes){
    return Container(
        padding: EdgeInsets.only(top:24),
        child:
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
              Container(
                padding: EdgeInsets.only(right: 10),
                child: Image.asset(iconRes, excludeFromSemantics: true,)
              ),
            Expanded(child:
              Semantics(
                label: title,
                header: true,
                excludeSemantics: true,
                child:
                Text(
                  title,
                  style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold),
                ),
              ),
            )
          ],)
    );
  }

  Widget _buildSwitch({String? title, bool? value, void Function()? onTap}){
    return Container(
      child: Container(
          decoration: BoxDecoration(
              color: Styles().colors!.white,
              border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
              borderRadius: BorderRadius.all(Radius.circular(4))),
          padding: EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                  child: Text(title ?? "",
                      style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary))),
              GestureDetector(
                  onTap: onTap ?? (){},
                  child: Padding(padding: EdgeInsets.only(left: 10), child: Image.asset((value ?? false) ? 'images/switch-on.png' : 'images/switch-off.png')))
            ])
          ])),
    );
  }

  void onNameChanged(String name){
    _group!.title = name.trim();
    validateName(name);
  }

  void validateName(String name){
    //TBD name validation hook
    List<String> takenNames = ["test","test1"];
    setState(() {
      _nameIsValid = !takenNames.contains(name);
    });
  }

  bool get _isAuthManGroup{
    return _group?.authManEnabled ?? false;
  }

  bool get _isPrivateGroup {
    return _group?.privacy == GroupPrivacy.private;
  }

  bool get _isPublicGroup {
    return _group?.privacy == GroupPrivacy.public;
  }
}

