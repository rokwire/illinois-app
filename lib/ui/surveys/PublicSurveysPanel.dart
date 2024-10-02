

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/ui/surveys/PublicSurveyCard.dart';
import 'package:neom/ui/surveys/SurveyPanel.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:neom/ui/widgets/TabBar.dart' as uiuc;
import 'package:neom/ui/widgets/TextTabBar.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';

enum PublicSurveysContentType { all, completed }

class PublicSurveysPanel extends StatefulWidget {
  final PublicSurveysContentType selectedType;

  PublicSurveysPanel({super.key, this.selectedType = PublicSurveysContentType.all });

  @override
  State<StatefulWidget> createState() => _PublicSurveysPanelState();
}

enum _DataActivity { init, refresh, extend }

class _PublicSurveysPanelState extends State<PublicSurveysPanel> with TickerProviderStateMixin implements NotificationsListener  {

  late PublicSurveysContentType _selectedContentType;

  List<Survey>? _contentList;
  bool? _lastPageLoaded;
  _DataActivity? _dataActivity;
  Set<String> _activitySurveyIds = <String>{};

  static const int _contentPageLength = 16;

  ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  int _selectedTab = 0;

  final List<String> _tabNames = [
    Localization().getStringEx('panel.public_surveys.content_type.all', 'All Surveys'),
    Localization().getStringEx('panel.public_surveys.content_type.completed', 'Completed Surveys'),
  ];

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Surveys.notifySurveyResponseCreated,
      Surveys.notifySurveyResponseDeleted,
    ]);
    _selectedContentType = widget.selectedType;
    _scrollController.addListener(_scrollListener);

    if (widget.selectedType == PublicSurveysContentType.completed) {
      _selectedTab = 1;
    }
    _tabController = TabController(length: 2, initialIndex: _selectedTab, vsync: this);
    _tabController.addListener(_onTabChanged);

    _init();
    super.initState();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void onNotification(String name, param) {
    if ((name == Surveys.notifySurveyResponseCreated) ||(name == Surveys.notifySurveyResponseDeleted)) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: RootHeaderBar(title: Localization().getStringEx("panel.public_surveys.home.header.title", "Surveys"), leading: RootHeaderBarLeading.Back,),
    body: _scaffoldContent,
    backgroundColor: Styles().colors.background,
    bottomNavigationBar: uiuc.TabBar(),
  );

  Widget get _scaffoldContent {
    List<Widget> tabs = _tabNames.map((e) => TextTabButton(title: e)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextTabBar(tabs: tabs, controller: _tabController, isScrollable: false, onTap: (index){_onTabChanged();}),
      Expanded(
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _panelContent,
            _panelContent,
          ],
        ),
      ),
    ],);
  }

  Widget get _panelContent =>
    RefreshIndicator(onRefresh: _onRefresh, child:
      SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), child:
        _surveysContent,
      )
    );

  Widget get _surveysContent {
    if (_dataActivity == _DataActivity.init) {
      return _loadingContent;
    }
    else if (_dataActivity == _DataActivity.refresh) {
      return _blankContent;
    }
    else if (_contentList == null) {
      return _messageContent(Localization().getStringEx('panel.public_surveys.label.description.failed', 'Failed to load surveys.'),
        title: Localization().getStringEx('panel.events2.home.message.failed.title', 'Failed')
      );
    }
    else if (_contentList?.length == 0) {
      return _messageContent(Localization().getStringEx('panel.public_surveys.label.description.empty', 'There are no available surveys at the moment.'),);
    }
    else {
      return _surveysList;
    }
  }

  Widget get _surveysList {
    List<Widget> cardsList = <Widget>[];
    for (Survey survey in _contentList!) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 8 : 0), child:
        PublicSurveyCard.listCard(survey,
          hasActivity: _activitySurveyIds.contains(survey.id),
          onTap: () => _onSurvey(survey),
        ),
      ),);
    }
    if (_dataActivity == _DataActivity.extend) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 8 : 0), child:
        _extendingIndicator
      ));
    }
    return Padding(padding: EdgeInsets.all(16), child:
      Column(children:  cardsList,)
    );
  }

  Widget get _loadingContent => Column(children: [
    Padding(padding: EdgeInsets.symmetric(vertical: _screenHeight / 4), child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary,)
      )
    ),
    Container(height: _screenHeight / 2,)
  ],);

  Widget get _blankContent => Container();

  Widget _messageContent(String message, { String? title }) => Center(child:
    Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: _screenHeight / 6), child:
      Column(children: [
        (title != null) ? Padding(padding: EdgeInsets.only(bottom: 12), child:
          Text(title, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.item.light.medium.fat'),)
        ) : Container(),
        Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle((title != null) ? 'widget.item.light.regular.thin' : 'widget.item.light.medium.fat'),),
      ],),
    )
  );

  Widget get _extendingIndicator => Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32), child:
    Align(alignment: Alignment.center, child:
      SizedBox(width: 24, height: 24, child:
        CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary),),),),);

  double get _screenHeight => MediaQuery.of(context).size.height;

  bool? get _completedQueryParam {
    switch (_selectedContentType) {
      case PublicSurveysContentType.all: return null;
      case PublicSurveysContentType.completed: return true;
    }
  }

  Future<void> _init({ int limit = _contentPageLength }) async {
    if ((_dataActivity != _DataActivity.init) && (_dataActivity != _DataActivity.refresh)) {
      setStateIfMounted(() {
        _dataActivity = _DataActivity.init;
      });

      List<Survey>? contentList = await Surveys().loadSurveys(SurveysQueryParam.public(completed: _completedQueryParam, limit: limit));

      if (_dataActivity == _DataActivity.init) {
        setStateIfMounted(() {
          _contentList = (contentList != null) ? List<Survey>.from(contentList) : null;
          _lastPageLoaded = (contentList != null) ? (contentList.length >= limit) : null;
          _dataActivity = null;
        });
      }
    }
  }

  Future<void> _refresh() async {
    if ((_dataActivity != _DataActivity.init) && (_dataActivity != _DataActivity.refresh)) {
      setStateIfMounted(() {
        _dataActivity = _DataActivity.refresh;
      });

      int limit = max(_contentList?.length ?? 0, _contentPageLength);
      List<Survey>? contentList = await Surveys().loadSurveys(SurveysQueryParam.public(completed: _completedQueryParam, limit: limit));

      if (mounted && (_dataActivity == _DataActivity.refresh)) {
        setStateIfMounted(() {
          if (contentList != null) {
            _contentList = List<Survey>.from(contentList);
            _lastPageLoaded = (contentList.length >= limit);
          }
          _dataActivity = null;
        });
      }
    }
  }

  Future<void> _extend() async {
    if (_dataActivity == null) {
      setStateIfMounted(() {
        _dataActivity = _DataActivity.extend;
      });

      int limit = _contentPageLength;
      int offset = _contentList?.length ?? 0;
      List<Survey>? contentList = await Surveys().loadSurveys(SurveysQueryParam.public(completed: _completedQueryParam, offset: offset, limit: limit));

      if (_dataActivity == _DataActivity.extend) {
        setState(() {
          if (contentList != null) {
            if (_contentList != null) {
              _contentList?.addAll(contentList);
            }
            else {
              _contentList = List<Survey>.from(contentList);
            }
            _lastPageLoaded = (contentList.length >= limit);
          }
          _dataActivity = null;
        });
      }
    }
  }

  void _scrollListener() {
    if ((_scrollController.offset >= _scrollController.position.maxScrollExtent) && (_lastPageLoaded != false) && (_dataActivity != _DataActivity.init) && (_dataActivity != _DataActivity.refresh)) {
      _extend();
    }
  }

  Future<void> _onRefresh() {
    Analytics().logSelect(target: 'Refresh');
    return _refresh();
  }

  void _onSurvey(Survey survey) {
    Analytics().logSelect(target: 'Survey: ${survey.title}');
    if (survey.completed != true) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel.defaultStyles(survey: survey)));
    }
    else if (!_activitySurveyIds.contains(survey.id)) {
      setState(() {
        _activitySurveyIds.add(survey.id);
      });
      Surveys().loadUserSurveyResponses(surveyIDs: <String>[survey.id]).then((List<SurveyResponse>? result) {
        if (mounted) {
          setState(() {
            _activitySurveyIds.remove(survey.id);
          });
          SurveyResponse? surveyResponse = (result?.isNotEmpty == true) ? result?.first : null;
          if (surveyResponse != null) {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel.defaultStyles(survey: surveyResponse.survey, inputEnabled: false, dateTaken: surveyResponse.dateTaken, showResult: true)));
          }
          else {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel.defaultStyles(survey: survey)));
          }
        }
      });
    }
  }

  void _onTabChanged({bool manual = true}) {
    if (!_tabController.indexIsChanging && _selectedTab != _tabController.index) {
      setState(() {
        _selectedTab = _tabController.index;
        _selectedContentType = _selectedTab == 0 ? PublicSurveysContentType.all : PublicSurveysContentType.completed;
        _dataActivity = null;
      });
    }
    _scrollController.animateTo(0, duration: Duration(milliseconds: 500), curve: Curves.linear);
  }
}
