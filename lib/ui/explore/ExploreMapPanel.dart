
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/MTD.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/Location.dart' as Native;
import 'package:illinois/model/MTD.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/model/Appointment.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Appointments.dart';
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
import 'package:illinois/ui/RootPanel.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2HomePanel.dart';
import 'package:illinois/ui/events2/Event2SearchPanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/explore/ExploreBuildingsSearchPanel.dart';
import 'package:illinois/ui/explore/ExploreListPanel.dart';
import 'package:illinois/ui/dining/DiningHomePanel.dart';
import 'package:illinois/ui/mtd/MTDStopSearchPanel.dart';
import 'package:illinois/ui/mtd/MTDStopsHomePanel.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/Filters.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/explore/ExploreStoriedSightsBottomSheet.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
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
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/image_utils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:timezone/timezone.dart';
import 'package:rokwire_plugin/model/places.dart' as places_model;

enum ExploreMapType { Events2, Dining, Laundry, Buildings, StudentCourse, Appointments, MTDStops, MyLocations, MentalHealth, StoriedSites }

enum EventsDisplayType { single, multiple, all }
enum ExploreFilterType { categories, event_time, event_tags, payment_type, work_time, student_course_terms }

class ExploreMapPanel extends StatefulWidget with AnalyticsInfo {

  static const String notifySelect = "edu.illinois.rokwire.explore.map.select";
  static const String selectParamKey = "select-param";

  static const ExploreMapType _defaultMapType = ExploreMapType.Buildings;

  final Map<String, dynamic> params = <String, dynamic>{};

  ExploreMapPanel({super.key});
  
  @override
  State<StatefulWidget> createState() => _ExploreMapPanelState();

  AnalyticsFeature? get analyticsFeature => _state?._selectedMapType?.analyticsFeature ??
    _selectedExploreType(exploreTypes: _buildExploreTypes())?.analyticsFeature ??
    AnalyticsFeature.Map;

  ExploreMapType? _selectedExploreType({ List<ExploreMapType>? exploreTypes }) =>
    _targetExploreType?._ensure(availableTypes: exploreTypes) ??
    Storage()._selectedMapExploreType?._ensure(availableTypes: exploreTypes) ??
    _defaultMapType._ensure(availableTypes: exploreTypes) ??
    ((exploreTypes?.isNotEmpty == true) ? exploreTypes?.first : null);

  ExploreMapType? get _targetExploreType => _exploreTypeFromParam(params[selectParamKey]);

  // Explore Types

  List<ExploreMapType> _buildExploreTypes() {
    List<ExploreMapType> exploreTypes = <ExploreMapType>[];
    List<dynamic>? codes = FlexUI()['explore.map'];
    if (codes != null) {
      for (dynamic code in codes) {
        ExploreMapType? codeType = ExploreMapTypeImpl.fromCode(code);
        if (codeType != null) {
          exploreTypes.add(codeType);
        }
      }
    }
    exploreTypes.sortAlphabetical();
    return exploreTypes;
  }

  // _ExploreMapPanelState access

  static bool get hasState => _state != null;

  static _ExploreMapPanelState? get _state {
    Set<NotificationsListener>? subscribers = NotificationService().subscribers(notifySelect);
    if (subscribers != null) {
      for (NotificationsListener subscriber in subscribers) {
        if ((subscriber is _ExploreMapPanelState) && subscriber.mounted) {
          return subscriber;
        }
      }
    }
    return null;
  }

  // static _ExploreMapPanel param

  static ExploreMapType? _exploreTypeFromParam(dynamic param) {
    if (param is ExploreMapType) {
      return param;
    }
    else if (param is ExploreMapSearchEventsParam) {
      return ExploreMapType.Events2;
    }
    else if (param is ExploreMapSearchMTDStopsParam) {
      return ExploreMapType.MTDStops;
    }
    else {
      return null;
    }
  }

}

