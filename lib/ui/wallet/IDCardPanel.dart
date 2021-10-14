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

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Auth.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/TransportationService.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';
import 'package:qr_flutter/qr_flutter.dart';

class IDCardPanel extends StatefulWidget {
  IDCardPanel();

  _IDCardPanelState createState() => _IDCardPanelState();
}

class _IDCardPanelState extends State<IDCardPanel>
  with SingleTickerProviderStateMixin
  implements NotificationsListener {

  final double _headingH1 = 200;
  final double _headingH2 = 80;
  final double _photoSize = 240;
  final double _iconSize = 64;

  Color _activeColor;
  Color get _activeBorderColor{ return _activeColor ?? Styles().colors.fillColorSecondary; }
  Color get _activeHeadingColor{ return _activeColor ?? Styles().colors.fillColorPrimary; }

  MemoryImage _photoImage;
  AnimationController _animationController;


  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, Auth.notifyCardChanged);
    
    _loadPhotoImage();
    
    _animationController = AnimationController(duration: Duration(milliseconds: 1500), lowerBound: 0, upperBound: 2 * math.pi, animationBehavior: AnimationBehavior.preserve, vsync: this)
    ..addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _animationController.repeat();

    _loadActiveColor().then((Color color){
      if (mounted) {
        setState(() {
          _activeColor = color;
        });
      }
    });
    
    // Auth().updateAuthCard();

    _loadPhotoImage();
  }

  void _loadPhotoImage(){
    _loadAsyncPhotoImage().then((MemoryImage photoImage){
      if (mounted) {
        setState(() {
          _photoImage = photoImage;
        });
      }
    });
  }

  Future<MemoryImage> _loadAsyncPhotoImage() async{
    Uint8List photoBytes = await  Auth().authCard.photoBytes;
    return AppCollection.isCollectionNotEmpty(photoBytes) ? MemoryImage(photoBytes) : null;
  }

  Future<Color> _loadActiveColor() async{
    String deviceId = await NativeCommunicator().getDeviceId();
    return await TransportationService().loadBusColor(deviceId: deviceId, userId: User().uuid);
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
    if (name == Auth.notifyCardChanged) {
      _loadPhotoImage();
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Column(children: <Widget>[
            Container(height: _headingH1, color: _activeHeadingColor,),
            Container(height: _headingH2, color: _activeHeadingColor, child: CustomPaint(painter: TrianglePainter(painterColor: Colors.white), child: Container(),),),
          ],),
          Column(children: <Widget>[
            Expanded(child: (Auth().authCard != null) ? _buildCardContent() : Container(),),

            SafeArea(child: Align(alignment: Alignment.bottomCenter, child:
              Padding(padding: EdgeInsets.only(bottom: 10), child:
                Semantics(button:true,label: Localization().getStringEx('widget.id_card.header.button.close.title', "close"), child:
                  InkWell(onTap : _onClose, child:
                    Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Color(0xff0f2040), width: 3)), child:
                      Align(alignment: Alignment.center, child:
                        Padding(padding: EdgeInsets.only(top: 2), child:
                          Semantics(excludeSemantics: true,child:
                          Text('\u00D7', style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.light, fontSize: 48),), )),
                        ),
                    ),
                  ),
                )
            )),),
          ],),
          SafeArea(child: Stack(children: <Widget>[
            Padding(padding: EdgeInsets.all(16), child:
                Semantics(header:true, child:
                  Text(Localization().getStringEx('widget.id_card.header.title', 'Illini ID'), style: TextStyle(color: Colors.white, fontFamily: Styles().fontFamilies.extraBold, fontSize: 20),),)),
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
    
    String cardExpires = Localization().getStringEx('widget.card.label.expires.title', 'Card Expires');
    String expirationDate = Auth().authCard.expirationDate;
    String cardExpiresText = (0 < (expirationDate?.length ?? 0)) ? "$cardExpires $expirationDate" : "";
    
    return SingleChildScrollView(scrollDirection: Axis.vertical, child:
    Column(children: <Widget>[
      Padding(padding: EdgeInsets.only(top: _headingH1 + (_headingH2 - _photoSize) / 2), child:
        Stack(children: <Widget>[
          Align(alignment: Alignment.topCenter, child:
            Container(width: _photoSize, height: _photoSize, child:
              Stack(children: <Widget>[
                Transform.rotate(angle: _animationController.value, child:
                  Container(width: _photoSize, height: _photoSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [ Styles().colors.fillColorSecondary, _activeBorderColor],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 1.0],),
                      color: Styles().colors.fillColorSecondary,),
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
                  image: DecorationImage(fit: BoxFit.cover, image: MemoryImage(Auth().authCard.photoBytes),),    
                )),
              )
            ),
            */
          ),
          Align(alignment: Alignment.topCenter, child:
            Padding(padding: EdgeInsets.only(top:_photoSize - _iconSize / 2 - 5, left: 3), child:
              Image.asset('images/group-5-white.png',excludeFromSemantics: true, width: _iconSize, height: _iconSize,)
            ),
          ),
        ],),
      ),
      Container(height: 10,),
      
      Text(Auth().authCard.fullName ?? '', style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.extraBold, fontSize: 24)),
      Text(Auth().authCard.roleDisplayString ?? '', style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.regular, fontSize: 20)),
      
      Container(height: 20,),

      Semantics( container: true,
        child: Column(children: <Widget>[
          Text((0 < (Auth().authCard.uin?.length ?? 0)) ? Localization().getStringEx('widget.card.label.uin.title', 'UIN') : '', style: TextStyle(color: Color(0xffcf3c1b), fontFamily: Styles().fontFamilies.regular, fontSize: 14)),
          Text(Auth().authCard.uin ?? '', style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.extraBold, fontSize: 28)),
        ],),
      ),
      Text(cardExpiresText, style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.regular, fontSize: 14)),
      
      Container(height: 20,),
      
      Visibility(
        visible: (0 < (Auth().authCard.cardNumber?.length ?? 0)),
        child: QrImage(
          data: Auth().authCard.magTrack2 ?? '',
          version: QrVersions.auto,
          size: MediaQuery.of(context).size.width / 4 + 10,
          padding: const EdgeInsets.all(10.0),),),
      Text(Auth().authCard.cardNumber ?? '', style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.regular, fontSize: 12)),

    ],)    );
  }

  Widget _buildPhotoImage(){
    return Container(width: _photoSize, height: _photoSize, child:
      Padding(padding: EdgeInsets.all(16),
        child: _photoImage != null
            ? Container(decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                image: DecorationImage(fit: BoxFit.cover, image:_photoImage ,),
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
}


