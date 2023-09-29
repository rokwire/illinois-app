
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/attributes/ContentAttributesPanel.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2DetailPanel.dart';
import 'package:illinois/ui/events2/Event2SearchPanel.dart';
import 'package:illinois/ui/events2/Event2TimeRangePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/explore/ExploreMapPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';
import 'package:url_launcher/url_launcher.dart';

class Event2HomePanel extends StatefulWidget {

  static const String routeName = 'Event2HomePanel';

  final Event2TimeFilter? timeFilter;
  final TZDateTime? customStartTime;
  final TZDateTime? customEndTime;

  final LinkedHashSet<Event2TypeFilter>? types;
  final Map<String, dynamic>? attributes;

  final Event2Selector? eventSelector;

  Event2HomePanel({Key? key,
    this.timeFilter, this.customStartTime, this.customEndTime,
    this.types, this.attributes, this.eventSelector
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Event2HomePanelState();

  // Filters onboarding

  static void present(BuildContext context, {Event2Selector? eventSelector, Map<String, dynamic>? attributes}) {
    if (attributes != null) {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: Event2HomePanel.routeName), builder: (context) => Event2HomePanel(eventSelector: eventSelector, attributes: attributes, types: LinkedHashSet<Event2TypeFilter>(),)));
    }
    else if (Storage().events2Attributes != null) {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: Event2HomePanel.routeName), builder: (context) => Event2HomePanel(eventSelector: eventSelector,)));
    }
    else {
      getLocationServicesStatus().then((LocationServicesStatus? status) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => ContentAttributesPanel(
          title: Localization().getStringEx('panel.events2.home.attributes.launch.header.title', 'Events'),
          bgImageKey: 'event-filters-background',
          descriptionBuilder: _buildOnboardingDescription,
          sectionTitleTextStyle: Styles().textStyles?.getTextStyle('widget.title.tiny.highlight'),
          sectionDescriptionTextStyle: Styles().textStyles?.getTextStyle('widget.item.small.thin.highlight'),
          sectionRequiredMarkTextStyle: Styles().textStyles?.getTextStyle('widget.title.tiny.extra_fat.highlight'),
          applyBuilder: _buildOnboardingApply,
          continueTitle: Localization().getStringEx('panel.events2.home.attributes.launch.continue.title', 'Set Up Later'),
          continueTextStyle: Styles().textStyles?.getTextStyle('widget.button.title.medium.underline.highlight'),
          contentAttributes: buildContentAttributesV1(status: status),
          sortType: ContentAttributesSortType.native,
          filtersMode: true,
        ))).then((result) {
          Map<String, dynamic>? selection = JsonUtils.mapValue(result);
          if (selection != null) {
            
            List<Event2TypeFilter>? typesList = event2TypeFilterListFromSelection(selection[eventTypeContentAttributeId]);
            Storage().events2Types = event2TypeFilterListToStringList(typesList) ;

            Map<String, dynamic> attributes = Map<String, dynamic>.from(selection);
            attributes.remove(eventTypeContentAttributeId);
            Storage().events2Attributes = attributes;

            Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: Event2HomePanel.routeName), builder: (context) => Event2HomePanel(
              types: (typesList != null) ? LinkedHashSet<Event2TypeFilter>.from(typesList) : null,
              attributes: attributes,
              eventSelector: eventSelector,
            )));
          }
        });
      });
    }
  }

  static Widget _buildOnboardingDescription(BuildContext context) {
    String decriptionHtml = Localization().getStringEx("panel.events2.home.attributes.launch.header.description", "Customize your events feed by setting the below filters or <a href='{{events2_url}}'>view all events now<a> and choose your event filters later.").
      replaceAll('{{events2_url}}', url);
    TextStyle? descriptionTextStyle = Styles().textStyles?.getTextStyle('widget.description.medium.fat.highlight'); // TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 18, color: Styles().colors!.white);
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: EdgeInsets.only(top: 32), child:
          Styles().images?.getImage('event-onboarding-header') ?? Container(),
        ),
        Padding(padding: EdgeInsets.only(top: 24, bottom: 8), child:
          HtmlWidget("<div style=text-align:center>$decriptionHtml</div>",
            onTapUrl: (url) => _onTapLinkUrl(context, url),
            textStyle: descriptionTextStyle,
            customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(descriptionTextStyle?.color ?? Colors.white)} : null
          ),
        ),
      ],)
    );
  }

  static String url = "${DeepLink().appUrl}/events2";

  static Map<String, dynamic> athleticsCategoryAttributes = {'category': 'Big 10 Athletics'};

  static Future<bool> _onTapLinkUrl(BuildContext context, String urlParam) async {
    if (urlParam == url) {
      Navigator.of(context).pop(<String, dynamic>{});
      return true;
    }
    else {
      Uri? uri = Uri.tryParse(urlParam);
      if ((uri != null) && (await canLaunchUrl(uri))) {
        LaunchMode launchMode = Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault;
        launchUrl(uri, mode: launchMode);
        return true;
      }
    }
    return false;
  }

  static Widget _buildOnboardingApply(BuildContext context, bool enabled, void Function() onTap) {
    String applyTitle = Localization().getStringEx('panel.events2.home.attributes.launch.apply.title', 'Create My Events Feed');
    TextStyle? applyTextStyle = Styles().textStyles?.getTextStyle(enabled ? 'widget.button.title.medium.fat' : 'widget.button.title.regular.variant3');
    Color? borderColor = enabled ? Styles().colors?.fillColorSecondary : Styles().colors?.fillColorPrimaryVariant;
    Decoration? applyDecoration = BoxDecoration(
      color: Styles().colors!.white,
      border: Border.all(color: borderColor ?? Colors.transparent, width: 1),
      borderRadius: BorderRadius.all(Radius.circular(16))
    );
    return InkWell(onTap: onTap, child:
      Container(decoration: applyDecoration, child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), child:
          Text(applyTitle, style: applyTextStyle, textAlign: TextAlign.center, maxLines: null,),
        )
      ),
    );
  }
  
  // Location Services

  static Future<LocationServicesStatus?> getLocationServicesStatus() async =>
    FlexUI().isLocationServicesAvailable ? await LocationServices().status : LocationServicesStatus.serviceDisabled;

  static Future<Position?> getUserLocationIfAvailable() async =>
    ((await Event2HomePanel.getLocationServicesStatus()) == LocationServicesStatus.permissionAllowed) ?
      await LocationServices().location : null;

  // ContentAttributes + EventType filter

  static ContentAttributes? buildContentAttributesV1({LocationServicesStatus? status}) {
    ContentAttributes? contentAttributes = ContentAttributes.fromOther(Events2().contentAttributes);
    contentAttributes?.attributes?.insert(0, buildEventTypeContentAttribute(status: status));
    return contentAttributes;
  }

  static const String internalContentAttributesScope = 'internal';
  static const String eventTypeContentAttributeId = 'event-type';
  static const String eventTimeContentAttributeId = 'event-time';

  static ContentAttribute buildEventTypeContentAttribute({ LocationServicesStatus? status }) {
    List<ContentAttributeValue> values = <ContentAttributeValue>[];
    bool locationAvailable = ((status == LocationServicesStatus.permissionAllowed) || (status == LocationServicesStatus.permissionNotDetermined));
    for (Event2TypeFilter value in Event2TypeFilter.values) {
      if ((value != Event2TypeFilter.nearby) || locationAvailable) {
        values.add(ContentAttributeValue(
          label: event2TypeFilterToDisplayString(value),
          value: value,
          group: eventTypeFilterGroups[value],
        ));
      } 
    }

    return ContentAttribute(
      id: eventTypeContentAttributeId,
      title: Localization().getStringEx('panel.events2.home.attributes.event_type.title', 'Event Type'),
      emptyHint: Localization().getStringEx('panel.events2.home.attributes.event_type.hint.empty', 'Select an event type'),
      semanticsHint: Localization().getStringEx('panel.events2.home.attributes.event_type.hint.semantics', 'Double type to show event options.'),
      widget: ContentAttributeWidget.dropdown,
      scope: <String>{ internalContentAttributesScope },
      requirements: ContentAttributeRequirements(maxSelectedCount: 1, functionalScope: contentAttributeRequirementsFunctionalScopeFilter),
      values: values
    );
  }

  // ContentAttributes + EventTime & EventType filter

  static ContentAttributes? buildContentAttributesV2({LocationServicesStatus? status, TZDateTime? customStartTime, TZDateTime? customEndTime }) {
    ContentAttributes? contentAttributes = ContentAttributes.fromOther(buildContentAttributesV1(status: status));
    contentAttributes?.attributes?.insert(0, Event2HomePanel.eventTimeContentAttribute(customStartTime: customStartTime, customEndTime: customEndTime));
    return contentAttributes;
  }

  static ContentAttribute eventTimeContentAttribute({ TZDateTime? customStartTime, TZDateTime? customEndTime }) {
    List<ContentAttributeValue> values = <ContentAttributeValue>[];
    for (Event2TimeFilter value in Event2TimeFilter.values) {
      values.add((value != Event2TimeFilter.customRange) ? ContentAttributeValue(
        label: event2TimeFilterToDisplayString(value),
        info: event2TimeFilterDisplayInfo(value),
        value: value,
      ) : _CustomRangeEventTimeAttributeValue(
        label: event2TimeFilterToDisplayString(value),
        info: event2TimeFilterDisplayInfo(value, customStartTime: customStartTime, customEndTime: customEndTime),
        value: value,
        customData: Event2TimeRangePanel.buldCustomData(customStartTime, customEndTime),
      ));
    }

    return ContentAttribute(
      id: eventTimeContentAttributeId,
      title: Localization().getStringEx('panel.events2.home.attributes.event_time.title', 'Date & Time'),
      emptyHint: Localization().getStringEx('panel.events2.home.attributes.event_time.hint.empty', 'Select an date & time'),
      semanticsHint: Localization().getStringEx('panel.events2.home.attributes.event_time.hint.semantics', 'Double type to show date & time options.'),
      widget: ContentAttributeWidget.dropdown,
      scope: <String>{ internalContentAttributesScope },
      requirements: ContentAttributeRequirements(minSelectedCount: 1, maxSelectedCount: 1, functionalScope: contentAttributeRequirementsFunctionalScopeFilter),
      values: values,
    );
  }

  // Filters UI

  static Future<Event2FilterParam?> presentFiltersV2(BuildContext context, Event2FilterParam filterParam, { LocationServicesStatus? status }) async {

    ContentAttributes? contentAttributes = buildContentAttributesV2(
      status: status,
      customStartTime: filterParam.customStartTime,
      customEndTime: filterParam.customEndTime,
    );

    if (contentAttributes != null) {
      Map<String, dynamic>? selection = (filterParam.attributes != null) ? Map<String, dynamic>.from(filterParam.attributes!) : <String, dynamic> {};
      selection[eventTimeContentAttributeId] = (filterParam.timeFilter != null) ? <Event2TimeFilter>[filterParam.timeFilter!] : <Event2TimeFilter>[];
      selection[eventTypeContentAttributeId] = (filterParam.types != null) ? filterParam.types!.toList() : <Event2TypeFilter>[];

      dynamic result = await Navigator.push(context, CupertinoPageRoute(builder: (context) => ContentAttributesPanel(
        title: Localization().getStringEx('panel.events2.home.attributes.filters.header.title', 'Event Filters'),
        description: Localization().getStringEx('panel.events2.home.attributes.filters.header.description', 'Choose one or more attributes to filter the events.'),
        contentAttributes: contentAttributes,
        selection: selection,
        sortType: ContentAttributesSortType.native,
        filtersMode: true,
        handleAttributeValue: handleAttributeValue,
      )));

      selection = JsonUtils.mapValue(result);
      if (selection != null) {

        TZDateTime? customStartTime, customEndTime;
        Event2TimeFilter? timeFilter = event2TimeFilterListFromSelection(selection[eventTimeContentAttributeId]);
        if (timeFilter == Event2TimeFilter.customRange) {
          Map<String, dynamic>? customData = contentAttributes.findAttribute(id: eventTimeContentAttributeId)?.findValue(value: Event2TimeFilter.customRange)?.customData;
          customStartTime = Event2TimeRangePanel.getStartTime(customData);
          customEndTime = Event2TimeRangePanel.getEndTime(customData);
        }

        List<Event2TypeFilter>? typesList = event2TypeFilterListFromSelection(selection[eventTypeContentAttributeId]);

        Map<String, dynamic> attributes = Map<String, dynamic>.from(selection);
        attributes.remove(Event2HomePanel.eventTimeContentAttributeId);
        attributes.remove(Event2HomePanel.eventTypeContentAttributeId);

        return Event2FilterParam(
          timeFilter: timeFilter,
          customStartTime: customStartTime,
          customEndTime: customEndTime,
          types: (typesList != null) ? LinkedHashSet<Event2TypeFilter>.from(typesList) : null,
          attributes: attributes
        );
      }
      else {
        return null;
      }
    }
    else {
      return null;
    }
  }

  static Future<bool?> handleAttributeValue({required BuildContext context, required ContentAttribute attribute, required ContentAttributeValue value}) async {
    return ((attribute.id == eventTimeContentAttributeId) && (value.value == Event2TimeFilter.customRange)) ?
      handleCustomRangeTimeAttribute(context: context, attribute: attribute, value: value) : null;
  }

  static Future<bool> handleCustomRangeTimeAttribute({required BuildContext context, required ContentAttribute attribute, required ContentAttributeValue value}) async {
    dynamic result = await Navigator.of(context).push(CupertinoPageRoute(builder: (context) => Event2TimeRangePanel(customData: value.customData,)));
    Map<String, dynamic>? customData = JsonUtils.mapValue(result);
    if (customData != null) {
      value.customData = customData;
      value.info = event2TimeFilterDisplayInfo(Event2TimeFilter.customRange, customStartTime: Event2TimeRangePanel.getStartTime(customData), customEndTime: Event2TimeRangePanel.getEndTime(customData));
      return true;
    }
    else {
      return false;
    }
  }
}

