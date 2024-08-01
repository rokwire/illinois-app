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
import 'package:neom/service/IlliniCash.dart';
import 'package:neom/service/OnCampus.dart';
import 'package:neom/ui/groups/ImageEditPanel.dart';
import 'package:neom/ui/profile/ProfileVoiceRecordigWidgets.dart';
import 'package:neom/ui/settings/SettingsWidgets.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:neom/service/Analytics.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileDetailsPage extends StatefulWidget {
  final String? parentRouteName;
  final EdgeInsets margin;

  ProfileDetailsPage({Key? key, this.parentRouteName, this.margin = const EdgeInsets.all(16) }) : super(key: key);

  @override
  _ProfileDetailsPageState createState() => _ProfileDetailsPageState();

  EdgeInsetsGeometry get horzMargin => EdgeInsets.only(left: margin.left, right: margin.right);
  EdgeInsetsGeometry get vertMargin => EdgeInsets.only(top: margin.top, bottom: margin.bottom);
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> implements NotificationsListener {

  TextEditingController? _nameController;
  TextEditingController? _emailController;
  TextEditingController? _phoneController;
  String? _initialName;
  String? _initialEmail;

  Uint8List? _profileImageBytes;

  bool _isSaving = false;
  bool _profilePicProcessing = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLogout,
      OnCampus.notifyChanged,
    ]);
    _nameController = TextEditingController(text: _initialName = Auth2().fullName ?? "");
    _emailController = TextEditingController(text: _initialEmail = Auth2().emails.isNotEmpty ? Auth2().emails.first : "");
    _phoneController = TextEditingController(text: Auth2().phones.isNotEmpty ? Auth2().phones.first : "");
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
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
    else if (name == OnCampus.notifyChanged) {
      if (mounted) {
        setState(() {
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: widget.vertMargin, child:
      Column(children: <Widget>[
        _buildProfilePicture(),
        _buildInfoContent(),
        _buildAccountManagementOptions(),
        _buildDeleteMyAccount()
      ]),
    );
  }

  Widget _buildInfoContent() {
    Widget? contentWidget;
    if (Auth2().isOidcLoggedIn) {
      contentWidget = _buildShibbolethInfoContent();
    }
    else if (Auth2().isCodeLoggedIn) {
      contentWidget = _buildPhoneVerifiedInfoContent();
    }
    else if (Auth2().isPasswordLoggedIn) {
      contentWidget = _buildEmailLoginInfoContent();
    }
    else if (Auth2().isPasskeyLoggedIn) {
      contentWidget = _buildPasskeyLoginInfoContent();
    }

    return (contentWidget != null) ? Padding(padding: EdgeInsets.only(top: 25), child: contentWidget) : Container() ;
  }

  Widget _buildShibbolethInfoContent(){
    return Column(children: <Widget>[
      _PersonalInfoEntry(
          title: Localization().getStringEx('panel.profile_info.net_id.title', 'UIN'),
          value: Auth2().account?.authType?.uiucUser?.identifier ?? "",
          margin: EdgeInsets.only(left: widget.margin.left, right: widget.margin.right),),
      _PersonalInfoEntry(
          title: Localization().getStringEx('panel.profile_info.full_name.title', 'Full Name'),
          value: Auth2().account?.authType?.uiucUser?.fullName ?? "",
          margin: EdgeInsets.only(top: 12, left: widget.margin.left, right: widget.margin.right),),
      ProfileNamePronouncementWidget(),
      _PersonalInfoEntry(
          title: Localization().getStringEx('panel.profile_info.middle_name.title', 'Middle Name'),
          value: Auth2().account?.authType?.uiucUser?.middleName ?? "",
          margin: EdgeInsets.only(top: 12, left: widget.margin.left, right: widget.margin.right),),
      _PersonalInfoEntry(
          title: Localization().getStringEx('panel.profile_info.last_name.title', 'Last Name'),
          value:  Auth2().account?.authType?.uiucUser?.lastName ?? "",
          margin: EdgeInsets.only(top: 12, left: widget.margin.left, right: widget.margin.right),),
      _PersonalInfoEntry(
          title: Localization().getStringEx('panel.profile_info.email_address.title', 'Email Address'),
          value: Auth2().account?.authType?.uiucUser?.email ?? "",
          margin: EdgeInsets.only(top: 12, left: widget.margin.left, right: widget.margin.right),),
      _PersonalInfoEntry(
          title: Localization().getStringEx('panel.profile_info.college.title', 'College'),
          value: IlliniCash().studentClassification?.collegeName ?? "",
          margin: EdgeInsets.only(top: 12, left: widget.margin.left, right: widget.margin.right),),
    ],);
  }

  Widget _buildPhoneVerifiedInfoContent(){
    return Padding(padding: widget.horzMargin, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Semantics(label: Localization().getStringEx("panel.profile_info.phone_or_email.name.title","Full Name"), header: true, excludeSemantics: true, child:
          Padding(padding: EdgeInsets.only(bottom: 8), child:
            Text(Localization().getStringEx("panel.profile_info.phone_or_email.name.title","Full Name"), textAlign: TextAlign.left, style: _formFieldLabelTextStyle)
          )
        ),
        Semantics(
          label: Localization().getStringEx("panel.profile_info.phone_or_email.name.title","Full Name"),
          hint: Localization().getStringEx("panel.profile_info.phone_or_email.name.hint",""),
          textField: true, excludeSemantics: true,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: Styles().colors.surface, border: Border.all(color: Styles().colors.fillColorPrimary, width: 1)),
//          height: 48,
            child: TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              onChanged: (text) { setState(() {});},
              decoration: InputDecoration(border: InputBorder.none),
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              style: Styles().textStyles.getTextStyle("widget.input_field.text.regular")
            ),
          )
          ),
          Container(height: 33,),
          //TODO: provide text fields here once Core BB has been updated to handle profile email and phone updates
          if (Auth2().phones.isNotEmpty)
            _PersonalInfoEntry(
                title: Localization().getStringEx("panel.profile_info.phone.title", "Phone Number"),
                value: Auth2().phones.first),
          if (Auth2().emails.isNotEmpty)
            _PersonalInfoEntry(
                title: Localization().getStringEx("panel.profile_info.email.title", "Email Address"),
                value: Auth2().emails.first),
//           Semantics(
//             label: Localization().getStringEx("panel.profile_info.phone_or_email.email.title", "Email Address"),
//             //hint: Localization().getStringEx("panel.profile_info.phone_or_email.email.hint", ""),
//             header: true, excludeSemantics: true,
//                child: Padding(padding: EdgeInsets.only(bottom: 8),
//                  child: Text(Localization().getStringEx("panel.profile_info.phone_or_email.email.title","Email Address"), textAlign: TextAlign.left,
//                     style: _formFieldLabelTextStyle)
//               )
//           ),
//           Semantics(
//             label:Localization().getStringEx("panel.profile_info.phone_or_email.email.title","Email Address"),
//             hint: Localization().getStringEx("panel.profile_info.phone_or_email.email.hint",""),
//             textField: true, excludeSemantics: true,
//             child: Container(
//                 padding: EdgeInsets.symmetric(horizontal: 8),
//                 decoration: BoxDecoration(color: Styles().colors.surface, border: Border.all(color: Styles().colors.fillColorPrimary, width: 1)),
// //                height: 48,
//                 child: TextField(
//                   controller: _emailController,
//                   onChanged: (text) { setState(() {});},
//                   decoration: InputDecoration(border: InputBorder.none),
//                   maxLengthEnforcement: MaxLengthEnforcement.enforced,
//                   style: Styles().textStyles.getTextStyle("widget.input_field.text.regular")
//                 ),
//               )
//           ),
        ],
      )
    );
  }

  Widget _buildEmailLoginInfoContent(){
    return Padding(padding: widget.horzMargin, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Semantics(label: Localization().getStringEx("panel.profile_info.phone_or_email.name.title","Full Name"), header: true, excludeSemantics: true, child:
          Padding(padding: EdgeInsets.only(bottom: 8), child:
            Text(Localization().getStringEx("panel.profile_info.phone_or_email.name.title","Full Name"), textAlign: TextAlign.left, style: _formFieldLabelTextStyle)
          )
        ),
        Semantics(
          label: Localization().getStringEx("panel.profile_info.phone_or_email.name.title","Full Name"),
          hint: Localization().getStringEx("panel.profile_info.phone_or_email.name.hint",""),
          textField: true, excludeSemantics: true,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: Styles().colors.surface, border: Border.all(color: Styles().colors.fillColorPrimary, width: 1)),
//          height: 48,
            child: TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              onChanged: (text) { setState(() {});},
              decoration: InputDecoration(border: InputBorder.none),
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              style: Styles().textStyles.getTextStyle("widget.input_field.text.regular")
            ),
          )
          ),
          Container(height: 33,),
          //TODO: provide text fields here once Core BB has been updated to handle profile email and phone updates
          if (Auth2().phones.isNotEmpty)
            _PersonalInfoEntry(
                title: Localization().getStringEx("panel.profile_info.phone.title", "Phone Number"),
                value: Auth2().phones.first),
          if (Auth2().emails.isNotEmpty)
            _PersonalInfoEntry(
                title: Localization().getStringEx("panel.profile_info.email.title", "Email Address"),
                value: Auth2().emails.first),
