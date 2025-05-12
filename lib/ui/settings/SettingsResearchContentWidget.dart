import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Questionnaire.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ResearchQuestionnaireAcknowledgementPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ResearchQuestionnairePanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

import '../../utils/AppUtils.dart';

class SettingsResearchContentWidget extends StatefulWidget{
  final String? parentRouteName;

  const SettingsResearchContentWidget({super.key, this.parentRouteName});

  @override
  State<StatefulWidget> createState() => _SettingsContactsContentWidgetState();

}

class _SettingsContactsContentWidgetState extends State<SettingsResearchContentWidget> {

  @override
  Widget build(BuildContext context) =>
    Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildQuestionnaireOptions()
      ],
    );

  Widget _buildQuestionnaireOptions() =>
   Padding(padding: EdgeInsets.only(top: 25), child:
    Column(children:<Widget>[
      Row(children: [
        Expanded(child:
        Text(Localization().getStringEx('panel.settings.home.calendar.research.title', 'Research Participation'), style:
        Styles().textStyles.getTextStyle("widget.title.large.fat")
        ),
        ),
      ]),
      Container(height: 4),
      ToggleRibbonButton(
          label: Localization().getStringEx('panel.settings.home.calendar.research.toggle.title', 'Participate in research'),
          border: Border.all(color: Styles().colors.surfaceAccent),
          borderRadius: BorderRadius.all(Radius.circular(4)),
          toggled: Questionnaires().participateInResearch == true,
          onTap: _onResearchQuestionnaireToggled
      ),
      Container(height: 4),
      RibbonButton(
          border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(4)),
          label: Localization().getStringEx("panel.settings.home.calendar.research.questionnaire.title", "Research interest form"),
          textStyle:  (Questionnaires().participateInResearch == true) ? Styles().textStyles.getTextStyle("widget.button.title.enabled") : Styles().textStyles.getTextStyle("widget.button.title.disabled"),
          rightIconKey: Questionnaires().participateInResearch ?? false ? 'chevron-right-bold' : 'chevron-right-gray',
          onTap: _onResearchQuestionnaireClicked
      ),
    ]),
  );

  void _onResearchQuestionnaireToggled() {
    Analytics().logSelect(target: 'Participate in research');
    if (Questionnaires().participateInResearch == true) {
      _promptTurnOffParticipateInResearch().then((bool? result) {
        if (result == true) {
          setState(() {
            Questionnaires().participateInResearch = false;
          });
        }
      });
    }
    else {
      setState(() {
        Questionnaires().participateInResearch = true;
      });
    }
  }

  void _onResearchQuestionnaireClicked() {
    Analytics().logSelect(target: 'Research Questionnaire');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2ResearchQuestionnairePanel(
      onContinue: _didResearchQuestionnaire,
    )));
  }

  Future<bool?> _promptTurnOffParticipateInResearch() async {
    String promptEn = 'Please confirm that you wish to no longer participate in Research Projects. All information filled out in your questionnaire will be deleted.';
    return await AppAlert.showCustomDialog(context: context,
        contentWidget:
        Text(Localization().getStringEx('panel.settings.home.calendar.research.prompt.title', promptEn),
          style: Styles().textStyles.getTextStyle("widget.message.regular"),
        ),
        actions: [
          TextButton(
              child: Text(Localization().getStringEx('dialog.yes.title', 'Yes')),
              onPressed: () { Analytics().logAlert(text: promptEn, selection: 'Yes'); Navigator.of(context).pop(true); }
          ),
          TextButton(
              child: Text(Localization().getStringEx('dialog.no.title', 'No')),
              onPressed: () { Analytics().logAlert(text: promptEn, selection: 'No'); Navigator.of(context).pop(false); }
          )
        ]);
  }

  void _didResearchQuestionnaire() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2ResearchQuestionnaireAcknowledgementPanel(
      onContinue: _didAcknowledgeResearchQuestionnaire,
    )));
  }

  void _didAcknowledgeResearchQuestionnaire() {
    if (widget.parentRouteName != null) {
      Navigator.of(context).popUntil((Route route){
        return route.settings.name == widget.parentRouteName;
      });
    }
    else {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

}