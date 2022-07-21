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
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class HomeCampusLinksWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeCampusLinksWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.campus_links.header.title', 'Campus Links');

  @override
  State<StatefulWidget> createState() => _HomeCampusLinksWidgetState();
}

class _HomeCampusLinksWidgetState extends HomeCompoundWidgetState<HomeCampusLinksWidget> implements NotificationsListener{

  @override String? get favoriteId => widget.favoriteId;
  @override String? get title => HomeCampusLinksWidget.title;
  @override String? get emptyMessage => Localization().getStringEx("widget.home.campus_links.text.empty.description", "Tap the \u2606 on items in Campus Links so you can quickly find them here.");


  @override
  Widget? widgetFromCode(String code) {
    if ((code == 'due_date_catalog') && _canDueDateCatalog) {
      return HomeCommandButton(
        title: Localization().getStringEx('widget.home.campus_links.date_cat.button.title', 'Due Date Catalog'),
        description: Localization().getStringEx('widget.home.campus_links.date_cat.button.description', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'),
        favorite: HomeFavorite(code, category: widget.favoriteId),
        onTap: _onDueDateCatalog,
      );
    }
    else {
      return null;
    }
  }
  
  bool get _canDueDateCatalog => StringUtils.isNotEmpty(Config().dateCatalogUrl);

  void _onDueDateCatalog() {
    Analytics().logSelect(target: "Due Date Catalog", source: widget.runtimeType.toString());
    
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('widget.home.campus_links.date_cat.label.offline', 'Due Date Catalog not available while offline.'));
    }
    else if (_canDueDateCatalog) {
      url_launcher.launch(Config().dateCatalogUrl!);
    }
  }
}
