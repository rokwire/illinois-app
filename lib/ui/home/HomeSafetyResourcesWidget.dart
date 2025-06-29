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

import 'package:collection/collection.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/guide/GuideEntryCard.dart';
import 'package:illinois/ui/guide/GuideListPanel.dart';
import 'package:rokwire_plugin/utils/utils.dart';

abstract class _HomeSafetyResourcesBaseWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  _HomeSafetyResourcesBaseWidget({super.key, this.favoriteId, this.updateController});

  String get _title;
  String get _localUrlMacro => '{{local_url}}';
  String get _privacyUrlMacro => '{{local_url}}';
  String get _emptyContentDescription;
  String get _listContentTitle;
  String get _listEmptyContentDescription;

  @override
  State<StatefulWidget> createState() => _HomeSafetyResourcesBaseWidgetState();
}

class HomeSafetyResourcesWidget extends _HomeSafetyResourcesBaseWidget {
  HomeSafetyResourcesWidget({super.key, super.favoriteId, super.updateController});

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.safety_resources.label.title', 'Safety Resources');

  @override String get _title => title;
  @override String get _emptyContentDescription => Localization().getStringEx("widget.home.safety_resources.text.empty.description", "Tap the \u2606 on items in <a href='$_localUrlMacro'><b>Safety Resources</b></a> for quick access here. (<a href='$_privacyUrlMacro'>Your privacy level</a> must be at least 2.)");
  @override String get _listContentTitle => Localization().getStringEx('panel.guide_list.label.safety_resources.section', 'Safety Resources');
  @override String get _listEmptyContentDescription => Localization().getStringEx("panel.guide_list.label.safety_resources.empty", "There are no active Safety Resources.");
}

class HomeCampusSafetyResourcesWidget extends _HomeSafetyResourcesBaseWidget {
  HomeCampusSafetyResourcesWidget({super.key, super.favoriteId, super.updateController});

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.campus_safety_resources.label.campus_safety_resources', 'Campus Safety Resources');

  @override String get _title => title;
  @override String get _emptyContentDescription => Localization().getStringEx("widget.home.campus_safety_resources.text.empty.description", "Tap the \u2606 on items in <a href='$_localUrlMacro'><b>Campus Safety Resources</b></a> for quick access here. (<a href='$_privacyUrlMacro'>Your privacy level</a> must be at least 2.");
  @override String get _listContentTitle => Localization().getStringEx('panel.guide_list.label.campus_safety_resources.section', 'Safety Resources');
  @override String get _listEmptyContentDescription => Localization().getStringEx("panel.guide_list.label.campus_safety_resources.empty", "There are no active Campus Safety Resources.");
}

class _HomeSafetyResourcesBaseWidgetState extends State<_HomeSafetyResourcesBaseWidget> with NotificationsListener {

  List<Map<String, dynamic>>? _resourceItems;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  Map<String, GlobalKey> _contentKeys = <String, GlobalKey>{};
  final double _pageSpacing = 16;

