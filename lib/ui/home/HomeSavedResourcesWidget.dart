
import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/model/GBV.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Content.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/academics/AcademicsLinks.dart';
import 'package:illinois/ui/accessibility/AccessiblePageView.dart';
import 'package:illinois/ui/career/CareerPlanningLinks.dart';
import 'package:illinois/ui/dining/DiningLinksPanel.dart';
import 'package:illinois/ui/gbv/GBVResourceDirectoryPanel.dart';
import 'package:illinois/ui/guide/CampusGuidePanel.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/mtd/TransportationLinks.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/ui/wellness/WellnessLinksPanel.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HomeSavedResourcesWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  static const String homeCode = 'saved_resources';
  static const String favoriteKey = GuideFavorite.favoriteKeyName;

  HomeSavedResourcesWidget({super.key, this.favoriteId, this.updateController});

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  String get _title => title;
  static String get title => Localization().getStringEx('widget.home.saved_resources.title', 'Saved Resources');

  @override
  State<StatefulWidget> createState() => _HomeSavedResourcesWidgetState();

  static void favoriteListener(BuildContext context, ResourceFavorite favorite) {
    if ((favorite.key == favoriteKey) && (Auth2().prefs?.isFavorite(favorite) == true) && _isWidgetAvailable && !_isWidgetFavorite && (Storage().askForSavedResourcesHomeFavorite != false)) {
      _HomeSavedResourcesFavoriteAlertDialog.show(context).then((bool? result){
        if (result == true) {
          _setFavoriteWidget();
        }
      });
    }
  }

  static void _setFavoriteWidget() {
    List<Favorite> favorites = <Favorite>[];
    List<String>? items = JsonUtils.listStringsValue(FlexUI()['home.$homeCode']);
    if (items != null) {
      for (String item in items) {
        favorites.add(HomeFavorite(item, category: homeCode));
      }
    }
    favorites.add(HomeFavorite(homeCode));
    Auth2().prefs?.setListFavorite(favorites, true);
  }

  static bool get _isWidgetAvailable => (JsonUtils.setStringsValue(FlexUI()['home'])?.contains(homeCode) == true);
  static bool get _isWidgetFavorite => (Auth2().prefs?.isFavorite(HomeFavorite(homeCode)) == true);
}

class _HomeSavedResourcesWidgetState extends _SavedResourcesImplWidgetState<HomeSavedResourcesWidget> with NotificationsListener {

  bool _visible = false;
  Key _visibilityDetectorKey = UniqueKey();
  FavoriteContentStatus _contentStatus = FavoriteContentStatus.none;

  DateTime? _pausedDateTime;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  Map<String, GlobalKey> _contentKeys = <String, GlobalKey>{};

  StreamSubscription<String>? _updateSubscription;

