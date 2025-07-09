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

import 'package:flutter/semantics.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/ui/dining/DiningCard.dart';
import 'package:illinois/ui/explore/ExploreDiningDetailPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/widgets/Filters.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/dining/HorizontalDiningSpecials.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/model/Dining.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';


enum DiningFilterType { payment_type, work_time }

class _DiningSortKey extends OrdinalSortKey {
  const _DiningSortKey(double order) : super(order);

  static const _DiningSortKey filterLayout = _DiningSortKey(1.0);
  static const _DiningSortKey headerBar = _DiningSortKey(2.0);
}

class DiningHomePanel extends StatefulWidget with AnalyticsInfo {

  final DiningFilter? initialFilter;
  final AnalyticsFeature? analyticsFeature; //This overrides AnalyticsInfo.analyticsFeature getter

  DiningHomePanel({this.initialFilter, this.analyticsFeature });

  @override
  _DiningHomePanelState createState() => _DiningHomePanelState();
}

class _DiningHomePanelState extends State<DiningHomePanel> with NotificationsListener {
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(horizontal: 16);
  
  List<Dining>? _dinings;
  List<DiningSpecial>? _diningSpecials;
  List<String>?  _filterWorkTimeValues;
  List<String>?  _filterPaymentTypeValues;

  List<DiningFilter> _filters = <DiningFilter>[
    DiningFilter(type: DiningFilterType.work_time),
    DiningFilter(type: DiningFilterType.payment_type)
  ];
  bool _filterOptionsVisible = false;

  ScrollController _scrollController = ScrollController();

