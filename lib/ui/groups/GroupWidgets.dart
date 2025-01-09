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

import 'package:device_calendar/device_calendar.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:neom/mainImpl.dart';
import 'package:neom/model/Analytics.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/service/Storage.dart';
import 'package:neom/ui/groups/GroupMembersSelectionPanel.dart';
import 'package:neom/ui/groups/GroupPostCreatePanel.dart';
import 'package:neom/ui/groups/ImageEditPanel.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:neom/ext/Group.dart';
import 'package:neom/ext/Social.dart';
import 'package:neom/service/Analytics.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:neom/ui/groups/GroupDetailPanel.dart';
import 'package:neom/ui/groups/GroupPostDetailPanel.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

/////////////////////////////////////
// GroupSectionTitle

class GroupSectionTitle extends StatelessWidget {
  final String? title;
  final TextStyle? titleTextStyle;
  final String? description;
  final TextStyle? descriptionTextStyle;
  final bool? requiredMark;
  final TextStyle? requiredMarkTextStyle;
  final EdgeInsetsGeometry margin;

  GroupSectionTitle({Key? key,
    this.title, this.titleTextStyle,
    this.description, this.descriptionTextStyle,
    this.requiredMark, this.requiredMarkTextStyle,
    this.margin = const EdgeInsets.only(bottom: 8, top: 16)}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(padding: margin, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Semantics(label: _semanticsLabel, hint: description, header: true, excludeSemantics: true, child:
          RichText(text:
            TextSpan(text: title, style: titleTextStyle ?? Styles().textStyles.getTextStyle("widget.title.tiny.fat"),
              children: [
                TextSpan(text: (requiredMark == true) ?  " *" : "", style: requiredMarkTextStyle ?? Styles().textStyles.getTextStyle("widget.title.tiny.extra_fat"),
              )
            ],),
          ),
        ),
        (description != null) ? Container(padding: EdgeInsets.only(top: 2), child:
          Text(description ?? "", semanticsLabel: "", style:  descriptionTextStyle ?? Styles().textStyles.getTextStyle("widget.item.small.thin"),),
        ) : Container(),
      ],)
    );
  }

  String? get _semanticsLabel => "$title ${requiredMark == true ? ", required" : ""}";
}

/////////////////////////////////////
// GroupDropDownButton

typedef GroupDropDownDescriptionDataBuilder<T> = String? Function(T item);

class GroupDropDownButton<T> extends StatefulWidget{

  final List<T>? items;
  final T? initialSelectedValue;
  final String? emptySelectionText;
  final String? buttonHint;
  final bool enabled;
  final bool multipleSelection;
  final double? itemHeight;
  final EdgeInsets padding;
  final BoxDecoration? decoration;
  
  final GroupDropDownDescriptionDataBuilder<T>? constructTitle;
  final GroupDropDownDescriptionDataBuilder<T>? constructDropdownTitle;
  final GroupDropDownDescriptionDataBuilder<T>? constructListItemTitle;
  
  final GroupDropDownDescriptionDataBuilder<T>? constructDescription;
  final GroupDropDownDescriptionDataBuilder<T>? constructDropdownDescription;
  final GroupDropDownDescriptionDataBuilder<T>? constructListItemDescription;
  
  final bool Function(T item)? isItemSelected;
  final bool Function(T item)? isItemEnabled;
  final void Function(T item)? onItemSelected;
  final void Function(T item)? onValueChanged;


  GroupDropDownButton({Key? key,
    this.items, this.initialSelectedValue, this.emptySelectionText, this.buttonHint,
    this.enabled = true, this.multipleSelection = false, this.itemHeight = kMinInteractiveDimension, this.padding = const EdgeInsets.only(left: 12, right: 8), this.decoration,
    this.constructTitle, this.constructDropdownTitle, this.constructListItemTitle,
    this.constructDescription, this.constructDropdownDescription, this.constructListItemDescription,
    this.onValueChanged, this.isItemSelected, this.isItemEnabled, this.onItemSelected }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GroupDropDownButtonState<T>();
  }
}

class _GroupDropDownButtonState<T> extends State<GroupDropDownButton<T>>{

  @override
  Widget build(BuildContext context) {
    TextStyle? valueStyle = Styles().textStyles.getTextStyle("widget.group.dropdown_button.value");
    TextStyle? hintStyle = Styles().textStyles.getTextStyle("widget.group.dropdown_button.hint");

    String? buttonTitle = _getButtonTitleText();
    String? buttonDescription = _getButtonDescriptionText();
    return Container (
      decoration: widget.decoration ?? BoxDecoration(
        color: Styles().colors.surface,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(4))
      ),
      padding: widget.padding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Semantics(container: true, label: buttonTitle, hint: widget.buttonHint, excludeSemantics: true, child:
          Theme(data: ThemeData(
            /// This is as a workaround to make dropdown backcolor always white according to Miro & Zepplin wireframes
            hoverColor: Styles().colors.surface,
            focusColor: Styles().colors.surface,
            canvasColor: Styles().colors.surface,
            primaryColor: Styles().colors.surface,
            /*accentColor: Styles().colors.surface,*/
            highlightColor: Styles().colors.surface,
            splashColor: Styles().colors.surface,),
            child: DropdownButton(
              icon: Styles().images.getImage('chevron-down', excludeFromSemantics: true), //Image.asset('images/icon-down-orange.png', excludeFromSemantics: true),
              isExpanded: true,
              itemHeight: null,
              focusColor: Styles().colors.surface,
              underline: Container(),
              hint: Text(buttonTitle ?? "", style: (widget.initialSelectedValue == null ? hintStyle : valueStyle)),
              items: _constructItems(),
              onChanged: (widget.enabled ? (dynamic value) => _onValueChanged(value) : null)
            ),
          ),
        ),
        Visibility(visible: buttonDescription != null, child:
          Semantics(container: true, child:
            Container(padding: EdgeInsets.only(right: 42, bottom: 12), child:
              Text(buttonDescription ?? '', style:
                Styles().textStyles.getTextStyle("widget.group.dropdown_button.hint"),
              ),
            )
          )
        ),
      ])
    );
  }

  Widget _buildDropDownItem(String title, String? description, bool isSelected, bool isEnabled) {
    String? imageAsset = isEnabled ?
      (widget.multipleSelection ?
        (isSelected ? "check-box-filled" : "box-outline-gray") :
        (isSelected ? "check-circle-filled" : "circle-outline")
      ) : null;

    return Container(color: (Colors.white), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
        Container(height: 11),
        Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Flexible(child:
            Padding(padding: const EdgeInsets.only(right: 8), child:
              Text(title, overflow: TextOverflow.ellipsis, style:
                isSelected ? Styles().textStyles.getTextStyle("widget.group.dropdown_button.item.selected") :  Styles().textStyles.getTextStyle("widget.group.dropdown_button.item.not_selected")
              ),
            )
          ),
          
          Styles().images.getImage(imageAsset, excludeFromSemantics: true) ?? Container()
        ]),
        Visibility(visible: description != null, child: 
          Container(padding: EdgeInsets.only(right: 30, top: 6),
            child: Text(description ?? '',
              style: Styles().textStyles.getTextStyle("widget.group.dropdown_button.hint")
            ),
          ),
        ),
        Container(height: 11),
        Container(height: 1, color: Styles().colors.fillColorPrimaryTransparent03,)
      ],)
    );
  }

  void _onValueChanged(dynamic value) {
    widget.onValueChanged!(value);
    setState(() {});
  }

  String? _getButtonDescriptionText(){
    if (widget.initialSelectedValue != null) {
      GroupDropDownDescriptionDataBuilder<T>? constructDescriptionFn = widget.constructDropdownDescription ?? widget.constructDescription;
      return (constructDescriptionFn != null) ? constructDescriptionFn(widget.initialSelectedValue!) : null;
    } else {
      //empty null for now
      return null;
    }
  }

  String? _getButtonTitleText(){
    if (widget.initialSelectedValue != null) {
      GroupDropDownDescriptionDataBuilder<T>? constructTitleFn = widget.constructTitle ?? widget.constructDropdownTitle;
      return constructTitleFn != null ? constructTitleFn(widget.initialSelectedValue!) : widget.initialSelectedValue?.toString();
    } else {
      return widget.emptySelectionText;
    }
  }

  bool _isItemSelected(T item) {
    if (widget.isItemSelected != null) {
      return widget.isItemSelected!(item);
    }
    else {
      return (widget.initialSelectedValue != null) && (widget.initialSelectedValue == item);
    }
  }

  bool _isItemEnabled(T item) {
    return (widget.isItemEnabled != null) ? widget.isItemEnabled!(item) : true;
  }

  List<DropdownMenuItem<T>>? _constructItems(){
    int optionsCount = widget.items?.length ?? 0;
    if (optionsCount == 0) {
      return null;
    }

    return widget.items!.map((T item) {
      GroupDropDownDescriptionDataBuilder<T>? constructTitleFn = widget.constructTitle ?? widget.constructListItemTitle;
      String? name = (constructTitleFn != null) ? constructTitleFn(item) : item?.toString();

      GroupDropDownDescriptionDataBuilder<T>? constructDescriptionFn = widget.constructListItemDescription ?? widget.constructDescription;
      String? description = (constructDescriptionFn != null) ? constructDescriptionFn(item) : null;

      return DropdownMenuItem<T>(
        value: item,
        child: (item != null) ? _buildDropDownItem(name!, description, _isItemSelected(item), _isItemEnabled(item)) : Container(),
        onTap: () => widget.onItemSelected?.call(item),
      );
    }).toList();
  }

}

/////////////////////////////////////
// GroupMembershipAddButton

class GroupMembershipAddButton extends StatelessWidget {
  final String?             title;
  final GestureTapCallback? onTap;
  final double             height;
  final EdgeInsetsGeometry padding;
  final bool               enabled;

  GroupMembershipAddButton({
    this.title,
    this.onTap,
    this.height = 42,
    this.padding = const EdgeInsets.only(left:24, right: 8,),
    this.enabled = true
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap,
      child: Container(height: height,
        decoration: BoxDecoration(color: Colors.white,
          border: Border.all(color: enabled ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent, width: 2),
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Padding(padding: EdgeInsets.only(left:16, right: 8, ),
          child: Center(
            child: Row(children: <Widget>[
              Text(title!, style:  enabled ? Styles().textStyles.getTextStyle("widget.button.title.enabled") : Styles().textStyles.getTextStyle("widget.button.title.disabled") ),
            ],)
          )
        ),
      ),
    );
  }
}

class HeaderBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: Localization().getStringEx('headerbar.back.title', 'Back'),
      hint: Localization().getStringEx('headerbar.back.hint', ''),
      button: true,
      excludeSemantics: true,
      child: IconButton(
          icon: Styles().images.getImage('caret-left', excludeFromSemantics: true) ?? Container(),
          onPressed: (){
            Analytics().logSelect(target: "Back");
            Navigator.pop(context);
          }),
    );
  }
}

class GroupsConfirmationDialog extends StatelessWidget{
  final String? message;
  final String? buttonTitle;
  final Function? onConfirmTap;

  const GroupsConfirmationDialog({Key? key, this.message, this.buttonTitle, this.onConfirmTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Styles().colors.fillColorPrimary,
      child: StatefulBuilder(
          builder: (context, setStateEx){
            return Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 26),
                    child: Text(
                      message!,
                      textAlign: TextAlign.left,
                      style: Styles().textStyles.getTextStyle("widget.dialog.message.regular.extra_fat"),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Expanded(child:
                        RoundedButton(
                          label: Localization().getStringEx('headerbar.back.title', "Back"),
                          textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.thin"),
                          borderColor: Styles().colors.surface,
                          backgroundColor: Styles().colors.surface,
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          onTap: (){
                            Analytics().logAlert(text: message, selection: "Back");
                            Navigator.pop(context);
                          },
                        )),
                      Container(width: 16,),
                      Expanded(child:
                        RoundedButton(
                          label: buttonTitle ?? '',
                          textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                          borderColor: Styles().colors.fillColorSecondary,
                          backgroundColor: Styles().colors.surface,
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          onTap: (){
                            Analytics().logAlert(text: message, selection: buttonTitle);
                            onConfirmTap!();
                          },
                      )),
                    ],
                  ),
                ],
              ),
            );
          }),
    );
  }
}

/////////////////////////////////////
// GroupAddImageWidget

class GroupAddImageWidget extends StatefulWidget {
  static String _groupImageStoragePath = 'group/tout';
  static int _groupImageWidth = 1080;

  final String? url;

  const GroupAddImageWidget({super.key, this.url});