  @override
  void initState() {

    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      AppLivecycle.notifyStateChanged,
      Auth2.notifyLoginChanged,
      Auth2.notifyPrefsChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      Guide.notifyChanged,
    ]);

    _updateSubscription = widget.updateController?.stream.listen((String command) {
      if (command == HomePanel.notifyRefresh) {
        _refreshIfVisible();
      }
    });

    _reload();

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _pageController?.dispose();
    _updateSubscription?.cancel();
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == Connectivity.notifyStatusChanged) {
      _reloadIfVisible(); // or mark as needs refresh
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _updateIfVisible();
    }
    else if (name == Auth2.notifyLoginChanged) {
      _reloadIfVisible(); // or mark as needs refresh
    }
    else if (name == Auth2.notifyPrefsChanged) {
      _reloadIfVisible(); // or mark as needs refresh
    }
    else if (name == Guide.notifyChanged) {
      _updateIfVisible();
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
          _reloadIfVisible();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
    HomeFavoriteWidget(favoriteId: widget.favoriteId, updateController: widget.updateController,
      title: widget._title,
      buttonBuilder: _favoriteButton,
      child: _visibilityDetectorWidget,
    );

  Widget _favoriteButton() => _HomeSavedResourcesFavoriteButton(
    favorite: HomeFavorite(widget.favoriteId),
    style: FavoriteIconStyle.Button,
    padding: HomeFavoriteWidget.favoriteButtonPadding,
    prompt: true
  );

  Widget get _visibilityDetectorWidget =>
    VisibilityDetector(
      key: _visibilityDetectorKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: _contentWidget,
    );

  Widget get _contentWidget {
    if (Connectivity().isOffline) {
      return HomeMessageCard(
        title: Localization().getStringEx("common.message.offline", "You appear to be offline"),
        message: Localization().getStringEx("widget.home.saved_resources.text.offline.description", "Saved resources are not available while offline."),
      );
    }
    else if (_contentActivity.showsProgress) {
      return HomeProgressWidget();
    }
    else if (_resources.length == 0) {
      return HomeMessageHtmlCard(
        message: _emptyContentMessageHtml,
        onTapLink : _onTapEmptyContentMessageLink,
      );
    }
    else {
      return _resourceContent;
    }
  }

  Widget get _resourceContent {
    Widget? contentWidget;
    if (1 < _resources.length) {
      List<Widget> pages = <Widget>[];
      for (ResourceFavorite resource in _resources) {
        pages.add(Padding(
          key: _contentKeys[resource.favoriteId ?? ''] ??= GlobalKey(),
          padding: HomeCard.defaultPageMargin,
          child: _resourceWidget(resource, displayMode: CardDisplayMode.home))
        );
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
    } else if (_resources.length == 1) {
      contentWidget = Padding(padding: HomeCard.defaultSingleCardMargin, child:
        _resourceWidget(_resources.first, displayMode: CardDisplayMode.home)
      );
    }

    return (contentWidget != null) ? Column(children: <Widget>[
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => _resources.length,centerWidget:
        HomeBrowseLinkButton(
          title: Localization().getStringEx('widget.home.saved_resources.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.saved_resources.button.all.hint', 'Tap to view all saved resources'),
          onTap: _onTapViewAll,
        ),
      ),
    ]) : Container();
  }

  void _onTapViewAll() {
    Analytics().logSelect(target: "View All", source: '${widget.runtimeType}' );
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SavedResourcesPanel()));
  }

  double get _pageHeight {
    double? minContentHeight;
    for (GlobalKey contentKey in _contentKeys.values) {
      final RenderObject? renderBox = contentKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && renderBox.hasSize && ((minContentHeight == null) || (renderBox.size.height < minContentHeight))) {
        minContentHeight = renderBox.size.height;
      }
    }
    return minContentHeight ?? 0;
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    _updateInternalVisibility(!info.visibleBounds.isEmpty);
  }

  // Visibility

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
        case FavoriteContentStatus.update: _update(); break;
        case FavoriteContentStatus.refresh: _refresh(); break;
        case FavoriteContentStatus.reload: _reload(); break;
      }
    }
  }

  // _SavedResourcesImplWidget

  @override
  Future<bool?> _load(FavoriteContentActivity contentActivity) async {
    if ((_contentActivity.index < contentActivity.index) && Connectivity().isNotOffline && mounted) {

      int currentPage = _getCurrentPage() ?? -1;
      ResourceFavorite? currentFavorite = ((0 <= currentPage) && (currentPage < _resources.length)) ? _resources[currentPage] : null;

      bool? resourcesUpdated = await super._load(contentActivity);

      if (mounted) {
        setState(() {
          _contentStatus = FavoriteContentStatus.none;
          //_pageViewKey = UniqueKey();
          //_contentKeys.clear();
        });

        int favoriteIndex = ((resourcesUpdated == true) && (currentFavorite != null)) ? _resources.indexOf(currentFavorite) : -1;
        int newPage = (favoriteIndex >= 0) ? favoriteIndex : currentPage;
        if (newPage >= 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController?.hasClients == true) {
              _pageController?.jumpToPage(newPage);
            }
          });
        }
      }
      return resourcesUpdated;
    } else {
      return null;
    }
  }

  Future<void> _reloadIfVisible() async {
    if (_visible) {
      return _reload();
    }
    else if (_contentStatus.canReload) {
      _contentStatus = FavoriteContentStatus.reload;
    }
  }

  Future<void> _refreshIfVisible() async {
    if (_visible) {
      return _refresh();
    }
    else if (_contentStatus.canRefresh) {
      _contentStatus = FavoriteContentStatus.refresh;
    }
  }

  Future<void> _updateIfVisible() async {
    if (_visible) {
      return _update();
    }
    else if (_contentStatus.canUpdate) {
      _contentStatus = FavoriteContentStatus.update;
    }
  }

  int? _getCurrentPage() {
    if (_resources.length > 1) {
      return ((_pageController?.hasPosition == true)) ? _pageController?.page?.toInt() : null;
    } else {
      return (_resources.length == 1) ? 0 : null;
    }
  }

}

