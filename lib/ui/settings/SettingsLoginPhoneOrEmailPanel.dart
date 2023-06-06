import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/settings/SettingsLoginEmailPanel.dart';
import 'package:illinois/ui/settings/SettingsLoginPhoneConfirmPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SettingsLoginPhoneOrEmailPanel extends StatefulWidget {
  final SettingsLoginPhoneOrEmailMode mode;
  final bool? link;
  final String? identifier;
  final void Function()? onFinish;

  SettingsLoginPhoneOrEmailPanel({this.mode = SettingsLoginPhoneOrEmailMode.both, this.link, this.identifier, this.onFinish });

  _SettingsLoginPhoneOrEmailPanelState createState() => _SettingsLoginPhoneOrEmailPanelState();
}

class _SettingsLoginPhoneOrEmailPanelState extends State<SettingsLoginPhoneOrEmailPanel>  {

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
    String title, description, headingTitle, headingHint, buttonProceedTitle, buttonProceedHint;
    TextInputType keyboardType;
    Widget? proceedRightIcon;
    
    if (widget.link == true) {
      if (widget.mode == SettingsLoginPhoneOrEmailMode.phone) {
        title = Localization().getStringEx('panel.settings.link.phone.label.title', 'Add Mobile');
        description = Localization().getStringEx('panel.settings.link.phone.label.description', 'You may sign in using your mobile phone number as an alternative way to sign in. Some features of the {{app_title}} App will not be available unless you login with your NetID.').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'));
        headingTitle = Localization().getStringEx('panel.settings.link.phone.label.heading', 'ADD MY MOBILE PHONE NUMBER');
        headingHint = Localization().getStringEx('panel.settings.link.phone.label.heading.hint', '');
        buttonProceedTitle =  Localization().getStringEx('panel.settings.link.phone.button.proceed.title', 'Add Mobile');
        buttonProceedHint = Localization().getStringEx('panel.settings.link.phone.button.proceed.hint', '');
        keyboardType = TextInputType.phone;
      }
      else if (widget.mode == SettingsLoginPhoneOrEmailMode.email){
        title = Localization().getStringEx('panel.settings.link.email.label.title', 'Add Email');
        description = Localization().getStringEx('panel.settings.link.email.label.description', 'You may sign in using your email as an alternative way to sign in. Some features of the {{app_title}} App will not be available unless you login with your NetID.').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'));
        headingTitle = Localization().getStringEx('panel.settings.link.email.label.heading', 'ADD MY EMAIL ADDRESS');
        headingHint =  Localization().getStringEx('panel.settings.link.email.label.heading.hint', '');
        buttonProceedTitle = Localization().getStringEx('panel.settings.link.email.button.proceed.title', 'Add Email');
        buttonProceedHint = Localization().getStringEx('panel.settings.link.email.button.proceed.hint', '');
        keyboardType = TextInputType.emailAddress;
      }
      else {
        title = Localization().getStringEx('panel.settings.link.both.label.title', 'Add Mobile or Email');
        description = Localization().getStringEx('panel.settings.link.both.label.description', 'You may sign in using your email or mobile phone number as an alternative way to sign in. Some features of the {{app_title}} App will not be available unless you login with your NetID.').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'));
        headingTitle = Localization().getStringEx('panel.settings.link.both.label.heading', 'ADD MY MOBILE PHONE NUMBER OR EMAIL ADDRESS');
        headingHint =  Localization().getStringEx('panel.settings.link.both.label.heading.hint', '');
        buttonProceedTitle = Localization().getStringEx('panel.settings.link.both.button.proceed.title', 'Add Mobile or Email');
        buttonProceedHint = Localization().getStringEx('panel.settings.link.both.button.proceed.hint', '');
        keyboardType = TextInputType.emailAddress;
      }
      proceedRightIcon = Styles().images?.getImage('plus-circle', excludeFromSemantics: true);
    }
    else {
      if (widget.mode == SettingsLoginPhoneOrEmailMode.phone) {
        title = Localization().getStringEx('panel.settings.login.phone.label.title', 'Sign In with Mobile');
        description = Localization().getStringEx('panel.settings.login.phone.label.description', 'To sign in, please enter your email address and follow the steps to sign in by email.');
        headingTitle = Localization().getStringEx('panel.settings.login.phone.label.heading', 'Mobile Phone Number:');
        headingHint = Localization().getStringEx('panel.settings.login.phone.label.heading.hint', '');
        buttonProceedTitle = Localization().getStringEx('panel.settings.login.phone.button.proceed.title', 'Proceed');
        buttonProceedHint = Localization().getStringEx('panel.settings.login.phone.button.proceed.hint', '');
        keyboardType = TextInputType.phone;
      }
      else if (widget.mode == SettingsLoginPhoneOrEmailMode.email){
        title = Localization().getStringEx('panel.settings.login.email.label.title', 'Sign In with Email');
        description = Localization().getStringEx('panel.settings.login.email.label.description', 'To sign in, please enter your mobile phone number to receive a verification code via text message.');
        headingTitle = Localization().getStringEx('panel.settings.login.email.label.heading', 'Email Address:');
        headingHint = Localization().getStringEx('panel.settings.login.email.label.heading.hint', '');
        buttonProceedTitle = Localization().getStringEx('panel.settings.login.email.button.proceed.title', 'Proceed');
        buttonProceedHint = Localization().getStringEx('panel.settings.login.email.button.proceed.hint', '');
        keyboardType = TextInputType.emailAddress;
      }
      else {
        title = Localization().getStringEx('panel.settings.login.both.label.title', 'Sign In with Mobile or Email');
        description = Localization().getStringEx('panel.settings.login.both.label.description', 'To sign in, please enter your mobile phone number to receive a verification code via text message. Or, enter your email address and follow the steps to sign in by email.');
        headingTitle = Localization().getStringEx('panel.settings.login.both.label.heading', 'Mobile Phone Number or Email Address:');
        headingHint = Localization().getStringEx('panel.settings.login.both.label.heading.hint', '');
        buttonProceedTitle = Localization().getStringEx('panel.settings.login.both.button.proceed.title', 'Proceed');
        buttonProceedHint = Localization().getStringEx('panel.settings.login.both.button.proceed.hint', '');
        keyboardType = TextInputType.emailAddress;
      }
    }


