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

import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:illinois/utils/Utils.dart';

class GroupCreatePanel extends StatefulWidget {
  _GroupCreatePanelState createState() => _GroupCreatePanelState();
}

class _GroupCreatePanelState extends State<GroupCreatePanel> {
  final _groupTitleController = TextEditingController();
  final _groupDescriptionController = TextEditingController();
  final _groupTagsController = TextEditingController();

  Group _group;

  List<GroupPrivacy> _groupPrivacyOptions;
  List<String> _groupCategories;
  LinkedHashSet<String> _groupsNames;

  bool _nameIsValid = true;
  bool _groupNamesLoading = false;
  bool _groupCategoeriesLoading = false;
  bool _creating = false;
  bool get _loading => _groupCategoeriesLoading || _groupNamesLoading;

  @override
  void initState() {
    _group = Group();
    _initGroupNames();
    _initPrivacyData();
    _initCategories();
    super.initState();
  }

  //Init
  void _initGroupNames(){
    _groupNamesLoading = true;
    Groups().loadGroups().then((groups){
      _groupsNames = groups?.map((group) => group?.title?.toLowerCase()?.trim())?.toSet();
    }).catchError((error){
      print(error);
    }).whenComplete((){
      setState(() {
        _groupNamesLoading = false;
      });
    });
  }

  void _initPrivacyData(){
    _groupPrivacyOptions = GroupPrivacy.values;
    _group.privacy = _groupPrivacyOptions[0]; //default value Private
  }

