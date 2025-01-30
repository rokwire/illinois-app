
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
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
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileInfoEditPage extends StatefulWidget {
  final ProfileInfo contentType;
  final Auth2UserProfile? profile;
  final Auth2UserPrivacy? privacy;
  final bool onboarding;
  final Uint8List? pronunciationAudioData;
  final Uint8List? photoImageData;
  final String? photoImageToken;
  final void Function({Auth2UserProfile? profile, Auth2UserPrivacy? privacy, Uint8List? pronunciationAudioData, Uint8List? photoImageData, String? photoImageToken})? onFinishEdit;

  ProfileInfoEditPage({super.key, required this.contentType,
    this.profile, this.privacy, this.onboarding = false,
    this.pronunciationAudioData, this.photoImageData, this.photoImageToken,
    this.onFinishEdit
  });

  @override
  State<StatefulWidget> createState() => ProfileInfoEditPageState();
}

class ProfileInfoEditPageState extends ProfileDirectoryMyInfoBasePageState<ProfileInfoEditPage> with WidgetsBindingObserver {

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
  Timer? _onScreenInsetsBottomChangedTimer;

  bool get _showProfileCommands => (widget.onboarding == false);

  @override
  void initState() {
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

    _profileVisibility = Auth2UserProfileFieldsVisibility.fromOther(widget.privacy?.fieldsVisibility?.profile,
      firstName: Auth2FieldVisibility.public,
      middleName: Auth2FieldVisibility.public,
      lastName: Auth2FieldVisibility.public,
      email: Auth2FieldVisibility.public,
    );

    _fieldVisibilities.addAll(_profileVisibility.fieldsVisibility);

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
  }

