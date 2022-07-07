
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';

class LinkButton extends StatelessWidget {
  final String? title;
  final String? hint;
  final void Function()? onTap;
  final EdgeInsetsGeometry padding;

  final Widget? textWidget;
  final TextStyle? textStyle;
  final Color? textColor;
  final String? fontFamily;
  final double fontSize;
  final TextAlign textAlign;
  final TextDecoration textDecoration;
  final TextDecorationStyle textDecorationStyle;
  final double textDecorationThickness;
  final Color? textDecorationColor;

  LinkButton({Key? key,
    this.title,
    this.hint,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 16),

    this.textWidget,
    this.textStyle,
    this.textColor,
    this.fontFamily,
    this.fontSize = 16,
    this.textAlign = TextAlign.center,
    this.textDecoration = TextDecoration.underline,
    this.textDecorationStyle = TextDecorationStyle.solid,
    this.textDecorationThickness = 1,
    this.textDecorationColor,

  }) : super(key: key);

  String? get _fontFamily => fontFamily ?? Styles().fontFamilies?.medium;
  Color? get _textColor => textColor ?? Styles().colors?.fillColorPrimary;
  Color? get _textDecorationColor => textDecorationColor ?? Styles().colors?.fillColorSecondary;
  TextStyle get _textStyle => textStyle ?? TextStyle(fontFamily: _fontFamily, fontSize: fontSize, color: _textColor, decoration: textDecoration, decorationThickness: textDecorationThickness, decorationStyle: textDecorationStyle, decorationColor: _textDecorationColor);
  Widget get _textWidget => textWidget ?? Text(title ?? '', style: _textStyle, textAlign: textAlign,);

  @override
  Widget build(BuildContext context) {
    return Semantics(label: title, hint: hint, button: true, child:
      InkWell(onTap: onTap, child:
        Padding(padding: padding, child:
          _textWidget
        ),
      ),
    );
  }
}