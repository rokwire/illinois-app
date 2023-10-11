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
// import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/model/Identity.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:http/http.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Identity.dart';
import 'package:illinois/service/MobileAccess.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
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
// import 'package:url_launcher/url_launcher.dart';

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

  int _mobileAccessLoadingProgress = 0;
  bool _isIcardMobileAvailable = false;
  List<dynamic>? _mobileAccessKeys;
  List<MobileIdCredential>? _mobileIdCredentials;
  PageController? _mobileAccessPageController;

  bool _submittingDeviceRegistration = false;
  bool _deleteMobileCredential = false;
  bool _renewingMobileId = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Auth2.notifyCardChanged,
      MobileAccess.notifyMobileStudentIdChanged,
      MobileAccess.notifyStartFinished,
      AppLivecycle.notifyStateChanged,
    ]);

    MobileAccess().startIfNeeded();
    
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

      _checkIcarMobileAvailable();

    // Auth2().updateAuthCard();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _animationController.dispose();
    _mobileAccessPageController?.dispose();
    super.dispose();
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

  Future<void> _loadMobileAccessDetails() async {
    if (_isIcardMobileAvailable) {
      _increaseMobileAccessLoadingProgress();
      MobileAccess().loadStudentId().then((studentId) {
        List<MobileIdCredential>? mobileCredentials = studentId?.mobileCredentials;
        if (CollectionUtils.isNotEmpty(mobileCredentials)) {
          _mobileIdCredentials = mobileCredentials;
          MobileAccess().getAvailableKeys().then((accessKeys) {
            List<dynamic>? mobileKeys = accessKeys;
            if (CollectionUtils.isNotEmpty(mobileKeys)) {
              _mobileAccessKeys = accessKeys;
            } else if (!_hasDeleteTimeout) {
              _deleteMobileCredential = true;
            }
            _decreaseMobileAccessLoadingProgress();
          });
        } else {
          _mobileIdCredentials = null;
          _mobileAccessKeys = null;
          _decreaseMobileAccessLoadingProgress();
        }
      });
    } else {
      setStateIfMounted(() {
        _mobileAccessKeys = null;
        _mobileIdCredentials = null;
      });
    }
  }

  // NotificationsListener
  
  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyCardChanged) {
      _loadAsyncPhotoImage().then((MemoryImage? photoImage){
        setStateIfMounted(() {
          _photoImage = photoImage;
        });
      });
    }
    else if (name == MobileAccess.notifyMobileStudentIdChanged) {
      MobileAccess().startIfNeeded();
      _checkIcarMobileAvailable();
      setStateIfMounted(() { });
    }
    else if (name == MobileAccess.notifyStartFinished) {
      _checkIcarMobileAvailable();
      setStateIfMounted(() { });
    } else if (name == AppLivecycle.notifyStateChanged) {
      if ((param is AppLifecycleState) && (param == AppLifecycleState.resumed)) {
        setStateIfMounted(() {});
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
    String roleDisplayString = (Auth2().authCard?.needsUpdate ?? false) ? Localization().getStringEx("widget.id_card.label.update_i_card", "Update your Illini ID") : (Auth2().authCard?.role ?? "");

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
            QrImageView(data: _userQRCodeContent ?? "", size: qrCodeImageSize, padding: const EdgeInsets.all(0), version: QrVersions.auto, ) :
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
    if (!_isIcardMobileAvailable) {
      return Container();
    } else if (_isMobileAccessLoading) {
      return Center(child: CircularProgressIndicator(color: Styles().colors?.fillColorSecondary));
    } else {
      return Padding(
        padding: EdgeInsets.only(bottom: 30),
        child: Column(children: [
          Container(color: Styles().colors!.dividerLine, height: 1),
          Padding(padding: EdgeInsets.only(top: 20), child: Styles().images?.getImage('mobile-access-logo', excludeFromSemantics: true)),
          (_hasMobileAccess ? _buildExistingMobileAccessContent() : _buildMissingMobileAccessContent())
        ]));
    }

  }

  Widget _buildExistingMobileAccessContent() {
    if (!_hasMobileAccess) {
      return Container();
    }
    if (_mobileAccessPageController == null) {
      _mobileAccessPageController = PageController();
    }
    int credentialsCount = _mobileIdCredentials!.length;
    List<Widget> credentialWidgets = <Widget>[];
    for(MobileIdCredential credential in _mobileIdCredentials!) {
      Widget credentialWidget = _buildSingleMobileAccessCredentialContent(credential);
      credentialWidgets.add(credentialWidget);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      ExpandablePageView(children: credentialWidgets, controller: _mobileAccessPageController),
      AccessibleViewPagerNavigationButtons(controller: _mobileAccessPageController, pagesCount: () => credentialsCount),
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

  Widget _buildSingleMobileAccessCredentialContent(MobileIdCredential credential) {
    String? credentialId = credential.id;
    String? expirationDateString = credential.displayExpirationDate;

    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Padding(
          padding: EdgeInsets.only(left: 16, bottom: 2, right: 16),
          child: Text(
              sprintf(
                  Localization().getStringEx('widget.id_card.label.mobile_access.my', 'My Mobile Access: %s'), [credentialId]),
              textAlign: TextAlign.center,
              style: Styles().textStyles?.getTextStyle('panel.id_card.detail.title.large'))),
      Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
              sprintf(Localization().getStringEx('widget.id_card.label.mobile_access.expires', 'Expires: %s'),
                  [StringUtils.ensureNotEmpty(expirationDateString, defaultValue: '---')]),
              style: Styles().textStyles?.getTextStyle('panel.id_card.detail.title.tiny'))),
      Visibility(visible: MobileAccess().canRenewMobileId, child: Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: RoundedButton(
              label: Localization().getStringEx('widget.id_card.button.mobile_access.renew', 'Renew'),
              hint: Localization().getStringEx('widget.id_card.button.mobile_access.renew.hint', ''),
              textStyle: Styles().textStyles?.getTextStyle("widget.button.title.enabled"),
              backgroundColor: Colors.white,
              contentWeight: 0.0,
              progress: _renewingMobileId,
              borderColor: Styles().colors!.fillColorSecondary,
              onTap: _onTapRenewMobileAccessButton)))
    ]);
  }

  Widget _buildMissingMobileAccessContent() {
    if (_hasMobileAccess) {
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
              label: _submitButtonLabel,
              hint: _submitButtonHint,
              textStyle: _submitButtonEnabled ? Styles().textStyles?.getTextStyle("widget.button.title.enabled") : Styles().textStyles?.getTextStyle("widget.button.title.disabled"),
              backgroundColor: Colors.white,
              enabled: _submitButtonEnabled,
              contentWeight: 0.0,
              borderColor: _submitButtonEnabled ? Styles().colors!.fillColorSecondary : Styles().colors!.disabledTextColor,
              progress: _submittingDeviceRegistration,
              onTap: _onTapSubmitMobileAccessButton)),
      Visibility(visible: MobileAccess().isMobileAccessWaiting, child: Padding(padding: EdgeInsets.only(bottom: 10), child: Text(
          StringUtils.ensureNotEmpty(_mobileAccessWaitingLabel),
          style: Styles().textStyles?.getTextStyle('panel.id_card.detail.title.tiny')))),
      Padding(
          padding: EdgeInsets.symmetric(horizontal: 50),
          child: Text(
              Localization().getStringEx('widget.id_card.label.mobile_access.i_card.not_available',
                  'Access various services and buildings on campus with your Illini ID.'),
              textAlign: TextAlign.center,
              style: Styles().textStyles?.getTextStyle('panel.id_card.detail.description.italic')))
    ]);
  }

  Future<bool> _checkNetIdStatus() async {
    if (Auth2().authCard?.photoBase64?.isEmpty ?? true) {
      await AppAlert.showDialogResult(context, Localization().getStringEx('panel.covid19_passport.message.missing_id_info', 'No Illini ID information found. You may have an expired Illini ID. Please contact the ID Center.'));
      return false;
    }
    return true;
  }

  void _onTapSubmitMobileAccessButton() {
    if (_submittingDeviceRegistration || !_submitButtonEnabled) {
      return;
    }
    Analytics().logSelect(target: _hasDeleteTimeout ? 'Download' : 'Request');
    _setSubmittingDeviceRegistration(true);
    if (_deleteMobileCredential) {
      Identity().deleteMobileCredential().then((deleteInitiated) {
        late String deleteMsg;
        if (deleteInitiated) {
          Storage().mobileAccessDeleteTimeoutUtcInMillis = DateTime.now().add(Duration(minutes: Config().mobileAccessDeleteTimeoutMins)).toUtc().millisecondsSinceEpoch;
          deleteMsg = Localization().getStringEx('widget.id_card.mobile_access.delete_credential.success.msg', 'Please, wait about 10 minutes until mobile access is available to download.');
        } else {
          deleteMsg = Localization().getStringEx('widget.id_card.mobile_access.delete_credential.failed.msg', 'Failed to request mobile access.');
        }
        _setSubmittingDeviceRegistration(false);
        AppAlert.showDialogResult(context, deleteMsg);
      });
    } else {
      MobileAccess().requestDeviceRegistration().then((error) {
        late String requestMsg;
        if (error != null) {
          requestMsg = _registrationErrorToString(error)!;
        } else {
          requestMsg = Localization().getStringEx('widget.id_card.mobile_access.request_register_device.success.msg', 'Successfully initiated device registration.');
          // Load mobile access details after successful device registration.
          _loadMobileAccessDetails();
        }
        _setSubmittingDeviceRegistration(false);
        AppAlert.showDialogResult(context, requestMsg);
      });
    }
  }

  void _onTapRenewMobileAccessButton() {
    if (_renewingMobileId) {
      return;
    }
    Analytics().logSelect(target: 'Renew Mobile Access');
    setStateIfMounted(() {
      _renewingMobileId = true;
    });
    MobileAccess().renewMobileId().then((studentId) {
      bool success = (studentId != null);
      late String msg;
      if (success) {
        msg = Localization().getStringEx('widget.id_card.mobile_access.renew.success.msg', 'Mobile Access was successfully renewed.');
      } else {
        msg = Localization().getStringEx('widget.id_card.mobile_access.renew.fail.msg', 'Failed to renew Mobile Access.');
      }
      setStateIfMounted(() {
        _renewingMobileId = false;
      });
      AppAlert.showDialogResult(context, msg).then((value) {
        if (success) {
          _loadMobileAccessDetails();
        }
      });
    });
  }

  void _onTapMobileAccessPermissions() {
    Analytics().logSelect(target: 'Mobile Access Permissions');
    SettingsHomeContentPanel.present(context, content: SettingsContent.i_card);
  }

  void _checkIcarMobileAvailable() {
    bool isIcardMobileAvailable = MobileAccess().isMobileAccessAvailable && MobileAccess().isStarted;
    if (_isIcardMobileAvailable != isIcardMobileAvailable) {
      _isIcardMobileAvailable = isIcardMobileAvailable;
      _loadMobileAccessDetails();
    }
  }

  void _increaseMobileAccessLoadingProgress() {
    setStateIfMounted(() {
      _mobileAccessLoadingProgress++;
    });
  }

  void _decreaseMobileAccessLoadingProgress() {
    setStateIfMounted(() {
      _mobileAccessLoadingProgress--;
    });
  }

  bool get _isMobileAccessLoading {
    return (_mobileAccessLoadingProgress > 0);
  }

  void _setSubmittingDeviceRegistration(bool value) {
    setStateIfMounted(() {
      _submittingDeviceRegistration = value;
    });
  }

  String? get _userQRCodeContent {
    String? qrCodeContent = Auth2().authCard!.magTrack2;
    return ((qrCodeContent != null) && (0 < qrCodeContent.length)) ? qrCodeContent : Auth2().authCard?.uin;
  }

  bool get _hasBuildingAccess => FlexUI().isSaferAvailable;

  bool get _hasMobileAccess => (_hasMobileAccessKeys && _hasMobileIdentityCredentials);

  bool get _hasMobileAccessKeys => ((_mobileAccessKeys != null) && _mobileAccessKeys!.isNotEmpty);

  bool get _hasMobileIdentityCredentials => CollectionUtils.isNotEmpty(_mobileIdCredentials);

  bool get _submitButtonEnabled {
    return ((!_hasDeleteTimeout || _deleteTimeoutPassed) && !MobileAccess().isMobileAccessWaiting);
  }

  DateTime? get _deleteTimeoutUtc {
    int? timeOutInMillis = Storage().mobileAccessDeleteTimeoutUtcInMillis;
    return (timeOutInMillis != null) ? DateTime.fromMillisecondsSinceEpoch(timeOutInMillis, isUtc: true) : null;
  }

  bool get _hasDeleteTimeout {
    return (_deleteTimeoutUtc != null);
  }

  bool get _deleteTimeoutPassed {
    return _hasDeleteTimeout && _deleteTimeoutUtc!.isBefore(DateTime.now().toUtc());
  }

  String get _submitButtonLabel {
    return _hasDeleteTimeout
        ? Localization().getStringEx('widget.id_card.button.mobile_access.download', 'Download')
        : Localization().getStringEx('widget.id_card.button.mobile_access.request', 'Request');
  }

  String get _submitButtonHint {
    return _hasDeleteTimeout
        ? Localization().getStringEx('widget.id_card.button.mobile_access.download.hint', '')
        : Localization().getStringEx('widget.id_card.button.mobile_access.request.hint', '');
  }

  String? get _mobileAccessWaitingLabel {
    if (MobileAccess().isMobileAccessIssuing) {
      return Localization().getStringEx('widget.id_card.mobile_access.pending.label', 'Pending');
    } else if (MobileAccess().isMobileAccessPending) {
      return Localization().getStringEx('widget.id_card.mobile_access.issuing.label', 'Issuing');
    } else {
      return null;
    }
  }

  static String? _registrationErrorToString(MobileAccessRequestDeviceRegistrationError? error) {
    switch (error) {
      case MobileAccessRequestDeviceRegistrationError.not_using_bb:
        return Localization()
            .getStringEx('widget.id_card.mobile_access.request_register_device.error.not_using_bb', 'You are not allowed to request mobile access.');
      case MobileAccessRequestDeviceRegistrationError.icard_not_allowed:
        return Localization()
            .getStringEx('widget.id_card.mobile_access.request_register_device.error.icard_not_allowed', 'You are not a member of a required group.');
      case MobileAccessRequestDeviceRegistrationError.device_already_registered:
        return Localization()
            .getStringEx('widget.id_card.mobile_access.request_register_device.error.device_already_registered', 'Your device had already been registered.');
      case MobileAccessRequestDeviceRegistrationError.no_mobile_credential:
        return Localization()
            .getStringEx('widget.id_card.mobile_access.request_register_device.error.no_mobile_credential', 'No mobile identity credential available.');
      case MobileAccessRequestDeviceRegistrationError.no_pending_invitation:
        return Localization()
            .getStringEx('widget.id_card.mobile_access.request_register_device.error.no_pending_invitation', 'No mobile identity invitation available.');
      case MobileAccessRequestDeviceRegistrationError.no_invitation_code:
        return Localization()
            .getStringEx('widget.id_card.mobile_access.request_register_device.error.no_invitation_code', 'No mobile identity invitation code available.');
      case MobileAccessRequestDeviceRegistrationError.invitation_code_expired:
        return Localization()
            .getStringEx('widget.id_card.mobile_access.request_register_device.error.invitation_code_expired', 'Invitation code has been expired.');
      case MobileAccessRequestDeviceRegistrationError.registration_initiation_failed:
        return Localization().getStringEx(
            'widget.id_card.mobile_access.request_register_device.error.registration_initiation_failed', 'Failed to initiate device registration.');
      default:
        return null;
    }
  }
}


