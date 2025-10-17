
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/ext/Building.dart';
import 'package:illinois/ext/Dining.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Map2.dart';
import 'package:illinois/ext/Places.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/Building.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Gateway.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/service/Map2.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/dining/DiningHomePanel.dart';
import 'package:illinois/ui/events2/Event2HomePanel.dart';
import 'package:illinois/ui/explore/ExploreMessagePopup.dart';
import 'package:illinois/ui/map2/Map2BasePanel.dart';
import 'package:illinois/ui/map2/Map2ExplorePOICard.dart';
import 'package:illinois/ui/map2/Map2FilterBuildingAmenitiesPanel.dart';
import 'package:illinois/ui/map2/Map2HomeExts.dart';
import 'package:illinois/ui/map2/Map2HomeFilters.dart';
import 'package:illinois/ui/map2/Map2TraySheet.dart';
import 'package:illinois/ui/map2/Map2Widgets.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/QrCodePanel.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/model/places.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/places.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

enum Map2ContentType { CampusBuildings, StudentCourses, DiningLocations, Events2, LaundryRooms, BusStops, Therapists, StoriedSites, MyLocations, }
enum Map2SortType { dateTime, alphabetical, proximity }
enum Map2SortOrder { ascending, descending }
enum ExploreProgressType { init, update }

typedef LoadExploresTask = Future<List<Explore>?>;

class Map2HomePanel extends StatefulWidget with AnalyticsInfo {
  static const String selectParamKey = "select-param";

  final Map<String, dynamic> initParams = <String, dynamic>{};

  Map2HomePanel({super.key});

  @override
  State<StatefulWidget> createState() => _Map2HomePanelState();

  AnalyticsFeature? get analyticsFeature =>
    _state?._selectedContentType?.analyticsFeature ??
    _initialContentType?.analyticsFeature ??
    AnalyticsFeature.Map;

  static bool get hasState => _state != null;

  static _Map2HomePanelState? get _state {
    Set<NotificationsListener>? subscribers = NotificationService().subscribers(Map2.notifySelect);
    if (subscribers != null) {
      for (NotificationsListener subscriber in subscribers) {
        if ((subscriber is _Map2HomePanelState) && subscriber.mounted) {
          return subscriber;
        }
      }
    }
    return null;
  }

  dynamic get _initialSelectParam => initParams[selectParamKey];

  Map2ContentType? get _initialContentType => _evalInitialContentTypeEx(
    availableTypes: Map2ContentTypeImpl.availableTypes
  );

  Map2ContentType? _evalInitialContentTypeEx({Set<Map2ContentType>? availableTypes}) => Map2ContentTypeImpl.initialType(
    initialSelectParam: _initialSelectParam,
    availableTypes: availableTypes
  );
}