class _SavedResourcesImplWidgetState<T extends StatefulWidget> extends State<T> {

  List<ResourceFavorite> _resources = <ResourceFavorite>[];
  Map<String, GBVData> _gbvDataMap = <String, GBVData>{};
  FavoriteContentActivity _contentActivity = FavoriteContentActivity.none;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }

  Widget? _resourceWidget(ResourceFavorite favorite, { required CardDisplayMode displayMode }) {
    String? category = favorite.category;
    if (category != null) {
      final GBVData? gbvData = _gbvDataMap[category];
      final GBVResource? gbvResource = gbvData?.resources.firstWhereOrNull((resource) => (resource.id == favorite.id));
      return (gbvResource != null) ? GBVResourceWidget(gbvResource,
        gbvData: gbvData,
        favoriteKey: HomeSavedResourcesWidget.favoriteKey,
        favoriteCategory: favorite.category,
        displayMode: displayMode.resourceDisplayMode,
      ) : null;
    } else {
      return GuideResourceWidget(
        guideEntryId: favorite.id,
        favoriteKey: HomeSavedResourcesWidget.favoriteKey,
        displayMode: displayMode,
      );
    }
  }

  // Data

  Future<_GBVResourcesContent> _loadContent(FavoriteContentActivity contentActivity) async {
    final Map<String, GBVData> gbvDataMap = <String, GBVData>{};
    final List<ResourceFavorite> resources = <ResourceFavorite>[];
    final LinkedHashSet<String>? favoriteIds = Auth2().prefs?.getFavorites(HomeSavedResourcesWidget.favoriteKey);
    if (favoriteIds != null) {
      List<Future<dynamic>> futures = <Future<dynamic>>[];
      Map<String, int> gbvFuturesMap = <String, int>{};

      // 1. Build favorites list and load GBV data futures
      List<ResourceFavorite> favorites = <ResourceFavorite>[];
      for (String favoriteId in favoriteIds) {
        ResourceFavorite favorite = ResourceFavorite.fromString(favoriteId, key: HomeSavedResourcesWidget.favoriteKey);
        favorites.add(favorite);

        String? category = favorite.category;
        if (category != null) {
          int? futureIndex = gbvFuturesMap[category];
          if ((futureIndex == null) && ((FavoriteContentActivity.update.index < contentActivity.index) || (_gbvDataMap.containsKey(category) != true))) {
            gbvFuturesMap[category] = futures.length;
            futures.add(favorite.isContentCategory ? Content().loadContentItem(category) : _AppBundleUtils.loadJson(category));
          }
        }
      }

      int guideFutureIndex = (contentActivity == FavoriteContentActivity.refresh) ? futures.length : -1;
      if (guideFutureIndex >= 0) {
        futures.add(Guide().refresh());
      }

      // 2. Load GBV data
      List<dynamic> results = futures.isNotEmpty ? await Future.wait(futures) : <dynamic>[];

      // 3. Fill gbvDataMap
      for (String category in gbvFuturesMap.keys) {
        int? index = gbvFuturesMap[category];
        dynamic gbvJson = ((index != null) && (0 <= index) && (index < results.length)) ? results[index] : null;
        GBVData? gbvData = GBVData.fromJson(JsonUtils.mapValue(gbvJson));
        if (gbvData != null) {
          gbvDataMap[category] = gbvData;
        }
      }

      // 4. Fill resources
      for (ResourceFavorite favorite in favorites.reversed) {
        String? category = favorite.category;
        if (category != null) {
          final GBVData? categoryData = gbvDataMap[category] ?? _gbvDataMap[category];
          final GBVResource? gbvResource = categoryData?.resources.firstWhereOrNull((resource) => (resource.id == favorite.id));
          if (gbvResource != null) {
            resources.add(favorite);
          }
        } else {
          final Map<String, dynamic>? guideEntry = Guide().entryById(favorite.id);
          if (guideEntry != null) {
            resources.add(favorite);
          }
        }
      }
    }
    return _GBVResourcesContent(resources: resources, gbvDataMap: gbvDataMap);
  }

  Future<bool?> _load(FavoriteContentActivity contentActivity) async {
    if ((_contentActivity.index < contentActivity.index) && Connectivity().isNotOffline && (mounted == true)) {

      setState((){
        _contentActivity = contentActivity;
      });

      _GBVResourcesContent result = await _loadContent(_contentActivity);

      if (mounted == true) {
        bool resourcesUpdated = (DeepCollectionEquality().equals(_resources, result.resources) != true);

        setState(() {
          if (resourcesUpdated) {
            _resources = result.resources;
            if (contentActivity == FavoriteContentActivity.update) {
              _gbvDataMap.addAll(result.gbvDataMap);
            } else {
              _gbvDataMap = result.gbvDataMap;
            }
          }
          _contentActivity = FavoriteContentActivity.none;
        });
        return resourcesUpdated;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  Future<void> _reload() => _load(FavoriteContentActivity.reload);
  Future<void> _refresh() => _load(FavoriteContentActivity.refresh);
  Future<void> _update() => _load(FavoriteContentActivity.update);

  // Empty Content

  static const String localScheme = 'local';
  static const String localUniversityLivingHost = 'university_living';
  static const String localUniversityLivingUrlMacro = '{{local_university_living_url}}';
  static const String localAcademicLinksHost = 'academic_links';
  static const String localAcademicLinksUrlMacro = '{{local_academics_links_url}}';
  static const String localCareerLinksHost = 'career_links';
  static const String localCareerLinksUrlMacro = '{{local_career_links_url}}';
  static const String localDiningLinksHost = 'dining_links';
  static const String localDiningLinksUrlMacro = '{{local_dining_links_url}}';
  static const String localTransportationLinksHost = 'transportation_links';
  static const String localTransportationLinksUrlMacro = '{{local_transportation_links_url}}';
  static const String localWellnessLinksHost = 'wellness_links';
  static const String localWellnessLinksUrlMacro = '{{local_wellness_links_url}}';
  static const String privacyScheme = 'privacy';
  static const String privacyLevelHost = 'level';
  static const String privacyUrlMacro = '{{privacy_url}}';

  String get _emptyContentMessageHtml =>
    Localization().getStringEx("widget.home.saved_resources.text.empty.description", "Tap the \u2606 on items in <a href='$localUniversityLivingUrlMacro'><b>University Living</b></a>, <a href='$localAcademicLinksUrlMacro'><b>Academic Links</b></a>, <a href='$localCareerLinksUrlMacro'><b>Career Planning Links</b></a>, <a href='$localDiningLinksUrlMacro'><b>Campus Dining</b></a>, <a href='$localTransportationLinksUrlMacro'><b>Transportation Dining</b></a> or <a href='localWellnessLinksUrlMacro'><b>24/7 Hotlines & Links</b></a> for quick access here. (<a href='$privacyUrlMacro'>Your privacy level</a> must be at least 3.)")
      .replaceAll(localUniversityLivingUrlMacro, '$localScheme://$localUniversityLivingHost')
      .replaceAll(localAcademicLinksUrlMacro, '$localScheme://$localAcademicLinksHost')
      .replaceAll(localCareerLinksUrlMacro, '$localScheme://$localCareerLinksHost')
      .replaceAll(localDiningLinksUrlMacro, '$localScheme://$localDiningLinksHost')
      .replaceAll(localTransportationLinksUrlMacro, '$localScheme://$localTransportationLinksHost')
      .replaceAll(localWellnessLinksUrlMacro, '$localScheme://$localWellnessLinksHost')
      .replaceAll(privacyUrlMacro, '$privacyScheme://$privacyLevelHost');

  void _onTapEmptyContentMessageLink(String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if (uri?.scheme == localScheme) {
      if (uri?.host == localUniversityLivingHost) {
        Analytics().logSelect(target: 'University Living', source: runtimeType.toString());
        Navigator.push(context, CupertinoPageRoute(builder: (context) => CampusGuidePanel()));
      } else if (uri?.host == localAcademicLinksHost) {
        Analytics().logSelect(target: 'Academic Links', source: runtimeType.toString());
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AcademicLinksPanel()));
      } else if (uri?.host == localCareerLinksHost) {
        Analytics().logSelect(target: 'Career Planning Links', source: runtimeType.toString());
        Navigator.push(context, CupertinoPageRoute(builder: (context) => CareerPlanningLinksPanel()));
      } else if (uri?.host == localDiningLinksHost) {
        Analytics().logSelect(target: 'Campus Dining', source: runtimeType.toString());
        Navigator.push(context, CupertinoPageRoute(builder: (context) => DiningLinksPanel()));
      } else if (uri?.host == localTransportationLinksHost) {
        Analytics().logSelect(target: 'Transportation Links', source: runtimeType.toString());
        Navigator.push(context, CupertinoPageRoute(builder: (context) => TransportationLinksPanel()));
      } else if (uri?.host == localWellnessLinksHost) {
        Analytics().logSelect(target: '24/7 Hotlines & Links', source: runtimeType.toString());
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessLinksPanel()));
      }
  } else if (uri?.scheme == privacyScheme) {
      if (uri?.host == privacyLevelHost) {
        Analytics().logSelect(target: 'Privacy Level', source: runtimeType.toString());
        Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,)));
      }
    }
  }
}

class SavedResourcesPanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SavedResourcesPanelState();
}

class _SavedResourcesPanelState extends _SavedResourcesImplWidgetState<SavedResourcesPanel> with NotificationsListener {

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {

    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      AppLivecycle.notifyStateChanged,
      Auth2.notifyLoginChanged,
      Auth2.notifyPrefsChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      Guide.notifyChanged,
    ]);

    _reload();

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Connectivity.notifyStatusChanged) {
      _reload(); // or mark as needs refresh
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _update();
    }
    else if (name == Auth2.notifyLoginChanged) {
      _reload(); // or mark as needs refresh
    }
    else if (name == Auth2.notifyPrefsChanged) {
      _reload(); // or mark as needs refresh
    }
    else if (name == Guide.notifyChanged) {
      _update();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HeaderBar(title: HomeSavedResourcesWidget.title,),
    body: _scaffoldContent,
    backgroundColor: Styles().colors.background,
    bottomNavigationBar: uiuc.TabBar(),
  );

  Widget get _scaffoldContent =>
    RefreshIndicator(onRefresh: _onPullToRefresh, child: _panelContent);

  Widget get _panelContent {
    if (_contentActivity == FavoriteContentActivity.reload) {
      return _loadingContent;
    }
    else if (_contentActivity == FavoriteContentActivity.refresh) {
      return Container();
    }
    else if (Connectivity().isOffline) {
      return _buildStatus(Localization().getStringEx("widget.home.saved_resources.text.offline.description", "Saved resources are not available while offline."));
    }
    else if (_resources.length == 0) {
      return _buildStatus(_emptyContentMessageHtml);
    }
    else {
      return _resourceContent;
    }
  }

  Widget get _resourceContent => ListView.separated(
    itemCount: _resources.length,
    itemBuilder: _buildResource,
    separatorBuilder: (context, index) => SizedBox(height: 8,),
    controller: _scrollController,
    physics: AlwaysScrollableScrollPhysics(),
    scrollDirection: Axis.vertical,
    padding: EdgeInsets.all(16),
  );

  Widget _buildResource(BuildContext context, int index) {
    ResourceFavorite? favorite = ListUtils.entry(_resources, index);
    Widget? resourceWidget = (favorite != null) ? _resourceWidget(favorite, displayMode: CardDisplayMode.browse) : null;
    return resourceWidget ?? Container();
  }

  Widget get _loadingContent =>
    Column(children: [
      Expanded(flex: 1, child: Container()),
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary,)
      ),
      Expanded(flex: 2, child: Container()),
    ],);

  Widget _buildStatus(String statusHtml) {
    double screenHeight = MediaQuery.of(context).size.height;
    return SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child:
      Padding(padding: EdgeInsets.only(left: 32, right: 32, top: screenHeight / 5), child:
        Row(children: [
          Expanded(child:
            HtmlWidget("<center>$statusHtml</center>" ,
              onTapUrl: (url) { _onTapEmptyContentMessageLink(url); return true; },
              textStyle:  Styles().textStyles.getTextStyle("widget.card.title.regular.fat"),
              customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null
            )
          ),
        ],)
      ),
    );
  }

  Future<void> _onPullToRefresh() => _refresh();
}

