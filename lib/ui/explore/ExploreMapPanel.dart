
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/Location.dart' as Native;
import 'package:illinois/model/MTD.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Gateway.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/StudentCourses.dart';
import 'package:illinois/ui/explore/ExploreListPanel.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/Filters.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class ExploreMapPanel extends StatefulWidget {
  final ExploreItem? initialContent;

  ExploreMapPanel({this.initialContent});
  
  @override
  State<StatefulWidget> createState() => _ExploreMapPanelState();
}

class _ExploreMapPanelState extends State<ExploreMapPanel> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin<ExploreMapPanel> {

  static const double _filterLayoutSortKey = 1.0;

  List<ExploreItem> _exploreItems = [];
  ExploreItem? _selectedExploreItem;
  EventsDisplayType? _selectedEventsDisplayType;

  List<String>? _eventCategories;
  List<StudentCourseTerm>? _studentCourseTerms;
  
  List<String>? _filterWorkTimeValues;
  List<String>? _filterPaymentTypeValues;
  List<String>? _filterEventTimeValues;
  
  Map<ExploreItem, List<ExploreFilter>>? _itemToFilterMap;
  
  bool _itemsDropDownValuesVisible = false;
  bool _eventsDisplayDropDownValuesVisible = false;
  bool _filtersDropdownVisible = false;
  
  List<Explore>? _explores;
  bool _exploreProgress = false;
  Future<List<Explore>?>? _exploreTask;

  final GlobalKey _mapContainerKey = GlobalKey();
  final String _mapStylesAssetName = 'assets/map.styles.json';
  final String _mapStylesExplorePoiKey = 'explore-poi';
  final String _mapStylesMtdStopKey = 'mtd-stop';
  final Map<String, BitmapDescriptor> _markerIconCache = <String, BitmapDescriptor>{};
  static const CameraPosition _defaultCameraPosition = CameraPosition(target: LatLng(40.102116, -88.227129), zoom: 17);
  static const double _mapBarHeight = 116;
  static const double _mapPadding = 50;
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
  dynamic _selectedMapExplore;
  AnimationController? _mapExploreBarAnimationController;
  
  String? _loadingMapStopIdRoutes;
  List<MTDRoute>? _selectedMapStopRoutes;

  LocationServicesStatus? _locationServicesStatus;
  Map<String, dynamic>? _mapStyles;

  @override
  void initState() {
    _exploreItems = _buildExploreItems();
    _selectedExploreItem = widget.initialContent ?? _lastExploreItem ?? ExploreItem.Events;
    _selectedEventsDisplayType = EventsDisplayType.single;
    
    _initFilters();
    _initMapStyles();
    _initLocationServicesStatus();
    _initExplores();

    _mapExploreBarAnimationController = AnimationController (duration: Duration(milliseconds: 200), lowerBound: -_mapBarHeight, upperBound: 0, vsync: this)
      ..addListener(() {
        setStateIfMounted(() {
        });
      });

    super.initState();
  }

  @override
  void dispose() {
    _mapExploreBarAnimationController?.dispose();
    super.dispose();
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
        _buildExploreItemsDropDownButton(),
      ),
      Expanded(child:
        Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Visibility(visible: (_selectedExploreItem == ExploreItem.Events), child:
              Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 0), child:
                _buildEventsDisplayTypesDropDownButton(),
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
          _buildExploreItemsDropDownContainer()
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
    return GoogleMap(
      key: _mapKey,
      initialCameraPosition: _lastCameraPosition ?? _defaultCameraPosition,
      onMapCreated: _onMapCreated,
      onCameraIdle: _onMapCameraIdle,
      onCameraMove: _onMapCameraMove,
      onTap: _onMapTap,
      compassEnabled: _userLocationEnabled,
      mapToolbarEnabled: Storage().debugMapShowLevels ?? false,
      markers: _targetMarkers ?? const <Marker>{},
    );
  }

