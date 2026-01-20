
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/ext/Dining.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Map2.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/dining/DiningCard.dart';
import 'package:illinois/ui/dining/HorizontalDiningSpecials.dart';
import 'package:illinois/ui/explore/ExploreDiningDetailPanel.dart';
import 'package:illinois/ui/map2/Map2HomeExts.dart';
import 'package:illinois/ui/map2/Map2HomePanel.dart';
import 'package:illinois/ui/map2/Map2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/QrCodePanel.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Dining2HomePanel extends StatefulWidget with AnalyticsInfo {
  final Dining2Filter? filter;
  final AnalyticsFeature? analyticsFeature; //This overrides AnalyticsInfo.analyticsFeature getter

  Dining2HomePanel({super.key, this.filter, this.analyticsFeature});

  @override
  State<StatefulWidget> createState() => _Dining2HomePanelState();
}

class _Dining2HomePanelState extends State<Dining2HomePanel> with NotificationsListener {

  // Data
  List<Dining>? _dinings;
  List<DiningSpecial>? _diningSpecials;
  List<Dining>? _displayDinings;
  Dining2Progress? _diningsProgress;

  // Filters
  PaymentType? _paymentType;
  late String _searchText;
  late bool _openNow;
  late bool _starred;
  late Dining2SortType _sortType;
  late Dining2SortOrder _sortOrder;

  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchTextNode = FocusNode();
  final GlobalKey _sortButtonKey = GlobalKey();
  final GlobalKey _paymentTypesButtonKey = GlobalKey();

  bool _searchOn = false;
  double? _sortDropdownWidth;
  double? _paymentTypesDropdownWidth;

