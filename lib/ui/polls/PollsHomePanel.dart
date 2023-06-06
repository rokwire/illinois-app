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
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/geo_fence.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/polls/PollProgressPainter.dart';
import 'package:illinois/ui/polls/CreatePollPanel.dart';
import 'package:illinois/ui/polls/PollBubblePinPanel.dart';
import 'package:illinois/ui/widgets/AccessWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:sprintf/sprintf.dart';
import 'package:illinois/service/Polls.dart' as illinois;


class PollsHomePanel extends StatefulWidget {

  _PollsHomePanelState createState() => _PollsHomePanelState();
}

class _PollsHomePanelState extends State<PollsHomePanel> implements NotificationsListener{

  _PollType? _selectedPollType;

  List<Poll>? _myPolls;
  PollsCursor? _myPollsCursor;
  String? _myPollsError;
  bool _myPollsLoading = false;
  
  List<Poll>? _recentPolls;
  List<Poll>? _recentLocalPolls;
  PollsCursor? _recentPollsCursor;
  String? _recentPollsError;
  bool _recentPollsLoading = false;

  List<Poll>? _groupPolls;
  PollsCursor? _groupPollsCursor;
  String? _groupPollsError;
  bool _groupPollsLoading = false;
  List<Group>? _myGroups;

  bool _hasPollsAccess = false;
  
  final GlobalKey _keyBleDescriptionText = GlobalKey();
  double _bleDescriptionTextHeight = 0;