  @override
  _GroupAddImageWidgetState createState() => _GroupAddImageWidgetState();
  //
  // // static Future<String?> show({required BuildContext context, String? updateUrl}) async {
  // static Future<ImagesResult?> show({required BuildContext context, String? url}) async {
  //   ImagesResult? imageResult;
  //
  //   if(url == null){
  //     Future<dynamic> result =  showDialog(context: context, builder: (_) => Material(type: MaterialType.transparency, child: GroupAddImageWidget()));
  //     return result.then((url) => url);
  //   } else {
  //     imageResult = await Navigator.push(context, CupertinoPageRoute(builder: (context) =>
  //         ImageEditPanel(storagePath: _groupImageStoragePath, width: _groupImageWidth, preloadImageUrl: url,)));
  //   }
  //
  //   // return imageResult?.resultType == ImagesResultType.succeeded? imageResult?.data?.toString() : null;
  //   return imageResult;
  // }

  static Future<ImagesResult?> show({required BuildContext context, String? url}) async =>
      showDialog(context: context, builder: (_) => Material(type: MaterialType.transparency, child: GroupAddImageWidget(url: url)));

}

class _GroupAddImageWidgetState extends State<GroupAddImageWidget> {
  var _imageUrlController = TextEditingController();
  bool _showProgress = false;

  @override
  void initState() {
    if(StringUtils.isNotEmpty(widget.url)){
      _imageUrlController.text = widget.url!;
    }
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
                      style: Styles().textStyles.getTextStyle("widget.dialog.message.large.thin")
                    ),
                  ),
                  Spacer(),
                  InkWell(
                    onTap: _onTapCloseImageSelection,
                    child: Padding(
                      padding: EdgeInsets.only(right: 10, top: 10),
                      child: Text(
                        '\u00D7',
                        semanticsLabel: "Close Button", //TBD localization
                        style: Styles().textStyles.getTextStyle('widget.dialog.button.close'),
                      ),
                    ),
                  ),
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
                              style: Styles().textStyles.getTextStyle('widget.input_field.text.regular'),
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors.textDark)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors.textDark)),
                                hintText:  Localization().getStringEx("widget.add_image.field.description.label","Image Url"),
                                labelText:  Localization().getStringEx("widget.add_image.field.description.hint","Image Url"),
                                labelStyle: Styles().textStyles.getTextStyle('widget.input_field.text.regular'),
                              ))),
                      Padding(
                          padding: EdgeInsets.all(10),
                          child: RoundedButton(
                              label: Localization().getStringEx("widget.add_image.button.use_url.label","Use Url"),
                              textStyle: Styles().textStyles.getTextStyle("widget.button.light.title.large.fat"),
                              borderColor: Styles().colors.fillColorSecondary,
                              backgroundColor: Styles().colors.background,
                              onTap: _onTapUseUrl)),
                      Padding(
                          padding: EdgeInsets.all(10),
                          child: RoundedButton(
                              label:  Localization().getStringEx("widget.add_image.button.chose_device.label","Choose from Device"),
                              textStyle: Styles().textStyles.getTextStyle("widget.button.light.title.large.fat"),
                              borderColor: Styles().colors.fillColorSecondary,
                              backgroundColor: Styles().colors.background,
                              progress: _showProgress,
                              onTap: _onTapChooseFromDevice)),
                      Padding(
                          padding: EdgeInsets.all(10),
                          child: RoundedButton(
                              label:  Localization().getStringEx("widget.add_image.button.clear.label","Clear"), //TBD localize
                              textStyle: Styles().textStyles.getTextStyle("widget.button.light.title.large.fat"),
                              borderColor: Styles().colors.fillColorSecondary,
                              backgroundColor: Styles().colors.background,
                              onTap: _onTapClear)),
                    ]))
          ],
        ));
  }

  void _onTapCloseImageSelection() {
    Analytics().logSelect(target: "Close image selection");
    Navigator.pop(context, ImagesResult.cancel());
  }

  void _onTapUseUrl() {
    Analytics().logSelect(target: "Use Url");
    String url = _imageUrlController.value.text;
    if (url == "") {
      AppToast.showMessage(Localization().getStringEx("widget.add_image.validation.url.label","Please enter an url"));
      return;
    }

    bool isReadyUrl = url.endsWith(".webp");
    if (isReadyUrl) {
      //ready
      AppToast.showMessage(Localization().getStringEx("widget.add_image.validation.success.label","Successfully added an image"));
      Navigator.pop(context, ImagesResult.succeed(imageUrl: url));
    } else {
      //we need to process it
      setState(() {
        _showProgress = true;
      });

      Future<ImagesResult> result =
      Content().useUrl(storageDir: GroupAddImageWidget._groupImageStoragePath, width: GroupAddImageWidget._groupImageWidth, url: url);
      result.then((logicResult) {
        setState(() {
          _showProgress = false;
        });


        ImagesResultType? resultType = logicResult.resultType;
        switch (resultType) {
          case ImagesResultType.cancelled:
          //do nothing
            break;
          case ImagesResultType.error:
            AppToast.showMessage(logicResult.errorMessage ?? ''); //TBD: localize error message
            break;
          case ImagesResultType.succeeded:
          //ready
            AppToast.showMessage(Localization().getStringEx("widget.add_image.validation.success.label","Successfully added an image"));
            Navigator.pop(context, logicResult);
            break;
          default:
            break;
        }
      });
    }
  }

  void _onTapChooseFromDevice() {
    Analytics().logSelect(target: "Choose From Device");

    setState(() {
      _showProgress = true;
    });

    // Future<ImagesResult?> result =
    // Content().selectImageFromDevice(storagePath: _groupImageStoragePath, width: _groupImageWidth);
    // result.then((logicResult) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ImageEditPanel(storagePath: GroupAddImageWidget._groupImageStoragePath, width: GroupAddImageWidget._groupImageWidth, preloadImageUrl: widget.url,))).then((logicResult){
      setState(() {
        _showProgress = false;
      });

      ImagesResultType? resultType = logicResult?.resultType;
      switch (resultType) {
        case ImagesResultType.cancelled:
        //do nothing
          break;
        case ImagesResultType.error:
          AppToast.showMessage(logicResult.errorMessage ?? ''); //TBD: localize error message
          break;
        case ImagesResultType.succeeded:
        //ready
          AppToast.showMessage(Localization().getStringEx("widget.add_image.validation.success.label","Successfully added an image"));
          Navigator.pop(context, logicResult);
          break;
        default:
          break;
      }
    });
  }

  void _onTapClear() {
    Analytics().logSelect(target: "Clear");
    Navigator.pop(context, ImagesResult.succeed());
  }


}

/////////////////////////////////////
// GroupCard


enum GroupCardDisplayType { myGroup, allGroups, homeGroups }

class GroupCard extends StatefulWidget with AnalyticsInfo {
  final Group? group;
  final GroupCardDisplayType displayType;
  final EdgeInsets margin;
  final Function? onImageTap;

  GroupCard({super.key,
    required this.group,
    this.displayType = GroupCardDisplayType.allGroups,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.onImageTap,
  });

  @override
  AnalyticsFeature? get analyticsFeature {
    switch (displayType) {
      case GroupCardDisplayType.myGroup:    return (group?.isResearchProject != true) ? AnalyticsFeature.GroupsMy : AnalyticsFeature.ResearchProjectMy;
      case GroupCardDisplayType.allGroups:  return (group?.isResearchProject != true) ? AnalyticsFeature.GroupsAll : AnalyticsFeature.ResearchProjectOpen;
      case GroupCardDisplayType.homeGroups: return (group?.isResearchProject != true) ? AnalyticsFeature.Groups : AnalyticsFeature.ResearchProject;
    }
  }

