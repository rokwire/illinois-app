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

import 'package:flutter/material.dart';
import 'package:illinois/model/wellness/ToDo.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class WellnessManageToDoCategoriesPanel extends StatefulWidget {
  final ToDoCategory? category;
  WellnessManageToDoCategoriesPanel({this.category});

  @override
  State<WellnessManageToDoCategoriesPanel> createState() => _WellnessManageToDoCategoriesPanelState();
}

class _WellnessManageToDoCategoriesPanelState extends State<WellnessManageToDoCategoriesPanel> implements NotificationsListener {
  ToDoCategory? _category;
  List<ToDoCategory>? _categories;
  late ToDoCategoryReminderType _selectedReminderType;
  Color? _selectedColor;
  Color? _tmpColor;
  TextEditingController _nameController = TextEditingController();
  bool _reminderTypeDropDownValuesVisible = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    NotificationService()
        .subscribe(this, [Wellness.notifyToDoCategoryCreated, Wellness.notifyToDoCategoryUpdated, Wellness.notifyToDoCategoryDeleted]);
    _category = widget.category;
    _selectedColor = _category?.color;
    _selectedReminderType = _category?.reminderType ?? ToDoCategoryReminderType.none;
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
      appBar: HeaderBar(title: Localization().getStringEx('panel.wellness.categories.manage.title', 'Manage Categories')),
      body: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(children: [
                _buildToDoListHeader(),
                _buildCreateCategoryHeader(),
                _buildCategoryNameWidget(),
                _buildColorsRowWidget(),
                _buildRemindersWidget()
              ]))),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildToDoListHeader() {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(Localization().getStringEx('panel.wellness.todo.header.label', 'My To-Do List'),
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18, fontFamily: Styles().fontFamilies!.bold)),
      HomeFavoriteButton(style: HomeFavoriteStyle.Button, padding: EdgeInsets.symmetric(horizontal: 16))
    ]);
  }

  Widget _buildCreateCategoryHeader() {
    return Padding(
        padding: EdgeInsets.only(top: 11),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Localization().getStringEx('panel.wellness.categories.create.header.label', 'Create a Category'),
              style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18, fontFamily: Styles().fontFamilies!.bold)),
          Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                  Localization().getStringEx('panel.wellness.categories.create.header.description',
                      'Examples: an RSO or club, a specific class, or a miscellaneous task category.'),
                  style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.regular)))
        ]));
  }

  Widget _buildCategoryNameWidget() {
    return Padding(
        padding: EdgeInsets.only(top: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: Text(Localization().getStringEx('panel.wellness.categories.name.field.label', 'NAME'),
                  style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.bold))),
          Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
              child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(border: InputBorder.none),
                  style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18, fontFamily: Styles().fontFamilies!.bold)))
        ]));
  }

  Widget _buildColorsRowWidget() {
    return Center(
        child: Padding(
            padding: EdgeInsets.only(top: 20),
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  _buildColorEntry(
                      color: Styles().colors!.fillColorSecondary!, isSelected: (_selectedColor == Styles().colors!.fillColorSecondary)),
                  _buildColorEntry(color: Styles().colors!.diningColor!, isSelected: (_selectedColor == Styles().colors!.diningColor)),
                  _buildColorEntry(color: Styles().colors!.placeColor!, isSelected: (_selectedColor == Styles().colors!.placeColor)),
                  _buildColorEntry(color: Styles().colors!.accentColor2!, isSelected: (_selectedColor == Styles().colors!.accentColor2)),
                  _buildColorEntry(color: Styles().colors!.accentColor3!, isSelected: (_selectedColor == Styles().colors!.accentColor3)),
                  _buildColorEntry(imageAsset: 'images/icon-color-edit.png'),
                ]))));
  }

  Widget _buildColorEntry({Color? color, String? imageAsset, bool isSelected = false}) {
    BoxBorder? border = isSelected ? Border.all(color: Colors.black, width: 2) : null;
    DecorationImage? image = StringUtils.isNotEmpty(imageAsset) ? DecorationImage(image: AssetImage(imageAsset!), fit: BoxFit.fill) : null;
    return Padding(padding: EdgeInsets.only(right: 10), child: GestureDetector(
        onTap: () => _onTapColor(color),
        child: Container(
            width: 50, height: 50, decoration: BoxDecoration(color: color, image: image, border: border, shape: BoxShape.circle))));
  }

  Widget _buildColorPickerDialog() {
    return SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
      ColorPicker(pickerColor: Styles().colors!.fillColorSecondary!, onColorChanged: _onColorChanged),
      Padding(
          padding: EdgeInsets.only(top: 20),
          child: Center(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
            RoundedButton(
                label: Localization().getStringEx('panel.wellness.categories.manage.color.pick.cancel.button', 'Cancel'),
                contentWeight: 0,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                fontSize: 16,
                onTap: _onTapCancelColorSelection),
            Container(width: 30),
            RoundedButton(
                label: Localization().getStringEx('panel.wellness.categories.manage.color.pick.select.button', 'Select'),
                contentWeight: 0,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                fontSize: 16,
                onTap: _onTapSelectColor)
          ])))
    ]));
  }

  Widget _buildRemindersWidget() {
    String? selectedTypeLabel = ToDoCategory.reminderTypeToDisplayString(_selectedReminderType);
    return Padding(
        padding: EdgeInsets.only(top: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: Text(Localization().getStringEx('panel.wellness.categories.reminders.field.label', 'REMINDERS'),
                  style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.bold))),
          GestureDetector(
              onTap: _onTapSelectedReminderType,
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  height: 48,
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(StringUtils.ensureNotEmpty(selectedTypeLabel),
                        style:
                            TextStyle(fontSize: 16, color: Styles().colors!.textSurfaceAccent, fontFamily: Styles().fontFamilies!.regular)),
                    Image.asset(_reminderTypeDropDownValuesVisible ? 'images/icon-up.png' : 'images/icon-down-orange.png')
                  ]))),
          Stack(children: [
            Column(children: [_buildSaveButton(), _buildManageCategories()]),
            _buildReminderTypesWidget()
          ])
        ]));
  }

  Widget _buildReminderTypesWidget() {
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
    for (ToDoCategoryReminderType type in ToDoCategoryReminderType.values) {
      sectionList.add(_buildReminderTypeItem(type));
    }
    return Column(children: sectionList);
  }

  Widget _buildReminderTypeItem(ToDoCategoryReminderType type) {
    bool isSelected = (type == _selectedReminderType);
    BorderSide borderSide = BorderSide(color: Styles().colors!.fillColorPrimary!, width: 1);
    return GestureDetector(
        onTap: () => _onTapReminderType(type),
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            height: 48,
            decoration: BoxDecoration(color: Colors.white, border: Border(left: borderSide, right: borderSide, bottom: borderSide)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(StringUtils.ensureNotEmpty(ToDoCategory.reminderTypeToDisplayString(type)),
                  style: TextStyle(fontSize: 16, color: Styles().colors!.textSurfaceAccent, fontFamily: Styles().fontFamilies!.regular)),
              Image.asset(isSelected ? 'images/icon-favorite-selected.png' : 'images/icon-favorite-deselected.png')
            ])));
  }

  Widget _buildSaveButton() {
    return Padding(
        padding: EdgeInsets.only(top: 30),
        child: RoundedButton(
            label: Localization().getStringEx('panel.wellness.categories.save.button', 'Save'),
            contentWeight: 0,
            progress: _loading,
            padding: EdgeInsets.symmetric(horizontal: 46, vertical: 8),
            onTap: _onTapSave));
  }

  Widget _buildManageCategories() {
    return Padding(
        padding: EdgeInsets.only(top: 30),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 1, color: Styles().colors!.mediumGray2),
          Padding(
              padding: EdgeInsets.only(top: 9),
              child: Text(Localization().getStringEx('panel.wellness.categories.manage.existing.label', 'Manage Existing Categories'),
                  style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies!.bold, color: Styles().colors!.fillColorPrimary))),
          Padding(
              padding: EdgeInsets.only(top: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildCategoriesWidgetList()))
        ]));
  }

  List<Widget> _buildCategoriesWidgetList() {
    List<Widget> widgetList = <Widget>[];
    if (_loading) {
      widgetList.add(CircularProgressIndicator());
    } else if (CollectionUtils.isNotEmpty(_categories)) {
      for (ToDoCategory category in _categories!) {
        widgetList.add(Padding(padding: EdgeInsets.only(top: 7), child: _buildCategoryCard(category)));
      }
    } else {
      widgetList.add(Text(Localization().getStringEx('panel.wellness.categories.manage.empty.label', 'No current categories'),
          style: TextStyle(color: Styles().colors!.textSurface, fontSize: 14, fontFamily: Styles().fontFamilies!.regular)));
    }
    return widgetList;
  }

  Widget _buildCategoryCard(ToDoCategory category) {
    return GestureDetector(
        onTap: () => _onTapEditCategory(category),
        child: Container(
            decoration: BoxDecoration(color: category.color, borderRadius: BorderRadius.circular(5)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Padding(
                  padding: EdgeInsets.only(left: 20, top: 10, bottom: 10),
                  child: Text(StringUtils.ensureNotEmpty(category.name),
                      style: TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.bold, fontSize: 14))),
              Expanded(child: Container()),
              Image.asset('images/icon-edit-white.png'),
              GestureDetector(
                  onTap: () => _onTapDeleteCategory(category),
                  child: Padding(
                      padding: EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 10),
                      child: Image.asset('images/icon-x-orange-small.png', color: Styles().colors!.white)))
            ])));
  }

  void _onColorChanged(Color newColor) {
    _tmpColor = newColor;
  }

  void _onTapCancelColorSelection() {
    Navigator.of(context).pop();
  }

  void _onTapSelectColor() {
    _selectedColor = _tmpColor;
    Navigator.of(context).pop();
    _updateState();
  }

  void _onTapEditCategory(ToDoCategory category) {
    //TBD: DD - implement
  }

  void _onTapDeleteCategory(ToDoCategory category) {
    AppAlert.showConfirmationDialog(
        buildContext: context,
        message: Localization().getStringEx(
            'panel.wellness.categories.manage.category.delete.confirmation.msg', 'Are sure that you want to delete this category?'),
        positiveCallback: () => _deleteCategory(category));
  }

  void _deleteCategory(ToDoCategory category) {
    _setLoading(true);
    Wellness().deleteToDoCategoryCached(category.id!).then((success) {
      late String msg;
      if (success) {
        msg =
            Localization().getStringEx('panel.wellness.categories.manage.category.delete.succeeded.msg', 'Category deleted successfully.');
      } else {
        msg = Localization().getStringEx('panel.wellness.categories.manage.category.delete.failed.msg', 'Failed to delete category.');
      }
      AppAlert.showDialogResult(context, msg);
      _setLoading(false);
    });
  }

  void _onTapSave() {
    _hideKeyboard();
    String name = _nameController.text;
    if(StringUtils.isEmpty(name)) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.wellness.categories.manage.empty.name.msg', 'Please, fill category name.'));
      return;
    }
    _setLoading(true);
    _category = ToDoCategory(name: name, colorHex: UiColors.toHex(_selectedColor), reminderType: _selectedReminderType);
    Wellness().createToDoCategoryCached(_category!).then((success) {
      late String msg;
      if (success) {
        msg = Localization().getStringEx('panel.wellness.categories.manage.category.create.succeeded.msg', 'Category created successfully.');
      } else {
        msg = Localization().getStringEx('panel.wellness.categories.manage.category.create.failed.msg', 'Failed to create category.');
      }
      AppAlert.showDialogResult(context, msg);
      _setLoading(false);
    });
  }

  void _onTapColor(Color? color) async {
    _hideKeyboard();
    if (color == null) {
      AppAlert.showCustomDialog(context: context, contentWidget: _buildColorPickerDialog()).then((_) {
        _tmpColor = null;
      });
    } else {
      _selectedColor = color;
      _updateState();
    }
  }

  void _onTapReminderType(ToDoCategoryReminderType type) {
    _hideKeyboard();
    if (_reminderTypeDropDownValuesVisible) {
      _reminderTypeDropDownValuesVisible = false;
    }
    _selectedReminderType = type;
    _updateState();
  }

  void _onTapSelectedReminderType() {
    _hideKeyboard();
    _reminderTypeDropDownValuesVisible = !_reminderTypeDropDownValuesVisible;
    _updateState();
  }

  void _loadCategories() {
    _setLoading(true);
    Wellness().loadToDoCategoriesCached().then((categories) {
      _categories = categories;
      _setLoading(false);
    });
  }

  void _clearSelectedFields() {
    _category = null;
    _selectedColor = null;
    _selectedReminderType = ToDoCategoryReminderType.none;
    _nameController.text = '';
    _updateState();
  }

  void _hideKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  void _setLoading(bool loading) {
    _loading = loading;
    _updateState();
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == Wellness.notifyToDoCategoryCreated) {
      _clearSelectedFields();
      _loadCategories();
    } else if (name == Wellness.notifyToDoCategoryUpdated) {
      _loadCategories();
    } else if (name == Wellness.notifyToDoCategoryDeleted) {
      _loadCategories();
    }
  }
}
