import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth.dart';
import 'package:illinois/service/Connectivity.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/onboarding/OnboardingLoginPhoneVerifyPanel.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/SectionTitlePrimary.dart';
import 'package:illinois/utils/Utils.dart';

class HomeLoginWidget extends StatefulWidget {

  HomeLoginWidget();

  @override
  _HomeLoginWidgetState createState() => _HomeLoginWidgetState();
}

class _HomeLoginWidgetState extends State<HomeLoginWidget> {

  @override
  Widget build(BuildContext context) {
    return _buildConnectPrimarySection();
  }

  Widget _buildConnectPrimarySection() {
    List<Widget> contentList = [];

    List<dynamic> codes = FlexUI()['home.connect'] ?? [];
    if(!codes.contains("netid")){
      codes.add("netid");
    }
    for (String code in codes) {
      if (code == 'netid') {
        contentList.add(HomeLoginNetIdWidget());
      } else if (code == 'phone') {
        contentList.add(HomeLoginPhoneWidget());
      }
    }

      if (AppCollection.isCollectionNotEmpty(contentList)) {
      List<Widget> content = <Widget>[];
      for (Widget entry in contentList) {
        if (entry != null) {
          if (content.isNotEmpty) {
            content.add(Container(height: 10,),);
          }
          content.add(entry);
        }
      }

      if (content.isNotEmpty) {
        content.add(Container(height: 20,),);
      }

      return SectionTitlePrimary(
        title: Localization().getStringEx("panel.home.connect.not_logged_in.title", "Connect to Illinois"),
        iconPath: 'images/icon-member.png',
        children: content,);
    }
    else {
      return Container();
    }
  }
}

class HomeLoginNetIdWidget extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return _buildConnectNetIdSection(context);
  }

  Widget _buildConnectNetIdSection(BuildContext context) {
    return Semantics(container: true, child: Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Styles().colors.surface, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))] ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Padding(padding: EdgeInsets.zero, child:
          RichText(textScaleFactor: MediaQuery.textScaleFactorOf(context), text:
          TextSpan(style: TextStyle(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: 16), children: <TextSpan>[
            TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_1", "Are you a ")),
            TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_2", "student"), style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold)),
            TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_3", " or ")),
            TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_4", "faculty member"), style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold)),
            TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_5", "? Sign in with your NetID."))
          ],),
          )),
          Container(margin: EdgeInsets.only(top: 14, bottom: 14), height: 1, color: Styles().colors.fillColorPrimaryTransparent015,),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
          Semantics(explicitChildNodes: true, child: ScalableRoundedButton(
            label: Localization().getStringEx("panel.home.connect.not_logged_in.netid.title", "Connect your NetID"),
            hint: '',
            borderColor: Styles().colors.fillColorSecondary,
            backgroundColor: Styles().colors.surface,
            textColor: Styles().colors.fillColorPrimary,
            onTap: ()=> _onTapConnectNetIdClicked(context),
          )),
          ),
        ]),
        ),
      ],),
    ));
  }


  void _onTapConnectNetIdClicked(BuildContext context) {
    Analytics.instance.logSelect(target: "Connect netId");
    if (Connectivity().isNotOffline) {
      Auth().authenticateWithShibboleth();
    } else {
      AppAlert.showOfflineMessage(context,"");
    }
  }
}

class HomeLoginPhoneWidget extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return _buildConnectPhoneSection(context);
  }

  Widget _buildConnectPhoneSection(BuildContext context) {
    return Semantics(container: true, child: Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Styles().colors.surface, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))] ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Padding(padding: EdgeInsets.zero, child:
            RichText(textScaleFactor: MediaQuery.textScaleFactorOf(context), text:
            TextSpan(style: TextStyle(color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular, fontSize: 16), children: <TextSpan>[
              TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.phone.description.part_1", "Don't have a NetID? "), style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold)),
              TextSpan( text: Localization().getStringEx("panel.home.connect.not_logged_in.phone.description.part_2", "Verify your phone number.")),
            ],),
            )),

            Container(margin: EdgeInsets.only(top: 14, bottom: 14), height: 1, color: Styles().colors.fillColorPrimaryTransparent015,),

            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child:
            Semantics(explicitChildNodes: true, child: ScalableRoundedButton(
              label: Localization().getStringEx("panel.home.connect.not_logged_in.phone.title", "Verify your phone number"),
              hint: '',
              borderColor: Styles().colors.fillColorSecondary,
              backgroundColor: Styles().colors.surface,
              textColor: Styles().colors.fillColorPrimary,
              onTap: ()=> _onTapConnectPhoneClicked(context),
            )),
            ),

          ]),
        ),
      ],),
    ));
  }

  void _onTapConnectPhoneClicked(BuildContext context) {
    Analytics.instance.logSelect(target: "Phone Verification");
    if (Connectivity().isNotOffline) {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: 'Phone Verification'), builder: (context) => OnboardingLoginPhoneVerifyPanel(onFinish: (_){_didConnectPhone(context);},)));
    } else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.label.offline.phone_ver', 'Verify Your Phone Number is not available while offline.'));
    }
  }

  void _didConnectPhone(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}