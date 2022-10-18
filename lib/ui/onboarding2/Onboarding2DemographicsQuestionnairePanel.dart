
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class Onboarding2DemographicsQuestionnairePanel extends StatefulWidget {

  final Map<String, dynamic>? onboardingContext;
  Onboarding2DemographicsQuestionnairePanel({this.onboardingContext});

  @override
  State<Onboarding2DemographicsQuestionnairePanel> createState() =>
    _Onboarding2DemographicsQuestionnairePanelState();

  static Future<bool?> prompt(BuildContext context) async {
    return await AppAlert.showCustomDialog(context: context,
      contentWidget:
        Text('Do you want to participate in Demographics Questionnaire?',
          style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.fillColorPrimary,),
        ),
      actions: [
        TextButton(
          child: Text(Localization().getStringEx('dialog.yex.title', 'Yes')),
          onPressed: () => Navigator.of(context).pop(true)
        ),
        TextButton(
          child: Text(Localization().getStringEx('dialog.no.title', 'No')),
          onPressed: () => Navigator.of(context).pop(false)
        )
      ]);
  }
}

class _Onboarding2DemographicsQuestionnairePanelState extends State<Onboarding2DemographicsQuestionnairePanel> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}