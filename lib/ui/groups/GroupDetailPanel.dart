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
import 'package:illinois/service/ExploreService.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/ui/groups/GroupMembershipRequestPanel.dart';
import 'package:illinois/ui/widgets/ExpandableText.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
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

class GroupDetailPanel extends StatefulWidget {

  final String groupId;

  GroupDetailPanel({this.groupId});

  @override
  _GroupDetailPanelState createState() => _GroupDetailPanelState();
}

class _GroupDetailPanelState extends State<GroupDetailPanel> implements NotificationsListener {

  GroupDetail        _groupDetail;
  bool               _loadingGroupDetail;
  List<GroupEvent>   _groupEvents;
  List<GroupMember>  _groupOfficers;
  Map<String, Event> _stepsEvents = Map<String, Event>();

  _DetailTab       _currentTab = _DetailTab.Events;

  bool get _isMember {
    return Groups().getUserMembership(widget.groupId) != null;
  }
  
  bool get _isAdmin {
    return Groups().getUserMembership(widget.groupId)?.admin ?? false;
  }

  bool get isPublic {
    return _groupDetail?.privacy == GroupPrivacy.public;
  }

  bool get isFavorite {
    return false;
  }

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, Groups.notifyUserMembershipUpdated);
    Groups().updateUserMemberships();
    
    _loadingGroupDetail = true;
    Groups().loadGroupDetail(widget.groupId).then((GroupDetail groupDetail){
      if (mounted) {
        setState(() {
          _loadingGroupDetail = false;
          _groupDetail = groupDetail;
          _loadMembershipStepEvents();
        });
      }
    });

    Groups().loadEvents(widget.groupId, limit: 3).then((List<GroupEvent> events) { 
      if (mounted) {
        setState(() {
          _groupEvents = events;
          _applyStepEvents(events);
        });
      }
    });

    Groups().loadGroupMembers(widget.groupId, status: GroupMemberStatus.officer).then((List<GroupMember> members) {
      if (mounted) {
        setState(() {
          _groupOfficers = members;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();

    NotificationService().unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loadingGroupDetail == true) {
      content = _buildLoadingContent();
    }
    else if (_groupDetail != null) {
      content = _buildGroupContent();
    }
    else {
      content = _buildErrorContent();
    }

    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
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
        child: _HeaderBackButton()
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
        child: _HeaderBackButton()
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
      content.add(_buildOfficers());
      if (isPublic) {
        content.add(_buildEvents());
      }
      content.add(_buildMembershipRequest());
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
          AppString.isStringNotEmpty(_groupDetail?.imageURL) ?  Positioned.fill(child:Image.network(_groupDetail?.imageURL, fit: BoxFit.cover, headers: AppImage.getAuthImageHeaders(),)) : Container(),
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
    int membersCount = _groupDetail?.membersCount ?? 0;
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
      List<Widget> tags = [];
      if (_groupDetail?.tags != null) {
        for (String tag in _groupDetail.tags) {
          if (0 < (tag?.length ?? 0)) {
            tags.add(Container(decoration:BoxDecoration(color: Styles().colors.fillColorPrimary, borderRadius:BorderRadius.circular(3),), child:
            Padding(padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8), child:
            Text(tag?.toUpperCase() ?? '', style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 12, color: Colors.white, ),),),),
            );
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
      commands.add(
        Padding(padding: EdgeInsets.symmetric(vertical: 4),
          child: Wrap(runSpacing: 8, spacing: 8, children:tags),
        ),);
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
                      Text(_groupDetail?.category?.toUpperCase() ?? '', style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 12, color: Styles().colors.fillColorPrimary),),
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
                          color: _isAdmin? Styles().colors.fillColorSecondary:  Styles().colors.fillColorPrimary,
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                        child: Center(
                          child: Text(_isAdmin? "ADMIN" : "MEMBER",
                            style: TextStyle(
                                fontFamily: Styles().fontFamilies.bold,
                                fontSize: 12,
                                color: Styles().colors.white
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: Container(),),
                    ],
                  ),
                ),
              Padding(padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(_groupDetail?.title ?? '',  style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 32, color: Styles().colors.fillColorPrimary),),
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
    if (_groupEvents != null) {
      for (GroupEvent groupEvent in _groupEvents) {
        content.add(_EventCard(groupEvent: groupEvent,));
      }
    }

    content.add(Padding(padding: EdgeInsets.only(top: 16), child:
      ScalableSmallRoundedButton(
          label: 'See all events',
          backgroundColor: Styles().colors.white,
          textColor: Styles().colors.fillColorPrimary,
          fontFamily: Styles().fontFamilies.bold,
          fontSize: 16,
          padding: EdgeInsets.symmetric(horizontal: 32, ),
          borderColor: Styles().colors.fillColorSecondary,
          borderWidth: 2,
  //        height: 42,
          onTap:() {  }
    )));

    return Column(
      children: <Widget>[
        SectionTitlePrimary(title: 'Upcoming Events (${_groupEvents?.length ?? 0}+)',
          iconPath: 'images/icon-calendar.png',
          children: content,),
      ]);
  }

  Widget _buildAbout() {
    String description = _groupDetail?.description ?? '';
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(padding: EdgeInsets.only(bottom: 16), child:
          Text('About this group', style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 16, color: Color(0xff494949), ),),
        ),
        Text(description, style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground, ),),
      ],),);
  }

  Widget _buildOfficers() {
    List<Widget> content = [];
    if (0 < (_groupOfficers?.length ?? 0)) {
      content.add(Padding(padding: EdgeInsets.only(left: 16), child: Container()),);
      for (GroupMember officer in _groupOfficers) {
        if (1 < content.length) {
          content.add(Padding(padding: EdgeInsets.only(left: 8), child: Container()),);
        }
        content.add(_OfficerCard(groupMember: officer,));
      }
      content.add(Padding(padding: EdgeInsets.only(left: 16), child: Container()),);
    }
    return Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
          Text('Current Officers', style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 20, color: Styles().colors.fillColorPrimary, ),),
        ),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: content),
        ),
        
      ],),);
  }

  Widget _buildMembershipRules() {
    List<Widget> content = [];
    List<GroupMembershipStep> steps = _groupDetail?.membershipQuest?.steps;
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
    return Container(color: Colors.white,
      child: Padding(padding: EdgeInsets.all(16),
        child: Row(children: <Widget>[
          Expanded(child: Container(),),
          RoundedButton(label: 'Request to join this group',
            backgroundColor: Styles().colors.white,
            textColor: Styles().colors.fillColorPrimary,
            fontFamily: Styles().fontFamilies.bold,
            fontSize: 16,
            padding: EdgeInsets.symmetric(horizontal: 32, ),
            borderColor: Styles().colors.fillColorSecondary,
            borderWidth: 2,
            height: 42,
            onTap:() { _onMembershipRequest();  }
          ),
          Expanded(child: Container(),),
        ],),
      ),
    );
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

  void _loadMembershipStepEvents() {
    
    Set<String> stepEventIds = Set<String>();
    List<GroupMembershipStep> steps = _groupDetail?.membershipQuest?.steps;
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

  void _onTab(_DetailTab tab) {
    setState(() {
      _currentTab = tab;
    });
  }

  void _onWebsite() {
    String url = _groupDetail?.webURL;
    if (url != null) {
      launch(url);
    }
  }


  void onTapMembers(){
    Analytics().logPage(name: "Group Members");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMembersPanel(groupDetail: _groupDetail)));
  }

  void onTapSettings(){
    Analytics().logPage(name: "Group Settings");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupSettingsPanel(groupDetail: _groupDetail,)));
  }

  void _onAdminView() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupAdminPanel(groupDetail: _groupDetail, groupEvents: _groupEvents,)));
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
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupMembershipRequestPanel(groupDetail: _groupDetail)));    
  }

  void _onSwitchFavorite() {
  }
}

