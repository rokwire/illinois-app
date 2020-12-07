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
import 'package:illinois/model/ImageType.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/ImageService.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/groups/GroupMembershipQuestionsPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class GroupSettingsPanel extends StatefulWidget {
  final Group group;
  
  GroupSettingsPanel({this.group});

  _GroupSettingsPanelState createState() => _GroupSettingsPanelState();
}

class _GroupSettingsPanelState extends State<GroupSettingsPanel> {
  final _eventTitleController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  final _groupTagsController = TextEditingController();
  final _linkController = TextEditingController();
  List<GroupPrivacy> _groupPrivacyOptions;
  List<String> _groupCategories;

  bool _nameIsValid = true;
  bool _loading = false;

  Group _group; // edit settings here until submit

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
                      context: context,
                      backIconRes: "images/close-white.png",
                      titleWidget: Text(
                        Localization().getStringEx("panel.groups_settings.label.heading", "Group Settings"),
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        Container(
                          color: Styles().colors.white,
                          child: Column(children: <Widget>[
                            _buildImageSection(),
                            Container(padding: EdgeInsets.symmetric(horizontal: 16), child:
                              _buildSectionTitle(Localization().getStringEx("panel.groups_settings.label.heading.general_info", "General group information"), "images/icon-schedule.png"),
                            ),
                            _buildNameField(),
                            _buildDescriptionField(),
                            _buildLinkField(),
                            Container(height: 1, color: Styles().colors.surfaceAccent,),
                            Container(padding: EdgeInsets.symmetric(horizontal: 16), child:
                              _buildSectionTitle(Localization().getStringEx("panel.groups_settings.label.heading.discoverability", "Discoverability"), "images/icon-schedule.png"),
                            ),
                            _buildCategoryDropDown(),
                            _buildTagsLayout(),
                            _buildPrivacyDropDown(),
                            _buildMembershipLayout(),
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
        backgroundColor: Styles().colors.background);
  }

  //Init
  void _initPrivacyData(){
    _groupPrivacyOptions = GroupPrivacy.values;
  }

  void _initCategories(){
    Groups().categories.then((categories){
     setState(() {
       _groupCategories = categories;
     });
    });
  }

  void _fillGroups(){
    if(_group!=null){
      //textFields
      if(_group.title!=null)
        _eventTitleController.text=_group.title;
      if(_group.description!=null)
        _eventDescriptionController.text=_group.description;
      if(_group.webURL!=null)
        _linkController.text = _group.webURL;
    }
  }

  //
  //Image
  Widget _buildImageSection(){
    final double _imageHeight = 200;

    return Container(
      height: _imageHeight,
      color: Styles().colors.background,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          AppString.isStringNotEmpty(_group?.imageURL) ?  Positioned.fill(child:Image.network(_group?.imageURL, fit: BoxFit.cover, headers: AppImage.getAuthImageHeaders(),)) : Container(),
          CustomPaint(
            painter: TrianglePainter(painterColor: Styles().colors.fillColorSecondaryTransparent05, left: false),
            child: Container(
              height: 53,
            ),
          ),
          CustomPaint(
            painter: TrianglePainter(painterColor: Styles().colors.white),
            child: Container(
              height: 30,
            ),
          ),
          Container(
            height: _imageHeight,
            child: Center(
              child:
              Semantics(label:Localization().getStringEx("panel.group_settings.add_image","Add cover image"),
                  hint: Localization().getStringEx("panel.group_settings.add_image.hint",""), button: true, excludeSemantics: true, child:
                  ScalableSmallRoundedButton(
                    maxLines: 2,
                    label: Localization().getStringEx("panel.group_settings.add_image","Add cover image"),
                    textColor: Styles().colors.fillColorPrimary,
                    onTap: _onTapAddImage,
                    showChevron: false,
                  )
              ),
            ),
          )
        ],
      ),
    );
  }