    return Scaffold(
      appBar: HeaderBar(title: title,),
      body: Column(children: <Widget>[
        Expanded(child:
          SingleChildScrollView(scrollDirection: Axis.vertical, child:
            Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(children:[
                Row(children: [ Expanded(child:
                  Text(description, style:  Styles().textStyles?.getTextStyle("widget.description.medium"),)
                )],),
                Container(height: 48),
                Row(children: [ Expanded(child:
                  Text(headingTitle, style: Styles().textStyles?.getTextStyle("widget.title.medium.fat"),)
                )],),
                Container(height: 6),
                Semantics(label: headingTitle, hint: headingHint, textField: true, excludeSemantics: true,
                  value: _phoneOrEmailController?.text,
                  child: Container(
                    color: (widget.identifier == null) ? Styles().colors?.white : Styles().colors?.background,
                    child: TextField(
                      controller: _phoneOrEmailController,
                      readOnly: widget.identifier != null,
                      autofocus: false,
                      autocorrect: false,
                      onSubmitted: (_) => _clearErrorMsg,
                      cursorColor: Styles().colors?.textBackground,
                      keyboardType: keyboardType,
                      style: Styles().textStyles?.getTextStyle("widget.input_field.text.medium"),
                      decoration: InputDecoration(
                        disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors!.mediumGray!, width: 1.0),),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors!.mediumGray!, width: 1.0),),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors!.mediumGray!, width: 1.0),),
                      ),
                    ),
                  ),
                ),
                Visibility(visible: StringUtils.isNotEmpty(_validationErrorMsg), child:
                  Padding(key: _validationErrorKey, padding: EdgeInsets.symmetric(vertical: 12), child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(StringUtils.ensureNotEmpty(_validationErrorMsg ?? ''), style: Styles().textStyles?.getTextStyle("panel.settings.error.text")),
                      Visibility(visible: StringUtils.isNotEmpty(_validationErrorDetails), child:
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(StringUtils.ensureNotEmpty(_validationErrorDetails ?? ''), style: Styles().textStyles?.getTextStyle("widget.detail.small")),
                        ),
                      ),
                    ],),
                  ),
                ),
                Container(height: 12),
                RoundedButton(
                  label: buttonProceedTitle,
                  hint: buttonProceedHint,
                  textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                  onTap: _onTapProceed,
                  backgroundColor: Styles().colors?.white,
                  borderColor: Styles().colors?.fillColorSecondary,
                  rightIcon: proceedRightIcon,
                  iconPadding: 16,
                  progress: _isLoading,
                ),
              ]),
            ),
          ),
        ),
        Container(height: 16,)
      ],),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: uiuc.TabBar(),
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

  void _loginByPhone(String? phoneNumber) {
    setState(() { _isLoading = true; });

    if (widget.link != true) {
      Auth2().authenticateWithPhone(phoneNumber).then((Auth2PhoneRequestCodeResult result) {
        _onPhoneInitiated(phoneNumber, result);
      });
    } else if (!Auth2().isPhoneLinked) { // at most one phone number may be linked at a time
      Map<String, dynamic> creds = {
        "phone": phoneNumber
      };
      Map<String, dynamic> params = {};
      Auth2().linkAccountAuthType(Auth2LoginType.phoneTwilio, creds, params).then((Auth2LinkResult result) {
        _onPhoneInitiated(phoneNumber, auth2PhoneRequestCodeResultFromAuth2LinkResult(result));
      });
    } else {
      setErrorMsg(Localization().getStringEx("panel.settings.link.phone.label.linked", "You have already added a phone number to your account."));
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _onPhoneInitiated(String? phoneNumber, Auth2PhoneRequestCodeResult result) {
    if (mounted) {
      setState(() { _isLoading = false; });

      if (result == Auth2PhoneRequestCodeResult.succeeded) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsLoginPhoneConfirmPanel(phoneNumber: phoneNumber, link: widget.link, onFinish: widget.onFinish)));
      } else if (result == Auth2PhoneRequestCodeResult.failedAccountExist) {
        setErrorMsg(Localization().getStringEx("panel.settings.link.phone.label.failed.exists", "An account is already using this phone number."),
            details: Localization().getStringEx("panel.settings.link.phone.label.failed.exists.detail", "1. You will need to sign in to the other account with this phone number.\n2. Go to \"Settings\" and press \"Forget all of my information\".\nYou can now use this as an alternate login."));
      } else {
        setErrorMsg(Localization().getStringEx("panel.settings.link.phone.label.failed", "Failed to send phone verification code. An unexpected error has occurred."));
      }
    }
  }

  void _loginByEmail(String? email) {
    setState(() { _isLoading = true; });

    if (widget.link == true) {
      Auth2().canLink(email, Auth2LoginType.email).then((bool? result) {
        if (mounted) {
          setState(() { _isLoading = false; });
          if (result == null) {
            setErrorMsg(Localization().getStringEx("panel.settings.link.email.label.failed", "Failed to send verification email. An unexpected error has occurred."));
          }
          else if (result == false) {
            setErrorMsg(Localization().getStringEx("panel.settings.link.email.label.failed.exists", "An account is already using this email."),
                details: Localization().getStringEx("panel.settings.link.email.label.failed.exists.detail", "1. You will need to sign in to the other account with this email address.\n2. Go to \"Settings\" and press \"Forget all of my information\".\nYou can now use this as an alternate login."));
          }
          else if (Auth2().isEmailLinked) { // at most one email address may be linked at a time
            setErrorMsg(Localization().getStringEx("panel.settings.link.email.label.linked", "You have already added an email address to your account."));
          }
          else {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsLoginEmailPanel(email: email, state: Auth2EmailAccountState.nonExistent, link: widget.link, onFinish: widget.onFinish)));
          }
        }
      });
    }
    else {
      Auth2().canSignIn(email, Auth2LoginType.email).then((bool? result) {
        if (mounted) {
          setState(() { _isLoading = false; });
          if (result != null) {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsLoginEmailPanel(email: email,
                state: result ? Auth2EmailAccountState.verified : Auth2EmailAccountState.nonExistent, link: widget.link, onFinish: widget.onFinish)));
          }
          else {
            setErrorMsg(Localization().getStringEx("panel.onboarding2.phone_or_email.email.failed", "Failed to verify email address."));
          }
        }
      });
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