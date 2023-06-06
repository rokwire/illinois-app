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

import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:illinois/ui/polls/PollProgressPainter.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:sprintf/sprintf.dart';
import 'package:illinois/service/Polls.dart' as illinois;

class PollBubblePromptPanel extends StatefulWidget {
  final String? pollId;

  PollBubblePromptPanel({this.pollId});

  @override
  _PollBubblePromptPanelState createState() => _PollBubblePromptPanelState();
}

class _PollBubblePromptPanelState extends State<PollBubblePromptPanel>  {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black.withOpacity(0.3), //Colors.transparent,
        body: SafeArea(
            child: Padding(
                padding: EdgeInsets.only(top: kToolbarHeight),
                child: Padding(
                    padding: EdgeInsets.all(5),
                    child: Stack(children: <Widget>[
                          SingleChildScrollView(child:
                          Column(children: <Widget>[ Container(
                            decoration: BoxDecoration(color: Styles().colors!.fillColorPrimary, borderRadius: BorderRadius.circular(5)),
                            child: Padding(padding: EdgeInsets.all(20), child:  PollContentWidget(pollId: widget.pollId,),),
                          ),],)),
                      Container(alignment: Alignment.topRight, child: _buildCloseButton()),
                    ])
      ))));
  }

  Widget _buildCloseButton() {
    return Semantics(
        label: Localization().getStringEx('panel.poll_prompt.button.close.title', 'Close'),
        button: true,
        excludeSemantics: true,
        child: InkWell(
            onTap : _onClose,
            child: Container(width: 48, height: 48, alignment: Alignment.center, child: Styles().images?.getImage('close-circle-white', excludeFromSemantics: true))));
  }

  void _onClose() {
    Navigator.of(context).pop();
    Polls().closePresenting();
  }
}

class PollContentWidget extends StatefulWidget{
  final String? pollId;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? doneButtonColor;

  PollContentWidget({this.pollId, this.backgroundColor , this.textColor, this.doneButtonColor});

  @override
  State<StatefulWidget> createState() => _PollContentState();
}

class _PollContentState extends State<PollContentWidget> implements NotificationsListener{
  Poll? _poll;
  bool _voteDone = false;
  Map<int, int> _votingOptions = {};

  List<GlobalKey>? _progressKeys;
  double? _progressWidth;