class _Map2HomePanelState extends Map2BasePanelState<Map2HomePanel>
  with NotificationsListener, SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin<Map2HomePanel>
{

  final GlobalKey _scaffoldKey = GlobalKey();
  final GlobalKey _contentHeadingBarKey = GlobalKey();
  final GlobalKey _contentTypesBarKey = GlobalKey();
  final GlobalKey _traySheetKey = GlobalKey();
  final GlobalKey _traySheetHeaderKey = GlobalKey();
  final GlobalKey _sortButtonKey = GlobalKey();
  final GlobalKey _termsButtonKey = GlobalKey();
  final GlobalKey _starredButtonKey = GlobalKey();
  final GlobalKey _amenitiesButtonKey = GlobalKey();
  final GlobalKey _filterButtonKey = GlobalKey();
  final GlobalKey _searchButtonKey = GlobalKey();
  final GlobalKey _paymentTypesButtonKey = GlobalKey();
  final GlobalKey _openNowButtonKey = GlobalKey();


  final ScrollController _contentTypesScrollController = ScrollController();
  final DraggableScrollableController _traySheetController = DraggableScrollableController();
  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchTextNode = FocusNode();

  late Set<Map2ContentType> _availableContentTypes;
  Map2ContentType? _selectedContentType;
  double _contentTypesScrollOffset = 0;

  final Map<Map2ContentType, Map2Filter> _filters = <Map2ContentType, Map2Filter>{};
  bool _searchOn = false;
  bool _mapDisabled = false;
  double? _sortDropdownWidth;
  double? _termsDropdownWidth;
  double? _paymentTypesDropdownWidth;

  List<Explore>? _explores;
  List<Explore>? _filteredExplores;
  List<Explore>? _trayExplores;
  LoadExploresTask? _exploresTask;
  ExploreProgressType? _exploresProgress;

  LinkedHashMap<String, dynamic>? _storiedSitesTags;
  String? _expandedStoriedSitesTag;

  Set<Explore>? _selectedExploreGroup;

  Explore? _pinnedExplore;
  Marker? _pinnedMarker;

  DateTime? _pausedDateTime;
  Position? _currentLocation;
  Map<String, dynamic>? _mapStyles;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Connectivity.notifyStatusChanged,
      LocationServices.notifyStatusChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      Auth2UserPrefs.notifyFavoriteReplaced,
      Map2ExplorePOICard.notifyPOIUpdated,
      Map2.notifySelect,
      FlexUI.notifyChanged,
    ]);

    _availableContentTypes = Map2ContentTypeImpl.availableTypes;
    _selectedContentType = widget._evalInitialContentTypeEx(availableTypes: _availableContentTypes);

    _contentTypesScrollController.addListener(_onContentTypesScroll);
    _traySheetController.addListener(_onSheetDragChanged);

    //updateLocationServicesStatus(updateCamera: true);
    _initSelectNotificationFilters(widget._initialSelectParam);
    _initMapStyles();
    _initExplores();

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _traySheetController.dispose();
    _contentTypesScrollController.dispose();
    _searchTextController.dispose();
    _searchTextNode.dispose();
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == Connectivity.notifyStatusChanged) {
      if (Connectivity().isNotOffline && mounted) {
        _onConnectivityStatusChanged();
      }
    }
    else if (name == LocationServices.notifyStatusChanged) {
      updateLocationServicesStatus(status: param);
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      if ((_selectedContentType == Map2ContentType.MyLocations) && mounted) {
        _updateExplores();
      }
    }
    else if (name == Auth2UserPrefs.notifyFavoriteReplaced) {
      if ((_selectedContentType == Map2ContentType.MyLocations) && (param is Pair) && mounted) {
        Explore? oldExplore = JsonUtils.cast(param.left);
        Explore? newExplore = JsonUtils.cast(param.right);
        if ((oldExplore != null) && (newExplore != null)) {
          _onExplorePOIUpdate(oldExplore, newExplore);
        }
      }
    }
    else if (name == Map2ExplorePOICard.notifyPOIUpdated) {
      if ((_selectedContentType == Map2ContentType.MyLocations) && (param is Pair) && mounted) {
        Explore? oldExplore = JsonUtils.cast(param.left);
        Explore? newExplore = JsonUtils.cast(param.right);
        if ((oldExplore != null) && (newExplore != null)) {
          _onExplorePOIUpdate(oldExplore, newExplore);
        }
      }
    }
    else if (name == Map2.notifySelect) {
      _processSelectNotification(param);
    }
    else if (name == FlexUI.notifyChanged) {
      _updateAvailableContentTypes();
      updateLocationServicesStatus();
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
      _currentLocation = null;
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          if (mounted) {
            updateLocationServicesStatus();
          }
        }
      }
    }
  }

  Future<void> _onConnectivityStatusChanged() async {
    if (Connectivity().isNotOffline && mounted) {
      if (locationServicesStatus == null) {
        await updateLocationServicesStatus();
      }
    }
  }

  // AutomaticKeepAliveClientMixin

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx("panel.map2.header.title", "Map2")),
      backgroundColor: Styles().colors.background,
      body: _scaffoldBody,
    );
  }

  Widget get _scaffoldBody =>
    Stack(key: _scaffoldKey, children: [

      Positioned.fill(child:
        _accessibilityWorkaroundWrapMap(child:
          Visibility(visible: (_exploresProgress == null), child:
            mapView
          )
        )
      ),

      Positioned.fill(child:
        Visibility(visible: (_selectedContentType == null), child:
          Align(alignment: Alignment.topCenter, child:
            _contentTypesBar
          ),
        ),
      ),

      Positioned.fill(child:
        Visibility(visible: (_selectedContentType != null), child:
          Column(children: [
            _contentHeadingBar,
            Expanded(child:
              Visibility(visible: (_exploresProgress == null) && (_trayExplores?.isNotEmpty == true), child:
                _traySheet,
              ),
            )
          ],),
        ),
      ),

      if (_exploresProgress != null)
        Positioned.fill(child:
          Center(child:
            _exploresProgressIndicator,
          ),
        ),

      if (markersProgress == true)
        Positioned.fill(child:
          Center(child:
            _mapProgressIndicator,
          ),
        ),
    ],);


  Widget get _mapProgressIndicator =>
    SizedBox(width: 24, height: 24, child:
      CircularProgressIndicator(color: Styles().colors.accentColor2, strokeWidth: 3,),
    );

  Widget get _exploresProgressIndicator =>
    SizedBox(width: 32, height: 32, child:
      CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
    );

  // Map Overrides

  @override
  Set<Marker>? get mapMarkers => (_pinnedMarker != null) ?
    markers?.union(<Marker>{_pinnedMarker!}) : markers;

  @override
  String? get mapStyle => _currentMapStyle;

  @override
  Size? get mapSize => _scaffoldKey.renderBoxSize;

  @override
  double get mapPadding => ((_trayExplores?.isNotEmpty == true) || _shouldHaveTrayExplores()) ? 80 : 40;

  @override
  double? get mapTopSiblingsHeight {
    double? headerBarHeight = _contentHeadingBarKey.renderBoxSize?.height;
    if (headerBarHeight != null) {
      if (_exploresProgress == ExploreProgressType.init) {
        headerBarHeight += _defaultContentFilterButtonsBarHeight;
      }
      if ((_exploresProgress != null) && (_selectedFilterIfExists?.hasFilter == true)) {
        headerBarHeight += _defaultContentFilterDescriptionBarHeight;
      }
    }
    return headerBarHeight;
  }

  @override
  double? get mapBottomSiblingsHeight {
    if (_trayExplores?.isNotEmpty == true) {
      return _traySheetKey.renderBoxSize?.height;
    }
    else if (_shouldHaveTrayExplores()) {
      double mapHeight = mapSize?.height ?? 0;
      double headerBarHeight = mapTopSiblingsHeight ?? 0;
      return (0 < mapHeight) ? (math.max(mapHeight - headerBarHeight, 0) * _trayInitialSize) : null;
    }
    else {
      return null;
    }
  }

  @override
  List<Explore>? get mapExplores => _filteredExplores;

  @override
  bool isExploreGroupMarkerDisabled(Set<Explore> exploreGroup) =>
    (_pinnedExplore != null) || ((_selectedExploreGroup != null) && (_selectedExploreGroup?.intersection(exploreGroup).isNotEmpty != true));

  @override
  bool isExploreMarkerDisabled(Explore explore) =>
    (_pinnedExplore != null) || (_selectedExploreGroup != null) && (_selectedExploreGroup?.contains(explore) != true);

  @override
  set mapKey(UniqueKey value) => super.mapKey = value;

  @override
  Future<void> buildMapContentData(List<Explore>? explores, { bool updateCamera = false, bool showProgress = false, double? zoom}) =>
    super.buildMapContentData(explores, updateCamera: updateCamera, showProgress: showProgress, zoom: zoom);

  // Map Events

  @override
  void onTapMap(LatLng coordinate) {
    Analytics().logSelect(target: "Map Location: { ${coordinate.latitude.toStringAsFixed(6)}, ${coordinate.longitude.toStringAsFixed(6)} }");
    if (_selectedExploreGroup != null) {
      setState(() {
        _selectedExploreGroup = null;
      });
      updateMapMarkers();
      _updateTrayExplores();
    }
    else if (_selectedContentType == Map2ContentType.MyLocations) {
      if (_pinnedExplore != null) {
        _pinExplore(null);
      }
      else {
        ExplorePOI explorePOI = ExplorePOIImpl.fromMapCoordinate(coordinate);
        if (_explores?.contains(explorePOI) != true) {
          _pinExplore(explorePOI);
        }
      }
    }
  }

  @override
  void onTapMapPoi(PointOfInterest poi) {
    Analytics().logSelect(target: "Map POI: ${poi.name}");
    if (_selectedExploreGroup != null) {
      setState(() {
        _selectedExploreGroup = null;
      });
      updateMapMarkers();
      _updateTrayExplores();
    }
    else if (_selectedContentType == Map2ContentType.MyLocations) {
      ExplorePOI explorePOI = ExplorePOIImpl.fromMapPOI(poi);
      if (_explores?.contains(explorePOI) != true) {
        _pinExplore(explorePOI);
      }
    }
  }

  @override
  void onTapMarker(dynamic origin) {
    if (origin is Explore) {
      Analytics().logSelect(target: "MAP Marker: ${origin.exploreTitle}");
      bool isExplorePOI = origin is ExplorePOI;
      setState(() {
        _selectedExploreGroup = isExplorePOI ? <Explore>{origin} : null;
      });
      updateMapMarkers();
      _updateTrayExplores();
      if (!isExplorePOI) {
        origin.exploreLaunchDetail(context, analyticsFeature: widget.analyticsFeature);
      }
    }
    else if (origin is Set<Explore>) {
      Analytics().logSelect(target: "Marker: { ${origin.length} items }");
      setState(() {
        _selectedExploreGroup = DeepCollectionEquality().equals(_selectedExploreGroup, origin) ? null : origin;
      });
      updateMapMarkers();
      _updateTrayExplores();
      Future.delayed(Duration(milliseconds: (_traySheetController.isAttached && _traySheetController.pixels > 0 ? 0 : _trayAnimationDuration.inMilliseconds)  +  (Platform.isIOS ? 1 : 0)), () =>
          AppSemantics.triggerAccessibilityFocus(_traySheetHeaderKey));
    }
  }

  // Locaction Services

  @override
  Future<void> onLocationServicesStatusChanged({bool updateCamera = false}) async {
    // Update current position, if possile
    if (locationServicesStatus == LocationServicesStatus.permissionAllowed) {
      Position? currentLocation = await LocationServices().location;
      if ((currentLocation != null) && (currentLocation != _currentLocation) && mounted) {

        setState(() {
          _currentLocation = currentLocation;
        });

        if (updateCamera) {
          CameraPosition cameraPosition = CameraPosition(target: currentLocation.gmsLatLng, zoom: Map2BasePanelState.defaultCameraZoom);
          if (mapController != null) {
            mapController?.moveCamera(CameraUpdate.newCameraPosition(cameraPosition));
          }
          else {
            lastCameraPosition = cameraPosition;
          }
        }
      }
    }
  }

  // Content Types

  Widget get _contentTypesBar => 
    SingleChildScrollView(
      key: _contentTypesBarKey,
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.only(top: 16),
      controller: _contentTypesScrollController,
      child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        Row(mainAxisSize: MainAxisSize.min, children: _contentTypesEntries,)
      )
    );
  
  List<Widget> get _contentTypesEntries {
    List<Widget> entries = <Widget>[];
    for (Map2ContentType contentType in Map2ContentType.values) {
      if (_availableContentTypes.contains(contentType)) {
        entries.add(Padding(
          padding: EdgeInsets.only(left: entries.isNotEmpty ? 8 : 0),
          child: Map2ContentTypeButton(contentType.displayTitle,
            onTap: () => _onTapContentTypeEntry(contentType),
          )
        ));
      }
    }
    return entries;
  }

  void _updateAvailableContentTypes() {
    Set<Map2ContentType> availableContentTypes = Map2ContentTypeImpl.availableTypes;
    if (!DeepCollectionEquality().equals(_availableContentTypes, availableContentTypes) && mounted) {
      setState(() {
        _availableContentTypes = availableContentTypes;
      });
      if ((_selectedContentType != null) && !_availableContentTypes.contains(_selectedContentType)) {
        setState(() {
          _selectedContentType = null;
        });
        _initExplores();
      }
    }
  }

  void _onTapContentTypeEntry(Map2ContentType contentType) {
    Analytics().logSelect(target: 'Content: ${contentType.displayTitleEx(language: 'en')}');
    _onContentTypeEntry(contentType);
  }

  void _onContentTypeEntry(Map2ContentType contentType) {
    setState(() {
      Storage().storedMap2ContentType = _selectedContentType = contentType;
    });
    _initExplores();
  }

  void _onContentTypesScroll() {
    _contentTypesScrollOffset = _contentTypesScrollController.offset;
  }

  void _updateContentTypesScrollPosition() {
    if (_contentTypesScrollController.hasClients) {
      _contentTypesScrollController.jumpTo(_contentTypesScrollOffset);
    }
  }

  void _processSelectNotification(dynamic param) {
    Map2ContentType? contentType = Map2ContentTypeImpl.selectParamType(param);
    if ((contentType != null) && mounted) {
      _initSelectNotificationFilters(param);
      _onContentTypeEntry(contentType);
    }
  }

  void _initSelectNotificationFilters(dynamic param) {
    if (param is Map2FilterEvents2Param) {
      _filters[Map2ContentType.Events2] = Map2Events2Filter.defaultFilter(
        searchText: param.searchText
      );
    }
    else if (param is Map2FilterBusStopsParam) {
      _filters[Map2ContentType.BusStops] = Map2BusStopsFilter.defaultFilter(
        searchText: param.searchText,
        starred: param.starred,
      );
    }
    else if (param is Map) {
      Map2FilterDeepLinkParam? deepLinkParam = Map2FilterDeepLinkParam.fromUriParams(JsonUtils.mapCastValue<String, String?>(param));
      if (deepLinkParam != null) {
        MapUtils.set(_filters, deepLinkParam.contentType, deepLinkParam.filter);
      }
    }
  }

  // Content Filters

  Widget get _contentHeadingBar =>
    Container(key: _contentHeadingBarKey, decoration: _contentHeadingDecoration, child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: _searchOn ? <Widget>[
        _contentFilterSearchBar,
      ] : <Widget>[
        _contentTitleBar,
        if ((_exploresProgress == null) || (_exploresProgress == ExploreProgressType.update))
          ...[_contentFilterButtonsBar ?? Container(),
            ...(_contentFilterButtonsExtraBars ?? [])
          ],
        if (_exploresProgress == null)
          _contentFilterDescriptionBar ?? Container(),
      ],),
    );

  BoxDecoration get _contentHeadingDecoration =>
    BoxDecoration(
      color: Styles().colors.background,
      border: Border(bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1),),
      boxShadow: [BoxShadow(color: Styles().colors.dropShadow, spreadRadius: 1, blurRadius: 3, offset: Offset(1, 1) )],
    );

  Widget get _contentTitleBar =>
    Semantics(header: true, container: true, child:
      Row(children: [
        Expanded(child:
          Padding(padding: EdgeInsets.only(left: 16, top: 8, bottom: 8), child:
            Text(_selectedContentType?.displayTitle ?? '', style: Styles().textStyles.getTextStyle('widget.title.regular.fat'),)
          ),
        ),
      Semantics(label: Localization().getStringEx('dialog.close.title', 'Close'), button: true, excludeSemantics: true, container: true, child:
        InkWell(onTap : _onTapClearContentType, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
            Styles().images.getImage('close-circle-small', excludeFromSemantics: true)
          ),
        )
        ),
      ],));

  void _onTapClearContentType() {
    Analytics().logSelect(target: 'Content: Clear');
    setState(() {
      Storage().storedMap2ContentType = _selectedContentType = null;
      _explores = _filteredExplores = null;
      _selectedExploreGroup = null;
      _trayExplores = null;
      _exploresTask = null;
      _exploresProgress = null;

      _storiedSitesTags = null;
      _expandedStoriedSitesTag = null;

      markers = null;
      exploreMapGroups = null;
      targetCameraUpdate = null;
      buildMarkersTask = null;
      lastMapZoom = null;
      markersProgress = false;

      _pinnedExplore = null;
      _pinnedMarker = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_){
      _updateContentTypesScrollPosition();
     _doAccessibilityWorkaround(()=>
        setStateIfMounted()
     ); //Workaround Accessibility
    });
  }

  // My Locactions Content && Selection

  void _pinExplore(Explore? exploreToPin) {
    Explore? pinnedExplore = (_pinnedExplore != exploreToPin) ? exploreToPin : null;
    if ((_pinnedExplore != pinnedExplore) && mounted) {
      setState(() {
        _pinnedExplore = pinnedExplore;
      });
      _updatePinMarker();
      updateMapMarkers();
      _updateTrayExplores();
    }
  }

  Future<void> _updatePinMarker() async {
    Marker? pinednMarker = (_pinnedExplore != null) ? await createPinMarker(_pinnedExplore, imageConfiguration: createLocalImageConfiguration(context)) : null;
    setStateIfMounted((){
      _pinnedMarker = pinednMarker;
    });
  }

  void _onExplorePOIUpdate(Explore oldExplore, Explore newExplore) {
    if (_explores?.contains(oldExplore) == true) {
      _explores?.remove(oldExplore);
      _explores?.insert(0, newExplore);
    }

    if (_filteredExplores?.contains(oldExplore) == true) {
      _filteredExplores?.remove(oldExplore);
      _filteredExplores?.insert(0, newExplore);
    }

    bool groupsModified = false;
    if (exploreMapGroups != null) {
      if (exploreMapGroups?.contains(oldExplore) == true) {
        exploreMapGroups?.remove(oldExplore);
        exploreMapGroups?.add(newExplore);
        groupsModified = true;
      }
      else {
        for (dynamic exploreMapGroup in exploreMapGroups!) {
          if ((exploreMapGroup is Set<Explore>) && exploreMapGroup.contains(oldExplore)) {
            exploreMapGroup.remove(oldExplore);
            exploreMapGroup.add(newExplore);
            groupsModified = true;
          }
        }
      }
    }

    if (_selectedExploreGroup?.contains(oldExplore) == true) {
      _selectedExploreGroup?.remove(oldExplore);
      _selectedExploreGroup?.add(newExplore);
      groupsModified = true;
    }

    if (groupsModified) {
      updateMapMarkers();
      _updateTrayExplores();
    }

    if (_pinnedExplore == oldExplore) {
      _pinnedExplore = newExplore;
      _updatePinMarker();
      _updateTrayExplores();
    }
  }

  // Tray Sheet

  static const List<double> _traySnapSizes = [0.03, 0.35, if (kDebugMode) 0.65, 0.97];
  final double _trayInitialSize = _traySnapSizes[1];
  final double _trayMinSize = _traySnapSizes.first;
  final double _trayMaxSize = _traySnapSizes.last;

  static const _trayAnimationDuration = const Duration(milliseconds: 200);
  static const _trayAnimationCurve = Curves.easeInOut;

  Widget get _traySheet =>
    DraggableScrollableSheet(
      controller: _traySheetController,
      snap: true, snapSizes: _traySnapSizes,
      initialChildSize: _trayMinSize,
      minChildSize: _trayMinSize,
      maxChildSize: _trayMaxSize,

      builder: (BuildContext context, ScrollController scrollController) => Map2TraySheet(
        key: _traySheetKey,
        headerKey: _traySheetHeaderKey,
        explores: _trayExplores,
        scrollController: scrollController,
        currentLocation: _currentLocation,
        totalCount: _trayTotalCount,
        analyticsFeature: widget.analyticsFeature,
      ),
    );

  _onSheetDragChanged() {
    _doAccessibilityWorkaround(()=>
      setStateIfMounted());
  }

  // Map Styles

  static const String _mapStylesAssetName = 'assets/map.styles.json';
  static const String _mapStylesBuildingsKey = 'explore-poi';
  static const String _mapStylesBusStopsKey = 'mtd-stop';

  Future<void> _initMapStyles() async {
    _mapStyles = JsonUtils.decodeMap(await rootBundle.loadString(_mapStylesAssetName));
  }

  String? get _currentMapStyle {
    switch (_selectedContentType) {
      case Map2ContentType.Therapists:
      case Map2ContentType.CampusBuildings: return JsonUtils.encode(_mapStyles?[_mapStylesBuildingsKey]);
      case Map2ContentType.BusStops: return JsonUtils.encode(_mapStyles![_mapStylesBusStopsKey]);
      default: return null;
    }
  }

  // Explores

  Future<void> _initExplores({ExploreProgressType progressType = ExploreProgressType.init}) async {
    if (mounted) {
      LoadExploresTask? exploresTask = _loadExplores();
      _doAccessibilityWorkaround(()=>
        exploresTask?.whenComplete(()=>setStateDelayedIfMounted((){}, duration: Duration(milliseconds: 200))));

      if (exploresTask != null) {
        // start loading
        setState(() {
          _exploresTask = exploresTask;
          _exploresProgress = progressType;
          _explores = _filteredExplores = _trayExplores = null;
          _selectedExploreGroup = null;
          _storiedSitesTags = null;
          _expandedStoriedSitesTag = null;
          _pinnedExplore = null;
          _pinnedMarker = null;
        });

        // wait for explores load
        Map2ContentType? exploreContentType = _selectedContentType;
        List<Explore>? explores = await exploresTask;

        if (mounted && (exploresTask == _exploresTask)) {
          List<Explore>? validExplores = explores?.validList;
          List<Explore>? filteredExplores = _filterExplores(validExplores);
          setState(() {
            _explores = validExplores;
            _filteredExplores = filteredExplores;
            _storiedSitesTags = JsonUtils.cast<List<Place>>(validExplores)?.tags;
          });

          await buildMapContentData(filteredExplores, updateCamera: true);

          if (mounted && (exploresTask == _exploresTask)) {
            setState(() {
              _exploresTask = null;
              _exploresProgress = null;
              mapKey = UniqueKey(); // force map rebuild

              if ((exploreContentType?.supportsManualFilters == true) && (validExplores?.isNotEmpty != true)) {
                _selectedContentType = null; // Unselect content type if there is nothing to show.
              }
            });
            _updateTrayExplores();
            _showContentMessageIfNeeded(exploreContentType, validExplores);
          } else {
            setStateIfMounted();
          }
        }
      }
      else {
        setState(() {
          _explores = _filteredExplores = _trayExplores = null;
          _selectedExploreGroup = null;
          _exploresTask = null;
          _exploresProgress = null;

          _storiedSitesTags = null;
          _expandedStoriedSitesTag = null;

          markers = null;
          exploreMapGroups = null;
          targetCameraUpdate = null;
          buildMarkersTask = null;
          lastMapZoom = null;
          markersProgress = false;

          _pinnedExplore = null;
          _pinnedMarker = null;
        });
      }
    }
  }

  Future<void> _updateExplores() async {
    if (mounted) {
      LoadExploresTask? exploresTask = _loadExplores();
      _doAccessibilityWorkaround(()=>
        exploresTask?.whenComplete(()=>
            setStateDelayedIfMounted((){}, duration: Duration(milliseconds: 200))));

      if (exploresTask != null) {
        // start loading
        setState(() {
          _exploresTask = exploresTask;
          markersProgress = true;
        });

        // wait for explores load
        List<Explore>? explores = await exploresTask;
        List<Explore>? validExplores = explores?.validList;
        List<Explore>? filteredExplores = _filterExplores(validExplores);

        if (mounted && (exploresTask == _exploresTask)) {
          if (!DeepCollectionEquality().equals(_filteredExplores, filteredExplores)) {

            setState(() {
              _explores = validExplores;
              _filteredExplores = filteredExplores;

              if ((_pinnedExplore != null) && (validExplores?.contains(_pinnedExplore) == true)) {
                _selectedExploreGroup = <Explore>{_pinnedExplore!};
                _pinnedExplore = null;
                _pinnedMarker = null;
              }
              else {
                _selectedExploreGroup = null;
              }

              _storiedSitesTags = JsonUtils.cast<List<Place>>(validExplores)?.tags;
              _expandedStoriedSitesTag = null;
            });

            _updateTrayExplores();

            await buildMapContentData(filteredExplores, updateCamera: false, showProgress: true);

            if (mounted && (exploresTask == _exploresTask)) {
              setState(() {
                _exploresTask = null;
                markersProgress = false;
              });
            }
          }
          else {
            setState(() {
              _exploresTask = null;
              markersProgress = false;
            });
          }
        }
      }
    }
  }

  LoadExploresTask? _loadExplores() async {
    switch (_selectedContentType) {
      case Map2ContentType.CampusBuildings:      return _loadCampusBuildings();
      case Map2ContentType.StudentCourses:       return _loadStudentCourses();
      case Map2ContentType.DiningLocations:      return _loadDiningLocations();
      case Map2ContentType.Events2:              return _loadEvents2();
      case Map2ContentType.LaundryRooms:         return _loadLaundryRooms();
      case Map2ContentType.BusStops:             return _loadBusStops();
      case Map2ContentType.Therapists:           return _loadTherapists();
      case Map2ContentType.StoriedSites:         return _loadStoriedSites();
      case Map2ContentType.MyLocations:          return _loadMyLocations();
      default: return null;
    }
  }

  Future<List<Explore>?> _loadCampusBuildings() async =>
    Gateway().loadBuildings();

  Future<List<Explore>?> _loadStudentCourses() async {
    String? termId = _studentCoursesFilter?.termId; // Force filter creation for valid tray content
    return (termId != null) ? await StudentCourses().loadCourses(termId: termId) : null;
  }

  Future<List<Explore>?> _loadDiningLocations() async =>
    Dinings().loadBackendDinings(false, null, null);

  Future<List<Explore>?> _loadEvents2() async =>
    Events2().loadEventsList(await _event2QueryParam());

  Future<Events2Query> _event2QueryParam() async {
    // Force filter creation for valid tray content
    Map2Events2Filter? filter = _events2Filter; // _events2FilterIfExists  ?? Map2Events2Filter.defaultFilter()
    return Events2Query(
      searchText: (filter?.searchText.isNotEmpty == true) ? filter?.searchText : null,
      timeFilter: filter?.event2Filter.timeFilter ?? Event2TimeFilter.upcoming,
      customStartTimeUtc: filter?.event2Filter.customStartTime?.toUtc(),
      customEndTimeUtc: filter?.event2Filter.customEndTime?.toUtc(),
      types: filter?.event2Filter.types,
      groupings: Event2Grouping.individualEvents(),
      attributes: filter?.event2Filter.attributes,
      //sortType: filter.sortType?.toEvent2SortType(),
      //sortOrder: filter.sortOrder?.toEvent2SortOrder(),
      location: _currentLocation,
    );
  }

  Future<List<Explore>?> _loadLaundryRooms() async {
    LaundrySchool? laundrySchool = await Laundries().loadSchoolRooms();
    return laundrySchool?.rooms;
  }

  Future<List<Explore>?> _loadBusStops() async {
    List<Explore>? result;
    if (MTD().stops == null) {
      await MTD().refreshStops();
    }
    if (MTD().stops != null) {
      _collectBusStops(result = <Explore>[], stops: MTD().stops?.stops);
    }
    return result;
  }

  void _collectBusStops(List<Explore> result, { List<MTDStop>? stops }) {
    if (stops != null) {
      for(MTDStop stop in stops) {
        if (stop.hasLocation) {
          result.add(stop);
        }
        if (stop.points != null) {
          _collectBusStops(result, stops: stop.points);
        }
      }
    }
  }

  Future<List<Explore>?> _loadTherapists() =>
    Wellness().loadMentalHealthBuildings();

  Future<List<Explore>?> _loadStoriedSites() =>
    Places().getAllPlaces();

  List<Explore>? _loadMyLocations() {
    List<ExplorePOI>? locations = ExplorePOI.listFromString(Auth2().prefs?.getFavorites(ExplorePOI.favoriteKeyName));
    return (locations != null) ? List.from(locations.reversed) : null;
  }

  List<Explore>? _filterExplores(List<Explore>? explores) =>
    ((explores != null) ? _selectedFilterIfExists?.filter(explores) : explores) ?? explores;

  List<Explore>? _sortExplores(Iterable<Explore>? explores) => (explores != null) ?
    (_selectedFilterIfExists?.sort(explores, position: _currentLocation) ?? List.from(explores)) : null;

  // Tray Content

  List<Explore>? _buildTrayExploresFromSource({
    Iterable<Explore>? filtered,
    Iterable<Explore>? selected,
    Explore? pinned,
  }) => (pinned != null) ? <Explore>[pinned] : _sortExplores(selected ?? filtered);

  List<Explore>? _buildTrayExplores() => _buildTrayExploresFromSource(
    filtered: (_selectedFilterIfExists?.hasFilter == true) ? _filteredExplores : null,
    selected: _selectedExploreGroup,
    pinned: _pinnedExplore,
  );

  bool _shouldHaveTrayExploresFromSource({
    Iterable<Explore>? filtered,
    Iterable<Explore>? selected,
    Explore? pinned,
  }) => (pinned != null) || ((selected ?? filtered)?.isNotEmpty == true);

  bool _shouldHaveTrayExplores() => _shouldHaveTrayExploresFromSource(
    filtered: (_selectedFilterIfExists?.hasFilter == true) ? _filteredExplores : null,
    selected: _selectedExploreGroup,
    pinned: _pinnedExplore,
  );

  int? get _trayTotalCount {
    if (_pinnedExplore != null) {
      return null;
    }
    else if (_selectedExploreGroup != null) {
      return (_filteredExplores ?? _explores)?.length;
    }
    else if (_selectedContentType?.supportsManualFilters == true) {
      return _explores?.length;
    }
    else {
      return null;
    }
  }

  void _updateTrayExplores() {
    List<Explore>? trayExplores = _buildTrayExplores();
    if (mounted && !DeepCollectionEquality().equals(_trayExplores, trayExplores)) {
      bool hadTray = _trayExplores?.isNotEmpty == true;
      bool haveTray = trayExplores?.isNotEmpty == true;
      if (haveTray == hadTray) {
        // Just update thay content
        setState(() {
          _trayExplores = trayExplores;
        });
      }
      else if (haveTray) {
        // Animate tray appearance
        setState(() {
          _trayExplores = trayExplores;
        });
        WidgetsBinding.instance.addPostFrameCallback((_){
          if (_traySheetController.isAttached) {
            _traySheetController.animateTo(_trayInitialSize, duration: _trayAnimationDuration, curve: _trayAnimationCurve);
          }
        });
      }
      else {
        // Animate tray disappearance
        WidgetsBinding.instance.addPostFrameCallback((_){
          if (_traySheetController.isAttached) {
            _traySheetController.animateTo(_trayMinSize, duration: _trayAnimationDuration, curve: _trayAnimationCurve).then((_){
              setStateIfMounted(() {
                _trayExplores = trayExplores;
              });
            });
          }
        });
      }
    }
  }
}