  Position? _currentLocation;
  LocationServicesStatus? _locationServicesStatus;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      LocationServices.notifyStatusChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);

    _currentFilter = widget.filter ?? _storedFilter ?? Dining2Filter();

    _initDiningData();

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _searchTextController.dispose();
    _searchTextNode.dispose();
    super.dispose();
  }

  @override
  void onNotification(String name, dynamic param) {

    if (name == FlexUI.notifyChanged) {
      _updateLocationServicesStatus();
    }
    else if (name == LocationServices.notifyStatusChanged) {
      _updateLocationServicesStatus(status: param);
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      //setStateIfMounted();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HeaderBar(title: Localization().getStringEx('panel.dining2.header.title', 'Residence Hall Dining'),),
    body: _scaffoldContent,
    backgroundColor: Styles().colors.background,
    bottomNavigationBar: uiuc.TabBar()
  );

  Widget get _scaffoldContent => (_diningsProgress == Dining2Progress.init) ? _loadingContent :
    RefreshIndicator(onRefresh: _refreshDiningData, child: _panelContent,);

  Widget get _panelContent {
    if (_dinings == null) {
      return _errorContent;
    } else if (_dinings?.isNotEmpty != true) {
      return _emptyContent;
    } else {
      return _bodyContent;
    }
  }
  
  Widget get _bodyContent => Column(children: [
    _filtersBar,
    Expanded(child: _diningsContent)
  ],);


  Widget get _filtersBar =>
    Container(decoration: _filterBarDecoration, child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: _searchOn ? <Widget>[
        _filterSearchBar,
      ] : <Widget>[
        _filterButtonsBar,
        _filterDescriptionBar ?? Container(),
      ],),
    );

  BoxDecoration get _filterBarDecoration => BoxDecoration(
    color: Styles().colors.background,
    border: Border(bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1),),
    boxShadow: [BoxShadow(color: Styles().colors.dropShadow, spreadRadius: 1, blurRadius: 3, offset: Offset(1, 1) )],
  );

  // Filter Buttons Bar

  Widget get _filterButtonsBar => Container(decoration: _buttonsBarDecoration, padding: _buttonsBarPadding, constraints: _buttonsBarConstraints, child:
    SingleChildScrollView(scrollDirection: Axis.horizontal, child:
      Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Padding(padding: _filterButtonsFirstPadding, child:
          _searchFilterButton,
        ),
        Padding(padding: _filterButtonsPadding, child:
          _starredFilterButton,
        ),
        Padding(padding: _filterButtonsPadding, child:
          _openNowFilterButton,
        ),
        Padding(padding: _filterButtonsPadding, child:
          _paymentTypesFilterButton,
        ),
        Padding(padding: _filterButtonsLastPadding, child:
          _sortFilterButton,
        ),
      ],)
    )
  );

  BoxDecoration get _buttonsBarDecoration => BoxDecoration(border:
    Border(top: BorderSide(color: Styles().colors.surfaceAccent, width: 1),),
  );

  static const EdgeInsetsGeometry _buttonsBarPadding = EdgeInsets.symmetric(vertical: 8);
  static const BoxConstraints _buttonsBarConstraints = BoxConstraints(minWidth: double.infinity);

  static const EdgeInsetsGeometry _filterButtonsPadding = EdgeInsets.only(right: 6);
  static const EdgeInsetsGeometry _filterButtonsFirstPadding = EdgeInsets.only(left: 16, right: 6);
  static const EdgeInsetsGeometry _filterButtonsLastPadding = EdgeInsets.only(right: 16);

  TextStyle? get _dropdownEntryNormalTextStyle => Styles().textStyles.getTextStyle("widget.message.regular");
  TextStyle? get _dropdownEntrySelectedTextStyle => Styles().textStyles.getTextStyle("widget.message.regular.fat");

  // Search Filter Button

  Widget get _searchFilterButton =>
    Map2FilterImageButton(
      image: Styles().images.getImage('search'),
      label: Localization().getStringEx('panel.dining2.filter.button.search.title', 'Search'),
      hint: Localization().getStringEx('panel.dining2.filter.button.search.hint', 'Type a search dining locations'),
      onTap: _onTapSearch,
    );

  void _onTapSearch() {
    Analytics().logSelect(target: 'Search');
    setStateIfMounted((){
      _searchOn = true;
      _searchTextController.text = _searchText;
    });
  }

  void _onSearchTextChanged(String text) {
  }

  void _onTapCancelSearchText() {
    if (_searchTextController.text.isNotEmpty) {
      Analytics().logSelect(target: 'Search: Clear');
      _searchTextController.text = '';
    }
    else {
      Analytics().logSelect(target: 'Search: Cancel');
      setStateIfMounted((){
        _searchText = '';
        _searchOn = false;
      });
      _onFiltersChanged();
    }
  }

  void _onTapSearchText() {
    Analytics().logSelect(target: 'Search: Do');
    setStateIfMounted((){
      _searchText = _searchTextController.text;
      _searchTextController.text = '';
      _searchOn = false;
    });
    _onFiltersChanged();
  }

  Widget get _starredFilterButton =>
    Map2FilterTextButton(
      title: Localization().getStringEx('panel.dining2.filter.button.starred.title', 'Starred'),
      hint: Localization().getStringEx('panel.dining2.filter.button.starred.hint', 'Tap to show only starred dining locations'),
      leftIcon: Styles().images.getImage('star-filled', size: 16),
      toggled: _starred == true,
      onTap: _onStarred,
    );

  void _onStarred() {
    Analytics().logSelect(target: 'Starred');
    setStateIfMounted((){
      _starred = (_starred != true);
    });
    _onFiltersChanged();
  }

  Widget get _openNowFilterButton =>
    Map2FilterTextButton(
      title: Localization().getStringEx('panel.dining2.filter.button.open_now.title', 'Open Now'),
      hint: Localization().getStringEx('panel.dining2.filter.button.open_now.hint', 'Tap to show only currently opened dining locations'),
      toggled: _openNow == true,
      onTap: _onTapOpenNow,
    );

  void _onTapOpenNow() {
    Analytics().logSelect(target: 'Open Now');
    setStateIfMounted((){
      _openNow = (_openNow != true);
    });
    _onFiltersChanged();
  }

  Widget get _sortFilterButton =>
    MergeSemantics(key: _sortButtonKey, child:
      Semantics(value: _sortType.displayTitle, child:
        DropdownButtonHideUnderline(child:
          DropdownButton2<Pair<Dining2SortType, Dining2SortOrder>>(
            dropdownStyleData: DropdownStyleData(
              width:  _sortDropdownWidth ??= _evaluateSortDropdownWidth(),
              padding: EdgeInsets.zero
            ),
        customButton: Map2FilterTextButton(
          title: Localization().getStringEx('panel.dining2.filter.button.sort.title', 'Sort'),
          hint: Localization().getStringEx('panel.dining2.filter.button.sort.hint', 'Tap to sort dining locations'),
          leftIcon: Styles().images.getImage('sort', size: 16),
          rightIcon: Styles().images.getImage('chevron-down'),
          //onTap: _onSort,
        ),
        isExpanded: false,
        items: _buildSortDropdownItems(),
        onChanged: _onSelectSortType,
      )
    )),
  );

  List<DropdownMenuItem<Pair<Dining2SortType, Dining2SortOrder>>> _buildSortDropdownItems() {
    bool isProximityAvailable = ((_locationServicesStatus == LocationServicesStatus.permissionAllowed) || (_locationServicesStatus == LocationServicesStatus.permissionNotDetermined));
    List<DropdownMenuItem<Pair<Dining2SortType, Dining2SortOrder>>> items = <DropdownMenuItem<Pair<Dining2SortType, Dining2SortOrder>>>[];
    for (Dining2SortType sortType in Dining2SortType.values) {
      if ((sortType != Dining2SortType.proximity) || isProximityAvailable) {
        for (Dining2SortOrder sortOrder in Dining2SortOrder.values) {
          if (sortType.isDropdownListEntry(sortOrder)) {
            String itemText = sortType.displayTitleEx(sortOrder);
            TextStyle? itemTextStyle = ((_sortType == sortType) && (_sortOrder == sortOrder)) ?
              _dropdownEntrySelectedTextStyle : _dropdownEntryNormalTextStyle;
            items.add(AccessibleDropDownMenuItem<Pair<Dining2SortType, Dining2SortOrder>>(key: ObjectKey(Pair(sortType, sortOrder)), value: Pair(sortType, sortOrder), child:
              Semantics(label: sortType.displayTitle, button: true, container: true, inMutuallyExclusiveGroup: true, child:
                Row(children: [
                  Expanded(child:
                    Text(itemText, overflow: TextOverflow.ellipsis, semanticsLabel: '', style: itemTextStyle,)
                  ),
                ],)
              )
            ));
          }
        }
      }
    }
    return items;
  }

  double _evaluateSortDropdownWidth() {
    double width = 0;
    for (Dining2SortType sortType in Dining2SortType.values) {
      for (Dining2SortOrder sortOrder in Dining2SortOrder.values) {
        if (sortType.isDropdownListEntry(sortOrder)) {
          final Size sizeFull = (TextPainter(
              text: TextSpan(
                text: sortType.displayTitleEx(sortOrder),
                style: _dropdownEntrySelectedTextStyle,
              ),
              textScaler: MediaQuery.of(context).textScaler,
              textDirection: TextDirection.ltr,
            )..layout()).size;
          if (width < sizeFull.width) {
            width = sizeFull.width;
          }
        }
      }
    }
    return math.min(width + 2 * 18, MediaQuery.of(context).size.width / 2); // add horizontal padding
  }

  void _onSelectSortType(Pair<Dining2SortType, Dining2SortOrder>? value) {
    Analytics().logSelect(target: 'Sort: ${value?.left.displayTitle} ${value?.right.displayTitle}');
    if (value != null) {
      setStateIfMounted(() {
        _sortType = value.left;
        _sortOrder = value.right;
      });
      _onFiltersChanged();
      Future.delayed(Duration(seconds: Platform.isIOS ? 1 : 0), () =>
        AppSemantics.triggerAccessibilityFocus(_sortButtonKey)
      );
    }
  }

  Widget get _paymentTypesFilterButton =>
    MergeSemantics(key: _paymentTypesButtonKey, child:
      Semantics(value: _paymentType?.displayTitle ?? PaymentTypeUtils.displayTitleAll, child:
        DropdownButtonHideUnderline(child:
          DropdownButton2<PaymentType>(
            dropdownStyleData: DropdownStyleData(
              width:  _paymentTypesDropdownWidth ??= _evaluatePaymentTypesDropdownWidth(),
              padding: EdgeInsets.zero
            ),
        customButton: Map2FilterTextButton(
          title: _paymentType?.displayTitle ?? PaymentTypeUtils.displayTitleAll,
          hint: Localization().getStringEx('panel.dining2.filter.button.payment_type.hint', 'Tap to select a payment type'),
          rightIcon: Styles().images.getImage('chevron-down'),
          //onTap: _onPaymentType,
        ),
        isExpanded: false,
        items: _buildPaymentTypesDropdownItems(),
        onChanged: _onSelectPaymentType,
      )
    )),
  );

  List<DropdownMenuItem<PaymentType>> _buildPaymentTypesDropdownItems() => [
    _buildPaymentTypesDropdownItem(null),
    ...PaymentType.values.map((paymentType) => _buildPaymentTypesDropdownItem(paymentType)),
  ];

  DropdownMenuItem<PaymentType> _buildPaymentTypesDropdownItem(PaymentType? paymentType) {
    String itemTitle = paymentType?.displayTitle ?? PaymentTypeUtils.displayTitleAll;
    TextStyle? itemTextStyle = (paymentType == _paymentType) ? _dropdownEntrySelectedTextStyle : _dropdownEntryNormalTextStyle;
    Widget? itemIcon = (paymentType == _paymentType) ? Styles().images.getImage('check', size: 18, color: Styles().colors.fillColorPrimary) : null;
    return AccessibleDropDownMenuItem<PaymentType>(key: ObjectKey(paymentType), value: paymentType, child:
      Semantics(label: itemTitle, button: true, container: true, inMutuallyExclusiveGroup: true, child:
        Row(children: [
          Expanded(child:
            Text(itemTitle, overflow: TextOverflow.ellipsis, semanticsLabel: '', style: itemTextStyle,),
          ),
          if (itemIcon != null)
            Padding(padding: EdgeInsets.only(left: 4), child: itemIcon,) ,
        ],)
      )
    );
  }

  double _evaluatePaymentTypesDropdownWidth() {
    double width = _evaluatePaymentTypeDropdownWidth(null);
    for (PaymentType paymentType in PaymentType.values) {
      final double itemWidth = _evaluatePaymentTypeDropdownWidth(paymentType);
      if (width < itemWidth) {
        width = itemWidth;
      }
    }
    return math.min(width + 3 * 18 + 4, MediaQuery.of(context).size.width * 2 / 3); // add horizontal padding
  }

  double _evaluatePaymentTypeDropdownWidth(PaymentType? paymentType) => (
    TextPainter(
      text: TextSpan(
        text: paymentType?.displayTitle ?? PaymentTypeUtils.displayTitleAll,
        style: _dropdownEntrySelectedTextStyle,
      ),
      textScaler: MediaQuery.of(context).textScaler,
      textDirection: TextDirection.ltr,
    )..layout()
  ).size.width;

  void _onSelectPaymentType(PaymentType? value) {
    Analytics().logSelect(target: 'Payment Type: ${value?.displayTitle}');
    setStateIfMounted(() {
      _paymentType = value; // (_paymentType != value) ? value : null;
    });
    _onFiltersChanged();
    Future.delayed(Duration(seconds: Platform.isIOS ? 1 : 0), () =>
      AppSemantics.triggerAccessibilityFocus(_paymentTypesButtonKey)
    );

  }

  // Filter Search Bar

  Widget get _filterSearchBar =>
    Container(padding: EdgeInsets.only(left: 16), child:
      Row(children: <Widget>[
        Expanded(child:
          _searchTextField,
        ),
        Map2PlainImageButton(
          imageKey: 'search',
          label: Localization().getStringEx('panel.search.button.search.title', 'Search'),
          hint: Localization().getStringEx('panel.search.button.search.hint', ''),
          onTap: _onTapSearchText,
        ),
        Map2PlainImageButton(
          imageKey: 'close',
          label: Localization().getStringEx('panel.search.button.clear.title', 'Clear'),
          hint: Localization().getStringEx('panel.search.button.clear.hint', ''),
          onTap: _onTapCancelSearchText,
        ),
      ],),
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
      onSubmitted: (_) => _onTapSearchText(),
      autofocus: true,
      cursorColor: Styles().colors.fillColorSecondary,
      keyboardType: TextInputType.text,
      style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
      decoration: InputDecoration(
        border: InputBorder.none,
      ),
    ),
  );

  // Filter Description Bar

  Widget? get _filterDescriptionBar {
    List<InlineSpan> spansList = _filterDescriptionSpans;
    return spansList.isNotEmpty ? Semantics(container: true, child:
        Container(decoration: _filterDescriptionBarDecoration, padding: _filterDescriptionBarPadding, constraints: _buttonsBarConstraints, child:
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child:
              IndexedSemantics(index: 1, child: Semantics( container: true, child:
                Padding(padding: EdgeInsets.only(top: 6, bottom: 6), child:
                  RichText(text: TextSpan(style: _filterDescriptionRegularStyle, children: spansList)),
                ),
              ))
            ),
            IndexedSemantics(index: 2, child: Semantics( container: true, child:
              Map2PlainImageButton(imageKey: 'share-nodes',
                label: Localization().getStringEx('panel.dining2.button.share.title', 'Share'),
                hint: Localization().getStringEx('panel.dining2.button.share.hint', 'Tap to share dining locations'),
                padding: EdgeInsets.only(left: 6, right: 6, top: 12, bottom: 12),
                onTap: _onTapShareFilter,
              )
            )),
            IndexedSemantics(index: 3, child: Semantics( container: true, child:
              Map2PlainImageButton(imageKey: 'location-outline',
                label: Localization().getStringEx('panel.dining2.button.map.title', 'Map'),
                hint: Localization().getStringEx('panel.dining2.button.map.hint', 'Show dining locations on map'),
                padding: EdgeInsets.only(left: 6, right: 6, top: 12, bottom: 12),
                onTap: _onTapMapFilter,
              )
            )),
            IndexedSemantics(index: 4, child: Semantics( container: true, child:
              Map2PlainImageButton(imageKey: 'close',
                  label: Localization().getStringEx('panel.dining2.button.clear.title', 'Clear'),
                  hint: Localization().getStringEx('panel.dining2.button.clear.hint', 'Tap to clear current filters'),
                padding: EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 12),
                onTap: _onTapClearFilter,
              ),
            ))
          ]),
        )
      ) : null;
  }

  List<InlineSpan> get _filterDescriptionSpans {
    List<InlineSpan> descriptionList = <InlineSpan>[];
    LinkedHashMap<String, List<String>> descriptionMap = _currentFilter.description(dinings: _displayDinings);
    descriptionMap.forEach((String descriptionCategory, List<String> descriptionItems){
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: '; ', style: _filterDescriptionRegularStyle,),);
      }
      if (descriptionItems.isEmpty) {
        descriptionList.add(TextSpan(text: descriptionCategory, style: _filterDescriptionBoldStyle,));
      } else {
        descriptionList.add(TextSpan(text: "$descriptionCategory: " , style: _filterDescriptionBoldStyle,));
        descriptionList.add(TextSpan(text: descriptionItems.join(', '), style: _filterDescriptionRegularStyle,),);
      }
    });
    return descriptionList;
  }

  void _onTapMapFilter() {
    Analytics().logSelect(target: "Filter: Map");
    NotificationService().notify(Map2.notifySelect, _currentFilter.map2FilterParam);
  }

  void _onTapShareFilter() {
    Analytics().logSelect(target: "Filter: Share");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => QrCodePanel.fromDiningFilterParam(_currentFilter, analyticsFeature: widget.analyticsFeature,)));
  }

  void _onTapClearFilter() {
    Analytics().logSelect(target: "Filter: Clear");
    setState(() {
      _currentFilter = Dining2Filter();
    });
    _onFiltersChanged();
  }

  BoxDecoration get _filterDescriptionBarDecoration => BoxDecoration(
    border: Border(top: BorderSide(color: Styles().colors.surfaceAccent, width: 1),),
  );

  static const EdgeInsetsGeometry _filterDescriptionBarPadding = EdgeInsets.only(left: 16, right: 8);

  TextStyle? get _filterDescriptionBoldStyle => Styles().textStyles.getTextStyle('widget.card.title.tiny.fat');
  TextStyle? get _filterDescriptionRegularStyle => Styles().textStyles.getTextStyle('widget.card.detail.small.regular');

  Widget get _diningsContent => (_displayDinings?.isNotEmpty == true) ?
    _diningsListContent : _emptyFiltersContent;

  Widget get _diningsListContent => ListView.builder(
    itemCount: _diningsListItemsCount,
    itemBuilder: _diningsListItem,
  );

  int get _diningsListItemsCount => _displayDiningsCount + _diningSpecialsCount;
  int get _displayDiningsCount => _displayDinings?.length ?? 0;
  int get _diningSpecialsCount => (_diningSpecials?.isNotEmpty == true) ? 1 : 0;

  Widget _diningsListItem(BuildContext context, int index) {
    if (0 < _diningSpecialsCount) {
      if (index == 0) {
        return Padding(padding: _cardPadding, child:
          HorizontalDiningSpecials(specials: _diningSpecials,)
        );
      }
      else {
        index -= 1;
      }
    }
    Dining? dining = ListUtils.entry(_displayDinings, index);
    EdgeInsets cardPadding = ((index + 1) < _displayDiningsCount) ? _cardPadding : _lastCardPadding;
    return (dining != null) ? Padding(padding: cardPadding, child:
      DiningCard(dining,
        currentLocation: _currentLocation,
        onTap: (_) => _onTapDining(dining)
      )
    ) : Container();
  }

  void _onTapDining(Dining dining) {
    Analytics().logSelect(target: dining.title);
    Navigator.push(context, CupertinoPageRoute(builder: (context) =>
      ExploreDiningDetailPanel(dining, analyticsFeature: widget.analyticsFeature,)
    ));
  }

  static const EdgeInsets _cardPadding = EdgeInsets.only(left: 16, right: 16, top: 12);
  static const EdgeInsets _lastCardPadding = EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12);

  Widget get _loadingContent => Center(child:
    SizedBox(width: 32, height: 32, child:
      CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
    )
  );

  Widget get _errorContent => _statusContent(Localization().getStringEx('panel.dining2.status.failed.title', 'Failed to load Residence Hall dining locations.'));
  Widget get _emptyContent => _statusContent(Localization().getStringEx('panel.dining2.status.empty.title', 'There are no Residence Hall dining locations available right now.'));
  Widget get _emptyFiltersContent => _statusContent(Localization().getStringEx('panel.dining2.status.filter.empty.title', 'There are no Residence Hall dining locations matching selected criteria'));

  static const double _statusPadding = 48;
  Widget _statusContent(String status, { double hPadding = _statusPadding, double vPadding = 4 * _statusPadding }) =>
    SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child:
      Padding(padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding), child:
        Text(status, style: Styles().textStyles.getTextStyle("widget.message.regular.fat"), textAlign: TextAlign.center,)
      )
    );

  // Filters

  Dining2Filter get _currentFilter => Dining2Filter(
    searchText: _searchText,
    paymentType: _paymentType,
    openNow: _openNow,
    starred: _starred,
    sortType: _sortType,
    sortOrder: _sortOrder,
  );

  set _currentFilter(Dining2Filter value) {
    _searchText = value.searchText;
    _paymentType = value.paymentType;
    _openNow = value.openNow;
    _starred = value.starred;
    _sortType = value.sortType;
    _sortOrder = value.sortOrder;
  }

  Dining2Filter? get _storedFilter =>
    Dining2Filter.fromJson(JsonUtils.decodeMap(Storage().diningFilter));

  set _storedFilter(Dining2Filter? value) =>
    Storage().diningFilter = JsonUtils.encode(value?.toJson());

  void _storeCurrentFilter() =>
    _storedFilter =  Dining2Filter.fromOther(_currentFilter, searchText: '');

  void _onFiltersChanged() {
    _storeCurrentFilter();
    setStateIfMounted((){
      _displayDinings = _currentFilter.build(_dinings, position: _currentLocation);
    });
  }

  // Dining Data

  Future<void> _initDiningData() async {
    if (_diningsProgress != Dining2Progress.init) {
      setState(() {
        _diningsProgress = Dining2Progress.init;
      });
      List<dynamic> results = await Future.wait(<Future<dynamic>>[
        Dinings().loadDinings(),
        Dinings().loadDiningSpecials(),
        _updateLocationServicesStatus(updateDisplayDinings: false),
      ]);
      if (mounted) {
        List<Dining>? dinings = JsonUtils.cast(ListUtils.entry<dynamic>(results, 0));
        List<DiningSpecial>? diningSpecials = JsonUtils.cast(ListUtils.entry<dynamic>(results, 1));
        setState(() {
          _dinings = dinings;
          _diningSpecials = diningSpecials;
          _displayDinings = _currentFilter.build(dinings, position: _currentLocation);
          _diningsProgress = null;
        });
      }
    }
  }

  Future<void> _refreshDiningData() async {
    if (_diningsProgress == null) {
      setState(() {
        _diningsProgress = Dining2Progress.update;
      });
      List<dynamic> results = await Future.wait(<Future<dynamic>>[
        Dinings().loadDinings(),
        Dinings().loadDiningSpecials(),
        _updateLocationServicesStatus(updateDisplayDinings: false),
      ]);
      if (mounted && (_diningsProgress == Dining2Progress.update)) {
        List<Dining>? dinings = JsonUtils.cast(ListUtils.entry<dynamic>(results, 0));
        List<DiningSpecial>? diningSpecials = JsonUtils.cast(ListUtils.entry<dynamic>(results, 1));
        setState(() {
          if (dinings != null) {
            _dinings = dinings;
            _displayDinings = _currentFilter.build(dinings, position: _currentLocation);
          }
          if (diningSpecials != null) {
            _diningSpecials = diningSpecials;
          }
          _diningsProgress = null;
        });
      }
    }
  }

  // Locaction Services

  Future<void> _updateLocationServicesStatus({ LocationServicesStatus? status, bool forcePositionUpdate = false, bool updateDisplayDinings = true }) async {
    status ??= FlexUI().isLocationServicesAvailable ? await LocationServices().status : LocationServicesStatus.serviceDisabled;
    if (mounted) {
      if ((status != null) && (status != _locationServicesStatus)) {
        setState(() {
          _locationServicesStatus = status;
        });
        await _updateLocationPosition(updateDisplayDinings: true);
      }
      else if (forcePositionUpdate) {
        await _updateLocationPosition(updateDisplayDinings: true);
      }
    }
  }

  Future<void> _updateLocationPosition({ bool updateDisplayDinings = true }) async {
    if (_locationServicesStatus == LocationServicesStatus.permissionAllowed) {
      Position? currentLocation = await LocationServices().location;
      if ((currentLocation != null) && (currentLocation != _currentLocation) && mounted) {
        setState(() {
          _currentLocation = currentLocation;
          if ((_sortType == Dining2SortType.proximity) && updateDisplayDinings) {
            _displayDinings = _currentFilter.build(_dinings, position: _currentLocation);
          }
        });
      }
    }
  }

}

