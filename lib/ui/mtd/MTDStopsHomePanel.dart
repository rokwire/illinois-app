import 'dart:collection';

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
import 'package:illinois/ui/mtd/MTDStopSearchPanel.dart';
import 'package:illinois/ui/mtd/MTDWidgets.dart';
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
    LocationServices().location.then((Position? position) {
      _currentPosition = position;
      if (mounted) {
        setState(() {
          _processingLocation = false;
          _stops = _contentList;
        });
      }
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
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.mtd_stops.home.header_bar.title', 'Bus Stops'), leading: RootHeaderBarLeading.Back,),
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
          Semantics( container: true,
            child: Column(children: [
            Expanded(child: 
              _processingLocation ? _buildLoading() :
                RefreshIndicator(onRefresh: _onPullToRefresh, child:
                _buildContent()
                ),
            ),
          ],)),
          _buildContentTypesDropdownContainer()
        ],)
      ),
    ],);
  }

  // Content Type Dropdown

  Widget _buildContentTypeDropdownButton() {
    return Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8), child:
      RibbonButton(
        textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat.secondary"),
        backgroundColor: Styles().colors?.white,
        borderRadius: BorderRadius.all(Radius.circular(5)),
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconKey: _contentTypesDropdownExpanded ? 'chevron-up' : 'chevron-down',
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
      rightIconKey: null,
      label: Localization().getStringEx('panel.mtd_stops.home.dropdown.search.title', 'Search Bus Stops'),
      onTap: _onTapSearch
    ),);

    return Semantics(container: true, child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: contentList)
      )
    ));
  }

  Widget _buildContentTypeDropdownItem(MTDStopsContentType contentType) {
    return RibbonButton(
        backgroundColor: Styles().colors?.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconKey: null,
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
      case MTDStopsContentType.all: return Localization().getStringEx('panel.mtd_stops.home.content_type.all.title', 'All Bus Stops');
      case MTDStopsContentType.my: return Localization().getStringEx('panel.mtd_stops.home.content_type.my.title', 'My Bus Stops');
      default: return '';
    }
  }


  void _onTapSearch() {
    Analytics().logSelect(target: "Search Bus Stop");
    setState(() {
      _contentTypesDropdownExpanded = false;
    });
    Navigator.push(context, CupertinoPageRoute(builder: (context) => MTDStopSearchPanel()));
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
      itemBuilder: (context, index) => MTDStopCard(
        stop: ListUtils.entry(_stops, index),
        expanded: _expanded,
        onDetail: _onSelectStop,
        onExpand: _onExpandStop,
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
      return ListUtils.reversed(MTD().stopsByIds(Auth2().account?.prefs?.getFavorites(MTDStop.favoriteKeyName) ?? LinkedHashSet<String>()));
    }
    else {
      return null;
    }
  }

  void _onSelectStop(MTDStop? stop) {
    Analytics().logSelect(target: "Bus Stop: ${stop?.name}" );
    if (stop != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => MTDStopDeparturesPanel(stop: stop)));
    }
  }

  void _onExpandStop(MTDStop? stop) {
    Analytics().logSelect(target: "Bus Stop: ${stop?.name}" );
    if (mounted && (stop?.id != null)) {
      setState(() {
        SetUtils.toggle(_expanded, stop?.id);
      });
    }
  }

  void _onLocationServicesStatusChanged(LocationServicesStatus? status) {
    if (FlexUI().isLocationServicesAvailable && !_processingLocation) {
      LocationServices().location.then((Position? position) {
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