// Map2 Semantics

extension _Map2Semantics on _Map2HomePanelState{
  int? get displayCount => _filteredExplores?.length;
  int? get totalCount => _explores?.length;

  String get _filterButtonHint =>  ". Results in filtering  ${displayCount ?? 0} from ${totalCount ?? 0} Buildings";

  String get _amenitiesSemanticsValue =>  LinkedHashSet<String>.from(_campusBuildingsFilterIfExists?.amenities.keys ?? <String>[]).toString();
}

// Map2 Accessibility Workaround

extension _Map2AccessibilityWorkaround on _Map2HomePanelState{  //Additional functionality and UI changes that will improve the Maps accessibility. Execute it only if needed
  bool get _needAccessibilityWorkaround => (_scaffoldKey.currentContext?.mounted == true) && AppSemantics.isAccessibilityEnabled(context);

  Widget _accessibilityWorkaroundWrapMap({Widget? child}) => VisibilityDetector(key: const Key('map2_location_panel_detector'),
      onVisibilityChanged: _onMapVisibilityChanged, child:
        Padding(padding: _accessibilityWorkaroundMapPadding, child:
          (_mapDisabled == true ? //Get disabled only if accessibility workaround is required
            Container(child: Center(child: Text("Map is disabled"))) : //Workaround to make DropDownMenuItems clickable. They go over MapView and do not get tap actions
            child))
  );//Workaround to make sheet and heading tappable. We resize the map so they don't go over the map

