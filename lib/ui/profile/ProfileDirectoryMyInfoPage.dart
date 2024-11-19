
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/ext/Directory.dart';
import 'package:illinois/model/Directory.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:illinois/ui/profile/ProfileDirectoryPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/styles.dart';

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
              DirectoryMemberDetails(_member)
            )
        ],)
      )
    ),
  );
}