  @override
  _GroupCardState createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> implements NotificationsListener {
  static const double _smallImageSize = 64;

  GroupStats? _groupStats;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Groups.notifyGroupStatsUpdated,
    ]);
    _loadGroupStats();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void onNotification(String name, dynamic param) {
    if ((name == Groups.notifyGroupStatsUpdated) && (widget.group?.id == param)) {
      _updateGroupStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: () => _onTapCard(context), child:
      Padding(padding: widget.margin, child:
        Container(padding: EdgeInsets.all(16), decoration: BoxDecoration( color: Styles().colors.surface, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))]), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            _buildHeading(),
            Container(height: 6),
            Row(children:[
              Expanded(child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                  _buildCategories(),
                  _buildTitle(),
                  _buildProperties(),
                ]),
              ),
              _buildImage()
            ]),
            Container(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child:
                _buildUpdateTime(),
              ),
              _buildMembersCount()
            ])
            // : Container()
          ]),
        )
      )
    );
  }

  Widget _buildHeading() {
    
    List<Widget> wrapContent = <Widget>[];

    if (widget.group?.privacy == GroupPrivacy.private) {
      wrapContent.add(_buildHeadingWrapLabel(Localization().getStringEx('widget.group_card.status.private', 'Private')));
    }

    if (widget.group?.authManEnabled ?? false) {
      wrapContent.add(_buildHeadingWrapLabel(Localization().getStringEx('widget.group_card.status.authman', 'Managed')));
    }

    if (widget.group?.hiddenForSearch ?? false) {
      wrapContent.add(_buildHeadingWrapLabel(Localization().getStringEx('widget.group_card.status.hidden', 'Hidden')));
    }

    List<String>? attributesList = Groups().displaySelectedContentAttributeLabelsFromSelection(widget.group?.attributes, usage: ContentAttributeUsage.label);
    if ((attributesList != null) && attributesList.isNotEmpty) {
      for (String attribute in attributesList) {
        wrapContent.add(_buildHeadingWrapLabel(attribute));
      }
    }

    // Finally, insert 'Public' if needed
    if ((widget.group?.privacy == GroupPrivacy.public) && wrapContent.isNotEmpty) {
      wrapContent.insert(0, _buildHeadingWrapLabel(Localization().getStringEx('widget.group_card.status.public', 'Public')));
    }

    List<Widget> rowContent = <Widget>[];

    String? userStatus = widget.group?.currentUserStatusText;
    if (StringUtils.isNotEmpty(userStatus)) {
      rowContent.add(Padding(padding: EdgeInsets.only(right: wrapContent.isNotEmpty ? 8 : 0), child:
        _buildHeadingLabel(userStatus!.toUpperCase(),
          color: widget.group?.currentUserStatusColor,
          textStyle: widget.group?.currentUserStatusTextStyle,
          semanticsLabel: sprintf(Localization().getStringEx('widget.group_card.status.hint', 'status: %s ,for: '), [userStatus.toLowerCase()])
        )      
      ));
    }

    if (wrapContent.isNotEmpty) {
      rowContent.add(Expanded(child:
        Wrap(alignment: WrapAlignment.end, spacing: 4, runSpacing: 2, children: wrapContent,)
      ));
    }

    return rowContent.isNotEmpty ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowContent,) : Container();
  }

  /*Widget _buildPrivacyStatysBadge(){
    String privacyStatus = '';
    if (widget.group?.authManEnabled ?? false) {
      privacyStatus += ' ' + Localization().getStringEx('widget.group_card.status.authman', 'Managed');
    }
    if (widget.group?.hiddenForSearch ?? false) {
      privacyStatus += ' ' + Localization().getStringEx('widget.group_card.status.hidden', 'Hidden');
    }
    if (widget.group?.privacy == GroupPrivacy.private) {
      privacyStatus = Localization().getStringEx('widget.group_card.status.private', 'Private') + privacyStatus;
    } else if (StringUtils.isNotEmpty(privacyStatus)) {
      privacyStatus = Localization().getStringEx('widget.group_card.status.public', 'Public') + privacyStatus;
    }

    return StringUtils.isNotEmpty(privacyStatus) ? _buildHeadingWrapLabel(privacyStatus) : Container();
  }*/

  Widget _buildHeadingLabel(String text, {Color? color, TextStyle? textStyle, String? semanticsLabel}) {
    return Semantics(label: semanticsLabel, excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.all(Radius.circular(2))),
        child: Text(text,
          style: textStyle ?? Styles().textStyles.getTextStyle("widget.heading.dark.extra_small"))));
  }

  Widget _buildHeadingWrapLabel(String text) {
    return _buildHeadingLabel(text.toUpperCase(),
      color: Styles().colors.fillColorSecondary,
      semanticsLabel: sprintf(Localization().getStringEx('widget.group_card.status.hint', 'status: %s ,for: '), [text.toLowerCase()])
    );
  }

  Widget _buildTitle() {
    return Row(children: [
      Expanded(child:
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child:
          Text(
            widget.group?.title?.toUpperCase() ?? "",
            overflow: TextOverflow.ellipsis,
            maxLines: widget.displayType == GroupCardDisplayType.homeGroups? 2 : 10,
            style: Styles().textStyles.getTextStyle('widget.group.card.title.medium.fat'),
          )
        )
      )
    ]);
  }

  Widget _buildCategories() {
    List<String>? displayList = Groups().displaySelectedContentAttributeLabelsFromSelection(widget.group?.attributes, usage: ContentAttributeUsage.category);
    return (displayList?.isNotEmpty ?? false) ? Row(children: [
      Expanded(child:
        RichText(
          text: TextSpan(children:<InlineSpan>[
            TextSpan(text: Localization().getStringEx('widget.group_card.categories.prefix', 'GROUP: '), style: Styles().textStyles.getTextStyle('widget.card.detail.tiny.fat'),),
            TextSpan(text: displayList?.join(', ').toUpperCase() ?? '', style: Styles().textStyles.getTextStyle('widget.card.detail.tiny'),),
          ]),
          overflow: TextOverflow.ellipsis,
          maxLines: (widget.displayType == GroupCardDisplayType.homeGroups) ? 2 : 10,
        ),
      )
    ]) : Container();
  }

  Widget _buildProperties() {
    List<Widget> propertiesList = <Widget>[];
    Map<String, dynamic>? groupAttributes = widget.group?.attributes;
    ContentAttributes? contentAttributes = Groups().contentAttributes;
    List<ContentAttribute>? attributes = contentAttributes?.attributes;
    if ((groupAttributes != null) && (contentAttributes != null) && (attributes != null)) {
      for (ContentAttribute attribute in attributes) {
        if ((attribute.usage == ContentAttributeUsage.property) && Groups().isContentAttributeEnabled(attribute)) {
          List<String>? displayAttributeValues = attribute.displaySelectedLabelsFromSelection(groupAttributes);
          if ((displayAttributeValues != null) && displayAttributeValues.isNotEmpty) {
            propertiesList.add(_buildProperty("${attribute.displayTitle}: ", displayAttributeValues.join(', ')));
          }
        }
      }
    }

    int pendingCount = (widget.group?.currentUserIsAdmin == true) ? (_groupStats?.pendingCount ?? 0) : 0;
    if (pendingCount > 0) {
      String pendingTitle = sprintf(Localization().getStringEx("widget.group_card.pending.label", "Pending: %s"), ['']);
      propertiesList.add(_buildProperty(pendingTitle, pendingCount.toString()));
    }

    return propertiesList.isNotEmpty ?
      Padding(padding: EdgeInsets.only(top: 4), child:
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: propertiesList,)
      ) : Container();
  }

  Widget _buildProperty(String title, String value) {
    return Row(children: [
      Text(title, overflow: TextOverflow.ellipsis, maxLines: 1, style:
        Styles().textStyles.getTextStyle("widget.card.detail.small.fat")
      ),
      Expanded(child:
        Text(value, maxLines: 1, style:
          Styles().textStyles.getTextStyle("widget.card.detail.small.regular")
        ),
      ),
    ],);
  }

  Widget _buildImage() {
    double maxImageWidth = 150;
    String? imageUrl = widget.group?.imageURL;
    return
      StringUtils.isEmpty(imageUrl) ? Container() :
      // Expanded(
      //     flex: 1,
      //     child:
      Semantics(
          label: "Group image",
          button: true,
          hint: "Double tap to zoom the image",
          child: GestureDetector(
              onTap: () {
                if (widget.onImageTap != null) {
                  widget.onImageTap!();
                }
              },
              child: Container(
                padding: EdgeInsets.only(left: 8),
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxImageWidth),
                  // width: _smallImageSize,
                  height: _smallImageSize,
                  child: Image.network(imageUrl!, excludeFromSemantics: true,
                    fit: BoxFit.fill,),),))
        // )
      );
  }


  Widget _buildUpdateTime() {
    return Container(
        child: Text(
          _timeUpdatedText,
          maxLines: (widget.displayType == GroupCardDisplayType.homeGroups) ? 2 : 10,
          overflow: TextOverflow.ellipsis,
          style: Styles().textStyles.getTextStyle("widget.card.detail.tiny")
    ));
  }

  bool get _isResearchProject => widget.group?.researchProject == true;

  Widget _buildMembersCount() {
    String membersLabel;
    int count = _groupStats?.activeMembersCount ?? 0;
    if (!_isResearchProject) {
      if (count == 0) {
        membersLabel = "No members";
      }
      else if (count == 1) {
        membersLabel = "1 member";
      }
      else {
        membersLabel = sprintf("%s members", [count]);
      }
    }
    else if (widget.group?.currentUserIsAdmin ?? false) {
      if (count == 0) {
        membersLabel = "No participants";
      }
      else if (count == 1) {
        membersLabel = "1 participant";
      }
      else {
        membersLabel = sprintf("%s participants", [count]);
      }
    }
    else {
      membersLabel = "";
    }
    return Visibility(visible: StringUtils.isNotEmpty(membersLabel), child:
      Text(membersLabel, style:
        Styles().textStyles.getTextStyle("widget.card.detail.tiny")
      ),
    );
  }

   void _loadGroupStats() {
    Groups().loadGroupStats(widget.group?.id).then((stats) {
      if (mounted) {
        setState(() {
          _groupStats = stats;
        });
      }
    });
  }

  void _updateGroupStats() {
    GroupStats? cachedGroupStats = Groups().cachedGroupStats(widget.group?.id);
    if ((cachedGroupStats != null) && (_groupStats != cachedGroupStats) && mounted) {
      setState(() {
        _groupStats = cachedGroupStats;
      });
    }
  }

  void _onTapCard(BuildContext context) {
    Analytics().logSelect(target: "Group: ${widget.group?.title}");
    // if (!Auth2().privacyMatch(4)) {
    //   AppAlert.showCustomDialog(context: context, contentWidget: _buildPrivacyAlertWidget(), actions: [
    //     TextButton(child: Text(Localization().getStringEx('dialog.ok.title', 'OK')), onPressed: _onDismissPopup)
    //   ]);
    // }
    // else
    if (!Auth2().isLoggedIn) {
      AppAlert.showCustomDialog(context: context, contentWidget: _buildLoggedOutAlertWidget(), actions: [
        TextButton(child: Text(Localization().getStringEx('dialog.ok.title', 'OK')), onPressed: _onDismissPopup)
      ]);
    }
    else {
      Navigator.push(context, CupertinoPageRoute(
        settings: RouteSettings(name: GroupDetailPanel.routeName),
        builder: (context) => GroupDetailPanel(group: widget.group, analyticsFeature: widget.analyticsFeature,)
      ));
    }
  }

  Widget _buildLoggedOutAlertWidget() =>
    Text(Localization().getStringEx('widget.group_card.login_na.msg', 'You need to be logged in to access specific groups. Set your privacy level to 4 or 5 under Settings. Then find the sign-in prompt under Profile.'), style:
      Styles().textStyles.getTextStyle('widget.description.small.fat')
    );

  Widget _buildPrivacyAlertWidget() {
    final String iconMacro = '{{privacy_level_icon}}';
    String privacyMsg = Localization().getStringEx('widget.group_card.privacy_alert.msg', 'With your privacy level at $iconMacro , you can only view the list of groups.');
    int iconMacroPosition = privacyMsg.indexOf(iconMacro);
    String privacyMsgStart = (0 < iconMacroPosition) ? privacyMsg.substring(0, iconMacroPosition) : '';
    String privacyMsgEnd = ((0 < iconMacroPosition) && (iconMacroPosition < privacyMsg.length)) ? privacyMsg.substring(iconMacroPosition + iconMacro.length) : '';

    return RichText(text: TextSpan(style: Styles().textStyles.getTextStyle('widget.description.small.fat'), children: [
      TextSpan(text: privacyMsgStart),
      WidgetSpan(alignment: PlaceholderAlignment.middle, child: _buildPrivacyLevelWidget()),
      TextSpan(text: privacyMsgEnd)
    ]));
  }

  Widget _buildPrivacyLevelWidget() {
    String privacyLevel = Auth2().prefs?.privacyLevel?.toString() ?? '';
    return Container(height: 40, width: 40, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Styles().colors.fillColorPrimary, width: 2), color: Styles().colors.surface, borderRadius: BorderRadius.all(Radius.circular(100)),), child:
      Container(height: 32, width: 32, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Styles().colors.fillColorSecondary, width: 2), color: Styles().colors.surface, borderRadius: BorderRadius.all(Radius.circular(100)),), child:
        Text(privacyLevel, style: Styles().textStyles.getTextStyle('widget.card.title.regular.extra_fat'))
      ),
    );
  }

  void _onDismissPopup() {
    Analytics().logSelect(target: 'OK');
    Navigator.of(context).pop();
  }

  String get _timeUpdatedText {
    return widget.group?.displayUpdateTime ?? '';
  }
}

//////////////////////////////////////
// GroupPostCard

class GroupPostCard extends StatefulWidget {
  final Post? post;
  final Group group;
  final List<Member>? allMembersAllowedToPost;
  final bool showImage;
  final bool isReply;
  final bool allowTap;

  GroupPostCard({Key? key, required this.post, required this.group, this.allMembersAllowedToPost, this.showImage = true, this.isReply = false, this.allowTap = true}) :
    super(key: key);

  @override
  _GroupPostCardState createState() => _GroupPostCardState();
}

