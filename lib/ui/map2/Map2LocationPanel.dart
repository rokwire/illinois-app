
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/Gateway.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/events2/Event2HomePanel.dart';
import 'package:illinois/ui/map2/Map2BasePanel.dart';
import 'package:illinois/ui/map2/Map2HomeExts.dart';
import 'package:illinois/ui/map2/Map2HomeFilters.dart';
import 'package:illinois/ui/map2/Map2HomePanel.dart';
import 'package:illinois/ui/map2/Map2TraySheet.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/places.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Map2LocationPanel extends StatefulWidget with AnalyticsInfo {

  static const String routeName = "Map2LocationPanel";

  final Map2ContentType? contentType;
  final Explore? selectedLocation;
  final AnalyticsFeature? _analyticsFeature;

  Map2LocationPanel({ Key? key, this.contentType = Map2ContentType.CampusBuildings, this.selectedLocation, AnalyticsFeature? analyticsFeature }) :
    _analyticsFeature = analyticsFeature;

  static Future<Explore?> push(BuildContext context, { Explore? selectedLocation }) =>
    Navigator.push<Explore>(context, CupertinoPageRoute(
      settings: RouteSettings(name: routeName),
      builder: (context) => Map2LocationPanel(
        selectedLocation: selectedLocation,
      ),
    ));

  @override
  AnalyticsFeature? get analyticsFeature => _analyticsFeature ?? Map2ContentType.CampusBuildings.analyticsFeature; // ?? AnalyticsFeature.Map;

  @override
  State<StatefulWidget> createState() => _Map2LocationPanelState();
}

