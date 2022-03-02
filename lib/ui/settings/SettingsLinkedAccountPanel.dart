import 'package:flutter/material.dart';
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
        appBar: HeaderBar(title: _title, leadingAsset: HeaderBar.defaultLeadingAsset),
        body: Column(children: <Widget>[
            Expanded(child:
              SingleChildScrollView(scrollDirection: Axis.vertical, child:
                Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(children:[
                    Row(children: [ Expanded(child:
                      Text(_description,
                        style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 18, color: Styles().colors!.fillColorPrimary),
                      )
                    )],),
                    Container(height: 48),
                    LinkAccountContentWidget(linkedAccount: _linkedAccount, onTapDisconnect: _onTapDisconnect, mode: widget.mode, isLoading: _isLoading,),
                    Container(height: 36),
                    Text(StringUtils.ensureNotEmpty(_errorMsg), style: TextStyle(color: Colors.red, fontSize: 16, fontFamily: Styles().fontFamilies!.bold),),
          ]))))]),);
  }

  void _onTapDisconnect(Auth2Type? account){
    if(_isLoading != true) {//Disable while loading
      _clearErrorMsg();
      setState(() {
        _isLoading = true;
      });

      if (widget.mode == LinkAccountMode.email && account?.email != null) {
        Auth2()
            .unlinkAccountAuthType(Auth2LoginType.email, account!.email!)
            .then(_handleResult);
      }
      else if (widget.mode == LinkAccountMode.phone && account?.phone != null) {
        Auth2().unlinkAccountAuthType(
            Auth2LoginType.phoneTwilio, account!.phone!).then(_handleResult);
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
          "You may sign in using your phone number as an alternate way to sign in. Some features of the Illinois App will not be available unless you login with your NetID.");
      case LinkAccountMode.email: return Localization().getStringEx("panel.settings.linked.email.label.description",
          "You may sign in using your email as an alternate way to sign in. Some features of the Illinois App will not be available unless you login with your NetID.");
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
                    Expanded(child: Text(_accountTypeText, style: TextStyle(color: Styles().colors!.textSurface, fontSize: 14, fontFamily: Styles().fontFamilies!.regular,)))
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text(_identifier, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold,)))
                  ],
                ),
                Container(height: 12,),
              ],
            ),
          ),
          Container(height: 1, color: Styles().colors?.lightGray!,),
          Container(
            color: Styles().colors!.white,
            child:
            Stack(children: [
              RibbonButton(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                textColor: Styles().colors!.textSurface,
                label: _buttonText,
                onTap: (){
                  if(onTapDisconnect!=null){
                    onTapDisconnect!(linkedAccount);
                  }
                },
              ),
              Visibility(visible: isLoading,
                  child: Container(height: 58, child:
                    Align(alignment: Alignment.centerRight, child:
                      Padding(padding: EdgeInsets.only(right: 10), child:
                        SizedBox(height: 24, width: 24, child:
                          CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), )
                  ),)),),)
            ],),
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