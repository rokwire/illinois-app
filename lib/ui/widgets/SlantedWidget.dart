import 'package:flutter/material.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';

class SlantedWidget extends StatefulWidget {
  final Color? color;
  final double triangleWidthFraction;
  final Widget child;

  const SlantedWidget({Key? key,
    this.color,
    this.triangleWidthFraction = 1/20,
    required this.child,
  }) : super(key: key);

  @override
  _SlantedWidgetState createState() => _SlantedWidgetState();
}

class _SlantedWidgetState extends State<SlantedWidget> {
  GlobalKey _contentKey = GlobalKey();
  Size? _contentSize;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evalContentSize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      CustomPaint(painter: TrianglePainter(painterColor: widget.color, horzDir: TriangleHorzDirection.leftToRight), child:
        Container(height: _contentSize?.height, width: (_contentSize?.width ?? MediaQuery.sizeOf(context).width) * widget.triangleWidthFraction),
      ),
      Expanded(key: _contentKey, child: widget.child,),
      CustomPaint(painter: TrianglePainter(painterColor: widget.color, vertDir: TriangleVertDirection.bottomToTop), child:
        Container(height: _contentSize?.height, width: (_contentSize?.width ?? MediaQuery.sizeOf(context).width) * widget.triangleWidthFraction),
      ),
    ],);
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