import 'package:flutter/material.dart';
import 'package:neom/model/Analytics.dart';
import 'package:neom/ext/Poll.dart';
import 'package:neom/ui/groups/GroupWidgets.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:neom/service/Analytics.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:neom/ui/polls/PollProgressPainter.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:neom/service/Polls.dart' as neom;

class PollCard extends StatefulWidget{
  final Poll? poll;
  final Group? group;
  final bool? isAdmin;
  final bool showGroupName;

  PollCard({required this.poll, this.group, this.isAdmin, this.showGroupName = true});

  @override
  State<StatefulWidget> createState() => _PollCardState();

  bool get _canStart {
    return (poll?.status == PollStatus.created) && (
        (poll?.isMine ?? false) ||
            (group?.currentUserIsAdmin ?? false)
    );
  }

  bool get _canEnd {
    return (poll?.status == PollStatus.opened) && (
        (poll?.isMine ?? false) ||
            (group?.currentUserIsAdmin ?? false)
    );
  }

  bool get _canDelete {
    return (
        (poll?.isMine ?? false) ||
            (group?.currentUserIsAdmin ?? false)
    );
  }
}

class _PollCardState extends State<PollCard> implements NotificationsListener {
  GroupStats? _groupStats;

  List<GlobalKey>? _progressKeys;
  double? _progressWidth;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Groups.notifyGroupStatsUpdated,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evalProgressWidths();
    });
    _loadGroupStats();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void onNotification(String name, dynamic param) {
    if ((name == Groups.notifyGroupStatsUpdated) && (widget.group?.id == param)) {
      _updateGroupStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    Poll poll = widget.poll!;
    String pollVotesStatus = _pollVotesStatus;

    List<Widget> footerWidgets = [];

    String? pollStatus;

    String? creator = StringUtils.isNotEmpty(widget.poll?.creatorUserName) ? widget.poll?.creatorUserName : Localization().getStringEx('panel.poll_prompt.text.someone', 'Someone');//TBD localize
    String wantsToKnow = sprintf(Localization().getStringEx('panel.poll_prompt.text.wants_to_know', '%s wants to know'), [creator]);
    String semanticsQuestionText =  "$wantsToKnow,\n ${poll.title!}";
    String pin = sprintf(Localization().getStringEx('panel.polls_prompt.card.text.pin', 'Poll #: %s'), [
      sprintf('%04i', [poll.pinCode ?? 0])
    ]);

    if(poll.status == PollStatus.created) {
      pollStatus = Localization().getStringEx("panel.polls_home.card.state.text.created","Polls created");
    } if (poll.status == PollStatus.opened) {
      pollStatus = Localization().getStringEx("panel.polls_home.card.state.text.open","Polls open");
      if (poll.canVote) {
        footerWidgets.add(_createVoteButton());
      }
    }
    else if (poll.status == PollStatus.closed) {
      pollStatus =  Localization().getStringEx("panel.polls_home.card.state.text.closed","Polls closed");
    }

    Widget cardBody = ((poll.status == PollStatus.opened) && (poll.settings?.hideResultsUntilClosed ?? false)) ?
    Text(Localization().getStringEx("panel.poll_prompt.text.rule.detail.hide_result", "Results will not be shown until the poll ends."), style: Styles().textStyles.getTextStyle('widget.card.detail.regular'),) :
    Column(children: _buildCheckboxOptions(),);

    return Column(children: <Widget>[
      Container(
        decoration: BoxDecoration(
          color: Styles().colors.surface,
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
          boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))],
        ),
        child: Padding(padding: EdgeInsets.only(left: 16, bottom: 16), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(children: <Widget>[
              if (widget.showGroupName)
                Expanded(child:
                  Text(StringUtils.ensureNotEmpty(widget.group?.title), overflow: TextOverflow.ellipsis, style:Styles().textStyles.getTextStyle("widget.card.detail.regular.fat")),
                ),
              if (!widget.showGroupName)
                Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(pin, style: Styles().textStyles.getTextStyle('widget.card.detail.regular.fat')),
              ),
              Visibility(visible: _PollOptionsState._hasPollOptions(widget), child:
                Semantics(label: Localization().getStringEx("panel.group_detail.label.options", "Options"), button: true,child:
                  GestureDetector(onTap: _onPollOptionsTap, child:
                    Padding(padding: EdgeInsets.only(right: 16.0), child:
                      Styles().images.getImage('ellipsis-alert'),
                    ),
                  ),
                ),
              )
            ]),
          ),
          // Padding(
          //   padding: const EdgeInsets.only(top: 16.0),
          //   child: Semantics(label:semanticsQuestionText, excludeSemantics: true, child:
          //   Text(wantsToKnow, style: Styles().textStyles.getTextStyle('widget.card.detail.regular'))
          //   ),
          // ),
          Row(children: [
            Visibility(visible: widget.poll?.creatorUserUuid != null,
                child: GroupMemberProfileInfoWidget(
                    key: ValueKey(widget.poll?.pollId),
                    name: widget.poll?.creatorUserName,
                    userId: widget.poll?.creatorUserUuid,
                    isAdmin: widget.isAdmin,
                    additionalInfo: _pollDateText
                  // updateController: widget.updateController,
                ))
          ],),
          Padding(padding: EdgeInsets.only(right: 16), child:
          Column(children: [
            Container(height: 8,),
            Text(poll.title!, style: Styles().textStyles.getTextStyle('widget.group.card.poll.title')), // widget.card.title.large
            Container(height:12),
            cardBody,
            Container(height:24),
            Semantics(excludeSemantics: true, label: "$pollStatus,$pollVotesStatus", child:
            Row(children: <Widget>[
              Expanded(child:
              Text(pollVotesStatus, style: Styles().textStyles.getTextStyle('widget.card.detail.regular'),),
              ),
              Expanded(child:
              Text(pollStatus ?? "", textAlign: TextAlign.right, style: Styles().textStyles.getTextStyle('widget.card.detail.regular.fat'),))
            ],),
            ),

            if (footerWidgets.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(children: footerWidgets,),
              ),
          ],),
          ),
        ],),
        ),
      ),],
    );
  }

  String? get _pollDateText =>
      "Quick Poll, Updated ${widget.poll?.displayUpdateTime}";

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
      String checkboxImage = didVote ? 'check-circle-filled' : 'check-circle-outline-gray';

      String votesString;
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

      String semanticsText = option + "," +"\n "+  votesString +"," + votesPercent.toStringAsFixed(0) +"%";

      result.add(Padding(padding: EdgeInsets.only(top: (0 < result.length) ? 8 : 0), child:
      GestureDetector(
          onTap: widget.poll!.userVote == null ? _onVoteTapped : null,
          child:
          Semantics(label: semanticsText, excludeSemantics: true, child:
          Row(children: <Widget>[
            Padding(padding: EdgeInsets.only(right: 5), child: Styles().images.getImage(checkboxImage, size: 24.0)),
            Expanded(
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                Expanded(
                  child: Stack(key: progressKey, alignment: Alignment.centerLeft, children: <Widget>[
                    CustomPaint(painter: PollProgressPainter(backgroundColor: Styles().colors.surface, progressColor: useCustomColor ? Styles().colors.fillColorPrimary : Styles().colors.lightGray, progress: votesPercent / 100.0), child: Container(height:30, width: _progressWidth),),
                    Padding(padding: EdgeInsets.only(left: 10, right: 5), child:
                      Text(option, style: useCustomColor? Styles().textStyles.getTextStyle('widget.group.card.poll.option_variant')  : Styles().textStyles.getTextStyle('widget.group.card.poll.option')),
                    ),
                  ],),
                ),
                Padding(padding: EdgeInsets.only(left: 10), child: Text('$votesString (${votesPercent.toStringAsFixed(0)}%)', textAlign: TextAlign.right,style: Styles().textStyles.getTextStyle('widget.group.card.poll.votes'),),)
              ],),
            ),
          ],)
          )
      )
      ));
    }
    return result;
  }

  Widget _createVoteButton(){
    return _createButton(Localization().getStringEx("panel.polls_home.card.button.title.vote","Vote"), _onVoteTapped);
  }

  Widget _createButton(String title, void Function()? onTap, {bool loading = false}){
    return Container( padding: EdgeInsets.symmetric(horizontal: 88,),
        child: Semantics(label: title, button: true, excludeSemantics: true,
          child: InkWell(
              onTap: onTap,
              child: Stack(children: <Widget>[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Styles().colors.fillColorSecondaryVariant,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Text(title, style: Styles().textStyles.getTextStyle("widget.description.regular"),),
                  ),
                ),
                Visibility(visible: loading,
                  child: Container(padding: EdgeInsets.symmetric(vertical: 5),
                    child: Align(alignment: Alignment.center,
                      child: SizedBox(height: 24, width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorPrimary), )
                      ),
                    ),
                  ),
                )
              ])
          ),
        ));
  }

  void _onVoteTapped(){
    Polls().presentPollVote(widget.poll);
  }

  void _evalProgressWidths() {
    if (_progressKeys != null) {
      double progressWidth = -1.0;
      for (GlobalKey progressKey in _progressKeys!) {
        final RenderObject? progressRender = progressKey.currentContext?.findRenderObject();
        if ((progressRender is RenderBox) && progressRender.hasSize && (0 < progressRender.size.width)) {
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

  void _loadGroupStats() {
    Groups().loadGroupStats(widget.group?.id).then((stats) {
      if (mounted) {
        setState(() {
          _groupStats = stats;
        });
      }
    });
  }

  void _updateGroupStats() {
    GroupStats? cachedGroupStats = Groups().cachedGroupStats(widget.group?.id);
    if ((cachedGroupStats != null) && (_groupStats != cachedGroupStats) && mounted) {
      setState(() {
        _groupStats = cachedGroupStats;
      });
    }
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

  void _onPollOptionsTap() {
    Analytics().logSelect(target: "Options");

    showModalBottomSheet(context: context, backgroundColor: Styles().colors.surface, isScrollControlled: true, isDismissible: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return _PollOptions(pollCard: widget,);
        }
    );
  }
}

class _PollOptions extends StatefulWidget with AnalyticsInfo {
  final PollCard pollCard;

  _PollOptions({Key? key, required this.pollCard}) : super(key: key);

  @override
  State<_PollOptions> createState() => _PollOptionsState();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.Groups;
}

class _PollOptionsState extends State<_PollOptions> {

  bool _isStarting = false;
  bool _isEnding = false;
  bool _isDeleting = false;

  static bool _hasPollOptions(PollCard pollCard) =>
      pollCard._canStart ||
          pollCard._canEnd ||
          pollCard._canDelete;

  @override
  Widget build(BuildContext context) {
    List<Widget> options = <Widget>[];

    if (widget.pollCard._canStart) {
      options.add(RibbonButton(
          label: Localization().getStringEx("panel.polls_home.card.button.title.start_poll", "Start Poll"),
          leftIconKey: "settings",
          progress: _isStarting,
          onTap: _onStartPollTapped
      ),);
    }
    if (widget.pollCard._canEnd) {
      options.add(RibbonButton(
          label: Localization().getStringEx("panel.polls_home.card.button.title.end_poll", "End Poll"),
          leftIconKey: "settings",
          progress: _isEnding,
          onTap: _onEndPollTapped
      ),);
    }

    if (widget.pollCard._canDelete) {
      options.add(RibbonButton(
          label: Localization().getStringEx("panel.polls_home.card.button.title.delete_poll", "Delete Poll"),
          leftIconKey: "trash",
          progress: _isDeleting,
          onTap: _onDeletePollTapped
      ),);
    }

    return Container(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child:
    Column(mainAxisSize: MainAxisSize.min, children: options,
    ),
    );

  }

  void _onStartPollTapped() {
    if (_isStarting != true) {
      setState(() {
        _isStarting = true;
      });
      Polls().open(widget.pollCard.poll?.pollId).then((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }).catchError((e) {
        if (mounted) {
          AppAlert.showDialogResult(context, neom.Polls.localizedErrorString(e));
        }
      }).whenComplete(() {
        if (mounted) {
          setState(() {
            _isStarting = false;
          });
        }
      });
    }
  }

  void _onEndPollTapped() {
    if (_isEnding != true) {
      setState(() {
        _isEnding = true;
      });
      Polls().close(widget.pollCard.poll?.pollId).then((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }).catchError((e) {
        if (mounted) {
          AppAlert.showDialogResult(context, neom.Polls.localizedErrorString(e));
        }
      }).whenComplete(() {
        if (mounted) {
          setState(() {
            _isEnding = false;
          });
        }
      });
    }
  }

  void _onDeletePollTapped() {
    if (_isDeleting != true) {
      setState(() {
        _isDeleting = true;
      });
      Polls().delete(widget.pollCard.poll?.pollId).then((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }).catchError((e) {
        if (mounted) {
          AppAlert.showDialogResult(context, neom.Polls.localizedErrorString(e));
        }
      }).whenComplete(() {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      });
    }
  }
}