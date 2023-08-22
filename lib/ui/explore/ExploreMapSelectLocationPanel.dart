
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/Appointment.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/Location.dart' as Native;
import 'package:illinois/model/MTD.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Gateway.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/explore/ExploreListPanel.dart';
import 'package:illinois/ui/explore/ExploreMapPanel.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/image_utils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class ExploreMapSelectLocationPanel extends StatefulWidget {

  final ExploreMapType? mapType;
  final Explore? selectedExplore;

  ExploreMapSelectLocationPanel({ Key? key, this.mapType, this.selectedExplore });
  
  @override
  State<StatefulWidget> createState() => _ExploreMapSelectLocationPanelState();
}

class _ExploreMapSelectLocationPanelState extends State<ExploreMapSelectLocationPanel>
  with SingleTickerProviderStateMixin implements NotificationsListener {

  late ExploreMapType? _mapType;

  List<Explore>? _explores;
  bool _exploreProgress = false;

  final GlobalKey _mapContainerKey = GlobalKey();
  final GlobalKey _mapExploreBarKey = GlobalKey();
  final Map<String, BitmapDescriptor> _markerIconCache = <String, BitmapDescriptor>{};
  static const CameraPosition _defaultCameraPosition = CameraPosition(target: LatLng(40.102116, -88.227129), zoom: 17);
  static const double _mapPadding = 50;
  static const double _mapGroupMarkerSize = 24;
  static const double _groupMarkersUpdateThresoldDelta = 0.3;
  static const List<double> _thresoldDistanceByZoom = [
		1000000, 800000, 600000, 200000, 100000, // zoom 0 - 4
		 100000,  80000,  60000,  20000,  10000, // zoom 5 - 9
		   5000,   2000,   1000,    500,    250, // zoom 10 - 14
		    100,     50,      0                  // zoom 15 - 16
  ];

  UniqueKey _mapKey = UniqueKey();
  GoogleMapController? _mapController;
  CameraPosition? _lastCameraPosition;
  double? _lastMarkersUpdateZoom;
  CameraUpdate? _targetCameraUpdate;
  String? _targetMapStyle, _lastMapStyle;
  Set<dynamic>? _exploreMarkerGroups;
  Set<Marker>? _targetMarkers;
  bool _markersProgress = false;
  Future<Set<Marker>?>? _buildMarkersTask;
  Explore? _pinnedMapExplore;
  dynamic _selectedMapExplore;
  AnimationController? _mapExploreBarAnimationController;
  
  LocationServicesStatus? _locationServicesStatus;

  @override
  void initState() {
    
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);

    _mapType = widget.mapType;

    _mapExploreBarAnimationController = AnimationController (duration: Duration(milliseconds: 200), lowerBound: 0, upperBound: 1, vsync: this)
      ..addListener(() {
        setStateIfMounted(() {
        });
      });

    _initLocationServicesStatus().then((_) {
      _initExplores();
    });

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _mapExploreBarAnimationController?.dispose();
    super.dispose();
  }

  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _onFavoritesChanged();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx("panel.map.select.header.title", "Select Location")),
      body: _buildScaffoldBody(),
      backgroundColor: Styles().colors?.background,
    );
  }

  Widget _buildScaffoldBody() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child:
        Container(key: _mapContainerKey, color: Styles().colors!.background, child:
          _buildContent(),
        ),
      ),
    ]);
  }

  // Map Widget

  Widget _buildContent() {
    if (_exploreProgress) {
      return _buildLoadingContent();
    }
    else {
      return _buildMapContent();
    }
  }

  Widget _buildMapContent() {
    return Stack(children: [
      _buildMapView(),
      _buildMapExploreBar(),
      Visibility(visible: _markersProgress, child:
        Positioned.fill(child:
          Center(child:
            SizedBox(width: 24, height: 24, child:
              CircularProgressIndicator(color: Styles().colors?.accentColor2, strokeWidth: 3,),
            )
          )
        )
      )
    ],);
  }

  Widget _buildMapView() {
    return Container(decoration: BoxDecoration(border: Border.all(color: Styles().colors?.disabledTextColor ?? Color(0xFF717273), width: 1)), child:
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
        mapToolbarEnabled: Storage().debugMapShowLevels ?? false,
        markers: _targetMarkers ?? const <Marker>{},
        indoorViewEnabled: true,
      //trafficEnabled: true,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) async {
    debugPrint('ExploreMap created' );
    _mapController = controller;

    if (_targetMapStyle != _lastMapStyle) {
      _mapController?.setMapStyle(_lastMapStyle = _targetMapStyle).catchError((e) {
        debugPrint(e.toString());
      });
    }

    if (_targetCameraUpdate != null) {
      if (Platform.isAndroid) {
        Future.delayed(Duration(milliseconds: 100), () {
          _mapController?.moveCamera(_targetCameraUpdate!).then((_) {
            _targetCameraUpdate = null;
          });
        });
      }
      else {
        _mapController?.moveCamera(_targetCameraUpdate!).then((_) {
          _targetCameraUpdate = null;
        });
      }
    }
  }

  void _onMapCameraMove(CameraPosition cameraPosition) {
    debugPrint('ExploreMap camera position: lat: ${cameraPosition.target.latitude} lng: ${cameraPosition.target.longitude} zoom: ${cameraPosition.zoom}' );
    _lastCameraPosition = cameraPosition;
  }

  void _onMapCameraIdle() {
    debugPrint('ExploreMap camera idle' );
    _mapController?.getZoomLevel().then((double value) {
      if (_lastMarkersUpdateZoom == null) {
        _lastMarkersUpdateZoom = value;
      }
      else if ((_lastMarkersUpdateZoom! - value).abs() > _groupMarkersUpdateThresoldDelta) {
        _buildMapContentData(_explores, pinnedExplore: _pinnedMapExplore, updateCamera: false, zoom: value, showProgress: true);
      }
    });
  }

  void _onMapTap(LatLng coordinate) {
    debugPrint('ExploreMap tap' );
    MTDStop? mtdStop = MTD().stops?.findStop(location: Native.LatLng(latitude: coordinate.latitude, longitude: coordinate.longitude), locationThresholdDistance: 25 /*in meters*/);
    if (mtdStop != null) {
      _selectMapExplore(mtdStop);
    }
    else if (_selectedMapExplore != null) {
      _selectMapExplore(null);
    }
    else {
      _selectMapExplore(ExplorePOI(location: ExploreLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)));
    }
  }

  void _onMapPoiTap(PointOfInterest poi) {
    debugPrint('ExploreMap POI tap' );
    MTDStop? mtdStop = MTD().stops?.findStop(location: Native.LatLng(latitude: poi.position.latitude, longitude: poi.position.longitude), locationThresholdDistance: 25 /*in meters*/);
    if (mtdStop != null) {
      _selectMapExplore(mtdStop);
    }
    else if (_selectedMapExplore != null) {
      _selectMapExplore(null);
    }
    else {
      _selectMapExplore(ExplorePOI(placeId: poi.placeId, name: poi.name, location: ExploreLocation(latitude: poi.position.latitude, longitude: poi.position.longitude)));
    }
  }

  void _onTapMarker(dynamic origin) {
    _selectMapExplore(origin);
  }

  // Map Explore Bar

  Widget _buildMapExploreBar() {
    Color? exploreColor;
    String? title, description;
    String detailsLabel = Localization().getStringEx('panel.explore.button.details.title', 'Details');
    String detailsHint = Localization().getStringEx('panel.explore.button.details.hint', '');
    void Function() onTapDetail = _onTapMapExploreDetail;
    bool canSelect = false, canDetail = true;

    if (_selectedMapExplore is Explore) {
      title = (_selectedMapExplore as Explore).mapMarkerTitle;
      description = (_selectedMapExplore as Explore).mapMarkerSnippet;
      exploreColor = (_selectedMapExplore as Explore).uiColor ?? Styles().colors?.white;
      if (_selectedMapExplore is ExplorePOI) {
        title = title?.replaceAll('\n', ' ');
        detailsLabel = Localization().getStringEx('panel.explore.button.clear.title', 'Clear');
        detailsHint = Localization().getStringEx('panel.explore.button.clear.hint', '');
        onTapDetail = _onTapMapClear;
      }
      canSelect = true;
    }
    else if  (_selectedMapExplore is List<Explore>) {
      String? exploreName = ExploreExt.getExploresListDisplayTitle(_selectedMapExplore);
      title = sprintf(Localization().getStringEx('panel.explore.map.popup.title.format', '%d %s'), [_selectedMapExplore?.length, exploreName]);
      Explore? explore = _selectedMapExplore.isNotEmpty ? _selectedMapExplore.first : null;
      description = explore?.exploreLocation?.description ?? "";
      exploreColor = explore?.uiColor ?? Styles().colors?.fillColorSecondary;
    }
    else {
      exploreColor = Styles().colors?.white;
      canSelect = canDetail = false;
    }

    double buttonWidth = (MediaQuery.of(context).size.width - (40 + 12)) / 2;

    double barHeight = _mapExploreBarSize?.height ?? 0;
    double wrapHeight = _mapSize?.height ?? 0;
    double progress = _mapExploreBarAnimationController?.value ?? 0;
    double top = wrapHeight - (progress * barHeight);

    return Positioned(top: top, left: 0, right: 0, child:
      Container(key: _mapExploreBarKey, decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: exploreColor!, width: 2, style: BorderStyle.solid), bottom: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1, style: BorderStyle.solid),),), child:
        SafeArea(child:
        Stack(children: [
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Padding(padding: EdgeInsets.only(right: 10), child:
                Text(title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: Styles().textStyles?.getTextStyle("widget.title.large.extra_fat")),
              ),
              Text(description ?? "", overflow: TextOverflow.ellipsis, style: Styles().textStyles?.getTextStyle("panel.event_schedule.map.description")),
              Container(height: 8,),
              Row(children: <Widget>[
                SizedBox(width: buttonWidth, child:
                  RoundedButton(
                    label: Localization().getStringEx('panel.map.select.button.select.title', 'Select'),
                    hint: Localization().getStringEx('panel.map.select.button.select.hint', ''),
                    textStyle: canSelect ? Styles().textStyles?.getTextStyle("widget.button.title.enabled") : Styles().textStyles?.getTextStyle("widget.button.title.disabled"),
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    borderColor: canSelect ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
                    onTap: _onTapMapSelectLocation
                  ),
                ),
                Container(width: 12,),
                SizedBox(width: buttonWidth, child:
                  RoundedButton(
                    label: detailsLabel,
                    hint: detailsHint,
                    textStyle: canDetail ? Styles().textStyles?.getTextStyle("widget.button.title.enabled") : Styles().textStyles?.getTextStyle("widget.button.title.disabled"),
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    borderColor: canDetail ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
                    onTap: onTapDetail,
                  ),
                ),
              ],),
            ]),
          ),
          (_selectedMapExplore is Favorite) ?
            Align(alignment: Alignment.topRight, child:
              FavoriteButton(favorite: (_selectedMapExplore as Favorite), style: FavoriteIconStyle.SlantHeader, padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),),
            ) :
            Container(),
        ],),
        ),
      ),
    );
  }

  void _onTapMapSelectLocation() async {
    Analytics().logSelect(target: 'Directions');
    dynamic explore = _selectedMapExplore;
    // _selectMapExplore(null);

    if (explore is Explore) {
      Navigator.pop(context, explore);
    }
  }
  
  void _onTapMapExploreDetail() {
    Analytics().logSelect(target: (_selectedMapExplore is MTDStop) ? 'Bus Schedule' : 'Details');
    if (_selectedMapExplore is Explore) {
        (_selectedMapExplore as Explore).exploreLaunchDetail(context);
    }
    else if (_selectedMapExplore is List<Explore>) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreListPanel(explores: _selectedMapExplore, exploreMapType: _mapType,),));
    }
    _selectMapExplore(null);
  }

  void _onTapMapClear() {
    Analytics().logSelect(target: 'Clear');
    dynamic selectedMapExplore = _selectedMapExplore;
    _selectMapExplore(null);
    if (selectedMapExplore is Favorite) {
      Future.delayed(Duration(milliseconds: 100), (){
        Auth2().account?.prefs?.setFavorite(selectedMapExplore, false);
      });
    }
  }

  void _selectMapExplore(dynamic explore) {
    if (explore != null) {
      _pinMapExplore(((explore is ExplorePOI) && StringUtils.isEmpty(explore.placeId)) ? explore : null);
      setStateIfMounted(() {
        _selectedMapExplore = explore;
      });
      _mapExploreBarAnimationController?.forward();
    }
    else if (_selectedMapExplore != null) {
      _pinMapExplore(null);
      _mapExploreBarAnimationController?.reverse().then((_) {
        setStateIfMounted(() {
          _selectedMapExplore = null;
        });
      });
    }
    else {
      _pinMapExplore(null);
    }
  }

  Future<void> _pinMapExplore(Explore? explore) async {
    if (_pinnedMapExplore != explore) {
      Future<Set<Marker>> buildMarkersTask = _buildMarkers(context, exploreGroups: _exploreMarkerGroups, pinnedExplore: explore);
      setStateIfMounted(() {
        _markersProgress = true;
        _pinnedMapExplore = explore;
        _buildMarkersTask = buildMarkersTask;
      });

      debugPrint('Rebbuilding Markers markersSource: ${_exploreMarkerGroups?.length}');
      Set<Marker> targetMarkers = await buildMarkersTask;
      debugPrint('Finished Rebuilding Markers => ${targetMarkers.length}');

      if (_buildMarkersTask == buildMarkersTask) {
        debugPrint('Applying ${targetMarkers.length} Building Markers');
        setStateIfMounted(() {
          _targetMarkers = targetMarkers;
          _markersProgress = false;
          _buildMarkersTask = null;
        });
      }
    }
  }

  Widget _buildLoadingContent() {
    return Semantics(
      label: Localization().getStringEx('panel.explore.state.loading.title', 'Loading'),
      hint: Localization().getStringEx('panel.explore.state.loading.hint', 'Please wait'),
      excludeSemantics: true,
      child: Column(children: [
        Expanded(flex: 1, child: Container(),),
        SizedBox(width: 32, height: 32, child:
          CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 3,),
        ),
        Expanded(flex: 1, child: Container(),),
      ],)
    );
  }

  // Locaction Services

  bool get _userLocationEnabled {
    return FlexUI().isLocationServicesAvailable && (_locationServicesStatus == LocationServicesStatus.permissionAllowed);
  }

  Future<void> _initLocationServicesStatus({ LocationServicesStatus? status}) async {
    status ??= FlexUI().isLocationServicesAvailable ? await LocationServices().status : LocationServicesStatus.serviceDisabled;
    if ((status != null) && (status != _locationServicesStatus)) {
      setStateIfMounted(() {
        _locationServicesStatus = status;
      });
    }
  }

  // Explore Content

  Future<void> _initExplores() async {
    applyStateIfMounted(() {
      _exploreProgress = true;
    });
    List<Explore>? explores = await _loadExplores();
    if (mounted) {
      await _buildMapContentData(explores, pinnedExplore: widget.selectedExplore, updateCamera: true);
      if (mounted) {
        setState(() {
          _explores = explores;
          _exploreProgress = false;
          _mapKey = UniqueKey(); // force map rebuild
        });
        _selectMapExplore(widget.selectedExplore);
     }
    }
  }

  Future<List<Explore>?> _loadExplores() async {
    if (Connectivity().isNotOffline) {
      switch (_mapType) {
        case ExploreMapType.Events2: return Events2().loadEventsList(Events2Query());
        case ExploreMapType.Dining: return _loadDinings();
        case ExploreMapType.Laundry: return _loadLaundry();
        case ExploreMapType.Buildings: return Gateway().loadBuildings();
        case ExploreMapType.StudentCourse: return _loadStudentCourses();
        case ExploreMapType.Appointments: return _loadAppointments();
        case ExploreMapType.MTDStops: return _loadMTDStops();
        case ExploreMapType.MTDDestinations: return _loadMTDDestinations();
        case ExploreMapType.MentalHealth: return Wellness().loadMentalHealthBuildings();
        case ExploreMapType.StateFarmWayfinding: break;
        default: break;
      }
    }
    return null;
  }

  Future<List<Explore>?> _loadDinings() async {
    return Dinings().loadBackendDinings(false, null, null);
  }

  Future<List<Explore>?> _loadLaundry() async {
    LaundrySchool? laundrySchool = await Laundries().loadSchoolRooms();
    return laundrySchool?.rooms;
  }

  Future<List<Explore>?> _loadStudentCourses() async {
    String? termId = StudentCourses().displayTermId;
    return (termId != null) ? await StudentCourses().loadCourses(termId: termId) : null;
  }

  Future<List<Explore>?> _loadAppointments() async {
    return Appointments().getAppointments(timeSource: AppointmentsTimeSource.upcoming, type: AppointmentType.in_person);
  }

  List<Explore>? _loadMTDStops() {
    List<Explore> result = <Explore>[];
    _collectBusStops(result, stops: MTD().stops?.stops);
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

  List<Explore>? _loadMTDDestinations() {
    return ExplorePOI.listFromString(Auth2().prefs?.getFavorites(ExplorePOI.favoriteKeyName)) ?? <Explore>[];
  }

  // Favorites

  void _onFavoritesChanged() {
    if (_mapType == ExploreMapType.MTDDestinations) {
      _refreshMTDDestinations();
    }
    else {
      setStateIfMounted(() {});
    }
  }

  // MTD Destinations

  void _refreshMTDDestinations() {
    List<Explore>? explores = _loadMTDDestinations();
    if (!DeepCollectionEquality().equals(_explores, explores) && mounted) {
      _buildMapContentData(explores, pinnedExplore: _pinnedMapExplore, updateCamera: false).then((_){
        if (mounted) {
          setState(() {
            _explores = explores;
          });
        }
      });
    }
  }


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

    Size? mapSize = _mapSize;
    if ((exploresBounds != null) && (mapSize != null)) {
      
      double thresoldDistance;
      Set<dynamic>? exploreMarkerGroups;
      if (exploresBounds.northeast != exploresBounds.southwest) {
        double? debugThresoldDistance = Storage().debugMapThresholdDistance?.toDouble();
        if (debugThresoldDistance != null) {
          thresoldDistance = debugThresoldDistance;
        }
        else {
          zoom ??= GeoMapUtils.getMapBoundZoom(exploresBounds, math.max(mapSize.width - 2 * _mapPadding, 0), math.max(mapSize.height - 2 * _mapPadding, 0));
          thresoldDistance = _thresoldDistanceForZoom(zoom);
        }
        exploreMarkerGroups = _buildMarkerGroups(explores, thresoldDistance: thresoldDistance);
      }
      else {
        thresoldDistance = 0;
        exploreMarkerGroups = (explores != null) ? Set<dynamic>.from(explores) : null;
      }
      
      if (!DeepCollectionEquality().equals(_exploreMarkerGroups, exploreMarkerGroups)) {
        Future<Set<Marker>> buildMarkersTask = _buildMarkers(context, exploreGroups: exploreMarkerGroups, pinnedExplore: pinnedExplore);
        _buildMarkersTask = buildMarkersTask;
        if (showProgress && mounted) {
          setState(() {
            _markersProgress = true;
          });
        }

        debugPrint('Building Markers for zoom: $zoom thresholdDistance: $thresoldDistance markersSource: ${exploreMarkerGroups?.length}');
        Set<Marker> targetMarkers = await buildMarkersTask;
        debugPrint('Finished Building Markers for zoom: $zoom thresholdDistance: $thresoldDistance => ${targetMarkers.length}');
    
        if (_buildMarkersTask == buildMarkersTask) {
          debugPrint('Applying Building Markers for zoom: $zoom thresholdDistance: $thresoldDistance => ${targetMarkers.length}');
          _targetMarkers = targetMarkers;
          _exploreMarkerGroups = exploreMarkerGroups;
          _targetCameraUpdate = targetCameraUpdate;
          _lastMarkersUpdateZoom = null;
          _buildMarkersTask = null;
          applyStateIfMounted(() {
            _markersProgress = false;
          });
        }
      }
    }
    else {
      _targetMarkers = null;
      _exploreMarkerGroups = null;
      _lastMarkersUpdateZoom = null;
      if (targetCameraUpdate != null) {
        _targetCameraUpdate = targetCameraUpdate;
      }
      if (showProgress && mounted) {
        setState(() {
        });
      }
    }
  }

  static Set<dynamic>? _buildMarkerGroups(List<Explore>? explores, { double thresoldDistance = 0 }) {
    if (explores != null) {
      if (0 < thresoldDistance) {
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
      }
      else {
        // no grouping
        return Set<dynamic>.from(explores);
      }
    }
    return null;
  }

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
      String markerKey = "map-marker-group-${markerColor?.value ?? 0}-${exploreGroup.length}";
      BitmapDescriptor markerIcon = _markerIconCache[markerKey] ??
        (_markerIconCache[markerKey] = await _groupMarkerIcon(
          context: context,
          imageSize: _mapGroupMarkerSize,
          backColor: markerColor,
          borderColor: sameExplore?.mapMarkerBorderColor ?? ExploreMap.unknownMarkerBorderColor,
          textColor: sameExplore?.mapMarkerTextColor ?? ExploreMap.unknownMarkerTextColor,
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
          anchor: markerAnchor)
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
      textStyle: Styles().textStyles?.getTextStyle("widget.text.fat")?.copyWith(
        fontSize: 12 * MediaQuery.of(context).devicePixelRatio,
        color: textColor,
        overflow: TextOverflow.visible //defined in code to be sure it is set
      ),
    );
    if (markerImageBytes != null) {
      return BitmapDescriptor.fromBytes(markerImageBytes);
    }
    else if (backColor != null) {
      return BitmapDescriptor.defaultMarkerWithHue(ColorUtils.hueFromColor(backColor).toDouble());
    }
    else {
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<Marker?> _createExploreMarker(Explore? explore, {required ImageConfiguration imageConfiguration}) async {
    LatLng? markerPosition = explore?.exploreLocation?.exploreLocationMapCoordinate;
    if (markerPosition != null) {
      BitmapDescriptor? markerIcon;
      Offset? markerAnchor;
      if (explore is MTDStop) {
        String markerAsset = 'images/map-marker-mtd-stop.png';
        markerIcon = _markerIconCache[markerAsset] ??
          (_markerIconCache[markerAsset] = await BitmapDescriptor.fromAssetImage(imageConfiguration, markerAsset));
        markerAnchor = Offset(0.5, 0.5);
      }
      else {
        Color? exploreColor = explore?.mapMarkerColor;
        markerIcon = (exploreColor != null) ? BitmapDescriptor.defaultMarkerWithHue(ColorUtils.hueFromColor(exploreColor).toDouble()) : BitmapDescriptor.defaultMarker;
        markerAnchor = Offset(0.5, 1);
      }
      return Marker(
        markerId: MarkerId("${markerPosition.latitude.toStringAsFixed(6)}:${markerPosition.latitude.toStringAsFixed(6)}"),
        position: markerPosition,
        icon: markerIcon,
        anchor: markerAnchor,
        consumeTapEvents: true,
        onTap: () => _onTapMarker(explore),
        infoWindow: InfoWindow(
          title:  explore?.mapMarkerTitle,
          snippet: explore?.mapMarkerSnippet,
          anchor: markerAnchor)
      );
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
          groupExplore.exploreLocation?.longitude?.toDouble() ?? 0);
        if (distance < thresoldDistance) {
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

  Size? get _mapSize => _globalKeySize(_mapContainerKey);
  Size? get _mapExploreBarSize => _globalKeySize(_mapExploreBarKey);

  static Size? _globalKeySize(GlobalKey key) {
    try {
      final RenderObject? renderBox = key.currentContext?.findRenderObject();
      return (renderBox is RenderBox) ? renderBox.size : null;
    }
    on Exception catch (e) {
      print(e.toString());
      return null;
    }
  }

}