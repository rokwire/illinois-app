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
  final String? hint;
  final void Function() onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final MainAxisSize mainAxisSize;
  final bool? progress;

  final TextStyle? textStyle;
  final Color? textColor;
  final String? fontFamily;
  final double fontSize;
  final TextAlign textAlign;

  final BoxBorder? border;
  final Color? borderColor;
  final double borderWidth;
  final double? maxBorderRadius;

  final BoxBorder? secondaryBorder;
  final Color? secondaryBorderColor;
  final double? secondaryBorderWidth;

  final Color? progressColor;
  final double? progressSize;
  final double? progressStrokeWidth;


  RoundedButton({
    required this.label,
    this.hint,
    required this.onTap,
    this.backgroundColor,      //= Styles().colors.white
    this.padding                 = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    this.mainAxisSize            = MainAxisSize.max,
    this.progress,

    this.textStyle,
    this.textColor,            //= Styles().colors.fillColorPrimary
    this.fontFamily,           //= Styles().fontFamilies.bold
    this.fontSize                = 20.0,
    this.textAlign               = TextAlign.center,

    this.border,
    this.borderColor,          //= Styles().colors.fillColorSecondary
    this.borderWidth             =  2.0,
    this.maxBorderRadius         = 24.0,

    this.secondaryBorder,
    this.secondaryBorderColor,
    this.secondaryBorderWidth,
    
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
    return Semantics(label: widget.label, hint: widget.hint, button: true /*, enabled: enabled*/, child:
      InkWell(onTap: widget.onTap, child:
        _wrapperContent
      ),
    );
  }

  Widget get _wrapperContent {
    return Row(children: [ (widget.mainAxisSize == MainAxisSize.max)
      ? Expanded(child: _borderContent)
      : _borderContent
    ]);
  }

  Widget get _borderContent {

    BorderRadiusGeometry? borderRadius = (_contentSize != null) ? BorderRadius.circular((widget.maxBorderRadius != null) ? min(_contentSize!.height / 2, widget.maxBorderRadius!) : (_contentSize!.height / 2)) : null;

    BoxBorder border = widget.border ?? Border.all(color: _borderColor, width: widget.borderWidth);

    BoxBorder? secondaryBorder = widget.secondaryBorder ?? ((widget.secondaryBorderColor != null) ? Border.all(
      color: widget.secondaryBorderColor!,
      width: widget.secondaryBorderWidth ?? widget.borderWidth
    ) : null);

    return Container(key: _contentKey, decoration: BoxDecoration(color: _backgroundColor, border: border, borderRadius: borderRadius), child: (secondaryBorder != null)
      ? Container(decoration: BoxDecoration(color: _backgroundColor, border: secondaryBorder, borderRadius: borderRadius), child: _innerContent)
      : _innerContent
    );
  }

  Widget get _innerContent {
    return Padding(padding: widget.padding, child:
      Semantics(excludeSemantics: true, child:
        Text(widget.label, style: _textStyle, textAlign: widget.textAlign,),
      ),
    );
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

class SmallRoundedButton extends StatelessWidget {
  final String? label;
  final String? hint;
  final GestureTapCallback? onTap;
  final bool showChevron;
  final Color? borderColor;

  SmallRoundedButton({required this.label, this.hint = '', this.onTap, this.showChevron = true, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        child: Semantics(
          label: label,
          hint: hint,
          button: true,
          excludeSemantics: true,
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor ?? Styles().colors!.fillColorSecondary!, width: 2.0),
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label!,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies!.bold,
                        fontSize: 16,
                        color: Styles().colors!.fillColorPrimary),
                  ),
                  Visibility(
                      visible: showChevron,
                      child: Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Image.asset('images/chevron-right.png', excludeFromSemantics: true),
                      ))
                ],
              ),
            ),
          ),
        ));
  }
}