import 'dart:collection';

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
import 'package:illinois/ui/mtd/MTDWidgets.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/ui/widgets/FilterTextButton.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum MTDStopsScope { all, my }
enum _PanelMode { regular, search }

class MTDStopsHomePanel extends StatefulWidget {
  static final String routeName = 'edu.illinois.rokwire.mtd-stops.home';

  final _PanelMode mode;
  final String? searchText;
  final MTDStopsScope? scope;

  MTDStopsHomePanel({Key? key, this.scope, this.mode = _PanelMode.regular, this.searchText }) : super(key: key);
  
  static void push(BuildContext context, { MTDStopsScope? scope }) =>
    Navigator.push(context, CupertinoPageRoute(
      settings: RouteSettings(name: routeName),
      builder: (context) => MTDStopsHomePanel(scope: scope,)
    ));

  State<MTDStopsHomePanel> createState() => _MTDStopsHomePanelState();
}

class _MTDStopsHomePanelState extends State<MTDStopsHomePanel> with NotificationsListener {
  
  static MTDStopsScope get _defaultContentScope => CollectionUtils.isNotEmpty(Auth2().account?.prefs?.getFavorites(MTDStop.favoriteKeyName)) ? MTDStopsScope.my : MTDStopsScope.all;
  static MTDStopsScope get _defaultSearchScope => MTDStopsScope.all;

  GlobalKey _myStopsButtonKey = GlobalKey();

  ScrollController _scrollController = ScrollController();
  TextEditingController _searchTextController = TextEditingController();
  FocusNode _searchTextNode = FocusNode();

  late MTDStopsScope _scope;
  String? _searchText;
  List<MTDStop>? _displayStops;
  Set<String> _expandedStops = <String>{};

  ContentActivity? _contentActivity;
  Position? _currentPosition;

  bool get _searchMode => (widget.mode == _PanelMode.search);
  bool get _regularMode => (widget.mode == _PanelMode.regular);

  bool get _commandBarVisible => (_regularMode || (_searchMode && (_searchText?.isNotEmpty == true) && (_contentActivity == null)));

  @override
  void initState() {
    NotificationService().subscribe(this, [
      MTD.notifyStopsChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      LocationServices.notifyStatusChanged,
    ]);
    
    _searchText = widget.searchText;
    _searchTextController.text = _searchText ?? '';

    _scope = widget.scope?._ensured ?? (_regularMode ? _defaultContentScope._ensured : _defaultSearchScope._ensured) ?? MTDStopsScope.all;

    if (_regularMode || (_searchMode && (_searchText?.isNotEmpty == true)))
      _loadInitialContent();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _scrollController.dispose();
    _searchTextController.dispose();
    _searchTextNode.dispose();
    super.dispose();
  }

 // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == MTD.notifyStopsChanged) {
      if (mounted) {
        _updateContent(refreshStops: true);
      }
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      if (mounted) {
        _updateContent();
      }
    }
    else if (name == LocationServices.notifyStatusChanged) {
      _onLocationServicesStatusChanged(param);
    }
  }
 
  @override
  Widget build(BuildContext context) =>
    Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.mtd_stops.home.header_bar.title', 'Bus Stops'), leading: RootHeaderBarLeading.Back,),
      body: _scaffoldBody,
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    );

  Widget get _scaffoldBody => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (_searchMode)
      _searchBar,
    if (_commandBarVisible)
      _commandBar,
    Expanded(child:
      RefreshIndicator(onRefresh: _onPullToRefresh, child:
        _bodyContent,
      ),
    )
  ],);

  Widget get _bodyContent {
    if (_contentActivity == ContentActivity.reload) {
      return _loadingContent;
    }
    else if (_contentActivity == ContentActivity.refresh) {
      return Container();
    }
    else if (_searchMode && (_searchText?.isNotEmpty != true)) {
      return Container();
    }
    else if (_displayStops == null) {
      return _buildStatus(widget.mode._displayErrorText(_scope));
    }
    else if (_displayStops?.length == 0) {
      return _buildStatus(widget.mode._displayEmptyText(_scope));
    }
    else {
      return _listContent;
    }
  }


  Widget get _listContent =>
    ListView.builder(
      itemBuilder: _buildListItem,
      itemCount: _displayStops?.length ?? 0,
      controller: _scrollController,
      physics: AlwaysScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      padding: EdgeInsets.all(16),
    );

  Widget _buildListItem(BuildContext context, int index) {
    MTDStop? stop = ListUtils.entry(_displayStops, index);
    return MTDStopCard(
      stop: stop,
      expanded: _expandedStops.contains(stop?.id),
      onDetail: _onSelectStop,
      onExpand: _onExpandStop,
      currentPosition: _currentPosition,
    );
  }

  Widget get _loadingContent =>
    Column(children: [
      Expanded(flex: 1, child: Container()),
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary,)
      ),
      Expanded(flex: 2, child: Container()),
    ],);

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
    if (url == MTDStopsScopeImpl._localUrl) {
      Analytics().logSelect(target: 'Bus Stops', source: widget.runtimeType.toString());
      setState(() {
        _displayStops = _buildStops(scope: _scope = MTDStopsScope.all, searchText: _searchText, currentPosition: _currentPosition);
      });
      return true;
    }
    else if (url == MTDStopsScopeImpl._privacyUrl) {
      Analytics().logSelect(target: 'Privacy Level', source: widget.runtimeType.toString());
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,)));
      return true;
    }
    else {
      return false;
    }
  }

  // Command Bar

  Widget get _commandBar =>
    Container(decoration: _commandBarDecoration, child:
        Column(children: [
          if (_regularMode)
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
              _commandButtonsBar,
            ),
          if (_searchMode && (_searchText?.isNotEmpty == true))
            _contentDescriptionBar,
        ],)
    );

  Decoration get _commandBarDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.disabledTextColor, width: 1)
  );

  Widget get _commandButtonsBar => Row(children: [
    Padding(padding: EdgeInsets.only(left: 16)),
    Expanded(child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [ //Row(mainAxisAlignment: MainAxisAlignment.start, children: [
      if (Auth2().isLoggedIn)
        MergeSemantics(key: _myStopsButtonKey, child:
          Semantics(/* TBD: value: _currentFilterParam.descriptionText, hint: _filtersButtonHint,*/ child:
            FilterTextButton(
              title: Localization().getStringEx('panel.mtd_stops.home.bar.button.my_stops.title', 'My Stops'),
              hint: Localization().getStringEx('panel.mtd_stops.home.bar.button.my_stops.hint', 'Tap to toggle my stops only filter'),
              leftIcon: Styles().images.getImage('groups', size: 16),
              toggled: _scope.starred,
              onTap: _onMyStops,
            ),
          ),
        ),
    ])),
    Expanded(child: Wrap(alignment: WrapAlignment.end, crossAxisAlignment: WrapCrossAlignment.center, verticalDirection: VerticalDirection.up, children: [
      LinkButton(
        title: Localization().getStringEx('panel.mtd_stops.home.bar.button.map.title', 'Map'),
        hint: Localization().getStringEx('panel.mtd_stops.home.bar.button.map.hint', 'Tap to view map'),
        textStyle: Styles().textStyles.getTextStyle('widget.button.title.small.medium.underline'),
        padding: EdgeInsets.only(left: 8, right: _regularMode ? 8 : 16, top: 12, bottom: 12),
        onTap: _onMapView,
      ),
      Visibility(visible: _regularMode, child:
        Event2ImageCommandButton(Styles().images.getImage('search'),
          label: Localization().getStringEx('panel.mtd_stops.home.bar.button.search.title', 'Search'),
          hint: Localization().getStringEx('panel.mtd_stops.home.bar.button.search.hint', 'Tap to search stops'),
          contentPadding: EdgeInsets.only(left: 8, right: 16, top: 12, bottom: 12),
          onTap: _onSearch
        ),
      ),
    ])),
  ],);

  Widget get _contentDescriptionBar {
    // Build description map
    LinkedHashMap<String, List<String>>? descriptionMap = LinkedHashMap<String, List<String>>();

    if (_searchMode && (_searchText?.isNotEmpty == true)) {
      String searchTitle = Localization().getStringEx('panel.mtd_stops.home.bar.description.search.title', 'Search');
      descriptionMap[searchTitle] = <String>[_searchText ?? ''];
    }

    if (_scope == MTDStopsScope.my) {
      String filterTitle = Localization().getStringEx('panel.mtd_stops.home.bar.description.filters.title', 'Filter');
      descriptionMap[filterTitle] = <String>[Localization().getStringEx('', 'Starred')];
    }

    if ((_displayStops != null) && (_contentActivity?.loading != true)) {
      String stopsTitle = Localization().getStringEx('panel.mtd_stops.home.bar.description.stops.title', 'Stops');
      descriptionMap[stopsTitle] = <String>[_displayStops?.length.toString() ?? ''];
    }

    // Build RichText spans list from desriptin map
    List<InlineSpan> descriptionSpans = <InlineSpan>[];
    TextStyle? boldStyle = Styles().textStyles.getTextStyle('widget.card.title.tiny.fat');
    TextStyle? regularStyle = Styles().textStyles.getTextStyle('widget.card.detail.small.regular');
    descriptionMap.forEach((String descriptionCategory, List<String> descriptionItems){
      if (descriptionSpans.isNotEmpty) {
        descriptionSpans.add(TextSpan(text: '; ', style: regularStyle,),);
      }
      if (descriptionItems.isEmpty) {
        descriptionSpans.add(TextSpan(text: descriptionCategory, style: boldStyle,));
      } else {
        descriptionSpans.add(TextSpan(text: "$descriptionCategory: " , style: boldStyle,));
        descriptionSpans.add(TextSpan(text: descriptionItems.join(', '), style: regularStyle,),);
      }
    });

    // Build description bar widget
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(child:
        Padding(padding: EdgeInsets.only(left: 12, top: 16, bottom: 16), child:
          RichText(text: TextSpan(style: regularStyle, children: descriptionSpans)),
        ),
      ),
      LinkButton(
        title: Localization().getStringEx('panel.mtd_stops.home.bar.button.map.title', 'Map'),
        hint: Localization().getStringEx('panel.mtd_stops.home.bar.button.map.hint', 'Tap to view map'),
        textStyle: Styles().textStyles.getTextStyle('widget.button.title.small.medium.underline'),
        padding: EdgeInsets.only(left: 8, right: _regularMode ? 8 : 16, top: 12, bottom: 12),
        onTap: _onMapView,
      ),
    ],);
  }

  // Search Bar

  Widget get _searchBar =>
    Container(decoration: _searchBarDecoration, padding: EdgeInsets.only(left: 16), child:
      Row(children: <Widget>[
        Expanded(child:
          _searchTextField,
        ),
        _buildSearchImageButton('close',
          label: Localization().getStringEx('panel.search.button.clear.title', 'Clear'),
          hint: Localization().getStringEx('panel.search.button.clear.hint', ''),
          onTap: _onTapSearchClear,
        ),
        /*_buildSearchImageButton('search',
          label: Localization().getStringEx('panel.search.button.search.title', 'Search'),
          hint: Localization().getStringEx('panel.search.button.search.hint', ''),
          onTap: _onTapSearch,
        ),*/
      ],),
    );

    Decoration get _searchBarDecoration => BoxDecoration(
      color: Styles().colors.white,
      border: (_commandBarVisible != true) ? Border(bottom: BorderSide(color: Styles().colors.disabledTextColor, width: 1)) : null,
    );

    Widget get _searchTextField => Semantics(
      label: Localization().getStringEx('panel.search.field.search.title', 'Search'),
      hint: Localization().getStringEx('panel.search.field.search.hint', ''),
      textField: true,
      excludeSemantics: true,
      child: TextField(
        controller: _searchTextController,
        focusNode: _searchTextNode,
        onChanged: (text) => _onSearchTextChanged(text),
        onSubmitted: (_) => _onTapSearch(),
        autofocus: true,
        cursorColor: Styles().colors.fillColorSecondary,
        keyboardType: TextInputType.text,
        style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
      ),
    );

    Widget _buildSearchImageButton(String image, {String? label, String? hint, void Function()? onTap}) =>
      Semantics(label: label, hint: hint, button: true, excludeSemantics: true, child:
        InkWell(onTap: onTap, child:
          Padding(padding: EdgeInsets.all(12), child:
            Styles().images.getImage(image, excludeFromSemantics: true),
          ),
        ),
      );

  // Content Data

  Future<void> _loadInitialContent() => _loadContent();
  Future<void> _onPullToRefresh() async => _loadContent(contentActivity: ContentActivity.refresh);
  Future<void> _updateContent({bool refreshStops = false, bool refreshCurrentPosition = false}) =>
    _loadContent(refreshStops: refreshStops, refreshCurrentPosition: false, restoreScrollPosition: true);

  Future<void> _loadContent({
    ContentActivity contentActivity = ContentActivity.reload,
    bool refreshStops = true,
    bool refreshCurrentPosition = true,
    bool restoreScrollPosition = false
  }) async {
    if (contentActivity.canOverride(_contentActivity) && mounted) {
      double scrollPosition = _scrollController.hasClients ? _scrollController.offset : 0;
      setState(() {
        _contentActivity = contentActivity;
      });
      List<dynamic> results = await Future.wait([
        if (refreshCurrentPosition)
          LocationServices().location,
        if (refreshStops)
          MTD().refreshStops(),
      ]);
      if (mounted && (_contentActivity == contentActivity)) {
        Position? currentPosition = refreshCurrentPosition ? JsonUtils.cast(results.first) : _currentPosition;
        setState(() {
          _displayStops = _buildStops(scope: _scope, searchText: _searchText, currentPosition: currentPosition);
          _currentPosition = currentPosition;
          _contentActivity = null;
        });

        if (restoreScrollPosition) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.jumpTo(scrollPosition);
          });
        }
      }
    }
  }

  static List<MTDStop>? _buildStops({ required MTDStopsScope scope, String? searchText, Position? currentPosition }) {
    if (scope == MTDStopsScope.all) {
      List<MTDStop>? stops = ((searchText != null) && searchText.isNotEmpty) ? MTD().stops?.searchStop(searchText) : ListUtils.from(MTD().stops?.stops);
      if ((stops != null) && (currentPosition != null)) {
        stops.sort((MTDStop stop1, MTDStop stop2) {
          LatLng? position1 = stop1.anyPosition;
          LatLng? position2 = stop2.anyPosition;
          if ((position1 != null) && position1.isValid && (position2 != null) && position2.isValid) {
            double distance1 = Geolocator.distanceBetween(position1.latitude ?? 0, position1.longitude ?? 0, currentPosition.latitude, currentPosition.longitude);
            double distance2 = Geolocator.distanceBetween(position2.latitude ?? 0, position2.longitude ?? 0, currentPosition.latitude, currentPosition.longitude);
            return distance1.compareTo(distance2);
          }
          else {
            return 0;
          }
        });
      }
      return stops;
    }
    else if (scope == MTDStopsScope.my) {
      List<MTDStop>? favoriteStops = ((searchText != null) && searchText.isNotEmpty) ?
        MTDStop.searchInList(MTD().favoriteStops, search: searchText.toLowerCase()) : MTD().favoriteStops;
      return ListUtils.reversed(favoriteStops);
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
        SetUtils.toggle(_expandedStops, stop?.id);
      });
    }
  }

  void _onLocationServicesStatusChanged(LocationServicesStatus? status) {
    if (FlexUI().isLocationServicesAvailable) {
      _updateContent(refreshCurrentPosition: true);
    }
  }

  void _onSearch() {
    Analytics().logSelect(target: "Search Bus Stop");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => MTDStopsHomePanel(mode: _PanelMode.search, /*scope: _scope*/)));
  }

  void _onMapView() {
    Analytics().logSelect(target: 'Map View');
    Map2FilterBusStopsParam param;
    switch (widget.mode) {
      case _PanelMode.regular: param = Map2FilterBusStopsParam(starred: _scope.starred == true); break;
      case _PanelMode.search: param = Map2FilterBusStopsParam(searchText: _searchText ?? ''); break;
    }
    NotificationService().notify(Map2.notifySelect, param);
  }

  void _onMyStops() {
    Analytics().logSelect(target: 'My Stops');
    setState(() {
      setState(() {
        _displayStops = _buildStops(scope: _scope = _scope._toggled, searchText: _searchText, currentPosition: _currentPosition);
      });
    });
  }

  void _onTapSearch() {
    Analytics().logSelect(target: "Search Bus Stops");
    String searchValue = _searchTextController.text.trim();
    if (searchValue.isNotEmpty) {
      FocusScope.of(context).requestFocus(FocusNode());
      _search(searchValue);
    }
    else {
      _clearSearch();
    }
  }

  void _onSearchTextChanged(String text) {
    String searchValue = _searchTextController.text.trim();
    if (searchValue.isNotEmpty) {
      _search(searchValue);
    }
    else {
      _clearSearch();
    }
  }

  void _onTapSearchClear() {
    if (StringUtils.isEmpty(_searchTextController.text)) {
      Navigator.pop(context);
    }
    else {
      _clearSearch();
    }
  }

  void _search(String searchValue) {
    if ((0 < searchValue.length) && (searchValue != _searchText)) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      setState(() {
        _displayStops = _buildStops(scope: _scope, searchText: _searchText = searchValue, currentPosition: _currentPosition);
        _expandedStops.clear();
      });
    }
  }

  void _clearSearch() {
    _searchTextController.clear();
    setState(() {
      _displayStops = null;
      _searchText = null;
    });
  }
}

