// Copyright 2025 Board of Trustees of the University of Illinois.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class AssistantDiningProductItemCard extends StatefulWidget {
  final DiningProductItem item;
  final GestureTapCallback? onTap;

  AssistantDiningProductItemCard({required this.item, this.onTap});

  @override
  State<AssistantDiningProductItemCard> createState() => _AssistantDiningProductItemCardState();
}

class _AssistantDiningProductItemCardState extends State<AssistantDiningProductItemCard> {

  Dining? _dining;
  bool _loadingDining = false;

  @override
  void initState() {
    super.initState();
    _loadDining();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadDining() {
    String? diningOptionId = widget.item.diningOptionId;
    if ((diningOptionId != null) && diningOptionId.isNotEmpty) {
      setStateIfMounted(() {
        _loadingDining = true;
      });
      Dinings().loadDining(diningOptionId).then((result) {
        setStateIfMounted(() {
          _dining = result;
          _loadingDining = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Container(
          decoration: BoxDecoration(color: Styles().colors.surface, borderRadius: BorderRadius.all(Radius.circular(8)), boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 1.0, blurRadius: 1.0, offset: Offset(0, 2))]),
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildDiningWidget(),
                  Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.start, children: [
                    Text(widget.item.category ?? '', style: Styles().textStyles.getTextStyle('widget.card.title.tiny.fat'), overflow: TextOverflow.ellipsis, maxLines: 1),
                    Visibility(visible: (widget.item.meal?.isNotEmpty == true), child: Text(' (${widget.item.meal ?? ''})', style: Styles().textStyles.getTextStyle('common.title.secondary'), overflow: TextOverflow.ellipsis, maxLines: 1)),
                  ]),
                  Padding(padding: EdgeInsets.only(top: 2, bottom: 14), child: Row(children: [Expanded(child: Text(widget.item.name ?? '', style: Styles().textStyles.getTextStyle('widget.title.medium.fat'), overflow: TextOverflow.ellipsis))])),
                  Visibility(
                      visible: widget.item.ingredients.isNotEmpty,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(Localization().getStringEx('panel.assistant.dining_product_item.ingredients.label', 'INGREDIENTS:'), style: Styles().textStyles.getTextStyle('widget.label.small.fat'), overflow: TextOverflow.ellipsis),
                        Row(children: [Expanded(child: Text(widget.item.ingredients.join(', '), style: Styles().textStyles.getTextStyle('widget.detail.small'), overflow: TextOverflow.ellipsis))])
                      ])),
                  Visibility(
                      visible: widget.item.dietaryPreferences.isNotEmpty,
                      child: Padding(
                          padding: EdgeInsets.only(top: (widget.item.ingredients.isNotEmpty ? 8 : 0)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(Localization().getStringEx('panel.assistant.dining_product_item.dietary_preferences.label', 'DIETARY PREFERENCES:'), style: Styles().textStyles.getTextStyle('widget.label.small.fat'), overflow: TextOverflow.ellipsis),
                            Row(children: [Expanded(child: Text(widget.item.dietaryPreferences.join(', '), style: Styles().textStyles.getTextStyle('widget.detail.small'), overflow: TextOverflow.ellipsis))])
                          ]))),
                ],
              ),
            ),
          )),
    );
  }

  Widget _buildDiningWidget() {
    late Widget diningContentWidget;
    if (_loadingDining) {
      diningContentWidget = Padding(padding: EdgeInsets.only(bottom: 8), child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)));
    } else if (_dining != null) {
      diningContentWidget = Padding(padding: EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.start, children: [Text(_dining?.title ?? '', style: Styles().textStyles.getTextStyle('widget.card.title.tiny.fat'), overflow: TextOverflow.ellipsis, maxLines: 1)]));
    } else {
      diningContentWidget = Container();
    }
    return diningContentWidget;
  }
}

class AssistantDiningNutritionItemCard extends StatelessWidget {
  final DiningNutritionItem item;
  final GestureTapCallback? onTap;

  AssistantDiningNutritionItemCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
          decoration: BoxDecoration(color: Styles().colors.surface, borderRadius: BorderRadius.all(Radius.circular(8)), boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 1.0, blurRadius: 1.0, offset: Offset(0, 2))]),
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(padding: EdgeInsets.only(top: 2, bottom: 14), child: Row(children: [Expanded(child: Text(item.name ?? '', style: Styles().textStyles.getTextStyle('widget.title.medium.fat'), overflow: TextOverflow.ellipsis))])),
                  Visibility(
                    visible: (item.nutritionList?.isNotEmpty == true),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(Localization().getStringEx('panel.assistant.dining_nutrition_item.info.label', 'NUTRITION INFO:'), style: Styles().textStyles.getTextStyle('widget.label.small.fat'), overflow: TextOverflow.ellipsis),
                      _buildNutritionInfoWidget(item.nutritionList),
                    ]),
                  ),
                ],
              ),
            ),
          )),
    );
  }

  Widget _buildNutritionInfoWidget(List<NutritionNameValuePair>? nutritionList) {
    if (nutritionList == null || nutritionList.isEmpty) {
      return Container();
    }
    String nutritionInfo = '';
    for (NutritionNameValuePair pair in nutritionList) {
      if (nutritionInfo.isNotEmpty) {
        nutritionInfo += ', ';
      }
      nutritionInfo += '${pair.name}: ${pair.value}';
    }
    return Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(
        child: Text(nutritionInfo, style: Styles().textStyles.getTextStyle('widget.detail.small'), overflow: TextOverflow.ellipsis, maxLines: 5),
      ),
    ]);
  }
}