enum Dining2Progress { init, update }
enum Dining2SortType { alphabetical, proximity }
enum Dining2SortOrder { ascending, descending }

class Dining2Filter {
  final PaymentType? paymentType;
  final String searchText;
  final bool openNow;
  final bool starred;

  final Dining2SortType sortType;
  final Dining2SortOrder sortOrder;

  static const Dining2SortType defaultSortType = Dining2SortType.alphabetical;
  static const Dining2SortOrder defaultSortOrder = Dining2SortOrder.ascending;

  const Dining2Filter({
    this.paymentType,
    this.searchText = '',
    this.openNow = false,
    this.starred = false,
    this.sortType = defaultSortType,
    this.sortOrder = defaultSortOrder,
  });

  factory Dining2Filter.fromOther(Dining2Filter other, {
    PaymentType? paymentType, String? searchText,
    bool? openNow, bool? starred,
    Dining2SortType? sortType, Dining2SortOrder? sortOrder,
  }) => Dining2Filter(
      paymentType: paymentType ?? other.paymentType,
      searchText: searchText ?? other.searchText,
      openNow: openNow ?? other.openNow,
      starred: starred ?? other.starred,
      sortType: sortType ?? other.sortType,
      sortOrder: sortOrder ?? other.sortOrder,
  );

