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
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/wellness/WellnessToDo.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/wellness/todo/WellnessToDoItemDetailPanel.dart';
import 'package:illinois/ui/wellness/todo/WellnessManageToDoCategoriesPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/AudioUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/scroll_pager.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessToDoHomeContentWidget extends StatefulWidget with AnalyticsInfo {
  final AnalyticsFeature? analyticsFeature; //This overrides AnalyticsInfo.analyticsFeature getter

  WellnessToDoHomeContentWidget({super.key, this.analyticsFeature});

  @override
  State<WellnessToDoHomeContentWidget> createState() => _WellnessToDoHomeContentWidgetState();
}

class _WellnessToDoHomeContentWidgetState extends State<WellnessToDoHomeContentWidget> with NotificationsListener {
  static final String _unAssignedLabel =
      Localization().getStringEx('panel.wellness.todo.items.unassigned.category.label', 'Unassigned Items');
  late _ToDoTab _selectedTab;
  List<WellnessToDoItem> _todoItems = [];
  List<WellnessToDoItem> _recurringTodoItems = [];
  late DateTime _calendarStartDate;
  late DateTime _calendarEndDate;
  bool _itemsLoading = false;
  late ScrollPagerController _scrollPagerController;
  final ScrollController _scrollController = ScrollController();

