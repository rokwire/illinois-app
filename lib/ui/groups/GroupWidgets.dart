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

import 'dart:typed_data';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/ext/Event.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/groups/GroupMembersSelectionPanel.dart';
import 'package:illinois/ui/groups/ImageEditPanel.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/geo_fence.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/events/CreateEventPanel.dart';
import 'package:illinois/ui/groups/GroupDetailPanel.dart';
import 'package:illinois/ui/groups/GroupPostDetailPanel.dart';
import 'package:illinois/ui/groups/GroupsEventDetailPanel.dart';
import 'package:illinois/ui/polls/PollProgressPainter.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:illinois/service/Auth2.dart' as illinois;
import 'package:illinois/service/Polls.dart' as illinois;

/////////////////////////////////////
// GroupDropDownButton

typedef GroupDropDownDescriptionDataBuilder<T> = String? Function(T item);

class GroupDropDownButton<T> extends StatefulWidget{
  final String? emptySelectionText;
  final String? buttonHint;

  final T? initialSelectedValue;
  final List<T>? items;
  final GroupDropDownDescriptionDataBuilder<T>? constructTitle;
  final GroupDropDownDescriptionDataBuilder<T>? constructDescription;
  final GroupDropDownDescriptionDataBuilder<T>? constructDropdownDescription;
  final GroupDropDownDescriptionDataBuilder<T>? constructListItemDescription;
  final Function? onValueChanged;
  final bool enabled;

  final EdgeInsets padding;
  final BoxDecoration? decoration;

  GroupDropDownButton({Key? key, this.emptySelectionText,this.buttonHint, this.initialSelectedValue, this.items, this.onValueChanged, this.enabled = true,
    this.constructTitle, this.constructDescription, this.constructDropdownDescription, this.constructListItemDescription, this.padding = const EdgeInsets.only(left: 12, right: 8), this.decoration}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GroupDropDownButtonState<T>();
  }
}

class _GroupDropDownButtonState<T> extends State<GroupDropDownButton>{

