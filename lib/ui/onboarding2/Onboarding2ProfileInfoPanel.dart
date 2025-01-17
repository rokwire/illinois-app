
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:illinois/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:illinois/ui/profile/ProfileInfoPage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class Onboarding2ProfileInfoPanel extends StatefulWidget {
  final Map<String, dynamic>? onboardingContext;

  Onboarding2ProfileInfoPanel({super.key, this.onboardingContext});

  @override
  State<StatefulWidget> createState() => _Onboarding2ProfileInfoPanelState();
}

class _Onboarding2ProfileInfoPanelState extends State<Onboarding2ProfileInfoPanel> implements NotificationsListener, Onboarding2ProgressableState {

  final GlobalKey<ProfileInfoPageState> _profileInfoKey = GlobalKey<ProfileInfoPageState>();
  bool _onboarding2Progress = false;
  bool _saving = false;

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
    Positioned(top: 0, left: 0, child:
      _backImageButton,
    ),
    Positioned(top: 0, right: 0, child:
      _skipLinkSection,
    )
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
      ProfileInfoPage(key: _profileInfoKey,
        contentType: ProfileInfo.directoryInfo,
        onStateChanged: _onProfileStateChanged,
        onboarding: true,
      ),
    );

  Widget get _footerWidget => _isLoaded ? _continueCommandSection : Container();

  Widget get _continueCommandSection => Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 32), child:
    _continueCommandButton,
  );

  bool get _canContinue => (_onboarding2Progress != true) && (_saving != true);

  Widget get _continueCommandButton => RoundedButton(
      label: Localization().getStringEx('panel.onboarding.profile_info.continue.title', 'Continue'),
      hint: Localization().getStringEx('panel.onboarding.profile_info.continue.hint', ''),
      textStyle: _canContinue ? Styles().textStyles.getTextStyle("widget.button.title.medium.fat") : Styles().textStyles.getTextStyle("widget.button.disabled.title.medium.fat.variant"),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      borderColor: _canContinue ? Styles().colors.fillColorSecondary : Styles().colors.fillColorPrimaryTransparent03,
      progress: _onboarding2Progress || _saving,
      enabled: _canContinue,
      onTap: _onTapContinue
  );

  bool get _canSkip => (_onboarding2Progress != true);

  Widget get _skipLinkSection => _onboarding2Progress ?
    Stack(children: [
      _skipLinkButton,
      Positioned.fill(child:
        Center(child:
          _skipProgressWidget
        )
      ),
    ],) : _skipLinkButton;

  Widget get _skipLinkButton => Onboarding2UnderlinedButton(
    title: Localization().getStringEx('panel.onboarding.profile_info.skip.title', 'Skip'),
    hint: Localization().getStringEx('panel.onboarding.profile_info.skip.hint', ''),
    padding: EdgeInsets.only(top: 30, bottom: 30, left: 20, right: 20),
    onTap: _onTapSkip,
  );

  Widget get _skipProgressWidget => SizedBox(width: 16, height: 16, child:
    CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorPrimary,)
  );

  void _onTapSkip() {
    Analytics().logSelect(target: "Skip");
    if (_canSkip) {
      _finishProfile();
    }
  }

  Widget get _backImageButton => OnboardingBackButton(
    padding: const EdgeInsets.only(top: 30, bottom: 30, left: 10, right: 20),
    onTap: _onTapBack
  );

  void _onTapBack() {
    Analytics().logSelect(target: "Back");
    Navigator.pop(context);
  }

  void _onProfileStateChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_){
        setStateIfMounted();
      });
    }
  }

  bool get _isLoaded => (_profileInfoKey.currentState?.isLoading == false);
  bool get _isEditing => (_profileInfoKey.currentState?.isEditing == true);
  bool get _isProfilePublic => (_profileInfoKey.currentState?.directoryVisibility == true);

  void _onTapContinue() {
    Analytics().logSelect(target: "Continue");
    if (_canContinue) {
      if (_isProfilePublic) {

        if (_isEditing) {
          setState(() {
            _saving = true;
          });
          _profileInfoKey.currentState?.saveEdit().then((bool result){
            if (mounted) {
              setState(() {
                _saving = false;
              });
              if (result) {
                _finishProfile();              }
            }
          });
        }
        else {
          _profileInfoKey.currentState?.setEditing(true);
        }
      }
      else {
        _finishProfile();
      }
    }
  }

  void _finishProfile() {
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

}