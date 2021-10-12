import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeGiesWidget extends StatefulWidget {

  final StreamController<void> refreshController;

  HomeGiesWidget({this.refreshController});

  @override
  _HomeGiesWidgetState createState() => _HomeGiesWidgetState();
}

class _HomeGiesWidgetState extends State<HomeGiesWidget>  {

  List<dynamic> _pages;
  Map<String, dynamic> _page;
  
  @override
  void initState() {
    super.initState();

    if (widget.refreshController != null) {
      widget.refreshController.stream.listen((_) {
        _page = ((_pages != null) && (0 < _pages.length)) ? AppJson.mapValue(_pages[0]) : null;
      });
    }

    rootBundle.loadString('assets/gies.wizard.json').then((String assetsContentString) {
      setState(() {
        _pages = AppJson.decodeList(assetsContentString);
        _page = ((_pages != null) && (0 < _pages.length)) ? AppJson.mapValue(_pages[0]) : null;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(visible: true, child:
      Semantics(container: true, child:
        Column(children: <Widget>[
          _buildHeader(),
          Stack(children:<Widget>[
            _buildSlant(),
            _buildContent(),
          ]),
        ]),
    ));
  }

  Widget _buildHeader() {
    return Container(color: Styles().colors.fillColorPrimary, child:
      Padding(padding: EdgeInsets.only(left: 20, top: 10, bottom: 10), child:
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Padding(padding: EdgeInsets.only(right: 16), child: Image.asset('images/campus-tools.png')),
          Expanded(child: 
            Text("New Degree Student Checklist", style:
              TextStyle(color: Styles().colors.white, fontFamily: Styles().fontFamilies.extraBold, fontSize: 20,),),),
      ],),),);
  }

  Widget _buildSlant() {
    return Column(children: <Widget>[
      Container(color:  Styles().colors.fillColorPrimary, height: 45,),
      Container(color: Styles().colors.fillColorPrimary, child:
        CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.background, left : true), child:
          Container(height: 65,),
        )),
    ],);
  }

  Widget _buildContent() {
    return Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 30), child:
      _GiesPageWidget(page: _page, onTapLink: _onTapLink, onTapPage: _onTapPage),
    );
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

  void _onTapPage(String pageId) {
    Map<String, dynamic> page = _getPage(pageId);
    if (page != null) {
      setState(() {
        _page = page;
      });
    }
  }

  Map<String, dynamic> _getPage(String id) {
    if (_pages != null) {
      for (dynamic page in _pages) {
        if (page is Map) {
          String pageId = page['id'];
          if (pageId == id) {
            try { return page.cast<String, dynamic>(); }
            catch(e) { print(e?.toString()); }
          }
        }
      }
    }
    return null;
  }
}

class _GiesPageWidget extends StatelessWidget {
  final Map<String, dynamic> page;
  final void Function(String) onTapLink;
  final void Function(String) onTapPage;
  
  _GiesPageWidget({this.page, this.onTapLink, this.onTapPage});

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[];

    String titleHtml = (page != null) ? AppJson.stringValue(page['title']) : null;
    if (AppString.isStringNotEmpty(titleHtml)) {
      contentList.add(
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
          Html(data: titleHtml,
            onLinkTap: (url, context, attributes, element) => onTapLink(url),
            style: { "body": Style(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold, fontSize: FontSize(24), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },),
      ),);
    }

    String textHtml = (page != null) ? AppJson.stringValue(page['text']) : null;
    if (AppString.isStringNotEmpty(textHtml)) {
      contentList.add(
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
          Html(data: textHtml,
            onLinkTap: (url, context, attributes, element) => onTapLink(url),
            style: { "body": Style(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },),
      ),);
    }

    List<dynamic> steps = (page != null) ? AppJson.listValue(page['steps']) : null;
    if (steps != null) {
      List<Widget> stepWidgets = <Widget>[];
      double stepTopPadding = 4, stepBottomPadding = 2;
      for (dynamic step in steps) {
        if (step is String) {
          stepWidgets.add(
            Padding(padding: EdgeInsets.only(top: stepTopPadding, bottom: stepBottomPadding), child:
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child:
                  Html(data: step,
                  onLinkTap: (url, context, attributes, element) => onTapLink(url),
                    style: { "body": Style(color: Styles().colors.fillColorSecondaryVariant, fontFamily: Styles().fontFamilies.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
                ),),
              ],)
            ),
          );
        }
      }
      if (0 < stepWidgets.length) {
        contentList.add(
          Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
            Column(children: stepWidgets,)
        ),);
      }
    }

    List<dynamic> buttons = (page != null) ? AppJson.listValue(page['buttons']) : null;
    if (buttons != null) {
      List<Widget> buttonWidgets = <Widget>[];
      for (dynamic button in buttons) {
        if (button is Map) {
          
        }
      }
    }


    return Padding(padding: EdgeInsets.only(), child:
      Container(
        decoration: BoxDecoration(
            color: Styles().colors.white,
            boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)) // BorderRadius.all(Radius.circular(4))
        ),
        clipBehavior: Clip.none,
        child: Padding(padding: EdgeInsets.all(16), child:
          Row(children: [ Expanded(child: Column(children: contentList))],)
        ),
    ),);
  }
}