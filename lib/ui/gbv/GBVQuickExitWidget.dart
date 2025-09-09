import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/InfoPopup.dart';
import 'package:illinois/ui/home/HomeFavoritesPanel.dart';
import 'package:illinois/service/Analytics.dart';

import '../RootPanel.dart';
import '../home/HomePanel.dart';

class GBVQuickExitWidget extends StatelessWidget {

  GBVQuickExitWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(padding: EdgeInsets.all(16), child:
    Row(crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(padding: EdgeInsets.only(right: 8), child:
        GestureDetector(onTap: () => _onQuickExitInfo(context), child:
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
            _quickExitIcon
        )
      ],
    )
    );
  }

  Widget quickExitButton(BuildContext context) => GestureDetector(onTap: () => _onQuickExit(context), child: _quickExitIcon);

  Widget get _quickExitIcon =>
    GBVQuickExitIcon();

  void _onQuickExitInfo(BuildContext context) {
    showDialog(context: context, builder: (_) => InfoPopup(
      backColor: Styles().colors.surface,
      padding: EdgeInsets.only(left: 32, right: 32, top: 40, bottom: 32),
      alignment: Alignment.center,
      infoTextWidget: Column(children: [
        GBVQuickExitIcon(),
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
    Analytics().logSelect(target: 'Quick Exit button');
    Navigator.of(context).popUntil((route) => route.isFirst);
    NotificationService().notify(HomeFavoritesPanel.notifySelect);
  }
}

class GBVQuickExitIcon extends StatelessWidget {
  final double size;
  GBVQuickExitIcon({super.key, this.size = 50 });

  @override
  Widget build(BuildContext context) =>
    Container(height: size, width: size,
      decoration: BoxDecoration(
        color: Styles().colors.white,
        border: Border.all(color: Styles().colors.lightGray),
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [BoxShadow(
          color: Colors.black26,
          blurRadius: 5.0,
          offset: Offset(2, 2)
        ),]
      ),
      child: Center(child:
        Styles().images.getImage('person-to-door', excludeFromSemantics: true, width: size / 2) ?? Container()
      )
    );
}
