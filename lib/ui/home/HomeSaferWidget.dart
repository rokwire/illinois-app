import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/home/HomePanel.dart';
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

  static const String notifyNeedsVisiblity = "edu.illinois.rokwire.home.safer.needs.visibility";
  
  final String? favoriteId;
  final StreamController<void>? refreshController;
  final HomeScrollableDragging? scrollableDragging;

  HomeSaferWidget({Key? key, this.favoriteId, this.refreshController, this.scrollableDragging}) : super(key: key);

  @override
  _HomeSaferWidgetState createState() => _HomeSaferWidgetState();
}

class _HomeSaferWidgetState extends State<HomeSaferWidget> implements NotificationsListener {

  bool _buildingAccessAuthLoading = false;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
    ]);

    if (widget.refreshController != null) {
      widget.refreshController!.stream.listen((_) {
      });
    }
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
            loading: _buildingAccessAuthLoading,
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
    if (!_buildingAccessAuthLoading) {
      Analytics().logSelect(target: 'Building Access');
      if (Connectivity().isOffline) {
        AppAlert.showOfflineMessage(context, "");
      } else if (!Auth2().privacyMatch(4)) {
        _onBuildingAccessPrivacyDoNotMatch();
      } else {
        _onBuildingAccessPrivacyMatch();
      }
    }
  }

  void _onBuildingAccessPrivacyDoNotMatch() {
    AppAlert.showCustomDialog(context: context, contentWidget: _buildPrivacyAlertWidget(), actions: [
      TextButton(
          child: Text(Localization().getStringEx('widget.home.safer.alert.building_access.privacy_level.4.button.label', 'Set to 4')),
          onPressed: () => _buildingAccessIncreasePrivacyLevelAndAuthentiate(4)),
      TextButton(
          child: Text(Localization().getStringEx('widget.home.safer.alert.building_access.privacy_level.5.button.label', 'Set to 5')),
          onPressed: () => _buildingAccessIncreasePrivacyLevelAndAuthentiate(5)),
      TextButton(child: Text(Localization().getStringEx('dialog.no.title', 'No')), onPressed: _buildingAccessNotIncreasePrivacyLevel)
    ]);
  }

  Widget _buildPrivacyAlertWidget() {
    final String iconMacro = '{{privacy_level_icon}}';
    String privacyMsg = Localization().getStringEx('widget.home.safer.alert.building_access.privacy_update.msg', 'With your privacy level at $iconMacro , you will have to sign in every time to show your building access status. Do you want to change your privacy level to 4 or 5 so you only have to sign in once?');
    int iconMacroPosition = privacyMsg.indexOf(iconMacro);
    String privacyMsgStart = (0 < iconMacroPosition) ? privacyMsg.substring(0, iconMacroPosition) : '';
    String privacyMsgEnd = ((0 < iconMacroPosition) && (iconMacroPosition < privacyMsg.length)) ? privacyMsg.substring(iconMacroPosition + iconMacro.length) : '';
    return RichText(text: TextSpan(style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.bold), children: [
      TextSpan(text: privacyMsgStart),
      WidgetSpan(alignment: PlaceholderAlignment.middle, child: _buildPrivacyLevelWidget()),
      TextSpan(text: privacyMsgEnd)
    ]));
  }

  Widget _buildPrivacyLevelWidget() {
    String privacyLevel = Auth2().prefs?.privacyLevel?.toString() ?? '';
    return Container(height: 40, width: 40, alignment: Alignment.center, decoration: BoxDecoration( border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 2), color: Styles().colors!.white, borderRadius: BorderRadius.all(Radius.circular(100)),), child:
      Container(height: 32, width: 32, alignment: Alignment.center, decoration: BoxDecoration( border: Border.all(color: Styles().colors!.fillColorSecondary!, width: 2), color: Styles().colors!.white, borderRadius: BorderRadius.all(Radius.circular(100)), ), child:
        Text(privacyLevel.toString(), style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 18, color: Styles().colors!.fillColorPrimary))));
  }

  void _buildingAccessNotIncreasePrivacyLevel() {
    Analytics().logSelect(target: 'No');
    Navigator.of(context).pop();
    if (StringUtils.isNotEmpty(Config().iCardBoardingPassUrl)) {
      launch(Config().iCardBoardingPassUrl!);
    }
  }

  void _buildingAccessIncreasePrivacyLevelAndAuthentiate(int privacyLevel) {
    Analytics().logSelect(target: 'Yes');
    Navigator.of(context).pop();
    Auth2().prefs?.privacyLevel = privacyLevel;
    Future.delayed(Duration(milliseconds: 300), () {
      NotificationService().notify(HomeSaferWidget.notifyNeedsVisiblity);
      _onBuildingAccessPrivacyMatch();
    });
  }

  void _onBuildingAccessPrivacyMatch() {
    if (Auth2().isOidcLoggedIn) {
      _showBuildingAccessPanel();
    } else {
      _buildingAccessOidcAuthenticate();
    }
  }

  void _buildingAccessOidcAuthenticate() {
    if (mounted) {
      setState(() { _buildingAccessAuthLoading = true; });
    }
    Auth2().authenticateWithOidc().then((Auth2OidcAuthenticateResult? result) {
//    Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          NotificationService().notify(HomeSaferWidget.notifyNeedsVisiblity);
          setState(() { _buildingAccessAuthLoading = false; });
          _buildingAccessOidcDidAuthenticate(result);
        }
//    });
    });
  }

  void _buildingAccessOidcDidAuthenticate(Auth2OidcAuthenticateResult? result) {
    if (result == Auth2OidcAuthenticateResult.succeeded) {
      _showBuildingAccessPanel();
    } else if (result != null) {
      AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
    }
  }

  void _showBuildingAccessPanel() {
    showModalBottomSheet(context: context,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        builder: (context) {
          return IDCardPanel();
        });
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
}
