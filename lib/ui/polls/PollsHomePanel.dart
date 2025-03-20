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
import 'package:neom/ui/polls/PollWidgets.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/FlexUI.dart';
import 'package:rokwire_plugin/service/geo_fence.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:neom/service/Storage.dart';
import 'package:neom/ui/polls/CreatePollPanel.dart';
import 'package:neom/ui/polls/PollBubblePinPanel.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:neom/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:neom/service/Polls.dart' as illinois;


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
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildScaffoldBody() {
    List<Widget> bodyWidgets = [];
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

    bodyWidgets.add(content);
    bodyWidgets.add(_buildCreatePollButton());
    _loadPolls();
    return Column(children: bodyWidgets);
  }

  Widget _buildDescriptionLayout(){
    String description = Localization().getStringEx("panel.polls_home.text.pin_description", "Ask the creator of the poll for its four-digit number.");

    return Container(
      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      color: Styles().colors.fillColorPrimary,
      child: Column(
        children: <Widget>[
          Row(children: <Widget>[
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(description,
                key: _keyBleDescriptionText,
                textAlign: TextAlign.center,
                style: Styles().textStyles.getTextStyle("panel.polls.home.description")
                ),
            ),
            ),
          ],),
          Container(height: 10,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80),
            child: RoundedButton(
              label: Localization().getStringEx("panel.polls_home.button.find_poll.title","Find Poll"),
              textStyle: Styles().textStyles.getTextStyle("widget.colourful_button.title.large.accent"),
              onTap: ()=>_onFindPollTapped(),
              backgroundColor: Styles().colors.fillColorPrimary,
              borderColor: Styles().colors.fillColorSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollsTabbar() {
    return Container(
      color: Styles().colors.background,
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
          Container(
            height: 112,
            width: double.infinity,
            child: Styles().images.getImage("slant-dark", fit: BoxFit.fill, excludeFromSemantics: true) ?? Container()),
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
            style: Styles().textStyles.getTextStyle("widget.title.extra_large.extra_fat")
          ),
          Container(height: 16,),
          Text(description,
            textAlign: TextAlign.center,
            style:Styles().textStyles.getTextStyle("widget.item.light.regular.thin") ),
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
            style: Styles().textStyles.getTextStyle("widget.title.extra_large.extra_fat")
          ),
          Container(height: 16,),
          Text(error,
            textAlign: TextAlign.center,
            style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),)
        ]
    ));
  }

  Widget _buildCreatePollButton() {
    return Container(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), color:Styles().colors.background,child:
      RoundedButton(label:Localization().getStringEx("panel.polls_home.text.create_poll","Create a Poll"),
          textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
          borderColor: Styles().colors.fillColorSecondaryVariant,
          backgroundColor: Styles().colors.fillColorSecondaryVariant,
        onTap:_onCreatePollTapped
    ));
  }

  void _evalBleDescriptionHeight() {
    try {
      final RenderObject? renderBox = _keyBleDescriptionText.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && renderBox.hasSize) {
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
              _myPolls ??= [];
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
              _recentPolls ??= [];
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
              _groupPolls ??= [];
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
            color: selected ? Colors.white : Styles().colors.lightGray,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 1.5, style: BorderStyle.solid),
            borderRadius: _borderRadius,
          ),
          child:Center(child: Text(text!,style: selected ? Styles().textStyles.getTextStyle("widget.tab.selected") : Styles().textStyles.getTextStyle("widget.tab.not_selected") )),
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