  int _limit = 100;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Wellness.notifyToDoItemCreated,
      Wellness.notifyToDoItemUpdated,
      Wellness.notifyToDoItemsDeleted,
      Wellness.notifyToDoCategoryChanged,
      Wellness.notifyToDoCategoryDeleted
    ]);
    _selectedTab = _ToDoTab.daily;
    _initCalendarDates();
    // _loadToDoItems();

    _scrollPagerController = ScrollPagerController(limit: _limit, controller:_scrollController, /*infinite: true,*/ onPage: _loadTodos, onStateChanged: (){
      if (mounted) {
        setState(() {
        });
      }
    }, onReset: () {
      _todoItems = [];
      _recurringTodoItems = [];
    });

    _scrollPagerController.registerScrollController(_scrollController);

    if (Wellness().isToDoListAccessed != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWelcomePopup().then((_){
          Wellness().toDoListAccessed(true);
        });
      });
    }

  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _scrollController.dispose();
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
          _buildTabButtonRow(),
          _buildManageButtonsRow(),
          _buildCalendarWidget(),
          _buildItemsContent(),
          // _buildClearCompletedItemsButton()
        ]));
  }

  Widget _buildTabButtonRow() {
    return Row(children: [
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
              selected: (_selectedTab == _ToDoTab.weekly),
              label: Localization().getStringEx('panel.wellness.todo.tab.weekly.label', 'Weekly'),
              hint: Localization().getStringEx('panel.wellness.todo.tab.weekly.hint', ''),
              onTap: () => _onTabChanged(tab: _ToDoTab.weekly)))
    ]);
  }

  Widget _buildManageButtonsRow() {
    return Padding(
        padding: EdgeInsets.only(top: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
              flex: 2,
              child: RoundedButton(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  label: Localization().getStringEx('panel.wellness.todo.items.add.button', 'Add Item'),
                  textStyle: Styles().textStyles.getTextStyle("widget.button.title.small.fat"),
                  rightIconPadding: EdgeInsets.symmetric(horizontal: 12),
                  borderColor: Styles().colors.fillColorSecondary,
                  leftIcon: Styles().images.getImage('plus-dark', excludeFromSemantics: true),
                  onTap: _onTapAddItem)),
          Container(width: 15),
          Flexible(
              flex: 3,
              child: RoundedButton(
                  label: Localization().getStringEx('panel.wellness.todo.categories.manage.button', 'Manage Categories'),
                  textStyle: Styles().textStyles.getTextStyle("widget.button.title.small.fat"),
                  borderColor: Styles().colors.fillColorPrimary,
                  onTap: _onTapManageCategories))
        ]));
  }

  /* Unused: Widget _buildClearCompletedItemsButton() {
    return Visibility(
        visible: _clearCompletedItemsButtonVisible,
        child: Padding(
            padding: EdgeInsets.only(top: 40),
            child: RoundedButton(
                label: Localization().getStringEx('panel.wellness.todo.items.completed.clear.button', 'Clear Completed Items'),
                textStyle: Styles().textStyles.getTextStyle("widget.button.title.regular"),
                borderColor: Styles().colors.fillColorPrimary,
                contentWeight: 0.75,
                padding: EdgeInsets.symmetric(vertical: 8),
                onTap: _onTapClearCompletedItems)));
  }*/

  Widget _buildCalendarWidget() {
    if (_selectedTab != _ToDoTab.weekly) {
      return Container();
    }
    TextStyle? smallStyle = Styles().textStyles.getTextStyle("widget.detail.small");
    return Padding(
        padding: EdgeInsets.only(top: 13),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.start, children: [
              Text(StringUtils.ensureNotEmpty(_formattedCalendarMonthLabel),
                  style: Styles().textStyles.getTextStyle("widget.title.regular.fat")),
              GestureDetector(
                  onTap: _onTapCalendarInfo,
                  child: Padding(padding: EdgeInsets.only(left: 5), child: Styles().images.getImage('info', excludeFromSemantics: true)))
            ]),
            Expanded(child: Container()),
            GestureDetector(
                onTap: _onTapPreviousWeek,
                child: Container(
                    color: Colors.transparent,
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                        child: Styles().images.getImage('chevron-left-bold', excludeFromSemantics: true)))),
            Text(Localization().getStringEx('panel.wellness.todo.items.this_week.label', 'This Week'), style: smallStyle),
            GestureDetector(
                onTap: _onTapNextWeek,
                child: Container(
                    color: Colors.transparent,
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                        child: Styles().images.getImage('chevron-right-bold', excludeFromSemantics: true))))
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
                  decoration: BoxDecoration(color: Styles().colors.white, borderRadius: BorderRadius.circular(5), boxShadow: [
                    BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))
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
    return Padding(padding: EdgeInsets.only(top: 32), child: Container(height: 1, color: Styles().colors.lightGray));
  }

  Widget _buildCalendarVerticalDelimiter() {
    return Container(width: 1, color: Styles().colors.lightGray);
  }

  Widget _buildCalendarHeaderDatesWidget() {
    List<Widget> dateWidgetList = <Widget>[];
    DateTime currentDate = DateTime.fromMillisecondsSinceEpoch(_calendarStartDate.millisecondsSinceEpoch);
    while (currentDate.isBefore(_calendarEndDate)) {
      String dateFormatted = AppDateTime().formatDateTime(currentDate, format: 'dd', ignoreTimeZone: true)!;
      Text dateWidget = Text(dateFormatted,
          style: Styles().textStyles.getTextStyle("widget.title.regular.fat"));
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
      List<WellnessToDoItem>? dayItems = _getItemsForDate(currentDate);
      if (CollectionUtils.isNotEmpty(dayItems)) {
        for (WellnessToDoItem item in dayItems!) {
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

  Widget _buildCalendarToDoItem(WellnessToDoItem? item) {
    double widgetSize = 30;
    bool hasReminder = (item?.reminderDateTimeUtc != null);
    return  GestureDetector(
        onTap: () => _onTapCalendarItem(item),
        child: Container(
            height: widgetSize,
            width: widgetSize,
            decoration: BoxDecoration(color: item?.color ?? Colors.transparent, shape: BoxShape.circle),
            child: Visibility(
                visible: hasReminder,
                child: Center(child: Styles().images.getImage('clock-white', excludeFromSemantics: true) ?? Container()))));
  }

  Widget _buildItemsContent() {

    if (_sortedItemsMap != null) {
      List<Widget> contentList = <Widget>[];
      for (String key in _sortedItemsMap!.keys) {
        List<WellnessToDoItem>? items = _sortedItemsMap![key];
        if (CollectionUtils.isNotEmpty(items)) {
          contentList.add(_buildSectionWidget(key));
          for (WellnessToDoItem item in items!) {
            contentList.add(Padding(padding: EdgeInsets.only(top: 10), child: _ToDoItemCard(item: item, analyticsFeature: widget.analyticsFeature,)));
          }
        }
      }

      return Expanded(
        child: ScrollPager(
          controller: _scrollPagerController,
          child: Column(children: contentList),
        ),
      );
      //Dead code: return Column(children: contentList);
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
              style: Styles().textStyles.getTextStyle("widget.message.small")))
    ]);
  }

  Widget _buildSectionWidget(String sectionKey) {
    return Padding(
        padding: EdgeInsets.only(top: 25),
        child: Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
          Styles().images.getImage('chevron-down', excludeFromSemantics: true) ?? Container(),
          Padding(
              padding: EdgeInsets.only(left: 7),
              child: Text(sectionKey,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Styles().textStyles.getTextStyle("widget.title.large.fat")))
        ]));
  }

  Future<bool?> _showWelcomePopup() =>
    AppAlert.showCustomDialog(
        context: context,
        contentPadding: EdgeInsets.all(0),
        contentWidget: Container(
            height: 250,
            decoration: BoxDecoration(color: Styles().colors.white, borderRadius: BorderRadius.circular(10.0)),
            child: Stack(alignment: Alignment.center, fit: StackFit.loose, children: [
              Padding(
                  padding: EdgeInsets.all(30),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(Localization().getStringEx('panel.wellness.todo.welcome.label', 'Welcome to Your To-Do List'),
                            textAlign: TextAlign.center,
                            style: Styles().textStyles.getTextStyle("panel.wellness.todo.dialog.heading.regular"))),
                    Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Text(
                            Localization().getStringEx('panel.wellness.todo.welcome.description.label',
                                'Free up space in your mind by recording your to-do items here.'),
                            textAlign: TextAlign.center,
                            style:  Styles().textStyles.getTextStyle("widget.detail.small")))
                  ])),
              Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                      onTap: _onClose,
                      child: Padding(padding: EdgeInsets.all(16), child: Styles().images.getImage('close-circle', excludeFromSemantics: true))))
            ])));

  void _onClose() {
    Analytics().logSelect(target: "Close", source: widget.runtimeType.toString());
    Navigator.of(context).pop();
  }

  void _onTabChanged({required _ToDoTab tab}) {
    Analytics().logSelect(target: tab.toString(), source: widget.runtimeType.toString());
    if (_selectedTab != tab) {
      _selectedTab = tab;
      _updateState();
    }
  }

  /* Unused: void _onTapClearCompletedItems() {
    Analytics().logSelect(target: 'Clear Completed Items', source: widget.runtimeType.toString());
    if (CollectionUtils.isEmpty(_todoItems)) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.wellness.todo.items.no_items.msg', 'There are no To-Do items.'));
      return;
    }
    AppAlert.showConfirmationDialog(
        buildContext: context,
        message: Localization().getStringEx(
            'panel.wellness.todo.item.completed.delete.confirmation.msg', 'Are you sure that you want to delete all completed To-Do items?'),
        positiveCallback: () => _deleteCompletedItems());
  } */

  /* Unused: void _deleteCompletedItems() {
    Analytics().logWellness(
      category: Analytics.LogWellnessCategoryToDo,
      action: Analytics.LogWellnessActionClear,
      target: _completedItemNames?.join(','),
      source: widget.runtimeType.toString(),
    );
    
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
            .getStringEx('panel.wellness.todo.items.completed.clear.succeeded.msg', 'Completed To-Do items were deleted successfully.');
      } else {
        msg = Localization().getStringEx('panel.wellness.todo.items.completed.clear.failed.msg', 'Failed to delete completed To-Do items.');
      }
      AppAlert.showDialogResult(context, msg);
      _setItemsLoading(false);
    });
  } */

  void _onTapPreviousWeek() {
    Analytics().logSelect(target: "Previous Week", source: widget.runtimeType.toString());
    Duration weekDuration = Duration(days: 7);
    _calendarStartDate = _calendarStartDate.subtract(weekDuration);
    _calendarEndDate = _calendarEndDate.subtract(weekDuration);
    _updateState();
  }

  void _onTapNextWeek() {
    Analytics().logSelect(target: "Next Week", source: widget.runtimeType.toString());
    Duration weekDuration = Duration(days: 7);
    _calendarStartDate = _calendarStartDate.add(weekDuration);
    _calendarEndDate = _calendarEndDate.add(weekDuration);
    _updateState();
  }

  void _onTapCalendarItem(WellnessToDoItem? item) async {
    Analytics().logSelect(target: "Calendar", source: widget.runtimeType.toString());
    if (item == null) {
      return;
    }
    if (item.reminderDateTime != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) =>
        WellnessToDoItemDetailPanel(item: item, optionalFieldsExpanded: true, analyticsFeature: widget.analyticsFeature,)
      ));
    } else {
      AppAlert.showCustomDialog(context: context, contentPadding: EdgeInsets.zero, contentWidget: _ToDoItemReminderDialog(item: item));
    }
  }

  void _onTapManageCategories() {
    Analytics().logSelect(target: "Manage Categories", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessManageToDoCategoriesPanel(analyticsFeature: widget.analyticsFeature,)));
  }

  void _onTapAddItem() {
    Analytics().logSelect(target: "Add Item", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessToDoItemDetailPanel(analyticsFeature: widget.analyticsFeature,)));
  }

  void _onTapCalendarInfo() {
    Analytics().logSelect(target: "Calendar Info", source: widget.runtimeType.toString());
    AppAlert.showTextMessage(
        context,
        Localization()
            .getStringEx('panel.wellness.todo.items.calendar.info.msg', 'Tap on a dot to set a reminder or to edit item details.'));
  }

  void _initCalendarDates() {
    DateTime now = DateTime.now();
    _calendarStartDate = now.subtract(Duration(days: now.weekday));
    _calendarEndDate = now.add(Duration(days: (7 - (now.weekday + 1))));
  }

  void _sortItemsByDate() {
    if (CollectionUtils.isEmpty(_todoItems)) {
      return;
    }
    _todoItems.sort((WellnessToDoItem first, WellnessToDoItem second) {
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

  String? _getItemKeyByTab(WellnessToDoItem item) {
    String? key;
    switch (_selectedTab) {
      case _ToDoTab.daily:
        key = item.displayDueDate;
        break;
      case _ToDoTab.category:
        key = item.category?.name;
        break;
      case _ToDoTab.weekly:
        key = item.displayDueDate;
        break;
    }
    if (StringUtils.isEmpty(key)) {
      key = _unAssignedLabel;
    }
    return key;
  }

  Map<String, List<WellnessToDoItem>>? get _sortedItemsMap {
    if (CollectionUtils.isEmpty(_todoItems)) {
      return null;
    }

    Map<String, List<WellnessToDoItem>> itemsMap = {};
    List<WellnessToDoItem>? categoryItems;
    for (WellnessToDoItem item in _todoItems) {
      String itemKey = _getItemKeyByTab(item)!;
      categoryItems = itemsMap[itemKey];
      if (categoryItems == null) {
        categoryItems = <WellnessToDoItem>[];
      }
      categoryItems.add(item);
      itemsMap[itemKey] = categoryItems;
    }

    _sortItemsByDate();

    if (_selectedTab != _ToDoTab.category) {
      return itemsMap;
    }
    SplayTreeMap<String, List<WellnessToDoItem>> sortedMap = SplayTreeMap<String, List<WellnessToDoItem>>.from(itemsMap, (first, second) {
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

  List<WellnessToDoItem>? _getItemsForDate(DateTime date) {
    List<WellnessToDoItem>? dayItems;
    for (WellnessToDoItem item in _todoItems) {
      DateTime? itemDueDate = item.dueDateTime;
      if (itemDueDate != null) {
        if ((itemDueDate.year == date.year) && (itemDueDate.month == date.month) && (itemDueDate.day == date.day)) {
          if (dayItems == null) {
            dayItems = <WellnessToDoItem>[];
          }
          dayItems.add(item);
        }
      }
    }
    return dayItems;
  }

  /* Unused void _setItemsLoading(bool loading) {
    _itemsLoading = loading;
    _updateState();
  } */

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  /* Ununsed List<String>? get _completedItemIds {
    if (CollectionUtils.isEmpty(_todoItems)) {
      return null;
    }
    List<String> completedItemsIds = <String>[];
    for (ToDoItem item in _todoItems) {
      if (item.isCompleted) {
        completedItemsIds.add(item.id!);
      }
    }
    return completedItemsIds;
  } */

  /* Ununsed List<String>? get _completedItemNames {
    if (CollectionUtils.isEmpty(_todoItems)) {
      return null;
    }
    List<String> completedItemsNames = <String>[];
    for (ToDoItem item in _todoItems) {
      if (item.isCompleted) {
        completedItemsNames.add(item.name!);
      }
    }
    return completedItemsNames;
  } */

  /* Ununsed bool get _clearCompletedItemsButtonVisible {
    return (_completedItemIds?.length ?? 0) > 0;
  } */

  String get _formattedCalendarMonthLabel {
    if (_calendarStartDate.month != _calendarEndDate.month) {
      return AppDateTime().formatDateTime(_calendarStartDate, format: 'MMM', ignoreTimeZone: true)! +
          ' / ' +
          AppDateTime().formatDateTime(_calendarEndDate, format: 'MMM yyyy', ignoreTimeZone: true)!;
    } else {
      return AppDateTime().formatDateTime(_calendarStartDate, format: 'MMMM yyyy', ignoreTimeZone: true)!;
    }
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if ((name == Wellness.notifyToDoItemCreated) ||
        (name == Wellness.notifyToDoItemUpdated) ||
        (name == Wellness.notifyToDoItemsDeleted) ||
        (name == Wellness.notifyToDoCategoryChanged) ||
        (name == Wellness.notifyToDoCategoryDeleted)) {
        _scrollPagerController.reset();

    }
  }

  Future<int> _loadTodos({required int limit, required int offset}) async {
    List<WellnessToDoItem>? responses = await Wellness().loadToDoItems(limit, offset);
    if (mounted && responses != null) {
      setState(() {
        _todoItems.addAll(responses.where((a) => _todoItems.every((b) => a.id != b.id)));
        // _todoItems?.addAll(responses);
        _recurringTodoItems.addAll(_todoItems.where((element) => element.recurrenceType != null && element.recurrenceType != "none" && element.recurrenceId == null));
        _fillRecurringTodos();
      });
    }
    return responses?.length ?? -1;
  }

  void _fillRecurringTodos(){
    if(_recurringTodoItems.isNotEmpty){
      DateTime? date = _recurringTodoItems[0].dueDateTimeUtc ?? DateTime.now();
      List<WellnessToDoItem> recurringItems = [];
      while(_todoItems.length + recurringItems.length < _limit){
        for(WellnessToDoItem item in _recurringTodoItems){
          if(date!.isBefore(item.dueDateTimeUtc ?? DateTime.now())
              || _isSameDate(item.dueDateTimeUtc, date)
              || _isRecurringDayCompleted(item, date)
          ){
            continue;
          }else{
            //daily
            if(item.recurrenceType?.substring((item.recurrenceType?.length ?? 0) -5, (item.recurrenceType?.length ?? 0)) == "* * *"){
              WellnessToDoItem toDoItem = WellnessToDoItem(
                  name: item.name,
                  category: item.category,
                  dueDateTimeUtc: new DateTime.utc(date.year, date.month, date.day, item.dueDateTimeUtc?.hour ?? 0, item.dueDateTimeUtc?.minute ?? 0),
                  hasDueTime:  item.hasDueTime,
                  reminderType:  item.reminderType,
                  reminderDateTimeUtc: item.reminderDateTimeUtc,
                  workDays:  item.workDays,
                  location:  item.location,
                  description:  item.description,
                  isCompleted: false,
                  recurrenceType:  item.recurrenceType,
                  recurrenceId:  item.id
              );
              recurringItems.add(toDoItem);
              //monthly
            }else if(item.recurrenceType?.substring((item.recurrenceType?.length ?? 0) -5, (item.recurrenceType?.length ?? 0)) == "* ? *"){
              List<String>? result = item.recurrenceType?.split(' ');
              if(result != null && int.parse(result[3]) == date.day) {
                WellnessToDoItem toDoItem = WellnessToDoItem(
                    name: item.name,
                    category: item.category,
                    dueDateTimeUtc: new DateTime.utc(date.year, date.month, date.day, item.dueDateTimeUtc?.hour ?? 0, item.dueDateTimeUtc?.minute ?? 0),
                    hasDueTime:  item.hasDueTime,
                    reminderType:  item.reminderType,
                    reminderDateTimeUtc: item.reminderDateTimeUtc,
                    workDays:  item.workDays,
                    location:  item.location,
                    description:  item.description,
                    isCompleted: false,
                    recurrenceType:  item.recurrenceType,
                    recurrenceId:  item.id
                );
                recurringItems.add(toDoItem);
              }
            }else{
              List<String>? result = item.recurrenceType?.split(' ');
              if(result != null){
                //weekly
                if(!result[5].contains(",") && _convertDayString(result[5]) == date.weekday){
                  WellnessToDoItem toDoItem = WellnessToDoItem(
                      name: item.name,
                      category: item.category,
                      dueDateTimeUtc: new DateTime.utc(date.year, date.month, date.day, item.dueDateTimeUtc?.hour ?? 0, item.dueDateTimeUtc?.minute ?? 0),
                      hasDueTime:  item.hasDueTime,
                      reminderType:  item.reminderType,
                      reminderDateTimeUtc: item.reminderDateTimeUtc,
                      workDays:  item.workDays,
                      location:  item.location,
                      description:  item.description,
                      isCompleted: false,
                      recurrenceType:  item.recurrenceType,
                      recurrenceId:  item.id
                  );
                  recurringItems.add(toDoItem);

                  //weekdays
                }else{
                  List<String>? daysStringList  = item.recurrenceType?.split(" ");
                  List<String>? dayStrings = daysStringList?[5].split(",");
                  if(dayStrings != null){
                    for(String day in dayStrings){
                      if(_convertDayString(day) == date.weekday){
                        WellnessToDoItem toDoItem = WellnessToDoItem(
                            name: item.name,
                            category: item.category,
                            dueDateTimeUtc: new DateTime.utc(date.year, date.month, date.day, item.dueDateTimeUtc?.hour ?? 0, item.dueDateTimeUtc?.minute ?? 0),
                            hasDueTime:  item.hasDueTime,
                            reminderType:  item.reminderType,
                            reminderDateTimeUtc: item.reminderDateTimeUtc,
                            workDays:  item.workDays,
                            location:  item.location,
                            description:  item.description,
                            isCompleted: false,
                            recurrenceType:  item.recurrenceType,
                            recurrenceId:  item.id
                        );
                        recurringItems.add(toDoItem);
                        break;
                      }
                    }
                  }
                }
              }
            }
          }
        }
        date = date?.add(Duration(days: 1));
      }
      _todoItems.addAll(recurringItems);
    }
  }

  int _convertDayString(String day){
    switch(day){
      case "MON":
        return 1;
      case "TUE":
        return 2;
      case "WED":
        return 3;
      case "THU":
        return 4;
      case "FRI":
        return 5;
      case "SAT":
        return 6;
      case "SUN":
        return 7;
      default:
        return -1;

    }
  }

  bool _isSameDate(DateTime? item, DateTime? date){
    return item?.month == date?.month && item?.day == date?.day;
  }

  bool _isRecurringDayCompleted(WellnessToDoItem recurringItem, DateTime? date){
    for(WellnessToDoItem item in _todoItems){
      if(_isSameDate(item.dueDateTimeUtc, date) && (item.recurrenceId ?? "") == recurringItem.id){
        return true;
      }
    }
    return false;
  }

}

class _ToDoItemCard extends StatefulWidget {
  final WellnessToDoItem item;
  final AnalyticsFeature? analyticsFeature;
  _ToDoItemCard({required this.item, this.analyticsFeature});

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
          padding: EdgeInsets.only(left: 15),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
             Expanded(
                 child: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                _buildCompletedWidget(color: widget.item.color),
                Expanded(
                    child: Text(StringUtils.ensureNotEmpty(widget.item.name),
                        overflow: TextOverflow.ellipsis,
                        style: Styles().textStyles.getTextStyle("panel.wellness.todo.card.title"))),
            ]))),
            Semantics(label: "Edit", button: true, child: InkWell(onTap: () => _onTapEdit(widget.item), child: Padding(padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10), child: Styles().images.getImage('edit-white', excludeFromSemantics: true))))
          ])),
      Visibility(visible: _loading, child: CircularProgressIndicator())
    ]);
  }

  Widget _buildCompletedWidget({required Color color}) {
    Widget? viewWidget = Styles().images.getImage(widget.item.isCompleted ? 'check-circle-outline-2' : 'circle-outline-white', excludeFromSemantics: true);
    return AppSemantics.buildCheckBoxSemantics( selected: widget.item.isCompleted, title: widget.item.name,
    child:GestureDetector(onTap: _onTapCompleted, child: Padding(padding: EdgeInsets.only(right: 20), child: viewWidget)));
  }

  void _onTapCompleted() {
    Analytics().logWellnessToDo(
      action: widget.item.isCompleted ? Analytics.LogWellnessActionUncomplete : Analytics.LogWellnessActionComplete,
      source: widget.runtimeType.toString(),
      item: widget.item,
    );
    widget.item.isCompleted = !widget.item.isCompleted;
    AppSemantics.announceCheckBoxStateChange(context, widget.item.isCompleted , widget.item.name);
    if (widget.item.isCompleted) {
      _playCheckingOffSound();
    }
    _setLoading(true);
    if(widget.item.id != null){
      Wellness().updateToDoItem(widget.item).then((success) {
        if (!success) {
          // revert value if update fails
          widget.item.isCompleted = !widget.item.isCompleted;
          String msg = Localization().getStringEx('panel.wellness.todo.item.update.failed.msg', 'Failed to update To-Do item.');
          AppAlert.showDialogResult(context, msg);
        }

      });
    }else{
      Wellness().createToDoItem(widget.item).then((success) {
        if (!success) {
          // revert value if update fails
          widget.item.isCompleted = !widget.item.isCompleted;
          String msg = Localization().getStringEx('panel.wellness.todo.item.create.failed.msg', 'Failed to create To-Do item.');
          AppAlert.showDialogResult(context, msg);
        }
      });
    }
    _setLoading(false);
  }

  void _onTapEdit(WellnessToDoItem item) {
    Analytics().logSelect(target: "Edit Item", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessToDoItemDetailPanel(item: item, analyticsFeature: widget.analyticsFeature,)));
  }

  void _playCheckingOffSound(){
    ResourceAudioSound('media/wellness-todo-check-off.m4a').play();
  }

  void _setLoading(bool loading) {
    _loading = loading;
    if (mounted) {
      setState(() {});
    }
  }
}

