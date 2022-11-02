
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Questionnaire.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';

class Onboarding2ResearchQuestionnairePromptPanel extends StatelessWidget {

  final Map<String, dynamic>? onboardingContext;
  Onboarding2ResearchQuestionnairePromptPanel({this.onboardingContext});

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
        Image.asset("images/questionnaire-header.png", fit: BoxFit.fitWidth, width: MediaQuery.of(context).size.width, excludeFromSemantics: true, ),
        Padding(padding: EdgeInsets.only(top: 90), child:
          Align(alignment: Alignment.topCenter, child: 
            Image.asset('images/questionnaire-icon.png'),
          ),
        ),
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
  String notRightNow = Localization().getStringEx('panel.onboarding.base.not_now.title":"Not right now', 'Not right now');
  
  return Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: 
    Column(children: [
      Padding(padding: EdgeInsets.only(top: 180), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: 
              Text(Localization().getStringEx('panel.onboarding2.research.questionnaire.prompt.introduction', 'Illinois is one of the world’s great research universities. Become a citizen scientist and take part in the discovery by participating in research at Illinois.'), textAlign: TextAlign.center,
                style: Styles().textStyles?.getTextStyle("widget.message.large"),
              ),
            )
          ],),
          Container(height: 32,),
          Row(children: [
            Expanded(child:
              RichText(text:
                TextSpan(children: [
                  TextSpan(text: Localization().getStringEx('panel.onboarding2.research.questionnaire.prompt.question', 'Would you like to get invitations to participate in research studies via the Illinois app?'),
                    style: Styles().textStyles?.getTextStyle("widget.message.large.fat"),
                  ),
                  TextSpan(text: Localization().getStringEx('panel.onboarding2.research.questionnaire.prompt.explanation', ' Many studies offer incentives.'),
                    style: Styles().textStyles?.getTextStyle("widget.message.large"),
                  ),
                ]),
                textAlign: TextAlign.center,
              ),
            )
          ],),
        ],),
      ),
      Expanded(child: Container(),),
      Padding(padding: EdgeInsets.only(top: 24), child:
        Column(children: [
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
          ],),
          InkWell(onTap: () => _onNotRightNow(context), child:
            Semantics(button: true, label: notRightNow, hint: Localization().getStringEx('panel.onboarding.base.not_now.hint', ''), excludeSemantics: true, child:
              Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
                Text(notRightNow, style:
                  TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Styles().colors!.fillColorPrimary, decoration: TextDecoration.underline, decorationColor: Styles().colors!.fillColorSecondary, decorationThickness: 1, decorationStyle: TextDecorationStyle.solid),
                ),
              ),
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
    Function? onConfirm = (onboardingContext != null) ? onboardingContext!["onConfirmAction"] : null;
    if (onConfirm != null) {
      onConfirm();
    }
  }

  void _onNo(BuildContext context) {
    Analytics().logSelect(target: "No");
    Questionnaires().participateInResearch = false;
    Function? onReject = (onboardingContext != null) ? onboardingContext!["onRejectAction"] : null;
    if (onReject != null) {
      onReject();
    }
  }

  void _onNotRightNow(BuildContext context) {
    Analytics().logSelect(target: "Not right now");
    Function? onReject = (onboardingContext != null) ? onboardingContext!["onRejectAction"] : null;
    if (onReject != null) {
      onReject();
    }
  }
}