class GuideResourceWidget extends StatelessWidget {
  final String? favoriteKey;
  final String? guideEntryId;
  final CardDisplayMode displayMode;

  GuideResourceWidget({super.key, this.favoriteKey, this.guideEntryId, this.displayMode = CardDisplayMode.browse});

  bool get _canFavorite => (favoriteKey != null);

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? guideEntry = Guide().entryById(guideEntryId);

    final int titleMaxLines = 1;
    String titleHtml = Guide().entryListTitle(guideEntry) ?? '';
    TextStyle? titleTextStyle = Styles().textStyles.getTextStyle("widget.button.title.medium.fat");
    double titleMaxTextHeight = MediaQuery.of(context).textScaler.scale(titleTextStyle?.fontSize ?? 0) * 1.5 * titleMaxLines;
    Widget titleWidget = StringUtils.containsHtmlTags(titleHtml) ?
      Container(constraints: BoxConstraints(maxHeight: titleMaxTextHeight), child:
        HtmlWidget('<div>$titleHtml</div>',
          textStyle: titleTextStyle,
          customStylesBuilder: (element) => _htmlContentStyles[element.localName],
          onTapUrl: (String url) => _onTapHtmlLink(context, url),
        )
      ) : Text(titleHtml, style: titleTextStyle, maxLines: titleMaxLines, overflow: TextOverflow.ellipsis,);

