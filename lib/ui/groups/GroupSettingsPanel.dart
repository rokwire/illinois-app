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

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/groups/GroupAdvancedSettingsPanel.dart';
import 'package:illinois/ui/attributes/ContentAttributesPanel.dart';
import 'package:illinois/ui/research/ResearchProjectProfilePanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/groups/GroupMembershipQuestionsPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupSettingsPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Group? group;
  final GroupStats? groupStats;
  
  GroupSettingsPanel({this.group, this.groupStats});

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
  final _researchConsentStatementController = TextEditingController();
  final _authManGroupNameController = TextEditingController();

  final List<GroupPrivacy>? _groupPrivacyOptions = GroupPrivacy.values;

  bool _nameIsValid = true;
  bool _updating = false;
  bool _deleting = false;
  bool _confirmationProgress = false;
  bool _researchRequiresConsentConfirmation = false;

  Group? _group; // edit settings here until submit

  @override
  void initState() {
    _group = Group.fromOther(widget.group);

    _groupTitleController.text = _group?.title ?? '';
    _groupDescriptionController.text = _group?.description ?? '';
    _researchConsentDetailsController.text = _group?.researchConsentDetails ?? '';
    _researchConsentStatementController.text = StringUtils.isNotEmpty(_group?.researchConsentStatement) ? _group!.researchConsentStatement! : 'I have read and I understand the consent details. I certify that I am 18 years old or older. By clicking the "Request to participate" button, I indicate my willingness to voluntarily take part in this study.';
    _linkController.text = _group?.webURL ?? '';
    _authManGroupNameController.text = _group?.authManGroupName ?? '';

    _researchRequiresConsentConfirmation = StringUtils.isNotEmpty(_group?.researchConsentStatement) ;

    _group?.settings ??= GroupSettingsExt.initialDefaultSettings(group: _group); //Group back compatibility for older groups without settings -> initit with default settings.Not used. The BB return all false by default
    super.initState();
  }

  @override
  void dispose() {
    _groupTitleController.dispose();
    _groupDescriptionController.dispose();
    _researchConsentDetailsController.dispose();
    _researchConsentStatementController.dispose();
    _linkController.dispose();
    _authManGroupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String barTitle = (_group?.researchProject == true) ?
      Localization().getStringEx("panel.groups_settings.label.project.heading", "Project Settings") :
      Localization().getStringEx("panel.groups_settings.label.heading", "Group Settings");

    List<Widget> contentList = <Widget>[
      _buildImageSection(),
      Container(padding: EdgeInsets.symmetric(horizontal: 16), child:
        _buildSectionTitle((_group?.researchProject == true) ? Localization().getStringEx("panel.project_settings.label.heading.general_info", "General project information") : Localization().getStringEx("panel.groups_settings.label.heading.general_info", "General group information"), "info"),
      ),
      _buildNameField(),
      _buildDescriptionField(),
      _buildLinkField(),

      // Container(height: 1, color: Styles().colors!.surfaceAccent,),
      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        _buildSectionTitle(Localization().getStringEx("panel.groups_settings.label.heading.discoverability", "Discoverability"), "search"),
      ),
      _buildAttributesLayout(),
      // Padding(padding: EdgeInsets.only(top: 12), child:
      //   Container(height: 1, color: Styles().colors!.surfaceAccent,),
      // ),
    ];

    if (!_isResearchProject) {
      contentList.addAll(<Widget>[
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
          _buildSectionTitle(Localization().getStringEx("panel.groups_create.label.privacy", "Privacy"), "privacy"),
        ),
        Container(height: 8),
        _buildPrivacyDropDown(),
        _buildHiddenForSearch(),
      ]);

      if (_canViewManagedSettings) {
        contentList.add(_buildAuthManLayout());
      }

      if (!_isAuthManGroup) {
        contentList.add(_buildMembershipLayout());
      }

      //#2685 [USABILITY] Hide group setting "Enable attendance checking" for 4.2
      //contentList.add(Padding(padding: EdgeInsets.only(top: 8), child:
      //  _buildAttendanceLayout(),
      //));

      contentList.add(Padding(padding: EdgeInsets.only(top: 8), child:
        _buildSettingsLayout(),
      ));
    }
    else {
      contentList.addAll(<Widget>[
        // Container(height: 1, color: Styles().colors!.surfaceAccent,),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
          _buildSectionTitle("Research", "settings"),
        ),
        //_buildResearchOptionLayout(),
        _buildResearchConsentDetailsField(),
        // #2626: Hide consent checkbox and edit control.
        // _buildResearchConfirmationLayout(),
        _buildResearchOpenLayout(),
        _buildResearchAudienceLayout(),
        _buildMembershipLayout(),
        // _buildProjectSettingsLayout(),
        _buildSettingsLayout(),
      ]);
    }

    contentList.add(Container(height: 24,  color: Styles().colors!.background,));

    return Scaffold(
      backgroundColor: Styles().colors!.background,
      body: Column(children: <Widget>[
        Expanded( child:
          Container(color: Styles().colors!.background, child:
            CustomScrollView( scrollDirection: Axis.vertical, slivers: <Widget>[
              SliverHeaderBar(title: barTitle),
              SliverList(delegate: SliverChildListDelegate([
                Container(color: Styles().colors!.background, child:
                  Column(children: contentList),
                )
              ]),),
            ],),
          ),
        ),
        _buildButtonsLayout(),
      ],),
    );
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
                    textStyle: _canUpdate ? Styles().textStyles?.getTextStyle("widget.button.title.large.fat") : Styles().textStyles?.getTextStyle("widget.button.disabled.title.large.fat"),
                    borderColor: _canUpdate ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
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
    String? _imageUrl = await GroupAddImageWidget.show(context: context, updateUrl: _group!.imageURL);
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
    String title = (_group?.researchProject == true) ? Localization().getStringEx("panel.project_settings.name.title", "PROJECT NAME") : Localization().getStringEx("panel.groups_settings.name.title", "GROUP NAME");
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
                  value: _groupTitleController.text,
                  excludeSemantics: true,
                  child: TextField(
                    controller: _groupTitleController,
                    enabled: _canUpdate,
                    readOnly: !_canUpdate,
                    onChanged: (name){_onNameChanged(name); setStateIfMounted(() { });},
                    maxLines: 1,
                    decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                    style: Styles().textStyles?.getTextStyle("widget.item.regular.thin")
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
                  Styles().images?.getImage('warning', excludeFromSemantics: true) ?? Container(),
                  Expanded(child:
                  Container(
                      padding: EdgeInsets.only(left: 12, right: 4),
                      child:Text(errorMessage,
                          style: Styles().textStyles?.getTextStyle("widget.item.small.thin"))
                  ))
                ],
              ),
            )
        ));
  }

  //Description
  Widget _buildDescriptionField() {
    String title = (_group?.researchProject == true) ?
      Localization().getStringEx("panel.groups_settings.description.project.title", "SHORT PROJECT DESCRIPTION") :
      Localization().getStringEx("panel.groups_settings.description.group.title", "GROUP DESCRIPTION");
    String? fieldTitle = (_group?.researchProject == true) ?
      Localization().getStringEx("panel.groups_settings.description.project.field", "What’s the purpose of your project? Who should join? What will you do at your events?") :
      Localization().getStringEx("panel.groups_settings.description.group.field", "What’s the purpose of your group? Who should join? What will you do at your events?");
    String? fieldHint = (_group?.researchProject == true) ?
      Localization().getStringEx("panel.groups_settings.description.project.field.hint", "") :
      Localization().getStringEx("panel.groups_settings.description.group.field.hint", "");

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
                value: _groupDescriptionController.text,
                child: TextField(
                  controller: _groupDescriptionController,
                  onChanged: (description){ _group!.description = description;  setStateIfMounted(() {});},
                  maxLines: 8,
                  enabled: _canUpdate,
                  readOnly: !_canUpdate,
                  decoration: InputDecoration(
                    hintText: fieldHint,
                    border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
                  style: Styles().textStyles?.getTextStyle("widget.item.regular.thin")
                )),
          ),
        ],
      ),
    );
  }
  //
  //Link
  Widget _buildLinkField(){
    String labelTitle = _isResearchProject ?
      Localization().getStringEx("panel.groups_settings.project.link.title", "OPTIONAL WEBSITE LINK") :
      Localization().getStringEx("panel.groups_settings.link.title", "WEBSITE LINK");
    String labelHint = _isResearchProject ?
      Localization().getStringEx("panel.groups_settings,project.link.title.hint", "") :
      Localization().getStringEx("panel.groups_settings.link.title.hint","");

    return
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
          Semantics(label:labelTitle,
            hint: labelHint, textField: true, excludeSemantics: true, value:  _group!.webURL,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: 8, top:16),
                    child: Text(
                      labelTitle,
                      style: Styles().textStyles?.getTextStyle("widget.title.small.fat.spaced")
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
                        style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"),
                        onChanged: (link){ _group!.webURL = link; setStateIfMounted(() {});},
                        maxLines: 1,
                      ),
                    ),
                  ),
                ]
            )
        ),
        Semantics(
            label: Localization().getStringEx("panel.groups_settings.link.button.confirm.link", 'Confirm website URL'),
            hint: Localization().getStringEx("panel.groups_settings.link.button.confirm.link.hint", ""),
            button: true, excludeSemantics: true,
            child: GestureDetector(
              onTap: _onTapConfirmLinkUrl,
              child: Text(
                Localization().getStringEx("panel.groups_settings.link.button.confirm.link.title", 'Confirm URL'),
                style: Styles().textStyles?.getTextStyle("widget.button.title.medium.underline")
              ),
            )
        ),
        Container(height: 15)
    ],));
  }

  void _onTapConfirmLinkUrl() {
    Analytics().logSelect(target: "Confirm Website url");
    if (_linkController.text.isNotEmpty) {
      Uri? uri = Uri.tryParse(_linkController.text);
      if (uri != null) {
        Uri? fixedUri = UrlUtils.fixUri(uri);
        if (fixedUri != null) {
          _linkController.text = fixedUri.toString();
          uri = fixedUri;
        }
        launchUrl(uri, mode: Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault);
      }
    }
  }

  //
  //Attributes
  Widget _buildAttributesLayout() {
    return (Groups().contentAttributes?.isNotEmpty ?? false) ? Container(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(flex: 5, child:
            _buildInfoHeader(
              Localization().getStringEx("panel.groups_create.attributes.title", "ATTRIBUTES"),
              _isResearchProject?
                Localization().getStringEx("panel.groups_create.attributes.project_description", "Attributes help you provide more information."):
                Localization().getStringEx("panel.groups_create.attributes.description", "Attributes help people understand more about your group."),
            )
          ),
          Container(width: 8),
          Expanded(flex: 2, child:
            RoundedButton(
              label: Localization().getStringEx("panel.groups_create.button.attributes.title", "Edit"),
              hint: Localization().getStringEx("panel.groups_create.button.attributes.hint", ""),
              textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
              backgroundColor: Styles().colors!.white,
              borderColor: Styles().colors!.fillColorSecondary,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onTap: _onTapAttributes,
            )
          )
        ]),
        ... _constructAttributesContent()
      ])
    ) : Container();
  }

  List<Widget> _constructAttributesContent() {
    List<Widget> attributesList = <Widget>[];
    Map<String, dynamic>? groupAttributes = _group?.attributes;
    ContentAttributes? contentAttributes = Groups().contentAttributes;
    List<ContentAttribute>? attributes = contentAttributes?.attributes;
    if ((groupAttributes != null) && (contentAttributes != null) && (attributes != null)) {
      for (ContentAttribute attribute in attributes) {
        List<String>? displayAttributeValues = attribute.displaySelectedLabelsFromSelection(groupAttributes, complete: true);
        if ((displayAttributeValues != null) && displayAttributeValues.isNotEmpty) {
          attributesList.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("${attribute.displayTitle}: ", overflow: TextOverflow.ellipsis, maxLines: 1, style:
              Styles().textStyles?.getTextStyle("widget.card.detail.small.fat")
            ),
            Expanded(child:
              Text(displayAttributeValues.join(', '), /*overflow: TextOverflow.ellipsis, maxLines: 1,*/ style:
                Styles().textStyles?.getTextStyle("widget.card.detail.small.regular")
              ),
            ),
          ],),);
        }
      }
    }
    return attributesList;
  }

  void _onTapAttributes() {
    Analytics().logSelect(target: "Attributes");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ContentAttributesPanel(
      title: (_group?.researchProject == true) ?
        Localization().getStringEx('panel.project.attributes.attributes.header.title', 'Project Attributes') :
        Localization().getStringEx('panel.group.attributes.attributes.header.title', 'Group Attributes'),
      description: (_group?.researchProject == true) ?
        Localization().getStringEx('panel.project.attributes.attributes.header.description', 'Choose one or more attributes that help describe this project.') :
        Localization().getStringEx('panel.group.attributes.attributes.header.description', 'Choose one or more attributes that help describe this group.'),
      contentAttributes: Groups().contentAttributes,
      selection: _group?.attributes,
      sortType: ContentAttributesSortType.alphabetical,
    ))).then((selection) {
      if ((selection != null) && mounted) {
        setState(() {
          _group?.attributes = selection;
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
                style: Styles().textStyles?.getTextStyle("widget.item.small.thin.spaced"),
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
                          Localization().getStringEx("panel.groups.common.private.search.hidden.description", "A hidden group is unsearchable."),
                          style: Styles().textStyles?.getTextStyle("widget.item.small.thin.spaced"))))
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
    String sectionTitle = _isResearchProject ?
      Localization().getStringEx("panel.project_settings.membership.title", "Participation") :
      Localization().getStringEx("panel.groups_settings.membership.title", "Membership");
    String buttonTitle = _isResearchProject ?
      Localization().getStringEx("panel.project_settings.membership.button.question.title", "Recruitment Questions") :
      Localization().getStringEx("panel.groups_settings.membership.button.question.title","Membership Questions");
    int questionsCount = _group?.questions?.length ?? 0;
    String questionsDescription = (0 < questionsCount) ?
      sprintf(Localization().getStringEx("panel.groups_settings.tags.label.question.format", "%s Question(s)"), [questionsCount.toString()]) :
      Localization().getStringEx("panel.groups_settings.membership.button.question.description.default", "No question");

    return
      Container(
        color: Styles().colors!.background,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column( children: <Widget>[
          _buildSectionTitle(sectionTitle, "person-circle"),
          Container(height: 12,),
          Semantics(
            explicitChildNodes: true,
            child:_buildMembershipButton(
              title: buttonTitle,
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
                        style: Styles().textStyles?.getTextStyle("widget.title.regular.fat")
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: Styles().images?.getImage('chevron-right-bold', excludeFromSemantics: true),
                    ),
                ]),
                Container(
                  padding: EdgeInsets.only(right: 42,top: 4),
                  child: Text(description,
                    style: Styles().textStyles?.getTextStyle("widget.detail.light.regular")
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
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMembershipQuestionsPanel(group: _group,))).then((_){
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
            title: "Currently recruiting participants",
            value: _group?.researchOpen == true,
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

  Widget _buildResearchConsentDetailsField() {
    String? title = "PROJECT DETAILS";
    String? fieldTitle = "PROJECT DETAILS FIELD";
    String? fieldHint = "";

    return Visibility(visible: _isResearchProject, child:
      Container(padding: EdgeInsets.symmetric(horizontal: 16), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          _buildInfoHeader(title, null, padding: EdgeInsets.only(bottom: 6, top: 12)),
          Container(decoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1), color: Styles().colors!.white), child:
            Row(children: [
              Expanded(child:
                  Semantics(label: fieldTitle, hint: fieldHint, textField: true, excludeSemantics: true, value: _researchConsentDetailsController.text, child:
                    TextField(
                        controller: _researchConsentDetailsController,
                        maxLines: 15,
                        decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
                        style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"),
                        onChanged: (text){ _group?.researchConsentDetails = text; setStateIfMounted(() { });},
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

  // #2626: Hide consent checkbox and edit control.
  /* Widget _buildResearchConfirmationLayout() {
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
            _buildInfoHeader(title, null, padding: EdgeInsets.only(bottom: 6, top: 12)),
            Container(decoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1), color: Styles().colors!.white), child:
              Row(children: [
                Expanded(child:
                  Semantics(label: fieldTitle, hint: fieldHint, textField: true, excludeSemantics: true, child:
                    TextField(
                        controller: _researchConsentStatementController,
                        maxLines: 5,
                        decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
                        style: TextStyle(color: Styles().colors!.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
                    )
                  ),
                )
              ])
            ),
          ],),
        ),
      ]),
    );
  }

  void _onTapResearchConfirmation() {
    if (mounted) {
      setState(() {
        _researchRequiresConsentConfirmation = !_researchRequiresConsentConfirmation;
      });
    }
  }*/

  Widget _buildResearchAudienceLayout() {
    int questionsCount = _researchProfileQuestionsCount;
    String questionsDescription = (0 < questionsCount) ?
      sprintf(Localization().getStringEx("panel.groups_settings.tags.label.question.format","%s Question(s)"), [questionsCount.toString()]) :
      Localization().getStringEx("panel.groups_settings.audience.button.question.description.default","All Potential Participants");

    return Container(
      color: Styles().colors!.background,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: <Widget>[
        _buildSectionTitle(Localization().getStringEx("panel.groups_create.audience.section.title", 'Audience'), "person"),
        Container(height: 12,),
        Semantics(
            explicitChildNodes: true,
            child: _buildMembershipButton(
                title: Localization().getStringEx("panel.groups_create.target.audience.title", "Target Audience"),
                description: questionsDescription,
                onTap: _onTapResearchProfile)),
      ]),
    );
  }

  int get _researchProfileQuestionsCount {
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
          _buildSectionTitle(Localization().getStringEx("panel.groups_settings.authman.section.title", "University managed membership"), "person-circle"),
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
                            style: Styles().textStyles?.getTextStyle("widget.message.regular.fat.accent"))),
                        GestureDetector(
                            onTap: _onTapAuthMan,
                            child: Padding(
                                padding: EdgeInsets.only(left: 10), child: Styles().images?.getImage(isAuthManGroup ? 'toggle-on' : 'toggle-off')))
                      ])
                    ])),
                Visibility(
                    visible: isAuthManGroup,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        _buildInfoHeader(Localization().getStringEx("panel.groups_settings.authman.group.name.label", "Membership name"), null),
                        Padding(padding: EdgeInsets.only(top: 14), child: Text('*', style: Styles().textStyles?.getTextStyle("widget.label.medium.fat")))
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
                            style: Styles().textStyles?.getTextStyle("widget.item.regular.thin")
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
           Row(children: [
            Expanded(
              child: RoundedButton(
                label: Localization().getStringEx("panel.groups_settings.button.update.title", "Update Settings"),
                textStyle: _canUpdate ? Styles().textStyles?.getTextStyle("widget.button.title.large.fat") : Styles().textStyles?.getTextStyle("widget.button.disabled.title.large.fat"),
                backgroundColor: Colors.white,
                borderColor: _canUpdate ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
                progress: _updating,
                enabled: _canUpdate,
                onTap: _onUpdateTap,
              ),
            ),
            Container(width: 16,),
            Expanded(
              child: RoundedButton(
                label: _isResearchProject ?
                  Localization().getStringEx("panel.project_settings.button.delete.title", "Delete this Project") : //TBD localize
                  Localization().getStringEx("panel.groups_settings.button.delete.title", "Delete this Group"),  //TBD localize
                textStyle: _canUpdate ? Styles().textStyles?.getTextStyle("widget.button.title.large.fat") : Styles().textStyles?.getTextStyle("widget.button.disabled.title.large.fat"),
                backgroundColor: Colors.white,
                borderColor: _canUpdate ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
                progress: _deleting,
                enabled: _canUpdate,
                onTap: _onDeleteTap,
              ),
            ),
          ],)
        ],),
      )
      ,),);
  }

  void _onUpdateTap() {
    if (_updating || !_canUpdate) {
      return;
    }

    if ((_group?.researchProject == true) && _researchRequiresConsentConfirmation && _researchConsentStatementController.text.isEmpty) {
      AppAlert.showDialogResult(context, 'Please enter participant consent text.');
      return;
    }
    else {
      _group?.researchConsentStatement = ((_group?.researchProject == true) && _researchRequiresConsentConfirmation && _researchConsentStatementController.text.isNotEmpty) ? _researchConsentStatementController.text : null;

    }

    Analytics().logSelect(target: 'Update Settings');
    setState(() {
      _updating = true;
    });

    // control research groups options
    if (_group?.researchProject == true) {
      _group?.privacy = GroupPrivacy.public;
      _group?.hiddenForSearch = false;
      _group?.authManEnabled = false;
      _group?.authManGroupName = null;
      _group!.attendanceGroup = false;
      //Unlocked Advanced setting
      // _group?.canJoinAutomatically = false;
      // _group?.onlyAdminsCanCreatePolls = true;
    }
    else {
      _group?.researchOpen = null;
      _group?.researchConsentDetails = null;
      _group?.researchConsentStatement = null;
      _group?.researchProfile = null;
    }

    // if the group is not authman then clear authman group name
    if (_group?.authManEnabled != true) {
      _group!.authManGroupName = null;
    }

    // if the group is not research or if it does not require confirmation then clear consent statement text
    if ((_group?.researchProject != true) || (_researchRequiresConsentConfirmation != true)) {
      _group?.researchConsentStatement = null;
    }

    Groups().updateGroup(_group).then((GroupError? error){
      if (mounted) {
        setState(() {
          _updating = false;
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

  void _onDeleteTap() {
    Analytics().logSelect(target: "Delete this group", attributes: _group?.analyticsAttributes);

    if (!_deleting) {
      int membersCount = widget.groupStats?.activeMembersCount ?? 0;
      String? confirmMsg = (membersCount > 1)
          ? sprintf(Localization().getStringEx("panel.group_detail.members_count.group.delete.confirm.msg", "This group has %d members. Are you sure you want to delete this group?"), [membersCount])
          : Localization().getStringEx("panel.group_detail.group.delete.confirm.msg", "Are you sure you want to delete this group?");

      showDialog(context: context,builder: (context) => _buildConfirmationDialog(
        confirmationTextMsg: confirmMsg,
        positiveButtonLabel: Localization().getStringEx('dialog.yes.title', 'Yes'),
        negativeButtonLabel: Localization().getStringEx('dialog.no.title', 'No'),
        onPositiveTap: _deleteGroup));
    }
  }

  void _deleteGroup() {

    Analytics().logSelect(target: 'Deleting group');

    if (_deleting) {
      return;
    }

    setStateIfMounted(() {
      _deleting = _confirmationProgress = true;
    });
    
    Groups().deleteGroup(widget.group?.id).then((bool success){
      setStateIfMounted(() {
        _deleting = _confirmationProgress = false;
      });
      Navigator.of(context).pop(); // Pop dialog
      if (success == true) {
        Navigator.of(context).pop(); // Pop to settings
        Navigator.of(context).pop(); // Pop group detail
      }
      else {
        AppAlert.showDialogResult(context, _isResearchProject ?
          Localization().getStringEx('panel.project_detail.group.delete.failed.msg', 'Failed to delete project.') :
          Localization().getStringEx('panel.group_detail.group.delete.failed.msg', 'Failed to delete group.')
        );
      }
    });
  }
  //

  
  // Attendance
  /*Widget _buildAttendanceLayout() {
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
  }*/

  //Settings
  Widget _buildSettingsLayout() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child:  RibbonButton(
            label: Localization().getStringEx('panel.groups_settings..button.advanced_settings.title', 'Advanced Settings'), //Localize
            hint: Localization().getStringEx('panel.groups_settings..button.advanced_settings..hint', ''),
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
            borderRadius: BorderRadius.circular(4),
            onTap: (){
              Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupAdvancedSettingsPanel(group: _group,))).then((_){
                if(mounted){
                  setState(() {

                  });
                }
              });
            }),
    );
  }

  //ProjectSettings
/*  Widget _buildProjectSettingsLayout() {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      EnabledToggleButton(
        label: Localization().getStringEx('panel.groups_settings.auto_join.project.enabled.label', 'Does not require my screening of potential participants'),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        enabled: true,
        toggled: _group?.canJoinAutomatically == true,
        onTap: _onTapJoinAutomatically
      )
    );
  }

  void _onTapJoinAutomatically() {
    Analytics().logSelect(target: "Does not require my screening of potential participants");
    setState(() {
      _group?.canJoinAutomatically = (_group?.canJoinAutomatically != true);
    });
  }*/

  // Common
  Widget _buildInfoHeader(String title, String? description, { EdgeInsetsGeometry padding = const EdgeInsets.only(bottom: 8, top: 24)}){
    return Container(padding: padding, child:
      Semantics(container: true, child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Semantics(label: title, header: true, excludeSemantics: true, child:
            Text(title, style: Styles().textStyles?.getTextStyle("widget.title.tiny")),
          ),
          ((description != null) && description.isNotEmpty) ? Container(padding: EdgeInsets.only(top: 2), child:
              Text(description, style: Styles().textStyles?.getTextStyle("widget.item.small.thin")),
            ) : Container(),
        ],),
      )
    );
  }

  Widget _buildSectionTitle(String title, String iconKey){
    return Container(
        padding: EdgeInsets.only(top:24),
        child:
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
              Container(
                padding: EdgeInsets.only(right: 10),
                child: Styles().images?.getImage(iconKey, excludeFromSemantics: true)
              ),
            Expanded(child:
              Semantics(
                label: title,
                header: true,
                excludeSemantics: true,
                child:
                Text(
                  title,
                  style: Styles().textStyles?.getTextStyle("widget.title.regular.fat")
                ),
              ),
            )
          ],)
    );
  }

  Widget _buildSwitch({String? title, bool? value, bool enabled = true, void Function()? onTap}) {
    return Container(
      child: Semantics(
        label: title,
        value: value == true?  Localization().getStringEx("toggle_button.status.checked", "checked",) : Localization().getStringEx("toggle_button.status.unchecked", "unchecked"),
        button: true,
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
                      style:enabled ? Styles().textStyles?.getTextStyle("widget.button.title.enabled") :  Styles().textStyles?.getTextStyle("widget.button.title.disabled"), semanticsLabel: "",)),
              GestureDetector(
                  onTap: (enabled && (onTap != null)) ?
                    (){
                      onTap();
                      AppSemantics.announceCheckBoxStateChange(context,  /*reversed value*/!(value == true), title);
                  } : (){},
                  child: Padding(padding: EdgeInsets.only(left: 10), child: Styles().images?.getImage(value ?? false ? 'toggle-on' : 'toggle-off')))
            ])
          ])),
    ));
  }

  Widget _buildConfirmationDialog({String? confirmationTextMsg,
    
    String? positiveButtonLabel,
    int positiveButtonFlex = 1,
    Function? onPositiveTap,
    
    String? negativeButtonLabel,
    int negativeButtonFlex = 1,
    
    int leftAreaFlex = 0,
  }) {
    return Dialog(
        backgroundColor: Styles().colors!.fillColorPrimary,
        child: StatefulBuilder(builder: (context, setStateEx) {
          return Padding(
              padding: EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Padding(
                    padding: EdgeInsets.symmetric(vertical: 26),
                    child: Text(confirmationTextMsg!,
                        textAlign: TextAlign.left, style:  Styles().textStyles?.getTextStyle('widget.dialog.message.medium'))),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                  Expanded(flex: leftAreaFlex, child: Container()),
                  Expanded(flex: negativeButtonFlex, child: RoundedButton(
                      label: StringUtils.ensureNotEmpty(negativeButtonLabel, defaultValue: Localization().getStringEx("panel.group_detail.button.back.title", "Back")),
                      textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.thin"),
                      borderColor: Styles().colors!.white,
                      backgroundColor: Styles().colors!.white,
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      onTap: () {
                        Analytics().logAlert(text: confirmationTextMsg, selection: negativeButtonLabel);
                        Navigator.pop(context);
                      }),),
                  Container(width: 16),
                  Expanded(flex: positiveButtonFlex, child: RoundedButton(
                    label: positiveButtonLabel ?? '',
                    textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                    borderColor: Styles().colors!.white,
                    backgroundColor: Styles().colors!.white,
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    progress: _confirmationProgress,
                    onTap: () {
                      Analytics().logAlert(text: confirmationTextMsg, selection: positiveButtonLabel);
                      onPositiveTap!();
                    },
                  ),),
                ])
              ]));
        }));
  }

  void _onNameChanged(String name) {
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

