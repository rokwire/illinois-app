import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AngledRibbonButton extends StatefulWidget {
  final String? label;
  final String? description;
  final void Function()? onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  final double triangleWidthFraction;

  final Widget? textWidget;
  final TextStyle? textStyle;
  final Color? textColor;
  final String? fontFamily;
  final double fontSize;
  final TextAlign textAlign;

  final Widget? descriptionWidget;
  final TextStyle? descriptionTextStyle;
  final Color? descriptionTextColor;
  final String? descriptionFontFamily;
  final double descriptionFontSize;
  final TextAlign descriptionTextAlign;
  final EdgeInsetsGeometry descriptionPadding;

  final Widget? leftIcon;
  final String? leftIconKey;
  final EdgeInsetsGeometry leftIconPadding;

  final Widget? rightIcon;
  final String? rightIconKey;
  final EdgeInsetsGeometry rightIconPadding;

  final BoxBorder? border;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? borderShadow;

  final bool? progress;
  final Color? progressColor;
  final double? progressSize;
  final double? progressStrokeWidth;
  final EdgeInsetsGeometry progressPadding;
  final AlignmentGeometry progressAlignment;
  final bool progressHidesIcon;

  final String? hint;
  final String? semanticsValue;

  const AngledRibbonButton({Key? key,
    this.label,
    this.description,
    this.onTap,
    this.backgroundColor,      //= Styles().colors.white
    this.padding,

    this.triangleWidthFraction = 1/20,

    this.textWidget,
    this.textStyle,
    this.textColor,            //= Styles().colors.fillColorPrimary
    this.fontFamily,           //= Styles().fontFamilies.bold
    this.fontSize                = 16.0,
    this.textAlign               = TextAlign.left,

    this.descriptionWidget,
    this.descriptionTextStyle,
    this.descriptionTextColor,  //= Styles().colors.textSurface
    this.descriptionFontFamily, //= Styles().fontFamilies.regular
    this.descriptionFontSize    = 14.0,
    this.descriptionTextAlign   = TextAlign.left,
    this.descriptionPadding     = const EdgeInsets.only(top: 2),

    this.leftIcon,
    this.leftIconKey,
    this.leftIconPadding         = const EdgeInsets.only(right: 8),

    this.rightIcon,
    this.rightIconKey,
    this.rightIconPadding        = const EdgeInsets.only(left: 8),

    this.border,
    this.borderShadow,
    this.borderRadius,

    this.progress,
    this.progressColor,
    this.progressSize,
    this.progressStrokeWidth,
    this.progressPadding            = const EdgeInsets.symmetric(horizontal: 12),
    this.progressAlignment          = Alignment.centerRight,
    this.progressHidesIcon          = true,

    this.hint,
    this.semanticsValue,
  }) : super(key: key);

  Color? get defaultBackgroundColor => Styles().colors.textLight;
  Color? get displayBackgroundColor => backgroundColor ?? defaultBackgroundColor;

  EdgeInsetsGeometry get displayPadding => padding ?? (hasDescription ? complexPadding : simplePadding);
  EdgeInsetsGeometry get simplePadding => const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  EdgeInsetsGeometry get complexPadding => const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

  Color? get defaultTextColor => Styles().colors.textPrimary;
  Color? get displayTextColor => textColor ?? defaultTextColor;
  String? get defaultFontFamily => Styles().fontFamilies.bold;
  String? get displayFontFamily => fontFamily ?? defaultFontFamily;
  TextStyle get displayTextStyle => textStyle ?? TextStyle(fontFamily: displayFontFamily, fontSize: fontSize, color: displayTextColor);
  Widget get displayTextWidget => textWidget ?? Text(label ?? '', style: displayTextStyle, textAlign: textAlign,);

  bool get hasDescription => StringUtils.isNotEmpty(description) || (descriptionWidget != null);
  Color? get defaultDescriptionTextColor => Styles().colors.textLight;
  Color? get displayDescriptionTextColor => descriptionTextColor ?? defaultDescriptionTextColor;
  String? get defaultDescriptionFontFamily => Styles().fontFamilies.regular;
  String? get displayDescriptionFontFamily => descriptionFontFamily ?? defaultDescriptionFontFamily;
  TextStyle get displayDescriptionTextStyle => descriptionTextStyle ?? TextStyle(fontFamily: displayDescriptionFontFamily, fontSize: fontSize, color: displayDescriptionTextColor);
  Widget get displayDescriptionWidget => descriptionWidget ?? Text(description ?? '', style: displayDescriptionTextStyle, textAlign: descriptionTextAlign,);

  Widget? get leftIconImage => (leftIconKey != null) ? Styles().images.getImage(leftIconKey, excludeFromSemantics: true) : null;
  Widget? get rightIconImage => (rightIconKey != null) ? Styles().images.getImage(rightIconKey, excludeFromSemantics: true) : null;

  Color? get defaultProgressColor => Styles().colors.fillColorSecondary;
  Color? get displayProgressColor => progressColor ?? defaultProgressColor;
  double get defaultStrokeWidth => 2.0;
  double get displayProgressStrokeWidth => progressStrokeWidth ?? defaultStrokeWidth;

  bool get progressHidesLeftIcon => (progress == true) && (progressHidesIcon == true) && (progressAlignment == Alignment.centerLeft);
  bool get progressHidesRightIcon => (progress == true) && (progressHidesIcon == true) && (progressAlignment == Alignment.centerRight);

  @override
  _AngledRibbonButtonState createState() => _AngledRibbonButtonState();

  @protected
  void onTapWidget(BuildContext context) {
    if (onTap != null) {
      onTap!();
    }
  }
}

