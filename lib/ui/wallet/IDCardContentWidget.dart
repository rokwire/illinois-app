/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:http/http.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Transportation.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';

class IDCardContentWidget extends StatefulWidget {
  IDCardContentWidget();

  _IDCardContentWidgetState createState() => _IDCardContentWidgetState();
}

class _IDCardContentWidgetState extends State<IDCardContentWidget>
  with SingleTickerProviderStateMixin
  implements NotificationsListener {

  final double _headingH1 = 200;
  final double _headingH2 = 80;
  final double _photoSize = 240;
  final double _illiniIconSize = 64;
  final double _buildingAccessIconSize = 84;

  Color? _activeColor;
  Color get _activeBorderColor{ return _activeColor ?? Styles().colors!.fillColorSecondary!; }
  Color get _activeHeadingColor{ return _activeColor ?? Styles().colors!.fillColorPrimary!; }

  MemoryImage? _photoImage;
  bool? _buildingAccess;
  DateTime? _buildingAccessTime;
  late bool _loadingBuildingAccess;
  late AnimationController _animationController;

  List<dynamic>? _mobileAccessKeys;
  bool _mobileAccessKeysLoading = false;
  PageController? _mobileKeysPageController;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Auth2.notifyCardChanged,
      FlexUI.notifyChanged,
    ]);
    
    _animationController = AnimationController(duration: Duration(milliseconds: 1500), lowerBound: 0, upperBound: 2 * math.pi, animationBehavior: AnimationBehavior.preserve, vsync: this)
    ..addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _animationController.repeat();

    _loadActiveColor().then((Color? color){
      if (mounted) {
        setState(() {
          _activeColor = color;
        });
      }
    });
    
    _loadAsyncPhotoImage().then((MemoryImage? photoImage){
      if (mounted) {
        setState(() {
          _photoImage = photoImage;
        });
      }
    });

    _loadingBuildingAccess = true;
    _loadBuildingAccess().then((bool? buildingAccess) {
      if (mounted) {
        setState(() {
          _buildingAccess = buildingAccess;
          _buildingAccessTime = DateTime.now();
          _loadingBuildingAccess = false;
        });
      }
      }).then((_){
        if (mounted) {
          _checkNetIdStatus();
        }
      });

      _loadMobileAccessKey();

    // Auth2().updateAuthCard();
  }

  Future<MemoryImage?> _loadAsyncPhotoImage() async{
    Uint8List? photoBytes = await  Auth2().authCard?.photoBytes;
    return CollectionUtils.isNotEmpty(photoBytes) ? MemoryImage(photoBytes!) : null;
  }

  Future<Color?> _loadActiveColor() async{
    String? deviceId = Auth2().deviceId;
    return await Transportation().loadBusColor(deviceId: deviceId, userId: Auth2().accountId);
  }

  Future<bool?> _loadBuildingAccess() async {
    if (_hasBuildingAccess && StringUtils.isNotEmpty(Config().padaapiUrl) && StringUtils.isNotEmpty(Config().padaapiApiKey) && StringUtils.isNotEmpty(Auth2().authCard?.uin)) {
      String url = "${Config().padaapiUrl}/access/${Auth2().authCard?.uin}";
      Map<String, String> headers = {
        HttpHeaders.acceptHeader : 'application/json',
        'x-api-key': Config().padaapiApiKey!
      };
      Response? response = await Network().get(url, headers: headers);
      Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
      return (responseJson != null) ? JsonUtils.boolValue(responseJson['allowAccess']) : null;
    }
    return null;
  }

  Future<void> _loadMobileAccessKey() async {
    if (Auth2().isLoggedIn) {
      _setMobileAccessKeysLoading(true);
      NativeCommunicator().getMobileAccessKeys().then((List<dynamic>? mobileAccessKeys) {
        _mobileAccessKeys = mobileAccessKeys;
        _setMobileAccessKeysLoading(false);
      });
    } else {
      setStateIfMounted(() {
        _mobileAccessKeys = null;
      });
    }
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _animationController.dispose();
    _mobileKeysPageController?.dispose();
    super.dispose();
  }

  // NotificationsListener
  
  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyCardChanged) {
      _loadAsyncPhotoImage().then((MemoryImage? photoImage){
        if (mounted) {
          setState(() {
            _photoImage = photoImage;
          });
        }
      });
    }
    else if (name == FlexUI.notifyChanged) {
        if (mounted) {
          setState(() {
          });
        }
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Container(child:
      Stack(children: <Widget>[
          
          Column(children: <Widget>[
            Container(height: _headingH1, color: _activeHeadingColor,),
            Container(height: _headingH2, color: _activeHeadingColor, child: CustomPaint(painter: TrianglePainter(painterColor: Colors.white), child: Container(),),),
          ],),
          
          (Auth2().authCard != null) ? _buildCardContent() : Container(),
        ],
      
    ),);
  }

  Widget _buildCardContent() {
    
    String? cardExpires = Localization().getStringEx('widget.card.label.expires.title', 'Expires');
    String? expirationDate = Auth2().authCard?.expirationDate;
    String cardExpiresText = (0 < (expirationDate?.length ?? 0)) ? "$cardExpires $expirationDate" : "";
    String roleDisplayString = (Auth2().authCard?.needsUpdate ?? false) ? Localization().getStringEx("widget.id_card.label.update_i_card", "Update your i-card") : (Auth2().authCard?.role ?? "");

    Widget? buildingAccessIcon;
    String? buildingAccessStatus;
    String? buildingAccessTime = AppDateTime().formatDateTime(_buildingAccessTime, format: 'MMM dd, yyyy HH:mm a');
    double buildingAccessStatusHeight = 24;
    double qrCodeImageSize = _buildingAccessIconSize + buildingAccessStatusHeight - 2;
    bool hasQrCode = (0 < (_userQRCodeContent?.length ?? 0));

    DateTime? expirationDateTimeUtc = Auth2().authCard?.expirationDateTimeUtc;
    bool cardExpired = (expirationDateTimeUtc != null) && DateTime.now().toUtc().isAfter(expirationDateTimeUtc);
    bool showQRCode = !cardExpired;

    if (_loadingBuildingAccess) {
      buildingAccessIcon = Container(width: _buildingAccessIconSize, height: _buildingAccessIconSize, child:
        Align(alignment: Alignment.center, child: 
          SizedBox(height: 42, width: 42, child:
            CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), )
          )
        ,),);
    }
    else if (_buildingAccess != null) {
      buildingAccessIcon = Styles().images?.getImage((_buildingAccess == true) ? 'building-access-granted' : 'building-access-denied', width: _buildingAccessIconSize, height: _buildingAccessIconSize, semanticLabel: "building access ${(_buildingAccess == true) ? "granted" : "denied"}",);
      buildingAccessStatus = (_buildingAccess == true) ? Localization().getString('widget.id_card.label.building_access.granted', defaults: 'GRANTED', language: 'en') : Localization().getString('widget.id_card.label.building_access.denied', defaults: 'DENIED', language: 'en');
    }
    else {
      buildingAccessIcon = Container(height: (qrCodeImageSize / 2 - buildingAccessStatusHeight - 6));
      buildingAccessStatus = Localization().getString('widget.id_card.label.building_access.not_available', defaults: 'NOT\nAVAILABLE', language: 'en');
    }
    bool hasBuildingAccess = _hasBuildingAccess && (0 < (Auth2().authCard?.uin?.length ?? 0));

    
    return Column(children: <Widget>[
      Padding(padding: EdgeInsets.only(top: _headingH1 + _headingH2 / 5 - _photoSize / 2 - MediaQuery.of(context).padding.top), child:
        Stack(children: <Widget>[
          Align(alignment: Alignment.topCenter, child:
            Container(width: _photoSize, height: _photoSize, child:
              Stack(children: <Widget>[
                Transform.rotate(angle: _animationController.value, child:
                  Container(width: _photoSize, height: _photoSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [ Styles().colors!.fillColorSecondary!, _activeBorderColor],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 1.0],),
                      color: Styles().colors!.fillColorSecondary,),
                  ),
                ),
                _buildPhotoImage()
              ],),
            ),
            /*
            Container(width: _photoSize, height: _photoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Styles().colors.fillColorSecondary, Styles().colors.fillColorSecondary],
                  begin: Alignment.topCenter,
                  end:Alignment.bottomCenter,
                  stops: [0.0, 1.0],),
                color: Styles().colors.fillColorSecondary,),
              child: Padding(padding: EdgeInsets.all(16),
                child: Container(decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  image: DecorationImage(fit: BoxFit.cover, image: MemoryImage(Auth2().authCard?.photoBytes),),    
                )),
              )
            ),
            */
          ),
          Align(alignment: Alignment.topCenter, child:
            Padding(padding: EdgeInsets.only(top:_photoSize - _illiniIconSize / 2 - 5, left: 3), child:
              Styles().images?.getImage('university-logo-circle-white', excludeFromSemantics: true, width: _illiniIconSize, height: _illiniIconSize,)
            ),
          ),
        ],),
      ),
      Container(height: 10,),
      
      Text(Auth2().authCard?.fullName?.trim() ?? '', style:Styles().textStyles?.getTextStyle("panel.id_card.detail.title.large")),
      Text(roleDisplayString, style:  Styles().textStyles?.getTextStyle("panel.id_card.detail.title.regular")),
      
      Container(height: 15,),

      Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        
        Visibility(visible: hasQrCode, child: Column(children: [
          Text(Auth2().authCard!.cardNumber ?? '', style: Styles().textStyles?.getTextStyle("panel.id_card.detail.title.small")),
          Container(height: 8),
          showQRCode ?
            QrImage(data: _userQRCodeContent ?? "", size: qrCodeImageSize, padding: const EdgeInsets.all(0), version: QrVersions.auto, ) :
            Container(width: qrCodeImageSize, height: qrCodeImageSize, color: Colors.transparent,),
        ],),),

        Visibility(visible: hasQrCode && hasBuildingAccess, child:
          Container(width: 20),
        ),

        Visibility(visible: hasBuildingAccess, child: Column(children: [
          Text(Localization().getString('widget.id_card.label.building_access', defaults: 'Building Access', language: 'en')!, style: Styles().textStyles?.getTextStyle("panel.id_card.detail.title.small")),
          Container(height: 8),
          buildingAccessIcon ?? Container(),
          Text(buildingAccessStatus ?? '', textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle("panel.id_card.detail.title.large")),
        ],),),

      ],),
      Container(height: 15),
      Text(buildingAccessTime ?? '', style: Styles().textStyles?.getTextStyle("panel.id_card.detail.title.medium")),
      Container(height: 15),
      Semantics( container: true,
        child: Column(children: <Widget>[
          // Text((0 < (Auth2().authCard?.uin?.length ?? 0)) ? Localization().getStringEx('widget.card.label.uin.title', 'UIN') : '', style: TextStyle(color: Color(0xffcf3c1b), fontFamily: Styles().fontFamilies!.regular, fontSize: 14)),
          Text(Auth2().authCard?.uin ?? '', style: Styles().textStyles?.getTextStyle("panel.id_card.detail.title.extra_large")),
        ],),
      ),
      Text(cardExpiresText, style:  Styles().textStyles?.getTextStyle("panel.id_card.detail.title.tiny")),
      Container(height: 30,),
      _buildMobileAccessContent()

    ]);
  }

  Widget _buildPhotoImage(){
    return Container(width: _photoSize, height: _photoSize, child:
      Padding(padding: EdgeInsets.all(16),
        child: _photoImage != null
            ? Container(decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                image: DecorationImage(fit: BoxFit.cover, image:_photoImage! ,),
              ))
            : Container(decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ))
      ),
    );
  }

  Widget _buildMobileAccessContent() {
    if (_mobileAccessKeysLoading) {
      return Center(child: CircularProgressIndicator(color: Styles().colors?.fillColorSecondary));
    }

    return Padding(
        padding: EdgeInsets.only(bottom: 30),
        child: Column(children: [
          Container(color: Styles().colors!.dividerLine, height: 1),
          Padding(padding: EdgeInsets.only(top: 20), child: Styles().images?.getImage('mobile-access-logo', excludeFromSemantics: true)),
          (_hasMobileAccessKeys ? _buildExistingMobileAccessContent() : _buildMissingMobileAccessExistsContent())
        ]));
  }

  Widget _buildExistingMobileAccessContent() {
    if (!_hasMobileAccessKeys) {
      return Container();
    }
    if (_mobileKeysPageController == null) {
      _mobileKeysPageController = PageController();
    }
    int keysCount = _mobileAccessKeys!.length;
    List<Widget> keyWidgets = <Widget>[];
    for(dynamic key in _mobileAccessKeys!) {
      Map<String, dynamic>? keyMap = JsonUtils.mapValue(key);
      Widget keyWidget = _buildSingleMobileAccessKeyContent(keyMap);
      keyWidgets.add(keyWidget);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      ExpandablePageView(children: keyWidgets, controller: _mobileKeysPageController),
      AccessibleViewPagerNavigationButtons(controller: _mobileKeysPageController, pagesCount: () => keysCount),
      Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: InkWell(
              onTap: _onTapMobileAccessPermissions,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Padding(padding: EdgeInsets.only(right: 0), child: (Styles().images?.getImage('settings') ?? Container())),
                LinkButton(
                    title: Localization().getStringEx('widget.id_card.label.mobile_access.permissions', 'Set mobile access permissions'),
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    textStyle: Styles().textStyles?.getTextStyle('panel.id_card.detail.description.medium.underline'),
                    onTap: _onTapMobileAccessPermissions)
              ])))
    ]);
  }

  Widget _buildSingleMobileAccessKeyContent(Map<String, dynamic>? mobileAccessKey) {
    if (mobileAccessKey == null) {
      return Container();
    }

    String? mobileAccessExternalId = JsonUtils.stringValue(mobileAccessKey['external_id']);
    String? mobileAccessExpirationDateString = JsonUtils.stringValue(mobileAccessKey['expiration_date']);

    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Padding(
          padding: EdgeInsets.only(left: 16, bottom: 2, right: 16),
          child: Text(
              sprintf(
                  Localization().getStringEx('widget.id_card.label.mobile_access.my', 'My Mobile Access: %s'), [mobileAccessExternalId]),
              textAlign: TextAlign.center,
              style: Styles().textStyles?.getTextStyle('panel.id_card.detail.title.large'))),
      Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
              sprintf(Localization().getStringEx('widget.id_card.label.mobile_access.expires', 'Expires: %s'),
                  [mobileAccessExpirationDateString ?? '---']),
              style: Styles().textStyles?.getTextStyle('panel.id_card.detail.title.tiny'))),
      Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: RoundedButton(
              label: Localization().getStringEx('widget.id_card.button.mobile_access.renew', 'Renew'),
              hint: Localization().getStringEx('widget.id_card.button.mobile_access.renew.hint', ''),
              backgroundColor: Colors.white,
              fontSize: 16.0,
              contentWeight: 0.0,
              textColor: Styles().colors!.fillColorPrimary,
              borderColor: Styles().colors!.fillColorSecondary,
              onTap: _onTapRenewMobileAccessButton)),
    ]);
  }

  Widget _buildMissingMobileAccessExistsContent() {
    if (_hasMobileAccessKeys) {
      return Container();
    }

    return Column(children: [
      Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(Localization().getStringEx('widget.id_card.label.mobile_access', 'Mobile Access'),
              style: Styles().textStyles?.getTextStyle('panel.id_card.detail.title.extra_large'))),
      Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: RoundedButton(
              label: Localization().getStringEx('widget.id_card.button.mobile_access.request', 'Request'),
              hint: Localization().getStringEx('widget.id_card.button.mobile_access.request.hint', ''),
              backgroundColor: Colors.white,
              fontSize: 16.0,
              contentWeight: 0.0,
              textColor: Styles().colors!.fillColorPrimary,
              borderColor: Styles().colors!.fillColorSecondary,
              onTap: _onTapRequestMobileAccessButton)),
      Padding(
          padding: EdgeInsets.symmetric(horizontal: 50),
          child: Text(
              Localization().getStringEx('widget.id_card.label.mobile_access.i_card.not_available',
                  'Access various services and buildings on campus with your mobile i-card.'),
              textAlign: TextAlign.center,
              style: Styles().textStyles?.getTextStyle('panel.id_card.detail.description.italic')))
    ]);
  }

  Future<bool> _checkNetIdStatus() async {
    if (Auth2().authCard?.photoBase64?.isEmpty ?? true) {
      await AppAlert.showDialogResult(context, Localization().getStringEx('panel.covid19_passport.message.missing_id_info', 'No Illini ID information found. You may have an expired i-card. Please contact the ID Center.'));
      return false;
    }
    return true;
  }

  void _onTapRequestMobileAccessButton() {
    Analytics().logSelect(target: 'Request Mobile Access');
    //TBD: DD - implement request
  }

  void _onTapRenewMobileAccessButton() {
    Analytics().logSelect(target: 'Renew Mobile Access');
    AppAlert.showCustomDialog(
        context: context,
        contentPadding: EdgeInsets.all(0),
        contentWidget: Container(
            decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: BorderRadius.circular(10.0)),
            child: Stack(alignment: Alignment.center, fit: StackFit.loose, children: [
              Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: HtmlWidget(
                            "<div style=text-align:center>${Localization().getStringEx('widget.id_card.dialog.text.renew_access', 'Renewing your mobile i-card access could take up to 30 minutes to complete. Your <b>building access will be temporarily disabled</b> while being renewed. <p>Would you still like to renew right now?</p>')}</div>",
                            textStyle: Styles().textStyles?.getTextStyle("widget.detail.small"))),
                    Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      RoundedButton(
                          label: Localization().getStringEx('widget.id_card.dialog.button.mobile_access.renew.cancel', 'Cancel'),
                          hint: Localization().getStringEx('widget.id_card.dialog.button.mobile_access.renew.cancel.hint', ''),
                          backgroundColor: Colors.white,
                          fontSize: 16.0,
                          contentWeight: 0.0,
                          textColor: Styles().colors!.fillColorPrimary,
                          borderColor: Styles().colors!.fillColorSecondary,
                          onTap: _onTapCancelRenew),
                      RoundedButton(
                          label: Localization().getStringEx('widget.id_card.dialog.button.mobile_access.renew_access', 'Renew Access'),
                          hint: Localization().getStringEx('widget.id_card.dialog.button.mobile_access.renew_access.hint', ''),
                          backgroundColor: Styles().colors!.fillColorSecondary,
                          fontSize: 16.0,
                          contentWeight: 0.0,
                          textColor: Styles().colors!.white,
                          borderColor: Styles().colors!.fillColorSecondary,
                          onTap: _onTapRenewAccess)
                    ])
                  ]))
            ])));
  }

  void _onTapCancelRenew() {
    Analytics().logSelect(target: 'Cancel Renew Access');
    Navigator.of(context).pop();
  }

  void _onTapRenewAccess() {
    Analytics().logSelect(target: 'Renew Access');
    Navigator.of(context).pop();
    //TBD: DD - implement renew access

    final String phoneMacro = '{{mobile_access_phone}}';
    final String emailMacro = '{{mobile_access_email}}';
    final String urlMacro = '{{mobile_access_website_url}}';
    final String externalLinkIconMacro = '{{external_link_icon}}';
    String rescheduleContentHtml = Localization().getStringEx("widget.id_card.dialog.text.renew_access.done",
        "If your mobile i-card does not work in 30 minutes, call <a href='tel:{{mobile_access_phone}}'>{{mobile_access_phone}}</a>, email <a href='mailto:{{mobile_access_email}}'>{{mobile_access_email}}</a>, or <a href='{{mobile_access_website_url}}'>visit the i-card website</a> <img src='asset:{{external_link_icon}}' alt=''/>");
    //TBD: DD - read phone, email and website from config when we have them
    rescheduleContentHtml = rescheduleContentHtml.replaceAll(phoneMacro, '555-555-555');
    rescheduleContentHtml = rescheduleContentHtml.replaceAll(emailMacro, 'test@email.com');
    rescheduleContentHtml = rescheduleContentHtml.replaceAll(urlMacro, 'https://www.google.com');
    rescheduleContentHtml = rescheduleContentHtml.replaceAll(externalLinkIconMacro, 'images/external-link.png');
    AppAlert.showCustomDialog(
        context: context,
        contentPadding: EdgeInsets.all(0),
        contentWidget: Container(
            decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: BorderRadius.circular(10.0)),
            child: Stack(alignment: Alignment.center, fit: StackFit.loose, children: [
              Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                        padding: EdgeInsets.only(top: 30),
                        child: Text(
                            Localization().getStringEx('widget.id_card.dialog.title.renew_access.done',
                                'Please wait at least 30 minutes before trying your mobile access'), textAlign: TextAlign.center,
                            style: Styles().textStyles?.getTextStyle('widget.title.medium.fat'))),
                    Padding(
                        padding: EdgeInsets.only(top: 20),
                        //TBD: DD - properly format html. Currently not able with this plugin
                        child: HtmlWidget("<div style=text-align:center>$rescheduleContentHtml</div>",
                            textStyle: Styles().textStyles?.getTextStyle("widget.detail.small"),
                            onTapUrl: (url) => _onTapLinkUrl(url)))
                  ])),
              Positioned.fill(
                  child: Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                          onTap: () {
                            Analytics().logSelect(target: 'Close Renew Mobile Access popup');
                            Navigator.of(context).pop();
                          },
                          child: Padding(padding: EdgeInsets.all(16), child: Styles().images?.getImage('close', color: Styles().colors?.fillColorPrimary)))))
            ])));
  }

  Future<bool> _onTapLinkUrl(String? url) async {
    if (StringUtils.isNotEmpty(url)) {
      Uri? uri = Uri.tryParse(url!);
      if ((uri != null) && (await canLaunchUrl(uri))) {
        LaunchMode launchMode = Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault;
        launchUrl(uri, mode: launchMode);
        return true;
      }
    }
    return false;
  }

  void _onTapMobileAccessPermissions() {
    Analytics().logSelect(target: 'Mobile Access Permissions');
    SettingsHomeContentPanel.present(context, content: SettingsContent.i_card);
  }

  void _setMobileAccessKeysLoading(bool loading) {
    setStateIfMounted(() {
      _mobileAccessKeysLoading = loading;
    });
  }

  String? get _userQRCodeContent {
    String? qrCodeContent = Auth2().authCard!.magTrack2;
    return ((qrCodeContent != null) && (0 < qrCodeContent.length)) ? qrCodeContent : Auth2().authCard?.uin;
  }

  bool get _hasBuildingAccess => FlexUI().isSaferAvailable;

  bool get _hasMobileAccessKeys {
    return (_mobileAccessKeys != null) && _mobileAccessKeys!.isNotEmpty;
  }
}


