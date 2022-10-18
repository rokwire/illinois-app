
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

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

  bool _loading = false;
  Map<String, dynamic>? _questionnaire;

  @override
  void initState() {
    _loading = true;
    _loadQuestionnaire().then((Map<String, dynamic>? questionnaire) {
      if (mounted) {
        setState(() {
          _loading = false;
          _questionnaire = questionnaire;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors?.background,
      body: SafeArea(child:
        Stack(children: [
          OnboardingBackButton(padding: const EdgeInsets.only(left: 10, top: 30, right: 20, bottom: 20), onTap: () {
            Analytics().logSelect(target: "Back");
            Navigator.pop(context);
          }),
          _buildContent(),
        ],)
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return _buildLoading();
    }
    else if (_questionnaire == null) {
      return _buildError();
    }
    else {
      return _buildQuestionnaire();
    }
  }
    
  Widget _buildQuestionnaire() {
    return Column(children: [
      Padding(padding: EdgeInsets.only(left: 45, right: 45, top: 20), child:
        Semantics(label: 'Demographics Questionnaire', hint: '', excludeSemantics: true, child:
          Row(children: [
            Expanded(child:
              Text('Demographics Questionnaire', style: TextStyle(fontFamily: Styles().fontFamilies?.extraBold, fontSize: 24, color: Styles().colors?.fillColorPrimary), textAlign: TextAlign.center,),
            )
          ],)
        ),
      )
    ],);
  }

  Widget _buildLoading() {
    return Row(children: [
      Expanded(child:
        Column(children: [
          Expanded(child:
            Align(alignment: Alignment.center, child:
              CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 3, )
            ),
          ),
        ],))
    ]);
  }

  Widget _buildError() {
    return Row(children: [
      Expanded(child:
        Column(children: [
          Expanded(child:
            Align(alignment: Alignment.center, child:
              Padding(padding: EdgeInsets.only(left: 32, right: 32, top: 24, bottom: 24), child:
                Row(children: [
                  Expanded(child:
                    Text('Failed to load demographics questionnaire.', style: TextStyle(fontFamily: Styles().fontFamilies?.medium, fontSize: 20, color: Styles().colors?.fillColorPrimary), textAlign: TextAlign.center,),
                  ),
                ],)
              )
            ),
          ),
        ],))
    ]);
  }

  Future<Map<String, dynamic>?> _loadQuestionnaire() async {
    try { return JsonUtils.decodeMap(await rootBundle.loadString('assets/questionnaire.demographics.json')); }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }
  
}