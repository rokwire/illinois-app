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
import 'package:illinois/model/Poll.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Content.dart';
import 'package:illinois/service/GeoFence.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:illinois/service/Network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Polls.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/events/CreateEventPanel.dart';
import 'package:illinois/ui/groups/GroupDetailPanel.dart';
import 'package:illinois/ui/groups/GroupPostDetailPanel.dart';
import 'package:illinois/ui/groups/GroupsEventDetailPanel.dart';
import 'package:illinois/ui/polls/PollProgressPainter.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
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
    String postDate = AppDateTimeUtils.timeAgoSinceDate(comment.dateCreated!);
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
                      decoration: StringUtils.isNotEmpty(comment.member?.photoURL)
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
                StringUtils.isNotEmpty(widget.event?.exploreImageURL),
                child: Padding(
                  padding: EdgeInsets.only(left: 12, right: 12, bottom: 8, top: 8),
                  child: SizedBox(
                    width: _smallImageSize,
                    height: _smallImageSize,
                    child: Image.network(
                      widget.event!.exploreImageURL!, excludeFromSemantics: true, fit: BoxFit.fill, headers: Network.authApiKeyHeader),),)),
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
        if (StringUtils.isNotEmpty(id)) {
          Navigator.pop(context);
        }
        else {
          AppAlert.showDialogResult(context, "Unable to update event");
        }
      });
    })));
  }

  bool get _canEdit {
    return widget.isAdmin && StringUtils.isNotEmpty(widget.event?.createdByGroupId);
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
                        semanticsLabel: "Close Button", //TBD localization
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
    String? pendingCountText = sprintf(Localization().getStringEx("widget.group_card.pending.label", "Pending: %s")!, [StringUtils.ensureNotEmpty(group!.pendingCount.toString())]);
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

    String? groupCategory = StringUtils.ensureNotEmpty(group?.category, defaultValue: Localization().getStringEx("panel.groups_home.label.category", "Category")!);
    if (StringUtils.isNotEmpty(groupCategory)) {
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
                          child: Text(StringUtils.ensureNotEmpty(widget.post!.subject),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 18, color: Styles().colors!.fillColorPrimary))),
                      Visibility(
                          visible: isRepliesLabelVisible,
                          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                            Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(StringUtils.ensureNotEmpty(visibleRepliesCount.toString()),
                                    style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 14))),
                            Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(StringUtils.ensureNotEmpty(repliesLabel),
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
                        StringUtils.isEmpty(imageUrl)? Container() :
                        Expanded(
                          flex: 1,
                          child: Semantics(
                            label: "post image",
                            button: true,
                            hint: "Double tap to zoom the image",
                            child:GestureDetector(
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
                                style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 14, color: Styles().colors!.fillColorPrimary)),
                          )),
                          Expanded(
                            flex: 2,
                            child: Semantics(child: Container(
                              padding: EdgeInsets.only(left: 6),
                              child: Text(StringUtils.ensureNotEmpty(widget.post?.displayDateTime),
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
    String? bodyText = StringUtils.ensureNotEmpty(widget.reply?.body);
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
                  Text(StringUtils.ensureNotEmpty(widget.reply?.member?.name),
                    style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary)),
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
                            child: Semantics(child: Text(StringUtils.ensureNotEmpty(widget.reply?.displayDateTime),
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
    return Semantics(
        container: true,
        explicitChildNodes: true,
        scopesRoute: true,
        child:Column(children: [
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
                                            Semantics(
                                              button: true,
                                              focusable: true,
                                              focused: true,
                                              child:GestureDetector(
                                                onTap: onClose,
                                                child: Padding(
                                                  padding: EdgeInsets.only(right: 10, top: 10),
                                                  child: Text('\u00D7',
                                                    semanticsLabel: "Close Button",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontFamily: Styles().fontFamilies!.medium,
                                                        fontSize: 50
                                                    ),
                                                  ),
                                                ),
                                              )
                                            )
                                          ],
                                        ),
                                      ),
                                      Container(
                                        child: StringUtils.isNotEmpty(imageUrl) ? Image.network(imageUrl!, excludeFromSemantics: true, fit: BoxFit.fitWidth, headers: Network.authApiKeyHeader): Container(),
                                      )
                                    ],
                                  ))
                          )
                      )
                  ),
                ],
              )))
      ))
      ],));
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
              ? Positioned.fill(child: Image.network(imageUrl!, semanticLabel: widget.imageSemanticsLabel??"", fit: BoxFit.cover))
              : Container(),
          Visibility( visible: showSlant,
              child: CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.fillColorSecondaryTransparent05, left: false), child: Container(height: 53))),
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
                      child: ScalableSmallRoundedButton(
                          maxLines: 2,
                          label:StringUtils.isEmpty(imageUrl)? Localization().getStringEx("panel.group.detail.post.add_image", "Add image") : Localization().getStringEx("panel.group.detail.post.change_image", "Edit Image"), // TBD localize
                          textColor: Styles().colors!.fillColorPrimary,
                          onTap: (){ _onTapAddImage();}
                      )))):
          Container()
        ]));
  }

  void _onTapAddImage() async {
    Analytics.instance.logSelect(target: "Add Image");
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

//Not used with the current PollService. Remove after deciding are we going to support as feature
class GroupPollVoteCard extends StatefulWidget{
  final Poll poll;
  final Group? group;

  GroupPollVoteCard({required this.poll, this.group});

  @override
  _GroupPollVoteCardState createState() => _GroupPollVoteCardState();

}

class _GroupPollVoteCardState extends State<GroupPollVoteCard> implements NotificationsListener {
  bool _voteDone = false;
  Map<int, int> _votingOptions = {};

  List<GlobalKey>? _progressKeys;
  double? _progressWidth;

  bool _showEndPollProgress = false;

  final Color? _backgroundColor = Styles().colors!.white;
  final Color? _textColor       = Styles().colors!.fillColorPrimary;
  // final Color? _doneButtonColor = Styles().colors!.fillColorSecondary;
  @override
  void initState() {
    NotificationService().subscribe(this, [
      Polls.notifyResultsChanged,
      Polls.notifyVoteChanged,
      Polls.notifyStatusChanged,
    ]);
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _evalProgressWidths();
    });
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
    if ((name == Polls.notifyVoteChanged) || (name == Polls.notifyResultsChanged) || (name == Polls.notifyStatusChanged)) {
      if (widget.poll.pollId == param) {
        _refreshPoll();
        if (widget.poll.status == PollStatus.closed) {
          _onClose();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return
      Container(
        decoration: BoxDecoration(color: _backgroundColor, borderRadius: BorderRadius.circular(5)),
        child: Padding(padding: EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildContent(),),),
      );
  }

  List<Widget> _buildContent() {
    if (_voteDone && widget.poll.settings!.hideResultsUntilClosed! && (widget.poll.status != PollStatus.closed)) {
      return _buildCheckoutContent();
    } else {
      return _buildStandardContent();
    }
  }

  List<Widget> _buildStandardContent() {
    List<Widget> footerWidgets = [];
    List<Widget> contentOptionsList;

    bool isClosed = widget.poll.status == PollStatus.closed;
    String? creator = widget.poll.creatorUserName ?? Localization().getStringEx('panel.poll_prompt.text.someone', 'Someone');
    String wantsToKnow = sprintf(Localization().getStringEx('panel.poll_prompt.text.wants_to_know', '%s wants to know')!, [creator]);

    String? pollStatus;
    if (widget.poll.status == PollStatus.opened) {
      pollStatus = Localization().getStringEx('panel.poll_prompt.text.poll_open', 'Polls open');
      if (widget.poll.isMine) {
        footerWidgets.add(Container(height:8));
        footerWidgets.add(_createEndPollButton());
      }
    }
    else if (isClosed) {
      pollStatus = Localization().getStringEx('panel.poll_prompt.text.poll_closed', 'Polls closed');
    }

    if (_voteDone) {
      contentOptionsList = _buildResultOptions();
      // footerWidgets.add(_buildVoteDoneButton(_onClose));
    }

    else {
      contentOptionsList = _allowRepeatOptions || widget.poll.status == PollStatus.closed ? _buildCheckboxOptions() : _buildButtonOptions();
      // Widget footerWidget = (_allowMultipleOptions || _allowRepeatOptions) ? _buildVoteDoneButton(_onVoteDone) : Container();
      // footerWidgets.add(footerWidget);
    }

    String pollTitle = widget.poll.title ?? '';
    String semanticsQuestionText =  "$wantsToKnow,\n $pollTitle";
    String semanticsStatusText = "$pollStatus,$_pollVotesStatus";
    return <Widget>[
      Row(children: <Widget>[Expanded(child: Container(),)],),
      Semantics(label:semanticsQuestionText,excludeSemantics: true,child:
      Text(wantsToKnow, style: TextStyle(color: _textColor, fontFamily: Styles().fontFamilies!.regular, fontSize: 12, fontWeight: FontWeight.w600),)),
      Semantics(excludeSemantics: true,child:
      Padding(padding: EdgeInsets.symmetric(vertical: 20),child:
      Text(pollTitle, style: TextStyle(color: _textColor, fontFamily: Styles().fontFamilies!.regular, fontSize: 24, fontWeight: FontWeight.w900),),)),
      Padding(padding: EdgeInsets.only(bottom: 20),child:
      Text(_votingRulesDetails, style: TextStyle(color: _textColor, fontFamily: Styles().fontFamilies!.regular, fontSize: 15),),),

      Column(children: contentOptionsList,),

      Semantics(label: semanticsStatusText, excludeSemantics: true,child:
      Padding(padding: EdgeInsets.only(top: 20), child:
        Row(children: <Widget>[
        Expanded(child: Text(_pollVotesStatus, textAlign: TextAlign.left, style: TextStyle(color: _textColor, fontFamily: Styles().fontFamilies!.regular, fontSize: 12, fontWeight: FontWeight.w500),)),
        Text('  ', style: TextStyle(color: _textColor, fontFamily: Styles().fontFamilies!.regular, fontSize: 12, fontWeight: FontWeight.w900),),
        Expanded(child:Text(pollStatus ?? '', textAlign: TextAlign.right, style: TextStyle(color: _textColor, fontFamily: Styles().fontFamilies!.regular, fontSize: 12, fontWeight: FontWeight.w200),)),
      ],),)),

      Column(children: footerWidgets),
    ];
  }

  List<Widget> _buildCheckoutContent() {
    String thanks = Localization().getStringEx('panel.poll_prompt.text.thanks_for_voting', 'Thanks for voting!')!;
    String willNotify = Localization().getStringEx('panel.poll_prompt.text.will_notify', 'We will notify you once the poll results are in.')!;
    return <Widget>[
      Row(children: <Widget>[Expanded(child: Container(),)],),
      Padding(padding: EdgeInsets.only(top: 32, bottom:20),child:
      Text(thanks, style: TextStyle(color: _textColor, fontFamily: Styles().fontFamilies!.regular, fontSize: 24, fontWeight: FontWeight.w900),),),
      Text(willNotify, style: TextStyle(color: _textColor, fontFamily: Styles().fontFamilies!.regular, fontSize: 16, fontWeight: FontWeight.w300),),
    ];
  }

  List<Widget> _buildButtonOptions() {
    List<Widget> result = [];
    int optionsCount = widget.poll.options?.length ?? 0;
    for (int optionIndex = 0; optionIndex < optionsCount; optionIndex++) {
      result.add(Padding(padding: EdgeInsets.only(top: (0 < result.length) ? 10 : 0), child:
      Stack(children: <Widget>[
        ScalableRoundedButton(
            label: widget.poll.options![optionIndex],
            backgroundColor: (0 < _optionVotes(optionIndex)) ? Styles().colors!.fillColorSecondary : _backgroundColor,
            hint: Localization().getStringEx("panel.poll_prompt.hint.select_option","Double tab to select this option"),
//            height: 42,
            fontSize: 16.0,
            textColor: _textColor,
            borderColor: Styles().colors!.fillColorSecondary,
            padding: EdgeInsets.symmetric(horizontal: 24),
            onTap: () { _onButtonOption(optionIndex); }
        ),
        Visibility(visible: (_votingOptions[optionIndex] != null),
          child: Container(
            height: 42,
            child: Align(alignment: Alignment.center,
              child: SizedBox(height: 21, width: 21,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(_textColor), )
              ),
            ),
          ),
        ),
      ],),
      ));
    }
    return result;
  }

  List<Widget> _buildCheckboxOptions() {
    bool isClosed = widget.poll.status == PollStatus.closed;

    List<Widget> result = [];
    _progressKeys = [];
    int maxValueIndex=-1;
    if(isClosed  && ((widget.poll.results?.totalVotes ?? 0) > 0)){
      maxValueIndex = 0;
      for (int optionIndex = 0; optionIndex<widget.poll.options!.length ; optionIndex++) {
        int? optionVotes =  widget.poll.results![optionIndex];
        if(optionVotes!=null &&  optionVotes > widget.poll.results![maxValueIndex]!)
          maxValueIndex = optionIndex;
      }
    }

    int totalVotes = (widget.poll.results?.totalVotes ?? 0);
    for (int optionIndex = 0; optionIndex<widget.poll.options!.length ; optionIndex++) {
      bool useCustomColor = isClosed && maxValueIndex == optionIndex;
      String option = widget.poll.options![optionIndex];
      bool didVote = ((widget.poll.userVote != null) && (0 < (widget.poll.userVote![optionIndex] ?? 0)));
      String checkboxImage = 'images/checkbox-unselected.png'; // 'images/checkbox-selected.png'

      String? votesString;
      int? votesCount = (widget.poll.results != null) ? widget.poll.results![optionIndex] : null;
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
      Color? votesColor = Styles().colors!.textBackground;

      GlobalKey progressKey = GlobalKey();
      _progressKeys!.add(progressKey);

      String semanticsText = option +"\n "+  votesString! +"," + votesPercent.toStringAsFixed(0) +"%";

      result.add(Padding(padding: EdgeInsets.only(top: (0 < result.length) ? 8 : 0), child:
      GestureDetector(
          onTap: () { _onButtonOption(optionIndex); },
          child: Semantics(label: semanticsText, excludeSemantics: true, child:
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
                  child: Text(option, style: TextStyle(color: useCustomColor?Styles().colors!.white:Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16, fontWeight: FontWeight.w500,height: 1.25),),)),
                Visibility( visible: didVote,
                    child:Padding(padding: EdgeInsets.only(right: 10), child: Image.asset('images/checkbox-small.png',),)
                ),
              ],),)
              ),
            ],)
            ),
            Expanded(
              flex: 5,
              child: Padding(padding: EdgeInsets.only(left: 10), child: Text('$votesString (${votesPercent.toStringAsFixed(0)}%)', textAlign: TextAlign.right,style: TextStyle(color: votesColor, fontFamily: Styles().fontFamilies!.regular, fontSize: 14, fontWeight: FontWeight.w500,height: 1.29),),),
            )
          ],)
          ))));
    }
    return result;
  }

  List<Widget> _buildResultOptions() {
    List<Widget> result = [];
    _progressKeys = [];
    int totalVotes = widget.poll.results?.totalVotes ?? 0;
    for (int optionIndex = 0; optionIndex < widget.poll.options!.length; optionIndex++) {
      String checkboxImage = (0 < _optionVotes(optionIndex)) ? 'images/checkbox-selected.png' : 'images/checkbox-unselected.png';

      String optionString = widget.poll.options![optionIndex];
      String? votesString;
      int? votesCount = (widget.poll.results != null) ? widget.poll.results![optionIndex] : null;
      double votesPercent = ((0 < totalVotes) && (votesCount != null)) ? (votesCount.toDouble() / totalVotes.toDouble() * 100.0) : 0.0;
      if ((votesCount == null) || (votesCount <= 0)) {
        votesString = Localization().getStringEx('panel.poll_prompt.text.no_votes', 'No votes');
      }
      else if (votesCount == 1) {
        votesString = Localization().getStringEx('panel.poll_prompt.text.single_vote', '1 vote');
      }
      else {
        votesString = sprintf(Localization().getStringEx('panel.poll_prompt.text.many_votes', '%s votes')!, ['$votesCount']);
      }

      GlobalKey progressKey = GlobalKey();
      _progressKeys!.add(progressKey);

      String semanticsText = optionString +"\n "+  votesString! +"," + votesPercent.toStringAsFixed(0) +"%";
      result.add(Padding(padding: EdgeInsets.only(top: (0 < result.length) ? 10 : 0), child:
      Semantics(label: semanticsText, excludeSemantics: true, child:
      Row(children: <Widget>[
        Padding(padding: EdgeInsets.only(right: 10), child: Image.asset(checkboxImage,),),
        Expanded(
            key: progressKey, child:Stack(children: <Widget>[
          CustomPaint(painter: PollProgressPainter(backgroundColor: Styles().colors!.fillColorPrimary, progressColor: Styles().colors!.lightGray!.withOpacity(0.2), progress: votesPercent / 100.0), child: Container(height:30, width: _progressWidth),),
          Container(/*height: 30,*/ child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Padding(padding: EdgeInsets.only(left: 5), child:
            Text(widget.poll.options![optionIndex],  maxLines: 5, overflow:TextOverflow.ellipsis, style: TextStyle(color: _textColor, fontFamily: Styles().fontFamilies!.regular, fontSize: 16, fontWeight: FontWeight.w500),),),
          ],),),
        ],)
        ),
        Expanded(child:
        Padding(padding: EdgeInsets.only(left: 10), child: Text('$votesString (${votesPercent.toStringAsFixed(0)}%)', textAlign:TextAlign.right, style: TextStyle(color: Styles().colors!.surfaceAccent, fontFamily: Styles().fontFamilies!.regular, fontSize: 14, fontWeight: FontWeight.w500),),),
        )
      ],))
      ));
    }
    return result;
  }

  Widget _createEndPollButton(){ //TBD localize whole panel
    return  Container( padding: EdgeInsets.symmetric(horizontal: 54,),
        child: Semantics(label: Localization().getStringEx("panel.polls_home.card.button.title.end_poll","End Poll"), button: true, excludeSemantics: true,
          child: InkWell(
              onTap: _onEndPollTapped,
              child: Stack(children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(vertical: 5,horizontal: 16),
                  decoration: BoxDecoration(
                    color: Styles().colors!.white,
                    border: Border.all(
                        color: Styles().colors!.fillColorSecondary!,
                        width: 2.0),
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Center(
                    child: Text(
                      Localization().getStringEx("panel.polls_home.card.button.title.end_poll","End Poll")!,
                      style: TextStyle(
                        fontFamily: Styles().fontFamilies!.bold,
                        fontSize: 16,
                        height: 1.38,
                        color: Styles().colors!.fillColorPrimary,
                      ),
                    ),
                  ),
                ),
                Visibility(visible: _showEndPollProgress,
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

//   Widget _buildVoteDoneButton(void Function() handler) {
//     return Padding(padding: EdgeInsets.only(top: 20, left: 30, right: 30), child: ScalableRoundedButton(
//         label: Localization().getStringEx('panel.poll_prompt.button.done_voting.title', 'Done Voting'),
//         backgroundColor: _backgroundColor,
// //        height: 42,
//         fontSize: 16.0,
//         textColor: _textColor,
//         borderColor: _doneButtonColor,
//         padding: EdgeInsets.symmetric(horizontal: 24),
//         onTap: handler)
//     );
//   }

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

  int _optionVotes(int optionIndex) {
    int? userVotes = (widget.poll.userVote != null) ? widget.poll.userVote![optionIndex] : null;
    return (userVotes ?? 0) + (_votingOptions[optionIndex] ?? 0);
  }

  int get _totalOptionVotes {
    int total = (widget.poll.userVote?.totalVotes ?? 0);
    _votingOptions.forEach((int optionIndex, int optionVotes) {
      total += optionVotes;
    });
    return total;
  }

  int get _totalOptions {
    return widget.poll.options?.length ?? 0;
  }

  int get _totalVotedOptions {
    int totalOptions = 0;
    for (int optionIndex = 0; optionIndex < _totalOptions; optionIndex++) {
      int? userVotes = (widget.poll.userVote != null) ? widget.poll.userVote![optionIndex] : null;
      if ((userVotes != null) || (_votingOptions[optionIndex] != null)) {
        totalOptions++;
      }
    }
    return totalOptions;
  }

  bool get _allowMultipleOptions {
    return widget.poll.settings?.allowMultipleOptions ?? false;
  }

  bool get _allowRepeatOptions {
    return widget.poll.settings?.allowRepeatOptions ?? false;
  }

  bool get _hideResultsUntilClosed {
    return widget.poll.settings?.hideResultsUntilClosed ?? false;
  }

  void _onButtonOption(int optionIndex) {
    if(widget.poll.status == PollStatus.closed){
      return; //Disable vote options for closed polls
    }
    if (_allowMultipleOptions) {
      if (_allowRepeatOptions) {
        _onVote(optionIndex);
      }
      else if (_optionVotes(optionIndex) == 0) {
        _onVote(optionIndex);
      }
    }
    else {
      if (_allowRepeatOptions) {
        if (_optionVotes(optionIndex) == _totalOptionVotes) {
          _onVote(optionIndex);
        }
      }
      else if (_totalOptionVotes == 0) {
        _onVote(optionIndex);
      }
    }
  }

  void _onVote(int optionIndex) {
    setState(() {
      _votingOptions[optionIndex] = (_votingOptions[optionIndex] ?? 0) + 1;
    });
    Polls().vote(widget.poll.pollId, PollVote(votes: { optionIndex : 1 })).then((_) {
      if ((!_allowMultipleOptions && !_allowRepeatOptions) ||
          (_allowMultipleOptions && !_allowRepeatOptions && (_totalVotedOptions == _totalOptions))) {
        setState(() {
          _voteDone = true;
        });
      }
    }).catchError((e){
      AppAlert.showDialogResult(context, e.toString());
    }).whenComplete((){
      setState(() {
        int? value = _votingOptions[optionIndex];
        if (value != null) {
          if (1 < value) {
            _votingOptions[optionIndex] = value - 1;
          }
          else {
            _votingOptions.remove(optionIndex);
          }
        }
      });
    });
  }

  // void _onVoteDone() {
  //   if (_votingOptions.length == 0) {
  //     setState(() {
  //       _voteDone = true;
  //     });
  //   }
  // }

  void _onClose() {
    if (_votingOptions.length == 0) {
      Navigator.of(context).pop();
      Polls().closePresent();
    }
  }

  String get _votingRulesDetails {
    String details = '';
    if (_allowMultipleOptions) {
      if (details.isNotEmpty) {
        details += '\n';
      }
      details += '• ' + Localization().getStringEx("panel.poll_prompt.text.rule.detail.multy_choice", "You can choose more that one answer.")!;
    }
    if (_allowRepeatOptions) {
      if (details.isNotEmpty) {
        details += '\n';
      }
      details += '• ' + Localization().getStringEx("panel.poll_prompt.text.rule.detail.repeat_vote", "You can vote as many times as you want before the poll closes.")!;
    }
    if (_hideResultsUntilClosed) {
      if (details.isNotEmpty) {
        details += '\n';
      }
      details += '• ' + Localization().getStringEx("panel.poll_prompt.text.rule.detail.hide_result", "Results will not be shown until the poll ends.")!;
    }
    return details;
  }

  String get _pollVotesStatus {
    bool hasGroup = (widget.group != null);
    int votes = hasGroup ? _uniqueVotersCount : (widget.poll.results?.totalVotes ?? 0);

    String statusString;
    if (1 < votes) {
      statusString = sprintf(Localization().getStringEx('panel.poll_prompt.text.many_votes', '%s votes')!, ['$votes']);
    } else if (0 < votes) {
      statusString = Localization().getStringEx('panel.poll_prompt.text.single_vote', '1 vote')!;
    } else {
      statusString = Localization().getStringEx('panel.poll_prompt.text.no_votes_yet', 'No votes yet')!;
    }

    if (hasGroup && (votes > 0)) {
      statusString += sprintf(' %s %d', [Localization().getStringEx('panel.polls_home.card.of.label', 'of')!, _groupMembersCount]);
    }

    return statusString;
  }

  void _onEndPollTapped(){
    _setEndButtonProgress(true);
    Polls().close(widget.poll.pollId).then((result) => _setEndButtonProgress(false)).catchError((e){
      _setEndButtonProgress(false);
      AppAlert.showDialogResult(context, e.toString());
    });

  }

  void _setEndButtonProgress(bool showProgress){
    setState(() {
      _showEndPollProgress = showProgress;
    });
  }

  void _refreshPoll()  async{
    // PollsChunk? groupPolls = await Polls().getGroupPolls([widget.group?.id??""]); //TBD request backend directly for one poll
    // Poll? updatedPoll = groupPolls?.polls!=null? groupPolls?.polls?.firstWhere((element) => element.pollId == widget.poll.pollId) : null;
    // Poll? updatedPoll = Polls().getPoll(pollId: widget.poll.pollId);
    // if(updatedPoll!=null){
    //   setState(() {
    //     _poll = updatedPoll;
    //   });
    // }
  }

  int get _uniqueVotersCount {
    return widget.poll.uniqueVotersCount ?? 0;
  }

  int get _groupMembersCount {
    return widget.group?.membersCount ?? 0;
  }
}

class GroupPollCard extends StatefulWidget{
  final Poll? poll;
  final Group? group;

  GroupPollCard({required this.poll, this.group});

  @override
  State<StatefulWidget> createState() => _GroupPollCardState();

}

class _GroupPollCardState extends State<GroupPollCard>{
  List<GlobalKey>? _progressKeys;
  double? _progressWidth;

  bool _showStartPollProgress = false;
  bool _showEndPollProgress = false;

  @override
  void initState() {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _evalProgressWidths();
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Poll poll = widget.poll!;
    String pollVotesStatus = _pollVotesStatus;

    List<Widget> footerWidgets = [];

    String? pollStatus;

    String? creator = widget.poll?.creatorUserName ?? Localization().getStringEx('panel.poll_prompt.text.someone', 'Someone');//TBD localize
    String wantsToKnow = sprintf(Localization().getStringEx('panel.poll_prompt.text.wants_to_know', '%s wants to know')!, [creator]);
    String semanticsQuestionText =  "$wantsToKnow,\n ${poll.title!}";

    if(poll.status == PollStatus.created) {
      pollStatus = Localization().getStringEx("panel.polls_home.card.state.text.created","Polls created");
      if (poll.isMine) {
        footerWidgets.add(_createStartPollButton());
        footerWidgets.add(Container(height:8));
      }
    } if (poll.status == PollStatus.opened) {
      pollStatus = Localization().getStringEx("panel.polls_home.card.state.text.open","Polls open");
      if (_canVote) {
        footerWidgets.add(_createVoteButton());
        footerWidgets.add(Container(height:8));
      }
      if (poll.isMine) {
        footerWidgets.add(_createEndPollButton());
        footerWidgets.add(Container(height:8));
      }
    }
    else if (poll.status == PollStatus.closed) {
      pollStatus =  Localization().getStringEx("panel.polls_home.card.state.text.closed","Polls closed");
    }

    Widget cardBody = ((poll.status == PollStatus.opened) && (poll.settings?.hideResultsUntilClosed ?? false)) ?
    Text(Localization().getStringEx("panel.poll_prompt.text.rule.detail.hide_result", "Results will not be shown until the poll ends.")!, style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 15, fontWeight: FontWeight.w500),) :
    Column(children: _buildCheckboxOptions(),);
    return
      Column(children: <Widget>[ Container(padding: EdgeInsets.symmetric(),
        decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: BorderRadius.circular(5)),
        child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:
        <Widget>[
          Row(children: <Widget>[Expanded(child: Container(),)],),
          Semantics(label:semanticsQuestionText,excludeSemantics: true,child:
            Text(wantsToKnow, style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 12, fontWeight: FontWeight.w600),)),
          Container(height: 12,),
          Padding(padding: EdgeInsets.symmetric(vertical: 0),child:
            Text(poll.title!, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20, height: 1.2 ),),),
          Container(height:12),
          cardBody,
          Container(height:25),
          Semantics(excludeSemantics: true, label: "$pollStatus,$pollVotesStatus",
            child: Padding(padding: EdgeInsets.only(bottom: 12), child: Row(children: <Widget>[
              Expanded(child:
                Text(pollVotesStatus, style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 12, ),),
              ),
              Expanded(child:
                Text(pollStatus ?? "", textAlign: TextAlign.right, style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.bold, fontSize: 12, ),))
            ],),),
          ),
          Column(children: footerWidgets,),
        ]
          ,),),
      ),],);
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
      String checkboxImage = 'images/checkbox-unselected.png'; // 'images/checkbox-selected.png'

      String? votesString;
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
      Color? votesColor = Styles().colors!.textBackground;

      GlobalKey progressKey = GlobalKey();
      _progressKeys!.add(progressKey);

      String semanticsText = option + "," +"\n "+  votesString! +"," + votesPercent.toStringAsFixed(0) +"%";

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
                  child: Text(option, style: TextStyle(color: useCustomColor?Styles().colors!.white:Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16, fontWeight: FontWeight.w500,height: 1.25),),)),
                Visibility( visible: didVote,
                    child:Padding(padding: EdgeInsets.only(right: 10), child: Image.asset('images/checkbox-small.png',),)
                ),
              ],),)
              ),
            ],)
            ),
            Expanded(
              flex: 5,
              child: Padding(padding: EdgeInsets.only(left: 10), child: Text('$votesString (${votesPercent.toStringAsFixed(0)}%)', textAlign: TextAlign.right,style: TextStyle(color: votesColor, fontFamily: Styles().fontFamilies!.regular, fontSize: 14, fontWeight: FontWeight.w500,height: 1.29),),),
            )
          ],)
          ))));
    }
    return result;
  }

  Widget _createStartPollButton(){
    return _createButton(Localization().getStringEx("panel.polls_home.card.button.title.start_poll","Start Poll")!, _onStartPollTapped, loading: _showStartPollProgress);
  }
  Widget _createEndPollButton(){
    return _createButton(Localization().getStringEx("panel.polls_home.card.button.title.end_poll","End Poll")!, _onEndPollTapped, loading: _showEndPollProgress);
  }
  Widget _createVoteButton(){
    return _createButton(Localization().getStringEx("panel.polls_home.card.button.title.vote","Vote")!, _onVoteTapped);
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
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: Styles().fontFamilies!.bold,
                        fontSize: 16,
                        height: 1.38,
                        color: Styles().colors!.fillColorPrimary,
                      ),
                    ),
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

  void _onStartPollTapped(){
    _setStartButtonProgress(true);
    Polls().open(widget.poll!.pollId).then((result) => _setStartButtonProgress(false)).catchError((e){
      _setStartButtonProgress(false);
      AppAlert.showDialogResult(context, e.toString());
    });
  }

  void _onEndPollTapped(){
    _setEndButtonProgress(true);
    Polls().close(widget.poll!.pollId).then((result) => _setEndButtonProgress(false)).catchError((e){
      _setEndButtonProgress(false);
      AppAlert.showDialogResult(context, e.toString());
    });

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

  void _setStartButtonProgress(bool showProgress){
    setState(() {
      _showStartPollProgress = showProgress;
    });
  }
  void _setEndButtonProgress(bool showProgress){
    setState(() {
      _showEndPollProgress = showProgress;
    });
  }

  bool get _canVote {
    return ((widget.poll!.status == PollStatus.opened) &&
        (((widget.poll!.userVote?.totalVotes ?? 0) == 0) ||
            widget.poll!.settings!.allowMultipleOptions! ||
            widget.poll!.settings!.allowRepeatOptions!
        ) &&
        (!widget.poll!.isGeoFenced || GeoFence().currentRegionIds.contains(widget.poll!.regionId))
    );
  }

  String get _pollVotesStatus {
    bool hasGroup = (widget.group != null);
    int votes = hasGroup ? _uniqueVotersCount : (widget.poll!.results?.totalVotes ?? 0);

    String statusString;
    if (1 < votes) {
      statusString = sprintf(Localization().getStringEx('panel.poll_prompt.text.many_votes', '%s votes')!, ['$votes']);
    } else if (0 < votes) {
      statusString = Localization().getStringEx('panel.poll_prompt.text.single_vote', '1 vote')!;
    } else {
      statusString = Localization().getStringEx('panel.poll_prompt.text.no_votes_yet', 'No votes yet')!;
    }

    if (hasGroup && (votes > 0)) {
      statusString += sprintf(' %s %d', [Localization().getStringEx('panel.polls_home.card.of.label', 'of')!, _groupMembersCount]);
    }

    return statusString;
  }

  int get _uniqueVotersCount {
    return widget.poll?.uniqueVotersCount ?? 0;
  }

  int get _groupMembersCount {
    return widget.group?.membersCount ?? 0;
  }
}