  @override
  Widget build(BuildContext context) {
    TextStyle? valueStyle = Styles().textStyles?.getTextStyle("widget.group.dropdown_button.value");
    TextStyle? hintStyle = Styles().textStyles?.getTextStyle("widget.group.dropdown_button.hint");

    String? buttonTitle = _getButtonTitleText();
    String? buttonDescription = _getButtonDescriptionText();
    return Container (
        decoration: widget.decoration != null
            ? widget.decoration
            : BoxDecoration(
            color: Styles().colors!.white,
            border: Border.all(
                color: Styles().colors!.surfaceAccent!,
                width: 1),
            borderRadius:
            BorderRadius.all(Radius.circular(4))),
        padding: widget.padding,
        child:
        Column( crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Semantics(
                container: true,
                label: buttonTitle,
                hint: widget.buttonHint,
                excludeSemantics: true,
                child: Theme(
                  data: ThemeData( /// This is as a workaround to make dropdown backcolor always white according to Miro & Zepplin wireframes
                    hoverColor: Styles().colors!.white,
                    focusColor: Styles().colors!.white,
                    canvasColor: Styles().colors!.white,
                    primaryColor: Styles().colors!.white,
                    /*accentColor: Styles().colors!.white,*/
                    highlightColor: Styles().colors!.white,
                    splashColor: Styles().colors!.white,
                  ),
                  child: DropdownButton(
                      icon: Image.asset('images/icon-down-orange.png', excludeFromSemantics: true),
                      isExpanded: true,
                      focusColor: Styles().colors!.white,
                      underline: Container(),
                      hint: Text(buttonTitle ?? "", style: (widget.initialSelectedValue == null ? hintStyle : valueStyle)),
                      items: _constructItems(),
                      onChanged: (widget.enabled ? (dynamic value) => _onValueChanged(value) : null)),
                ),
              ),
              buttonDescription==null? Container():
              Semantics(container: true, child:
                Container(
                  padding: EdgeInsets.only(right: 42, bottom: 12),
                  child: Text(buttonDescription,
                    style: Styles().textStyles?.getTextStyle("widget.group.dropdown_button.hint"),
                  ),
                )
              )
            ]
        )
    );
  }

  Widget _buildDropDownItem(String title, String? description, bool isSelected){
    return
      Container(
          color: (Colors.white),
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(height: 11),
            Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: isSelected? Styles().textStyles?.getTextStyle("widget.group.dropdown_button.item.selected") :  Styles().textStyles?.getTextStyle("widget.group.dropdown_button.item.not_selected")
                        ),
                      )),
                  isSelected
                      ? Image.asset("images/checkbox-selected.png", excludeFromSemantics: true)
                      : Image.asset("images/oval-orange.png", excludeFromSemantics: true)
                ]),
            description==null? Container() : Container(height: 6,),
            description==null? Container():
            Container(
              padding: EdgeInsets.only(right: 30),
              child: Text(description,
                style: Styles().textStyles?.getTextStyle("widget.group.dropdown_button.hint")
              ),
            ),
            Container(height: 11),
            Container(height: 1, color: Styles().colors!.fillColorPrimaryTransparent03,)
          ],)
    );
  }

  void _onValueChanged(dynamic value) {
    widget.onValueChanged!(value);
    setState(() {});
  }

  String? _getButtonDescriptionText(){
    if (widget.initialSelectedValue != null) {
      GroupDropDownDescriptionDataBuilder<T?>? constructDescriptionFn = widget.constructDropdownDescription ?? widget.constructDescription;
      return constructDescriptionFn!=null? constructDescriptionFn(widget.initialSelectedValue) : null;
    } else {
      //empty null for now
      return null;
    }
  }

  String? _getButtonTitleText(){
    if (widget.initialSelectedValue != null) {
      return widget.constructTitle != null ? widget.constructTitle!(widget.initialSelectedValue) : widget.initialSelectedValue?.toString();
    } else {
      return widget.emptySelectionText;
    }
  }

  List<DropdownMenuItem<dynamic>>? _constructItems(){
    int optionsCount = widget.items?.length ?? 0;
    if (optionsCount == 0) {
      return null;
    }

    return widget.items!.map((Object? item) {
      String? name = widget.constructTitle!=null? widget.constructTitle!(item) : item?.toString();
      GroupDropDownDescriptionDataBuilder<T?>? constructDescriptionFn = widget.constructListItemDescription ?? widget.constructDescription;
      String? description = constructDescriptionFn!=null? constructDescriptionFn(item as T?) : null;
      bool isSelected = (widget.initialSelectedValue != null) && (widget.initialSelectedValue == item);
      return DropdownMenuItem<dynamic>(
        value: item,
        child: item!=null? _buildDropDownItem(name!,description,isSelected): Container(),
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
          border: Border.all(color: enabled ? Styles().colors!.fillColorSecondary! : Styles().colors!.surfaceAccent!, width: 2),
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Padding(padding: EdgeInsets.only(left:16, right: 8, ),
          child: Center(
            child: Row(children: <Widget>[
              Text(title!, style:  enabled ? Styles().textStyles?.getTextStyle("widget.button.title.enabled") : Styles().textStyles?.getTextStyle("widget.button.title.disabled") ),
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
          icon: Image.asset('images/chevron-left-white.png', excludeFromSemantics: true),
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
      backgroundColor: Styles().colors!.fillColorPrimary,
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
                      style: Styles().textStyles?.getTextStyle("widget.dialog.message.regular.extra_fat"),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Expanded(child:
                        RoundedButton(
                          label: Localization().getStringEx('headerbar.back.title', "Back"),
                          fontFamily: "ProximaNovaRegular",
                          textColor: Styles().colors!.fillColorPrimary,
                          borderColor: Styles().colors!.white,
                          backgroundColor: Styles().colors!.white,
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
                          fontFamily: "ProximaNovaBold",
                          textColor: Styles().colors!.fillColorPrimary,
                          borderColor: Styles().colors!.fillColorSecondary,
                          backgroundColor: Styles().colors!.white,
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

//////////////////////////
//GroupEventCard

class GroupEventCard extends StatefulWidget {
  final Event? groupEvent;
  final Group? group;

  GroupEventCard({this.groupEvent, this.group});

  @override
  createState()=> _GroupEventCardState();
}

class _GroupEventCardState extends State<GroupEventCard>{
  @override
  Widget build(BuildContext context) {
    Event? event = widget.groupEvent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
            color: Styles().colors!.white,
            boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))],
            borderRadius: BorderRadius.all(Radius.circular(8))
        ),
        child: _EventContent(event: event, group: widget.group),
      ),
    );
  }
}

class _EventContent extends StatefulWidget {
  final Group? group;
  final Event? event;

  _EventContent({this.event, this.group});

  @override
  createState()=> _EventContentState();

  bool get isAdmin => group?.currentMember?.isAdmin ?? false;
}

class _EventContentState extends State<_EventContent> implements NotificationsListener {
  static const double _smallImageSize = 64;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted(() {});
    }
    else if (name == FlexUI.notifyChanged) {
      setStateIfMounted(() {});
    }
  }

  @override
  Widget build(BuildContext context) {

    bool isFavorite = widget.event?.isFavorite ?? false;
    String? imageUrl = widget.event?.eventImageUrl;

    List<Widget> content = [
      Padding(padding: EdgeInsets.only(bottom: 8, right: 8), child:
        Container(constraints: BoxConstraints(minHeight: 64), child:
          Text(widget.event?.title ?? '',  style:Styles().textStyles?.getTextStyle("widget.title.large.extra_fat")),
      )),
    ];
    content.add(Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Row(children: <Widget>[
      Padding(padding: EdgeInsets.only(right: 8), child: Image.asset('images/icon-calendar.png'),),
      Expanded(child:
      Text(widget.event?.timeDisplayString ?? '', style: Styles().textStyles?.getTextStyle("widget.card.detail.small"))
      ),
    ],)),);

    return Stack(children: <Widget>[
      InkWell(onTap: () {
          Analytics().logSelect(target: "Group Event");
          Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupEventDetailPanel(event: widget.event, group: widget.group, previewMode: widget.isAdmin,)));
        },
        child: Padding(padding: EdgeInsets.only(left:16, right: 80, top: 16, bottom: 16), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: content),
        )
      ),
      Align(alignment: Alignment.topRight, child:
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Visibility(visible: illinois.Auth2().canFavorite,
                child: Semantics(
                  label: isFavorite ? Localization().getStringEx(
                      'widget.card.button.favorite.off.title',
                      'Remove From Favorites') : Localization().getStringEx(
                      'widget.card.button.favorite.on.title',
                      'Add To Favorites'),
                  hint: isFavorite ? Localization().getStringEx(
                      'widget.card.button.favorite.off.hint', '') : Localization()
                      .getStringEx('widget.card.button.favorite.on.hint', ''),
                  button: true,
                  excludeSemantics: true,
                  child: InkWell(onTap: _onFavoriteTap, child:
                    Container(width: 42, height: 42, alignment: Alignment.center, child:
                      Image.asset(isFavorite ? 'images/icon-star-blue.png' : 'images/icon-star-gray-frame-thin.png'),
                    ),
                ))),

              Visibility(visible: _hasEventOptions, child:
                Semantics(label: Localization().getStringEx("panel.group_detail.label.options", "Options"), button: true,child:
                  InkWell(onTap: _onEventOptionsTap, child:
                    Container(width: 42, height: 42, alignment: Alignment.center, child:
                      Image.asset('images/icon-groups-options-orange.png'),
                    ),
                  ),
                )
              ),
            ],),
            Visibility(visible:
                StringUtils.isNotEmpty(imageUrl),
                child:Padding(
                  padding: EdgeInsets.only(left: 12, right: 12, bottom: 8, top: 8),
                  child: SizedBox(
                    width: _smallImageSize,
                    height: _smallImageSize,
                    child: ModalImageHolder(child: Image.network(imageUrl ?? '', excludeFromSemantics: true, fit: BoxFit.fill, headers: Config().networkAuthHeaders)),),)),
                ])
                )
    ],);
  }

  void _onFavoriteTap() {
    Analytics().logSelect(target: "Favorite: ${widget.event?.title}");
    Auth2().prefs?.toggleFavorite(widget.event);
  }

  bool get _hasEventOptions => _canDelete || _canEdit;

  void _onEventOptionsTap(){
    Analytics().logSelect(target: "Options");

    List<Widget> options = <Widget>[];
    
    if (_canEdit) {
      options.add(RibbonButton(
        label: Localization().getStringEx("panel.group_detail.button.edit_event.title", "Edit Event"),
        leftIconAsset: "images/icon-edit.png",
        onTap: _onEditEventTap
      ),);
    }

    if (_canDelete) {
      options.add(RibbonButton(
        label: Localization().getStringEx("panel.group_detail.button.delete_event.title", "Remove group event"),
        leftIconAsset: "images/icon-leave-group.png",
        onTap: (){
          Analytics().logSelect(target: "Remove group event");
          showDialog(context: context, builder: (context)=>_buildRemoveEventDialog(context)).then((value) => Navigator.pop(context));
        },
      ),);
    }

    showModalBottomSheet(context: context, backgroundColor: Colors.white, isScrollControlled: true, isDismissible: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context){
          return Container(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child:
            Column(mainAxisSize: MainAxisSize.min, children: options,
            ),
          );
        }
    );
  }

  Widget _buildRemoveEventDialog(BuildContext context){
    return GroupsConfirmationDialog(
        message: Localization().getStringEx("panel.group_detail.message.remove_event.title",  "Are you sure you want to remove this event from your group page?"),
        buttonTitle:Localization().getStringEx("panel.group_detail.button.remove.title", "Remove"),
        onConfirmTap:(){_onRemoveEvent(context);});
  }

  void _onRemoveEvent(BuildContext context){
    Groups().deleteEventFromGroup(event: widget.event!, groupId: widget.group!.id).then((value){
      Navigator.of(context).pop();
    });
  }

  void _onEditEventTap(){
    Analytics().logSelect(target: "Update Event");
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEventPanel(group: widget.group, editEvent: widget.event, onEditTap: (BuildContext context, Event event, List<Member>? selection) {
      Groups().updateGroupEvents(event).then((String? id) {
        if (StringUtils.isNotEmpty(id)) {
          Groups().updateLinkedEventMembers(groupId: widget.group?.id,eventId: event.id, toMembers: selection).then((success){
            if(success){
              Navigator.pop(context);
            } else {
              AppAlert.showDialogResult(context, "Unable to update event members");
            }
          }).catchError((_){
            AppAlert.showDialogResult(context, "Error Occurred while updating event members");
          });
        }
        else {
          AppAlert.showDialogResult(context, "Unable to update event");
        }
      }).catchError((_){
        AppAlert.showDialogResult(context, "Error Occurred while updating event");
      });
    })));
  }

  bool get _canEdit {
    return widget.isAdmin && StringUtils.isNotEmpty(widget.event?.createdByGroupId);
  }

  bool get _canDelete {
    return widget.isAdmin;
  }
}

/////////////////////////////////////
// GroupAddImageWidget

class GroupAddImageWidget extends StatefulWidget {
  @override
  _GroupAddImageWidgetState createState() => _GroupAddImageWidgetState();
}

class _GroupAddImageWidgetState extends State<GroupAddImageWidget> {
  final String _groupImageStoragePath = 'group/tout';
  final int _groupImageWidth = 1080;

