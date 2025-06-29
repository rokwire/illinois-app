
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/assistant/AssistantHomePanel.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/attributes/ContentAttributesPanel.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2DetailPanel.dart';
import 'package:illinois/ui/widgets/QrCodePanel.dart';
import 'package:illinois/ui/events2/Event2SearchPanel.dart';
import 'package:illinois/ui/events2/Event2TimeRangePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/explore/ExploreMapPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
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

class Event2HomePanel extends StatefulWidget with AnalyticsInfo {

  static const String routeName = 'Event2HomePanel';

  final Event2TimeFilter? timeFilter;
  final TZDateTime? customStartTime;
  final TZDateTime? customEndTime;

  final LinkedHashSet<Event2TypeFilter>? types;
  final Map<String, dynamic>? attributes;

  final Event2SortType? sortType;

  final Event2Selector2? eventSelector;
  final AnalyticsFeature? analyticsFeature;  //This overrides AnalyticsInfo.analyticsFeature getter

  Event2HomePanel({Key? key,
    this.timeFilter, this.customStartTime, this.customEndTime,
    this.types, this.attributes, this.sortType,
    this.eventSelector, this.analyticsFeature,
  }) : super(key: key);

  factory Event2HomePanel.withFilter(Event2FilterParam filterParam, {Key? key}) => Event2HomePanel(
    key: key,
    timeFilter: filterParam.timeFilter,
    customStartTime: filterParam.customStartTime,
    customEndTime: filterParam.customEndTime,
    types: filterParam.types,
    attributes: filterParam.attributes,
  );

  @override
  State<StatefulWidget> createState() => _Event2HomePanelState();

  // Filters onboarding

