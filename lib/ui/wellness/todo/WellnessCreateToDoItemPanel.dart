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
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessCreateToDoItemPanel extends StatefulWidget {
  WellnessCreateToDoItemPanel();

  @override
  State<WellnessCreateToDoItemPanel> createState() => _WellnessCreateToDoItemPanelState();
}

class _WellnessCreateToDoItemPanelState extends State<WellnessCreateToDoItemPanel> {
  List<ToDoCategory>? _categories;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.wellness.home.header.title', 'Wellness')),
      body: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildToDoListHeader(),
                _buildAddItemHeader(),
                _buildItemName(),
                _buildOptionalFieldsHeader(),
                _buildCategoryContainer(),
                _buildLocationContainer(),
                _buildDescriptionContainer(),
                _buildSaveButton()
              ]))),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildToDoListHeader() {
    return Padding(
        padding: EdgeInsets.only(top: 35),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(Localization().getStringEx('panel.wellness.todo.header.label', 'My To-Do List'),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18, fontFamily: Styles().fontFamilies!.bold)),
          HomeFavoriteButton(style: HomeFavoriteStyle.Button, padding: EdgeInsets.symmetric(horizontal: 16))
        ]));
  }

  Widget _buildAddItemHeader() {
    return Padding(
        padding: EdgeInsets.only(top: 10),
        child: Text(Localization().getStringEx('panel.wellness.todo.item.add.label', 'Add an Item'),
            style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold)));
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
    return Padding(
        padding: EdgeInsets.only(top: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 1, color: Styles().colors!.mediumGray2),
          Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(Localization().getStringEx('panel.wellness.todo.item.optional_fields.label', 'Optional Fields'),
                  style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.bold)))
        ]));
  }

  Widget _buildCategoryContainer() {
    return Padding(
        padding: EdgeInsets.only(top: 11),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildFieldLabel(label: Localization().getStringEx('panel.wellness.todo.item.category.field.label', 'CATEGORY')),
          //TBD: DD - implement
          Text('TBD - implement')
        ]));
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
    return Text(label, style: TextStyle(color: Styles().colors!.textSurfaceAccent, fontSize: 12, fontFamily: Styles().fontFamilies!.bold));
  }

  Widget _buildInputField({required TextEditingController controller}) {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
        child: TextField(
            controller: controller,
            decoration: InputDecoration(border: InputBorder.none),
            style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18, fontFamily: Styles().fontFamilies!.bold)));
  }

  Widget _buildSaveButton() {
    return Center(
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: RoundedButton(
                label: Localization().getStringEx('panel.wellness.todo.item.save.button', 'Save'),
                contentWeight: 0,
                padding: EdgeInsets.symmetric(horizontal: 46, vertical: 8),
                onTap: _onTapSave)));
  }

  void _onTapSave() {
    //TBD: DD - implement
  }

  void _loadCategories() {
    //TBD: DD - implement
  }

  void _setLoading(bool loading) {
    _loading = loading;
    if (mounted) {
      setState(() {});
    }
  }
}
