import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neom/ext/Event2.dart';
import 'package:neom/model/Analytics.dart';
import 'package:neom/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:neom/ui/events2/Event2DetailPanel.dart';
import 'package:neom/ui/events2/Event2Widgets.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:neom/ext/Group.dart';
import 'package:neom/service/Analytics.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:neom/ui/widgets/TabBar.dart' as uiuc;

class GroupAllEventsPanel extends StatefulWidget with AnalyticsInfo {
  final Group? group;

  const GroupAllEventsPanel({Key? key, this.group}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupAllEventsState();

  @override
  AnalyticsFeature? get analyticsFeature => (group?.researchProject == true) ? AnalyticsFeature.ResearchProject : AnalyticsFeature.Groups;

  @override
  Map<String, dynamic>? get analyticsPageAttributes => group?.analyticsAttributes;
}

class _GroupAllEventsState extends State<GroupAllEventsPanel> implements NotificationsListener {
  List<Event2>? _events;
  bool? _lastPageLoadedAll;
  int? _totalEventsCount;
  bool _loadingEvents = false;
  bool _extendingEvents = false;
  static const int _eventsPageLength = 16;

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Events2.notifyUpdated,
      Groups.notifyGroupEventsUpdated,
    ]);
    _scrollController.addListener(_scrollListener);
    _load();
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
    if (name == Events2.notifyUpdated) {
      _updateEventIfNeeded(param);
    } else if (name == Groups.notifyGroupEventsUpdated) {
      if ((param is String) && (param == widget.group!.id)) {
        _reload();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(
            title: Localization().getStringEx("panel.groups_all_events.label.heading", "Upcoming Events") +
                ((_totalEventsCount != null) ? " ($_totalEventsCount)" : "")),
        body: SingleChildScrollView(
            controller: _scrollController,
            child: Column(children: <Widget>[
              Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18), child: _loadingEvents ? _loadingIndicator : _buildEvents())
            ])),
        backgroundColor: Styles().colors.background,
        bottomNavigationBar: uiuc.TabBar());
  }

  Widget _buildEvents() {
    List<Widget> content = <Widget>[];

    if (_events != null) {
      for (Event2 groupEvent in _events!) {
        content.add(Padding(padding: EdgeInsets.only(bottom: 16), child: Event2Card(groupEvent, group: widget.group, onTap: () => _onTapEvent(groupEvent))));
      }

      if (_extendingEvents) {
        content.add(Padding(padding: EdgeInsets.only(top: content.isNotEmpty ? 8 : 0), child: _extendingIndicator));
      }
    }

    return Column(children: content);
  }

  Widget get _loadingIndicator {
    return Padding(
        padding: EdgeInsets.only(top: 150),
        child: Center(
            child: SizedBox(
                width: 32, height: 32, child: CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3))));
  }

  Widget get _extendingIndicator => Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Align(
          alignment: Alignment.center,
          child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary)))));

  void _load() {
    if (!_loadingEvents) {
      setStateIfMounted(() {
        _loadingEvents = true;
        _extendingEvents = false;
      });

      Events2().loadGroupEvents(groupId: widget.group?.id, limit: _eventsPageLength).then((Events2ListResult? eventsResult) {
        List<Event2>? events = eventsResult?.events;

        setStateIfMounted(() {
          _events = (events != null) ? List<Event2>.from(events) : null;
          _totalEventsCount = eventsResult?.totalCount;
          _lastPageLoadedAll = (events != null) ? (events.length >= _eventsPageLength) : null;
          _loadingEvents = false;
        });
      });
    }
  }

  void _updateEventIfNeeded(dynamic event) {
    if ((event is Event2) && (event.id != null) && mounted) {
      int? index = Event2.indexInList(_events, id: event.id);
      if (index != null) {
        setState(() {
          _events?[index] = event;
        });
      }
    }
  }

  void _scrollListener() {
    if ((_scrollController.offset >= _scrollController.position.maxScrollExtent) &&
        (_hasMoreEvents != false) &&
        !_loadingEvents &&
        !_extendingEvents) {
      _extend();
    }
  }

  Future<void> _extend() async {
    if (!_loadingEvents && !_extendingEvents) {
      setStateIfMounted(() {
        _extendingEvents = true;
      });

      Events2ListResult? listResult = await Events2().loadGroupEvents(groupId: widget.group?.id, offset: _events?.length ?? 0, limit: _eventsPageLength);
      List<Event2>? events = listResult?.events;
      int? totalCount = listResult?.totalCount;

      if (mounted && _extendingEvents && !_loadingEvents) {
        setState(() {
          if (events != null) {
            if (_events != null) {
              _events?.addAll(events);
            } else {
              _events = List<Event2>.from(events);
            }
            _lastPageLoadedAll = (events.length >= _eventsPageLength);
          }
          if (totalCount != null) {
            _totalEventsCount = totalCount;
          }
          _extendingEvents = false;
        });
      }
    }
  }

  void _reload() {
    if (!_loadingEvents && !_extendingEvents) {
      setStateIfMounted(() {
        _loadingEvents = true;
        _extendingEvents = false;
      });
      int limit = _events?.length ?? 0;
      Events2().loadGroupEvents(groupId: widget.group!.id!, offset: 0, limit: limit).then((result) {
        Events2ListResult? listResult = (result is Events2ListResult) ? result : null;
        List<Event2>? events = listResult?.events;

        setStateIfMounted(() {
          _events = (events != null) ? List<Event2>.from(events) : null;
          _totalEventsCount = listResult?.totalCount;
          _lastPageLoadedAll = (events != null) ? (events.length >= limit) : null;
          _loadingEvents = false;
        });
      });
    }
  }

  void _onTapEvent(Event2 event) {
    Analytics().logSelect(target: 'Group Event: ${event.name}');
    if (event.hasGame) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(game: event.game, event: event, group: widget.group,)));
    }
    else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2DetailPanel(event: event, group: widget.group)));
    }
  }

  bool? get _hasMoreEvents => (_totalEventsCount != null) ? ((_events?.length ?? 0) < _totalEventsCount!) : _lastPageLoadedAll;
}