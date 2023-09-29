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
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/service/Polls.dart' as illinois;

class GroupPollListPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Group group;

  GroupPollListPanel({required this.group});

  @override
  _GroupPollListPanelState createState() => _GroupPollListPanelState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes => group.analyticsAttributes;
}

class _GroupPollListPanelState extends State<GroupPollListPanel> implements NotificationsListener {
  List<Poll>? _polls;
  PollsCursor? _pollsCursor;
  String? _pollsError;
  bool _pollsLoading = false;

  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Polls.notifyCreated, Polls.notifyStatusChanged, Polls.notifyVoteChanged, Polls.notifyResultsChanged]);
    _loadPolls();
    _scrollController = ScrollController();
    _scrollController!.addListener(_scrollListener);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(
            title: Localization().getStringEx('panel.group_polls.label.heading', 'All Polls'),
        ),
        body: CustomScrollView(controller: _scrollController, slivers: <Widget>[
          SliverList(
              delegate: SliverChildListDelegate([
            Column(children: <Widget>[_buildPollsContent()])
          ]))
        ]),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: uiuc.TabBar());
  }

  Widget _buildPollsContent() {
    int pollsLength = (_polls?.length ?? 0);

    Widget pollsContent;
    if ((0 < pollsLength) || _pollsLoading) {
      pollsContent = _buildPolls();
    } else if (_pollsError != null) {
      pollsContent = _buildErrorContent();
    } else {
      pollsContent = _buildEmptyContent();
    }

    return Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18), child: pollsContent);
  }

  Widget _buildPolls() {
    List<Widget> content = [];

    int pollsLength = _polls?.length ?? 0;

    if (0 < pollsLength) {
      _polls!.forEach((poll) {
        content.add(GroupPollCard(poll: poll, group: widget.group));
        content.add(_constructListSeparator());
      });
    }

    if (_pollsLoading) {
      content.add(_constructLoadingIndicator());
      content.add(_constructListSeparator());
    }

    return Column(children: content);
  }

  Widget _constructListSeparator() {
    return Container(height: 16);
  }

  Widget _buildEmptyContent() {
    String message = Localization().getStringEx('panel.group_polls.empty.message', 'There are no group polls.');
    String description = Localization().getStringEx('panel.group_polls.empty.description', 'You will see the polls for your group here.');

    return Container(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          Container(height: 100),
          Text(message,
              textAlign: TextAlign.center,
              style: Styles().textStyles?.getTextStyle("widget.title.extra_large.extra_fat")),
          Container(height: 16),
          Text(description,
              textAlign: TextAlign.center, style:Styles().textStyles?.getTextStyle("widget.item.regular.thin"))
        ]));
  }

  Widget _constructLoadingIndicator() {
    return Container(height: 80, child: Align(alignment: Alignment.center, child: CircularProgressIndicator()));
  }

  Widget _buildErrorContent() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          Container(height: 46),
          Text(Localization().getStringEx('panel.group_polls.text.error', 'Error'),
              textAlign: TextAlign.center,
              style: Styles().textStyles?.getTextStyle("widget.title.extra_large.extra_fat")),
          Container(height: 16),
          Text(StringUtils.ensureNotEmpty(_pollsError),
              textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"))
        ]));
  }

  void _loadPolls() {
    if (((_polls == null) || (_pollsCursor != null)) && !_pollsLoading) {
      String? groupId = widget.group.id;
      if (StringUtils.isNotEmpty(groupId)) {
        _setGroupPollsLoading(true);
        Polls().getGroupPolls(groupIds: {groupId!}, cursor: _pollsCursor)?.then((PollsChunk? result) {
          if (result != null) {
            if (_polls == null) {
              _polls = [];
            }
            _polls!.addAll(result.polls!);
            _pollsCursor = (0 < result.polls!.length) ? result.cursor : null;
            _pollsError = null;
          }
        }).catchError((e) {
          _pollsError = illinois.Polls.localizedErrorString(e);
        }).whenComplete(() {
          _setGroupPollsLoading(false);
        });
      }
    }
  }

  void _onPollUpdated(String? pollId) {
    Poll? poll = Polls().getPoll(pollId: pollId);
    if (poll != null) {
      if (mounted) {
        setState(() {
          _updatePoll(poll);
        });
      }
    }
  }

  void _updatePoll(Poll poll) {
    if (CollectionUtils.isNotEmpty(_polls)) {
      for (int index = 0; index < _polls!.length; index++) {
        if (_polls![index].pollId == poll.pollId) {
          _polls![index] = poll;
        }
      }
    }
  }

  void _scrollListener() {
    if (_scrollController!.offset >= _scrollController!.position.maxScrollExtent) {
      _loadPolls();
    }
  }

  void _setGroupPollsLoading(bool loading) {
    _pollsLoading = loading;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void onNotification(String name, param) {
    if((name == Polls.notifyCreated) || (name == Polls.notifyStatusChanged) || (name == Polls.notifyVoteChanged) || (name == Polls.notifyResultsChanged)) {
      _onPollUpdated(param);
    }
  }
}