  @override
  Widget build(BuildContext context) =>
      Padding(padding: EdgeInsets.zero, child:
        Column(children: [
          _photoWidget,
          Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
            _nameWidget,
          ),

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

    Widget get _photoWidget => Stack(children: [
      Padding(padding: EdgeInsets.only(left: 8, right: 8, bottom: 20), child:
        DirectoryProfilePhoto(
          key: _photoKey,
          photoUrl: _photoImageUrl,
          photoUrlHeaders: _photoAuthHeaders,
          photoData: _photoImageData,
          imageSize: _photoImageSize,
        ),
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

    Widget get _togglePhotoVisibilityButton =>
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

    static const double _buttonIconSize = 16;

    Widget get _nameWidget =>
      Text(widget.profile?.fullName ?? '', style: nameTextStyle, textAlign: TextAlign.center,);

  // Edit: Pronunciation

  Widget get _pronunciationSection => _fieldSection(
    headingTitle: Localization().getStringEx('panel.profile.info.title.pronunciation.text', 'Name Pronunciation'),
    fieldControl: StringUtils.isNotEmpty(_pronunciationText) ? _pronunciationEditBar : _pronunciationCreateControl,
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

  Widget get _pronounsSection => _textFieldSection(_ProfileField.pronouns,
    headingTitle: Localization().getStringEx('panel.profile.info.title.pronouns.text', 'Pronouns'),
  );

  Widget get _titleSection => _textFieldSection(_ProfileField.title,
    headingTitle: Localization().getStringEx('panel.profile.info.title.title.text', 'Title'),
    headingHint: Localization().getStringEx('panel.profile.info.title.title.hint', '(Ex: Professional/Extracurricular Role)')
  );

  Widget get _collegeSection => _textFieldSection(_ProfileField.college,
    headingTitle: Localization().getStringEx('panel.profile.info.title.college.text', 'College'),
    enabled: false,
  );

  Widget get _departmentSection => _textFieldSection(_ProfileField.department,
    headingTitle: Localization().getStringEx('panel.profile.info.title.department.text', 'Department'),
    enabled: false,
  );

  Widget get _majorSection => _textFieldSection(_ProfileField.major,
    headingTitle: Localization().getStringEx('panel.profile.info.title.major.text', 'Major'),
    enabled: false,
  );

  Widget get _emailSection => _textFieldSection(_ProfileField.email,
    headingTitle: Localization().getStringEx('panel.profile.info.title.email.text', 'Email Address'),
    enabled: false, locked: true,
  );

  Widget get _email2Section => _textFieldSection(_ProfileField.email2,
    headingTitle: Localization().getStringEx('panel.profile.info.title.email2.text', 'Alternate Email Address'),
  );

  Widget get _phoneSection => _textFieldSection(_ProfileField.phone,
    headingTitle: Localization().getStringEx('panel.profile.info.title.phone.text', 'Phone Number'),
  );

  Widget get _websiteSection => _textFieldSection(_ProfileField.website,
    headingTitle: Localization().getStringEx('panel.profile.info.title.website.text', 'Website URL'),
    headingHint: Localization().getStringEx('panel.profile.info.title.website.hinr', '(Ex: Linkedin)'),
  );

  Widget _textFieldSection(_ProfileField field, {
    String? headingTitle, String? headingHint,
    TextInputType textInputType = TextInputType.text,
    bool autocorrect = true,
    bool enabled = true,
    bool locked = false,
  }) => _fieldSection(
    headingTitle: headingTitle,
    headingHint: headingHint,
    fieldControl: _textFieldControl(field,
        textInputType: textInputType,
        autocorrect: autocorrect,
        enabled: enabled,
        locked: locked,
    )
  );

  Widget _textFieldControl(_ProfileField field, {
    TextInputType textInputType = TextInputType.text,
    bool autocorrect = true,
    bool enabled = true,
    bool locked = false,
    }) => Row(children: [
      Expanded(child:
        _textFieldWidget(field, textInputType: textInputType, autocorrect: autocorrect, enabled: enabled)
      ),
      Padding(padding: EdgeInsets.only(left: 6), child:
        _visibilityButton(field, locked: locked),
      ),
    ],);

  Widget _fieldSection({
    String? headingTitle, String? headingHint,
    Widget? fieldControl,
  }) => Padding(padding: EdgeInsets.only(top: 12), child:
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
              readOnly: (enabled != true),
              onChanged: (String text) => _onTextChanged(field, text),
            )
          )
        ),
        if (enabled)
          InkWell(onTap: () => _onTextEdit(field), child:
            Padding(padding: EdgeInsets.only(left: 2, right: 14,  top: 14, bottom: 14), child:
              Styles().images.getImage('edit', color: Styles().colors.mediumGray2, size: _buttonIconSize)
            )
          ),
      ])
    );

  Widget _visibilityButton(_ProfileField field, { bool locked = false}) =>
    _iconButton(
      icon: _visibilityIcon(field, locked: locked),
      onTap: ((_fieldTextNotEmpty[field] == true) && !locked) ? () => _onToggleFieldVisibility(field) : null,
    );

  Widget _iconButton({ Widget? icon, bool progress = false, void Function()? onTap}) =>
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
    } else if (_permittedVisibility.contains(_fieldVisibilities[field]) && (_fieldTextNotEmpty[field] == true)) {
      return _publicIcon;
    } else {
      return _privateIcon;
    }
  }

  Widget? get _editIcon => Styles().images.getImage('edit', color: Styles().colors.fillColorPrimary, size: _buttonIconSize);
  Widget? get _trashIcon => Styles().images.getImage('trash', color: Styles().colors.fillColorPrimary, size: _buttonIconSize);
  Widget? get _publicIcon => Styles().images.getImage('eye', color: Styles().colors.fillColorSecondary, size: _buttonIconSize);
  Widget? get _privateIcon => Styles().images.getImage('eye-slash', color: Styles().colors.mediumGray2, size: _buttonIconSize);
  Widget? get _lockIcon => Styles().images.getImage('lock', color: Styles().colors.fillColorSecondary, size: _buttonIconSize);
  Widget? get _playIcon => Styles().images.getImage('play', color: Styles().colors.fillColorPrimary, size: _buttonIconSize);
  Widget? get _pauseIcon => Styles().images.getImage('pause', color: Styles().colors.fillColorPrimary, size: _buttonIconSize);
  //Widget? get _stopIcon => Styles().images.getImage('stop', color: Styles().colors.fillColorPrimary, size: _editButtonIconSize);

  Decoration get _controlDecoration => BoxDecoration(
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
    if (wasNotEmpty != isNotEmpty) {
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

    Auth2UserProfile profile = _Auth2UserProfileUtils.buildModified(widget.profile, _fieldTextControllers);
    Auth2UserPrivacy privacy = Auth2UserPrivacy.fromOther(widget.privacy,
      fieldsVisibility: Auth2AccountFieldsVisibility.fromOther(widget.privacy?.fieldsVisibility,
          profile: _Auth2UserProfileFieldsVisibilityUtils.buildModified(_profileVisibility, _fieldVisibilities),
      )
    );

    String? prompt;
    if (widget.profile != profile) {
      prompt = (widget.privacy != privacy) ?
        Localization().getStringEx('panel.profile.info.cancel.save.profile_and_privacy.prompt.text', 'Save your profile and privacy settings changes?') :
        Localization().getStringEx('panel.profile.info.cancel.save.profile.prompt.text', 'Save your profile settings changes?');
    }
    else if (widget.privacy != privacy) {
      prompt = Localization().getStringEx('panel.profile.info.cancel.save.privacy.prompt.text', 'Save your privacy settings changes?');
    }

    bool shouldSave = (prompt != null) ? await AppAlert.showConfirmationDialog(context,
      message: prompt,
      positiveButtonLabel: Localization().getStringEx('dialog.yes.title', 'Yes'),
      negativeButtonLabel: Localization().getStringEx('dialog.no.title', 'No')
    ) : false;
    if (shouldSave) {
      _onSaveEdit();
    }
    else {
      widget.onFinishEdit?.call(
        photoImageData: _photoImageData,
        photoImageToken: _photoImageToken,
        pronunciationAudioData: _pronunciationAudioData,
      );
    }
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
    saveEdit();
  }

  Future<bool> saveEdit() async {
    FocusScope.of(context).unfocus();

    if (_saving == true) {
      // Operation in progress
      return false;
    }
    else {
      Auth2UserProfile profile = _Auth2UserProfileUtils.buildModified(widget.profile, _fieldTextControllers);
      Auth2UserPrivacy privacy = Auth2UserPrivacy.fromOther(widget.privacy,
        fieldsVisibility: Auth2AccountFieldsVisibility.fromOther(widget.privacy?.fieldsVisibility,
            profile: _Auth2UserProfileFieldsVisibilityUtils.buildModified(_profileVisibility, _fieldVisibilities),
        )
      );

      List<Future> futures = [];

      int? profileIndex = (widget.profile != profile) ? futures.length : null;
      if (profileIndex != null) {
        futures.add(Auth2().saveUserProfile(profile));
      }

      int? privacyIndex = (widget.privacy != privacy) ? futures.length : null;
      if (privacyIndex != null) {
        futures.add(Auth2().saveUserPrivacy(privacy));
      }

      if (futures.length == 0) {
        // Nothing to save
        widget.onFinishEdit?.call(
          pronunciationAudioData: _pronunciationAudioData,
          photoImageData: _photoImageData,
          photoImageToken: _photoImageToken,
        );
        return true;
      }
      else {
        setState(() {
          _saving = true;
        });

        List<dynamic> results = await Future.wait(futures);

        if (mounted == false) {
          // Already stalled
          return false;
        }
        else {
          bool? profileResult = ((profileIndex != null) && (profileIndex < results.length)) ? results[profileIndex] : null;
          bool? privacyResult = ((privacyIndex != null) && (privacyIndex < results.length)) ? results[privacyIndex] : null;

          setState(() {
            _saving = false;
          });

          if ((profileResult ?? true) && (privacyResult ?? true)) {
            widget.onFinishEdit?.call(
              profile: (profileResult == true) ? profile : null,
              privacy: (privacyResult == true) ? privacy : null,
              pronunciationAudioData: _pronunciationAudioData,
              photoImageData: _photoImageData,
              photoImageToken: _photoImageToken,
            );
            return true; // Succeeded
          }
          else {
            AppAlert.showTextMessage(context, Localization().getStringEx('panel.profile.info.save.failed.text', 'Failed to update profile and privacy settings.'));
            return false; // Failed
          }
        }
      }
    }
  }

  Auth2FieldVisibility get _positiveVisibility =>
    widget.contentType.positiveVisibility;

  Set<Auth2FieldVisibility> get _permittedVisibility =>
    widget.contentType.permitedVisibility;
}

