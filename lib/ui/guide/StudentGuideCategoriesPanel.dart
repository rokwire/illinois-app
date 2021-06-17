
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/StudentGuide.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/guide/StudentGuideListPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/Utils.dart';

class StudentGuideCategoriesPanel extends StatefulWidget {
  StudentGuideCategoriesPanel();

  _StudentGuideCategoriesPanelState createState() => _StudentGuideCategoriesPanelState();
}

class _StudentGuideCategoriesPanelState extends State<StudentGuideCategoriesPanel> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text('Student Guide', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold),),
      ),
      body: Column(children: <Widget>[
          Expanded(child:
            SingleChildScrollView(child:
              SafeArea(child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children:
                  _buildContent()
                ),
              ),
            ),
          ),
        ],),
      backgroundColor: Styles().colors.background,
    );
  }

  List<Widget> _buildContent() {
    List<Widget> contentList = <Widget>[];
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

      categoriesMap.forEach((String category, LinkedHashSet<String> sections) {
        contentList.add(_buildHeading(category));
        for (String section in sections) {
          contentList.add(_buildEntry(section, category: category));
        }
      });
        
    }
    return contentList;
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
    //Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentGuideListPanel(category: category,)));
  }

  void _onTapSection(String section, {String category}) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentGuideListPanel(category: category, section: section,)));
  }
}


