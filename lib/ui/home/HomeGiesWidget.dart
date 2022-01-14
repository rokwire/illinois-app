import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:illinois/service/Localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeGiesWidget extends StatefulWidget {

  static const String notifyPageChanged  = "edu.illinois.rokwire.gies.widget.page.changed";

  final StreamController<void>? refreshController;

  HomeGiesWidget({Key? key, this.refreshController}) : super(key: key);

  @override
  _HomeGiesWidgetState createState() => _HomeGiesWidgetState();
}

class _HomeGiesWidgetState extends State<HomeGiesWidget>  {

  List<dynamic>? _pages;
  List<String>?  _navigationPages;
   
  late Map<int, Set<String>> _progressPages;
  Set<String>? _completedPages;
  List<int>? _progressSteps;

  @override
  void initState() {
    super.initState();

    _navigationPages = Storage().giesNavPages ?? [];
    _completedPages = Storage().giesCompletedPages ?? Set<String>();

    if (widget.refreshController != null) {
      widget.refreshController!.stream.listen((_) {
        if (kDebugMode /*|| (Config().configEnvironment == ConfigEnvironment.dev)*/) {
          setState(() {
            _resetNavigationPages();
            _resetCompleted();
            _resetNotes();
          });
        }
      });
    }

    AppBundle.loadString('assets/gies.json').then((String? assetsContentString) {
      setState(() {
        _pages = AppJson.decodeList(assetsContentString);
        _buildProgressSteps();
        _ensureNavigationPages();
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
    return Container(color: Styles().colors!.fillColorPrimary, child:
      Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 10), child:
        Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child: 
              Text(Localization().getStringEx('widget.gies.title', 'iDegrees New Student Checklist')!, textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20,),),),
          ],),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
            Expanded(child: Container()),
            Padding(padding: EdgeInsets.only(top: 3), child:
              _buildProgress(),
            ),
            Expanded(child:
              Align(alignment: Alignment.centerRight, child:
                InkWell(onTap: () => _onTapNotes(), child:
                  Padding(padding: EdgeInsets.only(top: 14, bottom: 4), child:
                    Text(Localization().getStringEx('widget.gies.button.notes', 'Notes')!, style: TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.bold, fontSize: 16, decoration: TextDecoration.underline, ),), // Styles().colors.fillColorSecondary
                  ),
                ),
              ),
            ),
          ],),
        ],),
      ),);
  }

  Widget _buildProgress() {

    List<Widget> progressWidgets = <Widget>[];
    if (_progressSteps != null) {
      int? currentPageProgress = _currentPageProgress;

      for (int progressStep in _progressSteps!) {
        
        double borderWidth;
        Color borderColor, textColor;
        String? textFamily;
        bool progressStepCompleted = _progressStepCompleted(progressStep);

        if ((currentPageProgress != null) && (progressStep == currentPageProgress)) {
          borderWidth = 3;
          borderColor = textColor = progressStepCompleted ? Colors.greenAccent : Colors.white;
          textFamily = Styles().fontFamilies!.extraBold;
        }
        else if (progressStepCompleted) {
          borderWidth = 2;
          borderColor = textColor = Colors.greenAccent;
          textFamily = Styles().fontFamilies!.medium;
        }
        else {
          borderWidth = 1;
          borderColor = textColor = Colors.white;
          textFamily = Styles().fontFamilies!.regular;
        }
        
        progressWidgets.add(
          Semantics(label: "Page ${progressStep.toString()}", button: true, hint: progressStepCompleted? "Completed" :((progressStep == currentPageProgress)? "Current page":"Not Completed"), child:
            InkWell(onTap: () => _onTapProgress(progressStep), child:
              Padding(padding: EdgeInsets.symmetric(horizontal: 3, vertical: 3), child:
//              Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: borderColor, width: borderWidth),), child:
//              Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.rectangle, border: Border(bottom: BorderSide(color: borderColor, width: borderWidth)),), child:
                Container(width: 28, height: 28, padding: EdgeInsets.only(top: 8, left: 8), child:
//                Align(alignment: Alignment.center, child:
//                  Text(progressStep.toString(), style: TextStyle(color: textColor, fontFamily: textFamily, fontSize: 16,), semanticsLabel: "",),),),),),));
/*                  Column(mainAxisSize: MainAxisSize.min, children:<Widget>[
                      Text(progressStep.toString(), style: TextStyle(color: textColor, fontFamily: textFamily, fontSize: 16,), semanticsLabel: '',),
                      Padding(padding: EdgeInsets.only(bottom: 3 - borderWidth), child:
                        Container(width: 12, height: borderWidth, color: borderColor,)
                      ),
                    ]),*/
                    Stack(children:<Widget>[
                      Container(width: 12, child:
                        Align(alignment: Alignment.topCenter, child: 
                          Text(progressStep.toString(), style: TextStyle(color: textColor, fontFamily: textFamily, fontSize: 16,), semanticsLabel: '',),
                        )
                      ),
                      Padding(padding: EdgeInsets.only(top: 17, bottom: 3 - borderWidth), child:
                        Container(width: 12, height: borderWidth, color: borderColor,)
                      ),
                    ]),
//                ),
                ),
              ),
            ),
          )
        );
      }
    }

    return progressWidgets.isNotEmpty ? Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: progressWidgets) : Container();
  }

  Widget _buildSlant() {
    return Column(children: <Widget>[
      Container(color:  Styles().colors!.fillColorPrimary, height: 45,),
      Container(color: Styles().colors!.fillColorPrimary, child:
        CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.background, left : true), child:
          Container(height: 65,),
        )),
    ],);
  }

  Widget _buildContent() {
    return Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 30), child:
      _GiesPageWidget(page: _currentPage, onTapLink: _onTapLink, onTapButton: _onTapButton, onTapBack: (1 < _navigationPages!.length) ? _onTapBack : null,),
    );
  }

  String get giesUrl => '${DeepLink().nativeUrl}/gies';


  void _onTapLink(String? url) {
    if (AppString.isStringNotEmpty(url)) {

      Uri? uri = Uri.tryParse(url!);
      Uri? giesUri = Uri.tryParse(giesUrl);
      if ((giesUri != null) &&
          (giesUri.scheme == uri!.scheme) &&
          (giesUri.authority == uri.authority) &&
          (giesUri.path == uri.path))
      {
        String? pageId = AppJson.stringValue(uri.queryParameters['page_id']);
        _pushPage(_getPage(id: pageId));
      }
      else if (AppUrl.launchInternal(url)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        launch(url);
      }
    }
  }

  void _onTapButton(Map<String, dynamic> button) {
    _processButtonPopup(button).then((_) {
      _processButtonPage(button);
    });
  }

  Future<void> _processButtonPopup(Map<String, dynamic> button) async {
    String? popupId = AppJson.stringValue(button['popup']);
    if (popupId != null) {
      await _showPopup(popupId);
    }
  }

  void _processButtonPage(Map<String, dynamic> button) {
    String? currentPageId = _currentPageId;
    if (_pageButtonCompletes(button)) {
      if ((currentPageId != null) && currentPageId.isNotEmpty && !_completedPages!.contains(currentPageId)) {
        setState(() {
          _completedPages!.add(currentPageId);
        });
        Storage().giesCompletedPages = _completedPages;
      }
    }

    String? pushPageId = AppJson.stringValue(button['page']);
    if ((pushPageId != null) && pushPageId.isNotEmpty) {
      int? currentPageProgress = getPageProgress(_currentPage);
      
      Map<String, dynamic>? pushPage = _getPage(id: pushPageId);
      int? pushPageProgress = getPageProgress(pushPage);

      if ((currentPageProgress != null) && (pushPageProgress != null) && (currentPageProgress < pushPageProgress)) {
        while (_progressStepCompleted(pushPageProgress)) {
          int nextPushPageProgress = pushPageProgress! + 1;
          Map<String, dynamic>? nextPushPage = _getPage(progress: nextPushPageProgress);
          String? nextPushPageId = (nextPushPage != null) ? AppJson.stringValue(nextPushPage['id']) : null;
          if ((nextPushPageId != null) && nextPushPageId.isNotEmpty) {
            pushPage = nextPushPage;
            pushPageId = nextPushPageId;
            pushPageProgress = nextPushPageProgress;
          }
          else {
            break;
          }
        }
      }

      _pushPage(pushPage);
    }
  }

  void _onTapBack() {
    _popPage();
  }

  void _onTapNotes() {
    _showPopup(_pagePopup(_currentPage) ?? 'notes');
  }


  void _onTapProgress(int progress) {
    int? currentPageProgress = _currentPageProgress;
    if (currentPageProgress != progress) {
      _pushPage(_getPage(progress: progress));
    }
  }

  String? get _currentPageId {
    return _navigationPages!.isNotEmpty ? _navigationPages!.last : null;
  }

  Map<String, dynamic>? get _currentPage {
    return _getPage(id: _currentPageId);
  }

  int? get _currentPageProgress {
    return getPageProgress(_currentPage);
  }

  static int? getPageProgress(Map<String, dynamic>? page) {
    return (page != null) ? (AppJson.intValue(page['progress']) ?? AppJson.intValue(page['progress-possition'])) : null;
  }

  void _pushPage(Map<String, dynamic>? pushPage) {
    String? pushPageId = (pushPage != null) ? AppJson.stringValue(pushPage['id']) : null;
    if ((pushPageId != null) && pushPageId.isNotEmpty && _hasPage(id: pushPageId)) {
      int? currentPageProgress = getPageProgress(_currentPage);
      int? pushPageProgress = getPageProgress(pushPage);
      setState(() {
        if (currentPageProgress == pushPageProgress) {
          _navigationPages!.add(pushPageId);
        }
        else {
          _navigationPages = [pushPageId];
        }
      });
      Storage().giesNavPages = _navigationPages;
      NotificationService().notify(HomeGiesWidget.notifyPageChanged);
    }
  }

  void _popPage() {
    if (1 < _navigationPages!.length) {
      setState(() {
        _navigationPages!.removeLast();
      });
      Storage().giesNavPages = _navigationPages;
      NotificationService().notify(HomeGiesWidget.notifyPageChanged);
    }
  }

  bool _hasPage({String? id}) {
    return _getPage(id: id) != null;
  }

  Map<String, dynamic>? _getPage({String? id, int? progress}) {
    if (_pages != null) {
      for (dynamic page in _pages!) {
        if (page is Map) {
          if (((id == null) || (id == AppJson.stringValue(page['id']))) &&
              ((progress == null) || (progress == (AppJson.intValue(page['progress']) ?? AppJson.intValue(page['progress-possition'])))))
          {
            try { return page.cast<String, dynamic>(); }
            catch(e) { print(e.toString()); }
          }
        }
      }
    }
    return null;
  }

  String? get _navigationRootPageId {
    if ((_pages != null) && _pages!.isNotEmpty) {
      for (dynamic page in _pages!) {
        if (page is Map) {
          String? pageId = AppJson.stringValue(page['id']);
          if (pageId != null) {
            return pageId;
          }
        }
      }
    }
    return null;
  }

  void _resetNavigationPages() {
    String? rootPageId = _navigationRootPageId;
    if ((rootPageId != null) && rootPageId.isNotEmpty) {
      Storage().giesNavPages = _navigationPages = [rootPageId];
    }
  }

  void _ensureNavigationPages() {
    if (_navigationPages!.isEmpty) {
      String? rootPageId = _navigationRootPageId;
      if ((rootPageId != null) && rootPageId.isNotEmpty) {
        Storage().giesNavPages = _navigationPages = [rootPageId];
      }
    }
  }

  void _buildProgressSteps() {
    _progressPages = Map<int, Set<String>>();
    if ((_pages != null) && _pages!.isNotEmpty) {
      for (dynamic page in _pages!) {
        if (page is Map) {
          int? pageProgress = AppJson.intValue(page['progress']);
          if (pageProgress != null) {
            String? pageId = AppJson.stringValue(page['id']);
            if ((pageId != null) && pageId.isNotEmpty && _pageCanComplete(page)) {
              Set<String>? progressPages = _progressPages[pageProgress];
              if (progressPages == null) {
                _progressPages[pageProgress] = progressPages = Set<String>();
              }
              progressPages.add(pageId);
            }
          }
        }
      }
      _progressSteps = List.from(_progressPages.keys);
      _progressSteps!.sort();
    }
  }

  void _resetCompleted() {
    _completedPages!.clear();
    Storage().giesCompletedPages = null;
  }

  static bool _pageCanComplete(Map? page) {
    List<dynamic>? buttons = (page != null) ? AppJson.listValue(page['buttons']) : null;
    if (buttons != null) {
      for (dynamic button in buttons) {
        if ((button is Map) && _pageButtonCompletes(button)) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _pageButtonCompletes(Map button) {
    return AppJson.boolValue(button['completes']) == true;
  }

  static String? _pagePopup(Map? page) {
    List<dynamic>? buttons = (page != null) ? AppJson.listValue(page['buttons']) : null;
    if (buttons != null) {
      String? popup;
      for (dynamic button in buttons) {
        if ((button is Map) && ((popup = _pageButtonPopup(button)) != null)) {
          return popup;
        }
      }
    }
    return null;
  }

  static String? _pageButtonPopup(Map button) {
    return AppJson.stringValue(button['popup']);
  }

  bool _progressStepCompleted(int? progressStep) {
    Set<String>? progressPages = _progressPages[progressStep];
    return (progressPages == null) || _completedPages!.containsAll(progressPages);
  }

  String? _currentNotes(List<dynamic>? notes) {

    Map<String, dynamic>? currentPage = _currentPage;
    String? currentPageId = (currentPage != null) ? AppJson.stringValue(currentPage['id']) : null;
    if ((notes != null) && (currentPageId != null)) {
      for (dynamic note in notes) {
        if (note is Map) {
          String? noteId = AppJson.stringValue(note['id']);
          if (noteId == currentPageId) {
            return currentPageId;
          }
        }
      }

      notes.add({
        'id': currentPageId,
        'title': AppJson.stringValue(currentPage!['title']),
      });
    }

    return currentPageId;
  }

  void _resetNotes() {
    Storage().giesNotes = null;
  }

  Future<void> _showPopup(String popupId) async {
    return showDialog(context: context, builder: (BuildContext context) {
      if (popupId == 'notes') {
        return _GiesNotesWidget(notes: AppJson.decodeList(Storage().giesNotes) ?? []);
      }
      else if (popupId == 'current-notes') {
        List<dynamic> notes = AppJson.decodeList(Storage().giesNotes) ?? [];
        String? focusNodeId =  _currentNotes(notes); 
        return _GiesNotesWidget(notes: notes, focusNoteId: focusNodeId,);
      }
      else {
        return Container();
      }
    });
  }

}

class _GiesPageWidget extends StatelessWidget {
  final Map<String, dynamic>? page;
  
  final void Function(String?)? onTapLink;
  final void Function(Map<String, dynamic> button)? onTapButton;
  final void Function()? onTapBack;
  
  _GiesPageWidget({this.page, this.onTapLink, this.onTapButton, this.onTapBack});

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[];

    String? titleHtml = (page != null) ? AppJson.stringValue(page!['title']) : null;
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
                onLinkTap: (url, context, attributes, element) => onTapLink!(url),
                style: {
                  "body": Style(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: FontSize(24), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
                  "a": Style(color: Styles().colors!.fillColorSecondaryVariant),
                },),
            ),
          ),

        ],));
    }

    String? textHtml = (page != null) ? AppJson.stringValue(page!['text']) : null;
    if (AppString.isStringNotEmpty(textHtml)) {
      contentList.add(
        Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
          Html(data: textHtml,
            onLinkTap: (url, context, attributes, element) => onTapLink!(url),
            style: {
              "body": Style(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
              "a": Style(color: Styles().colors!.fillColorSecondaryVariant),
            },),
      ),);
    }

    List<dynamic>? steps = (page != null) ? AppJson.listValue(page!['steps']) : null;
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
                  onLinkTap: (url, context, attributes, element) => onTapLink!(url),
                    style: {
                      "body": Style(color: Styles().colors!.fillColorSecondaryVariant, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
                      "a": Style(color: Styles().colors!.fillColorSecondaryVariant),
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

    List<dynamic>? content = (page != null) ? AppJson.listValue(page!['content']) : null;
    if (content != null) {
      for (dynamic contentEntry in content) {
        if (contentEntry is Map) {
          List<Widget> contentEntryWidgets = <Widget>[];
          
          String? headingHtml = AppJson.stringValue(contentEntry['heading']);
          if (AppString.isStringNotEmpty(headingHtml)) {
            contentEntryWidgets.add(
              Padding(padding: EdgeInsets.only(top: 4, bottom: 4), child:
                Html(data: headingHtml,
                  onLinkTap: (url, context, attributes, element) => onTapLink!(url),
                  style: {
                    "body": Style(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
                    "a": Style(color: Styles().colors!.fillColorSecondaryVariant),
                  },
              ),),
            );
          }

          List<dynamic>? bullets = AppJson.listValue(contentEntry['bullets']);
          if (bullets != null) {
            String bulletText = '\u2022';
            Color? bulletColor = Styles().colors!.textBackground;
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
                        onLinkTap: (url, context, attributes, element) => onTapLink!(url),
                          style: {
                            "body": Style(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
                            "a": Style(color: Styles().colors!.fillColorSecondaryVariant),
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
          
          List<dynamic>? numbers = AppJson.listValue(contentEntry['numbers']);
          if (numbers != null) {
            Color? numberColor = Styles().colors!.textBackground;
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
                        onLinkTap: (url, context, attributes, element) => onTapLink!(url),
                          style: {
                            "body": Style(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
                            "a": Style(color: Styles().colors!.fillColorSecondaryVariant),
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

    List<dynamic>? buttons = (page != null) ? AppJson.listValue(page!['buttons']) : null;
    if (buttons != null) {
      List<Widget> buttonWidgets = <Widget>[];
      for (dynamic button in buttons) {
        if (button is Map) {
          String? title = AppJson.stringValue(button['title']);
          buttonWidgets.add(
            Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              RoundedButton(label: title,
                backgroundColor: Styles().colors!.white,
                textColor: Styles().colors!.fillColorPrimary,
                fontFamily: Styles().fontFamilies!.bold,
                fontSize: 16,
                padding: EdgeInsets.symmetric(horizontal: 16, ),
                borderColor: Styles().colors!.fillColorSecondary,
                borderWidth: 2,
                height: 42,
                onTap:() {
                  try { onTapButton!(button.cast<String, dynamic>()); }
                  catch (e) { print(e.toString()); }
                }
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
            color: Styles().colors!.white,
            boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)) // BorderRadius.all(Radius.circular(4))
        ),
        clipBehavior: Clip.none,
        child: Padding(padding: EdgeInsets.only(top: 16, bottom: 16), child:
          Row(children: [ Expanded(child: Column(children: contentList))],)
        ),
    ),);
  }
}

class _GiesNotesWidget extends StatefulWidget {
  final List<dynamic>? notes;
  final String? focusNoteId;
  _GiesNotesWidget({this.notes, this.focusNoteId});
  _GiesNotesWidgetState createState() => _GiesNotesWidgetState();
}

class _GiesNotesWidgetState extends State<_GiesNotesWidget> {

  Map<String, TextEditingController> _textEditingControllers = Map<String, TextEditingController>();
  FocusNode _focusNode = FocusNode();
  GlobalKey _focusKey = GlobalKey();

  @override
  void initState() {
    _focusNode = FocusNode();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (_focusKey.currentContext != null) {
        Scrollable.ensureVisible(_focusKey.currentContext!, duration: Duration(milliseconds: 300)).then((_) {
          _focusNode.requestFocus();
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textEditingControllers.forEach((key, value) {
      value.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    List<Widget> noteWidgets = <Widget>[];
    if ((widget.notes != null) && widget.notes!.isNotEmpty) {
      //Text(Localization().getStringEx('widget.gies.notes.label.add', 'Add to Notes:'), textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.fillColorPrimary),),
      for (dynamic note in widget.notes!) {
        if (note is Map) {
          String? noteId = AppJson.stringValue(note['id']);
          String title = AppJson.stringValue(note['title'])!;
          String? text = AppJson.stringValue(note['text']);

          TextEditingController? controller = _textEditingControllers[noteId];
          if ((controller == null) && (noteId != null)) {
            _textEditingControllers[noteId] = controller = TextEditingController(text: text ?? '');
          }

          noteWidgets.add(
            Padding(padding: EdgeInsets.only(bottom: 8), child:
              Column(key: (noteId == widget.focusNoteId) ? _focusKey : null, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary),),
                Container(height: 4,),
                TextField(
                  autocorrect: false,
                  focusNode: (noteId == widget.focusNoteId) ? _focusNode : null,
                  controller: controller,
                  maxLines: null,
                  decoration: InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0)), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
                ),
              ])
            )
          );
        }
      }
    }

    return ClipRRect(borderRadius: BorderRadius.all(Radius.circular(8)), child:
      Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),), child:
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(children: <Widget>[
              Expanded(child:
                Container(decoration: BoxDecoration(color: Styles().colors!.fillColorPrimary, borderRadius: BorderRadius.vertical(top: Radius.circular(8)),), child:
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
                    Row(children: [
                      Expanded(child:
                        Text(Localization().getStringEx('widget.gies.notes.title', 'Things to Remember')!, style: TextStyle(fontSize: 20, color: Colors.white),),
                      ),
                      Semantics(
                        label: Localization().getStringEx("dialog.close.title","Close"), button: true,
                        child: InkWell(onTap:() {
                          Analytics.instance.logAlert(text: "Things to Remember", selection: "Close");
                          Navigator.of(context).pop();
                        }, child:
                        Container(height: 30, width: 30, decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(15)), border: Border.all(color: Styles().colors!.white!, width: 2),), child:
                          Center(child:
                            Text('\u00D7', style: TextStyle(fontSize: 24, color: Colors.white, ),semanticsLabel: "", ),
                          ),
                        ),
                      )),
                    ],),),
                ),
              ),
            ],
          ),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
            Column(children: [
              Container(height: 240, child: noteWidgets.isNotEmpty
                ? SingleChildScrollView(child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: noteWidgets,),
                  )
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Expanded(child: Container(),),
                    Row(children: [
                      Expanded(child:
                        Text('No saved notes yet.', textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary),),
                      ),
                    ]),
                    Expanded(child: Container(),),
                  ],),
              ),
              Container(height: 16,),
              Visibility(visible: (widget.notes != null) && widget.notes!.isNotEmpty, child:
                RoundedButton(
                  label: Localization().getStringEx('widget.gies.notes.button.save', 'Save'),
                  backgroundColor: Colors.transparent,
                  textColor: Styles().colors!.fillColorPrimary,
                  borderColor: Styles().colors!.fillColorSecondary,
                  padding: EdgeInsets.symmetric(horizontal: 16, ),
                  borderWidth: 2, height: 42,
                  onTap: () => _onSave(),
                ),
              ),
            ]),
          )
        ],
      )
      ),
    );
  }

  void _onSave() {
    Analytics.instance.logAlert(text: "Things to Remember", selection: "Save");

    if (widget.notes != null) {
      for (dynamic note in widget.notes!) {
        if (note is Map) {
          String? noteId = AppJson.stringValue(note['id']);
          note['text'] = _textEditingControllers[noteId]?.text;
        }
      }
    }

    Storage().giesNotes = AppJson.encode(widget.notes);
    Navigator.of(context).pop();
  }

}