  var _imageUrlController = TextEditingController();
  bool _showProgress = false;

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
                color: Styles().colors!.fillColorPrimary,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 10, top: 10),
                    child: Text(
                      Localization().getStringEx("widget.add_image.heading", "Select Image"),
                      style: Styles().textStyles?.getTextStyle("widget.dialog.message.large")
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
                        style: Styles().textStyles?.getTextStyle('widget.dialog.button.close'),
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
                                hintText:  Localization().getStringEx("widget.add_image.field.description.label","Image Url"),
                                labelText:  Localization().getStringEx("widget.add_image.field.description.hint","Image Url"),
                              ))),
                      Padding(
                          padding: EdgeInsets.all(10),
                          child: RoundedButton(
                              label: Localization().getStringEx("widget.add_image.button.use_url.label","Use Url"),
                              borderColor: Styles().colors!.fillColorSecondary,
                              backgroundColor: Styles().colors!.background,
                              textColor: Styles().colors!.fillColorPrimary,
                              onTap: _onTapUseUrl)),
                      Padding(
                          padding: EdgeInsets.all(10),
                          child: RoundedButton(
                              label:  Localization().getStringEx("widget.add_image.button.chose_device.label","Choose from Device"),
                              borderColor: Styles().colors!.fillColorSecondary,
                              backgroundColor: Styles().colors!.background,
                              textColor: Styles().colors!.fillColorPrimary,
                              progress: _showProgress,
                              onTap: _onTapChooseFromDevice)),
                    ]))
          ],
        ));
  }

  void _onTapCloseImageSelection() {
    Analytics().logSelect(target: "Close image selection");
    Navigator.pop(context, "");
  }

  void _onTapUseUrl() {
    Analytics().logSelect(target: "Use Url");
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
      Content().useUrl(storageDir: _groupImageStoragePath, width: _groupImageWidth, url: url);
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
            AppToast.show(logicResult.errorMessage ?? ''); //TBD: localize error message
            break;
          case ImagesResultType.succeeded:
          //ready
            AppToast.show(Localization().getStringEx("widget.add_image.validation.success.label","Successfully added an image"));
            Navigator.pop(context, logicResult.data);
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
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ImageEditPanel(storagePath: _groupImageStoragePath, width: _groupImageWidth))).then((logicResult){
      setState(() {
        _showProgress = false;
      });

      ImagesResultType? resultType = logicResult?.resultType;
      switch (resultType) {
        case ImagesResultType.cancelled:
        //do nothing
          break;
        case ImagesResultType.error:
          AppToast.show(logicResult.errorMessage ?? ''); //TBD: localize error message
          break;
        case ImagesResultType.succeeded:
        //ready
          AppToast.show(Localization().getStringEx("widget.add_image.validation.success.label","Successfully added an image"));
          Navigator.pop(context, logicResult.data);
          break;
        default:
          break;
      }
    });
  }


}

/////////////////////////////////////
// GroupCard


enum GroupCardDisplayType { myGroup, allGroups, homeGroups }

class GroupCard extends StatefulWidget {
  final Group? group;
  final GroupCardDisplayType displayType;
  final Function? onImageTap;
  final EdgeInsets margin;

  GroupCard({required this.group,
    this.displayType = GroupCardDisplayType.allGroups,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.onImageTap,
  });

  @override
  _GroupCardState createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  static const double _smallImageSize = 64;

  GroupStats? _groupStats;

  final GlobalKey _contentKey = GlobalKey();
  Size? _contentSize;
  bool? _bussy;

  @override
  void initState() {
    super.initState();
    _loadGroupStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evalContentSize();
    });
  }

  @override
  Widget build(BuildContext context) {
    String? pendingCountText = sprintf(Localization().getStringEx("widget.group_card.pending.label", "Pending: %s"), [StringUtils.ensureNotEmpty((_groupStats?.pendingCount ?? 0).toString())]);
    String? groupCategory = StringUtils.ensureNotEmpty(widget.group?.category, defaultValue: Localization().getStringEx("panel.groups_home.label.category", "Category"));
    return GestureDetector(onTap: () => _onTapCard(context), child:
      Padding(padding: widget.margin, child:
        Container(padding: EdgeInsets.all(16), decoration: BoxDecoration( color: Styles().colors!.white, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))]), child:
          Stack(children: [
            Column(key: _contentKey, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              _buildHeading(),
              Container(height: 6),
              Row(children:[
                Expanded(child:
                  Column(children:[
                    Row(children: [
                      Expanded(child:
                        Text(groupCategory,
                          overflow: TextOverflow.ellipsis,
                          maxLines: (widget.displayType == GroupCardDisplayType.homeGroups) ? 2 : 10,
                          style: Styles().textStyles?.getTextStyle("widget.card.title.small.fat")
                        )
                      ),
                    ]),
                    Row(children: [
                      Expanded(child:
                        Padding(padding: const EdgeInsets.symmetric(vertical: 0), child:
                          Text(widget.group?.title ?? "", overflow: TextOverflow.ellipsis, maxLines: widget.displayType == GroupCardDisplayType.homeGroups? 2 : 10, style:  Styles().textStyles?.getTextStyle("widget.title.large.extra_fat"))
                        )
                      )
                    ]),
                  ]),
                ),
                _buildImage()
              ]),
              (widget.displayType == GroupCardDisplayType.homeGroups) ? Expanded(child: Container()) : Container(),
              Visibility(visible: (widget.group?.currentUserIsAdmin ?? false) && ((_groupStats?.pendingCount ?? 0) > 0), child:
                Text(pendingCountText, overflow: TextOverflow.ellipsis, maxLines: widget.displayType == GroupCardDisplayType.homeGroups? 2 : 10, style: Styles().textStyles?.getTextStyle("widget.card.detail.regular_variant"),),
              ),
              Container(height: 4),
              // (displayType == GroupCardDisplayType.myGroup || displayType == GroupCardDisplayType.homeGroups) ?
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child:
                  _buildUpdateTime(),
                ),
                _buildMembersCount()
              ])
              // : Container()
            ]),
            Visibility(visible: (_bussy == true), child:
              (_contentSize != null) ? SizedBox(width: _contentSize!.width, height: _contentSize!.height, child:
                Align(alignment: Alignment.center, child:
                  SizedBox(height: 24, width: 24, child:
                    CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), )
                  ),
                ),
              ) : Container(),
            ),
          ],),
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

    if ((widget.group?.privacy == GroupPrivacy.public) && wrapContent.isNotEmpty) {
      wrapContent.insert(0, _buildHeadingWrapLabel(Localization().getStringEx('widget.group_card.status.public', 'Public')));
    }

    List<Widget> rowContent = <Widget>[];

    String? userStatus = widget.group?.currentUserStatusText;
    if (StringUtils.isNotEmpty(userStatus)) {
      rowContent.add(Padding(padding: EdgeInsets.only(right: wrapContent.isNotEmpty ? 8 : 0), child:
        _buildHeadingLabel(userStatus!.toUpperCase(),
          color: widget.group?.currentUserStatusColor,
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

  Widget _buildHeadingLabel(String text, {Color? color, String? semanticsLabel}) {
    return Semantics(label: semanticsLabel, excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.all(Radius.circular(2))),
        child: Text(text,
          style: Styles().textStyles?.getTextStyle("widget.heading.small"))));
  }

  Widget _buildHeadingWrapLabel(String text) {
    return _buildHeadingLabel(text.toUpperCase(),
      color: Styles().colors?.fillColorSecondary,
      semanticsLabel: sprintf(Localization().getStringEx('widget.group_card.status.hint', 'status: %s ,for: '), [text.toLowerCase()])
    );
  }

  Widget _buildImage() {
    double maxImageWidgth = 150;
    String? imageUrl = widget.group?.imageURL;
    return
      StringUtils.isEmpty(imageUrl) ? Container() :
      // Expanded(
      //     flex: 1,
      //     child:
      Semantics(
          label: "post image",
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
                  constraints: BoxConstraints(maxWidth: maxImageWidgth),
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
          style: Styles().textStyles?.getTextStyle("widget.card.detail.small_variant")
    ));
  }

  Widget _buildMembersCount() {
    int count = _groupStats?.activeMembersCount ?? 0;
    String membersLabel = (count == 1)
        ? Localization().getStringEx('widget.group_card.member.label', 'member')
        : Localization().getStringEx('widget.group_card.members.label', 'members');
    return Container(
        child: Text('$count $membersLabel',
            style: Styles().textStyles?.getTextStyle("widget.card.detail.small_variant")));
  }

   void _loadGroupStats() {
    Groups().loadGroupStats(widget.group?.id).then((stats) {
      _groupStats = stats;
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _onTapCard(BuildContext context) {
    Analytics().logSelect(target: "Group: ${widget.group?.title}");
    if (FlexUI().isAuthenticationAvailable) {
      if (Auth2().isOidcLoggedIn) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupDetailPanel(group: widget.group)));
      }
      else {
        setState(() { _bussy = true; });

        Auth2().authenticateWithOidc().then((Auth2OidcAuthenticateResult? result) {
          if (mounted) {
            setState(() { _bussy = null; });
            if (result == Auth2OidcAuthenticateResult.succeeded) {
              Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupDetailPanel(group: widget.group)));
            }
          }
        });
      }
    }
    else {
      AppAlert.showCustomDialog(context: context, contentWidget: _buildPrivacyAlertWidget(), actions: [
        TextButton(child: Text(Localization().getStringEx('dialog.ok.title', 'OK')), onPressed: () => _onDismissPrivacyAlert(context))
      ]);
    }
  }

  Widget _buildPrivacyAlertWidget() {
    final String iconMacro = '{{privacy_level_icon}}';
    String privacyMsg = Localization().getStringEx('panel.group_card.privacy_alert.msg', 'With your privacy level at $iconMacro , you can only view existing groups.');
    int iconMacroPosition = privacyMsg.indexOf(iconMacro);
    String privacyMsgStart = (0 < iconMacroPosition) ? privacyMsg.substring(0, iconMacroPosition) : '';
    String privacyMsgEnd = ((0 < iconMacroPosition) && (iconMacroPosition < privacyMsg.length)) ? privacyMsg.substring(iconMacroPosition + iconMacro.length) : '';

    return RichText(text: TextSpan(style: Styles().textStyles?.getTextStyle('"widget.description.small.fat'), children: [
      TextSpan(text: privacyMsgStart),
      WidgetSpan(alignment: PlaceholderAlignment.middle, child: _buildPrivacyLevelWidget()),
      TextSpan(text: privacyMsgEnd)
    ]));
  }

  Widget _buildPrivacyLevelWidget() {
    String privacyLevel = Auth2().prefs?.privacyLevel?.toString() ?? '';
    return Container(height: 40, width: 40, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 2), color: Styles().colors!.white, borderRadius: BorderRadius.all(Radius.circular(100)),), child:
      Container(height: 32, width: 32, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorSecondary!, width: 2), color: Styles().colors!.white, borderRadius: BorderRadius.all(Radius.circular(100)),), child:
        Text(privacyLevel, style: Styles().textStyles?.getTextStyle('widget.card.title.regular.extra_fat'))
      ),
    );
  }

  void _onDismissPrivacyAlert(BuildContext context) {
    Analytics().logSelect(target: 'OK');
    Navigator.of(context).pop();
  }

  String get _timeUpdatedText {
    return widget.group?.displayUpdateTime ?? '';
  }

  void _evalContentSize() {
    try {
      final RenderObject? renderBox = _contentKey.currentContext?.findRenderObject();
      if (renderBox is RenderBox) {
        if (mounted) {
          setState(() {
            _contentSize = renderBox.size;
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}

//////////////////////////////////////
// GroupPostCard

class GroupPostCard extends StatefulWidget {
  final GroupPost? post;
  final Group? group;

  GroupPostCard({Key? key, required this.post, required this.group}) :
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
    String? memberName = widget.post?.member?.displayShortName;
    String? htmlBody = widget.post?.body;
    String? imageUrl = widget.post?.imageUrl;
    int visibleRepliesCount = getVisibleRepliesCount();
    bool isRepliesLabelVisible = (visibleRepliesCount > 0);
    String? repliesLabel = (visibleRepliesCount == 1)
        ? Localization().getStringEx('widget.group.card.reply.single.reply.label', 'Reply')
        : Localization().getStringEx('widget.group.card.reply.multiple.replies.label', 'Replies');
    return Stack(alignment: Alignment.topRight, children: [
      Semantics(button:true,
        child:GestureDetector(
          onTap: _onTapCard,
          child: Container(
              decoration: BoxDecoration(
                  color: Styles().colors!.white,
                  boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))],
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [
                      Expanded(
                          child: Text(StringUtils.ensureNotEmpty(widget.post!.subject),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: Styles().textStyles?.getTextStyle('widget.card.title.regular.fat') )),
                      Visibility(
                          visible: isRepliesLabelVisible,
                          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                            Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(StringUtils.ensureNotEmpty(visibleRepliesCount.toString()),
                                    style: Styles().textStyles?.getTextStyle('widget.description.small'))),
                            Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(StringUtils.ensureNotEmpty(repliesLabel),
                                    style: Styles().textStyles?.getTextStyle('widget.description.small')))
                          ])),
                    ]),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.only(top: 10, bottom: 10),
                            child: Html(data: htmlBody, style: {
                              "body": Style(
                                  color: Styles().colors!.fillColorPrimary,
                                  fontFamily: Styles().fontFamilies!.regular,
                                  fontSize: FontSize(16),
                                  maxLines: 3,
                                  textOverflow: TextOverflow.ellipsis,
                                  margin: EdgeInsets.zero,
                              ),
                            }, onLinkTap: (url, context, attributes, element) => _onLinkTap(url)))),
                        StringUtils.isEmpty(imageUrl)? Container() :
                        Expanded(
                          flex: 1,
                          child: Semantics(
                            label: "post image",
                            button: true,
                            hint: "Double tap to zoom the image",
                            child: Container(
                                padding: EdgeInsets.only(left: 8, bottom: 8, top: 8),
                                child: SizedBox(
                                  width: _smallImageSize,
                                  height: _smallImageSize,
                                  child: ModalImageHolder(child: Image.network(imageUrl!, excludeFromSemantics: true, fit: BoxFit.fill,)),),)
                            ))
                    ],),
                    Container(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child:Container(
                              padding: EdgeInsets.only(right: 6),
                              child:Text(StringUtils.ensureNotEmpty(memberName),
                                textAlign: TextAlign.left,
                                style: Styles().textStyles?.getTextStyle('widget.description.small')),
                          )),
                          Expanded(
                            flex: 2,
                            child: Semantics(child: Container(
                              padding: EdgeInsets.only(left: 6),
                              child: Text(StringUtils.ensureNotEmpty(widget.post?.displayDateTime),
                                semanticsLabel: "Updated ${widget.post?.displayDateTime ?? ""} ago",
                                textAlign: TextAlign.right,
                                style: Styles().textStyles?.getTextStyle('widget.description.small'))),
                          )),
                        ],
                      )
                    )
                  ]))))),
    ]);
  }

  void _onTapCard() {
    Analytics().logSelect(target: "Group post");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostDetailPanel(post: widget.post, group: widget.group)));
  }

  void _onLinkTap(String? url) {
    Analytics().logSelect(target: url);
    if (StringUtils.isNotEmpty(url)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
    }
  }

  int getVisibleRepliesCount() {
    int result = 0;
    List<GroupPost>? replies = widget.post?.replies;
    if (replies != null) {
      bool? memberOrAdmin = widget.group?.currentUserIsMemberOrAdmin;
      for (GroupPost? reply in replies) {
        if ((reply!.private != true) || (memberOrAdmin == true)) {
          result++;
        }
      }
    }
    return result;
  }
}

