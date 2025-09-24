
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:illinois/ext/Auth2.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileInfoPreviewPage extends StatefulWidget {
  final Auth2UserProfile? profile;
  final Auth2UserPrivacy? privacy;
  final bool onboarding;
  final Uint8List? pronunciationAudioData;
  final Uint8List? photoImageData;
  final String? photoImageToken;

  ProfileInfoPreviewPage({super.key,
    this.profile, this.privacy, this.onboarding = false,
    this.photoImageData, this.photoImageToken, this.pronunciationAudioData
  });

  @override
  State<StatefulWidget> createState() => ProfileInfoPreviewPageState();
}

class ProfileInfoPreviewPageState extends State<ProfileInfoPreviewPage> {

  Auth2UserProfile? _publicProfile;

  @override
  void initState() {
    _publicProfile = widget.profile?.buildPublic(widget.privacy, permitted: { Auth2FieldVisibility.public });
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

  String? get _photoImageUrl => StringUtils.isNotEmpty(_publicProfile?.photoUrl) ?
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
          DirectoryProfileDetails(_publicProfile)
        ),
        //if (_canShare)
        //  _shareButton,
    ],)
  );

  Widget get _cardContentHeading => Column(children: [
    Padding(padding: EdgeInsets.only(top: (_publicProfile?.pronunciationUrl?.isNotEmpty == true) ? 0 : 12), child:
      RichText(textAlign: TextAlign.center, text: TextSpan(style: nameTextStyle, children: [
        TextSpan(text: _publicProfile?.fullName ?? ''),
        if (_publicProfile?.pronunciationUrl?.isNotEmpty == true)
          WidgetSpan(alignment: PlaceholderAlignment.middle, child:
            DirectoryPronunciationButton(
              url: _publicProfile?.pronunciationUrl,
              data: widget.pronunciationAudioData,
              padding: EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            ),
          ),
      ])),
    ),
  if (_publicProfile?.pronouns?.isNotEmpty == true)
    Text(_publicProfile?.pronouns ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'), textAlign: TextAlign.center,),
  ],);

  TextStyle? get nameTextStyle =>
    Styles().textStyles.getTextStyleEx('widget.title.medium_large.fat', fontHeight: 0.85, textOverflow: TextOverflow.ellipsis);
}

