
import 'dart:io';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/image_utils.dart';
import 'package:rokwire_plugin/utils/utils.dart';

typedef BuildMarkersTask = Future<Set<Marker>>;
typedef MarkerIconsCache = Map<String, BitmapDescriptor>;

class Map2BasePanelState<T extends StatefulWidget> extends State<T> {

  @protected UniqueKey mapKey = UniqueKey();
  @protected GoogleMapController? mapController;
  @protected CameraPosition? lastCameraPosition;
  @protected CameraUpdate? targetCameraUpdate;
  @protected double? lastMapZoom;

  Set<Marker>? markers;
  Set<dynamic>? exploreMapGroups;
  BuildMarkersTask? buildMarkersTask;
  MarkerIconsCache markerIconsCache = <String, BitmapDescriptor>{};
  bool markersProgress = false;

  LocationServicesStatus? locationServicesStatus;

  // Map Content Static Data
  static const CameraPosition defaultCameraPosition = CameraPosition(target: defaultCameraTarget, zoom: defaultCameraZoom);
  static const LatLng defaultCameraTarget = LatLng(40.102116, -88.227129);
  static const double defaultCameraZoom = 17;
  static const double groupMarkersUpdateThresoldDelta = 0.1;

  // Markers Content Static Data

  static const double _mapExploreMarkerSize = 18;
  static const double _mapGroupMarkerSize = 24;
  static const double _mapPinMarkerSize = 24;
  static const Offset _mapPinMarkerAnchor = Offset(0.5, 1);
  static const Offset _mapCircleMarkerAnchor = Offset(0.5, 0.5);
  