//////////////////////////////////////
// GroupReplyCard

class GroupReplyCard extends StatefulWidget {
  final GroupPost? reply;
  final GroupPost? post;
  final Group? group;
  final String? iconPath;
  final String? semanticsLabel;
  final void Function()? onIconTap;
  final void Function()? onCardTap;
  final bool showRepliesCount;

  GroupReplyCard({@required this.reply, @required this.post, @required this.group, this.iconPath, this.onIconTap, this.semanticsLabel, this.showRepliesCount = true, this.onCardTap});

  @override
  _GroupReplyCardState createState() => _GroupReplyCardState();
}

class _GroupReplyCardState extends State<GroupReplyCard> with NotificationsListener{
  static const double _smallImageSize = 64;

  @override
  void initState() {
    NotificationService().subscribe(this, Groups.notifyGroupPostsUpdated);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int visibleRepliesCount = widget.reply?.replies?.length ?? 0;
    bool isRepliesLabelVisible = (visibleRepliesCount > 0) && widget.showRepliesCount;
    String? repliesLabel = (visibleRepliesCount == 1)
        ? Localization().getStringEx('widget.group.card.reply.single.reply.label', 'Reply')
        : Localization().getStringEx('widget.group.card.reply.multiple.replies.label', 'Replies');
    String? bodyText = StringUtils.ensureNotEmpty(widget.reply?.body);
    if (widget.reply?.isUpdated ?? false) {
      bodyText +=
          ' <span>(${Localization().getStringEx('widget.group.card.reply.edited.reply.label', 'edited')})</span>';
    }
    return Semantics(container: true, button: true,
      child:GestureDetector(
        onTap: widget.onCardTap ?? _onTapCard,
         child:Container(
        decoration: BoxDecoration(
            color: Styles().colors!.white,
            boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))],
            borderRadius: BorderRadius.all(Radius.circular(8))),
        child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Semantics( child:
                  Text(StringUtils.ensureNotEmpty(widget.reply?.member?.displayShortName),
                    style: Styles().textStyles?.getTextStyle("widget.card.title.small.fat")),
                ),
                Expanded(child: Container()),
                Visibility(
                  visible: Config().showGroupPostReactions,
                  child: GroupPostReaction(
                    groupID: widget.group?.id,
                    post: widget.reply,
                    reaction: thumbsUpReaction,
                    accountIDs: widget.reply?.reactions[thumbsUpReaction],
                    selectedIconPath: 'images/icon-thumbs-up-solid.png',
                    deselectedIconPath: 'images/icon-thumbs-up-outline.png',
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
                            child: (StringUtils.isNotEmpty(widget.iconPath) ? Image.asset(widget.iconPath!, excludeFromSemantics: true,) : Container())))))))
              ]),
              Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: Container(
                          child: Semantics( child:
                          Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Html(
                                data: bodyText,
                                style: {
                                "body": Style(
                                    color: Styles().colors!.fillColorPrimary,
                                    fontFamily: Styles().fontFamilies!.regular,
                                    fontSize: FontSize(16),
                                    maxLines: 3000,
                                    textOverflow: TextOverflow.ellipsis,
                                    margin: EdgeInsets.zero
                                ),
                                "span": Style(
                                    color: Styles().colors!.blackTransparent018,
                                    fontFamily: Styles().fontFamilies!.regular,
                                    fontSize: FontSize(16),
                                    maxLines: 1,
                                    textOverflow: TextOverflow.ellipsis)
                                },
                                onLinkTap: (url, context, attributes, element) => _onLinkTap(url)))))),
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
                                style: Styles().textStyles?.getTextStyle('widget.description.small'))),)),
                      Visibility(
                        visible: isRepliesLabelVisible,
                        child: Expanded(child: Container(
                          child: Semantics(child: Text("$visibleRepliesCount $repliesLabel",
                              textAlign: TextAlign.right,
                              style: Styles().textStyles?.getTextStyle('widget.description.small_underline')
                        ))),
                      ))
                ],),)
            ])))));
  }

  void _onLinkTap(String? url) {
    Analytics().logSelect(target: url);
    if (StringUtils.isNotEmpty(url)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
    }
  }

  void _onTapCard(){
    Analytics().logSelect(target: "Group reply");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupPostDetailPanel(post: widget.post, group: widget.group, focusedReply: widget.reply, hidePostOptions: true,)));
  }

  @override
  void onNotification(String name, param) {
    if (name == Groups.notifyGroupPostsUpdated) {
      setState(() {});
    }
  }
}