  EdgeInsets get _accessibilityWorkaroundMapPadding {//Workaround for the Maps Accessibility. Even when Map is at the bottom layer of the stack it takes the Tap gestures.
    if(_needAccessibilityWorkaround == false)
      return EdgeInsets.zero;

    double sheetHeight = _traySheetController.isAttached ? _traySheetController.pixels : 0;
    double headerBarHeight = _contentHeadingBarKey.renderBoxSize?.height ?? 0;
    double typesBarHeight = _contentTypesBarKey.renderBoxSize?.height ?? 0;

    double topPadding = _selectedContentType != null ? headerBarHeight : typesBarHeight; //If we have heading reduce the pam size at top
    double bottomPadding = _selectedContentType != null && _trayExplores?.isNotEmpty == true ? sheetHeight : 0;//if we have sheet
    return EdgeInsets.only(top: topPadding, bottom: bottomPadding);
  }

  void _onMenuVisibilityChanged(bool visible) => _needAccessibilityWorkaround ? setStateIfMounted(()=> _mapDisabled = visible) : null;

  void _onMapVisibilityChanged(VisibilityInfo info){
    if(info.visibleFraction == 0){
      if(_mapDisabled == false)
        _accessibilityDisableMap();
    } else {
      if(_mapDisabled == true)
        _accessibilityEnableMap();
    }
  }

  void _doAccessibilityWorkaround(Function? fn) => (_needAccessibilityWorkaround && fn != null) ?
    fn() : null;

  void _accessibilityDisableMap() {
    _doAccessibilityWorkaround(
            ()=> setStateIfMounted(()=>_mapDisabled = true));
    // AppToast.showMessage("Disabled");
  }

  void _accessibilityEnableMap() {
    _doAccessibilityWorkaround(
            ()=> setStateIfMounted(()=>_mapDisabled = false));
    // AppToast.showMessage("Enabled");
  }
}

// Map2 Filters

extension _Map2HomePanelFilters on _Map2HomePanelState {
  
  Widget? get _contentFilterButtonsBar => _buildContentFilterButtonsBar(_filterButtons,
    decoration: _contentFiltersBarDecoration,
    padding: _contentFilterButtonsBarPadding,
  );

  List<Widget>? get _contentFilterButtonsExtraBars {
    List<List<Widget>>? filterExtraButtonsLists = _filterExtraButtons;
    if (filterExtraButtonsLists != null) {
      List<Widget> bars = <Widget>[];
      for (List<Widget> buttons in filterExtraButtonsLists) {
        ListUtils.add(bars, _buildContentFilterButtonsBar(buttons,
          padding: _contentFilterExtraButtonsBarPadding,
        ));
      }
      return bars.isNotEmpty ? bars : null;
    }
    else {
      return null;
    }
  }

