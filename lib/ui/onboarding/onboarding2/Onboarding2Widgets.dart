
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:illinois/utils/Utils.dart';

class Onboarding2TitleWidget extends StatelessWidget{
  final String title;

  const Onboarding2TitleWidget({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backColor = Styles().colors.fillColorSecondary;
    Color leftTriangleColor = Styles().colors.background;
    Color rightTriangleColor = UiColors.fromHex("cc3e1e");

    return Container(
      child: Container(
        color: backColor ,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            Container(
              child: Column(
                children: [
                  Container(height: 31,),
                  Image.asset("images/illinois-blockI-blue.png", excludeFromSemantics: true, width: 24, fit: BoxFit.fitWidth,),
                  Container(height: 17,),
                  Row(
                    children: <Widget>[
                      Container(width: 32,),
                      Expanded(child:
                        Text(title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: Styles().fontFamilies.bold,
                            fontSize: 32,
                            color: Styles().colors.white,
                            letterSpacing: 1),
                        ),
                      ),
                      Container(width: 32,),
                    ]),
                  Container(height: 90,),
              ],),
            ),
            CustomPaint(
              painter: TrianglePainter(painterColor: rightTriangleColor, left: false),
              child: Container(
                height: 48,
              ),
            ),
            CustomPaint(
              painter: TrianglePainter(painterColor: leftTriangleColor),
              child: Container(
                height: 64,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Onboarding2BackButton extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final GestureTapCallback onTap;
  final String image;
  final Color color;

  Onboarding2BackButton({this.padding, this.onTap, this.image = 'images/chevron-left-gray.png', this.color});

  @override
  Widget build(BuildContext context) {
    return Semantics(
        label: Localization().getStringEx('headerbar.back.title', 'Back'),
        hint: Localization().getStringEx('headerbar.back.hint', ''),
        button: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: padding,
            child: Container(
                height: 32,
                width: 32,
                child: Image.asset(image, color: this.color ?? Styles().colors.fillColorSecondary,)
            ),
          ),
        )
    );
  }
}

class Onboarding2ToggleButton extends StatelessWidget{
  final String toggledTitle;
  final String unToggledTitle;
  final bool toggled;
  final Function onTap;
  final BuildContext context;//Required in order to announce the VO status change
  final EdgeInsets padding;

  const Onboarding2ToggleButton({Key key, this.toggledTitle, this.unToggledTitle, this.toggled, this.onTap, this.context, this.padding = const EdgeInsets.all(0)}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { onTap(); anaunceChange(); },
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[ Expanded(
          child: Container(
            padding: padding,
            decoration: BoxDecoration(color: Styles().colors.background, border:Border(top: BorderSide(width: 2, color: Styles().colors.surfaceAccent)),),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child:  Row(
                children: <Widget>[
                  Expanded(child:
                  Text(_label,
                    style: TextStyle(color: Styles().colors.textSurface, fontSize: 14, fontFamily: Styles().fontFamilies.regular),
                  )
                  ),
                  (_image != null) ? Padding(padding: EdgeInsets.only(left: 7), child: _image) : Container(),
                ],
              ),
            ),
          )
      ),],),
    );
  }

  void anaunceChange() {
    AppSemantics.announceCheckBoxStateChange(context, !toggled, _label); // !toggled because we announce before the state got updated
  }

  String get _label{
    return toggled? toggledTitle : unToggledTitle;
  }

  Widget get _image{
    return Image.asset( toggled ? 'images/toggle-yes.png' : 'images/toggle-no.png');
  }
}