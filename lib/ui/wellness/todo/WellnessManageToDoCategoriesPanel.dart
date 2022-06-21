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
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessManageToDoCategoriesPanel extends StatefulWidget {
  final ToDoCategory? category;
  WellnessManageToDoCategoriesPanel({this.category});

  @override
  State<WellnessManageToDoCategoriesPanel> createState() => _WellnessManageToDoCategoriesPanelState();
}

class _WellnessManageToDoCategoriesPanelState extends State<WellnessManageToDoCategoriesPanel> {
  ToDoCategory? _category;
  List<ToDoCategory>? _categories;
  late ToDoCategoryReminderType _selectedReminderType;
  TextEditingController _nameController = TextEditingController();
  bool _reminderTypeDropDownValuesVisible = false;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    _selectedReminderType = _category?.reminderType ?? ToDoCategoryReminderType.none;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.wellness.categories.manage.title', 'Manage Categories')),
      body: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                  children: [_buildCreateCategoryHeader(), _buildCategoryNameWidget(), _buildColorsRowWidget(), _buildRemindersWidget()]))),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildCreateCategoryHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(Localization().getStringEx('panel.wellness.categories.create.header.label', 'Create a Category'),
          style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18, fontFamily: Styles().fontFamilies!.bold)),
      Padding(
          padding: EdgeInsets.only(top: 5),
          child: Text(
              Localization().getStringEx('panel.wellness.categories.create.header.description',
                  'Examples: an RSO or club, a specific class, or a miscellaneous task category.'),
              style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.regular)))
    ]);
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
    return Padding(
        padding: EdgeInsets.only(top: 20),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _buildColorEntry(color: Styles().colors!.fillColorSecondary!, isSelected: true),
          _buildColorEntry(color: Styles().colors!.diningColor!),
          _buildColorEntry(color: Styles().colors!.placeColor!),
          _buildColorEntry(color: Styles().colors!.accentColor2!),
          _buildColorEntry(color: Styles().colors!.accentColor3!),
          _buildColorEntry(imageAsset: 'images/icon-color-edit.png'),
        ]));
  }

  Widget _buildColorEntry({Color? color, String? imageAsset, bool isSelected = false}) {
    BoxBorder? border = isSelected ? Border.all(color: Colors.black, width: 2) : null;
    DecorationImage? image = StringUtils.isNotEmpty(imageAsset) ? DecorationImage(image: AssetImage(imageAsset!), fit: BoxFit.fill) : null;
    return Container(width: 50, height: 50, decoration: BoxDecoration(color: color, image: image, border: border, shape: BoxShape.circle));
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
    //TBD: DD - implement
    return Padding(
        padding: EdgeInsets.only(top: 30),
        child: RoundedButton(
            label: Localization().getStringEx('panel.wellness.categories.save.button', 'Save'),
            contentWeight: 0,
            padding: EdgeInsets.symmetric(horizontal: 46, vertical: 8),
            onTap: _onTapSave));
  }

  Widget _buildManageCategories() {
    //TBD: DD - implement
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
    if (CollectionUtils.isNotEmpty(_categories)) {
      //TBD: DD - implement
    } else {
      widgetList.add(Text(Localization().getStringEx('panel.wellness.categories.manage.empty.label', 'No current categories'),
          style: TextStyle(color: Styles().colors!.textSurface, fontSize: 14, fontFamily: Styles().fontFamilies!.regular)));
    }
    return widgetList;
  }

  void _onTapSave() {
    //TBD: DD - implement
  }

  void _onTapReminderType(ToDoCategoryReminderType type) {
    if (_reminderTypeDropDownValuesVisible) {
      _reminderTypeDropDownValuesVisible = false;
    }
    _selectedReminderType = type;
    _updateState();
  }

  void _onTapSelectedReminderType() {
    _reminderTypeDropDownValuesVisible = !_reminderTypeDropDownValuesVisible;
    _updateState();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }
}
