import 'package:flutter/material.dart';
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
    return Container();
  }

  // Filters

  Widget _buildFilters() {
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child:
      Padding(padding: EdgeInsets.all(12), child:
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