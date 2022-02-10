/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';

class RoundedButton extends StatefulWidget {
  final String label;
  final void Function() onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final MainAxisSize mainAxisSize;
  final double? minAxisContentWeight;
  final MainAxisAlignment minAxisAlignment;
  
  final TextStyle? textStyle;
  final Color? textColor;
  final String? fontFamily;
  final double fontSize;
  final TextAlign textAlign;

  final Widget? leftIcon;
  final EdgeInsetsGeometry? leftIconPadding;
  
  final Widget? rightIcon;
  final EdgeInsetsGeometry? rightIconPadding;

  final double iconPadding;

  final String? hint;
  final bool enabled;

  final BoxBorder? border;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? borderShadow;
  final double? maxBorderRadius;

  final BoxBorder? secondaryBorder;
  final Color? secondaryBorderColor;
  final double? secondaryBorderWidth;

  final bool? progress;
  final Color? progressColor;
  final double? progressSize;
  final double? progressStrokeWidth;

  RoundedButton({
    required this.label,
    required this.onTap,
    this.backgroundColor,      //= Styles().colors.white
    this.padding                 = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    this.mainAxisSize            = MainAxisSize.max,
    this.minAxisContentWeight,
    this.minAxisAlignment        = MainAxisAlignment.center,

    this.textStyle,
    this.textColor,            //= Styles().colors.fillColorPrimary
    this.fontFamily,           //= Styles().fontFamilies.bold
    this.fontSize                = 20.0,
    this.textAlign               = TextAlign.center,

    this.leftIcon,
    this.leftIconPadding,
    this.rightIcon,
    this.rightIconPadding,
    this.iconPadding             = 8,

    this.hint,
    this.enabled                 = true,

    this.border,
    this.borderColor,          //= Styles().colors.fillColorSecondary
    this.borderWidth             =  2.0,
    this.borderShadow,
    this.maxBorderRadius         = 24.0,

    this.secondaryBorder,
    this.secondaryBorderColor,
    this.secondaryBorderWidth,
    
    this.progress,
    this.progressColor,
    this.progressSize,
    this.progressStrokeWidth,
  });

  _RoundedButtonState createState() => _RoundedButtonState();


}

class _RoundedButtonState extends State<RoundedButton> {
  final GlobalKey _contentKey = GlobalKey();
  Size? _contentSize;

  Color get _backgroundColor => widget.backgroundColor ?? Styles().colors!.white!;
  
  Color get _textColor => widget.textColor ?? Styles().colors!.fillColorPrimary!;
  String get _fontFamily => widget.fontFamily ?? Styles().fontFamilies!.bold!;
  TextStyle get _textStyle => widget.textStyle ?? TextStyle(fontFamily: _fontFamily, fontSize: widget.fontSize, color: _textColor);

  Color get _borderColor => widget.borderColor ?? Styles().colors!.fillColorSecondary!;

  Widget get _leftIcon => widget.leftIcon ?? Container();
  EdgeInsetsGeometry get _leftIconPadding => widget.leftIconPadding ?? EdgeInsets.all(widget.iconPadding);
  bool get _hasLeftIcon => (widget.leftIcon != null) || (widget.leftIconPadding != null);
  
  Widget get _rightIcon => widget.rightIcon ?? Container();
  EdgeInsetsGeometry get _rightIconPadding => widget.rightIconPadding ?? EdgeInsets.all(widget.iconPadding);
  bool get _hasRightIcon => (widget.rightIcon != null) || (widget.rightIconPadding != null);

