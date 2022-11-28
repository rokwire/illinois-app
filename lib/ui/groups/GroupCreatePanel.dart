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
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:illinois/ui/groups/GroupMembershipQuestionsPanel.dart';
import 'package:illinois/ui/groups/GroupTagsPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class GroupCreatePanel extends StatefulWidget {
  final Group? group;
  GroupCreatePanel({Key? key, this.group}) : super(key: key);
  _GroupCreatePanelState createState() => _GroupCreatePanelState();
}

class _GroupCreatePanelState extends State<GroupCreatePanel> {
  final _groupTitleController = TextEditingController();
  final _groupDescriptionController = TextEditingController();
  final _researchConsentDetailsController = TextEditingController();
  final _researchConsentStatementController = TextEditingController();
  final _authManGroupNameController = TextEditingController();

  Group? _group;

  final List<GroupPrivacy> _groupPrivacyOptions = GroupPrivacy.values;
  List<String>? _groupCategories;

  bool _groupCategoeriesLoading = false;
  bool _creating = false;
  bool _researchRequiresConsentConfirmation = false;

  @override
  void initState() {
    _initGroup();
    _initCategories();
    _initResearchConsentDetails();
    super.initState();
  }

  @override
  void dispose() {
    _groupTitleController.dispose();
    _groupDescriptionController.dispose();
    _researchConsentDetailsController.dispose();
    _researchConsentStatementController.dispose();
    _authManGroupNameController.dispose();
    super.dispose();
  }

  //Init

  void _initGroup(){
    _group = (widget.group != null) ? Group.fromOther(widget.group) : Group();
    _group?.onlyAdminsCanCreatePolls ??= true;
    _group?.researchOpen ??= (_group?.researchProject == true) ? true : null;
    _group?.privacy ??= (_group?.researchProject == true) ? GroupPrivacy.public : GroupPrivacy.private;
    _group?.category ??= (_group?.researchProject == true) ? 'Other' : null;

    _groupTitleController.text = _group?.title ?? '';
    _groupDescriptionController.text = _group?.description ?? '';
    _researchConsentDetailsController.text = _group?.researchConsentDetails ?? '';
    _authManGroupNameController.text = _group?.authManGroupName ?? '';

    // #2550: we need consent checkbox selected by default
    _researchRequiresConsentConfirmation = true; // StringUtils.isNotEmpty(_group?.researchConsentStatement)

    if (StringUtils.isNotEmpty(_group?.researchConsentStatement)) {
      _researchConsentStatementController.text = _group!.researchConsentStatement!;
    }
    else {
      _group?.researchConsentStatement = _researchConsentStatementController.text = 'I have read and I understand the consent details. I certify that I am 18 years old or older. By clicking the "Request to participate" button, I indicate my willingness to voluntarily take part in this study.';
    }
  }

  void _initCategories(){
    setState(() {
      _groupCategoeriesLoading = true;
    });
    Groups().loadCategories().then((categories){
      setStateIfMounted(() {
        _groupCategories = categories;
      });
    }).whenComplete((){
      setStateIfMounted(() {
        _groupCategoeriesLoading = false;
      });
    });
  }

  Future<void> _initResearchConsentDetails() async {
    if (_group?.researchProject == true) {
      String? currentLocale = Localization().currentLocale?.languageCode;
      String? defaultLocale = Localization().defaultLocale?.languageCode;
      String? consentDetails;
      if ((consentDetails == null) && (currentLocale != null)) {
        consentDetails = await AppBundle.loadString('assets/research.consent.details.$currentLocale.txt');
      }
      if ((consentDetails == null) && (defaultLocale != null) && (defaultLocale != currentLocale)) {
        consentDetails = await AppBundle.loadString('assets/research.consent.details.$defaultLocale.txt');
      }
      if (consentDetails == null) {
        consentDetails = await AppBundle.loadString('assets/research.consent.details.txt');
      }
      if (consentDetails != null) {
        _group?.researchConsentDetails = _researchConsentDetailsController.text = consentDetails;
      }
    }
  }


