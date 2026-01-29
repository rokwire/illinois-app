
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/debug/DebugHomePanel.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/profile/ProfileLoginLinkedAccountPanel.dart';
import 'package:illinois/ui/profile/ProfileLoginEmailPanel.dart';
import 'package:illinois/ui/profile/ProfileLoginPhoneConfirmPanel.dart';
import 'package:illinois/ui/profile/ProfileLoginPhoneOrEmailPanel.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/auth2.dart';
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

  static BorderRadius _bottomRounding = BorderRadius.only(bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5));
  static BorderRadius _topRounding = BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5));
  static BorderRadius _allRounding = BorderRadius.all(Radius.circular(5));
  static Border _allBorder = Border.all(color: Styles().colors.surfaceAccent, width: 1);

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
      else if (code == 'linked') {
        contentList.add(_buildLinked());
      }
    }

    if (kDebugMode || (Config().configEnvironment == ConfigEnvironment.dev)) {
      contentList.add(_buildDebug());
    }

    contentList.add(Container(height: 48,),);

    contentList.add(_buildAppInfo());

    return Padding(padding: widget.margin, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList)
    );
  }

  // Connect

  Widget _buildConnect() {
    List<Widget> contentList =  [];
    contentList.add(Padding(padding: EdgeInsets.only(bottom: 2), child:
      Text(Localization().getStringEx("panel.settings.home.connect.not_logged_in.title", "Sign in to {{app_title}}").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')),
        style: Styles().textStyles.getTextStyle("widget.title.large"),
      ),
    ),);

    List<dynamic> codes = FlexUI()['authenticate.connect'] ?? [];
    for (String code in codes) {
      if (code == 'netid') {
          contentList.add(Padding(padding: EdgeInsets.symmetric(vertical: 10), child:
            _netIdDescription
          ),);
          contentList.add(RibbonButton(
            border: _allBorder,
            borderRadius: _allRounding,
            title: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.title", "Sign in with your NetID"),
            progress: _connectingNetId == true,
            onTap: _onConnectNetIdClicked
          ),);
      }
      else if (code == 'phone_or_email') {
          contentList.add(Padding(padding: EdgeInsets.symmetric(vertical: 10), child:
            RichText(text:
              TextSpan(style: Styles().textStyles.getTextStyle("widget.item.regular.thin"), children: <TextSpan>[
                TextSpan(text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.phone_or_email.description.part_1", "Don't have a NetID? "),
                  style: Styles().textStyles.getTextStyle("widget.detail.regular.fat")
                ),
                TextSpan(text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.phone_or_email.description.part_2",
                  "Sign in with your mobile phone number or email address to save your preferences and have the same experience on more than one device."
                )),
              ],),
            ),
          ),);
          contentList.add(RibbonButton(
            borderRadius: _allRounding,
            border: _allBorder,
            title: Localization().getStringEx("panel.settings.home.connect.not_logged_in.phone_or_email.title", "Sign in with mobile phone or email"),
            onTap: _onPhoneOrEmailLoginClicked
          ),);
      }
    }

    return Padding(padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:
        contentList
      ),
    );
  }

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

  Widget get _netIdDescription {
    final String appTitleMacro = '{{app_title}}';
    final String employeeMacro = '{{employee}}';
    final String universityStudentMacro = '{{university_student}}';

    String appTitleText = Localization().getStringEx('app.title', 'Illinois');
    String employeeText = Localization().getStringEx('panel.settings.verify_identity.label.connect_id.desription.employee', 'employee');
    String universityStudentText = Localization().getStringEx('panel.settings.verify_identity.label.connect_id.desription.university_student', 'university student');

    TextStyle? regularTextStyle = Styles().textStyles.getTextStyle('widget.info.regular.thin');
    TextStyle? boldTextStyle = Styles().textStyles.getTextStyle('widget.info.regular.fat');

    String descriptionText = Localization().getStringEx('panel.settings.verify_identity.label.connect_id.desription', 'Are you a $universityStudentMacro or $employeeMacro? Sign in with your NetID to see $appTitleMacro information specific to you, like your Illini ID and course schedule.').
      replaceAll(appTitleMacro, appTitleText);

    List<InlineSpan> spanList = StringUtils.split<InlineSpan>(descriptionText, macros: [employeeMacro, universityStudentMacro], builder: (String entry){
      if (entry == employeeMacro) {
        return TextSpan(text: employeeText, style: boldTextStyle);
      }
      if (entry == universityStudentMacro) {
        return TextSpan(text: universityStudentText, style: boldTextStyle);
      }
      else {
        return TextSpan(text: entry);
      }
    });
    return RichText(text:
      TextSpan(style: regularTextStyle, children: spanList)
    );
  }

  void _onPhoneOrEmailLoginClicked() {
    Analytics().logSelect(target: "Phone or Email Login");
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
      if (code == 'netid') {
        contentList.addAll(_buildConnectedNetIdLayout());
      }
      else if (code == 'phone') {
        contentList.addAll(_buildConnectedPhoneLayout());
      }
      else if (code == 'email') {
        contentList.addAll(_buildConnectedEmailLayout());
      }
    }

    return Visibility(visible: CollectionUtils.isNotEmpty(contentList), child:
      Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Styles().colors.white,
            borderRadius: BorderRadius.all(Radius.circular(4)),
            border: Border.all(color: Styles().colors.fillColorPrimary, width: 1)
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList)
        )
      )
    );
  }

  List<Widget> _buildConnectedNetIdLayout() {
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

    return contentList;
  }

  List<Widget> _buildConnectedPhoneLayout() {
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
            onTap: _onPhoneOrEmailLoginClicked));
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
    return contentList;
  }

  List<Widget> _buildConnectedEmailLayout() {
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
          onTap: _onPhoneOrEmailLoginClicked
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
    return contentList;
  }

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

  Widget _buildLinked() {
    List<Widget> contentList =  [];

    List<dynamic> codes = FlexUI()['authenticate.linked'] ?? [];
    for (String code in codes) {
      if (code == 'netid') {
        List<Widget> linkedNetIDs = _buildLinkedNetIdLayout();
        contentList.addAll(linkedNetIDs);
      }
      else if (code == 'phone') {
        List<Widget> linkedPhones = _buildLinkedPhoneLayout();
        if (linkedPhones.length > 0 && contentList.length > 0) {
          contentList.add(Container(height: 16.0,));
        }
        contentList.addAll(linkedPhones);
      }
      else if (code == 'email') {
        List<Widget> linkedEmails = _buildLinkedEmailLayout();
        if (linkedEmails.length > 0 && contentList.length > 0) {
          contentList.add(Container(height: 16.0,));
        }
        contentList.addAll(linkedEmails);
      }
    }

    contentList.add(_buildLink());

    return Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 5), child:
          Text(Localization().getStringEx("panel.settings.home.linked.title", "Alternate Sign Ins"),
            style: Styles().textStyles.getTextStyle("widget.title.large.fat"),
          ),
        ),
        ...contentList,
      ])
    );
  }

  List<Widget> _buildLinkedNetIdLayout() {
    List<Widget> contentList = [];
    List<Auth2Type> linkedTypes = Auth2().linkedOidc;

    List<dynamic> codes = FlexUI()['authenticate.linked.netid'] ?? [];
    for (Auth2Type linked in linkedTypes) {
      if (StringUtils.isNotEmpty(linked.identifier) && linked.identifier != Auth2().account?.authType?.identifier) {
        for (int index = 0; index < codes.length; index++) {
          String code = codes[index];
          BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
          if (code == 'info') {
            contentList.add(Container(
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: borderRadius, border: _allBorder),
              child: Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Text(Localization().getStringEx("panel.settings.home.linked.net_id.header", "UIN"),
                      style: Styles().textStyles.getTextStyle("widget.item.small.thin")),
                  Text(linked.identifier!, style: Styles().textStyles.getTextStyle("widget.detail.regular.fat")),
                ],)
              )
            ));
          }
        }
      }
    }

    return contentList;
  }

  List<Widget> _buildLinkedPhoneLayout() {
    List<Widget> contentList = [];
    List<Auth2Type> linkedTypes = Auth2().linkedPhone;

    List<dynamic> codes = FlexUI()['authenticate.linked.phone'] ?? [];
    for (Auth2Type linked in linkedTypes) {
      if (StringUtils.isNotEmpty(linked.identifier) && linked.identifier != Auth2().account?.authType?.identifier) {
        for (int index = 0; index < codes.length; index++) {
          String code = codes[index];
          BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
          if (code == 'info') {
            contentList.add(GestureDetector(onTap: () => _onTapAlternatePhone(linked), child:
              Container(
                width: double.infinity,
                decoration: BoxDecoration(borderRadius: borderRadius, border: _allBorder),
                child: Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      Text(Localization().getStringEx("panel.settings.home.linked.phone.header", "Phone"),
                        style: Styles().textStyles.getTextStyle("widget.item.small.thin")),
                      Text(linked.identifier!,
                        style: Styles().textStyles.getTextStyle("widget.detail.regular.fat")),
                    ],),
                    Expanded(child: Container()),
                    Styles().images.getImage('chevron-right-bold', excludeFromSemantics: true) ?? Container(),
                  ])
                )
              )
            ));
          }
        }
      }
    }

    return contentList;
  }

  List<Widget> _buildLinkedEmailLayout() {
    List<Widget> contentList = [];
    List<Auth2Type> linkedTypes = Auth2().linkedEmail;

    List<dynamic> codes = FlexUI()['authenticate.linked.email'] ?? [];
    for (Auth2Type linked in linkedTypes) {
      if (StringUtils.isNotEmpty(linked.identifier) && linked.identifier != Auth2().account?.authType?.identifier) {
        for (int index = 0; index < codes.length; index++) {
          String code = codes[index];
          BorderRadius borderRadius = _borderRadiusFromIndex(index, codes.length);
          if (code == 'info') {
            contentList.add(GestureDetector(onTap: () => _onTapAlternateEmail(linked), child:
              Container(
                width: double.infinity,
                decoration: BoxDecoration(borderRadius: borderRadius, border: _allBorder),
                child: Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      Text(Localization().getStringEx("panel.settings.home.linked.email.header", "Email"),
                        style: Styles().textStyles.getTextStyle("widget.item.small.thin")),
                      Text(linked.identifier!,
                        style: Styles().textStyles.getTextStyle("widget.detail.regular.fat")),
                    ]),
                    Expanded(child: Container()),
                    Styles().images.getImage('chevron-right-bold', excludeFromSemantics: true) ?? Container(),
                  ]),
                )
              )
            ));
          }
        }
      }
    }

    return contentList;
  }


  // Link

  Widget _buildLink() {
    List<Widget> contentList =  [];
    List<dynamic> codes = FlexUI()['authenticate.link'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      if (code == 'netid') {
        contentList.add(Padding(padding: EdgeInsets.only(top: contentList.isNotEmpty ? 2 : 0), child:
          RibbonButton(
            backgroundColor: Styles().colors.white,
            border: _allBorder,
            borderRadius: _allRounding,
            title: Localization().getStringEx("panel.settings.home.connect.not_linked.netid.title", "Add a NetID"),
            progress: (_connectingNetId == true),
            onTap: _onLinkNetIdClicked),
        ));
      }
      else if (code == 'phone') {
        contentList.add(Padding(padding: EdgeInsets.only(top: contentList.isNotEmpty ? 2 : 0), child:
          RibbonButton(
            backgroundColor: Styles().colors.white,
            border: _allBorder,
            borderRadius: _allRounding,
            title: Localization().getStringEx("panel.settings.home.connect.not_linked.phone.title", "Add a phone number"),
            onTap: () => _onLinkPhoneOrEmailClicked(SettingsLoginPhoneOrEmailMode.phone)),
        ),);
      }
      else if (code == 'email') {
        contentList.add(Padding(padding: EdgeInsets.only(top: contentList.isNotEmpty ? 2 : 0), child:
          RibbonButton(
            backgroundColor: Styles().colors.white,
            border: _allBorder,
            borderRadius: _allRounding,
            title: Localization().getStringEx("panel.settings.home.connect.not_linked.email.title", "Add an email address"),
            onTap: () => _onLinkPhoneOrEmailClicked(SettingsLoginPhoneOrEmailMode.email)),
        ),);
      }
    }

    if (contentList.length > 0) {
      return Column(children: contentList);
    }

    return Container(height: 0.0,);
  }

  void _onLinkNetIdClicked() {
    Analytics().logSelect(target: "Link Illinois NetID");
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.settings.label.offline.netid', 'Feature not available when offline.'));
    }
    else if (!FlexUI().isAuthenticationAvailable) {
      AppAlert.showAuthenticationNAMessage(context);
    }
    else {
      SettingsDialog.show(context,
        title: Localization().getStringEx("panel.settings.link.login_prompt.title", "Sign In Required"),
        message: [ TextSpan(text: Localization().getStringEx("panel.settings.link.login_prompt.description", "For security, you must sign in again to confirm it's you before adding an alternate account.")), ],
        continueTitle: Localization().getStringEx("panel.settings.link.login_prompt.confirm.title", "Sign In"),
        onContinue: (List<String> selectedValues, OnContinueProgressController progressController ) => _onLinkNetIdReloginConfirmed(progressController),
      );
    }
  }

  void _onLinkNetIdReloginConfirmed(OnContinueProgressController progressController) {
      progressController(loading: true);
      _linkVerifySignIn().then((bool? result) {
        progressController(loading: false);
        _popToMe();
        if (result == true) {
          Auth2().authenticateWithOidc(link: true).then((Auth2OidcAuthenticateResult? result) {
            if (result == Auth2OidcAuthenticateResult.failed) {
              AppAlert.showDialogResult(context, Localization().getStringEx("panel.settings.netid.link.failed", "Failed to add {{app_title}} NetID.").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')));
            } else if (result == Auth2OidcAuthenticateResult.failedAccountExist) {
              _showNetIDAccountExistsDialog();
            }
          });
        }
      });
  }

  void _showNetIDAccountExistsDialog() {
    AppAlert.showCustomDialog(context: context, contentWidget:
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text(Localization().getStringEx("panel.settings.netid.link.failed.exists", "An account is already using this NetID."),
          style: Styles().textStyles.getTextStyle("panel.settings.error.text")),
        Padding(padding: const EdgeInsets.only(top: 8.0), child:
          Text(Localization().getStringEx("panel.settings.netid.link.failed.exists.details", "1. You will need to sign in to the other account with this NetID.\n2. Go to \"Settings\" and press \"Forget all of my information\".\nYou can now use this as an alternate login."),
            style: Styles().textStyles.getTextStyle("widget.message.small")
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, true), child:
          Text(Localization().getStringEx("dialog.ok.title", "OK")),
        ),
      ]
    );
  }

  void _onLinkPhoneOrEmailClicked(SettingsLoginPhoneOrEmailMode mode) {
    Analytics().logSelect(target: "Link ${settingsLoginPhoneOrEmailModeToString(mode)}");

    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.settings.label.offline.phone_or_email', 'Feature not available when offline.'));
    }
    else if (!FlexUI().isAuthenticationAvailable) {
      AppAlert.showAuthenticationNAMessage(context);
    }
    else {
      SettingsDialog.show(context,
        title: Localization().getStringEx("panel.settings.link.login_prompt.title", "Sign In Required"),
        message: [ TextSpan(text: Localization().getStringEx("panel.settings.link.login_prompt.description", "For security, you must sign in again to confirm it's you before adding an alternate account.")), ],
        continueTitle: Localization().getStringEx("panel.settings.link.login_prompt.confirm.title", "Sign In"),
        onContinue: (List<String> selectedValues, OnContinueProgressController progressController) => _onLinkPhoneOrEmailReloginConfirmed(mode, progressController),
      );
    }
  }

  void _onLinkPhoneOrEmailReloginConfirmed(SettingsLoginPhoneOrEmailMode mode, OnContinueProgressController progressController) {
    progressController(loading: true);
    _linkVerifySignIn().then((bool? result) {
      progressController(loading: false);
      _popToMe();
      if (result == true) {
        Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) => ProfileLoginPhoneOrEmailPanel(mode: mode, link: true, onFinish: () {
          _popToMe();
        },)),);
      }
    });
  }

  Future<bool?> _linkVerifySignIn() async {
    if (Auth2().isOidcLoggedIn) {
      Auth2OidcAuthenticateResult? result = await Auth2().authenticateWithOidc();
      return (result != null) ? (result == Auth2OidcAuthenticateResult.succeeded) : null;
    }
    else if (Auth2().isEmailLoggedIn) {
      Completer<bool?> completer = Completer<bool?>();
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) =>
        ProfileLoginEmailPanel(email: Auth2().account?.authType?.identifier, state: Auth2EmailAccountState.verified, onFinish: () {
          completer.complete(true);
        },)
      ),).then((_) {
        completer.complete(null);
      });
      return completer.future;
    }
    else if (Auth2().isPhoneLoggedIn) {
      Completer<bool?> completer = Completer<bool?>();
      Auth2().authenticateWithPhone(Auth2().account?.authType?.identifier).then((Auth2PhoneRequestCodeResult result) {
        if (result == Auth2PhoneRequestCodeResult.succeeded) {
          Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) =>
            ProfileLoginPhoneConfirmPanel(phoneNumber: Auth2().account?.authType?.identifier, onFinish: () {
              completer.complete(true);
            },)
          ),).then((_) {
            completer.complete(null);
          });
        }
        else {
          AppAlert.showDialogResult(context, Localization().getStringEx("panel.onboarding2.phone_or_email.phone.failed", "Failed to send phone verification code. An unexpected error has occurred.")).then((_) {
            completer.complete(null);
          });
        }
      });
      return completer.future;
    }
    else {
      return null;
    }
  }

  void _onTapAlternateEmail(Auth2Type linked) {
    Analytics().logSelect(target: "Alternate Email");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ProfileLoginLinkedAccountPanel(linkedAccount: linked, mode: LinkAccountMode.email,)));
  }

  void _onTapAlternatePhone(Auth2Type linked) {
    Analytics().logSelect(target: "Alternate Phone");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ProfileLoginLinkedAccountPanel(linkedAccount: linked, mode: LinkAccountMode.phone,)));
  }

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

  BorderRadius _borderRadiusFromIndex(int index, int length) {
    int first = 0;
    int last = length - 1;
    if ((index == first) && (index < last)) {
      return _topRounding;
    }
    else if ((first < index) && (index == last)) {
      return _bottomRounding;
    }
    else if ((index == first) && (index == last)) {
      return _allRounding;
    }
    else {
      return BorderRadius.zero;
    }
  }
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