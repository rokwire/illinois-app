
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/localization.dart';

class InfoPopup extends StatelessWidget {

  final Color? backColor;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  final double borderRadius;
  final BoxBorder? border;

  final String? infoText;
  final TextStyle? infoTextStyle;

  final Widget? closeIcon;
  final EdgeInsetsGeometry closeIconMargin;

  InfoPopup({Key? key,
    this.backColor,
    this.padding = const EdgeInsets.all(24),
    this.alignment = Alignment.center,

    this.borderRadius = 8,
    this.border,

    this.infoText,
    this.infoTextStyle,

    this.closeIcon,
    this.closeIconMargin = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius),), alignment: alignment, child: 
      ClipRRect(borderRadius: BorderRadius.all(Radius.circular(borderRadius)), child:
        Container(decoration: BoxDecoration(color: backColor, borderRadius: BorderRadius.circular(borderRadius), border: border), child:
    
          Stack(children: [
            Padding(padding: padding, child:
              Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Row(children: [
                  Expanded(child:
                    Text(infoText ?? '', style: infoTextStyle),
                  ),
                ],),
              ],),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(child: Container()),
                Semantics( label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), button: true, child:
                  InkWell(onTap : () => _onClose(context), child:
                    Padding(padding:closeIconMargin, child: 
                      closeIcon,
                    ),
                  ),
                ),
              ]),
            ],)
          ],)

        ),
      ),
    );
  }

  void _onClose(BuildContext context) {
    Analytics().logSelect(target: 'Close');
    Navigator.pop(context);
  }
}
