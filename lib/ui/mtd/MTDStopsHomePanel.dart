import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/MTD.dart';
import 'package:illinois/model/Location.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/service/Map2.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/map2/Map2HomeExts.dart';
import 'package:illinois/ui/mtd/MTDStopDeparturesPanel.dart';
import 'package:illinois/ui/mtd/MTDStopSearchPanel.dart';
import 'package:illinois/ui/mtd/MTDWidgets.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
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

class _MTDStopsHomePanelState extends State<MTDStopsHomePanel> with NotificationsListener {
  
  static Color _dimmedBackgroundColor = Color(0x99000000);
  static MTDStopsScope get _defaultScope => CollectionUtils.isNotEmpty(Auth2().account?.prefs?.getFavorites(MTDStop.favoriteKeyName)) ? MTDStopsScope.my : MTDStopsScope.all;

  static const String _localUrl = 'local://bus_stops';
  static const String _localUrlMacro = '{{local_url}}';
  static const String _privacyUrl = 'privacy://level';
  static const String _privacyUrlMacro = '{{privacy_url}}';

  late List<MTDStopsScope> _scopes;
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
    
    _scopes = _MTDStopsScopeList.fromContentTypes(MTDStopsScope.values);
    _selectedScope = widget.scope?._ensure(availableScopes: _scopes) ??
      _defaultScope._ensure(availableScopes: _scopes) ??
      (_scopes.isNotEmpty ? _scopes.first : null);

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
        title: _selectedScope?.displayTitle,
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
    for (MTDStopsScope scope in _scopes) {
      if (scope != _selectedScope) {
        contentList.add(RibbonButton(
          backgroundColor: Styles().colors.white,
          border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
          textStyle: Styles().textStyles.getTextStyle((_selectedScope == scope) ? 'widget.button.title.medium.fat.secondary' : 'widget.button.title.medium.fat'),
          rightIconKey: (_selectedScope == scope) ? 'check-accent' : null,
          title: scope.displayTitle,
          onTap: () => _onTapContentTypeDropdownItem(scope)
        ));
      }
    }

    return Semantics(container: true, child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: contentList)
      )
    ));
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
    Analytics().logSelect(target: contentType.displayTitleEn);
    if (_selectedScope != contentType) {
      setState(() {
        _selectedScope = contentType;
        _contentTypesDropdownExpanded = false;
        _stops = _contentList;
      });
    }
    else {
      setState(() {
        _contentTypesDropdownExpanded = false;
      });
    }
  }

  void _selectContentType(MTDStopsScope contentType) {
    if (_selectedScope != contentType) {
      setState(() {
        _selectedScope = contentType;
        _contentTypesDropdownExpanded = false;
        _stops = _contentList;
      });
    }
  }


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
      return _buildStatus(_emptyDisplayStatusHtml);
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

  Widget _buildStatus(String statusHtml) {
    double screenHeight = MediaQuery.of(context).size.height;
    return SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child:
      Padding(padding: EdgeInsets.only(left: 32, right: 32, top: screenHeight / 5), child:
        Row(children: [
          Expanded(child:
            HtmlWidget("<center>$statusHtml</center>" ,
              onTapUrl: _handleLocalUrl,
              textStyle: Styles().textStyles.getTextStyle("widget.message.regular"),
              customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null
            )
          ),
        ],)
      ),
    );
  }

  bool _handleLocalUrl(String? url) {
    if (url == _localUrl) {
      Analytics().logSelect(target: 'Bus Stops', source: widget.runtimeType.toString());
      _selectContentType(MTDStopsScope.all);
      return true;
    }
    else if (url == _privacyUrl) {
      Analytics().logSelect(target: 'Privacy Level', source: widget.runtimeType.toString());
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,)));
      return true;
    }
    else {
      return false;
    }
  }

  String get _errorDisplayStatus {
    switch(_selectedScope) {
      case MTDStopsScope.all: return Localization().getStringEx('panel.mtd_stops.home.status.error.all.text', 'Failed to load bus stops.');
      case MTDStopsScope.my: return Localization().getStringEx('panel.mtd_stops.home.status.error.my.text', 'Failed to load saved bus stops.');
      default: return '';
    }
  }

  String get _emptyDisplayStatusHtml {
    switch(_selectedScope) {
      case MTDStopsScope.all: return Localization().getStringEx('panel.mtd_stops.home.status.empty.all.text', 'There are no bus stops available.');
      case MTDStopsScope.my: return Localization().getStringEx('panel.mtd_stops.home.status.empty.my.text', "Tap the \u2606 on <a href='$_localUrlMacro'><b>bus stops</b></a> for quick access here. (<a href='$_privacyUrlMacro'>Your privacy level</a> must be at least 2.)")
        .replaceAll(_localUrlMacro, _localUrl)
        .replaceAll(_privacyUrlMacro, _privacyUrl);
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
    NotificationService().notify(Map2.notifySelect, Map2FilterBusStopsParam(starred: _selectedScope?.starred == true));
  }
}

// MTDStopsScope

extension MTDStopsScopeImpl on MTDStopsScope {
  String get displayTitle => displayTitleLng();
  String get displayTitleEn => displayTitleLng('en');

  String displayTitleLng([String? language]) {
    switch (this) {
      case MTDStopsScope.all: return Localization().getStringEx('panel.mtd_stops.home.content_type.all.title', 'All Bus Stops', language: language);
      case MTDStopsScope.my: return Localization().getStringEx('panel.mtd_stops.home.content_type.my.title', 'My Bus Stops', language: language);
    }
  }

  String get displayHint => displayHintLng();
  String get displayHintEn => displayHintLng('en');

  String displayHintLng([String? language]) {
    switch (this) {
      case MTDStopsScope.all: return Localization().getStringEx('panel.explore.label.mtd_stops.scope.all.title', 'All Stops', language: language);
      case MTDStopsScope.my: return Localization().getStringEx('panel.explore.label.mtd_stops.scope.my.title', 'My Stops', language: language);
    }
  }

  String get jsonString {
    switch (this) {
      case MTDStopsScope.all: return 'all';
      case MTDStopsScope.my: return 'my';
    }
  }

  static MTDStopsScope? fromJsonString(String? value) {
    switch(value) {
      case 'all': return MTDStopsScope.all;
      case 'my': return MTDStopsScope.my;
      default: return null;
    }
  }

  bool get starred => this == MTDStopsScope.my;

  MTDStopsScope? _ensure({List<MTDStopsScope>? availableScopes}) =>
    (availableScopes?.contains(this) != false) ? this : null;
}

extension _MTDStopsScopeList on List<MTDStopsScope> {
  void sortAlphabetical() => sort((MTDStopsScope t1, MTDStopsScope t2) => t1.displayTitle.compareTo(t2.displayTitle));

  static List<MTDStopsScope> fromContentTypes(Iterable<MTDStopsScope> contentTypes) {
    List<MTDStopsScope> contentTypesList = List<MTDStopsScope>.from(contentTypes);
    contentTypesList.sortAlphabetical();
    return contentTypesList;
  }
}
