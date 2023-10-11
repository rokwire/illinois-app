import 'package:flutter/material.dart';


class BackGestureDetector extends StatelessWidget {
  final void Function()? onBack;
  final Widget child;
  final int swipeSensitivity = 24;
  BackGestureDetector({Key? key, required this.child, this.onBack}) : super(key: key);
  
  @override
  Widget build(BuildContext context) => GestureDetector(
    onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(context, details),
    child: child
  );

  void _onHorizontalDragUpdate(BuildContext context, DragUpdateDetails details) {
    //debugPrint("onHorizontalDragUpdate: ${details.delta.dx}");
    if (details.delta.dx > swipeSensitivity) {
      if (onBack != null) {
        onBack!();
      }
      else {
        Navigator.of(context).pop();
      }
    }
  }
} 