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
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/research/ResearchProjectProfilePanel.dart';
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
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
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
  final _groupTitleController = TextEditingController();
  final _groupDescriptionController = TextEditingController();
  final _linkController = TextEditingController();
  final _researchConsentDetailsController = TextEditingController();
  final _authManGroupNameController = TextEditingController();

  final List<GroupPrivacy>? _groupPrivacyOptions = GroupPrivacy.values;
  List<String>? _groupCategories;

  bool _nameIsValid = true;
  bool _loading = false;

  Group? _group; // edit settings here until submit

  @override
  void initState() {
    _group = Group.fromOther(widget.group);

    _groupTitleController.text = _group?.title ?? '';
    _groupDescriptionController.text = _group?.description ?? '';
    _researchConsentDetailsController.text = _group?.researchConsentDetails ?? '';
    _linkController.text = _group?.webURL ?? '';
    _authManGroupNameController.text = _group?.authManGroupName ?? '';

    _initCategories();
    super.initState();
  }

  @override
  void dispose() {
    _groupTitleController.dispose();
    _groupDescriptionController.dispose();
    _researchConsentDetailsController.dispose();
    _linkController.dispose();
    _authManGroupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                color: Styles().colors!.background,
                child: CustomScrollView(
                  scrollDirection: Axis.vertical,
                  slivers: <Widget>[
                    SliverHeaderBar(
                      title: (_group?.researchProject == true) ? "Project Settings" : Localization().getStringEx("panel.groups_settings.label.heading", "Group Settings"),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        Container(
                          color: Styles().colors!.background,
                          child: Column(children: <Widget>[
                            _buildImageSection(),
                            Container(padding: EdgeInsets.symmetric(horizontal: 16), child:
                              _buildSectionTitle((_group?.researchProject == true) ? "General project information" : Localization().getStringEx("panel.groups_settings.label.heading.general_info", "General group information"), "images/icon-schedule.png"),
                            ),
                            _buildNameField(),
                            _buildDescriptionField(),
                            _buildLinkField(),
                            
                            Visibility(visible: !_isResearchProject, child:
                              Column(children: [
                                Container(height: 1, color: Styles().colors!.surfaceAccent,),
                                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
                                  _buildSectionTitle(Localization().getStringEx("panel.groups_settings.label.heading.discoverability", "Discoverability"), "images/icon-schedule.png"),
                                ),
                                _buildCategoryDropDown(),
                                _buildTagsLayout(),
                              ],)
                            ),
                            
                            Visibility(visible: _isResearchProject, child:
                              Column(children: [
                                Container(height: 1, color: Styles().colors!.surfaceAccent,),
                                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
                                  _buildSectionTitle("Research", "images/icon-gear.png"),
                                ),
                                //_buildResearchOptionLayout(),
                                _buildResearchOpenLayout(),
                                _buildResearchConfirmationLayout(),
                                _buildResearchConsentDetailsField(),
                                _buildResearchAudienceLayout(),
                              ])
                            ),

                            Visibility(visible: !_isResearchProject, child:
                              Column(children: [
                                Padding(padding: EdgeInsets.symmetric(vertical: 24), child:
                                  Container(height: 1, color: Styles().colors!.surfaceAccent,),
                                ),
                                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
                                  _buildSectionTitle(Localization().getStringEx("panel.groups_create.label.privacy", "Privacy"), "images/icon-privacy.png"),
                                ),
                                Container(height: 8),
                                _buildPrivacyDropDown(),
                                _buildHiddenForSearch(),
                              ])
                            ),

                            Visibility(visible: _canViewManagedSettings && !_isResearchProject, child:
                              _buildAuthManLayout()
                            ),
                            
                            Visibility(visible: !_isAuthManGroup, child:
                              _buildMembershipLayout()
                            ),
                            
                            Visibility(visible: _canViewManagedSettings  && !_isResearchProject, child:
                              Padding(padding: EdgeInsets.only(top: 8), child:
                                _buildCanAutoJoinLayout(),
                              )
                            ),

                            Visibility(visible: !_isResearchProject, child:
                              Padding(padding: EdgeInsets.only(top: 8), child:
                                _buildPollsLayout(),
                              )
                            ),

                            Visibility(visible: !_isResearchProject, child:
                              Padding(padding: EdgeInsets.only(top: 8), child:
                                _buildAttendanceLayout(),
                              )
                            ),

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
  void _initCategories(){
    Groups().loadCategories().then((categories){
     setState(() {
       _groupCategories = categories;
     });
    });
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
          StringUtils.isNotEmpty(_group?.imageURL) ?  Positioned.fill(child: ModalImageHolder(child: Image.network(_group!.imageURL!, excludeFromSemantics: true, fit: BoxFit.cover, headers: Config().networkAuthHeaders))) : Container(),
          CustomPaint(
            painter: TrianglePainter(painterColor: Styles().colors!.fillColorSecondaryTransparent05, horzDir: TriangleHorzDirection.leftToRight),
            child: Container(
              height: 53,
            ),
          ),
          CustomPaint(
            painter: TrianglePainter(painterColor: Styles().colors!.background),
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
                    borderColor: _canUpdate ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
                    textColor: _canUpdate ? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent,
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
    if (!_canUpdate) {
      return;
    }
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
    String title = (_group?.researchProject == true) ? "PROJECT NAME" : Localization().getStringEx("panel.groups_settings.name.title", "GROUP NAME");
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
                    controller: _groupTitleController,
                    enabled: _canUpdate,
                    readOnly: !_canUpdate,
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
    String title = (_group?.researchProject == true) ? "PROJECT DESCRIPTION" : Localization().getStringEx("panel.groups_settings.description.title", "GROUP DESCRIPTION");
    String? fieldTitle = (_group?.researchProject == true) ?
      "What’s the purpose of your project? Who should join? What will you do at your events?" :
      Localization().getStringEx("panel.groups_settings.description.field", "What’s the purpose of your group? Who should join? What will you do at your events?");
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
                  controller: _groupDescriptionController,
                  onChanged: (description){ _group!.description = description;},
                  maxLines: 8,
                  enabled: _canUpdate,
                  readOnly: !_canUpdate,
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
                        enabled: _canUpdate,
                        readOnly: !_canUpdate,
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
  //Research Consent Details
  Widget _buildResearchConsentDetailsField() {
    String? title = "Consent details";
    String? description = "Lorem ipsum dolor sit amet? Consectetur adipiscing elit? Sed fermentum ante est, sed dignissim lectus rutrum id?";
    String? fieldTitle = "CONSENT DETAILS FIELD";
    String? fieldHint = "";

    return Visibility(visible: _isResearchProject, child:
      Container(padding: EdgeInsets.symmetric(horizontal: 16), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          _buildInfoHeader(title, description),
          Container(height: 5,),
          Container(decoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1), color: Styles().colors!.white), child:
            Row(children: [
              Expanded(child:
                  Semantics(label: fieldTitle, hint: fieldHint, textField: true, excludeSemantics: true, child:
                    TextField(
                        controller: _researchConsentDetailsController,
                        maxLines: 15,
                        decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
                        style: TextStyle(color: Styles().colors!.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
                        onChanged: (text) => _group?.researchConsentDetails = text,
                    )
                  ),
                )
              ])
            ),
          ],
        ),
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
            _buildInfoHeader(Localization().getStringEx("panel.groups_settings.category.title", "CATEGORY"),
              (_group?.researchProject == true) ?
                "Choose the category your project can be filtered by." :
                Localization().getStringEx("panel.groups_settings.category.description", "Choose the category your group can be filtered by."),),
            Semantics(
            explicitChildNodes: true,
            child: GroupDropDownButton(
                enabled: _canUpdate,
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
    String? description = (_group?.researchProject == true) ?
      "Tags help people understand more about your project." :
      Localization().getStringEx("panel.groups_create.tags.description", "Tags help people understand more about your group.");
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
                      borderColor: _canUpdate ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
                      textColor: _canUpdate ? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent,
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
        label: sprintf(Localization().getStringEx("panel.groups_settings.tags.label.tag.format", "%s tag, "),[tag]),
        hint: Localization().getStringEx("panel.groups_settings.tags.label.tag.hint", "double tab to remove tag"),
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

  void onTagTap(String tag) {
    if (!_canUpdate) {
      return;
    }
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

  void _onTapTags() {
    if (!_canUpdate) {
      return;
    }
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
                  enabled: _canUpdate,
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
    if (!_canUpdate) {
      return;
    }
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
                      enabled: _canUpdate,
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
    if (!_canUpdate) {
      return;
    }
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
      sprintf(Localization().getStringEx("panel.groups_settings.tags.label.question.format","%s Question(s)"), [questionsCount.toString()]) :
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

  void _onTapMembershipQuestion() {
    if (!_canUpdate) {
      return;
    }
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

  // Research 
  
  /*Widget _buildResearchOptionLayout() {
    return Container(
        padding: EdgeInsets.only(left: 16, right: 16, top: 8),
        child: _buildSwitch(
            title: "Is this a research project?",
            value: _group?.researchProject,
            onTap: _onTapResearchProject));
  }

  void _onTapResearchProject() {
    if (_group != null) {
      if (mounted) {
        setState(() {
          _group?.researchProject = !(_group?.researchProject ?? false);
        });
      }
    }
  }*/

  Widget _buildResearchOpenLayout() {
    return Container(
        padding: EdgeInsets.only(left: 16, right: 16, top: 8),
        child: _buildSwitch(
            title: "Is recruitment closed?",
            value: _group?.researchOpen == false,
            onTap: _onTapResearchOpen));
  }

  void _onTapResearchOpen() {
    if (_group != null) {
      if (mounted) {
        setState(() {
          _group?.researchOpen = (_group?.researchOpen != true);
        });
      }
    }
  }

  Widget _buildResearchConfirmationLayout() {
    return Container(
        padding: EdgeInsets.only(left: 16, right: 16, top: 8),
        child: _buildSwitch(
            title: "Requires confirmation",
            value: (_group?.researchConfirmation == true),
            onTap: _onTapResearchConfirmation));
  }

  void _onTapResearchConfirmation() {
    if (_group != null) {
      if (mounted) {
        setState(() {
          _group?.researchConfirmation = (_group?.researchConfirmation != true);
        });
      }
    }
  }

  Widget _buildResearchAudienceLayout() {
    int questionsCount = researchProfileQuestionsCount;
    String questionsDescription = (0 < questionsCount) ?
      sprintf(Localization().getStringEx("panel.groups_settings.tags.label.question.format","%s Question(s)"), [questionsCount.toString()]) :
      Localization().getStringEx("panel.groups_settings.membership.button.question.description.default","No question");

    return Container(
      color: Styles().colors!.background,
      padding: EdgeInsets.only(left: 16, right: 16, top: 8),
      child: Column(children: <Widget>[
        Semantics(
            explicitChildNodes: true,
            child: _buildMembershipButton(
                title: "Target Audience",
                description: questionsDescription,
                onTap: _onTapResearchProfile)),
      ]),
    );
  }

  int get researchProfileQuestionsCount {
    int count = 0;
    _group?.researchProfile?.forEach((String key, dynamic value) {
      if (value is Map) {
        count += value.length;
      }
    });
    return count;
  }

  void _onTapResearchProfile() {
    Analytics().logSelect(target: "Target Audience");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ResearchProjectProfilePanel(profile: _group?.researchProfile,))).then((dynamic profile){
      setState(() {
        if (profile is Map<String, dynamic>) {
          _group?.researchProfile = profile;
        }
      });
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
                            style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: (_canUpdate ? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent)))),
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
                            enabled: _canUpdate,
                            readOnly: !_canUpdate,
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
    if (!_canUpdate) {
      return;
    }
    Analytics().logSelect(target: "AuthMan Group");
    if (_group != null) {
      _group!.authManEnabled = (_group!.authManEnabled != true);
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onAuthManGroupNameChanged(String name) {
    if (!_canUpdate) {
      return;
    }
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
            borderColor: _canUpdate ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
            textColor: _canUpdate ? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent,
            progress: _loading,
            enabled: _canUpdate,
            onTap: _onUpdateTap,
          ),
        ],),
      )
      ,),);
  }

  void _onUpdateTap() {
    if (!_canUpdate) {
      return;
    }
    Analytics().logSelect(target: 'Update Settings');
    setState(() {
      _loading = true;
    });

    // control research groups options
    if (_group?.researchProject == true) {
      _group?.privacy = GroupPrivacy.public;
      _group?.hiddenForSearch = false;
      _group?.canJoinAutomatically = false;
      _group?.onlyAdminsCanCreatePolls = true;
      _group?.authManEnabled = false;
      _group?.authManGroupName = null;
      _group!.attendanceGroup = false;
    }
    else {
      _group?.researchOpen = null;
      _group?.researchConsentDetails = null;
      _group?.researchConfirmation = null;
      _group?.researchProfile = null;
    }

    // if the group is not authman then clear authman group name
    if (_group?.authManEnabled != true) {
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
      child: _buildSwitch(title: Localization().getStringEx("panel.groups_settings.only_admins_create_polls.enabled.label", "Only admins can create Polls"),
          enabled: _canUpdate,
          value: _group?.onlyAdminsCanCreatePolls,
          onTap: _onTapOnlyAdminCreatePolls
      ),
    );
  }

  void _onTapOnlyAdminCreatePolls() {
    if (!_canUpdate) {
      return;
    }
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
            enabled: _canUpdate,
            value: _group?.attendanceGroup,
            onTap: _onTapAttendanceGroup));
  }

  void _onTapAttendanceGroup() {
    if (!_canUpdate) {
      return;
    }
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
        child: _buildSwitch(title: Localization().getStringEx("panel.groups_settings.auto_join.enabled.label", "Group can be joined automatically?"),
          enabled: _canUpdate,
          value: _group?.canJoinAutomatically,
          onTap: () {
            if (!_canUpdate) {
              return;
            }
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

  Widget _buildSwitch({String? title, bool? value, bool enabled = true, void Function()? onTap}) {
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
                      style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: enabled ? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent))),
              GestureDetector(
                  onTap: (enabled && (onTap != null)) ? onTap : (){},
                  child: Padding(padding: EdgeInsets.only(left: 10), child: Image.asset((value ?? false) ? 'images/switch-on.png' : 'images/switch-off.png')))
            ])
          ])),
    );
  }

  void onNameChanged(String name) {
    if (!_canUpdate) {
      return;
    }
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

  bool get _canUpdate {
    if (!(_group?.currentUserIsAdmin ?? false)) {
      return false;
    }
    if (_isAuthManGroup) {
      return _isUserManagedGroupAdmin;
    } else {
      return true;
    }
  }

  bool get _canViewManagedSettings {
    return _isAuthManGroup || _isUserManagedGroupAdmin;
  }

  bool get _isUserManagedGroupAdmin {
    return Auth2().account?.isManagedGroupAdmin ?? false;
  }

  bool get _isAuthManGroup{
    return _group?.authManEnabled ?? false;
  }

  bool get _isResearchProject {
    return _group?.researchProject ?? false;
  }

  bool get _isPrivateGroup {
    return _group?.privacy == GroupPrivacy.private;
  }

  bool get _isPublicGroup {
    return _group?.privacy == GroupPrivacy.public;
  }
}

