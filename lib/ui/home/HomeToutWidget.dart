import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeToutWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;
  final void Function()? onEdit;
  
  HomeToutWidget({Key? key, this.favoriteId, this.updateController, this.onEdit});

  @override
  _HomeToutWidgetState createState() => _HomeToutWidgetState();
}

class _HomeToutWidgetState extends State<HomeToutWidget> implements NotificationsListener {

  String? _imageUrl;
  DateTime? _imageDateTime;
  DayPart? _dayPart;
  
  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
      AppLivecycle.notifyStateChanged,
    ]);

    widget.updateController?.stream.listen((String command) {
      if (command == HomePanel.notifyRefresh) {
        _refresh();
      }
    });

    _dayPart = DateTimeUtils.getDayPart();

    _imageUrl = Storage().homeToutImageUrl;
    _imageDateTime = DateTime.fromMillisecondsSinceEpoch(Storage().homeToutImageTime ?? 0);
    if (_shouldUpdateImage(dayPart: _dayPart)) {
      _updateContent(dayPart: _dayPart);
    }

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? imageUrl = _imageUrl;
    String? title2 = _title2;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      (imageUrl != null) ? _buildImageWidget(imageUrl) : Container(),
      Container(padding: EdgeInsets.only(bottom: 16,), color: Styles().colors?.fillColorPrimary, child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 16, top: 16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_title1 ?? '', style: TextStyle(color: Styles().colors?.textColorPrimary, fontFamily: Styles().fontFamilies?.bold, fontSize: 18),),
                Visibility(visible: StringUtils.isNotEmpty(title2), child:
                  Row(children: [
                    Text(title2 ?? '', style: TextStyle(color: Styles().colors?.textColorPrimary, fontFamily: Styles().fontFamilies?.extraBold, fontSize: 20),),
                    Semantics(label: Localization().getStringEx("widget.home.tout.button.info.label", "Info"), hint: Localization().getStringEx("widget.home.tout.button.info.hint", "Tap for more info"), child:
                      InkWell(onTap: _onInfo, child:
                        Padding(padding: EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8), child:
                          Image.asset('images/icon-info-orange.png', excludeFromSemantics: true,),
                        )
                      ),
                    ),
                  ],)
                ),
              ],),
            )
          ),
          GestureDetector(onTap: widget.onEdit, child:
            Padding(padding: EdgeInsets.only(top: 16, right: 16), child: Text(Localization().getStringEx('widget.home.tout.customize.label', 'Customize'),
                        style: TextStyle(color: Styles().colors?.textColorPrimary, fontFamily: Styles().fontFamilies?.bold, fontSize: 18, 
                        decoration: TextDecoration.underline, decorationColor: Styles().colors?.textColorPrimary, decorationThickness: 1)))
          ),
        ],)
      )

    ],);
  }

  Widget _buildImageWidget(String imageUrl) {
    final double triangleHeight = 40;
    return Stack(children: [
      Image.network(imageUrl, semanticLabel: 'tout',
          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
        double imageWidth = MediaQuery.of(context).size.width;
        double imageHeight = imageWidth * 810 / 1080;
        return (loadingProgress != null)
            ? Container(
                color: Styles().colors?.fillColorPrimary,
                width: imageWidth,
                height: imageHeight,
                child: Center(
                    child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors?.white))))
            : child;
      }),
      Align(
          alignment: Alignment.topCenter,
          child: CustomPaint(
              painter: TrianglePainter(
                  painterColor: Styles().colors!.fillColorSecondaryTransparent05,
                  horzDir: TriangleHorzDirection.rightToLeft,
                  vertDir: TriangleVertDirection.bottomToTop),
              child: Container(height: triangleHeight))),
      Positioned.fill(
          child: Align(
              alignment: Alignment.bottomCenter,
              child: CustomPaint(
                  painter: TrianglePainter(
                      painterColor: Styles().colors!.fillColorSecondaryTransparent05,
                      horzDir: TriangleHorzDirection.leftToRight,
                      vertDir: TriangleVertDirection.topToBottom),
                  child: Container(height: triangleHeight)))),
      Positioned.fill(
          child: Align(
              alignment: Alignment.bottomCenter,
              child: CustomPaint(
                  painter: TrianglePainter(
                      painterColor: Styles().colors!.fillColorPrimary,
                      horzDir: TriangleHorzDirection.rightToLeft,
                      vertDir: TriangleVertDirection.topToBottom),
                  child: Container(height: triangleHeight))))
    ]);
  }

  String? get _title1 {
    if (_dayPart != null) {
      String greeting = AppDateTimeUtils.getDayPartGreeting(dayPart: _dayPart);
      if (Auth2().firstName?.isNotEmpty ?? false) {
        return "$greeting,";
      }
      else {
        return StringUtils.capitalize("$greeting!", allWords: true);
      }
    }
    else {
      return null;
    }
  }

  String? get _title2 {
    return Auth2().firstName;
  }

  bool _shouldUpdateImage({DayPart? dayPart}) {
    dayPart ??= DateTimeUtils.getDayPart();
    return (_imageUrl == null) || (_imageDateTime == null) || (4 < DateTime.now().difference(_imageDateTime!).inHours) || (dayPart != DateTimeUtils.getDayPart(dateTime: _imageDateTime));
  }

  void _update() {
    DayPart dayPart = DateTimeUtils.getDayPart();
    if ((_dayPart != dayPart) || _shouldUpdateImage(dayPart: dayPart)) {
      _updateContent(dayPart: dayPart);

      if (mounted) {
        setState(() {});
      }
    }
  }

  void _refresh() {
    _updateContent();
    if (mounted) {
      setState(() {});
    }
  }

  void _updateContent({DayPart? dayPart}) {
    _dayPart = dayPart ?? DateTimeUtils.getDayPart();
    Storage().homeToutImageUrl = _imageUrl = Assets().randomStringFromListWithKey('images.random.home.tout.${dayPartToString(_dayPart)}');
    Storage().homeToutImageTime = (_imageDateTime = DateTime.now()).millisecondsSinceEpoch;
  }

  void _onInfo() {
    Analytics().logSelect(target: "Search");
    _InfoDialog.show(context);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyLoginChanged) {
      if (mounted) {
        setState(() {});
      }
    }
    else if ((name == AppLivecycle.notifyStateChanged) && (param == AppLifecycleState.resumed)) {
      _update();
    }
  }
}

