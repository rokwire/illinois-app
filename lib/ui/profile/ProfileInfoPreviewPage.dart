
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/profile/ProfileInfoPage.dart';
import 'package:illinois/ui/profile/ProfileInfoAndDirectoryPage.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/ui/profile/ProfileLoginPage.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileInfoPreviewPage extends StatefulWidget {
  final ProfileInfo contentType;
  final Auth2UserProfile? profile;
  final Auth2UserPrivacy? privacy;
  final Uint8List? pronunciationAudioData;
  final Uint8List? photoImageData;
  final String? photoImageToken;
  final void Function()? onEditInfo;
  ProfileInfoPreviewPage({super.key, required this.contentType, this.profile, this.privacy, this.photoImageData, this.photoImageToken, this.pronunciationAudioData, this.onEditInfo });

  @override
  State<StatefulWidget> createState() => _ProfileInfoPreviewPageState();
}

class _ProfileInfoPreviewPageState extends ProfileDirectoryMyInfoBasePageState<ProfileInfoPreviewPage> {

  Auth2UserProfile? _profile;
  bool _preparingDeleteAccount = false;

  @override
  void initState() {
    Auth2UserProfileFieldsVisibility profileVisibility = Auth2UserProfileFieldsVisibility.fromOther(widget.privacy?.fieldsVisibility?.profile,
      firstName: Auth2FieldVisibility.public,
      middleName: Auth2FieldVisibility.public,
      lastName: Auth2FieldVisibility.public,
      email: Auth2FieldVisibility.public,
    );

    _profile = Auth2UserProfile.fromFieldsVisibility(widget.profile, profileVisibility, permitted: _permittedVisibility);

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(children: [
        if (_directoryVisibility)
          Text(_desriptionText, style: Styles().textStyles.getTextStyle('widget.detail.small'), textAlign: TextAlign.center,),
        _profileContent,
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
  }

  String get _desriptionText {
    switch (widget.contentType) {
      case ProfileInfo.connectionsInfo: return Localization().getStringEx('panel.profile.info.connections.preview.description.text', 'Preview of how your profile displays for your Connections.');
      case ProfileInfo.directoryInfo: return Localization().getStringEx('panel.profile.info.directory.preview.description.text', 'Preview of how your profile displays in the User Directory.');
    }
  }

  Widget get _profileContent => _directoryVisibility ?
    _publicProfileContent : _privateProfileContent;

  String? get _photoImageUrl => StringUtils.isNotEmpty(_profile?.photoUrl) ?
    Content().getUserPhotoUrl(type: UserProfileImageType.medium, params: DirectoryProfilePhotoUtils.tokenUrlParam(widget.photoImageToken)) : null;

  double get _photoImageSize => MediaQuery.of(context).size.width / 3;

  Map<String, String>? get _photoAuthHeaders => DirectoryProfilePhotoUtils.authHeaders;

  Widget get _publicProfileContent =>
    Padding(padding: EdgeInsets.only(top: 24), child:
      Stack(children: [
        Padding(padding: EdgeInsets.only(top: _photoImageSize / 2), child:
          DirectoryProfileCard(child:
            Padding(padding: EdgeInsets.only(top: _photoImageSize / 2), child:
              _publicCardContent
            )
          ),
        ),
        Center(child:
          DirectoryProfilePhoto(
            photoUrl: _photoImageUrl,
            photoUrlHeaders: _photoAuthHeaders,
            photoData: widget.photoImageData,
            imageSize: _photoImageSize,
          ),
        )
      ]),
    );

  Widget get _publicCardContent =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child:
            _cardContentHeading,
          ),
        ],),
        Padding(padding: EdgeInsets.only(top: 12, bottom: 12), child:
          DirectoryProfileDetails(_profile)
        ),
        //_shareButton,
    ],)
  );

  Widget get _cardContentHeading => Center(child:
    Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_profile?.pronunciationUrl?.isNotEmpty == true)
        DirectoryPronunciationButton.spacer(),
      Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: EdgeInsets.only(top: 16), child:
          Text(_profile?.fullName ?? '', style: nameTextStyle, textAlign: TextAlign.center,),
        ),
        if (_profile?.pronouns?.isNotEmpty == true)
          Text(_profile?.pronouns ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'), textAlign: TextAlign.center,),
      ]),
      if (_profile?.pronunciationUrl?.isNotEmpty == true)
        DirectoryPronunciationButton(url: _profile?.pronunciationUrl, data: widget.pronunciationAudioData,),
    ],),
  );

  Widget get _privateProfileContent =>
    Padding(padding: EdgeInsets.only(top: 12), child:
      DirectoryProfileCard(child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
          Center(child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(_privateProfileTitle, style: Styles().textStyles.getTextStyle('widget.detail.regular.fat')),
              Padding(padding: EdgeInsets.only(top: 6), child:
                _privateProfileDescriptionContent,
              )
            ],)
          )
        ),
      ),
    );

  String get _privateProfileTitle =>
    AppTextUtils.appTitleString('panel.profile.info.directory_visibility.private.title.text', 'Your Directory Visibility is set to Private');

  Widget get _privateProfileDescriptionContent {
    final String linkEditMacro = "{{link.edit}}";
    String messageTemplate = Localization().getStringEx('panel.profile.info.directory_visibility.private.description.text', 'To make your account visible in the User Directory, $linkEditMacro your privacy settings and set your Directory Visibility to Public.');
    List<String> messages = messageTemplate.split(linkEditMacro);
    List<InlineSpan> spanList = <InlineSpan>[];
    if (0 < messages.length)
      spanList.add(TextSpan(text: messages.first));
    for (int index = 1; index < messages.length; index++) {
      spanList.add(TextSpan(text: Localization().getStringEx('panel.profile.info.directory_visibility.private.link.edit', "edit"), style : Styles().textStyles.getTextStyle("widget.link.button.title.regular"),
        recognizer: TapGestureRecognizer()..onTap = _onEditInfo, ));
      spanList.add(TextSpan(text: messages[index]));
    }

    return RichText(textAlign: TextAlign.left, text:
      TextSpan(style: Styles().textStyles.getTextStyle("widget.detail.regular"), children: spanList)
    );
  }

  Widget get _commandBar {
    switch (widget.contentType) {
      case ProfileInfo.connectionsInfo: return _myConnectionsInfoCommandBar;
      case ProfileInfo.directoryInfo: return _myDirectoryInfoCommandBar;
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
    label: _editInfoButtonTitle,
    fontFamily: Styles().fontFamilies.bold, fontSize: 16,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    onTap: _onEditInfo,
  );

  String get _editInfoButtonTitle =>
    Localization().getStringEx('panel.profile.info.command.button.edit.text', 'Edit My Info');

  void _onEditInfo() {
    Analytics().logSelect(target: 'Edit My Info');
    widget.onEditInfo?.call();
  }

  Widget get _swapInfoButton => RoundedButton(
    label: Localization().getStringEx('panel.profile.info.command.button.swap.text', 'Swap Info'),
    fontFamily: Styles().fontFamilies.bold, fontSize: 16,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    onTap: _onSwapInfo,
  );

  void _onSwapInfo() {
    Analytics().logSelect(target: 'Swap Info');
  }

  // ignore: unused_element
  Widget get _shareButton => Row(children: [
    Padding(padding: EdgeInsets.only(right: 4), child:
      Styles().images.getImage('share', size: 14) ?? Container()
    ),
    Expanded(child:
      LinkButton(
        title: AppTextUtils.appTitleString('panel.profile.info.command.link.share.text', 'Share my info outside the ${AppTextUtils.appTitleMacro} app'),
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
    title: Localization().getStringEx('panel.profile.info.command.link.sign_out.text', 'Sign Out'),
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
      title: AppTextUtils.appTitleString('panel.profile.info.command.link.delete_account.text', 'Delete My ${AppTextUtils.appTitleMacro} App Account'),
      textStyle: Styles().textStyles.getTextStyle('widget.button.title.small.underline'),
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      onTap: _onDeleteAccount,
    ),
    if (_preparingDeleteAccount)
      Positioned.fill(child:
        Center(child:
          SizedBox(width: 14, height: 14, child:
            DirectoryProgressWidget()
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

  bool get _directoryVisibility =>
    widget.privacy?.public == true;

  Set<Auth2FieldVisibility> get _permittedVisibility =>
    super.permittedVisibility(widget.contentType);
}
