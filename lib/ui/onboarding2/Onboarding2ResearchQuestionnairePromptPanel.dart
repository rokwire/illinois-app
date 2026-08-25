
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/service/Questionnaire.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Onboarding2ResearchQuestionnairePromptPanel extends StatefulWidget with Onboarding2Panel {

  final String onboardingCode;
  final Onboarding2Context? onboardingContext;
  final void Function(BuildContext context, Onboarding2Panel panel, bool? participateInResearch)? onContinue;
  Onboarding2ResearchQuestionnairePromptPanel({ super.key, this.onboardingCode = '', this.onboardingContext, this.onContinue });

  _Onboarding2ResearchQuestionnairePromptPanelState? get _currentState => JsonUtils.cast(globalKey?.currentState);

  @override
  bool get onboardingProgress => (_currentState?.onboardingProgress == true);
  @override
  set onboardingProgress(bool value) => _currentState?.onboardingProgress = value;
  @override
  Future<bool> isOnboardingEnabled() async => Questionnaires().participateInResearch != true;

  @override
  State<StatefulWidget> createState() => _Onboarding2ResearchQuestionnairePromptPanelState();
}

class _Onboarding2ResearchQuestionnairePromptPanelState extends State<Onboarding2ResearchQuestionnairePromptPanel> {

  bool _onboardingProgress = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors.background,
      body: Column(children: [
        Stack(children: [
          Styles().images.getImage("header-login", fit: BoxFit.fitWidth, width: MediaQuery.of(context).size.width, excludeFromSemantics: true) ?? Container(),
          Visibility(visible: Navigator.canPop(context), child:
            Positioned(top: 0, left: 0, child:
              SafeArea(child:
                Onboarding2BackButton(padding: const EdgeInsets.all(16), onTap: () => _onBack(context)),
              ),
            ),
          ),
        ],),
        Expanded(child:
          SafeArea(top: false, child:
            _buildContent(context)
          ),
        ),
      ]),
    );
  }

  Widget _buildContent(BuildContext context) {
  String notRightNow = Localization().getStringEx('panel.onboarding.base.not_now.title":"Not right now', 'Not right now');
  
  return Padding(padding: EdgeInsets.symmetric(horizontal: 24), child:
    Column(children: [
      Expanded(child:
        SingleChildScrollView(child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 24,),
            Center(child:
              FittedBox(fit: BoxFit.scaleDown, child:
                Text(Localization().getStringEx('panel.onboarding2.research.questionnaire.prompt.title', 'Participate in Research'), maxLines: 1, textAlign: TextAlign.center,
                  style: Styles().textStyles.getTextStyle("widget.title.extra_huge.fat"),
                ),
              ),
            ),
            Container(height: 24,),
            Text(Localization().getStringEx('panel.onboarding2.research.questionnaire.prompt.introduction', 'Illinois is one of the world’s great research universities. As a member of the university, you can help scientists answer questions that lead to new discoveries.'), textAlign: TextAlign.center,
              style: Styles().textStyles.getTextStyle("widget.message.regular"),
            ),
            Container(height: 32,),
            RichText(text:
              TextSpan(children: [
                TextSpan(text: Localization().getStringEx('panel.onboarding2.research.questionnaire.prompt.question', 'Would you like to get invitations to become a research participant via the Illinois app?'),
                  style: Styles().textStyles.getTextStyle("widget.message.regular.fat"),
                ),
                TextSpan(text: '\n'),
                TextSpan(text: Localization().getStringEx('panel.onboarding2.research.questionnaire.prompt.explanation', ' Many studies offer incentives.').trim(),
                  style: Styles().textStyles.getTextStyle("widget.message.regular"),
                ),
              ]),
              textAlign: TextAlign.center,
            ),
            Container(height: 32,),
          ],),
        ),
      ),
      Padding(padding: EdgeInsets.only(top: 24), child:
        Column(children: [
          Row(children: [
            Expanded(child:
              RoundedButton(
                label: Localization().getStringEx('dialog.no.title', 'No'),
                textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Styles().colors.white,
                borderColor: Styles().colors.fillColorSecondaryVariant,
                onTap: () => _onNo(context),
              ),
            ),
            Container(width: 12,),
            Expanded(child:
              RoundedButton(
                label: Localization().getStringEx('dialog.yes.title', 'Yes'),
                textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Styles().colors.white,
                borderColor: Styles().colors.fillColorSecondaryVariant,
                onTap: () => _onYes(context),
              ),
            ),
          ],),
          InkWell(onTap: () => _onNotRightNow(context), child:
            Semantics(button: true, label: notRightNow, hint: Localization().getStringEx('panel.onboarding.base.not_now.hint', ''), excludeSemantics: true, child:
              Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
                Text(notRightNow, style: Styles().textStyles.getTextStyle("widget.button.title.medium.underline")),
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
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _onYes(BuildContext context) {
    Analytics().logSelect(target: "Yes");
    _onboardingNext(true);
  }

  void _onNo(BuildContext context) {
    Analytics().logSelect(target: "No");
    _onboardingNext(false);
  }

  void _onNotRightNow(BuildContext context) {
    Analytics().logSelect(target: "Not right now");
    _onboardingNext();
  }

  // Onboarding

  bool get onboardingProgress => _onboardingProgress;
  set onboardingProgress(bool value) {
    setStateIfMounted(() {
      _onboardingProgress = value;
    });
  }

  // void _onboardingBack() => Navigator.of(context).pop();
  void _onboardingNext([bool? participateInResearch = null]) async {
    Questionnaires().participateInResearch = participateInResearch;
    Storage().participateInResearchPrompted = true;
    if (widget.onContinue != null) {
      widget.onContinue?.call(context, widget, participateInResearch);
    } else {
      Onboarding2().next(context, widget);
    }
  }
}