import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:illinois/ext/Auth2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/profile/ProfileLoginPhoneOrEmailPanel.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class HomeLoginWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeLoginWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  @override
  _HomeLoginWidgetState createState() => _HomeLoginWidgetState();
}

class _HomeLoginWidgetState extends State<HomeLoginWidget> with NotificationsListener {

  late bool _visible;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
      FlexUI.notifyChanged,
    ]);
    _visible = Storage().homeLoginVisible != false;
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void onNotification(String name, dynamic param) {
    if ((name == Auth2.notifyLoginChanged) || (name == FlexUI.notifyChanged)) {
      setStateIfMounted(() { });
    }
  }

  @override
  Widget build(BuildContext context) =>
    _visible ? _buildContentWidget(_contentWidgets) : Container();

  Widget _buildContentWidget(List<Widget> contentWidgets) =>
    contentWidgets.isNotEmpty ? _buildContentCard(contentWidgets) : Container();

  Widget _buildContentCard(List<Widget> contentWidgets) =>
    HomeCardWidget(
      title: Localization().getStringEx("panel.home.connect.not_logged_in.title", "Connect to Illinois").toUpperCase(),
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
      onClose: _onClose,
      child: Column(children:contentWidgets),
    );

  List<Widget> get _contentWidgets {
    List<Widget> contentList = <Widget>[];

    List<dynamic> codes = FlexUI()['home.connect'] ?? [];
    for (String code in codes) {
      if (code == 'netid') {
        _addContentWidget(contentList, _HomeLoginNetIdWidget());
      } else if (code == 'phone_or_email') {
        _addContentWidget(contentList, _HomeLoginPhoneOrEmailWidget());
      }
    }
    return contentList;
  }

  void _addContentWidget(List<Widget> contentList, Widget contentWidget) {
    if (contentList.isNotEmpty) {
      contentList.add(
        Padding(padding: EdgeInsets.only(bottom: 16), child:
          Container(height: 1, color: Styles().colors.fillColorPrimaryTransparent015,),
        )
      );
    }
    contentList.add(contentWidget);
  }
  
  void _onClose() {
    Analytics().logSelect(target: "Close", source: widget.runtimeType.toString());
    setState(() {
      Storage().homeLoginVisible = _visible = false;
    });
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
  Widget build(BuildContext context) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      //Container(margin: EdgeInsets.only(bottom: 12), height: 1, color: Styles().colors.fillColorPrimaryTransparent015,),
      RichText(textScaler: MediaQuery.of(context).textScaler, text:
        TextSpan(style: Styles().textStyles.getTextStyle("widget.item.regular.thin"), children: <TextSpan>[
          TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_1", "Are you a ")),
          TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_2", "university student"), style: Styles().textStyles.getTextStyle("widget.detail.regular.fat")),
          TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_3", " or ")),
          TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_4", "employee"), style: Styles().textStyles.getTextStyle("widget.detail.regular.fat")),
          TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.netid.description.part_5", "? Sign in with your NetID to access features connected to your university account.")),
        ],),
      ),
      Padding(padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16), child:
        Semantics(explicitChildNodes: true, child:
          RoundedButton(
            label: Localization().getStringEx("panel.home.connect.not_logged_in.netid.title", "Sign In with your NetID"),
            textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
            borderColor: Styles().colors.fillColorSecondary,
            backgroundColor: Styles().colors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            progress: (_authLoading == true),
            onTap: ()=> _onTapConnectNetIdClicked(context),
          )
        ),
      ),
    ]);


  void _onTapConnectNetIdClicked(BuildContext context) {
    Analytics().logSelect(target: "Connect netId", source: widget.runtimeType.toString());
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context,"");
    }
    else if (!FlexUI().isAuthenticationAvailable) {
      AppAlert.showAuthenticationNAMessage(context);
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
  Widget build(BuildContext context) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Padding(padding: EdgeInsets.zero, child:
        RichText(textScaler: MediaQuery.of(context).textScaler, text:
        TextSpan(style: Styles().textStyles.getTextStyle("widget.item.regular.thin"), children: <TextSpan>[
          TextSpan(text: Localization().getStringEx("panel.home.connect.not_logged_in.phone_or_email.description.part_1", "Don't have a NetID? "), style: Styles().textStyles.getTextStyle("widget.detail.regular.fat")),
          TextSpan( text: (Auth2().prefs?.isProspective != true) ?
            Localization().getStringEx("panel.home.connect.not_logged_in.phone_or_email.description.part_2a", "Verify your phone number or sign up/in by email.") :
            Localization().getStringEx("panel.home.connect.not_logged_in.phone_or_email.description.part_2b", "Sign in with an email address to access more features.")
          ),
        ],),
      )),

      Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), child:
        Semantics(explicitChildNodes: true, child:
          RoundedButton(
            label: Localization().getStringEx("panel.home.connect.not_logged_in.phone_or_email.title", "Continue"),
            hint: '',
            textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
            borderColor: Styles().colors.fillColorSecondary,
            backgroundColor: Styles().colors.surface,
            onTap: ()=> _onTapPhoneOrEmailClicked(context),
          ),
        ),
      ),

    ]);

  void _onTapPhoneOrEmailClicked(BuildContext context) {
    Analytics().logSelect(target: "Phone or Email Login", source: runtimeType.toString());
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.label.offline.phone_or_email', 'Feature not available when offline.'));
    }
    else if (!FlexUI().isAuthenticationAvailable) {
      AppAlert.showAuthenticationNAMessage(context);
    }
    else {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) => ProfileLoginPhoneOrEmailPanel(onFinish: () => _didLogin(context)),),);
    }
  }

  void _didLogin(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

