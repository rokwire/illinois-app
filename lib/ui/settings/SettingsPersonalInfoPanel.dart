/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/utils/Utils.dart';

class SettingsPersonalInfoPanel extends StatefulWidget {
  _SettingsPersonalInfoPanelState createState() => _SettingsPersonalInfoPanelState();
}

class _SettingsPersonalInfoPanelState extends State<SettingsPersonalInfoPanel> {

  TextEditingController _nameController;
  TextEditingController _emailController;
  String _initialName;
  String _initialEmail;

  //bool _isDeleting = false;
  bool _isSaving = false;

  @override
  void initState() {
    _initTextControllers();
    super.initState();
  }

  Future<void> _deleteUserData() async{
    Analytics.instance.logAlert(text: "Remove My Information", selection: "Yes");

    bool piiDeleted = await Auth2().deleteUser();
    if(piiDeleted) {
      await User().deleteUser();
    }
    Auth2().logout();
  }

  void _initTextControllers(){
    _nameController = TextEditingController();
    _emailController = TextEditingController();

    _nameController.text = _initialName = Auth2().user?.profile?.fullName ?? "";
    _emailController.text = _initialEmail = Auth2().user?.account?.email ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx("panel.profile_info.header.title", "PERSONAL INFO"),
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0),
        ),
      ),
      body: Column(children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                child: _showShibbolethInfo? _buildShibolethInfoContent() : _buildPhoneVerifiedInfoContent()
              ),
            ),
          ),
        ),
        _showShibbolethInfo? _buildShibbolethAccountManagementOptions() : _buildPhoneAccountManagementOptions(),
        Container(height: 16,)
      ],),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildShibolethInfoContent(){
    return Container(
      child: Column(
        children: <Widget>[
          _PersonalInfoEntry(
              title: Localization().getStringEx('panel.profile_info.net_id.title', 'NetID'),
              value: Auth2().user?.uiucAccount?.username ?? ""
          ),
          _PersonalInfoEntry(
              title: Localization().getStringEx('panel.profile_info.full_name.title', 'Full Name'),
              value: Auth2().user?.uiucAccount?.fullName ?? ""),
          _PersonalInfoEntry(
              title: Localization().getStringEx('panel.profile_info.middle_name.title', 'Middle Name'),
              value: Auth2().user?.uiucAccount?.middleName ?? ""),
          _PersonalInfoEntry(
              title: Localization().getStringEx('panel.profile_info.last_name.title', 'Last Name'),
              value:  Auth2().user?.uiucAccount?.lastName ?? ""),
          _PersonalInfoEntry(
              title: Localization().getStringEx('panel.profile_info.email_address.title', 'Email Address'),
              value: Auth2().user?.uiucAccount?.email ?? ""),
        ],
      ),
    );
  }

  Widget _buildPhoneVerifiedInfoContent(){
    return Container(
      child:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(height: 32,),
          Semantics(label:Localization().getStringEx("panel.profile_info.phone_number.name.title","Full Name"),
              header: true, excludeSemantics: true, child:
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child:
                    Text(
                      Localization().getStringEx("panel.profile_info.phone_number.name.title","Full Name"),
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          color: Styles().colors.fillColorPrimary,
                          fontSize: 12,
                          fontFamily: Styles().fontFamilies.bold,
                          letterSpacing: 1),
                    )
              )
          ),
          Semantics(label:Localization().getStringEx("panel.profile_info.phone_number.name.title","Full Name"),
              hint: Localization().getStringEx("panel.profile_info.phone_number.name.hint",""), textField: true, excludeSemantics: true, child:
              Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: Styles().colors.fillColorPrimary,
                          width: 1)),
