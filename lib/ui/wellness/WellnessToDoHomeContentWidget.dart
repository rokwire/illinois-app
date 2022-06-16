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

import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:illinois/model/wellness/ToDo.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessToDoHomeContentWidget extends StatefulWidget {
  WellnessToDoHomeContentWidget();

  @override
  State<WellnessToDoHomeContentWidget> createState() => _WellnessToDoHomeContentWidgetState();
}

class _WellnessToDoHomeContentWidgetState extends State<WellnessToDoHomeContentWidget> {
  static final String _unAssignedLabel =
      Localization().getStringEx('panel.wellness.todo.items.unassigned.category.label', 'Unassigned Items');
  late _ToDoTab _selectedTab;
  List<ToDoItem>? _todoItems;
  bool _welcomeVisible = false;
  bool _itemsLoading = false;

  @override
  void initState() {
    super.initState();
    _welcomeVisible = (Storage().isUserAccessedWellnessToDo != true);
    if (Storage().isUserAccessedWellnessToDo != true) {
      Storage().userAccessedWellnessToDo = true;
    }
    _selectedTab = _ToDoTab.daily;
    _loadToDoItems();
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
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      _buildTabButtonRow(),
      _buildClearCompletedItemsButton(),
      (_welcomeVisible ? _buildWelcomeContent() : _buildItemsContent()),
      //TBD: DD - properly position the button if the content is not scrollable
      _buildManageCategoriesButton()
    ]);
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
              selected: (_selectedTab == _ToDoTab.reminders),
              label: Localization().getStringEx('panel.wellness.todo.tab.reminders.label', 'Reminders'),
              hint: Localization().getStringEx('panel.wellness.todo.tab.reminders.hint', ''),
              onTap: () => _onTabChanged(tab: _ToDoTab.reminders)))
    ]);
  }

  Widget _buildClearCompletedItemsButton() {
    bool visible = !_welcomeVisible && !_itemsLoading && CollectionUtils.isNotEmpty(_todoItems);
    return Visibility(
        visible: visible,
        child: Padding(
            padding: EdgeInsets.only(top: 15),
            child: RoundedButton(
                contentWeight: 0.75,
                padding: EdgeInsets.symmetric(vertical: 8),
                fontSize: 18,
                label: Localization().getStringEx('panel.wellness.todo.items.completed.clear.button', 'Clear Completed Items'),
                onTap: _onTapClearCompletedItems)));
  }

  Widget _buildManageCategoriesButton() {
    return Padding(
        padding: EdgeInsets.only(top: 30),
        child: RoundedButton(
            contentWeight: 0.75,
            padding: EdgeInsets.symmetric(vertical: 8),
            fontSize: 18,
            label: Localization().getStringEx('panel.wellness.todo.categories.manage.button', 'Manage Categories'),
            onTap: _onTapManageCategories));
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

  Widget _buildWelcomeContent() {
    return Column(children: [
      _buildSectionWidget(_unAssignedLabel),
      Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Container(
              height: 200,
              decoration: BoxDecoration(
                  color: Styles().colors!.white,
                  boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]),
              child: Stack(alignment: Alignment.center, children: [
                Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Text(Localization().getStringEx('panel.wellness.todo.welcome.header.label', 'Welcome to your'),
                          style:
                              TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.medium)),
                      Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(Localization().getStringEx('panel.wellness.todo.welcome.todo_list.label', 'To-Do List'),
                              style: TextStyle(
                                  color: Styles().colors!.fillColorPrimary, fontSize: 18, fontFamily: Styles().fontFamilies!.bold))),
                      Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Text(
                              Localization()
                                  .getStringEx('panel.wellness.todo.welcome.description.label', 'Use this tool to manage your ...'),
                              style: TextStyle(
                                  color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.regular)))
                    ])),
                Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                        onTap: _onTapCloseWelcome,
                        child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Image.asset('images/icon-x-orange.png', color: Styles().colors!.mediumGray))))
              ])))
    ]);
  }

  Widget _buildEmptyContent() {
    return Column(children: [
      _buildSectionWidget(_unAssignedLabel),
      Padding(
          padding: EdgeInsets.symmetric(vertical: 30, horizontal: 16),
          child: Text(Localization().getStringEx('panel.wellness.todo.items.add.empty.msg', 'No upcoming items'),
              style: TextStyle(fontSize: 14, color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.regular)))
    ]);
  }

  Widget _buildSectionWidget(String sectionKey) {
    return Padding(
        padding: EdgeInsets.only(top: 25),
        child: Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(sectionKey,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(fontSize: 20, fontFamily: Styles().fontFamilies!.bold, color: Styles().colors!.fillColorPrimary)),
          Padding(padding: EdgeInsets.only(left: 7), child: Image.asset('images/icon-down.png')),
          Expanded(child: Container()),
          RoundedButton(
              label: Localization().getStringEx('panel.wellness.todo.items.add.button', 'Add Item'),
              borderColor: Styles().colors!.fillColorPrimary,
              textColor: Styles().colors!.fillColorPrimary,
              leftIcon: Image.asset('images/icon-add-14x14.png', color: Styles().colors!.fillColorPrimary),
              iconPadding: 8,
              rightIconPadding: EdgeInsets.only(right: 8),
              fontSize: 14,
              contentWeight: 0,
              fontFamily: Styles().fontFamilies!.regular,
              padding: EdgeInsets.zero,
              onTap: _onTapAddItem)
        ]));
  }

  void _onTabChanged({required _ToDoTab tab}) {
    if (_selectedTab != tab) {
      _selectedTab = tab;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onTapCloseWelcome() {
    _welcomeVisible = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _onTapClearCompletedItems() {
    //TBD: DD - implement
    AppAlert.showDialogResult(context, 'Not Implemented');
  }

  void _onTapManageCategories() {
    //TBD: DD - implement
    AppAlert.showDialogResult(context, 'Not Implemented');
  }

  void _onTapAddItem() {
    if (_welcomeVisible) {
      return;
    }
    //TBD: DD - implement
  }

  void _loadToDoItems() {
    _setItemsLoading(true);
    //TBD: DD - implement with backend
    Future.delayed(Duration(seconds: 1)).then((_) {
      List<dynamic>? itemsJson = JsonUtils.decodeList(
          '[{"id":"dfssdfdssdtghnhn","name":"Lon Capa Homework","category":{"id":"asdadsad","name":"Chem 201","color":"#002855","reminder_type":"night_before"},"due_date_time":"2022-05-20T16:00","work_days":["2022-05-17","2022-05-18"],"location":{"latitude":40.101977,"longitude":88.227162},"description":"I have to do my homework.","completed":true},{"id":"fdsddsdssdtghnhn","name":"Read Chapter 1 Jane Eyre","category":{"id":"67yh","name":"Eng 103","color":"#E84A27","reminder_type":"morning_of"},"due_date_time":"2022-07-03T07:15","work_days":["2022-06-30","2022-07-01","2022-07-02"],"location":{"latitude":40.201977,"longitude":87.227162},"description":"I have to do my homework.","completed":true},{"id":"09kj90ipsdfk","name":"Call about Prescriptions","due_date_time":"2022-06-15T14:30","work_days":["2022-06-02","2022-06-10"],"location":{"latitude":40.101877,"longitude":88.237162},"description":"Call about the Prescriptions.","completed":false},{"id":"09ksdde45fk","name":"Read Chapter 1 Jane Eyre","category":{"id":"67yh","name":"Eng 103","color":"#E84A27","reminder_type":"morning_of"},"location":{"latitude":40.101877,"longitude":88.237162},"description":"Read this chapter.","completed":false}]');
      _todoItems = ToDoItem.listFromJson(itemsJson);
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

  void _setItemsLoading(bool loading) {
    _itemsLoading = loading;
    if (mounted) {
      setState(() {});
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
  @override
  Widget build(BuildContext context) {
    Color cardColor = UiColors.fromHex(widget.item.category?.colorHex) ?? Styles().colors!.fillColorPrimary!;
    return Container(
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.all(Radius.circular(10))),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          _buildCompletedWidget(color: cardColor),
          Expanded(
              child: Text(StringUtils.ensureNotEmpty(widget.item.name),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 18, color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.bold))),
          GestureDetector(onTap: _onTapRemove, child: Image.asset('images/icon-x-orange.png', color: Styles().colors!.white))
        ]));
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
    //TBD: DD - implement
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
