
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/ext/Directory.dart';
import 'package:illinois/model/Directory.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:illinois/ui/profile/ProfileDirectoryPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

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
      pronoun: 'he',
      college: 'Academic Affairs',
      department: 'Center for Advanced Study',
      phone: '(234) 567-8901'
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
                DirectoryMemberPhoto(_member, imageSize: _photoImageSize, headers: _photoImageHeaders,),
              )
            ])
        ),
        Padding(padding: EdgeInsets.only(top: 24), child:
          _commandBar,
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

  String get _desriptionText {
    switch (widget.contentType) {
      case MyDirectoryInfo.myConnectionsInfo: return AppTextUtils.appTitleString('panel.profile.directory.my_info.connections.description.text', 'Preview of how your profile displays for your ${AppTextUtils.appTitleMacro} Connections.');
      case MyDirectoryInfo.myDirectoryInfo: return AppTextUtils.appTitleString('panel.profile.directory.my_info.directory.description.text', 'Preview of how your profile displays in the directory.');
    }
  }

  double get _photoImageSize => MediaQuery.of(context).size.width / 3;

  Map<String, String> get _photoImageHeaders => <String, String>{
    HttpHeaders.authorizationHeader : "${Auth2().token?.tokenType ?? 'Bearer'} ${Auth2().token?.accessToken}",
  };

  Widget get _cardWidget => Container(
    decoration: BoxDecoration(
      color: Styles().colors.white,
      border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
      borderRadius: BorderRadius.all(Radius.circular(16)),
      boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
    ),
    child: Padding(padding: EdgeInsets.only(top: _photoImageSize / 2), child:
      _cardContent
    ),
  );

  Widget get _cardContent =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child:
            _cardContentHeading,
          ),
        ],),
        Padding(padding: EdgeInsets.only(top: 12), child:
          DirectoryMemberDetails(_member)
        ),
        Padding(padding: EdgeInsets.only(top: 6), child:
          _shareButton,
        )
    ],)
  );

  Widget get _cardContentHeading =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_member.fullName, style: Styles().textStyles.getTextStyleEx('widget.title.medium_large.fat', fontHeight: 0.85), textAlign: TextAlign.center,),
      if (_member.pronoun?.isNotEmpty == true)
        Text(_member.pronoun ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small')),
    ]);

  Widget get _commandBar {
    switch (widget.contentType) {
      case MyDirectoryInfo.myConnectionsInfo: return _myConnectionsInfoCommandBar;
      case MyDirectoryInfo.myDirectoryInfo: return _myDirectoryInfoCommandBar;
    }
  }

  Widget get _myConnectionsInfoCommandBar => Row(children: [
    Expanded(child: editInfoButton,),
    Container(width: 8),
    Expanded(child: swapInfoButton,),
  ],);

  Widget get _myDirectoryInfoCommandBar => Row(children: [
    Expanded(flex: 1, child: Container(),),
    Expanded(flex: 2, child: editInfoButton,),
    Expanded(flex: 1, child: Container(),),
  ],);

  Widget get editInfoButton => RoundedButton(
    label: Localization().getStringEx('panel.profile.directory.my_info.command.button.edit.text', 'Edit My Info'),
    fontFamily: Styles().fontFamilies.bold, fontSize: 16,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    onTap: _onEditInfo,
  );

  void _onEditInfo() {
    Analytics().logSelect(target: 'Edit My Info');
  }

  Widget get swapInfoButton => RoundedButton(
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
        padding: EdgeInsets.symmetric(vertical: 12),
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
  }

  Widget get _deleteAccountButton => LinkButton(
    title: AppTextUtils.appTitleString('panel.profile.directory.my_info.command.link.delete_account.text', 'Delete My ${AppTextUtils.appTitleMacro} App Account'),
    textStyle: Styles().textStyles.getTextStyle('widget.button.title.small.underline'),
    onTap: _onDeleteAccount,
  );

  void _onDeleteAccount() {
    Analytics().logSelect(target: 'Delete Account');
  }

}
