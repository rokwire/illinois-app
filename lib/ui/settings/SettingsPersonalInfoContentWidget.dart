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

import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:illinois/ui/groups/ImageEditPanel.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SettingsPersonalInfoContentWidget extends StatefulWidget {
  _SettingsPersonalInfoContentWidgetState createState() => _SettingsPersonalInfoContentWidgetState();
}

class _SettingsPersonalInfoContentWidgetState extends State<SettingsPersonalInfoContentWidget> implements NotificationsListener {

  TextEditingController? _nameController;
  TextEditingController? _emailController;
  TextEditingController? _phoneController;
  String? _initialName;
  String? _initialEmail;
  String? _initialPhone;

  Uint8List? _profileImageBytes;

  bool _isSaving = false;
  bool _profilePicProcessing = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [Auth2.notifyLogout]);
    _nameController = TextEditingController(text: _initialName = Auth2().fullName ?? "");
    _emailController = TextEditingController(text: _initialEmail = Auth2().email ?? "");
    _phoneController = TextEditingController(text: _initialPhone = Auth2().phone ?? "");
    _loadUserProfilePicture();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _nameController!.dispose();
    _emailController!.dispose();
    _phoneController!.dispose();
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyLogout) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Container(child: Column(children: [_buildProfilePicture(), _buildInfoContent()])),
      _buildAccountManagementOptions(),
      _buildDeleteMyAccount()
    ]);
  }

  Widget _buildInfoContent() {
    late Widget contentWidget;
    if (Auth2().isOidcLoggedIn) {
      contentWidget = _buildShibbolethInfoContent();
    }
    else if (Auth2().isPhoneLoggedIn) {
      contentWidget = _buildPhoneVerifiedInfoContent();
    }
    else if (Auth2().isEmailLoggedIn) {
      contentWidget = _buildEmailLoginInfoContent();
    }
    else {
      contentWidget = Container();
    }
    return Padding(padding: EdgeInsets.only(bottom: 25), child: contentWidget);
  }

  Widget _buildShibbolethInfoContent(){
    return Container(
      child: Column(
        children: <Widget>[
          _PersonalInfoEntry(
              title: Localization().getStringEx('panel.profile_info.net_id.title', 'UIN'),
              value: Auth2().account?.authType?.uiucUser?.identifier ?? ""
          ),
          _PersonalInfoEntry(
              title: Localization().getStringEx('panel.profile_info.full_name.title', 'Full Name'),
              value: Auth2().account?.authType?.uiucUser?.fullName ?? ""),
          _PersonalInfoEntry(
              title: Localization().getStringEx('panel.profile_info.middle_name.title', 'Middle Name'),
              value: Auth2().account?.authType?.uiucUser?.middleName ?? ""),
          _PersonalInfoEntry(
              title: Localization().getStringEx('panel.profile_info.last_name.title', 'Last Name'),
              value:  Auth2().account?.authType?.uiucUser?.lastName ?? ""),
          _PersonalInfoEntry(
              title: Localization().getStringEx('panel.profile_info.email_address.title', 'Email Address'),
              value: Auth2().account?.authType?.uiucUser?.email ?? ""),
          _PersonalInfoEntry(
              title: Localization().getStringEx('panel.profile_info.college.title', 'College'),
              value: IlliniCash().studentClassification?.collegeName ?? ""),
        ],
      ),
    );
  }

  Widget _buildPhoneVerifiedInfoContent(){
    return Container(child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Container(height: 32,),
        Semantics(label: Localization().getStringEx("panel.profile_info.phone_or_email.name.title","Full Name"), header: true, excludeSemantics: true, child:
          Padding(padding: EdgeInsets.only(bottom: 8), child:
            Text(Localization().getStringEx("panel.profile_info.phone_or_email.name.title","Full Name"), textAlign: TextAlign.left, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 12, fontFamily: Styles().fontFamilies!.bold, letterSpacing: 1),)
          )
        ),
        Semantics(
          label: Localization().getStringEx("panel.profile_info.phone_or_email.name.title","Full Name"),
          hint: Localization().getStringEx("panel.profile_info.phone_or_email.name.hint",""),
          textField: true, excludeSemantics: true,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1)),
