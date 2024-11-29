
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/groups/ImageEditPanel.dart';
import 'package:illinois/ui/profile/ProfileDirectoryPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryWidgets.dart';
import 'package:illinois/ui/profile/ProfileLoginPage.dart';
import 'package:illinois/ui/profile/ProfileVoiceRecordigWidgets.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/AudioUtils.dart';
import 'package:just_audio/just_audio.dart';
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

enum _ProfileField {
  firstName, middleName, lastName, pronouns,
  birthYear, photoUrl, pronunciationUrl,
  email, email2, phone, website,
  college, department, major, title,
  address, state, zip, country,
}

class _ProfileDirectoryMyInfoPageState extends State<ProfileDirectoryMyInfoPage> with WidgetsBindingObserver {

  Auth2UserProfile? _profile;
  // ignore: unused_field
  Auth2UserPrivacy? _privacy;
  Auth2UserProfileFieldsVisibility? _profileVisibility;
  Auth2UserProfile? _previewProfile;

  bool _loading = false;
  bool _editing = false;
  bool _saving = false;
  bool _preparingDeleteAccount = false;
  bool _clearingUserPhoto = false;
  bool _clearingUserPronunciation = false;
  bool _initializingAudioPlayer = false;
  AudioPlayer? _audioPlayer;

  late double _screenInsetsBottom;
  Timer? _onScreenInsetsBottomChangedTimer;

  static const String _photoImageKey = 'edu.illinois.rokwire.token';
  String _photoImageToken = _DateTimeUtils.imageToken;