class _GroupPostCardState extends State<GroupPostCard> {
  static const double _smallImageSize = 64;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String? creatorName = widget.post?.creatorName;
    String? htmlBody = widget.post?.body;
    String? imageUrl = widget.post?.imageUrl;
    List<String>? memberIds = widget.group.id != null ? widget.post?.getMemberAccountIds(groupId: widget.group.id!) : null;
    int visibleRepliesCount = _visibleRepliesCount;
    bool isRepliesLabelVisible = (visibleRepliesCount > 0);
    String? repliesLabel = (visibleRepliesCount == 1)
        ? Localization().getStringEx('widget.group.card.reply.single.reply.label', 'reply')
        : Localization().getStringEx('widget.group.card.reply.multiple.replies.label', 'replies');
    return Stack(alignment: Alignment.topRight, children: [
      Semantics(button:true,
        child:GestureDetector(
          onTap: widget.allowTap ? _onTapCard : null,
          child: Container(
              decoration: BoxDecoration(
                  color: Styles().colors.surface,
                  boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))],
              ),
              child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          CollectionUtils.isNotEmpty(Auth2().profilePicture) ?
                            Container(width: 20, height: 20, decoration:
                              BoxDecoration(shape: BoxShape.circle, color: Colors.white, image:
                                DecorationImage( fit: BoxFit.cover, image: Image.memory(Auth2().profilePicture!).image)
                              )
                            ) : Styles().images.getImage('person-circle-white') ?? Container(),
                          Padding(
                            padding: EdgeInsets.only(left: 8),
                            child:Text(StringUtils.ensureNotEmpty(creatorName),
                                textAlign: TextAlign.left,
                                style: Styles().textStyles.getTextStyle('widget.card.detail.tiny.medium_fat')),
                          ),
                        ]),
                        _buildDisplayDateWidget,
                      ],
                    ),
                    Container(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: HtmlWidget(
                              "<div style= text-overflow:ellipsis;max-lines:3> ${StringUtils.ensureNotEmpty(htmlBody)}</div>",
                              onTapUrl : (url) {_onLinkTap(url); return true;},
                              textStyle:  Styles().textStyles.getTextStyle("widget.card.title.small")
                          )),
                        StringUtils.isEmpty(imageUrl) || !widget.showImage ? Container() :
                        Expanded(
                          flex: 1,
                          child: Semantics(
                            label: "post image",
                            button: true,
                            hint: "Double tap to zoom the image",
                            child: Container(
                                padding: EdgeInsets.only(left: 8),
                                child: SizedBox(
                                  width: _smallImageSize,
                                  height: _smallImageSize,
                                  child: ModalImageHolder(child: Image.network(imageUrl!, excludeFromSemantics: true, fit: BoxFit.fill,)),),)
                            ))
                    ],),
                    Container(height: 16.0),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      GroupReaction(
                        groupId: widget.group.id,
                        entityId: widget.post?.id,
                        reactionSource: SocialEntityType.post,
                      ),
                      _buildScheduledDateWidget,
                      Visibility(
                        visible: isRepliesLabelVisible,
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Styles().images.getImage('comment') ?? Container(),
                          Padding(
                            padding: EdgeInsets.only(left: 6.0),
                            child: Text(StringUtils.ensureNotEmpty('${visibleRepliesCount.toString()} $repliesLabel'),
                              style: Styles().textStyles.getTextStyle('widget.card.detail.tiny.medium_fat')
                            ),
                          ),
                        ]),
                      )
                    ]),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(color: Styles().colors.dividerLineAccent, thickness: 1),
                    ),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('To: ${memberIds?.length ?? 0} members',
                        style: Styles().textStyles.getTextStyle('widget.card.detail.tiny.medium_fat')
                      ),
                      GestureDetector( onTap: () => _onTapPostOptions(), child:
                        Styles().images.getImage(widget.isReply ? 'ellipsis-alert' : 'report', excludeFromSemantics: true, color: Styles().colors.alert)
                      ),
                    ]),
                  ]))))),
    ]);
  }

  Widget get _buildDisplayDateWidget {
    String displayDateTime = StringUtils.ensureNotEmpty(widget.post?.displayDateTime);
    return Visibility(visible: widget.post?.isScheduled != true, child:
    Semantics(child: Container(
        padding: EdgeInsets.only(left: 6),
        child: Text(displayDateTime,
            semanticsLabel: "Updated ${widget.post?.displayDateTime ?? ""}",
            textAlign: TextAlign.right,
            style: Styles().textStyles.getTextStyle('widget.card.detail.tiny.medium_fat')))));
  }

  Widget get _buildScheduledDateWidget => Visibility(visible: widget.post?.isScheduled == true, child:
    Row( mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end,
      children:[
        Container(width: 6,),
        Container( padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Styles().colors.mediumGray1, borderRadius: BorderRadius.all(Radius.circular(2)),), child:
          Semantics(label: "Scheduled for ${widget.post?.displayScheduledTime ?? ""}", excludeSemantics: true, child:
            Text("Scheduled: ${widget.post?.displayScheduledTime ?? ""}", style:  Styles().textStyles.getTextStyle('widget.heading.extra_small'),)
        ))
    ]));

  void _onTapCard() {
    Analytics().logSelect(target: "Group post");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostDetailPanel(post: widget.post, group: widget.group)));
  }

  void _onLinkTap(String? url) {
    Analytics().logSelect(target: url);
    UrlUtils.launchExternal(url);
  }

  void _onTapPostOptions() {
    bool isReportAbuseVisible = widget.group.currentUserIsMemberOrAdmin ?? false;
    Analytics().logSelect(target: 'Post Options');
    showModalBottomSheet(
        context: context,
        backgroundColor: Styles().colors.surface,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)),),
        builder: (context) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Visibility(visible: isReportAbuseVisible, child: RibbonButton(
                    leftIconKey: "reply",
                    label: Localization().getStringEx("panel.group.detail.post.reply.reply.label", "Reply"),
                    onTap: _onTapReply
                )),
                // Visibility(visible: isReportAbuseVisible, child: RibbonButton(
                //   leftIconKey: "comment",
                //   label: Localization().getStringEx("panel.group.detail.post.button.report.students_dean.labe", "Report to Dean of Students"),
                //   onTap: () => _onTapReportAbuse(options: GroupPostReportAbuseOptions(reportToDeanOfStudents : true), post: widget.post),
                // )),
                // Visibility(visible: isReportAbuseVisible, child: RibbonButton(
                //   leftIconKey: "comment",
                //   label: Localization().getStringEx("panel.group.detail.post.button.report.group_admins.labe", "Report to Group Administrator(s)"),
                //   onTap: () => _onTapReportAbuse(options: GroupPostReportAbuseOptions(reportToGroupAdmins: true), post: widget.post),
                // )),
              ],
            ),
          );
        });
  }

  void _onTapReply() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostCreatePanel(group: widget.group, inReplyTo: widget.post?.id))).then((_) {
      Navigator.of(context).pop();
    });
  }

  // void _onTapReportAbuse({required GroupPostReportAbuseOptions options, Post? post}) {
  //   String? analyticsTarget;
  //   if (options.reportToDeanOfStudents && !options.reportToGroupAdmins) {
  //     analyticsTarget = Localization().getStringEx('panel.group.detail.post.report_abuse.students_dean.description.text', 'Report violation of Student Code to Dean of Students');
  //   }
  //   else if (!options.reportToDeanOfStudents && options.reportToGroupAdmins) {
  //     analyticsTarget = Localization().getStringEx('panel.group.detail.post.report_abuse.group_admins.description.text', 'Report obscene, threatening, or harassing content to Group Administrators');
  //   }
  //   else if (options.reportToDeanOfStudents && options.reportToGroupAdmins) {
  //     analyticsTarget = Localization().getStringEx('panel.group.detail.post.report_abuse.both.description.text', 'Report violation of Student Code to Dean of Students and obscene, threatening, or harassing content to Group Administrators');
  //   }
  //   Analytics().logSelect(target: analyticsTarget);
  //
  //   Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (context) => GroupPostReportAbuse(options: options, groupId: widget.group?.id, postId: (post ?? widget.post)?.id)));
  // }

  int get _visibleRepliesCount {
    int result = 0;
    //TBD: DDGS - implement replies
    // List<GroupPost>? replies = widget.post?.replies;
    List<Comment>? replies = null;
    if (replies != null) {
      //TBD: DD - implement comments count
      // bool? memberOrAdmin = widget.group.currentUserIsMemberOrAdmin;
      // for (Comment? reply in replies) {
      //   if ((reply!.private != true) || (memberOrAdmin == true)) {
      //     result++;
      //   }
      // }
      result = replies.length;
    }
    return result;
  }
}

//////////////////////////////////////
// GroupReplyCard

class GroupReplyCard extends StatefulWidget {
  final Comment? reply;
  final Post? post;
  final Group? group;
  final String? iconPath;
  final String? semanticsLabel;
  final void Function()? onIconTap;
  final void Function()? onCardTap;
  final bool showRepliesCount;

  GroupReplyCard({required this.reply, required this.post, required this.group, this.iconPath, this.onIconTap, this.semanticsLabel, this.showRepliesCount = true, this.onCardTap});

  @override
  _GroupReplyCardState createState() => _GroupReplyCardState();
}

class _GroupReplyCardState extends State<GroupReplyCard> with NotificationsListener{
  static const double _smallImageSize = 64;

  @override
  void initState() {
    NotificationService().subscribe(this, Social.notifyPostsUpdated);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? bodyText = StringUtils.ensureNotEmpty(widget.reply?.body);
    if (widget.reply?.isUpdated ?? false) {
      bodyText +=
          ' <span>(${Localization().getStringEx('widget.group.card.reply.edited.reply.label', 'edited')})</span>';
      // bodyText += ' <span style=color:${ColorUtils.toHex(Styles().colors.textDisabled  ?? Colors.blue)}>(${Localization().getStringEx('widget.group.card.reply.edited.reply.label', 'edited')})</span>';
      // bodyText += ' <a>(${Localization().getStringEx('widget.group.card.reply.edited.reply.label', 'edited')})</a>';

      // ' <span style=color:${ColorUtils.toHex(Styles().colors.textSurface ?? Colors.blue)}} >(${"VERY VERY VERY VERY VERY VERY VEry  long Span so we can check it's overflow styling"/*Localization().getStringEx('widget.group.card.reply.edited.reply.label', 'edited')*/})</span>';
          // ' <span>(${"VERY VERY VERY VERY VERY VEry long Span so we can check it's overflow styling"/*Localization().getStringEx('widget.group.card.reply.edited.reply.label', 'edited')*/})</span>';
    }
    return Semantics(container: true, button: true,
      child:GestureDetector(
        onTap: widget.onCardTap ?? _onTapCard,
         child:Container(
        decoration: BoxDecoration(
            color: Styles().colors.surface,
            boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))],
            borderRadius: BorderRadius.all(Radius.circular(8))),
        child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Semantics( child:
                  Text(StringUtils.ensureNotEmpty(widget.reply?.creatorName),
                    style: Styles().textStyles.getTextStyle("widget.card.title.small.fat")),
                ),
                Expanded(child: Container()),
                Visibility(
                  visible: Config().showGroupPostReactions &&
                      (widget.group?.currentUserHasPermissionToSendReactions == true),
                  child: GroupReaction(
                    groupId: widget.group?.id,
                    entityId: widget.reply?.id,
                    reactionSource: SocialEntityType.comment,
                  ),
                ),
                Visibility(
                    visible: StringUtils.isNotEmpty(widget.iconPath),
                    child: Semantics( child:Container(
                    child: Semantics(label: widget.semanticsLabel??"", button: true,
                    child: GestureDetector(
                        onTap: widget.onIconTap,
                        child: Padding(
                            padding: EdgeInsets.only(left: 10, top: 3),
                            child: (StringUtils.isNotEmpty(widget.iconPath) ? Styles().images.getImage(widget.iconPath!, excludeFromSemantics: true,) : Container())))))))
              ]),
              Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: Container(
                          child: Semantics( child:
                          Padding(
                              padding: EdgeInsets.only(top: 10),
                              child:
                              HtmlWidget(
                                  StringUtils.ensureNotEmpty(bodyText),
                                  onTapUrl : (url) {_onLinkTap(url); return true;},
                                  textStyle:  Styles().textStyles.getTextStyle("widget.card.title.small"),
                                  customStylesBuilder: (element) => (element.localName == "span") ? {"color": ColorUtils.toHex(Styles().colors.textDisabled)}: null //Not able to use Transparent colour, it's not parsed correctly
                                  // customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.blackTransparent018 ?? Colors.blue)} : null
                              )
                              // Html(
                              //   data: bodyText,
                              //   style: {
                              //   "body": Style(
                              //       color: Styles().colors.fillColorPrimary,
                              //       fontFamily: Styles().fontFamilies.regular,
                              //       fontSize: FontSize(16),
                              //       maxLines: 3000,
                              //       textOverflow: TextOverflow.ellipsis,
                              //       margin: EdgeInsets.zero
                              //   ),
                              //   "span": Style(
                              //       color: Styles().colors.blackTransparent018,
                              //       fontFamily: Styles().fontFamilies.regular,
                              //       fontSize: FontSize(16),
                              //       maxLines: 1,
                              //       textOverflow: TextOverflow.ellipsis)
                              //   },
                              //   onLinkTap: (url, context, attributes, element) => _onLinkTap(url))

                          )))),
                  StringUtils.isEmpty(widget.reply?.imageUrl)? Container() :
                  Expanded(
                      flex: 1,
                      child: Semantics (
                        button: true, label: "Image",
                       child: Container(
                          padding: EdgeInsets.only(left: 8, bottom: 8, top: 8),
                          child: SizedBox(
                          width: _smallImageSize,
                          height: _smallImageSize,
                           child: ModalImageHolder(child: Image.network(widget.reply!.imageUrl!, excludeFromSemantics: true, fit: BoxFit.fill,)),),))
                  )
                ],),
              Container(
                    padding: EdgeInsets.only(top: 12),
                    child: Row(children: [
                      Expanded(
                          child: Container(
                            child: Semantics(child: Text(StringUtils.ensureNotEmpty(widget.reply?.displayDateTime),
                                semanticsLabel: "Updated ${widget.reply?.displayDateTime ?? ""} ago",
                                style: Styles().textStyles.getTextStyle('widget.description.small'))),)),
                ],),)
            ])))));
  }

  void _onLinkTap(String? url) {
    Analytics().logSelect(target: url);
    UrlUtils.launchExternal(url);
  }

  void _onTapCard(){
    Analytics().logSelect(target: "Group reply");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostDetailPanel(post: widget.post, group: widget.group!, focusedReply: widget.reply, hidePostOptions: true,)));
  }

  @override
  void onNotification(String name, param) {
    if (name == Social.notifyPostsUpdated) {
      setStateIfMounted(() {});
    }
  }
}

//////////////////////////////////////
// GroupPostReaction

class GroupReaction extends StatefulWidget {
  final String? groupId;
  final String? entityId;
  final SocialEntityType reactionSource;

  GroupReaction({required this.groupId, this.entityId, required this.reactionSource});

  @override
  State<GroupReaction> createState() => _GroupReactionState();
}

class _GroupReactionState extends State<GroupReaction> {

