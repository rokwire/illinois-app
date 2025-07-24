import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/gbv/GBVResourceListPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:illinois/ui/gbv/SituationStepPanel.dart';

class SexualMisconductPathwaysPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.sexual_misconduct.header.title', 'Inappropriate Sexual Behavior')),
      body: _buildContent(context),
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SectionSlantHeader(
      headerWidget: _buildHeader(context),
      slantColor: Styles().colors.gradientColorPrimary,
      slantPainterHeadingHeight: 0,
      backgroundColor: Styles().colors.background,
      children: [
      ],
      childrenPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      allowOverlap: false,
    );
  }

  Widget _buildHeader(BuildContext context) {
    Widget content;
    content = Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(Localization().getStringEx('', 'A Path Forward'),
          style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.get_started.header'), textAlign: TextAlign.left,
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
        Text(Localization().getStringEx('', 'If you think you or a friend has experienced inappropriate sexual behavior or an unhealthy relationship, help is available.'),
          style: Styles().textStyles.getTextStyle('widget.description.regular.highlight'), textAlign: TextAlign.left,
        )
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
        Text(Localization().getStringEx('', 'Choose one of the below pathways or view a list of resources.'),
          style: Styles().textStyles.getTextStyle('widget.description.regular.highlight'), textAlign: TextAlign.left,
        )
        ),
        _buildPathwayButton(context, 'Talk to someone confidentially', () => _onTalkToSomeone(context)),
        _buildPathwayButton(context, 'File a report', () => _onFileReport(context)),
        _buildPathwayButton(context, 'Support a friend', () => _onSupportFriend(context)),
        _buildPathwayButton(context, "I'm not sure yet", () => _onNotSure(context)),
        // ),

      ])
    );
    return Container(
      padding: EdgeInsets.only(top: 8, bottom: 32),
      child: Padding(padding: EdgeInsets.only(left: 24, right: 8), child: content,),
      decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Styles().colors.fillColorPrimaryVariant,
                Styles().colors.gradientColorPrimary,
              ]
          )
      ),
    );
  }

  Widget _buildPathwayButton(BuildContext context, String label, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: RoundedButton(
        label: label,
        textStyle: Styles().textStyles.getTextStyle('widget.title.regular.fat'),
        onTap: onTap,
        backgroundColor: Styles().colors.white,
      ),
    );
  }


  void _onTalkToSomeone(BuildContext context) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceListPanel(id: 'confidential_resources')));
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

    if (situation != null) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => SituationStepPanel(situation: situation),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to load the survey step.")),
      );
    }
  }

}