class _Event2HomePanelState extends State<Event2HomePanel> implements NotificationsListener {

  List<Event2>? _events;
  bool? _lastPageLoadedAll;
  int? _totalEventsCount;
  String? _eventsErrorText;
  bool _loadingEvents = false;
  bool _refreshingEvents = false;
  bool _extendingEvents = false;
  static const int _eventsPageLength = 16;

  late Event2TimeFilter _timeFilter;
  TZDateTime? _customStartTime;
  TZDateTime? _customEndTime;
  late LinkedHashSet<Event2TypeFilter> _types;
  late Map<String, dynamic> _attributes;
  
  late Event2SortType _sortType;
  double? _sortDropdownWidth;

  LocationServicesStatus? _locationServicesStatus;
  bool _loadingLocationServicesStatus = false;
  Position? _currentLocation;

  ScrollController _scrollController = ScrollController();

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

    if ((widget.timeFilter != null) && ((widget.timeFilter != Event2TimeFilter.customRange) || ((widget.customStartTime != null) && (widget.customEndTime != null)))) {
      _timeFilter = widget.timeFilter!;
      _customStartTime = (_timeFilter == Event2TimeFilter.customRange) ? widget.customStartTime : null;
      _customEndTime = (_timeFilter == Event2TimeFilter.customRange) ? widget.customEndTime : null;
    }
    else {
      _timeFilter = event2TimeFilterFromString(Storage().events2Time) ?? Event2TimeFilter.upcoming;
      _customStartTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomStartTime));
      _customEndTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomEndTime));
    }

    _types = widget.types ?? LinkedHashSetUtils.from<Event2TypeFilter>(event2TypeFilterListFromStringList(Storage().events2Types)) ?? LinkedHashSet<Event2TypeFilter>();
    _attributes = widget.attributes ?? Storage().events2Attributes ?? <String, dynamic>{};
    _sortType = event2SortTypeFromString(Storage().events2SortType) ?? Event2SortType.dateTime;

    _initLocationServicesStatus().then((_) {
      _ensureCurrentLocation();
      _reload();
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
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == Auth2.notifyLoginChanged) {
      _refresh();
    }
    else if (name == FlexUI.notifyChanged) {
      _currentLocation = null;
      _updateLocationServicesStatus().then((_) {
        _ensureCurrentLocation();
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
      _currentLocation = null;
    }
    else if (state == AppLifecycleState.resumed) {
      _updateLocationServicesStatus().then((_) {
        _ensureCurrentLocation();
      });
    }
  }

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
          SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), child:
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
            contentPadding: EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 12),
            onTap: _onCreate
          ),
        ),
        Event2ImageCommandButton('search',
          label: Localization().getStringEx('panel.events2.home.bar.button.search.title', 'Search'),
          hint: Localization().getStringEx('panel.events2.home.bar.button.search.hint', 'Tap to search events'),
          contentPadding: EdgeInsets.only(left: 8, right: 16, top: 12, bottom: 12),
          onTap: _onSearch
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
    }

    if ((1 < (_events?.length ?? 0)) || _loadingEvents || _refreshingEvents) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: '; ', style: regularStyle,),);
      }

      String? sortStatus = event2SortTypeDisplayStatusString(_sortType);
      if (sortStatus != null) {
        descriptionList.add(TextSpan(text: Localization().getStringEx('panel.events2.home.attributes.sort.label.title', 'Sort: ') , style: boldStyle,));
        descriptionList.add(TextSpan(text: sortStatus, style: regularStyle,),);
      }
    }

    if ((_totalEventsCount != null) && !_loadingEvents && !_refreshingEvents) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: '; ', style: regularStyle,),);
      }

      String? sortStatus = event2SortTypeDisplayStatusString(_sortType);
      if (sortStatus != null) {
        descriptionList.add(TextSpan(text: Localization().getStringEx('panel.events2.home.attributes.events.label.title', 'Events: ') , style: boldStyle,));
        descriptionList.add(TextSpan(text: _totalEventsCount?.toString(), style: regularStyle,),);
      }
    } 

    if (descriptionList.isNotEmpty) {
      descriptionList.add(TextSpan(text: '.', style: regularStyle,),);
      return Padding(padding: EdgeInsets.only(top: 12), child:
        Container(decoration: _contentDescriptionDecoration, padding: EdgeInsets.only(top: 12, left: 16, right: 16), child:
          Row(children: [ Expanded(child:
            RichText(text: TextSpan(style: regularStyle, children: descriptionList))
          ),],)
      ));
    }
    else {
      return Container();
    }
  }

  Decoration get _contentDescriptionDecoration => BoxDecoration(
    color: Styles().colors?.white,
    border: Border(top: BorderSide(color: Styles().colors?.disabledTextColor ?? Color(0xFF717273), width: 1))
  );

  Widget _buildEventsContent() {
    if (_loadingEvents || _loadingLocationServicesStatus) {
      return _buildLoadingContent();
    }
    else if (_refreshingEvents) {
      return Container();
    }
    else if (_events == null) {
      return _buildMessageContent(_eventsErrorText ?? Localization().getStringEx('logic.general.unknown_error', 'Unknown Error Occurred'),
        title: Localization().getStringEx('panel.events2.home.message.failed.title', 'Failed')
      );
    }
    else if (_events?.length == 0) {
      return _buildMessageContent(Localization().getStringEx('panel.events2.home.message.empty.description', 'There are no events matching the selected filters.'));
    }
    else {
      return _buildEventsList();
    }
  }

  Widget _buildEventsList() {
    List<Widget> cardsList = <Widget>[];
    for (Event2 event in _events!) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 8 : 0), child:
        Event2Card(event, userLocation: _currentLocation, onTap: () => _onEvent(event),),
      ),);
    }
    if (_extendingEvents) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 8 : 0), child:
        _extendingIndicator
      ));
    }
    return Padding(padding: EdgeInsets.all(16), child:
      Column(children:  cardsList,)
    );
  }

  double get _screenHeight => MediaQuery.of(context).size.height;

  Widget _buildMessageContent(String message, { String? title }) =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: _screenHeight / 6), child:
      Column(children: [
        (title != null) ? Padding(padding: EdgeInsets.only(bottom: 12), child:
          Text(title, textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle('widget.item.medium.fat'),)
        ) : Container(),
        Text(message, textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle((title != null) ? 'widget.item.regular.thin' : 'widget.item.medium.fat'),),
      ],),
    );

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

  Widget get _extendingIndicator => Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32), child:
    Align(alignment: Alignment.center, child:
      SizedBox(width: 24, height: 24, child:
        CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary),),),),);

  void _scrollListener() {
    if ((_scrollController.offset >= _scrollController.position.maxScrollExtent) && (_hasMoreEvents != false) && !_loadingEvents && !_extendingEvents) {
      _extend();
    }
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

  // Location Status and Position

  Future<void> _initLocationServicesStatus() async {
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

  Future<Position?> _ensureCurrentLocation({ bool prompt = false}) async {
    if (_currentLocation == null) {
      if (prompt && (_locationServicesStatus == LocationServicesStatus.permissionNotDetermined)) {
        _locationServicesStatus = await LocationServices().requestPermission();
        _updateOnLocationServicesStatus();
      }
      if (_locationServicesStatus == LocationServicesStatus.permissionAllowed) {
        _currentLocation = await LocationServices().location;
      }
    }
    return _currentLocation;
  } 

  // Event2 Query

  bool get _queryNeedsLocation => (_types.contains(Event2TypeFilter.nearby) || (_sortType == Event2SortType.proximity));

  Future<Events2Query> _queryParam({int offset = 0, int limit = _eventsPageLength}) async {
    if (_queryNeedsLocation) {
      await _ensureCurrentLocation(prompt: true);
    }
    return Events2Query(
      offset: offset,
      limit: limit,
      timeFilter: _timeFilter,
      customStartTimeUtc: _customStartTime?.toUtc(),
      customEndTimeUtc: _customEndTime?.toUtc(),
      types: _types,
      attributes: _attributes,
      sortType: _sortType,
      sortOrder: Event2SortOrder.ascending,
      location: _currentLocation,
    );
  } 

  Future<void> _reload({ int limit = _eventsPageLength }) async {
    if (!_loadingEvents && !_refreshingEvents) {
      setStateIfMounted(() {
        _loadingEvents = true;
        _extendingEvents = false;
      });

      dynamic result = await Events2().loadEventsEx(await _queryParam(limit: limit));
      Events2ListResult? listResult = (result is Events2ListResult) ? result : null;
      List<Event2>? events = listResult?.events;
      String? errorTextResult = (result is String) ? result : null;

      setStateIfMounted(() {
        _events = (events != null) ? List<Event2>.from(events) : null;
        _totalEventsCount = listResult?.totalCount;
        _lastPageLoadedAll = (events != null) ? (events.length >= limit) : null;
        _eventsErrorText = errorTextResult;
        _loadingEvents = false;
      });
    }
  }

  bool? get _hasMoreEvents => (_totalEventsCount != null) ?
    ((_events?.length ?? 0) < _totalEventsCount!) : _lastPageLoadedAll;

  Future<void> _refresh() async {

    if (!_loadingEvents && !_refreshingEvents) {
      setStateIfMounted(() {
        _refreshingEvents = true;
        _extendingEvents = false;
      });

      int limit = max(_events?.length ?? 0, _eventsPageLength);
      dynamic result = await Events2().loadEventsEx(await _queryParam(limit: limit));
      Events2ListResult? listResult = (result is Events2ListResult) ? result : null;
      List<Event2>? events = listResult?.events;
      int? totalCount = listResult?.totalCount;
      String? errorTextResult = (result is String) ? result : null;

      setStateIfMounted(() {
        if (events != null) {
          _events = List<Event2>.from(events);
          _lastPageLoadedAll = (events.length >= limit);
          _eventsErrorText = null;
        }
        else if (_events == null) {
          // If there was events content, preserve it. Otherwise, show the error
          _eventsErrorText = errorTextResult;
        }
        if (totalCount != null) {
          _totalEventsCount = totalCount;
        }
        _refreshingEvents = false;
      });
    }
  }

  Future<void> _extend() async {
    if (!_loadingEvents && !_refreshingEvents && !_extendingEvents) {
      setStateIfMounted(() {
        _extendingEvents = true;
      });

      Events2ListResult? listResult = await Events2().loadEvents(await _queryParam(offset: _events?.length ?? 0, limit: _eventsPageLength));
      List<Event2>? events = listResult?.events;
      int? totalCount = listResult?.totalCount;

      if (mounted && _extendingEvents && !_loadingEvents && !_refreshingEvents) {
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
          if (totalCount != null) {
            _totalEventsCount = totalCount;
          }
          _extendingEvents = false;
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

  // Command Handlers

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

  void _onSearch() {
    Analytics().logSelect(target: 'Search');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2SearchPanel(searchContext: Event2SearchContext.List, locationServicesStatus: _locationServicesStatus, userLocation: _currentLocation, eventSelector: widget.eventSelector)));
  }

  void _onCreate() {
    Analytics().logSelect(target: 'Create');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2CreatePanel()));
  }

  void _onMapView() {
    Analytics().logSelect(target: 'Map View');
    NotificationService().notify(ExploreMapPanel.notifySelect, ExploreMapSearchEventsParam(''));
  }

  void _onEvent(Event2 event) {
    Analytics().logSelect(target: 'Event: ${event.name}');
    if (event.hasGame) {
      widget.eventSelector?.data.event = event;
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(game: event.game, eventSelector: widget.eventSelector)));
    } else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2DetailPanel(event: event, userLocation: _currentLocation, eventSelector: widget.eventSelector,)));
    }
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

class Event2FilterParam {
  static const String notifyChanged = "edu.illinois.rokwire.event2.home.filters.changed";

  final Event2TimeFilter? timeFilter;
  final TZDateTime? customStartTime;
  final TZDateTime? customEndTime;
  final LinkedHashSet<Event2TypeFilter>? types;
  final Map<String, dynamic>? attributes;

  Event2FilterParam({
    this.timeFilter, this.customStartTime, this.customEndTime,
    this.types, this.attributes,
  });

  static void notifySubscribersChanged({NotificationsListener? except}) {
    Set<NotificationsListener>? subscribers = NotificationService().subscribers(notifyChanged);
    if (subscribers != null) {
      for (NotificationsListener subscriber in subscribers) {
        if (subscriber != except) {
          subscriber.onNotification(notifyChanged, null);
        }
      }
    }
  }
}