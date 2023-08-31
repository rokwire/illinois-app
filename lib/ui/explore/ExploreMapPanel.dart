
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ext/Explore.dart';
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
import 'package:illinois/ui/explore/ExploreListPanel.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/Filters.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
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
import 'package:timezone/timezone.dart';

enum ExploreMapType { Events2, Dining, Laundry, Buildings, StudentCourse, Appointments, MTDStops, MTDDestinations, MentalHealth, StateFarmWayfinding }

class ExploreMapPanel extends StatefulWidget {
  static const String notifySelect = "edu.illinois.rokwire.explore.map.select";
  static const String selectParamKey = "select-param";

  final Map<String, dynamic> params = <String, dynamic>{};

  ExploreMapPanel();
  
  @override
  State<StatefulWidget> createState() => _ExploreMapPanelState();

  static bool get hasState {
    Set<NotificationsListener>? subscribers = NotificationService().subscribers(ExploreMapPanel.notifySelect);
    if (subscribers != null) {
      for (NotificationsListener subscriber in subscribers) {
        if ((subscriber is _ExploreMapPanelState) && subscriber.mounted) {
          return true;
        }
      }
    }
    return false;
  }
}

class _ExploreMapPanelState extends State<ExploreMapPanel>
  with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin<ExploreMapPanel>
  implements NotificationsListener {

  static const double _filterLayoutSortKey = 1.0;
  static const ExploreMapType _defaultMapType = ExploreMapType.Buildings;

  List<ExploreMapType> _exploreTypes = [];
  ExploreMapType _selectedMapType = _defaultMapType;
  EventsDisplayType? _selectedEventsDisplayType;

  late Event2TimeFilter _event2TimeFilter;
  TZDateTime? _event2CustomStartTime;
  TZDateTime? _event2CustomEndTime;
  late LinkedHashSet<Event2TypeFilter> _event2Types;
  late Map<String, dynamic> _event2Attributes;
  String? _event2SearchText;

  List<StudentCourseTerm>? _studentCourseTerms;
  
  List<String>? _filterWorkTimeValues;
  List<String>? _filterPaymentTypeValues;
  List<String>? _filterEventTimeValues;
  
  Map<ExploreMapType, List<ExploreFilter>>? _itemToFilterMap;
  
  bool _itemsDropDownValuesVisible = false;
  bool _eventsDisplayDropDownValuesVisible = false;
  bool _filtersDropdownVisible = false;
  
  List<Explore>? _explores;
  bool _exploreProgress = false;
  Future<List<Explore>?>? _exploreTask;

  final GlobalKey _mapContainerKey = GlobalKey();
  final GlobalKey _mapExploreBarKey = GlobalKey();
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
  String? _targetMapStyle, _lastMapStyle;
  Set<dynamic>? _exploreMarkerGroups;
  Set<Marker>? _targetMarkers;
  bool _markersProgress = false;
  Future<Set<Marker>?>? _buildMarkersTask;
  Explore? _pinnedMapExplore;
  dynamic _selectedMapExplore;
  AnimationController? _mapExploreBarAnimationController;
  
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
    
    _exploreTypes = _buildExploreTypes();
    _selectedMapType = _ensureExploreType(_initialExploreType) ?? _ensureExploreType(_lastExploreType) ?? _defaultMapType;
    _selectedEventsDisplayType = EventsDisplayType.single;
    
    _event2TimeFilter = event2TimeFilterFromString(Storage().events2Time) ?? Event2TimeFilter.upcoming;
    _event2CustomStartTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomStartTime));
    _event2CustomEndTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomEndTime));
    _event2Types = LinkedHashSetUtils.from<Event2TypeFilter>(event2TypeFilterListFromStringList(Storage().events2Types)) ?? LinkedHashSet<Event2TypeFilter>();
    _event2Attributes = Storage().events2Attributes ?? <String, dynamic>{};
    _event2SearchText = _intialEvent2SearchParam?.searchText;

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
      if ((_selectedMapType == ExploreMapType.StudentCourse) && mounted) {
        _refreshExplores();
      }
    }
    else if (name == StudentCourses.notifySelectedTermChanged) {
      applyStateIfMounted(() {
        _updateSelectedTermId();
      });
      if ((_selectedMapType == ExploreMapType.StudentCourse) && mounted) {
        _refreshExplores();
      }
    }
    else if (name == StudentCourses.notifyCachedCoursesChanged) {
      String? termId = param;
      if ((_selectedMapType == ExploreMapType.StudentCourse) && mounted && ((termId == null) || (StudentCourses().displayTermId == termId))) {
        _refreshExplores();
      }
    }
    else if (name == MTD.notifyStopsChanged) {
      if ((_selectedMapType == ExploreMapType.MTDStops) && mounted) {
        _refreshExplores();
      }
    }
    else if (name == Appointments.notifyUpcomingAppointmentsChanged) {
      if ((_selectedMapType == ExploreMapType.Appointments) && mounted) {
        _refreshExplores();
      }
    }
    else if (name == ExploreMapPanel.notifySelect) {
      if (mounted) {
        if ((param is ExploreMapType) && (_selectedMapType != param)) {
          setState(() {
            _selectedMapType = param;
          });
          _initExplores();
        }
        else if (param is ExploreMapSearchEventsParam) {
          if ((_selectedMapType != ExploreMapType.Events2) || (_event2SearchText != param.searchText)) {
            setState(() {
              _selectedMapType = ExploreMapType.Events2;
              _event2SearchText = param.searchText;
            });
            _initExplores();
          }
        }
      }
    }
    else if (name == RootPanel.notifyTabChanged) {
      if ((param == RootTab.Maps) && mounted &&
          (CollectionUtils.isEmpty(_exploreTypes) || (_selectedMapType == ExploreMapType.Events2) || (_selectedMapType == ExploreMapType.Appointments)) // Do not refresh for other ExploreMapType types as they are rarely changed or fire notification for that
      ) {
        _refreshExplores();
      }
    }
    else if (name == Storage.notifySettingChanged) {
      if (param == Storage.debugMapThresholdDistanceKey) {
        _buildMapContentData(_explores, pinnedExplore: _pinnedMapExplore, updateCamera: false, zoom: _lastMarkersUpdateZoom, showProgress: true);
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
      backgroundColor: Styles().colors?.background,
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
            Visibility(visible: (_selectedMapType == ExploreMapType.Events2), child:
              Padding(padding: EdgeInsets.only(top: 8, bottom: 2), child:
                _buildEvents2HeaderBar(),
              ),
            ),
            Expanded(child:
              Stack(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: EdgeInsets.only(left: 12, right: 12, bottom: 12), child:
                    Wrap(children: _buildFilters()),
                  ),
                  Expanded(child:
                    Container(key: _mapContainerKey, color: Styles().colors!.background, child:
                      _buildContent(),
                    ),
                  ),
                ]),
                _buildEventsDisplayTypesDropDownContainer(),
                _buildFilterValuesContainer()
              ]),
            ),
          ]),
          _buildExploreTypesDropDownContainer()
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
      return _buildMessageContent(_failedContentMessage ?? '');
    }
    else if (_explores!.isEmpty) {
      return _buildMessageContent(_emptyContentMessage ?? '');
    }*/
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
    else if (_selectedMapType == ExploreMapType.MTDDestinations) {
      _selectMapExplore(ExplorePOI(location: ExploreLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)));
    }
  }

  void _onMapPoiTap(PointOfInterest poi) {
    debugPrint('ExploreMap POI tap' );
    MTDStop? mtdStop = MTD().stops?.findStop(location: Native.LatLng(latitude: poi.position.latitude, longitude: poi.position.longitude), locationThresholdDistance: 25 /*in meters*/);
    if (mtdStop != null) {
      _selectMapExplore(mtdStop);
    }
    else if (_selectedMapType == ExploreMapType.MTDDestinations) {
      _selectMapExplore(ExplorePOI(placeId: poi.placeId, name: poi.name, location: ExploreLocation(latitude: poi.position.latitude, longitude: poi.position.longitude)));
    }
    else if (_selectedMapExplore != null) {
      _selectMapExplore(null);
    }
  }

  void _onTapMarker(dynamic origin) {
    _selectMapExplore(origin);
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
      exploreColor = (_selectedMapExplore as Explore).uiColor ?? Styles().colors?.white;
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
      exploreColor = explore?.uiColor ?? Styles().colors?.fillColorSecondary;
    }
    else {
      exploreColor = Styles().colors?.white;
      canDirections = canDetail = false;
    }

    double buttonWidth = (MediaQuery.of(context).size.width - (40 + 12)) / 2;

    double barHeight = _mapExploreBarSize?.height ?? 0;
    double wrapHeight = _mapSize?.height ?? 0;
    double progress = _mapExploreBarAnimationController?.value ?? 0;
    double top = wrapHeight - (progress * barHeight);

    return Positioned(top: top, left: 0, right: 0, child:
      Container(key: _mapExploreBarKey, decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: exploreColor!, width: 2, style: BorderStyle.solid), bottom: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1, style: BorderStyle.solid),),), child:
        Stack(children: [
          Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Padding(padding: EdgeInsets.only(right: 10), child:
                Text(title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: Styles().textStyles?.getTextStyle("widget.title.large.extra_fat")),
              ),
              (descriptionWidget != null) ?
                Row(children: <Widget>[
                  Text(description ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: Styles().textStyles?.getTextStyle("panel.event_schedule.map.description")),
                  descriptionWidget
                ]) :
                Text(description ?? "", overflow: TextOverflow.ellipsis, style: Styles().textStyles?.getTextStyle("panel.event_schedule.map.description")),
              Container(height: 8,),
              Row(children: <Widget>[
                SizedBox(width: buttonWidth, child:
                  RoundedButton(
                    label: Localization().getStringEx('panel.explore.button.directions.title', 'Directions'),
                    hint: Localization().getStringEx('panel.explore.button.directions.hint', ''),
                    textStyle: canDirections ? Styles().textStyles?.getTextStyle("widget.button.title.enabled") : Styles().textStyles?.getTextStyle("widget.button.title.disabled"),
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    borderColor: canDirections ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
                    onTap: _onTapMapExploreDirections
                  ),
                ),
                Container(width: 12,),
                SizedBox(width: buttonWidth, child:
                  RoundedButton(
                    label: detailsLabel,
                    hint: detailsHint,
                    textStyle: canDirections ? Styles().textStyles?.getTextStyle("widget.button.title.enabled") : Styles().textStyles?.getTextStyle("widget.button.title.disabled"),
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
    );
  }

  void _onTapMapExploreDirections() async {
    Analytics().logSelect(target: 'Directions');
    
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
      AppAlert.showMessage(context, Localization().getStringEx("panel.explore.directions.failed.msg", "Failed to launch navigation directions."));  
    }
    
    // AppAlert.showMessage(context, Localization().getStringEx("panel.explore.directions.na.msg", "You need to enable location services in order to get navigation directions."));
  }
  
  void _onTapMapExploreDetail() {
    Analytics().logSelect(target: (_selectedMapExplore is MTDStop) ? 'Bus Schedule' : 'Details');
    if (_selectedMapExplore is Explore) {
        (_selectedMapExplore as Explore).exploreLaunchDetail(context);
    }
    else if (_selectedMapExplore is List<Explore>) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreListPanel(explores: _selectedMapExplore, exploreMapType: _selectedMapType,),));
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
    if (explore is Explore) {
      exploreTarget = explore.exploreTitle ?? explore.exploreLocation?.name ?? explore.exploreLocation?.displayAddress ?? explore.exploreLocation?.displayCoordinates;
    }
    else if (explore is List<Explore>) {
      exploreTarget = '${explore.length} ${ExploreExt.getExploresListDisplayTitle(explore, language: 'en')}';
    }
    Analytics().logMapSelect(target: exploreTarget);
  }

  Widget? _buildExploreBarStopDescription() {
    if (_loadingMapStopIdRoutes != null) {
      return Padding(padding: EdgeInsets.only(left: 8, top: 3, bottom: 2), child:
        SizedBox(width: 16, height: 16, child:
          CircularProgressIndicator(color: Styles().colors?.mtdColor, strokeWidth: 2,),
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
                  Text(route.shortName ?? '', overflow: TextOverflow.ellipsis, style: Styles().textStyles?.getTextStyle("widget.item.tiny.extra_fat")?.copyWith(color: route.textColor)),
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
          CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 3,),
        ),
        Expanded(flex: 1, child: Container(),),
      ],)
    );
  }

  /*Widget _buildMessageContent(String message) {
    return Column(children: [
      Expanded(flex: 1, child: Container(),),
      Padding(padding: EdgeInsets.symmetric(horizontal: 32), child:
        Text(message, textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18)),
      ),
      Expanded(flex: 2, child: Container(),),
    ],);
  }*/

  void _showMessagePopup(String? message) {
    if ((message != null) && message.isNotEmpty) {
      showDialog(context: context, builder: (context) => AlertDialog(contentPadding: EdgeInsets.zero, content: 
        Container(decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: BorderRadius.circular(10.0)), child:
          Stack(alignment: Alignment.center, fit: StackFit.loose, children: [
            Padding(padding: EdgeInsets.all(30), child:
              Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                Styles().images?.getImage('university-logo') ?? Container(),
                Padding(padding: EdgeInsets.only(top: 20), child:
                  Text(message, textAlign: TextAlign.center, style:
                    Styles().textStyles?.getTextStyle("widget.detail.small")
                  )
                )
              ])
            ),
            Positioned.fill(child:
              Align(alignment: Alignment.topRight, child:
                InkWell(onTap: () => _onCloseMessagePopup(message), child:
                  Padding(padding: EdgeInsets.all(16), child:
                    Styles().images?.getImage("close")
                  )
                )
              )
            )
          ])
        )
      ));
    }
  }

  void _showOptionalMessagePopup(String message, { String? showPopupStorageKey }) {
    showDialog(context: context, builder: (context) => ExploreOptionalMessagePopup(
      message: message,
      showPopupStorageKey: showPopupStorageKey,
    ));
  }

  void _onCloseMessagePopup(String message) {
    Analytics().logSelect(target: 'Close $message');
    Navigator.of(context).pop();
  }

  // Events2 - Data

  Widget _buildEvents2HeaderBar() => Column(children: [
    _buildEvents2CommandButtons(),
    _buildEvents2ContentDescription(),
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
            textStyle: Styles().textStyles?.getTextStyle('widget.button.title.regular.underline'),
          ),
        ),
        Visibility(visible: Auth2().account?.isCalendarAdmin ?? false, child:
          Event2ImageCommandButton('plus-circle',
            label: Localization().getStringEx('panel.events2.home.bar.button.create.title', 'Create'),
            hint: Localization().getStringEx('panel.events2.home.bar.button.create.hint', 'Tap to create event'),
            contentPadding: EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 16),
            onTap: _onEvent2Create
          ),
        ),
        Event2ImageCommandButton('search',
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
    TextStyle? boldStyle = Styles().textStyles?.getTextStyle("widget.card.title.tiny.fat");
    TextStyle? regularStyle = Styles().textStyles?.getTextStyle("widget.card.detail.small.regular");

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
        
        Storage().events2Time = event2TimeFilterToString(_event2TimeFilter);
        Storage().events2CustomStartTime = JsonUtils.encode(_event2CustomStartTime?.toJson());
        Storage().events2CustomEndTime = JsonUtils.encode(_event2CustomEndTime?.toJson());
        Storage().events2Types = event2TypeFilterListToStringList(_event2Types.toList());
        Storage().events2Attributes = _event2Attributes;

        Event2FilterParam.notifySubscribersChanged(except: this);

        _refreshExplores();
      }
    });
  }

  void _updateEvent2Filers() {
    Event2TimeFilter? timeFilter = event2TimeFilterFromString(Storage().events2Time);
    TZDateTime? customStartTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomStartTime));
    TZDateTime? customEndTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomEndTime));
    LinkedHashSet<Event2TypeFilter>? types = LinkedHashSetUtils.from<Event2TypeFilter>(event2TypeFilterListFromStringList(Storage().events2Types));
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
    Event2HomePanel.present(context);
  }

  // Dropdown Widgets

  Widget _buildExploreTypesDropDownButton() {
    return RibbonButton(
      textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat.secondary"),
      backgroundColor: Styles().colors!.white,
      borderRadius: BorderRadius.all(Radius.circular(5)),
      border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
      rightIconKey: (_itemsDropDownValuesVisible ? 'chevron-up' : 'chevron-down'),
      label: _exploreItemName(_selectedMapType),
      hint: _exploreItemHint(_selectedMapType),
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
          Container(color: Styles().colors!.blackTransparent06)
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
      Container(color: Styles().colors!.fillColorSecondary, height: 2)
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
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
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
          Container(color: Styles().colors!.blackTransparent06)
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
      Container(color: Styles().colors!.fillColorSecondary, height: 2),
    ];
    for (ExploreMapType exploreItem in _exploreTypes) {
      if ((_selectedMapType != exploreItem)) {
        itemList.add(_buildExploreDropDownItem(exploreItem));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: itemList)
      )
    );
  }

  Widget _buildExploreDropDownItem(ExploreMapType exploreItem) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconKey: null,
        label: _exploreItemName(exploreItem),
        onTap: () => _onTapExploreType(exploreItem)
      );
  }

  void _onTapExploreType(ExploreMapType item) {
    Analytics().logSelect(target: _exploreItemName(item));
    ExploreMapType? lastExploreType = _selectedMapType;
    Storage().selectedMapExploreType = exploreMapTypeToString(item);
    setStateIfMounted(() {
      _clearActiveFilter();
      _selectedMapType = _lastExploreType = item;
      _itemsDropDownValuesVisible = false;
    });
    if (lastExploreType != item) {
      _targetMapStyle = _currentMapStyle;
      _initExplores();
    }
  }

  // Filter Widgets

  List<Widget> _buildFilters() {
    List<Widget> filterTypeWidgets = [];
    List<ExploreFilter>? visibleFilters = (_itemToFilterMap != null) ? _itemToFilterMap![_selectedMapType] : null;
    if ((visibleFilters == null ) || visibleFilters.isEmpty) {
      filterTypeWidgets.add(Container());
    }
    else {
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
    }
    return filterTypeWidgets;
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
              Container(decoration: BoxDecoration(color: Styles().colors!.fillColorSecondary, borderRadius: BorderRadius.circular(5.0),), child:
                Padding(padding: EdgeInsets.only(top: 2), child:
                  Container(color: Colors.white, child:
                    ListView.separated(
                      shrinkWrap: true,
                      separatorBuilder: (context, index) => Divider(height: 1, color: Styles().colors!.fillColorPrimaryTransparent03,),
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

  List<ExploreMapType> _buildExploreTypes() {
    List<ExploreMapType> exploreTypes = [];
    List<dynamic>? codes = FlexUI()['explore.map'];
    if (codes != null) {
      for (dynamic code in codes) {
        if (code == 'events2') {
          exploreTypes.add(ExploreMapType.Events2);
        }
        else if (code == 'dining') {
          exploreTypes.add(ExploreMapType.Dining);
        }
        else if (code == 'laundry') {
          exploreTypes.add(ExploreMapType.Laundry);
        }
        else if (code == 'buildings') {
          exploreTypes.add(ExploreMapType.Buildings);
        }
        else if (code == 'student_courses') {
          exploreTypes.add(ExploreMapType.StudentCourse);
        }
        else if (code == 'appointments') {
          exploreTypes.add(ExploreMapType.Appointments);
        }
        else if (code == 'mtd_stops') {
          exploreTypes.add(ExploreMapType.MTDStops);
        }
        else if (code == 'mtd_destinations') {
          exploreTypes.add(ExploreMapType.MTDDestinations);
        }
        else if (code == 'mental_health') {
          exploreTypes.add(ExploreMapType.MentalHealth);
        }
        else if (code == 'state_farm_wayfinding') {
          exploreTypes.add(ExploreMapType.StateFarmWayfinding);
        }
      }
    }
    return exploreTypes;
  }

  void _updateExploreTypes() {
    List<ExploreMapType> exploreTypes = _buildExploreTypes();
    if (!DeepCollectionEquality().equals(_exploreTypes, exploreTypes)) {
      if (exploreTypes.contains(_selectedMapType)) {
        setStateIfMounted(() {
          _exploreTypes = exploreTypes;
        });
      }
      else {
        ExploreMapType selectedMapType = _defaultMapType;
        setStateIfMounted(() {
          _exploreTypes = exploreTypes;
          _selectedMapType = selectedMapType;
        });
        _initExplores();
      }
    }
  }
  ExploreMapType? _ensureExploreType(ExploreMapType? exploreItem, { List<ExploreMapType>? exploreTypes}) {
    exploreTypes ??= _exploreTypes;
    return ((exploreItem != null) && exploreTypes.contains(exploreItem)) ? exploreItem : null;

  }

  ExploreMapType? get _initialExploreType => _paramExploreType(widget.params[ExploreMapPanel.selectParamKey]);

  static ExploreMapType? _paramExploreType(dynamic param) {
    if (param is ExploreMapType) {
      return param;
    }
    else if (param is ExploreMapSearchEventsParam) {
      return ExploreMapType.Events2;
    }
    else {
      return null;
    }
  }

  ExploreMapSearchEventsParam? get _intialEvent2SearchParam => _paramSearchEvents2(widget.params[ExploreMapPanel.selectParamKey]);

  static ExploreMapSearchEventsParam? _paramSearchEvents2(dynamic param) => (param is ExploreMapSearchEventsParam) ? param : null;

  ExploreMapType? get _lastExploreType => exploreMapItemFromString(Storage().selectedMapExploreType);
  
  set _lastExploreType(ExploreMapType? value) => Storage().selectedMapExploreType = exploreMapTypeToString(value);

  static String? _exploreItemName(ExploreMapType? exploreItem) {
    switch (exploreItem) {
      case ExploreMapType.Events2:             return Localization().getStringEx('panel.explore.button.events2.title', 'All Events');
      case ExploreMapType.Dining:              return Localization().getStringEx('panel.explore.button.dining.title', 'Residence Hall Dining');
      case ExploreMapType.Laundry:             return Localization().getStringEx('panel.explore.button.laundry.title', 'Laundry');
      case ExploreMapType.Buildings:           return Localization().getStringEx('panel.explore.button.buildings.title', 'Campus Buildings');
      case ExploreMapType.StudentCourse:       return Localization().getStringEx('panel.explore.button.student_course.title', 'My Courses');
      case ExploreMapType.Appointments:        return Localization().getStringEx('panel.explore.button.appointments.title', 'MyMcKinley In-Person Appointments');
      case ExploreMapType.MTDStops:            return Localization().getStringEx('panel.explore.button.mtd_stops.title', 'MTD Stops');
      case ExploreMapType.MTDDestinations:     return Localization().getStringEx('panel.explore.button.mtd_destinations.title', 'MTD Destinations');
      case ExploreMapType.MentalHealth:        return Localization().getStringEx('panel.explore.button.mental_health.title', 'Find a Therapist');
      case ExploreMapType.StateFarmWayfinding: return Localization().getStringEx('panel.explore.button.state_farm.title', 'State Farm Wayfinding');
      default:                              return null;
    }
  }

  static String? _exploreItemHint(ExploreMapType? exploreItem) {
    switch (exploreItem) {
      case ExploreMapType.Events2:             return Localization().getStringEx('panel.explore.button.events2.hint', '');
      case ExploreMapType.Dining:              return Localization().getStringEx('panel.explore.button.dining.hint', '');
      case ExploreMapType.Laundry:             return Localization().getStringEx('panel.explore.button.laundry.hint', '');
      case ExploreMapType.Buildings:           return Localization().getStringEx('panel.explore.button.buildings.hint', '');
      case ExploreMapType.StudentCourse:       return Localization().getStringEx('panel.explore.button.student_course.hint', '');
      case ExploreMapType.Appointments:        return Localization().getStringEx('panel.explore.button.appointments.hint', '');
      case ExploreMapType.MTDStops:            return Localization().getStringEx('panel.explore.button.mtd_stops.hint', '');
      case ExploreMapType.MTDDestinations:     return Localization().getStringEx('panel.explore.button.mtd_destinations.hint', '');
      case ExploreMapType.MentalHealth:        return Localization().getStringEx('panel.explore.button.mental_health.hint', '');
      case ExploreMapType.StateFarmWayfinding: return Localization().getStringEx('panel.explore.button.state_farm.hint', '');
      default:                              return null;
    }
  }

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

  void _clearActiveFilter() {
    List<ExploreFilter>? itemFilters = (_itemToFilterMap != null) ? _itemToFilterMap![_selectedMapType] : null;
    if (itemFilters != null && itemFilters.isNotEmpty) {
      for (ExploreFilter filter in itemFilters) {
        filter.active = false;
      }
    }
    _filtersDropdownVisible = false;
  }

  void _toggleActiveFilter(ExploreFilter selectedFilter) {
    _clearActiveFilter();
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

  // Content Data

  /*String? get _offlineContentMessage {
    switch (_selectedMapType) {
      case ExploreMapType.Events:              return Localization().getStringEx('panel.explore.state.offline.empty.events', 'No upcoming events available while offline.');
      case ExploreMapType.Events2:             return Localization().getStringEx('panel.explore.state.offline.empty.events2', 'No events feed is available while offline.');
      case ExploreMapType.Dining:              return Localization().getStringEx('panel.explore.state.offline.empty.dining', 'No dining locations available while offline.');
      case ExploreMapType.Laundry:             return Localization().getStringEx('panel.explore.state.offline.empty.laundry', 'No laundry locations available while offline.');
      case ExploreMapType.Buildings:           return Localization().getStringEx('panel.explore.state.offline.empty.buildings', 'No building locations available while offline.');
      case ExploreMapType.StudentCourse:       return Localization().getStringEx('panel.explore.state.offline.empty.student_course', 'No student courses available while offline.');
      case ExploreMapType.Appointments:        return Localization().getStringEx('panel.explore.state.offline.empty.appointments', 'No appointments available while offline.');
      case ExploreMapType.MTDStops:            return Localization().getStringEx('panel.explore.state.offline.empty.mtd_stops', 'No MTD stop locations available while offline.');
      case ExploreMapType.MTDDestinations:     return Localization().getStringEx('panel.explore.state.offline.empty.mtd_destinations', 'No MTD destinaion locations available while offline.');
      case ExploreMapType.MentalHealth:        return Localization().getStringEx('panel.explore.state.offline.empty.mental_health', 'No therapist locations are available while offline.');
      case ExploreMapType.StateFarmWayfinding: return Localization().getStringEx('panel.explore.state.offline.empty.state_farm', 'No State Farm Wayfinding available while offline.');
      default:                              return null;
    }
  }*/

  String? get _emptyContentMessage {
    switch (_selectedMapType) {
      case ExploreMapType.Events2: return Localization().getStringEx('panel.explore.state.online.empty.events2', 'No events are available.');
      case ExploreMapType.Dining: return Localization().getStringEx('panel.explore.state.online.empty.dining', 'No dining locations are currently open.');
      case ExploreMapType.Laundry: return Localization().getStringEx('panel.explore.state.online.empty.laundry', 'No laundry locations are currently open.');
      case ExploreMapType.Buildings: return Localization().getStringEx('panel.explore.state.online.empty.buildings', 'No building locations available.');
      case ExploreMapType.StudentCourse: return Localization().getStringEx('panel.explore.state.online.empty.student_course', 'No student courses registered.');
      case ExploreMapType.Appointments: return Localization().getStringEx('panel.explore.state.online.empty.appointments', 'No appointments available.');
      case ExploreMapType.MTDStops: return Localization().getStringEx('panel.explore.state.online.empty.mtd_stops', 'No MTD stop locations available.');
      case ExploreMapType.MTDDestinations: return Localization().getStringEx('panel.explore.state.online.empty.mtd_destinations', 'No MTD destinaion locations available.');
      case ExploreMapType.MentalHealth: return Localization().getStringEx('panel.explore.state.online.empty.mental_health', 'No therapist locations are available.');
      case ExploreMapType.StateFarmWayfinding: return Localization().getStringEx('panel.explore.state.online.empty.state_farm', 'No State Farm Wayfinding available.');
      default:  return null;
    }
  }

  String? get _failedContentMessage {
    switch (_selectedMapType) {
      case ExploreMapType.Events2: return Localization().getStringEx('panel.explore.state.failed.events2', 'Failed to load all events.');
      case ExploreMapType.Dining: return Localization().getStringEx('panel.explore.state.failed.dining', 'Failed to load dining locations.');
      case ExploreMapType.Laundry: return Localization().getStringEx('panel.explore.state.failed.laundry', 'Failed to load laundry locations.');
      case ExploreMapType.Buildings: return Localization().getStringEx('panel.explore.state.failed.buildings', 'Failed to load building locations.');
      case ExploreMapType.StudentCourse: return Localization().getStringEx('panel.explore.state.failed.student_course', 'Failed to load student courses.');
      case ExploreMapType.Appointments: return Localization().getStringEx('panel.explore.state.failed.appointments', 'Failed to load appointments.');
      case ExploreMapType.MTDStops: return Localization().getStringEx('panel.explore.state.failed.mtd_stops', 'Failed to load MTD stop locations.');
      case ExploreMapType.MTDDestinations: return Localization().getStringEx('panel.explore.state.failed.mtd_destinations', 'Failed to load MTD destinaion locations.');
      case ExploreMapType.MentalHealth: return Localization().getStringEx('panel.explore.state.failed.mental_health', 'Failed to load therapist locations.');
      case ExploreMapType.StateFarmWayfinding: return Localization().getStringEx('panel.explore.state.failed.state_farm', 'Failed to load State Farm Wayfinding.');
      default:  return null;
    }
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
          _exploreTask = null;
          _exploreProgress = false;
          _mapKey = UniqueKey(); // force map rebuild
        });
        _selectMapExplore(null);
        _displayContentPopups();
     }
    }
  }

  Future<void> _refreshExplores() async {
    Future<List<Explore>?> exploreTask = _loadExplores();
    List<Explore>? explores = await (_exploreTask = exploreTask);
    if (mounted && (exploreTask == _exploreTask) && !DeepCollectionEquality().equals(_explores, explores)) {
      await _buildMapContentData(explores, pinnedExplore: _pinnedMapExplore, updateCamera: false);
      if (mounted && (exploreTask == _exploreTask)) {
        setState(() {
          _explores = explores;
          _exploreProgress = false;
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
        case ExploreMapType.MTDDestinations: return _loadMTDDestinations();
        case ExploreMapType.MentalHealth: return _loadMentalHealthBuildings();
        case ExploreMapType.StateFarmWayfinding: break;
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
    if (_selectedMapType == ExploreMapType.StateFarmWayfinding) {
      _viewStateFarmPoi();
    }
    else if (_explores == null) {
      _showMessagePopup(_failedContentMessage);
    }
    else if (_selectedMapType == ExploreMapType.Appointments) {
      if (Storage().appointmentsCanDisplay != true) {
        _showMessagePopup(Localization().getStringEx('panel.explore.hide.appointments.msg', 'There is nothing to display as you have chosen not to display any past or future appointments.'));
      } else if (CollectionUtils.isEmpty(_explores)) {
        _showMessagePopup(Localization().getStringEx('panel.explore.missing.appointments.msg','You currently have no upcoming in-person appointments linked within {{app_title}} app.').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')));
      }
    }
    else if (_selectedMapType == ExploreMapType.MTDStops) {
      if (Storage().showMtdStopsMapInstructions != false) {
        _showOptionalMessagePopup(Localization().getStringEx("panel.explore.instructions.mtd_stops.msg", "Please tap a bus stop on the map to get bus schedules. Tap the star to save the bus stop as a favorite."), showPopupStorageKey: Storage().showMtdStopsMapInstructionsKey,
        );
      }
      else if (CollectionUtils.isEmpty(_explores)) {
        _showMessagePopup(Localization().getStringEx('panel.explore.missing.mtd_destinations.msg', 'You currently have no saved destinations. Please tap the location on the map that will be your destination. You can tap the Map to get Directions or Save the destination as a favorite.'),);
      }
    }
    else if (_selectedMapType == ExploreMapType.MTDDestinations) {
      if (Storage().showMtdDestinationsMapInstructions != false) {
        _showOptionalMessagePopup(Localization().getStringEx("panel.explore.instructions.mtd_destinations.msg", "Please tap a location on the map that will be your destination. Tap the star to save the destination as a favorite.",), showPopupStorageKey: Storage().showMtdDestinationsMapInstructionsKey
        );
      }
      else if (CollectionUtils.isEmpty(_explores)) {
        _showMessagePopup(_emptyContentMessage);
      }
    }
    else if (CollectionUtils.isEmpty(_explores)) {
      _showMessagePopup(_emptyContentMessage);
    }
  }

  // Favorites

  void _onFavoritesChanged() {
    if (_selectedMapType == ExploreMapType.MTDDestinations) {
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

  // Map Styles
  
  void _initMapStyles() {
    rootBundle.loadString(_mapStylesAssetName).then((String value) {
      _mapStyles = JsonUtils.decodeMap(value);
      _targetMapStyle = _currentMapStyle;
    }).catchError((_){
    });
  }

  String? get _currentMapStyle {
    if (_mapStyles != null) {
      if ((_selectedMapType == ExploreMapType.Buildings) || (_selectedMapType == ExploreMapType.MentalHealth)) {
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

  void _viewStateFarmPoi() {
    Analytics().logSelect(target: "State Farm Wayfinding");
    Map<String, dynamic> stateFarmLocation = Config().stateFarmWayfinding;
    LatLng location = LatLng(
      JsonUtils.doubleValue(stateFarmLocation['latitude']) ?? 0,
      JsonUtils.doubleValue(stateFarmLocation['longitude']) ?? 0
    );
    double zoom = JsonUtils.doubleValue(stateFarmLocation['zoom']) ?? 0;
    _targetCameraUpdate = CameraUpdate.newCameraPosition(CameraPosition(target: location, zoom: zoom));
    _pinMapExplore(ExplorePOI(name: 'State Farm', location: ExploreLocation( latitude: location.latitude, longitude: location.longitude)));
  }
}

////////////////////
// ExploreMapType


ExploreMapType? exploreMapItemFromString(String? value) {
  if (value == 'events2') {
    return ExploreMapType.Events2;
  }
  else if (value == 'dining') {
    return ExploreMapType.Dining;
  }
  else if (value == 'laundry') {
    return ExploreMapType.Laundry;
  }
  else if (value == 'buildings') {
    return ExploreMapType.Buildings;
  }
  else if (value == 'studentCourse') {
    return ExploreMapType.StudentCourse;
  }
  else if (value == 'appointments') {
    return ExploreMapType.Appointments;
  }
  else if (value == 'mtdStops') {
    return ExploreMapType.MTDStops;
  }
  else if (value == 'mtdDestinations') {
    return ExploreMapType.MTDDestinations;
  }
  else if (value == 'mentalHealth') {
    return ExploreMapType.MentalHealth;
  }
  else if (value == 'stateFarmWayfinding') {
    return ExploreMapType.StateFarmWayfinding;
  }
  else {
    return null;
  }
}

String? exploreMapTypeToString(ExploreMapType? value) {
  switch(value) {
    case ExploreMapType.Events2:             return 'events2';
    case ExploreMapType.Dining:              return 'dining';
    case ExploreMapType.Laundry:             return 'laundry';
    case ExploreMapType.Buildings:           return 'buildings';
    case ExploreMapType.StudentCourse:       return 'studentCourse';
    case ExploreMapType.Appointments:        return 'appointments';
    case ExploreMapType.MTDStops:            return 'mtdStops';
    case ExploreMapType.MTDDestinations:     return 'mtdDestinations';
    case ExploreMapType.MentalHealth:        return 'mentalHealth';
    case ExploreMapType.StateFarmWayfinding: return 'stateFarmWayfinding';
    default: return null;
  }
}

class ExploreMapSearchEventsParam {
  final String searchText;
  ExploreMapSearchEventsParam(this.searchText);
}