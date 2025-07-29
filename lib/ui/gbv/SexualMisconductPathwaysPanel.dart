import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:illinois/ui/safety/SituationStepPanel.dart';
import 'package:illinois/model/SurveyTracker.dart';

class SexualMisconductPathwaysPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.sexual_misconduct.header.title', 'A Path Forward')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              Localization().getStringEx('panel.sexual_misconduct.path_forward.title', 'A Path Forward'),
              style: Styles().textStyles.getTextStyle('widget.title.large.fat'),
            ),
            SizedBox(height: 16),
            Text(
              Localization().getStringEx('panel.sexual_misconduct.path_forward.description',
                  'If you think you or a friend has experienced inappropriate sexual behavior or an unhealthy relationship, help is available.'),
              style: Styles().textStyles.getTextStyle('widget.message.regular'),
            ),
            SizedBox(height: 24),
            _buildPathwayButton(context, 'Talk to someone confidentially', () => _onTalkToSomeone(context)),
            _buildPathwayButton(context, 'File a report', () => _onFileReport(context)),
            _buildPathwayButton(context, 'Support a friend', () => _onSupportFriend(context)),
            _buildPathwayButton(context, "I'm not sure yet", () => _onNotSure(context)),
          ],
        ),
      ),
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildPathwayButton(BuildContext context, String label, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: RibbonButton(
        label: label,
        onTap: onTap,
        backgroundColor: Styles().colors.white,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
      ),
    );
  }


  void _onTalkToSomeone(BuildContext context) {
    // Navigate to Confidential Resources JSON
  }
  void _onFileReport(BuildContext context) {
    // Navigate to Filing a Report flow
  }
  void _onSupportFriend(BuildContext context) {
    // Navigate to Supporting a Friend Resources
  }
  void _onNotSure(BuildContext context) async {
    // Load the survey by its ID
    Survey? survey = await Surveys().loadSurvey("cabb1338-48df-4299-8c2a-563e021f82ca");

    // Extract the "situation" step
    SurveyData? situation = survey?.data['situation'];
    final SurveyTracker responseTracker = SurveyTracker();

    if (situation != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SituationStepPanel(
              situation: situation,
              responseTracker: responseTracker,
              stepKey: 'situation',
              surveyData: survey!.data, ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to load the survey step.")),
      );
    }
  }


}
