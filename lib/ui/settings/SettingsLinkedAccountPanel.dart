import 'package:flutter/material.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class SettingsLinkedAccountPanel extends StatefulWidget{
  final Auth2Type? linkedAccount;
  final LinkAccountMode mode;

  const SettingsLinkedAccountPanel({Key? key, this.linkedAccount, required this.mode}) :super(key: key);


  @override
  State<StatefulWidget> createState() => _SettingsLinkedAccountState();
}

class _SettingsLinkedAccountState extends State<SettingsLinkedAccountPanel>{
  bool _isLoading = false;
  String _errorMsg = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: _title, leadingIconKey: HeaderBar.defaultLeadingIconKey),
        body: Column(children: <Widget>[
            Expanded(child:
              SingleChildScrollView(scrollDirection: Axis.vertical, child:
                Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(children:[
                    Row(children: [ Expanded(child:
                      Text(_description,
                        style: Styles().textStyles?.getTextStyle("widget.description.medium"),
                      )
                    )],),
                    Container(height: 48),
                    LinkAccountContentWidget(linkedAccount: _linkedAccount, onTapDisconnect: _onTapDisconnect, mode: widget.mode, isLoading: _isLoading,),
                    Container(height: 36),
                    Text(StringUtils.ensureNotEmpty(_errorMsg), style: Styles().textStyles?.getTextStyle("panel.settings.error.text")),
          ]))))]),);
  }

  void _onTapDisconnect(Auth2Type? account){
    if(_isLoading != true) {//Disable while loading
      SettingsDialog.show(context,
        title: Localization().getStringEx("panel.settings.link.login_prompt.title", "Sign In Required"),
        message: [ TextSpan(text: Localization().getStringEx("panel.settings.link.login_prompt.description", "For security, you must sign in again to confirm it's you before adding an alternate account.")), ],
        continueTitle: Localization().getStringEx("panel.settings.link.login_prompt.confirm.title", "Sign In"),
        onContinue: (List<String> selectedValues, OnContinueProgressController progressController) => _onTapDisconnectConfirmed(mode, progressController),
      );

      _clearErrorMsg();
      setState(() {
        _isLoading = true;
      });

      if (account?.identifier != null) {
        Auth2().unlinkAccountAuthType(_loginType, account!.identifier!).then(_handleResult);
      }
      else { //No Valid account identifier
        setErrorMsg(_defaultErrorMsg);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  //TODO: fix
  // void _onLinkPhoneOrEmailReloginConfirmed(SettingsLoginPhoneOrEmailMode mode, OnContinueProgressController progressController) {
  //   progressController(loading: true);
  //   _linkVerifySignIn().then((bool? result) {
  //     progressController(loading: false);
  //     _popToMe();
  //     if (result == true) {
  //       Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) => SettingsLoginPhoneOrEmailPanel(mode: mode, link: true, onFinish: () {
  //         _popToMe();
  //       },)),);
  //     }
  //   });
  // }
  //
  // Future<bool?> _linkVerifySignIn() async {
  //   if (Auth2().isOidcLoggedIn) {
  //     Auth2OidcAuthenticateResult? result = await Auth2().authenticateWithOidc();
  //     return (result != null) ? (result == Auth2OidcAuthenticateResult.succeeded) : null;
  //   }
  //   else if (Auth2().isEmailLoggedIn) {
  //     Completer<bool?> completer = Completer<bool?>();
  //     Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) =>
  //         SettingsLoginEmailPanel(email: Auth2().account?.authType?.identifier, state: Auth2EmailAccountState.verified, onFinish: () {
  //           completer.complete(true);
  //         },)
  //     ),).then((_) {
  //       completer.complete(null);
  //     });
  //     return completer.future;
  //   }
  //   else if (Auth2().isPhoneLoggedIn) {
  //     Completer<bool?> completer = Completer<bool?>();
  //     Auth2().authenticateWithPhone(Auth2().account?.authType?.identifier).then((Auth2PhoneRequestCodeResult result) {
  //       if (result == Auth2PhoneRequestCodeResult.succeeded) {
  //         Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) =>
  //             SettingsLoginPhoneConfirmPanel(phoneNumber: Auth2().account?.authType?.identifier, onFinish: () {
  //               completer.complete(true);
  //             },)
  //         ),).then((_) {
  //           completer.complete(null);
  //         });
  //       }
  //       else {
  //         AppAlert.showDialogResult(context, Localization().getStringEx("panel.onboarding2.phone_or_email.phone.failed", "Failed to send phone verification code. An unexpected error has occurred.")).then((_) {
  //           completer.complete(null);
  //         });
  //       }
  //     });
  //     return completer.future;
  //   }
  //   else {
  //     return null;
  //   }
  // }

  void _handleResult(bool? result){
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (result != null) {
      if (!result) {
        setErrorMsg(_defaultErrorMsg);
        return;
      }

      Navigator.of(context).pop();
    } else {
      setErrorMsg(_defaultErrorMsg);
    }
  }

  void setErrorMsg(String msg){
    setState(() {
      if(mounted){
        _errorMsg = msg;
      }
    });
  }

  void _clearErrorMsg(){
    setState(() {
      if(mounted){
        _errorMsg = "";
      }
    });
  }

  String get _title{
    switch (widget.mode){
      case LinkAccountMode.phone: return Localization().getStringEx("panel.settings.linked.phone.label.title", "Alternate Phone Number");
      case LinkAccountMode.email: return Localization().getStringEx("panel.settings.linked.email.label.title", "Alternate Email");
    }
  }

  String get _description{
    switch (widget.mode){
      case LinkAccountMode.phone: return Localization().getStringEx("panel.settings.linked.phone.label.description",
          "You may sign in using your phone number as an alternate way to sign in. Some features of the {{app_title}} App will not be available unless you login with your NetID.").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'));
      case LinkAccountMode.email: return Localization().getStringEx("panel.settings.linked.email.label.description",
          "You may sign in using your email as an alternate way to sign in. Some features of the {{app_title}} App will not be available unless you login with your NetID.").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois'));
    }
  }

  String get _defaultErrorMsg{
    switch (widget.mode){
      case LinkAccountMode.phone: return Localization().getStringEx("panel.settings.linked.phone.label.failed", "Failed to disconnect phone");
      case LinkAccountMode.email: return Localization().getStringEx("panel.settings.linked.email.label.failed", "Failed to disconnect email");
    }
  }

  Auth2Type? get _linkedAccount{
    return widget.linkedAccount;
  }

  Auth2LoginType get _loginType{
    switch (widget.mode){
      case LinkAccountMode.phone: return Auth2LoginType.phoneTwilio;
      case LinkAccountMode.email: return Auth2LoginType.email;
    }
  }
}

class LinkAccountContentWidget extends StatelessWidget{
  final LinkAccountMode mode;
  final Auth2Type? linkedAccount;
  final bool isLoading;
  final void Function(Auth2Type?)? onTapDisconnect;

  const LinkAccountContentWidget({Key? key, this.linkedAccount, this.onTapDisconnect, required this.mode, required this.isLoading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Styles().colors!.lightGray!),borderRadius: BorderRadius.all(Radius.circular(4))),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 13),
            color: Styles().colors!.white,
            child: Column(
              children: [
                Container(height: 12,),
                Row(
                  children: [
                    Expanded(child: Text(_accountTypeText, style: Styles().textStyles?.getTextStyle("panel.settings.link_account.type.title")))
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text(_identifier, style: Styles().textStyles?.getTextStyle("widget.detail.regular.fat") ))
                  ],
                ),
                Container(height: 12,),
              ],
            ),
          ),
          Container(height: 1, color: Styles().colors?.lightGray!,),
          Container(
            color: Styles().colors!.white,
            child: RibbonButton(
              textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat.secondary"),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              label: _buttonText,
              progress: isLoading,
              onTap: (){
                if(onTapDisconnect!=null){
                  onTapDisconnect!(linkedAccount);
                }
              },
            ),
          )
        ],
      ),
    );
  }

  String get _accountTypeText{
    switch(mode){
      case LinkAccountMode.phone: return Localization().getStringEx("panel.settings.linked.phone.field.label.phone","Phone");
      case LinkAccountMode.email: return Localization().getStringEx("panel.settings.linked.email.field.label.email","Email");
    }
  }

  String get _buttonText{
    switch(mode){
      case LinkAccountMode.phone: return Localization().getStringEx("panel.settings.linked.phone.button.label.phone", "Remove this Phone Number");
      case LinkAccountMode.email: return Localization().getStringEx("panel.settings.linked.email.button.label.email", "Remove this Email Address");
    }
  }

  String get _identifier{
    return linkedAccount?.identifier ?? "";
  }
}

enum LinkAccountMode { phone, email, }