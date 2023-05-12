

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/styles.dart';

class HomeTBDWidget extends StatelessWidget {
  final String? title;
  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeTBDWidget({Key? key, this.title, this.favoriteId, this.updateController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: favoriteId,
      title: title,
      titleIconKey: 'campus-tools',
      //flatHeight: 0, slantHeight: 0, childPadding: EdgeInsets.all(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: Styles().colors!.surface, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))] ),
        child: Column(children: <Widget>[
          Row(children: <Widget>[
            Expanded(child:
              Text('TBD', style: Styles().textStyles?.getTextStyle("widget.message.large.fat"), semanticsLabel: "",)
            )
          ]),
          Row(children: <Widget>[
            Expanded(child:
              Text('Comming soon...', style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"), semanticsLabel: "",)
            )
          ]),
        ]),
      )
    );
  }
}