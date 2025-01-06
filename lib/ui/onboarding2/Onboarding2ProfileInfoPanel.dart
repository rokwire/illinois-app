
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:illinois/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:illinois/ui/profile/ProfileInfoAndDirectoryPage.dart';
import 'package:illinois/ui/profile/ProfileInfoPage.dart';
import 'package:illinois/utils/AppUtils.dart';
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

  GlobalKey<ProfileInfoPageState> _profileKey = GlobalKey();
  bool _progress = false;

  bool get _isPreviewMode => (_profileKey.currentState?.previewMode == true);
  bool get _isAccountPublic => (Auth2().account?.privacy?.public == true);

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
  bool get onboarding2Progress => _progress;

  @override
  set onboarding2Progress(bool progress) => setStateIfMounted(() { _progress = progress; });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Styles().colors.background,
    body: SingleChildScrollView(child:
      Column(children: [
        _headerWidget,
        _titleWidget,
        if (_isAccountPublic == false)
          _descriptionWidget,
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

  Widget get _descriptionWidget =>
    Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, ), child:
      Center(child:
        Text(Localization().getStringEx('panel.onboarding.profile_info.description', 'Choose how your account will be visible to other users in User Directory'),
          style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 14, color: Styles().colors.fillColorPrimary),
          textAlign: TextAlign.center,
        ),
      )
    );

  Widget get _profileWidget =>
    Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16), child:
      ProfileInfoPage(key: _profileKey, contentType: ProfileInfo.directoryInfo, onStateChanged: _onProfileStateChanged,),
    );

  Widget get _footerWidget => _isPreviewMode ? (
    _progress ? Stack(children: [
        _continueButton,
        Positioned.fill(child:
          Center(child:
            _progressWidget
          )
        ),
    ],) : _continueButton
  ) : Padding(padding: EdgeInsets.only(top: 24));

  Widget get _continueButton =>
    Onboarding2UnderlinedButton(
      title: _continueTitle,
      hint: _continueHint,
      padding: EdgeInsets.only(top: 16, bottom: 16, left: 16, right: 16),
      onTap: _onTapContinue,
    );

  Widget get _progressWidget => SizedBox(width: 24, height: 24, child:
    CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary,)
  );

  String get _continueTitle => _isAccountPublic ?
    Localization().getStringEx('panel.onboarding.profile_info.continue.title', 'Continue') :
    Localization().getStringEx('panel.onboarding.profile_info.skip.title', 'Not Right Now');

  String get _continueHint => _isAccountPublic ?
    Localization().getStringEx('panel.onboarding.profile_info.continue.hint', '') :
    Localization().getStringEx('panel.onboarding.profile_info.skip.hint', '');

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