//////////////////////////////////////
// GroupPostReaction

const String thumbsUpReaction = "thumbs-up";

class GroupPostReaction extends StatelessWidget {
  final String? groupID;
  final GroupPost? post;
  final String reaction;
  final List<String>? accountIDs;
  final String selectedIconPath;
  final String deselectedIconPath;
  final double iconSize;

  GroupPostReaction({required this.groupID, required this.post, required this.reaction,
    this.accountIDs, required this.selectedIconPath, required this.deselectedIconPath, this.iconSize = 18});

  @override
  Widget build(BuildContext context) {
    bool selected = accountIDs?.contains(Auth2().accountId) ?? false;
    return Semantics(button: true, label: reaction,
        child: InkWell(
            onTap: () => _onTapReaction(groupID, post, reaction),
            onLongPress: () => _onLongPressReactions(context, accountIDs, groupID),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(selected ? selectedIconPath : deselectedIconPath,
                      width: iconSize, height: iconSize, fit: BoxFit.fitWidth, excludeFromSemantics: true),
                  Visibility(visible: accountIDs != null && accountIDs!.length > 0,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(accountIDs?.length.toString() ?? '',
                            style: TextStyle(
                                fontFamily: Styles().fontFamilies!.regular,
                                fontSize: 14,
                                color: Styles().colors!.fillColorPrimary)),
                      ))
                ])));
  }

  void _onTapReaction(String? groupId, GroupPost? post, String reaction) async {
    bool success = await Groups().togglePostReaction(groupId, post?.id, reaction);
    if (success) {
      GroupPost? updatedPost = await Groups().loadGroupPost(groupId: groupId, postId: post?.id);
      if (updatedPost != null) {
        post?.reactions.clear();
        post?.reactions.addAll(updatedPost.reactions);
        NotificationService().notify(Groups.notifyGroupPostReactionsUpdated);
      }
    }
  }

  void _onLongPressReactions(BuildContext context, List<String>? accountIDs, String? groupID) async {
    if (accountIDs == null || accountIDs.isEmpty || groupID == null || groupID.isEmpty) {
      return;
    }
    Analytics().logSelect(target: 'Reactions List');

    List<Widget> reactions = [];
    List<Member>? members = await Groups().loadMembers(groupId: groupID, userIds: accountIDs);
    for (Member member in members ?? []) {
      reactions.add(Padding(
        padding: const EdgeInsets.only(bottom: 24.0, left: 8.0, right: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset('images/icon-thumbs-up-solid.png', width: 24, height: 24,
                fit: BoxFit.fitWidth, excludeFromSemantics: true),
            Container(width: 16),
            Text(member.displayShortName, style: TextStyle(
                fontFamily: Styles().fontFamilies!.bold,
                fontSize: 16,
                color: Styles().colors!.fillColorPrimary)),
          ],
        ),
      ));
    }

    showModalBottomSheet(
        context: context,
        backgroundColor: Styles().colors!.white,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)),),
        builder: (context) {
          return Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 24),
            height: MediaQuery.of(context).size.height / 2,
            child: Column(
              children: [
                Container(width: 60, height: 8, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Styles().colors?.disabledTextColor)),
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
                      _FontIcon(
                          onTap: _onTapBold,
                          buttonLabel: "Bold",
                          iconPath: 'images/icon-bold.png'),
                      Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: _FontIcon(
                              onTap: _onTapItalic,
                              buttonLabel: "Italic",
                              iconPath: 'images/icon-italic.png')),
                      Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: _FontIcon(
                              onTap: _onTapUnderline,
                              buttonLabel: "Underline",
                              iconPath: 'images/icon-underline.png')),
                      Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Semantics(button: true, child:
                          GestureDetector(
                              onTap: _onTapEditLink,
                              child: Text(
                                  Localization().getStringEx(
                                      'panel.group.detail.post.create.link.label',
                                      'Link'),
                                  style: Styles().textStyles?.getTextStyle('widget.group.input_field.link')))))
                    ])),
            Padding(
                padding: EdgeInsets.only(top: 8, bottom: 16),
                child: TextField(
                    controller: _bodyController,
                    onChanged: (String text){
                      if (widget.onBodyChanged != null) {
                        widget.onBodyChanged!(text);
                      }
                    },
                    maxLines: 15,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                        hintText: _hint,
                        border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Styles().colors!.mediumGray!,
                                width: 0.0))),
                    style: Styles().textStyles?.getTextStyle(''))),
          ],
        )
    );
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
              style: Styles().textStyles?.getTextStyle('widget.group.input_field.heading')),
          Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                  Localization().getStringEx(
                      'panel.group.detail.post.create.dialog.link.text.label',
                      'Link Text:'),
                  style: Styles().textStyles?.getTextStyle('widget.group.input_field.detail'))),
          Padding(
              padding: EdgeInsets.only(top: 6),
              child: TextField(
                  controller: _linkTextController,
                  maxLines: 1,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Styles().colors!.mediumGray!, width: 0.0))),
                  style: Styles().textStyles?.getTextStyle('widget.input_field.text.regular'))),
          Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                  Localization().getStringEx(
                      'panel.group.detail.post.create.dialog.link.url.label',
                      'Link URL:'),
                  style: Styles().textStyles?.getTextStyle('widget.group.input_field.detail'))),
          Padding(
              padding: EdgeInsets.only(top: 6),
              child: TextField(
                  controller: _linkUrlController,
                  maxLines: 1,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Styles().colors!.mediumGray!, width: 0.0))),
                  style: Styles().textStyles?.getTextStyle('widget.input_field.text.regular')))
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
  static List<Member>? constructUpdatedMembersList({List<Member>? selection, List<Member>? upToDateMembers}){
    if(CollectionUtils.isNotEmpty(selection) && CollectionUtils.isNotEmpty(upToDateMembers)){
      return upToDateMembers!.where((member) => selection!.any((outdatedMember) => outdatedMember.userId == member.userId)).toList();
    }

    return selection;
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
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("To: ", style: Styles().textStyles?.getTextStyle('widget.group.members.title'),),
              Expanded(
                child: _buildDropDown(),
              )
            ],
          ),
          GestureDetector(
            onTap: _onTapEdit,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(selectedMembersText, style: Styles().textStyles?.getTextStyle("widget.group.members.selected_entry"),),
            )
          ),
          Visibility(
            visible: _showChangeButton,
            child: RoundedButton(label: "Edit", onTap: _onTapEdit, textColor: Styles().colors!.fillColorSecondary!,conentAlignment: MainAxisAlignment.start, contentWeight: 0.33, padding: EdgeInsets.all(3), maxBorderRadius: 5,)
          )
        ],
      ),
    );
  }
  
  Widget _buildDropDown(){
    return Container(
        height: 48,
        decoration: BoxDecoration(
            color:  widget.enabled? Colors.white: Styles().colors!.background!,
            border: Border.all(color: Styles().colors!.lightGray!, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(4))),
        child: Padding(
            padding: EdgeInsets.only(left: 10),
            child:
              DropdownButtonHideUnderline(
                // child: ButtonTheme(
                //   alignedDropdown: true,
                  child: DropdownButton2<GroupMemberSelectionData>(
                    isExpanded: true,
                    dropdownPadding: EdgeInsets.zero,
                    itemPadding: EdgeInsets.zero,
                    iconEnabledColor: Styles().colors!.fillColorSecondary!,
                    icon: widget.enabled? Icon(Icons.arrow_drop_down): Container(),
                    // buttonDecoration: widget.enabled? null : BoxDecoration(color: Styles().colors!.background),
                    dropdownDecoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorPrimary!,width: 2, style: BorderStyle.solid), borderRadius: BorderRadius.only(bottomRight: Radius.circular(8), bottomLeft: Radius.circular(8))),
                    // style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 20, fontFamily: Styles().fontFamilies!.bold),
                    // value: _currentSelection,
                    items: _buildDropDownItems,
                    hint: Text(_selectionText,  style: Styles().textStyles?.getTextStyle('widget.group.members.title') ,),
                    onChanged: widget.enabled? (GroupMemberSelectionData? data) {
                      _onDropDownItemChanged(data);
                    } : null,
                )))
              // )
    );
  }

  List<DropdownMenuItem<GroupMemberSelectionData>> get _buildDropDownItems {
    List<DropdownMenuItem<GroupMemberSelectionData>> items = [];

    items.add(DropdownMenuItem(alignment: AlignmentDirectional.topCenter,enabled: false, value: null,
        child:
          Container(
            color: Styles().colors!.fillColorPrimary,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
              Expanded(child:
                Container(color: Styles().colors!.fillColorPrimary,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  child:Text("Select Recipient(s)", style:  Styles().textStyles?.getTextStyle('widget.group.members.dropdown.item'),))
          )
          ])))
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
                  child: Text(title, maxLines: 2, style: Styles().textStyles?.getTextStyle('widget.group.members.dropdown.item'))
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
              child: Text(title, maxLines: 2, style: Styles().textStyles?.getTextStyle('widget.group.members.dropdown.item.selected') ,)
          ))
      ]
    );
  }

  void _onDropDownItemChanged(GroupMemberSelectionData? data){
    if(data != null){
      switch (data.type){
        case GroupMemberSelectionDataType.Selection:
          _onSelectionChanged(data.requiresValidation?
              /*Trim Members which are no longer present*/
            GroupMembersSelectionWidget.constructUpdatedMembersList(selection: data.selection, upToDateMembers: _allMembersAllowedToPost) :
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
        setState(() {
            _allMembersAllowedToPost = members;
            if((_allMembersAllowedToPost?.isNotEmpty ?? false) && (widget.selectedMembers?.isNotEmpty ?? false)){
              //If we have successfully loaded the group data -> refresh initial selection
               _onSelectionChanged(GroupMembersSelectionWidget.constructUpdatedMembersList(upToDateMembers: _allMembersAllowedToPost, selection: widget.selectedMembers)); //Notify Parent widget with the updated values
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

class _FontIcon extends StatelessWidget {
  final GestureTapCallback? onTap;
  final String iconPath;
  final String? buttonLabel;
  _FontIcon({this.onTap, required this.iconPath, this.buttonLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(button: true, label: buttonLabel,
        child:GestureDetector(
            onTap: onTap, child: Image.asset(iconPath, width: 18, height: 18, excludeFromSemantics: true,)));
  }
}

typedef void OnImageChangedListener(String imageUrl);
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
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final double _imageHeight = 200;
    bool wrapContent = widget.wrapContent;
    bool explicitlyShowAddButton = widget.buttonVisible;
    bool showSlant = widget.showSlant;
    String? imageUrl = _imageUrl ?? widget.imageUrl; // For some reason sometimes the widget url is present but the _imageUrl is null

    return Container(
        constraints: BoxConstraints(
          maxHeight: (imageUrl!=null || !wrapContent)? _imageHeight : (double.infinity),
        ),
        color: Styles().colors!.background,
        child: Stack(alignment: Alignment.bottomCenter, children: <Widget>[
          StringUtils.isNotEmpty(imageUrl)
              ? Positioned.fill(child: ModalImageHolder(child: Image.network(imageUrl!, semanticLabel: widget.imageSemanticsLabel??"", fit: BoxFit.cover)))
              : Container(),
          Visibility( visible: showSlant,
              child: CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.fillColorSecondaryTransparent05, horzDir: TriangleHorzDirection.leftToRight), child: Container(height: 53))),
          Visibility( visible: showSlant,
              child: CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.background), child: Container(height: 30))),
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
                          textColor: Styles().colors!.fillColorPrimary,
                          contentWeight: 0.8,
                          onTap: (){ _onTapAddImage();}
                      )))):
          Container()
        ]));
  }

  void _onTapAddImage() async {
    Analytics().logSelect(target: "Add Image");
    String imageUrl = await showDialog(context: context, builder: (_) => Material(type: MaterialType.transparency, child: GroupAddImageWidget()));
    if (StringUtils.isNotEmpty(imageUrl) && (widget.onImageChanged != null)) {
      widget.onImageChanged!(imageUrl);
      if (mounted) {
        setState(() {
          _imageUrl = imageUrl;
        });
      }
    }
    Log.d("Image Url: $imageUrl");
  }
}