  List<Reaction>? _reactions;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadReactions();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
        button: true,
        label: Localization().getStringEx('widget.group.card.reaction.thumbs_up.label', 'thumbs-up'),
        child: Stack(alignment: Alignment.center, children: [
          Visibility(
              visible: _loading,
              child: SizedBox.square(
                  dimension: 16, child: CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 2))),
          InkWell(
              onTap: _onTapReaction,
              onLongPress: _onLongPressReactions,
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: [
                Styles().images.getImage(_isCurrentUserReacted ? 'thumbs-up-filled' : 'thumbs-up-outline-gray', excludeFromSemantics: true) ??
                    Container(),
                Visibility(
                    visible: _hasReactions,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(_reactionsCountLabel, style: Styles().textStyles.getTextStyle("widget.button.title.small")),
                    ))
              ]))
        ]));
  }

  void _onTapReaction() {
    Analytics().logSelect(target: 'Reaction');
    if (!_hasEntityId) {
      return;
    }
    setStateIfMounted(() {
      _loading = true;
    });
    Social().react(entityId: widget.entityId!, source: widget.reactionSource).then((succeeded) {
      if (succeeded) {
        _loadReactions();
      } else {
        setStateIfMounted(() {
          _loading = false;
        });
        AppAlert.showDialogResult(
            context, Localization().getStringEx('widget.group.card.reaction.failed.msg', 'Failed to react. Please, try again.'));
      }
    });
  }

  void _onLongPressReactions() {
    if (!_hasReactions) {
      return;
    }
    Analytics().logSelect(target: 'Reactions List');

    List<Widget> reactions = [];
    for (Reaction reaction in _reactions!) {
      reactions.add(Padding(
        padding: const EdgeInsets.only(bottom: 24.0, left: 8.0, right: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Currently we have only likes
            Styles().images.getImage('thumbs-up-filled', size: 24, fit: BoxFit.fill, excludeFromSemantics: true) ?? Container(),
            Container(width: 16),
            Text(StringUtils.ensureNotEmpty(reaction.engagerName), style: Styles().textStyles.getTextStyle("widget.title.regular.fat")),
          ],
        ),
      ));
    }

    showModalBottomSheet(
        context: context,
        backgroundColor: Styles().colors.surface,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)),),
        builder: (context) {
          return Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 24),
            height: MediaQuery.of(context).size.height / 2,
            child: Column(
              children: [
                Container(width: 60, height: 8, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Styles().colors.textDisabled)),
                Container(height: 16),
                Expanded(
                  child: ListView(
                    children: reactions,
                  ),
                ),
              ],
            ),
          );
        });
  }

  void _loadReactions() {
    if (!_hasEntityId) {
      return;
    }
    setStateIfMounted(() {
      _loading = true;
    });
    Social().loadReactions(entityId: widget.entityId!, source: widget.reactionSource).then((result) {
      setStateIfMounted(() {
        _loading = false;
        _reactions = result;
      });
    });
  }

  int get _reactionsCount => (_reactions?.length ?? 0);

  bool get _hasReactions => (_reactionsCount > 0);

  String get _reactionsCountLabel {
    return _hasReactions ? _reactionsCount.toString() : '';
  }

  bool get _isCurrentUserReacted {
    if (_hasReactions) {
      for (Reaction reaction in _reactions!) {
        if (reaction.isCurrentUserReacted) {
          return true;
        }
      }
    }
    return false;
  }

  bool get _hasEntityId => (widget.entityId != null);
}

typedef void OnBodyChangedListener(String text);

class PostInputField extends StatefulWidget{
  final EdgeInsets? padding;
  final String? hint;
  final String? text;
  final OnBodyChangedListener? onBodyChanged;

  const PostInputField({Key? key, this.padding, this.hint, this.text, this.onBodyChanged}) : super(key: key);
  
  @override
  State<StatefulWidget> createState() {
    return _PostInputFieldState();
  }
}

class _PostInputFieldState extends State<PostInputField>{ //TBD localize properly
  TextEditingController _bodyController = TextEditingController();
  TextEditingController _linkTextController = TextEditingController();
  TextEditingController _linkUrlController = TextEditingController();
  
  EdgeInsets? _padding;
  String? _hint;

  @override
  void initState() {
    super.initState();
    _padding = widget.padding ?? EdgeInsets.only(top: 5);
    _hint = widget.hint ?? Localization().getStringEx("panel.group.detail.post.reply.create.body.field.hint", "Write a Reply ...");
    _bodyController.text = widget.text ?? "";
  }
  
  @override
  void dispose() {
    super.dispose();
    _bodyController.dispose();
    _linkTextController.dispose();
    _linkUrlController.dispose();
  }

  @override
  void didUpdateWidget(PostInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    String? oldBodyInitialText = oldWidget.text;
    String? newBodyInitialText = widget.text;
    if (oldBodyInitialText != newBodyInitialText) {
      _bodyController.text = StringUtils.ensureNotEmpty(newBodyInitialText);
      if (mounted) {
        setState(() {});
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
          children: [
            Padding(
                padding: _padding!,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Styles().images.getImage('bold-dark', semanticLabel: 'Bold') ?? Container(),
                        onPressed: _onTapBold),
                      Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: IconButton(
                              icon: Styles().images.getImage('italic-dark', semanticLabel: 'Italic') ?? Container(),
                              onPressed: _onTapItalic)),
                      Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: IconButton(
                              icon: Styles().images.getImage('underline-dark', semanticLabel: 'Underline') ?? Container(),
                              onPressed: _onTapUnderline)),
                      Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Semantics(button: true, child:
                          GestureDetector(
                              onTap: _onTapEditLink,
                              child: Text(
                                  Localization().getStringEx(
                                      'panel.group.detail.post.create.link.label',
                                      'Link'),
                                  style: Styles().textStyles.getTextStyle('widget.group.input_field.link')))))
                    ])),
            Padding(
                padding: EdgeInsets.only(top: 8, bottom: 16),
                child: TextField(
                    controller: _bodyController,
                    onChanged: _notifyChanged,
                    maxLines: 15,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                        hintText: _hint,
                        hintStyle: Styles().textStyles.getTextStyle("widget.input_field.hint.regular"),
                        fillColor: Styles().colors.surface,
                        filled: true,
                        border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Styles().colors.mediumGray,
                                width: 0.0))),
                    style: Styles().textStyles.getTextStyle('widget.input_field.text.regular'))),
          ],
        )
    );
  }

  void _notifyChanged(String text) {
    if (widget.onBodyChanged != null) {
      widget.onBodyChanged!(text);
    }
  }

  //HTML Body input Actions
  void _onTapBold() {
    Analytics().logSelect(target: 'Bold');
    _wrapBodySelection('<b>', '</b>');
  }

  void _onTapItalic() {
    Analytics().logSelect(target: 'Italic');
    _wrapBodySelection('<i>', '</i>');
  }

  void _onTapUnderline() {
    Analytics().logSelect(target: 'Underline');
    _wrapBodySelection('<u>', '</u>');
  }

  void _onTapEditLink() {
    Analytics().logSelect(target: 'Edit Link');
    int linkStartPosition = _bodyController.selection.start;
    int linkEndPosition = _bodyController.selection.end;
    _linkTextController.text = StringUtils.ensureNotEmpty(_bodyController.selection.textInside(_bodyController.text));
    AppAlert.showCustomDialog(
        context: context,
        contentWidget: _buildLinkDialog(),
        actions: [
          TextButton(
              onPressed: () {
                Analytics().logSelect(target: 'Set Link Url');
                _onTapOkLink(linkStartPosition, linkEndPosition);
              },
              child: Text(Localization().getStringEx('dialog.ok.title', 'OK'))),
          TextButton(
              onPressed: () {
                Analytics().logSelect(target: 'Cancel');
                Navigator.of(context).pop();
              },
              child: Text(
                  Localization().getStringEx('dialog.cancel.title', 'Cancel')))
        ]);
  }

  void _onTapOkLink(int startPosition, int endPosition) {
    Navigator.of(context).pop();
    if ((startPosition < 0) || (endPosition < 0)) {
      return;
    }
    String linkText = _linkTextController.text;
    _linkTextController.text = '';
    String linkUrl = _linkUrlController.text;
    _linkUrlController.text = '';
    String currentText = _bodyController.text;
    currentText =
        currentText.replaceRange(startPosition, endPosition, linkText);
    _bodyController.text = currentText;
    endPosition = startPosition + linkText.length;
    _wrapBody('<a href="$linkUrl">', '</a>', startPosition, endPosition);
  }

  void _wrapBodySelection(String firstValue, String secondValue) {
    int startPosition = _bodyController.selection.start;
    int endPosition = _bodyController.selection.end;
    if ((startPosition < 0) || (endPosition < 0)) {
      return;
    }
    _wrapBody(firstValue, secondValue, startPosition, endPosition);
  }

  void _wrapBody(String firstValue, String secondValue, int startPosition,
      int endPosition) {
    String currentText = _bodyController.text;
    String result = StringUtils.wrapRange(
        currentText, firstValue, secondValue, startPosition, endPosition);
    _bodyController.text = result;
    _bodyController.selection = TextSelection.fromPosition(
        TextPosition(offset: (endPosition + firstValue.length)));
    _notifyChanged(result);
  }
  
  //Dialog
  Widget _buildLinkDialog() {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              Localization().getStringEx(
                  'panel.group.detail.post.create.dialog.link.edit.header',
                  'Edit Link'),
              style: Styles().textStyles.getTextStyle('widget.group.input_field.heading')),
          Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                  Localization().getStringEx(
                      'panel.group.detail.post.create.dialog.link.text.label',
                      'Link Text:'),
                  style: Styles().textStyles.getTextStyle('widget.group.input_field.detail'))),
          Padding(
              padding: EdgeInsets.only(top: 6),
              child: TextField(
                  controller: _linkTextController,
                  maxLines: 1,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Styles().colors.mediumGray, width: 0.0))),
                  style: Styles().textStyles.getTextStyle('widget.input_field.text.regular'))),
          Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                  Localization().getStringEx(
                      'panel.group.detail.post.create.dialog.link.url.label',
                      'Link URL:'),
                  style: Styles().textStyles.getTextStyle('widget.group.input_field.detail'))),
          Padding(
              padding: EdgeInsets.only(top: 6),
              child: TextField(
                  controller: _linkUrlController,
                  maxLines: 1,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Styles().colors.mediumGray, width: 0.0))),
                  style: Styles().textStyles.getTextStyle('widget.input_field.text.regular')))
        ]);
  }
}

class GroupMembersSelectionWidget extends StatefulWidget{
  final String? groupId;
  final GroupPrivacy? groupPrivacy;
  final List<Member>? allMembers;
  final List<Member>? selectedMembers;
  final void Function(List<Member>?)? onSelectionChanged;
  final bool enabled;

  const GroupMembersSelectionWidget({Key? key, this.selectedMembers, this.allMembers,this.onSelectionChanged, this.groupId, this.groupPrivacy, this.enabled = true}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupMembersSelectionState();

  //When we work with Update post the member stored in the post came with less populated fields and they do not match the == operator
  static List<Member>? constructUpdatedMembersList({List<String>? selectedAccountIds, List<Member>? upToDateMembers}) {
    if (CollectionUtils.isNotEmpty(selectedAccountIds) && CollectionUtils.isNotEmpty(upToDateMembers)) {
      return upToDateMembers!.where((member) => selectedAccountIds!.any((memberAccountId) => memberAccountId == member.userId)).toList();
    }
    return null;
  }
}

class _GroupMembersSelectionState extends State<GroupMembersSelectionWidget>{
  List<Member>? _allMembersAllowedToPost;

  @override
  void initState() {
    super.initState();
    _initAllMembersAllowedToPost();
  }

