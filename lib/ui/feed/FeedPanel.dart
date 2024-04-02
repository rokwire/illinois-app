import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/model/Appointment.dart';
import 'package:illinois/model/Feed.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/model/Twitter.dart';
import 'package:illinois/model/wellness/WellnessToDo.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Feed.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/academics/StudentCourses.dart';
import 'package:illinois/ui/appointments/AppointmentCard.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsCard.dart';
import 'package:illinois/ui/athletics/AthleticsWidgets.dart';
import 'package:illinois/ui/events2/Event2DetailPanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/guide/GuideEntryCard.dart';
import 'package:illinois/ui/home/HomeTwitterWidget.dart';
import 'package:illinois/ui/notifications/NotificationsHomePanel.dart';
import 'package:illinois/ui/notifications/NotificationsInboxPage.dart';
import 'package:illinois/ui/wellness/WellnessDailyTipsContentWidget.dart';
import 'package:illinois/ui/wellness/todo/WellnessToDoHomeContentWidget.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class FeedPanel extends StatefulWidget {
  FeedPanel();

  @override
  _FeedPanelState createState() => _FeedPanelState();
}

class _FeedPanelState extends State<FeedPanel> with AutomaticKeepAliveClientMixin<FeedPanel> implements NotificationsListener {

  static const int _pageLength = 8;

  List<FeedItem>? _feed;
  bool? _loadedAll;
  bool _loading = false;
  bool _loadingLocation = false;
  bool _refreshing = false;
  bool _extending = false;

  LocationServicesStatus? _locationServicesStatus;
  Position? _currentLocation;