  static const String localScheme = 'local';
  static const String privacyScheme = 'privacy';
  static const String privacyLevelHost = 'level';

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      Config.notifyConfigChanged,
      Guide.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      AppLivecycle.notifyStateChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          Guide().refresh();
        }
      });
    }

    _resourceItems = _buildContentList();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Config.notifyConfigChanged) {
      if (mounted) {
        setState(() {});
      }
    }
    else if (name == Guide.notifyChanged) {
      _updateResourceItems();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _updateResourceItems();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      if (param == AppLifecycleState.resumed) {
        _updateResourceItems(); // update on each resume for time interval filtering
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeFavoriteWidget(favoriteId: widget.favoriteId,
      title: widget._title,
      child: _buildContent()
    );
  }

  Widget _buildContent() {
    return  (_resourceItems?.isEmpty ?? true) ?  _buildEmptyContent() : _buildResourceContent();
  }

  Widget _buildResourceContent() {
    Widget contentWidget;
    int visibleCount = _resourceItems?.length ?? 0; // Config().homeCampusRemindersCount
    if (1 < visibleCount) {
      
      List<Widget> pages = <Widget>[];
      for (int index = 0; index < visibleCount; index++) {
        Map<String, dynamic>? reminderItem = JsonUtils.mapValue(_resourceItems![index]);
        pages.add(Padding(key: _contentKeys[Guide().entryId(reminderItem) ?? ''] ??= GlobalKey(), padding: EdgeInsets.only(right: _pageSpacing + 2, bottom: 2), child:
          GuideEntryCard(reminderItem, favoriteKey: GuideFavorite.constructFavoriteKeyName(contentType: Guide.campusSafetyResourceContentType), displayMode: GuideEntryCardDisplayMode.home,)
        ));
      }

      if (_pageController == null) {
        double screenWidth = MediaQuery.of(context).size.width;
        double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
        _pageController = PageController(viewportFraction: pageViewport);
      }

      contentWidget = Container(constraints: BoxConstraints(minHeight: _pageHeight), child:
        ExpandablePageView(
          key: _pageViewKey,
          controller: _pageController,
          estimatedPageSize: _pageHeight,
          allowImplicitScrolling: true,
          children: pages,
        ),
      );

    }
    else {
      contentWidget = Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        GuideEntryCard(_resourceItems?.first, favoriteKey: GuideFavorite.constructFavoriteKeyName(contentType: Guide.campusSafetyResourceContentType), displayMode: GuideEntryCardDisplayMode.home)
      );
    }
    return Column(children: <Widget>[
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => visibleCount, centerWidget:
       HomeBrowseLinkButton(
          title: Localization().getStringEx('widget.home.safety_resources.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.safety_resources.button.all.hint', 'Tap to view all safety resources'),
          onTap: _onViewAll,
        ),
      ),
    ]);
  }

  void _updateResourceItems() {
    List<Map<String, dynamic>>? resourceItems = _buildContentList();
    if (mounted && (resourceItems != null) && !DeepCollectionEquality().equals(_resourceItems, resourceItems)) {
      setState(() {
        _resourceItems = resourceItems;
        _pageViewKey = UniqueKey();
        // _pageController = null;
        _pageController?.jumpToPage(0);
        _contentKeys.clear();
      });
    }
  }

  List<Map<String, dynamic>>? _buildContentList() {
    List<Map<String, dynamic>>? safetyResourcesList = Guide().safetyResourcesList;
    if (safetyResourcesList != null) {
      List<Map<String, dynamic>> favoritesList = <Map<String, dynamic>>[];
      for(Map<String, dynamic> safetyResourceEntry in safetyResourcesList) {
        String? entryId = Guide().entryId(safetyResourceEntry);
        if (Auth2().account?.prefs?.isFavorite(GuideFavorite(contentType: Guide.campusSafetyResourceContentType, id: entryId)) ?? false) {
          favoritesList.add(safetyResourceEntry);
        }
      }
      return favoritesList;
    }
    return null;
  }

  Widget _buildEmptyContent() {
    String message = widget._emptyContentDescription
      .replaceAll(widget._localUrlMacro, '$localScheme://${Guide.campusSafetyResourceContentType}')
      .replaceAll(widget._privacyUrlMacro, '$privacyScheme://$privacyLevelHost');
    return HomeMessageHtmlCard(message: message, onTapLink: _onMessageLink,);
  }

  void _onMessageLink(String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if ((uri?.scheme == localScheme) && (uri?.host.toLowerCase() == Guide.campusSafetyResourceContentType.toLowerCase())) {
      _onCampusSafetyResourceLink();
    }
    else if ((uri?.scheme == privacyScheme) && (uri?.host == privacyLevelHost)) {
      _onPrivacyLevelLink();
    }
  }

  void _onCampusSafetyResourceLink() {
    Analytics().logSelect(target: "Campus Safety Resources Link", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(
      contentList: Guide().safetyResourcesList,
      contentTitle: widget._listContentTitle,
      contentEmptyMessage: widget._listEmptyContentDescription,
      favoriteKey: GuideFavorite.constructFavoriteKeyName(contentType: Guide.campusSafetyResourceContentType),
    )));
  }

  void _onPrivacyLevelLink() {
    Analytics().logSelect(target: "Privacy Level", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,)));
  }

  double get _pageHeight {

    double? minContentHeight;
    for(GlobalKey contentKey in _contentKeys.values) {
      final RenderObject? renderBox = contentKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && renderBox.hasSize && ((minContentHeight == null) || (renderBox.size.height < minContentHeight))) {
        minContentHeight = renderBox.size.height;
      }
    }

    return minContentHeight ?? 0;
  }

  void _onViewAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(
      contentList: Guide().safetyResourcesList,
      contentTitle: widget._listContentTitle,
      contentEmptyMessage: widget._listEmptyContentDescription,
      favoriteKey: GuideFavorite.constructFavoriteKeyName(contentType: Guide.campusSafetyResourceContentType),
    )));
  }

}

