import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/model/Location.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/ui/mtd/MTDStopDeparturesPanel.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum MTDStopsContentType { all, my }

class MTDStopsHomePanel extends StatefulWidget {

  final MTDStopsContentType? contentType;

  MTDStopsHomePanel({Key? key, this.contentType}) : super(key: key);
  
  State<MTDStopsHomePanel> createState() => _MTDStopsHomePanelState();
}

class _MTDStopsHomePanelState extends State<MTDStopsHomePanel> implements NotificationsListener {
  
  static Color _dimmedBackgroundColor = Color(0x99000000);

  MTDStopsContentType? _selectedContentType;
  bool _contentTypesDropdownExpanded = false;
  List<MTDStop>? _stops;
  Set<String> _expanded = <String>{};

  Position? _currentPosition;
  LocationServicesStatus? _locationServicesStatus;
  bool _processingLocation = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      MTD.notifyStopsChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      LocationServices.notifyStatusChanged,
    ]);
    
    if (widget.contentType != null) {
      _selectedContentType = widget.contentType;
    }
    else {
      _selectedContentType = CollectionUtils.isNotEmpty(Auth2().account?.prefs?.getFavorites(MTDStop.favoriteKeyName)) ? MTDStopsContentType.my : MTDStopsContentType.all;
    }
    
    _processingLocation = true;
    _loadLocationServicesStatus().then((LocationServicesStatus? locationServicesStatus) {
      _locationServicesStatus = locationServicesStatus;
      _loadPosition().then((Position? position) {
        _currentPosition = position;
        if (mounted) {
          setState(() {
            _processingLocation = false;
            _stops = _contentList;
          });
        }
      });
    });

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
    if (name == MTD.notifyStopsChanged) {
      if (mounted) {
        setState(() {
          _stops = _contentList;
        });
      }
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      if (mounted) {
        setState(() {});
      }
    }
    else if (name == LocationServices.notifyStatusChanged) {
      _onLocationServicesStatusChanged(param);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootBackHeaderBar(
        title: Localization().getStringEx('panel.mtd_stops.home.header_bar.title', 'MTD Stops'),
      ),
      body: _buildPage(),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildPage() {
    return Column(children: [
      _buildContentTypeDropdownButton(),
      Expanded(child:
        Stack(children: [
          Column(children: [
            Expanded(child: 
              _processingLocation ? _buildLoading() :
                RefreshIndicator(onRefresh: _onPullToRefresh, child:
                _buildContent()
                ),
            ),
          ],),
          _buildContentTypesDropdownContainer()
        ],)
      ),
    ],);
  }

  // Content Type Dropdown

  Widget _buildContentTypeDropdownButton() {
    return Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8), child:
      RibbonButton(
        textColor: Styles().colors?.fillColorSecondary,
        backgroundColor: Styles().colors?.white,
        borderRadius: BorderRadius.all(Radius.circular(5)),
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconAsset: (_contentTypesDropdownExpanded ? 'images/icon-up.png' : 'images/icon-down-orange.png'),
        label: _getContentTypeName(_selectedContentType),
        onTap: _onTapContentTypeDropdownButton
      )
    );
  }

  Widget _buildContentTypesDropdownContainer() {
    return Visibility(visible: _contentTypesDropdownExpanded, child:
      Stack(children: [
        GestureDetector(onTap: _onTapContentTypeBackgroundContainer, child:
          Container(color: _dimmedBackgroundColor)),
        _buildContentTypesDropdownList()
    ]));
  }

  Widget _buildContentTypesDropdownList() {
    
    List<Widget> contentList = <Widget>[];
    contentList.add(Container(color: Styles().colors?.fillColorSecondary, height: 2));
    for (MTDStopsContentType contentType in MTDStopsContentType.values) {
      if ((_selectedContentType != contentType)) {
        contentList.add(_buildContentTypeDropdownItem(contentType));
      }
    }
    contentList.add(RibbonButton(
      backgroundColor: Styles().colors?.white,
      border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
      rightIconAsset: null,
      label: Localization().getStringEx('panel.mtd_stops.home.dropdown.search.title', 'Search Stop'),
      onTap: _onTapSearch
    ),);

    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: contentList)
      )
    );
  }

  Widget _buildContentTypeDropdownItem(MTDStopsContentType contentType) {
    return RibbonButton(
        backgroundColor: Styles().colors?.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconAsset: null,
        label: _getContentTypeName(contentType),
        onTap: () => _onTapContentTypeDropdownItem(contentType));
  }

  void _onTapContentTypeDropdownButton() {
    setState(() {
      _contentTypesDropdownExpanded = !_contentTypesDropdownExpanded;
    });
  }

  void _onTapContentTypeBackgroundContainer() {
    setState(() {
      _contentTypesDropdownExpanded = false;
    });
  }

  void _onTapContentTypeDropdownItem(MTDStopsContentType contentType) {
    Analytics().logSelect(target: _getContentTypeName(contentType, languageCode: 'en'));
    if (_selectedContentType != contentType) {
      setState(() {
        _selectedContentType = contentType;
        _contentTypesDropdownExpanded = false;
        _stops = _contentList;
      });
    }
  }


  static String _getContentTypeName(MTDStopsContentType? contentType, {String? languageCode} )  {
    switch (contentType) {
      case MTDStopsContentType.all: return Localization().getStringEx('panel.mtd_stops.home.content_type.all.title', 'All Stops');
      case MTDStopsContentType.my: return Localization().getStringEx('panel.mtd_stops.home.content_type.my.title', 'My Stops');
      default: return '';
    }
  }


  void _onTapSearch() {
    Analytics().logSelect(target: "Search MTD Stop");
    setState(() {
      _contentTypesDropdownExpanded = false;
    });
  }

  // Content Widget

  Widget _buildContent() {
    if (_stops == null) {
      return _buildStatus(_errorDisplayStatus);
    }
    else if (_stops!.isEmpty) {
      return _buildStatus(_emptyDisplayStatus);
    }
    else {
      return _buildStops();
    }
  }

  Widget _buildStops() {
    return ListView.separated(
      itemBuilder: (context, index) => _MTDStopCard(
        stop: ListUtils.entry(_stops, index),
        expanded: _expanded,
        onExpand: () => _onExpandStop(ListUtils.entry(_stops, index)),
        currentPosition: _currentPosition,
      ),
      separatorBuilder: (context, index) => Container(),
      itemCount: _stops?.length ?? 0,
      padding: EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildLoading() {
    return Align(alignment: Alignment.center, child:
      CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 3, ),
    );
  }

  Widget _buildStatus(String status) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Padding(padding: EdgeInsets.only(left: 32, right: 32, top: screenHeight / 5), child:
        Row(children: [
          Expanded(child:
            Text(status ,style:
              Styles().textStyles?.getTextStyle("widget.message.large"), textAlign: TextAlign.center,),
          ),
        ],)
    );
  }

  String get _errorDisplayStatus {
    switch(_selectedContentType) {
      case MTDStopsContentType.all: return Localization().getStringEx('panel.mtd_stops.home.status.error.all.text', 'Failed to load bus stops.');
      case MTDStopsContentType.my: return Localization().getStringEx('panel.mtd_stops.home.status.error.my.text', 'Failed to load saved bus stops.');
      default: return '';
    }
  }

  String get _emptyDisplayStatus {
    switch(_selectedContentType) {
      case MTDStopsContentType.all: return Localization().getStringEx('panel.mtd_stops.home.status.empty.all.text', 'There are no bus stops available.');
      case MTDStopsContentType.my: return Localization().getStringEx('panel.mtd_stops.home.status.empty.my.text', 'You have no saved bus stops.');
      default: return '';
    }
  }

  // Content Data


  Future<void> _onPullToRefresh() async {
    await MTD().refreshStops();
  }

  List<MTDStop>? get _contentList {
    if (_selectedContentType == MTDStopsContentType.all) {
      List<MTDStop>? stops = ListUtils.from(MTD().stops?.stops);
      if ((stops != null) && (_currentPosition != null)) {
        stops.sort((MTDStop stop1, MTDStop stop2) {
          LatLng? position1 = stop1.anyPosition;
          LatLng? position2 = stop2.anyPosition;
          if ((position1 != null) && position1.isValid && (position2 != null) && position2.isValid) {
            double distance1 = Geolocator.distanceBetween(position1.latitude!, position1.longitude!, _currentPosition!.latitude, _currentPosition!.longitude);
            double distance2 = Geolocator.distanceBetween(position2.latitude!, position2.longitude!, _currentPosition!.latitude, _currentPosition!.longitude);
            return distance1.compareTo(distance2);
          }
          else {
            return 0;
          }
        });
      }
      return stops;
    }
    else if (_selectedContentType == MTDStopsContentType.my) {
      return ListUtils.reversed(MTD().stopsByIds(Auth2().account?.prefs?.getFavorites(MTDStop.favoriteKeyName)));
    }
    else {
      return null;
    }
  }

  void _onExpandStop(MTDStop? stop) {
    Analytics().logSelect(target: "MTD Stop: ${stop?.name}" );
    if (mounted && (stop?.id != null)) {
      setState(() {
        SetUtils.toggle(_expanded, stop?.id);
      });
    }
  }

  Future<LocationServicesStatus?> _loadLocationServicesStatus() async {
    LocationServicesStatus? locationServicesStatus;
    if (FlexUI().isLocationServicesAvailable) {
      locationServicesStatus = await LocationServices().status;
      if (locationServicesStatus == LocationServicesStatus.permissionNotDetermined) {
        locationServicesStatus = await LocationServices().requestPermission();
      }
    }
    return locationServicesStatus;
  }

  Future<Position?> _loadPosition() async {
    return (_locationServicesStatus == LocationServicesStatus.permissionAllowed) ? await LocationServices().location : null;
  }

  void _onLocationServicesStatusChanged(LocationServicesStatus? status) {
    if (FlexUI().isLocationServicesAvailable && !_processingLocation) {
      _locationServicesStatus = status;
      _loadPosition().then((Position? position) {
        _currentPosition = position;
        if (mounted) {
          setState(() {
            _stops = _contentList;
          });
        }
      });
    }
  }
}