//Polls

class GroupPollCard extends StatefulWidget{
  final Poll? poll;
  final Group? group;

  GroupPollCard({required this.poll, this.group});

  @override
  State<StatefulWidget> createState() => _GroupPollCardState();

  bool get _canStart {
    return (poll?.status == PollStatus.created) && (
      (poll?.isMine ?? false) ||
      (group?.currentUserIsAdmin ?? false)
    );
  }
  
  bool get _canVote {
    return ((poll!.status == PollStatus.opened) &&
        (((poll!.userVote?.totalVotes ?? 0) == 0) ||
            poll!.settings!.allowMultipleOptions! ||
            poll!.settings!.allowRepeatOptions!
        ) &&
        (!poll!.isGeoFenced || GeoFence().currentRegionIds.contains(poll!.regionId))
    );
  }

  bool get _canEnd {
    return (poll?.status == PollStatus.opened) && (
      (poll?.isMine ?? false) ||
      (group?.currentUserIsAdmin ?? false)
    );
  }

  bool get _canDelete {
    return (
      (poll?.isMine ?? false) ||
      (group?.currentUserIsAdmin ?? false)
    );
  }
}

class _GroupPollCardState extends State<GroupPollCard> {
  GroupStats? _groupStats;

  List<GlobalKey>? _progressKeys;
  double? _progressWidth;

