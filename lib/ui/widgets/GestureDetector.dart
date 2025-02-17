import 'package:flutter/material.dart';


class PopGestureDetector extends StatelessWidget {
  final int swipeSensitivityDx = 24;
  final int swipeSensitivityDy = 24;
  final int swipeSensitivityMs = 300;

  final Widget child;
  final void Function()? onBack;
  final void Function()? onClose;

  static int _lastDetectedTimeX = 0;
  static int _lastDetectedTimeY = 0;

  PopGestureDetector({Key? key, required this.child, this.onBack, this.onClose}) : super(key: key);
  
  @override
  Widget build(BuildContext context) => GestureDetector(
    onHorizontalDragUpdate: (onBack != null) ? (details) => _onHorizontalDragUpdate(context, details) : null,
    onVerticalDragUpdate: (onClose != null) ? (details) => _onVerticalDragUpdate(context, details) : null,
    child: child
  );

  void _onHorizontalDragUpdate(BuildContext context, DragUpdateDetails details) {
    int detectionTime = DateTime.now().millisecondsSinceEpoch;
    //debugPrint("onHorizontalDragUpdate dy=${details.delta.dx}, time=$detectionTime");
    if ((details.delta.dx > swipeSensitivityDx) && ((detectionTime - _lastDetectedTimeX) > swipeSensitivityMs)) {
      _lastDetectedTimeX = detectionTime;
      onBack?.call();
    }
  }

  void _onVerticalDragUpdate(BuildContext context, DragUpdateDetails details) {
    int detectionTime = DateTime.now().millisecondsSinceEpoch;
    //debugPrint("onVerticalDragUpdate dy=${details.delta.dy}, time=$detectionTime");
    if ((details.delta.dy > swipeSensitivityDy) && ((detectionTime - _lastDetectedTimeY) > swipeSensitivityMs)) {
      _lastDetectedTimeY = detectionTime;
      onClose?.call();
    }
  }
}
