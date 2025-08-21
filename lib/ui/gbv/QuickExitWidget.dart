import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/InfoPopup.dart';

class QuickExitWidget extends StatelessWidget {

  QuickExitWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(padding: EdgeInsets.all(16), child:
    Row(crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(padding: EdgeInsets.only(right: 8), child:
        GestureDetector(onTap: () => onQuickExitInfo(context), child:
        Styles().images.getImage('info', excludeFromSemantics: true) ?? Container(),
        )
        ),
        Expanded(child:
        RichText(text:
        TextSpan(children: [
          TextSpan(text: Localization().getStringEx('', 'Privacy: '),
              style: Styles().textStyles.getTextStyle('widget.item.small.fat')),
          TextSpan(text: Localization().getStringEx('', 'your app activity is not shared with others.'),
              style: Styles().textStyles.getTextStyle('widget.item.small.thin')),
        ])
        )
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
        GestureDetector(onTap: () => _onQuickExit(context), child:
            quickExitIcon
        )
      ],
    )
    );
  }

  Widget get quickExitIcon =>
    Container(height: 50, width: 50, decoration: BoxDecoration(
    color: Styles().colors.white,
    border: Border.all(color: Colors.grey),
    borderRadius: BorderRadius.circular(40),
    boxShadow: [
    BoxShadow(
    color: Colors.black26,
    blurRadius: 10.0,
    ),
    ]), child:
    Styles().images.getImage('person-to-door', excludeFromSemantics: true, width: 25) ?? Container()
  );

  void onQuickExitInfo(BuildContext context) {
    showDialog(context: context, builder: (_) => InfoPopup(
      backColor: Styles().colors.surface,
      padding: EdgeInsets.only(left: 32, right: 32, top: 40, bottom: 32),
      alignment: Alignment.center,
      infoTextWidget: Column(children: [
        Container(height: 50, width: 50, decoration: BoxDecoration(
            color: Styles().colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
              ),
            ]), child:
        Styles().images.getImage('person-to-door', excludeFromSemantics: true, width: 25) ?? Container()
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: 8)),
        Text(Localization().getStringEx('', 'Use the quick exit icon at any time to be routed to the Illinois app home screen.'),
          style: Styles().textStyles.getTextStyle('widget.description.regular'), textAlign: TextAlign.left,
        )
      ]
      ),
      closeIcon: Styles().images.getImage('close-circle', excludeFromSemantics: true),
    ),);
  }

  void _onQuickExit(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
