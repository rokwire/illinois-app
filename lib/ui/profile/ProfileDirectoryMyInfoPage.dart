
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/ui/profile/ProfileDirectoryMyInfoEditPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryMyInfoPreviewPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryPage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

////////////////////////////////////////
// ProfileDirectoryMyInfoPage

class ProfileDirectoryMyInfoPage extends StatefulWidget {
  final MyProfileInfo contentType;
  ProfileDirectoryMyInfoPage({super.key, required this.contentType});

  @override
  State<StatefulWidget> createState() => _ProfileDirectoryMyInfoPageState();
}

class _ProfileDirectoryMyInfoPageState extends ProfileDirectoryMyInfoBasePageState<ProfileDirectoryMyInfoPage> {

  Auth2UserProfile? _profile;
  Auth2UserPrivacy? _privacy;
  Auth2UserProfile? _previewProfile;

  bool _loading = false;
  bool _editing = false;

  @override
  void initState() {
    super.photoImageToken = ProfileDirectoryMyInfoDateTimeUtils.imageToken;
    _loadProfileAndPrivacy();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _loadingContent;
    }
    else if (_editing) {
      return ProfileDirectoryMyInfoEditPage(
          contentType: widget.contentType,
          profile: _profile,
          privacy: _privacy,
          photoImageToken: photoImageToken,
          onFinishEdit: _onFinishEditInfo,
      );
    }
    else {
      return ProfileDirectoryMyInfoPreviewPage(
        contentType: widget.contentType,
        previewProfile: _previewProfile,
        photoImageToken: photoImageToken,
        onEditInfo: _onEditInfo,
      );
    }
  }

  Widget get _loadingContent => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 64,), child:
    Center(child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,)
      )
    )
  );

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

        Auth2UserProfileFieldsVisibility profileVisibility = Auth2UserProfileFieldsVisibility.fromOther(privacy?.fieldsVisibility?.profile,
          firstName: Auth2FieldVisibility.public,
          middleName: Auth2FieldVisibility.public,
          lastName: Auth2FieldVisibility.public,
          email: Auth2FieldVisibility.public,
        );

        _previewProfile = Auth2UserProfile.fromFieldsVisibility(_profile, profileVisibility, permitted: _permittedVisibility);

        _loading = false;
      });
    }
  }

  void _onEditInfo() {
    setStateIfMounted(() {
      _editing = true;
    });
  }

  void _onFinishEditInfo({Auth2UserProfile? profile, Auth2UserPrivacy? privacy, String? photoImageToken }) {
    setStateIfMounted((){
      if (profile != null) {
        _profile = profile;
      }

      if (privacy != null) {
        _privacy = privacy;
      }

      if (photoImageToken != null) {
        super.photoImageToken = photoImageToken;
      }

      if ((profile != null) || (privacy != null)) {
        Auth2UserProfileFieldsVisibility profileVisibility = Auth2UserProfileFieldsVisibility.fromOther(_privacy?.fieldsVisibility?.profile,
          firstName: Auth2FieldVisibility.public,
          middleName: Auth2FieldVisibility.public,
          lastName: Auth2FieldVisibility.public,
          email: Auth2FieldVisibility.public,
        );
        _previewProfile = Auth2UserProfile.fromFieldsVisibility(_profile, profileVisibility, permitted: _permittedVisibility);
      }

      _editing = false;
    });
  }

  Set<Auth2FieldVisibility> get _permittedVisibility =>
    super.permittedVisibility(widget.contentType);
}

///////////////////////////////////////////
// _ProfileDirectoryMyInfoUtilsPageState

class ProfileDirectoryMyInfoBasePageState<T extends StatefulWidget> extends State<T> {

  // Photo Image

  static const String _photoImageKey = 'edu.illinois.rokwire.token';
  String? photoImageToken;

  String? photoImageUrl(String? photoUrl) => ((photoUrl != null) && (photoImageToken != null)) ?
    UrlUtils.addQueryParameters(photoUrl, { _photoImageKey : photoImageToken ?? ''}) : photoUrl;

  Map<String, String> get photoImageHeaders => <String, String>{
    HttpHeaders.authorizationHeader : "${Auth2().token?.tokenType ?? 'Bearer'} ${Auth2().token?.accessToken}",
  };

  // Name Text Style

  TextStyle? get nameTextStyle =>
    Styles().textStyles.getTextStyleEx('widget.title.medium_large.fat', fontHeight: 0.85);

  // Progress Widget

  Widget get progressWidget =>
    CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary,);

  // Positive and Permited visibility

  static const Auth2FieldVisibility _directoryPositiveVisibility = Auth2FieldVisibility.public;
  static const Auth2FieldVisibility _connectionsPositiveVisibility = Auth2FieldVisibility.connections;

  Auth2FieldVisibility positiveVisibility(MyProfileInfo contentType) {
    switch(contentType) {
      case MyProfileInfo.myDirectoryInfo: return _directoryPositiveVisibility;
      case MyProfileInfo.myConnectionsInfo: return _connectionsPositiveVisibility;
    }
  }

  static const Set<Auth2FieldVisibility> _directoryPermittedVisibility = const <Auth2FieldVisibility>{ _directoryPositiveVisibility };
  static const Set<Auth2FieldVisibility> _connectionsPermittedVisibility = const <Auth2FieldVisibility>{ _directoryPositiveVisibility, _connectionsPositiveVisibility };

  Set<Auth2FieldVisibility> permittedVisibility(MyProfileInfo contentType) {
    switch(contentType) {
      case MyProfileInfo.myDirectoryInfo: return _directoryPermittedVisibility;
      case MyProfileInfo.myConnectionsInfo: return _connectionsPermittedVisibility;
    }
  }

  @override
  Widget build(BuildContext context) =>
    throw UnimplementedError();
}

///////////////////////////////////////////
// DateTime Utils

extension ProfileDirectoryMyInfoDateTimeUtils on DateTime {
  static String get imageToken => DateTime.now().millisecondsSinceEpoch.toString();
}
