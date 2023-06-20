
import 'dart:collection';
import 'dart:math';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/attributes/ContentAttributesPanel.dart';
import 'package:illinois/ui/events2/Event2DetailPanel.dart';
import 'package:illinois/ui/events2/Event2TimeRangePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/storage.dart' as rokwire;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';

class Event2HomePanel extends StatefulWidget {
  static final String routeName = 'Event2HomePanel';

  final EventTimeFilter? timeFilter;
  final TZDateTime? customStartTime;
  final TZDateTime? customEndTime;

  final LinkedHashSet<EventTypeFilter>? types;
  final Map<String, dynamic>? attributes;

  Event2HomePanel({Key? key,
    this.timeFilter, this.customStartTime, this.customEndTime,
    this.types, this.attributes
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Event2HomePanelState();

  static void present(BuildContext context) {
    if (Storage().events2Attributes != null) {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: Event2HomePanel.routeName), builder: (context) => Event2HomePanel()));
    }
    else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ContentAttributesPanel(
        title: Localization().getStringEx('panel.events2.home.attributes.launch.header.title', 'Events'),
        description: Localization().getStringEx('panel.events2.home.attributes.launch.header.description', 'Discover events across campus and around the world'),
        applyTitle: Localization().getStringEx('panel.events2.home.attributes.launch.apply.title', 'Explore'),
        continueTitle:Localization().getStringEx('panel.events2.home.attributes.launch.continue.title', 'Not right now'),
        contentAttributes: contentAttributesExt,
        sortType: ContentAttributesSortType.native,
        filtersMode: true,
      ))).then((result) {
        Map<String, dynamic>? selection = JsonUtils.mapValue(result);
        if (selection != null) {
          
          List<EventTypeFilter>? typesList = eventTypeFilterListFromSelection(selection[eventTypeContentAttributeId]);
          Storage().events2Types = eventTypeFilterListToStringList(typesList) ;

          Map<String, dynamic> attributes = Map<String, dynamic>.from(selection);
          attributes.remove(eventTypeContentAttributeId);
          Storage().events2Attributes = attributes;

          Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: Event2HomePanel.routeName), builder: (context) => Event2HomePanel(
            types: (typesList != null) ? LinkedHashSet<EventTypeFilter>.from(typesList) : null,
            attributes: attributes,
          )));
        }
      });
    }
  }

  static ContentAttributes? get contentAttributesExt {
    ContentAttributes? contentAttributes = ContentAttributes.fromOther(Events2().contentAttributes);
    contentAttributes?.attributes?.insert(0, eventTypeContentAttribute);
    return contentAttributes;
  }

  static const String internalContentAttributesScope = 'internal';
  static const String eventTypeContentAttributeId = 'event-type';
  static const String eventTimeContentAttributeId = 'event-time';
  
  static ContentAttribute get eventTypeContentAttribute {
    List<ContentAttributeValue> values = <ContentAttributeValue>[];
    for (EventTypeFilter value in EventTypeFilter.values) {
      values.add(ContentAttributeValue(
        label: eventTypeFilterToDisplayString(value),
        value: value,
        group: eventTypeFilterGroups[value],
      ));
    }

    return ContentAttribute(
      id: eventTypeContentAttributeId,
      title: Localization().getStringEx('panel.events2.home.attributes.event_type.title', 'Event Type'),
      emptyHint: Localization().getStringEx('panel.events2.home.attributes.event_type.hint.empty', 'Select an event type...'),
      semanticsHint: Localization().getStringEx('panel.events2.home.attributes.event_type.hint.semantics', 'Double type to show event options.'),
      widget: ContentAttributeWidget.dropdown,
      scope: <String>{ internalContentAttributesScope },
      requirements: ContentAttributeRequirements(maxSelectedCount: 1, scope: contentAttributeRequirementsScopeFilter),
      values: values
    );
  }

  static ContentAttribute eventTimeContentAttribute({ TZDateTime? customStartTime, TZDateTime? customEndTime }) {
    List<ContentAttributeValue> values = <ContentAttributeValue>[];
    for (EventTimeFilter value in EventTimeFilter.values) {
      values.add((value != EventTimeFilter.customRange) ? ContentAttributeValue(
        label: eventTimeFilterToDisplayString(value),
        info: eventTimeFilterDisplayInfo(value),
        value: value,
      ) : _CustomRangeEventTimeAttributeValue(
        label: eventTimeFilterToDisplayString(value),
        info: eventTimeFilterDisplayInfo(value, customStartTime: customStartTime, customEndTime: customEndTime),
        value: value,
        customData: Event2TimeRangePanel.buldCustomData(customStartTime, customEndTime),
      ));
    }

    return ContentAttribute(
      id: eventTimeContentAttributeId,
      title: Localization().getStringEx('panel.events2.home.attributes.event_time.title', 'Date & Time'),
      emptyHint: Localization().getStringEx('panel.events2.home.attributes.event_time.hint.empty', 'Select an date & time...'),
      semanticsHint: Localization().getStringEx('panel.events2.home.attributes.event_time.hint.semantics', 'Double type to show date & time options.'),
      widget: ContentAttributeWidget.dropdown,
      scope: <String>{ internalContentAttributesScope },
      requirements: ContentAttributeRequirements(minSelectedCount: 1, maxSelectedCount: 1, scope: contentAttributeRequirementsScopeFilter),
      values: values,
    );
  }

  Future<bool?> handleAttributeValue({required BuildContext context, required ContentAttribute attribute, required ContentAttributeValue value}) async {
    return ((attribute.id == eventTimeContentAttributeId) && (value.value == EventTimeFilter.customRange)) ?
      handleCustomRangeTimeAttribute(context: context, attribute: attribute, value: value) : null;
  }

  Future<bool> handleCustomRangeTimeAttribute({required BuildContext context, required ContentAttribute attribute, required ContentAttributeValue value}) async {
    dynamic result = await Navigator.of(context).push(CupertinoPageRoute(builder: (context) => Event2TimeRangePanel(customData: value.customData,)));
    Map<String, dynamic>? customData = JsonUtils.mapValue(result);
    if (customData != null) {
      value.customData = customData;
      value.info = eventTimeFilterDisplayInfo(EventTimeFilter.customRange, customStartTime: Event2TimeRangePanel.getStartTime(customData), customEndTime: Event2TimeRangePanel.getEndTime(customData));
      return true;
    }
    else {
      return false;
    }
  }


}

