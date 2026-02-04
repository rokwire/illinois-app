
import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Auth2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/directory/DirectoryAccountsPage.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/profile/ProfileInfoEditPage.dart';
import 'package:illinois/ui/profile/ProfileInfoPreviewPage.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/ui/profile/ProfileBusinessCardPage.dart';
import 'package:illinois/ui/profile/ProfileLoginPage.dart';
import 'package:illinois/ui/profile/ProfileStoredDataPanel.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileInfoPage extends StatefulWidget {
  static const String editParamKey = 'edu.illinois.rokwire.profile.directory.info.edit';

  final Map<String, dynamic>? params;
  final bool onboarding;
  final void Function()? onStateChanged;

  ProfileInfoPage({super.key, this.params, this.onboarding = false, this.onStateChanged});

  @override
  State<StatefulWidget> createState() => ProfileInfoPageState();

  bool? get editParam {
    dynamic edit = (params != null) ? params![editParamKey] : null;
    return (edit is bool) ? edit : null;
  }
}

class ProfileInfoPageState extends State<ProfileInfoPage> with NotificationsListener {

  final GlobalKey<ProfileInfoPreviewPageState> _profileInfoPreviewKey = GlobalKey<ProfileInfoPreviewPageState>();
  final GlobalKey<ProfileInfoEditPageState> _profileInfoEditKey = GlobalKey<ProfileInfoEditPageState>();

  Auth2UserProfile? _profile;
  Auth2UserPrivacy? _privacy;
  Uint8List? _photoImageData;
  Uint8List? _pronunciationAudioData;
  String _photoImageToken = DirectoryProfilePhotoUtils.newToken;

  bool _loading = false;
  bool _editing = false;
  bool _updatingDirectoryVisibility = false;
  bool _preparingDeleteAccount = false;
  bool _signingOut = false;

  bool get _showProfileCommands => (widget.onboarding == false);
  bool get _showAccountCommands => (widget.onboarding == false);

  bool get isLoading => _loading;
  bool get directoryVisibility => (_privacy?.public == true);

  bool get _privacyAvailable => FlexUI().isPrivacyAvailable;
  bool get _directoryVisibilityAvailable =>  _privacyAvailable;
  bool get _directoryVisibilityEnabled => _profile?.isNameNotEmpty == true;

  Future<bool?> saveModified() async => _profileInfoEditKey.currentState?.saveModified();

  @override
  void initState() {
    NotificationService().subscribe(this, [
      DirectoryAccountsPage.notifyEditInfo,
      FlexUI.notifyChanged,
    ]);
    _editing = (widget.editParam == true);
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
    else if (name == FlexUI.notifyChanged) {
      setStateIfMounted((){});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _loadingContent;
    }
    else {
      return Column(children: [
        if (_directoryVisibilityAvailable)
          _directoryVisibilityContent,

        if ((widget.onboarding == false) && _directoryVisibilityAvailable)
          Container(height: 4,),

        Padding(padding: EdgeInsets.only(top: 16), child:
          _editing ? _editContent : _previewContent,
        ),

        if (_showAccountCommands && !_editing)
          _accountCommands,
      ],);
    }
  }

