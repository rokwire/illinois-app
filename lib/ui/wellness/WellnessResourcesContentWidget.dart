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
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class WellnessResourcesContentWidget extends StatefulWidget {
  WellnessResourcesContentWidget();

  @override
  State<WellnessResourcesContentWidget> createState() => _WellnessResourcesContentWidgetState();
}

class _WellnessResourcesContentWidgetState extends State<WellnessResourcesContentWidget> {
  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    return Column(children: [_buildHeader(), _buildActionButtonsContainer(), _buildResourceButtonsContainer()]);
  }

  Widget _buildHeader() {
    return Padding(
        padding: EdgeInsets.only(left: 5, bottom: 10, right: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(Localization().getStringEx('panel.wellness.resources.header.label', 'Wellness Resources'),
              style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 22, fontFamily: Styles().fontFamilies!.extraBold)),
          HomeFavoriteStar(selected: false, style: HomeFavoriteStyle.Button, padding: EdgeInsets.symmetric(horizontal: 16))
        ]));
  }

  Widget _buildActionButtonsContainer() {
    List<Widget> widgetList = <Widget>[];
    widgetList.add(_buildActionButton(
        label: Localization().getStringEx('panel.wellness.resources.appointment.button', 'I want to make an appointment')));
    widgetList.add(_buildActionButton(
        label:
            Localization().getStringEx('panel.wellness.resources.help_person.button', 'I want to help a friend, student, or a co-worker')));
    widgetList.add(
        _buildActionButton(label: Localization().getStringEx('panel.wellness.resources.not_sure.button', "I'm not sure where to start")));
    return Column(children: widgetList);
  }

  Widget _buildActionButton({required String label}) {
    return Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Container(
            decoration: BoxDecoration(
                color: Styles().colors!.white,
                border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
                borderRadius: BorderRadius.circular(5)),
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                      child: Padding(
                          padding: EdgeInsets.only(left: 15),
                          child: Text(label,
                              style: TextStyle(
                                  color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 18)))),
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Image.asset('images/external-link.png', color: Styles().colors!.mediumGray)),
                    HomeFavoriteStar(selected: false, style: HomeFavoriteStyle.Button, padding: EdgeInsets.only(left: 7, right: 15))
                  ])
                ]))));
  }

  Widget _buildResourceButtonsContainer() {
    List<Widget> widgetList = <Widget>[];
    widgetList.add(_buildResourceButton(
        label: Localization().getStringEx('panel.wellness.resources.24_hour.button', '24-Hour Resources'), isExternalLink: false));
    widgetList.add(_buildResourceButton(
        label: Localization().getStringEx('panel.wellness.resources.accessibility.button', 'Accessibility and Accommodations')));
    widgetList
        .add(_buildResourceButton(label: Localization().getStringEx('panel.wellness.resources.after_hours.button', 'After Hours Support')));
    widgetList.add(
        _buildResourceButton(label: Localization().getStringEx('panel.wellness.resources.campus_service.button', 'Campus Service Units')));
    widgetList.add(_buildResourceButton(
        label: Localization().getStringEx('panel.wellness.resources.core_campus_resources.button', 'Core Campus Resources'),
        isExternalLink: false));
    widgetList.add(_buildResourceButton(
        label: Localization().getStringEx('panel.wellness.resources.financial_assistance.button', 'Financial Assistance')));
    widgetList.add(_buildResourceButton(
        label: Localization().getStringEx('panel.wellness.resources.fitness_recreations.button', 'Fitness and Recreations')));
    widgetList.add(
        _buildResourceButton(label: Localization().getStringEx('panel.wellness.resources.food_nutrition.button', 'Food and Nutrition')));
    widgetList.add(_buildResourceButton(
        label: Localization().getStringEx('panel.wellness.resources.health_counselling.button', 'Mental Health and Counselling')));
    widgetList.add(
        _buildResourceButton(label: Localization().getStringEx('panel.wellness.resources.nature_culture.button', 'Nature and Culture')));
    widgetList.add(_buildResourceButton(
        label: Localization().getStringEx('panel.wellness.resources.other_resources.button', 'Other Wellness Resources')));
    widgetList.add(
        _buildResourceButton(label: Localization().getStringEx('panel.wellness.resources.sexual_misconduct.button', 'Sexual Misconduct')));
    widgetList.add(_buildResourceButton(
        label: Localization().getStringEx('panel.wellness.resources.events_workshops.button', 'Wellness Events & Workshops')));
    return Column(children: widgetList);
  }

  Widget _buildResourceButton({required String label, bool isExternalLink = true, void Function()? onTap}) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            color: Styles().colors!.white,
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  HomeFavoriteStar(selected: false, style: HomeFavoriteStyle.Button, padding: EdgeInsets.symmetric(horizontal: 10)),
                  Expanded(
                      child: Text(label,
                          style:
                              TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 16))),
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Visibility(
                        visible: isExternalLink,
                        child: Padding(
                            padding: EdgeInsets.only(left: 7),
                            child: Image.asset('images/external-link.png', color: Styles().colors!.mediumGray))),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Image.asset('images/chevron-right.png'))
                  ])
                ]))));
  }
}
