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

import 'package:flutter/cupertino.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:illinois/ext/Event.dart';
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
import 'package:illinois/ui/settings/SettingsManageInterestsPanel.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class HomeUpcomingEventsWidget extends StatefulWidget {

  final StreamController<void>? refreshController;

  HomeUpcomingEventsWidget({Key? key, this.refreshController}) : super(key: key);

  @override
  _HomeUpcomingEventsWidgetState createState() => _HomeUpcomingEventsWidgetState();
}

class _HomeUpcomingEventsWidgetState extends State<HomeUpcomingEventsWidget> implements NotificationsListener {

  Set<String>?   _availableCategories;
  Set<String>?   _categoriesFilter;
  Set<String>?   _tagsFilter;
  List<Event>?   _events;
  bool?          _loadingEvents;
  DateTime?      _pausedDateTime;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Auth2UserPrefs.notifyTagsChanged,
      Auth2UserPrefs.notifyInterestsChanged,
      Events.notifyEventCreated,
      Events.notifyEventUpdated,
      AppLivecycle.notifyStateChanged,
    ]);
    if (widget.refreshController != null) {
      widget.refreshController!.stream.listen((_) {
        _loadEvents();
      });
    }
    _loadAvailableCategories();
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
      _loadAvailableCategories();
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
              _events = _randomSelection(events, 5);
            });
          }
        }
        else {
          Events().loadEvents(limit: 20, eventFilter: EventTimeFilter.upcoming).then((List<Event>? events) {
            _loadingEvents = false;
            setState(() {
              _tagsFilter = null;
              _categoriesFilter = null;
              _events = _randomSelection(events, 5);
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
    if (CollectionUtils.isEmpty(_events)) {
      return Container();
    }
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SectionRibbonHeader(
            title: Localization().getStringEx('widget.home_upcoming_events.label.events_for_you', 'Events For You'),
            subTitle: _hasFiltersApplied ? Localization().getStringEx('widget.home_upcoming_events.label.events_for_you.sub_title', 'Curated from your interests') : '',
            titleIconAsset: 'images/icon-calendar.png',
            rightIconAsset: 'images/settings-white.png',
            rightIconAction: () {
              Analytics().logSelect(target: "Events for you - settings");
              Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsManageInterestsPanel()));
            },
          ),
          Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _buildListItems(context)),
          Container(
            height: 20,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 25),
            child: RoundedButton(
                label: Localization().getStringEx(
                    'widget.home_upcoming_events.button.more.title',
                    'View All Events'),
                hint: Localization().getStringEx(
                    'widget.home_upcoming_events.button.more.hint', ''),
                borderColor: Styles().colors!.fillColorSecondary,
                textColor: Styles().colors!.fillColorPrimary,
                backgroundColor: Styles().colors!.white,
                onTap: () => _navigateToExploreEvents(),
              ),
          ),
          Container(
            height: 48,
          ),
        ]);
  }

  List<Widget> _buildListItems(BuildContext context) {
    List<Widget> widgets = [];
    if (_events?.isNotEmpty ?? false) {
      for (Event event in _events!) {
        if (widgets.isEmpty && StringUtils.isNotEmpty(event.eventImageUrl)) {
          widgets.add(ImageSlantHeader(
            slantImageColor: Styles().colors!.fillColorSecondaryTransparent05,
            slantImageAsset: 'images/slant-down-right.png',
            //applyHorizontalPadding: false,
            child: _buildItemCard(context: context, item: event, showSmallImage: false),
            imageUrl: event.eventImageUrl
          ));
        }
        else {
          widgets.add(_buildItemCard(context: context, item: event),);
        }
      }

      /*for (int i = widgets.isNotEmpty ? 1 : 0; i < _events!.length; i++) {
        Event event = _events![i];
        widgets.add(ImageHolderListItem(
            placeHolderDividerResource: Styles().colors!.fillColorSecondaryTransparent05,
            placeHolderSlantResource: 'images/slant-down-right.png',
            applyHorizontalPadding: false,
            child: _buildItemCard(context: context, item: event, showSmallImage: (i != 0)),
            imageUrl: i == 0 ? event.eventImageUrl : null));
      }*/
    }
    return widgets;
  }

  Widget _buildItemCard({BuildContext? context, Event? item, bool? showSmallImage}) {
    if (item != null) {
      return Padding(padding: EdgeInsets.only(top: 16), child:
        ExploreCard(
          explore: item,
          showTopBorder: true,
          showSmallImage: showSmallImage,
          onTap: () => _onTapEvent(item),
        ),
      );
    }
    return Container();
  }

  void _onTapEvent(Event? event) {
    Analytics().logSelect(target: "HomeUpcomingEvents event: ${event?.exploreId}");

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

  void _navigateToExploreEvents() {
    Analytics().logSelect(target: "HomeUpcomingEvents View all events");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(initialTab: ExploreTab.Events)));
  }
}
