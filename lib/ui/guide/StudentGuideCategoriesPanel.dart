
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
        titleWidget: Text('New Student Guide', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold),),
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
      
      for (dynamic guideEntry in StudentGuide().contentList) {
        if (guideEntry is Map) {
          List<dynamic> categories = AppJson.listValue(guideEntry['categories']);
          if (categories != null) {
            for (dynamic categoryEntry in categories) {
              if (categoryEntry is Map) {
                String category = AppJson.stringValue(categoryEntry['category']);
                String subCategory = AppJson.stringValue(categoryEntry['sub_category']);
                if ((category != null) && (subCategory != null)) {
                  LinkedHashSet<String> categoryEntries = categoriesMap[category];
                  if (categoryEntries == null) {
                    categoriesMap[category] = categoryEntries = LinkedHashSet<String>();
                  }
                  if (!categoryEntries.contains(subCategory)) {
                    categoryEntries.add(subCategory);
                  }
                }
              }
            }
          }
        }
      }

      categoriesMap.forEach((String category, LinkedHashSet<String> subCategories) {
        contentList.add(_buildHeading(category));
        for (String subCategory in subCategories) {
          contentList.add(_buildEntry(subCategory, category: category));
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

  Widget _buildEntry(String subCategory, { String category }) {
    return GestureDetector(onTap: () => _onTapSubCategory(subCategory, category: category), child:
      Padding(padding: EdgeInsets.only(left:16, right: 16, top: 4), child:
        Container(color: Styles().colors.fillColorPrimary, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
            Row(children: [
              Expanded(child:
                Text(subCategory, style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.bold),)
              ),
              Image.asset("images/chevron-right-white.png")
            ],),
          ),
        ),
      ),
    );
  }

  void _onTapCategory(String category) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentGuideListPanel(category: category,)));
  }

  void _onTapSubCategory(String subCategory, {String category}) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => StudentGuideListPanel(category: category, subCategory: subCategory,)));
  }
}


