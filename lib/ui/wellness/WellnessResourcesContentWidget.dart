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
    return Column(children: [_buildHeader()]);
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
}
