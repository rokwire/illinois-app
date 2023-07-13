import 'dart:async';

import 'package:collection/collection.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/guide/GuideEntryCard.dart';
import 'package:illinois/ui/guide/GuideListPanel.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeCampusHighlightsWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeCampusHighlightsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.campus_guide_highlights.label.heading', 'Campus Guide Highlights');
  
  @override
  _HomeCampusHighlightsWidgetState createState() => _HomeCampusHighlightsWidgetState();
}

class _HomeCampusHighlightsWidgetState extends State<HomeCampusHighlightsWidget> implements NotificationsListener {

  List<Map<String, dynamic>>? _promotedItems;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  Map<String, GlobalKey> _contentKeys = <String, GlobalKey>{};
  final double _pageSpacing = 16;

  static const String localScheme = 'local';
  static const String localUrlMacro = '{{local_url}}';

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      Config.notifyConfigChanged,
      Guide.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      Auth2UserPrefs.notifyRolesChanged,
      Auth2.notifyCardChanged,
      AppLivecycle.notifyStateChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          Guide().refresh();
        }
      });
    }

    _promotedItems = _buildContentList();
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
    if (name == Config.notifyConfigChanged) {
      if (mounted) {
        setState(() {});
      }
    }
    else if (name == Guide.notifyChanged) {
      _updatePromotedItems();
    }
    else if (name == Auth2UserPrefs.notifyRolesChanged) {
      _updatePromotedItems();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      _updatePromotedItems();
    }
    else if (name == Auth2.notifyCardChanged) {
      _updatePromotedItems();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      if (param == AppLifecycleState.resumed) {
        _updatePromotedItems(); // update on each resume for time interval filtering
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: Localization().getStringEx('widget.home.campus_guide_highlights.label.heading', 'Campus Guide Highlights'),
      titleIconKey: 'campus-tools',
      child: _buildContent() 
    );
  }

  Widget _buildContent() {
    return  (_promotedItems?.isEmpty ?? true) ? _buildEmptyContent() : _buildPromotedContent();
  }

  Widget _buildPromotedContent() {
    Widget contentWidget;
    int visibleCount = _promotedItems?.length ?? 0; // Config().homeCampusHighlightsCount

    if (1 < visibleCount) {
      
      List<Widget> pages = <Widget>[];
      for (int index = 0; index < visibleCount; index++) {
        Map<String, dynamic>? promotedItem = JsonUtils.mapValue(_promotedItems![index]);
        pages.add(Padding(key: _contentKeys[Guide().entryId(promotedItem) ?? ''] ??= GlobalKey(), padding: EdgeInsets.only(right: _pageSpacing + 2, bottom: 8), child:
          GuideEntryCard(promotedItem)
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
        GuideEntryCard(_promotedItems?.first)
      );
    }

    return Column(children: <Widget>[
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => visibleCount, centerWidget:
        LinkButton(
              title: Localization().getStringEx('widget.home.campus_guide_highlights.button.all.title', 'View All'),
              hint: Localization().getStringEx('widget.home.campus_guide_highlights.button.all.hint', 'Tap to view all highlights'),
          onTap: _onViewAll,
        ),
      ),
    ]);
  }

  void _updatePromotedItems() {
    List<Map<String, dynamic>>? promotedItems = _buildContentList();
    if (mounted && (promotedItems != null) && !DeepCollectionEquality().equals(_promotedItems, promotedItems)) {
      setState(() {
        _promotedItems = promotedItems;
        _pageViewKey = UniqueKey();
        // _pageController = null;
        _pageController?.jumpToPage(0);
        _contentKeys.clear();
      });
    }
  }

  List<Map<String, dynamic>>? _buildContentList() {
    List<Map<String, dynamic>>? promotedItems = Guide().promotedList;
    if (promotedItems != null) {
      List<Map<String, dynamic>> favoritesList = <Map<String, dynamic>>[];
      for(Map<String, dynamic> promotedItem in promotedItems) {
        String? entryId = Guide().entryId(promotedItem);
        if (Auth2().account?.prefs?.isFavorite(GuideFavorite(contentType: Guide.campusHighlightContentType, id: entryId)) ?? false) {
          favoritesList.add(promotedItem);
        }
      }
      return favoritesList;
    }
    return null;
  }

  Widget _buildEmptyContent() {
    String message = Localization().getStringEx("widget.home.campus_guide_highlights.text.empty.description", "Tap the \u2606 on items in <a href='{{local_url}}'><b>Campus Guide Highlights</b></a> for quick access here.")
      .replaceAll(localUrlMacro, '$localScheme://${Guide.campusHighlightContentType}');
      return HomeMessageHtmlCard(message: message, onTapLink: _onMessageLink,);
  }

  void _onMessageLink(String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if ((uri?.scheme == localScheme) && (uri?.host.toLowerCase() == Guide.campusHighlightContentType.toLowerCase())) {
      _onCampusHighlightLink();
    }
  }

  void _onCampusHighlightLink() {
    Analytics().logSelect(target: "Campus Guide Highlight Link", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(
      contentList: Guide().promotedList,
      contentTitle: Localization().getStringEx('panel.guide_list.label.highlights.section', 'Campus Highlights'),
      contentEmptyMessage: Localization().getStringEx("panel.guide_list.label.highlights.empty", "There are no active Campus Hightlights."),
      favoriteKey: GuideFavorite.constructFavoriteKeyName(contentType: Guide.campusHighlightContentType),
    )));
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

  void _onViewAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(
      contentList: Guide().promotedList,
      contentTitle: Localization().getStringEx('panel.guide_list.label.highlights.section', 'Campus Highlights'),
      contentEmptyMessage: Localization().getStringEx("panel.guide_list.label.highlights.empty", "There are no active Campus Guide Highlights."),
      favoriteKey: GuideFavorite.constructFavoriteKeyName(contentType: Guide.campusHighlightContentType),
    )));
  }
}