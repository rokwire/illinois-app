
import 'package:flutter/cupertino.dart';
import 'package:illinois/model/Config.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/onboarding/OnboardingMessagePanel.dart';

class OnboardingConfigAlertPanel extends StatefulWidget {
  static const String notifyCheckAgain  = "edu.illinois.rokwire.onboarding.alert.check_again";

  final ConfigAlert? alert;

  OnboardingConfigAlertPanel({super.key, this.alert});

  @override
  State<StatefulWidget> createState() => _OnboardingConfigAlertPanelState();
}

class _OnboardingConfigAlertPanelState extends State<OnboardingConfigAlertPanel> {

  bool _progress = false;

  @override
  Widget build(BuildContext context) => OnboardingMessagePanel(
    title: widget.alert?.title,
    message: widget.alert?.message,
    footer: _footerWidget,
  );

  Widget get _footerWidget =>
    Padding(padding: EdgeInsets.only(top: 8, bottom: 32), child:
      RoundedButton(
        label: Localization().getStringEx('panel.onboarding.alert.button.check_again.title', 'Check Again'),
        hint: Localization().getStringEx('panel.onboarding.alert.button.check_again.hint', ''),
        textStyle: Styles().textStyles.getTextStyle("widget.colourful_button.title.large.accent"),
        borderColor: Styles().colors.fillColorSecondary,
        backgroundColor: Styles().colors.fillColorSecondary,
        progress: _progress,
        progressColor: Styles().colors.white,
        progressStrokeWidth: 2,
        onTap: _onCheckAgain,
      ),
    );

  void _onCheckAgain() {
    Analytics().logSelect(target: 'Check Again');
    if (_progress == false) {
      setState(() {
        _progress = true;
      });

      Config().refresh().then((_){
        if (mounted) {
          setState(() {
            _progress = false;
          });
          NotificationService().notify(OnboardingConfigAlertPanel.notifyCheckAgain);
        }
      });
    }
  }
}