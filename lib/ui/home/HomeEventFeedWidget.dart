/*
 * Copyright 2022 Board of Trustees of the University of Illinois.
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

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Content.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeEventFeedWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeEventFeedWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.event_feed.label.header.title', 'Event Feed');

  State<HomeEventFeedWidget> createState() => _HomeEventFeedWidgetState();
}

class _HomeEventFeedWidgetState extends State<HomeEventFeedWidget> implements NotificationsListener {
  List<Event2>? _events;
  DateTime? _pausedDateTime;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  Map<String, GlobalKey> _contentKeys = <String, GlobalKey>{};
  final double _pageSpacing = 16;

  @override
  void initState() {

    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _refresh();
        }
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
    if (name == Content.notifyVideoTutorialsChanged) {
      _refresh();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
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
          _refresh();
        }
      }
    }
  }

  void _refresh() {
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: HomeEventFeedWidget.title,
      titleIconKey: 'events',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (CollectionUtils.isEmpty(_events)) {
      return HomeMessageCard(
        message: Localization().getStringEx("widget.home.event_feed.text.empty.description", "There are no events available."));
    }
    else {
      return _buildEventsContent();
    }
  }

  Widget _buildEventsContent() {
    Widget contentWidget;
    List<Widget> pages = <Widget>[];

    int eventsCount = _events?.length ?? 0;
    if (eventsCount > 1) {
      for (Event2 event in _events!) {
        pages.add(Padding(
            key: _contentKeys[StringUtils.ensureNotEmpty(event.id)] ??= GlobalKey(),
            padding: EdgeInsets.only(right: _pageSpacing + 2, bottom: 8),
            child: _buildEventEntry(event)));
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
          allowImplicitScrolling: true,
          children: pages,
        ),
      );
    }
    else if (eventsCount == 1) {
      contentWidget = Padding(padding: EdgeInsets.only(left: 16, right: 16), child:
        _buildEventEntry(_events!.first)
      );
    }
    else {
      contentWidget = Container();
    }

    return Column(children: <Widget>[
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => pages.length,),
      LinkButton(
        title: Localization().getStringEx('widget.home.event_feed.button.all.title', 'View All'),
        hint: Localization().getStringEx('widget.home.event_feed.button.all.hint', 'Tap to view all events'),
        onTap: _onTapViewAll,
      ),
    ]);
  }

  Widget _buildEventEntry(Event2 event) {
    return Container(height: 80,);
  }

  double get _pageHeight {
    double? minContentHeight;
    for (GlobalKey contentKey in _contentKeys.values) {
      final RenderObject? renderBox = contentKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && ((minContentHeight == null) || (renderBox.size.height < minContentHeight))) {
        minContentHeight = renderBox.size.height;
      }
    }
    return minContentHeight ?? 0;
  }

  void _onTapViewAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
  }
}