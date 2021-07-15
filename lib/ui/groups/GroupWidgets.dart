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
import 'package:illinois/model/Event.dart';
import 'package:illinois/model/Groups.dart';
import 'package:illinois/model/ImageType.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/ImageService.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/ui/events/CreateEventPanel.dart';
import 'package:illinois/ui/groups/GroupCreatePostPanel.dart';
import 'package:illinois/ui/groups/GroupDetailPanel.dart';
import 'package:illinois/ui/groups/GroupViewPostPanel.dart';
import 'package:illinois/ui/groups/GroupsEventDetailPanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:sprintf/sprintf.dart';

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
                container: true,
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
              Semantics(container: true, child:
                Container(
                  padding: EdgeInsets.only(right: 42, bottom: 12),
                  child: Text(buttonDescription,
                    style: TextStyle(color: Styles().colors.mediumGray, fontSize: 16, fontFamily: Styles().fontFamilies.regular),
                  ),
                )
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

    if(_canPostComment){
      content2.add(
          Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              child:_buildAddPostButton(photoUrl: Groups().getUserMembership(widget.group?.id)?.photoURL,
                  onTap: (){
                    Analytics().logPage(name: "Add post");
                    //TBD: remove if not used
                    // Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupCreatePostPanel(groupEvent: widget.groupEvent,groupId: widget.group?.id,)));
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

  bool get _canPostComment{
    return widget.isAdmin && false; //TBD for now hide all comment options. Determine who can add comment
  }
}

class _EventContent extends StatefulWidget {
  final Group group;
  final Event event;
  final bool isAdmin;

  _EventContent({this.event, this.isAdmin = false, this.group});

  @override
  createState()=> _EventContentState();
}

class _EventContentState extends State<_EventContent> implements NotificationsListener {


  @override
  void initState() {
    NotificationService().subscribe(this, User.notifyFavoritesUpdated);
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
    if (name == User.notifyFavoritesUpdated) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {

    bool isFavorite = User().isExploreFavorite(widget.event);

    List<Widget> content = [
      Padding(padding: EdgeInsets.only(bottom: 8, right: 48), child:
      Text(widget.event?.title ?? '',  style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 20, color: Styles().colors.fillColorPrimary),),
      ),
    ];
    content.add(Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Row(children: <Widget>[
      Padding(padding: EdgeInsets.only(right: 8), child: Image.asset('images/icon-calendar.png'),),
      Expanded(child:
      Text(widget.event.timeDisplayString,  style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 14, color: Styles().colors.textBackground),)
      ),
    ],)),);

    return Stack(children: <Widget>[
      GestureDetector(onTap: () {
        Analytics().logPage(name: "Group Settings");
        Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupEventDetailPanel(event: widget.event, groupId: widget.group?.id,previewMode: widget.isAdmin,)));
      },
          child: Padding(padding: EdgeInsets.all(16), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: content),
          )
      ),
      Align(alignment: Alignment.topRight, child:
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
      ],),)
    ],);
  }

  void _onFavoriteTap() {
    Analytics.instance.logSelect(target: "Favorite");
    User().switchFavorite(widget.event);
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
    Groups().deleteEventFromGroup(event: widget.event, groupId: widget.group.id).then((value){
      Navigator.of(context).pop();
    });
  }

  void _onEditEventTap(BuildContext context){
    Analytics().logPage(name: "Create Event");
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEventPanel(group: widget.group, editEvent: widget.event,onEditTap: (Event event) {
      Groups().updateGroupEvents(event).then((String id) {
        if (AppString.isStringNotEmpty(id)) {
          Navigator.pop(context);
        }
        else {
          AppAlert.showDialogResult(context, "Unable to update event");
        }
      });
    })));
  }

  bool get _canEdit{
    return widget.isAdmin;
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
  var _imageUrlController = TextEditingController();

  final ImageType _imageType = ImageType(identifier: 'event-tout', width: 1080);
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
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: Styles().fontFamilies.medium,
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
                            fontFamily: Styles().fontFamilies.medium,
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
                              borderColor: Styles().colors.fillColorSecondary,
                              backgroundColor: Styles().colors.background,
                              textColor: Styles().colors.fillColorPrimary,
                              onTap: _onTapUseUrl)),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                              padding: EdgeInsets.all(10),
                              child: RoundedButton(
                                  label:  Localization().getStringEx("widget.add_image.button.chose_device.label","Choose from device"),
                                  borderColor: Styles().colors.fillColorSecondary,
                                  backgroundColor: Styles().colors.background,
                                  textColor: Styles().colors.fillColorPrimary,
                                  onTap: _onTapChooseFromDevice)),
                          _showProgress ? CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorPrimary)) : Container(),
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
      ImageService().useUrl(_imageType, url);
      result.then((logicResult) {
        setState(() {
          _showProgress = false;
        });


        ImagesResultType resultType = logicResult.resultType;
        switch (resultType) {
          case ImagesResultType.CANCELLED:
          //do nothing
            break;
          case ImagesResultType.ERROR_OCCURRED:
            AppToast.show(logicResult.errorMessage);
            break;
          case ImagesResultType.SUCCEEDED:
          //ready
            AppToast.show(Localization().getStringEx("widget.add_image.validation.success.label","Successfully added an image"));
            Navigator.pop(context, logicResult.data);
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

    Future<ImagesResult> result =
    ImageService().chooseFromDevice(_imageType);
    result.then((logicResult) {
      setState(() {
        _showProgress = false;
      });

      ImagesResultType resultType = logicResult.resultType;
      switch (resultType) {
        case ImagesResultType.CANCELLED:
        //do nothing
          break;
        case ImagesResultType.ERROR_OCCURRED:
          AppToast.show(logicResult.errorMessage);
          break;
        case ImagesResultType.SUCCEEDED:
        //ready
          AppToast.show(Localization().getStringEx("widget.add_image.validation.success.label","Successfully added an image"));
          Navigator.pop(context, logicResult.data);
          break;
      }
    });
  }
}

/////////////////////////////////////
// GroupCard


enum GroupCardDisplayType { myGroup, allGroups }

class GroupCard extends StatelessWidget {
  final Group group;
  final GroupCardDisplayType displayType;

  GroupCard({@required this.group, this.displayType = GroupCardDisplayType.allGroups});

  @override
  Widget build(BuildContext context) {
    String pendingCountText = sprintf(Localization().getStringEx("widget.group_card.pending.label", "Pending: %s"), [AppString.getDefaultEmptyString(value: group.pendingCount?.toString())]);
    return GestureDetector(
        onTap: () => _onTapCard(context),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Styles().colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  _buildHeading(),
                  Container(height: 3),
                  Row(children: [
                    Expanded(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            child: Text(group?.title ?? "",
                                style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 20, color: Styles().colors.fillColorPrimary))))
                  ]),
                  Visibility(
                    visible: (group?.currentUserIsAdmin ?? false) && (group.pendingCount > 0),
                    child: Text(pendingCountText ?? "",
                      style: TextStyle(
                          fontFamily: Styles().fontFamilies.regular,
                          fontSize: 16,
                          color: Styles().colors.textBackgroundVariant
                      ),
                    ),
                  ),
                  Container(height: 4),
                  displayType == GroupCardDisplayType.allGroups ? Container() : _buildUpdateTime()
                ]))));
  }

  Widget _buildHeading() {
    bool showMember = group?.currentUserAsMember?.status != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [
      Visibility(visible: showMember, child: _buildMember()),
      Visibility(visible: showMember, child: Container(height: 6)),
      Text(AppString.getDefaultEmptyString(value: group?.category, defaultValue: Localization().getStringEx("panel.groups_home.label.category", "Category")),
          style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.fillColorPrimary))
    ]);
  }

  Widget _buildMember() {
    return Row(children: <Widget>[
      Semantics(
          label: "status: " + (group?.currentUserStatusText?.toLowerCase() ?? "") + " ,for: ",
          excludeSemantics: true,
          child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: group.currentUserStatusColor, borderRadius: BorderRadius.all(Radius.circular(2))),
              child: Center(
                  child: Text(group.currentUserStatusText.toUpperCase(),
                      style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 12, color: Styles().colors.white))))),
      Expanded(child: Container())
    ]);
  }

  Widget _buildUpdateTime() {
    return Container(
        child: Text(
      _timeUpdatedText,
      style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 14, color: Styles().colors.textSurface),
    ));
  }

  void _onTapCard(BuildContext context) {
    Analytics.instance.logSelect(target: "${group.title}");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupDetailPanel(groupId: group.id)));
  }

  String get _timeUpdatedText {
    return "Updated about 2 hours ago"; //TBD
  }
}

