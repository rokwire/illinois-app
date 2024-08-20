
import 'package:universal_io/io.dart';

import 'package:flutter/cupertino.dart';

import 'GestureDetector.dart';

// The reason of this wrapper is that PopScope does not work as documented in iOS:
// https://github.com/flutter/flutter/issues/138624

class PopScopeFix extends StatelessWidget {

  final Widget child;
  final void Function()? onBack;

  const PopScopeFix({super.key, required this.child, this.onBack});

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (bool didPop, Object? result) => _onPopInvoked(context, didPop),
    child: Platform.isIOS ?
      BackGestureDetector(onBack: () => _onBack(context), child: child,) :
      child,
    );

  void _onPopInvoked(BuildContext context, bool didPop) {
    if (!didPop) {
      _onBack(context);
    }
  }

  void _onBack(BuildContext context) {
    if (onBack != null) {
      onBack?.call();
    }
    else {
      Navigator.of(context).pop();
    }
  }
}