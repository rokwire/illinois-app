
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/model/Location.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/ui/mtd/MTDStopDeparturesPanel.dart';
import 'package:illinois/ui/mtd/MTDWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class MTDStopSearchPanel extends StatefulWidget {
  MTDStopSearchPanel({Key? key }) : super(key: key);

  @override
  State<MTDStopSearchPanel> createState() => _MTDStopSearchPanelState();
}

class _MTDStopSearchPanelState extends State<MTDStopSearchPanel> implements NotificationsListener {

  TextEditingController _searchController = TextEditingController();
  String? _searchValue;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.mtd_stops.search.header.title", "Search"),
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
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
                cursorColor: Styles().colors!.fillColorSecondary,
                keyboardType: TextInputType.text,
                style: Styles().textStyles?.getTextStyle("widget.input_field.text.regular"),
                decoration: InputDecoration(
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Semantics(button: true, excludeSemantics: true,
              label: Localization().getStringEx('panel.mtd_stops.search.clear.button.title', 'Clear'),
              hint: Localization().getStringEx('panel.mtd_stops.search.clear.button.hint', ''),
              child: Padding(padding: EdgeInsets.all(16), child:
                GestureDetector(onTap: _onTapClear, child:
                  Styles().images?.getImage('close', excludeFromSemantics: true)
                ),
              )
          ),
          /*Semantics(button: true, excludeSemantics: true,
            label: Localization().getStringEx('panel.mtd_stops.search.search.button.title', 'Search'),
            hint: Localization().getStringEx('panel.mtd_stops.search.search.button.hint', ''),
            child: Padding(padding: EdgeInsets.all(12), child:
              GestureDetector(onTap: _onTapSearch, child:
                Image.asset('images/icon-search.png', color: Styles().colors!.fillColorSecondary),
              ),
            ),
          ),*/
        ],),
      ),
      InkWell(onTap: _onTapInfo, child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: EdgeInsets.all(16), child:
            RichText(text:
              TextSpan(style: Styles().textStyles?.getTextStyle("widget.button.title.large.thin"), children: <TextSpan>[
                TextSpan(text: _searchLabel, style: Styles().textStyles?.getTextStyle("widget.text.semi_fat")),
              ],),
            )
          ),
          Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 24), child:
            Text(_resultsCountLabel, style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"),
            ),
          ),
        ],),
      ),
      Expanded(child:
        _buildResultsList()
      )
    ],);
  }

  String get _searchLabel {
    return (_searchValue != null) ?
      sprintf(Localization().getStringEx('panel.mtd_stops.search.label.results_for', 'Results for %s'), [_searchValue!]) :
      Localization().getStringEx('panel.mtd_stops.search.label.search_for', 'Searching Bus Stops');
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
    if (mounted && (_searchValue != null)) {
      setState(() {
        _stops = _buildStops(_searchValue!);     
      });
    }
  }

  void _search(String searchValue) {
    if ((0 < searchValue.length) && (searchValue != _searchValue)) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      setState(() {
        _stops = _buildStops(_searchValue = searchValue);
      });
    }
  }

  List<MTDStop>? _buildStops(String searchValue) {
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

  void _clear() {
    _searchController.clear();
    setState(() {
      _stops = null;
      _searchValue = null;
    });
  }

  void _onTapInfo() {
    FocusScope.of(context).requestFocus(FocusNode());
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
}