  Map<_ProfileField, Auth2FieldVisibility?>? _fieldVisibilities;
  final Map<_ProfileField, TextEditingController?> _fieldTextControllers = {};
  final Map<_ProfileField, FocusNode?> _fieldFocusNodes = {};

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    });
    for (_ProfileField field in _ProfileField.values) {
      _fieldTextControllers[field] = TextEditingController();
      _fieldFocusNodes[field] = FocusNode();
    }
    _loadProfileAndPrivacy();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (_ProfileField field in _ProfileField.values) {
      _fieldTextControllers[field]?.dispose();
      _fieldFocusNodes[field]?.dispose();
    }
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _loadingContent;
    }
    else if (_editing) {
      return _editContent;
    }
    else {
      return _previewContent;
    }
  }

  @override
  void didChangeMetrics() {
    double screenInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    if (screenInsetsBottom != _screenInsetsBottom) {
      _screenInsetsBottom = screenInsetsBottom;
      _onScreenInsetsBottomChangedTimer?.cancel();
      _onScreenInsetsBottomChangedTimer = Timer(Duration(milliseconds: 100), _didChangeScreenInsetsBottom);
    }
  }

  void _didChangeScreenInsetsBottom() {
    _onScreenInsetsBottomChangedTimer = null;
    setStateIfMounted(() {
    });
  }

  //////////////////////////////
  // Preview Content

  Widget get _previewContent =>
      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        Column(children: [
          Text(_previewDesriptionText, style: Styles().textStyles.getTextStyle('widget.detail.small'), textAlign: TextAlign.center,),
          Padding(padding: EdgeInsets.only(top: 24), child:
              Stack(children: [
                Padding(padding: EdgeInsets.only(top: _previewPhotoImageSize / 2), child:
                  _previewCardWidget,
                ),
                Center(child:
                  DirectoryProfilePhoto(_previewPhotoUrl, imageSize: _previewPhotoImageSize, headers: _photoImageHeaders,),
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

  String? get _previewPhotoUrl => _photoImageUrl(_previewProfile?.photoUrl);

  double get _previewPhotoImageSize => MediaQuery.of(context).size.width / 3;

  String? _photoImageUrl(String? photoUrl) => (photoUrl != null) ?
    UrlUtils.addQueryParameters(photoUrl, { _photoImageKey : _photoImageToken}) : null;

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
              _previewCardContentHeading,
            ),
          ],),
        ),
        Padding(padding: EdgeInsets.only(top: 12), child:
          DirectoryProfileDetails(_previewProfile)
        ),
        _shareButton,
    ],)
  );

  Widget get _previewCardContentHeading =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_previewProfile?.fullName ?? '', style: _nameTextStyle, textAlign: TextAlign.center,),
      if (_previewProfile?.pronouns?.isNotEmpty == true)
        Text(_previewProfile?.pronouns ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small')),
    ]);

  TextStyle? get _nameTextStyle =>
    Styles().textStyles.getTextStyleEx('widget.title.medium_large.fat', fontHeight: 0.85);

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

    for (_ProfileField field in _ProfileField.values) {
      _fieldTextControllers[field]?.text = _profile?.fieldValue(field) ?? '';
    }

    setState(() {
      _editing = true;
      _fieldVisibilities = _profileVisibility?.fieldsVisibility ?? <_ProfileField, Auth2FieldVisibility?>{};
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
            _progressWidget
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

  //////////////////////////////
  // Loading Content

  Widget get _loadingContent => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 64,), child:
    Center(child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,)
      )
    )
  );

  //////////////////////////////
  // Editing Content

  Widget get _editContent =>
    Padding(padding: EdgeInsets.zero, child:
      Column(children: [
        Text(_editDesriptionText, style: Styles().textStyles.getTextStyle('widget.detail.small'), textAlign: TextAlign.center,),
        Padding(padding: EdgeInsets.only(top: 24), child:
          _editPhotoWidget,
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
          _editNameWidget,
        ),

        _editPronunciationSection,
        _editPronounsSection,
        _editTitleSection,
        _editCollegeSection,
        _editDepartmentSection,
        _editMajorSection,
        _editEmailSection,
        _editEmail2Section,
        _editPhoneSection,
        _editWebsiteSection,

        Padding(padding: EdgeInsets.only(top: 24), child:
          _editCommandBar,
        ),
        Padding(padding: EdgeInsets.only(top: 8)),
        if (_screenInsetsBottom > 0)
          Padding(padding: EdgeInsets.only(top: _screenInsetsBottom)),
      ],),
    );

  String get _editDesriptionText {
    switch (widget.contentType) {
      case MyProfileInfo.myConnectionsInfo: return AppTextUtils.appTitleString('panel.profile.directory.my_info.connections.edit.description.text', 'Choose how your profile displays for your ${AppTextUtils.appTitleMacro} Connections.');
      case MyProfileInfo.myDirectoryInfo: return AppTextUtils.appTitleString('panel.profile.directory.my_info.directory.edit.description.text', 'Choose how your profile displays in the directory.');
    }
  }

  // Edit: Photo

  String? get _editPhotoUrl => _photoImageUrl(StringUtils.ensureEmpty(_editPhotoText));
  double get _editPhotoImageSize => MediaQuery.of(context).size.width / 3;

  Widget get _editPhotoWidget => Stack(children: [
    Padding(padding: EdgeInsets.only(left: 8, right: 8, bottom: 20), child:
      DirectoryProfilePhoto(_editPhotoUrl, imageSize: _editPhotoImageSize, headers: _photoImageHeaders,),
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

  Widget get _editPhotoButton =>
    _editPhotoIconButton(_editIcon,
      onTap: _onEditPhotoButton,
      progress: _clearingUserPhoto,
    );

  void _onEditPhotoButton() {
    Analytics().logSelect(target: 'Edit Photo');
    if (StringUtils.isNotEmpty(_editPhotoText)) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) => Container(padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16), child:
          Column(mainAxisSize: MainAxisSize.min, children: [
            RibbonButton(label: Localization().getStringEx('panel.profile.directory.my_info.command.button.photo.edit.text', 'Edit Photo'), rightIconKey: 'edit', onTap: () { Navigator.of(context).pop(); _onEditPhoto(); }),
            RibbonButton(label: Localization().getStringEx('panel.profile.directory.my_info.command.button.photo.clear.text', 'Clear Photo'), rightIconKey: 'clear', onTap: () { Navigator.of(context).pop(); _onClearPhoto(); }),
          ])
        ),
      );
    }
    else {
      _onEditPhoto();
    }
  }

  void _onEditPhoto() {
    Analytics().logSelect(target: 'Edit Photo');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ImageEditPanel(isUserPic: true))).then((imageUploadResult) {
      if (mounted && (imageUploadResult is ImagesResult)) {
        if (imageUploadResult.resultType == ImagesResultType.succeeded) {
          setState(() {
            _editPhotoText = Content().getUserPhotoUrl(accountId: Auth2().accountId, type: UserProfileImageType.medium) ?? '';
            _photoImageToken = _DateTimeUtils.imageToken;
          });
        }
        else if (imageUploadResult.resultType == ImagesResultType.error) {
          AppAlert.showDialogResult(context, Localization().getStringEx('panel.profile_info.picture.upload.failed.msg', 'Failed to upload profile picture. Please, try again later.'));
        }
      }
    });
  }

  void _onClearPhoto() {
    Analytics().logSelect(target: 'Clear Photo');
    AppAlert.showConfirmationDialog(buildContext: context,
        message: _clearPhotoPrompt(),
        positiveButtonLabel: Localization().getStringEx('dialog.ok.title', 'OK'),
        negativeButtonLabel: Localization().getStringEx('dialog.cancel.title', 'Cancel'),
    ).then((bool result) {
      if (result) {
        _onConfirmClearPhoto();
      } else {
        _onCancelClearPhoto();
      }
    });
  }

  String _clearPhotoPrompt({ String? language }) =>
    Localization().getStringEx('panel.profile_info.picture.delete.confirmation.msg', 'Are you sure you want to remove this profile picture?', language: language);

  void _onConfirmClearPhoto() {
    Analytics().logAlert(text: _clearPhotoPrompt(language: 'en'), selection: 'OK');
    setState(() {
      _clearingUserPhoto = true;
    });
    Content().deleteUserPhoto().then((ImagesResult deleteImageResult) {
      if (mounted) {
        setState(() {
          _clearingUserPhoto = false;
        });
        if (deleteImageResult.resultType == ImagesResultType.succeeded) {
          setState(() {
            _editPhotoText = '';
          });
        }
        else if (deleteImageResult.resultType == ImagesResultType.error) {
          AppAlert.showDialogResult(context, Localization().getStringEx('panel.profile_info.picture.delete.failed.msg', 'Failed to delete profile picture. Please, try again later.'));
        }
      }
    });
  }

  void _onCancelClearPhoto() {
    Analytics().logAlert(text: _clearPhotoPrompt(language: 'en'), selection: 'OK');
  }

  Widget get _togglePhotoVisibilityButton =>
    _editPhotoIconButton(_editVisibilityIcon(_fieldVisibilities?[_ProfileField.photoUrl]),
      onTap: () => _onToggleFieldVisibility(_ProfileField.photoUrl)
    );

  Widget _editPhotoIconButton(Widget? icon, { void Function()? onTap, bool progress = false}) =>
    InkWell(onTap: onTap, child:
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Styles().colors.white,
          border: Border.all(color: Styles().colors.surfaceAccent, width: 1)
        ),
        child: Padding(padding: EdgeInsets.all(12),
          child: progress ? SizedBox(
            width: _editButtonIconSize,
            height: _editButtonIconSize,
            child: _progressWidget,
          ) : icon
        ),
      )
    );

  static const double _editButtonIconSize = 16;

  Widget get _editNameWidget =>
    Text(_profile?.fullName ?? '', style: _nameTextStyle, textAlign: TextAlign.center,);

  // Edit: Pronunciation

  Widget get _editPronunciationSection => _editFieldSection(
    headingTitle: Localization().getStringEx('panel.profile.directory.my_info.title.pronunciation.text', 'Name Pronunciation'),
    fieldControl: StringUtils.isNotEmpty(_editPronunciationText) ? _pronunciationEditBar: _pronunciationCreateControl,
  );

  Widget get _pronunciationCreateControl => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Styles().images.getImage('plus-circle', size: 24) ?? Container(),
    Expanded(child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 6), child:
        InkWell(onTap: _onCreatePronunciation, child:
          Text(_pronunciationCreateText(), style: Styles().textStyles.getTextStyle('widget.detail.small.underline'),)
        ),
      ),
    ),
    Padding(padding: EdgeInsets.only(left: 6), child:
      _editVisibilityButton(_ProfileField.pronunciationUrl),
    ),
  ],);

  String _pronunciationCreateText({String? language}) =>
    Localization().getStringEx('panel.profile.directory.my_info.command.link.pronunciation.text', 'Add name pronunciation and how you prefer to be addressed (Ex: "Please call me Dr. Last Name, First Name or Nickname")', language: language);

  Widget get _pronunciationEditBar => Row(children: [
    Wrap( spacing: 6, runSpacing: 6, children: [
      _pronunciationPreviewButton,
      _pronunciationEditButton,
      _pronunciationDeleteButton,
      _editVisibilityButton(_ProfileField.pronunciationUrl),
    ],)
  ],);

  Widget get _pronunciationPreviewButton => _editIconButton(
    icon: _pronunciationPreviewIcon,
    progress: _initializingAudioPlayer,
    onTap: _onPreviewPronunciation,
  );

  Widget? get _pronunciationPreviewIcon => (_audioPlayer?.playing == true) ? _pauseIcon : _playIcon;

  Widget get _pronunciationEditButton => _editIconButton(
    icon: _editIcon,
    onTap: _onEditPronunciation,
  );

  Widget get _pronunciationDeleteButton => _editIconButton(
    icon: _trashIcon,
    progress: _clearingUserPronunciation,
    onTap: _onDeletePronunciation,
  );

  void _onCreatePronunciation() {
    Analytics().logSelect(target: _pronunciationCreateText(language: 'en'));
    _createPronunciation();
  }

  void _onEditPronunciation() {
    Analytics().logSelect(target: 'Edit Pronuncaion');
    _createPronunciation();
  }

  void _createPronunciation() {
    ProfileSoundRecorderDialog.show(context).then((AudioResult? result) {
      if (result?.resultType == AudioResultType.succeeded) {
        setState(() {
          _editPronunciationText = Content().getUserNamePronunciationUrl(accountId: Auth2().accountId);
        });
      }
    });
  }

  void _onDeletePronunciation() {
    Analytics().logSelect(target: 'Delete Pronuncaion');
    //AppAlert.showConfirmationDialog(bu)
    ProfileNamePronouncementConfirmDeleteDialog.show(context).then((bool? result) {
      if (mounted && (result == true)) {
        setState(() {
          _clearingUserPronunciation = true;
        });
        Content().deleteUserNamePronunciation().then((AudioResult? result){
          if (mounted) {
            if (result?.resultType == AudioResultType.succeeded) {
              setState(() {
                _clearingUserPronunciation = false;
                _editPronunciationText = null;
              });
            }
            else {
              setState(() {
                _clearingUserPronunciation = false;
              });
              AppAlert.showTextMessage(context, Localization().getStringEx('panel.profile_info.pronunciation.delete.failed.msg', 'Failed to delete pronunciation audio. Please try again later.'));
            }
          }
        });
      }
    });
  }

  void _onPreviewPronunciation() async {
    if (_audioPlayer == null) {
      setState(() {
        _initializingAudioPlayer = true;
      });

      AudioResult? result = await Content().loadUserNamePronunciation(accountId: Auth2().accountId);
      if (mounted) {
        Uint8List? audioData = (result?.resultType == AudioResultType.succeeded) ? result?.data : null;
        if (audioData != null) {
          _audioPlayer = AudioPlayer();

          _audioPlayer?.playerStateStream.listen((PlayerState state) {
            if ((state.processingState == ProcessingState.completed) && mounted) {
              setState(() {
                _audioPlayer?.dispose();
                _audioPlayer = null;
              });
            }
          });

          Duration? duration;
          try { duration = await _audioPlayer?.setAudioSource(Uint8ListAudioSource(audioData)); }
          catch(e) {}

          if (mounted) {
            if ((duration != null) && (duration.inMilliseconds > 0)) {
              setState(() {
                _initializingAudioPlayer = false;
                _audioPlayer?.play();
              });
            }
            else {
              _handlePronunciationPlaybackError();
            }
          }
        }
        else {
          _handlePronunciationPlaybackError();
        }
      }
    }
    else if (_audioPlayer?.playing == true) {
      _audioPlayer?.pause();
    }
    else {
      _audioPlayer?.play();
    }
  }

  void _handlePronunciationPlaybackError() {
    setState(() {
      _initializingAudioPlayer = false;
      _audioPlayer?.dispose();
      _audioPlayer = null;
    });
    AppAlert.showTextMessage(context, Localization().getStringEx('panel.profile.directory.my_info.playback.failed.text', 'Failed to play audio stream.'));
  }

  // Edit: Other Sections

  Widget get _editPronounsSection => _editTextFieldSection(_ProfileField.pronouns,
    headingTitle: Localization().getStringEx('panel.profile.directory.my_info.title.pronouns.text', 'Pronouns'),
  );

  Widget get _editTitleSection => _editTextFieldSection(_ProfileField.title,
    headingTitle: Localization().getStringEx('panel.profile.directory.my_info.title.title.text', 'Title'),
    headingHint: Localization().getStringEx('panel.profile.directory.my_info.title.title.hint', '(Ex: Professional/Extracurricular Role)')
  );

  Widget get _editCollegeSection => _editTextFieldSection(_ProfileField.college,
    headingTitle: Localization().getStringEx('panel.profile.directory.my_info.title.college.text', 'College'),
    enabled: false,
  );

  Widget get _editDepartmentSection => _editTextFieldSection(_ProfileField.department,
    headingTitle: Localization().getStringEx('panel.profile.directory.my_info.title.department.text', 'Department'),
    enabled: false,
  );

  Widget get _editMajorSection => _editTextFieldSection(_ProfileField.major,
    headingTitle: Localization().getStringEx('panel.profile.directory.my_info.title.major.text', 'Major'),
    enabled: false,
  );

  Widget get _editEmailSection => _editTextFieldSection(_ProfileField.email,
    headingTitle: Localization().getStringEx('panel.profile.directory.my_info.title.email.text', 'Email Address'),
    enabled: false, public: true,
  );

  Widget get _editEmail2Section => _editTextFieldSection(_ProfileField.email2,
    headingTitle: Localization().getStringEx('panel.profile.directory.my_info.title.email2.text', 'Alternate Email Address'),
  );

  Widget get _editPhoneSection => _editTextFieldSection(_ProfileField.phone,
    headingTitle: Localization().getStringEx('panel.profile.directory.my_info.title.phone.text', 'Phone Number'),
  );

  Widget get _editWebsiteSection => _editTextFieldSection(_ProfileField.website,
    headingTitle: Localization().getStringEx('panel.profile.directory.my_info.title.website.text', 'Website URL'),
    headingHint: Localization().getStringEx('panel.profile.directory.my_info.title.website.hinr', '(Ex: Linkedin)'),
  );

  Widget _editTextFieldSection(_ProfileField field, {
    String? headingTitle, String? headingHint,
    TextInputType textInputType = TextInputType.text,
    bool autocorrect = true,
    bool enabled = true,
    bool public = false,
  }) => _editFieldSection(
    headingTitle: headingTitle,
    headingHint: headingTitle,
    fieldControl: _editTextFieldControl(field,
        textInputType: textInputType,
        autocorrect: autocorrect,
        enabled: enabled,
        public: public,
    )
  );

  Widget _editTextFieldControl(_ProfileField field, {
    TextInputType textInputType = TextInputType.text,
    bool autocorrect = true,
    bool enabled = true,
    bool public = false,
    }) => Row(children: [
      Expanded(child:
        _editTextWidget(field, textInputType: textInputType, autocorrect: autocorrect, enabled: enabled)
      ),
      Padding(padding: EdgeInsets.only(left: 6), child:
        _editVisibilityButton(field, public: public),
      ),
    ],);

  Widget _editFieldSection({
    String? headingTitle, String? headingHint,
    Widget? fieldControl,
  }) => Padding(padding: EdgeInsets.only(top: 12), child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      if (headingTitle?.isNotEmpty == true)
        _editHeadingWidget(headingTitle ?? '', hint: headingHint),
      if (fieldControl != null)
        fieldControl
    ],)
  );

  Widget _editHeadingWidget(String? title, { String? hint }) =>
    Padding(padding: EdgeInsets.only(bottom: 2), child:
      RichText(textAlign: TextAlign.left, text:
        TextSpan(style: Styles().textStyles.getTextStyle('widget.title.tiny.fat.spaced'), children: [
          TextSpan(text: title?.toUpperCase()),
          if (hint?.isNotEmpty == true)
            TextSpan(text: ' ' + (hint?.toUpperCase() ?? ''), style: Styles().textStyles.getTextStyle('widget.title.tiny'))
        ]),
      ),
    );

  Widget _editTextWidget(_ProfileField field, {
    TextInputType textInputType = TextInputType.text,
    bool autocorrect = true,
    bool enabled = true,
  }) =>
    Container(decoration: _editCtrlDecoration, child:
      Row(children: [
        Expanded(child:
          Padding(padding: EdgeInsets.only(left: 12, right: enabled ? 12 : 0, top: 0, bottom: 0), child:
            TextField(
              controller: _fieldTextControllers[field],
              focusNode: _fieldFocusNodes[field],
              decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
              style: Styles().textStyles.getTextStyle('widget.input_field.dark.text.regular.thin'),
              maxLines: 1,
              keyboardType: textInputType,
              autocorrect: autocorrect,
              readOnly: (enabled != true),
            )
          )
        ),
        if (enabled)
          InkWell(onTap: () => _onToggleTextEditing(field), child:
            Padding(padding: EdgeInsets.only(left: 2, right: 14,  top: 14, bottom: 14), child:
              Styles().images.getImage('edit', color: Styles().colors.mediumGray2, size: _editButtonIconSize)
            )
          ),
      ])
    );

  Widget _editVisibilityButton(_ProfileField field, { bool public = false}) =>
    _editIconButton(
      icon: _editVisibilityIcon(_fieldVisibilities?[field], public: public),
      onTap: public ? null : () => _onToggleFieldVisibility(field),
    );

  Widget _editIconButton({ Widget? icon, bool progress = false, void Function()? onTap}) =>
    InkWell(onTap: onTap, child:
      Container(decoration: _editCtrlDecoration, child:
        Padding(padding: EdgeInsets.all(15), child:
          SizedBox(width: _editButtonIconSize, height: _editButtonIconSize, child:
            progress ? _progressWidget : Center(child: icon,)
          ),
        )
      )
    );

  Widget get _progressWidget =>
    CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary,);

  Widget? _editVisibilityIcon(Auth2FieldVisibility? visibility, { bool public = false} ) {
    if (public) {
      return _lockIcon;
    } else if (_permittedVisibility.contains(visibility)) {
      return _publicIcon;
    } else {
      return _privateIcon;
    }
  }

  Widget? get _editIcon => Styles().images.getImage('edit', color: Styles().colors.fillColorPrimary, size: _editButtonIconSize);
  Widget? get _trashIcon => Styles().images.getImage('trash', color: Styles().colors.fillColorPrimary, size: _editButtonIconSize);
  Widget? get _publicIcon => Styles().images.getImage('eye', color: Styles().colors.fillColorSecondary, size: _editButtonIconSize);
  Widget? get _privateIcon => Styles().images.getImage('eye-slash', color: Styles().colors.mediumGray2, size: _editButtonIconSize);
  Widget? get _lockIcon => Styles().images.getImage('lock', color: Styles().colors.fillColorSecondary, size: _editButtonIconSize);
  Widget? get _playIcon => Styles().images.getImage('play', color: Styles().colors.fillColorPrimary, size: _editButtonIconSize);
  Widget? get _pauseIcon => Styles().images.getImage('pause', color: Styles().colors.fillColorPrimary, size: _editButtonIconSize);
  //Widget? get _stopIcon => Styles().images.getImage('stop', color: Styles().colors.fillColorPrimary, size: _editButtonIconSize);

  Decoration get _editCtrlDecoration => BoxDecoration(
    color: Styles().colors.white,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );


  String? get _editPhotoText => _fieldTextControllers[_ProfileField.photoUrl]?.text;
  set _editPhotoText(String? value) => (_fieldTextControllers[_ProfileField.photoUrl] ??= TextEditingController()).text = value ?? '';

  String? get _editPronunciationText => _fieldTextControllers[_ProfileField.pronunciationUrl]?.text;
  set _editPronunciationText(String? value) => (_fieldTextControllers[_ProfileField.pronunciationUrl] ??= TextEditingController()).text = value ?? '';

  void _onToggleTextEditing(_ProfileField field) {
    FocusNode? focusNode = _fieldFocusNodes[field];
    if (focusNode?.hasFocus == true) {
      focusNode?.unfocus();
    } else {
      focusNode?.requestFocus();
    }
  }

  void _onToggleFieldVisibility(_ProfileField field) {
    Analytics().logSelect(target: 'Toggle $field Visibility');
    setState(() {
      Auth2FieldVisibility? visibility = _fieldVisibilities?[field];
      _fieldVisibilities?[field] = (_permittedVisibility.contains(visibility)) ?
        Auth2FieldVisibility.private : _positiveVisibility;
    });
  }

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
    progress: _saving,
    onTap: _onSaveEdit,
  );

  void _onSaveEdit() {
    Analytics().logSelect(target: 'Save Edit');
    _saveProfileAndPrivacy().then((bool result) {
      if (mounted) {
        if (result) {
          setState(() {
            _editing = false;
          });
        }
        else {
          AppAlert.showTextMessage(context, Localization().getStringEx('panel.profile.directory.my_info.save.failed.text', 'Failed to update profile and privacy settings.'));
        }
      }
    });
  }

  Future<void> _loadProfileAndPrivacy() async {
    setState(() {
      _loading = true;
    });
    List<dynamic> results = await Future.wait([
      Auth2().loadUserProfile(),
      Auth2().loadUserPrivacy(),
    ]);
    if (mounted) {
      Auth2UserProfile? profile = JsonUtils.cast<Auth2UserProfile>(ListUtils.entry(results, 0));
      Auth2UserPrivacy? privacy = JsonUtils.cast<Auth2UserPrivacy>(ListUtils.entry(results, 1));
      setState(() {
        //TMP: Added some sample data
        _profile = Auth2UserProfile.fromOther(profile ?? Auth2().profile,);
        _privacy = privacy;

        //TMP: Added some sample data
        _profileVisibility = Auth2UserProfileFieldsVisibility.fromOther(privacy?.fieldsVisibility?.profile,
          firstName: Auth2FieldVisibility.public,
          middleName: Auth2FieldVisibility.public,
          lastName: Auth2FieldVisibility.public,
          email: Auth2FieldVisibility.public,
        );

        _previewProfile = Auth2UserProfile.fromFieldsVisibility(_profile, _profileVisibility, permitted: _permittedVisibility);

        _loading = false;
      });
    }
  }

  Future<bool> _saveProfileAndPrivacy() async {
    Auth2UserProfile profile = _Auth2UserProfileUtils.buildModified(_profile, _fieldTextControllers);
    Auth2UserProfileFieldsVisibility profileVisibility = _Auth2UserProfileFieldsVisibilityUtils.buildModified(_profileVisibility, _fieldVisibilities);

    List<Future> futures = [];

    int? profileIndex = (_profile != profile) ? futures.length : null;
    if (profileIndex != null) {
      futures.add(Auth2().saveUserProfile(profile));
    }

    int? privacyIndex = (_profileVisibility != profileVisibility) ? futures.length : null;
    if (privacyIndex != null) {
      futures.add(Auth2().saveUserPrivacy(Auth2UserPrivacy.fromOther(_privacy, fieldsVisibility: Auth2AccountFieldsVisibility.fromOther(_privacy?.fieldsVisibility, profile: profileVisibility))));
    }

    if (0 < futures.length) {
      setState(() {
        _saving = true;
      });

      List<dynamic> results = await Future.wait(futures);

      bool? profileResult = ((profileIndex != null) && (profileIndex < results.length)) ? results[profileIndex] : null;
      bool? privacyResult = ((privacyIndex != null) && (privacyIndex < results.length)) ? results[privacyIndex] : null;

      setStateIfMounted((){
        if (profileResult == true) {
          _profile = profile;
        }

        if (privacyResult == true) {
          _profileVisibility = Auth2UserProfileFieldsVisibility.fromOther(profileVisibility,
            firstName: Auth2FieldVisibility.public,
            middleName: Auth2FieldVisibility.public,
            lastName: Auth2FieldVisibility.public,
            email: Auth2FieldVisibility.public,
          );
        }

        if ((profileResult == true) || (privacyResult == true)) {
          _previewProfile = Auth2UserProfile.fromFieldsVisibility(_profile, _profileVisibility, permitted: _permittedVisibility);
        }

        _saving = false;
      });

      return (profileResult ?? true) && (privacyResult ?? true);
    }
    else {
      return true;
    }
  }

  static const Auth2FieldVisibility _directoryPositiveVisibility = Auth2FieldVisibility.public;
  static const Auth2FieldVisibility _connectionsPositiveVisibility = Auth2FieldVisibility.connections;

  Auth2FieldVisibility get _positiveVisibility {
    switch(widget.contentType) {
      case MyProfileInfo.myDirectoryInfo: return _directoryPositiveVisibility;
      case MyProfileInfo.myConnectionsInfo: return _connectionsPositiveVisibility;
    }
  }

  static const Set<Auth2FieldVisibility> _directoryPermittedVisibility = const <Auth2FieldVisibility>{ _directoryPositiveVisibility };
  static const Set<Auth2FieldVisibility> _connectionsPermittedVisibility = const <Auth2FieldVisibility>{ _directoryPositiveVisibility, _connectionsPositiveVisibility };

  Set<Auth2FieldVisibility> get _permittedVisibility {
    switch(widget.contentType) {
      case MyProfileInfo.myDirectoryInfo: return _directoryPermittedVisibility;
      case MyProfileInfo.myConnectionsInfo: return _connectionsPermittedVisibility;
    }
  }

}