class _Event2HomePanelState extends State<Event2HomePanel> implements NotificationsListener {

  bool _loadingEvents = false;
  List<Event2>? _events;
  static const int eventsPageLength = 12;

  late EventTimeFilter _timeFilter;
  TZDateTime? _customStartTime;
  TZDateTime? _customEndTime;
  late LinkedHashSet<EventTypeFilter> _types;
  late Map<String, dynamic> _attributes;
  
  late EventSortType _sortType;
  double? _sortDropdownWidth;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Storage.notifySettingChanged
    ]);

    _timeFilter = widget.timeFilter ?? eventTimeFilterFromString(Storage().events2Time) ?? EventTimeFilter.upcoming;

    if ((_timeFilter == EventTimeFilter.customRange) && (widget.customStartTime != null) && (widget.customEndTime != null)) {
      _customStartTime = widget.customStartTime;
      _customEndTime = widget.customEndTime;
    }
    else {
      _timeFilter = EventTimeFilter.upcoming;
    }

    _types = widget.types ?? LinkedHashSetUtils.from<EventTypeFilter>(eventTypeFilterListFromStringList(Storage().events2Types)) ?? LinkedHashSet<EventTypeFilter>();
    _attributes = widget.attributes ?? Storage().events2Attributes ?? <String, dynamic>{};
    _sortType = eventSortTypeFromString(Storage().events2Sort) ?? EventSortType.dateTime;

    _loadingEvents = true;
    Events2().loadEvents(queryParam).then((List<Event2>? events) {
      setStateIfMounted(() {
        _events = (events != null) ? List<Event2>.from(events) : null;
        _loadingEvents = false;
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
  void onNotification(String name, param) {
    if (name == Storage.notifySettingChanged) {
      if (param == rokwire.Storage.debugUseSampleEvents2Key) {
        _onRefresh();
      }
    }
  }

  // Event2 Query

  Events2Query get queryParam => queryParamEx();

  Events2Query queryParamEx({int offset = 0, int limit = eventsPageLength}) => Events2Query(
    offset: offset,
    limit: limit,
    timeFilter: _timeFilter,
    customStartTimeUtc: _customStartTime?.toUtc(),
    customEndTimeUtc: _customEndTime?.toUtc(),
    types: _types,
    attributes: _attributes,
    sortType: _sortType
  );

  // Widget

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx("panel.events2.home.header.title", "Events"), leading: RootHeaderBarLeading.Back,),
      body: _buildPanelContent(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildPanelContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildCommandBar(),
      Expanded(child:
        RefreshIndicator(onRefresh: _onRefresh, child:
          SingleChildScrollView(child:
            _buildEventsContent(),
          )
        )
      )
    ],);
  }

  Widget _buildCommandBar() {
    return Container(decoration: _commandBarDecoration, child:
      Padding(padding: EdgeInsets.only(top: 8, bottom: 12), child:
        Column(children: [
          _buildCommandButtons(),
          _buildContentDescription(),
        ],)
      ),
    );
  }

  Decoration get _commandBarDecoration => BoxDecoration(
    color: Styles().colors?.white,
    border: Border.all(color: Styles().colors?.disabledTextColor ?? Color(0xFF717273), width: 1)
  );

  Widget _buildCommandButtons() {
    return Row(children: [
      Padding(padding: EdgeInsets.only(left: 16)),
      Expanded(flex: 6, child: Wrap(spacing: 8, runSpacing: 8, children: [ //Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Event2FilterCommandButton(
          title: 'Filters',
          leftIconKey: 'filters',
          rightIconKey: 'chevron-right',
          onTap: _onFilters,
        ),
        _sortButton,

      ])),
      Expanded(flex: 4, child: Wrap(alignment: WrapAlignment.end, verticalDirection: VerticalDirection.up, children: [
        LinkButton(
          title: 'Map View',
          hint: 'Tap to view map',
          onTap: _onMapView,
          padding: EdgeInsets.only(left: 0, right: 8, top: 16, bottom: 16),
          textStyle: Styles().textStyles?.getTextStyle('widget.button.title.regular.underline'),
        ),
        Event2ImageCommandButton('plus-circle',
          label: 'Create',
          hint: 'Tap to create event',
          contentPadding: EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 16),
          onTap: _onCreate
        ),
        Event2ImageCommandButton('search',
          label: 'Search',
          hint: 'Tap to search events',
          contentPadding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
          onTap: _onSearch
        ),
      ])),
    ],);
  }


  Widget get _sortButton {
    _sortDropdownWidth ??= _evaluateSortDropdownWidth();
    return DropdownButtonHideUnderline(child:
      DropdownButton2<String>(
        dropdownStyleData: DropdownStyleData(width: _sortDropdownWidth),
        customButton: Event2FilterCommandButton(title: 'Sort', leftIconKey: 'sort'),
        isExpanded: false,
        items: _buildSortDropdownItems(),
        onChanged: _onSortType,
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildSortDropdownItems() {
    List<DropdownMenuItem<String>> items = <DropdownMenuItem<String>>[];
    for (EventSortType sortType in EventSortType.values) {
      items.add(DropdownMenuItem<String>(
        value: eventSortTypeToString(sortType),
        child: Text(eventSortTypeToDisplayString(sortType) ?? '', overflow: TextOverflow.ellipsis, style: (_sortType == sortType) ?
          Styles().textStyles?.getTextStyle("widget.message.regular.fat") :
          Styles().textStyles?.getTextStyle("widget.message.regular"),
      )));
    }
    return items;
  }

  double _evaluateSortDropdownWidth() {
    double width = 0;
    for (EventSortType sortType in EventSortType.values) {
      final Size sizeFull = (TextPainter(
          text: TextSpan(
            text: eventSortTypeToDisplayString(sortType) ?? '',
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

  Widget _buildContentDescription() {
    List<InlineSpan> descriptionList = <InlineSpan>[];
    TextStyle? boldStyle = Styles().textStyles?.getTextStyle("widget.card.title.tiny.fat");
    TextStyle? regularStyle = Styles().textStyles?.getTextStyle("widget.card.detail.small.regular");

    String? timeDescription = (_timeFilter != EventTimeFilter.customRange) ?
      eventTimeFilterToDisplayString(_timeFilter) :
      eventTimeFilterDisplayInfo(EventTimeFilter.customRange, customStartTime: _customStartTime, customEndTime: _customEndTime);
    
    if (timeDescription != null) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: ", " , style: regularStyle,));
      }
      descriptionList.add(TextSpan(text: timeDescription, style: regularStyle,),);
    }

    for (EventTypeFilter type in _types) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: ", " , style: regularStyle,));
      }
      descriptionList.add(TextSpan(text: eventTypeFilterToDisplayString(type), style: regularStyle,),);
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
      descriptionList.insert(0, TextSpan(text: Localization().getStringEx('panel.events2.home.attributes.filters.label.title', 'Filter by: ') , style: boldStyle,));
      descriptionList.add(TextSpan(text: '.', style: regularStyle,),);
    }

    if (1 < (_events?.length ?? 0)) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: ' ', style: regularStyle,),);
      }
      descriptionList.add(TextSpan(text: Localization().getStringEx('panel.events2.home.attributes.sort.label.title', 'Sort ') , style: boldStyle,));
      descriptionList.add(TextSpan(text: eventSortTypeToDisplayStatusString(_sortType), style: regularStyle,),);
      descriptionList.add(TextSpan(text: '.', style: regularStyle,),);
    }

    if (descriptionList.isNotEmpty) {
      return Padding(padding: EdgeInsets.only(top: 12), child:
        Container(decoration: _attributesDescriptionDecoration, padding: EdgeInsets.only(top: 12, left: 16, right: 16), child:
          Row(children: [ Expanded(child:
            RichText(text: TextSpan(style: regularStyle, children: descriptionList))
          ),],)
      ));
    }
    else {
      return Container();
    }
  }

  Decoration get _attributesDescriptionDecoration => BoxDecoration(
    color: Styles().colors?.white,
    border: Border(top: BorderSide(color: Styles().colors?.disabledTextColor ?? Color(0xFF717273), width: 1))
  );

  Widget _buildEventsContent() {
    if (_loadingEvents) {
      return _buildLoadingContent();
    }
    else if (_events == null) {
      return _buildMessageContent('Failed to load events.');
    }
    else if (_events?.length == 0) {
      return _buildMessageContent(_attributes.isNotEmpty ? 'There are no events matching the selected filters.' : 'There are no events defined yet.');
    }
    else {
      return _buildEventsList();
    }
  }

  Widget _buildEventsList() {
    List<Widget> cardsList = <Widget>[];
    for (Event2 event in _events!) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 8 : 0), child:
        Event2Card(event, onTap: () => _onEvent(event),),
      ),);
    }
    return Padding(padding: EdgeInsets.all(16), child:
      Column(children:  cardsList,)
    );
  }

  Widget _buildMessageContent(String message) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Column(children: [
      Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: screenHeight / 4), child:
        Text(message, textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle('widget.item.medium.fat'),)
      ),
      Container(height: screenHeight / 2,)
    ],);
  }

  Widget _buildLoadingContent() {
    double screenHeight = MediaQuery.of(context).size.height;
    return Column(children: [
      Padding(padding: EdgeInsets.symmetric(vertical: screenHeight / 4), child:
        SizedBox(width: 32, height: 32, child:
          CircularProgressIndicator(color: Styles().colors?.fillColorSecondary,)
        )
      ),
      Container(height: screenHeight / 2,)
    ],);
  }

  Future<void> _onRefresh() async {
    if (_loadingEvents != true) {
      setState(() {
        _loadingEvents = true;
      });

      Events2().loadEvents(queryParamEx(limit: max(_events?.length ?? 0, eventsPageLength))).then((List<Event2>? events) {
        setStateIfMounted(() {
          _events = (events != null) ? List<Event2>.from(events) : null;
          _loadingEvents = false;
        });
      });
    }
  }

  void _onFilters() {
    Analytics().logSelect(target: 'Filters');
    //Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2FiltersPanel(_attributes)));
    Map<String, dynamic> selection = Map<String, dynamic>.from(_attributes);
    selection[Event2HomePanel.eventTypeContentAttributeId] = _types.toList();
    selection[Event2HomePanel.eventTimeContentAttributeId] = <dynamic>[_timeFilter];
    
    if (Events2().contentAttributes != null) {
      ContentAttributes? contentAttributes = contentAttributesExt;
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ContentAttributesPanel(
        title: Localization().getStringEx('panel.events2.home.attributes.filters.header.title', 'Event Filters'),
        description: Localization().getStringEx('panel.events2.home.attributes.filters.header.description', 'Choose one or more attributes to filter the events.'),
        contentAttributes: contentAttributes,
        selection: selection,
        sortType: ContentAttributesSortType.native,
        filtersMode: true,
        handleAttributeValue: widget.handleAttributeValue,
      ))).then((result) {
        Map<String, dynamic>? selection = JsonUtils.mapValue(result);
        if ((selection != null) && mounted) {

          TZDateTime? customStartTime, customEndTime;
          EventTimeFilter timeFilter = eventTimeFilterListFromSelection(selection[Event2HomePanel.eventTimeContentAttributeId]) ?? _timeFilter;
          Storage().events2Time = eventTimeFilterToString(timeFilter);
          if (timeFilter == EventTimeFilter.customRange) {
            Map<String, dynamic>? customData = contentAttributes?.findAttribute(id: Event2HomePanel.eventTimeContentAttributeId)?.findValue(value: EventTimeFilter.customRange)?.customData;
            customStartTime = Event2TimeRangePanel.getStartTime(customData);
            customEndTime = Event2TimeRangePanel.getEndTime(customData);
          }

          List<EventTypeFilter>? typesList = eventTypeFilterListFromSelection(selection[Event2HomePanel.eventTypeContentAttributeId]);
          Storage().events2Types = eventTypeFilterListToStringList(typesList);

          Map<String, dynamic> attributes = Map<String, dynamic>.from(selection);
          attributes.remove(Event2HomePanel.eventTimeContentAttributeId);
          attributes.remove(Event2HomePanel.eventTypeContentAttributeId);
          Storage().events2Attributes = attributes;

          setState(() {
            _timeFilter = timeFilter;
            _customStartTime = customStartTime;
            _customEndTime = customEndTime;
            _types = (typesList != null) ? LinkedHashSet<EventTypeFilter>.from(typesList) : LinkedHashSet<EventTypeFilter>();
            _attributes = selection;
            _loadingEvents = true;
          });

          Events2().loadEvents(queryParam).then((List<Event2>? events) {
            setStateIfMounted(() {
              _events = (events != null) ? List<Event2>.from(events) : null;
              _loadingEvents = false;
            });
          });
        }
      });
    }
  }

  ContentAttributes? get contentAttributesExt {
    ContentAttributes? contentAttributes = ContentAttributes.fromOther(Event2HomePanel.contentAttributesExt);
    contentAttributes?.attributes?.insert(0, Event2HomePanel.eventTimeContentAttribute(customStartTime: _customStartTime, customEndTime: _customEndTime));
    return contentAttributes;
  }

  void _onSortType(String? value) {
    Analytics().logSelect(target: 'Sort');
    EventSortType? sortType = eventSortTypeFromString(value);
    if (sortType != null) {
      setState(() {
        _sortType = sortType;
        _loadingEvents = true;
      });

      Storage().events2Sort = eventSortTypeToString(sortType);

      Events2().loadEvents(Events2Query(offset: 0, limit: max(_events?.length ?? 0, eventsPageLength), attributes: _attributes, sortType: _sortType)).then((List<Event2>? events) {
        setStateIfMounted(() {
          _events = (events != null) ? List<Event2>.from(events) : null;
          _loadingEvents = false;
        });
      });
    }
  }

  void _onSearch() {
    Analytics().logSelect(target: 'Search');
    AppAlert.showDialogResult(context, 'TBD');
  }

  void _onCreate() {
    Analytics().logSelect(target: 'Create');
    AppAlert.showDialogResult(context, 'TBD');
  }

  void _onMapView() {
    Analytics().logSelect(target: 'Map View');
    AppAlert.showDialogResult(context, 'TBD');
  }

  void _onEvent(Event2 event) {
    Analytics().logSelect(target: 'Event: ${event.name}');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2DetailPanel(event: event,)));
  }
}

class _CustomRangeEventTimeAttributeValue extends ContentAttributeValue {
  _CustomRangeEventTimeAttributeValue({String? label, dynamic value, String? group, Map<String, dynamic>? requirements, String? info, Map<String, dynamic>? customData }) :
    super (label: label, value: value, group: group, requirements: requirements, info: info, customData: customData);

  @override
  String? get selectedLabel {
    String title = Localization().getStringEx("model.event2.event_time.custom_range.selected", "Custom");
    return (StringUtils.isNotEmpty(info)) ? '$title $info' : title;
  }
}