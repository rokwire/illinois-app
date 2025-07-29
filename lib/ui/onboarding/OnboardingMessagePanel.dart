
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';

class OnboardingMessagePanel extends StatelessWidget {
  final String? title;
  final String? message;
  final Widget? footer;

  OnboardingMessagePanel({Key? key, this.title, this.message, this.footer}) :
    super(key: key);

  @override
  Widget build(BuildContext context) =>
    Scaffold(backgroundColor: Styles().colors.background, body:
      Column(children: <Widget>[
        Styles().images.getImage('header-login', fit: BoxFit.fitWidth, width: MediaQuery.of(context).size.width, excludeFromSemantics: true,) ?? Container(),
        Expanded(child:
          SafeArea(child:
            Padding(padding: EdgeInsets.symmetric(horizontal: 42), child:
              Column(children: <Widget>[
                Expanded(flex: 1, child: Container()),

                if (title != null)
                  Text(title ?? '', textAlign: TextAlign.center, style:
                    TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 32, color: Styles().colors.fillColorPrimary),
                  ),

                Expanded(flex: 1, child: Container()),

                if (message != null)
                  Text(message ?? '', textAlign: TextAlign.center, style:
                    TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 20, color: Styles().colors.fillColorPrimary),
                  ),

                Expanded(flex: 3, child: Container()),

                if (footer != null)
                  footer ?? Container(),
              ]),
            )
          )
        )
      ],)
    );
}
