import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
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
          _updatePromotedItems();
        }
      });
    }

    _promotedItems = Guide().promotedList;
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
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
    return Visibility(visible: CollectionUtils.isNotEmpty(_promotedItems), child:
        HomeSlantWidget(favoriteId: widget.favoriteId,
          title: Localization().getStringEx('widget.home.campus_guide_highlights.label.heading', 'Campus Guide Highlights'),
          titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
          child: Column(children: _buildPromotedList(),) 
        ),
    );
  }

  void _updatePromotedItems() {
    List<Map<String, dynamic>>? promotedItems = Guide().promotedList;
    if (!DeepCollectionEquality().equals(_promotedItems, promotedItems)) {
      setState(() {
        _promotedItems = promotedItems;
      });
    }
  }

  List<Widget> _buildPromotedList() {
    List<Widget> contentList = <Widget>[];
    if (_promotedItems != null) {
      int promotedCount = min(_promotedItems!.length, Config().homeCampusHighlightsCount);
      for (int index = 0; index < promotedCount; index++) {
        Map<String, dynamic>? promotedItem = _promotedItems![index];
        if (contentList.isNotEmpty) {
          contentList.add(Container(height: 8,));
        }
        contentList.add(GuideEntryCard(promotedItem));
      }
      if (promotedCount < _promotedItems!.length) {
          contentList.add(LinkButton(
            title: Localization().getStringEx('widget.home.campus_guide_highlights.button.all.title', 'View All'),
            hint: Localization().getStringEx('widget.home.campus_guide_highlights.button.all.hint', 'Tap to view all highlights'),
            onTap: _onSeeAll,
          ));
      }
    }
    return contentList;
  }

  void _onSeeAll() {
    Analytics().logSelect(target: "HomeCampusHighlightsWidget View All");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(contentList: _promotedItems, contentTitle: Localization().getStringEx('panel.guide_list.label.highlights.section', 'Highlights'))));
  }
}