  static void present(BuildContext context, {
    Event2TimeFilter? timeFilter, TZDateTime? customStartTime, TZDateTime? customEndTime,
    LinkedHashSet<Event2TypeFilter>? types, Map<String, dynamic>? attributes, Event2SortType? sortType,
    Event2Selector2? eventSelector, AnalyticsFeature? analyticsFeature,
  }) {
    if ((timeFilter != null) || (attributes != null) || (types != null)) {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: Event2HomePanel.routeName), builder: (context) => Event2HomePanel(
        timeFilter: timeFilter ?? Event2TimeFilter.upcoming, customStartTime: customStartTime, customEndTime: customEndTime,
        types: types ?? LinkedHashSet<Event2TypeFilter>(),
        attributes: attributes ?? <String, dynamic>{},
        sortType: sortType ?? Event2SortType.dateTime,
        eventSelector: eventSelector, analyticsFeature: analyticsFeature,
      )));
    }
    else if (Storage().events2Attributes != null) {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: Event2HomePanel.routeName), builder: (context) => Event2HomePanel(
        eventSelector: eventSelector, analyticsFeature: analyticsFeature,
      )));
    }
    else {
      getLocationServicesStatus().then((LocationServicesStatus? status) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => _Event2OnboardingFiltersPanel(
          status: status,
        ))).then((result) {
          Map<String, dynamic>? selection = JsonUtils.mapValue(result);
          if (selection != null) {

            List<Event2TypeFilter>? typesList = ListUtils.combine([
              Event2TypeFilterListImpl.fromAttributeSelection(selection[eventDetailsContentAttributeId]),
              Event2TypeFilterListImpl.fromAttributeSelection(selection[eventLimitsContentAttributeId]),
            ]);
            Storage().events2Types = typesList?.toJson();

            Map<String, dynamic> attributes = Map<String, dynamic>.from(selection);
            attributes.remove(eventDetailsContentAttributeId);
            attributes.remove(eventLimitsContentAttributeId);
            Storage().events2Attributes = attributes;

            Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: Event2HomePanel.routeName), builder: (context) => Event2HomePanel(
              types: (typesList != null) ? LinkedHashSet<Event2TypeFilter>.from(typesList) : null,
              attributes: attributes,
              eventSelector: eventSelector, analyticsFeature: analyticsFeature,
            )));
          }
        });
      });
    }
  }

  static Widget _buildOnboardingDescription(BuildContext context) {
    String decriptionHtml = Localization().getStringEx("panel.events2.home.attributes.launch.header.description", "Customize your events feed by setting the below filters or <a href='{{events2_url}}'>view all events now<a> and choose your event filters later.").
      replaceAll('{{events2_url}}', url);
    TextStyle? descriptionTextStyle = Styles().textStyles.getTextStyle('widget.description.medium.fat.highlight'); // TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 18, color: Styles().colors.white);
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: EdgeInsets.only(top: 32), child:
          Styles().images.getImage('event-onboarding-header') ?? Container(),
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

  static Widget? _buildFiltersFooter(BuildContext context) {
    Widget? infoIcon = Styles().images.getImage('info');
    return (Config().eventsPublishingInfoUrl?.isNotEmpty == true) ? InkWell(onTap: _onTapFilterFooter, child:
      Padding(padding: const EdgeInsets.symmetric(vertical: 8), child:
        Row(children: [
          if (infoIcon != null)
            Padding(padding: const EdgeInsets.only(right: 4), child:
                infoIcon,
            ),
          Expanded(child:
            Text(Localization().getStringEx('panel.events2.home.attributes.footer.text', 'How are events published in the {{app_title}} app?').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')),
              style: Styles().textStyles.getTextStyle('widget.description.regular.underline'),
            )
          )
        ],)
      )
    ) : null;
  }
  
  static void _onTapFilterFooter() {
    String? url = Config().eventsPublishingInfoUrl;
    if (DeepLink().isAppUrl(url)) {
      DeepLink().launchUrl(url);
    }
    else if (url != null) {
      Uri? uri = Uri.tryParse(url);
      if (uri != null) {
        launchUrl(uri);
      }
    }
  }

  static String url = "${DeepLink().appUrl}/events2";

  static Map<String, dynamic> athleticsCategoryAttributes = {'category': Events2.sportEventCategory};

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
    TextStyle? applyTextStyle = Styles().textStyles.getTextStyle(enabled ? 'widget.button.title.medium.fat' : 'widget.button.title.regular.variant3');
    Color? borderColor = enabled ? Styles().colors.fillColorSecondary : Styles().colors.fillColorPrimaryVariant;
    Decoration? applyDecoration = BoxDecoration(
      color: Styles().colors.white,
      border: Border.all(color: borderColor, width: 1),
      borderRadius: BorderRadius.all(Radius.circular(16))
    );
    return InkWell(onTap: () => _onTapOnboardingApply(onTap), child:
      Container(decoration: applyDecoration, child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), child:
          Text(_onboardingApplyTitle, style: applyTextStyle, textAlign: TextAlign.center, maxLines: null,),
        )
      ),
    );
  }

  static String get _onboardingApplyTitle => _onboardingApplyTitleEx();

  static String _onboardingApplyTitleEx({String? language}) =>
    Localization().getStringEx('panel.events2.home.attributes.launch.apply.title', 'Create My Events Feed', language: language);

  static void _onTapOnboardingApply(void Function() applyHandler) {
    Analytics().logSelect(target: _onboardingApplyTitleEx(language: 'en'));
    applyHandler();
  }
  
  static Widget _buildOnboardingContinue(BuildContext context, void Function() onTap) =>
    InkWell(onTap: () => _onTapOnboardingContinue(onTap), child:
      Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
        Text(_onboardingContinueTitle, style: Styles().textStyles.getTextStyle('widget.button.title.medium.underline.highlight'),)
      ),
    );

  static String get _onboardingContinueTitle => _onboardingContinueTitleEx();

  static String _onboardingContinueTitleEx({String? language}) =>
    Localization().getStringEx('panel.events2.home.attributes.launch.continue.title', 'Set Up Later', language: language);

  static void _onTapOnboardingContinue(void Function() continueHandler) {
    Analytics().logSelect(target: _onboardingContinueTitleEx(language: 'en'));
    continueHandler();
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
    contentAttributes?.attributes?.insert(0, buildEventDetailsContentAttribute());
    contentAttributes?.attributes?.add(buildEventLimitsContentAttribute(status: status));
    return contentAttributes;
  }

  static ContentAttribute buildEventDetailsContentAttribute() {
    List<ContentAttributeValue> values = <ContentAttributeValue>[];
    for (Event2TypeFilter value in Event2TypeFilter.values) {
      Event2TypeGroup? group = eventTypeFilterGroups[value];
      if (group != Event2TypeGroup.limits) {
        values.add(ContentAttributeValue(
          label: event2TypeFilterToDisplayString(value),
          value: value,
          group: group?.name,
        ));
      } 
    }

    return ContentAttribute(
      id: eventDetailsContentAttributeId,
      title: Localization().getStringEx('panel.events2.home.attributes.event_details.title', 'Event Details'),
      emptyHint: Localization().getStringEx('panel.events2.home.attributes.event_details.hint.empty', 'Select event details'),
      semanticsHint: Localization().getStringEx('panel.events2.home.attributes.event_details.hint.semantics', 'Double type to show event details.'),
      widget: ContentAttributeWidget.dropdown,
      scope: <String>{ Events2.contentAttributesScope },
      groupsRequirements: <String, ContentAttributeRequirements>{
        ContentAttribute.anyGroupRequirements: ContentAttributeRequirements(maxSelectedCount: 1, functionalScope: contentAttributeRequirementsFunctionalScopeFilter),
      },
      values: values,
      translations: event2TypeGroupToTranslationsMap(),
    );
  }

  static ContentAttribute buildEventLimitsContentAttribute({ LocationServicesStatus? status }) {
    List<ContentAttributeValue> values = <ContentAttributeValue>[];
    bool locationAvailable = ((status == LocationServicesStatus.permissionAllowed) || (status == LocationServicesStatus.permissionNotDetermined));
    for (Event2TypeFilter value in Event2TypeFilter.values) {
      Event2TypeGroup? group = eventTypeFilterGroups[value];
      if ((group == Event2TypeGroup.limits) && ((value != Event2TypeFilter.nearby) || locationAvailable)) {
        values.add(ContentAttributeValue(
          label: event2TypeFilterToDisplayString(value),
          selectLabel: event2TypeFilterToSelectDisplayString(value),
          value: value,
          group: group?.name,
        ));
      }
    }

    return ContentAttribute(
      id: eventLimitsContentAttributeId,
      title: Localization().getStringEx('panel.events2.home.attributes.event_limits.title', 'Event Limits'),
      longTitle: Localization().getStringEx('panel.events2.home.attributes.event_limits.long_title', 'Limit Results To'),
      emptyHint: Localization().getStringEx('panel.events2.home.attributes.event_limits.hint.empty', 'Choose limits'),
      semanticsHint: Localization().getStringEx('panel.events2.home.attributes.event_limits.hint.semantics', 'Double type to show event limits.'),
      widget: ContentAttributeWidget.dropdown,
      scope: <String>{ Events2.contentAttributesScope },
      groupsRequirements: <String, ContentAttributeRequirements>{
        Event2TypeGroup.limits.name: ContentAttributeRequirements(functionalScope: contentAttributeRequirementsFunctionalScopeFilter),
      },
      values: values,
      translations: event2TypeGroupToTranslationsMap(),
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
      scope: <String>{ Events2.contentAttributesScope },
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
      selection[eventDetailsContentAttributeId] = (filterParam.types != null) ? List<Event2TypeFilter>.from(filterParam.types?.where((type) => eventTypeFilterGroups[type] != Event2TypeGroup.limits) ?? <Event2TypeFilter>[]) : <Event2TypeFilter>[];
      selection[eventLimitsContentAttributeId] = (filterParam.types != null) ? List<Event2TypeFilter>.from(filterParam.types?.where((type) => eventTypeFilterGroups[type] == Event2TypeGroup.limits) ?? <Event2TypeFilter>[]) : <Event2TypeFilter>[];

      dynamic result = await Navigator.push(context, CupertinoPageRoute(builder: (context) => ContentAttributesPanel(
        title: Localization().getStringEx('panel.events2.home.attributes.filters.header.title', 'Event Filters'),
        description: Localization().getStringEx('panel.events2.home.attributes.filters.header.description', 'Choose one or more attributes to filter the events.'),
        contentAttributes: contentAttributes,
        selection: selection,
        scope: Events2.contentAttributesScope,
        sortType: ContentAttributesSortType.native,
        filtersMode: true,
        footerBuilder: _buildFiltersFooter,
        handleAttributeValue: handleAttributeValue,
        countAttributeValues: countAttributeValues,
      )));

      selection = JsonUtils.mapValue(result);
      return (selection != null) ? Event2FilterParam.fromAttributesSelection(selection, contentAttributes: contentAttributes) : null;
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

  static Future<Map<dynamic, int?>?> countAttributeValues({
    required ContentAttribute attribute,
    required List<ContentAttributeValue> attributeValues,
    Map<String, dynamic>? attributesSelection,
    ContentAttributes? contentAttributes,
  }) async {
    String? attributeId = attribute.id;
    if (attributeId != null) {
      Events2Query baseFilterQuery = Events2QueryImpl.fromFilterParam(Event2FilterParam.fromAttributesSelection(attributesSelection ?? {}, contentAttributes: contentAttributes), groupings: Event2Grouping.individualEvents());

      Map<String, dynamic> valueIds = <String, dynamic>{};
      Map<String, Events2Query> countQueries = <String, Events2Query>{};
      for (ContentAttributeValue attributeValue in attributeValues) {
        String? valueId = attributeValue.valueId;
        if (valueId != null) {
          valueIds[valueId] = attributeValue.value;
          countQueries[valueId] = Events2QueryImpl.fromFilterParam(Event2FilterParam.fromAttributesSelection({
            attributeId: attributeValue.value,
          }, contentAttributes: contentAttributes));
        }
      }

      Map<String, int?>? counts = await Events2().loadEventsCounts(baseQuery: baseFilterQuery, countQueries: countQueries,);
      return counts?.map<dynamic, int?>((String valueId, int? count) => MapEntry(valueIds[valueId], count));
    }
    return null;
  }
}

class _Event2HomePanelState extends State<Event2HomePanel> with NotificationsListener {

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

  GlobalKey? _sortButtonKey;
  GlobalKey? _filtersButtonKey;

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
      _timeFilter = widget.timeFilter ?? Event2TimeFilter.upcoming;
      _customStartTime = (_timeFilter == Event2TimeFilter.customRange) ? widget.customStartTime : null;
      _customEndTime = (_timeFilter == Event2TimeFilter.customRange) ? widget.customEndTime : null;
    }
    else {
      _timeFilter = Event2TimeFilterImpl.fromJson(Storage().events2Time) ?? Event2TimeFilter.upcoming;
      _customStartTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomStartTime));
      _customEndTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomEndTime));
    }

    _types = widget.types ?? LinkedHashSetUtils.from<Event2TypeFilter>(Event2TypeFilterListImpl.listFromJson(Storage().events2Types)) ?? LinkedHashSet<Event2TypeFilter>();
    _attributes = widget.attributes ?? Storage().events2Attributes ?? <String, dynamic>{};
    _sortType = widget.sortType ?? event2SortTypeFromString(Storage().events2SortType) ?? Event2SortType.dateTime;

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
      backgroundColor: Styles().colors.background,
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
      Padding(padding: EdgeInsets.only(top: 8), child:
        Column(children: [
          _buildCommandButtons(),
          _buildContentDescription(),
        ],)
      ),
    );
  }

  Decoration get _commandBarDecoration => BoxDecoration(
    color: Styles().colors.white,
    border: Border.all(color: Styles().colors.disabledTextColor, width: 1)
  );

  Widget _buildCommandButtons() {
    return Row(children: [
      Padding(padding: EdgeInsets.only(left: 16)),
      Expanded(flex: 6, child: Wrap(spacing: 8, runSpacing: 8, children: [ //Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        MergeSemantics(key: _filtersButtonKey ??= GlobalKey(), child:
          Semantics(value: _currentFilterParam.descriptionText, child:
            Event2FilterCommandButton(
              title: Localization().getStringEx('panel.events2.home.bar.button.filter.title', 'Filter'),
              leftIconKey: 'filters',
              rightIconKey: 'chevron-right',
              onTap: _onFilters,
            )
          )
        ),
        _sortButton,

      ])),
      Expanded(flex: 4, child: Wrap(alignment: WrapAlignment.end, crossAxisAlignment: WrapCrossAlignment.center, verticalDirection: VerticalDirection.up, children: [
        LinkButton(
          title: Localization().getStringEx('panel.events2.home.bar.button.map.title', 'Map'), 
          hint: Localization().getStringEx('panel.events2.home.bar.button.map.hint', 'Tap to view map'),
          textStyle: Styles().textStyles.getTextStyle('widget.button.title.regular.underline'),
          padding: EdgeInsets.only(left: 0, right: 8, top: 12, bottom: 12),
          onTap: _onMapView,
        ),
        Visibility(visible: Auth2().isCalendarAdmin, child:
          Event2ImageCommandButton(Styles().images.getImage('plus-circle'),
            label: Localization().getStringEx('panel.events2.home.bar.button.create.title', 'Create'),
            hint: Localization().getStringEx('panel.events2.home.bar.button.create.hint', 'Tap to create event'),
            contentPadding: EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 12),
            onTap: _onCreate
          ),
        ),
        Event2ImageCommandButton(Styles().images.getImage('search'),
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
    return  MergeSemantics(key: _sortButtonKey ??= GlobalKey(), child: Semantics(value: event2SortTypeToDisplayString(_sortType), child:
      DropdownButtonHideUnderline(child:
        DropdownButton2<Event2SortType>(
          dropdownStyleData: DropdownStyleData(width: _sortDropdownWidth, padding: EdgeInsets.zero),
          customButton: Event2FilterCommandButton(
            title: Localization().getStringEx('panel.events2.home.bar.button.sort.title', 'Sort'),
            leftIconKey: 'sort'
          ),
          isExpanded: false,
          items: _buildSortDropdownItems(),
          onChanged: _onSortType,
        )
      )),
    );
  }

  List<DropdownMenuItem<Event2SortType>> _buildSortDropdownItems() {
    List<DropdownMenuItem<Event2SortType>> items = <DropdownMenuItem<Event2SortType>>[];
    bool locationAvailable = ((_locationServicesStatus == LocationServicesStatus.permissionAllowed) || (_locationServicesStatus == LocationServicesStatus.permissionNotDetermined));
    for (Event2SortType sortType in Event2SortType.values) {
      if ((sortType != Event2SortType.proximity) || locationAvailable) {
        String? displaySortType = _sortDropdownItemTitle(sortType);
        items.add(AccessibleDropDownMenuItem<Event2SortType>(
          key: ObjectKey(sortType),
          value: sortType,
          child: Semantics(label: displaySortType, button: true, container: true, inMutuallyExclusiveGroup: true,
            child: Text(displaySortType, overflow: TextOverflow.ellipsis, style: (_sortType == sortType) ?
              Styles().textStyles.getTextStyle("widget.message.regular.fat") :
              Styles().textStyles.getTextStyle("widget.message.regular"),
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
            style: Styles().textStyles.getTextStyle("widget.message.regular.fat"),
          ),
          textScaler: MediaQuery.of(context).textScaler,
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
    TextStyle? boldStyle = Styles().textStyles.getTextStyle("widget.card.title.tiny.fat");
    TextStyle? regularStyle = Styles().textStyles.getTextStyle("widget.card.detail.small.regular");
    List<InlineSpan> descriptionList = _currentFilterParam.buildDescription(boldStyle: boldStyle, regularStyle: regularStyle);

    if (descriptionList.isNotEmpty) {
      descriptionList.insert(0, TextSpan(text: Localization().getStringEx('panel.events2.home.attributes.filter.label.title', 'Filter: ') , style: boldStyle,));
    }

    if ((1 < (_events?.length ?? 0)) || _loadingEvents || _refreshingEvents) {
      String? sortStatus = event2SortTypeDisplayStatusString(_sortType);
      if (sortStatus != null) {
        if (descriptionList.isNotEmpty) {
          descriptionList.add(TextSpan(text: '; ', style: regularStyle,),);
        }

        descriptionList.add(TextSpan(text: Localization().getStringEx('panel.events2.home.attributes.sort.label.title', 'Sort: ') , style: boldStyle,));
        descriptionList.add(TextSpan(text: sortStatus, style: regularStyle,),);
      }
    }

    if ((_totalEventsCount != null) && !_loadingEvents && !_refreshingEvents) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: '; ', style: regularStyle,),);
      }

      descriptionList.add(TextSpan(text: Localization().getStringEx('panel.events2.home.attributes.events.label.title', 'Events: ') , style: boldStyle,));
      descriptionList.add(TextSpan(text: _totalEventsCount?.toString(), style: regularStyle,),);
    }

    if (descriptionList.isNotEmpty) {
      descriptionList.add(TextSpan(text: '.', style: regularStyle,),);
      return Padding(padding: EdgeInsets.only(top: 12), child:
        Container(decoration: _contentDescriptionDecoration, child:
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child:
              Padding(padding: EdgeInsets.only(left: 12, top: 16, bottom: 16), child:
                RichText(text: TextSpan(style: regularStyle, children: descriptionList)),
              ),
            ),
            Visibility(visible: _canShareFilters, child:
              Event2ImageCommandButton(Styles().images.getImage('share-nodes'),
                label: Localization().getStringEx('panel.events2.home.bar.button.share.title', 'Share Event Set'),
                hint: Localization().getStringEx('panel.events2.home.bar.button.share.hinr', 'Tap to share current event set'),
                contentPadding: EdgeInsets.only(left: 16, right: _canClearFilters ? (8 + 2) : 16, top: 12, bottom: 12),
                onTap: _onShareFilters
              ),
            ),
            Visibility(visible: _canClearFilters, child:
              Event2ImageCommandButton(Styles().images.getImage('close'), // size: 14
                label: Localization().getStringEx('panel.events2.home.bar.button.clear.title', 'Clear Filters'),
                hint: Localization().getStringEx('panel.events2.home.bar.button.clear.hinr', 'Tap to clear current filters'),
                contentPadding: EdgeInsets.only(left: 8 + 2, right: 16 + 2, top: 12, bottom: 12),
                onTap: _onClearFilters
              ),
            ),
          ],)
      ));
    }
    else {
      return Container(height: 12);
    }
  }

  Decoration get _contentDescriptionDecoration => BoxDecoration(
    color: Styles().colors.white,
    border: Border(top: BorderSide(color: Styles().colors.disabledTextColor, width: 1))
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
    if (_isAssistantPromptVisible) {
      cardsList.add(_buildAssistantPrompt());
    }
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

  Widget _buildAssistantPrompt() {
    Widget? imageWidget = Styles().images.getImage('assistant-prompt-orange');
    return CustomPaint(
      painter: _AssistantPromptShadowPainter(),
      child: ClipPath(
        clipper: _AssistantPromptClipper(),
        child: Container(
            padding: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Styles().colors.surface,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Stack(children: [
              Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 16, right: 30),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    (imageWidget != null) ? Padding(padding: EdgeInsets.only(right: 10), child: imageWidget) : Container(),
                    Expanded(
                        child: RichText(
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 4,
                            text: TextSpan(style: Styles().textStyles.getTextStyle('widget.message.regular'), children: [
                              TextSpan(text: Localization().getStringEx('panel.events2.assistant.prompt.header.text', 'Try asking the Illinois Assistant: '), style: Styles().textStyles.getTextStyle('widget.message.regular')),
                              TextSpan(text: Localization().getStringEx('panel.events2.assistant.prompt.question.text', "What's happening this weekend?"), style: Styles().textStyles.getTextStyle('widget.item.regular_underline.thin'), recognizer: TapGestureRecognizer()..onTap = () => _onTapAskAssistant()),
                            ])))
                    // Text('Try asking the Illinois Assistant', style: Styles().textStyles.getTextStyle('widget.message.regular'))
                  ])),
              Align(alignment: Alignment.topRight, child: GestureDetector(onTap: _onTapCloseAssistantPrompt, child: Padding(padding: EdgeInsets.only(left: 16, top: 8, right: 8, bottom: 16), child: Styles().images.getImage('close-circle-small', excludeFromSemantics: true))))
            ])),
      ),
    );
  }

  void _onTapAskAssistant() {
    Analytics().logEventsAssistantPrompt(action: 'clicked');
    AssistantHomePanel.present(context, initialQuestion: Localization().getStringEx('panel.events2.assistant.prompt.question.text', "What's happening this weekend?"));
    setStateIfMounted(() {
      Storage().assistantEventsPromptHidden = true;
    });
  }

  void _onTapCloseAssistantPrompt() {
    Analytics().logEventsAssistantPrompt(action: 'closed');
    setStateIfMounted(() {
      Storage().assistantEventsPromptHidden = true;
    });
  }

  bool get _isAssistantPromptVisible => Auth2().isOidcLoggedIn && (Storage().assistantEventsPromptHidden != true);

  double get _screenHeight => MediaQuery.of(context).size.height;

  Widget _buildMessageContent(String message, { String? title }) =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: _screenHeight / 6), child:
      Column(children: [
        (title != null) ? Padding(padding: EdgeInsets.only(bottom: 12), child:
          Text(title, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.item.medium.fat'),)
        ) : Container(),
        Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle((title != null) ? 'widget.item.regular.thin' : 'widget.item.medium.fat'),),
      ],),
    );

  Widget _buildLoadingContent() {
    double screenHeight = MediaQuery.of(context).size.height;
    return Column(children: [
      Padding(padding: EdgeInsets.symmetric(vertical: screenHeight / 4), child:
        SizedBox(width: 32, height: 32, child:
          CircularProgressIndicator(color: Styles().colors.fillColorSecondary,)
        )
      ),
      Container(height: screenHeight / 2,)
    ],);
  }

  Widget get _extendingIndicator => Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32), child:
    Align(alignment: Alignment.center, child:
      SizedBox(width: 24, height: 24, child:
        CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary),),),),);

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

          Storage().events2Time = _timeFilter.toJson();
          Storage().events2CustomStartTime = JsonUtils.encode(_customStartTime?.toJson());
          Storage().events2CustomEndTime = JsonUtils.encode(_customEndTime?.toJson());
          Storage().events2Types = _types.toJson();
          Storage().events2Attributes = _attributes;

          Event2FilterParam.notifySubscribersChanged(except: this);

          _reload().then((_) =>
              Future.delayed(Platform.isIOS ? Duration(seconds: 1) : Duration.zero, ()=>
                  AppSemantics.triggerAccessibilityFocus(_filtersButtonKey))
          );
      }
    });
  }

  void _updateFilers() {
    Event2TimeFilter? timeFilter = Event2TimeFilterImpl.fromJson(Storage().events2Time);
    TZDateTime? customStartTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomStartTime));
    TZDateTime? customEndTime = TZDateTimeExt.fromJson(JsonUtils.decode(Storage().events2CustomEndTime));
    LinkedHashSet<Event2TypeFilter>? types = LinkedHashSetUtils.from<Event2TypeFilter>(Event2TypeFilterListImpl.listFromJson(Storage().events2Types));
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
      groupings: Event2Grouping.individualEvents(),
      attributes: _attributes,
      sortType: _sortType,
      sortOrder: ((_timeFilter == Event2TimeFilter.past) && (_sortType == Event2SortType.dateTime)) ? Event2SortOrder.descending : Event2SortOrder.ascending,
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

  void _updateEventIfNeeded(dynamic event) {
    if ((event is Event2) && (event.id != null) && mounted) {
      int? index = Event2.indexInList(_events, id: event.id);
      if (index != null) {
        setState(() {
          _events?[index] = event;
        });
      }
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
        _reload().then((_)=>
            Future.delayed(Platform.isIOS ? Duration(seconds: 1) : Duration.zero, ()=>
                AppSemantics.triggerAccessibilityFocus(_sortButtonKey)));

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

  Event2FilterParam get _currentFilterParam => Event2FilterParam(
    timeFilter: _timeFilter,
    customStartTime: _customStartTime,
    customEndTime: _customEndTime,
    types: LinkedHashSetUtils.ensureEmpty(_types),
    attributes: MapUtils.ensureEmpty(_attributes),
  );

  bool get _canShareFilters => true;

  void _onShareFilters() {
    Analytics().logSelect(target: 'Share Filters');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => QrCodePanel.fromEventFilterParam(_currentFilterParam)));
  }

  bool get _canClearFilters =>
    (_timeFilter != Event2TimeFilter.upcoming) ||
    (_sortType != Event2SortType.dateTime) ||
    _types.isNotEmpty ||
    _attributes.isNotEmpty;

  void _onClearFilters() {
    Analytics().logSelect(target: 'Clear Filters');
    setState(() {
      _timeFilter = Event2TimeFilter.upcoming;
      _customStartTime = null;
      _customEndTime = null;
      _types = LinkedHashSet<Event2TypeFilter>();
      _attributes = <String, dynamic>{};
      _sortType = Event2SortType.dateTime;
    });

    Storage().events2Time = _timeFilter.toJson();
    Storage().events2CustomStartTime = JsonUtils.encode(_customStartTime?.toJson());
    Storage().events2CustomEndTime = JsonUtils.encode(_customEndTime?.toJson());
    Storage().events2Types = _types.toJson();
    Storage().events2Attributes = _attributes;
    Storage().events2SortType = event2SortTypeToString(_sortType);

    Event2FilterParam.notifySubscribersChanged(except: this);

    _reload();
  }

  void _onMapView() {
    Analytics().logSelect(target: 'Map View');
    NotificationService().notify(ExploreMapPanel.notifySelect, ExploreMapSearchEventsParam(''));
  }

  void _onEvent(Event2 event) {
    Analytics().logSelect(target: 'Event: ${event.name}');
    if (event.hasGame) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(game: event.game, event: event, eventSelector: widget.eventSelector)));
    } else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2DetailPanel(event: event, userLocation: _currentLocation, eventSelector: widget.eventSelector,)));
    }
  }
}