  Widget get _previewContent =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(children: [
        ProfileInfoPreviewPage(
          key: _profileInfoPreviewKey,
          profile: _profile,
          privacy: _privacy,
          onboarding: widget.onboarding,
          pronunciationAudioData: _pronunciationAudioData,
          photoImageData: _photoImageData,
          photoImageToken: _photoImageToken,
        ),
        if (_showProfileCommands)
          Padding(padding: EdgeInsets.only(top: 24), child:
            _previewCommandBar,
          ),
      ]),
    );

  Widget get _editContent =>
    ProfileInfoEditPage(
      key: _profileInfoEditKey,
      authType: Auth2().account?.authType,
      profile: _profile,
      privacy: _privacy,
      onboarding: widget.onboarding,
      pronunciationAudioData: _pronunciationAudioData,
      photoImageData: _photoImageData,
      photoImageToken: _photoImageToken,
      onFinishEdit: _onFinishEditInfo,
  );

  Widget get _directoryVisibilityContent =>
    Semantics(container: true, onTap: _onToggleDirectoryVisibility, child:
      DirectoryProfileCard(child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child:
              Padding(padding: EdgeInsets.only(left: 16, top: 12), child:
                _directoryVisibilityTitle
              ),
            ),
            _directoryVisibilityControl,
          ],),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16,), child:
            Container(height: 1, color: Styles().colors.surfaceAccent,),
          ),
          Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16), child:
            _directoryVisibilityDescription,
          )
        ],)
    ));

  Widget get _directoryVisibilityControl {
    if (_updatingDirectoryVisibility) {
      return _directoryVisibilityProgress;
    }
    else if (_directoryVisibilityEnabled) {
      return _directoryVisibilityToggleButton;
    }
    else {
      return _directoryVisibilityDisabledButton;
    }
  }


  Widget get _directoryVisibilityDisabledButton =>
    Semantics(label: _directoryVisibilityToggleLabel, hint: _directoryVisibilityToggleHint, enabled: _directoryVisibilityEnabled, button: true, excludeSemantics: true, child:
      Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12), child:
        Styles().images.getImage('toggle-off',
          color: Styles().colors.fillColorPrimaryTransparent03,
          colorBlendMode: BlendMode.dstIn,
        )
      )
    );

  Widget get _directoryVisibilityToggleButton =>
    Semantics(label: _directoryVisibilityToggleLabel, hint: _directoryVisibilityToggleHint, value: _directoryVisibilityToggleValue, toggled: directoryVisibility, enabled: _directoryVisibilityEnabled, button: true, excludeSemantics: true, child:
      InkWell(onTap: _onToggleDirectoryVisibility, child:
        Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12), child:
          Styles().images.getImage(directoryVisibility ? 'toggle-on' : 'toggle-off')
        )
      )
    );

  Widget get _directoryVisibilityProgress =>
    Semantics(label: _directoryVisibilityProgressLabel, hint: _directoryVisibilityProgressHint, container: true, child:
      Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12), child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2), child:
            SizedBox(width: 24, height: 24, child:
              CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,)
            )
        )
      )
    );

  Widget get _directoryVisibilityTitle =>
    ExcludeSemantics(child:
      Text(Localization().getStringEx('panel.profile.info.directory_visibility.command.toggle.title', 'Directory Visibility'),
        style: _directoryVisibilityEnabled ?
          Styles().textStyles.getTextStyle('widget.toggle_button.title.regular.enabled') :
          Styles().textStyles.getTextStyle('widget.toggle_button.title.regular.disabled')
    ));

  String get _directoryVisibilityTitleText =>
    Localization().getStringEx('panel.profile.info.directory_visibility.command.toggle.title', 'Directory Visibility');

  String get _directoryVisibilityToggleLabel => _directoryVisibilityTitleText;

  String get _directoryVisibilityToggleValue => AppSemantics.toggleValue(directoryVisibility);

  String get _directoryVisibilityToggleHint => AppSemantics.toggleHint(directoryVisibility,
    enabled: _directoryVisibilityEnabled,
    subject: _directoryVisibilityTitleText
  );

  String get _directoryVisibilityAnnouncement => AppSemantics.toggleAnnouncement(directoryVisibility, subject: _directoryVisibilityTitleText);
  String get _directoryVisibilityFailedAnnouncement => AppSemantics.toggleFailedAnnouncement(directoryVisibility, subject: _directoryVisibilityTitleText);

  String get _directoryVisibilityProgressLabel => _directoryVisibilityTitleText;
  String get _directoryVisibilityProgressHint => AppSemantics.progressHint(subject: _directoryVisibilityTitleText);

  Widget get _directoryVisibilityDescription {

    final String visibilityMacro = "{{visibility}}";

    String messageTemplate = _directoryVisibilityEnabled ? (directoryVisibility ?
      AppTextUtils.appTitleString('panel.profile.info.directory_visibility.public.description', 'Your directory visibility is set to $visibilityMacro. The information below will be visible to ${AppTextUtils.appTitleMacro} app users signed in with their NetIDs.') :
      AppTextUtils.appTitleString('panel.profile.info.directory_visibility.private.description', 'Your directory visibility is set to $visibilityMacro. Your profile is visible only to you.')) :
    AppTextUtils.appTitleString('panel.profile.info.directory_visibility.disabled.description', 'Your directory visibility is $visibilityMacro. Your name is required to be visible to ${AppTextUtils.appTitleMacro} app users.');

    String visibilityValue = _directoryVisibilityEnabled ? (directoryVisibility ?
      Localization().getStringEx('panel.profile.info.directory_visibility.public.text', 'Public') :
      Localization().getStringEx('panel.profile.info.directory_visibility.private.text', 'Private')) :
    Localization().getStringEx('panel.profile.info.directory_visibility.not_enabled.text', 'Not Enabled');

    List<InlineSpan> spanList = StringUtils.split<InlineSpan>(messageTemplate,
      macros: [visibilityMacro],
      builder: (String entry) => (entry == visibilityMacro) ?
        TextSpan(text: visibilityValue, style : Styles().textStyles.getTextStyle("widget.detail.small.fat"),) :
        TextSpan(text: entry)
    );

    return RichText(textAlign: TextAlign.left, text:
      TextSpan(style: Styles().textStyles.getTextStyle("widget.detail.small"), children: spanList)
    );
  }

  void _onToggleDirectoryVisibility() {
    Analytics().logSelect(target: "Directory Visibility: ${directoryVisibility ? 'OFF' : 'ON'}");
    setState(() {
      _updatingDirectoryVisibility = true;
    });
    Auth2UserPrivacy privacy = Auth2UserPrivacy.fromOther(_privacy,
      public: !directoryVisibility,
    );
    Auth2().saveUserPrivacy(privacy).then((bool result){
      if (mounted) {
        if (result) {
          setState(() {
            _updatingDirectoryVisibility = false;
            _editing = false;
            _privacy = privacy;
          });
          AppSemantics.announceMessage(context, _directoryVisibilityAnnouncement);
        }
        else {
          setState(() {
            _updatingDirectoryVisibility = false;
          });
          AppSemantics.announceMessage(context, _directoryVisibilityFailedAnnouncement);
          AppAlert.showTextMessage(context, Localization().getStringEx('panel.profile.info.directory_visibility.toggle.failed.text', 'Failed to update directory visibility.'));
        }
      }
    });
  }

  TextStyle? get nameTextStyle =>
    Styles().textStyles.getTextStyleEx('widget.title.medium_large.fat', fontHeight: 0.85, textOverflow: TextOverflow.ellipsis);

  Widget get _loadingContent => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 64,), child:
    Center(child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,)
      )
    )
  );

  Widget get _previewCommandBar => Row(children: _canShare ? [
    Expanded(flex: 1, child: _shareInfoButton,),
    Container(width: 12,),
    Expanded(flex: 1, child: _editInfoButton,),
  ] : [
    Expanded(flex: 1, child: Container(),),
    Expanded(flex: 2, child: _editInfoButton,),
    Expanded(flex: 1, child: Container(),),
  ],);

  bool get _canShare => (widget.onboarding == false) && Auth2().isOidcLoggedIn && (_profile?.isNotEmpty == true);

  Widget get _shareInfoButton => RoundedButton(
    label: Localization().getStringEx('panel.profile.info.command.button.share.text', 'Export Business Card'),
    fontFamily: Styles().fontFamilies.bold, fontSize: 14,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    onTap: _onShareInfo,
  );

  Widget get _editInfoButton => RoundedButton(
    label: Localization().getStringEx('panel.profile.info.command.button.edit.text', 'Edit My Info'),
    fontFamily: Styles().fontFamilies.bold, fontSize: 14,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    onTap: _onEditInfo,
  );

  Widget get _accountCommands =>
    Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
      Column(children: [
        _signOutButton,
        _viewStoredDataButton,
        _deleteAccountButton,
    ],),
  );

  Widget get _signOutButton => Stack(children: [
    LinkButton(
      title: Localization().getStringEx('panel.profile.info.command.link.sign_out.text', 'Sign Out'),
      textStyle: Styles().textStyles.getTextStyle('widget.button.title.small.underline'),
      padding: EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 16),
      onTap: _onSignOut,
    ),
    if (_signingOut)
      Positioned.fill(child:
        Center(child:
          SizedBox(width: 14, height: 14, child:
            DirectoryProgressWidget()
          )
        )
      )
  ],);

  void _onSignOut() {
    Analytics().logSelect(target: 'Sign Out');
    if (_signingOut != true) {
      showDialog<bool?>(context: context, builder: (context) => ProfilePromptLogoutWidget()).then((bool? result) {
        if (result == true) {
          setState(() {
            _signingOut = true;
          });
          Auth2().logout().then((_){
            setStateIfMounted(() {
              _signingOut = false;
            });
          });
        }
      });
    }
  }

  Widget get _viewStoredDataButton =>
    LinkButton(
      title: Localization().getStringEx('panel.profile.info.command.link.view_stored_data.text', 'View My Stored Information'),
      hint: Localization().getStringEx('panel.profile.info.command.link.view_stored_data.hint', 'See everything we know about you'),
      textStyle: Styles().textStyles.getTextStyle('widget.button.title.small.underline'),
      padding: EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
      onTap: _onViewStoredData,
    );

  void _onViewStoredData() {
    Analytics().logSelect(target: 'View My Stored Information');
    ProfileStoredDataPanel.present(context);
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
              onContinue: (List<String> selectedValues, OnContinueProgressController progressController) => _deleteAccount(selectedValues.contains(groupsSwitchTitle), progressController),
              longButtonTitle: true
          );
        }
      });
    }
  }

  void _deleteAccount(bool deleteContributions, OnContinueProgressController progressController) async {
    Analytics().logAlert(text: "Remove My Information", selection: "Yes");
    progressController(loading: true);
    NetworkAuthProvider? authProvider = Auth2().networkAuthProvider; // Store token before
    bool? result = await Auth2().deleteUser();
    if (result == true) {
      List<Future<bool?>> futures = [
        Inbox().deleteUser(auth: authProvider)
      ];
      if (deleteContributions) {
        futures.addAll(<Future<bool?>>[
          Groups().deleteUserData(auth: authProvider),
          Social().deleteUser(auth: authProvider)
        ]);
      }
      await Future.wait(futures);
      progressController(loading: false);
      Navigator.pop(context);
    }
    else {
      progressController(loading: false);
      AppAlert.showTextMessage(context, Localization().getStringEx('panel.profile.info.delete.failed.text', 'Failed to delete app account.'));
    }
  }

  Future<void> _loadInitialContent() async {
    setState(() {
      _loading = true;
      widget.onStateChanged?.call();
    });

    ProfileInfoLoadResult loadResult = await ProfileInfoLoad.loadInitial();
    setStateIfMounted(() {
      _profile = loadResult.profile;
      _privacy = loadResult.privacy;
      _photoImageData = loadResult.photoImageData;
      _pronunciationAudioData = loadResult.pronunciationAudioData;
      _loading = false;
      widget.onStateChanged?.call();
    });
  }

  void _onShareInfo() {
    Analytics().logSelect(target: 'Export Business Card');
    NotificationService().notify(ProfileHomePanel.notifySelectContent, [
      ProfileContentType.share,
      <String, dynamic>{
        ProfileBusinessCardPage.profileResultKey : ProfileInfoLoadResult(
          profile: _profile,
          privacy: _privacy,
          photoImageData: _photoImageData,
          pronunciationAudioData: _pronunciationAudioData,
        )
      }
    ]);
  }

  void _onEditInfo() {
    Analytics().logSelect(target: 'Edit My Info');
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

      if (_showProfileCommands) {
        _editing = false;
      }
      widget.onStateChanged?.call();
    });
  }
}

