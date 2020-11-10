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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:illinois/ui/events/CreateEventPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/groups/GroupMembershipQuestionsPanel.dart';
import 'package:illinois/ui/groups/GroupMembershipStepsPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class GroupSettingsPanel extends StatefulWidget {
  final GroupDetail groupDetail;
  
  GroupSettingsPanel({this.groupDetail});

  _GroupSettingsPanelState createState() => _GroupSettingsPanelState();
}

class _GroupSettingsPanelState extends State<GroupSettingsPanel> {
  final _eventTitleController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  final _linkController = TextEditingController();
  List<GroupPrivacy> _groupPrivacyOptions;
  List<String> _groupCategories;
  List<String> _groupTags;

  bool _nameIsValid = true;
  bool _loading = false;

  GroupDetail _groupDetail; // edit settings here until submit

  @override
  void initState() {
    _groupDetail = GroupDetail.fromOther(widget.groupDetail);
    _initPrivacyData();
    _initCategories();
    _initTags();
    _fillGroupDetails();
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

  void _initTags(){
    Groups().tags.then((tags){
      setState(() {
        _groupTags = tags;
      });
    });
  }

  void _fillGroupDetails(){
    if(_groupDetail!=null){
      //textFields
      if(_groupDetail.title!=null)
        _eventTitleController.text=_groupDetail.title;
      if(_groupDetail.description!=null)
        _eventDescriptionController.text=_groupDetail.description;
      if(_groupDetail.webURL!=null)
        _linkController.text = _groupDetail.webURL;
    }
  }

  //
  //Image
  Widget _buildImageSection(){
    final double _imageHeight = 208;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        Container(
          color: Styles().colors.lightGray,
          height: _imageHeight,
        ),
        CustomPaint(
            painter: TrianglePainter(
                painterColor: Styles().colors.fillColorSecondary,
                left: false),
            child: Container(
              height: 48,
            )),
        CustomPaint(
          painter:
          TrianglePainter(painterColor: Colors.white),
          child: Container(
            height: 25,
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
    );
  }

  void _onTapAddImage() async {
    Analytics.instance.logSelect(target: "Add Image");
    String _imageUrl = await showDialog(
        context: context,
        builder: (_) => Material(
          type: MaterialType.transparency,
          child: AddImageWidget(),
        )
    );
    if(_imageUrl!=null){
      _groupDetail.imageURL = _imageUrl;
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
    String fieldTitle = Localization().getStringEx("panel.groups_settings.description.field", "Tell people what this gtoup is about");
    String fieldHint = Localization().getStringEx("panel.groups_settings.description.field.hint", "");

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildInfoHeader(title,null),
          Container(
            height: 230,
            padding: EdgeInsets.only(left: 8,right: 8, top: 12, bottom: 16),
            decoration: BoxDecoration(border: Border.all(color: Styles().colors.fillColorPrimary, width: 1),color: Styles().colors.white),
            child: Semantics(
                label: fieldTitle,
                hint: fieldHint,
                textField: true,
                excludeSemantics: true,
                child: TextField(
                  controller: _eventDescriptionController,
                  onChanged: (description){ _groupDetail.description = description;},
                  maxLines: 64,
                  decoration: InputDecoration(
                    hintText: fieldTitle,
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
                        onChanged: (link){ _groupDetail.webURL = link;},
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
            GroupDropDownButton(
                emptySelectionText: Localization().getStringEx("panel.groups_settings.category.default_text", "Select a category.."),
                buttonHint: Localization().getStringEx("panel.groups_settings.category.hint", "Double tap to show categories options"),
                initialSelectedValue: _groupDetail?.category,
                items: _groupCategories,
                constructTitle: (item) => item,
                onValueChanged: (value) {
                  setState(() {
                    _groupDetail?.category = value;
                    Log.d("Selected Category: $value");
                  });
                }
            )
          ],
        ));
  }
  //

  //Types
  Widget _buildTagsLayout() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildInfoHeader(Localization().getStringEx("panel.groups_settings.tags.title", "TAGS"),
              Localization().getStringEx("panel.groups_settings.tags.description", "Tags help people understand more about your group. Select all that apply to your group."),),
            Container(height: 8,),
            _constructTagsContent()
          ],
        ));
  }

