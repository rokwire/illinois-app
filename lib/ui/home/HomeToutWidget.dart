import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeToutWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;
  final void Function() onEdit;
  
  HomeToutWidget({Key? key, this.favoriteId, this.updateController, required this.onEdit});

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
    String? title2 = _firstName;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      (imageUrl != null) ? _buildImageWidget(imageUrl) : Container(),
      Container(padding: EdgeInsets.only(bottom: 16,), color: Styles().colors?.fillColorPrimary, child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 16, top: 16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_title1 ?? '', style: Styles().textStyles?.getTextStyle("widget.title.light.medium.fat")),
                Visibility(visible: StringUtils.isNotEmpty(title2), child:
                  Row(children: [
                    Text(title2 ?? '', style: Styles().textStyles?.getTextStyle("widget.title.light.large.extra_fat")),
                    Semantics(label: Localization().getStringEx("widget.home.tout.button.info.label", "Info"), hint: Localization().getStringEx("widget.home.tout.button.info.hint", "Tap for more info"), child:
                      InkWell(onTap: _onInfo, child:
                        Padding(padding: EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8), child:
                          Styles().images?.getImage('info', excludeFromSemantics: true),
                        )
                      ),
                    ),
                  ],)
                ),
              ],),
            )
          ),
          GestureDetector(onTap: _onCustomize, child:
            Padding(padding: EdgeInsets.only(top: 16, right: 16), child:
              Text(Localization().getStringEx('widget.home.tout.customize.label', 'Customize'),
                style: Styles().textStyles?.getTextStyle("widget.home_tout.button.underline.title")))
          ),
        ],)
      )

    ],);
  }

  Widget _buildImageWidget(String imageUrl) {
    final double triangleHeight = 40;
    return Stack(children: [
      Semantics(label: "tout", image: true, excludeSemantics: true, child:
        ModalImageHolder(child: Image.network(imageUrl, semanticLabel: '', loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
        double imageWidth = MediaQuery.of(context).size.width;
        double imageHeight = imageWidth * 810 / 1080;
        return (loadingProgress != null) ?
          Container(color: Styles().colors?.fillColorPrimary, width: imageWidth, height: imageHeight, child:
            Center(child:
              CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors?.white))
            )
          ) :
          AspectRatio(aspectRatio: (1080.0 / 810.0), child: 
            Container(color: Styles().colors?.fillColorPrimary, child: child)
          );
      }))),
      Align(alignment: Alignment.topCenter, child:
        CustomPaint(painter: TrianglePainter(
              painterColor: Styles().colors!.fillColorSecondaryTransparent05,
              horzDir: TriangleHorzDirection.rightToLeft,
              vertDir: TriangleVertDirection.bottomToTop),
          child: Container(height: triangleHeight))),
      Positioned.fill(child:
        Align(alignment: Alignment.bottomCenter, child:
          CustomPaint(painter: TrianglePainter(
                painterColor: Styles().colors!.fillColorSecondaryTransparent05,
                horzDir: TriangleHorzDirection.leftToRight,
                vertDir: TriangleVertDirection.topToBottom),
            child: Container(height: triangleHeight)))),
      Positioned.fill(child:
        Align(alignment: Alignment.bottomCenter, child:
          CustomPaint(painter: TrianglePainter(
                painterColor: Styles().colors!.fillColorPrimary,
                horzDir: TriangleHorzDirection.rightToLeft,
                vertDir: TriangleVertDirection.topToBottom),
            child: Container(height: triangleHeight))))
    ]);
  }

  String? get _title1 {
    if (_dayPart != null) {
      String greeting = AppDateTimeUtils.getDayPartGreeting(dayPart: _dayPart);
      if (_firstName?.isNotEmpty ?? false) {
        return "$greeting,";
      }
      else {
        return StringUtils.capitalize("$greeting!", allWords: false);
      }
    }
    else {
      return null;
    }
  }

  String? get _firstName {
    return Auth2().account?.authType?.uiucUser?.firstName ?? Auth2().profile?.firstName;
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
    Storage().homeToutImageUrl = _imageUrl = Content().randomImageUrl('home.tout.${dayPartToString(_dayPart)}');
    Storage().homeToutImageTime = (_imageDateTime = DateTime.now()).millisecondsSinceEpoch;
  }

  void _onInfo() {
    Analytics().logSelect(target: "Info", source: widget.runtimeType.toString());
    _InfoDialog.show(context);
  }

  void _onCustomize() {
    Analytics().logSelect(target: 'Customize', source: widget.runtimeType.toString());
    widget.onEdit();
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
    final String preferredFirstNameUrlMacro = '{{preferred_first_name_url}}';
    String contentHtml = Localization().getStringEx("widget.home.tout.popup.info.content", "To change your first name in the {{app_title}} app, review the <a href='{{preferred_first_name_url}}'>preferred name instructions</a>.").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'));
    contentHtml = contentHtml.replaceAll(preferredFirstNameUrlMacro, Config().preferredFirstNameStmntUrl ?? '');
    return ClipRRect(borderRadius: BorderRadius.all(Radius.circular(8)), child:
      Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),), alignment: Alignment.center, child: 
        Container(decoration: BoxDecoration(color: Styles().colors?.fillColorPrimary, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 1)), child:
    
          Padding(padding: EdgeInsets.only(left: 24, bottom: 24), child:
            Column(mainAxisSize: MainAxisSize.min, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [
                Expanded(child:
                  Padding(padding: EdgeInsets.only(top: 24), child:
                  HtmlWidget(
                      StringUtils.ensureNotEmpty(contentHtml),
                      onTapUrl : (url) {_onTapLink(context ,url); return true;},
                      textStyle:  Styles().textStyles?.getTextStyle("widget.dialog.message.medium.fat"),
                      customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors!.white ?? Colors.white)} : null
                  )
                    //Text('Illinois app uses your first name from Student Self-Service. You can change your preferred name under Personal Information and Preferred First Name',
                    //  style: TextStyle(color: Styles().colors?.white, fontSize: 16, fontFamily: Styles().fontFamilies!.bold,),
                    //)
                  )
                ),
                Semantics(button: true, label: Localization().getStringEx("dialog.close.title","Close"), child:
                  InkWell(onTap: () => _onTapClose(context), child:
                    Padding(padding: EdgeInsets.all(16), child:
                      Styles().images?.getImage('close-circle-white', excludeFromSemantics: true)
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
      Uri? uri = Uri.tryParse(url!);
      if (uri != null) {
        launchUrl(uri);
      }
    }
  }

}