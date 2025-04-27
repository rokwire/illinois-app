
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:illinois/ext/Auth2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/profile/ProfileInfoPage.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/ui/profile/ProfileInfoSharePanel.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileInfoPreviewPage extends StatefulWidget {
  final ProfileInfo contentType;
  final Auth2UserProfile? profile;
  final Auth2UserPrivacy? privacy;
  final bool onboarding;
  final Uint8List? pronunciationAudioData;
  final Uint8List? photoImageData;
  final String? photoImageToken;

  ProfileInfoPreviewPage({super.key, required this.contentType,
    this.profile, this.privacy, this.onboarding = false,
    this.photoImageData, this.photoImageToken, this.pronunciationAudioData
  });

  @override
  State<StatefulWidget> createState() => ProfileInfoPreviewPageState();
}

class ProfileInfoPreviewPageState extends State<ProfileInfoPreviewPage> {

  Auth2UserProfile? _profile;

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
          DirectoryProfileDetails(_profile)
        ),
        if ((widget.onboarding == false) && Auth2().isOidcLoggedIn && (_profile?.isNotEmpty == true))
          _shareButton,
    ],)
  );

  Widget get _cardContentHeading => Column(children: [
    Padding(padding: EdgeInsets.only(top: (_profile?.pronunciationUrl?.isNotEmpty == true) ? 0 : 12), child:
      RichText(textAlign: TextAlign.center, text: TextSpan(style: nameTextStyle, children: [
        TextSpan(text: _profile?.fullName ?? ''),
        if (_profile?.pronunciationUrl?.isNotEmpty == true)
          WidgetSpan(alignment: PlaceholderAlignment.middle, child:
            DirectoryPronunciationButton(
              url: _profile?.pronunciationUrl,
              data: widget.pronunciationAudioData,
              padding: EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            ),
          ),
      ])),
    ),
  if (_profile?.pronouns?.isNotEmpty == true)
    Text(_profile?.pronouns ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'), textAlign: TextAlign.center,),
  ],);

  Widget get _shareButton => Row(children: [
    Padding(padding: EdgeInsets.only(right: 4), child:
      Styles().images.getImage('share', size: 14) ?? Container()
    ),
    Expanded(child:
      LinkButton(
        title: Localization().getStringEx('panel.profile.info.command.link.share.text', 'Share My Info'),
        textStyle: Styles().textStyles.getTextStyle('widget.button.title.small.underline'),
        textAlign: TextAlign.left,
        padding: EdgeInsets.symmetric(vertical: 16),
        onTap: _onShare,
      ),
    ),
  ],);

  void _onShare() {
    Analytics().logSelect(target: 'Share');
    ProfileInfoShareSheet.present(context,
      profile: _profile,
      photoImageData: widget.photoImageData,
      pronunciationAudioData: widget.pronunciationAudioData,
    );
  }

  Set<Auth2FieldVisibility> get _permittedVisibility =>
    widget.contentType.permitedVisibility;

  TextStyle? get nameTextStyle =>
    Styles().textStyles.getTextStyleEx('widget.title.medium_large.fat', fontHeight: 0.85, textOverflow: TextOverflow.ellipsis);
}

