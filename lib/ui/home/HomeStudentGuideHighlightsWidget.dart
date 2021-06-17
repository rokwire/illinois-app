import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Auth.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/StudentGuide.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/ui/guide/StudentGuideListPanel.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/SectionTitlePrimary.dart';
import 'package:illinois/utils/Utils.dart';

class HomeStudentGuideHighlightsWidget extends StatefulWidget {

  final StreamController<void> refreshController;

  HomeStudentGuideHighlightsWidget({this.refreshController});

  @override
  _HomeStudentGuideHighlightsWidgetState createState() => _HomeStudentGuideHighlightsWidgetState();
}

class _HomeStudentGuideHighlightsWidgetState extends State<HomeStudentGuideHighlightsWidget> implements NotificationsListener {

  static const int _maxItems = 3;

  List<dynamic> _promotedItems;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      StudentGuide.notifyChanged,
      User.notifyRolesUpdated,
      AppLivecycle.notifyStateChanged,
      Auth.notifyCardChanged,
    ]);

    if (widget.refreshController != null) {
      widget.refreshController.stream.listen((_) {
        _updatePromotedItems();
      });
    }

    _promotedItems = StudentGuide().promotedList;
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == StudentGuide.notifyChanged) {
      _updatePromotedItems();
    }
    else if (name == User.notifyRolesUpdated) {
      _updatePromotedItems();
    }
    else if (name == Auth.notifyCardChanged) {
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
    return Visibility(visible: AppCollection.isCollectionNotEmpty(_promotedItems), child:
      Column(children: [
          SectionTitlePrimary(
            title: Localization().getStringEx('widget.home_student_guide_highlights.label.heading', 'Student Guide Highlights'),
            iconPath: 'images/campus-tools.png',
            children: _buildPromotedList()
          ),
        ]),
    );
  }

  void _updatePromotedItems() {
    List<dynamic> promotedItems = StudentGuide().promotedList;
    if (!DeepCollectionEquality().equals(_promotedItems, promotedItems)) {
      setState(() {
        _promotedItems = promotedItems;
      });
    }
  }

  List<Widget> _buildPromotedList() {
    List<Widget> contentList = <Widget>[];
    if (_promotedItems != null) {
      int promotedCount = min(_promotedItems.length, _maxItems);
      for (int index = 0; index < promotedCount; index++) {
        dynamic promotedItem = _promotedItems[index];
        if (contentList.isNotEmpty) {
          contentList.add(Container(height: 8,));
        }
        contentList.add(StudentGuideEntryCard(AppJson.mapValue(promotedItem)));
      }
    }
    if (_maxItems < _promotedItems.length) {
      contentList.add(Container(height: 16,));
      contentList.add(ScalableRoundedButton(
        label: Localization().getStringEx('widget.home_student_guide_highlights.button.more.title', 'View All'),
        hint: Localization().getStringEx('widget.home_student_guide_highlights.button.more.hint', 'Tap to view all highlights'),
        borderColor: Styles().colors.fillColorSecondary,
        textColor: Styles().colors.fillColorPrimary,
        backgroundColor: Styles().colors.white,
        onTap: () => _showAll(),
      ));
    }
    return contentList;
  }

  void _showAll() {
    Analytics.instance.logSelect(target: "HomeStudentGuideHighlightsWidget View All");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentGuideListPanel(promotedList: _promotedItems,)));
  }
}