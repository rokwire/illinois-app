
import 'package:flutter/material.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Onboarding2.dart';
import 'package:neom/ui/onboarding/OnboardingBackButton.dart';
import 'package:neom/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:neom/ui/profile/ProfileInfoPage.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class Onboarding2ProfileInfoPanel extends StatefulWidget {
  final Map<String, dynamic>? onboardingContext;

  Onboarding2ProfileInfoPanel({super.key, this.onboardingContext});

  @override
  State<StatefulWidget> createState() => _Onboarding2ProfileInfoPanelState();
}

class _Onboarding2ProfileInfoPanelState extends State<Onboarding2ProfileInfoPanel> implements NotificationsListener, Onboarding2ProgressableState {

  bool _onboarding2Progress = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyPrivacyChanged,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void onNotification(String name, param) {
    if (name == Auth2.notifyPrivacyChanged) {
      setStateIfMounted(() {});
    }
  }

  @override
  bool get onboarding2Progress => _onboarding2Progress;

  @override
  set onboarding2Progress(bool progress) => setStateIfMounted(() { _onboarding2Progress = progress; });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Styles().colors.background,
    body: SingleChildScrollView(child:
      Column(children: [
        _headerWidget,
        _titleWidget,
        _profileWidget,
        _footerWidget,
      ],)
    ),
  );

  Widget get _headerWidget => Stack(children: [
    Styles().images.getImage('header-login', fit: BoxFit.fitWidth, width: MediaQuery.of(context).size.width, excludeFromSemantics: true,) ?? Container(),
    OnboardingBackButton(padding: const EdgeInsets.only(left: 10, top: 30, right: 20, bottom: 20), onTap: _onTapBack),
  ],);

  Widget get _titleWidget =>
    Padding(padding: EdgeInsets.only(left: 32, right: 32, top: 24, bottom: 16), child:
      Center(child:
        Text(Localization().getStringEx('panel.onboarding.profile_info.title', 'User Directory'),
          style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 36, color: Styles().colors.fillColorPrimary),
          textAlign: TextAlign.center,
        ),
      )
    );

  Widget get _profileWidget =>
    Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16), child:
      ProfileInfoPage(contentType: ProfileInfo.directoryInfo, onStateChanged: _onProfileStateChanged,),
    );

  Widget get _footerWidget =>  _onboarding2Progress ?
    Stack(children: [
      _continueButton,
      Positioned.fill(child:
        Center(child:
          _progressWidget
        )
      ),
    ],) : _continueButton;

  Widget get _continueButton =>
    Onboarding2UnderlinedButton(
      title: Localization().getStringEx('panel.onboarding.profile_info.continue.title', 'Continue'),
      hint: Localization().getStringEx('panel.onboarding.profile_info.continue.hint', ''),
      padding: EdgeInsets.only(top: 24, bottom: 24, left: 16, right: 16),
      onTap: _onTapContinue,
    );

  Widget get _progressWidget => SizedBox(width: 24, height: 24, child:
    CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary,)
  );

  void _onProfileStateChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_){
        setStateIfMounted();
      });
    }
  }

  void _onTapContinue() {
    Analytics().logSelect(target: "Continue");
    Map<String, dynamic>? onboardingContext = widget.onboardingContext;
    Function? onContinue = onboardingContext?['onContinueAction'];
    Function? onContinueEx = onboardingContext?['onContinueActionEx'];
    if (onContinueEx != null) {
      onContinueEx(this);
    }
    else if (onContinue != null) {
      onContinue();
    }
  }

  void _onTapBack() {
    Analytics().logSelect(target: "Back");
    Navigator.pop(context);
  }
}