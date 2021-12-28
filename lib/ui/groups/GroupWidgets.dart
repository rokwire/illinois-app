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
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Content.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/events/CreateEventPanel.dart';
import 'package:illinois/ui/groups/GroupDetailPanel.dart';
import 'package:illinois/ui/groups/GroupPostDetailPanel.dart';
import 'package:illinois/ui/groups/GroupsEventDetailPanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:sprintf/sprintf.dart';

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
    TextStyle valueStyle = TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold);
    TextStyle hintStyle = TextStyle(color: Styles().colors!.mediumGray, fontSize: 16, fontFamily: Styles().fontFamilies!.regular);

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
                    accentColor: Styles().colors!.white,
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
                    style: TextStyle(color: Styles().colors!.mediumGray, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
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
            Container(height: 20,),
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
                          style: TextStyle(
                              fontFamily: isSelected? Styles().fontFamilies!.bold : Styles().fontFamilies!.regular,
                              color: Styles().colors!.fillColorPrimary,
                              fontSize: 16),
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
                style: TextStyle(color: Styles().colors!.mediumGray, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
              ),
            ),
            Container(height: 20,),
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
              Text(title!, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: enabled ? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent),),
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
            Analytics.instance.logSelect(target: "Back");
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
                      style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20, color: Styles().colors!.white),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Expanded(child:
                        ScalableRoundedButton(
                          label: Localization().getStringEx('headerbar.back.title', "Back"),
                          fontFamily: "ProximaNovaRegular",
                          textColor: Styles().colors!.fillColorPrimary,
                          borderColor: Styles().colors!.white,
                          backgroundColor: Styles().colors!.white,
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          onTap: (){
                            Analytics.instance.logAlert(text: message, selection: "Back");
                            Navigator.pop(context);
                          },
                        )),
                      Container(width: 16,),
                      Expanded(child:
                        ScalableRoundedButton(
                          label: buttonTitle,
                          fontFamily: "ProximaNovaBold",
                          textColor: Styles().colors!.fillColorPrimary,
                          borderColor: Styles().colors!.fillColorSecondary,
                          backgroundColor: Styles().colors!.white,
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          onTap: (){
                            Analytics.instance.logAlert(text: message, selection: buttonTitle);
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
  final GroupEvent? groupEvent;
  final Group? group;
  final bool isAdmin;

  GroupEventCard({this.groupEvent, this.group, this.isAdmin = false});

  @override
  createState()=> _GroupEventCardState();
}
class _GroupEventCardState extends State<GroupEventCard>{
  bool _showAllComments = false;

  @override
  Widget build(BuildContext context) {
    GroupEvent? event = widget.groupEvent;
    List<Widget> content = [
      _EventContent(event: event, isAdmin: widget.isAdmin, group: widget.group,),
    ];
    List<Widget> content2 = [];

    if(_canPostComment){
      content2.add(
          Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              child:_buildAddPostButton(photoUrl: Groups().getUserMembership(widget.group?.id)?.photoURL,
                  onTap: (){
                    Analytics().logSelect(target: "Add post");
                    //TBD: remove if not used
                    // Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupCreatePostPanel(groupEvent: widget.groupEvent,groupId: widget.group?.id,)));
                  }))
      );
    }

    if (0 < (event?.comments?.length ?? 0)) {
      content.add(Container(color: Styles().colors!.surfaceAccent, height: 1,));

      for (GroupEventComment? comment in event!.comments!) {
        content2.add(_buildComment(comment!));
        if(!_showAllComments){
          break;
        }
      }
      if(!_showAllComments && (1 < (event.comments?.length ?? 0))){
        content2.add(
            Container(color: Styles().colors!.fillColorSecondary,height: 1,margin: EdgeInsets.only(top:12, bottom: 10),)
        );
        content2.add(
            Semantics(
              button: true,
              child: GestureDetector(
                onTap: (){
                  Analytics().logSelect(target: "See previous posts");
                  setState(() {
                    _showAllComments = true;
                  });},
                child: Center(child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(Localization().getStringEx("panel.group_detail.button.previous_post.title", "See previous posts")!, style: TextStyle(fontSize: 16,
                        fontFamily: Styles().fontFamilies!.bold,
                        color: Styles().colors!.fillColorPrimary),),
                    Padding(
                      padding: EdgeInsets.only(left: 7), child: Image.asset('images/icon-down-orange.png', color:  Styles().colors!.fillColorPrimary,),),
                  ],),
                ),),
            )
        );
        content2.add(Container(height: 7,));
      }

      content.add(Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children:content2))
      );

    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
            color: Styles().colors!.white,
            boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))],
            borderRadius: BorderRadius.all(Radius.circular(8))
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: content,),
      ),
    );
  }

  Widget _buildComment(GroupEventComment comment){
    String? memberName = comment.member!.name;
    String postDate = AppDateTime.timeAgoSinceDate(comment.dateCreated!);
    return
      Semantics(
          label: "$memberName posted, $postDate: ${comment.text}",
          excludeSemantics: true,
          child:Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: Styles().colors!.white,
                    boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
                    borderRadius: BorderRadius.all(Radius.circular(4))
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Container(height: 32, width: 32,
                      decoration: AppString.isStringNotEmpty(comment.member?.photoURL)
                          ? BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(image:NetworkImage(comment.member!.photoURL!), fit: BoxFit.cover))
                          : null,
                    ),
                    Expanded(
                      flex: 5,
                      child: Padding(padding:EdgeInsets.only(left: 8) , child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        Padding(padding: EdgeInsets.only(bottom: 2), child:
                        Text(comment.member!.name! , style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 14, color: Styles().colors!.fillColorPrimary),),
                        ),
                        Text(postDate, style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 12, color: Styles().colors!.textBackground),)
                      ],),),),
                  ],),
                  Padding(padding: EdgeInsets.only(top:8), child:
                  Text(comment.text!, style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textBackground),)
                  ),
                ],),
              )));
  }

  Widget _buildAddPostButton({String? photoUrl,void onTap()?}){
    return
      InkWell(
          onTap: onTap,
          child: Container(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              photoUrl == null ? Container():
              Container(height: 32, width: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(image:NetworkImage(photoUrl), fit: BoxFit.cover),
                ),
              ),
              Container(width: 6,),
              Expanded(child:
              Container(
                  height: 45,
                  alignment: Alignment.centerLeft,
                  padding:EdgeInsets.symmetric(horizontal: 12) ,
                  decoration: BoxDecoration(
                      color: Styles().colors!.white,
                      boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))],
                      borderRadius: BorderRadius.all(Radius.circular(8))
                  ),
                  child:
                  Text(Localization().getStringEx("panel.group_detail.button.add_post.title", "Add a public post ...")!,style: TextStyle(fontSize: 16, color: Styles().colors!.textSurface, fontFamily: Styles().fontFamilies!.regular),)
              ))
            ],),
          ));
  }

  bool get _canPostComment{
    return widget.isAdmin && false; //TBD for now hide all comment options. Determine who can add comment
  }
}

