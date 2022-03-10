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
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/events/CreateEventPanel.dart';
import 'package:illinois/ui/groups/GroupMembersPanel.dart';
import 'package:illinois/ui/groups/GroupSettingsPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/section_heading.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/ext/Event.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:sprintf/sprintf.dart';

import 'GroupFindEventPanel.dart';

class GroupAdminPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Group? group;
  final List<GroupEvent>?   groupEvents;
  
  GroupAdminPanel({this.group, this.groupEvents});

  @override
  _GroupAdminPanelState createState() => _GroupAdminPanelState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes => group?.analyticsAttributes;
}

class _GroupAdminPanelState extends State<GroupAdminPanel>{

  bool saved = false;
  //TBD Consider do we need deep copy of the GroupEvents or we want to work over the original data
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.groups_admin.header.title", "Admin view"),
        leadingAsset: 'images/icon-circle-close.png',
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  _buildHeading(),
                  _buildEventsSection(),
//                  _mocEventSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildHeading(){
    String members;
    int membersCount = widget.group?.membersCount ?? 0;
    if (membersCount == 0) {
      members = Localization().getStringEx("panel.groups_admin.members.count.empty", "No Current Members");
    }
    else if (membersCount == 1) {
      members = Localization().getStringEx("panel.groups_admin.members.count.one", "1 Current Member");
    }
    else {
      members = sprintf(Localization().getStringEx("panel.groups_admin.members.count.format", "%s Current Members"),[membersCount]);
    }

    return Container(
      padding: EdgeInsets.all(16),
      color: Styles().colors!.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(widget.group?.category?.toUpperCase() ?? '',
                  style: TextStyle(
                    fontFamily: Styles().fontFamilies!.bold,
                    fontSize: 12,
                    color: Styles().colors!.fillColorPrimary
                  ),
                ),
              ),
              IconButton(
                onPressed: (){setState((){saved = !saved;});},
                icon: saved
                    ? Image.asset('images/icon-star-selected.png')
                    : Image.asset('images/icon-star.png'),
              )
            ],
          ),
          Container(height: 12,),
          Text(widget.group?.title ?? '',
            style: TextStyle(
              fontFamily: Styles().fontFamilies!.extraBold,
              fontSize: 32,
              color: Styles().colors!.fillColorPrimary,
            ),
          ),
          Container(height: 8,),
          Text(members,
            style: TextStyle(
              fontFamily: Styles().fontFamilies!.bold,
              fontSize: 16,
              color: Styles().colors!.textBackground,
            ),
          ),
          Container(height: 20,),
          RibbonButton(
            label: Localization().getStringEx("panel.groups_admin.button.manage_members.title", "Manage Members"),
            hint: Localization().getStringEx("panel.groups_admin.button.manage_members.hint", ""),
            leftIconAsset: 'images/icon-member.png',
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 0),
            onTap: onTapMembers,
          ),
          Container(height: 1, color: Styles().colors!.surfaceAccent,),
          RibbonButton(
            label: Localization().getStringEx("panel.groups_admin.button.group_settings.title", "Group Settings"),
            hint: Localization().getStringEx("panel.groups_admin.button.group_settings.hint", ""),
            leftIconAsset: 'images/icon-gear.png',
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 0),
            onTap: onTapSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildEventsSection(){
    Widget eventsWidget;
    if(CollectionUtils.isNotEmpty(widget.groupEvents)){
      eventsWidget = Column(
        children: widget.groupEvents!.map((event){
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _EventCard(groupEvent: event,groupId: widget.group?.id, onDeleteTap: (GroupEvent event){
              widget.groupEvents!.remove(event);
//            Groups().updateGroupEvents(widget.group?.id, widget.groupEvents);//TBD Consider how to notify service for the update
              setState(() {});
            },),
          );
        }).toList(),
      );
    }
    else{
      eventsWidget = _NoUpcomingEvents();
    }

    int eventsCount = widget.groupEvents?.length ?? 0;
    return SectionSlantHeader(title: "${Localization().getStringEx("panel.groups_admin.label.upcoming_events", "Upcoming events")} ($eventsCount)",
      titleIconAsset: 'images/icon-calendar.png',
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: eventsWidget,
        )
      ],
    );
  }

  void onTapMembers(){
    Analytics().logSelect(target: "Group Members");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMembersPanel(group: widget.group)));
  }

  void onTapSettings(){
    Analytics().logSelect(target: "Group Settings");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupSettingsPanel(group: widget.group,)));
  }
}

