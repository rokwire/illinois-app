
import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/directory/DirectoryAccountsPage.dart';
import 'package:illinois/ui/profile/ProfileInfoEditPage.dart';
import 'package:illinois/ui/profile/ProfileInfoPreviewPage.dart';
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
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileInfoPage extends StatefulWidget {
  static const String editParamKey = 'edu.illinois.rokwire.profile.directory.info.edit';

  final ProfileInfo contentType;
  final Map<String, dynamic>? params;
  final bool showAccountCommands;
  final void Function()? onStateChanged;

  ProfileInfoPage({super.key, required this.contentType, this.params, this.showAccountCommands = false, this.onStateChanged});

  @override
  State<StatefulWidget> createState() => ProfileInfoPageState();

  bool? get editParam {
    dynamic edit = (params != null) ? params![editParamKey] : null;
    return (edit is bool) ? edit : null;
  }
}

class ProfileInfoPageState extends ProfileDirectoryMyInfoBasePageState<ProfileInfoPage> implements NotificationsListener {

  Auth2UserProfile? _profile;
  Auth2UserPrivacy? _privacy;
  Uint8List? _photoImageData;
  Uint8List? _pronunciationAudioData;
  String _photoImageToken = DirectoryProfilePhotoUtils.newToken;

  bool _loading = false;
  bool _editing = false;
  bool _preparingDeleteAccount = false;

  bool get previewMode => !_loading && !_editing;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      DirectoryAccountsPage.notifyEditInfo,
    ]);
    _editing = widget.editParam ?? false;
    _loadInitialContent();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void onNotification(String name, param) {
    if (name == DirectoryAccountsPage.notifyEditInfo) {
      setStateIfMounted((){
        _editing = true;
        widget.onStateChanged?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _loadingContent;
    }
    else if (_editing) {
      return ProfileInfoEditPage(
          contentType: widget.contentType,
          profile: _profile,
          privacy: _privacy,
          pronunciationAudioData: _pronunciationAudioData,
          photoImageData: _photoImageData,
          photoImageToken: _photoImageToken,
          onFinishEdit: _onFinishEditInfo,
      );
    }
    else {
      return Column(children: [
        ProfileInfoPreviewPage(
          contentType: widget.contentType,
          profile: _profile,
          privacy: _privacy,
          pronunciationAudioData: _pronunciationAudioData,
          photoImageData: _photoImageData,
          photoImageToken: _photoImageToken,
          onEditInfo: _onEditInfo,
        ),
        if (widget.showAccountCommands)
          _accountCommands,
      ],);
    }
  }

  Widget get _loadingContent => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 64,), child:
    Center(child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,)
      )
    )
  );

  Widget get _accountCommands => Column(children: [
    Padding(padding: EdgeInsets.only(top: 8)),
    _signOutButton,
    _deleteAccountButton,
    Padding(padding: EdgeInsets.only(top: 8)),
  ],);

  Widget get _signOutButton => LinkButton(
    title: Localization().getStringEx('panel.profile.info.command.link.sign_out.text', 'Sign Out'),
    textStyle: Styles().textStyles.getTextStyle('widget.button.title.small.underline'),
    padding: EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 16),
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
      padding: EdgeInsets.only(top: 8, bottom: 16, left: 16, right: 16),
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

  Future<void> _loadInitialContent() async {
    setState(() {
      _loading = true;
      widget.onStateChanged?.call();
    });

    List<dynamic> results = await Future.wait([
      Auth2().loadUserProfile(),
      Auth2().loadUserPrivacy(),
      Content().loadUserPhoto(type: UserProfileImageType.medium),
      Content().loadUserNamePronunciation(),
    ]);

    if (mounted) {
      Auth2UserProfile? profile = JsonUtils.cast<Auth2UserProfile>(ListUtils.entry(results, 0));
      Auth2UserPrivacy? privacy = JsonUtils.cast<Auth2UserPrivacy>(ListUtils.entry(results, 1));
      ImagesResult? photoResult = JsonUtils.cast<ImagesResult>(ListUtils.entry(results, 2));
      AudioResult? pronunciationResult = JsonUtils.cast<AudioResult>(ListUtils.entry(results, 3));

      Auth2UserProfile? updatedProfile = await _syncUserProfile(profile,
        hasContentUserPhoto: photoResult?.succeeded == true,
        hasContentUserNamePronunciation: pronunciationResult?.succeeded == true,
      );
      if (updatedProfile != null) {
        profile = updatedProfile;
      }

      setState(() {
        //TMP: Added some sample data
        _profile = Auth2UserProfile.fromOther(profile ?? Auth2().profile,);
        _privacy = privacy;
        _photoImageData = photoResult?.imageData;
        _pronunciationAudioData = pronunciationResult?.audioData;
        _loading = false;
        widget.onStateChanged?.call();
      });
    }
  }

  Future<Auth2UserProfile?> _syncUserProfile(Auth2UserProfile? profile, { bool? hasContentUserPhoto, bool? hasContentUserNamePronunciation }) async {
    if (profile != null) {

      Set<Auth2UserProfileScope> updateProfileScope = <Auth2UserProfileScope>{};

      String? profilePhotoUrl = profile.photoUrl;
      if (hasContentUserPhoto != null) {
        bool profileHasUserPhoto = StringUtils.isNotEmpty(profilePhotoUrl);
        if (profileHasUserPhoto != hasContentUserPhoto) {
          profilePhotoUrl = hasContentUserPhoto ? Content().getUserPhotoUrl(accountId: Auth2().accountId, type: UserProfileImageType.medium) : "";
          updateProfileScope.add(Auth2UserProfileScope.photoUrl);
        }
      }

      String? profilePronunciationUrl = profile.pronunciationUrl;
      if (hasContentUserNamePronunciation != null) {
        bool profileHasPronunciationUrl = StringUtils.isNotEmpty(profilePronunciationUrl);
        if (profileHasPronunciationUrl != hasContentUserNamePronunciation) {
          profilePronunciationUrl = hasContentUserNamePronunciation ? Content().getUserNamePronunciationUrl(accountId: Auth2().accountId) : "";
          updateProfileScope.add(Auth2UserProfileScope.pronunciationUrl);
        }
      }

      if (updateProfileScope.isNotEmpty) {
        Auth2UserProfile updatedProfile = Auth2UserProfile.fromOther(profile,
          override: Auth2UserProfile(
            photoUrl: profilePhotoUrl,
            pronunciationUrl: profilePronunciationUrl,
          ),
          scope: updateProfileScope);

        bool updateResult = await Auth2().saveUserProfile(updatedProfile);
        if (updateResult == true) {
          return updatedProfile;
        }
      }
    }

    return null;
  }

  void _onEditInfo() {
    setStateIfMounted(() {
      _editing = true;
      widget.onStateChanged?.call();
    });
  }

  void _onFinishEditInfo({Auth2UserProfile? profile, Auth2UserPrivacy? privacy,
    Uint8List? pronunciationAudioData,
    Uint8List? photoImageData,
    String? photoImageToken
  }) {
    setStateIfMounted((){
      if (profile != null) {
        _profile = profile;
      }

      if (privacy != null) {
        _privacy = privacy;
      }

      if ((_photoImageToken != photoImageToken) && (photoImageToken != null)) {
        _photoImageToken = photoImageToken;
      }

      if (!DeepCollectionEquality().equals(_photoImageData, photoImageData)) {
        _photoImageData = photoImageData;
      }

      if (!DeepCollectionEquality().equals(_pronunciationAudioData, pronunciationAudioData)) {
        _pronunciationAudioData = pronunciationAudioData;
      }

      _editing = false;
      widget.onStateChanged?.call();
    });
  }
}

