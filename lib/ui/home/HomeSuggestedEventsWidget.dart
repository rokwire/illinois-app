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

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:illinois/ui/explore/ExploreDetailPanel.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class HomeSuggestedEventsWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeSuggestedEventsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.suggested_events.label.events_for_you', 'Suggested Events');

  @override
  State<HomeSuggestedEventsWidget> createState() => _HomeSuggestedEventsWidgetState();
}

class _HomeSuggestedEventsWidgetState extends State<HomeSuggestedEventsWidget> implements NotificationsListener {

  Set<String>?    _availableCategories;
  Set<String>?    _categoriesFilter;
  Set<String>?    _tagsFilter;
  List<Event>?    _events;
  bool?           _loadingEvents;
  DateTime?       _pausedDateTime;
  
  PageController? _pageController;
  Key?            _pageViewKey;
  Map<String, GlobalKey> _contentKeys = <String, GlobalKey>{};
  final double    _pageSpacing = 16;

  @override
  void initState() {
    
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Config.notifyConfigChanged,
      Auth2UserPrefs.notifyTagsChanged,
      Auth2UserPrefs.notifyInterestsChanged,
      Events.notifyEventCreated,
      Events.notifyEventUpdated,
      AppLivecycle.notifyStateChanged,
    ]);
    
    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _loadEvents();
        }
      });
    }

    _loadAvailableCategories();
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
      _loadAvailableCategories();
    }
    else if (name == Config.notifyConfigChanged) {
      if (mounted) {
        setState(() {});
      }
    }
    else if (name == Auth2UserPrefs.notifyTagsChanged) {
      _loadEvents();
    }
    else if (name == Auth2UserPrefs.notifyInterestsChanged) {
      _loadEvents();
    }
    else if (name == Events.notifyEventCreated) {
      _loadEvents();
    }
    else if (name == Events.notifyEventUpdated) {
      _loadEvents();
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
          _loadEvents();
        }
      }
    }
  }

  void _loadAvailableCategories() {
    if (Connectivity().isNotOffline) {
      Events().loadEventCategories().then((List<dynamic>? categories) {
        _applyAvailableCategories(categories);
        _loadEvents();
      });
    }
    else {
      setState(() {
      });
    }
  }

  void _applyAvailableCategories(List<dynamic>? categories) {
    if ((categories != null) && (0 < categories.length)) {
      for (dynamic category in categories) {
        if (category is Map) {
          dynamic categoryName = category['category'];
          if (categoryName is String) {
            if (_availableCategories == null) {
              _availableCategories = Set();
            }
            _availableCategories!.add(categoryName);
          }
        }
      }
    }
  }

  void _loadEvents() {

    if (Connectivity().isNotOffline && (_loadingEvents != true)) {

      Set<String>? userCategories = (Auth2().prefs?.interestCategories != null) ? Set.from(Auth2().prefs!.interestCategories!) : null;
      if ((userCategories != null) && userCategories.isNotEmpty && (_availableCategories != null) && _availableCategories!.isNotEmpty) {
        userCategories = userCategories.intersection(_availableCategories!);
      }
      Set<String>? categoriesFilter = ((userCategories != null) && userCategories.isNotEmpty) ? userCategories : null;

      Set<String>? userTags = Auth2().prefs?.positiveTags;
      Set<String>? tagsFilter = ((userTags != null) && userTags.isNotEmpty) ? userTags : null;

      _loadingEvents = true;
      Events().loadEvents(limit: 20, eventFilter: EventTimeFilter.upcoming, categories: categoriesFilter, tags: tagsFilter).then((List<Event>? events) {

        bool haveEvents = (events != null) && events.isNotEmpty;
        bool haveTagsFilters = (tagsFilter != null) && tagsFilter.isNotEmpty;
        bool haveCategoriesFilters = (categoriesFilter != null) && categoriesFilter.isNotEmpty;
        bool haveFilters = haveTagsFilters || haveCategoriesFilters;

        if (haveEvents || !haveFilters) {
          _loadingEvents = false;
          if (mounted) {
            setState(() {
              _tagsFilter = tagsFilter;
              _categoriesFilter = categoriesFilter;
              _events = _randomSelection(events, Config().homeUpcomingEventsCount);
              _pageViewKey = UniqueKey();
              // _pageController = null;
              _contentKeys.clear();
            });
          }
        }
        else {
          Events().loadEvents(limit: 20, eventFilter: EventTimeFilter.upcoming).then((List<Event>? events) {
            _loadingEvents = false;
            setState(() {
              _tagsFilter = null;
              _categoriesFilter = null;
              _events = _randomSelection(events, Config().homeUpcomingEventsCount);
              _pageViewKey = UniqueKey();
              // _pageController = null;
              _pageController?.jumpToPage(0);
              _contentKeys.clear();
            });
          });
        }
      });
    }
    else {
      setState(() {});
    }
  }

  bool get _hasFiltersApplied {
    return ((_categoriesFilter != null) && _categoriesFilter!.isNotEmpty) ||
        ((_tagsFilter != null) && _tagsFilter!.isNotEmpty);
  }

  List<Event>? _randomSelection(List<Event>? events, int limit) {
    if ((events != null) && (limit < events.length)) {

      // Generate random indexes
      List<int> positions = [];
      for (int position = 0; position < limit; position++) {
        int eventsIndex = Random().nextInt(events.length);

        // Check if already generated
        int previousEventsIndex = eventsIndex + 1;
        while (eventsIndex != previousEventsIndex) {
          previousEventsIndex = eventsIndex;
          for (int pos = 0; pos < position; pos++) {
            if (positions[pos] == eventsIndex) {
              eventsIndex = (eventsIndex + 1) % events.length;
              break;
            }
          }
        }

        positions.add(eventsIndex);
      }

      // Build random events
      List<Event> randomEvents = [];
      for (int position in positions) {
        randomEvents.add(events[position]);
      }
      // Sort events
      SortUtils.sort(randomEvents);

      return randomEvents;
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
      _EventsRibbonHeader(
        title: Localization().getStringEx('widget.home.suggested_events.label.events_for_you', 'Suggested Events'),
        subTitle: _hasFiltersApplied ? Localization().getStringEx('widget.home.suggested_events.label.events_for_you.sub_title', 'Curated from your interests') : '',
        favoriteId: widget.favoriteId,
        rightIconKey: 'settings-white',
        rightIconAction: _navigateToSettings,
      ),
      Stack(children:<Widget>[
        _buildSlant(),
        _buildContent(),
      ]),
    ]);
  }

  Widget _buildSlant() {
    return Column(children: <Widget>[
      Container(color:  Styles().colors!.fillColorPrimary, height: 45,),
      Container(color: Styles().colors!.fillColorPrimary, child:
        CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.background, horzDir: TriangleHorzDirection.rightToLeft), child:
          Container(height: 65,),
        )),
    ],);
  }

  Widget _buildContent() {
    return (_events?.isEmpty ?? true) ? HomeMessageCard(
      message: Localization().getStringEx("widget.home.suggested_events.text.empty.description", "There are no suggested events available."),
    ) : _buildEventsContent();
  }

  Widget _buildEventsContent() {
    Widget contentWidget;
    List<Widget> pages = <Widget>[];
    if (1 < (_events?.length ?? 0)) {

      for (Event event in _events!) {
        pages.add(Padding(key: _contentKeys[event.id ?? ''] ??= GlobalKey(), padding: EdgeInsets.only(right: _pageSpacing, bottom: 16), child:
          ExploreCard(explore: event, showTopBorder: true, horizontalPadding: 0, onTap: () => _onTapEvent(event),
        )
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
          allowImplicitScrolling: true,
          children: pages,
        ),
      );
    }
    else {
      contentWidget = Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
        ExploreCard(explore: _events?.first, showTopBorder: true, horizontalPadding: 0, onTap: () => _onTapEvent(_events?.first))
      );
    }

    return Column(children: <Widget>[
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => pages.length, centerWidget:
        LinkButton(
          title: Localization().getStringEx('widget.home.suggested_events.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.suggested_events.button.all.hint', 'Tap to view all events'),
          onTap: _navigateToExploreEvents,
        ),
      ),
    ]);
  }


  void _onTapEvent(Event? event) {
    Analytics().logSelect(target: "Event: '${event?.title}'", source: widget.runtimeType.toString());

    if (event?.isComposite ?? false) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => CompositeEventsDetailPanel(parentEvent: event)));
    }
    else if (event?.isGameEvent ?? false) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(gameId: event!.speaker, sportName: event.registrationLabel,)));
    }
    else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreDetailPanel(explore: event)));
    }
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

  void _navigateToExploreEvents() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(exploreType: ExploreType.Events)));
  }

  void _navigateToSettings() {
    Analytics().logSelect(target: "Settings", source: widget.runtimeType.toString());
    SettingsHomeContentPanel.present(context, content: SettingsContent.interests);
  }
}