class _EventContent extends StatefulWidget {
  final Group? group;
  final Event? event;
  final bool isAdmin;

  _EventContent({this.event, this.isAdmin = false, this.group});

  @override
  createState()=> _EventContentState();
}

class _EventContentState extends State<_EventContent> implements NotificationsListener {
  static const double _smallImageSize = 64;

  @override
  void initState() {
    NotificationService().subscribe(this, Auth2UserPrefs.notifyFavoritesChanged);
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
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {

    bool isFavorite = widget.event!.isFavorite;

    List<Widget> content = [
      Padding(padding: EdgeInsets.only(bottom: 8, right: 8), child:
        Container(constraints: BoxConstraints(minHeight: 64), child:
          Text(widget.event?.title ?? '',  style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20, color: Styles().colors!.fillColorPrimary),),
      )),
    ];
    content.add(Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Row(children: <Widget>[
      Padding(padding: EdgeInsets.only(right: 8), child: Image.asset('images/icon-calendar.png'),),
      Expanded(child:
      Text(widget.event!.timeDisplayString!,  style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 14, color: Styles().colors!.textBackground),)
      ),
    ],)),);

    return Stack(children: <Widget>[
      GestureDetector(onTap: () {
        Analytics().logSelect(target: "Group Event");
        Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupEventDetailPanel(event: widget.event, group: widget.group, previewMode: widget.isAdmin,)));
      },
          child: Padding(padding: EdgeInsets.only(left:16, right: 80, top: 16, bottom: 16), child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: content),
          )
      ),
      Align(alignment: Alignment.topRight, child:
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Semantics(
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
                child: GestureDetector(onTap: _onFavoriteTap, child:
                  Container(width: 42, height: 42, alignment: Alignment.center, child:
                    Image.asset(isFavorite ? 'images/icon-star-selected.png' : 'images/icon-star.png'),
                  ),
                )),

              !widget.isAdmin? Container(width: 0, height: 0) :
              Semantics(label: Localization().getStringEx("panel.group_detail.label.options", "Options"), button: true,child:
                GestureDetector(onTap: () { _onOptionsTap();}, child:
                  Container(width: 42, height: 42, alignment: Alignment.center, child:
                    Image.asset('images/icon-groups-options-orange.png'),
                  ),
                ),
              )
            ],),
            Visibility(visible:
                AppString.isStringNotEmpty(widget.event?.exploreImageURL),
                child: Padding(
                  padding: EdgeInsets.only(left: 12, right: 12, bottom: 8, top: 8),
                  child: SizedBox(
                    width: _smallImageSize,
                    height: _smallImageSize,
                    child: Image.network(
                      widget.event!.exploreImageURL!, excludeFromSemantics: true, fit: BoxFit.fill,),),)),
                ])
                )
    ],);
  }

  void _onFavoriteTap() {
    Analytics.instance.logSelect(target: "Favorite: ${widget.event?.title}");
    Auth2().prefs?.toggleFavorite(widget.event);
  }

  void _onOptionsTap(){
    Analytics.instance.logSelect(target: "Options");
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context){
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 16,vertical: 17),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(height: 48,),
                !_canDelete? Container():
                  RibbonButton(
                    height: null,
                    leftIcon: "images/icon-leave-group.png",
                    label:Localization().getStringEx("panel.group_detail.button.delete_event.title", "Remove group event"),
                    onTap: (){
                      Analytics().logSelect(target: "Remove group event");
                      showDialog(context: context, builder: (context)=>_buildRemoveEventDialog(context)).then((value) => Navigator.pop(context));
                    },
                  ),
                !_canEdit? Container():
                  RibbonButton(
                    height: null,
                    leftIcon: "images/icon-edit.png",
                    label:Localization().getStringEx("panel.group_detail.button.edit_event.title", "Edit Event"),
                    onTap: (){
                      _onEditEventTap(context);
                    },
                  ),
              ],
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

  void _onEditEventTap(BuildContext context){
    Analytics().logSelect(target: "Update Event");
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEventPanel(group: widget.group, editEvent: widget.event, onEditTap: (BuildContext context, Event event) {
      Groups().updateGroupEvents(event).then((String? id) {
        if (AppString.isStringNotEmpty(id)) {
          Navigator.pop(context);
        }
        else {
          AppAlert.showDialogResult(context, "Unable to update event");
        }
      });
    })));
  }

  bool get _canEdit {
    return widget.isAdmin && AppString.isStringNotEmpty(widget.event?.createdByGroupId);
  }

  bool get _canDelete{
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
                      Localization().getStringEx("widget.add_image.heading", "Select Image")!,
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: Styles().fontFamilies!.medium,
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
                            fontFamily: Styles().fontFamilies!.medium,
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
                              borderColor: Styles().colors!.fillColorSecondary,
                              backgroundColor: Styles().colors!.background,
                              textColor: Styles().colors!.fillColorPrimary,
                              onTap: _onTapUseUrl)),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                              padding: EdgeInsets.all(10),
                              child: RoundedButton(
                                  label:  Localization().getStringEx("widget.add_image.button.chose_device.label","Choose from device"),
                                  borderColor: Styles().colors!.fillColorSecondary,
                                  backgroundColor: Styles().colors!.background,
                                  textColor: Styles().colors!.fillColorPrimary,
                                  onTap: _onTapChooseFromDevice)),
                          _showProgress ? CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorPrimary)) : Container(),
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
      AppToast.show(Localization().getStringEx("widget.add_image.validation.url.label","Please enter an url")!);
      return;
    }

    bool isReadyUrl = url.endsWith(".webp");
    if (isReadyUrl) {
      //ready
      AppToast.show(Localization().getStringEx("widget.add_image.validation.success.label","Successfully added an image")!);
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
          case ImagesResultType.CANCELLED:
          //do nothing
            break;
          case ImagesResultType.ERROR_OCCURRED:
            AppToast.show(logicResult.errorMessage!);
            break;
          case ImagesResultType.SUCCEEDED:
          //ready
            AppToast.show(Localization().getStringEx("widget.add_image.validation.success.label","Successfully added an image")!);
            Navigator.pop(context, logicResult.data);
            break;
          default:
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

    Future<ImagesResult?> result =
    Content().selectImageFromDevice(storagePath: _groupImageStoragePath, width: _groupImageWidth);
    result.then((logicResult) {
      setState(() {
        _showProgress = false;
      });

      ImagesResultType? resultType = logicResult!.resultType;
      switch (resultType) {
        case ImagesResultType.CANCELLED:
        //do nothing
          break;
        case ImagesResultType.ERROR_OCCURRED:
          AppToast.show(logicResult.errorMessage!);
          break;
        case ImagesResultType.SUCCEEDED:
        //ready
          AppToast.show(Localization().getStringEx("widget.add_image.validation.success.label","Successfully added an image")!);
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

class GroupCard extends StatelessWidget {
  final Group? group;
  final GroupCardDisplayType displayType;

  GroupCard({required this.group, this.displayType = GroupCardDisplayType.allGroups});

  @override
  Widget build(BuildContext context) {
    String? pendingCountText = sprintf(Localization().getStringEx("widget.group_card.pending.label", "Pending: %s")!, [AppString.getDefaultEmptyString(group!.pendingCount.toString())]);
    return GestureDetector(
        onTap: () => _onTapCard(context),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Styles().colors!.white,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  _buildHeading(),
                  Container(height: 3),
                  Row(children: [
                    Expanded(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            child: Text(group?.title ?? "",
                                overflow: TextOverflow.ellipsis,
                                maxLines: displayType == GroupCardDisplayType.homeGroups? 2 : 10,
                                style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20, color: Styles().colors!.fillColorPrimary))))
                  ]),
                  (displayType == GroupCardDisplayType.homeGroups) ? Expanded(child: Container()) :Container(),
                  Visibility(
                    visible: (group?.currentUserIsAdmin ?? false) && (group!.pendingCount > 0),
                    child: Text(pendingCountText,
                      overflow: TextOverflow.ellipsis,
                      maxLines: displayType == GroupCardDisplayType.homeGroups? 2 : 10,
                      style: TextStyle(
                          fontFamily: Styles().fontFamilies!.regular,
                          fontSize: 16,
                          color: Styles().colors!.textBackgroundVariant,

                      ),
                    ),
                  ),
                  Container(height: 4),
                  (displayType == GroupCardDisplayType.myGroup || displayType == GroupCardDisplayType.homeGroups ) ? _buildUpdateTime() : Container()
                ]))));
  }

  Widget _buildHeading() {
    List<Widget> leftContent = <Widget>[];

    if (group?.currentUserAsMember?.status != null) {
      leftContent.add(
        Semantics(
          label: "status: ${group?.currentUserStatusText?.toLowerCase() ?? ""} ,for: ",
          excludeSemantics: true,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: group!.currentUserStatusColor, borderRadius: BorderRadius.all(Radius.circular(2))),
            child: Text(group!.currentUserStatusText!.toUpperCase(),
              style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 12, color: Styles().colors!.white)))),
      );
    }

    String? groupCategory = AppString.getDefaultEmptyString(group?.category, defaultValue: Localization().getStringEx("panel.groups_home.label.category", "Category")!);
    if (AppString.isStringNotEmpty(groupCategory)) {
      if (leftContent.isNotEmpty) {
        leftContent.add(Container(height: 6,));
      }
      leftContent.add(
        Text(groupCategory, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary),
          overflow: TextOverflow.ellipsis,
          maxLines: displayType == GroupCardDisplayType.homeGroups? 2 : 10,)
      );
    }

    List<Widget> rightContent = <Widget>[];

    String? privacyStatus;
    if (group?.privacy == GroupPrivacy.private) {
      privacyStatus = Localization().getStringEx('widget.group_card.status.private', 'Private') ;
    }

    if (privacyStatus != null) {
      rightContent.add(
        Semantics(
          label: sprintf(Localization().getStringEx('widget.group_card.status.hint', 'status: %s ,for: ')!, [privacyStatus]),
          excludeSemantics: true,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Styles().colors!.fillColorSecondary, borderRadius: BorderRadius.all(Radius.circular(2))),
            child: Text(privacyStatus.toUpperCase(),
              style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 12, color: Styles().colors!.white)))),
      );
    }

    List<Widget> content = <Widget>[];
    if (leftContent.isNotEmpty) {
      content.add(Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: leftContent,)));
    }

    if (rightContent.isNotEmpty) {
      if (leftContent.isEmpty) {
        content.add(Expanded(child: Container()));
      }
      content.add(Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: rightContent,));
    }

    return content.isNotEmpty ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: content,) : Container(width: 0, height: 0);
  }


  Widget _buildUpdateTime() {
    return Container(
        child: Text(
          _timeUpdatedText,
          maxLines: displayType == GroupCardDisplayType.homeGroups? 2 : 10,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 14, color: Styles().colors!.textSurface,),
    ));
  }

  void _onTapCard(BuildContext context) {
    Analytics.instance.logSelect(target: "Group: ${group!.title}");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupDetailPanel(group: group)));
  }

  String get _timeUpdatedText {
    return group!.displayUpdateTime ?? '';
  }
}

