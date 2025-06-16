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
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/styles.dart';


class SettingsFoodFiltersPage extends StatefulWidget{

  _SettingsFoodFiltersPageState createState() => _SettingsFoodFiltersPageState();
}

class _SettingsFoodFiltersPageState extends State<SettingsFoodFiltersPage> {

  late Set<String> _includedFoodTypes;
  late Set<String> _excludedFoodIngredients;

  @override
  void initState() {

    // Validate selection: make sure selection does not contain unavailable items
    Set<String> availableFoodTypes = Set.from(Dinings().foodTypes ?? <String>[]);
    _includedFoodTypes = Set.from(Auth2().prefs?.includedFoodTypes ?? <String>{});
    _includedFoodTypes.removeWhere((foodType) => availableFoodTypes.contains(foodType) != true);

    // Validate selection: make sure selection does not contain unavailable items
    Set<String> availableFoodIngredients = Set.from(Dinings().foodIngredients ?? <String>[]);
    _excludedFoodIngredients = Set.from(Auth2().prefs?.excludedFoodIngredients ?? <String>{});
    _excludedFoodIngredients.removeWhere((foodIngredient) => availableFoodIngredients.contains(foodIngredient) != true);

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Container(height: 20,),

      Container(decoration: _sectionDecoration, child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), child:
          Semantics(label: _onlyShowText, hint: _onlyShowHint, button: false, child:
            Row(children: <Widget>[
              Expanded(child:
                Text(_onlyShowText, textAlign: TextAlign.left, style: Styles().textStyles.getTextStyle("panel.settings.food_filter.title")),
              )
            ],),
          ),
        ),
      ),

      _buildFoodTypes(),

      Container(height: 20,),

      Container(decoration: _sectionDecoration, child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), child:
          Semantics(label: _excludeText, hint: _excludeHint, button: false, child:
            Row(children: <Widget>[
              Expanded(child:
                Text(_excludeText, textAlign: TextAlign.left, style: Styles().textStyles.getTextStyle("panel.settings.food_filter.title")),
              )
            ],),
          ),
        ),
      ),

      _buildFoodIngredients(),

      Container(height: 20,),
    ],);

  Widget _buildFoodTypes(){
    List<Widget> list = [];
    List<String>? foodTypes = Dinings().foodTypes;
    if (foodTypes != null) {
      for (String foodType in foodTypes) {
        list.add(ToggleRibbonButton(
          label: Dinings().getLocalizedString(foodType),
          toggled: _includedFoodTypes.contains(foodType),
          onTap: () => _onFoodTypePrefTapped(foodType),
        ));
      }
    }

    return Column(children: list,);
  }

  Widget _buildFoodIngredients(){
    List<Widget> list = [];
    List<String>? foodIngredients = Dinings().foodIngredients;
    if (foodIngredients != null) {
      for(String foodIngredient in foodIngredients) {
        list.add(ToggleRibbonButton(
          label: Dinings().getLocalizedString(foodIngredient),
          toggled: _excludedFoodIngredients.contains(foodIngredient),
          onTap: () => _onFoodIngredientPrefTapped(foodIngredient),
        ));
      }
    }

    return Column(children: list,);
  }

  String get _onlyShowText => Localization().getStringEx("panel.food_filters.label.only_show_food_that_are.title", "ONLY SHOW FOODS THAT ARE");
  String get _onlyShowHint => Localization().getStringEx("panel.food_filters.label.only_show_food_that_are.hint", "");

  String get _excludeText => Localization().getStringEx("panel.food_filters.label.exclude_ingredients.title", "EXCLUDE FOODS WITH INGREDIENTS");
  String get _excludeHint => Localization().getStringEx("panel.food_filters.label.exclude_ingredients.hint", "");

  BorderRadiusGeometry get _topRounding => BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4));
  Decoration get _sectionDecoration => BoxDecoration(color: Styles().colors.fillColorPrimary, borderRadius: _topRounding);

  void _onFoodTypePrefTapped(String? foodOption){
    Analytics().logSelect(target: "FoodType: $foodOption");
    if (foodOption != null) {
      setState((){
        if (_includedFoodTypes.contains(foodOption)) {
          _includedFoodTypes.remove(foodOption);
        } else {
          _includedFoodTypes.add(foodOption);
        }
        Auth2().prefs?.includedFoodTypes = _includedFoodTypes;
      });
    }
  }

  void _onFoodIngredientPrefTapped(String? foodOption){
    Analytics().logSelect(target: "FoodIngredient: $foodOption");
    if (foodOption != null) {
      setState((){
        if (_excludedFoodIngredients.contains(foodOption)) {
          _excludedFoodIngredients.remove(foodOption);
        } else {
          _excludedFoodIngredients.add(foodOption);
        }
        Auth2().prefs?.excludedFoodIngredients = _excludedFoodIngredients;
      });
    }
  }
}

class SettingsFoodFiltersBottomSheet extends StatelessWidget {
  SettingsFoodFiltersBottomSheet._();

  static void present(BuildContext context) {
    MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
    double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 16;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Styles().colors.background,
      constraints: BoxConstraints(maxHeight: height, minHeight: height),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SettingsFoodFiltersBottomSheet._();
      }
    );
  }

  @override
  Widget build(BuildContext context) =>
    Padding(padding: MediaQuery.of(context).viewInsets, child:
      Column(children: [
        _buildHeaderBar(context),
        Container(color: Styles().colors.surfaceAccent, height: 1,),
        Expanded(child:
          SingleChildScrollView(child:
            Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
              SettingsFoodFiltersPage()
            )
          ),
        ),
      ],),
    );

  Widget _buildHeaderBar(BuildContext context) =>
    Container(color: Styles().colors.white, child:
      Row(children: [
        Expanded(child:
          Padding(padding: EdgeInsets.only(left: 16), child:
            Text(Localization().getStringEx('panel.settings.home.settings.sections.food_filter.label', 'My Food Filter'), style: Styles().textStyles.getTextStyle("widget.label.medium.fat"),)
          )
        ),
        Semantics( label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), inMutuallyExclusiveGroup: true, button: true, child:
          InkWell(onTap : () => _onTapClose(context), child:
            Container(padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16), child:
              Styles().images.getImage('close-circle', excludeFromSemantics: true),
            ),
          ),
        ),

      ],),
    );

  void _onTapClose(BuildContext context)  {
    Analytics().logSelect(target: 'Close', source: runtimeType.toString());
    Navigator.of(context).pop();
  }
}