  @override
  Widget build(BuildContext context) {
    String selectedMembers = selectedMembersText;
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("To: ", style: Styles().textStyles.getTextStyle('widget.title.large.fat'),),
              Expanded(
                child: _buildDropDown(),
              )
            ],
          ),
          Visibility(visible: selectedMembers.isNotEmpty,
            child: GestureDetector(
              onTap: _onTapEdit,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(selectedMembers, style: Styles().textStyles.getTextStyle("widget.group.members.selected_entry"),),
              )
            ),
          ),
          Visibility(
            visible: _showChangeButton,
            child: RoundedButton(label: "Edit", onTap: _onTapEdit,
              textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat.secondary"),
              conentAlignment: MainAxisAlignment.start, contentWeight: 0.33,
              padding: EdgeInsets.all(3), maxBorderRadius: 5,)
          )
        ],
      ),
    );
  }
  
  Widget _buildDropDown(){
    return Container(
        height: 48,
        decoration: BoxDecoration(
            color:  widget.enabled? Colors.white: Styles().colors.background,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(4))),
        child: Padding(
            padding: EdgeInsets.only(left: 10),
            child:
              DropdownButtonHideUnderline(
                // child: ButtonTheme(
                //   alignedDropdown: true,
                  child: Theme(
                    data: ThemeData(
                      canvasColor: Styles().colors.surface,
                    ),
                    child: DropdownButton2<GroupMemberSelectionData>(
                      isExpanded: true,
                      dropdownStyleData: DropdownStyleData(padding: EdgeInsets.zero,
                        decoration: BoxDecoration(border: Border.all(color: Styles().colors.fillColorPrimary, width: 2, style: BorderStyle.solid),
                            borderRadius: BorderRadius.only(bottomRight: Radius.circular(8), bottomLeft: Radius.circular(8))),
                      ),
                      iconStyleData: IconStyleData(icon: widget.enabled? Icon(Icons.arrow_drop_down): Container(),
                          iconEnabledColor: Styles().colors.fillColorSecondary),
                      // buttonDecoration: widget.enabled? null : BoxDecoration(color: Styles().colors.background),
                      // style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 20, fontFamily: Styles().fontFamilies.bold),
                      // value: _currentSelection,
                      items: _buildDropDownItems,
                      hint: Text(_selectionText,  style: widget.enabled ? Styles().textStyles.getTextStyle('widget.group.members.title') : Styles().textStyles.getTextStyle('widget.title.medium.fat'),),
                      onChanged: widget.enabled? (GroupMemberSelectionData? data) {
                        _onDropDownItemChanged(data);
                      } : null,
                                    ),
                  )))
              // )
    );
  }

  List<DropdownMenuItem<GroupMemberSelectionData>> get _buildDropDownItems {
    List<DropdownMenuItem<GroupMemberSelectionData>> items = [];

    items.add(DropdownMenuItem(alignment: AlignmentDirectional.topCenter,enabled: false, value: null,
        child:
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
            Expanded(child:
              Container(color: Styles().colors.surface,
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                child:Text("Select Recipient(s)", style:  Styles().textStyles.getTextStyle('widget.group.members.dropdown.item'),))
                    )
                    ]))
    );
    items.add(DropdownMenuItem(value: GroupMemberSelectionData(type: GroupMemberSelectionDataType.Selection, selection: null), child: _buildDropDownItemLayout("All Members")));
    items.add(DropdownMenuItem(value: GroupMemberSelectionData(type: GroupMemberSelectionDataType.PerformNewSelection, selection: null) , child: _buildDropDownItemLayout("Select Members")));

    //Stored Selections
    List<List<Member>>? storedSelections = _storedMembersSelections;
    if(CollectionUtils.isNotEmpty(storedSelections)){
      items.add(DropdownMenuItem(enabled: false ,value: null, child: _buildDropDownHeaderLayout("RECENTLY USED")));
      storedSelections!.reversed.forEach((selection){
        items.add(DropdownMenuItem(value: GroupMemberSelectionData(type: GroupMemberSelectionDataType.Selection, selection: selection, requiresValidation: true), child: _buildDropDownItemLayout(constructSelectionTitle(selection))));
      });
    }

    return items;
  }

  Widget _buildDropDownHeaderLayout(String title){
    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Expanded(
              child:Container(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text(title, maxLines: 2, style: Styles().textStyles.getTextStyle('widget.group.members.dropdown.item'))
              ))
        ]
    );
  }

  Widget _buildDropDownItemLayout(String title){
    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Expanded(
            child:Container(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: Text(title, maxLines: 2, style: Styles().textStyles.getTextStyle('widget.group.members.dropdown.item.selected') ,)
          ))
      ]
    );
  }

  void _onDropDownItemChanged(GroupMemberSelectionData? data){
    if(data != null){
      switch (data.type){
        case GroupMemberSelectionDataType.Selection:
          List<String>? selectedMemberAccountIds = MemberExt.extractUserIds(data.selection);
          _onSelectionChanged(data.requiresValidation?
              /*Trim Members which are no longer present*/
            GroupMembersSelectionWidget.constructUpdatedMembersList(selectedAccountIds: selectedMemberAccountIds, upToDateMembers: _allMembersAllowedToPost) :
              data.selection);
          break;
        case GroupMemberSelectionDataType.PerformNewSelection:
          _onTapEdit();
          break;
      }
    }
  }

  // List<Member>? _validateSelection(List<Member>? selection, List<Member>? availableMembers){
  //   if(CollectionUtils.isNotEmpty(selection) && CollectionUtils.isNotEmpty(availableMembers)){
  //     return selection!.where((selectedMember) => availableMembers!.contains(selectedMember)).toList();
  //   }
  //
  //   return selection;
  // }

  void _onTapEdit(){
    Analytics().logSelect(target: "Edit Members");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMembersSelectionPanel(allMembers: _allMembersAllowedToPost, selectedMembers: widget.selectedMembers, groupId: widget.groupId, groupPrivacy: widget.groupPrivacy))).then((result) {
      _onSelectionChanged(result);
    });
  }

  void _onSelectionChanged(List<Member>? selection){
    if(widget.onSelectionChanged!=null){
      widget.onSelectionChanged!(selection);
    }
  }

  void _initAllMembersAllowedToPost(){
    if(widget.allMembers!=null){
      _allMembersAllowedToPost = widget.allMembers;
    } else if(widget.groupId!=null) {
      _loadAllMembersAllowedToPost();
    }
  }

  void _loadAllMembersAllowedToPost() {
    Groups().loadMembersAllowedToPost(groupId: widget.groupId).then((members) {
      if (mounted && CollectionUtils.isNotEmpty(members)) {
        List<String>? selectedAccountIds = MemberExt.extractUserIds(widget.selectedMembers);
        setState(() {
            _allMembersAllowedToPost = members;
            if((_allMembersAllowedToPost?.isNotEmpty ?? false) && (widget.selectedMembers?.isNotEmpty ?? false)){
              //If we have successfully loaded the group data -> refresh initial selection
               _onSelectionChanged(GroupMembersSelectionWidget.constructUpdatedMembersList(upToDateMembers: _allMembersAllowedToPost, selectedAccountIds: selectedAccountIds)); //Notify Parent widget with the updated values
            }
        });
      }
    });
  }

  List<List<Member>>? get _storedMembersSelections{
    Map<String, List<List<Member>>>? selectionsTable = Storage().groupMembersSelection;
    if(selectionsTable!=null && widget.groupId!=null){
      return selectionsTable[widget.groupId!];
    }

    return null;
  }

  static String constructSelectionTitle(List<Member>? selection){
    String result = "";
    if(CollectionUtils.isNotEmpty(selection)){
      selection!.forEach((member) {
        result += ((result.isNotEmpty) ? ", " : "");
        result += member.displayShortName;
      });
    }
    return result;
  }
  
  String get _selectionText{
    if(CollectionUtils.isNotEmpty(widget.selectedMembers)){
      return "Selected Members (${widget.selectedMembers?.length ?? 0})";
    } else {
      return "All Members (${_allMembersAllowedToPost?.length ?? 0})";
    }
  }

  String get selectedMembersText{
    return constructSelectionTitle(widget.selectedMembers);
  }

  bool get _showChangeButton{
    return false; //Remove entire button if we are sure that we are not gonna use it anymore.
    // return CollectionUtils.isNotEmpty(widget.selectedMembers) && widget.enabled;
  }

}
enum GroupMemberSelectionDataType {Selection, PerformNewSelection}
class GroupMemberSelectionData {
  final GroupMemberSelectionDataType type;
  final List<Member>? selection;
  final bool requiresValidation;

  GroupMemberSelectionData({required this.type, required this.selection, this.requiresValidation = false});
}

typedef void OnImageChangedListener(String? imageUrl);
class ImageChooserWidget extends StatefulWidget{ //TBD Localize properly
  final String? imageUrl;
  final bool wrapContent;
  final bool showSlant;
  final bool buttonVisible;
  final OnImageChangedListener? onImageChanged;
  final String? imageSemanticsLabel;

  const ImageChooserWidget({Key? key, this.imageUrl, this.onImageChanged, this.wrapContent = false, this.showSlant = true, this.buttonVisible = false, this.imageSemanticsLabel}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ImageChooserState();
}

class _ImageChooserState extends State<ImageChooserWidget>{

  @override
  Widget build(BuildContext context) {
    final double _imageHeight = 200;
    bool wrapContent = widget.wrapContent;
    bool explicitlyShowAddButton = widget.buttonVisible;
    bool showSlant = widget.showSlant;
    String? imageUrl = widget.imageUrl; // For some reason sometimes the widget url is present but the _imageUrl is null

    return Container(
        constraints: BoxConstraints(
          maxHeight: (imageUrl!=null || !wrapContent)? _imageHeight : (double.infinity),
        ),
        color: Styles().colors.background,
        child: Stack(alignment: Alignment.bottomCenter, children: <Widget>[
          StringUtils.isNotEmpty(imageUrl)
              ? Positioned.fill(child: ModalImageHolder(child: Image.network(imageUrl!, semanticLabel: widget.imageSemanticsLabel??"", fit: BoxFit.cover)))
              : Container(),
          StringUtils.isEmpty(imageUrl) || explicitlyShowAddButton
              ? Container(
              child: Center(
                  child: Semantics(
                      label: Localization().getStringEx("panel.group.detail.post.add_image", "Add cover image"),
                      hint: Localization().getStringEx("panel.group.detail.post.add_image.hint", ""),
                      button: true,
                      excludeSemantics: true,
                      child: RoundedButton(
                          label:StringUtils.isEmpty(imageUrl)? Localization().getStringEx("panel.group.detail.post.add_image", "Add image") : Localization().getStringEx("panel.group.detail.post.change_image", "Edit Image"), // TBD localize
                          textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                          contentWeight: 0.8,
                          onTap: (){ _onTapAddImage();}
                      )))):
          Container()
        ]));
  }

  void _onTapAddImage() async {
    Analytics().logSelect(target: "Add Image");
    ImagesResult? result = await GroupAddImageWidget.show(context: context, url: widget.imageUrl).then((result) => result);

    if(result?.succeeded == true) {
      widget.onImageChanged?.call(result?.imageUrl);
      // setStateIfMounted(() {
      //   _imageUrl = result?.stringData;
      // });
      Log.d("Image Url: ${result?.imageUrl}");
    }
  }
}

/////////////////////////////////////
// GroupMemberProfileImage

class GroupMemberProfileImage extends StatefulWidget {
  final String? userId;
  final GestureTapCallback? onTap;

  GroupMemberProfileImage({this.userId, this.onTap});