// MTDStopsScope

extension MTDStopsScopeImpl on MTDStopsScope {

  static const String _localUrl = 'local://bus_stops';
  static const String _localUrlMacro = '{{local_url}}';
  static const String _privacyUrl = 'privacy://level';
  static const String _privacyUrlMacro = '{{privacy_url}}';

  String get displayTitle => displayTitleEx();
  String get displayTitleEn => displayTitleEx('en');

  String displayTitleEx([String? language]) {
    switch (this) {
      case MTDStopsScope.all: return Localization().getStringEx('panel.explore.label.mtd_stops.scope.all.title', 'All Stops', language: language);
      case MTDStopsScope.my: return Localization().getStringEx('panel.explore.label.mtd_stops.scope.my.title', 'My Stops', language: language);
    }
  }

  String get _displayErrorContentText {
    switch(this) {
      case MTDStopsScope.all: return Localization().getStringEx('panel.mtd_stops.home.status.error.all.text', 'Failed to load bus stops.');
      case MTDStopsScope.my: return Localization().getStringEx('panel.mtd_stops.home.status.error.my.text', 'Failed to load saved bus stops.');
    }
  }

  String get _displayErrorSearchText {
    switch(this) {
      case MTDStopsScope.all: return Localization().getStringEx('panel.mtd_stops.home.search.error.all.text', 'Failed to search bus stops.');
      case MTDStopsScope.my: return Localization().getStringEx('panel.mtd_stops.home.search.error.my.text', 'Failed to search saved bus stops.');
    }
  }