  Widget? _buildContentFilterButtonsBar(List<Widget>? buttons, { BoxDecoration? decoration, EdgeInsetsGeometry? padding}) => ((buttons != null) && buttons.isNotEmpty) ?
    Container(decoration: decoration, padding: padding, constraints: _contentFiltersBarConstraints, child:
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(mainAxisSize: MainAxisSize.min, children: buttons,)
      )
    ) : null;

  Widget? get _contentFilterDescriptionBar {
    Map2Filter? selectedFilter = _selectedFilterIfExists;
    LinkedHashMap<String, List<String>>? descriptionMap = (selectedFilter?.hasFilter == true) ?
      selectedFilter?.description(_filteredExplores, canSort: _trayExplores?.isNotEmpty == true) : null;
    if ((descriptionMap != null) && descriptionMap.isNotEmpty)  {
      TextStyle? boldStyle = Styles().textStyles.getTextStyle('widget.card.title.tiny.fat');
      TextStyle? regularStyle = Styles().textStyles.getTextStyle('widget.card.detail.small.regular');
      List<InlineSpan> descriptionList = <InlineSpan>[];
      descriptionMap.forEach((String descriptionCategory, List<String> descriptionItems){
        if (descriptionList.isNotEmpty) {
          descriptionList.add(TextSpan(text: '; ', style: regularStyle,),);
        }
        if (descriptionItems.isEmpty) {
          descriptionList.add(TextSpan(text: descriptionCategory, style: boldStyle,));
        } else {
          descriptionList.add(TextSpan(text: "$descriptionCategory: " , style: boldStyle,));
          descriptionList.add(TextSpan(text: descriptionItems.join(', '), style: regularStyle,),);
        }
      });
      // descriptionList.add(TextSpan(text: '.', style: regularStyle,),);

      return Semantics(container: true, child:
        Container(decoration: _contentFiltersBarDecoration, padding: _contentFilterDescriptionBarPadding, constraints: _contentFiltersBarConstraints, child:
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child:
              IndexedSemantics(index: 1, child: Semantics( container: true, child:
                Padding(padding: EdgeInsets.only(top: 6, bottom: 6), child:
                  RichText(text: TextSpan(style: regularStyle, children: descriptionList)),
                ),
              ))
            ),
            IndexedSemantics(index: 2, child: Semantics( container: true, child:
              Map2PlainImageButton(imageKey: 'share-nodes',
                label: Localization().getStringEx('panel.events2.home.bar.button.share.title', 'Share Event Set'),
                hint: Localization().getStringEx('panel.events2.home.bar.button.share.hinr', 'Tap to share current event set'),
                padding: EdgeInsets.only(left: 16, right: (8 + 2), top: 12, bottom: 12),
                onTap: _onTapShareFilter
              )
            )),
            IndexedSemantics(index: 1, child: Semantics( container: true, child:
              Map2PlainImageButton(imageKey: 'close',
                  label: Localization().getStringEx('panel.events2.home.bar.button.clear.title', 'Clear Filters'),
                  hint: Localization().getStringEx('panel.events2.home.bar.button.clear.hinr', 'Tap to clear current filters'),
                padding: EdgeInsets.only(left: 8 + 2, right: 16 + 2, top: 12, bottom: 12),
                onTap: _onTapClearFilter
              ),
            ))
          ]),
        )
      );
    }
    return null;
  }

  double get _defaultContentFilterDescriptionBarHeight =>
    18 + 2 * 12; // image size + vertical button padding, no bar padding

  BoxConstraints get _contentFiltersBarConstraints => BoxConstraints(
    minWidth: double.infinity
  );

  BoxDecoration get _contentFiltersBarDecoration => BoxDecoration(
    border: Border(top: BorderSide(color: Styles().colors.surfaceAccent, width: 1),),
  );

  double get _defaultContentFilterButtonsBarHeight =>
    Map2FilterImageButton.defaultHeight + 2 * 8;

  EdgeInsetsGeometry get _contentFilterButtonsBarPadding =>
    EdgeInsets.only(left: 16, top: 8, bottom: 8);

  EdgeInsetsGeometry get _contentFilterExtraButtonsBarPadding =>
    EdgeInsets.only(left: 16, bottom: 8);

  EdgeInsetsGeometry get _contentFilterDescriptionBarPadding =>
    EdgeInsets.only(left: 16);

  List<Widget>? get _filterButtons {
    switch (_selectedContentType) {
      case Map2ContentType.CampusBuildings:      return _campusBuildingsFilterButtons;
      case Map2ContentType.StudentCourses:       return _studentCoursesFilterButtons;
      case Map2ContentType.DiningLocations:      return _diningLocationsFilterButtons;
      case Map2ContentType.Events2:              return _events2FilterButtons;
      case Map2ContentType.LaundryRooms:         return _laundryRoomsFilterButtons;
      case Map2ContentType.BusStops:             return _busStopsFilterButtons;
      case Map2ContentType.Therapists:           return null;
      case Map2ContentType.StoriedSites:         return _storiedSitesFilterButtons;
      case Map2ContentType.MyLocations:          return _myLocationsFilterButtons;
      default: return null;
    }
  }

  List<List<Widget>>? get _filterExtraButtons {
    switch (_selectedContentType) {
      case Map2ContentType.StoriedSites:         return _storiedSitesFilterExtraButtons;
      default: return null;
    }
  }

  List<Widget> get _campusBuildingsFilterButtons => <Widget>[
    Padding(padding: _filterButtonsPadding, child:
      _searchFilterButton,
    ),
    if (_isSortAvailable)
      Padding(padding: _filterButtonsPadding, child:
        _sortFilterButton,
      ),
    Padding(padding: _filterButtonsPadding, child:
      _starredFilterButton,
    ),
    Padding(padding: _filterButtonsPadding, child:
      _amenitiesBuildingsFilterButton,
    ),
    _filterButtonsEdgeSpacing,
  ];

  List<Widget> get _studentCoursesFilterButtons => <Widget>[
    if (_isSortAvailable)
      Padding(padding: _filterButtonsPadding, child:
        _sortFilterButton,
      ),
    if (StudentCourses().terms?.isNotEmpty == true)
      Padding(padding: _filterButtonsPadding, child:
        _termsButton,
      ),
    _filterButtonsEdgeSpacing,
  ];

  List<Widget> get _diningLocationsFilterButtons => <Widget>[
    Padding(padding: _filterButtonsPadding, child:
      _searchFilterButton,
    ),
    if (_isSortAvailable)
      Padding(padding: _filterButtonsPadding, child:
        _sortFilterButton,
      ),
    Padding(padding: _filterButtonsPadding, child:
      _starredFilterButton,
    ),
    Padding(padding: _filterButtonsPadding, child:
      _openNowDiningLocationsFilterButton,
    ),
    Padding(padding: _filterButtonsPadding, child:
      _paymentTypesDiningLocationsFilterButton,
    ),
    _filterButtonsEdgeSpacing,
  ];

  List<Widget> get _events2FilterButtons => <Widget>[
    Padding(padding: _filterButtonsPadding, child:
      _searchFilterButton,
    ),
    if (_isSortAvailable)
      Padding(padding: _filterButtonsPadding, child:
        _sortFilterButton,
      ),
    Padding(padding: _filterButtonsPadding, child:
      _filtersFilterButton,
    ),
    _filterButtonsEdgeSpacing,
  ];

  List<Widget> get _laundryRoomsFilterButtons => <Widget>[
    Padding(padding: _filterButtonsPadding, child:
      _searchFilterButton,
    ),
    if (_isSortAvailable)
      Padding(padding: _filterButtonsPadding, child:
        _sortFilterButton,
      ),
    Padding(padding: _filterButtonsPadding, child:
      _starredFilterButton,
    ),
    _filterButtonsEdgeSpacing,
  ];

  List<Widget> get _busStopsFilterButtons => <Widget>[
    Padding(padding: _filterButtonsPadding, child:
      _searchFilterButton,
    ),
    if (_isSortAvailable)
      Padding(padding: _filterButtonsPadding, child:
        _sortFilterButton,
      ),
    Padding(padding: _filterButtonsPadding, child:
      _starredFilterButton,
    ),
    _filterButtonsEdgeSpacing,
  ];


  List<Widget> get _storiedSitesFilterButtons => <Widget>[
    Padding(padding: _filterButtonsPadding, child:
      _searchFilterButton,
    ),
    if (_isSortAvailable)
      Padding(padding: _filterButtonsPadding, child:
        _sortFilterButton,
      ),
    Padding(padding: _filterButtonsPadding, child:
      _visitedStoriedSitesFilterButton,
    ),
    if (_storiedSitesTags != null)
      ..._storiedSitesTagButtons(_storiedSitesTags!)
  ];

  List<List<Widget>>? get _storiedSitesFilterExtraButtons {
    if ((_storiedSitesTags != null) && (_expandedStoriedSitesTag != null)) {
      List<List<Widget>> buttons = <List<Widget>>[];
      String tagPrefix = '';
      LinkedHashMap<String, dynamic>? subTags = _storiedSitesTags;
      List<String> expandedTags = _expandedStoriedSitesTag?.split('.') ?? <String>[];
      for (String expandedTag in expandedTags) {
        LinkedHashMap<String, dynamic>? expandedSubTags = subTags?[expandedTag];
        String expandedTagPrefix = tagPrefix.isNotEmpty ? "$tagPrefix.$expandedTag" : expandedTag;
        List<Widget>? subTagButtons = (expandedSubTags != null) ? _storiedSitesTagButtons(expandedSubTags, tagPrefix: expandedTagPrefix) : null;
        if ((subTagButtons != null) && subTagButtons.isNotEmpty) {
          buttons.add(subTagButtons);
          subTags = expandedSubTags;
          tagPrefix = expandedTagPrefix;
        }
        else {
          break;
        }
      }
      return buttons;
    }
    else {
      return null;
    }
  }

  List<Widget> _storiedSitesTagButtons(LinkedHashMap<String, dynamic> tags, { String? tagPrefix }) {
    List<Widget> buttons = <Widget>[];

    // First add simple tag buttons
    for (String tagEntry in tags.keys) {
      LinkedHashMap? tagValue = JsonUtils.cast(tags[tagEntry]);
      if (tagValue?.isNotEmpty != true) {
        String tag = (tagPrefix?.isNotEmpty == true) ? "$tagPrefix.$tagEntry" : tagEntry;
        buttons.add(Padding(padding: _filterButtonsPadding, child:
          _storiedSiteSimpleTagButton(tag, title: tagEntry),
        ));
      }
    }

    // Then add compound tag buttons after the single
    for (String tagEntry in tags.keys) {
      LinkedHashMap? tagValue = JsonUtils.cast(tags[tagEntry]);
      if (tagValue?.isNotEmpty == true) {
        String tag = (tagPrefix?.isNotEmpty == true) ? "$tagPrefix.$tagEntry" : tagEntry;
        buttons.add(Padding(padding: _filterButtonsPadding, child:
          _storiedSiteCompoundTagButton(tag, title: tagEntry),
        ));
      }
    }
    return buttons;
  }

  List<Widget> get _myLocationsFilterButtons => <Widget>[
    Padding(padding: _filterButtonsPadding, child:
      _searchFilterButton,
    ),
    if (_isSortAvailable)
      Padding(padding: _filterButtonsPadding, child:
        _sortFilterButton,
      ),
    _filterButtonsEdgeSpacing,
  ];

  // Search Filter Button

  Widget get _searchFilterButton =>
    Map2FilterImageButton(
      key: _searchButtonKey,
      image: Styles().images.getImage('search'),
      label: Localization().getStringEx('panel.map2.button.search.title', 'Search'),
      hint: Localization().getStringEx('panel.map2.button.search.hint', 'Type a search locations'),
      onTap: _onTapSearch,
    );

  void _onTapSearch() {
    Analytics().logSelect(target: 'Search');
    setStateIfMounted((){
      _searchOn = true;
      _searchTextController.text = _selectedFilterIfExists?.searchText ?? '';
    });
  }

  void _onSearchTextChanged(String text) {
  }

  void _onTapCancelSearchText() {
    if (_searchTextController.text.isNotEmpty) {
      Analytics().logSelect(target: 'Search: Clear');
      _searchTextController.text = '';
    }
    else {
      Analytics().logSelect(target: 'Search: Cancel');
      setStateIfMounted((){
        _selectedFilter?.searchText = '';
        _searchOn = false;
      });
      _onFiltersChanged();
    }
  }

  void _onTapSearchText() {
    Analytics().logSelect(target: 'Search: Do');
    setStateIfMounted((){
      _selectedFilter?.searchText = _searchTextController.text;
      _searchTextController.text = '';
      _searchOn = false;
    });
    _onFiltersChanged();
  }

  // Starred Filter Button

  Widget get _starredFilterButton =>
    Map2FilterTextButton(
      key: _starredButtonKey,
      title: Localization().getStringEx('panel.map2.button.starred.title', 'Starred'),
      hint: Localization().getStringEx('panel.map2.button.starred.hint', 'Tap to show only starred locations') + " $_filterButtonHint",
      leftIcon: Styles().images.getImage('star-filled', size: 16),
      toggled: _selectedFilterIfExists?.starred == true,
      onTap: _onStarred,
    );

  void _onStarred() {
    Analytics().logSelect(target: 'Starred');
    setStateIfMounted((){
      _selectedFilter?.starred = (_selectedFilter?.starred != true);
    });
    _onFiltersChanged();
  }

  // Amenities Buildings Filter Button

  Widget get _amenitiesBuildingsFilterButton =>
    MergeSemantics(key: _amenitiesButtonKey, child: Semantics(label: _amenitiesSemanticsValue, child:
      Map2FilterTextButton(
        title: Localization().getStringEx('panel.map2.button.amenities.title', 'Amenities'),
        hint: Localization().getStringEx('panel.map2.button.amenities.hint', 'Tap to edit amenities for visible location') + " $_filterButtonHint",
        leftIcon: Styles().images.getImage('toilet', size: 16),
        rightIcon: Styles().images.getImage('chevron-right'),
        onTap: _onAmenities,
    )));

  void _onAmenities() {
    Analytics().logSelect(target: 'Amenities');
    List<Building>? buildings = JsonUtils.listCastValue<Building>(_explores);
    Map<String, String> buildingsAmenities = buildings?.featureNames ?? <String, String>{};
    // _doAccessibilityWorkaround(
    //         ()=> setStateIfMounted(()=>_mapDisabled = true));
    Navigator.push<LinkedHashSet<String>?>(context, CupertinoPageRoute(builder: (context) => Map2FilterBuildingAmenitiesPanel(
      amenities: buildingsAmenities,
      selectedAmenityIds: LinkedHashSet<String>.from(_campusBuildingsFilterIfExists?.amenities.keys ?? <String>[]),
    ),
    )).then(((LinkedHashSet<String>? amenityIds) {
      // _doAccessibilityWorkaround(
      //         ()=> setStateIfMounted(()=>_mapDisabled = false));
      if (amenityIds != null) {
        setStateIfMounted(() {
          _campusBuildingsFilter?.amenities = amenityIds.selectedFromBuildingAmenities(buildingsAmenities);
        });
        _onFiltersChanged();
        Future.delayed(Duration(milliseconds: 200 + (Platform.isIOS ? 1000 : 0)), () =>
            AppSemantics.triggerAccessibilityFocus(_amenitiesButtonKey));
      }
    }));
  }

  // Terms Student Courses Button

  Widget get _termsButton =>
    MergeSemantics(key: _termsButtonKey, child:
      Semantics(value: _studentCoursesFilterIfExists?.termName, child:
        DropdownButtonHideUnderline(child:
          DropdownButton2<StudentCourseTerm>(
            dropdownStyleData: DropdownStyleData(
              width:  _termsDropdownWidth ??= _evaluateTermsDropdownWidth(),
              padding: EdgeInsets.zero
            ),
        customButton: Map2FilterTextButton(
          title: _studentCoursesFilterIfExists?.termName ?? Localization().getStringEx('panel.map2.button.terms.title', 'Terms'),
          hint: Localization().getStringEx('panel.map2.button.terms.hint', 'Tap to choose term') + " $_filterButtonHint",
          rightIcon: Styles().images.getImage('chevron-down'),
          //onTap: _onTerm,
        ),
        isExpanded: false,
        items: _buildTermsDropdownItems(),
        onChanged: _onSelectTerm,
        onMenuStateChange: _onMenuVisibilityChanged,
      )
    )),
  );

  List<DropdownMenuItem<StudentCourseTerm>> _buildTermsDropdownItems() {
    List<DropdownMenuItem<StudentCourseTerm>> items = <DropdownMenuItem<StudentCourseTerm>>[];
    String? displayTermId = _studentCoursesFilterIfExists?.termId;
    List<StudentCourseTerm>? terms = StudentCourses().terms;
    if (terms != null) {
      for (StudentCourseTerm term in terms) {
        String itemTitle = term.name ?? '';
        TextStyle? itemTextStyle = (term.id == displayTermId) ? _dropdownEntrySelectedTextStyle : _dropdownEntryNormalTextStyle;
        Widget? itemIcon = (term.id == displayTermId) ? Styles().images.getImage('check', size: 18, color: Styles().colors.fillColorPrimary) : null;
        items.add(AccessibleDropDownMenuItem<StudentCourseTerm>(key: ObjectKey(term), value: term,
          child: Semantics(label: itemTitle, button: true, container: true, inMutuallyExclusiveGroup: true,
            child: Row(children: [
              Expanded(child:
                Text(itemTitle, overflow: TextOverflow.ellipsis, semanticsLabel: '', style: itemTextStyle,),
              ),
              if (itemIcon != null)
                Padding(padding: EdgeInsets.only(left: 4), child: itemIcon,) ,
            ],) )));
      }
    }
    return items;
  }

  double _evaluateTermsDropdownWidth() {
    double width = 0;
    List<StudentCourseTerm>? terms = StudentCourses().terms;
    if (terms != null) {
      for (StudentCourseTerm term in terms) {
        final Size sizeFull = (TextPainter(
            text: TextSpan(
              text: term.name ?? Localization().getStringEx('panel.map2.button.terms.title', 'Terms'),
              style: _dropdownEntrySelectedTextStyle,
            ),
            textScaler: MediaQuery.of(context).textScaler,
            textDirection: TextDirection.ltr,
          )..layout()).size;
        if (width < sizeFull.width) {
          width = sizeFull.width;
        }
      }
    }
    return math.min(width + 3 * 18 + 4, MediaQuery.of(context).size.width / 2); // add horizontal padding
  }

  void _onSelectTerm(StudentCourseTerm? value) {
    Analytics().logSelect(target: 'Term: ${value?.name}');
    setStateIfMounted((){
      _studentCoursesFilter?.termId = value?.id;
    });
    _onFiltersChanged();
    Future.delayed(Duration(seconds: Platform.isIOS ? 1 : 0), () =>
        AppSemantics.triggerAccessibilityFocus(_termsButtonKey)
    );
  }

  // Open Now Dining Locations Filter Button

  Widget get _openNowDiningLocationsFilterButton =>
    Map2FilterTextButton(
      key: _openNowButtonKey,
      title: Localization().getStringEx('panel.map2.button.open_now.title', 'Open Now'),
      hint: Localization().getStringEx('panel.map2.button.open_now.hint', 'Tap to show only currently opened locations') + " $_filterButtonHint",
      toggled: _diningLocationsFilterIfExists?.onlyOpened == true,
      onTap: _onTapOpenNow,
    );

  void _onTapOpenNow() {
    Analytics().logSelect(target: 'Open Now');
    setStateIfMounted((){
      _diningLocationsFilter?.onlyOpened = (_diningLocationsFilterIfExists?.onlyOpened != true);
    });
    _onFiltersChanged();
  }

  // Payment Types Dining Locations Filter Button

  Widget get _paymentTypesDiningLocationsFilterButton =>
    MergeSemantics(key: _paymentTypesButtonKey, child:
      Semantics(value: _selectedPaymentType?.displayTitle, child:
        DropdownButtonHideUnderline(child:
          DropdownButton2<PaymentType>(
            dropdownStyleData: DropdownStyleData(
              width:  _paymentTypesDropdownWidth ??= _evaluatePaymentTypesDropdownWidth(),
              padding: EdgeInsets.zero
            ),
        customButton: Map2FilterTextButton(
          title: _selectedPaymentType?.displayTitle ?? Localization().getStringEx('panel.map2.button.payment_type.title', 'Payment Type'),
          hint: Localization().getStringEx('panel.map2.button.payment_type.hint', 'Tap to select a payment type') + " $_filterButtonHint",
          rightIcon: Styles().images.getImage('chevron-down'),
          //onTap: _onPaymentType,
        ),
        isExpanded: false,
        items: _buildPaymentTypesDropdownItems(),
        onChanged: _onSelectPaymentType,
        onMenuStateChange: _onMenuVisibilityChanged,
      )
    )),
  );

  List<DropdownMenuItem<PaymentType>> _buildPaymentTypesDropdownItems() {
    List<DropdownMenuItem<PaymentType>> items = <DropdownMenuItem<PaymentType>>[];
    for (PaymentType paymentType in PaymentType.values) {
      String itemTitle = paymentType.displayTitle;
      TextStyle? itemTextStyle = (paymentType == _selectedPaymentType) ? _dropdownEntrySelectedTextStyle : _dropdownEntryNormalTextStyle;
      Widget? itemIcon = (paymentType == _selectedPaymentType) ? Styles().images.getImage('check', size: 18, color: Styles().colors.fillColorPrimary) : null;
      items.add(AccessibleDropDownMenuItem<PaymentType>(key: ObjectKey(paymentType), value: paymentType,
        child: Semantics(label: itemTitle, button: true, container: true, inMutuallyExclusiveGroup: true,
          child: Row(children: [
            Expanded(child:
              Text(itemTitle, overflow: TextOverflow.ellipsis, semanticsLabel: '', style: itemTextStyle,),
            ),
            if (itemIcon != null)
              Padding(padding: EdgeInsets.only(left: 4), child: itemIcon,) ,
          ],) )));
    }
    return items;
  }

  double _evaluatePaymentTypesDropdownWidth() {
    double width = 0;
    for (PaymentType paymentType in PaymentType.values) {
      final Size sizeFull = (TextPainter(
          text: TextSpan(
            text: paymentType.displayTitle,
            style: _dropdownEntrySelectedTextStyle,
          ),
          textScaler: MediaQuery.of(context).textScaler,
          textDirection: TextDirection.ltr,
        )..layout()).size;
      if (width < sizeFull.width) {
        width = sizeFull.width;
      }
    }
    return math.min(width + 3 * 18 + 4, MediaQuery.of(context).size.width / 2); // add horizontal padding
  }

  void _onSelectPaymentType(PaymentType? value) {
    Analytics().logSelect(target: 'Payment Type: ${value?.displayTitle}');
    setStateIfMounted(() {
      if (_selectedPaymentType != value) {
        _selectedPaymentType = value;
      }
      else {
        _selectedPaymentType = null;
      }
    });
    _onFiltersChanged();
    Future.delayed(Duration(seconds: Platform.isIOS ? 1 : 0), () =>
      AppSemantics.triggerAccessibilityFocus(_paymentTypesButtonKey)
    );

  }

  PaymentType? get _selectedPaymentType => _diningLocationsFilterIfExists?.paymentType;
  set _selectedPaymentType(PaymentType? value) => _diningLocationsFilter?.paymentType = value;

  // Filters Filter Button

  Widget get _filtersFilterButton =>
    Map2FilterTextButton(
      key: _filterButtonKey,
      title: Localization().getStringEx('panel.map2.button.filters.title', 'Filters'),
      hint: Localization().getStringEx('panel.map2.button.filters.hint', 'Tap to edit filters') + " $_filterButtonHint",
      leftIcon: Styles().images.getImage('filters', size: 16),
      rightIcon: Styles().images.getImage('chevron-right'),
      onTap: _onTapFilters,
    );

  void _onTapFilters() {
    Analytics().logSelect(target: 'Filters');

    Event2FilterParam eventFilter = _events2FilterIfExists?.event2Filter ?? Event2FilterParam.fromStorage();
    Event2HomePanel.presentFiltersV2(context, eventFilter).then((Event2FilterParam? filterResult) {
      if ((filterResult != null) && mounted) {
        setStateIfMounted(() {
          _events2Filter?.applyEvent2Filter(filterResult);
        });
        filterResult.saveToStorage();
        _onFiltersChanged();
      }
    });
  }

  // Visited Storied Sites Filter Button

  Widget get _visitedStoriedSitesFilterButton =>
    Map2FilterTextButton(
      title: Localization().getStringEx('panel.map2.button.visited.title', 'Visited'),
      hint: Localization().getStringEx('panel.map2.button.visited.hint', 'Tap to show only visited') + " $_filterButtonHint",
      toggled: _storiedSitesFilterIfExists?.onlyVisited == true,
      onTap: _onTapOnlyVisited,
    );

  void _onTapOnlyVisited() {
    Analytics().logSelect(target: 'Visited');
    setStateIfMounted((){
      _storiedSitesFilter?.onlyVisited = (_storiedSitesFilterIfExists?.onlyVisited != true);
    });
    _onFiltersChanged();
  }

  // Storied Sites Tag Buttons

  Widget _storiedSiteSimpleTagButton(String tag , { String? title }) =>
    Map2FilterTextButton(
      title: title ?? tag,
      hint: Localization().getStringEx('panel.map2.button.starred.hint', 'Tap to show only starred locations'),
      toggled: _storiedSitesFilterIfExists?.tags.contains(tag) == true,
      onTap: () => _onTapStoriedSiteSimpleTag(tag),
    );

  void _onTapStoriedSiteSimpleTag(String tag) {
    Analytics().logSelect(target: 'Storied Site Tag: $tag');
    setStateIfMounted((){
      LinkedHashSet<String>? tags = _storiedSitesFilter?.tags;
      if (tags?.contains(tag) == true) {
        tags?.remove(tag);
      }
      else {
        tags?.add(tag);
      }
    });
    _onFiltersChanged();
  }

  Widget _storiedSiteCompoundTagButton(String tag, { String? title }) =>
    Map2FilterTextButton(
      title: title ?? tag,
      hint: Localization().getStringEx('panel.map2.button.tags.hint', 'Tap to filter by tag'),
      rightIcon: (_expandedStoriedSitesTag?.startsWith(tag) == true) ? Styles().images.getImage('chevron-up') : Styles().images.getImage('chevron-down'),
      onTap: () => _onTapStoriedSiteCompoundTag(tag),
    );

  void _onTapStoriedSiteCompoundTag(String tag) {
    Analytics().logSelect(target: 'Storied Site Tag: $tag');
    setStateIfMounted((){
      _expandedStoriedSitesTag = (_expandedStoriedSitesTag?.startsWith(tag) == true) ?
        tag.tagHead : tag;
    });
  }

  // Sort Filter Button

  bool get _isSortAvailable => (_trayExplores?.isNotEmpty == true);

  Widget get _sortFilterButton =>
    MergeSemantics(key: _sortButtonKey, child:
      Semantics(value: _selectedSortType.displayTitle, child:
        DropdownButtonHideUnderline(child:
          DropdownButton2<Pair<Map2SortType, Map2SortOrder?>>(
            dropdownStyleData: DropdownStyleData(
              width:  _sortDropdownWidth ??= _evaluateSortDropdownWidth(),
              padding: EdgeInsets.zero
            ),
        customButton: Map2FilterTextButton(
          title: Localization().getStringEx('panel.map2.button.sort.title', 'Sort'),
          hint: Localization().getStringEx('panel.map2.button.sort.hint', 'Tap to sort locations') + " ${_filterButtonHint}",
          leftIcon: Styles().images.getImage('sort', size: 16),
          rightIcon: Styles().images.getImage('chevron-down'),
          //onTap: _onSort,
        ),
        isExpanded: false,
        items: _buildSortDropdownItems(),
        onChanged: _onSelectSortType,
        onMenuStateChange: _onMenuVisibilityChanged,
      )
    )),
  );

  List<DropdownMenuItem<Pair<Map2SortType, Map2SortOrder?>>> _buildSortDropdownItems() {
    bool isProximityAvailable = ((locationServicesStatus == LocationServicesStatus.permissionAllowed) || (locationServicesStatus == LocationServicesStatus.permissionNotDetermined));
    List<DropdownMenuItem<Pair<Map2SortType, Map2SortOrder?>>> items = <DropdownMenuItem<Pair<Map2SortType, Map2SortOrder?>>>[];
    for (Map2SortType sortType in Map2SortType.values) {
      if ((_selectedContentType?.supportsSortType(sortType) == true) &&
          ((sortType != Map2SortType.proximity) || isProximityAvailable)
      ) {
        for (Map2SortOrder? sortOrder in _sortDropdownOrderItems) {
          if (sortType.isDropdownListEntry(sortOrder)) {
            String? itemTitle = sortType.displayTitle;
            String? itemSortOrder = sortType.dropdownSortOrderIndicator(sortOrder);
            String itemText = (itemSortOrder != null) ? '$itemTitle $itemSortOrder' : itemTitle;
            bool isSortOrderSelected = sortType.isDropdownListEntrySelected(sortOrder) ?? (_selectedSortOrder == sortOrder);
            TextStyle? itemTextStyle = ((_selectedSortType == sortType) && isSortOrderSelected) ?
              _dropdownEntrySelectedTextStyle : _dropdownEntryNormalTextStyle;
            items.add(AccessibleDropDownMenuItem<Pair<Map2SortType, Map2SortOrder?>>(key: ObjectKey(Pair(sortType, sortOrder)), value: Pair(sortType, sortOrder), child:
              Semantics(label: sortType.displayTitle, button: true, container: true, inMutuallyExclusiveGroup: true, child:
                Row(children: [
                  Expanded(child:
                    Text(itemText, overflow: TextOverflow.ellipsis, semanticsLabel: '', style: itemTextStyle,)
                  ),
                ],)
              )
            ));
          }
        }
      }
    }
    return items;
  }

  double _evaluateSortDropdownWidth() {
    double width = 0;
    for (Map2SortType sortType in Map2SortType.values) {
      for (Map2SortOrder? sortOrder in _sortDropdownOrderItems) {
        if (sortType.isDropdownListEntry(sortOrder)) {
          String? itemTitle = sortType.displayTitle;
          String? itemSortOrder = sortType.dropdownSortOrderIndicator(sortOrder);
          String itemText = (itemSortOrder != null) ? '$itemTitle $itemSortOrder' : itemTitle;
          final Size sizeFull = (TextPainter(
              text: TextSpan(
                text: itemText,
                style: _dropdownEntrySelectedTextStyle,
              ),
              textScaler: MediaQuery.of(context).textScaler,
              textDirection: TextDirection.ltr,
            )..layout()).size;
          if (width < sizeFull.width) {
            width = sizeFull.width;
          }
        }
      }
    }
    return math.min(width + 2 * 18, MediaQuery.of(context).size.width / 2); // add horizontal padding
  }

  List<Map2SortOrder?> get _sortDropdownOrderItems =>
    <Map2SortOrder?>[null, ...Map2SortOrder.values, ];

  void _onSelectSortType(Pair<Map2SortType, Map2SortOrder?>? value) {
    Analytics().logSelect(target: 'Sort: ${value?.left.displayTitle} ${value?.right?.displayTitle}');
    if (value != null) {
      setStateIfMounted(() {
        _selectedSortType = value.left;
        _selectedSortOrder = value.right ?? _expectedSortOrder(value.left);
      });
      _onSortChanged();
      Future.delayed(Duration(seconds: Platform.isIOS ? 1 : 0), () =>
        AppSemantics.triggerAccessibilityFocus(_sortButtonKey)
      );
    }
  }

  Map2SortType get _selectedSortType => _selectedFilterIfExists?.sortType ?? Map2Filter.defaultSortType;
  set _selectedSortType(Map2SortType value) => _selectedFilter?.sortType = value;

  Map2SortOrder get _selectedSortOrder => _selectedFilterIfExists?.sortOrder ?? Map2Filter.defaultSortOrder;
  set _selectedSortOrder(Map2SortOrder value) => _selectedFilter?.sortOrder = value;
  Map2SortOrder _expectedSortOrder(Map2SortType sortType) => Map2Filter.defaultFromContentType(_selectedContentType)?.expectedSortOrder(sortType) ?? Map2Filter.defaultSortOrder;

  TextStyle? get _dropdownEntryNormalTextStyle => Styles().textStyles.getTextStyle("widget.message.regular");
  TextStyle? get _dropdownEntrySelectedTextStyle => Styles().textStyles.getTextStyle("widget.message.regular.fat");

  static const EdgeInsetsGeometry _filterButtonsPadding = EdgeInsets.only(right: 6);

  Widget get _filterButtonsEdgeSpacing =>
    SizedBox(width: 18,);

  Map2Filter? get _selectedFilter => _getFilter(_selectedContentType, ensure: true);
  Map2Filter? get _selectedFilterIfExists => _getFilter(_selectedContentType, ensure: false);

  Map2CampusBuildingsFilter? get _campusBuildingsFilter => JsonUtils.cast(_getFilter(Map2ContentType.CampusBuildings, ensure: true));
  Map2CampusBuildingsFilter? get _campusBuildingsFilterIfExists => JsonUtils.cast(_getFilter(Map2ContentType.CampusBuildings, ensure: false));

  Map2StudentCoursesFilter? get _studentCoursesFilter => JsonUtils.cast(_getFilter(Map2ContentType.StudentCourses, ensure: true));
  Map2StudentCoursesFilter? get _studentCoursesFilterIfExists => JsonUtils.cast(_getFilter(Map2ContentType.StudentCourses, ensure: false));

  Map2DiningLocationsFilter? get _diningLocationsFilter => JsonUtils.cast(_getFilter(Map2ContentType.DiningLocations, ensure: true));
  Map2DiningLocationsFilter? get _diningLocationsFilterIfExists => JsonUtils.cast(_getFilter(Map2ContentType.DiningLocations, ensure: false));

  Map2Events2Filter?         get _events2Filter => JsonUtils.cast(_getFilter(Map2ContentType.Events2, ensure: true));
  Map2Events2Filter?         get _events2FilterIfExists => JsonUtils.cast(_getFilter(Map2ContentType.Events2, ensure: false));

  Map2StoriedSitesFilter?    get _storiedSitesFilter => JsonUtils.cast(_getFilter(Map2ContentType.StoriedSites, ensure: true));
  Map2StoriedSitesFilter?    get _storiedSitesFilterIfExists => JsonUtils.cast(_getFilter(Map2ContentType.StoriedSites, ensure: false));

  Map2Filter? _getFilter(Map2ContentType? contentType, { bool ensure = false, bool reset = false }) {
    if (contentType != null) {
      Map2Filter? filter = _filters[contentType];
      if (((filter == null) && ensure) || reset) {
        filter = Map2Filter.defaultFromContentType(contentType);
        if (filter != null) {
          _filters[contentType] = filter;
        }
      }
      return filter;
    }
    else {
      return null;
    }
  }

  Widget get _contentFilterSearchBar =>
    Container(padding: EdgeInsets.only(left: 16), child:
      Row(children: <Widget>[
        Expanded(child:
          _searchTextField,
        ),
        Map2PlainImageButton(
          imageKey: 'search',
          label: Localization().getStringEx('panel.search.button.search.title', 'Search'),
          hint: Localization().getStringEx('panel.search.button.search.hint', ''),
          onTap: _onTapSearchText,
        ),
        Map2PlainImageButton(
          imageKey: 'close',
          label: Localization().getStringEx('panel.search.button.clear.title', 'Clear'),
          hint: Localization().getStringEx('panel.search.button.clear.hint', ''),
          onTap: _onTapCancelSearchText,
        ),
      ],),
    );
      
  Widget get _searchTextField => Semantics(
    label: Localization().getStringEx('panel.search.field.search.title', 'Search'),
    hint: Localization().getStringEx('panel.search.field.search.hint', ''),
    textField: true,
    excludeSemantics: true,
    child: TextField(
      controller: _searchTextController,
      focusNode: _searchTextNode,
      onChanged: (text) => _onSearchTextChanged(text),
      onSubmitted: (_) => _onTapSearchText(),
      autofocus: true,
      cursorColor: Styles().colors.fillColorSecondary,
      keyboardType: TextInputType.text,
      style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
      decoration: InputDecoration(
        border: InputBorder.none,
      ),
    ),
  );

  //void _onFilterButtonsScroll() {}

  void _onTapShareFilter() {
    Analytics().logSelect(target: "Filter: Share");
    Map2ContentType? contentType = _selectedContentType;
    if (contentType != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => QrCodePanel.fromMap2DeepLinkParam(
        param: Map2FilterDeepLinkParam(
          contentType: contentType,
          filter: _selectedFilterIfExists,
        ),
        analyticsFeature: widget.analyticsFeature,
      )));
    }
  }

  void _onTapClearFilter() {
    Analytics().logSelect(target: "Filter: Clear");
    Map2ContentType? contentType = _selectedContentType;
    if (contentType != null) {
      Map2Filter? emptyFilter = Map2Filter.emptyFromContentType(_selectedContentType);
      setStateIfMounted(() {
        if (emptyFilter != null) {
          _filters[contentType] = emptyFilter;
        }
        else {
          _filters.remove(contentType);
        }
      });
      _onFiltersChanged();
    }
  }

  void _onFiltersChanged() {
    if (mounted) {
      if (_selectedContentType?.supportsManualFilters == true) {
        _updateFilteredExplores();
      }
      else {
        _initExplores(progressType: ExploreProgressType.update);
      }
    }
  }

  Future<void> _updateFilteredExplores() async {
    List<Explore>? filteredExplores = _filterExplores(_explores);
    if (mounted && !DeepCollectionEquality().equals(_filteredExplores, filteredExplores)) {
      setStateIfMounted(() {
        _exploresProgress = ExploreProgressType.update;
      });
      await buildMapContentData(filteredExplores, updateCamera: true, showProgress: true);
      if (mounted) {
        setStateIfMounted(() {
          _filteredExplores = filteredExplores;
          _selectedExploreGroup = null;
          _exploresProgress = null;
          mapKey = UniqueKey(); // force map rebuild
        });
        _updateTrayExplores();
      }
    }
  }

  void _onSortChanged() =>
    _updateTrayExplores();
}