///////////////////////////////////////////
// _ProfileDirectoryMyInfoUtilsPageState

class ProfileDirectoryMyInfoBasePageState<T extends StatefulWidget> extends State<T> {

  // Name Text Style

  TextStyle? get nameTextStyle =>
    Styles().textStyles.getTextStyleEx('widget.title.medium_large.fat', fontHeight: 0.85, textOverflow: TextOverflow.ellipsis);

  // Positive and Permitted visibility

  static const Auth2FieldVisibility _directoryPositiveVisibility = Auth2FieldVisibility.public;
  static const Auth2FieldVisibility _connectionsPositiveVisibility = Auth2FieldVisibility.connections;

  Auth2FieldVisibility positiveVisibility(ProfileInfo contentType) {
    switch(contentType) {
      case ProfileInfo.directoryInfo: return _directoryPositiveVisibility;
      case ProfileInfo.connectionsInfo: return _connectionsPositiveVisibility;
    }
  }

  static const Set<Auth2FieldVisibility> _directoryPermittedVisibility = const <Auth2FieldVisibility>{ _directoryPositiveVisibility };
  static const Set<Auth2FieldVisibility> _connectionsPermittedVisibility = const <Auth2FieldVisibility>{ _directoryPositiveVisibility, _connectionsPositiveVisibility };

  Set<Auth2FieldVisibility> permittedVisibility(ProfileInfo contentType) {
    switch(contentType) {
      case ProfileInfo.directoryInfo: return _directoryPermittedVisibility;
      case ProfileInfo.connectionsInfo: return _connectionsPermittedVisibility;
    }
  }

  @override
  Widget build(BuildContext context) =>
    throw UnimplementedError();
}
