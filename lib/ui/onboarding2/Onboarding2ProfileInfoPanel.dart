
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:illinois/ui/profile/ProfileInfoPage.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/SlantedWidget.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/onboarding.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Onboarding2ProfileInfoPanel extends StatefulWidget with Onboarding2Panel {
  final String onboardingCode;
  final Onboarding2Context? onboardingContext;
  Onboarding2ProfileInfoPanel({ super.key, this.onboardingCode = 'profile_info', this.onboardingContext });

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
  bool get onboarding2Progress => _onboardingProgress;

  @override
  set onboarding2Progress(bool progress) => setStateIfMounted(() { _onboardingProgress = progress; });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Scaffold(
      backgroundColor: Styles().colors.background,
      body: SingleChildScrollView(child:
        Column(
          children: [
            _headerWidget,
            Container(
              constraints: BoxConstraints(maxWidth: Config().webContentMaxWidth),
              child: Column(
                crossAxisAlignment: kIsWeb ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  _titleWidget,
                  _profileWidget,
                  _footerWidget,
                ],
              ),
            ),
          ],
        )
      ),
    ),
  );

  Widget get _headerWidget => Semantics(hint: Localization().getStringEx("common.heading.one.hint","Header 1"), header: true, child:
    Onboarding2TitleWidget()
  );

  Widget get _titleWidget =>
    Padding(padding: EdgeInsets.only(left: 32, right: 32, top: 24, bottom: 16), child:
      Text(Localization().getStringEx('panel.onboarding.profile_info.title', 'PROFILE AND DIRECTORY'),
        style: Styles().textStyles.getTextStyle('panel.onboarding.profile_info.heading.title'),
        textAlign: TextAlign.center,
      )
    );

  Widget get _profileWidget =>
    Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16), child:
      ProfileInfoPage(key: _profileInfoKey,
        params: {
          ProfileInfoPage.editParamKey : true,
        },
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

  bool get _canContinue => (_onboardingProgress != true) && (_saving != true);

  Widget get _continueCommandButton => SlantedWidget(
    color: Styles().colors.fillColorSecondary,
    child: RibbonButton(
        backgroundColor: Styles().colors.fillColorSecondary,
        label: Localization().getStringEx('panel.onboarding.profile_info.continue.title', 'Continue'),
        hint: Localization().getStringEx('panel.onboarding.profile_info.continue.hint', ''),
        textStyle: Styles().textStyles.getTextStyle("widget.button.light.title.large.fat"),
        textAlign: TextAlign.center,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        progress: _onboardingProgress || _saving,
        progressColor: Styles().colors.textLight,
        onTap: _onTapContinue,
        rightIconKey: null,
    ),
  );

  void _onProfileStateChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_){
        setStateIfMounted();
      });
    }
  }

  bool get _isLoaded => (_profileInfoKey.currentState?.isLoading != true);
  bool get _isEditing => (_profileInfoKey.currentState?.isEditing == true);

  void _onTapContinue() {
    Analytics().logSelect(target: "Continue");
    if (_canContinue) {
      if (_isEditing) {
        setState(() {
          _saving = true;
        });
        _profileInfoKey.currentState?.saveModified().then((bool? result){
          if (mounted) {
            setState(() {
              _saving = false;
            });
            if (result ?? false) {
              _onboardingNext();
            }
          }
        });
      }
      else {
        _profileInfoKey.currentState?.setEditing(true);
      }
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