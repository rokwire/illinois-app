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
import 'dart:collection';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:illinois/ui/wellness/WellnessResourcesContentWidget.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeWellnessResourcesWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeWellnessResourcesWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.wellness_resources.header.label', 'My Wellness Resources');

  @override
  State<HomeWellnessResourcesWidget> createState() => _HomeWellnessResourcesWidgetState();

}

class _HomeWellnessResourcesWidgetState extends State<HomeWellnessResourcesWidget> implements NotificationsListener {

  List<dynamic>? _favoriteCommands;
  Map<String, dynamic>? _strings;
  
  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  Map<String, GlobalKey> _contentKeys = <String, GlobalKey>{};
  String? _currentFavoriteId;
  int _currentPage = -1;
  final double _pageSpacing = 16;

  static const String localScheme = 'local';
  static const String localUrlMacro = '{{local_url}}';


  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      Wellness.notifyResourcesContentChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        _updateContent();
      });
    }

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
    if ((name == Wellness.notifyResourcesContentChanged) ||
        (name == Auth2UserPrefs.notifyFavoritesChanged)) {
        _updateContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: HomeWellnessResourcesWidget.title,
      titleIconKey: 'wellness',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return  (_favoriteCommands?.isEmpty ?? true) ? _buildEmpty() : _buildResourceContent();
  }

  Widget _buildEmpty() {
    String favoriteKey = WellnessFavorite.favoriteKeyName(category: WellnessResourcesContentWidget.wellnessCategoryKey);
    String message = Localization().getStringEx("widget.home.wellness_resources.text.empty.description", "Tap the \u2606 on items in <a href='$localUrlMacro'><b>Wellness Resources</b></a> so you can quickly find them here.")
      .replaceAll(localUrlMacro, '$localScheme://$favoriteKey');

    return Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
      Container(decoration: BoxDecoration(color: Styles().colors!.surface, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))] ),
        padding: EdgeInsets.all(16),
        child: HtmlWidget(
            message,
            onTapUrl : (url) {_handleLocalUrl(url); return true;},
            textStyle:  Styles().textStyles?.getTextStyle("widget.item.regular.thin"),
            customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors!.fillColorSecondary ?? Colors.blue)} : null
        )
      ),
    );
  }

  Widget _buildResourceContent() {
    Widget contentWidget;
    int visibleCount = _favoriteCommands?.length ?? 0; // Config().homeWellnessResourcesCount
    if (1 < visibleCount) {

      List<Widget> pages = <Widget>[];
      for (int index = 0; index < visibleCount; index++) {
        Map<String, dynamic>? command = JsonUtils.mapValue(_favoriteCommands![index]);
        Widget? button = (command != null) ? _buildResourceButton(command) : null;
        if (button != null) {
          String? commandId = JsonUtils.stringValue(command!['id']);
          pages.add(Padding(key: _contentKeys[commandId ?? ''] ??= GlobalKey(), padding: EdgeInsets.only(right: _pageSpacing), child: button));
        }
      }

      if (_pageController == null) {
        double screenWidth = MediaQuery.of(context).size.width;
        double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
        _pageController = PageController(viewportFraction: pageViewport, initialPage: _currentPage);
      }

      contentWidget = Container(constraints: BoxConstraints(minHeight: _pageHeight), child:
        ExpandablePageView(
          key: _pageViewKey,
          controller: _pageController,
          estimatedPageSize: _pageHeight,
          onPageChanged: _onCurrentPageChanged,
          allowImplicitScrolling: true,
          children: pages,
        ),
      );
    }
    else {
      contentWidget = Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        _buildResourceButton(JsonUtils.mapValue(_favoriteCommands?.first) ?? {})
      );
    }

    return Column(children: [
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => visibleCount, centerWidget:
        LinkButton(
          title: Localization().getStringEx('widget.home.wellness_resources.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.wellness_resources.button.all.hint', 'Tap to view all wellness resources'),
          onTap: _onViewAll,
        ),
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
    Map<String, dynamic>? content = Wellness().resources;
    _strings = (content != null) ? JsonUtils.mapValue(content['strings']) : null;
    List<dynamic>? commands = (content != null) ? JsonUtils.listValue(content['commands']) : null;
    WellnessResourcesContentWidget.ensureDefaultFavorites(commands);
    _favoriteCommands = _filterFavoriteCommands(commands);
    if (_favoriteCommands?.isNotEmpty ?? false) {
      _currentPage = 0;

      Map<String, dynamic>? command = JsonUtils.mapValue(_favoriteCommands!.first);
      _currentFavoriteId =  (command != null) ? JsonUtils.stringValue(command['id']) : null;
    }
  }

  void _updateContent() {
    Map<String, dynamic>? content = Wellness().resources;
    Map<String, dynamic>? strings = (content != null) ? JsonUtils.mapValue(content['strings']) : null;
    List<dynamic>? commands = (content != null) ? JsonUtils.listValue(content['commands']) : null;
    WellnessResourcesContentWidget.ensureDefaultFavorites(commands);
    List<dynamic>? favoriteCommands = _filterFavoriteCommands(commands);

    if (mounted && (favoriteCommands != null) && !DeepCollectionEquality().equals(_favoriteCommands, favoriteCommands)) {
      setState(() {
        _favoriteCommands = favoriteCommands;
        _strings = strings;
        _updateCurrentPage();
      });
    }
  }

  static List<dynamic>? _filterFavoriteCommands(List<dynamic>? commands) {
    List<dynamic>? favoriteCommands;
    LinkedHashSet<String>? wellnessFavorites = Auth2().prefs?.getFavorites(WellnessFavorite.favoriteKeyName(category: WellnessResourcesContentWidget.wellnessCategoryKey));
    if ((wellnessFavorites != null) && (commands != null)) {
      favoriteCommands = [];
      for (String favoriteId in wellnessFavorites) {
        for (dynamic entry in commands) {
          Map<String, dynamic>? command = JsonUtils.mapValue(entry);
          if (command != null) {
            String? commandId = JsonUtils.stringValue(command['id']);
            if (commandId == favoriteId)  {
              favoriteCommands.add(entry);
              break;
            }
          }
        }
      }
    }
    return favoriteCommands;
  }

  int _findFavorite(String? favoriteId) {
    if (_favoriteCommands != null) {
      for (int index = 0; index < _favoriteCommands!.length; index++) {
        Map<String, dynamic>? command = JsonUtils.mapValue(_favoriteCommands![index]);
        String? commandId = (command != null) ? JsonUtils.stringValue(command['id']) : null;
        if (commandId == favoriteId) {
          return index;
        }
      }
    }
    return -1;
  }

  void _updateCurrentPage() {
    if (_favoriteCommands?.isNotEmpty ?? false)  {
      int currentPage = (_currentFavoriteId != null) ? _findFavorite(_currentFavoriteId!) : -1;
      if (currentPage < 0) {
        currentPage = max(0, min(_currentPage, _favoriteCommands!.length - 1));
      }

      Map<String, dynamic>? command = JsonUtils.mapValue(ListUtils.entry(_favoriteCommands, _currentPage = currentPage));
      _currentFavoriteId = (command != null) ? JsonUtils.stringValue(command['id']) : null;
    }
    else {
      _currentPage = -1;
      _currentFavoriteId = null;
    }

    _pageViewKey = UniqueKey();
    // _pageController = null;
    _pageController?.jumpToPage(0);
    _contentKeys.clear();
  }

  void _onCurrentPageChanged(int index) {
    Map<String, dynamic>? command = JsonUtils.mapValue(ListUtils.entry(_favoriteCommands, _currentPage = index));
    _currentFavoriteId = (command != null) ? JsonUtils.stringValue(command['id']) : null;
  }

  double get _pageHeight {

    double? minContentHeight;
    for(GlobalKey contentKey in _contentKeys.values) {
      final RenderObject? renderBox = contentKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && ((minContentHeight == null) || (renderBox.size.height < minContentHeight))) {
        minContentHeight = renderBox.size.height;
      }
    }

    return minContentHeight ?? 0;
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

  void _handleLocalUrl(String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if ((uri?.scheme == localScheme) && (uri?.host.toLowerCase() == WellnessFavorite.favoriteKeyName(category: WellnessResourcesContentWidget.wellnessCategoryKey).toLowerCase())) {
      Analytics().logSelect(target: "View Home", source: widget.runtimeType.toString());
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(content: WellnessContent.resources,)));
    }
  }

  void _onViewAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(content: WellnessContent.resources,)));
  }

  void _onCommand(Map<String, dynamic> command) {
    String? resourceName = _getString(JsonUtils.stringValue(command['id']), languageCode: Localization().defaultLocale?.languageCode);
    Analytics().logSelect(target: "Resource: '$resourceName'" , source: widget.runtimeType.toString());
    _launchUrl(JsonUtils.stringValue(command['url']));
  }

  void _launchUrl(String? url) {
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    }
  }
}

