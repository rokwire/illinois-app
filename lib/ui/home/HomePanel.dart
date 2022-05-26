/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/home/HomeCanvasCoursesWidget.dart';
import 'package:illinois/ui/home/HomeFavoritesWidget.dart';
import 'package:illinois/ui/home/HomeGiesWidget.dart';
import 'package:illinois/ui/home/HomeWPGUFMRadioWidget.dart';
import 'package:illinois/ui/home/HomeWalletWidget.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/LiveStats.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/home/HomeCampusRemindersWidget.dart';
import 'package:illinois/ui/home/HomeCampusToolsWidget.dart';
import 'package:illinois/ui/home/HomeCreatePollWidget.dart';
import 'package:illinois/ui/home/HomeGameDayWidget.dart';
import 'package:illinois/ui/home/HomeHighligtedFeaturesWidget.dart';
import 'package:illinois/ui/home/HomeLoginWidget.dart';
import 'package:illinois/ui/home/HomeMyGroupsWidget.dart';
import 'package:illinois/ui/home/HomePreferredSportsWidget.dart';
import 'package:illinois/ui/home/HomeRecentItemsWidget.dart';
import 'package:illinois/ui/home/HomeSaferWidget.dart';
import 'package:illinois/ui/home/HomeCampusHighlightsWidget.dart';
import 'package:illinois/ui/home/HomeTwitterWidget.dart';
import 'package:illinois/ui/home/HomeVoterRegistrationWidget.dart';
import 'package:illinois/ui/home/HomeUpcomingEventsWidget.dart';
import 'package:illinois/ui/widgets/FlexContent.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class HomePanel extends StatefulWidget {
  @override
  _HomePanelState createState() => _HomePanelState();
}

class _HomePanelState extends State<HomePanel> with AutomaticKeepAliveClientMixin<HomePanel> implements NotificationsListener, HomeScrollableDragging {
  
