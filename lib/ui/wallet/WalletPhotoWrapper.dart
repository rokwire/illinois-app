
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Transportation.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';

class WalletPhotoWrapper extends StatefulWidget {

  final double topOffset;
  final Color? headingColor;
  final Color? accentColor;
  final Color? borderColor;
  final Color backgroundColor;
  final Widget? child;

  WalletPhotoWrapper({super.key, this.topOffset = 0, this.headingColor, this.accentColor, this.borderColor, this.backgroundColor = Colors.white, this.child });

  static double photoSize(BuildContext context) => _WalletPhotoWrapperState._defaultPhotoSize(context);

  @override
  State<StatefulWidget> createState() => _WalletPhotoWrapperState();
}

class _WalletPhotoWrapperState extends State<WalletPhotoWrapper> with NotificationsListener, SingleTickerProviderStateMixin {

  Color? _headingColor;
  MemoryImage? _photoImage;
  late AnimationController _animationController;

  static double _defaultPhotoSize(BuildContext context) => MediaQuery.of(context).size.width * 0.56;
  double get _photoSize => _defaultPhotoSize(context);
  double get _photoTopOffset => widget.topOffset + 16;
  double get _childTopOffset => _photoTopOffset + _photoSize + _illiniIconSize / 2 + 16;
  double get _headingH1 => _photoTopOffset + _photoSize / 2 - _headingH2 / 5;
  double get _headingH2 => _photoSize / 3;
  double get _illiniIconSize => 64;

  Color get _displayBorderColor => widget.borderColor ?? widget.headingColor ?? _headingColor ?? Styles().colors.fillColorSecondary;
  Color get _displayHeadingColor => widget.headingColor ?? _headingColor ?? widget.backgroundColor; // ?? Styles().colors.fillColorPrimary;
  Color get _displayAccentColor => widget.accentColor ?? Styles().colors.fillColorSecondary;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      Auth2.notifyCardChanged,
    ]);

    _animationController = AnimationController(duration: Duration(milliseconds: 1500), lowerBound: 0, upperBound: 2 * math.pi, animationBehavior: AnimationBehavior.preserve, vsync: this)
    ..addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _animationController.repeat();

    _updatePhotoImage();

    if (widget.headingColor == null) {
      _updateHeadingColor();
    }
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WalletPhotoWrapper oldWidget) {
    if ((widget.headingColor == null) && (_headingColor == null)) {
      _updateHeadingColor();
    }
    super.didUpdateWidget(oldWidget);
  }

  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if ((name == Auth2.notifyCardChanged) && mounted) {
      _updatePhotoImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Container(height: _headingH1, color: _displayHeadingColor,), //
        Container(height: _headingH2, color: _displayHeadingColor, child:
          CustomPaint(painter: TrianglePainter(painterColor: widget.backgroundColor), child: Container(),),
        ),
      ],),

      if (Auth2().iCard != null)
        Padding(padding: EdgeInsets.only(top: _photoTopOffset), child:
          _photoWidget,
        ),

      if (widget.child != null)
        Padding(padding: EdgeInsets.only(top: _childTopOffset), child:
          widget.child,
        ),
    ],);
  }

  Widget get _photoWidget =>
    Stack(children: <Widget>[
      Align(alignment: Alignment.topCenter, child:
        Container(width: _photoSize, height: _photoSize, child:
          Stack(children: <Widget>[
            Transform.rotate(angle: _animationController.value, child:
              Container(width: _photoSize, height: _photoSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    // colors: [ Styles().colors.fillColorSecondary, _displayBorderColor],
                    colors: [ _displayAccentColor, _displayBorderColor],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 1.0],
                  ),
                  color: Styles().colors.fillColorSecondary,
                ),
              ),
            ),
            _photoImageWidget,
        ],),
      ),
    ),
    Align(alignment: Alignment.topCenter, child:
      Padding(padding: EdgeInsets.only(top:_photoSize - _illiniIconSize / 2 - 5, left: 3), child:
        Styles().images.getImage('university-logo-circle-white', excludeFromSemantics: true, width: _illiniIconSize, height: _illiniIconSize,)
      ),
    ),
  ],);

  Widget get _photoImageWidget =>
    Container(width: _photoSize, height: _photoSize, child:
      Padding(padding: EdgeInsets.all(16), child:
        Container(decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          image: (_photoImage != null) ? DecorationImage(fit: BoxFit.cover, image:_photoImage! ,) : null
        ))
      ),
    );

  Future<MemoryImage?> loadPhotoImage() async {
    Uint8List? photoBytes = await  Auth2().iCard?.photoBytes;
    try { return ((photoBytes != null) && photoBytes.isNotEmpty) ? MemoryImage(photoBytes) : null; }
    catch(e) { debugPrint(e.toString()); return null; }
  }

  void _updatePhotoImage() {
    loadPhotoImage().then((MemoryImage? photoImage){
      if (mounted) {
        setState(() {
          _photoImage = photoImage;
        });
      }
    });
  }

  void _updateHeadingColor() {
    Transportation().loadBusColor(deviceId: Auth2().deviceId, userId: Auth2().accountId).then((Color? color) {
      if (mounted && (color != null)) {
        setState(() {
          _headingColor = color;
        });
      }
    });
  }

}
