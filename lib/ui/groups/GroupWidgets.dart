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
import 'package:illinois/model/Event.dart';
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/events/CreateEventPanel.dart';
import 'package:illinois/ui/groups/GroupCreatePostPanel.dart';
import 'package:illinois/ui/groups/GroupsEventDetailPanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/utils/Utils.dart';

/////////////////////////////////////
// GroupDropDownButton

typedef GroupDropDownDescriptionDataBuilder<T> = String Function(T item);

class GroupDropDownButton<T> extends StatefulWidget{
  final String emptySelectionText;
  final String buttonHint;

  final T initialSelectedValue;
  final List<T> items;
  final GroupDropDownDescriptionDataBuilder<T> constructTitle;
  final GroupDropDownDescriptionDataBuilder<T> constructDescription;
  final Function onValueChanged;

  final EdgeInsets padding;
  final BoxDecoration decoration;

  GroupDropDownButton({Key key, this.emptySelectionText,this.buttonHint, this.initialSelectedValue, this.items, this.onValueChanged,
    this.constructTitle, this.constructDescription, this.padding = const EdgeInsets.only(left: 12, right: 8), this.decoration}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GroupDropDownButtonState<T>();
  }
}

class _GroupDropDownButtonState<T> extends State<GroupDropDownButton>{
  T selectedValue;

  @override
  void initState() {
    selectedValue = widget.initialSelectedValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle valueStyle = TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold);
    TextStyle hintStyle = TextStyle(color: Styles().colors.mediumGray, fontSize: 16, fontFamily: Styles().fontFamilies.regular);

    String buttonTitle = _getButtonTitleText();
    String buttonDescription = _getButtonDescriptionText();
    return Container (
        decoration: widget.decoration != null
            ? widget.decoration
            : BoxDecoration(
            color: Styles().colors.white,
            border: Border.all(
                color: Styles().colors.surfaceAccent,
                width: 1),
            borderRadius:
            BorderRadius.all(Radius.circular(4))),
        padding: widget.padding,
        child:
        Column( crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Semantics(
                label: buttonTitle,
                hint: widget.buttonHint,
                excludeSemantics: true,
                child: Theme(
                  data: ThemeData( /// This is as a workaround to make dropdown backcolor always white according to Miro & Zepplin wireframes
                    hoverColor: Styles().colors.white,
                    focusColor: Styles().colors.white,
                    canvasColor: Styles().colors.white,
                    primaryColor: Styles().colors.white,
                    accentColor: Styles().colors.white,
                    highlightColor: Styles().colors.white,
                    splashColor: Styles().colors.white,
                  ),
                  child: DropdownButton(
                      icon: Image.asset('images/icon-down-orange.png'),
                      isExpanded: true,
                      focusColor: Styles().colors.white,
                      underline: Container(),
                      hint: Text(buttonTitle ?? "", style: selectedValue == null?hintStyle:valueStyle),
                      items: _constructItems(),
                      onChanged: (value){
                        selectedValue = value;
                        widget.onValueChanged(value);
                        setState(() {});
                      }),
                ),
              ),
              buttonDescription==null? Container():
              Container(
                padding: EdgeInsets.only(right: 42, bottom: 12),
                child: Text(buttonDescription,
                  style: TextStyle(color: Styles().colors.mediumGray, fontSize: 16, fontFamily: Styles().fontFamilies.regular),
                ),
              )
            ]
        )
    );
  }

  Widget _buildDropDownItem(String title, String description, bool isSelected){
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
                              fontFamily: isSelected? Styles().fontFamilies.bold : Styles().fontFamilies.regular,
                              color: Styles().colors.fillColorPrimary,
                              fontSize: 16),
                        ),
                      )),
                  isSelected
                      ? Image.asset("images/checkbox-selected.png")
                      : Image.asset("images/oval-orange.png")
                ]),
            description==null? Container() : Container(height: 6,),
            description==null? Container():
            Container(
              padding: EdgeInsets.only(right: 30),
              child: Text(description,
                style: TextStyle(color: Styles().colors.mediumGray, fontSize: 16, fontFamily: Styles().fontFamilies.regular),
              ),
            ),
            Container(height: 20,),
            Container(height: 1, color: Styles().colors.fillColorPrimaryTransparent03,)
          ],)
    );
  }

  String _getButtonDescriptionText(){
    if(selectedValue!=null){
      return widget.constructDescription!=null? widget.constructDescription(selectedValue) : null;
    } else {
      //empty null for now
      return null;
    }
  }

  String _getButtonTitleText(){
    if(selectedValue!=null){
      return widget.constructTitle!=null? widget.constructTitle(selectedValue) : selectedValue.toString();
    } else {
      return widget.emptySelectionText;
    }
  }

  List<DropdownMenuItem<dynamic>> _constructItems(){
    int optionsCount = widget.items?.length ?? 0;
    if (optionsCount == 0) {
      return null;
    }
    return widget.items.map((Object item) {
      String name = widget.constructTitle!=null? widget.constructTitle(item) : item?.toString();
      String description = widget.constructDescription!=null? widget.constructDescription(item) : null;
      bool isSelected = selectedValue!=null && selectedValue == item;
      return DropdownMenuItem<dynamic>(
        value: item,
        child: item!=null? _buildDropDownItem(name,description,isSelected): Container(),
      );
    }).toList();
  }

}