  @override
  void initState() {
    _loadGroupStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evalProgressWidths();
    });
    super.initState();
  }

  void _loadGroupStats() {
    Groups().loadGroupStats(widget.group?.id).then((stats) {
      _groupStats = stats;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Poll poll = widget.poll!;
    String pollVotesStatus = _pollVotesStatus;

    List<Widget> footerWidgets = [];

    String? pollStatus;

    String? creator = widget.poll?.creatorUserName ?? Localization().getStringEx('panel.poll_prompt.text.someone', 'Someone');//TBD localize
    String wantsToKnow = sprintf(Localization().getStringEx('panel.poll_prompt.text.wants_to_know', '%s wants to know'), [creator]);
    String semanticsQuestionText =  "$wantsToKnow,\n ${poll.title!}";
    String pin = sprintf(Localization().getStringEx('panel.polls_prompt.card.text.pin', 'Pin: %s'), [
      sprintf('%04i', [poll.pinCode ?? 0])
    ]);

    if(poll.status == PollStatus.created) {
      pollStatus = Localization().getStringEx("panel.polls_home.card.state.text.created","Polls created");
    } if (poll.status == PollStatus.opened) {
      pollStatus = Localization().getStringEx("panel.polls_home.card.state.text.open","Polls open");
      if (widget._canVote) {
        footerWidgets.add(_createVoteButton());
      }
    }
    else if (poll.status == PollStatus.closed) {
      pollStatus =  Localization().getStringEx("panel.polls_home.card.state.text.closed","Polls closed");
    }

    Widget cardBody = ((poll.status == PollStatus.opened) && (poll.settings?.hideResultsUntilClosed ?? false)) ?
      Text(Localization().getStringEx("panel.poll_prompt.text.rule.detail.hide_result", "Results will not be shown until the poll ends."), style: Styles().textStyles?.getTextStyle('widget.card.detail.regular'),) :
      Column(children: _buildCheckboxOptions(),);

    return Column(children: <Widget>[
      Container(
        decoration: BoxDecoration(
          color: Styles().colors!.white,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))],
        ),
        child: Padding(padding: EdgeInsets.only(left: 16, bottom: 16), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Row(children: <Widget>[
              Expanded(child:
                Semantics(label:semanticsQuestionText, excludeSemantics: true, child:
                  Text(wantsToKnow, style: Styles().textStyles?.getTextStyle('widget.card.detail.tiny'))),
              ),
              Text(pin, style: Styles().textStyles?.getTextStyle('widget.card.detail.tiny.fat')),
              Visibility(visible: _GroupPollOptionsState._hasPollOptions(widget), child:
                Semantics(label: Localization().getStringEx("panel.group_detail.label.options", "Options"), button: true,child:
                  GestureDetector(onTap: _onPollOptionsTap, child:
                    Padding(padding: EdgeInsets.all(10), child:
                      Image.asset('images/icon-groups-options-orange.png'),
                    ),
                  ),
                ),
              )
            ]),
            Padding(padding: EdgeInsets.only(right: 16), child:
              Column(children: [
                Container(height: 12,),
                Text(poll.title!, style: Styles().textStyles?.getTextStyle('widget.group.card.poll.title')),
                Container(height:12),
                cardBody,
                Container(height:25),
                Semantics(excludeSemantics: true, label: "$pollStatus,$pollVotesStatus", child:
                  Padding(padding: EdgeInsets.only(bottom: 12), child:
                    Row(children: <Widget>[
                      Expanded(child:
                        Text(pollVotesStatus, style: Styles().textStyles?.getTextStyle('widget.card.detail.tiny'),),
                      ),
                      Expanded(child:
                        Text(pollStatus ?? "", textAlign: TextAlign.right, style: Styles().textStyles?.getTextStyle('widget.card.detail.tiny.fat'),))
                    ],),
                  ),
                ),
            
                Column(children: footerWidgets,),
              ],),
            ),
          ],),
        ),
      ),],
    );
  }

  List<Widget> _buildCheckboxOptions() {
    bool isClosed = widget.poll!.status == PollStatus.closed;

    List<Widget> result = [];
    _progressKeys = [];
    int maxValueIndex=-1;
    if(isClosed  && ((widget.poll!.results?.totalVotes ?? 0) > 0)){
      maxValueIndex = 0;
      for (int optionIndex = 0; optionIndex<widget.poll!.options!.length ; optionIndex++) {
        int? optionVotes =  widget.poll!.results![optionIndex];
        if(optionVotes!=null &&  optionVotes > widget.poll!.results![maxValueIndex]!)
          maxValueIndex = optionIndex;
      }
    }

    int totalVotes = (widget.poll!.results?.totalVotes ?? 0);
    for (int optionIndex = 0; optionIndex<widget.poll!.options!.length ; optionIndex++) {
      bool useCustomColor = isClosed && maxValueIndex == optionIndex;
      String option = widget.poll!.options![optionIndex];
      bool didVote = ((widget.poll!.userVote != null) && (0 < (widget.poll!.userVote![optionIndex] ?? 0)));
      String checkboxImage = didVote ? 'images/deselected-dark.png' : 'images/checkbox-unselected.png';

      String votesString;
      int? votesCount = (widget.poll!.results != null) ? widget.poll!.results![optionIndex] : null;
      double votesPercent = ((0 < totalVotes) && (votesCount != null)) ? (votesCount.toDouble() / totalVotes.toDouble() * 100.0) : 0.0;
      if ((votesCount == null) || (votesCount == 0)) {
        votesString = '';
      }
      else if (votesCount == 1) {
        votesString = Localization().getStringEx("panel.polls_home.card.text.one_vote","1 vote");
      }
      else {
        String? votes = Localization().getStringEx("panel.polls_home.card.text.votes","votes");
        votesString = '$votesCount $votes';
      }

      GlobalKey progressKey = GlobalKey();
      _progressKeys!.add(progressKey);

      String semanticsText = option + "," +"\n "+  votesString +"," + votesPercent.toStringAsFixed(0) +"%";

      result.add(Padding(padding: EdgeInsets.only(top: (0 < result.length) ? 8 : 0), child:
      GestureDetector(
          child:
          Semantics(label: semanticsText, excludeSemantics: true, child:
          Row(children: <Widget>[
            Padding(padding: EdgeInsets.only(right: 10), child: Image.asset(checkboxImage,),),
            Expanded(
                flex: 5,
                key: progressKey, child:
            Stack(alignment: Alignment.centerLeft, children: <Widget>[
              CustomPaint(painter: PollProgressPainter(backgroundColor: Styles().colors!.white, progressColor: useCustomColor ?Styles().colors!.fillColorPrimary:Styles().colors!.lightGray, progress: votesPercent / 100.0), child: Container(height:30, width: _progressWidth),),
              Container(/*height: 15+ 16*MediaQuery.of(context).textScaleFactor,*/ child:
              Padding(padding: EdgeInsets.only(left: 5), child:
              Row(children: <Widget>[
                Expanded( child:
                Padding( padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text(option, style: useCustomColor? Styles().textStyles?.getTextStyle('widget.group.card.poll.option_variant')  : Styles().textStyles?.getTextStyle('widget.group.card.poll.option')),)),
                Visibility( visible: didVote,
                    child:Padding(padding: EdgeInsets.only(right: 10), child: Image.asset('images/checkbox-small.png',),)
                ),
              ],),)
              ),
            ],)
            ),
            Expanded(
              flex: 5,
              child: Padding(padding: EdgeInsets.only(left: 10), child: Text('$votesString (${votesPercent.toStringAsFixed(0)}%)', textAlign: TextAlign.right,style: Styles().textStyles?.getTextStyle('widget.group.card.poll.votes'),),),
            )
          ],)
          ))));
    }
    return result;
  }

  Widget _createVoteButton(){
    return _createButton(Localization().getStringEx("panel.polls_home.card.button.title.vote","Vote"), _onVoteTapped);
  }

  Widget _createButton(String title, void Function()? onTap, {bool enabled=true, bool loading = false}){
    return Container( padding: EdgeInsets.symmetric(horizontal: 54,),
        child: Semantics(label: title, button: true, excludeSemantics: true,
          child: InkWell(
              onTap: onTap,
              child: Stack(children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(vertical: 5,horizontal: 16),
                  decoration: BoxDecoration(
                    color: Styles().colors!.white,
                    border: Border.all(
                        color: enabled? Styles().colors!.fillColorSecondary! :Styles().colors!.surfaceAccent!,
                        width: 2.0),
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Center(
                    child: Text(title, style: Styles().textStyles?.getTextStyle("widget.description.small"),),
                  ),
                ),
                Visibility(visible: loading,
                  child: Container(padding: EdgeInsets.symmetric(vertical: 5),
                    child: Align(alignment: Alignment.center,
                      child: SizedBox(height: 24, width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorPrimary), )
                      ),
                    ),
                  ),
                )
              ])
          ),
        ));
  }

  void _onVoteTapped(){
    Polls().presentPollVote(widget.poll);
  }

  void _evalProgressWidths() {
    if (_progressKeys != null) {
      double progressWidth = -1.0;
      for (GlobalKey progressKey in _progressKeys!) {
        final RenderObject? progressRender = progressKey.currentContext?.findRenderObject();
        if ((progressRender is RenderBox) && (0 < progressRender.size.width)) {
          if ((progressWidth < 0.0) || (progressRender.size.width < progressWidth)) {
            progressWidth = progressRender.size.width;
          }
        }
      }
      if (0 < progressWidth) {
        setState(() {
          _progressWidth = progressWidth;
        });
      }
    }
  }

  String get _pollVotesStatus {
    bool hasGroup = (widget.group != null);
    int votes = hasGroup ? _uniqueVotersCount : (widget.poll!.results?.totalVotes ?? 0);

    String statusString;
    if (1 < votes) {
      statusString = sprintf(Localization().getStringEx('panel.poll_prompt.text.many_votes', '%s votes'), ['$votes']);
    } else if (0 < votes) {
      statusString = Localization().getStringEx('panel.poll_prompt.text.single_vote', '1 vote');
    } else {
      statusString = Localization().getStringEx('panel.poll_prompt.text.no_votes_yet', 'No votes yet');
    }

    if (hasGroup && (votes > 0)) {
      statusString += sprintf(' %s %d', [Localization().getStringEx('panel.polls_home.card.of.label', 'of'), _groupMembersCount]);
    }

    return statusString;
  }

  int get _uniqueVotersCount {
    return widget.poll?.uniqueVotersCount ?? 0;
  }

  int get _groupMembersCount {
    return _groupStats?.activeMembersCount ?? 0;
  }

  void _onPollOptionsTap() {
    Analytics().logSelect(target: "Options");

    showModalBottomSheet(context: context, backgroundColor: Colors.white, isScrollControlled: true, isDismissible: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return _GroupPollOptions(pollCard: widget,);
        }
    );
  }
}