///////////////////////////////////////////
// ProfileInfoLoad

class ProfileInfoLoad {

  static bool get _privacyAvailable => FlexUI().isPrivacyAvailable;

  static Future<ProfileInfoLoadResult> loadInitial() async {
    List<dynamic> results = await Future.wait([
      Auth2().loadUserProfile(),
      Auth2().loadUserPrivacy(),
      Content().loadUserPhoto(type: UserProfileImageType.medium),
      Content().loadUserNamePronunciation(),
    ]);

    Auth2UserProfile? profile = JsonUtils.cast<Auth2UserProfile>(ListUtils.entry(results, 0));
    Auth2UserPrivacy? privacy = JsonUtils.cast<Auth2UserPrivacy>(ListUtils.entry(results, 1));
    ImagesResult? photoResult = JsonUtils.cast<ImagesResult>(ListUtils.entry(results, 2));
    AudioResult? pronunciationResult = JsonUtils.cast<AudioResult>(ListUtils.entry(results, 3));

    ProfileInfoLoadResult? syncResult = await _syncUserProfileAndPrivacy(Auth2().account, profile, privacy,
      hasContentUserPhoto: photoResult?.succeeded == true,
      hasContentUserNamePronunciation: pronunciationResult?.succeeded == true,
    );

    if (syncResult?.profile != null) {
      profile = syncResult?.profile;
    }

    if (syncResult?.privacy != null) {
      privacy = syncResult?.privacy;
    }

    Uint8List? photoImageData = photoResult?.imageData;
    if (syncResult?.photoImageData != null) {
      photoImageData = syncResult?.photoImageData;
    }

    Uint8List? pronunciationAudioData = pronunciationResult?.audioData;
    if (syncResult?.pronunciationAudioData != null) {
      pronunciationAudioData = syncResult?.pronunciationAudioData;
    }

    return ProfileInfoLoadResult(
      profile: Auth2UserProfile.fromOther(profile ?? Auth2().profile,),
      privacy: privacy,
      photoImageData: photoImageData,
      pronunciationAudioData: pronunciationAudioData,
    );
  }