  void _initCategories(){
    setState(() {
      _groupCategoeriesLoading = true;
    });
    Groups().categories.then((categories){
      setState(() {
        _groupCategories = categories;
      });
    }).whenComplete((){
      setState(() {
        _groupCategoeriesLoading = false;
      });
    });
  }
  //

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          children: <Widget>[
            _loading
            ? Expanded(child:
                Center(child:
                  Container(
                    child: Align(alignment: Alignment.center,
                      child: SizedBox(height: 24, width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorPrimary), )
                      ),
                    ),
                  ),
                )
              )
            : Expanded(
              child: Container(
                color: Colors.white,
                child: CustomScrollView(
                  scrollDirection: Axis.vertical,
                  slivers: <Widget>[
                    SliverHeaderBar(
                      context: context,
                      backIconRes: "images/close-white.png",
                      titleWidget: Text(
                        Localization().getStringEx("panel.groups_create.label.heading", "Create a group"),
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        Container(
                          color: Styles().colors.background,
                          child: Column(children: <Widget>[
                            _buildImageSection(),
                            _buildNameField(),
                            _buildNameError(),
                            _buildDescriptionField(),
                            Container(height: 24,),
                            Container(height: 1, color: Styles().colors.surfaceAccent,),
                            Container(height: 24,),
                            _buildTitle(Localization().getStringEx("panel.groups_create.label.discoverability", "Discoverability"), "images/icon-search.png"),
                            _buildCategoryDropDown(),
                            _buildTagsLayout(),
                            Container(height: 24,),
                            Container(height: 1, color: Styles().colors.surfaceAccent,),
                            Container(height: 24,),
                            _buildTitle(Localization().getStringEx("panel.groups_create.label.privacy", "Privacy"), "images/icon-privacy.png"),
                            _buildPrivacyDropDown(),
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

  //Image
  Widget _buildImageSection() {
    final double _imageHeight = 200;

    return Container(
        height: _imageHeight,
        color: Styles().colors.background,
        child: Stack(alignment: Alignment.bottomCenter, children: <Widget>[
          AppString.isStringNotEmpty(_group?.imageURL)
              ? Positioned.fill(child: Image.network(_group?.imageURL, fit: BoxFit.cover, headers: Network.appAuthHeaders))
              : Container(),
          CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.fillColorSecondaryTransparent05, left: false), child: Container(height: 53)),
          CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.background), child: Container(height: 30)),
          Container(
              height: _imageHeight,
              child: Center(
                  child: Semantics(
                      label: Localization().getStringEx("panel.group_settings.add_image", "Add cover image"),
                      hint: Localization().getStringEx("panel.group_settings.add_image.hint", ""),
                      button: true,
                      excludeSemantics: true,
                      child: ScalableSmallRoundedButton(
                          maxLines: 2,
                          label: Localization().getStringEx("panel.group_settings.add_image", "Add cover image"),
                          textColor: Styles().colors.fillColorPrimary,
                          onTap: _onTapAddImage,
                          showChevron: false))))
        ]));
  }

  void _onTapAddImage() async {
    Analytics.instance.logSelect(target: "Add Image");
    String _imageUrl = await showDialog(context: context, builder: (_) => Material(type: MaterialType.transparency, child: GroupAddImageWidget()));
    if (_imageUrl != null) {
      if (mounted) {
        setState(() {
          _group.imageURL = _imageUrl;
        });
      }
    }
    Log.d("Image Url: $_imageUrl");
  }

  //Name
  Widget _buildNameField() {
    String title = Localization().getStringEx("panel.groups_create.name.title", "NAME YOUR GROUP");
    String fieldTitle = Localization().getStringEx("panel.groups_create.name.field", "NAME FIELD");
    String fieldHint = Localization().getStringEx("panel.groups_create.name.field.hint", "");

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
         _buildSectionTitle(title,null),
          Container(
            height: 48,
            padding: EdgeInsets.only(left: 12,right: 12, top: 12, bottom: 16),
            decoration: BoxDecoration(border: Border.all(color: Styles().colors.fillColorPrimary, width: 1),color: Styles().colors.white),
            child: Semantics(
                label: fieldTitle,
                hint: fieldHint,
                textField: true,
                excludeSemantics: true,
                child: TextField(
                  controller: _groupTitleController,
                  onChanged: onNameChanged,
                  decoration: InputDecoration(border: InputBorder.none,),
                  style: TextStyle(color: Styles().colors.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies.regular),
                )),
          ),
        ],
      ),

    );
  }

  Widget _buildNameError(){
    String errorMessage = Localization().getStringEx("panel.groups_create.name.error.message", "A group with this name already exists. Please try a different name.");

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
  //Name
  Widget _buildDescriptionField() {
    String title = Localization().getStringEx("panel.groups_create.description.title", "DESCRIPTION");
    String description = Localization().getStringEx("panel.groups_create.description.description", "What’s the purpose of your group? Who should join? What will you do at your events?");
    String fieldTitle = Localization().getStringEx("panel.groups_create.description.field", "DESCRIPTION FIELD");
    String fieldHint = Localization().getStringEx("panel.groups_create.description.field.hint", "");

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionTitle(title,description),
          Container(height: 5,),
          Container(
            height: 114,
            padding: EdgeInsets.only(left: 12,right: 12, top: 12, bottom: 16),
            decoration: BoxDecoration(border: Border.all(color: Styles().colors.fillColorPrimary, width: 1),color: Styles().colors.white),
            child:
            Row(children: [
              Expanded(child:
                Semantics(
                    label: fieldTitle,
                    hint: fieldHint,
                    textField: true,
                    excludeSemantics: true,
                    child: TextField(
                      onChanged: (text){
                        if(_group!=null)
                          _group.description = text;
                      },
                      controller: _groupDescriptionController,
                      maxLines: 100,
                      decoration: InputDecoration(border: InputBorder.none,),
                      style: TextStyle(color: Styles().colors.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies.regular),
                    )),
            )],)
          ),
        ],
      ),

    );
  }
  //
  //Category
  Widget _buildCategoryDropDown() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle(Localization().getStringEx("panel.groups_create.category.title", "GROUP CATEGORY"),
              Localization().getStringEx("panel.groups_create.category.description", "Choose the category your group can be filtered by."),),
            GroupDropDownButton(
              emptySelectionText: Localization().getStringEx("panel.groups_create.category.default_text", "Select a category.."),
              buttonHint: Localization().getStringEx("panel.groups_create.category.hint", "Double tap to show categories options"),
              items: _groupCategories,
              constructTitle: (item) => item,
              onValueChanged: (value) {
                setState(() {
                  _group.category = value;
                  Log.d("Selected Category: $value");
                });
              }
            )
          ],
        ));
  }
  //
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
                    hint: Localization().getStringEx("panel.groups_create.tags.button.add.hint", ""),
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

    List<Widget> rows = [];
    List<Widget> lastRowChildren;
    for(int i=0; i<buttons.length;i++){
      if(i%2==0){
        lastRowChildren =  [];
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
    List<Widget> result =  [];
    if (AppCollection.isCollectionNotEmpty(tags)) {
      tags.forEach((String tag) {
        result.add(_buildTagButton(tag));
      });
    }
    return result;
  }

  Widget _buildTagButton(String tag){
    return
      InkWell(
          child: Container(
              decoration: BoxDecoration(
                  color: Styles().colors.fillColorPrimary,
                  borderRadius: BorderRadius.all(Radius.circular(4))),
              child: Row(children: <Widget>[
                Container(
                    padding: EdgeInsets.only(top:4,bottom: 4,left: 8),
                    child: Text(tag,
                      style: TextStyle(color: Styles().colors.white, fontFamily: Styles().fontFamilies.bold, fontSize: 12,),
                    )),
                Container (
                  padding: EdgeInsets.only(top:8,bottom: 8,right: 8, left: 8),
                  child: Image.asset("images/small-add-orange.png"),
                )

              ],)
          ),
          onTap: () => onTagTap(tag)
      );
  }

  void onTagTap(String tag){
    if(_group!=null) {
      if (_group.tags == null) {
        _group.tags =  [];
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
        _group.tags = [];
      }
      _group.tags.add(tag);
      _groupTagsController.clear();
    }

    setState(() {});
  }
  //

  //Privacy
  Widget _buildPrivacyDropDown() {
    return
      Column(children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child:  _buildSectionTitle( Localization().getStringEx("panel.groups_create.privacy.title", "PRIVACY"),null)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child:  GroupDropDownButton(
              emptySelectionText: Localization().getStringEx("panel.groups_create.privacy.hint.default","Select privacy setting.."),
              buttonHint: Localization().getStringEx("panel.groups_create.privacy.hint", "Double tap to show privacy options"),
              items: _groupPrivacyOptions,
              initialSelectedValue: _group.privacy,
              constructDescription:
                  (item) => item == GroupPrivacy.private?
              Localization().getStringEx("panel.common.privacy_description.private", "Only members can see group events") :
              Localization().getStringEx("panel.common.privacy_description.public",  "Anyone can see group events"),
              constructTitle:
                  (item) => item == GroupPrivacy.private?
              Localization().getStringEx("panel.common.privacy_title.private", "Private") :
              Localization().getStringEx("panel.common.privacy_title.public",  "Public"),

              onValueChanged: (value) {
                setState(() {
                  _group.privacy = value;
                });
              }
          )
        ),
        Container(padding: EdgeInsets.symmetric(horizontal: 24,vertical: 12),
          child:Text(
            Localization().getStringEx("panel.groups_create.privacy.description", "Anyone who uses the Illinois app can find this group. Only admins can see whose in the group."),
            style: TextStyle(color: Styles().colors.textBackground, fontSize: 14, fontFamily: Styles().fontFamilies.regular, letterSpacing: 1),
          ),),
        Container(height: 40,)
      ],);
  }
  //

  //Buttons
  Widget _buildButtonsLayout() {
    return
      Stack(alignment: Alignment.center, children: <Widget>[
        Container( color: Styles().colors.white,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ScalableRoundedButton(
              label: Localization().getStringEx("panel.groups_create.button.create.title", "Create Group"),
              backgroundColor: Colors.white,
              borderColor: Styles().colors.fillColorSecondary,
              textColor: Styles().colors.fillColorPrimary,
              onTap: _onCreateTap,
            ),
          )
          ,),
        Visibility(visible: _creating,
          child: Container(
            child: Align(alignment: Alignment.center,
              child: SizedBox(height: 24, width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorPrimary), )
              ),
            ),
          ),
        ),
      ],);
  }

  void _onCreateTap(){
    setState(() {
      _creating = true;
    });
    Groups().createGroup(_group).then((detail){
      if(detail!=null){
        //ok
        setState(() {
          _creating = false;
        });

        Navigator.pop(context);
      }
    }).catchError((e){
      //error
      setState(() {
        _creating = false;
      });
    });
  }
  //
  // Common
  Widget _buildSectionTitle(String title, String description){
    return Container(
      padding: EdgeInsets.only(bottom: 8, top:16),
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

  Widget _buildTitle(String title, String iconRes){
    return
      Container(
        padding: EdgeInsets.only(left: 16),
        child:
          Semantics(
            label: title,
            hint: title,
            header: true,
            excludeSemantics: true,
            child:
            Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Image.asset(iconRes, color: Styles().colors.fillColorSecondary,),
              Expanded(child:
              Container(
                  padding: EdgeInsets.only(left: 14, right: 4),
                  child:Text(
                    title,
                    style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold,),
                  )
              ))
      ],)));
  }

  void onNameChanged(String name){
    _group.title = name;
     validateName(name);
  }

  void validateName(String name){
    LinkedHashSet<String> takenNames = _groupsNames ?? [];
    setState(() {
      _nameIsValid = !(takenNames?.contains(name?.toLowerCase()?.trim())??false);
    });
  }
}
