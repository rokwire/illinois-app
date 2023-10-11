import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/settings/SettingsLoginPhoneOrEmailPanel.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeLoginWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeLoginWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  @override
  _HomeLoginWidgetState createState() => _HomeLoginWidgetState();
}

class _HomeLoginWidgetState extends State<HomeLoginWidget> implements NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyLoginChanged) {
      setStateIfMounted(() { });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildConnectPrimarySection();
  }

  Widget _buildConnectPrimarySection() {
    List<Widget> contentList = [];

    List<dynamic> codes = FlexUI()['home.connect'] ?? [];
    for (String code in codes) {
      if (code == 'netid') {
        contentList.add(_HomeLoginNetIdWidget());
      } else if (code == 'phone_or_email') {
        contentList.add(_HomeLoginPhoneOrEmailWidget());
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

      return HomeSlantWidget(favoriteId: widget.favoriteId,
          title: Localization().getStringEx("panel.home.connect.not_logged_in.title", "Connect to Illinois"),
          titleIconKey: 'person-circle',
          childPadding: HomeSlantWidget.defaultChildPadding,
          child: Column(children: content,),
      );
    }
    else {
      return Container();
    }
  }
}

class _HomeLoginNetIdWidget extends StatefulWidget {

  _HomeLoginNetIdWidget();

  @override
  _HomeLoginNetIdWidgetState createState() => _HomeLoginNetIdWidgetState();
}

class _HomeLoginNetIdWidgetState extends State<_HomeLoginNetIdWidget> {

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
          TextSpan(style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"), children: <TextSpan>[
            TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_1", "Are you a ")),
            TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_2", "university student"), style: Styles().textStyles?.getTextStyle("widget.detail.regular.fat")),
            TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_3", " or ")),
            TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_4", "employee"), style: Styles().textStyles?.getTextStyle("widget.detail.regular.fat")),
            TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_5", "? Sign in with your NetID to access features connected to your university account.")),
          ],),
          )),
          Container(margin: EdgeInsets.only(top: 14, bottom: 14), height: 1, color: Styles().colors!.fillColorPrimaryTransparent015,),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
          Semantics(explicitChildNodes: true, child: RoundedButton(
            label: Localization().getStringEx("panel.home.connect.not_logged_in.netid.title", "Sign In with your NetID"),
            hint: '',
            textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
            borderColor: Styles().colors!.fillColorSecondary,
            backgroundColor: Styles().colors!.surface,
            progress: (_authLoading == true),
            onTap: ()=> _onTapConnectNetIdClicked(context),
          )),
          ),
        ]),
        ),
      ],),
    ));
  }


  void _onTapConnectNetIdClicked(BuildContext context) {
    Analytics().logSelect(target: "Connect netId", source: widget.runtimeType.toString());
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context,"");
    }
    else if (_authLoading != true) {
      setState(() { _authLoading = true; });
      Auth2().authenticateWithOidc().then((Auth2OidcAuthenticateResult? result) {
        if (mounted) {
          setState(() { _authLoading = false; });
          if (result != Auth2OidcAuthenticateResult.succeeded) {
            AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
          }
        }
      });
    }
  }
}

class _HomeLoginPhoneOrEmailWidget extends StatelessWidget{
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
            TextSpan(style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"), children: <TextSpan>[
              TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.phone_or_email.description.part_1", "Don't have a NetID? "), style: Styles().textStyles?.getTextStyle("widget.detail.regular.fat")),
              TextSpan( text: Localization().getStringEx("panel.home.connect.not_logged_in.phone_or_email.description.part_2", "Verify your phone number or sign up/in by email.")),
            ],),
            )),

            Container(margin: EdgeInsets.only(top: 14, bottom: 14), height: 1, color: Styles().colors!.fillColorPrimaryTransparent015,),

            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child:
            Semantics(explicitChildNodes: true, child: RoundedButton(
              label: Localization().getStringEx("panel.home.connect.not_logged_in.phone_or_email.title", "Continue"),
              hint: '',
              textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
              borderColor: Styles().colors!.fillColorSecondary,
              backgroundColor: Styles().colors!.surface,
              onTap: ()=> _onTapPhoneOrEmailClicked(context),
            )),
            ),

          ]),
        ),
      ],),
    ));
  }

  void _onTapPhoneOrEmailClicked(BuildContext context) {
    Analytics().logSelect(target: "Phone or Email Login", source: runtimeType.toString());
    if (Connectivity().isNotOffline) {
      Navigator.push(context, CupertinoPageRoute(
        settings: RouteSettings(),
        builder: (context) => SettingsLoginPhoneOrEmailPanel(
          onFinish: () {
            _didLogin(context);
          }
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