class _NoUpcomingEvents extends StatelessWidget{
  _NoUpcomingEvents();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Styles().colors!.white,
        borderRadius: BorderRadius.all(Radius.circular(4)),
        boxShadow: [BoxShadow(color: Styles().colors!.fillColorPrimaryTransparent015!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(0, 2))],
      ),
      child: Column(
        children: <Widget>[
          Text(
            Localization().getStringEx("panel.groups_admin.label.no_upcoming_events", "No upcoming events"),
            style: TextStyle(
              color: Styles().colors!.textBackground,
              fontSize: 20,
              fontFamily: Styles().fontFamilies!.extraBold,
            ),
          ),
          Container(height: 10,),
          Text(
            Localization().getStringEx("panel.groups_admin.label.create_new_event", "Create a new event or share an existing event with your members. "),
            style: TextStyle(
              color: Styles().colors!.textBackground,
              fontSize: 16,
              fontFamily: Styles().fontFamilies!.regular,
            ),
          ),
          Container(height: 20,),
          Row(
            children: <Widget>[
              Expanded(
                child: RoundedButton(
                  label: Localization().getStringEx("panel.groups_admin.button.find_existing.title", "Find existing"),
                  hint: Localization().getStringEx("panel.groups_admin.button.find_existing.hint", ""),
                  textColor: Styles().colors!.fillColorPrimary,
                  backgroundColor: Styles().colors!.white,
                  borderColor:  Styles().colors!.white,
                  secondaryBorderColor: Styles().colors!.fillColorSecondary,
                  onTap: () => _onTapFindEvent(context),
                ),
              ),
              Container(width: 10,),
              Expanded(
                child: RoundedButton(
                  label: Localization().getStringEx("panel.groups_admin.button.create_event.title", "Create"),
                  hint: Localization().getStringEx("panel.groups_admin.button.create_event.hint", ""),
                  textColor: Styles().colors!.fillColorPrimary,
                  backgroundColor: Styles().colors!.white,
                  borderColor:  Styles().colors!.white,
                  secondaryBorderColor: Styles().colors!.fillColorSecondary,
                  onTap: () => _onTapCreateEvent(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onTapCreateEvent(BuildContext context){
    Analytics().logSelect(target: "Create Event");
    Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEventPanel()));
    // TBD Notify service for Create Event
  }

  void _onTapFindEvent(BuildContext context){
    Analytics().logSelect(target: "Find Event");
    GroupEventsContext groupContext = GroupEventsContext(events: <Event>[]);
    Navigator.push(context, MaterialPageRoute(builder: (context) => GroupFindEventPanel(groupContext: groupContext,)));
  }
}

class _EventCard extends StatelessWidget {
  final String? groupId;
  final GroupEvent? groupEvent;
  final Function? onDeleteTap;

  _EventCard({this.groupEvent, this.groupId, this.onDeleteTap});

  @override
  Widget build(BuildContext context) {
    
    List<Widget> content = [
      EventContent(event: groupEvent,
        topRightButton:
        GestureDetector(onTap:(){ _onSettingsTap(context,groupEvent);},
          child: Container(width: 48, height: 48, color: Colors.transparent,
            child: Align(alignment: Alignment.center,
              child: Image.asset("images/group-event-settings.png"),
            ),
          ),
        )
        /*GestureDetector(onTap:(){ _onDeleteTap(context,groupEvent);},
          child: Container(width: 48, height: 48, color: Colors.transparent,
            child: Align(alignment: Alignment.center,
              child: Text('X', style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.fillColorPrimary,),),
            ),
          ),
        ),*/
      )
    ];

    if (0 < (groupEvent?.comments?.length ?? 0)) {
      content.add(Container(color: Styles().colors!.surfaceAccent, height: 1,));

      List<Widget> content2 = [];
      for (GroupEventComment? comment in groupEvent!.comments!) {
        content2.add(Padding(
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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(image:NetworkImage(comment!.member!.photoURL!), fit: BoxFit.cover),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Padding(padding:EdgeInsets.only(left: 8) , child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Padding(padding: EdgeInsets.only(bottom: 2), child:
                    Text(comment.member!.displayShortName, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 14, color: Styles().colors!.fillColorPrimary),),
                    ),
                    Row(children: <Widget>[
                      Padding(padding: EdgeInsets.only(right: 2), child:
                      Image.asset('images/icon-badge.png'),
                      ),
                      Text(comment.member!.officerTitle!, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 10, color: Styles().colors!.fillColorPrimary),),
                    ],)
                  ],),),),
                  Expanded(
                    flex:3,
                    child: Text(AppDateTimeUtils.getDisplayDateTime(comment.dateCreated), style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 12, color: Styles().colors!.textBackground),)
                  )
                ],),
                Padding(padding: EdgeInsets.only(top:8), child:
                Text(comment.text!, style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textBackground),)
                ),
              ],),
            )));
      }

        content.add(Padding(padding: EdgeInsets.all(8), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children:content2))
        );
    }

    content.add(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child:_buildAddPostButton(onTap: (){
            Analytics().logSelect(target: "Add post");
            // TBD: remove if not used
            // Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupCreatePostPanel(groupEvent: groupEvent,groupId: groupId,)));
        })));

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

  Widget _buildAddPostButton({String? photoUrl,void onTap()?}){
      return
        InkWell(
          onTap: onTap,
          child: Container(
          padding: EdgeInsets.only(top: 0,bottom: 16),
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
                Text(Localization().getStringEx("panel.groups_admin.button.post.text","Post about this event..."),style: TextStyle(fontFamily: 'ProximaNovaExtraRegular', fontSize: 14, color: Styles().colors!.textBackground),)
            ))
          ],),
      ));
  }

  void _onSettingsTap(BuildContext context, GroupEvent? event){
    Analytics().logSelect(target: "Settings");
    showDialog(
        context: context,
        builder: (_) => Material(
          type: MaterialType.transparency,
          child: Container(
            color: Styles().colors!.blackTransparent06,
            child: Stack(
              children: <Widget>[
                Align(alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16,vertical: 17),
                    child: Column(
                      children: <Widget>[
                        Expanded(child: Container()),
                        RoundedButton(
                          label:Localization().getStringEx("panel.groups_admin.button.delete.title", "Delete"),
                          backgroundColor: Styles().colors!.white,
                          borderColor: Styles().colors!.fillColorPrimary,
                          textColor: Styles().colors!.fillColorPrimary,
                          fontFamily: 'ProximaNovaRegulat',
                          fontSize: 16,
//                          height: 42,
                          borderWidth: 2,
                          onTap: (){
                            Navigator.pop(context);
                            _onDeleteTap(context, event);
                          },
                        ),
                        Container(height: 8,),
                        RoundedButton(
                          label:Localization().getStringEx("panel.groups_admin.button.edit.title", "Edit"),
                          backgroundColor: Styles().colors!.white,
                          borderColor: Styles().colors!.fillColorPrimary,
                          textColor: Styles().colors!.fillColorPrimary,
                          fontFamily: Styles().fontFamilies!.regular,
                          fontSize: 16,
//                          height: 42,
                          borderWidth: 2,
                          onTap: (){
                            Navigator.pop(context);
                            Navigator.push(context, CupertinoPageRoute(builder: (context) => CreateEventPanel(editEvent: event, onEditTap: (Event event){
                              //TBD notify service for Event Update
                              Groups().updateGroupEvents(event).then((String? id) {
                                if (StringUtils.isNotEmpty(id)) {
                                  Navigator.pop(context);
                                }
                                else {
                                  AppAlert.showDialogResult(context, "Unable to update event");
                                }
                              });
                            },)));
                          },
                        ),
                        Container(height: 8,),
                        RoundedButton(
                          label: Localization().getStringEx("panel.groups_admin.button.cancel.title", "Cancel"),
                          backgroundColor: Styles().colors!.white,
                          borderColor: Styles().colors!.fillColorSecondary,
                          textColor: Styles().colors!.fillColorPrimary,
                          fontFamily: Styles().fontFamilies!.bold,
                          fontSize: 16,
//                          height: 42,
                          borderWidth: 2,
                          onTap: (){
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  )
                )
              ],
            ),
          ),
        )
    );
  }

  void _onDeleteTap(BuildContext context, GroupEvent? event){
    Analytics().logSelect(target: "Delete");
    showDialog(
        context: context,
        builder: (_) => Material(
          type: MaterialType.transparency,
          child: Container(
            color: Styles().colors!.blackTransparent06,
            child: Stack(
              children: <Widget>[
                Align(alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16,vertical: 17),
                      child: Column(
                        children: <Widget>[
                          Expanded(child: Container()),
                          Container(height: 8,),
                          RoundedButton(
                            label: Localization().getStringEx("panel.groups_admin.button.remove.title", "Remove event"),
                            backgroundColor: Styles().colors!.white,
                            borderColor: Styles().colors!.fillColorPrimary,
                            textColor: Styles().colors!.fillColorPrimary,
                            fontFamily: Styles().fontFamilies!.regular,
                            fontSize: 16,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            contentWeight: 0.0,
                            borderWidth: 2,
                            onTap: (){
                              Analytics().logAlert(text: 'Remove event', selection: 'OK');
                              _removeEvent(context, event);
                            },
                          ),
                          Container(height: 8,),
                          RoundedButton(
                            label: Localization().getStringEx("panel.groups_admin.button.cancel.title", "Cancel"),
                            backgroundColor: Styles().colors!.white,
                            borderColor: Styles().colors!.fillColorSecondary,
                            textColor: Styles().colors!.fillColorPrimary,
                            fontFamily: Styles().fontFamilies!.bold,
                            fontSize: 16,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            contentWeight: 0.0,
                            borderWidth: 2,
                            onTap: (){
                              Analytics().logAlert(text: 'Remove event', selection: 'Cancel');
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    )
                )
              ],
            ),
          ),
        )
    );
  }

  _removeEvent(BuildContext context,GroupEvent? event){
    onDeleteTap!(event);
    Navigator.pop(context);
  }
}

class EventContent extends StatelessWidget {
  final GroupEvent? event;
  final Widget? topRightButton;

  EventContent({this.event, this.topRightButton});

  @override
  Widget build(BuildContext context) {
    List<Widget> content = [
      Padding(padding: EdgeInsets.only(bottom: 8,right: 25), child:
      Text(event?.title??"",  style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20, color: Styles().colors!.fillColorPrimary),),
      ),
    ];
    content.add(Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Row(children: <Widget>[
      Padding(padding: EdgeInsets.only(right: 8), child: Image.asset('images/icon-calendar.png'),),
      Expanded(
        child: Text(event?.timeDisplayString ?? '',  style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 14, color: Styles().colors!.textBackground),),
      )
    ],)),);

    return Stack(children: <Widget>[
      GestureDetector(onTap: () { /* push event detail */ },
          child: Padding(padding: EdgeInsets.all(16), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: content),
          )
      ),

       topRightButton!=null ?
        Align(alignment: Alignment.topRight,
          child: topRightButton) : Container()
    ],);

  }
}