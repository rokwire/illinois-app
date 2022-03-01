import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class SettingsLinkPhoneConfirmPanel extends StatefulWidget {

  final String? phoneNumber;
  final void Function()? onFinish;

  SettingsLinkPhoneConfirmPanel({this.phoneNumber, this.onFinish});

  _SettingsLinkPhoneConfirmPanelState createState() => _SettingsLinkPhoneConfirmPanelState();
}

class _SettingsLinkPhoneConfirmPanelState extends State<SettingsLinkPhoneConfirmPanel>  {

  TextEditingController _codeController = TextEditingController();
  String? _verificationErrorMsg;

  bool _isConfirming = false;
  bool _isCanceling = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? phoneNumber = widget.phoneNumber;
    String maskedPhoneNumber = StringUtils.getMaskedPhoneNumber(phoneNumber);
    String description = sprintf(Localization().getStringEx('panel.onboarding.confirm_phone.description.send', 'A one time code has been sent to %s. Enter your code below to continue.'), [maskedPhoneNumber]);
    String headingTitle = Localization().getStringEx("panel.onboarding.confirm_phone.code.label", "One-time code");
    String headingHint = Localization().getStringEx("panel.onboarding.confirm_phone.code.hint", "");

    return Scaffold(
      appBar: HeaderBar(title: 'Confirm your code',),
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
                  value: _codeController.text,
                  child: Container(
                    color: Styles().colors?.white,
                    child: TextField(
                      controller: _codeController,
                      autofocus: false,
                      autocorrect: false,
                      onSubmitted: (_) => _clearErrorMsg,
                      cursorColor: Styles().colors?.textBackground,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(fontSize: 18, fontFamily: Styles().fontFamilies?.regular, color: Styles().colors?.textBackground),
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors!.background!, width: 2.0, style: BorderStyle.solid),),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors!.background!, width: 2.0),),
                      ),
                    ),
                  ),
                ),
                Visibility(visible: StringUtils.isNotEmpty(_verificationErrorMsg), child:
                  Padding(padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12), child:
                    Text(StringUtils.ensureNotEmpty(_verificationErrorMsg), style: TextStyle(color: Colors.red, fontSize: 14, fontFamily: Styles().fontFamilies!.medium),),
                  ),
                ),
                
                Container(height: 12),
                Row(children: [
                  Expanded(child: RoundedButton(
                    label:  Localization().getStringEx("panel.onboarding.confirm_phone.button.confirm.short.label", "Confirm"),
                    hint: Localization().getStringEx("panel.onboarding.confirm_phone.button.confirm.hint", ""),
                    onTap: _onTapConfirm,
                    backgroundColor: Styles().colors?.white,
                    textColor: Styles().colors?.fillColorPrimary,
                    borderColor: Styles().colors?.fillColorSecondary,
                    progress: _isConfirming,
                  ),),
                  Container(width: 12),
                  Expanded(child: RoundedButton(
                    label:  Localization().getStringEx("panel.onboarding.confirm_phone.button.link.cancel.label", "Cancel"),
                    hint: Localization().getStringEx("panel.onboarding.confirm_phone.button.link.cancel.hint", ""),
                    onTap: _onTapCancel,
                    backgroundColor: Styles().colors?.white,
                    textColor: Styles().colors?.fillColorPrimary,
                    borderColor: Styles().colors?.fillColorSecondary,
                    progress: _isCanceling,
                  ),),
                ],),

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

  void _onTapConfirm() {

    if(_isConfirming || _isCanceling){
      return;
    }

    Analytics().logSelect(target: "Confirm phone number");
    _clearErrorMsg();
    _validateCode();
    if (StringUtils.isNotEmpty(_verificationErrorMsg)) {
      return;
    }
    String? phoneNumber = widget.phoneNumber;
    setState(() {
      _isConfirming = true;
    });

    Map<String, dynamic> creds = {
      "phone": phoneNumber,
      "code": _codeController.text,
    };
    Map<String, dynamic> params = {};
    Auth2().linkAccountAuthType(Auth2LoginType.phoneTwilio, creds, params).then((result) {
      if(mounted) {
        setState(() {
          _isConfirming = false;
        });
        if (result == Auth2LinkResult.succeeded) {
          _onPhoneVerified(Auth2PhoneSendCodeResult.succeeded);
        } else if (result == Auth2LinkResult.failedInvalid) {
          _onPhoneVerified(Auth2PhoneSendCodeResult.failedInvalid);
        } else {
          _onPhoneVerified(Auth2PhoneSendCodeResult.failed);
        }
      }
    });
  }

  void _onTapCancel() {
    if(_isConfirming || _isCanceling){
      return;
    }

    String phoneNumber = widget.phoneNumber ?? '';
    setState(() {
      _isCanceling = true;
    });

    Auth2().unlinkAccountAuthType(Auth2LoginType.phoneTwilio, phoneNumber).then((success) {
      if (mounted) {
        setState(() {
          _isCanceling = false;
        });
        if (success) {
          _finishedPhoneVerification();
        }
        else {
          setState(() {
            _verificationErrorMsg = Localization().getStringEx("panel.onboarding.confirm_phone.link.cancel.text", "Failed to remove phone number from your account.");
          });
        }
      }
    });
  }

  void _onPhoneVerified(Auth2PhoneSendCodeResult result) {
    if (result == Auth2PhoneSendCodeResult.failed) {
      setState(() {
        _verificationErrorMsg = Localization().getStringEx("panel.onboarding.confirm_phone.validation.server_error.text", "Failed to verify code. An unexpected error occurred.");
      });
    } else if (result == Auth2PhoneSendCodeResult.failedInvalid) {
      setState(() {
        _verificationErrorMsg = Localization().getStringEx("panel.onboarding.confirm_phone.validation.invalid.text", "Incorrect code.");
      });
    } else {
      _finishedPhoneVerification();
    }
  }

  void _finishedPhoneVerification() {
    if (widget.onFinish != null) {
      widget.onFinish!();
    }
  }

  void _validateCode() {
    String phoneNumberValue = _codeController.text;
    if (StringUtils.isEmpty(phoneNumberValue)) {
      setState(() {
        _verificationErrorMsg = Localization().getStringEx("panel.onboarding.confirm_phone.validation.phone_number.text", "Please, fill your code");
      });
      return;
    }
  }

  void _clearErrorMsg() {
    setState(() {
      _verificationErrorMsg = null;
    });
  }
}