import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/MTD.dart';
import 'package:illinois/model/Location.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/explore/ExploreMapPanel.dart';
import 'package:illinois/ui/mtd/MTDStopDeparturesPanel.dart';
import 'package:illinois/ui/mtd/MTDStopSearchPanel.dart';
import 'package:illinois/ui/mtd/MTDWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum MTDStopsScope { all, my }

class MTDStopsHomePanel extends StatefulWidget {

  final MTDStopsScope? scope;

  MTDStopsHomePanel({Key? key, this.scope}) : super(key: key);
  
  State<MTDStopsHomePanel> createState() => _MTDStopsHomePanelState();
}

class _MTDStopsHomePanelState extends State<MTDStopsHomePanel> implements NotificationsListener {
  
  static Color _dimmedBackgroundColor = Color(0x99000000);

  MTDStopsScope? _selectedScope;
  bool _contentTypesDropdownExpanded = false;
  List<MTDStop>? _stops;
  Set<String> _expanded = <String>{};

  Position? _currentPosition;
  bool _processing = false;
  bool _refreshing = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      MTD.notifyStopsChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      LocationServices.notifyStatusChanged,
    ]);
    
    if (widget.scope != null) {
      _selectedScope = widget.scope;
    }
    else {
      _selectedScope = CollectionUtils.isNotEmpty(Auth2().account?.prefs?.getFavorites(MTDStop.favoriteKeyName)) ? MTDStopsScope.my : MTDStopsScope.all;
    }

    _updateStops();
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
      if (mounted && !_processing) {
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
  Widget build(BuildContext context) =>
    _buildScaffoldContent();

  Widget _buildScaffoldContent() =>
    Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.mtd_stops.home.header_bar.title', 'Bus Stops'), leading: RootHeaderBarLeading.Back,),
      body: _buildPanelContent(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    );

  Widget _buildPanelContent() =>
    Column(children: [
      _buildContentTypeDropdownButton(),
      Expanded(child:
        Stack(children: [
          Semantics( container: true, child:
            Column(children: [
              Expanded(child:
                _processing ? _buildLoading() : RefreshIndicator(onRefresh: _onPullToRefresh, child:
                  _buildBusStopsContent()
                ),
              ),
            ],),
          ),
          _buildContentTypesDropdownContainer()
        ],)
      ),
    ],);

  // Content Type Dropdown

  Widget _buildContentTypeDropdownButton() {
    return Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8), child:
      RibbonButton(
        textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"),
        backgroundColor: Styles().colors.white,
        borderRadius: BorderRadius.all(Radius.circular(5)),
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        rightIconKey: _contentTypesDropdownExpanded ? 'chevron-up' : 'chevron-down',
        label: _getContentTypeName(_selectedScope),
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
    contentList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));
    for (MTDStopsScope contentType in MTDStopsScope.values) {
      if ((_selectedScope != contentType)) {
        contentList.add(_buildContentTypeDropdownItem(contentType));
      }
    }

    return Semantics(container: true, child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: contentList)
      )
    ));
  }

  Widget _buildContentTypeDropdownItem(MTDStopsScope contentType) {
    return RibbonButton(
        backgroundColor: Styles().colors.white,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
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

  void _onTapContentTypeDropdownItem(MTDStopsScope contentType) {
    Analytics().logSelect(target: _getContentTypeName(contentType, languageCode: 'en'));
    if (_selectedScope != contentType) {
      setState(() {
        _selectedScope = contentType;
        _contentTypesDropdownExpanded = false;
        _stops = _contentList;
      });
    }
  }


  static String _getContentTypeName(MTDStopsScope? contentType, {String? languageCode} ) =>
      contentType?.titleEx(languageCode: languageCode) ?? '';

  // Content Widget

  Widget _buildCommandBar() => Wrap(alignment: WrapAlignment.end, crossAxisAlignment: WrapCrossAlignment.center, children: [
    LinkButton(
      title: Localization().getStringEx('panel.events2.home.bar.button.map.title', 'Map'),
      hint: Localization().getStringEx('panel.events2.home.bar.button.map.hint', 'Tap to view map'),
      textStyle: Styles().textStyles.getTextStyle('widget.button.title.regular.underline'),
      padding: EdgeInsets.only(left: 0, right: 8, top: 12, bottom: 12),
      onTap: _onMapView,
    ),
    Event2ImageCommandButton(Styles().images.getImage('search'),
      label: Localization().getStringEx('panel.events2.home.bar.button.search.title', 'Search'),
      hint: Localization().getStringEx('panel.events2.home.bar.button.search.hint', 'Tap to search events'),
      contentPadding: EdgeInsets.only(left: 8, right: 16, top: 12, bottom: 12),
      onTap: _onSearch
    ),
  ],);

  Widget _buildBusStopsContent() {
    if (_refreshing) {
      return Container();
    }
    else if (_stops == null) {
      return _buildStatus(_errorDisplayStatus);
    }
    else if (_stops!.isEmpty) {
      return _buildStatus(_emptyDisplayStatus);
    }
    else {
      return _buildStops();
    }
  }

  Widget _buildStops() =>
    Column(children: [
      Align(alignment: Alignment.centerRight, child:
        _buildCommandBar(),
      ),
      Expanded(child:
        ListView.separated(
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
        ),
      )
    ],);

  Widget _buildLoading() {
    return Align(alignment: Alignment.center, child:
      CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3, ),
    );
  }

  Widget _buildStatus(String status) {
    double screenHeight = MediaQuery.of(context).size.height;
    return SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child:
      Padding(padding: EdgeInsets.only(left: 32, right: 32, top: screenHeight / 5), child:
        Row(children: [
          Expanded(child:
            Text(status ,style:
              Styles().textStyles.getTextStyle("widget.message.large"), textAlign: TextAlign.center,),
          ),
        ],)
      ),
    );
  }

  String get _errorDisplayStatus {
    switch(_selectedScope) {
      case MTDStopsScope.all: return Localization().getStringEx('panel.mtd_stops.home.status.error.all.text', 'Failed to load bus stops.');
      case MTDStopsScope.my: return Localization().getStringEx('panel.mtd_stops.home.status.error.my.text', 'Failed to load saved bus stops.');
      default: return '';
    }
  }

  String get _emptyDisplayStatus {
    switch(_selectedScope) {
      case MTDStopsScope.all: return Localization().getStringEx('panel.mtd_stops.home.status.empty.all.text', 'There are no bus stops available.');
      case MTDStopsScope.my: return Localization().getStringEx('panel.mtd_stops.home.status.empty.my.text', 'You have no saved bus stops.');
      default: return '';
    }
  }

  // Content Data

  Future<void> _updateStops() async {
    setStateIfMounted(() {
      _processing = true;
    });
    _currentPosition = await LocationServices().location;
    if (mounted) {
      if (MTD().stops == null) {
        await MTD().refreshStops();
      }
      if (mounted) {
        setState(() {
          _processing = false;
          _stops = _contentList;
        });
      }
    }
  }

  Future<void> _onPullToRefresh() async {
    setStateIfMounted((){
      _refreshing = true;
    });
    await MTD().refreshStops();
    setStateIfMounted((){
      _refreshing = false;
    });
  }

  List<MTDStop>? get _contentList {
    if (_selectedScope == MTDStopsScope.all) {
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
    else if (_selectedScope == MTDStopsScope.my) {
      return ListUtils.reversed(MTD().favoriteStops);
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
    if (FlexUI().isLocationServicesAvailable && !_processing) {
      _updateStops();
    }
  }

  void _onSearch() {
    Analytics().logSelect(target: "Search Bus Stop");
    setState(() {
      _contentTypesDropdownExpanded = false;
    });
    Navigator.push(context, CupertinoPageRoute(builder: (context) => MTDStopSearchPanel(scope: _selectedScope ?? MTDStopsScope.all,)));
  }

  void _onMapView() {
    Analytics().logSelect(target: 'Map View');
    NotificationService().notify(ExploreMapPanel.notifySelect, ExploreMapSearchMTDStopsParam(scope: _selectedScope ?? MTDStopsScope.all));
  }
}

extension MTDStopsScopeExt on MTDStopsScope {

  String get title => titleEx();
  String titleEx({String? languageCode}) {
    switch (this) {
      case MTDStopsScope.all: return Localization().getStringEx('panel.mtd_stops.home.content_type.all.title', 'All Bus Stops', language: languageCode);
      case MTDStopsScope.my: return Localization().getStringEx('panel.mtd_stops.home.content_type.my.title', 'My Bus Stops', language: languageCode);
    }
  }

  String get hint => hintEx();
  String hintEx({String? languageCode}) {
    switch (this) {
      case MTDStopsScope.all: return Localization().getStringEx('panel.explore.label.mtd_stops.scope.all.title', 'All Stops', language: languageCode);
      case MTDStopsScope.my: return Localization().getStringEx('panel.explore.label.mtd_stops.scope.my.title', 'My Stops', language: languageCode);
    }
  }
}