  ScrollController? _scrollController;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Polls.notifyCreated,
      Polls.notifyDeleted,
      Polls.notifyStatusChanged,
      Polls.notifyVoteChanged,
      Polls.notifyResultsChanged,
      GeoFence.notifyCurrentRegionsUpdated,
      FlexUI.notifyChanged,
      Groups.notifyUserMembershipUpdated,
    ]);

    _scrollController = ScrollController();
    _scrollController!.addListener(_scrollListener);
    
    _recentLocalPolls = Polls().localRecentPolls();
    _selectPollType(_PollType.values[Storage().selectedPollType ?? 0]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evalBleDescriptionHeight();
    });

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.polls_home.text.header.title","Quick Polls"),
      ),
      body: _buildScaffoldBody(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildScaffoldBody() {
    List<Widget> bodyWidgets = [];
    Widget? accessWidget = AccessCard.builder(resource: 'polls');
    Widget content = Expanded(child:
      CustomScrollView(
          controller: _scrollController,
          slivers: <Widget>[
            SliverList(
              delegate: SliverChildListDelegate([
                Column(
                  children: <Widget>[
                    _buildDescriptionLayout(),
                    _buildPollsTabbar(),
                    _buildPollsContent(),
                  ],
                )
              ]),
            ),
          ],
      )
    );

    if (accessWidget != null) {
      bodyWidgets.add(Padding(padding: const EdgeInsets.only(top: 16), child: accessWidget));
      _hasPollsAccess = false;
    } else {
      bodyWidgets.add(content);
      bodyWidgets.add(_buildCreatePollButton());
      if (!_hasPollsAccess) {
        _loadPolls();
      }
      _hasPollsAccess = true;
    }
    return Column(children: bodyWidgets);
  }

  Widget _buildDescriptionLayout(){
    String description = Localization().getStringEx("panel.polls_home.text.pin_description", "Ask the creator of the poll for its four-digit number.");

    return Container(
      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      color: Styles().colors!.fillColorPrimary,
      child: Column(
        children: <Widget>[
          Row(children: <Widget>[
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(description,
                key: _keyBleDescriptionText,
                textAlign: TextAlign.center,
                style: Styles().textStyles?.getTextStyle("panel.polls.home.description")
                ),
            ),
            ),
          ],),
          Container(height: 10,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80),
            child: RoundedButton(
              label: Localization().getStringEx("panel.polls_home.button.find_poll.title","Find Poll"),
              textStyle: Styles().textStyles?.getTextStyle("widget.colourful_button.title.large.accent"),
              onTap: ()=>_onFindPollTapped(),
              backgroundColor: Styles().colors!.fillColorPrimary,
              borderColor: Styles().colors!.fillColorSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollsTabbar() {
    return Container(
      color: Styles().colors!.backgroundVariant,
      padding: EdgeInsets.only(left: 16, top: 16, right: 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _PollsHomePanelFilterTab(
              text: Localization().getStringEx("panel.polls_home.tab.title.recent_polls","Recent Polls"),
              tabPosition: _PollFilterTabPosition.left,
              selected: (_selectedPollType == _PollType.recentPolls),
              onTap: _onRecentPollsTapped,
            )
          ),
          Expanded(
              child: _PollsHomePanelFilterTab(
                text: Localization().getStringEx("panel.polls_home.tab.title.group_polls","Group Polls"),
                tabPosition: _PollFilterTabPosition.center,
                selected: (_selectedPollType == _PollType.groupPolls),
                onTap: _onGroupPollsTapped,
              )
          ),
          Expanded(
            child: _PollsHomePanelFilterTab(
              text: Localization().getStringEx("panel.polls_home.tab.title.my_polls","My Polls"),
              tabPosition: _PollFilterTabPosition.right,
              selected: (_selectedPollType == _PollType.myPolls),
              onTap: _onMyPollsTapped,
            )
          )
        ],
      ),
    );
  }

  Widget _buildPollsContent(){

    List<Poll>? polls;
    List<Poll>? localPolls;
    late bool pollsLoading;
    String? pollsError;
    if (_selectedPollType == _PollType.myPolls) {
      polls = _myPolls;
      pollsLoading = _myPollsLoading;
      pollsError = _myPollsError;
    }
    else if (_selectedPollType == _PollType.recentPolls) {
      polls = _recentPolls;
      localPolls = _recentLocalPolls;
      pollsLoading = _recentPollsLoading;
      pollsError = _recentPollsError;
    }
    else if (_selectedPollType == _PollType.groupPolls) {
      polls = _groupPolls;
      pollsLoading = _groupPollsLoading;
      pollsError = _groupPollsError;
    }

    int pollsLenght = (polls?.length ?? 0) + (localPolls?.length ?? 0);

    Widget pollsContent;
    if ((0 < pollsLenght) || pollsLoading) {
      pollsContent = _buildPolls(localPolls, polls, pollsLoading);
    }
    else if (pollsError != null) {
      pollsContent = _buildErrorContent(pollsError);
    }
    else {
      pollsContent = _buildEmptyContent();
    }

    return
      Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          Styles().images?.getImage("slant-dark") ?? Container(),
          Padding( padding: EdgeInsets.symmetric(horizontal: 16),
              child: pollsContent,
          )]);
  }

  List<Poll>? get _polls {
    switch (_selectedPollType) {
      case _PollType.myPolls:
        return _myPolls;
      case _PollType.recentPolls:
        return _recentPolls;
      case _PollType.groupPolls:
        return _groupPolls;
      default:
        return null;
    }
  }

  Widget _buildPolls(List<Poll>? polls1, List<Poll>? polls2, bool pollsLoading) {

    List<Widget> content = [];

    int pols1Len = (polls1 != null) ? polls1.length : 0;
    int pols2Len = (polls2 != null) ? polls2.length : 0;

    if (0 < (pols1Len + pols2Len)) {
      content.add(_constructListSeparator());
    }

    if (0 < pols1Len) {
      polls1!.forEach((poll){
        Group? group = _getGroup(poll.groupId);
        content.add(PollCard(poll: poll, group: group));
        content.add(_constructListSeparator());
      });
    }

    if (0 < pols2Len) {
      polls2!.forEach((poll){
        Group? group = _getGroup(poll.groupId);
        content.add(PollCard(poll: poll, group: group));
        content.add(_constructListSeparator());
      });
    }

    if (pollsLoading) {
        content.add(_constructLoadingIndicator());
        content.add(_constructListSeparator());
    }

    return Column(children:content);
  }

  Widget _constructListSeparator(){
    return Container(height: 16,);
  }

  Widget _constructLoadingIndicator() {
    return Container(height: 80, child: Align(alignment: Alignment.center, child: CircularProgressIndicator(),),);
  }

  Widget _buildEmptyContent(){
    String message, description;
    if (_selectedPollType == _PollType.myPolls) {
      message = Localization().getStringEx("panel.polls_home.tab.empty.message.my_pols","Have a question?");
      description = Localization().getStringEx("panel.polls_home.tab.empty.description.my_pols","Pose a question to people near you by creating your first poll");
    }
    else if (_selectedPollType == _PollType.recentPolls) {
      message = Localization().getStringEx("panel.polls_home.tab.empty.message.recent_polls","There’s nothing here…yet");
      description = Localization().getStringEx("panel.polls_home.tab.empty.description.recent_polls","Once you've participated in a poll you can track the results here.");
    }
    else if (_selectedPollType == _PollType.groupPolls) {
      message = Localization().getStringEx("panel.polls_home.tab.empty.message.group_polls","There’s nothing here…yet");
      description = Localization().getStringEx("panel.polls_home.tab.empty.description.group_polls","You will see the polls for all your groups.");
    }
    else {
      message = description = '';
    }

    return Container(padding: EdgeInsets.symmetric(horizontal: 24),child:
      Column(
        children:[
          Container(height: 100,),
          Text(message,
            textAlign: TextAlign.center,
            style: Styles().textStyles?.getTextStyle("widget.title.extra_large.extra_fat")
          ),
          Container(height: 16,),
          Text(description,
            textAlign: TextAlign.center,
            style:Styles().textStyles?.getTextStyle("widget.item.regular.thin") ),
        ]
    ));
  }

  Widget _buildErrorContent(String error){

    return Container(padding: EdgeInsets.symmetric(horizontal: 24),child:
      Column(
        children:[
          Container(height: 46,),
          Text(Localization().getStringEx("panel.polls_home.text.error","Error"),
            textAlign: TextAlign.center,
            style: Styles().textStyles?.getTextStyle("widget.title.extra_large.extra_fat")
          ),
          Container(height: 16,),
          Text(error,
            textAlign: TextAlign.center,
            style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"),)
        ]
    ));
  }

  Widget _buildCreatePollButton() {
    return Container(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), color:Styles().colors!.white,child:
      RoundedButton(label:Localization().getStringEx("panel.polls_home.text.create_poll","Create a Poll"),
          textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
          borderColor: Styles().colors!.fillColorSecondary,
          backgroundColor: Styles().colors!.white,
        onTap:_onCreatePollTapped
    ));
  }

  void _evalBleDescriptionHeight() {
    try {
      final RenderObject? renderBox = _keyBleDescriptionText.currentContext?.findRenderObject();
      if (renderBox is RenderBox) {
        _bleDescriptionTextHeight = renderBox.size.height;
      }
    } on Exception catch (e) {
      print(e.toString());
    }
  }

  void _onFindPollTapped() {
    Analytics().logSelect(target:"Find Poll");
    double topOffset = kToolbarHeight + 18 + _bleDescriptionTextHeight + 5;
    Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (context, _, __) => PollBubblePinPanel(topOffset:topOffset))).then((dynamic poll){
      if (poll is Poll) {
        if (!Polls().presentPollId(poll.pollId)) {
          AppAlert.showDialogResult(context, Localization().getStringEx('panel.polls_home.text.unable_to_present', 'Unable to present poll at the moment'));
        }
      }
    });
  }

  void _onCreatePollTapped(){
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CreatePollPanel()));
  }

  void _onRecentPollsTapped(){
    _selectPollType(_PollType.recentPolls);
  }

  void _onMyPollsTapped(){
    _selectPollType(_PollType.myPolls);
  }

  void _onGroupPollsTapped() {
    _selectPollType(_PollType.groupPolls);
  }

  void _selectPollType(_PollType pollType) {
    if (_selectedPollType != pollType) {
      setStateIfMounted(() {
        _selectedPollType = pollType;
        Storage().selectedPollType = _PollType.values.indexOf(_selectedPollType!);
        if (_polls == null) {
          _loadPolls();
        }
      });
    }
  }

  void _loadPolls() {

    if (_selectedPollType == _PollType.myPolls) {
      _loadMyPolls();
    }
    else if (_selectedPollType == _PollType.recentPolls) {
      _loadRecentPolls();
    }
    else if (_selectedPollType == _PollType.groupPolls) {
      _loadGroupPolls();
    }
  }

  void _loadMyPolls() {
    if (((_myPolls == null) || (_myPollsCursor != null)) && !_myPollsLoading) {
      setStateIfMounted(() {
        _myPollsLoading = true;
      });

      _loadMyGroupsIfNeeded().then((_) {
        Polls().getMyPolls(cursor: _myPollsCursor)!.then((PollsChunk? result) {
          setStateIfMounted(() {
            if (result != null) {
              if (_myPolls == null) {
                _myPolls = [];
              }
              _myPolls!.addAll(result.polls!);
              _myPollsCursor = (0 < result.polls!.length) ? result.cursor : null;
              _myPollsError = null;
            }
          });
        }).catchError((e) {
          _myPollsError = illinois.Polls.localizedErrorString(e);
        }).whenComplete(() {
          setStateIfMounted(() {
            _myPollsLoading = false;
          });
        });
      });
    }
  }

  void _loadRecentPolls() {
    if (((_recentPolls == null) || (_recentPollsCursor != null)) && !_recentPollsLoading) {
      setStateIfMounted(() {
        _recentPollsLoading = true;
      });

      _loadMyGroupsIfNeeded().then((_) {
        Polls().getRecentPolls(cursor: _recentPollsCursor)!.then((PollsChunk? result){
          setStateIfMounted((){
            if (result != null) {
              if (_recentPolls == null) {
                _recentPolls = [];
              }
              _stripRecentLocalPolls(result.polls);
              _recentPolls!.addAll(result.polls!);
              _recentPollsCursor = (0 < result.polls!.length) ? result.cursor : null;
              _recentPollsError = null;
            }
          });
        }).catchError((e){
          _recentPollsError = illinois.Polls.localizedErrorString(e);
        }).whenComplete((){
          setStateIfMounted((){
            _recentPollsLoading = false;
          });
        });
      });
    }
  }

  void _loadGroupPolls() {
    if (((_groupPolls == null) || (_groupPollsCursor != null)) && !_groupPollsLoading) {
      _setGroupPollsLoading(true);
      _loadMyGroupsIfNeeded().then((_) {
        Set<String>? groupIds = _myGroupIds;
        if (CollectionUtils.isNotEmpty(groupIds)) {
          Polls().getGroupPolls(groupIds: groupIds, cursor: _groupPollsCursor)!.then((PollsChunk? result) {
            if (result != null) {
              if (_groupPolls == null) {
                _groupPolls = [];
              }
              _groupPolls!.addAll(result.polls!);
              _groupPollsCursor = (0 < result.polls!.length) ? result.cursor : null;
              _groupPollsError = null;
            }
            setStateIfMounted(() {});
          }).catchError((e) {
            _groupPollsError = illinois.Polls.localizedErrorString(e);
          }).whenComplete(() {
            _setGroupPollsLoading(false);
          });
        } else {
          _setGroupPollsLoading(false);
        }
      });
    }
  }

  Future<void> _loadMyGroupsIfNeeded() async {
    if (CollectionUtils.isEmpty(_myGroups)) {
      await _reloadMyGroups();
    }
  }

  Future<void> _reloadMyGroups() async {
    List<Group>? allMyGroups = await Groups().loadGroups(contentType: GroupsContentType.my);
    _myGroups = _buildVisibleGroups(allMyGroups);
  }

  Set<String>? get _myGroupIds {
    Set<String>? groupIds;
    if (CollectionUtils.isNotEmpty(_myGroups)) {
      groupIds = <String>{};
      _myGroups!.forEach((group) {
        groupIds!.add(group.id!);
      });
    }
    return groupIds;
  }

  Group? _getGroup(String? groupId) {
    if (StringUtils.isNotEmpty(groupId) && CollectionUtils.isNotEmpty(_myGroups)) {
      for (Group group in _myGroups!) {
        if (groupId == group.id) {
          return group;
        }
      }
    }
    return null;
  }

  List<Group>? _buildVisibleGroups(List<Group>? allGroups) {
    List<Group>? visibleGroups;
    if (allGroups != null) {
      visibleGroups = <Group>[];
      for (Group group in allGroups) {
        if (group.isVisible) {
          ListUtils.add(visibleGroups, group);
        }
      }
    }
    return visibleGroups;
  }

  void _setGroupPollsLoading(bool loading) {
    setStateIfMounted(() {
      _groupPollsLoading = loading;
    });
  }

  void _stripRecentLocalPolls(List<Poll>?recentPolls) {
    if (recentPolls != null) {
      for (Poll? poll in recentPolls) {
        for (int index = _recentLocalPolls!.length - 1; 0 <= index; index--) {
          Poll localRecentPoll = _recentLocalPolls![index];
          if (localRecentPoll.pollId == poll!.pollId) {
            _recentLocalPolls!.removeAt(index);
          }
        }
      }
    }
  }

  void _updateRecentLocalPolls() {
    _recentLocalPolls = Polls().localRecentPolls();
    _stripRecentLocalPolls(_recentPolls);
  }

  void _updatePoll(Poll poll) {
    _updatePollInList(poll, _myPolls);
    _updatePollInList(poll, _recentPolls);
    _updatePollInList(poll, _recentLocalPolls);
  }

  void _updatePollInList(Poll? poll, List<Poll>?polls) {
    if ((poll != null) && (polls != null)) {
      for (int index = 0; index < polls.length; index++) {
        if (polls[index].pollId == poll.pollId) {
          polls[index] = poll;
        }
      }
    }
  }

  void _deletePoll(String? pollId) {
    _deletePollInList(pollId, _myPolls);
    _deletePollInList(pollId, _recentPolls);
    _deletePollInList(pollId, _recentLocalPolls);
  }

  void _deletePollInList(String? pollId, List<Poll>?polls) {
    if ((pollId != null) && (polls != null)) {
      for (int index = polls.length - 1; 0 <= index; index--) {
        if (polls[index].pollId == pollId) {
          polls.removeAt(index);
        }
      }
    }
  }

  void _resetMyPolls() {
    _myPolls = null;
    _myPollsCursor = null;
    _myPollsError = null;

    if (_selectedPollType == _PollType.myPolls) {
      _loadMyPolls();
    }
  }


  void _onPollCreated(String? pollId) {
    _resetMyPolls();
    setStateIfMounted(() {
      _updateRecentLocalPolls();  
    });
  }

  void _onPollUpdated(String? pollId) {
    Poll? poll = Polls().getPoll(pollId: pollId);
    if (poll != null) {
      setStateIfMounted(() {
        _updatePoll(poll);
      });
    }
  }

  void _onPollDeleted(String? pollId) {
    if (pollId != null) {
      setStateIfMounted(() {
        _deletePoll(pollId);
      });
    }
  }

  void _scrollListener() {
    if (_scrollController!.offset >= _scrollController!.position.maxScrollExtent) {
      _loadPolls();
    }
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == Polls.notifyCreated) {
      _onPollCreated(param);
    }
    else if (name == Polls.notifyDeleted) {
      _onPollDeleted(param);
    }
    else if (name == Polls.notifyVoteChanged) {
      _onPollUpdated(param);
    }
    else if (name == Polls.notifyResultsChanged) {
      _onPollUpdated(param);
    }
    else if (name == Polls.notifyStatusChanged) {
      _onPollUpdated(param);
    }
    else if (name == GeoFence.notifyCurrentRegionsUpdated) {
      setStateIfMounted(() { });
    }
    else if (name == FlexUI.notifyChanged) {
      setStateIfMounted(() { });
    }
    else if (name == Groups.notifyUserMembershipUpdated) {
      _reloadMyGroups().then((_) {
        _loadPolls();
      });
    }
  }
}

