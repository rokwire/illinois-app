import 'dart:async';

import 'package:flutter/material.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/StudentGuide.dart';
import 'package:illinois/ui/guide/StudentGuideListPanel.dart';
import 'package:illinois/ui/widgets/SectionTitlePrimary.dart';
import 'package:illinois/utils/Utils.dart';

class HomeStudentGuidePromoWidget extends StatefulWidget {

  final StreamController<void> refreshController;

  HomeStudentGuidePromoWidget({this.refreshController});

  @override
  _HomeStudentGuidePromoWidgetState createState() => _HomeStudentGuidePromoWidgetState();
}

class _HomeStudentGuidePromoWidgetState extends State<HomeStudentGuidePromoWidget> implements NotificationsListener {

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
      for (dynamic promotedItem in _promotedItems) {
        if (contentList.isNotEmpty) {
          contentList.add(Container(height: 8,));
        }
        contentList.add(StudentGuideEntryCard(AppJson.mapValue(promotedItem)));
      }
    }
    return contentList;
  }
}