/////////////////////////////////////
// GroupMembershipAddButton

class GroupMembershipAddButton extends StatelessWidget {
  final String             title;
  final GestureTapCallback onTap;
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
              Text(title, style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: enabled ? Styles().colors.fillColorPrimary : Styles().colors.surfaceAccent),),
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
          icon: Image.asset('images/chevron-left-white.png'),
          onPressed: (){
            Analytics.instance.logSelect(target: "Back");
            Navigator.pop(context);
          }),
    );
  }
}

class GroupsConfirmationDialog extends StatelessWidget{
  final String message;
  final String buttonTitle;
  final Function onConfirmTap;

  const GroupsConfirmationDialog({Key key, this.message, this.buttonTitle, this.onConfirmTap}) : super(key: key);

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
                      message,
                      textAlign: TextAlign.left,
                      style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 20, color: Styles().colors.white),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Expanded(child:
                        ScalableRoundedButton(
                          label: Localization().getStringEx('headerbar.back.title', "Back"),
                          fontFamily: "ProximaNovaRegular",
                          textColor: Styles().colors.fillColorPrimary,
                          borderColor: Styles().colors.white,
                          backgroundColor: Styles().colors.white,
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          onTap: ()=>Navigator.pop(context),
                        )),
                      Container(width: 16,),
                      Expanded(child:
                        ScalableRoundedButton(
                          label: buttonTitle,
                          fontFamily: "ProximaNovaBold",
                          textColor: Styles().colors.fillColorPrimary,
                          borderColor: Styles().colors.fillColorSecondary,
                          backgroundColor: Styles().colors.white,
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          onTap: (){
                            onConfirmTap();
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
  final GroupEvent groupEvent;
  final Group group;
  final bool isAdmin;

  GroupEventCard({this.groupEvent, this.group, this.isAdmin = false});

  @override
  createState()=> _GroupEventCardState();
}
class _GroupEventCardState extends State<GroupEventCard>{
  bool _showAllComments = false;

  @override
  Widget build(BuildContext context) {
    GroupEvent event = widget.groupEvent;
    List<Widget> content = [
      _EventContent(event: event, isAdmin: widget.isAdmin, group: widget.group,),
    ];
    List<Widget> content2 = [];

    if(widget.isAdmin){
      content2.add(
          Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              child:_buildAddPostButton(photoUrl: Groups().getUserMembership(widget.group?.id)?.photoURL,
                  onTap: (){
                    Analytics().logPage(name: "Add post");
                    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupCreatePostPanel(groupEvent: widget.groupEvent,groupId: widget.group?.id,)));
                  }))
      );
    }

    if (0 < (event?.comments?.length ?? 0)) {
      content.add(Container(color: Styles().colors.surfaceAccent, height: 1,));

      for (GroupEventComment comment in event.comments) {
        content2.add(_buildComment(comment));
        if(!_showAllComments){
          break;
        }
      }
      if(!_showAllComments && (1 < (event?.comments?.length ?? 0))){
        content2.add(
            Container(color: Styles().colors.fillColorSecondary,height: 1,margin: EdgeInsets.only(top:12, bottom: 10),)
        );
        content2.add(
            Semantics(
              button: true,
              child: GestureDetector(
                onTap: (){
                  setState(() {
                    _showAllComments = true;
                  });},
                child: Center(child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(Localization().getStringEx("panel.group_detail.button.previous_post.title", "See previous posts"), style: TextStyle(fontSize: 16,
                        fontFamily: Styles().fontFamilies.bold,
                        color: Styles().colors.fillColorPrimary),),
                    Padding(
                      padding: EdgeInsets.only(left: 7), child: Image.asset('images/icon-down-orange.png', color:  Styles().colors.fillColorPrimary,),),
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
            color: Styles().colors.white,
            boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))],
            borderRadius: BorderRadius.all(Radius.circular(8))
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: content,),
      ),
    );
  }

  Widget _buildComment(GroupEventComment comment){
    String memberName = comment.member.name;
    String postDate = AppDateTime.timeAgoSinceDate(comment.dateCreated);
    return
      Semantics(
          label: "$memberName posted, $postDate: ${comment.text}",
          excludeSemantics: true,
          child:Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: Styles().colors.white,
                    boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
                    borderRadius: BorderRadius.all(Radius.circular(4))
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Container(height: 32, width: 32,
                      decoration: AppString.isStringNotEmpty(comment?.member?.photoURL)
                          ? BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(image:NetworkImage(comment.member.photoURL), fit: BoxFit.cover))
                          : null,
                    ),
                    Expanded(
                      flex: 5,
                      child: Padding(padding:EdgeInsets.only(left: 8) , child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        Padding(padding: EdgeInsets.only(bottom: 2), child:
                        Text(comment.member.name , style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 14, color: Styles().colors.fillColorPrimary),),
                        ),
                        Text(postDate, style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 12, color: Styles().colors.textBackground),)
                      ],),),),
                  ],),
                  Padding(padding: EdgeInsets.only(top:8), child:
                  Text(comment.text, style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground),)
                  ),
                ],),
              )));
  }

  Widget _buildAddPostButton({String photoUrl,Function onTap}){
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
                      color: Styles().colors.white,
                      boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))],
                      borderRadius: BorderRadius.all(Radius.circular(8))
                  ),
                  child:
                  Text(Localization().getStringEx("panel.group_detail.button.add_post.title", "Add a public post ..."),style: TextStyle(fontSize: 16, color: Styles().colors.textSurface, fontFamily: Styles().fontFamilies.regular),)
              ))
            ],),
          ));
  }
}

