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
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth.dart';
import 'package:illinois/service/ExploreService.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/ui/events/CreateEventPanel.dart';
import 'package:illinois/ui/groups/GroupCreatePostPanel.dart';
import 'package:illinois/ui/groups/GroupMembershipRequestPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/groups/GroupsEventDetailPanel.dart';
import 'package:illinois/ui/widgets/ExpandableText.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/SectionTitlePrimary.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:url_launcher/url_launcher.dart';

import 'GroupAdminPanel.dart';
import 'GroupMembersPanel.dart';
import 'GroupSettingsPanel.dart';

enum _DetailTab { Events, About }

class GroupPanel extends StatefulWidget {

  final String groupId;

  GroupPanel({this.groupId});

  @override
  _GroupPanelState createState() => _GroupPanelState();
}

class _GroupPanelState extends State<GroupPanel> implements NotificationsListener {

  Group              _group;
  bool               _loading = false;
  bool               _cancelling = false;
  bool               _leaving = false;
  List<GroupEvent>   _groupEvents;
  List<Member>       _groupAdmins;
  Map<String, Event> _stepsEvents = Map<String, Event>();

  _DetailTab       _currentTab = _DetailTab.Events;

  bool get _isMember {
    if(_group?.members?.isNotEmpty ?? false){
      for(Member member in _group.members){
        if(member.email == Auth()?.authInfo?.email){
          return true;
        }
      }
    }
    return false;
  }
  
  bool get _isAdmin {
    if(_group?.members?.isNotEmpty ?? false){
      for(Member member in _group.members){
        if(member.email == Auth()?.authInfo?.email && member.status == GroupMemberStatus.admin){
          return true;
        }
      }
    }
    return false;
  }

  bool get isPublic {
    return _group?.privacy == GroupPrivacy.public;
  }

