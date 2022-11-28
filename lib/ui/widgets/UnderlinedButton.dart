
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';

class UnderlinedButton extends StatelessWidget {
  final Function? onTap;
  final String? title;
  final String? hint;
  final double fontSize;
  final EdgeInsets padding;
  final String? fontFamily;
  final bool progress;

  const UnderlinedButton(
      {Key? key, this.onTap, this.title, this.hint, this.fontSize = 16, this.padding = const EdgeInsets
          .symmetric(vertical: 20), this.fontFamily, this.progress = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Semantics(
        label: title,
        hint: hint,
        button: true,
        excludeSemantics: true,
        child: GestureDetector(
            onTap: () {
              if (onTap != null) {
                onTap!();
              }
            },
            child: Stack(
              children: [
                Align(alignment: Alignment.center,
                    child:
                    Padding(
                        padding: padding,
                        child: Container(
                            decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(
                                  color: Styles().colors!.fillColorSecondary!,
                                  width: 1,),)
                            ),
                            padding: EdgeInsets.only(bottom: 2),
                            child: Text(
                              title!,
                              style: Styles().textStyles?.getTextStyle("widget.button.title.medium")?.copyWith(fontSize: fontSize, fontFamily: fontFamily ?? Styles().fontFamilies!.medium),
                            )))),
                progress ?
                Align(alignment: Alignment.center,
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary!), )
                ) : Container(),
              ],
            )
        )));
  }
}