    Widget contentWidget;
    String descriptionHtml = Guide().entryListDescription(guideEntry) ?? '';
    if (descriptionHtml.isNotEmpty) {

      final int descriptionMaxLines = 3;
      TextStyle? descriptionTextStyle = Styles().textStyles.getTextStyle("widget.detail.small");
      double descriptionMaxTextHeight = MediaQuery.of(context).textScaler.scale(descriptionTextStyle?.fontSize ?? 0) * 1.5 * descriptionMaxLines;
      Widget descriptionWidget = StringUtils.containsHtmlTags(descriptionHtml) ?
        Container(constraints: BoxConstraints(maxHeight: descriptionMaxTextHeight), child:
          HtmlWidget('<div>$descriptionHtml</div>',
            textStyle: descriptionTextStyle,
            customStylesBuilder: (element) => _htmlContentStyles[element.localName],
            onTapUrl: (String url) => _onTapHtmlLink(context, url),
          )
        ) :
        Text(descriptionHtml, style: descriptionTextStyle, maxLines: descriptionMaxLines, overflow: TextOverflow.ellipsis,);

      double favTitleOffsetY = max(FavoriteStarIcon.defaultButtonSize - MediaQuery.of(context).textScaler.scale(titleTextStyle?.fontSize ?? 0) * 1.5, 0) / 2;

      contentWidget = Padding(padding: _canFavorite ? EdgeInsets.zero : EdgeInsets.only(bottom: 4), child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_canFavorite)
            FavoriteButton(style: FavoriteIconStyle.Button, favorite: ResourceFavorite(key: favoriteKey ?? '', id: guideEntryId),),
          Expanded(child:
            Row(children: [
              Expanded(child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Padding(padding: _canFavorite ? EdgeInsets.only(top: favTitleOffsetY) : EdgeInsets.only(left: 16, top: 16), child:
                    titleWidget
                  ),
                  Padding(padding: EdgeInsets.only(left: _canFavorite ? 0 : 16, top: 12, bottom: 12), child:
                    descriptionWidget
                  ),
                ])
              ),
              Padding(padding: EdgeInsets.symmetric(horizontal: 8), child:
                Styles().images.getImage('chevron-right', width: 12, height: 12, fit: BoxFit.contain) ?? Container()
              )
            ]),
          )
        ]),
      );
    } else {
      contentWidget = Row(children: [
        if (_canFavorite)
          FavoriteButton(style: FavoriteIconStyle.Button, favorite: ResourceFavorite(key: favoriteKey ?? '', id: guideEntryId),),
        Expanded(child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: _canFavorite ? EdgeInsets.zero : EdgeInsets.only(left: 16, top: 16, bottom: 16), child:
              titleWidget
            ),
          ])
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 8), child:
          Styles().images.getImage('chevron-right', width: 12, height: 12, fit: BoxFit.contain) ?? Container()
        )
      ]);
    }

    return GestureDetector(onTap: () => _onTapGuideEntry(context), child:
      Container(decoration: _contentDecoration, child:
        ClipRRect(borderRadius: _contentBorderRadius, child:
          contentWidget
        )
      )
    );
  }

  BoxDecoration get _contentDecoration {
    switch (displayMode) {
      case CardDisplayMode.browse: return GBVResourceWidget.browseContentDecoraton;
      case CardDisplayMode.home: return HomeCard.boxDecoration;
    }
  }

  BorderRadius get _contentBorderRadius {
    switch (displayMode) {
      case CardDisplayMode.browse: return GBVResourceWidget.browseBorderRadius;
      case CardDisplayMode.home: return HomeCard.borderRadius;
    }
  }

  void _onTapGuideEntry(BuildContext context) {
    Analytics().logSelect(target: "Guide Entry: $guideEntryId");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideDetailPanel(
      guideEntryId: guideEntryId,
      favoriteKey: favoriteKey,
    )));
  }

  Map<String, Map<String, String>> get _htmlContentStyles => {
    'a' : _htmlLinkStyle,
    'div' : _htmlLimitTextStyle,
  };

  Map<String, String> get _htmlLimitTextStyle => <String, String>{
    'line-clamp': '3',
    //'text-overflow': 'ellipsis',
  };

  Map<String, String> get _htmlLinkStyle => <String, String>{
    // 'color': _htmlLinkColor,
    'text-decoration-color': _htmlLinkColor,
  };

  String get _htmlLinkColor =>
    ColorUtils.toHex(Styles().colors.fillColorSecondary);

  bool _onTapHtmlLink(BuildContext context, String url)  {
    Analytics().logSelect(target: 'Link: $url');
    if (DeepLink().isAppUrl(url)) {
      DeepLink().launchUrl(url);
    } else {
      AppLaunchUrl.launchExternal(url: url);
    }
    return true;
  }
}