  @override
  void initState() {
    updateLocationServicesStatus(updateCamera: true);
    initAccessibility();
    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
    throw UnimplementedError();

  @protected
  Widget get mapView => Container(decoration: mapViewDecoration, child:
    GoogleMap(
      key: mapKey,
      initialCameraPosition: lastCameraPosition ?? defaultCameraPosition,
      onMapCreated: onMapCreated,
      onCameraIdle: onMapCameraIdle,
      onCameraMove: onMapCameraMove,
      onTap: onTapMap,
      onPoiTap: onTapMapPoi,
      myLocationEnabled: isUserLocationEnabled,
      myLocationButtonEnabled: isUserLocationEnabled,
      mapToolbarEnabled: Storage().debugMapShowLevels == true,
      markers: mapMarkers ?? <Marker>{},
      style: mapStyle,
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

  @protected
  BoxDecoration get mapViewDecoration =>
    BoxDecoration(border: Border.all(color: Styles().colors.surfaceAccent, width: 1));


  @protected
  Set<Marker>? get mapMarkers => markers;

  // Map Data Sources

  @protected String? get mapStyle => null;
  @protected Size? get mapSize => null;
  @protected double get mapPadding => 40;
  @protected double? get mapTopSiblingsHeight => null;
  @protected double? get mapBottomSiblingsHeight => null;

  @protected
  List<Explore>? get mapExplores => null;

  @protected
  bool isExploreGroupMarkerDisabled(Set<Explore> exploreGroup) => false;

  @protected
  bool isExploreMarkerDisabled(Explore explore) => false;

  // Map Events

  @protected
  void onMapCreated(GoogleMapController controller) async {
    // debugPrint('Map2 created' );
    mapController = controller;

    if (targetCameraUpdate != null) {
      if (Platform.isAndroid) {
        Future.delayed(Duration(milliseconds: 100), () {
          applyCameraUpdate();
        });
      }
      else {
        applyCameraUpdate();
      }
    }

    onAccessibilityMapCreated();
  }

  @protected
  void applyCameraUpdate() {
    if (targetCameraUpdate != null) {
      mapController?.moveCamera(targetCameraUpdate!).then((_) {
        targetCameraUpdate = null;
      });
    }
  }

  @protected
  void onMapCameraMove(CameraPosition cameraPosition) {
    // debugPrint('Map2 camera position: lat: ${cameraPosition.target.latitude} lng: ${cameraPosition.target.longitude} zoom: ${cameraPosition.zoom}' );
    lastCameraPosition = cameraPosition;
  }

  @protected
  void onMapCameraIdle() {
    // debugPrint('Map2 camera idle' );
    updateMapContentForZoom();
  }

  @protected
  void onTapMap(LatLng coordinate) {
    // debugPrint('Map2 tap' );
  }

  @protected
  void onTapMapPoi(PointOfInterest poi) {
    // debugPrint('Map2 POI tap' );
  }

  @protected
  void onTapMarker(dynamic origin) {
    // debugPrint('Map2 Marker tap' );
  }

  // Locaction Services

  @protected
  bool get isUserLocationEnabled =>
    FlexUI().isLocationServicesAvailable && (locationServicesStatus == LocationServicesStatus.permissionAllowed);

  @protected
  Future<void> updateLocationServicesStatus({ LocationServicesStatus? status, bool updateCamera = false}) async {
    status ??= FlexUI().isLocationServicesAvailable ? await LocationServices().status : LocationServicesStatus.serviceDisabled;
    if ((status != null) && (status != locationServicesStatus) && mounted) {
      setState(() {
        locationServicesStatus = status;
      });

      await onLocationServicesStatusChanged(updateCamera: updateCamera);
    }
  }

  @protected
  Future<void> onLocationServicesStatusChanged({bool updateCamera = false}) async {
  }

  // Map Content

  @protected
  Future<void> updateMapContentForZoom() async {
    double? mapZoom = await mapController?.getZoomLevel();
    if (mapZoom != null) {
      if (lastMapZoom == null) {
        lastMapZoom = mapZoom;
      }
      else if ((lastMapZoom! - mapZoom).abs() > groupMarkersUpdateThresoldDelta) {
        buildMapContentData(mapExplores, updateCamera: false, showProgress: true, zoom: mapZoom,);
      }
    }
  }

  @protected
  Future<void> buildMapContentData(List<Explore>? explores, { bool updateCamera = false, bool showProgress = false, double? zoom}) async {
    Size? displaySize = mapSize;
    LatLngBounds? exploresRawBounds = explores?.boundsRect;
    LatLngBounds? exploresBounds = (exploresRawBounds != null) ? updateBoundsForSiblings(exploresRawBounds) : null;
    CameraUpdate? cameraUpdate = updateCamera ? cameraUpdateForBounds(exploresBounds) : null;
    if ((exploresBounds != null) && (displaySize != null)) {

      double thresoldDistance;
      Set<dynamic>? exploreGroups;
      if (exploresBounds.northeast != exploresBounds.southwest) {
        double? debugThresoldDistance = Storage().debugMapThresholdDistance?.toDouble();
        if (debugThresoldDistance != null) {
          thresoldDistance = debugThresoldDistance;
        }
        else if (updateCamera) {
          zoom ??= GeoMapUtils.getMapBoundZoom(exploresBounds, math.max(displaySize.width - 2 * mapPadding, 0), math.max(displaySize.height - 2 * mapPadding, 0));
          thresoldDistance = thresoldDistanceForZoom(zoom);
        }
        else {
          zoom ??= await mapController?.getZoomLevel() ?? lastMapZoom ?? defaultCameraZoom;
          thresoldDistance = thresoldDistanceForZoom(zoom);
        }
        exploreGroups = buildExplorMapGroups(explores, thresoldDistance: thresoldDistance);
      }
      else {
        thresoldDistance = 0;
        List<Explore>? validExplores = (explores != null) ? explores.validList : null;
        if ((validExplores != null) && validExplores.isNotEmpty) {
          dynamic groupEntry = (validExplores.length == 1) ? validExplores.first : Set<Explore>.from(validExplores);
          exploreGroups = <dynamic>{ groupEntry };
        }
      }

      if (!DeepCollectionEquality().equals(exploreMapGroups, exploreGroups)) {
        BuildMarkersTask markersTask = buildMarkers(context, exploreGroups: exploreGroups, );
        buildMarkersTask = markersTask;
        if (showProgress && mounted) {
          setStateIfMounted(() {
            markersProgress = true;
          });
        }

        //debugPrint('Building Markers for zoom: $zoom thresholdDistance: $thresoldDistance markersSource: ${exploreGroups?.length}');
        Set<Marker> targetMarkers = await markersTask;
        //debugPrint('Finished Building Markers for zoom: $zoom thresholdDistance: $thresoldDistance => ${targetMarkers.length}');

        if ((buildMarkersTask == markersTask) && mounted) {
          //debugPrint('Applying Building Markers for zoom: $zoom thresholdDistance: $thresoldDistance => ${targetMarkers.length}');
          setStateIfMounted(() {
            markers = targetMarkers;
            exploreMapGroups = exploreGroups;
            targetCameraUpdate = cameraUpdate;
            lastMapZoom = zoom;
            buildMarkersTask = null;
            markersProgress = false;
          });
        }
      }
    }
    else if (mounted) {
      setStateIfMounted(() {
        markers = null;
        exploreMapGroups = null;
        targetCameraUpdate = cameraUpdate;
        buildMarkersTask = null;
        lastMapZoom = null;
        markersProgress = false;
      });
    }
  }

  @protected
  Future<void> updateMapMarkers({ bool showProgress = false }) async {
    BuildMarkersTask markersTask = buildMarkers(context, exploreGroups: exploreMapGroups, );
    buildMarkersTask = markersTask;
    if (showProgress && mounted) {
      setStateIfMounted(() {
        markersProgress = true;
      });
    }

    //debugPrint('Building Markers for zoom: $zoom thresholdDistance: $thresoldDistance markersSource: ${exploreGroups?.length}');
    Set<Marker> targetMarkers = await markersTask;
    //debugPrint('Finished Building Markers for zoom: $zoom thresholdDistance: $thresoldDistance => ${targetMarkers.length}');

    if ((buildMarkersTask == markersTask) && mounted) {
      //debugPrint('Applying Building Markers for zoom: $zoom thresholdDistance: $thresoldDistance => ${targetMarkers.length}');
      setStateIfMounted(() {
        markers = targetMarkers;
        buildMarkersTask = null;
        markersProgress = false;
      });
    }
  }

  static Set<dynamic>? buildExplorMapGroups(Iterable<Explore>? explores, { double thresoldDistance = 0 }) {
    if (explores != null) {
      Map<LatLng, Set<Explore>> exploreGroups = buildInitialExploreGroups(explores, thresoldDistance: thresoldDistance);
      mergeInitialExploreGroups(exploreGroups, thresoldDistance: thresoldDistance);
      Set<dynamic> markerGroups = buildMarkerGroups(exploreGroups);
      return markerGroups;
    }
    else {
      return null;
    }
  }

  /*static List<Explore> sortExploresForMapGroups(Iterable<Explore> explores) {
    List<Explore> orderedExplores = List<Explore>.from(explores);
    Map<LatLng, double> distances = evalExploresDistances(explores);
    orderedExplores.sort((Explore e1, Explore e2) {
      double d1 = distances[e1.exploreLocation?.exploreLocationMapCoordinate] ?? 0;
      double d2 = distances[e2.exploreLocation?.exploreLocationMapCoordinate] ?? 0;
      return d1.compareTo(d2);
    });
    return orderedExplores;
  }

  static Map<LatLng, double> evalExploresDistances(Iterable<Explore> explores, { LatLng startingPoint = const LatLng(0,0) }) {
    Map<LatLng, double> distances = <LatLng, double>{};
    for (Explore explore in explores) {
      LatLng? exploreLatLng = explore.exploreLocation?.exploreLocationMapCoordinate;
      if (exploreLatLng != null) {
        distances[exploreLatLng] = GeoMapUtils.getDistance(
          exploreLatLng.latitude, exploreLatLng.longitude,
          startingPoint.latitude, startingPoint.longitude,
        );
      }
    }
    return distances;
  }*/

  static Map<LatLng, Set<Explore>> buildInitialExploreGroups(Iterable<Explore> explores, { double thresoldDistance = 0 }) {
    Map<LatLng, Set<Explore>> exploreGroups = <LatLng, Set<Explore>>{};

    // List<Explore> orderedExplores = sortExploresForMapGroups(explores);
    for (Explore explore in explores) {
      LatLng? exploreLatLng = explore.exploreLocation?.exploreLocationMapCoordinate;
      if (exploreLatLng != null) {
        LatLng? existingGroupCenter = lookupForInsertInExploreGroup(exploreGroups.keys, exploreLatLng, thresoldDistance: thresoldDistance);
        if (existingGroupCenter != null) {
          Set<Explore> groupExplores = exploreGroups[existingGroupCenter] ?? <Explore>{};
          groupExplores.add(explore);
          LatLng updatedGroupCenter = groupExplores.centerPoint ?? exploreLatLng;
          exploreGroups[updatedGroupCenter] = groupExplores;
          exploreGroups.remove(existingGroupCenter);
        }
        else {
          exploreGroups[exploreLatLng] = <Explore>{explore};
        }
      }
    }
    return exploreGroups;
  }

  static LatLng? lookupForInsertInExploreGroup(Iterable<LatLng> groupCenters, LatLng exploreLatLng, { double thresoldDistance = 0 }) {
    for (LatLng groupCenter in groupCenters) {
      double distanceFromGroupCenter = GeoMapUtils.getDistance(
        exploreLatLng.latitude, exploreLatLng.longitude,
        groupCenter.latitude, groupCenter.longitude,
      );
      if (distanceFromGroupCenter <= thresoldDistance) {
        return groupCenter;
      }
    }
    return null;
  }

  static void mergeInitialExploreGroups(Map<LatLng, Set<Explore>> exploreGroups, { double thresoldDistance = 0 }) {
    Pair<LatLng, LatLng>? nearbyGroups;
    while((nearbyGroups = lookupMergeOfExploreGroups(exploreGroups.keys.toList(), thresoldDistance : thresoldDistance)) != null) {
      Set<Explore>? leftExplores = exploreGroups[nearbyGroups?.left];
      Set<Explore>? rightExplores = exploreGroups[nearbyGroups?.right];
      if ((leftExplores != null) && (rightExplores != null)) {
        Set<Explore> mergedGroupExplores = leftExplores.union(rightExplores);
        LatLng? mergedGroupCenter = mergedGroupExplores.centerPoint;
        if (mergedGroupCenter != null) {
          exploreGroups[mergedGroupCenter] = mergedGroupExplores;
          exploreGroups.remove(nearbyGroups?.left);
          exploreGroups.remove(nearbyGroups?.right);
        }
        else {
          return;
        }
      }
      else {
        return;
      }
    }
  }

  static Pair<LatLng, LatLng>? lookupMergeOfExploreGroups(List<LatLng> groupCenters, { double thresoldDistance = 0 }) {
    double? minDistance;
    Pair<LatLng, LatLng>? minPair;
    for (int index1 = 0; index1 < groupCenters.length; index1++) {
      for (int index2 = index1 + 1; index2 < groupCenters.length; index2++) {
        LatLng groupCenter1 = groupCenters[index1];
        LatLng groupCenter2 = groupCenters[index2];
        double distanceBetweenGroupCenters = GeoMapUtils.getDistance(
          groupCenter1.latitude, groupCenter1.longitude,
          groupCenter2.latitude, groupCenter2.longitude,
        );
        if (distanceBetweenGroupCenters <= thresoldDistance) {
          if ((minDistance == null) || (distanceBetweenGroupCenters < minDistance)) {
            minPair = Pair(groupCenter1, groupCenter2);
            minDistance = distanceBetweenGroupCenters;
          }
        }
      }
    }
    return minPair;
  }

  static Set<dynamic> buildMarkerGroups(Map<LatLng, Set<Explore>> exploreGroups) {
    Set<dynamic> markerGroups = <dynamic>{};
    for (Set<Explore> exploreGroup in exploreGroups.values) {
      if (exploreGroup.length == 1) {
        markerGroups.add(exploreGroup.first);
      }
      else if (exploreGroup.length > 1) {
        markerGroups.add(exploreGroup);
      }
    }
    return markerGroups;
  }

  static double thresoldDistanceForZoom(double zoom) {
    final double targetPixelSize = _mapGroupMarkerSize * 1.5;
    final double metersPerPixel = (math.cos(defaultCameraTarget.latitude * math.pi/180) * 2 * math.pi * 6378137) / (256 * math.pow(2, zoom));
    double thresoldDistance = targetPixelSize * metersPerPixel;
    /* debugPrint("Distance for Zoom: ${zoom.toStringAsFixed(2)} => ${thresoldDistance.toStringAsFixed(2)}");
    static const List<double> thresoldDistanceByZoom = [
  		1000000, 800000, 600000, 200000, 100000, // zoom 0 - 4
  		 100000,  80000,  60000,  20000,  10000, // zoom 5 - 9
  		   5000,   2000,   1000,    500,    250, // zoom 10 - 14
  		    100,     50,      0                  // zoom 15 - 16
    ]; */
    return thresoldDistance;
  }

  @protected
  CameraUpdate cameraUpdateForBounds(LatLngBounds? bounds) {
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

  @protected
  LatLngBounds updateBoundsForSiblings(LatLngBounds bounds) => (bounds.northeast != bounds.southwest) ?
    enlargeBoundsForSiblings(bounds, topPadding: mapPadding, bottomPadding: mapPadding) : bounds;

  @protected
  LatLngBounds enlargeBoundsForSiblings(LatLngBounds bounds, { double? topPadding, double? bottomPadding, }) {
    double northLat = bounds.northeast.latitude;
    double southLat = bounds.southwest.latitude;
    double boundHeight = northLat - southLat;
    double? mapHeight = mapSize?.height;
    if ((southLat < northLat) && (mapHeight != null) && (mapHeight > 0)) {

      double topSiblingsHeight = mapTopSiblingsHeight ?? 0.0;
      if (0 < topSiblingsHeight) {
        northLat += (topSiblingsHeight / mapHeight) * boundHeight;
      }

      double bottomSiblingsHeight = mapBottomSiblingsHeight ?? 0.0;
      if (0 < bottomSiblingsHeight) {
        southLat -= (bottomSiblingsHeight / mapHeight) * boundHeight;
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

  // Map Markers

  @protected
  Future<Set<Marker>> buildMarkers(BuildContext context, { Set<dynamic>? exploreGroups }) async {
    Set<Marker> markers = <Marker>{};
    ImageConfiguration imageConfiguration = createLocalImageConfiguration(context);
    if (exploreGroups != null) {
      for (dynamic entry in exploreGroups) {
        Marker? marker;
        if (entry is Set<Explore>) {
          marker = await createExploreGroupMarker(entry, imageConfiguration: imageConfiguration);
        }
        else if (entry is Explore) {
          marker = await createExploreMarker(entry, imageConfiguration: imageConfiguration);
        }
        if (marker != null) {
          markers.add(marker);
        }
      }
    }

    return markers;
  }

  @protected
  Future<Marker?> createExploreGroupMarker(Set<Explore>? exploreGroup, { required ImageConfiguration imageConfiguration }) async {
    LatLng? markerPosition = exploreGroup?.centerPoint;
    if ((exploreGroup != null) && (markerPosition != null)) {
      Explore? representativeExplore = exploreGroup.groupRepresentative;
      bool exploreDisabled = isExploreGroupMarkerDisabled(exploreGroup);
      Color? markerColor = exploreDisabled ? ExploreMap.disabledMarkerColor : representativeExplore?.mapMarkerColor;
      Color? markerBorderColor = exploreDisabled ? ExploreMap.disabledGroupMarkerBorderColor : (representativeExplore?.mapMarkerBorderColor ?? ExploreMap.defaultMarkerBorderColor);
      Color? markerTextColor = exploreDisabled ? ExploreMap.disabledMarkerTextColor : (representativeExplore?.mapMarkerTextColor ?? ExploreMap.defaultMarkerTextColor);
      String markerKey = "group-${markerColor?.toARGB32() ?? 0}-${exploreGroup.length}";
      return Marker(
        markerId: MarkerId("${markerPosition.latitude.toStringAsFixed(6)}:${markerPosition.latitude.toStringAsFixed(6)}"),
        position: markerPosition,
        icon: markerIconsCache[markerKey] ??= await _markerIcon(context,
          imageSize: _mapGroupMarkerSize,
          backColor: markerColor,
          borderColor: markerBorderColor,
          textColor: markerTextColor,
          text: exploreGroup.length.toString(),
        ),
        anchor: _mapCircleMarkerAnchor,
        consumeTapEvents: true,
        onTap: () => onTapMarker(exploreGroup),
        infoWindow: InfoWindow(
          title:  representativeExplore?.getMapGroupMarkerTitle(exploreGroup.length),
          anchor: _mapCircleMarkerAnchor
        )
      );
    }
    return null;
  }

  @protected
  Future<Marker?> createExploreMarker(Explore? explore, { required ImageConfiguration imageConfiguration }) async {
    LatLng? markerPosition = explore?.exploreLocation?.exploreLocationMapCoordinate;
    if ((explore != null) && (markerPosition != null)) {
      BitmapDescriptor? markerIcon;
      Offset? markerAnchor;
      if (explore is MTDStop) {
        markerIcon = markerIconsCache['mtd'] ??= await BitmapDescriptor.asset(imageConfiguration, 'images/map-marker-mtd-stop.png');
        markerAnchor = _mapCircleMarkerAnchor;
      }
      else {
        bool exploreDisabled = isExploreMarkerDisabled(explore);
        Color? exploreColor = exploreDisabled ? ExploreMap.disabledMarkerColor : explore.mapMarkerColor;
        Color? borderColor = exploreDisabled ? ExploreMap.disabledExploreMarkerBorderColor : (explore.mapMarkerBorderColor ?? ExploreMap.defaultMarkerBorderColor);
        String markerKey = "explore-${exploreColor?.toARGB32() ?? 0}";
        markerIcon = markerIconsCache[markerKey] ??= await _markerIcon(context,
          imageSize: _mapExploreMarkerSize,
          backColor: Styles().colors.white,
          backColor2: exploreColor,
          backColor2Offset: 8,
          borderColor: borderColor,
          borderWidth: 1,
          borderOffset: 0,
        );
        markerAnchor = _mapPinMarkerAnchor;
      }
      return Marker(
        markerId: MarkerId("${markerPosition.latitude.toStringAsFixed(6)}:${markerPosition.longitude.toStringAsFixed(6)}"),
        position: markerPosition,
        icon: markerIcon,
        anchor: markerAnchor,
        consumeTapEvents: true,
        onTap: () => onTapMarker(explore),
        infoWindow: InfoWindow(
          title: explore.mapMarkerTitle,
          snippet: explore.mapMarkerSnippet,
          anchor: markerAnchor)
      );
    }
    return null;
  }

  @protected
  Future<Marker?> createPinMarker(Explore? explore, { required ImageConfiguration imageConfiguration }) async {
    LatLng? markerPosition = explore?.exploreLocation?.exploreLocationMapCoordinate;
    Offset markerAnchor = ((explore is ExplorePOI) && (explore.placeId?.isNotEmpty == true)) ? _mapPinMarkerAnchor : _mapCircleMarkerAnchor;
    return (markerPosition != null) ? Marker(
      markerId: MarkerId("${markerPosition.latitude.toStringAsFixed(6)}:${markerPosition.longitude.toStringAsFixed(6)}"),
      position: markerPosition,
      icon: markerIconsCache['pin'] ??= await _markerIcon(context,
          imageSize: _mapPinMarkerSize,
          backColor: Styles().colors.accentColor3,
          backColor2: Styles().colors.mtdColor,
          borderColor: Styles().colors.white,
          borderWidth: 2,
          borderOffset: 3,
          backColor2Offset: 5,
        ),
      anchor: markerAnchor,
      consumeTapEvents: true,
      onTap: () => onTapMarker(explore),
      infoWindow: InfoWindow(
        title: explore?.mapMarkerTitle,
        snippet: explore?.mapMarkerSnippet,
        anchor: markerAnchor)
    ) : null;
  }

  static Future<BitmapDescriptor> _markerIcon(BuildContext context, {required double imageSize,
      Color? backColor,
      Color? backColor2, double backColor2Offset = 1,
      Color? borderColor, double borderWidth = 1, double borderOffset = 0,
      Color? textColor, String? text
  }) async {
    Uint8List? markerImageBytes = await ImageUtils.mapMarkerImage(
      imageSize: imageSize * MediaQuery.of(context).devicePixelRatio,
      backColor: backColor,
      backColor2: backColor2,
      backColor2Offset: backColor2Offset,
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
}

extension _Map2Accessibility on Map2BasePanelState{
  void initAccessibility(){
    // Hybrid Composition mode (AndroidViewSurface) instead of the default Virtual Display.
    // This is known to improve gesture and accessibility handling.
    if (Platform.isAndroid) {
      GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
      if (mapsImplementation is GoogleMapsFlutterAndroid) {
        mapsImplementation.useAndroidViewSurface = true;
        //Setting that will reduce the need of the workaround (refreshAccessibility) Deprecated in version 2.7.0
        // mapsImplementation.forceAccessibilityEnabled = true;
      }
    }
  }

  void onAccessibilityMapCreated() =>
      //Setting that will reduce the need of the workaround (refreshAccessibility) Deprecated in version 2.7.0
      // mapsImplementation.forceAccessibilityEnabled = true;
      AppSemantics.isAccessibilityEnabled(context) ?
        AppSemantics.triggerAccessibilityHardResetWorkaround(context) :
        null;
}