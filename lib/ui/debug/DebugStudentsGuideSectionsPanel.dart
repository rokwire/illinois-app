
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/debug/DebugStudentsGuideDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/Utils.dart';

class DebugStudentsGuideSectionsPanel extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  final String category;
  DebugStudentsGuideSectionsPanel({ this.entries, this.category });

  _DebugStudentsGuideSectionsPanelState createState() => _DebugStudentsGuideSectionsPanelState();
}

class _DebugStudentsGuideSectionsPanelState extends State<DebugStudentsGuideSectionsPanel> {

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
        titleWidget: Text(widget.category ?? '', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold),),
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
      
      // build sections
      List<String> sectionsList = <String>[];
      Map<String, List<Map<String, dynamic>>> sectionsMap = Map<String, List<Map<String, dynamic>>>();
      for (Map<String, dynamic> entry in widget.entries) {
        if (entry['category'] == widget.category) {
          String entrySection = AppJson.stringValue(entry['section']) ?? '';
          List<Map<String, dynamic>> sectionEntries = sectionsMap[entrySection];
          if (sectionEntries == null) {
            sectionsMap[entrySection] = sectionEntries = <Map<String, dynamic>>[];
            sectionsList.add(entrySection);
          }
          sectionEntries.add(entry);
        }
      }
      
      // build widgets
      
      for (String section in sectionsList) {
        if (contentList.isNotEmpty) {
          contentList.add(Container(height: 16,));
        }
        contentList.add(_buildSectionHeading(section));
        List<Map<String, dynamic>> sectionEntries = sectionsMap[section];
        for (Map<String, dynamic> entry in sectionEntries) {
          contentList.add(
            Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8), child:
              StudentsGuideEntryCard(entry, entries: widget.entries,)
            )
          );
        }

      }
    }
    return contentList;
  }

  Widget _buildSectionHeading(String section) {
    return Container(color: Styles().colors.fillColorPrimary, child:
      Row(children: [
        Expanded(child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
            Text(section, style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.bold),)
          ),
        )
      ],),
    );
  }
}

class StudentsGuideEntryCard extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  final Map<String, dynamic> entry;
  StudentsGuideEntryCard(this.entry, {this.entries});

  _StudentsGuideEntryCardState createState() => _StudentsGuideEntryCardState();
}

class _StudentsGuideEntryCardState extends State<StudentsGuideEntryCard> {

  bool _isFavorite = false;

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
    return Container(
      decoration: BoxDecoration(
          color: Styles().colors.white,
          boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
          borderRadius: BorderRadius.all(Radius.circular(4))
      ),
      child: Stack(children: [
        GestureDetector(onTap: _onTapEntry, child:
          Padding(padding: EdgeInsets.all(16), child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppJson.stringValue(widget.entry['list_title']) ?? '', style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold),),
              Container(height: 8,),
              Text(AppJson.stringValue(widget.entry['list_description']) ?? '', style: TextStyle(color: Styles().colors.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies.regular),),
            ],),
        ),),
        Align(alignment: Alignment.topRight, child:
          GestureDetector(onTap: _onTapFavorite, child:
            Container(padding: EdgeInsets.all(9), child: 
              Image.asset(_isFavorite ? 'images/icon-star-selected.png' : 'images/icon-star.png')
        ),),),
      ],),
      
    );
  }

  void _onTapFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _onTapEntry() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugStudentsGuideDetailPanel(entries: widget.entries, entry: widget.entry,)));
  }
}