//          height: 48,
            child: TextField(
              controller: _nameController,
              onChanged: (text) { setState(() {});},
              decoration: InputDecoration(border: InputBorder.none),
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              style: TextStyle(color: Styles().colors!.textSurface, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
            ),
          )
          ),
          Container(height: 33,),
          Semantics(
            label: Localization().getStringEx("panel.profile_info.phone_or_email.email.title", "Email Address"),
            //hint: Localization().getStringEx("panel.profile_info.phone_or_email.email.hint", ""),
            header: true, excludeSemantics: true,
               child: Padding(padding: EdgeInsets.only(bottom: 8),
                 child: Text(Localization().getStringEx("panel.profile_info.phone_or_email.email.title","Email Address"), textAlign: TextAlign.left,
                    style: TextStyle( color: Styles().colors!.fillColorPrimary, fontSize: 12, fontFamily: Styles().fontFamilies!.bold, letterSpacing: 1),)
              )
          ),
          Semantics(
            label:Localization().getStringEx("panel.profile_info.phone_or_email.email.title","Email Address"),
            hint: Localization().getStringEx("panel.profile_info.phone_or_email.email.hint",""),
            textField: true, excludeSemantics: true,
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1)),
//                height: 48,
                child: TextField(
                  controller: _emailController,
                  onChanged: (text) { setState(() {});},
                  decoration: InputDecoration(border: InputBorder.none),
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  style: TextStyle(color: Styles().colors!.textSurface, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
                ),
              )
          ),
          _PersonalInfoEntry(
              visible: Auth2().isPhoneLoggedIn,
              title: Localization().getStringEx("panel.profile_info.phone_number.title", "Phone Number"),
              value: Auth2().account?.authType?.phone ?? ""),
        ],
      ),
    );
  }

  Widget _buildEmailLoginInfoContent(){
    return Container(child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Container(height: 32,),
        Semantics(label: Localization().getStringEx("panel.profile_info.phone_or_email.name.title","Full Name"), header: true, excludeSemantics: true, child:
          Padding(padding: EdgeInsets.only(bottom: 8), child:
            Text(Localization().getStringEx("panel.profile_info.phone_or_email.name.title","Full Name"), textAlign: TextAlign.left, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 12, fontFamily: Styles().fontFamilies!.bold, letterSpacing: 1),)
          )
        ),
        Semantics(
          label: Localization().getStringEx("panel.profile_info.phone_or_email.name.title","Full Name"),
          hint: Localization().getStringEx("panel.profile_info.phone_or_email.name.hint",""),
          textField: true, excludeSemantics: true,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1)),
