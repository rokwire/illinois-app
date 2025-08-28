
import 'dart:io';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Map2.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/MTD.dart';
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
import 'package:illinois/ui/map2/Map2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/Utils.dart';
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

  final GlobalKey _mapWrapperKey = GlobalKey();
  final GlobalKey _contentHeadingBarKey = GlobalKey();

  UniqueKey _mapKey = UniqueKey();
  GoogleMapController? _mapController;
  CameraPosition? _lastCameraPosition;
  CameraUpdate? _targetCameraUpdate;
  double? _lastMapZoom;

  late Set<Map2ContentType> _availableContentTypes;
  Map2ContentType? _selectedContentType;

  List<Explore>? _explores;
  LoadExploresTask? _exploresTask;
  bool _exploresProgress = false;

  Set<Marker>? _mapMarkers;
  Set<dynamic>? _exploreMapGroups;
  BuildMarkersTask? _buildMarkersTask;
  MarkerIconsCache _markerIconsCache = <String, BitmapDescriptor>{};
  bool _markersProgress = false;

  DateTime? _pausedDateTime;
  Position? _currentLocation;
  LocationServicesStatus? _locationServicesStatus;

  static const CameraPosition _defaultCameraPosition = CameraPosition(target: _defaultCameraTarget, zoom: _defaultCameraZoom);
  static const LatLng _defaultCameraTarget = LatLng(40.102116, -88.227129);
  static const double _defaultCameraZoom = 17;
  static const double _mapPadding = 50;
  static const double _mapGroupMarkerSize = 24;
  static const double _groupMarkersUpdateThresoldDelta = 0.3;
  static const List<double> _thresoldDistanceByZoom = [
		1000000, 800000, 600000, 200000, 100000, // zoom 0 - 4
		 100000,  80000,  60000,  20000,  10000, // zoom 5 - 9
		   5000,   2000,   1000,    500,    250, // zoom 10 - 14
		    100,     50,      0                  // zoom 15 - 16
  ];

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Connectivity.notifyStatusChanged,
      LocationServices.notifyStatusChanged,
      FlexUI.notifyChanged,
    ]);

    _availableContentTypes = _Map2ContentType.availableTypes;

    _updateLocationServicesStatus(init: true);
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
      appBar: RootHeaderBar(title: Localization().getStringEx("panel.maps2.header.title", "Map2")),
      body: _scaffoldBody,
      backgroundColor: Styles().colors.background,
    );
  }

