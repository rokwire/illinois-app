
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:illinois/utils/AppUtils.dart';

class Onboarding2TitleWidget extends StatelessWidget{
  final String? title;

  const Onboarding2TitleWidget({Key? key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color? backColor = Styles().colors!.fillColorSecondary;
    Color? leftTriangleColor = Styles().colors!.background;
    Color? rightTriangleColor = UiColors.fromHex("cc3e1e");

    return Container(child:
      Container(color: backColor, child:
        Stack(alignment: Alignment.bottomCenter, children: <Widget>[
          SafeArea(child:
            Column(children: [
              Container(height: 31,),
              Styles().images?.getImage("university-logo-dark", excludeFromSemantics: true) ?? Container(),
              Container(height: 17,),
              Row(children: <Widget>[
                Container(width: 32,),
                Expanded(child:
                  Text(title!, textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle("panel.onboarding2.heading.title"),),
                ),
                Container(width: 32,),
              ]),
              Container(height: 90,),
            ],),
          ),
          CustomPaint(painter: TrianglePainter(painterColor: rightTriangleColor, horzDir: TriangleHorzDirection.leftToRight), child:
            Container(height: 48,),
          ),
          CustomPaint(painter: TrianglePainter(painterColor: leftTriangleColor), child:
            Container(height: 64,),
          ),
        ],),
      ),
    );
  }
}

class Onboarding2BackButton extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final GestureTapCallback? onTap;
  final String imageKey;
  final Color? color;

  Onboarding2BackButton({this.padding, this.onTap, this.imageKey = 'chevron-left-bold', this.color});

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
            padding: padding!,
            child: Container(child: Styles().images?.getImage(imageKey, color: this.color, excludeFromSemantics: true)
            ),
          ),
        )
    );
  }
}

class Onboarding2ToggleButton extends StatelessWidget{
  final String? toggledTitle;
  final String? unToggledTitle;
  final bool? toggled;
  final Function? onTap;
  final BuildContext? context;//Required in order to announce the VO status change
  final EdgeInsets padding;

  const Onboarding2ToggleButton({Key? key, this.toggledTitle, this.unToggledTitle, this.toggled, this.onTap, this.context, this.padding = const EdgeInsets.all(0)}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return
      Semantics(
          label: _label,
          value: (toggled!
              ? Localization().getStringEx(
            "toggle_button.status.checked",
            "checked",)
              : Localization().getStringEx("toggle_button.status.unchecked", "unchecked")) +
              ", " +
              Localization().getStringEx("toggle_button.status.checkbox", "checkbox"),
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () { onTap!(); anaunceChange(); },
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[ Expanded(
                child: Container(
                  padding: padding,
                  decoration: BoxDecoration(color: Styles().colors!.background, border:Border(top: BorderSide(width: 2, color: Styles().colors!.surfaceAccent!)),),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child:  Row(
                      children: <Widget>[
                        Expanded(child:
                        Text(_label!,
                          style: Styles().textStyles?.getTextStyle("widget.button.description.small")
                        )
                        ),
                        Padding(padding: EdgeInsets.only(left: 7), child: _image),
                      ],
                    ),
                  ),
                )
            ),],),
          ));
  }

  void anaunceChange() {
    AppSemantics.announceCheckBoxStateChange(context, !toggled!, !toggled!? toggledTitle: unToggledTitle); // !toggled because we announce before the state got updated
  }

  String? get _label{
    return toggled!? toggledTitle : unToggledTitle;
  }

  Widget? get _image{
    return Styles().images?.getImage(toggled! ? 'toggle-on' : 'toggle-off', excludeFromSemantics: true);
  }
}

class Onboarding2InfoDialog extends StatelessWidget{
  static final TextStyle titleStyle = Styles().textStyles?.getTextStyle("widget.title.large.fat") ?? TextStyle(fontSize: 20.0, color: Styles().colors!.fillColorPrimary,fontFamily: Styles().fontFamilies!.bold);
  static final TextStyle contentStyle = Styles().textStyles?.getTextStyle("widget.info.regular.thin") ?? TextStyle(fontSize: 16.0, color: Styles().colors!.textSurface, fontFamily: Styles().fontFamilies!.regular);

