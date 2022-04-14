import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/home/HomeSaferTestLocationsPanel.dart';
import 'package:illinois/ui/home/HomeSaferWellnessAnswerCenterPanel.dart';
import 'package:illinois/ui/wallet/IDCardPanel.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeSaferWidget extends StatefulWidget {
  final bool? authLoading;

  HomeSaferWidget({this.authLoading});

  @override
  _HomeSaferWidgetState createState() => _HomeSaferWidgetState();
}

class _HomeSaferWidgetState extends State<HomeSaferWidget> implements NotificationsListener {

  static const String _notifyOidcAuthenticated     = "edu.illinois.rokwire.home.safer.authenticated";
  bool _authLoading = false;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      Auth2.notifyLoginFinished,
      _notifyOidcAuthenticated,
    ]);

    _authLoading = widget.authLoading ?? false;
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      if (mounted) {
        setState(() {});
      }
    }
    else if (name == _notifyOidcAuthenticated) {
      if (mounted) {
        _processOidcAuthResult(param);
      }
    }
    else if (name == Auth2.notifyLoginFinished) {
      if (_authLoading && mounted) {
        setState(() {
          _authLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionSlantHeader(
      title: Localization().getStringEx('widget.home.safer.label.title', 'Building Access'),
      titleIconAsset: 'images/campus-tools.png',
      children: _buildCommandsList(),);
  }

  List<Widget> _buildCommandsList() {
    List<Widget> contentList = <Widget>[];
    List<dynamic>? contentListCodes = FlexUI()['home.safer'];
    if (contentListCodes != null) {
      for (dynamic contentListCode in contentListCodes) {
        Widget? contentEntry;
        if (contentListCode == 'building_access') {
          contentEntry = _buildCommandEntry(
            title: Localization().getStringEx('widget.home.safer.button.building_access.title', 'Building Access'),
            description: Localization().getStringEx('widget.home.safer.button.building_access.description', 'Check your current building access.'),
            loading: _authLoading,
            onTap: _onBuildingAccess,
          );
        }
        else if (contentListCode == 'test_locations') {
          contentEntry = _buildCommandEntry(
            title: Localization().getStringEx('widget.home.safer.button.test_locations.title', 'Test Locations'),
            description: Localization().getStringEx('widget.home.safer.button.test_locations.description', 'Find test locations'),
            onTap: _onTestLocations,
          );
        }
        else if (contentListCode == 'my_mckinley') {
          contentEntry = _buildCommandEntry(
            title: Localization().getStringEx('widget.home.safer.button.my_mckinley.title', 'MyMcKinley'),
            description: Localization().getStringEx('widget.home.safer.button.my_mckinley.description', 'MyMcKinley Patient Health Portal'),
            onTap: _onMyMcKinley,
          );
        }
        else if (contentListCode == 'wellness_answer_center') {
          contentEntry = _buildCommandEntry(
            title: Localization().getStringEx('widget.home.safer.button.wellness_answer_center.title', 'Answer Center'),
            description: Localization().getStringEx('widget.home.safer.button.wellness_answer_center.description', 'Get answers to your questions.'),
            onTap: _onWellnessAnswerCenter,
          );
        }

        if (contentEntry != null) {
          if (contentList.isNotEmpty) {
            contentList.add(Container(height: 6,));
          }
          contentList.add(contentEntry);
        }
      }

    }
   return contentList;
  }

  Widget _buildCommandEntry({required String title, String? description, bool? loading, void Function()? onTap}) {
    return Semantics(label: title, hint: description, button: true, child:
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(color: Styles().colors!.surface, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))] ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Row(children: <Widget>[
              Expanded(child:
                Text(title, style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20, color: Styles().colors!.fillColorPrimary), semanticsLabel: "",),
              ),
              ((loading == true)
                ? SizedBox(height: 16, width: 16, child:
                    CircularProgressIndicator(color: Styles().colors!.fillColorSecondary, strokeWidth: 2),
                  )
                : Image.asset('images/chevron-right.png', excludeFromSemantics: true))
            ],),
            StringUtils.isNotEmpty(description)
              ? Padding(padding: EdgeInsets.only(top: 5), child:
                  Text(description!, style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.textSurface), semanticsLabel: "",),
                )
              : Container(),
        ],),),),
      );
  }

  void _onBuildingAccess() {
    if (!_authLoading) {
      Analytics().logSelect(target: 'Building Access');
      if (Connectivity().isOffline) {
        AppAlert.showOfflineMessage(context, "");
      } else if (Auth2().privacyMatch(4)) {
        _handlePrivacyMatch4();
      } else {
        _handlePrivacyBelow4();
      }
    }
  }

  void _handlePrivacyMatch4() {
    if (Auth2().isOidcLoggedIn) {
      _showModalIdCardPanel();
    } else {
      _oidcAuthenticate();
    }
  }

  void _handlePrivacyBelow4() {
    AppAlert.showCustomDialog(context: context, contentWidget: _buildPrivacyAlertContentWidget(), actions: [
      TextButton(
          child: Text(Localization().getStringEx('widget.home.safer.alert.building_access.privacy_level.4.button.label', 'Set to 4')),
          onPressed: () => _increasePrivacyLevelAndAuthenticate(4)),
      TextButton(
          child: Text(Localization().getStringEx('widget.home.safer.alert.building_access.privacy_level.5.button.label', 'Set to 5')),
          onPressed: () => _increasePrivacyLevelAndAuthenticate(5)),
      TextButton(child: Text(Localization().getStringEx('dialog.no.title', 'No')), onPressed: _doNotIncreasePrivacyLevel)
    ]);
  }

  Widget _buildPrivacyAlertContentWidget() {
    int userPrivacyLevel = Auth2().prefs?.privacyLevel ?? 0;
    String privacyMsg1 =
        Localization().getStringEx('widget.home.safer.alert.building_access.privacy_update.msg1', 'With your privacy level ');
    String privacyMsg2 = Localization().getStringEx('widget.home.safer.alert.building_access.privacy_update.msg2',
        ' , you will have to sign in everytime to show your building access status. Do you want to change your privacy level to 4 or 5 so you only have to sign in once?');
    return RichText(
        text: TextSpan(
            style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.bold),
            children: [
          TextSpan(text: privacyMsg1),
          WidgetSpan(alignment: PlaceholderAlignment.middle, child: _buildPrivacyLevelWidget(userPrivacyLevel)),
          TextSpan(text: privacyMsg2)
        ]));
  }

  Widget _buildPrivacyLevelWidget(int privacyLevel) {
    return Container(
        height: 40,
        width: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 2),
          color: Styles().colors!.white,
          borderRadius: BorderRadius.all(Radius.circular(100)),
        ),
        child: Container(
            height: 32,
            width: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Styles().colors!.fillColorSecondary!, width: 2),
              color: Styles().colors!.white,
              borderRadius: BorderRadius.all(Radius.circular(100)),
            ),
            child: Text(privacyLevel.toString(),
                style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 18, color: Styles().colors!.fillColorPrimary))));
  }

  void _increasePrivacyLevelAndAuthenticate(int privacyLevel) {
    Analytics().logSelect(target: 'Yes');
    Navigator.of(context).pop();
    _oidcAuthenticate(privacyLevel: privacyLevel); // User is allowed, so increase privacy level to privacyLevel
  }

  void _doNotIncreasePrivacyLevel() {
    Analytics().logSelect(target: 'No');
    Navigator.of(context).pop();
    if (StringUtils.isNotEmpty(Config().iCardBoardingPassUrl)) {
      launch(Config().iCardBoardingPassUrl!);
    }
  }

  void _oidcAuthenticate({int? privacyLevel}) {
    if (mounted) {
      setState(() {
        _authLoading = true;
      });
    }
    if (privacyLevel != null) {
      Auth2().prefs?.privacyLevel = privacyLevel;
    }
    Auth2().authenticateWithOidc().then((Auth2OidcAuthenticateResult? result) {
      if (mounted) {
        _processOidcAuthResult(result);
        setState(() {
          _authLoading = false;
        });
      } else {
        NotificationService().notify(_notifyOidcAuthenticated, result);
      }
    });
  }

  void _processOidcAuthResult(Auth2OidcAuthenticateResult? result) {
    if (result == Auth2OidcAuthenticateResult.succeeded) {
      if (_authLoading) {
        _authLoading = false;
        if (mounted) {
          setState(() {});
        }
      }
      _showModalIdCardPanel();
    } else if (result != null) {
      AppAlert.showDialogResult(
          context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
    }
  }

  void _onTestLocations() {
    Analytics().logSelect(target: 'Locations');
    Navigator.push(context, CupertinoPageRoute(
      builder: (context) => HomeSaferTestLocationsPanel()
    ));
  }

  void _onMyMcKinley() {
    Analytics().logSelect(target: 'MyMcKinley');
    if (StringUtils.isNotEmpty(Config().saferMcKinley['url'])) {
      launch(Config().saferMcKinley['url']);
    }
  }

  void _onWellnessAnswerCenter() {
    Analytics().logSelect(target: 'Answer Center');
    Navigator.push(context, CupertinoPageRoute(
      builder: (context) => HomeSaferWellnessAnswerCenterPanel()
    ));
  }

  void _showModalIdCardPanel() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        builder: (context) {
          return IDCardPanel();
        });
  }
}
