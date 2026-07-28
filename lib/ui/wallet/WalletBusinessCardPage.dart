
import 'package:flutter/cupertino.dart';
import 'package:illinois/ui/profile/ProfileBusinessCardPage.dart';
import 'package:illinois/ui/wallet/WalletHomePanel.dart';
import 'package:rokwire_plugin/service/styles.dart';

class WalletBusinessCardPage extends StatelessWidget with WalletHomePage {
  final double topOffset;
  WalletBusinessCardPage({super.key, this.topOffset = 0});

  @override
  Widget build(BuildContext context) =>
    Padding(padding: EdgeInsets.only(top: topOffset, left: 16, right: 16), child:
      ProfileBusinessCardPage()
    );

  @override
  Color get backgroundColor => Styles().colors.background;
}