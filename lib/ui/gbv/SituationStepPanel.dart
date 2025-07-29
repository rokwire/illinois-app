import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/model/options.dart';
import 'package:illinois/service/GBVRules.dart';
import 'package:illinois/model/SurveyTracker.dart';

class SituationStepPanel extends StatelessWidget {
  final SurveyData situation;
  final SurveyTracker responseTracker;
  final String stepKey;
  final Map<String, SurveyData> surveyData;
  //TODO: Implement remainder of illinois_gbv_result_rules.json and all of the survey
  //TODO: Update Mongo database to reflect Figma https://www.figma.com/design/1hkYSwY89cpDkj0Mej7iCA/GBV---for-Dev-team?node-id=9428-2115&p=f
  const SituationStepPanel({Key? key, required this.situation, required this.responseTracker, required this.stepKey, required this.surveyData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<OptionData>? options;
    if (situation is SurveyQuestionMultipleChoice) {
      options = (situation as SurveyQuestionMultipleChoice).options;
      print('listed multiple choice options');
    }

    return Scaffold(
      appBar: AppBar(title: Text('Situation')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              situation.text,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (situation.moreInfo != null && situation.moreInfo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  situation.moreInfo!,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            SizedBox(height: 24),
            if (options != null)
              ...options.map((option) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton(
                  onPressed: () async {
                    print('setting response with stepKey: "$stepKey"');
                    responseTracker.setResponse(stepKey, option.title);
                    print('responseTracker responses: ${responseTracker.responses}');
                    if (stepKey == 'next') { // or whatever the step key for final action is
                      List<dynamic> rules = await GBVResultRulesService.loadRules();
                      dynamic result = getMatchingResult(rules, responseTracker.responses);
                      if (result != null && result['action'] == 'alert') {
                        final String dataKey = result['data']; // e.g., 'data.counseling_center'
                        print('dataKey is $dataKey');
                        // Pull info from survey JSON using `dataKey`, then display
                        showResourceDialog(context, surveyData[dataKey]!);
                      }
                    }
                  }
                  ,
                  child: Text(option.title ?? ''),
                ),
              )),
          ],
        ),
      ),
    );
  }
}

void showResourceDialog(BuildContext context, SurveyData resourceData) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(resourceData.text ?? 'Resource'),
        content: Text(resourceData.moreInfo ?? ''),
        actions: <Widget>[
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}