  // Json Serialization
  static Dining2Filter? fromJson(Map<String, dynamic>? json) => (json != null) ? Dining2Filter(
    paymentType: PaymentTypeImpl.fromJson(JsonUtils.stringValue(json['paymentType'])),
    searchText: JsonUtils.stringValue(json['searchText']) ?? '',
    openNow: JsonUtils.boolValue(json['openNow']) ?? false,
    starred: JsonUtils.boolValue(json['starred']) ?? false,
    sortType: Dining2SortTypeImpl.fromJson(JsonUtils.stringValue(json['sortType'])) ?? defaultSortType,
    sortOrder: Dining2SortOrderImpl.fromJson(JsonUtils.stringValue(json['sortOrder'])) ?? defaultSortOrder,
  ) : null;

  toJson() => {
    'paymentType': paymentType?.toJson(),
    'searchText': searchText,
    'openNow': openNow,
    'starred': starred,
    'sortType': sortType.toJson(),
    'sortOrder': sortOrder.toJson(),
  };

  // Uri

  factory Dining2Filter.fromUriParams(Map<String, String> uriParams) {
    return Dining2Filter(
      paymentType: PaymentTypeImpl.fromJson(uriParams['payment_type']),
      searchText: uriParams['search_text'] ?? '',
      openNow: JsonUtils.cast(JsonUtils.decode(uriParams['open_now'])) ?? false,
      starred: JsonUtils.cast(JsonUtils.decode(uriParams['starred'])) ?? false,
      sortType: Dining2SortTypeImpl.fromJson(uriParams['sort_type']) ?? defaultSortType,
      sortOrder: Dining2SortOrderImpl.fromJson(uriParams['sort_order']) ?? defaultSortOrder,
    );
  }