  bool get isFavorite {
    return false;
  }

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [Groups.notifyUserMembershipUpdated, Groups.notifyGroupCreated, Groups.notifyGroupUpdated]);

    _loadGroup();

    Groups().loadEvents(widget.groupId, limit: 3).then((List<GroupEvent> events) { 
      if (mounted) {
        setState(() {
          _groupEvents = events;
          _applyStepEvents(events);
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();

    NotificationService().unsubscribe(this);
  }

  void _loadGroup(){
    setState(() {
      _loading = true;
    });
    Groups().loadGroup(widget.groupId).then((Group group){
      if (mounted) {
        setState(() {
          _loading = false;
          if(group != null) {
            _group = group;
            _groupAdmins = _group.getMembersByStatus(GroupMemberStatus.admin);
            _loadMembershipStepEvents();
          }
        });
      }
    });
  }

  void _cancelMembershipRequest(){
    setState(() {
      _cancelling = true;
    });
    Groups().cancelRequestMembership(widget.groupId).whenComplete((){
      if (mounted) {
        setState(() {
          _cancelling = false;
        });
        _loadGroup();
      }
    });
  }

  Future<void> _leaveGroup(Function setStateEx){
    setStateEx(() {
      _leaving = true;
    });
    return Groups().leaveGroup(widget.groupId).whenComplete((){
      if (mounted) {
        setStateEx(() {
          _leaving = false;
        });
        _loadGroup();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading == true) {
      content = _buildLoadingContent();
    }
    else if (_group != null) {
      content = _buildGroupContent();
    }
    else {
      content = _buildErrorContent();
    }

    return Scaffold(
      appBar: AppBar(
        leading: HeaderBackButton(),
        actions: [
          Semantics(
              label:  'Options',
              button: true,
              excludeSemantics: true,
              child: IconButton(
                icon: Image.asset(
                  'images/groups-more-inactive.png',
                ),
                onPressed:_onGroupOptionsTap,
              ))
        ],
      ),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
      body: content,
    );
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Groups.notifyUserMembershipUpdated) {
      setState(() {});
    }
    else if (param == widget.groupId && (name == Groups.notifyGroupCreated || name == Groups.notifyGroupUpdated)){
      _loadGroup();
    }
  }

  // Content Builder

  Widget _buildLoadingContent() {
    return Stack(children: <Widget>[
      Column(children: <Widget>[
        Expanded(
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorSecondary), ),
          ),
        ),
      ]),
      SafeArea(
        child: HeaderBackButton()
      ),
    ],);
  }

  Widget _buildErrorContent() {
    return Stack(children: <Widget>[
      Column(children: <Widget>[
        Expanded(
          child: Center(
            child: Padding(padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text('Failed to load group data.',  style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 20, color: Styles().colors.fillColorPrimary),)
            ),
          ),
        ),
      ]),
      SafeArea(
        child: HeaderBackButton()
      ),
    ],);
  }

  Widget _buildGroupContent() {
    List<Widget> content = [
      _buildImageHeader(),
      _buildGroupInfo()
    ];
    if (_isMember) {
      content.add(_buildTabs());
      if (_currentTab == _DetailTab.Events) {
        content.add(_buildEvents());
      }
      else if (_currentTab == _DetailTab.About) {
        content.add(_buildAbout());
      }
    }
    else {
      content.add(_buildAbout());
      content.add(_buildAdmins());
      if (isPublic) {
        content.add(_buildEvents());
      }
    }

    return Column(children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content,
            ),
          ),
        ),
        _buildMembershipRequest(),
        _buildCancelMembershipRequest(),
      ],
    );
  }

  Widget _buildImageHeader(){
    return Container(
      height: 200,
      color: Styles().colors.background,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          AppString.isStringNotEmpty(_group?.imageURL) ?  Positioned.fill(child:Image.network(_group?.imageURL, fit: BoxFit.cover, headers: AppImage.getAuthImageHeaders(),)) : Container(),
          CustomPaint(
            painter: TrianglePainter(painterColor: Styles().colors.fillColorSecondaryTransparent05, left: false),
            child: Container(
              height: 53,
            ),
          ),
          CustomPaint(
            painter: TrianglePainter(painterColor: Styles().colors.white),
            child: Container(
              height: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfo() {
    List<Widget> commands = List<Widget>();

    String members;
    int membersCount = _group?.membersCount ?? 0;
    if (membersCount == 0) {
      members = 'No Members';
    }
    else if (membersCount == 1) {
      members = '1 Member';
    }
    else {
      members = '$membersCount Members';
    }

    if(_isMember){
      if(_isAdmin){
        commands.add(RibbonButton(
          height: null,
          label: Localization().getStringEx("panel.groups_admin.button.manage_members.title", "Manage Members"),
          hint: Localization().getStringEx("panel.groups_admin.button.manage_members.hint", ""),
          leftIcon: 'images/icon-member.png',
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 0),
          onTap: onTapMembers,
        ));
        commands.add(Container(height: 1, color: Styles().colors.surfaceAccent,));
        commands.add(RibbonButton(
          height: null,
          label: Localization().getStringEx("panel.groups_admin.button.group_settings.title", "Group Settings"),
          hint: Localization().getStringEx("panel.groups_admin.button.group_settings.hint", ""),
          leftIcon: 'images/icon-gear.png',
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 0),
          onTap: onTapSettings,
        ));
      }
    } else {
      String tags = "";
      if (_group?.tags?.isNotEmpty ?? false) {
        for (String tag in _group.tags) {
          if (0 < (tag?.length ?? 0)) {
            tags+=((tags.isNotEmpty? ", ": "") + tag ?? '');
          }
        }
      }

      commands.add(
        RibbonButton(label: 'Website',
          icon: 'images/external-link.png',
          leftIcon: 'images/globe.png',
          padding: EdgeInsets.symmetric(horizontal: 0),
          onTap: (){ _onWebsite(); },)
      );
      if(tags?.isNotEmpty ?? false) {
        commands.add(Container(height: 12,));
        commands.add(
          Padding(padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(child:
              RichText(
                text: new TextSpan(
                  style: TextStyle(color: Styles().colors.textSurface,
                      fontFamily: Styles().fontFamilies.bold,
                      fontSize: 12),
                  children: <TextSpan>[
                    new TextSpan(text: "Group Tags: "),
                    new TextSpan(
                        text: tags,
                        style: TextStyle(
                            fontFamily: Styles().fontFamilies.regular)),
                  ],
                ),
              )
              )
            ],),
          ),);
      }
    }

    return Container(color: Colors.white,
      child: Stack(children: <Widget>[
        Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _isMember? Container():
                Padding(padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: <Widget>[
                    Expanded(child:
                      Text(_group?.category?.toUpperCase() ?? '', style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 12, color: Styles().colors.fillColorPrimary),),
                    ),
                  ],),),
              (!_isMember)? Container():
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _group.currentUserStatusColor,
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                        child: Center(
                          child:
                          Semantics(
                            label: _group?.currentUserStatusText?.toLowerCase(),
                            excludeSemantics: true,
                            child: Text(_group.currentUserStatusText.toUpperCase(),
                              style: TextStyle(
                                  fontFamily: Styles().fontFamilies.bold,
                                  fontSize: 12,
                                  color: Styles().colors.white
                              ),
                            )
                          ),
                        ),
                      ),
                      Expanded(child: Container(),),
                    ],
                  ),
                ),
              Padding(padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(_group?.title ?? '',  style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 32, color: Styles().colors.fillColorPrimary),),
              ),
              Padding(padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(members,  style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.textBackground, ),)
              ),
              Padding(padding: EdgeInsets.symmetric(vertical: 4),
                child: Column(children: commands,),
              ),
            ],),
          ),
        ],),
      );
  }

  Widget _buildTabs() {
    List<Widget> tabs = [];
    for (_DetailTab tab in _DetailTab.values) {
      String title;
      switch(tab) {
        case _DetailTab.Events: title = 'Events'; break;
        case _DetailTab.About: title = 'About'; break;
      }
      bool selected = (_currentTab == tab);

      if (0 < tabs.length) {
        tabs.add(Padding(padding: EdgeInsets.only(left: 8),child: Container(),));
      }

      tabs.add(Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
        RoundedButton(label: title,
          backgroundColor: selected ? Styles().colors.fillColorPrimary : Styles().colors.background,
          textColor: selected ? Colors.white :  Styles().colors.fillColorPrimary,
          fontFamily: selected ? Styles().fontFamilies.bold : Styles().fontFamilies.regular,
          fontSize: 16,
          padding: EdgeInsets.symmetric(horizontal: 16),
          borderColor: selected ? Styles().colors.fillColorPrimary : Styles().colors.surfaceAccent,
          borderWidth: 1,
          height: 22 + 16*MediaQuery.of(context).textScaleFactor,
          onTap:() { _onTab(tab); }
        ),
      ],));
    }

    return
      Row(children: [
        Expanded(
          child: Container(
            child: Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children:tabs),
                )
            ),
          )
        )
      ],);
  }

  Widget _buildEvents() {
    
    List<Widget> content = [];
    if(_isAdmin){
      content.add(_buildAdminEventOptions());
    }

    if (_groupEvents != null) {
      for (GroupEvent groupEvent in _groupEvents) {
        content.add(_EventCard(groupEvent: groupEvent, group: _group, isAdmin: _isAdmin));
      }
    }

    content.add(Padding(padding: EdgeInsets.only(top: 16), child:
      ScalableSmallRoundedButton(
          label: 'See all events',
          widthCoeficient: 2,
          backgroundColor: Styles().colors.white,
          textColor: Styles().colors.fillColorPrimary,
          fontFamily: Styles().fontFamilies.bold,
          fontSize: 16,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          borderColor: Styles().colors.fillColorSecondary,
          borderWidth: 2,
  //        height: 42,
          onTap:() {
            //TBD
          }
    )));

    return Column(
      children: <Widget>[
        SectionTitlePrimary(title: 'Upcoming Events (${_groupEvents?.length ?? 0})',
          iconPath: 'images/icon-calendar.png',
          children: content,),
      ]);
  }

  Widget _buildAdminEventOptions(){
    bool haveEvents = _groupEvents?.isNotEmpty ?? false;
    haveEvents = false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        decoration: BoxDecoration(
            color: Styles().colors.white,
            boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))],
            borderRadius: BorderRadius.all(Radius.circular(8))
        ),
        child: Column(children: [
          haveEvents? Container():
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text("No upcoming events", style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 20, color: Styles().colors.textBackground, ), textAlign: TextAlign.left,),
                Container(height: 8,),
                Text("Create a new event or share an existing event with your members. ", style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground, )),
                Container(height: 16,),
              ],),
          Row(
            children: [
              Expanded(child:
                ScalableRoundedButton(
                    label: "Browse",
                    backgroundColor: Styles().colors.white,
                    textColor: Styles().colors.fillColorPrimary,
                    fontFamily: Styles().fontFamilies.bold,
                    fontSize: 16,
                    borderColor: Styles().colors.fillColorSecondary,
                    borderWidth: 2,
                    //        height: 42,
                    onTap:() { /*TBD browse events*/ }
                ),
              ),
              Container(width: 16,),
              Expanded(child:
                ScalableRoundedButton(
                  label: "Create event",
                  backgroundColor: Styles().colors.white,
                  textColor: Styles().colors.fillColorPrimary,
                  fontFamily: Styles().fontFamilies.bold,
                  fontSize: 16,
                  borderColor: Styles().colors.fillColorSecondary,
                  borderWidth: 2,
                  //        height: 42,
                  onTap: _onTapCreateEvent,
                  showAdd: true,),
              )
            ],
          ),
        ],)
      ),
    );
  }

  Widget _buildAbout() {
    String description = _group?.description ?? '';
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(padding: EdgeInsets.only(bottom: 16), child:
          Text('About us', style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 16, color: Color(0xff494949), ),),
        ),
        ExpandableText(description, style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground, ), trimLines: 4, iconColor: Styles().colors.fillColorPrimary,),
      ],),);
  }

  Widget _buildAdmins() {
    List<Widget> content = [];
    if (0 < (_groupAdmins?.length ?? 0)) {
      content.add(Padding(padding: EdgeInsets.only(left: 16), child: Container()),);
      for (Member officer in _groupAdmins) {
        if (1 < content.length) {
          content.add(Padding(padding: EdgeInsets.only(left: 8), child: Container()),);
        }
        content.add(_OfficerCard(groupMember: officer,));
      }
      content.add(Padding(padding: EdgeInsets.only(left: 16), child: Container()),);
    }
    return
      Stack(children: [
        Container(
            height: 112,
            color: Styles().colors.backgroundVariant,
            child:
            Column(children: [
              Container(height: 80,),
              Container(
                  height: 32,
                  child: CustomPaint(
                    painter: TrianglePainter(painterColor: Styles().colors.background),
                    child: Container(),
                  )
              ),
            ],)
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
            Text('Admins', style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 20, color: Styles().colors.fillColorPrimary, ),),
          ),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child:
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: content),
          ),

        ],),)
      ],);
  }

  Widget _buildMembershipRules() {
    List<Widget> content = [];
    List<GroupMembershipStep> steps = _group?.membershipQuest?.steps;
    if (steps != null) {
      for (int index = 0; index < steps.length; index++) {
        content.add(_MembershipStepCard(membershipStep: steps[index], stepsEvents:_stepsEvents, stepIndex: index,));
      }
    }
    return Column(
      children: <Widget>[
        SectionTitlePrimary(title: 'Become a member',
          iconPath: 'images/member.png',
          children: content,),
      ]);
  }

  Widget _buildMembershipRequest() {
    return
      Auth().isShibbolethLoggedIn && _group.currentUserCanJoin
          ? Container(color: Colors.white,
              child: Padding(padding: EdgeInsets.all(16),
                  child: ScalableRoundedButton(label: 'Request to join',
                    backgroundColor: Styles().colors.white,
                    textColor: Styles().colors.fillColorPrimary,
                    fontFamily: Styles().fontFamilies.bold,
                    fontSize: 16,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    borderColor: Styles().colors.fillColorSecondary,
                    borderWidth: 2,
                    onTap:() { _onMembershipRequest();  }
                  ),
              ),
            )
          : Container();
  }

  Widget _buildCancelMembershipRequest() {
    return
      Auth().isShibbolethLoggedIn && _group.currentUserIsPendingMember
          ? Stack(
            alignment: Alignment.center,
            children: [
              Container(color: Colors.white,
                  child: Padding(padding: EdgeInsets.all(16),
                    child: ScalableRoundedButton(label: 'Cancel Request',
                        backgroundColor: Styles().colors.white,
                        textColor: Styles().colors.fillColorPrimary,
                        fontFamily: Styles().fontFamilies.bold,
                        fontSize: 16,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        borderColor: Styles().colors.fillColorSecondary,
                        borderWidth: 2,
                        onTap:() { _onCancelMembershipRequest();  }
                    ),
                  )),
              _cancelling ? CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorSecondary), ) : Container(),
            ],
          )
          : Container();
  }

  Widget _buildSocial() {
    return Padding(padding: EdgeInsets.all(16), child: Row(children: <Widget>[
      Expanded(child: Container(),),
      _SocialButton(imageAsset:'images/fb-12x24.png', onTap: () { _onSocialFacebook(); }),
      Padding(padding: EdgeInsets.only(left: 8),),
      _SocialButton(imageAsset:'images/twitter-24x22.png', onTap: () { _onSocialTwitter(); }),
      Padding(padding: EdgeInsets.only(left: 8),),
      _SocialButton(imageAsset:'images/ig-24x24.png', onTap: () { _onSocialInstagram(); }),
      Expanded(child: Container(),),
    ],),);
  }

  Widget _buildCancelRequestDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Styles().colors.fillColorPrimary,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Text(
                "Are you sure you want to cancel your request to join this group?",
                textAlign: TextAlign.left,
                style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Styles().colors.white),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                RoundedButton(
                  label: "Back",
                  fontFamily: "ProximaNovaRegular",
                  textColor: Styles().colors.fillColorPrimary,
                  borderColor: Styles().colors.white,
                  backgroundColor: Styles().colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  onTap: ()=>Navigator.pop(context),
                ),
                Container(width: 16,),
                RoundedButton(
                  label: "Cancel request",
                  fontFamily: "ProximaNovaBold",
                  textColor: Styles().colors.fillColorPrimary,
                  borderColor: Styles().colors.white,
                  backgroundColor: Styles().colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  onTap: (){
                    _cancelMembershipRequest();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveGroupDialog(BuildContext context) {
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
                      "Are you sure you want to leave this group?",
                      textAlign: TextAlign.left,
                      style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Styles().colors.white),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      RoundedButton(
                        label: "Back",
                        fontFamily: "ProximaNovaRegular",
                        textColor: Styles().colors.fillColorPrimary,
                        borderColor: Styles().colors.white,
                        backgroundColor: Styles().colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        onTap: ()=>Navigator.pop(context),
                      ),
                      Container(width: 16,),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          RoundedButton(
                            label: "Leave",
                            fontFamily: "ProximaNovaBold",
                            textColor: Styles().colors.fillColorPrimary,
                            borderColor: Styles().colors.white,
                            backgroundColor: Styles().colors.white,
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            onTap: (){
                              _leaveGroup(setStateEx).then((value) => Navigator.pop(context));
                            },
                          ),
                          _leaving ? CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorSecondary), ) : Container(),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
    );
  }

  void _loadMembershipStepEvents() {
    Set<String> stepEventIds = Set<String>();
    List<GroupMembershipStep> steps = _group?.membershipQuest?.steps;
    if (0 < (steps?.length ?? 0)) {
      for (GroupMembershipStep step in steps) {
        if (step.eventIds != null) {
          stepEventIds.addAll(step.eventIds);
        }
      }

      ExploreService().loadEventsByIds(stepEventIds).then((List<Event> events){
        if (mounted) {
          setState(() {
            _applyStepEvents(events);
          });
        }
    
      });
    }
  }

  void _applyStepEvents(List<Event> events) {
    if (events != null) {
      for (Event event in events) {
        if ((event.id != null) && !_stepsEvents.containsKey(event.id)) {
          _stepsEvents[event.id] = event;
        }
      }
    }
  }

  void _onGroupOptionsTap(){
    //TBD rest options
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
                  label:"Leave group",
                  onTap: (){
                    showDialog(context: context, builder: (context)=>_buildLeaveGroupDialog(context)).then((value) => Navigator.pop(context));
                  },
                ),
                //Container(height: 1, color: Styles().colors.surfaceAccent,),
                //Container(height: 8,)
              ],
            ),
          );
        }
    );
  }

  void _onTab(_DetailTab tab) {
    setState(() {
      _currentTab = tab;
    });
  }

  void _onWebsite() {
    String url = _group?.webURL;
    if (url != null) {
      launch(url);
    }
  }


  void onTapMembers(){
    Analytics().logPage(name: "Group Members");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMembersPanel(groupId: _group.id)));
  }

  void onTapSettings(){
    Analytics().logPage(name: "Group Settings");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupSettingsPanel(group: _group,)));
  }

  void _onAdminView() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupAdminPanel(group: _group, groupEvents: _groupEvents,)));
  }

  void _onSocialFacebook() {
    launch('https://www.facebook.com');
  }

  void _onSocialTwitter() {
    launch('https://www.twitter.com');
  }

  void _onSocialInstagram() {
    launch('https://www.instagram.com');
  }

  void _onMembershipRequest() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMembershipRequestPanel(group: _group)));
  }

  void _onCancelMembershipRequest(){
    showDialog(context: context, builder: (context) => _buildCancelRequestDialog(context));
  }

  void _onSwitchFavorite() {
  }

  void _onTapCreateEvent(){
    Analytics().logPage(name: "Create Event");
    Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEventPanel(group: _group,)));
  }
}