// Content Messages

extension _Map2HomePanelMessages on _Map2HomePanelState {

  static const String _privacyUrl = 'privacy://level';
  static const String _privacyUrlMacro = '{{privacy_url}}';

  void _showContentMessageIfNeeded(Map2ContentType? contentType, List<Explore>? explores) {
    if (contentType != null) {
      if (explores == null) {
        _showMessagePopup(contentType.displayFailedContentMessage);
      }
      else if (explores.length == 0) {
        if (contentType == Map2ContentType.MyLocations) {
          String messageHtml = Localization().getStringEx('panel.explore.missing.my_locations.msg', "You currently have no saved locations.<br><br>Select a location on the map and tap the \u2606 to save it as a favorite. (<a href='$_privacyUrlMacro'>Your privacy level</a> must be at least 2.)").
            replaceAll(_privacyUrlMacro, _privacyUrl);
          _showMessagePopup(messageHtml);
        }
        else {
          _showMessagePopup(contentType.displayEmptyContentMessage);
        }
      }
      else if ((contentType == Map2ContentType.BusStops) && (Storage().showMtdStopsMapInstructions != false)) {
        String messageHtml = Localization().getStringEx("panel.explore.instructions.mtd_stops.msg", "Tap a bus stop on the map to get bus schedules.<br><br>Tap the \u2606 to save the bus stop. (<a href='$_privacyUrlMacro'>Your privacy level</a> must be at least 2.)").
          replaceAll(_privacyUrlMacro, _privacyUrl);
        _showOptionalMessagePopup(messageHtml, showPopupStorageKey: Storage().showMtdStopsMapInstructionsKey,);
      }
      else if ((contentType == Map2ContentType.MyLocations) && (Storage().showMyLocationsMapInstructions != false)) {
        String messageHtml = Localization().getStringEx("panel.explore.instructions.my_locations.msg", "Select a location on the map and tap the \u2606  to save it as a favorite. (<a href='$_privacyUrlMacro'>Your privacy level</a> must be at least 2.)",).
          replaceAll(_privacyUrlMacro, _privacyUrl);
        _showOptionalMessagePopup(messageHtml, showPopupStorageKey: Storage().showMyLocationsMapInstructionsKey);
      }
    }
  }

  void _showMessagePopup(String? message) {
    if ((message != null) && message.isNotEmpty) {
      ExploreMessagePopup.show(context, message, onTapUrl: _handleLocalUrl);
    }
  }

  void _showOptionalMessagePopup(String message, { String? showPopupStorageKey }) {
    showDialog(context: context, builder: (context) =>
      ExploreOptionalMessagePopup(
        message: message,
        showPopupStorageKey: showPopupStorageKey,
        onTapUrl: _handleLocalUrl,
      )
    );
  }

  bool _handleLocalUrl(String url) {
    if (url == _privacyUrl) {
      Analytics().logSelect(target: 'Privacy Level');
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,)));
      return true;
    }
    else {
      return false;
    }
  }

}
