
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:illinois/service/Styles.dart';

typedef void OnWidgetSizeChange(Size size);

class MeasureSize extends StatefulWidget {
  final Widget child;
  final OnWidgetSizeChange onChange;

  const MeasureSize({
    Key key,
    @required this.onChange,
    @required this.child,
  }) : super(key: key);

  @override
  _MeasureSizeState createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback(postFrameCallback);
    return Container(
      key: widgetKey,
      child: widget.child,
    );
  }

  var widgetKey = GlobalKey();
  var oldSize;

  void postFrameCallback(_) {
    var context = widgetKey.currentContext;
    if (context == null) return;

    var newSize = context.size;
    if (oldSize == newSize) return;

    oldSize = newSize;
    widget.onChange(newSize);
  }
}

class ScalableScrollView extends StatefulWidget{
  final Widget bottomNotScrollableWidget;
  final Widget scrollableChild;

  const ScalableScrollView({Key key, this.bottomNotScrollableWidget, this.scrollableChild}) : super(key: key);

  @override
  _ScalableScrollViewState createState() => _ScalableScrollViewState();
}

class _ScalableScrollViewState extends State<ScalableScrollView>{
  Size _bottomWidgetSize;
  Size _scrollableChildSize;

  @override
  Widget build(BuildContext context) {
    bool needScroll = _scrollableChildSize!=null && _bottomWidgetSize!=null ? (_scrollableChildSize.height + _bottomWidgetSize.height > MediaQuery.of(context).size.height): false;
    double scrollableHeight = MediaQuery.of(context).size.height  - (_bottomWidgetSize?.height??0);
    int bottomWidgetFlex = (_bottomWidgetSize?.height ?? 0) > 1? (_bottomWidgetSize?.height??1).round() : 0;
    int scrollableWidgetFlex = scrollableHeight > 0? (scrollableHeight?.round()??1) : 0;
    return Container(
        child:Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            needScroll?
            Flexible(
                flex: scrollableWidgetFlex,
                child: SingleChildScrollView(
                  child: _buildScrollContent(),
                )
            ) : _buildScrollContent(),
            needScroll? Container() : Expanded(child: Container(),),
            needScroll?
            Flexible(
                flex: bottomWidgetFlex,
                child: _buildBottomWidget()
            ) : _buildBottomWidget(),
          ],
        )
    );
  }

  Widget _buildScrollContent(){
    return MeasureSize(
        onChange: (Size size){
          if(_scrollableChildSize != size){
            setState(() {
              _scrollableChildSize = size;
            });
          }
        },
        child:widget.scrollableChild ?? Container());
  }

  Widget _buildBottomWidget(){
    return MeasureSize(
        onChange: (Size size){
          if(_bottomWidgetSize!=size) {
            setState(() {
              _bottomWidgetSize = size;
            });
          }
        },
        child:
        Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children:[
              widget.bottomNotScrollableWidget ?? Container()
            ]
        )
    );
  }
}

class ScalableRoundedButton extends StatelessWidget {
  final String label;
  final String hint;
  final Color backgroundColor;
  final Function onTap;
  final Color textColor;
  final TextAlign textAlign;
  final String fontFamily;
  final double fontSize;
  final Color borderColor;
  final double borderWidth;
  final Color secondaryBorderColor;
  final List<BoxShadow> shadow;
  final EdgeInsetsGeometry padding;
  final bool enabled;
  final bool showAdd;
  final bool showChevron;

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
        this.showAdd = false,
        this.showChevron = false
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
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: (backgroundColor ?? Styles().colors.fillColorPrimary),
              border: Border.all(
                  color: (borderColor != null) ? borderColor : (backgroundColor ?? Styles().colors.fillColorPrimary),
                  width: borderWidth),
              borderRadius: borderRadius,
              boxShadow: this.shadow
            ),
            child: Container(
              decoration: BoxDecoration(
                  color: (backgroundColor ?? Styles().colors.fillColorPrimary),
                  border: Border.all(
                      color: (secondaryBorderColor != null)
                          ? secondaryBorderColor
                          : (backgroundColor ?? Styles().colors.fillColorPrimary),
                      width: borderWidth),
                  borderRadius: borderRadius),
              child: Padding(
                  padding: padding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                    Expanded(child:
                    Text(
                      label,
                      textAlign: textAlign,
                      style: TextStyle(
                        fontFamily: fontFamily ?? Styles().fontFamilies.bold,
                        fontSize: fontSize,
                        color: textColor,
                      ),
                    )),
                    Visibility(
                        visible: showChevron,
                        child: Padding(
                          padding: EdgeInsets.only(left: 5),
                          child: Image.asset('images/chevron-right.png'),
                        )),
                    Visibility(
                        visible: showAdd,
                        child: Padding(
                          padding: EdgeInsets.only(left: 5),
                          child: Image.asset('images/icon-add-20x18.png'),
                        ))
                  ],)),
            ),
          ),
        ));
  }
}

class ScalableFilterSelectorWidget extends StatelessWidget {
  final String label;
  final String hint;
  final String labelFontFamily;
  final double labelFontSize;
  final bool active;
  final EdgeInsets padding;
  final bool visible;
  final GestureTapCallback onTap;

  ScalableFilterSelectorWidget(
      {@required this.label,
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
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: labelFontSize, color: (active ? Styles().colors.fillColorSecondary : Styles().colors.fillColorPrimary), fontFamily: labelFontFamily ?? Styles().fontFamilies.bold),
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