  //

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Styles().colors!.background, body:
      Column(children: <Widget>[
        _loading
          ? Expanded(child:
              Center(child:
                Container(
                  child: Align(alignment: Alignment.center,
                    child: SizedBox(height: 24, width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorPrimary), )
                    ),
                  ),
                ),
              )
            )
          : Expanded(child:
            Container(color: Colors.white, child:
              CustomScrollView(scrollDirection: Axis.vertical, slivers: <Widget>[
                SliverHeaderBar(
                  title: (_group?.researchProject == true) ? 'Create Research Project' : Localization().getStringEx("panel.groups_create.label.heading", "Create a Group"),
                ),
                SliverList(delegate: SliverChildListDelegate([
                  Container(color: Styles().colors!.background, child:
                    Column(children: <Widget>[
                      _buildImageSection(),
                      _buildNameField(),
                      _buildDescriptionField(),

                      Visibility(visible: !_isResearchProject, child:
                        Column(children: [
                          Padding(padding: EdgeInsets.symmetric(vertical: 20), child:
                            Container(height: 1, color: Styles().colors!.surfaceAccent,),
                          ),
                          _buildTitle(Localization().getStringEx("panel.groups_create.label.discoverability", "Discoverability"), "images/icon-search.png"),
                          _buildCategoryDropDown(),
                          _buildTagsLayout(),
                        ]),
                      ),


                      Visibility(visible:_isResearchProject, child:
                        Column(children: [
                          //Padding(padding: EdgeInsets.symmetric(vertical: 20), child:
                          //  Container(height: 1, color: Styles().colors!.surfaceAccent,),
                          //),
                          //_buildTitle("Research", "images/icon-gear.png"),
                          //_buildResearchOptionLayout(),
                          //_buildResearchOpenLayout(),
                          _buildResearchConsentDetailsField(),
                          _buildResearchConfirmationLayout(),
                          _buildResearchAudienceLayout(),
                        ])
                      ),

                      Visibility(visible: !_isResearchProject, child:
                        Column(children: [
                          Padding(padding: EdgeInsets.symmetric(vertical: 24), child:
                            Container(height: 1, color: Styles().colors!.surfaceAccent,),
                          ),
                          _buildTitle(Localization().getStringEx("panel.groups_create.label.privacy", "Privacy"), "images/icon-privacy.png"),
                          Container(height: 8),
                          _buildPrivacyDropDown(),
                          _buildHiddenForSearch(),
                        ])
                      ),

                      Visibility(visible: _isManagedGroupAdmin && !_isResearchProject, child: Column(children: [
                        _buildTitle(Localization().getStringEx("panel.groups_create.authman.section.title", "University managed membership"), "images/icon-member.png"),
                        _buildAuthManLayout(),
                      ])),
                      
                      Visibility(visible: !_isAuthManGroup, child: Padding(padding: EdgeInsets.only(top: 20), child: Column(children: [
                        _buildTitle(_isResearchProject ? 'Participation' : Localization().getStringEx("panel.groups_create.membership.section.title", "Membership"), "images/icon-member.png"),
                        _buildMembershipLayout(),
                      ],),),),
                      
                      Visibility(visible: !_isResearchProject, child:
                        Padding(padding: EdgeInsets.only(top: 8), child:
                          _buildCanAutojoinLayout(),
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
                      Container(height: 40),
                    ],),
                  )
                ]),
              ),
            ],),
          ),
        ),
        _buildButtonsLayout(),
      ],),
    );
  }

  //Image
  Widget _buildImageSection() {
    final double _imageHeight = 200;

    return Container(
        height: _imageHeight,
        color: Styles().colors!.background,
        child: Stack(alignment: Alignment.bottomCenter, children: <Widget>[
          StringUtils.isNotEmpty(_group?.imageURL)
              ? Positioned.fill(child: ModalImageHolder(child:Image.network(_group!.imageURL!, excludeFromSemantics: true, fit: BoxFit.cover, headers: Config().networkAuthHeaders)))
              : Container(),
          CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.fillColorSecondaryTransparent05, horzDir: TriangleHorzDirection.leftToRight), child: Container(height: 53)),
          CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.background), child: Container(height: 30)),
          Container(
              height: _imageHeight,
              child: Center(
                  child: Semantics(
                      label: Localization().getStringEx("panel.groups_settings.add_image", "Add Cover Image"),
                      hint: Localization().getStringEx("panel.groups_settings.add_image.hint", ""),
                      button: true,
                      excludeSemantics: true,
                      child: RoundedButton(
                          label: Localization().getStringEx("panel.groups_settings.add_image", "Add Cover Image"),
                          textColor: Styles().colors!.fillColorPrimary,
                          onTap: _onTapAddImage,
                          backgroundColor: Colors.transparent,
                          contentWeight: 0.8,
                    ))))
        ]));
  }

  void _onTapAddImage() async {
    Analytics().logSelect(target: "Add Image");
    String? _imageUrl = await showDialog(context: context, builder: (_) => Material(type: MaterialType.transparency, child: GroupAddImageWidget()));
    if (_imageUrl != null) {
      if (mounted) {
        setState(() {
          _group!.imageURL = _imageUrl;
        });
      }
    }
    Log.d("Image Url: $_imageUrl");
  }

  //Name
  Widget _buildNameField() {
    String? title = (_group?.researchProject == true) ? "NAME YOUR PROJECT" : Localization().getStringEx("panel.groups_create.name.title", "NAME YOUR GROUP");
    String? fieldTitle = Localization().getStringEx("panel.groups_create.name.field", "NAME FIELD");
    String? fieldHint = Localization().getStringEx("panel.groups_create.name.field.hint", "");

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
         _buildSectionTitle(title,null, true),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1),color: Styles().colors!.white),
            child: Semantics(
                label: fieldTitle,
                hint: fieldHint,
                textField: true,
                excludeSemantics: true,
                child: TextField(
                  controller: _groupTitleController,
                  onChanged: (text) => setState((){_group?.title = text; }) ,
                  maxLines: 1,
                  decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                  style: TextStyle(color: Styles().colors!.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
                )),
          ),
        ],
      ),

    );
  }

  //Description
  //Name
  Widget _buildDescriptionField() {
    String? title = Localization().getStringEx("panel.groups_create.description.title", "DESCRIPTION");
    String? description = (_group?.researchProject == true) ?
      "What’s the purpose of your project? Who should join? What will you do at your events?" :
      Localization().getStringEx("panel.groups_create.description.description", "What’s the purpose of your group? Who should join? What will you do at your events?");
    String? fieldTitle = Localization().getStringEx("panel.groups_create.description.field", "DESCRIPTION FIELD");
    String? fieldHint = Localization().getStringEx("panel.groups_create.description.field.hint", "");

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionTitle(title,description),
          Container(height: 5,),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1),color: Styles().colors!.white),
            child:
            Row(children: [
              Expanded(child:
                Semantics(
                    label: fieldTitle,
                    hint: fieldHint,
                    textField: true,
                    excludeSemantics: true,
                    child: TextField(
                      onChanged: (text) => _group?.description = text,
                      controller: _groupDescriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
                      style: TextStyle(color: Styles().colors!.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
                    )),
            )],)
          ),
        ],
      ),

    );
  }
  //
  //Research Description
  Widget _buildResearchConsentDetailsField() {
    String? title = "PROJECT DETAILS";
    String? fieldTitle = "PROJECT DETAILS FIELD";
    String? fieldHint = "";

    return Visibility(visible: _isResearchProject, child:
      Container(padding: EdgeInsets.symmetric(horizontal: 16), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          _buildSectionTitle(title, null),
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
        ],),
      ),
    );
  }
  //
  //Research Confirmation
  Widget _buildResearchConfirmationLayout() {
    String? title = "PARTICIPANT CONSENT";
    String? fieldTitle = "PARTICIPANT CONSENT FIELD";
    String? fieldHint = "";

    return Container(padding: EdgeInsets.only(left: 16, right: 16, top: 8), child:
      Column(children: [
        _buildSwitch(
          title: "Require participant consent",
          value: _researchRequiresConsentConfirmation,
          onTap: _onTapResearchConfirmation
        ),
        Visibility(visible: _researchRequiresConsentConfirmation, child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            _buildSectionTitle(title, null),
            Container(decoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1), color: Styles().colors!.white), child:
              Row(children: [
                Expanded(child:
                  Semantics(label: fieldTitle, hint: fieldHint, textField: true, excludeSemantics: true, child:
                    TextField(
                        controller: _researchConsentStatementController,
                        maxLines: 5,
                        decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
                        style: TextStyle(color: Styles().colors!.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
                        onChanged: (text) => setState(() { _group?.researchConsentStatement = text; }),
                    )
                  ),
                )
              ])
            ),
          ],),
        ),

      ],)
    );
  }

  void _onTapResearchConfirmation() {
    if (mounted) {
      setState(() {
        _researchRequiresConsentConfirmation = !_researchRequiresConsentConfirmation;
      });
    }
  }
  //
  //Category
  Widget _buildCategoryDropDown() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle(
              (_group?.researchProject == true) ? "PROJECT CATEGORY" : Localization().getStringEx("panel.groups_create.category.title", "GROUP CATEGORY"),
              (_group?.researchProject == true) ? "Choose the category your project can be filtered by." : Localization().getStringEx("panel.groups_create.category.description", "Choose the category your group can be filtered by."), true),
            GroupDropDownButton(
              emptySelectionText: Localization().getStringEx("panel.groups_create.category.default_text", "Select a category.."),
              buttonHint: Localization().getStringEx("panel.groups_create.category.hint", "Double tap to show categories options"),
              items: _groupCategories,
              initialSelectedValue: _group?.category,
              constructTitle: (dynamic item) => item,
              onValueChanged: (value) {
                setState(() {
                  _group!.category = value;
                  Log.d("Selected Category: $value");
                });
              }
            )
          ],
        ));
  }

  //Tags
  Widget _buildTagsLayout() {
    String? fieldTitle = Localization().getStringEx("panel.groups_create.tags.title", "TAGS");
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(flex: 5, child:
              _buildSectionTitle(fieldTitle, (_group?.researchProject == true) ? "Tags help people understand more about your project." : Localization().getStringEx("panel.groups_create.tags.description", "Tags help people understand more about your group."))),
            Container(width: 8),
            Expanded(flex: 2, child:
              RoundedButton(
                label: Localization().getStringEx("panel.groups_create.button.tags.title", "Tags"),
                hint: Localization().getStringEx("panel.groups_create.button.tags.hint", ""),
                backgroundColor: Styles().colors!.white,
                textColor: Styles().colors!.fillColorPrimary,
                borderColor: Styles().colors!.fillColorSecondary,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: _onTapTags))
          ]),
          _constructTagButtonsContent()
        ]));
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

    return Padding(padding: EdgeInsets.only(top: 10), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows,
    ));
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
      InkWell(
          child: Container(
              decoration: BoxDecoration(
                  color: Styles().colors!.fillColorPrimary,
                  borderRadius: BorderRadius.all(Radius.circular(4))),
              child: Row(children: <Widget>[
                Container(
                    padding: EdgeInsets.only(top:4,bottom: 4,left: 8),
                    child: Text(tag,
                      style: TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.bold, fontSize: 12,),
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
    Analytics().logSelect(target: "Tag: $tag");
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
    Analytics().logSelect(target: "Tags");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupTagsPanel(selectedTags: _group?.tags))).then((tags) {
      // (tags == null) means that the user hit the back button
      if (tags != null) {
        setState(() {
          _group!.tags = tags;
        });
      }
    });
  }

  //Privacy
  Widget _buildPrivacyDropDown() {

    String? longDescription;
    switch(_group?.privacy) {
      case GroupPrivacy.private: longDescription = Localization().getStringEx("panel.groups.common.privacy.description.long.private", "Anyone who uses the app can find this group if they search and match the full name. Only admins can see who is in the group."); break;
      case GroupPrivacy.public: longDescription = Localization().getStringEx("panel.groups.common.privacy.description.long.public", "Anyone who uses the app will see this group. Only admins can see who is in the group."); break;
      default: break;
    }

    return
      Column(children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child:  GroupDropDownButton(
              emptySelectionText: Localization().getStringEx("panel.groups_create.privacy.hint.default","Select privacy setting.."),
              buttonHint: Localization().getStringEx("panel.groups_create.privacy.hint", "Double tap to show privacy options"),
              items: _groupPrivacyOptions,
              initialSelectedValue: _group!.privacy,
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
        ),
        Semantics(container: true, child:
          Container(padding: EdgeInsets.symmetric(horizontal: 24,vertical: 12),
            child:Text(longDescription ?? '',
              style: TextStyle(color: Styles().colors!.textBackground, fontSize: 14, fontFamily: Styles().fontFamilies!.regular, letterSpacing: 1),
            ),)),
        Container(height: _isPrivateGroup ? 5 : 40)
      ],);
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
        child: Padding(
            padding: EdgeInsets.only(left: 16, right: 16),
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

  // Membership Questions
  Widget _buildMembershipLayout() {
    String buttonTitle = _isResearchProject ? "Recruitment Questions" : Localization().getStringEx("panel.groups_settings.membership.button.question.title","Membership Questions");
    int questionsCount = _group?.questions?.length ?? 0;
    String questionsDescription = (0 < questionsCount)
        ? (questionsCount.toString() + " " + Localization().getStringEx("panel.groups_create.questions.existing.label", "Question(s)"))
        : Localization().getStringEx("panel.groups_create.questions.missing.label", "No questions");

    return Container(color: Styles().colors!.background, padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(children: <Widget>[
        Container(height: 12),
        Semantics(explicitChildNodes: true, child:
          _buildMembershipButton(
            title: buttonTitle,
            description: questionsDescription,
            onTap: _onTapQuestions
          )
        ),
        Container(height: 20),
      ]),
    );
  }

  Widget _buildMembershipButton({required String title, required String description, void onTap()?}) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            decoration: BoxDecoration(
                color: Styles().colors!.white,
                border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
                borderRadius: BorderRadius.all(Radius.circular(4))),
            padding: EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: <Widget>[
                Expanded(
                    child: Text(
                  title,
                  style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary),
                )),
                Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Image.asset('images/chevron-right.png'),
                )
              ]),
              Container(
                  padding: EdgeInsets.only(right: 42, top: 4),
                  child: Text(
                    description,
                    style: TextStyle(color: Styles().colors!.mediumGray, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
                  ))
            ])));
  }

  void _onTapQuestions() {
    Analytics().logSelect(target: "Membership Questions");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMembershipQuestionsPanel(group: _group))).then((_) {
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
  }

  Widget _buildResearchOpenLayout() {
    return Container(
        padding: EdgeInsets.only(left: 16, right: 16, top: 8),
        child: _buildSwitch(
            title: "Is the research project open?",
            value: _group?.researchOpen == true,
            onTap: _onTapResearchOpen));
  }

  void _onTapResearchOpen() {
    if (_group != null) {
      if (mounted) {
        setState(() {
          _group?.researchOpen = !(_group?.researchOpen ?? false);
        });
      }
    }
  }*/

  Widget _buildResearchAudienceLayout() {
    int questionsCount = _researchProfileQuestionsCount;
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

  int get _researchProfileQuestionsCount {
    int count = 0;
    _group?.researchProfile?.forEach((String key, dynamic value) {
      if (value is Map) {
        value.forEach((key, value) {
          if ((value is List) && value.isNotEmpty) {
            count++;
          }
        });
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

  //Autojoin
  Widget _buildCanAutojoinLayout(){
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: _buildSwitch(title: Localization().getStringEx("panel.groups_create.auto_join.enabled.label", "Group can be joined automatically?"),
        value: _group?.canJoinAutomatically,
        onTap: () {
          if (_group?.canJoinAutomatically != null) {
            _group!.canJoinAutomatically = !(_group!.canJoinAutomatically!);
          } else {
            _group?.canJoinAutomatically = true;
          }
        }
      ),
    );
  }

  // AuthMan Group
  Widget _buildAuthManLayout() {
    return Padding(
        padding: EdgeInsets.only(left: 16, top: 12, right: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSwitch(title: Localization().getStringEx("panel.groups_create.authman.enabled.label", "Is this a managed membership group?"),
              value: _isAuthManGroup,
              onTap: _onTapAuthMan
          ),
          Visibility(
              visible: _isAuthManGroup,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildSectionTitle(Localization().getStringEx("panel.groups_create.authman.group.name.label", "Membership name"), null, true),
                Container(
                    decoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1), color: Styles().colors!.white),
                    child: TextField(
                      onChanged: _onAuthManGroupNameChanged,
                      controller: _authManGroupNameController,
                      maxLines: 5,
                      decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
                      style: TextStyle(color: Styles().colors!.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
                    ))
              ]))
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
    if (mounted) {
      setState(() {
        _group?.authManGroupName = name;
      });
    }
  }

  //Polls
  Widget _buildPollsLayout(){
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: _buildSwitch(title: Localization().getStringEx("panel.groups_create.only_admins_create_polls.enabled.label", "Only admins can create Polls"),
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
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _buildSwitch(
            title: Localization().getStringEx("panel.groups_create.attendance_group.label", "Enable attendance checking"),
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

  //Buttons
  Widget _buildButtonsLayout() {
    return
        Container( color: Styles().colors!.white,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: RoundedButton(
              label: (_group?.researchProject == true) ? "Create Project" : Localization().getStringEx("panel.groups_create.button.create.title", "Create Group"),
              backgroundColor: Styles().colors!.white,
              borderColor: _canSave ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
              textColor: _canSave ? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent,
              enabled: _canSave,
              progress:  _creating,
              onTap: _onCreateTap,
            ),
          ),
        );
  }

  void _onCreateTap() {
    AppAlert.showCustomDialog(
        context: context,
        contentWidget: Text(Localization().getStringEx("panel.groups_create.prompt.msg.title", "The {{app_university}} takes pride in its efforts to support free speech and to foster inclusion and mutual respect. Users may submit a report to group administrators about obscene, threatening, or harassing content. Users may also choose to report content in violation of Student Code to the Office of the Dean of Students.").replaceAll('{{app_university}}', Localization().getStringEx('app.univerity_name', 'University of Illinois'))),
        actions: <Widget>[
          TextButton(
              child:
              Text(Localization().getStringEx('dialog.ok.title', 'Ok')),
              onPressed: () {
                Navigator.of(context).pop();
                _onCreateGroup();
              }),
          TextButton(
              child: Text(Localization().getStringEx('dialog.cancel.title', 'Cancel')),
              onPressed: () => Navigator.of(context).pop())
        ]);
  }

  void _onCreateGroup() {
    Analytics().logSelect(target: "Create Group");
    if(!_creating && _canSave) {
      setState(() {
        _creating = true;
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
        _group?.researchConsentStatement = null;
        _group?.researchProfile = null;
      }

      // if the group is not authman then clear authman group name
      if (_group?.authManEnabled != true) {
        _group?.authManGroupName = null;
      }

      // if the group is not research or if it does not require confirmation then clear consent statement text
      if ((_group?.researchProject != true) || (_researchRequiresConsentConfirmation != true)) {
        _group?.researchConsentStatement = null;
      }

      Groups().createGroup(_group).then((GroupError? error) {
        if (mounted) {
          setState(() {
            _creating = false;
          });
          if (error == null) { //ok
            Navigator.pop(context);
          } else { //not ok
            String? message;
            switch (error.code) {
              case 1: message = Localization().getStringEx("panel.groups_create.permission.error.message", "You do not have permission to perform this operation."); break;
              case 5: message = Localization().getStringEx("panel.groups_create.name.error.message", "A group with this name already exists. Please try a different name."); break;
              default: message = sprintf(Localization().getStringEx("panel.groups_create.failed.msg", "Failed to create group: %s."), [error.text ?? Localization().getStringEx('panel.groups_create.unknown.error.message', 'Unknown error occurred')]); break;
            }
            AppAlert.showDialogResult(context, message);
          }
        }
      });
    }
  }

  //
  // Common
  Widget _buildSectionTitle(String? title, String? description, [bool requiredMark = false]){
    return Container(
      padding: EdgeInsets.only(bottom: 8, top:16),
      child:
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
        Semantics(
          label: title,
          hint: description,
          header: true,
          excludeSemantics: true,
          child:
          RichText(
            text: TextSpan(
              text: title,
              children: [
                TextSpan(
                  text: requiredMark ?  " *" : "",
                  style: TextStyle(color: Styles().colors!.fillColorSecondary, fontSize: 12, fontFamily: Styles().fontFamilies!.extraBold),
                )
              ],
              style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 12, fontFamily: Styles().fontFamilies!.bold),
            ),
          ),
        ),
        description==null? Container():
            Container(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                description,
                semanticsLabel: "",
                style: TextStyle(color: Styles().colors!.textBackground, fontSize: 14, fontFamily: Styles().fontFamilies!.regular),
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
            header: true,
            excludeSemantics: true,
            child:
            Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Image.asset(iconRes, color: Styles().colors!.fillColorSecondary,),
              Expanded(child:
              Container(
                  padding: EdgeInsets.only(left: 14, right: 4),
                  child:Text(
                    title,
                    style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold,),
                  )
              ))
      ],)));
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

  bool get _isManagedGroupAdmin {
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

  bool get _canSave {
    return StringUtils.isNotEmpty(_group?.title) &&
        StringUtils.isNotEmpty(_group?.category) &&
        (!(_group?.authManEnabled ?? false) || (StringUtils.isNotEmpty(_group?.authManGroupName))) &&
        ((_group?.researchProject != true) || !_researchRequiresConsentConfirmation || StringUtils.isNotEmpty(_group?.researchConsentStatement)) &&
        ((_group?.researchProject != true) || (_researchProfileQuestionsCount > 0));
  }

  bool get _loading => _groupCategoeriesLoading;
}
