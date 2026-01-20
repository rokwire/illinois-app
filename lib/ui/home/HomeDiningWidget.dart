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
import 'package:flutter/cupertino.dart';
import 'package:illinois/ext/Dining.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/accessibility/AccessiblePageView.dart';
import 'package:illinois/ui/dining/Dining2HomePanel.dart';
import 'package:illinois/ui/dining/DiningCard.dart';
import 'package:illinois/ui/explore/ExploreDiningDetailPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

enum FavoriteDiningContentType { my, all, open }

class HomeDiningWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeDiningWidget({super.key, this.favoriteId, this.updateController});

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  String get _title => title;
  static String get title => Localization().getStringEx('widget.home.dinings.header.title', 'Dining');

  @override
  State<StatefulWidget> createState() => _HomeDiningWidgetState();
}

class _HomeDiningWidgetState extends State<HomeDiningWidget> {

  late FavoriteDiningContentType _contentType;

  @override
  void initState() {
    _contentType = _FavoriteDiningContentType.fromJson(Storage().getHomeFavoriteSelectedContent(widget.favoriteId)) ?? FavoriteDiningContentType.all;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return HomeFavoriteWidget(favoriteId: widget.favoriteId, title: widget._title, child:
      _contentWidget,
    );
  }

  Widget get _contentWidget => Column(mainAxisSize: MainAxisSize.min, children: [
    Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 8), child:
      _contentTypeBar,
    ),
    ..._contentTypeWidgets,
  ],);

  Iterable<Widget> get _contentTypeWidgets => FavoriteDiningContentType.values.map((FavoriteDiningContentType contentType) =>
    Visibility(visible: (_contentType == contentType), maintainState: true, child:
    _HomeDiningImplWidget(contentType,
        updateController: widget.updateController,
      ),
    ));

  // https://stackoverflow.com/a/51157072/3759472
  // IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch,
  Widget get _contentTypeBar => Row(children: List<Widget>.from(
    FavoriteDiningContentType.values.map((FavoriteDiningContentType contentType) => Expanded(child:
      HomeFavTabBarBtn(contentType.diningTitle.toUpperCase(),
        position: contentType.position,
        selected: _contentType == contentType,
        onTap: () => _onContentType(contentType),
      )
    )),
  ));

  void _onContentType(FavoriteDiningContentType contentType) {
    if ((_contentType != contentType) && mounted) {
      setState(() {
        _contentType = contentType;
        Storage().setHomeFavoriteSelectedContent(widget.favoriteId, contentType.toJson());
      });
    }
  }
}

class _HomeDiningImplWidget extends StatefulWidget {

  final FavoriteDiningContentType contentType;
  final StreamController<String>? updateController;

  // ignore: unused_element_parameter
  const _HomeDiningImplWidget(this.contentType, {super.key, this.updateController});

  State<StatefulWidget> createState() => _HomeDiningImplWidgetState();
}

class _HomeDiningImplWidgetState extends State<_HomeDiningImplWidget> with NotificationsListener {

  List<Dining>? _dinings;
  bool _loadingDinings = false;
  bool _refreshingDinings = false;

  bool _visible = false;
  Key _visibilityDetectorKey = UniqueKey();
  DateTime? _pausedDateTime;
  FavoriteContentStatus _contentStatus = FavoriteContentStatus.none;

  Map<String, GlobalKey> _contentKeys = <String, GlobalKey>{};
  PageController? _pageController;
  Key _pageViewKey = UniqueKey();