// _Event2OnboardingFiltersPanel

class _Event2OnboardingFiltersPanel extends ContentAttributesPanel {
  _Event2OnboardingFiltersPanel({Key? key, LocationServicesStatus? status }) : super(key: key,
    title: Localization().getStringEx('panel.events2.home.attributes.launch.header.title', 'Events'),
    bgImageKey: 'event-filters-background',
    descriptionBuilder: Event2HomePanel._buildOnboardingDescription,
    sectionTitleTextStyle: Styles().textStyles.getTextStyle('widget.title.tiny.fat.highlight'),
    sectionDescriptionTextStyle: Styles().textStyles.getTextStyle('widget.item.small.thin.highlight'),
    sectionRequiredMarkTextStyle: Styles().textStyles.getTextStyle('widget.title.tiny.extra_fat.highlight'),
    applyBuilder: Event2HomePanel._buildOnboardingApply,
    continueBuilder: Event2HomePanel._buildOnboardingContinue,
    contentAttributes: Event2HomePanel.buildContentAttributesV1(status: status),
    sortType: ContentAttributesSortType.native,
    scope: Events2.contentAttributesScope,
    filtersMode: true,
  );
}

// _CustomRangeEventTimeAttributeValue

class _CustomRangeEventTimeAttributeValue extends ContentAttributeValue {
  _CustomRangeEventTimeAttributeValue({String? label, dynamic value, String? group, Map<String, dynamic>? requirements, String? info, Map<String, dynamic>? customData }) :
    super (label: label, value: value, group: group, requirements: requirements, info: info, customData: customData);

