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
import 'package:flutter/material.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:http/http.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Transportation.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:qr_flutter/qr_flutter.dart';

class IDCardPanel extends StatefulWidget {
  IDCardPanel();

  static void present(BuildContext context) {
    if (!Auth2().isOidcLoggedIn) {
      AppAlert.showMessage(context, Localization().getStringEx('panel.browse.label.logged_out.illini_id', 'You need to be logged in to access Illini ID.'));
    }
    else if (StringUtils.isEmpty(Auth2().authCard?.cardNumber)) {
      AppAlert.showMessage(context, Localization().getStringEx('panel.browse.label.no_card.illini_id', 'You need a valid Illini Identity card to access Illini ID.'));
    }
    else {
      showModalBottomSheet(context: context,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        builder: (context) => IDCardPanel());
    }
  }

  _IDCardPanelState createState() => _IDCardPanelState();
}

class _IDCardPanelState extends State<IDCardPanel>
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


  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, Auth2.notifyCardChanged);
    
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

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _animationController.dispose();
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
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(body:
      Stack(children: <Widget>[
          
          Column(children: <Widget>[
            Container(height: _headingH1, color: _activeHeadingColor,),
            Container(height: _headingH2, color: _activeHeadingColor, child: CustomPaint(painter: TrianglePainter(painterColor: Colors.white), child: Container(),),),
          ],),
          
          SafeArea(child: Column(children: <Widget>[
            Expanded(child: (Auth2().authCard != null) ? _buildCardContent() : Container(),),

            Align(alignment: Alignment.bottomCenter, child:
              Padding(padding: EdgeInsets.only(), child:
                Semantics(button:true,label: Localization().getStringEx('widget.id_card.header.button.close.title', "close"), child:
                  InkWell(onTap : _onClose, child:
                    Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Color(0xff0f2040), width: 3)), child:
                      Align(alignment: Alignment.center, child:
                        Padding(padding: EdgeInsets.only(top: 2), child:
                          Semantics(excludeSemantics: true, child:
                          Text('\u00D7', style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.light, fontSize: 48),), )),
                        ),
                    ),
                  ),
                )
            ),),
          ],),),

          SafeArea(child: Stack(children: <Widget>[
            Padding(padding: EdgeInsets.all(16), child:
                Semantics(header:true, child:
                  Text(Localization().getStringEx('widget.id_card.header.title', 'Illini ID'), style: TextStyle(color: Colors.white, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20),),)),
            Align(alignment: Alignment.topRight, child:
                Semantics(button: true, label: Localization().getStringEx('widget.id_card.header.button.close.title', "close"), child:
                  InkWell(
                    onTap : _onClose,
                    child: Container(width: 48, height: 48, alignment: Alignment.center, child: Image.asset('images/close-white.png', excludeFromSemantics: true,))),
                )),
          ],),),
        ],
      
    ),);
  }

  Widget _buildCardContent() {
    
    String? cardExpires = Localization().getStringEx('widget.card.label.expires.title', 'Card Expires');
    String? expirationDate = Auth2().authCard?.expirationDate;
    String cardExpiresText = (0 < (expirationDate?.length ?? 0)) ? "$cardExpires $expirationDate" : "";
    String roleDisplayString = (Auth2().authCard?.needsUpdate ?? false) ? Localization().getStringEx("widget.id_card.label.update_i_card", "Update your i-card") : (Auth2().authCard?.role ?? "");

    Widget? buildingAccessIcon;
    String? buildingAccessStatus;
    String? buildingAccessTime = AppDateTime().formatDateTime(_buildingAccessTime, format: 'MMM dd, yyyy HH:mm a');
    double buildingAccessStatusHeight = 24;
    double qrCodeImageSize = _buildingAccessIconSize + buildingAccessStatusHeight - 2;
    bool hasQrCode = (0 < (_userQRCodeContent?.length ?? 0));

    if (_loadingBuildingAccess) {
      buildingAccessIcon = Container(width: _buildingAccessIconSize, height: _buildingAccessIconSize, child:
        Align(alignment: Alignment.center, child: 
          SizedBox(height: 42, width: 42, child:
            CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), )
          )
        ,),);
    }
    else if (_buildingAccess != null) {

      buildingAccessIcon = Image.asset((_buildingAccess == true) ? 'images/group-20.png' : 'images/group-28.png', width: _buildingAccessIconSize, height: _buildingAccessIconSize, semanticLabel: "building access ${(_buildingAccess == true) ? "granted" : "denied"}",);
      buildingAccessStatus = (_buildingAccess == true) ? Localization().getString('widget.id_card.label.building_access.granted', defaults: 'GRANTED', language: 'en') : Localization().getString('widget.id_card.label.building_access.denied', defaults: 'DENIED', language: 'en');
    }
    else {
      buildingAccessIcon = Container(height: (qrCodeImageSize / 2 - buildingAccessStatusHeight - 6));
      buildingAccessStatus = Localization().getString('widget.id_card.label.building_access.not_available', defaults: 'NOT\nAVAILABLE', language: 'en');
    }
    bool hasBuildingAccess = _hasBuildingAccess && (0 < (Auth2().authCard?.uin?.length ?? 0));

    
    return SingleChildScrollView(scrollDirection: Axis.vertical, child:
    Column(children: <Widget>[
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
              Image.asset('images/group-5-white.png',excludeFromSemantics: true, width: _illiniIconSize, height: _illiniIconSize,)
            ),
          ),
        ],),
      ),
      Container(height: 10,),
      
      Text(Auth2().authCard?.fullName?.trim() ?? '', style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 24)),
      Text(roleDisplayString, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.regular, fontSize: 20)),
      
      Container(height: 15,),

      Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        
        Visibility(visible: hasQrCode, child: Column(children: [
          Text(Auth2().authCard!.cardNumber ?? '', style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.regular, fontSize: 16)),
          Container(height: 8),
          QrImage(data: _userQRCodeContent ?? "", size: qrCodeImageSize, padding: const EdgeInsets.all(0), version: QrVersions.auto, ),
        ],),),

        Visibility(visible: hasQrCode && hasBuildingAccess, child:
          Container(width: 20),
        ),

        Visibility(visible: hasBuildingAccess, child: Column(children: [
          Text(Localization().getString('widget.id_card.label.building_access', defaults: 'Building Access', language: 'en')!, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.regular, fontSize: 16)),
          Container(height: 8),
          buildingAccessIcon,
          Text(buildingAccessStatus ?? '', textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.extraBold, fontSize: buildingAccessStatusHeight),),
        ],),),

      ],),
      Container(height: 15),
      Text(buildingAccessTime ?? '', style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20)),
      Container(height: 15),
      Semantics( container: true,
        child: Column(children: <Widget>[
          // Text((0 < (Auth2().authCard?.uin?.length ?? 0)) ? Localization().getStringEx('widget.card.label.uin.title', 'UIN') : '', style: TextStyle(color: Color(0xffcf3c1b), fontFamily: Styles().fontFamilies!.regular, fontSize: 14)),
          Text(Auth2().authCard?.uin ?? '', style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 28)),
        ],),
      ),
      Text(cardExpiresText, style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.regular, fontSize: 14)),
      Container(height: 30,),

    ],)    );
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

  void _onClose() {
    Navigator.of(context).pop();
  }

  Future<bool> _checkNetIdStatus() async {
    if (Auth2().authCard?.photoBase64?.isEmpty ?? true) {
      await AppAlert.showDialogResult(context, Localization().getStringEx('panel.covid19_passport.message.missing_id_info', 'No Illini ID information found. You may have an expired i-card. Please contact the ID Center.'));
      return false;
    }
    return true;
  }

  String? get _userQRCodeContent {
    String? qrCodeContent = Auth2().authCard!.magTrack2;
    return ((qrCodeContent != null) && (0 < qrCodeContent.length)) ? qrCodeContent : Auth2().authCard?.uin;
  }

  bool get _hasBuildingAccess => FlexUI().hasFeature('safer');

}