  void _onMapCreated(GoogleMapController controller) async {
    debugPrint('ExploreMap created' );
    _mapController = controller;

    if (_targetMapStyle != _lastMapStyle) {
      try { await _mapController?.setMapStyle(_lastMapStyle = _targetMapStyle); }
      catch(e) { debugPrint(e.toString()); }
    }

    if (_targetCameraUpdate != null) {
      await _mapController?.moveCamera(_targetCameraUpdate!);
      _targetCameraUpdate = null;
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
        _buildMapContentData(_explores, updateCamera: false, zoom: value, showProgress: true);
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
    else if ((_selectedExploreItem == ExploreItem.MTDDestinations)) {
      _selectMapExplore(ExplorePOI(location: ExploreLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)));
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
    bool canDirections = _userLocationEnabled, canDetail = true;
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

    return Positioned(bottom: _mapExploreBarAnimationController?.value, left: 0, right: 0, child:
      Container(height: _mapBarHeight, decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: exploreColor!, width: 2, style: BorderStyle.solid), bottom: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1, style: BorderStyle.solid),),), child:
        Stack(children: [
          Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Padding(padding: EdgeInsets.only(right: 10), child:
                Text(title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20, color: Styles().colors!.fillColorPrimary, )),
              ),
              (descriptionWidget != null) ?
                Row(children: <Widget>[
                  Text(description ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Colors.black38,)),
                  descriptionWidget
                ]) :
                Text(description ?? "", overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Colors.black38,)),
              Container(height: 8,),
              Row(children: <Widget>[
                SizedBox(width: buttonWidth, child:
                  RoundedButton(
                    label: Localization().getStringEx('panel.explore.button.directions.title', 'Directions'),
                    hint: Localization().getStringEx('panel.explore.button.directions.hint', ''),
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    fontSize: 16.0,
                    textColor: canDirections ? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent,
                    borderColor: canDirections ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
                    onTap: _onTapMapExploreDirections
                  ),
                ),
                Container(width: 12,),
                SizedBox(width: buttonWidth, child:
                  RoundedButton(
                    label: detailsLabel,
                    hint: detailsHint,
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    fontSize: 16.0,
                    textColor: canDetail ? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent,
                    borderColor: canDetail ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
                    onTap: onTapDetail,
                  ),
                ),
              ],),
            ]),
          ),
          (_selectedMapExplore is Favorite) ?
            Align(alignment: Alignment.topRight, child:
              FavoriteButton(favorite: (_selectedMapExplore as Favorite), style: FavoriteIconStyle.Button, padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),),
            ) :
            Container(),
        ],),
      ),
    );
  }
  void _onTapMapExploreDirections() {
    Analytics().logSelect(target: 'Directions');
    if (_userLocationEnabled) {
      dynamic explore = _selectedMapExplore;
      _selectMapExplore(null);
      if (explore != null) {
        String? travelMode;
        if (explore is List) {
          dynamic exploreEntry = (0 < explore.length) ? explore.first : null;
          travelMode = ((exploreEntry is MTDStop) || (exploreEntry is ExplorePOI)) ? 'transit' : null;
        }
        else {
          travelMode = ((explore is MTDStop) || (explore is ExplorePOI)) ? 'transit' : null;
        }
        NativeCommunicator().launchExploreMapDirections(target: explore, options: (travelMode != null) ? {
          'travelMode': travelMode
        } : null);
      }
    }
    else {
      AppAlert.showMessage(context, Localization().getStringEx("panel.explore.directions.na.msg", "You need to enable location services in order to get navigation directions."));
    }
  }
  
  void _onTapMapExploreDetail() {
    Analytics().logSelect(target: (_selectedMapExplore is MTDStop) ? 'Bus Schedule' : 'Details');
    if (_selectedMapExplore is Explore) {
      (_selectedMapExplore as Explore).exploreLaunchDetail(context);
    }
    else if (_selectedMapExplore is List<Explore>) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreListPanel(explores: _selectedMapExplore),));
    }
    _selectMapExplore(null);
  }

  void _onTapMapClear() {
    Analytics().logSelect(target: 'Clear');
    if (_selectedMapExplore is Favorite) {
      Auth2().account?.prefs?.setFavorite(_selectedMapExplore as Favorite, false);
    }
    _selectMapExplore(null);
  }

  void _selectMapExplore(dynamic explore) {
    if (explore != null) {
      //TBD: _nativeMapController?.markPOI(((explore is ExplorePOI) && StringUtils.isEmpty(explore.placeId)) ? explore : null);
      setStateIfMounted(() {
        _selectedMapExplore = explore;
      });
      _updateSelectedMapStopRoutes();
      _mapExploreBarAnimationController?.forward();
    }
    else if (_selectedMapExplore != null) {
      //TBD: _nativeMapController?.markPOI(null);
      _mapExploreBarAnimationController?.reverse().then((_) {
        setStateIfMounted(() {
          _selectedMapExplore = null;
        });
        _updateSelectedMapStopRoutes();
      });
    }
  }

  Widget? _buildExploreBarStopDescription() {
    if (_loadingMapStopIdRoutes != null) {
      return Padding(padding: EdgeInsets.only(left: 8), child:
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
                  Text(route.shortName ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 12, color: route.textColor,)),
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
        return null;
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

  // Dropdown Widgets

  Widget _buildExploreItemsDropDownButton() {
    return RibbonButton(
      textColor: Styles().colors!.fillColorSecondary,
      backgroundColor: Styles().colors!.white,
      borderRadius: BorderRadius.all(Radius.circular(5)),
      border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
      rightIconKey: (_itemsDropDownValuesVisible ? 'chevron-up' : 'chevron-down'),
      label: _exploreItemName(_selectedExploreItem),
      hint: _exploreItemHint(_selectedExploreItem),
      onTap: _onExploreItemsDropdown
    );
  }

  void _onExploreItemsDropdown() {
    Analytics().logSelect(target: 'Explore Dropdown');
    setStateIfMounted(() {
      _clearActiveFilter();
      _itemsDropDownValuesVisible = !_itemsDropDownValuesVisible;
    });
  }

  Widget _buildEventsDisplayTypesDropDownButton() {
    return RibbonButton(
      textColor: Styles().colors!.fillColorSecondary,
      backgroundColor: Styles().colors!.white,
      borderRadius: BorderRadius.all(Radius.circular(5)),
      border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
      rightIconKey: (_eventsDisplayDropDownValuesVisible ? 'chevron-up' : 'chevron-down'),
      label: _eventsDisplayTypeName(_selectedEventsDisplayType),
      onTap: _onEventsDisplayTypesDropDown
    );
  }

  void _onEventsDisplayTypesDropDown() {
    Analytics().logSelect(target: 'Events Type Dropdown');
    setStateIfMounted(() {
      _clearActiveFilter();
      _eventsDisplayDropDownValuesVisible = !_eventsDisplayDropDownValuesVisible;
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

  Widget _buildExploreItemsDropDownContainer() {
    return Visibility(visible: _itemsDropDownValuesVisible, child:
      Positioned.fill(child:
        Stack(children: <Widget>[
          _buildExploreDropDownDismissLayer(),
          _buildExploreItemsDropDownWidget()
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

  Widget _buildExploreItemsDropDownWidget() {
    List<Widget> itemList = <Widget>[
      Container(color: Styles().colors!.fillColorSecondary, height: 2),
    ];
    for (ExploreItem exploreItem in _exploreItems) {
      if ((_selectedExploreItem != exploreItem)) {
        itemList.add(_buildExploreDropDownItem(exploreItem));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: itemList)
      )
    );
  }

  Widget _buildExploreDropDownItem(ExploreItem exploreItem) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconKey: null,
        label: _exploreItemName(exploreItem),
        onTap: () => _onTapExploreItem(exploreItem)
      );
  }

  void _onTapExploreItem(ExploreItem item) {
    Analytics().logSelect(target: _exploreItemName(item));
    ExploreItem? lastExploreItem = _selectedExploreItem;
    Storage().selectedMapExploreItem = exploreItemToString(item);
    setStateIfMounted(() {
      _clearActiveFilter();
      _selectedExploreItem = _lastExploreItem = item;
      _itemsDropDownValuesVisible = false;
    });
    if (lastExploreItem != item) {
      _targetMapStyle = _currentMapStyle;
      _initExplores();
    }
  }

  // Filter Widgets

  List<Widget> _buildFilters() {
    List<Widget> filterTypeWidgets = [];
    List<ExploreFilter>? visibleFilters = (_itemToFilterMap != null) ? _itemToFilterMap![_selectedExploreItem] : null;
    if ((visibleFilters == null ) || visibleFilters.isEmpty || (_eventCategories == null)) {
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

  List<ExploreItem> _buildExploreItems() {
    List<ExploreItem> exploreItems = [];
    List<dynamic>? codes = FlexUI()['explore.map'];
    if (codes != null) {
      for (dynamic code in codes) {
        if (code == 'events') {
          exploreItems.add(ExploreItem.Events);
        }
        else if (code == 'dining') {
          exploreItems.add(ExploreItem.Dining);
        }
        else if (code == 'laundry') {
          exploreItems.add(ExploreItem.Laundry);
        }
        else if (code == 'buildings') {
          exploreItems.add(ExploreItem.Buildings);
        }
        else if (code == 'student_courses') {
          exploreItems.add(ExploreItem.StudentCourse);
        }
        else if (code == 'appointments') {
          exploreItems.add(ExploreItem.Appointments);
        }
        else if (code == 'mtd_stops') {
          exploreItems.add(ExploreItem.MTDStops);
        }
        else if (code == 'mtd_destinations') {
          exploreItems.add(ExploreItem.MTDDestinations);
        }
        else if (code == 'state_farm_wayfinding') {
          exploreItems.add(ExploreItem.StateFarmWayfinding);
        }
      }
    }
    return exploreItems;
  }

  ExploreItem? get _lastExploreItem => exploreItemFromString(Storage().selectedMapExploreItem);
  
  set _lastExploreItem(ExploreItem? value) => Storage().selectedMapExploreItem = exploreItemToString(value);

  static String? _exploreItemName(ExploreItem? exploreItem) {
    switch (exploreItem) {
      case ExploreItem.Events:              return Localization().getStringEx('panel.explore.button.events.title', 'Events');
      case ExploreItem.Dining:              return Localization().getStringEx('panel.explore.button.dining.title', 'Residence Hall Dining');
      case ExploreItem.Laundry:             return Localization().getStringEx('panel.explore.button.laundry.title', 'Laundry');
      case ExploreItem.Buildings:           return Localization().getStringEx('panel.explore.button.buildings.title', 'Campus Buildings');
      case ExploreItem.StudentCourse:       return Localization().getStringEx('panel.explore.button.student_course.title', 'My Courses');
      case ExploreItem.Appointments:        return Localization().getStringEx('panel.explore.button.appointments.title', 'MyMcKinley In-Person Appointments');
      case ExploreItem.MTDStops:            return Localization().getStringEx('panel.explore.button.mtd_stops.title', 'MTD Stops');
      case ExploreItem.MTDDestinations:     return Localization().getStringEx('panel.explore.button.mtd_destinations.title', 'MTD Destinations');
      case ExploreItem.StateFarmWayfinding: return Localization().getStringEx('panel.explore.button.state_farm.title', 'State Farm Wayfinding');
      default:                              return null;
    }
  }

  static String? _exploreItemHint(ExploreItem? exploreItem) {
    switch (exploreItem) {
      case ExploreItem.Events:              return Localization().getStringEx('panel.explore.button.events.hint', '');
      case ExploreItem.Dining:              return Localization().getStringEx('panel.explore.button.dining.hint', '');
      case ExploreItem.Laundry:             return Localization().getStringEx('panel.explore.button.laundry.hint', '');
      case ExploreItem.Buildings:           return Localization().getStringEx('panel.explore.button.buildings.hint', '');
      case ExploreItem.StudentCourse:       return Localization().getStringEx('panel.explore.button.student_course.hint', '');
      case ExploreItem.Appointments:        return Localization().getStringEx('panel.explore.button.appointments.hint', '');
      case ExploreItem.MTDStops:            return Localization().getStringEx('panel.explore.button.mtd_stops.hint', '');
      case ExploreItem.MTDDestinations:     return Localization().getStringEx('panel.explore.button.mtd_destinations.hint', '');
      case ExploreItem.StateFarmWayfinding: return Localization().getStringEx('panel.explore.button.state_farm.hint', '');
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
      ExploreItem.Events: <ExploreFilter>[
        ExploreFilter(type: ExploreFilterType.categories),
        ExploreFilter(type: ExploreFilterType.event_time, selectedIndexes: {2})
      ],
      ExploreItem.Dining: <ExploreFilter>[
        ExploreFilter(type: ExploreFilterType.work_time),
        ExploreFilter(type: ExploreFilterType.payment_type)
      ],
      ExploreItem.StudentCourse: <ExploreFilter>[
        ExploreFilter(type: ExploreFilterType.student_course_terms, selectedIndexes: { _selectedTermIndex }),
      ],
    };

    if (Connectivity().isNotOffline) {
      Events().loadEventCategories().then((List<dynamic>? categories) {
        setStateIfMounted(() {
          _eventCategories = _buildEventCategories(categories);
        });
      });
    }
  }

  void _clearActiveFilter() {
    List<ExploreFilter>? itemFilters = (_itemToFilterMap != null) ? _itemToFilterMap![_selectedExploreItem] : null;
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
    List<ExploreFilter>? itemFilters = (_itemToFilterMap != null) ? _itemToFilterMap![_selectedExploreItem] : null;
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
      case ExploreFilterType.categories:   return _filterEventCategoriesValues;
      case ExploreFilterType.work_time:    return _filterWorkTimeValues;
      case ExploreFilterType.payment_type: return _filterPaymentTypeValues;
      case ExploreFilterType.event_time:   return _filterEventTimeValues;
      case ExploreFilterType.event_tags:   return _filterTagsValues;
      case ExploreFilterType.student_course_terms: return _filterTermsValues;
      default: return null;
    }
  }

  List<String> get _filterEventCategoriesValues => <String>[
      Localization().getStringEx('panel.explore.filter.categories.all', 'All Categories'),
      Localization().getStringEx('panel.explore.filter.categories.my', 'My Categories'),
      ... _eventCategories ?? <String>[]
    ];

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

  List<String>? _buildEventCategories(List<dynamic>? categories) {
    List<String>? eventCategories;
    if (categories != null) {
      eventCategories = <String>[];
      for (dynamic entry in categories) {
        Map<String, dynamic>? mapEntry = JsonUtils.mapValue(entry);
        String? category = (mapEntry != null) ? JsonUtils.stringValue(['category']) : null;
        if (category != null) {
          eventCategories.add(category); 
        }
      }
    }
    return eventCategories;
  }

  Set<int>? _getSelectedFilterIndexes(List<ExploreFilter>? selectedFilterList, ExploreFilterType filterType) {
    if (selectedFilterList != null) {
      for (ExploreFilter selectedFilter in selectedFilterList) {
        if (selectedFilter.type == filterType) {
          return selectedFilter.selectedIndexes;
        }
      }
    }
    return null;
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

  Set<String?>? _getSelectedCategories(List<ExploreFilter>? selectedFilterList) {
    if (selectedFilterList == null || selectedFilterList.isEmpty) {
      return null;
    }
    
    Set<String?>? selectedCategories;
    for (ExploreFilter selectedFilter in selectedFilterList) {
      //Apply custom logic for categories
      if (selectedFilter.type == ExploreFilterType.categories) {
        Set<int> selectedIndexes = selectedFilter.selectedIndexes;
        if (selectedIndexes.isEmpty || selectedIndexes.contains(0)) {
          break; // All Categories
        }
        else {
          selectedCategories = Set();
          
          if (selectedIndexes.contains(1)) { // My categories
            Iterable<String>? userCategories = Auth2().prefs?.interestCategories;
            if (userCategories != null && userCategories.isNotEmpty) {
              selectedCategories.addAll(userCategories);
            }
          }
          
          List<String> filterCategoriesValues = _filterEventCategoriesValues;
          if (filterCategoriesValues.isNotEmpty) {
            for (int selectedCategoryIndex in selectedIndexes) {
              if ((selectedCategoryIndex < filterCategoriesValues.length) && selectedCategoryIndex != 1) {
                String? singleCategory = filterCategoriesValues[selectedCategoryIndex];
                if (StringUtils.isNotEmpty(singleCategory)) {
                  selectedCategories.add(singleCategory);
                }
              }
            }
          }
        }
      }
    }
    return selectedCategories;
  }

  EventTimeFilter _getSelectedEventTimePeriod(List<ExploreFilter>? selectedFilterList) {
    Set<int>? selectedIndexes = _getSelectedFilterIndexes(selectedFilterList, ExploreFilterType.event_time);
    int index = (selectedIndexes != null && selectedIndexes.isNotEmpty) ? selectedIndexes.first : -1; //Get first one because only categories has more than one selectable index
    switch (index) {

      case 0: // 'Upcoming':
        return EventTimeFilter.upcoming;
      case 1: // 'Today':
        return EventTimeFilter.today;
      case 2: // 'Next 7 days':
        return EventTimeFilter.next7Day;
      case 3: // 'This Weekend':
        return EventTimeFilter.thisWeekend;
      
      case 4: //'Next 30 days':
        return EventTimeFilter.next30Days;
      default:
        return EventTimeFilter.upcoming;
    }

    /*//Filter by the time in the University
    DateTime nowUni = AppDateTime().getUniLocalTimeFromUtcTime(now.toUtc());
    int hoursDiffToUni = now.hour - nowUni.hour;
    DateTime startDateUni = startDate.add(Duration(hours: hoursDiffToUni));
    DateTime endDateUni = (endDate != null) ? endDate.add(
        Duration(hours: hoursDiffToUni)) : null;

    return {
      'start_date' : startDateUni,
      'end_date' : endDateUni
    };*/
  }

  Set<String>? _getSelectedEventTags(List<ExploreFilter>? selectedFilterList) {
    if (selectedFilterList == null || selectedFilterList.isEmpty) {
      return null;
    }
    for (ExploreFilter selectedFilter in selectedFilterList) {
      if (selectedFilter.type == ExploreFilterType.event_tags) {
        int index = selectedFilter.firstSelectedIndex;
        if (index == 0) {
          return null; //All Tags
        } else { //My tags
          return Auth2().prefs?.positiveTags;
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

  // Content Data

  /*String? get _offlineContentMessage {
    switch (_selectedExploreItem) {
      case ExploreItem.Events:              return Localization().getStringEx('panel.explore.state.offline.empty.events', 'No upcoming events available while offline..');
      case ExploreItem.Dining:              return Localization().getStringEx('panel.explore.state.offline.empty.dining', 'No dining locations available while offline.');
      case ExploreItem.Laundry:             return Localization().getStringEx('panel.explore.state.offline.empty.laundry', 'No laundry locations available while offline.');
      case ExploreItem.Buildings:           return Localization().getStringEx('panel.explore.state.offline.empty.buildings', 'No building locations available while offline.');
      case ExploreItem.StudentCourse:       return Localization().getStringEx('panel.explore.state.offline.empty.student_course', 'No student courses available while offline.');
      case ExploreItem.Appointments:        return Localization().getStringEx('panel.explore.state.offline.empty.appointments', 'No appointments available while offline.');
      case ExploreItem.MTDStops:            return Localization().getStringEx('panel.explore.state.offline.empty.mtd_stops', 'No MTD stop locations available while offline.');
      case ExploreItem.MTDDestinations:     return Localization().getStringEx('panel.explore.state.offline.empty.mtd_destinations', 'No MTD destinaion locations available while offline.');
      case ExploreItem.StateFarmWayfinding: return Localization().getStringEx('panel.explore.state.offline.empty.state_farm', 'No State Farm Wayfinding available while offline.');
      default:                              return null;
    }
  }*/

  String? get _emptyContentMessage {
    switch (_selectedExploreItem) {
      case ExploreItem.Events: return Localization().getStringEx('panel.explore.state.online.empty.events', 'No upcoming events.');
      case ExploreItem.Dining: return Localization().getStringEx('panel.explore.state.online.empty.dining', 'No dining locations are currently open.');
      case ExploreItem.Laundry: return Localization().getStringEx('panel.explore.state.online.empty.laundry', 'No laundry locations are currently open.');
      case ExploreItem.Buildings: return Localization().getStringEx('panel.explore.state.online.empty.buildings', 'No building locations available.');
      case ExploreItem.StudentCourse: return Localization().getStringEx('panel.explore.state.online.empty.student_course', 'No student courses available.');
      case ExploreItem.Appointments: return Localization().getStringEx('panel.explore.state.online.empty.appointments', 'No appointments available.');
      case ExploreItem.MTDStops: return Localization().getStringEx('panel.explore.state.online.empty.mtd_stops', 'No MTD stop locations available.');
      case ExploreItem.MTDDestinations: return Localization().getStringEx('panel.explore.state.online.empty.mtd_destinations', 'No MTD destinaion locations available.');
      case ExploreItem.StateFarmWayfinding: return Localization().getStringEx('panel.explore.state.online.empty.state_farm', 'No State Farm Wayfinding available.');
      default:  return null;
    }
  }

  String? get _failedContentMessage {
    switch (_selectedExploreItem) {
      case ExploreItem.Events: return Localization().getStringEx('panel.explore.state.failed.events', 'Failed to load upcoming events.');
      case ExploreItem.Dining: return Localization().getStringEx('panel.explore.state.failed.dining', 'Failed to load dining locations.');
      case ExploreItem.Laundry: return Localization().getStringEx('panel.explore.state.failed.laundry', 'Failed to load laundry locations.');
      case ExploreItem.Buildings: return Localization().getStringEx('panel.explore.state.failed.buildings', 'Failed to load building locations.');
      case ExploreItem.StudentCourse: return Localization().getStringEx('panel.explore.state.failed.student_course', 'Failed to load student courses.');
      case ExploreItem.Appointments: return Localization().getStringEx('panel.explore.state.failed.appointments', 'Failed to load appointments.');
      case ExploreItem.MTDStops: return Localization().getStringEx('panel.explore.state.failed.mtd_stops', 'Failed to load MTD stop locations.');
      case ExploreItem.MTDDestinations: return Localization().getStringEx('panel.explore.state.failed.mtd_destinations', 'Failed to load MTD destinaion locations.');
      case ExploreItem.StateFarmWayfinding: return Localization().getStringEx('panel.explore.state.failed.state_farm', 'Failed to load State Farm Wayfinding.');
      default:  return null;
    }
  }

  // Locaction Services

  bool get _userLocationEnabled {
    return FlexUI().isLocationServicesAvailable && (_locationServicesStatus == LocationServicesStatus.permissionAllowed);
  }

  void _initLocationServicesStatus() {
    if (FlexUI().isLocationServicesAvailable) {
      LocationServices().status.then((LocationServicesStatus? locationServicesStatus) {
        setStateIfMounted(() {
          _locationServicesStatus = locationServicesStatus;
        });
      });
    }
  }


  // Explore Content

  void _initExplores() {
    Future<List<Explore>?> exploreTask = _loadExplores();
    _exploreTask = exploreTask;
    _exploreProgress = true;
    _exploreTask?.then((List<Explore>? explores) {
      if (mounted && (exploreTask == _exploreTask)) {
        _buildMapContentData(explores, updateCamera: true).then((_){
          if (mounted && (exploreTask == _exploreTask)) {
            setState(() {
              _explores = explores;
              _exploreTask = null;
              _exploreProgress = false;
              _selectedMapExplore = null;
              _mapExploreBarAnimationController?.value = _mapExploreBarAnimationController?.lowerBound ?? 0;
              _mapKey = UniqueKey(); // force map rebuild
            });
            _displayContentPopups();
          }
        });
      }
    });
  }

  Future<void> _onRefresh() async {
    Future<List<Explore>?> exploreTask = _loadExplores();
    List<Explore>? explores = await (_exploreTask = exploreTask);
    if (mounted && (exploreTask == _exploreTask)) {
      _buildMapContentData(explores, updateCamera: false).then((_){
        if (mounted && (exploreTask == _exploreTask)) {
          setState(() {
            _explores = explores;
            _exploreTask = null;
          });
        }
      });
    }
  }

  Future<List<Explore>?> _loadExplores() async {
    if (Connectivity().isNotOffline) {
      List<ExploreFilter>? selectedFilterList = (_itemToFilterMap != null) ? _itemToFilterMap![_selectedExploreItem] : null;
      switch (_selectedExploreItem) {
        case ExploreItem.Events: return _loadEvents(selectedFilterList);
        case ExploreItem.Dining: return _loadDining(selectedFilterList);
        case ExploreItem.Laundry: return _loadLaundry();
        case ExploreItem.Buildings: return _loadBuildings();
        case ExploreItem.StudentCourse: return _loadStudentCourse(selectedFilterList);
        case ExploreItem.Appointments: return _loadAppointments();
        case ExploreItem.MTDStops: return _loadMTDStops();
        case ExploreItem.MTDDestinations: return _loadMTDDestinations();
        case ExploreItem.StateFarmWayfinding: break;
        default: break;
      }
    }
    return null;
  }

  Future<List<Explore>?> _loadEvents(List<ExploreFilter>? selectedFilterList) async {
    List<Explore>? explores;
    Set<String?>? categories = _getSelectedCategories(selectedFilterList);
    Set<String>? tags = _getSelectedEventTags(selectedFilterList);
    EventTimeFilter eventFilter = _getSelectedEventTimePeriod(selectedFilterList);
    List<Event>? events = await Events().loadEvents(categories: categories, tags: tags, eventFilter: eventFilter);
    if (events != null) {
      explores = _filterEvents(events);
    }
    return explores;
  }

  List<Explore>? _filterEvents(List<Event> allEvents) {
    if (_selectedEventsDisplayType == EventsDisplayType.all) {
      return allEvents;
    }
    else {
        List<Explore> displayEvents = [];
        for (Event event in allEvents) {
          if (((_selectedEventsDisplayType == EventsDisplayType.multiple) && event.isMultiEvent) ||
              ((_selectedEventsDisplayType == EventsDisplayType.single) && !event.isMultiEvent)) {
            displayEvents.add(event);
          }
        }
        return displayEvents;
    }
  }

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

  Future<List<Explore>?> _loadMTDStops() async {
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

  Future<List<Explore>?> _loadMTDDestinations() async {
    return ExplorePOI.listFromString(Auth2().prefs?.getFavorites(ExplorePOI.favoriteKeyName)) ?? <Explore>[];
  }

  Future<List<Explore>?> _loadStudentCourse(List<ExploreFilter>? selectedFilterList) async {
    String? termId = _getSelectedTermId(selectedFilterList) ?? StudentCourses().displayTermId;
    return (termId != null) ? await StudentCourses().loadCourses(termId: termId) : null;
  }

  Future<List<Explore>?> _loadAppointments() async {
    return Appointments().getAppointments(onlyUpcoming: true, type: AppointmentType.in_person);
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
      _showMessagePopup(_failedContentMessage);
    }
    else if (_selectedExploreItem == ExploreItem.Appointments) {
      if (Storage().appointmentsCanDisplay != true) {
        _showMessagePopup(Localization().getStringEx('panel.explore.hide.appointments.msg', 'There is nothing to display as you have chosen not to display any past or future appointments.'));
      } else if (CollectionUtils.isEmpty(_explores)) {
        _showMessagePopup(Localization().getStringEx('panel.explore.missing.appointments.msg','You currently have no upcoming in-person appointments linked within {{app_title}} app.').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')));
      }
    }
    else if (_selectedExploreItem == ExploreItem.MTDStops) {
      if (Storage().showMtdStopsMapInstructions != false) {
        _showOptionalMessagePopup(Localization().getStringEx("panel.explore.instructions.mtd_stops.msg", "Please tap a bus stop on the map to get bus schedules. Tap the star to save the bus stop as a favorite."), showPopupStorageKey: Storage().showMtdStopsMapInstructionsKey,
        );
      }
      else if (CollectionUtils.isEmpty(_explores)) {
        _showMessagePopup(Localization().getStringEx('panel.explore.missing.mtd_destinations.msg', 'You currently have no saved destinations. Please tap the location on the map that will be your destination. You can tap the Map to get Directions or Save the destination as a favorite.'),);
      }
    }
    else if (_selectedExploreItem == ExploreItem.MTDDestinations) {
      if (Storage().showMtdDestinationsMapInstructions != false) {
        _showOptionalMessagePopup(Localization().getStringEx("panel.explore.instructions.mtd_destinations.msg", "Please tap a location on the map that will be your destination. Tap the star to save the destination as a favorite.",), showPopupStorageKey: Storage().showMtdDestinationsMapInstructionsKey
        );
      }
      else if (CollectionUtils.isEmpty(_explores)) {
        _showMessagePopup(_emptyContentMessage);
      }
    }
    else if (_selectedExploreItem == ExploreItem.StateFarmWayfinding) {
      //TBD: _viewStateFarmPoi();
    }
    else if (CollectionUtils.isEmpty(_explores)) {
      _showMessagePopup(_emptyContentMessage);
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
      if (_selectedExploreItem == ExploreItem.Buildings) {
        return JsonUtils.encode(_mapStyles![_mapStylesExplorePoiKey]);
      }
      else if (_selectedExploreItem == ExploreItem.MTDStops) {
        return JsonUtils.encode(_mapStyles![_mapStylesMtdStopKey]);
      }
    }
    return null;
  }

  // Map Content

  Future<void> _buildMapContentData(List<Explore>? explores, { bool updateCamera = false, bool showProgress = false, double? zoom}) async {
    LatLngBounds? exploresBounds = ExploreMap.boundsOfList(explores);

    CameraUpdate? targetCameraUpdate = updateCamera ?
      ((exploresBounds != null) ? CameraUpdate.newLatLngBounds(exploresBounds, _mapPadding) : CameraUpdate.newCameraPosition(_defaultCameraPosition)) : null;

    Size? mapSize = _mapSize;
    if ((exploresBounds != null) && (mapSize != null)) {
      zoom ??= GoogleMapUtils.getMapBoundZoom(exploresBounds, math.max(mapSize.width - 2 * _mapPadding, 0), math.max(mapSize.height - 2 * _mapPadding, 0));
      double thresoldDistance = _thresoldDistanceForZoom(zoom);
      Set<dynamic>? exploreMarkerGroups = _buildMarkerGroups(explores, thresoldDistance: thresoldDistance);
      if (!DeepCollectionEquality().equals(_exploreMarkerGroups, exploreMarkerGroups)) {
        Future<Set<Marker>> buildMarkersTask = _buildMarkers(exploreMarkerGroups, context);
        if (showProgress && mounted) {
          setState(() {
            _markersProgress = true;
          });
        }
        _buildMarkersTask = buildMarkersTask;
        debugPrint('Building Markers for zoom: $zoom thresholdDistance: $thresoldDistance markersSource: ${exploreMarkerGroups?.length}');
        Set<Marker> targetMarkers = await buildMarkersTask;
        debugPrint('Finished Building Markers for zoom: $zoom thresholdDistance: $thresoldDistance => ${targetMarkers.length}');
        if (_buildMarkersTask == buildMarkersTask) {
          debugPrint('Applying ${targetMarkers.length} Building Markers for zoom: $zoom thresholdDistance: $thresoldDistance');
          _targetMarkers = targetMarkers;
          _exploreMarkerGroups = exploreMarkerGroups;
          _targetCameraUpdate = targetCameraUpdate;
          _lastMarkersUpdateZoom = null;
          if (showProgress && mounted) {
            setState(() {
              _markersProgress = false;
            });
          }
        }
      }
    }
    else if (targetCameraUpdate != null) {
      _targetCameraUpdate = targetCameraUpdate;
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

  Future<Set<Marker>> _buildMarkers(Set<dynamic>? exploreGroups, BuildContext context) async {
    Set<Marker> markers = <Marker>{};
    if (exploreGroups != null) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context);
      for (dynamic entry in exploreGroups) {
        LatLng? markerPosition;
        BitmapDescriptor? markerIcon;
        Offset? markerAnchor;
        String? markerTitle, markerSnippet;
        
        if (entry is List<Explore>) {
          markerPosition = ExploreMap.centerOfList(entry);
          Explore? sameExplore = ExploreMap.mapGroupSameExploreForList(entry);
          String markerAsset = sameExplore?.mapMarkerAssetName ?? 'images/map-marker-group-laundry.png';
          markerIcon = _markerIconCache[markerAsset] ??
            (_markerIconCache[markerAsset] = await BitmapDescriptor.fromAssetImage(imageConfiguration, markerAsset));
          markerAnchor = Offset(0.5, 0.5);
          markerTitle = sameExplore?.getMapGroupMarkerTitle(entry.length);
        }
        else if (entry is Explore) {
          markerPosition = (entry.exploreLocation?.isLocationCoordinateValid == true) ? LatLng(
            entry.exploreLocation?.latitude?.toDouble() ?? 0,
            entry.exploreLocation?.longitude?.toDouble() ?? 0
          ) : null;
          if (entry is MTDStop) {
            String markerAsset = 'images/map-marker-mtd-stop.png';
            markerIcon = _markerIconCache[markerAsset] ??
              (_markerIconCache[markerAsset] = await BitmapDescriptor.fromAssetImage(imageConfiguration, markerAsset));
            markerAnchor = Offset(0.5, 0.5);
          }
          else {
            Color? exploreColor = entry.uiColor;
            markerIcon = (exploreColor != null) ? BitmapDescriptor.defaultMarkerWithHue(ColorUtils.hueFromColor(exploreColor).toDouble()) : BitmapDescriptor.defaultMarker;
            markerAnchor = Offset(0.5, 1);
          }
          markerTitle = entry.mapMarkerTitle;
          markerSnippet = entry.mapMarkerSnippet;
        }
        
        
        if (markerPosition != null) {
          markerIcon ??= BitmapDescriptor.defaultMarker;
          markerAnchor ??= Offset(0.5, 1);
          markers.add(Marker(
            markerId: MarkerId("${markerPosition.latitude.toStringAsFixed(6)}:${markerPosition.latitude.toStringAsFixed(6)}"),
            position: markerPosition,
            icon: markerIcon,
            anchor: markerAnchor,
            consumeTapEvents: true,
            onTap: () => _onTapMarker(entry),
            infoWindow: InfoWindow(
              title: markerTitle,
              snippet: markerSnippet,
              anchor: markerAnchor)
          ));
        }
      }
    }
    return markers;
  }

  static List<Explore>? _lookupExploreGroup(List<List<Explore>> exploreGroups, ExploreLocation exploreLocation, { double thresoldDistance = 0 }) {
    for (List<Explore> groupExploreList in exploreGroups) {
      for (Explore groupExplore in groupExploreList) {
        double distance = GoogleMapUtils.getDistance(
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

  Size? get _mapSize {
    try {
      final RenderObject? renderBox = _mapContainerKey.currentContext?.findRenderObject();
      return (renderBox is RenderBox) ? renderBox.size : null;
    }
    on Exception catch (e) {
      print(e.toString());
      return null;
    }
  }

}