  @override
  State<GroupMemberProfileImage> createState() => _GroupMemberProfileImageState();
}

class _GroupMemberProfileImageState extends State<GroupMemberProfileImage> implements NotificationsListener {
  Uint8List? _imageBytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, Content.notifyUserProfilePictureChanged);
    _loadImage();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    bool hasProfilePhoto = (_imageBytes != null);
    Widget? profileImage = hasProfilePhoto
        ? Container(decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(fit: (hasProfilePhoto ? BoxFit.cover : BoxFit.contain), image: Image.memory(_imageBytes!).image)))
        : Styles().images.getImage('profile-placeholder', excludeFromSemantics: true);

    return GestureDetector(
        onTap: widget.onTap ?? _onImageTap,
        child: Stack(alignment: Alignment.center, children: [
          if (profileImage != null) profileImage,
          Visibility(
              visible: _loading,
              child: SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 2)))
        ]));
  }

  void _loadImage() {
    if (StringUtils.isNotEmpty(widget.userId)) {
      _setImageLoading(true);
      Content().loadUserPhoto(accountId: widget.userId, type: UserProfileImageType.small).then((ImagesResult? imageResult) {
        _imageBytes = imageResult?.imageData;
        _setImageLoading(false);
      });
    }
  }

  void _onImageTap() {
    Analytics().logSelect(target: "Group Member Image");
    if (_imageBytes != null) {
      String? imageUrl = Content().getUserPhotoUrl(accountId: widget.userId, type: UserProfileImageType.defaultType);
      if (StringUtils.isNotEmpty(imageUrl)) {
        Navigator.push(context, PageRouteBuilder(opaque: false, pageBuilder: (context, _, __) => ModalImagePanel(imageUrl: imageUrl!, networkImageHeaders: Auth2().networkAuthHeaders, onCloseAnalytics: () => Analytics().logSelect(target: "Close Group Member Image"))));
      }
    }
  }

  void _setImageLoading(bool loading) {
    if (_loading != loading) {
      _loading = loading;
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Notifications

  @override
  void onNotification(String name, param) {
    if (name == Content.notifyUserProfilePictureChanged) {
      // If it's current user - reload profile picture
      if (widget.userId == Auth2().accountId) {
        _loadImage();
      }
    }
  }
}

class GroupsSelectionPopup extends StatefulWidget {
  final List<Group>? groups;

  final String? title;
  final String? description;


  GroupsSelectionPopup({super.key, this.groups, this.title, this.description});

  String get _displayTitle => title ?? _defaultTitle;
  String get _displayDescription => description ?? _defaultDescription;

  static final String _defaultTitle = Localization().getStringEx("widget.groups.post.selection.heading", "Select Group");
  static final String _defaultDescription = Localization().getStringEx("widget.groups.post.selection.message", "Also send this post to these selected groups:");

  @override
  _GroupsSelectionPopupState createState() => _GroupsSelectionPopupState();
}

class _GroupsSelectionPopupState extends State<GroupsSelectionPopup> {
  Set<String> _selectedGroupIds = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(contentPadding: EdgeInsets.zero, scrollable: false, content:
    Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Container(
          decoration: BoxDecoration(
            color: Styles().colors.fillColorPrimary,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
          ),
          child: Row(children: <Widget>[
            Opacity(opacity: 0, child:
              Padding(padding: EdgeInsets.all(8), child:
                Styles().images.getImage('close-circle-white', excludeFromSemantics: true)
              )
            ),
            Expanded(child:
              Padding(padding: EdgeInsets.symmetric(vertical: 10), child:
                Text(widget._displayTitle, textAlign: TextAlign.center,
                    style: Styles().textStyles.getTextStyle("widget.dialog.message.large.thin")
                )
              )
            ),
            Semantics(button: true, label: Localization().getStringEx("dialog.close.title","Close"), child:
              InkWell(onTap: _onTapClose, child:
                Padding(padding: EdgeInsets.only(top: 8, bottom: 8, left: 4, right: 12), child:
                  Styles().images.getImage('close-circle-white', excludeFromSemantics: true)
                )
              )
            )
          ])
      ),
      Padding(padding: EdgeInsets.all(10), child: _buildGroupsList()),

      Semantics(container: true, child:
      Container(
          // constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height / 4 ),
          padding: EdgeInsets.all(10), child:
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _onTapSelectAll,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          child: Text( Localization().getStringEx('dialog.select_all.title', 'Select All'),
                            style:  Styles().textStyles.getTextStyle("widget.button.title.medium.fat.underline")),
                      )
                    )
                  ),

                  Expanded(child:
                  Row(
                    children: [
                      Expanded(child: Container()),
                      Container(child:InkWell(
                        onTap: _onTapClearSelection,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          child:Text(Localization().getStringEx('dialog.deselect_all.title', 'Deselect All'),
                            textAlign: TextAlign.left,
                            style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.underline"))),

                      ))
                    ],
                  )),
                ],
              ),
            Container(height: 12,),
            Row(
              mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                  child: RoundedButton(
                      label: Localization().getStringEx("widget.groups.selection.button.send.label", "Send"),//TBD localize
                      textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                      borderColor: Styles().colors.fillColorSecondary,
                      backgroundColor: Styles().colors.surface,
                      onTap: _onTapSelect
                  )),
                  Container(width: 16,),
                  Expanded(child:RoundedButton(
                      label: Localization().getStringEx("widget.groups.selection.button.cancel.label", "Cancel"),//TBD localize
                      textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                      borderColor: Styles().colors.fillColorPrimary,
                      backgroundColor: Styles().colors.surface,
                      onTap: _onTapClose
                  ))
                ],
              )
          ],
        )
      )
      )
    ]));
  }

  Widget _buildGroupsList() {
    double screenHeight = MediaQuery.of(context).size.height;
    double maxListHeight = screenHeight>0 ? screenHeight/2 : 100;

    if (CollectionUtils.isEmpty(widget.groups)) {
      return Container();
    }
    List<Widget> groupWidgetList = [];

    groupWidgetList.add(Container(
      padding: EdgeInsets.symmetric(vertical: 12), //TBD localize
      child: Text(widget._displayDescription, textAlign: TextAlign.center,
          style: Styles().textStyles.getTextStyle("widget.message.regular.fat")),
    ),);

    for (Group group in widget.groups!) {
      if (group.id != null) {
        groupWidgetList.add(ToggleRibbonButton(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
            label: group.title,
            toggled: _selectedGroupIds.contains(group.id),
            onTap: () => _onTapGroup(group.id!),
            textStyle:  Styles().textStyles.getTextStyle("widget.button.title.medium.fat.dark")
        ));
      }

    }
    return Container(constraints: BoxConstraints(maxHeight: maxListHeight), child:SingleChildScrollView(child:Column(children: groupWidgetList)));
  }

  void _onTapGroup(String groupId) {
    if (mounted) {
      setState(() {
        if (_selectedGroupIds.contains(groupId)) {
          _selectedGroupIds.remove(groupId);
        } else {
          _selectedGroupIds.add(groupId);
        }
      });
    }
  }

  void _onTapSelect() {
    List<Group>? selectedGroups = [];
    if (widget.groups != null) {
      for (Group group in widget.groups!) {
        if (_selectedGroupIds.contains(group.id)) {
          selectedGroups.add(group);
        }
      }
    }
    Navigator.of(context).pop(selectedGroups);
  }

  void _onTapSelectAll(){
    if (CollectionUtils.isNotEmpty(widget.groups)) {
      _clearSelection();
      for (Group group in widget.groups!) {
        if (group.id != null) {
          _selectedGroupIds.add(group.id!);
        }
      }
      if(mounted){
        setState(() {

        });
      }
    }

  }

  void _onTapClearSelection(){
    _clearSelection();
    if(mounted){
      setState(() {

      });
    }
  }

  void _clearSelection(){
    _selectedGroupIds = {};
  }

  void _onTapClose() {
    Navigator.of(context).pop(<Group>[]);
  }
}

class EnabledToggleButton extends ToggleRibbonButton {
  final bool? enabled;

  EnabledToggleButton(
      {String? label,
        bool? toggled,
        void Function()? onTap,
        BoxBorder? border,
        BorderRadius? borderRadius,
        TextStyle? textStyle,
        this.enabled})
      : super(label: label, toggled: (toggled == true), onTap: onTap, border: border, borderRadius: borderRadius, textStyle: textStyle);

  @override
  bool get toggled => (enabled == true) && super.toggled;

  @override
  Widget? get rightIconImage => Styles().images.getImage(toggled ? 'toggle-on' : 'toggle-off');  //Workaround for blurry images
}

class GroupMemberSettingsLayout extends StatelessWidget{
  final GroupSettings? settings;
  final Function? onChanged;

  const GroupMemberSettingsLayout({Key? key, this.settings, this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: settings!=null?
        _buildSettingsLayout() :
        Container(),
    );
  }

