
import 'package:flutter/cupertino.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/styles.dart';

class AccentCard extends StatelessWidget {

  final CardDisplayMode displayMode;
  final Color? accentColor;
  final Widget? child;

  AccentCard({super.key, required this.displayMode, this.accentColor, this.child });

  @override
  Widget build(BuildContext context) {
    switch (displayMode) {
      case CardDisplayMode.home: return _homeDisplayWidget;
      case CardDisplayMode.browse: return _browseDisplayWidget;
    }
  }

  Widget get _homeDisplayWidget =>
    Container(decoration: HomeCard.defaultDecoration, margin: EdgeInsets.only(bottom: HomeCard.defaultShadowBlurRadius, ), child:
      Column(children: <Widget>[
        Container(height: defaultHeaderHeight(displayMode), decoration: defaultHeaderDecoration(accentColor),),
        child ?? Container()
      ]),
    );

  Widget get _browseDisplayWidget =>
    Column(children: <Widget>[
      Container(height: defaultHeaderHeight(displayMode), color: accentColor,),
      Container(decoration: defaultBrowseDecoration, child: child),
    ]);

  // Header Widget & Decoration

  static double defaultHeaderHeight(CardDisplayMode displayMode) {
    switch (displayMode) {
      case CardDisplayMode.home: return defaultHomeHeaderHeight;
      case CardDisplayMode.browse: return defaultBrowseHeaderHeight;
    }
  }
  static const double defaultHomeHeaderHeight = 8;
  static const double defaultBrowseHeaderHeight = 4;

  static BoxDecoration defaultHeaderDecoration(Color? accentColor) => BoxDecoration(
    color: accentColor,
    borderRadius: BorderRadius.only(
        topLeft: HomeCard.defaultRadius,
        topRight: HomeCard.defaultRadius,
    ),
  );

  // Browse Decoration

  static BoxDecoration get defaultBrowseDecoration => BoxDecoration(
    color: HomeCard.defaultBackColor,
    border: defaultBrowseBorder,
    borderRadius: defaultBorderRadius,
  );

  static Border get defaultBrowseBorder => Border(left: defaultBrowseBorderSize, right: defaultBrowseBorderSize, bottom: defaultBrowseBorderSize);
  static BorderSide get defaultBrowseBorderSize => BorderSide(color: defaultBrowseBorderColor, width: 1);
  static Color get defaultBrowseBorderColor => Styles().colors.surfaceAccent;

  static const BorderRadius defaultBorderRadius = const BorderRadius.vertical(bottom: defaultRadius);
  static const Radius defaultRadius = const Radius.circular(4);
}