class _MTDStopCard extends StatelessWidget {
  final MTDStop? stop;
  final Set<String>? expanded;
  final void Function()? onExpand;
  final Position? currentPosition;

  _MTDStopCard({Key? key, this.stop, this.expanded, this.onExpand, this.currentPosition }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[];
    contentList.add(_buildHeading(context));
    contentList.add(_buildEntries(context));
    return Column(children: contentList,);
  }

  Widget _buildHeading(BuildContext context) {
    String description = '';
    TextStyle titleStyle;
    EdgeInsetsGeometry titlePadding, favoritePadding;
    if (CollectionUtils.isNotEmpty(stop?.points)) {

      if (StringUtils.isNotEmpty(stop?.code)) {
        description = stop!.code!;
      }

      String? distance = distanceText;
      if (StringUtils.isNotEmpty(distance)) {
        if (description.isNotEmpty) {
          description += ", $distance";
        }
        else {
          description = distance!;
        }
      }

      int stopPointsCount = stop?.points?.length ?? 0;
      String pointsDescription = (1 < stopPointsCount) ? "$stopPointsCount stop points" : "$stopPointsCount stop point";
      if (description.isNotEmpty) {
        description += " ($pointsDescription)";
      }
      else {
        description = pointsDescription;
      }

      titleStyle = TextStyle(fontFamily: Styles().fontFamilies?.extraBold, fontSize: 20, color: Styles().colors!.fillColorPrimary);
      titlePadding = EdgeInsets.only(top: 12);
      favoritePadding = EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8);
    }
    else {
      titleStyle = TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary);
      titlePadding = EdgeInsets.only(top: 16);
      favoritePadding = EdgeInsets.all(16);
    }

    return Padding(padding: EdgeInsets.only(bottom: 4), child:
      InkWell(onTap: () => _onTapStop(context), child:
        Container(
          decoration: BoxDecoration(color: Styles().colors?.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),),
          padding: EdgeInsets.only(left: 16,),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child:
                Padding(padding: titlePadding, child:
                  Text(stop?.name ?? '', style: titleStyle)
                )
              ),
              Opacity(opacity: 1, child:
                Semantics(label: 'Favorite', button: true, child:
                  InkWell(onTap: () => _onTapFavorite(context), child:
                    FavoriteStarIcon(selected: _isFavorite, style: FavoriteIconStyle.Button, padding: favoritePadding,)
                  ),
                ),
              ),
            ],),
            
            Visibility(visible: description.isNotEmpty, child:
              InkWell(onTap: _onTapExpand, child:
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child:
                    Padding(padding: EdgeInsets.only(top: 4, bottom: 8), child:
                      Text(description, style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textSurface), maxLines: 1, overflow: TextOverflow.ellipsis,)
                    )
                  ),
                  Semantics(
                    label: _isExpanded ? Localization().getStringEx('panel.browse.section.status.colapse.title', 'Colapse') : Localization().getStringEx('panel.browse.section.status.expand.title', 'Expand'),
                    hint: _isExpanded ? Localization().getStringEx('panel.browse.section.status.colapse.hint', 'Tap to colapse section content') : Localization().getStringEx('panel.browse.section.status.expand.hint', 'Tap to expand section content'),
                    button: true, child:
                        Container(padding: EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 16), child:
                          SizedBox(width: 18, height: 18, child:
                            Center(child:
                              _isExpanded ?
                                Image.asset('images/arrow-up-orange.png', excludeFromSemantics: true) :
                                Image.asset('images/arrow-down-orange.png', excludeFromSemantics: true)
                            ),
                          )
                        ),
                  ),
                ],),
              ),
            ),
          ],),
        ),
      ),
    );
  }

  Widget _buildEntries(BuildContext context) {
      List<Widget> entriesList = <Widget>[];
      if (_isExpanded && CollectionUtils.isNotEmpty(stop?.points)) {
        for (MTDStop stop in stop!.points!) {
          entriesList.add(_MTDStopCard(
            stop: stop,
            expanded: expanded,
            onExpand: onExpand,
            currentPosition: currentPosition,
          ));
        }
      }
      return entriesList.isNotEmpty ? Padding(padding: EdgeInsets.only(left: 16), child:
        Column(children: entriesList,)
      ) : Container();
  }

  String? get distanceText {
    LatLng? stopPosition = stop?.anyPosition;
    if ((currentPosition != null) && (stopPosition != null) && stopPosition.isValid) {
      double distanceInMeters = Geolocator.distanceBetween(stopPosition.latitude!, stopPosition.longitude!, currentPosition!.latitude, currentPosition!.longitude);
      double distanceInMiles = distanceInMeters / 1609.344;
      return distanceInMiles.toStringAsFixed(1) + " mi away";
    }
    return null;
  }

  void _onTapStop(BuildContext context) {
    Analytics().logSelect(target: "MTD Stop: ${stop?.name}" );
    if (stop != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => MTDStopDeparturesPanel(stop: stop!)));
    }
  }

  bool get _canExpand => StringUtils.isNotEmpty(stop?.id) && CollectionUtils.isNotEmpty(stop?.points);

  bool get _isExpanded => expanded?.contains(stop?.id) ?? false;

  void _onTapExpand() {
    if (_canExpand && (onExpand != null)) {
      onExpand!();
    }
  }

  bool get _isFavorite => Auth2().account?.prefs?.isFavorite(stop) ?? false;

  void _onTapFavorite(BuildContext context) {
    Analytics().logSelect(target: "Favorite: ${MTDStop.favoriteKeyName}");
    Auth2().account?.prefs?.toggleFavorite(stop);
  }
}

