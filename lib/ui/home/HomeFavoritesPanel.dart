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
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:neom/model/Analytics.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/ui/home/HomePanel.dart';
import 'package:neom/ui/home/HomeToutWidget.dart';
import 'package:neom/ui/home/HomeWelcomeMessageWidget.dart';
import 'package:neom/ui/home/HomeWelcomeVideoWidget.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:neom/service/FlexUI.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:neom/ui/home/HomeLoginWidget.dart';
import 'package:neom/ui/home/HomeVoterRegistrationWidget.dart';
import 'package:neom/ui/widgets/FlexContent.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

////////////////////////
// HomeFavoritesPanel

class HomeFavoritesPanel extends StatefulWidget with AnalyticsInfo {
  static const String notifySelect       = "edu.illinois.rokwire.favorites.select";

  @override
  State<StatefulWidget> createState() => _HomeFavoritesPanelState();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.Home;
}

class _HomeFavoritesPanelState extends State<HomeFavoritesPanel> with AutomaticKeepAliveClientMixin<HomeFavoritesPanel> implements NotificationsListener {
  StreamController<String> _updateController = StreamController.broadcast();
  GlobalKey _contentWrapperKey = GlobalKey();
  GlobalKey _favoritesKey = GlobalKey();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    NotificationService().subscribe(this, []);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _updateController.close();
    _scrollController.dispose();
    super.dispose();
  }

  // AutomaticKeepAliveClientMixin

  @override
  bool get wantKeepAlive => true;

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.home.header.favorites.title', 'Favorites')),
      body: Column(key: _contentWrapperKey, children: <Widget>[
        Expanded(child:
          RefreshIndicator(onRefresh: _onPullToRefresh, child:
            SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), child:
              HomeFavoritesContentWidget(key: _favoritesKey, updateController: _updateController,),
            ),
          ),
        ),
      ]),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: null,
    );
  }

  Future<void> _onPullToRefresh() async {
    _updateController.add(HomePanel.notifyRefresh);
  }
}

////////////////////////
// HomeFavoritesContentWidget

class HomeFavoritesContentWidget extends StatefulWidget {
  final Set<String>? availableSystemCodes;
  final StreamController<String>? updateController;

  HomeFavoritesContentWidget({super.key, this.availableSystemCodes, this.updateController});

  @override
  _HomeFavoritesContentWidgetState createState() => _HomeFavoritesContentWidgetState();
}

class _HomeFavoritesContentWidgetState extends State<HomeFavoritesContentWidget> implements NotificationsListener {

  List<String>? _systemCodes;
  List<String>? _favoriteCodes;
  Set<String>? _availableCodes;
  Map<String, GlobalKey> _widgetKeys = <String, GlobalKey>{};

  @override
  void initState() {

    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);