class _InfoDialog extends StatelessWidget {

  static void show(BuildContext context) {
    showDialog(context: context, builder: (_) =>  _InfoDialog(),);
  }

  @override
  Widget build(BuildContext context) {
    final String selfServiceUrlMacro = '{{student_self_service_url}}';
    String contentHtml = Localization().getStringEx("widget.home.tout.popup.info.content", "Illinois app uses your first name from <a href='{{student_self_service_url}}'>Student Self-Service</a>. You can change your preferred name under Personal Information and Preferred First Name.");
    contentHtml = contentHtml.replaceAll(selfServiceUrlMacro, Config().studentSelfServiceUrl ?? '');
    return ClipRRect(borderRadius: BorderRadius.all(Radius.circular(8)), child:
      Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),), alignment: Alignment.center, child: 
        Container(decoration: BoxDecoration(color: Styles().colors?.fillColorPrimary, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 1)), child:
    
          Padding(padding: EdgeInsets.only(left: 24, bottom: 24), child:
            Column(mainAxisSize: MainAxisSize.min, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [
                Expanded(child:
                  Padding(padding: EdgeInsets.only(top: 24), child:
                    Html(data: contentHtml,
                      onLinkTap: (url, renderContext, attributes, element) => _onTapLink(context, url),
                      style: {
                        "body": Style(color: Styles().colors?.white, fontFamily: Styles().fontFamilies!.bold, fontSize: FontSize(16), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
                        "a": Style(color: Styles().colors?.fillColorSecondaryVariant),
                      },),
                    //Text('Illinois app uses your first name from Student Self-Service. You can change your preferred name under Personal Information and Preferred First Name',
                    //  style: TextStyle(color: Styles().colors?.white, fontSize: 16, fontFamily: Styles().fontFamilies!.bold,),
                    //)
                  )
                ),
                Semantics(button: true, label: Localization().getStringEx("dialog.close.title","Close"), child:
                  InkWell(onTap: () => _onTapClose(context), child:
                    Padding(padding: EdgeInsets.all(16), child:
                      Image.asset('images/close-white.png', excludeFromSemantics: true,)
                    )
                  )
                )
              ]),
            ]),
          ),

        ),
      ),
    );
  }

  void _onTapClose(BuildContext context) {
    Analytics().logAlert(text: "Info", selection: "Close");
    Navigator.pop(context);
  }

  void _onTapLink(BuildContext context, String? url) {
    Analytics().logAlert(text: "Info", selection: "Student Self Service");
    if (StringUtils.isNotEmpty(url)) {
      Navigator.pop(context);
      launch(url!);
    }
  }

}