  @override
  String? get selectedLabel {
    String title = Localization().getStringEx("model.event2.event_time.custom_range.selected", "Custom");
    return (StringUtils.isNotEmpty(info)) ? '$title $info' : title;
  }
}

// Custom Content Attribute Ids

const String eventDetailsContentAttributeId = 'event-details';
const String eventLimitsContentAttributeId = 'event-limits';
const String eventTimeContentAttributeId = 'event-time';

// Event2FilterParam

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

  factory Event2FilterParam.fromUriParams(Map<String, String> uriParams) {
    return Event2FilterParam(
      timeFilter: Event2TimeFilterImpl.fromJson(uriParams['time_filter']),
      customStartTime: TZDateTimeExt.fromJson(JsonUtils.decodeMap(uriParams['custom_start_time'])),
      customEndTime: TZDateTimeExt.fromJson(JsonUtils.decodeMap(uriParams['custom_end_time'])),
      types: LinkedHashSetUtils.from(Event2TypeFilterListImpl.listFromJson(JsonUtils.listStringsValue(JsonUtils.decodeList(uriParams['types'])))),
      attributes: JsonUtils.decodeMap(uriParams['attributes']),
    );
  }

  Map<String, String> toUriParams() {
    Map <String, String> uriParams = <String, String>{};
    MapUtils.add(uriParams, 'time_filter', timeFilter?.toJson());
    MapUtils.add(uriParams, 'custom_start_time', JsonUtils.encode(customStartTime?.toJson()));
    MapUtils.add(uriParams, 'custom_end_time', JsonUtils.encode(customEndTime?.toJson()));
    MapUtils.add(uriParams, 'types', JsonUtils.encode(types?.toJson()));
    MapUtils.add(uriParams, 'attributes', JsonUtils.encode(attributes));
    return uriParams;
  }

  factory Event2FilterParam.fromAttributesSelection(Map<String, dynamic> selection, { required ContentAttributes? contentAttributes }) {
    TZDateTime? customStartTime, customEndTime;
    Event2TimeFilter? timeFilter = Event2TimeFilterImpl.fromAttributeSelection(selection[eventTimeContentAttributeId]);
    if (timeFilter == Event2TimeFilter.customRange) {
      Map<String, dynamic>? customData = contentAttributes?.findAttribute(id: eventTimeContentAttributeId)?.findValue(value: Event2TimeFilter.customRange)?.customData;
      customStartTime = Event2TimeRangePanel.getStartTime(customData);
      customEndTime = Event2TimeRangePanel.getEndTime(customData);
    }

    List<Event2TypeFilter>? typesList = ListUtils.combine([
      Event2TypeFilterListImpl.fromAttributeSelection(selection[eventDetailsContentAttributeId]),
      Event2TypeFilterListImpl.fromAttributeSelection(selection[eventLimitsContentAttributeId]),
    ]);

    Map<String, dynamic> attributes = Map<String, dynamic>.from(selection);
    attributes.remove(eventTimeContentAttributeId);
    attributes.remove(eventDetailsContentAttributeId);
    attributes.remove(eventLimitsContentAttributeId);

    return Event2FilterParam(
      timeFilter: timeFilter,
      customStartTime: customStartTime,
      customEndTime: customEndTime,
      types: (typesList != null) ? LinkedHashSet<Event2TypeFilter>.from(typesList) : null,
      attributes: attributes
    );
  }

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