  List<String>? _contentListCodes;
  StreamController<void> _refreshController = StreamController.broadcast();
  HomeSaferWidget? _saferWidget;
  GlobalKey _saferKey = GlobalKey();
  GlobalKey _contentWrapperKey = GlobalKey();
  ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  bool isDragging = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Localization.notifyStringsUpdated,
      FlexUI.notifyChanged,
      Styles.notifyChanged,
      Assets.notifyChanged,
      HomeSaferWidget.notifyNeedsVisiblity,
    ]);
    _contentListCodes = JsonUtils.listStringsValue(FlexUI()['home'])  ?? [];
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _refreshController.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.home.header.title', 'ILLINOIS')),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child:
        Listener(onPointerMove: _onPointerMove, onPointerUp: (_) => _onPointerCancel, onPointerCancel: (_) => _onPointerCancel, child:
          Column(key: _contentWrapperKey, children: <Widget>[
            Expanded(child:
              SingleChildScrollView(controller: _scrollController, child:
                Column(children: _buildContentList(),)
              )
            ),
          ]),
        ),
      ),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: null,
    );
  }

  List<Widget> _buildContentList() {

    List<Widget> widgets = [];
    HomeSaferWidget? saferWidget;

    for (String code in _contentListCodes!) {
      Widget? widget;

      if (code == 'game_day') {
        widget = HomeGameDayWidget(favoriteId: code, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'campus_tools') {
        widget = HomeCampusToolsWidget(favoriteId: code, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'pref_sports') {
        widget = HomePreferredSportsWidget(menSports: true, womenSports: true, favoriteId: code, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'campus_reminders') {
        widget = HomeCampusRemindersWidget(favoriteId: code, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'upcoming_events') {
        widget = HomeUpcomingEventsWidget(favoriteId: code, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'recent_items') {
        widget = HomeRecentItemsWidget(favoriteId: code, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'campus_highlights') {
        widget = HomeCampusHighlightsWidget(favoriteId: code, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'twitter') {
        widget = HomeTwitterWidget(favoriteId: code, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'gies') {
        widget = HomeGiesWidget(favoriteId: code, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'canvas') {
        widget = HomeCanvasCoursesWidget(refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'voter_registration') {
        widget = HomeVoterRegistrationWidget(favoriteId: code, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'create_poll') {
        widget = HomeCreatePollWidget(favoriteId: code, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'connect') {
        widget = HomeLoginWidget(refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'highlighted_features') {
        widget = HomeHighlightedFeatures(favoriteId: code, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'my_groups') {
        widget = HomeMyGroupsWidget(favoriteId: code, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'safer') {
        widget = saferWidget = _saferWidget ??= HomeSaferWidget(key: _saferKey, favoriteId: code, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'wallet') {
        widget = HomeWalletWidget(favoriteId: code, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'wpgufm_radio') {
        widget = HomeWPGUFMRadioWidget(favoriteId: code, refreshController: _refreshController, scrollableDragging: this,);
      }

      // Favs

      else if (code == 'events_favs') {
        widget = HomeFavoritesWidget(favoriteId: code, favoriteKey: Event.favoriteKeyName, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'dining_favs') {
        widget = HomeFavoritesWidget(favoriteId: code, favoriteKey: Dining.favoriteKeyName, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'athletics_favs') {
        widget = HomeFavoritesWidget(favoriteId: code, favoriteKey: Game.favoriteKeyName, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'news_favs') {
        widget = HomeFavoritesWidget(favoriteId: code, favoriteKey: News.favoriteKeyName, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'laundry_favs') {
        widget = HomeFavoritesWidget(favoriteId: code, favoriteKey: LaundryRoom.favoriteKeyName, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'inbox_favs') {
        widget = HomeFavoritesWidget(favoriteId: code, favoriteKey: InboxMessage.favoriteKeyName, refreshController: _refreshController, scrollableDragging: this,);
      }
      else if (code == 'campus_guide_favs') {
        widget = HomeFavoritesWidget(favoriteId: code, favoriteKey: GuideFavorite.favoriteKeyName, refreshController: _refreshController, scrollableDragging: this,);
      }

      // Assets widget

      else {
        widget = FlexContent.fromAssets(code);
      }

      if (widget != null) {
        widgets.add(widget);
      }
    }

    if ((saferWidget == null) && (_saferWidget != null)) {
      _saferWidget = null; // Clear the cached HomeSaferWidget if not Safer indget in Home content.
    }

    return widgets;
  }

  void _updateContentListCodes() {
    List<String>? contentListCodes = JsonUtils.listStringsValue(FlexUI()['home']);
    if ((contentListCodes != null) && !DeepCollectionEquality().equals(_contentListCodes, contentListCodes)) {
      setState(() {
        _contentListCodes = contentListCodes;
      });
    }
  }

  Future<void> _onPullToRefresh() async {
    LiveStats().refresh();
    _refreshController.add(null);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (isDragging) {
      RenderBox render = _contentWrapperKey.currentContext?.findRenderObject() as RenderBox;
      Offset position = render.localToGlobal(Offset.zero);
      double topY = position.dy;  // top position of the widget
      double bottomY = topY + render.size.height; // bottom position of the widget

      const detectedRange = 64;
      const double maxScrollDistance = 64;
      if (event.position.dy < topY + detectedRange) {
        // scroll up
        double scrollOffet = (topY + detectedRange - max(event.position.dy, topY)) / detectedRange * maxScrollDistance;
        _scrollUp(scrollOffet);

        if (_scrollTimer != null) {
          _scrollTimer?.cancel();
        }
        _scrollTimer = Timer.periodic(Duration(milliseconds: 100), (time) => _scrollUp(scrollOffet));
      }
      else if (event.position.dy > bottomY - detectedRange) {
        // scroll down
        double scrollOffet = (min(event.position.dy, bottomY) - bottomY + detectedRange) / detectedRange * maxScrollDistance;
        _scrollDown(scrollOffet);

        if (_scrollTimer != null) {
          _scrollTimer?.cancel();
        }
        _scrollTimer = Timer.periodic(Duration(milliseconds: 100), (time) => _scrollDown(scrollOffet));
      }
      else {
        _cancelScrollTimer();
      }
    }
  }

  void _onPointerCancel() {
    _cancelScrollTimer();
  }

  
  void _scrollUp(double scrollDistance) {
    double offset = max(_scrollController.offset - scrollDistance, _scrollController.position.minScrollExtent);
    if (offset < _scrollController.offset) {
      _scrollController.jumpTo(offset);
    }
  }

  void _scrollDown(double scrollDistance) {
    double offset = min(_scrollController.offset + scrollDistance, _scrollController.position.maxScrollExtent);
    if (_scrollController.offset < offset) {
      _scrollController.jumpTo(offset);
    }
  }

  void _cancelScrollTimer() {
    if (_scrollTimer != null) {
      _scrollTimer?.cancel();
      _scrollTimer = null;
    }
  }

  void _ensureSaferWidgetVisibiity() {
      BuildContext? saferContext = _saferKey.currentContext;
      if (saferContext != null) {
        Scrollable.ensureVisible(saferContext, duration: Duration(milliseconds: 300));
      }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      if (param == AppLifecycleState.resumed) {
        setState(() {});
      }
    }
    else if (name == Localization.notifyStringsUpdated) {
      setState(() { });
    }
    else if (name == FlexUI.notifyChanged) {
      _updateContentListCodes();
    }
    else if(name == Storage.offsetDateKey){
      setState(() {});
    }
    else if(name == Storage.useDeviceLocalTimeZoneKey){
      setState(() {});
    }
    else if (name == Styles.notifyChanged){
      setState(() {});
    }
    else if (name == Assets.notifyChanged) {
      setState(() {});
    }
    else if (name == HomeSaferWidget.notifyNeedsVisiblity) {
      _ensureSaferWidgetVisibiity();
    }
  }
}

class HomeFavorite implements Favorite {
  final String? id;
  HomeFavorite({this.id});

  bool operator == (o) => o is HomeFavorite && o.id == id;

  int get hashCode => (id?.hashCode ?? 0);

  static const String favoriteKeyName = "homePanelIds";
  @override String get favoriteKey => favoriteKeyName;
  @override String? get favoriteId => id;
}

abstract class HomeScrollableDragging  {
  set isDragging(bool value);
}