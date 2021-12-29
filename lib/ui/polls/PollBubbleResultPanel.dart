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
import 'package:illinois/model/Poll.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Polls.dart';
import 'package:illinois/ui/polls/PollProgressPainter.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
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
    String wantsToKnow = sprintf(Localization().getStringEx('panel.poll_prompt.text.wants_to_know', '%s wants to know')!, [creator]);

    String? votesNum;
    int totalVotes = poll.results?.totalVotes ?? 0;
    if (1 < totalVotes) {
      votesNum = sprintf(Localization().getStringEx('panel.poll_prompt.text.many_votes', '%s votes')!, ['$totalVotes']);
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
        Text(wantsToKnow, style: TextStyle(color: Colors.white, fontFamily: Styles().fontFamilies!.bold, fontSize: 12),)),
      Semantics(excludeSemantics: true,child:
        Padding(padding: EdgeInsets.symmetric(vertical: 20),child:
          Text(poll.title ?? '', style: TextStyle(color: Colors.white, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 24),),)),

      Column(children: _buildResultOptions(poll),),
      Semantics(label: semanticsStatusText, excludeSemantics: true,child:
        Padding(padding: EdgeInsets.only(top: 20), child: Wrap(children: <Widget>[
          Text(votesNum ?? '', style: TextStyle(color: Colors.white, fontFamily: Styles().fontFamilies!.bold, fontSize: 12, ),),
          Text('  ', style: TextStyle(color: Colors.white, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 12, ),),
          Text(pollStatus ?? '', style: TextStyle(color: Colors.white, fontFamily: Styles().fontFamilies!.medium, fontSize: 12, ),),
      ],),)),

      _buildResultsDoneButton(),
    ];
  }

  List<Widget> _buildResultOptions(Poll poll) {
    List<Widget> result = [];
    _progressKeys = [];
    int totalVotes = poll.results?.totalVotes ?? 0;
    for (int optionIndex = 0; optionIndex < poll.options!.length; optionIndex++) {
      String checkboxImage = 'images/checkbox-unselected.png'; // (_vote[optionIndex] != null) ? 'images/checkbox-selected.png' : 'images/checkbox-unselected.png';

      String optionString = poll.options![optionIndex];
      String? votesString;
      int? votesCount = (poll.results != null) ? poll.results![optionIndex] : null;
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
            Expanded(key: progressKey, child:Stack(children: <Widget>[
              CustomPaint(painter: PollProgressPainter(backgroundColor: Styles().colors!.fillColorPrimary, progressColor: Styles().colors!.lightGray!.withOpacity(0.2), progress: votesPercent / 100.0), child: Container(/*height:30, width: _progressWidth*/),),
              Container(/*height: 30,*/ child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                Padding(padding: EdgeInsets.only(left: 5), child:
                  Text(poll.options![optionIndex], style: TextStyle(color: Colors.white, fontFamily: Styles().fontFamilies!.regular, fontSize: 16, fontWeight: FontWeight.w500),),),
              ],),),
              ],)
            ),
            Expanded(child:
              Padding(padding: EdgeInsets.only(left: 10), child: Text('$votesString (${votesPercent.toStringAsFixed(0)}%)', style: TextStyle(color: Styles().colors!.surfaceAccent, fontFamily: Styles().fontFamilies!.regular, fontSize: 14, fontWeight: FontWeight.w500),),),
            )
            ],))
      ));
    }
    return result;
  }

  Widget _buildResultsDoneButton() {
    return Padding(padding: EdgeInsets.only(top: 20, left: 30, right: 30), child: ScalableRoundedButton(
        label: 'Done',
        backgroundColor: Styles().colors!.fillColorPrimary,
//        height: 42,
        fontSize: 16.0,
        textColor: Colors.white,
        borderColor: Styles().colors!.fillColorSecondary,
        padding: EdgeInsets.symmetric(horizontal: 24),
        onTap: () { _onResultsDone(); })       
      );
  } 

  List<Widget> _buildReportContent(Poll? poll) {
    String resultsIn = Localization().getStringEx('panel.poll_prompt.text.results_are_in', 'Results are in!')!;
    String pollClosed = Localization().getStringEx('panel.poll_prompt.text.voted_poll_closed', 'A poll you voted in has closed.')!;
    return <Widget>[
      Row(children: <Widget>[Expanded(child: Container(),)],),
      Padding(padding: EdgeInsets.only(top: 32, bottom:20),child:
        Text(resultsIn, style: TextStyle(color: Colors.white, fontFamily: Styles().fontFamilies!.regular, fontSize: 24, fontWeight: FontWeight.w900),),),
      Text(pollClosed, style: TextStyle(color: Colors.white, fontFamily: Styles().fontFamilies!.regular, fontSize: 16, fontWeight: FontWeight.w300),),
      _buildViewResultsButton(),
    ];
  }

  Widget _buildViewResultsButton() {
    return Padding(padding: EdgeInsets.only(top: 20, left: 50, right: 50), child:
      ScalableRoundedButton(
        label: Localization().getStringEx('panel.poll_prompt.button.view_poll_results.title', 'View poll results'),
        backgroundColor: Styles().colors!.fillColorPrimary,
//        height: 42,
        fontSize: 16.0,
        textColor: Colors.white,
        borderColor: Styles().colors!.fillColorSecondary,
        padding: EdgeInsets.symmetric(horizontal: 24),
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
            child: Container(width: 48, height: 48, alignment: Alignment.center, child: Image.asset('images/close-white.png'))));
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
    Polls().closePresent();
  }
}
