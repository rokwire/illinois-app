
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/StudentGuide.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/guide/StudentGuideListPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/Utils.dart';

class StudentGuideCategoriesPanel extends StatefulWidget {
  StudentGuideCategoriesPanel();

  _StudentGuideCategoriesPanelState createState() => _StudentGuideCategoriesPanelState();
}

class _StudentGuideCategoriesPanelState extends State<StudentGuideCategoriesPanel> implements NotificationsListener {

  List<String> _categories;
  Map<String, List<String>> _categorySections;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      StudentGuide.notifyChanged,
    ]);
    _buildCategories();
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
      setState(() {
        _buildCategories();
      });
    }
  }

  void _buildCategories() {
    
    if (StudentGuide().contentList != null) {
      
      LinkedHashMap<String, LinkedHashSet<String>> categoriesMap = LinkedHashMap<String, LinkedHashSet<String>>();
      
      for (dynamic contentEntry in StudentGuide().contentList) {
        Map<String, dynamic> guideEntry = AppJson.mapValue(contentEntry);
        if (guideEntry != null) {
          String category = AppJson.stringValue(StudentGuide().entryValue(guideEntry, 'category'));
          String section = AppJson.stringValue(StudentGuide().entryValue(guideEntry, 'section'));
          if ((category != null) && (section != null)) {
            LinkedHashSet<String> categorySections = categoriesMap[category];
            if (categorySections == null) {
              categoriesMap[category] = categorySections = LinkedHashSet<String>();
            }
            if (!categorySections.contains(section)) {
              categorySections.add(section);
            }
          }
        }
      }

      _categories = List.from(categoriesMap.keys) ;
      _categories.sort();

      _categorySections = Map<String, List<String>>();
      categoriesMap.forEach((String category, LinkedHashSet<String> sectionsSet) {
        List<String> sections = List.from(sectionsSet);
        sections.sort();
        _categorySections[category] = sections;
      });
        
    }
    else {
      _categories = null;
      _categorySections = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx('panel.student_guide_categories.label.heading', 'Student Guide'), style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold),),
      ),
      body: Column(children: <Widget>[
          Expanded(child:
            _buildContent(),
          ),
        ],),
      backgroundColor: Styles().colors.background,
    );
  }

  Widget _buildContent() {
    if ((_categories != null) && (0 < _categories.length)) {
      List<Widget> contentList = <Widget>[];
      for (String category in _categories) {
        contentList.add(_buildHeading(category));
        for (String section in _categorySections[category]) {
          contentList.add(_buildEntry(section, category: category));
        }
      }

      return SingleChildScrollView(child:
        SafeArea(child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children:
            contentList
          ),
        ),
      );
    }
    else {
      return Padding(padding: EdgeInsets.all(32), child:
        Center(child:
          Text(Localization().getStringEx('panel.student_guide_categories.label.content.empty', 'Empty guide content'), style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold),)
        ,)
      );
    }

  }

  Widget _buildHeading(String category) {
    
    return GestureDetector(onTap: () => _onTapCategory(category), child:
      Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 4), child:
        Row(children: [
          Expanded(child:
            Text(category, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold),)
          ),
        ],),
      ),
    );
  }

  Widget _buildEntry(String section, { String category }) {
    return GestureDetector(onTap: () => _onTapSection(section, category: category), child:
      Padding(padding: EdgeInsets.only(left:16, right: 16, top: 4), child:
        Container(color: Styles().colors.fillColorPrimary, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
            Row(children: [
              Expanded(child:
                Text(section, style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.bold),)
              ),
              Image.asset("images/chevron-right-white.png")
            ],),
          ),
        ),
      ),
    );
  }

  void _onTapCategory(String category) {
    Analytics.instance.logSelect(target: category);
    //Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentGuideListPanel(category: category,)));
  }

  void _onTapSection(String section, {String category}) {
    Analytics.instance.logSelect(target: "$section / $category");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentGuideListPanel(category: category, section: section,)));
  }
}


