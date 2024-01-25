
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';


class AssignmentCompletePanel extends StatefulWidget {

  final Color? color;
  final Color? colorAccent;

  const AssignmentCompletePanel({required this.color, required this.colorAccent});


  @override
  State<AssignmentCompletePanel> createState() => _AssignmentCompletePanelState();
}

class _AssignmentCompletePanelState extends State<AssignmentCompletePanel> implements NotificationsListener {

  late Color? _color;
  late Color? _colorAccent;
  late ConfettiController _confettiController;

  @override
  void initState() {
    _color = widget.color!;
    _colorAccent = widget.colorAccent!;
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
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
      appBar: HeaderBar(title: Localization().getStringEx('', 'Daily Activities'),
        textStyle: Styles().textStyles.getTextStyle('header_bar'),),
      body: Column(
        children: _buildAssignmentCompleteWidgets(),
      ),
      backgroundColor: _color,
    );
  }

  List<Widget> _buildAssignmentCompleteWidgets() {
    List<Widget> widgets = <Widget>[];

    widgets.add(
      Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  numberOfParticles: 300,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                ),
              ),
              Center(
                child: Text("Keep up the \ngood work!", style: Styles().textStyles.getTextStyle("widget.title.light.huge.fat"),),
              ),
            ],
          )
      )
    );

    widgets.add(
      Padding(padding: EdgeInsets.all(16),
          child: RoundedButton(
              label: Localization().getStringEx('panel.trial.button.continue.label', 'Continue'),
              textStyle: Styles().textStyles.getTextStyle("widget.title.light.regular.fat"),
              backgroundColor: _colorAccent,
              borderColor: _colorAccent,
              onTap: ()=> Navigator.pop(context))
      )
    );

    return widgets;
  }



  @override
  void onNotification(String name, param) {
    // TODO: implement onNotification
  }

}