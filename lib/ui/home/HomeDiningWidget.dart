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

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/localization.dart';

class HomeDiningWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeDiningWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.dinings.header.title', 'Dining');

  @override
  State<StatefulWidget> createState() => _HomeDiningWidgetState();
}

class _HomeDiningWidgetState extends HomeCompoundWidgetState<HomeDiningWidget> {

  @override String? get favoriteId => widget.favoriteId;
  @override String? get title => HomeDiningWidget.title;
  @override String? get titleIconKey => 'dining';
  @override String? get emptyMessage => Localization().getStringEx("widget.home.dinings.text.empty.description", "Tap the \u2606 on items in Dinings so you can quickly find them here.");

  @override
  Widget? widgetFromCode(String code) {
    if (code == 'dinings_all') {
      return HomeCommandButton(
        title: Localization().getStringEx('widget.home.dinings.all.button.title', 'Residence Hall Dining'),
        description: Localization().getStringEx('widget.home.dinings.all.button.description', 'Students, faculty, staff, and visitors are welcome to eat at any residence hall dining location.'),
        favorite: HomeFavorite(code, category: widget.favoriteId),
        onTap: _onTapDiningsAll,
      );
    }
    else if (code == 'dinings_open') {
      return HomeCommandButton(
        title: Localization().getStringEx('widget.home.dinings.open.button.title', 'Residence Hall Dining Open Now'),
        description: Localization().getStringEx('widget.home.dinings.open.button.description', 'Quick access to any locations that are currently open.'),
        favorite: HomeFavorite(code, category: widget.favoriteId),
        onTap: _onTapDiningsOpen,
      );
    }
    else {
      return null;
    }
  }
  
  void _onTapDiningsAll() {
    Analytics().logSelect(target: "Residence Hall Dining", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(exploreType: ExploreType.Dining) ));
  }

  void _onTapDiningsOpen() {
    Analytics().logSelect(target: "Residence Hall Dining Open Now", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExplorePanel(exploreType: ExploreType.Dining, initialFilter: ExploreFilter(type: ExploreFilterType.work_time, selectedIndexes: {1}))));
  }
}
