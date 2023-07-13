
import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/polls/PollsHomePanel.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeRecentPollsWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeRecentPollsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.recent_polls.text.title', 'Recent Polls');

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

  @override
  void initState() {

    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      AppLivecycle.notifyStateChanged,
      Config.notifyConfigChanged,
      Polls.notifyCreated,
      Polls.notifyStatusChanged,
      Polls.notifyVoteChanged,
      Polls.notifyResultsChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _refreshPolls(showProgress: true);
        }
      });
    }

    if (Connectivity().isOnline) {
      _loadingPolls = true;
      Polls().getRecentPolls(cursor: PollsCursor(offset: 0, limit: Config().homeRecentPollsCount + 1))?.then((PollsChunk? result) {
        setStateIfMounted(() {
          _loadingPolls = false;
          _recentPolls = result?.polls;
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
      _refreshPolls();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == Config.notifyConfigChanged) {
      if (mounted) {
        setState(() {});
      }
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
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: HomeRecentPollsWidget.title,
      titleIconKey: 'polls',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (Connectivity().isOffline) {
      return HomeMessageCard(
        title: Localization().getStringEx("common.message.offline", "You appear to be offline"),
        message: Localization().getStringEx("widget.home.recent_polls.text.offline", "Recent Polls are not available while offline"),);
    }
    else if (_loadingPolls) {
      return HomeProgressWidget();
    }
    else if (CollectionUtils.isEmpty(_recentPolls)) {
      return HomeMessageCard(
        message: Localization().getStringEx("widget.home.recent_polls.text.empty.description", "No Recent Polls are available right now."),);
    }
    else {
      return _buildPollsContent();
    }

  }

  Widget _buildPollsContent() {
    Widget contentWidget;
    List<Widget> pages = <Widget>[];

    if (1 < (_recentPolls?.length ?? 0)) {

      for (Poll poll in _recentPolls!) {
        pages.add(Padding(key: _contentKeys[poll.pollId ?? ''] ??= GlobalKey(), padding: EdgeInsets.only(right: _pageSpacing), child:
          PollCard(poll: poll, group: _getGroup(poll.groupId)),
        ));
      }

      if (_loadingPollsPage) {
        pages.add(Padding(key: _contentKeys['last'] ??= GlobalKey(), padding: EdgeInsets.only(right: _pageSpacing), child:
          Container(decoration: BoxDecoration(color: Styles().colors?.white, borderRadius: BorderRadius.circular(5)), child:
            HomeProgressWidget(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: (_pageHeight - 24) / 2),
              progessSize: Size(24, 24),
              progressColor: Styles().colors?.fillColorPrimary,
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
    }
    else {
      contentWidget = Padding(padding: EdgeInsets.only(left: 16, right: 16), child:
        PollCard(poll: _recentPolls?.first, group: _getGroup(_recentPolls?.first.groupId))
      );
    }

    return Column(children: <Widget>[
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => pages.length, centerWidget:
        LinkButton(
          title: Localization().getStringEx('widget.home.recent_polls.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.recent_polls.button.all.hint', 'Tap to view all polls'),
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
      if ((renderBox is RenderBox) && ((minContentHeight == null) || (renderBox.size.height < minContentHeight))) {
        minContentHeight = renderBox.size.height;
      }
    }

    return minContentHeight ?? 0;
  }

  void _onTapSeeAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PollsHomePanel()));
  }

  void _refreshPolls({bool showProgress = false}) {
    if (Connectivity().isOnline) {
      if (showProgress && mounted) {
        setState(() {
          _loadingPolls = true;
        });
      }
      Polls().getRecentPolls(cursor: PollsCursor(offset: 0, limit: max(_recentPolls?.length ?? 0, Config().homeRecentPollsCount + 1)))?.then((PollsChunk? result) {
        if (mounted) {
          setState(() {
            if (showProgress) {
              _loadingPolls = false;
            }
            if ((result?.polls != null) && !DeepCollectionEquality().equals(_recentPolls, result?.polls)) {
              _recentPolls = result?.polls;
              _pageViewKey = UniqueKey();
              // _pageController = null;
              _pageController?.jumpToPage(0);
              _contentKeys.clear();
            }
          });
        }
      });
    }
  }

  void _loadNextPollsPage() {
    if (Connectivity().isOnline && _hasMorePolls && !_loadingPollsPage) {
      if (mounted) {
        setState(() {
          _loadingPollsPage = true;
        });
      }
      Polls().getRecentPolls(cursor: PollsCursor(offset: _recentPolls?.length, limit: Config().homeRecentPollsCount + 1))?.then((PollsChunk? result) {
        if (mounted) {
          setState(() {
            _loadingPollsPage = false;
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
        }
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