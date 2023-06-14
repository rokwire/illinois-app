
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';

class Onboarding2ResearchQuestionnaireAcknowledgementPanel extends StatelessWidget {

  final Map<String, dynamic>? onboardingContext;
  Onboarding2ResearchQuestionnaireAcknowledgementPanel({this.onboardingContext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors?.background,
      body: Stack(children: [
        Column(children: [
          Container(color: Styles().colors?.white, height: 90,),
          CustomPaint(painter: TrianglePainter(painterColor: Styles().colors?.white, vertDir: TriangleVertDirection.bottomToTop, horzDir: TriangleHorzDirection.leftToRight), child:
            Container(height: 70,),
          ),
        ],),
        Styles().images?.getImage("header-questionnaire", fit: BoxFit.fitWidth, width: MediaQuery.of(context).size.width, excludeFromSemantics: true) ?? Container(),
        Padding(padding: EdgeInsets.only(top: 90), child:
          Align(alignment: Alignment.topCenter, child: 
            Styles().images?.getImage('questionnaire', excludeFromSemantics: true),
          ),
        ),
        Positioned.fill(child:
          SafeArea(child:
            _buildContent(context)
          ),
        ),
        SafeArea(child: 
          OnboardingBackButton(padding: const EdgeInsets.only(left: 10, top: 30, right: 20, bottom: 20), onTap: () => _onBack(context)),
        ),
      ]),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: 
      Column(children: [
        Expanded(child: 
          Padding(padding: EdgeInsets.only(top: 148), child:
            SingleChildScrollView(child:
              Padding(padding: EdgeInsets.symmetric(vertical: 32), child:
                Text(Localization().getStringEx('panel.onboarding2.research.questionnaire.acknowledgement.title', 'Thank you! We will notify you when you become eligible for any upcoming research projects.'), textAlign: TextAlign.center,
                  style: Styles().textStyles?.getTextStyle("widget.message.large.fat"),
                ),
              ),
            ),
          ),
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: 24), child:
          RoundedButton(
            label: Localization().getStringEx('dialog.OK.title', 'OK'),
            textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat"),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Styles().colors!.white,
            borderColor: Styles().colors!.fillColorSecondaryVariant,
            onTap: () => _onContinue(context),
          ),
        )
    ],),
    );
  }

  void _onBack(BuildContext context) {
    Analytics().logSelect(target: "Back");
    Navigator.pop(context);
  }

  void _onContinue(BuildContext context) {
    Analytics().logSelect(target: "Continue");
    Function? onContinue = (onboardingContext != null) ? onboardingContext!["onContinueAction"] : null;
    if (onContinue != null) {
      onContinue();
    }
  }
}