  final Widget? content;
  final BuildContext? context;

  static void show({required BuildContext context, Widget? content}){
    showDialog(
        context: context,
        builder: (_) => Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
          child: Onboarding2InfoDialog(content: content, context: context),
        )
    );
  }

  const Onboarding2InfoDialog({Key? key, this.content, this.context}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
        builder: (context, setState) {
          return ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              child: Dialog(
                backgroundColor: Styles().colors!.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Semantics(label: Localization().getStringEx(
                              "dialog.close.title", "Close"), button: true, child:
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(child: Styles().images?.getImage("close", excludeFromSemantics: true)),
                          ))),
                        Container(height: 12,),
                        content ?? Container(),
                        Container(height:10),
//                        RichText(
//                            textScaleFactor: MediaQuery.textScaleFactorOf(context),
//                            text: new TextSpan(
//                                children: <TextSpan>[
//                                  TextSpan(text: Localization().getStringEx("panel.onboarding2.dialog.learn_more.collected_information_disclosure", "All of this information is collected and used in accordance with our "), style: Onboarding2InfoDialog.contentStyle,),
//                                  TextSpan(text:Localization().getStringEx("panel.onboarding2.dialog.learn_more.button.privacy_policy.title", "Privacy Policy "), style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 14, decoration: TextDecoration.underline, decorationColor: Styles().colors.fillColorSecondary),
//                                      recognizer: TapGestureRecognizer()..onTap = _openPrivacyPolicy, children: [
//                                        WidgetSpan(child: Container(padding: EdgeInsets.only(bottom: 4), child: Image.asset("images/icon-external-link-blue.png", excludeFromSemantics: true,)))
//                                      ]),
//                                ]
//                            )
//                        ),

                        RichText(
                            textScaleFactor: MediaQuery.textScaleFactorOf(context),
                            text: new TextSpan(
                                children:[
                                  TextSpan(text: Localization().getStringEx("panel.onboarding2.dialog.learn_more.collected_information_disclosure", "All of this information is collected and used in accordance with our "), style: Onboarding2InfoDialog.contentStyle,),
                                  WidgetSpan(child: Onboarding2UnderlinedButton(title: Localization().getStringEx("panel.onboarding2.dialog.learn_more.button.privacy_policy.title", "Privacy notice "), onTap: () => _openPrivacyPolicy(context), padding: EdgeInsets.all(0), textStyle: Styles().textStyles?.getTextStyle("widget.button.title.small.underline"))),
                                  WidgetSpan(child: Container(
                                      decoration: BoxDecoration(
                                          border: Border(bottom: BorderSide(color: Styles().colors!.fillColorSecondary!, width: 1, ),)
                                      ),
                                      padding: EdgeInsets.only(bottom: 2),
                                      child: Container(
                                          padding: EdgeInsets.only(bottom: 4),
                                          child: Styles().images?.getImage("external-link", excludeFromSemantics: true,)))),
                                ]
                            )
                        ),
                        Container(height:36)
                      ],
                    )
                  )
                ),
              )
          );
        }
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    Analytics().logSelect(target: "Privacy Policy");
    AppPrivacyPolicy.launch(context);
  }
}

class Onboarding2UnderlinedButton extends StatelessWidget{ //TBD check if we can replace with UnderlineButton
  final Function? onTap;
  final String? title;
  final String? hint;
  final TextStyle? textStyle;
  final EdgeInsets padding;

  const Onboarding2UnderlinedButton({Key? key, this.onTap, this.title, this.hint, this.padding = const EdgeInsets.symmetric(vertical: 20), this.textStyle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  GestureDetector(
      onTap: () {
        onTap!();
      },
      child: Semantics(
          label: title,
          hint: hint,
          button: true,
          excludeSemantics: true,
          child: Padding(
              padding: padding,
              child: Container(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text(
                    title!,
                    style: textStyle ?? defaultTextStyle
                  )))),
    );
  }

  TextStyle? get defaultTextStyle => Styles().textStyles?.getTextStyle("widget.button.title.medium.underline");

}