class _PollsHomePanelFilterTab extends StatelessWidget {
  final String? text;
  final String hint;
  final _PollFilterTabPosition tabPosition;
  final bool selected;
  final GestureTapCallback? onTap;

  // ignore: unused_element
  _PollsHomePanelFilterTab({Key? key, this.text, this.hint = '', this.tabPosition = _PollFilterTabPosition.left, this.selected = false, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Semantics(label: text, hint:hint, button:true, excludeSemantics: true, child:Container(
          height: 48,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Styles().colors!.lightGray,
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1.5, style: BorderStyle.solid),
            borderRadius: _borderRadius,
          ),
          child:Center(child: Text(text!,style: selected ? Styles().textStyles?.getTextStyle("widget.tab.selected") : Styles().textStyles?.getTextStyle("widget.tab.not_selected") )),
        ),
        ));
  }

  BorderRadiusGeometry get _borderRadius {
    switch (tabPosition) {
      case _PollFilterTabPosition.left:
        return BorderRadius.horizontal(left: Radius.circular(100.0));
      case _PollFilterTabPosition.center:
        return BorderRadius.zero;
      case _PollFilterTabPosition.right:
        return BorderRadius.horizontal(right: Radius.circular(100.0));
    }
  }
}

enum _PollType { myPolls, recentPolls, groupPolls }

