import 'package:flutter/material.dart';


class BackGestureDetector extends StatelessWidget {
  final int swipeSensitivityDx = 24;
  final int swipeSensitivityMs = 300;

  final Widget child;
  final void Function()? onBack;

  static int _lastDetectedTime = 0;

  BackGestureDetector({Key? key, required this.child, this.onBack}) : super(key: key);
  
  @override
  Widget build(BuildContext context) => GestureDetector(
    onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(context, details),
    child: child
  );

  void _onHorizontalDragUpdate(BuildContext context, DragUpdateDetails details) {
    int detectionTime = DateTime.now().millisecondsSinceEpoch;
    //debugPrint("onHorizontalDragUpdate dy=${details.delta.dx}, time=$detectionTime");
    if ((details.delta.dx > swipeSensitivityDx) && ((detectionTime - _lastDetectedTime) > swipeSensitivityMs)) {
      _lastDetectedTime = detectionTime;
      if (onBack != null) {
        onBack!();
      }
      else {
        Navigator.of(context).pop();
      }
    }
  }
} 