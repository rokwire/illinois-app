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
import 'dart:math';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/groups/GroupAdvancedSettingsPanel.dart';
import 'package:illinois/ui/attributes/ContentAttributesPanel.dart';
import 'package:illinois/ui/groups/GroupsContentSettingsPanel.dart';
import 'package:illinois/ui/research/ResearchProjectProfilePanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:illinois/ui/groups/GroupMembershipQuestionsPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/accessible_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupCreatePanel extends StatefulWidget with AnalyticsInfo {
  final Group? group;

  GroupCreatePanel({Key? key, this.group}) : super(key: key);

  @override
  _GroupCreatePanelState createState() => _GroupCreatePanelState();

  @override
  AnalyticsFeature? get analyticsFeature => (group?.researchProject == true) ? AnalyticsFeature.ResearchProject : AnalyticsFeature.Groups;
}

class _GroupCreatePanelState extends State<GroupCreatePanel> {
  final _groupNetIdsController = TextEditingController();
  final _groupTitleController = TextEditingController();
  final _groupDescriptionController = TextEditingController();
  final _linkController = TextEditingController();
  final _researchConsentDetailsController = TextEditingController();
  final _researchConsentStatementController = TextEditingController();
  final _authManGroupNameController = TextEditingController();

  Group? _group;

  GroupMemberStatus _selectedMembersStatus = GroupMemberStatus.admin;
  double? _membersStatusDropdownItemsWidth;

  final List<GroupPrivacy> _groupPrivacyOptions = GroupPrivacy.values;

  bool _creating = false;
  bool _researchRequiresConsentConfirmation = false;

  @override
  void initState() {
    _initGroup();
    _initResearchConsentDetails();
    super.initState();
  }

  @override
  void dispose() {
    _groupNetIdsController.dispose();
    _groupTitleController.dispose();
    _groupDescriptionController.dispose();
    _linkController.dispose();
    _researchConsentDetailsController.dispose();
    _researchConsentStatementController.dispose();
    _authManGroupNameController.dispose();
    super.dispose();
  }

  //Init

  void _initGroup(){
    _group = (widget.group != null) ? Group.fromOther(widget.group) : Group();
    _group?.onlyAdminsCanCreatePolls ??= true;
    if (_group?.researchProject == true)
      _group?.canJoinAutomatically ??= true;
    _group?.researchOpen ??= (_group?.researchProject == true) ? true : null;
    _group?.privacy ??= (_group?.researchProject == true) ? GroupPrivacy.public : GroupPrivacy.private;
    _group?.settings ??= GroupSettingsExt.initialDefaultSettings(group: _group);

    _groupTitleController.text = _group?.title ?? '';
    _groupDescriptionController.text = _group?.description ?? '';
    _linkController.text = _group?.webURL ?? '';
    _researchConsentDetailsController.text = _group?.researchConsentDetails ?? '';
    _authManGroupNameController.text = _group?.authManGroupName ?? '';

    // #2550: we need consent checkbox selected by default
    // #2626: Hide consent checkbox and edit control. Default it to false...
    _researchRequiresConsentConfirmation = StringUtils.isNotEmpty(_group?.researchConsentStatement);

    if (StringUtils.isNotEmpty(_group?.researchConsentStatement)) {
      _researchConsentStatementController.text = _group!.researchConsentStatement!;
    }
    else {
      _group?.researchConsentStatement = _researchConsentStatementController.text = 'I have read and I understand the consent details. I certify that I am 18 years old or older. By clicking the "Request to participate" button, I indicate my willingness to voluntarily take part in this study.';
    }
  }

  Future<void> _initResearchConsentDetails() async {
    if (_group?.researchProject == true) {
      const String researchConsentCategory = 'research_consent';
      List<String> contentCategories = <String>[researchConsentCategory];

      String? currentLocale = Localization().currentLocale?.languageCode;
      String? currentLocaleCategory = StringUtils.isNotEmpty(currentLocale) ?
        "${researchConsentCategory}_$currentLocale" : null;
      if (currentLocaleCategory != null) {
        contentCategories.add(currentLocaleCategory);
      }

      String? defaultLocale = Localization().defaultLocale?.languageCode;
      String? defaultLocaleCategory = (StringUtils.isNotEmpty(defaultLocale) && (defaultLocale != currentLocale)) ?
        "${researchConsentCategory}_$defaultLocale" : null;
      if (defaultLocaleCategory != null) {
        contentCategories.add(defaultLocaleCategory);
      }

      Map<String, dynamic>? contentItems = await Content().loadContentItems(contentCategories);

      String? consentDetails = (contentItems != null) ? (
          JsonUtils.stringValue(contentItems[currentLocaleCategory]) ?? 
          JsonUtils.stringValue(contentItems[defaultLocaleCategory]) ??
          JsonUtils.stringValue(contentItems[researchConsentCategory])
      ) : null;

      if (consentDetails != null) {
        _group?.researchConsentDetails = _researchConsentDetailsController.text = consentDetails;
      }
    }
  }