class _GroupPollOptions extends StatefulWidget {
  final GroupPollCard pollCard;
  
  _GroupPollOptions({Key? key, required this.pollCard}) : super(key: key);
  
  @override
  State<_GroupPollOptions> createState() => _GroupPollOptionsState();
}

class _GroupPollOptionsState extends State<_GroupPollOptions> {

  bool _isStarting = false;
  bool _isEnding = false;
  bool _isDeleting = false;

  static bool _hasPollOptions(GroupPollCard pollCard) =>
    pollCard._canStart ||
    pollCard._canEnd ||
    pollCard._canDelete;

  @override
  Widget build(BuildContext context) {
    List<Widget> options = <Widget>[];

    if (widget.pollCard._canStart) {
      options.add(RibbonButton(
        label: Localization().getStringEx("panel.polls_home.card.button.title.start_poll", "Start Poll"),
        leftIconAsset: "images/icon-gear.png",
        progress: _isStarting,
        onTap: _onStartPollTapped
      ),);
    }
    if (widget.pollCard._canEnd) {
      options.add(RibbonButton(
        label: Localization().getStringEx("panel.polls_home.card.button.title.end_poll", "End Poll"),
        leftIconAsset: "images/icon-gear.png",
        progress: _isEnding,
        onTap: _onEndPollTapped
      ),);
    }

    if (widget.pollCard._canDelete) {
      options.add(RibbonButton(
        label: Localization().getStringEx("panel.polls_home.card.button.title.delete_poll", "Delete Poll"),
        leftIconAsset: "images/icon-leave-group.png",
        progress: _isDeleting,
        onTap: _onDeletePollTapped
      ),);
    }

    return Container(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child:
      Column(mainAxisSize: MainAxisSize.min, children: options,
      ),
    );

  }

  void _onStartPollTapped() {
    if (_isStarting != true) {
      setState(() {
        _isStarting = true;
      });
      Polls().open(widget.pollCard.poll?.pollId).then((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }).catchError((e) {
        if (mounted) {
          AppAlert.showDialogResult(context, illinois.Polls.localizedErrorString(e));
        }
      }).whenComplete(() {
        if (mounted) {
          setState(() {
            _isStarting = false;
          });
        }
      });
    }
  }

  void _onEndPollTapped() {
    if (_isEnding != true) {
      setState(() {
        _isEnding = true;
      });
      Polls().close(widget.pollCard.poll?.pollId).then((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }).catchError((e) {
        if (mounted) {
          AppAlert.showDialogResult(context, illinois.Polls.localizedErrorString(e));
        }
      }).whenComplete(() {
        if (mounted) {
          setState(() {
            _isEnding = false;
          });
        }
      });
    }
  }

  void _onDeletePollTapped() {
    if (_isDeleting != true) {
      setState(() {
        _isDeleting = true;
      });
      Polls().delete(widget.pollCard.poll?.pollId).then((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }).catchError((e) {
        if (mounted) {
          AppAlert.showDialogResult(context, illinois.Polls.localizedErrorString(e));
        }
      }).whenComplete(() {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      });
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
    Image profileImage = hasProfilePhoto
        ? Image.memory(_imageBytes!)
        : Image.asset('images/missing-profile-photo-placeholder.png', excludeFromSemantics: true);

    return GestureDetector(
        onTap: widget.onTap ?? _onImageTap,
        child: Stack(alignment: Alignment.center, children: [
          Container(
              decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(fit: (hasProfilePhoto ? BoxFit.cover : BoxFit.contain), image: profileImage.image))),
          Visibility(
              visible: _loading,
              child: SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(color: Styles().colors!.fillColorSecondary, strokeWidth: 2)))
        ]));
  }

  void _loadImage() {
    if (StringUtils.isNotEmpty(widget.userId)) {
      _setImageLoading(true);
      Content().loadSmallUserProfileImage(accountId: widget.userId).then((imageBytes) {
        _imageBytes = imageBytes;
        _setImageLoading(false);
      });
    }
  }

  void _onImageTap() {
    Analytics().logSelect(target: "Group Member Image");
    if (_imageBytes != null) {
      String? imageUrl = Content().getUserProfileImage(accountId: widget.userId, type: UserProfileImageType.defaultType);
      if (StringUtils.isNotEmpty(imageUrl)) {
        Navigator.push(
            context,
            PageRouteBuilder(
                opaque: false,
                pageBuilder: (context, _, __) =>
                    ModalImagePanel(imageUrl: imageUrl!, networkImageHeaders: Auth2().networkAuthHeaders, onCloseAnalytics: () => Analytics().logSelect(target: "Close Group Member Image"))));
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

  GroupsSelectionPopup({this.groups});

  @override
  _GroupsSelectionPopupState createState() => _GroupsSelectionPopupState();
}

class _GroupsSelectionPopupState extends State<GroupsSelectionPopup> {
  Set<String> _selectedGroupIds = {};

  @override
  void initState() {
    super.initState();
    if (CollectionUtils.isNotEmpty(widget.groups)) {
      for (Group group in widget.groups!) {
        if (group.id != null) {
          _selectedGroupIds.add(group.id!);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(contentPadding: EdgeInsets.zero, scrollable: true, content:
    Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Container(
          decoration: BoxDecoration(
            color: Styles().colors!.fillColorPrimary,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
          ),
          child: Row(children: <Widget>[
            Opacity(opacity: 0, child:
            Padding(padding: EdgeInsets.all(8), child:
            Image.asset('images/close-white.png', excludeFromSemantics: true,)
            )
            ),
            Expanded(child:
            Padding(padding: EdgeInsets.symmetric(vertical: 10), child:
            Text(Localization().getStringEx("widget.groups.selection.heading", "Select Group"), textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontFamily: Styles().fontFamilies!.medium, fontSize: 24)
            )
            )
            ),
            Semantics(button: true, label: Localization().getStringEx("dialog.close.title","Close"), child:
            InkWell(onTap: _onTapClose, child:
            Padding(padding: EdgeInsets.only(top: 8, bottom: 8, left: 4, right: 12), child:
            Image.asset('images/close-white.png', excludeFromSemantics: true,)
            )
            )
            )
          ])
      ),
      Padding(padding: EdgeInsets.all(10), child: _buildGroupsList()),
      Semantics(container: true, child:
      Padding(padding: EdgeInsets.all(10), child:
      RoundedButton(
          label: Localization().getStringEx("widget.groups.selection.button.select.label", "Select"),
          borderColor: Styles().colors!.fillColorSecondary,
          backgroundColor: Styles().colors!.white,
          textColor: Styles().colors!.fillColorPrimary,
          onTap: _onTapSelect
      )
      )
      )
    ]));
  }

  Widget _buildGroupsList() {
    if (CollectionUtils.isEmpty(widget.groups)) {
      return Container();
    }
    List<Widget> groupWidgetList = [];
    for (Group group in widget.groups!) {
      if (group.id != null) {
        groupWidgetList.add(ToggleRibbonButton(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
            label: group.title,
            toggled: _selectedGroupIds.contains(group.id),
            onTap: () => _onTapGroup(group.id!),
            textStyle: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold)
        ));
      }

    }
    return Column(children: groupWidgetList);
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

  void _onTapClose() {
    Navigator.of(context).pop(<Group>[]);
  }
}