extension _Auth2UserProfileFieldsVisibilityUtils on Auth2UserProfileFieldsVisibility {
  Map<_ProfileField, Auth2FieldVisibility?> get fieldsVisibility => <_ProfileField, Auth2FieldVisibility?>{
    _ProfileField.firstName: firstName,
    _ProfileField.middleName: middleName,
    _ProfileField.lastName: lastName,
    _ProfileField.pronouns: pronouns,

    _ProfileField.birthYear: birthYear,
    _ProfileField.photoUrl: photoUrl,
    _ProfileField.pronunciationUrl: pronunciationUrl,

    _ProfileField.email: email,
    _ProfileField.email2: email2,
    _ProfileField.phone: phone,
    _ProfileField.website: website,

    _ProfileField.college: college,
    _ProfileField.department: department,
    _ProfileField.major: major,
    _ProfileField.title: title,

    _ProfileField.address: address,
    _ProfileField.state: state,
    _ProfileField.zip: zip,
    _ProfileField.country: country,
  };

  static Auth2UserProfileFieldsVisibility buildModified(Auth2UserProfileFieldsVisibility? other, Map<_ProfileField, Auth2FieldVisibility?>? fields) =>
    Auth2UserProfileFieldsVisibility.fromOther(other,
      firstName : fields?[_ProfileField.firstName],
      middleName : fields?[_ProfileField.middleName],
      lastName : fields?[_ProfileField.lastName],
      pronouns : fields?[_ProfileField.pronouns],

      birthYear : fields?[_ProfileField.birthYear],
      photoUrl : fields?[_ProfileField.photoUrl],
      pronunciationUrl : fields?[_ProfileField.pronunciationUrl],

      email : fields?[_ProfileField.email],
      phone : fields?[_ProfileField.phone],
      website : fields?[_ProfileField.website],

      address : fields?[_ProfileField.address],
      state : fields?[_ProfileField.state],
      zip : fields?[_ProfileField.zip],
      country : fields?[_ProfileField.country],

      data: MapUtils.ensureEmpty({

        if (fields?[_ProfileField.college] != null)
          Auth2UserProfile.collegeDataKey: fields?[_ProfileField.college],

        if (fields?[_ProfileField.department] != null)
          Auth2UserProfile.departmentDataKey: fields?[_ProfileField.department],

        if (fields?[_ProfileField.major] != null)
          Auth2UserProfile.majorDataKey: fields?[_ProfileField.major],

        if (fields?[_ProfileField.title] != null)
          Auth2UserProfile.titleDataKey: fields?[_ProfileField.title],

        if (fields?[_ProfileField.email2] != null)
          Auth2UserProfile.email2DataKey: fields?[_ProfileField.email2],
      }),
    );
}