class _AngledRibbonButtonState extends State<AngledRibbonButton> {

  final GlobalKey _contentKey = GlobalKey();
  Size? _contentSize;

  double get _progressSize => widget.progressSize ?? ((_contentSize?.height ?? 0) / 2.5);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evalContentSize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return (widget.progress == true)
        ? Stack(children: [ _contentWidget, _progressWidget, ],)
        : _contentWidget;
  }

  Widget get _contentWidget {
    Widget? leftIconWidget = !widget.progressHidesLeftIcon ? (widget.leftIcon ?? widget.leftIconImage) : null;
    Widget? rightIconWidget = !widget.progressHidesRightIcon ? (widget.rightIcon ?? widget.rightIconImage) : null;
    Widget textContentWidget = widget.hasDescription ?
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      widget.displayTextWidget,
      widget.displayDescriptionWidget,
    ],) : widget.displayTextWidget;
    return Material(color: Colors.transparent,
      child: Semantics(label: widget.label, hint: widget.hint, value : widget.semanticsValue, button: true, excludeSemantics: true, child:
        InkWell(onTap: () => widget.onTapWidget(context), child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            CustomPaint(painter: TrianglePainter(painterColor: widget.displayBackgroundColor, horzDir: TriangleHorzDirection.leftToRight, vertDir: TriangleVertDirection.topToBottom), child:
              Container(height: _contentSize?.height, width: (_contentSize?.width ?? MediaQuery.sizeOf(context).width) * widget.triangleWidthFraction),
            ),
            Expanded(child:
              Container(key: _contentKey, decoration: BoxDecoration(color: widget.displayBackgroundColor, border: widget.border, borderRadius: widget.borderRadius, boxShadow: widget.borderShadow), child:
                Padding(padding: widget.displayPadding, child:
                  Row(children: <Widget>[
                    (leftIconWidget != null) ? Padding(padding: widget.leftIconPadding, child: leftIconWidget) : Container(),
                    Expanded(child:
                      textContentWidget
                    ),
                    (rightIconWidget != null) ? Padding(padding: widget.rightIconPadding, child: rightIconWidget) : Container(),
                  ],),
                ),
              )
            ),
            CustomPaint(painter: TrianglePainter(painterColor: widget.displayBackgroundColor, vertDir: TriangleVertDirection.bottomToTop), child:
              Container(height: _contentSize?.height, width: (_contentSize?.width ?? MediaQuery.sizeOf(context).width) * widget.triangleWidthFraction),
            ),
          ],),
        ),
      ),
    );
  }

  Widget get _progressWidget {
    return (_contentSize != null) ? SizedBox(width: _contentSize!.width, height: _contentSize!.height, child:
      Padding(padding: widget.progressPadding, child:
        Align(alignment: widget.progressAlignment, child:
          SizedBox(height: _progressSize, width: _progressSize, child:
            CircularProgressIndicator(strokeWidth: widget.displayProgressStrokeWidth, valueColor: AlwaysStoppedAnimation<Color?>(widget.displayProgressColor), )
          ),
        ),
      ),
    ) : Container();
  }

  void _evalContentSize() {
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
      debugPrint(e.toString());
    }
  }
}