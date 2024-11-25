
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:illinois/ui/profile/ProfileDirectoryPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryWidgets.dart';
import 'package:illinois/ui/profile/ProfileLoginPage.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileDirectoryMyInfoPage extends StatefulWidget {
  final MyProfileInfo contentType;
  ProfileDirectoryMyInfoPage({super.key, required this.contentType});

  @override
  State<StatefulWidget> createState() => _ProfileDirectoryMyInfoPageState();
}

class _ProfileDirectoryMyInfoPageState extends State<ProfileDirectoryMyInfoPage>  {

  Auth2UserProfile? _profile;
  bool _loadingProfile = false;
  bool _editing = false;
  bool _preparingDeleteAccount = false;

  @override
  void initState() {
    _loadingProfile = true;
    Auth2().loadUserProfile().then((Auth2UserProfile? profile) {
      if (mounted) {
        setState(() {
          _loadingProfile = false;
          _profile = Auth2UserProfile.fromOther(profile ?? Auth2().profile,
            photoUrl: StringUtils.firstNotEmpty(Auth2().profile?.photoUrl, Content().getUserProfileImage(accountId: Auth2().accountId, type: UserProfileImageType.medium)),
            phone: StringUtils.firstNotEmpty(Auth2().profile?.phone , '(234) 567-8901'),
            data: <String, dynamic> {
              Auth2UserProfile.collegeDataKey : StringUtils.firstNotEmpty(IlliniCash().studentClassification?.collegeName, 'Academic Affairs'),
              Auth2UserProfile.departmentDataKey : StringUtils.firstNotEmpty(IlliniCash().studentClassification?.departmentName, 'Center for Advanced Study'),
              Auth2UserProfile.pronounDataKey : 'he',
            }
          );
        });
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return _loadingContent;
    }
    else if (_editing) {
      return _editContent;
    }
    else {
      return _previewContent;
    }
  }

  Widget get _previewContent =>
      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        Column(children: [
          Text(_previewDesriptionText, style: Styles().textStyles.getTextStyle('widget.title.tiny'), textAlign: TextAlign.center,),
          Padding(padding: EdgeInsets.only(top: 24), child:
              Stack(children: [
                Padding(padding: EdgeInsets.only(top: _previewPhotoImageSize / 2), child:
                  _previewCardWidget,
                ),
                Center(child:
                  DirectoryProfilePhoto(_profile?.photoUrl, imageSize: _previewPhotoImageSize, headers: _photoImageHeaders,),
                )
              ])
          ),
          Padding(padding: EdgeInsets.only(top: 24), child:
            _previewCommandBar,
          ),
          Padding(padding: EdgeInsets.only(top: 8), child:
            _signOutButton,
          ),
          Padding(padding: EdgeInsets.zero, child:
            _deleteAccountButton,
          ),
          Padding(padding: EdgeInsets.only(top: 8)),
        ],),
      );

  String get _previewDesriptionText {
    switch (widget.contentType) {
      case MyProfileInfo.myConnectionsInfo: return AppTextUtils.appTitleString('panel.profile.directory.my_info.connections.preview.description.text', 'Preview of how your profile displays for your ${AppTextUtils.appTitleMacro} Connections.');
      case MyProfileInfo.myDirectoryInfo: return AppTextUtils.appTitleString('panel.profile.directory.my_info.directory.preview.description.text', 'Preview of how your profile displays in the directory.');
    }
  }

  double get _previewPhotoImageSize => MediaQuery.of(context).size.width / 3;

  Map<String, String> get _photoImageHeaders => <String, String>{
    HttpHeaders.authorizationHeader : "${Auth2().token?.tokenType ?? 'Bearer'} ${Auth2().token?.accessToken}",
  };

  Widget get _previewCardWidget => Container(
    decoration: BoxDecoration(
      color: Styles().colors.white,
      border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
      borderRadius: BorderRadius.all(Radius.circular(16)),
      boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
    ),
    child: Padding(padding: EdgeInsets.only(top: _previewPhotoImageSize / 2), child:
      _previewCardContent
    ),
  );

  Widget get _previewCardContent =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: EdgeInsets.only(top: 12), child:
          Row(children: [
            Expanded(child:
              _cardContentHeading,
            ),
          ],),
        ),
        Padding(padding: EdgeInsets.only(top: 12), child:
          DirectoryProfileDetails(_profile)
        ),
        _shareButton,
    ],)
  );

  Widget get _cardContentHeading =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_profile?.fullName ?? '', style: Styles().textStyles.getTextStyleEx('widget.title.medium_large.fat', fontHeight: 0.85), textAlign: TextAlign.center,),
      if (_profile?.pronoun?.isNotEmpty == true)
        Text(_profile?.pronoun ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small')),
    ]);

  Widget get _previewCommandBar {
    switch (widget.contentType) {
      case MyProfileInfo.myConnectionsInfo: return _myConnectionsInfoCommandBar;
      case MyProfileInfo.myDirectoryInfo: return _myDirectoryInfoCommandBar;
    }
  }

  Widget get _myConnectionsInfoCommandBar => Row(children: [
    Expanded(child: _editInfoButton,),
    Container(width: 8),
    Expanded(child: _swapInfoButton,),
  ],);

  Widget get _myDirectoryInfoCommandBar => Row(children: [
    Expanded(flex: 1, child: Container(),),
    Expanded(flex: 2, child: _editInfoButton,),
    Expanded(flex: 1, child: Container(),),
  ],);

  Widget get _editInfoButton => RoundedButton(
    label: Localization().getStringEx('panel.profile.directory.my_info.command.button.edit.text', 'Edit My Info'),
    fontFamily: Styles().fontFamilies.bold, fontSize: 16,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    onTap: _onEditInfo,
  );

  void _onEditInfo() {
    Analytics().logSelect(target: 'Edit My Info');
    setState(() {
      _editing = true;
    });
  }

  Widget get _swapInfoButton => RoundedButton(
      label: Localization().getStringEx('panel.profile.directory.my_info.command.button.swap.text', 'Swap Info'),
      fontFamily: Styles().fontFamilies.bold, fontSize: 16,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: _onSwapInfo,
  );

  void _onSwapInfo() {
    Analytics().logSelect(target: 'Swap Info');
  }

  Widget get _shareButton => Row(children: [
    Padding(padding: EdgeInsets.only(right: 4), child:
      Styles().images.getImage('share', size: 14) ?? Container()
    ),
    Expanded(child:
      LinkButton(
        title: AppTextUtils.appTitleString('panel.profile.directory.my_info.command.link.share.text', 'Share my info outside the ${AppTextUtils.appTitleMacro} app'),
        textStyle: Styles().textStyles.getTextStyle('widget.button.title.small.underline'),
        textAlign: TextAlign.left,
        padding: EdgeInsets.symmetric(vertical: 16),
        onTap: _onShare,
      ),
    ),
  ],);

  void _onShare() {
    Analytics().logSelect(target: 'Share');
  }

  Widget get _signOutButton => LinkButton(
    title: Localization().getStringEx('panel.profile.directory.my_info.command.link.sign_out.text', 'Sign Out'),
    textStyle: Styles().textStyles.getTextStyle('widget.button.title.small.underline'),
    onTap: _onSignOut,
  );

  void _onSignOut() {
    Analytics().logSelect(target: 'Sign Out');
    showDialog<bool?>(context: context, builder: (context) => ProfilePromptLogoutWidget()).then((bool? result) {
      if (result == true) {
        Auth2().logout();
      }
    });
  }

  Widget get _deleteAccountButton => Stack(children: [
    LinkButton(
      title: AppTextUtils.appTitleString('panel.profile.directory.my_info.command.link.delete_account.text', 'Delete My ${AppTextUtils.appTitleMacro} App Account'),
      textStyle: Styles().textStyles.getTextStyle('widget.button.title.small.underline'),
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      onTap: _onDeleteAccount,
    ),
    if (_preparingDeleteAccount)
      Positioned.fill(child:
        Center(child:
          SizedBox(width: 14, height: 14, child:
            CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary,)
          )
        )
      )
  ],);

  void _onDeleteAccount() {
    Analytics().logSelect(target: 'Delete Account');
    if (!_preparingDeleteAccount) {
      setState(() {
        _preparingDeleteAccount = true;
      });
      Groups().getUserPostCount().then((int userPostCount) {
        if (mounted) {
          setState(() {
            _preparingDeleteAccount = false;
          });
          final String groupsSwitchTitle = Localization().getStringEx('panel.settings.privacy_center.delete_account.contributions.delete.msg', 'Please delete all my contributions.');
          SettingsDialog.show(context,
              title: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.title", "Delete your account?"),
              message: [
                TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description1", "This will ")),
                TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description2", "Permanently "),style: Styles().textStyles.getTextStyle("widget.text.fat")),
                TextSpan(text: Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description3", "delete all of your information. You will not be able to retrieve your data after you have deleted it. Are you sure you want to continue?")),
                if (0 < userPostCount)
                  TextSpan(text:Localization().getStringEx("panel.settings.privacy_center.label.delete_message.description.groups", " You have contributed to Groups. Do you wish to delete all of those entries (posts, replies, reactions and events) or leave them for others to see.")),
              ],
              options: (0 < userPostCount) ? [groupsSwitchTitle] : null,
              initialOptionsSelection: (0 < userPostCount) ?  [groupsSwitchTitle] : [],
              continueTitle: Localization().getStringEx("panel.settings.privacy_center.button.forget_info.title","Forget My Information"),
              onContinue: (List<String> selectedValues, OnContinueProgressController progressController) async {
                Analytics().logAlert(text: "Remove My Information", selection: "Yes");
                progressController(loading: true);
                if (selectedValues.contains(groupsSwitchTitle)){
                  await Groups().deleteUserData();
                }
                await Auth2().deleteUser();
                progressController(loading: false);
                Navigator.pop(context);
              },
              longButtonTitle: true
          );
        }
      });
    }
  }

  Widget get _loadingContent => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 64,), child:
    Center(child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,)
      )
    )
  );

  Widget get _editContent =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(children: [
        Text(_editDesriptionText, style: Styles().textStyles.getTextStyle('widget.title.tiny'), textAlign: TextAlign.center,),
        Padding(padding: EdgeInsets.only(top: 24), child:
          _editPhotoWidget,
        ),
        Padding(padding: EdgeInsets.only(top: 24), child:
          _editCommandBar,
        ),
        Padding(padding: EdgeInsets.only(top: 8)),
      ],),
    );

  String get _editDesriptionText {
    switch (widget.contentType) {
      case MyProfileInfo.myConnectionsInfo: return AppTextUtils.appTitleString('panel.profile.directory.my_info.connections.edit.description.text', 'Edit how your profile displays for your ${AppTextUtils.appTitleMacro} Connections.');
      case MyProfileInfo.myDirectoryInfo: return AppTextUtils.appTitleString('panel.profile.directory.my_info.directory.edit.description.text', 'Edit how your profile displays in the directory.');
    }
  }


  double get _editPhotoImageSize => MediaQuery.of(context).size.width / 3;

  Widget get _editPhotoWidget => Stack(children: [
    Padding(padding: EdgeInsets.only(left: 8, right: 8, bottom: 20), child:
      DirectoryProfilePhoto(_profile?.photoUrl, imageSize: _editPhotoImageSize, headers: _photoImageHeaders,),
    ),
    Positioned.fill(child:
      Align(alignment: Alignment.bottomLeft, child:
        _editPhotoButton
      )
    ),
    Positioned.fill(child:
      Align(alignment: Alignment.bottomRight, child:
      _togglePhotoVisibilityButton
      )
    )
  ],);

  Widget get _editPhotoButton => _photoButton(
    icon: 'edit',
    iconColor: Styles().colors.fillColorPrimary,
    onTap: _onEditPhoto
  );

  void _onEditPhoto() {
    Analytics().logSelect(target: 'Edit Photo');
  }

  Widget get _togglePhotoVisibilityButton => _photoButton(
      icon: 'eye-slash',
      iconColor: Styles().colors.mediumGray2,
      onTap: _onTogglePhotoVisibility
  );

  void _onTogglePhotoVisibility() {
    Analytics().logSelect(target: 'Toggle Photo Visibility');
  }

  Widget _photoButton({String? icon, Color? iconColor, void Function()? onTap}) =>
    InkWell(onTap: onTap, child:
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Styles().colors.white,
          border: Border.all(color: Styles().colors.surfaceAccent, width: 1)
        ),
        child: Padding(padding: EdgeInsets.all(12), child:
            Styles().images.getImage(icon, color: iconColor)
        ),
      )


    );


  Widget get _editCommandBar => Row(children: [
    Expanded(child: _cancelEditButton,),
    Container(width: 8),
    Expanded(child: _saveEditButton,),
  ],);

  Widget get _cancelEditButton => RoundedButton(
    label: Localization().getStringEx('dialog.cancel.title', 'Cancel'),
    fontFamily: Styles().fontFamilies.bold, fontSize: 16,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    onTap: _onCancelEdit,
  );

  void _onCancelEdit() {
    Analytics().logSelect(target: 'Cancel Edit');
    setState(() {
      _editing = false;
    });
  }

  Widget get _saveEditButton => RoundedButton(
    label: Localization().getStringEx('dialog.save.title', 'Save'),
    fontFamily: Styles().fontFamilies.bold, fontSize: 16,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    onTap: _onSaveEdit,
  );

  void _onSaveEdit() {
    Analytics().logSelect(target: 'Save Edit');
    setState(() {
      _editing = true;
    });
  }
}
