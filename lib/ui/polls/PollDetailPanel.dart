/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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
import 'package:illinois/ui/polls/PollsHomePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class PollDetailPanel extends StatefulWidget {
  final String? pollId;

  PollDetailPanel({required this.pollId});

  @override
  _PollDetailPanelState createState() => _PollDetailPanelState();
}

class _PollDetailPanelState extends State<PollDetailPanel> implements NotificationsListener {
  Poll? _poll;
  Group? _group;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    NotificationService()
        .subscribe(this, [Polls.notifyDeleted, Polls.notifyStatusChanged, Polls.notifyVoteChanged, Polls.notifyResultsChanged]);
    _loadPoll();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: Localization().getStringEx('panel.poll.detail.header.title', 'Poll')),
        body: SingleChildScrollView(child: _buildContent()),
        backgroundColor: Styles().colors!.white,
        bottomNavigationBar: uiuc.TabBar());
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingContent();
    } else if (StringUtils.isEmpty(widget.pollId) || (_poll == null)) {
      return _buildErrorContent();
    } else {
      return _buildPollContent();
    }
  }

  Widget _buildPollContent() {
    return PollCard(poll: _poll, group: _group);
  }

  Widget _buildErrorContent() {
    return _buildCenterWidget(Text(Localization().getStringEx('panel.poll.detail.error.msg', 'This poll does not exist anymore.')));
  }

  Widget _buildLoadingContent() {
    return _buildCenterWidget(CircularProgressIndicator());
  }

  Widget _buildCenterWidget(Widget child) {
    return Center(
        child: Column(children: <Widget>[
      Container(height: MediaQuery.of(context).size.height / 5),
      child,
      Container(height: MediaQuery.of(context).size.height / 5 * 3)
    ]));
  }

  void _loadPoll() {
    if (StringUtils.isEmpty(widget.pollId)) {
      return;
    }
    _increaseProgress();
    Polls().loadById(widget.pollId!).then((poll) {
      _poll = poll;
      _loadGroup();
      _decreaseProgress();
    });
  }

  void _loadGroup() {
    if (!(_poll?.hasGroup ?? false)) {
      return;
    }
    String pollGroupId = _poll!.groupId!;
    List<Group>? userGroups = Groups().userGroups;
    if (CollectionUtils.isNotEmpty(userGroups)) {
      for (Group group in userGroups!) {
        if (group.id == pollGroupId) {
          _group = group;
          break;
        }
      }
    }
  }

  void _onPollUpdated(String? pollId) {
    if (pollId == widget.pollId) {
      _loadPoll();
    }
  }

  void _increaseProgress() {
    setStateIfMounted(() {
      _loadingProgress++;
    });
  }

  void _decreaseProgress() {
    setStateIfMounted(() {
      _loadingProgress--;
    });
  }

  bool get _isLoading {
    return (_loadingProgress > 0);
  }

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if (name == Polls.notifyVoteChanged ||
        name == Polls.notifyResultsChanged ||
        name == Polls.notifyStatusChanged ||
        name == Polls.notifyDeleted) {
      _onPollUpdated(param);
    }
  }
}
