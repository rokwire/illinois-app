import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:url_launcher/url_launcher.dart';

class DebugStudentsGuideDetailPanel extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  final Map<String, dynamic> entry;
  DebugStudentsGuideDetailPanel({ this.entries, this.entry });

  _DebugStudentsGuideDetailPanelState createState() => _DebugStudentsGuideDetailPanelState();
}

class _DebugStudentsGuideDetailPanelState extends State<DebugStudentsGuideDetailPanel> {

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
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text('', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold),),
      ),
      body: Column(children: <Widget>[
          Expanded(child:
            SingleChildScrollView(child:
              SafeArea(child:
                Stack(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children:
                    _buildContent()
                  ),
                  Align(alignment: Alignment.topRight, child:
                    GestureDetector(onTap: _onTapFavorite, child:
                      Container(padding: EdgeInsets.all(16), child: 
                        Image.asset(_isFavorite ? 'images/icon-star-selected.png' : 'images/icon-star.png')
                  ),),),

                ],)
              ),
            ),
          ),
        ],),
      backgroundColor: Styles().colors.background,
    );
  }

  List<Widget> _buildContent() {
    List<Widget> contentList = <Widget>[
      _buildHeading(),
      _buildDetails()
    ];
    return contentList;
  }

  Widget _buildHeading() {
    List<Widget> contentList = <Widget>[];

    String category = AppJson.stringValue(widget.entry['category']);
    contentList.add(
      Padding(padding: EdgeInsets.only(bottom: 8), child:
        Text(category?.toUpperCase() ?? '', style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.semiBold),),
    ),);

    String title = AppJson.stringValue(widget.entry['detail_title']);
    if (AppString.isStringNotEmpty(title)) {
      contentList.add(
        Padding(padding: EdgeInsets.all(8), child:
          Text(title ?? '', style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 36, fontFamily: Styles().fontFamilies.bold),),
      ),);
    }
    
    String descriptionHtml = AppJson.stringValue(widget.entry['detail_description']);
    if (AppString.isStringNotEmpty(descriptionHtml)) {
      contentList.add(
        Padding(padding: EdgeInsets.all(8), child:
          Html(data: descriptionHtml,
            onLinkTap: (url, context, attributes, element) => _onTapLink(url),
            style: { "body": Style(fontFamily: Styles().fontFamilies.regular, color: Styles().colors.textBackground, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
      ),),);
    }


    List<dynamic> links = AppJson.listValue(widget.entry['links']);
    if (links != null) {
      for (dynamic link in links) {
        if (link is Map) {
          String url = AppJson.stringValue(link['url']);
          String text = AppJson.stringValue(link['text']);
          String icon = AppJson.stringValue(link['icon']);
          contentList.add(GestureDetector(onTap: () => _onTapLink(url), child:
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
              Row(children: [
                Image.network(icon, width: 24, height: 24),
                Padding(padding: EdgeInsets.only(left: 4), child:
                  Text(text, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 18, fontFamily: Styles().fontFamilies.regular, decoration: TextDecoration.underline))
                ),
              ],)
          ),));
        }
      }
    }

    return Container(color: Colors.white, padding: EdgeInsets.all(16), child:
      Row(children: [
        Expanded(child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList),
        ),
      ],)
    );
  }

  Widget _buildDetails() {
    List<Widget> contentList = <Widget>[];

    String title = AppJson.stringValue(widget.entry['sub_details_title']);
    if (AppString.isStringNotEmpty(title)) {
      contentList.add(
        Padding(padding: EdgeInsets.all(8), child:
          Text(title ?? '', style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 36, fontFamily: Styles().fontFamilies.bold),),
      ),);
    }

    String descriptionHtml = AppJson.stringValue(widget.entry['sub_details_description']);
    if (AppString.isStringNotEmpty(descriptionHtml)) {
      contentList.add(
        Padding(padding: EdgeInsets.all(8), child:
          Html(data: descriptionHtml,
            onLinkTap: (url, context, attributes, element) => _onTapLink(url),
            style: { "body": Style(fontFamily: Styles().fontFamilies.regular, color: Styles().colors.textBackground, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
      ),),);
    }

    return Container(padding: EdgeInsets.all(16), child:
      Row(children: [
        Expanded(child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList),
        ),
      ],)
    );
  }

  void _onTapFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
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
}