enum _PollFilterTabPosition { left, center, right }

class PollCard extends StatefulWidget {
  final Poll? poll;
  final Group? group;

  const PollCard({Key? key, this.poll, this.group}) : super(key: key);
  _PollCardState createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  List<GlobalKey>? _progressKeys;
  double? _progressWidth;

  bool _showStartPollProgress = false;
  bool _showEndPollProgress = false;
  bool _showDeletePollProgress = false;

  GroupStats? _groupStats;

  @override
  void initState() {
    _loadGroupStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    if(poll.status == PollStatus.created) {
      pollStatus = Localization().getStringEx("panel.polls_home.card.state.text.created","Polls created");
      if (poll.isMine) {
        footerWidgets.add(_createStartPollButton());
        footerWidgets.add(Container(height:8));  
      }
    } if (poll.status == PollStatus.opened) {
      pollStatus = Localization().getStringEx("panel.polls_home.card.state.text.open","Polls open");
      if (poll.canVote) {
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

    String? groupName = widget.group?.title;

    bool canDeletePoll = poll.isMine || (widget.group?.currentUserIsAdmin ?? false);

    String pin = sprintf(Localization().getStringEx('panel.polls_home.card.text.pin', 'Pin: %s'), [
      sprintf('%04i', [poll.pinCode ?? 0])
    ]);

    Widget optionsWidget = ((poll.status == PollStatus.opened) && (poll.settings?.hideResultsUntilClosed ?? false)) ?
      Text(Localization().getStringEx("panel.poll_prompt.text.rule.detail.hide_result", "Results will not be shown until the poll ends."), style: Styles().textStyles?.getTextStyle("widget.card.detail.small")) :
      Column(children: _buildCheckboxOptions(),);

    Widget bodyWidget = Padding(padding: EdgeInsets.all(16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Visibility(visible: (widget.group != null), child:
          Padding(padding: EdgeInsets.only(bottom: 10, right: canDeletePoll ? 24 : 0), child:
            Row(children: [
              Padding(padding: EdgeInsets.only(right: 3), child:
                Text(Localization().getStringEx('panel.polls_home.card.group.label', 'Group:'), style:Styles().textStyles?.getTextStyle("widget.card.title.tiny")
                ),
              ),
              Expanded(child:
                Text(StringUtils.ensureNotEmpty(groupName), overflow: TextOverflow.ellipsis, style:Styles().textStyles?.getTextStyle("widget.card.title.tiny.fat")
                ),
              ),
            ]),
          ),
        ),
        Semantics(excludeSemantics: true, label: "$pollStatus,$pollVotesStatus", child:
          Padding(padding: EdgeInsets.only(bottom: 12, right: (canDeletePoll && (widget.group == null)) ? 24 : 0), child:
            Row(children: <Widget>[
              Text(StringUtils.ensureNotEmpty(pollVotesStatus), style:Styles().textStyles?.getTextStyle("widget.card.detail.tiny.fat")
              ),
              Text('  ', style:Styles().textStyles?.getTextStyle("widget.card.detail.tiny")
              ),
              Expanded(child:
                Text(pollStatus ?? '', style:
                Styles().textStyles?.getTextStyle("widget.card.detail.tiny"),
                ),
              ),
              Expanded(child: Container()),
              Text(pin, style: Styles().textStyles?.getTextStyle("widget.card.detail.tiny.fat"),
              )
            ],),
          ),
        ),
        Row(children: <Widget>[
          Expanded(child: Container(),)
        ],),
        Padding(padding: EdgeInsets.symmetric(vertical: 0),child:
          Text(poll.title ?? '', style:Styles().textStyles?.getTextStyle("widget.card.title.medium.extra_fat"),
          ),
        ),
        Container(height:12),
        optionsWidget,
        Container(height:25),
        Column(children: footerWidgets,),
      ]),
    );

    Widget contnetWidget = poll.isMine ? 
      Stack(children: <Widget>[
        bodyWidget,
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          _createDeletePollImageButton(),
        ],),
      ]) : bodyWidget;