  @override
  void initState() {

    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      AppLivecycle.notifyStateChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _refreshDiningsIfVisible();
        }
      });
    }

    _loadDinings();

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
      _loadDiningsIfVisible();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted();
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
          _refreshDiningsIfVisible();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => VisibilityDetector(
    key: _visibilityDetectorKey,
    onVisibilityChanged: _onVisibilityChanged,
    child: _contentWidget,
  );

  Widget get _contentWidget {
    if (Connectivity().isOffline) {
      return HomeMessageCard(
        title: Localization().getStringEx("common.message.offline", "You appear to be offline"),
        message: Localization().getStringEx("widget.home.dinings.text.offline.description", "No dining locations available while offline."),
      );
    }
    else if (_loadingDinings || _refreshingDinings) {
      return HomeProgressWidget();
    }
    else {
      return _diningsContentWidget;
    }
  }

  Widget get _diningsContentWidget {
      Widget? contentWidget;
      List<Dining>? displayDinings = _buildDisplayDinings();
      if (displayDinings != null) {
        if (1 < displayDinings.length) {

          List<Widget> pages = <Widget>[];
          for (Dining dining in displayDinings) {
            pages.add(Padding(
                key: _contentKeys[dining.id ?? ''] ??= GlobalKey(),
                padding: HomeCard.defaultPageMargin,
                child: DiningCard(dining, onTap: (context) => _onTapDining(dining))
            ));
          }

          if (_pageController == null) {
            double screenWidth = MediaQuery.of(context).size.width;
            double pageViewport = (screenWidth - 2 * HomeCard.pageSpacing) / screenWidth;
            _pageController = PageController(viewportFraction: pageViewport);
          }

          contentWidget = Container(constraints: BoxConstraints(minHeight: _pageHeight), child:
            AccessiblePageView(
              key: _pageViewKey,
              controller: _pageController,
              estimatedPageSize: _pageHeight,
              allowImplicitScrolling: true,
              children: pages,
            ),
          );
        }
        else if (displayDinings.length == 1) {
          contentWidget = Padding(padding: HomeCard.defaultSingleCardMargin, child:
            DiningCard(displayDinings.first, onTap: (context) => _onTapDining(displayDinings.first))
          );
        }
      }

      return (contentWidget != null) ? Column(children: <Widget>[
        contentWidget,
        AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => displayDinings?.length ?? 0, centerWidget:
          HomeBrowseLinkButton(
            title: Localization().getStringEx('widget.home.laundry.button.all.title', 'View All'),
            hint: Localization().getStringEx('widget.home.laundry.button.all.hint', 'Tap to view all laundries'),
            onTap: _onTapSeeAll,
          ),
        ),
      ]) : _emptyContentWidget;
    }

  double get _pageHeight {

    double? minContentHeight;
    for(GlobalKey contentKey in _contentKeys.values) {
      final RenderObject? renderBox = contentKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && renderBox.hasSize && ((minContentHeight == null) || (renderBox.size.height < minContentHeight))) {
        minContentHeight = renderBox.size.height;
      }
    }

    return minContentHeight ?? 0;
  }

  static const String localScheme = 'local';
  static const String localDiningHost = 'dining';
  static const String localUrlMacro = '{{local_url}}';
  static const String privacyScheme = 'privacy';
  static const String privacyLevelHost = 'level';
  static const String privacyUrlMacro = '{{privacy_url}}';

  Widget get _emptyContentWidget {
    if (widget.contentType == FavoriteDiningContentType.all) {
      return HomeMessageCard(message: Localization().getStringEx("widget.home.dinings.all.empty.description", "No dining locations are available right now."),);
    }
    else if (widget.contentType == FavoriteDiningContentType.open) {
      return HomeMessageCard(message: Localization().getStringEx("widget.home.dinings.open.empty.description", "No dining locations are currently opened."),);
    }
    else if (widget.contentType == FavoriteDiningContentType.my) {
      String message = Localization().getStringEx("widget.home.dinings.my.empty.description", "Tap the \u2606 on items in <a href='$localUrlMacro'><b>Dining</b></a> for quick access here. (<a href='$privacyUrlMacro'>Your privacy level</a> must be at least 2.)")
          .replaceAll(localUrlMacro, '$localScheme://$localDiningHost')
          .replaceAll(privacyUrlMacro, '$privacyScheme://$privacyLevelHost');

      return HomeMessageHtmlCard(message: message, onTapLink: _onMessageLink,);
    }
    else {
      return Container();
    }
  }

  void _onMessageLink(String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if (uri?.scheme == localScheme) {
      if (uri?.host.toLowerCase() == localDiningHost.toLowerCase()) {
        _launchDinings();
      }
      else if ((uri?.scheme == privacyScheme) && (uri?.host == privacyLevelHost)) {
        Analytics().logSelect(target: 'Privacy Level', source: runtimeType.toString());
        Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,)));
      }
    }
  }

  // Visibility

  void _onVisibilityChanged(VisibilityInfo info) {
    _updateInternalVisibility(!info.visibleBounds.isEmpty);
  }

  void _updateInternalVisibility(bool visible) {
    if (_visible != visible) {
      _visible = visible;
      _onInternalVisibilityChanged();
    }
  }

  void _onInternalVisibilityChanged() {
    if (_visible) {
      switch(_contentStatus) {
        case FavoriteContentStatus.none: break;
        case FavoriteContentStatus.refresh: _refreshDinings(); break;
        case FavoriteContentStatus.reload: _loadDinings(); break;
      }
    }
  }

  // Content Data

  Future<void> _loadDiningsIfVisible() async {
    if (_visible) {
      return _loadDinings();
    }
    else if (_contentStatus.index < FavoriteContentStatus.reload.index) {
      _contentStatus = FavoriteContentStatus.reload;
    }
  }

  Future<void> _loadDinings() async {
    if ((_loadingDinings == false) && mounted) {
      setState(() {
        _loadingDinings = true;
        _refreshingDinings = false;
      });

      List<Dining>? dinings = await Dinings().loadFilteredDinings();

      setStateIfMounted(() {
        _dinings = dinings;
        _contentStatus = FavoriteContentStatus.none;
        _loadingDinings = false;
        _contentKeys.clear();
      });
    }
  }

  Future<void> _refreshDiningsIfVisible() async {
    if (_visible) {
      return _refreshDinings();
    }
    else if (_contentStatus.index < FavoriteContentStatus.refresh.index) {
      _contentStatus = FavoriteContentStatus.refresh;
    }
  }

  Future<void> _refreshDinings() async {
    if ((_loadingDinings == false) && (_refreshingDinings == false) && mounted) {
      setState(() {
        _refreshingDinings = true;
      });

      List<Dining>? dinings = await Dinings().loadFilteredDinings();

      if (mounted && _refreshingDinings && (dinings != null) && !DeepCollectionEquality().equals(dinings, _dinings)) {
        setState(() {
          dinings = dinings;
          _contentStatus = FavoriteContentStatus.none;
          _refreshingDinings = false;
          _pageViewKey = UniqueKey();
          _contentKeys.clear();
          // _pageController = null;
          if ((_dinings?.isNotEmpty == true) && (_pageController?.hasClients == true)) {
            _pageController?.jumpToPage(0);
          }
        });
      }
    }
  }

  List<Dining>? _buildDisplayDinings() {
    switch (widget.contentType) {
      case FavoriteDiningContentType.my: return _buildFavoriteDinings();
      case FavoriteDiningContentType.all: return _dinings;
      case FavoriteDiningContentType.open: return _buildOnenNowDinings();
    }
  }

  List<Dining>? _buildOnenNowDinings() {
    List<Dining>? openNowDinings = (_dinings != null) ? <Dining>[] : null;
    if (openNowDinings != null) {
      for (Dining dining in _dinings!) {
        if (dining.isOpen) {
          openNowDinings.add(dining);
        }
      }
    }
    return openNowDinings;
  }

  List<Dining>? _buildFavoriteDinings() {
    List<Dining>? dinings = _dinings;
    LinkedHashSet<String>? favoriteDiningIds = Auth2().prefs?.getFavorites(Dining.favoriteKeyName);
    if ((dinings != null) && (favoriteDiningIds != null)) {
      Map<String, Dining> favorites = <String, Dining>{};
      if (dinings.isNotEmpty && favoriteDiningIds.isNotEmpty) {
        for (Dining dining in dinings) {
          if ((dining.favoriteId != null) && favoriteDiningIds.contains(dining.favoriteId)) {
            favorites[dining.favoriteId!] = dining;
          }
        }
      }

      List<Favorite>? result = <Favorite>[];
      if (favorites.isNotEmpty) {
        for (String favoriteId in favoriteDiningIds) {
          ListUtils.add(result, favorites[favoriteId]);
        }
      }

      // show last added at top
      return List.from(result.reversed);
    }
    else {
      return null;
    }
  }

  // Event Handlers

  void _onTapDining(Dining dining) {
    Analytics().logSelect(target: "Dinning: '${dining.title}'", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreDiningDetailPanel(dining,)));
  }

  void _onTapSeeAll() {
    Analytics().logSelect(target: "View All / ${widget.contentType.diningTitle}", source: widget.runtimeType.toString());
    switch (widget.contentType) {
      case FavoriteDiningContentType.my: _launchFavoriteDinings(); break;
      case FavoriteDiningContentType.all: _launchDinings(); break;
      case FavoriteDiningContentType.open: _launchOpenNowDinings(); break;
    }
  }

  void _launchDinings() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Dining2HomePanel(
      analyticsFeature: AnalyticsFeature.DiningAll
    ) ));;
  }

  void _launchOpenNowDinings() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Dining2HomePanel(
      filter: Dining2Filter(openNow: true),
      analyticsFeature: AnalyticsFeature.DiningOpen
    )));
  }

  void _launchFavoriteDinings() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Dining2HomePanel(
      filter: Dining2Filter(starred: true),
      analyticsFeature: AnalyticsFeature.DiningFavorites
    )));
  }
}


