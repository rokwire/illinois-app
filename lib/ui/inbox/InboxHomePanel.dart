import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/FilterWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';

class InboxHomePanel extends StatefulWidget {
  InboxHomePanel();

  _InboxHomePanelState createState() => _InboxHomePanelState();
}

class _InboxHomePanelState extends State<InboxHomePanel> implements NotificationsListener {

  List<_FilterEntry> _types = [
    _FilterEntry(value: null, name: "Any Type"),
    _FilterEntry(value: "Admin"),
    _FilterEntry(value: "Academic"),
    _FilterEntry(value: "Athletics"),
    _FilterEntry(value: "Community"),
    _FilterEntry(value: "Entertainment"),
    _FilterEntry(value: "Recreation"),
    _FilterEntry(value: "Other"),
  ];

  List<_FilterEntry> _times = [
    _FilterEntry(name: "Any Time", value: null),
    _FilterEntry(name: "Today", value: _TimeFilter.Today),
    _FilterEntry(name: "Today and Yesterday", value: _TimeFilter.TodayAndYesterday),
    _FilterEntry(name: "This week", value: _TimeFilter.ThisWeek),
    _FilterEntry(name: "Last week", value: _TimeFilter.LastWeek),
    _FilterEntry(name: "This month", value: _TimeFilter.ThisMonth),
    _FilterEntry(name: "Last Month", value: _TimeFilter.LastMonth),
  ];

