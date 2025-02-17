
import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'GestureDetector.dart';

// The reason of this wrapper is that PopScope does not work as documented in iOS:
// https://github.com/flutter/flutter/issues/138624

class PopScopeFix extends StatelessWidget {

  final Widget child;
  final void Function()? onBack;
  final void Function()? onClose;

  const PopScopeFix({super.key, required this.child, this.onBack, this.onClose});

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (bool didPop, Object? result) => _onPopInvoked(context, didPop),
    child: Platform.isIOS ? PopGestureDetector(
      onBack: () => _onBack(context),
      onClose: () => _onClose(context),
      child: child,
    ) : child,
    );

  void _onPopInvoked(BuildContext context, bool didPop) {
    if (!didPop) {
      if (onBack != null) {
        _onBack(context);
      }
      if (onClose != null) {
        _onClose(context);
      }
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

  void _onClose(BuildContext context) {
    if (onClose != null) {
      onClose?.call();
    }
    else {
      Navigator.of(context).pop();
    }
  }
}