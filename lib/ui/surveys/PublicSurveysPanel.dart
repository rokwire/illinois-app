

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/ui/surveys/PublicSurveyCard.dart';
import 'package:neom/ui/surveys/SurveyPanel.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:neom/ui/widgets/TabBar.dart' as uiuc;
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

class _PublicSurveysPanelState extends State<PublicSurveysPanel> implements NotificationsListener  {

  late PublicSurveysContentType _selectedContentType;
  bool _contentTypeDropdownExpanded = false;

  List<Survey>? _contentList;
  bool? _lastPageLoaded;
  _DataActivity? _dataActivity;

  static const int _contentPageLength = 16;
  final Color _dropdownShadowColor = Color(0x99000000);

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Surveys.notifySurveyResponseCreated,
      Surveys.notifySurveyResponseDeleted,
    ]);
    _selectedContentType = widget.selectedType;
    _scrollController.addListener(_scrollListener);
    _init();
    super.initState();
  }

  @override
  void dispose() {
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

  Widget get _scaffoldContent => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _contentTypeDropdownWidget,
    Expanded(child:
        Stack(alignment: Alignment.topCenter, children: <Widget>[
          _panelContent,
          _dropdownListContainer,
        ])
    )
  ],);

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
        PublicSurveyCard.listCard(survey, onTap: () => _onSurvey(survey),),
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
          Text(title, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.item.medium.fat'),)
        ) : Container(),
        Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle((title != null) ? 'widget.item.regular.thin' : 'widget.item.medium.fat'),),
      ],),
    )
  );

  Widget get _extendingIndicator => Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32), child:
    Align(alignment: Alignment.center, child:
      SizedBox(width: 24, height: 24, child:
        CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary),),),),);

  Widget get _contentTypeDropdownWidget => Padding(padding: EdgeInsets.only(left: 16, top: 16, right: 16), child: RibbonButton(
    progress: (_dataActivity == _DataActivity.refresh),
    textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"),
    backgroundColor: Styles().colors.white,
    borderRadius: BorderRadius.all(Radius.circular(5)),
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    rightIconKey: (_contentTypeDropdownExpanded == true) ? 'chevron-up' : 'chevron-down',
    label: publicSurveysContentTypeDisplayName(_selectedContentType),
    onTap: _onContentTypeDropdown,
  ));

  Widget get _dropdownListContainer => Visibility(visible: _contentTypeDropdownExpanded, child:
    Stack(children: [
      InkWell(onTap: _onTapDropdownListShaddow, child:
        Container(color: _dropdownShadowColor),
      ),
      _dropdownListWidget
  ]));

  Widget get _dropdownListWidget {
    List<Widget> dropdownList = <Widget>[];
    dropdownList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));
    for (PublicSurveysContentType type in PublicSurveysContentType.values) {
      if ((_selectedContentType != type)) {
        dropdownList.add(_dropdownListItem(type));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: dropdownList)
      )
    );
  }

  Widget _dropdownListItem(PublicSurveysContentType contentType) => RibbonButton(
    backgroundColor: Styles().colors.white,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    rightIconKey: null,
    label: publicSurveysContentTypeDisplayName(contentType),
    onTap: () => _onDropdownListItem(contentType)
  );

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
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: survey)));
  }

  void _onContentTypeDropdown() {
    setState(() {
      _contentTypeDropdownExpanded = !_contentTypeDropdownExpanded;
    });
  }

  void _onTapDropdownListShaddow() {
    setState(() {
      _contentTypeDropdownExpanded = false;
    });
  }

  void _onDropdownListItem(PublicSurveysContentType contentType) {
    if (_selectedContentType != contentType) {
      setState(() {
        _selectedContentType = contentType;
        _contentTypeDropdownExpanded = false;
        _dataActivity = null;
      });
      _init();
    }
    else {
      setState(() {
        _contentTypeDropdownExpanded = false;
      });
    }
  }
}

String publicSurveysContentTypeDisplayName(PublicSurveysContentType value) {
  switch(value) {
    case PublicSurveysContentType.all: return Localization().getStringEx('panel.public_surveys.content_type.all', 'All Surveys');
    case PublicSurveysContentType.completed: return Localization().getStringEx('panel.public_surveys.content_type.completed', 'Completed Surveys');
  }
}