class _Map2LocationPanelState extends Map2BasePanelState<Map2LocationPanel>
  with SingleTickerProviderStateMixin
{

  final GlobalKey _scaffoldKey = GlobalKey();
  final GlobalKey _traySheetKey = GlobalKey();

  final ScrollController _contentTypesScrollController = ScrollController();
  final DraggableScrollableController _traySheetController = DraggableScrollableController();

  List<Explore>? _explores;
  List<Explore>? _trayExplores;
  LoadExploresTask? _exploresTask;
  ExploreProgressType? _exploresProgress;

  Set<Explore>? _selectedExploreGroup;

  Explore? _pinnedExplore;
  Marker? _pinnedMarker;

  Map<String, dynamic>? _mapStyles;

  @override
  void initState() {
    _initMapStyles();
    _initExplores();
    super.initState();
  }

  @override
  void dispose() {
    _traySheetController.dispose();
    _contentTypesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HeaderBar(title: Localization().getStringEx("panel.map.select.header.title", "Select Location")),
    body: RefreshIndicator(onRefresh: _onRefresh, child: _scaffoldBody),
    backgroundColor: Styles().colors.background,
  );

  Widget get _scaffoldBody =>
    Stack(key: _scaffoldKey, children: [
      Positioned.fill(child:
        Visibility(visible: (_exploresProgress == null), child:
          mapView
        ),
      ),

      Positioned.fill(child:
        Visibility(visible: (_exploresProgress == null) && (_trayExplores?.isNotEmpty == true), child:
          _traySheet
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
    ]);

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
        explores: _trayExplores,
        scrollController: scrollController,
        totalCount: _trayTotalCount,
        analyticsFeature: widget.analyticsFeature,
      ),
    );

  // Progress Indicators

  Widget get _mapProgressIndicator => Semantics(
    label: Localization().getStringEx('panel.explore.state.loading.title', 'Loading'),
    hint: Localization().getStringEx('panel.explore.state.loading.hint', 'Please wait'),
    excludeSemantics: true, child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
      ),
  );

  Widget get _exploresProgressIndicator => Semantics(
    label: Localization().getStringEx('panel.explore.state.loading.title', 'Loading'),
    hint: Localization().getStringEx('panel.explore.state.loading.hint', 'Please wait'),
    excludeSemantics: true, child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
      ),
  );

  // Map Overrides

  @override
  Set<Marker>? get mapMarkers => (_pinnedMarker != null) ?
    markers?.union(<Marker>{_pinnedMarker!}) : markers;

  @override
  String? get mapStyle => JsonUtils.encode(_mapStyles?[_mapStylesBuildingsKey]);

  @override
  Size? get mapSize => _scaffoldKey.renderBoxSize;

  @override
  List<Explore>? get mapExplores => _explores;

  @override
  bool isExploreGroupMarkerDisabled(Set<Explore> exploreGroup) =>
    (_pinnedExplore != null) || ((_selectedExploreGroup != null) && (_selectedExploreGroup?.intersection(exploreGroup).isNotEmpty != true));

  @override
  bool isExploreMarkerDisabled(Explore explore) =>
    (_pinnedExplore != null) || (_selectedExploreGroup != null) && (_selectedExploreGroup?.contains(explore) != true);

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
    else {
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
    else {
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
      setState(() {
        _selectedExploreGroup = <Explore>{origin};
      });
      updateMapMarkers();
      _updateTrayExplores();
    }
    else if (origin is Set<Explore>) {
      Analytics().logSelect(target: "Marker: { ${origin.length} items }");
      setState(() {
        _selectedExploreGroup = DeepCollectionEquality().equals(_selectedExploreGroup, origin) ? null : origin;
      });
      updateMapMarkers();
      _updateTrayExplores();
    }
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

  // Map Content

  Future<void> _initExplores({ExploreProgressType progressType = ExploreProgressType.init}) async {
    if (mounted) {
      LoadExploresTask? exploresTask = _loadExplores();
      if (exploresTask != null) {
        // start loading
        setState(() {
          _exploresTask = exploresTask;
          _exploresProgress = progressType;
        });

        // wait for explores load
        List<Explore>? explores = await exploresTask;

        if (mounted && (exploresTask == _exploresTask)) {
          List<Explore>? validExplores = explores?.validList;
          await buildMapContentData(validExplores, updateCamera: true);

          if (mounted && (exploresTask == _exploresTask)) {
            setState(() {
              _explores = validExplores;
              _exploresTask = null;
              _exploresProgress = null;
              mapKey = UniqueKey(); // force map rebuild
            });
            _updateTrayExplores();
          }
        }
      }
      else {
        setState(() {
          _explores = _trayExplores = null;
          _selectedExploreGroup = null;
          _exploresTask = null;
          _exploresProgress = null;

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
      if (exploresTask != null) {
        // start loading
        setState(() {
          _exploresTask = exploresTask;
          markersProgress = true;
        });

        // wait for explores load
        List<Explore>? explores = await exploresTask;
        List<Explore>? validExplores = explores?.validList;

        if (mounted && (exploresTask == _exploresTask)) {
          if (!DeepCollectionEquality().equals(_explores, validExplores)) {

            setState(() {
              _explores = validExplores;
            });

            _updateTrayExplores();

            await buildMapContentData(validExplores, updateCamera: false, showProgress: true);

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

  Future<void> _onRefresh() => _updateExplores();

  LoadExploresTask? _loadExplores() async {
    switch (widget.contentType) {
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
    String? termId = StudentCourses().displayTerm?.id;
    return (termId != null) ? await StudentCourses().loadCourses(termId: termId) : null;
  }

  Future<List<Explore>?> _loadDiningLocations() async =>
    Dinings().loadBackendDinings(false, null, null);

  Future<List<Explore>?> _loadEvents2() async =>
    Events2().loadEventsList(await _event2QueryParam());

  Future<Events2Query> _event2QueryParam() async {
    Event2FilterParam event2Filter = Event2FilterParam.fromStorage();
    return Events2Query(
      searchText: null,
      timeFilter: event2Filter.timeFilter ?? Event2TimeFilter.upcoming,
      customStartTimeUtc: event2Filter.customStartTime?.toUtc(),
      customEndTimeUtc: event2Filter.customEndTime?.toUtc(),
      types: event2Filter.types,
      groupings: Event2Grouping.individualEvents(),
      attributes: event2Filter.attributes,
      //sortType: filter.sortType?.toEvent2SortType(),
      //sortOrder: filter.sortOrder?.toEvent2SortOrder(),
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

  // Map Styles

  static const String _mapStylesAssetName = 'assets/map.styles.json';
  static const String _mapStylesBuildingsKey = 'explore-poi';

  Future<void> _initMapStyles() async {
    _mapStyles = JsonUtils.decodeMap(await rootBundle.loadString(_mapStylesAssetName));
  }

  // Tray Content

  List<Explore>? _buildTrayExploresFromSource({
    Iterable<Explore>? selected,
    Explore? pinned,
  }) => (pinned != null) ? <Explore>[pinned] : _sortExplores(selected);


  List<Explore>? _buildTrayExplores() => _buildTrayExploresFromSource(
    selected: _selectedExploreGroup,
    pinned: _pinnedExplore,
  );

  List<Explore>? _sortExplores(Iterable<Explore>? explores) => (explores != null) ?
    Map2Filter.empty().sort(explores) : null;

  int? get _trayTotalCount {
    if (_pinnedExplore != null) {
      return null;
    }
    else if (_selectedExploreGroup != null) {
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