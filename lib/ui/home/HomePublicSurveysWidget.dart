import 'dart:async';
import 'dart:math';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/ui/home/HomePanel.dart';
import 'package:neom/ui/home/HomeWidgets.dart';
import 'package:neom/ui/surveys/PublicSurveyCard.dart';
import 'package:neom/ui/surveys/PublicSurveysPanel.dart';
import 'package:neom/ui/surveys/SurveyPanel.dart';
import 'package:neom/ui/widgets/LinkButton.dart';
import 'package:neom/ui/widgets/SemanticsWidgets.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomePublicSurveysWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomePublicSurveysWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.public_surveys.label.header.title', 'Surveys');

  @override
  State<StatefulWidget> createState() => _HomePublicSurveysWidgetState();
}

enum _DataActivity { init, refresh, extend }

class _HomePublicSurveysWidgetState extends State<HomePublicSurveysWidget> implements NotificationsListener {

  List<Survey>? _contentList;
  bool? _lastPageLoaded;
  _DataActivity? _dataActivity;
  Map<String, GlobalKey> _cardKeys = <String, GlobalKey>{};
  Set<String> _activitySurveyIds = <String>{};
  DateTime? _pausedDateTime;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  static const String _progressPageKey = '{{progress}}';
  static double _pageSpacing = 16;
  static double _pageBottomPadding = 0;
  static const int _contentPageLength = 16;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      Surveys.notifySurveyResponseCreated,
      Surveys.notifySurveyResponseDeleted,
      Connectivity.notifyStatusChanged,
      Auth2.notifyLoginChanged,
      AppLifecycle.notifyStateChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _refresh();
        }
      });
    }

    _init();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void onNotification(String name, param) {
    if (name == AppLifecycle.notifyStateChanged) {
      _onAppLifecycleStateChanged(param);
    }
    else if ((name == Connectivity.notifyStatusChanged) ||
             (name == Auth2.notifyLoginChanged) ||
             (name == Surveys.notifySurveyResponseCreated) ||
             (name == Surveys.notifySurveyResponseDeleted)) {
      _refresh().then((_) {
        setStateIfMounted();
      });
    }
  }

  void _onAppLifecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _refresh();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: HomePublicSurveysWidget.title,
      titleIconKey: 'survey',
      child: _widgetContent,
    );
  }

  Widget get _widgetContent {
    if (Connectivity().isOffline) {
      return HomeMessageCard(
        title: Localization().getStringEx("common.message.offline", "You appear to be offline"),
        message: Localization().getStringEx("widget.home.public_surveys.label.description.offline", "Surveys are not available while offline"),
      );
    }
    else if (!Auth2().isLoggedIn) {
      return HomeMessageCard(
        title: Localization().getStringEx("common.message.logged_out", "You are not logged in"),
        message: Localization().getStringEx("widget.home.public_surveys.label.description.logged_out", "You need to be logged in to access surveys. Set your privacy level to 4 or 5 in your Profile. Then find the sign-in prompt under Settings."),);
    }
    else if (_dataActivity == _DataActivity.init) {
      return HomeProgressWidget();
    }
    else if (_dataActivity == _DataActivity.refresh) {
      return HomeProgressWidget();
    }
    else if (_contentList == null) {
      return HomeMessageCard(
        title: Localization().getStringEx('common.label.failed', 'Failed'),
        message: Localization().getStringEx("widget.home.public_surveys.label.description.failed", "Failed to load surveys."),
      );
    }
    else if (_contentList?.length == 0) {
      return HomeMessageCard(
        message: Localization().getStringEx("widget.home.public_surveys.label.description.empty", "There are no available surveys at the moment."),
      );
    }
    else {
      return Column(children: [
        _surveysContent,
        AccessibleViewPagerNavigationButtons(
          controller: _pageController,
          pagesCount: () {
            if ((_contentList?.length ?? 0) == _cardsPerPage) {
              return 1;
            }
            return (_contentList?.length ?? 0) ~/ _cardsPerPage + 1;
          },
          centerWidget: LinkButton(
            title: Localization().getStringEx('widget.home.groups.button.all.title', 'View All'),
            hint: Localization().getStringEx('widget.home.groups.button.all.hint', 'Tap to view all groups'),
            textStyle: Styles().textStyles.getTextStyle('widget.description.regular.light.underline'),
            onTap: _onSeeAll,
          ),
        ),
      ],);
    }
  }

  Widget get _surveysContent => (_contentList?.length == 1) ?
    _singleSurveyContent : _multipleSurveysContent;

  Widget get _singleSurveyContent =>
    Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8), child:
      Container(
        constraints: BoxConstraints(maxWidth: _cardWidth),
        child: PublicSurveyCard.pageCard(_contentList!.first, hasActivity: _activitySurveyIds.contains(_contentList!.first.id), onTap: () => _onSurvey(_contentList!.first),)
      )
    );

  double get _pageHeight {

    double? minContentHeight;
    for(GlobalKey contentKey in _cardKeys.values) {
      final RenderObject? renderBox = contentKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && renderBox.hasSize && ((minContentHeight == null) || (renderBox.size.height < minContentHeight))) {
        minContentHeight = renderBox.size.height;
      }
    }

    return minContentHeight ?? 0;
  }

  double get _cardWidth {
    double screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth - 2 * _cardsPerPage * _pageSpacing) / _cardsPerPage;
  }

  int get _cardsPerPage {
    ScreenType screenType = ScreenUtils.getType(context);
    switch (screenType) {
      case ScreenType.desktop:
        return min(5, (_contentList?.length ?? 1));
      case ScreenType.tablet:
        return min(3, (_contentList?.length ?? 1));
      case ScreenType.phone:
        return 1;
      default:
        return 1;
    }
  }

  Widget get _multipleSurveysContent {

    List<Widget> pages = <Widget>[];

    int cardCount = _contentList?.length ?? 0;
    int pageCount = cardCount ~/ _cardsPerPage;
    for (int index = 0; index < pageCount + 1; index++) {
      List<Widget> pageCards = [];
      for (int cardIndex = 0; cardIndex < _cardsPerPage; cardIndex++) {
        if (index * _cardsPerPage + cardIndex >= _contentList!.length) {
          break;
        }
        Survey survey = _contentList![index * _cardsPerPage + cardIndex];
        pageCards.add(Padding(
          key: _cardKeys[survey.id] ??= GlobalKey(),
          padding: EdgeInsets.only(right: _pageSpacing, bottom: _pageBottomPadding),
          child: Container(
            constraints: BoxConstraints(maxWidth: _cardWidth),
            child: PublicSurveyCard.pageCard(survey, hasActivity: _activitySurveyIds.contains(survey.id), onTap: () => _onSurvey(survey),)
          )
        ),);
      }
      if (_cardsPerPage > 1 && pageCards.length > 1) {
        pages.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: pageCards,
        ));
      } else {
        pages.addAll(pageCards);
      }
    }

    if (_dataActivity == _DataActivity.extend) {
      pages.add(Padding(
        key: _cardKeys[_progressPageKey] ??= GlobalKey(),
        padding: EdgeInsets.only(right: _pageSpacing, bottom: _pageBottomPadding),
        child: PublicSurveyPageProgressCard()
      ),);
    }

    if (_pageController == null) {
      double screenWidth = MediaQuery.of(context).size.width;
      double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
      _pageController = PageController(viewportFraction: pageViewport);
    }

    return Container(constraints: BoxConstraints(minHeight: _pageHeight), child:
      ExpandablePageView(
        key: _pageViewKey,
        controller: _pageController,
        onPageChanged: _onPageChanged,
        estimatedPageSize: _pageHeight,
        allowImplicitScrolling : true,
        children: pages),
    );
  }


  Future<void> _init({ int limit = _contentPageLength }) async {
    if (Connectivity().isOnline && (_dataActivity != _DataActivity.init) && (_dataActivity != _DataActivity.refresh)) {
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
    if (Connectivity().isOnline && Auth2().isLoggedIn && (_dataActivity != _DataActivity.init) && (_dataActivity != _DataActivity.refresh)) {
      setStateIfMounted(() {
        _dataActivity = _DataActivity.refresh;
      });

      int limit = max(_contentList?.length ?? 0, _contentPageLength);
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
    if (Connectivity().isOnline && (_dataActivity == null)) {
      setStateIfMounted(() {
        _dataActivity = _DataActivity.extend;
      });

      int limit = _contentPageLength;
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

  void _onPageChanged(int index) {
    int pagesCount = _contentList?.length ?? 0;
    if ((pagesCount <= (index + 1)) && (_lastPageLoaded != false)) {
      _extend();
    }
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
        if (mounted && (_activitySurveyIds.contains(survey.id))) {
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

  void _onSeeAll() {
    Analytics().logSelect(target: "View All", source: '${widget.runtimeType}' );
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PublicSurveysPanel()));
  }
}

class PublicSurveyPageProgressCard extends StatelessWidget {

  PublicSurveyPageProgressCard({super.key});

  @override
  Widget build(BuildContext context) =>
    Container(decoration: PublicSurveyCard.contentDecoration, child:
      ClipRRect(borderRadius: PublicSurveyCard.contentBorderRadius, child:
        Padding(padding: const EdgeInsets.all(16), child:
          Center(child:
            SizedBox(height: 21, width: 21, child:
              CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorPrimary, )
            ),
          )
        )
      ),
    );
}

