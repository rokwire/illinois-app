
import 'dart:io';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/ext/Building.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Map2.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Gateway.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/map2/Map2TraySheet.dart';
import 'package:illinois/ui/map2/Map2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/image_utils.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum Map2ContentType { CampusBuildings, StudentCourses, DiningLocations, Events2, Laundries, BusStops, Therapists, MyLocations }

typedef LoadExploresTask = Future<List<Explore>?>;
typedef BuildMarkersTask = Future<Set<Marker>>;
typedef MarkerIconsCache = Map<String, BitmapDescriptor>;

class Map2Panel extends StatefulWidget with AnalyticsInfo {
  Map2Panel({super.key});

  @override
  State<StatefulWidget> createState() => _Map2PanelState();

  AnalyticsFeature? get analyticsFeature =>
    /*_state?._selectedMapType?.analyticsFeature ??
    _selectedExploreType(exploreTypes: _buildExploreTypes())?.analyticsFeature ?? */
    AnalyticsFeature.Map;
}

class _Map2PanelState extends State<Map2Panel>
  with NotificationsListener, SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin<Map2Panel>
{

  final GlobalKey _scaffoldKey = GlobalKey();
  final GlobalKey _contentHeadingBarKey = GlobalKey();
  final GlobalKey _traySheetKey = GlobalKey();

  UniqueKey _mapKey = UniqueKey();
  GoogleMapController? _mapController;
  CameraPosition? _lastCameraPosition;
  CameraUpdate? _targetCameraUpdate;
  double? _lastMapZoom;

  final ScrollController _contentTypesScrollController = ScrollController();
  final ScrollController _filterButtonsScrollController = ScrollController();
  final DraggableScrollableController _traySheetController = DraggableScrollableController();

  late Set<Map2ContentType> _availableContentTypes;
  Map2ContentType? _selectedContentType;
  double _contentTypesScrollOffset = 0;

  Map<Map2ContentType, _Map2Filter> _filters = <Map2ContentType, _Map2Filter>{};

  List<Explore>? _explores;
  List<Explore>? _filteredExplores;
  List<Explore>? _visibleExplores;
  LoadExploresTask? _exploresTask;
  bool _exploresProgress = false;

  Set<Marker>? _mapMarkers;
  Set<dynamic>? _exploreMapGroups;
  BuildMarkersTask? _buildMarkersTask;
  MarkerIconsCache _markerIconsCache = <String, BitmapDescriptor>{};
  bool _markersProgress = false;

  Explore? _pinnedExplore;
  Marker? _pinnedMarker;
  BitmapDescriptor? _pinMarkerIcon;

  DateTime? _pausedDateTime;
  Position? _currentLocation;
  Map<String, dynamic>? _mapStyles;
  LocationServicesStatus? _locationServicesStatus;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Connectivity.notifyStatusChanged,
      LocationServices.notifyStatusChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged,
    ]);

    _availableContentTypes = _Map2ContentType.availableTypes;
    _selectedContentType = _Map2ContentType.initialType(availableTypes: _availableContentTypes);

    _contentTypesScrollController.addListener(_onContentTypesScroll);
    //_filterButtonsScrollController.addListener(_onFilterButtonsScroll);

    _updateLocationServicesStatus(init: true);
    _initMapStyles();
    _initExplores();

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _traySheetController.dispose();
    _contentTypesScrollController.dispose();
    _filterButtonsScrollController.dispose();
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
      _updateLocationServicesStatus(status: param);
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      if (_selectedContentType == Map2ContentType.MyLocations) {
        _updateExplores();
      }
    }
    else if (name == FlexUI.notifyChanged) {
      _updateAvailableContentTypes();
      _updateLocationServicesStatus();
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
            _updateLocationServicesStatus();
          }
        }
      }
    }
  }

  Future<void> _onConnectivityStatusChanged() async {
    if (Connectivity().isNotOffline && mounted) {
      if (_locationServicesStatus == null) {
        await _updateLocationServicesStatus();
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
      body: _scaffoldBody,
      backgroundColor: Styles().colors.background,
    );
  }

  Widget get _scaffoldBody =>
    Stack(key: _scaffoldKey, children: [

      Positioned.fill(child:
        Visibility(visible: (_exploresProgress == false), child:
          _mapView
        ),
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
              Visibility(visible: ((_exploresProgress == false) && ((_visibleExplores?.isNotEmpty == true) || (_pinnedExplore != null))), child:
                _traySheet,
              ),
            )
          ],),
        ),
      ),

      if (_exploresProgress == true)
        Positioned.fill(child:
          Center(child:
            _exploresProgressIndicator,
          ),
        ),

      if (_markersProgress == true)
        Positioned.fill(child:
          Center(child:
            _mapProgressIndicator,
          ),
        ),
    ],);

  Widget get _mapView => Container(decoration: _mapViewDecoration, child:
    GoogleMap(
      key: _mapKey,
      initialCameraPosition: _lastCameraPosition ?? _Map2PanelContent.defaultCameraPosition,
      onMapCreated: _onMapCreated,
      onCameraIdle: _onMapCameraIdle,
      onCameraMove: _onMapCameraMove,
      onTap: _onMapTap,
      onPoiTap: _onMapPoiTap,
      myLocationEnabled: _userLocationEnabled,
      myLocationButtonEnabled: _userLocationEnabled,
      mapToolbarEnabled: Storage().debugMapShowLevels == true,
      markers: ((_pinnedExplore != null) ? _pinnedMarkers : _mapMarkers) ?? <Marker>{},
      style: _currentMapStyle,
      indoorViewEnabled: true,
      //trafficEnabled: true,
      // This fixes #4306. The gestureRecognizers parameter is needed because of PopScopeFix wrapper in RootPanel,
      // which uses BackGestureDetector in iOS, that disables scroll, pan and zoom of the map view.
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>> {
        Factory<OneSequenceGestureRecognizer>(
          () => EagerGestureRecognizer(),
        ),
      },
    ),
  );

  BoxDecoration get _mapViewDecoration =>
    BoxDecoration(border: Border.all(color: Styles().colors.surfaceAccent, width: 1));

  Widget get _mapProgressIndicator =>
    SizedBox(width: 24, height: 24, child:
      CircularProgressIndicator(color: Styles().colors.accentColor2, strokeWidth: 3,),
    );

  Widget get _exploresProgressIndicator =>
    SizedBox(width: 32, height: 32, child:
      CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
    );

  // Map Events

  void _onMapCreated(GoogleMapController controller) async {
    // debugPrint('Map2 created' );
    _mapController = controller;

    if (_targetCameraUpdate != null) {
      if (Platform.isAndroid) {
        Future.delayed(Duration(milliseconds: 100), () {
          _applyCameraUpdate();
        });
      }
      else {
        _applyCameraUpdate();
      }
    }
  }

  void _applyCameraUpdate() {
    if (_targetCameraUpdate != null) {
      _mapController?.moveCamera(_targetCameraUpdate!).then((_) {
        _targetCameraUpdate = null;
      });
    }
  }

  void _onMapCameraMove(CameraPosition cameraPosition) {
    // debugPrint('Map2 camera position: lat: ${cameraPosition.target.latitude} lng: ${cameraPosition.target.longitude} zoom: ${cameraPosition.zoom}' );
    _lastCameraPosition = cameraPosition;
  }

  void _onMapCameraIdle() {
    // debugPrint('Map2 camera idle' );
    _updateVisibleExplores();
    _updateMapContentForZoom();
  }

  void _onMapTap(LatLng coordinate) {
    // debugPrint('Map2 tap' );
    if (_selectedContentType == Map2ContentType.MyLocations) {
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

  void _onMapPoiTap(PointOfInterest poi) {
    // debugPrint('Map2 POI tap' );
    if (_selectedContentType == Map2ContentType.MyLocations) {
      ExplorePOI explorePOI = ExplorePOIImpl.fromMapPOI(poi);
      if (_explores?.contains(explorePOI) != true) {
        _pinExplore(explorePOI);
      }
    }
  }

  void _onTapMarker(dynamic origin) {
    // debugPrint('Map2 Marker tap' );
    if (origin is Explore) {
      origin.exploreLaunchDetail(context, analyticsFeature: widget.analyticsFeature);
    }
    else if (origin is List<Explore>) {
      _ensureExploresVisibility(origin);
    }
  }

  // Locaction Services

  bool get _userLocationEnabled =>
    FlexUI().isLocationServicesAvailable && (_locationServicesStatus == LocationServicesStatus.permissionAllowed);

  Future<void> _updateLocationServicesStatus({ LocationServicesStatus? status, bool init = false}) async {
    status ??= FlexUI().isLocationServicesAvailable ? await LocationServices().status : LocationServicesStatus.serviceDisabled;
    if ((status != null) && (status != _locationServicesStatus) && mounted) {
      setState(() {
        _locationServicesStatus = status;
      });
      
      await _updateCurrentLocation(init: init);
    }
  }
  
  Future<void> _updateCurrentLocation({bool init = false}) async {
    if (_locationServicesStatus == LocationServicesStatus.permissionAllowed) {
      Position? currentLocation = await LocationServices().location;
      if ((currentLocation != null) && (currentLocation != _currentLocation) && mounted) {

        setState(() {
          _currentLocation = currentLocation;
        });

        if (init) {
          CameraPosition cameraPosition = CameraPosition(target: currentLocation.gmsLatLng, zoom: _Map2PanelContent.defaultCameraZoom);
          if (_mapController != null) {
            _mapController?.moveCamera(CameraUpdate.newCameraPosition(cameraPosition));
          }
          else {
            _lastCameraPosition = cameraPosition;
          }
        }
      }
    }
  }

  // Content Types

  Widget get _contentTypesBar => 
    SingleChildScrollView(
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
            onTap: () => _onContentTypeEntry(contentType),
          )
        ));
      }
    }
    return entries;
  }

  void _updateAvailableContentTypes() {
    Set<Map2ContentType> availableContentTypes = _Map2ContentType.availableTypes;
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

  void _onContentTypeEntry(Map2ContentType contentType) {
    setState(() {
      Storage()._storedMap2ContentType = _selectedContentType = contentType;
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

  // Content Filters

  Widget get _contentHeadingBar =>
    Container(key: _contentHeadingBarKey, decoration: _contentHeadingDecoration, child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _contentTitleBar,
        ... _contentFilterButtonsBar,
      ],),
    );

  BoxDecoration get _contentHeadingDecoration =>
    BoxDecoration(
      color: Styles().colors.background,
      border: Border(bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1),),
      boxShadow: [BoxShadow(color: Styles().colors.dropShadow, spreadRadius: 1, blurRadius: 3, offset: Offset(1, 1) )],
    );

  Widget get _contentTitleBar =>
    Row(children: [
      Expanded(child:
        Padding(padding: EdgeInsets.only(left: 16, top: 8, bottom: 8), child:
          Text(_selectedContentType?.displayTitle ?? '', style: Styles().textStyles.getTextStyle('widget.title.regular.fat'),)
        ),
      ),
      Semantics(label: Localization().getStringEx('dialog.close.title', 'Close'), button: true, excludeSemantics: true, child:
        InkWell(onTap : _onUnselectContentType, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
            Styles().images.getImage('close-circle-small', excludeFromSemantics: true)
          ),
        ),
      ),
    ],);

  void _onUnselectContentType() {
    setState(() {
      Storage()._storedMap2ContentType = _selectedContentType = null;
      _explores = _filteredExplores = _visibleExplores = null;
      _exploresTask = null;
      _exploresProgress = false;

      _mapMarkers = null;
      _exploreMapGroups = null;
      _targetCameraUpdate = null;
      _buildMarkersTask = null;
      _lastMapZoom = null;
      _markersProgress = false;

      _pinnedExplore = null;
      _pinnedMarker = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_){
      _updateContentTypesScrollPosition();
    });
  }

  // My Locactions Content && Selection

  void _pinExplore(Explore? exploreToPin) {
    Explore? pinnedExplore = (_pinnedExplore != exploreToPin) ? exploreToPin : null;
    if ((_pinnedExplore != pinnedExplore) && mounted) {
      setState(() {
        _pinnedExplore = pinnedExplore;
      });
      _updateVisibleExplores();
      _updatePinMarker();
    }
  }

  Future<void> _updatePinMarker() async {
    Marker? pinednMarker = (_pinnedExplore != null) ? await _createPinMarker(_pinnedExplore, imageConfiguration: createLocalImageConfiguration(context)) : null;
    setStateIfMounted((){
      _pinnedMarker = pinednMarker;
    });
  }

  Set<Marker>? get _pinnedMarkers => (_pinnedMarker != null) ? <Marker> { _pinnedMarker! } : null;
  List<Explore>? get _pinnedVisibleExplores => (_pinnedExplore != null) ? <Explore>[_pinnedExplore!] : null;
  int? get _pinnedExploresCount => (_pinnedExplore != null) ? 1 : null;

  // Tray Sheet

  static const List<double> _traySnapSizes = [0.03, 0.35, 0.65, 0.97];
  final double _trayInitialSize = _traySnapSizes[1];
  final double _trayMinSize = _traySnapSizes.first;
  final double _trayMaxSize = _traySnapSizes.last;

  Widget get _traySheet =>
    DraggableScrollableSheet(
      controller: _traySheetController,
      snap: true, snapSizes: _traySnapSizes,
      initialChildSize: _trayInitialSize,
      minChildSize: _trayMinSize,
      maxChildSize: _trayMaxSize,

      builder: (BuildContext context, ScrollController scrollController) => Map2TraySheet(
        key: _traySheetKey,
        visibleExplores: _pinnedVisibleExplores ?? _visibleExplores,
        scrollController: scrollController,
        currentLocation: _currentLocation,
        totalExploresCount: _pinnedExploresCount ?? _filteredExplores?.length ?? _explores?.length,
        analyticsFeature: widget.analyticsFeature,
      ),
    );

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

  Future<void> _initExplores() async {
    if (mounted) {
      LoadExploresTask? exploresTask = _loadExplores();
      if (exploresTask != null) {
        // start loading
        setState(() {
          _exploresTask = exploresTask;
          _exploresProgress = true;
          _explores = _filteredExplores = _visibleExplores = null;
          _pinnedExplore = null;
          _pinnedMarker = null;
        });

        // wait for explores load
        List<Explore>? explores = await exploresTask;
        List<Explore>? filteredExplores = _filterExplores(explores);

        if (mounted && (exploresTask == _exploresTask)) {
          await _buildMapContentData(filteredExplores, updateCamera: true);
          if (mounted && (exploresTask == _exploresTask)) {
            setState(() {
              _explores = explores;
              _filteredExplores = filteredExplores;
              _exploresTask = null;
              _exploresProgress = false;
              _mapKey = UniqueKey(); // force map rebuild
            });
          }
        }
      }
      else {
        setState(() {
          _explores = _filteredExplores = _visibleExplores = null;
          _exploresTask = null;
          _exploresProgress = false;

          _mapMarkers = null;
          _exploreMapGroups = null;
          _targetCameraUpdate = null;
          _buildMarkersTask = null;
          _lastMapZoom = null;
          _markersProgress = false;

          _pinnedExplore = null;
          _pinnedMarker = null;
        });
      }
    }
  }

  Future<void> _updateExplores() async {
    if (mounted) {
      LoadExploresTask? exploresTask = _loadExplores();
      if (exploresTask != null) {
        // start loading
        setState(() {
          _exploresTask = exploresTask;
          _markersProgress = true;
        });

        // wait for explores load
        List<Explore>? explores = await exploresTask;
        List<Explore>? filteredExplores = _filterExplores(explores);

        if (mounted && (exploresTask == _exploresTask) && !DeepCollectionEquality().equals(_filteredExplores, filteredExplores)) {
          await _buildMapContentData(filteredExplores, updateCamera: false, showProgress: true);
          if (mounted && (exploresTask == _exploresTask)) {

            setState(() {
              _explores = explores;
              _filteredExplores = filteredExplores;
              _exploresTask = null;
              if ((_pinnedExplore != null) && (explores?.contains(_pinnedExplore) == true)) {
                _pinnedExplore = null;
                _pinnedMarker = null;
              }
            });
            _updateVisibleExplores();
          }
        }
      }
    }
  }

  Future<void> _updateFilteredExplores() async {
    if (mounted) {
      List<Explore>? filteredExplores = _filterExplores(_explores);
      if (mounted && !DeepCollectionEquality().equals(_filteredExplores, filteredExplores)) {
        await _buildMapContentData(filteredExplores, updateCamera: true, showProgress: true);
        if (mounted) {
          setState(() {
            _filteredExplores = filteredExplores;
            _mapKey = UniqueKey(); // force map rebuild
          });
          _updateVisibleExplores();
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
      case Map2ContentType.Laundries:            return _loadLaundries();
      case Map2ContentType.BusStops:             return _loadBusStops();
      case Map2ContentType.Therapists:           return _loadTherapists();
      case Map2ContentType.MyLocations:          return _loadMyLocations();
      default: return null;
    }
  }

  Future<List<Explore>?> _loadCampusBuildings() =>
    Gateway().loadBuildings();

  Future<List<Explore>?> _loadStudentCourses() async {
    String? termId = StudentCourses().displayTermId;
    return (termId != null) ? await StudentCourses().loadCourses(termId: termId) : null;
  }

  Future<List<Explore>?> _loadDiningLocations() async {
    PaymentType? paymentType = null;
    bool onlyOpened = false;
    return await Dinings().loadBackendDinings(onlyOpened, paymentType, null);
  }

  Future<List<Explore>?> _loadEvents2() async =>
    Events2().loadEventsList(await _event2QueryParam());

  Future<Events2Query> _event2QueryParam() async {
    return Events2Query(
      searchText: null,
      timeFilter: null,
      customStartTimeUtc: null,
      customEndTimeUtc: null,
      types: null,
      attributes: null,
      location: _currentLocation,
    );
  }

  Future<List<Explore>?> _loadLaundries() async {
    LaundrySchool? laundrySchool = await Laundries().loadSchoolRooms();
    return laundrySchool?.rooms;
  }

  Future<List<Explore>?> _loadBusStops() async {
    if (MTD().stops == null) {
      await MTD().refreshStops();
    }
    List<Explore>? result;
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

  List<Explore>? _loadMyLocations() {
    List<ExplorePOI>? locations = ExplorePOI.listFromString(Auth2().prefs?.getFavorites(ExplorePOI.favoriteKeyName));
    return (locations != null) ? List.from(locations.reversed) : null;
  }

  List<Explore>? _filterExplores(List<Explore>? explores) {
    _Map2Filter? filter = _filters[_selectedContentType];
    return ((explores != null) && (filter != null)) ?
      filter.process(explores) : explores;
  }

  // Visible Explores

  Future<List<Explore>?> _buildVisibleExplores() async {
    List<Explore>? visibleExplores;
    if (_mapController != null) {
      visibleExplores = <Explore>[];
      LatLngBounds clipBounds = await _visibleMapBounds(topPadding: _Map2PanelContent.mapPadding, bottomPadding: 2 * _Map2PanelContent.mapPadding) ??
        _shrinkBoundsForSiblings(await _mapController!.getVisibleRegion(), topPadding: _Map2PanelContent.mapPadding, bottomPadding: 2 * _Map2PanelContent.mapPadding,);

      if (_filteredExplores?.isNotEmpty == true) {
        for (Explore explore in _filteredExplores!) {
          LatLng? exploreLocation = explore.exploreLocation?.exploreLocationMapCoordinate;
          if ((exploreLocation != null) && clipBounds.contains(exploreLocation)) {
            visibleExplores.add(explore);
          }
        }
      }
    }

    return visibleExplores;
  }

  Future<void> _updateVisibleExplores() async {
    List<Explore>? visibleExplores = await _buildVisibleExplores();
    if (mounted && !DeepCollectionEquality().equals(_visibleExplores, visibleExplores)) {
      setState(() {
        _visibleExplores = visibleExplores;
      });
    }
  }

  // API


}

// Map2 Filters

extension _Map2PanelFilters on _Map2PanelState {

  List<Widget> get _contentFilterButtonsBar {
    List<Widget>? filterButtonsList = (_exploresProgress == false) ? _filterButtons : null;
    return ((filterButtonsList != null) && filterButtonsList.isNotEmpty) ? <Widget>[
      Container(decoration: _contentFiltersBarDecoration, padding: _contentFiltersBarPadding, constraints: _contentFiltersBarConstraints, child:
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _filterButtonsScrollController,
          child: Row(mainAxisSize: MainAxisSize.min, children: filterButtonsList,)
        )
      ),
    ] : <Widget>[];
  }

  BoxConstraints get _contentFiltersBarConstraints => BoxConstraints(
      minWidth: double.infinity
  );

  BoxDecoration get _contentFiltersBarDecoration =>
    BoxDecoration(
      border: Border(top: BorderSide(color: Styles().colors.surfaceAccent, width: 1),),
    );

  EdgeInsetsGeometry get _contentFiltersBarPadding =>
    EdgeInsets.only(left: 16, top: 8, bottom: 8);

  List<Widget>? get _filterButtons {
    switch (_selectedContentType) {
      case Map2ContentType.CampusBuildings:      return _campusBuildingsFilterButtons;
      case Map2ContentType.StudentCourses:
      case Map2ContentType.DiningLocations:
      case Map2ContentType.Events2:
      case Map2ContentType.Laundries:
      case Map2ContentType.BusStops:
      case Map2ContentType.Therapists:
      case Map2ContentType.MyLocations:
      default: return <Widget>[];
    }
  }

  List<Widget> get _campusBuildingsFilterButtons => <Widget>[
    _searchFilterButton, _filterButtonsSpacing,
    _sortFilterButton, _filterButtonsSpacing,
    _starredBuildingsFilterButton, _filterButtonsSpacing,
    _amenitiesBuildingsFilterButton, _filterButtonsEdgeSpacing,
  ];

  Widget get _searchFilterButton =>
    Map2FilterImageButton(
      image: Styles().images.getImage('search'),
      label: Localization().getStringEx('panel.map2.button.search.title', 'Search'),
      hint: Localization().getStringEx('panel.map2.button.search.hint', 'Type a search locations'),
      onTap: _onSearch,
    );

  Widget get _sortFilterButton =>
    Map2FilterTextButton(
      title: Localization().getStringEx('panel.map2.button.sort.title', 'Sort'),
      hint: Localization().getStringEx('panel.map2.button.sort.hint', 'Tap to sort locations'),
      leftIcon: Styles().images.getImage('sort', size: 16),
      rightIcon: Styles().images.getImage('chevron-down'),
      onTap: _onSort,
    );

  Widget get _starredBuildingsFilterButton =>
    Map2FilterTextButton(
      title: Localization().getStringEx('panel.map2.button.starred.title', 'Starred'),
      hint: Localization().getStringEx('panel.map2.button.starred.hint', 'Tap to show only starred locations'),
      leftIcon: Styles().images.getImage('star-filled', size: 16),
      toggled: _campusBuildingsFilter?.starred == true,
      onTap: _onStarred,
    );

  Widget get _amenitiesBuildingsFilterButton =>
    Map2FilterTextButton(
      title: Localization().getStringEx('panel.map2.button.amenities.title', 'Amenities'),
      hint: Localization().getStringEx('panel.map2.button.amenities.hint', 'Tap to edit amenities for visible location'),
      leftIcon: Styles().images.getImage('toilet', size: 16),
      onTap: _onAmenities,
    );

  Widget get _filterButtonsSpacing =>
    SizedBox(width: 6,);

  Widget get _filterButtonsEdgeSpacing =>
    SizedBox(width: 24,);

  _Map2CampusBuildingsFilters? get _campusBuildingsFilter => JsonUtils.cast(_filters[Map2ContentType.CampusBuildings]);

  //void _onFilterButtonsScroll() {}

  void _onSearch() {

  }

  void _onSort() {

  }


  void _onStarred() {
    _Map2CampusBuildingsFilters? filter = JsonUtils.cast(_filters[Map2ContentType.CampusBuildings] ??= _Map2CampusBuildingsFilters());
    if (filter != null) {
      setStateIfMounted((){
        filter.starred = (filter.starred != true);
      });
      _updateFilteredExplores();
    }
  }

  void _onAmenities() {

  }
}

// Map2 Content

extension _Map2PanelContent on _Map2PanelState {
  static const CameraPosition defaultCameraPosition = CameraPosition(target: defaultCameraTarget, zoom: defaultCameraZoom);
  static const LatLng defaultCameraTarget = LatLng(40.102116, -88.227129);
  static const double defaultCameraZoom = 17;
  static const double mapPadding = 60;
  static const double groupMarkersUpdateThresoldDelta = 0.3;
  static const List<double> thresoldDistanceByZoom = [
		1000000, 800000, 600000, 200000, 100000, // zoom 0 - 4
		 100000,  80000,  60000,  20000,  10000, // zoom 5 - 9
		   5000,   2000,   1000,    500,    250, // zoom 10 - 14
		    100,     50,      0                  // zoom 15 - 16
  ];

  Future<void> _updateMapContentForZoom() async {
    double? mapZoom = await _mapController?.getZoomLevel();
    if (mapZoom != null) {
      if (_lastMapZoom == null) {
        _lastMapZoom = mapZoom;
      }
      else if ((_lastMapZoom! - mapZoom).abs() > groupMarkersUpdateThresoldDelta) {
        _buildMapContentData(_filteredExplores, updateCamera: false, showProgress: true, zoom: mapZoom,);
      }
    }
  }

  Future<void> _ensureExploresVisibility(List<Explore>? explores) async {
    LatLngBounds? exploresBounds = ExploreMap.boundsOfList(explores);
    CameraUpdate? targetCameraUpdate = (exploresBounds != null) ? _cameraUpdateForBounds(exploresBounds) : null;
    if (targetCameraUpdate != null) {
      _mapController?.animateCamera(targetCameraUpdate).then((_){
        if (mounted) {
          _updateVisibleExplores();
          _updateMapContentForZoom();
        }
      });
    }
  }

  Future<void> _buildMapContentData(List<Explore>? explores, { bool updateCamera = false, bool showProgress = false, double? zoom}) async {
    Size? mapSize = _scaffoldKey.renderBoxSize;
    LatLngBounds? exploresRawBounds = ExploreMap.boundsOfList(explores);
    LatLngBounds? exploresBounds = (exploresRawBounds != null) ? _updateBoundsForSiblings(exploresRawBounds) : null;
    CameraUpdate? targetCameraUpdate = updateCamera ? _cameraUpdateForBounds(exploresBounds) : null;
    if ((exploresBounds != null) && (mapSize != null)) {

      double thresoldDistance;
      Set<dynamic>? exploreMapGroups;
      if (exploresBounds.northeast != exploresBounds.southwest) {
        double? debugThresoldDistance = Storage().debugMapThresholdDistance?.toDouble();
        if (debugThresoldDistance != null) {
          thresoldDistance = debugThresoldDistance;
        }
        else {
          zoom ??= GeoMapUtils.getMapBoundZoom(exploresBounds, math.max(mapSize.width - 2 * mapPadding, 0), math.max(mapSize.height - 2 * mapPadding, 0));
          thresoldDistance = _thresoldDistanceForZoom(zoom);
        }
        exploreMapGroups = _buildExplorMapGroups(explores, thresoldDistance: thresoldDistance);
      }
      else {
        thresoldDistance = 0;
        exploreMapGroups =  (explores != null) ? <dynamic>{ ExploreMap.validFromList(explores) } : null;
      }
      if (!DeepCollectionEquality().equals(_exploreMapGroups, exploreMapGroups)) {
        BuildMarkersTask buildMarkersTask = _buildMarkers(context, exploreGroups: exploreMapGroups, );
        _buildMarkersTask = buildMarkersTask;
        if (showProgress && mounted) {
          setStateIfMounted(() {
            _markersProgress = true;
          });
        }

        //debugPrint('Building Markers for zoom: $zoom thresholdDistance: $thresoldDistance markersSource: ${exploreMapGroups?.length}');
        Set<Marker> targetMarkers = await buildMarkersTask;
        //debugPrint('Finished Building Markers for zoom: $zoom thresholdDistance: $thresoldDistance => ${targetMarkers.length}');

        if ((_buildMarkersTask == buildMarkersTask) && mounted) {
          //debugPrint('Applying Building Markers for zoom: $zoom thresholdDistance: $thresoldDistance => ${targetMarkers.length}');
          _mapMarkers = targetMarkers;
          _exploreMapGroups = exploreMapGroups;
          _targetCameraUpdate = targetCameraUpdate;
          _buildMarkersTask = null;
          _lastMapZoom = null;
          setStateIfMounted(() {
            _markersProgress = false;
          });
        }
      }
    }
    else if (mounted) {
      _mapMarkers = null;
      _exploreMapGroups = null;
      _targetCameraUpdate = targetCameraUpdate;
      _buildMarkersTask = null;
      _lastMapZoom = null;
      setStateIfMounted(() {
        _markersProgress = false;
      });
    }
  }

  static Set<dynamic>? _buildExplorMapGroups(List<Explore>? explores, { double thresoldDistance = 0 }) {
    if (explores != null) {
      // group by thresoldDistance
      List<List<Explore>> exploreGroups = <List<Explore>>[];

      for (Explore explore in explores) {
        ExploreLocation? exploreLocation = explore.exploreLocation;
        if ((exploreLocation != null) && exploreLocation.isLocationCoordinateValid) {
          List<Explore>? groupExploreList = _lookupExploreGroup(exploreGroups, exploreLocation, thresoldDistance: thresoldDistance);
          if (groupExploreList != null) {
            groupExploreList.add(explore);
          }
          else {
            exploreGroups.add(<Explore>[explore]);
          }
        }
      }

      Set<dynamic> markerGroups = <dynamic>{};
      for (List<Explore> exploreGroup in exploreGroups) {
        if (exploreGroup.length == 1) {
          markerGroups.add(exploreGroup.first);
        }
        else if (exploreGroup.length > 1) {
          markerGroups.add(exploreGroup);
        }
      }

      return markerGroups;

      // no grouping
      // return Set<dynamic>.from(explores);
    }
    return null;
  }

  static List<Explore>? _lookupExploreGroup(List<List<Explore>> exploreGroups, ExploreLocation exploreLocation, { double thresoldDistance = 0 }) {
    for (List<Explore> groupExploreList in exploreGroups) {
      for (Explore groupExplore in groupExploreList) {
        double distance = GeoMapUtils.getDistance(
          exploreLocation.latitude?.toDouble() ?? 0,
          exploreLocation.longitude?.toDouble() ?? 0,
          groupExplore.exploreLocation?.latitude?.toDouble() ?? 0,
          groupExplore.exploreLocation?.longitude?.toDouble() ?? 0
        );
        if (distance <= thresoldDistance) {
          return groupExploreList;
        }
      }
    }
    return null;
  }

  static double _thresoldDistanceForZoom(double zoom) {
    int zoomIndex = zoom.round();
    if ((0 <= zoomIndex) && (zoomIndex < thresoldDistanceByZoom.length)) {
      double zoomDistance = thresoldDistanceByZoom[zoomIndex];
      double nextZoomDistance = ((zoomIndex + 1) < thresoldDistanceByZoom.length) ? thresoldDistanceByZoom[zoomIndex + 1] : 0;
      double thresoldDistance = zoomDistance - (zoom - zoomIndex.toDouble()) * (zoomDistance - nextZoomDistance);
      return thresoldDistance;
    }
    return 0;
  }


  CameraUpdate _cameraUpdateForBounds(LatLngBounds? bounds) {
    if (bounds == null) {
      return CameraUpdate.newCameraPosition(defaultCameraPosition);
    }
    else if (bounds.northeast == bounds.southwest) {
      return CameraUpdate.newCameraPosition(CameraPosition(target: bounds.northeast, zoom: defaultCameraZoom));
    }
    else {
      return CameraUpdate.newLatLngBounds(bounds, mapPadding);
    }
  }

  LatLngBounds _updateBoundsForSiblings(LatLngBounds bounds) => (bounds.northeast != bounds.southwest) ?
    _enlargeBoundsForSiblings(bounds, topPadding: mapPadding, bottomPadding: 2 * mapPadding) : bounds;

  LatLngBounds _enlargeBoundsForSiblings(LatLngBounds bounds, { double? topPadding, double? bottomPadding, }) {
    double northLat = bounds.northeast.latitude;
    double southLat = bounds.southwest.latitude;
    double boundHeight = northLat - southLat;
    double? mapHeight = _scaffoldKey.renderBoxSize?.height;
    if ((southLat < northLat) && (mapHeight != null) && (mapHeight > 0)) {

      double headingBarHeight = _contentHeadingBarKey.renderBoxSize?.height ?? 0.0;
      if (0 < headingBarHeight) {
        northLat += (headingBarHeight / mapHeight) * boundHeight;
      }

      double trayHeight = _traySheetKey.renderBoxSize?.height ?? 0.0;
      if (trayHeight <= 0.0) {
        trayHeight = _trayInitialSize * math.max(mapHeight - headingBarHeight, 0.0);
      }
      if (0.0 < trayHeight) {
        southLat -= (trayHeight / mapHeight) * boundHeight;
      }

      if ((topPadding != null) && (0 < topPadding)) {
        northLat += (topPadding / mapHeight) * boundHeight;
      }

      if ((bottomPadding != null) && (0 < bottomPadding)) {
        southLat -= (bottomPadding / mapHeight) * boundHeight;
      }

      if (southLat < northLat) {
        // debugPrint("[${northLat.toStringAsFixed(6)}, ${southLat.toStringAsFixed(6)}] => [${north2Lat.toStringAsFixed(6)}, ${south2Lat.toStringAsFixed(6)}]");
        return LatLngBounds(
          northeast: LatLng(northLat, bounds.northeast.longitude),
          southwest: LatLng(southLat, bounds.southwest.longitude)
        );
      }
    }
    return bounds;
  }

  LatLngBounds _shrinkBoundsForSiblings(LatLngBounds bounds, { double? topPadding, double? bottomPadding, }) {
    double northLat = bounds.northeast.latitude;
    double southLat = bounds.southwest.latitude;
    double boundHeight = northLat - southLat;
    double? mapHeight = _scaffoldKey.renderBoxSize?.height;
    if ((southLat < northLat) && (mapHeight != null) && (mapHeight > 0))
    {
      double headingBarHeight = _contentHeadingBarKey.renderBoxSize?.height ?? 0.0;
      if (0 < headingBarHeight) {
        northLat -= (headingBarHeight / mapHeight) * boundHeight;
      }

      double trayHeight = _traySheetKey.renderBoxSize?.height ?? 0.0;
      if (trayHeight <= 0.0) {
        trayHeight = _trayInitialSize * math.max(mapHeight - headingBarHeight, 0.0);
      }
      if (0.0 < trayHeight) {
        southLat += (trayHeight / mapHeight) * boundHeight;
      }

      if ((topPadding != null) && (0 < topPadding)) {
        northLat -= (topPadding / mapHeight) * boundHeight;
      }

      if ((bottomPadding != null) && (0 < bottomPadding)) {
        southLat += (bottomPadding / mapHeight) * boundHeight;
      }

      if (southLat <= northLat) {
        // debugPrint("[${northLat.toStringAsFixed(6)}, ${southLat.toStringAsFixed(6)}] => [${north2Lat.toStringAsFixed(6)}, ${south2Lat.toStringAsFixed(6)}]");
        return LatLngBounds(
          northeast: LatLng(northLat, bounds.northeast.longitude),
          southwest: LatLng(southLat, bounds.southwest.longitude)
        );
      }
    }
    return bounds;
  }

  Future<LatLngBounds?> _visibleMapBounds({ double? topPadding, double? bottomPadding, }) async {
    Size? mapSize = _scaffoldKey.renderBoxSize;
    if ((mapSize != null) && (mapSize.width > 0) && (mapSize.height > 0) && (_mapController != null)) {
      double top = 0, bottom = mapSize.height;

      double headingBarHeight = _contentHeadingBarKey.renderBoxSize?.height ?? 0.0;
      if (0 < headingBarHeight) {
        top += headingBarHeight;
      }

      double trayHeight = _traySheetKey.renderBoxSize?.height ?? 0.0;
      if (trayHeight <= 0.0) {
        trayHeight = _trayInitialSize * math.max(mapSize.height - headingBarHeight, 0);
      }
      if (0.0 < trayHeight) {
        bottom -= trayHeight;
      }

      if ((topPadding != null) && (0 < topPadding)) {
        top += topPadding;
      }

      if ((bottomPadding != null) && (0 < bottomPadding)) {
        bottom -= bottomPadding;
      }

      if (top < bottom) {
        // southwest, northeast
        List<LatLng> result = await Future.wait<LatLng>(<Future<LatLng>>[
          _mapController!.getLatLng(ScreenCoordinate(x:                     0, y: bottom.round())), // southwest
          _mapController!.getLatLng(ScreenCoordinate(x: mapSize.width.round(), y: top.round())), // northeast
        ]);
        return LatLngBounds(southwest: result[0], northeast: result[1]);
      }
    }

    return null;
  }
}

// Map2 Markers

extension _Map2PanelMarkers on _Map2PanelState {

  static const double _mapPinMarkerSize = 24;
  static const double _mapGroupMarkerSize = 24;
  static const Offset _mapPinMarkerAnchor = Offset(0.5, 1);
  static const Offset _mapCircleMarkerAnchor = Offset(0.5, 0.5);

  Future<Set<Marker>> _buildMarkers(BuildContext context, { Set<dynamic>? exploreGroups }) async {
    Set<Marker> markers = <Marker>{};
    ImageConfiguration imageConfiguration = createLocalImageConfiguration(context);
    if (exploreGroups != null) {
      for (dynamic entry in exploreGroups) {
        Marker? marker;
        if (entry is List<Explore>) {
          marker = await _createExploreGroupMarker(entry, imageConfiguration: imageConfiguration);
        }
        else if (entry is Explore) {
          marker = await _createExploreMarker(entry, imageConfiguration: imageConfiguration);
        }
        if (marker != null) {
          markers.add(marker);
        }
      }
    }

    return markers;
  }

  Future<Marker?> _createExploreGroupMarker(List<Explore>? exploreGroup, { required ImageConfiguration imageConfiguration }) async {
    LatLng? markerPosition = ExploreMap.centerOfList(exploreGroup);
    if ((exploreGroup != null) && (markerPosition != null)) {
      Explore? sameExplore = ExploreMap.mapGroupSameExploreForList(exploreGroup);
      Color? markerColor = sameExplore?.mapMarkerColor ?? ExploreMap.unknownMarkerColor;
      Color? markerBorderColor = sameExplore?.mapMarkerBorderColor ?? ExploreMap.defaultMarkerBorderColor;
      Color? markerTextColor = sameExplore?.mapMarkerTextColor ?? ExploreMap.defaultMarkerTextColor;
      String markerKey = "map-marker-group-${markerColor?.toARGB32() ?? 0}-${exploreGroup.length}";
      BitmapDescriptor markerIcon = _markerIconsCache[markerKey] ??
        (_markerIconsCache[markerKey] = await _groupMarkerIcon(
          context: context,
          imageSize: _mapGroupMarkerSize,
          backColor: markerColor,
          borderColor: markerBorderColor,
          textColor: markerTextColor,
          text: exploreGroup.length.toString(),
        ));
      return Marker(
        markerId: MarkerId("${markerPosition.latitude.toStringAsFixed(6)}:${markerPosition.latitude.toStringAsFixed(6)}"),
        position: markerPosition,
        icon: markerIcon,
        anchor: _mapCircleMarkerAnchor,
        consumeTapEvents: true,
        onTap: () => _onTapMarker(exploreGroup),
        infoWindow: InfoWindow(
          title:  sameExplore?.getMapGroupMarkerTitle(exploreGroup.length),
          anchor: _mapCircleMarkerAnchor
        )
      );
    }
    return null;
  }

  static Future<BitmapDescriptor> _groupMarkerIcon({required BuildContext context, required double imageSize,
      Color? backColor, Color? backColor2,
      Color? borderColor, double borderWidth = 1, double borderOffset = 0,
      Color? textColor, String? text
  }) async {
    Uint8List? markerImageBytes = await ImageUtils.mapGroupMarkerImage(
      imageSize: imageSize * MediaQuery.of(context).devicePixelRatio,
      backColor: backColor, backColor2: backColor2,
      strokeColor: borderColor,
      strokeWidth: borderWidth * MediaQuery.of(context).devicePixelRatio,
      strokeOffset: borderOffset  * MediaQuery.of(context).devicePixelRatio,
      text: text,
      textStyle: (text != null) ? Styles().textStyles.getTextStyle("widget.text.fat")?.copyWith(
        fontSize: 12 * MediaQuery.of(context).devicePixelRatio,
        color: textColor,
        overflow: TextOverflow.visible //defined in code to be sure it is set
      ) : null,
    );
    if (markerImageBytes != null) {
      return BitmapDescriptor.bytes(markerImageBytes,
        imagePixelRatio: MediaQuery.of(context).devicePixelRatio,
        width: imageSize, height: imageSize,
      );
    }
    else if (backColor != null) {
      return BitmapDescriptor.defaultMarkerWithHue(ColorUtils.hueFromColor(backColor).toDouble());
    }
    else {
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<Marker?> _createExploreMarker(Explore? explore, { required ImageConfiguration imageConfiguration, Color? markerColor}) async {
    LatLng? markerPosition = explore?.exploreLocation?.exploreLocationMapCoordinate;
    if (markerPosition != null) {
      BitmapDescriptor? markerIcon;
      Offset? markerAnchor;
      if (explore is MTDStop) {
        String markerAsset = 'images/map-marker-mtd-stop.png';
        markerIcon = _markerIconsCache[markerAsset] ??
          (_markerIconsCache[markerAsset] = await BitmapDescriptor.asset(imageConfiguration, markerAsset));
        markerAnchor = _mapCircleMarkerAnchor;
      }
      else {
        Color? exploreColor = markerColor ?? explore?.mapMarkerColor;
        markerIcon = (exploreColor != null) ? BitmapDescriptor.defaultMarkerWithHue(ColorUtils.hueFromColor(exploreColor).toDouble()) : BitmapDescriptor.defaultMarker;
        markerAnchor = _mapPinMarkerAnchor;
      }
      return Marker(
        markerId: MarkerId("${markerPosition.latitude.toStringAsFixed(6)}:${markerPosition.longitude.toStringAsFixed(6)}"),
        position: markerPosition,
        icon: markerIcon,
        anchor: markerAnchor,
        consumeTapEvents: true,
        onTap: () => _onTapMarker(explore),
        infoWindow: InfoWindow(
          title: explore?.mapMarkerTitle,
          snippet: explore?.mapMarkerSnippet,
          anchor: markerAnchor)
      );
    }
    return null;
  }

  Future<Marker?> _createPinMarker(Explore? explore, { required ImageConfiguration imageConfiguration }) async {
    LatLng? markerPosition = explore?.exploreLocation?.exploreLocationMapCoordinate;
    Offset markerAnchor = ((explore is ExplorePOI) && (explore.placeId?.isNotEmpty == true)) ? _mapPinMarkerAnchor : _mapCircleMarkerAnchor;
    return (markerPosition != null) ? Marker(
      markerId: MarkerId("${markerPosition.latitude.toStringAsFixed(6)}:${markerPosition.longitude.toStringAsFixed(6)}"),
      position: markerPosition,
      icon: _pinMarkerIcon ??= await _createPinMarkerIcon(),
      anchor: markerAnchor,
      consumeTapEvents: true,
      onTap: () => _onTapMarker(explore),
      infoWindow: InfoWindow(
        title: explore?.mapMarkerTitle,
        snippet: explore?.mapMarkerSnippet,
        anchor: markerAnchor)
    ) : null;
  }

  Future<BitmapDescriptor> _createPinMarkerIcon() => _groupMarkerIcon(
    context: context,
    imageSize: _mapPinMarkerSize,
    backColor: Styles().colors.accentColor3,
    backColor2: Styles().colors.mtdColor,
    borderColor: Styles().colors.white,
    borderWidth: 2,
    borderOffset: 3,
  );
}

extension _Map2ContentType on Map2ContentType {
  String get displayTitle => displayTitleEx();

  String displayTitleEx({String? language}) {
    switch(this) {
      case Map2ContentType.CampusBuildings:      return Localization().getStringEx('panel.explore.button.buildings.title', 'Campus Buildings', language: language);
      case Map2ContentType.StudentCourses:       return Localization().getStringEx('panel.explore.button.student_course.title', 'My Courses', language: language);
      case Map2ContentType.DiningLocations:      return Localization().getStringEx('panel.explore.button.dining.title', 'Residence Hall Dining', language: language);
      case Map2ContentType.Events2:              return Localization().getStringEx('panel.explore.button.events2.title', 'Events', language: language);
      case Map2ContentType.Laundries:            return Localization().getStringEx('panel.explore.button.laundry.title', 'Laundry', language: language);
      case Map2ContentType.BusStops:             return Localization().getStringEx('panel.explore.button.mtd_stops.title', 'MTD Stops', language: language);
      case Map2ContentType.Therapists:           return Localization().getStringEx('panel.explore.button.mental_health.title', 'Find a Therapist', language: language);
      case Map2ContentType.MyLocations:          return Localization().getStringEx('panel.explore.button.my_locations.title', 'My Locations', language: language);
    }
  }

  static Map2ContentType? fromJson(String? value) {
    switch (value) {
      case 'buildings': return Map2ContentType.CampusBuildings;
      case 'student_courses': return Map2ContentType.StudentCourses;
      case 'dining': return Map2ContentType.DiningLocations;
      case 'events2': return Map2ContentType.Events2;
      case 'laundry': return Map2ContentType.Laundries;
      case 'mtd_stops': return Map2ContentType.BusStops;
      case 'mental_health': return Map2ContentType.Therapists;
      case 'my_locations': return Map2ContentType.MyLocations;
      default: return null;
    }
  }

  String toJson() {
    switch(this) {
      case Map2ContentType.CampusBuildings:      return 'buildings';
      case Map2ContentType.StudentCourses:       return 'student_courses';
      case Map2ContentType.DiningLocations:      return 'dining';
      case Map2ContentType.Events2:              return 'events2';
      case Map2ContentType.Laundries:            return 'laundry';
      case Map2ContentType.BusStops:             return 'mtd_stops';
      case Map2ContentType.Therapists:           return 'mental_health';
      case Map2ContentType.MyLocations:          return 'my_locations';
    }
  }

  static const Map2ContentType _defaultType = Map2ContentType.CampusBuildings;

  static Map2ContentType? initialType({ Iterable<Map2ContentType>? availableTypes }) {
    dynamic storedType = Storage()._storedAvailableMap2ContentType(availableTypes: availableTypes);
    return (storedType is Map2ContentType?) ? storedType : (
      (_defaultType._ensure(availableTypes: availableTypes)) ??
      ((availableTypes?.isNotEmpty == true) ? availableTypes?.first : null)
    );
  }

  static Set<Map2ContentType> get availableTypes {
    List<dynamic>? codes = FlexUI()['explore.map'];
    Set<Map2ContentType> availableTypes = <Map2ContentType>{};
    if (codes != null) {
      for (dynamic code in codes) {
        Map2ContentType? contentType = fromJson(code);
        if (contentType != null) {
          availableTypes.add(contentType);
        }
      }
    }
    return availableTypes;
  }

  Map2ContentType? _ensure({ Iterable<Map2ContentType>? availableTypes }) =>
      (availableTypes?.contains(this) != false) ? this : null;
}

extension _StorageMapExt on Storage {
  static const String _nullContentTypeJson = 'null';

  // ignore: unused_element
  Map2ContentType? get _storedMap2ContentType => _Map2ContentType.fromJson(Storage().selectedMap2ContentType);
  set _storedMap2ContentType(Map2ContentType? value) => Storage().selectedMap2ContentType = value?.toJson() ?? _nullContentTypeJson;

  dynamic _storedAvailableMap2ContentType({ Iterable<Map2ContentType>? availableTypes }) {
    String? storedTypeJson = Storage().selectedMap2ContentType;
    if (storedTypeJson != null) {
      Map2ContentType? storedType = _Map2ContentType.fromJson(storedTypeJson);
      if (storedType == null) {
        return null; // selected: null
      }
      else {
        Map2ContentType? ensuredStoredType = storedType._ensure(availableTypes: availableTypes);
        if (ensuredStoredType != null) {
          return ensuredStoredType; // selected: ensuredStoredType
        }
        else {
          return false; // selected: n.a.
        }
      }
    }
    else {
      return false; // selected: n.a.
    }
  }
}

extension ExplorePOIImpl on ExplorePOI {

  static ExplorePOI fromMapPOI(PointOfInterest poi) =>
    ExplorePOI(
      placeId: poi.placeId,
      name: poi.name.replaceAll('\n', ' '),
      location: ExploreLocation(
        latitude: poi.position.latitude,
        longitude: poi.position.longitude
      )
    );

  static ExplorePOI fromMapCoordinate(LatLng coordinate) =>
    ExplorePOI(
      placeId: null,
      name: Localization().getStringEx('panel.explore.item.location.name','Location'),
      location: ExploreLocation(
        latitude: coordinate.latitude,
        longitude: coordinate.longitude
      )
    );
}

abstract class _Map2Filter {
  List<Explore> process(List<Explore> explores);
}

class _Map2CampusBuildingsFilters implements _Map2Filter {
  String search;
  bool starred;
  Set<String> amenities;

  // ignore: unused_element_parameter
  _Map2CampusBuildingsFilters({this.search = "", this.starred = false, this.amenities = const <String>{}});

  @override
  List<Explore> process(List<Explore> explores) {
    if (explores.isNotEmpty && ((search.isNotEmpty == true) || (starred == true) || (amenities.isNotEmpty == true))) {
      String? searchLowerCase = search.toLowerCase();
      Iterable<String> amenitiesLowerCase = amenities.map((String amenity) => amenity.toLowerCase());

      List<Explore> filtered = <Explore>[];
      for (Explore explore in explores) {
        if ((explore is Building) &&
            ((searchLowerCase.isNotEmpty != true) || (explore.matchSearchLowerCase(searchLowerCase))) &&
            ((starred != true) || (Auth2().prefs?.isFavorite(explore as Favorite) == true)) &&
            ((amenitiesLowerCase.isNotEmpty != true) || (explore.matchAmenitiesLowerCase(amenitiesLowerCase)))
          ) {
          filtered.add(explore);
        }
      }
      return filtered;
    }
    else {
      return explores;
    }
  }

}