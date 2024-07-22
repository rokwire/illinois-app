

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/surveys/SurveyPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';

class PublicSurveysPanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PublicSurveysPanelState();
}

enum _DataActivity { init, refresh, extend }

class _PublicSurveysPanelState extends State<PublicSurveysPanel>  {

  List<Survey>? _contentList;
  bool? _lastPageLoaded;
  _DataActivity? _dataActivity;
  static const int _pageLength = 16;

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    _scrollController.addListener(_scrollListener);
    _init();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: RootHeaderBar(title: Localization().getStringEx("panel.public_surveys.home.header.title", "Public Surveys"), leading: RootHeaderBarLeading.Back,),
    body: _panelContent,
    backgroundColor: Styles().colors.background,
    bottomNavigationBar: uiuc.TabBar(),
  );

  Widget get _panelContent => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(child:
      RefreshIndicator(onRefresh: _onRefresh, child:
        SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), child:
          _surveysContent,
        )
      )
    )
  ],);

  Widget get _surveysContent {
    if (_dataActivity == _DataActivity.init) {
      return _loadingContent;
    }
    else if (_dataActivity == _DataActivity.refresh) {
      return _blankContent;
    }
    else if (_contentList == null) {
      return _messageContent(Localization().getStringEx('panel.public_surveys.label.description.failed', 'Failed to load public surveys.'),
        title: Localization().getStringEx('panel.events2.home.message.failed.title', 'Failed')
      );
    }
    else if (_contentList?.length == 0) {
      return _messageContent(Localization().getStringEx('panel.public_surveys.label.description.empty', 'There are no available public surveys at the moment.'),);
    }
    else {
      return _surveysList;
    }
  }

  Widget get _surveysList {
    List<Widget> cardsList = <Widget>[];
    for (Survey survey in _contentList!) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 8 : 0), child:
        _SurveyCard(survey, onTap: () => _onSurvey(survey),),
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

  Widget _messageContent(String message, { String? title }) =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: _screenHeight / 6), child:
      Column(children: [
        (title != null) ? Padding(padding: EdgeInsets.only(bottom: 12), child:
          Text(title, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.item.medium.fat'),)
        ) : Container(),
        Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle((title != null) ? 'widget.item.regular.thin' : 'widget.item.medium.fat'),),
      ],),
    );

  Widget get _extendingIndicator => Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32), child:
    Align(alignment: Alignment.center, child:
      SizedBox(width: 24, height: 24, child:
        CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary),),),),);

  double get _screenHeight => MediaQuery.of(context).size.height;

  Future<void> _init({ int limit = _pageLength }) async {
    if ((_dataActivity != _DataActivity.init) && (_dataActivity != _DataActivity.refresh)) {
      setStateIfMounted(() {
        _dataActivity = _DataActivity.init;
      });

      List<Survey>? contentList = await Surveys().loadSurveys(SurveysQueryParam.public(limit: limit));

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

      int limit = max(_contentList?.length ?? 0, _pageLength);
      List<Survey>? contentList = await Surveys().loadSurveys(SurveysQueryParam.public(limit: limit));

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

      int limit = _pageLength;
      int offset = _contentList?.length ?? 0;
      List<Survey>? contentList = await Surveys().loadSurveys(SurveysQueryParam.public(offset: offset, limit: limit));

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

  Future<void> _onRefresh() async {
    Analytics().logSelect(target: 'Refresh');
    return _refresh();
  }

  void _onSurvey(Survey survey) {
    Analytics().logSelect(target: 'Survey: ${survey.title}');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: survey)));  }
}

class _SurveyCard extends StatelessWidget {
  final Survey survey;
  final void Function()? onTap;

  // ignore: unused_element
  _SurveyCard(this.survey, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) =>
    InkWell(onTap: onTap, child: _contentWidget);

  Widget get _contentWidget =>
    Container(decoration: _contentDecoration, child:
      ClipRRect(borderRadius: _contentBorderRadius, child:
        Padding(padding: const EdgeInsets.all(16), child:
          Row(children: [
            Expanded(child:
              Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.start, children: [
                Text(survey.title, style: Styles().textStyles.getTextStyle('widget.card.title.small.fat'),),
                // Build more details here
              ],)
            ),
            Padding(padding: const EdgeInsets.only(left: 8), child:
                Styles().images.getImage('chevron-right-bold'),
            )
          ],)
        )
      ),
    );

  static Decoration get _contentDecoration => BoxDecoration(
    color: Styles().colors.surface,
    borderRadius: _contentBorderRadius,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 1.0, blurRadius: 1.0, offset: Offset(0, 2))]
  );

  static BorderRadiusGeometry get _contentBorderRadius => BorderRadius.all(Radius.circular(8));

}