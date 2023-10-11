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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/wellness/ToDo.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/wellness/todo/WellnessManageToDoCategoriesPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessToDoItemDetailPanel extends StatefulWidget  implements AnalyticsPageAttributes {
  final String? itemId;
  final ToDoItem? item;
  final bool? optionalFieldsExpanded;
  WellnessToDoItemDetailPanel({this.itemId, this.item, this.optionalFieldsExpanded});

  @override
  State<WellnessToDoItemDetailPanel> createState() => _WellnessToDoItemDetailPanelState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes {
    return {
      Analytics.LogWellnessCategoryName: Analytics.LogWellnessCategoryToDo,
      Analytics.LogWellnessTargetName: item?.name,
      Analytics.LogWellnessToDoCategoryName: item?.category?.name,
      Analytics.LogWellnessToDoDueDateTime: DateTimeUtils.utcDateTimeToString(item?.dueDateTime),
      Analytics.LogWellnessToDoReminderType: item?.reminderType.toString(),
      Analytics.LogWellnessToDoWorkdays: item?.workDays?.join(','),
    };
  }
}

class _WellnessToDoItemDetailPanelState extends State<WellnessToDoItemDetailPanel> implements NotificationsListener {
  static final String _workDayFormat = 'yyyy-MM-dd';

  ToDoItem? _item;
  ToDoCategory? _category;
  List<ToDoCategory>? _categories;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  ToDoReminderType? _selectedReminderType;
  DateTime? _reminderDateTime;
  List<DateTime>? _workDays;
  late bool _optionalFieldsVisible;
  bool _reminderTypeDropDownValuesVisible = false;
  bool _categoriesDropDownVisible = false;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Wellness.notifyToDoCategoryChanged, Wellness.notifyToDoCategoryDeleted]);
    if (StringUtils.isNotEmpty(widget.itemId)) {
      _loadToDoItem();
    } else {
      _item = widget.item;
      if (_item != null) {
        _populateItemFields();
      } else {
        _selectedReminderType = ToDoReminderType.none;
      }
    }
    _optionalFieldsVisible = widget.optionalFieldsExpanded ?? false;
    _loadCategories();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.wellness.todo.item.detail.header.title', 'To-Do List Item')),
      body:
          SingleChildScrollView(child: Padding(padding: EdgeInsets.all(16), child: (_isLoading ? _buildLoadingContent() : _buildContent()))),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildAddItemHeader(),
      _buildItemName(),
      _buildOptionalFieldsHeader(),
      Visibility(
          visible: _optionalFieldsVisible,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildCurrentCategoryContainer(),
            Stack(children: [
              Column(children: [
                _buildDueDateContainer(),
                _buildDueTimeContainer(),
                _buildSelectedReminderTypeContainer(),
                Stack(children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [_buildWorkDaysContainer(), _buildLocationContainer(), _buildDescriptionContainer()]),
                  _buildReminderTypeDropDown()
                ]),
              ]),
              _buildCategoryDropDown()
            ])
          ])),
      _buildSaveButton()
    ]);
  }

  Widget _buildLoadingContent() {
    return Center(
        child: Column(children: <Widget>[
      Container(height: MediaQuery.of(context).size.height / 5),
      CircularProgressIndicator(),
      Container(height: MediaQuery.of(context).size.height / 5 * 3)
    ]));
  }

  Widget _buildAddItemHeader() {
    return Padding(
        padding: EdgeInsets.only(top: 16),
        child: Text(Localization().getStringEx('panel.wellness.todo.item.add.label', 'Add an Item'),
            style: Styles().textStyles?.getTextStyle("widget.title.regular.fat")));
  }

  Widget _buildItemName() {
    return Padding(
        padding: EdgeInsets.only(top: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: _buildFieldLabel(label: Localization().getStringEx('panel.wellness.todo.item.name.field.label', 'ITEM NAME'))),
          _buildInputField(controller: _nameController)
        ]));
  }

  Widget _buildOptionalFieldsHeader() {
    return GestureDetector(
        onTap: _onTapOptionalFields,
        child: Container(
            color: Colors.transparent,
            child: Padding(
                padding: EdgeInsets.only(top: 22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(height: 1, color: Styles().colors!.mediumGray2),
                  Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Text(Localization().getStringEx('panel.wellness.todo.item.optional_fields.label', 'Optional Fields'),
                            style: Styles().textStyles?.getTextStyle("widget.title.small.fat")),
                        Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Styles().images?.getImage(_optionalFieldsVisible ? 'chevron-up' : 'chevron-down', excludeFromSemantics: true))
                      ]))
                ]))));
  }

  Widget _buildCurrentCategoryContainer() {
    return Padding(
        padding: EdgeInsets.only(top: 11),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: _buildFieldLabel(label: Localization().getStringEx('panel.wellness.todo.item.category.field.label', 'CATEGORY'))),
          GestureDetector(
              onTap: _onTapCurrentCategory,
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  decoration:
                      BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text(
                        StringUtils.ensureNotEmpty(_category?.name,
                            defaultValue: Localization().getStringEx('panel.wellness.todo.item.category.none.label', 'None')),
                        overflow: TextOverflow.ellipsis,
                        style:Styles().textStyles?.getTextStyle("panel.wellness.todo.item_detail.title")),
                    Expanded(child: Container()),
                    Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Styles().images?.getImage(_categoriesDropDownVisible ? 'chevron-up' : 'chevron-down'))
                  ])))
        ]));
  }

  Widget _buildCategoryDropDown() {
    List<Widget> widgetList = <Widget>[];
    if (CollectionUtils.isNotEmpty(_categories)) {
      widgetList.add(Container(color: Styles().colors!.fillColorSecondary, height: 2));
      widgetList.add(_buildCategoryItem(null)); // "None"
      widgetList.add(_buildCategoryItem(ToDoCategory())); // "Create a Category"
      for (ToDoCategory category in _categories!) {
        widgetList.add(_buildCategoryItem(category));
      }
    }
    return Visibility(
        visible: _categoriesDropDownVisible, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgetList));
  }

  Widget _buildCategoryItem(ToDoCategory? category) {
    bool isSelected = (category == _category);
    late String categoryName;
    if (category == null) {
      categoryName = Localization().getStringEx('panel.wellness.todo.item.category.none.label', 'None');
    } else if (category.id == null) {
      categoryName = Localization().getStringEx('panel.wellness.todo.item.category.create.label', 'Create a Category');
    } else {
      categoryName = category.name!;
    }
    BorderSide borderSide = BorderSide(color: Styles().colors!.fillColorPrimary!, width: 1);
    return GestureDetector(
        onTap: () => _onTapCategory(category),
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, border: Border(left: borderSide, right: borderSide, bottom: borderSide)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(StringUtils.ensureNotEmpty(categoryName),
                  style: Styles().textStyles?.getTextStyle("panel.wellness.todo.item_detail.item")),
              Styles().images?.getImage(isSelected ? 'radio-button-on' : 'radio-button-off') ?? Container()
            ])));
  }

  Widget _buildDueDateContainer() {
    return Padding(
        padding: EdgeInsets.only(top: 17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: _buildFieldLabel(label: Localization().getStringEx('panel.wellness.todo.item.due_date.field.label', 'DUE DATE'))),
          GestureDetector(
              onTap: _onTapDueDate,
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  decoration:
                      BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text(StringUtils.ensureNotEmpty(_formattedDueDate),
                        style: Styles().textStyles?.getTextStyle("panel.wellness.todo.item_detail.title")),
                    Expanded(child: Container()),
                    Styles().images?.getImage('calendar', excludeFromSemantics: true) ?? Container(),
                  ])))
        ]));
  }

  Widget _buildDueTimeContainer() {
    return Visibility(
        visible: (_dueDate != null),
        child: Padding(
            padding: EdgeInsets.only(top: 17),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: EdgeInsets.only(bottom: 5),
                  child: _buildFieldLabel(label: Localization().getStringEx('panel.wellness.todo.item.due_time.field.label', 'TIME DUE'))),
              GestureDetector(
                  onTap: _onTapDueTime,
                  child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      decoration:
                          BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Text(StringUtils.ensureNotEmpty(_formattedDueTime),
                            style: Styles().textStyles?.getTextStyle("panel.wellness.todo.item_detail.title")),
                        Expanded(child: Container())
                      ])))
            ])));
  }

  Widget _buildSelectedReminderTypeContainer() {
    String? selectedTypeLabel = _getReminderTypeLabel(_selectedReminderType);
    return Padding(
        padding: EdgeInsets.only(top: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: _buildFieldLabel(label: Localization().getStringEx('panel.wellness.todo.item.reminder.field.label', 'REMINDER'))),
          GestureDetector(
              onTap: _onTapSelectedReminderType,
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  decoration:
                      BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text(StringUtils.ensureNotEmpty(selectedTypeLabel),
                        overflow: TextOverflow.ellipsis,
                        style: Styles().textStyles?.getTextStyle("panel.wellness.todo.item_detail.title")),
                    Expanded(child: Container()),
                    Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Styles().images?.getImage(_reminderTypeDropDownValuesVisible ? 'chevron-up' : 'chevron-down'))
                  ])))
        ]));
  }

  Widget _buildReminderTypeDropDown() {
    return Visibility(
        visible: _reminderTypeDropDownValuesVisible,
        child: Positioned.fill(
            child: Stack(children: <Widget>[_buildReminderTypeDropDownDismissLayer(), _buildReminderTypeDropDownItemsWidget()])));
  }

  Widget _buildReminderTypeDropDownDismissLayer() {
    return Positioned.fill(
        child: BlockSemantics(
            child: GestureDetector(
                onTap: () {
                  setState(() {
                    _reminderTypeDropDownValuesVisible = false;
                  });
                },
                child: Container(color: Colors.transparent))));
  }

  Widget _buildReminderTypeDropDownItemsWidget() {
    List<Widget> sectionList = <Widget>[];
    sectionList.add(Container(color: Styles().colors!.fillColorSecondary, height: 2));
    for (ToDoReminderType type in ToDoReminderType.values) {
      sectionList.add(_buildReminderTypeItem(type));
    }
    return Column(children: sectionList);
  }

  Widget _buildReminderTypeItem(ToDoReminderType type) {
    bool isSelected = (type == _selectedReminderType);
    BorderSide borderSide = BorderSide(color: Styles().colors!.fillColorPrimary!, width: 1);
    return GestureDetector(
        onTap: () => _onTapReminderType(type),
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            height: 48,
            decoration: BoxDecoration(color: Colors.white, border: Border(left: borderSide, right: borderSide, bottom: borderSide)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(StringUtils.ensureNotEmpty(_getReminderTypeLabel(type)),
                  style: Styles().textStyles?.getTextStyle("panel.wellness.todo.item_detail.item")),
              Styles().images?.getImage(isSelected ? 'radio-button-on' : 'radio-button-off', excludeFromSemantics: true) ?? Container()
            ])));
  }

  Widget _buildWorkDaysContainer() {
    return Padding(
        padding: EdgeInsets.only(top: 17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: _buildFieldLabel(label: Localization().getStringEx('panel.wellness.todo.item.work_days.field.label', 'DAYS TO WORK ON ITEM'))),
          GestureDetector(
              onTap: _onTapWorkDays,
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: (CollectionUtils.isEmpty(_workDays) ? 24 : 12)),
                  decoration:
                      BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
                  child: Row(children: [
                    Expanded(
                        child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: _buildWorkDaysWidgetList())))
                  ])))
        ]));
  }

  List<Widget> _buildWorkDaysWidgetList() {
    List<Widget> widgetList = <Widget>[];
    if (_workDays != null) {
      for (DateTime date in _workDays!) {
        widgetList.add(Padding(padding: EdgeInsets.only(left: 5), child: _buildWorkDayWidget(date: date)));
      }
    }
    return widgetList;
  }

  Widget _buildWorkDayWidget({required DateTime date}) {
    return Padding(
        padding: EdgeInsets.only(left: 5),
        child: Container(
            decoration: BoxDecoration(color: Styles().colors!.lightGray),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text(StringUtils.ensureNotEmpty(AppDateTime().formatDateTime(date, format: 'EEEE, MM/dd', ignoreTimeZone: true)),
                      style: Styles().textStyles?.getTextStyle("panel.wellness.todo.item_detail.work_date"))),
              GestureDetector(
                  onTap: () => _onTapRemoveWorkDay(date),
                  child: Container(
                      color: Styles().colors!.lightGray,
                      child: Padding(
                          padding: EdgeInsets.only(left: 25, top: 7, right: 10, bottom: 7),
                          child: Styles().images?.getImage('close', excludeFromSemantics: true))))
            ])));
  }

  Widget _buildLocationContainer() {
    return Padding(
        padding: EdgeInsets.only(top: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: _buildFieldLabel(label: Localization().getStringEx('panel.wellness.todo.item.location.field.label', 'LOCATION'))),
          _buildInputField(controller: _locationController)
        ]));
  }

  Widget _buildDescriptionContainer() {
    return Padding(
        padding: EdgeInsets.only(top: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child:
                  _buildFieldLabel(label: Localization().getStringEx('panel.wellness.todo.item.description.field.label', 'DESCRIPTION'))),
          _buildInputField(controller: _descriptionController)
        ]));
  }

  Widget _buildFieldLabel({required String label}) {
    return Text(label, style: Styles().textStyles?.getTextStyle("panel.wellness.todo.item_detail.empty"));
  }

  Widget _buildInputField({required TextEditingController controller}) {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
        child: TextField(
            controller: controller,
            decoration: InputDecoration(border: InputBorder.none),
            style:  Styles().textStyles?.getTextStyle("panel.wellness.todo.item_detail.title")));
  }

  Widget _buildSaveButton() {
    bool hasItemForEdit = (_item != null);
    return Center(
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
              Flexible(flex: (hasItemForEdit ? 1 : 0), child: Visibility(visible: hasItemForEdit, child: RoundedButton(
                label: Localization().getStringEx('panel.wellness.todo.item.delete.button', 'Delete'),
                borderColor: Styles().colors!.fillColorPrimary,
                contentWeight: (hasItemForEdit ? 1 : 0),
                padding: EdgeInsets.symmetric(horizontal: 46, vertical: 8),
                onTap: _onTapDelete))),
              Visibility(visible: hasItemForEdit, child: Container(width: 15)),
              Flexible(flex: (hasItemForEdit ? 1 : 0), child: RoundedButton(
                label: Localization().getStringEx('panel.wellness.todo.item.save.button', 'Save'),
                contentWeight: (hasItemForEdit ? 1 : 0),
                padding: EdgeInsets.symmetric(horizontal: 46, vertical: 8),
                onTap: _onTapSave))
            ])));
  }

  void _onTapOptionalFields() {
    Analytics().logSelect(target: 'Optional Fields');
    _hideKeyboard();
    _optionalFieldsVisible = !_optionalFieldsVisible;
    if (_optionalFieldsVisible == false) {
      _categoriesDropDownVisible = false;
    }
    _updateState();
  }

  void _onTapCurrentCategory() {
    Analytics().logSelect(target: 'Categories Dropdown');
    _hideKeyboard();
    _categoriesDropDownVisible = !_categoriesDropDownVisible;
    _updateState();
  }

  void _onTapCategory(ToDoCategory? category) {
    _hideKeyboard();
    if ((category != null) && (category.id == null)) {
      Analytics().logSelect(target: 'Create a Category');
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessManageToDoCategoriesPanel()));
    } else if (_category != category) {
      Analytics().logSelect(target: 'Category: ${category?.name}');
      _category = category;
    }
    _categoriesDropDownVisible = !_categoriesDropDownVisible;
    _updateState();
  }

  void _onTapSelectedReminderType() {
    Analytics().logSelect(target: 'Reminder Types Dropdown');
    _hideKeyboard();
    _reminderTypeDropDownValuesVisible = !_reminderTypeDropDownValuesVisible;
    _updateState();
  }

  void _onTapReminderType(ToDoReminderType type) {
    Analytics().logSelect(target: 'Reminder Type: $type');
    _hideKeyboard();
    if (_reminderTypeDropDownValuesVisible) {
      _reminderTypeDropDownValuesVisible = false;
    }
    _selectedReminderType = type;
    _populateReminderDateTime();
    _updateState();
  }

  void _onTapDueDate() async {
    Analytics().logSelect(target: 'Due Date');
    _hideKeyboard();
    DateTime? resultDate = await _pickDate();
    if (resultDate != null) {
      _dueDate = resultDate;
      if (_selectedReminderType != ToDoReminderType.specific_time) {
        _populateReminderDateTime();
      }
      _updateState();
    }
  }

  void _onTapDueTime() async {
    Analytics().logSelect(target: 'Due Time');
    if (_dueDate == null) {
      return;
    }
    _hideKeyboard();
    TimeOfDay? resultTime = await _pickTime();
    if (resultTime != null) {
      _dueTime = resultTime;
      _updateState();
    }
  }

  void _onTapWorkDays() async {
    Analytics().logSelect(target: 'Workdays');
    DateTime? resultDate = await _pickDate();
    if ((resultDate != null) && !(_workDays?.contains(resultDate) ?? false)) {
      if (_workDays == null) {
        _workDays = <DateTime>[];
      }
      _workDays!.add(resultDate);
      _workDays!.sort();
      _updateState();
    }
  }

  void _onTapRemoveWorkDay(DateTime date) {
    Analytics().logSelect(target: 'Remove Workday');
    if (_workDays?.contains(date) ?? false) {
      _workDays!.remove(date);
      _updateState();
    }
  }

  Future<DateTime?> _pickDate() async {
    final DateTime initialDate = DateTime.now();
    final int oneYearInDays = 365;
    DateTime firstDate = DateTime.fromMillisecondsSinceEpoch(initialDate.subtract(Duration(days: oneYearInDays)).millisecondsSinceEpoch);
    DateTime lastDate = DateTime.fromMillisecondsSinceEpoch(initialDate.add(Duration(days: oneYearInDays)).millisecondsSinceEpoch);
    DateTime? resultDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        builder: (BuildContext context, Widget? child) {
          return Theme(data: ThemeData.light(), child: child!);
        });
    return resultDate;
  }

  Future<TimeOfDay?> _pickTime() async {
    TimeOfDay initialTime = TimeOfDay.now();
    return await showTimePicker(context: context, initialTime: initialTime);
  }

  void _onTapDelete() {
    Analytics().logSelect(target: 'Delete');
    if (_item == null) {
      AppAlert.showDialogResult(
          context, Localization().getStringEx('panel.wellness.todo.item.delete.no_item.msg', 'There is no selected item to delete.'));
      return;
    }

    AppAlert.showConfirmationDialog(
        buildContext: context,
        message: Localization()
            .getStringEx('panel.wellness.todo.item.delete.confirmation.msg', 'Are sure that you want to delete this To-Do item?'),
        positiveCallback: () => _deleteToDoItem());
  }

  void _deleteToDoItem() {
    _increaseProgress();
    Analytics().logWellnessToDo(
      action: Analytics.LogWellnessActionClear,
      item: _item,
    );
    Wellness().deleteToDoItem(_item!.id!).then((success) {
      late String msg;
      if (success) {
        msg = Localization().getStringEx('panel.wellness.todo.item.delete.succeeded.msg', 'To-Do item deleted successfully.');
      } else {
        msg = Localization().getStringEx('panel.wellness.todo.item.delete.failed.msg', 'Failed to delete To-Do item.');
      }
      AppAlert.showDialogResult(context, msg).then((_) {
        if (success) {
          Navigator.of(context).pop();
        }
      });
      _decreaseProgress();
    });
  }

  void _onTapSave() {
    Analytics().logSelect(target: 'Save');
    _hideKeyboard();
    String name = _nameController.text;
    if (StringUtils.isEmpty(name)) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.wellness.todo.item.empty.name.msg', 'Please, fill name.'));
      return;
    }
    _increaseProgress();
    bool hasDueTime = false;
    if (_dueDate != null) {
      if (_dueTime != null) {
        hasDueTime = true;
        _dueDate = DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day, _dueTime!.hour, _dueTime!.minute);
      }
    }
    String? location = StringUtils.isNotEmpty(_locationController.text) ? _locationController.text : null;
    String? description = StringUtils.isNotEmpty(_descriptionController.text) ? _descriptionController.text : null;
    ToDoItem itemToSave = ToDoItem(
        id: _item?.id,
        name: name,
        category: _category,
        dueDateTimeUtc: _dueDate?.toUtc(),
        hasDueTime: hasDueTime,
        location: location,
        isCompleted: _item?.isCompleted ?? false,
        description: description,
        workDays: _formattedWorkDays,
        reminderType: _selectedReminderType,
        reminderDateTimeUtc: _reminderDateTime?.toUtc());

    Analytics().logWellnessToDo(
      action: (_item?.id == null) ? Analytics.LogWellnessActionCreate : Analytics.LogWellnessActionUpdate,
      item: itemToSave,
    );

    if (_item?.id != null) {
      Wellness().updateToDoItem(itemToSave).then((success) {
        _onSaveCompleted(success);
      });
    } else {
      Wellness().createToDoItem(itemToSave).then((success) {
        _onSaveCompleted(success);
      });
    }
  }

  void _onSaveCompleted(bool success) {
    late String msg;
      if (success) {
        msg = Localization().getStringEx('panel.wellness.todo.item.save.succeeded.msg', 'To-Do item saved successfully.');
      } else {
        msg = Localization().getStringEx('panel.wellness.todo.item.save.failed.msg', 'Failed to save To-Do item.');
      }
      AppAlert.showDialogResult(context, msg).then((_) {
        if (success) {
          Navigator.of(context).pop();
        }
      });
      _decreaseProgress();
  }

  void _loadCategories() {
    _increaseProgress();
    Wellness().loadToDoCategories().then((categories) {
      _categories = categories;
      _decreaseProgress();
    });
  }

  void _loadToDoItem() {
    _increaseProgress();
    Wellness().loadToDoItem(widget.itemId).then((item) {
      _item = item;
      if (_item != null) {
        _populateItemFields();
      } else {
        _selectedReminderType = ToDoReminderType.none;
      }
      _decreaseProgress();
    });
  }

  void _populateItemFields() {
    _category = _item?.category;
    _nameController.text = StringUtils.ensureNotEmpty(_item?.name);
    _descriptionController.text = StringUtils.ensureNotEmpty(_item?.description);
    _locationController.text = StringUtils.ensureNotEmpty(_item?.location);
    _selectedReminderType = _item?.reminderType ?? ToDoReminderType.none;
    _dueDate = _item?.dueDateTime;
    _reminderDateTime = _item?.reminderDateTime;
    if ((_dueDate != null) && (_item?.hasDueTime ?? false) == true) {
      _dueTime = TimeOfDay(hour: _dueDate!.hour, minute: _dueDate!.minute);
    }
    if (CollectionUtils.isNotEmpty(_item?.workDays)) {
      _workDays = <DateTime>[];
      for (String dateString in _item!.workDays!) {
        DateTime? workDate = DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(dateString), format: _workDayFormat, isUtc: false);
        if (workDate != null) {
          _workDays!.add(workDate);
        }
      }
    }
  }

  void _populateReminderDateTime() async {
    if (_dueDate == null) {
      _reminderDateTime = null;
      return;
    }
    switch (_selectedReminderType) {
      case ToDoReminderType.none:
        _reminderDateTime = null;
        break;
      case ToDoReminderType.morning_of:
        _reminderDateTime = DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day, 8); // 8:00 AM in the morning
        break;
      case ToDoReminderType.night_before:
        _reminderDateTime =
            DateTime(_dueDate!.year, _dueDate!.month, (_dueDate!.day), 21).subtract(Duration(days: 1)); // 9:00 PM the night before
        break;
      case ToDoReminderType.specific_time:
        TimeOfDay? pickedTime = await _pickTime();
        if (pickedTime == null) {
          return;
        }
        _reminderDateTime = DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day, pickedTime.hour, pickedTime.minute);
        break;
      default:
        _reminderDateTime = null;
        break;
    }
  }

  void _increaseProgress() {
    setStateIfMounted(() {
      _loadingProgress++;
    });
  }

  void _decreaseProgress() {
    setStateIfMounted(() {
      _loadingProgress--;
    });
  }

  bool get _isLoading {
    return (_loadingProgress > 0);
  }

  void _hideKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  String? _getReminderTypeLabel(ToDoReminderType? type) {
    String? typeLabel = ToDoItem.reminderTypeToDisplayString(type);
    if ((type == ToDoReminderType.specific_time) && (_reminderDateTime != null)) {
      typeLabel = typeLabel! + ' (${AppDateTime().formatDateTime(_reminderDateTime, format: 'h:mm a', ignoreTimeZone: true)})';
    }
    return typeLabel;
  }

  String? get _formattedDueDate {
    return AppDateTime().formatDateTime(_dueDate, format: 'MM/dd/yy', ignoreTimeZone: true);
  }

  String? get _formattedDueTime {
    if ((_dueDate == null) || (_dueTime == null)) {
      return null;
    }
    DateTime time = DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day, _dueTime!.hour, _dueTime!.minute);
    return AppDateTime().formatDateTime(time, format: 'h:mm a', ignoreTimeZone: true);
  }

  List<String>? get _formattedWorkDays {
    if (CollectionUtils.isEmpty(_workDays)) {
      return null;
    }
    List<String> stringList = <String>[];
    for (DateTime day in _workDays!) {
      String? formattedWorkDay = AppDateTime().formatDateTime(day, format: _workDayFormat, ignoreTimeZone: true);
      if (StringUtils.isNotEmpty(formattedWorkDay)) {
        stringList.add(formattedWorkDay!);
      }
    }
    return stringList;
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == Wellness.notifyToDoCategoryChanged) {
      _loadCategories();
    } else if (name == Wellness.notifyToDoCategoryDeleted) {
      _loadCategories();
    }
  }
}