extension _FavoriteDiningContentType on FavoriteDiningContentType {

  String get diningTitle {
    switch (this) {
      case FavoriteDiningContentType.my: return Localization().getStringEx('widget.home.dinings.my.button.title', 'My Locations');
      case FavoriteDiningContentType.all: return Localization().getStringEx('widget.home.dinings.all.button.title', 'All Locations');
      case FavoriteDiningContentType.open: return Localization().getStringEx('widget.home.dinings.open.button.title', 'Open Now');
    }
  }

  HomeFavTabBarBtnPos get position {
    if (this == FavoriteDiningContentType.values.first) {
      return HomeFavTabBarBtnPos.first;
    }
    else if (this == FavoriteDiningContentType.values.last) {
      return HomeFavTabBarBtnPos.last;
    }
    else {
      return HomeFavTabBarBtnPos.middle;
    }
  }

  static FavoriteDiningContentType? fromJson(dynamic value) {
    switch (value) {
      case 'my': return FavoriteDiningContentType.my;
      case 'all': return FavoriteDiningContentType.all;
      case 'open': return FavoriteDiningContentType.open;
    }
    return null;
  }

  toJson() {
    switch (this) {
      case FavoriteDiningContentType.my: return 'my';
      case FavoriteDiningContentType.all: return 'all';
      case FavoriteDiningContentType.open: return 'open';
    }
  }
}


