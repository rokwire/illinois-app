
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';

class ScalableFilterSelectorWidget extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? labelFontFamily;
  final double labelFontSize;
  final bool active;
  final EdgeInsets padding;
  final bool visible;
  final GestureTapCallback? onTap;

  ScalableFilterSelectorWidget(
      {required this.label,
        this.hint,
        this.labelFontFamily,
        this.labelFontSize = 16,
        this.active = false,
        this.padding = const EdgeInsets.only(left: 4, right: 4, top: 12),
        this.visible = false,
        this.onTap});

  @override
  Widget build(BuildContext context) {
    return Visibility(
        visible: visible,
        child:
        Semantics(
            label: label,
            hint: hint,
            excludeSemantics: true,
            button: true,
            child: InkWell(
                onTap: onTap,
                child: Container(
                  child: Padding(
                    padding: padding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Expanded(child:
                          Text(
                            label!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: labelFontSize, color: (active ? Styles().colors!.fillColorSecondary : Styles().colors!.fillColorPrimary), fontFamily: labelFontFamily ?? Styles().fontFamilies!.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Image.asset(active ? 'images/icon-up.png' : 'images/icon-down.png', excludeFromSemantics: true),
                        )
                      ],
                    ),
                  ),
                ))));
  }
}

