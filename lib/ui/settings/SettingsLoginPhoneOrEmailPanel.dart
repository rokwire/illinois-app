import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/settings/SettingsLoginEmailPanel.dart';
import 'package:illinois/ui/settings/SettingsLoginPhoneConfirmPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SettingsLoginPhoneOrEmailPanel extends StatefulWidget {
  final SettingsLinkPhoneOrEmailMode mode;
  final String? identifier;
  final void Function()? onFinish;

  SettingsLoginPhoneOrEmailPanel({this.mode = SettingsLinkPhoneOrEmailMode.both, this.identifier, this.onFinish });

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
    String title, description, headingTitle, headingHint, buttonAddTitle, buttonAddHint;
    TextInputType keyboardType;
    if (widget.mode == SettingsLinkPhoneOrEmailMode.phone) {
      title = Localization().getStringEx('panel.settings.link.phone.label.title', 'Add Phone Number');
      description = Localization().getStringEx('panel.settings.link.phone.label.description', 'You may sign in using your phone number as an alternative way to sign in. Some features of the Illinois App will not be available unless you login with your NetID.');
      headingTitle = Localization().getStringEx('panel.settings.link.phone.label.heading', 'ADD MY PHONE NUMBER');
      headingHint = Localization().getStringEx('panel.settings.link.phone.label.heading.hint', '');
      buttonAddTitle = Localization().getStringEx('panel.settings.link.phone.button.add.title', 'Add Phone Number');
      buttonAddHint = Localization().getStringEx('panel.settings.link.phone.button.add.hint', '');
      keyboardType = TextInputType.phone;
    }
    else if (widget.mode == SettingsLinkPhoneOrEmailMode.email){
      title = Localization().getStringEx('panel.settings.link.email.label.title', 'Add Email Address');
      description = Localization().getStringEx('panel.settings.link.email.label.description', 'You may sign in using your email as an alternative way to sign in. Some features of the Illinois App will not be available unless you login with your NetID.');
      headingTitle = Localization().getStringEx('panel.settings.link.email.label.heading', 'ADD MY EMAIL ADDRESS');
      headingHint = Localization().getStringEx('panel.settings.link.email.label.heading.hint', '');
      buttonAddTitle = Localization().getStringEx('panel.settings.link.email.button.add.title', 'Add Email Address');
      buttonAddHint = Localization().getStringEx('panel.settings.link.email.button.add.hint', '');
      keyboardType = TextInputType.emailAddress;
    }
    else {
      title = Localization().getStringEx('panel.settings.link.both.label.title', 'Add Phone or Email');
      description = Localization().getStringEx('panel.settings.link.both.label.description', 'You may sign in using your email or phone number as an alternative way to sign in. Some features of the Illinois App will not be available unless you login with your NetID.');
      headingTitle = Localization().getStringEx('panel.settings.link.both.label.heading', 'ADD MY PHONE NUMBER OR EMAIL ADDRESS');
      headingHint = Localization().getStringEx('panel.settings.link.both.label.heading.hint', '');
      buttonAddTitle = Localization().getStringEx('panel.settings.link.both.button.add.title', 'Add Phone or Email');
      buttonAddHint = Localization().getStringEx('panel.settings.link.both.button.add.hint', '');
      keyboardType = TextInputType.emailAddress;
    }

    return Scaffold(
      appBar: HeaderBar(title: title,),
      body: Column(children: <Widget>[
        Expanded(child:
          SingleChildScrollView(scrollDirection: Axis.vertical, child:
            Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(children:[
                Row(children: [ Expanded(child:
                  Text(description, style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 18, color: Styles().colors!.fillColorPrimary),)
                )],),
                Container(height: 48),
                Row(children: [ Expanded(child:
                  Text(headingTitle, style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 18, color: Styles().colors!.fillColorPrimary),)
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
                      style: TextStyle(fontSize: 18, fontFamily: Styles().fontFamilies?.regular, color: Styles().colors?.textBackground),
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors!.background!, width: 2.0, style: BorderStyle.solid),),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors!.background!, width: 2.0),),
                      ),
                    ),
                  ),
                ),
                Visibility(visible: StringUtils.isNotEmpty(_validationErrorMsg), child:
                  Padding(key: _validationErrorKey, padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), child:
                    Column(
                      children: [
                        Text(StringUtils.ensureNotEmpty(_validationErrorMsg ?? ''), style: TextStyle(color: Colors.red, fontSize: 16, fontFamily: Styles().fontFamilies!.bold),),
                        Visibility(visible: StringUtils.isNotEmpty(_validationErrorDetails), child:
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(StringUtils.ensureNotEmpty(_validationErrorDetails ?? ''), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.regular),),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(height: 12),
                RoundedButton(
                  label: buttonAddTitle,
                  hint: buttonAddHint,
                  onTap: _onTapAdd,
                  backgroundColor: Styles().colors?.white,
                  textColor: Styles().colors?.fillColorPrimary,
                  borderColor: Styles().colors?.fillColorSecondary,
                  contentWeight: 0.65,
                  conentAlignment: MainAxisAlignment.start,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  rightIcon: Image.asset('images/icon-plus.png'),
                  rightIconPadding: EdgeInsets.only(right: 8),
                  leftIconPadding: EdgeInsets.zero,
                  progress: _isLoading,
                ),
              ]),
            ),
          ),
        ),
        Container(height: 16,)
      ],),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  void _clearErrorMsg() {
    setState(() {
      _validationErrorMsg = null;
    });
  }
  
  void _onTapAdd() {
    String analyticsText, validationText;
    if (widget.mode == SettingsLinkPhoneOrEmailMode.phone) {
      analyticsText = 'Add Phone Number';
      validationText = Localization().getStringEx('panel.settings.link.phone.label.validation', 'Please enter your phone number.');
    }
    else if (widget.mode == SettingsLinkPhoneOrEmailMode.email){
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
      if (widget.mode == SettingsLinkPhoneOrEmailMode.phone || widget.mode == SettingsLinkPhoneOrEmailMode.both) {
        phone = _validatePhoneNumber(phoneOrEmailValue);
      }
      if (widget.mode == SettingsLinkPhoneOrEmailMode.email || widget.mode == SettingsLinkPhoneOrEmailMode.both) {
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

    if (!Auth2().isPhoneLinked){ // at most one phone number may be linked at a time
      Map<String, dynamic> creds = {
        "phone": phoneNumber
      };
      Map<String, dynamic> params = {};
      Auth2().linkAccountAuthType(Auth2LoginType.phoneTwilio, creds, params).then((result) {
        if (result == Auth2LinkResult.succeeded) {
          _onPhoneInitiated(phoneNumber, Auth2PhoneRequestCodeResult.succeeded);
        } else if (result == Auth2LinkResult.failedAccountExist) {
          _onPhoneInitiated(phoneNumber, Auth2PhoneRequestCodeResult.failedAccountExist);
        } else {
          _onPhoneInitiated(phoneNumber, Auth2PhoneRequestCodeResult.failed);
        }
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
    }

    if (result == Auth2PhoneRequestCodeResult.succeeded) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsLoginPhoneConfirmPanel(phoneNumber: phoneNumber, onFinish: widget.onFinish)));
    } else if (result == Auth2PhoneRequestCodeResult.failedAccountExist) {
      setErrorMsg(Localization().getStringEx("panel.settings.link.phone.label.failed.exists", "An account is already using this phone number."));
    } else {
      setErrorMsg(Localization().getStringEx("panel.settings.link.phone.label.failed", "Failed to send phone verification code. An unexpected error has occurred."));
    }
  }

  void _loginByEmail(String? email) {
    setState(() { _isLoading = true; });

    Auth2().canLink(email, Auth2LoginType.email).then((bool? result) {
      if (mounted) {
        setState(() { _isLoading = false; });
        if (result != null) {
          if (!result) {
            setErrorMsg(Localization().getStringEx("panel.settings.link.email.label.failed", "An account is already using this email address."),);
            return;
          } else if (Auth2().isEmailLinked) { // at most one email address may be linked at a time
            setErrorMsg(Localization().getStringEx("panel.settings.link.email.label.linked", "You have already added an email address to your account."));
            return;
          }
          
          Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsLoginEmailPanel(email: email, onFinish: widget.onFinish)));
        }
        else {
          setErrorMsg(Localization().getStringEx("panel.settings.link.email.label.failed", "Failed to send verification email. An unexpected error has occurred."));
        }
      }
    });
  }

  void setErrorMsg(String? msg, {String? details}) {
    setState(() {
      _validationErrorMsg = msg;
      _validationErrorDetails = details;
    });

    if (StringUtils.isNotEmpty(msg)) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
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

enum SettingsLinkPhoneOrEmailMode {
  phone,
  email,
  both
}

String settingsLinkPhoneOrEmailModeToString(SettingsLinkPhoneOrEmailMode mode) {
  switch(mode) {
    case SettingsLinkPhoneOrEmailMode.phone: return 'phone';
    case SettingsLinkPhoneOrEmailMode.email: return 'email';
    case SettingsLinkPhoneOrEmailMode.both: return 'both';
  }
}