class _ExploreMapPanelState extends State<ExploreMapPanel>
  with NotificationsListener, SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin<ExploreMapPanel> {

  static const double _filterLayoutSortKey = 1.0;
  static const String _privacyUrl = 'privacy://level';
  static const String _privacyUrlMacro = '{{privacy_url}}';

  late List<ExploreMapType> _exploreTypes;
  ExploreMapType? _selectedMapType;
  EventsDisplayType? _selectedEventsDisplayType;

  late Event2TimeFilter _event2TimeFilter;
  TZDateTime? _event2CustomStartTime;
  TZDateTime? _event2CustomEndTime;
  late LinkedHashSet<Event2TypeFilter> _event2Types;
  late Map<String, dynamic> _event2Attributes;
  String? _event2SearchText;

  MTDStopsScope? _mtdStopScope;
  String? _mtdStopSearchText;

  List<StudentCourseTerm>? _studentCourseTerms;
  
  List<String>? _filterWorkTimeValues;
  List<String>? _filterPaymentTypeValues;
  List<String>? _filterEventTimeValues;
  
  Map<ExploreMapType, List<ExploreFilter>>? _itemToFilterMap;
  
  bool _itemsDropDownValuesVisible = false;
  bool _eventsDisplayDropDownValuesVisible = false;
  bool _filtersDropdownVisible = false;
  
  List<Explore>? _explores;
  List<Explore>? _filteredExplores;
  bool _exploreProgress = false;
  Future<List<Explore>?>? _exploreTask;

  final GlobalKey _mapContainerKey = GlobalKey();
  final GlobalKey _mapExploreBarKey = GlobalKey();
  final GlobalKey<ExploreStoriedSightsBottomSheetState> _storiedSightsKey = GlobalKey<ExploreStoriedSightsBottomSheetState>();
  final String _mapStylesAssetName = 'assets/map.styles.json';
  final String _mapStylesExplorePoiKey = 'explore-poi';
  final String _mapStylesMtdStopKey = 'mtd-stop';
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
  Set<dynamic>? _exploreMarkerGroups;
  Set<Marker>? _targetMarkers;
  bool _markersProgress = false;
  Future<Set<Marker>?>? _buildMarkersTask;
  Explore? _pinnedMapExplore;
  dynamic _selectedMapExplore;
  Explore? _selectedStoriedSiteExplore;
  AnimationController? _mapExploreBarAnimationController;
  GestureRecognizer? _clearMTDStopsSearchRecognizer;
  GestureRecognizer? _clearMTDStopsScopeRecognizer;

  String? _loadingMapStopIdRoutes;
  List<MTDRoute>? _selectedMapStopRoutes;

  LocationServicesStatus? _locationServicesStatus;
  Position? _currentLocation;
  Map<String, dynamic>? _mapStyles;
  DateTime? _pausedDateTime;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Connectivity.notifyStatusChanged,
      LocationServices.notifyStatusChanged,
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged,
      StudentCourses.notifyTermsChanged,
      StudentCourses.notifySelectedTermChanged,
      StudentCourses.notifyCachedCoursesChanged,
      MTD.notifyStopsChanged,
      Appointments.notifyUpcomingAppointmentsChanged,
      ExploreMapPanel.notifySelect,
      RootPanel.notifyTabChanged,
      Storage.notifySettingChanged,
      Event2FilterParam.notifyChanged,
    ]);
    
    _exploreTypes = widget._buildExploreTypes();
    _selectedMapType = widget._selectedExploreType(exploreTypes: _exploreTypes);
    _selectedEventsDisplayType = EventsDisplayType.single;
    
    _event2TimeFilter = Event2TimeFilterImpl.fromJson(Storage().events2Time) ?? Event2TimeFilter.upcoming;
    _event2CustomStartTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomStartTime));
    _event2CustomEndTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomEndTime));
    _event2Types = LinkedHashSetUtils.from<Event2TypeFilter>(Event2TypeFilterListImpl.listFromJson(Storage().events2Types)) ?? LinkedHashSet<Event2TypeFilter>();
    _event2Attributes = Storage().events2Attributes ?? <String, dynamic>{};
    _event2SearchText = _initialEvent2SearchParam?.searchText;

    _mtdStopSearchText = _initialMTDStopsSearchParam?.searchText;
    _mtdStopScope = _initialMTDStopsSearchParam?.scope;

    _initFilters();
    _initMapStyles();
    _initLocationServicesStatus().then((_) {
      _initExplores();
    });

    _mapExploreBarAnimationController = AnimationController (duration: Duration(milliseconds: 200), lowerBound: 0, upperBound: 1, vsync: this)
      ..addListener(() {
        setStateIfMounted(() {
        });
      });

    // https://stackoverflow.com/a/78750681/3759472
    _clearMTDStopsSearchRecognizer = TapGestureRecognizer()..onTap = _onMTDStopsClearSearch;
    _clearMTDStopsScopeRecognizer = TapGestureRecognizer()..onTap = _onMTDStopsClearScope;

    super.initState();
  }

  @override
  void dispose() {
     NotificationService().unsubscribe(this);
    _mapExploreBarAnimationController?.dispose();
     _clearMTDStopsSearchRecognizer?.dispose();
     _clearMTDStopsScopeRecognizer?.dispose();
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
        _onConnectionOnline();
      }
    }
    else if (name == LocationServices.notifyStatusChanged) {
      _initLocationServicesStatus(status: param);
    }
    else if (name == Auth2UserPrefs.notifyPrivacyLevelChanged) {
      _initLocationServicesStatus();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _onFavoritesChanged();
    }
    else if (name == FlexUI.notifyChanged) {
      _currentLocation = null;
      _updateExploreTypes();
    }
    else if (name == StudentCourses.notifyTermsChanged) {
      applyStateIfMounted(() {
        _studentCourseTerms = StudentCourses().terms;
      });
      if ((_selectedMapType == ExploreMapType.StudentCourse) && (_exploreTask == null) && mounted) {
        _refreshExplores();
      }
    }
    else if (name == StudentCourses.notifySelectedTermChanged) {
      applyStateIfMounted(() {
        _updateSelectedTermId();
      });
      if ((_selectedMapType == ExploreMapType.StudentCourse)  && (_exploreTask == null) && mounted) {
        _refreshExplores();
      }
    }
    else if (name == StudentCourses.notifyCachedCoursesChanged) {
      String? termId = param;
      if ((_selectedMapType == ExploreMapType.StudentCourse) && (_exploreTask == null) && mounted && ((termId == null) || (StudentCourses().displayTermId == termId))) {
        _refreshExplores();
      }
    }
    else if (name == MTD.notifyStopsChanged) {
      if ((_selectedMapType == ExploreMapType.MTDStops) && (_exploreTask == null) && mounted) {
        _refreshExplores();
      }
    }
    else if (name == Appointments.notifyUpcomingAppointmentsChanged) {
      if ((_selectedMapType == ExploreMapType.Appointments) && (_exploreTask == null) && mounted) {
        _refreshExplores();
      }
    }
    else if (name == ExploreMapPanel.notifySelect) {
      if (mounted) {
        if ((param is ExploreMapType) && (_selectedMapType != param)) {
          setState(() {
            Storage()._selectedMapExploreType = _selectedMapType = param;
          });
          _initExplores();
        }
        else if (param is ExploreMapSearchEventsParam) {
          if ((_selectedMapType != ExploreMapType.Events2) || (_event2SearchText != param.searchText)) {
            setState(() {
              Storage()._selectedMapExploreType = _selectedMapType = ExploreMapType.Events2;
              _event2SearchText = param.searchText;
            });
            _initExplores();
          }
        }
        else if (param is ExploreMapSearchMTDStopsParam) {
          if ((_selectedMapType != ExploreMapType.MTDStops) || (_mtdStopSearchText != param.searchText) || (_mtdStopScope != param.scope)) {
            setState(() {
              Storage()._selectedMapExploreType = _selectedMapType = ExploreMapType.MTDStops;
              _mtdStopSearchText = param.searchText;
              _mtdStopScope = param.scope;
            });
            _initExplores();
          }
        }
      }
    }
    else if (name == RootPanel.notifyTabChanged) {
      if ((param == RootTab.Maps) && (_exploreTask == null) && mounted &&
          (CollectionUtils.isEmpty(_exploreTypes) || CollectionUtils.isEmpty(_explores) || (_selectedMapType == ExploreMapType.Events2) || (_selectedMapType == ExploreMapType.Appointments)) // Do not refresh for other ExploreMapType types as they are rarely changed or fire notification for that
      ) {
        _refreshExplores();
      }
    }
    else if (name == Storage.notifySettingChanged) {
      if (param == Storage.debugMapThresholdDistanceKey) {
        _buildMapContentData(_filteredExplores ?? _explores, pinnedExplore: _pinnedMapExplore, updateCamera: false, zoom: _lastMarkersUpdateZoom, showProgress: true);
      }
      else if (param == Storage.debugMapShowLevelsKey) {
        setStateIfMounted(() { });
      }
    }
    else if (name == Event2FilterParam.notifyChanged) {
      _updateEvent2Filers();
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
            _initLocationServicesStatus().then((_) {
              _refreshExplores();
            });
          }
        }
      }
    }
  }

  void _onConnectionOnline() async {
      if (_locationServicesStatus == null) {
        await _initLocationServicesStatus();
      }
      if ((_explores == null) && (_exploreTask == null)) {
        _initExplores();
      }
  }

  // AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx("panel.maps.header.title", "Map")),
      body: RefreshIndicator(onRefresh: _onRefresh, child: _buildScaffoldBody(),),
      backgroundColor: Styles().colors.background,
    );
  }

  Widget _buildScaffoldBody() {
    return Column(children: <Widget>[
      Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 0), child:
        _buildExploreTypesDropDownButton(),
      ),
      Expanded(child:
        Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            if (_selectedMapType == ExploreMapType.Events2)
              Padding(padding: EdgeInsets.only(top: 8, bottom: 2), child:
                _buildEvents2HeaderBar(),
              ),
            if (_selectedMapType == ExploreMapType.Buildings)
              Padding(padding: EdgeInsets.only(top: 8, bottom: 2), child:
                _buildBuildingsHeaderBar(),
              ),
            if (_selectedMapType == ExploreMapType.MTDStops)
              _buildMTDStopsHeaderBar(),
            Expanded(child:
              Stack(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildFiltersBar(),
                  Expanded(child:
                    Container(key: _mapContainerKey, color: Styles().colors.background, child:
                      _buildContent(),
                    ),
                  ),
                ]),
                _buildEventsDisplayTypesDropDownContainer(),
                _buildFilterValuesContainer()
              ]),
            ),
          ]),
          if (_selectedMapType == ExploreMapType.StoriedSites && _exploreTask == null && _explores != null)
            ExploreStoriedSightsBottomSheet(
              key: _storiedSightsKey,
              places: _explores?.whereType<Place>().toList() ?? [],
              onPlaceSelected: _onStoriedSitesPlaceSelected,
              onFilteredPlacesChanged: _onStoriedSitesFilteredPlacesChanged,
              onBackPressed: _onStoriedSitesBackPressed,
            ),
          _buildExploreTypesDropDownContainer(),
        ]),
      )
    ]);
  }

  // Map Widget

  Widget _buildContent() {
    if (_exploreProgress) {
      return _buildLoadingContent();
    }
    /*else if (Connectivity().isOffline) {
      return _buildMessageContent(_offlineContentMessage ?? '');
    }
    else if (_explores == null) {
      return _buildMessageContent(_selectedMapType?._displayFailedContentMessage ?? '');
    }
    else if (_explores!.isEmpty) {
      return _buildMessageContent(_selectedMapType?._emptyContentMessage ?? '');
    }*/
    else {
      return _buildMapContent();
    }
  }

  Widget _buildMapContent() {
    return Stack(children: [
      _buildMapView(),
      if (_selectedMapType != ExploreMapType.StoriedSites)
        _buildMapExploreBar(),
      Visibility(visible: _markersProgress, child:
        Positioned.fill(child:
          Center(child:
            SizedBox(width: 24, height: 24, child:
              CircularProgressIndicator(color: Styles().colors.accentColor2, strokeWidth: 3,),
            )
          )
        )
      )
    ],);
  }

  Widget _buildMapView() {
    return Container(decoration: BoxDecoration(border: Border.all(color: Styles().colors.disabledTextColor, width: 1)), child:
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
  }

  void _onMapCreated(GoogleMapController controller) async {
    debugPrint('ExploreMap created' );
    _mapController = controller;

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
        _buildMapContentData(_filteredExplores ?? _explores, pinnedExplore: _pinnedMapExplore, updateCamera: false, zoom: value, showProgress: true);
      }
    });
  }

  void _onMapTap(LatLng coordinate) {
    debugPrint('ExploreMap tap' );
    MTDStop? mtdStop;
    if ((mtdStop = MTD().stops?.findStop(location: Native.LatLng(latitude: coordinate.latitude, longitude: coordinate.longitude), locationThresholdDistance: 25 /*in meters*/)) != null) {
      _selectMapExplore(mtdStop);
    }
    else if (_selectedMapExplore != null) {
      _selectMapExplore(null);
    }
    else if (_selectedMapType == ExploreMapType.MyLocations) {
      _selectMapExplore(ExplorePOI(location: ExploreLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)));
    }
  }

  void _onMapPoiTap(PointOfInterest poi) {
    debugPrint('ExploreMap POI tap' );
    MTDStop? mtdStop = MTD().stops?.findStop(location: Native.LatLng(latitude: poi.position.latitude, longitude: poi.position.longitude), locationThresholdDistance: 25 /*in meters*/);
    if (mtdStop != null) {
      _selectMapExplore(mtdStop);
    }
    else if (_selectedMapType == ExploreMapType.MyLocations) {
      _selectMapExplore(ExplorePOI(placeId: poi.placeId, name: poi.name, location: ExploreLocation(latitude: poi.position.latitude, longitude: poi.position.longitude)));
    }
    else if (_selectedMapExplore != null) {
      _selectMapExplore(null);
    }
  }

  void _onTapMarker(dynamic origin) {
    if (_selectedMapType == ExploreMapType.StoriedSites) {
      _selectStoriedSiteExplore(origin);
    }
    else {
      _selectMapExplore(origin);
    }
  }

  void _onStoriedSitesPlaceSelected(places_model.Place place) {
    _centerMapOnExplore(place, zoom: false);
    _selectMapExplore(place);
  }

  void _onStoriedSitesFilteredPlacesChanged(List<places_model.Place>? filteredExplores) {
    if (!DeepCollectionEquality().equals(_filteredExplores, filteredExplores)) {
      _mapController?.getZoomLevel().then((double value) {
        _filteredExplores = (filteredExplores != null) ? List.from(filteredExplores) : null;
        _buildMapContentData(_filteredExplores ?? _explores, pinnedExplore: _pinnedMapExplore, updateCamera: false, showProgress: true, zoom: value);
      });
    }
  }

  void _onStoriedSitesBackPressed() {
    _selectStoriedSiteExplore(null);
  }

  void _selectStoriedSiteExplore(dynamic explore) {
    if (explore is Place) {
      _storiedSightsKey.currentState?.selectPlace(explore);
    }
    else if (explore is List<Explore>) {
      List<places_model.Place> places = explore.cast<places_model.Place>();
      _storiedSightsKey.currentState?.selectPlaces(places);
      _centerMapOnExplore(places);
    }

    _updateSelectedStoriedSiteMarker(explore is Explore ? explore : null);

    _logAnalyticsSelect(explore);
  }

  Future<void> _updateSelectedStoriedSiteMarker(Explore? selectedStoriedSiteExplore) async {
    Set<Marker>? targetMarkers = (_targetMarkers != null) ? Set<Marker>.from(_targetMarkers!) : null;
    if ((targetMarkers != null) && (_selectedStoriedSiteExplore != selectedStoriedSiteExplore)) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context);

      if (_selectedStoriedSiteExplore != null) {
        Marker? selectedStoriedSiteMarker = targetMarkers.exploreMarker(_selectedStoriedSiteExplore);
        Marker? selectedStoriedSiteMarkerUpd = await _createExploreMarker(_selectedStoriedSiteExplore, imageConfiguration: imageConfiguration);
        if ((selectedStoriedSiteMarker != null) && (selectedStoriedSiteMarkerUpd != null)) {
          targetMarkers.remove(selectedStoriedSiteMarker);
          targetMarkers.add(selectedStoriedSiteMarkerUpd);
        }
      }

      _selectedStoriedSiteExplore = selectedStoriedSiteExplore;

      if (_selectedStoriedSiteExplore != null) {
        Marker? selectedStoriedSiteMarker = targetMarkers.exploreMarker(_selectedStoriedSiteExplore);
        Marker? selectedStoriedSiteMarkerUpd = await _createExploreMarker(_selectedStoriedSiteExplore, imageConfiguration: imageConfiguration, markerColor: Styles().colors.fillColorSecondary);
        if ((selectedStoriedSiteMarker != null) && (selectedStoriedSiteMarkerUpd != null)) {
          targetMarkers.remove(selectedStoriedSiteMarker);
          targetMarkers.add(selectedStoriedSiteMarkerUpd);
        }
      }
    }

    if (!DeepCollectionEquality().equals(_targetMarkers, targetMarkers)) {
      setStateIfMounted((){
        _targetMarkers = targetMarkers;
      });
    }
  }

  void _centerMapOnExplore(dynamic explore, {bool zoom = true}) async {
    LatLng? targetPosition;

    if (explore is Explore) {
      targetPosition = explore.exploreLocation?.exploreLocationMapCoordinate;
    } else if (explore is List<Explore> && explore.isNotEmpty) {
      targetPosition = ExploreMap.centerOfList(explore);
    }

    if (targetPosition != null && _mapController != null) {
      double currentZoom = await _mapController!.getZoomLevel();
      double targetZoom = currentZoom;

      if (zoom) {
        targetZoom += 1;
        if (targetZoom > 20) {
          targetZoom = 20;
        }
      }

      CameraUpdate cameraUpdate = zoom
          ? CameraUpdate.newLatLngZoom(targetPosition, targetZoom)
          : CameraUpdate.newLatLng(targetPosition); // Center without zoom

      await _mapController!.moveCamera(cameraUpdate);

      double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      double offset = 450 / devicePixelRatio;

      await _mapController!.moveCamera(CameraUpdate.scrollBy(0, offset));
    }
  }

  // Map Explore Bar

  Widget _buildMapExploreBar() {
    String? title, description;
    String detailsLabel = Localization().getStringEx('panel.explore.button.details.title', 'Details');
    String detailsHint = Localization().getStringEx('panel.explore.button.details.hint', '');
    Color? exploreColor;
    Widget? descriptionWidget;
    bool canDirections = true, canDetail = true;
    void Function() onTapDetail = _onTapMapExploreDetail;

    if (_selectedMapExplore is Explore) {
      title = (_selectedMapExplore as Explore).mapMarkerTitle;
      description = (_selectedMapExplore as Explore).mapMarkerSnippet;
      exploreColor = (_selectedMapExplore as Explore).uiColor ?? Styles().colors.white;
      if (_selectedMapExplore is MTDStop) {
        detailsLabel = Localization().getStringEx('panel.explore.button.bus_schedule.title', 'Bus Schedule');
        detailsHint = Localization().getStringEx('panel.explore.button.bus_schedule.hint', '');
        descriptionWidget = _buildExploreBarStopDescription();
      }
      else if (_selectedMapExplore is ExplorePOI) {
        title = title?.replaceAll('\n', ' ');
        detailsLabel = Localization().getStringEx('panel.explore.button.clear.title', 'Clear');
        detailsHint = Localization().getStringEx('panel.explore.button.clear.hint', '');
        onTapDetail = _onTapMapClear;
      }
    }
    else if  (_selectedMapExplore is List<Explore>) {
      String? exploreName = ExploreExt.getExploresListDisplayTitle(_selectedMapExplore);
      title = sprintf(Localization().getStringEx('panel.explore.map.popup.title.format', '%d %s'), [_selectedMapExplore?.length, exploreName]);
      Explore? explore = _selectedMapExplore.isNotEmpty ? _selectedMapExplore.first : null;
      description = explore?.exploreLocation?.description ?? "";
      exploreColor = explore?.uiColor ?? Styles().colors.fillColorSecondary;
    }
    else {
      exploreColor = Styles().colors.white;
      canDirections = canDetail = false;
    }

    double buttonWidth = (MediaQuery.of(context).size.width - (40 + 12)) / 2;

    double barHeight = _mapExploreBarSize?.height ?? 0;
    double wrapHeight = _mapSize?.height ?? 0;
    double progress = _mapExploreBarAnimationController?.value ?? 0;
    double top = wrapHeight - (progress * barHeight);

    return Positioned(top: top, left: 0, right: 0, child:
      Container(key: _mapExploreBarKey, decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: exploreColor, width: 2, style: BorderStyle.solid), bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1, style: BorderStyle.solid),),), child:
        Stack(children: [
          Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Padding(padding: EdgeInsets.only(right: 10), child:
                Text(title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: Styles().textStyles.getTextStyle("widget.title.large.extra_fat")),
              ),
              (descriptionWidget != null) ?
                Row(children: <Widget>[
                  Text(description ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: Styles().textStyles.getTextStyle("panel.event_schedule.map.description")),
                  descriptionWidget
                ]) :
                Text(description ?? "", overflow: TextOverflow.ellipsis, style: Styles().textStyles.getTextStyle("panel.event_schedule.map.description")),
              Container(height: 8,),
              Row(children: <Widget>[
                SizedBox(width: buttonWidth, child:
                  RoundedButton(
                    label: Localization().getStringEx('panel.explore.button.directions.title', 'Directions'),
                    hint: Localization().getStringEx('panel.explore.button.directions.hint', ''),
                    textStyle: canDirections ? Styles().textStyles.getTextStyle("widget.button.title.enabled") : Styles().textStyles.getTextStyle("widget.button.title.disabled"),
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    borderColor: canDirections ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
                    onTap: _onTapMapExploreDirections
                  ),
                ),
                Container(width: 12,),
                SizedBox(width: buttonWidth, child:
                  RoundedButton(
                    label: detailsLabel,
                    hint: detailsHint,
                    textStyle: canDirections ? Styles().textStyles.getTextStyle("widget.button.title.enabled") : Styles().textStyles.getTextStyle("widget.button.title.disabled"),
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    borderColor: canDetail ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
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
    );
  }

  void _onTapMapExploreDirections() async {
    Analytics().logSelect(
      target: 'Directions',
      feature: ExploreExt.getExploreAnalyticsFeature(_selectedMapExplore),
    );
    
    dynamic explore = _selectedMapExplore;
    _selectMapExplore(null);
    Future<bool>? launchTask;
    if (explore is Explore) {
      launchTask = explore.launchDirections();
    }
    else if (explore is List<Explore>) {
      launchTask = GeoMapUtils.launchDirections(destination: ExploreMap.centerOfList(explore), travelMode: GeoMapUtils.traveModeWalking);
    }

    if ((launchTask != null) && !await launchTask) {
      AppAlert.showTextMessage(context, Localization().getStringEx("panel.explore.directions.failed.msg", "Failed to launch navigation directions."));
    }
    
    // AppAlert.showMessage(context, Localization().getStringEx("panel.explore.directions.na.msg", "You need to enable location services in order to get navigation directions."));
  }
  
  void _onTapMapExploreDetail() {
    Analytics().logSelect(
      target: (_selectedMapExplore is MTDStop) ? 'Bus Schedule' : 'Details',
      feature: ExploreExt.getExploreAnalyticsFeature(_selectedMapExplore),
    );
    if (_selectedMapExplore is Explore) {
        (_selectedMapExplore as Explore).exploreLaunchDetail(context, analyticsFeature: widget.analyticsFeature);
    }
    else if (_selectedMapExplore is List<Explore>) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreListPanel(explores: _selectedMapExplore, exploreMapType: _selectedMapType, analyticsFeature: widget.analyticsFeature,),));
    }
    _selectMapExplore(null);
  }

  void _onTapMapClear() {
    Analytics().logSelect(
      target: 'Clear',
      feature: ExploreExt.getExploreAnalyticsFeature(_selectedMapExplore),
    );
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
      _updateSelectedMapStopRoutes();
      _mapExploreBarAnimationController?.forward();
    }
    else if (_selectedMapExplore != null) {
      _pinMapExplore(null);
      _mapExploreBarAnimationController?.reverse().then((_) {
        setStateIfMounted(() {
          _selectedMapExplore = null;
        });
        _updateSelectedMapStopRoutes();
      });
    }
    else {
      _pinMapExplore(null);
    }

    _logAnalyticsSelect(explore);
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

  void _logAnalyticsSelect(dynamic explore) {
    String? exploreTarget;
    AnalyticsFeature? exploreFeature;
    if (explore is Explore) {
      exploreTarget = explore.exploreTitle ?? explore.exploreLocation?.name ?? explore.exploreLocation?.displayAddress ?? explore.exploreLocation?.displayCoordinates;
      exploreFeature = explore.analyticsFeature;
    }
    else if (explore is List<Explore>) {
      exploreTarget = '${explore.length} ${ExploreExt.getExploresListDisplayTitle(explore, language: 'en')}';
      exploreFeature = ExploreExt.getExploresListAnalyticsFeature(explore);
    }
    Analytics().logMapSelect(
      target: exploreTarget,
      feature: exploreFeature,
    );
  }

  Widget? _buildExploreBarStopDescription() {
    if (_loadingMapStopIdRoutes != null) {
      return Padding(padding: EdgeInsets.only(left: 8, top: 3, bottom: 2), child:
        SizedBox(width: 16, height: 16, child:
          CircularProgressIndicator(color: Styles().colors.mtdColor, strokeWidth: 2,),
        ),
      );
    }
    else {
      List<Widget> routeWidgets = <Widget>[];
      if (_selectedMapStopRoutes != null) {
        for (MTDRoute route in _selectedMapStopRoutes!) {
          routeWidgets.add(
            Padding(padding: EdgeInsets.only(left: routeWidgets.isNotEmpty ? 6 : 0), child:
              Container(decoration: BoxDecoration(color: route.color, border: Border.all(color: route.textColor ?? Colors.transparent, width: 1), borderRadius: BorderRadius.circular(5)), child:
                Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), child:
                  Text(route.shortName ?? '', overflow: TextOverflow.ellipsis, style: Styles().textStyles.getTextStyle("widget.item.tiny.extra_fat")?.copyWith(color: route.textColor)),
                )
              )
            )
          );
        }
      }
      if (routeWidgets.isNotEmpty) {
        return Padding(padding: EdgeInsets.only(left: 8), child:
          SingleChildScrollView(scrollDirection: Axis.horizontal, child:
            Row(children: routeWidgets,)
          ),
        );
      }
      else {
        return Container(height: 21);
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
          CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
        ),
        Expanded(flex: 1, child: Container(),),
      ],)
    );
  }

  /*Widget _buildMessageContent(String message) {
    return Column(children: [
      Expanded(flex: 1, child: Container(),),
      Padding(padding: EdgeInsets.symmetric(horizontal: 32), child:
        Text(message, textAlign: TextAlign.center, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 18)),
      ),
      Expanded(flex: 2, child: Container(),),
    ],);
  }*/

  void _showMessagePopup(String? message) {
    if ((message != null) && message.isNotEmpty) {
      ExploreMessagePopup.show(context, message, onTapUrl: _handleLocalUrl);
    }
  }

  void _showOptionalMessagePopup(String message, { String? showPopupStorageKey }) {
    showDialog(context: context, builder: (context) => ExploreOptionalMessagePopup(
      message: message,
      showPopupStorageKey: showPopupStorageKey,
      onTapUrl: _handleLocalUrl,
    ));
  }

  Widget _buildBuildingsHeaderBar() => Row(mainAxisAlignment: MainAxisAlignment.end, children: [
    Event2ImageCommandButton(Styles().images.getImage('search'),
        label: Localization().getStringEx('panel.explore.button.search.buildings.title', 'Search'),
        hint: Localization().getStringEx('panel.explore.button.search.buildings.hint', 'Tap to search buildings'),
        contentPadding: EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
        onTap: _onBuildingsSearch
    ),
  ],);

  void _onBuildingsSearch() {
    Analytics().logSelect(target: 'Search');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreBuildingsSearchPanel()));
  }

  Widget _buildMTDStopsHeaderBar() => Row(children: [
    Expanded(child:
      _buildMtdStopsContentDescription(),
    ),
    LinkButton(
      title: Localization().getStringEx('panel.events2.home.bar.button.list.title', 'List'),
      hint: Localization().getStringEx('panel.events2.home.bar.button.list.hint', 'Tap to view events as list'),
      onTap: _onMTDStopsListView,
      padding: EdgeInsets.only(left: 0, right: 8, top: 16, bottom: 16),
      textStyle: Styles().textStyles.getTextStyle('widget.button.title.regular.underline'),
    ),
    Event2ImageCommandButton(Styles().images.getImage('search'),
      label: Localization().getStringEx('panel.explore.button.search.buildings.title', 'Search'),
      hint: Localization().getStringEx('panel.explore.button.search.buildings.hint', 'Tap to search buildings'),
      contentPadding: EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
      onTap: _onMTDStopsSearch
    ),
  ],);

  Widget _buildMtdStopsContentDescription() {
    List<InlineSpan> descriptionList = <InlineSpan>[];
    TextStyle? boldStyle = Styles().textStyles.getTextStyle("widget.card.title.tiny.fat");
    TextStyle? regularStyle = Styles().textStyles.getTextStyle("widget.card.detail.small.regular");

    if (StringUtils.isNotEmpty(_mtdStopSearchText)) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: '  ', style: regularStyle,),);
      }
      descriptionList.add(TextSpan(text: Localization().getStringEx('panel.explore.label.search.label.title', 'Search: ') , style: boldStyle, recognizer: _clearMTDStopsSearchRecognizer, ));
      descriptionList.add(TextSpan(text: _mtdStopSearchText ?? '' , style: regularStyle, recognizer: _clearMTDStopsSearchRecognizer));
      descriptionList.add(_buildCloseSpan(onTap: _onMTDStopsClearSearch));
    }

    if ((_mtdStopScope != null) && (_mtdStopScope != MTDStopsScope.all)) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: '  ', style: regularStyle,),);
      }
      descriptionList.add(TextSpan(text: Localization().getStringEx('panel.explore.label.scope.label.title', 'Filter: ') , style: boldStyle, recognizer: _clearMTDStopsScopeRecognizer, ));
      descriptionList.add(TextSpan(text: _mtdStopScope?.displayHint ?? '' , style: regularStyle, recognizer: _clearMTDStopsScopeRecognizer));
      descriptionList.add(_buildCloseSpan(onTap: _onMTDStopsClearScope));
    }

    if (descriptionList.isNotEmpty) {
      descriptionList.add(TextSpan(text: '  ', style: regularStyle,),);
    }
    descriptionList.add(TextSpan(text: Localization().getStringEx('panel.explore.label.locations.label.title', 'Locations: ') , style: boldStyle,));
    descriptionList.add(TextSpan(text: _exploreProgress ? '...' : (_totalExploreLocations()?.toString() ?? '-') , style: regularStyle,));

    if (descriptionList.isNotEmpty) {
      return Container(padding: EdgeInsets.only(left: 16, right: 16), child:
          Row(children: [ Expanded(child:
            RichText(text: TextSpan(style: regularStyle, children: descriptionList))
          ),],)
      );
    }
    else {
      return Container();
    }
  }

  InlineSpan _buildCloseSpan({void Function()? onTap}) =>
    WidgetSpan(alignment: PlaceholderAlignment.middle, child:
      InkWell(onTap: onTap, child:
        Padding(padding: EdgeInsets.only(left: 1), child:
          Styles().images.getImage('close-circle', size: 12) ?? Container()
        )
      )
    );

  void _onMTDStopsSearch() {
    Analytics().logSelect(target: 'Search');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => MTDStopSearchPanel(
        scope: _mtdStopScope ?? MTDStopsScope.all,
        searchText: _mtdStopSearchText,
        searchContext: MTDStopSearchContext.Map,
    ))).then((result) {
      if (result is String) {
        String? mtdStopSearchText = result.isNotEmpty ? result : null;
        if (_mtdStopSearchText != mtdStopSearchText) {
          setStateIfMounted(() {
            _mtdStopSearchText = mtdStopSearchText;
          });
          if ((mtdStopSearchText != null) && mtdStopSearchText.isNotEmpty) {
            Analytics().logSearch(mtdStopSearchText);
          }
          _initExplores();
        }
      }
    });
  }

  void _onMTDStopsListView() {
    Analytics().logSelect(target: 'List View');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => MTDStopsHomePanel(scope: _mtdStopScope ?? MTDStopsScope.all,)));;
  }

  void _onMTDStopsClearSearch() {
    Analytics().logSelect(target: 'Clear MTD Stops Search');
    setState(() {
      _mtdStopSearchText = null;
    });
    _initExplores();
  }

  void _onMTDStopsClearScope() {
    Analytics().logSelect(target: 'Clear MTD Stops Scope');
    setState(() {
      _mtdStopScope = null;
    });
    _initExplores();
  }

  // Events2 - Data

  Widget _buildEvents2HeaderBar() => Column(children: [
    _buildEvents2CommandButtons(),
    _buildEvents2ContentDescription(),
    Padding(padding: EdgeInsets.only(bottom: 12)),
  ],);
  
  Widget _buildEvents2CommandButtons() {
    return Row(children: [
      Padding(padding: EdgeInsets.only(left: 16)),
      Expanded(flex: 6, child: Wrap(spacing: 8, runSpacing: 8, children: [ //Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Event2FilterCommandButton(
          title: Localization().getStringEx('panel.events2.home.bar.button.filter.title', 'Filter'),
          leftIconKey: 'filters',
          rightIconKey: 'chevron-right',
          onTap: _onEvent2Filters,
        ),
        //_sortButton,

      ])),
      Expanded(flex: 4, child: Wrap(alignment: WrapAlignment.end, verticalDirection: VerticalDirection.up, children: [
        Visibility(visible: StringUtils.isEmpty(_event2SearchText), child:
          LinkButton(
            title: Localization().getStringEx('panel.events2.home.bar.button.list.title', 'List'), 
            hint: Localization().getStringEx('panel.events2.home.bar.button.list.hint', 'Tap to view events as list'),
            onTap: _onEvent2ListView,
            padding: EdgeInsets.only(left: 0, right: 8, top: 16, bottom: 16),
            textStyle: Styles().textStyles.getTextStyle('widget.button.title.regular.underline'),
          ),
        ),
        Visibility(visible: Auth2().isCalendarAdmin, child:
          Event2ImageCommandButton(Styles().images.getImage('plus-circle'),
            label: Localization().getStringEx('panel.events2.home.bar.button.create.title', 'Create'),
            hint: Localization().getStringEx('panel.events2.home.bar.button.create.hint', 'Tap to create event'),
            contentPadding: EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 16),
            onTap: _onEvent2Create
          ),
        ),
        Event2ImageCommandButton(Styles().images.getImage('search'),
          label: Localization().getStringEx('panel.events2.home.bar.button.search.title', 'Search'),
          hint: Localization().getStringEx('panel.events2.home.bar.button.search.hint', 'Tap to search events'),
          contentPadding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
          onTap: _onEvent2Search
        ),
      ])),
    ],);
  }

  Widget _buildEvents2ContentDescription() {
    List<InlineSpan> descriptionList = <InlineSpan>[];
    TextStyle? boldStyle = Styles().textStyles.getTextStyle("widget.card.title.tiny.fat");
    TextStyle? regularStyle = Styles().textStyles.getTextStyle("widget.card.detail.small.regular");

    if (StringUtils.isNotEmpty(_event2SearchText)) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: '; ', style: regularStyle,),);
      }
      descriptionList.add(TextSpan(text: Localization().getStringEx('panel.event2.search.search.label.title', 'Search: ') , style: boldStyle,));
      descriptionList.add(TextSpan(text: _event2SearchText ?? '' , style: regularStyle,));
    }

    List<InlineSpan> filtersList = _buildEvents2FilterAttributes(boldStyle: boldStyle, regularStyle: regularStyle);
    if (filtersList.isNotEmpty) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: '; ', style: regularStyle,),);
      }
      descriptionList.add(TextSpan(text: Localization().getStringEx('panel.events2.home.attributes.filter.label.title', 'Filter: ') , style: boldStyle,));
      descriptionList.addAll(filtersList);
    }

    if (descriptionList.isNotEmpty) {
      descriptionList.add(TextSpan(text: '; ', style: regularStyle,),);
    }
    descriptionList.add(TextSpan(text: Localization().getStringEx('panel.explore.label.locations.label.title', 'Locations: ') , style: boldStyle,));
    descriptionList.add(TextSpan(text: _exploreProgress ? '...' : (_totalExploreLocations()?.toString() ?? '-') , style: regularStyle,));
    descriptionList.add(TextSpan(text: '.', style: regularStyle,),);

    if (descriptionList.isNotEmpty) {
      return Container(padding: EdgeInsets.only(left: 16, right: 16), child:
          Row(children: [ Expanded(child:
            RichText(text: TextSpan(style: regularStyle, children: descriptionList))
          ),],)
      );
    }
    else {
      return Container();
    }
  }

  List<InlineSpan> _buildEvents2FilterAttributes({TextStyle? boldStyle, TextStyle? regularStyle}) {
    List<InlineSpan> filtersList = <InlineSpan>[];
    String? timeDescription = (_event2TimeFilter != Event2TimeFilter.customRange) ?
      event2TimeFilterToDisplayString(_event2TimeFilter) :
      event2TimeFilterDisplayInfo(Event2TimeFilter.customRange, customStartTime: _event2CustomStartTime, customEndTime: _event2CustomEndTime);
    
    if (timeDescription != null) {
      if (filtersList.isNotEmpty) {
        filtersList.add(TextSpan(text: ", " , style: regularStyle,));
      }
      filtersList.add(TextSpan(text: timeDescription, style: regularStyle,),);
    }

    for (Event2TypeFilter type in _event2Types) {
      if (filtersList.isNotEmpty) {
        filtersList.add(TextSpan(text: ", " , style: regularStyle,));
      }
      filtersList.add(TextSpan(text: event2TypeFilterToDisplayString(type), style: regularStyle,),);
    }

    ContentAttributes? contentAttributes = Events2().contentAttributes;
    List<ContentAttribute>? attributes = contentAttributes?.attributes;
    if (_event2Attributes.isNotEmpty && (contentAttributes != null) && (attributes != null)) {
      for (ContentAttribute attribute in attributes) {
        List<String>? displayAttributeValues = attribute.displaySelectedLabelsFromSelection(_event2Attributes, complete: true);
        if ((displayAttributeValues != null) && displayAttributeValues.isNotEmpty) {
          for (String attributeValue in displayAttributeValues) {
            if (filtersList.isNotEmpty) {
              filtersList.add(TextSpan(text: ", " , style: regularStyle,));
            }
            filtersList.add(TextSpan(text: attributeValue, style: regularStyle,),);
          }
        }
      }
    }

    return filtersList;
  }

  void _onEvent2Filters() {
    Analytics().logSelect(target: 'Filters');

    Event2HomePanel.presentFiltersV2(context, Event2FilterParam(
      timeFilter: _event2TimeFilter,
      customStartTime: _event2CustomStartTime,
      customEndTime: _event2CustomEndTime,
      types: _event2Types,
      attributes: _event2Attributes
    )).then((Event2FilterParam? filterResult) {
      if ((filterResult != null) && mounted) {
        setState(() {
          _event2TimeFilter = filterResult.timeFilter ?? Event2TimeFilter.upcoming;
          _event2CustomStartTime = filterResult.customStartTime;
          _event2CustomEndTime = filterResult.customEndTime;
          _event2Types = filterResult.types ?? LinkedHashSet<Event2TypeFilter>();
          _event2Attributes = filterResult.attributes ?? <String, dynamic>{};
        });
        
        Storage().events2Time = _event2TimeFilter.toJson();
        Storage().events2CustomStartTime = JsonUtils.encode(_event2CustomStartTime?.toJson());
        Storage().events2CustomEndTime = JsonUtils.encode(_event2CustomEndTime?.toJson());
        Storage().events2Types = _event2Types.toJson();
        Storage().events2Attributes = _event2Attributes;

        Event2FilterParam.notifySubscribersChanged(except: this);

        _refreshExplores();
      }
    });
  }

  void _updateEvent2Filers() {
    Event2TimeFilter? timeFilter = Event2TimeFilterImpl.fromJson(Storage().events2Time);
    TZDateTime? customStartTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomStartTime));
    TZDateTime? customEndTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomEndTime));
    LinkedHashSet<Event2TypeFilter>? types = LinkedHashSetUtils.from<Event2TypeFilter>(Event2TypeFilterListImpl.listFromJson(Storage().events2Types));
    Map<String, dynamic>? attributes = Storage().events2Attributes;

    setStateIfMounted(() {
      if (timeFilter != null) {
        _event2TimeFilter = timeFilter;
        _event2CustomStartTime = customStartTime;
        _event2CustomEndTime = customEndTime;
      }
      if (types != null) {
        _event2Types = types;
      }
      if (attributes != null) {
        _event2Attributes = attributes;
      }
    });

    if (_selectedMapType == ExploreMapType.Events2) {
      _refreshExplores();
    }
  }

  void _onEvent2Search() {
    Analytics().logSelect(target: 'Search');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2SearchPanel(searchText: _event2SearchText, searchContext: Event2SearchContext.Map, userLocation: _currentLocation))).then((result) {
      if (result is String) {
        String? event2SearchText = result.isNotEmpty ? result : null;
        if (_event2SearchText != event2SearchText) {
          setStateIfMounted(() {
            _event2SearchText = event2SearchText;
          });
          if ((event2SearchText != null) && event2SearchText.isNotEmpty) {
            Analytics().logSearch(event2SearchText);
          }
          _initExplores();
        }
      }
    });
  }

  void _onEvent2Create() {
    Analytics().logSelect(target: 'Create');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2CreatePanel()));
  }

  void _onEvent2ListView() {
    Analytics().logSelect(target: 'List View');
    Event2HomePanel.present(context, analyticsFeature: widget.analyticsFeature);
  }

  // Dropdown Widgets

  Widget _buildExploreTypesDropDownButton() {
    return RibbonButton(
      textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"),
      backgroundColor: Styles().colors.white,
      borderRadius: BorderRadius.all(Radius.circular(5)),
      border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
      rightIconKey: (_itemsDropDownValuesVisible ? 'chevron-up' : 'chevron-down'),
      label: _selectedMapType?.displayTitle,
      hint: _selectedMapType?._displayHint,
      onTap: _onExploreTypesDropdown
    );
  }

  void _onExploreTypesDropdown() {
    Analytics().logSelect(target: 'Explore Dropdown');
    setStateIfMounted(() {
      _clearActiveFilter();
      _itemsDropDownValuesVisible = !_itemsDropDownValuesVisible;
    });
  }

  Widget _buildEventsDisplayTypesDropDownContainer() {
    return Visibility(visible: _eventsDisplayDropDownValuesVisible, child:
      Positioned.fill(child:
        Stack(children: <Widget>[
          _buildEventsDisplayTypesDropDownDismissLayer(),
          _buildEventsDisplayTypesDropDownWidget()
        ]),
      ),
    );
  }

  Widget _buildEventsDisplayTypesDropDownDismissLayer() {
    return Positioned.fill(child:
      BlockSemantics(child:
        GestureDetector(onTap: _onDismissEventsDisplayTypesDropDown, child:
          Container(color: Styles().colors.blackTransparent06)
        )
      )
    );
  }

  void _onDismissEventsDisplayTypesDropDown() {
    Analytics().logSelect(target: 'Events Type Dismiss');
    setStateIfMounted(() {
      _eventsDisplayDropDownValuesVisible = false;
    });
  }

  Widget _buildEventsDisplayTypesDropDownWidget() {
    List<Widget> displayTypesWidgetList = <Widget>[
      Container(color: Styles().colors.fillColorSecondary, height: 2)
    ];
    for (EventsDisplayType displayType in EventsDisplayType.values) {
      if ((_selectedEventsDisplayType != displayType)) {
        displayTypesWidgetList.add(_buildEventsDisplayTypeDropDownItem(displayType));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: displayTypesWidgetList)
      )
    );
  }

  Widget _buildEventsDisplayTypeDropDownItem(EventsDisplayType displayType) {
    return RibbonButton(
        backgroundColor: Styles().colors.white,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        rightIconKey: null,
        label: _eventsDisplayTypeName(displayType),
        onTap: () => _onEventsDisplayType(displayType));
  }

  void _onEventsDisplayType(EventsDisplayType displayType) {
    Analytics().logSelect(target: _eventsDisplayTypeName(displayType));

    EventsDisplayType? lastDisplayType = _selectedEventsDisplayType;
    setStateIfMounted(() {
      _clearActiveFilter();
      _selectedEventsDisplayType = displayType;
      _eventsDisplayDropDownValuesVisible = !_eventsDisplayDropDownValuesVisible;
    });
    if (lastDisplayType != _selectedEventsDisplayType) {
      _initExplores();
    }
  }

  Widget _buildExploreTypesDropDownContainer() {
    return Visibility(visible: _itemsDropDownValuesVisible, child:
      Positioned.fill(child:
        Stack(children: <Widget>[
          _buildExploreDropDownDismissLayer(),
          _buildExploreTypesDropDownWidget()
        ])
      )
    );
  }

  Widget _buildExploreDropDownDismissLayer() {
    return Positioned.fill(child:
      BlockSemantics(child:
        GestureDetector(onTap: _onDismissExploreDropDown, child:
          Container(color: Styles().colors.blackTransparent06)
        )
      )
    );
  }

  void _onDismissExploreDropDown() {
    Analytics().logSelect(target: "Explore Dropdown Dismiss");
    setStateIfMounted(() {
      _itemsDropDownValuesVisible = false;
    });
  }

  Widget _buildExploreTypesDropDownWidget() {
    List<Widget> itemList = <Widget>[
      Container(color: Styles().colors.fillColorSecondary, height: 2),
    ];
    for (ExploreMapType exploreItem in _exploreTypes) {
      itemList.add(RibbonButton(
        backgroundColor: Styles().colors.white,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        textStyle: Styles().textStyles.getTextStyle((_selectedMapType == exploreItem) ? 'widget.button.title.medium.fat.secondary' : 'widget.button.title.medium.fat'),
        rightIconKey: (_selectedMapType == exploreItem) ? 'check-accent' : null,
        label: exploreItem.displayTitle,
        onTap: () => _onTapExploreType(exploreItem)
      ));
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: itemList)
      )
    );
  }

  void _onTapExploreType(ExploreMapType item) {
    Analytics().logSelect(target: item.displayTitleEn);
    ExploreMapType? lastExploreType = _selectedMapType;
    setStateIfMounted(() {
      _clearActiveFilter();
      Storage()._selectedMapExploreType = _selectedMapType = item;
      _itemsDropDownValuesVisible = false;
    });
    if (lastExploreType != item) {
      _initExplores();
    }
  }

  // Filter Widgets

  Widget _buildFiltersBar() {
    List<Widget> filterTypeWidgets = [];
    List<ExploreFilter>? visibleFilters = (_itemToFilterMap != null) ? _itemToFilterMap![_selectedMapType] : null;
    if ((visibleFilters != null ) && visibleFilters.isNotEmpty) {
      for (int i = 0; i < visibleFilters.length; i++) {
        ExploreFilter selectedFilter = visibleFilters[i];
        List<String> filterValues = _getFilterValues(selectedFilter.type)!;
        int filterValueIndex = selectedFilter.firstSelectedIndex;
        String? filterHeaderLabel = (0 <= filterValueIndex) && (filterValueIndex < filterValues.length) ? filterValues[filterValueIndex] : null;
        filterTypeWidgets.add(FilterSelector(
          title: filterHeaderLabel,
          hint: _getFilterHint(selectedFilter.type),
          active: selectedFilter.active,
          onTap: () => _onFilterType(filterHeaderLabel, selectedFilter),
        ));
      }

      return Padding(padding: EdgeInsets.only(left: 12, right: 12, bottom: 12), child:
        Wrap(children: filterTypeWidgets),
      );
    }
    else {
      return Container();
    }
  }

  void _onFilterType(String? filterName, ExploreFilter selectedFilter) {
    Analytics().logSelect(target: filterName);
    setStateIfMounted(() {
      _toggleActiveFilter(selectedFilter);
    });
  }

  Widget _buildFilterValuesContainer() {
    ExploreFilter? selectedFilter = _selectedFilter;
    List<String>? filterValues = (selectedFilter != null) ? _getFilterValues(selectedFilter.type) : null;
    if ((selectedFilter != null) && (filterValues != null)) {
      List<String?>? filterSubLabels = (selectedFilter.type == ExploreFilterType.event_time) ? _buildFilterEventDateSubLabels() : null;
      return Semantics(sortKey: OrdinalSortKey(_filterLayoutSortKey), child:
        Visibility(visible: _filtersDropdownVisible, child:
          Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 36, bottom: 40), child:
            Semantics(child:
              Container(decoration: BoxDecoration(color: Styles().colors.fillColorSecondary, borderRadius: BorderRadius.circular(5.0),), child:
                Padding(padding: EdgeInsets.only(top: 2), child:
                  Container(color: Colors.white, child:
                    ListView.separated(
                      shrinkWrap: true,
                      separatorBuilder: (context, index) => Divider(height: 1, color: Styles().colors.fillColorPrimaryTransparent03,),
                      itemCount: filterValues.length,
                      itemBuilder: (context, index) => FilterListItem(
                        title: filterValues[index],
                        description: CollectionUtils.isNotEmpty(filterSubLabels) ? filterSubLabels![index] : null,
                        selected: selectedFilter.selectedIndexes.contains(index),
                        onTap: () => _onFilterItem(selectedFilter, filterValues[index], index),
                      ),
                    ),
                  ),
                ),
              )
            )
          ),
        )
      );
    }
    return Container();
  }

  void _onFilterItem(ExploreFilter selectedFilter, String newValueText, int newValueIndex) {
    Analytics().logSelect(target: "FilterItem: $newValueText");
    
    // JP: Change category selection back to radio button only. Only one of the possibilities should be picked at a time. Sorry I asked for the change.
    Set<int> selectedIndexes = { newValueIndex };
    /*Apply custom logic for selecting event categories.
    Set<int> selectedIndexes = Set.of(selectedFilter.selectedIndexes); //Copy
    
    if (selectedFilter.type == ExploreFilterType.categories) {
      if (newValueIndex == 0) {
        selectedIndexes = {newValueIndex};
      } else {
        if (selectedIndexes.contains(newValueIndex)) {
          selectedIndexes.remove(newValueIndex);
          if (selectedIndexes.isEmpty) {
            selectedIndexes = {0}; //select All categories
          }
        } else {
          selectedIndexes.remove(0);
          selectedIndexes.add(newValueIndex);
        }
      }
    } else {
      selectedIndexes = {newValueIndex};
    }*/
    
    Set<int> lastSelectedIndexes = selectedFilter.selectedIndexes;
    selectedFilter.selectedIndexes = selectedIndexes;
    selectedFilter.active = _filtersDropdownVisible = false;

    if (selectedFilter.type == ExploreFilterType.student_course_terms) {
      StudentCourseTerm? term = ListUtils.entry(_studentCourseTerms, newValueIndex);
      if (term != null) {
        StudentCourses().selectedTermId = term.id;
      }
    }

    if (!DeepCollectionEquality().equals(lastSelectedIndexes, selectedIndexes)) {
      _initExplores();
    }
    else {
      setState(() {});
    }
  }

  List<String?> _buildFilterEventDateSubLabels() {
    String dateFormat = 'MM/dd';
    DateTime now = DateTime.now();
    String? todayDateLabel = AppDateTime()
        .formatDateTime(now, format: dateFormat,
        ignoreTimeZone: true);

    //Next 7 days
    String next7DaysEnd = '${AppDateTime()
        .formatDateTime(now.add(Duration(days: 6)), format: dateFormat,
        ignoreTimeZone: true)}';
    String next7DaysLabel = '$todayDateLabel - $next7DaysEnd';

    //This weekend
    int currentWeekDay = now.weekday;
    DateTime weekendStartDate = DateTime(
        now.year, now.month, now.day, 0, 0, 0)
        .add(Duration(days: (6 - currentWeekDay)));
    DateTime weekendEndDate = weekendStartDate.add(
        Duration(days: 1, hours: 23, minutes: 59, seconds: 59));
    String? weekendStartLabel = AppDateTime().formatDateTime(
        weekendStartDate, format: dateFormat,
        ignoreTimeZone: true);
    String? weekendEndLabel = AppDateTime().formatDateTime(
        weekendEndDate, format: dateFormat, ignoreTimeZone: true);
    String weekendLabel = '$weekendStartLabel - $weekendEndLabel';

    //Next 30 days
    String? next30DaysEndLabel = AppDateTime()
        .formatDateTime(now.add(Duration(days: 30)), format: dateFormat,
        ignoreTimeZone: true);
    String next30DaysLabel = '$todayDateLabel - $next30DaysEndLabel';

    return [
      null, //Upcoming has no subLabel
      todayDateLabel,
      next7DaysLabel,
      weekendLabel,
      next30DaysLabel
    ];
  }

  // Explore Items

  void _updateExploreTypes() {
    List<ExploreMapType> exploreTypes = widget._buildExploreTypes();
    if (!DeepCollectionEquality().equals(_exploreTypes, exploreTypes)) {
      if (exploreTypes.contains(_selectedMapType)) {
        setStateIfMounted(() {
          _exploreTypes = exploreTypes;
        });
      }
      else {
        setStateIfMounted(() {
          _exploreTypes = exploreTypes;
          _selectedMapType = ExploreMapPanel._defaultMapType._ensure(availableTypes: exploreTypes) ??
              (exploreTypes.isNotEmpty ? exploreTypes.first : null);
        });
        _initExplores();
      }
    }
  }

  ExploreMapSearchEventsParam? get _initialEvent2SearchParam => _paramSearchEvents2(widget.params[ExploreMapPanel.selectParamKey]);
  static ExploreMapSearchEventsParam? _paramSearchEvents2(dynamic param) => (param is ExploreMapSearchEventsParam) ? param : null;

  ExploreMapSearchMTDStopsParam? get _initialMTDStopsSearchParam => _paramSearchMTDStops(widget.params[ExploreMapPanel.selectParamKey]);
  static ExploreMapSearchMTDStopsParam? _paramSearchMTDStops(dynamic param) => (param is ExploreMapSearchMTDStopsParam) ? param : null;

  // Filters

  void _initFilters() {

    _filterEventTimeValues = [
      Localization().getStringEx('panel.explore.filter.time.upcoming', 'Upcoming'),
      Localization().getStringEx('panel.explore.filter.time.today', 'Today'),
      Localization().getStringEx('panel.explore.filter.time.next_7_days', 'Next 7 Days'),
      Localization().getStringEx('panel.explore.filter.time.this_weekend', 'This Weekend'),
      Localization().getStringEx('panel.explore.filter.time.this_month', 'Next 30 days'),
    ];

    _filterPaymentTypeValues = [
      Localization().getStringEx('panel.explore.filter.payment_types.all', 'All Payment Types')  
    ];
    for (PaymentType paymentType in PaymentType.values) {
      _filterPaymentTypeValues!.add(PaymentTypeHelper.paymentTypeToDisplayString(paymentType) ?? '');
    }

    _filterWorkTimeValues = [
      Localization().getStringEx('panel.explore.filter.worktimes.all', 'All Locations'),
      Localization().getStringEx('panel.explore.filter.worktimes.open_now', 'Open Now'),
    ];

    _studentCourseTerms = StudentCourses().terms;

    _itemToFilterMap = {
      ExploreMapType.Dining: <ExploreFilter>[
        ExploreFilter(type: ExploreFilterType.work_time),
        ExploreFilter(type: ExploreFilterType.payment_type)
      ],
      ExploreMapType.StudentCourse: <ExploreFilter>[
        ExploreFilter(type: ExploreFilterType.student_course_terms, selectedIndexes: { _selectedTermIndex }),
      ],
    };
    
  }

  void _clearActiveFilter({ExploreFilter? skipFilter }) {
    List<ExploreFilter>? itemFilters = (_itemToFilterMap != null) ? _itemToFilterMap![_selectedMapType] : null;
    if (itemFilters != null && itemFilters.isNotEmpty) {
      for (ExploreFilter filter in itemFilters) {
        if (filter != skipFilter) {
          filter.active = false;
        }
      }
    }
    _filtersDropdownVisible = false;
  }

  void _toggleActiveFilter(ExploreFilter selectedFilter) {
    _clearActiveFilter(skipFilter: selectedFilter);
    selectedFilter.active = _filtersDropdownVisible = !selectedFilter.active;
  }

  ExploreFilter? get _selectedFilter {
    List<ExploreFilter>? itemFilters = (_itemToFilterMap != null) ? _itemToFilterMap![_selectedMapType] : null;
    if (itemFilters != null && itemFilters.isNotEmpty) {
      for (ExploreFilter filter in itemFilters) {
        if (filter.active) {
          return filter;
        }
      }
    }
    return null;
  }

  static String? _eventsDisplayTypeName(EventsDisplayType? type) {
    switch (type) {
      case EventsDisplayType.all:       return Localization().getStringEx('panel.explore.button.events.display_type.all.label', 'All Events');
      case EventsDisplayType.multiple:  return Localization().getStringEx('panel.explore.button.events.display_type.multiple.label', 'Multi-day events');
      case EventsDisplayType.single:    return Localization().getStringEx('panel.explore.button.events.display_type.single.label', 'Single day events');
      default:                      return null;
    }
  }

  List<String>? _getFilterValues(ExploreFilterType filterType) {
    switch (filterType) {
      case ExploreFilterType.work_time:    return _filterWorkTimeValues;
      case ExploreFilterType.payment_type: return _filterPaymentTypeValues;
      case ExploreFilterType.event_time:   return _filterEventTimeValues;
      case ExploreFilterType.event_tags:   return _filterTagsValues;
      case ExploreFilterType.student_course_terms: return _filterTermsValues;
      default: return null;
    }
  }

  List<String> get _filterTagsValues => <String>[
    Localization().getStringEx('panel.explore.filter.tags.all', 'All Tags'),
    Localization().getStringEx('panel.explore.filter.tags.my', 'My Tags'),
  ];

  List<String> get _filterTermsValues {
    List<String> categoriesValues = [];
    if (_studentCourseTerms != null) {
      for (StudentCourseTerm term in _studentCourseTerms!) {
        categoriesValues.add(term.name ?? '');
      }
    }
    return categoriesValues;
  }

  int get _selectedTermIndex {
    String? displayTermId = StudentCourses().displayTermId;
    if ((_studentCourseTerms != null) && (displayTermId != null)) {
      for (int index = 0; index < _studentCourseTerms!.length; index++) {
        if (_studentCourseTerms![index].id == displayTermId) {
          return index;
        }
      }
    }
    return -1;
  }

  String? _getSelectedTermId(List<ExploreFilter>? selectedFilterList) {
    ExploreFilter? selectedFilter = _getSelectedFilter(selectedFilterList, ExploreFilterType.student_course_terms);
    int index = selectedFilter?.firstSelectedIndex ?? -1;
    return ((0 <= index) && (index < (_studentCourseTerms?.length ?? 0))) ? _studentCourseTerms![index].id : null;
  }

  void _updateSelectedTermId() {
    List<ExploreFilter>? selectedFilterList = (_itemToFilterMap != null) ? _itemToFilterMap![ExploreMapType.StudentCourse] : null; 
    ExploreFilter? selectedFilter = _getSelectedFilter(selectedFilterList, ExploreFilterType.student_course_terms);
    if (selectedFilter != null) {
      selectedFilter.selectedIndexes = { _selectedTermIndex };
    }
  }

  String? _getFilterHint(ExploreFilterType filterType) {
    switch (filterType) {
      case ExploreFilterType.categories:
        return Localization().getStringEx('panel.explore.filter.categories.hint', '');
      case ExploreFilterType.work_time:
        return Localization().getStringEx('panel.explore.filter.worktimes.hint', '');
      case ExploreFilterType.payment_type:
        return Localization().getStringEx('panel.explore.filter.payment_types.hint', '');
      case ExploreFilterType.event_time:
        return Localization().getStringEx('panel.explore.filter.time.hint', '');
      case ExploreFilterType.event_tags:
        return Localization().getStringEx('panel.explore.filter.tags.hint', '');
      case ExploreFilterType.student_course_terms:
        return Localization().getStringEx('panel.explore.filter.terms.hint', '');
      default:
        return null;
    }
  }

  ExploreFilter? _getSelectedFilter(List<ExploreFilter>? selectedFilterList, ExploreFilterType type) {
    if (selectedFilterList != null) {
      for (ExploreFilter selectedFilter in selectedFilterList) {
        if (selectedFilter.type == type) {
          return selectedFilter;
        }
      }
    }
    return null;
  }

  String? _getSelectedWorkTime(List<ExploreFilter>? selectedFilterList) {
    if (selectedFilterList == null || selectedFilterList.isEmpty) {
      return null;
    }
    for (ExploreFilter selectedFilter in selectedFilterList) {
      if (selectedFilter.type == ExploreFilterType.work_time) {
        int index = selectedFilter.firstSelectedIndex;
        return (_filterWorkTimeValues!.length > index)
            ? _filterWorkTimeValues![index]
            : null;
      }
    }
    return null;
  }

  PaymentType? _getSelectedPaymentType(List<ExploreFilter>? selectedFilterList) {
    if (selectedFilterList == null || selectedFilterList.isEmpty) {
      return null;
    }
    for (ExploreFilter selectedFilter in selectedFilterList) {
      if (selectedFilter.type == ExploreFilterType.payment_type) {
        int index = selectedFilter.firstSelectedIndex;
        if (index == 0) {
          return null; //All payment types
        }
        return (_filterPaymentTypeValues!.length > index)
            ? PaymentType.values[index - 1]
            : null;
      }
    }
    return null;
  }

  // Events2 - Data

  bool _updateEvent2FiltersOnLocationServicesStatus() {
    bool locationNotAvailable = ((_locationServicesStatus == LocationServicesStatus.serviceDisabled) || ((_locationServicesStatus == LocationServicesStatus.permissionDenied)));
    if (_event2Types.contains(Event2TypeFilter.nearby) && locationNotAvailable) {
      _event2Types.remove(Event2TypeFilter.nearby);
      return true;
    }
    else {
      return false;
    }
  }

  Future<Position?> _ensureCurrentLocation() async {
    if (_currentLocation == null) {
      if (_locationServicesStatus == LocationServicesStatus.permissionNotDetermined) {
        _locationServicesStatus = await LocationServices().requestPermission();
        _updateEvent2FiltersOnLocationServicesStatus();
      }
      if (_locationServicesStatus == LocationServicesStatus.permissionAllowed) {
        _currentLocation = await LocationServices().location;
      }
    }
    return _currentLocation;
  } 

  Future<Events2Query> _event2QueryParam() async {
    if (_event2Types.contains(Event2TypeFilter.nearby)) {
      await _ensureCurrentLocation();
    }
    return Events2Query(
      searchText: _event2SearchText,
      timeFilter: _event2TimeFilter,
      customStartTimeUtc: _event2CustomStartTime?.toUtc(),
      customEndTimeUtc: _event2CustomEndTime?.toUtc(),
      types: _event2Types,
      attributes: _event2Attributes,
      location: _currentLocation,
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
      _updateEvent2FiltersOnLocationServicesStatus();
    }
  }

  // Explore Content

  Future<void> _initExplores() async {
    Future<List<Explore>?> exploreTask = _loadExplores();
    applyStateIfMounted(() {
      _exploreProgress = true;
    });
    List<Explore>? explores = await (_exploreTask = exploreTask);
    if (mounted && (exploreTask == _exploreTask)) {
      await _buildMapContentData(explores, pinnedExplore: null, updateCamera: true);
      if (mounted && (exploreTask == _exploreTask)) {
        setState(() {
          _explores = explores;
          _filteredExplores = null;
          _exploreTask = null;
          _exploreProgress = false;
          _mapKey = UniqueKey(); // force map rebuild
        });
        _selectMapExplore(null);
        _selectStoriedSiteExplore(null);
        _displayContentPopups();
      }
    }
  }


  Future<void> _refreshExplores() async {
    Future<List<Explore>?> exploreTask = _loadExplores();
    List<Explore>? explores = await (_exploreTask = exploreTask);
    if (mounted && (exploreTask == _exploreTask)) {
      if (!DeepCollectionEquality().equals(_explores, explores)) {
        await _buildMapContentData(explores, pinnedExplore: _pinnedMapExplore, updateCamera: false);
        if (mounted && (exploreTask == _exploreTask)) {
          setState(() {
            _explores = explores;
            _filteredExplores = null;
            _exploreProgress = false;
            _exploreTask = null;
          });
        }
      }
      else {
        setState(() {
          _exploreTask = null;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _refreshExplores() ;
  }

  Future<List<Explore>?> _loadExplores() async {
    if (Connectivity().isNotOffline) {
      List<ExploreFilter>? selectedFilterList = (_itemToFilterMap != null) ? _itemToFilterMap![_selectedMapType] : null;
      switch (_selectedMapType) {
        case ExploreMapType.Events2: return _loadEvents2();
        case ExploreMapType.Dining: return _loadDining(selectedFilterList);
        case ExploreMapType.Laundry: return _loadLaundry();
        case ExploreMapType.Buildings: return _loadBuildings();
        case ExploreMapType.StudentCourse: return _loadStudentCourse(selectedFilterList);
        case ExploreMapType.Appointments: return _loadAppointments();
        case ExploreMapType.MTDStops: return _loadMTDStops();
        case ExploreMapType.MyLocations: return _loadMyLocations();
        case ExploreMapType.MentalHealth: return _loadMentalHealthBuildings();
        case ExploreMapType.StoriedSites: return _loadPlaces();
        default: break;
      }
    }
    return null;
  }

  Future<List<Explore>?> _loadEvents2() async =>
    await Events2().loadEventsList(await _event2QueryParam());

  Future<List<Explore>?> _loadDining(List<ExploreFilter>? selectedFilterList) async {
    String? workTime = _getSelectedWorkTime(selectedFilterList);
    PaymentType? paymentType = _getSelectedPaymentType(selectedFilterList);
    bool onlyOpened = (CollectionUtils.isNotEmpty(_filterWorkTimeValues)) ? (_filterWorkTimeValues![1] == workTime) : false;
    return await Dinings().loadBackendDinings(onlyOpened, paymentType, null);
  }

  Future<List<Explore>?> _loadLaundry() async {
    LaundrySchool? laundrySchool = await Laundries().loadSchoolRooms();
    return laundrySchool?.rooms;
  }

  Future<List<Explore>?> _loadBuildings() async {
    return await Gateway().loadBuildings();
  }

  Future<List<Explore>?> _loadMentalHealthBuildings() async {
    return await Wellness().loadMentalHealthBuildings();
  }

  Future<List<Explore>?> _loadPlaces() async {
    return await Places().getAllPlaces();
  }

  Future<List<Explore>?> _loadMTDStops() async {
    if (MTD().stops == null) {
      await MTD().refreshStops();
    }
    List<Explore>? result;
    if (MTD().stops != null) {
      _collectBusStops(result = <Explore>[], stops: _sourceBusStops);
    }
    return result;
  }

  List<MTDStop>? get _sourceBusStops {
    List<MTDStop>? stops;
    switch (_mtdStopScope) {
      case null:
      case MTDStopsScope.all: stops = MTD().stops?.stops; break;
      case MTDStopsScope.my: stops = MTD().favoriteStops; break;
    }
    return (_mtdStopSearchText?.isNotEmpty == true) ? MTDStop.searchInList(stops, search: _mtdStopSearchText?.toLowerCase()) : stops;
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

  List<Explore>? _loadMyLocations() {
    return ExplorePOI.listFromString(Auth2().prefs?.getFavorites(ExplorePOI.favoriteKeyName)) ?? <Explore>[];
  }

  Future<List<Explore>?> _loadStudentCourse(List<ExploreFilter>? selectedFilterList) async {
    String? termId = _getSelectedTermId(selectedFilterList) ?? StudentCourses().displayTermId;
    return (termId != null) ? await StudentCourses().loadCourses(termId: termId) : null;
  }

  Future<List<Explore>?> _loadAppointments() async {
    return Appointments().getAppointments(timeSource: AppointmentsTimeSource.upcoming, type: AppointmentType.in_person);
  }

  void _updateSelectedMapStopRoutes() {
    String? stopId = (_selectedMapExplore is MTDStop) ? (_selectedMapExplore as MTDStop).id : null;
    if ((stopId != null) && (stopId != _loadingMapStopIdRoutes)) {
      setStateIfMounted(() {
        _loadingMapStopIdRoutes = stopId;
      });
      MTD().getRoutes(stopId: stopId).then((List<MTDRoute>? routes) {
        String? currentStopId = (_selectedMapExplore is MTDStop) ? (_selectedMapExplore as MTDStop).id : null;
        if (currentStopId == stopId) {
          setStateIfMounted(() {
            _loadingMapStopIdRoutes = null;
            _selectedMapStopRoutes = MTDRoute.mergeUiRoutes(routes);
          });
        }
      });
    }
    else if ((stopId == null) && ((_loadingMapStopIdRoutes != null) || (_selectedMapStopRoutes != null))) {
      setStateIfMounted(() {
        _loadingMapStopIdRoutes = null;
        _selectedMapStopRoutes = null;
      });
    }
  }

  void _displayContentPopups() {
    if (_explores == null) {
      _showMessagePopup(_selectedMapType?._displayFailedContentMessage);
    }
    else if (_selectedMapType == ExploreMapType.Appointments) {
      if (CollectionUtils.isEmpty(_explores)) {
        _showMessagePopup(Localization().getStringEx('panel.explore.missing.appointments.msg','You currently have no upcoming in-person appointments linked within {{app_title}} app.').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')));
      }
      else if (Storage().appointmentsCanDisplay != true) {
        _showMessagePopup(Localization().getStringEx('panel.explore.hide.appointments.msg', 'There is nothing to display as you have chosen not to display any past or future appointments.'));
      }
    }
    else if (_selectedMapType == ExploreMapType.MTDStops) {
      if (CollectionUtils.isEmpty(_explores)) {
        _showMessagePopup(ExploreMapType.MTDStops._displayEmptyContentMessage);
      }
      else if (Storage().showMtdStopsMapInstructions != false) {
        String messageHtml = Localization().getStringEx("panel.explore.instructions.mtd_stops.msg", "Tap a bus stop on the map to get bus schedules.<br><br>Tap the \u2606 to save the bus stop. (<a href='$_privacyUrlMacro'>Your privacy level</a> must be at least 2.)").
          replaceAll(_privacyUrlMacro, _privacyUrl);
        _showOptionalMessagePopup(messageHtml, showPopupStorageKey: Storage().showMtdStopsMapInstructionsKey,
        );
      }
    }
    else if (_selectedMapType == ExploreMapType.MyLocations) {
      if (CollectionUtils.isEmpty(_explores)) {
        String messageHtml = Localization().getStringEx('panel.explore.missing.my_locations.msg', "You currently have no saved locations.<br><br>Select a location on the map and tap the \u2606 to save it as a favorite. (<a href='$_privacyUrlMacro'>Your privacy level</a> must be at least 2.)").
          replaceAll(_privacyUrlMacro, _privacyUrl);
        _showMessagePopup(messageHtml);
      }
      else if (Storage().showMyLocationsMapInstructions != false) {
        String messageHtml = Localization().getStringEx("panel.explore.instructions.my_locations.msg", "Select a location on the map and tap the \u2606  to save it as a favorite. (<a href='$_privacyUrlMacro'>Your privacy level</a> must be at least 2.)",).
          replaceAll(_privacyUrlMacro, _privacyUrl);
        _showOptionalMessagePopup(messageHtml, showPopupStorageKey: Storage().showMyLocationsMapInstructionsKey
        );
      }
    }
    else if (CollectionUtils.isEmpty(_explores)) {
      _showMessagePopup(_selectedMapType?._displayEmptyContentMessage);
    }
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

  // Favorites

  void _onFavoritesChanged() {
    if (_selectedMapType == ExploreMapType.MyLocations) {
      _refreshMyLocations();
    }
    else {
      setStateIfMounted(() {});
    }
  }

  // My Locations

  void _refreshMyLocations() {
    List<Explore>? explores = _loadMyLocations();
    if (!DeepCollectionEquality().equals(_explores, explores) && mounted) {
      _buildMapContentData(explores, pinnedExplore: _pinnedMapExplore, updateCamera: false).then((_){
        if (mounted) {
          setState(() {
            _explores = explores;
            _filteredExplores = null;
          });
        }
      });
    }
  }

  // Map Styles
  
  void _initMapStyles() {
    rootBundle.loadString(_mapStylesAssetName).then((String value) {
      _mapStyles = JsonUtils.decodeMap(value);
    }).catchError((_){
    });
  }

  String? get _currentMapStyle {
    if (_mapStyles != null) {
      if ((_selectedMapType == ExploreMapType.Buildings) || (_selectedMapType == ExploreMapType.MentalHealth) || (_selectedMapType == ExploreMapType.StoriedSites)) {
        return JsonUtils.encode(_mapStyles![_mapStylesExplorePoiKey]);
      }
      else if (_selectedMapType == ExploreMapType.MTDStops) {
        return JsonUtils.encode(_mapStyles![_mapStylesMtdStopKey]);
      }
    }
    return null;
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
        exploreMarkerGroups =  (explores != null) ? <dynamic>{ ExploreMap.validFromList(explores) } : null;
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

  int? _totalExploreLocations() {
    if (_exploreMarkerGroups != null) {
      int totalCount = 0;
      for (dynamic group in _exploreMarkerGroups!) {
        if (group is Explore) {
          totalCount++;
        }
        else if (group is List) {
          totalCount += group.length;
        }
      }
      return totalCount;
    }
    return null;
  }

  Future<Marker?> _createExploreGroupMarker(List<Explore>? exploreGroup, { required ImageConfiguration imageConfiguration }) async {
    LatLng? markerPosition = ExploreMap.centerOfList(exploreGroup);
    if ((exploreGroup != null) && (markerPosition != null)) {
      Explore? sameExplore = ExploreMap.mapGroupSameExploreForList(exploreGroup);
      Color? markerColor = sameExplore?.mapMarkerColor ?? ExploreMap.unknownMarkerColor;
      Color? markerBorderColor = sameExplore?.mapMarkerBorderColor ?? ExploreMap.defaultMarkerBorderColor;
      Color? markerTextColor = sameExplore?.mapMarkerTextColor ?? ExploreMap.defaultMarkerTextColor;
      String markerKey = "map-marker-group-${markerColor?.toARGB32() ?? 0}-${exploreGroup.length}";
      BitmapDescriptor markerIcon = _markerIconCache[markerKey] ??
          (_markerIconCache[markerKey] = await _groupMarkerIcon(
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


  Future<Marker?> _createExploreMarker(Explore? explore, {required ImageConfiguration imageConfiguration, Color? markerColor }) async {
    LatLng? markerPosition = explore?.exploreLocation?.exploreLocationMapCoordinate;
    if (markerPosition != null) {
      BitmapDescriptor? markerIcon;
      Offset? markerAnchor;
      if (explore is MTDStop) {
        String markerAsset = 'images/map-marker-mtd-stop.png';
        markerIcon = _markerIconCache[markerAsset] ??
          (_markerIconCache[markerAsset] = await BitmapDescriptor.asset(imageConfiguration, markerAsset));
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

  Size? get _mapSize => _globalKeySize(_mapContainerKey);
  Size? get _mapExploreBarSize => _globalKeySize(_mapExploreBarKey);

  static Size? _globalKeySize(GlobalKey key) {
    try {
      final RenderObject? renderBox = key.currentContext?.findRenderObject();
      return ((renderBox is RenderBox) && renderBox.hasSize) ? renderBox.size : null;
    }
    on Exception catch (e) {
      print(e.toString());
      return null;
    }
  }
}

/////////////////////////////////
// ExploreMessagePopup

class ExploreMessagePopup extends StatelessWidget {
  final String message;
  final bool Function(String url)? onTapUrl;
  ExploreMessagePopup({super.key, required this.message, this.onTapUrl});

  static Future<void> show(BuildContext context, String message, { bool Function(String url)? onTapUrl}) =>
    showDialog(context: context, builder: (context) => ExploreMessagePopup(message: message, onTapUrl: onTapUrl));

  @override
  Widget build(BuildContext context) =>
    AlertDialog(contentPadding: EdgeInsets.zero, content:
      Container(decoration: BoxDecoration(color: Styles().colors.white, borderRadius: BorderRadius.circular(10.0)), child:
        Stack(alignment: Alignment.center, fit: StackFit.loose, children: [
          Padding(padding: EdgeInsets.all(30), child:
            Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
              Styles().images.getImage('university-logo') ?? Container(),
              Padding(padding: EdgeInsets.only(top: 20), child:
                // Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.detail.small")
                HtmlWidget(message,
                  onTapUrl: (url) => (onTapUrl != null) ? onTapUrl!(url) : false,
                  textStyle: Styles().textStyles.getTextStyle("widget.detail.small"),
                  customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null
                )
              )
            ])
          ),
          Positioned.fill(child:
            Align(alignment: Alignment.topRight, child:
              InkWell(onTap: () => _onClose(context, message), child:
                Padding(padding: EdgeInsets.all(16), child:
                  Styles().images.getImage("close-circle")
                )
              )
            )
          )
        ])
      )
    );

  void _onClose(BuildContext context, String message) {
    Analytics().logAlert(text: message, selection: 'Close');
    Navigator.of(context).pop();
  }
}

///////////////////////////////////
// ExploreMapSearchEventsParam

class ExploreMapSearchEventsParam {
  final String searchText;
  ExploreMapSearchEventsParam(this.searchText);
}

///////////////////////////////////
// ExploreMapSearchMTDStopsParam

class ExploreMapSearchMTDStopsParam {
  final String searchText;
  final MTDStopsScope scope;
  ExploreMapSearchMTDStopsParam({this.searchText = '', this.scope = MTDStopsScope.all});
}

////////////////////
// ExploreFilter

class ExploreFilter {
  ExploreFilterType type;
  Set<int> selectedIndexes;
  bool active;

  ExploreFilter({required this.type, this.selectedIndexes = const {0}, this.active = false});

  int get firstSelectedIndex => (selectedIndexes.isEmpty) ? -1 : selectedIndexes.first;
}

////////////////////
// _MapMarkersSet

extension _MapMarkersSet on Set<Marker> {

  Marker? exploreMarker(Explore? explore) {
    LatLng? markerPosition = explore?.exploreLocation?.exploreLocationMapCoordinate;
    String? markerId = (markerPosition != null) ? "${markerPosition.latitude.toStringAsFixed(6)}:${markerPosition.longitude.toStringAsFixed(6)}" : null;
    return (markerId != null) ? markerById(MarkerId(markerId)) : null;
  }

  Marker? markerById(MarkerId markerId) =>
    firstWhereOrNull((marker) => marker.markerId == markerId);
}

////////////////////
// ExploreMapType

extension ExploreMapTypeImpl on ExploreMapType {

  String get displayTitle => _displayTitleLng();
  String get displayTitleEn => _displayTitleLng('en');

  String _displayTitleLng([String? language]) {
    switch (this) {
      case ExploreMapType.Events2:             return Localization().getStringEx('panel.explore.button.events2.title', 'Events', language: language);
      case ExploreMapType.Dining:              return Localization().getStringEx('panel.explore.button.dining.title', 'Residence Hall Dining', language: language);
      case ExploreMapType.Laundry:             return Localization().getStringEx('panel.explore.button.laundry.title', 'Laundry', language: language);
      case ExploreMapType.Buildings:           return Localization().getStringEx('panel.explore.button.buildings.title', 'Campus Buildings', language: language);
      case ExploreMapType.StudentCourse:       return Localization().getStringEx('panel.explore.button.student_course.title', 'My Courses', language: language);
      case ExploreMapType.Appointments:        return Localization().getStringEx('panel.explore.button.appointments.title', 'MyMcKinley In-Person Appointments', language: language);
      case ExploreMapType.MTDStops:            return Localization().getStringEx('panel.explore.button.mtd_stops.title', 'MTD Stops', language: language);
      case ExploreMapType.MyLocations:         return Localization().getStringEx('panel.explore.button.my_locations.title', 'My Locations', language: language);
      case ExploreMapType.MentalHealth:        return Localization().getStringEx('panel.explore.button.mental_health.title', 'Find a Therapist', language: language);
      case ExploreMapType.StoriedSites:        return Localization().getStringEx('panel.explore.button.stored_sites.title', 'Storied Sites', language: language);
    }
  }

  String get _displayHint {
    switch (this) {
      case ExploreMapType.Events2:             return Localization().getStringEx('panel.explore.button.events2.hint', '');
      case ExploreMapType.Dining:              return Localization().getStringEx('panel.explore.button.dining.hint', '');
      case ExploreMapType.Laundry:             return Localization().getStringEx('panel.explore.button.laundry.hint', '');
      case ExploreMapType.Buildings:           return Localization().getStringEx('panel.explore.button.buildings.hint', '');
      case ExploreMapType.StudentCourse:       return Localization().getStringEx('panel.explore.button.student_course.hint', '');
      case ExploreMapType.Appointments:        return Localization().getStringEx('panel.explore.button.appointments.hint', '');
      case ExploreMapType.MTDStops:            return Localization().getStringEx('panel.explore.button.mtd_stops.hint', '');
      case ExploreMapType.MyLocations:         return Localization().getStringEx('panel.explore.button.my_locations.hint', '');
      case ExploreMapType.MentalHealth:        return Localization().getStringEx('panel.explore.button.mental_health.hint', '');
      case ExploreMapType.StoriedSites:        return Localization().getStringEx('panel.explore.button.stored_sites.hint', '');
    }
  }

  String get _displayEmptyContentMessage {
    switch (this) {
      case ExploreMapType.Events2: return Localization().getStringEx('panel.explore.state.online.empty.events2', 'No events are available.');
      case ExploreMapType.Dining: return Localization().getStringEx('panel.explore.state.online.empty.dining', 'No dining locations are currently open.');
      case ExploreMapType.Laundry: return Localization().getStringEx('panel.explore.state.online.empty.laundry', 'No laundry locations are currently open.');
      case ExploreMapType.Buildings: return Localization().getStringEx('panel.explore.state.online.empty.buildings', 'No building locations available.');
      case ExploreMapType.StudentCourse: return Localization().getStringEx('panel.explore.state.online.empty.student_course', 'No student courses registered.');
      case ExploreMapType.Appointments: return Localization().getStringEx('panel.explore.state.online.empty.appointments', 'No appointments available.');
      case ExploreMapType.MTDStops: return Localization().getStringEx('panel.explore.state.online.empty.mtd_stops', 'No MTD stop locations available.');
      case ExploreMapType.MyLocations: return Localization().getStringEx('panel.explore.state.online.empty.my_locations', 'No saved locations available.');
      case ExploreMapType.MentalHealth: return Localization().getStringEx('panel.explore.state.online.empty.mental_health', 'No therapist locations are available.');
      case ExploreMapType.StoriedSites: return Localization().getStringEx('panel.explore.state.online.empty.stored_sites', 'No storied sites are available.');
    }
  }

  String get _displayFailedContentMessage {
    switch (this) {
      case ExploreMapType.Events2: return Localization().getStringEx('panel.explore.state.failed.events2', 'Failed to load all events.');
      case ExploreMapType.Dining: return Localization().getStringEx('panel.explore.state.failed.dining', 'Failed to load dining locations.');
      case ExploreMapType.Laundry: return Localization().getStringEx('panel.explore.state.failed.laundry', 'Failed to load laundry locations.');
      case ExploreMapType.Buildings: return Localization().getStringEx('panel.explore.state.failed.buildings', 'Failed to load building locations.');
      case ExploreMapType.StudentCourse: return Localization().getStringEx('panel.explore.state.failed.student_course', 'Failed to load student courses.');
      case ExploreMapType.Appointments: return Localization().getStringEx('panel.explore.state.failed.appointments', 'Failed to load appointments.');
      case ExploreMapType.MTDStops: return Localization().getStringEx('panel.explore.state.failed.mtd_stops', 'Failed to load MTD stop locations.');
      case ExploreMapType.MyLocations: return Localization().getStringEx('panel.explore.state.failed.my_locations', 'Failed to load saved locations.');
      case ExploreMapType.MentalHealth: return Localization().getStringEx('panel.explore.state.failed.mental_health', 'Failed to load therapist locations.');
      case ExploreMapType.StoriedSites: return Localization().getStringEx('panel.explore.state.failed.stored_sites', 'Failed to load storied sites.');
    }
  }

  /*String get _displayOfflineContentMessage {
    switch (this) {
      case ExploreMapType.Events2:             return Localization().getStringEx('panel.explore.state.offline.empty.events2', 'No events feed is available while offline.');
      case ExploreMapType.Dining:              return Localization().getStringEx('panel.explore.state.offline.empty.dining', 'No dining locations available while offline.');
      case ExploreMapType.Laundry:             return Localization().getStringEx('panel.explore.state.offline.empty.laundry', 'No laundry locations available while offline.');
      case ExploreMapType.Buildings:           return Localization().getStringEx('panel.explore.state.offline.empty.buildings', 'No building locations available while offline.');
      case ExploreMapType.StudentCourse:       return Localization().getStringEx('panel.explore.state.offline.empty.student_course', 'No student courses available while offline.');
      case ExploreMapType.Appointments:        return Localization().getStringEx('panel.explore.state.offline.empty.appointments', 'No appointments available while offline.');
      case ExploreMapType.MTDStops:            return Localization().getStringEx('panel.explore.state.offline.empty.mtd_stops', 'No MTD stop locations available while offline.');
      case ExploreMapType.MyLocations:         return Localization().getStringEx('panel.explore.state.offline.empty.my_locations', 'No saved locations available while offline.');
      case ExploreMapType.MentalHealth:        return Localization().getStringEx('panel.explore.state.offline.empty.mental_health', 'No therapist locations are available while offline.');
      case ExploreMapType.StoriedSites:        return Localization().getStringEx('panel.explore.state.offline.empty.stored_sites', 'No storied sites are available while offline.');
    }
  }*/

  String get jsonString {
    switch (this) {
      case ExploreMapType.Events2:             return 'events2';
      case ExploreMapType.Dining:              return 'dining';
      case ExploreMapType.Laundry:             return 'laundry';
      case ExploreMapType.Buildings:           return 'buildings';
      case ExploreMapType.StudentCourse:       return 'studentCourse';
      case ExploreMapType.Appointments:        return 'appointments';
      case ExploreMapType.MTDStops:            return 'mtdStops';
      case ExploreMapType.MyLocations:         return 'myLocations';
      case ExploreMapType.MentalHealth:        return 'mentalHealth';
      case ExploreMapType.StoriedSites:        return 'storiedSights';
    }
  }

  static ExploreMapType? fromJsonString(String? value) {
    switch (value) {
      case 'events2': return ExploreMapType.Events2;
      case 'dining': return ExploreMapType.Dining;
      case 'laundry': return ExploreMapType.Laundry;
      case 'buildings': return ExploreMapType.Buildings;
      case 'studentCourse': return ExploreMapType.StudentCourse;
      case 'appointments': return ExploreMapType.Appointments;
      case 'mtdStops': return ExploreMapType.MTDStops;
      case 'myLocations': return ExploreMapType.MyLocations;
      case 'mentalHealth': return ExploreMapType.MentalHealth;
      case 'storiedSights': return ExploreMapType.StoriedSites;
      default: return null;
    }
  }

  static ExploreMapType? fromCode(String? value) {
    switch (value) {
      case 'events2': return ExploreMapType.Events2;
      case 'dining': return ExploreMapType.Dining;
      case 'laundry': return ExploreMapType.Laundry;
      case 'buildings': return ExploreMapType.Buildings;
      case 'student_courses': return ExploreMapType.StudentCourse;
      case 'appointments': return ExploreMapType.Appointments;
      case 'mtd_stops': return ExploreMapType.MTDStops;
      case 'my_locations': return ExploreMapType.MyLocations;
      case 'mental_health': return ExploreMapType.MentalHealth;
      case 'storied_sites': return ExploreMapType.StoriedSites;
      default: return null;
    }
  }

  AnalyticsFeature get analyticsFeature {
    switch (this) {
    case ExploreMapType.Events2:             return AnalyticsFeature.MapEvents;
    case ExploreMapType.Dining:              return AnalyticsFeature.MapDining;
    case ExploreMapType.Laundry:             return AnalyticsFeature.MapLaundry;
    case ExploreMapType.Buildings:           return AnalyticsFeature.MapBuildings;
    case ExploreMapType.StudentCourse:       return AnalyticsFeature.MapStudentCourse;
    case ExploreMapType.Appointments:        return AnalyticsFeature.MapAppointments;
    case ExploreMapType.MTDStops:            return AnalyticsFeature.MapMTDStops;
    case ExploreMapType.MyLocations:         return AnalyticsFeature.MapMyLocations;
    case ExploreMapType.MentalHealth:        return AnalyticsFeature.MapMentalHealth;
    case ExploreMapType.StoriedSites:        return AnalyticsFeature.StoriedSites;
    }
  }

  ExploreMapType? _ensure({List<ExploreMapType>? availableTypes}) =>
      (availableTypes?.contains(this) != false) ? this : null;
}

extension _ExploreMapTypeList on List<ExploreMapType> {
  void sortAlphabetical() => sort((ExploreMapType t1, ExploreMapType t2) => t1.displayTitle.compareTo(t2.displayTitle));
}

extension _StorageMapExt on Storage {
  ExploreMapType? get _selectedMapExploreType => ExploreMapTypeImpl.fromJsonString(Storage().selectedMapExploreType);
  set _selectedMapExploreType(ExploreMapType? value) => Storage().selectedMapExploreType = value?.jsonString;
}