  Map<String, String> toUriParams() {
    Map <String, String> uriParams = <String, String>{};
    MapUtils.add(uriParams, 'payment_type', paymentType?.toJson());
    MapUtils.add(uriParams, 'search_text', searchText.isNotEmpty ? searchText : null);
    MapUtils.add(uriParams, 'open_now', openNow ? JsonUtils.encode(openNow) : null);
    MapUtils.add(uriParams, 'starred', starred ? JsonUtils.encode(starred) : null);
    MapUtils.add(uriParams, 'sort_type', (sortType != defaultSortType) ? sortType.toJson() : null);
    MapUtils.add(uriParams, 'sort_order', (sortOrder != defaultSortOrder) ? sortOrder.toJson() : null);
    return uriParams;
  }

  // Map2

  Map2FilterDiningsLocationsParam get map2FilterParam => Map2FilterDiningsLocationsParam(
    paymentType: paymentType, searchText: searchText,
    openNow: openNow, starred: starred,
    sortType: sortType.map2SortType,
    sortOrder: sortOrder.map2SortOrder,
  );

  // Content

  List<Dining>? build(List<Dining>? source, { Position? position }) {
    List<Dining>? result = _filter(source, searchLowerCaseText: searchText.toLowerCase());
    _sort(result, position: position);
    return result;
  }

