
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/service/FirebaseMessaging.dart';
import 'package:neom/service/FlexUI.dart';
import 'package:neom/ui/profile/ProfileHomePanel.dart';
import 'package:neom/ui/profile/ProfileLoginLinkedAccountPanel.dart';
import 'package:neom/ui/profile/ProfileLoginCodePanel.dart';
import 'package:neom/ui/profile/ProfileLoginPhoneOrEmailPanel.dart';
import 'package:neom/ui/settings/SettingsWidgets.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
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

class _ProfileLoginPageState extends State<ProfileLoginPage> implements NotificationsListener {

  static BorderRadius _bottomRounding = BorderRadius.only(bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5));
  static BorderRadius _topRounding = BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5));
  static BorderRadius _allRounding = BorderRadius.all(Radius.circular(5));
  static Border _allBorder = Border.all(color: Styles().colors.surfaceAccent, width: 1);

  bool _connectingNetId = false;

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

    // if (kDebugMode || (Config().configEnvironment == ConfigEnvironment.dev)) {
    //   contentList.add(_buildDebug());
    // }

    contentList.add(Container(height: 48,),);

    contentList.add(_buildAppInfo());

    return Padding(padding: widget.margin, child:
      Column(crossAxisAlignment: CrossAxisAlignment.center, children: contentList)
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
            RichText(text:
              TextSpan(style: Styles().textStyles.getTextStyle("widget.item.regular.thin"), children: <TextSpan>[
                TextSpan(text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.description.part_1", "Are you a ")),
                TextSpan(text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.description.part_2", "university student"),
                  style: Styles().textStyles.getTextStyle("widget.detail.regular.fat")),
                TextSpan(text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.description.part_3", " or ")),
                TextSpan(text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.description.part_4", "employee"),
                  style: Styles().textStyles.getTextStyle("widget.detail.regular.fat")),
                TextSpan(text: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.description.part_5",
                      "? Sign in with your NetID to see {{app_title}} information specific to you, like your Illini Cash and meal plan.").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')))
              ],),
            )
          ),);
          contentList.add(RibbonButton(
            backgroundColor: Styles().colors.gradientColorPrimary,
            border: _allBorder,
            borderRadius: _allRounding,
            label: Localization().getStringEx("panel.settings.home.connect.not_logged_in.netid.title", "Sign in with your NetID"),
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
            backgroundColor: Styles().colors.gradientColorPrimary,
            borderRadius: _allRounding,
            border: _allBorder,
            label: Localization().getStringEx("panel.settings.home.connect.not_logged_in.phone_or_email.title", "Sign in with mobile phone or email"),
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
    if (_connectingNetId != true) {
      setState(() { _connectingNetId = true; });
      Auth2().authenticateWithOidc().then((Auth2OidcAuthenticateResult? result) {
        if (mounted) {
          setState(() { _connectingNetId = false; });
          if (result?.status != Auth2OidcAuthenticateResultStatus.succeeded) {
            AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
          }
        }
      });
    }
  }

  void _onPhoneOrEmailLoginClicked() {
    Analytics().logSelect(target: "Phone or Email Login");
    if (Connectivity().isNotOffline) {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) => ProfileLoginPhoneOrEmailPanel(onFinish: () {
        _popToMe();
      },),),);
    } else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.settings.label.offline.phone_or_email', 'Feature not available when offline.'));
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
    //TODO: where should all account identifiers be listed?
    List<Widget> contentList =  [];

    List<dynamic> codes = FlexUI()['authenticate.connected'] ?? [];
    for (String code in codes) {
      if (code == 'netid') {
        contentList.addAll(_buildConnectedNetIdLayout());
      }
      else if (code == 'code') {
        contentList.addAll(_buildConnectedCodeLayout());
      }
      else if (code == 'password') {
        contentList.addAll(_buildConnectedPasswordLayout());
      }
      else if (code == 'passkey') {
        contentList.addAll(_buildConnectedPasskeyLayout());
      }
    }

    return Visibility(visible: CollectionUtils.isNotEmpty(contentList), child:
      Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Styles().colors.gradientColorPrimary,
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
            style: Styles().textStyles.getTextStyle("widget.detail.regular.extra_fat")),
          Padding(padding: EdgeInsets.only(top: 3), child: Text(Auth2().fullName ?? "",
            style: Styles().textStyles.getTextStyle("widget.detail.large.fat"))),
        ]));
      }
      else if (code == 'disconnect') {
        contentList.add(Padding(padding: EdgeInsets.only(top: 12), child:
          RoundedButton(
            label: Localization().getStringEx("panel.settings.home.net_id.button.disconnect", "Sign Out"),
            textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
            backgroundColor: Styles().colors.gradientColorPrimary,
            contentWeight: 0.45,
            conentAlignment: MainAxisAlignment.start,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            onTap: _onDisconnectClicked
          )
        ));
      }
    }

    return contentList;
  }

  List<Widget> _buildConnectedCodeLayout() {
    List<Widget> contentList = [];

    String fullName = Auth2().fullName ?? "";
    bool hasFullName = StringUtils.isNotEmpty(fullName);

    List<dynamic> codes = FlexUI()['authenticate.connected.code'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      if (code == 'info') {
        contentList.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(Localization().getStringEx("panel.settings.home.code_login.message", "Signed in with"),
              style: Styles().textStyles.getTextStyle("widget.detail.regular.extra_fat")),
          Visibility(visible: hasFullName, child:
            Padding(padding: EdgeInsets.only(top: 3), child:
              Text(fullName, style: Styles().textStyles.getTextStyle("widget.detail.large.fat"))
            )
          ),
          Padding(padding: EdgeInsets.only(top: 3), child:
            Text(Auth2().phones.isNotEmpty ? Auth2().phones.first : (Auth2().emails.isNotEmpty ? Auth2().emails.first : ""), style: Styles().textStyles.getTextStyle("widget.detail.large.fat"))
          )
        ]));
      }
      else if (code == 'verify') {
        contentList.add(RibbonButton(
            backgroundColor: Styles().colors.gradientColorPrimary,
            border: _allBorder,
            borderRadius: _allRounding,
            label: Localization().getStringEx("panel.settings.home.code_login.button.connect", "Verify Code"),
            onTap: _onPhoneOrEmailLoginClicked));
      }
      else if (code == 'disconnect') {
        contentList.add(Padding(padding: EdgeInsets.only(top: 12), child:
          RoundedButton(
            label: Localization().getStringEx("panel.settings.home.code_login.button.disconnect", "Sign Out"),
            textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
            backgroundColor: Styles().colors.fillColorSecondary,
            contentWeight: 0.45,
            conentAlignment: MainAxisAlignment.start,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            onTap: _onDisconnectClicked
          )
        ));
      }
    }
    return contentList;
  }

  List<Widget> _buildConnectedPasswordLayout() {
    List<Widget> contentList = [];

    String fullName = Auth2().fullName ?? "";
    bool hasFullName = StringUtils.isNotEmpty(fullName);

    List<dynamic> codes = FlexUI()['authenticate.connected.password'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      if (code == 'info') {
        contentList.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(Localization().getStringEx("panel.settings.home.password_login.message", "Signed in with password"),
              style: Styles().textStyles.getTextStyle("widget.detail.regular.extra_fat")),
          Visibility(visible: hasFullName, child:
            Padding(padding: EdgeInsets.only(top: 3), child:
              Text(fullName, style: Styles().textStyles.getTextStyle("widget.detail.large.fat"))
            )
          ),
          Padding(padding: EdgeInsets.only(top: 3), child:
            Text(Auth2().emails.isNotEmpty ? Auth2().emails.first : "", style:  Styles().textStyles.getTextStyle("widget.detail.large.fat"))
          )
        ]));
      }
      else if (code == 'login') {
        contentList.add(RibbonButton(
          backgroundColor: Styles().colors.gradientColorPrimary,
          border: _allBorder,
          borderRadius: _allRounding,
          label: Localization().getStringEx("panel.settings.home.password_login.button.connect", "Login With Password"),
          onTap: _onPhoneOrEmailLoginClicked
        ));
      }
      else if (code == 'disconnect') {
        contentList.add(Padding(padding: EdgeInsets.only(top: 12), child:
          RoundedButton(
            label: Localization().getStringEx("panel.settings.home.password_login.button.disconnect", "Sign Out"),
            textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
            backgroundColor: Styles().colors.fillColorSecondary,
            contentWeight: 0.45,
            conentAlignment: MainAxisAlignment.start,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            onTap: _onDisconnectClicked
          )
        ));
      }
    }
    return contentList;
  }

  List<Widget> _buildConnectedPasskeyLayout() {
    List<Widget> contentList = [];

    String fullName = Auth2().fullName ?? "";
    bool hasFullName = StringUtils.isNotEmpty(fullName);

    List<dynamic> codes = FlexUI()['authenticate.connected.passkey'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      if (code == 'info') {
        contentList.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(Localization().getStringEx("panel.settings.home.passkey_login.message", "Signed in with passkey"),
              style: Styles().textStyles.getTextStyle("widget.detail.light.regular.extra_fat")),
          Visibility(visible: hasFullName, child:
            Padding(padding: EdgeInsets.only(top: 3), child:
              Text(fullName, style: Styles().textStyles.getTextStyle("widget.detail.large.fat"))
            )
          ),
          Padding(padding: EdgeInsets.only(top: 3), child:
            Text(Auth2().phones.isNotEmpty ? Auth2().phones.first : (Auth2().emails.isNotEmpty ? Auth2().emails.first : ""), style:  Styles().textStyles.getTextStyle("widget.detail.large.fat"))
          )
        ]));
      }
      else if (code == 'login') {
        contentList.add(RibbonButton(
            backgroundColor: Styles().colors.gradientColorPrimary,
            border: _allBorder,
            borderRadius: _allRounding,
            label: Localization().getStringEx("panel.settings.home.passkey_login.button.connect", "Login With Passkey"),
            //TODO onTap: _onPhoneOrEmailLoginClicked
        ));
      }
      else if (code == 'disconnect') {
        contentList.add(Padding(padding: EdgeInsets.only(top: 12), child:
          RoundedButton(
              label: Localization().getStringEx("panel.settings.home.passkey_login.button.disconnect", "Sign Out"),
              textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
              backgroundColor: Styles().colors.fillColorSecondary,
              contentWeight: 0.45,
              conentAlignment: MainAxisAlignment.start,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              onTap: _onDisconnectClicked
          )
        ));
      }
    }
    return contentList;
  }

  void _onDisconnectClicked() {
    if (Auth2().isOidcLoggedIn) {
      Analytics().logSelect(target: "Disconnect netId");
    } else if (Auth2().isCodeLoggedIn) {
      Analytics().logSelect(target: "Disconnect code");
    } else if (Auth2().isPasswordLoggedIn) {
      Analytics().logSelect(target: "Disconnect password");
    } else if (Auth2().isPasskeyLoggedIn) {
      Analytics().logSelect(target: "Disconnect passkey");
    }
    showDialog(context: context, builder: (context) => _buildLogoutDialog(context));
  }

  Widget _buildLogoutDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Styles().colors.background,
      child: Padding(padding: EdgeInsets.all(18), child:
        Container(
          constraints: BoxConstraints(maxWidth: Config().webContentMaxWidth),
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Text(Localization().getStringEx("panel.settings.home.logout.title", "{{app_title}}").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')),
              style: Styles().textStyles.getTextStyle("widget.title.light.extra_large"),
            ),
            Padding(padding: EdgeInsets.symmetric(vertical: 26), child:
              Text(Localization().getStringEx("panel.settings.home.logout.message", _promptEn), textAlign: TextAlign.left,
                style: Styles().textStyles.getTextStyle("widget.message.light.medium")
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
              TextButton(onPressed: _onConfirmLogout, child:
                Text(Localization().getStringEx("panel.settings.home.logout.button.yes", "Yes"))
              ),
              TextButton(onPressed: _onRejectLogout, child:
                Text(Localization().getStringEx("panel.settings.home.logout.no", "No"))
              )
            ],),
          ],),
        ),
      ),
    );
  }

  static const String _promptEn = 'Are you sure you want to sign out?';

  void _onConfirmLogout() {
    Analytics().logAlert(text: _promptEn, selection: "Yes");
    Navigator.pop(context);
    Auth2().logout();
  }

  void _onRejectLogout() {
    Analytics().logAlert(text: _promptEn, selection: "No");
    Navigator.pop(context);
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
            style: Styles().textStyles.getTextStyle("widget.title.light.large.fat"),
          ),
        ),
        ...contentList,
      ])
    );
  }

  List<Widget> _buildLinkedNetIdLayout() {
    List<Widget> contentList = [];
    List<Auth2Identifier> linkedIdentifiers = Auth2().linkedOidcIdentifiers;

    List<dynamic> codes = FlexUI()['authenticate.linked.netid'] ?? [];
    for (Auth2Identifier linked in linkedIdentifiers) {
      if (StringUtils.isNotEmpty(linked.identifier) && linked.identifier != Auth2().account?.identifier?.identifier) {
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
    List<Auth2Identifier> linkedIdentifiers = Auth2().linkedPhone;

    List<dynamic> codes = FlexUI()['authenticate.linked.phone'] ?? [];
    for (Auth2Identifier linked in linkedIdentifiers) {
      if (StringUtils.isNotEmpty(linked.identifier) && linked.identifier != Auth2().account?.identifier?.identifier) {
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
    List<Auth2Identifier> linkedIdentifiers = Auth2().linkedEmail;

    List<dynamic> codes = FlexUI()['authenticate.linked.email'] ?? [];
    for (Auth2Identifier linked in linkedIdentifiers) {
      if (StringUtils.isNotEmpty(linked.identifier) && linked.identifier != Auth2().account?.identifier?.identifier) {
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
    //TODO: Add option to link passkey in case user deletes from device? ("Passkey recovery") -> can we tell on backend which passkey the user may have deleted from device?
    List<Widget> contentList =  [];
    List<dynamic> codes = FlexUI()['authenticate.link'] ?? [];
    for (int index = 0; index < codes.length; index++) {
      String code = codes[index];
      if (code == 'netid') {
        contentList.add(Padding(padding: EdgeInsets.only(top: contentList.isNotEmpty ? 2 : 0), child:
          RibbonButton(
            backgroundColor: Styles().colors.gradientColorPrimary,
            border: _allBorder,
            borderRadius: _allRounding,
            label: Localization().getStringEx("panel.settings.home.connect.not_linked.netid.title", "Add a NetID"),
            progress: (_connectingNetId == true),
            onTap: _onLinkNetIdClicked),
        ));
      }
      else if (code == 'phone') {
        contentList.add(Padding(padding: EdgeInsets.only(top: contentList.isNotEmpty ? 2 : 0), child:
          RibbonButton(
            backgroundColor: Styles().colors.gradientColorPrimary,
            textColor: Styles().colors.textLight,
            border: _allBorder,
            borderRadius: _allRounding,
            label: Localization().getStringEx("panel.settings.home.connect.not_linked.phone.title", "Add a phone number"),
            onTap: () => _onLinkPhoneOrEmailClicked(SettingsLoginPhoneOrEmailMode.phone)),
        ),);
      }
      else if (code == 'email') {
        contentList.add(Padding(padding: EdgeInsets.only(top: contentList.isNotEmpty ? 2 : 0), child:
          RibbonButton(
            backgroundColor: Styles().colors.gradientColorPrimary,
            textColor: Styles().colors.textLight,
            border: _allBorder,
            borderRadius: _allRounding,
            label: Localization().getStringEx("panel.settings.home.connect.not_linked.email.title", "Add an email address"),
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
    if (Connectivity().isNotOffline) {
      SettingsDialog.show(context,
        title: Localization().getStringEx("panel.settings.link.login_prompt.title", "Sign In Required"),
        message: [ TextSpan(text: Localization().getStringEx("panel.settings.link.login_prompt.description", "For security, you must sign in again to confirm it's you before adding an alternate account.")), ],
        continueTitle: Localization().getStringEx("panel.settings.link.login_prompt.confirm.title", "Sign In"),
        onContinue: (List<String> selectedValues, OnContinueProgressController progressController ) => _onLinkNetIdReloginConfirmed(progressController),
      );
    } else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.settings.label.offline.netid', 'Feature not available when offline.'));
    }
  }

  void _onLinkNetIdReloginConfirmed(OnContinueProgressController progressController) {
      progressController(loading: true);
      _linkVerifySignIn().then((bool? result) {
        progressController(loading: false);
        _popToMe();
        if (result == true) {
          Auth2().authenticateWithOidc(link: true).then((Auth2OidcAuthenticateResult? result) {
            if (result?.status == Auth2OidcAuthenticateResultStatus.failed) {
              AppAlert.showDialogResult(context, Localization().getStringEx("panel.settings.netid.link.failed", "Failed to add {{app_title}} NetID.").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')));
            } else if (result?.status == Auth2OidcAuthenticateResultStatus.failedAccountExist) {
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

    if (Connectivity().isNotOffline) {
      SettingsDialog.show(context,
        title: Localization().getStringEx("panel.settings.link.login_prompt.title", "Sign In Required"),
        message: [ TextSpan(text: Localization().getStringEx("panel.settings.link.login_prompt.description", "For security, you must sign in again to confirm it's you before adding an alternate account.")), ],
        continueTitle: Localization().getStringEx("panel.settings.link.login_prompt.confirm.title", "Sign In"),
        onContinue: (List<String> selectedValues, OnContinueProgressController progressController) => _onLinkPhoneOrEmailReloginConfirmed(mode, progressController),
      );
    } else {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.settings.label.offline.phone_or_email', 'Feature not available when offline.'));
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
      return (result != null) ? (result.status == Auth2OidcAuthenticateResultStatus.succeeded) : null;
    }
    else if (Auth2().isPasskeyLoggedIn) {
      Auth2PasskeySignInResult result = await Auth2().authenticateWithPasskey();
      return result.status == Auth2PasskeySignInResultStatus.succeeded;
    }
    else if (Auth2().isCodeLoggedIn) {
      Completer<bool?> completer = Completer<bool?>();
      Auth2().authenticateWithCode(Auth2().account?.identifier?.identifier).then((Auth2RequestCodeResult result) {
        if (result == Auth2RequestCodeResult.succeeded) {
          Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(), builder: (context) =>
            ProfileLoginCodePanel(identifier: Auth2().account?.identifier?.identifier, onFinish: () {
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

  void _onTapAlternateEmail(Auth2Identifier linked) {
    Analytics().logSelect(target: "Alternate Email");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ProfileLoginLinkedAccountPanel(linkedIdentifier: linked, mode: LinkAccountMode.email,)));
  }

  void _onTapAlternatePhone(Auth2Identifier linked) {
    Analytics().logSelect(target: "Alternate Phone");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ProfileLoginLinkedAccountPanel(linkedIdentifier: linked, mode: LinkAccountMode.phone,)));
  }

  // Debug

  // Widget _buildDebug() => Padding(padding: EdgeInsets.only(top: 24), child:
  //   RibbonButton(
  //     backgroundColor: Styles().colors.gradientColorPrimary,
  //     border: _allBorder,
  //     borderRadius: _allRounding,
  //     textColor: Styles().colors.textLight,
  //     label: Localization().getStringEx("panel.profile_info.button.debug.title", "Debug"),
  //     onTap: _onDebugClicked)
  //   );

  // void _onDebugClicked() {
  //   Analytics().logSelect(target: "Debug");
  //   Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugHomePanel()));
  // }

  // App Info

  Widget _buildAppInfo() => Column(children: [
    Container(
      padding: const EdgeInsets.all(6),
      child: SizedBox(width: 51, height: 51, child:
        Styles().images.getImage('university-logo-oval-white', fit: BoxFit.contain),
      ),
    ),
    Padding(padding: const EdgeInsets.only(top: 8)),
    RichText(text:
      TextSpan(style: Styles().textStyles.getTextStyle("widget.item.light.regular.thin"), children:[
        TextSpan(text: Localization().getStringEx('panel.settings.home.version.info.label', '{{app_title}} App Version:').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')),),
        TextSpan(text:  " $_appVersion", style : Styles().textStyles.getTextStyle("widget.item.light.regular.fat")),
      ])
    ),
    // Text(_copyrightText, textAlign: TextAlign.center, style:  Styles().textStyles.getTextStyle("widget.item.light.regular.thin"))
  ],);

  String get _appVersion => Config().appVersion ?? '';

  // String get _copyrightText => Localization().getStringEx('panel.settings.home.copyright.text', 'Copyright © {{COPYRIGHT_YEAR}} University of Illinois Board of Trustees')
  //   .replaceAll('{{COPYRIGHT_YEAR}}', DateFormat('yyyy').format(DateTime.now()));

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