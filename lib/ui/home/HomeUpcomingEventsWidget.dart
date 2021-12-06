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
import 'package:flutter/material.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Connectivity.dart';
import 'package:illinois/service/ExploreService.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:illinois/ui/explore/ExploreDetailPanel.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/settings/SettingsManageInterestsPanel.dart';
import 'package:illinois/ui/widgets/HomeHeader.dart';
import 'package:illinois/ui/widgets/ImageHolderListItem.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class HomeUpcomingEventsWidget extends StatefulWidget {

  final StreamController<void> refreshController;

  HomeUpcomingEventsWidget({this.refreshController});

  @override
  _HomeUpcomingEventsWidgetState createState() => _HomeUpcomingEventsWidgetState();
}

class _HomeUpcomingEventsWidgetState extends State<HomeUpcomingEventsWidget> implements NotificationsListener {

  Set<String>   _availableCategories;
  Set<String>   _categoriesFilter;
  Set<String>   _tagsFilter;
  List<Explore> _events;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Auth2UserPrefs.notifyTagsChanged,
    ]);
    if (widget.refreshController != null) {
      widget.refreshController.stream.listen((_) {
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
  }

  void _loadAvailableCategories() {
    if (Connectivity().isNotOffline) {
      ExploreService().loadEventCategories().then((List<dynamic> categories) {
        _applyAvailableCategories(categories);
        _loadEvents();
      });
    }
    else {
      setState(() {
      });
    }
  }

  void _applyAvailableCategories(List<dynamic> categories) {
    if ((categories != null) && (0 < categories.length)) {
      for (dynamic category in categories) {
        if (category is Map) {
          dynamic categoryName = category['category'];
          if (categoryName is String) {
            if (_availableCategories == null) {
              _availableCategories = Set();
            }
            _availableCategories.add(categoryName);
          }
        }
      }
    }
  }

  void _loadEvents() {

    if (Connectivity().isNotOffline) {

      Set<String> userCategories = Set.from(Auth2().prefs?.interestCategories ?? []);
      if ((userCategories != null) && userCategories.isNotEmpty && (_availableCategories != null) && _availableCategories.isNotEmpty) {
        userCategories = userCategories.intersection(_availableCategories);
      }
      Set<String> categoriesFilter = ((userCategories != null) && userCategories.isNotEmpty) ? userCategories : null;

      Set<String> userTags = Auth2().prefs?.positiveTags;
      Set<String> tagsFilter = ((userTags != null) && userTags.isNotEmpty) ? userTags : null;

      ExploreService().loadEvents(limit: 20, eventFilter: EventTimeFilter.upcoming, categories: _categoriesFilter, tags: tagsFilter).then((List<Explore> events) {

        bool haveEvents = (events != null) && events.isNotEmpty;
        bool haveTagsFilters = (tagsFilter != null) && tagsFilter.isNotEmpty;
        bool haveCategoriesFilters = (categoriesFilter != null) && categoriesFilter.isNotEmpty;
        bool haveFilters = haveTagsFilters || haveCategoriesFilters;

        if (haveEvents || !haveFilters) {
          if (mounted) {
            setState(() {
              _tagsFilter = tagsFilter;
              _categoriesFilter = categoriesFilter;
              _events = _randomSelection(events, 5);
            });
          }
          else {
            _tagsFilter = tagsFilter;
            _categoriesFilter = categoriesFilter;
            _events = _randomSelection(events, 5);
          }
        }
        else {
          ExploreService().loadEvents(limit: 20, eventFilter: EventTimeFilter.upcoming).then((List<Explore> events) {
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
    return ((_categoriesFilter != null) && _categoriesFilter.isNotEmpty) ||
        ((_tagsFilter != null) && _tagsFilter.isNotEmpty);
  }

  List<Explore> _randomSelection(List<Explore> events, int limit) {
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
      List<Explore> randomEvents = [];
      for (int position in positions) {
        randomEvents.add(events[position]);
      }
      return randomEvents;
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    if (AppCollection.isCollectionEmpty(_events)) {
      return Container();
    }
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          HomeHeader(
            title: Localization().getStringEx(
                'widget.home_upcoming_events.label.events_for_you',
                'Events For You'),
            imageRes: 'images/icon-calendar.png',
            subTitle: _hasFiltersApplied ? Localization().getStringEx('widget.home_upcoming_events.label.events_for_you.sub_title', 'Curated from your interests') : '',
            onSettingsTap: (){
              Analytics.instance.logSelect(target: "Events for you - settings");
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
            child: ScalableRoundedButton(
                label: Localization().getStringEx(
                    'widget.home_upcoming_events.button.more.title',
                    'View all events'),
                hint: Localization().getStringEx(
                    'widget.home_upcoming_events.button.more.hint', ''),
                borderColor: Styles().colors.fillColorSecondary,
                textColor: Styles().colors.fillColorPrimary,
                backgroundColor: Styles().colors.white,
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
      for (int i = 0; i < _events.length; i++) {
        Explore event = _events[i];
        widgets.add(ImageHolderListItem(
            placeHolderDividerResource: Styles().colors.fillColorSecondaryTransparent05,
            placeHolderSlantResource: 'images/slant-down-right.png',
            applyHorizontalPadding: false,
            child: _buildItemCard(
                context: context, item: event, showSmallImage: (i != 0)),
            imageUrl: i == 0 ? _getImage(event) : null));
      }
    }
    return widgets;
  }

  String _getImage(dynamic item) {
    if (item != null && item is Event) {
      return item.exploreImageURL;
    } else if (item != null && item is Game) {
      return item.imageUrl;
    }
    return null;
  }

  Widget _buildItemCard({BuildContext context, Explore item, bool showSmallImage}) {
    if (item != null) {
      return ExploreCard(
        explore: item,
        showTopBorder: true,
        showSmallImage: showSmallImage,
        onTap: () => _onTapExplore(item),
      );
    }
    return Container();
  }

  void _onTapExplore(Explore explore) {
    Favorite favorite = explore is Favorite? explore as Favorite: null;
    String exploreid = favorite?.favoriteId;
    Analytics.instance.logSelect(target: "HomeUpcomingEvents event: $exploreid");

    Event event = (explore is Event) ? explore : null;
    if (event?.isComposite ?? false) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => CompositeEventsDetailPanel(parentEvent: event)));
    }
    else if (event?.isGameEvent ?? false) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(gameId: event.speaker, sportName: event.registrationLabel,)));
    }
    else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreDetailPanel(explore: explore)));
    }
  }

  void _navigateToExploreEvents() {
    Analytics.instance.logSelect(target: "HomeUpcomingEvents View all events");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(initialTab: ExploreTab.Events, showHeaderBack: true,)));
  }
}
