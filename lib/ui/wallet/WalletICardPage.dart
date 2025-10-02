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
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:http/http.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/ui/wallet/WalletPhotoWrapper.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

  GestureRecognizer? _lostCardLaunchRecognizer;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
    ]);

    _lostCardLaunchRecognizer = TapGestureRecognizer()..onTap = _onLaunchLostCardUrl;

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

    // Auth2().updateAuthCard();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _lostCardLaunchRecognizer?.dispose();
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
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
          // Text((0 < (Auth2().authCard?.uin?.length ?? 0)) ? Localization().getStringEx('widget.card.label.uin.title', 'UIN') : '', style: TextStyle(color: Color(0xffcf3c1b), fontFamily: Styles().fontFamilies.regular, fontSize: 14)),
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

  String? get _userQRCodeContent {
    String? qrCodeContent = Auth2().iCard!.magTrack2;
    return ((qrCodeContent != null) && (0 < qrCodeContent.length)) ? qrCodeContent : Auth2().iCard?.uin;
  }

  bool get _hasBuildingAccess => false;
}

