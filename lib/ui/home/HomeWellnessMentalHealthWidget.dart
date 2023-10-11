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
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Guide.dart';
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

class HomeWellnessMentalHealthWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeWellnessMentalHealthWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.wellness_mental_health.header.label', 'My Mental Health Resources');

  @override
  State<HomeWellnessMentalHealthWidget> createState() => _HomeWellnessMentalHealthWidgetState();

}

class _HomeWellnessMentalHealthWidgetState extends State<HomeWellnessMentalHealthWidget> implements NotificationsListener {

  List<Map<String, dynamic>>? _resourceItems;
  
  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  Map<String, GlobalKey> _contentKeys = <String, GlobalKey>{};
  int _currentPage = -1;
  final double _pageSpacing = 16;

  static const String localScheme = 'local';
  static const String localUrlMacro = '{{local_url}}';


  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      Guide.notifyChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          Guide().refresh();
        }
      });
    }

    _resourceItems = _buildResourceItems();
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
    if ((name == Guide.notifyChanged) ||
        (name == Auth2UserPrefs.notifyFavoritesChanged)) {
        _updateResourceItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: HomeWellnessMentalHealthWidget.title,
      titleIconKey: 'wellness',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return  (_resourceItems?.isEmpty ?? true) ? _buildEmpty() : _buildResourceContent();
  }

  Widget _buildEmpty() {
    String favoriteKey = WellnessFavorite.favoriteKeyName(category: WellnessResourcesContentWidget.wellnessCategoryKey);
    String message = Localization().getStringEx("widget.home.wellness_mental_health.text.empty.description", "Tap the \u2606 on items in <a href='$localUrlMacro'><b>Metnal Heatlh Resources</b></a> so you can quickly find them here.")
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
    int visibleCount = _resourceItems?.length ?? 0; // Config().homeWellnessResourcesCount
    if (1 < visibleCount) {

      List<Widget> pages = <Widget>[];
      for (int index = 0; index < visibleCount; index++) {
        Map<String, dynamic>? resourceItem = JsonUtils.mapValue(_resourceItems![index]);
        Widget? button = (resourceItem != null) ? _buildResourceButton(resourceItem) : null;
        if (button != null) {
          String? resourceId = Guide().entryId(resourceItem);
          pages.add(Padding(key: _contentKeys[resourceId ?? ''] ??= GlobalKey(), padding: EdgeInsets.only(right: _pageSpacing), child: button));
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
          allowImplicitScrolling: true,
          children: pages,
        ),
      );
    }
    else {
      contentWidget = Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        _buildResourceButton(JsonUtils.mapValue(_resourceItems?.first) ?? {})
      );
    }

    return Column(children: [
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => visibleCount, centerWidget:
        LinkButton(
          title: Localization().getStringEx('widget.home.wellness_mental_health.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.wellness_mental_health.button.all.hint', 'Tap to view all mental heatlh resources'),
          onTap: _onViewAll,
        ),
      ),
    ],);
  }

  Widget? _buildResourceButton(Map<String, dynamic> resourceItem) {
    
    String? id = Guide().entryId(resourceItem);
    String? title = Guide().entryListTitle(resourceItem);
    Favorite favorite = GuideFavorite(id: id, contentType: Guide.wellnessMentalHealthContentType);

    return WellnessLargeResourceButton(
      label: title,
      favorite: favorite,
      onTap: () => _onCommand(resourceItem),
    );
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

  void _updateResourceItems() {
    List<Map<String, dynamic>>? resourceItems = _buildResourceItems();
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

  List<Map<String, dynamic>>? _buildResourceItems() {
    List<Map<String, dynamic>>? mentalHealthList = Guide().mentalHealthList;
    if (mentalHealthList != null) {
      List<Map<String, dynamic>> favoritesList = <Map<String, dynamic>>[];
      for(Map<String, dynamic> menatlHealthEntry in mentalHealthList) {
        String? entryId = Guide().entryId(menatlHealthEntry);
        if (Auth2().account?.prefs?.isFavorite(GuideFavorite(contentType: Guide.wellnessMentalHealthContentType, id: entryId)) ?? false) {
          favoritesList.add(menatlHealthEntry);
        }
      }
      return favoritesList;
    }
    return null;
  }

  void _handleLocalUrl(String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if ((uri?.scheme == localScheme) && (uri?.host.toLowerCase() == WellnessFavorite.favoriteKeyName(category: WellnessResourcesContentWidget.wellnessCategoryKey).toLowerCase())) {
      Analytics().logSelect(target: "View Home", source: widget.runtimeType.toString());
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(content: WellnessContent.mentalHealth,)));
    }
  }

  void _onViewAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(content: WellnessContent.mentalHealth,)));
  }

  void _onCommand(Map<String, dynamic> resourceItem) {
    String? title = Guide().entryListTitle(resourceItem);
    Analytics().logSelect(target: "Mental Health Resource: '$title'" , source: widget.runtimeType.toString());

    String? id = Guide().entryId(resourceItem);
    String? url = "${Guide().guideDetailUrl}?guide_id=$id";
    if (DeepLink().isAppUrl(url)) {
      DeepLink().launchUrl(url);
    }
    else {
      Uri? uri = Uri.tryParse(url);
      if (uri != null) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}