  Future<List<Dining>?>? _loadingTask;
  bool? _loadingProgress;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Storage.offsetDateKey,
      Storage.useDeviceLocalTimeZoneKey,
      Connectivity.notifyStatusChanged,
      Localization.notifyStringsUpdated,
      Auth2UserPrefs.notifyFavoritesChanged,
      MTD.notifyStopsChanged,
      Appointments.notifyUpcomingAppointmentsChanged,
      AppLivecycle.notifyStateChanged,
    ]);


    _initFilters();

    _loadingProgress = true;
    
    _loadDinings();

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: headerBarWidget,
        body: RefreshIndicator(
          onRefresh: () => _loadDinings(progress: false, updateOnly: true),
          child: _buildContent(),
        ),
        backgroundColor: Styles().colors.background,
        bottomNavigationBar: uiuc.TabBar());
  }

  bool get _hasDiningSpecials{
    return _diningSpecials != null && _diningSpecials!.isNotEmpty;
  }

  int get _diningsCount{
    int diningsCount = (_dinings != null) ? _dinings!.length : 0;

    if(_hasDiningSpecials){
      diningsCount++;
    }
    return diningsCount;
  }

  void _initFilters() {
    if (widget.initialFilter != null) {
        for (int index = 0; index < _filters.length; index++) {
          if (_filters[index].type == widget.initialFilter?.type) {
            _filters[index] = widget.initialFilter!;
          }
        }
    }

    _filterPaymentTypeValues = [
      Localization().getStringEx('panel.explore.filter.payment_types.all', 'All Payment Types')  
    ];
    for (PaymentType paymentType in PaymentType.values) {
      _filterPaymentTypeValues!.add(PaymentTypeHelper.paymentTypeToDisplayString(paymentType) ?? '');
    }

    _filterWorkTimeValues = [
      Localization().getStringEx('panel.explore.filter.worktimes.all', 'All Locations'),
      Localization().getStringEx('panel.explore.filter.worktimes.open_now', 'Open Now'),
    ];
  }

  Future<void> _loadDinings({bool? progress, bool updateOnly = false}) async {
    Future<List<Dining>?>? task = Connectivity().isNotOffline ? _loadRawDinings(_filters) :  null;

    if (task != null) {
      _refresh(() {
        _loadingTask = task;
        _loadingProgress = progress ?? !updateOnly;
      });
      
      List<Dining>? dinings = await task;

      if (_loadingTask == task) {
        if ((updateOnly == false) || ((dinings != null) && !DeepCollectionEquality().equals(dinings, _dinings))) {
          _applyDinings(dinings, updateOnly: updateOnly);
        }
        else {
          _refresh(() {
            _loadingTask = null;
            _loadingProgress = null;
          });
        }
      }
      else {
        // Do not do anything, _loadingTask will finish the loading.
      }
    }
    else if (updateOnly == false) {
      _applyDinings(null, updateOnly: updateOnly);
    }
  }


  void _applyDinings(List<Dining>? dinings, { bool updateOnly = false}) {
    _refresh(() {
      _loadingTask = null;
      _loadingProgress = null;
      _dinings = dinings;
    });
  }

  Future<List<Dining>?> _loadRawDinings(List<DiningFilter>? selectedFilterList) async {
    String? workTime = _getSelectedWorkTime(selectedFilterList);
    PaymentType? paymentType = _getSelectedPaymentType(selectedFilterList);
    bool onlyOpened = (CollectionUtils.isNotEmpty(_filterWorkTimeValues)) ? (_filterWorkTimeValues![1] == workTime) : false;

    _diningSpecials = await Dinings().loadDiningSpecials();
    return Dinings().loadBackendDinings(onlyOpened, paymentType, null);
  }

  String? _getSelectedWorkTime(List<DiningFilter>? selectedFilterList) {
    if (selectedFilterList == null || selectedFilterList.isEmpty) {
      return null;
    }
    for (DiningFilter selectedFilter in selectedFilterList) {
      if (selectedFilter.type == DiningFilterType.work_time) {
        int index = selectedFilter.firstSelectedIndex;
        return (_filterWorkTimeValues!.length > index)
            ? _filterWorkTimeValues![index]
            : null;
      }
    }
    return null;
  }

  PaymentType? _getSelectedPaymentType(List<DiningFilter>? selectedFilterList) {
    if (selectedFilterList == null || selectedFilterList.isEmpty) {
      return null;
    }
    for (DiningFilter selectedFilter in selectedFilterList) {
      if (selectedFilter.type == DiningFilterType.payment_type) {
        int index = selectedFilter.firstSelectedIndex;
        if (index == 0) {
          return null; //All payment types
        }
        return (_filterPaymentTypeValues!.length > index)
            ? PaymentType.values[index - 1]
            : null;
      }
    }
    return null;
  }

  List<String>? _getFilterValuesByType(DiningFilterType filterType) {
    switch (filterType) {
      case DiningFilterType.work_time:
        return _filterWorkTimeValues;
      case DiningFilterType.payment_type:
        return _filterPaymentTypeValues;
    }
  }

  String? _getFilterHintByType(DiningFilterType filterType) {
    switch (filterType) {
      case DiningFilterType.work_time:
        return Localization().getStringEx('panel.explore.filter.worktimes.hint', '');
      case DiningFilterType.payment_type:
        return Localization().getStringEx('panel.explore.filter.payment_types.hint', '');
    }
  }

  // Build UI

  PreferredSizeWidget get headerBarWidget {
    return HeaderBar(
      title: Localization().getStringEx('panel.explore.header.dining.title', 'Residence Hall Dining'),
      sortKey: _DiningSortKey.headerBar,
    );
  }

  Widget _buildContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Expanded(child:
        Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: EdgeInsets.only(left: 12, right: 12, bottom: 12), child:
              Wrap(children: _buildFilterWidgets()),
            ),
            Expanded(child:
              Container(color: Styles().colors.background, child:
                _buildListView(),
              ),
            ),
          ]),
          _buildFilterValuesContainer()
        ]),
      ),
    ]);
  }

  Widget _buildListView() {
    if (_loadingProgress == true) {
      return _buildLoading();
    }
    else if (Connectivity().isOffline) {
      return _buildOffline();
    }

    Widget diningsContent = (_diningsCount > 0) ?
      ListView.separated(
        separatorBuilder: (context, index) => Divider(color: Colors.transparent,),
        itemCount: _diningsCount,
        itemBuilder: _buildDiningEntry,
        controller: _scrollController,
      ) : _buildEmpty();

    return  Stack(children: [
      Container(color: Styles().colors.background, child: diningsContent),
      _buildDimmedContainer(),
    ]);
  }

  Widget _buildDiningEntry(BuildContext context, int index){
    if(_hasDiningSpecials) {
      if (index == 0) {
        return HorizontalDiningSpecials(specials: _diningSpecials,);
      }
    }

    int realIndex = _hasDiningSpecials ? index - 1 : index;
    Dining? dining = _dinings![realIndex];

    return Padding(padding: cardPadding, child:
      DiningCard(dining, onTap: (_) => _onTapDining(dining))
    );
  }

  Widget _buildLoading() {
    return Semantics(
      label: Localization().getStringEx('panel.explore.state.loading.title', 'Loading'),
      hint: Localization().getStringEx('panel.explore.state.loading.hint', 'Please wait'),
      excludeSemantics: true,
      child:Container(
        color: Styles().colors.background,
        child: Align(
          alignment: Alignment.center,
          child: CircularProgressIndicator(),
        ),
    ));
  }

  Widget _buildEmpty() {
    return SingleChildScrollView(child:
      Center(child:
        Column(children: <Widget>[
          Container(height: MediaQuery.of(context).size.height / 5),
          Text(Localization().getStringEx('panel.explore.state.online.empty.dining', 'No dining locations are currently open.'), textAlign: TextAlign.center,),
          Container(height: MediaQuery.of(context).size.height / 5 * 3),
        ]),
      ),
    );
  }

  Widget _buildOffline() {
    return SingleChildScrollView(child:
      Center(child:
        Column(children: <Widget>[
          Container(height: MediaQuery.of(context).size.height / 5),
          Text(Localization().getStringEx("common.message.offline", "You appear to be offline"), style: Styles().textStyles.getTextStyle("widget.message.regular")),
          Container(height: 8),
          Text(Localization().getStringEx('panel.explore.state.offline.empty.dining', 'No dining locations available while offline.')),
          Container(height: MediaQuery.of(context).size.height / 5 * 3),
        ],),),
    );
  }

  Widget _buildDimmedContainer() {
    return Visibility(visible: _filterOptionsVisible, child:
      BlockSemantics(child:
        Container(color: Color(0x99000000))
      )
    );
  }

  Widget _buildFilterValuesContainer() {
    DiningFilter? selectedFilter;
    for (DiningFilter filter in _filters) {
      if (filter.active) {
        selectedFilter = filter;
        break;
      }
    }
    if (selectedFilter == null) {
      return Container();
    }
    List<String> filterValues = _getFilterValuesByType(selectedFilter.type)!;
    return Semantics(sortKey: _DiningSortKey.filterLayout,
      child: Visibility(
        visible: _filterOptionsVisible,
        child: Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 36, bottom: 40),
          child: Semantics(child:Container(
            decoration: BoxDecoration(
              color: Styles().colors.fillColorSecondary,
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Container(
                color: Colors.white,
                child: ListView.separated(
                  shrinkWrap: true,
                  separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Styles().colors.fillColorPrimaryTransparent03,
                      ),
                  itemCount: filterValues.length,
                  itemBuilder: (context, index) {
                    return  FilterListItem(
                      title: filterValues[index],
                      selected: (selectedFilter?.selectedIndexes != null && selectedFilter!.selectedIndexes.contains(index)),
                      onTap: () {
                        Analytics().logSelect(target: "FilterItem: ${filterValues[index]}");
                        _onFilterValueClick(selectedFilter!, index);
                      },
                    );
                  },
                  controller: _scrollController,
                ),
              ),
            ),
          ))),
    ));
  }

  List<Widget> _buildFilterWidgets() {
    List<Widget> filterTypeWidgets = [];
    for (int i = 0; i < _filters.length; i++) {
      DiningFilter selectedFilter = _filters[i];
      // Do not show categories filter if selected category is athletics "Big 10 Athletics" (e.g only one selected index with value 2)
      List<String> filterValues = _getFilterValuesByType(selectedFilter.type)!;
      int filterValueIndex = selectedFilter.firstSelectedIndex;
      String? filterHeaderLabel = filterValues[filterValueIndex];
      filterTypeWidgets.add(FilterSelector(
        title: filterHeaderLabel,
        hint: _getFilterHintByType(selectedFilter.type),
        active: selectedFilter.active,
        onTap: (){
          Analytics().logSelect(target: "Filter: $filterHeaderLabel");
          return _onFilterTypeClicked(selectedFilter);},
      ));
    }
    return filterTypeWidgets;
  }

  //Click listeners

  void _onTapDining(Dining dining) {
    Analytics().logSelect(target: dining.title);
    Navigator.push(context, CupertinoPageRoute(builder: (context) =>
      ExploreDiningDetailPanel(dining: dining, analyticsFeature: widget.analyticsFeature,)
    ));
  }

  void _onFilterTypeClicked(DiningFilter selectedFilter) {
    // Analytics().logSelect(target:...);
    _refresh(() {
      for (DiningFilter filter in _filters) {
        if (filter != selectedFilter) {
          filter.active = false;
        }
      }
      selectedFilter.active = _filterOptionsVisible = !selectedFilter.active;
    });
  }

  void _onFilterValueClick(DiningFilter selectedFilter, int newValueIndex) {
    //Apply custom logic for selecting event categories.
    Set<int> selectedIndexes = Set.of(selectedFilter.selectedIndexes); //Copy
    
    // JP: Change category selection back to radio button only. Only one of the possibilities should be picked at a time. Sorry I asked for the change.
    selectedIndexes = {newValueIndex};
    /*if (selectedFilter.type == DiningFilterType.categories) {
      if (newValueIndex == 0) {
        selectedIndexes = {newValueIndex};
      } else {
        if (selectedIndexes.contains(newValueIndex)) {
          selectedIndexes.remove(newValueIndex);
          if (selectedIndexes.isEmpty) {
            selectedIndexes = {0}; //select All categories
          }
        } else {
          selectedIndexes.remove(0);
          selectedIndexes.add(newValueIndex);
        }
      }
    } else {
      selectedIndexes = {newValueIndex};
    }*/

    selectedFilter.selectedIndexes = selectedIndexes;
    selectedFilter.active = _filterOptionsVisible = false;

    _loadDinings();
  }

  void _refresh(void fn()){
    if(mounted) {
      this.setState(fn);
    }
  }

  // NotificationsListener
  
  @override
  void onNotification(String name, dynamic param) {
    if (name == Connectivity.notifyStatusChanged) {
      _loadDinings(updateOnly: true);
    }
    else if (name == Localization.notifyStringsUpdated) {
      _refresh(() { });
    }
    else if (name == Storage.offsetDateKey) {
      if (mounted) {
        _loadDinings(updateOnly: true);
      }
    }
    else if (name == Storage.useDeviceLocalTimeZoneKey) {
      if (mounted) {
        _loadDinings(updateOnly: true);
      }
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _onFavoritesChanged();
    }
  }

  void _onFavoritesChanged() {
    _refresh(() {});
  }
}

