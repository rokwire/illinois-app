

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/debug/DebugHomePanel.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/profile/ProfileLoginPhoneOrEmailPanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileLoginPage extends StatefulWidget {

  final EdgeInsetsGeometry margin;

  ProfileLoginPage({super.key, this.margin = const EdgeInsets.all(16) });

  @override
  State<StatefulWidget> createState() => _ProfileLoginPageState();
}

class _ProfileLoginPageState extends State<ProfileLoginPage> with NotificationsListener {
  bool _connectingNetId = false;
  bool _disconnectingNetId = false;
  bool _disconnectingPhone = false;
  bool _disconnectingEmail = false;
  bool get _disconnecting => _disconnectingNetId || _disconnectingPhone || _disconnectingEmail;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
      Auth2.notifyLinkChanged,
      Auth2.notifyPrefsChanged,
      FirebaseMessaging.notifySettingUpdated,
      FlexUI.notifyChanged,
      Styles.notifyChanged
    ]);

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyLoginChanged) {
      setStateIfMounted();
    } else if (name == Auth2.notifyLinkChanged){
      setStateIfMounted();
    } else if (name == Auth2.notifyPrefsChanged){
      setStateIfMounted();
    } else if (name == FirebaseMessaging.notifySettingUpdated) {
      setStateIfMounted();
    } else if (name == FlexUI.notifyChanged) {
      setStateIfMounted();
    } else if (name == Styles.notifyChanged) {
      setStateIfMounted();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = [];

    List<dynamic> codes = FlexUI()['authenticate'] ?? [];

    for (String code in codes) {
      if (code == 'connect') {
        contentList.add(_buildConnect());
      }
      else if (code == 'connected') {
        contentList.add(_buildConnected());
      }
    }

    if (kDebugMode || (Config().configEnvironment == ConfigEnvironment.dev)) {
      contentList.add(_buildDebug());
    }

    contentList.add(Container(height: 48 * 4,),);

    contentList.add(_buildAppInfo());

    return Padding(padding: widget.margin, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList)
    );
  }

  // Connect

  Widget _buildConnect() {
    List<Widget> contentList =  [];
    List<dynamic> codes = FlexUI()['authenticate.connect'] ?? [];
    for (String code in codes) {
      Widget? codeWidget;
      switch(code) {
        case 'netid': codeWidget = _signInWithNetIdWidget; break;
        case 'phone_or_email': codeWidget = Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 16), child: _signInWithPhoneOrEmailWidget); break;
      }
      if (codeWidget != null) {
        contentList.add(Padding(padding: EdgeInsetsGeometry.only(top: contentList.isNotEmpty ? 16 : 0), child:
          codeWidget,
        ));
      }
    }

    return Padding(padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:
        contentList
      ),
    );
  }

  Widget get _signInWithNetIdWidget =>
    ProfileLoginHighlightedBox(child:
        Column(children: [
          Text(Localization().getStringEx('panel.home.connect.not_logged_in.netid.description', 'Sign in with your Illinois NetID to access your Illini ID, course schedule, and other personalized features.'),
            style: Styles().textStyles.getTextStyle('widget.description.regular.thin')
          ),
          SizedBox(height: 16,),
          RoundedButton(
            label: Localization().getStringEx("panel.home.connect.not_logged_in.netid.button.title", "Sign In with Your NetID"),
            textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
            borderColor: Styles().colors.fillColorSecondary,
            backgroundColor: Styles().colors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            contentWeight: 0.75,
            progress: (_connectingNetId == true),
            onTap: _onConnectNetIdClicked,
          )
        ],)
    );

  void _onConnectNetIdClicked() {
    Analytics().logSelect(target: "Connect netId");
    if (!FlexUI().isAuthenticationAvailable) {
      AppAlert.showAuthenticationNAMessage(context);
    }
    else if (_connectingNetId != true) {
      setState(() { _connectingNetId = true; });
      Auth2().authenticateWithOidc().then((Auth2OidcAuthenticateResult? result) {
        if (mounted) {
          setState(() { _connectingNetId = false; });
          if (result != Auth2OidcAuthenticateResult.succeeded) {
            AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
          }
        }
      });
    }
  }

  Widget get _signInWithPhoneOrEmailWidget =>
    HtmlWidget(_signInWithPhoneOrEmailDescriptionHtml,
      onTapUrl : (url) { _onTapSignInWithPhoneOrEmailLink(context, url); return true; },
      textStyle:  Styles().textStyles.getTextStyle("widget.description.small"),
      customStylesBuilder: (element) => _htmlStyleMap[element.localName?.toLowerCase()],
    );

  static const String _localScheme = 'local';
  static const String _signInHost = 'signin';
  static const String _signInUrlMacro = '{{signin_url}}';
  static const String _signInUrl = '$_localScheme://$_signInHost';

  String get _signInWithPhoneOrEmailDescriptionHtml => Localization().getStringEx("panel.home.connect.not_logged_in.phone_or_email.description", "<b>Don’t have a NetID?</b> <a href='$_signInUrlMacro'>Use your mobile phone number or personal (non-Illinois) email address to sign in.</a><p>Once a NetID is issued, sign in above using your NetID.</p>").
    replaceAll(_signInUrlMacro, _signInUrl);

  Map<String, Map<String, String>> get _htmlStyleMap => {
    'a' : _htmlLinkStyle
  };

  Map<String, String> get _htmlLinkStyle => <String, String>{
    'color': _htmlTextColor,
    'text-decoration-color': _htmlLinkColor,
  };

  String get _htmlTextColor => ColorUtils.toHex(Styles().colors.fillColorPrimary);
  String get _htmlLinkColor => ColorUtils.toHex(Styles().colors.fillColorSecondary);

  void _onTapSignInWithPhoneOrEmailLink(BuildContext context, String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if ((uri?.scheme == _localScheme) && (uri?.host == _signInHost)) {
      _connectPhoneOrEmail();
    }
  }

  void _connectPhoneOrEmail() {
    Analytics().logSelect(target: "Phone or Email Login", source: runtimeType.toString());
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.settings.label.offline.phone_or_email', 'Feature not available when offline.'));
    }
    else if (!FlexUI().isAuthenticationAvailable) {
      AppAlert.showAuthenticationNAMessage(context);
    }
    else {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) => ProfileLoginPhoneOrEmailPanel(onFinish: _popToMe),),);
    }
  }

  void _popToMe() {
    Navigator.of(context).popUntil((Route route){
      return route.settings.name == ProfileHomePanel.routeName;
      // return AppNavigation.routeRootWidget(route, context: context)?.runtimeType == widget.parentWidget.runtimeType;
    });
  }

  // Connected

  Widget _buildConnected() {
    List<Widget> contentList =  [];

    List<dynamic> codes = FlexUI()['authenticate.connected'] ?? [];
    for (String code in codes) {
      Widget? codeWidget;
      switch(code) {
        case 'netid': codeWidget = _buildConnectedNetIdLayout(); break;
        case 'phone': codeWidget = _buildConnectedPhoneLayout(); break;
        case 'email': codeWidget = _buildConnectedEmailLayout(); break;
      }
      if (codeWidget != null) {
        contentList.add(Padding(padding: EdgeInsetsGeometry.only(top: contentList.isNotEmpty ? 16 : 0), child:
          codeWidget,
        ));
      }
    }

    return contentList.isNotEmpty ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList) : Container();
  }


  Widget _buildConnectedNetIdLayout() {
    List<Widget> contentList = [];

    List<dynamic> codes = FlexUI()['authenticate.connected.netid'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      if (code == 'info') {
        contentList.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(Localization().getStringEx("panel.settings.home.net_id.message", "Signed in with your NetID"),
            style: Styles().textStyles.getTextStyle("widget.message.regular.extra_fat")),
          Padding(padding: EdgeInsets.only(top: 3), child: Text(Auth2().fullName ?? "",
            style: Styles().textStyles.getTextStyle("widget.detail.large.fat"))),
        ]));
      }
      else if (code == 'disconnect') {
        contentList.add(Padding(padding: EdgeInsets.only(top: 12), child:
          Row(children: [ Expanded(child:
            Wrap(alignment: WrapAlignment.start, spacing: 8, runSpacing: 8, children: [
              CompactRoundedButton(
                label: Localization().getStringEx("panel.settings.home.net_id.button.profile", "View My Profile"),
                textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
                onTap: _onViewProfileClicked
              ),
              CompactRoundedButton(
                label: Localization().getStringEx("panel.settings.home.net_id.button.disconnect", "Sign Out"),
                textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
                progress: _disconnectingNetId,
                onTap: _onDisconnectNetIdClicked
              ),
            ],),
          ),],),
        ));
      }
    }

    return ProfileLoginHighlightedBox(child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList,),
    );
  }

  Widget _buildConnectedPhoneLayout() {
    List<Widget> contentList = [];

    String fullName = Auth2().fullName ?? "";
    bool hasFullName = StringUtils.isNotEmpty(fullName);

    List<dynamic> codes = FlexUI()['authenticate.connected.phone'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      if (code == 'info') {
        contentList.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(Localization().getStringEx("panel.settings.home.phone_ver.message", "Signed in with your Phone"),
              style: Styles().textStyles.getTextStyle("widget.message.regular.extra_fat")),
          Visibility(visible: hasFullName, child:
            Padding(padding: EdgeInsets.only(top: 3), child:
              Text(fullName, style: Styles().textStyles.getTextStyle("widget.detail.large.fat"))
            )
          ),
          Padding(padding: EdgeInsets.only(top: 3), child:
            Text(Auth2().account?.authType?.phone ?? "", style: Styles().textStyles.getTextStyle("widget.detail.large.fat"))
          )
        ]));
      }
      else if (code == 'verify') {
        contentList.add(RibbonButton(
            border: _allBorder,
            borderRadius: _allRounding,
            title: Localization().getStringEx("panel.settings.home.phone_ver.button.connect", "Verify Your Mobile Phone Number"),
            onTap: _connectPhoneOrEmail));
      }
      else if (code == 'disconnect') {
        contentList.add(Padding(padding: EdgeInsets.only(top: 12), child:
          RoundedButton(
            label: Localization().getStringEx("panel.settings.home.phone_ver.button.disconnect", "Sign Out"),
            textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
            contentWeight: 0.45,
            conentAlignment: MainAxisAlignment.start,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            progress: _disconnectingPhone,
            onTap: _onDisconnectPhoneClicked
          )
        ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ProfileLoginHighlightedBox(child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList,),
      ),
      Padding(padding: EdgeInsetsGeometry.only(left: 16, right: 16, top: 12), child:
        _connectedPhoneOrEmailDescription
      )
    ],);
  }

  Widget _buildConnectedEmailLayout() {
    List<Widget> contentList = [];

    String fullName = Auth2().fullName ?? "";
    bool hasFullName = StringUtils.isNotEmpty(fullName);

    List<dynamic> codes = FlexUI()['authenticate.connected.email'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      if (code == 'info') {
        contentList.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(Localization().getStringEx("panel.settings.home.email_login.message", "Signed in with your Email"),
              style: Styles().textStyles.getTextStyle("widget.message.regular.extra_fat")),
          Visibility(visible: hasFullName, child:
            Padding(padding: EdgeInsets.only(top: 3), child:
              Text(fullName, style: Styles().textStyles.getTextStyle("widget.detail.large.fat"))
            )
          ),
          Padding(padding: EdgeInsets.only(top: 3), child:
            Text(Auth2().account?.authType?.email ?? "", style:  Styles().textStyles.getTextStyle("widget.detail.large.fat"))
          )
        ]));
      }
      else if (code == 'login') {
        contentList.add(RibbonButton(
          border: _allBorder,
          borderRadius: _allRounding,
          title: Localization().getStringEx("panel.settings.home.email_login.button.connect", "Login With Email"),
          onTap: _connectPhoneOrEmail
        ));
      }
      else if (code == 'disconnect') {
        contentList.add(Padding(padding: EdgeInsets.only(top: 12), child:
          RoundedButton(
            label: Localization().getStringEx("panel.settings.home.email_login.button.disconnect", "Sign Out"),
            textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
            contentWeight: 0.45,
            conentAlignment: MainAxisAlignment.start,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            progress: _disconnectingEmail,
            onTap: _onDisconnectEmailClicked
          )
        ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ProfileLoginHighlightedBox(child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList,),
      ),
      Padding(padding: EdgeInsetsGeometry.only(left: 16, right: 16, top: 12,), child:
        _connectedPhoneOrEmailDescription
      )
    ],);
  }

  Widget get _connectedPhoneOrEmailDescription =>
    Text(Localization().getStringEx('panel.settings.home.connect.logged_in.phone_or_email.description.text', 'Once you\'ve been issued an Illinois NetID, sign out, then sign in again with "Sign In with Your NetID" to access university features.'),
      style: Styles().textStyles.getTextStyle('widget.description.regular.thin'),);

  void _onDisconnectNetIdClicked() {
    Analytics().logSelect(target: 'Sign Out: Disconnect NetId');
    _logout(progress: (value) => setStateIfMounted(() => _disconnectingNetId = value));
  }

  void _onDisconnectPhoneClicked() {
    Analytics().logSelect(target: 'Sign Out: Disconnect Phone');
    _logout(progress: (value) => setStateIfMounted(() => _disconnectingPhone = value));
  }

  void _onDisconnectEmailClicked() {
    Analytics().logSelect(target: 'Sign Out: Disconnect Email');
    _logout(progress: (value) => setStateIfMounted(() => _disconnectingEmail = value));
  }

  void _logout({ void Function(bool)? progress }) {
    if (_disconnecting != true) {
      showDialog<bool?>(context: context, builder: (context) => ProfilePromptLogoutWidget()).then((bool? result) {
        if (result == true) {
          progress?.call(true);
          Auth2().logout().then((_){
            progress?.call(false);
          });
        }
      });
    }
  }

  void _onViewProfileClicked() {
    Analytics().logSelect(target: 'View Profile');
    NotificationService().notify(ProfileHomePanel.notifySelectContent, ProfileContentType.profile);
  }

  // Linked



  // Debug

  Widget _buildDebug() => Padding(padding: EdgeInsets.only(top: 24), child:
    RibbonButton(
      border: _allBorder,
      borderRadius: _allRounding,
      title: Localization().getStringEx("panel.profile_info.button.debug.title", "Debug"),
      onTap: _onDebugClicked)
    );

  void _onDebugClicked() {
    Analytics().logSelect(target: "Debug");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugHomePanel()));
  }

  // App Info

  Widget _buildAppInfo() => Column(children: [
    Container(
      padding: const EdgeInsets.all(6),
      child: SizedBox(width: 51, height: 51, child:
        Styles().images.getImage('university-logo-oval-white', fit: BoxFit.contain),
      ),
    ),
    Padding(padding: const EdgeInsets.only(top: 8)),
    RichText(textAlign: TextAlign.left, text:
      TextSpan(style: Styles().textStyles.getTextStyle("widget.item.regular.thin"), children:[
        TextSpan(text: Localization().getStringEx('panel.settings.home.version.info.label', '{{app_title}} App Version:').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')),),
        TextSpan(text:  " $_appVersion", style : Styles().textStyles.getTextStyle("widget.item.regular.fat")),
      ])
    ),
    Text(_copyrightText, textAlign: TextAlign.center, style:  Styles().textStyles.getTextStyle("widget.item.regular.thin"))
  ],);

  String get _appVersion => Config().appVersion ?? '';

  String get _copyrightText => Localization().getStringEx('panel.settings.home.copyright.text', 'Copyright © {{COPYRIGHT_YEAR}} University of Illinois Board of Trustees')
    .replaceAll('{{COPYRIGHT_YEAR}}', DateFormat('yyyy').format(DateTime.now()));

  // Utilities


  static Border get _allBorder => Border.all(color: Styles().colors.surfaceAccent, width: 1);
  static const BorderRadius _allRounding = BorderRadius.all(Radius.circular(5));
}

