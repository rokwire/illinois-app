
import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/model/GBV.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Content.dart';
import 'package:illinois/ui/academics/AcademicsLinks.dart';
import 'package:illinois/ui/accessibility/AccessiblePageView.dart';
import 'package:illinois/ui/career/CareerPlanningLinks.dart';
import 'package:illinois/ui/dining/DiningLinksPanel.dart';
import 'package:illinois/ui/gbv/GBVResourceDirectoryPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/ui/wellness/WellnessLinksPanel.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';


class HomeSavedGBVResourcesWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  static const String favoriteKey = 'savedGBVResourcesKeys';

  HomeSavedGBVResourcesWidget({super.key, this.favoriteId, this.updateController});

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  String get _title => title;
  static String get title => Localization().getStringEx('widget.home.saved_gbv_resources.title', 'Saved Resources2');

  @override
  State<StatefulWidget> createState() => _HomeSavedGBVResourcesWidgetState();
}

class _HomeSavedGBVResourcesWidgetState extends State<HomeSavedGBVResourcesWidget> with NotificationsListener {

  LinkedHashMap<GBVResourceFavorite, GBVResource>? _resources;
  Map<String, GBVData> _gbvDataMap = <String, GBVData>{};
  FavoriteContentActivity _contentActivity = FavoriteContentActivity.none;