  static Future<ProfileInfoLoadResult?> _syncUserProfileAndPrivacy(Auth2Account? account, Auth2UserProfile? profile, Auth2UserPrivacy? privacy, {
    bool? hasContentUserPhoto,
    bool? hasContentUserNamePronunciation
  }) async {

    // Check if user profile needs synchronization
    Auth2UserProfile? updatedProfile = null;
    Set<Auth2UserProfileScope> updateProfileScope = <Auth2UserProfileScope>{};

    // Photo Url?
    String? profilePhotoUrl = profile?.photoUrl;
    if (hasContentUserPhoto != null) {
      bool profileHasUserPhoto = StringUtils.isNotEmpty(profilePhotoUrl);
      if (profileHasUserPhoto != hasContentUserPhoto) {
        profilePhotoUrl = hasContentUserPhoto ? Content().getUserPhotoUrl(accountId: Auth2().accountId, type: UserProfileImageType.medium) : "";
        updateProfileScope.add(Auth2UserProfileScope.photoUrl);
      }
    }

    // Pronunciation Url?
    String? profilePronunciationUrl = profile?.pronunciationUrl;
    if (hasContentUserNamePronunciation != null) {
      bool profileHasPronunciationUrl = StringUtils.isNotEmpty(profilePronunciationUrl);
      if (profileHasPronunciationUrl != hasContentUserNamePronunciation) {
        profilePronunciationUrl = hasContentUserNamePronunciation ? Content().getUserNamePronunciationUrl(accountId: Auth2().accountId) : "";
        updateProfileScope.add(Auth2UserProfileScope.pronunciationUrl);
      }
    }

    // First/Middle/Last Names & Email?
    String? profileFirstName = profile?.firstName;
    String? profileMiddleName = profile?.middleName;
    String? profileLastName = profile?.lastName;
    String? profileEmail = profile?.email;
    String? profilePhone = profile?.phone;

    List<Auth2Type>? authTypes = account?.authTypes;
    if (authTypes != null) {

      // First Name?
      if (StringUtils.isEmpty(profileFirstName)) {
        for (Auth2Type authType in authTypes) {
          if (StringUtils.isNotEmpty(authType.uiucUser?.firstName)) {
            profileFirstName = authType.uiucUser?.firstName;
            updateProfileScope.add(Auth2UserProfileScope.firstName);
            break;
          }
        }
      }

      // Middle Name?
      if (StringUtils.isEmpty(profileMiddleName)) {
        for (Auth2Type authType in authTypes) {
          if (StringUtils.isNotEmpty(authType.uiucUser?.middleName)) {
            profileMiddleName = authType.uiucUser?.middleName;
            updateProfileScope.add(Auth2UserProfileScope.middleName);
            break;
          }
        }
      }

      // Last Name?
      if (StringUtils.isEmpty(profileLastName)) {
        for (Auth2Type authType in authTypes) {
          if (StringUtils.isNotEmpty(authType.uiucUser?.lastName)) {
            profileLastName = authType.uiucUser?.lastName;
            updateProfileScope.add(Auth2UserProfileScope.lastName);
            break;
          }
        }
      }

      // Email? => Round 1, from illinois_oidc auth type
      if (StringUtils.isEmpty(profileEmail)) {
        for (Auth2Type authType in authTypes) {
          if (StringUtils.isNotEmpty(authType.uiucUser?.email)) {
            profileEmail = authType.uiucUser?.email;
            updateProfileScope.add(Auth2UserProfileScope.email);
            break;
          }
        }
      }

      // Email? => Round 2, from email auth type
      if (StringUtils.isEmpty(profileEmail)) {
        for (Auth2Type authType in authTypes) {
          if ((authType.loginType == Auth2LoginType.email) && StringUtils.isNotEmpty(authType.identifier)) {
            profileEmail = authType.identifier;
            updateProfileScope.add(Auth2UserProfileScope.email);
            break;
          }
        }
      }

      // Phone?
      if (StringUtils.isEmpty(profilePhone)) {
        for (Auth2Type authType in authTypes) {
          if (((authType.loginType == Auth2LoginType.phone) || (authType.loginType == Auth2LoginType.phoneTwilio)) && StringUtils.isNotEmpty(authType.identifier)) {
            profilePhone = authType.identifier;
            updateProfileScope.add(Auth2UserProfileScope.phone);
            break;
          }
        }
      }
    }

    if (updateProfileScope.isNotEmpty) {
      updatedProfile = Auth2UserProfile.fromOther(profile,
        override: Auth2UserProfile(
          photoUrl: profilePhotoUrl,
          pronunciationUrl: profilePronunciationUrl,
          firstName: profileFirstName,
          middleName: profileMiddleName,
          lastName: profileLastName,
          email: profileEmail,
          phone: profilePhone,
        ),
        scope: updateProfileScope);

      debugPrint("ProfileInfo: Detected Requred Updates:\n${JsonUtils.encode(updatedProfile.toJson(), prettify: true)}");
    }

    bool isProfileNameNotEmpty = StringUtils.isNotEmpty(profileFirstName) || StringUtils.isNotEmpty(profileMiddleName) || StringUtils.isNotEmpty(profileLastName);
    bool? privacyIsPublic = (_privacyAvailable && (privacy?.public == null) && isProfileNameNotEmpty) ? true : privacy?.public;
    Auth2UserPrivacy? updatedPrivacy = (privacyIsPublic != null) ? Auth2UserPrivacy.fromOther(privacy,
      public: privacyIsPublic,
      fieldsVisibility: Auth2AccountFieldsVisibility.fromOther(privacy?.fieldsVisibility,
        profile: Auth2UserProfileFieldsVisibility.fromOther(privacy?.fieldsVisibility?.profile,
          firstName: (privacy?.fieldsVisibility?.profile?.firstName != Auth2FieldVisibility.public) ? Auth2FieldVisibility.public : privacy?.fieldsVisibility?.profile?.firstName,
          middleName: (privacy?.fieldsVisibility?.profile?.middleName != Auth2FieldVisibility.public) ? Auth2FieldVisibility.public : privacy?.fieldsVisibility?.profile?.middleName,
          lastName: (privacy?.fieldsVisibility?.profile?.lastName != Auth2FieldVisibility.public) ? Auth2FieldVisibility.public : privacy?.fieldsVisibility?.profile?.lastName,
          email: ((account?.authType?.loginType?.shouldHaveEmail == true) && (privacy?.fieldsVisibility?.profile?.email != Auth2FieldVisibility.public)) ? Auth2FieldVisibility.public : privacy?.fieldsVisibility?.profile?.email,
          phone: ((account?.authType?.loginType?.shouldHavePhone == true) && (privacy?.fieldsVisibility?.profile?.phone != Auth2FieldVisibility.public)) ? Auth2FieldVisibility.public : privacy?.fieldsVisibility?.profile?.phone,
        )
      )
    ) : null;


    List<Future<bool>> updateFutures = <Future<bool>>[];

    int updateProfileIndex = ((updatedProfile != null) && (updatedProfile != profile)) ? updateFutures.length : -1;
    if (0 <= updateProfileIndex) {
      updateFutures.add(Auth2().saveUserProfile(updatedProfile));
    }

    int updatePrivacyIndex = (_privacyAvailable && (updatedPrivacy != null) && (updatedPrivacy != privacy)) ? updateFutures.length : -1;
    if (0 <= updatePrivacyIndex) {
      updateFutures.add(Auth2().saveUserPrivacy(updatedPrivacy));
    }

    if (0 < updateFutures.length) {
      List<bool> updateResults = await Future.wait(updateFutures);
      bool? updateProfileResult = (0 <= updateProfileIndex) ? updateResults[updateProfileIndex] : null;
      bool? updatePrivacyResult = (0 <= updatePrivacyIndex) ? updateResults[updatePrivacyIndex] : null;
      return ProfileInfoLoadResult(
        profile: (updateProfileResult == true) ? updatedProfile : null,
        privacy: (updatePrivacyResult == true) ? updatedPrivacy : null,
      );
    }
    else {
      return null;
    }
  }
}

///////////////////////////////////////////
// ProfileInfoSyncResult

class ProfileInfoLoadResult {
  final Auth2UserProfile? profile;
  final Auth2UserPrivacy? privacy;
  final Uint8List? photoImageData;
  final Uint8List? pronunciationAudioData;

  ProfileInfoLoadResult({this.profile, this.privacy, this.photoImageData, this.pronunciationAudioData});
}
