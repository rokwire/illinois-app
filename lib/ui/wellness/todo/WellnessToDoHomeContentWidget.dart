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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/wellness/ToDo.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/wellness/todo/WellnessCreateToDoItemPanel.dart';
import 'package:illinois/ui/wellness/todo/WellnessManageToDoCategoriesPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessToDoHomeContentWidget extends StatefulWidget {
  WellnessToDoHomeContentWidget();

  @override
  State<WellnessToDoHomeContentWidget> createState() => _WellnessToDoHomeContentWidgetState();
}

class _WellnessToDoHomeContentWidgetState extends State<WellnessToDoHomeContentWidget> implements NotificationsListener {
  static final String _unAssignedLabel =
      Localization().getStringEx('panel.wellness.todo.items.unassigned.category.label', 'Unassigned Items');
  late _ToDoTab _selectedTab;
  List<ToDoItem>? _todoItems;
  late DateTime _calendarStartDate;
  late DateTime _calendarEndDate;
  bool _itemsLoading = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Wellness.notifyToDoItemCreated, Wellness.notifyToDoItemDeleted]);
    _selectedTab = _ToDoTab.daily;
    _initCalendarDates();
    _loadToDoItems();
    if (Storage().isUserAccessedWellnessToDo != true) {
      Storage().userAccessedWellnessToDo = true;
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        _showWelcomePopup();
      });
    }
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_itemsLoading) {
      return _buildLoadingContent();
    } else {
      return _buildContent();
    }
  }

  Widget _buildContent() {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          _buildToDoListHeader(),
          _buildTabButtonRow(),
          _buildCalendarWidget(),
          _buildItemsContent(),
          _buildClearCompletedItemsButton(),
          _buildManageCategoriesButton()
        ]));
  }

  Widget _buildToDoListHeader() {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(Localization().getStringEx('panel.wellness.todo.header.label', 'My To-Do List'),
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18, fontFamily: Styles().fontFamilies!.bold)),
      HomeFavoriteButton(style: HomeFavoriteStyle.Button, padding: EdgeInsets.symmetric(horizontal: 16)),
      Expanded(child: Container()),
      RoundedButton(
          label: Localization().getStringEx('panel.wellness.todo.items.add.button', 'Add Item'),
          borderColor: Styles().colors!.fillColorSecondary,
          textColor: Styles().colors!.fillColorPrimary,
          leftIcon: Image.asset('images/icon-add-14x14.png', color: Styles().colors!.fillColorPrimary),
          iconPadding: 8,
          rightIconPadding: EdgeInsets.only(right: 8),
          fontSize: 14,
          contentWeight: 0,
          fontFamily: Styles().fontFamilies!.regular,
          padding: EdgeInsets.zero,
          onTap: _onTapAddItem)
    ]);
  }

  Widget _buildTabButtonRow() {
    return Padding(
        padding: EdgeInsets.only(top: 14),
        child: Row(children: [
          Expanded(
              child: _TabButton(
                  position: _TabButtonPosition.first,
                  selected: (_selectedTab == _ToDoTab.daily),
                  label: Localization().getStringEx('panel.wellness.todo.tab.daily.label', 'Daily'),
                  hint: Localization().getStringEx('panel.wellness.todo.tab.daily.hint', ''),
                  onTap: () => _onTabChanged(tab: _ToDoTab.daily))),
          Expanded(
              child: _TabButton(
                  position: _TabButtonPosition.middle,
                  selected: (_selectedTab == _ToDoTab.category),
                  label: Localization().getStringEx('panel.wellness.todo.tab.category.label', 'Category'),
                  hint: Localization().getStringEx('panel.wellness.todo.tab.category.hint', ''),
                  onTap: () => _onTabChanged(tab: _ToDoTab.category))),
          Expanded(
              child: _TabButton(
                  position: _TabButtonPosition.last,
                  selected: (_selectedTab == _ToDoTab.reminders),
                  label: Localization().getStringEx('panel.wellness.todo.tab.reminders.label', 'Reminders'),
                  hint: Localization().getStringEx('panel.wellness.todo.tab.reminders.hint', ''),
                  onTap: () => _onTabChanged(tab: _ToDoTab.reminders)))
        ]));
  }

  Widget _buildClearCompletedItemsButton() {
    return Padding(
        padding: EdgeInsets.only(top: 40),
        child: RoundedButton(
            borderColor: Styles().colors!.fillColorPrimary,
            contentWeight: 0.75,
            padding: EdgeInsets.symmetric(vertical: 8),
            fontSize: 18,
            label: Localization().getStringEx('panel.wellness.todo.items.completed.clear.button', 'Clear Completed Items'),
            onTap: _onTapClearCompletedItems));
  }

  Widget _buildCalendarWidget() {
    if (_selectedTab != _ToDoTab.reminders) {
      return Container();
    }
    TextStyle smallStyle = TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.regular);
    return Padding(
        padding: EdgeInsets.only(top: 28),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text(StringUtils.ensureNotEmpty(AppDateTime().formatDateTime(_calendarStartDate, format: 'MMMM yyyy', ignoreTimeZone: true)),
                style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold)),
            Expanded(child: Container()),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: GestureDetector(onTap: _onTapPreviousWeek, child: Image.asset('images/icon-blue-chevron-left.png'))),
            Text(Localization().getStringEx('panel.wellness.todo.items.this_week.label', 'This Week'), style: smallStyle),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: GestureDetector(onTap: _onTapNextWeek, child: Image.asset('images/icon-blue-chevron-right.png')))
          ]),
          Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                Text('Su', style: smallStyle),
                Text('M', style: smallStyle),
                Text('T', style: smallStyle),
                Text('W', style: smallStyle),
                Text('Th', style: smallStyle),
                Text('F', style: smallStyle),
                Text('Sa', style: smallStyle)
              ])),
          Padding(
              padding: EdgeInsets.only(top: 5),
              child: Container(
                  height: 176,
                  decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: BorderRadius.circular(5), boxShadow: [
                    BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))
                  ]),
                  child: Stack(children: [
                    _buildCalendarVerticalDelimiters(),
                    _buildCalendarHotizontalDelimiter(),
                    _buildCalendarHeaderDatesWidget(),
                    _buildCalendarItems()
                  ])))
        ]));
  }

  Widget _buildCalendarVerticalDelimiters() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _buildCalendarVerticalDelimiter(),
      _buildCalendarVerticalDelimiter(),
      _buildCalendarVerticalDelimiter(),
      _buildCalendarVerticalDelimiter(),
      _buildCalendarVerticalDelimiter(),
      _buildCalendarVerticalDelimiter()
    ]);
  }

  Widget _buildCalendarHotizontalDelimiter() {
    return Padding(padding: EdgeInsets.only(top: 32), child: Container(height: 1, color: Styles().colors!.lightGray));
  }

  Widget _buildCalendarVerticalDelimiter() {
    return Container(width: 1, color: Styles().colors!.lightGray);
  }

  Widget _buildCalendarHeaderDatesWidget() {
    List<Widget> dateWidgetList = <Widget>[];
    DateTime currentDate = DateTime.fromMillisecondsSinceEpoch(_calendarStartDate.millisecondsSinceEpoch);
    while (currentDate.isBefore(_calendarEndDate)) {
      String dateFormatted = AppDateTime().formatDateTime(currentDate, format: 'dd', ignoreTimeZone: true)!;
      Text dateWidget = Text(dateFormatted,
          style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold));
      dateWidgetList.add(dateWidget);
      currentDate = currentDate.add(Duration(days: 1));
    }
    return Padding(
        padding: EdgeInsets.only(top: 7), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: dateWidgetList));
  }

  Widget _buildCalendarItems() {
    List<Widget> scrollWidgets = <Widget>[];
    DateTime currentDate = DateTime.fromMillisecondsSinceEpoch(_calendarStartDate.millisecondsSinceEpoch);
    while (currentDate.isBefore(_calendarEndDate)) {
      List<Widget> dayItemWidgets = <Widget>[];
      List<ToDoItem>? dayItems = _getItemsForDate(currentDate);
      if (CollectionUtils.isNotEmpty(dayItems)) {
        for (ToDoItem item in dayItems!) {
          dayItemWidgets.add(Padding(padding: EdgeInsets.only(top: 7), child: _buildCalendarToDoItem(item)));
        }
      }
      if (CollectionUtils.isEmpty(dayItemWidgets)) {
        dayItemWidgets.add(_buildCalendarToDoItem(null)); // Build empty transparent widget for proper horizontal adjustment
      }
      scrollWidgets.add(SingleChildScrollView(
          scrollDirection: Axis.vertical, child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: dayItemWidgets)));

      currentDate = currentDate.add(Duration(days: 1));
    }
    return Padding(
        padding: EdgeInsets.only(top: 34), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: scrollWidgets));
  }

  Widget _buildCalendarToDoItem(ToDoItem? item) {
    double widgetSize = 30;
    return GestureDetector(
        onTap: () => _onTapCalendarItem(item),
        child: Container(height: widgetSize, width: widgetSize, decoration: BoxDecoration(color: item?.color ?? Colors.transparent, shape: BoxShape.circle)));
  }

  Widget _buildManageCategoriesButton() {
    return Padding(
        padding: EdgeInsets.only(top: 15),
        child: GestureDetector(
            onTap: _onTapManageCategories,
            child: Column(children: [
              Text(Localization().getStringEx('panel.wellness.todo.categories.manage.button', 'Manage Categories'),
                  style: TextStyle(fontSize: 14, fontFamily: Styles().fontFamilies!.bold, color: Styles().colors!.fillColorPrimary)),
              Divider(color: Styles().colors!.fillColorPrimary, thickness: 2, height: 2, indent: 100, endIndent: 100)
            ])));
  }

  Widget _buildItemsContent() {
    if (_sortedItemsMap != null) {
      List<Widget> contentList = <Widget>[];
      for (String key in _sortedItemsMap!.keys) {
        List<ToDoItem>? items = _sortedItemsMap![key];
        if (CollectionUtils.isNotEmpty(items)) {
          contentList.add(_buildSectionWidget(key));
          for (ToDoItem item in items!) {
            contentList.add(Padding(padding: EdgeInsets.only(top: 10), child: _ToDoItemCard(item: item)));
          }
        }
      }
      return Column(children: contentList);
    } else {
      return _buildEmptyContent();
    }
  }

  Widget _buildLoadingContent() {
    return Center(
        child: Column(children: <Widget>[
      Container(height: MediaQuery.of(context).size.height / 5),
      CircularProgressIndicator(),
      Container(height: MediaQuery.of(context).size.height / 5 * 3)
    ]));
  }

  Widget _buildEmptyContent() {
    return Column(children: [
      _buildSectionWidget(_unAssignedLabel),
      Padding(
          padding: EdgeInsets.symmetric(vertical: 30, horizontal: 16),
          child: Text(Localization().getStringEx('panel.wellness.todo.items.add.empty.msg', 'You currently have no to-do list items.'),
              style: TextStyle(fontSize: 14, color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.regular)))
    ]);
  }

  Widget _buildSectionWidget(String sectionKey) {
    return Padding(
        padding: EdgeInsets.only(top: 25),
        child: Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
          Image.asset('images/icon-down.png'),
          Padding(
              padding: EdgeInsets.only(left: 7),
              child: Text(sectionKey,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(fontSize: 20, fontFamily: Styles().fontFamilies!.bold, color: Styles().colors!.fillColorPrimary)))
        ]));
  }

  void _showWelcomePopup() {
    AppAlert.showCustomDialog(
        context: context,
        contentPadding: EdgeInsets.all(0),
        contentWidget: Container(
            height: 250,
            decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: BorderRadius.circular(10.0)),
            child: Stack(alignment: Alignment.center, fit: StackFit.loose, children: [
              Padding(
                  padding: EdgeInsets.all(30),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(Localization().getStringEx('panel.wellness.todo.welcome.label', 'Welcome to Your To-Do List'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Styles().colors!.fillColorSecondary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold))),
                    Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Text(
                            Localization().getStringEx('panel.wellness.todo.welcome.description.label',
                                'Free up space in your mind by recording your to-do items here.'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.regular)))
                  ])),
              Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                      onTap: () => {Navigator.of(context).pop()},
                      child: Padding(padding: EdgeInsets.all(16), child: Image.asset('images/icon-x-orange.png'))))
            ])));
  }

  void _onTabChanged({required _ToDoTab tab}) {
    if (_selectedTab != tab) {
      _selectedTab = tab;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onTapClearCompletedItems() {
    //TBD: DD - implement
    AppAlert.showDialogResult(context, 'Not Implemented');
  }

  void _onTapPreviousWeek() {
    //TBD: DD - implement
  }

  void _onTapNextWeek() {
    //TBD: DD - implement
  }

  void _onTapCalendarItem(ToDoItem? item) {
    //TBD: DD - implement
  }

  void _onTapManageCategories() {
    Analytics().logSelect(target: "Manage Categories");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessManageToDoCategoriesPanel()));
  }

  void _onTapAddItem() {
    Analytics().logSelect(target: "Add Item");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessCreateToDoItemPanel()));
  }

  void _initCalendarDates() {
    DateTime now = DateTime.now();
    _calendarStartDate = now.subtract(Duration(days: now.weekday));
    _calendarEndDate = now.add(Duration(days: (7 - (now.weekday + 1))));
  }

  void _loadToDoItems() {
    _setItemsLoading(true);
    Wellness().loadToDoItemsCached().then((items) {
      _todoItems = items;
      _sortItemsByDate();
      _setItemsLoading(false);
    });
  }

  void _sortItemsByDate() {
    if (CollectionUtils.isEmpty(_todoItems)) {
      return;
    }
    _todoItems!.sort((ToDoItem first, ToDoItem second) {
      if ((first.dueDateTime == null) && (second.dueDateTime != null)) {
        return -1;
      } else if ((first.dueDateTime != null) && (second.dueDateTime == null)) {
        return 1;
      } else if ((first.dueDateTime == null) && (second.dueDateTime == null)) {
        return 0;
      } else {
        return (first.dueDateTime!.isBefore(second.dueDateTime!)) ? -1 : 1;
      }
    });
  }

  String? _getItemKeyByTab(ToDoItem item) {
    String? key;
    switch (_selectedTab) {
      case _ToDoTab.daily:
        key = item.displayDueDate;
        break;
      case _ToDoTab.category:
        key = item.category?.name;
        break;
      case _ToDoTab.reminders:
        key = item.displayDueDate;
        break;
    }
    if (StringUtils.isEmpty(key)) {
      key = _unAssignedLabel;
    }
    return key;
  }

  Map<String, List<ToDoItem>>? get _sortedItemsMap {
    if (CollectionUtils.isEmpty(_todoItems)) {
      return null;
    }
    Map<String, List<ToDoItem>> itemsMap = {};
    for (ToDoItem item in _todoItems!) {
      String itemKey = _getItemKeyByTab(item)!;
      List<ToDoItem>? categoryItems = itemsMap[itemKey];
      if (categoryItems == null) {
        categoryItems = <ToDoItem>[];
      }
      categoryItems.add(item);
      itemsMap[itemKey] = categoryItems;
    }
    if (_selectedTab != _ToDoTab.category) {
      return itemsMap;
    }
    SplayTreeMap<String, List<ToDoItem>> sortedMap = SplayTreeMap<String, List<ToDoItem>>.from(itemsMap, (first, second) {
      if ((first == _unAssignedLabel) && (second != _unAssignedLabel)) {
        return -1;
      } else if ((first != _unAssignedLabel) && (second == _unAssignedLabel)) {
        return 1;
      } else {
        return first.compareTo(second);
      }
    });
    return sortedMap;
  }

  List<ToDoItem>? _getItemsForDate(DateTime date) {
    List<ToDoItem>? dayItems;
    if (_todoItems != null) {
      for (ToDoItem item in _todoItems!) {
        DateTime? itemDueDate = item.dueDateTime;
        if (itemDueDate != null) {
          if ((itemDueDate.year == date.year) && (itemDueDate.month == date.month) && (itemDueDate.day == date.day)) {
            if (dayItems == null) {
              dayItems = <ToDoItem>[];
            }
            dayItems.add(item);
          }
        }
      }
    }
    return dayItems;
  }

  void _setItemsLoading(bool loading) {
    _itemsLoading = loading;
    if (mounted) {
      setState(() {});
    }
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == Wellness.notifyToDoItemCreated) {
      _loadToDoItems();
    } else if (name == Wellness.notifyToDoItemDeleted) {
      _loadToDoItems();
    }
  }
}

