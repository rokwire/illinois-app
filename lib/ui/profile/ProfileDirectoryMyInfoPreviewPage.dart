
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/profile/ProfileDirectoryMyInfoPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryWidgets.dart';
import 'package:illinois/ui/profile/ProfileLoginPage.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class ProfileDirectoryMyInfoPreviewPage extends StatefulWidget {
  final MyProfileInfo contentType;
  final Auth2UserProfile? previewProfile;
  final String? photoImageToken;
  final void Function()? onEditInfo;
  ProfileDirectoryMyInfoPreviewPage({super.key, required this.contentType, this.previewProfile, this.photoImageToken, this.onEditInfo });

  @override
  State<StatefulWidget> createState() => _ProfileDirectoryMyInfoPreviewPageState();
}

class _ProfileDirectoryMyInfoPreviewPageState extends ProfileDirectoryMyInfoBasePageState<ProfileDirectoryMyInfoPreviewPage> {

  bool _preparingDeleteAccount = false;

  @override
  void initState() {
    super.photoImageToken = widget.photoImageToken;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(children: [
        Text(_desriptionText, style: Styles().textStyles.getTextStyle('widget.detail.small'), textAlign: TextAlign.center,),
        Padding(padding: EdgeInsets.only(top: 24), child:
            Stack(children: [
              Padding(padding: EdgeInsets.only(top: _photoImageSize / 2), child:
                _cardWidget,
              ),
              Center(child:
                DirectoryProfilePhoto(_photoUrl, imageSize: _photoImageSize, headers: photoImageHeaders,),
              )
            ])
        ),
        Padding(padding: EdgeInsets.only(top: 24), child:
          _commandBar,
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

  String get _desriptionText {
    switch (widget.contentType) {
      case MyProfileInfo.myConnectionsInfo: return AppTextUtils.appTitleString('panel.profile.directory.my_info.connections.preview.description.text', 'Preview of how your profile displays for your ${AppTextUtils.appTitleMacro} Connections.');
      case MyProfileInfo.myDirectoryInfo: return AppTextUtils.appTitleString('panel.profile.directory.my_info.directory.preview.description.text', 'Preview of how your profile displays in the directory.');
    }
  }

  String? get _photoUrl => photoImageUrl(widget.previewProfile?.photoUrl);

  double get _photoImageSize => MediaQuery.of(context).size.width / 3;

  Widget get _cardWidget => Container(
    decoration: BoxDecoration(
      color: Styles().colors.white,
      border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
      borderRadius: BorderRadius.all(Radius.circular(16)),
      boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
    ),
    child: Padding(padding: EdgeInsets.only(top: _photoImageSize / 2), child:
      _cardContent
    ),
  );

  Widget get _cardContent =>
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
          DirectoryProfileDetails(widget.previewProfile)
        ),
        _shareButton,
    ],)
  );

  Widget get _cardContentHeading =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      Text(widget.previewProfile?.fullName ?? '', style: nameTextStyle, textAlign: TextAlign.center,),
      if (widget.previewProfile?.pronouns?.isNotEmpty == true)
        Text(widget.previewProfile?.pronouns ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small')),
    ]);

  Widget get _commandBar {
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
    widget.onEditInfo?.call();
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
            super.progressWidget
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
      Social().getUserPostsCount().then((int userPostCount) {
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
                  Future.wait([Groups().deleteUserData(), Social().deleteUser()]);
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
}
