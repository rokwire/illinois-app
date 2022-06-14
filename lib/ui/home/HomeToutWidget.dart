import 'dart:async';

import 'package:flutter/material.dart';
import 'package:illinois/service/Auth2.dart';
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

class HomeToutWidget extends StatefulWidget {
  static const String notifyImageUpdate      = "edu.illinois.rokwire.home.tout.image.update";

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
  String? _greeting;
  
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

    _imageUrl = Storage().homeToutImageUrl;
    _imageDateTime = DateTime.fromMillisecondsSinceEpoch(Storage().homeToutImageTime ?? 0);
    if ((_imageUrl == null) || (_imageDateTime == null) || _shouldUpdateImage) {
      Storage().homeToutImageUrl = _imageUrl = Assets().randomStringFromListWithKey('images.random.home.tout');
      Storage().homeToutImageTime = (_imageDateTime = DateTime.now()).microsecondsSinceEpoch;
      NotificationService().notify(HomeToutWidget.notifyImageUpdate);
    }

    _greeting = AppDateTimeUtils.getDayGreeting();
    
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      (imageUrl != null) ? _buildImageWidget(imageUrl) : Container(),
      Container(padding: EdgeInsets.only(bottom: 16,), color: Styles().colors?.fillColorPrimary, child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 16, top: 16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title1 ?? '', style: TextStyle(color: Styles().colors?.textColorPrimary, fontFamily: Styles().fontFamilies?.bold, fontSize: 18),),
                Text(title2 ?? '', style: TextStyle(color: Styles().colors?.textColorPrimary, fontFamily: Styles().fontFamilies?.extraBold, fontSize: 20),)
              ],),
            )
          ),
          GestureDetector(onTap: widget.onEdit, child:
            Padding(padding: EdgeInsets.only(top: 16, right: 16), child: Text(Localization().getStringEx('widget.home.tout.reorder.label', 'Reorder'),
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

  String? get title1 {
    if (_greeting?.isNotEmpty ?? false) {
      if (Auth2().firstName?.isNotEmpty ?? false) {
        return "$_greeting,";
      }
      else {
        return StringUtils.capitalize("$_greeting!", allWords: true);
      }
    }
    else {
      return null;
    }
  }

  String? get title2 {
    return Auth2().firstName;
  }

  bool get _shouldUpdateImage {
    return (_imageDateTime == null) || (4 < DateTime.now().difference(_imageDateTime!).inHours);
  }

  void _update() {
    String? greeting = AppDateTimeUtils.getDayGreeting();
    if (mounted && ((_greeting != greeting) || _shouldUpdateImage)) {
      Storage().homeToutImageUrl = _imageUrl = Assets().randomStringFromListWithKey('images.random.home.tout');
      Storage().homeToutImageTime = (_imageDateTime = DateTime.now()).microsecondsSinceEpoch;
      NotificationService().notify(HomeToutWidget.notifyImageUpdate);

      _greeting = greeting;

      if (mounted) {
        setState(() {});
      }
    }
  }

  void _refresh() {
    Storage().homeToutImageUrl = _imageUrl = Assets().randomStringFromListWithKey('images.random.home.tout');
    Storage().homeToutImageTime = (_imageDateTime = DateTime.now()).microsecondsSinceEpoch;
    NotificationService().notify(HomeToutWidget.notifyImageUpdate);
    
    _greeting = AppDateTimeUtils.getDayGreeting();
    
    if (mounted) {
      setState(() {});
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyLoginChanged) {
      if (mounted) {
        setState(() {});
      }
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      if (param == AppLifecycleState.resumed) {
        _update();
      }
    }
  }
}