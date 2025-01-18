
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/service/Onboarding2.dart';
import 'package:neom/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:neom/ui/profile/ProfileInfoPage.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:neom/ui/widgets/SlantedWidget.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/onboarding.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Onboarding2ProfileInfoPanel extends StatefulWidget with OnboardingPanel {
  final Map<String, dynamic>? onboardingContext;

  Onboarding2ProfileInfoPanel({super.key, this.onboardingContext});

  @override
  State<StatefulWidget> createState() => _Onboarding2ProfileInfoPanelState();

  @override
  bool get onboardingCanDisplay {
    return StringUtils.isEmpty(Auth2().fullName);
  }
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
        contentType: ProfileInfo.directoryInfo,
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

  bool get _canContinue => (_onboarding2Progress != true) && (_saving != true);

  Widget get _continueCommandButton => SlantedWidget(
    color: Styles().colors.fillColorSecondary,
    child: RibbonButton(
        backgroundColor: Styles().colors.fillColorSecondary,
        label: Localization().getStringEx('panel.onboarding.profile_info.continue.title', 'Continue'),
        hint: Localization().getStringEx('panel.onboarding.profile_info.continue.hint', ''),
        textStyle: Styles().textStyles.getTextStyle("widget.button.light.title.large.fat"),
        textAlign: TextAlign.center,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        progress: _onboarding2Progress || _saving,
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

  bool get _isLoaded => (_profileInfoKey.currentState?.isLoading == false);
  bool get _isEditing => (_profileInfoKey.currentState?.isEditing == true);

  void _onTapContinue() {
    Analytics().logSelect(target: "Continue");
    if (_canContinue) {
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
              _finishProfile();
            }
          }
        });
      }
      else {
        _profileInfoKey.currentState?.setEditing(true);
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
    else {
      Onboarding().next(context, widget);
    }
  }
}