class _EventsRibbonHeader extends StatelessWidget {
  final String? title;
  final String? subTitle;

  final String? rightIconLabel;
  final String? rightIconKey;
  final void Function()? rightIconAction;

  final String? favoriteId;

  const _EventsRibbonHeader({Key? key,
    this.title,
    this.subTitle,

    // ignore: unused_element
    this.rightIconLabel,
    this.rightIconKey,
    this.rightIconAction,

    this.favoriteId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> titleList = <Widget>[];

    titleList.add(
      HomeTitleIcon(image: Styles().images?.getImage('calendar')),
    );
      
    titleList.add(
      Expanded(child:
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
          StringUtils.isNotEmpty(subTitle) ?
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Semantics(label: title, header: true, excludeSemantics: true, child:
                Text(title ?? '', style: Styles().textStyles?.getTextStyle("widget.heading.large.extra_fat"))
              ),
              Semantics(label: subTitle, header: true, excludeSemantics: true, child:
                Text(subTitle ?? '', style: Styles().textStyles?.getTextStyle("widget.heading.regular"))
              ),
            ],) :
            Semantics(label: title, header: true, excludeSemantics: true, child:
              Text(title ?? '', style: Styles().textStyles?.getTextStyle("widget.heading.large.extra_fat"))
            ),
        ),
      ),
    );

    Widget? rightIconWidget = (rightIconKey != null) ?
      Semantics(label: rightIconLabel, button: true, child:
        InkWell(onTap: rightIconAction, child:
          Padding(padding: EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 16), child:
            Styles().images?.getImage(rightIconKey, excludeFromSemantics: true,),
          )
        )
      ) : null;

    if (rightIconWidget != null) {
      titleList.add(rightIconWidget);
    }

    titleList.add(HomeFavoriteButton(favorite: HomeFavorite(favoriteId), style: FavoriteIconStyle.SlantHeader, prompt: true));

    Widget contentWidget = Container(color: Styles().colors?.fillColorPrimary, child: 
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: titleList,),
    );

    return contentWidget;
  }
}