//           Semantics(
//             label: Localization().getStringEx("panel.profile_info.phone_or_email.phone.title", "Phone Number"),
//             //hint: Localization().getStringEx("panel.profile_info.phone_or_email.phone.hint", ""),
//             header: true, excludeSemantics: true,
//                child: Padding(padding: EdgeInsets.only(bottom: 8),
//                  child: Text(Localization().getStringEx("panel.profile_info.phone_or_email.phone.title","Phone Number"), textAlign: TextAlign.left, style: _formFieldLabelTextStyle)
//               )
//           ),
//           Semantics(
//             label:Localization().getStringEx("panel.profile_info.phone_or_email.phone.title","Phone Number"),
//             hint: Localization().getStringEx("panel.profile_info.phone_or_email.phone.hint",""),
//             textField: true, excludeSemantics: true,
//             child: Container(
//                 padding: EdgeInsets.symmetric(horizontal: 8),
//                 decoration: BoxDecoration(color: Styles().colors.surface, border: Border.all(color: Styles().colors.fillColorPrimary, width: 1)),
// //                height: 48,
//                 child: TextField(
//                   controller: _phoneController,
//                   onChanged: (text) { setState(() {});},
//                   decoration: InputDecoration(border: InputBorder.none),
//                   maxLengthEnforcement: MaxLengthEnforcement.enforced,
//                   style: Styles().textStyles.getTextStyle("widget.input_field.text.regular")
//                 ),
//               )
//           ),
        ],
      )
    );
  }

  Widget _buildPasskeyLoginInfoContent(){
    return Padding(padding: widget.horzMargin,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Semantics(label: Localization().getStringEx("panel.profile_info.phone_or_email.name.title","Full Name"), header: true, excludeSemantics: true, child:
          Padding(padding: EdgeInsets.only(bottom: 8), child:
            Text(Localization().getStringEx("panel.profile_info.phone_or_email.name.title","Full Name"), textAlign: TextAlign.left, style: _formFieldLabelTextStyle)
          )
        ),
        Semantics(
            label: Localization().getStringEx("panel.profile_info.phone_or_email.name.title","Full Name"),
            hint: Localization().getStringEx("panel.profile_info.phone_or_email.name.hint",""),
            textField: true, excludeSemantics: true,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: Styles().colors.surface, border: Border.all(color: Styles().colors.fillColorPrimary, width: 1)),
      //          height: 48,
              child: TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (text) { setState(() {});},
                  decoration: InputDecoration(border: InputBorder.none),
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  style: Styles().textStyles.getTextStyle("widget.input_field.text.regular")
              ),
            )
        ),
        Container(height: 33,),
        //TODO: provide text fields here once Core BB has been updated to handle profile email and phone updates
        if (Auth2().phones.isNotEmpty)
          _PersonalInfoEntry(
              title: Localization().getStringEx("panel.profile_info.phone.title", "Phone Number"),
              value: Auth2().phones.first),
        if (Auth2().emails.isNotEmpty)
          _PersonalInfoEntry(
              title: Localization().getStringEx("panel.profile_info.email.title", "Email Address"),
              value: Auth2().emails.first),
      ],
      ),
    );
  }

  //AccountManagementOptions

  Widget _buildAccountManagementOptions() {
    Widget? contentWidget;
    if (Auth2().isOidcLoggedIn) {
      contentWidget = _buildShibbolethAccountManagementOptions();
    }
    else if (Auth2().isCodeLoggedIn) {
      contentWidget = _buildPhoneOrEmailAccountManagementOptions();
    }
    else if (Auth2().isPasswordLoggedIn) {
      contentWidget = _buildPhoneOrEmailAccountManagementOptions();
    }
    else if (Auth2().isPasskeyLoggedIn) {
      contentWidget = _buildPhoneOrEmailAccountManagementOptions();
    }
    
    return (contentWidget != null) ? Padding(padding: EdgeInsets.only(top: 25, left: widget.margin.left, right: widget.margin.right), child: contentWidget) : Container();
  }

  Widget _buildShibbolethAccountManagementOptions() {
    return RoundedButton(
      label: Localization().getStringEx("panel.profile_info.button.sign_out.title", "Sign Out"),
      hint: Localization().getStringEx("panel.profile_info.button.sign_out.hint", ""),
      textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
      backgroundColor: Styles().colors.background,
      borderColor: Styles().colors.fillColorSecondary,
      borderShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))],
      onTap: _onSignOutClicked,
    );
  }

  Widget _buildPhoneOrEmailAccountManagementOptions() {
    return RoundedButton(
      label: Localization().getStringEx("panel.profile_info.button.save.title", "Save Changes"),
      hint: Localization().getStringEx("panel.profile_info.button.save.hint", ""),
      textStyle: _canSave ? Styles().textStyles.getTextStyle("widget.button.title.enabled") : Styles().textStyles.getTextStyle("widget.button.title.disabled"),
      enabled: _canSave,
      backgroundColor: _canSave ? Styles().colors.fillColorSecondary : Styles().colors.background,
      borderColor: _canSave? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
      progress: _isSaving,
      progressColor: Styles().colors.background,
      onTap: _onSaveChangesClicked,
    );
  }

  Widget _buildLogoutDialog(BuildContext context) {
    String promptEn = 'Are you sure you want to sign out?';
    return Dialog(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              Localization().getStringEx("panel.profile_info.logout.title", "{{app_title}}").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')),
              style: Styles().textStyles.getTextStyle("widget.dialog.message.dark.large"),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Text(
                Localization().getStringEx("panel.profile_info.logout.message", promptEn),
                textAlign: TextAlign.left,
                style: Styles().textStyles.getTextStyle("widget.dialog.message.dark.regular")
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                    onPressed: () {
                      Analytics().logAlert(text: promptEn, selection: "Yes");
                      Navigator.pop(context);
                      Auth2().logout();
                    },
                    child: Text(Localization().getStringEx("panel.profile_info.logout.button.yes", "Yes"))),
                TextButton(
                    onPressed: () {
                      Analytics().logAlert(text: promptEn, selection: "No");
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
    Widget contentWidget;
    if (_profilePicProcessing) {
      contentWidget = Center(child: CircularProgressIndicator());
    } else {
      Image? profileImage = _hasProfilePicture? Image.memory(_profileImageBytes!) : null;
      Widget? profilePicture = _hasProfilePicture ? ModalImageHolder(
          image: profileImage?.image,
          child: Container(decoration:
            BoxDecoration(shape: BoxShape.circle, color: Styles().colors.surface, image: DecorationImage(fit: _hasProfilePicture ? BoxFit.cover : BoxFit.contain, image: profileImage!.image))
          ),
        ) : Styles().images.getImage('profile-placeholder', excludeFromSemantics: true);
      contentWidget = Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Visibility(visible: _hasProfilePicture, child:
            Padding(padding: EdgeInsets.only(right: 24), child:
              _buildProfileImageButton(
                Localization().getStringEx("panel.profile_info.button.picture.edit.title", "Edit"),
                Localization().getStringEx("panel.profile_info.button.picture.edit.hint", "Edit profile photo"),
                _onTapEditPicture
              )
            )
          ),
          Expanded(child:
            Container(width: 189, height: 189, child:
              Semantics(image: true, label: "Profile", child: profilePicture)
            ),
          ),
          Visibility(visible: _hasProfilePicture, child:
            Padding(padding: EdgeInsets.only(left: 24), child:
              _buildProfileImageButton(
                Localization().getStringEx("panel.profile_info.button.picture.delete.title", "Delete"),
                Localization().getStringEx("panel.profile_info.button.picture.delete.hint", "Delete profile photo"),
                _onTapDeletePicture
              )
            )
          )
        ]),
        Visibility(visible: !_hasProfilePicture, child:
          Padding(padding: EdgeInsets.only(top: 10), child:
            _buildProfileImageButton(
              Localization().getStringEx("panel.profile_info.button.profile_picture.title", "Set Profile Photo"),
              Localization().getStringEx("panel.profile_info.button.profile_picture.hint", ""),
              _onTapProfilePicture
            )
          )
        )
      ]);
    }

    return Padding(padding: EdgeInsets.only(top: 25, left: widget.margin.left, right: widget.margin.right), child: contentWidget);
  }

  Widget _buildProfileImageButton(String title, String hint, GestureTapCallback? onTap) {
    return Semantics(label: title, hint: hint, button: true,
        child: GestureDetector(
        onTap: onTap,
        child: Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors.fillColorSecondary, width: 1))),
            padding: EdgeInsets.only(bottom: 2),
            child: Text(title,
                semanticsLabel: "",
                style:  Styles().textStyles.getTextStyle("panel.settings.button.title.medium")))));
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

    String? firstName, lastName, middleName;
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

      setState(() { _isSaving = true; });

      Auth2().loadUserProfile().then((Auth2UserProfile? userProfile) {
        if (mounted) {
          if (userProfile != null) {
            Auth2UserProfile? updatedUserProfile = Auth2UserProfile.fromOther(userProfile,
              firstName: firstName,
              middleName: middleName,
              lastName: lastName,
            );
            if (userProfile != updatedUserProfile) {
              Auth2().saveAccountUserProfile(updatedUserProfile).then((bool result) {
                if (mounted) {
                  setState(() {
                    _isSaving = false;
                  });
                  if (result == true) {
                    Navigator.pop(context);
                  } else {
                    AppToast.showMessage("Unable to perform save");
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
            AppToast.showMessage("Unable to perform save");
          }
        }
      });
    }
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

  void _deleteProfilePicture(){
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

  void _onTapDeletePicture() {
    String promptEn = Localization().getStringEx('panel.profile_info.picture.delete.confirmation.msg', 'Are you sure you want to remove this profile picture?');
    AppAlert.showCustomDialog(context: context,
        contentWidget:
        Text(promptEn,
          style: Styles().textStyles.getTextStyle("widget.message.light.regular"),
        ),
        actions: [
          TextButton(
              child: Text(Localization().getStringEx('dialog.ok.title', 'OK')),
              onPressed: () {
                Analytics().logAlert(text: promptEn, selection: 'OK');
                Navigator.of(context).pop(true);
                _deleteProfilePicture();
              }
          ),
          TextButton(
              child: Text(Localization().getStringEx('dialog.cancel.title', 'Cancel')),
              onPressed: () { Analytics().logAlert(text: promptEn, selection: 'Cancel'); Navigator.of(context).pop(false); }
          )
        ]);
  }

  Widget _buildDeleteMyAccount() {
    return Padding(padding: EdgeInsets.only(top: 24, bottom: 12, left: widget.margin.left, right: widget.margin.right), child:
    RoundedButton(
        backgroundColor: Styles().colors.surface,
        borderColor: Styles().colors.alert,
        borderWidth: 1,
        textStyle: Styles().textStyles.getTextStyle('widget.error.regular'),
        label: Localization().getStringEx("panel.settings.privacy_center.button.delete_data.title", "Delete My Account"),
        hint: Localization().getStringEx("panel.settings.privacy_center.label.delete.description", "This will delete all of your personal information that was shared and stored within the app."),
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
          TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description2", "Permanently "),style: Styles().textStyles.getTextStyle("widget.text.fat")),
          TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description3", "delete all of your information. You will not be able to retrieve your data after you have deleted it. Are you sure you want to continue?")),
          TextSpan(text: contributeInGroups?
          Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description.groups", " You have contributed to Groups. Do you wish to delete all of those entries (posts, replies, reactions and events) or leave them for others to see.") :
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

  String get _customFullName {
    return _nameController?.value.text??"";
  }
  
  String get _customEmail {
      return _emailController?.value.text??"";
  }

  bool get _hasProfilePicture {
    return (_profileImageBytes != null);
  }

  TextStyle? get _formFieldLabelTextStyle {
    return  Styles().textStyles.getTextStyle("widget.detail.small");
  }
}

class _PersonalInfoEntry extends StatelessWidget {
  final String? title;
  final String? value;
  final EdgeInsetsGeometry margin;

  _PersonalInfoEntry({this.title, this.value, this.margin = const EdgeInsets.only(top: 12)});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: margin, child:
      Row(children: [
        Expanded(child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(title ?? '', style: Styles().textStyles.getTextStyle("panel.settings.detail.title.medium")
              ),
              Container(height: 5,),
              Text(value ?? '', style: Styles().textStyles.getTextStyle("widget.detail.large.fat"))
            ],),
        )
      ],),
    );
  }
}