/*  Widget get _scaffoldBody => Stack(key: _mapWrapperKey, children: [

    Positioned.fill(child:
      Opacity(opacity: (_exploresProgress == false) ? 1 : 0, child:
        _mapView
      ),
    ),

    Positioned.fill(child:
      Align(alignment: Alignment.topCenter, child:
        Opacity(opacity: (_selectedContentType != null) ? 1 : 0, child:
          _contentHeadingBar
        ),
      ),
    ),

    Positioned.fill(child:
      Align(alignment: Alignment.topCenter, child:
        Opacity(opacity: (_selectedContentType == null) ? 1 : 0, child:
          _contentTypesBar
        ),
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
  ],);*/

  Widget get _scaffoldBody => Column(children: [
    if (_selectedContentType != null)
      _contentHeadingBar,

    Expanded(child:
      Stack(key: _mapWrapperKey, children: [
        Positioned.fill(child:
          Visibility(visible: _exploresProgress == false, child:
            _mapView
          ),
        ),

        if (_selectedContentType == null)
          Positioned.fill(child:
            Align(alignment: Alignment.topCenter, child:
              _contentTypesBar,
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

      ],)
    )
  ],);


  Widget get _mapView => Container(decoration: _mapViewDecoration, child:
    GoogleMap(
      key: _mapKey,
      initialCameraPosition: _lastCameraPosition ?? _defaultCameraPosition,
      onMapCreated: _onMapCreated,
      onCameraIdle: _onMapCameraIdle,
      onCameraMove: _onMapCameraMove,
      onTap: _onMapTap,
      onPoiTap: _onMapPoiTap,
      myLocationEnabled: _userLocationEnabled,
      myLocationButtonEnabled: _userLocationEnabled,
      mapToolbarEnabled: Storage().debugMapShowLevels == true,
      markers: _mapMarkers ?? const <Marker>{},
      style: null,
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
    _mapController?.getZoomLevel().then((double value) {
      if (_lastMapZoom == null) {
        _lastMapZoom = value;
      }
      else if ((_lastMapZoom! - value).abs() > _groupMarkersUpdateThresoldDelta) {
        _buildMapContentData(_explores, updateCamera: false, showProgress: true, zoom: value,);
      }
    });
  }

  void _onMapTap(LatLng coordinate) {
    // debugPrint('Map2 tap' );
  }

  void _onMapPoiTap(PointOfInterest poi) {
    // debugPrint('Map2 POI tap' );
  }

  void _onTapMarker(dynamic origin) {
    // debugPrint('Map2 Marker tap' );
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
          CameraPosition cameraPosition = CameraPosition(target: currentLocation.gmsLatLng, zoom: _defaultCameraZoom);
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
          child: Map2ContentTypeButton(
            title: contentType.displayTitle,
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
      _selectedContentType = contentType;
    });
    _initExplores();
  }

  // Content Type

  Widget get _contentHeadingBar => Container(key: _contentHeadingBarKey, decoration: _contentHeadingDecoration, child:
      Column(mainAxisSize: MainAxisSize.min, children: [
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
        ],)
      ],)
  );
    
  BoxDecoration get _contentHeadingDecoration =>
    BoxDecoration(
      color: Styles().colors.background,
      border: Border(bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1),),
      boxShadow: [BoxShadow(color: Styles().colors.dropShadow, spreadRadius: 1, blurRadius: 3, offset: Offset(1, 1) )],
    );

  void _onUnselectContentType() {
    setState(() {
      _selectedContentType = null;
      _explores = null;
      _exploresTask = null;
      _exploresProgress = false;

      _mapMarkers = null;
      _exploreMapGroups = null;
      _targetCameraUpdate = null;
      _buildMarkersTask = null;
      _lastMapZoom = null;
      _markersProgress = false;
    });

    double? contentHeadingHeight = _contentHeadingBarKey.renderBoxSize?.height;
    if (contentHeadingHeight != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController?.moveCamera(CameraUpdate.scrollBy(0, -contentHeadingHeight / 2));
      });
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
          _explores = null;
        });

        // wait for explores load
        List<Explore>? explores = await exploresTask;

        if (mounted && (exploresTask == _exploresTask)) {
          await _buildMapContentData(explores, pinnedExplore: null, updateCamera: true);
          if (mounted && (exploresTask == _exploresTask)) {
            setState(() {
              _explores = explores;
              _exploresTask = null;
              _exploresProgress = false;
              _mapKey = UniqueKey(); // force map rebuild
            });
          }
        }
      }
      else {
        setState(() {
          _explores = null;
          _exploresTask = null;
          _exploresProgress = false;

          _mapMarkers = null;
          _exploreMapGroups = null;
          _targetCameraUpdate = null;
          _buildMarkersTask = null;
          _lastMapZoom = null;
          _markersProgress = false;
        });
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

  List<Explore>? _loadMyLocations() =>
    ExplorePOI.listFromString(Auth2().prefs?.getFavorites(ExplorePOI.favoriteKeyName));

  // Map Content

  Future<void> _buildMapContentData(List<Explore>? explores, {Explore? pinnedExplore, bool updateCamera = false, bool showProgress = false, double? zoom}) async {
    LatLngBounds? exploresBounds = ExploreMap.boundsOfList(explores);

    CameraUpdate? targetCameraUpdate;
    if (updateCamera) {
      if (exploresBounds == null) {
        targetCameraUpdate = CameraUpdate.newCameraPosition(_defaultCameraPosition);
      }
      else if (exploresBounds.northeast == exploresBounds.southwest) {
        targetCameraUpdate = CameraUpdate.newCameraPosition(CameraPosition(target: exploresBounds.northeast, zoom: _defaultCameraPosition.zoom));
      }
      else {
        targetCameraUpdate = CameraUpdate.newLatLngBounds(exploresBounds, _mapPadding);
      }
    }

    Size? mapSize = _mapWrapperKey.renderBoxSize;
    if ((exploresBounds != null) && (mapSize != null)) {

      double thresoldDistance;
      Set<dynamic>? exploreMapGroups;
      if (exploresBounds.northeast != exploresBounds.southwest) {
        double? debugThresoldDistance = Storage().debugMapThresholdDistance?.toDouble();
        if (debugThresoldDistance != null) {
          thresoldDistance = debugThresoldDistance;
        }
        else {
          zoom ??= GeoMapUtils.getMapBoundZoom(exploresBounds, math.max(mapSize.width - 2 * _mapPadding, 0), math.max(mapSize.height - 2 * _mapPadding, 0));
          thresoldDistance = _thresoldDistanceForZoom(zoom);
        }
        exploreMapGroups = _buildExplorMapGroups(explores, thresoldDistance: thresoldDistance);
      }
      else {
        thresoldDistance = 0;
        exploreMapGroups =  (explores != null) ? <dynamic>{ ExploreMap.validFromList(explores) } : null;
      }
      if (!DeepCollectionEquality().equals(_exploreMapGroups, exploreMapGroups)) {
        BuildMarkersTask buildMarkersTask = _buildMarkers(context, exploreGroups: exploreMapGroups, pinnedExplore: pinnedExplore);
        _buildMarkersTask = buildMarkersTask;
        if (showProgress && mounted) {
          setState(() {
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
          setState(() {
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
      setState(() {
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
    if ((0 <= zoomIndex) && (zoomIndex < _thresoldDistanceByZoom.length)) {
      double zoomDistance = _thresoldDistanceByZoom[zoomIndex];
      double nextZoomDistance = ((zoomIndex + 1) < _thresoldDistanceByZoom.length) ? _thresoldDistanceByZoom[zoomIndex + 1] : 0;
      double thresoldDistance = zoomDistance - (zoom - zoomIndex.toDouble()) * (zoomDistance - nextZoomDistance);
      return thresoldDistance;
    }
    return 0;
  }

  // Map Markers

  Future<Set<Marker>> _buildMarkers(BuildContext context, { Set<dynamic>? exploreGroups, Explore? pinnedExplore }) async {
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

    if (pinnedExplore != null) {
      Marker? marker = await _createExploreMarker(pinnedExplore, imageConfiguration: imageConfiguration);
      if (marker != null) {
        markers.add(marker);
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
          count: exploreGroup.length,
        ));
      Offset markerAnchor = Offset(0.5, 0.5);
      return Marker(
        markerId: MarkerId("${markerPosition.latitude.toStringAsFixed(6)}:${markerPosition.latitude.toStringAsFixed(6)}"),
        position: markerPosition,
        icon: markerIcon,
        anchor: markerAnchor,
        consumeTapEvents: true,
        onTap: () => _onTapMarker(exploreGroup),
        infoWindow: InfoWindow(
          title:  sameExplore?.getMapGroupMarkerTitle(exploreGroup.length),
          anchor: markerAnchor
        )
      );
    }
    return null;
  }

  static Future<BitmapDescriptor> _groupMarkerIcon({required BuildContext context, required double imageSize, Color? backColor, Color? borderColor, Color? textColor, int? count}) async {
    Uint8List? markerImageBytes = await ImageUtils.mapGroupMarkerImage(
      imageSize: imageSize * MediaQuery.of(context).devicePixelRatio,
      backColor: backColor,
      strokeColor: borderColor,
      text: count?.toString(),
      textStyle: Styles().textStyles.getTextStyle("widget.text.fat")?.copyWith(
        fontSize: 12 * MediaQuery.of(context).devicePixelRatio,
        color: textColor,
        overflow: TextOverflow.visible //defined in code to be sure it is set
      ),
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
        markerAnchor = Offset(0.5, 0.5);
      }
      else {
        Color? exploreColor = markerColor ?? explore?.mapMarkerColor;
        markerIcon = (exploreColor != null) ? BitmapDescriptor.defaultMarkerWithHue(ColorUtils.hueFromColor(exploreColor).toDouble()) : BitmapDescriptor.defaultMarker;
        markerAnchor = Offset(0.5, 1);
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

  static Map2ContentType? fromJsonString(String? value) {
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

  static Set<Map2ContentType> get availableTypes {
    List<dynamic>? codes = FlexUI()['explore.map'];
    Set<Map2ContentType> availableTypes = <Map2ContentType>{};
    if (codes != null) {
      for (dynamic code in codes) {
        Map2ContentType? contentType = fromJsonString(code);
        if (contentType != null) {
          availableTypes.add(contentType);
        }
      }
    }
    return availableTypes;
  }
}

extension _Map2ExploreContent on Map2ContentType {

}

