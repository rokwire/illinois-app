
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/ext/Map2.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/map2/Map2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

enum Map2ContentType { CampusBuildings, StudentCourses, DiningLocations, Events2, Laundries, BusStops, Therapists, MyLocations }

typedef Future<List<Explore>?> LoadExploresTask();

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

  UniqueKey _mapKey = UniqueKey();
  GoogleMapController? _mapController;
  CameraPosition? _lastCameraPosition;
  Set<Marker>? _mapMarkers;

  late Set<Map2ContentType> _availableContentTypes;
  Map2ContentType? _selectedContentType;

  List<Explore>? _explores;
  LoadExploresTask? _loadExploresTask;

  DateTime? _pausedDateTime;
  Position? _currentLocation;
  LocationServicesStatus? _locationServicesStatus;

  static const CameraPosition _defaultCameraPosition = CameraPosition(target: _defaultCameraTarget, zoom: _defaultCameraZoom);
  static const LatLng _defaultCameraTarget = LatLng(40.102116, -88.227129);
  static const double _defaultCameraZoom = 17;

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

  Widget get _scaffoldBody =>
    Stack(children: [
      _map2View,
      Positioned.fill(child:
        Align(alignment: Alignment.topCenter, child:
          _map2Heading,
        ),
      ),
    ],);

  Widget get _map2Heading => (_selectedContentType != null) ?
    _contentTypeHeading : _contentTypesBar;

  Widget get _map2View => Container(decoration: _mapViewDecoration, child:
    GoogleMap(
      key: _mapKey,
      initialCameraPosition: _lastCameraPosition ??= _defaultCameraPosition,
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

  // Map Events

  void _onMapCreated(GoogleMapController controller) async {
    debugPrint('Map2 created' );
    _mapController = controller;
  }

  void _onMapCameraMove(CameraPosition cameraPosition) {
    debugPrint('Map2 camera position: lat: ${cameraPosition.target.latitude} lng: ${cameraPosition.target.longitude} zoom: ${cameraPosition.zoom}' );
    _lastCameraPosition = cameraPosition;
  }

  void _onMapCameraIdle() {
    debugPrint('Map2 camera idle' );
  }

  void _onMapTap(LatLng coordinate) {
    debugPrint('Map2 tap' );
  }

  void _onMapPoiTap(PointOfInterest poi) {
    debugPrint('Map2 POI tap' );
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
        if ((_selectedContentType != null) && !_availableContentTypes.contains(_selectedContentType)) {
          _selectedContentType = null;
        }
      });
    }
  }

  void _onContentTypeEntry(Map2ContentType contentType) {
    setState(() {
      _selectedContentType = contentType;
    });

  }

  // Content Type

  Widget get _contentTypeHeading => Container(decoration: _contentHeadingDecoration, child:
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
    });
  }

  // Explores

  Future<List<Explore>?> _loadExplores() async {
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