  //

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Styles().colors.background, body:
      Column(children: <Widget>[
        Expanded(child:
          _loading ? _buildLoading() : _buildContent()
        ),
        _buildButtonsLayout()
      ]),
    );
  }

  Widget _buildContent() {
    String barTitle = (_group?.researchProject == true) ?
      Localization().getStringEx("panel.groups_create.label.project.heading", "Create Research Project") :
      Localization().getStringEx("panel.groups_create.label.group.heading", "Create a Group");

    List<Widget> contentLayout = <Widget>[
      _buildImageSection(),
      _buildAdminSettingsSection(),
      _buildNameField(),
      _buildDescriptionField(),
    ];

    if (!_isResearchProject) {
      contentLayout.addAll(<Widget>[

        _buildLinkField(),

        Container(height: 16),
        _buildTitle(Localization().getStringEx("panel.groups_create.label.discoverability", "Discoverability"), "search"),
        _buildAttributesLayout(),
        Container(height: 8),
        Container(height: 16),
        _buildTitle(Localization().getStringEx("panel.groups_create.label.privacy", "Privacy"), "privacy"),
        Container(height: 8),
        
        _buildPrivacyDropDown(),
        _buildHiddenForSearch(),
        _buildAdministrative(),
      ]);

      if (_isManagedGroupAdmin) {
        contentLayout.addAll(<Widget>[
          _buildTitle(Localization().getStringEx("panel.groups_create.authman.section.title", "University managed membership"), "person"),
          _buildAuthManLayout(),
        ]);
      }

      if (!_isAuthManGroup) {
        contentLayout.addAll(<Widget>[
          Container(height: 20),
          _buildTitle(Localization().getStringEx("panel.groups_create.membership.section.title", "Membership"), "person-circle"),
          _buildMembershipLayout(),
        ]);
      }

      //#2685 [USABILITY] Hide group setting "Enable attendance checking" for 4.2
      //contentLayout.add(
      //  Padding(padding: EdgeInsets.only(top: 8), child:
      //    _buildAttendanceLayout(),
      //  )
      //);
      contentLayout.add(
          Padding(padding: EdgeInsets.only(top: 8), child:
            _buildContentSectionsLayout(),
          )
      );

      contentLayout.add(
        Padding(padding: EdgeInsets.only(top: 8), child:
          _buildSettingsLayout(),
        )
      );
    }
    else {
      contentLayout.addAll(<Widget>[
        //Padding(padding: EdgeInsets.symmetric(vertical: 20), child:
        //  Container(height: 1, color: Styles().colors.surfaceAccent,),
        //),
        //_buildTitle("Research", "images/icon-gear.png"),
        //_buildResearchOptionLayout(),
        //_buildResearchOpenLayout(),
        //_buildResearchConsentDetailsField(),
        // #2626: Hide consent checkbox and edit control.
        // _buildResearchConfirmationLayout(),
        _buildLinkField(),

        Container(height: 16),
        _buildTitle(Localization().getStringEx("panel.groups_create.label.discoverability", "Discoverability"), "search"),
        _buildAttributesLayout(),
        Container(height: 8),

        Container(height: 16),
        _buildTitle(Localization().getStringEx("panel.groups_create.audience.section.title", 'Audience'), "person"),
        _buildResearchAudienceLayout(),
        Container(height: 8),

        Container(height: 20),
        _buildTitle(Localization().getStringEx("panel.groups_create.participation.section.title", 'Participation'), "person-circle"),
        _buildMembershipLayout(),
        // _buildProjectSettingsLayout(),
        _buildSettingsLayout(),
      ]);
    }

    contentLayout.add(Container(height: 40));
    
    return Container(color: Colors.white, child:
      CustomScrollView(scrollDirection: Axis.vertical, slivers: <Widget>[
        SliverHeaderBar(title: barTitle,),
        SliverList(delegate: SliverChildListDelegate([
          Container(color: Styles().colors.background, child:
            Column(children: contentLayout),
          )
        ]),),
      ],),
    );
  }

  Widget _buildLoading() {
    return Center(child:
      Container(
        child: Align(alignment: Alignment.center,
          child: SizedBox(height: 24, width: 24,
              child: Semantics(label: "Loading." ,container: true, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorPrimary), ))
          ),
        ),
      ),
    );
  }

  //Image
  Widget _buildImageSection() {
    final double _imageHeight = 200;
    String? url = _group?.imageURL;
    String buttonLabel =  StringUtils.isEmpty(url) ? Localization().getStringEx("", "Add Cover Image") : Localization().getStringEx("", "Edit Cover Image");
    return Semantics(container: true,  child: Container(
        height: _imageHeight,
        color: Styles().colors.background,
        child: Stack(alignment: Alignment.bottomCenter, children: <Widget>[
          StringUtils.isNotEmpty(url)
              ? Positioned.fill(child: AccessibleImageHolder(child:
                  ModalImageHolder(child:
                    Image.network(_group!.imageURL!, excludeFromSemantics: true, fit: BoxFit.cover, headers: Config().networkAuthHeaders))))
              : Container(),
          CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.fillColorSecondaryTransparent05, horzDir: TriangleHorzDirection.leftToRight), child: Container(height: 53)),
          CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.background), child: Container(height: 30)),
          Container(
              height: _imageHeight,
              child: Center(
                  child: Semantics(
                      label: buttonLabel,
                      hint: Localization().getStringEx("panel.groups_settings.add_image.hint", ""),
                      button: true,
                      excludeSemantics: true,
                      child: RoundedButton(
                          label: buttonLabel,
                          textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                          onTap: _onTapAddImage,
                          contentWeight: 0.8,
                    ))))
        ])));
  }

  void _onTapAddImage() async {
    Analytics().logSelect(target: "Add Image");
    ImagesResult? result = await GroupAddImageWidget.show(context: context, url: _group!.imageURL).then((result) => result);
    if (result?.succeeded == true) {
      setStateIfMounted(() {
        _group!.imageURL = result?.imageUrl;
      });
      Log.d("Image Url: ${result?.imageUrl}");
    }
  }

  //Name
  Widget _buildNameField() {
    String? title = (_group?.researchProject == true) ? "NAME YOUR PROJECT" : Localization().getStringEx("panel.groups_create.name.title", "NAME YOUR GROUP");
    String? fieldTitle = Localization().getStringEx("panel.groups_create.name.field", "NAME FIELD");
    String? fieldHint = Localization().getStringEx("panel.groups_create.name.field.hint", "");

    return Container(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        GroupSectionTitle(title: title, requiredMark: true),
          TextField(
            controller: _groupTitleController,
            onChanged: (text) => setState((){_group?.title = text;}) ,
            maxLines: 1,
            decoration: _textFieldDecorationEx(label: AppSemantics.textFieldSemanticsLabel(label: fieldTitle, hint: fieldHint)),
            style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
          )
        ],
      ),

    );
  }

  // InputDecoration get _textFieldDecoration => _textFieldDecorationEx();

  InputDecoration _textFieldDecorationEx({Widget? label, String? hintText}) => InputDecoration(
    label: label, hintText: hintText,
    fillColor: Styles().colors.surface, filled: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Styles().colors.fillColorPrimary, width: 1),
      //borderRadius: BorderRadius.circular(0)
    ),
  );

  //Description
  //Name
  Widget _buildDescriptionField() {
    String? title = (_group?.researchProject == true) ?
      Localization().getStringEx("panel.groups_create.description.project.title", "SHORT DESCRIPTION") :
      Localization().getStringEx("panel.groups_create.description.group.title", "DESCRIPTION");
    String? description = (_group?.researchProject == true) ?
      Localization().getStringEx("panel.groups_create.description.project.description", "What’s the purpose of your project? Who should join? What will participation involve?") :
      Localization().getStringEx("panel.groups_create.description.group.description", "What’s the purpose of your group? Who should join? What will you do at your events?");
    String? fieldTitle = (_group?.researchProject == true) ?
      Localization().getStringEx("panel.groups_create.description.project.field", "SHORT DESCRIPTION FIELD") :
      Localization().getStringEx("panel.groups_create.description.group.field", "DESCRIPTION FIELD");
    String? fieldHint = (_group?.researchProject == true) ?
      Localization().getStringEx("panel.groups_create.description.project.field.hint", "") :
      Localization().getStringEx("panel.groups_create.description.group.field.hint", "");

    return Container(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        GroupSectionTitle(title: title, description: description),
        //Container(height: 5,),
        TextField(
          controller: _groupDescriptionController,
          onChanged: (text) {_group?.description = text; setStateIfMounted(() { });},
          maxLines: 5,
          decoration: _textFieldDecorationEx(label: AppSemantics.textFieldSemanticsLabel(label: fieldTitle, hint: fieldHint)),
          style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
        ),
      ],),
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

    return Container(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column( crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Padding(padding: EdgeInsets.only(bottom: 8, top: 24), child:
            Text(labelTitle, style: Styles().textStyles.getTextStyle("widget.title.tiny.fat")),
          ),
          Padding(padding: EdgeInsets.only(bottom: 15), child:
            TextField(
              controller: _linkController,
              decoration: _textFieldDecorationEx(
                  hintText:  Localization().getStringEx("panel.groups_settings.link.hint", "Add URL"),
                  label: AppSemantics.textFieldSemanticsLabel(label: labelTitle, hint: labelHint),
              ),
              style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
              onChanged: (link){ _group!.webURL = link; setStateIfMounted(() {});},
              maxLines: 1,
            ),
          ),
        ]),
        Semantics(
          label:Localization().getStringEx("panel.groups_settings.link.button.confirm.link",'Confirm website URL'),
          hint: Localization().getStringEx("panel.groups_settings.link.button.confirm.link.hint",""), button: true, excludeSemantics: true,
          child: GestureDetector( onTap: _onTapConfirmLinkUrl, child:
            Text(Localization().getStringEx("panel.groups_settings.link.button.confirm.link.title",'Confirm URL'), style: Styles().textStyles.getTextStyle("widget.button.title.medium.underline")),
          )
        ),
        Container(height: 15)
      ],)
    );
  }

  void _onTapConfirmLinkUrl() {
    Analytics().logSelect(target: "Confirm Website url");
    if (_linkController.text.isNotEmpty) {
      Uri? uri = Uri.tryParse(_linkController.text);
      if (uri != null) {
        Uri? fixedUri = uri.fix();
        if (fixedUri != null) {
          _linkController.text = fixedUri.toString();
          uri = fixedUri;
        }
        launchUrl(uri, mode: Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault);
      }
    }
  }

  //
  //Research Description
  /*Widget _buildResearchConsentDetailsField() {
    String? title = "PROJECT DETAILS";
    String? fieldTitle = "PROJECT DETAILS FIELD";
    String? fieldHint = "";

    return Visibility(visible: _isResearchProject, child:
      Container(padding: EdgeInsets.symmetric(horizontal: 16), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          GroupSectionTitle(title: title),
          Container(decoration: BoxDecoration(border: Border.all(color: Styles().colors.fillColorPrimary, width: 1), color: Styles().colors.white), child:
            Row(children: [
              Expanded(child:
                Semantics(label: fieldTitle, hint: fieldHint, textField: true, excludeSemantics: true, value: _researchConsentDetailsController.text, child:
                  TextField(
                      controller: _researchConsentDetailsController,
                      maxLines: 15,
                      decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
                      style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
                      onChanged: (text){ _group?.researchConsentDetails = text; setStateIfMounted(() { });},
                  )
                ),
              )
            ])
          ),
        ],),
      ),
    );
  }*/
  //
  // Research Confirmation
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
            GroupSectionTitle(title: title),
            Container(decoration: BoxDecoration(border: Border.all(color: Styles().colors.fillColorPrimary, width: 1), color: Styles().colors.white), child:
              Row(children: [
                Expanded(child:
                  Semantics(label: fieldTitle, hint: fieldHint, textField: true, excludeSemantics: true, child:
                    TextField(
                        controller: _researchConsentStatementController,
                        maxLines: 5,
                        decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
                        style: TextStyle(color: Styles().colors.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies.regular),
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
  }*/

  //Content Sections
  Widget _buildContentSectionsLayout(){
    return Container(
      color: Styles().colors.background,
      padding: EdgeInsets.only(left: 16, right: 16,),
      child: Column(children: <Widget>[
        Semantics(
            explicitChildNodes: true,
            child: _buildSettingButton(
                title: Localization().getStringEx("", "Group Content"), //TBD localize
                description: _isResearchProject?
                Localization().getStringEx("", "Customize your project content type(s) and the order"):
                Localization().getStringEx("", "Customize your group content type(s) and the order"),
                onTap: () =>
                    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupContentSettingsPanel(group: _group,)))
            )),
      ]),
    );
  }

  //
  //Attributes
  Widget _buildAttributesLayout() {
    return (_contentAttributes?.isNotEmpty ?? false) ? Container(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(flex: 5, child:
            GroupSectionTitle(
              title: Localization().getStringEx("panel.groups_create.attributes.title", "ATTRIBUTES"),
              description: _isResearchProject?
                Localization().getStringEx("panel.groups_create.attributes.project_description", "Attributes help you provide more information."):
                Localization().getStringEx("panel.groups_create.attributes.description", "Attributes help people understand more about your group."),
              requiredMark: (!_isResearchProject) && (_contentAttributes?.hasRequired(contentAttributeRequirementsFunctionalScopeCreate) ?? false),  //can we remove the * at the end of the label "Attributes" as it does not work here. //If you decide to fix this and keep the * then change the description text from...
            )
          ),
          Container(width: 8),
          Expanded(flex: 2, child:
            RoundedButton(
              label: Localization().getStringEx("panel.groups_create.button.attributes.title", "Edit"),
              hint: Localization().getStringEx("panel.groups_create.button.attributes.hint", ""),
              textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
              backgroundColor: Styles().colors.white,
              borderColor: Styles().colors.fillColorSecondary,
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
    List<ContentAttribute>? attributes = _contentAttributes?.attributes;
    if ((groupAttributes != null) && (attributes != null)) {
      for (ContentAttribute attribute in attributes) {
        List<String>? displayAttributes = attribute.displaySelectedLabelsFromSelection(groupAttributes, complete: true);
        if ((displayAttributes != null) && displayAttributes.isNotEmpty) {
          attributesList.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("${attribute.displayTitle}: ", overflow: TextOverflow.ellipsis, maxLines: 1, style:
              Styles().textStyles.getTextStyle("widget.card.detail.small.fat")
            ),
            Expanded(child:
              Text(displayAttributes.join(', '), /*overflow: TextOverflow.ellipsis, maxLines: 1,*/ style:
                Styles().textStyles.getTextStyle("widget.card.detail.small.regular")
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
      scope: _contentAttributesScope,
      contentAttributes: _contentAttributes,
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
              style: Styles().textStyles.getTextStyle("widget.item.small.thin.spaced")
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
                      subject: Localization().getStringEx("panel.groups.common.private.search.hidden.subject", "Hidden Group"),
                      value: _group?.hiddenForSearch,
                      onTap: _onTapHiddenForSearch)),
              Semantics(
                  container: true,
                  child: Container(
                      padding: EdgeInsets.only(left: 8, right: 8, top: 12),
                      child: Text(
                          Localization()
                              .getStringEx("panel.groups.common.private.search.hidden.description", "A hidden group is unsearchable."),
                          style: Styles().textStyles.getTextStyle("widget.item.small.thin.spaced"))))
            ])));
  }

  void _onTapHiddenForSearch() {
    _group!.hiddenForSearch = !(_group!.hiddenForSearch ?? false);
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildAdministrative() {
    return Padding(padding: EdgeInsets.all(16), child: Container(child:
      _buildSwitch(
        title: Localization().getStringEx('panel.groups.common.administrative.switch.label', 'Is this group an admin team for managing Illinois app events?'),
        subject: Localization().getStringEx('panel.groups.common.administrative.switch.subject', 'Admin Team Group'),
        value: _group?.administrative,
        onTap: _onTapAdministrative
      )));
  }

  void _onTapAdministrative() {
    setStateIfMounted(() {
      _group?.administrative = (_group?.administrative != true);
    });
  }

  // Membership Questions
  Widget _buildMembershipLayout() {
    String buttonTitle = _isResearchProject ? Localization().getStringEx("panel.groups_settings.recruitment.button.question.title", "Recruitment Questions") : Localization().getStringEx("panel.groups_settings.membership.button.question.title", "Membership Questions");
    int questionsCount = _group?.questions?.length ?? 0;
    String questionsDescription = (0 < questionsCount)
        ? (questionsCount.toString() + " " + Localization().getStringEx("panel.groups_create.questions.existing.label", "Question(s)"))
        : Localization().getStringEx("panel.groups_create.questions.missing.label", "No questions");

    return Container(color: Styles().colors.background, padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(children: <Widget>[
        Container(height: 12),
        Semantics(explicitChildNodes: true, child:
          _buildSettingButton(
            title: buttonTitle,
            description: questionsDescription,
            onTap: _onTapQuestions
          )
        ),
      ]),
    );
  }

  Widget _buildSettingButton({required String title, required String description, void onTap()?}) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            decoration: BoxDecoration(
                color: Styles().colors.white,
                border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                borderRadius: BorderRadius.all(Radius.circular(4))),
            padding: EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: <Widget>[
                Expanded(
                    child: Text(
                  title,
                  style: Styles().textStyles.getTextStyle("widget.title.regular.fat")
                )),
                Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Styles().images.getImage('chevron-right-bold', excludeFromSemantics: true),
                )
              ]),
              Container(
                  padding: EdgeInsets.only(right: 42, top: 4),
                  child: Text(
                    description,
                    style: Styles().textStyles.getTextStyle("widget.detail.light.regular")
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
      sprintf(Localization().getStringEx("panel.groups_settings.tags.label.question.format", "%s Question(s)"), [questionsCount.toString()]) :
      Localization().getStringEx("panel.groups_settings.audience.button.question.description.default", "All Potential Participants");

    return Container(
      color: Styles().colors.background,
      padding: EdgeInsets.only(left: 16, right: 16, top: 8),
      child: Column(children: <Widget>[
        Semantics(
            explicitChildNodes: true,
            child: _buildSettingButton(
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

  // AuthMan Group
  Widget _buildAuthManLayout() {
    String fieldTitle = Localization().getStringEx("panel.groups_create.authman.enabled.label", "Is this a managed membership group?");

    return Padding(padding: EdgeInsets.only(left: 16, top: 12, right: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSwitch(
          title: fieldTitle,
          subject: Localization().getStringEx("panel.groups_create.authman.enabled.subject", "Managed Membership Group"),
          value: _isAuthManGroup,
          onTap: _onTapAuthMan
        ),
        Visibility(visible: _isAuthManGroup, child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GroupSectionTitle(
              title: Localization().getStringEx("panel.groups_create.authman.group.name.label", "Membership name"),
              requiredMark: true
            ),
            TextField(
              onChanged: _onAuthManGroupNameChanged,
              controller: _authManGroupNameController,
              maxLines: 5,
              decoration: _textFieldDecorationEx(
                label: AppSemantics.textFieldSemanticsLabel(label: fieldTitle),
              ),
              style: Styles().textStyles.getTextStyle("widget.item.regular.thin")
            )
          ])
        )
      ])
    );
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

  // Attendance
  /*Widget _buildAttendanceLayout() {
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
  }*/

  //Settings
  Widget _buildSettingsLayout() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child:  RibbonButton(
          title: Localization().getStringEx('panel.groups_settings.button.advanced_settings.title', 'Advanced Settings'), //Localize
          semanticsHint: Localization().getStringEx('panel.groups_settings.button.advanced_settings.hint', ''),
          border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
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
      ToggleRibbonButton(
        label: Localization().getStringEx('panel.groups_settings.auto_join.project.enabled.label', 'Does not require my screening of potential participants'),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
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
  } */
  //Buttons
  Widget _buildButtonsLayout() {
    return Semantics(container: true, child: Container( color: Styles().colors.white,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: RoundedButton(
              label: (_group?.researchProject == true) ?
                Localization().getStringEx("panel.groups_create.button.create.project.title", "Create Project") :
                Localization().getStringEx("panel.groups_create.button.create.title", "Create Group"),
              textStyle: _canSave ? Styles().textStyles.getTextStyle("widget.button.title.large.fat") : Styles().textStyles.getTextStyle("widget.button.disabled.title.large.fat"),
              backgroundColor: Styles().colors.white,
              borderColor: _canSave ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
              enabled: _canSave,
              progress:  _creating,
              onTap: _onTapCreate,
            ),
          ),
        ));
  }

  void _onTapCreate() {
    Analytics().logSelect(target: "Create Group");
    if (!_creating && _canSave) {
      if (_isResearchProject) {
        _onCreateGroup();
      }
      else {
        _showCreateGroupPrompt().then((bool? result) {
          if (result == true) {
            _onCreateGroup();
          }
        });
      }

    }
  }

  Future<bool?> _showCreateGroupPrompt() {
    String prompt = Localization().getStringEx("panel.groups_create.prompt.msg.title", "The {{app_university}} takes pride in its efforts to support free speech and to foster inclusion and mutual respect. Users may submit a report to group administrators about obscene, threatening, or harassing content. Users may also choose to report content in violation of Student Code to the Office of the Dean of Students.").replaceAll('{{app_university}}', Localization().getStringEx('app.university_name', 'University of Illinois'));
    return AppAlert.showCustomDialog(context: context,
      contentWidget: Text(prompt),
      actions: <Widget>[
        TextButton(
          child: Text(Localization().getStringEx('dialog.ok.title', 'OK')),
          onPressed: () {
            Analytics().logAlert(text: prompt, selection: "OK");
            Navigator.of(context).pop(true);
          }),
        TextButton(
          child: Text(Localization().getStringEx('dialog.cancel.title', 'Cancel')),
          onPressed: () {
            Analytics().logAlert(text: prompt, selection: "Cancel");
            Navigator.of(context).pop(false);
          })
      ]);
  }

  void _onCreateGroup() {
    if (!_creating && _canSave) {
      setState(() {
        _creating = true;
      });

      // control research groups options
      if (_group?.researchProject == true) {
        _group?.privacy = GroupPrivacy.public;
        _group?.hiddenForSearch = false;
        _group?.authManEnabled = false;
        _group?.authManGroupName = null;
        _group!.attendanceGroup = false;
        //Unlocked Advanced setting
        // _group?.canJoinAutomatically = true;
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
        _group?.authManGroupName = null;
      }

      // if the group is not research or if it does not require confirmation then clear consent statement text
      if ((_group?.researchProject != true) || (_researchRequiresConsentConfirmation != true)) {
        _group?.researchConsentStatement = null;
      }

      //Add members/admins
      List<String>? adminNetIds;
      GroupMemberStatus? adminsStatus;
      if(StringUtils.isNotEmpty(_groupNetIdsController.text)) {
        adminsStatus = _selectedMembersStatus;
        adminNetIds = ListUtils.notEmpty(ListUtils.stripEmptyStrings(_groupNetIdsController.text.split(ListUtils.commonDelimiterRegExp)));
      }

      Groups().createGroup(_group, adminNetIds: adminNetIds, adminsStatus: adminsStatus).then((GroupError? error) {
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
  // AdminSection
  Widget _buildAdminSettingsSection() {
    String title =  'NETIDS (comma separated)'; //TBD localize
    String fieldTitle = 'NET ids';
    return Visibility(visible: true, child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child:
              GroupSectionTitle(title: title, requiredMark: false)
            )
          ]),
          Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: [
            Expanded(child:
              TextField(
                controller: _groupNetIdsController,
                maxLines: 1,
                decoration: _textFieldDecorationEx(
                  label: AppSemantics.textFieldSemanticsLabel(label: fieldTitle),
                ),
                style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
              )
            ),
            Padding(padding: EdgeInsets.only(left: /*AppScreen.isLarge(context) ? 30 : */6), child:
              _adminStatusDropdown
            )
          ])
        ])
      )
    );
  }


  Widget get _adminStatusDropdown =>
    MergeSemantics(key: GlobalKey(), child:
      Semantics(label: "Select Status", child:
        DropdownButtonHideUnderline(child:
          DropdownButton2<GroupMemberStatus>(
            dropdownStyleData: DropdownStyleData(
              width: _membersStatusDropdownItemsWidth ??= _evalMembersStatusDropdownItemsWidth(),
              direction: DropdownDirection.left,
              decoration: _dropdownDecoration,
            ),
            customButton: _adminStatusDropdownButton(),
            isExpanded: false,
            items: _adminStatusDropdownItems(),
            onChanged: _onAdminStatusDropdownSelected,
          ),
        )
      )
    );

  void _onAdminStatusDropdownSelected(GroupMemberStatus? status) {
    Analytics().logSelect(target: 'Select Admin Status: $status');
    if ((status != null) && mounted)
    setState(() {
      _selectedMembersStatus = status;
    });
  }

  Widget _adminStatusDropdownButton() =>
    Container(decoration: _dropdownDecoration, child:
      Padding(padding: EdgeInsets.only(left: 12, right: 6, top: 12, bottom: 12), child:
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(groupMemberStatusToString(_selectedMembersStatus) ?? '', style: Styles().textStyles.getTextStyle('widget.group.dropdown_button.value') ,),
          Padding(padding: EdgeInsets.only(left: 8), child:
            SizedBox(width: 10, height: 10, child:
              Center(child:
                Styles().images.getImage('chevron-down', size: 10),
              )
            )
          )
        ],)
      )
    );

  List<DropdownMenuItem<GroupMemberStatus>> _adminStatusDropdownItems() =>
    List.from(_adminsStatusItems.map((status) => _adminStatusDropdownItem(status, selected: _selectedMembersStatus == status)));

  DropdownMenuItem<GroupMemberStatus> _adminStatusDropdownItem(GroupMemberStatus status, { bool selected = false,}) =>
      AccessibleDropDownMenuItem<GroupMemberStatus>(
        semanticsLabel: status.name,
        value: status,
        child: Row(mainAxisSize: MainAxisSize.max, children: [
          Expanded(child:
            Text(groupMemberStatusToString(status) ?? '',
              overflow: TextOverflow.ellipsis,
              style: Styles().textStyles.getTextStyle(selected ?  'widget.group.dropdown_button.item.selected' : 'widget.group.dropdown_button.item.not_selected'),
              semanticsLabel: "",
            ),
          ),
          Padding(padding: EdgeInsets.only(left: 12), child:
            SizedBox(width: 16, height: 16, child:
              Center(child: Styles().images.getImage(selected ? 'radio-button-on' : 'radio-button-off', size: 16))
            )
          )
        ],),
      );

  double _evalMembersStatusDropdownItemsWidth() {
    double maxTextWidth = 0;
    for (GroupMemberStatus status in _adminsStatusItems) {
      final Size textSizeFull = (TextPainter(
        text: TextSpan(text: groupMemberStatusToString(status) ?? '', style: Styles().textStyles.getTextStyle('widget.group.dropdown_button.item.not_selected')),
        textScaler: MediaQuery.of(context).textScaler,
        textDirection: TextDirection.ltr,
      )..layout()).size;
      if (maxTextWidth < textSizeFull.width) {
        maxTextWidth = textSizeFull.width;
      }
    }
    double dropdownItemWidth = (maxTextWidth * 5 / 3) + (16 + 12) + 32;
    return min(dropdownItemWidth, MediaQuery.of(context).size.width * 2 / 3);
  }

  BoxDecoration get _dropdownDecoration => BoxDecoration(
    color: Styles().colors.white,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  List<GroupMemberStatus> get _adminsStatusItems => [GroupMemberStatus.admin, GroupMemberStatus.member];

  //
  // Common
  Widget _buildTitle(String title, String iconKey){
    return Container( padding: EdgeInsets.only(left: 16), child:
      Semantics(label: title, header: true, excludeSemantics: true, child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Styles().images.getImage(iconKey, excludeFromSemantics: true) ?? Container(),
          Expanded(child:
            Container(padding: EdgeInsets.only(left: 14, right: 4), child:
              Text(title, style: Styles().textStyles.getTextStyle("widget.title.regular.fat"),)
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSwitch({required String title, String? subject, bool? value, void Function()? onTap}){
    bool toggled = (value == true);
    String semanticsValue = AppSemantics.toggleValue(toggled);
    String semanticsHint = AppSemantics.toggleHint(toggled,
      subject: subject ?? title,
    );

    return Semantics(label: title, hint: semanticsHint, value: semanticsValue, button: true, child:
      Container(
        decoration: BoxDecoration(
            color: Styles().colors.white,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(4))
        ),
        padding: EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child:
              Text(title, semanticsLabel: "", style: Styles().textStyles.getTextStyle("widget.title.regular.fat"))
            ),
            GestureDetector(
              onTap: ((onTap != null)) ?() {
                onTap();
                AppSemantics.announceCheckBoxStateChange(context,  /*reversed value*/!(value == true), title);
              } : (){},
              child: Padding(padding: EdgeInsets.only(left: 10), child:
                Styles().images.getImage(value ?? false ? 'toggle-on' : 'toggle-off')
              )
            )
          ])
        ])
      ),
    );
  }

  bool get _isManagedGroupAdmin {
    return Auth2().isManagedGroupAdmin;
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
        (_contentAttributes?.isSelectionValid(_group?.attributes) ?? false) &&
        (!(_group?.authManEnabled ?? false) || (StringUtils.isNotEmpty(_group?.authManGroupName))) &&
        ((_group?.researchProject != true) || !_researchRequiresConsentConfirmation || StringUtils.isNotEmpty(_group?.researchConsentStatement)) &&
        ((_group?.researchProject != true) || (_researchProfileQuestionsCount >= 0));
  }

  bool get _loading => false;

  String get _contentAttributesScope => Groups.contentAttributesScope(researchProject: _isResearchProject);
  ContentAttributes? get _contentAttributes => Groups().contentAttributes(researchProject: _isResearchProject);
}
