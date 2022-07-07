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
import 'dart:math';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/main.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:illinois/ui/wellness/WellnessResourcesContentWidget.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeWellnessResourcesWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeWellnessResourcesWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.wellness_resources.header.label', 'My Wellness Resources');

  @override
  State<HomeWellnessResourcesWidget> createState() => _HomeWellnessResourcesWidgetState();

}

class _HomeWellnessResourcesWidgetState extends State<HomeWellnessResourcesWidget> implements NotificationsListener {

  List<dynamic>? _commands;
  Map<String, dynamic>? _strings;
  PageController? _pageController;
  final double _pageSpacing = 16;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      Assets.notifyChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        setState(() {
          _initContent();
        });
      });
    }

    double screenWidth = MediaQuery.of(App.instance?.currentContext ?? context).size.width;
    double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
    _pageController = PageController(viewportFraction: pageViewport);

    _initContent();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _pageController?.dispose();
    super.dispose();
  }
  
  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if ((name == Assets.notifyChanged) ||
        (name == Auth2UserPrefs.notifyFavoritesChanged)) {
      if (mounted) {
        setState(() {
          _initContent();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: HomeWellnessResourcesWidget.title,
      titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
      childPadding: EdgeInsets.zero,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return  (_commands?.isEmpty ?? true) ? HomeMessageCard(
      title: Localization().getStringEx("widget.home.wellness_resources.text.empty", "Whoops! Nothing to see here."),
      message: Localization().getStringEx("widget.home.wellness_resources.text.empty.description", "Tap the \u2606 on items in Wellness Resources so you can quickly find them here."),
    ) : _buildResourceContent();
  }

  Widget _buildResourceContent() {
    Widget contentWidget;
    int visibleCount = min(Config().homeWellnessResourcesCount, _commands?.length ?? 0);
    if (1 < visibleCount) {

      double pageHeight = 18 * MediaQuery.of(context).textScaleFactor + 2 * 16;

      List<Widget> pages = <Widget>[];
      for (int index = 0; index < visibleCount; index++) {
        Map<String, dynamic>? command = JsonUtils.mapValue(_commands![index]);
        Widget? button = (command != null) ? _buildResourceButton(command) : null;
        if (button != null) {
          pages.add(Padding(padding: EdgeInsets.only(right: _pageSpacing), child: button));
        }
      }

      contentWidget = Container(constraints: BoxConstraints(minHeight: pageHeight), child:
        ExpandablePageView(controller: _pageController, children: pages, estimatedPageSize: pageHeight),
      );
    }
    else {
      contentWidget = Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        _buildResourceButton(JsonUtils.mapValue(_commands?.first) ?? {})
      );
    }

    return Column(children: [
      contentWidget,
      LinkButton(
        title: Localization().getStringEx('widget.home.wellness_resources.button.all.title', 'View All'),
        hint: Localization().getStringEx('widget.home.wellness_resources.button.all.hint', 'Tap to view all wellness resources'),
        onTap: _onViewAll,
      ),
    ],);
  }

  Widget? _buildResourceButton(Map<String, dynamic> command) {
    String? id = JsonUtils.stringValue(command['id']);
    Favorite favorite = WellnessFavorite(id, category: WellnessResourcesContentWidget.wellnessCategoryKey);
    String? url = JsonUtils.stringValue(command['url']);
    String? type = JsonUtils.stringValue(command['type']);
    if (type == 'large') {
      return WellnessLargeResourceButton(
        label: _getString(id),
        favorite: favorite,
        hasExternalLink: UrlUtils.isWebScheme(url),
        onTap: () => _onCommand(command),
      );
    }
    else if (type == 'regular') {
      return WellnessRegularResourceButton(
        label: _getString(id),
        favorite: favorite,
        hasExternalLink: UrlUtils.isWebScheme(url),
        hasBorder: true,
        onTap: () => _onCommand(command),
      );
    }
    else {
      return null;
    }
  }

  void _initContent() {
    Map<String, dynamic>? content = JsonUtils.mapValue(Assets()['wellness.${WellnessResourcesContentWidget.wellnessCategoryKey}']) ;
    _strings = (content != null) ? JsonUtils.mapValue(content['strings']) : null;
    _commands = null;
    List<dynamic>? commands = (content != null) ? JsonUtils.listValue(content['commands']) : null;
    if (commands != null) {
      _commands = [];
      for (dynamic entry in commands) {
        Map<String, dynamic>? command = JsonUtils.mapValue(entry);
        if (command != null) {
          String? id = JsonUtils.stringValue(command['id']);
          Favorite favorite = WellnessFavorite(id, category: WellnessResourcesContentWidget.wellnessCategoryKey);
          if (Auth2().prefs?.isFavorite(favorite) ?? false) {
            _commands?.add(entry);
          }
        }
      }
    }
  }

  String? _getString(String? key, {String? languageCode}) {
    if ((_strings != null) && (key != null)) {
      Map<String, dynamic>? mapping =
        JsonUtils.mapValue(_strings![languageCode]) ??
        JsonUtils.mapValue(_strings![Localization().currentLocale?.languageCode]) ??
        JsonUtils.mapValue(_strings![Localization().defaultLocale?.languageCode]);
      if (mapping != null) {
        return JsonUtils.stringValue(mapping[key]);
      }
    }
    return null;
  }

  void _onViewAll() {
    Analytics().logSelect(target: "HomeWellnessResourcesWidget View All");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(content: WellnessContent.resources,)));
  }

  void _onCommand(Map<String, dynamic> command) {
    Analytics().logSelect(target: _getString(JsonUtils.stringValue(command['id']), languageCode: Localization().defaultLocale?.languageCode),);
    _launchUrl(JsonUtils.stringValue(command['url']));
  }

  void _launchUrl(String? url) {
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else if (UrlUtils.launchInternal(url)){
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      }
      else{
        launch(url!);
      }
    }
  }
}

