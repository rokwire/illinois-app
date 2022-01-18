import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/onboarding2/Onboarding2LoginPhoneOrEmailPanel.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/SectionTitlePrimary.dart';
import 'package:rokwire_plugin/utils/Utils.dart';

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

    List<dynamic> codes = FlexUI()['home.content.connect'] ?? [];
    for (String code in codes) {
      if (code == 'netid') {
        contentList.add(HomeLoginNetIdWidget());
      } else if (code == 'phone_or_email') {
        contentList.add(HomeLoginPhoneOrEmailWidget());
      }
    }

      if (CollectionUtils.isNotEmpty(contentList)) {
      List<Widget> content = <Widget>[];
      for (Widget entry in contentList) {
        if (content.isNotEmpty) {
          content.add(Container(height: 10,),);
        }
        content.add(entry);
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

class HomeLoginNetIdWidget extends StatefulWidget {

  HomeLoginNetIdWidget();

  @override
  _HomeLoginNetIdWidgetState createState() => _HomeLoginNetIdWidgetState();
}

class _HomeLoginNetIdWidgetState extends State<HomeLoginNetIdWidget> {

  bool _authLoading = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(container: true, child: Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Styles().colors!.surface, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))] ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Padding(padding: EdgeInsets.zero, child:
          RichText(textScaleFactor: MediaQuery.textScaleFactorOf(context), text:
          TextSpan(style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16), children: <TextSpan>[
            TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_1", "Are you a ")),
            TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_2", "university student"), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold)),
            TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_3", " or ")),
            TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_4", "employee"), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold)),
            TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_5", "? Sign in with your NetID."))
          ],),
          )),
          Container(margin: EdgeInsets.only(top: 14, bottom: 14), height: 1, color: Styles().colors!.fillColorPrimaryTransparent015,),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
          Stack(children: <Widget>[
            Semantics(explicitChildNodes: true, child: ScalableRoundedButton(
              label: Localization().getStringEx("panel.home.connect.not_logged_in.netid.title", "Connect your NetID"),
              hint: '',
              borderColor: Styles().colors!.fillColorSecondary,
              backgroundColor: Styles().colors!.surface,
              textColor: Styles().colors!.fillColorPrimary,
              onTap: ()=> _onTapConnectNetIdClicked(context),
            )),
            Visibility(visible: _authLoading == true, child:
              Container(height: 42, child:
                Align(alignment: Alignment.center, child:
                  SizedBox(height: 24, width: 24, child:
                    CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), )
                  ),
                ),
              ),
            ),
          ]),
          ),
        ]),
        ),
      ],),
    ));
  }


  void _onTapConnectNetIdClicked(BuildContext context) {
    Analytics.instance.logSelect(target: "Connect netId");
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context,"");
    }
    else if (_authLoading != true) {
      setState(() { _authLoading = true; });
      Auth2().authenticateWithOidc().then((bool? result) {
        if (mounted) {
          setState(() { _authLoading = false; });
          if (result == false) {
            AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
          }
        }
      });
    }
  }
}

class HomeLoginPhoneOrEmailWidget extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Semantics(container: true, child: Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Styles().colors!.surface, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))] ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Padding(padding: EdgeInsets.zero, child:
            RichText(textScaleFactor: MediaQuery.textScaleFactorOf(context), text:
            TextSpan(style: TextStyle(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: 16), children: <TextSpan>[
              TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.phone_or_email.description.part_1", "Don't have a NetID? "), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold)),
              TextSpan( text: Localization().getStringEx("panel.home.connect.not_logged_in.phone_or_email.description.part_2", "Verify your phone number or sign up/in by email.")),
            ],),
            )),

            Container(margin: EdgeInsets.only(top: 14, bottom: 14), height: 1, color: Styles().colors!.fillColorPrimaryTransparent015,),

            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child:
            Semantics(explicitChildNodes: true, child: ScalableRoundedButton(
              label: Localization().getStringEx("panel.home.connect.not_logged_in.phone_or_email.title", "Proceed"),
              hint: '',
              borderColor: Styles().colors!.fillColorSecondary,
              backgroundColor: Styles().colors!.surface,
              textColor: Styles().colors!.fillColorPrimary,
              onTap: ()=> _onTapPhoneOrEmailClicked(context),
            )),
            ),

          ]),
        ),
      ],),
    ));
  }

  void _onTapPhoneOrEmailClicked(BuildContext context) {
    Analytics.instance.logSelect(target: "Phone or Email Login");
    if (Connectivity().isNotOffline) {
      Navigator.push(context, CupertinoPageRoute(
        settings: RouteSettings(),
        builder: (context) => Onboarding2LoginPhoneOrEmailPanel(
          onboardingContext: {
            "onContinueAction": () {
              _didLogin(context);
            }
          },
        ),
      ),);
    } else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.label.offline.phone_or_email', 'Feature not available when offline.'));
    }
  }

  void _didLogin(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

