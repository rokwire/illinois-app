
import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/polls/PollsHomePanel.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeRecentPollsWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeRecentPollsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.recent_polls.text.title', 'Recent Polls');

  State<HomeRecentPollsWidget> createState() => _HomeRecentPollsWidgetState();
}

class _HomeRecentPollsWidgetState extends State<HomeRecentPollsWidget> implements NotificationsListener {

  List<Poll>? _recentPolls;
  bool _loadingPolls = false;
  DateTime? _pausedDateTime;

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
        titleIcon: Image.asset('images/icon-news.png'),
        child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (Connectivity().isOffline) {
      return HomeMessageCard(
        title: Localization().getStringEx("app.offline.message.title", "You appear to be offline"),
        message: Localization().getStringEx("widget.home.recent_polls.text.offline", "Recent Polls are not available while offline"),);
    }
    else if (_loadingPolls) {
      return HomeProgressWidget();
    }
    else if (CollectionUtils.isEmpty(_recentPolls)) {
      return HomeMessageCard(
        title: Localization().getStringEx("widget.home.recent_polls.text.empty", "Whoops! Nothing to see here."),
        message: Localization().getStringEx("widget.home.recent_polls.text.empty.description", "No Recent Polls are available right now."),);
    }
    else {
      return _buildPollsContent();
    }

  }

  Widget _buildPollsContent() {
    List<Widget> contentList = [];
    if (_recentPolls != null) {
      int count = min(Config().homeRecentPollsCount, _recentPolls?.length ?? 0);
      for (int index = 0; index < count; index++) {
        if (0 < index) {
          contentList.add(Container(height: 8,));
        }
        Poll poll = _recentPolls![index];
        contentList.add(PollCard(poll: poll, group: _getGroup(poll.groupId)));
      }
      if (Config().homeRecentPollsCount < (_recentPolls?.length ?? 0)) {
        contentList.add(
            LinkButton(
              title: Localization().getStringEx('widget.home.recent_polls.button.all.title', 'View All'),
              hint: Localization().getStringEx('widget.home.recent_polls.button.all.hint', 'Tap to view all news'),
              onTap: _onTapSeeAll,
            ),
        );
      }
    }
    return Column(children: contentList,);
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

  void _onTapSeeAll() {
    Analytics().logSelect(target: "HomeRecentPolls: View All");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PollsHomePanel()));
  }

  void _refreshPolls({bool showProgress = false}) {
    if (Connectivity().isOnline) {
      if (showProgress && mounted) {
        setState(() {
          _loadingPolls = true;
        });
      }
      Polls().getRecentPolls(cursor: PollsCursor(offset: 0, limit: Config().homeRecentPollsCount + 1))?.then((PollsChunk? result) {
        if (mounted) {
          setState(() {
            if (showProgress) {
              _loadingPolls = false;
            }
            if (result?.polls != null) {
              _recentPolls = result?.polls;
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