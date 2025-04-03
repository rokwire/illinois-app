
import 'package:flutter/material.dart';
import 'package:illinois/ui/wallet/WalletPhotoWrapperWidget.dart';

class WalletLibraryCardWidget extends StatefulWidget {
  final double topOffset;

  WalletLibraryCardWidget({super.key, this.topOffset = 0});

  State<StatefulWidget> createState() => _WalletLibraryCardWidgetState();
}

class _WalletLibraryCardWidgetState extends State<WalletLibraryCardWidget> {
  @override
  Widget build(BuildContext context) {
    return WalletPhotoWrapperWidget(topOffset: widget.topOffset,);
  }
}
