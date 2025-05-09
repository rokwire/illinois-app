
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
import 'package:rokwire_plugin/utils/utils.dart';

class Onboarding2ProfileInfoPanel extends StatefulWidget with Onboarding2Panel {
  final String onboardingCode;
  final Onboarding2Context? onboardingContext;
  Onboarding2ProfileInfoPanel({ super.key, this.onboardingCode = '', this.onboardingContext });

  _Onboarding2ProfileInfoPanelState? get _currentState => JsonUtils.cast(globalKey?.currentState);

  @override
  bool get onboardingProgress => (_currentState?.onboardingProgress == true);
  @override
  set onboardingProgress(bool value) => _currentState?.onboardingProgress = value;

  @override
  State<StatefulWidget> createState() => _Onboarding2ProfileInfoPanelState();
}

class _Onboarding2ProfileInfoPanelState extends State<Onboarding2ProfileInfoPanel> with NotificationsListener, Onboarding2ProgressableState {

  final GlobalKey<ProfileInfoPageState> _profileInfoKey = GlobalKey<ProfileInfoPageState>();
  bool _onboardingProgress = false;

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
  bool get onboarding2Progress => _onboardingProgress;

  @override
  set onboarding2Progress(bool progress) => setStateIfMounted(() { _onboardingProgress = progress; });

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
        SafeArea(child:
          _backImageButton,
        ),
      ),
    if (_isLoading)
      Positioned(top: 0, right: 0, child:
          SafeArea(child:
            _skipLinkSection,
          ),
        ),
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
        onStateChanged: _onProfileStateChanged,
        onboarding: true,
      ),
    );

  Widget get _footerWidget => _isLoaded ? _continueCommandSection : Container();

  Widget get _continueCommandSection => Padding(padding: EdgeInsets.symmetric(horizontal: 32), child:
    Column(children: [
      Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
        Text(Localization().getStringEx('panel.onboarding.profile_info.description.text', 'To adjust your profile information and its visibility at any time, go to My Profile.'), style: Styles().textStyles.getTextStyle('widget.detail.small'), textAlign: TextAlign.center,),
      ),
      Padding(padding: EdgeInsets.only(bottom: 32), child:
        _continueCommandButton,
      ),
    ],),
  );

  bool get _canContinue => (_onboardingProgress != true);

  Widget get _continueCommandButton => RoundedButton(
      label: Localization().getStringEx('panel.onboarding.profile_info.continue.title', 'Continue'),
      hint: Localization().getStringEx('panel.onboarding.profile_info.continue.hint', ''),
      textStyle: _canContinue ? Styles().textStyles.getTextStyle("widget.button.title.medium.fat") : Styles().textStyles.getTextStyle("widget.button.disabled.title.medium.fat.variant"),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      borderColor: _canContinue ? Styles().colors.fillColorSecondary : Styles().colors.fillColorPrimaryTransparent03,
      progress: _onboardingProgress,
      enabled: _canContinue,
      onTap: _onTapContinue
  );

  bool get _canSkip => (_onboardingProgress != true);

  Widget get _skipLinkSection => _onboardingProgress ?
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

  Widget get _backImageButton => OnboardingBackButton(
    padding: const EdgeInsets.only(top: 30, bottom: 30, left: 10, right: 20),
    onTap: _onTapBack
  );

  void _onProfileStateChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_){
        setStateIfMounted();
      });
    }
  }

  void _onTapBack() {
    Analytics().logSelect(target: "Back");
    _onboardingBack();
  }

  void _onTapSkip() {
    Analytics().logSelect(target: "Skip");
    if (_canSkip) {
      _onboardingNext();
    }
  }

  bool get _isLoaded => (_profileInfoKey.currentState?.isLoading != true);
  bool get _isLoading => (_profileInfoKey.currentState?.isLoading == true);

  void _onTapContinue() {
    Analytics().logSelect(target: "Continue");
    if (_canContinue) {
      _onboardingNext();
    }
  }

  // Onboarding

  bool get onboardingProgress => _onboardingProgress;
  set onboardingProgress(bool value) {
    setStateIfMounted(() {
      _onboardingProgress = value;
    });
  }

  void _onboardingBack() => Navigator.of(context).pop();
  void _onboardingNext() => Onboarding2().next(context, widget);
}