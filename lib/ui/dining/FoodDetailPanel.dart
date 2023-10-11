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
import 'package:illinois/service/Dinings.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';


class FoodDetailPanel extends StatefulWidget {

  final DiningProductItem productItem;
  
  FoodDetailPanel({required this.productItem});

  _FoodDetailPanelState createState() => _FoodDetailPanelState();
}

class _FoodDetailPanelState extends State<FoodDetailPanel> {

  bool _isLoading = false;

  DiningNutritionItem? _nutritionItem;

  @override
  void initState() {
    super.initState();
    _loadNutritionItem();
  }

  void _loadNutritionItem(){
    setState(() {
      _isLoading = true;
    });
    Dinings().loadNutritionItemWithId(widget.productItem.itemID).then((item){
      _nutritionItem = item;
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: widget.productItem.name,
        //textStyle: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 16),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _isLoading
                ? _buildLoadingContent()
                : _buildMainContent(),
          ),
        ],
      ),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildLoadingContent(){
      return Center(
        child: CircularProgressIndicator(),
      );
  }

  Widget _buildMainContent(){
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(height: 20,),
            _nutritionItem == null ? Container(
              child: Center(
                child: Text(Localization().getStringEx("panel.food_details.label.nutrition_fatcts_not_available.title", "Nutrition information not available"),
                  style: Styles().textStyles?.getTextStyle("widget.message.small.semi_fat"),
                ),
              ),
            ):
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
                  label: Localization().getStringEx("panel.food_details.label.nutrition_fatcts.title", "NUTRITION FACTS"),
                  hint: Localization().getStringEx("panel.food_details.label.nutrition_fatcts.hint", ""),
                  button: false,
                  header: true,
                  excludeSemantics: true,
                  child: Row(
                    children: <Widget>[
                      Expanded(child:
                        Text(
                          Localization().getStringEx("panel.food_details.label.nutrition_fatcts.title", "NUTRITION FACTS"),
                          textAlign: TextAlign.left,
                          style: Styles().textStyles?.getTextStyle("widget.title.light.small.fat.spaced"),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            _buildNutritionFacts(),
            Container(height: 20,),
            Semantics(
              label: Localization().getStringEx("panel.food_details.button.view_full_list_of_ingredients.title", "View full list of ingredients"),
              hint: Localization().getStringEx("panel.food_details.button.view_full_list_of_ingredients.title", ""),
              button: true,
              child: RibbonButton(
                label: Localization().getStringEx("panel.food_details.button.view_full_list_of_ingredients.title", "View full list of ingredients"),
                borderRadius: BorderRadius.all(Radius.circular(4)),
                border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
                onTap: (){_onEatSmartTapped(context);},
              ),
            ),
            _buildIncludedIngedients(),
            _buildDietaryPreference(),
            Container(height: 20,),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionFacts(){
    List<Widget> list = [];
    if(_nutritionItem!=null) {
      list.add(_FactItem(label: Localization().getStringEx('com.illinois.nutrition_type.entry.Serving', 'Serving'), value: _nutritionItem!.serving));

      for(NutritionNameValuePair nutritionEntry in _nutritionItem!.nutritionList!){
        String? foodTypeLabel = Dinings().getLocalizedString(nutritionEntry.name);
        list.add(_FactItem(label: foodTypeLabel, value: nutritionEntry.value));
      }
    }
    return Column(
      children: list,
    );
  }

  Widget _buildIncludedIngedients(){
    List<Widget> list = [];
    List<String> ingredients = widget.productItem.ingredients;
    if(ingredients.isNotEmpty) {
      list.add(Container(height: 20,));
      list.add(Container(
        decoration: BoxDecoration(
            color: Styles().colors!.fillColorPrimary,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4))),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          child: Semantics(
            label: Localization().getStringEx("panel.food_details.label.include_ingredients.title", "INCLUDES THESE INGREDIENTS"),
            hint: Localization().getStringEx("panel.food_details.label.include_ingredients.hint", ""),
            button: false,
            header: true,
            excludeSemantics: true,
            child: Row(
              children: <Widget>[
                Expanded(
                  child:Text(
                    Localization().getStringEx("panel.food_details.label.include_ingredients.title", "INCLUDES THESE INGREDIENTS"),
                    textAlign: TextAlign.left,
                    style: Styles().textStyles?.getTextStyle("widget.title.light.small.fat.spaced")
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
      for (String entry in ingredients) {
        entry = entry.trim();
        if(entry.isNotEmpty) {
          String? ingredientLabel = Dinings().getLocalizedString(entry);
          list.add(_IngredientItem(label: ingredientLabel));
        }
      }
    }

    return Column(
      children: list,
    );
  }

  Widget _buildDietaryPreference(){
    List<Widget> list = [];
    List<String> preferences = widget.productItem.dietaryPreferences;
    if(preferences.isNotEmpty) {
      list.add(Container(height: 20,));
      list.add(Container(
        decoration: BoxDecoration(
            color: Styles().colors!.fillColorPrimary,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4))),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          child: Semantics(
            label: Localization().getStringEx("panel.food_details.label.dietary_preferences.title", "DIETARY PREFERENCES"),
            hint: Localization().getStringEx("panel.food_details.label.dietary_preferences.hint", ""),
            button: false,
            excludeSemantics: true,
            child: Row(
              children: <Widget>[
                Expanded(child:
                Text(
                  Localization().getStringEx("panel.food_details.label.dietary_preferences.title", "DIETARY PREFERENCES"),
                  textAlign: TextAlign.left,
                  style: Styles().textStyles?.getTextStyle("widget.title.light.small.fat.spaced")
                ),),
              ],
            ),
          ),
        ),
      ));
      for (String entry in preferences) {
        entry = entry.trim();
        if(entry.isNotEmpty) {
          String? ingredientLabel = Dinings().getLocalizedString(entry);
          list.add(_IngredientItem(label: ingredientLabel));
        }
      }
    }

    return Column(
      children: list,
    );
  }

  void _onEatSmartTapped(BuildContext context){
    Analytics().logSelect(target: "View full list of ingredients");
    if (Config().eatSmartUrl != null) {
      Navigator.push(context, CupertinoPageRoute(
          builder: (context)=>WebPanel(url: Config().eatSmartUrl )
      ));
    }
  }
}

class _FactItem extends StatelessWidget {
  final String? label;
  final String? value;

  _FactItem({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: value,
      button: false,
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(width: 1, color: Styles().colors!.surfaceAccent!),
            right: BorderSide(width: 1, color: Styles().colors!.surfaceAccent!),
            bottom: BorderSide(width: 1, color: Styles().colors!.surfaceAccent!),
          ),
          color: Colors.white,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                flex: 5,
                child: Text(
                  StringUtils.isNotEmpty(label) ? label! : "",
                  textAlign: TextAlign.left,
                  style: Styles().textStyles?.getTextStyle("widget.title.regular.fat"),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                StringUtils.isNotEmpty(value) ? value! : "",
                textAlign: TextAlign.right,
                style: Styles().textStyles?.getTextStyle("widget.detail.light.small"),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientItem extends StatelessWidget {
  final String? label;

  _IngredientItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: false,
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(width: 1, color: Styles().colors!.surfaceAccent!),
            right: BorderSide(width: 1, color: Styles().colors!.surfaceAccent!),
            bottom: BorderSide(width: 1, color: Styles().colors!.surfaceAccent!),
          ),
          color: Colors.white,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                StringUtils.isNotEmpty(label) ? label! : "",
                style: Styles().textStyles?.getTextStyle("widget.detail.medium"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}