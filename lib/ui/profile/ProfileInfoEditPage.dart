
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Auth2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/groups/ImageEditPanel.dart';
import 'package:illinois/ui/profile/ProfileInfoPage.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/ui/profile/ProfileVoiceRecordigWidgets.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/AudioUtils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileInfoEditPage extends StatefulWidget {
  final ProfileInfo contentType;
  final bool onboarding;

  final Auth2Type? authType;
  final Auth2UserProfile? profile;
  final Auth2UserPrivacy? privacy;

  final Uint8List? pronunciationAudioData;
  final Uint8List? photoImageData;
  final String? photoImageToken;

  final void Function({Auth2UserProfile? profile, Auth2UserPrivacy? privacy, Uint8List? pronunciationAudioData, Uint8List? photoImageData, String? photoImageToken})? onFinishEdit;

  ProfileInfoEditPage({super.key,
    required this.contentType, this.onboarding = false,
    this.authType, this.profile, this.privacy,
    this.pronunciationAudioData, this.photoImageData, this.photoImageToken,
    this.onFinishEdit
  });

  @override
  State<StatefulWidget> createState() => ProfileInfoEditPageState();
}

class ProfileInfoEditPageState extends ProfileDirectoryMyInfoBasePageState<ProfileInfoEditPage> with NotificationsListener, WidgetsBindingObserver {

  late Auth2UserProfileFieldsVisibility _profileVisibility;
  late Uint8List? _pronunciationAudioData;
  late Uint8List? _photoImageData;
  late String? _photoImageToken;

  final Map<_ProfileField, Auth2FieldVisibility?> _fieldVisibilities = {};
  final Map<_ProfileField, TextEditingController> _fieldTextControllers = {};
  final Map<_ProfileField, bool> _fieldTextNotEmpty = {};
  final Map<_ProfileField, FocusNode> _fieldFocusNodes = {};

  bool _saving = false;
  bool _clearingUserPhoto = false;
  bool _clearingUserPronunciation = false;
  bool _initializingAudioPlayer = false;

  UniqueKey _photoKey = UniqueKey();
  AudioPlayer? _audioPlayer;

  double _screenInsetsBottom = 0;
  double? _visibilityDropdownItemsWidth;
  Timer? _onScreenInsetsBottomChangedTimer;

  final Map<Auth2LoginType, Set<_ProfileField>> fieldAvailabilities = <Auth2LoginType, Set<_ProfileField>>{
    Auth2LoginType.oidc: _oidcFieldAvailabilities,
    Auth2LoginType.oidcIllinois: _oidcFieldAvailabilities,
    Auth2LoginType.email: _emailFieldAvailabilities,
    Auth2LoginType.phone: _phoneFieldAvailabilities,
    Auth2LoginType.phoneTwilio: _phoneFieldAvailabilities,
    Auth2LoginType.username: _defaultFieldAvailabilities,
  };
  static Set<_ProfileField> _oidcFieldAvailabilities = _ProfileField.values.toSet();
  static Set<_ProfileField> _defaultFieldAvailabilities = <_ProfileField>{_ProfileField.firstName, _ProfileField.middleName, _ProfileField.lastName, _ProfileField.photoUrl};
  static Set<_ProfileField> _emailFieldAvailabilities = _defaultFieldAvailabilities.union(<_ProfileField>{ _ProfileField.email});
  static Set<_ProfileField> _phoneFieldAvailabilities = _defaultFieldAvailabilities.union(<_ProfileField>{ _ProfileField.phone});

  static const double _buttonIconSize = 16;
  static const double _dropdownItemInnerIconPaddingX = 6;
  static const double _dropdownButtonInnerIconPaddingX = 12;
  static const double _dropdownButtonChevronIconSize = 10;
  static const EdgeInsetsGeometry _dropdownMenuItemPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  static const EdgeInsetsGeometry _dropdownButtonPadding = const EdgeInsets.only(left: 16, right: 8, top: 15, bottom: 15);

  bool _isFieldAvailable(_ProfileField field) => (fieldAvailabilities[widget.authType?.loginType]?.contains(field) == true);
  bool get _showProfileCommands => (widget.onboarding == false);
  bool get _showPrivacyControls => (widget.onboarding == false) && FlexUI().isPrivacyAvailable;
  bool get _showNameControls => (widget.authType?.loginType?.shouldHaveName != true) || !_hasProfileName;
  bool get _canEditName => (widget.authType?.loginType?.shouldHaveName != true) || !_hasProfileName;
  bool get _hasProfileName => (widget.profile?.isNameNotEmpty == true);