  Widget _constructTagsContent(){
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
      children: rows,
    );
  }

  List<Widget> _buildTagsButtons(){
      List<String> tags = _groupTags;
      List<Widget> result = new List();
      if (AppCollection.isCollectionNotEmpty(tags)) {
        tags.forEach((String tag) {
          result.add(_buildTagButton(tag));
        });
      }
      return result;
  }

  Widget _buildTagButton(String tag){
    bool isSelected = _groupDetail?.tags?.contains(tag)??false;
    return
      InkWell(
      child: Container(
          decoration: BoxDecoration(
              color: isSelected? Styles().colors.fillColorPrimary: Styles().colors.lightGray,
              borderRadius: BorderRadius.all(Radius.circular(4))),
          child: Row(children: <Widget>[
            Container(
              padding: EdgeInsets.only(top:4,bottom: 4,left: 8),
              child: Text(tag,
                style: TextStyle(color: isSelected? Styles().colors.white : Styles().colors.textBackground , fontFamily: Styles().fontFamilies.bold, fontSize: 12,),
              )),
            Container (
              padding: EdgeInsets.only(top:8,bottom: 8,right: 8),
              child: Image.asset(isSelected?"images/small-add-orange.png" : "images/small-add.png"),
            )

          ],)
        ),
      onTap: () => onTagTap(tag)
      );
  }

  void onTagTap(String tag){
    if(_groupDetail!=null) {
      if (_groupDetail.tags == null) {
        _groupDetail.tags = new List();
      }

      if (_groupDetail.tags.contains(tag)) {
        _groupDetail.tags.remove(tag);
      } else {
        _groupDetail.tags.add(tag);
      }
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
          Container(
              child:  GroupDropDownButton(
                  emptySelectionText: Localization().getStringEx("panel.groups_settings.privacy.hint.default","Select privacy setting.."),
                  buttonHint: Localization().getStringEx("panel.groups_settings.privacy.hint", "Double tap to show privacy oprions"),
                  items: _groupPrivacyOptions,
                  initialSelectedValue: _groupDetail?.privacy ?? (_groupPrivacyOptions!=null?_groupPrivacyOptions[0] : null),
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
                      _groupDetail?.privacy = value;
                    });
                  }
              )
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8,vertical: 12),
            child:Text(
              Localization().getStringEx("panel.groups_settings.privacy.description", "Anyone who uses the Illinois app can find this group. Only admins can see whose in the group."),
              style: TextStyle(color: Styles().colors.textBackground, fontSize: 14, fontFamily: Styles().fontFamilies.regular, letterSpacing: 1),
            ),),
          Container(height: 8,)
      ],));
  }
  //

  //Membership
  Widget _buildMembershipLayout(){
    int questionsCount = _groupDetail?.membershipQuest?.questions?.length ?? 0;
    String questionsDescription = (0 < questionsCount) ?
      "$questionsCount Questions" :
      Localization().getStringEx("panel.groups_settings.membership.button.question.description.default","No question");

    return
      Container(
        color: Styles().colors.background,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column( children: <Widget>[
          _buildSectionTitle( Localization().getStringEx("panel.groups_settings.membership.title", "Membership"),"images/icon-member.png"),
          Container(height: 12,),
          _buildMembershipButton(title: Localization().getStringEx("panel.groups_settings.membership.button.steps.title","Membership steps"),
            description: Localization().getStringEx("panel.groups_settings.membership.button.steps.description","Share the steps someone will take to become a member."),
            onTap: _onTapMembershipSteps),
          Container(height: 10,),
          _buildMembershipButton(title: Localization().getStringEx("panel.groups_settings.membership.button.question.title","Membership question"),
            description: questionsDescription,
            onTap: _onTapMembershipQuestion),
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

  void _onTapMembershipSteps(){
    Analytics.instance.logSelect(target: "Membership Steps");
    if (_groupDetail.membershipQuest == null) {
      _groupDetail.membershipQuest = GroupMembershipQuest();
    }
    if (_groupDetail.membershipQuest.steps == null) {
      _groupDetail.membershipQuest.steps = [];
    }
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMembershipStepsPanel(steps: _groupDetail.membershipQuest.steps,)));
  }

  void _onTapMembershipQuestion(){
    Analytics.instance.logSelect(target: "Membership Question");
    if (_groupDetail.membershipQuest == null) {
      _groupDetail.membershipQuest = GroupMembershipQuest();
    }
    if (_groupDetail.membershipQuest.questions == null) {
      _groupDetail.membershipQuest.questions = [];
    }
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMembershipQuestionsPanel(questions: _groupDetail.membershipQuest.questions,))).then((_){
      setState(() {
      });
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
//            height: 48,
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
    Groups().updateGroup(_groupDetail).then((detail){
      if(detail!=null){
        //ok
        setState(() {
          _loading = false;
        });

        Navigator.pop(context);
      } else {
        AppAlert.showDialogResult(context, "Unable to update group"); //TBD localize
      }
    }).catchError((e){
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              label: title,
              hint: title,
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
          ],)

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
                hint: title,
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
    _groupDetail.title = name;
    validateName(name);
  }

  void validateName(String name){
    //TBD
    List<String> takenNames = ["test","test1"];
    setState(() {
      _nameIsValid = !(takenNames?.contains(name)??false);
    });
  }
}