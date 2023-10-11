/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2DetailPanel.dart';
import 'package:illinois/ui/events2/Event2HomePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/explore/ExploreMapPanel.dart';
import 'package:illinois/ui/widgets/GestureDetector.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:timezone/timezone.dart';

class Event2SearchPanel extends StatefulWidget {
  final String? searchText;
  final Event2SearchContext? searchContext;
  final LocationServicesStatus? locationServicesStatus;
  final Position? userLocation;
  final Event2Selector? eventSelector;

  Event2SearchPanel({Key? key, this.searchText, this.searchContext, this.locationServicesStatus, this.userLocation, this.eventSelector}) : super(key: key);

  @override
  _Event2SearchPanelState createState() => _Event2SearchPanelState();
}

class _Event2SearchPanelState extends State<Event2SearchPanel> implements NotificationsListener {

  ScrollController _scrollController = ScrollController();
  TextEditingController _searchTextController = TextEditingController();
  FocusNode _searchTextNode = FocusNode();

  Client? _searchClient;
  Client? _refreshClient;
  Client? _extendClient;

  List<Event2>? _events;
  String? _eventsErrorText;
  int? _totalEventsCount;
  bool? _lastPageLoadedAll;
  static const int _eventsPageLength = 16;

  String? _searchText;

  late Event2TimeFilter _timeFilter;
  TZDateTime? _customStartTime;
  TZDateTime? _customEndTime;
  late LinkedHashSet<Event2TypeFilter> _types;
  late Map<String, dynamic> _attributes;
  
  late Event2SortType _sortType;
  double? _sortDropdownWidth;

