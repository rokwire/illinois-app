import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/ui/home/HomePanel.dart';
import 'package:neom/ui/home/HomeWidgets.dart';
import 'package:neom/ui/polls/CreatePollPanel.dart';
import 'package:neom/ui/polls/PollWidgets.dart';
import 'package:neom/ui/polls/PollsHomePanel.dart';
import 'package:neom/ui/widgets/LinkButton.dart';
import 'package:neom/ui/widgets/SemanticsWidgets.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:flutter/material.dart';

class HomePollsSectionWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomePollsSectionWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
      HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
        title: StringUtils.capitalize(title),
      );

  static String get title => Localization().getStringEx('widget.home.polls.label.header.title', 'POLLS');

  @override
  State<StatefulWidget> createState() => _HomePollsSectionWidgetState();
}

class _HomePollsSectionWidgetState extends State<HomePollsSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return HomeBannerWidget(favoriteId: widget.favoriteId,
      title: HomePollsSectionWidget.title,
      bannerImageKey: 'banner-polls',
      child: _widgetContent,
      childPadding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
    );
  }

  Widget get _widgetContent {
    return Column(children: [
      HomeRecentPollsWidget(updateController: widget.updateController,),
      // Container(height: 16),
      // HomeCreatePollWidget(updateController: widget.updateController,),
    ],);
  }
}

class HomeRecentPollsWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeRecentPollsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
      HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
        title: title,
      );

  static String get title => Localization().getStringEx('widget.home.recent_polls.text.title', 'RECENT POLLS');

  State<HomeRecentPollsWidget> createState() => _HomeRecentPollsWidgetState();
}

class _HomeRecentPollsWidgetState extends State<HomeRecentPollsWidget> implements NotificationsListener {

  List<Poll>? _recentPolls;
  bool _loadingPolls = false;
  bool _loadingPollsPage = false;
  bool _hasMorePolls = true;
  DateTime? _pausedDateTime;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  Map<String, GlobalKey> _contentKeys = <String, GlobalKey>{};
  final double _pageSpacing = 16;
  final double _pageBottomPadding = 16;