  late Color? _backgroundColor;
  late Color? _textColor;
  late Color? _doneButtonColor;
  @override
  void initState() {
    _backgroundColor = widget.backgroundColor ?? Styles().colors!.fillColorPrimary;
    _textColor = widget.textColor ?? Styles().colors!.white;
    _doneButtonColor = widget.doneButtonColor ?? Styles().colors!.white;

    NotificationService().subscribe(this, [
      Polls.notifyResultsChanged,
      Polls.notifyVoteChanged,
      Polls.notifyStatusChanged,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evalProgressWidths();
    });
    _poll = Polls().getPoll(pollId: widget.pollId);
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
      if (widget.pollId == param) {
        setState(() {
          _poll = Polls().getPoll(pollId: widget.pollId);
        });
        if (_poll!.status == PollStatus.closed) {
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
    if (_voteDone && _poll!.settings!.hideResultsUntilClosed! && (_poll!.status != PollStatus.closed)) {
      return _buildCheckoutContent();
    }
    else {
      return _buildStandardContent();
    }
  }

  List<Widget> _buildStandardContent() {

    String? creator = _poll?.creatorUserName ?? Localization().getStringEx('panel.poll_prompt.text.someone', 'Someone');
    String wantsToKnow = sprintf(Localization().getStringEx('panel.poll_prompt.text.wants_to_know', '%s wants to know'), [creator]);

    String? votesNum;
    int totalVotes = _poll?.results?.totalVotes ?? 0;
    if (1 < totalVotes) {
      votesNum = sprintf(Localization().getStringEx('panel.poll_prompt.text.many_votes', '%s votes'), ['$totalVotes']);
    }
    else if (0 < totalVotes) {
      votesNum = Localization().getStringEx('panel.poll_prompt.text.single_vote', '1 vote');
    }
    else {
      votesNum = Localization().getStringEx('panel.poll_prompt.text.no_votes_yet', 'No votes yet');
    }

    String? pollStatus;
    if (_poll?.status == PollStatus.opened) {
      pollStatus = Localization().getStringEx('panel.poll_prompt.text.poll_open', 'Polls open');
    }
    else if (_poll?.status == PollStatus.closed) {
      pollStatus = Localization().getStringEx('panel.poll_prompt.text.poll_closed', 'Polls closed');
    }

    Widget footerWidget;
    List<Widget> contentOptionsList;
    if (_voteDone) {
      contentOptionsList = _buildResultOptions();
      footerWidget = _buildVoteDoneButton(_onClose);
    }
    else {
      contentOptionsList = _allowRepeatOptions ? _buildCheckboxOptions() : _buildButtonOptions();
      footerWidget = (_allowMultipleOptions || _allowRepeatOptions) ? _buildVoteDoneButton(_onVoteDone) : Container();
    }
    String pollTitle = _poll?.title ?? '';
    String semanticsQuestionText =  "$wantsToKnow,\n$pollTitle";
    String semanticsStatusText = "$pollStatus,$votesNum";
    return <Widget>[
      Row(children: <Widget>[Expanded(child: Container(),)],),
      Semantics(label:semanticsQuestionText,excludeSemantics: true,child:
      Text(wantsToKnow, style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.small")?.copyWith(color: _textColor))),
      Semantics(excludeSemantics: true,child:
      Padding(padding: EdgeInsets.symmetric(vertical: 20),child:
      Text(pollTitle, style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.large.fat")?.copyWith(color: _textColor)),)),
      Padding(padding: EdgeInsets.only(bottom: 20),child:
      Text(_votingRulesDetails, style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.voting.result")?.copyWith(color: _textColor),),),

      Column(children: contentOptionsList,),

      Semantics(label: semanticsStatusText, excludeSemantics: true,child:
      Padding(padding: EdgeInsets.only(top: 20), child: Wrap(children: <Widget>[
        Text(votesNum, style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.small.regular")?.copyWith(color: _textColor),),
        Text('  ', style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.small.regular")?.copyWith(color: _textColor),),
        Text(pollStatus ?? '', style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.small.thin")?.copyWith(color: _textColor)),
      ],),)),

      footerWidget,
    ];
  }

  List<Widget> _buildCheckoutContent() {
    String thanks = Localization().getStringEx('panel.poll_prompt.text.thanks_for_voting', 'Thanks for voting!');
    String willNotify = Localization().getStringEx('panel.poll_prompt.text.will_notify', 'We will notify you once the poll results are in.');
    return <Widget>[
      Row(children: <Widget>[Expanded(child: Container(),)],),
      Padding(padding: EdgeInsets.only(top: 32, bottom:20),child:
      Text(thanks, style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.large.fat")?.copyWith(color: _textColor)),),
      Text(willNotify, style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.regular.thin")?.copyWith(color: _textColor)),
    ];
  }

  List<Widget> _buildButtonOptions() {
    List<Widget> result = [];
    int optionsCount = _poll?.options?.length ?? 0;
    for (int optionIndex = 0; optionIndex < optionsCount; optionIndex++) {
      result.add(Padding(padding: EdgeInsets.only(top: (0 < result.length) ? 10 : 0), child:
      Stack(children: <Widget>[
        RoundedButton(
            label: _poll!.options![optionIndex],
            backgroundColor: (0 < _optionVotes(optionIndex)) ? Styles().colors!.fillColorSecondary : _backgroundColor,
            hint: Localization().getStringEx("panel.poll_prompt.hint.select_option","Double tab to select this option"),
            textStyle: Styles().textStyles?.getTextStyle("widget.button.title.enabled")?.copyWith(color: _textColor),
            borderColor: Styles().colors!.fillColorSecondary,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    List<Widget> result = [];
    _progressKeys = [];
    int totalVotes = _totalOptionVotes;
    int optionsCount = _poll?.options?.length ?? 0;
    for (int optionIndex = 0; optionIndex < optionsCount; optionIndex++) {
      String checkboxIconKey = (0 < _optionVotes(optionIndex)) ? 'check-circle-filled' : 'check-circle-outline-gray';

      String optionString = _poll!.options![optionIndex];
      String votesString;
      int votesCount = _optionVotes(optionIndex);
      double votesPercent = (0 < totalVotes) ? (votesCount.toDouble() / totalVotes.toDouble() * 100.0) : 0.0;
      if (votesCount <= 0) {
        votesString = '';
      }
      else if (votesCount == 1) {
        votesString = Localization().getStringEx('panel.poll_prompt.text.single_vote', '1 vote');
      }
      else {
        votesString = sprintf(Localization().getStringEx('panel.poll_prompt.text.many_votes', '%s votes'), ['$votesCount']);
      }

      GlobalKey progressKey = GlobalKey();
      _progressKeys!.add(progressKey);

      String semanticsText = optionString +",\n "+  votesString +"," + votesPercent.toStringAsFixed(0) +"%";

      result.add(Padding(padding: EdgeInsets.only(top: (0 < result.length) ? 10 : 0), child:
      GestureDetector(
          onTap: () { _onButtonOption(optionIndex); },
          child:  Semantics(label: semanticsText, excludeSemantics: true, child:
          Row(children: <Widget>[
            Padding(padding: EdgeInsets.only(right: 10), child: Stack(children: <Widget>[
              Styles().images?.getImage(checkboxIconKey, excludeFromSemantics: true) ?? Container(),
              Visibility(visible: (_votingOptions[optionIndex] != null),
                child: SizedBox(height: 24, width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(_textColor), )
                ),
              ),
            ],),),
            Expanded(key: progressKey, child:Stack(children: <Widget>[
              CustomPaint(painter: PollProgressPainter(backgroundColor: Styles().colors!.fillColorPrimary, progressColor: Styles().colors!.lightGray!.withOpacity(0.2), progress: votesPercent / 100.0), child: Container(height:30, width: _progressWidth),),
              Container(height: 15 + 16*MediaQuery.of(context).textScaleFactor, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                Padding(padding: EdgeInsets.only(left: 5), child:
                Row(children: <Widget>[
                  Expanded(child:
                  Text(optionString, maxLines: 1, overflow: TextOverflow.ellipsis, style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.regular")?.copyWith(color: _textColor)),),
                ],))
              ],),),
            ],)
            ),
            Padding(padding: EdgeInsets.only(left: 10), child: Text(votesString, style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.medium.accent"),),),
          ],)
          ))));
    }
    return result;
  }

  List<Widget> _buildResultOptions() {
    List<Widget> result = [];
    _progressKeys = [];
    int totalVotes = _poll?.results?.totalVotes ?? 0;
    for (int optionIndex = 0; optionIndex < _poll!.options!.length; optionIndex++) {
      String checkboxImageKey = (0 < _optionVotes(optionIndex)) ? 'check-circle-filled' : 'check-cricle-outline';

      String optionString = _poll!.options![optionIndex];
      String votesString;
      int? votesCount = (_poll!.results != null) ? _poll!.results![optionIndex] : null;
      double votesPercent = ((0 < totalVotes) && (votesCount != null)) ? (votesCount.toDouble() / totalVotes.toDouble() * 100.0) : 0.0;
      if ((votesCount == null) || (votesCount <= 0)) {
        votesString = Localization().getStringEx('panel.poll_prompt.text.no_votes', 'No votes');
      }
      else if (votesCount == 1) {
        votesString = Localization().getStringEx('panel.poll_prompt.text.single_vote', '1 vote');
      }
      else {
        votesString = sprintf(Localization().getStringEx('panel.poll_prompt.text.many_votes', '%s votes'), ['$votesCount']);
      }

      GlobalKey progressKey = GlobalKey();
      _progressKeys!.add(progressKey);

      String semanticsText = optionString +",\n "+  votesString +"," + votesPercent.toStringAsFixed(0) +"%";
      result.add(Padding(padding: EdgeInsets.only(top: (0 < result.length) ? 10 : 0), child:
      Semantics(label: semanticsText, excludeSemantics: true, child:
      Row(children: <Widget>[
        Padding(padding: EdgeInsets.only(right: 10), child: Styles().images?.getImage(checkboxImageKey, excludeFromSemantics: true)),
        Expanded(
            key: progressKey, child:Stack(children: <Widget>[
          CustomPaint(painter: PollProgressPainter(backgroundColor: Styles().colors!.fillColorPrimary, progressColor: Styles().colors!.lightGray!.withOpacity(0.2), progress: votesPercent / 100.0), child: Container(height:30, width: _progressWidth),),
          Container(/*height: 30,*/ child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Padding(padding: EdgeInsets.only(left: 5), child:
            Text(_poll!.options![optionIndex],  maxLines: 5, overflow:TextOverflow.ellipsis, style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.regular")?.copyWith(color: _textColor)),),
          ],),),
        ],)
        ),
        Expanded(child:
        Padding(padding: EdgeInsets.only(left: 10), child: Text('$votesString (${votesPercent.toStringAsFixed(0)}%)', textAlign:TextAlign.right, style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.medium.accent")),),
        )
      ],))
      ));
    }
    return result;
  }

  Widget _buildVoteDoneButton(void Function() handler) {
    return Padding(padding: EdgeInsets.only(top: 20, left: 30, right: 30), child: RoundedButton(
        label: Localization().getStringEx('panel.poll_prompt.button.done_voting.title', 'Done Voting'),
        textStyle: Styles().textStyles?.getTextStyle("widget.button.title.enabled")?.copyWith(color: _textColor),
        backgroundColor: _backgroundColor,
        borderColor: _doneButtonColor,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        onTap: (){
          AppSemantics.announceMessage(context, Localization().getStringEx('panel.poll_prompt.button.done_voting.status.success', 'Poll voting ended successfully'));
          handler();
        })
    );
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

  int _optionVotes(int optionIndex) {
    int? userVotes = (_poll!.userVote != null) ? _poll!.userVote![optionIndex] : null;
    return (userVotes ?? 0) + (_votingOptions[optionIndex] ?? 0);
  }

  int get _totalOptionVotes {
    int total = (_poll!.userVote?.totalVotes ?? 0);
    _votingOptions.forEach((int optionIndex, int optionVotes) {
      total += optionVotes;
    });
    return total;
  }

  int get _totalOptions {
    return _poll?.options?.length ?? 0;
  }

  int get _totalVotedOptions {
    int totalOptions = 0;
    for (int optionIndex = 0; optionIndex < _totalOptions; optionIndex++) {
      int? userVotes = (_poll!.userVote != null) ? _poll!.userVote![optionIndex] : null;
      if ((userVotes != null) || (_votingOptions[optionIndex] != null)) {
        totalOptions++;
      }
    }
    return totalOptions;
  }

  bool get _allowMultipleOptions {
    return _poll?.settings?.allowMultipleOptions ?? false;
  }

  bool get _allowRepeatOptions {
    return _poll?.settings?.allowRepeatOptions ?? false;
  }

  bool get _hideResultsUntilClosed {
    return _poll?.settings?.hideResultsUntilClosed ?? false;
  }

  void _onButtonOption(int optionIndex) {
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
    Polls().vote(widget.pollId, PollVote(votes: { optionIndex : 1 })).then((_) {
      if ((!_allowMultipleOptions && !_allowRepeatOptions) ||
          (_allowMultipleOptions && !_allowRepeatOptions && (_totalVotedOptions == _totalOptions))) {
        setState(() {
          _voteDone = true;
        });
      }
    }).catchError((e){
      AppAlert.showDialogResult(context, illinois.Polls.localizedErrorString(e));
    }).whenComplete((){
      AppSemantics.announceMessage(context,  Localization().getStringEx("panel.poll_prompt.vote.status.announce.success", "Successfully Voted"));
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
        if(!_allowMultipleOptions && !_allowRepeatOptions){
          //We only want to see the 2nd panel for multi voting. If a Poll is a single vote poll then when a user votes close the panel.
          _onClose();
        }
      });
    });
  }

  void _onVoteDone() {
    if (_votingOptions.length == 0) {
      setState(() {
        _voteDone = true;
      });
    }
  }

  void _onClose() {
    if (_votingOptions.length == 0) {
      Navigator.of(context).pop();
      Polls().closePresenting();
    }
  }

  String get _votingRulesDetails {
    String details = '';
    if (_allowMultipleOptions) {
      if (details.isNotEmpty) {
        details += '\n';
      }
      details += '• ' + Localization().getStringEx("panel.poll_prompt.text.rule.detail.multy_choice", "You can choose more than one answer.");
    }
    if (_allowRepeatOptions) {
      if (details.isNotEmpty) {
        details += '\n';
      }
      details += '• ' + Localization().getStringEx("panel.poll_prompt.text.rule.detail.repeat_vote", "You can vote as many times as you want before the poll closes.");
    }
    if (_hideResultsUntilClosed) {
      if (details.isNotEmpty) {
        details += '\n';
      }
      details += '• ' + Localization().getStringEx("panel.poll_prompt.text.rule.detail.hide_result", "Results will not be shown until the poll ends.");
    }
    return details;
  }
}
