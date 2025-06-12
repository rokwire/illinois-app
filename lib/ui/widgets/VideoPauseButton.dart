import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';

class VideoPauseButton extends StatelessWidget {
  final bool hasBackground;

  VideoPauseButton({this.hasBackground = true});

  @override
  Widget build(BuildContext context) {
    final double buttonWidth = 80;
    final double buttonHeight = 50;
    return Container(
        decoration: BoxDecoration(color: (hasBackground ? Styles().colors.iconColor : Colors.transparent), borderRadius: BorderRadius.all(Radius.circular(10))),
        width: buttonWidth,
        height: buttonHeight,
        child: Center(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: (buttonWidth / 10),
                height: (buttonHeight / 2),
                color: Styles().colors.white,
              ),
              Container(width: 8,),
              Container(
                width: (buttonWidth / 10),
                height: (buttonHeight / 2),
                color: Styles().colors.white,
              ),
            ])));
  }
}