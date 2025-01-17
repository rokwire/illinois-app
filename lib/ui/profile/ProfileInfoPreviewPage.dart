
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/ui/profile/ProfileInfoPage.dart';
import 'package:neom/ui/directory/DirectoryWidgets.dart';
import 'package:neom/ui/profile/ProfileInfoSharePanel.dart';
import 'package:neom/ui/widgets/LinkButton.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/auth2.directory.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileInfoPreviewPage extends StatefulWidget {
  final ProfileInfo contentType;
  final Auth2UserProfile? profile;
  final Auth2UserPrivacy? privacy;
  final List<Auth2Identifier>? identifiers;
  final bool onboarding;
  final Uint8List? pronunciationAudioData;
  final Uint8List? photoImageData;
  final String? photoImageToken;

  ProfileInfoPreviewPage({super.key, required this.contentType,
    this.profile, this.privacy, this.identifiers, this.onboarding = false,
    this.photoImageData, this.photoImageToken, this.pronunciationAudioData
  });

  @override
  State<StatefulWidget> createState() => ProfileInfoPreviewPageState();
}

class ProfileInfoPreviewPageState extends ProfileDirectoryMyInfoBasePageState<ProfileInfoPreviewPage> {

  Auth2UserProfile? _profile;
  List<Auth2PublicAccountIdentifier>? _identifiers;

  @override
  void initState() {
    Auth2UserProfileFieldsVisibility profileVisibility = Auth2UserProfileFieldsVisibility.fromOther(widget.privacy?.fieldsVisibility?.profile,
      firstName: Auth2FieldVisibility.public,
      middleName: Auth2FieldVisibility.public,
      lastName: Auth2FieldVisibility.public,
    );

    _profile = Auth2UserProfile.fromFieldsVisibility(widget.profile, profileVisibility, permitted: _permittedVisibility);
    _identifiers = List.generate(widget.identifiers?.length ?? 0, (index) => Auth2PublicAccountIdentifier.fromUserIdentifier(widget.identifiers![index]));

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    Stack(children: [
      Padding(padding: EdgeInsets.only(top: _photoImageSize / 2), child:
        DirectoryProfileCard(roundingRadius: 16, child:
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
    ]);

  String? get _photoImageUrl => StringUtils.isNotEmpty(_profile?.photoUrl) ?
    Content().getUserPhotoUrl(type: UserProfileImageType.medium, params: DirectoryProfilePhotoUtils.tokenUrlParam(widget.photoImageToken)) : null;

  double get _photoImageSize => MediaQuery.of(context).size.width / 3;

  Map<String, String>? get _photoAuthHeaders => DirectoryProfilePhotoUtils.authHeaders;

  Widget get _publicCardContent =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child:
            _cardContentHeading,
          ),
        ],),
        Padding(padding: EdgeInsets.only(top: 12, bottom: 12), child:
          DirectoryProfileDetails(_profile, _identifiers,),
        ),
        if (widget.onboarding == false)
          _shareButton,
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
    ProfileInfoSharePanel.present(context, profile: _profile);
  }

  Set<Auth2FieldVisibility> get _permittedVisibility =>
    super.permittedVisibility(widget.contentType);
}