  List<Dining>? _filter(List<Dining>? source, { String? searchLowerCaseText }) =>
    (source != null) ? List<Dining>.from(source.where((Dining dining) => (
      ((openNow != true) || dining.isOpen) &&
      ((starred != true) || dining.isStarred) &&
      ((paymentType == null) || (dining.paymentTypes?.contains(paymentType) == true)) &&
      ((searchLowerCaseText == null) || (searchLowerCaseText.isEmpty == true) || dining.matchSearchTextLowerCase(searchLowerCaseText))
    ))) : null;

  void _sort(List<Dining>? content, { Position? position }) {
    switch (sortType) {
      case Dining2SortType.alphabetical: _sortAlphabeticaly(content); break;
      case Dining2SortType.proximity: _sortByProximity(content, position: position); break;
    }
  }

  void _sortAlphabeticaly(List<Dining>? content) =>
      content?.sort((Dining dining1, Dining dining2) =>
      SortUtils.compare(dining1.title, dining2.title, descending: (sortOrder == Dining2SortOrder.descending))
    );

  void _sortByProximity(List<Dining>? content, { Position? position }) {
    content?.sort((Dining dining1, Dining dining2) {
      LatLng? location1 = dining1.exploreLocation?.exploreLocationMapCoordinate;
      double distance1 = ((location1 != null) && (position != null)) ? Geolocator.distanceBetween(location1.latitude, location1.longitude, position.latitude, position.longitude) : 0.0;

      LatLng? location2 = dining2.exploreLocation?.exploreLocationMapCoordinate;
      double distance2 = ((location2 != null) && (position != null)) ? Geolocator.distanceBetween(location2.latitude, location2.longitude, position.latitude, position.longitude) : 0.0;

      return (sortOrder == Dining2SortOrder.descending) ? distance2.compareTo(distance1) : distance1.compareTo(distance2); // SortUtils.compare(distance1, distance2);
    });
  }

