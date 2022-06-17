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
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class WellnessManageCategoriesPanel extends StatefulWidget {
  WellnessManageCategoriesPanel();

  @override
  State<WellnessManageCategoriesPanel> createState() => _WellnessManageCategoriesPanelState();
}

class _WellnessManageCategoriesPanelState extends State<WellnessManageCategoriesPanel> {
  TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.wellness.categories.manage.title', 'Manage Categories')),
      body: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(children: [_buildCreateCategoryHeader(), _buildCategoryNameWidget(), _buildColorsRowWidget()]))),
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
                  'Examples could include making a category for RSOs, each class, or for your every day miscellaneous tasks.'),
              style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.regular)))
    ]);
  }

  Widget _buildCategoryNameWidget() {
    return Padding(
        padding: EdgeInsets.only(top: 20),
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
            child: TextField(
                controller: _nameController,
                decoration: InputDecoration(border: InputBorder.none),
                style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18, fontFamily: Styles().fontFamilies!.bold))));
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
        ]));
  }

  Widget _buildColorEntry({required Color color, bool isSelected = false}) {
    BoxBorder? border = isSelected ? Border.all(color: Colors.black, width: 2) : null;
    return Container(width: 50, height: 50, decoration: BoxDecoration(color: color, border: border, shape: BoxShape.circle));
  }
}