class _ToDoItemCard extends StatefulWidget {
  final ToDoItem item;
  _ToDoItemCard({required this.item});

  @override
  State<_ToDoItemCard> createState() => _ToDoItemCardState();
}

class _ToDoItemCardState extends State<_ToDoItemCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      Container(
          decoration: BoxDecoration(color: widget.item.color, borderRadius: BorderRadius.all(Radius.circular(10))),
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            _buildCompletedWidget(color: widget.item.color),
            Expanded(
                child: Text(StringUtils.ensureNotEmpty(widget.item.name),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 18, color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.bold))),
            GestureDetector(onTap: _onTapRemove, child: Image.asset('images/icon-x-orange.png', color: Styles().colors!.white))
          ])),
      Visibility(visible: _loading, child: CircularProgressIndicator())
    ]);
  }

  Widget _buildCompletedWidget({required Color color}) {
    final double viewWidgetSize = 30;
    Widget viewWidget = widget.item.isCompleted
        ? Image.asset('images/example.png', height: viewWidgetSize, width: viewWidgetSize, fit: BoxFit.fill)
        : Container(
            decoration: BoxDecoration(color: Styles().colors!.white, shape: BoxShape.circle),
            height: viewWidgetSize,
            width: viewWidgetSize);
    return GestureDetector(onTap: _onTapCompleted, child: Padding(padding: EdgeInsets.only(right: 20), child: viewWidget));
  }

  void _onTapCompleted() {
    //TBD: DD - implement
  }

  void _onTapRemove() {
    AppAlert.showConfirmationDialog(
        buildContext: context,
        message: Localization()
            .getStringEx('panel.wellness.todo.item.delete.confirmation.msg', 'Are sure that you want to delete this To-Do item?'),
        positiveCallback: () => _deleteToDoItem());
  }

  void _deleteToDoItem() {
    _setLoading(true);
    Wellness().deleteToDoItemCached(widget.item.id!).then((success) {
      late String msg;
      if (success) {
        msg = Localization().getStringEx('panel.wellness.todo.item.delete.succeeded.msg', 'To-Do item deleted successfully.');
      } else {
        msg = Localization().getStringEx('panel.wellness.todo.item.delete.failed.msg', 'Failed to delete To-Do item.');
      }
      AppAlert.showDialogResult(context, msg);
      _setLoading(false);
    });
  }

  void _setLoading(bool loading) {
    _loading = loading;
    if (mounted) {
      setState(() {});
    }
  }
}