  Color get _progressColor => widget.progressColor ?? _borderColor;
  double get _progressSize => widget.progressSize ?? ((_contentSize?.height ?? 0) / 2);
  double get _progressStrokeWidth => widget.progressStrokeWidth ?? widget.borderWidth;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _evalHeight();
    });
  }

  @override
  Widget build(BuildContext context) {
    return (widget.progress == true)
      ? Stack(children: [ _outerContent, _progressContent, ],)
      : _outerContent;
  }

  Widget get _outerContent {
    return Semantics(label: widget.label, hint: widget.hint, button: true, enabled: widget.enabled, child:
      InkWell(onTap: widget.onTap, child:
        _wrapperContent
      ),
    );
  }

  Widget get _wrapperContent {
    if (widget.mainAxisSize == MainAxisSize.max) {
      return Row(children: [
        Expanded(child: _borderContent)
      ]);
    }
    else if (widget.minAxisContentWeight != null) {
      if (widget.minAxisAlignment == MainAxisAlignment.start) {
        return Row(children: [
          Expanded(flex: (100 * widget.minAxisContentWeight!).toInt(), child: _borderContent),
          Expanded(flex: (100 * max(1 - widget.minAxisContentWeight!, 0)).toInt(), child: Container()),
        ]);
      }
      else if (widget.minAxisAlignment == MainAxisAlignment.end) {
        return Row(children: [
          Expanded(flex: (100 * max(1 - widget.minAxisContentWeight!, 0)).toInt(), child: Container()),
          Expanded(flex: (100 * widget.minAxisContentWeight!).toInt(), child: _borderContent),
        ]);
      }
      else {
        return Row(children: [
          Expanded(flex: (100 * max(1 - widget.minAxisContentWeight!, 0) ~/ 2), child: Container()),
          Expanded(flex: (100 * widget.minAxisContentWeight!).toInt(), child: _borderContent),
          Expanded(flex: (100 * max(1 - widget.minAxisContentWeight!, 0) ~/ 2), child: Container()),
        ]);
      }
    }
    else {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        _borderContent
      ]);
    }
  }

  Widget get _borderContent {

    BorderRadiusGeometry? borderRadius = (_contentSize != null) ? BorderRadius.circular((widget.maxBorderRadius != null) ? min(_contentSize!.height / 2, widget.maxBorderRadius!) : (_contentSize!.height / 2)) : null;

    BoxBorder border = widget.border ?? Border.all(color: _borderColor, width: widget.borderWidth);

    BoxBorder? secondaryBorder = widget.secondaryBorder ?? ((widget.secondaryBorderColor != null) ? Border.all(
      color: widget.secondaryBorderColor!,
      width: widget.secondaryBorderWidth ?? widget.borderWidth
    ) : null);

    return Container(key: _contentKey, decoration: BoxDecoration(color: _backgroundColor, border: border, borderRadius: borderRadius, boxShadow: widget.borderShadow), child: (secondaryBorder != null)
      ? Container(decoration: BoxDecoration(color: _backgroundColor, border: secondaryBorder, borderRadius: borderRadius), child: _innerContent)
      : _innerContent
    );
  }

  Widget get _innerContent {
    if ((widget.rightIcon != null) || (widget.leftIcon != null)) {
      List<Widget> rowContent = <Widget>[];
      
      if (_hasLeftIcon) {
        rowContent.add(Padding(padding: _leftIconPadding, child: _leftIcon,));
      }
      else if (_hasRightIcon && (widget.textAlign == TextAlign.center)) {
        // add space keeper at left to keep text content centered
        rowContent.add(Padding(padding: _rightIconPadding, child: Visibility(visible: false, maintainSize: true, maintainAnimation: true, maintainState: true, child: _rightIcon)));
      }

      rowContent.add((widget.mainAxisSize == MainAxisSize.max) ?
        Expanded(child:
          Padding(padding: widget.padding, child:
            Text(widget.label, style: _textStyle, textAlign: widget.textAlign,)
          )
        ) :
        Padding(padding: widget.padding, child:
          Text(widget.label, style: _textStyle, textAlign: widget.textAlign,)
        )
      );

      if (_hasRightIcon) {
        rowContent.add(Padding(padding: _rightIconPadding, child: _rightIcon,));
      }
      else if (_hasLeftIcon && (widget.textAlign == TextAlign.center)) {
        // add space keeper at right to keep text content centered
        rowContent.add(Padding(padding: _leftIconPadding, child: Visibility(visible: false, maintainSize: true, maintainAnimation: true, maintainState: true, child: _leftIcon)));
      }

      return Semantics(excludeSemantics: true, child:
        Row(mainAxisAlignment: MainAxisAlignment.center, children: rowContent)
      );
    }
    else {
      return Semantics(excludeSemantics: true, child:
        Padding(padding: widget.padding, child:
          Text(widget.label, style: _textStyle, textAlign: widget.textAlign,)
        )
      );
    }
  }

  Widget get _progressContent {
    return (_contentSize != null) ? Container(width: _contentSize!.width, height: _contentSize!.height,
      child: Align(alignment: Alignment.center,
        child: SizedBox(height: _progressSize, width: _progressSize,
            child: CircularProgressIndicator(strokeWidth: _progressStrokeWidth, valueColor: AlwaysStoppedAnimation<Color?>(_progressColor), )
        ),
      ),
    ): Container();
  }

  void _evalHeight() {
    try {
      final RenderObject? renderBox = _contentKey.currentContext?.findRenderObject();
      if (renderBox is RenderBox) {
        if (mounted) {
          setState(() {
            _contentSize = renderBox.size;
          });
        }
      }
    } catch (e) {
      print(e.toString());
    }
  }
}

class SmallRoundedButton extends RoundedButton {
  SmallRoundedButton({
    required String label,
    required void Function() onTap,
    Color? backgroundColor               = Colors.transparent,
    EdgeInsetsGeometry padding           = const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
    MainAxisSize mainAxisSize            = MainAxisSize.min,
  
    TextStyle? textStyle,
    Color? textColor,
    String? fontFamily,
    double? fontSize,
    TextAlign? textAlign,

    Widget? leftIcon,
    EdgeInsetsGeometry? leftIconPadding  = const EdgeInsets.only(right: 15),
  
    Widget? rightIcon,
    EdgeInsetsGeometry? rightIconPadding = const EdgeInsets.only(right: 15),

    double iconPadding                   = 8,

    String? hint,
    bool enabled                         = true,

    BoxBorder? border,
    Color? borderColor,
    double borderWidth                   = 2.0,
    List<BoxShadow>? borderShadow,
    double? maxBorderRadius = 24.0,

    BoxBorder? secondaryBorder,
    Color? secondaryBorderColor,
    double? secondaryBorderWidth,

    bool? progress,
    Color? progressColor,
    double? progressSize,
    double? progressStrokeWidth,

  }) : super(
    label: label,
    onTap: onTap,
    backgroundColor: backgroundColor,
    padding: padding,
    mainAxisSize : mainAxisSize,
  
    textStyle : textStyle,
    textColor : textColor,
    fontFamily : fontFamily,
    fontSize: fontSize ?? 16,
    textAlign: textAlign ?? TextAlign.left,

    leftIcon: leftIcon,
    leftIconPadding: leftIconPadding,
  
    rightIcon: rightIcon ?? Image.asset('images/chevron-right.png', excludeFromSemantics: true),
    rightIconPadding: rightIconPadding,

    iconPadding: iconPadding,

    hint: hint,
    enabled: enabled,

    border: border,
    borderColor: borderColor,
    borderWidth: borderWidth,
    borderShadow: borderShadow,
    maxBorderRadius: maxBorderRadius,

    secondaryBorder: secondaryBorder,
    secondaryBorderColor: secondaryBorderColor,
    secondaryBorderWidth: secondaryBorderWidth,

    progress: progress,
    progressColor: progressColor,
    progressSize: progressSize,
    progressStrokeWidth: progressStrokeWidth,
  );

}
