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
import 'package:neom/model/Analytics.dart';
import 'package:neom/model/wellness/WellnessToDo.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/AppDateTime.dart';
import 'package:neom/service/Wellness.dart';
import 'package:neom/ui/wellness/todo/WellnessManageToDoCategoriesPanel.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:neom/ui/widgets/TabBar.dart' as uiuc;
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:weekday_selector/weekday_selector.dart';

class WellnessToDoItemDetailPanel extends StatefulWidget  with AnalyticsInfo {
  final String? itemId;
  final WellnessToDoItem? item;
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

  WellnessToDoItem? _item;
  WellnessToDoCategory? _category;
  List<WellnessToDoCategory>? _categories;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  DateTime? _endDate;
  WellnessToDoReminderType? _selectedReminderType;
  DateTime? _reminderDateTime;
  List<DateTime>? _workDays;
  late bool _optionalFieldsVisible;
  bool _reminderTypeDropDownValuesVisible = false;
  bool _categoriesDropDownVisible = false;
  int _loadingProgress = 0;
  List<bool> _weekdayValues = [false, false, false, false, false, false, false];

  final List<String> _recurringTypes = ["Does not repeat", "Daily",
    "Weekly", "Monthly", "Weekdays"];
  String? _selectedRecurringType = "Does not repeat";

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
        _selectedReminderType = WellnessToDoReminderType.none;
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
      backgroundColor: Styles().colors.background,
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
                _buildRecurringContainer(),
                _buildWeekdaySelectorContainer(),
                _buildDueDateContainer(),
                _buildEndDateContainer(),
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
            style: Styles().textStyles.getTextStyle("widget.title.regular.fat")));
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
                  Container(height: 1, color: Styles().colors.mediumGray2),
                  Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Text(Localization().getStringEx('panel.wellness.todo.item.optional_fields.label', 'Optional Fields'),
                            style: Styles().textStyles.getTextStyle("widget.title.small.fat")),
                        Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Styles().images.getImage(_optionalFieldsVisible ? 'chevron-up' : 'chevron-down', excludeFromSemantics: true))
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
                      BoxDecoration(color: Styles().colors.surface, border: Border.all(color: Styles().colors.mediumGray, width: 1)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text(
                        StringUtils.ensureNotEmpty(_category?.name,
                            defaultValue: Localization().getStringEx('panel.wellness.todo.item.category.none.label', 'None')),
                        overflow: TextOverflow.ellipsis,
                        style:Styles().textStyles.getTextStyle("panel.wellness.todo.item_detail.title")),
                    Expanded(child: Container()),
                    Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Styles().images.getImage(_categoriesDropDownVisible ? 'chevron-up' : 'chevron-down'))
                  ])))
        ]));
  }

  Widget _buildCategoryDropDown() {
    List<Widget> widgetList = <Widget>[];
    if (CollectionUtils.isNotEmpty(_categories)) {
      widgetList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));
      widgetList.add(_buildCategoryItem(null)); // "None"
      widgetList.add(_buildCategoryItem(WellnessToDoCategory())); // "Create a Category"
      for (WellnessToDoCategory category in _categories!) {
        widgetList.add(_buildCategoryItem(category));
      }
    }
    return Visibility(
        visible: _categoriesDropDownVisible, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgetList));
  }

  Widget _buildCategoryItem(WellnessToDoCategory? category) {
    bool isSelected = (category == _category);
    late String categoryName;
    if (category == null) {
      categoryName = Localization().getStringEx('panel.wellness.todo.item.category.none.label', 'None');
    } else if (category.id == null) {
      categoryName = Localization().getStringEx('panel.wellness.todo.item.category.create.label', 'Create a Category');
    } else {
      categoryName = category.name!;
    }
    BorderSide borderSide = BorderSide(color: Styles().colors.fillColorPrimary, width: 1);
    return GestureDetector(
        onTap: () => _onTapCategory(category),
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, border: Border(left: borderSide, right: borderSide, bottom: borderSide)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(StringUtils.ensureNotEmpty(categoryName),
                  style: Styles().textStyles.getTextStyle("panel.wellness.todo.item_detail.item")),
              Styles().images.getImage(isSelected ? 'radio-button-on' : 'radio-button-off') ?? Container()
            ])));
  }

  Widget _buildDueDateContainer() {
    return Padding(
        padding: EdgeInsets.only(top: 17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: _buildFieldLabel(label:  _selectedRecurringType == "Does not repeat" ? Localization().getStringEx('panel.wellness.todo.item.due_date.field.label', 'DUE DATE') : Localization().getStringEx('panel.wellness.todo.item.start_date.field.label', 'START DATE') )),
          GestureDetector(
              onTap: _onTapDueDate,
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  decoration:
                      BoxDecoration(color: Styles().colors.surface, border: Border.all(color: Styles().colors.mediumGray, width: 1)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text(StringUtils.ensureNotEmpty(_formattedDueDate),
                        style: Styles().textStyles.getTextStyle("panel.wellness.todo.item_detail.title")),
                    Expanded(child: Container()),
                    Styles().images.getImage('calendar', excludeFromSemantics: true) ?? Container(),
                  ])))
        ]));
  }

  Widget _buildEndDateContainer() {
    return Visibility(
        visible: _selectedRecurringType != "Does not repeat",
        child: Padding(
            padding: EdgeInsets.only(top: 17),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: EdgeInsets.only(bottom: 5),
                  child: _buildFieldLabel(label: Localization().getStringEx('panel.wellness.todo.item.end_date.field.label', 'END DATE'))),
              GestureDetector(
                  onTap: _onTapEndDate,
                  child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      decoration:
                      BoxDecoration(color: Styles().colors.surface, border: Border.all(color: Styles().colors.mediumGray, width: 1)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Text(StringUtils.ensureNotEmpty(_formattedEndDate),
                            style: Styles().textStyles.getTextStyle("panel.wellness.todo.item_detail.title")),
                        Expanded(child: Container()),
                        Styles().images.getImage('calendar', excludeFromSemantics: true) ?? Container(),
                      ])))
            ])
        )
    );
  }

  Widget _buildWeekdaySelectorContainer(){
    return Visibility(
        visible: _selectedRecurringType == "Weekdays",
        child: Padding(
            padding: EdgeInsets.only(top: 17),
            child: WeekdaySelector(
              color:  Styles().colors.mediumGray,
              selectedFillColor: Styles().colors.fillColorPrimary,
              selectedColor: Styles().colors.fillColorSecondary,
              onChanged: (int day) {
                setState(() {
                  final index = day % 7;
                  _weekdayValues[index] = !_weekdayValues[index];
                });
              },
              values: _weekdayValues,
            )
        )
    );
  }

  Widget _buildRecurringContainer(){
    return Padding(
      padding: EdgeInsets.only(top: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: _buildFieldLabel(label: Localization().getStringEx('', 'RECURRENCE TYPE'))),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Styles().colors.mediumGray, width: 1),
              color: Styles().colors.surface,
            ),
            child: Padding(
              padding: EdgeInsets.only(right: 5, left: 5),
              child: DropdownButton(
                  value: _selectedRecurringType,
                  dropdownColor: Styles().colors.surface,
                  isExpanded: true,
                  icon: Styles().images.getImage(_reminderTypeDropDownValuesVisible ? 'chevron-up' : 'chevron-down'),
                  style: Styles().textStyles.getTextStyle("panel.wellness.todo.item_detail.title"),
                  items: DropdownBuilder.getItems(_recurringTypes, style: Styles().textStyles.getTextStyle("panel.wellness.todo.item_detail.title")),
                  onChanged: (String? selected) {
                    setState(() {
                      _selectedRecurringType = selected;
                    });
                  }
              ),
            ),
          ),
        ],
      ),
    );
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
                          BoxDecoration(color: Styles().colors.surface, border: Border.all(color: Styles().colors.mediumGray, width: 1)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Text(StringUtils.ensureNotEmpty(_formattedDueTime),
                            style: Styles().textStyles.getTextStyle("panel.wellness.todo.item_detail.title")),
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
                      BoxDecoration(color: Styles().colors.surface, border: Border.all(color: Styles().colors.mediumGray, width: 1)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text(StringUtils.ensureNotEmpty(selectedTypeLabel),
                        overflow: TextOverflow.ellipsis,
                        style: Styles().textStyles.getTextStyle("panel.wellness.todo.item_detail.title")),
                    Expanded(child: Container()),
                    Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Styles().images.getImage(_reminderTypeDropDownValuesVisible ? 'chevron-up' : 'chevron-down'))
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
    sectionList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));
    for (WellnessToDoReminderType type in WellnessToDoReminderType.values) {
      sectionList.add(_buildReminderTypeItem(type));
    }
    return Column(children: sectionList);
  }

  Widget _buildReminderTypeItem(WellnessToDoReminderType type) {
    bool isSelected = (type == _selectedReminderType);
    BorderSide borderSide = BorderSide(color: Styles().colors.fillColorPrimary, width: 1);
    return GestureDetector(
        onTap: () => _onTapReminderType(type),
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            height: 48,
            decoration: BoxDecoration(color: Colors.white, border: Border(left: borderSide, right: borderSide, bottom: borderSide)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(StringUtils.ensureNotEmpty(_getReminderTypeLabel(type)),
                  style: Styles().textStyles.getTextStyle("panel.wellness.todo.item_detail.item")),
              Styles().images.getImage(isSelected ? 'radio-button-on' : 'radio-button-off', excludeFromSemantics: true) ?? Container()
            ])));
  }

  Widget _buildWorkDaysContainer() {
    return _hideWorkDays ? Container() :
      Padding(
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
                      BoxDecoration(color: Styles().colors.surface, border: Border.all(color: Styles().colors.mediumGray, width: 1)),
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
            decoration: BoxDecoration(color: Styles().colors.lightGray),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text(StringUtils.ensureNotEmpty(AppDateTime().formatDateTime(date, format: 'EEEE, MM/dd', ignoreTimeZone: true)),
                      style: Styles().textStyles.getTextStyle("panel.wellness.todo.item_detail.work_date"))),
              GestureDetector(
                  onTap: () => _onTapRemoveWorkDay(date),
                  child: Container(
                      color: Styles().colors.lightGray,
                      child: Padding(
                          padding: EdgeInsets.only(left: 25, top: 7, right: 10, bottom: 7),
                          child: Styles().images.getImage('close-circle', excludeFromSemantics: true))))
            ])));
  }

  Widget _buildLocationContainer() {
    return _hideLocation ? Container() :
      Padding(
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
    return Text(label, style: Styles().textStyles.getTextStyle("panel.wellness.todo.item_detail.empty"));
  }

  Widget _buildInputField({required TextEditingController controller}) {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: Styles().colors.surface, border: Border.all(color: Styles().colors.mediumGray, width: 1)),
        child: TextField(
            controller: controller,
            decoration: InputDecoration(border: InputBorder.none),
            style:  Styles().textStyles.getTextStyle("panel.wellness.todo.item_detail.title")));
  }

  Widget _buildSaveButton() {
    bool hasItemForEdit = (_item != null);
    return Center(
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
              Flexible(flex: (hasItemForEdit ? 1 : 0), child: Visibility(visible: hasItemForEdit, child: RoundedButton(
                label: Localization().getStringEx('panel.wellness.todo.item.delete.button', 'Delete'),
                borderColor: Styles().colors.fillColorPrimary,
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

  void _onTapCategory(WellnessToDoCategory? category) {
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

  void _onTapReminderType(WellnessToDoReminderType type) {
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
      if (_selectedReminderType != WellnessToDoReminderType.specific_time) {
        _populateReminderDateTime();
      }
      _updateState();
    }
  }

  void _onTapEndDate() async {
    Analytics().logSelect(target: 'End Date');
    _hideKeyboard();
    DateTime? resultDate = await _pickDate();
    if (resultDate != null) {
      _endDate = resultDate;
      if (_selectedReminderType != WellnessToDoReminderType.specific_time) {
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

        if(_endDate != null){
          _endDate = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, _dueTime!.hour, _dueTime!.minute);
        }
      }
    }
    String? location = StringUtils.isNotEmpty(_locationController.text) ? _locationController.text : null;
    String? description = StringUtils.isNotEmpty(_descriptionController.text) ? _descriptionController.text : null;
    WellnessToDoItem? itemToSave = WellnessToDoItem(
          id: _item?.id,
          name: name,
          category: _category,
          dueDateTimeUtc: _dueDate?.toUtc(),
          endDateTimeUtc: _endDate?.toUtc(),
          hasDueTime: hasDueTime,
          location: location,
          isCompleted: _item?.isCompleted ?? false,
          description: description,
          workDays: _formattedWorkDays,
          reminderType: _selectedReminderType,
          recurrenceType: _generateCronExpressionFromString(),
          recurrenceId: _item?.recurrenceId,
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
      // });
    }
  }

  String _generateCronExpressionFromString(){
      switch(_selectedRecurringType){
        case "Daily":{
          return "0 " + (_dueTime?.minute.toString() ?? "0") + " " + (_dueTime?.hour.toString() ?? "0") + " ? * * *";
        }
        case "Does not repeat":{
          return "none";
        }
        case "Weekly":{
          return "0 " + (_dueTime?.minute.toString() ?? "0") + " " + (_dueTime?.hour.toString() ?? "0") + " ? * " + (_getWeekdayFromCode(_dueDate?.weekday ?? 0)) + " *";
        }
        case "Monthly":{
          return "0 " + (_dueTime?.minute.toString() ?? "0") + " " + (_dueTime?.hour.toString() ?? "0") + " " +(_dueDate?.day.toString() ?? "0") + " * ? *";
        }
        case "Annually":{
          return "0 " + (_dueTime?.minute.toString() ?? "0") + " " + (_dueTime?.hour.toString() ?? "0") + " " + (_dueDate?.day.toString() ?? "0") + " " + (_getMonthFromCode(_dueDate?.month ?? 0)) + " ? *";
        }
        case "Weekdays":{
          return "0 " + (_dueTime?.minute.toString() ?? "0") + " " + (_dueTime?.hour.toString() ?? "0") + " ? * " + _selectedWeekdaysToCron() + " *";
        }
        default:{
          return "0 0 0 ? * * *";
        }
      }

  }

  String _selectedWeekdaysToCron(){
    String weekdayString = "";
    for(int i =0; i<_weekdayValues.length; i++){
      if(_weekdayValues[i]){
        weekdayString = weekdayString + _getWeekdayFromCode(i) + ",";
      }
    }

    return weekdayString.substring(0, weekdayString.length-1);
  }

  String _generateStringFromCronExpression(String cron){
    if(cron.isEmpty || cron == "none"){
      return "Does not repeat";
    }else{
      if(cron.substring((cron.length) -5, (cron.length)) == "* * *"){
        return "Daily";
      }else if(cron.substring(cron.length -5, cron.length) == "* ? *"){
        return "Monthly";
      }else{
        // String daysString = cron.substring(11, cron.length-2);
        List<String> daysStringList  = cron.split(" ");
        if(daysStringList[5].length == 3){
          return "Weekly";
        }else{
          List<String> dayStrings = daysStringList[5].split(",");
          _determineHighlightedDays(dayStrings);
          return "Weekdays";
        }
      }

    }

  }

  void _determineHighlightedDays(List<String> days){
    for(String day in days){
      _weekdayValues[_convertDayString(day)] = !_weekdayValues[_convertDayString(day)];
    }
  }

  String _getWeekdayFromCode(int dayCode){
    switch(dayCode){
      case 1:
        return "MON";
      case 2:
        return "TUE";
      case 3:
        return "WED";
      case 4:
        return "THU";
      case 5:
        return "FRI";
      case 6:
        return "SAT";
      case 7:
      case 0:
        return "SUN";
      default:
        return "*";
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
        return 0;
      default:
        return -1;

    }
  }

  String _getMonthFromCode(int dayCode){
    switch(dayCode){
      case 1:{
        return "JAN";
      }
      case 2:{
        return "FEB";
      }
      case 3:{
        return "MAR";
      }
      case 4:{
        return "APR";
      }
      case 5:{
        return "MAY";
      }
      case 6:{
        return "JUN";
      }
      case 7:{
        return "JUL";
      }
      case 8:{
        return "AUG";
      }
      case 9:{
        return "SEP";
      }
      case 10:{
        return "OCT";
      }
      case 11:{
        return "NOV";
      }
      case 12:{
        return "DEC";
      }
      default:
        return "*";
    }
  }

  void _onSaveCompleted(bool success) {
    //Unused: late String msg;
      _decreaseProgress();
    Navigator.of(context).pop();
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
        _selectedReminderType = WellnessToDoReminderType.none;
      }
      _decreaseProgress();
    });
  }

  void _populateItemFields() {
    _category = _item?.category;
    _nameController.text = StringUtils.ensureNotEmpty(_item?.name);
    _descriptionController.text = StringUtils.ensureNotEmpty(_item?.description);
    _locationController.text = StringUtils.ensureNotEmpty(_item?.location);
    _selectedReminderType = _item?.reminderType ?? WellnessToDoReminderType.none;
    _dueDate = _item?.dueDateTime;
    _reminderDateTime = _item?.reminderDateTime;
    _selectedRecurringType = _generateStringFromCronExpression(_item?.recurrenceType ?? "");
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
      case WellnessToDoReminderType.none:
        _reminderDateTime = null;
        break;
      case WellnessToDoReminderType.morning_of:
        _reminderDateTime = DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day, 8); // 8:00 AM in the morning
        break;
      case WellnessToDoReminderType.night_before:
        _reminderDateTime =
            DateTime(_dueDate!.year, _dueDate!.month, (_dueDate!.day), 21).subtract(Duration(days: 1)); // 9:00 PM the night before
        break;
      case WellnessToDoReminderType.specific_time:
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

  String? _getReminderTypeLabel(WellnessToDoReminderType? type) {
    String? typeLabel = WellnessToDoItem.reminderTypeToDisplayString(type);
    if ((type == WellnessToDoReminderType.specific_time) && (_reminderDateTime != null)) {
      typeLabel = typeLabel! + ' (${AppDateTime().formatDateTime(_reminderDateTime, format: 'h:mm a', ignoreTimeZone: true)})';
    }
    return typeLabel;
  }

  String? get _formattedDueDate {
    return AppDateTime().formatDateTime(_dueDate, format: 'MM/dd/yy', ignoreTimeZone: true);
  }

  String? get _formattedEndDate {
    return AppDateTime().formatDateTime(_endDate, format: 'MM/dd/yy', ignoreTimeZone: true);
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

  bool get _hideLocation => true; //TBD remove field if we are not going to show it anymore

  bool get _hideWorkDays => true; //TBD remove field if we are not going to show it anymore

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


class DropdownBuilder {
  static List<DropdownMenuItem<T>> getItems<T>(List<T> options, {String? nullOption, TextStyle? style}) {
    List<DropdownMenuItem<T>> dropDownItems = <DropdownMenuItem<T>>[];
    if (nullOption != null) {
      dropDownItems.add(DropdownMenuItem(value: null, child: Text(nullOption, style: style ?? Styles().textStyles.getTextStyle("widget.detail.regular"))));
    }
    for (T option in options) {
      dropDownItems.add(DropdownMenuItem(value: option, child: Text(option.toString(), style: style ?? Styles().textStyles.getTextStyle("widget.detail.regular"))));
    }
    return dropDownItems;
  }
}
