
import 'package:flutter/cupertino.dart';
import 'package:illinois/ui/profile/ProfileBusinessCardPage.dart';

class WalletBusinessCardPage extends StatelessWidget {
  final double topOffset;
  WalletBusinessCardPage({super.key, this.topOffset = 0});

  @override
  Widget build(BuildContext context) =>
    Padding(padding: EdgeInsets.only(top: topOffset, left: 16, right: 16), child:
      ProfileBusinessCardPage()
    );
}