//////////////////////////////////////
// GroupPostCard

class GroupPostCard extends StatefulWidget {
  final GroupPost post;
  final Group group;

  GroupPostCard({@required this.post, @required this.group});

  @override
  _GroupPostCardState createState() => _GroupPostCardState();
}

class _GroupPostCardState extends State<GroupPostCard> {
  @override
  Widget build(BuildContext context) {
    String memberName = widget.post?.member?.name;
    String htmlBody = widget.post?.body;
    return Stack(alignment: Alignment.topRight, children: [
      GestureDetector(
          onTap: _onTapCard,
          child: Container(
              decoration: BoxDecoration(
                  color: Styles().colors.white,
                  boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))],
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.start, children: [
                      Text(AppString.getDefaultEmptyString(value: widget.post.subject),
                          style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 18, color: Styles().colors.fillColorPrimary)),
                      Visibility(
                          visible: (_visibleRepliesCount > 0),
                          child: Padding(
                              padding: EdgeInsets.only(left: 14),
                              child: Text(AppString.getDefaultEmptyString(value: _visibleRepliesCount.toString()),
                                  style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 18)))),
                    ]),
                    Text(AppString.getDefaultEmptyString(value: memberName),
                        style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 14, color: Styles().colors.fillColorPrimary)),
                    Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Text(AppString.getDefaultEmptyString(value: widget.post?.displayDateTime),
                            style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 14, color: Styles().colors.fillColorPrimary))),
                    Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Html(data: htmlBody, style: {
                          "body": Style(
                              color: Styles().colors.fillColorPrimary,
                              fontFamily: Styles().fontFamilies.regular,
                              fontSize: FontSize(16),
                              maxLines: 3,
                              textOverflow: TextOverflow.ellipsis)
                        }))
                  ])))),
      Visibility(
          visible: _isReplyVisible,
          child: GestureDetector(
              onTap: _onTapReply,
              child: Padding(padding: EdgeInsets.only(left: 20, top: 14, bottom: 20, right: 12), child: Image.asset('images/icon-group-post-reply.png'))))
    ]);
  }

  void _onTapCard() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupViewPostPanel(post: widget.post, group: widget.group)));
  }

  void _onTapReply() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupCreatePostPanel(post: widget.post, group: widget.group)));
  }

  bool get _isReplyVisible {
    return widget.group?.currentUserIsMemberOrAdmin ?? false;
  }

  int get _visibleRepliesCount {
    if (AppCollection.isCollectionEmpty(widget.post?.replies)) {
      return 0;
    }
    bool currentUserIsMemberOrAdmin = widget.group?.currentUserIsMemberOrAdmin ?? false;
    int visibleRepliesCount = 0;
    for (GroupPost reply in widget.post.replies) {
      if ((reply.private == false) || (reply.private == null) || currentUserIsMemberOrAdmin) {
        visibleRepliesCount++;
      }
    }
    return visibleRepliesCount;
  }
}

