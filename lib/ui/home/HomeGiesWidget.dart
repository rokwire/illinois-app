import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
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

  static const String GIES_URI = 'edu.illinois.rokwire://rokwire.illinois.edu/gies';

  List<dynamic> _pages;
  List<String> _passed;
  List<int> _progressSteps;
  
  @override
  void initState() {
    super.initState();

    _passed = Storage().giesPages ?? [];

    if (widget.refreshController != null) {
      widget.refreshController.stream.listen((_) {
        _resetPassed();
      });
    }

    rootBundle.loadString('assets/gies.wizard.json').then((String assetsContentString) {
      setState(() {
        _pages = AppJson.decodeList(assetsContentString);
        _buildProgressSteps();
        _ensurePassed();
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

    List<Widget> progressWidgets = <Widget>[];
    if (_progressSteps != null) {
      Map<String, dynamic> curentPage = _currentPage;
      int currentProgress = (curentPage != null) ? (AppJson.intValue(curentPage['progress']) ?? AppJson.intValue(curentPage['progress-possition'])) : null;

      for (int progressStep in _progressSteps) {
        if (progressWidgets.isNotEmpty) {
          progressWidgets.add(Container(width: 6));
        }
        
        double borderWidth;
        Color borderColor, textColor;
        String textFamily;
        
        if ((currentProgress != null) && (progressStep < currentProgress)) {
          borderWidth = 2;
          borderColor = textColor = Colors.greenAccent;
          textFamily = Styles().fontFamilies.medium;
        }
        else if ((currentProgress != null) && (progressStep == currentProgress)) {
          borderWidth = 3;
          borderColor = textColor = Colors.white;
          textFamily = Styles().fontFamilies.extraBold;
        }
        else {
          borderWidth = 1;
          borderColor = textColor = Colors.white;
          textFamily = Styles().fontFamilies.regular;
        }

        progressWidgets.add(Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: borderColor, width: borderWidth),), child:
          Align(alignment: Alignment.center, child:
            Text(progressStep.toString(), style: TextStyle(color: textColor, fontFamily: textFamily, fontSize: 16,)),),),);
      }
    }
    if (progressWidgets.isNotEmpty) {
      progressWidgets.insert(0, Expanded(child: Container()));
      progressWidgets.insert(progressWidgets.length, Expanded(child: Container()));
    }

    return Container(color: Styles().colors.fillColorPrimary, child:
      Padding(padding: EdgeInsets.only(left: 20, top: 10, bottom: 7), child:
        Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child: 
              Text("iMBA New student checklist", textAlign: TextAlign.center, style: TextStyle(color: Styles().colors.white, fontFamily: Styles().fontFamilies.extraBold, fontSize: 20,),),),
          ],),
          Padding(padding: EdgeInsets.only(top: 7), child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: progressWidgets,)),
        ],),
      ),);
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
      _GiesPageWidget(page: _currentPage, onTapLink: _onTapLink, onTapPage: _onTapPage, onTapBack: (1 < _passed.length) ? _onTapBack : null,),
    );
  }

  void _onTapLink(String url) {
    if (AppString.isStringNotEmpty(url)) {

      Uri uri = Uri.tryParse(url);
      Uri giesUri = Uri.tryParse(GIES_URI);
      if ((giesUri != null) &&
          (giesUri.scheme == uri.scheme) &&
          (giesUri.authority == uri.authority) &&
          (giesUri.path == uri.path))
      {
        String pageId = (uri.queryParameters != null) ? AppJson.stringValue(uri.queryParameters['page_id']) : null;
        if ((pageId != null) && pageId.isNotEmpty) {
          _onTapPage(pageId);
        }
      }
      else if (AppUrl.launchInternal(url)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        launch(url);
      }
    }
  }

  void _onTapPage(String pageId) {
    Map<String, dynamic> page = _getPage(pageId);
    if (page != null) {

      _passed.add(pageId);
      Storage().giesPages = _passed;

      setState(() {});
    }
  }

  void _onTapBack() {
    if (1 < _passed.length) {
      _passed.removeLast();
      Storage().giesPages = _passed;

      setState(() {});
    }
  }

  Map<String, dynamic> get _currentPage {
    return _passed.isNotEmpty ? _getPage(_passed.last) : null;
  }

  Map<String, dynamic> _getPage(String id) {
    if (_pages != null) {
      for (dynamic page in _pages) {
        if (page is Map) {
          String pageId = AppJson.stringValue(page['id']);
          if (pageId == id) {
            try { return page.cast<String, dynamic>(); }
            catch(e) { print(e?.toString()); }
          }
        }
      }
    }
    return null;
  }

  void _resetPassed() {
    if ((_pages != null) && _pages.isNotEmpty) {
      Map<String, dynamic> firstPage = AppJson.mapValue(_pages.first);
      String pageId = (firstPage != null) ? AppJson.stringValue(firstPage['id']) : null;
      if (pageId != null) {
        setState(() {
          Storage().giesPages = _passed = [pageId];
        });
      }
    }
  }

  void _ensurePassed() {
    if ((_pages != null) && _pages.isNotEmpty && _passed.isEmpty) {
      Map<String, dynamic> firstPage = AppJson.mapValue(_pages.first);
      String pageId = (firstPage != null) ? AppJson.stringValue(firstPage['id']) : null;
      if (pageId != null) {
        _passed.add(pageId);
        Storage().giesPages = _passed;
      }
    }
  }

  void _buildProgressSteps() {
    if ((_pages != null) && _pages.isNotEmpty) {
      Set<int> progressSteps = Set<int>();
      for (dynamic page in _pages) {
        if (page is Map) {
          int pageProgress = AppJson.intValue(page['progress']) ?? AppJson.intValue(page['progress-entry']);
          if ((pageProgress != null) && !progressSteps.contains(pageProgress))  {
            progressSteps.add(pageProgress);
          }
        }
      }
      _progressSteps = List.from(progressSteps);
      _progressSteps.sort();
    }
  }
}