  @override
  void initState() {

    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Auth2.notifyLoginChanged,
      AppLifecycle.notifyStateChanged,
      Config.notifyConfigChanged,
      Polls.notifyCreated,
      Polls.notifyStatusChanged,
      Polls.notifyVoteChanged,
      Polls.notifyResultsChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _refreshPolls(showProgress: true, initResult: true);
        }
      });
    }

    if (Connectivity().isOnline) {
      _loadingPolls = true;
      Polls().getRecentPolls(cursor: PollsCursor(offset: 0, limit: Config().homeRecentPollsCount + 1))?.then((PollsChunk? result) {
        setStateIfMounted(() {
          _recentPolls = result?.polls;
        });
      }).catchError((_){

      }).whenComplete((){
        setStateIfMounted(() {
          _loadingPolls = false;
        });
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _pageController?.dispose();
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Connectivity.notifyStatusChanged) {
      _onContentAvailabilityChanged(Connectivity().isOnline);
    }
    else if (name == Auth2.notifyLoginChanged) {
      _onContentAvailabilityChanged(Auth2().isLoggedIn);
    }
    else if (name == AppLifecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == Config.notifyConfigChanged) {
      setStateIfMounted(() {});
    }
    else if (name == Polls.notifyCreated) {
      _onPollCreated(param);
    }
    else if (name == Polls.notifyVoteChanged) {
      _onPollUpdated(param);
    }
    else if (name == Polls.notifyResultsChanged) {
      _onPollUpdated(param);
    }
    else if (name == Polls.notifyStatusChanged) {
      _onPollUpdated(param);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    if (Connectivity().isOffline) {
      return HomeMessageCard(
        title: Localization().getStringEx("common.message.offline", "You appear to be offline"),
        message: Localization().getStringEx("widget.home.recent_polls.text.offline", "Recent Polls are not available while offline"),);
    }
    else if (!Auth2().isLoggedIn) {
      return HomeMessageCard(
        title: Localization().getStringEx("common.message.logged_out", "You are not signed in"),
        message: Localization().getStringEx("widget.home.recent_polls.text.logged_out", "Recent Polls are not available while not signed in."),);
    }
    else if (_loadingPolls) {
      return HomeProgressWidget();
    }
    else if (CollectionUtils.isEmpty(_recentPolls)) {
      return HomeMessageCard(
        message: Localization().getStringEx("widget.home.recent_polls.text.empty.description", "No polls are available right now."),);
    }
    else {
      return _buildPollsContent();
    }

  }

  Widget _buildPollsContent() {
    Widget contentWidget;
    int visibleCount = _recentPolls?.length ?? 0;
    int pageCount = visibleCount ~/ _cardsPerPage;
    bool extraPage = (visibleCount % _cardsPerPage) > 0;

    List<Widget> pages = <Widget>[];
    for (int index = 0; index < pageCount + (extraPage ? 1 : 0); index++) {
      List<Widget> pageCards = [];
      for (int groupIndex = 0; groupIndex < _cardsPerPage; groupIndex++) {
        Widget pageCard = SizedBox(width: _cardWidth);
        if (index * _cardsPerPage + groupIndex < _recentPolls!.length) {
          Poll poll = _recentPolls![index * _cardsPerPage + groupIndex];
          GlobalKey pollKey = (_contentKeys[poll.pollId ?? ''] ??= GlobalKey());
          pageCard = Padding(key: pollKey, padding: EdgeInsets.only(right: _pageSpacing, bottom: _pageBottomPadding), child:
            Semantics(/* excludeSemantics: !(_pageController?.page == _groups?.indexOf(group)),*/ child:
              Container(
                constraints: BoxConstraints(maxWidth: _cardWidth),
                child: PollCard(poll: poll, group: _getGroup(poll.groupId)),
              ),
          ));
        }
        pageCards.add(pageCard);
      }
      if (_cardsPerPage > 1) {
        pages.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: pageCards,
        ));
      } else {
        pages.addAll(pageCards);
      }
    }

    if (_loadingPollsPage) {
      pages.add(Padding(key: _contentKeys['last'] ??= GlobalKey(), padding: EdgeInsets.only(right: _pageSpacing), child:
        Container(decoration: BoxDecoration(color: Styles().colors.surface, borderRadius: BorderRadius.circular(5)), child:
          HomeProgressWidget(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: (_pageHeight - 24) / 2),
            progessSize: Size(24, 24),
            progressColor: Styles().colors.fillColorPrimary,
          ),
        ),
      ));
    }

    if (_pageController == null) {
      double screenWidth = MediaQuery.of(context).size.width;
      double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
      _pageController = PageController(viewportFraction: pageViewport);
    }

    contentWidget = Container(constraints: BoxConstraints(minHeight: _pageHeight), child:
      ExpandablePageView(
        key: _pageViewKey,
        controller: _pageController,
        estimatedPageSize: _pageHeight,
        onPageChanged: _onPageChanged,
        allowImplicitScrolling: true,
        children: pages,
      ),
    );

    return Column(children: <Widget>[
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => pages.length, centerWidget:
        LinkButton(
          title: Localization().getStringEx('widget.home.recent_polls.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.recent_polls.button.all.hint', 'Tap to view all polls'),
          textStyle: Styles().textStyles.getTextStyle('widget.description.regular.light.underline'),
          onTap: _onTapSeeAll,
        ),
      ),
    ]);
  }

  void _onPageChanged(int index) {
    if (((_recentPolls?.length ?? 0) <= (index + 1)) && _hasMorePolls && !_loadingPollsPage) {
      _loadNextPollsPage();
    }
  }

  Group? _getGroup(String? groupId) {
    List<Group>? groups = Groups().userGroups;
    if (StringUtils.isNotEmpty(groupId) && CollectionUtils.isNotEmpty(groups)) {
      for (Group group in groups!) {
        if (groupId == group.id) {
          return group;
        }
      }
    }
    return null;
  }

  double get _pageHeight {

    double? minContentHeight;
    for(GlobalKey contentKey in _contentKeys.values) {
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
        return min(5, (_recentPolls?.length ?? 1));
      case ScreenType.tablet:
        return min(3, (_recentPolls?.length ?? 1));
      case ScreenType.phone:
        return 1;
      default:
        return 1;
    }
  }

  void _onTapSeeAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PollsHomePanel()));
  }

  void _refreshPolls({bool showProgress = false, bool initResult = false}) {
    if (Connectivity().isOnline && Auth2().isLoggedIn && (_loadingPolls != true)) {
      if (showProgress && mounted) {
        setState(() {
          _loadingPolls = true;
        });
      }
      Polls().getRecentPolls(cursor: PollsCursor(offset: 0, limit: max(_recentPolls?.length ?? 0, Config().homeRecentPollsCount + 1)))?.then((PollsChunk? result) {
        if (initResult || ((result?.polls != null) && !DeepCollectionEquality().equals(_recentPolls, result?.polls))) {
          setStateIfMounted(() {
            _recentPolls = result?.polls;
            _pageViewKey = UniqueKey();
            _pageController?.jumpToPage(0);
            _contentKeys.clear();
          });
        }
      }).catchError((_){
        if (initResult) {
          setStateIfMounted(() {
            _recentPolls = null;
            _pageViewKey = UniqueKey();
            _pageController?.jumpToPage(0);
            _contentKeys.clear();
          });
        }
      }).whenComplete((){
        if (showProgress && mounted) {
          setState(() {
            _loadingPolls = false;
          });
        }
      });
    }
  }

  void _loadNextPollsPage() {
    if (Connectivity().isOnline && _hasMorePolls && !_loadingPollsPage) {
      setStateIfMounted(() {
        _loadingPollsPage = true;
      });
      Polls().getRecentPolls(cursor: PollsCursor(offset: _recentPolls?.length, limit: Config().homeRecentPollsCount + 1))?.then((PollsChunk? result) {
        setStateIfMounted(() {
          if (result?.polls != null) {
            _hasMorePolls = result?.polls?.isNotEmpty ?? false;
            if (_recentPolls != null) {
              _recentPolls?.addAll(result!.polls!);
            }
            else {
              _recentPolls = result?.polls;
            }
          }
        });
      }).catchError((_){

      }).whenComplete((){
        setStateIfMounted(() {
          _loadingPollsPage = false;
        });
      });
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _refreshPolls();
        }
      }
    }
  }

  void _onContentAvailabilityChanged(bool available) {
    if (available) {
      _refreshPolls(showProgress: true, initResult: true);
    }
    else {
      setStateIfMounted();
    }
  }

  void _onPollCreated(String? pollId) {
    _refreshPolls();
  }

  void _onPollUpdated(String? pollId) {
    Poll? poll = Polls().getPoll(pollId: pollId);
    if (poll != null) {
      setState(() {
        _updatePoll(poll);
      });
    }
  }

  void _updatePoll(Poll poll) {
    if (_recentPolls != null) {
      for (int index = 0; index < _recentPolls!.length; index++) {
        if (_recentPolls![index].pollId == poll.pollId) {
          _recentPolls![index] = poll;
        }
      }
    }
  }
}

class HomeCreatePollWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeCreatePollWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
      HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
        title: title,
      );

  static String get title => Localization().getStringEx("widget.home_create_poll.heading.title", "CREATE POLL");

  @override
  _HomeCreatePollWidgetState createState() => _HomeCreatePollWidgetState();
}

class _HomeCreatePollWidgetState extends State<HomeCreatePollWidget> {
  bool _visible = true;
  bool _authLoading = false;

  @override
  Widget build(BuildContext context) {

    return Visibility(visible: _visible, child:
      HomeBannerSubsectionWidget(
        title: HomeCreatePollWidget.title,
        // childPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: _buildContent(),
      )
    );
  }

  Widget _buildContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text(Localization().getStringEx("widget.home_create_poll.text.title","Quickly Create and Share Polls."), style: Styles().textStyles.getTextStyle("widget.title.dark.large.extra_fat")),
      Padding(padding: EdgeInsets.symmetric(vertical: 10), child:
        Text(_canCreatePoll ?
        Localization().getStringEx("widget.home_create_poll.text.description", "People in your Group can be notified to vote through the {{app_title}} app. Or you can give voters the four-digit poll number.").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')) :
        AppTextUtils.loggedOutFeatureNA(Localization().getStringEx('generic.app.feature.polls', 'Polls')),
            style: Styles().textStyles.getTextStyle("widget.description.medium.regular")
        ),
      ),
      _buildButtons()
    ],);
  }

  Widget _buildButtons(){
    return _canCreatePoll?
    RoundedButton(
      label: Localization().getStringEx("widget.home_create_poll.button.create_poll.label","Create a Poll"),
      textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
      borderColor: Styles().colors.fillColorSecondary,
      backgroundColor: Colors.white,
      contentWeight: 0.6,
      conentAlignment: MainAxisAlignment.start,
      onTap: _onCreatePoll,
    ) :
    Padding(padding: EdgeInsets.only(right: 120), child:
      RoundedButton(
        label: Localization().getStringEx("widget.home_create_poll.button.login.label","Login"),
        textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
        borderColor: Styles().colors.fillColorSecondary,
        backgroundColor: Colors.white,
        progress: _authLoading,
        onTap: _onLogin,
      ),
    );
  }

  void _onCreatePoll() {
    Analytics().logSelect(target: "Create Poll", source: widget.runtimeType.toString());
    CreatePollPanel.present(context);
  }

  bool get _canCreatePoll {
    return Auth2().isLoggedIn;
  }

  void _onLogin(){
    Analytics().logSelect(target: "Login", source: widget.runtimeType.toString());
    if (_authLoading != true) {
      setState(() { _authLoading = true; });
      Auth2().authenticateWithOidc().then((Auth2OidcAuthenticateResult? result) {
        if (mounted) {
          setState(() { _authLoading = false; });
          if (result?.status != Auth2OidcAuthenticateResultStatus.succeeded) {
            AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
          }
        }
      });
    }
  }
}