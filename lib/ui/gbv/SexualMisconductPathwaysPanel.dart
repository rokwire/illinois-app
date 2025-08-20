import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
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
    try {
      final String jsonStr = await rootBundle.loadString('assets/extra/gbv/illinois_gbv_survey.json');
      final Map<String, dynamic> surveyMap = json.decode(jsonStr);

      final Survey survey = Survey.fromJson(surveyMap);
      final SurveyTracker responseTracker = SurveyTracker();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SituationStepPanel(
            stepKey: 'situation',
            responseTracker: responseTracker,
            surveyData: survey.data,
          ),
        ),
      );
    } catch (e, s) {
      debugPrint("Error loading static survey JSON: $e");
      debugPrintStack(stackTrace: s);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error loading survey JSON: ${e.toString()}",
            maxLines: 4,
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }




}
