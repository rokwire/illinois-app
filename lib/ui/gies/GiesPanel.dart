import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/home/HomeGiesWidget.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';

class GiesPanel extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _GiesPanelState();

}

class _GiesPanelState extends State<GiesPanel>{
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx("panel.groups_home.label.heading","Groups")!,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: Styles().fontFamilies!.extraBold,
            letterSpacing: 1.0),
        ),
      ),
      body: SingleChildScrollView(child:
        Column(children: <Widget>[
          HomeGiesWidget()
        ])));
  }

}