  String _selectedType;
  _TimeFilter _selectedTime;
  _FilterType _selectedFilter;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, []);
  }
  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx('panel.inbox.label.heading', 'Inbox'), style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold),),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          _buildFilters(),
          Expanded(child:
            _buildContent(),
          ),
          TabBarWidget(),
        ],),
      backgroundColor: Styles().colors.background,
    );
  }

  Widget _buildContent() {
    return Stack(children: [
      Padding(padding: EdgeInsets.only(top: 12), child:
        Container()
      ),
      Visibility(visible: (_selectedFilter != null), child:
        Stack(children:<Widget>[
          _buildDisabledContentLayer(),
          _buildFilterValues(),
        ]),
      ),
    ]);
  }

  Widget _buildDisabledContentLayer() {
    return Padding(padding: EdgeInsets.only(top: 12), child:
      BlockSemantics(child:
        Container(color: Color(0x99000000))
      ),
    );
  }

  Widget _buildFilterValues() {

    List<_FilterEntry> filterValues;
    dynamic selectedFilterValue;
    List<String> subLabels;
    switch(_selectedFilter) {
      case _FilterType.Type: filterValues = _types; selectedFilterValue = _selectedType; subLabels = null; break;
      case _FilterType.Time: filterValues = _times; selectedFilterValue = _selectedTime; subLabels = _buildTimeDates(); break;
      default: filterValues = []; break;
    }

    return Padding(padding: EdgeInsets.only(top: 6, left: 16, right: 16, bottom: 32), child:
      Container(decoration: BoxDecoration(color: Styles().colors.fillColorSecondary, borderRadius: BorderRadius.circular(5.0)), child: 
        Padding(padding: EdgeInsets.only(top: 2), child:
          Container(color: Colors.white, child:
            ListView.separated(
              shrinkWrap: true,
              separatorBuilder: (context, index) => Divider(height: 1, color: Styles().colors.fillColorPrimaryTransparent03,),
              itemCount: filterValues.length,
              itemBuilder: (context, index) {
                return FilterListItemWidget(
                  label: filterValues[index].name,
                  subLabel: (subLabels != null) ? subLabels[index] : null,
                  selected: selectedFilterValue == filterValues[index].value,
                  onTap: () { _onFilterValue(_selectedFilter, filterValues[index]); },
                );
              }
            ),
          ),
        )
      )
    );
  }

  List<String> _buildTimeDates() {
    DateTime now = DateTime.now();
    String todayStr = AppDateTime().formatDateTime(now, format: AppDateTime.eventFilterDisplayDateFormat, ignoreTimeZone: true);

    List<String> timeDates = <String>[];
    for (_FilterEntry timeEntry in _times) {
      String timeDate;
      switch(timeEntry?.value) {
        case _TimeFilter.Today:
          timeDate = todayStr;
          break;

        case _TimeFilter.TodayAndYesterday:
          DateTime yesterday = DateTime(now.year, now.month, now.day - 1);
          String yesterdayStr = AppDateTime().formatDateTime(yesterday, format: AppDateTime.eventFilterDisplayDateFormat, ignoreTimeZone: true);
          timeDate = "$yesterdayStr - $todayStr";
          break;

        case _TimeFilter.ThisWeek:
          if (1 < now.weekday) {
            DateTime startOfThisWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
            String startOfThisWeekStr = AppDateTime().formatDateTime(startOfThisWeek, format: AppDateTime.eventFilterDisplayDateFormat, ignoreTimeZone: true);
            timeDate = "$startOfThisWeekStr - $todayStr";
          }
          else {
            timeDate = todayStr;
          }
          break;

        case _TimeFilter.LastWeek:
          DateTime startOfLastWeek = DateTime(now.year, now.month, now.day - now.weekday + 1 - 7);
          String startOfLastWeekStr = AppDateTime().formatDateTime(startOfLastWeek, format: AppDateTime.eventFilterDisplayDateFormat, ignoreTimeZone: true);
          DateTime endOfLastWeek = DateTime(now.year, now.month, now.day - now.weekday);
          String endOfLastWeekStr = AppDateTime().formatDateTime(endOfLastWeek, format: AppDateTime.eventFilterDisplayDateFormat, ignoreTimeZone: true);
          timeDate = "$startOfLastWeekStr - $endOfLastWeekStr";
          break;

        case _TimeFilter.ThisMonth:
          if (1 < now.day) {
            DateTime startOfThisMonth = DateTime(now.year, now.month, 1);
            String startOfThisMonthStr = AppDateTime().formatDateTime(startOfThisMonth, format: AppDateTime.eventFilterDisplayDateFormat, ignoreTimeZone: true);
            timeDate = "$startOfThisMonthStr - $todayStr";
          }
          break;

        case _TimeFilter.LastMonth:
          DateTime startOfLastMonth = DateTime(now.year, now.month - 1, 1);
          String startOfLastMonthStr = AppDateTime().formatDateTime(startOfLastMonth, format: AppDateTime.eventFilterDisplayDateFormat, ignoreTimeZone: true);
          DateTime endOfLastMonth = DateTime(now.year, now.month, 0);
          String endOfLastMonthStr = AppDateTime().formatDateTime(endOfLastMonth, format: AppDateTime.eventFilterDisplayDateFormat, ignoreTimeZone: true);
          timeDate = "$startOfLastMonthStr - $endOfLastMonthStr";
          break;
      }
      timeDates.add(timeDate);
    }
    return timeDates;
  }

  void _onFilterValue(_FilterType filterType, _FilterEntry filterEntry) {
    Analytics().logSelect(target: "FilterItem: ${filterEntry.name}");
    setState(() {
      switch(filterType) {
        case _FilterType.Type: _selectedType = filterEntry?.value; break;
        case _FilterType.Time: _selectedTime = filterEntry?.value; break;
      }
      _selectedFilter = null;
    });
  }

  // Filters

  Widget _buildFilters() {
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child:
      Padding(padding: EdgeInsets.only(left: 12, right: 12, top: 12), child:
        Row(children: <Widget>[
          FilterSelectorWidget(
            label: _FilterEntry.entryInList(_types, _selectedType)?.name ?? '',
            active: _selectedFilter == _FilterType.Type,
            visible: true,
            onTap: () { _onFilter(_FilterType.Type); }
          ),
          FilterSelectorWidget(
            label: _FilterEntry.entryInList(_times, _selectedTime)?.name ?? '',
            active: _selectedFilter == _FilterType.Time,
            visible: true,
            onTap: () { _onFilter(_FilterType.Time); }
          )
        ],
    ),),);
  }

  void _onFilter(_FilterType filterType) {
    setState(() {
      _selectedFilter = (filterType != _selectedFilter) ? filterType : null;
    });
  }

}

class _FilterEntry {
  final String _name;
  final dynamic _value;
  _FilterEntry({String name, dynamic value}) :
    _name = name ?? value?.toString(),
    _value = value;

  String get name => _name;
  dynamic get value => _value;
  
  static _FilterEntry entryInList(List<_FilterEntry> entries, dynamic value) {
    if (entries != null) {
      for (_FilterEntry entry in entries) {
        if (entry.value == value) {
          return entry;
        }
      }
    }
    return null;
  }
  
}

enum _TimeFilter {
  Today, TodayAndYesterday, ThisWeek, LastWeek, ThisMonth, LastMonth
}

enum _FilterType {
  Type, Time
}