  void _onTapAddImage() async {
    Analytics.instance.logSelect(target: "Add Image");
    String _imageUrl = await showDialog(
        context: context,
        builder: (_) => Material(
          type: MaterialType.transparency,
          child: _AddImageWidget(),
        )
    );
    if(_imageUrl!=null){
      setState(() {
        _group.imageURL = _imageUrl;
      });
    }
    Log.d("Image Url: $_imageUrl");
  }
  //
  //Name
  Widget _buildNameField() {
    String title = Localization().getStringEx("panel.groups_settings.name.title", "GROUP NAME");
    String fieldTitle = Localization().getStringEx("panel.groups_settings.name.field", "NAME FIELD");
    String fieldHint = Localization().getStringEx("panel.groups_settings.name.field.hint", "");

    return
      Column(children: <Widget>[
        Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildInfoHeader(title,null),
            Container(
              height: 48,
              padding: EdgeInsets.only(left: 8,right: 8, top: 12, bottom: 16),
              decoration: BoxDecoration(border: Border.all(color: Styles().colors.fillColorPrimary, width: 1),color: Styles().colors.white),
              child: Semantics(
                  label: fieldTitle,
                  hint: fieldHint,
                  textField: true,
                  excludeSemantics: true,
                  child: TextField(
                    controller: _eventTitleController,
                    onChanged: onNameChanged,
                    decoration: InputDecoration(border: InputBorder.none,),
                    style: TextStyle(color: Styles().colors.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies.regular),
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
                  color: Styles().colors.fillColorSecondaryVariant,
                  border: Border.all(
                      color: Styles().colors.fillColorSecondary,
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
                          style: TextStyle(color: Styles().colors.textBackground, fontSize: 14, fontFamily: Styles().fontFamilies.regular))
                  ))
                ],
              ),
            )
        ));
  }
  //

  //Description
  Widget _buildDescriptionField() {
    String title = Localization().getStringEx("panel.groups_settings.description.title", "GROUP DESCRIPTION");
    String fieldTitle = Localization().getStringEx("panel.groups_settings.description.field", "What’s the purpose of your group? Who should join? What will you do at your events?");
    String fieldHint = Localization().getStringEx("panel.groups_settings.description.field.hint", "");

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildInfoHeader(title,fieldTitle),
          Container(
            height: 230,
            padding: EdgeInsets.only(left: 8,right: 8, top: 12, bottom: 16),
            decoration: BoxDecoration(border: Border.all(color: Styles().colors.fillColorPrimary, width: 1),color: Styles().colors.white),
            child: Semantics(
                label: title,
                hint: fieldHint,
                textField: true,
                excludeSemantics: true,
                child: TextField(
                  controller: _eventDescriptionController,
                  onChanged: (description){ _group.description = description;},
                  maxLines: 64,
                  decoration: InputDecoration(
                    hintText: fieldHint,
                    border: InputBorder.none,),
                  style: TextStyle(color: Styles().colors.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies.regular),
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
                          color: Styles().colors.fillColorPrimary,
                          fontSize: 14,
                          fontFamily: Styles().fontFamilies.bold,
                          letterSpacing: 1),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 15),
                    child: Container(
                      padding:
                      EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                              color: Styles().colors.fillColorPrimary,
                              width: 1)),
                      height: 48,
                      child: TextField(
                        controller: _linkController,
                        decoration: InputDecoration(
                            hintText:  Localization().getStringEx("panel.groups_settings.link.hint", "Add URL"),
                            border: InputBorder.none),
                        style: TextStyle(
                            color: Styles().colors.textBackground,
                            fontSize: 16,
                            fontFamily: Styles().fontFamilies.regular),
                        onChanged: (link){ _group.webURL = link;},
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
                    color: Styles().colors.fillColorPrimary,
                    fontSize: 16,
                    fontFamily: Styles().fontFamilies.medium,
                    decoration: TextDecoration.underline,
                    decorationThickness: 1,
                    decorationColor:
                    Styles().colors.fillColorSecondary),
              ),
            )
        ),
        Container(height: 15)
    ],));
  }

  void _onTapConfirmLinkUrl() {
    Analytics.instance.logSelect(target: "Confirm Website url");
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
                constructTitle: (item) => item,
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
    String fieldTitle = Localization().getStringEx("panel.groups_create.tags.title", "TAGS");
    String fieldHint= Localization().getStringEx("panel.groups_create.tags.hint", "");
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle(fieldTitle,
              Localization().getStringEx("panel.groups_create.tags.description", "Tags help people understand more about your group."),),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    height: 48,
                    padding: EdgeInsets.only(left: 12,right: 12, top: 12, bottom: 16),
                    decoration: BoxDecoration(border: Border.all(color: Styles().colors.fillColorPrimary, width: 1),color: Styles().colors.white),
                    child: Semantics(
                        label: fieldTitle,
                        hint: fieldHint,
                        textField: true,
                        excludeSemantics: true,
                        child: TextField(
                          controller: _groupTagsController,
                          decoration: InputDecoration(border: InputBorder.none,),
                          style: TextStyle(color: Styles().colors.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies.regular),
                        )),
                  ),
                ),
                Container(width: 8,),
                Expanded(
                    flex: 2,
                    child:
                    ScalableRoundedButton(
                      label: Localization().getStringEx("panel.groups_create.tags.button.add.title", "Add"),
                      hint: Localization().getStringEx("panel.groups_create.tags.button.add.hint", "Add"),
                      backgroundColor: Styles().colors.white,
                      textColor: Styles().colors.fillColorPrimary,
                      borderColor: Styles().colors.fillColorSecondary,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      onTap: _onTapAddTag,
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
    if(buttons?.isEmpty??true)
      return Container();

    List<Widget> rows = List();
    List<Widget> lastRowChildren;
    for(int i=0; i<buttons.length;i++){
      if(i%2==0){
        lastRowChildren = new List();
        rows.add(SingleChildScrollView(scrollDirection: Axis.horizontal, child:Row(children:lastRowChildren,)));
        rows.add(Container(height: 8,));
      } else {
        lastRowChildren?.add(Container(width: 13,));
      }
      lastRowChildren.add(buttons[i]);
    }
    rows.add(Container(height: 24,));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  List<Widget> _buildTagsButtons(){
    List<String> tags = _group?.tags;
    List<Widget> result = new List();
    if (AppCollection.isCollectionNotEmpty(tags)) {
      tags.forEach((String tag) {
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
                  color: Styles().colors.fillColorPrimary,
                  borderRadius: BorderRadius.all(Radius.circular(4))),
              child: Row(children: <Widget>[
                Semantics(excludeSemantics: true, child:
                  Container(
                      padding: EdgeInsets.only(top:4,bottom: 4,left: 8),
                      child: Text(tag,
                        style: TextStyle(color: Styles().colors.white, fontFamily: Styles().fontFamilies.bold, fontSize: 12,),
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
    if(_group!=null) {
      if (_group.tags == null) {
        _group.tags = new List();
      }

      if (_group.tags.contains(tag)) {
        _group.tags.remove(tag);
      } else {
        _group.tags.add(tag);
      }
    }
    setState(() {});
  }

  void _onTapAddTag(){
    String tag = _groupTagsController.text?.toString();
    if(_group!=null) {
      if (_group.tags == null) {
        _group.tags = new List<String>();
      }
      _group.tags.add(tag);
      _groupTagsController.clear();
    }

    setState(() {});
  }
  //
  //Privacy
  Widget _buildPrivacyDropDown() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        color: Styles().colors.background,
        child:Column(children: <Widget>[
          Container(
              child:  _buildSectionTitle( Localization().getStringEx("panel.groups_settings.privacy.title", "Privacy"),"images/icon-privacy.png")),
          Container(
              child:  _buildInfoHeader( Localization().getStringEx("panel.groups_settings.privacy.title.description", "SELECT PRIVACY"),null, topPadding: 12)),
          Semantics(
          explicitChildNodes: true,
          child: Container(
              child:  GroupDropDownButton(
                  emptySelectionText: Localization().getStringEx("panel.groups_settings.privacy.hint.default","Select privacy setting.."),
                  buttonHint: Localization().getStringEx("panel.groups_settings.privacy.hint", "Double tap to show privacy oprions"),
                  items: _groupPrivacyOptions,
                  initialSelectedValue: _group?.privacy ?? (_groupPrivacyOptions!=null?_groupPrivacyOptions[0] : null),
                  constructDescription:
                      (item) => item == GroupPrivacy.private?
                        Localization().getStringEx("panel.common.privacy_description.private", "Only members can see group events and posts") :
                        Localization().getStringEx("panel.common.privacy_description.public",  "Anyone can see group events and posts"),
                  constructTitle:
                      (item) => item == GroupPrivacy.private?
                        Localization().getStringEx("panel.common.privacy_title.private", "Private") :
                        Localization().getStringEx("panel.common.privacy_title.public",  "Public"),
                  onValueChanged: (value) {
                    setState(() {
                      _group?.privacy = value;
                    });
                  }
              )
          )),
          Semantics(
            explicitChildNodes: true,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8,vertical: 12),
              child:Text(
                Localization().getStringEx("panel.groups_settings.privacy.description", "Anyone who uses the Illinois app can find this group. Only admins can see whose in the group."),
                style: TextStyle(color: Styles().colors.textBackground, fontSize: 14, fontFamily: Styles().fontFamilies.regular, letterSpacing: 1),
            ),)),
          Container(height: 8,)
      ],));
  }
  //
  //Membership
  Widget _buildMembershipLayout(){
    int questionsCount = _group?.questions?.length ?? 0;
    String questionsDescription = (0 < questionsCount) ?
      (questionsCount.toString() + Localization().getStringEx("panel.groups_create.tags.label.question","Questions")) :
      Localization().getStringEx("panel.groups_settings.membership.button.question.description.default","No question");

    return
      Container(
        color: Styles().colors.background,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column( children: <Widget>[
          _buildSectionTitle( Localization().getStringEx("panel.groups_settings.membership.title", "Membership"),"images/icon-member.png"),
          Container(height: 12,),
          Semantics(
            explicitChildNodes: true,
            child:_buildMembershipButton(title: Localization().getStringEx("panel.groups_settings.membership.button.question.title","Membership question"),
              description: questionsDescription,
              onTap: _onTapMembershipQuestion)),
          Container(height: 40,),
    ]),);
  }

  Widget _buildMembershipButton({String title, String description, Function onTap}){
    return
      InkWell(onTap: onTap,
      child:
        Container (
          decoration: BoxDecoration(
              color: Styles().colors.white,
              border: Border.all(
                  color: Styles().colors.surfaceAccent,
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
                            fontFamily: Styles().fontFamilies.bold,
                            fontSize: 16,
                            color: Styles().colors.fillColorPrimary),
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
                    style: TextStyle(color: Styles().colors.mediumGray, fontSize: 16, fontFamily: Styles().fontFamilies.regular),
                  ),
                )
              ]
          )
      )
    );
  }

  void _onTapMembershipQuestion(){
    Analytics.instance.logSelect(target: "Membership Question");
    if (_group.questions == null) {
      _group.questions = [];
    }
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMembershipQuestionsPanel(questions: _group.questions,))).then((dynamic questions){
      if(questions is List<GroupMembershipQuestion>){
        _group.questions = questions;
      }
      setState(() {});
    });
  }

  //Buttons
  Widget _buildButtonsLayout() {
    return SafeArea(child: Container( color: Styles().colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Center(
        child:
        Stack(children: <Widget>[
          ScalableRoundedButton(
            label: Localization().getStringEx("panel.groups_settings.button.update.title", "Update Settings"),
            backgroundColor: Colors.white,
            borderColor: Styles().colors.fillColorSecondary,
            textColor: Styles().colors.fillColorPrimary,
            onTap: _onUpdateTap,
          ),
          Visibility(visible: _loading,
            child: Container(
              height: 48,
              child: Align(alignment: Alignment.center,
                child: SizedBox(height: 24, width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorPrimary), )
                ),
              ),
            ),
          ),
        ],),
      )
      ,),);
  }

  void _onUpdateTap(){
    setState(() {
      _loading = true;
    });
    Groups().updateGroup(_group).then((_){
      setState(() {
        _loading = false;
      });

      Navigator.pop(context);
    }).catchError((e){
      AppAlert.showDialogResult(context, Localization().getStringEx("panel.groups_create.tags.label.update_error", "Unable to update the group"));
      //error
      setState(() {
        _loading = false;
      });
    });
  }
  //
  // Common
  Widget _buildInfoHeader(String title, String description,{double topPadding = 24}){
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
                style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 12, fontFamily: Styles().fontFamilies.bold),
              ),
            ),
            description==null? Container():
            Container(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                description,
                style: TextStyle(color: Styles().colors.textBackground, fontSize: 14, fontFamily: Styles().fontFamilies.regular),
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
            iconRes==null? Container() :
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
                  style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold),
                ),
              ),
            )
          ],)
    );
  }

  void onNameChanged(String name){
    _group.title = name;
    validateName(name);
  }

  void validateName(String name){
    //TBD name validation hook
    List<String> takenNames = ["test","test1"];
    setState(() {
      _nameIsValid = !(takenNames?.contains(name)??false);
    });
  }
}