  LocationServicesStatus? _locationServicesStatus;
  bool _loadingLocationServicesStatus = false;
  Position? _userLocation;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Storage.notifySettingChanged,
      AppLivecycle.notifyStateChanged,
      Auth2.notifyLoginChanged,
      FlexUI.notifyChanged,
      Event2FilterParam.notifyChanged,
      Events2.notifyChanged,
      Events2.notifyUpdated,
    ]);

    _scrollController.addListener(_scrollListener);
    _searchTextController.text = widget.searchText ?? '';

    _timeFilter = event2TimeFilterFromString(Storage().events2Time) ?? Event2TimeFilter.upcoming;
    _customStartTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomStartTime));
    _customEndTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomEndTime));

    _types = LinkedHashSetUtils.from<Event2TypeFilter>(event2TypeFilterListFromStringList(Storage().events2Types)) ?? LinkedHashSet<Event2TypeFilter>();
    _attributes = Storage().events2Attributes ?? <String, dynamic>{};
    _sortType = event2SortTypeFromString(Storage().events2SortType) ?? Event2SortType.dateTime;

    _locationServicesStatus = widget.locationServicesStatus;
    _userLocation = widget.userLocation;

    _ensureLocationServicesStatus().then((_) {
      _updateOnLocationServicesStatus();
      _ensureUserLocation().then((_) {
        if (widget.searchText?.isNotEmpty == true) {
          _search(widget.searchText!);
        }
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _searchTextController.dispose();
    _searchTextNode.dispose();
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == Auth2.notifyLoginChanged) {
      _refresh();
    }
    else if (name == FlexUI.notifyChanged) {
      _userLocation = null;
      _updateLocationServicesStatus().then((_) {
        _ensureUserLocation();
      });
    }
    else if (name == Event2FilterParam.notifyChanged) {
      _updateFilers();
    }
    else if (name == Events2.notifyChanged) {
      _reload();
    }
    else if (name == Events2.notifyUpdated) {
      _updateEventIfNeeded(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _userLocation = null;
    }
    else if (state == AppLifecycleState.resumed) {
      _updateLocationServicesStatus().then((_) {
        _ensureUserLocation();
      });
    }
  }

  // Widget

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: () => AppPopScope.back(_onHeaderBarBack), child: Platform.isIOS ?
      BackGestureDetector(onBack: _onHeaderBarBack, child:
        _buildScaffoldContent(),
      ) :
      _buildScaffoldContent()
    );
  }

  Widget _buildScaffoldContent() {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.event2.search.header.title", "Search"),
        onLeading: _onHeaderBarBack,
      ),
      body: _buildPanelContent(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildPanelContent() {
    return RefreshIndicator(onRefresh: _onRefresh, child:
      SingleChildScrollView(scrollDirection: Axis.vertical, controller: _scrollController, child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Container(color: Styles().colors?.white, child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              _buildSearchBar(),
              _buildCommandBar(),
            ]),
          ),
          _buildResultContent()
        ],),
      ),
    );
  }

  Widget _buildSearchBar() => Container(decoration: _searchBarDecoration, padding: EdgeInsets.only(left: 16), child:
    Row(children: <Widget>[
      Expanded(child:
        _buildSearchTextField()
      ),
      _buildSearchImageButton('close',
        label: Localization().getStringEx('panel.search.button.clear.title', 'Clear'),
        hint: Localization().getStringEx('panel.search.button.clear.hint', ''),
        onTap: _onTapClear,
      ),
      _buildSearchImageButton('search',
        label: Localization().getStringEx('panel.search.button.search.title', 'Search'),
        hint: Localization().getStringEx('panel.search.button.search.hint', ''),
        onTap: _onTapSearch,
      ),
    ],),
  );

  Decoration get _searchBarDecoration => BoxDecoration(
    color: Styles().colors?.white,
    border: Border(bottom: BorderSide(color: Styles().colors?.disabledTextColor ?? Color(0xFF717273), width: 1))
  );

  Widget _buildSearchTextField() => Semantics(
    label: Localization().getStringEx('panel.search.field.search.title', 'Search'),
    hint: Localization().getStringEx('panel.search.field.search.hint', ''),
    textField: true,
    excludeSemantics: true,
    child: TextField(
      controller: _searchTextController,
      focusNode: _searchTextNode,
      onChanged: (text) => _onTextChanged(text),
      onSubmitted: (_) => _onTapSearch(),
      autofocus: true,
      cursorColor: Styles().colors!.fillColorSecondary,
      keyboardType: TextInputType.text,
      style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"),
      decoration: InputDecoration(
        border: InputBorder.none,
      ),
    ),
  );
  
  Widget _buildSearchImageButton(String image, {String? label, String? hint, void Function()? onTap}) =>
    Semantics(label: label, hint: hint, button: true, excludeSemantics: true, child:
      InkWell(onTap: onTap, child:
        Padding(padding: EdgeInsets.all(12), child:
          Styles().images?.getImage(image, excludeFromSemantics: true),
        ),
      ),
    );

  Widget _buildCommandBar() {
    return StringUtils.isNotEmpty(_searchText) ?  Padding(padding: EdgeInsets.only(top: 8), child:
      Column(children: [
        _buildCommandButtons(),
        _buildContentDescription(),
      ],)
    ) : Container();
  }

  Widget _buildCommandButtons() {
    return Row(children: [
      Padding(padding: EdgeInsets.only(left: 16)),
      Expanded(flex: 6, child: Wrap(spacing: 8, runSpacing: 8, children: [ //Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Event2FilterCommandButton(
          title: Localization().getStringEx('panel.events2.home.bar.button.filter.title', 'Filter'),
          leftIconKey: 'filters',
          rightIconKey: 'chevron-right',
          onTap: _onFilters,
        ),
        _sortButton,
      ])),
      Expanded(flex: 4, child: Wrap(alignment: WrapAlignment.end, verticalDirection: VerticalDirection.up, children: [
        LinkButton(
          title: Localization().getStringEx('panel.events2.home.bar.button.map.title', 'Map'), 
          hint: Localization().getStringEx('panel.events2.home.bar.button.map.hint', 'Tap to view map'),
          textStyle: Styles().textStyles?.getTextStyle('widget.button.title.regular.underline'),
          padding: EdgeInsets.only(left: 0, right: 8, top: 12, bottom: 12),
          onTap: _onMapView,
        ),
        Visibility(visible: Auth2().account?.isCalendarAdmin ?? false, child:
          Event2ImageCommandButton('plus-circle',
            label: Localization().getStringEx('panel.events2.home.bar.button.create.title', 'Create'),
            hint: Localization().getStringEx('panel.events2.home.bar.button.create.hint', 'Tap to create event'),
            contentPadding: EdgeInsets.only(left: 8, right: 16, top: 12, bottom: 12),
            onTap: _onCreate
          ),
        ),
      ])),
    ],);
  }


  Widget get _sortButton {
    _sortDropdownWidth ??= _evaluateSortDropdownWidth();
    return DropdownButtonHideUnderline(child:
      DropdownButton2<Event2SortType>(
        dropdownStyleData: DropdownStyleData(width: _sortDropdownWidth),
        customButton: Event2FilterCommandButton(
          title: Localization().getStringEx('panel.events2.home.bar.button.sort.title', 'Sort'),
          leftIconKey: 'sort'
        ),
        isExpanded: false,
        items: _buildSortDropdownItems(),
        onChanged: _onSortType,
      ),
    );
  }

  List<DropdownMenuItem<Event2SortType>> _buildSortDropdownItems() {
    List<DropdownMenuItem<Event2SortType>> items = <DropdownMenuItem<Event2SortType>>[];
    bool locationAvailable = ((_locationServicesStatus == LocationServicesStatus.permissionAllowed) || (_locationServicesStatus == LocationServicesStatus.permissionNotDetermined));
    for (Event2SortType sortType in Event2SortType.values) {
      if ((sortType != Event2SortType.proximity) || locationAvailable) {
        String? displaySortType = _sortDropdownItemTitle(sortType);
        items.add(DropdownMenuItem<Event2SortType>(
          value: sortType,
          child: Semantics(label: displaySortType, container: true, button: true,
            child: Text(displaySortType, overflow: TextOverflow.ellipsis, style: (_sortType == sortType) ?
              Styles().textStyles?.getTextStyle("widget.message.regular.fat") :
              Styles().textStyles?.getTextStyle("widget.message.regular"),
              semanticsLabel: "",
        ))));
      }
    }
    return items;
  }

  double _evaluateSortDropdownWidth() {
    double width = 0;
    for (Event2SortType sortType in Event2SortType.values) {
      final Size sizeFull = (TextPainter(
          text: TextSpan(
            text: _sortDropdownItemTitle(sortType),
            style: Styles().textStyles?.getTextStyle("widget.message.regular.fat"),
          ),
          textScaleFactor: MediaQuery.of(context).textScaleFactor,
          textDirection: TextDirection.ltr,
        )..layout()).size;
      if (width < sizeFull.width) {
        width = sizeFull.width;
      }
    }
    return min(width + 2 * 16, MediaQuery.of(context).size.width / 2); // add horizontal padding
  }

  String _sortDropdownItemTitle(Event2SortType sortType, { Event2SortOrder? sortOrder}) {
    String? displaySortType = event2SortTypeToDisplayString(sortType);
    if ((displaySortType != null) && (sortOrder != null)) {
      String? displaySortOrderIndicator = event2SortOrderIndicatorDisplayString(sortOrder);
      if (displaySortOrderIndicator != null) {
        displaySortType = "$displaySortType $displaySortOrderIndicator";
      }
    }
    return displaySortType ?? '';
  }

  Widget _buildContentDescription() {
    List<InlineSpan> descriptionList = <InlineSpan>[];
    TextStyle? boldStyle = Styles().textStyles?.getTextStyle("widget.card.title.tiny.fat");
    TextStyle? regularStyle = Styles().textStyles?.getTextStyle("widget.card.detail.small.regular");
    
    descriptionList.add(TextSpan(text: Localization().getStringEx('panel.event2.search.search.label.title', 'Search: ') , style: boldStyle,));
    descriptionList.add(TextSpan(text: _searchText ?? '' , style: regularStyle,));
    descriptionList.add(TextSpan(text: '; ', style: regularStyle,),);
    
    descriptionList.addAll(_buildFiltersDescription(boldStyle: boldStyle, regularStyle: regularStyle));
    
    descriptionList.addAll(_buildSortDescription(boldStyle: boldStyle, regularStyle: regularStyle));
    
    descriptionList.add(TextSpan(text: Localization().getStringEx('panel.event2.search.events.label.title', 'Events: ') , style: boldStyle,));
    descriptionList.add(TextSpan(text: _searching ? '...' : (_totalEventsCount?.toString() ?? '-') , style: regularStyle,));
    descriptionList.add(TextSpan(text: '.', style: regularStyle,),);
    
    return Padding(padding: EdgeInsets.only(top: 12), child:
      Container(decoration: _contentDescriptionDecoration, padding: EdgeInsets.only(top: 12, bottom: 12, left: 16, right: 16), child:
        Row(children: [ Expanded(child:
          RichText(text: TextSpan(style: regularStyle, children: descriptionList))
        ),],)
    ));
  }

  Decoration get _contentDescriptionDecoration => BoxDecoration(
    color: Styles().colors?.white,
    border: Border(
      top: BorderSide(color: Styles().colors?.disabledTextColor ?? Color(0xFF717273), width: 1),
      bottom: BorderSide(color: Styles().colors?.disabledTextColor ?? Color(0xFF717273), width: 1),
    )
  );

  List<InlineSpan> _buildFiltersDescription({TextStyle? boldStyle, TextStyle? regularStyle}) {
    List<InlineSpan> descriptionList = <InlineSpan>[];

    String? timeDescription = (_timeFilter != Event2TimeFilter.customRange) ?
      event2TimeFilterToDisplayString(_timeFilter) :
      event2TimeFilterDisplayInfo(Event2TimeFilter.customRange, customStartTime: _customStartTime, customEndTime: _customEndTime);
    
    if (timeDescription != null) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: ", " , style: regularStyle,));
      }
      descriptionList.add(TextSpan(text: timeDescription, style: regularStyle,),);
    }

    for (Event2TypeFilter type in _types) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: ", " , style: regularStyle,));
      }
      descriptionList.add(TextSpan(text: event2TypeFilterToDisplayString(type), style: regularStyle,),);
    }

    ContentAttributes? contentAttributes = Events2().contentAttributes;
    List<ContentAttribute>? attributes = contentAttributes?.attributes;
    if (_attributes.isNotEmpty && (contentAttributes != null) && (attributes != null)) {
      for (ContentAttribute attribute in attributes) {
        List<String>? displayAttributeValues = attribute.displaySelectedLabelsFromSelection(_attributes, complete: true);
        if ((displayAttributeValues != null) && displayAttributeValues.isNotEmpty) {
          for (String attributeValue in displayAttributeValues) {
            if (descriptionList.isNotEmpty) {
              descriptionList.add(TextSpan(text: ", " , style: regularStyle,));
            }
            descriptionList.add(TextSpan(text: attributeValue, style: regularStyle,),);
          }
        }
      }
    }

    if (descriptionList.isNotEmpty) {
      descriptionList.insert(0, TextSpan(text: Localization().getStringEx('panel.events2.home.attributes.filter.label.title', 'Filter: ') , style: boldStyle,));
      descriptionList.add(TextSpan(text: '; ', style: regularStyle,),);
    }
    
    return descriptionList;
  }

  List<InlineSpan> _buildSortDescription({TextStyle? boldStyle, TextStyle? regularStyle}) {
    List<InlineSpan> descriptionList = <InlineSpan>[];
    if ((1 < (_events?.length ?? 0)) || _searching) {
      String? sortStatus = event2SortTypeDisplayStatusString(_sortType);
      if (sortStatus != null) {
        descriptionList.add(TextSpan(text: Localization().getStringEx('panel.events2.home.attributes.sort.label.title', 'Sort: ') , style: boldStyle,));
        descriptionList.add(TextSpan(text: sortStatus, style: regularStyle,),);
        descriptionList.add(TextSpan(text: '; ', style: regularStyle,),);
      }
    }

    return descriptionList;
  }

  Widget _buildResultContent() {
    if (_searching) {
      return _buildLoadingContent(); 
    }
    else if (StringUtils.isEmpty(_searchText)) {
      return Container();
    }
    else if (_loadingLocationServicesStatus) {
      return _buildLoadingContent(); 
    }
    else if (_events == null) {
      return _buildMessageContent(_eventsErrorText ?? Localization().getStringEx('logic.general.unknown_error', 'Unknown Error Occurred'),
        title: Localization().getStringEx('panel.events2.home.message.failed.title', 'Failed')
      );
    }
    else if (_events?.length == 0) {
      return _buildMessageContent(Localization().getStringEx('panel.event2.search.empty.message', 'There are no events matching the search text.'));
    }
    else {
      return _buildListContent();
    }
  }

  Widget _buildListContent() {
    List<Widget> cardsList = <Widget>[];
    for (Event2 event in _events!) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: 8), child:
        Event2Card(event, userLocation: _userLocation, onTap: () => _onTapEvent(event),),
      ),);
    }
    if (_extendClient != null) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 8 : 0), child:
        _extendIndicator
      ));
    }
    return Padding(padding: EdgeInsets.all(16), child:
      Column(children:  cardsList,)
    );
  }

  Widget get _extendIndicator => Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32), child:
    Align(alignment: Alignment.center, child:
      SizedBox(width: 24, height: 24, child:
        CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary),),),),);

  Widget _buildLoadingContent() => Padding(padding: EdgeInsets.only(left: 32, right: 32, top: _screenHeight / 4, bottom: 3 * _screenHeight / 4), child:
    Center(child:
      CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 3,),
    ),
  );

  Widget _buildMessageContent(String message, { String? title }) =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: _screenHeight / 6), child:
      Column(children: [
        (title != null) ? Padding(padding: EdgeInsets.only(bottom: 12), child:
          Text(title, textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle('widget.item.medium.fat'),)
        ) : Container(),
        Text(message, textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle((title != null) ? 'widget.item.regular.thin' : 'widget.item.medium.fat'),),
      ],),
    );

  double get _screenHeight => MediaQuery.of(context).size.height;

  void _onTapEvent(Event2 event) {
    Analytics().logSelect(target: 'Event: ${event.name}');
    if (event.hasGame) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(game: event.game)));
    } else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2DetailPanel(event: event, userLocation: _userLocation, eventSelector: widget.eventSelector,)));
    }
  }

  void _onTextChanged(String text) {
    if ((text.trim() != _searchText) && mounted) {
      setState(() {
        _searchText = null;
        _totalEventsCount = null;
        _lastPageLoadedAll = null;
        _events = null;
        _eventsErrorText = null;
      });
    }
  }

  void _onTapClear() {
    Analytics().logSelect(target: "Clear");
    if (StringUtils.isEmpty(_searchTextController.text.trim())) {
      Navigator.of(context).pop("");
    }
    else if (mounted) {
      _searchTextController.text = '';
      _searchTextNode.requestFocus();
      setState(() {
        _searchText = null;
        _totalEventsCount = null;
        _lastPageLoadedAll = null;
        _events = null;
        _eventsErrorText = null;
      });
    }
  }

  void _onTapSearch() {
    Analytics().logSelect(target: "Search");

    String searchText = _searchTextController.text.trim();
    if (searchText.isNotEmpty) {
      FocusScope.of(context).requestFocus(FocusNode());
      _search(searchText);
    }
  }

  void _onCreate() {
    Analytics().logSelect(target: 'Create');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2CreatePanel()));
  }

  void _onMapView() {
    Analytics().logSelect(target: 'Map View');
    if (widget.searchContext == Event2SearchContext.Map) {
      Navigator.of(context).pop((0 < (_totalEventsCount ?? 0)) ? _searchText : null);
    }
    else {
      NotificationService().notify(ExploreMapPanel.notifySelect, ExploreMapSearchEventsParam(_searchText ?? ''));
    }
  }

  void _onHeaderBarBack() {
    Analytics().logSelect(target: 'HeaderBar: Back');
    Navigator.of(context).pop((0 < (_totalEventsCount ?? 0)) ? _searchText : null);
  }

  Future<void> _onRefresh() {
    Analytics().logSelect(target: 'Refresh');
    return _refresh();
  }

  void _onFilters() {
    Analytics().logSelect(target: 'Filters');

    Event2HomePanel.presentFiltersV2(context, Event2FilterParam(
      timeFilter: _timeFilter,
      customStartTime: _customStartTime,
      customEndTime: _customEndTime,
      types: _types,
      attributes: _attributes
    )).then((Event2FilterParam? filterResult) {
      if ((filterResult != null) && mounted) {
        setState(() {
          _timeFilter = filterResult.timeFilter ?? Event2TimeFilter.upcoming;
          _customStartTime = filterResult.customStartTime;
          _customEndTime = filterResult.customEndTime;
          _types = filterResult.types ?? LinkedHashSet<Event2TypeFilter>();
          _attributes = filterResult.attributes ?? <String, dynamic>{};
        });
        
        Storage().events2Time = event2TimeFilterToString(_timeFilter);
        Storage().events2CustomStartTime = JsonUtils.encode(_customStartTime?.toJson());
        Storage().events2CustomEndTime = JsonUtils.encode(_customEndTime?.toJson());
        Storage().events2Types = event2TypeFilterListToStringList(_types.toList());
        Storage().events2Attributes = _attributes;

        Event2FilterParam.notifySubscribersChanged(except: this);

        _reload();
      }
    });
  }

  void _updateFilers() {
    Event2TimeFilter? timeFilter = event2TimeFilterFromString(Storage().events2Time);
    TZDateTime? customStartTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomStartTime));
    TZDateTime? customEndTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomEndTime));
    LinkedHashSet<Event2TypeFilter>? types = LinkedHashSetUtils.from<Event2TypeFilter>(event2TypeFilterListFromStringList(Storage().events2Types));
    Map<String, dynamic>? attributes = Storage().events2Attributes;

    setStateIfMounted(() {
      if (timeFilter != null) {
        _timeFilter = timeFilter;
        _customStartTime = customStartTime;
        _customEndTime = customEndTime;
      }
      if (types != null) {
        _types = types;
      }
      if (attributes != null) {
        _attributes = attributes;
      }
    });
    
    _reload();
  }

  void _onSortType(Event2SortType? value) {
    Analytics().logSelect(target: 'Sort');
    if (value != null) {
      if (_sortType != value) {
        setState(() {
          _sortType = value;
        });
        Storage().events2SortType = event2SortTypeToString(_sortType);
        _reload();
      }
    }
  }

  bool? get _hasMoreEvents => (_totalEventsCount != null) ?
    ((_events?.length ?? 0) < _totalEventsCount!) : _lastPageLoadedAll;

  void _scrollListener() {
    if ((_scrollController.offset >= _scrollController.position.maxScrollExtent) && (_hasMoreEvents != false) && !_searching && !_extending) {
      _extend();
    }
  }

  bool get _searching => (_searchClient !=  null);
  bool get _extending => (_extendClient != null);

  // Event2 Query

  bool get _queryNeedsLocation => (_types.contains(Event2TypeFilter.nearby) || (_sortType == Event2SortType.proximity));

  Future<Events2Query> _queryParam(String searchText, { int offset = 0, int limit = _eventsPageLength}) async {
    if (_queryNeedsLocation) {
      await _ensureUserLocation(prompt: true);
    }
    return Events2Query(
      searchText: searchText,
      timeFilter: _timeFilter,
      customStartTimeUtc: _customStartTime?.toUtc(),
      customEndTimeUtc: _customEndTime?.toUtc(),
      types: _types,
      attributes: _attributes,
      sortType: _sortType,
      sortOrder: Event2SortOrder.ascending,
      location: _userLocation,
      offset: offset,
      limit: limit,
    );
  } 

  Future<void> _search(String searchText, { int limit = _eventsPageLength }) async {
    if (searchText.isNotEmpty) {
      Client client = Client();

      _searchClient?.close();
      _refreshClient?.close();
      _extendClient?.close();

      setState(() {
        _searchText = searchText;
        _searchClient = client;
        _refreshClient = _extendClient = null;
      });

      dynamic result = await Events2().loadEventsEx(await _queryParam(searchText,
        offset: 0,
        limit: limit,
      ), client: _searchClient);
      Events2ListResult? listResult = (result is Events2ListResult) ? result : null;
      List<Event2>? events = listResult?.events;
      int? totalEventsCount = listResult?.totalCount;
      String? errorTextResult = (result is String) ? result : null;

      if (identical(_searchClient, client)) {
        setStateIfMounted(() {
          _events = (events != null) ? List<Event2>.from(events) : null;
          _totalEventsCount = totalEventsCount;
          _lastPageLoadedAll = (events != null) ? (events.length >= limit) : null;
          _eventsErrorText = errorTextResult;
          _searchClient = null;
        });
      }
    }
  }

  Future<void> _reload() async => (_searchText?.isNotEmpty == true) ? await _search(_searchText!) : Future.value();

  Future<void> _refresh() async {
    if (_searchText?.isNotEmpty == true) {
      Client client = Client();
      
      _searchClient?.close();
      _refreshClient?.close();
      _extendClient?.close();
      
      setState(() {
        _refreshClient = client;
        _searchClient = _extendClient = null;
      });

      int limit = max(_events?.length ?? 0, _eventsPageLength);
      dynamic result = await Events2().loadEventsEx(await _queryParam(_searchText!,
        offset: 0,
        limit: limit,
      ), client: _refreshClient);
      Events2ListResult? listResult = (result is Events2ListResult) ? result : null;
      List<Event2>? events = listResult?.events;
      int? totalEventsCount = listResult?.totalCount;
      String? errorTextResult = (result is String) ? result : null;

      if (mounted && identical(_refreshClient, client)) {
        setState(() {
          if (events != null) {
            _events = List<Event2>.from(events);
            _lastPageLoadedAll = (events.length >= limit);
            _eventsErrorText = null;
          }
          else if (_events == null) {
            // If there was events content, preserve it. Otherwise, show the error
            _eventsErrorText = errorTextResult;
          }
          if (totalEventsCount != null) {
            _totalEventsCount = totalEventsCount;
          }
          _refreshClient = null;
        });
      }
    }
  }

  Future<void> _extend() async {
    if (_searchText?.isNotEmpty == true) {
      Client client = Client();
      
      _searchClient?.close();
      _refreshClient?.close();
      _extendClient?.close();
      
      setState(() {
        _extendClient = client;
        _searchClient = _refreshClient = null;
      });

      Events2ListResult? listResult = await Events2().loadEvents(await _queryParam(_searchText!,
        offset: _events?.length ?? 0,
        limit: _eventsPageLength,
      ), client: _extendClient);
      List<Event2>? events = listResult?.events;
      int? totalEventsCount = listResult?.totalCount;

      if (mounted && identical(_extendClient, client)) {
        setState(() {
          if (events != null) {
            if (_events != null) {
              _events?.addAll(events);
            }
            else {
              _events = List<Event2>.from(events);
            }
            _lastPageLoadedAll = (events.length >= _eventsPageLength);
          }
          if (totalEventsCount != null) {
            _totalEventsCount = totalEventsCount;
          }
          _extendClient = null;
        });
      }
    }
  }

  void _updateEventIfNeeded(Event2? event) {
    if ((event != null) && (event.id != null) && mounted) {
      int? index = Event2.indexInList(_events, id: event.id);
      if (index != null)
      setState(() {
       _events?[index] = event;
      });
    }
  }
  // Location Status and Position

  Future<void> _ensureLocationServicesStatus({ bool force = false}) async {
    if ((_locationServicesStatus == null) || force) {
      setStateIfMounted(() {
        _loadingLocationServicesStatus = true;
      });
      LocationServicesStatus? locationServicesStatus = await Event2HomePanel.getLocationServicesStatus();
      if (locationServicesStatus != null) {
        setStateIfMounted(() {
          _locationServicesStatus = locationServicesStatus;
          _loadingLocationServicesStatus = false;
          _updateOnLocationServicesStatus();
        });
      }
    }
  }

  Future<void> _updateLocationServicesStatus() async {
    LocationServicesStatus? locationServicesStatus = await Event2HomePanel.getLocationServicesStatus();
    if (_locationServicesStatus != locationServicesStatus) {
      bool needsReload = false;
      setStateIfMounted(() {
        _locationServicesStatus = locationServicesStatus;
        needsReload = _updateOnLocationServicesStatus();
      });
      if (needsReload) {
        _reload();
      }
    }
  }

  bool _updateOnLocationServicesStatus() {
    bool result = false;
    bool locationNotAvailable = ((_locationServicesStatus == LocationServicesStatus.serviceDisabled) || ((_locationServicesStatus == LocationServicesStatus.permissionDenied)));
    if (_types.contains(Event2TypeFilter.nearby) && locationNotAvailable) {
      _types.remove(Event2TypeFilter.nearby);
      result = true;
    }
    if ((_sortType == Event2SortType.proximity) && locationNotAvailable) {
      _sortType = Event2SortType.dateTime;
      result = true;
    }
    return result;
  }

  Future<Position?> _ensureUserLocation({ bool prompt = false}) async {
    if (_userLocation == null) {
      if (prompt && (_locationServicesStatus == LocationServicesStatus.permissionNotDetermined)) {
        _locationServicesStatus = await LocationServices().requestPermission();
        _updateOnLocationServicesStatus();
      }
      if (_locationServicesStatus == LocationServicesStatus.permissionAllowed) {
        _userLocation = await LocationServices().location;
      }
    }
    return _userLocation;
  } 


}

enum Event2SearchContext { List, Map }