class _EventContent extends StatelessWidget {
  final Group group;
  final Event event;
  final bool isAdmin;

  _EventContent({this.event, this.isAdmin = false, this.group});

  @override
  Widget build(BuildContext context) {

    List<Widget> content = [
      Padding(padding: EdgeInsets.only(bottom: 8, right: 48), child:
      Text(event?.title ?? '',  style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 20, color: Styles().colors.fillColorPrimary),),
      ),
    ];
    content.add(Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Row(children: <Widget>[
      Padding(padding: EdgeInsets.only(right: 8), child: Image.asset('images/icon-calendar.png'),),
      Expanded(child:
      Text(event.timeDisplayString,  style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 14, color: Styles().colors.textBackground),)
      ),
    ],)),);

    return Stack(children: <Widget>[
      GestureDetector(onTap: () {
        Analytics().logPage(name: "Group Settings");
        Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupEventDetailPanel(event: event,)));
      },
          child: Padding(padding: EdgeInsets.all(16), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: content),
          )
      ),
      Align(alignment: Alignment.topRight,
          child:
          Container(
            padding: EdgeInsets.only(top: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Semantics(
                    label: Localization().getStringEx("panel.group_detail.button.favorites.title", "Favorites"),
                    button: true,
                    child: GestureDetector(onTap: () { /*TBD switch favorite */ },
                      child: Container(
                        child: Image.asset('images/icon-star.png', excludeFromSemantics: true,),
                      ),
                    )),
                !isAdmin? Container() :
                Container(
                  padding: EdgeInsets.only(left: 12),
                  child:
                  GestureDetector(onTap: () { _onOptionsTap(context);},
                    child: Container(
                      child: Image.asset('images/icon-groups-options-orange.png'),
                    ),
                  ),
                )
              ],),))
    ],);
  }

  void _onOptionsTap(BuildContext context){
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
                RibbonButton(
                  height: null,
                  leftIcon: "images/icon-leave-group.png",
                  label:Localization().getStringEx("panel.group_detail.button.remove_event.title", "Remove Event"),
                  onTap: (){
                    showDialog(context: context, builder: (context)=>_buildRemoveEventDialog(context)).then((value) => Navigator.pop(context));
                  },
                ),
                RibbonButton(
                  height: null,
                  leftIcon: "images/icon-leave-group.png",
                  label:Localization().getStringEx("panel.group_detail.button.delete_event.title", "Delete Event"),
                  onTap: (){
                    showDialog(context: context, builder: (context)=>_buildDeleteEventDialog(context)).then((value) => Navigator.pop(context));
                  },
                ),
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
        message: Localization().getStringEx("panel.group_detail.button.remove_event.title",  "Remove this event from your group page?"),
        buttonTitle:Localization().getStringEx("panel.group_detail.button.remove.title", "Remove"),
        onConfirmTap:_onRemoveEvent);
  }

  Widget _buildDeleteEventDialog(BuildContext context){
    return GroupsConfirmationDialog(
        message: Localization().getStringEx("panel.group_detail.button.delete_event.title", "Delete this event from your groups page?"),
        buttonTitle:  Localization().getStringEx("panel.group_detail.button.delete.title","Delete"),
        onConfirmTap:_onDeleteEvent);
  }

  void _onRemoveEvent(BuildContext context){
    Groups().removeEventFromGroup(eventId: event.eventId, groupId: group.id).then((value){
      Navigator.of(context).pop();
    });
  }

  void _onDeleteEvent(BuildContext context){
    Groups().deleteEventFromGroup(eventId: event.eventId, groupId: group.id).then((value){
      Navigator.of(context).pop();
    });
  }

  void _onEditEventTap(BuildContext context){
    Analytics().logPage(name: "Create Event");
    Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEventPanel(group: group,)));
  }
}