  @override
  void initState() {
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
    ]);

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    });

    _pronunciationAudioData = widget.pronunciationAudioData;
    _photoImageData = widget.photoImageData;
    _photoImageToken = widget.photoImageToken;

    for (_ProfileField field in _ProfileField.values) {
      _fieldTextControllers[field] = TextEditingController(text: widget.profile?.fieldValue(field) ?? '');
      _fieldTextNotEmpty[field] = (widget.profile?.fieldValue(field)?.isNotEmpty == true);
      _fieldFocusNodes[field] = FocusNode();
    }

    _profileVisibility = _showPrivacyControls ? Auth2UserProfileFieldsVisibility.fromOther(widget.privacy?.fieldsVisibility?.profile,
      firstName: Auth2FieldVisibility.public,
      middleName: Auth2FieldVisibility.public,
      lastName: Auth2FieldVisibility.public,
      email: ((widget.authType?.loginType?.canEditPrivacy == true) && (widget.authType?.loginType?.shouldHaveEmail == true)) ? Auth2FieldVisibility.public : null,
      phone: ((widget.authType?.loginType?.canEditPrivacy == true) && (widget.authType?.loginType?.shouldHavePhone == true)) ? Auth2FieldVisibility.public : null,
    ) : Auth2UserProfileFieldsVisibility.fromOther(widget.privacy?.fieldsVisibility?.profile);

    _fieldVisibilities.addAll(_profileVisibility.fieldsVisibility);

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);

    for (_ProfileField field in _ProfileField.values) {
      _fieldTextControllers[field]?.dispose();
      _fieldFocusNodes[field]?.dispose();
    }

    _audioPlayer?.dispose();

    super.dispose();
  }

  @override
  void onNotification(String name, param) {
    if (name == FlexUI.notifyChanged) {
      setStateIfMounted((){});
    }
  }

  @override
  void didChangeMetrics() {
    double screenInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    if (screenInsetsBottom != _screenInsetsBottom) {
      _screenInsetsBottom = screenInsetsBottom;
      _onScreenInsetsBottomChangedTimer?.cancel();
      _onScreenInsetsBottomChangedTimer = Timer(Duration(milliseconds: 100), (){
        _onScreenInsetsBottomChangedTimer = null;
        setStateIfMounted(() {});
      });
    }

    double visibilityDropdownItemsWidth = _evaluateVisibilityDropdownItemsWidth();
    if (_visibilityDropdownItemsWidth != visibilityDropdownItemsWidth) {
      setStateIfMounted(() {
        _visibilityDropdownItemsWidth = visibilityDropdownItemsWidth;
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      Padding(padding: EdgeInsets.zero, child:
        Column(children: [
          _photoWidget,
          Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
            _staticNameWidget,
          ),

          if (_showNameControls)
            ...[
              _firstNameSection,
              _middleNameSection,
              _lastNameSection,
            ],
          _pronunciationSection,
          _pronounsSection,
          _titleSection,
          _collegeSection,
          _departmentSection,
          _majorSection,
          _emailSection,
          _email2Section,
          _phoneSection,
          _websiteSection,

          if (_showProfileCommands)
            Padding(padding: EdgeInsets.only(top: 24, bottom: 16), child:
              _commandBar,
            ),
          if (_screenInsetsBottom > 0)
            Padding(padding: EdgeInsets.only(top: _screenInsetsBottom)),
        ],),
      );

    // Edit: Photo

    String? get _photoImageUrl => StringUtils.isNotEmpty(_photoText) ?
      Content().getUserPhotoUrl(type: UserProfileImageType.medium, params: DirectoryProfilePhotoUtils.tokenUrlParam(_photoImageToken)) : null;

    double get _photoImageSize => MediaQuery.of(context).size.width / 3;

    Map<String, String>? get _photoAuthHeaders => DirectoryProfilePhotoUtils.authHeaders;

    Widget get _photoWidget => _isFieldAvailable(_ProfileField.photoUrl) ? Stack(children: [
      Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 20), child:
        DirectoryProfilePhoto(
          key: _photoKey,
          photoUrl: _photoImageUrl,
          photoUrlHeaders: _photoAuthHeaders,
          photoData: _photoImageData,
          imageSize: _photoImageSize,
        ),
      ),
      Positioned.fill(child:
        Align(alignment: _showPrivacyControls ? Alignment.bottomLeft : Alignment.bottomRight, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 8), child:
            _editPhotoButton
          )
        )
      ),
      if (_showPrivacyControls)
        Positioned.fill(child:
          Align(alignment: Alignment.bottomRight, child:
            _editPhotoVisibilityButton
          )
        )
    ],) : Container();

    Widget get _editPhotoButton =>
      _photoIconButton(_editIcon,
        onTap: _onEditPhotoButton,
        progress: _clearingUserPhoto,
      );

    void _onEditPhotoButton() {
      Analytics().logSelect(target: 'Edit Photo');
      if (StringUtils.isNotEmpty(_photoText)) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          isScrollControlled: true,
          isDismissible: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (context) => Container(padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16), child:
            Column(mainAxisSize: MainAxisSize.min, children: [
              RibbonButton(label: Localization().getStringEx('panel.profile.info.command.button.photo.edit.text', 'Edit Photo'), rightIconKey: 'edit', onTap: () { Navigator.of(context).pop(); _onEditPhoto(); }),
              RibbonButton(label: Localization().getStringEx('panel.profile.info.command.button.photo.clear.text', 'Clear Photo'), rightIconKey: 'clear', onTap: () { Navigator.of(context).pop(); _onClearPhoto(); }),
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
              _photoKey = UniqueKey();
              _photoText = Content().getUserPhotoUrl(accountId: Auth2().accountId, type: UserProfileImageType.medium) ?? '';
              _photoImageToken = DirectoryProfilePhotoUtils.newToken;
              _photoImageData = imageUploadResult.imageData;
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
      AppAlert.showConfirmationDialog(context, message: _clearPhotoPrompt(),).then((bool result) {
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
              _photoKey = UniqueKey();
              _photoText = '';
              _photoImageToken = DirectoryProfilePhotoUtils.newToken;
              _photoImageData = null;
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

    Widget get _editPhotoVisibilityButton =>
      _photoVisibilityDropdown; // _photoVisibilityToggleButton

    Widget get _photoVisibilityDropdown =>
      _visibilityDropdown(_ProfileField.photoUrl,
        buttonPadding: EdgeInsets.only(left: 8, right: 6, top: 10, bottom: 10),
        buttonInnerIconPadding: 8
      );

    // ignore: unused_element
    Widget get _photoVisibilityToggleButton =>
    _photoIconButton(_visibilityIcon(_ProfileField.photoUrl),
      onTap: (_fieldTextNotEmpty[_ProfileField.photoUrl] == true) ? () => _onToggleFieldVisibility(_ProfileField.photoUrl) : null,
    );

    Widget _photoIconButton(Widget? icon, { void Function()? onTap, bool progress = false}) =>
      InkWell(onTap: onTap, child:
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Styles().colors.white,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 1)
          ),
          child: Padding(padding: EdgeInsets.all(12),
            child: progress ? SizedBox(
              width: _buttonIconSize,
              height: _buttonIconSize,
              child: DirectoryProgressWidget(),
            ) : icon
          ),
        )
      );

    Widget get _staticNameWidget =>
      Text(_staicNameText ?? '', style: nameTextStyle, textAlign: TextAlign.center,);

    String? get _staicNameText => StringUtils.fullName([
      _fieldTextControllers[_ProfileField.firstName]?.text,
      _fieldTextControllers[_ProfileField.middleName]?.text,
      _fieldTextControllers[_ProfileField.lastName]?.text,
    ]);

  // Edit: Pronunciation

  Widget get _pronunciationSection => _isFieldAvailable(_ProfileField.pronunciationUrl) ? _fieldSection(
    headingTitle: Localization().getStringEx('panel.profile.info.title.pronunciation.text', 'Name Pronunciation'),
    fieldControl: StringUtils.isNotEmpty(_pronunciationText) ? _pronunciationEditBar : _pronunciationCreateControl,
  ) : Container();

  Widget get _pronunciationCreateControl => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Styles().images.getImage('plus-circle', size: 24) ?? Container(),
    Expanded(child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 6), child:
        InkWell(onTap: _onCreatePronunciation, child:
          Text(_pronunciationCreateText(), style: Styles().textStyles.getTextStyle('widget.detail.small.underline'),)
        ),
      ),
    ),
    if (_showPrivacyControls)
      Padding(padding: EdgeInsets.only(left: 6), child:
        _visibilityButton(_ProfileField.pronunciationUrl),
    ),
  ],);

  String _pronunciationCreateText({String? language}) =>
    Localization().getStringEx('panel.profile.info.command.link.pronunciation.text', 'Add name pronunciation and how you prefer to be addressed (Ex: "Please call me Dr. Last Name, First Name or Nickname")', language: language);

  Widget get _pronunciationEditBar => Row(children: [
    Wrap( spacing: 6, runSpacing: 6, children: [
      _pronunciationPlayButton,
      _pronunciationEditButton,
      _pronunciationDeleteButton,
      if (_showPrivacyControls)
        _visibilityButton(_ProfileField.pronunciationUrl),
    ],)
  ],);

  Widget get _pronunciationPlayButton => _iconButton(
    icon: _pronunciationPlayIcon,
    progress: _initializingAudioPlayer,
    onTap: _onPlayPronunciation,
  );

  Widget? get _pronunciationPlayIcon => (_audioPlayer?.playing == true) ? _pauseIcon : _playIcon;

  Widget get _pronunciationEditButton => _iconButton(
    icon: _editIcon,
    onTap: _onEditPronunciation,
  );

  Widget get _pronunciationDeleteButton => _iconButton(
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
          _pronunciationText = Content().getUserNamePronunciationUrl(accountId: Auth2().accountId);
          _pronunciationAudioData = result?.audioData;
        });
      }
    });
  }

  void _onDeletePronunciation() {
    Analytics().logSelect(target: 'Delete Pronuncaion');

    AppAlert.showConfirmationDialog(context, message: Localization().getStringEx("panel.profile_info.pronunciation.delete.confirmation.msg", "Are you sure you want to remove this pronunciation audio?")).then((bool? result) {
      if (mounted && (result == true)) {
        setState(() {
          _clearingUserPronunciation = true;
        });
        Content().deleteUserNamePronunciation().then((AudioResult? result){
          if (mounted) {
            if (result?.resultType == AudioResultType.succeeded) {
              setState(() {
                _clearingUserPronunciation = false;
                _pronunciationText = null;
                _pronunciationAudioData = null;
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

  void _onPlayPronunciation() async {
    if (_audioPlayer == null) {
      if (_initializingAudioPlayer == false) {
        setState(() {
          _initializingAudioPlayer = true;
        });

        Uint8List? audioData = _pronunciationAudioData;
        if (audioData == null) {
          AudioResult? result = await Content().loadUserNamePronunciation();
          audioData = (result?.resultType == AudioResultType.succeeded) ? result?.audioData : null;
        }

        if (mounted) {
          if (audioData != null) {
            setState(() {
              _initializingAudioPlayer = false;
            });

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
      else {
        // ignore taps while initializing
      }
    }
    else if (_audioPlayer?.playing == true) {
      setState(() {
        _audioPlayer?.pause();
      });
    }
    else {
      setState(() {
        _audioPlayer?.play();
      });
    }
  }

  void _handlePronunciationPlaybackError() {
    setState(() {
      _initializingAudioPlayer = false;
      _audioPlayer?.dispose();
      _audioPlayer = null;
    });
    AppAlert.showTextMessage(context, Localization().getStringEx('panel.profile.info.playback.failed.text', 'Failed to play audio stream.'));
  }

  // Edit: Other Sections

  Widget get _firstNameSection => _textFieldSection(_ProfileField.firstName,
    headingTitle: Localization().getStringEx('panel.profile.info.title.first_name.text', 'First Name'),
    enabled: _canEditName, locked: true, available: _showPrivacyControls,
  );

  Widget get _middleNameSection => _textFieldSection(_ProfileField.middleName,
    headingTitle: Localization().getStringEx('panel.profile.info.title.middle_name.text', 'Middle Name'),
    enabled: _canEditName, locked: true, available: _showPrivacyControls,
  );

  Widget get _lastNameSection => _textFieldSection(_ProfileField.lastName,
    headingTitle: Localization().getStringEx('panel.profile.info.title.last_name.text', 'Last Name'),
    enabled: _canEditName, locked: true, available: _showPrivacyControls,
  );

  Widget get _pronounsSection => _textFieldSection(_ProfileField.pronouns,
    headingTitle: Localization().getStringEx('panel.profile.info.title.pronouns.text', 'Pronouns'),
    available: _showPrivacyControls,
  );

  Widget get _titleSection => _textFieldSection(_ProfileField.title,
    headingTitle: Localization().getStringEx('panel.profile.info.title.title.text', 'Title'),
    headingHint: Localization().getStringEx('panel.profile.info.title.title.hint', '(Ex: Professional/Extracurricular Role)'),
    available: _showPrivacyControls,
  );

  Widget get _collegeSection => _textFieldSection(_ProfileField.college,
    headingTitle: Localization().getStringEx('panel.profile.info.title.college.text', 'College'),
    enabled: false, available: _showPrivacyControls,
  );

  Widget get _departmentSection => _textFieldSection(_ProfileField.department,
    headingTitle: Localization().getStringEx('panel.profile.info.title.department.text', 'Department'),
    enabled: false, available: _showPrivacyControls,
  );

  Widget get _majorSection => _textFieldSection(_ProfileField.major,
    headingTitle: Localization().getStringEx('panel.profile.info.title.major.text', 'Major'),
    enabled: false, available: _showPrivacyControls,
  );

  Widget get _emailSection => _textFieldSection(_ProfileField.email,
    headingTitle: Localization().getStringEx('panel.profile.info.title.email.text', 'Email Address'),
    textInputType: TextInputType.emailAddress,
    enabled: (widget.authType?.loginType?.shouldHaveEmail != true) || StringUtils.isEmpty(widget.profile?.email),
    locked: (widget.authType?.loginType?.shouldHaveEmail == true),
    available: _showPrivacyControls,
  );

  Widget get _email2Section => _textFieldSection(_ProfileField.email2,
    headingTitle: Localization().getStringEx('panel.profile.info.title.email2.text', 'Alternate Email Address'),
    textInputType: TextInputType.emailAddress,
    available: _showPrivacyControls,
  );

  Widget get _phoneSection => _textFieldSection(_ProfileField.phone,
    headingTitle: Localization().getStringEx('panel.profile.info.title.phone.text', 'Phone Number'),
    textInputType: TextInputType.phone,
    enabled: (widget.authType?.loginType?.shouldHavePhone != true) || StringUtils.isEmpty(widget.profile?.phone),
    locked: (widget.authType?.loginType?.shouldHavePhone == true),
    available: _showPrivacyControls,
  );

  Widget get _websiteSection => _textFieldSection(_ProfileField.website,
    headingTitle: Localization().getStringEx('panel.profile.info.title.website.text', 'Website URL'),
    headingHint: Localization().getStringEx('panel.profile.info.title.website.hinr', '(Ex: Linkedin)'),
    textInputType: TextInputType.url,
    available: _showPrivacyControls,
  );

  Widget _textFieldSection(_ProfileField field, {
    String? headingTitle, String? headingHint,
    TextInputType textInputType = TextInputType.text,
    bool autocorrect = true, bool enabled = true,
    bool available = true, bool locked = false,
  }) => (((_fieldTextControllers[field]?.text.isNotEmpty == true) || enabled) && _isFieldAvailable(field)) ?
    _fieldSection(
      headingTitle: headingTitle,
      headingHint: headingHint,
      fieldControl: _textFieldControl(field,
          textInputType: textInputType,
          autocorrect: autocorrect,
          enabled: enabled,
          available: available,
          locked: locked,
      )
    ) : Container();

  Widget _textFieldControl(_ProfileField field, {
    TextInputType textInputType = TextInputType.text,
    bool autocorrect = true, bool enabled = true,
    bool locked = false, bool available = true,
    }) =>
      Row(children: [
        Expanded(child:
          _textFieldWidget(field, textInputType: textInputType, autocorrect: autocorrect, enabled: enabled, locked: locked && !enabled && !available)
        ),
        if (_showPrivacyControls)
          Padding(padding: EdgeInsets.only(left: 6), child:
            _visibilityButton(field, locked: locked),
          ),
      ],);

  Widget _fieldSection({
    String? headingTitle, String? headingHint,
    Widget? fieldControl,
  }) =>
    Padding(padding: EdgeInsets.only(top: 12), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        if (headingTitle?.isNotEmpty == true)
          _sectionHeadingWidget(headingTitle ?? '', hint: headingHint),
        if (fieldControl != null)
          fieldControl
      ],)
    );

  Widget _sectionHeadingWidget(String? title, { String? hint }) =>
    Padding(padding: EdgeInsets.only(bottom: 2), child:
      RichText(textAlign: TextAlign.left, text:
        TextSpan(style: Styles().textStyles.getTextStyle('widget.title.tiny.fat.spaced'), children: [
          TextSpan(text: title?.toUpperCase()),
          if (hint?.isNotEmpty == true)
            TextSpan(text: ' ' + (hint?.toUpperCase() ?? ''), style: Styles().textStyles.getTextStyle('widget.title.tiny'))
        ]),
      ),
    );

  Widget _textFieldWidget(_ProfileField field, {
    TextInputType textInputType = TextInputType.text,
    bool autocorrect = true,
    bool enabled = true,
    bool locked = false,
  }) =>
    Container(decoration: _controlDecoration, child:
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
              readOnly: ((enabled != true) || (locked == true)),
              onChanged: (String text) => _onTextChanged(field, text),
            )
          )
        ),
        if (locked)
          Padding(padding: EdgeInsets.only(left: 2, right: 14,  top: 14, bottom: 14), child:
            Styles().images.getImage('lock', color: Styles().colors.mediumGray2, size: _buttonIconSize)
          ),
        if (enabled && !locked)
          InkWell(onTap: () => _onTextEdit(field), child:
            Padding(padding: EdgeInsets.only(left: 2, right: 14,  top: 14, bottom: 14), child:
              Styles().images.getImage('edit', color: Styles().colors.mediumGray2, size: _buttonIconSize)
            )
          ),
      ])
    );

  Widget _visibilityButton(_ProfileField field, { bool locked = false }) =>
    _visibilityDropdown(field, locked: locked); // _visibilityToggleButton(field, locked: locked);

  // ignore: unused_element
  Widget _visibilityToggleButton(_ProfileField field, { bool locked = false }) =>
    _iconButton(
      icon: _visibilityIcon(field, locked: locked),
      onTap: ((_fieldTextNotEmpty[field] == true) && !locked) ? () => _onToggleFieldVisibility(field) : null,
    );

  Widget _iconButton({ Widget? icon, void Function()? onTap, bool progress = false}) =>
    InkWell(onTap: onTap, child:
      Container(decoration: _controlDecoration, child:
        Padding(padding: EdgeInsets.all(15), child:
          SizedBox(width: _buttonIconSize, height: _buttonIconSize, child:
            progress ? DirectoryProgressWidget() : Center(child: icon,)
          ),
        )
      )
    );

  Widget? _visibilityIcon(_ProfileField field, { bool locked = false} ) {
    if (locked) {
      return _lockIcon;
    } else if (isProfileFieldVisibilityPermitted(field)) {
      return _publicIcon;
    } else {
      return _privateIcon;
    }
  }

  Widget? _visibilityDropdownIcon(_ProfileField field, { bool locked = false} ) {
    if (locked) {
      return _lockIcon;
    } else if (isProfileFieldVisibilityPermitted(field)) {
      return _publicDropdownIcon;
    } else {
      return _privateDropdownIcon;
    }
  }

  bool isProfileFieldVisibilityPermitted(_ProfileField field) =>
    _permittedVisibility.contains(_fieldVisibilities[field]) && (_fieldTextNotEmpty[field] == true);

  Auth2FieldVisibility profileFieldVisibility(_ProfileField field) {
    Auth2FieldVisibility? profileFieldVisibility = _fieldVisibilities[field];
    return ((_fieldTextNotEmpty[field] == true) && (profileFieldVisibility != null) && _permittedVisibility.contains(profileFieldVisibility)) ? profileFieldVisibility : Auth2FieldVisibility.private;
  }

  static Widget? get _editIcon => Styles().images.getImage('edit', color: Styles().colors.fillColorPrimary, size: _buttonIconSize);
  static Widget? get _trashIcon => Styles().images.getImage('trash', color: Styles().colors.fillColorPrimary, size: _buttonIconSize);
  static Widget? get _publicIcon => Styles().images.getImage('eye', color: Styles().colors.fillColorSecondary, size: _buttonIconSize);
  static Widget? get _privateIcon => Styles().images.getImage('eye-slash', color: Styles().colors.mediumGray2, size: _buttonIconSize);
  static Widget? get _lockIcon => Styles().images.getImage('lock', color: Styles().colors.fillColorSecondary, size: _buttonIconSize);
  static Widget? get _playIcon => Styles().images.getImage('play', color: Styles().colors.fillColorPrimary, size: _buttonIconSize);
  static Widget? get _pauseIcon => Styles().images.getImage('pause', color: Styles().colors.fillColorPrimary, size: _buttonIconSize);
  static Widget? get _publicDropdownIcon => Styles().images.getImage('earth-americas', color: Styles().colors.fillColorSecondary, size: _buttonIconSize);
  static Widget? get _privateDropdownIcon => Styles().images.getImage('earth-americas', color: Styles().colors.mediumGray2, size: _buttonIconSize);
  static Widget? get _lockDropdownIcon => Styles().images.getImage('lock', color: Styles().colors.mediumGray2, size: _buttonIconSize);
  static Widget? get _chevronDropdownIcon => Styles().images.getImage('chevron-down', color: Styles().colors.mediumGray2, size: _dropdownButtonChevronIconSize);
  static Widget? get _redioOnDropdownIcon => Styles().images.getImage('radio-button-on', size: _buttonIconSize);
  static Widget? get _redioOffDropdownIcon => Styles().images.getImage('radio-button-off', size: _buttonIconSize);

  //static  Widget? get _stopIcon => Styles().images.getImage('stop', color: Styles().colors.fillColorPrimary, size: _editButtonIconSize);

  Widget _visibilityDropdown(_ProfileField field, {
      bool locked = false,
      EdgeInsetsGeometry buttonPadding = _dropdownButtonPadding,
      double buttonInnerIconPadding = _dropdownButtonInnerIconPaddingX,
    }) =>
    DropdownButtonHideUnderline(child:
      DropdownButton2<Auth2FieldVisibility>(
        dropdownStyleData: DropdownStyleData(
          width: _visibilityDropdownItemsWidth ??= _evaluateVisibilityDropdownItemsWidth(),
          direction: DropdownDirection.left,
          decoration: _controlDecoration,
        ),
        customButton: locked ? _visibilityDropdownLockedButton : _visibilityDropdownButton(field,
          padding: buttonPadding,
          innerIconPadding: buttonInnerIconPadding,
        ),
        isExpanded: false,
        items: _visibilityDropdownItems(field),
        onChanged: ((_fieldTextNotEmpty[field] == true) && !locked) ? (Auth2FieldVisibility? visibility) => _onDropdownFieldVisibility(field, visibility) : null,
      ),
    );

  Widget _visibilityDropdownButton(_ProfileField field, {
      bool locked = false,
      EdgeInsetsGeometry padding = _dropdownButtonPadding,
      double innerIconPadding = _dropdownButtonInnerIconPaddingX,
    }) =>
    Container(decoration: _controlDecoration, child:
      Padding(padding: padding, child:
        Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: _buttonIconSize, height: _buttonIconSize, child:
            Center(child: _visibilityDropdownIcon(field, locked: locked),)
          ),
          Padding(padding: EdgeInsets.only(left: innerIconPadding), child:
            SizedBox(width: _dropdownButtonChevronIconSize, height: _dropdownButtonChevronIconSize, child:
              Center(child:
                locked ? null : _chevronDropdownIcon,
              )
            )
          )
        ],)
      )
    );

  Widget get _visibilityDropdownLockedButton =>
      Container(decoration: _controlDecoration, child:
        Padding(padding: EdgeInsets.only(left: 23, right: 23, top: 15, bottom: 15), child:
          SizedBox(width: _buttonIconSize, height: _buttonIconSize, child:
            Center(child: _lockIcon,)
          ),
        )
      );

  List<DropdownMenuItem<Auth2FieldVisibility>> _visibilityDropdownItems(_ProfileField field) {
    List<DropdownMenuItem<Auth2FieldVisibility>> items = <DropdownMenuItem<Auth2FieldVisibility>>[];
    Auth2FieldVisibility selectedFieldVisibility = profileFieldVisibility(field);
    for (Auth2FieldVisibility fieldVisibility in Auth2FieldVisibility.values.reversed) {
      if ((fieldVisibility == Auth2FieldVisibility.private) || _permittedVisibility.contains(fieldVisibility)) {
        items.add(_visibilityDropdownItem(fieldVisibility, selected: selectedFieldVisibility == fieldVisibility));
      }
    }
    return items;
  }

  DropdownMenuItem<Auth2FieldVisibility> _visibilityDropdownItem(Auth2FieldVisibility visibility, { bool selected = false}) =>
    DropdownMenuItem<Auth2FieldVisibility>(
      value: visibility,
      child: Semantics(label: visibility.semanticLabel, container: true, button: true, child:
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisSize: MainAxisSize.max, children: [
            Padding(padding: EdgeInsets.only(right: _dropdownItemInnerIconPaddingX), child:
              SizedBox(width: _buttonIconSize, height: _buttonIconSize, child:
                Center(child: visibility.displayDropdownItemIcon)
              )
            ),
            Expanded(child:
              Text(visibility.displayTitle,
                overflow: TextOverflow.ellipsis,
                style: selected ? _selectedDropdownItemTextStyle : _regularDropdownItemTextStyle,
                semanticsLabel: "",
              ),
            ),
            Padding(padding: EdgeInsets.only(left: _dropdownItemInnerIconPaddingX), child:
              SizedBox(width: _buttonIconSize, height: _buttonIconSize, child:
                Center(child: selected ? _redioOnDropdownIcon : _redioOffDropdownIcon)
              )
            )
          ],),
          if (visibility.displayDescription.isNotEmpty)
            Padding(padding: EdgeInsets.symmetric(horizontal: _dropdownItemInnerIconPaddingX + _buttonIconSize), child:
              Text(visibility.displayDescription,
                overflow: TextOverflow.ellipsis,
                style: _descriptionDropdownItemTextStyle,
                semanticsLabel: "",
              ),
            )
        ],)
      ),
    );

  double _evaluateVisibilityDropdownItemsWidth() {
    double maxTextWidth = 0;
    for (Auth2FieldVisibility fieldVisibility in Auth2FieldVisibility.values) {
      if ((fieldVisibility == Auth2FieldVisibility.private) || _permittedVisibility.contains(fieldVisibility)) {
        final Size textSizeFull = (TextPainter(
          text: TextSpan(text: fieldVisibility.displayTitle, style: _selectedDropdownItemTextStyle,),
          textScaler: MediaQuery.of(context).textScaler,
          textDirection: TextDirection.ltr,
        )..layout()).size;
        if (maxTextWidth < textSizeFull.width) {
          maxTextWidth = textSizeFull.width;
        }
        final Size descriptionSizeFull = (TextPainter(
          text: TextSpan(text: fieldVisibility.displayDescription, style: _selectedDropdownItemTextStyle,),
          textScaler: MediaQuery.of(context).textScaler,
          textDirection: TextDirection.ltr,
        )..layout()).size;
        if (maxTextWidth < descriptionSizeFull.width) {
          maxTextWidth = descriptionSizeFull.width;
        }
      }
    }
    double dropdownItemWidth = (maxTextWidth * 5 / 3) + 2 * (_buttonIconSize + _dropdownItemInnerIconPaddingX) + _dropdownMenuItemPadding.horizontal;
    return min(dropdownItemWidth, MediaQuery.of(context).size.width * 2 / 3);
  }


  TextStyle? get _selectedDropdownItemTextStyle => Styles().textStyles.getTextStyle("widget.item.regular.extra_fat");
  TextStyle? get _regularDropdownItemTextStyle => Styles().textStyles.getTextStyle("widget.item.regular.semi_fat");
  TextStyle? get _descriptionDropdownItemTextStyle => Styles().textStyles.getTextStyle("widget.item.small.semi_fat");

  void _onDropdownFieldVisibility(_ProfileField field, Auth2FieldVisibility? visibility) {
    Analytics().logSelect(target: 'Select $field Visibility $visibility');
    setState(() {
      _fieldVisibilities[field] = visibility;
    });
  }


  BoxDecoration get _controlDecoration => BoxDecoration(
    color: Styles().colors.white,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );


  String? get _photoText => _fieldTextControllers[_ProfileField.photoUrl]?.text;
  set _photoText(String? value) {
    (_fieldTextControllers[_ProfileField.photoUrl] ??= TextEditingController()).text = value ?? '';
    _onTextChanged(_ProfileField.photoUrl, value ?? '');
  }

  String? get _pronunciationText => _fieldTextControllers[_ProfileField.pronunciationUrl]?.text;
  set _pronunciationText(String? value) {
    (_fieldTextControllers[_ProfileField.pronunciationUrl] ??= TextEditingController()).text = value ?? '';
    _onTextChanged(_ProfileField.pronunciationUrl, value ?? '');
  }

  void _onTextChanged(_ProfileField field, String value) {
    bool wasNotEmpty = (_fieldTextNotEmpty[field] == true);
    bool isNotEmpty = value.isNotEmpty;
    if ((wasNotEmpty != isNotEmpty) || field.isName) {
      setState(() {
        _fieldTextNotEmpty[field] = isNotEmpty;
      });
    }
  }

  void _onTextEdit(_ProfileField field) {
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
      Auth2FieldVisibility? visibility = _fieldVisibilities[field];
      _fieldVisibilities[field] = (_permittedVisibility.contains(visibility)) ?
        Auth2FieldVisibility.private : _positiveVisibility;
    });
  }

  Widget get _commandBar => Row(children: [
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

  void _onCancelEdit() async {
    Analytics().logSelect(target: 'Cancel Edit');
    FocusScope.of(context).unfocus();

    if (_saving == false) {
      Auth2UserProfile profile = _Auth2UserProfileUtils.buildModified(widget.profile, _fieldTextControllers);
      Auth2UserPrivacy? privacy = _showPrivacyControls ? Auth2UserPrivacy.fromOther(widget.privacy,
        fieldsVisibility: Auth2AccountFieldsVisibility.fromOther(widget.privacy?.fieldsVisibility,
            profile: _Auth2UserProfileFieldsVisibilityUtils.buildModified(_profileVisibility, _fieldVisibilities),
        )
      ) : null;

      bool? shouldSave = await _shouldSaveModified(
        profileModified: (profile != _Auth2UserProfileUtils.buildCopy(widget.profile)),
        privacyModified: (privacy != null) && (privacy != widget.privacy)
      );
      if (shouldSave == true) {
        _ProfileSaveResult result = await _saveEdit(profile, privacy);
        if (result.succeeded) {
          widget.onFinishEdit?.call(
            profile: (result.profile == true) ? profile : null,
            privacy: (result.privacy == true) ? privacy : null,
            pronunciationAudioData: _pronunciationAudioData,
            photoImageData: _photoImageData,
            photoImageToken: _photoImageToken,
          );
        }
      }
      else if (shouldSave == false) {
        widget.onFinishEdit?.call(
          photoImageData: _photoImageData,
          photoImageToken: _photoImageToken,
          pronunciationAudioData: _pronunciationAudioData,
        );
      }
    }
  }

  Future<bool?> _shouldSaveModified({bool? profileModified, bool? privacyModified}) async {
    String? prompt;
    if (profileModified == true) {
      prompt = (privacyModified == true) ?
        Localization().getStringEx('panel.profile.info.cancel.save.profile_and_privacy.prompt.text', 'Save your profile and privacy settings changes?') :
        Localization().getStringEx('panel.profile.info.cancel.save.profile.prompt.text', 'Save your profile settings changes?');
    }
    else if (privacyModified == true) {
      prompt = Localization().getStringEx('panel.profile.info.cancel.save.privacy.prompt.text', 'Save your privacy settings changes?');
    }

    return (prompt != null) ? await showDialog(context: context, builder: (context) =>
      AlertDialog(content: Text(prompt ?? ''), actions: <Widget>[
        TextButton(child:
          Text(Localization().getStringEx('dialog.yes.title', 'Yes')),
          onPressed: () {
            Analytics().logAlert(text: prompt, selection: 'Yes');
            Navigator.pop(context, true);
          }
        ),
        TextButton(child:
          Text(Localization().getStringEx('dialog.no.title', 'No')),
          onPressed: () {
            Analytics().logAlert(text: prompt, selection: 'No');
            Navigator.pop(context, false);
          }
        ),
        TextButton(child:
          Text(Localization().getStringEx('dialog.cancel.title', 'Cancel')),
          onPressed: () {
            Analytics().logAlert(text: prompt, selection: 'Cancel');
            Navigator.pop(context, null);
          }
        ),
      ])
    ) : false;
  }

  Widget get _saveEditButton => RoundedButton(
    label: Localization().getStringEx('dialog.save.title', 'Save'),
    fontFamily: Styles().fontFamilies.bold, fontSize: 16,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    progress: _saving,
    onTap: _onSaveEdit,
  );

  void _onSaveEdit() async {
    Analytics().logSelect(target: 'Save Edit');
    FocusScope.of(context).unfocus();

    if (_saving == false) {
      Auth2UserProfile profile = _Auth2UserProfileUtils.buildModified(widget.profile, _fieldTextControllers);
      Auth2UserPrivacy privacy = Auth2UserPrivacy.fromOther(widget.privacy,
        fieldsVisibility: _showPrivacyControls ? Auth2AccountFieldsVisibility.fromOther(widget.privacy?.fieldsVisibility,
            profile: _Auth2UserProfileFieldsVisibilityUtils.buildModified(_profileVisibility, _fieldVisibilities),
        ) : null
      );

      _ProfileSaveResult result = await _saveEdit(profile, _showPrivacyControls ? privacy : null);

      if (result.succeeded) {
        widget.onFinishEdit?.call(
          profile: (result.profile == true) ? profile : null,
          privacy: (result.privacy == true) ? privacy : null,
          pronunciationAudioData: _pronunciationAudioData,
          photoImageData: _photoImageData,
          photoImageToken: _photoImageToken,
        );
      }
    }
  }

  Future<_ProfileSaveResult> _saveEdit(Auth2UserProfile? profile, Auth2UserPrivacy? privacy) async {

    List<Future> futures = [];

    int? profileIndex = ((profile != null) && (profile != _Auth2UserProfileUtils.buildCopy(widget.profile))) ? futures.length : null;
    if (profileIndex != null) {
      futures.add(Auth2().saveUserProfile(profile));
    }

    int? privacyIndex = ((privacy != null) && (widget.privacy != privacy)) ? futures.length : null;
    if (privacyIndex != null) {
      futures.add(Auth2().saveUserPrivacy(privacy));
    }

    if (futures.length == 0) {
      return _ProfileSaveResult();
    }
    else {
      setStateIfMounted(() {
        _saving = true;
      });

      List<dynamic> results = await Future.wait(futures);

      setStateIfMounted(() {
        _saving = false;
      });

      bool? profileResult = ((profileIndex != null) && (profileIndex < results.length)) ? results[profileIndex] : null;
      bool? privacyResult = ((privacyIndex != null) && (privacyIndex < results.length)) ? results[privacyIndex] : null;
      if ((profileResult == false) || (privacyResult == false)) {
        await AppAlert.showTextMessage(context, Localization().getStringEx('panel.profile.info.save.failed.text', 'Failed to update profile and privacy settings.'));
      }
      return _ProfileSaveResult(profile: profileResult, privacy: privacyResult);
    }
  }

  // Returns true if we can close the UI, false if canceled.
  Future<bool> saveModified() async {
    FocusScope.of(context).unfocus();

    if (mounted && (_saving == false)) {
      Auth2UserProfile profile = _Auth2UserProfileUtils.buildModified(widget.profile, _fieldTextControllers);
      Auth2UserPrivacy privacy = Auth2UserPrivacy.fromOther(widget.privacy,
        fieldsVisibility: _showPrivacyControls ? Auth2AccountFieldsVisibility.fromOther(widget.privacy?.fieldsVisibility,
          profile: _Auth2UserProfileFieldsVisibilityUtils.buildModified(_profileVisibility, _fieldVisibilities),
        ) : null
      );

      bool? shouldSave = await _shouldSaveModified(
        profileModified: (profile != _Auth2UserProfileUtils.buildCopy(widget.profile)),
        privacyModified: _showPrivacyControls && (privacy != widget.privacy)
      );
      if (shouldSave == true) {
        await _saveEdit(profile, _showPrivacyControls ? privacy : null);
      }
      return (shouldSave != null);
    }
    else {
      return true;
    }
  }

  Auth2FieldVisibility get _positiveVisibility =>
    widget.contentType.positiveVisibility;

  Set<Auth2FieldVisibility> get _permittedVisibility =>
    widget.contentType.permitedVisibility;
}

///////////////////////////////////////////
// _ProfileSaveResult

class _ProfileSaveResult {
  bool? profile;
  bool? privacy;
  _ProfileSaveResult({this.profile, this.privacy});

  bool get succeeded => (profile ?? true) && (privacy ?? true);
}

///////////////////////////////////////////
// _ProfileField

enum _ProfileField {
  firstName, middleName, lastName, pronouns,
  photoUrl, pronunciationUrl,
  email, email2, phone, website,
  college, department, major, title,
}

extension _ProfileFieldExt on _ProfileField {
  bool get isName => (this == _ProfileField.firstName) || (this == _ProfileField.middleName) || (this == _ProfileField.lastName);
}

///////////////////////////////////////////
// Auth2LoginTypeProfileUtils

extension Auth2LoginTypeProfileUtils on Auth2LoginType {
  bool get canEditPrivacy => (this == Auth2LoginType.oidcIllinois);
  bool get shouldHaveName => (this == Auth2LoginType.oidcIllinois);
  bool get shouldHaveEmail => (this == Auth2LoginType.oidcIllinois) || (this == Auth2LoginType.email);
  bool get shouldHavePhone => (this == Auth2LoginType.phone) || (this == Auth2LoginType.phoneTwilio);
}
///////////////////////////////////////////
// Auth2UserProfile Utils

extension _Auth2UserProfileUtils on Auth2UserProfile {

  String? fieldValue(_ProfileField field) {
    switch(field) {
      case _ProfileField.firstName: return firstName;
      case _ProfileField.middleName: return middleName;
      case _ProfileField.lastName: return lastName;

      case _ProfileField.pronouns: return pronouns;

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
    }
  }

  static Auth2UserProfile buildModified(Auth2UserProfile? other, Map<_ProfileField, TextEditingController?> fields) =>
    Auth2UserProfile.fromOther(other,
      override: Auth2UserProfile(
        firstName: StringUtils.ensureNotEmpty(fields[_ProfileField.firstName]?.text),
        middleName: StringUtils.ensureNotEmpty(fields[_ProfileField.middleName]?.text),
        lastName: StringUtils.ensureNotEmpty(fields[_ProfileField.lastName]?.text),

        pronouns: StringUtils.ensureNotEmpty(fields[_ProfileField.pronouns]?.text),

        photoUrl: StringUtils.ensureNotEmpty(fields[_ProfileField.photoUrl]?.text),
        pronunciationUrl: StringUtils.ensureNotEmpty(fields[_ProfileField.pronunciationUrl]?.text),

        email: StringUtils.ensureNotEmpty(fields[_ProfileField.email]?.text),
        phone: StringUtils.ensureNotEmpty(fields[_ProfileField.phone]?.text),
        website: StringUtils.ensureNotEmpty(fields[_ProfileField.website]?.text),

        data: {
          Auth2UserProfile.collegeDataKey: StringUtils.ensureNotEmpty(fields[_ProfileField.college]?.text),
          Auth2UserProfile.departmentDataKey: StringUtils.ensureNotEmpty(fields[_ProfileField.department]?.text),
          Auth2UserProfile.majorDataKey: StringUtils.ensureNotEmpty(fields[_ProfileField.major]?.text),
          Auth2UserProfile.titleDataKey: StringUtils.ensureNotEmpty(fields[_ProfileField.title]?.text),
          Auth2UserProfile.email2DataKey: StringUtils.ensureNotEmpty(fields[_ProfileField.email2]?.text),
        }
      ),
      scope: <Auth2UserProfileScope> {
        Auth2UserProfileScope.firstName, Auth2UserProfileScope.middleName, Auth2UserProfileScope.lastName,
        Auth2UserProfileScope.pronouns,
        Auth2UserProfileScope.photoUrl, Auth2UserProfileScope.pronunciationUrl,
        Auth2UserProfileScope.email, /* Auth2UserProfileScope.email2, */ Auth2UserProfileScope.phone, Auth2UserProfileScope.website,
        /* Auth2UserProfileScope.college, Auth2UserProfileScope.department, Auth2UserProfileScope.major, Auth2UserProfileScope.title, */
      }
    );

  static Auth2UserProfile buildCopy(Auth2UserProfile? other) =>
    Auth2UserProfile.fromOther(other,
      override: Auth2UserProfile(
        firstName: StringUtils.ensureNotEmpty(other?.firstName),
        middleName: StringUtils.ensureNotEmpty(other?.middleName),
        lastName: StringUtils.ensureNotEmpty(other?.lastName),

        pronouns: StringUtils.ensureNotEmpty(other?.pronouns),

        photoUrl: StringUtils.ensureNotEmpty(other?.photoUrl),
        pronunciationUrl: StringUtils.ensureNotEmpty(other?.pronunciationUrl),

        email: StringUtils.ensureNotEmpty(other?.email),
        phone: StringUtils.ensureNotEmpty(other?.phone),
        website: StringUtils.ensureNotEmpty(other?.website),

        data: {
          Auth2UserProfile.collegeDataKey: StringUtils.ensureNotEmpty(other?.college),
          Auth2UserProfile.departmentDataKey: StringUtils.ensureNotEmpty(other?.department),
          Auth2UserProfile.majorDataKey: StringUtils.ensureNotEmpty(other?.major),
          Auth2UserProfile.titleDataKey: StringUtils.ensureNotEmpty(other?.title),
          Auth2UserProfile.email2DataKey: StringUtils.ensureNotEmpty(other?.email2),
        }
      ),
      scope: <Auth2UserProfileScope> {
        Auth2UserProfileScope.firstName, Auth2UserProfileScope.middleName, Auth2UserProfileScope.lastName,
        Auth2UserProfileScope.pronouns,
        Auth2UserProfileScope.photoUrl, Auth2UserProfileScope.pronunciationUrl,
        Auth2UserProfileScope.email, /* Auth2UserProfileScope.email2, */ Auth2UserProfileScope.phone, Auth2UserProfileScope.website,
        /* Auth2UserProfileScope.college, Auth2UserProfileScope.department, Auth2UserProfileScope.major, Auth2UserProfileScope.title, */
      }
    );
}

///////////////////////////////////////////
// Auth2UserProfileFieldsVisibility Utils

extension _Auth2UserProfileFieldsVisibilityUtils on Auth2UserProfileFieldsVisibility {

  Map<_ProfileField, Auth2FieldVisibility?> get fieldsVisibility => <_ProfileField, Auth2FieldVisibility?>{
    _ProfileField.firstName: firstName,
    _ProfileField.middleName: middleName,
    _ProfileField.lastName: lastName,

    _ProfileField.pronouns: pronouns,

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
  };

  static Auth2UserProfileFieldsVisibility buildModified(Auth2UserProfileFieldsVisibility? other, Map<_ProfileField, Auth2FieldVisibility?>? fields) =>
    Auth2UserProfileFieldsVisibility.fromOther(other,
      firstName : fields?[_ProfileField.firstName],
      middleName : fields?[_ProfileField.middleName],
      lastName : fields?[_ProfileField.lastName],

      pronouns : fields?[_ProfileField.pronouns],

      photoUrl : fields?[_ProfileField.photoUrl],
      pronunciationUrl : fields?[_ProfileField.pronunciationUrl],

      email : fields?[_ProfileField.email],
      phone : fields?[_ProfileField.phone],
      website : fields?[_ProfileField.website],

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

///////////////////////////////////////////
// _Auth2FieldVisibilityUI

extension _Auth2FieldVisibilityUI on Auth2FieldVisibility {

  String get displayTitle {
    switch(this) {
      case Auth2FieldVisibility.public: return Localization().getStringEx('panel.profile.info.directory_visibility.dropdown.public.title', 'Public');
      case Auth2FieldVisibility.connections: return Localization().getStringEx('panel.profile.info.directory_visibility.dropdown.connections.title', 'Only My Connections');
      case Auth2FieldVisibility.private: return Localization().getStringEx('panel.profile.info.directory_visibility.dropdown.private.title', 'Only me');
    }
  }

  String get displayDescription {
    switch(this) {
      case Auth2FieldVisibility.public: return Localization().getStringEx('panel.profile.info.directory_visibility.dropdown.public.description', 'Anyone can view');
      case Auth2FieldVisibility.connections: return Localization().getStringEx('panel.profile.info.directory_visibility.dropdown.connections.description', '');
      case Auth2FieldVisibility.private: return Localization().getStringEx('panel.profile.info.directory_visibility.dropdown.private.description', '');
    }
  }

  String get semanticLabel =>
    "$displayTitle $displayDescription";

  Widget? get displayDropdownItemIcon {
    switch(this) {
      case Auth2FieldVisibility.public: return ProfileInfoEditPageState._publicDropdownIcon;
      case Auth2FieldVisibility.connections: return ProfileInfoEditPageState._lockDropdownIcon;
      case Auth2FieldVisibility.private: return ProfileInfoEditPageState._lockDropdownIcon;
    }
  }
}