/////////////////////////
// ExploreOptionalMessagePopup

class ExploreOptionalMessagePopup extends StatefulWidget {
  final String message;
  final String? showPopupStorageKey;
  final bool Function(String url)? onTapUrl;
  ExploreOptionalMessagePopup({Key? key, required this.message, this.showPopupStorageKey, this.onTapUrl}) : super(key: key);

  @override
  State<ExploreOptionalMessagePopup> createState() => _MTDInstructionsPopupState();
}

class _MTDInstructionsPopupState extends State<ExploreOptionalMessagePopup> {
  bool? showInstructionsPopup;
  
  @override
  void initState() {
    showInstructionsPopup = (widget.showPopupStorageKey != null) ? Storage().getBoolWithName(widget.showPopupStorageKey!) : null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String dontShow = Localization().getStringEx("panel.explore.instructions.mtd.dont_show.msg", "Don't show me this again.");

    return AlertDialog(contentPadding: EdgeInsets.zero, content:
      Container(decoration: BoxDecoration(color: Styles().colors.white, borderRadius: BorderRadius.circular(10.0)), child:
        Stack(alignment: Alignment.center, children: [
          Padding(padding: EdgeInsets.only(top: 36, bottom: 9), child:
            Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(padding: EdgeInsets.symmetric(horizontal: 32), child:
                Column(children: [
                  Styles().images.getImage('university-logo', excludeFromSemantics: true) ?? Container(),
                  Padding(padding: EdgeInsets.only(top: 18), child:
                    //Text(widget.message, textAlign: TextAlign.left, style: Styles().textStyles.getTextStyle("widget.detail.small"))
                    HtmlWidget(widget.message,
                      onTapUrl: (url) => (widget.onTapUrl != null) ? widget.onTapUrl!(url) : false,
                      textStyle: Styles().textStyles.getTextStyle("widget.detail.small"),
                      customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null
                    )
                  )
                ]),
              ),

              Visibility(visible: (widget.showPopupStorageKey != null), child:
                Padding(padding: EdgeInsets.only(left: 16, right: 32), child:
                  Semantics(
                      label: dontShow,
                      value: showInstructionsPopup == false ?   Localization().getStringEx("toggle_button.status.checked", "checked",) : Localization().getStringEx("toggle_button.status.unchecked", "unchecked"),
                      button: true,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      InkWell(
                        onTap: (){
                          AppSemantics.announceCheckBoxStateChange(context,  /*reversed value*/!(showInstructionsPopup == false), dontShow);
                          _onDoNotShow();
                          },
                        child: Padding(padding: EdgeInsets.all(16), child:
                          Styles().images.getImage((showInstructionsPopup == false) ? "check-circle-filled" : "check-circle-outline-gray"),
                        ),
                      ),
                      Expanded(child:
                        Text(dontShow, style: Styles().textStyles.getTextStyle("widget.detail.small"), textAlign: TextAlign.left,semanticsLabel: "",)
                      ),
                  ])),
                ),
              ),
            ])
          ),
          Positioned.fill(child:
            Align(alignment: Alignment.topRight, child:
              Semantics(  button: true, label: "close",
              child: InkWell(onTap: () {
                Analytics().logSelect(target: 'Close MTD instructions popup');
                Navigator.of(context).pop();
                }, child:
                Padding(padding: EdgeInsets.all(16), child:
                  Styles().images.getImage('close-circle', excludeFromSemantics: true)
                )
              ))
            )
          ),
        ])
     )
    );
  }

  void _onDoNotShow() {
    setState(() {
      if (widget.showPopupStorageKey != null) {
        Storage().setBoolWithName(widget.showPopupStorageKey!, showInstructionsPopup = (showInstructionsPopup == false));
      }
    });  
  }
}


////////////////////
// DiningFilter

class DiningFilter {
  DiningFilterType type;
  Set<int> selectedIndexes;
  bool active;

  DiningFilter(
      {required this.type, this.selectedIndexes = const {0}, this.active = false});

  int get firstSelectedIndex {
    if (selectedIndexes.isEmpty) {
      return -1;
    }
    return selectedIndexes.first;
  }
}