///////////////////////////////////////////
// _ProfileField

// NB: Use same naming with Auth2UserProfileScope
enum _ProfileField {
  pronouns,
  photoUrl, pronunciationUrl,
  email, email2, phone, website,
  college, department, major, title,
}

extension _ProfileFieldImpl on _ProfileField {

  // static _ProfileField? fromString(String value) => _ProfileField.values.firstWhereOrNull((field) => (field.toString() == value));

  static Set<Auth2UserProfileScope> get profileScope => <Auth2UserProfileScope> {
    Auth2UserProfileScope.pronouns,
    Auth2UserProfileScope.photoUrl, Auth2UserProfileScope.pronunciationUrl,
    Auth2UserProfileScope.email, /*Auth2UserProfileScope.email2,*/ Auth2UserProfileScope.phone, Auth2UserProfileScope.website,
    /* Auth2UserProfileScope.college, Auth2UserProfileScope.department, Auth2UserProfileScope.major, Auth2UserProfileScope.title, */
  };
}

///////////////////////////////////////////
// Auth2UserProfile Utils

extension _Auth2UserProfileUtils on Auth2UserProfile {

  String? fieldValue(_ProfileField field) {
    switch(field) {
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
      scope: _ProfileFieldImpl.profileScope,
    );
}

///////////////////////////////////////////
// Auth2UserProfileFieldsVisibility Utils

extension _Auth2UserProfileFieldsVisibilityUtils on Auth2UserProfileFieldsVisibility {

  Map<_ProfileField, Auth2FieldVisibility?> get fieldsVisibility => <_ProfileField, Auth2FieldVisibility?>{
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