//          height: 48,
            child: TextField(
              controller: _nameController,
              onChanged: (text) { setState(() {});},
              decoration: InputDecoration(border: InputBorder.none),
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              style: TextStyle(color: Styles().colors!.textSurface, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
            ),
          )
          ),
          Container(height: 33,),
          Semantics(
            label: Localization().getStringEx("panel.profile_info.phone_or_email.phone.title", "Phone Number"),
            //hint: Localization().getStringEx("panel.profile_info.phone_or_email.phone.hint", ""),
            header: true, excludeSemantics: true,
               child: Padding(padding: EdgeInsets.only(bottom: 8),
                 child: Text(Localization().getStringEx("panel.profile_info.phone_or_email.phone.title","Phone Number"), textAlign: TextAlign.left, style: TextStyle( color: Styles().colors!.fillColorPrimary, fontSize: 12, fontFamily: Styles().fontFamilies!.bold, letterSpacing: 1),)
              )
          ),
          Semantics(
            label:Localization().getStringEx("panel.profile_info.phone_or_email.phone.title","Phone Number"),
            hint: Localization().getStringEx("panel.profile_info.phone_or_email.phone.hint",""),
            textField: true, excludeSemantics: true,
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1)),
//                height: 48,
                child: TextField(
                  controller: _emailController,
                  onChanged: (text) { setState(() {});},
                  decoration: InputDecoration(border: InputBorder.none),
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  style: TextStyle(color: Styles().colors!.textSurface, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
                ),
              )
          ),
          _PersonalInfoEntry(
              visible: Auth2().isEmailLoggedIn,
              title: Localization().getStringEx("panel.profile_info.email.title", "Email Address"),
              value: Auth2().account?.authType?.email ?? ""),
        ],
      ),
    );
  }

  //AccountManagementOptions

  Widget _buildAccountManagementOptions() {
    if (Auth2().isOidcLoggedIn) {
      return _buildShibbolethAccountManagementOptions();
    }
    else if (Auth2().isPhoneLoggedIn) {
      return _buildPhoneOrEmailAccountManagementOptions();
    }
    else if (Auth2().isEmailLoggedIn) {
      return _buildPhoneOrEmailAccountManagementOptions();
    }
    else {
      return Container();
    }
  }

  Widget _buildShibbolethAccountManagementOptions() {
    return
      Padding(
        padding: EdgeInsets.symmetric(vertical: 5),
        child: RoundedButton(
          label: Localization().getStringEx("panel.profile_info.button.sign_out.title", "Sign Out"),
          hint: Localization().getStringEx("panel.profile_info.button.sign_out.hint", ""),
          backgroundColor: Styles().colors!.background,
          fontSize: 16.0,
          textColor: Styles().colors!.fillColorPrimary,
          borderColor: Styles().colors!.fillColorSecondary,
          onTap: _onSignOutClicked,
        ),
      );
  }

  Widget _buildPhoneOrEmailAccountManagementOptions() {
    return Container(child:
      Row(children: <Widget>[
        Expanded(child:
          Padding(padding: EdgeInsets.symmetric(vertical: 5), child:
            RoundedButton(
              label: Localization().getStringEx("panel.profile_info.button.save.title", "Save Changes"),
              hint: Localization().getStringEx("panel.profile_info.button.save.hint", ""),
              enabled: _canSave,
              backgroundColor: _canSave ? Styles().colors!.white : Styles().colors!.background,
              fontSize: 16.0,
              textColor: _canSave? Styles().colors!.fillColorPrimary : Styles().colors!.surfaceAccent,
              borderColor: _canSave? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
              progress: _isSaving,
              onTap: _onSaveChangesClicked,
            ),
          ),
        ),
        Container(width: 12,),
        Expanded(child:
          Padding(padding: EdgeInsets.symmetric(vertical: 5), child:
            RoundedButton(
              label: Localization().getStringEx("panel.profile_info.button.sign_out.title", "Sign Out"),
              hint: Localization().getStringEx("panel.profile_info.button.sign_out.hint", ""),
              backgroundColor: Styles().colors!.white,
              fontSize: 16.0,
              textColor: Styles().colors!.fillColorPrimary,
              borderColor: Styles().colors!.fillColorSecondary,
              onTap: _onSignOutClicked,
            ),
          ),
        ),
      ],),
    );
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
                style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Colors.black),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                    onPressed: () {
                      Analytics().logAlert(text: "Sign out", selection: "Yes");
                      Navigator.pop(context);
                      Auth2().logout();
                    },
                    child: Text(Localization().getStringEx("panel.profile_info.logout.button.yes", "Yes"))),
                TextButton(
                    onPressed: () {
                      Analytics().logAlert(text: "Sign out", selection: "No");
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

  Widget _buildProfilePicture() {
    late Widget contentWidget;
    if (_profilePicProcessing) {
      contentWidget = Center(child: CircularProgressIndicator());
    } else {
      Image profileImage = _hasProfilePicture
          ? Image.memory(_profileImageBytes!)
          : Image.asset('images/missing-photo-placeholder.png', excludeFromSemantics: true);
      contentWidget = Padding(
          padding: EdgeInsets.only(bottom: 25),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Visibility(
                  visible: _hasProfilePicture,
                  child: Padding(
                      padding: EdgeInsets.only(right: 24),
                      child: _buildProfileImageButton(
                          Localization().getStringEx("panel.profile_info.button.picture.edit.title", "Edit"),
                          Localization().getStringEx("panel.profile_info.button.picture.edit.hint", "Edit profile picture"),
                          _onTapEditPicture))),
              Expanded(child: Container(
                  width: 189,
                  height: 189,
                  child: Semantics (
                    image: true,
                    label: "Profile",
                    child: Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          image: DecorationImage(fit: BoxFit.cover, image: profileImage.image)))))),
              Visibility(
                  visible: _hasProfilePicture,
                  child: Padding(
                      padding: EdgeInsets.only(left: 24),
                      child: _buildProfileImageButton(
                          Localization().getStringEx("panel.profile_info.button.picture.delete.title", "Delete"),
                          Localization().getStringEx("panel.profile_info.button.picture.delete.hint", "Delete profile picture"),
                          _onTapDeletePicture)))
            ]),
            Visibility(
                visible: !_hasProfilePicture,
                child: Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: _buildProfileImageButton(
                        Localization().getStringEx("panel.profile_info.button.profile_picture.title", "Set Profile Picture"),
                        Localization().getStringEx("panel.profile_info.button.profile_picture.hint", ""),
                        _onTapProfilePicture)))
          ]));
    }
    return Padding(padding: EdgeInsets.only(top: 25), child: contentWidget);
  }

  Widget _buildProfileImageButton(String title, String hint, GestureTapCallback? onTap) {
    return Semantics(label: title, hint: hint, button: true,
        child: GestureDetector(
        onTap: onTap,
        child: Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors!.fillColorSecondary!, width: 1))),
            padding: EdgeInsets.only(bottom: 2),
            child: Text(title,
                semanticsLabel: "",
                style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 16, color: Styles().colors!.textBackground)))));
  }

  void _loadUserProfilePicture() {
    _setProfilePicProcessing(true);
    Content().loadDefaultUserProfileImage().then((imageBytes) {
      _profileImageBytes = imageBytes;
      _setProfilePicProcessing(false);
    });
  }

  void _setProfilePicProcessing(bool processing) {
    if (_profilePicProcessing != processing) {
      _profilePicProcessing = processing;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onSignOutClicked() {
    showDialog(context: context, builder: (context) => _buildLogoutDialog(context));
  }

  void _onSaveChangesClicked() async{

    String? email, phone, firstName, lastName, middleName;
    if (_isEmailChanged){
      email = _customEmail;
    }

    if (_isPhoneChanged){
      phone = _customPhone;
    }

    if (_isNameChanged){
      String fullName = _customFullName;

      //split names
      List<String> splitNames = fullName.split(" ");
      int namesLength = splitNames.length;
      if(namesLength > 3){
        //Not sure if possible but handle the case
        //Everything after first and middle name will be last name containing spaces
        firstName = splitNames[0];
        middleName = splitNames[1];
        lastName = "";
        splitNames.forEach((element) {
          if(splitNames.indexOf(element)>1){
            lastName = lastName! + "$element ";
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
    }

    setState(() { _isSaving = true; });

    Auth2().loadUserProfile().then((Auth2UserProfile? userProfile) {
      if (mounted) {
        if (userProfile != null) {
          Auth2UserProfile? updatedUserProfile = Auth2UserProfile.fromOther(userProfile,
            email: email,
            phone: phone,
            firstName: firstName,
            middleName: middleName,
            lastName: lastName,
          );
          if (userProfile != updatedUserProfile) {
            Auth2().saveAccountUserProfile(updatedUserProfile).then((bool result) {
              if (mounted) {
                setState(() { _isSaving = false; });
                if (result == true) {
                  Navigator.pop(context);
                } else {
                  AppToast.show("Unable to perform save");
                }
              }
            });
          }
          else {
            setState(() { _isSaving = false; });
            Navigator.pop(context);
          }
        }
        else {
          setState(() { _isSaving = false; });
          AppToast.show("Unable to perform save");
        }
      }
    });
  }

  void _onTapProfilePicture() {
    Analytics().logSelect(target: "Profile Picture");
    _onChangeProfilePicture();
  }

  void _onTapEditPicture() {
    Analytics().logSelect(target: "Edit Profile Picture");
    _onChangeProfilePicture();
  }

  void _onChangeProfilePicture() {
    _setProfilePicProcessing(true);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ImageEditPanel(isUserPic: true))).then(
      (imageUploadResult) {
        if(imageUploadResult != null) {
          ImagesResultType? resultType = imageUploadResult?.resultType;
          switch (resultType) {
            case ImagesResultType.cancelled:
              _setProfilePicProcessing(false);
              break;
            case ImagesResultType.error:
              AppAlert.showDialogResult(
                  context,
                  Localization().getStringEx(
                      'panel.profile_info.picture.upload.failed.msg',
                      'Failed to upload profile picture. Please, try again later.'));
              _setProfilePicProcessing(false);
              break;
            case ImagesResultType.succeeded:
              _loadUserProfilePicture();
              break;
            default:
              break;
          }
        } else {
          _setProfilePicProcessing(false);
        }
      });
  }

  void _onTapDeletePicture() {
    Analytics().logSelect(target: "Delete Profile Picture");
    _setProfilePicProcessing(true);
    Content().deleteCurrentUserProfileImage().then((deleteImageResult) {
      ImagesResultType? resultType = deleteImageResult.resultType;
      switch (resultType) {
        case ImagesResultType.error:
          AppAlert.showDialogResult(
              context,
              Localization().getStringEx(
                  'panel.profile_info.picture.delete.failed.msg', 'Failed to delete profile picture. Please, try again later.'));
          _setProfilePicProcessing(false);
          break;
        case ImagesResultType.succeeded:
          _profileImageBytes = null;
          _setProfilePicProcessing(false);
          break;
        default:
          _setProfilePicProcessing(false);
          break;
      }
    });
  }

  Widget _buildDeleteMyAccount() {
    return Padding(padding: EdgeInsets.only(top: 24, bottom: 12), child:
    RoundedButton(
        backgroundColor: Styles().colors!.white,
        borderColor: Styles().colors!.white,
        textColor: UiColors.fromHex("#f54400"),
        fontSize: 16,
        fontFamily: Styles().fontFamilies!.regular,
        label: Localization().getStringEx("panel.settings.privacy_center.button.delete_data.title", "Delete My Account"),
        hint: Localization().getStringEx("panel.settings.privacy_center.label.delete.description", "This will delete all of your personal information that was shared and stored within the app."),
        borderShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))],
        onTap: _onTapDeleteData
      )
    );
  }

  void _onTapDeleteData() async {
    final String groupsSwitchTitle = Localization().getStringEx('panel.settings.privacy_center.delete_account.contributions.delete.msg', 'Please delete all my contributions.');
    int userPostCount = await Groups().getUserPostCount();
    bool contributeInGroups = userPostCount > 0;

    SettingsDialog.show(context,
        title: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.title", "Delete your account?"),
        message: [
          TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description1", "This will ")),
          TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description2", "Permanently "),style: TextStyle(fontFamily: Styles().fontFamilies!.bold)),
          TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description3", "delete all of your information. You will not be able to retrieve your data after you have deleted it. Are you sure you want to continue?")),
          TextSpan(text: contributeInGroups?
          Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description.groups", " You have contributed to Groups. Do you wish to delete all of those entries (posts, replies, and events) or leave them for others to see.") :
          ""
          ),
        ],
        options:contributeInGroups ? [groupsSwitchTitle] : null,
        initialOptionsSelection:contributeInGroups ?  [groupsSwitchTitle] : [],
        continueTitle: Localization().getStringEx("panel.settings.privacy_center.button.forget_info.title","Forget My Information"),
        onContinue: (List<String> selectedValues, OnContinueProgressController progressController ){
          progressController(loading: true);
          if(selectedValues.contains(groupsSwitchTitle)){
            Groups().deleteUserData();
          }
          _deleteUserData().then((_){
            progressController(loading: false);
            Navigator.pop(context);
          });

        },
        longButtonTitle: true
    );
  }

  Future<void> _deleteUserData() async {
    Analytics().logAlert(text: "Remove My Information", selection: "Yes");
    await Auth2().deleteUser();
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
  
  bool get _isPhoneChanged{
    return (_initialPhone!= _customPhone);
  }

  String get _customFullName {
    return _nameController?.value.text??"";
  }
  
  String get _customEmail {
      return _emailController?.value.text??"";
  }
  
  String get _customPhone {
      return _phoneController?.value.text??"";
  }

  bool get _hasProfilePicture {
    return (_profileImageBytes != null);
  }
}

class _PersonalInfoEntry extends StatelessWidget {
  final String? title;
  final String? value;
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
                      title!,
                      style: TextStyle(
                          fontFamily: Styles().fontFamilies!.medium,
                          fontSize: 14,
                          letterSpacing: 0.5,
                          color: Styles().colors!.textBackground),
                    ),
                    Container(
                      height: 5,
                    ),
                    Text(
                      value!,
                      style:
                          TextStyle(fontSize: 20, color: Styles().colors!.fillColorPrimary),
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