class _HomeSavedResourcesFavoriteAlertDialog extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _HomeSavedResourcesFavoriteAlertDialogState();

  static Future<bool?>show(BuildContext context) =>
    showDialog(context: context, builder: (_) => AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: _HomeSavedResourcesFavoriteAlertDialog(),
    ));
}

class _HomeSavedResourcesFavoriteAlertDialogState extends State<_HomeSavedResourcesFavoriteAlertDialog> {
  @override
  Widget build(BuildContext context) =>
    Container(decoration: _contentDecoration, child:
      ClipRRect(borderRadius: _contentBorderRadius, child:
          Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: EdgeInsetsGeometry.only(left: 24, right: 24, top: 24, bottom: 16), child:
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_promptText, style: _textStyle, textAlign: TextAlign.center,),
                Padding(padding: EdgeInsetsGeometry.only(top: 16), child:
                  Row(children: [
                    Expanded(child:
                      CompactRoundedButton(
                        label: Localization().getStringEx('dialog.no.title', 'No'),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        borderColor: Styles().colors.fillColorPrimary,
                        onTap: () => _onConfirm(false),
                      ),
                    ),
                    SizedBox(width: 16,),
                    Expanded(child:
                      CompactRoundedButton(
                        label: Localization().getStringEx('dialog.yes.title', 'Yes'),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        onTap: () => _onConfirm(true),),
                    ),
                  ],)
                )
              ]),
            ),
            Divider(color: _contentBorderColor, height: _contentBorderSize,),
            Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 24), child:
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                InkWell(onTap: _onDontShow, child:
                  Padding(padding: EdgeInsets.all(16), child:
                    Styles().images.getImage(_dontShow ? "check-circle-filled" : "check-circle-outline-gray"),
                  ),
                ),
                Text(_dontShowText, style: _textStyle, textAlign: TextAlign.left, )
              ]),
            )
          ],)
      )
    );

  bool get _dontShow => (Storage().askForSavedResourcesHomeFavorite == false);

  void _onDontShow() {
    setState(() {
      Storage().askForSavedResourcesHomeFavorite = !_dontShow;
    });
  }

  void _onConfirm(bool selection) {
    Analytics().logSelect(target: selection ? 'Yes' : 'No');
    Navigator.of(context).pop(selection);
  }

  String get _promptText => Localization().getStringEx('widget.home.saved_resources.favorites.prompt', 'Item saved. Add your Saved Resources to your Home Favorites?');
  String get _dontShowText => Localization().getStringEx('widget.home.saved_resources.favorites.dont_show_again', "Don't show me this again.");

  TextStyle? get _textStyle => Styles().textStyles.getTextStyle('widget.detail.regular');

  BoxDecoration get _contentDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: _contentBorderColor, width: _contentBorderSize),
    borderRadius: _contentBorderRadius,
  );

  Color get _contentBorderColor => Styles().colors.surfaceAccent;
  double get _contentBorderSize => 1;

  BorderRadius get _contentBorderRadius =>
    BorderRadius.all(Radius.circular(12));
}

