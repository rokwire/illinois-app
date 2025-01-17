/*
 * Copyright 2025 Board of Trustees of the University of Illinois.
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

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class NotificationsFilterPanel extends StatefulWidget {
  final bool? unread;
  final bool? muted;
  final DateInterval? interval;

  NotificationsFilterPanel._({this.unread, this.muted, this.interval});

  static Future<dynamic> present(BuildContext context, {bool? unread, bool? muted, DateInterval? interval}) {
    MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
    double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 16;
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        useRootNavigator: true,
        clipBehavior: Clip.antiAlias,
        backgroundColor: Styles().colors.background,
        constraints: BoxConstraints(maxHeight: height, minHeight: height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (context) {
          return NotificationsFilterPanel._(unread: unread, muted: muted, interval: interval);
        });
  }


  static final List<FilterEntry> dateFilterEntries = [
    FilterEntry(name: Localization().getStringEx('panel.inbox.filter.time.all.label', 'All Notifications'), value: null),
    FilterEntry(name: Localization().getStringEx('panel.inbox.filter.time.today.label', 'Today'), value: TimeFilter.Today),
    FilterEntry(name: Localization().getStringEx('panel.inbox.filter.time.yesterday.label', 'Yesterday'), value: TimeFilter.Yesterday),
    FilterEntry(name: Localization().getStringEx('panel.inbox.filter.time.this_week.label', 'This week'), value: TimeFilter.ThisWeek),
    FilterEntry(name: Localization().getStringEx('panel.inbox.filter.time.last_week.label', 'Last week'), value: TimeFilter.LastWeek),
    FilterEntry(name: Localization().getStringEx('panel.inbox.filter.time.this_month.label', 'This month'), value: TimeFilter.ThisMonth),
    FilterEntry(name: Localization().getStringEx('panel.inbox.filter.time.last_month.label', 'Last Month'), value: TimeFilter.LastMonth),
  ];

  static Map<TimeFilter, DateInterval> getTimeFilterIntervals() {
    DateTime now = DateTime.now();
    return {
      TimeFilter.Today: DateInterval(startDate: DateTime(now.year, now.month, now.day)),
      TimeFilter.Yesterday:
      DateInterval(startDate: DateTime(now.year, now.month, now.day - 1), endDate: DateTime(now.year, now.month, now.day)),
      TimeFilter.ThisWeek: DateInterval(startDate: DateTime(now.year, now.month, now.day - now.weekday + 1)),
      TimeFilter.LastWeek: DateInterval(
          startDate: DateTime(now.year, now.month, now.day - now.weekday + 1 - 7),
          endDate: DateTime(now.year, now.month, now.day - now.weekday + 1)),
      TimeFilter.ThisMonth: DateInterval(startDate: DateTime(now.year, now.month, 1)),
      TimeFilter.LastMonth: DateInterval(startDate: DateTime(now.year, now.month - 1, 1), endDate: DateTime(now.year, now.month, 0)),
    };
  }

  @override
  _NotificationsFilterPanelState createState() => _NotificationsFilterPanelState();
}

class _NotificationsFilterPanelState extends State<NotificationsFilterPanel> {

  bool? _unread;
  bool? _muted;
  TimeFilter? _selectedTimeFilter;

  @override
  void initState() {
    super.initState();
    _unread = widget.unread;
    _muted = widget.muted;
    _selectedTimeFilter = _getTimeFilterBy(interval: widget.interval);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [_buildHeader(), Container(color: Styles().colors.surfaceAccent, height: 1), Expanded(child: _buildContent())]);
  }

  Widget _buildHeader() {
    return Container(
        color: Styles().colors.white,
        child: Row(children: [
          Expanded(
              child: Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Semantics(
                      container: true,
                      header: true,
                      child: Text(Localization().getStringEx('panel.settings.notifications.header.inbox.label', 'Notifications'),
                          style: Styles().textStyles.getTextStyle("widget.sheet.title.regular"))))),
          Semantics(
              label: Localization().getStringEx('dialog.close.title', 'Close'),
              hint: Localization().getStringEx('dialog.close.hint', ''),
              container: true,
              button: true,
              child: InkWell(
                  onTap: _onTapClose,
                  child: Container(
                      padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
                      child: Styles().images.getImage('close-circle', excludeFromSemantics: true))))
        ]));
  }

  Widget _buildContent() {
    return Semantics(
        container: true,
        child: SingleChildScrollView(
            child: Container(
                color: Styles().colors.background,
                padding: EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildViewFilters(), _buildDateFilters(), _buildApplyButton()]))));
  }

  Widget _buildViewFilters() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(Localization().getStringEx('panel.inbox.filter.view.label', 'VIEW'),
          style: Styles().textStyles.getTextStyle('widget.title.regular.fat')),
      Padding(
          padding: EdgeInsets.only(top: 10),
          child: _buildToggleWidget(
              label: Localization().getStringEx('panel.inbox.filter.notifications.toggle.unread.label', 'Unread Notifications'),
              value: (_unread == true),
              onTapValue: _onTapUnread)),
      Padding(
          padding: EdgeInsets.only(top: 10),
          child: _buildToggleWidget(
              label: Localization().getStringEx('panel.inbox.filter.notifications.toggle.muted.label', 'Muted Notifications'),
              value: (_muted != false),
              onTapValue: _onTapMuted)),
      Padding(
          padding: EdgeInsets.only(left: 12, top: 6),
          child: Text(
              Localization()
                  .getStringEx('panel.inbox.filter.notifications.toggle.muted.description', 'View notifications you have turned off.'),
              style: Styles().textStyles.getTextStyle('panel.inbox.notifications.filter.muted.description')))
    ]);
  }

  Widget _buildToggleWidget({required String label, bool? value, required void Function()? onTapValue}) {
    return Container(
        decoration: BoxDecoration(
            color: Styles().colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8)),
            boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 4.0, offset: Offset(2, 2))]),
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Padding(padding: EdgeInsets.only(left: 10), child: Text(label, style: Styles().textStyles.getTextStyle('widget.info.small'))),
          InkWell(
              onTap: onTapValue,
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Styles().images.getImage((value == true) ? 'toggle-on' : 'toggle-off') ?? Container()))
        ]));
  }

  Widget _buildDateFilters() {
    return Padding(
        padding: EdgeInsets.only(top: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Localization().getStringEx('panel.inbox.filter.date.label', 'DATE RANGE'),
              style: Styles().textStyles.getTextStyle('widget.title.regular.fat')),
          Padding(padding: EdgeInsets.only(top: 8), child: _buildDateRangeFilterValues())
        ]));
  }

  Widget _buildDateRangeFilterValues() {
    final Radius borderRadiusValue = Radius.circular(10);
    List<FilterEntry> dateFilterEntries = NotificationsFilterPanel.dateFilterEntries;
    List<String> subLabels = _buildDateLabels();
    return Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8)),
            boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 4.0, offset: Offset(2, 2))]),
        child: ListView.separated(
            shrinkWrap: true,
            separatorBuilder: (context, index) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Divider(height: 1, color: Styles().colors.fillColorPrimaryTransparent03)),
            itemCount: dateFilterEntries.length,
            itemBuilder: (context, index) {
              FilterEntry filterEntry = dateFilterEntries[index];
              BorderRadius? borderRadius;
              if (index == 0) {
                borderRadius = BorderRadius.only(topLeft: borderRadiusValue, topRight: borderRadiusValue);
              } else if (index == (dateFilterEntries.length - 1)) {
                borderRadius = BorderRadius.only(bottomLeft: borderRadiusValue, bottomRight: borderRadiusValue);
              }
              return _buildDateEntryWidget(
                  title: dateFilterEntries[index].name,
                  description: subLabels[index],
                  borderRadius: borderRadius,
                  onTap: () => _onTapTimeFilter(filterEntry.value),
                  selected: (_selectedTimeFilter == filterEntry.value));
            }));
  }

  List<String> _buildDateLabels() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    Map<TimeFilter, DateInterval> intervals = NotificationsFilterPanel.getTimeFilterIntervals();

    List<String> timeDates = <String>[];
    for (FilterEntry timeEntry in NotificationsFilterPanel.dateFilterEntries) {
      String? timeDate;
      DateInterval? interval = intervals[timeEntry.value];
      if (interval != null) {
        DateTime startDate = interval.startDate!;
        String? startStr = AppDateTime().formatDateTime(interval.startDate, format: 'MM/dd', ignoreTimeZone: true);

        DateTime endDate = interval.endDate ?? today;
        if (1 < endDate.difference(startDate).inDays) {
          String? endStr = AppDateTime().formatDateTime(endDate, format: 'MM/dd', ignoreTimeZone: true);
          timeDate = "$startStr - $endStr";
        } else {
          timeDate = startStr;
        }
      }
      timeDates.add(timeDate ?? '');
    }

    return timeDates;
  }

  Widget _buildDateEntryWidget(
      {String? title, String? description, required bool selected, void Function()? onTap, BorderRadius? borderRadius}) {
    TextStyle? titleTextStyle =
        selected ? Styles().textStyles.getTextStyle('widget.title.small.fat') : Styles().textStyles.getTextStyle('widget.title.small');

    List<Widget> contentList = <Widget>[Expanded(child: Text(StringUtils.ensureNotEmpty(title), style: titleTextStyle))];
    if (StringUtils.isNotEmpty(description)) {
      contentList.add(Text(StringUtils.ensureNotEmpty(description),
          maxLines: 1, overflow: TextOverflow.ellipsis, style: Styles().textStyles.getTextStyle('widget.title.regular')));
    }
    contentList.add(Padding(
        padding: EdgeInsets.only(left: 10),
        child: (selected ? Styles().images.getImage('radio-button-on') : Styles().images.getImage('radio-button-off'))));

    return Semantics(
        label: title,
        button: true,
        selected: selected,
        excludeSemantics: true,
        child: InkWell(
            onTap: onTap,
            child: Container(
                decoration: BoxDecoration(color: Styles().colors.white, borderRadius: borderRadius),
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    child: Row(mainAxisSize: MainAxisSize.max, children: contentList)))));
  }

  Widget _buildApplyButton() {
    return Padding(
        padding: EdgeInsets.only(top: 30),
        child: RoundedButton(
            label: Localization().getStringEx('panel.inbox.filter.apply.button', 'Apply'),
            padding: EdgeInsets.symmetric(vertical: 4),
            contentWeight: 0.35,
            fontSize: 16,
            onTap: _onTapApply));
  }

  void _onTapApply() {
    Analytics().logSelect(target: 'Apply');
    FilterResult result = FilterResult(muted: _muted, unread: _unread, dateInterval: _getDateIntervalBy(filter: _selectedTimeFilter));
    Navigator.of(context).pop(result);
  }

  ///
  /// Muted requires special treatment. Values meanings:
  ///  - null - show muted and not-muted notifications
  ///  - false - do not show muted notifications
  ///  - true - show only muted notifications
  ///
  void _onTapMuted() {
    setStateIfMounted(() {
      if (_muted == null) {
        _muted = false;
      } else {
        _muted = null;
      }
    });
  }

  ///
  /// Unread requires special treatment. Values meanings:
  ///  - null - show read and unread notifications
  ///  - false - show only read notifications
  ///  - true - show only unread notifications
  ///
  void _onTapUnread() {
    setStateIfMounted(() {
      if (_unread == true) {
        _unread = null;
      } else {
        _unread = true;
      }
    });
  }

  void _onTapTimeFilter(dynamic timeFilterValue) {
    setStateIfMounted(() {
      if (timeFilterValue is TimeFilter) {
        _selectedTimeFilter = timeFilterValue;
      } else {
        _selectedTimeFilter = null;
      }
    });
  }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: widget.runtimeType.toString());
    Navigator.of(context).pop(null);
  }

  DateInterval? _getDateIntervalBy({TimeFilter? filter}) {
    if (filter == null) {
      return null;
    }
    return NotificationsFilterPanel.getTimeFilterIntervals()[filter];
  }

  TimeFilter? _getTimeFilterBy({DateInterval? interval}) {
    if (interval != null) {
      Map<TimeFilter, DateInterval> filterIntervals = NotificationsFilterPanel.getTimeFilterIntervals();
      for (TimeFilter filter in filterIntervals.keys) {
        DateInterval? current = filterIntervals[filter];
        if (current == interval) {
          return filter;
        }
      }
    }
    return null;
  }
}

enum TimeFilter { Today, Yesterday, ThisWeek, LastWeek, ThisMonth, LastMonth }

class DateInterval {
  final DateTime? startDate;
  final DateTime? endDate;

  DateInterval({this.startDate, this.endDate});

  bool contains(DateTime? dateTime) {
    if (dateTime == null) {
      return false;
    } else if ((startDate != null) && startDate!.isAfter(dateTime)) {
      return false;
    } else if ((endDate != null) && endDate!.isBefore(dateTime)) {
      return false;
    } else {
      return true;
    }
  }

  @override
  bool operator ==(other) => (other is DateInterval) && (other.startDate == startDate) && (other.endDate == endDate);

  @override
  int get hashCode => (startDate?.hashCode ?? 0) ^ (endDate?.hashCode ?? 0);
}

class FilterEntry {
  final String? _name;
  final dynamic _value;

  String? get name => _name;

  dynamic get value => _value;

  FilterEntry({String? name, dynamic value})
      : _name = name ?? value?.toString(),
        _value = value;

  static FilterEntry? entryInList(List<FilterEntry>? entries, dynamic value) {
    if (entries != null) {
      for (FilterEntry entry in entries) {
        if (entry.value == value) {
          return entry;
        }
      }
    }
    return null;
  }
}

class FilterResult {
  final bool? muted;
  final bool? unread;
  final DateInterval? dateInterval;

  FilterResult({this.muted, this.unread, this.dateInterval});
}