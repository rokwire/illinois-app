
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
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

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
  Set<Marker>? _mapMarkers;

  CameraPosition? _lastCameraPosition;

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
    _map2View;

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
    BoxDecoration(border: Border.all(color: Styles().colors.disabledTextColor, width: 1));

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
}
