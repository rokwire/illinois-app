
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Questionnaire.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class Onboarding2PromptResearchQuestionnairePanel extends StatelessWidget {

  final Map<String, dynamic>? onboardingContext;
  Onboarding2PromptResearchQuestionnairePanel({this.onboardingContext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors?.background,
      body: Stack(children: [
        Image.asset("images/login-header.png", fit: BoxFit.fitWidth, width: MediaQuery.of(context).size.width, excludeFromSemantics: true, ),
        SafeArea(child:
          _buildContent(context)
        ),
        SafeArea(child: 
          OnboardingBackButton(padding: const EdgeInsets.only(left: 10, top: 30, right: 20, bottom: 20), onTap: () => _onBack(context)),
        ),
      ]),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(padding: EdgeInsets.only(left: 24, right: 24, top: 148), child: 
    Column(children: [
      Expanded(flex: 1, child: Container(),),
      Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 0), child:
        Row(children: [
          Expanded(child: 
            Text(Localization().getStringEx('panel.onboarding2.research.questionnaire.prompt', 'Would you like to participate in Research?'), textAlign: TextAlign.center,
              style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 24, color: Styles().colors?.fillColorPrimary,),
            ),
          )
        ],),
      ),
      Expanded(flex: 4, child: Container(),),
      Padding(padding: EdgeInsets.symmetric(vertical: 24), child:
        Row(children: [
          Expanded(child:
            RoundedButton(
              label: Localization().getStringEx('dialog.yes.title', 'Yes'),
              fontSize: 16,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Styles().colors!.white,
              borderColor: Styles().colors!.fillColorSecondaryVariant,
              textColor: Styles().colors!.fillColorPrimary,
              onTap: () => _onYes(context),
            ),
          ),
          Container(width: 12,),
          Expanded(child:
            RoundedButton(
              label: Localization().getStringEx('dialog.no.title', 'No'),
              fontSize: 16,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Styles().colors!.white,
              borderColor: Styles().colors!.fillColorSecondaryVariant,
              textColor: Styles().colors!.fillColorPrimary,
              onTap: () => _onNo(context),
            ),
          ),
        ],)
      )
    ],),
    );
  }

  void _onBack(BuildContext context) {
    Analytics().logSelect(target: "Back");
    Navigator.pop(context);
  }

  void _onYes(BuildContext context) {
    Analytics().logSelect(target: "Yes");
    Questionnaires().participateInResearch = true;
    Navigator.pop(context, true);
    /*Function? onConfirm = (onboardingContext != null) ? onboardingContext!["onConfirmAction"] : null;
    if (onConfirm != null) {
      onConfirm();
    }*/
  }

  void _onNo(BuildContext context) {
    Analytics().logSelect(target: "No");
    Questionnaires().participateInResearch = false;
    Navigator.pop(context, false);
    /*Function? onReject = (onboardingContext != null) ? onboardingContext!["onRejectAction"] : null;
    if (onReject != null) {
      onReject();
    }*/
  }
}