class _HomeSavedResourcesFavoriteButton extends HomeFavoriteButton {
  _HomeSavedResourcesFavoriteButton({ super.favorite, required super.style, super.padding = FavoriteStarIcon.defaultPadding, super.prompt = false});

  @override
  bool? get isFavorite => (super.isFavorite != false);
}

class ResourceFavorite extends Favorite {
  final String key;
  final String? category;
  final String? id;

  ResourceFavorite({ required this.key, this.category, this.id });

  factory ResourceFavorite.fromString(String value, { required String key}) {
    List<String> items = value.split(_favoriteSeparator);
    if (items.length > 1) {
      return ResourceFavorite(key: key, category: items.first, id: items.second);
    } else if (items.length == 1) {
      return ResourceFavorite(key: key, id: items.first);
    } else {
      return ResourceFavorite(key: key);
    }
  }

  bool get isContentAsset {
    List<String>? pathItems = category?.split(_directorySeparator);
    if ((pathItems != null) && (pathItems.length > 1)) { // has directory & base name
      List<String> basenameItems = pathItems.last.split(_extensionSeparator);
      return (basenameItems.length > 1); // has file name & extension
    } else {
      return false;
    }
  }

  bool get isContentCategory => (category != null) && (category?.isNotEmpty == true) && (isContentAsset == false);

  bool operator == (o) => o is ResourceFavorite && o.id == id && o.category == category && o.key == key;
  int get hashCode => (id?.hashCode ?? 0) ^ (category?.hashCode ?? 0) ^ (key.hashCode);

  @override String get favoriteKey => key;
  @override String? get favoriteId => ((category != null) && (id != null)) ? '$category$_favoriteSeparator$id' : id;

  static const String _favoriteSeparator = ':';
  static const String _directorySeparator = '/';
  static const String _extensionSeparator = '.';
}

class _GBVResourcesContent {
  final List<ResourceFavorite> resources;
  final Map<String, GBVData> gbvDataMap;

  _GBVResourcesContent({required this.resources, required this.gbvDataMap });

  // ignore: unused_element
  factory _GBVResourcesContent.empty() => _GBVResourcesContent(
    resources:  <ResourceFavorite>[],
    gbvDataMap: <String, GBVData>{},
  );
}

extension _AppBundleUtils on AppBundle {
  static Future<dynamic> loadJson(String key, {bool cache = true}) async =>
    JsonUtils.decode(await AppBundle.loadString(key, cache: cache));
}

extension _CardDisplayModeImpl on CardDisplayMode {
  GBVResourceDisplayMode get resourceDisplayMode {
    switch (this) {
      case CardDisplayMode.home: return GBVResourceDisplayMode.home;
      case CardDisplayMode.browse: return GBVResourceDisplayMode.browse;
    }
  }
}