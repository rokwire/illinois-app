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
import 'package:illinois/ui/wellness/todo/WellnessToDoItemDetailPanel.dart';
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
    NotificationService().subscribe(this, [Wellness.notifyToDoItemCreated, Wellness.notifyToDoItemUpdated, Wellness.notifyToDoItemsDeleted]);
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
          _buildClearCompletedItemsButton()
        ]));
  }

  Widget _buildToDoListHeader() {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(
          flex: 2,
          child: RoundedButton(
              padding: EdgeInsets.symmetric(vertical: 10),
              label: Localization().getStringEx('panel.wellness.todo.items.add.button', 'Add Item'),
              rightIconPadding: EdgeInsets.symmetric(horizontal: 12),
              borderColor: Styles().colors!.fillColorSecondary,
              textColor: Styles().colors!.fillColorPrimary,
              leftIcon: Image.asset('images/icon-add-14x14.png', color: Styles().colors!.fillColorPrimary),
              fontSize: 14,
              fontFamily: Styles().fontFamilies!.bold,
              onTap: _onTapAddItem)),
      Container(width: 15),
      Flexible(
          flex: 3,
          child: RoundedButton(
              label: Localization().getStringEx('panel.wellness.todo.categories.manage.button', 'Manage Categories'),
              borderColor: Styles().colors!.fillColorPrimary,
              textColor: Styles().colors!.fillColorPrimary,
              fontSize: 14,
              fontFamily: Styles().fontFamilies!.bold,
              onTap: _onTapManageCategories))
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
    return Visibility(
        visible: _clearCompletedItemsButtonVisible,
        child: Padding(
            padding: EdgeInsets.only(top: 40),
            child: RoundedButton(
                borderColor: Styles().colors!.fillColorPrimary,
                contentWeight: 0.75,
                padding: EdgeInsets.symmetric(vertical: 8),
                fontSize: 18,
                label: Localization().getStringEx('panel.wellness.todo.items.completed.clear.button', 'Clear Completed Items'),
                onTap: _onTapClearCompletedItems)));
  }

  Widget _buildCalendarWidget() {
    if (_selectedTab != _ToDoTab.reminders) {
      return Container();
    }
    TextStyle smallStyle = TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.regular);
    return Padding(
        padding: EdgeInsets.only(top: 13),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text(StringUtils.ensureNotEmpty(_formattedCalendarMonthLabel),
                style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold)),
            Expanded(child: Container()),
            GestureDetector(
                onTap: _onTapPreviousWeek,
                child: Container(
                    color: Colors.transparent,
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                        child: Image.asset('images/icon-blue-chevron-left.png')))),
            Text(Localization().getStringEx('panel.wellness.todo.items.this_week.label', 'This Week'), style: smallStyle),
            GestureDetector(
                onTap: _onTapNextWeek,
                child: Container(
                    color: Colors.transparent,
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                        child: Image.asset('images/icon-blue-chevron-right.png'))))
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            Text('Su', style: smallStyle),
            Text('M', style: smallStyle),
            Text('T', style: smallStyle),
            Text('W', style: smallStyle),
            Text('Th', style: smallStyle),
            Text('F', style: smallStyle),
            Text('Sa', style: smallStyle)
          ]),
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
      dayItemWidgets.add(Container(height: 5)); // add empty space below
      scrollWidgets.add(SingleChildScrollView(
          scrollDirection: Axis.vertical, child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: dayItemWidgets)));

      currentDate = currentDate.add(Duration(days: 1));
    }
    return Padding(
        padding: EdgeInsets.only(top: 34), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: scrollWidgets));
  }

  Widget _buildCalendarToDoItem(ToDoItem? item) {
    double widgetSize = 30;
    bool hasReminder = (item?.reminderDateTimeUtc != null);
    return GestureDetector(
        onTap: () => _onTapCalendarItem(item),
        child: Container(
            height: widgetSize,
            width: widgetSize,
            decoration: BoxDecoration(color: item?.color ?? Colors.transparent, shape: BoxShape.circle),
            child: Visibility(
                visible: hasReminder,
                child: Center(
                    child: Stack(
                        alignment: Alignment.center,
                        children: [Image.asset('images/icon-oval-white.png'), Image.asset('images/icon-arrows.png')])))));
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
      _updateState();
    }
  }

  void _onTapClearCompletedItems() {
    if (CollectionUtils.isEmpty(_todoItems)) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.wellness.todo.items.no_items.msg', 'There are no To-Do items.'));
      return;
    }
    AppAlert.showConfirmationDialog(
        buildContext: context,
        message: Localization().getStringEx(
            'panel.wellness.todo.item.completed.delete.confirmation.msg', 'Are you sure that you want to delete all completed To-Do items?'),
        positiveCallback: () => _deleteCompletedItems());
  }

  void _deleteCompletedItems() {
    List<String>? completedItemsIds = _completedItemIds;
    if (CollectionUtils.isEmpty(completedItemsIds)) {
      AppAlert.showDialogResult(
          context, Localization().getStringEx('panel.wellness.todo.items.no_completed_items.msg', 'There are no completed To-Do items.'));
      return;
    }
    _setItemsLoading(true);
    Wellness().deleteToDoItems(completedItemsIds).then((success) {
      late String msg;
      if (success) {
        msg = Localization()
            .getStringEx('panel.wellness.todo.items.completed.clear.succeeded.msg', 'Completed To-Do items are deleted successfully.');
      } else {
        msg = Localization().getStringEx('panel.wellness.todo.items.completed.clear.failed.msg', 'Failed to delete completed To-Do items.');
      }
      AppAlert.showDialogResult(context, msg);
      _setItemsLoading(false);
    });
  }

  void _onTapPreviousWeek() {
    Duration weekDuration = Duration(days: 7);
    _calendarStartDate = _calendarStartDate.subtract(weekDuration);
    _calendarEndDate = _calendarEndDate.subtract(weekDuration);
    _updateState();
  }

  void _onTapNextWeek() {
    Duration weekDuration = Duration(days: 7);
    _calendarStartDate = _calendarStartDate.add(weekDuration);
    _calendarEndDate = _calendarEndDate.add(weekDuration);
    _updateState();
  }

  void _onTapCalendarItem(ToDoItem? item) async {
    if (item == null) {
      return;
    }
    AppAlert.showCustomDialog(context: context, contentPadding: EdgeInsets.zero, contentWidget: _ToDoItemReminderDialog(item: item));
  }

  void _onTapManageCategories() {
    Analytics().logSelect(target: "Manage Categories");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessManageToDoCategoriesPanel()));
  }

  void _onTapAddItem() {
    Analytics().logSelect(target: "Add Item");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessToDoItemDetailPanel()));
  }

  void _initCalendarDates() {
    DateTime now = DateTime.now();
    _calendarStartDate = now.subtract(Duration(days: now.weekday));
    _calendarEndDate = now.add(Duration(days: (7 - (now.weekday + 1))));
  }

  void _loadToDoItems() {
    _setItemsLoading(true);
    Wellness().loadToDoItems().then((items) {
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
    _updateState();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  List<String>? get _completedItemIds {
    if (CollectionUtils.isEmpty(_todoItems)) {
      return null;
    }
    List<String> completedItemsIds = <String>[];
    for (ToDoItem item in _todoItems!) {
      if (item.isCompleted) {
        completedItemsIds.add(item.id!);
      }
    }
    return completedItemsIds;
  }

  bool get _clearCompletedItemsButtonVisible {
    return (_completedItemIds?.length ?? 0) > 0;
  }

  String get _formattedCalendarMonthLabel {
    if (_calendarStartDate.month != _calendarEndDate.month) {
      return AppDateTime().formatDateTime(_calendarStartDate, format: 'MMMM', ignoreTimeZone: true)! +
          ' / ' +
          AppDateTime().formatDateTime(_calendarEndDate, format: 'MMMM yyyy', ignoreTimeZone: true)!;
    } else {
      return AppDateTime().formatDateTime(_calendarStartDate, format: 'MMMM yyyy', ignoreTimeZone: true)!;
    }
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == Wellness.notifyToDoItemCreated) {
      _loadToDoItems();
    } else if (name == Wellness.notifyToDoItemUpdated) {
      _loadToDoItems();
    } else if (name == Wellness.notifyToDoItemsDeleted) {
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
            GestureDetector(onTap: () => _onTapEdit(widget.item), child: Image.asset('images/edit-white.png'))
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
    _setLoading(true);
    widget.item.isCompleted = !widget.item.isCompleted;
    Wellness().updateToDoItem(widget.item).then((success) {
      if (!success) {
        String msg = Localization().getStringEx('panel.wellness.todo.item.update.failed.msg', 'Failed to update To-Do item.');
        AppAlert.showDialogResult(context, msg);
      }
      _setLoading(false);
    });
  }

  void _onTapEdit(ToDoItem item) {
    Analytics().logSelect(target: "Edit Item");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessToDoItemDetailPanel(item: item)));
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

class _ToDoItemReminderDialog extends StatefulWidget {
  final ToDoItem item;
  _ToDoItemReminderDialog({required this.item});

  @override
  State<_ToDoItemReminderDialog> createState() => _ToDoItemReminderDialogState();

}

class _ToDoItemReminderDialogState extends State<_ToDoItemReminderDialog> {
  late ToDoItem _item;
  late DateTime _reminderDateTime;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _reminderDateTime = AppDateTime().getDeviceTimeFromUtcTime(_item.reminderDateTimeUtc) ?? _item.dueDateTime!;
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Stack(children: [
        Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
                onTap: _onTapCloseEditReminderDialog,
                child: Container(
                    color: Colors.transparent,
                    child: Padding(padding: EdgeInsets.all(16), child: Image.asset('images/icon-x-orange.png'))))),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
            child: Center(
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Expanded(
                    child: Text(StringUtils.ensureNotEmpty(_item.name),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 4,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies!.bold, color: Styles().colors!.fillColorPrimary)))
              ]),
              GestureDetector(
                  onTap: _onTapPickReminderDate,
                  child: Container(
                      color: Colors.transparent,
                      child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(StringUtils.ensureNotEmpty(_formattedDate),
                              style: TextStyle(
                                  fontSize: 14, color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.regular))))),
              GestureDetector(
                  onTap: _onTapPickReminderTime,
                  child: Container(
                      color: Colors.transparent,
                      child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(StringUtils.ensureNotEmpty(_formattedTime),
                              style: TextStyle(
                                  fontSize: 36, color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold))))),
              Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: RoundedButton(
                      label: Localization().getStringEx('panel.wellness.todo.items.reminder.set.button', 'Set Reminder'),
                      onTap: _onTapSetReminder,
                      contentWeight: 0,
                      progress: _loading,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10)))
            ])))
      ])
    ]);
  }

  void _onTapPickReminderDate() {
    if (_loading) {
      return;
    }
    final int oneYearInDays = 365;
    DateTime firstDate =
        DateTime.fromMillisecondsSinceEpoch(_reminderDateTime.subtract(Duration(days: oneYearInDays)).millisecondsSinceEpoch);
    DateTime lastDate = DateTime.fromMillisecondsSinceEpoch(_reminderDateTime.add(Duration(days: oneYearInDays)).millisecondsSinceEpoch);
    showDatePicker(
        context: context,
        initialDate: _reminderDateTime,
        firstDate: firstDate,
        lastDate: lastDate,
        builder: (BuildContext context, Widget? child) {
          return Theme(data: ThemeData.light(), child: child!);
        }).then((resultDate) {
      if (resultDate != null) {
        _reminderDateTime = resultDate;
        _updateState();
      }
    });
  }

  void _onTapPickReminderTime() {
    if (_loading) {
      return;
    }
    TimeOfDay initialTime = TimeOfDay(hour: _reminderDateTime.hour, minute: _reminderDateTime.minute);
    showTimePicker(context: context, initialTime: initialTime).then((resultTime) {
      if (resultTime != null) {
        _reminderDateTime =
            DateTime(_reminderDateTime.year, _reminderDateTime.month, _reminderDateTime.day, resultTime.hour, resultTime.minute);
        _updateState();
      }
    });
  }

  void _onTapSetReminder() {
    if (_loading) {
      return;
    }
    _setLoading(true);
    _item.reminderDateTimeUtc = _reminderDateTime.toUtc();
    Wellness().updateToDoItem(_item).then((success) {
      _setLoading(false);
      if (!success) {
        String msg = Localization().getStringEx('panel.wellness.todo.items.reminder.set.failed.msg', 'Failed to set reminder.');
        AppAlert.showDialogResult(context, msg);
      } else {
        Navigator.of(context).pop(true);
      }
    });
  }

  void _onTapCloseEditReminderDialog() {
    if(_loading) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _setLoading(bool loading) {
    _loading = loading;
    _updateState();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  String get _formattedDate {
    return AppDateTime().formatDateTime(_reminderDateTime, format: 'EEEE, MM/dd', ignoreTimeZone: true)!;
  }

  String get _formattedTime {
    return AppDateTime().formatDateTime(_reminderDateTime, format: 'hh : mm a', ignoreTimeZone: true)!;
  }
}
