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
import 'package:illinois/model/Rewards.dart';
import 'package:illinois/service/Rewards.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class DebugRewardsPanel extends StatefulWidget{
  _DebugRewardsPanelState createState() => _DebugRewardsPanelState();
}

class _DebugRewardsPanelState extends State<DebugRewardsPanel>{

  int? _userBalance;
  List<RewardHistoryEntry>? _historyEntries;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _loadHistory();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Styles().colors!.surface,
        appBar: HeaderBar(title: 'Rewards'),
        body: SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.all(16),
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Rewards balance', style: _defaultBoldTextStyle),
                          Text('${_userBalance ?? 0}', style: _defaultBoldTextStyle),
                        ]),
                        _buildDelimiterWidget(),
                        _buildHistoryHeaderWidget(),
                        _buildDelimiterWidget(),
                        _buildHistoryEntriesContentWidget()
                      ]))));
  }

  Widget _buildDelimiterWidget() {
    return Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Container(height: 1, color: Styles().colors!.lightGray));
  }

  Widget _buildHistoryHeaderWidget() {
    return Row(children: [
      Expanded(child: Text('Date', style: _defaultBoldTextStyle)),
      Expanded(
          flex: 3, child: Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('Description', style: _defaultBoldTextStyle))),
      Expanded(child: Text('Points', textAlign: TextAlign.end, style: _defaultBoldTextStyle))
    ]);
  }

  Widget _buildHistoryEntriesContentWidget() {
    if (CollectionUtils.isEmpty(_historyEntries)) {
      return Center(child: Text('No history, yet', style: _defaultRegularTextStyle));
    }
    List<Widget> entriesWidgetList = [];
    for (RewardHistoryEntry entry in _historyEntries!) {
      entriesWidgetList.add(_buildEntryWidget(entry));
      entriesWidgetList.add(_buildDelimiterWidget());
    }
    return Column(children: entriesWidgetList);
  }

  Widget _buildEntryWidget(RewardHistoryEntry entry) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Text(StringUtils.ensureNotEmpty(entry.displayDate), style: _defaultRegularTextStyle)),
      Expanded(
          flex: 3,
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(StringUtils.ensureNotEmpty(entry.displayDescription), style: _defaultRegularTextStyle))),
      Expanded(child: Text(StringUtils.ensureNotEmpty(entry.amount?.toString()), textAlign: TextAlign.end, style: _defaultRegularTextStyle))
    ]);
  }

  TextStyle get _defaultBoldTextStyle {
    return TextStyle(fontSize: 18, fontFamily: Styles().fontFamilies!.bold, color: Colors.black);
  }

  TextStyle get _defaultRegularTextStyle {
    return TextStyle(fontSize: 18, fontFamily: Styles().fontFamilies!.regular, color: Colors.black);
  }

  void _loadBalance() {
    _increaseProgress();
    Rewards().loadBalance().then((balance) {
      _userBalance = balance;
      _decreaseProgress();
    });
  }

  void _loadHistory() {
    _increaseProgress();
    Rewards().loadHistory().then((entries) {
      _historyEntries = entries;
      _decreaseProgress();
    });
  }

  void _increaseProgress() {
    _loadingProgress++;
    if (mounted) {
      setState(() {});
    }
  }

  void _decreaseProgress() {
    _loadingProgress--;
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isLoading {
    return (_loadingProgress > 0);
  }
}


