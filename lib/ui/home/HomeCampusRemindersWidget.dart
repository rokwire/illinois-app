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
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/accessibility/AccessiblePageView.dart';
import 'package:illinois/ui/guide/CampusGuidePanel.dart';
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
import 'package:rokwire_plugin/utils/utils.dart';

class HomeCampusRemindersWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeCampusRemindersWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.campus_reminders.label.campus_reminders', 'Campus Reminders');
  
  @override
  _HomeCampusRemindersWidgetState createState() => _HomeCampusRemindersWidgetState();
}

class _HomeCampusRemindersWidgetState extends State<HomeCampusRemindersWidget> with NotificationsListener {

  List<Map<String, dynamic>>? _reminderItems;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  Map<String, GlobalKey> _contentKeys = <String, GlobalKey>{};
  StreamSubscription<String>? _updateSubscription;

  static const String localScheme = 'local';
  static const String localUrlMacro = '{{local_url}}';
  static const String privacyUrl = 'privacy://level';
  static const String privacyUrlMacro = '{{privacy_url}}';

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      Config.notifyConfigChanged,
      Guide.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      AppLivecycle.notifyStateChanged,
    ]);

    _updateSubscription = widget.updateController?.stream.listen((String command) {
      if (command == HomePanel.notifyRefresh) {
        Guide().refresh();
      }
    });

    _reminderItems = _buildContentList();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _updateSubscription?.cancel();
    _pageController?.dispose();
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
      _updateReminderItems();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _updateReminderItems();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      if (param == AppLifecycleState.resumed) {
        _updateReminderItems(); // update on each resume for time interval filtering
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeFavoriteWidget(favoriteId: widget.favoriteId,
      title: Localization().getStringEx('widget.home.campus_reminders.label.campus_reminders', 'Campus Reminders'),
      updateController: widget.updateController,
      child: _buildContent()
    );
  }

  Widget _buildContent() {
    return  (_reminderItems?.isEmpty ?? true) ? _buildEmptyContent() : _buildRemindersContent();
  }

  Widget _buildRemindersContent() {
    Widget contentWidget;
    int visibleCount = _reminderItems?.length ?? 0; // Config().homeCampusRemindersCount
    if (1 < visibleCount) {
      
      List<Widget> pages = <Widget>[];
      for (int index = 0; index < visibleCount; index++) {
        Map<String, dynamic>? reminderItem = JsonUtils.mapValue(_reminderItems![index]);
        pages.add(Padding(
          key: _contentKeys[Guide().entryId(reminderItem) ?? ''] ??= GlobalKey(),
          padding: HomeCard.defaultPageMargin,
          child: GuideEntryCard(reminderItem,
            favoriteKey: GuideFavorite.constructFavoriteKeyName(contentType: Guide.campusReminderContentType),
            displayMode: CardDisplayMode.home,
          )
        ));
      }

      if (_pageController == null) {
        double screenWidth = MediaQuery.of(context).size.width;
        double pageViewport = (screenWidth - 2 * HomeCard.pageSpacing) / screenWidth;
        _pageController = PageController(viewportFraction: pageViewport);
      }

      contentWidget = Container(constraints: BoxConstraints(minHeight: _pageHeight), child:
        AccessiblePageView(
          key: _pageViewKey,
          controller: _pageController,
          estimatedPageSize: _pageHeight,
          allowImplicitScrolling: true,
          children: pages,
        ),
      );

    }
    else {
      contentWidget = Padding(padding: HomeCard.defaultSingleCardMargin, child:
        GuideEntryCard(_reminderItems?.first,
          favoriteKey: GuideFavorite.constructFavoriteKeyName(contentType: Guide.campusReminderContentType),
          displayMode: CardDisplayMode.home,
        )
      );
    }
    return Column(children: <Widget>[
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => visibleCount, centerWidget:
        HomeBrowseLinkButton(
          title: Localization().getStringEx('widget.home.campus_reminders.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.campus_reminders.button.all.hint', 'Tap to view all reminders'),
          onTap: _onViewAll,
        ),
      ),
    ]);
  }

  void _updateReminderItems() {
    List<Map<String, dynamic>>? reminderItems = _buildContentList();
    if (mounted && (reminderItems != null) && !DeepCollectionEquality().equals(_reminderItems, reminderItems)) {
      setState(() {
        _reminderItems = List<Map<String, dynamic>>.from(reminderItems);
        _pageViewKey = UniqueKey();
        // _pageController = null;
        if ((_reminderItems?.isNotEmpty == true) && (_pageController?.hasClients == true)) {
          _pageController?.jumpToPage(0);
        }
        _contentKeys.clear();
      });
    }
  }

  List<Map<String, dynamic>>? _buildContentList() {
    List<Map<String, dynamic>>? reminderItems = Guide().remindersList;
    if (reminderItems != null) {
      List<Map<String, dynamic>> favoritesList = <Map<String, dynamic>>[];
      for(Map<String, dynamic> reminderItem in reminderItems) {
        String? entryId = Guide().entryId(reminderItem);
        if (Auth2().account?.prefs?.isFavorite(GuideFavorite(contentType: Guide.campusReminderContentType, id: entryId)) == true) {
          favoritesList.add(reminderItem);
        }
      }
      return favoritesList;
    }
    return null;
  }

  // HomeMessageCard(message: Localization().getStringEx("", "There are no active Campus Reminders."),)
  Widget _buildEmptyContent() {
    String message = Localization().getStringEx("widget.home.campus_reminders.text.empty.description", "Tap the \u2606 on items in <a href='{{local_url}}'><b>Campus Reminders</b></a> for quick access here. (<a href='{{privacy_url}}'>Your privacy level</a> must be at least 3.)")
      .replaceAll(localUrlMacro, '$localScheme://${Guide.campusReminderContentType}')
      .replaceAll(privacyUrlMacro, privacyUrl);
      return HomeMessageHtmlCard(message: message, onTapLink: _onMessageLink,);
  }


  void _onMessageLink(String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if ((uri?.scheme == localScheme) && (uri?.host.toLowerCase() == Guide.campusReminderContentType.toLowerCase())) {
      _onCampusRemindersLink();
    }
    else if (url == privacyUrl) {
      _onPrivacyLevelLink();
    }
  }

  void _onCampusRemindersLink() {
    Analytics().logSelect(target: "Campus Guide Reminders Link", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CampusRemindersPanel()));
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
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CampusRemindersPanel()));
  }
}

