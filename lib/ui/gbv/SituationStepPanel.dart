import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/model/options.dart';

class SituationStepPanel extends StatelessWidget {
  final SurveyData situation;
  //TODO: Make use of illinois_gbv_result_rules.json
  const SituationStepPanel({Key? key, required this.situation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<OptionData>? options;
    if (situation is SurveyQuestionMultipleChoice) {
      options = (situation as SurveyQuestionMultipleChoice).options;
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
                  onPressed: () {
                    // TODO: Handle option selection
                  },
                  child: Text(option.title),
                ),
              )),
          ],
        ),
      ),
    );
  }
}
