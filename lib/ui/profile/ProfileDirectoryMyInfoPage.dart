
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/ext/Directory.dart';
import 'package:illinois/model/Directory.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:illinois/ui/profile/ProfileDirectoryPage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileDirectoryMyInfoPage extends StatefulWidget {
  final MyDirectoryInfo contentType;
  ProfileDirectoryMyInfoPage({super.key, required this.contentType});

  @override
  State<StatefulWidget> createState() => _ProfileDirectoryMyInfoPageState();
}

class _ProfileDirectoryMyInfoPageState extends State<ProfileDirectoryMyInfoPage>  {

  late DirectoryMember _member;

  @override
  void initState() {
    _member = DirectoryMemberExt.fromExternalData(
      auth2Account: Auth2().account,
      studentClassification: IlliniCash().studentClassification,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(children: [
        Text(_desriptionText, style: Styles().textStyles.getTextStyle('widget.title.tiny'), textAlign: TextAlign.center,),
        Padding(padding: EdgeInsets.only(top: 24), child:
            Stack(children: [
              Padding(padding: EdgeInsets.only(top: _photoImageSize / 2), child:
                _cardWidget,
              ),
              Center(child:
                _photoImage,
              )
            ])
        )
      ],),
    );

  String get _desriptionText {
    switch (widget.contentType) {
      case MyDirectoryInfo.myConnectionsInfo: return AppTextUtils.appTitleString('panel.profile.directory.my_info.connections.description.text', 'Preview of how your profile displays for your ${AppTextUtils.appTitleMacro} Connections.');
      case MyDirectoryInfo.myDirectoryInfo: return AppTextUtils.appTitleString('panel.profile.directory.my_info.directory.description.text', 'Preview of how your profile displays in the directory.');
    }
  }

  double get _photoImageSize => MediaQuery.of(context).size.width / 3;

  Widget get _photoImage => (_member.photoUrl?.isNotEmpty == true) ?
    Container(
      width: _photoImageSize, height: _photoImageSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Styles().colors.background,
        image: DecorationImage(
          fit: BoxFit.cover,
          image: NetworkImage(_member.photoUrl ?? '', headers: _photoImageHeaders)
        ),
      )
    ) : (Styles().images.getImage('profile-placeholder', excludeFromSemantics: true, size: _photoImageSize) ?? Container());

  Map<String, String> get _photoImageHeaders => <String, String>{
    HttpHeaders.authorizationHeader : "${Auth2().token?.tokenType ?? 'Bearer'} ${Auth2().token?.accessToken}",
  };
//String tokenType = Auth2().token?.tokenType ?? 'Bearer';
//String token = Auth2().token?.accessToken ?? '';

  Widget get _cardWidget => Container(
    decoration: BoxDecoration(
      color: Styles().colors.white,
      border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
      borderRadius: BorderRadius.all(Radius.circular(16)),
      boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
    ),
    child: Padding(padding: EdgeInsets.only(top: _photoImageSize / 2), child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child:
                Center(child:
                  Text(_member.fullName, style: Styles().textStyles.getTextStyle('widget.title.medium_large.fat'), textAlign: TextAlign.center,))
                )
              ],),
            Padding(padding: EdgeInsets.only(top: 12), child:
              _expandedDetails
            )
        ],)
      )
    ),
  );

  Widget get _expandedDetails =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_member.college?.isNotEmpty == true)
          Text(_member.college ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'),),
        if (_member.department?.isNotEmpty == true)
          Text(_member.department ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'),),
        if (_member.major?.isNotEmpty == true)
          Text(_member.major ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'),),
        if (_member.email?.isNotEmpty == true)
          _linkDetail(_member.email ?? '', 'mailto:${_member.email}'),
        if (_member.email2?.isNotEmpty == true)
          _linkDetail(_member.email2 ?? '', 'mailto:${_member.email2}'),
        if (_member.phone?.isNotEmpty == true)
          _linkDetail(_member.phone ?? '', 'tel:${_member.phone}'),
        if (_member.website?.isNotEmpty == true)
          _linkDetail(_member.website ?? '', UrlUtils.fixUrl(_member.website ?? '', scheme: 'https') ?? _member.website ?? ''),
      ],);

  Widget _linkDetail(String text, String url) =>
    InkWell(onTap: () => _onTapLink(url, analyticsTarget: text), child:
      Text(text, style: Styles().textStyles.getTextStyleEx('widget.button.title.small.underline', decorationColor: Styles().colors.fillColorPrimary),),
    );

  void _onTapLink(String url, {String? analyticsTarget}) {
    Analytics().logSelect(target: analyticsTarget ?? url);
    _launchUrl(context, url);
  }

  static void _launchUrl(BuildContext context, String? url) {
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri, mode: (Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault));
        }
      }
    }
  }
}
