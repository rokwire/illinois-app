
import 'package:flutter/material.dart';
import 'package:illinois/ui/wallet/WalletPhotoWrapper.dart';

class WalletLibraryCardPage extends StatefulWidget {
  final double topOffset;
  WalletLibraryCardPage({super.key, this.topOffset = 0});

  State<StatefulWidget> createState() => _WalletLibraryCardPageState();
}

class _WalletLibraryCardPageState extends State<WalletLibraryCardPage> {
  @override
  Widget build(BuildContext context) {
    return WalletPhotoWrapper(topOffset: widget.topOffset,);
  }
}