  String get descriptionText {
    String descriptionText = '';
    description().forEach((String descriptionCategory, List<String> descriptionItems){
      if (descriptionText.isNotEmpty) {
        descriptionText += '; ';
      }
      if (descriptionItems.isEmpty) {
        descriptionText += descriptionCategory;
      } else {
        descriptionText += "$descriptionCategory: ";
        descriptionText += descriptionItems.join(', ');
      }
    });
    return descriptionText;
  }

  LinkedHashMap<String, List<String>> description({List<Dining>? dinings}) {
    LinkedHashMap<String, List<String>> descriptionMap = LinkedHashMap<String, List<String>>();
    if (searchText.isNotEmpty) {
      String searchKey = Localization().getStringEx('panel.dining2.filter.description.search.text', 'Search');
      descriptionMap[searchKey] = <String>[searchText];
    }
    if (paymentType != null) {
      String? paymentTypeValue = paymentType?.displayTitle;
      if ((paymentTypeValue != null) && paymentTypeValue.isNotEmpty) {
        String paymentTypeKey = Localization().getStringEx('panel.dining2.filter.description.payment_type.text', 'Payment Type');
        descriptionMap[paymentTypeKey] = <String>[paymentTypeValue];
      }
    }
    if (starred) {
      String starredKey = Localization().getStringEx('panel.dining2.filter.description.starred.text', 'Starred');
      descriptionMap[starredKey] = <String>[];
    }
    if (openNow) {
      String onlyOpenedKey = Localization().getStringEx('panel.dining2.filter.description.open_now.text', 'Open Now');
      descriptionMap[onlyOpenedKey] = <String>[];
    }
    if (descriptionMap.isNotEmpty) {
      String sortKey = Localization().getStringEx('panel.dining2.filter.description.sort.text', 'Sort');
      String sortValue = sortType.displayTitleEx(sortOrder);
      descriptionMap[sortKey] = <String>[sortValue];
    }
    if ((dinings != null) && descriptionMap.isNotEmpty)  {
      String diningsKey = Localization().getStringEx('panel.dining2.filter.description.dinings.text', 'Dining Locations');
      String diningsValue = dinings.length.toString();
      descriptionMap[diningsKey] = <String>[diningsValue];
    }
    return descriptionMap;
  }
}

