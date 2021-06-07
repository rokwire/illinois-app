
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/debug/DebugStudentsGuideSectionsPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/Utils.dart';

class DebugStudentsGuideSubCategoriesPanel extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  final String audience;
  final String category;
  DebugStudentsGuideSubCategoriesPanel({ this.entries,  this.audience, this.category});

  _DebugStudentsGuideSubCategoriesPanelState createState() => _DebugStudentsGuideSubCategoriesPanelState();
}

class _DebugStudentsGuideSubCategoriesPanelState extends State<DebugStudentsGuideSubCategoriesPanel> {

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
        titleWidget: Text(widget.audience ?? '', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold),),
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
    if (widget.entries != null) {

      LinkedHashSet<String> subCategories = LinkedHashSet<String>();
      
      for (Map<String, dynamic> entry in widget.entries) {
        List<dynamic> categories = AppJson.listValue(entry['categories']);
        if (categories != null) {
          for (dynamic categoryEntry in categories) {
            if (categoryEntry is Map) {
              String audience = AppJson.stringValue(categoryEntry['audience']);
              String category = AppJson.stringValue(categoryEntry['category']);
              String subCategory = AppJson.stringValue(categoryEntry['sub_category']);
              if ((widget.audience == audience) && (widget.category == category) && (subCategory != null) && !subCategories.contains(subCategory)) {
                subCategories.add(subCategory);
              }
            }
          }
        }
      }

      contentList.add(_buildHeading(widget.category));

      for (String subCategory in subCategories) {
        contentList.add(_buildEntry(subCategory));
      }
      
    }
    return contentList;
  }

  Widget _buildHeading(String category) {
    return Padding(padding: EdgeInsets.only(top: 16), child:
      Container(color: Styles().colors.fillColorPrimary, child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
          Row(children: [
            Expanded(child:
              Text(category, style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.bold),)
            ),
          ],),
        ),
      )
    );
  }

  Widget _buildEntry(String subCategory) {
    return Padding(padding: EdgeInsets.only(left:16, right: 16, top: 4), child:
      GestureDetector(onTap: () => _onTapSubCategory(subCategory), child:
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

  void _onTapSubCategory(String subCategory) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugStudentsGuideSectionsPanel(entries: widget.entries, audience: widget.audience, category: widget.category, subCategory: subCategory,)));
  }
}