class _EventCard extends StatelessWidget {

  final GroupEvent groupEvent;
  
  _EventCard({this.groupEvent});

  @override
  Widget build(BuildContext context) {
    
    List<Widget> content = [
      _EventContent(event: groupEvent,),
    ];

    if (0 < (groupEvent?.comments?.length ?? 0)) {
      content.add(Container(color: Styles().colors.surfaceAccent, height: 1,));
      
      List<Widget> content2 = [];
      for (GroupEventComment comment in groupEvent.comments) {
        content2.add(Padding(
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(image:NetworkImage(comment.member.photoURL), fit: BoxFit.cover),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Padding(padding:EdgeInsets.only(left: 8) , child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Padding(padding: EdgeInsets.only(bottom: 2), child:
                    Text(comment.member.name , style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 14, color: Styles().colors.fillColorPrimary),),
                  ),
                  Row(children: <Widget>[
                    Padding(padding: EdgeInsets.only(right: 2), child: 
                      Image.asset('images/icon-badge.png'),
                    ),
                    Text(comment.member.officerTitle, style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 10, color: Styles().colors.fillColorPrimary),),
                  ],)
                ],),),),
                Expanded(
                  flex: 3,
                  child: Text(AppDateTime().getDisplayDateTime(comment.dateCreated), style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 12, color: Styles().colors.textBackground),)
                )
              ],),
              Padding(padding: EdgeInsets.only(top:8), child:
                ExpandableText(comment.text, style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground),)
              ),
            ],),
          )));
      }

      content.add(Padding(padding: EdgeInsets.all(8), child:
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
}

class _EventContent extends StatelessWidget {
  final Event event;
  
  _EventContent({this.event});

  @override
  Widget build(BuildContext context) {
    
    List<Widget> content = [
      Padding(padding: EdgeInsets.only(bottom: 8), child:
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
      GestureDetector(onTap: () { /* push event detail */ },
        child: Padding(padding: EdgeInsets.all(16), child:
         Column(crossAxisAlignment: CrossAxisAlignment.start, children: content),
        )
      ),
      Align(alignment: Alignment.topRight,
        child: GestureDetector(onTap: () { /* switch favorite */ },
          child: Container(width: 48, height: 48,
            child: Align(alignment: Alignment.center,
              child: Image.asset('images/icon-star.png'),
            ),
          ),
        ),
      ),
    ],);

  }
}

class _OfficerCard extends StatelessWidget {
  final GroupMember groupMember;
  
  _OfficerCard({this.groupMember});

  @override
  Widget build(BuildContext context) {

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Container(height: 144, width: 128,
        decoration: BoxDecoration(
          //color: Styles().colors.fillColorPrimary,
          image: DecorationImage(image:NetworkImage(groupMember?.photoURL), fit: BoxFit.cover),
          borderRadius: BorderRadius.all(Radius.circular(4))),
        ),
      Padding(padding: EdgeInsets.only(top: 4),
        child: Text(groupMember?.name, style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.fillColorPrimary),),),
      Text(groupMember?.officerTitle, style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground),),
    ],);
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

class _HeaderBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: Localization().getStringEx('headerbar.back.title', 'Back'),
      hint: Localization().getStringEx('headerbar.back.hint', ''),
      button: true,
      child: GestureDetector(
        onTap: () {
          Analytics.instance.logSelect(target: "Back");
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ClipOval(
            child: Container(
                height: 32,
                width: 32,
                color: Styles().colors.fillColorPrimary,
                child: Image.asset('images/chevron-left-white.png')
            ),
          ),
        ),
      )
    );
  }
}