extension Dining2SortTypeImpl on Dining2SortType {

  static Dining2SortType? fromJson(dynamic value) {
    switch (value) {
      case 'alphabetical': return Dining2SortType.alphabetical;
      case 'proximity': return Dining2SortType.proximity;
      default: return null;
    }
  }

  String toJson() {
    switch (this) {
      case Dining2SortType.alphabetical: return 'alphabetical';
      case Dining2SortType.proximity: return 'proximity';
    }
  }

  Map2SortType get map2SortType {
    switch (this) {
      case Dining2SortType.alphabetical: return Map2SortType.alphabetical;
      case Dining2SortType.proximity: return Map2SortType.proximity;
    }
  }

  String get displayTitle {
    switch (this) {
      case Dining2SortType.alphabetical: return Localization().getStringEx('model.map2.sort_type.alphabetical', 'Alphabetical');
      case Dining2SortType.proximity: return Localization().getStringEx('model.map2.sort_type.proximity', 'Proximity');
    }
  }

  String displayTitleEx(Dining2SortOrder sortOrder) {
    String? sortOrderIndicator = sortOrderDisplayAbbreviation(sortOrder);
    return (sortOrderIndicator != null) ? '$displayTitle $sortOrderIndicator' : displayTitle;
  }

  String? sortOrderDisplayAbbreviation(Dining2SortOrder sortOrder) => (this == Dining2SortType.alphabetical) ?
    sortOrder.displayAbbreviation : null;

  bool isDropdownListEntry(Dining2SortOrder sortOrder) {
    switch(this) {
      case Dining2SortType.alphabetical: return true;
      case Dining2SortType.proximity: return (sortOrder == Dining2SortOrder.ascending);
    }
  }

}

extension Dining2SortOrderImpl on Dining2SortOrder {

  static Dining2SortOrder? fromJson(dynamic value) {
    switch (value) {
      case 'ascending': return Dining2SortOrder.ascending;
      case 'descending': return Dining2SortOrder.descending;
      default: return null;
    }
  }

  String toJson() {
    switch (this) {
      case Dining2SortOrder.ascending: return 'ascending';
      case Dining2SortOrder.descending: return 'descending';
    }
  }

  Map2SortOrder get map2SortOrder {
    switch (this) {
      case Dining2SortOrder.ascending: return Map2SortOrder.ascending;
      case Dining2SortOrder.descending: return Map2SortOrder.descending;
    }
  }

  String get displayTitle {
    switch (this) {
      case Dining2SortOrder.ascending: return Localization().getStringEx('model.map2.sort_order.ascending', 'Ascending');
      case Dining2SortOrder.descending: return Localization().getStringEx('model.map2.sort_order.descending', 'Descending');
    }
  }

  String get displayAbbreviation {
    switch (this) {
      case Dining2SortOrder.ascending: return Localization().getStringEx('model.map2.sort_order.ascending.alphabetical.abbr', 'A-Z');
      case Dining2SortOrder.descending: return Localization().getStringEx('model.map2.sort_order.descending.alphabetical.abbr', 'Z-A');
    }
  }
}
