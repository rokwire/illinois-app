import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:neom/ui/profile/ProfileLoginCodePanel.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:neom/ui/widgets/SlantedWidget.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileLoginPhoneOrEmailPanel extends StatefulWidget {
  final SettingsLoginPhoneOrEmailMode mode;
  final bool? link;
  final String? identifier;
  final void Function()? onFinish;

  ProfileLoginPhoneOrEmailPanel({this.mode = SettingsLoginPhoneOrEmailMode.both, this.link, this.identifier, this.onFinish });

  _ProfileLoginPhoneOrEmailPanelState createState() => _ProfileLoginPhoneOrEmailPanelState();
}

class _ProfileLoginPhoneOrEmailPanelState extends State<ProfileLoginPhoneOrEmailPanel>  {

  TextEditingController? _phoneOrEmailController;

  String? _validationErrorMsg;
  String? _validationErrorDetails;
  GlobalKey _validationErrorKey = GlobalKey();

  bool _isLoading = false;

  @override
  void initState() {
    _phoneOrEmailController = TextEditingController(text: widget.identifier);
    super.initState();
  }

  @override
  void dispose() {
    _phoneOrEmailController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String description, headingTitle, headingHint, buttonProceedTitle, buttonProceedHint;
    TextInputType keyboardType;
    // Widget? proceedRightIcon;
    
    if (widget.link == true) {
      if (widget.mode == SettingsLoginPhoneOrEmailMode.phone) {
        description = Localization().getStringEx('panel.settings.link.phone.label.description', 'You may sign in using your mobile phone number as an alternative way to sign in. Some features of the {{app_title}} App will not be available unless you login with your NetID.').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'));
        headingTitle = Localization().getStringEx('panel.settings.link.phone.label.heading', 'ADD MY MOBILE PHONE NUMBER');
        headingHint = Localization().getStringEx('panel.settings.link.phone.label.heading.hint', '');
        buttonProceedTitle =  Localization().getStringEx('panel.settings.link.phone.button.proceed.title', 'Add Mobile');
        buttonProceedHint = Localization().getStringEx('panel.settings.link.phone.button.proceed.hint', '');
        keyboardType = TextInputType.phone;
      }
      else if (widget.mode == SettingsLoginPhoneOrEmailMode.email){
        description = Localization().getStringEx('panel.settings.link.email.label.description', 'You may sign in using your email as an alternative way to sign in. Some features of the {{app_title}} App will not be available unless you login with your NetID.').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'));
        headingTitle = Localization().getStringEx('panel.settings.link.email.label.heading', 'ADD MY EMAIL ADDRESS');
        headingHint =  Localization().getStringEx('panel.settings.link.email.label.heading.hint', '');
        buttonProceedTitle = Localization().getStringEx('panel.settings.link.email.button.proceed.title', 'Add Email');
        buttonProceedHint = Localization().getStringEx('panel.settings.link.email.button.proceed.hint', '');
        keyboardType = TextInputType.emailAddress;
      }
      else {
        description = Localization().getStringEx('panel.settings.link.both.label.description', 'You may sign in using your email or mobile phone number as an alternative way to sign in. Some features of the {{app_title}} App will not be available unless you login with your NetID.').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'));
        headingTitle = Localization().getStringEx('panel.settings.link.both.label.heading', 'ADD MY MOBILE PHONE NUMBER OR EMAIL ADDRESS');
        headingHint =  Localization().getStringEx('panel.settings.link.both.label.heading.hint', '');
        buttonProceedTitle = Localization().getStringEx('panel.settings.link.both.button.proceed.title', 'Add Mobile or Email');
        buttonProceedHint = Localization().getStringEx('panel.settings.link.both.button.proceed.hint', '');
        keyboardType = TextInputType.emailAddress;
      }
      // proceedRightIcon = Styles().images.getImage('plus-circle', excludeFromSemantics: true);
    }
    else {
      if (widget.mode == SettingsLoginPhoneOrEmailMode.phone) {
        description = Localization().getStringEx('panel.settings.login.phone.label.description', 'To sign in, please enter your email address and follow the steps to sign in by email.');
        headingTitle = Localization().getStringEx('panel.settings.login.phone.label.heading', 'Mobile Phone Number:');
        headingHint = Localization().getStringEx('panel.settings.login.phone.label.heading.hint', '');
        buttonProceedTitle = Localization().getStringEx('panel.settings.login.phone.button.proceed.title', 'Proceed');
        buttonProceedHint = Localization().getStringEx('panel.settings.login.phone.button.proceed.hint', '');
        keyboardType = TextInputType.phone;
      }
      else if (widget.mode == SettingsLoginPhoneOrEmailMode.email){
        description = Localization().getStringEx('panel.settings.login.email.label.description', 'To sign in, please enter your mobile phone number to receive a verification code via text message.');
        headingTitle = Localization().getStringEx('panel.settings.login.email.label.heading', 'Email Address:');
        headingHint = Localization().getStringEx('panel.settings.login.email.label.heading.hint', '');
        buttonProceedTitle = Localization().getStringEx('panel.settings.login.email.button.proceed.title', 'Proceed');
        buttonProceedHint = Localization().getStringEx('panel.settings.login.email.button.proceed.hint', '');
        keyboardType = TextInputType.emailAddress;
      }
      else {
        description = Localization().getStringEx('panel.settings.login.both.label.description', 'Please enter your mobile phone number or email address to receive a verification code via text message or email.');
        headingTitle = Localization().getStringEx('panel.settings.login.both.label.heading', 'Mobile Phone Number or Email Address:');
        headingHint = Localization().getStringEx('panel.settings.login.both.label.heading.hint', '');
        buttonProceedTitle = Localization().getStringEx('panel.settings.login.both.button.proceed.title', 'Proceed');
        buttonProceedHint = Localization().getStringEx('panel.settings.login.both.button.proceed.hint', '');
        keyboardType = TextInputType.emailAddress;
      }
    }

    return SafeArea(
      child: Scaffold(
        body: Column(children: <Widget>[
          Expanded(child:
            SingleChildScrollView(scrollDirection: Axis.vertical, child:
              Column(children:[
                Stack(
                  children: [
                    Semantics(hint: Localization().getStringEx("common.heading.one.hint","Header 1"), header: true, child:
                      Onboarding2TitleWidget(),
                    ),
                    Positioned(
                      top: 32,
                      left: 0,
                      child: Onboarding2BackButton(padding: const EdgeInsets.all(16.0,),
                          onTap:() {
                            Analytics().logSelect(target: "Back");
                            Navigator.pop(context);
                          }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
                  child: Row(children: [ Expanded(child:
                    Text(description, style:  Styles().textStyles.getTextStyle("widget.description.medium.light"),)
                  )],),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(children: [ Expanded(child:
                    Text(headingTitle, style: Styles().textStyles.getTextStyle("widget.title.light.medium.fat"),)
                  )],),
                ),
                Container(height: 8),
                Semantics(label: headingTitle, hint: headingHint, textField: true, excludeSemantics: true,
                  value: _phoneOrEmailController?.text,
                  child: Container(
                    color: Styles().colors.background,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: TextField(
                      controller: _phoneOrEmailController,
                      readOnly: widget.identifier != null,
                      autofocus: false,
                      autocorrect: false,
                      onSubmitted: (_) => _clearErrorMsg,
                      cursorColor: Styles().colors.textDark,
                      keyboardType: keyboardType,
                      scrollPadding: EdgeInsets.only(bottom: 120),
                      style: Styles().textStyles.getTextStyle("widget.input_field.text.medium"),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Styles().colors.surface,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Visibility(visible: StringUtils.isNotEmpty(_validationErrorMsg), child:
                  Padding(key: _validationErrorKey, padding: EdgeInsets.symmetric(vertical: 16), child:
                    Column(children: [
                      Text(StringUtils.ensureNotEmpty(_validationErrorMsg ?? ''), style: Styles().textStyles.getTextStyle("panel.settings.error.text"), textAlign: TextAlign.center,),
                      Visibility(visible: StringUtils.isNotEmpty(_validationErrorDetails), child:
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(StringUtils.ensureNotEmpty(_validationErrorDetails ?? ''), style: Styles().textStyles.getTextStyle("widget.detail.small"), textAlign: TextAlign.center,),
                        ),
                      ),
                    ],),
                  ),
                ),
                Container(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SlantedWidget(
                    color: Styles().colors.fillColorSecondary,
                    child: RibbonButton(
                      label: buttonProceedTitle,
                      hint: buttonProceedHint,
                      textAlign: TextAlign.center,
                      backgroundColor: Styles().colors.fillColorSecondary,
                      textStyle: Styles().textStyles.getTextStyle('widget.button.light.title.large.fat'),
                      onTap: _onTapProceed,
                      // rightIcon: proceedRightIcon,
                      rightIconKey: null,
                      progress: _isLoading,
                      progressColor: Styles().colors.textLight,
                    ),
                  ),
                ),
              ]),
            ),
          ),
          Container(height: 16,)
        ],),
        backgroundColor: Styles().colors.background,
      ),
    );
  }

  void _clearErrorMsg() {
    setState(() {
      _validationErrorMsg = null;
    });
  }
  
  void _onTapProceed() {
    String analyticsText, validationText;
    if (widget.mode == SettingsLoginPhoneOrEmailMode.phone) {
      analyticsText = 'Add Phone Number';
      validationText = Localization().getStringEx('panel.settings.link.phone.label.validation', 'Please enter your phone number.');
    }
    else if (widget.mode == SettingsLoginPhoneOrEmailMode.email){
      analyticsText = 'Add Email Address';
      validationText = Localization().getStringEx('panel.settings.link.email.label.validation', 'Please enter your email address.');
    }
    else {
      analyticsText = 'Add Phone or Email';
      validationText = Localization().getStringEx('panel.settings.link.both.label.validation', 'Please enter your phone number or email address.');
    }


    Analytics().logSelect(target: analyticsText);

    if (_isLoading != true) {
      _clearErrorMsg();

      String phoneOrEmailValue = _phoneOrEmailController!.text;
      String? phone, email;
      if (widget.mode == SettingsLoginPhoneOrEmailMode.phone || widget.mode == SettingsLoginPhoneOrEmailMode.both) {
        phone = _validatePhoneNumber(phoneOrEmailValue);
      }
      if (widget.mode == SettingsLoginPhoneOrEmailMode.email || widget.mode == SettingsLoginPhoneOrEmailMode.both) {
        email = StringUtils.isEmailValid(phoneOrEmailValue) ? phoneOrEmailValue : null;
      }

      if (StringUtils.isNotEmpty(phone)) {
        _loginByPhone(phone);
      }
      else if (StringUtils.isNotEmpty(email)) {
        _loginByEmail(email);
      }
      else {
        setErrorMsg(validationText);
      }
    }
  }

  Future<void> _loginByPhone(String? phoneNumber) async {
    setState(() { _isLoading = true; });

    if (widget.link != true) {
      Auth2RequestCodeResult result = await Auth2().authenticateWithCode(phoneNumber, identifierType: Auth2Identifier.typePhone);
      if (mounted) {
        _onPhoneInitiated(phoneNumber, result);
      }
    } else if (!Auth2().isPhoneLinked) { // at most one phone number may be linked at a time
      Auth2LinkResult result = await Auth2().linkAccountIdentifier(phoneNumber, Auth2Identifier.typePhone);
      if (mounted) {
        _onPhoneInitiated(phoneNumber, auth2RequestCodeResultFromAuth2LinkResult(result));
      }
    } else {
      setErrorMsg(Localization().getStringEx("panel.settings.link.phone.label.linked", "You have already added a phone number to your account."));
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _onPhoneInitiated(String? phoneNumber, Auth2RequestCodeResult result) {
    if (mounted) {
      setState(() { _isLoading = false; });

      if (result == Auth2RequestCodeResult.succeeded) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => ProfileLoginCodePanel(identifier: phoneNumber, linkIdentifier: widget.link, onFinish: widget.onFinish)));
      } else if (result == Auth2RequestCodeResult.failedAccountExist) {
        setErrorMsg(Localization().getStringEx("panel.settings.link.phone.label.failed.exists", "An account is already using this phone number."),
            details: Localization().getStringEx("panel.settings.link.phone.label.failed.exists.detail", "1. You will need to sign in to the other account with this phone number.\n2. Go to \"Settings\" and press \"Forget all of my information\".\nYou can now use this as an alternate login."));
      } else {
        setErrorMsg(Localization().getStringEx("panel.settings.link.phone.label.failed", "Failed to send phone verification code. An unexpected error has occurred."));
      }
    }
  }

  Future<void> _loginByEmail(String? email) async {
    setState(() { _isLoading = true; });
    if (widget.link != true) {
      Auth2RequestCodeResult result = await Auth2().authenticateWithCode(email, identifierType: Auth2Identifier.typeEmail);
      if (mounted) {
        setState(() { _isLoading = false; });
        _onEmailInitiated(context, email, result);
      }
    } else if (!Auth2().isEmailLinked) {
      Auth2LinkResult result = await Auth2().linkAccountIdentifier(email, Auth2Identifier.typeEmail);
      if (mounted) {
        setState(() { _isLoading = false; });
        _onEmailInitiated(context, email, auth2RequestCodeResultFromAuth2LinkResult(result));
      }
    } else {
      Map<String, dynamic> creds = {
        "email": email
      };
      Map<String, dynamic> params = {};
      Auth2LinkResult result = await Auth2().linkAccountAuthType(Auth2Type.typeCode, creds, params);
      if (mounted) {
        setState(() { _isLoading = false; });
        _onEmailInitiated(context, email, auth2RequestCodeResultFromAuth2LinkResult(result));
      }
    }
  }

  void _onEmailInitiated(BuildContext context, String? email, Auth2RequestCodeResult result) {
    if (result == Auth2RequestCodeResult.succeeded) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ProfileLoginCodePanel(identifier: email, defaultIdentifierType: Auth2Identifier.typeEmail, linkIdentifier: widget.link, onFinish: widget.onFinish)));
    } else if (result == Auth2RequestCodeResult.failedAccountExist) {
      setErrorMsg(Localization().getStringEx('panel.settings.profile.error.email.exists', 'The email address you selected is already in use. Please pick a different one.'));
    } else if (result == Auth2RequestCodeResult.failed) {
      setErrorMsg(Localization().getStringEx('panel.settings.profile.error.email.failed', 'The email address you selected could not be added to your account.'));
    } else {
      setErrorMsg(Localization().getStringEx("panel.settings.link.phone.label.failed", "Failed to send verification code. An unexpected error has occurred."));
    }
  }

  void setErrorMsg(String? msg, {String? details}) {
    setState(() {
      _validationErrorMsg = msg;
      _validationErrorDetails = details;
    });

    if (StringUtils.isNotEmpty(msg)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_validationErrorKey.currentContext != null) {
          Scrollable.ensureVisible(_validationErrorKey.currentContext!, duration: Duration(milliseconds: 300)).then((_) {
          });
        }
      });
    }
  }

  static String? _validatePhoneNumber(String? phoneNumber) {
    if (kReleaseMode) {
      if (StringUtils.isUsPhoneValid(phoneNumber)) {
        phoneNumber = StringUtils.constructUsPhone(phoneNumber);
        if (StringUtils.isUsPhoneValid(phoneNumber)) {
          return phoneNumber;
        }
      }
    }
    else {
      if (StringUtils.isPhoneValid(phoneNumber)) {
        return phoneNumber;
      }
    }
    return null;
  }
}

enum SettingsLoginPhoneOrEmailMode {
  phone,
  email,
  both
}

String settingsLoginPhoneOrEmailModeToString(SettingsLoginPhoneOrEmailMode mode) {
  switch(mode) {
    case SettingsLoginPhoneOrEmailMode.phone: return 'phone';
    case SettingsLoginPhoneOrEmailMode.email: return 'email';
    case SettingsLoginPhoneOrEmailMode.both: return 'both';
  }
}