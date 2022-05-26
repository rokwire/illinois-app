import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeSlantHeader.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Guide.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/guide/GuideEntryCard.dart';
import 'package:illinois/ui/guide/GuideListPanel.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeCampusHighlightsWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<void>? refreshController;
  final HomeScrollableDragging? scrollableDragging;

  HomeCampusHighlightsWidget({Key? key, this.favoriteId, this.refreshController, this.scrollableDragging}) : super(key: key);

  @override
  _HomeCampusHighlightsWidgetState createState() => _HomeCampusHighlightsWidgetState();
}

class _HomeCampusHighlightsWidgetState extends State<HomeCampusHighlightsWidget> implements NotificationsListener {

  static const int _maxItems = 3;

  List<Map<String, dynamic>>? _promotedItems;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      Guide.notifyChanged,
      Auth2UserPrefs.notifyRolesChanged,
      AppLivecycle.notifyStateChanged,
      Auth2.notifyCardChanged,
    ]);

    if (widget.refreshController != null) {
      widget.refreshController!.stream.listen((_) {
        _updatePromotedItems();
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
    if (name == Guide.notifyChanged) {
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
      Column(children: [
          HomeSlantHeader(favoriteId: widget.favoriteId, scrollableDragging: widget.scrollableDragging,
            title: Localization().getStringEx('widget.home_campus_guide_highlights.label.heading', 'Campus Guide Highlights'),
            children: _buildPromotedList()
          ),
        ]),
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
      int promotedCount = min(_promotedItems!.length, _maxItems);
      for (int index = 0; index < promotedCount; index++) {
        Map<String, dynamic>? promotedItem = _promotedItems![index];
        if (contentList.isNotEmpty) {
          contentList.add(Container(height: 8,));
        }
        contentList.add(GuideEntryCard(promotedItem));
      }
      if (_maxItems < _promotedItems!.length) {
        contentList.add(Container(height: 16,));
        contentList.add(RoundedButton(
          label: Localization().getStringEx('widget.home_campus_guide_highlights.button.more.title', 'View All'),
          hint: Localization().getStringEx('widget.home_campus_guide_highlights.button.more.hint', 'Tap to view all highlights'),
          borderColor: Styles().colors!.fillColorSecondary,
          textColor: Styles().colors!.fillColorPrimary,
          backgroundColor: Styles().colors!.white,
          onTap: () => _showAll(),
        ));
      }
    }
    return contentList;
  }

  void _showAll() {
    Analytics().logSelect(target: "HomeCampusHighlightsWidget View All");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(contentList: _promotedItems, contentTitle: Localization().getStringEx('panel.guide_list.label.highlights.section', 'Highlights'))));
  }
}