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


class SettingsFoodFiltersContentWidget extends StatefulWidget{

  _SettingsFoodFiltersContentWidgetState createState() => _SettingsFoodFiltersContentWidgetState();
}

class _SettingsFoodFiltersContentWidgetState extends State<SettingsFoodFiltersContentWidget> {

  //Set<String> selectedPreferences;
  late Set<String>? _selectedTypesPrefs;
  Set<String>? _selectedIngredientsPrefs;

  @override
  void initState() {
    _loadFoodPreferences();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadFoodPreferences(){
    _selectedTypesPrefs = (Auth2().prefs?.includedFoodTypes != null) ? Set.from(Auth2().prefs!.includedFoodTypes!) : null;
    _selectedIngredientsPrefs = (Auth2().prefs?.excludedFoodIngredients != null) ? Set.from(Auth2().prefs!.excludedFoodIngredients!) : null;
  }

  @override
  Widget build(BuildContext context) {
    String onlyShow = Localization().getStringEx("panel.food_filters.label.only_show_food_that_are.title", "ONLY SHOW FOODS THAT ARE");
    return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(height: 20,),
                    Container(
                      decoration: BoxDecoration(
                          color: Styles().colors!.fillColorPrimary,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4))),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Semantics(
                          label: onlyShow,
                          hint: Localization().getStringEx("panel.food_filters.label.only_show_food_that_are.hint", ""),
                          button: false,
                          child: Row(
                            children: <Widget>[
                              Expanded(
                              child: Text(
                                onlyShow,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    fontFamily: Styles().fontFamilies!.bold,
                                    color: Colors.white,
                                    fontSize: 14,
                                    letterSpacing: 1.0),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildFoodTypes(),
                    Container(height: 20,),
                    Container(
                      decoration: BoxDecoration(
                          color: Styles().colors!.fillColorPrimary,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4))),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Semantics(
                          label: Localization().getStringEx("panel.food_filters.label.exclude_ingredients.title", "EXCLUDE FOODS WITH INGREDIENTS"),
                          hint: Localization().getStringEx("panel.food_filters.label.exclude_ingredients.title", ""),
                          button: false,
                          child: Row(
                            children: <Widget>[
                            Expanded(
                            child: Text(
                              Localization().getStringEx("panel.food_filters.label.exclude_ingredients.title", "EXCLUDE FOODS WITH INGREDIENTS"),
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontFamily: Styles().fontFamilies!.bold,
                                  color: Colors.white,
                                  fontSize: 14,
                                  letterSpacing: 1.0),
                              ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildFoodIngredients(),
                    Container(height: 20,),
                  ],
                );
  }

  Widget _buildFoodTypes(){
    List<Widget> list = [];
    List<String>? foodTypes = Dinings().foodTypes;
    if (foodTypes != null) {
      for(String foodType in foodTypes){
        bool selected = _selectedTypesPrefs?.contains(foodType) ?? false;
        String? foodLabel = Dinings().getLocalizedString(foodType);
        list.add(
            ToggleRibbonButton(
              label: foodLabel,
              onTap: (){_onFoodTypePrefTapped(foodType);},
              toggled: selected,
            ));
      }
    }

    return Column(
      children: list,
    );
  }

  Widget _buildFoodIngredients(){
    List<Widget> list = [];
    List<String>? foodIngredients = Dinings().foodIngredients;
    if (foodIngredients != null) {
      for(String foodIngredient in foodIngredients){
        bool selected = _selectedIngredientsPrefs?.contains(foodIngredient) ?? false;
        String? ingredientLabel = Dinings().getLocalizedString(foodIngredient);
        list.add(
            ToggleRibbonButton(
              label: ingredientLabel,
              onTap: (){_onFoodIngredientPrefTapped(foodIngredient);},
              toggled: selected,
            ));
      }
    }

    return Column(
      children: list,
    );
  }

  void _onFoodTypePrefTapped(String? foodOption){
    Analytics().logSelect(target: "FoodType: $foodOption");
    if(foodOption != null) {
      if(_selectedTypesPrefs == null) {
        _selectedTypesPrefs = <String>{ foodOption };
      }
      else if(_selectedTypesPrefs!.contains(foodOption)){
        _selectedTypesPrefs!.remove(foodOption);
      }
      else{
        _selectedTypesPrefs!.add(foodOption);
      }
      Auth2().prefs?.includedFoodTypes = _selectedTypesPrefs;

      setState((){});
    }
  }

  void _onFoodIngredientPrefTapped(String? foodOption){
    Analytics().logSelect(target: "FoodIngredient: $foodOption");
    if(foodOption != null) {
      if(_selectedIngredientsPrefs == null){
        _selectedIngredientsPrefs = <String>{ foodOption };
      }
      if(_selectedIngredientsPrefs!.contains(foodOption)){
        _selectedIngredientsPrefs!.remove(foodOption);
      }
      else{
        _selectedIngredientsPrefs!.add(foodOption);
      }
      Auth2().prefs?.excludedFoodIngredients = _selectedIngredientsPrefs;
      setState((){});
    }
  }
}