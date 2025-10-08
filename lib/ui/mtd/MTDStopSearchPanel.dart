
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/MTD.dart';
import 'package:illinois/model/Location.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/ui/map2/Map2HomeExts.dart';
import 'package:illinois/ui/map2/Map2HomePanel.dart';
import 'package:illinois/ui/mtd/MTDStopDeparturesPanel.dart';
import 'package:illinois/ui/mtd/MTDStopsHomePanel.dart';
import 'package:illinois/ui/mtd/MTDWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/PopScopeFix.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class MTDStopSearchPanel extends StatefulWidget {
  final String? searchText;
  final MTDStopsScope scope;
  final MTDStopSearchContext? searchContext;

  MTDStopSearchPanel({ Key? key, this.scope = MTDStopsScope.all, this.searchText, this.searchContext }) : super(key: key);

  @override
  State<MTDStopSearchPanel> createState() => _MTDStopSearchPanelState();
}

class _MTDStopSearchPanelState extends State<MTDStopSearchPanel> with NotificationsListener {

  TextEditingController _searchController = TextEditingController();
  String? _searchText;
  List<MTDStop>? _stops;
  Set<String> _expanded = <String>{};

  Position? _currentPosition;

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    NotificationService().subscribe(this, [
      MTD.notifyStopsChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      LocationServices.notifyStatusChanged,
    ]);

    _scrollController.addListener(_scrollListener);

    String? initialSearchText = widget.searchText;
    if ((initialSearchText != null) && initialSearchText.isNotEmpty) {
      _searchController.text = _searchText = initialSearchText;
      _stops = _buildStops(initialSearchText);
    }

    LocationServices().location.then((Position? position) {
      _currentPosition = position;
      if (mounted) {
        setState(() {});
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

 // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == MTD.notifyStopsChanged) {
      _updateSearchResults();
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
    PopScopeFix(onBack: _onHeaderBarBack, child: _buildScaffoldContent());

  Widget _buildScaffoldContent() =>
    Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.mtd_stops.search.header.title", "Search"),
        onLeading: _onHeaderBarBack,
      ),
      body: _buildPanelContent(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    );

  Widget _buildPanelContent() =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      _buildSearchBar(),
      _buildInfoBar(),
      Expanded(child:
        _buildResultsList()
      )
    ],);