class _GiesPageWidget extends StatelessWidget {
  final Map<String, dynamic> page;
  
  final void Function(String) onTapLink;
  final void Function(String) onTapPage;
  final void Function() onTapBack;
  
  _GiesPageWidget({this.page, this.onTapLink, this.onTapPage, this.onTapBack});

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[];

    String titleHtml = (page != null) ? AppJson.stringValue(page['title']) : null;
    if (AppString.isStringNotEmpty(titleHtml)) {
      contentList.add(
        
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          (onTapBack != null) ?
            Semantics(
              label: Localization().getStringEx('headerbar.back.title', 'Back'),
              hint: Localization().getStringEx('headerbar.back.hint', ''),
              button: true,
              child: InkWell(
                onTap: onTapBack,
                child: Container(height: 36, width: 36, child:
                  Image.asset('images/chevron-left-gray.png')
                ),
                ),
            ) :
            Padding(padding: EdgeInsets.only(left: 16), child: Container()),

          Expanded(child:
            Padding(padding: EdgeInsets.only(top: 4, bottom: 4, right: 16), child:
              Html(data: titleHtml,
                onLinkTap: (url, context, attributes, element) => onTapLink(url),
                style: {
                  "body": Style(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold, fontSize: FontSize(24), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
                  "a": Style(color: Styles().colors.fillColorSecondaryVariant),
                },),
            ),
          ),

        ],));
    }

    String textHtml = (page != null) ? AppJson.stringValue(page['text']) : null;
    if (AppString.isStringNotEmpty(textHtml)) {
      contentList.add(
        Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
          Html(data: textHtml,
            onLinkTap: (url, context, attributes, element) => onTapLink(url),
            style: {
              "body": Style(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
              "a": Style(color: Styles().colors.fillColorSecondaryVariant),
            },),
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
                    style: {
                      "body": Style(color: Styles().colors.fillColorSecondaryVariant, fontFamily: Styles().fontFamilies.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
                      "a": Style(color: Styles().colors.fillColorSecondaryVariant),
                    },
                ),),
              ],)
            ),
          );
        }
      }
      if (0 < stepWidgets.length) {
        contentList.add(
          Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
            Column(children: stepWidgets,)
        ),);
      }
    }

    List<dynamic> content = (page != null) ? AppJson.listValue(page['content']) : null;
    if (content != null) {
      for (dynamic contentEntry in content) {
        if (contentEntry is Map) {
          List<Widget> contentEntryWidgets = <Widget>[];
          
          String headingHtml = AppJson.stringValue(contentEntry['heading']);
          if (AppString.isStringNotEmpty(headingHtml)) {
            contentEntryWidgets.add(
              Padding(padding: EdgeInsets.only(top: 4, bottom: 4), child:
                Html(data: headingHtml,
                  onLinkTap: (url, context, attributes, element) => onTapLink(url),
                  style: {
                    "body": Style(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
                    "a": Style(color: Styles().colors.fillColorSecondaryVariant),
                  },
              ),),
            );
          }

          List<dynamic> bullets = AppJson.listValue(contentEntry['bullets']);
          if (bullets != null) {
            String bulletText = '\u2022';
            Color bulletColor = Styles().colors.textBackground;
            List<Widget> bulletWidgets = <Widget>[];
            for (dynamic bulletEntry in bullets) {
              if ((bulletEntry is String) && bulletEntry.isNotEmpty) {
                bulletWidgets.add(
                  Padding(padding: EdgeInsets.only(top: 4, bottom: 2), child:
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(padding: EdgeInsets.only(left: 16, right: 8), child:
                        Text(bulletText, style: TextStyle(color: bulletColor, fontSize: 20),),),
                      Expanded(child:
                        Html(data: bulletEntry,
                        onLinkTap: (url, context, attributes, element) => onTapLink(url),
                          style: {
                            "body": Style(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
                            "a": Style(color: Styles().colors.fillColorSecondaryVariant),
                          },
                      ),),
                    ],)
                  ),
                );
              }
            }
            if (0 < bulletWidgets.length) {
              contentEntryWidgets.add(Column(children: bulletWidgets,));
            }
          }
          
          List<dynamic> numbers = AppJson.listValue(contentEntry['numbers']);
          if (numbers != null) {
            Color numberColor = Styles().colors.textBackground;
            List<Widget> numberWidgets = <Widget>[];
            for (int numberIndex = 0; numberIndex < numbers.length; numberIndex++) {
              dynamic numberEntry = numbers[numberIndex];
              if ((numberEntry is String) && numberEntry.isNotEmpty) {
                numberWidgets.add(
                  Padding(padding: EdgeInsets.only(top: 4, bottom: 2), child:
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(padding: EdgeInsets.only(left: 16, right: 8), child:
                        Text('${numberIndex + 1}.', style: TextStyle(color: numberColor, fontSize: 20),),),
                      Expanded(child:
                        Html(data: numberEntry,
                        onLinkTap: (url, context, attributes, element) => onTapLink(url),
                          style: {
                            "body": Style(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
                            "a": Style(color: Styles().colors.fillColorSecondaryVariant),
                          },
                      ),),
                    ],)
                  ),
                );
              }
            }
            if (0 < numberWidgets.length) {
              contentEntryWidgets.add(Column(children: numberWidgets,));
            }
          }

          if (0 < contentEntryWidgets.length) {
            contentList.add(
              Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                Column(children: contentEntryWidgets)
            ),);
          }
        }
      }
    }

    List<dynamic> buttons = (page != null) ? AppJson.listValue(page['buttons']) : null;
    if (buttons != null) {
      List<Widget> buttonWidgets = <Widget>[];
      for (dynamic button in buttons) {
        if (button is Map) {
          String title = AppJson.stringValue(button['title']);
          String page = AppJson.stringValue(button['page']);
          buttonWidgets.add(
            Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              RoundedButton(label: title,
                backgroundColor: Styles().colors.white,
                textColor: Styles().colors.fillColorPrimary,
                fontFamily: Styles().fontFamilies.bold,
                fontSize: 16,
                padding: EdgeInsets.symmetric(horizontal: 16, ),
                borderColor: Styles().colors.fillColorSecondary,
                borderWidth: 2,
                height: 42,
                onTap:() { onTapPage(page);  }
              )
            ]),
          );
        }
      }
      if (0 < buttonWidgets.length) {
        contentList.add(
          Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
            Wrap(runSpacing: 8, spacing: 16, children: buttonWidgets,)
        ),);
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
        child: Padding(padding: EdgeInsets.only(top: 16, bottom: 16), child:
          Row(children: [ Expanded(child: Column(children: contentList))],)
        ),
    ),);
  }
}