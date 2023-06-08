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
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class GroupSurveyResponsesPanel extends StatefulWidget {
  final List<Survey> surveys;
  final Group group;

  GroupSurveyResponsesPanel({required this.surveys, required this.group});

  @override
  _GroupSurveyResponsesPanelState createState() => _GroupSurveyResponsesPanelState();
}

class _GroupSurveyResponsesPanelState extends State<GroupSurveyResponsesPanel> implements NotificationsListener {
  //TODO: everything
  late List<Survey> _surveys;
  int _surveyBatchOffset = 0;
  String? _surveysError;
  bool _surveysLoading = false;

  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Surveys.notifySurveyCreated, Surveys.notifySurveyDeleted]);
    _surveys = List.from(widget.surveys);
    _surveyBatchOffset = _surveys.length;
    _scrollController = ScrollController();
    _scrollController!.addListener(_scrollListener);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(
            title: Localization().getStringEx('panel.group_surveys.label.heading', 'All Surveys'),
        ),
        body: CustomScrollView(controller: _scrollController, slivers: <Widget>[
          SliverList(
              delegate: SliverChildListDelegate([
            Column(children: <Widget>[_buildSurveysContent()])
          ]))
        ]),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: uiuc.TabBar());
  }

  Widget _buildSurveysContent() {
    Widget surveysContent;
    if ((0 < _surveys.length) || _surveysLoading) {
      surveysContent = _buildSurveys();
    } else if (_surveysError != null) {
      surveysContent = _buildErrorContent();
    } else {
      surveysContent = _buildEmptyContent();
    }

    return Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18), child: surveysContent);
  }

  Widget _buildSurveys() {
    List<Widget> content = [];

    if (0 < _surveys.length) {
      _surveys.forEach((survey) {
        content.add(GroupSurveyCard(survey: survey, group: widget.group));
        content.add(_constructListSeparator());
      });
    }

    if (_surveysLoading) {
      content.add(_constructLoadingIndicator());
      content.add(_constructListSeparator());
    }

    return Column(children: content);
  }

  Widget _constructListSeparator() {
    return Container(height: 16);
  }

  Widget _buildEmptyContent() {
    String message = Localization().getStringEx('panel.group_surveys.empty.message', 'There are no group surveys.');
    String description = Localization().getStringEx('panel.group_surveys.empty.description', 'You will see the surveys for your group here.');

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
          Text(Localization().getStringEx('panel.group_surveys.text.error', 'Error'),
              textAlign: TextAlign.center,
              style: Styles().textStyles?.getTextStyle("widget.title.extra_large.extra_fat")),
          Container(height: 16),
          Text(StringUtils.ensureNotEmpty(_surveysError),
              textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"))
        ]));
  }

  void _loadSurveys() {
    if (!_surveysLoading) {
      String? groupId = widget.group.id;
      if (StringUtils.isNotEmpty(groupId)) {
        _setGroupSurveysLoading(true);
        Surveys().loadSurveys(groupIds: [groupId!], offset: _surveyBatchOffset).then((result) {
          if ((result?.length ?? 0) > 0) {
            _surveys.addAll(result!);
            _surveyBatchOffset = _surveys.length;
            _surveysError = null;
          }
        }).catchError((e) {
          _surveysError = 'Failed to load group surveys';
        }).whenComplete(() {
          _setGroupSurveysLoading(false);
        });
      }
    }
  }

  void _scrollListener() {
    if (_scrollController!.offset >= _scrollController!.position.maxScrollExtent) {
      _loadSurveys();
    }
  }

  void _setGroupSurveysLoading(bool loading) {
    _surveysLoading = loading;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void onNotification(String name, param) {
    if((name == Surveys.notifySurveyCreated) || (name == Surveys.notifySurveyDeleted)) {
      _surveys.clear();
      _loadSurveys();
    }
  }
}
