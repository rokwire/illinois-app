
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/debug/DebugStudentsGuideDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:url_launcher/url_launcher.dart';

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
  
  void _onTapLink(String url) {
    if (AppString.isStringNotEmpty(url)) {
      if (AppUrl.launchInternal(url)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        launch(url);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String titleHtml = AppJson.stringValue(widget.entry['list_title']) ?? AppJson.stringValue(widget.entry['title']) ?? '';
    String descriptionHtml = AppJson.stringValue(widget.entry['list_description']) ?? AppJson.stringValue(widget.entry['description']) ?? '';
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
              Html(data: titleHtml,
                onLinkTap: (url, context, attributes, element) => _onTapLink(url),
                style: { "body": Style(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },),
              Container(height: 8,),
              Html(data: descriptionHtml,
                onLinkTap: (url, context, attributes, element) => _onTapLink(url),
                style: { "body": Style(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: FontSize(16), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },),
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