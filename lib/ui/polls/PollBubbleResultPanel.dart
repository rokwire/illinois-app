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
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:illinois/ui/polls/PollProgressPainter.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:sprintf/sprintf.dart';

class PollBubbleResultPanel extends StatefulWidget {
  final String? pollId;

  PollBubbleResultPanel({this.pollId});

  @override
  _PollBubbleResultPanelState createState() => _PollBubbleResultPanelState();
}

class _PollBubbleResultPanelState extends State<PollBubbleResultPanel> implements NotificationsListener {
  bool _resultsVisible = false;

  List<GlobalKey>? _progressKeys;
  //double _progressWidth;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Polls.notifyVoteChanged,
      Polls.notifyResultsChanged,
      Polls.notifyStatusChanged,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      if (widget.pollId == param) {
        setState(() {
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Poll? poll = Polls().getPoll(pollId: widget.pollId);
    return Scaffold(
        backgroundColor: Colors.black.withOpacity(0.3), //Colors.transparent,
        body: SafeArea(
            child: Padding(
                padding: EdgeInsets.only(top: kToolbarHeight),
                child: Padding(
                    padding: EdgeInsets.all(5),
                    child: Stack(children: <Widget>[
                          SingleChildScrollView(child:Column(children: <Widget>[ Container(
                            decoration: BoxDecoration(color: Styles().colors!.fillColorPrimary, borderRadius: BorderRadius.circular(5)),
                            child: Padding(padding: EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildContent(poll),),),
                          ),],)),
                      Container(alignment: Alignment.topRight, child: _buildCloseButton()),
                    ])
      ))));
  }

  List<Widget> _buildContent(Poll? poll) {
    return _resultsVisible ? _buildResultsContent(poll!) : _buildReportContent(poll);
  }

  List<Widget> _buildResultsContent(Poll poll) {
    String? creator = poll.creatorUserName ?? Localization().getStringEx('panel.poll_prompt.text.someone', 'Someone');
    String wantsToKnow = sprintf(Localization().getStringEx('panel.poll_prompt.text.wants_to_know', '%s wants to know'), [creator]);

    String votesNum;
    int totalVotes = poll.results?.totalVotes ?? 0;
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
    if (poll.status == PollStatus.opened) {
      pollStatus = Localization().getStringEx('panel.poll_prompt.text.poll_open', 'Polls open');
    }
    else if (poll.status == PollStatus.closed) {
      pollStatus = Localization().getStringEx('panel.poll_prompt.text.poll_closed', 'Polls closed');
    }

    String pollTitle = poll.title ?? '';
    String semanticsQuestionText = "$wantsToKnow\n$pollTitle";
    String semanticsStatusText = "$pollStatus,$votesNum";

    return <Widget>[
      Row(children: <Widget>[Expanded(child: Container(),)],),
      Semantics(label:semanticsQuestionText,excludeSemantics: true,child:
        Text(wantsToKnow, style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.small"),)),
      Semantics(excludeSemantics: true,child:
        Padding(padding: EdgeInsets.symmetric(vertical: 20),child:
          Text(poll.title ?? '', style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.large.fat"),),)),

      Column(children: _buildResultOptions(poll),),
      Semantics(label: semanticsStatusText, excludeSemantics: true,child:
        Padding(padding: EdgeInsets.only(top: 20), child: Wrap(children: <Widget>[
          Text(votesNum, style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.small.regular")),
          Text('  ', style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.small.regular")),
          Text(pollStatus ?? '', style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.small.thin")),
      ],),)),

      _buildResultsDoneButton(),
    ];
  }

  List<Widget> _buildResultOptions(Poll poll) {
    List<Widget> result = [];
    _progressKeys = [];
    int totalVotes = poll.results?.totalVotes ?? 0;
    for (int optionIndex = 0; optionIndex < poll.options!.length; optionIndex++) {
      String checkboxIconKey = 'check-circle-outline-gray'; // (_vote[optionIndex] != null) ? 'images/checkbox-selected.png' : 'images/checkbox-unselected.png';

      String optionString = poll.options![optionIndex];
      String votesString;
      int? votesCount = (poll.results != null) ? poll.results![optionIndex] : null;
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

      String semanticsText = optionString +"\n "+  votesString +"," + votesPercent.toStringAsFixed(0) +"%";

      result.add(Padding(padding: EdgeInsets.only(top: (0 < result.length) ? 10 : 0), child:
        Semantics(label: semanticsText, excludeSemantics: true, child:
          Row(children: <Widget>[
            Padding(padding: EdgeInsets.only(right: 10), child: Styles().images?.getImage(checkboxIconKey, excludeFromSemantics: true)),
            Expanded(key: progressKey, child:Stack(children: <Widget>[
              CustomPaint(painter: PollProgressPainter(backgroundColor: Styles().colors!.fillColorPrimary, progressColor: Styles().colors!.lightGray!.withOpacity(0.2), progress: votesPercent / 100.0), child: Container(/*height:30, width: _progressWidth*/),),
              Container(/*height: 30,*/ child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                Padding(padding: EdgeInsets.only(left: 5), child:
                  Text(poll.options![optionIndex], style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.regular")),),
              ],),),
              ],)
            ),
            Expanded(child:
              Padding(padding: EdgeInsets.only(left: 10), child: Text('$votesString (${votesPercent.toStringAsFixed(0)}%)', style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.medium.accent")),),
            )
            ],))
      ));
    }
    return result;
  }

  Widget _buildResultsDoneButton() {
    return Padding(padding: EdgeInsets.only(top: 20, left: 30, right: 30), child: RoundedButton(
        label: 'Done',
        textStyle: Styles().textStyles?.getTextStyle("widget.colourful_button.title.accent"),
        backgroundColor: Styles().colors!.fillColorPrimary,
        borderColor: Styles().colors!.fillColorSecondary,
        padding: EdgeInsets.symmetric(horizontal: 24),
        onTap: () { _onResultsDone(); })       
      );
  } 

  List<Widget> _buildReportContent(Poll? poll) {
    String resultsIn = Localization().getStringEx('panel.poll_prompt.text.results_are_in', 'Results are in!');
    String pollClosed = Localization().getStringEx('panel.poll_prompt.text.voted_poll_closed', 'A poll you voted in has closed.');
    return <Widget>[
      Row(children: <Widget>[Expanded(child: Container(),)],),
      Padding(padding: EdgeInsets.only(top: 32, bottom:20),child:
        Text(resultsIn, style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.large.fat")),),
      Text(pollClosed, style: Styles().textStyles?.getTextStyle("panel.poll.bubble.prompt.detail.regular.thin")),
      _buildViewResultsButton(),
    ];
  }

  Widget _buildViewResultsButton() {
    return Padding(padding: EdgeInsets.only(top: 20, left: 50, right: 50), child:
      RoundedButton(
        label: Localization().getStringEx('panel.poll_prompt.button.view_poll_results.title', 'View poll results'),
        textStyle: Styles().textStyles?.getTextStyle("widget.colourful_button.title.accent"),
        backgroundColor: Styles().colors!.fillColorPrimary,
        borderColor: Styles().colors!.fillColorSecondary,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        onTap: () { _onViewResults(); }
      ),
    );
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
          //_progressWidth = progressWidth;
        });
      }
    }
  }

  void _onViewResults() {
    setState(() {
      _resultsVisible = true;
    });
  }

  void _onResultsDone() {
    _onClose();
  }

  void _onClose() {
    Navigator.of(context).pop();
    Polls().closePresenting();
  }
}
