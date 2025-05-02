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
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Identity.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:http/http.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Identity.dart';
import 'package:illinois/service/MobileAccess.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:illinois/ui/wallet/WalletPhotoWrapper.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_io/io.dart';
// import 'package:url_launcher/url_launcher.dart';

//////////////////////////
// WalletICardPage

class WalletICardPage extends StatefulWidget {
  final double topOffset;
  WalletICardPage({super.key, this.topOffset = 0});

  _WalletICardPageState createState() => _WalletICardPageState();
}

class _WalletICardPageState extends State<WalletICardPage> with NotificationsListener {

  final double _buildingAccessIconSize = 84;

  bool? _buildingAccess;
  DateTime? _buildingAccessTime;
  late bool _loadingBuildingAccess;

  int _mobileAccessLoadingProgress = 0;
  bool _isIcardMobileAvailable = false;
  List<dynamic>? _mobileAccessKeys;
  List<MobileIdCredential>? _mobileIdCredentials;
  PageController? _mobileAccessPageController;

  bool _submittingDeviceRegistration = false;
  bool _deleteMobileCredential = false;
  bool _renewingMobileId = false;

  GestureRecognizer? _lostCardLaunchRecognizer;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      MobileAccess.notifyMobileStudentIdChanged,
      MobileAccess.notifyStartFinished,
      AppLifecycle.notifyStateChanged,
    ]);

    _lostCardLaunchRecognizer = TapGestureRecognizer()..onTap = _onLaunchLostCardUrl;

    MobileAccess().startIfNeeded();

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
    _mobileAccessPageController?.dispose();
    _lostCardLaunchRecognizer?.dispose();
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == MobileAccess.notifyMobileStudentIdChanged) {
      MobileAccess().startIfNeeded();
      _checkIcarMobileAvailable();
      setStateIfMounted(() { });
    }
    else if (name == MobileAccess.notifyStartFinished) {
      _checkIcarMobileAvailable();
      setStateIfMounted(() { });
    } else if (name == AppLifecycle.notifyStateChanged) {
      if ((param is AppLifecycleState) && (param == AppLifecycleState.resumed)) {
        setStateIfMounted(() {});
      }
    }
  }


  @override
  Widget build(BuildContext context) =>
    WalletPhotoWrapper(topOffset: widget.topOffset, child: _buildCardContent(),);

  Widget _buildCardContent() {

    String? cardExpires = Localization().getStringEx('widget.card.label.expires.title', 'Expires');
    String? expirationDate = Auth2().iCard?.expirationDate;
    String cardExpiresText = (0 < (expirationDate?.length ?? 0)) ? "$cardExpires $expirationDate" : "";
    String roleDisplayString = (Auth2().iCard?.needsUpdate ?? false) ? Localization().getStringEx("widget.id_card.label.update_i_card", "Update your Illini ID") : (Auth2().iCard?.role ?? "");

    Widget? buildingAccessIcon;
    String? buildingAccessStatus;
    String? buildingAccessTime = AppDateTime().formatDateTime(_buildingAccessTime, format: 'MMM dd, yyyy HH:mm a');
    double buildingAccessStatusHeight = 24;
    double qrCodeImageSize = _buildingAccessIconSize + buildingAccessStatusHeight - 2;
    bool hasQrCode = (0 < (_userQRCodeContent?.length ?? 0));

    DateTime? expirationDateTimeUtc = Auth2().iCard?.expirationDateTimeUtc;
    bool cardExpired = (expirationDateTimeUtc != null) && DateTime.now().toUtc().isAfter(expirationDateTimeUtc);
    bool showQRCode = !cardExpired;

    if (_loadingBuildingAccess) {
      buildingAccessIcon = Container(width: _buildingAccessIconSize, height: _buildingAccessIconSize, child:
        Align(alignment: Alignment.center, child:
          SizedBox(height: 42, width: 42, child:
            CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary), )
          )
        ,),);
    }
    else if (_buildingAccess != null) {
      buildingAccessIcon = Styles().images.getImage((_buildingAccess == true) ? 'building-access-granted' : 'building-access-denied', width: _buildingAccessIconSize, height: _buildingAccessIconSize, semanticLabel: "building access ${(_buildingAccess == true) ? "granted" : "denied"}",);
      buildingAccessStatus = (_buildingAccess == true) ? Localization().getString('widget.id_card.label.building_access.granted', defaults: 'GRANTED', language: 'en') : Localization().getString('widget.id_card.label.building_access.denied', defaults: 'DENIED', language: 'en');
    }
    else {
      buildingAccessIcon = Container(height: (qrCodeImageSize / 2 - buildingAccessStatusHeight - 6));
      buildingAccessStatus = Localization().getString('widget.id_card.label.building_access.not_available', defaults: 'NOT\nAVAILABLE', language: 'en');
    }
    bool hasBuildingAccess = _hasBuildingAccess && (0 < (Auth2().iCard?.uin?.length ?? 0));

    return Column(children: <Widget>[
      Text(Auth2().iCard?.fullName?.trim() ?? '', style:Styles().textStyles.getTextStyle("panel.id_card.detail.title.large")),
      Text(roleDisplayString, style:  Styles().textStyles.getTextStyle("panel.id_card.detail.title.regular")),

      Container(height: 16,),

      Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

        Visibility(visible: hasQrCode, child: Column(children: [
          //Text(Auth2().iCard!.cardNumber ?? '', style: Styles().textStyles.getTextStyle("panel.id_card.detail.title.small")),
          //Container(height: 8),
          showQRCode ?
            QrImageView(data: _userQRCodeContent ?? "", size: qrCodeImageSize, padding: const EdgeInsets.all(0), version: QrVersions.auto, ) :
            Container(width: qrCodeImageSize, height: qrCodeImageSize, color: Colors.transparent,),
        ],),),

        Visibility(visible: hasQrCode && hasBuildingAccess, child:
          Container(width: 16),
        ),

        Visibility(visible: hasBuildingAccess, child: Column(children: [
          Text(Localization().getString('widget.id_card.label.building_access', defaults: 'Building Access', language: 'en')!, style: Styles().textStyles.getTextStyle("panel.id_card.detail.title.small")),
          Container(height: 8),
          buildingAccessIcon ?? Container(),
          Text(buildingAccessStatus ?? '', textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("panel.id_card.detail.title.large")),
        ],),),

      ],),

      Container(height: 16),

      Text(buildingAccessTime ?? '', style: Styles().textStyles.getTextStyle("panel.id_card.detail.title.medium")),

      Container(height: 16),

      Semantics( container: true, child:
        Column(children: <Widget>[
          // Text((0 < (Auth2().iCard?.uin?.length ?? 0)) ? Localization().getStringEx('widget.card.label.uin.title', 'UIN') : '', style: TextStyle(color: Color(0xffcf3c1b), fontFamily: Styles().fontFamilies.regular, fontSize: 14)),
          Text(Auth2().iCard?.uin ?? '', style: Styles().textStyles.getTextStyle("panel.id_card.detail.title.extra_large")),
        ],),
      ),

      Text(cardExpiresText, style:  Styles().textStyles.getTextStyle("panel.id_card.detail.title.tiny")),

      Container(height: 16,),

      Padding(padding: EdgeInsets.symmetric(horizontal: 48), child:
        Text(Localization().getStringEx('widget.id_card.text.card_instructions', 'This ID must be presented to university officials upon request.'), textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("panel.id_card.detail.description.italic")),
      ),

      Container(height: 8,),

      Padding(padding: EdgeInsets.symmetric(horizontal: 48), child:
        _lostCardInfoWidget,
      ),

      Container(height: 32,),

      _buildMobileAccessContent(),
    ]);
  }

  Widget _buildMobileAccessContent() {
    if (!_isIcardMobileAvailable) {
      return Container();
    } else if (_isMobileAccessLoading) {
      return Center(child: CircularProgressIndicator(color: Styles().colors.fillColorSecondary));
    } else {
      return Padding(
        padding: EdgeInsets.only(bottom: 30),
        child: Column(children: [
          Container(color: Styles().colors.dividerLine, height: 1),
          Padding(padding: EdgeInsets.only(top: 20), child: Styles().images.getImage('mobile-access-logo', excludeFromSemantics: true)),
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
                Padding(padding: EdgeInsets.only(right: 0), child: (Styles().images.getImage('settings') ?? Container())),
                LinkButton(
                    title: Localization().getStringEx('widget.id_card.label.mobile_access.permissions', 'Set mobile access permissions'),
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    textStyle: Styles().textStyles.getTextStyle('panel.id_card.mobile_access.link_button.description.medium.underline'),
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
              style: Styles().textStyles.getTextStyle('panel.id_card.detail.title.large'))),
      Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
              sprintf(Localization().getStringEx('widget.id_card.label.mobile_access.expires', 'Expires: %s'),
                  [StringUtils.ensureNotEmpty(expirationDateString, defaultValue: '---')]),
              style: Styles().textStyles.getTextStyle('panel.id_card.detail.title.tiny'))),
      Visibility(visible: MobileAccess().canRenewMobileId, child: Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: RoundedButton(
              label: Localization().getStringEx('widget.id_card.button.mobile_access.renew', 'Renew'),
              hint: Localization().getStringEx('widget.id_card.button.mobile_access.renew.hint', ''),
              textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
              backgroundColor: Colors.white,
              contentWeight: 0.0,
              progress: _renewingMobileId,
              borderColor: Styles().colors.fillColorSecondary,
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
              style: Styles().textStyles.getTextStyle('panel.id_card.detail.title.extra_large'))),
      Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: RoundedButton(
              label: _submitButtonLabel,
              hint: _submitButtonHint,
              textStyle: _submitButtonEnabled ? Styles().textStyles.getTextStyle("widget.button.title.enabled") : Styles().textStyles.getTextStyle("widget.button.title.disabled"),
              backgroundColor: Colors.white,
              enabled: _submitButtonEnabled,
              contentWeight: 0.0,
              borderColor: _submitButtonEnabled ? Styles().colors.fillColorSecondary : Styles().colors.textDisabled,
              progress: _submittingDeviceRegistration,
              onTap: _onTapSubmitMobileAccessButton)),
      Visibility(visible: MobileAccess().isMobileAccessWaiting, child: Padding(padding: EdgeInsets.only(bottom: 10), child: Text(
          StringUtils.ensureNotEmpty(_mobileAccessWaitingLabel),
          style: Styles().textStyles.getTextStyle('panel.id_card.detail.title.tiny')))),
      Padding(
          padding: EdgeInsets.symmetric(horizontal: 50),
          child: Text(
              Localization().getStringEx('widget.id_card.label.mobile_access.i_card.not_available',
                  'Access various services and buildings on campus with your Illini ID.'),
              textAlign: TextAlign.center,
              style: Styles().textStyles.getTextStyle('panel.id_card.mobile_access.description.italic')))
    ]);
  }

  Future<bool?> _loadBuildingAccess() async {
    if (_hasBuildingAccess && StringUtils.isNotEmpty(Config().padaapiUrl) && StringUtils.isNotEmpty(Config().padaapiApiKey) && StringUtils.isNotEmpty(Auth2().iCard?.uin)) {
      String url = "${Config().padaapiUrl}/access/${Auth2().iCard?.uin}";
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

  Widget get _lostCardInfoWidget {
    final String lostLinkMacro = '{{lost_link}}';
    final String externalLinkMacro = '{{external_link_icon}}';
    TextStyle? regularTextStyle = Styles().textStyles.getTextStyle('panel.id_card.detail.description.italic');
    TextStyle? linkTextStyle = Styles().textStyles.getTextStyle('panel.id_card.detail.description.italic.link');

    String infoText = Localization().getStringEx('widget.id_card.text.lost_instructions.format', '$externalLinkMacro $lostLinkMacro');
    String linkText = Localization().getStringEx('widget.id_card.text.lost_instructions.link', 'Lost or stolen i-card?');

    List<InlineSpan> spanList = StringUtils.split<InlineSpan>(infoText, macros: [lostLinkMacro, externalLinkMacro], builder: (String entry){
      if (entry == lostLinkMacro) {
        return TextSpan(text: linkText, style : linkTextStyle, recognizer: _lostCardLaunchRecognizer,);
      }
      else if (entry == externalLinkMacro) {
        return WidgetSpan(alignment: PlaceholderAlignment.middle, child: Styles().images.getImage('external-link', size: 14) ?? Container());
      }
      else {
        return TextSpan(text: entry);
      }
    });
    return RichText(textAlign: TextAlign.center, text:
      TextSpan(style: regularTextStyle, children: spanList)
    );
  }

  void _onLaunchLostCardUrl() {
    Analytics().logSelect(target: 'Lost iCard Report');
    _launchUrl(Config().iCardLostReportUrl);
  }

  static void _launchUrl(String? url) {
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri, mode: (Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault));
        }
      }
    }
  }

  Future<bool> _checkNetIdStatus() async {
    if (Auth2().iCard?.photoBase64?.isEmpty ?? true) {
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
    MobileAccess().renewMobileId().then((result) {
      bool success = (result?.isRenewed == true);
      late String msg;
      if (success) {
        msg = Localization().getStringEx('widget.id_card.mobile_access.renew.success.msg', 'Mobile Access was successfully renewed.');
      } else {
        msg = sprintf(Localization().getStringEx('widget.id_card.mobile_access.renew.fail.msg', 'Failed to renew Mobile Access. Reason: %s'), [result?.resultDescription ?? 'unknown']);
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
    String? qrCodeContent = Auth2().iCard!.magTrack2;
    return ((qrCodeContent != null) && (0 < qrCodeContent.length)) ? qrCodeContent : Auth2().iCard?.uin;
  }

  bool get _hasBuildingAccess => false;

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