class ProfilePromptLogoutWidget extends StatelessWidget {
  ProfilePromptLogoutWidget({super.key});

  @override
  Widget build(BuildContext context) => Dialog(child:
    Padding(padding: EdgeInsets.all(18), child:
      Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Text(AppTextUtils.appTitleString("panel.settings.home.logout.title", AppTextUtils.appTitleMacro),
          style: Styles().textStyles.getTextStyle("widget.message.dark.extra_large"),
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: 26), child:
          Text(_promptText(), textAlign: TextAlign.left,
            style: Styles().textStyles.getTextStyle("widget.message.dark.medium")
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
          TextButton(onPressed: () => _onTapYes(context), child:
            Text(Localization().getStringEx("panel.settings.home.logout.button.yes", "Yes"))
          ),
          TextButton(onPressed: () => _onTapNo(context), child:
            Text(Localization().getStringEx("panel.settings.home.logout.no", "No"))
          )
        ],),
      ],),
    ),
  );

  String _promptText({String? language}) => Localization().getStringEx("panel.settings.home.logout.message", "Are you sure you want to sign out?", language: 'en');

  void _onTapYes(BuildContext context) {
    Analytics().logAlert(text: _promptText(language: 'en'), selection: "Yes");
    Navigator.pop(context, true);
  }

  void _onTapNo(BuildContext context) {
    Analytics().logAlert(text: _promptText(language: 'en'), selection: "No");
    Navigator.pop(context, false);
  }
}

class ProfileLoginHighlightedBox extends StatelessWidget {
  final Widget? child;
  ProfileLoginHighlightedBox({this.child});

  @override
  Widget build(BuildContext context) =>
    Container(decoration: decoration, padding: padding, child: child);

  static BoxDecoration get decoration => BoxDecoration(
    color: Styles().colors.white,
    borderRadius: BorderRadius.all(Radius.circular(4)),
    border: Border.all(color: Styles().colors.fillColorPrimary, width: 1)
  );

  static EdgeInsets get padding =>
    EdgeInsets.symmetric(horizontal: 16, vertical: 12);
}