enum _ToDoTab { daily, category, reminders }

enum _TabButtonPosition { first, middle, last }

class _TabButton extends StatelessWidget {
  final String? label;
  final String? hint;
  final _TabButtonPosition position;
  final bool? selected;
  final GestureTapCallback? onTap;

  _TabButton({this.label, this.hint, required this.position, this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Semantics(
            label: label,
            hint: hint,
            button: true,
            excludeSemantics: true,
            child: Container(
                height: 24 + 16 * MediaQuery.of(context).textScaleFactor,
                decoration: BoxDecoration(
                    color: selected! ? Colors.white : Styles().colors!.lightGray, border: _border, borderRadius: _borderRadius),
                child: Center(
                    child: Text(label!,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: selected! ? Styles().fontFamilies!.extraBold : Styles().fontFamilies!.medium,
                            fontSize: 16,
                            color: Styles().colors!.fillColorPrimary))))));
  }

  BorderRadiusGeometry? get _borderRadius {
    switch (position) {
      case _TabButtonPosition.first:
        return BorderRadius.horizontal(left: Radius.circular(100.0));
      case _TabButtonPosition.middle:
        return null;
      case _TabButtonPosition.last:
        return BorderRadius.horizontal(right: Radius.circular(100.0));
    }
  }

  BoxBorder? get _border {
    BorderSide borderSide = BorderSide(color: Styles().colors!.surfaceAccent!, width: 2, style: BorderStyle.solid);
    switch (position) {
      case _TabButtonPosition.first:
        return Border.fromBorderSide(borderSide);
      case _TabButtonPosition.middle:
        return Border(top: borderSide, bottom: borderSide);
      case _TabButtonPosition.last:
        return Border.fromBorderSide(borderSide);
    }
  }
}