//                  height: 48,
                  child: TextField(
                    controller: _nameController,
                    onChanged: (text){ setState(() {});},
                    decoration: InputDecoration(
                        border: InputBorder.none),
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    style: TextStyle(
                        color: Styles().colors.textSurface,
                        fontSize: 16,
                        fontFamily: Styles().fontFamilies.regular),
                  ),
              )
          ),
          Container(height: 33,),
          Semantics(label:Localization().getStringEx("panel.profile_info.phone_number.email.title","Email"),
              header: true, excludeSemantics: true, child:
              Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child:
                  Text(
                    Localization().getStringEx("panel.profile_info.phone_number.email.title","Email"),
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: Styles().colors.fillColorPrimary,
                        fontSize: 12,
                        fontFamily: Styles().fontFamilies.bold,
                        letterSpacing: 1),
                  )
              )
          ),
          Semantics(label:Localization().getStringEx("panel.profile_info.phone_number.email.title","Email"),
              hint: Localization().getStringEx("panel.profile_info.phone_number.email.hint",""), textField: true, excludeSemantics: true, child:
              Container(
                padding:
                EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                    border: Border.all(
                        color: Styles().colors.fillColorPrimary,
                        width: 1)),
//                height: 48,
                child: TextField(
                  controller: _emailController,
                  onChanged: (text){ setState(() {});},
                  decoration: InputDecoration(
                      border: InputBorder.none),
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  style: TextStyle(
                      color: Styles().colors.textSurface,
                      fontSize: 16,
                      fontFamily: Styles().fontFamilies.regular),
                ),
              )
          ),
          _PersonalInfoEntry(
              visible: Auth2().isPhoneLoggedIn,
              title: Localization().getStringEx("panel.profile_info.phone_number.title", "Phone Number"),
              value: Auth2().user?.account?.phone ?? ""),
        ],
      ),
    );
  }

  //AccountManagementOptions
  Widget _buildShibbolethAccountManagementOptions() {
    return
      Padding(
        padding: EdgeInsets.symmetric( vertical: 5, horizontal: 16),
        child: ScalableRoundedButton(
          label: Localization().getStringEx("panel.profile_info.button.sign_out.title", "Sign Out"),
          hint: Localization().getStringEx("panel.profile_info.button.sign_out.hint", ""),
          backgroundColor: Styles().colors.background,
          fontSize: 16.0,
          textColor: Styles().colors.fillColorPrimary,
          borderColor: Styles().colors.fillColorSecondary,
          onTap: _onSignOutClicked,
        ),
      );
  }

  Widget _buildPhoneAccountManagementOptions() {
    return
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child:Row(
          children: <Widget>[
            Expanded(child:
              Padding(
                  padding: EdgeInsets.symmetric( vertical: 5),
                  child:
                  Stack(children: <Widget>[
                    ScalableRoundedButton(
                      label: Localization().getStringEx("panel.profile_info.button.save.title", "Save Changes"),
                      hint: Localization().getStringEx("panel.profile_info.button.save.hint", ""),
                      enabled: _canSave,
                      backgroundColor: _canSave ? Styles().colors.white : Styles().colors.background,
                      fontSize: 16.0,
                      textColor: _canSave? Styles().colors.fillColorPrimary : Styles().colors.surfaceAccent,
                      borderColor: _canSave? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
                      onTap: _onSaveChangesClicked,
                    ),
                    Visibility(
                        visible:_isSaving,
                        child: Align(alignment: Alignment.center,
                          child:Container(
                            padding: EdgeInsets.all(4),
                            child: Center(child:
                            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorSecondary), strokeWidth: 2,),),),
                        ))
                  ],)
                  ,
              ),
            ),
            Container(width: 12,),
            Expanded(
              child:Padding(
                padding: EdgeInsets.symmetric( vertical: 5),
                child: ScalableRoundedButton(
                  label: Localization().getStringEx("panel.profile_info.button.sign_out.title", "Sign Out"),
                  hint: Localization().getStringEx("panel.profile_info.button.sign_out.hint", ""),
                  backgroundColor: Styles().colors.white,
                  fontSize: 16.0,
                  textColor: Styles().colors.fillColorPrimary,
                  borderColor: Styles().colors.fillColorSecondary,
                  onTap: _onSignOutClicked,
                ),
              )
            ),
          ],
    ));
  }

  Widget _buildLogoutDialog(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              Localization().getStringEx("panel.profile_info.logout.title", "Illinois"),
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Text(
                Localization().getStringEx("panel.profile_info.logout.message", "Are you sure you want to sign out?"),
                textAlign: TextAlign.left,
                style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Colors.black),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                    onPressed: () {
                      Analytics.instance.logAlert(text: "Sign out", selection: "Yes");
                      Navigator.pop(context);
                      Auth2().logout();
                    },
                    child: Text(Localization().getStringEx("panel.profile_info.logout.button.yes", "Yes"))),
                TextButton(
                    onPressed: () {
                      Analytics.instance.logAlert(text: "Sign out", selection: "No");
                      Navigator.pop(context);
                    },
                    child: Text(Localization().getStringEx("panel.profile_info.logout.no", "No")))
              ],
            ),
          ],
        ),
      ),
    );
  }

  void onConfirmRemoveMyInfo(BuildContext context, Function setState){
    setState(() {
      //_isDeleting = true;
    });
    _deleteUserData()
        .then((_){
          Navigator.pop(context);
        })
        .whenComplete((){
          setState(() {
            //_isDeleting = false;
          });
        })
        .catchError((error){
          AppAlert.showDialogResult(context, error.toString()).then((_){
            Navigator.pop(context);
          });
    });
  }

  _onSignOutClicked() {
    showDialog(context: context, builder: (context) => _buildLogoutDialog(context));
  }

  _onSaveChangesClicked() async{
    /* TBD Auth2: update user profile in Auth2
    bool piiDataUpdated = false;
    setState(() {
      _isSaving = true;
    });
    UserPiiData updatedUserPiiData;
    UserPiiData userPiiData = UserPiiData.fromObject(await Auth2().reloadUserPiiData());
    if (userPiiData != null) {
      if(_isEmailChanged){
        userPiiData.email = _customEmail;
        piiDataUpdated = true;
      }
      if(_isNameChanged){
        String firstName="";
        String middleName="";
        String lastName="";
        String fullName = _customFullName;

        //split names
        List<String> splitNames = fullName.split(" ");
        int namesLength = (splitNames?.length ?? 0);
        if(namesLength > 3){
          //Not sure if possible but handle the case
          //Everything after first and middle name will be last name containing spaces
          firstName = splitNames[0];
          middleName = splitNames[1];
          splitNames.forEach((element) {
            if(splitNames.indexOf(element)>1){
              lastName += "$element ";
            }
          });
        } else if (namesLength == 3) {
          firstName = splitNames[0];
          middleName = splitNames[1];
          lastName = splitNames[2];
        } else if (namesLength == 2) {
          firstName = splitNames[0];
          lastName = splitNames[1];
        } else {
          firstName = fullName;
        }

        //populate names to PiiData
        userPiiData.firstName = firstName;
        userPiiData.middleName = middleName;
        userPiiData.lastName = lastName;
        piiDataUpdated = true;
      }

      if(piiDataUpdated) {
        updatedUserPiiData = await Auth2().storeUserPiiData(userPiiData);
      }
    }
    setState(() {
      _isSaving = false;
    });
    if(updatedUserPiiData != null){
      Navigator.pop(context);
    } else {
      AppToast.show("Unable to perform save");
    }*/
  }

  bool get _canSave{
    return _isEmailChanged || _isNameChanged;
  }

  bool get _isNameChanged{
    return (_initialName!= _customFullName);
  }
  
  bool get _isEmailChanged{
    return (_initialEmail!= _customEmail);
  }
  
  String get _customEmail {
      return _emailController?.value?.text??"";
  }
  
  String get _customFullName {
    return _nameController?.value?.text??"";
  }
  
  bool get _showShibbolethInfo{
    return Auth2().isOidcLoggedIn;
  }

}

class _PersonalInfoEntry extends StatelessWidget {
  final String title;
  final String value;
  final bool visible;

  _PersonalInfoEntry({this.title, this.value, this.visible = true});

  @override
  Widget build(BuildContext context) {
    return visible
        ? Container(
            margin: EdgeInsets.only(top: 25),
            child: Row(
              children: <Widget>[
                Expanded(child:
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                          fontFamily: Styles().fontFamilies.medium,
                          fontSize: 14,
                          letterSpacing: 0.5,
                          color: Styles().colors.textBackground),
                    ),
                    Container(
                      height: 5,
                    ),
                    Text(
                      value,
                      style:
                          TextStyle(fontSize: 20, color: Styles().colors.fillColorPrimary),
                    )
                  ],
                )
                ),
              ],
            ),
        )
        : Container();
  }
}