enum _ToDoTab { daily, category, weekly }

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
                height: 24 + MediaQuery.of(context).textScaler.scale(16),
                decoration: BoxDecoration(
                    color: selected! ? Colors.white : Styles().colors.lightGray, border: _border, borderRadius: _borderRadius),
                child: Center(
                    child: Text(label!,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: selected! ? Styles().textStyles.getTextStyle("widget.tab.selected") : Styles().textStyles.getTextStyle("widget.tab.not_selected"))))));
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
    BorderSide borderSide = BorderSide(color: Styles().colors.surfaceAccent, width: 2, style: BorderStyle.solid);
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
  final WellnessToDoItem item;
  _ToDoItemReminderDialog({required this.item});

  @override
  State<_ToDoItemReminderDialog> createState() => _ToDoItemReminderDialogState();

}

class _ToDoItemReminderDialogState extends State<_ToDoItemReminderDialog> {
  late WellnessToDoItem _item;
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
                    child: Padding(padding: EdgeInsets.all(16), child: Styles().images.getImage('close-circle', excludeFromSemantics: true))))),
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
                        style:Styles().textStyles.getTextStyle("widget.title.regular.fat")))
              ]),
              GestureDetector(
                  onTap: _onTapPickReminderDate,
                  child: Container(
                      color: Colors.transparent,
                      child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(StringUtils.ensureNotEmpty(_formattedDate),
                              style: Styles().textStyles.getTextStyle("widget.detail.small"))))),
              GestureDetector(
                  onTap: _onTapPickReminderTime,
                  child: Container(
                      color: Colors.transparent,
                      child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(StringUtils.ensureNotEmpty(_formattedTime),
                              style: Styles().textStyles.getTextStyle("panel.wellness.todo.content.large_title"))))),
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
    Analytics().logSelect(target: "Pick Reminder Date", source: widget.runtimeType.toString());
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
    Analytics().logSelect(target: "Pick Reminder Time", source: widget.runtimeType.toString());
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
    Analytics().logSelect(target: "Set Reminder", source: widget.runtimeType.toString());
    if (_loading) {
      return;
    }
    Analytics().logWellnessToDo(
      action: Analytics.LogWellnessActionUpdate,
      source: widget.runtimeType.toString(),
      item: widget.item,
    );
    _setLoading(true);
    _item.reminderDateTimeUtc = _reminderDateTime.toUtc();
    _item.reminderType = WellnessToDoReminderType.specific_time;
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
    Analytics().logSelect(target: "Close", source: widget.runtimeType.toString());
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
