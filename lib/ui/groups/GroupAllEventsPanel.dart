import 'package:flutter/material.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/groups/GroupWidgets.dart';

class GroupAllEventsPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Group? group;

  const GroupAllEventsPanel({Key? key, this.group}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupAllEventsState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes => group?.analyticsAttributes;
}

class _GroupAllEventsState extends State<GroupAllEventsPanel>{
  List<Event2>? _events;
  bool? _lastPageLoadedAll;
  int? _totalEventsCount;
  bool _loadingEvents = false;
  bool _extendingEvents = false;
  static const int _eventsPageLength = 16;

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    _scrollController.addListener(_scrollListener);
    _load();
    super.initState();
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
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: uiuc.TabBar());
  }

  Widget _buildEvents() {
    List<Widget> content = <Widget>[];

    if (_events != null) {
      for (Event2? groupEvent in _events!) {
        content.add(GroupEventCard(groupEvent: groupEvent, group: widget.group));
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
                width: 32, height: 32, child: CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 3))));
  }

  Widget get _extendingIndicator => Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Align(
          alignment: Alignment.center,
          child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary)))));

  void _load() {
    if (!_loadingEvents) {
      setStateIfMounted(() {
        _loadingEvents = true;
        _extendingEvents = false;
      });

      Groups().loadEventsV3(widget.group?.id, limit: _eventsPageLength).then((Events2ListResult? eventsResult) {
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

      Events2ListResult? listResult = await Groups().loadEventsV3(widget.group?.id, offset: _events?.length ?? 0, limit: _eventsPageLength);
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

  bool? get _hasMoreEvents => (_totalEventsCount != null) ? ((_events?.length ?? 0) < _totalEventsCount!) : _lastPageLoadedAll;
}