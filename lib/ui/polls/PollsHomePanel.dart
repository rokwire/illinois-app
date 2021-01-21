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
import 'package:illinois/model/Poll.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/GeoFence.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Polls.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/polls/PollProgressPainter.dart';
import 'package:illinois/ui/polls/CreatePollPanel.dart';
import 'package:illinois/ui/polls/PollBubblePinPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';
import 'package:sprintf/sprintf.dart';


class PollsHomePanel extends StatefulWidget {

  _PollsHomePanelState createState() => _PollsHomePanelState();
}

class _PollsHomePanelState extends State<PollsHomePanel> implements NotificationsListener{

  _PollType _selectedPollType;

  List<Poll> _myPolls;
  String _myPollsCursor;
  String _myPollsError;
  bool _myPollsLoading = false;
  
  List<Poll> _recentPolls;
  List<Poll> _recentLocalPolls;
  String _recentPollsCursor;
  String _recentPollsError;
  bool _recentPollsLoading = false;

  bool _loggingIn = false;
  
  final GlobalKey _keyBleDescriptionText = GlobalKey();
  double _bleDescriptionTextHeight = 0;

  ScrollController _scrollController;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Polls.notifyCreated,
      Polls.notifyStatusChanged,
      Polls.notifyVoteChanged,
      Polls.notifyResultsChanged,
      GeoFence.notifyCurrentRegionsUpdated,
      FlexUI.notifyChanged,
      Auth.notifyStarted,
      Auth.notifyInfoChanged,
    ]);

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    
    _recentLocalPolls = Polls().localRecentPolls();
    _selectPollType(_couldCreatePoll ? _PollType.values[Storage().selectedPollType ?? 0] : _PollType.recentPolls);

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
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(
        Localization().getStringEx("panel.polls_home.text.header.title","Quick Polls"),
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0),
        ),
      ),
      body: _buildScaffoldBody(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildScaffoldBody() {
    return Column(children:[
      Expanded(child:
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
      ),
      _buildCreatePollButton()
    ]);
  }

  Widget _buildDescriptionLayout(){
    String description = Localization().getStringEx("panel.polls_home.text.ble_enabled_description", "If you are close to the poll creator, the poll should automatically appear, otherwise ask the creator for its 4 Digit #.");

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
                style: TextStyle(
                    color: Styles().colors.white,
                    fontFamily: Styles().fontFamilies.regular,
                    fontSize: 16
                  ),
                ),
            ),
            ),
          ],),
          Container(height: 10,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80),
            child: ScalableRoundedButton(
              label: Localization().getStringEx("panel.polls_home.button.find_poll.title","Find Poll"),
              onTap: ()=>_onFindPollTapped(),
              backgroundColor: Styles().colors.fillColorPrimary,
              textColor: Styles().colors.white,
              borderColor: Styles().colors.fillColorSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollsTabbar() {
    return _couldCreatePoll ?
      Container(
        color: Styles().colors.backgroundVariant,
        padding: EdgeInsets.only(left: 16, top: 16, right: 16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _PollsHomePanelFilterTab(
                text: Localization().getStringEx("panel.polls_home.tab.title.recent_polls","Recent Polls"),
                left: true,
                selected: (_selectedPollType == _PollType.recentPolls),
                onTap: _onRecentPollsTapped,
              )
            ),
            Expanded(
              child: _PollsHomePanelFilterTab(
                text: Localization().getStringEx("panel.polls_home.tab.title.my_polls","My Polls"),
                left: false,
                selected: (_selectedPollType == _PollType.myPolls),
                onTap: _onMyPollsTapped,
              )
            )
          ],
        ),
      ) :
      Container();
  }

  Widget _buildPollsContent(){

    List<Poll> polls;
    List<Poll> localPolls;
    bool pollsLoading;
    String pollsError;
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
    int pollsLenght = (polls?.length ?? 0) + (localPolls?.length ?? 0);

    Widget pollsContent;
    if ((_selectedPollType == _PollType.myPolls) && !_canCreatePoll) {
      pollsContent = _buildLoginContent();
    }
    else if ((0 < pollsLenght) || pollsLoading) {
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
            Visibility(visible: _couldCreatePoll, child:
              Column(
                children: <Widget>[
                  Container(
                    height: 88,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage("images/slant-down-right-grey.png" ),
                            fit: BoxFit.fill)),
                  )
                ],
              ),
            ),
            Padding( padding: EdgeInsets.symmetric(horizontal: 16),
                child: pollsContent,
            )],);

  }

  List<Poll> get _polls {
    if (_selectedPollType == _PollType.myPolls) {
      return _myPolls;
    }
    else if (_selectedPollType == _PollType.recentPolls) {
      return _recentPolls;
    }
    else {
      return null;
    }
  }

  Widget _buildPolls(List<Poll> polls1, List<Poll> polls2, bool pollsLoading) {

    List<Widget> content = List();

    int pols1Len = (polls1 != null) ? polls1.length : 0;
    int pols2Len = (polls2 != null) ? polls2.length : 0;

    if (0 < (pols1Len + pols2Len)) {
      content.add(_constructListSeparator());
    }

    if (0 < pols1Len) {
      polls1.forEach((poll){
        content.add(_PollCard(poll: poll));
        content.add(_constructListSeparator());
      });
    }

    if (0 < pols2Len) {
      polls2.forEach((poll){
        content.add(_PollCard(poll: poll));
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
    else {
      message = description = '';
    }

    return Container(padding: EdgeInsets.symmetric(horizontal: 24),child:
      Column(
        children:[
          Container(height: 100,),
          Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Styles().colors.fillColorPrimary,
                fontFamily: Styles().fontFamilies.extraBold,
                fontSize: 24
            ),
          ),
          Container(height: 16,),
          Text(description,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Styles().colors.textBackground,
                fontFamily: Styles().fontFamilies.regular,
                fontSize: 16,
            ),),
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
            style: TextStyle(
                color: Styles().colors.fillColorPrimary,
                fontFamily: Styles().fontFamilies.extraBold,
                fontSize: 24
            ),
          ),
          Container(height: 16,),
          Text(error,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Styles().colors.textBackground,
                fontFamily: Styles().fontFamilies.regular,
                fontSize: 16,
            ),),
        ]
    ));
  }

  Widget _buildLoginContent(){

    return Container(padding: EdgeInsets.symmetric(horizontal: 24), child:
      Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children:[
          Container(height: 100,),
          Text(Localization().getStringEx("panel.polls_home.text.login_description", 'You need to be logged in to create and share polls with people near you.'),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Styles().colors.fillColorPrimary,
                fontFamily: Styles().fontFamilies.semiBold,
                fontSize: 24,
            ),),
      ]),
    );
  }

  Widget _buildCreatePollButton() {
    if (_canCreatePoll) {
      return Container(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), color:Styles().colors.white,child:
        ScalableRoundedButton(label:Localization().getStringEx("panel.polls_home.text.create_poll","Create a poll"),
            textColor: Styles().colors.fillColorPrimary,
            borderColor: Styles().colors.fillColorSecondary,
            backgroundColor: Styles().colors.white,
          onTap:_onCreatePollTapped
      ));
    }
    else if (_couldCreatePoll) {
      return Container(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), color:Styles().colors.white,child:
        Stack(children: <Widget>[
          RoundedButton(label:Localization().getStringEx("panel.polls_home.text.login","Login"),
            textColor: Styles().colors.fillColorPrimary,
            borderColor: Styles().colors.fillColorSecondary,
            backgroundColor: Styles().colors.white,
            height: 48,
            onTap:_onLoginTapped
          ),
          Visibility(visible: _loggingIn,
            child: Container(
              height: 48,
              child: Align(alignment: Alignment.center,
                child: SizedBox(height: 24, width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorPrimary), )
                ),
              ),
            ),
          ),
        ],),
        );
    }
    else {
      return Container();
    }
  }

  void _evalBleDescriptionHeight() {
    try {
      final RenderObject renderBox = _keyBleDescriptionText?.currentContext?.findRenderObject();
      if (renderBox is RenderBox) {
        _bleDescriptionTextHeight = renderBox.size.height;
      }
    } on Exception catch (e) {
      print(e.toString());
    }
  }

  void _onFindPollTapped() {
    Analytics().logPage(name:"Find Poll");
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

  void _onLoginTapped() {
    if (!_loggingIn) {
      Auth().authenticateWithShibboleth();
    }
  }

  void _onRecentPollsTapped(){
    _selectPollType(_PollType.recentPolls);
  }

  void _onMyPollsTapped(){
    _selectPollType(_PollType.myPolls);
  }

  void _selectPollType(_PollType pollType) {
    if (_selectedPollType != pollType) {
      setState(() {
        _selectedPollType = pollType;
        Storage().selectedPollType = _PollType.values.indexOf(_selectedPollType);
        if (_polls == null) {
          _loadPolls();
        }
      });
    }
  }

  bool get _couldCreatePoll {
    return FlexUI().hasFeature('create_poll');
  }

  bool get _canCreatePoll {
    return _couldCreatePoll && Auth().isLoggedIn;
  }

  void _loadPolls() {

    if (_selectedPollType == _PollType.myPolls) {
      _loadMyPolls();
    }
    else if (_selectedPollType == _PollType.recentPolls) {
      _loadRecentPolls();
    }
  }

  void _loadMyPolls() {
    if (((_myPolls == null) || (_myPollsCursor != null)) && !_myPollsLoading) {
      setState(() {
        _myPollsLoading = true;
      });
      Polls().getMyPolls(cursor: _myPollsCursor).then((PollsChunk result){
        setState((){
          if (result != null) {
            if (_myPolls == null) {
              _myPolls = [];
            }
            _myPolls.addAll(result.polls);
            _myPollsCursor = (0 < result.polls.length) ? result.cursor : null;
            _myPollsError = null;
          }
        });
      }).catchError((e){
        _myPollsError = e?.toString() ?? "Unknown error occured";
      }).whenComplete((){
        setState((){
          _myPollsLoading = false;
        });
      });
    }
  }

  void _loadRecentPolls() {
    if (((_recentPolls == null) || (_recentPollsCursor != null)) && !_recentPollsLoading) {
      setState(() {
        _recentPollsLoading = true;
      });
      Polls().getRecentPolls(cursor: _recentPollsCursor).then((PollsChunk result){
        setState((){
          if (result != null) {
            if (_recentPolls == null) {
              _recentPolls = [];
            }
            _stripRecentLocalPolls(result.polls);
            _recentPolls.addAll(result.polls);
            _recentPollsCursor = (0 < result.polls.length) ? result.cursor : null;
            _recentPollsError = null;
          }
        });
      }).catchError((e){
        _recentPollsError = e?.toString() ?? "Unknown error occured";
      }).whenComplete((){
        setState((){
          _recentPollsLoading = false;
        });
      });
    }
  }

  void _stripRecentLocalPolls(List<Poll>recentPolls) {
    if (recentPolls != null) {
      for (Poll poll in recentPolls) {
        for (int index = _recentLocalPolls.length - 1; 0 <= index; index--) {
          Poll localRecentPoll = _recentLocalPolls[index];
          if (localRecentPoll.pollId == poll.pollId) {
            _recentLocalPolls.removeAt(index);
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

  void _updatePollInList(Poll poll, List<Poll>polls) {
    if ((poll != null) && (polls != null)) {
      for (int index = 0; index < polls.length; index++) {
        if (polls[index].pollId == poll.pollId) {
          polls[index] = poll;
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


  void _onPollCreated(String pollId) {
    _resetMyPolls();
    setState(() {
      _updateRecentLocalPolls();  
    });
  }

  void _onPollUpdated(String pollId) {
    Poll poll = Polls().getPoll(pollId: pollId);
    if (poll != null) {
      setState(() {
        _updatePoll(poll);
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent) {
      _loadPolls();
    }
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == Polls.notifyCreated) {
      _onPollCreated(param);
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
      setState(() { });
    }
    else if (name == FlexUI.notifyChanged) {
      setState(() { });
    }
    else if (name == Auth.notifyStarted) {
      setState(() {
        _loggingIn = true;
      });
    }
    else if (name == Auth.notifyInfoChanged) {
      setState(() {
        _loggingIn = false;
      });
    }
  }
}

class _PollsHomePanelFilterTab extends StatelessWidget {
  final String text;
  final String hint;
  final bool left;
  final bool selected;
  final GestureTapCallback onTap;

  _PollsHomePanelFilterTab({Key key, this.text, this.hint = '', this.left = false, this.selected = false, this.onTap}) : super(key: key);

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
            borderRadius: left ? BorderRadius.horizontal(left: Radius.circular(100.0)) : BorderRadius.horizontal(right: Radius.circular(100.0)),
          ),
          child:Center(child: Text(text,style:TextStyle(
              fontFamily: selected ? Styles().fontFamilies.extraBold : Styles().fontFamilies.medium,
              fontSize: 16,
              color: Styles().colors.fillColorPrimary))),
        ),
        ));
  }
}


enum _PollType { myPolls, recentPolls}

class _PollCard extends StatefulWidget{
  final Poll poll;

  const _PollCard({Key key, this.poll}) : super(key: key);
  _PollCardState createState() => _PollCardState();
}

class _PollCardState extends State<_PollCard>{
  List<GlobalKey> _progressKeys;
  double _progressWidth;

  bool _showStartPollProgress = false;
  bool _showEndPollProgress = false;

  @override
  void initState() {
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
    Poll poll = widget.poll;
    int totalVotes = (poll.results?.totalVotes ?? 0);
    String votesNum;
    if (1 < totalVotes) {
      votesNum = sprintf(Localization().getStringEx('panel.poll_prompt.text.many_votes', '%s votes'), ['$totalVotes']);
    }
    else if (0 < totalVotes) {
      votesNum = Localization().getStringEx('panel.poll_prompt.text.single_vote', '1 vote');
    }
    else {
      votesNum = Localization().getStringEx('panel.poll_prompt.text.no_votes_yet', 'No votes yet');
    }

    List<Widget> footerWidgets = [];

    String pollStatus;
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

    String pin = sprintf(Localization().getStringEx('panel.polls_home.card.text.pin', 'Pin: %s'), [
      sprintf('%04i', [poll.pinCode ?? 0])
    ]);

    Widget cardBody = ((poll.status == PollStatus.opened) && (poll.settings?.hideResultsUntilClosed ?? false)) ?
      Text(Localization().getStringEx("panel.poll_prompt.text.rule.detail.hide_result", "Results will not be shown until the poll ends."), style: TextStyle(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: 15, fontWeight: FontWeight.w500),) :
      Column(children: _buildCheckboxOptions(),);

    return
      Column(children: <Widget>[ Container(padding: EdgeInsets.symmetric(),
        decoration: BoxDecoration(color: Styles().colors.white, borderRadius: BorderRadius.circular(5)),
        child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:
        <Widget>[
          Semantics(excludeSemantics: true, label: pollStatus+","+votesNum,
          child: Padding(padding: EdgeInsets.only(bottom: 12), child: Row(children: <Widget>[
            Text(votesNum, style: TextStyle(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.bold, fontSize: 12,),),
            Text('  ', style: TextStyle(color: Colors.white, fontFamily: Styles().fontFamilies.regular, fontSize: 12,),),
            Expanded(child:
            Text(pollStatus ?? '', style: TextStyle(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: 12, ),),
            ),
            Expanded(child:
              Text(pin, style: TextStyle(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: 12, ),),
            )
          ],),),
          ),
          Row(children: <Widget>[Expanded(child: Container(),)],),
          Padding(padding: EdgeInsets.symmetric(vertical: 0),child:
          Text(poll.title, style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.extraBold, fontSize: 20, height: 1.2 ),),),
          Container(height:12),
          cardBody,
          Container(height:25),
          Column(children: footerWidgets,),
        ]
          ,),),
      ),],);
  }

  List<Widget> _buildCheckboxOptions() {
    bool isClosed = widget.poll.status == PollStatus.closed;

    List<Widget> result = [];
    _progressKeys = [];
    int maxValueIndex=-1;
    if(isClosed  && ((widget.poll.results?.totalVotes ?? 0) > 0)){
      maxValueIndex = 0;
      for (int optionIndex = 0; optionIndex<widget.poll.options.length ; optionIndex++) {
        int optionVotes =  widget.poll.results[optionIndex];
        if(optionVotes!=null &&  optionVotes > widget.poll.results[maxValueIndex])
          maxValueIndex = optionIndex;
      }
    }

    int totalVotes = (widget.poll.results?.totalVotes ?? 0);
    for (int optionIndex = 0; optionIndex<widget.poll.options.length ; optionIndex++) {
      bool useCustomColor = isClosed && maxValueIndex == optionIndex;
      String option = widget.poll.options[optionIndex];
      bool didVote = ((widget.poll.userVote != null) && (0 < (widget.poll.userVote[optionIndex] ?? 0)));
      String checkboxImage = 'images/checkbox-unselected.png'; // 'images/checkbox-selected.png'

      String votesString;
      int votesCount = (widget.poll.results != null) ? widget.poll.results[optionIndex] : null;
      double votesPercent = ((0 < totalVotes) && (votesCount != null)) ? (votesCount.toDouble() / totalVotes.toDouble() * 100.0) : 0.0;
      if ((votesCount == null) || (votesCount == 0)) {
        votesString = '';
      }
      else if (votesCount == 1) {
        votesString = Localization().getStringEx("panel.polls_home.card.text.one_vote","1 vote");
      }
      else {
        String votes = Localization().getStringEx("panel.polls_home.card.text.votes","votes");
        votesString = '$votesCount $votes';
      }
      Color votesColor = Styles().colors.textBackground;

      GlobalKey progressKey = GlobalKey();
      _progressKeys.add(progressKey);

      String semanticsText = option +"\n "+  votesString +"," + votesPercent.toStringAsFixed(0) +"%";

      result.add(Padding(padding: EdgeInsets.only(top: (0 < result.length) ? 8 : 0), child:
      GestureDetector(
          child:
          Semantics(label: semanticsText, excludeSemantics: true, child:
          Row(children: <Widget>[
            Padding(padding: EdgeInsets.only(right: 10), child: Image.asset(checkboxImage,),),
            Expanded(
              flex: 5,
              key: progressKey, child:
                Stack(children: <Widget>[
              CustomPaint(painter: PollProgressPainter(backgroundColor: Styles().colors.white, progressColor: useCustomColor ?Styles().colors.fillColorPrimary:Styles().colors.lightGray, progress: votesPercent / 100.0), child: Container(height:30, width: _progressWidth),),
              Container(/*height: 15+ 16*MediaQuery.of(context).textScaleFactor,*/ child:
                Padding(padding: EdgeInsets.only(left: 5), child:
                    Row(children: <Widget>[
                      Expanded( child:
                      Padding( padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Text(option, style: TextStyle(color: useCustomColor?Styles().colors.white:Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: 16, fontWeight: FontWeight.w500,height: 1.25),),)),
                        Visibility( visible: didVote,
                        child:Padding(padding: EdgeInsets.only(right: 10), child: Image.asset('images/checkbox-small.png',),)
                      ),
                    ],),)
              ),
            ],)
            ),
            Expanded(
              flex: 5,
              child: Padding(padding: EdgeInsets.only(left: 10), child: Text('$votesString (${votesPercent.toStringAsFixed(0)}%)', textAlign: TextAlign.right,style: TextStyle(color: votesColor, fontFamily: Styles().fontFamilies.regular, fontSize: 14, fontWeight: FontWeight.w500,height: 1.29),),),
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

  Widget _createButton(String title, Function onTap, {bool enabled=true, bool loading = false}){
    return Container( padding: EdgeInsets.symmetric(horizontal: 54,),
          child: Semantics(label: title, button: true, excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            child: Stack(children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(vertical: 5,horizontal: 16),
                decoration: BoxDecoration(
                  color: Styles().colors.white,
                  border: Border.all(
                      color: enabled? Styles().colors.fillColorSecondary :Styles().colors.surfaceAccent,
                      width: 2.0),
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: Center(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: Styles().fontFamilies.bold,
                            fontSize: 16,
                            height: 1.38,
                            color: Styles().colors.fillColorPrimary,
                          ),
                        ),
                      ),
                ),
                Visibility(visible: loading,
                  child: Container(padding: EdgeInsets.symmetric(vertical: 5),
                    child: Align(alignment: Alignment.center,
                      child: SizedBox(height: 24, width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorPrimary), )
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
      Polls().open(widget.poll.pollId).then((result) => _setStartButtonProgress(false)).catchError((e){
        _setStartButtonProgress(false);
        AppAlert.showDialogResult(context, e?.toString() ?? "Unknown error occured");
      });
  }

  void _onEndPollTapped(){
    _setEndButtonProgress(true);
      Polls().close(widget.poll.pollId).then((result) => _setEndButtonProgress(false)).catchError((e){
        _setEndButtonProgress(false);
        AppAlert.showDialogResult(context, e?.toString() ?? "Unknown error occured");
      });

  }

  void _onVoteTapped(){
    Polls().presentPollVote(widget.poll);
  }

  void _evalProgressWidths() {
    if (_progressKeys != null) {
      double progressWidth = -1.0;
      for (GlobalKey progressKey in _progressKeys) {
        final RenderObject progressRender = progressKey?.currentContext?.findRenderObject();
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
    return ((widget.poll.status == PollStatus.opened) &&
        (((widget.poll.userVote?.totalVotes ?? 0) == 0) ||
          widget.poll.settings.allowMultipleOptions ||
          widget.poll.settings.allowRepeatOptions
        ) &&
        (!widget.poll.isGeoFenced || GeoFence().currentRegionIds.contains(widget.poll.regionId))
    );
  }

}