class _EventCard extends StatefulWidget {
  final GroupEvent groupEvent;
  final Group group;
  final bool isAdmin;

  _EventCard({this.groupEvent, this.group, this.isAdmin = false});

  @override
  createState()=> _EventCardState();
}
class _EventCardState extends State<_EventCard>{
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
//              label: "See previous posts",
              child: GestureDetector(
              onTap: (){
                setState(() {
                _showAllComments = true;
              });},
              child: Center(child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text("See previous posts", style: TextStyle(fontSize: 16,
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
                  Text("Add a public post ...",style: TextStyle(fontSize: 16, color: Styles().colors.textSurface, fontFamily: Styles().fontFamilies.regular),)
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
          label: "Favorites",
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
                  label:"Remove Event",
                  onTap: (){
                    showDialog(context: context, builder: (context)=>_buildRemoveEventDialog(context)).then((value) => Navigator.pop(context));
                  },
                ),
                RibbonButton(
                  height: null,
                  leftIcon: "images/icon-leave-group.png",
                  label:"Delete Event",
                  onTap: (){
                    showDialog(context: context, builder: (context)=>_buildDeleteEventDialog(context)).then((value) => Navigator.pop(context));
                  },
                ),
                RibbonButton(
                  height: null,
                  leftIcon: "images/icon-edit.png",
                  label:"Edit Event",
                  onTap: (){
                    _onEditEventTap(context);
                  },
                ),
                //Container(height: 1, color: Styles().colors.surfaceAccent,),
                //Container(height: 8,)
              ],
            ),
          );
        }
    );
  }

  Widget _buildRemoveEventDialog(BuildContext context){
    return GroupsConfirmationDialog(
        message: "Remove this event from your group page?",
        buttonTitle: "Remove",
        onConfirmTap:_onRemoveEvent);
  }

  Widget _buildDeleteEventDialog(BuildContext context){
    return GroupsConfirmationDialog(
        message: "Delete this event from your groups page?",
        buttonTitle:  "Delete",
        onConfirmTap:_onDeleteEvent);
  }

  void _onRemoveEvent(){
    //TBD
  }

  void _onDeleteEvent(){
    //TBD
  }

  void _onEditEventTap(BuildContext context){
    Analytics().logPage(name: "Create Event");
    Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEventPanel(group: group,)));
  }
}