  Widget _buildSettingsLayout() {
    List<Widget> preferenceWidgets = [];
    MemberPostPreferences? groupPostSettings = settings?.memberPostPreferences;
    MemberInfoPreferences? groupInfoSettings = settings?.memberInfoPreferences;

    bool isGroupPostAllowed = groupPostSettings?.allowSendPost ?? true; // true by default
    bool isGroupInfoAllowed = groupInfoSettings?.allowMemberInfo ?? true; // true by default

    //Info
    preferenceWidgets.add(
        Container(
          padding: EdgeInsets.all(1),
          decoration:  BoxDecoration(color: Styles().colors.surface, border: Border.all(color: Styles().colors.surfaceAccent, width: 1), borderRadius:  BorderRadius.all(Radius.circular(4))),
          child: Column(
            children: [
              EnabledToggleButton(
                  enabled: true,
                  borderRadius: BorderRadius.zero,
                  label: Localization().getStringEx("panel.groups_create.settings.enable_member_info.label", "View Other Members"),
                  toggled: isGroupInfoAllowed,
                  onTap: (){_onSettingsTap(
                      changeSetting: (){ settings?.memberInfoPreferences?.allowMemberInfo =  !(settings?.memberInfoPreferences?.allowMemberInfo ?? true);}
                  );},
                  textStyle: isGroupInfoAllowed
                      ? Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.fat.enabled")
                      : Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.fat.disabled")),
              Row(children: [
                Expanded(
                    child: Container(
                        color: Styles().colors.surface,
                        child: Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Column(children: [
                              EnabledToggleButton(
                                  enabled: isGroupInfoAllowed,
                                  borderRadius: BorderRadius.zero,
                                  label: Localization().getStringEx("panel.groups_create.settings.allow_info_net_id.label", "View University ID (NetID)"), //TBD localize section
                                  toggled: (settings?.memberInfoPreferences?.viewMemberNetId ?? false),
                                  onTap: (){_onSettingsTap(
                                      changeSetting: (){if(isGroupInfoAllowed == true) {settings?.memberInfoPreferences?.viewMemberNetId = !(settings?.memberInfoPreferences?.viewMemberNetId ?? false);}}
                                  );},
                                  textStyle: isGroupInfoAllowed
                                      ? Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.enabled")
                                      : Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.disabled")),
                             //Hide View Name. We will always want to show the name, so just keep it as true and just hide it so it cannot be changed.
                              /*EnabledToggleButton(
                                  enabled: isGroupInfoAllowed,
                                  borderRadius: BorderRadius.zero,
                                  label: Localization().getStringEx("panel.groups_create.settings.allow_view_name.label", "View Name"),
                                  toggled: (settings?.memberInfoPreferences?.viewMemberName ?? false),
                                  onTap: (){
                                    _onSettingsTap(
                                        changeSetting: (){ if(isGroupInfoAllowed == true) {settings?.memberInfoPreferences?.viewMemberName =  !(settings?.memberInfoPreferences?.viewMemberName ?? false);}}
                                    );},
                                  textStyle: isGroupInfoAllowed
                                      ? Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.enabled")
                                      : Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.disabled")),*/
                              EnabledToggleButton(
                                  enabled: isGroupInfoAllowed,
                                  borderRadius: BorderRadius.zero,
                                  label: Localization().getStringEx("panel.groups_create.settings.allow_view_email.label", "View Email Address"),
                                  toggled: (settings?.memberInfoPreferences?.viewMemberEmail ?? false),
                                  onTap: (){_onSettingsTap(
                                      changeSetting: (){  if(isGroupInfoAllowed == true) {settings?.memberInfoPreferences?.viewMemberEmail =  !(settings?.memberInfoPreferences?.viewMemberEmail ?? false);}}
                                  );},
                                  textStyle: isGroupInfoAllowed
                                      ? Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.enabled")
                                      : Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.disabled")),
                              //Hide Phone for now
                              // EnabledToggleButton(
                              //     enabled: isGroupInfoAllowed,
                              //     borderRadius: BorderRadius.zero,
                              //     label: Localization().getStringEx("panel.groups_create.settings.allow_view_phone.label", "View Phone"),
                              //     toggled: (settings?.memberInfoPreferences?.viewMemberPhone ?? false),
                              //     onTap: (){_onSettingsTap(
                              //         changeSetting: (){ if(isGroupInfoAllowed == true) {settings?.memberInfoPreferences?.viewMemberPhone =  !(settings?.memberInfoPreferences?.viewMemberPhone ?? false);}}
                              //     );},
                              //     textStyle: isGroupInfoAllowed
                              //         ? Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.enabled")
                              //         : Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.disabled")),
                            ]))))
              ])
        ],
      ),
    ));

    preferenceWidgets.add(Container(height: 8,));
    //Post
    preferenceWidgets.add(Container(
        padding: EdgeInsets.all(1),
        decoration:  BoxDecoration(color: Styles().colors.surface, border: Border.all(color: Styles().colors.surfaceAccent, width: 1), borderRadius:  BorderRadius.all(Radius.circular(4))),
        child: Column(
            children: [
              EnabledToggleButton(
                  enabled: true,
                  borderRadius: BorderRadius.zero,
                  label: Localization().getStringEx("panel.groups_create.settings.enable_post.label", "Member Posts"),
                  toggled: isGroupPostAllowed,
                  onTap: (){_onSettingsTap(
                      changeSetting: (){settings?.memberPostPreferences?.allowSendPost =  !(settings?.memberPostPreferences?.allowSendPost ?? true);}
                  );},
                  textStyle: isGroupPostAllowed
                      ? Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.fat.enabled")
                      : Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.fat.disabled")),
              Row(children: [
                Expanded(
                    child: Container(
                        color: Styles().colors.surface,
                        child: Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Column(children: [
                              EnabledToggleButton(
                                  enabled: (isGroupPostAllowed == true && isGroupInfoAllowed == true),
                                  borderRadius: BorderRadius.zero,
                                  label: Localization().getStringEx("panel.groups_create.posts_to_members.label", "Send posts to specific members"), //TBD localize section
                                  toggled: (settings?.memberPostPreferences?.sendPostToSpecificMembers ?? false),
                                  onTap: (){_onSettingsTap(
                                      changeSetting: (){ if(isGroupPostAllowed == true && isGroupInfoAllowed == true) {settings?.memberPostPreferences?.sendPostToSpecificMembers =  !(settings?.memberPostPreferences?.sendPostToSpecificMembers ?? false);}}
                                  );},
                                  textStyle: (isGroupPostAllowed == true && isGroupInfoAllowed == true)
                                      ? Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.enabled")
                                      : Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.disabled")),
                              EnabledToggleButton(
                                  enabled: isGroupPostAllowed,
                                  borderRadius: BorderRadius.zero,
                                  label: Localization().getStringEx("panel.groups_create.posts_to_admins.label", "Send posts to admins"),
                                  toggled: (settings?.memberPostPreferences?.sendPostToAdmins ?? false),
                                  onTap: (){_onSettingsTap(
                                      changeSetting: (){ if(isGroupPostAllowed == true) {settings?.memberPostPreferences?.sendPostToAdmins =  !(settings?.memberPostPreferences?.sendPostToAdmins ?? false);}}
                                  );},
                                  textStyle: isGroupPostAllowed
                                      ? Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.enabled")
                                      : Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.disabled")),
                              EnabledToggleButton(
                                  enabled: isGroupPostAllowed,
                                  borderRadius: BorderRadius.zero,
                                  label: Localization().getStringEx("panel.groups_create.posts_to_all.label", "Send posts to all members"),
                                  toggled: (settings?.memberPostPreferences?.sendPostToAll ?? false),
                                  onTap: (){_onSettingsTap(
                                      changeSetting: (){ if(isGroupPostAllowed == true) {settings?.memberPostPreferences?.sendPostToAll =  !(settings?.memberPostPreferences?.sendPostToAll ?? false);}}
                                  );},
                                  textStyle: isGroupPostAllowed
                                      ? Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.enabled")
                                      : Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.disabled")),
                              EnabledToggleButton(
                                  enabled: isGroupPostAllowed,
                                  borderRadius: BorderRadius.zero,
                                  label: Localization().getStringEx("panel.groups_create.send_replies.label", "Send replies"),
                                  toggled: (settings?.memberPostPreferences?.sendPostReplies ?? false),
                                  onTap: (){_onSettingsTap(
                                      changeSetting: (){ if(isGroupPostAllowed == true) {settings?.memberPostPreferences?.sendPostReplies =  !(settings?.memberPostPreferences?.sendPostReplies ?? false);}}
                                  );},
                                  textStyle: isGroupPostAllowed
                                      ? Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.enabled")
                                      : Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.disabled")),
                              EnabledToggleButton(
                                  enabled: isGroupPostAllowed,
                                  borderRadius: BorderRadius.zero,
                                  label: Localization().getStringEx("panel.groups_create.posts_to_members.label", "Reactions (emojis) to posts"),
                                  toggled: (settings?.memberPostPreferences?.sendPostReactions ?? false),
                                  onTap: (){_onSettingsTap(
                                      changeSetting: (){ if(isGroupPostAllowed == true) {settings?.memberPostPreferences?.sendPostReactions =  !(settings?.memberPostPreferences?.sendPostReactions ?? false);}}
                                  );},
                                  textStyle: isGroupPostAllowed
                                      ? Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.enabled")
                                      : Styles().textStyles.getTextStyle("panel.group_member_notifications.toggle_button.title.small.disabled")),
                            ]))))
                  ])
    ])));

    preferenceWidgets.add(Container(height: 10,));

    return Container(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: preferenceWidgets));
  }

  void _onSettingsTap({Function? changeSetting}){
    if(changeSetting!=null){
      changeSetting();
      if(onChanged != null){
        onChanged!();
      }
    }
  }

}

class GroupScheduleTimeWidget extends StatefulWidget {
  final Location? timeZone;

  final DateTime? scheduleTime;
  final bool? enabled;
  final bool enableTimeZone;
  final Function(DateTime?)? onDateChanged;

  const GroupScheduleTimeWidget({super.key,  this.timeZone, this.scheduleTime, this.onDateChanged, this.enabled = true, this.enableTimeZone = false,});

  @override
  State<StatefulWidget> createState() => _GroupScheduleTimeState();

}

class _GroupScheduleTimeState extends State<GroupScheduleTimeWidget>{
  bool required = false;
  bool _expanded = false;

  late Location _timeZone;
  DateTime? _date;
  TimeOfDay? _time;

  TZDateTime? get _dateTime => _date!= null ? _dateTimeWithDateAndTimeOfDay(_date!, _time) : null;

  // DateTime? get _dateTimeUtc => _date!=null && _time!=null ?
  //     DateTime.fromMillisecondsSinceEpoch(_dateTimeWithDateAndTimeOfDay(_date!, _time).toUtc().millisecondsSinceEpoch, isUtc: true) : null;
  DateTime? get _dateTimeUtc => _dateTime?.toUtc();

  @override
  void initState() {
    _timeZone = timeZoneDatabase.locations[widget.timeZone] ?? DateTimeLocal.timezoneLocal;
    DateTime? dateTimeUtc = widget.scheduleTime;
    if (dateTimeUtc != null) {
      TZDateTime scheduleTime = TZDateTime.from(dateTimeUtc, _timeZone);
      _date = TZDateTimeUtils.dateOnly(scheduleTime);
      _time = TimeOfDay.fromDateTime(scheduleTime);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: EdgeInsets.only(top: 16), child:
          Text("Schedule: ", style: Styles().textStyles.getTextStyle('widget.group.members.light.title'),)),
        Expanded(child: _buildDropdown())
    ]);
  }

  Widget _buildDropdown(){
    // String title = (_time != null? DateFormat("EEE, MMM dd, h:mma").format(_dateWithTimeOfDay(_time!)) : "");
    DateTime? selectedTime = _dateTime?.toLocal();
    String title = (selectedTime != null? DateFormat("EEE, MMM dd, h:mma").format(selectedTime) : "");

    return Padding(padding: EdgeInsets.zero, child:
    Column(children: <Widget>[
      Container(
        decoration: BoxDecoration(
            color: widget.enabled == true ? Styles().colors.surface : null,
            border: Border.all(color: /*widget.enabled == true ? Styles().colors.mediumGray2 :*/ Styles().colors.surfaceAccent, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(4))
        ),
        child: Column(children: <Widget>[
          Semantics(button: true, label: title,
              child: InkWell(
                onTap: (){
                  if(widget.enabled == true) {
                    setStateIfMounted(() {
                      _expanded = !_expanded;
                    });
                  }
                },
                child: Padding(padding: sectionHeadingContentPadding, child:
                Row(children: [
                  Expanded(child:
                    Semantics ( label: title, child:
                      RichText(text:
                        TextSpan(text: title, style: Styles().textStyles.getTextStyle("widget.title.medium.fat"), semanticsLabel: "", children: required ? <InlineSpan>[
                          TextSpan(text: ' *', style: Styles().textStyles.getTextStyle('widget.label.small.fat'), semanticsLabel: ""),
                  ] : null),
                  ))
                  ),
                  Visibility(visible: widget.enabled == true, child:
                    Padding(padding: EdgeInsets.only(left: 8), child:
                      Styles().images.getImage(_expanded ? 'chevron-up' : 'chevron-down') ?? Container()),)
                ],),
                ),
              )
          ),
          Visibility(visible: _expanded, child:
          Container(decoration: BoxDecoration(border: Border(top: BorderSide(color: Styles().colors.mediumGray2, width: 1))),
            child: Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
            Container(child: buildBody() ??
                Container())
            ),
          ),
          ),
        ],),
      ),
    ]),
    );
  }

  Widget? buildBody() => Column(children: [
      _buildTimeZoneDropdown(),
      Padding(padding: EdgeInsets.only(bottom: 12)),
      Row(
        children: [
          Expanded(flex: 3, child:buildSectionTitleWidget(Localization().getStringEx("", "DATE"),)),
          Expanded(flex: 7, child: _buildDropdownButton(label: (_date != null) ? DateFormat("EEE, MMM dd, yyyy").format(_date!) : "-", onTap: _onDate))
        ],),
      Padding(padding: EdgeInsets.only(bottom: 12)),
      Row(
        children: [
          Expanded(flex: 3, child:buildSectionTitleWidget(Localization().getStringEx("", "TIME"),)),
          Expanded(flex: 7, child: _buildDropdownButton(label: (_time != null) ? DateFormat("h:mma").format(_dateWithTimeOfDay(_time!)) : "-", onTap: _onTime))
      ],)
    ]);

  Widget _buildDropdownButton({String? label, GestureTapCallback? onTap}) {
    return InkWell(onTap: onTap, child:
      Container(decoration: dropdownButtonDecoration, padding: dropdownButtonContentPadding, child:
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Text(label ??  '-', style: Styles().textStyles.getTextStyle("widget.title.regular"),),
          Styles().images.getImage('chevron-down') ?? Container()
        ],),
      ),
    );
  }

  void _onDate() {
    Analytics().logSelect(target: "Date");
    hideKeyboard(context);
    DateTime now = DateUtils.dateOnly(DateTime.now());
    DateTime minDate = now;
    DateTime maxDate = now.add(Duration(days: 366));
    DateTime selectedDate = (_date != null) ? DateTimeUtils.min(DateTimeUtils.max(_date!, minDate), maxDate) : minDate;
    showDatePicker(context: context,
      initialDate: selectedDate,
      firstDate: minDate,
      lastDate: maxDate,
      currentDate: now,
    ).then((DateTime? result) {
      if ((result != null) && mounted) {
        setState(() {
          TZDateTime zoneTime = TZDateTime.from(result, _timeZone);
          _date = DateUtils.dateOnly(zoneTime);
          widget.onDateChanged?.call(_dateTimeUtc);
          // _errorMap = _buildErrorMap(); //TBD handle error
        });
      }
    });
  }

  void _onTime() {
    Analytics().logSelect(target: "Time");
    hideKeyboard(context);
    showTimePicker(context: context, initialTime: _time ?? TimeOfDay(hour: 0, minute: 0)).then((TimeOfDay? result) {
      if ((result != null) && mounted) {
        setState(() {
          _time = result;
          widget.onDateChanged?.call(_dateTimeUtc);
          // _errorMap = _buildErrorMap(); //TBD handle error
        });
      }
    });
  }

  //TIMEZONE
  Widget _buildTimeZoneDropdown(){
    return Visibility(visible: widget.enableTimeZone, child:
      Semantics(container: true, child:
        Row(children: <Widget>[
          Expanded(flex: 4, child:
            buildSectionTitleWidget(Localization().getStringEx("", "TIME ZONE")),
          ),
          Container(width: 16,),
          Expanded(flex: 6, child:
            Container(decoration: dropdownButtonDecoration, child:
              Padding(padding: EdgeInsets.only(left: 12, right: 8), child:
                DropdownButtonHideUnderline(child:
                  DropdownButton<Location>(
                      icon: Styles().images.getImage('chevron-down'),
                      isExpanded: true,
                      style: Styles().textStyles.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                      hint: Text(_timeZone.name,),
                      items: _buildTimeZoneDropDownItems(),
                      onChanged: _onTimeZoneChanged
                  ),
                ),
              ),
            ),
          ),
        ])
      )
    );
  }

  List<DropdownMenuItem<Location>>? _buildTimeZoneDropDownItems() {
    List<DropdownMenuItem<Location>> menuItems = <DropdownMenuItem<Location>>[];
    timeZoneDatabase.locations.forEach((String name, Location location) {
      if (name.startsWith('US/')) {
        menuItems.add(DropdownMenuItem<Location>(
          value: location,
          child: Semantics(label: name, excludeSemantics: true, container:true, child: Text(name, style: headingTextStype)),
        ));
      }
    });

    return menuItems;
  }

  void _onTimeZoneChanged(Location? value) {
    Analytics().logSelect(target: "Time Zone selected: $value");
    hideKeyboard(context);
    if ((value != null) && mounted) {
      setState(() {
        _timeZone = value;
        widget.onDateChanged?.call(_dateTimeUtc);
      });
    }
  }

  DateTime _dateWithTimeOfDay(TimeOfDay time) =>
      _dateTimeWithDateAndTimeOfDay(DateTime.now(), time);

  TZDateTime _dateTimeWithDateAndTimeOfDay(DateTime date, TimeOfDay? time, { bool inclusive = false}) =>
      TZDateTime(_timeZone, date.year, date.month, date.day, time?.hour ?? (inclusive ? 23 : 0), time?.minute ?? (inclusive ? 59 : 0));

  //Common
  static Widget buildSectionTitleWidget(String title, { bool required = false, TextStyle? textStyle, TextStyle? requiredTextStyle,  }) =>
      Semantics ( label: title, child:
        RichText(textScaler: textScaler, text:
          TextSpan(text: title, style: textStyle ?? headingTextStype, semanticsLabel: "", children: required ? <InlineSpan>[
            TextSpan(text: ' *', style: requiredTextStyle ?? Styles().textStyles.getTextStyle('widget.label.small.fat'), semanticsLabel: ""),
          ] : null),
      ));

  static TextStyle? get headingTextStype => Styles().textStyles.getTextStyle("widget.title.dark.small.fat.spaced");

  static const EdgeInsetsGeometry dropdownButtonContentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  static const EdgeInsetsGeometry sectionHeadingContentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14);

  static BoxDecoration get dropdownButtonDecoration => BoxDecoration(
      color: Styles().colors.surface,
      border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
      borderRadius: BorderRadius.all(Radius.circular(4))
  );

  static TextScaler get textScaler {
    BuildContext? context = App.instance?.currentContext;
    return (context != null) ? MediaQuery.of(context).textScaler : TextScaler.noScaling;
  }

  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}
