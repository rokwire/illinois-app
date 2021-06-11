import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/StudentGuide.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/guide/StudentGuideListPanel.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/SectionTitlePrimary.dart';
import 'package:illinois/utils/Utils.dart';

class HomeStudentGuidePromoWidget extends StatefulWidget {

  final StreamController<void> refreshController;

  HomeStudentGuidePromoWidget({this.refreshController});

  @override
  _HomeStudentGuidePromoWidgetState createState() => _HomeStudentGuidePromoWidgetState();
}

class _HomeStudentGuidePromoWidgetState extends State<HomeStudentGuidePromoWidget> implements NotificationsListener {

  static const int _maxItems = 5;

  List<dynamic> _promotedItems;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      StudentGuide.notifyChanged
    ]);

    if (widget.refreshController != null) {
      widget.refreshController.stream.listen((_) {
        _loadPromotedItems();
      });
    }

    _loadPromotedItems();
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
      _loadPromotedItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(visible: AppCollection.isCollectionNotEmpty(_promotedItems), child:
      Column(children: [
          SectionTitlePrimary(
            title: "Promoted",
            iconPath: 'images/campus-tools.png',
            children: _buildPromotedList()
          ),
        ]),
    );
  }

  void _loadPromotedItems() {
    setState(() {
      _promotedItems = StudentGuide().promotedList;
    });
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
        label: 'View All',
        hint: '',
        borderColor: Styles().colors.fillColorSecondary,
        textColor: Styles().colors.fillColorPrimary,
        backgroundColor: Styles().colors.white,
        onTap: () => _showAll(),
      ));
    }
    return contentList;
  }

  void _showAll() {
    Analytics.instance.logSelect(target: "HomeStudentGuidePromoWidget View All");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentGuideListPanel(promotedList: _promotedItems,)));
  }
}