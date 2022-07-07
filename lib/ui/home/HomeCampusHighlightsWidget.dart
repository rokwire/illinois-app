import 'dart:async';

import 'package:collection/collection.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/main.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
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

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.campus_guide_highlights.label.heading', 'Campus Guide Highlights');
  
  @override
  _HomeCampusHighlightsWidgetState createState() => _HomeCampusHighlightsWidgetState();
}

class _HomeCampusHighlightsWidgetState extends State<HomeCampusHighlightsWidget> implements NotificationsListener {

  List<Map<String, dynamic>>? _promotedItems;
  PageController? _pageController;
  final double _pageSpacing = 16;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      Config.notifyConfigChanged,
      Guide.notifyChanged,
      Auth2UserPrefs.notifyRolesChanged,
      AppLivecycle.notifyStateChanged,
      Auth2.notifyCardChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          Guide().refresh();
        }
      });
    }

    double screenWidth = MediaQuery.of(App.instance?.currentContext ?? context).size.width;
    double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
    _pageController = PageController(viewportFraction: pageViewport);

    _promotedItems = Guide().promotedList;
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
      titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
      childPadding: EdgeInsets.zero,
      child: _buildContent() 
    );
  }

  Widget _buildContent() {
    return  (_promotedItems?.isEmpty ?? true) ? HomeMessageCard(
      title: Localization().getStringEx("widget.home.campus_guide_highlights.text.empty", "Whoops! Nothing to see here."),
      message: Localization().getStringEx("widget.home.campus_guide_highlights.text.empty.description", "There are no active Campus Guide Highlights."),
    ) : _buildPromotedContent();
  }

  Widget _buildPromotedContent() {
    Widget contentWidget;
    int visibleCount = _promotedItems?.length ?? 0; // Config().homeCampusHighlightsCount

    if (1 < visibleCount) {
      
      double pageHeight = (18 + 16) * MediaQuery.of(context).textScaleFactor + 4 + 8 + 2 * 16;

      List<Widget> pages = <Widget>[];
      for (int index = 0; index < visibleCount; index++) {
        pages.add(Padding(padding: EdgeInsets.only(right: _pageSpacing + 2, bottom: 2), child:
          GuideEntryCard(JsonUtils.mapValue(_promotedItems![index]))
        ));
      }

      contentWidget = Container(constraints: BoxConstraints(minHeight: pageHeight), child:
        ExpandablePageView(controller: _pageController, children: pages, estimatedPageSize: pageHeight),
      );

    }
    else {
      contentWidget = Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        GuideEntryCard(_promotedItems?.first)
      );
    }

    return Column(children: <Widget>[
      contentWidget,
      LinkButton(
            title: Localization().getStringEx('widget.home.campus_guide_highlights.button.all.title', 'View All'),
            hint: Localization().getStringEx('widget.home.campus_guide_highlights.button.all.hint', 'Tap to view all highlights'),
        onTap: _onSeeAll,
      ),
    ]);
  }

  void _updatePromotedItems() {
    List<Map<String, dynamic>>? promotedItems = Guide().promotedList;
    if (!DeepCollectionEquality().equals(_promotedItems, promotedItems)) {
      setState(() {
        _promotedItems = promotedItems;
      });
    }
  }

  void _onSeeAll() {
    Analytics().logSelect(target: "HomeCampusHighlightsWidget View All");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(contentList: _promotedItems, contentTitle: Localization().getStringEx('panel.guide_list.label.highlights.section', 'Highlights'))));
  }
}