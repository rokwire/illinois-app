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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessManageToDoCategoriesPanel extends StatefulWidget {
  final ToDoCategory? category;
  WellnessManageToDoCategoriesPanel({this.category});

  @override
  State<WellnessManageToDoCategoriesPanel> createState() => _WellnessManageToDoCategoriesPanelState();
}

class _WellnessManageToDoCategoriesPanelState extends State<WellnessManageToDoCategoriesPanel> implements NotificationsListener {
  static final List<String> _availableCategoryHexColors = ['#E45434', '#F5821E', '#54A747', '#009FD4', '#1D58A7', '#662d91'];

  ToDoCategory? _category;
  List<ToDoCategory>? _categories;
  Color? _selectedColor;
  TextEditingController _nameController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    NotificationService()
        .subscribe(this, [Wellness.notifyToDoCategoryChanged, Wellness.notifyToDoCategoryDeleted]);
    _category = widget.category;
    _selectedColor = _category?.color;
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
                _buildCreateCategoryHeader(),
                _buildCategoryNameWidget(),
                _buildColorsRowWidget(),
                _buildEditCategoryButtons(),
                _buildManageCategories()
              ]))),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildCreateCategoryHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(Localization().getStringEx('panel.wellness.categories.create.header.label', 'Create a Category'),
          style: Styles().textStyles?.getTextStyle("widget.title.medium.fat")),
      Padding(
          padding: EdgeInsets.only(top: 5),
          child: Text(
              Localization().getStringEx('panel.wellness.categories.create.header.description',
                  'Examples: an RSO or club, a specific class, or a miscellaneous task category.'),
              style: Styles().textStyles?.getTextStyle("widget.detail.small")))
    ]);
  }

  Widget _buildCategoryNameWidget() {
    return Padding(
        padding: EdgeInsets.only(top: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: Text(Localization().getStringEx('panel.wellness.categories.name.field.label', 'NAME'),
                  style: Styles().textStyles?.getTextStyle("widget.description.small.fat"))),
          Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
              child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(border: InputBorder.none),
                  style: Styles().textStyles?.getTextStyle("widget.title.medium.fat")))
        ]));
  }

  Widget _buildColorsRowWidget() {
    List<Widget> colorWidgets = [];
    for (String colorHex in _availableCategoryHexColors) {
      colorWidgets.add(_buildColorEntry(color: UiColors.fromHex(colorHex), isSelected: (_selectedColor == UiColors.fromHex(colorHex))));
    }
    return Center(
        child: Padding(
            padding: EdgeInsets.only(top: 20),
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal, child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: colorWidgets))));
  }

  Widget _buildColorEntry({Color? color, String? imageAsset, bool isSelected = false}) {
    BoxBorder? border = isSelected ? Border.all(color: Colors.black, width: 2) : null;
    DecorationImage? image = StringUtils.isNotEmpty(imageAsset) ? DecorationImage(image: AssetImage(imageAsset!), fit: BoxFit.fill) : null;
    return Padding(padding: EdgeInsets.only(right: 10), child: GestureDetector(
        onTap: () => _onTapColor(color),
        child: Container(
            width: 50, height: 50, decoration: BoxDecoration(color: color, image: image, border: border, shape: BoxShape.circle))));
  }

  Widget _buildEditCategoryButtons() {
    bool hasCategoryForEdit = (_category != null);
    return Padding(
        padding: EdgeInsets.only(top: 30),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(
              flex: (hasCategoryForEdit ? 1 : 0),
              child: Visibility(
                  visible: hasCategoryForEdit,
                  child: RoundedButton(
                      label: Localization().getStringEx('panel.wellness.categories.delete.button', 'Delete'),
                      borderColor: Styles().colors!.fillColorPrimary,
                      progress: _loading,
                      padding: EdgeInsets.symmetric(horizontal: 46, vertical: 8),
                      onTap: _onTapDelete))),
          Visibility(visible: hasCategoryForEdit, child: Container(width: 15)),
          Flexible(
              flex: (hasCategoryForEdit ? 1 : 0),
              child: RoundedButton(
                  label: Localization().getStringEx('panel.wellness.categories.save.button', 'Save'),
                  contentWeight: (hasCategoryForEdit ? 1 : 0),
                  progress: _loading,
                  padding: EdgeInsets.symmetric(horizontal: 46, vertical: 8),
                  onTap: _onTapSave))
        ]));
  }

  Widget _buildManageCategories() {
    return Padding(
        padding: EdgeInsets.only(top: 30),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(height: 1, color: Styles().colors!.mediumGray2),
          Padding(
              padding: EdgeInsets.only(top: 9),
              child: Row(children: [
                Expanded(
                    child: Text(Localization().getStringEx('panel.wellness.categories.manage.existing.label', 'Manage Existing Categories'),
                        overflow: TextOverflow.ellipsis,
                        style: Styles().textStyles?.getTextStyle("widget.title.regular")))
              ])),
          Padding(
              padding: EdgeInsets.only(top: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: _buildCategoriesWidgetList()))
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
      widgetList.add(Row(children: [
        Expanded(child: Text(Localization().getStringEx('panel.wellness.categories.manage.empty.label', 'No current categories'),
          style: Styles().textStyles?.getTextStyle("panel.wellness.todo.category.empty.msg")))
      ]));
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
                      style: Styles().textStyles?.getTextStyle("panel.wellness.todo.category.card.title.regular"))),
              Expanded(child: Container()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Image.asset('images/edit-white.png'))
            ])));
  }

  void _onTapEditCategory(ToDoCategory category) {
    Analytics().logSelect(target: "Edit ${category.name}");
    _category = category;
    _nameController.text = StringUtils.ensureNotEmpty(_category?.name);
    _selectedColor = _category?.color;
    _updateState();
  }

  void _onTapDelete() {
    Analytics().logSelect(target: "Delete");
    if (_category == null) {
      AppAlert.showDialogResult(
          context,
          Localization().getStringEx(
              'panel.wellness.categories.manage.category.delete.no_selected_category.msg', 'There is no selected category to delete.'));
      return;
    }
    AppAlert.showConfirmationDialog(
        buildContext: context,
        message: Localization().getStringEx(
            'panel.wellness.categories.manage.category.delete.confirmation.msg', 'Are sure that you want to delete this category?'),
        positiveCallback: () => _deleteCategory(_category!));
  }

  void _deleteCategory(ToDoCategory category) {
    _setLoading(true);
    Wellness().deleteToDoCategory(category.id!).then((success) {
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
    Analytics().logSelect(target: "Save");
    _hideKeyboard();
    String name = _nameController.text;
    if (StringUtils.isEmpty(name)) {
      AppAlert.showDialogResult(
          context, Localization().getStringEx('panel.wellness.categories.manage.empty.name.msg', 'Please, fill category name.'));
      return;
    }
    _setLoading(true);
    ToDoCategory cat = ToDoCategory(id: _category?.id, name: name, colorHex: UiColors.toHex(_selectedColor));
    Wellness().saveToDoCategory(cat).then((success) {
      late String msg;
      if (success) {
        msg = Localization().getStringEx('panel.wellness.categories.manage.category.save.succeeded.msg', 'Category saved successfully.');
      } else {
        msg = Localization().getStringEx('panel.wellness.categories.manage.category.save.failed.msg', 'Failed to save category.');
      }
      AppAlert.showDialogResult(context, msg);
      _setLoading(false);
    });
  }

  void _onTapColor(Color? color) async {
    Analytics().logSelect(target: "Color: $color");
    _hideKeyboard();
    if (color != null) {
      _selectedColor = color;
      _updateState();
    }
  }

  void _loadCategories() {
    _setLoading(true);
    Wellness().loadToDoCategories().then((categories) {
      _categories = categories;
      _setLoading(false);
    });
  }

  void _clearCategoryFields() {
    _category = null;
    _selectedColor = null;
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
    if (name == Wellness.notifyToDoCategoryChanged) {
      _clearCategoryFields();
      _loadCategories();
    } else if (name == Wellness.notifyToDoCategoryDeleted) {
      _clearCategoryFields();
      _loadCategories();
    }
  }
}