    // Build Favorite codes before start listening for Auth2UserPrefs.notifyFavoritesChanged
    // because _buildFavoriteCodes may fire such.
    _systemCodes = JsonUtils.listStringsValue(FlexUI()['home.system']);
    _availableCodes = _getAvailableHomeSections(JsonUtils.setStringsValue(FlexUI()['home'])) ?? <String>{};
    _favoriteCodes = _buildFavoriteCodes();

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
    if (name == FlexUI.notifyChanged) {
      _updateContentCodes();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _updateFavoriteCodes();
    }
  }

  @override
  Widget build(BuildContext context) =>
    Column(children: <Widget>[
      ..._buildWidgetsFromCodes(_systemCodes, availableCodes: widget.availableSystemCodes),
      ..._buildWidgetsFromCodes(_favoriteCodes?.reversed, availableCodes: _availableCodes),
    ],);

  List<Widget> _buildWidgetsFromCodes(Iterable<String>? codes, { Set<String>? availableCodes }) {
    List<Widget> widgets = [];
    if (codes != null) {
      for (String code in codes) {
        if ((availableCodes == null) || availableCodes.contains(code)) {
          Widget? widget = _widgetFromCode(code);
          if (widget is Widget) {
            widgets.add(widget);
          }
        }
      }
    }
    return widgets;
  }

  Widget? _widgetFromCode(String code,) {
    if (code == 'tout') {
      return HomeToutWidget(key: _widgetKey(code), favoriteId: code, updateController: widget.updateController, contentType: HomeContentType.favorites,);
    }
    else if (code == 'emergency') {
      return FlexContent(contentKey: code, key: _widgetKey(code), favoriteId: code, updateController: widget.updateController);
    }
    else if (code == 'voter_registration') {
      return HomeVoterRegistrationWidget(key: _widgetKey(code), favoriteId: code, updateController: widget.updateController,);
    }
    else if (code == 'connect') {
      return HomeLoginWidget(key: _widgetKey(code), favoriteId: code, updateController: widget.updateController,);
    }
    else if (code == 'welcome_video') {
      return HomeWelcomeVideoWidget(key: _widgetKey(code), favoriteId: code, updateController: widget.updateController,);
    }
    else if (code == 'welcome_message') {
      return HomeWelcomeMessageWidget(key: _widgetKey(code), favoriteId: code, updateController: widget.updateController,);
    }
    else {
      dynamic data = HomePanel.dataFromCode(code,
        title: false, handle: false, position: 0,
        globalKeys: _widgetKeys,
        updateController: widget.updateController,
      );

      return (data is Widget) ? data : FlexContent(contentKey: code, key: _widgetKey(code), favoriteId: code, updateController: widget.updateController);
    }
  }

  GlobalKey _widgetKey(String code) => _widgetKeys[HomePanel.sectionFromCode(code)] ??= GlobalKey();

  void _updateContentCodes() {
    Set<String>? availableCodes = _getAvailableHomeSections(JsonUtils.setStringsValue(FlexUI()['home']));
    bool availableCodesChanged = (availableCodes != null) && !DeepCollectionEquality().equals(_availableCodes, availableCodes);

    List<String>? systemCodes = JsonUtils.listStringsValue(FlexUI()['home.system']);
    bool systemCodesChanged = (systemCodes != null) && !DeepCollectionEquality().equals(_systemCodes, systemCodes);

    if (mounted && (availableCodesChanged || systemCodesChanged)) {
      setState(() {
        if (availableCodesChanged) {
          _availableCodes = availableCodes;
        }
        if (systemCodesChanged) {
          _systemCodes = systemCodes;
        }
      });
    }
  }

  Set<String>? _getAvailableHomeSections(Set<String>? availableCodes) {
    Set<String>? availableSections;
    if (availableCodes != null) {
      availableSections = {};
      for(String code in availableCodes) {
        availableSections.add(HomePanel.sectionFromCode(code));
      }
    }
    return availableSections;
  }

  List<String>? _buildFavoriteCodes() {
    LinkedHashSet<String>? homeFavorites = Auth2().prefs?.getFavorites(HomeFavorite.favoriteKeyName());
    if (homeFavorites == null) {
      homeFavorites = _initDefaultFavorites();
    }

    Set<String>? updatedFavorites = _getAvailableHomeSections(homeFavorites);
    return (updatedFavorites != null) ? List.from(updatedFavorites) : null;
  }

  void _updateFavoriteCodes() {
    if (mounted) {
      List<String>? favoriteCodes = _buildFavoriteCodes();
      if ((favoriteCodes != null) && !DeepCollectionEquality().equals(_favoriteCodes, favoriteCodes)) {
        setState(() {
          _favoriteCodes = favoriteCodes;
        });
      }
    }
  }

  static LinkedHashSet<String>? _initDefaultFavorites() {
    Map<String, dynamic>? defaults = FlexUI().content('defaults.favorites');
    if (defaults != null) {
      List<String>? defaultContent = JsonUtils.listStringsValue(defaults['home']);
      if (defaultContent != null) {

        // Init content of all compound widgets that bellongs to home favorites content
        for (String code in defaultContent) {
          List<String>? defaultWidgetContent = JsonUtils.listStringsValue(defaults['home.$code']);
          if (defaultWidgetContent != null) {
            Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: code),
              LinkedHashSet<String>.from(defaultWidgetContent.reversed));
          }
        }

        // Clear content of all compound widgets that do not bellongs to home favorites content
        Iterable<String>? favoriteKeys = Auth2().prefs?.favoritesKeys;
        if (favoriteKeys != null) {
          for (String favoriteKey in List.from(favoriteKeys)) {
            String? code = HomeFavorite.parseFavoriteKeyCategory(favoriteKey);
            if ((code != null) && !defaultContent.contains(code)) {
              Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: code), null);
            }
          }
        }

        // Init content of home favorites
        LinkedHashSet<String>? defaultFavorites = LinkedHashSet<String>.from(defaultContent.reversed);
        Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), defaultFavorites);
        return defaultFavorites;
      }
    }
    return null;
  }
}

