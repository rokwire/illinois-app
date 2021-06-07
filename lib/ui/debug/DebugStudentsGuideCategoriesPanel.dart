
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/debug/DebugStudentsGuideSubCategoriesPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/Utils.dart';

class DebugStudentsGuideCategoriesPanel extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  DebugStudentsGuideCategoriesPanel({ this.entries });

  _DebugStudentsGuideCategoriesPanelState createState() => _DebugStudentsGuideCategoriesPanelState();
}

class _DebugStudentsGuideCategoriesPanelState extends State<DebugStudentsGuideCategoriesPanel> {

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
        titleWidget: Text('Info Content', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold),),
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
      
      // construct sections & involvements
      LinkedHashMap<String, LinkedHashSet<String>> audienceMap = LinkedHashMap<String, LinkedHashSet<String>>();
      
      for (Map<String, dynamic> entry in widget.entries) {
        List<dynamic> categories = AppJson.listValue(entry['categories']);
        if (categories != null) {
          for (dynamic categoryEntry in categories) {
            if (categoryEntry is Map) {
              String audience = AppJson.stringValue(categoryEntry['audience']);
              String category = AppJson.stringValue(categoryEntry['category']);
              if ((audience != null) && (category != null)) {
                LinkedHashSet<String> audienceEntries = audienceMap[audience];
                if (audienceEntries == null) {
                  audienceMap[audience] = audienceEntries = LinkedHashSet<String>();
                }
                if (!audienceEntries.contains(category)) {
                  audienceEntries.add(category);
                }
              }
            }
          }
        }
      }

      audienceMap.forEach((String audience, LinkedHashSet<String> categories) {
        contentList.add(_buildHeading(audience));
        for (String category in categories) {
          contentList.add(_buildEntry(category, audience: audience));
        }
      });
        
    }
    return contentList;
  }

  Widget _buildHeading(String audience) {
    return Padding(padding: EdgeInsets.only(top: 16), child:
      Container(color: Styles().colors.fillColorPrimary, child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
          Row(children: [
            Expanded(child:
              Text(audience, style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.bold),)
            ),
          ],),
        ),
      )
    );
  }

  Widget _buildEntry(String category, {String audience}) {
    return Padding(padding: EdgeInsets.only(left:16, right: 16, top: 4), child:
      GestureDetector(onTap: () => _onTapCategory(category, audience: audience), child:
        Container(color: Styles().colors.fillColorPrimary, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
            Row(children: [
              Expanded(child:
                Text(category, style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.bold),)
              ),
              Image.asset("images/chevron-right-white.png")
            ],),
          ),
        ),
      ),
    );
  }

  void _onTapCategory(String category, {String audience}) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugStudentsGuideSubCategoriesPanel(entries: widget.entries, audience: audience, category: category,)));
  }
}


