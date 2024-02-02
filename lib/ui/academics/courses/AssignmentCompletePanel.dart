
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:sprintf/sprintf.dart';


class AssignmentCompletePanel extends StatefulWidget {
  final String contentName;
  final int? pauses;
  final Color? color;
  final Color? colorAccent;

  const AssignmentCompletePanel({required this.contentName, this.pauses, required this.color, required this.colorAccent});


  @override
  State<AssignmentCompletePanel> createState() => _AssignmentCompletePanelState();
}

class _AssignmentCompletePanelState extends State<AssignmentCompletePanel> {

  Color? _color;
  Color? _colorAccent;
  ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 3));

  @override
  void initState() {
    _color = widget.color;
    _colorAccent = widget.colorAccent;
    super.initState();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _confettiController.play();
    return Scaffold(
      appBar: HeaderBar(title: widget.contentName, textStyle: Styles().textStyles.getTextStyle('header_bar'),),
      body: Column(
        children: _buildAssignmentCompleteWidgets(),
      ),
      backgroundColor: _color,
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
                  child: Text(sprintf(Localization().getStringEx('panel.essential_skills_coach.assignment.complete.earned_pause.message', "You earned a pause!\nYou now have %d pauses."), [widget.pauses]), style: Styles().textStyles.getTextStyle("widget.title.light.huge.fat"),),
                ),
              Text(Localization().getStringEx('panel.essential_skills_coach.assignment.complete.message', "Keep up the \ngood work!"), style: Styles().textStyles.getTextStyle("widget.title.light.huge.fat"),),
            ],
          )
      ),
      Padding(padding: EdgeInsets.all(16),
          child: RoundedButton(
              label: Localization().getStringEx('panel.essential_skills_coach.assignment.complete.button.continue.label', 'Continue'),
              textStyle: Styles().textStyles.getTextStyle("widget.title.light.regular.fat"),
              backgroundColor: _colorAccent,
              borderColor: _colorAccent,
              onTap: ()=> Navigator.pop(context))
      ),
    ];
  }
}