class _OfficerCard extends StatelessWidget {
  final Member groupMember;
  
  _OfficerCard({this.groupMember});

  @override
  Widget build(BuildContext context) {

    return Container(
      width: 128,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Container(height: 144, width: 128,
          decoration: BoxDecoration(
            //color: Styles().colors.fillColorPrimary,
            image: DecorationImage(image: AppString.isStringNotEmpty(groupMember?.photoURL) ? NetworkImage(groupMember?.photoURL) : AssetImage('images/missing-photo-placeholder.png'), fit: BoxFit.contain),
              borderRadius: BorderRadius.all(Radius.circular(4))),
          ),
        Padding(padding: EdgeInsets.only(top: 4),
          child: Text(groupMember?.name ?? "", style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.fillColorPrimary),),),
        Text(groupMember?.officerTitle ?? "", style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground),),
      ],),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final double width;
  final double height;
  final String imageAsset;
  final GestureTapCallback onTap;
  
  _SocialButton({this.width = 48, this.height = 48, this.imageAsset, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Styles().colors.fillColorPrimary,
          borderRadius:BorderRadius.circular(3),
          boxShadow: [BoxShadow(color: Color(0x30002855), spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
        ),
        child: Align(alignment: Alignment.center, child: Image.asset(imageAsset),),
      ),
    );
  }
}

class _MembershipStepCard extends StatelessWidget {
  
  final GroupMembershipStep membershipStep;
  final Map<String, Event> stepsEvents;
  final int stepIndex;
  
  _MembershipStepCard({this.membershipStep, this.stepsEvents, this.stepIndex});

  @override
  Widget build(BuildContext context) {
    
    List<Widget> content = [];

    content.add(Padding(padding: EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Step ${(stepIndex ?? 0) + 1}',  style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.fillColorPrimary),),),
        Padding(padding: EdgeInsets.only(bottom: 8), child: Text(membershipStep.description ?? '',  style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground),),),
      ]),
    ));

    if ((stepsEvents != null) && (membershipStep?.eventIds != null)) {
      for (String eventId in membershipStep.eventIds) {
        Event event = stepsEvents[eventId];
        if (event != null) {
          content.add(Container(color: Styles().colors.surfaceAccent, height: 1,));
          content.add(_EventContent(event: event,),);
        }
      }
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
}