// Event2FilterParamUi

extension Event2FilterParamUi on Event2FilterParam {
  List<InlineSpan> buildDescription({ TextStyle? boldStyle, TextStyle? regularStyle}) {
    List<InlineSpan> descriptionList = <InlineSpan>[];
    boldStyle ??= Styles().textStyles.getTextStyle("widget.card.title.tiny.fat");
    regularStyle ??= Styles().textStyles.getTextStyle("widget.card.detail.small.regular");

    String? timeDescription = (timeFilter != Event2TimeFilter.customRange) ?
      event2TimeFilterToDisplayString(timeFilter) :
      event2TimeFilterDisplayInfo(Event2TimeFilter.customRange, customStartTime: customStartTime, customEndTime: customEndTime);

    if (timeDescription != null) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: ", " , style: regularStyle,));
      }
      descriptionList.add(TextSpan(text: timeDescription, style: regularStyle,),);
    }

    if (types != null) {
      for (Event2TypeFilter type in types!) {
        if (descriptionList.isNotEmpty) {
          descriptionList.add(TextSpan(text: ", " , style: regularStyle,));
        }
        descriptionList.add(TextSpan(text: event2TypeFilterToDisplayString(type), style: regularStyle,),);
      }
    }

    ContentAttributes? contentAttributes = Events2().contentAttributes;
    List<ContentAttribute>? attributesList = contentAttributes?.attributes;
    if ((attributes?.isNotEmpty == true) && (contentAttributes != null) && (attributesList != null)) {
      for (ContentAttribute attribute in attributesList) {
        List<String>? displayAttributeValues = attribute.displaySelectedLabelsFromSelection(attributes, complete: true);
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

    return descriptionList;
  }

  String get descriptionText {
      String descriptionText = "";

      String? timeDescription = (timeFilter != Event2TimeFilter.customRange) ?
      event2TimeFilterToDisplayString(timeFilter) :
      event2TimeFilterDisplayInfo(Event2TimeFilter.customRange, customStartTime: customStartTime, customEndTime: customEndTime);

      if (timeDescription != null) {
        if (StringUtils.isNotEmpty(descriptionText)) {
          descriptionText += ", ";
        }
        descriptionText += timeDescription;
      }

      if (types != null) {
        for (Event2TypeFilter type in types!) {
          if (StringUtils.isNotEmpty(descriptionText)) {
            descriptionText += ", ";
          }
          descriptionText += event2TypeFilterToDisplayString(type) ?? "";
        }
      }

      ContentAttributes? contentAttributes = Events2().contentAttributes;
      List<ContentAttribute>? attributesList = contentAttributes?.attributes;
      if ((attributes?.isNotEmpty == true) && (contentAttributes != null) && (attributesList != null)) {
        for (ContentAttribute attribute in attributesList) {
          List<String>? displayAttributeValues = attribute.displaySelectedLabelsFromSelection(attributes, complete: true);
          if ((displayAttributeValues != null) && displayAttributeValues.isNotEmpty) {
            for (String attributeValue in displayAttributeValues) {
              if (StringUtils.isNotEmpty(descriptionText)) {
                descriptionText += ", ";
              }
              descriptionText += attributeValue;
            }
          }
        }
      }
      return descriptionText;
  }
}