//////////////////////////////////////
// GroupReplyCard

class GroupReplyCard extends StatefulWidget {
  final GroupPost reply;
  final Group group;
  final String iconPath;
  final Function onIconTap;

  GroupReplyCard({@required this.reply, @required this.group, this.iconPath, this.onIconTap});

  @override
  _GroupReplyCardState createState() => _GroupReplyCardState();
}

class _GroupReplyCardState extends State<GroupReplyCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Styles().colors.white,
            boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))],
            borderRadius: BorderRadius.all(Radius.circular(8))),
        child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(AppString.getDefaultEmptyString(value: widget.reply?.member?.name),
                    style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 18, color: Styles().colors.fillColorPrimary)),
                Visibility(
                    visible: AppString.isStringNotEmpty(widget.iconPath),
                    child: GestureDetector(
                        onTap: widget.onIconTap,
                        child: Padding(
                            padding: EdgeInsets.only(left: 10, top: 3, bottom: 3),
                            child: (AppString.isStringNotEmpty(widget.iconPath) ? Image.asset('images/trash.png') : Container()))))
              ]),
              Padding(padding: EdgeInsets.only(top: 3), child: Text(AppString.getDefaultEmptyString(value: widget.reply?.displayDateTime),
                  style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 14, color: Styles().colors.fillColorPrimary))),
              Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Html(data: widget.reply?.body, style: {
                    "body": Style(
                        color: Styles().colors.fillColorPrimary,
                        fontFamily: Styles().fontFamilies.regular,
                        fontSize: FontSize(16),
                        maxLines: 3,
                        textOverflow: TextOverflow.ellipsis)
                  }))
            ])));
  }
}