
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:sprintf/sprintf.dart';


class AssignmentCompletePanel extends StatefulWidget with AnalyticsInfo {
  final int unitNumber;
  final int activityNumber;
  final int? pauses;
  final Color? color;
  final AnalyticsFeature? analyticsFeature; //This overrides AnalyticsInfo.analyticsFeature getter

  const AssignmentCompletePanel({required this.unitNumber, required this.activityNumber, this.pauses, required this.color, this.analyticsFeature});


  @override
  State<AssignmentCompletePanel> createState() => _AssignmentCompletePanelState();
}

class _AssignmentCompletePanelState extends State<AssignmentCompletePanel> {
  ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 3));

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _confettiController.play();
    return Scaffold(
      appBar: HeaderBar(
        title: sprintf(Localization().getStringEx("panel.essential_skills_coach.assignment.header.title", "Unit %d Activity %d"), [widget.unitNumber, widget.activityNumber]),
        textStyle: Styles().textStyles.getTextStyle('header_bar'),
      ),
      body: Column(
        children: _buildAssignmentCompleteWidgets(),
      ),
      backgroundColor: Styles().colors.background,
    );
  }

  List<Widget> _buildAssignmentCompleteWidgets() {
    return [
      Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ConfettiWidget(
                confettiController: _confettiController,
                numberOfParticles: 300,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
              ),
              if (widget.pauses != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    sprintf(Localization().getStringEx('panel.essential_skills_coach.assignment.complete.earned_pause.message', "You earned a pause!\nYou now have %d pauses."), [widget.pauses]),
                    style: Styles().textStyles.getTextStyle("widget.detail.extra_large.fat"),
                  ),
                ),
              Text(
                Localization().getStringEx('panel.essential_skills_coach.assignment.complete.message', "Keep up the \ngood work!"),
                style: Styles().textStyles.getTextStyle("widget.detail.extra_large.fat"),
              ),
            ],
          )
      ),
      Padding(padding: EdgeInsets.all(16),
          child: RoundedButton(
              label: Localization().getStringEx('panel.essential_skills_coach.assignment.complete.button.continue.label', 'Continue'),
              textStyle: Styles().textStyles.getTextStyle("widget.title.light.regular.fat"),
              backgroundColor: widget.color,
              borderColor: widget.color,
              onTap: ()=> Navigator.pop(context))
      ),
    ];
  }
}