  String get _displayEmptyContentHtml {
    switch(this) {
      case MTDStopsScope.all: return Localization().getStringEx('panel.mtd_stops.home.status.empty.all.text', 'There are no bus stops available.');
      case MTDStopsScope.my: return Localization().getStringEx('panel.mtd_stops.home.status.empty.my.text', "Tap the \u2606 on <a href='$_localUrlMacro'><b>bus stops</b></a> for quick access here. (<a href='$_privacyUrlMacro'>Your privacy level</a> must be at least 3.)")
        .replaceAll(_localUrlMacro, _localUrl)
        .replaceAll(_privacyUrlMacro, _privacyUrl);
    }
  }

  String get _displayEmptySearchText {
    switch(this) {
      case MTDStopsScope.all: return Localization().getStringEx('panel.mtd_stops.home.search.empty.all.text', 'There are no bus stops matcing the search term.');
      case MTDStopsScope.my: return Localization().getStringEx('panel.mtd_stops.home.search.empty.my.text', "There are no saved bus stops matcing the search term.");
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

  bool get all => this == MTDStopsScope.all;
  bool get starred => this == MTDStopsScope.my;

  MTDStopsScope? get _ensured => (Auth2().isLoggedIn || all) ? this : null;
  MTDStopsScope get _toggled => all ? MTDStopsScope.my : MTDStopsScope.all;
}

extension _PanelModeImpl on _PanelMode {
  String _displayErrorText(MTDStopsScope scope) {
    switch(this) {
      case _PanelMode.regular: return scope._displayErrorContentText;
      case _PanelMode.search: return scope._displayErrorSearchText;
    }
  }

  String _displayEmptyText(MTDStopsScope scope) {
    switch(this) {
      case _PanelMode.regular: return scope._displayEmptyContentHtml;
      case _PanelMode.search: return scope._displayEmptySearchText;
    }
  }
}