    return Semantics(container: true, child:
      Column(children: <Widget>[
        Container(decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: BorderRadius.circular(5)), child:
          contnetWidget
        ),
      ],),
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
      String checkboxIconKey = didVote ? 'check-circle-filled' : 'check-circle-outline-gray';

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

      GlobalKey progressKey = GlobalKey();
      _progressKeys!.add(progressKey);

      String semanticsText = option +"\n "+  votesString +"," + votesPercent.toStringAsFixed(0) +"%";

      result.add(Padding(padding: EdgeInsets.only(top: (0 < result.length) ? 8 : 0), child:
      GestureDetector(
          child:
          Semantics(label: semanticsText, excludeSemantics: true, child:
          Row(children: <Widget>[
            Padding(padding: EdgeInsets.only(right: 10), child: Styles().images?.getImage(checkboxIconKey, excludeFromSemantics: true)),
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
                        child: Text(option, style: useCustomColor? Styles().textStyles?.getTextStyle("panel.polls.home.check.accent") : Styles().textStyles?.getTextStyle("panel.polls.home.check")),)),
                        Visibility( visible: didVote,
                        child: Padding(padding: EdgeInsets.only(right: 10), child: Styles().images?.getImage('check-circle-outline-gray', excludeFromSemantics: true))
                      ),
                    ],),)
              ),
            ],)
            ),
            Expanded(
              flex: 5,
              child: Padding(padding: EdgeInsets.only(left: 10), child: Text('$votesString (${votesPercent.toStringAsFixed(0)}%)', textAlign: TextAlign.right,style: Styles().textStyles?.getTextStyle("panel.polls.home.card.percentage.title"),),),
            )
          ],)
      ))));
    }
    return result;
  }

  Widget _createStartPollButton(){
    return _createButton(Localization().getStringEx("panel.polls_home.card.button.title.start_poll","Start Poll"), _onStartPollTapped, loading: _showStartPollProgress);
  }
  Widget _createEndPollButton(){
    return _createButton(Localization().getStringEx("panel.polls_home.card.button.title.end_poll","End Poll"), _onEndPollTapped, loading: _showEndPollProgress);
  }
  Widget _createVoteButton(){
    return _createButton(Localization().getStringEx("panel.polls_home.card.button.title.vote","Vote"), _onVoteTapped);
  }

  Widget _createButton(String title, void Function()? onTap, {bool enabled=true, bool loading = false}){
    return Container(padding: EdgeInsets.symmetric(horizontal: 54,), child:
      Semantics(label: title, container: true, button: true, excludeSemantics: true, child:
        GestureDetector(onTap: onTap, child:
          Stack(children: <Widget>[
            Container(padding: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
              decoration: BoxDecoration(
                color: Styles().colors!.white,
                border: Border.all(color: enabled? Styles().colors!.fillColorSecondary! :Styles().colors!.surfaceAccent!, width: 2.0),
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: Center(child:
                Text(title, style: Styles().textStyles?.getTextStyle("panel.polls.home.card.button.create.title")
                ),
              ),
            ),
            Visibility(visible: loading, child:
              Container(padding: EdgeInsets.symmetric(vertical: 5), child:
                Align(alignment: Alignment.center, child:
                  SizedBox(height: 24, width: 24, child:
                    CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorPrimary),)
                  ),
                ),
              ),
            ),
          ])
        ),
      ),
    );
  }

  Widget _createDeletePollImageButton() {
    String title = Localization().getStringEx("panel.polls_home.card.button.title.delete_poll","Delete Poll");
    return Semantics(label: title, container: true, button: true, excludeSemantics: true, child:
      GestureDetector(onTap: _onDeletePollTapped, child:
        Stack(children: [
          Padding(padding: EdgeInsets.all(12), child:
          Styles().images?.getImage('trash', excludeFromSemantics: true),
          ),
          _showDeletePollProgress ? Padding(padding: EdgeInsets.all(9), child:
            SizedBox(height: 24, width: 24, child:
              CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary),)
          )) : Container(),
        ]),
      ),
    );
  }

  Future<bool?> promptDeletePoll() async {
    String message =  Localization().getStringEx('panel.polls_home.card.button.prompt.delete_poll', 'Delete \"{PollTitle}\" poll?').replaceAll('{PollTitle}', widget.poll?.title ?? '');
    
    return await showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        content: Text(message),
        actions: <Widget>[
          TextButton(child: Text(Localization().getStringEx("dialog.yes.title", "Yes")),
            onPressed:(){
              Analytics().logAlert(text: message, selection: "Yes");
              Navigator.pop(context, true);
            }),
          TextButton(child: Text(Localization().getStringEx("dialog.no.title", "No")),
            onPressed:(){
              Analytics().logAlert(text: message, selection: "No");
              Navigator.pop(context, false);
            }),
        ]
      );
    });
  }

  void _loadGroupStats() {
    String? groupId = widget.group?.id;
    if (StringUtils.isNotEmpty(groupId)) {
      Groups().loadGroupStats(groupId!).then((stats) {
        setStateIfMounted(() {
          _groupStats = stats;
        });
      });
    }
  }

  void _onStartPollTapped(){
    if (_showStartPollProgress != true) {
      _setStartButtonProgress(true);
      Polls().open(widget.poll!.pollId).then((result) => _setStartButtonProgress(false)).catchError((e){
        _setStartButtonProgress(false);
        AppAlert.showDialogResult(context, illinois.Polls.localizedErrorString(e));
      });
    }
  }

  void _onEndPollTapped() {
    if (_showEndPollProgress != true) {
      _setEndButtonProgress(true);
      Polls().close(widget.poll!.pollId).then((result) {
          AppSemantics.announceMessage(context, Localization().getStringEx('panel.polls_home.card.button.message.end_poll.success', 'Poll ended successfully'));
          _setEndButtonProgress(false);
      }).catchError((e){
        _setEndButtonProgress(false);
        AppAlert.showDialogResult(context, illinois.Polls.localizedErrorString(e));
      });
    }
  }

  void _onDeletePollTapped() {
    if (_showDeletePollProgress != true) {
      promptDeletePoll().then((bool? result){
        if (result == true) {
          _setDeleteButtonProgress(true);
          Polls().delete(widget.poll!.pollId).then((result) {
              AppSemantics.announceMessage(context, Localization().getStringEx('panel.polls_home.card.button.message.delete_poll.success', 'Poll deleted successfully'));
              _setDeleteButtonProgress(false);
          }).catchError((e){
            _setDeleteButtonProgress(false);
            AppAlert.showDialogResult(context, illinois.Polls.localizedErrorString(e));
          });
        }
      });
    }
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
        setStateIfMounted(() {
          _progressWidth = progressWidth;
        });
      }
    }
  }

  void _setStartButtonProgress(bool showProgress){
    setStateIfMounted(() {
      _showStartPollProgress = showProgress;
    });
  }
  void _setEndButtonProgress(bool showProgress){
    setStateIfMounted(() {
      _showEndPollProgress = showProgress;
    });
  }

  void _setDeleteButtonProgress(bool showProgress){
    setStateIfMounted(() {
      _showDeletePollProgress = showProgress;
    });
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
}