  bool _visible = false;
  Key _visibilityDetectorKey = UniqueKey();
  DateTime? _pausedDateTime;
  FavoriteContentStatus _contentStatus = FavoriteContentStatus.none;

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
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);

    _updateSubscription = widget.updateController?.stream.listen((String command) {
      if (command == HomePanel.notifyRefresh) {
        _reloadIfVisible();
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
      _reloadIfVisible();
    }
    else if (name == Auth2.notifyLoginChanged) {
      _reloadIfVisible(); // or mark as needs refresh
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
          _refreshIfVisible();
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
        message: Localization().getStringEx("widget.home.saved_gbv_resources.text.offline.description", "Saved resources are not available while offline."),
      );
    }
    else if (_contentActivity.showsProgress) {
      return HomeProgressWidget();
    }
    else if (_resources == null) {
      return HomeMessageCard(
        title: Localization().getStringEx('common.label.failed', 'Failed'),
        message: Localization().getStringEx('logic.general.unknown_error', 'Unknown Error Occurred')
      );
    }
    else if (_resources?.length == 0) {
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
    int resourcesCount = _resources?.length ?? 0;
    if (1 < resourcesCount) {
      List<Widget> pages = <Widget>[];
      _resources?.forEach((GBVResourceFavorite favorite, GBVResource resource) {
        String contentKey = "${favorite.category}-${favorite.id}";
        pages.add(Padding(
          key: _contentKeys[contentKey] ??= GlobalKey(),
          padding: HomeCard.defaultPageMargin,
          child: GBVResourceWidget(resource,
            gbvData: _gbvDataMap[favorite.category],
            favoriteKey: HomeSavedGBVResourcesWidget.favoriteKey,
            favoriteCategory: favorite.category,
          )
        ));
      });

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
    } else if (resourcesCount == 1) {
      GBVResourceFavorite? favorite = _resources?.keys.first;
      GBVResource? resource = _resources?[favorite];
      contentWidget = (resource != null) ? Padding(padding: HomeCard.defaultSingleCardMargin, child:
        GBVResourceWidget(resource,
          gbvData: _gbvDataMap[favorite?.category],
          favoriteKey: HomeSavedGBVResourcesWidget.favoriteKey,
          favoriteCategory: favorite?.category,
        )
      ) : null;
    }

    return (contentWidget != null) ? Column(children: <Widget>[
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => resourcesCount,),
    ]) : Container();
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
        case FavoriteContentStatus.refresh: _refresh(); break;
        case FavoriteContentStatus.reload: _reload(); break;
      }
    }
  }

  // Data

  Future<Pair<LinkedHashMap<GBVResourceFavorite, GBVResource>, Map<String, GBVData>>> _loadContent() async {
    Map<String, GBVData> gbvDataMap = <String, GBVData>{};
    LinkedHashMap<GBVResourceFavorite, GBVResource> resources = LinkedHashMap<GBVResourceFavorite, GBVResource>();
    LinkedHashSet<String>? favoriteIds = Auth2().prefs?.getFavorites(HomeSavedGBVResourcesWidget.favoriteKey);
    if (favoriteIds != null) {
      List<GBVResourceFavorite> favorites = <GBVResourceFavorite>[];
      List<Future<dynamic>> futures = <Future<dynamic>>[];
      Map<String, int> futuresMap = <String, int>{};

      // 1. Build favorites list and load GBV data futures
      for (String favoriteId in favoriteIds) {
        GBVResourceFavorite favorite = GBVResourceFavorite.fromString(favoriteId, key: HomeSavedGBVResourcesWidget.favoriteKey);
        String? category = favorite.category;
        if (category != null) {
          favorites.add(favorite);
          int? futureIndex = futuresMap[category];
          if (futureIndex == null) {
            futuresMap[category] = futures.length;
            futures.add(favorite.isContentCategory ? Content().loadContentItem(category) : _AppBundleUtils.loadJson(category));
          }
        }
      }

      // 2. Load GBV data
      List<dynamic> results = futures.isNotEmpty ? await Future.wait(futures) : <dynamic>[];

      // 3. Fill gbvDataMap
      for (String category in futuresMap.keys) {
        int? index = futuresMap[category];
        dynamic gbvJson = ((index != null) && (0 <= index) && (index < results.length)) ? results[index] : null;
        GBVData? gbvData = GBVData.fromJson(JsonUtils.mapValue(gbvJson));
        if (gbvData != null) {
          gbvDataMap[category] = gbvData;
        }
      }

      // 4. Fill resources
      for (GBVResourceFavorite favorite in favorites) {
        GBVResource? gbvResource = gbvDataMap[favorite.category]?.resources.firstWhereOrNull((resource) => (resource.id == favorite.id));
        if (gbvResource != null) {
          resources[favorite] = gbvResource;
        }
      }
    }
    return Pair(resources, gbvDataMap);
  }

  Future<void> _reloadIfVisible() async {
    if (_visible) {
      return _reload();
    }
    else if (_contentStatus.canReload) {
      _contentStatus = FavoriteContentStatus.reload;
    }
  }

  Future<void> _reload() async {
    if (_contentActivity.canReloadOrRefresh && mounted) {
      setState(() {
        _contentActivity = FavoriteContentActivity.reload;
      });

      Pair<LinkedHashMap<GBVResourceFavorite, GBVResource>, Map<String, GBVData>> result = await _loadContent();

      setStateIfMounted(() {
        _resources = result.left;
        _gbvDataMap = result.right;
        _contentActivity = FavoriteContentActivity.none;
        _contentStatus = FavoriteContentStatus.none;
        _pageViewKey = UniqueKey();
        _contentKeys.clear();
      });
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

  Future<void> _refresh() async {

    if (_contentActivity.canReloadOrRefresh && mounted) {
      setStateIfMounted(() {
        _contentActivity = FavoriteContentActivity.refresh;
      });

      Pair<LinkedHashMap<GBVResourceFavorite, GBVResource>, Map<String, GBVData>> result = await _loadContent();

      setStateIfMounted(() {
        _resources = result.left;
        _gbvDataMap = result.right;
        _contentActivity = FavoriteContentActivity.none;
        _contentStatus = FavoriteContentStatus.none;
        _pageViewKey = UniqueKey();
        _contentKeys.clear();
      });
    }
  }

  // Empty Content

  static const String localScheme = 'local';
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
    Localization().getStringEx("widget.home.saved_gbv_resources.text.empty.description", "Tap the \u2606 on items in <a href='$localAcademicLinksUrlMacro'><b>Academic Links</b></a>, <a href='$localCareerLinksUrlMacro'><b>Career Planning Links</b></a>, <a href='$localDiningLinksUrlMacro'><b>Campus Dining</b></a>, <a href='$localTransportationLinksUrlMacro'><b>Transportation Dining</b></a> or <a href='localWellnessLinksUrlMacro'><b>24/7 Hotlines & Links</b></a> for quick access here. (<a href='$privacyUrlMacro'>Your privacy level</a> must be at least 3.)")
      .replaceAll(localAcademicLinksUrlMacro, '$localScheme://$localAcademicLinksHost')
      .replaceAll(localCareerLinksUrlMacro, '$localScheme://$localCareerLinksHost')
      .replaceAll(localDiningLinksUrlMacro, '$localScheme://$localDiningLinksHost')
      .replaceAll(localTransportationLinksUrlMacro, '$localScheme://$localTransportationLinksHost')
      .replaceAll(localWellnessLinksUrlMacro, '$localScheme://$localWellnessLinksHost')
      .replaceAll(privacyUrlMacro, '$privacyScheme://$privacyLevelHost');

  void _onTapEmptyContentMessageLink(String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if (uri?.scheme == localScheme) {
      if (uri?.host == localAcademicLinksHost) {
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
        //TBD: Navigator.push(context, CupertinoPageRoute(builder: (context) => TransportationLinksPanel()));
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

class _HomeSavedResourcesFavoriteButton extends HomeFavoriteButton {
  _HomeSavedResourcesFavoriteButton({ super.favorite, required super.style, super.padding = FavoriteStarIcon.defaultPadding, super.prompt = false});

  @override
  bool? get isFavorite => (super.isFavorite != false);
}



extension _AppBundleUtils on AppBundle {
  static Future<dynamic> loadJson(String key, {bool cache = true}) async =>
    JsonUtils.decode(await AppBundle.loadString(key, cache: cache));
}