// Event2SortOrderImpl

extension Event2SortOrderImpl on Event2SortOrder {
  static Event2SortOrder? defaultFrom({Event2SortType? sortType, Event2TimeFilter? timeFilter}) =>
    (sortType != null) ? (((timeFilter == Event2TimeFilter.past) && (sortType == Event2SortType.dateTime)) ? Event2SortOrder.descending : Event2SortOrder.ascending) : null;
}

// Events2QueryImpl

extension Events2QueryImpl on Events2Query {
  static Events2Query fromFilterParam(Event2FilterParam filterParam, { int? offset, int? limit, List<Event2Grouping>? groupings, Event2SortType? sortType, Position? location }) =>
    Events2Query(
      offset: offset,
      limit: limit,
      timeFilter: filterParam.timeFilter,
      customStartTimeUtc: filterParam.customStartTime?.toUtc(),
      customEndTimeUtc: filterParam.customEndTime?.toUtc(),
      types: filterParam.types,
      groupings: groupings,
      attributes: filterParam.attributes,
      sortType: sortType,
      sortOrder: Event2SortOrderImpl.defaultFrom(sortType: sortType, timeFilter: filterParam.timeFilter),
      location: location,
    );
}

// _ContentAttributeValueImpl

extension _ContentAttributeValueImpl on ContentAttributeValue {
  String? get valueId {
    dynamic v = value;
    if (v is String) {
      return v;
    }
    else if (v is Event2TimeFilter) {
      return v.toJson();
    }
    else if (v is Event2TypeFilter) {
      return v.toJson();
    }
    else {
      return null;
    }
  }
}

class _AssistantPromptShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _AssistantPromptClipper().getClip(size);
    final shadowPaint = Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _AssistantPromptClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const radius = 12.0;
    const triangleHeight = 14.0;
    const triangleBase = 18.0;
    const triangleOffsetPercent = 0.82;

    final triangleLeftX = size.width * triangleOffsetPercent;
    final triangleRightX = triangleLeftX + triangleBase;
    final triangleTipX = triangleLeftX;
    final triangleTipY = size.height;
    final triangleBaseY = size.height - triangleHeight;

    final path = Path();

    // Start from top-left
    path.moveTo(radius, 0);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, triangleBaseY - radius);
    path.quadraticBezierTo(size.width, triangleBaseY, size.width - radius, triangleBaseY);

    // Line to before triangle
    path.lineTo(triangleRightX, triangleBaseY);

    // Triangle
    path.lineTo(triangleTipX, triangleTipY);
    path.lineTo(triangleLeftX, triangleBaseY);

    // Continue left
    path.lineTo(radius, triangleBaseY);
    path.quadraticBezierTo(0, triangleBaseY, 0, triangleBaseY - radius);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}