//////////////////////////////////////
// GroupPostCard

class GroupPostCard extends StatefulWidget {
  final GroupPost? post;
  final Group? group;
  final Function? onImageTap;

  GroupPostCard({Key? key, required this.post, required this.group, this.onImageTap}) :
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
    String? memberName = widget.post?.member?.name;
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
                          child: Text(AppString.getDefaultEmptyString(widget.post!.subject),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 18, color: Styles().colors!.fillColorPrimary))),
                      Visibility(
                          visible: isRepliesLabelVisible,
                          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                            Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(AppString.getDefaultEmptyString(visibleRepliesCount.toString()),
                                    style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 14))),
                            Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(AppString.getDefaultEmptyString(repliesLabel),
                                    style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 14)))
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
                        AppString.isStringEmpty(imageUrl)? Container() :
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: (){
                              if(widget.onImageTap!=null){
                                widget.onImageTap!();
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.only(left: 8, bottom: 8, top: 8),
                              child: SizedBox(
                                width: _smallImageSize,
                                height: _smallImageSize,
                                child: Image.network(imageUrl!, excludeFromSemantics: true, fit: BoxFit.fill,),),))
                          )
                    ],),
                    Container(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child:Container(
                              padding: EdgeInsets.only(right: 6),
                              child:Text(AppString.getDefaultEmptyString(memberName),
                                textAlign: TextAlign.left,
                                style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 14, color: Styles().colors!.fillColorPrimary)),
                          )),
                          Expanded(
                            flex: 2,
                            child: Semantics(child: Container(
                              padding: EdgeInsets.only(left: 6),
                              child: Text(AppString.getDefaultEmptyString(widget.post?.displayDateTime),
                                semanticsLabel: "Updated ${widget.post?.getDisplayDateTime() ?? ""} ago",
                                textAlign: TextAlign.right,
                                style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 14, color: Styles().colors!.fillColorPrimary))),
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
    Analytics.instance.logSelect(target: url);
    if (AppString.isStringNotEmpty(url)) {
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
  final void Function()? onImageTap;

  GroupReplyCard({@required this.reply, @required this.post, @required this.group, this.iconPath, this.onIconTap, this.semanticsLabel, this.showRepliesCount = true, this.onCardTap, this.onImageTap});

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
    String? bodyText = AppString.getDefaultEmptyString(widget.reply?.body);
    if (widget.reply?.isUpdated ?? false) {
      bodyText +=
          ' <span>(${Localization().getStringEx('widget.group.card.reply.edited.reply.label', 'edited')})</span>';
    }
    return Semantics(container: true,
      child:Container(
        decoration: BoxDecoration(
            color: Styles().colors!.white,
            boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))],
            borderRadius: BorderRadius.all(Radius.circular(8))),
        child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Semantics( child:
                  Text(AppString.getDefaultEmptyString(widget.reply?.member?.name),
                    style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary)),
                ),
                Visibility(
                    visible: AppString.isStringNotEmpty(widget.iconPath),
                    child: Semantics( child:Container(
                    child: Semantics(label: widget.semanticsLabel??"", button: true,
                    child: GestureDetector(
                        onTap: widget.onIconTap,
                        child: Padding(
                            padding: EdgeInsets.only(left: 10, top: 3),
                            child: (AppString.isStringNotEmpty(widget.iconPath) ? Image.asset(widget.iconPath!, excludeFromSemantics: true,) : Container())))))))
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
                  AppString.isStringEmpty(widget.reply?.imageUrl)? Container() :
                  Expanded(
                      flex: 1,
                      child:
                      GestureDetector(
                        onTap: (){
                          if(widget.onImageTap!=null){
                            widget.onImageTap!();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.only(left: 8, bottom: 8, top: 8),
                          child: SizedBox(
                          width: _smallImageSize,
                          height: _smallImageSize,
                           child: Image.network(widget.reply!.imageUrl!, excludeFromSemantics: true, fit: BoxFit.fill,),),))
                  )
                ],),
              Semantics( button: true, child:
                GestureDetector(
                  onTap: widget.onCardTap ?? _onTapCard,
                  child: Container(
                    padding: EdgeInsets.only(top: 12),
                    child: Row(children: [
                      Expanded(
                          child: Container(
                            child: Semantics(child: Text(AppString.getDefaultEmptyString(widget.reply?.displayDateTime),
                                semanticsLabel: "Updated ${widget.reply?.getDisplayDateTime() ?? ""} ago",
                                style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 14, color: Styles().colors!.fillColorPrimary))),)),
                      Visibility(
                        visible: isRepliesLabelVisible,
                        child: Expanded(child: Container(
                          child: Semantics(child: Text("$visibleRepliesCount $repliesLabel",
                              textAlign: TextAlign.right,
                              style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 14, decoration: TextDecoration.underline,)
                        ))),
                      ))
                ],),)))
            ]))));
  }

  void _onLinkTap(String? url) {
    Analytics.instance.logSelect(target: url);
    if (AppString.isStringNotEmpty(url)) {
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

class ModalImageDialog extends StatelessWidget{
  final String? imageUrl;
  final GestureTapCallback? onClose;

  ModalImageDialog({this.imageUrl, this.onClose});

  static  Widget modalDialogContainer({Widget? content, String? imageUrl, GestureTapCallback? onClose}){
      return Stack(children: [
        content ?? Container(),
        buildModalPhotoDialog(imageUrl: imageUrl, onClose: onClose)
      ]);
  }

  static Widget buildModalPhotoDialog({String? imageUrl, GestureTapCallback? onClose}){
    return imageUrl!=null ? ModalImageDialog(
        imageUrl: imageUrl,
        onClose: onClose
    ) : Container();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: PinchZoom(
        child: GestureDetector(
        onTap: onClose, //dismiss
        child: Container(
            color: Styles().colors!.blackTransparent06,
            child:Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                    child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: GestureDetector(
                            onTap: (){}, //Do not dismiss when tap the dialog
                            child: Container(
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      color: Styles().colors!.fillColorPrimary,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: <Widget>[
                                          GestureDetector(
                                            onTap: onClose,
                                            child: Padding(
                                              padding: EdgeInsets.only(right: 10, top: 10),
                                              child: Text('\u00D7',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: Styles().fontFamilies!.medium,
                                                    fontSize: 50
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    Container(
                                      child: AppString.isStringNotEmpty(imageUrl) ? Image.network(imageUrl!, excludeFromSemantics: true, fit: BoxFit.fitWidth,): Container(),
                                    )
                                  ],
                                ))
                        )
                    )
                ),
              ],
            )))
    ))
    ],);
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
                                      'Link')!,
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.black,
                                      fontFamily:
                                      Styles().fontFamilies!.medium)))))
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
                    decoration: InputDecoration(
                        hintText: _hint,
                        border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Styles().colors!.mediumGray!,
                                width: 0.0))),
                    style: TextStyle(
                        color: Styles().colors!.textBackground,
                        fontSize: 16,
                        fontFamily: Styles().fontFamilies!.regular))),
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
    _linkTextController.text = AppString.getDefaultEmptyString(_bodyController.selection.textInside(_bodyController.text));
    AppAlert.showCustomDialog(
        context: context,
        contentWidget: _buildLinkDialog(),
        actions: [
          TextButton(
              onPressed: () {
                Analytics().logSelect(target: 'Set Link Url');
                _onTapOkLink(linkStartPosition, linkEndPosition);
              },
              child: Text(Localization().getStringEx('dialog.ok.title', 'OK')!)),
          TextButton(
              onPressed: () {
                Analytics().logSelect(target: 'Cancel');
                Navigator.of(context).pop();
              },
              child: Text(
                  Localization().getStringEx('dialog.cancel.title', 'Cancel')!))
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
    String result = AppString.wrapRange(
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
                  'Edit Link')!,
              style: TextStyle(
                  fontSize: 20,
                  color: Styles().colors!.fillColorPrimary,
                  fontFamily: Styles().fontFamilies!.medium)),
          Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                  Localization().getStringEx(
                      'panel.group.detail.post.create.dialog.link.text.label',
                      'Link Text:')!,
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: Styles().fontFamilies!.regular,
                      color: Styles().colors!.fillColorPrimary))),
          Padding(
              padding: EdgeInsets.only(top: 6),
              child: TextField(
                  controller: _linkTextController,
                  maxLines: 1,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Styles().colors!.mediumGray!, width: 0.0))),
                  style: TextStyle(
                      color: Styles().colors!.textBackground,
                      fontSize: 16,
                      fontFamily: Styles().fontFamilies!.regular))),
          Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                  Localization().getStringEx(
                      'panel.group.detail.post.create.dialog.link.url.label',
                      'Link URL:')!,
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: Styles().fontFamilies!.regular,
                      color: Styles().colors!.fillColorPrimary))),
          Padding(
              padding: EdgeInsets.only(top: 6),
              child: TextField(
                  controller: _linkUrlController,
                  maxLines: 1,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Styles().colors!.mediumGray!, width: 0.0))),
                  style: TextStyle(
                      color: Styles().colors!.textBackground,
                      fontSize: 16,
                      fontFamily: Styles().fontFamilies!.regular)))
        ]);
  }
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

  const ImageChooserWidget({Key? key, this.imageUrl, this.onImageChanged, this.wrapContent = false, this.showSlant = true, this.buttonVisible = false}) : super(key: key);

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
          AppString.isStringNotEmpty(imageUrl)
              ? Positioned.fill(child: Image.network(imageUrl!, excludeFromSemantics: true, fit: BoxFit.cover))
              : Container(),
          Visibility( visible: showSlant,
              child: CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.fillColorSecondaryTransparent05, left: false), child: Container(height: 53))),
          Visibility( visible: showSlant,
              child: CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.background), child: Container(height: 30))),
          AppString.isStringEmpty(imageUrl) || explicitlyShowAddButton
              ? Container(
              child: Center(
                  child: Semantics(
                      label: Localization().getStringEx("panel.group.detail.post.add_image", "Add cover image"),
                      hint: Localization().getStringEx("panel.group.detail.post.add_image.hint", ""),
                      button: true,
                      excludeSemantics: true,
                      child: ScalableSmallRoundedButton(
                          maxLines: 2,
                          label:AppString.isStringEmpty(imageUrl)? Localization().getStringEx("panel.group.detail.post.add_image", "Add image") : Localization().getStringEx("panel.group.detail.post.change_image", "Edit Image"), // TBD localize
                          textColor: Styles().colors!.fillColorPrimary,
                          onTap: (){ _onTapAddImage();}
                      )))):
          Container()
        ]));
  }

  void _onTapAddImage() async {
    Analytics.instance.logSelect(target: "Add Image");
    String imageUrl = await showDialog(context: context, builder: (_) => Material(type: MaterialType.transparency, child: GroupAddImageWidget()));
    if (AppString.isStringNotEmpty(imageUrl) && (widget.onImageChanged != null)) {
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