  ScrollController _scrollController = ScrollController();
  DateTime? _pausedDateTime;


  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      FlexUI.notifyChanged,
    ]);
    _scrollController.addListener(_scrollListener);

    _initLocationServicesStatus().then((_) {
      _ensureCurrentLocation();
      _load();
    });

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

  // AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;


  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == FlexUI.notifyChanged) {
      _currentLocation = null;
      _updateLocationServicesStatus().then((_) {
        _ensureCurrentLocation();
      });
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _currentLocation = null;
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateLocationServicesStatus().then((_) {
            _ensureCurrentLocation();
            _refresh();
          });
        }
      }
    }
  }

  // Widgets Content

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.feeds.label.title', 'Feed')),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child:
        Column(children: <Widget>[
          Expanded(child:
            SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), child:
              _feedContent
            )
          ),
        ]),
      ),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: null,
    );
  }

  Widget get _feedContent {
    if (_loading || _loadingLocation) {
      return _loadingFeedContent;
    }
    else if (_refreshing) {
      return Container();
    }
    else if (_feed == null) {
      return _messageContent(Localization().getStringEx('panel.feeds.message.failed.description', 'Failed to load feed content.'));
    }
    else if (_feed?.length == 0) {
      return _messageContent(Localization().getStringEx('panel.feeds.message.empty.description', 'There is no feed content available right now.'),);
    }
    else {
      return _feedList;
    }
  }

  Widget get _feedList {
    List<Widget> widgetList = <Widget>[];
    for (FeedItem feedItem in _feed!) {
      Widget? feedItemWidget = _feedItemContent(feedItem);
      if (feedItemWidget != null) {
        widgetList.add(Padding(padding: EdgeInsets.only(top: 8), child:
          feedItemWidget,
        ),);
      }
    }
    if (_extending) {
      widgetList.add(Padding(padding: EdgeInsets.only(top: 8), child:
        _extendingListItem
      ));
    }
    return Padding(padding: EdgeInsets.only(top: 8, bottom: 16), child:
      Column(children: widgetList,)
    );
  }

  Widget? _feedItemContent(FeedItem feedItem) {
    if ((feedItem.type == FeedItemType.event) && (feedItem.data is Event2)) {
      Event2 event = feedItem.data as Event2;
      return event.hasGame ?
        AthleticsEventCard(sportEvent: event, showImage: true, onTap: () => _onEvent(event)) :
        _CardWrapper(child: Event2Card(feedItem.data as Event2, userLocation: _currentLocation, onTap: () => _onEvent(event),),);
    }
    else if ((feedItem.type == FeedItemType.notification) && (feedItem.data is InboxMessage)) {
      return _CardWrapper(child: InboxMessageCard(message: feedItem.data as InboxMessage, onTap: () => _onNotification(feedItem.data as InboxMessage),),
      );
    }
    else if ((feedItem.type == FeedItemType.appointment) && (feedItem.data is Appointment)) {
      return _CardWrapper(child: AppointmentCard(appointment: feedItem.data as Appointment),);
    }
    else if ((feedItem.type == FeedItemType.studentCourse) && (feedItem.data is StudentCourse)) {
      return _CardWrapper(child: StudentCourseCard(course: feedItem.data as StudentCourse),);
    }
    else if ((feedItem.type == FeedItemType.campusReminder) && (feedItem.data is Map<String, dynamic>)) {
      return _CardWrapper(child: GuideEntryCard(JsonUtils.mapValue(feedItem.data)),);
    }
    else if ((feedItem.type == FeedItemType.sportNews) && (feedItem.data is News)) {
      return _CardWrapper(child: AthleticsNewsCard(news: feedItem.data as News));
    }
    else if ((feedItem.type == FeedItemType.tweet) && (feedItem.data is Tweet)) {
      return _CardWrapper(child: TweetWidget(tweet: feedItem.data as Tweet),);
    }
    else if ((feedItem.type == FeedItemType.wellnessToDo) && (feedItem.data is WellnessToDoItem)) {
      return _CardWrapper(child: WellnessToDoItemCard(item: feedItem.data as WellnessToDoItem));
    }
    else if ((feedItem.type == FeedItemType.wellnessTip) && (feedItem.data is Map<String, dynamic>)) {
      Map<String, dynamic> tipData = feedItem.data as Map<String, dynamic>;
      return _CardWrapper(child: WellnessTipWidget(
        text: JsonUtils.stringValue(tipData['text']) ?? '',
        decoration: BoxDecoration(
          color: ColorUtils.fromHex(JsonUtils.stringValue(tipData['color'])) ?? Styles().colors.accentColor3,
          border: Border.all(color: Styles().colors.mediumGray2, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(8))
        ),
      ));
    }
    else {
      return null;
    }
  }

  Widget _messageContent(String message, { String? title }) =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: _screenHeight / 6), child:
      Column(children: [
        (title != null) ? Padding(padding: EdgeInsets.only(bottom: 12), child:
          Text(title, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.item.medium.fat'),)
        ) : Container(),
        Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle((title != null) ? 'widget.item.regular.thin' : 'widget.item.medium.fat'),),
      ],),
    );

  Widget get _loadingFeedContent => Container(padding: EdgeInsets.symmetric(vertical: _screenHeight / 4), child:
    Align(alignment: Alignment.center, child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary,)
      )
    ),
  );

  Widget get _extendingListItem => Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32), child:
    Align(alignment: Alignment.center, child:
      SizedBox(width: 24, height: 24, child:
        CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary),),
      ),
    ),
  );

  double get _screenHeight => MediaQuery.of(context).size.height;

  Future<void> _onPullToRefresh() {
    Analytics().logSelect(target: 'Refresh');
    return _refresh();
  }

  void _scrollListener() {
    if ((_scrollController.offset >= _scrollController.position.maxScrollExtent) && _moreFeedAvailabe && !_loading && !_refreshing && !_extending) {
      _extend();
    }
  }

  // Feed Content Supply

  bool get _moreFeedAvailabe => (_loadedAll != true);

  Future<void> _load({int limit = _pageLength}) async {
    if ((_loading != true) && (_refreshing != true)) {
      setStateIfMounted(() {
        _loading = true;
        _extending = false;
      });

      List<FeedItem>? result = await Feed().load(offset: 0, limit: limit);

      setStateIfMounted(() {
        _feed = (result != null) ? List<FeedItem>.from(result) : null;
        _loadedAll = (result != null) ? (result.length < limit) : null;
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if ((_loading != true) && (_refreshing != true)) {
      setStateIfMounted(() {
        _refreshing = true;
        _extending = false;
      });

      int limit = max(_feed?.length ?? 0, _pageLength);
      List<FeedItem>? result = await Feed().load(offset: 0, limit: limit);

      setStateIfMounted(() {
        if (result != null) {
          _feed = List<FeedItem>.from(result);
          _loadedAll = (result.length < limit);
        }
        _refreshing = false;
      });
    }
  }

  Future<void> _extend() async {
    if ((_loading != true) && (_refreshing != true) && (_extending != true)) {
      setStateIfMounted(() {
        _extending = true;
      });

      int offset = _feed?.length ?? 0;
      int limit = _pageLength;
      List<FeedItem>? result = await Feed().load(offset: offset, limit: limit);

      if ((_extending == true) && (_loading != true) && (_refreshing != true)) {
        setStateIfMounted(() {
          if (result != null) {
            if (_feed != null) {
              _feed?.addAll(result);
            }
            else {
              _feed = List<FeedItem>.from(result);
            }
            _loadedAll = (result.length < limit);
          }
          _extending = false;
        });
      }
    }
  }

  // Location Status and Position

  Future<void> _initLocationServicesStatus() async {
    setStateIfMounted(() {
      _loadingLocation = true;
    });
    LocationServicesStatus? locationServicesStatus = await _getLocationServicesStatus();
      setStateIfMounted(() {
        if (locationServicesStatus != null) {
          _locationServicesStatus = locationServicesStatus;
        }
        _loadingLocation = false;
      });
  }

  Future<void> _updateLocationServicesStatus() async {
    LocationServicesStatus? locationServicesStatus = await _getLocationServicesStatus();
    if (_locationServicesStatus != locationServicesStatus) {
      setStateIfMounted(() {
        _locationServicesStatus = locationServicesStatus;
      });
    }
  }

  Future<Position?> _ensureCurrentLocation({ bool prompt = false}) async {
    if (_currentLocation == null) {
      if (prompt && (_locationServicesStatus == LocationServicesStatus.permissionNotDetermined)) {
        LocationServicesStatus? locationServicesStatus = await LocationServices().requestPermission();
        setStateIfMounted(() {
          _locationServicesStatus = locationServicesStatus;
        });
      }
      if (mounted && (_locationServicesStatus == LocationServicesStatus.permissionAllowed)) {
        Position? currentLocation = await LocationServices().location;
        setStateIfMounted(() {
          _currentLocation = currentLocation;
        });
      }
    }
    return _currentLocation;
  }

  Future<LocationServicesStatus?> _getLocationServicesStatus() async =>
    FlexUI().isLocationServicesAvailable ? await LocationServices().status : LocationServicesStatus.serviceDisabled;

  Future<Position?> getUserLocationIfAvailable() async =>
    ((await _getLocationServicesStatus()) == LocationServicesStatus.permissionAllowed) ?
      await LocationServices().location : null;

  // Feed Detail Handlers

  void _onEvent(Event2 event) {
    Analytics().logSelect(target: 'Event: ${event.name}');
    if (event.hasGame) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(game: event.game, event: event)));
    } else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2DetailPanel(event: event, userLocation: _currentLocation,)));
    }
  }

  void _onNotification(InboxMessage message) {
    Analytics().logSelect(target: 'Notification: ${message.subject}');
    NotificationsHomePanel.launchMessageDetail(message);
  }
}

class _CardWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  // ignore: unused_element
  _CardWrapper({super.key, required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 16)});

  @override
  Widget build(BuildContext context) => Container(padding: padding, child: child);
}