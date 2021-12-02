
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Styles.dart';

class ScalableRoundedButton extends StatelessWidget {
  final String? label;
  final String? hint;
  final Color? backgroundColor;
  final Function? onTap;
  final Color? textColor;
  final TextAlign textAlign;
  final String? fontFamily;
  final double fontSize;
  final int maxLines;
  final Color? borderColor;
  final double borderWidth;
  final Color? secondaryBorderColor;
  final List<BoxShadow>? shadow;
  final EdgeInsetsGeometry padding;
  final bool enabled;
  final Image? leftIcon;
  final Image? rightIcon;

  ScalableRoundedButton(
      {this.label = '',
        this.hint = '',
        this.backgroundColor,
        this.textColor = Colors.white,
        this.textAlign = TextAlign.center,
        this.fontFamily,
        this.fontSize = 20.0,
        this.padding = const EdgeInsets.all(5),
        this.enabled = true,
        this.borderColor,
        this.borderWidth = 2.0,
        this.secondaryBorderColor,
        this.shadow,
        this.onTap,
        this.leftIcon,
        this.rightIcon,
        this.maxLines = 10
      });

  @override
  Widget build(BuildContext context) {
    BorderRadius borderRadius = BorderRadius.circular(24);
    return Semantics(
        label: label,
        hint: hint,
        button: true,
        excludeSemantics: true,
        enabled: enabled,
        child: InkWell(
          onTap: onTap as void Function()?,
          child: Container(
            decoration: BoxDecoration(
              color: (backgroundColor ?? Styles().colors!.fillColorPrimary),
              border: Border.all(
                  color: (borderColor != null) ? borderColor! : (backgroundColor ?? Styles().colors!.fillColorPrimary!),
                  width: borderWidth),
              borderRadius: borderRadius,
              boxShadow: this.shadow
            ),
            child: Container(
              decoration: BoxDecoration(
                  color: (backgroundColor ?? Styles().colors!.fillColorPrimary),
                  border: Border.all(
                      color: (secondaryBorderColor != null)
                          ? secondaryBorderColor!
                          : (backgroundColor ?? Styles().colors!.fillColorPrimary!),
                      width: borderWidth),
                  borderRadius: borderRadius),
              child: Padding(
                  padding: padding,
                  child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                    (leftIcon != null) ? Padding(padding: EdgeInsets.only(right: 5), child: leftIcon,) : Container(height: 0, width: 0),
                    Expanded(child:
                      Text(label!, textAlign: textAlign, maxLines: maxLines, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: fontFamily ?? Styles().fontFamilies!.bold,
                          fontSize: fontSize,
                          color: textColor,
                        ),
                    )),
                    
                    (rightIcon != null) ? Padding(padding: EdgeInsets.only(left: 5), child: rightIcon,) : Container(height: 0, width: 0),

                    /*Visibility(visible: showChevron, child:
                      Padding(padding: EdgeInsets.only(left: 5), child:
                        Image.asset('images/chevron-right.png'),
                    )),*/
                    
                    /*Visibility(visible: showAdd, child:
                      Padding(padding: EdgeInsets.only(left: 5), child:
                        Image.asset('images/icon-add-20x18.png'),
                    ))*/
                  ],),),
            ),
          ),
        ));
  }
}

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
                          child: Image.asset(active ? 'images/icon-up.png' : 'images/icon-down.png'),
                        )
                      ],
                    ),
                  ),
                ))));
  }
}

class ScalableSmallRoundedButton extends StatelessWidget{
  final String? label;
  final String hint;
  final Color? backgroundColor;
  final Function? onTap;
  final Color? textColor;
  final TextAlign textAlign;
  final String? fontFamily;
  final double fontSize;
  final Color? borderColor;
  final double borderWidth;
  final Color? secondaryBorderColor;
  final List<BoxShadow>? shadow;
  final EdgeInsetsGeometry padding;
  final bool enabled;
  final Image? leftIcon;
  final Image? rightIcon;
  final int widthCoeficient;
  final int maxLines;

  const ScalableSmallRoundedButton({Key? key,
    this.label = '',
    this.hint = '',
    this.backgroundColor,
    this.textColor = Colors.white,
    this.textAlign = TextAlign.center,
    this.fontFamily,
    this.widthCoeficient = 5,
    this.fontSize = 20.0,
    this.padding = const EdgeInsets.all(5),
    this.enabled = true,
    this.borderColor,
    this.borderWidth = 2.0,
    this.secondaryBorderColor,
    this.shadow,
    this.onTap,
    this.leftIcon,
    this.rightIcon,
    this.maxLines = 10
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return
      Row(children: <Widget>[
        Expanded(
          flex: 1,
          child: Container(),
        ),
        Expanded(
          flex: widthCoeficient,
          child: ScalableRoundedButton(
            label: this.label,
            hint: this.hint,
            onTap: onTap,
            textColor: textColor ?? Styles().colors!.fillColorPrimary,
            borderColor: borderColor?? Styles().colors!.fillColorSecondary,
            backgroundColor: backgroundColor?? Styles().colors!.background,
            leftIcon: leftIcon,
            rightIcon: rightIcon,
            textAlign: textAlign,
            padding: padding,
            enabled: enabled,
            fontSize: fontSize,
            borderWidth: borderWidth,
            fontFamily: fontFamily,
            secondaryBorderColor: secondaryBorderColor,
            shadow: shadow,
            maxLines: maxLines,
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(),),
      ],);
  }
}