  Widget _buildSearchBar() =>
    Container(height: 48, padding: EdgeInsets.only(left: 16), color: Colors.white, child:
      Row(children: <Widget>[
        Flexible(child:
          Semantics(textField: true, excludeSemantics: true,
            label: Localization().getStringEx('panel.mtd_stops.search.search.field.title', 'Search'),
            hint: Localization().getStringEx('panel.mtd_stops.search.search.field.search.hint', ''),
            child: TextField(
              controller: _searchController,
              onChanged: (text) => _onSearchTextChanged(text),
              onSubmitted: (_) => _onTapSearch(),
              autofocus: true,
              cursorColor: Styles().colors.fillColorSecondary,
              keyboardType: TextInputType.text,
              style: Styles().textStyles.getTextStyle("widget.input_field.text.regular"),
              decoration: InputDecoration(
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        Semantics(button: true, excludeSemantics: true,
            label: Localization().getStringEx('panel.mtd_stops.search.clear.button.title', 'Clear'),
            hint: Localization().getStringEx('panel.mtd_stops.search.clear.button.hint', ''),
            child: GestureDetector(onTap: _onTapClear, child:
              Padding(padding: EdgeInsets.all(16), child:
                Styles().images.getImage('close', excludeFromSemantics: true)
              ),
            )
        ),
        /*Semantics(button: true, excludeSemantics: true,
          label: Localization().getStringEx('panel.mtd_stops.search.search.button.title', 'Search'),
          hint: Localization().getStringEx('panel.mtd_stops.search.search.button.hint', ''),
          child: Padding(padding: EdgeInsets.all(12), child:
            GestureDetector(onTap: _onTapSearch, child:
              Image.asset('images/icon-search.png', color: Styles().colors.fillColorSecondary),
            ),
          ),
        ),*/
      ],),
    );

  Widget _buildInfoBar() =>
    InkWell(onTap: _onTapInfo, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child:
            Padding(padding: EdgeInsets.all(16), child:
              RichText(text:
                TextSpan(style: Styles().textStyles.getTextStyle("widget.button.title.large.thin"), children: <TextSpan>[
                  TextSpan(text: _searchLabel, style: Styles().textStyles.getTextStyle("widget.text.semi_fat")),
                ],),
              )
            ),
          ),
          if (_searchText?.isNotEmpty == true)
            LinkButton(
              title: Localization().getStringEx('panel.events2.home.bar.button.map.title', 'Map'),
              hint: Localization().getStringEx('panel.events2.home.bar.button.map.hint', 'Tap to view map'),
              textStyle: Styles().textStyles.getTextStyle('widget.button.title.regular.underline'),
              padding: EdgeInsets.only(left: 0, right: 16, top: 12, bottom: 12),
              onTap: _onMapView,
            ),
        ],),
        Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 24), child:
          Text(_resultsCountLabel, style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
          ),
        ),
      ],),
    );

  String get _searchLabel {
    if (_searchText != null) {
      switch(widget.scope) {
        case MTDStopsScope.all: return sprintf(Localization().getStringEx('panel.mtd_stops.search.label.results_for.all', 'Results for %s'), [_searchText ?? '']);
        case MTDStopsScope.my: return sprintf(Localization().getStringEx('panel.mtd_stops.search.label.results_for.my', 'Results for %s'), [_searchText ?? '']);
      }
    }
    else {
      switch(widget.scope) {
        case MTDStopsScope.all: return Localization().getStringEx('panel.mtd_stops.search.label.search_for.all', 'Searching Bus Stops');
        case MTDStopsScope.my: return Localization().getStringEx('panel.mtd_stops.search.label.search_for.my', 'Searching My Bus Stops');
      }
    }
  }

  String get _resultsCountLabel {
    int? resultsCount = _stops?.length;
    if (resultsCount == null) {
      return '';
    }
    else if (resultsCount == 0) {
      return Localization().getStringEx('panel.mtd_stops.search.label.not_found', 'No results found');
    }
    else if (resultsCount == 1) {
      return Localization().getStringEx('panel.mtd_stops.search.label.found_single', '1 result found');
    }
    else {
      return sprintf(Localization().getStringEx('panel.mtd_stops.search.label.found_multi', '%d results found'), [resultsCount]);
    }
  }

  Widget _buildResultsList() {
    return (CollectionUtils.isNotEmpty(_stops)) ? ListView.separated(
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
      controller: _scrollController,
    ) : Container();
  }

  void _updateSearchResults() {
    if (mounted && (_searchText != null)) {
      setState(() {
        _stops = _buildStops(_searchText!);
      });
    }
  }

  void _search(String searchValue) {
    if ((0 < searchValue.length) && (searchValue != _searchText)) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      setState(() {
        _stops = _buildStops(_searchText = searchValue);
      });
    }
  }

  List<MTDStop>? _buildStops(String searchValue) {

    if (widget.scope == MTDStopsScope.all) {
      List<MTDStop> stops = MTD().stops?.searchStop(searchValue) ?? <MTDStop>[];

      if (_currentPosition != null) {
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
    else if (widget.scope == MTDStopsScope.my) {
      return MTDStop.searchInList(MTD().favoriteStops, search: searchValue.toLowerCase());
    }
    else {
      return [];
    }
  }

  void _clear() {
    _searchController.clear();
    setState(() {
      _stops = null;
      _searchText = null;
    });
  }

  void _onTapInfo() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _onMapView() {
    Analytics().logSelect(target: 'Map View');
    if (widget.searchContext == MTDStopSearchContext.Map) {
      Navigator.of(context).pop((_searchText?.isNotEmpty == true) ? _searchText : _searchController.text);
    }
    else {
      NotificationService().notify(Map2HomePanel.notifySelect, Map2FilterBusStopsParam(searchText: _searchText ?? '', starred: widget.scope.starred ));
    }
  }

  void _scrollListener() {
    if (View.of(context).viewInsets.bottom > 0.0) {
      FocusScope.of(context).requestFocus(FocusNode());
    }
  }

  void _onTapSearch() {
    Analytics().logSelect(target: "Search Bus Stops");
    String searchValue = _searchController.text.trim();
    if (searchValue.isNotEmpty) {
      FocusScope.of(context).requestFocus(FocusNode());
      _search(searchValue);
    }
    else {
      _clear();
    }
  }

  void _onTapClear() {
    Analytics().logSelect(target: "Clear Search");
    if (StringUtils.isEmpty(_searchController.text)) {
      Navigator.pop(context);
    }
    else {
      _clear();
    }
  }

  void _onSearchTextChanged(String text) {
    String searchValue = _searchController.text.trim();
    if (searchValue.isNotEmpty) {
      _search(searchValue);
    }
    else {
      _clear();
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
    if (FlexUI().isLocationServicesAvailable) {
      LocationServices().location.then((Position? position) {
        _currentPosition = position;
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  void _onHeaderBarBack() {
    Analytics().logSelect(target: 'HeaderBar: Back');
    Navigator.of(context).pop((_searchText?.isNotEmpty == true) ? _searchText : _searchController.text);
  }
}

enum MTDStopSearchContext { List, Map }