extension _Auth2UserProfileUtils on Auth2UserProfile {

  String? fieldValue(_ProfileField field) {
    switch(field) {
      case _ProfileField.firstName: return firstName;
      case _ProfileField.middleName: return middleName;
      case _ProfileField.lastName: return lastName;
      case _ProfileField.pronouns: return pronouns;

      case _ProfileField.birthYear: return birthYear?.toString();
      case _ProfileField.photoUrl: return photoUrl;
      case _ProfileField.pronunciationUrl: return pronunciationUrl;

      case _ProfileField.email: return email;
      case _ProfileField.email2: return email2;
      case _ProfileField.phone: return phone;
      case _ProfileField.website: return website;

      case _ProfileField.college: return college;
      case _ProfileField.department: return department;
      case _ProfileField.major: return major;
      case _ProfileField.title: return title;

      case _ProfileField.address: return address;
      case _ProfileField.state: return state;
      case _ProfileField.zip: return zip;
      case _ProfileField.country: return country;
    }
  }

  static Auth2UserProfile buildModified(Auth2UserProfile? other, Map<_ProfileField, TextEditingController?> fields) =>
    Auth2UserProfile.fromOther(other,
      firstName: StringUtils.ensureEmpty(fields[_ProfileField.firstName]?.text),
      middleName: StringUtils.ensureEmpty(fields[_ProfileField.middleName]?.text),
      lastName: StringUtils.ensureEmpty(fields[_ProfileField.lastName]?.text),
      pronouns: StringUtils.ensureEmpty(fields[_ProfileField.pronouns]?.text),

      birthYear: JsonUtils.intValue(StringUtils.ensureEmpty(fields[_ProfileField.birthYear]?.text)),
      photoUrl: StringUtils.ensureEmpty(fields[_ProfileField.photoUrl]?.text),
      pronunciationUrl: StringUtils.ensureEmpty(fields[_ProfileField.pronunciationUrl]?.text),

      email: StringUtils.ensureEmpty(fields[_ProfileField.email]?.text),
      phone: StringUtils.ensureEmpty(fields[_ProfileField.phone]?.text),
      website: StringUtils.ensureEmpty(fields[_ProfileField.website]?.text),

      address: StringUtils.ensureEmpty(fields[_ProfileField.address]?.text),
      state: StringUtils.ensureEmpty(fields[_ProfileField.state]?.text),
      zip: StringUtils.ensureEmpty(fields[_ProfileField.zip]?.text),
      country: StringUtils.ensureEmpty(fields[_ProfileField.country]?.text),

      data: {
        if (fields[_ProfileField.college]?.text.isNotEmpty == true)
          Auth2UserProfile.collegeDataKey: fields[_ProfileField.college]?.text,

        if (fields[_ProfileField.department]?.text.isNotEmpty == true)
          Auth2UserProfile.departmentDataKey: fields[_ProfileField.department]?.text,

        if (fields[_ProfileField.major]?.text.isNotEmpty == true)
          Auth2UserProfile.majorDataKey: fields[_ProfileField.major]?.text,

        if (fields[_ProfileField.title]?.text.isNotEmpty == true)
          Auth2UserProfile.titleDataKey: fields[_ProfileField.title]?.text,

        if (fields[_ProfileField.email2]?.text.isNotEmpty == true)
          Auth2UserProfile.email2DataKey: fields[_ProfileField.email2]?.text,
      }
    );
}

extension _DateTimeUtils on DateTime {
  static String get imageToken => DateTime.now().millisecondsSinceEpoch.toString();
}