class _AddImageWidget extends StatefulWidget {
  @override
  _AddImageWidgetState createState() => _AddImageWidgetState();
}

class _AddImageWidgetState extends State<_AddImageWidget> {
  var _imageUrlController = TextEditingController();

  final ImageType _imageType = ImageType(identifier: 'event-tout', width: 1080);
  bool _showProgress = false;

  _AddImageWidgetState();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _imageUrlController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Styles().colors.fillColorPrimary,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 10, top: 10),
                    child: Text(
                      Localization().getStringEx("widget.add_image.heading", "Select Image"),
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: Styles().fontFamilies.medium,
                          fontSize: 24),
                    ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: _onTapCloseImageSelection,
                    child: Padding(
                      padding: EdgeInsets.only(right: 10, top: 10),
                      child: Text(
                        '\u00D7',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: Styles().fontFamilies.medium,
                            fontSize: 50),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Container(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.all(10),
                          child: TextFormField(
                              controller: _imageUrlController,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText:  Localization().getStringEx("widget.add_image.field.description.label","Image url"),
                                labelText:  Localization().getStringEx("widget.add_image.field.description.hint","Image url"),
                              ))),
                      Padding(
                          padding: EdgeInsets.all(10),
                          child: RoundedButton(
                              label: Localization().getStringEx("widget.add_image.button.use_url.label","Use Url"),
                              borderColor: Styles().colors.fillColorSecondary,
                              backgroundColor: Styles().colors.background,
                              textColor: Styles().colors.fillColorPrimary,
                              onTap: _onTapUseUrl)),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                              padding: EdgeInsets.all(10),
                              child: RoundedButton(
                                  label:  Localization().getStringEx("widget.add_image.button.chose_device.label","Choose from device"),
                                  borderColor: Styles().colors.fillColorSecondary,
                                  backgroundColor: Styles().colors.background,
                                  textColor: Styles().colors.fillColorPrimary,
                                  onTap: _onTapChooseFromDevice)),
                          _showProgress ? AppProgressIndicator.create() : Container(),
                        ],
                      ),
                    ]))
          ],
        ));
  }

  void _onTapCloseImageSelection() {
    Analytics.instance.logSelect(target: "Close image selection");
    Navigator.pop(context, "");
  }

  void _onTapUseUrl() {
    Analytics.instance.logSelect(target: "Use Url");
    String url = _imageUrlController.value.text;
    if (url == "") {
      AppToast.show(Localization().getStringEx("widget.add_image.validation.url.label","Please enter an url"));
      return;
    }

    bool isReadyUrl = url.endsWith(".webp");
    if (isReadyUrl) {
      //ready
      AppToast.show(Localization().getStringEx("widget.add_image.validation.success.label","Successfully added an image"));
      Navigator.pop(context, url);
    } else {
      //we need to process it
      setState(() {
        _showProgress = true;
      });

      Future<ImagesResult> result =
      ImageService().useUrl(_imageType, url);
      result.then((logicResult) {
        setState(() {
          _showProgress = false;
        });


        ImagesResultType resultType = logicResult.resultType;
        switch (resultType) {
          case ImagesResultType.CANCELLED:
          //do nothing
            break;
          case ImagesResultType.ERROR_OCCURRED:
            AppToast.show(logicResult.errorMessage);
            break;
          case ImagesResultType.SUCCEEDED:
          //ready
            AppToast.show(Localization().getStringEx("widget.add_image.validation.success.label","Successfully added an image"));
            Navigator.pop(context, logicResult.data);
            break;
        }
      });
    }
  }

  void _onTapChooseFromDevice() {
    Analytics.instance.logSelect(target: "Choose From Device");

    setState(() {
      _showProgress = true;
    });

    Future<ImagesResult> result =
    ImageService().chooseFromDevice(_imageType);
    result.then((logicResult) {
      setState(() {
        _showProgress = false;
      });

      ImagesResultType resultType = logicResult.resultType;
      switch (resultType) {
        case ImagesResultType.CANCELLED:
        //do nothing
          break;
        case ImagesResultType.ERROR_OCCURRED:
          AppToast.show(logicResult.errorMessage);
          break;
        case ImagesResultType.SUCCEEDED:
        //ready
          AppToast.show(Localization().getStringEx("widget.add_image.validation.success.label","Successfully added an image"));
          Navigator.pop(context, logicResult.data);
          break;
      }
    });
  }
}